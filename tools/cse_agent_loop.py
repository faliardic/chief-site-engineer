"""GitHub-hosted CSE Codex/ChatGPT review loop.

The workflow uses this helper to select an approved task Issue, prepare a
bounded Codex prompt, run deterministic validation and scope checks, and ask a
review model to approve the resulting diff or request a bounded correction.
Git and publication remain host-controlled operations.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any, Mapping, Sequence

from tools.cse_api_bridge import BridgeError, GitHubClient, parse_task, validate_command
from tools.cse_bridge_poll import select_task, task_ready

RUNTIME_DIR = Path(".cse") / "agent-loop"
STATUS_PREFIX = "<!-- cse-agent-loop-status:"


def _github() -> GitHubClient:
    repository = os.environ.get("GITHUB_REPOSITORY", "").strip()
    token = os.environ.get("GITHUB_TOKEN", "").strip()
    if not repository or not token:
        raise BridgeError("github_configuration_missing")
    return GitHubClient(
        repository,
        token,
        os.environ.get("GITHUB_API_URL", "https://api.github.com"),
    )


def _write_output(name: str, value: str) -> None:
    destination = os.environ.get("GITHUB_OUTPUT", "").strip()
    if not destination:
        print(f"{name}={value}")
        return
    with Path(destination).open("a", encoding="utf-8") as stream:
        stream.write(f"{name}<<CSE_EOF\n{value}\nCSE_EOF\n")


def _issue_number(value: str) -> int:
    try:
        number = int(value)
    except ValueError as exc:
        raise BridgeError("issue_number_invalid") from exc
    if number <= 0:
        raise BridgeError("issue_number_invalid")
    return number


def _issue_and_task(github: GitHubClient, issue_number: int):
    issue = github.issue(issue_number)
    body = issue.get("body")
    if not isinstance(body, str):
        raise BridgeError("task_body_missing")
    task = parse_task(body)
    if task.repository.casefold() != github.repository.casefold():
        raise BridgeError("task_repository_mismatch")
    return issue, body, task


def command_select(args: argparse.Namespace) -> int:
    github = _github()
    issue_number: int | None
    if args.issue_number:
        issue_number = _issue_number(args.issue_number)
        issue = github.issue(issue_number)
        comments = github.comments(issue_number)
        if not task_ready(issue, comments):
            raise BridgeError("task_not_ready")
    else:
        issue_number = select_task(github)
    if issue_number is None:
        _write_output("found", "false")
        return 0
    _write_output("found", "true")
    _write_output("issue_number", str(issue_number))
    return 0


def _implement_prompt(issue_number: int, body: str) -> str:
    return f"""You are the CSE Codex implementation agent for GitHub Issue #{issue_number}.

Execute the task exactly as specified in the Issue body below.

Host-controlled boundaries:
- Work only in the current checked-out task branch.
- Modify only paths listed under `Allowed paths`.
- Do not commit, push, create or merge pull requests, comment on GitHub, or alter workflows unless explicitly allowlisted.
- Do not access devices, user data, credentials, reports, backups, exports, or release operations.
- Run useful focused checks while working, but the host will run the binding validation commands.
- Finish with the working tree containing the smallest complete implementation.

ISSUE BODY
==========
{body}
"""


def _correction_prompt(issue_number: int, body: str, feedback: str, round_number: int) -> str:
    return f"""You are the CSE Codex correction agent for GitHub Issue #{issue_number}, review round {round_number}.

The prior implementation was reviewed. Address every actionable item below while preserving the Issue scope and existing correct behavior.

Host-controlled boundaries:
- Modify only paths listed under `Allowed paths`.
- Do not commit, push, create or merge pull requests, or comment on GitHub.
- Do not broaden scope or change unrelated files.
- Finish with a clean, reviewable implementation ready for binding host validation.

ISSUE BODY
==========
{body}

