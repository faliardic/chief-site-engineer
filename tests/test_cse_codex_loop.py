from __future__ import annotations

import json
import os
import shutil
import sys
import tempfile
import unittest
from dataclasses import replace
from pathlib import Path
from unittest.mock import patch

from tools.cse_api_bridge import BridgeError, parse_task
from tools.cse_codex_loop import (
    CommandResult,
    LoopConfig,
    RunArtifacts,
    WORKTREE_REMOVE_ATTEMPTS,
    _validation_argv,
    create_worktree,
    local_gate_ready,
    process_issue,
    run_loop,
    run_validations,
    select_local_gate_issue,
    task_worktree,
    terminal_comment,
)


def task_body(*, allowed: str = "docs/cse_codex_loop.md") -> str:
    return f"""<!-- cse-bridge-task:v1 -->

## Repository
faliardic/chief-site-engineer

## Base
master

## Branch
codex/issue-345-local-codex-agent-loop

## Goal
Implement the local loop test fixture.

## Allowed paths
- {allowed}

## Validation commands
- python -m unittest
- git diff --check

## Commit
Add local Codex implementer reviewer loop

## Draft PR
Add local Codex implementer reviewer loop
Related to this Issue
"""


def validation_task(*commands: str):  # type: ignore[no-untyped-def]
    validation_commands = "\n".join(f"- {command}" for command in commands)
    return parse_task(
        task_body().replace(
            "- python -m unittest\n- git diff --check", validation_commands
        )
    )


APPROVAL = {
    "body": "CSE_BRIDGE_APPROVED\nCSE_LOCAL_GATE_REQUEST",
    "author_association": "OWNER",
    "created_at": "2026-08-04T19:55:02Z",
}


class FakeGitHub:
    repository = "faliardic/chief-site-engineer"

    def __init__(
        self,
        *,
        body: str | None = None,
        approval: bool = True,
        comments: list[dict[str, object]] | None = None,
        issue_overrides: dict[str, object] | None = None,
    ):
        self.body = body or task_body()
        self._comments = (
            [dict(item) for item in comments]
            if comments is not None
            else ([dict(APPROVAL)] if approval else [])
        )
        self.issue_data: dict[str, object] = {
            "number": 345,
            "body": self.body,
            "state": "open",
        }
        self.issue_data.update(issue_overrides or {})
        self.posted: list[str] = []
        self.prs: list[object] = []

    def request(self, method, path, payload=None):  # type: ignore[no-untyped-def]
        if method == "GET" and path.endswith("issues?state=open&per_page=100"):
            return [dict(self.issue_data)]
        raise AssertionError((method, path, payload))

    def issue(self, number: int):
        self.assert_issue(number)
        return dict(self.issue_data)

    def comments(self, number: int):
        self.assert_issue(number)
        return list(self._comments)

    def comment(self, number: int, body: str) -> None:
        self.assert_issue(number)
        self.posted.append(body)
        self._comments.append({"body": body, "author_association": "NONE"})

    def create_draft_pr(self, task):  # type: ignore[no-untyped-def]
        self.prs.append(task)
        return {"html_url": "https://github.example/pr/1"}

    def assert_issue(self, number: int) -> None:
        if number != 345:
            raise AssertionError(number)


class EmptyGitHub(FakeGitHub):
    def request(self, method, path, payload=None):  # type: ignore[no-untyped-def]
        return []


