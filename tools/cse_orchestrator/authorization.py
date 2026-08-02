"""Strict machine-readable authorization v1 parsing and selection."""

from __future__ import annotations

import hashlib
import json
import re
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any, Iterable, Mapping


AUTHORIZATION_MARKER = "<!-- cse-orchestrator-authorization:v1 -->"

TOP_LEVEL_FIELDS = frozenset(
    {
        "schema_version",
        "repository",
        "issue",
        "comment_id",
        "scope_version",
        "validation_class",
        "approval_level",
        "capability",
        "branch",
        "base_sha",
        "head_sha",
        "tree_sha",
        "action",
        "pending_action",
        "required_approval_level",
        "previous_state",
        "resume_state",
        "expected_success_state",
        "supersedes_comment_id",
        "runtime_root",
        "read_allowlist",
        "write_allowlist",
        "action_allowlist",
        "budgets",
        "expires_at",
        "nonce",
    }
)

BUDGET_FIELDS = frozenset(
    {
        "primary_max",
        "correction_max",
        "same_operation_retry_max",
        "focused_test_max",
        "compileall_max",
        "full_test_max",
        "integration_smoke_max",
        "git_mutation_max",
        "github_mutation_max",
        "api_max",
        "build_max",
        "device_max",
        "target_seconds",
        "hard_stop_seconds",
    }
)

APPROVAL_LEVELS = frozenset(
    {
        "SAFE_READ",
        "CODE_CHANGE",
        "CORRECTION",
        "FULL_VALIDATION",
        "CHECKPOINT_COMMIT",
        "BUILD",
        "DEVICE",
        "PUBLISH",
        "MERGE",
        "RELEASE",
    }
)
CAPABILITIES = frozenset({"Code", "Device", "Publish"})
SHA_PATTERN = re.compile(r"^[0-9a-f]{40}$")
UTC_PATTERN = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$")
FENCED_JSON_PATTERN = re.compile(r"```json\s*(\{.*?\})\s*```", re.DOTALL)


class AuthorizationError(ValueError):
    """A machine authorization cannot be trusted."""

    def __init__(self, reason: str):
        super().__init__(reason)
        self.reason = reason


class AuthorizationExpired(AuthorizationError):
    """A structurally valid authorization is no longer current."""


@dataclass(frozen=True)
class ParsedAuthorization:
    comment_id: int
    payload: dict[str, Any]
    payload_hash: str
    expires_at: datetime


@dataclass(frozen=True)
class AuthorizationSelection:
    status: str
    comment_id: int | None = None
    payload_hash: str | None = None
    payload: dict[str, Any] | None = None
    reasons: tuple[str, ...] = ()

    def public_dict(self) -> dict[str, Any]:
        payload = self.payload or {}
        return {
            "status": self.status,
            "comment_id": self.comment_id,
            "payload_hash": self.payload_hash,
            "approval_level": payload.get("approval_level"),
            "capability": payload.get("capability"),
            "action": payload.get("action"),
            "reasons": list(self.reasons),
        }


