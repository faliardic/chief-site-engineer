"""Deterministic resumable O10 workflow coordinator and bounded host adapters."""

from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Mapping, Protocol

from .observer import GhGitHubClient
from .workflow_authorization import (
    WorkflowAuthorization,
    WorkflowStageAuthorization,
    canonical_json_bytes,
)
from .workflow_store import (
    HASH_PATTERN,
    WorkflowContract,
    WorkflowProjection,
    WorkflowStore,
    WorkflowStoreError,
)


REASON_PATTERN = re.compile(r"^[a-z][a-z0-9_]{2,95}$")
SHA_PATTERN = re.compile(r"^[0-9a-f]{40}$")
EVIDENCE_MARKER_PREFIX = "cse-orchestrator-workflow-evidence:v1"
CONTROLLER_SOURCE_ROOT = Path(__file__).resolve().parents[2]


class WorkflowError(RuntimeError):
    """The coordinator cannot continue without weakening workflow authority."""


def _hash_bytes(value: bytes) -> str:
    return "sha256:" + hashlib.sha256(value).hexdigest()


def _hash_mapping(value: Mapping[str, object]) -> str:
    return _hash_bytes(canonical_json_bytes(value))


def _normalized_reason(value: object, fallback: str) -> str:
    if isinstance(value, str) and REASON_PATTERN.fullmatch(value):
        return value
    return fallback


def _bounded(value: bytes, limit: int) -> tuple[bytes, bool]:
    return value[:limit], len(value) > limit


@dataclass(frozen=True)
class TargetObservation:
    repo_root: str
    branch: str
    head_sha: str
    tree_sha: str
    staged_paths: tuple[str, ...]
    changed_paths: tuple[str, ...]
    source_fingerprint: str

    def public_dict(self) -> dict[str, object]:
        return {
            "repo_root": self.repo_root,
            "branch": self.branch,
            "head_sha": self.head_sha,
            "tree_sha": self.tree_sha,
            "staged_paths": list(self.staged_paths),
            "changed_paths": list(self.changed_paths),
            "source_fingerprint": self.source_fingerprint,
        }


@dataclass(frozen=True)
class CommandDiagnostic:
    stage: str
    command_family: str
    argv_fingerprint: str
    command_index: int
    action_started: bool
    exit_code: int | None
    duration_ms: int
    truncated: bool
    timed_out: bool
    stdout_sha256: str
    stderr_sha256: str
    reason_code: str | None
    first_failed_predicate: str | None

    def public_dict(self) -> dict[str, object]:
        return {
            "stage": self.stage,
            "command_family": self.command_family,
            "argv_fingerprint": self.argv_fingerprint,
            "command_index": self.command_index,
            "action_started": self.action_started,
            "exit_code": self.exit_code,
            "duration_ms": self.duration_ms,
            "truncated": self.truncated,
            "timed_out": self.timed_out,
            "stdout_sha256": self.stdout_sha256,
            "stderr_sha256": self.stderr_sha256,
            "reason_code": self.reason_code,
            "first_failed_predicate": self.first_failed_predicate,
        }


@dataclass(frozen=True)
class StageExecution:
    success: bool
    classification: str
    reason_code: str | None
    first_failed_predicate: str | None
    diagnostics: tuple[CommandDiagnostic, ...]
    details: Mapping[str, object]
    reused: bool = False


class StageExecutor(Protocol):
    def execute(
        self,
        stage: WorkflowStageAuthorization,
        authorization: WorkflowAuthorization,
        *,
        controller_root: Path,
        target_root: Path,
    ) -> StageExecution: ...


class EvidenceSink(Protocol):
    def emit(
        self,
        *,
        workflow_id: str,
        evidence_key: str,
        payload: Mapping[str, object],
    ) -> Mapping[str, object]: ...


class NullEvidenceSink:
    def emit(self, *, workflow_id, evidence_key, payload):
        return {"reused": False, "comment_id": None}


def _run_process(
    argv: tuple[str, ...],
    *,
    cwd: Path,
    environment: Mapping[str, str],
    timeout_seconds: int,
    output_limit_bytes: int,
) -> dict[str, object]:
    started = time.monotonic()
    try:
        completed = subprocess.run(
            list(argv),
            cwd=cwd,
            env=dict(environment),
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            shell=False,
            timeout=timeout_seconds,
            check=False,
        )
    except subprocess.TimeoutExpired as exc:
        stdout, stdout_truncated = _bounded(exc.stdout or b"", output_limit_bytes)
        stderr, stderr_truncated = _bounded(exc.stderr or b"", output_limit_bytes)
        return {
            "action_started": True,
            "exit_code": None,
            "duration_ms": int((time.monotonic() - started) * 1000),
            "stdout": stdout,
            "stderr": stderr,
            "truncated": stdout_truncated or stderr_truncated,
            "timed_out": True,
            "reason_code": "command_timeout",
            "first_failed_predicate": "command_completed_before_timeout",
        }
    except (OSError, ValueError):
        return {
            "action_started": False,
            "exit_code": None,
            "duration_ms": int((time.monotonic() - started) * 1000),
            "stdout": b"",
            "stderr": b"",
            "truncated": False,
            "timed_out": False,
            "reason_code": "executable_unavailable",
            "first_failed_predicate": "subprocess_started",
        }
    stdout, stdout_truncated = _bounded(completed.stdout, output_limit_bytes)
    stderr, stderr_truncated = _bounded(completed.stderr, output_limit_bytes)
    return {
        "action_started": True,
        "exit_code": completed.returncode,
        "duration_ms": int((time.monotonic() - started) * 1000),
        "stdout": stdout,
        "stderr": stderr,
        "truncated": stdout_truncated or stderr_truncated,
        "timed_out": False,
        "reason_code": None if completed.returncode == 0 else "command_exit_nonzero",
        "first_failed_predicate": (
            None if completed.returncode == 0 else "exit_code_equals_zero"
        ),
    }


