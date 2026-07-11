"""Read-only CSE handoff status reporter."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Sequence


@dataclass(frozen=True)
class CommandResult:
    args: list[str]
    returncode: int
    stdout: str
    stderr: str

    @property
    def ok(self) -> bool:
        return self.returncode == 0


def run_command(args: Sequence[str], cwd: Path) -> CommandResult:
    try:
        completed = subprocess.run(
            list(args),
            cwd=cwd,
            text=True,
            capture_output=True,
            check=False,
        )
    except FileNotFoundError as exc:
        return CommandResult(
            args=list(args),
            returncode=127,
            stdout="",
            stderr=str(exc),
        )

    return CommandResult(
        args=list(args),
        returncode=completed.returncode,
        stdout=completed.stdout,
        stderr=completed.stderr,
    )


def split_lines(value: str) -> list[str]:
    return [line.rstrip() for line in value.splitlines() if line.rstrip()]


def command_payload(result: CommandResult) -> dict[str, object]:
    return {
        "command": result.args,
        "returncode": result.returncode,
        "ok": result.ok,
        "stdout": split_lines(result.stdout),
        "stderr": split_lines(result.stderr),
    }


def first_line(result: CommandResult) -> str | None:
    lines = split_lines(result.stdout)
    return lines[0] if result.ok and lines else None


def collect_head(repo_root: Path) -> dict[str, object]:
    branch = run_command(["git", "branch", "--show-current"], repo_root)
    head = run_command(["git", "log", "-1", "--format=%H%x00%s"], repo_root)
    sha = None
    message = None
    if head.ok:
        raw = head.stdout.rstrip("\n")
        if "\x00" in raw:
            sha, message = raw.split("\x00", 1)

    return {
        "branch": first_line(branch),
        "commit": sha,
        "message": message,
        "commands": {
            "branch": command_payload(branch),
            "head": command_payload(head),
        },
    }


def collect_divergence(repo_root: Path, upstream_ref: str) -> dict[str, object]:
    verify = run_command(["git", "rev-parse", "--verify", upstream_ref], repo_root)
    if not verify.ok:
        return {
            "upstream": upstream_ref,
            "available": False,
            "ahead": None,
            "behind": None,
            "commands": {"verify": command_payload(verify)},
        }

    count = run_command(
        ["git", "rev-list", "--left-right", "--count", f"{upstream_ref}...HEAD"],
        repo_root,
    )
    ahead = None
    behind = None
    if count.ok:
        parts = count.stdout.strip().split()
        if len(parts) == 2 and all(part.isdigit() for part in parts):
            behind = int(parts[0])
            ahead = int(parts[1])

    return {
        "upstream": upstream_ref,
        "available": True,
        "ahead": ahead,
        "behind": behind,
        "commands": {
            "verify": command_payload(verify),
            "count": command_payload(count),
        },
    }


def collect_git_lists(repo_root: Path) -> dict[str, object]:
    staged = run_command(["git", "diff", "--name-status", "--cached"], repo_root)
    tracked = run_command(["git", "diff", "--name-status"], repo_root)
    status_ignored = run_command(
        ["git", "status", "--ignored", "--short", "--untracked-files=all"],
        repo_root,
    )
    ignored_files = [
        line[3:]
        for line in split_lines(status_ignored.stdout)
        if line.startswith("!! ")
    ]
    untracked_files = [
        line[3:]
        for line in split_lines(status_ignored.stdout)
        if line.startswith("?? ")
    ]

    return {
        "staged_files": split_lines(staged.stdout) if staged.ok else [],
        "tracked_worktree_changes": split_lines(tracked.stdout) if tracked.ok else [],
        "untracked_files": untracked_files if status_ignored.ok else [],
        "ignored_files": ignored_files if status_ignored.ok else [],
        "commands": {
            "staged": command_payload(staged),
            "tracked": command_payload(tracked),
            "ignored": command_payload(status_ignored),
        },
    }


def collect_diff_check(repo_root: Path) -> dict[str, object]:
    result = run_command(["git", "diff", "--check"], repo_root)
    return command_payload(result)


def relative_paths(paths: Iterable[Path], repo_root: Path) -> list[str]:
    values = []
    for path in paths:
        try:
            relative = path.relative_to(repo_root)
        except ValueError:
            continue
        values.append(relative.as_posix())
    return sorted(values)


def collect_exports(repo_root: Path) -> dict[str, object]:
    exports_dir = repo_root / "exports"
    if not exports_dir.exists():
        return {
            "exists": False,
            "contents": [],
            "clean": False,
            "expected_only": [".gitkeep"],
        }

    contents = relative_paths(
        (path for path in exports_dir.rglob("*") if path.is_file()),
        exports_dir,
    )
    return {
        "exists": True,
        "contents": contents,
        "clean": contents == [".gitkeep"],
        "expected_only": [".gitkeep"],
    }


def collect_zip_files(repo_root: Path) -> dict[str, object]:
    zip_files = relative_paths(
        (
            path
            for path in repo_root.rglob("*.zip")
            if ".git" not in path.relative_to(repo_root).parts
        ),
        repo_root,
    )
    return {
        "count": len(zip_files),
        "files": zip_files,
    }


def collect_pytest(repo_root: Path, run_tests: bool) -> dict[str, object]:
    if not run_tests:
        return {
            "requested": False,
            "command": [sys.executable, "-m", "pytest"],
            "returncode": None,
            "ok": None,
            "stdout": [],
            "stderr": [],
        }

    result = run_command([sys.executable, "-m", "pytest"], repo_root)
    payload = command_payload(result)
    payload["requested"] = True
    return payload


def collect_status(repo_root: Path, run_tests: bool, upstream_ref: str) -> dict[str, object]:
    return {
        "schema_version": 1,
        "repo_root": str(repo_root),
        "head": collect_head(repo_root),
        "divergence": collect_divergence(repo_root, upstream_ref),
        "git": collect_git_lists(repo_root),
        "diff_check": collect_diff_check(repo_root),
        "exports": collect_exports(repo_root),
        "zip_files": collect_zip_files(repo_root),
        "pytest": collect_pytest(repo_root, run_tests),
    }


FINALIZE_REQUIRED_ARGS = (
    "step",
    "issue",
    "pull_request",
    "issue_state",
    "pull_request_state",
    "source_branch",
    "base_branch",
    "merge_commit",
    "verification_summary",
    "next_action",
    "state_output",
)


def validate_finalize_args(args: argparse.Namespace) -> list[str]:
    missing = []
    for name in FINALIZE_REQUIRED_ARGS:
        value = getattr(args, name)
        if value is None or value == "":
            missing.append(name.replace("_", "-"))
    return missing


def build_finalized_state(
    args: argparse.Namespace,
    repo_root: Path,
    upstream_ref: str,
) -> dict[str, object]:
    return {
        "protocol_version": 1,
        "step": args.step,
        "finalized_step": args.step,
        "issue": args.issue,
        "issue_state": args.issue_state,
        "pull_request": args.pull_request,
        "pull_request_state": args.pull_request_state,
        "source_branch": args.source_branch,
        "base_branch": args.base_branch,
        "merge_commit": args.merge_commit,
        "workflow_status": "merged_finalized",
        "merge_authorized": True,
        "remote_state_source": "explicit_cli_metadata",
        "verification": {
            "summary": args.verification_summary,
        },
        "exports": collect_exports(repo_root),
        "zip_files": collect_zip_files(repo_root),
        "local_git_evidence": {
            "head": collect_head(repo_root),
            "divergence": collect_divergence(repo_root, upstream_ref),
            "git": collect_git_lists(repo_root),
            "note": "Local evidence only; remote PR and issue state came from explicit CLI metadata.",
        },
        "next_action": args.next_action,
    }


def render_text(report: dict[str, object]) -> str:
    head = report["head"]
    divergence = report["divergence"]
    git_info = report["git"]
    diff_check = report["diff_check"]
    exports = report["exports"]
    zip_files = report["zip_files"]
    pytest = report["pytest"]

    assert isinstance(head, dict)
    assert isinstance(divergence, dict)
    assert isinstance(git_info, dict)
    assert isinstance(diff_check, dict)
    assert isinstance(exports, dict)
    assert isinstance(zip_files, dict)
    assert isinstance(pytest, dict)

    divergence_text = "unavailable"
    if divergence.get("available"):
        divergence_text = (
            f"ahead {divergence.get('ahead')}, behind {divergence.get('behind')}"
        )

    pytest_text = "not run"
    if pytest.get("requested"):
        pytest_text = "passed" if pytest.get("ok") else "failed"

    lines = [
        "CSE Status",
        f"- Branch: {head.get('branch') or 'unknown'}",
        f"- HEAD: {head.get('commit') or 'unknown'} {head.get('message') or ''}".rstrip(),
        f"- origin/master...HEAD: {divergence_text}",
        f"- Staged files: {len(git_info.get('staged_files', []))}",
        f"- Tracked worktree changes: {len(git_info.get('tracked_worktree_changes', []))}",
        f"- Untracked files: {len(git_info.get('untracked_files', []))}",
        f"- Ignored files visible: {len(git_info.get('ignored_files', []))}",
        f"- git diff --check: {'passed' if diff_check.get('ok') else 'failed'}",
        f"- exports/: {'clean' if exports.get('clean') else 'not clean'}",
        f"- ZIP files: {zip_files.get('count')}",
        f"- Pytest: {pytest_text}",
    ]
    return "\n".join(lines)


def write_json_output(report: dict[str, object], output_path: Path, overwrite: bool) -> None:
    if output_path.exists() and not overwrite:
        raise FileExistsError(
            f"{output_path} already exists; pass --overwrite to replace it"
        )
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Report local CSE handoff status.")
    parser.add_argument(
        "--run-tests",
        action="store_true",
        help="Run python -m pytest and include the result.",
    )
    parser.add_argument(
        "--format",
        choices=("both", "text", "json"),
        default="both",
        help="Choose terminal output format. Default emits text and JSON.",
    )
    parser.add_argument(
        "--json-output",
        type=Path,
        help="Optional path for writing the JSON report.",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Allow --json-output to replace an existing file.",
    )
    parser.add_argument(
        "--upstream-ref",
        default="origin/master",
        help="Remote ref used for divergence reporting.",
    )
    parser.add_argument(
        "--finalize-state",
        action="store_true",
        help="Write an explicit post-merge finalized state JSON.",
    )
    parser.add_argument("--step", type=int, help="Finalized step number.")
    parser.add_argument("--issue", type=int, help="Issue number for the finalized step.")
    parser.add_argument(
        "--pull-request",
        type=int,
        help="Pull request number for the finalized step.",
    )
    parser.add_argument(
        "--issue-state",
        choices=("closed", "completed"),
        help="Explicit issue state supplied by the user.",
    )
    parser.add_argument(
        "--pull-request-state",
        choices=("merged",),
        help="Explicit pull request state supplied by the user.",
    )
    parser.add_argument(
        "--source-branch",
        "--merged-branch",
        dest="source_branch",
        help="Branch that was merged.",
    )
    parser.add_argument("--base-branch", help="Base branch that received the merge.")
    parser.add_argument("--merge-commit", help="Merge commit SHA supplied by the user.")
    parser.add_argument(
        "--verification-summary",
        help="Explicit verification and test summary for the finalized state.",
    )
    parser.add_argument(
        "--next-action",
        help="Recommended next action after finalization.",
    )
    parser.add_argument(
        "--state-output",
        type=Path,
        help="Explicit path for writing finalized project state JSON.",
    )
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    repo_root = Path.cwd().resolve()

    if args.finalize_state:
        missing = validate_finalize_args(args)
        if missing:
            print(
                "Missing required finalization metadata: " + ", ".join(missing),
                file=sys.stderr,
            )
            return 2
        report = build_finalized_state(args, repo_root, args.upstream_ref)
        try:
            write_json_output(report, args.state_output, args.overwrite)
        except FileExistsError as exc:
            print(str(exc), file=sys.stderr)
            return 2
        print(json.dumps(report, indent=2, sort_keys=True))
        return 0

    report = collect_status(repo_root, args.run_tests, args.upstream_ref)

    if args.json_output is not None:
        try:
            write_json_output(report, args.json_output, args.overwrite)
        except FileExistsError as exc:
            print(str(exc), file=sys.stderr)
            return 2

    json_text = json.dumps(report, indent=2, sort_keys=True)
    if args.format in {"both", "text"}:
        print(render_text(report))
    if args.format == "both":
        print("\nJSON:")
    if args.format in {"both", "json"}:
        print(json_text)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
