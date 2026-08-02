"""Pure deterministic parser for frozen CSE command results.

The module does not start actions, admit budgets, make policy decisions, or
perform filesystem, subprocess, network, GitHub, or device I/O. It converts an
immutable caller-owned mapping into data-minimal result evidence only.
"""

from __future__ import annotations

import hashlib
import json
import re
from dataclasses import dataclass
from types import MappingProxyType
from typing import Mapping, Sequence


COMMAND_FAMILIES = frozenset(
    {
        "pytest",
        "compileall",
        "git_diff_check",
        "flutter_test",
        "flutter_analyze",
        "build",
        "generic_command",
    }
)

INPUT_FIELDS = frozenset(
    {
        "schema_version",
        "command_family",
        "action_started",
        "wrapper_failed",
        "exit_code",
        "duration_ms",
        "stdout",
        "stderr",
        "truncated",
        "timed_out",
        "failed_stage",
    }
)

COUNT_FIELDS = ("passed", "failed", "skipped", "errors", "warnings", "total")
MAX_EXCERPT_LINES = 8
MAX_EXCERPT_CHARS = 200

_SECRET_ASSIGNMENT = re.compile(
    r"(?i)\b(token|password|passwd|secret|api[_-]?key|credential)"
    r"\s*[:=]\s*[^\s,;]+"
)
_AUTHORIZATION = re.compile(r"(?i)\bauthorization\s*:\s*bearer\s+\S+")
_TOKEN_SHAPE = re.compile(
    r"\b(?:gh[pousr]_[A-Za-z0-9_]{12,}|sk-[A-Za-z0-9_-]{12,})\b"
)
_EMAIL = re.compile(r"\b[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b")
_WINDOWS_USER_PATH = re.compile(r"(?i)\b[A-Z]:\\Users\\[^\\\s]+")


class ResultInputError(ValueError):
    """The frozen result input cannot be trusted or interpreted safely."""


@dataclass(frozen=True)
class ParsedCommandResult:
    schema_version: int
    command_family: str
    action_started: bool
    wrapper_failed: bool
    exit_code: int | None
    duration_ms: int
    counts: Mapping[str, int | None]
    failure_class: str | None
    failed_stage: str | None
    budget_consumed: bool
    stdout_hash: str
    stderr_hash: str
    sanitized_excerpt: tuple[str, ...]
    truncated: bool
    timed_out: bool
    reasons: tuple[str, ...]

    def public_dict(self) -> dict[str, object]:
        return {
            "schema_version": self.schema_version,
            "command_family": self.command_family,
            "action_started": self.action_started,
            "wrapper_failed": self.wrapper_failed,
            "exit_code": self.exit_code,
            "duration_ms": self.duration_ms,
            "counts": {field: self.counts[field] for field in COUNT_FIELDS},
            "failure_class": self.failure_class,
            "failed_stage": self.failed_stage,
            "budget_consumed": self.budget_consumed,
            "stdout_hash": self.stdout_hash,
            "stderr_hash": self.stderr_hash,
            "sanitized_excerpt": list(self.sanitized_excerpt),
            "truncated": self.truncated,
            "timed_out": self.timed_out,
            "reasons": list(self.reasons),
        }


@dataclass(frozen=True)
class _FamilyEvidence:
    counts: Mapping[str, int | None]
    success_signal: bool
    failure_signal: bool
    recognized: bool
    failure_class: str
    reasons: tuple[str, ...] = ()


def canonical_result_json(result: ParsedCommandResult) -> str:
    if not isinstance(result, ParsedCommandResult):
        raise TypeError("parsed_result_required")
    return json.dumps(
        result.public_dict(),
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    )


def _hash_stream(value: str) -> str:
    return "sha256:" + hashlib.sha256(value.encode("utf-8")).hexdigest()


def _unknown_counts() -> dict[str, int | None]:
    return {field: None for field in COUNT_FIELDS}


