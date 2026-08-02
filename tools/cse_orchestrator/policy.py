"""Pure deterministic action-admission policy for CSE O2.

The module deliberately has no runner, network adapter, filesystem adapter, or
approval persistence. It evaluates immutable caller-owned data and returns a
canonicalizable decision only.
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any, Mapping, Sequence

from .state import State, can_transition, parse_state


APPROVAL_ORDER = (
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
)

CODE_ACTIONS = frozenset({"CODE_CHANGE", "CORRECTION"})
GENERIC_ACTIONS = frozenset(
    {"FULL_VALIDATION", "CHECKPOINT_COMMIT", "BUILD", "DEVICE", "PUBLISH"}
)
ACTION_TYPES = CODE_ACTIONS | GENERIC_ACTIONS

CAPABILITY_FOR_ACTION: Mapping[str, str] = {
    "CODE_CHANGE": "Code",
    "CORRECTION": "Code",
    "FULL_VALIDATION": "Code",
    "CHECKPOINT_COMMIT": "Code",
    "BUILD": "Code",
    "DEVICE": "Device",
    "PUBLISH": "Publish",
}

SUCCESS_STATE_FOR_ACTION: Mapping[str, str] = {
    "CODE_CHANGE": "FOCUSED_PASS",
    "CORRECTION": "FOCUSED_PASS",
    "FULL_VALIDATION": "FULL_PASS",
    "CHECKPOINT_COMMIT": "CHECKPOINT_COMMITTED",
    "BUILD": "ARTIFACT_BUILT",
    "DEVICE": "DEVICE_ACCEPTANCE",
    "PUBLISH": "COMPLETED",
}

RESUME_STATE_FOR_ACTION: Mapping[str, str] = {
    "CODE_CHANGE": "SCOPE_VALIDATED",
    "CORRECTION": "SCOPE_VALIDATED",
    "FULL_VALIDATION": "FOCUSED_PASS",
    "CHECKPOINT_COMMIT": "SOURCE_VALIDATED",
    "BUILD": "CHECKPOINT_COMMITTED",
    "DEVICE": "ARTIFACT_BUILT",
    "PUBLISH": "PUBLISH_READY",
}

BUDGET_COUNTER_FOR_ACTION: Mapping[str, str] = {
    "CODE_CHANGE": "primary",
    "CORRECTION": "correction",
    "FULL_VALIDATION": "full_gate",
    "CHECKPOINT_COMMIT": "checkpoint_commit",
    "BUILD": "build",
    "DEVICE": "device",
    "PUBLISH": "publish",
}

AWAITING_ACTIONS_FOR_STATE: Mapping[str, frozenset[str]] = {
    "SCOPE_VALIDATED": CODE_ACTIONS,
    "FOCUSED_PASS": frozenset({"FULL_VALIDATION"}),
    "SOURCE_VALIDATED": frozenset({"CHECKPOINT_COMMIT"}),
    "CHECKPOINT_COMMITTED": frozenset({"BUILD"}),
    "ARTIFACT_BUILT": frozenset({"DEVICE"}),
    "PUBLISH_READY": frozenset({"PUBLISH"}),
}

SKIPPED_GATES: Mapping[tuple[str, str], tuple[str, ...]] = {
    ("FOCUSED_PASS", "SOURCE_VALIDATED"): ("FULL_VALIDATION",),
    ("CHECKPOINT_COMMITTED", "PUBLISH_READY"): ("BUILD", "DEVICE"),
    ("ARTIFACT_BUILT", "PUBLISH_READY"): ("DEVICE",),
    ("PUBLISH_READY", "COMPLETED"): ("PUBLISH",),
}

BLOCKER_PRECEDENCE = (
    "USER_DATA_RISK",
    "PROVENANCE_MISMATCH",
    "SCOPE_DRIFT",
    "ALLOWLIST_VIOLATION",
    "APPROVAL_EXPIRED",
    "SOURCE_FAILURE",
    "STATE_DRIFT",
    "RETRY_BUDGET_EXHAUSTED",
    "TIME_BUDGET_EXHAUSTED",
    "TOOLCHAIN_FAILURE",
    "AUTOMATION_HARNESS_FAILURE",
    "DEVICE_UNAVAILABLE",
    "DEVICE_UI_TARGET_NOT_FOUND",
    "TEST_FAILURE",
    "ANALYZE_FAILURE",
)
_BLOCKER_RANK = {value: index for index, value in enumerate(BLOCKER_PRECEDENCE)}

TOP_LEVEL_FIELDS = frozenset(
    {
        "schema_version",
        "evaluated_at",
        "state_from",
        "state_to",
        "pending_action",
        "required_approval_level",
        "resume_state",
        "expected_success_state",
        "capability",
        "authorization",
        "current_fingerprints",
        "budget",
        "retry",
        "blockers",
        "reused_evidence",
        "gate_dispositions",
    }
)
FINGERPRINT_FIELDS = frozenset(
    {"source", "contract", "scope", "action", "capability", "budget"}
)
AUTHORIZATION_FIELDS = frozenset(
    {
        "status",
        "approval_level",
        "capability",
        "expires_at",
        "consumed",
        "superseded",
        "fingerprints",
    }
)
BUDGET_FIELDS = frozenset(
    {
        "primary_used",
        "primary_max",
        "correction_used",
        "correction_max",
        "same_operation_retry_used",
        "same_operation_retry_max",
        "full_gate_used",
        "full_gate_max",
        "checkpoint_commit_used",
        "checkpoint_commit_max",
        "build_used",
        "build_max",
        "device_used",
        "device_max",
        "publish_used",
        "publish_max",
        "elapsed_seconds",
        "hard_stop_seconds",
        "full_gate_revision",
    }
)
RETRY_FIELDS = frozenset(
    {"same_operation", "failed_action", "correction_fingerprint"}
)
EVIDENCE_FIELDS = frozenset(
    {
        "gate",
        "status",
        "source_fingerprint",
        "contract_fingerprint",
        "evidence_fingerprint",
    }
)
GATE_DISPOSITION_FIELDS = frozenset({"gate", "status", "reason"})


@dataclass(frozen=True)
class PolicyDecision:
    allowed: bool
    state_from: str
    state_to: str
    required_approval_level: str | None
    blockers: tuple[str, ...] = ()
    budget_delta: Mapping[str, int] | None = None
    reused_evidence: tuple[dict[str, str], ...] = ()
    reasons: tuple[str, ...] = ()

    def public_dict(self) -> dict[str, object]:
        return {
            "allowed": self.allowed,
            "state_from": self.state_from,
            "state_to": self.state_to,
            "required_approval_level": self.required_approval_level,
            "blockers": list(self.blockers),
            "budget_delta": dict(self.budget_delta or {}),
            "reused_evidence": [dict(item) for item in self.reused_evidence],
            "reasons": list(self.reasons),
        }


def canonical_decision_json(decision: PolicyDecision) -> str:
    return json.dumps(
        decision.public_dict(),
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    )


def approval_satisfies(granted: str, required: str) -> bool:
    try:
        return APPROVAL_ORDER.index(granted) >= APPROVAL_ORDER.index(required)
    except ValueError:
        return False


def _ordered_blockers(values: Sequence[str]) -> tuple[str, ...]:
    return tuple(
        sorted(
            set(values),
            key=lambda value: (_BLOCKER_RANK.get(value, len(_BLOCKER_RANK)), value),
        )
    )


def _ordered_reasons(values: Sequence[str]) -> tuple[str, ...]:
    return tuple(sorted(set(values)))


def _canonical_item(value: Mapping[str, object]) -> str:
    return json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    )


def _deny(
    *,
    state_from: str,
    required_approval_level: str | None,
    blockers: Sequence[str],
    reasons: Sequence[str],
    state_to: str = "BLOCKED",
) -> PolicyDecision:
    return PolicyDecision(
        allowed=False,
        state_from=state_from,
        state_to=state_to,
        required_approval_level=required_approval_level,
        blockers=_ordered_blockers(blockers),
        budget_delta={},
        reused_evidence=(),
        reasons=_ordered_reasons(reasons),
    )


def _parse_utc(value: object, field: str) -> datetime:
    if not isinstance(value, str) or not value.endswith("Z"):
        raise ValueError(f"invalid_utc:{field}")
    try:
        parsed = datetime.strptime(value, "%Y-%m-%dT%H:%M:%SZ")
    except ValueError as exc:
        raise ValueError(f"invalid_utc:{field}") from exc
    return parsed.replace(tzinfo=timezone.utc)


def _exact_fields(value: object, expected: frozenset[str], label: str) -> Mapping[str, Any]:
    if not isinstance(value, Mapping):
        raise ValueError(f"invalid_object:{label}")
    actual = set(value)
    missing = sorted(expected - actual)
    unknown = sorted(actual - expected)
    if missing:
        raise ValueError(f"missing_fields:{label}:{','.join(missing)}")
    if unknown:
        raise ValueError(f"unknown_fields:{label}:{','.join(unknown)}")
    return value


def _parse_fingerprints(value: object, label: str) -> dict[str, str]:
    mapping = _exact_fields(value, FINGERPRINT_FIELDS, label)
    result: dict[str, str] = {}
    for field in sorted(FINGERPRINT_FIELDS):
        item = mapping[field]
        if not isinstance(item, str) or not item:
            raise ValueError(f"invalid_fingerprint:{label}.{field}")
        result[field] = item
    return result


def _parse_budget(value: object) -> dict[str, object]:
    mapping = _exact_fields(value, BUDGET_FIELDS, "budget")
    result = dict(mapping)
    for counter in (
        "primary",
        "correction",
        "same_operation_retry",
        "full_gate",
        "checkpoint_commit",
        "build",
        "device",
        "publish",
    ):
        used = result[f"{counter}_used"]
        maximum = result[f"{counter}_max"]
        if (
            isinstance(used, bool)
            or isinstance(maximum, bool)
            or not isinstance(used, int)
            or not isinstance(maximum, int)
            or used < 0
            or maximum < 0
            or used > maximum
        ):
            raise ValueError(f"invalid_budget_counter:{counter}")
    elapsed = result["elapsed_seconds"]
    hard_stop = result["hard_stop_seconds"]
    if (
        isinstance(elapsed, bool)
        or isinstance(hard_stop, bool)
        or not isinstance(elapsed, int)
        or not isinstance(hard_stop, int)
        or elapsed < 0
        or hard_stop < 1
    ):
        raise ValueError("invalid_time_budget")
    revision = result["full_gate_revision"]
    if revision is not None and (not isinstance(revision, str) or not revision):
        raise ValueError("invalid_full_gate_revision")
    return result


def _parse_retry(value: object) -> dict[str, object]:
    mapping = _exact_fields(value, RETRY_FIELDS, "retry")
    result = dict(mapping)
    if not isinstance(result["same_operation"], bool):
        raise ValueError("invalid_retry_flag")
    for field in ("failed_action", "correction_fingerprint"):
        item = result[field]
        if item is not None and (not isinstance(item, str) or not item):
            raise ValueError(f"invalid_retry_field:{field}")
    if not result["same_operation"] and (
        result["failed_action"] is not None
        or result["correction_fingerprint"] is not None
    ):
        raise ValueError("retry_metadata_without_retry")
    return result


def _parse_evidence(value: object) -> list[dict[str, str]]:
    if not isinstance(value, list):
        raise ValueError("invalid_list:reused_evidence")
    result: list[dict[str, str]] = []
    for item in value:
        mapping = _exact_fields(item, EVIDENCE_FIELDS, "reused_evidence")
        normalized: dict[str, str] = {}
        for field in sorted(EVIDENCE_FIELDS):
            current = mapping[field]
            if not isinstance(current, str) or not current:
                raise ValueError(f"invalid_evidence_field:{field}")
            normalized[field] = current
        result.append(normalized)
    return sorted(result, key=_canonical_item)


def _parse_gate_dispositions(value: object) -> list[dict[str, str]]:
    if not isinstance(value, list):
        raise ValueError("invalid_list:gate_dispositions")
    result: list[dict[str, str]] = []
    for item in value:
        mapping = _exact_fields(item, GATE_DISPOSITION_FIELDS, "gate_disposition")
        normalized: dict[str, str] = {}
        for field in sorted(GATE_DISPOSITION_FIELDS):
            current = mapping[field]
            if not isinstance(current, str) or not current:
                raise ValueError(f"invalid_gate_disposition_field:{field}")
            normalized[field] = current
        if normalized["status"] not in {"not_required", "reused"}:
            raise ValueError("gate_disposition_status_invalid")
        result.append(normalized)
    gates = [item["gate"] for item in result]
    if len(gates) != len(set(gates)):
        raise ValueError("duplicate_gate_disposition")
    return sorted(result, key=_canonical_item)


def _validate_authorization(
    value: object,
    *,
    current: Mapping[str, str],
    pending_action: str,
    required_level: str,
    capability: str,
    evaluated_at: datetime,
) -> tuple[list[str], list[str]]:
    blockers: list[str] = []
    reasons: list[str] = []
    if value is None:
        return ["APPROVAL_EXPIRED"], ["approval_not_valid"]
    try:
        mapping = _exact_fields(value, AUTHORIZATION_FIELDS, "authorization")
        approved_fingerprints = _parse_fingerprints(
            mapping["fingerprints"], "authorization.fingerprints"
        )
        expiry = _parse_utc(mapping["expires_at"], "authorization.expires_at")
    except ValueError as exc:
        return ["APPROVAL_EXPIRED"], [str(exc)]

    status = mapping["status"]
    approval_level = mapping["approval_level"]
    approved_capability = mapping["capability"]
    consumed = mapping["consumed"]
    superseded = mapping["superseded"]
    if not isinstance(status, str) or status != "valid":
        reasons.append("approval_not_valid")
    if not isinstance(consumed, bool) or consumed:
        reasons.append("approval_consumed")
    if not isinstance(superseded, bool) or superseded:
        reasons.append("approval_superseded")
    if evaluated_at >= expiry:
        reasons.append("approval_expired")
    if not isinstance(approval_level, str) or not approval_satisfies(
        approval_level, required_level
    ):
        reasons.append("approval_level_insufficient")
    if approval_level != pending_action or approval_level != required_level:
        reasons.append("approval_action_mismatch")
    if approved_capability != capability or capability != CAPABILITY_FOR_ACTION[pending_action]:
        reasons.append("capability_mismatch")

    for field in sorted(FINGERPRINT_FIELDS):
        if approved_fingerprints[field] != current[field]:
            reasons.append(f"approval_drift:{field}")
    if reasons:
        blockers.append("APPROVAL_EXPIRED")
    return blockers, reasons


def _validate_gate_accounting(
    *,
    state_from: str,
    state_to: str,
    current: Mapping[str, str],
    evidence: Sequence[dict[str, str]],
    dispositions: Sequence[dict[str, str]],
) -> tuple[list[str], list[str], tuple[dict[str, str], ...]]:
    required = SKIPPED_GATES.get((state_from, state_to), ())
    if not required:
        if dispositions:
            return ["SCOPE_DRIFT"], ["unexpected_gate_disposition"], ()
        return [], [], ()
    by_gate = {item["gate"]: item for item in dispositions}
    if set(by_gate) - set(required):
        return ["SCOPE_DRIFT"], ["unexpected_gate_disposition"], ()

    blockers: list[str] = []
    reasons: list[str] = []
    accepted: list[dict[str, str]] = []
    for gate in required:
        disposition = by_gate.get(gate)
        if disposition is None:
            blockers.append("SCOPE_DRIFT")
            reasons.append(f"optional_gate_not_accounted:{gate}")
            continue
        if disposition["status"] == "not_required":
            continue
        matches = [item for item in evidence if item["gate"] == gate]
        exact = [
            item
            for item in matches
            if item["status"] == "PASS"
            and item["source_fingerprint"] == current["source"]
            and item["contract_fingerprint"] == current["contract"]
        ]
        if len(exact) != 1 or len(matches) != 1:
            blockers.append("PROVENANCE_MISMATCH")
            reasons.append(f"reused_evidence_mismatch:{gate}")
        else:
            accepted.append(exact[0])
    return blockers, reasons, tuple(sorted(accepted, key=_canonical_item))


def _budget_admission(
    *,
    action: str,
    budget: Mapping[str, object],
    retry: Mapping[str, object],
    current: Mapping[str, str],
) -> tuple[list[str], list[str], dict[str, int]]:
    blockers: list[str] = []
    reasons: list[str] = []
    delta: dict[str, int] = {}
    if int(budget["elapsed_seconds"]) >= int(budget["hard_stop_seconds"]):
        return ["TIME_BUDGET_EXHAUSTED"], ["hard_stop_reached"], {}

    if retry["same_operation"]:
        if action != "CORRECTION":
            return ["SCOPE_DRIFT"], ["same_operation_retry_requires_correction"], {}
        if retry["correction_fingerprint"] != current["action"]:
            return ["PROVENANCE_MISMATCH"], ["correction_fingerprint_mismatch"], {}
        failed_action = retry["failed_action"]
        if failed_action not in ACTION_TYPES:
            return ["SCOPE_DRIFT"], ["failed_action_invalid"], {}

    counter = BUDGET_COUNTER_FOR_ACTION[action]
    counters = [counter]
    if retry["same_operation"]:
        counters.append("same_operation_retry")
    for item in counters:
        used = int(budget[f"{item}_used"])
        maximum = int(budget[f"{item}_max"])
        if used >= maximum:
            blockers.append("RETRY_BUDGET_EXHAUSTED")
            reasons.append(f"budget_exhausted:{item}")
        else:
            delta[f"{item}_used"] = 1

    if (
        action == "FULL_VALIDATION"
        and int(budget["full_gate_used"]) > 0
        and budget["full_gate_revision"] == current["source"]
    ):
        blockers.append("RETRY_BUDGET_EXHAUSTED")
        reasons.append("full_gate_revision_reuse_required")
    if blockers:
        return blockers, reasons, {}
    return [], [], dict(sorted(delta.items()))


def evaluate_policy(value: Mapping[str, object]) -> PolicyDecision:
    """Evaluate one strict in-memory request without mutating it or doing I/O."""

    if not isinstance(value, Mapping):
        return _deny(
            state_from="UNKNOWN",
            required_approval_level=None,
            blockers=["SCOPE_DRIFT"],
            reasons=["policy_input_must_be_object"],
        )

    state_from_value = value.get("state_from")
    state_from = state_from_value if isinstance(state_from_value, str) else "UNKNOWN"
    required_value = value.get("required_approval_level")
    required = required_value if isinstance(required_value, str) else None
    try:
        request = _exact_fields(value, TOP_LEVEL_FIELDS, "policy_input")
    except ValueError as exc:
        return _deny(
            state_from=state_from,
            required_approval_level=required,
            blockers=["SCOPE_DRIFT"],
            reasons=[str(exc)],
        )

    try:
        if request["schema_version"] != 1:
            raise ValueError("schema_version_must_be_1")
        evaluated_at = _parse_utc(request["evaluated_at"], "evaluated_at")
        source_state = parse_state(request["state_from"])
        target_state = parse_state(request["state_to"])
    except (ValueError, TypeError) as exc:
        reason = str(exc)
        blocker = "STATE_DRIFT" if "state" in reason else "SCOPE_DRIFT"
        return _deny(
            state_from=state_from,
            required_approval_level=required,
            blockers=[blocker],
            reasons=[reason],
        )

    action = request["pending_action"]
    required_level = request["required_approval_level"]
    resume_state = request["resume_state"]
    expected_success_state = request["expected_success_state"]
    capability = request["capability"]
    scalar_fields = {
        "pending_action": action,
        "required_approval_level": required_level,
        "resume_state": resume_state,
        "expected_success_state": expected_success_state,
        "capability": capability,
    }
    invalid_scalars = [
        field
        for field, item in scalar_fields.items()
        if not isinstance(item, str) or not item
    ]
    if invalid_scalars:
        return _deny(
            state_from=source_state.value,
            required_approval_level=required,
            blockers=["SCOPE_DRIFT"],
            reasons=[f"invalid_string:{field}" for field in invalid_scalars],
        )
    assert isinstance(action, str)
    assert isinstance(required_level, str)
    assert isinstance(resume_state, str)
    assert isinstance(expected_success_state, str)
    assert isinstance(capability, str)

    semantic_reasons: list[str] = []
    if action not in ACTION_TYPES:
        semantic_reasons.append("pending_action_unknown")
    if required_level not in APPROVAL_ORDER:
        semantic_reasons.append("approval_level_unknown")
    if action in ACTION_TYPES and required_level != action:
        semantic_reasons.append("required_approval_level_mismatch")
    if capability not in {"Code", "Device", "Publish"}:
        semantic_reasons.append("capability_unknown")
    if action in ACTION_TYPES and capability != CAPABILITY_FOR_ACTION[action]:
        semantic_reasons.append("action_capability_mismatch")
    if action in ACTION_TYPES and expected_success_state != SUCCESS_STATE_FOR_ACTION[action]:
        semantic_reasons.append("expected_success_state_mismatch")
    if action in ACTION_TYPES and resume_state != RESUME_STATE_FOR_ACTION[action]:
        semantic_reasons.append("resume_state_mismatch")
    if semantic_reasons:
        return _deny(
            state_from=source_state.value,
            required_approval_level=required_level,
            blockers=["SCOPE_DRIFT"],
            reasons=semantic_reasons,
        )

    try:
        current = _parse_fingerprints(
            request["current_fingerprints"], "current_fingerprints"
        )
        parsed_budget = _parse_budget(request["budget"])
        retry = _parse_retry(request["retry"])
        evidence = _parse_evidence(request["reused_evidence"])
        dispositions = _parse_gate_dispositions(request["gate_dispositions"])
    except ValueError as exc:
        return _deny(
            state_from=source_state.value,
            required_approval_level=required_level,
            blockers=["SCOPE_DRIFT"],
            reasons=[str(exc)],
        )
    if current["capability"] != capability:
        return _deny(
            state_from=source_state.value,
            required_approval_level=required_level,
            blockers=["SCOPE_DRIFT"],
            reasons=["current_capability_fingerprint_mismatch"],
        )

    raw_blockers = request["blockers"]
    if not isinstance(raw_blockers, list) or not all(
        isinstance(item, str) for item in raw_blockers
    ):
        return _deny(
            state_from=source_state.value,
            required_approval_level=required_level,
            blockers=["SCOPE_DRIFT"],
            reasons=["blockers_must_be_string_list"],
        )
    unknown_blockers = sorted(set(raw_blockers) - set(BLOCKER_PRECEDENCE))
    if unknown_blockers:
        return _deny(
            state_from=source_state.value,
            required_approval_level=required_level,
            blockers=["SCOPE_DRIFT"],
            reasons=[f"unknown_blocker:{item}" for item in unknown_blockers],
        )
    if raw_blockers:
        return _deny(
            state_from=source_state.value,
            required_approval_level=required_level,
            blockers=raw_blockers,
            reasons=[f"input_blocker:{item}" for item in raw_blockers],
        )

    if not can_transition(source_state, target_state):
        return _deny(
            state_from=source_state.value,
            required_approval_level=required_level,
            blockers=["STATE_DRIFT"],
            reasons=[
                f"transition_not_allowed:{source_state.value}->{target_state.value}"
            ],
        )

    if target_state is State.AWAITING_APPROVAL:
        expected_actions = AWAITING_ACTIONS_FOR_STATE.get(source_state.value, frozenset())
        if action not in expected_actions:
            return _deny(
                state_from=source_state.value,
                required_approval_level=required_level,
                blockers=["STATE_DRIFT"],
                reasons=["awaiting_action_does_not_match_resume_state"],
            )
        return PolicyDecision(
            allowed=False,
            state_from=source_state.value,
            state_to=State.AWAITING_APPROVAL.value,
            required_approval_level=required_level,
            blockers=(),
            budget_delta={},
            reused_evidence=(),
            reasons=("approval_required",),
        )

    gate_blockers, gate_reasons, accepted_evidence = _validate_gate_accounting(
        state_from=source_state.value,
        state_to=target_state.value,
        current=current,
        evidence=evidence,
        dispositions=dispositions,
    )
    if gate_blockers:
        return _deny(
            state_from=source_state.value,
            required_approval_level=required_level,
            blockers=gate_blockers,
            reasons=gate_reasons,
        )

    authorization_states = {
        State.AWAITING_APPROVAL,
        State.CODEX_AUTHORIZED,
        State.ACTION_AUTHORIZED,
    }
    if source_state in authorization_states:
        expected_authorized_state = (
            State.CODEX_AUTHORIZED if action in CODE_ACTIONS else State.ACTION_AUTHORIZED
        )
        if source_state is State.AWAITING_APPROVAL and target_state is not expected_authorized_state:
            return _deny(
                state_from=source_state.value,
                required_approval_level=required_level,
                blockers=["STATE_DRIFT"],
                reasons=["authorized_state_mismatch"],
            )
        if source_state is State.CODEX_AUTHORIZED and action not in CODE_ACTIONS:
            return _deny(
                state_from=source_state.value,
                required_approval_level=required_level,
                blockers=["STATE_DRIFT"],
                reasons=["codex_authorized_action_mismatch"],
            )
        if source_state is State.ACTION_AUTHORIZED and action not in GENERIC_ACTIONS:
            return _deny(
                state_from=source_state.value,
                required_approval_level=required_level,
                blockers=["STATE_DRIFT"],
                reasons=["generic_authorized_action_mismatch"],
            )
        auth_blockers, auth_reasons = _validate_authorization(
            request["authorization"],
            current=current,
            pending_action=action,
            required_level=required_level,
            capability=capability,
            evaluated_at=evaluated_at,
        )
        if auth_blockers:
            return _deny(
                state_from=source_state.value,
                required_approval_level=required_level,
                blockers=auth_blockers,
                reasons=auth_reasons,
                state_to=(
                    State.AWAITING_APPROVAL.value
                    if source_state is State.AWAITING_APPROVAL
                    else State.BLOCKED.value
                ),
            )

    budget_delta: dict[str, int] = {}
    invocation_transition = (
        (source_state is State.CODEX_AUTHORIZED and target_state is State.CODEX_RUNNING)
        or (
            source_state is State.ACTION_AUTHORIZED
            and target_state is State.ACTION_RUNNING
        )
    )
    if invocation_transition:
        budget_blockers, budget_reasons, budget_delta = _budget_admission(
            action=action,
            budget=parsed_budget,
            retry=retry,
            current=current,
        )
        if budget_blockers:
            return _deny(
                state_from=source_state.value,
                required_approval_level=required_level,
                blockers=budget_blockers,
                reasons=budget_reasons,
            )

    if source_state is State.DETERMINISTIC_VALIDATION and target_state not in {
        State.FAILED,
        State.BLOCKED,
    }:
        if target_state.value != SUCCESS_STATE_FOR_ACTION[action]:
            return _deny(
                state_from=source_state.value,
                required_approval_level=required_level,
                blockers=["STATE_DRIFT"],
                reasons=["result_state_does_not_match_pending_action"],
            )

    return PolicyDecision(
        allowed=True,
        state_from=source_state.value,
        state_to=target_state.value,
        required_approval_level=required_level,
        blockers=(),
        budget_delta=budget_delta,
        reused_evidence=accepted_evidence,
        reasons=(),
    )
