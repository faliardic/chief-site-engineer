"""One-mutation GitHub REST Draft-PR adapter for CSE O9."""

from __future__ import annotations

import hashlib
import json
import re
import socket
import subprocess
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Mapping, Protocol


API_ROOT = "https://api.github.com"
REPOSITORY_PATTERN = re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")
SHA_PATTERN = re.compile(r"^[0-9a-f]{40}$")


class GitHubRestError(RuntimeError):
    """A Draft PR request was not safe to admit."""


@dataclass(frozen=True)
class RestResponse:
    status_code: int
    headers: Mapping[str, str]
    body: bytes


class RestTransport(Protocol):
    def request(
        self,
        method: str,
        url: str,
        *,
        headers: Mapping[str, str],
        body: bytes | None,
        timeout_seconds: int,
    ) -> RestResponse: ...


class UrlLibRestTransport:
    def request(
        self,
        method: str,
        url: str,
        *,
        headers: Mapping[str, str],
        body: bytes | None,
        timeout_seconds: int,
    ) -> RestResponse:
        request = urllib.request.Request(url, data=body, headers=dict(headers), method=method)
        try:
            with urllib.request.urlopen(request, timeout=timeout_seconds) as response:
                return RestResponse(
                    int(response.status),
                    {str(key).lower(): str(value) for key, value in response.headers.items()},
                    response.read(),
                )
        except urllib.error.HTTPError as exc:
            return RestResponse(
                int(exc.code),
                {str(key).lower(): str(value) for key, value in exc.headers.items()},
                exc.read(),
            )


@dataclass(frozen=True)
class GitHubRestContract:
    repository: str
    branch: str
    base_branch: str
    head_sha: str
    remote_head_sha: str
    remote_divergence: tuple[int, int]
    issue: int
    title: str
    body: str
    draft: bool


@dataclass(frozen=True)
class GitHubRestTemplate:
    repository: str
    branch: str
    base_branch: str
    expected_base_sha: str
    issue: int
    title: str
    body: str
    draft: bool


@dataclass(frozen=True)
class GitProcessResult:
    exit_code: int | None
    stdout: bytes
    stderr: bytes
    timed_out: bool
    truncated: bool


class GitProcess(Protocol):
    def run(self, argv: tuple[str, ...], *, cwd: Path, timeout_seconds: int,
            output_limit_bytes: int) -> GitProcessResult: ...


class SubprocessGitProcess:
    """Bounded shell-free host process adapter."""

    def run(self, argv, *, cwd, timeout_seconds, output_limit_bytes):
        try:
            completed = subprocess.run(
                list(argv), cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                timeout=timeout_seconds, check=False, shell=False,
            )
        except subprocess.TimeoutExpired as exc:
            stdout, stderr = exc.stdout or b"", exc.stderr or b""
            return GitProcessResult(None, stdout[:output_limit_bytes], stderr[:output_limit_bytes],
                                    True, len(stdout) > output_limit_bytes or len(stderr) > output_limit_bytes)
        except (OSError, ValueError):
            return GitProcessResult(None, b"", b"process unavailable", False, False)
        return GitProcessResult(
            completed.returncode, completed.stdout[:output_limit_bytes],
            completed.stderr[:output_limit_bytes], False,
            len(completed.stdout) > output_limit_bytes or len(completed.stderr) > output_limit_bytes,
        )


@dataclass(frozen=True)
class HostPublishRequest:
    repo_root: Path
    branch: str
    expected_base_sha: str
    write_allowlist: tuple[str, ...]
    validation_argv: tuple[tuple[str, ...], ...]
    commit_message: str
    github: GitHubRestTemplate
    timeout_seconds: int = 300
    output_limit_bytes: int = 1048576


@dataclass(frozen=True)
class DraftPullRequestResult:
    executed: bool
    number: int | None
    state: str
    draft: bool
    request_id: str | None

    def public_dict(self) -> dict[str, object]:
        return {
            "executed": self.executed,
            "number": self.number,
            "state": self.state,
            "draft": self.draft,
            "request_id": self.request_id,
        }


