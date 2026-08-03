from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from tools.cse_api_bridge import (
    BridgeError,
    BridgeTask,
    LocalTools,
    approved,
    parse_task,
    path_allowed,
    redact,
    terminal_state,
    validate_command,
)


VALID_TASK = """<!-- cse-bridge-task:v1 -->

## Repository
faliardic/chief-site-engineer

## Base
master

## Branch
codex/example-task

## Goal
Update the example safely.

## Allowed paths
- docs/example.md
- tests/test_example.py

## Validation commands
- python -m pytest tests/test_example.py
- python -m compileall -q app scripts tools
- git diff --check

## Commit
Update example safely

## Draft PR
Update example safely
Related to #999
"""


class TaskParserTests(unittest.TestCase):
    def test_valid_task_parses(self) -> None:
        task = parse_task(VALID_TASK)
        self.assertEqual(task.repository, "faliardic/chief-site-engineer")
        self.assertEqual(task.base, "master")
        self.assertEqual(task.branch, "codex/example-task")
        self.assertEqual(task.allowed_paths, ("docs/example.md", "tests/test_example.py"))
        self.assertEqual(task.pr_body_first_line, "Related to #999")

    def test_marker_is_required(self) -> None:
        with self.assertRaisesRegex(BridgeError, "task_marker_missing"):
            parse_task(VALID_TASK.replace("<!-- cse-bridge-task:v1 -->", ""))

    def test_duplicate_section_is_rejected(self) -> None:
        with self.assertRaisesRegex(BridgeError, "duplicate_task_section"):
            parse_task(VALID_TASK + "\n## Goal\nSecond goal\n")

    def test_protected_path_is_rejected(self) -> None:
        body = VALID_TASK.replace("- docs/example.md", "- .github/workflows/unsafe.yml")
        with self.assertRaisesRegex(BridgeError, "task_path_protected"):
            parse_task(body)

    def test_shell_composition_is_rejected(self) -> None:
        with self.assertRaisesRegex(BridgeError, "validation_command_forbidden"):
            validate_command("python -m pytest; git push")

    def test_unknown_validation_command_is_rejected(self) -> None:
        with self.assertRaisesRegex(BridgeError, "validation_command_forbidden"):
            validate_command("powershell -File run.ps1")


class PolicyTests(unittest.TestCase):
    def test_glob_allowlist(self) -> None:
        self.assertTrue(path_allowed("docs/guide.md", ("docs/*.md",)))
        self.assertFalse(path_allowed("mobile/lib/main.dart", ("docs/*.md",)))

    def test_approval_requires_trusted_association_and_exact_line(self) -> None:
        self.assertTrue(
            approved(
                [
                    {
                        "body": "CSE_BRIDGE_APPROVED",
                        "author_association": "OWNER",
                    }
                ]
            )
        )
        self.assertFalse(
            approved(
                [
                    {
                        "body": "please CSE_BRIDGE_APPROVED now",
                        "author_association": "OWNER",
                    }
                ]
            )
        )
        self.assertFalse(
            approved(
                [
                    {
                        "body": "CSE_BRIDGE_APPROVED",
                        "author_association": "NONE",
                    }
                ]
            )
        )

    def test_terminal_state_is_duplicate_safe(self) -> None:
        comments = [
            {"body": "<!-- cse-bridge-status:RUNNING -->"},
            {"body": "<!-- cse-bridge-status:PASS -->"},
        ]
        self.assertEqual(terminal_state(comments), "PASS")

    def test_secret_redaction(self) -> None:
        value = redact("Authorization: Bearer abcdefghijklmnop")
        self.assertNotIn("abcdefghijklmnop", value)
        self.assertIn("[REDACTED]", value)


class LocalToolTests(unittest.TestCase):
    def test_write_outside_allowlist_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            task = BridgeTask(
                repository="faliardic/chief-site-engineer",
                base="master",
                branch="codex/example-task",
                goal="goal",
                allowed_paths=("docs/*.md",),
                validation_commands=("git diff --check",),
                commit_subject="subject",
                pr_title="title",
                pr_body_first_line="Related to #1",
            )
            tools = LocalTools(root, task)
            with self.assertRaisesRegex(BridgeError, "model_write_out_of_scope"):
                tools.dispatch("write_file", {"path": "mobile/lib/main.dart", "content": "x"})

    def test_write_inside_allowlist(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            task = BridgeTask(
                repository="faliardic/chief-site-engineer",
                base="master",
                branch="codex/example-task",
                goal="goal",
                allowed_paths=("docs/*.md",),
                validation_commands=("git diff --check",),
                commit_subject="subject",
                pr_title="title",
                pr_body_first_line="Related to #1",
            )
            tools = LocalTools(root, task)
            result = tools.dispatch("write_file", {"path": "docs/example.md", "content": "ok\n"})
            self.assertEqual(result, {"written": "docs/example.md"})
            self.assertEqual((root / "docs/example.md").read_text(encoding="utf-8"), "ok\n")


if __name__ == "__main__":
    unittest.main()