def _diagnostic(
    stage: WorkflowStageAuthorization,
    argv: tuple[str, ...],
    index: int,
    raw: Mapping[str, object],
) -> CommandDiagnostic:
    stdout = raw.get("stdout", b"")
    stderr = raw.get("stderr", b"")
    if isinstance(stdout, str):
        stdout = stdout.encode("utf-8", errors="replace")
    if isinstance(stderr, str):
        stderr = stderr.encode("utf-8", errors="replace")
    if not isinstance(stdout, bytes) or not isinstance(stderr, bytes):
        raise WorkflowError("command_output_type_invalid")
    exit_code = raw.get("exit_code")
    if exit_code is not None and (isinstance(exit_code, bool) or not isinstance(exit_code, int)):
        raise WorkflowError("command_exit_code_invalid")
    reason = raw.get("reason_code")
    predicate = raw.get("first_failed_predicate")
    return CommandDiagnostic(
        stage=stage.name,
        command_family=stage.command_family,
        argv_fingerprint=_hash_mapping({"argv": list(argv)}),
        command_index=index,
        action_started=raw.get("action_started") is True,
        exit_code=exit_code,
        duration_ms=max(0, int(raw.get("duration_ms", 0))),
        truncated=raw.get("truncated") is True,
        timed_out=raw.get("timed_out") is True,
        stdout_sha256=_hash_bytes(stdout),
        stderr_sha256=_hash_bytes(stderr),
        reason_code=(
            _normalized_reason(reason, "command_failed") if reason is not None else None
        ),
        first_failed_predicate=(
            _normalized_reason(predicate, "command_result_valid")
            if predicate is not None
            else None
        ),
    )


def _status_paths(value: str) -> tuple[str, ...]:
    paths: list[str] = []
    for line in value.splitlines():
        if not line:
            continue
        if len(line) < 4 or " -> " in line:
            raise WorkflowError("worktree_status_invalid")
        paths.append(line[3:].replace("\\", "/"))
    return tuple(sorted(paths))


def _git_text(root: Path, argv: tuple[str, ...], *, timeout: int = 30) -> str:
    raw = _run_process(
        argv,
        cwd=root,
        environment=os.environ,
        timeout_seconds=timeout,
        output_limit_bytes=1024 * 1024,
    )
    if raw["exit_code"] != 0 or raw["truncated"] or raw["timed_out"]:
        raise WorkflowError("git_observation_failed")
    stdout = raw["stdout"]
    assert isinstance(stdout, bytes)
    try:
        return stdout.decode("utf-8").rstrip("\r\n")
    except UnicodeDecodeError as exc:
        raise WorkflowError("git_observation_encoding_invalid") from exc


def observe_target(repo_root: Path) -> TargetObservation:
    root = Path(repo_root).resolve()
    if not root.is_dir():
        raise WorkflowError("target_root_missing")
    actual = Path(_git_text(root, ("git", "rev-parse", "--show-toplevel"))).resolve()
    if actual != root:
        raise WorkflowError("target_root_mismatch")
    branch = _git_text(root, ("git", "branch", "--show-current"))
    head = _git_text(root, ("git", "rev-parse", "HEAD"))
    tree = _git_text(root, ("git", "rev-parse", "HEAD^{tree}"))
    if not SHA_PATTERN.fullmatch(head) or not SHA_PATTERN.fullmatch(tree):
        raise WorkflowError("target_git_identity_invalid")
    staged_text = _git_text(root, ("git", "diff", "--cached", "--name-only"))
    staged = tuple(
        sorted(
            line.replace("\\", "/")
            for line in staged_text.splitlines()
            if line.strip()
        )
    )
    changed = _status_paths(
        _git_text(root, ("git", "status", "--porcelain=v1", "--untracked-files=all"))
    )
    identity = {
        "branch": branch,
        "head_sha": head,
        "tree_sha": tree,
        "staged_paths": list(staged),
        "changed_paths": list(changed),
    }
    return TargetObservation(
        repo_root=str(root),
        branch=branch,
        head_sha=head,
        tree_sha=tree,
        staged_paths=staged,
        changed_paths=changed,
        source_fingerprint=_hash_mapping(identity),
    )


def controller_revision(controller_root: Path) -> tuple[str, str]:
    root = Path(controller_root).resolve()
    return (
        _git_text(root, ("git", "rev-parse", "HEAD")),
        _git_text(root, ("git", "rev-parse", "HEAD^{tree}")),
    )


def prepare_target_branch(
    authorization: WorkflowAuthorization,
    target_root: Path,
    *,
    execute: bool,
) -> TargetObservation:
    observation = observe_target(target_root)
    target = authorization.target
    expected_branch = str(target["branch"])
    if observation.branch == expected_branch:
        return observation
    if observation.staged_paths or observation.changed_paths:
        raise WorkflowError("target_branch_switch_dirty")
    if observation.head_sha != target["base_sha"]:
        raise WorkflowError("target_branch_switch_base_drift")
    if not execute:
        return observation
    existing = _run_process(
        ("git", "show-ref", "--verify", f"refs/heads/{expected_branch}"),
        cwd=Path(target_root).resolve(),
        environment=os.environ,
        timeout_seconds=30,
        output_limit_bytes=65536,
    )
    command = (
        ("git", "switch", expected_branch)
        if existing["exit_code"] == 0
        else ("git", "switch", "-c", expected_branch)
    )
    result = _run_process(
        command,
        cwd=Path(target_root).resolve(),
        environment=os.environ,
        timeout_seconds=30,
        output_limit_bytes=65536,
    )
    if result["exit_code"] != 0:
        raise WorkflowError("target_branch_prepare_failed")
    return observe_target(target_root)


