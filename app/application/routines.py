"""Transactional application use cases for recurring field routines."""

from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass, replace
from datetime import date, datetime, timezone
from enum import Enum
from pathlib import Path
from uuid import uuid4
from zoneinfo import ZoneInfo

from app.field_tracking import (
    ISTANBUL_TIMEZONE,
    RoutineOccurrence,
    RoutineOccurrenceEvent,
    RoutineOccurrenceEventType,
    RoutineOccurrenceOutcome,
    RoutineOccurrenceStatus,
    RoutineOccurrenceViewGroup,
    RoutineRecurrenceType,
    RoutineTemplate,
    RoutineTemplateEvent,
    RoutineTemplateEventType,
    RoutineTemplateStatus,
    classify_routine_occurrence,
    due_routine_dates,
    plan_routine_occurrence,
    validate_iso_weekday,
    validate_local_date,
    validate_local_time,
)
from app.persistence import (
    InvalidRecordError,
    RecordNotFound,
    RevisionConflict,
    SQLiteUnitOfWork,
    validate_record_id,
    validate_utc_timestamp,
)


TEMPLATE_UPDATE_FIELDS = (
    "description",
    "end_date",
    "is_important",
    "local_time",
    "month_day",
    "project_id",
    "recurrence_type",
    "start_date",
    "title",
    "weekdays",
)
USER_CLOSE_OUTCOMES = (
    RoutineOccurrenceOutcome.COMPLETED,
    RoutineOccurrenceOutcome.NO_WORK,
    RoutineOccurrenceOutcome.NOT_REQUIRED,
)


@dataclass(frozen=True, slots=True)
class CreateRoutineTemplate:
    title: str
    recurrence_type: RoutineRecurrenceType
    local_time: str
    start_date: str
    description: str | None = None
    project_id: str | None = None
    weekdays: frozenset[int] = frozenset()
    month_day: int | None = None
    end_date: str | None = None
    is_important: bool = False

    def __post_init__(self) -> None:
        _normalize_template_command(self)


@dataclass(frozen=True, slots=True)
class UpdateRoutineTemplate:
    title: str
    recurrence_type: RoutineRecurrenceType
    local_time: str
    start_date: str
    description: str | None = None
    project_id: str | None = None
    weekdays: frozenset[int] = frozenset()
    month_day: int | None = None
    end_date: str | None = None
    is_important: bool = False

    def __post_init__(self) -> None:
        _normalize_template_command(self)


@dataclass(frozen=True, slots=True)
class RoutineTemplateQuery:
    status: RoutineTemplateStatus | None = None
    project_id: str | None = None
    personal_only: bool = False

    def __post_init__(self) -> None:
        if self.status is not None:
            object.__setattr__(
                self,
                "status",
                _coerce_enum(self.status, RoutineTemplateStatus, "status"),
            )
        if self.project_id is not None:
            validate_record_id(self.project_id)
        if not isinstance(self.personal_only, bool):
            raise ValueError("personal_only must be a bool")
        if self.personal_only and self.project_id is not None:
            raise ValueError("personal_only and project_id cannot be used together")


class RoutineOccurrenceView(str, Enum):
    OVERDUE = "overdue"
    TODAY = "today"
    UPCOMING = "upcoming"


@dataclass(frozen=True, slots=True)
class RoutineOccurrenceQuery:
    routine_template_id: str | None = None
    status: RoutineOccurrenceStatus | None = None
    view: RoutineOccurrenceView | None = None
    as_of_utc: str | None = None

    def __post_init__(self) -> None:
        if self.routine_template_id is not None:
            validate_record_id(self.routine_template_id)
        if self.status is not None:
            object.__setattr__(
                self,
                "status",
                _coerce_enum(self.status, RoutineOccurrenceStatus, "status"),
            )
        if self.view is not None:
            object.__setattr__(
                self,
                "view",
                _coerce_enum(self.view, RoutineOccurrenceView, "view"),
            )
        if self.as_of_utc is not None:
            validate_utc_timestamp(self.as_of_utc)
        if self.view is not None and self.as_of_utc is None:
            raise ValueError(f"view={self.view.value} requires as_of_utc")


