import sqlite3
from dataclasses import replace
from pathlib import Path

import pytest

from app.field_tracking import (
    FollowUpEvent,
    FollowUpEventType,
    FollowUpItem,
    FollowUpStatus,
    RoutineOccurrence,
    RoutineOccurrenceEvent,
    RoutineOccurrenceEventType,
    RoutineOccurrenceOutcome,
    RoutineOccurrenceStatus,
    RoutineRecurrenceType,
    RoutineTemplate,
    RoutineTemplateEvent,
    RoutineTemplateEventType,
    create_follow_up_item,
)
from app.models import FieldObservationRecord
from app.persistence import (
    DuplicateRecordError,
    ForeignKeyViolation,
    InvalidRecordError,
    ProjectRecord,
    RecordNotFound,
    RevisionConflict,
    SQLiteUnitOfWork,
    connect_database,
    migrate_database,
)


PROJECT_ID = "11111111-1111-4111-8111-111111111111"
SECOND_PROJECT_ID = "22222222-2222-4222-8222-222222222222"
OBSERVATION_ID = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"
FOLLOW_UP_ID = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"
SECOND_FOLLOW_UP_ID = "cccccccc-cccc-4ccc-8ccc-cccccccccccc"
TEMPLATE_ID = "dddddddd-dddd-4ddd-8ddd-dddddddddddd"
SECOND_TEMPLATE_ID = "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee"
OCCURRENCE_ID = "ffffffff-ffff-4fff-8fff-ffffffffffff"
SECOND_OCCURRENCE_ID = "12345678-1234-4234-8234-123456789abc"
EVENT_ONE_ID = "23456789-2345-4345-8345-23456789abcd"
EVENT_TWO_ID = "3456789a-3456-4456-8456-3456789abcde"
T1 = "2026-07-15T06:00:00Z"
T2 = "2026-07-15T07:00:00Z"
T3 = "2026-07-15T08:00:00Z"


def _project(project_id: str = PROJECT_ID) -> ProjectRecord:
    return ProjectRecord(project_id, "Örnek Şantiye", T1)


def _observation() -> FieldObservationRecord:
    return FieldObservationRecord(
        observation_id=OBSERVATION_ID,
        project_id=PROJECT_ID,
        observed_at=T1,
        location="A Blok",
        category="quality",
        description="Kalıp birleşimi kontrol edilecek.",
        created_at=T1,
        updated_at=T1,
    )


def _follow_up(
    follow_up_id: str = FOLLOW_UP_ID,
    *,
    created_at: str = T1,
    status: FollowUpStatus = FollowUpStatus.INBOX,
    project_id: str | None = None,
    observation_id: str | None = None,
    next_attention_at: str | None = None,
) -> FollowUpItem:
    return FollowUpItem(
        follow_up_id=follow_up_id,
        capture_text="  Kalıp   kontrolünü unutma  ",
        title="Kalıp kontrolü",
        created_at=created_at,
        updated_at=created_at,
        status=status,
        project_id=project_id,
        observation_id=observation_id,
        next_attention_at=next_attention_at,
    )


def _template(
    routine_template_id: str = TEMPLATE_ID,
    *,
    project_id: str | None = None,
    recurrence_type: RoutineRecurrenceType = RoutineRecurrenceType.WEEKLY,
    weekdays: frozenset[int] = frozenset({1, 3}),
) -> RoutineTemplate:
    return RoutineTemplate(
        routine_template_id=routine_template_id,
        title="Haftalık saha kontrolü",
        recurrence_type=recurrence_type,
        local_time="09:30",
        start_date="2026-07-13",
        created_at=T1,
        updated_at=T1,
        project_id=project_id,
        weekdays=weekdays,
    )


