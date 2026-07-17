"""Saha Takibi domain records and pure recurrence calculations.

This module deliberately has no database, clock, file-system, or UI dependency.
Callers provide identifiers, timestamps, local dates, and the current time
explicitly. Persistence and application-service behavior belong to later tasks.
"""

from __future__ import annotations

import json
from collections.abc import Iterable, Mapping
from dataclasses import dataclass, field
from datetime import date, datetime, time, timedelta, timezone
from enum import Enum
from zoneinfo import ZoneInfo

from app.persistence.contracts import (
    serialize_utc_timestamp,
    validate_record_id,
    validate_utc_timestamp,
)
from app.persistence.records import serialize_event_payload
from app.time_contracts import ISTANBUL_TIMEZONE_NAME


ISTANBUL_TIMEZONE = ISTANBUL_TIMEZONE_NAME
SUPPORTED_TIMEZONES: tuple[str, ...] = (ISTANBUL_TIMEZONE,)


class FollowUpItemType(str, Enum):
    ACTION = "action"
    WAITING = "waiting"
    RECHECK = "recheck"


class FollowUpStatus(str, Enum):
    INBOX = "inbox"
    ACTIVE = "active"
    WAITING = "waiting"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class FollowUpOutcome(str, Enum):
    COMPLETED = "completed"
    NOT_REQUIRED = "not_required"
    CONVERTED_TO_OBSERVATION = "converted_to_observation"
    CANCELLED = "cancelled"


class RoutineRecurrenceType(str, Enum):
    DAILY = "daily"
    WEEKDAYS = "weekdays"
    WEEKLY = "weekly"
    MONTHLY = "monthly"


class RoutineTemplateStatus(str, Enum):
    ACTIVE = "active"
    INACTIVE = "inactive"


class RoutineOccurrenceStatus(str, Enum):
    OPEN = "open"
    CLOSED = "closed"


class RoutineOccurrenceOutcome(str, Enum):
    COMPLETED = "completed"
    NO_WORK = "no_work"
    NOT_REQUIRED = "not_required"
    MISSED = "missed"


class FollowUpEventType(str, Enum):
    CREATED = "follow_up.created"
    SCHEDULED = "follow_up.scheduled"
    RESCHEDULED = "follow_up.rescheduled"
    WAITING_STARTED = "follow_up.waiting_started"
    COMPLETED = "follow_up.completed"
    CANCELLED = "follow_up.cancelled"
    REOPENED = "follow_up.reopened"
    OBSERVATION_LINKED = "follow_up.observation_linked"
    CONVERTED_TO_OBSERVATION = "follow_up.converted_to_observation"
    DETAILS_UPDATED = "follow_up.details_updated"
    MOVED_TO_INBOX = "follow_up.moved_to_inbox"
    PROJECT_CHANGED = "follow_up.project_changed"


class RoutineTemplateEventType(str, Enum):
    CREATED = "routine_template.created"
    UPDATED = "routine_template.updated"
    DEACTIVATED = "routine_template.deactivated"


class RoutineOccurrenceEventType(str, Enum):
    CREATED = "routine_occurrence.created"
    SNOOZED = "routine_occurrence.snoozed"
    COMPLETED = "routine_occurrence.completed"
    NO_WORK = "routine_occurrence.no_work"
    NOT_REQUIRED = "routine_occurrence.not_required"
    MISSED = "routine_occurrence.missed"
    REOPENED = "routine_occurrence.reopened"


class FollowUpViewGroup(str, Enum):
    INBOX = "inbox"
    OVERDUE = "overdue"
    TODAY = "today"
    UPCOMING = "upcoming"


class RoutineOccurrenceViewGroup(str, Enum):
    OVERDUE = "overdue"
    TODAY = "today"
    UPCOMING = "upcoming"


FOLLOW_UP_EVENT_TYPES = tuple(value.value for value in FollowUpEventType)
ROUTINE_TEMPLATE_EVENT_TYPES = tuple(
    value.value for value in RoutineTemplateEventType
)
ROUTINE_OCCURRENCE_EVENT_TYPES = tuple(
    value.value for value in RoutineOccurrenceEventType
)


def normalize_capture_text(value: str) -> str:
    """Normalize quick-capture whitespace without changing written meaning."""

    if not isinstance(value, str):
        raise ValueError("capture_text must be a string")
    normalized = " ".join(value.split())
    if not normalized:
        raise ValueError("capture_text must not be empty")
    return normalized


