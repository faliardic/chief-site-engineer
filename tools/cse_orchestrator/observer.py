"""Deterministic, data-minimal Git/GitHub observer for CSE O1."""

from __future__ import annotations

import hashlib
import json
import os
import re
import subprocess
import tempfile
import uuid
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable, Mapping, Protocol, Sequence

from .authorization import AuthorizationSelection, select_latest_authorization


SHA_PATTERN = re.compile(r"^[0-9a-f]{40}$")
REPOSITORY_PATTERN = re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")
EXACT_RECORD_PATTERNS = (
    re.compile(r"^\.cse/tasks/\d+_task\.md$"),
    re.compile(r"^\.cse/results/\d+_result\.md$"),
    re.compile(r"^\.cse/state/project_state\.json$"),
)

BLOCKER_PRECEDENCE = {
    "USER_DATA_RISK": (0, 14),
    "PROVENANCE_MISMATCH": (1, 13),
    "SCOPE_DRIFT": (1, 13),
    "APPROVAL_EXPIRED": (2, 12),
    "SOURCE_FAILURE": (3, 11),
    "STATE_DRIFT": (4, 10),
}


@dataclass(frozen=True)
class CommandResult:
    args: tuple[str, ...]
    returncode: int
    stdout: str
    stderr: str

    @property
    def ok(self) -> bool:
        return self.returncode == 0


CommandRunner = Callable[[Sequence[str], Path], CommandResult]
ApiRunner = Callable[[tuple[str, ...]], CommandResult]

GITHUB_GET_FAILURE_REASONS = frozenset(
    {
        "github_get_executable_unavailable",
        "github_get_timeout",
        "github_get_utf8_invalid",
    }
)
GITHUB_CLIENT_ERROR_REASONS = GITHUB_GET_FAILURE_REASONS | frozenset(
    {
        "github_get_failed",
        "github_get_json_invalid",
        "github_get_pagination_limit",
        "github_get_repository_shape_invalid",
        "github_get_issue_shape_invalid",
        "github_get_comments_shape_invalid",
    }
)
GITHUB_COMMENTS_MAX_PAGES = 100


class GitHubClientError(RuntimeError):
    """A sanitized, stable failure from the shared GitHub GET adapter."""


def sanitized_github_error_reason(value: object) -> str:
    reason = str(value)
    return reason if reason in GITHUB_CLIENT_ERROR_REASONS else "github_get_failed"


class GitHubClient(Protocol):
    def get_repository(self) -> dict[str, Any]: ...

    def get_issue(self, issue_number: int) -> dict[str, Any]: ...

    def get_issue_comments(self, issue_number: int) -> list[dict[str, Any]]: ...


def _is_exact_record_path(value: str) -> bool:
    return any(pattern.fullmatch(value) for pattern in EXACT_RECORD_PATTERNS)


def is_allowed_read_only_command(args: Sequence[str]) -> bool:
    """Allow only the bounded command shapes specified by the O1 contract."""

    command = tuple(str(item) for item in args)
    if command == ("git", "rev-parse", "--show-toplevel"):
        return True
    if command == ("git", "branch", "--show-current"):
        return True
    if len(command) == 3 and command[:2] == ("git", "rev-parse"):
        return command[2] in {
            "HEAD",
            "HEAD^",
            "HEAD^{tree}",
            "refs/heads/master",
            "refs/remotes/origin/master",
        }
    if command in {
        ("git", "diff", "--name-status", "--cached"),
        ("git", "diff", "--name-status"),
        ("git", "remote", "get-url", "origin"),
        ("git", "ls-remote", "--heads", "origin", "refs/heads/master"),
    }:
        return True
    if len(command) == 5 and command[:4] == (
        "git",
        "ls-files",
        "--error-unmatch",
        "--",
    ):
        return _is_exact_record_path(command[4])
    if len(command) == 4 and command[:3] == ("git", "hash-object", "--"):
        return _is_exact_record_path(command[3])
    return False


def run_read_only_command(args: Sequence[str], cwd: Path) -> CommandResult:
    command = tuple(str(item) for item in args)
    if not is_allowed_read_only_command(command):
        raise ValueError("command_not_in_read_only_allowlist")
    try:
        completed = subprocess.run(
            command,
            cwd=cwd,
            text=True,
            capture_output=True,
            check=False,
        )
    except OSError:
        return CommandResult(command, 127, "", "command unavailable")
    return CommandResult(command, completed.returncode, completed.stdout, completed.stderr)


