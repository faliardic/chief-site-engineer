"""Pure deterministic O4 replay for the sanitized Issue #284 event fixture.

The engine receives an already-loaded mapping. It performs no filesystem,
subprocess, network, GitHub, API, build, or device operation and never treats
the replay as authority to continue the historical run.
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass
from types import MappingProxyType
from typing import Any, Mapping, Sequence

from .authorization import CAPABILITIES
from .policy import APPROVAL_ORDER
from .state import State


ISSUE_284_BASE = "eb85f0a2ea0901f0074887fe999e74b6ab4aed0f"
ISSUE_284_BRANCH = "codex/issue-284-reminder-all-day-edit"
ISSUE_284_CHECKPOINT = "b0e9cf247afa6bac5d38684dbc626a11fdf45663"
ISSUE_284_CHECKPOINT_TREE = "4e3ccd1e37b050588f135138ceb69105c74c5059"
ISSUE_284_CHECKPOINT_SUBJECT = "Add reminder all-day editing"
SOURCE_PRECEDENCE = (
    "github_authorization",
    "task_result",
    ".cse_state",
)

FIXTURE_FIELDS = frozenset(
    {
        "schema_version",
        "issue_number",
        "source_state",
        "source_base",
        "source_branch",
        "device_target",
        "comment_count",
        "source_precedence",
        "checkpoint",
        "events",
        "expected_final",
    }
)
CHECKPOINT_FIELDS = frozenset(
    {
        "commit",
        "parent",
        "tree",
        "subject",
        "changed_file_count",
        "published",
    }
)
FINAL_FIELDS = frozenset(
    {
        "state",
        "blocker",
        "next_gate",
        "issue_completed",
        "checkpoint_frozen",
        "remote_published",
    }
)
EVENT_FIELDS = frozenset(
    {
        "event_id",
        "sequence",
        "comment_id",
        "event_kind",
        "source_authority",
        "scope_version",
        "supersedes_comment_id",
        "authorization_comment_id",
        "action_kind",
        "approval_level",
        "capability",
        "source_fingerprint",
        "branch_fingerprint",
        "checkpoint_fingerprint",
        "action_fingerprint",
        "allowlist",
        "budget_delta",
        "action_started",
        "result_class",
        "expected_state",
        "blocker",
        "next_gate",
        "reused_evidence_id",
    }
)

BUDGET_COUNTERS = (
    "build",
    "checkpoint_commit",
    "correction",
    "device",
    "full_validation",
    "install",
    "primary",
    "publish",
    "retry",
)
RESULT_CLASSES = frozenset(
    {
        "source",
        "test",
        "analyze",
        "build",
        "toolchain",
        "harness",
        "timeout",
        "provenance",
        "unknown",
    }
)
AUTHORIZATION_KINDS = frozenset({"authorization", "authorization_evidence"})
EVENT_KINDS = AUTHORIZATION_KINDS | {"result"}
SOURCE_AUTHORITIES = frozenset(SOURCE_PRECEDENCE)
SHA_PATTERN = re.compile(r"^[0-9a-f]{40}$")

ACTION_RULES: Mapping[str, tuple[str, str, str]] = {
    "CODE_CHANGE": ("CODE_CHANGE", "Code", "CODEX_AUTHORIZED"),
    "CORRECTION": ("CORRECTION", "Code", "CODEX_AUTHORIZED"),
    "FOCUSED_VALIDATION": ("CORRECTION", "Code", "ACTION_AUTHORIZED"),
    "FULL_VALIDATION": ("FULL_VALIDATION", "Code", "ACTION_AUTHORIZED"),
    "CHECKPOINT_COMMIT": ("CHECKPOINT_COMMIT", "Code", "ACTION_AUTHORIZED"),
    "BUILD_DEVICE": ("DEVICE", "Device", "ACTION_AUTHORIZED"),
    "DEVICE": ("DEVICE", "Device", "ACTION_AUTHORIZED"),
    "PUBLISH": ("PUBLISH", "Publish", "ACTION_AUTHORIZED"),
}


class ReplayInputError(ValueError):
    """The frozen replay cannot be trusted without weakening O0–O3."""


@dataclass(frozen=True)
class ReplaySummary:
    schema_version: int
    issue_number: int
    unique_event_count: int
    authorization_count: int
    ordinary_result_count: int
    latest_valid_authorization_comment_id: int
    latest_scope_version: int
    checkpoint_commit: str
    checkpoint_tree: str
    checkpoint_verified: bool
    budget_authorized: Mapping[str, int]
    invocation_count: int
    result_classes: tuple[str, ...]
    reused_evidence_ids: tuple[str, ...]
    unauthorized_action_count: int
    final_state: str
    final_blocker: str | None
    next_gate: str
    issue_completed: bool
    checkpoint_frozen: bool
    remote_published: bool
    reasons: tuple[str, ...]

    def public_dict(self) -> dict[str, object]:
        return {
            "schema_version": self.schema_version,
            "issue_number": self.issue_number,
            "unique_event_count": self.unique_event_count,
            "authorization_count": self.authorization_count,
            "ordinary_result_count": self.ordinary_result_count,
            "latest_valid_authorization_comment_id": (
                self.latest_valid_authorization_comment_id
            ),
            "latest_scope_version": self.latest_scope_version,
            "checkpoint_commit": self.checkpoint_commit,
            "checkpoint_tree": self.checkpoint_tree,
            "checkpoint_verified": self.checkpoint_verified,
            "budget_authorized": {
                field: self.budget_authorized[field] for field in BUDGET_COUNTERS
            },
            "invocation_count": self.invocation_count,
            "result_classes": list(self.result_classes),
            "reused_evidence_ids": list(self.reused_evidence_ids),
            "unauthorized_action_count": self.unauthorized_action_count,
            "final_state": self.final_state,
            "final_blocker": self.final_blocker,
            "next_gate": self.next_gate,
            "issue_completed": self.issue_completed,
            "checkpoint_frozen": self.checkpoint_frozen,
            "remote_published": self.remote_published,
            "reasons": list(self.reasons),
        }


def canonical_replay_json(summary: ReplaySummary) -> str:
    if not isinstance(summary, ReplaySummary):
        raise TypeError("replay_summary_required")
    return json.dumps(
        summary.public_dict(),
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    )


def _canonical_bytes(value: Mapping[str, object]) -> bytes:
    return json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")


def _exact_fields(
    value: object,
    expected: frozenset[str],
    label: str,
) -> Mapping[str, Any]:
    if not isinstance(value, Mapping):
        raise ReplayInputError(f"invalid_object:{label}")
    actual = set(value)
    missing = sorted(expected - actual)
    unknown = sorted(actual - expected)
    if missing:
        raise ReplayInputError(f"missing_fields:{label}:{','.join(missing)}")
    if unknown:
        raise ReplayInputError(f"unknown_fields:{label}:{','.join(unknown)}")
    return value


def _positive_int(value: object, field: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value < 1:
        raise ReplayInputError(f"invalid_positive_integer:{field}")
    return value


def _nullable_int(value: object, field: str) -> int | None:
    if value is None:
        return None
    return _positive_int(value, field)


def _required_string(value: object, field: str) -> str:
    if not isinstance(value, str) or not value:
        raise ReplayInputError(f"invalid_string:{field}")
    return value


def _nullable_string(value: object, field: str) -> str | None:
    if value is None:
        return None
    return _required_string(value, field)


def _sha(value: object, field: str) -> str:
    result = _required_string(value, field)
    if not SHA_PATTERN.fullmatch(result):
        raise ReplayInputError(f"invalid_sha:{field}")
    return result


def _string_list(value: object, field: str) -> tuple[str, ...]:
    if not isinstance(value, list):
        raise ReplayInputError(f"invalid_list:{field}")
    result: list[str] = []
    for item in value:
        result.append(_required_string(item, field))
    if len(result) != len(set(result)):
        raise ReplayInputError(f"duplicate_list_item:{field}")
    return tuple(result)


def _budget_delta(value: object) -> dict[str, int]:
    if not isinstance(value, Mapping):
        raise ReplayInputError("invalid_object:budget_delta")
    unknown = sorted(set(value) - set(BUDGET_COUNTERS))
    if unknown:
        raise ReplayInputError(f"unknown_budget_counter:{','.join(unknown)}")
    result: dict[str, int] = {}
    for field, current in value.items():
        if isinstance(current, bool) or not isinstance(current, int) or current < 1:
            raise ReplayInputError(f"invalid_budget_delta:{field}")
        result[field] = current
    return result


def _validate_checkpoint(value: object, source_base: str) -> dict[str, object]:
    checkpoint = dict(_exact_fields(value, CHECKPOINT_FIELDS, "checkpoint"))
    commit = _sha(checkpoint["commit"], "checkpoint.commit")
    parent = _sha(checkpoint["parent"], "checkpoint.parent")
    tree = _sha(checkpoint["tree"], "checkpoint.tree")
    subject = _required_string(checkpoint["subject"], "checkpoint.subject")
    changed_file_count = _positive_int(
        checkpoint["changed_file_count"], "checkpoint.changed_file_count"
    )
    published = checkpoint["published"]
    if not isinstance(published, bool):
        raise ReplayInputError("invalid_boolean:checkpoint.published")
    if (
        commit != ISSUE_284_CHECKPOINT
        or parent != source_base
        or parent != ISSUE_284_BASE
        or tree != ISSUE_284_CHECKPOINT_TREE
        or subject != ISSUE_284_CHECKPOINT_SUBJECT
        or changed_file_count != 6
    ):
        raise ReplayInputError("checkpoint_provenance_mismatch")
    if published:
        raise ReplayInputError("checkpoint_publication_drift")
    return checkpoint


def _validate_final(value: object) -> dict[str, object]:
    final = dict(_exact_fields(value, FINAL_FIELDS, "expected_final"))
    expected = {
        "state": "ACTION_AUTHORIZED",
        "blocker": "DEVICE_ACCEPTANCE_PENDING",
        "next_gate": "DEVICE",
        "issue_completed": False,
        "checkpoint_frozen": True,
        "remote_published": False,
    }
    if final != expected:
        raise ReplayInputError("false_completion_or_final_state_drift")
    try:
        State(str(final["state"]))
    except ValueError as exc:
        raise ReplayInputError("invalid_final_state") from exc
    return final


def _validate_event_scalars(value: object) -> dict[str, object]:
    event = dict(_exact_fields(value, EVENT_FIELDS, "event"))
    _required_string(event["event_id"], "event.event_id")
    _positive_int(event["sequence"], "event.sequence")
    _positive_int(event["comment_id"], "event.comment_id")
    kind = _required_string(event["event_kind"], "event.event_kind")
    if kind not in EVENT_KINDS:
        raise ReplayInputError(f"unknown_event_kind:{kind}")
    authority = _required_string(
        event["source_authority"], "event.source_authority"
    )
    if authority not in SOURCE_AUTHORITIES:
        raise ReplayInputError(f"unknown_source_authority:{authority}")
    _positive_int(event["scope_version"], "event.scope_version")
    _nullable_int(event["supersedes_comment_id"], "event.supersedes_comment_id")
    _nullable_int(event["authorization_comment_id"], "event.authorization_comment_id")
    _required_string(event["action_kind"], "event.action_kind")
    _nullable_string(event["approval_level"], "event.approval_level")
    _nullable_string(event["capability"], "event.capability")
    _sha(event["source_fingerprint"], "event.source_fingerprint")
    _required_string(event["branch_fingerprint"], "event.branch_fingerprint")
    checkpoint = _nullable_string(
        event["checkpoint_fingerprint"], "event.checkpoint_fingerprint"
    )
    if checkpoint is not None and not SHA_PATTERN.fullmatch(checkpoint):
        raise ReplayInputError("invalid_sha:event.checkpoint_fingerprint")
    _required_string(event["action_fingerprint"], "event.action_fingerprint")
    _string_list(event["allowlist"], "event.allowlist")
    _budget_delta(event["budget_delta"])
    action_started = event["action_started"]
    if action_started is not None and not isinstance(action_started, bool):
        raise ReplayInputError("invalid_boolean:event.action_started")
    result_class = _nullable_string(event["result_class"], "event.result_class")
    if result_class is not None and result_class not in RESULT_CLASSES:
        raise ReplayInputError(f"unknown_result_class:{result_class}")
    expected_state = _required_string(event["expected_state"], "event.expected_state")
    try:
        State(expected_state)
    except ValueError as exc:
        raise ReplayInputError(f"unknown_expected_state:{expected_state}") from exc
    _nullable_string(event["blocker"], "event.blocker")
    _required_string(event["next_gate"], "event.next_gate")
    _nullable_string(event["reused_evidence_id"], "event.reused_evidence_id")
    return event


def _validate_authorization_event(
    event: Mapping[str, object],
    *,
    latest_comment_id: int | None,
    latest_scope_version: int,
    source_base: str,
    source_branch: str,
    checkpoint_commit: str,
) -> tuple[str, str, str]:
    action = str(event["action_kind"])
    rule = ACTION_RULES.get(action)
    if rule is None:
        raise ReplayInputError(f"unknown_action:{action}")
    required_approval, required_capability, authorized_state = rule
    approval = event["approval_level"]
    capability = event["capability"]
    if approval != required_approval:
        raise ReplayInputError("approval_level_mismatch")
    if approval not in APPROVAL_ORDER:
        raise ReplayInputError("approval_level_unknown")
    if capability != required_capability or capability not in CAPABILITIES:
        raise ReplayInputError("capability_mismatch")
    if event["expected_state"] != authorized_state:
        raise ReplayInputError("authorization_state_mismatch")
    expected_supersession = latest_comment_id
    if event["supersedes_comment_id"] != expected_supersession:
        raise ReplayInputError("supersession_mismatch")
    if event["scope_version"] != latest_scope_version + 1:
        raise ReplayInputError("scope_version_not_increasing")
    if event["authorization_comment_id"] is not None:
        raise ReplayInputError("authorization_self_reference")
    if event["action_started"] is not None or event["result_class"] is not None:
        raise ReplayInputError("authorization_contains_result")
    if event["blocker"] is not None:
        raise ReplayInputError("authorization_contains_blocker")
    if event["branch_fingerprint"] != source_branch:
        raise ReplayInputError("branch_fingerprint_drift")
    checkpoint_fingerprint = event["checkpoint_fingerprint"]
    expected_source = source_base
    if checkpoint_fingerprint is not None:
        if checkpoint_fingerprint != checkpoint_commit:
            raise ReplayInputError("checkpoint_fingerprint_drift")
        expected_source = checkpoint_commit
    if event["source_fingerprint"] != expected_source:
        raise ReplayInputError("source_fingerprint_drift")
    return action, required_approval, required_capability


def _validate_result_event(
    event: Mapping[str, object],
    authorizations: Mapping[int, Mapping[str, object]],
    consumed: set[int],
    source_branch: str,
) -> bool:
    if event["approval_level"] is not None or event["capability"] is not None:
        raise ReplayInputError("result_contains_authorization")
    if event["supersedes_comment_id"] is not None:
        raise ReplayInputError("result_supersession_forbidden")
    if event["budget_delta"]:
        raise ReplayInputError("result_budget_delta_forbidden")
    if event["allowlist"]:
        raise ReplayInputError("result_allowlist_forbidden")
    if event["result_class"] is None or event["blocker"] is None:
        raise ReplayInputError("result_evidence_incomplete")
    if event["expected_state"] != "BLOCKED":
        raise ReplayInputError("result_state_mismatch")
    authorization_id = event["authorization_comment_id"]
    if not isinstance(authorization_id, int):
        raise ReplayInputError("result_authorization_required")
    authorization = authorizations.get(authorization_id)
    if authorization is None:
        raise ReplayInputError("unauthorized_action")
    if (
        event["action_kind"] != authorization["action_kind"]
        or event["scope_version"] != authorization["scope_version"]
    ):
        raise ReplayInputError("unauthorized_action")
    if event["action_fingerprint"] != authorization["action_fingerprint"]:
        raise ReplayInputError("action_fingerprint_drift")
    if event["source_fingerprint"] != authorization["source_fingerprint"]:
        raise ReplayInputError("source_fingerprint_drift")
    if event["branch_fingerprint"] != source_branch:
        raise ReplayInputError("branch_fingerprint_drift")
    if event["checkpoint_fingerprint"] != authorization["checkpoint_fingerprint"]:
        raise ReplayInputError("checkpoint_fingerprint_drift")
    action_started = event["action_started"]
    if action_started is True:
        if authorization_id in consumed:
            raise ReplayInputError("blind_retry")
        consumed.add(authorization_id)
        return True
    return False


def replay_issue_284(value: Mapping[str, object]) -> ReplaySummary:
    """Replay sanitized Issue #284 metadata without executing any action."""

    fixture = dict(_exact_fields(value, FIXTURE_FIELDS, "fixture"))
    schema_version = fixture["schema_version"]
    if isinstance(schema_version, bool) or schema_version != 1:
        raise ReplayInputError("unsupported_schema_version")
    issue_number = fixture["issue_number"]
    if isinstance(issue_number, bool) or issue_number != 284:
        raise ReplayInputError("unexpected_issue_number")
    if fixture["source_state"] != "open":
        raise ReplayInputError("source_issue_state_drift")
    source_base = _sha(fixture["source_base"], "source_base")
    if source_base != ISSUE_284_BASE:
        raise ReplayInputError("source_base_drift")
    source_branch = _required_string(fixture["source_branch"], "source_branch")
    if source_branch != ISSUE_284_BRANCH:
        raise ReplayInputError("source_branch_drift")
    if fixture["device_target"] != "tablet_primary":
        raise ReplayInputError("device_target_not_symbolic")
    precedence = _string_list(fixture["source_precedence"], "source_precedence")
    if precedence != SOURCE_PRECEDENCE:
        raise ReplayInputError("source_precedence_drift")
    checkpoint = _validate_checkpoint(fixture["checkpoint"], source_base)
    final = _validate_final(fixture["expected_final"])
    events_value = fixture["events"]
    if not isinstance(events_value, list):
        raise ReplayInputError("invalid_list:events")
    comment_count = _positive_int(fixture["comment_count"], "comment_count")
    if comment_count != len(events_value):
        raise ReplayInputError("comment_count_mismatch")

    seen: dict[str, bytes] = {}
    authorizations: dict[int, Mapping[str, object]] = {}
    consumed_authorizations: set[int] = set()
    budget = {field: 0 for field in BUDGET_COUNTERS}
    result_classes: list[str] = []
    reused_evidence_ids: set[str] = set()
    last_evidence_for_action: dict[str, str] = {}
    latest_comment_id: int | None = None
    latest_scope_version = 0
    last_sequence = 0
    authorization_count = 0
    ordinary_result_count = 0
    invocation_count = 0
    checkpoint_verified = False

    for raw_event in events_value:
        event = _validate_event_scalars(raw_event)
        event_id = str(event["event_id"])
        event_bytes = _canonical_bytes(event)
        previous = seen.get(event_id)
        if previous is not None:
            if previous != event_bytes:
                raise ReplayInputError("event_id_collision")
            continue
        sequence = int(event["sequence"])
        if sequence <= last_sequence:
            raise ReplayInputError("sequence_not_increasing")
        seen[event_id] = event_bytes
        last_sequence = sequence

        if event["source_authority"] != "github_authorization":
            continue

        kind = str(event["event_kind"])
        if kind in AUTHORIZATION_KINDS:
            action, _, _ = _validate_authorization_event(
                event,
                latest_comment_id=latest_comment_id,
                latest_scope_version=latest_scope_version,
                source_base=source_base,
                source_branch=source_branch,
                checkpoint_commit=str(checkpoint["commit"]),
            )
            comment_id = int(event["comment_id"])
            authorizations[comment_id] = event
            latest_comment_id = comment_id
            latest_scope_version = int(event["scope_version"])
            authorization_count += 1
            for field, delta in _budget_delta(event["budget_delta"]).items():
                budget[field] += delta
            evidence_id = event["reused_evidence_id"]
            if isinstance(evidence_id, str):
                previous_evidence = last_evidence_for_action.get(action)
                if previous_evidence is not None and previous_evidence != evidence_id:
                    raise ReplayInputError("reused_evidence_drift")
                last_evidence_for_action[action] = evidence_id
                reused_evidence_ids.add(evidence_id)
            if kind == "authorization_evidence":
                if event["checkpoint_fingerprint"] != checkpoint["commit"]:
                    raise ReplayInputError("checkpoint_provenance_mismatch")
                checkpoint_verified = True
        else:
            if _validate_result_event(
                event,
                authorizations,
                consumed_authorizations,
                source_branch,
            ):
                invocation_count += 1
            ordinary_result_count += 1
            result_classes.append(str(event["result_class"]))

    if latest_comment_id is None:
        raise ReplayInputError("authorization_missing")
    if latest_comment_id != 5147042969 or latest_scope_version != 15:
        raise ReplayInputError("latest_authorization_drift")
    if len(seen) < 19:
        raise ReplayInputError("source_comment_set_incomplete")
    if not checkpoint_verified:
        raise ReplayInputError("checkpoint_evidence_missing")
    if "PUBLISH" in (
        str(event["action_kind"])
        for event in authorizations.values()
    ):
        raise ReplayInputError("unauthorized_publish_authorization")

    return ReplaySummary(
        schema_version=1,
        issue_number=284,
        unique_event_count=len(seen),
        authorization_count=authorization_count,
        ordinary_result_count=ordinary_result_count,
        latest_valid_authorization_comment_id=latest_comment_id,
        latest_scope_version=latest_scope_version,
        checkpoint_commit=str(checkpoint["commit"]),
        checkpoint_tree=str(checkpoint["tree"]),
        checkpoint_verified=checkpoint_verified,
        budget_authorized=MappingProxyType(dict(budget)),
        invocation_count=invocation_count,
        result_classes=tuple(result_classes),
        reused_evidence_ids=tuple(sorted(reused_evidence_ids)),
        unauthorized_action_count=0,
        final_state=str(final["state"]),
        final_blocker=str(final["blocker"]),
        next_gate=str(final["next_gate"]),
        issue_completed=bool(final["issue_completed"]),
        checkpoint_frozen=bool(final["checkpoint_frozen"]),
        remote_published=bool(final["remote_published"]),
        reasons=("device_acceptance_pending", "issue_remains_open"),
    )
