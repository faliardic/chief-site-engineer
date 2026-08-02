from __future__ import annotations

import builtins
import copy
import json
import socket
import subprocess
from dataclasses import replace

import pytest

from tools.cse_orchestrator import policy, state


NOW = "2026-08-02T12:00:00Z"
SOURCE = "sha256:" + "1" * 64
CONTRACT = "sha256:" + "2" * 64
SCOPE = "sha256:" + "3" * 64
ACTION = "sha256:" + "4" * 64
BUDGET = "sha256:" + "5" * 64


def fingerprints(**overrides: str) -> dict[str, str]:
    value = {
        "source": SOURCE,
        "contract": CONTRACT,
        "scope": SCOPE,
        "action": ACTION,
        "capability": "Code",
        "budget": BUDGET,
    }
    value.update(overrides)
    return value


def budget(**overrides: object) -> dict[str, object]:
    value: dict[str, object] = {
        "primary_used": 0,
        "primary_max": 1,
        "correction_used": 0,
        "correction_max": 1,
        "same_operation_retry_used": 0,
        "same_operation_retry_max": 1,
        "full_gate_used": 0,
        "full_gate_max": 1,
        "checkpoint_commit_used": 0,
        "checkpoint_commit_max": 1,
        "build_used": 0,
        "build_max": 1,
        "device_used": 0,
        "device_max": 1,
        "publish_used": 0,
        "publish_max": 1,
        "elapsed_seconds": 0,
        "hard_stop_seconds": 3600,
        "full_gate_revision": None,
    }
    value.update(overrides)
    return value


def authorization(
    approval_level: str = "CODE_CHANGE",
    capability: str = "Code",
    **overrides: object,
) -> dict[str, object]:
    value: dict[str, object] = {
        "status": "valid",
        "approval_level": approval_level,
        "capability": capability,
        "expires_at": "2026-08-09T21:00:00Z",
        "consumed": False,
        "superseded": False,
        "fingerprints": fingerprints(capability=capability),
    }
    value.update(overrides)
    return value


def request(**overrides: object) -> dict[str, object]:
    value: dict[str, object] = {
        "schema_version": 1,
        "evaluated_at": NOW,
        "state_from": "SCOPE_VALIDATED",
        "state_to": "AWAITING_APPROVAL",
        "pending_action": "CODE_CHANGE",
        "required_approval_level": "CODE_CHANGE",
        "resume_state": "SCOPE_VALIDATED",
        "expected_success_state": "FOCUSED_PASS",
        "capability": "Code",
        "authorization": None,
        "current_fingerprints": fingerprints(),
        "budget": budget(),
        "retry": {
            "same_operation": False,
            "failed_action": None,
            "correction_fingerprint": None,
        },
        "blockers": [],
        "reused_evidence": [],
        "gate_dispositions": [],
    }
    value.update(overrides)
    return value


def authorized_request(
    action: str,
    state_from: str,
    state_to: str,
    expected_success_state: str,
    capability: str = "Code",
    **overrides: object,
) -> dict[str, object]:
    resume_state = {
        "CODE_CHANGE": "SCOPE_VALIDATED",
        "CORRECTION": "SCOPE_VALIDATED",
        "FULL_VALIDATION": "FOCUSED_PASS",
        "CHECKPOINT_COMMIT": "SOURCE_VALIDATED",
        "BUILD": "CHECKPOINT_COMMITTED",
        "DEVICE": "ARTIFACT_BUILT",
        "PUBLISH": "PUBLISH_READY",
    }[action]
    value = request(
        state_from=state_from,
        state_to=state_to,
        pending_action=action,
        required_approval_level=action,
        resume_state=resume_state,
        expected_success_state=expected_success_state,
        capability=capability,
        current_fingerprints=fingerprints(capability=capability),
        authorization=authorization(action, capability),
    )
    value.update(overrides)
    return value