def _validate_contract(value: GitHubRestContract) -> None:
    if not isinstance(value, GitHubRestContract):
        raise GitHubRestError("github_contract_required")
    if not REPOSITORY_PATTERN.fullmatch(value.repository):
        raise GitHubRestError("repository_invalid")
    if not value.branch or "\x00" in value.branch:
        raise GitHubRestError("branch_invalid")
    if value.base_branch != "master":
        raise GitHubRestError("base_must_be_master")
    if not SHA_PATTERN.fullmatch(value.head_sha) or not SHA_PATTERN.fullmatch(value.remote_head_sha):
        raise GitHubRestError("head_sha_invalid")
    if value.remote_divergence != (0, 0):
        raise GitHubRestError("remote_divergence")
    if value.remote_head_sha != value.head_sha:
        raise GitHubRestError("head_drift")
    if value.draft is not True:
        raise GitHubRestError("draft_required")
    if isinstance(value.issue, bool) or not isinstance(value.issue, int) or value.issue < 1:
        raise GitHubRestError("issue_invalid")
    if not value.title or not value.body or "\x00" in value.title + value.body:
        raise GitHubRestError("pull_request_text_invalid")
    if value.body.splitlines()[0] != f"Closes #{value.issue}":
        raise GitHubRestError("issue_prefix_invalid")
    forbidden = re.compile(r"(?i)\b(ready|merge|issue close|branch delete|release)\b")
    if forbidden.search(value.title):
        raise GitHubRestError("forbidden_publish_action")


def _validate_template(value: GitHubRestTemplate) -> None:
    if not isinstance(value, GitHubRestTemplate):
        raise GitHubRestError("github_template_required")
    _validate_contract(GitHubRestContract(
        value.repository, value.branch, value.base_branch, value.expected_base_sha,
        value.expected_base_sha, (0, 0), value.issue, value.title, value.body, value.draft,
    ))


