from __future__ import annotations

import builtins
import copy
import json
import socket
import subprocess
from pathlib import Path

import pytest

from tools.cse_orchestrator import replay


FIXTURE_PATH = (
    Path(__file__).parent
    / "fixtures"
    / "cse_orchestrator"
    / "issue_284_replay.json"
)


def fixture() -> dict[str, object]:
    return json.loads(FIXTURE_PATH.read_text(encoding="utf-8"))


def append_event(value: dict[str, object], event: dict[str, object]) -> None:
    events = value["events"]
    assert isinstance(events, list)
    events.append(event)
    value["comment_count"] = int(value["comment_count"]) + 1


def test_fixture_is_exact_19_comment_sanitized_source() -> None:
    value = fixture()
    events = value["events"]

    assert value["schema_version"] == 1
    assert value["issue_number"] == 284
    assert value["comment_count"] == 19
    assert isinstance(events, list)
    assert [event["comment_id"] for event in events] == [
        5140760422,
        5140885406,
        5140911905,
        5141050407,
        5141065966,
        5141106220,
        5141118552,
        5141165644,
        5145200821,
        5145300880,
        5145407628,
        5145525014,
        5145606224,
        5145678941,
        5146083446,
        5146161593,
        5146716927,
        5146838458,
        5147042969,
    ]
    assert value["device_target"] == "tablet_primary"


def test_replay_produces_expected_open_checkpoint_summary() -> None:
    summary = replay.replay_issue_284(fixture())

    assert summary.public_dict() == {
        "schema_version": 1,
        "issue_number": 284,
        "unique_event_count": 19,
        "authorization_count": 15,
        "ordinary_result_count": 4,
        "latest_valid_authorization_comment_id": 5147042969,
        "latest_scope_version": 15,
        "checkpoint_commit": "b0e9cf247afa6bac5d38684dbc626a11fdf45663",
        "checkpoint_tree": "4e3ccd1e37b050588f135138ceb69105c74c5059",
        "checkpoint_verified": True,
        "budget_authorized": {
            "build": 1,
            "checkpoint_commit": 1,
            "correction": 6,
            "device": 4,
            "full_validation": 1,
            "install": 1,
            "primary": 1,
            "publish": 0,
            "retry": 7,
        },
        "invocation_count": 3,
        "result_classes": ["source", "harness", "timeout", "test"],
        "reused_evidence_ids": [
            "evidence:core-tablet-smoke-v1",
            "evidence:full-357-v1",
            "evidence:lifecycle-55-v1",
            "evidence:source-validation-v1",
        ],
        "unauthorized_action_count": 0,
        "final_state": "ACTION_AUTHORIZED",
        "final_blocker": "DEVICE_ACCEPTANCE_PENDING",
        "next_gate": "DEVICE",
        "issue_completed": False,
        "checkpoint_frozen": True,
        "remote_published": False,
        "reasons": ["device_acceptance_pending", "issue_remains_open"],
    }


def test_unknown_or_missing_fixture_and_event_fields_fail_closed() -> None:
    unknown = fixture()
    unknown["raw_body"] = "not allowed"
    missing = fixture()
    missing.pop("source_base")
    unknown_event = fixture()
    unknown_event["events"][0]["surprise"] = True  # type: ignore[index]
    missing_event = fixture()
    missing_event["events"][0].pop("scope_version")  # type: ignore[index]

    for value, reason in (
        (unknown, "unknown_fields:fixture"),
        (missing, "missing_fields:fixture"),
        (unknown_event, "unknown_fields:event"),
        (missing_event, "missing_fields:event"),
    ):
        with pytest.raises(replay.ReplayInputError, match=reason):
            replay.replay_issue_284(value)


def test_sequence_must_be_strictly_monotonic() -> None:
    value = fixture()
    value["events"][7]["sequence"] = 6  # type: ignore[index]

    with pytest.raises(replay.ReplayInputError, match="sequence_not_increasing"):
        replay.replay_issue_284(value)


