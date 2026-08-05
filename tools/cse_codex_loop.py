"""Run one approved CSE Issue through a local Codex implement/review loop.

Codex edits only a repository-external worktree.  Scope checks, validation,
Git publication, GitHub comments, and cleanup remain deterministic host work.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import time
import uuid
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable, Mapping, Sequence

from tools.cse_api_bridge import (
    BridgeError,
    BridgeTask,
    GitHubClient,
    parse_task,
    path_allowed,
    terminal_state,
    validate_command,
)
from tools.cse_bridge_poll import task_ready

DEFAULT_REPOSITORY = "faliardic/chief-site-engineer"
TASK_NAME = "CSE Codex Loop"
STATUS_NAME = "worker-status.json"
RUN_STATUS_NAME = "status.json"
RUN_STDOUT_NAME = "stdout.log"
RUN_STDERR_NAME = "stderr.log"
REVIEW_SCHEMA_NAME = "review-schema.json"
REVIEW_RESULT_NAME = "review-result.json"
PASS_MARKER = "<!-- cse-bridge-status:PASS -->"
FAILED_MARKER = "<!-- cse-bridge-status:FAILED -->"
NEEDS_HUMAN_MARKER = "<!-- cse-bridge-status:NEEDS_HUMAN -->"
RUNNING_MARKER = "<!-- cse-bridge-status:RUNNING -->"
WORKTREE_REMOVE_ATTEMPTS = 3
WORKTREE_CLEANUP_RETRY_SECONDS = 0.2

_SECRET_PATTERNS = (
    re.compile(r"(?i)authorization\s*:\s*bearer\s+\S+"),
    re.compile(r"(?i)(?:api[_-]?key|token|secret|password)\s*[:=]\s*\S+"),
    re.compile(r"\bsk-[A-Za-z0-9_-]{12,}\b"),
    re.compile(r"\bgh[pousr]_[A-Za-z0-9_]{12,}\b"),
    re.compile(r"\bgithub_pat_[A-Za-z0-9_]{12,}\b", re.IGNORECASE),
)
_SAFE_REASON = re.compile(r"^[a-z0-9_]{1,80}$")


@dataclass(frozen=True)
class CommandResult:
    returncode: int
    stdout: str = ""
    stderr: str = ""


CommandAdapter = Callable[[Sequence[str], Path, int, str | None], CommandResult]


@dataclass(frozen=True)
class LoopConfig:
    repository: str
    repo_root: Path
    codex_path: Path
    git_path: Path
    gh_path: Path
    python_path: Path
    allowed_base: str = "master"
    max_runs: int = 20
    flutter_path: Path | None = None


@dataclass(frozen=True)
class ReviewResult:
    verdict: str
    summary: str
    findings: tuple[str, ...]


@dataclass(frozen=True)
class PublicationResult:
    pr: Mapping[str, Any]
    commit: str


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def new_run_id() -> str:
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    return f"{timestamp}-{uuid.uuid4().hex[:8]}"


def default_runtime_root() -> Path:
    local_app_data = os.environ.get("LOCALAPPDATA")
    if local_app_data:
        return Path(local_app_data) / "CSE-Codex-Loop"
    return Path.home() / ".cse-codex-loop"


def sanitize(value: str, *, sensitive: Sequence[str] = (), limit: int = 8000) -> str:
    cleaned = value
    for item in sensitive:
        if item:
            cleaned = cleaned.replace(item, "[REDACTED]")
    for pattern in _SECRET_PATTERNS:
        cleaned = pattern.sub("[REDACTED]", cleaned)
    return cleaned[:limit]


def _atomic_json(path: Path, payload: Mapping[str, object]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(
        json.dumps(payload, ensure_ascii=False, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    os.replace(temporary, path)


class RunArtifacts:
    """Data-minimal, issue-aware records for one invocation."""

    def __init__(self, runtime_root: Path, run_id: str, issue_number: int | None):
        self.runtime_root = runtime_root.resolve()
        self.run_id = run_id
        self.issue_number = issue_number
        self.run_root = self.runtime_root / "runs" / run_id
        self.run_root.mkdir(parents=True, exist_ok=False)
        (self.run_root / RUN_STDOUT_NAME).write_text("", encoding="utf-8")
        (self.run_root / RUN_STDERR_NAME).write_text("", encoding="utf-8")

    @classmethod
    def create(
        cls,
        runtime_root: Path,
        issue_number: int | None,
        *,
        max_runs: int = 20,
        run_id: str | None = None,
    ) -> "RunArtifacts":
        runtime = runtime_root.resolve()
        runtime.mkdir(parents=True, exist_ok=True)
        artifacts = cls(runtime, run_id or new_run_id(), issue_number)
        rotate_runs(runtime, max_runs=max_runs, keep=artifacts.run_root)
        artifacts.update("STARTING", "startup", None)
        return artifacts

    def set_issue(self, issue_number: int) -> None:
        self.issue_number = issue_number

    def update(
        self,
        state: str,
        phase: str,
        exit_code: int | None,
        reason: str | None = None,
    ) -> None:
        if reason is not None and not _SAFE_REASON.fullmatch(reason):
            reason = "unsafe_reason_rejected"
        payload: dict[str, object] = {
            "run_id": self.run_id,
            "issue_number": self.issue_number,
            "state": state,
            "phase": phase,
            "exit_code": exit_code,
            "reason": reason,
            "updated_at": utc_now(),
        }
        _atomic_json(self.run_root / RUN_STATUS_NAME, payload)
        _atomic_json(self.runtime_root / STATUS_NAME, payload)

    def record_command(
        self,
        stage: str,
        result: CommandResult,
        *,
        include_output: bool = False,
        sensitive: Sequence[str] = (),
    ) -> None:
        stdout = f"[{stage}] exit={result.returncode}\n"
        stderr = ""
        if include_output and result.stdout:
            stdout += sanitize(result.stdout, sensitive=sensitive) + "\n"
        if result.stderr:
            if include_output:
                stderr = sanitize(result.stderr, sensitive=sensitive) + "\n"
            elif result.returncode:
                stderr = f"[{stage}] command_failed\n"
        with (self.run_root / RUN_STDOUT_NAME).open("a", encoding="utf-8") as stream:
            stream.write(stdout)
        if stderr:
            with (self.run_root / RUN_STDERR_NAME).open(
                "a", encoding="utf-8"
            ) as stream:
                stream.write(stderr)


def rotate_runs(runtime_root: Path, *, max_runs: int, keep: Path | None = None) -> None:
    if max_runs < 1:
        raise BridgeError("run_rotation_invalid")
    runs_root = (runtime_root / "runs").resolve()
    runs_root.mkdir(parents=True, exist_ok=True)
    directories = sorted(
        (item for item in runs_root.iterdir() if item.is_dir()),
        key=lambda item: (item.stat().st_mtime_ns, item.name),
        reverse=True,
    )
    keep_resolved = keep.resolve() if keep is not None else None
    retained = 0
    for directory in directories:
        resolved = directory.resolve()
        if resolved.parent != runs_root:
            continue
        if keep_resolved is not None and resolved == keep_resolved:
            retained += 1
            continue
        if retained < max_runs:
            retained += 1
            continue
        shutil.rmtree(resolved)


def run_command(
    argv: Sequence[str],
    cwd: Path,
    timeout: int = 120,
    input_text: str | None = None,
) -> CommandResult:
    try:
        completed = subprocess.run(
            list(argv),
            cwd=cwd,
            input=input_text,
            stdin=subprocess.DEVNULL if input_text is None else None,
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


def _required_string(value: object, reason: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise BridgeError(reason)
    return value.strip()


def _exact_path(value: object, reason: str) -> Path:
    path = Path(_required_string(value, reason))
    if not path.is_absolute() or not path.is_file():
        raise BridgeError(reason)
    return path.resolve()


def _optional_exact_path(value: object, reason: str) -> Path | None:
    if value is None:
        return None
    return _exact_path(value, reason)


def load_config(runtime_root: Path) -> LoopConfig:
    path = runtime_root.resolve() / "config.json"
    try:
        value = json.loads(path.read_text(encoding="utf-8-sig"))
    except (OSError, json.JSONDecodeError) as exc:
        raise BridgeError("local_config_invalid") from exc
    if not isinstance(value, Mapping):
        raise BridgeError("local_config_invalid")
    repository = _required_string(value.get("repository"), "repository_invalid")
    repo_root = Path(
        _required_string(value.get("repo_root"), "repo_root_invalid")
    )
    if not repo_root.is_absolute() or not repo_root.is_dir():
        raise BridgeError("repo_root_invalid")
    max_runs = value.get("max_runs", 20)
    if not isinstance(max_runs, int) or not 1 <= max_runs <= 100:
        raise BridgeError("run_rotation_invalid")
    return LoopConfig(
        repository=repository,
        repo_root=repo_root.resolve(),
        codex_path=_exact_path(value.get("codex_path"), "codex_path_invalid"),
        git_path=_exact_path(value.get("git_path"), "git_path_invalid"),
        gh_path=_exact_path(value.get("gh_path"), "gh_path_invalid"),
        python_path=_exact_path(value.get("python_path"), "python_path_invalid"),
        allowed_base=_required_string(
            value.get("allowed_base", "master"), "allowed_base_invalid"
        ),
        max_runs=max_runs,
        flutter_path=_optional_exact_path(
            value.get("flutter_path"), "flutter_path_invalid"
        ),
    )


def _run_checked(
    argv: Sequence[str],
    cwd: Path,
    reason: str,
    command: CommandAdapter,
    artifacts: RunArtifacts,
    stage: str,
    *,
    timeout: int = 120,
    input_text: str | None = None,
    include_output: bool = False,
) -> CommandResult:
    result = command(argv, cwd, timeout, input_text)
    artifacts.record_command(
        stage,
        result,
        include_output=include_output,
        sensitive=(input_text,) if input_text is not None else (),
    )
    if result.returncode != 0:
        raise BridgeError(reason)
    return result


def validate_repository(
    config: LoopConfig,
    command: CommandAdapter,
    artifacts: RunArtifacts,
) -> None:
    result = _run_checked(
        (str(config.git_path), "rev-parse", "--show-toplevel"),
        config.repo_root,
        "canonical_repository_invalid",
        command,
        artifacts,
        "repository-root",
        timeout=30,
    )
    if Path(result.stdout.strip()).resolve() != config.repo_root:
        raise BridgeError("canonical_repository_mismatch")
    origin = _run_checked(
        (str(config.git_path), "remote", "get-url", "origin"),
        config.repo_root,
        "origin_unavailable",
        command,
        artifacts,
        "repository-origin",
        timeout=30,
    ).stdout.strip()
    normalized = origin.removesuffix(".git")
    for prefix in (
        "https://github.com/",
        "http://github.com/",
        "ssh://git@github.com/",
        "git@github.com:",
    ):
        if normalized.startswith(prefix):
            normalized = normalized[len(prefix) :]
            break
    if normalized.strip("/").casefold() != config.repository.casefold():
        raise BridgeError("origin_repository_mismatch")


def resolve_github_token(
    config: LoopConfig,
    command: CommandAdapter,
    artifacts: RunArtifacts,
) -> str:
    configured = os.environ.get("GITHUB_TOKEN", "").strip()
    if configured:
        return configured
    result = command(
        (str(config.gh_path), "auth", "token"), config.repo_root, 30, None
    )
    artifacts.record_command("github-auth", result, include_output=False)
    if result.returncode != 0 or not result.stdout.strip():
        raise BridgeError("github_auth_missing")
    return result.stdout.strip()


def select_approved_issue(github: GitHubClient) -> int | None:
    issues = github.request(
        "GET", f"/repos/{github.repository}/issues?state=open&per_page=100"
    )
    candidates: list[int] = []
    for issue in issues:
        number = issue.get("number")
        if isinstance(number, int) and task_ready(issue, github.comments(number)):
            candidates.append(number)
    return min(candidates) if candidates else None


def task_worktree(runtime_root: Path, issue_number: int) -> Path:
    return runtime_root.resolve() / "worktrees" / f"issue-{issue_number}"


def _git_result(
    config: LoopConfig,
    args: Sequence[str],
    cwd: Path,
    command: CommandAdapter,
    artifacts: RunArtifacts,
    stage: str,
    *,
    timeout: int = 120,
) -> CommandResult:
    result = command((str(config.git_path), *args), cwd, timeout, None)
    artifacts.record_command(stage, result, include_output=False)
    return result


def create_worktree(
    config: LoopConfig,
    runtime_root: Path,
    issue_number: int,
    task: BridgeTask,
    command: CommandAdapter,
    artifacts: RunArtifacts,
) -> Path:
    worktree = task_worktree(runtime_root, issue_number)
    try:
        worktree.resolve().relative_to(config.repo_root)
    except ValueError:
        pass
    else:
        raise BridgeError("worktree_not_external")
    if worktree.exists():
        raise BridgeError("worktree_conflict")
    local_branch = _git_result(
        config,
        ("show-ref", "--verify", "--quiet", f"refs/heads/{task.branch}"),
        config.repo_root,
        command,
        artifacts,
        "local-branch-check",
        timeout=30,
    )
    if local_branch.returncode == 0:
        raise BridgeError("branch_conflict")
    if local_branch.returncode not in {0, 1}:
        raise BridgeError("branch_check_failed")
    remote_branch = _git_result(
        config,
        ("ls-remote", "--exit-code", "--heads", "origin", task.branch),
        config.repo_root,
        command,
        artifacts,
        "remote-branch-check",
        timeout=60,
    )
    if remote_branch.returncode == 0:
        raise BridgeError("branch_conflict")
    if remote_branch.returncode not in {0, 2}:
        raise BridgeError("branch_check_failed")
    fetch = _git_result(
        config,
        ("fetch", "origin", task.base, "--prune"),
        config.repo_root,
        command,
        artifacts,
        "base-fetch",
        timeout=180,
    )
    if fetch.returncode != 0:
        raise BridgeError("base_fetch_failed")
    worktree.parent.mkdir(parents=True, exist_ok=True)
    added = _git_result(
        config,
        (
            "worktree",
            "add",
            "-b",
            task.branch,
            str(worktree),
            f"origin/{task.base}",
        ),
        config.repo_root,
        command,
        artifacts,
        "worktree-create",
        timeout=180,
    )
    if added.returncode != 0:
        raise BridgeError("worktree_create_failed")
    return worktree


def implementation_prompt(task: BridgeTask) -> str:
    writable = "\n".join(f"- {path}" for path in task.allowed_paths)
    commands = "\n".join(f"- {command}" for command in task.validation_commands)
    prompt = f"""Implement the approved CSE Issue in this worktree.