class FakeCommands:
    def __init__(
        self,
        *,
        changed: str = "docs/cse_codex_loop.md",
        reviews: list[dict[str, object]] | None = None,
        validation_exit: int = 0,
        implementer_exit: int = 0,
        cleanup_remove_failures: int = 0,
        cleanup_dirty: bool = False,
        cleanup_absent_after_push: bool = False,
        cleanup_absent_but_registered: bool = False,
        cleanup_unregister_on_failed_remove: bool = False,
        include_unrelated_stale_worktree: bool = False,
    ):
        self.changed = changed
        self.reviews = list(
            reviews
            or [{"verdict": "approved", "summary": "Looks good.", "findings": []}]
        )
        self.validation_exit = validation_exit
        self.implementer_exit = implementer_exit
        self.cleanup_remove_failures = cleanup_remove_failures
        self.cleanup_dirty = cleanup_dirty
        self.cleanup_absent_after_push = cleanup_absent_after_push
        self.cleanup_absent_but_registered = cleanup_absent_but_registered
        self.cleanup_unregister_on_failed_remove = cleanup_unregister_on_failed_remove
        self.include_unrelated_stale_worktree = include_unrelated_stale_worktree
        self.calls: list[tuple[str, ...]] = []
        self.prompts: list[str] = []
        self.review_prompts: list[str] = []
        self.cleanup = False
        self.cleanup_remove_calls = 0
        self.prune_invoked = False
        self.registered_worktrees: list[Path] = []
        self.worktree_list_snapshots: list[tuple[Path, ...]] = []
        self.unrelated_stale_worktree: Path | None = None
        self.committed = False
        self.published_commit = "a" * 40

    def __call__(self, argv, cwd, timeout, input_text):  # type: ignore[no-untyped-def]
        call = tuple(str(item) for item in argv)
        self.calls.append(call)
        tool = Path(call[0]).name.casefold()
        args = call[1:]
        if tool == "git.exe":
            return self.git(args, Path(cwd))
        if tool == "codex.exe":
            return self.codex(call, Path(cwd), input_text)
        if tool == "python.exe":
            return CommandResult(self.validation_exit, "focused tests\n")
        raise AssertionError(call)

    def git(self, args: tuple[str, ...], cwd: Path) -> CommandResult:
        if args == ("rev-parse", "--show-toplevel"):
            return CommandResult(0, str(cwd))
        if args == ("remote", "get-url", "origin"):
            return CommandResult(
                0, "https://github.com/faliardic/chief-site-engineer.git\n"
            )
        if args[:3] == ("show-ref", "--verify", "--quiet"):
            return CommandResult(1)
        if args[:4] == ("ls-remote", "--exit-code", "--heads", "origin"):
            return CommandResult(2)
        if args[:2] == ("fetch", "origin"):
            return CommandResult(0)
        if args[:2] == ("worktree", "add"):
            worktree = Path(args[-2])
            worktree.mkdir(parents=True)
            self.registered_worktrees = [cwd.resolve(), worktree.resolve()]
            if self.include_unrelated_stale_worktree:
                self.unrelated_stale_worktree = (
                    worktree.parent / "unrelated-historical-stale"
                ).resolve()
                self.registered_worktrees.append(self.unrelated_stale_worktree)
            return CommandResult(0)
        if args[:2] == ("status", "--porcelain=v1"):
            if self.committed:
                changed = f" M {self.changed}\n" if self.cleanup_dirty else ""
                return CommandResult(0, changed)
            return CommandResult(0, f"?? {self.changed}\n")
        if args == ("diff", "--check"):
            return CommandResult(0)
        if args[:2] == ("add", "-A"):
            return CommandResult(0)
        if args == ("diff", "--cached", "--name-only"):
            return CommandResult(0, self.changed + "\n")
        if "commit" in args:
            self.committed = True
            return CommandResult(0)
        if args == ("rev-parse", "--verify", "HEAD"):
            return CommandResult(0, self.published_commit + "\n")
        if args[:2] == ("push", "origin"):
            if self.cleanup_absent_after_push or self.cleanup_absent_but_registered:
                shutil.rmtree(cwd)
            if self.cleanup_absent_after_push:
                self.registered_worktrees = [
                    path for path in self.registered_worktrees if path != cwd.resolve()
                ]
            return CommandResult(0)
        if args == ("symbolic-ref", "--quiet", "HEAD"):
            return CommandResult(
                0, "refs/heads/codex/issue-345-local-codex-agent-loop\n"
            )
        if args[:2] == ("worktree", "remove"):
            self.cleanup_remove_calls += 1
            if self.cleanup_remove_calls <= self.cleanup_remove_failures:
                if self.cleanup_unregister_on_failed_remove:
                    removed = Path(args[-1]).resolve()
                    shutil.rmtree(removed)
                    self.registered_worktrees = [
                        path for path in self.registered_worktrees if path != removed
                    ]
                return CommandResult(1, stderr="transient cleanup failure")
            removed = Path(args[-1]).resolve()
            shutil.rmtree(removed)
            self.registered_worktrees = [
                path for path in self.registered_worktrees if path != removed
            ]
            self.cleanup = True
            return CommandResult(0)
        if args == ("worktree", "list", "--porcelain", "-z"):
            snapshot = tuple(self.registered_worktrees)
            self.worktree_list_snapshots.append(snapshot)
            records = []
            for registered in snapshot:
                fields = [f"worktree {registered}", f"HEAD {self.published_commit}"]
                if registered == self.unrelated_stale_worktree:
                    fields.extend(
                        (
                            "detached",
                            "prunable gitdir file points to non-existent location",
                        )
                    )
                else:
                    fields.append("branch refs/heads/test")
                records.append("\0".join(fields) + "\0\0")
            return CommandResult(0, "".join(records))
        if args == ("worktree", "prune", "--expire", "now"):
            self.prune_invoked = True
            self.registered_worktrees = [
                path
                for path in self.registered_worktrees
                if path != self.unrelated_stale_worktree
            ]
            return CommandResult(0)
        raise AssertionError(args)

    def codex(
        self, call: tuple[str, ...], cwd: Path, input_text: str | None
    ) -> CommandResult:
        sandbox = call[call.index("--sandbox") + 1]
        if sandbox == "read-only":
            self.review_prompts.append(input_text or "")
            result_path = Path(call[call.index("--output-last-message") + 1])
            value = self.reviews.pop(0)
            result_path.write_text(json.dumps(value), encoding="utf-8")
            return CommandResult(0)
        self.prompts.append(input_text or "")
        if self.implementer_exit:
            return CommandResult(self.implementer_exit, stderr="failed")
        destination = cwd / self.changed
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text("implemented\n", encoding="utf-8")
        return CommandResult(0)