REVIEW FEEDBACK
===============
{feedback}
"""


def command_prepare(args: argparse.Namespace) -> int:
    github = _github()
    issue_number = _issue_number(args.issue_number)
    _issue, body, task = _issue_and_task(github, issue_number)
    RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
    prompt_path = RUNTIME_DIR / "implement-prompt.md"
    prompt_path.write_text(_implement_prompt(issue_number, body), encoding="utf-8")
    _write_output("base", task.base)
    _write_output("branch", task.branch)
    _write_output("commit_subject", task.commit_subject)
    _write_output("pr_title", task.pr_title)
    _write_output("pr_body", f"{task.pr_body_first_line}\n\nRelated to #{issue_number}")
    _write_output("prompt_file", prompt_path.as_posix())
    return 0


def command_correction_prompt(args: argparse.Namespace) -> int:
    github = _github()
    issue_number = _issue_number(args.issue_number)
    _issue, body, _task = _issue_and_task(github, issue_number)
    feedback = Path(args.feedback_file).read_text(encoding="utf-8").strip()
    if not feedback:
        raise BridgeError("review_feedback_missing")
    RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
    prompt_path = RUNTIME_DIR / f"correction-{args.round_number}.md"
    prompt_path.write_text(
        _correction_prompt(issue_number, body, feedback, args.round_number),
        encoding="utf-8",
    )
    _write_output("prompt_file", prompt_path.as_posix())
    return 0


def command_comment(args: argparse.Namespace) -> int:
    github = _github()
    issue_number = _issue_number(args.issue_number)
    marker = f"{STATUS_PREFIX}{args.state} -->"
    body = f"{marker}\n{args.message.strip()}"
    comments = github.comments(issue_number)
    if any(marker in str(comment.get("body", "")) for comment in comments):
        return 0
    github.comment(issue_number, body)
    return 0


def _run(argv: Sequence[str], cwd: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        list(argv),
        cwd=cwd,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding="utf-8",
        errors="replace",
        shell=False,
        check=False,
    )


def command_validate(args: argparse.Namespace) -> int:
    github = _github()
    issue_number = _issue_number(args.issue_number)
    _issue, _body, task = _issue_and_task(github, issue_number)
    root = Path(args.repo_root).resolve()
    RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
    log_path = RUNTIME_DIR / f"validation-{args.round_number}.log"
    chunks: list[str] = []
    for command in task.validation_commands:
        argv = validate_command(command)
        result = _run(argv, root)
        chunks.append(f"$ {command}\n{result.stdout}\nexit={result.returncode}\n")
        if result.returncode != 0:
            log_path.write_text("\n".join(chunks), encoding="utf-8")
            _write_output("validation_log", log_path.as_posix())
            raise BridgeError("validation_failed")
    log_path.write_text("\n".join(chunks), encoding="utf-8")
    _write_output("validation_log", log_path.as_posix())
    return 0


def _changed_paths(root: Path, base: str) -> tuple[str, ...]:
    result = _run(("git", "diff", "--name-only", f"origin/{base}...HEAD"), root)
    if result.returncode != 0:
        raise BridgeError("scope_diff_failed")
    committed = {line.strip() for line in result.stdout.splitlines() if line.strip()}
    result = _run(("git", "status", "--porcelain"), root)
    if result.returncode != 0:
        raise BridgeError("scope_status_failed")
    working = {
        line[3:].strip().replace("\\", "/")
        for line in result.stdout.splitlines()
        if len(line) >= 4
    }
    working = {path.split(" -> ")[-1] for path in working}
    return tuple(sorted(committed | working))


def command_scope(args: argparse.Namespace) -> int:
    github = _github()
    issue_number = _issue_number(args.issue_number)
    _issue, _body, task = _issue_and_task(github, issue_number)
    root = Path(args.repo_root).resolve()
    changed = _changed_paths(root, task.base)
    if not changed:
        raise BridgeError("no_task_changes")
    from tools.cse_api_bridge import path_allowed

    unexpected = [path for path in changed if not path_allowed(path, task.allowed_paths)]
    if unexpected:
        print("unexpected_paths=" + ",".join(unexpected), file=sys.stderr)
        raise BridgeError("task_scope_violation")
    _write_output("changed_paths", "\n".join(changed))
    return 0


def _safe_diff(root: Path, base: str, limit: int = 120_000) -> str:
    result = _run(("git", "diff", "--no-ext-diff", f"origin/{base}...HEAD"), root)
    if result.returncode != 0:
        raise BridgeError("review_diff_failed")
    return result.stdout[:limit]


def _review_prompt(issue_number: int, body: str, diff: str, validation: str) -> str:
    return f"""You are the independent ChatGPT reviewer for CSE GitHub Issue #{issue_number}.

