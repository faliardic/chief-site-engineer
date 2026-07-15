"""Repository ports and SQLite adapters for Field Tracking persistence."""

from __future__ import annotations

import sqlite3
from collections.abc import Callable
from dataclasses import replace
from datetime import date
from typing import TYPE_CHECKING, Protocol, TypeVar

if TYPE_CHECKING:
    from app.field_tracking import (
        FollowUpEvent,
        FollowUpItem,
        FollowUpStatus,
        RoutineOccurrence,
        RoutineOccurrenceEvent,
        RoutineOccurrenceStatus,
        RoutineTemplate,
        RoutineTemplateEvent,
        RoutineTemplateStatus,
    )

from .contracts import INITIAL_REVISION, validate_utc_timestamp
from .errors import InvalidRecordError, RecordNotFound, RevisionConflict
from .field_tracking_mapping import (
    follow_up_event_from_row,
    follow_up_event_to_row,
    follow_up_from_row,
    follow_up_to_row,
    routine_occurrence_event_from_row,
    routine_occurrence_event_to_row,
    routine_occurrence_from_row,
    routine_occurrence_to_row,
    routine_template_event_from_row,
    routine_template_event_to_row,
    routine_template_from_row,
    routine_template_to_row,
)
from .repositories import (
    _SQLiteRepository,
    _raise_integrity_error,
    _validate_id,
    _validate_revision,
)


class FollowUpRepositoryPort(Protocol):
    def add(self, record: FollowUpItem) -> None: ...

    def get(self, follow_up_id: str) -> FollowUpItem: ...

    def list_all(self) -> list[FollowUpItem]: ...

    def list_by_status(self, status: FollowUpStatus) -> list[FollowUpItem]: ...

    def list_by_project_id(self, project_id: str | None) -> list[FollowUpItem]: ...

    def list_by_observation_id(self, observation_id: str) -> list[FollowUpItem]: ...

    def list_by_attention_range(
        self, start_at: str, end_at: str
    ) -> list[FollowUpItem]: ...

    def update(
        self, record: FollowUpItem, *, expected_revision: int
    ) -> FollowUpItem: ...


class FollowUpEventRepositoryPort(Protocol):
    def add(self, record: FollowUpEvent) -> None: ...

    def list_for_follow_up(self, follow_up_id: str) -> list[FollowUpEvent]: ...


class RoutineTemplateRepositoryPort(Protocol):
    def add(self, record: RoutineTemplate) -> None: ...

    def get(self, routine_template_id: str) -> RoutineTemplate: ...

    def list_all(self) -> list[RoutineTemplate]: ...

    def list_by_status(
        self, status: RoutineTemplateStatus
    ) -> list[RoutineTemplate]: ...

    def list_by_project_id(
        self, project_id: str | None
    ) -> list[RoutineTemplate]: ...

    def update(
        self, record: RoutineTemplate, *, expected_revision: int
    ) -> RoutineTemplate: ...


class RoutineTemplateEventRepositoryPort(Protocol):
    def add(self, record: RoutineTemplateEvent) -> None: ...

    def list_for_template(
        self, routine_template_id: str
    ) -> list[RoutineTemplateEvent]: ...


class RoutineOccurrenceRepositoryPort(Protocol):
    def add(self, record: RoutineOccurrence) -> RoutineOccurrence: ...

    def add_if_absent(self, record: RoutineOccurrence) -> RoutineOccurrence: ...

    def get(self, routine_occurrence_id: str) -> RoutineOccurrence: ...

    def get_by_template_date(
        self, routine_template_id: str, occurrence_local_date: str
    ) -> RoutineOccurrence: ...

    def list_for_template(
        self, routine_template_id: str
    ) -> list[RoutineOccurrence]: ...

    def list_by_status(
        self, status: RoutineOccurrenceStatus
    ) -> list[RoutineOccurrence]: ...

    def list_by_attention_range(
        self, start_at: str, end_at: str
    ) -> list[RoutineOccurrence]: ...

    def update(
        self, record: RoutineOccurrence, *, expected_revision: int
    ) -> RoutineOccurrence: ...