class DefaultStageExecutor:
    """Shell-free command, artifact, commit, push and Draft-PR executor."""

    def _command(
        self,
        stage: WorkflowStageAuthorization,
        argv: tuple[str, ...],
        cwd: Path,
        index: int,
        environment: Mapping[str, str] | None = None,
    ) -> tuple[CommandDiagnostic, bytes]:
        raw = _run_process(
            argv,
            cwd=cwd,
            environment=environment or os.environ,
            timeout_seconds=stage.timeout_seconds,
            output_limit_bytes=stage.output_limit_bytes,
        )
        diagnostic = _diagnostic(stage, argv, index, raw)
        stdout = raw.get("stdout", b"")
        if isinstance(stdout, str):
            stdout = stdout.encode("utf-8", errors="replace")
        assert isinstance(stdout, bytes)
        return diagnostic, stdout

    @staticmethod
    def _failure(
        stage: WorkflowStageAuthorization,
        diagnostics: list[CommandDiagnostic],
    ) -> StageExecution:
        failed = diagnostics[-1]
        return StageExecution(
            False,
            stage.failure_class,
            failed.reason_code or "command_failed",
            failed.first_failed_predicate or "command_succeeded",
            tuple(diagnostics),
            {},
        )

    def _artifact(self, stage, authorization, target_root):
        raw = authorization.payload["artifact"]
        if not isinstance(raw, Mapping):
            return StageExecution(
                False, "unsafe", "artifact_contract_missing", "artifact_contract_present", (), {}
            )
        candidate = Path(str(raw["path"]))
        if not candidate.is_absolute():
            candidate = target_root / candidate
        started = time.monotonic()
        if not candidate.is_file():
            return StageExecution(
                False, "external", "artifact_missing", "artifact_path_exists", (), {}
            )
        digest = _hash_bytes(candidate.read_bytes())
        diagnostic = CommandDiagnostic(
            stage.name,
            stage.command_family,
            _hash_mapping({"artifact_path": str(candidate)}),
            1,
            True,
            0 if digest == raw["sha256"] else 1,
            int((time.monotonic() - started) * 1000),
            False,
            False,
            digest,
            _hash_bytes(b""),
            None if digest == raw["sha256"] else "artifact_hash_mismatch",
            None if digest == raw["sha256"] else "artifact_sha256_matches",
        )
        if digest != raw["sha256"]:
            return StageExecution(
                False,
                "unsafe",
                "artifact_hash_mismatch",
                "artifact_sha256_matches",
                (diagnostic,),
                {},
            )
        details = {
            "artifact": {
                **dict(raw),
                "path": str(candidate.resolve()),
                "size": candidate.stat().st_size,
            }
        }
        return StageExecution(True, "unsafe", None, None, (diagnostic,), details)

    def _commit(self, stage, authorization, target_root):
        publish = authorization.payload["publish"]
        if not isinstance(publish, Mapping):
            return StageExecution(False, "unsafe", "publish_contract_missing", "publish_contract_present", (), {})
        diagnostics: list[CommandDiagnostic] = []
        expected_initial = str(authorization.target["head_sha"])
        head_d, head_raw = self._command(stage, ("git", "rev-parse", "HEAD"), target_root, 1)
        diagnostics.append(head_d)
        if head_d.exit_code != 0:
            return self._failure(stage, diagnostics)
        head = head_raw.decode("utf-8", errors="replace").strip()
        if head != expected_initial:
            subject_d, subject_raw = self._command(
                stage, ("git", "log", "-1", "--format=%s"), target_root, 2
            )
            diagnostics.append(subject_d)
            parent_d, parent_raw = self._command(
                stage, ("git", "rev-parse", "HEAD^"), target_root, 3
            )
            diagnostics.append(parent_d)
            if any(item.exit_code != 0 for item in diagnostics[-2:]):
                return self._failure(stage, diagnostics)
            if (
                subject_raw.decode("utf-8", errors="replace").strip()
                == publish["commit_message"]
                and parent_raw.decode("utf-8", errors="replace").strip()
                == expected_initial
            ):
                return StageExecution(
                    True, "unsafe", None, None, tuple(diagnostics), {"publish": {"commit_sha": head}}, True
                )
            return StageExecution(False, "unsafe", "commit_provenance_drift", "authorized_commit_matches", tuple(diagnostics), {})

        observation = observe_target(target_root)
        paths = observation.changed_paths
        if not paths or set(paths) - set(authorization.write_allowlist):
            return StageExecution(False, "unsafe", "commit_scope_drift", "changed_paths_within_allowlist", tuple(diagnostics), {})
        if observation.staged_paths:
            return StageExecution(False, "unsafe", "commit_index_not_empty", "staging_initially_empty", tuple(diagnostics), {})
        commands = (
            ("git", "add", "--", *paths),
            ("git", "diff", "--cached", "--check"),
            ("git", "commit", "-m", str(publish["commit_message"])),
        )
        for offset, argv in enumerate(commands, start=2):
            diagnostic, _ = self._command(stage, argv, target_root, offset)
            diagnostics.append(diagnostic)
            if diagnostic.exit_code != 0:
                return self._failure(stage, diagnostics)
        final = observe_target(target_root)
        if final.changed_paths or final.staged_paths or final.head_sha == expected_initial:
            return StageExecution(False, "unsafe", "commit_postcondition_failed", "commit_tree_clean", tuple(diagnostics), {})
        return StageExecution(
            True,
            "unsafe",
            None,
            None,
            tuple(diagnostics),
            {"publish": {"commit_sha": final.head_sha}},
        )

    def _push(self, stage, authorization, target_root):
        diagnostics: list[CommandDiagnostic] = []
        branch = str(authorization.target["branch"])
        local = observe_target(target_root).head_sha
        read_argv = ("git", "ls-remote", "--heads", "origin", f"refs/heads/{branch}")
        diagnostic, raw = self._command(stage, read_argv, target_root, 1)
        diagnostics.append(diagnostic)
        if diagnostic.exit_code != 0:
            return self._failure(stage, diagnostics)
        remote_line = raw.decode("utf-8", errors="replace").strip()
        remote = remote_line.split()[0] if remote_line else None
        if remote == local:
            return StageExecution(True, "unsafe", None, None, tuple(diagnostics), {"publish": {"commit_sha": local, "push_reused": True}}, True)
        if remote is not None:
            return StageExecution(False, "unsafe", "remote_branch_drift", "remote_branch_absent_or_exact", tuple(diagnostics), {})
        push_d, _ = self._command(
            stage, ("git", "push", "-u", "origin", branch), target_root, 2
        )
        diagnostics.append(push_d)
        if push_d.exit_code != 0:
            return self._failure(stage, diagnostics)
        verify_d, verify_raw = self._command(stage, read_argv, target_root, 3)
        diagnostics.append(verify_d)
        verified = verify_raw.decode("utf-8", errors="replace").strip().split()
        if verify_d.exit_code != 0 or not verified or verified[0] != local:
            return StageExecution(False, "unsafe", "push_provenance_failed", "remote_head_matches_local", tuple(diagnostics), {})
        return StageExecution(True, "unsafe", None, None, tuple(diagnostics), {"publish": {"commit_sha": local, "push_reused": False}})

    def _draft_pr(self, stage, authorization, target_root):
        publish = authorization.payload["publish"]
        if not isinstance(publish, Mapping):
            return StageExecution(False, "unsafe", "publish_contract_missing", "publish_contract_present", (), {})
        branch = str(authorization.target["branch"])
        repository = authorization.repository
        diagnostics: list[CommandDiagnostic] = []
        list_argv = (
            "gh", "pr", "list", "--repo", repository, "--head", branch,
            "--base", str(publish["base_branch"]), "--state", "open",
            "--json", "number,isDraft,state,url,title",
        )
        list_d, raw = self._command(stage, list_argv, target_root, 1)
        diagnostics.append(list_d)
        if list_d.exit_code != 0:
            return self._failure(stage, diagnostics)
        try:
            existing = json.loads(raw.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError):
            return StageExecution(False, "unsafe", "pr_list_json_invalid", "pr_list_is_json", tuple(diagnostics), {})
        if not isinstance(existing, list):
            return StageExecution(False, "unsafe", "pr_list_shape_invalid", "pr_list_is_array", tuple(diagnostics), {})
        if existing:
            if len(existing) != 1:
                return StageExecution(False, "unsafe", "duplicate_open_pr", "single_open_pr", tuple(diagnostics), {})
            item = existing[0]
            if not isinstance(item, dict) or item.get("isDraft") is not True or item.get("title") != publish["title"]:
                return StageExecution(False, "unsafe", "existing_pr_drift", "existing_pr_matches_contract", tuple(diagnostics), {})
            return StageExecution(True, "unsafe", None, None, tuple(diagnostics), {"publish": {"pr": item, "pr_reused": True}}, True)
        body = (
            f"{publish['body_first_line']}\n\n"
            "Implements the authorized resumable workflow contract.\n\n"
            "Validation evidence is recorded on the linked Issue."
        )
        create_argv = (
            "gh", "pr", "create", "--repo", repository, "--draft",
            "--base", str(publish["base_branch"]), "--head", branch,
            "--title", str(publish["title"]), "--body", body,
        )
        create_d, _ = self._command(stage, create_argv, target_root, 2)
        diagnostics.append(create_d)
        if create_d.exit_code != 0:
            return self._failure(stage, diagnostics)
        verify_d, verify_raw = self._command(stage, list_argv, target_root, 3)
        diagnostics.append(verify_d)
        try:
            created = json.loads(verify_raw.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError):
            return StageExecution(False, "unsafe", "pr_verify_json_invalid", "created_pr_is_queryable", tuple(diagnostics), {})
        if verify_d.exit_code != 0 or not isinstance(created, list) or len(created) != 1 or created[0].get("isDraft") is not True:
            return StageExecution(False, "unsafe", "pr_verify_failed", "created_pr_matches_contract", tuple(diagnostics), {})
        return StageExecution(True, "unsafe", None, None, tuple(diagnostics), {"publish": {"pr": created[0], "pr_reused": False}})

    def execute(self, stage, authorization, *, controller_root, target_root):
        if stage.kind == "artifact_verify":
            return self._artifact(stage, authorization, target_root)
        if stage.kind == "commit":
            return self._commit(stage, authorization, target_root)
        if stage.kind == "push":
            return self._push(stage, authorization, target_root)
        if stage.kind == "draft_pr":
            return self._draft_pr(stage, authorization, target_root)
        if stage.kind == "issue_comment":
            return StageExecution(True, "unsafe", None, None, (), {})
        cwd = controller_root if stage.cwd == "controller" else target_root
        environment = {
            key: os.environ[key]
            for key in stage.environment_allowlist
            if key in os.environ
        }
        diagnostic, _ = self._command(stage, stage.argv, cwd, 1, environment)
        if diagnostic.exit_code == 0 and not diagnostic.timed_out and not diagnostic.truncated:
            return StageExecution(True, "unsafe", None, None, (diagnostic,), {})
        return self._failure(stage, [diagnostic])