def test_exact_duplicate_event_is_idempotent_but_conflict_is_rejected() -> None:
    value = fixture()
    duplicate = copy.deepcopy(value["events"][5])  # type: ignore[index]
    append_event(value, duplicate)

    assert replay.replay_issue_284(value).unique_event_count == 19

    conflict = fixture()
    changed = copy.deepcopy(conflict["events"][5])  # type: ignore[index]
    changed["blocker"] = "TEST_FAILURE"
    append_event(conflict, changed)
    with pytest.raises(replay.ReplayInputError, match="event_id_collision"):
        replay.replay_issue_284(conflict)


def test_latest_valid_authorization_requires_exact_supersession() -> None:
    value = fixture()
    event = copy.deepcopy(value["events"][-1])  # type: ignore[index]
    event.update(
        {
            "event_id": "issue284-comment-6000000001",
            "sequence": 20,
            "comment_id": 6000000001,
            "scope_version": 16,
            "supersedes_comment_id": 5146161593,
            "action_fingerprint": "scope-16-invalid-supersession",
        }
    )
    append_event(value, event)

    with pytest.raises(replay.ReplayInputError, match="supersession_mismatch"):
        replay.replay_issue_284(value)


@pytest.mark.parametrize("authority", ["task_result", ".cse_state"])
def test_lower_authority_newer_record_cannot_expand_github_authorization(
    authority: str,
) -> None:
    value = fixture()
    event = copy.deepcopy(value["events"][-1])  # type: ignore[index]
    event.update(
        {
            "event_id": f"issue284-lower-authority-{authority}",
            "sequence": 20,
            "comment_id": 6000000002,
            "source_authority": authority,
            "scope_version": 16,
            "supersedes_comment_id": 5147042969,
            "action_kind": "PUBLISH",
            "approval_level": "PUBLISH",
            "capability": "Publish",
            "action_fingerprint": "scope-16-lower-authority-publish",
            "budget_delta": {"publish": 1},
            "expected_state": "ACTION_AUTHORIZED",
            "next_gate": "PUBLISH",
        }
    )
    append_event(value, event)

    summary = replay.replay_issue_284(value)

    assert summary.latest_valid_authorization_comment_id == 5147042969
    assert summary.budget_authorized["publish"] == 0
    assert summary.unauthorized_action_count == 0


def test_budget_can_expand_only_on_github_authorization() -> None:
    value = fixture()
    value["events"][1]["budget_delta"] = {"retry": 1}  # type: ignore[index]

    with pytest.raises(replay.ReplayInputError, match="result_budget_delta_forbidden"):
        replay.replay_issue_284(value)

    unknown = fixture()
    unknown["events"][2]["budget_delta"] = {"free_retry": 1}  # type: ignore[index]
    with pytest.raises(replay.ReplayInputError, match="unknown_budget_counter"):
        replay.replay_issue_284(unknown)


def test_same_authorization_cannot_start_a_blind_retry() -> None:
    value = fixture()
    event = copy.deepcopy(value["events"][7])  # type: ignore[index]
    event.update(
        {
            "event_id": "issue284-comment-6000000003",
            "sequence": 20,
            "comment_id": 6000000003,
            "blocker": "TEST_FAILURE",
        }
    )
    append_event(value, event)

    with pytest.raises(replay.ReplayInputError, match="blind_retry"):
        replay.replay_issue_284(value)


def test_unproven_action_start_does_not_consume_invocation_budget() -> None:
    value = fixture()
    summary = replay.replay_issue_284(value)

    timeout_event = value["events"][5]  # type: ignore[index]
    assert timeout_event["action_started"] is None
    assert timeout_event["result_class"] == "timeout"
    assert summary.invocation_count == 3


@pytest.mark.parametrize(
    ("event_index", "field", "replacement", "reason"),
    [
        (18, "source_fingerprint", "0" * 40, "source_fingerprint_drift"),
        (18, "branch_fingerprint", "codex/drift", "branch_fingerprint_drift"),
        (7, "action_fingerprint", "scope-drift", "action_fingerprint_drift"),
        (18, "capability", "Code", "capability_mismatch"),
    ],
)
def test_source_scope_action_and_capability_drift_fail_closed(
    event_index: int,
    field: str,
    replacement: str,
    reason: str,
) -> None:
    value = fixture()
    value["events"][event_index][field] = replacement  # type: ignore[index]

    with pytest.raises(replay.ReplayInputError, match=reason):
        replay.replay_issue_284(value)