class RoutineOccurrenceEventRepositoryPort(Protocol):
    def add(self, record: RoutineOccurrenceEvent) -> None: ...

    def list_for_occurrence(
        self, routine_occurrence_id: str
    ) -> list[RoutineOccurrenceEvent]: ...


FOLLOW_UP_COLUMNS = """
id, capture_text, title, description, item_type, status, project_id,
observation_id, location, related_person, is_important, next_attention_at,
deadline_at, condition_text, outcome_type, outcome_note, revision, created_at,
updated_at, completed_at, cancelled_at
"""

ROUTINE_TEMPLATE_COLUMNS = """
id, title, description, project_id, recurrence_type, local_time, timezone,
month_day, start_date, end_date, status, is_important, revision, created_at,
updated_at, deactivated_at
"""

ROUTINE_OCCURRENCE_COLUMNS = """
id, routine_template_id, occurrence_local_date, scheduled_local_time,
scheduled_at_utc, status, next_attention_at, outcome_type, outcome_note,
revision, created_at, completed_at
"""

FOLLOW_UP_EVENT_COLUMNS = """
id, follow_up_id, sequence, event_type, actor, occurred_at, payload_json
"""

FOLLOW_UP_STATUSES = ("inbox", "active", "waiting", "completed", "cancelled")
ROUTINE_TEMPLATE_STATUSES = ("active", "inactive")
ROUTINE_OCCURRENCE_STATUSES = ("open", "closed")

ROUTINE_TEMPLATE_EVENT_COLUMNS = """
id, routine_template_id, sequence, event_type, actor, occurred_at, payload_json
"""

ROUTINE_OCCURRENCE_EVENT_COLUMNS = """
id, routine_occurrence_id, sequence, event_type, actor, occurred_at, payload_json
"""