def _known_counts(
    *,
    passed: int = 0,
    failed: int = 0,
    skipped: int = 0,
    errors: int = 0,
    warnings: int = 0,
) -> dict[str, int]:
    return {
        "passed": passed,
        "failed": failed,
        "skipped": skipped,
        "errors": errors,
        "warnings": warnings,
        "total": passed + failed + skipped + errors,
    }


def _sanitize_line(value: str) -> str:
    value = _AUTHORIZATION.sub("Authorization: Bearer [REDACTED]", value)
    value = _TOKEN_SHAPE.sub("[REDACTED]", value)
    value = _SECRET_ASSIGNMENT.sub(
        lambda match: f"{match.group(1)}=[REDACTED]", value
    )
    value = _EMAIL.sub("[EMAIL]", value)
    value = _WINDOWS_USER_PATH.sub("%USERPROFILE%", value)
    if len(value) > MAX_EXCERPT_CHARS:
        return value[: MAX_EXCERPT_CHARS - 1] + "…"
    return value


def _sanitized_excerpt(stdout: str, stderr: str) -> tuple[str, ...]:
    lines: list[str] = []
    for stream in (stdout, stderr):
        for line in stream.splitlines():
            if not line.strip():
                continue
            lines.append(_sanitize_line(line))
            if len(lines) == MAX_EXCERPT_LINES:
                return tuple(lines)
    return tuple(lines)


def _validate_input(value: Mapping[str, object]) -> dict[str, object]:
    if not isinstance(value, Mapping):
        raise ResultInputError("mapping_required")
    actual = set(value)
    missing = sorted(INPUT_FIELDS - actual)
    unknown = sorted(actual - INPUT_FIELDS)
    if missing:
        raise ResultInputError(f"missing_fields:{','.join(missing)}")
    if unknown:
        raise ResultInputError(f"unknown_fields:{','.join(unknown)}")

    result = dict(value)
    schema_version = result["schema_version"]
    if isinstance(schema_version, bool) or schema_version != 1:
        raise ResultInputError("unsupported_schema_version")

    family = result["command_family"]
    if not isinstance(family, str) or family not in COMMAND_FAMILIES:
        raise ResultInputError("unknown_command_family")

    for field in ("action_started", "wrapper_failed", "truncated", "timed_out"):
        if not isinstance(result[field], bool):
            raise ResultInputError(f"invalid_boolean:{field}")

    exit_code = result["exit_code"]
    if exit_code is not None and (
        isinstance(exit_code, bool) or not isinstance(exit_code, int)
    ):
        raise ResultInputError("invalid_exit_code")

    duration_ms = result["duration_ms"]
    if (
        isinstance(duration_ms, bool)
        or not isinstance(duration_ms, int)
        or duration_ms < 0
    ):
        raise ResultInputError("invalid_duration_ms")

    for field in ("stdout", "stderr"):
        if not isinstance(result[field], str):
            raise ResultInputError(f"invalid_text:{field}")

    failed_stage = result["failed_stage"]
    if failed_stage is not None and (
        not isinstance(failed_stage, str) or not failed_stage
    ):
        raise ResultInputError("invalid_failed_stage")

    action_started = result["action_started"]
    wrapper_failed = result["wrapper_failed"]
    timed_out = result["timed_out"]
    if not action_started:
        if not wrapper_failed:
            raise ResultInputError("action_not_started_without_wrapper_failure")
        if timed_out:
            raise ResultInputError("timeout_before_action_start")
        if exit_code is not None:
            raise ResultInputError("exit_code_before_action_start")
    elif exit_code is None and not (wrapper_failed or timed_out):
        raise ResultInputError("missing_exit_code_after_action_start")
    return result


