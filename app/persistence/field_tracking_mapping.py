"""Explicit domain-to-SQLite mappings for Field Tracking records."""

from __future__ import annotations

import json
from collections.abc import Iterable, Mapping
from typing import TYPE_CHECKING, cast

if TYPE_CHECKING:
    from app.field_tracking import (
        FollowUpEvent,
        FollowUpItem,
        RoutineOccurrence,
        RoutineOccurrenceEvent,
        RoutineTemplate,
        RoutineTemplateEvent,
    )

from .records import canonicalize_event_payload_json


def follow_up_to_row(record: FollowUpItem) -> dict[str, object]:
    """Return the complete SQLite row for one follow-up aggregate."""

    return {
        "id": record.follow_up_id,
        "capture_text": record.capture_text,
        "title": record.title,
        "description": record.description,
        "item_type": record.item_type.value,
        "status": record.status.value,
        "project_id": record.project_id,
        "observation_id": record.observation_id,
        "location": record.location,
        "related_person": record.related_person,
        "is_important": int(record.is_important),
        "next_attention_at": record.next_attention_at,
        "deadline_at": record.deadline_at,
        "condition_text": record.condition_text,
        "outcome_type": (
            record.outcome_type.value if record.outcome_type is not None else None
        ),
        "outcome_note": record.outcome_note,
        "revision": record.revision,
        "created_at": record.created_at,
        "updated_at": record.updated_at,
        "completed_at": record.completed_at,
        "cancelled_at": record.cancelled_at,
    }


def follow_up_from_row(row: Mapping[str, object]) -> FollowUpItem:
    """Build a validated follow-up domain record from one SQLite row."""

    from app.field_tracking import (
        FollowUpItem,
        FollowUpItemType,
        FollowUpOutcome,
        FollowUpStatus,
    )

    return FollowUpItem(
        follow_up_id=cast(str, row["id"]),
        capture_text=cast(str, row["capture_text"]),
        title=cast(str, row["title"]),
        description=cast(str | None, row["description"]),
        item_type=FollowUpItemType(cast(str, row["item_type"])),
        status=FollowUpStatus(cast(str, row["status"])),
        project_id=cast(str | None, row["project_id"]),
        observation_id=cast(str | None, row["observation_id"]),
        location=cast(str | None, row["location"]),
        related_person=cast(str | None, row["related_person"]),
        is_important=_database_bool(row["is_important"], "is_important"),
        next_attention_at=cast(str | None, row["next_attention_at"]),
        deadline_at=cast(str | None, row["deadline_at"]),
        condition_text=cast(str | None, row["condition_text"]),
        outcome_type=(
            FollowUpOutcome(cast(str, row["outcome_type"]))
            if row["outcome_type"] is not None
            else None
        ),
        outcome_note=cast(str | None, row["outcome_note"]),
        revision=cast(int, row["revision"]),
        created_at=cast(str, row["created_at"]),
        updated_at=cast(str, row["updated_at"]),
        completed_at=cast(str | None, row["completed_at"]),
        cancelled_at=cast(str | None, row["cancelled_at"]),
    )


def routine_template_to_row(record: RoutineTemplate) -> dict[str, object]:
    """Return the parent SQLite row for one routine template."""

    return {
        "id": record.routine_template_id,
        "title": record.title,
        "description": record.description,
        "project_id": record.project_id,
        "recurrence_type": record.recurrence_type.value,
        "local_time": record.local_time,
        "timezone": record.timezone,
        "month_day": record.month_day,
        "start_date": record.start_date,
        "end_date": record.end_date,
        "status": record.status.value,
        "is_important": int(record.is_important),
        "revision": record.revision,
        "created_at": record.created_at,
        "updated_at": record.updated_at,
        "deactivated_at": record.deactivated_at,
    }


def routine_template_from_row(
    row: Mapping[str, object], weekdays: Iterable[int]
) -> RoutineTemplate:
    """Build a validated template and attach its normalized weekday relation."""

    from app.field_tracking import (
        RoutineRecurrenceType,
        RoutineTemplate,
        RoutineTemplateStatus,
    )

    return RoutineTemplate(
        routine_template_id=cast(str, row["id"]),
        title=cast(str, row["title"]),
        description=cast(str | None, row["description"]),
        project_id=cast(str | None, row["project_id"]),
        recurrence_type=RoutineRecurrenceType(cast(str, row["recurrence_type"])),
        local_time=cast(str, row["local_time"]),
        timezone=cast(str, row["timezone"]),
        weekdays=frozenset(weekdays),
        month_day=cast(int | None, row["month_day"]),
        start_date=cast(str, row["start_date"]),
        end_date=cast(str | None, row["end_date"]),
        status=RoutineTemplateStatus(cast(str, row["status"])),
        is_important=_database_bool(row["is_important"], "is_important"),
        revision=cast(int, row["revision"]),
        created_at=cast(str, row["created_at"]),
        updated_at=cast(str, row["updated_at"]),
        deactivated_at=cast(str | None, row["deactivated_at"]),
    )