def _run_binary_utf8(
    args: tuple[str, ...],
    *,
    timeout_seconds: int = 30,
) -> CommandResult:
    """Capture bytes and decode them strictly on the calling thread."""

    try:
        completed = subprocess.run(
            args,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            stdin=subprocess.DEVNULL,
            shell=False,
            check=False,
            timeout=timeout_seconds,
        )
    except OSError:
        return CommandResult(args, 127, "", "github_get_executable_unavailable")
    except subprocess.TimeoutExpired:
        return CommandResult(args, 124, "", "github_get_timeout")
    try:
        stdout = bytes(completed.stdout or b"").decode("utf-8", errors="strict")
        stderr = bytes(completed.stderr or b"").decode("utf-8", errors="strict")
    except UnicodeDecodeError:
        return CommandResult(args, 65, "", "github_get_utf8_invalid")
    return CommandResult(args, completed.returncode, stdout, stderr)


def _run_gh_api(args: tuple[str, ...]) -> CommandResult:
    if args[:4] != ("gh", "api", "--method", "GET") or len(args) != 5:
        raise ValueError("github_api_command_not_read_only_get")
    return _run_binary_utf8(args)


class GhGitHubClient:
    """Minimal `gh api` GET adapter; no mutation method exists."""

    def __init__(self, repository: str, *, api_runner: ApiRunner | None = None):
        if not REPOSITORY_PATTERN.fullmatch(repository):
            raise ValueError("repository must be owner/name")
        self.repository = repository
        self.api_runner = api_runner or _run_gh_api

    def _get_json(self, endpoint: str) -> Any:
        args = ("gh", "api", "--method", "GET", endpoint)
        result = self.api_runner(args)
        if not result.ok:
            reason = (
                result.stderr
                if result.stderr in GITHUB_GET_FAILURE_REASONS
                else "github_get_failed"
            )
            raise GitHubClientError(reason)
        try:
            return json.loads(result.stdout)
        except (json.JSONDecodeError, TypeError) as exc:
            raise GitHubClientError("github_get_json_invalid") from exc

    def get_repository(self) -> dict[str, Any]:
        value = self._get_json(f"repos/{self.repository}")
        if not isinstance(value, dict):
            raise GitHubClientError("github_get_repository_shape_invalid")
        return value

    def get_issue(self, issue_number: int) -> dict[str, Any]:
        value = self._get_json(f"repos/{self.repository}/issues/{issue_number}")
        if not isinstance(value, dict):
            raise GitHubClientError("github_get_issue_shape_invalid")
        return value

    def get_issue_comments(self, issue_number: int) -> list[dict[str, Any]]:
        values: list[dict[str, Any]] = []
        page = 1
        while True:
            endpoint = (
                f"repos/{self.repository}/issues/{issue_number}/comments"
                f"?per_page=100&page={page}"
            )
            current = self._get_json(endpoint)
            if not isinstance(current, list) or not all(
                isinstance(item, dict) for item in current
            ):
                raise GitHubClientError("github_get_comments_shape_invalid")
            values.extend(current)
            if len(current) < 100:
                return values
            if page >= GITHUB_COMMENTS_MAX_PAGES:
                raise GitHubClientError("github_get_pagination_limit")
            page += 1


def _first_line(result: CommandResult) -> str | None:
    if not result.ok:
        return None
    lines = [line.strip() for line in result.stdout.splitlines() if line.strip()]
    return lines[0] if lines else None


def _normalized_path(value: str | Path) -> str:
    return os.path.normcase(str(Path(value).resolve()))


def _parse_name_status(result: CommandResult) -> list[str]:
    if not result.ok:
        return []
    return sorted(line.rstrip() for line in result.stdout.splitlines() if line.rstrip())


def _sha_or_none(value: str | None) -> str | None:
    return value if value is not None and SHA_PATTERN.fullmatch(value) else None


