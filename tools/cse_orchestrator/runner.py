"""Controlled exact-argv execution with injected process adapters for CSE O6."""

from __future__ import annotations

import os
import subprocess
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Mapping, Protocol

from .ledger import RuntimeLedger
from .planner import ActionPlan, PlanError
from .policy import PolicyDecision
from .results import ParsedCommandResult, canonical_result_json, parse_command_result


class ExecutionError(RuntimeError):
    """Execution admission failed closed before an unapproved action."""


class ProcessAdapter(Protocol):
    def run(
        self,
        argv: tuple[str, ...],
        *,
        cwd: Path,
        environment: dict[str, str],
        timeout_seconds: int,
        output_limit_bytes: int,
    ) -> dict[str, object]: ...


def _bounded_decode(value: bytes, limit: int) -> tuple[str, bool]:
    truncated = len(value) > limit
    return value[:limit].decode("utf-8", errors="replace"), truncated


class SubprocessProcessAdapter:
    """Explicit execute-mode adapter; planning and tests do not instantiate it."""

    def __init__(self, command_family: str) -> None:
        if not isinstance(command_family, str) or not command_family:
            raise ValueError("command_family_required")
        self.command_family = command_family

    def run(
        self,
        argv: tuple[str, ...],
        *,
        cwd: Path,
        environment: dict[str, str],
        timeout_seconds: int,
        output_limit_bytes: int,
    ) -> dict[str, object]:
        started = time.monotonic()
        base = {
            "schema_version": 1,
            "command_family": self.command_family,
            "action_started": False,
            "wrapper_failed": False,
            "exit_code": None,
            "duration_ms": 0,
            "stdout": "",
            "stderr": "",
            "truncated": False,
            "timed_out": False,
            "failed_stage": None,
        }
        try:
            completed = subprocess.run(
                list(argv),
                cwd=cwd,
                env=environment,
                shell=False,
                stdin=subprocess.DEVNULL,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                timeout=timeout_seconds,
                check=False,
            )
        except subprocess.TimeoutExpired as exc:
            stdout, stdout_truncated = _bounded_decode(exc.stdout or b"", output_limit_bytes)
            stderr, stderr_truncated = _bounded_decode(exc.stderr or b"", output_limit_bytes)
            return {
                **base,
                "action_started": True,
                "duration_ms": int((time.monotonic() - started) * 1000),
                "stdout": stdout,
                "stderr": stderr,
                "truncated": stdout_truncated or stderr_truncated,
                "timed_out": True,
                "failed_stage": "subprocess_timeout",
            }
        except (OSError, ValueError) as exc:
            return {
                **base,
                "wrapper_failed": True,
                "duration_ms": int((time.monotonic() - started) * 1000),
                "stderr": f"process adapter initialization failed: {type(exc).__name__}",
                "failed_stage": "subprocess_start",
            }
        stdout, stdout_truncated = _bounded_decode(completed.stdout, output_limit_bytes)
        stderr, stderr_truncated = _bounded_decode(completed.stderr, output_limit_bytes)
        return {
            **base,
            "action_started": True,
            "exit_code": completed.returncode,
            "duration_ms": int((time.monotonic() - started) * 1000),
            "stdout": stdout,
            "stderr": stderr,
            "truncated": stdout_truncated or stderr_truncated,
        }


@dataclass(frozen=True)
class ExecutionResult:
    plan_sha256: str
    action_fingerprint: str
    success: bool
    state: str
    parsed_result: ParsedCommandResult

    def public_dict(self) -> dict[str, object]:
        return {
            "schema_version": 1,
            "plan_sha256": self.plan_sha256,
            "action_fingerprint": self.action_fingerprint,
            "success": self.success,
            "state": self.state,
            "result": self.parsed_result.public_dict(),
        }


def canonical_execution_json(result: ExecutionResult) -> str:
    if not isinstance(result, ExecutionResult):
        raise TypeError("execution_result_required")
    import json

    return json.dumps(
        result.public_dict(),
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    )