def _pytest_evidence(text: str) -> _FamilyEvidence:
    counts = _known_counts()
    tokens = re.findall(
        r"(?<!\w)(\d+)\s+(passed|failed|skipped|error|errors|warning|warnings)\b",
        text,
        flags=re.IGNORECASE,
    )
    no_tests = bool(re.search(r"\bno tests ran\b", text, flags=re.IGNORECASE))
    collection_error = bool(
        re.search(r"\bERROR collecting\b", text, flags=re.IGNORECASE)
    )
    interrupted = "KeyboardInterrupt" in text or "Interrupted" in text
    if tokens:
        values = {field: 0 for field in COUNT_FIELDS[:-1]}
        for raw_count, raw_name in tokens:
            name = raw_name.lower()
            field = {
                "error": "errors",
                "errors": "errors",
                "warning": "warnings",
                "warnings": "warnings",
            }.get(name, name)
            values[field] = int(raw_count)
        counts = _known_counts(**values)
    reasons: list[str] = []
    if no_tests:
        reasons.append("no_tests_collected")
    if collection_error:
        reasons.append("collection_error")
    if interrupted:
        reasons.append("interrupted")
    failure_signal = (
        no_tests
        or collection_error
        or interrupted
        or counts["failed"] > 0
        or counts["errors"] > 0
    )
    success_signal = bool(tokens and counts["passed"] > 0 and not failure_signal)
    return _FamilyEvidence(
        counts=counts,
        success_signal=success_signal,
        failure_signal=failure_signal,
        recognized=bool(tokens or no_tests or collection_error or interrupted),
        failure_class="source" if collection_error else "test",
        reasons=tuple(reasons),
    )


def _compileall_evidence(text: str) -> _FamilyEvidence:
    failure = bool(
        re.search(r"\*\*\* Error compiling|\bSyntaxError\b", text, re.IGNORECASE)
    )
    reasons = ("compile_error",) if failure else ()
    return _FamilyEvidence(
        counts=_unknown_counts(),
        success_signal=not failure,
        failure_signal=failure,
        recognized=True,
        failure_class="source",
        reasons=reasons,
    )


def _diff_evidence(text: str) -> _FamilyEvidence:
    failure = bool(
        re.search(
            r"trailing whitespace|space before tab|new blank line at EOF",
            text,
            re.IGNORECASE,
        )
    )
    reasons = ("whitespace_error",) if failure else ()
    return _FamilyEvidence(
        counts=_unknown_counts(),
        success_signal=not failure,
        failure_signal=failure,
        recognized=True,
        failure_class="source",
        reasons=reasons,
    )


def _flutter_test_evidence(text: str) -> _FamilyEvidence:
    matches = re.findall(r"\+(\d+)(?:\s+-(\d+))?(?:\s+~(\d+))?", text)
    counts: Mapping[str, int | None] = _unknown_counts()
    failed = 0
    if matches:
        passed_raw, failed_raw, skipped_raw = matches[-1]
        failed = int(failed_raw or 0)
        counts = _known_counts(
            passed=int(passed_raw),
            failed=failed,
            skipped=int(skipped_raw or 0),
        )
    explicit_success = "All tests passed!" in text
    explicit_failure = "Some tests failed" in text or failed > 0
    return _FamilyEvidence(
        counts=counts,
        success_signal=explicit_success,
        failure_signal=explicit_failure,
        recognized=bool(matches or explicit_success or explicit_failure),
        failure_class="test",
    )


def _flutter_analyze_evidence(text: str) -> _FamilyEvidence:
    no_issues = "No issues found!" in text
    issue_match = re.search(r"\b(\d+) issues? found\b", text, re.IGNORECASE)
    errors = len(re.findall(r"(?im)^\s*error\s*[•-]", text))
    warnings = len(re.findall(r"(?im)^\s*warning\s*[•-]", text))
    counts = _unknown_counts()
    if no_issues:
        counts.update({"errors": 0, "warnings": 0, "total": 0})
    elif issue_match:
        counts.update(
            {
                "errors": errors,
                "warnings": warnings,
                "total": int(issue_match.group(1)),
            }
        )
    return _FamilyEvidence(
        counts=counts,
        success_signal=no_issues,
        failure_signal=bool(issue_match and int(issue_match.group(1)) > 0),
        recognized=bool(no_issues or issue_match),
        failure_class="analyze",
    )


