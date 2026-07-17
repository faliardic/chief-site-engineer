"""Transactional application use cases for one-off field follow-ups."""

from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass, replace
from datetime import date
from enum import Enum
from pathlib import Path
from uuid import uuid4

from app.field_tracking import (
    FollowUpEvent,
    FollowUpEventType,
    FollowUpItem,
    FollowUpItemType,
    FollowUpOutcome,
    FollowUpStatus,
    FollowUpViewGroup,
    classify_follow_up,
    create_follow_up_item,
    normalize_capture_text,
    select_now_attention_items,
)
from app.persistence import (
    InvalidRecordError,
    RevisionConflict,
    SQLiteUnitOfWork,
    validate_record_id,
    validate_utc_timestamp,
)
from app.time_contracts import to_istanbul, utc_now


DETAIL_FIELDS = (
    "condition_text",
    "deadline_at",
    "description",
    "is_important",
    "item_type",
    "location",
    "related_person",
    "title",
)
PLANNED_STATUSES = (FollowUpStatus.ACTIVE, FollowUpStatus.WAITING)
OPEN_STATUSES = (
    FollowUpStatus.INBOX,
    FollowUpStatus.ACTIVE,
    FollowUpStatus.WAITING,
)
TERMINAL_STATUSES = (FollowUpStatus.COMPLETED, FollowUpStatus.CANCELLED)


class FollowUpView(str, Enum):
    """Application query views; these values are never persisted as statuses."""

    INBOX = "inbox"
    OVERDUE = "overdue"
    TODAY = "today"
    UPCOMING = "upcoming"
    NOW = "now"


@dataclass(frozen=True, slots=True)
class CreateFollowUp:
    capture_text: str

    def __post_init__(self) -> None:
        object.__setattr__(
            self, "capture_text", normalize_capture_text(self.capture_text)
        )


@dataclass(frozen=True, slots=True)
class UpdateFollowUp:
    title: str
    description: str | None
    item_type: FollowUpItemType
    location: str | None
    related_person: str | None
    is_important: bool
    condition_text: str | None
    deadline_at: str | None

    def __post_init__(self) -> None:
        object.__setattr__(self, "title", _normalize_title(self.title))
        for field_name in (
            "description",
            "location",
            "related_person",
            "condition_text",
        ):
            object.__setattr__(
                self,
                field_name,
                _normalize_optional_text(getattr(self, field_name), field_name),
            )
        object.__setattr__(
            self,
            "item_type",
            _coerce_enum(self.item_type, FollowUpItemType, "item_type"),
        )
        if not isinstance(self.is_important, bool):
            raise ValueError("is_important must be a bool")
        if self.deadline_at is not None:
            validate_utc_timestamp(self.deadline_at)


@dataclass(frozen=True, slots=True)
class ScheduleFollowUp:
    next_attention_at: str
    target_status: FollowUpStatus

    def __post_init__(self) -> None:
        validate_utc_timestamp(self.next_attention_at)
        target_status = _coerce_enum(
            self.target_status, FollowUpStatus, "target_status"
        )
        if target_status not in PLANNED_STATUSES:
            allowed = tuple(status.value for status in PLANNED_STATUSES)
            raise ValueError(f"target_status must be one of {allowed}")
        object.__setattr__(self, "target_status", target_status)


@dataclass(frozen=True, slots=True)
class MarkWaiting:
    next_attention_at: str
    related_person: str | None = None
    condition_text: str | None = None

    def __post_init__(self) -> None:
        validate_utc_timestamp(self.next_attention_at)
        for field_name in ("related_person", "condition_text"):
            object.__setattr__(
                self,
                field_name,
                _normalize_optional_text(getattr(self, field_name), field_name),
            )


@dataclass(frozen=True, slots=True)
class CompleteFollowUp:
    outcome_type: FollowUpOutcome
    outcome_note: str | None = None

    def __post_init__(self) -> None:
        outcome_type = _coerce_enum(
            self.outcome_type, FollowUpOutcome, "outcome_type"
        )
        allowed_outcomes = (
            FollowUpOutcome.COMPLETED,
            FollowUpOutcome.NOT_REQUIRED,
        )
        if outcome_type not in allowed_outcomes:
            allowed = tuple(outcome.value for outcome in allowed_outcomes)
            raise ValueError(f"outcome_type must be one of {allowed}")
        object.__setattr__(self, "outcome_type", outcome_type)
        object.__setattr__(
            self,
            "outcome_note",
            _normalize_optional_text(self.outcome_note, "outcome_note"),
        )