def validate_local_date(value: str) -> str:
    """Return an exact ``YYYY-MM-DD`` local date or raise ``ValueError``."""

    if not isinstance(value, str) or value != value.strip():
        raise ValueError("local date must use YYYY-MM-DD")
    try:
        parsed = date.fromisoformat(value)
    except ValueError as exc:
        raise ValueError("local date must use YYYY-MM-DD") from exc
    if parsed.isoformat() != value:
        raise ValueError("local date must use YYYY-MM-DD")
    return value


def validate_local_time(value: str) -> str:
    """Return an exact 24-hour ``HH:MM`` local time or raise ``ValueError``."""

    if not isinstance(value, str) or len(value) != 5:
        raise ValueError("local time must use HH:MM")
    try:
        parsed = time.fromisoformat(value)
    except ValueError as exc:
        raise ValueError("local time must use HH:MM") from exc
    if parsed.second or parsed.microsecond or parsed.strftime("%H:%M") != value:
        raise ValueError("local time must use HH:MM")
    return value


def validate_timezone(value: str) -> str:
    """Validate the v0.1 timezone allowlist."""

    if value not in SUPPORTED_TIMEZONES:
        raise ValueError(f"timezone must be one of {SUPPORTED_TIMEZONES}")
    return value


def validate_iso_weekday(value: int) -> int:
    """Return an ISO weekday from Monday=1 through Sunday=7."""

    if isinstance(value, bool) or not isinstance(value, int) or not 1 <= value <= 7:
        raise ValueError("ISO weekday must be an integer from 1 through 7")
    return value


@dataclass(frozen=True, slots=True)
class FollowUpItem:
    follow_up_id: str
    capture_text: str
    title: str
    created_at: str
    updated_at: str
    description: str | None = None
    item_type: FollowUpItemType = FollowUpItemType.ACTION
    status: FollowUpStatus = FollowUpStatus.INBOX
    project_id: str | None = None
    observation_id: str | None = None
    location: str | None = None
    related_person: str | None = None
    is_important: bool = False
    next_attention_at: str | None = None
    deadline_at: str | None = None
    condition_text: str | None = None
    outcome_type: FollowUpOutcome | None = None
    outcome_note: str | None = None
    revision: int = 1
    completed_at: str | None = None
    cancelled_at: str | None = None

    def __post_init__(self) -> None:
        validate_record_id(self.follow_up_id)
        object.__setattr__(self, "capture_text", normalize_capture_text(self.capture_text))
        _require_non_empty_text(self.title, "title")
        object.__setattr__(
            self, "item_type", _coerce_enum(self.item_type, FollowUpItemType, "item_type")
        )
        object.__setattr__(
            self, "status", _coerce_enum(self.status, FollowUpStatus, "status")
        )
        if self.outcome_type is not None:
            object.__setattr__(
                self,
                "outcome_type",
                _coerce_enum(self.outcome_type, FollowUpOutcome, "outcome_type"),
            )

        for field_name in (
            "description",
            "location",
            "related_person",
            "condition_text",
            "outcome_note",
        ):
            _validate_optional_text(getattr(self, field_name), field_name)

        _validate_optional_record_id(self.project_id, "project_id")
        _validate_optional_record_id(self.observation_id, "observation_id")
        if self.observation_id is not None and self.project_id is None:
            raise ValueError("observation_id requires project_id")

        _require_bool(self.is_important, "is_important")
        _validate_revision(self.revision)
        for timestamp in (
            self.created_at,
            self.updated_at,
            self.next_attention_at,
            self.deadline_at,
            self.completed_at,
            self.cancelled_at,
        ):
            if timestamp is not None:
                validate_utc_timestamp(timestamp)

        if self.status in (FollowUpStatus.ACTIVE, FollowUpStatus.WAITING):
            if self.next_attention_at is None:
                raise ValueError("active and waiting follow-ups require next_attention_at")

        if self.status == FollowUpStatus.COMPLETED:
            if self.completed_at is None or self.outcome_type is None:
                raise ValueError("completed follow-up requires outcome_type and completed_at")
            if self.cancelled_at is not None:
                raise ValueError("completed follow-up cannot have cancelled_at")
            if self.outcome_type == FollowUpOutcome.CANCELLED:
                raise ValueError("completed follow-up cannot use cancelled outcome")
        elif self.status == FollowUpStatus.CANCELLED:
            if (
                self.cancelled_at is None
                or self.outcome_type != FollowUpOutcome.CANCELLED
            ):
                raise ValueError(
                    "cancelled follow-up requires cancelled outcome and cancelled_at"
                )
            if self.completed_at is not None:
                raise ValueError("cancelled follow-up cannot have completed_at")
        elif any(
            value is not None
            for value in (
                self.outcome_type,
                self.outcome_note,
                self.completed_at,
                self.cancelled_at,
            )
        ):
            raise ValueError("non-terminal follow-up cannot have outcome fields")


