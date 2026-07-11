import json
import sys
from pathlib import Path

import pytest

from scripts import cse_status


def command(args, returncode=0, stdout="", stderr=""):
    return cse_status.CommandResult(
        args=list(args),
        returncode=returncode,
        stdout=stdout,
        stderr=stderr,
    )


def test_collect_status_does_not_run_pytest_without_flag(monkeypatch, tmp_path):
    calls = []

    def fake_run(args, cwd):
        calls.append(args)
        if args[:3] == ["git", "branch", "--show-current"]:
            return command(args, stdout="feature\n")
        if args[:3] == ["git", "log", "-1"]:
            return command(args, stdout="abc123\x00Subject\n")
        if args[:3] == ["git", "rev-parse", "--verify"]:
            return command(args, stdout="base\n")
        if args[:3] == ["git", "rev-list", "--left-right"]:
            return command(args, stdout="2\t3\n")
        return command(args)

    monkeypatch.setattr(cse_status, "run_command", fake_run)

    report = cse_status.collect_status(tmp_path, run_tests=False, upstream_ref="origin/master")

    assert report["pytest"]["requested"] is False
    assert [sys.executable, "-m", "pytest"] not in calls
    assert report["head"]["branch"] == "feature"
    assert report["divergence"]["behind"] == 2
    assert report["divergence"]["ahead"] == 3


def test_collect_status_runs_pytest_only_with_flag(monkeypatch, tmp_path):
    calls = []

    def fake_run(args, cwd):
        calls.append(args)
        if args == [sys.executable, "-m", "pytest"]:
            return command(args, stdout="1 passed\n")
        if args[:3] == ["git", "log", "-1"]:
            return command(args, stdout="abc123\x00Subject\n")
        if args[:3] == ["git", "rev-parse", "--verify"]:
            return command(args, returncode=1, stderr="missing\n")
        return command(args)

    monkeypatch.setattr(cse_status, "run_command", fake_run)

    report = cse_status.collect_status(tmp_path, run_tests=True, upstream_ref="origin/master")

    assert [sys.executable, "-m", "pytest"] in calls
    assert report["pytest"]["requested"] is True
    assert report["pytest"]["ok"] is True


def test_git_lists_separate_ignored_files(monkeypatch, tmp_path):
    def fake_run(args, cwd):
        if args[:3] == ["git", "diff", "--name-status"]:
            return command(args, stdout="M\ttracked.py\n")
        if args[:3] == ["git", "status", "--ignored"]:
            return command(args, stdout=" M tracked.py\n!! .pytest_cache/file\n?? new.py\n")
        return command(args)

    monkeypatch.setattr(cse_status, "run_command", fake_run)

    report = cse_status.collect_git_lists(tmp_path)

    assert report["tracked_worktree_changes"] == ["M\ttracked.py"]
    assert report["untracked_files"] == ["new.py"]
    assert report["ignored_files"] == [".pytest_cache/file"]


def test_exports_clean_only_when_gitkeep_is_the_only_file(tmp_path):
    exports = tmp_path / "exports"
    exports.mkdir()
    (exports / ".gitkeep").write_text("\n", encoding="utf-8")

    assert cse_status.collect_exports(tmp_path)["clean"] is True

    (exports / "report.json").write_text("{}", encoding="utf-8")

    assert cse_status.collect_exports(tmp_path)["clean"] is False


def test_zip_collection_skips_git_directory(tmp_path):
    (tmp_path / "archive.zip").write_text("zip", encoding="utf-8")
    git_dir = tmp_path / ".git"
    git_dir.mkdir()
    (git_dir / "internal.zip").write_text("zip", encoding="utf-8")

    report = cse_status.collect_zip_files(tmp_path)

    assert report == {"count": 1, "files": ["archive.zip"]}


def test_json_output_refuses_overwrite_without_flag(tmp_path):
    output_path = tmp_path / "status.json"
    output_path.write_text("old", encoding="utf-8")

    with pytest.raises(FileExistsError):
        cse_status.write_json_output({"ok": True}, output_path, overwrite=False)


def test_json_output_writes_sorted_parseable_json(tmp_path):
    output_path = tmp_path / "status.json"

    cse_status.write_json_output({"b": 2, "a": 1}, output_path, overwrite=False)

    assert json.loads(output_path.read_text(encoding="utf-8")) == {"a": 1, "b": 2}
    assert output_path.read_text(encoding="utf-8").splitlines()[1].startswith('  "a"')