@dataclass(frozen=True, slots=True)
class CloseRoutineOccurrence:
    outcome_type: RoutineOccurrenceOutcome
    outcome_note: str | None = None

    def __post_init__(self) -> None:
        outcome_type = _coerce_enum(
            self.outcome_type, RoutineOccurrenceOutcome, "outcome_type"
        )
        if outcome_type not in USER_CLOSE_OUTCOMES:
            allowed = tuple(outcome.value for outcome in USER_CLOSE_OUTCOMES)
            raise ValueError(f"outcome_type must be one of {allowed}")
        object.__setattr__(self, "outcome_type", outcome_type)
        object.__setattr__(
            self,
            "outcome_note",
            _normalize_optional_text(self.outcome_note, "outcome_note"),
        )


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds").replace(
        "+00:00", "Z"
    )


class RoutineApplicationService:
    """Coordinate routine aggregates and append-only event persistence."""

    def __init__(
        self,
        database_path: str | Path,
        *,
        uow_factory: Callable[[], SQLiteUnitOfWork] | None = None,
        clock: Callable[[], str] = _utc_now,
        uuid_factory: Callable[[], str] = lambda: str(uuid4()),
        local_actor: str = "local-user",
    ) -> None:
        if not isinstance(local_actor, str) or not local_actor.strip():
            raise ValueError("local_actor must not be empty")
        self.database_path = Path(database_path)
        self._uow_factory = uow_factory or (
            lambda: SQLiteUnitOfWork(self.database_path)
        )
        self._clock = clock
        self._uuid_factory = uuid_factory
        self._local_actor = local_actor.strip()

    def create_template(self, command: CreateRoutineTemplate) -> RoutineTemplate:
        _require_instance(command, CreateRoutineTemplate, "command")
        with self._uow_factory() as unit_of_work:
            if command.project_id is not None:
                unit_of_work.projects.get(command.project_id)
            occurred_at = self._now()
            template = RoutineTemplate(
                routine_template_id=self._new_id(),
                title=command.title,
                description=command.description,
                project_id=command.project_id,
                recurrence_type=command.recurrence_type,
                local_time=command.local_time,
                weekdays=command.weekdays,
                month_day=command.month_day,
                start_date=command.start_date,
                end_date=command.end_date,
                is_important=command.is_important,
                created_at=occurred_at,
                updated_at=occurred_at,
            )
            unit_of_work.routine_templates.add(template)
            unit_of_work.routine_template_events.add(
                self._template_event(
                    template,
                    sequence=1,
                    event_type=RoutineTemplateEventType.CREATED,
                    occurred_at=occurred_at,
                    payload={
                        "local_time": template.local_time,
                        "project_id": template.project_id,
                        "recurrence_type": template.recurrence_type.value,
                        "revision": template.revision,
                        "status": template.status.value,
                    },
                )
            )
            unit_of_work.commit()
        return template

    def get_template(self, routine_template_id: str) -> RoutineTemplate:
        validate_record_id(routine_template_id)
        with self._uow_factory() as unit_of_work:
            return unit_of_work.routine_templates.get(routine_template_id)

    def list_templates(
        self, query: RoutineTemplateQuery
    ) -> tuple[RoutineTemplate, ...]:
        _require_instance(query, RoutineTemplateQuery, "query")
        with self._uow_factory() as unit_of_work:
            templates = tuple(unit_of_work.routine_templates.list_all())
        if query.status is not None:
            templates = tuple(
                template
                for template in templates
                if template.status == query.status
            )
        if query.project_id is not None:
            templates = tuple(
                template
                for template in templates
                if template.project_id == query.project_id
            )
        if query.personal_only:
            templates = tuple(
                template for template in templates if template.project_id is None
            )
        return templates

    def list_template_history(
        self, routine_template_id: str
    ) -> tuple[RoutineTemplateEvent, ...]:
        validate_record_id(routine_template_id)
        with self._uow_factory() as unit_of_work:
            unit_of_work.routine_templates.get(routine_template_id)
            return tuple(
                unit_of_work.routine_template_events.list_for_template(
                    routine_template_id
                )
            )

    def update_template(
        self,
        routine_template_id: str,
        expected_revision: int,
        command: UpdateRoutineTemplate,
    ) -> RoutineTemplate:
        validate_record_id(routine_template_id)
        _validate_expected_revision(expected_revision)
        _require_instance(command, UpdateRoutineTemplate, "command")
        with self._uow_factory() as unit_of_work:
            current = unit_of_work.routine_templates.get(routine_template_id)
            self._require_current_revision(
                current.routine_template_id,
                current.revision,
                expected_revision,
            )
            if current.status != RoutineTemplateStatus.ACTIVE:
                raise InvalidRecordError("inactive routine template cannot be updated")
            if command.project_id is not None:
                unit_of_work.projects.get(command.project_id)
            values = {
                field_name: getattr(command, field_name)
                for field_name in TEMPLATE_UPDATE_FIELDS
            }
            changed_fields = sorted(
                field_name
                for field_name, value in values.items()
                if getattr(current, field_name) != value
            )
            if not changed_fields:
                return current
            occurred_at = self._now()
            updated = replace(
                current,
                **values,
                revision=current.revision + 1,
                updated_at=occurred_at,
            )
            stored = unit_of_work.routine_templates.update(
                updated, expected_revision=expected_revision
            )
            unit_of_work.routine_template_events.add(
                self._template_event(
                    stored,
                    sequence=self._next_template_sequence(
                        unit_of_work, routine_template_id
                    ),
                    event_type=RoutineTemplateEventType.UPDATED,
                    occurred_at=occurred_at,
                    payload={
                        "changed_fields": changed_fields,
                        "revision": stored.revision,
                    },
                )
            )
            unit_of_work.commit()
            return stored

    def deactivate_template(
        self, routine_template_id: str, expected_revision: int
    ) -> RoutineTemplate:
        validate_record_id(routine_template_id)
        _validate_expected_revision(expected_revision)
        with self._uow_factory() as unit_of_work:
            current = unit_of_work.routine_templates.get(routine_template_id)
            self._require_current_revision(
                current.routine_template_id,
                current.revision,
                expected_revision,
            )
            if current.status == RoutineTemplateStatus.INACTIVE:
                return current
            occurred_at = self._now()
            updated = replace(
                current,
                status=RoutineTemplateStatus.INACTIVE,
                deactivated_at=occurred_at,
                updated_at=occurred_at,
                revision=current.revision + 1,
            )
            stored = unit_of_work.routine_templates.update(
                updated, expected_revision=expected_revision
            )
            unit_of_work.routine_template_events.add(
                self._template_event(
                    stored,
                    sequence=self._next_template_sequence(
                        unit_of_work, routine_template_id
                    ),
                    event_type=RoutineTemplateEventType.DEACTIVATED,
                    occurred_at=occurred_at,
                    payload={
                        "deactivated_at": stored.deactivated_at,
                        "from_status": current.status.value,
                        "revision": stored.revision,
                        "status": stored.status.value,
                    },
                )
            )
            unit_of_work.commit()
            return stored

    def ensure_occurrences(self, as_of_utc: str) -> tuple[RoutineOccurrence, ...]:
        validate_utc_timestamp(as_of_utc)
        today_local = _istanbul_date(as_of_utc)
        ensured: list[RoutineOccurrence] = []
        with self._uow_factory() as unit_of_work:
            templates = tuple(unit_of_work.routine_templates.list_all())
            for template in templates:
                for local_date in due_routine_dates(template, today_local):
                    local_date_text = local_date.isoformat()
                    try:
                        existing = unit_of_work.routine_occurrences.get_by_template_date(
                            template.routine_template_id, local_date_text
                        )
                    except RecordNotFound:
                        pass
                    else:
                        ensured.append(existing)
                        continue

                    plan = plan_routine_occurrence(
                        template, local_date, today_local
                    )
                    created_at = self._now()
                    candidate = RoutineOccurrence(
                        routine_occurrence_id=self._new_id(),
                        routine_template_id=template.routine_template_id,
                        occurrence_local_date=plan.schedule.occurrence_local_date,
                        scheduled_local_time=plan.schedule.scheduled_local_time,
                        scheduled_at_utc=plan.schedule.scheduled_at_utc,
                        status=RoutineOccurrenceStatus.OPEN,
                        next_attention_at=plan.schedule.next_attention_at,
                        revision=1,
                        created_at=created_at,
                    )
                    stored = unit_of_work.routine_occurrences.add_if_absent(candidate)
                    if stored.routine_occurrence_id != candidate.routine_occurrence_id:
                        ensured.append(stored)
                        continue

                    unit_of_work.routine_occurrence_events.add(
                        self._occurrence_event(
                            stored,
                            sequence=1,
                            event_type=RoutineOccurrenceEventType.CREATED,
                            occurred_at=created_at,
                            payload={
                                "occurrence_local_date": stored.occurrence_local_date,
                                "revision": stored.revision,
                                "routine_template_id": stored.routine_template_id,
                                "scheduled_at_utc": stored.scheduled_at_utc,
                                "status": stored.status.value,
                            },
                        )
                    )
                    if plan.status == RoutineOccurrenceStatus.CLOSED:
                        missed_at = self._now()
                        missed = replace(
                            stored,
                            status=RoutineOccurrenceStatus.CLOSED,
                            outcome_type=RoutineOccurrenceOutcome.MISSED,
                            outcome_note=None,
                            completed_at=missed_at,
                            revision=stored.revision + 1,
                        )
                        stored = unit_of_work.routine_occurrences.update(
                            missed, expected_revision=1
                        )
                        unit_of_work.routine_occurrence_events.add(
                            self._occurrence_event(
                                stored,
                                sequence=self._next_occurrence_sequence(
                                    unit_of_work, stored.routine_occurrence_id
                                ),
                                event_type=RoutineOccurrenceEventType.MISSED,
                                occurred_at=missed_at,
                                payload={
                                    "from_status": RoutineOccurrenceStatus.OPEN.value,
                                    "occurrence_local_date": (
                                        stored.occurrence_local_date
                                    ),
                                    "outcome_type": stored.outcome_type.value,
                                    "revision": stored.revision,
                                },
                            )
                        )
                    ensured.append(stored)
            unit_of_work.commit()
        return tuple(
            sorted(
                ensured,
                key=lambda occurrence: (
                    occurrence.occurrence_local_date,
                    occurrence.routine_template_id,
                    occurrence.routine_occurrence_id,
                ),
            )
        )

    def list_occurrences(
        self, query: RoutineOccurrenceQuery
    ) -> tuple[RoutineOccurrence, ...]:
        _require_instance(query, RoutineOccurrenceQuery, "query")
        with self._uow_factory() as unit_of_work:
            if query.routine_template_id is not None:
                unit_of_work.routine_templates.get(query.routine_template_id)
                occurrences = tuple(
                    unit_of_work.routine_occurrences.list_for_template(
                        query.routine_template_id
                    )
                )
            elif query.status is not None:
                occurrences = tuple(
                    unit_of_work.routine_occurrences.list_by_status(query.status)
                )
            else:
                occurrences = tuple(
                    occurrence
                    for template in unit_of_work.routine_templates.list_all()
                    for occurrence in unit_of_work.routine_occurrences.list_for_template(
                        template.routine_template_id
                    )
                )

        if query.status is not None:
            occurrences = tuple(
                occurrence
                for occurrence in occurrences
                if occurrence.status == query.status
            )
        if query.view is not None:
            if query.as_of_utc is None:
                raise ValueError(f"view={query.view.value} requires as_of_utc")
            expected_group = RoutineOccurrenceViewGroup(query.view.value)
            occurrences = tuple(
                occurrence
                for occurrence in occurrences
                if classify_routine_occurrence(occurrence, query.as_of_utc)
                == expected_group
            )
        return tuple(
            sorted(
                occurrences,
                key=lambda occurrence: (
                    occurrence.occurrence_local_date,
                    occurrence.routine_occurrence_id,
                ),
            )
        )

    def list_occurrence_history(
        self, routine_occurrence_id: str
    ) -> tuple[RoutineOccurrenceEvent, ...]:
        validate_record_id(routine_occurrence_id)
        with self._uow_factory() as unit_of_work:
            unit_of_work.routine_occurrences.get(routine_occurrence_id)
            return tuple(
                unit_of_work.routine_occurrence_events.list_for_occurrence(
                    routine_occurrence_id
                )
            )

    def snooze_occurrence(
        self,
        routine_occurrence_id: str,
        expected_revision: int,
        next_attention_at: str,
    ) -> RoutineOccurrence:
        validate_record_id(routine_occurrence_id)
        _validate_expected_revision(expected_revision)
        validate_utc_timestamp(next_attention_at)
        with self._uow_factory() as unit_of_work:
            current = unit_of_work.routine_occurrences.get(routine_occurrence_id)
            self._require_current_revision(
                current.routine_occurrence_id,
                current.revision,
                expected_revision,
            )
            if current.status != RoutineOccurrenceStatus.OPEN:
                raise InvalidRecordError("only open routine occurrence can be snoozed")
            if current.next_attention_at == next_attention_at:
                return current
            occurred_at = self._now()
            updated = replace(
                current,
                next_attention_at=next_attention_at,
                revision=current.revision + 1,
            )
            stored = unit_of_work.routine_occurrences.update(
                updated, expected_revision=expected_revision
            )
            unit_of_work.routine_occurrence_events.add(
                self._occurrence_event(
                    stored,
                    sequence=self._next_occurrence_sequence(
                        unit_of_work, routine_occurrence_id
                    ),
                    event_type=RoutineOccurrenceEventType.SNOOZED,
                    occurred_at=occurred_at,
                    payload={
                        "next_attention_at": stored.next_attention_at,
                        "previous_next_attention_at": current.next_attention_at,
                        "revision": stored.revision,
                    },
                )
            )
            unit_of_work.commit()
            return stored

    def close_occurrence(
        self,
        routine_occurrence_id: str,
        expected_revision: int,
        command: CloseRoutineOccurrence,
    ) -> RoutineOccurrence:
        validate_record_id(routine_occurrence_id)
        _validate_expected_revision(expected_revision)
        _require_instance(command, CloseRoutineOccurrence, "command")
        with self._uow_factory() as unit_of_work:
            current = unit_of_work.routine_occurrences.get(routine_occurrence_id)
            self._require_current_revision(
                current.routine_occurrence_id,
                current.revision,
                expected_revision,
            )
            if current.status != RoutineOccurrenceStatus.OPEN:
                raise InvalidRecordError("only open routine occurrence can be closed")
            occurred_at = self._now()
            updated = replace(
                current,
                status=RoutineOccurrenceStatus.CLOSED,
                outcome_type=command.outcome_type,
                outcome_note=command.outcome_note,
                completed_at=occurred_at,
                revision=current.revision + 1,
            )
            stored = unit_of_work.routine_occurrences.update(
                updated, expected_revision=expected_revision
            )
            event_types = {
                RoutineOccurrenceOutcome.COMPLETED: (
                    RoutineOccurrenceEventType.COMPLETED
                ),
                RoutineOccurrenceOutcome.NO_WORK: RoutineOccurrenceEventType.NO_WORK,
                RoutineOccurrenceOutcome.NOT_REQUIRED: (
                    RoutineOccurrenceEventType.NOT_REQUIRED
                ),
            }
            unit_of_work.routine_occurrence_events.add(
                self._occurrence_event(
                    stored,
                    sequence=self._next_occurrence_sequence(
                        unit_of_work, routine_occurrence_id
                    ),
                    event_type=event_types[command.outcome_type],
                    occurred_at=occurred_at,
                    payload={
                        "from_status": current.status.value,
                        "outcome_note": stored.outcome_note,
                        "outcome_type": stored.outcome_type.value,
                        "revision": stored.revision,
                    },
                )
            )
            unit_of_work.commit()
            return stored

    def reopen_occurrence(
        self,
        routine_occurrence_id: str,
        expected_revision: int,
        next_attention_at: str,
    ) -> RoutineOccurrence:
        validate_record_id(routine_occurrence_id)
        _validate_expected_revision(expected_revision)
        validate_utc_timestamp(next_attention_at)
        with self._uow_factory() as unit_of_work:
            current = unit_of_work.routine_occurrences.get(routine_occurrence_id)
            self._require_current_revision(
                current.routine_occurrence_id,
                current.revision,
                expected_revision,
            )
            if current.status != RoutineOccurrenceStatus.CLOSED:
                raise InvalidRecordError("only closed routine occurrence can be reopened")
            occurred_at = self._now()
            previous_outcome_type = current.outcome_type
            updated = replace(
                current,
                status=RoutineOccurrenceStatus.OPEN,
                outcome_type=None,
                outcome_note=None,
                completed_at=None,
                next_attention_at=next_attention_at,
                revision=current.revision + 1,
            )
            stored = unit_of_work.routine_occurrences.update(
                updated, expected_revision=expected_revision
            )
            unit_of_work.routine_occurrence_events.add(
                self._occurrence_event(
                    stored,
                    sequence=self._next_occurrence_sequence(
                        unit_of_work, routine_occurrence_id
                    ),
                    event_type=RoutineOccurrenceEventType.REOPENED,
                    occurred_at=occurred_at,
                    payload={
                        "next_attention_at": stored.next_attention_at,
                        "previous_outcome_type": previous_outcome_type.value,
                        "revision": stored.revision,
                        "status": stored.status.value,
                    },
                )
            )
            unit_of_work.commit()
            return stored

    def _template_event(
        self,
        template: RoutineTemplate,
        *,
        sequence: int,
        event_type: RoutineTemplateEventType,
        occurred_at: str,
        payload: dict[str, object],
    ) -> RoutineTemplateEvent:
        return RoutineTemplateEvent(
            event_id=self._new_id(),
            routine_template_id=template.routine_template_id,
            sequence=sequence,
            event_type=event_type,
            actor=self._local_actor,
            occurred_at=occurred_at,
            payload=payload,
        )

    def _occurrence_event(
        self,
        occurrence: RoutineOccurrence,
        *,
        sequence: int,
        event_type: RoutineOccurrenceEventType,
        occurred_at: str,
        payload: dict[str, object],
    ) -> RoutineOccurrenceEvent:
        return RoutineOccurrenceEvent(
            event_id=self._new_id(),
            routine_occurrence_id=occurrence.routine_occurrence_id,
            sequence=sequence,
            event_type=event_type,
            actor=self._local_actor,
            occurred_at=occurred_at,
            payload=payload,
        )

    @staticmethod
    def _next_template_sequence(
        unit_of_work: SQLiteUnitOfWork, routine_template_id: str
    ) -> int:
        history = unit_of_work.routine_template_events.list_for_template(
            routine_template_id
        )
        return history[-1].sequence + 1 if history else 1

    @staticmethod
    def _next_occurrence_sequence(
        unit_of_work: SQLiteUnitOfWork, routine_occurrence_id: str
    ) -> int:
        history = unit_of_work.routine_occurrence_events.list_for_occurrence(
            routine_occurrence_id
        )
        return history[-1].sequence + 1 if history else 1

    @staticmethod
    def _require_current_revision(
        record_id: str, actual_revision: int, expected_revision: int
    ) -> None:
        if actual_revision != expected_revision:
            raise RevisionConflict(record_id, expected_revision, actual_revision)

    def _now(self) -> str:
        value = self._clock()
        validate_utc_timestamp(value)
        return value

    def _new_id(self) -> str:
        value = self._uuid_factory()
        validate_record_id(value)
        return value