@dataclass(frozen=True, slots=True)
class FollowUpQuery:
    status: FollowUpStatus | None = None
    project_id: str | None = None
    personal_only: bool = False
    observation_id: str | None = None
    view: FollowUpView | None = None
    as_of_utc: str | None = None

    def __post_init__(self) -> None:
        if self.status is not None:
            object.__setattr__(
                self,
                "status",
                _coerce_enum(self.status, FollowUpStatus, "status"),
            )
        if not isinstance(self.personal_only, bool):
            raise ValueError("personal_only must be a bool")
        if self.project_id is not None:
            validate_record_id(self.project_id)
        if self.observation_id is not None:
            validate_record_id(self.observation_id)
        if self.personal_only and self.project_id is not None:
            raise ValueError("personal_only and project_id cannot be used together")
        if self.view is not None:
            object.__setattr__(
                self, "view", _coerce_enum(self.view, FollowUpView, "view")
            )
        if self.as_of_utc is not None:
            validate_utc_timestamp(self.as_of_utc)
        if self.view in (
            FollowUpView.OVERDUE,
            FollowUpView.TODAY,
            FollowUpView.UPCOMING,
            FollowUpView.NOW,
        ) and self.as_of_utc is None:
            raise ValueError(f"view={self.view.value} requires as_of_utc")


def _utc_now() -> str:
    return utc_now()


