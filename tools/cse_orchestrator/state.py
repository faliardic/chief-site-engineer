"""Executable, immutable O0 state-machine contract for CSE O2."""

from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass
from enum import Enum
from typing import Iterable, Mapping


class State(str, Enum):
    IDLE = "IDLE"
    OBSERVING = "OBSERVING"
    PREFLIGHT_BLOCKED = "PREFLIGHT_BLOCKED"
    SCOPE_VALIDATED = "SCOPE_VALIDATED"
    AWAITING_APPROVAL = "AWAITING_APPROVAL"
    CODEX_AUTHORIZED = "CODEX_AUTHORIZED"
    ACTION_AUTHORIZED = "ACTION_AUTHORIZED"
    CODEX_RUNNING = "CODEX_RUNNING"
    ACTION_RUNNING = "ACTION_RUNNING"
    RESULT_RECEIVED = "RESULT_RECEIVED"
    DETERMINISTIC_VALIDATION = "DETERMINISTIC_VALIDATION"
    FOCUSED_PASS = "FOCUSED_PASS"
    FULL_PASS = "FULL_PASS"
    SOURCE_VALIDATED = "SOURCE_VALIDATED"
    CHECKPOINT_COMMITTED = "CHECKPOINT_COMMITTED"
    ARTIFACT_BUILT = "ARTIFACT_BUILT"
    DEVICE_ACCEPTANCE = "DEVICE_ACCEPTANCE"
    PUBLISH_READY = "PUBLISH_READY"
    BLOCKED = "BLOCKED"
    FAILED = "FAILED"
    CANCELLED = "CANCELLED"
    COMPLETED = "COMPLETED"


TERMINAL_STATES = frozenset(
    {
        State.PREFLIGHT_BLOCKED,
        State.BLOCKED,
        State.FAILED,
        State.CANCELLED,
        State.COMPLETED,
    }
)


_DOCUMENTED_TRANSITIONS: Mapping[State, frozenset[State]] = {
    State.IDLE: frozenset({State.OBSERVING}),
    State.OBSERVING: frozenset({State.SCOPE_VALIDATED, State.PREFLIGHT_BLOCKED}),
    State.SCOPE_VALIDATED: frozenset({State.AWAITING_APPROVAL}),
    State.AWAITING_APPROVAL: frozenset(
        {State.CODEX_AUTHORIZED, State.ACTION_AUTHORIZED}
    ),
    State.CODEX_AUTHORIZED: frozenset({State.CODEX_RUNNING}),
    State.ACTION_AUTHORIZED: frozenset({State.ACTION_RUNNING}),
    State.CODEX_RUNNING: frozenset({State.RESULT_RECEIVED}),
    State.ACTION_RUNNING: frozenset({State.RESULT_RECEIVED}),
    State.RESULT_RECEIVED: frozenset({State.DETERMINISTIC_VALIDATION}),
    State.DETERMINISTIC_VALIDATION: frozenset(
        {
            State.FOCUSED_PASS,
            State.FULL_PASS,
            State.CHECKPOINT_COMMITTED,
            State.ARTIFACT_BUILT,
            State.DEVICE_ACCEPTANCE,
            State.COMPLETED,
            State.FAILED,
            State.BLOCKED,
        }
    ),
    State.FOCUSED_PASS: frozenset(
        {State.AWAITING_APPROVAL, State.SOURCE_VALIDATED}
    ),
    State.FULL_PASS: frozenset({State.SOURCE_VALIDATED}),
    State.SOURCE_VALIDATED: frozenset({State.AWAITING_APPROVAL}),
    State.CHECKPOINT_COMMITTED: frozenset(
        {State.AWAITING_APPROVAL, State.PUBLISH_READY}
    ),
    State.ARTIFACT_BUILT: frozenset(
        {State.AWAITING_APPROVAL, State.PUBLISH_READY}
    ),
    State.DEVICE_ACCEPTANCE: frozenset({State.PUBLISH_READY}),
    State.PUBLISH_READY: frozenset(
        {State.AWAITING_APPROVAL, State.COMPLETED}
    ),
    State.PREFLIGHT_BLOCKED: frozenset(),
    State.BLOCKED: frozenset(),
    State.FAILED: frozenset(),
    State.CANCELLED: frozenset(),
    State.COMPLETED: frozenset(),
}