def routine_occurrence_to_row(record: RoutineOccurrence) -> dict[str, object]:
    """Return the complete SQLite row for one routine occurrence."""

    return {
        "id": record.routine_occurrence_id,
        "routine_template_id": record.routine_template_id,
        "occurrence_local_date": record.occurrence_local_date,
        "scheduled_local_time": record.scheduled_local_time,
        "scheduled_at_utc": record.scheduled_at_utc,
        "status": record.status.value,
        "next_attention_at": record.next_attention_at,
        "outcome_type": (
            record.outcome_type.value if record.outcome_type is not None else None
        ),
        "outcome_note": record.outcome_note,
        "revision": record.revision,
        "created_at": record.created_at,
        "completed_at": record.completed_at,
    }


def routine_occurrence_from_row(row: Mapping[str, object]) -> RoutineOccurrence:
    """Build a validated routine occurrence domain record."""

    from app.field_tracking import (
        RoutineOccurrence,
        RoutineOccurrenceOutcome,
        RoutineOccurrenceStatus,
    )

    return RoutineOccurrence(
        routine_occurrence_id=cast(str, row["id"]),
        routine_template_id=cast(str, row["routine_template_id"]),
        occurrence_local_date=cast(str, row["occurrence_local_date"]),
        scheduled_local_time=cast(str, row["scheduled_local_time"]),
        scheduled_at_utc=cast(str, row["scheduled_at_utc"]),
        status=RoutineOccurrenceStatus(cast(str, row["status"])),
        next_attention_at=cast(str, row["next_attention_at"]),
        outcome_type=(
            RoutineOccurrenceOutcome(cast(str, row["outcome_type"]))
            if row["outcome_type"] is not None
            else None
        ),
        outcome_note=cast(str | None, row["outcome_note"]),
        revision=cast(int, row["revision"]),
        created_at=cast(str, row["created_at"]),
        completed_at=cast(str | None, row["completed_at"]),
    )


def follow_up_event_to_row(record: FollowUpEvent) -> dict[str, object]:
    return _event_to_row(record, "follow_up_id", record.follow_up_id)


def follow_up_event_from_row(row: Mapping[str, object]) -> FollowUpEvent:
    from app.field_tracking import FollowUpEvent, FollowUpEventType

    return FollowUpEvent(
        event_id=cast(str, row["id"]),
        follow_up_id=cast(str, row["follow_up_id"]),
        sequence=cast(int, row["sequence"]),
        event_type=FollowUpEventType(cast(str, row["event_type"])),
        actor=cast(str, row["actor"]),
        occurred_at=cast(str, row["occurred_at"]),
        payload=_event_payload(row["payload_json"]),
    )


def routine_template_event_to_row(
    record: RoutineTemplateEvent,
) -> dict[str, object]:
    return _event_to_row(
        record, "routine_template_id", record.routine_template_id
    )


def routine_template_event_from_row(
    row: Mapping[str, object],
) -> RoutineTemplateEvent:
    from app.field_tracking import RoutineTemplateEvent, RoutineTemplateEventType

    return RoutineTemplateEvent(
        event_id=cast(str, row["id"]),
        routine_template_id=cast(str, row["routine_template_id"]),
        sequence=cast(int, row["sequence"]),
        event_type=RoutineTemplateEventType(cast(str, row["event_type"])),
        actor=cast(str, row["actor"]),
        occurred_at=cast(str, row["occurred_at"]),
        payload=_event_payload(row["payload_json"]),
    )


def routine_occurrence_event_to_row(
    record: RoutineOccurrenceEvent,
) -> dict[str, object]:
    return _event_to_row(
        record, "routine_occurrence_id", record.routine_occurrence_id
    )


def routine_occurrence_event_from_row(
    row: Mapping[str, object],
) -> RoutineOccurrenceEvent:
    from app.field_tracking import (
        RoutineOccurrenceEvent,
        RoutineOccurrenceEventType,
    )

    return RoutineOccurrenceEvent(
        event_id=cast(str, row["id"]),
        routine_occurrence_id=cast(str, row["routine_occurrence_id"]),
        sequence=cast(int, row["sequence"]),
        event_type=RoutineOccurrenceEventType(cast(str, row["event_type"])),
        actor=cast(str, row["actor"]),
        occurred_at=cast(str, row["occurred_at"]),
        payload=_event_payload(row["payload_json"]),
    )


def _event_to_row(
    record: FollowUpEvent | RoutineTemplateEvent | RoutineOccurrenceEvent,
    aggregate_column: str,
    aggregate_id: str,
) -> dict[str, object]:
    return {
        "id": record.event_id,
        aggregate_column: aggregate_id,
        "sequence": record.sequence,
        "event_type": record.event_type.value,
        "actor": record.actor,
        "occurred_at": record.occurred_at,
        "payload_json": record.payload_json,
    }


def _event_payload(value: object) -> Mapping[str, object]:
    canonical = canonicalize_event_payload_json(cast(str, value))
    return cast(dict[str, object], json.loads(canonical))


def _database_bool(value: object, field_name: str) -> bool:
    if value == 0:
        return False
    if value == 1:
        return True
    raise ValueError(f"{field_name} database value must be 0 or 1")


__all__ = [
    "follow_up_event_from_row",
    "follow_up_event_to_row",
    "follow_up_from_row",
    "follow_up_to_row",
    "routine_occurrence_event_from_row",
    "routine_occurrence_event_to_row",
    "routine_occurrence_from_row",
    "routine_occurrence_to_row",
    "routine_template_event_from_row",
    "routine_template_event_to_row",
    "routine_template_from_row",
    "routine_template_to_row",
]