class HostPublisher:
    """Own final validation, exact staging, one commit, one push and provenance."""

    def __init__(self, process: GitProcess | None = None) -> None:
        self._process = process or SubprocessGitProcess()
        self._used = False
        self._baseline_fingerprint: str | None = None

    def _run(self, request: HostPublishRequest, argv: tuple[str, ...]) -> str:
        result = self._process.run(
            argv, cwd=request.repo_root.resolve(), timeout_seconds=request.timeout_seconds,
            output_limit_bytes=request.output_limit_bytes,
        )
        if result.timed_out or result.truncated or result.exit_code != 0:
            raise GitHubRestError("host_command_failed")
        try:
            return result.stdout.decode("utf-8").rstrip("\r\n")
        except UnicodeDecodeError as exc:
            raise GitHubRestError("host_command_output_invalid") from exc

    def _validate_request(self, request: HostPublishRequest) -> None:
        if not isinstance(request, HostPublishRequest) or not request.repo_root.resolve().is_dir():
            raise GitHubRestError("host_publish_request_invalid")
        if not SHA_PATTERN.fullmatch(request.expected_base_sha):
            raise GitHubRestError("expected_base_invalid")
        if request.github.branch != request.branch or request.github.expected_base_sha != request.expected_base_sha:
            raise GitHubRestError("publish_template_drift")
        _validate_template(request.github)
        if not request.write_allowlist or len(set(request.write_allowlist)) != len(request.write_allowlist):
            raise GitHubRestError("write_allowlist_invalid")
        for path in request.write_allowlist:
            candidate = Path(path)
            if candidate.is_absolute() or ".." in candidate.parts or path.startswith(".git/"):
                raise GitHubRestError("write_allowlist_invalid")
        if not request.validation_argv or any(not argv for argv in request.validation_argv):
            raise GitHubRestError("validation_argv_invalid")
        for argv in request.validation_argv:
            allowed = (
                len(argv) >= 3
                and argv[0] in {"python", "python3", "py"}
                and argv[1] == "-m"
                and argv[2] in {"pytest", "compileall"}
            ) or argv == ("git", "diff", "--check")
            if not allowed or any("\x00" in item for item in argv):
                raise GitHubRestError("validation_argv_forbidden")
        if not request.commit_message or "\x00" in request.commit_message:
            raise GitHubRestError("commit_message_invalid")

    def preflight(self, request: HostPublishRequest, *, execute: bool = False) -> None:
        self._validate_request(request)
        if not execute:
            return
        if self._run(request, ("git", "branch", "--show-current")) != request.branch:
            raise GitHubRestError("branch_drift")
        if self._run(request, ("git", "rev-parse", "HEAD")) != request.expected_base_sha:
            raise GitHubRestError("base_head_drift")
        if self._run(request, ("git", "rev-parse", "origin/master")) != request.expected_base_sha:
            raise GitHubRestError("remote_base_drift")
        if self._run(request, ("git", "diff", "--cached", "--name-only")):
            raise GitHubRestError("initial_index_dirty")
        status = self._run(request, ("git", "status", "--porcelain", "--untracked-files=all"))
        if set(self._status_paths(status)) != set(request.write_allowlist):
            raise GitHubRestError("initial_path_scope_drift")
        self._baseline_fingerprint = self._baseline(request, status)

    def _baseline(self, request: HostPublishRequest, status: str) -> str:
        digest = hashlib.sha256()
        digest.update(request.branch.encode("utf-8"))
        digest.update(b"\0")
        digest.update(request.expected_base_sha.encode("ascii"))
        for line in sorted(status.splitlines()):
            digest.update(b"\0")
            digest.update(line.encode("utf-8"))
        for path in sorted(request.write_allowlist):
            candidate = request.repo_root.resolve() / path
            if not candidate.is_file():
                raise GitHubRestError("baseline_path_invalid")
            digest.update(b"\0")
            digest.update(path.encode("utf-8"))
            digest.update(b"\0")
            digest.update(hashlib.sha256(candidate.read_bytes()).digest())
        return "sha256:" + digest.hexdigest()

    def verify_baseline(self, request: HostPublishRequest, *, execute: bool = False) -> None:
        self._validate_request(request)
        if not execute:
            return
        if self._baseline_fingerprint is None:
            raise GitHubRestError("baseline_snapshot_missing")
        if self._run(request, ("git", "branch", "--show-current")) != request.branch:
            raise GitHubRestError("branch_drift")
        if self._run(request, ("git", "rev-parse", "HEAD")) != request.expected_base_sha:
            raise GitHubRestError("base_head_drift")
        if self._run(request, ("git", "rev-parse", "origin/master")) != request.expected_base_sha:
            raise GitHubRestError("remote_base_drift")
        if self._run(request, ("git", "diff", "--cached", "--name-only")):
            raise GitHubRestError("baseline_index_drift")
        status = self._run(request, ("git", "status", "--porcelain", "--untracked-files=all"))
        if set(self._status_paths(status)) != set(request.write_allowlist):
            raise GitHubRestError("baseline_path_scope_drift")
        if self._baseline(request, status) != self._baseline_fingerprint:
            raise GitHubRestError("baseline_fingerprint_drift")

    @staticmethod
    def _status_paths(status: str) -> tuple[str, ...]:
        paths = []
        for line in status.splitlines():
            if len(line) < 4 or " -> " in line:
                raise GitHubRestError("worktree_status_invalid")
            paths.append(line[3:])
        return tuple(paths)

    def publish(self, request: HostPublishRequest, *, execute: bool = False) -> GitHubRestContract:
        self._validate_request(request)
        if not execute:
            return GitHubRestContract(
                request.github.repository, request.branch, request.github.base_branch,
                request.expected_base_sha, request.expected_base_sha, (0, 0), request.github.issue,
                request.github.title, request.github.body, True,
            )
        if self._used:
            raise GitHubRestError("duplicate_host_publish")
        self._used = True
        if self._run(request, ("git", "branch", "--show-current")) != request.branch:
            raise GitHubRestError("branch_drift")
        if self._run(request, ("git", "rev-parse", "HEAD")) != request.expected_base_sha:
            raise GitHubRestError("child_git_write_detected")
        if self._run(request, ("git", "rev-parse", "origin/master")) != request.expected_base_sha:
            raise GitHubRestError("remote_base_drift")
        if self._run(request, ("git", "merge-base", "HEAD", "origin/master")) != request.expected_base_sha:
            raise GitHubRestError("base_ancestry_drift")
        if self._run(request, ("git", "diff", "--cached", "--name-only")):
            raise GitHubRestError("child_staged_changes")
        status = self._run(request, ("git", "status", "--porcelain", "--untracked-files=all"))
        if set(self._status_paths(status)) != set(request.write_allowlist):
            raise GitHubRestError("changed_path_scope_drift")
        for argv in request.validation_argv:
            self._run(request, argv)
        self._run(request, ("git", "add", "--", *request.write_allowlist))
        staged = self._run(request, ("git", "diff", "--cached", "--name-only"))
        if set(staged.splitlines()) != set(request.write_allowlist):
            raise GitHubRestError("staged_path_scope_drift")
        self._run(request, ("git", "diff", "--cached", "--check"))
        self._run(request, ("git", "commit", "-m", request.commit_message))
        head = self._run(request, ("git", "rev-parse", "HEAD"))
        if not SHA_PATTERN.fullmatch(head) or head == request.expected_base_sha:
            raise GitHubRestError("commit_provenance_invalid")
        base_divergence = self._run(
            request, ("git", "rev-list", "--left-right", "--count", "origin/master...HEAD")
        ).split()
        if base_divergence != ["0", "1"]:
            raise GitHubRestError("base_divergence_invalid")
        if self._run(request, ("git", "status", "--porcelain", "--untracked-files=all")):
            raise GitHubRestError("post_commit_worktree_dirty")
        self._run(request, ("git", "push", "origin", request.branch))
        remote = self._run(request, ("git", "rev-parse", f"origin/{request.branch}"))
        divergence = self._run(
            request, ("git", "rev-list", "--left-right", "--count", f"origin/{request.branch}...HEAD")
        ).split()
        if remote != head or divergence != ["0", "0"]:
            raise GitHubRestError("remote_provenance_invalid")
        return GitHubRestContract(
            request.github.repository, request.branch, request.github.base_branch, head, remote,
            (0, 0), request.github.issue, request.github.title, request.github.body, True,
        )


