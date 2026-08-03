"""Minimal GitHub Issue -> OpenAI Responses API -> Draft PR bridge.

The bridge intentionally exposes only bounded file tools to the model. Git,
validation and publication remain deterministic host-side operations.
"""

from __future__ import annotations

import argparse
import fnmatch
import json
import os
import re
import shlex
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from pathlib import Path, PurePosixPath
from typing import Any, Iterable, Mapping, Sequence

TASK_MARKER = "<!-- cse-bridge-task:v1 -->"
APPROVAL_LINE = "CSE_BRIDGE_APPROVED"
STATUS_PREFIX = "<!-- cse-bridge-status:"
TERMINAL_STATES = {"PASS", "FAILED", "NEEDS_HUMAN"}
ALLOWED_APPROVER_ASSOCIATIONS = {"OWNER", "MEMBER", "COLLABORATOR"}
PROTECTED_PREFIXES = (
    ".git/",
    ".github/workflows/",
    ".cse/state/",
    "device-backups/",
    "reports/",
    "exports/",
)
PROTECTED_EXACT = {
    ".env",
    ".env.local",
    "credentials.json",
    "secrets.json",
}
SECRET_PATTERN = re.compile(
    r"(?i)(authorization\s*:\s*bearer\s+\S+|(?:api[_-]?key|token|secret|password)"
    r"\s*[:=]\s*\S+|sk-[A-Za-z0-9_-]{12,}|gh[pousr]_[A-Za-z0-9_]{12,})"
)
SHELL_META_PATTERN = re.compile(r"[;&|><`]|\$\(|\r|\n")


class BridgeError(RuntimeError):
    """Stable bridge failure suitable for a data-minimal Issue comment."""

    def __init__(self, reason: str):
        super().__init__(reason)
        self.reason = reason


@dataclass(frozen=True)
class BridgeTask:
    repository: str
    base: str
    branch: str
    goal: str
    allowed_paths: tuple[str, ...]
    validation_commands: tuple[str, ...]
    commit_subject: str
    pr_title: str
    pr_body_first_line: str


def _section_map(body: str) -> dict[str, str]:
    sections: dict[str, list[str]] = {}
    current: str | None = None
    for line in body.replace("\r\n", "\n").replace("\r", "\n").split("\n"):
        match = re.fullmatch(r"##\s+(.+?)\s*", line)
        if match:
            current = match.group(1).strip()
            if current in sections:
                raise BridgeError("duplicate_task_section")
            sections[current] = []
        elif current is not None:
            sections[current].append(line)
    return {key: "\n".join(value).strip() for key, value in sections.items()}


def _single_line(value: str, reason: str) -> str:
    lines = [line.strip() for line in value.splitlines() if line.strip()]
    if len(lines) != 1 or len(lines[0]) > 200:
        raise BridgeError(reason)
    return lines[0]


def _bullet_lines(value: str, reason: str) -> tuple[str, ...]:
    result: list[str] = []
    for line in value.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        if not stripped.startswith("- "):
            raise BridgeError(reason)
        result.append(stripped[2:].strip())
    if not result or len(result) > 64:
        raise BridgeError(reason)
    return tuple(result)


def normalize_repo_path(value: str) -> str:
    value = value.replace("\\", "/").strip()
    path = PurePosixPath(value)
    if (
        not value
        or path.is_absolute()
        or any(part in {"", ".", ".."} for part in path.parts)
        or ":" in value
        or "\x00" in value
    ):
        raise BridgeError("task_path_invalid")
    normalized = path.as_posix()
    if normalized in PROTECTED_EXACT or any(
        normalized == prefix.rstrip("/") or normalized.startswith(prefix)
        for prefix in PROTECTED_PREFIXES
    ):
        raise BridgeError("task_path_protected")
    return normalized