class SQLiteFollowUpRepository(_SQLiteRepository):
    """SQLite adapter for follow-up aggregates."""

    def add(self, record: FollowUpItem) -> None:
        self._require_transaction()
        _require_initial_revision(record.revision, "follow-up")
        row = follow_up_to_row(record)
        try:
            self._connection.execute(
                f"""
                INSERT INTO follow_up_items ({FOLLOW_UP_COLUMNS})
                VALUES (
                    :id, :capture_text, :title, :description, :item_type, :status,
                    :project_id, :observation_id, :location, :related_person,
                    :is_important, :next_attention_at, :deadline_at,
                    :condition_text, :outcome_type, :outcome_note, :revision,
                    :created_at, :updated_at, :completed_at, :cancelled_at
                )
                """,
                row,
            )
        except sqlite3.IntegrityError as exc:
            _raise_integrity_error(exc, "follow-up")

    def get(self, follow_up_id: str) -> FollowUpItem:
        self._ensure_active()
        _validate_id(follow_up_id, "follow_up_id")
        row = self._connection.execute(
            f"SELECT {FOLLOW_UP_COLUMNS} FROM follow_up_items WHERE id = ?",
            (follow_up_id,),
        ).fetchone()
        if row is None:
            raise RecordNotFound("follow-up", follow_up_id)
        return _map_stored("follow-up", follow_up_from_row, row)

    def list_all(self) -> list[FollowUpItem]:
        return self._list("ORDER BY created_at, id")

    def list_by_status(self, status: FollowUpStatus) -> list[FollowUpItem]:
        normalized = _enum_value(status, FOLLOW_UP_STATUSES, "follow-up status")
        return self._list("WHERE status = ? ORDER BY created_at, id", (normalized,))

    def list_by_project_id(self, project_id: str | None) -> list[FollowUpItem]:
        if project_id is None:
            return self._list("WHERE project_id IS NULL ORDER BY created_at, id")
        _validate_id(project_id, "project_id")
        return self._list(
            "WHERE project_id = ? ORDER BY created_at, id", (project_id,)
        )

    def list_by_observation_id(self, observation_id: str) -> list[FollowUpItem]:
        _validate_id(observation_id, "observation_id")
        return self._list(
            "WHERE observation_id = ? ORDER BY created_at, id", (observation_id,)
        )

    def list_by_attention_range(
        self, start_at: str, end_at: str
    ) -> list[FollowUpItem]:
        _validate_attention_range(start_at, end_at)
        return self._list(
            """
            WHERE next_attention_at >= ? AND next_attention_at <= ?
            ORDER BY next_attention_at, id
            """,
            (start_at, end_at),
        )

    def update(
        self, record: FollowUpItem, *, expected_revision: int
    ) -> FollowUpItem:
        self._require_transaction()
        _validate_revision(expected_revision)
        current = self.get(record.follow_up_id)
        _require_current_revision(current.revision, expected_revision, record.follow_up_id)
        _require_unchanged(
            (record.capture_text, record.created_at),
            (current.capture_text, current.created_at),
            "follow-up capture_text and created_at are immutable",
        )
        if replace(record, revision=current.revision) == current:
            return current
        _require_next_revision(record.revision, expected_revision)
        row = follow_up_to_row(record)
        try:
            cursor = self._connection.execute(
                f"""
                UPDATE follow_up_items SET
                    capture_text = :capture_text, title = :title,
                    description = :description, item_type = :item_type,
                    status = :status, project_id = :project_id,
                    observation_id = :observation_id, location = :location,
                    related_person = :related_person,
                    is_important = :is_important,
                    next_attention_at = :next_attention_at,
                    deadline_at = :deadline_at,
                    condition_text = :condition_text,
                    outcome_type = :outcome_type,
                    outcome_note = :outcome_note, revision = :revision,
                    created_at = :created_at, updated_at = :updated_at,
                    completed_at = :completed_at, cancelled_at = :cancelled_at
                WHERE id = :id AND revision = :expected_revision
                """,
                {**row, "expected_revision": expected_revision},
            )
        except sqlite3.IntegrityError as exc:
            _raise_integrity_error(exc, "follow-up")
        if cursor.rowcount != 1:
            actual = self.get(record.follow_up_id)
            raise RevisionConflict(record.follow_up_id, expected_revision, actual.revision)
        return record

    def _list(
        self, suffix: str, parameters: tuple[object, ...] = ()
    ) -> list[FollowUpItem]:
        self._ensure_active()
        rows = self._connection.execute(
            f"SELECT {FOLLOW_UP_COLUMNS} FROM follow_up_items {suffix}", parameters
        )
        return [_map_stored("follow-up", follow_up_from_row, row) for row in rows]