def _hash_payload(payload: Mapping[str, Any]) -> str:
    raw = json.dumps(
        payload,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")
    return "sha256:" + hashlib.sha256(raw).hexdigest()


def collect_git_observation(
    repo_root: Path,
    command_runner: CommandRunner = run_read_only_command,
) -> tuple[dict[str, Any], list[str]]:
    """Collect only tracked Git metadata and live master provenance."""

    root = Path(repo_root).resolve()
    commands = {
        "root": ("git", "rev-parse", "--show-toplevel"),
        "branch": ("git", "branch", "--show-current"),
        "head": ("git", "rev-parse", "HEAD"),
        "parent": ("git", "rev-parse", "HEAD^"),
        "tree": ("git", "rev-parse", "HEAD^{tree}"),
        "local_master": ("git", "rev-parse", "refs/heads/master"),
        "origin_master": ("git", "rev-parse", "refs/remotes/origin/master"),
        "staged": ("git", "diff", "--name-status", "--cached"),
        "tracked": ("git", "diff", "--name-status"),
        "origin_url": ("git", "remote", "get-url", "origin"),
        "remote_master": (
            "git",
            "ls-remote",
            "--heads",
            "origin",
            "refs/heads/master",
        ),
    }
    results = {name: command_runner(args, root) for name, args in commands.items()}
    blockers: list[str] = []

    actual_root = _first_line(results["root"])
    if actual_root is None:
        blockers.append("SOURCE_FAILURE")
    elif _normalized_path(actual_root) != _normalized_path(root):
        blockers.append("PROVENANCE_MISMATCH")

    branch = _first_line(results["branch"])
    head_sha = _sha_or_none(_first_line(results["head"]))
    parent_sha = _sha_or_none(_first_line(results["parent"]))
    tree_sha = _sha_or_none(_first_line(results["tree"]))
    local_master_sha = _sha_or_none(_first_line(results["local_master"]))
    origin_master_sha = _sha_or_none(_first_line(results["origin_master"]))
    origin_url = _first_line(results["origin_url"])

    live_line = _first_line(results["remote_master"])
    remote_master_sha = None
    if live_line:
        remote_master_sha = _sha_or_none(live_line.split()[0])

    required_values = (
        branch,
        head_sha,
        parent_sha,
        tree_sha,
        local_master_sha,
        origin_master_sha,
        origin_url,
        remote_master_sha,
    )
    if any(value is None for value in required_values):
        blockers.append("SOURCE_FAILURE")

    staged = _parse_name_status(results["staged"])
    tracked = _parse_name_status(results["tracked"])
    if not results["staged"].ok or not results["tracked"].ok:
        blockers.append("SOURCE_FAILURE")

    master_values = (local_master_sha, origin_master_sha, remote_master_sha)
    if all(master_values) and len(set(master_values)) != 1:
        blockers.append("STATE_DRIFT")

    fingerprint_inputs = {
        "head_sha": head_sha,
        "tree_sha": tree_sha,
        "staged": staged,
        "tracked_worktree": tracked,
    }
    return (
        {
            "branch": branch,
            "head_sha": head_sha,
            "parent_sha": parent_sha,
            "tree_sha": tree_sha,
            "local_master_sha": local_master_sha,
            "origin_master_sha": origin_master_sha,
            "remote_master_sha": remote_master_sha,
            "origin_url": origin_url,
            "staged": staged,
            "tracked_worktree": tracked,
            "tracked_fingerprint": _hash_payload(fingerprint_inputs),
        },
        sorted(set(blockers)),
    )


def _comment_metadata(comments: Sequence[Mapping[str, Any]]) -> list[dict[str, Any]]:
    values = [
        {
            "id": item.get("id"),
            "created_at": item.get("created_at"),
            "updated_at": item.get("updated_at"),
        }
        for item in comments
    ]
    return sorted(values, key=lambda item: int(item.get("id") or 0))


def comments_metadata_hash(comments: Sequence[Mapping[str, Any]]) -> str:
    return _hash_payload({"comments": _comment_metadata(comments)})


def collect_github_observation(
    repository: str,
    issue_number: int,
    github_client: GitHubClient,
) -> tuple[dict[str, Any], list[dict[str, Any]], list[str]]:
    """Collect GET-only repository/Issue metadata and retain bodies only internally."""

    try:
        repo = github_client.get_repository()
        issue = github_client.get_issue(issue_number)
        comments = github_client.get_issue_comments(issue_number)
    except (OSError, RuntimeError, ValueError, TypeError):
        return (
            {
                "repository": repository,
                "default_branch": None,
                "issue_state": None,
                "issue_updated_at": None,
                "comment_count": 0,
                "comments_metadata_hash": _hash_payload({"comments": []}),
            },
            [],
            ["SOURCE_FAILURE"],
        )

    blockers: list[str] = []
    if repo.get("full_name") != repository or issue.get("number") != issue_number:
        blockers.append("PROVENANCE_MISMATCH")
    metadata = {
        "repository": repo.get("full_name"),
        "default_branch": repo.get("default_branch"),
        "issue_state": issue.get("state"),
        "issue_updated_at": issue.get("updated_at"),
        "comment_count": len(comments),
        "comments_metadata_hash": comments_metadata_hash(comments),
    }
    return metadata, comments, blockers


def collect_exact_records(
    repo_root: Path,
    issue_number: int,
    command_runner: CommandRunner = run_read_only_command,
) -> dict[str, dict[str, Any]]:
    root = Path(repo_root).resolve()
    paths = {
        "task": f".cse/tasks/{issue_number}_task.md",
        "result": f".cse/results/{issue_number}_result.md",
        "project_state": ".cse/state/project_state.json",
    }
    records: dict[str, dict[str, Any]] = {}
    for name, relative in paths.items():
        exists = (root / Path(relative)).is_file()
        tracked_result = command_runner(
            ("git", "ls-files", "--error-unmatch", "--", relative),
            root,
        )
        tracked = tracked_result.ok and _first_line(tracked_result) == relative
        blob_hash = None
        if exists:
            hash_result = command_runner(("git", "hash-object", "--", relative), root)
            blob_hash = _sha_or_none(_first_line(hash_result))
        records[name] = {
            "path": relative,
            "exists": exists,
            "tracked": tracked,
            "blob_hash": blob_hash,
            "content_included": False,
        }
    return records


def runtime_root_is_safe(repo_root: Path, runtime_root: Path) -> bool:
    repo = Path(repo_root).resolve()
    runtime = Path(runtime_root).resolve()
    try:
        return os.path.commonpath((str(repo), str(runtime))) != str(repo)
    except ValueError:
        return True


def canonical_json_text(value: Mapping[str, Any]) -> str:
    return json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n"


def write_observation_atomic(
    observation: Mapping[str, Any],
    runtime_root: Path,
    run_id: str,
) -> tuple[dict[str, Any], Path]:
    """Write one sanitized observation through temp-file plus atomic replace."""

    output_dir = Path(runtime_root).resolve() / "runs" / run_id
    output_dir.mkdir(parents=True, exist_ok=False)
    output_path = output_dir / "observation.json"
    value = dict(observation)
    value["runtime_output_path"] = str(output_path)

    temporary_path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            newline="\n",
            prefix=".observation-",
            suffix=".tmp",
            dir=output_dir,
            delete=False,
        ) as handle:
            temporary_path = Path(handle.name)
            handle.write(canonical_json_text(value))
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary_path, output_path)
    finally:
        if temporary_path is not None and temporary_path.exists():
            temporary_path.unlink()
    return value, output_path