Review only the Issue contract, proposed diff, and validation evidence below. Check correctness, scope, regressions, safety boundaries, and whether every requested acceptance condition is actually met.

Return exactly one of these formats:

APPROVED
<one concise approval rationale>

or

CHANGES_REQUESTED
1. <specific actionable correction>
2. <specific actionable correction>

Do not request unrelated improvements. Do not approve if the evidence is insufficient.

ISSUE BODY
==========
{body}

DIFF
====
{diff}

VALIDATION
==========
{validation}
"""


def command_review(args: argparse.Namespace) -> int:
    from openai import OpenAI

    github = _github()
    issue_number = _issue_number(args.issue_number)
    _issue, body, task = _issue_and_task(github, issue_number)
    root = Path(args.repo_root).resolve()
    validation = Path(args.validation_log).read_text(encoding="utf-8")[:40_000]
    prompt = _review_prompt(issue_number, body, _safe_diff(root, task.base), validation)
    model = os.environ.get("CSE_REVIEW_MODEL", "gpt-5.6").strip() or "gpt-5.6"
    client = OpenAI(max_retries=0, timeout=180.0)
    try:
        response = client.responses.create(model=model, input=prompt, store=False)
        text = response.output_text.strip()
    finally:
        client.close()
    RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
    feedback_path = RUNTIME_DIR / f"review-{args.round_number}.txt"
    feedback_path.write_text(text + "\n", encoding="utf-8")
    first_line = text.splitlines()[0].strip() if text else ""
    if first_line == "APPROVED":
        verdict = "approved"
    elif first_line == "CHANGES_REQUESTED":
        verdict = "changes_requested"
    else:
        verdict = "needs_human"
    _write_output("verdict", verdict)
    _write_output("feedback_file", feedback_path.as_posix())
    return 0


def command_pr(args: argparse.Namespace) -> int:
    github = _github()
    issue_number = _issue_number(args.issue_number)
    _issue, _body, task = _issue_and_task(github, issue_number)
    pr = github.create_draft_pr(task)
    url = str(pr.get("html_url", ""))
    number = pr.get("number")
    if not url or not isinstance(number, int):
        raise BridgeError("draft_pr_invalid")
    _write_output("pr_url", url)
    _write_output("pr_number", str(number))
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    select = subparsers.add_parser("select")
    select.add_argument("--issue-number", default="")
    select.set_defaults(func=command_select)

    prepare = subparsers.add_parser("prepare")
    prepare.add_argument("--issue-number", required=True)
    prepare.set_defaults(func=command_prepare)

    correction = subparsers.add_parser("correction-prompt")
    correction.add_argument("--issue-number", required=True)
    correction.add_argument("--round-number", type=int, required=True)
    correction.add_argument("--feedback-file", required=True)
    correction.set_defaults(func=command_correction_prompt)

    comment = subparsers.add_parser("comment")
    comment.add_argument("--issue-number", required=True)
    comment.add_argument("--state", required=True)
    comment.add_argument("--message", required=True)
    comment.set_defaults(func=command_comment)

    validate = subparsers.add_parser("validate")
    validate.add_argument("--issue-number", required=True)
    validate.add_argument("--round-number", type=int, required=True)
    validate.add_argument("--repo-root", default=".")
    validate.set_defaults(func=command_validate)

    scope = subparsers.add_parser("scope")
    scope.add_argument("--issue-number", required=True)
    scope.add_argument("--repo-root", default=".")
    scope.set_defaults(func=command_scope)

    review = subparsers.add_parser("review")
    review.add_argument("--issue-number", required=True)
    review.add_argument("--round-number", type=int, required=True)
    review.add_argument("--validation-log", required=True)
    review.add_argument("--repo-root", default=".")
    review.set_defaults(func=command_review)

    pr = subparsers.add_parser("pr")
    pr.add_argument("--issue-number", required=True)
    pr.set_defaults(func=command_pr)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        return int(args.func(args))
    except BridgeError as exc:
        print(exc.reason, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