def _normalize_template_command(
    command: CreateRoutineTemplate | UpdateRoutineTemplate,
) -> None:
    object.__setattr__(command, "title", _normalize_title(command.title))
    object.__setattr__(
        command,
        "description",
        _normalize_optional_text(command.description, "description"),
    )
    recurrence_type = _coerce_enum(
        command.recurrence_type, RoutineRecurrenceType, "recurrence_type"
    )
    object.__setattr__(command, "recurrence_type", recurrence_type)
    validate_local_time(command.local_time)
    validate_local_date(command.start_date)
    if command.end_date is not None:
        validate_local_date(command.end_date)
        if date.fromisoformat(command.end_date) < date.fromisoformat(
            command.start_date
        ):
            raise ValueError("end_date cannot be before start_date")
    if command.project_id is not None:
        validate_record_id(command.project_id)
    if isinstance(command.weekdays, (str, bytes)):
        raise ValueError("weekdays must be a collection of ISO weekdays")
    try:
        weekdays = frozenset(command.weekdays)
    except TypeError as exc:
        raise ValueError("weekdays must be a collection of ISO weekdays") from exc
    for weekday in weekdays:
        validate_iso_weekday(weekday)
    object.__setattr__(command, "weekdays", weekdays)
    if recurrence_type == RoutineRecurrenceType.WEEKLY:
        if not weekdays:
            raise ValueError("weekly recurrence requires at least one ISO weekday")
    elif weekdays:
        raise ValueError("only weekly recurrence may define weekdays")
    if recurrence_type == RoutineRecurrenceType.MONTHLY:
        if (
            isinstance(command.month_day, bool)
            or not isinstance(command.month_day, int)
            or not 1 <= command.month_day <= 31
        ):
            raise ValueError("monthly recurrence requires month_day from 1 through 31")
    elif command.month_day is not None:
        raise ValueError("only monthly recurrence may define month_day")
    if not isinstance(command.is_important, bool):
        raise ValueError("is_important must be a bool")


