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