class SQLiteRoutineTemplateRepository(_SQLiteRepository):
    """SQLite adapter for routine templates and normalized weekdays."""

    def add(self, record: RoutineTemplate) -> None:
        self._require_transaction()
        _require_initial_revision(record.revision, "routine template")
        row = routine_template_to_row(record)
        try:
            self._connection.execute(
                f"""
                INSERT INTO routine_templates ({ROUTINE_TEMPLATE_COLUMNS})
                VALUES (
                    :id, :title, :description, :project_id, :recurrence_type,
                    :local_time, :timezone, :month_day, :start_date, :end_date,
                    :status, :is_important, :revision, :created_at, :updated_at,
                    :deactivated_at
                )
                """,
                row,
            )
            self._replace_weekdays(record)
        except sqlite3.IntegrityError as exc:
            _raise_integrity_error(exc, "routine template")

    def get(self, routine_template_id: str) -> RoutineTemplate:
        self._ensure_active()
        _validate_id(routine_template_id, "routine_template_id")
        row = self._connection.execute(
            f"SELECT {ROUTINE_TEMPLATE_COLUMNS} FROM routine_templates WHERE id = ?",
            (routine_template_id,),
        ).fetchone()
        if row is None:
            raise RecordNotFound("routine template", routine_template_id)
        weekdays = self._weekday_values(routine_template_id)
        return _map_stored(
            "routine template", routine_template_from_row, row, weekdays
        )

    def list_all(self) -> list[RoutineTemplate]:
        return self._list("ORDER BY start_date, id")

    def list_by_status(
        self, status: RoutineTemplateStatus
    ) -> list[RoutineTemplate]:
        normalized = _enum_value(
            status, ROUTINE_TEMPLATE_STATUSES, "template status"
        )
        return self._list(
            "WHERE status = ? ORDER BY start_date, id", (normalized,)
        )

    def list_by_project_id(
        self, project_id: str | None
    ) -> list[RoutineTemplate]:
        if project_id is None:
            return self._list("WHERE project_id IS NULL ORDER BY start_date, id")
        _validate_id(project_id, "project_id")
        return self._list(
            "WHERE project_id = ? ORDER BY start_date, id", (project_id,)
        )

    def update(
        self, record: RoutineTemplate, *, expected_revision: int
    ) -> RoutineTemplate:
        self._require_transaction()
        _validate_revision(expected_revision)
        current = self.get(record.routine_template_id)
        _require_current_revision(
            current.revision, expected_revision, record.routine_template_id
        )
        _require_unchanged(
            (record.created_at,),
            (current.created_at,),
            "routine template created_at is immutable",
        )
        if replace(record, revision=current.revision) == current:
            return current
        _require_next_revision(record.revision, expected_revision)
        row = routine_template_to_row(record)
        try:
            cursor = self._connection.execute(
                """
                UPDATE routine_templates SET
                    title = :title, description = :description,
                    project_id = :project_id, recurrence_type = :recurrence_type,
                    local_time = :local_time, timezone = :timezone,
                    month_day = :month_day, start_date = :start_date,
                    end_date = :end_date, status = :status,
                    is_important = :is_important, revision = :revision,
                    created_at = :created_at, updated_at = :updated_at,
                    deactivated_at = :deactivated_at
                WHERE id = :id AND revision = :expected_revision
                """,
                {**row, "expected_revision": expected_revision},
            )
            if cursor.rowcount != 1:
                actual = self.get(record.routine_template_id)
                raise RevisionConflict(
                    record.routine_template_id, expected_revision, actual.revision
                )
            self._replace_weekdays(record)
        except sqlite3.IntegrityError as exc:
            _raise_integrity_error(exc, "routine template")
        return record

    def _list(
        self, suffix: str, parameters: tuple[object, ...] = ()
    ) -> list[RoutineTemplate]:
        self._ensure_active()
        rows = self._connection.execute(
            f"SELECT {ROUTINE_TEMPLATE_COLUMNS} FROM routine_templates {suffix}",
            parameters,
        )
        return [
            _map_stored(
                "routine template",
                routine_template_from_row,
                row,
                self._weekday_values(row["id"]),
            )
            for row in rows
        ]

    def _weekday_values(self, routine_template_id: str) -> list[int]:
        rows = self._connection.execute(
            """
            SELECT iso_weekday FROM routine_template_weekdays
            WHERE routine_template_id = ? ORDER BY iso_weekday
            """,
            (routine_template_id,),
        )
        return [row["iso_weekday"] for row in rows]

    def _replace_weekdays(self, record: RoutineTemplate) -> None:
        self._connection.execute(
            "DELETE FROM routine_template_weekdays WHERE routine_template_id = ?",
            (record.routine_template_id,),
        )
        self._connection.executemany(
            """
            INSERT INTO routine_template_weekdays
                (routine_template_id, iso_weekday) VALUES (?, ?)
            """,
            [
                (record.routine_template_id, weekday)
                for weekday in sorted(record.weekdays)
            ],
        )