class LoopFixture(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name).resolve()
        self.repo = self.root / "repo"
        self.runtime = self.root / "runtime"
        self.repo.mkdir()
        self.config = LoopConfig(
            repository="faliardic/chief-site-engineer",
            repo_root=self.repo,
            codex_path=self.root / "codex.exe",
            git_path=self.root / "git.exe",
            gh_path=self.root / "gh.exe",
            python_path=self.root / "python.exe",
        )

    def artifacts(self) -> RunArtifacts:
        return RunArtifacts.create(
            self.runtime, None, run_id="20260804T200000Z-12345678"
        )


class SelectionTests(LoopFixture):
    def test_no_task_is_idle(self) -> None:
        commands = FakeCommands()
        artifacts = self.artifacts()
        result = run_loop(
            self.config,
            self.runtime,
            EmptyGitHub(),
            commands,
            artifacts,
        )
        self.assertEqual(result, 0)
        status = json.loads(
            (artifacts.run_root / "status.json").read_text(encoding="utf-8")
        )
        self.assertEqual(status["state"], "IDLE")
        self.assertEqual(status["reason"], "no_task")

    def test_only_explicit_trusted_local_gate_is_selected(self) -> None:
        self.assertEqual(select_local_gate_issue(FakeGitHub()), 345)
        self.assertIsNone(select_local_gate_issue(FakeGitHub(approval=False)))

    def test_generic_approval_without_local_gate_is_idle(self) -> None:
        generic = FakeGitHub(
            comments=[
                {
                    **APPROVAL,
                    "body": "CSE_BRIDGE_APPROVED",
                }
            ]
        )

        self.assertFalse(
            local_gate_ready(generic.issue_data, generic.comments(345))
        )
        self.assertIsNone(select_local_gate_issue(generic))

        commands = FakeCommands()
        artifacts = self.artifacts()
        self.assertEqual(
            run_loop(
                self.config,
                self.runtime,
                generic,
                commands,
                artifacts,
            ),
            0,
        )
        self.assertEqual(
            [call[1:] for call in commands.calls],
            [
                ("rev-parse", "--show-toplevel"),
                ("remote", "get-url", "origin"),
            ],
        )

    def test_stale_local_gate_does_not_authorize_new_generic_approval(
        self,
    ) -> None:
        comments = [
            dict(APPROVAL),
            {
                "body": "CSE_BRIDGE_APPROVED",
                "author_association": "OWNER",
                "created_at": "2026-08-04T19:56:02Z",
            },
        ]
        github = FakeGitHub(comments=comments)

        self.assertFalse(
            local_gate_ready(github.issue_data, github.comments(345))
        )
        self.assertIsNone(select_local_gate_issue(github))