class ControlledRunner:
    def __init__(self, *, process_adapter: ProcessAdapter, ledger: RuntimeLedger) -> None:
        self.process_adapter = process_adapter
        self.ledger = ledger

    def execute(
        self,
        plan: ActionPlan,
        decision: PolicyDecision,
        *,
        execute: bool,
        current_source_fingerprint: str,
        current_action_fingerprint: str,
        environment: Mapping[str, str] | None = None,
    ) -> ExecutionResult:
        if not execute:
            raise ExecutionError("explicit_execute_required")
        if not isinstance(plan, ActionPlan):
            raise ExecutionError("action_plan_required")
        try:
            ActionPlan.from_dict(plan.public_dict())
        except PlanError as exc:
            raise ExecutionError(f"plan_invalid:{exc}") from exc
        if plan.mode != "execute":
            raise ExecutionError("execute_mode_plan_required")
        if not isinstance(decision, PolicyDecision) or not decision.allowed:
            raise ExecutionError("policy_admission_required")
        expected_running = (
            "CODEX_RUNNING"
            if plan.pending_action in {"CODE_CHANGE", "CORRECTION"}
            else "ACTION_RUNNING"
        )
        if (
            decision.state_to != expected_running
            or decision.required_approval_level != plan.required_approval_level
            or dict(decision.budget_delta or {}) != dict(plan.budget_delta)
        ):
            raise ExecutionError("policy_plan_mismatch")
        if current_source_fingerprint != plan.source_fingerprint:
            raise ExecutionError("source_fingerprint_drift")
        if current_action_fingerprint != plan.action_fingerprint:
            raise ExecutionError("action_fingerprint_drift")
        if self.ledger.run_id != plan.run_id:
            raise ExecutionError("ledger_run_mismatch")

        source_environment = environment or {}
        if not isinstance(source_environment, Mapping) or not all(
            isinstance(key, str) and isinstance(value, str)
            for key, value in source_environment.items()
        ):
            raise ExecutionError("environment_invalid")
        admitted_environment = {
            key: source_environment[key]
            for key in plan.environment_allowlist
            if key in source_environment
        }
        adapter_name = type(self.process_adapter).__name__
        self.ledger.append_admission(plan, adapter_name=adapter_name)
        try:
            raw = self.process_adapter.run(
                plan.argv,
                cwd=Path(plan.cwd),
                environment=admitted_environment,
                timeout_seconds=plan.timeout_seconds,
                output_limit_bytes=plan.output_limit_bytes,
            )
        except Exception as exc:  # adapter failures become frozen O3 evidence
            raw = {
                "schema_version": 1,
                "command_family": plan.command_family,
                "action_started": False,
                "wrapper_failed": True,
                "exit_code": None,
                "duration_ms": 0,
                "stdout": "",
                "stderr": f"process adapter failed: {type(exc).__name__}",
                "truncated": False,
                "timed_out": False,
                "failed_stage": "process_adapter",
            }
        if not isinstance(raw, dict):
            raise ExecutionError("adapter_result_invalid")
        if raw.get("command_family") != plan.command_family:
            raw = {
                "schema_version": 1,
                "command_family": plan.command_family,
                "action_started": False,
                "wrapper_failed": True,
                "exit_code": None,
                "duration_ms": 0,
                "stdout": "",
                "stderr": "adapter command family mismatch",
                "truncated": False,
                "timed_out": False,
                "failed_stage": "process_adapter",
            }
        parsed = parse_command_result(raw)
        success = parsed.failure_class is None and parsed.exit_code == 0
        state = plan.expected_success_state if success else plan.expected_failure_state
        result = ExecutionResult(
            plan_sha256=plan.plan_sha256,
            action_fingerprint=plan.action_fingerprint,
            success=success,
            state=state,
            parsed_result=parsed,
        )
        # Only data-minimal O3 output is persisted; raw streams never enter the ledger.
        self.ledger.append_result(plan, result.public_dict())
        return result