class GhIssueEvidenceSink:
    """Duplicate-safe, data-minimal Issue evidence through the authenticated gh session."""

    def __init__(self, repository: str, issue: int) -> None:
        self.repository = repository
        self.issue = issue
        self._client = GhGitHubClient(repository)

    def emit(self, *, workflow_id, evidence_key, payload):
        if not REASON_PATTERN.fullmatch(evidence_key):
            raise WorkflowError("evidence_key_invalid")
        marker = f"<!-- {EVIDENCE_MARKER_PREFIX}:{workflow_id}:{evidence_key} -->"
        comments = self._client.get_issue_comments(self.issue)
        matches = [item for item in comments if marker in str(item.get("body", ""))]
        if len(matches) > 1:
            raise WorkflowError("duplicate_evidence_comment")
        if matches:
            return {"reused": True, "comment_id": matches[0].get("id")}
        safe = {
            key: value
            for key, value in payload.items()
            if key in {"status", "stage", "reason_code", "fingerprint", "count"}
        }
        body = (
            f"{marker}\n"
            "## CSE resumable workflow evidence\n\n"
            f"- Workflow: `{workflow_id}`\n"
            f"- Event: `{evidence_key}`\n"
            f"- Evidence: `{json.dumps(safe, sort_keys=True, separators=(',', ':'))}`"
        )
        result = _run_process(
            (
                "gh", "api", "--method", "POST",
                f"repos/{self.repository}/issues/{self.issue}/comments",
                "-f", f"body={body}",
            ),
            cwd=Path.cwd(),
            environment=os.environ,
            timeout_seconds=30,
            output_limit_bytes=262144,
        )
        if result["exit_code"] != 0 or result["truncated"]:
            raise WorkflowError("github_evidence_post_failed")
        try:
            value = json.loads(bytes(result["stdout"]).decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError, TypeError) as exc:
            raise WorkflowError("github_evidence_response_invalid") from exc
        if not isinstance(value, dict) or not isinstance(value.get("id"), int):
            raise WorkflowError("github_evidence_response_invalid")
        return {"reused": False, "comment_id": value["id"]}