def _normalize_title(value: str) -> str:
    if not isinstance(value, str):
        raise ValueError("title must be a string")
    normalized = " ".join(value.split())
    if not normalized:
        raise ValueError("title must not be empty")
    return normalized


def _normalize_optional_text(value: object, field_name: str) -> str | None:
    if value is None:
        return None
    if not isinstance(value, str):
        raise ValueError(f"{field_name} must be a string or None")
    normalized = value.strip()
    return normalized or None


def _coerce_enum(value: object, enum_type: type[Enum], field_name: str) -> Enum:
    try:
        return enum_type(value)
    except (TypeError, ValueError) as exc:
        allowed = tuple(member.value for member in enum_type)
        raise ValueError(f"{field_name} must be one of {allowed}") from exc


def _validate_expected_revision(value: int) -> None:
    if isinstance(value, bool) or not isinstance(value, int) or value < 1:
        raise InvalidRecordError(
            "expected_revision must be an integer greater than or equal to 1"
        )


def _istanbul_date(value: str) -> date:
    validate_utc_timestamp(value)
    return datetime.fromisoformat(f"{value[:-1]}+00:00").astimezone(
        ZoneInfo(ISTANBUL_TIMEZONE)
    ).date()


def _require_instance(value: object, expected_type: type[object], name: str) -> None:
    if not isinstance(value, expected_type):
        raise TypeError(f"{name} must be {expected_type.__name__}")


__all__ = [
    "CloseRoutineOccurrence",
    "CreateRoutineTemplate",
    "RoutineApplicationService",
    "RoutineOccurrenceQuery",
    "RoutineOccurrenceView",
    "RoutineTemplateQuery",
    "UpdateRoutineTemplate",
]