class FollowUpApplicationService:
    """Coordinate follow-up aggregate and append-only event persistence."""

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

    def create_follow_up(self, command: CreateFollowUp) -> FollowUpItem:
        _require_instance(command, CreateFollowUp, "command")
        occurred_at = self._now()
        item = create_follow_up_item(
            follow_up_id=self._new_id(),
            capture_text=command.capture_text,
            created_at=occurred_at,
        )
        event = self._event(
            item,
            sequence=1,
            event_type=FollowUpEventType.CREATED,
            occurred_at=occurred_at,
            payload={"revision": item.revision, "status": item.status.value},
        )
        with self._uow_factory() as unit_of_work:
            unit_of_work.follow_ups.add(item)
            unit_of_work.follow_up_events.add(event)
            unit_of_work.commit()
        return item

    def get_follow_up(self, follow_up_id: str) -> FollowUpItem:
        validate_record_id(follow_up_id)
        with self._uow_factory() as unit_of_work:
            return unit_of_work.follow_ups.get(follow_up_id)

    def list_follow_ups(
        self, query: FollowUpQuery
    ) -> tuple[FollowUpItem, ...]:
        _require_instance(query, FollowUpQuery, "query")
        with self._uow_factory() as unit_of_work:
            items = tuple(unit_of_work.follow_ups.list_all())

        if query.status is not None:
            items = tuple(item for item in items if item.status == query.status)
        if query.project_id is not None:
            items = tuple(
                item for item in items if item.project_id == query.project_id
            )
        if query.personal_only:
            items = tuple(item for item in items if item.project_id is None)
        if query.observation_id is not None:
            items = tuple(
                item
                for item in items
                if item.observation_id == query.observation_id
            )

        if query.view == FollowUpView.INBOX:
            items = tuple(
                item for item in items if item.status == FollowUpStatus.INBOX
            )
        elif query.view == FollowUpView.NOW:
            if query.as_of_utc is None:
                raise ValueError("view=now requires as_of_utc")
            items = select_now_attention_items(items, query.as_of_utc)
        elif query.view is not None:
            if query.as_of_utc is None:
                raise ValueError(f"view={query.view.value} requires as_of_utc")
            today_local = _istanbul_date(query.as_of_utc)
            expected_group = FollowUpViewGroup(query.view.value)
            items = tuple(
                item
                for item in items
                if classify_follow_up(item, today_local) == expected_group
            )
        return items

    def list_history(self, follow_up_id: str) -> tuple[FollowUpEvent, ...]:
        validate_record_id(follow_up_id)
        with self._uow_factory() as unit_of_work:
            unit_of_work.follow_ups.get(follow_up_id)
            return tuple(
                unit_of_work.follow_up_events.list_for_follow_up(follow_up_id)
            )

    def update_details(
        self,
        follow_up_id: str,
        expected_revision: int,
        command: UpdateFollowUp,
    ) -> FollowUpItem:
        validate_record_id(follow_up_id)
        _validate_expected_revision(expected_revision)
        _require_instance(command, UpdateFollowUp, "command")
        with self._uow_factory() as unit_of_work:
            current = unit_of_work.follow_ups.get(follow_up_id)
            self._require_current_revision(current, expected_revision)
            values = {
                field_name: getattr(command, field_name)
                for field_name in DETAIL_FIELDS
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
            stored = unit_of_work.follow_ups.update(
                updated, expected_revision=expected_revision
            )
            unit_of_work.follow_up_events.add(
                self._event(
                    stored,
                    sequence=self._next_sequence(unit_of_work, follow_up_id),
                    event_type=FollowUpEventType.DETAILS_UPDATED,
                    occurred_at=occurred_at,
                    payload={
                        "changed_fields": changed_fields,
                        "revision": stored.revision,
                    },
                )
            )
            unit_of_work.commit()
            return stored

    def schedule(
        self,
        follow_up_id: str,
        expected_revision: int,
        command: ScheduleFollowUp,
    ) -> FollowUpItem:
        validate_record_id(follow_up_id)
        _validate_expected_revision(expected_revision)
        _require_instance(command, ScheduleFollowUp, "command")
        with self._uow_factory() as unit_of_work:
            current = unit_of_work.follow_ups.get(follow_up_id)
            self._require_current_revision(current, expected_revision)
            if current.status in TERMINAL_STATUSES:
                raise InvalidRecordError("terminal follow-up cannot be scheduled")
            if (
                current.status == command.target_status
                and current.next_attention_at == command.next_attention_at
            ):
                return current
            event_type = (
                FollowUpEventType.SCHEDULED
                if current.status == FollowUpStatus.INBOX
                else FollowUpEventType.RESCHEDULED
            )
            occurred_at = self._now()
            updated = replace(
                current,
                status=command.target_status,
                next_attention_at=command.next_attention_at,
                revision=current.revision + 1,
                updated_at=occurred_at,
            )
            stored = unit_of_work.follow_ups.update(
                updated, expected_revision=expected_revision
            )
            unit_of_work.follow_up_events.add(
                self._event(
                    stored,
                    sequence=self._next_sequence(unit_of_work, follow_up_id),
                    event_type=event_type,
                    occurred_at=occurred_at,
                    payload={
                        "from_status": current.status.value,
                        "next_attention_at": stored.next_attention_at,
                        "previous_next_attention_at": current.next_attention_at,
                        "revision": stored.revision,
                        "status": stored.status.value,
                    },
                )
            )
            unit_of_work.commit()
            return stored

    def move_to_inbox(
        self, follow_up_id: str, expected_revision: int
    ) -> FollowUpItem:
        validate_record_id(follow_up_id)
        _validate_expected_revision(expected_revision)
        with self._uow_factory() as unit_of_work:
            current = unit_of_work.follow_ups.get(follow_up_id)
            self._require_current_revision(current, expected_revision)
            if (
                current.status == FollowUpStatus.INBOX
                and current.next_attention_at is None
            ):
                return current
            if current.status not in PLANNED_STATUSES:
                raise InvalidRecordError(
                    "only active or waiting follow-up can move to inbox"
                )
            occurred_at = self._now()
            updated = replace(
                current,
                status=FollowUpStatus.INBOX,
                next_attention_at=None,
                revision=current.revision + 1,
                updated_at=occurred_at,
            )
            stored = unit_of_work.follow_ups.update(
                updated, expected_revision=expected_revision
            )
            unit_of_work.follow_up_events.add(
                self._event(
                    stored,
                    sequence=self._next_sequence(unit_of_work, follow_up_id),
                    event_type=FollowUpEventType.MOVED_TO_INBOX,
                    occurred_at=occurred_at,
                    payload={
                        "from_status": current.status.value,
                        "previous_next_attention_at": current.next_attention_at,
                        "revision": stored.revision,
                    },
                )
            )
            unit_of_work.commit()
            return stored

    def set_project(
        self,
        follow_up_id: str,
        expected_revision: int,
        project_id: str | None,
    ) -> FollowUpItem:
        validate_record_id(follow_up_id)
        _validate_expected_revision(expected_revision)
        if project_id is not None:
            validate_record_id(project_id)
        with self._uow_factory() as unit_of_work:
            current = unit_of_work.follow_ups.get(follow_up_id)
            self._require_current_revision(current, expected_revision)
            if project_id is not None:
                unit_of_work.projects.get(project_id)
            if current.observation_id is not None:
                if project_id != current.project_id:
                    raise InvalidRecordError(
                        "observation-linked follow-up project cannot change"
                    )
                return current
            if current.project_id == project_id:
                return current
            occurred_at = self._now()
            updated = replace(
                current,
                project_id=project_id,
                revision=current.revision + 1,
                updated_at=occurred_at,
            )
            stored = unit_of_work.follow_ups.update(
                updated, expected_revision=expected_revision
            )
            unit_of_work.follow_up_events.add(
                self._event(
                    stored,
                    sequence=self._next_sequence(unit_of_work, follow_up_id),
                    event_type=FollowUpEventType.PROJECT_CHANGED,
                    occurred_at=occurred_at,
                    payload={
                        "from_project_id": current.project_id,
                        "project_id": stored.project_id,
                        "revision": stored.revision,
                    },
                )
            )
            unit_of_work.commit()
            return stored

    def mark_waiting(
        self,
        follow_up_id: str,
        expected_revision: int,
        command: MarkWaiting,
    ) -> FollowUpItem:
        validate_record_id(follow_up_id)
        _validate_expected_revision(expected_revision)
        _require_instance(command, MarkWaiting, "command")
        with self._uow_factory() as unit_of_work:
            current = unit_of_work.follow_ups.get(follow_up_id)
            self._require_current_revision(current, expected_revision)
            if current.status == FollowUpStatus.WAITING:
                if (
                    current.next_attention_at == command.next_attention_at
                    and current.related_person == command.related_person
                    and current.condition_text == command.condition_text
                ):
                    return current
                raise InvalidRecordError(
                    "waiting follow-up cannot start waiting again with "
                    "different values"
                )
            if current.status not in (
                FollowUpStatus.INBOX,
                FollowUpStatus.ACTIVE,
            ):
                raise InvalidRecordError(
                    "only inbox or active follow-up can start waiting"
                )

            occurred_at = self._now()
            updated = replace(
                current,
                status=FollowUpStatus.WAITING,
                next_attention_at=command.next_attention_at,
                related_person=command.related_person,
                condition_text=command.condition_text,
                revision=current.revision + 1,
                updated_at=occurred_at,
            )
            stored = unit_of_work.follow_ups.update(
                updated, expected_revision=expected_revision
            )
            unit_of_work.follow_up_events.add(
                self._event(
                    stored,
                    sequence=self._next_sequence(unit_of_work, follow_up_id),
                    event_type=FollowUpEventType.WAITING_STARTED,
                    occurred_at=occurred_at,
                    payload={
                        "condition_text": stored.condition_text,
                        "from_status": current.status.value,
                        "next_attention_at": stored.next_attention_at,
                        "previous_next_attention_at": current.next_attention_at,
                        "related_person": stored.related_person,
                        "revision": stored.revision,
                    },
                )
            )
            unit_of_work.commit()
            return stored

    def complete(
        self,
        follow_up_id: str,
        expected_revision: int,
        command: CompleteFollowUp,
    ) -> FollowUpItem:
        validate_record_id(follow_up_id)
        _validate_expected_revision(expected_revision)
        _require_instance(command, CompleteFollowUp, "command")
        with self._uow_factory() as unit_of_work:
            current = unit_of_work.follow_ups.get(follow_up_id)
            self._require_current_revision(current, expected_revision)
            if current.status not in OPEN_STATUSES:
                raise InvalidRecordError(
                    "only open follow-up can be completed"
                )

            occurred_at = self._now()
            updated = replace(
                current,
                status=FollowUpStatus.COMPLETED,
                outcome_type=command.outcome_type,
                outcome_note=command.outcome_note,
                completed_at=occurred_at,
                cancelled_at=None,
                next_attention_at=None,
                revision=current.revision + 1,
                updated_at=occurred_at,
            )
            stored = unit_of_work.follow_ups.update(
                updated, expected_revision=expected_revision
            )
            unit_of_work.follow_up_events.add(
                self._event(
                    stored,
                    sequence=self._next_sequence(unit_of_work, follow_up_id),
                    event_type=FollowUpEventType.COMPLETED,
                    occurred_at=occurred_at,
                    payload={
                        "from_status": current.status.value,
                        "outcome_note": stored.outcome_note,
                        "outcome_type": stored.outcome_type.value,
                        "previous_next_attention_at": current.next_attention_at,
                        "revision": stored.revision,
                    },
                )
            )
            unit_of_work.commit()
            return stored

    def cancel(
        self,
        follow_up_id: str,
        expected_revision: int,
        outcome_note: str | None,
    ) -> FollowUpItem:
        validate_record_id(follow_up_id)
        _validate_expected_revision(expected_revision)
        normalized_note = _normalize_optional_text(outcome_note, "outcome_note")
        with self._uow_factory() as unit_of_work:
            current = unit_of_work.follow_ups.get(follow_up_id)
            self._require_current_revision(current, expected_revision)
            if current.status not in OPEN_STATUSES:
                raise InvalidRecordError("only open follow-up can be cancelled")

            occurred_at = self._now()
            updated = replace(
                current,
                status=FollowUpStatus.CANCELLED,
                outcome_type=FollowUpOutcome.CANCELLED,
                outcome_note=normalized_note,
                completed_at=None,
                cancelled_at=occurred_at,
                next_attention_at=None,
                revision=current.revision + 1,
                updated_at=occurred_at,
            )
            stored = unit_of_work.follow_ups.update(
                updated, expected_revision=expected_revision
            )
            unit_of_work.follow_up_events.add(
                self._event(
                    stored,
                    sequence=self._next_sequence(unit_of_work, follow_up_id),
                    event_type=FollowUpEventType.CANCELLED,
                    occurred_at=occurred_at,
                    payload={
                        "from_status": current.status.value,
                        "outcome_note": stored.outcome_note,
                        "outcome_type": stored.outcome_type.value,
                        "previous_next_attention_at": current.next_attention_at,
                        "revision": stored.revision,
                    },
                )
            )
            unit_of_work.commit()
            return stored

    def reopen(
        self,
        follow_up_id: str,
        expected_revision: int,
        next_attention_at: str | None,
    ) -> FollowUpItem:
        validate_record_id(follow_up_id)
        _validate_expected_revision(expected_revision)
        if next_attention_at is not None:
            validate_utc_timestamp(next_attention_at)
        with self._uow_factory() as unit_of_work:
            current = unit_of_work.follow_ups.get(follow_up_id)
            self._require_current_revision(current, expected_revision)
            if current.status not in TERMINAL_STATUSES:
                raise InvalidRecordError(
                    "only completed or cancelled follow-up can be reopened"
                )

            occurred_at = self._now()
            target_status = (
                FollowUpStatus.ACTIVE
                if next_attention_at is not None
                else FollowUpStatus.INBOX
            )
            previous_outcome_type = current.outcome_type
            updated = replace(
                current,
                status=target_status,
                next_attention_at=next_attention_at,
                outcome_type=None,
                outcome_note=None,
                completed_at=None,
                cancelled_at=None,
                revision=current.revision + 1,
                updated_at=occurred_at,
            )
            stored = unit_of_work.follow_ups.update(
                updated, expected_revision=expected_revision
            )
            unit_of_work.follow_up_events.add(
                self._event(
                    stored,
                    sequence=self._next_sequence(unit_of_work, follow_up_id),
                    event_type=FollowUpEventType.REOPENED,
                    occurred_at=occurred_at,
                    payload={
                        "from_status": current.status.value,
                        "next_attention_at": stored.next_attention_at,
                        "previous_outcome_type": previous_outcome_type.value,
                        "revision": stored.revision,
                        "status": stored.status.value,
                    },
                )
            )
            unit_of_work.commit()
            return stored

    def link_observation(
        self,
        follow_up_id: str,
        expected_revision: int,
        observation_id: str,
    ) -> FollowUpItem:
        validate_record_id(follow_up_id)
        _validate_expected_revision(expected_revision)
        validate_record_id(observation_id)
        with self._uow_factory() as unit_of_work:
            current = unit_of_work.follow_ups.get(follow_up_id)
            self._require_current_revision(current, expected_revision)
            observation = unit_of_work.observations.get(observation_id)
            self._require_observation_target(
                current,
                observation.observation_id,
                observation.project_id,
            )
            if current.observation_id == observation.observation_id:
                return current

            occurred_at = self._now()
            updated = replace(
                current,
                observation_id=observation.observation_id,
                project_id=observation.project_id,
                revision=current.revision + 1,
                updated_at=occurred_at,
            )
            stored = unit_of_work.follow_ups.update(
                updated, expected_revision=expected_revision
            )
            unit_of_work.follow_up_events.add(
                self._event(
                    stored,
                    sequence=self._next_sequence(unit_of_work, follow_up_id),
                    event_type=FollowUpEventType.OBSERVATION_LINKED,
                    occurred_at=occurred_at,
                    payload={
                        "from_project_id": current.project_id,
                        "observation_id": stored.observation_id,
                        "project_id": stored.project_id,
                        "revision": stored.revision,
                        "status": stored.status.value,
                    },
                )
            )
            unit_of_work.commit()
            return stored

    def convert_to_observation(
        self,
        follow_up_id: str,
        expected_revision: int,
        observation_id: str,
    ) -> FollowUpItem:
        validate_record_id(follow_up_id)
        _validate_expected_revision(expected_revision)
        validate_record_id(observation_id)
        with self._uow_factory() as unit_of_work:
            current = unit_of_work.follow_ups.get(follow_up_id)
            self._require_current_revision(current, expected_revision)
            observation = unit_of_work.observations.get(observation_id)
            self._require_observation_target(
                current,
                observation.observation_id,
                observation.project_id,
            )
            if (
                current.status == FollowUpStatus.COMPLETED
                and current.outcome_type
                == FollowUpOutcome.CONVERTED_TO_OBSERVATION
                and current.outcome_note is None
                and current.observation_id == observation.observation_id
                and current.project_id == observation.project_id
                and current.next_attention_at is None
            ):
                return current
            if current.status not in OPEN_STATUSES:
                raise InvalidRecordError(
                    "only open follow-up can convert to observation"
                )

            occurred_at = self._now()
            updated = replace(
                current,
                status=FollowUpStatus.COMPLETED,
                outcome_type=FollowUpOutcome.CONVERTED_TO_OBSERVATION,
                outcome_note=None,
                completed_at=occurred_at,
                cancelled_at=None,
                next_attention_at=None,
                observation_id=observation.observation_id,
                project_id=observation.project_id,
                revision=current.revision + 1,
                updated_at=occurred_at,
            )
            stored = unit_of_work.follow_ups.update(
                updated, expected_revision=expected_revision
            )
            unit_of_work.follow_up_events.add(
                self._event(
                    stored,
                    sequence=self._next_sequence(unit_of_work, follow_up_id),
                    event_type=FollowUpEventType.CONVERTED_TO_OBSERVATION,
                    occurred_at=occurred_at,
                    payload={
                        "from_project_id": current.project_id,
                        "from_status": current.status.value,
                        "observation_id": stored.observation_id,
                        "outcome_type": stored.outcome_type.value,
                        "previous_next_attention_at": current.next_attention_at,
                        "project_id": stored.project_id,
                        "revision": stored.revision,
                    },
                )
            )
            unit_of_work.commit()
            return stored

    def _event(
        self,
        item: FollowUpItem,
        *,
        sequence: int,
        event_type: FollowUpEventType,
        occurred_at: str,
        payload: dict[str, object],
    ) -> FollowUpEvent:
        return FollowUpEvent(
            event_id=self._new_id(),
            follow_up_id=item.follow_up_id,
            sequence=sequence,
            event_type=event_type,
            actor=self._local_actor,
            occurred_at=occurred_at,
            payload=payload,
        )

    @staticmethod
    def _next_sequence(
        unit_of_work: SQLiteUnitOfWork, follow_up_id: str
    ) -> int:
        history = unit_of_work.follow_up_events.list_for_follow_up(follow_up_id)
        return history[-1].sequence + 1 if history else 1

    @staticmethod
    def _require_current_revision(
        item: FollowUpItem, expected_revision: int
    ) -> None:
        if item.revision != expected_revision:
            raise RevisionConflict(
                item.follow_up_id, expected_revision, item.revision
            )

    @staticmethod
    def _require_observation_target(
        item: FollowUpItem,
        observation_id: str,
        observation_project_id: str,
    ) -> None:
        if (
            item.observation_id is not None
            and item.observation_id != observation_id
        ):
            raise InvalidRecordError(
                "follow-up is already linked to a different observation"
            )
        if (
            item.project_id is not None
            and item.project_id != observation_project_id
        ):
            raise InvalidRecordError(
                "follow-up project must match observation project"
            )

    def _now(self) -> str:
        value = self._clock()
        validate_utc_timestamp(value)
        return value

    def _new_id(self) -> str:
        value = self._uuid_factory()
        validate_record_id(value)
        return value


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
    return to_istanbul(value).date()


def _require_instance(value: object, expected_type: type[object], name: str) -> None:
    if not isinstance(value, expected_type):
        raise TypeError(f"{name} must be {expected_type.__name__}")


__all__ = [
    "CompleteFollowUp",
    "CreateFollowUp",
    "FollowUpApplicationService",
    "FollowUpQuery",
    "FollowUpView",
    "MarkWaiting",
    "ScheduleFollowUp",
    "UpdateFollowUp",
]