def test_transition_table_contains_every_documented_transition() -> None:
    expected = {
        ("IDLE", "OBSERVING"),
        ("OBSERVING", "SCOPE_VALIDATED"),
        ("OBSERVING", "PREFLIGHT_BLOCKED"),
        ("SCOPE_VALIDATED", "AWAITING_APPROVAL"),
        ("AWAITING_APPROVAL", "CODEX_AUTHORIZED"),
        ("AWAITING_APPROVAL", "ACTION_AUTHORIZED"),
        ("CODEX_AUTHORIZED", "CODEX_RUNNING"),
        ("ACTION_AUTHORIZED", "ACTION_RUNNING"),
        ("CODEX_RUNNING", "RESULT_RECEIVED"),
        ("ACTION_RUNNING", "RESULT_RECEIVED"),
        ("RESULT_RECEIVED", "DETERMINISTIC_VALIDATION"),
        ("DETERMINISTIC_VALIDATION", "FOCUSED_PASS"),
        ("DETERMINISTIC_VALIDATION", "FULL_PASS"),
        ("DETERMINISTIC_VALIDATION", "CHECKPOINT_COMMITTED"),
        ("DETERMINISTIC_VALIDATION", "ARTIFACT_BUILT"),
        ("DETERMINISTIC_VALIDATION", "DEVICE_ACCEPTANCE"),
        ("DETERMINISTIC_VALIDATION", "COMPLETED"),
        ("DETERMINISTIC_VALIDATION", "FAILED"),
        ("DETERMINISTIC_VALIDATION", "BLOCKED"),
        ("FOCUSED_PASS", "AWAITING_APPROVAL"),
        ("FOCUSED_PASS", "SOURCE_VALIDATED"),
        ("FULL_PASS", "SOURCE_VALIDATED"),
        ("SOURCE_VALIDATED", "AWAITING_APPROVAL"),
        ("CHECKPOINT_COMMITTED", "AWAITING_APPROVAL"),
        ("CHECKPOINT_COMMITTED", "PUBLISH_READY"),
        ("ARTIFACT_BUILT", "AWAITING_APPROVAL"),
        ("ARTIFACT_BUILT", "PUBLISH_READY"),
        ("DEVICE_ACCEPTANCE", "PUBLISH_READY"),
        ("PUBLISH_READY", "AWAITING_APPROVAL"),
        ("PUBLISH_READY", "COMPLETED"),
    }
    actual = {
        (source.value, target.value)
        for source, targets in state.ALLOWED_TRANSITIONS.items()
        for target in targets
        if target is not state.State.CANCELLED
    }

    assert actual == expected


def test_every_non_terminal_state_can_cancel_and_terminal_states_cannot_leave() -> None:
    for source in state.State:
        if source in state.TERMINAL_STATES:
            assert state.ALLOWED_TRANSITIONS[source] == frozenset()
        else:
            assert state.State.CANCELLED in state.ALLOWED_TRANSITIONS[source]


def test_transition_lookup_rejects_unknown_and_forbidden_values() -> None:
    assert state.can_transition("SCOPE_VALIDATED", "AWAITING_APPROVAL") is True
    assert state.can_transition("ACTION_AUTHORIZED", "FULL_PASS") is False
    assert state.can_transition("UNKNOWN", "BLOCKED") is False


def test_append_only_projection_is_replay_idempotent() -> None:
    first = state.create_transition_event(
        run_id="run-001",
        sequence=1,
        state_from="IDLE",
        state_to="OBSERVING",
        source_fingerprint=SOURCE,
    )
    second = state.create_transition_event(
        run_id="run-001",
        sequence=2,
        state_from="OBSERVING",
        state_to="SCOPE_VALIDATED",
        source_fingerprint=SOURCE,
    )

    assert state.project_events("IDLE", (first, second, first, second)) is state.State.SCOPE_VALIDATED


def test_append_only_projection_rejects_invalid_transition_and_event_id_collision() -> None:
    invalid = state.create_transition_event(
        run_id="run-001",
        sequence=1,
        state_from="IDLE",
        state_to="SCOPE_VALIDATED",
        source_fingerprint=SOURCE,
        validate_transition=False,
    )
    with pytest.raises(state.TransitionError, match="transition_not_allowed"):
        state.project_events("IDLE", (invalid,))

    valid = state.create_transition_event(
        run_id="run-002",
        sequence=1,
        state_from="IDLE",
        state_to="OBSERVING",
        source_fingerprint=SOURCE,
    )
    collision = replace(valid, state_to=state.State.CANCELLED)
    with pytest.raises(state.TransitionError, match="event_id_collision"):
        state.project_events("IDLE", (valid, collision))


def test_requesting_an_action_produces_explicit_awaiting_approval() -> None:
    decision = policy.evaluate_policy(request())

    assert decision.public_dict() == {
        "allowed": False,
        "state_from": "SCOPE_VALIDATED",
        "state_to": "AWAITING_APPROVAL",
        "required_approval_level": "CODE_CHANGE",
        "blockers": [],
        "budget_delta": {},
        "reused_evidence": [],
        "reasons": ["approval_required"],
    }