def create_follow_up_item(
    *, follow_up_id: str, capture_text: str, created_at: str
) -> FollowUpItem:
    """Build the deterministic initial record for the quick ``+ Unutma`` flow."""

    normalized = normalize_capture_text(capture_text)
    return FollowUpItem(
        follow_up_id=follow_up_id,
        capture_text=normalized,
        title=normalized,
        created_at=created_at,
        updated_at=created_at,
    )


@dataclass(frozen=True, slots=True)
class RoutineTemplate:
    routine_template_id: str
    title: str
    recurrence_type: RoutineRecurrenceType
    local_time: str
    start_date: str
    created_at: str
    updated_at: str
    description: str | None = None
    project_id: str | None = None
    timezone: str = ISTANBUL_TIMEZONE
    weekdays: frozenset[int] = field(default_factory=frozenset)
    month_day: int | None = None
    end_date: str | None = None
    status: RoutineTemplateStatus = RoutineTemplateStatus.ACTIVE
    is_important: bool = False
    revision: int = 1
    deactivated_at: str | None = None

    def __post_init__(self) -> None:
        validate_record_id(self.routine_template_id)
        _require_non_empty_text(self.title, "title")
        _validate_optional_text(self.description, "description")
        _validate_optional_record_id(self.project_id, "project_id")
        object.__setattr__(
            self,
            "recurrence_type",
            _coerce_enum(
                self.recurrence_type, RoutineRecurrenceType, "recurrence_type"
            ),
        )
        object.__setattr__(
            self,
            "status",
            _coerce_enum(self.status, RoutineTemplateStatus, "status"),
        )
        validate_local_time(self.local_time)
        validate_timezone(self.timezone)
        start = _local_date_from_string(self.start_date)
        end = (
            _local_date_from_string(self.end_date)
            if self.end_date is not None
            else None
        )
        if end is not None and end < start:
            raise ValueError("end_date cannot be before start_date")

        if isinstance(self.weekdays, (str, bytes)):
            raise ValueError("weekdays must be a collection of ISO weekdays")
        try:
            normalized_weekdays = frozenset(self.weekdays)
        except TypeError as exc:
            raise ValueError("weekdays must be a collection of ISO weekdays") from exc
        for weekday in normalized_weekdays:
            validate_iso_weekday(weekday)
        object.__setattr__(self, "weekdays", normalized_weekdays)

        if self.recurrence_type == RoutineRecurrenceType.WEEKLY:
            if not self.weekdays:
                raise ValueError("weekly recurrence requires at least one ISO weekday")
        elif self.weekdays:
            raise ValueError("only weekly recurrence may define weekdays")

        if self.recurrence_type == RoutineRecurrenceType.MONTHLY:
            if (
                isinstance(self.month_day, bool)
                or not isinstance(self.month_day, int)
                or not 1 <= self.month_day <= 31
            ):
                raise ValueError("monthly recurrence requires month_day from 1 through 31")
        elif self.month_day is not None:
            raise ValueError("only monthly recurrence may define month_day")

        _require_bool(self.is_important, "is_important")
        _validate_revision(self.revision)
        validate_utc_timestamp(self.created_at)
        validate_utc_timestamp(self.updated_at)
        if self.deactivated_at is not None:
            validate_utc_timestamp(self.deactivated_at)
        if self.status == RoutineTemplateStatus.INACTIVE:
            if self.deactivated_at is None:
                raise ValueError("inactive template requires deactivated_at")
        elif self.deactivated_at is not None:
            raise ValueError("active template cannot have deactivated_at")