def _add_blocker(blockers: list[dict[str, str]], code: str, reason: str) -> None:
    item = {"code": code, "reason": reason}
    if item not in blockers:
        blockers.append(item)


def classify_blockers(
    blockers: Sequence[Mapping[str, str]],
) -> tuple[list[dict[str, str]], str, int]:
    normalized = [
        {"code": str(item["code"]), "reason": str(item["reason"])}
        for item in blockers
    ]
    unique = list({(item["code"], item["reason"]): item for item in normalized}.values())
    ordered = sorted(
        unique,
        key=lambda item: (
            BLOCKER_PRECEDENCE.get(item["code"], (99, 1))[0],
            item["code"],
            item["reason"],
        ),
    )
    if not ordered:
        return [], "OBSERVING", 0
    exit_code = BLOCKER_PRECEDENCE.get(ordered[0]["code"], (99, 1))[1]
    return ordered, "PREFLIGHT_BLOCKED", exit_code


def _validate_authorization_source(
    selection: AuthorizationSelection,
    git: Mapping[str, Any],
    repository: str,
    issue_number: int,
) -> list[dict[str, str]]:
    if selection.status == "missing":
        return []
    if selection.status in {"invalid", "expired"}:
        reasons = selection.reasons or ("authorization_invalid",)
        code = (
            "PROVENANCE_MISMATCH"
            if any("comment_id_mismatch" in reason for reason in reasons)
            else "APPROVAL_EXPIRED"
        )
        return [{"code": code, "reason": reasons[0]}]
    if selection.status != "valid" or selection.payload is None:
        return [{"code": "APPROVAL_EXPIRED", "reason": "authorization_unusable"}]

    payload = selection.payload
    comparisons = {
        "repository": (payload.get("repository"), repository),
        "issue": (payload.get("issue"), issue_number),
        "branch": (payload.get("branch"), git.get("branch")),
        "base_sha": (payload.get("base_sha"), git.get("origin_master_sha")),
        "head_sha": (payload.get("head_sha"), git.get("head_sha")),
        "tree_sha": (payload.get("tree_sha"), git.get("tree_sha")),
    }
    blockers: list[dict[str, str]] = []
    for field, (expected, actual) in comparisons.items():
        if expected != actual:
            _add_blocker(
                blockers,
                "PROVENANCE_MISMATCH",
                f"authorization_{field}_mismatch",
            )
    return blockers