@pytest.mark.parametrize(
    ("action", "authorized_state"),
    [
        ("CODE_CHANGE", "CODEX_AUTHORIZED"),
        ("CORRECTION", "CODEX_AUTHORIZED"),
        ("FULL_VALIDATION", "ACTION_AUTHORIZED"),
        ("CHECKPOINT_COMMIT", "ACTION_AUTHORIZED"),
        ("BUILD", "ACTION_AUTHORIZED"),
        ("DEVICE", "ACTION_AUTHORIZED"),
        ("PUBLISH", "ACTION_AUTHORIZED"),
    ],
)
def test_approval_routes_only_to_the_correct_authorized_state(
    action: str,
    authorized_state: str,
) -> None:
    capability = policy.CAPABILITY_FOR_ACTION[action]
    value = authorized_request(
        action,
        "AWAITING_APPROVAL",
        authorized_state,
        policy.SUCCESS_STATE_FOR_ACTION[action],
        capability,
    )

    assert policy.evaluate_policy(value).allowed is True


def test_action_authorized_never_transitions_directly_to_success() -> None:
    value = authorized_request(
        "FULL_VALIDATION",
        "ACTION_AUTHORIZED",
        "FULL_PASS",
        "FULL_PASS",
    )

    decision = policy.evaluate_policy(value)

    assert decision.allowed is False
    assert decision.blockers == ("STATE_DRIFT",)


@pytest.mark.parametrize(
    ("action", "success"),
    [
        ("CODE_CHANGE", "FOCUSED_PASS"),
        ("CORRECTION", "FOCUSED_PASS"),
        ("FULL_VALIDATION", "FULL_PASS"),
        ("CHECKPOINT_COMMIT", "CHECKPOINT_COMMITTED"),
        ("BUILD", "ARTIFACT_BUILT"),
        ("DEVICE", "DEVICE_ACCEPTANCE"),
        ("PUBLISH", "COMPLETED"),
    ],
)
def test_result_validation_selects_only_the_action_success_state(
    action: str,
    success: str,
) -> None:
    capability = policy.CAPABILITY_FOR_ACTION[action]
    value = authorized_request(
        action,
        "DETERMINISTIC_VALIDATION",
        success,
        success,
        capability,
        authorization=None,
    )

    assert policy.evaluate_policy(value).allowed is True


def test_unknown_field_state_action_capability_and_budget_fail_closed() -> None:
    cases = []
    unknown_field = request()
    unknown_field["surprise"] = True
    cases.append((unknown_field, "SCOPE_DRIFT"))
    cases.append((request(state_from="UNKNOWN"), "STATE_DRIFT"))
    cases.append((request(pending_action="UNKNOWN"), "SCOPE_DRIFT"))
    cases.append((request(capability="Unknown"), "SCOPE_DRIFT"))
    unknown_budget = budget()
    unknown_budget["free_retries"] = 99
    cases.append((request(budget=unknown_budget), "SCOPE_DRIFT"))

    for value, blocker in cases:
        decision = policy.evaluate_policy(value)
        assert decision.allowed is False
        assert blocker in decision.blockers


def test_approval_level_ordering_is_explicit_but_admission_remains_action_bound() -> None:
    assert policy.approval_satisfies("RELEASE", "SAFE_READ") is True
    assert policy.approval_satisfies("SAFE_READ", "CODE_CHANGE") is False

    value = authorized_request(
        "CODE_CHANGE",
        "AWAITING_APPROVAL",
        "CODEX_AUTHORIZED",
        "FOCUSED_PASS",
    )
    value["authorization"] = authorization("RELEASE", "Publish")
    decision = policy.evaluate_policy(value)
    assert decision.allowed is False
    assert "APPROVAL_EXPIRED" in decision.blockers


def test_capability_mismatch_fails_closed() -> None:
    value = authorized_request(
        "DEVICE",
        "AWAITING_APPROVAL",
        "ACTION_AUTHORIZED",
        "DEVICE_ACCEPTANCE",
        "Device",
    )
    value["authorization"] = authorization("DEVICE", "Code")

    decision = policy.evaluate_policy(value)

    assert decision.allowed is False
    assert decision.blockers == ("APPROVAL_EXPIRED",)
    assert "capability_mismatch" in decision.reasons


@pytest.mark.parametrize(
    ("updates", "reason"),
    [
        ({"expires_at": "2026-08-02T11:59:59Z"}, "approval_expired"),
        ({"superseded": True}, "approval_superseded"),
        ({"consumed": True}, "approval_consumed"),
        ({"status": "missing"}, "approval_not_valid"),
    ],
)
def test_expired_superseded_consumed_or_missing_authorization_is_denied(
    updates: dict[str, object],
    reason: str,
) -> None:
    value = authorized_request(
        "CODE_CHANGE",
        "AWAITING_APPROVAL",
        "CODEX_AUTHORIZED",
        "FOCUSED_PASS",
    )
    value["authorization"] = authorization(**updates)

    decision = policy.evaluate_policy(value)

    assert decision.allowed is False
    assert "APPROVAL_EXPIRED" in decision.blockers
    assert reason in decision.reasons