Goal:
{task.goal}

Writable paths:
{writable}

Host validation commands (the host will run these):
{commands}

Rules:
- Modify only the writable paths.
- Keep the implementation narrow and preserve existing behavior.
- Do not commit, push, open a PR, merge, or contact GitHub.
- Do not use network, credentials, devices, ADB, release, backup, restore, or user data.
- Do not read secret files. The deterministic host owns scope and validation gates.
"""
    if len(prompt) > 28_000:
        raise BridgeError("codex_prompt_too_large")
    return prompt


def correction_prompt(task: BridgeTask, review: ReviewResult) -> str:
    findings = "\n".join(f"- {item}" for item in review.findings)
    writable = "\n".join(f"- {path}" for path in task.allowed_paths)
    prompt = f"""Apply the one permitted correction pass in this worktree.

Reviewer summary:
{review.summary}

Actionable findings:
{findings}

Writable paths:
{writable}

Fix only these findings. Do not commit, push, use network, access credentials,
devices, release operations, backup/restore, or user data. The host will repeat
scope, validation, and independent review exactly once.
"""
    if len(prompt) > 16_000:
        raise BridgeError("correction_prompt_too_large")
    return prompt


def run_codex_pass(
    config: LoopConfig,
    worktree: Path,
    prompt: str,
    command: CommandAdapter,
    artifacts: RunArtifacts,
    *,
    correction: bool = False,
) -> None:
    stage = "codex-correction" if correction else "codex-implementer"
    result = command(
        (
            str(config.codex_path),
            "exec",
            "--ephemeral",
            "--sandbox",
            "workspace-write",
            "-C",
            str(worktree),
            "-",
        ),
        worktree,
        3600,
        prompt,
    )
    artifacts.record_command(stage, result, include_output=False, sensitive=(prompt,))
    if result.returncode != 0:
        raise BridgeError(
            "codex_correction_failed" if correction else "codex_implementer_failed"
        )


def changed_paths(
    config: LoopConfig,
    worktree: Path,
    command: CommandAdapter,
    artifacts: RunArtifacts,
) -> tuple[str, ...]:
    result = _git_result(
        config,
        ("status", "--porcelain=v1", "--untracked-files=all"),
        worktree,
        command,
        artifacts,
        "scope-status",
        timeout=30,
    )
    if result.returncode != 0:
        raise BridgeError("scope_status_failed")
    paths: set[str] = set()
    for line in result.stdout.splitlines():
        if len(line) < 4:
            continue
        path = line[3:]
        if " -> " in path:
            path = path.split(" -> ", 1)[1]
        paths.add(path.replace("\\", "/"))
    return tuple(sorted(paths))


def enforce_scope(
    config: LoopConfig,
    worktree: Path,
    task: BridgeTask,
    command: CommandAdapter,
    artifacts: RunArtifacts,
) -> tuple[str, ...]:
    paths = changed_paths(config, worktree, command, artifacts)
    if not paths:
        raise BridgeError("no_changes_produced")
    for path in paths:
        if not path_allowed(path, task.allowed_paths):
            raise BridgeError("scope_violation")
    return paths


def _validation_argv(config: LoopConfig, command_text: str) -> tuple[str, ...]:
    argv = validate_command(command_text)
    executable = Path(argv[0]).name.casefold()
    if executable in {"python", "python.exe", "py", "py.exe"}:
        return (str(config.python_path), *argv[1:])
    if executable in {"git", "git.exe"}:
        return (str(config.git_path), *argv[1:])
    if executable in {"flutter", "flutter.bat"}:
        if config.flutter_path is None:
            raise BridgeError("validation_executable_unconfigured")
        return (str(config.flutter_path), *argv[1:])
    raise BridgeError("validation_executable_unconfigured")


def run_validations(
    config: LoopConfig,
    worktree: Path,
    task: BridgeTask,
    command: CommandAdapter,
    artifacts: RunArtifacts,
) -> None:
    for index, command_text in enumerate(task.validation_commands, start=1):
        result = command(
            _validation_argv(config, command_text), worktree, 1200, None
        )
        artifacts.record_command(
            f"validation-{index}", result, include_output=False
        )
        if result.returncode != 0:
            raise BridgeError("validation_failed")


def _review_schema() -> dict[str, object]:
    return {
        "type": "object",
        "properties": {
            "verdict": {
                "type": "string",
                "enum": ["approved", "changes_requested", "needs_human"],
            },
            "summary": {"type": "string"},
            "findings": {"type": "array", "items": {"type": "string"}},
        },
        "required": ["verdict", "summary", "findings"],
        "additionalProperties": False,
    }


def parse_review(value: object) -> ReviewResult:
    if not isinstance(value, Mapping):
        raise BridgeError("structured_review_invalid")
    verdict = value.get("verdict")
    summary = value.get("summary")
    raw_findings = value.get("findings")
    if verdict not in {"approved", "changes_requested", "needs_human"}:
        raise BridgeError("structured_review_invalid")
    if not isinstance(summary, str) or not summary.strip() or len(summary) > 4000:
        raise BridgeError("structured_review_invalid")
    if not isinstance(raw_findings, list) or len(raw_findings) > 50:
        raise BridgeError("structured_review_invalid")
    findings: list[str] = []
    for item in raw_findings:
        if isinstance(item, str):
            finding = item.strip()
        elif isinstance(item, Mapping):
            finding = json.dumps(item, ensure_ascii=False, sort_keys=True)
        else:
            raise BridgeError("structured_review_invalid")
        if not finding or len(finding) > 2000:
            raise BridgeError("structured_review_invalid")
        findings.append(finding)
    if verdict == "changes_requested" and not findings:
        raise BridgeError("structured_review_invalid")
    return ReviewResult(str(verdict), summary.strip(), tuple(findings))


def review_prompt(task: BridgeTask, changed_paths: Sequence[str]) -> str:
    writable = "\n".join(f"- {path}" for path in task.allowed_paths)
    changed = "\n".join(f"- {path}" for path in changed_paths)
    validations = "\n".join(
        f"- PASS: {command}" for command in task.validation_commands
    )
    prompt = f"""Independently review the uncommitted changes in this worktree.