def _tool_fingerprint(stage: WorkflowStageAuthorization) -> str:
    executable = (
        stage.argv[0]
        if stage.kind == "command"
        else "git" if stage.kind in {"commit", "push"}
        else "gh" if stage.kind in {"draft_pr", "issue_comment"}
        else sys.executable
    )
    resolved = Path(sys.executable) if executable in {"python", "python3", "py"} else None
    if resolved is None:
        found = shutil.which(executable)
        if found is None:
            raise WorkflowError(f"required_executable_missing:{stage.command_family}")
        resolved = Path(found)
    try:
        digest = _hash_bytes(resolved.read_bytes())
    except OSError as exc:
        raise WorkflowError("required_executable_unreadable") from exc
    return _hash_mapping(
        {"executable": resolved.name.lower(), "path": str(resolved.resolve()), "sha256": digest}
    )


def _command_fingerprint(stage: WorkflowStageAuthorization) -> str:
    return _hash_mapping(
        {
            "kind": stage.kind,
            "command_family": stage.command_family,
            "argv": list(stage.argv),
            "cwd": stage.cwd,
            "timeout_seconds": stage.timeout_seconds,
            "output_limit_bytes": stage.output_limit_bytes,
        }
    )


def _artifact_fingerprint(authorization: WorkflowAuthorization, target_root: Path) -> str | None:
    artifact = authorization.payload["artifact"]
    if not isinstance(artifact, Mapping):
        return None
    path = Path(str(artifact["path"]))
    if not path.is_absolute():
        path = target_root / path
    if not path.is_file():
        return None
    return _hash_bytes(path.read_bytes())


def _budget_counter(stage: WorkflowStageAuthorization) -> str:
    return {
        "commit": "commit",
        "push": "push",
        "draft_pr": "draft_pr",
        "issue_comment": "github_comment",
    }.get(stage.kind, "command")


