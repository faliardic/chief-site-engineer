"""Find one approved CSE bridge task and execute it.

The poller is intentionally small. It does not edit code, choose scope, or
publish. It only selects a task whose latest trusted approval is newer than any
WAITING_CONFIG/RUNNING marker, then delegates to cse_api_bridge.
"""

from __future__ import annotations

import argparse
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping, Sequence

from tools.cse_api_bridge import (
    APPROVAL_LINE,
    TASK_MARKER,
    TRUSTED_ASSOCIATIONS,
    BridgeError,
    GitHubClient,
    execute,
)

TERMINAL_MARKERS = (
    "<!-- cse-bridge-status:PASS -->",
    "<!-- cse-bridge-status:FAILED -->",
    "<!-- cse-bridge-status:NEEDS_HUMAN -->",
)
PAUSE_MARKERS = (
    "<!-- cse-bridge-status:WAITING_CONFIG -->",
    "<!-- cse-bridge-status:RUNNING -->",
)


def _timestamp(value: object) -> datetime:
    if not isinstance(value, str) or not value:
        return datetime.min.replace(tzinfo=timezone.utc)
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return datetime.min.replace(tzinfo=timezone.utc)
    return parsed if parsed.tzinfo is not None else parsed.replace(tzinfo=timezone.utc)


def task_ready(
    issue: Mapping[str, Any], comments: Sequence[Mapping[str, Any]]
) -> bool:
    if "pull_request" in issue:
        return False
    body = issue.get("body")
    if not isinstance(body, str) or TASK_MARKER not in body:
        return False

    latest_approval = datetime.min.replace(tzinfo=timezone.utc)
    latest_pause = datetime.min.replace(tzinfo=timezone.utc)
    for comment in comments:
        comment_body = str(comment.get("body", ""))
        if any(marker in comment_body for marker in TERMINAL_MARKERS):
            return False
        lines = {line.strip() for line in comment_body.splitlines()}
        created = _timestamp(comment.get("created_at"))
        if (
            APPROVAL_LINE in lines
            and str(comment.get("author_association", ""))
            in TRUSTED_ASSOCIATIONS
        ):
            latest_approval = max(latest_approval, created)
        if any(marker in comment_body for marker in PAUSE_MARKERS):
            latest_pause = max(latest_pause, created)

    return latest_approval > latest_pause


def select_task(github: GitHubClient) -> int | None:
    issues = github.request(
        "GET", f"/repos/{github.repository}/issues?state=open&per_page=100"
    )
    candidates: list[int] = []
    for issue in issues:
        number = issue.get("number")
        if not isinstance(number, int):
            continue
        comments = github.comments(number)
        if task_ready(issue, comments):
            candidates.append(number)
    return min(candidates) if candidates else None


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", type=Path, default=Path.cwd())
    args = parser.parse_args(argv)

    repository = os.environ.get("GITHUB_REPOSITORY", "")
    token = os.environ.get("GITHUB_TOKEN", "")
    if not repository or not token:
        raise SystemExit("github_configuration_missing")

    github = GitHubClient(
        repository,
        token,
        os.environ.get("GITHUB_API_URL", "https://api.github.com"),
    )
    try:
        issue_number = select_task(github)
        if issue_number is None:
            return 0
        return execute(issue_number, args.repo_root.resolve())
    except BridgeError as exc:
        print(exc.reason)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
