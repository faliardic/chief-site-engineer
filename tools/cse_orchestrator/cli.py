"""Observe-only command-line interface for the CSE O1 observer."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Sequence

from .observer import REPOSITORY_PATTERN, observe_repository


def _positive_issue(value: str) -> int:
    try:
        issue = int(value)
    except ValueError as exc:
        raise argparse.ArgumentTypeError("issue must be a positive integer") from exc
    if issue < 1:
        raise argparse.ArgumentTypeError("issue must be a positive integer")
    return issue


def _repository(value: str) -> str:
    if not REPOSITORY_PATTERN.fullmatch(value):
        raise argparse.ArgumentTypeError("repository must be owner/name")
    return value


def _strict_path(value: str) -> Path:
    if not value or "\x00" in value:
        raise argparse.ArgumentTypeError("path is invalid")
    return Path(value)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="python -m tools.cse_orchestrator.cli",
        description="CSE Development Orchestrator read-only observer",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)
    observe = subparsers.add_parser(
        "observe",
        help="Collect one sanitized, read-only Observation v1",
    )
    observe.add_argument("--repo-root", required=True, type=_strict_path)
    observe.add_argument("--repository", required=True, type=_repository)
    observe.add_argument("--issue", required=True, type=_positive_issue)
    observe.add_argument("--runtime-root", required=True, type=_strict_path)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if args.command != "observe":
        return 2
    try:
        observation = observe_repository(
            repo_root=args.repo_root,
            repository=args.repository,
            issue_number=args.issue,
            runtime_root=args.runtime_root,
        )
    except (OSError, RuntimeError, ValueError):
        observation = {
            "schema_version": 1,
            "state": "PREFLIGHT_BLOCKED",
            "blockers": [
                {"code": "SOURCE_FAILURE", "reason": "observer_initialization_failed"}
            ],
            "exit_code": 11,
        }
    print(json.dumps(observation, ensure_ascii=False, indent=2, sort_keys=True))
    return int(observation.get("exit_code", 11))


if __name__ == "__main__":
    raise SystemExit(main())