class SQLiteRoutineOccurrenceRepository(_SQLiteRepository):
    """SQLite adapter with idempotent template-and-local-date insertion."""

    def add(self, record: RoutineOccurrence) -> RoutineOccurrence:
        """Add an occurrence through the idempotent natural-key primitive."""

        return self.add_if_absent(record)

    def add_if_absent(self, record: RoutineOccurrence) -> RoutineOccurrence:
        self._require_transaction()
        _require_initial_revision(record.revision, "routine occurrence")
        row = routine_occurrence_to_row(record)
        try:
            self._connection.execute(
                f"""
                INSERT INTO routine_occurrences ({ROUTINE_OCCURRENCE_COLUMNS})
                VALUES (
                    :id, :routine_template_id, :occurrence_local_date,
                    :scheduled_local_time, :scheduled_at_utc, :status,
                    :next_attention_at, :outcome_type, :outcome_note, :revision,
                    :created_at, :completed_at
                )
                """,
                row,
            )
        except sqlite3.IntegrityError as exc:
            existing = self._find_by_template_date(
                record.routine_template_id, record.occurrence_local_date
            )
            if existing is not None:
                return existing
            _raise_integrity_error(exc, "routine occurrence")
        return record

    def get(self, routine_occurrence_id: str) -> RoutineOccurrence:
        self._ensure_active()
        _validate_id(routine_occurrence_id, "routine_occurrence_id")
        row = self._connection.execute(
            f"SELECT {ROUTINE_OCCURRENCE_COLUMNS} FROM routine_occurrences WHERE id = ?",
            (routine_occurrence_id,),
        ).fetchone()
        if row is None:
            raise RecordNotFound("routine occurrence", routine_occurrence_id)
        return _map_stored("routine occurrence", routine_occurrence_from_row, row)

    def get_by_template_date(
        self, routine_template_id: str, occurrence_local_date: str
    ) -> RoutineOccurrence:
        self._ensure_active()
        _validate_id(routine_template_id, "routine_template_id")
        _validate_date(occurrence_local_date)
        record = self._find_by_template_date(
            routine_template_id, occurrence_local_date
        )
        if record is None:
            raise RecordNotFound(
                "routine occurrence", f"{routine_template_id}/{occurrence_local_date}"
            )
        return record

    def list_for_template(
        self, routine_template_id: str
    ) -> list[RoutineOccurrence]:
        _validate_id(routine_template_id, "routine_template_id")
        return self._list(
            """
            WHERE routine_template_id = ?
            ORDER BY occurrence_local_date, id
            """,
            (routine_template_id,),
        )

    def list_by_status(
        self, status: RoutineOccurrenceStatus
    ) -> list[RoutineOccurrence]:
        normalized = _enum_value(
            status, ROUTINE_OCCURRENCE_STATUSES, "occurrence status"
        )
        return self._list(
            "WHERE status = ? ORDER BY occurrence_local_date, id", (normalized,)
        )

    def list_by_attention_range(
        self, start_at: str, end_at: str
    ) -> list[RoutineOccurrence]:
        _validate_attention_range(start_at, end_at)
        return self._list(
            """
            WHERE next_attention_at >= ? AND next_attention_at <= ?
            ORDER BY next_attention_at, id
            """,
            (start_at, end_at),
        )

    def update(
        self, record: RoutineOccurrence, *, expected_revision: int
    ) -> RoutineOccurrence:
        self._require_transaction()
        _validate_revision(expected_revision)
        current = self.get(record.routine_occurrence_id)
        _require_current_revision(
            current.revision, expected_revision, record.routine_occurrence_id
        )
        _require_unchanged(
            (
                record.routine_template_id,
                record.occurrence_local_date,
                record.scheduled_local_time,
                record.scheduled_at_utc,
                record.created_at,
            ),
            (
                current.routine_template_id,
                current.occurrence_local_date,
                current.scheduled_local_time,
                current.scheduled_at_utc,
                current.created_at,
            ),
            "routine occurrence identity and schedule snapshot are immutable",
        )
        if replace(record, revision=current.revision) == current:
            return current
        _require_next_revision(record.revision, expected_revision)
        row = routine_occurrence_to_row(record)
        try:
            cursor = self._connection.execute(
                """
                UPDATE routine_occurrences SET
                    routine_template_id = :routine_template_id,
                    occurrence_local_date = :occurrence_local_date,
                    scheduled_local_time = :scheduled_local_time,
                    scheduled_at_utc = :scheduled_at_utc, status = :status,
                    next_attention_at = :next_attention_at,
                    outcome_type = :outcome_type, outcome_note = :outcome_note,
                    revision = :revision, created_at = :created_at,
                    completed_at = :completed_at
                WHERE id = :id AND revision = :expected_revision
                """,
                {**row, "expected_revision": expected_revision},
            )
        except sqlite3.IntegrityError as exc:
            _raise_integrity_error(exc, "routine occurrence")
        if cursor.rowcount != 1:
            actual = self.get(record.routine_occurrence_id)
            raise RevisionConflict(
                record.routine_occurrence_id, expected_revision, actual.revision
            )
        return record

    def _find_by_template_date(
        self, routine_template_id: str, occurrence_local_date: str
    ) -> RoutineOccurrence | None:
        row = self._connection.execute(
            f"""
            SELECT {ROUTINE_OCCURRENCE_COLUMNS} FROM routine_occurrences
            WHERE routine_template_id = ? AND occurrence_local_date = ?
            """,
            (routine_template_id, occurrence_local_date),
        ).fetchone()
        if row is None:
            return None
        return _map_stored("routine occurrence", routine_occurrence_from_row, row)

    def _list(
        self, suffix: str, parameters: tuple[object, ...] = ()
    ) -> list[RoutineOccurrence]:
        self._ensure_active()
        rows = self._connection.execute(
            f"SELECT {ROUTINE_OCCURRENCE_COLUMNS} FROM routine_occurrences {suffix}",
            parameters,
        )
        return [
            _map_stored("routine occurrence", routine_occurrence_from_row, row)
            for row in rows
        ]


