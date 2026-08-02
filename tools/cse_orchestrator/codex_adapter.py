"""Exact-argv, one-shot Codex child adapter for CSE O9."""

from __future__ import annotations

import hashlib
import os
import re
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Mapping, Protocol


_FINGERPRINT = re.compile(r"^sha256:[0-9a-f]{64}$")
_SECRET = re.compile(
    r"(?i)(authorization\s*:\s*bearer|(?:api[_-]?key|token|secret|password)\s*[:=]|sk-[A-Za-z0-9_-]{12,}|gh[pousr]_[A-Za-z0-9_]{12,})"
)


class CodexAdapterError(RuntimeError):
    """A Codex child could not be safely admitted."""


@dataclass(frozen=True)
class CodexProcessResult:
    exit_code: int | None
    stdout: bytes
    stderr: bytes
    timed_out: bool
    truncated: bool


class CodexProcess(Protocol):
    def run(
        self,
        argv: tuple[str, ...],
        *,
        cwd: Path,
        environment: Mapping[str, str],
        prompt: bytes,
        timeout_seconds: int,
        output_limit_bytes: int,
    ) -> CodexProcessResult: ...


def _bounded(value: bytes, limit: int) -> tuple[bytes, bool]:
    return value[:limit], len(value) > limit


class SubprocessCodexProcess:
    """Real shell-free process adapter; callers must explicitly execute."""

    def run(
        self,
        argv: tuple[str, ...],
        *,
        cwd: Path,
        environment: Mapping[str, str],
        prompt: bytes,
        timeout_seconds: int,
        output_limit_bytes: int,
    ) -> CodexProcessResult:
        try:
            completed = subprocess.run(
                list(argv),
                cwd=cwd,
                env=dict(environment),
                input=prompt,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                timeout=timeout_seconds,
                check=False,
                shell=False,
            )
        except subprocess.TimeoutExpired as exc:
            stdout, stdout_truncated = _bounded(exc.stdout or b"", output_limit_bytes)
            stderr, stderr_truncated = _bounded(exc.stderr or b"", output_limit_bytes)
            return CodexProcessResult(
                None, stdout, stderr, True, stdout_truncated or stderr_truncated
            )
        except (OSError, ValueError):
            return CodexProcessResult(None, b"", b"codex process unavailable", False, False)
        stdout, stdout_truncated = _bounded(completed.stdout, output_limit_bytes)
        stderr, stderr_truncated = _bounded(completed.stderr, output_limit_bytes)
        return CodexProcessResult(
            completed.returncode,
            stdout,
            stderr,
            False,
            stdout_truncated or stderr_truncated,
        )


@dataclass(frozen=True)
class CodexChildRequest:
    action_fingerprint: str
    repo_root: Path
    runtime_root: Path
    prompt: str
    help_output: str
    environment_allowlist: tuple[str, ...]
    timeout_seconds: int
    output_limit_bytes: int


@dataclass(frozen=True)
class CodexChildResult:
    status: str
    executed: bool
    exit_code: int | None
    stdout_sha256: str | None
    stderr_sha256: str | None
    truncated: bool

    def public_dict(self) -> dict[str, object]:
        return {
            "status": self.status,
            "executed": self.executed,
            "exit_code": self.exit_code,
            "stdout_sha256": self.stdout_sha256,
            "stderr_sha256": self.stderr_sha256,
            "truncated": self.truncated,
        }


def _hash(value: bytes) -> str:
    return "sha256:" + hashlib.sha256(value).hexdigest()


def _outside(child: Path, parent: Path) -> bool:
    try:
        child.relative_to(parent)
        return False
    except ValueError:
        return True


def _validated_request(request: CodexChildRequest) -> tuple[Path, Path]:
    if not isinstance(request, CodexChildRequest):
        raise CodexAdapterError("codex_request_required")
    repo = request.repo_root.resolve()
    runtime = request.runtime_root.resolve()
    if not repo.is_dir():
        raise CodexAdapterError("repo_root_invalid")
    if not runtime.is_dir() or not _outside(runtime, repo):
        raise CodexAdapterError("runtime_root_must_be_external")
    if not _FINGERPRINT.fullmatch(request.action_fingerprint):
        raise CodexAdapterError("action_fingerprint_invalid")
    if not request.prompt or "\x00" in request.prompt or _SECRET.search(request.prompt):
        raise CodexAdapterError("prompt_invalid_or_secret")
    if len(request.prompt) > 12000:
        raise CodexAdapterError("prompt_too_large")
    if (
        "Usage: codex exec" not in request.help_output
        or not re.search(r"(?m)^\s*-\s+.*stdin", request.help_output, re.IGNORECASE)
    ):
        raise CodexAdapterError("codex_stdin_argv_not_verified")
    if request.timeout_seconds < 1 or request.output_limit_bytes < 1024:
        raise CodexAdapterError("codex_bounds_invalid")
    if len(set(request.environment_allowlist)) != len(request.environment_allowlist):
        raise CodexAdapterError("environment_allowlist_invalid")
    return repo, runtime


class CodexChildAdapter:
    """Admit each action fingerprint once and never invoke a shell."""

    def __init__(self, process: CodexProcess | None = None) -> None:
        self._process = process or SubprocessCodexProcess()
        self._used: set[str] = set()

    def execute(
        self,
        request: CodexChildRequest,
        *,
        execute: bool = False,
        environment: Mapping[str, str] | None = None,
    ) -> CodexChildResult:
        repo, runtime = _validated_request(request)
        if not execute:
            return CodexChildResult("DRY_RUN", False, None, None, None, False)
        if request.action_fingerprint in self._used:
            raise CodexAdapterError("duplicate_codex_child")
        self._used.add(request.action_fingerprint)
        source = environment if environment is not None else os.environ
        child_environment = {
            name: source[name]
            for name in request.environment_allowlist
            if name in source
        }
        temporary_path: Path | None = None
        try:
            with tempfile.NamedTemporaryFile(
                mode="wb",
                prefix="cse-o9-prompt-",
                suffix=".tmp",
                dir=runtime,
                delete=False,
            ) as stream:
                temporary_path = Path(stream.name)
                stream.write(request.prompt.encode("utf-8"))
            prompt = temporary_path.read_bytes()
            result = self._process.run(
                ("codex", "exec", "-"),
                cwd=repo,
                environment=child_environment,
                prompt=prompt,
                timeout_seconds=request.timeout_seconds,
                output_limit_bytes=request.output_limit_bytes,
            )
        finally:
            if temporary_path is not None:
                try:
                    temporary_path.unlink()
                except FileNotFoundError:
                    pass
        combined = (result.stdout + b"\n" + result.stderr).lower()
        if result.timed_out:
            status = "TIMEOUT"
        elif result.exit_code is None:
            status = "CLI_UNAVAILABLE"
        elif result.exit_code == 0:
            status = "PASS"
        elif b"auth" in combined or b"login" in combined:
            status = "AUTHENTICATION_FAILURE"
        else:
            status = "CHILD_FAILED"
        return CodexChildResult(
            status,
            True,
            result.exit_code,
            _hash(result.stdout),
            _hash(result.stderr),
            result.truncated,
        )