@pytest.mark.parametrize("field", ["source", "scope", "action", "capability", "budget"])
def test_approval_fingerprint_drift_is_denied(field: str) -> None:
    approved = fingerprints()
    approved[field] = "drifted"
    value = authorized_request(
        "CODE_CHANGE",
        "AWAITING_APPROVAL",
        "CODEX_AUTHORIZED",
        "FOCUSED_PASS",
    )
    value["authorization"] = authorization(fingerprints=approved)

    decision = policy.evaluate_policy(value)

    assert decision.allowed is False
    assert decision.blockers == ("APPROVAL_EXPIRED",)
    assert f"approval_drift:{field}" in decision.reasons


def test_budget_is_admitted_before_invocation_and_delta_is_deterministic() -> None:
    value = authorized_request(
        "CODE_CHANGE",
        "CODEX_AUTHORIZED",
        "CODEX_RUNNING",
        "FOCUSED_PASS",
    )

    decision = policy.evaluate_policy(value)

    assert decision.allowed is True
    assert decision.budget_delta == {"primary_used": 1}


@pytest.mark.parametrize(
    ("action", "used_field", "max_field", "capability"),
    [
        ("FULL_VALIDATION", "full_gate_used", "full_gate_max", "Code"),
        ("CHECKPOINT_COMMIT", "checkpoint_commit_used", "checkpoint_commit_max", "Code"),
        ("BUILD", "build_used", "build_max", "Code"),
        ("DEVICE", "device_used", "device_max", "Device"),
        ("PUBLISH", "publish_used", "publish_max", "Publish"),
    ],
)
def test_every_generic_action_has_a_pre_invocation_budget(
    action: str,
    used_field: str,
    max_field: str,
    capability: str,
) -> None:
    value = authorized_request(
        action,
        "ACTION_AUTHORIZED",
        "ACTION_RUNNING",
        policy.SUCCESS_STATE_FOR_ACTION[action],
        capability,
    )

    decision = policy.evaluate_policy(value)

    assert decision.allowed is True
    assert decision.budget_delta == {used_field: 1}
    exhausted = budget(**{used_field: 1, max_field: 1})
    value["budget"] = exhausted
    denied = policy.evaluate_policy(value)
    assert denied.allowed is False
    assert denied.blockers == ("RETRY_BUDGET_EXHAUSTED",)


def test_same_operation_retry_requires_exact_correction_and_two_budgets() -> None:
    value = authorized_request(
        "CORRECTION",
        "CODEX_AUTHORIZED",
        "CODEX_RUNNING",
        "FOCUSED_PASS",
        retry={
            "same_operation": True,
            "failed_action": "CODE_CHANGE",
            "correction_fingerprint": ACTION,
        },
    )

    decision = policy.evaluate_policy(value)

    assert decision.allowed is True
    assert decision.budget_delta == {
        "correction_used": 1,
        "same_operation_retry_used": 1,
    }

    invalid = copy.deepcopy(value)
    invalid["retry"]["correction_fingerprint"] = "drifted"  # type: ignore[index]
    denied = policy.evaluate_policy(invalid)
    assert denied.allowed is False
    assert "PROVENANCE_MISMATCH" in denied.blockers


def test_correction_and_retry_limits_fail_closed() -> None:
    value = authorized_request(
        "CORRECTION",
        "CODEX_AUTHORIZED",
        "CODEX_RUNNING",
        "FOCUSED_PASS",
        budget=budget(
            correction_used=1,
            correction_max=1,
            same_operation_retry_used=1,
            same_operation_retry_max=1,
        ),
        retry={
            "same_operation": True,
            "failed_action": "CODE_CHANGE",
            "correction_fingerprint": ACTION,
        },
    )

    decision = policy.evaluate_policy(value)

    assert decision.allowed is False
    assert decision.blockers == ("RETRY_BUDGET_EXHAUSTED",)


def test_hard_stop_precedes_action_admission() -> None:
    value = authorized_request(
        "CODE_CHANGE",
        "CODEX_AUTHORIZED",
        "CODEX_RUNNING",
        "FOCUSED_PASS",
        budget=budget(elapsed_seconds=3600, hard_stop_seconds=3600),
    )

    decision = policy.evaluate_policy(value)

    assert decision.allowed is False
    assert decision.blockers == ("TIME_BUDGET_EXHAUSTED",)
    assert decision.budget_delta == {}


