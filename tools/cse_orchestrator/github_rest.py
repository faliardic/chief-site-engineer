"""One-mutation GitHub REST Draft-PR adapter for CSE O9."""

from __future__ import annotations

import json
import re
import socket
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
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