def observe_repository(
    *,
    repo_root: Path,
    repository: str,
    issue_number: int,
    runtime_root: Path,
    command_runner: CommandRunner = run_read_only_command,
    github_client: GitHubClient | None = None,
    now: datetime | None = None,
    run_id: str | None = None,
    write_runtime: bool = True,
) -> dict[str, Any]:
    """Assemble one sanitized Observation v1 and optionally persist it outside Git."""

    root = Path(repo_root).resolve()
    runtime = Path(runtime_root).resolve()
    current = now or datetime.now(timezone.utc)
    if current.tzinfo is None or current.utcoffset() is None:
        raise ValueError("now must be timezone-aware")
    current = current.astimezone(timezone.utc)
    opaque_run_id = run_id or uuid.uuid4().hex
    blockers: list[dict[str, str]] = []

    if not runtime_root_is_safe(root, runtime):
        _add_blocker(blockers, "USER_DATA_RISK", "runtime_root_inside_repository")

    git, git_blockers = collect_git_observation(root, command_runner)
    for code in git_blockers:
        reason = {
            "PROVENANCE_MISMATCH": "canonical_root_mismatch",
            "STATE_DRIFT": "master_sha_mismatch",
            "SOURCE_FAILURE": "git_source_unavailable",
        }[code]
        _add_blocker(blockers, code, reason)

    source = github_client or GhGitHubClient(repository)
    github, raw_comments, github_blockers = collect_github_observation(
        repository,
        issue_number,
        source,
    )
    for code in github_blockers:
        reason = (
            "github_provenance_mismatch"
            if code == "PROVENANCE_MISMATCH"
            else "github_source_unavailable"
        )
        _add_blocker(blockers, code, reason)

    selection = select_latest_authorization(raw_comments, now=current)
    blockers.extend(
        _validate_authorization_source(selection, git, repository, issue_number)
    )
    records = collect_exact_records(root, issue_number, command_runner)

    ordered_blockers, state, exit_code = classify_blockers(blockers)
    if not ordered_blockers and selection.status == "valid":
        state = "SCOPE_VALIDATED"

    observed_at = current.isoformat(timespec="seconds").replace("+00:00", "Z")
    observation: dict[str, Any] = {
        "schema_version": 1,
        "run_id": opaque_run_id,
        "observed_at_utc": observed_at,
        "repository": repository,
        "repo_root": str(root),
        "issue": issue_number,
        "git": git,
        "github": github,
        "authorization": selection.public_dict(),
        "records": records,
        "state": state,
        "blockers": ordered_blockers,
        "exit_code": exit_code,
        "runtime_output_path": None,
    }

    if write_runtime and runtime_root_is_safe(root, runtime):
        try:
            observation, _ = write_observation_atomic(
                observation,
                runtime,
                opaque_run_id,
            )
        except OSError:
            _add_blocker(blockers, "SOURCE_FAILURE", "runtime_atomic_write_failed")
            ordered_blockers, state, exit_code = classify_blockers(blockers)
            observation["blockers"] = ordered_blockers
            observation["state"] = state
            observation["exit_code"] = exit_code
    return observation
