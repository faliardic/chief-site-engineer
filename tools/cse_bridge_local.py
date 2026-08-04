"""Windows-local scheduler entry point for the CSE OpenAI API bridge.

This module polls GitHub for one approved task, creates a repository-external
Git worktree, and delegates the coding pass to :mod:`tools.cse_api_bridge`.
The canonical checkout is never switched to a task branch.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Callable, Mapping, Sequence

from tools.cse_api_bridge import BridgeError, GitHubClient, execute, parse_task
from tools.cse_bridge_poll import select_task

DEFAULT_REPOSITORY = "faliardic/chief-site-engineer"
DEFAULT_REPO_ROOT = Path(r"V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer")
LOCK_NAME = "worker.lock"
STATUS_NAME = "worker-status.json"


@dataclass(frozen=True)
class CommandResult:
    returncode: int
    stdout: str = ""
    stderr: str = ""


CommandAdapter = Callable[[Sequence[str], Path, int], CommandResult]
PidChecker = Callable[[int], bool]


def default_runtime_root() -> Path:
    local_app_data = os.environ.get("LOCALAPPDATA")
    if local_app_data:
        return Path(local_app_data) / "CSE-Bridge"
    return Path.home() / ".cse-bridge"


def run_command(argv: Sequence[str], cwd: Path, timeout: int = 120) -> CommandResult:
    try:
        completed = subprocess.run(
            list(argv),
            cwd=cwd,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8",
            errors="replace",
            shell=False,
            timeout=timeout,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise BridgeError("local_command_unavailable") from exc
    return CommandResult(completed.returncode, completed.stdout, completed.stderr)


def require_success(result: CommandResult, reason: str) -> str:
    if result.returncode != 0:
        raise BridgeError(reason)
    return result.stdout.strip()


def normalize_origin(value: str) -> str:
    cleaned = value.strip().removesuffix(".git")
    prefixes = (
        "https://github.com/",
        "http://github.com/",
        "ssh://git@github.com/",
        "git@github.com:",
    )
    for prefix in prefixes:
        if cleaned.startswith(prefix):
            cleaned = cleaned[len(prefix) :]
            break
    return cleaned.strip("/")


def validate_repository(
    repo_root: Path,
    repository: str,
    command: CommandAdapter = run_command,
) -> None:
    root = repo_root.resolve()
    top = require_success(
        command(("git", "rev-parse", "--show-toplevel"), root, 30),
        "canonical_repository_invalid",
    )
    if Path(top).resolve() != root:
        raise BridgeError("canonical_repository_mismatch")
    origin = require_success(
        command(("git", "remote", "get-url", "origin"), root, 30),
        "origin_unavailable",
    )
    if normalize_origin(origin).casefold() != repository.casefold():
        raise BridgeError("origin_repository_mismatch")


def resolve_github_token(
    repo_root: Path,
    command: CommandAdapter = run_command,
) -> str:
    configured = os.environ.get("GITHUB_TOKEN", "").strip()
    if configured:
        return configured
    token = require_success(
        command(("gh", "auth", "token"), repo_root, 30),
        "github_auth_missing",
    )
    if not token:
        raise BridgeError("github_auth_missing")
    return token


def pid_is_alive(pid: int) -> bool:
    if pid <= 0:
        return False
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    except OSError:
        return False
    return True


def write_status(
    runtime_root: Path,
    state: str,
    exit_code: int | None,
    reason: str | None = None,
) -> None:
    runtime = runtime_root.resolve()
    runtime.mkdir(parents=True, exist_ok=True)
    payload = {
        "state": state,
        "exit_code": exit_code,
        "reason": reason,
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }
    destination = runtime / STATUS_NAME
    temporary = destination.with_suffix(".tmp")
    temporary.write_text(
        json.dumps(payload, ensure_ascii=False, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    os.replace(temporary, destination)


class SingleInstanceLock:
    def __init__(self, path: Path, checker: PidChecker = pid_is_alive):
        self.path = path
        self.checker = checker
        self.fd: int | None = None

    def _existing_pid(self) -> int | None:
        try:
            raw = self.path.read_text(encoding="ascii").strip()
            return int(raw)
        except (OSError, UnicodeError, ValueError):
            return None

    def __enter__(self) -> "SingleInstanceLock":
        self.path.parent.mkdir(parents=True, exist_ok=True)
        for _ in range(2):
            try:
                self.fd = os.open(
                    self.path,
                    os.O_CREAT | os.O_EXCL | os.O_WRONLY,
                    0o600,
                )
            except FileExistsError as exc:
                existing_pid = self._existing_pid()
                if existing_pid is None or self.checker(existing_pid):
                    raise BridgeError("bridge_already_running") from exc
                try:
                    self.path.unlink()
                except FileNotFoundError:
                    pass
                continue
            os.write(self.fd, str(os.getpid()).encode("ascii"))
            return self
        raise BridgeError("bridge_already_running")

    def __exit__(self, exc_type, exc, tb) -> None:  # type: ignore[no-untyped-def]
        if self.fd is not None:
            os.close(self.fd)
            self.fd = None
        try:
            self.path.unlink()
        except FileNotFoundError:
            pass


def task_worktree(runtime_root: Path, issue_number: int) -> Path:
    return runtime_root.resolve() / "worktrees" / f"issue-{issue_number}"


def _remote_branch_exists(
    repo_root: Path,
    branch: str,
    command: CommandAdapter,
) -> bool:
    result = command(
        ("git", "ls-remote", "--exit-code", "--heads", "origin", branch),
        repo_root,
        60,
    )
    if result.returncode not in {0, 2}:
        raise BridgeError("remote_branch_check_failed")
    return result.returncode == 0


def create_worktree(
    repo_root: Path,
    runtime_root: Path,
    issue_number: int,
    base: str,
    branch: str,
    command: CommandAdapter = run_command,
) -> Path:
    root = repo_root.resolve()
    worktree = task_worktree(runtime_root, issue_number)
    if worktree.exists():
        raise BridgeError("bridge_worktree_already_exists")
    if _remote_branch_exists(root, branch, command):
        raise BridgeError("task_branch_already_exists")
    require_success(
        command(("git", "fetch", "origin", base, "--prune"), root, 180),
        "base_fetch_failed",
    )
    worktree.parent.mkdir(parents=True, exist_ok=True)
    require_success(
        command(
            ("git", "worktree", "add", "--detach", str(worktree), f"origin/{base}"),
            root,
            180,
        ),
        "worktree_create_failed",
    )
    return worktree


def remove_successful_worktree(
    repo_root: Path,
    worktree: Path,
    branch: str,
    command: CommandAdapter = run_command,
) -> None:
    root = repo_root.resolve()
    require_success(
        command(("git", "worktree", "remove", "--force", str(worktree)), root, 120),
        "worktree_remove_failed",
    )
    result = command(("git", "branch", "-D", branch), root, 30)
    if result.returncode not in {0, 1}:
        raise BridgeError("local_branch_cleanup_failed")


def load_local_config(runtime_root: Path) -> Mapping[str, object]:
    config_path = runtime_root / "config.json"
    if not config_path.is_file():
        raise BridgeError("local_config_missing")
    try:
        value = json.loads(config_path.read_text(encoding="utf-8-sig"))
    except (OSError, json.JSONDecodeError) as exc:
        raise BridgeError("local_config_invalid") from exc
    if not isinstance(value, dict):
        raise BridgeError("local_config_invalid")
    return value


def run_once(
    repo_root: Path,
    runtime_root: Path,
    *,
    repository: str = DEFAULT_REPOSITORY,
    command: CommandAdapter = run_command,
) -> int:
    validate_repository(repo_root, repository, command)
    config = load_local_config(runtime_root)
    model = str(config.get("model", "")).strip()
    if not model:
        raise BridgeError("model_configuration_missing")
    if not os.environ.get("OPENAI_API_KEY", "").strip():
        raise BridgeError("openai_key_missing")

    token = resolve_github_token(repo_root, command)
    os.environ["GITHUB_REPOSITORY"] = repository
    os.environ["GITHUB_TOKEN"] = token
    os.environ["CSE_BRIDGE_MODEL"] = model
    os.environ.setdefault("CSE_BRIDGE_BASE", "master")

    github = GitHubClient(repository, token)
    issue_number = select_task(github)
    if issue_number is None:
        return 0
    issue = github.issue(issue_number)
    body = issue.get("body")
    if not isinstance(body, str):
        raise BridgeError("task_body_missing")
    task = parse_task(body)
    worktree = create_worktree(
        repo_root,
        runtime_root,
        issue_number,
        task.base,
        task.branch,
        command,
    )
    result = execute(issue_number, worktree)
    if result == 0:
        remove_successful_worktree(repo_root, worktree, task.branch, command)
    return result


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", type=Path, default=DEFAULT_REPO_ROOT)
    parser.add_argument("--runtime-root", type=Path, default=default_runtime_root())
    args = parser.parse_args(argv)
    runtime_root = args.runtime_root.resolve()
    write_status(runtime_root, "STARTING", None)
    try:
        with SingleInstanceLock(runtime_root / LOCK_NAME):
            write_status(runtime_root, "RUNNING", None)
            result = run_once(args.repo_root, runtime_root)
    except BridgeError as exc:
        if exc.reason == "bridge_already_running":
            write_status(runtime_root, "SKIPPED", 0, exc.reason)
            return 0
        write_status(runtime_root, "FAILED", 1, exc.reason)
        print(exc.reason, file=sys.stderr)
        return 1
    except Exception:
        write_status(runtime_root, "FAILED", 1, "unexpected_worker_failure")
        print("unexpected_worker_failure", file=sys.stderr)
        return 1
    if result == 0:
        write_status(runtime_root, "PASS", 0)
    else:
        write_status(runtime_root, "FAILED", result, f"worker_exit_{result}")
    return result


if __name__ == "__main__":
    raise SystemExit(main())