class WorkflowCoordinator:
    """Run or resume authorized stages until completion or a real stop class."""

    def __init__(
        self,
        *,
        authorization: WorkflowAuthorization,
        controller_root: Path,
        target_root: Path,
        runtime_root: Path,
        executor: StageExecutor | None = None,
        evidence_sink: EvidenceSink | None = None,
    ) -> None:
        self.authorization = authorization
        self.controller_root = Path(controller_root).resolve()
        self.target_root = Path(target_root).resolve()
        self.runtime_root = Path(runtime_root).resolve()
        self.contract = WorkflowContract.from_authorization(authorization)
        self.store = WorkflowStore(
            runtime_root=self.runtime_root,
            repo_root=self.target_root,
            workflow_id=self.contract.workflow_id,
        )
        self.executor = executor or DefaultStageExecutor()
        self.evidence_sink = evidence_sink or NullEvidenceSink()

    def _validate_controller(self) -> None:
        if self.controller_root == self.target_root:
            raise WorkflowError("controller_target_not_separated")
        if self.controller_root != CONTROLLER_SOURCE_ROOT.resolve():
            raise WorkflowError("controller_source_root_mismatch")
        revision, _ = controller_revision(self.controller_root)
        if revision != self.authorization.payload["controller_revision"]:
            raise WorkflowError("controller_revision_drift")
        controller = observe_target(self.controller_root)
        if controller.changed_paths or controller.staged_paths:
            raise WorkflowError("controller_worktree_dirty")
        try:
            self.runtime_root.relative_to(self.controller_root)
            raise WorkflowError("runtime_root_inside_controller")
        except ValueError:
            pass

    def _preflight_tools(self) -> None:
        for stage in self.authorization.stages:
            _tool_fingerprint(stage)

    def plan(self) -> dict[str, object]:
        self._validate_controller()
        observation = prepare_target_branch(
            self.authorization, self.target_root, execute=False
        )
        target = self.authorization.target
        needs_branch = observation.branch != target["branch"]
        if not needs_branch and (
            observation.head_sha != target["head_sha"]
            or observation.tree_sha != target["tree_sha"]
        ):
            raise WorkflowError("target_checkpoint_drift")
        return {
            "schema_version": 1,
            "workflow_id": self.contract.workflow_id,
            "status": "DRY_RUN",
            "next_action": "prepare_target_branch" if needs_branch else self.contract.stages[0].name,
            "authorization_fingerprint": self.authorization.fingerprint,
            "contract_fingerprint": self.contract.contract_fingerprint,
            "target_source_fingerprint": observation.source_fingerprint,
        }

    def _emit(
        self,
        evidence_key: str,
        payload: Mapping[str, object],
    ) -> None:
        verification = self.store.verify()
        recorded = {
            str(event["payload"].get("evidence_key"))
            for event in verification.events
            if event["event_type"] == "github_evidence"
        }
        if evidence_key in recorded:
            return
        if verification.projection.consumed_budgets.get(
            "github_comment", 0
        ) >= int(self.authorization.budgets["github_comment_max"]):
            raise WorkflowError("github_comment_budget_exhausted")
        result = self.evidence_sink.emit(
            workflow_id=self.contract.workflow_id,
            evidence_key=evidence_key,
            payload=payload,
        )
        self.store.append(
            "github_evidence",
            {
                "evidence_key": evidence_key,
                "result_fingerprint": _hash_mapping(dict(result)),
            },
        )

    def _stage_evidence(
        self,
        stage: WorkflowStageAuthorization,
        observation: TargetObservation,
        execution: StageExecution,
        tool_fingerprint: str,
        command_fingerprint: str,
        artifact_fingerprint: str | None,
    ) -> dict[str, object]:
        diagnostics = [item.public_dict() for item in execution.diagnostics]
        identity = {
            "stage": stage.name,
            "source_fingerprint": observation.source_fingerprint,
            "tool_fingerprint": tool_fingerprint,
            "command_fingerprint": command_fingerprint,
            "artifact_fingerprint": artifact_fingerprint,
            "diagnostics_fingerprint": _hash_mapping({"diagnostics": diagnostics}),
        }
        return {**identity, "evidence_fingerprint": _hash_mapping(identity)}

    def _reconcile_evidence(self, projection: WorkflowProjection) -> None:
        for evidence in projection.passed_evidence:
            stage = str(evidence.get("stage", ""))
            if not stage:
                raise WorkflowError("passed_evidence_stage_missing")
            self._emit(
                f"gate_pass_{stage}",
                {
                    "status": "PASS",
                    "stage": stage,
                    "fingerprint": str(evidence.get("evidence_fingerprint", "")),
                    "count": projection.event_count,
                },
            )
        if projection.status == "COMPLETED":
            self._emit(
                "workflow_completed",
                {
                    "status": projection.status,
                    "fingerprint": projection.tail_hash,
                    "count": projection.event_count,
                },
            )

    def _matching_reused_evidence(
        self,
        stage: WorkflowStageAuthorization,
        observation: TargetObservation,
        tool_fingerprint: str,
        command_fingerprint: str,
        artifact_fingerprint: str | None,
    ) -> Mapping[str, object] | None:
        values = [
            item
            for item in self.authorization.reused_evidence
            if item["stage"] == stage.name
        ]
        if not values:
            return None
        evidence = values[0]
        expected = {
            "source_fingerprint": observation.source_fingerprint,
            "tool_fingerprint": tool_fingerprint,
            "command_fingerprint": command_fingerprint,
            "artifact_fingerprint": artifact_fingerprint,
        }
        if not stage.reusable or any(evidence[key] != value for key, value in expected.items()):
            raise WorkflowError("reused_evidence_provenance_mismatch")
        return evidence

    def _validate_target_scope(self, observation: TargetObservation) -> None:
        outside = set(observation.changed_paths) - set(self.authorization.write_allowlist)
        if outside:
            raise WorkflowError("target_allowlist_drift")

    def run(self, *, execute: bool) -> dict[str, object]:
        if not execute:
            return self.plan()
        if not self.authorization.execution_authorized:
            raise WorkflowError("workflow_execution_not_authorized")
        self._validate_controller()
        self._preflight_tools()
        observation = prepare_target_branch(
            self.authorization, self.target_root, execute=True
        )
        target = self.authorization.target
        if not self.store.manifest_path.exists():
            if (
                observation.branch != target["branch"]
                or observation.head_sha != target["head_sha"]
                or observation.tree_sha != target["tree_sha"]
            ):
                raise WorkflowError("target_checkpoint_drift")
            if observation.staged_paths or observation.changed_paths:
                raise WorkflowError("target_initial_state_dirty")
        projection = self.store.start(self.contract)
        if observation.branch != target["branch"]:
            raise WorkflowError("target_branch_drift")
        if projection.last_target_fingerprint is None:
            if (
                observation.head_sha != target["head_sha"]
                or observation.tree_sha != target["tree_sha"]
            ):
                raise WorkflowError("target_checkpoint_drift")
            if observation.staged_paths or observation.changed_paths:
                raise WorkflowError("target_initial_state_dirty")
        if projection.artifact is not None:
            verify_projected_artifact(projection, target_root=self.target_root)
        self._emit(
            "workflow_started",
            {
                "status": projection.status,
                "fingerprint": self.contract.contract_fingerprint,
                "count": projection.event_count,
            },
        )
        projection = self.store.verify().projection
        self._reconcile_evidence(projection)
        projection = self.store.verify().projection
        if projection.status == "COMPLETED":
            return projection.public_dict(self.contract)
        if projection.status in {"AWAITING_USER_DECISION", "UNSAFE_BLOCKED"}:
            return projection.public_dict(self.contract)

        live = observe_target(self.target_root)
        self._validate_target_scope(live)
        if projection.last_target_fingerprint is None:
            self.store.append(
                "target_observed", {"source_fingerprint": live.source_fingerprint}
            )
        elif projection.last_target_fingerprint != live.source_fingerprint:
            if projection.status in {"PAUSED_EXTERNAL", "RESUMABLE_FAILURE"}:
                self.store.append(
                    "workflow_resumed", {"stage_index": projection.current_stage_index}
                )
                projection = self.store.verify().projection
            stage = self.contract.stages[projection.current_stage_index]
            self.store.append(
                "stage_failed",
                {
                    "stage": stage.name,
                    "classification": "unsafe",
                    "reason_code": "target_source_drift",
                    "command_index": 0,
                    "first_failed_predicate": "target_source_fingerprint_matches",
                },
            )
            projection = self.store.verify().projection
            self._emit(
                "workflow_blocked",
                {
                    "status": projection.status,
                    "stage": stage.name,
                    "reason_code": "target_source_drift",
                    "fingerprint": live.source_fingerprint,
                    "count": projection.event_count,
                },
            )
            return projection.public_dict(self.contract)
        elif projection.status in {"PAUSED_EXTERNAL", "RESUMABLE_FAILURE"}:
            self.store.append(
                "workflow_resumed", {"stage_index": projection.current_stage_index}
            )
            projection = self.store.verify().projection
            self._emit(
                "workflow_resumed",
                {
                    "status": projection.status,
                    "stage": self.contract.stages[projection.current_stage_index].name,
                    "fingerprint": live.source_fingerprint,
                    "count": projection.event_count,
                },
            )

        started = time.monotonic()
        while True:
            projection = self.store.verify().projection
            if projection.current_stage_index >= len(self.authorization.stages):
                if projection.status != "RUNNING":
                    return projection.public_dict(self.contract)
                final_target = observe_target(self.target_root)
                self._validate_target_scope(final_target)
                if final_target.changed_paths or final_target.staged_paths:
                    self.store.append(
                        "workflow_failed",
                        {
                            "phase": "completion",
                            "reason_code": "completion_target_not_clean",
                            "command_index": 0,
                            "first_failed_predicate": (
                                "target_worktree_and_staging_clean"
                            ),
                        },
                    )
                    return self.store.verify().projection.public_dict(self.contract)
                if isinstance(self.authorization.payload["publish"], Mapping):
                    publish = projection.publish or {}
                    pr = publish.get("pr")
                    if (
                        not publish.get("commit_sha")
                        or "push_reused" not in publish
                        or not isinstance(pr, Mapping)
                        or pr.get("isDraft") is not True
                    ):
                        self.store.append(
                            "workflow_failed",
                            {
                                "phase": "completion",
                                "reason_code": (
                                    "completion_publish_provenance_missing"
                                ),
                                "command_index": 0,
                                "first_failed_predicate": (
                                    "publish_provenance_complete"
                                ),
                            },
                        )
                        return self.store.verify().projection.public_dict(
                            self.contract
                        )
                self.store.append("workflow_completed", {})
                projection = self.store.verify().projection
                self._emit(
                    "workflow_completed",
                    {
                        "status": projection.status,
                        "fingerprint": projection.tail_hash,
                        "count": projection.event_count,
                    },
                )
                return self.store.verify().projection.public_dict(self.contract)
            if projection.status != "RUNNING":
                return projection.public_dict(self.contract)
            if time.monotonic() - started >= int(self.authorization.budgets["hard_stop_seconds"]):
                stage = self.authorization.stages[projection.current_stage_index]
                self.store.append(
                    "stage_failed",
                    {
                        "stage": stage.name,
                        "classification": "unsafe",
                        "reason_code": "workflow_hard_stop",
                        "command_index": 0,
                        "first_failed_predicate": "elapsed_before_hard_stop",
                    },
                )
                return self.store.verify().projection.public_dict(self.contract)

            stage = self.authorization.stages[projection.current_stage_index]
            live = observe_target(self.target_root)
            self._validate_target_scope(live)
            if projection.last_target_fingerprint != live.source_fingerprint:
                raise WorkflowError("target_source_drift")
            tool = _tool_fingerprint(stage)
            command = _command_fingerprint(stage)
            artifact = _artifact_fingerprint(self.authorization, self.target_root)
            try:
                reused = self._matching_reused_evidence(
                    stage, live, tool, command, artifact
                )
            except WorkflowError:
                self.store.append(
                    "stage_failed",
                    {
                        "stage": stage.name,
                        "classification": "unsafe",
                        "reason_code": "reused_evidence_provenance_mismatch",
                        "command_index": 0,
                        "first_failed_predicate": "reused_evidence_matches_current_fingerprint",
                    },
                )
                return self.store.verify().projection.public_dict(self.contract)
            if reused is not None:
                details: dict[str, object] = {
                    "target_after_fingerprint": live.source_fingerprint
                }
                if stage.kind == "artifact_verify" and isinstance(
                    self.authorization.payload["artifact"], Mapping
                ):
                    details["artifact"] = dict(self.authorization.payload["artifact"])
                self.store.append(
                    "stage_reused",
                    {
                        "stage_index": projection.current_stage_index,
                        "stage": stage.name,
                        "evidence": dict(reused),
                        "details": details,
                    },
                )
                current = self.store.verify().projection
                self._emit(
                    f"gate_pass_{stage.name}",
                    {
                        "status": "reused",
                        "stage": stage.name,
                        "fingerprint": str(reused["evidence_fingerprint"]),
                        "count": current.event_count,
                    },
                )
                continue

            counter = _budget_counter(stage)
            maximum = int(self.authorization.budgets[f"{counter}_max"])
            used = projection.consumed_budgets.get(counter, 0)
            if used >= maximum:
                self.store.append(
                    "stage_failed",
                    {
                        "stage": stage.name,
                        "classification": "unsafe",
                        "reason_code": "workflow_budget_exhausted",
                        "command_index": 0,
                        "first_failed_predicate": f"{counter}_budget_available",
                    },
                )
                return self.store.verify().projection.public_dict(self.contract)
            attempt = projection.stage_attempts.get(stage.name, 0) + 1
            attempt_id = _hash_mapping(
                {
                    "workflow_id": self.contract.workflow_id,
                    "stage": stage.name,
                    "attempt": attempt,
                    "source_fingerprint": live.source_fingerprint,
                    "stage_fingerprint": self.contract.stages[
                        projection.current_stage_index
                    ].stage_fingerprint,
                }
            )
            self.store.append(
                "stage_admitted",
                {
                    "stage_index": projection.current_stage_index,
                    "stage": stage.name,
                    "attempt": attempt,
                    "attempt_id": attempt_id,
                    "stage_fingerprint": self.contract.stages[
                        projection.current_stage_index
                    ].stage_fingerprint,
                    "budget_counter": counter,
                },
            )
            execution = self.executor.execute(
                stage,
                self.authorization,
                controller_root=self.controller_root,
                target_root=self.target_root,
            )
            if execution.success:
                after = observe_target(self.target_root)
                self._validate_target_scope(after)
                evidence = self._stage_evidence(
                    stage, live, execution, tool, command, artifact
                )
                details = {
                    **dict(execution.details),
                    "target_after_fingerprint": after.source_fingerprint,
                }
                self.store.append(
                    "stage_passed",
                    {
                        "stage_index": projection.current_stage_index,
                        "stage": stage.name,
                        "evidence": evidence,
                        "details": details,
                    },
                )
                current = self.store.verify().projection
                self._emit(
                    f"gate_pass_{stage.name}",
                    {
                        "status": "reused" if execution.reused else "PASS",
                        "stage": stage.name,
                        "fingerprint": evidence["evidence_fingerprint"],
                        "count": current.event_count,
                    },
                )
                continue

            diagnostic = execution.diagnostics[-1] if execution.diagnostics else None
            payload = {
                "stage": stage.name,
                "reason_code": execution.reason_code or "stage_failed",
                "command_index": diagnostic.command_index if diagnostic else 0,
                "first_failed_predicate": execution.first_failed_predicate or "stage_succeeded",
            }
            if execution.classification == "external":
                self.store.append("stage_paused", payload)
            else:
                self.store.append(
                    "stage_failed",
                    {**payload, "classification": execution.classification},
                )
            current = self.store.verify().projection
            key = (
                "workflow_paused"
                if current.status == "PAUSED_EXTERNAL"
                else "workflow_blocked"
            )
            self._emit(
                key,
                {
                    "status": current.status,
                    "stage": stage.name,
                    "reason_code": current.last_blocker,
                    "fingerprint": live.source_fingerprint,
                    "count": current.event_count,
                },
            )
            if current.status == "RESUMABLE_FAILURE":
                self.store.append(
                    "workflow_resumed", {"stage_index": current.current_stage_index}
                )
                continue
            return self.store.verify().projection.public_dict(self.contract)


def verify_projected_artifact(
    projection: WorkflowProjection,
    *,
    target_root: Path,
) -> dict[str, object]:
    if projection.artifact is None:
        return {"present": False, "valid": True, "fingerprint": None}
    value = projection.artifact
    path = Path(str(value["path"]))
    if not path.is_absolute():
        path = Path(target_root).resolve() / path
    if not path.is_file():
        raise WorkflowError("projected_artifact_missing")
    digest = _hash_bytes(path.read_bytes())
    expected = value.get("sha256")
    if digest != expected:
        raise WorkflowError("projected_artifact_hash_mismatch")
    return {"present": True, "valid": True, "fingerprint": digest}