@dataclass(frozen=True, slots=True)
class RoutineOccurrence:
    routine_occurrence_id: str
    routine_template_id: str
    occurrence_local_date: str
    scheduled_local_time: str
    scheduled_at_utc: str
    status: RoutineOccurrenceStatus
    next_attention_at: str
    revision: int
    created_at: str
    outcome_type: RoutineOccurrenceOutcome | None = None
    outcome_note: str | None = None
    completed_at: str | None = None

    def __post_init__(self) -> None:
        validate_record_id(self.routine_occurrence_id)
        validate_record_id(self.routine_template_id)
        validate_local_date(self.occurrence_local_date)
        validate_local_time(self.scheduled_local_time)
        validate_utc_timestamp(self.scheduled_at_utc)
        validate_utc_timestamp(self.next_attention_at)
        validate_utc_timestamp(self.created_at)
        object.__setattr__(
            self,
            "status",
            _coerce_enum(self.status, RoutineOccurrenceStatus, "status"),
        )
        if self.outcome_type is not None:
            object.__setattr__(
                self,
                "outcome_type",
                _coerce_enum(
                    self.outcome_type, RoutineOccurrenceOutcome, "outcome_type"
                ),
            )
        _validate_revision(self.revision)
        if self.completed_at is not None:
            validate_utc_timestamp(self.completed_at)
        _validate_optional_text(self.outcome_note, "outcome_note")
        expected_schedule = _scheduled_utc_snapshot(
            self.occurrence_local_date, self.scheduled_local_time
        )
        if self.scheduled_at_utc != expected_schedule:
            raise ValueError(
                "scheduled_at_utc must match Istanbul local date and time snapshot"
            )

        if self.status == RoutineOccurrenceStatus.OPEN:
            if any(
                value is not None
                for value in (self.outcome_type, self.outcome_note, self.completed_at)
            ):
                raise ValueError("open occurrence cannot have outcome fields")
        elif self.outcome_type is None or self.completed_at is None:
            raise ValueError("closed occurrence requires outcome_type and completed_at")


@dataclass(frozen=True, slots=True)
class RoutineOccurrenceSchedule:
    occurrence_local_date: str
    scheduled_local_time: str
    scheduled_at_utc: str
    next_attention_at: str

    def __post_init__(self) -> None:
        validate_local_date(self.occurrence_local_date)
        validate_local_time(self.scheduled_local_time)
        validate_utc_timestamp(self.scheduled_at_utc)
        validate_utc_timestamp(self.next_attention_at)
        expected_schedule = _scheduled_utc_snapshot(
            self.occurrence_local_date, self.scheduled_local_time
        )
        if self.scheduled_at_utc != expected_schedule:
            raise ValueError(
                "scheduled_at_utc must match Istanbul local date and time snapshot"
            )
        if self.next_attention_at != self.scheduled_at_utc:
            raise ValueError("initial next_attention_at must equal scheduled_at_utc")


@dataclass(frozen=True, slots=True)
class RoutineOccurrencePlan:
    schedule: RoutineOccurrenceSchedule
    status: RoutineOccurrenceStatus
    outcome_type: RoutineOccurrenceOutcome | None

    def __post_init__(self) -> None:
        object.__setattr__(
            self,
            "status",
            _coerce_enum(self.status, RoutineOccurrenceStatus, "status"),
        )
        if self.outcome_type is not None:
            object.__setattr__(
                self,
                "outcome_type",
                _coerce_enum(
                    self.outcome_type, RoutineOccurrenceOutcome, "outcome_type"
                ),
            )
        if self.status == RoutineOccurrenceStatus.OPEN and self.outcome_type is not None:
            raise ValueError("open plan cannot have an outcome")
        if (
            self.status == RoutineOccurrenceStatus.CLOSED
            and self.outcome_type != RoutineOccurrenceOutcome.MISSED
        ):
            raise ValueError("backfill closed plan must use missed outcome")


@dataclass(frozen=True, slots=True)
class FollowUpEvent:
    event_id: str
    follow_up_id: str
    sequence: int
    event_type: FollowUpEventType
    actor: str
    occurred_at: str
    payload: Mapping[str, object] = field(default_factory=dict)

    def __post_init__(self) -> None:
        _validate_event_identity(self.event_id, self.follow_up_id, self.sequence)
        object.__setattr__(
            self,
            "event_type",
            _coerce_enum(self.event_type, FollowUpEventType, "event_type"),
        )
        _validate_event_details(self.actor, self.occurred_at)
        object.__setattr__(self, "payload", _canonical_payload(self.payload))

    @property
    def payload_json(self) -> str:
        return serialize_event_payload(self.payload)