class WorktreeTests(LoopFixture):
    def test_external_worktree_is_created_from_exact_origin_base(self) -> None:
        commands = FakeCommands()
        artifacts = self.artifacts()
        task = __import__(
            "tools.cse_api_bridge", fromlist=["parse_task"]
        ).parse_task(task_body())
        worktree = create_worktree(
            self.config, self.runtime, 345, task, commands, artifacts
        )
        self.assertEqual(worktree, task_worktree(self.runtime, 345))
        self.assertNotIn(self.repo, worktree.parents)
        self.assertIn(
            (
                str(self.config.git_path),
                "worktree",
                "add",
                "-b",
                task.branch,
                str(worktree),
                "origin/master",
            ),
            commands.calls,
        )


class ValidationExecutableTests(LoopFixture):
    def test_configured_flutter_validation_uses_exact_executable(self) -> None:
        flutter_path = self.root / "flutter.bat"
        config = replace(self.config, flutter_path=flutter_path)

        self.assertEqual(
            _validation_argv(config, "flutter test test/widget_test.dart"),
            (str(flutter_path), "test", "test/widget_test.dart"),
        )

    def test_flutter_is_required_only_for_declared_flutter_validation(self) -> None:
        self.assertEqual(
            _validation_argv(self.config, "python -m unittest"),
            (str(self.config.python_path), "-m", "unittest"),
        )
        with self.assertRaisesRegex(
            BridgeError, "validation_executable_unconfigured"
        ):
            _validation_argv(self.config, "flutter analyze")


class ValidationWorkingDirectoryTests(LoopFixture):
    def configured_flutter(self) -> LoopConfig:
        return replace(self.config, flutter_path=self.root / "flutter.bat")

    def validation_adapter(self):  # type: ignore[no-untyped-def]
        calls: list[tuple[tuple[str, ...], Path, int, str | None]] = []

        def command(argv, cwd, timeout, input_text):  # type: ignore[no-untyped-def]
            calls.append((tuple(argv), Path(cwd), timeout, input_text))
            return CommandResult(0)

        return calls, command

    def test_root_flutter_package_selects_worktree_root(self) -> None:
        worktree = self.root / "worktree"
        mobile_root = worktree / "mobile"
        mobile_root.mkdir(parents=True)
        (worktree / "pubspec.yaml").write_text("name: root\n", encoding="utf-8")
        (mobile_root / "pubspec.yaml").write_text(
            "name: nested\n", encoding="utf-8"
        )
        calls, command = self.validation_adapter()

        run_validations(
            self.configured_flutter(),
            worktree,
            validation_task("flutter test test/widget_test.dart"),
            command,
            self.artifacts(),
        )

        self.assertEqual(calls[0][1], worktree)

    def test_nested_flutter_package_selects_mobile_root(self) -> None:
        worktree = self.root / "worktree"
        mobile_root = worktree / "mobile"
        mobile_root.mkdir(parents=True)
        (mobile_root / "pubspec.yaml").write_text(
            "name: nested\n", encoding="utf-8"
        )
        calls, command = self.validation_adapter()

        run_validations(
            self.configured_flutter(),
            worktree,
            validation_task("flutter analyze"),
            command,
            self.artifacts(),
        )

        self.assertEqual(calls[0][1], mobile_root)

    def test_missing_pubspec_fails_before_command_adapter(self) -> None:
        worktree = self.root / "worktree"
        worktree.mkdir()
        calls, command = self.validation_adapter()

        with self.assertRaisesRegex(
            BridgeError, "validation_working_directory_unavailable"
        ):
            run_validations(
                self.configured_flutter(),
                worktree,
                validation_task("flutter test test/widget_test.dart"),
                command,
                self.artifacts(),
            )

        self.assertEqual(calls, [])

    def test_python_and_git_keep_worktree_root(self) -> None:
        worktree = self.root / "worktree"
        worktree.mkdir()
        calls, command = self.validation_adapter()

        run_validations(
            self.config,
            worktree,
            validation_task("python -m unittest", "git diff --check"),
            command,
            self.artifacts(),
        )

        self.assertEqual([call[1] for call in calls], [worktree, worktree])
        self.assertEqual(
            [call[0] for call in calls],
            [
                (str(self.config.python_path), "-m", "unittest"),
                (str(self.config.git_path), "diff", "--check"),
            ],
        )

    def test_flutter_path_remains_required_before_command_adapter(self) -> None:
        worktree = self.root / "worktree"
        worktree.mkdir()
        (worktree / "pubspec.yaml").write_text("name: root\n", encoding="utf-8")
        calls, command = self.validation_adapter()

        with self.assertRaisesRegex(
            BridgeError, "validation_executable_unconfigured"
        ):
            run_validations(
                self.config,
                worktree,
                validation_task("flutter analyze"),
                command,
                self.artifacts(),
            )

        self.assertEqual(calls, [])