def _build_evidence(text: str) -> _FamilyEvidence:
    success = bool(
        re.search(r"\bBUILD SUCCESSFUL\b|\bBuilt\b", text, re.IGNORECASE)
    )
    failure = bool(
        re.search(r"\bBUILD FAILED\b|\bBuild failed\b", text, re.IGNORECASE)
    )
    return _FamilyEvidence(
        counts=_unknown_counts(),
        success_signal=success,
        failure_signal=failure,
        recognized=success or failure,
        failure_class="build",
    )


def _generic_evidence(text: str) -> _FamilyEvidence:
    toolchain_failure = bool(
        re.search(
            r"command not found|not recognized as an internal or external command|"
            r"No such file or directory",
            text,
            re.IGNORECASE,
        )
    )
    return _FamilyEvidence(
        counts=_unknown_counts(),
        success_signal=False,
        failure_signal=toolchain_failure,
        recognized=True,
        failure_class="toolchain" if toolchain_failure else "unknown",
        reasons=("toolchain_unavailable",) if toolchain_failure else (),
    )


def _family_evidence(family: str, text: str) -> _FamilyEvidence:
    parsers = {
        "pytest": _pytest_evidence,
        "compileall": _compileall_evidence,
        "git_diff_check": _diff_evidence,
        "flutter_test": _flutter_test_evidence,
        "flutter_analyze": _flutter_analyze_evidence,
        "build": _build_evidence,
        "generic_command": _generic_evidence,
    }
    return parsers[family](text)


def _ordered_reasons(values: Sequence[str]) -> tuple[str, ...]:
    return tuple(sorted(set(values)))


def parse_command_result(value: Mapping[str, object]) -> ParsedCommandResult:
    """Parse frozen command evidence without starting or authorizing an action."""

    source = _validate_input(value)
    family = str(source["command_family"])
    action_started = bool(source["action_started"])
    wrapper_failed = bool(source["wrapper_failed"])
    stdout = str(source["stdout"])
    stderr = str(source["stderr"])
    truncated = bool(source["truncated"])
    timed_out = bool(source["timed_out"])
    exit_code = source["exit_code"]
    text = stdout + "\n" + stderr
    evidence = _family_evidence(family, text)
    reasons = list(evidence.reasons)
    failure_class: str | None = None

    if truncated:
        reasons.append("output_truncated")

    if not action_started:
        failure_class = "harness"
        reasons.extend(("action_not_started", "wrapper_failure"))
    elif wrapper_failed:
        failure_class = "harness"
        reasons.append("wrapper_failure")
    elif timed_out:
        failure_class = "timeout"
        reasons.append("timeout")
    else:
        contradiction = (
            exit_code == 0 and evidence.failure_signal
        ) or (
            exit_code is not None
            and exit_code != 0
            and evidence.success_signal
            and not evidence.failure_signal
        )
        if contradiction:
            failure_class = "provenance"
            reasons.append("exit_output_contradiction")
        elif not evidence.recognized:
            failure_class = "provenance"
            reasons.append("output_unrecognized")
        elif exit_code != 0:
            failure_class = evidence.failure_class

    return ParsedCommandResult(
        schema_version=1,
        command_family=family,
        action_started=action_started,
        wrapper_failed=wrapper_failed,
        exit_code=exit_code if isinstance(exit_code, int) else None,
        duration_ms=int(source["duration_ms"]),
        counts=MappingProxyType(dict(evidence.counts)),
        failure_class=failure_class,
        failed_stage=(
            str(source["failed_stage"])
            if source["failed_stage"] is not None
            else None
        ),
        budget_consumed=action_started,
        stdout_hash=_hash_stream(stdout),
        stderr_hash=_hash_stream(stderr),
        sanitized_excerpt=_sanitized_excerpt(stdout, stderr),
        truncated=truncated,
        timed_out=timed_out,
        reasons=_ordered_reasons(reasons),
    )
