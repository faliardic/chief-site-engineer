import sqlite3
from pathlib import Path

import pytest

from app.models import FieldObservationRecord
from app.persistence import (
    DuplicateRecordError,
    ForeignKeyViolation,
    InvalidRecordError,
    OBSERVATION_EVENT_TYPES,
    ObservationEventRecord,
    ProjectRecord,
    SQLiteUnitOfWork,
    serialize_event_payload,
)


PROJECT_ID = "11111111-1111-4111-8111-111111111111"
OBSERVATION_ID = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"
EVENT_ID = "dddddddd-dddd-4ddd-8ddd-dddddddddddd"
SECOND_EVENT_ID = "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee"
THIRD_EVENT_ID = "ffffffff-ffff-4fff-8fff-ffffffffffff"
T1 = "2026-07-12T09:00:00Z"
T2 = "2026-07-12T10:00:00Z"
T3 = "2026-07-12T11:00:00Z"


def test_observation_event_vocabulary_is_explicit() -> None:
    assert OBSERVATION_EVENT_TYPES == (
        "observation_created",
        "observation_details_updated",
        "observation_status_changed",
        "observation_reporting_updated",
        "observation_archived",
    )


def _project() -> ProjectRecord:
    return ProjectRecord(PROJECT_ID, "Ornek Santiye", T1)


def _observation() -> FieldObservationRecord:
    return FieldObservationRecord(
        observation_id=OBSERVATION_ID,
        project_id=PROJECT_ID,
        observed_at=T1,
        location="A Blok 2. Kat",
        category="quality",
        description="Kalip birlesiminde aciklik goruldu.",
        created_at=T1,
        updated_at=T1,
    )


def _event(
    event_id: str = EVENT_ID,
    *,
    event_type: str = "observation_created",
    occurred_at: str = T1,
    payload_json: str | None = None,
) -> ObservationEventRecord:
    return ObservationEventRecord(
        event_id=event_id,
        observation_id=OBSERVATION_ID,
        event_type=event_type,
        actor="Santiye sefi",
        occurred_at=occurred_at,
        payload_json=payload_json or '{"z": 2, "a": 1}',
    )


def _seed_observation(database_path: Path) -> None:
    with SQLiteUnitOfWork(database_path) as unit_of_work:
        unit_of_work.projects.add(_project())
        unit_of_work.observations.add(_observation())
        unit_of_work.commit()


def test_event_add_list_round_trip_uses_deterministic_json_and_order(
    tmp_path: Path,
) -> None:
    database_path = tmp_path / "events.sqlite3"
    _seed_observation(database_path)

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        unit_of_work.events.add(
            _event(SECOND_EVENT_ID, event_type="observation_status_changed", occurred_at=T2)
        )
        unit_of_work.events.add(_event())
        unit_of_work.events.add(
            _event(
                THIRD_EVENT_ID,
                event_type="observation_reporting_updated",
                occurred_at=T3,
            )
        )
        unit_of_work.commit()

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        events = unit_of_work.events.list_for_observation(OBSERVATION_ID)

    assert [event.event_id for event in events] == [
        EVENT_ID,
        SECOND_EVENT_ID,
        THIRD_EVENT_ID,
    ]
    assert all(event.payload_json == '{"a":1,"z":2}' for event in events)
    assert events[0].payload == {"a": 1, "z": 2}


def test_same_timestamp_events_keep_insertion_order_after_reopen(
    tmp_path: Path,
) -> None:
    database_path = tmp_path / "same-timestamp-events.sqlite3"
    _seed_observation(database_path)
    inserted_events = [
        _event(THIRD_EVENT_ID, occurred_at=T2),
        _event(
            EVENT_ID,
            event_type="observation_details_updated",
            occurred_at=T2,
        ),
        _event(
            SECOND_EVENT_ID,
            event_type="observation_status_changed",
            occurred_at=T2,
        ),
    ]

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        for event in inserted_events:
            unit_of_work.events.add(event)
        unit_of_work.commit()

    with SQLiteUnitOfWork(database_path) as reopened:
        stored_events = reopened.events.list_for_observation(OBSERVATION_ID)

    assert [event.event_id for event in stored_events] == [
        THIRD_EVENT_ID,
        EVENT_ID,
        SECOND_EVENT_ID,
    ]


@pytest.mark.parametrize("payload_json", ["not-json", "[]", '"text"'])
def test_event_rejects_payload_that_is_not_valid_json_object(
    tmp_path: Path,
    payload_json: str,
) -> None:
    database_path = tmp_path / f"invalid-payload-{len(payload_json)}.sqlite3"
    _seed_observation(database_path)

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        with pytest.raises(InvalidRecordError, match="JSON object"):
            unit_of_work.events.add(_event(payload_json=payload_json))
        assert unit_of_work.events.list_for_observation(OBSERVATION_ID) == []


def test_event_rejects_unknown_event_type(tmp_path: Path) -> None:
    database_path = tmp_path / "invalid-event-type.sqlite3"
    _seed_observation(database_path)

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        with pytest.raises(InvalidRecordError, match="event_type"):
            unit_of_work.events.add(_event(event_type="unknown"))


def test_event_foreign_key_violation_raises_explicit_error(tmp_path: Path) -> None:
    database_path = tmp_path / "event-foreign-key.sqlite3"

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        with pytest.raises(ForeignKeyViolation) as error:
            unit_of_work.events.add(_event())

    assert isinstance(error.value.__cause__, sqlite3.IntegrityError)


def test_observation_mutation_and_event_commit_atomically(tmp_path: Path) -> None:
    database_path = tmp_path / "atomic-commit.sqlite3"
    _seed_observation(database_path)

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        updated = unit_of_work.observations.update_status(
            OBSERVATION_ID,
            expected_revision=1,
            new_status="tracking",
            occurred_at=T2,
        )
        unit_of_work.events.add(
            _event(
                event_type="observation_status_changed",
                occurred_at=T2,
                payload_json=serialize_event_payload(
                    {"from": "open", "revision": updated.revision, "to": "tracking"}
                ),
            )
        )
        unit_of_work.commit()

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        stored = unit_of_work.observations.get(OBSERVATION_ID)
        events = unit_of_work.events.list_for_observation(OBSERVATION_ID)

    assert stored.status == "tracking"
    assert stored.revision == 2
    assert len(events) == 1
    assert events[0].payload == {
        "from": "open",
        "revision": 2,
        "to": "tracking",
    }


def test_event_insert_failure_rolls_back_observation_mutation(tmp_path: Path) -> None:
    database_path = tmp_path / "atomic-rollback.sqlite3"
    _seed_observation(database_path)

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        unit_of_work.events.add(_event())
        unit_of_work.commit()

    with pytest.raises(DuplicateRecordError):
        with SQLiteUnitOfWork(database_path) as unit_of_work:
            unit_of_work.observations.update_status(
                OBSERVATION_ID,
                expected_revision=1,
                new_status="tracking",
                occurred_at=T2,
            )
            unit_of_work.events.add(
                _event(event_type="observation_status_changed", occurred_at=T2)
            )
            unit_of_work.commit()

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        stored = unit_of_work.observations.get(OBSERVATION_ID)
        events = unit_of_work.events.list_for_observation(OBSERVATION_ID)

    assert stored.status == "open"
    assert stored.revision == 1
    assert [event.event_id for event in events] == [EVENT_ID]