def _occurrence(
    routine_occurrence_id: str = OCCURRENCE_ID,
    *,
    routine_template_id: str = TEMPLATE_ID,
    local_date: str = "2026-07-15",
) -> RoutineOccurrence:
    return RoutineOccurrence(
        routine_occurrence_id=routine_occurrence_id,
        routine_template_id=routine_template_id,
        occurrence_local_date=local_date,
        scheduled_local_time="09:30",
        scheduled_at_utc=f"{local_date}T06:30:00Z",
        status=RoutineOccurrenceStatus.OPEN,
        next_attention_at=f"{local_date}T06:30:00Z",
        revision=1,
        created_at=T1,
    )


def _follow_up_event(
    *,
    event_id: str = EVENT_ONE_ID,
    sequence: int = 1,
    occurred_at: str = T1,
) -> FollowUpEvent:
    return FollowUpEvent(
        event_id=event_id,
        follow_up_id=FOLLOW_UP_ID,
        sequence=sequence,
        event_type=FollowUpEventType.CREATED,
        actor="Santiye sefi",
        occurred_at=occurred_at,
        payload={"revision": 1, "title": "Kalıp kontrolü"},
    )


def _seed_project_and_observation(unit_of_work: SQLiteUnitOfWork) -> None:
    unit_of_work.projects.add(_project())
    unit_of_work.observations.add(_observation())


def test_follow_up_round_trip_queries_and_personal_workspace(tmp_path: Path) -> None:
    database_path = tmp_path / "follow-ups.sqlite3"
    personal = _follow_up()
    planned = _follow_up(
        SECOND_FOLLOW_UP_ID,
        created_at=T2,
        status=FollowUpStatus.ACTIVE,
        project_id=PROJECT_ID,
        observation_id=OBSERVATION_ID,
        next_attention_at=T3,
    )

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        _seed_project_and_observation(unit_of_work)
        unit_of_work.follow_ups.add(planned)
        unit_of_work.follow_ups.add(personal)
        unit_of_work.commit()

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        assert unit_of_work.follow_ups.get(FOLLOW_UP_ID) == personal
        assert unit_of_work.follow_ups.list_all() == [personal, planned]
        assert unit_of_work.follow_ups.list_by_project_id(None) == [personal]
        assert unit_of_work.follow_ups.list_by_project_id(PROJECT_ID) == [planned]
        assert unit_of_work.follow_ups.list_by_observation_id(OBSERVATION_ID) == [
            planned
        ]
        assert unit_of_work.follow_ups.list_by_status(FollowUpStatus.ACTIVE) == [
            planned
        ]
        assert unit_of_work.follow_ups.list_by_attention_range(T2, T3) == [planned]


def test_follow_up_title_update_noop_and_revision_conflict(tmp_path: Path) -> None:
    database_path = tmp_path / "follow-up-update.sqlite3"
    original = _follow_up()

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        unit_of_work.follow_ups.add(original)
        unit_of_work.commit()

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        assert (
            unit_of_work.follow_ups.update(
                replace(original, revision=99), expected_revision=1
            )
            == original
        )
        updated = replace(
            original,
            title="Düzenlenmiş başlık",
            updated_at=T2,
            revision=2,
        )
        assert unit_of_work.follow_ups.update(updated, expected_revision=1) == updated
        with pytest.raises(RevisionConflict):
            unit_of_work.follow_ups.update(updated, expected_revision=1)
        unit_of_work.commit()

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        stored = unit_of_work.follow_ups.get(FOLLOW_UP_ID)
        assert stored.title == "Düzenlenmiş başlık"
        assert stored.capture_text == "Kalıp kontrolünü unutma"
        assert stored.revision == 2


def test_observation_project_composite_foreign_key_rejects_mismatch(
    tmp_path: Path,
) -> None:
    database_path = tmp_path / "observation-project.sqlite3"
    mismatched = _follow_up(
        status=FollowUpStatus.ACTIVE,
        project_id=SECOND_PROJECT_ID,
        observation_id=OBSERVATION_ID,
        next_attention_at=T2,
    )

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        _seed_project_and_observation(unit_of_work)
        unit_of_work.projects.add(_project(SECOND_PROJECT_ID))
        with pytest.raises(ForeignKeyViolation):
            unit_of_work.follow_ups.add(mismatched)