EventRecord = TypeVar("EventRecord")


class _SQLiteEventRepository(_SQLiteRepository):
    def _add(
        self,
        table: str,
        columns: str,
        row: dict[str, object],
        record_type: str,
    ) -> None:
        self._require_transaction()
        aggregate_column = next(
            key
            for key in (
                "follow_up_id",
                "routine_template_id",
                "routine_occurrence_id",
            )
            if key in row
        )
        try:
            self._connection.execute(
                f"""
                INSERT INTO {table} ({columns})
                VALUES (
                    :id, :{aggregate_column}, :sequence, :event_type, :actor,
                    :occurred_at, :payload_json
                )
                """,
                row,
            )
        except sqlite3.IntegrityError as exc:
            _raise_integrity_error(exc, record_type)

    def _list_events(
        self,
        table: str,
        columns: str,
        aggregate_column: str,
        aggregate_id: str,
        record_type: str,
        mapper: Callable[[sqlite3.Row], EventRecord],
    ) -> list[EventRecord]:
        self._ensure_active()
        rows = self._connection.execute(
            f"""
            SELECT {columns} FROM {table}
            WHERE {aggregate_column} = ? ORDER BY sequence
            """,
            (aggregate_id,),
        )
        return [_map_stored(record_type, mapper, row) for row in rows]


class SQLiteFollowUpEventRepository(_SQLiteEventRepository):
    """Append-only SQLite adapter for follow-up events."""

    def add(self, record: FollowUpEvent) -> None:
        self._add(
            "follow_up_events",
            FOLLOW_UP_EVENT_COLUMNS,
            follow_up_event_to_row(record),
            "follow-up event",
        )

    def list_for_follow_up(self, follow_up_id: str) -> list[FollowUpEvent]:
        _validate_id(follow_up_id, "follow_up_id")
        return self._list_events(
            "follow_up_events",
            FOLLOW_UP_EVENT_COLUMNS,
            "follow_up_id",
            follow_up_id,
            "follow-up event",
            follow_up_event_from_row,
        )


class SQLiteRoutineTemplateEventRepository(_SQLiteEventRepository):
    """Append-only SQLite adapter for routine template events."""

    def add(self, record: RoutineTemplateEvent) -> None:
        self._add(
            "routine_template_events",
            ROUTINE_TEMPLATE_EVENT_COLUMNS,
            routine_template_event_to_row(record),
            "routine template event",
        )

    def list_for_template(
        self, routine_template_id: str
    ) -> list[RoutineTemplateEvent]:
        _validate_id(routine_template_id, "routine_template_id")
        return self._list_events(
            "routine_template_events",
            ROUTINE_TEMPLATE_EVENT_COLUMNS,
            "routine_template_id",
            routine_template_id,
            "routine template event",
            routine_template_event_from_row,
        )