class GitHubRestClient:
    """Perform one existing-PR read and at most one Draft-PR mutation."""

    def __init__(
        self,
        token: str | None,
        *,
        transport: RestTransport | None = None,
        timeout_seconds: int = 30,
    ) -> None:
        self._token = token
        self._transport = transport or UrlLibRestTransport()
        self._timeout_seconds = timeout_seconds
        self._request_used = False

    @classmethod
    def from_environment(
        cls,
        environment: Mapping[str, str],
        *,
        transport: RestTransport | None = None,
        timeout_seconds: int = 30,
    ) -> "GitHubRestClient":
        token = environment.get("GITHUB_TOKEN")
        if not token:
            raise GitHubRestError("credentials_missing:GITHUB_TOKEN")
        return cls(token, transport=transport, timeout_seconds=timeout_seconds)

    def _call(self, method: str, url: str, body: bytes | None) -> RestResponse:
        if not self._token:
            raise GitHubRestError("credentials_missing:GITHUB_TOKEN")
        headers = {
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {self._token}",
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": "cse-orchestrator-o9",
        }
        if body is not None:
            headers["Content-Type"] = "application/json"
        try:
            return self._transport.request(
                method,
                url,
                headers=headers,
                body=body,
                timeout_seconds=self._timeout_seconds,
            )
        except (TimeoutError, socket.timeout, urllib.error.URLError) as exc:
            raise GitHubRestError("github_timeout") from exc
        except OSError as exc:
            raise GitHubRestError("github_transport_error") from exc

    def create_draft_pull_request(
        self,
        contract: GitHubRestContract,
        *,
        execute: bool = False,
    ) -> DraftPullRequestResult:
        _validate_contract(contract)
        if not execute:
            return DraftPullRequestResult(False, None, "planned", True, None)
        if self._request_used:
            raise GitHubRestError("duplicate_github_request")
        self._request_used = True
        owner = contract.repository.split("/", 1)[0]
        query = urllib.parse.urlencode(
            {
                "state": "open",
                "head": f"{owner}:{contract.branch}",
                "base": contract.base_branch,
            }
        )
        endpoint = f"{API_ROOT}/repos/{contract.repository}/pulls"
        existing = self._call("GET", f"{endpoint}?{query}", None)
        if existing.status_code != 200:
            raise GitHubRestError(f"github_preflight_error:{existing.status_code}")
        try:
            existing_value = json.loads(existing.body)
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise GitHubRestError("github_preflight_json_invalid") from exc
        if not isinstance(existing_value, list):
            raise GitHubRestError("github_preflight_shape_invalid")
        if existing_value:
            raise GitHubRestError("existing_open_pr")
        payload = {
            "title": contract.title,
            "body": contract.body,
            "head": contract.branch,
            "base": contract.base_branch,
            "draft": True,
        }
        created = self._call(
            "POST",
            endpoint,
            json.dumps(payload, separators=(",", ":")).encode("utf-8"),
        )
        if created.status_code != 201:
            raise GitHubRestError(f"github_create_error:{created.status_code}")
        try:
            value = json.loads(created.body)
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise GitHubRestError("github_response_json_invalid") from exc
        if (
            not isinstance(value, dict)
            or isinstance(value.get("number"), bool)
            or not isinstance(value.get("number"), int)
            or value.get("state") != "open"
            or value.get("draft") is not True
        ):
            raise GitHubRestError("github_response_invalid")
        normalized_headers = {str(key).lower(): str(item) for key, item in created.headers.items()}
        return DraftPullRequestResult(
            True,
            value["number"],
            "open",
            True,
            normalized_headers.get("x-github-request-id"),
        )