def test_main_json_format_is_parseable(monkeypatch, capsys, tmp_path):
    monkeypatch.chdir(tmp_path)
    monkeypatch.setattr(
        cse_status,
        "collect_status",
        lambda repo_root, run_tests, upstream_ref: {"schema_version": 1, "repo_root": str(repo_root)},
    )

    result = cse_status.main(["--format", "json"])

    assert result == 0
    assert json.loads(capsys.readouterr().out) == {
        "schema_version": 1,
        "repo_root": str(tmp_path.resolve()),
    }


def test_default_command_does_not_write_state(monkeypatch, tmp_path):
    writes = []
    monkeypatch.chdir(tmp_path)
    monkeypatch.setattr(
        cse_status,
        "collect_status",
        lambda repo_root, run_tests, upstream_ref: {"schema_version": 1},
    )
    monkeypatch.setattr(
        cse_status,
        "write_json_output",
        lambda report, output_path, overwrite: writes.append(output_path),
    )

    result = cse_status.main(["--format", "json"])

    assert result == 0
    assert writes == []


def test_finalize_state_requires_explicit_metadata(monkeypatch, capsys, tmp_path):
    monkeypatch.chdir(tmp_path)

    result = cse_status.main(["--finalize-state"])

    captured = capsys.readouterr()
    assert result == 2
    assert "Missing required finalization metadata" in captured.err
    assert "state-output" in captured.err


def test_finalize_state_refuses_to_overwrite_without_flag(monkeypatch, tmp_path):
    output_path = tmp_path / "project_state.json"
    output_path.write_text("old", encoding="utf-8")
    monkeypatch.chdir(tmp_path)

    result = cse_status.main(
        [
            "--finalize-state",
            "--step",
            "194",
            "--issue",
            "3",
            "--pull-request",
            "4",
            "--issue-state",
            "closed",
            "--pull-request-state",
            "merged",
            "--source-branch",
            "step-194-cse-status-report",
            "--base-branch",
            "master",
            "--merge-commit",
            "de95bc0ed7f3115bba80d4410dfa2f518fb6bfe1",
            "--verification-summary",
            "tests passed",
            "--next-action",
            "start next task",
            "--state-output",
            str(output_path),
        ]
    )

    assert result == 2
    assert output_path.read_text(encoding="utf-8") == "old"


def test_build_finalized_state_is_deterministic_and_explicit(monkeypatch, tmp_path):
    args = cse_status.build_parser().parse_args(
        [
            "--finalize-state",
            "--step",
            "194",
            "--issue",
            "3",
            "--pull-request",
            "4",
            "--issue-state",
            "closed",
            "--pull-request-state",
            "merged",
            "--source-branch",
            "step-194-cse-status-report",
            "--base-branch",
            "master",
            "--merge-commit",
            "de95bc0ed7f3115bba80d4410dfa2f518fb6bfe1",
            "--verification-summary",
            "406 passed",
            "--next-action",
            "start step 195",
            "--state-output",
            str(tmp_path / "state.json"),
            "--overwrite",
        ]
    )
    monkeypatch.setattr(cse_status, "collect_exports", lambda repo_root: {"clean": True})
    monkeypatch.setattr(cse_status, "collect_zip_files", lambda repo_root: {"count": 0})
    monkeypatch.setattr(cse_status, "collect_head", lambda repo_root: {"branch": "master"})
    monkeypatch.setattr(
        cse_status,
        "collect_divergence",
        lambda repo_root, upstream_ref: {"available": True, "ahead": 0, "behind": 0},
    )
    monkeypatch.setattr(
        cse_status,
        "collect_git_lists",
        lambda repo_root: {"staged_files": [], "tracked_worktree_changes": []},
    )

    state = cse_status.build_finalized_state(args, tmp_path, "origin/master")

    assert state["workflow_status"] == "merged_finalized"
    assert state["merge_authorized"] is True
    assert state["remote_state_source"] == "explicit_cli_metadata"
    assert state["pull_request_state"] == "merged"
    assert state["verification"] == {"summary": "406 passed"}
    assert json.dumps(state, sort_keys=True) == json.dumps(state, sort_keys=True)