def parse_task(body: str) -> BridgeTask:
    if TASK_MARKER not in body:
        raise BridgeError("task_marker_missing")
    sections = _section_map(body)
    required = {
        "Repository",
        "Base",
        "Branch",
        "Goal",
        "Allowed paths",
        "Validation commands",
        "Commit",
        "Draft PR",
    }
    if set(sections) != required:
        raise BridgeError("task_sections_invalid")
    repository = _single_line(sections["Repository"], "task_repository_invalid")
    if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", repository):
        raise BridgeError("task_repository_invalid")
    base = _single_line(sections["Base"], "task_base_invalid")
    branch = _single_line(sections["Branch"], "task_branch_invalid")
    if not re.fullmatch(r"codex/[a-z0-9][a-z0-9._/-]{2,120}", branch):
        raise BridgeError("task_branch_invalid")
    goal = sections["Goal"].strip()
    if not goal or len(goal) > 20_000 or SECRET_PATTERN.search(goal):
        raise BridgeError("task_goal_invalid")
    allowed_paths = tuple(
        normalize_repo_path(item)
        for item in _bullet_lines(sections["Allowed paths"], "task_allowlist_invalid")
    )
    validation_commands = _bullet_lines(
        sections["Validation commands"], "task_validation_invalid"
    )
    for command in validation_commands:
        validate_command(command)
    commit_subject = _single_line(sections["Commit"], "task_commit_invalid")
    if len(commit_subject) > 100 or SECRET_PATTERN.search(commit_subject):
        raise BridgeError("task_commit_invalid")
    pr_lines = [line.strip() for line in sections["Draft PR"].splitlines() if line.strip()]
    if len(pr_lines) != 2 or any(len(line) > 200 for line in pr_lines):
        raise BridgeError("task_pr_invalid")
    return BridgeTask(
        repository=repository,
        base=base,
        branch=branch,
        goal=goal,
        allowed_paths=allowed_paths,
        validation_commands=validation_commands,
        commit_subject=commit_subject,
        pr_title=pr_lines[0],
        pr_body_first_line=pr_lines[1],
    )


def path_allowed(path: str, patterns: Sequence[str]) -> bool:
    normalized = normalize_repo_path(path)
    return any(fnmatch.fnmatchcase(normalized, pattern) for pattern in patterns)


def validate_command(command: str) -> tuple[str, ...]:
    if not command or len(command) > 1000 or SHELL_META_PATTERN.search(command):
        raise BridgeError("validation_command_forbidden")
    try:
        argv = tuple(shlex.split(command, posix=os.name != "nt"))
    except ValueError as exc:
        raise BridgeError("validation_command_invalid") from exc
    if not argv:
        raise BridgeError("validation_command_invalid")
    executable = Path(argv[0]).name.lower()
    if executable in {"python", "python.exe", "py", "py.exe"}:
        if len(argv) < 3 or argv[1] != "-m" or argv[2] not in {
            "pytest",
            "unittest",
            "compileall",
        }:
            raise BridgeError("validation_command_forbidden")
    elif executable in {"flutter", "flutter.bat"}:
        if len(argv) < 2 or argv[1] not in {"test", "analyze", "build"}:
            raise BridgeError("validation_command_forbidden")
    elif executable in {"git", "git.exe"}:
        if argv[1:] != ("diff", "--check"):
            raise BridgeError("validation_command_forbidden")
    else:
        raise BridgeError("validation_command_forbidden")
    lowered = {item.lower() for item in argv}
    if lowered & {
        "adb",
        "adb.exe",
        "uninstall",
        "clear-data",
        "clean",
        "reset",
        "push",
        "merge",
        "release",
    }:
        raise BridgeError("validation_command_forbidden")
    return argv


def redact(value: str) -> str:
    return SECRET_PATTERN.sub("[REDACTED]", value)[:6000]


def terminal_state(comments: Sequence[Mapping[str, Any]]) -> str | None:
    for comment in reversed(comments):
        body = str(comment.get("body", ""))
        match = re.search(r"<!-- cse-bridge-status:(PASS|FAILED|NEEDS_HUMAN) -->", body)
        if match:
            return match.group(1)
    return None


def approved(comments: Sequence[Mapping[str, Any]]) -> bool:
    for comment in comments:
        body = str(comment.get("body", ""))
        association = str(comment.get("author_association", ""))
        if association in ALLOWED_APPROVER_ASSOCIATIONS and APPROVAL_LINE in {
            line.strip() for line in body.splitlines()
        }:
            return True
    return False