class SQLiteRoutineOccurrenceEventRepository(_SQLiteEventRepository):
    """Append-only SQLite adapter for routine occurrence events."""

    def add(self, record: RoutineOccurrenceEvent) -> None:
        self._add(
            "routine_occurrence_events",
            ROUTINE_OCCURRENCE_EVENT_COLUMNS,
            routine_occurrence_event_to_row(record),
            "routine occurrence event",
        )

    def list_for_occurrence(
        self, routine_occurrence_id: str
    ) -> list[RoutineOccurrenceEvent]:
        _validate_id(routine_occurrence_id, "routine_occurrence_id")
        return self._list_events(
            "routine_occurrence_events",
            ROUTINE_OCCURRENCE_EVENT_COLUMNS,
            "routine_occurrence_id",
            routine_occurrence_id,
            "routine occurrence event",
            routine_occurrence_event_from_row,
        )


StoredRecord = TypeVar("StoredRecord")


def _map_stored(
    record_type: str,
    mapper: Callable[..., StoredRecord],
    row: sqlite3.Row,
    *args: object,
) -> StoredRecord:
    try:
        return mapper(row, *args)
    except (IndexError, KeyError, TypeError, ValueError) as exc:
        raise InvalidRecordError(f"stored {record_type} is invalid: {exc}") from exc


def _require_initial_revision(revision: int, record_type: str) -> None:
    if revision != INITIAL_REVISION:
        raise InvalidRecordError(
            f"new {record_type} revision must be {INITIAL_REVISION}"
        )


def _require_current_revision(actual: int, expected: int, record_id: str) -> None:
    if actual != expected:
        raise RevisionConflict(record_id, expected, actual)


def _require_next_revision(candidate: int, expected: int) -> None:
    if candidate != expected + 1:
        raise InvalidRecordError("updated record revision must increase by exactly one")


def _require_unchanged(
    candidate: tuple[object, ...], current: tuple[object, ...], message: str
) -> None:
    if candidate != current:
        raise InvalidRecordError(message)


def _enum_value(
    value: object, allowed_values: tuple[str, ...], field_name: str
) -> str:
    normalized = getattr(value, "value", value)
    if not isinstance(normalized, str) or normalized not in allowed_values:
        raise InvalidRecordError(f"invalid {field_name}")
    return normalized


def _validate_date(value: str) -> None:
    try:
        parsed = date.fromisoformat(value)
    except (TypeError, ValueError) as exc:
        raise InvalidRecordError(f"occurrence_local_date: {exc}") from exc
    if parsed.isoformat() != value:
        raise InvalidRecordError(
            "occurrence_local_date must use canonical YYYY-MM-DD format"
        )


def _validate_attention_range(start_at: str, end_at: str) -> None:
    try:
        validate_utc_timestamp(start_at)
        validate_utc_timestamp(end_at)
    except ValueError as exc:
        raise InvalidRecordError(f"attention range: {exc}") from exc
    if start_at > end_at:
        raise InvalidRecordError("attention range start_at cannot be after end_at")


__all__ = [
    "FollowUpEventRepositoryPort",
    "FollowUpRepositoryPort",
    "RoutineOccurrenceEventRepositoryPort",
    "RoutineOccurrenceRepositoryPort",
    "RoutineTemplateEventRepositoryPort",
    "RoutineTemplateRepositoryPort",
    "SQLiteFollowUpEventRepository",
    "SQLiteFollowUpRepository",
    "SQLiteRoutineOccurrenceEventRepository",
    "SQLiteRoutineOccurrenceRepository",
    "SQLiteRoutineTemplateEventRepository",
    "SQLiteRoutineTemplateRepository",
]