ALLOWED_TRANSITIONS: Mapping[State, frozenset[State]] = {
    source: (
        targets
        if source in TERMINAL_STATES
        else frozenset(set(targets) | {State.CANCELLED})
    )
    for source, targets in _DOCUMENTED_TRANSITIONS.items()
}


class TransitionError(ValueError):
    """An event cannot be projected without weakening the state contract."""


def parse_state(value: State | str) -> State:
    if isinstance(value, State):
        return value
    try:
        return State(value)
    except (TypeError, ValueError) as exc:
        raise TransitionError(f"unknown_state:{value}") from exc


def can_transition(state_from: State | str, state_to: State | str) -> bool:
    try:
        source = parse_state(state_from)
        target = parse_state(state_to)
    except TransitionError:
        return False
    return target in ALLOWED_TRANSITIONS[source]


def _canonical_bytes(value: Mapping[str, object]) -> bytes:
    return json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")


@dataclass(frozen=True)
class TransitionEvent:
    """One immutable state transition; persistence belongs to a later phase."""

    event_id: str
    run_id: str
    sequence: int
    state_from: State
    state_to: State
    source_fingerprint: str

    def identity_payload(self) -> dict[str, object]:
        return {
            "event_type": "state_transition",
            "run_id": self.run_id,
            "schema_version": 1,
            "sequence": self.sequence,
            "source_fingerprint": self.source_fingerprint,
            "state_from": self.state_from.value,
            "state_to": self.state_to.value,
        }

    def public_dict(self) -> dict[str, object]:
        return {"event_id": self.event_id, **self.identity_payload()}


def _event_id(payload: Mapping[str, object]) -> str:
    return "sha256:" + hashlib.sha256(_canonical_bytes(payload)).hexdigest()


def create_transition_event(
    *,
    run_id: str,
    sequence: int,
    state_from: State | str,
    state_to: State | str,
    source_fingerprint: str,
    validate_transition: bool = True,
) -> TransitionEvent:
    if not isinstance(run_id, str) or not run_id:
        raise TransitionError("run_id_required")
    if isinstance(sequence, bool) or not isinstance(sequence, int) or sequence < 1:
        raise TransitionError("sequence_must_be_positive")
    if not isinstance(source_fingerprint, str) or not source_fingerprint:
        raise TransitionError("source_fingerprint_required")
    source = parse_state(state_from)
    target = parse_state(state_to)
    if validate_transition and not can_transition(source, target):
        raise TransitionError(
            f"transition_not_allowed:{source.value}->{target.value}"
        )
    payload = {
        "event_type": "state_transition",
        "run_id": run_id,
        "schema_version": 1,
        "sequence": sequence,
        "source_fingerprint": source_fingerprint,
        "state_from": source.value,
        "state_to": target.value,
    }
    return TransitionEvent(
        event_id=_event_id(payload),
        run_id=run_id,
        sequence=sequence,
        state_from=source,
        state_to=target,
        source_fingerprint=source_fingerprint,
    )


def project_events(
    initial_state: State | str,
    events: Iterable[TransitionEvent],
) -> State:
    """Project immutable events; exact replays are no-ops, collisions fail."""

    current = parse_state(initial_state)
    seen: dict[str, bytes] = {}
    run_id: str | None = None
    last_sequence = 0
    for event in events:
        if not isinstance(event, TransitionEvent):
            raise TransitionError("event_type_invalid")
        public_bytes = _canonical_bytes(event.public_dict())
        previous = seen.get(event.event_id)
        if previous is not None:
            if previous != public_bytes:
                raise TransitionError("event_id_collision")
            continue
        if event.event_id != _event_id(event.identity_payload()):
            raise TransitionError("event_id_invalid")
        if run_id is None:
            run_id = event.run_id
        elif event.run_id != run_id:
            raise TransitionError("run_id_mismatch")
        if event.sequence <= last_sequence:
            raise TransitionError("sequence_not_increasing")
        if event.state_from is not current:
            raise TransitionError("projection_state_mismatch")
        if not can_transition(event.state_from, event.state_to):
            raise TransitionError(
                "transition_not_allowed:"
                f"{event.state_from.value}->{event.state_to.value}"
            )
        seen[event.event_id] = public_bytes
        last_sequence = event.sequence
        current = event.state_to
    return current