class OrchestrationTests(LoopFixture):
    def run_issue(
        self, commands: FakeCommands, github: FakeGitHub | None = None
    ) -> tuple[int, FakeGitHub, RunArtifacts]:
        client = github or FakeGitHub()
        artifacts = self.artifacts()
        result = process_issue(
            345,
            self.config,
            self.runtime,
            client,
            commands,
            artifacts,
        )
        return result, client, artifacts

    def test_implement_review_approval_publish_and_cleanup(self) -> None:
        commands = FakeCommands()
        result, github, artifacts = self.run_issue(commands)
        self.assertEqual(result, 0)
        self.assertTrue(commands.cleanup)
        self.assertFalse(task_worktree(self.runtime, 345).exists())
        self.assertEqual(len(github.prs), 1)
        self.assertIn("READY_FOR_FATIH", github.posted[-1])
        self.assertIn(
            "--sandbox", "\n".join(" ".join(call) for call in commands.calls)
        )
        self.assertEqual(len(commands.review_prompts), 1)
        review_prompt = commands.review_prompts[0]
        self.assertIn("Implement the local loop test fixture.", review_prompt)
        self.assertIn("- docs/cse_codex_loop.md", review_prompt)
        self.assertIn("- PASS: python -m unittest", review_prompt)
        self.assertIn("Host-observed changed paths", review_prompt)
        status = json.loads(
            (artifacts.run_root / "status.json").read_text(encoding="utf-8")
        )
        self.assertEqual(status["state"], "PASS")

    def test_transient_first_remove_failure_is_retried_then_cleaned(self) -> None:
        commands = FakeCommands(cleanup_remove_failures=1)

        result, github, artifacts = self.run_issue(commands)

        self.assertEqual(result, 0)
        self.assertEqual(commands.cleanup_remove_calls, 2)
        self.assertFalse(task_worktree(self.runtime, 345).exists())
        self.assertNotIn("approved_cleanup_pending", github.posted[-1])
        status = json.loads(
            (artifacts.run_root / "status.json").read_text(encoding="utf-8")
        )
        self.assertEqual(status["reason"], "approved")

    def test_already_absent_unregistered_worktree_is_cleanup_complete(self) -> None:
        commands = FakeCommands(cleanup_absent_after_push=True)

        result, github, _ = self.run_issue(commands)

        self.assertEqual(result, 0)
        self.assertEqual(commands.cleanup_remove_calls, 0)
        self.assertFalse(commands.prune_invoked)
        self.assertIn(
            (
                str(self.config.git_path),
                "worktree",
                "list",
                "--porcelain",
                "-z",
            ),
            commands.calls,
        )
        self.assertNotIn("approved_cleanup_pending", github.posted[-1])

    def test_failed_remove_is_complete_when_exact_path_is_unregistered(self) -> None:
        commands = FakeCommands(
            cleanup_remove_failures=1,
            cleanup_unregister_on_failed_remove=True,
        )

        result, github, _ = self.run_issue(commands)

        self.assertEqual(result, 0)
        self.assertEqual(commands.cleanup_remove_calls, 1)
        self.assertFalse(commands.prune_invoked)
        self.assertNotIn("approved_cleanup_pending", github.posted[-1])

    def test_absent_but_registered_worktree_is_preserved_as_cleanup_pending(
        self,
    ) -> None:
        commands = FakeCommands(cleanup_absent_but_registered=True)

        result, github, _ = self.run_issue(commands)

        self.assertEqual(result, 0)
        self.assertEqual(commands.cleanup_remove_calls, 0)
        self.assertFalse(commands.prune_invoked)
        self.assertIn("`approved_cleanup_pending`", github.posted[-1])

    def test_cleanup_never_prunes_unrelated_stale_worktree_metadata(self) -> None:
        commands = FakeCommands(include_unrelated_stale_worktree=True)

        result, github, _ = self.run_issue(commands)

        issue_worktree = task_worktree(self.runtime, 345).resolve()
        unrelated = commands.unrelated_stale_worktree
        self.assertEqual(result, 0)
        self.assertIsNotNone(unrelated)
        self.assertIn(issue_worktree, commands.worktree_list_snapshots[0])
        self.assertIn(unrelated, commands.worktree_list_snapshots[0])
        self.assertNotIn(issue_worktree, commands.registered_worktrees)
        self.assertIn(unrelated, commands.registered_worktrees)
        self.assertFalse(commands.prune_invoked)
        self.assertFalse(
            any(call[1:3] == ("worktree", "prune") for call in commands.calls)
        )
        self.assertNotIn("approved_cleanup_pending", github.posted[-1])

    def test_dirty_published_worktree_is_preserved_with_cleanup_warning(self) -> None:
        commands = FakeCommands(cleanup_dirty=True)

        result, github, artifacts = self.run_issue(commands)

        self.assertEqual(result, 0)
        self.assertEqual(commands.cleanup_remove_calls, 0)
        self.assertTrue(task_worktree(self.runtime, 345).exists())
        self.assertIn("READY_FOR_FATIH", github.posted[-1])
        self.assertIn("https://github.example/pr/1", github.posted[-1])
        self.assertIn("`approved_cleanup_pending`", github.posted[-1])
        self.assertNotIn("FAILED\n", github.posted[-1])
        status = json.loads(
            (artifacts.run_root / "status.json").read_text(encoding="utf-8")
        )
        self.assertEqual(status["state"], "PASS")
        self.assertEqual(status["exit_code"], 0)
        self.assertEqual(status["reason"], "approved_cleanup_pending")

    def test_persistent_cleanup_failure_after_publication_is_pass_warning(
        self,
    ) -> None:
        commands = FakeCommands(cleanup_remove_failures=WORKTREE_REMOVE_ATTEMPTS)

        with patch(
            "tools.cse_codex_loop.shutil.rmtree",
            side_effect=PermissionError("locked"),
        ):
            result, github, artifacts = self.run_issue(commands)

        self.assertEqual(result, 0)
        self.assertEqual(commands.cleanup_remove_calls, WORKTREE_REMOVE_ATTEMPTS)
        self.assertTrue(task_worktree(self.runtime, 345).exists())
        self.assertEqual(len(github.prs), 1)
        self.assertIn("READY_FOR_FATIH", github.posted[-1])
        self.assertIn("https://github.example/pr/1", github.posted[-1])
        self.assertIn("`approved_cleanup_pending`", github.posted[-1])
        self.assertNotIn("FAILED\n", github.posted[-1])
        status = json.loads(
            (artifacts.run_root / "status.json").read_text(encoding="utf-8")
        )
        self.assertEqual(status["state"], "PASS")
        self.assertEqual(status["exit_code"], 0)
        self.assertEqual(status["reason"], "approved_cleanup_pending")

    def test_scope_violation_fails_and_preserves_worktree(self) -> None:
        commands = FakeCommands(changed="app/product.py")
        result, github, _ = self.run_issue(commands)
        self.assertEqual(result, 1)
        self.assertTrue(task_worktree(self.runtime, 345).exists())
        self.assertIn("`scope_violation`", github.posted[-1])
        self.assertFalse(commands.cleanup)

    def test_validation_failure_is_terminal_without_correction(self) -> None:
        commands = FakeCommands(validation_exit=1)
        result, github, _ = self.run_issue(commands)
        self.assertEqual(result, 1)
        self.assertIn("`validation_failed`", github.posted[-1])
        self.assertEqual(len(commands.prompts), 1)
        self.assertTrue(task_worktree(self.runtime, 345).exists())

    def test_one_review_correction_then_approval(self) -> None:
        commands = FakeCommands(
            reviews=[
                {
                    "verdict": "changes_requested",
                    "summary": "One fix is needed.",
                    "findings": ["Tighten the status assertion."],
                },
                {"verdict": "approved", "summary": "Fixed.", "findings": []},
            ]
        )
        result, github, _ = self.run_issue(commands)
        self.assertEqual(result, 0)
        self.assertEqual(len(commands.prompts), 2)
        self.assertIn("Tighten the status assertion", commands.prompts[1])
        self.assertIn("READY_FOR_FATIH", github.posted[-1])

    def test_unresolved_second_review_needs_human_and_preserves_worktree(self) -> None:
        requested = {
            "verdict": "changes_requested",
            "summary": "Still wrong.",
            "findings": ["Fix the remaining issue."],
        }
        commands = FakeCommands(reviews=[requested, requested])
        result, github, _ = self.run_issue(commands)
        self.assertEqual(result, 3)
        self.assertIn("NEEDS_HUMAN", github.posted[-1])
        self.assertIn("`review_unresolved`", github.posted[-1])
        self.assertTrue(task_worktree(self.runtime, 345).exists())
        self.assertFalse(github.prs)

    def test_explicit_issue_rejects_stale_running_approval(self) -> None:
        stale = FakeGitHub(
            comments=[
                dict(APPROVAL),
                {
                    "body": "<!-- cse-bridge-status:RUNNING -->",
                    "author_association": "OWNER",
                    "created_at": "2026-08-04T19:56:02Z",
                },
            ]
        )
        commands = FakeCommands()

        with self.assertRaisesRegex(BridgeError, "task_not_ready"):
            self.run_issue(commands, stale)

        self.assertFalse(commands.calls)

    def test_explicit_issue_accepts_newer_reapproval_after_running(self) -> None:
        reapproved = FakeGitHub(
            comments=[
                dict(APPROVAL),
                {
                    "body": "<!-- cse-bridge-status:RUNNING -->",
                    "author_association": "OWNER",
                    "created_at": "2026-08-04T19:56:02Z",
                },
                {
                    "body": (
                        "CSE_BRIDGE_APPROVED\n"
                        "CSE_LOCAL_GATE_REQUEST"
                    ),
                    "author_association": "OWNER",
                    "created_at": "2026-08-04T19:57:02Z",
                },
            ]
        )

        result, github, _ = self.run_issue(FakeCommands(), reapproved)

        self.assertEqual(result, 0)
        self.assertIn("READY_FOR_FATIH", github.posted[-1])

    def test_explicit_issue_cannot_bypass_local_gate_boundary(self) -> None:
        generic = FakeGitHub(
            comments=[
                {
                    **APPROVAL,
                    "body": "CSE_BRIDGE_APPROVED",
                }
            ]
        )
        commands = FakeCommands()

        with self.assertRaisesRegex(BridgeError, "task_not_ready"):
            self.run_issue(commands, generic)

        self.assertFalse(commands.calls)

    def test_explicit_issue_requires_open_non_pr_issue(self) -> None:
        for index, overrides in enumerate(
            ({"state": "closed"}, {"pull_request": {"url": "example"}})
        ):
            with self.subTest(overrides=overrides):
                commands = FakeCommands()
                artifacts = RunArtifacts.create(
                    self.runtime,
                    345,
                    run_id=f"not-ready-{index}",
                )
                with self.assertRaisesRegex(BridgeError, "task_not_ready"):
                    process_issue(
                        345,
                        self.config,
                        self.runtime,
                        FakeGitHub(issue_overrides=overrides),
                        commands,
                        artifacts,
                    )
                self.assertFalse(commands.calls)

    def test_codex_failure_is_data_minimal_and_preserves_worktree(self) -> None:
        commands = FakeCommands(implementer_exit=2)
        result, github, _ = self.run_issue(commands)
        self.assertEqual(result, 1)
        self.assertIn("`codex_implementer_failed`", github.posted[-1])
        self.assertNotIn("failed\n", github.posted[-1])
        self.assertTrue(task_worktree(self.runtime, 345).exists())

    def test_terminal_comments_are_stable(self) -> None:
        ready = terminal_comment(
            "READY_FOR_FATIH", "approved", "run-1", "https://example/pr/1"
        )
        failed = terminal_comment("FAILED", "validation_failed", "run-1")
        needs = terminal_comment("NEEDS_HUMAN", "review_unresolved", "run-1")
        self.assertTrue(ready.startswith("<!-- cse-bridge-status:PASS -->\n"))
        self.assertIn("READY_FOR_FATIH", ready)
        self.assertIn("FAILED\n", failed)
        self.assertIn("NEEDS_HUMAN\n", needs)