def test_reused_evidence_requires_an_exact_prior_identity() -> None:
    value = fixture()
    value["events"][13]["reused_evidence_id"] = "evidence:unknown"  # type: ignore[index]

    with pytest.raises(replay.ReplayInputError, match="reused_evidence_drift"):
        replay.replay_issue_284(value)


@pytest.mark.parametrize("field", ["parent", "tree"])
def test_checkpoint_parent_and_tree_provenance_are_exact(field: str) -> None:
    value = fixture()
    value["checkpoint"][field] = "0" * 40  # type: ignore[index]

    with pytest.raises(replay.ReplayInputError, match="checkpoint_provenance_mismatch"):
        replay.replay_issue_284(value)


def test_build_and_device_have_exact_approval_and_publish_is_unauthorized() -> None:
    value = fixture()
    summary = replay.replay_issue_284(value)

    assert summary.budget_authorized["build"] == 1
    assert summary.budget_authorized["device"] == 4
    assert summary.budget_authorized["publish"] == 0
    assert summary.unauthorized_action_count == 0

    publish = fixture()
    event = copy.deepcopy(publish["events"][7])  # type: ignore[index]
    event.update(
        {
            "event_id": "issue284-comment-6000000004",
            "sequence": 20,
            "comment_id": 6000000004,
            "scope_version": 15,
            "authorization_comment_id": 5147042969,
            "action_kind": "PUBLISH",
            "action_fingerprint": "scope-15-device-continuation",
            "result_class": "unknown",
            "blocker": "PROVENANCE_MISMATCH",
            "next_gate": "PUBLISH",
        }
    )
    append_event(publish, event)
    with pytest.raises(replay.ReplayInputError, match="unauthorized_action"):
        replay.replay_issue_284(publish)


def test_final_replay_never_claims_issue_completion_or_publication() -> None:
    summary = replay.replay_issue_284(fixture())

    assert summary.issue_completed is False
    assert summary.remote_published is False
    assert summary.final_state != "COMPLETED"
    assert summary.checkpoint_frozen is True
    assert summary.next_gate == "DEVICE"


def test_fixture_has_no_raw_or_forbidden_data_patterns() -> None:
    text = FIXTURE_PATH.read_text(encoding="utf-8")
    lowered = text.lower()

    assert '"body"' not in lowered
    assert '"stdout"' not in lowered
    assert '"stderr"' not in lowered
    assert "r52w90jfn1m" not in lowered
    assert "sm-x610" not in lowered
    assert "c:\\users\\" not in lowered
    assert "@" not in text
    assert "ghp_" not in lowered
    assert "sk-" not in lowered
    assert "logcat" not in lowered
    assert "uiautomator" not in lowered
    assert "backup" not in lowered
    assert "tablet_primary" in text


def test_input_is_immutable_and_canonical_summary_is_byte_stable() -> None:
    value = fixture()
    original = copy.deepcopy(value)

    first = replay.replay_issue_284(value)
    reordered = dict(reversed(list(value.items())))
    second = replay.replay_issue_284(reordered)
    first_json = replay.canonical_replay_json(first)
    second_json = replay.canonical_replay_json(second)

    assert value == original
    assert first_json == second_json
    assert first_json == json.dumps(
        json.loads(first_json),
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    )


def test_replay_has_no_subprocess_network_or_filesystem_access(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    value = fixture()

    def forbidden(*args: object, **kwargs: object) -> object:
        raise AssertionError("external I/O is forbidden")

    monkeypatch.setattr(subprocess, "run", forbidden)
    monkeypatch.setattr(socket, "socket", forbidden)
    monkeypatch.setattr(builtins, "open", forbidden)

    summary = replay.replay_issue_284(value)

    assert summary.unique_event_count == 19