Issue goal, constraints, and acceptance criteria:
{task.goal}

Allowed paths:
{writable}

Host-observed changed paths:
{changed}

Data-minimal host validation summary:
{validations}

Review rules:
- Work read-only and inspect the uncommitted diff against the complete Issue contract.
- Verify scope, correctness, regressions, and whether the acceptance criteria are met.
- Treat the host summary only as evidence that the listed deterministic commands passed.
- Return only the required structured verdict, summary, and actionable findings.
- Use verdict needs_human when the contract cannot be verified safely from this worktree.
"""
    if len(prompt) > 28_000:
        raise BridgeError("review_prompt_too_large")
    return prompt


def run_review(
    config: LoopConfig,
    worktree: Path,
    task: BridgeTask,
    changed_paths: Sequence[str],
    command: CommandAdapter,
    artifacts: RunArtifacts,
    *,
    round_number: int,
) -> ReviewResult:
    schema_path = artifacts.run_root / REVIEW_SCHEMA_NAME
    result_path = artifacts.run_root / REVIEW_RESULT_NAME
    schema_path.write_text(
        json.dumps(_review_schema(), ensure_ascii=False, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    try:
        result_path.unlink()
    except FileNotFoundError:
        pass
    prompt = review_prompt(task, changed_paths)
    result = command(
        (
            str(config.codex_path),
            "exec",
            "--ephemeral",
            "--sandbox",
            "read-only",
            "-C",
            str(worktree),
            "--output-schema",
            str(schema_path),
            "--output-last-message",
            str(result_path),
            "-",
        ),
        worktree,
        1800,
        prompt,
    )
    artifacts.record_command(
        f"codex-review-{round_number}", result, sensitive=(prompt,)
    )
    if result.returncode != 0:
        raise BridgeError("codex_review_failed")
    try:
        raw = result_path.read_text(encoding="utf-8")
    except OSError:
        raw = result.stdout
    finally:
        try:
            result_path.unlink()
        except FileNotFoundError:
            pass
    try:
        value = json.loads(raw.strip())
    except json.JSONDecodeError as exc:
        raise BridgeError("structured_review_invalid") from exc
    return parse_review(value)


def publish(
    config: LoopConfig,
    worktree: Path,
    task: BridgeTask,
    github: GitHubClient,
    command: CommandAdapter,
    artifacts: RunArtifacts,
) -> PublicationResult:
    paths = enforce_scope(config, worktree, task, command, artifacts)
    add = _git_result(
        config,
        ("add", "-A"),
        worktree,
        command,
        artifacts,
        "git-add",
        timeout=60,
    )
    if add.returncode != 0:
        raise BridgeError("git_add_failed")
    staged = _git_result(
        config,
        ("diff", "--cached", "--name-only"),
        worktree,
        command,
        artifacts,
        "staged-scope",
        timeout=30,
    )
    if staged.returncode != 0:
        raise BridgeError("staged_scope_failed")
    staged_paths = tuple(
        sorted(line.replace("\\", "/") for line in staged.stdout.splitlines() if line)
    )
    if staged_paths != paths:
        raise BridgeError("staged_scope_mismatch")
    commit = _git_result(
        config,
        (
            "-c",
            "user.name=CSE Codex Loop",
            "-c",
            "user.email=cse-codex-loop@users.noreply.github.com",
            "commit",
            "-m",
            task.commit_subject,
        ),
        worktree,
        command,
        artifacts,
        "git-commit",
        timeout=120,
    )
    if commit.returncode != 0:
        raise BridgeError("git_commit_failed")
    published_commit = _git_result(
        config,
        ("rev-parse", "--verify", "HEAD"),
        worktree,
        command,
        artifacts,
        "published-commit",
        timeout=30,
    )
    commit_sha = published_commit.stdout.strip()
    if published_commit.returncode != 0 or not re.fullmatch(
        r"[0-9a-fA-F]{40,64}", commit_sha
    ):
        raise BridgeError("published_commit_unavailable")
    pushed = _git_result(
        config,
        ("push", "origin", f"HEAD:refs/heads/{task.branch}"),
        worktree,
        command,
        artifacts,
        "git-push",
        timeout=300,
    )
    if pushed.returncode != 0:
        raise BridgeError("git_push_failed")
    return PublicationResult(github.create_draft_pr(task), commit_sha)


def _published_worktree_is_clean(
    config: LoopConfig,
    worktree: Path,
    task: BridgeTask,
    published_commit: str,
    command: CommandAdapter,
    artifacts: RunArtifacts,
    *,
    stage: str,
) -> bool:
    status = _git_result(
        config,
        ("status", "--porcelain=v1", "--untracked-files=all"),
        worktree,
        command,
        artifacts,
        f"{stage}-status",
        timeout=30,
    )
    if status.returncode != 0 or status.stdout.strip():
        return False
    branch = _git_result(
        config,
        ("symbolic-ref", "--quiet", "HEAD"),
        worktree,
        command,
        artifacts,
        f"{stage}-branch",
        timeout=30,
    )
    if branch.returncode != 0 or branch.stdout.strip() != f"refs/heads/{task.branch}":
        return False
    head = _git_result(
        config,
        ("rev-parse", "--verify", "HEAD"),
        worktree,
        command,
        artifacts,
        f"{stage}-commit",
        timeout=30,
    )
    return (
        head.returncode == 0
        and head.stdout.strip().casefold() == published_commit.casefold()
    )


def _registered_worktree_paths(output: str) -> tuple[Path, ...] | None:
    if not output or not output.endswith("\0\0"):
        return None
    paths: list[Path] = []
    for record in output[:-2].split("\0\0"):
        fields = record.split("\0")
        if not fields or not fields[0].startswith("worktree "):
            return None
        raw_path = fields[0].removeprefix("worktree ")
        path = Path(raw_path)
        if not raw_path or not path.is_absolute():
            return None
        paths.append(path)
    return tuple(paths)


def _issue_worktree_is_registered(
    config: LoopConfig,
    worktree: Path,
    command: CommandAdapter,
    artifacts: RunArtifacts,
    *,
    stage: str,
) -> bool | None:
    result = _git_result(
        config,
        ("worktree", "list", "--porcelain", "-z"),
        config.repo_root,
        command,
        artifacts,
        stage,
        timeout=30,
    )
    if result.returncode != 0:
        return None
    registered_paths = _registered_worktree_paths(result.stdout)
    if registered_paths is None:
        return None
    expected = os.path.normcase(os.path.abspath(worktree))
    return any(
        os.path.normcase(os.path.abspath(path)) == expected
        for path in registered_paths
    )


def remove_successful_worktree(
    config: LoopConfig,
    worktree: Path,
    task: BridgeTask,
    published_commit: str,
    command: CommandAdapter,
    artifacts: RunArtifacts,
) -> bool:
    issue_number = artifacts.issue_number
    if issue_number is None:
        return False
    expected = task_worktree(artifacts.runtime_root, issue_number)
    if worktree.resolve() != expected.resolve():
        return False
    try:
        worktree.resolve().relative_to(config.repo_root)
    except ValueError:
        pass
    else:
        return False

    try:
        registered = _issue_worktree_is_registered(
            config,
            worktree,
            command,
            artifacts,
            stage="worktree-cleanup-list-initial",
        )
        if registered is None:
            return False
        if not worktree.exists():
            return not registered
        if not registered:
            return False
        for attempt in range(1, WORKTREE_REMOVE_ATTEMPTS + 1):
            if not _published_worktree_is_clean(
                config,
                worktree,
                task,
                published_commit,
                command,
                artifacts,
                stage=f"worktree-cleanup-check-{attempt}",
            ):
                return False
            result = _git_result(
                config,
                ("worktree", "remove", "--force", str(worktree)),
                config.repo_root,
                command,
                artifacts,
                f"worktree-cleanup-remove-{attempt}",
                timeout=120,
            )
            registered = _issue_worktree_is_registered(
                config,
                worktree,
                command,
                artifacts,
                stage=f"worktree-cleanup-list-{attempt}",
            )
            if registered is None:
                return False
            if not registered:
                if result.returncode != 0 or not worktree.exists():
                    return True
                if not _published_worktree_is_clean(
                    config,
                    worktree,
                    task,
                    published_commit,
                    command,
                    artifacts,
                    stage="worktree-cleanup-fallback-check",
                ):
                    return False
                try:
                    shutil.rmtree(worktree)
                except FileNotFoundError:
                    pass
                except OSError:
                    return False
                return not worktree.exists()
            if not worktree.exists():
                return False
            if attempt < WORKTREE_REMOVE_ATTEMPTS:
                time.sleep(WORKTREE_CLEANUP_RETRY_SECONDS)
        return False
    except (BridgeError, OSError):
        return False


def terminal_comment(kind: str, reason: str, run_id: str, pr_url: str = "") -> str:
    if not _SAFE_REASON.fullmatch(reason):
        reason = "unsafe_reason_rejected"
    if kind == "READY_FOR_FATIH":
        lines = [
            PASS_MARKER,
            "READY_FOR_FATIH",
            f"Run: `{run_id}`",
            "Host validation and independent Codex review passed.",
        ]
        if pr_url:
            lines.append(f"Draft PR: {pr_url}")
        if reason != "approved":
            lines.append(f"Cleanup warning: `{reason}`.")
        return "\n".join(lines)
    if kind == "NEEDS_HUMAN":
        return (
            f"{NEEDS_HUMAN_MARKER}\nNEEDS_HUMAN\nRun: `{run_id}`\n"
            f"CSE Codex Loop stopped: `{reason}`."
        )
    return (
        f"{FAILED_MARKER}\nFAILED\nRun: `{run_id}`\n"
        f"CSE Codex Loop stopped: `{reason}`."
    )


def _failure_kind(reason: str) -> str:
    if reason in {"review_needs_human", "review_unresolved"}:
        return "NEEDS_HUMAN"
    return "FAILED"


def process_issue(
    issue_number: int,
    config: LoopConfig,
    runtime_root: Path,
    github: GitHubClient,
    command: CommandAdapter,
    artifacts: RunArtifacts,
) -> int:
    artifacts.set_issue(issue_number)
    artifacts.update("RUNNING", "task", None)
    issue = github.issue(issue_number)
    comments = github.comments(issue_number)
    if str(issue.get("state", "")).casefold() != "open" or "pull_request" in issue:
        raise BridgeError("task_not_ready")
    if terminal_state(comments) is not None:
        artifacts.update("SKIPPED", "terminal", 0, "task_already_terminal")
        return 0
    body = issue.get("body")
    if not isinstance(body, str):
        raise BridgeError("task_body_missing")
    task = parse_task(body)
    if task.repository.casefold() != config.repository.casefold():
        raise BridgeError("task_repository_mismatch")
    if task.base != config.allowed_base:
        raise BridgeError("task_base_forbidden")
    if not task_ready(issue, comments):
        raise BridgeError("task_not_ready")
    github.comment(
        issue_number,
        f"{RUNNING_MARKER}\nCSE Codex Loop started.\nRun: `{artifacts.run_id}`",
    )
    worktree: Path | None = None
    try:
        artifacts.update("RUNNING", "worktree", None)
        worktree = create_worktree(
            config, runtime_root, issue_number, task, command, artifacts
        )
        artifacts.update("RUNNING", "implement", None)
        run_codex_pass(
            config,
            worktree,
            implementation_prompt(task),
            command,
            artifacts,
        )
        artifacts.update("RUNNING", "validate", None)
        paths = enforce_scope(config, worktree, task, command, artifacts)
        run_validations(config, worktree, task, command, artifacts)
        artifacts.update("RUNNING", "review", None)
        review = run_review(
            config,
            worktree,
            task,
            paths,
            command,
            artifacts,
            round_number=1,
        )
        if review.verdict == "needs_human":
            raise BridgeError("review_needs_human")
        if review.verdict == "changes_requested":
            artifacts.update("RUNNING", "correction", None)
            run_codex_pass(
                config,
                worktree,
                correction_prompt(task, review),
                command,
                artifacts,
                correction=True,
            )
            artifacts.update("RUNNING", "revalidate", None)
            paths = enforce_scope(config, worktree, task, command, artifacts)
            run_validations(config, worktree, task, command, artifacts)
            artifacts.update("RUNNING", "rereview", None)
            review = run_review(
                config,
                worktree,
                task,
                paths,
                command,
                artifacts,
                round_number=2,
            )
            if review.verdict != "approved":
                raise BridgeError("review_unresolved")
        artifacts.update("RUNNING", "publish", None)
        publication = publish(config, worktree, task, github, command, artifacts)
        pr_url = str(publication.pr.get("html_url", ""))
        try:
            cleanup_complete = remove_successful_worktree(
                config,
                worktree,
                task,
                publication.commit,
                command,
                artifacts,
            )
        except Exception:
            cleanup_complete = False
        reason = "approved" if cleanup_complete else "approved_cleanup_pending"
        github.comment(
            issue_number,
            terminal_comment("READY_FOR_FATIH", reason, artifacts.run_id, pr_url),
        )
        artifacts.update("PASS", "complete", 0, reason)
        return 0
    except BridgeError as exc:
        kind = _failure_kind(exc.reason)
        github.comment(
            issue_number,
            terminal_comment(kind, exc.reason, artifacts.run_id),
        )
        artifacts.update(kind, "complete", 3 if kind == "NEEDS_HUMAN" else 1, exc.reason)
        return 3 if kind == "NEEDS_HUMAN" else 1
    except Exception:
        reason = "unexpected_worker_failure"
        try:
            github.comment(
                issue_number,
                terminal_comment("FAILED", reason, artifacts.run_id),
            )
        except BridgeError:
            pass
        artifacts.update("FAILED", "complete", 1, reason)
        return 1


def run_loop(
    config: LoopConfig,
    runtime_root: Path,
    github: GitHubClient,
    command: CommandAdapter,
    artifacts: RunArtifacts,
    *,
    issue_number: int | None = None,
) -> int:
    validate_repository(config, command, artifacts)
    selected = issue_number if issue_number is not None else select_approved_issue(github)
    if selected is None:
        artifacts.update("IDLE", "complete", 0, "no_task")
        return 0
    return process_issue(
        selected, config, runtime_root, github, command, artifacts
    )


def run_smoke(
    config: LoopConfig,
    command: CommandAdapter,
    artifacts: RunArtifacts,
) -> int:
    output_path = artifacts.run_root / "smoke-result.txt"
    prompt = (
        "Read-only connectivity check. Do not modify files. "
        "Reply with exactly CSE_CODEX_EXEC_PASS."
    )
    result = command(
        (
            str(config.codex_path),
            "exec",
            "--ephemeral",
            "--sandbox",
            "read-only",
            "-C",
            str(config.repo_root),
            "--output-last-message",
            str(output_path),
            "-",
        ),
        config.repo_root,
        300,
        prompt,
    )
    artifacts.record_command("codex-smoke", result, sensitive=(prompt,))
    if result.returncode != 0:
        raise BridgeError("codex_smoke_failed")
    try:
        answer = output_path.read_text(encoding="utf-8").strip()
    except OSError:
        answer = result.stdout.strip()
    if answer != "CSE_CODEX_EXEC_PASS":
        raise BridgeError("codex_smoke_invalid")
    artifacts.update("PASS", "smoke", 0, "codex_connectivity_pass")
    print(answer)
    return 0


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runtime-root", type=Path, default=default_runtime_root())
    parser.add_argument("--issue-number", type=int)
    parser.add_argument("--smoke", action="store_true")
    args = parser.parse_args(argv)
    runtime_root = args.runtime_root.resolve()
    artifacts = RunArtifacts.create(runtime_root, args.issue_number)
    try:
        config = load_config(runtime_root)
        if config.max_runs != 20:
            rotate_runs(runtime_root, max_runs=config.max_runs, keep=artifacts.run_root)
        if args.smoke:
            return run_smoke(config, run_command, artifacts)
        token = resolve_github_token(config, run_command, artifacts)
        github = GitHubClient(config.repository, token)
        return run_loop(
            config,
            runtime_root,
            github,
            run_command,
            artifacts,
            issue_number=args.issue_number,
        )
    except BridgeError as exc:
        artifacts.update("FAILED", "complete", 1, exc.reason)
        print(exc.reason, file=sys.stderr)
        return 1
    except Exception:
        artifacts.update("FAILED", "complete", 1, "unexpected_worker_failure")
        print("unexpected_worker_failure", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