def test_template_round_trip_weekday_relation_queries_and_update(
    tmp_path: Path,
) -> None:
    database_path = tmp_path / "templates.sqlite3"
    personal = _template()
    project_daily = _template(
        SECOND_TEMPLATE_ID,
        project_id=PROJECT_ID,
        recurrence_type=RoutineRecurrenceType.DAILY,
        weekdays=frozenset(),
    )

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        unit_of_work.projects.add(_project())
        unit_of_work.routine_templates.add(project_daily)
        unit_of_work.routine_templates.add(personal)
        unit_of_work.commit()

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        assert unit_of_work.routine_templates.get(TEMPLATE_ID) == personal
        assert unit_of_work.routine_templates.list_by_project_id(None) == [personal]
        assert unit_of_work.routine_templates.list_by_project_id(PROJECT_ID) == [
            project_daily
        ]
        updated = replace(
            personal,
            title="Pazartesi ve cuma kontrolü",
            weekdays=frozenset({1, 5}),
            revision=2,
            updated_at=T2,
        )
        assert (
            unit_of_work.routine_templates.update(updated, expected_revision=1)
            == updated
        )
        unit_of_work.commit()

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        assert unit_of_work.routine_templates.get(TEMPLATE_ID).weekdays == frozenset(
            {1, 5}
        )


def test_occurrence_add_if_absent_is_idempotent_for_template_and_date(
    tmp_path: Path,
) -> None:
    database_path = tmp_path / "idempotent-occurrence.sqlite3"
    original = _occurrence()
    duplicate_date = _occurrence(SECOND_OCCURRENCE_ID)

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        unit_of_work.routine_templates.add(_template())
        assert unit_of_work.routine_occurrences.add(original) == original
        assert (
            unit_of_work.routine_occurrences.add_if_absent(duplicate_date) == original
        )
        assert unit_of_work.routine_occurrences.list_for_template(TEMPLATE_ID) == [
            original
        ]
        unit_of_work.commit()

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        assert (
            unit_of_work.routine_occurrences.get_by_template_date(
                TEMPLATE_ID, "2026-07-15"
            )
            == original
        )


def test_occurrence_update_and_queries_use_domain_records(tmp_path: Path) -> None:
    database_path = tmp_path / "occurrence-update.sqlite3"
    occurrence = _occurrence()

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        unit_of_work.routine_templates.add(_template())
        unit_of_work.routine_occurrences.add_if_absent(occurrence)
        closed = replace(
            occurrence,
            status=RoutineOccurrenceStatus.CLOSED,
            outcome_type=RoutineOccurrenceOutcome.COMPLETED,
            outcome_note="Kontrol tamamlandı.",
            completed_at=T3,
            revision=2,
        )
        assert (
            unit_of_work.routine_occurrences.update(closed, expected_revision=1)
            == closed
        )
        assert unit_of_work.routine_occurrences.list_by_status("closed") == [closed]
        assert unit_of_work.routine_occurrences.list_by_attention_range(T1, T3) == [
            closed
        ]
        unit_of_work.commit()