@dataclass(frozen=True, slots=True)
class RoutineTemplateEvent:
    event_id: str
    routine_template_id: str
    sequence: int
    event_type: RoutineTemplateEventType
    actor: str
    occurred_at: str
    payload: Mapping[str, object] = field(default_factory=dict)

    def __post_init__(self) -> None:
        _validate_event_identity(
            self.event_id, self.routine_template_id, self.sequence
        )
        object.__setattr__(
            self,
            "event_type",
            _coerce_enum(self.event_type, RoutineTemplateEventType, "event_type"),
        )
        _validate_event_details(self.actor, self.occurred_at)
        object.__setattr__(self, "payload", _canonical_payload(self.payload))

    @property
    def payload_json(self) -> str:
        return serialize_event_payload(self.payload)


@dataclass(frozen=True, slots=True)
class RoutineOccurrenceEvent:
    event_id: str
    routine_occurrence_id: str
    sequence: int
    event_type: RoutineOccurrenceEventType
    actor: str
    occurred_at: str
    payload: Mapping[str, object] = field(default_factory=dict)

    def __post_init__(self) -> None:
        _validate_event_identity(
            self.event_id, self.routine_occurrence_id, self.sequence
        )
        object.__setattr__(
            self,
            "event_type",
            _coerce_enum(self.event_type, RoutineOccurrenceEventType, "event_type"),
        )
        _validate_event_details(self.actor, self.occurred_at)
        object.__setattr__(self, "payload", _canonical_payload(self.payload))

    @property
    def payload_json(self) -> str:
        return serialize_event_payload(self.payload)


def matches_routine_date(template: RoutineTemplate, local_date: date) -> bool:
    """Return whether a template may produce one explicit local date."""

    local_date = _require_date(local_date, "local_date")
    if template.status == RoutineTemplateStatus.INACTIVE:
        deactivation_local_date = _istanbul_local_date(template.deactivated_at)
        if local_date >= deactivation_local_date:
            return False
    start = _local_date_from_string(template.start_date)
    end = (
        _local_date_from_string(template.end_date)
        if template.end_date is not None
        else None
    )
    if local_date < start or (end is not None and local_date > end):
        return False
    if template.recurrence_type == RoutineRecurrenceType.DAILY:
        return True
    if template.recurrence_type == RoutineRecurrenceType.WEEKDAYS:
        return local_date.isoweekday() <= 5
    if template.recurrence_type == RoutineRecurrenceType.WEEKLY:
        return local_date.isoweekday() in template.weekdays
    return local_date.day == template.month_day


def due_routine_dates(
    template: RoutineTemplate, today_local: date, window_days: int = 7
) -> tuple[date, ...]:
    """Return matching dates in the bounded window ending on ``today_local``."""

    today_local = _require_date(today_local, "today_local")
    if (
        isinstance(window_days, bool)
        or not isinstance(window_days, int)
        or window_days < 1
    ):
        raise ValueError("window_days must be an integer greater than or equal to 1")
    first_day = today_local - timedelta(days=window_days - 1)
    return tuple(
        candidate
        for offset in range(window_days)
        if matches_routine_date(
            template, candidate := first_day + timedelta(days=offset)
        )
    )


def build_occurrence_schedule(
    template: RoutineTemplate, local_date: date
) -> RoutineOccurrenceSchedule:
    """Build deterministic local and UTC schedule snapshots for one due date."""

    local_date = _require_date(local_date, "local_date")
    if not matches_routine_date(template, local_date):
        raise ValueError("template does not match local_date")
    local_clock = time.fromisoformat(template.local_time)
    local_timestamp = datetime.combine(
        local_date, local_clock, tzinfo=ZoneInfo(template.timezone)
    )
    scheduled_at_utc = serialize_utc_timestamp(local_timestamp)
    return RoutineOccurrenceSchedule(
        occurrence_local_date=local_date.isoformat(),
        scheduled_local_time=template.local_time,
        scheduled_at_utc=scheduled_at_utc,
        next_attention_at=scheduled_at_utc,
    )