class GitHubClient:
    def __init__(self, repository: str, token: str, api_url: str = "https://api.github.com"):
        self.repository = repository
        self.api_url = api_url.rstrip("/")
        self.headers = {
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": "cse-api-bridge",
        }

    def request(self, method: str, path: str, payload: Mapping[str, Any] | None = None) -> Any:
        data = json.dumps(payload).encode("utf-8") if payload is not None else None
        request = urllib.request.Request(
            f"{self.api_url}{path}", data=data, method=method, headers=self.headers
        )
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                raw = response.read()
        except urllib.error.HTTPError as exc:
            raise BridgeError(f"github_http_{exc.code}") from exc
        except (OSError, TimeoutError) as exc:
            raise BridgeError("github_unavailable") from exc
        return json.loads(raw.decode("utf-8")) if raw else None

    def issue(self, number: int) -> Mapping[str, Any]:
        return self.request("GET", f"/repos/{self.repository}/issues/{number}")

    def comments(self, number: int) -> list[Mapping[str, Any]]:
        value = self.request(
            "GET", f"/repos/{self.repository}/issues/{number}/comments?per_page=100"
        )
        return list(value)

    def comment(self, number: int, body: str) -> None:
        self.request(
            "POST",
            f"/repos/{self.repository}/issues/{number}/comments",
            {"body": body},
        )

    def open_pr_for_branch(self, branch: str) -> Mapping[str, Any] | None:
        owner = self.repository.split("/", 1)[0]
        head = urllib.parse.quote(f"{owner}:{branch}", safe="")
        value = self.request(
            "GET", f"/repos/{self.repository}/pulls?state=open&head={head}&per_page=10"
        )
        return value[0] if value else None

    def create_draft_pr(self, task: BridgeTask) -> Mapping[str, Any]:
        existing = self.open_pr_for_branch(task.branch)
        if existing is not None:
            return existing
        return self.request(
            "POST",
            f"/repos/{self.repository}/pulls",
            {
                "title": task.pr_title,
                "head": task.branch,
                "base": task.base,
                "body": task.pr_body_first_line,
                "draft": True,
            },
        )


class ResponsesClient:
    def __init__(self, api_key: str, model: str):
        self.api_key = api_key
        self.model = model

    def create(self, payload: Mapping[str, Any]) -> Mapping[str, Any]:
        request = urllib.request.Request(
            "https://api.openai.com/v1/responses",
            data=json.dumps(payload).encode("utf-8"),
            method="POST",
            headers={
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json",
                "User-Agent": "cse-api-bridge",
            },
        )
        delay = 2.0
        for attempt in range(3):
            try:
                with urllib.request.urlopen(request, timeout=180) as response:
                    return json.loads(response.read().decode("utf-8"))
            except urllib.error.HTTPError as exc:
                if exc.code not in {408, 409, 429, 500, 502, 503, 504} or attempt == 2:
                    raise BridgeError(f"openai_http_{exc.code}") from exc
            except (OSError, TimeoutError) as exc:
                if attempt == 2:
                    raise BridgeError("openai_unavailable") from exc
            time.sleep(delay)
            delay *= 2
        raise BridgeError("openai_unavailable")


TOOLS = [
    {
        "type": "function",
        "name": "read_file",
        "description": "Read one tracked, non-protected UTF-8 repository file.",
        "parameters": {
            "type": "object",
            "properties": {"path": {"type": "string"}},
            "required": ["path"],
            "additionalProperties": False,
        },
        "strict": True,
    },
    {
        "type": "function",
        "name": "search_files",
        "description": "Search tracked text files for a literal query.",
        "parameters": {
            "type": "object",
            "properties": {
                "query": {"type": "string"},
                "roots": {"type": "array", "items": {"type": "string"}},
            },
            "required": ["query", "roots"],
            "additionalProperties": False,
        },
        "strict": True,
    },
    {
        "type": "function",
        "name": "write_file",
        "description": "Write one UTF-8 file inside the task write allowlist.",
        "parameters": {
            "type": "object",
            "properties": {
                "path": {"type": "string"},
                "content": {"type": "string"},
            },
            "required": ["path", "content"],
            "additionalProperties": False,
        },
        "strict": True,
    },
    {
        "type": "function",
        "name": "replace_text",
        "description": "Replace one exact text occurrence in an allowlisted file.",
        "parameters": {
            "type": "object",
            "properties": {
                "path": {"type": "string"},
                "old": {"type": "string"},
                "new": {"type": "string"},
            },
            "required": ["path", "old", "new"],
            "additionalProperties": False,
        },
        "strict": True,
    },
    {
        "type": "function",
        "name": "list_changed_paths",
        "description": "List current Git changed paths.",
        "parameters": {"type": "object", "properties": {}, "additionalProperties": False},
        "strict": True,
    },
    {
        "type": "function",
        "name": "finish",
        "description": "Finish the coding pass with a concise summary.",
        "parameters": {
            "type": "object",
            "properties": {"summary": {"type": "string"}},
            "required": ["summary"],
            "additionalProperties": False,
        },
        "strict": True,
    },
]