def test_finalize_state_writes_parseable_json_with_overwrite(monkeypatch, tmp_path):
    output_path = tmp_path / "project_state.json"
    output_path.write_text("old", encoding="utf-8")
    monkeypatch.chdir(tmp_path)
    monkeypatch.setattr(cse_status, "collect_exports", lambda repo_root: {"clean": True})
    monkeypatch.setattr(cse_status, "collect_zip_files", lambda repo_root: {"count": 0})
    monkeypatch.setattr(cse_status, "collect_head", lambda repo_root: {"branch": "master"})
    monkeypatch.setattr(
        cse_status,
        "collect_divergence",
        lambda repo_root, upstream_ref: {"available": True, "ahead": 0, "behind": 0},
    )
    monkeypatch.setattr(
        cse_status,
        "collect_git_lists",
        lambda repo_root: {"staged_files": [], "tracked_worktree_changes": []},
    )

    result = cse_status.main(
        [
            "--finalize-state",
            "--step",
            "194",
            "--issue",
            "3",
            "--pull-request",
            "4",
            "--issue-state",
            "closed",
            "--pull-request-state",
            "merged",
            "--source-branch",
            "step-194-cse-status-report",
            "--base-branch",
            "master",
            "--merge-commit",
            "de95bc0ed7f3115bba80d4410dfa2f518fb6bfe1",
            "--verification-summary",
            "tests passed",
            "--next-action",
            "start next task",
            "--state-output",
            str(output_path),
            "--overwrite",
        ]
    )

    assert result == 0
    state = json.loads(output_path.read_text(encoding="utf-8"))
    assert state["step"] == 194
    assert state["pull_request_state"] == "merged"


def test_finalize_state_uses_no_git_mutation_commands(monkeypatch, tmp_path):
    calls = []

    def fake_run(args, cwd):
        calls.append(args)
        if args[:3] == ["git", "branch", "--show-current"]:
            return command(args, stdout="master\n")
        if args[:3] == ["git", "log", "-1"]:
            return command(args, stdout="abc123\x00Subject\n")
        if args[:3] == ["git", "rev-parse", "--verify"]:
            return command(args, stdout="base\n")
        if args[:3] == ["git", "rev-list", "--left-right"]:
            return command(args, stdout="0\t0\n")
        return command(args)

    args = cse_status.build_parser().parse_args(
        [
            "--finalize-state",
            "--step",
            "194",
            "--issue",
            "3",
            "--pull-request",
            "4",
            "--issue-state",
            "closed",
            "--pull-request-state",
            "merged",
            "--source-branch",
            "step-194-cse-status-report",
            "--base-branch",
            "master",
            "--merge-commit",
            "de95bc0ed7f3115bba80d4410dfa2f518fb6bfe1",
            "--verification-summary",
            "tests passed",
            "--next-action",
            "start next task",
            "--state-output",
            str(tmp_path / "state.json"),
        ]
    )
    monkeypatch.setattr(cse_status, "run_command", fake_run)

    cse_status.build_finalized_state(args, tmp_path, "origin/master")

    forbidden = {"add", "commit", "push", "merge", "checkout", "switch", "clean", "reset"}
    assert not any(call[0] == "git" and call[1] in forbidden for call in calls)


def test_finalize_state_does_not_mutate_exports_or_zip_files(monkeypatch, tmp_path):
    exports = tmp_path / "exports"
    exports.mkdir()
    gitkeep = exports / ".gitkeep"
    gitkeep.write_text("\n", encoding="utf-8")
    zip_file = tmp_path / "backup.zip"
    zip_file.write_text("zip", encoding="utf-8")
    before = {
        gitkeep: gitkeep.read_text(encoding="utf-8"),
        zip_file: zip_file.read_text(encoding="utf-8"),
    }
    args = cse_status.build_parser().parse_args(
        [
            "--finalize-state",
            "--step",
            "194",
            "--issue",
            "3",
            "--pull-request",
            "4",
            "--issue-state",
            "closed",
            "--pull-request-state",
            "merged",
            "--source-branch",
            "step-194-cse-status-report",
            "--base-branch",
            "master",
            "--merge-commit",
            "de95bc0ed7f3115bba80d4410dfa2f518fb6bfe1",
            "--verification-summary",
            "tests passed",
            "--next-action",
            "start next task",
            "--state-output",
            str(tmp_path / "state.json"),
        ]
    )
    monkeypatch.setattr(cse_status, "collect_head", lambda repo_root: {})
    monkeypatch.setattr(cse_status, "collect_divergence", lambda repo_root, upstream_ref: {})
    monkeypatch.setattr(cse_status, "collect_git_lists", lambda repo_root: {})

    cse_status.build_finalized_state(args, tmp_path, "origin/master")

    assert gitkeep.read_text(encoding="utf-8") == before[gitkeep]
    assert zip_file.read_text(encoding="utf-8") == before[zip_file]