def test_three_event_histories_are_append_only_and_order_only_by_sequence(
    tmp_path: Path,
) -> None:
    database_path = tmp_path / "events.sqlite3"
    follow_event_two = _follow_up_event(
        event_id=EVENT_TWO_ID, sequence=2, occurred_at=T1
    )
    follow_event_one = _follow_up_event(sequence=1, occurred_at=T3)
    template_event = RoutineTemplateEvent(
        event_id="456789ab-4567-4567-8567-456789abcdef",
        routine_template_id=TEMPLATE_ID,
        sequence=1,
        event_type=RoutineTemplateEventType.CREATED,
        actor="Santiye sefi",
        occurred_at=T2,
        payload={"revision": 1},
    )
    occurrence_event = RoutineOccurrenceEvent(
        event_id="56789abc-5678-4678-8678-56789abcdef0",
        routine_occurrence_id=OCCURRENCE_ID,
        sequence=1,
        event_type=RoutineOccurrenceEventType.CREATED,
        actor="system",
        occurred_at=T2,
        payload={"revision": 1},
    )

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        unit_of_work.follow_ups.add(_follow_up())
        unit_of_work.routine_templates.add(_template())
        unit_of_work.routine_occurrences.add_if_absent(_occurrence())
        unit_of_work.follow_up_events.add(follow_event_two)
        unit_of_work.follow_up_events.add(follow_event_one)
        unit_of_work.routine_template_events.add(template_event)
        unit_of_work.routine_occurrence_events.add(occurrence_event)
        unit_of_work.commit()

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        assert unit_of_work.follow_up_events.list_for_follow_up(FOLLOW_UP_ID) == [
            follow_event_one,
            follow_event_two,
        ]
        assert unit_of_work.routine_template_events.list_for_template(TEMPLATE_ID) == [
            template_event
        ]
        assert unit_of_work.routine_occurrence_events.list_for_occurrence(
            OCCURRENCE_ID
        ) == [occurrence_event]
        assert not hasattr(unit_of_work.follow_up_events, "update")
        assert not hasattr(unit_of_work.follow_up_events, "delete")
        assert not hasattr(unit_of_work.follow_ups, "delete")


def test_duplicate_event_sequence_is_rejected(tmp_path: Path) -> None:
    database_path = tmp_path / "duplicate-event.sqlite3"
    template_event = RoutineTemplateEvent(
        event_id="456789ab-4567-4567-8567-456789abcdef",
        routine_template_id=TEMPLATE_ID,
        sequence=1,
        event_type=RoutineTemplateEventType.CREATED,
        actor="Santiye sefi",
        occurred_at=T1,
        payload={"revision": 1},
    )
    occurrence_event = RoutineOccurrenceEvent(
        event_id="56789abc-5678-4678-8678-56789abcdef0",
        routine_occurrence_id=OCCURRENCE_ID,
        sequence=1,
        event_type=RoutineOccurrenceEventType.CREATED,
        actor="system",
        occurred_at=T1,
        payload={"revision": 1},
    )

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        unit_of_work.follow_ups.add(_follow_up())
        unit_of_work.routine_templates.add(_template())
        unit_of_work.routine_occurrences.add_if_absent(_occurrence())
        unit_of_work.follow_up_events.add(_follow_up_event())
        unit_of_work.routine_template_events.add(template_event)
        unit_of_work.routine_occurrence_events.add(occurrence_event)
        with pytest.raises(DuplicateRecordError):
            unit_of_work.follow_up_events.add(
                _follow_up_event(event_id=EVENT_TWO_ID)
            )
        with pytest.raises(DuplicateRecordError):
            unit_of_work.routine_template_events.add(
                replace(
                    template_event,
                    event_id="6789abcd-6789-4789-8789-6789abcdef01",
                )
            )
        with pytest.raises(DuplicateRecordError):
            unit_of_work.routine_occurrence_events.add(
                replace(
                    occurrence_event,
                    event_id="789abcde-789a-489a-889a-789abcdef012",
                )
            )


def test_aggregate_and_event_commit_in_same_transaction(tmp_path: Path) -> None:
    database_path = tmp_path / "aggregate-event-commit.sqlite3"

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        unit_of_work.follow_ups.add(_follow_up())
        unit_of_work.follow_up_events.add(_follow_up_event())
        unit_of_work.commit()

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        assert unit_of_work.follow_ups.get(FOLLOW_UP_ID) == _follow_up()
        assert unit_of_work.follow_up_events.list_for_follow_up(FOLLOW_UP_ID) == [
            _follow_up_event()
        ]


def test_event_failure_rolls_back_new_aggregate(tmp_path: Path) -> None:
    database_path = tmp_path / "aggregate-event-rollback.sqlite3"

    with pytest.raises(DuplicateRecordError):
        with SQLiteUnitOfWork(database_path) as unit_of_work:
            unit_of_work.follow_ups.add(_follow_up())
            unit_of_work.follow_up_events.add(_follow_up_event())
            unit_of_work.follow_up_events.add(
                _follow_up_event(event_id=EVENT_TWO_ID)
            )

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        with pytest.raises(RecordNotFound):
            unit_of_work.follow_ups.get(FOLLOW_UP_ID)