def test_full_gate_cannot_run_twice_on_the_same_source_revision() -> None:
    value = authorized_request(
        "FULL_VALIDATION",
        "ACTION_AUTHORIZED",
        "ACTION_RUNNING",
        "FULL_PASS",
        budget=budget(full_gate_used=1, full_gate_max=2, full_gate_revision=SOURCE),
    )

    decision = policy.evaluate_policy(value)

    assert decision.allowed is False
    assert decision.blockers == ("RETRY_BUDGET_EXHAUSTED",)
    assert "full_gate_revision_reuse_required" in decision.reasons


def test_optional_gate_must_be_not_required_or_exact_reused_evidence() -> None:
    silent = request(
        state_from="FOCUSED_PASS",
        state_to="SOURCE_VALIDATED",
        pending_action="FULL_VALIDATION",
        required_approval_level="FULL_VALIDATION",
        resume_state="FOCUSED_PASS",
        expected_success_state="FULL_PASS",
    )
    denied = policy.evaluate_policy(silent)
    assert denied.allowed is False
    assert denied.blockers == ("SCOPE_DRIFT",)
    assert "optional_gate_not_accounted:FULL_VALIDATION" in denied.reasons

    not_required = copy.deepcopy(silent)
    not_required["gate_dispositions"] = [
        {
            "gate": "FULL_VALIDATION",
            "status": "not_required",
            "reason": "validation class is focused only",
        }
    ]
    assert policy.evaluate_policy(not_required).allowed is True


def test_reused_evidence_requires_exact_source_and_contract_fingerprints() -> None:
    evidence = {
        "gate": "FULL_VALIDATION",
        "status": "PASS",
        "source_fingerprint": SOURCE,
        "contract_fingerprint": CONTRACT,
        "evidence_fingerprint": "sha256:" + "6" * 64,
    }
    value = request(
        state_from="FOCUSED_PASS",
        state_to="SOURCE_VALIDATED",
        pending_action="FULL_VALIDATION",
        required_approval_level="FULL_VALIDATION",
        resume_state="FOCUSED_PASS",
        expected_success_state="FULL_PASS",
        reused_evidence=[evidence],
        gate_dispositions=[
            {"gate": "FULL_VALIDATION", "status": "reused", "reason": "same source"}
        ],
    )

    decision = policy.evaluate_policy(value)

    assert decision.allowed is True
    assert decision.reused_evidence == (evidence,)

    drifted = copy.deepcopy(value)
    drifted["reused_evidence"][0]["source_fingerprint"] = "sha256:" + "7" * 64  # type: ignore[index]
    denied = policy.evaluate_policy(drifted)
    assert denied.allowed is False
    assert denied.blockers == ("PROVENANCE_MISMATCH",)


def test_blocker_precedence_is_stable_and_keeps_all_known_blockers() -> None:
    value = request(
        blockers=["STATE_DRIFT", "APPROVAL_EXPIRED", "USER_DATA_RISK"]
    )

    decision = policy.evaluate_policy(value)

    assert decision.allowed is False
    assert decision.state_to == "BLOCKED"
    assert decision.blockers == (
        "USER_DATA_RISK",
        "APPROVAL_EXPIRED",
        "STATE_DRIFT",
    )


def test_input_is_not_mutated() -> None:
    value = authorized_request(
        "CODE_CHANGE",
        "CODEX_AUTHORIZED",
        "CODEX_RUNNING",
        "FOCUSED_PASS",
    )
    original = copy.deepcopy(value)

    policy.evaluate_policy(value)

    assert value == original


def test_canonical_output_is_byte_stable_and_order_independent() -> None:
    first = request(blockers=["STATE_DRIFT", "USER_DATA_RISK"])
    second = copy.deepcopy(first)
    second["blockers"] = list(reversed(second["blockers"]))  # type: ignore[index]

    first_text = policy.canonical_decision_json(policy.evaluate_policy(first))
    second_text = policy.canonical_decision_json(policy.evaluate_policy(second))

    assert first_text == second_text
    assert json.loads(first_text)["allowed"] is False
    assert first_text == json.dumps(
        json.loads(first_text),
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    )


def test_policy_has_no_subprocess_network_or_filesystem_access(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    def forbidden(*args: object, **kwargs: object) -> object:
        raise AssertionError("external I/O is forbidden")

    monkeypatch.setattr(subprocess, "run", forbidden)
    monkeypatch.setattr(socket, "socket", forbidden)
    monkeypatch.setattr(builtins, "open", forbidden)

    decision = policy.evaluate_policy(request())

    assert decision.state_to == "AWAITING_APPROVAL"