def plan_routine_occurrence(
    template: RoutineTemplate, local_date: date, today_local: date
) -> RoutineOccurrencePlan:
    """Plan a past date as missed and today's date as open, without persistence."""

    local_date = _require_date(local_date, "local_date")
    today_local = _require_date(today_local, "today_local")
    if local_date > today_local:
        raise ValueError("future occurrence planning is not allowed")
    schedule = build_occurrence_schedule(template, local_date)
    if local_date < today_local:
        return RoutineOccurrencePlan(
            schedule=schedule,
            status=RoutineOccurrenceStatus.CLOSED,
            outcome_type=RoutineOccurrenceOutcome.MISSED,
        )
    return RoutineOccurrencePlan(
        schedule=schedule,
        status=RoutineOccurrenceStatus.OPEN,
        outcome_type=None,
    )


def effective_follow_up_attention_at(item: FollowUpItem) -> str | None:
    """Return the earlier planned attention/deadline instant for open planned work."""

    if item.status not in (FollowUpStatus.ACTIVE, FollowUpStatus.WAITING):
        return None
    if item.deadline_at is None:
        return item.next_attention_at
    if item.next_attention_at is None:
        return item.deadline_at
    return min(
        (item.next_attention_at, item.deadline_at), key=_utc_datetime_from_string
    )


def classify_follow_up(
    item: FollowUpItem, today_local: date
) -> FollowUpViewGroup | None:
    """Derive inbox/overdue/today/upcoming; no ``now`` category exists."""

    today_local = _require_date(today_local, "today_local")
    if item.status == FollowUpStatus.INBOX:
        return FollowUpViewGroup.INBOX
    effective = effective_follow_up_attention_at(item)
    if effective is None:
        return None
    attention_date = _istanbul_local_date(effective)
    if attention_date < today_local:
        return FollowUpViewGroup.OVERDUE
    if attention_date == today_local:
        return FollowUpViewGroup.TODAY
    return FollowUpViewGroup.UPCOMING


def is_now_attention_item(item: FollowUpItem, now_utc: str) -> bool:
    """Return membership in overdue + due-today + important-inbox composition."""

    validate_utc_timestamp(now_utc)
    if item.status == FollowUpStatus.INBOX:
        return item.is_important
    effective = effective_follow_up_attention_at(item)
    if effective is None:
        return False
    now = _utc_datetime_from_string(now_utc)
    today_local = now.astimezone(ZoneInfo(ISTANBUL_TIMEZONE)).date()
    group = classify_follow_up(item, today_local)
    return group == FollowUpViewGroup.OVERDUE or (
        group == FollowUpViewGroup.TODAY
        and _utc_datetime_from_string(effective) <= now
    )


def select_now_attention_items(
    items: Iterable[FollowUpItem], now_utc: str
) -> tuple[FollowUpItem, ...]:
    """Return the deterministic, de-duplicated ``Şimdi ilgilen`` composition."""

    validate_utc_timestamp(now_utc)
    selected: list[FollowUpItem] = []
    seen_ids: set[str] = set()
    for item in items:
        if item.follow_up_id in seen_ids or not is_now_attention_item(item, now_utc):
            continue
        seen_ids.add(item.follow_up_id)
        selected.append(item)
    return tuple(selected)


def classify_routine_occurrence(
    occurrence: RoutineOccurrence, now_utc: str
) -> RoutineOccurrenceViewGroup | None:
    """Derive an open occurrence view group from its explicit attention instant."""

    validate_utc_timestamp(now_utc)
    if occurrence.status != RoutineOccurrenceStatus.OPEN:
        return None
    attention = _utc_datetime_from_string(occurrence.next_attention_at)
    now = _utc_datetime_from_string(now_utc)
    if attention < now:
        return RoutineOccurrenceViewGroup.OVERDUE
    today_local = now.astimezone(ZoneInfo(ISTANBUL_TIMEZONE)).date()
    attention_local = attention.astimezone(ZoneInfo(ISTANBUL_TIMEZONE)).date()
    if attention_local == today_local:
        return RoutineOccurrenceViewGroup.TODAY
    return RoutineOccurrenceViewGroup.UPCOMING


def _coerce_enum(value: object, enum_type: type[Enum], field_name: str) -> Enum:
    try:
        return enum_type(value)
    except (TypeError, ValueError) as exc:
        allowed = tuple(member.value for member in enum_type)
        raise ValueError(f"{field_name} must be one of {allowed}") from exc