def _run(argv: Sequence[str], *, cwd: Path, timeout: int = 120, check: bool = True) -> subprocess.CompletedProcess[str]:
    try:
        result = subprocess.run(
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
        raise BridgeError("host_command_unavailable") from exc
    if check and result.returncode != 0:
        raise BridgeError("host_command_failed")
    return result


def changed_paths(root: Path) -> tuple[str, ...]:
    value = _run(
        ["git", "status", "--porcelain=v1", "--untracked-files=all"],
        cwd=root,
    ).stdout
    result: set[str] = set()
    for line in value.splitlines():
        if len(line) < 4:
            continue
        path = line[3:]
        if " -> " in path:
            path = path.split(" -> ", 1)[1]
        result.add(path.replace("\\", "/"))
    return tuple(sorted(result))


class LocalTools:
    def __init__(self, root: Path, task: BridgeTask):
        self.root = root.resolve()
        self.task = task
        self.finished_summary: str | None = None

    def _path(self, value: str, *, write: bool) -> Path:
        normalized = normalize_repo_path(value)
        if write and not path_allowed(normalized, self.task.allowed_paths):
            raise BridgeError("model_write_out_of_scope")
        path = (self.root / normalized).resolve()
        try:
            path.relative_to(self.root)
        except ValueError as exc:
            raise BridgeError("model_path_escape") from exc
        if not write and path.exists():
            tracked = _run(
                ["git", "ls-files", "--error-unmatch", normalized],
                cwd=self.root,
                check=False,
            )
            if tracked.returncode != 0:
                raise BridgeError("model_read_untracked_forbidden")
        return path

    def dispatch(self, name: str, arguments: Mapping[str, Any]) -> Mapping[str, Any]:
        if name == "read_file":
            path = self._path(str(arguments["path"]), write=False)
            if not path.is_file() or path.stat().st_size > 512_000:
                raise BridgeError("model_read_unavailable")
            return {"content": path.read_text(encoding="utf-8")}
        if name == "search_files":
            query = str(arguments["query"])
            if not query or len(query) > 200:
                raise BridgeError("model_search_invalid")
            roots = [normalize_repo_path(str(item)) for item in arguments["roots"]]
            tracked = _run(["git", "ls-files"], cwd=self.root).stdout.splitlines()
            hits: list[dict[str, Any]] = []
            for candidate in tracked:
                normalized = candidate.replace("\\", "/")
                if roots and not any(
                    normalized == root or normalized.startswith(root.rstrip("/") + "/")
                    for root in roots
                ):
                    continue
                try:
                    normalize_repo_path(normalized)
                except BridgeError:
                    continue
                path = self.root / normalized
                if not path.is_file() or path.stat().st_size > 256_000:
                    continue
                try:
                    lines = path.read_text(encoding="utf-8").splitlines()
                except UnicodeDecodeError:
                    continue
                for number, line in enumerate(lines, 1):
                    if query in line:
                        hits.append({"path": normalized, "line": number, "text": line[:500]})
                        if len(hits) >= 50:
                            return {"hits": hits}
            return {"hits": hits}
        if name == "write_file":
            path = self._path(str(arguments["path"]), write=True)
            content = str(arguments["content"])
            if len(content.encode("utf-8")) > 1_000_000 or SECRET_PATTERN.search(content):
                raise BridgeError("model_write_invalid")
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8", newline="\n")
            return {"written": path.relative_to(self.root).as_posix()}
        if name == "replace_text":
            path = self._path(str(arguments["path"]), write=True)
            old = str(arguments["old"])
            new = str(arguments["new"])
            if not path.is_file() or not old or SECRET_PATTERN.search(new):
                raise BridgeError("model_replace_invalid")
            current = path.read_text(encoding="utf-8")
            if current.count(old) != 1:
                raise BridgeError("model_replace_not_exact")
            path.write_text(current.replace(old, new, 1), encoding="utf-8", newline="\n")
            return {"replaced": path.relative_to(self.root).as_posix()}
        if name == "list_changed_paths":
            return {"paths": list(changed_paths(self.root))}
        if name == "finish":
            summary = redact(str(arguments["summary"]))
            if not summary:
                raise BridgeError("model_finish_invalid")
            self.finished_summary = summary
            return {"finished": True}
        raise BridgeError("model_tool_forbidden")


def run_model(client: ResponsesClient, tools: LocalTools, prompt: str) -> str:
    payload: dict[str, Any] = {
        "model": client.model,
        "input": prompt,
        "tools": TOOLS,
        "tool_choice": "auto",
        "store": False,
    }
    for _ in range(40):
        response = client.create(payload)
        output = response.get("output")
        if not isinstance(output, list):
            raise BridgeError("openai_response_invalid")
        calls = [item for item in output if item.get("type") == "function_call"]
        if not calls:
            raise BridgeError("model_finished_without_finish")
        if any(item.get("name") == "finish" for item in calls) and len(calls) != 1:
            raise BridgeError("model_finish_must_be_single")
        results: list[dict[str, Any]] = []
        for call in calls:
            try:
                arguments = json.loads(str(call.get("arguments", "{}")))
            except json.JSONDecodeError as exc:
                raise BridgeError("model_arguments_invalid") from exc
            if not isinstance(arguments, Mapping):
                raise BridgeError("model_arguments_invalid")
            result = tools.dispatch(str(call.get("name", "")), arguments)
            results.append(
                {
                    "type": "function_call_output",
                    "call_id": str(call.get("call_id", "")),
                    "output": json.dumps(result, ensure_ascii=False),
                }
            )
        if tools.finished_summary is not None:
            return tools.finished_summary
        response_id = response.get("id")
        if not isinstance(response_id, str) or not response_id:
            raise BridgeError("openai_response_invalid")
        payload = {
            "model": client.model,
            "previous_response_id": response_id,
            "input": results,
            "tools": TOOLS,
            "tool_choice": "auto",
            "store": False,
        }
    raise BridgeError("model_tool_round_limit")


def validate_scope(root: Path, task: BridgeTask) -> tuple[str, ...]:
    paths = changed_paths(root)
    if not paths:
        raise BridgeError("no_changes_produced")
    for path in paths:
        if not path_allowed(path, task.allowed_paths):
            raise BridgeError("changed_path_out_of_scope")
    diff_check = _run(["git", "diff", "--check"], cwd=root, check=False)
    if diff_check.returncode != 0:
        raise BridgeError("git_diff_check_failed")
    return paths


def run_validations(root: Path, task: BridgeTask) -> tuple[bool, str]:
    summaries: list[str] = []
    timeout = int(os.environ.get("CSE_BRIDGE_COMMAND_TIMEOUT", "1200"))
    for command in task.validation_commands:
        argv = validate_command(command)
        result = _run(argv, cwd=root, timeout=timeout, check=False)
        summaries.append(f"{command}: exit {result.returncode}")
        if result.returncode != 0:
            detail = redact((result.stdout + "\n" + result.stderr)[-5000:])
            return False, "\n".join(summaries) + "\n" + detail
    return True, "\n".join(summaries)


def model_prompt(task: BridgeTask, *, correction: str | None = None) -> str:
    correction_text = (
        "\nThe previous pass failed deterministic validation. Fix only the reported failure:\n"
        + correction
        if correction
        else ""
    )
    return f"""You are the coding model for CSE Bridge.

Goal:
{task.goal}

Writable paths:
{chr(10).join('- ' + item for item in task.allowed_paths)}

Rules:
- Inspect repository files with read_file/search_files.
- Modify only writable paths with write_file or replace_text.
- Do not request shell, Git, GitHub, credentials, network or device access.
- Preserve existing style and compatibility.
- Call finish exactly once when the coding pass is complete.
{correction_text}
"""


def prepare_branch(root: Path, task: BridgeTask) -> None:
    if changed_paths(root):
        raise BridgeError("checkout_not_clean")
    _run(["git", "fetch", "origin", task.base, "--prune"], cwd=root)
    remote = _run(
        ["git", "ls-remote", "--exit-code", "--heads", "origin", task.branch],
        cwd=root,
        check=False,
    )
    if remote.returncode == 0:
        raise BridgeError("task_branch_already_exists")
    _run(["git", "switch", "-c", task.branch, f"origin/{task.base}"], cwd=root)


def publish(root: Path, task: BridgeTask, github: GitHubClient) -> Mapping[str, Any]:
    paths = validate_scope(root, task)
    _run(["git", "config", "user.name", "CSE API Bridge"], cwd=root)
    _run(["git", "config", "user.email", "cse-bridge@users.noreply.github.com"], cwd=root)
    _run(["git", "add", "-A"], cwd=root)
    staged = _run(["git", "diff", "--cached", "--name-only"], cwd=root).stdout.splitlines()
    if tuple(sorted(item.replace("\\", "/") for item in staged)) != paths:
        raise BridgeError("staged_scope_mismatch")
    _run(["git", "commit", "-m", task.commit_subject], cwd=root)
    _run(["git", "push", "origin", f"HEAD:refs/heads/{task.branch}"], cwd=root, timeout=300)
    return github.create_draft_pr(task)


def execute(issue_number: int, root: Path) -> int:
    repository = os.environ.get("GITHUB_REPOSITORY", "")
    token = os.environ.get("GITHUB_TOKEN", "")
    api_key = os.environ.get("OPENAI_API_KEY", "")
    model = os.environ.get("CSE_BRIDGE_MODEL", "")
    if not repository or not token:
        raise BridgeError("github_configuration_missing")
    github = GitHubClient(repository, token, os.environ.get("GITHUB_API_URL", "https://api.github.com"))
    issue = github.issue(issue_number)
    comments = github.comments(issue_number)
    if terminal_state(comments) is not None:
        return 0
    body = issue.get("body")
    if not isinstance(body, str):
        raise BridgeError("task_body_missing")
    task = parse_task(body)
    if task.repository != repository:
        raise BridgeError("task_repository_mismatch")
    expected_base = os.environ.get("CSE_BRIDGE_BASE", "master")
    if task.base != expected_base:
        raise BridgeError("task_base_forbidden")
    if not approved(comments):
        raise BridgeError("task_not_approved")
    if not api_key or not model:
        github.comment(
            issue_number,
            "<!-- cse-bridge-status:NEEDS_HUMAN -->\nCSE Bridge configuration is missing: repository secret `OPENAI_API_KEY` and/or repository variable `CSE_BRIDGE_MODEL`.",
        )
        return 2
    github.comment(
        issue_number,
        "<!-- cse-bridge-status:RUNNING -->\nCSE API Bridge started the approved task.",
    )
    prepare_branch(root, task)
    client = ResponsesClient(api_key, model)
    tools = LocalTools(root, task)
    summary = run_model(client, tools, model_prompt(task))
    try:
        validate_scope(root, task)
        passed, validation = run_validations(root, task)
    except BridgeError as exc:
        passed, validation = False, exc.reason
    if not passed:
        tools.finished_summary = None
        summary = run_model(
            client,
            tools,
            model_prompt(task, correction=redact(validation)),
        )
        validate_scope(root, task)
        passed, validation = run_validations(root, task)
    if not passed:
        github.comment(
            issue_number,
            "<!-- cse-bridge-status:NEEDS_HUMAN -->\nThe primary pass and one bounded correction did not pass validation.\n\n" + redact(validation),
        )
        return 3
    pr = publish(root, task, github)
    pr_url = str(pr.get("html_url", ""))
    github.comment(
        issue_number,
        "<!-- cse-bridge-status:PASS -->\n"
        f"CSE API Bridge completed the task and opened a Draft PR: {pr_url}\n\n"
        f"Summary: {redact(summary)}\n\nValidation:\n{redact(validation)}",
    )
    return 0


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("run",))
    parser.add_argument("--issue-number", type=int, required=True)
    parser.add_argument("--repo-root", type=Path, default=Path.cwd())
    args = parser.parse_args(argv)
    try:
        return execute(args.issue_number, args.repo_root.resolve())
    except BridgeError as exc:
        repository = os.environ.get("GITHUB_REPOSITORY", "")
        token = os.environ.get("GITHUB_TOKEN", "")
        if repository and token:
            try:
                GitHubClient(repository, token).comment(
                    args.issue_number,
                    f"<!-- cse-bridge-status:FAILED -->\nCSE API Bridge stopped: `{exc.reason}`.",
                )
            except BridgeError:
                pass
        print(exc.reason, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