def _reject_duplicate_pairs(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    value: dict[str, Any] = {}
    for key, item in pairs:
        if key in value:
            raise AuthorizationError(f"duplicate_field:{key}")
        value[key] = item
    return value


def canonical_json_bytes(payload: Mapping[str, Any]) -> bytes:
    """Return the canonical sorted UTF-8 representation used for fingerprints."""

    return json.dumps(
        payload,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")


def payload_sha256(payload: Mapping[str, Any]) -> str:
    return hashlib.sha256(canonical_json_bytes(payload)).hexdigest()


def _require_exact_fields(value: Mapping[str, Any], expected: frozenset[str], label: str) -> None:
    actual = set(value)
    missing = sorted(expected - actual)
    unknown = sorted(actual - expected)
    if missing:
        raise AuthorizationError(f"missing_fields:{label}:{','.join(missing)}")
    if unknown:
        raise AuthorizationError(f"unknown_fields:{label}:{','.join(unknown)}")


def _require_int(value: Any, field: str, *, positive: bool = False) -> int:
    if isinstance(value, bool) or not isinstance(value, int):
        raise AuthorizationError(f"invalid_integer:{field}")
    if value < (1 if positive else 0):
        raise AuthorizationError(f"invalid_integer:{field}")
    return value


def _require_string(value: Any, field: str) -> str:
    if not isinstance(value, str) or not value:
        raise AuthorizationError(f"invalid_string:{field}")
    return value


def _require_string_list(value: Any, field: str) -> list[str]:
    if not isinstance(value, list) or not all(isinstance(item, str) and item for item in value):
        raise AuthorizationError(f"invalid_string_list:{field}")
    if len(set(value)) != len(value):
        raise AuthorizationError(f"duplicate_list_item:{field}")
    return value


def _parse_expiry(value: Any) -> datetime:
    expires_at = _require_string(value, "expires_at")
    if not UTC_PATTERN.fullmatch(expires_at):
        raise AuthorizationError("expires_at_utc_required")
    try:
        return datetime.strptime(expires_at, "%Y-%m-%dT%H:%M:%SZ").replace(
            tzinfo=timezone.utc
        )
    except ValueError as exc:
        raise AuthorizationError("expires_at_utc_invalid") from exc


def _validate_payload(payload: dict[str, Any], transport_comment_id: int) -> datetime:
    _require_exact_fields(payload, TOP_LEVEL_FIELDS, "authorization")
    if payload["schema_version"] != 1:
        raise AuthorizationError("schema_version_must_be_1")

    _require_string(payload["repository"], "repository")
    _require_int(payload["issue"], "issue", positive=True)
    comment_id = _require_int(payload["comment_id"], "comment_id", positive=True)
    if comment_id != transport_comment_id:
        raise AuthorizationError("comment_id_mismatch")
    _require_int(payload["scope_version"], "scope_version", positive=True)
    _require_string(payload["validation_class"], "validation_class")

    approval_level = _require_string(payload["approval_level"], "approval_level")
    if approval_level not in APPROVAL_LEVELS:
        raise AuthorizationError("approval_level_invalid")
    if payload["required_approval_level"] != approval_level:
        raise AuthorizationError("required_approval_level_mismatch")
    capability = _require_string(payload["capability"], "capability")
    if capability not in CAPABILITIES:
        raise AuthorizationError("capability_invalid")

    for field in (
        "branch",
        "action",
        "pending_action",
        "required_approval_level",
        "previous_state",
        "resume_state",
        "expected_success_state",
        "runtime_root",
        "nonce",
    ):
        _require_string(payload[field], field)
    if payload["pending_action"] != payload["action"]:
        raise AuthorizationError("pending_action_mismatch")

    for field in ("base_sha", "head_sha", "tree_sha"):
        value = _require_string(payload[field], field)
        if not SHA_PATTERN.fullmatch(value):
            raise AuthorizationError(f"invalid_sha:{field}")

    supersedes = payload["supersedes_comment_id"]
    if supersedes is not None:
        _require_int(supersedes, "supersedes_comment_id", positive=True)

    for field in ("read_allowlist", "write_allowlist", "action_allowlist"):
        _require_string_list(payload[field], field)

    budgets = payload["budgets"]
    if not isinstance(budgets, dict):
        raise AuthorizationError("budgets_must_be_object")
    actual_budget_fields = set(budgets)
    if actual_budget_fields != BUDGET_FIELDS:
        missing = sorted(BUDGET_FIELDS - actual_budget_fields)
        unknown = sorted(actual_budget_fields - BUDGET_FIELDS)
        raise AuthorizationError(
            "budget_fields_invalid:"
            f"missing={','.join(missing)};unknown={','.join(unknown)}"
        )
    for field in BUDGET_FIELDS:
        _require_int(budgets[field], f"budgets.{field}")
    if budgets["hard_stop_seconds"] < budgets["target_seconds"]:
        raise AuthorizationError("budget_hard_stop_before_target")

    return _parse_expiry(payload["expires_at"])


def parse_authorization_comment(
    comment: Mapping[str, Any],
    *,
    now: datetime | None = None,
) -> ParsedAuthorization:
    """Parse one transport comment without exposing its body in the result."""

    transport_comment_id = _require_int(comment.get("id"), "transport_comment_id", positive=True)
    body = comment.get("body")
    if not isinstance(body, str):
        raise AuthorizationError("comment_body_missing")
    if body.count(AUTHORIZATION_MARKER) != 1:
        raise AuthorizationError("authorization_marker_count_invalid")

    tail = body.split(AUTHORIZATION_MARKER, 1)[1]
    matches = FENCED_JSON_PATTERN.findall(tail)
    if len(matches) != 1 or tail.count("```json") != 1:
        raise AuthorizationError("authorization_json_fence_count_invalid")
    try:
        payload = json.loads(matches[0], object_pairs_hook=_reject_duplicate_pairs)
    except AuthorizationError:
        raise
    except (json.JSONDecodeError, TypeError) as exc:
        raise AuthorizationError("authorization_json_invalid") from exc
    if not isinstance(payload, dict):
        raise AuthorizationError("authorization_payload_must_be_object")

    expires_at = _validate_payload(payload, transport_comment_id)
    current = now or datetime.now(timezone.utc)
    if current.tzinfo is None or current.utcoffset() is None:
        raise ValueError("now must be timezone-aware")
    if current.astimezone(timezone.utc) >= expires_at:
        raise AuthorizationExpired("authorization_expired")

    return ParsedAuthorization(
        comment_id=transport_comment_id,
        payload=payload,
        payload_hash=payload_sha256(payload),
        expires_at=expires_at,
    )


def select_latest_authorization(
    comments: Iterable[Mapping[str, Any]],
    *,
    now: datetime | None = None,
) -> AuthorizationSelection:
    """Select only a schema-valid authorization with an explicit supersession chain."""

    ordered = sorted(comments, key=lambda item: int(item.get("id", 0)))
    candidates = [
        item
        for item in ordered
        if isinstance(item.get("body"), str)
        and AUTHORIZATION_MARKER in str(item.get("body"))
    ]
    if not candidates:
        return AuthorizationSelection(status="missing")

    active: ParsedAuthorization | None = None
    last_failure: AuthorizationSelection | None = None
    for item in candidates:
        try:
            parsed = parse_authorization_comment(item, now=now)
        except AuthorizationExpired as exc:
            if active is None:
                last_failure = AuthorizationSelection(
                    status="expired",
                    comment_id=int(item.get("id", 0)) or None,
                    reasons=(exc.reason,),
                )
            continue
        except AuthorizationError as exc:
            if active is None:
                last_failure = AuthorizationSelection(
                    status="invalid",
                    comment_id=int(item.get("id", 0)) or None,
                    reasons=(exc.reason,),
                )
            continue

        supersedes = parsed.payload["supersedes_comment_id"]
        if active is None:
            if supersedes is None:
                active = parsed
            else:
                last_failure = AuthorizationSelection(
                    status="invalid",
                    comment_id=parsed.comment_id,
                    payload_hash=parsed.payload_hash,
                    reasons=("supersedes_unknown_comment",),
                )
        elif supersedes == active.comment_id:
            active = parsed

    if active is not None:
        return AuthorizationSelection(
            status="valid",
            comment_id=active.comment_id,
            payload_hash=active.payload_hash,
            payload=active.payload,
        )
    return last_failure or AuthorizationSelection(status="missing")