def _require_non_empty_text(value: str, field_name: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"{field_name} must not be empty")
    return value


def _validate_optional_text(value: str | None, field_name: str) -> None:
    if value is not None and not isinstance(value, str):
        raise ValueError(f"{field_name} must be a string or None")


def _require_bool(value: bool, field_name: str) -> None:
    if not isinstance(value, bool):
        raise ValueError(f"{field_name} must be a bool")


def _validate_optional_record_id(value: str | None, field_name: str) -> None:
    if value is None:
        return
    try:
        validate_record_id(value)
    except ValueError as exc:
        raise ValueError(f"{field_name} must be a canonical UUID string") from exc


def _validate_revision(value: int) -> None:
    if isinstance(value, bool) or not isinstance(value, int) or value < 1:
        raise ValueError("revision must be an integer greater than or equal to 1")


def _local_date_from_string(value: str) -> date:
    validate_local_date(value)
    return date.fromisoformat(value)


def _require_date(value: date, field_name: str) -> date:
    if isinstance(value, datetime) or not isinstance(value, date):
        raise ValueError(f"{field_name} must be a date")
    return value


def _utc_datetime_from_string(value: str) -> datetime:
    validate_utc_timestamp(value)
    return datetime.fromisoformat(f"{value[:-1]}+00:00").astimezone(timezone.utc)


def _istanbul_local_date(value: str) -> date:
    return _utc_datetime_from_string(value).astimezone(
        ZoneInfo(ISTANBUL_TIMEZONE)
    ).date()


def _scheduled_utc_snapshot(local_date: str, local_time: str) -> str:
    local_timestamp = datetime.combine(
        _local_date_from_string(local_date),
        time.fromisoformat(validate_local_time(local_time)),
        tzinfo=ZoneInfo(ISTANBUL_TIMEZONE),
    )
    return serialize_utc_timestamp(local_timestamp)


def _validate_event_identity(
    event_id: str, aggregate_id: str, sequence: int
) -> None:
    validate_record_id(event_id)
    validate_record_id(aggregate_id)
    if isinstance(sequence, bool) or not isinstance(sequence, int) or sequence < 1:
        raise ValueError("event sequence must be an integer greater than or equal to 1")


def _validate_event_details(actor: str, occurred_at: str) -> None:
    _require_non_empty_text(actor, "actor")
    validate_utc_timestamp(occurred_at)


def _canonical_payload(payload: Mapping[str, object]) -> dict[str, object]:
    serialized = serialize_event_payload(payload)
    canonical = json.loads(serialized)
    revision = canonical.get("revision")
    if isinstance(revision, bool) or not isinstance(revision, int) or revision < 1:
        raise ValueError("event payload requires revision greater than or equal to 1")
    return canonical


__all__ = [
    "FOLLOW_UP_EVENT_TYPES",
    "ISTANBUL_TIMEZONE",
    "ROUTINE_OCCURRENCE_EVENT_TYPES",
    "ROUTINE_TEMPLATE_EVENT_TYPES",
    "SUPPORTED_TIMEZONES",
    "FollowUpEvent",
    "FollowUpEventType",
    "FollowUpItem",
    "FollowUpItemType",
    "FollowUpOutcome",
    "FollowUpStatus",
    "FollowUpViewGroup",
    "RoutineOccurrence",
    "RoutineOccurrenceEvent",
    "RoutineOccurrenceEventType",
    "RoutineOccurrenceOutcome",
    "RoutineOccurrencePlan",
    "RoutineOccurrenceSchedule",
    "RoutineOccurrenceStatus",
    "RoutineOccurrenceViewGroup",
    "RoutineRecurrenceType",
    "RoutineTemplate",
    "RoutineTemplateEvent",
    "RoutineTemplateEventType",
    "RoutineTemplateStatus",
    "build_occurrence_schedule",
    "classify_follow_up",
    "classify_routine_occurrence",
    "create_follow_up_item",
    "due_routine_dates",
    "effective_follow_up_attention_at",
    "is_now_attention_item",
    "matches_routine_date",
    "normalize_capture_text",
    "plan_routine_occurrence",
    "select_now_attention_items",
    "validate_iso_weekday",
    "validate_local_date",
    "validate_local_time",
    "validate_timezone",
]