def test_event_failure_rolls_back_aggregate_update(tmp_path: Path) -> None:
    database_path = tmp_path / "mutation-event-rollback.sqlite3"
    original = _follow_up()

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        unit_of_work.follow_ups.add(original)
        unit_of_work.follow_up_events.add(_follow_up_event())
        unit_of_work.commit()

    with pytest.raises(DuplicateRecordError):
        with SQLiteUnitOfWork(database_path) as unit_of_work:
            changed = replace(
                original, title="Geçici başlık", updated_at=T2, revision=2
            )
            unit_of_work.follow_ups.update(changed, expected_revision=1)
            unit_of_work.follow_up_events.add(
                _follow_up_event(event_id=EVENT_TWO_ID)
            )

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        assert unit_of_work.follow_ups.get(FOLLOW_UP_ID) == original


@pytest.mark.parametrize("status", ["active", "waiting"])
def test_database_check_rejects_planned_follow_up_without_attention(
    tmp_path: Path, status: str
) -> None:
    connection = connect_database(tmp_path / "follow-up-check.sqlite3")
    try:
        migrate_database(connection)
        with pytest.raises(sqlite3.IntegrityError):
            connection.execute(
                """
                INSERT INTO follow_up_items (
                    id, capture_text, title, item_type, status, is_important,
                    revision, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    FOLLOW_UP_ID,
                    "Kontrol",
                    "Kontrol",
                    "action",
                    status,
                    0,
                    1,
                    T1,
                    T1,
                ),
            )
    finally:
        connection.close()


def test_database_check_rejects_terminal_follow_up_without_outcome(
    tmp_path: Path,
) -> None:
    connection = connect_database(tmp_path / "follow-up-terminal-check.sqlite3")
    try:
        migrate_database(connection)
        with pytest.raises(sqlite3.IntegrityError):
            connection.execute(
                """
                INSERT INTO follow_up_items (
                    id, capture_text, title, item_type, status, is_important,
                    revision, created_at, updated_at, completed_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    FOLLOW_UP_ID,
                    "Kontrol",
                    "Kontrol",
                    "action",
                    "completed",
                    0,
                    1,
                    T1,
                    T1,
                    T2,
                ),
            )
    finally:
        connection.close()


def test_database_unique_constraint_rejects_duplicate_occurrence_date(
    tmp_path: Path,
) -> None:
    database_path = tmp_path / "occurrence-unique.sqlite3"
    with SQLiteUnitOfWork(database_path) as unit_of_work:
        unit_of_work.routine_templates.add(_template())
        unit_of_work.routine_occurrences.add_if_absent(_occurrence())
        connection = unit_of_work._connection
        assert connection is not None
        with pytest.raises(sqlite3.IntegrityError):
            connection.execute(
                """
                INSERT INTO routine_occurrences (
                    id, routine_template_id, occurrence_local_date,
                    scheduled_local_time, scheduled_at_utc, status,
                    next_attention_at, revision, created_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    SECOND_OCCURRENCE_ID,
                    TEMPLATE_ID,
                    "2026-07-15",
                    "09:30",
                    "2026-07-15T06:30:00Z",
                    "open",
                    "2026-07-15T06:30:00Z",
                    1,
                    T1,
                ),
            )


def test_invalid_repository_query_inputs_fail_closed(tmp_path: Path) -> None:
    database_path = tmp_path / "invalid-query.sqlite3"
    with SQLiteUnitOfWork(database_path) as unit_of_work:
        with pytest.raises(InvalidRecordError):
            unit_of_work.follow_ups.list_by_attention_range(T3, T1)
        with pytest.raises(InvalidRecordError):
            unit_of_work.routine_occurrences.get_by_template_date(
                TEMPLATE_ID, "15-07-2026"
            )
        with pytest.raises(InvalidRecordError):
            unit_of_work.routine_templates.list_by_status("unknown")