@unittest.skipUnless(os.name == "nt", "Windows command stubs exercise shell=False")
class StubExecutableIntegrationTests(unittest.TestCase):
    def test_issue_to_correction_approval_and_publication(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            repo = root / "repo"
            runtime = root / "runtime"
            repo.mkdir()
            state_path = root / "state.json"
            stub_path = root / "stub.py"
            stub_path.write_text(
                STUB_PROGRAM.replace("__STATE__", repr(str(state_path))).replace(
                    "__REPO__", repr(str(repo))
                ),
                encoding="utf-8",
            )
            executables: dict[str, Path] = {}
            for name in ("git", "codex", "python", "gh"):
                wrapper = root / f"{name}.cmd"
                wrapper.write_text(
                    f'@echo off\r\n"{sys.executable}" "{stub_path}" {name} %*\r\n',
                    encoding="utf-8",
                )
                executables[name] = wrapper
            config = LoopConfig(
                repository="faliardic/chief-site-engineer",
                repo_root=repo,
                codex_path=executables["codex"],
                git_path=executables["git"],
                gh_path=executables["gh"],
                python_path=executables["python"],
            )
            artifacts = RunArtifacts.create(runtime, 345, run_id="integration-run")
            github = FakeGitHub()
            from tools.cse_codex_loop import run_command

            result = run_loop(
                config,
                runtime,
                github,
                run_command,
                artifacts,
                issue_number=345,
            )
            self.assertEqual(result, 0)
            state = json.loads(state_path.read_text(encoding="utf-8"))
            self.assertEqual(state["reviews"], 2)
            self.assertTrue(state["committed"])
            self.assertTrue(state["pushed"])
            self.assertIn("READY_FOR_FATIH", github.posted[-1])


STUB_PROGRAM = r'''import json
import shutil
import sys
from pathlib import Path

state_path = Path(__STATE__)
repo = Path(__REPO__)
state = json.loads(state_path.read_text()) if state_path.exists() else {
    "reviews": 0, "changed": False, "committed": False, "pushed": False
}
tool, *args = sys.argv[1:]

def save():
    state_path.write_text(json.dumps(state))

if tool == "git":
    if args == ["rev-parse", "--show-toplevel"]:
        print(repo)
    elif args == ["remote", "get-url", "origin"]:
        print("https://github.com/faliardic/chief-site-engineer.git")
    elif args[:3] == ["show-ref", "--verify", "--quiet"]:
        sys.exit(1)
    elif args[:4] == ["ls-remote", "--exit-code", "--heads", "origin"]:
        sys.exit(2)
    elif args[:2] == ["worktree", "add"]:
        worktree = Path(args[-2])
        worktree.mkdir(parents=True)
        state["worktree"] = str(worktree)
    elif args[:2] == ["status", "--porcelain=v1"]:
        if not state["committed"]:
            print("?? docs/cse_codex_loop.md")
    elif args == ["diff", "--cached", "--name-only"]:
        print("docs/cse_codex_loop.md")
    elif "commit" in args:
        state["committed"] = True
    elif args == ["rev-parse", "--verify", "HEAD"]:
        print("a" * 40)
    elif args[:2] == ["push", "origin"]:
        state["pushed"] = True
    elif args == ["symbolic-ref", "--quiet", "HEAD"]:
        print("refs/heads/codex/issue-345-local-codex-agent-loop")
    elif args == ["worktree", "list", "--porcelain", "-z"]:
        paths = [repo]
        if state.get("worktree"):
            paths.append(Path(state["worktree"]))
        sys.stdout.write("".join(
            f"worktree {path}\0HEAD {'a' * 40}\0branch refs/heads/test\0\0"
            for path in paths
        ))
    elif args[:2] == ["worktree", "remove"]:
        shutil.rmtree(Path(args[-1]))
        state.pop("worktree", None)
    save()
elif tool == "codex":
    if args[args.index("--sandbox") + 1] == "read-only":
        state["reviews"] += 1
        verdict = "changes_requested" if state["reviews"] == 1 else "approved"
        findings = ["Apply the stub correction."] if state["reviews"] == 1 else []
        output = Path(args[args.index("--output-last-message") + 1])
        output.write_text(json.dumps({
            "verdict": verdict, "summary": "stub review", "findings": findings
        }))
    else:
        destination = Path.cwd() / "docs" / "cse_codex_loop.md"
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text("stub implementation\n")
        state["changed"] = True
    save()
elif tool in {"python", "gh"}:
    pass
'''


if __name__ == "__main__":
    unittest.main()
