import sqlite3
from pathlib import Path

import pytest

from app.models import FieldObservationRecord
from app.persistence import (
    ArchivedRecordError,
    DuplicateRecordError,
    ForeignKeyViolation,
    InvalidRecordError,
    InvalidTransition,
    ProjectRecord,
    RecordNotFound,
    RevisionConflict,
    SQLiteUnitOfWork,
)


PROJECT_ID = "11111111-1111-4111-8111-111111111111"
SECOND_PROJECT_ID = "22222222-2222-4222-8222-222222222222"
OBSERVATION_ID = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"
SECOND_OBSERVATION_ID = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"
THIRD_OBSERVATION_ID = "cccccccc-cccc-4ccc-8ccc-cccccccccccc"
T1 = "2026-07-12T09:00:00Z"
T2 = "2026-07-12T10:00:00Z"
T3 = "2026-07-12T11:00:00Z"


def _project(
    project_id: str = PROJECT_ID,
    *,
    name: str = "Ornek Santiye",
    created_at: str = T1,
) -> ProjectRecord:
    return ProjectRecord(project_id=project_id, name=name, created_at=created_at)


def _observation(
    observation_id: str = OBSERVATION_ID,
    *,
    project_id: str = PROJECT_ID,
    observed_at: str = T1,
    status: str = "open",
    closed_at: str | None = None,
    notes: str | None = "Kolon kalibi fotografla kontrol edildi.",
) -> FieldObservationRecord:
    return FieldObservationRecord(
        observation_id=observation_id,
        project_id=project_id,
        observed_at=observed_at,
        location="A Blok 2. Kat",
        category="quality",
        description="Kalip birlesiminde aciklik goruldu.",
        status=status,
        closed_at=closed_at,
        notes=notes,
        created_at=T1,
        updated_at=T1,
    )


def _seed_observation(
    database_path: Path,
    *,
    observation: FieldObservationRecord | None = None,
) -> None:
    with SQLiteUnitOfWork(database_path) as unit_of_work:
        unit_of_work.projects.add(_project())
        unit_of_work.observations.add(observation or _observation())
        unit_of_work.commit()


def test_project_repository_add_get_and_list_are_persistent_and_deterministic(
    tmp_path: Path,
) -> None:
    database_path = tmp_path / "projects.sqlite3"

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        unit_of_work.projects.add(
            _project(SECOND_PROJECT_ID, name="Ikinci Proje", created_at=T2)
        )
        unit_of_work.projects.add(_project())
        unit_of_work.commit()

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        assert unit_of_work.projects.get(PROJECT_ID) == _project()
        assert unit_of_work.projects.list_all() == [
            _project(),
            _project(SECOND_PROJECT_ID, name="Ikinci Proje", created_at=T2),
        ]


def test_duplicate_project_and_observation_ids_raise_explicit_errors(
    tmp_path: Path,
) -> None:
    database_path = tmp_path / "duplicates.sqlite3"

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        unit_of_work.projects.add(_project())

        with pytest.raises(DuplicateRecordError) as project_error:
            unit_of_work.projects.add(_project())

        unit_of_work.observations.add(_observation())
        with pytest.raises(DuplicateRecordError) as observation_error:
            unit_of_work.observations.add(_observation())

    assert isinstance(project_error.value.__cause__, sqlite3.IntegrityError)
    assert isinstance(observation_error.value.__cause__, sqlite3.IntegrityError)


def test_observation_foreign_key_violation_raises_explicit_error(
    tmp_path: Path,
) -> None:
    database_path = tmp_path / "foreign-key.sqlite3"

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        with pytest.raises(ForeignKeyViolation) as error:
            unit_of_work.observations.add(
                _observation(project_id=SECOND_PROJECT_ID)
            )

    assert isinstance(error.value.__cause__, sqlite3.IntegrityError)


def test_observation_get_list_and_filters_are_deterministic(tmp_path: Path) -> None:
    database_path = tmp_path / "listing.sqlite3"

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        unit_of_work.projects.add(_project())
        unit_of_work.projects.add(
            _project(SECOND_PROJECT_ID, name="Ikinci Proje", created_at=T2)
        )
        second = _observation(
            SECOND_OBSERVATION_ID,
            observed_at=T2,
            status="tracking",
        )
        first = _observation()
        third = _observation(
            THIRD_OBSERVATION_ID,
            project_id=SECOND_PROJECT_ID,
            observed_at=T3,
        )
        unit_of_work.observations.add(second)
        unit_of_work.observations.add(third)
        unit_of_work.observations.add(first)
        unit_of_work.commit()

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        assert unit_of_work.observations.get(OBSERVATION_ID) == first
        assert unit_of_work.observations.list_all() == [first, second, third]
        assert unit_of_work.observations.list_by_project_id(PROJECT_ID) == [
            first,
            second,
        ]
        assert unit_of_work.observations.list_by_status("open") == [first, third]


def test_missing_records_raise_record_not_found(tmp_path: Path) -> None:
    database_path = tmp_path / "missing.sqlite3"

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        with pytest.raises(RecordNotFound):
            unit_of_work.projects.get(PROJECT_ID)
        with pytest.raises(RecordNotFound):
            unit_of_work.observations.get(OBSERVATION_ID)


def test_status_update_increments_revision_and_sets_closed_at(tmp_path: Path) -> None:
    database_path = tmp_path / "status.sqlite3"
    _seed_observation(database_path)

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        tracking = unit_of_work.observations.update_status(
            OBSERVATION_ID,
            expected_revision=1,
            new_status="tracking",
            occurred_at=T2,
        )
        assert tracking.status == "tracking"
        assert tracking.closed_at is None
        assert tracking.updated_at == T2
        assert tracking.revision == 2
        unit_of_work.commit()

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        closed = unit_of_work.observations.update_status(
            OBSERVATION_ID,
            expected_revision=2,
            new_status="closed",
            occurred_at=T3,
        )
        assert closed.status == "closed"
        assert closed.closed_at == T3
        assert closed.updated_at == T3
        assert closed.revision == 3
        unit_of_work.commit()

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        assert unit_of_work.observations.get(OBSERVATION_ID) == closed


def test_same_status_update_is_no_op_without_revision_change(tmp_path: Path) -> None:
    database_path = tmp_path / "status-no-op.sqlite3"
    _seed_observation(database_path)

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        result = unit_of_work.observations.update_status(
            OBSERVATION_ID,
            expected_revision=1,
            new_status="open",
            occurred_at=T2,
        )
        assert unit_of_work.events.list_for_observation(OBSERVATION_ID) == []
        unit_of_work.commit()

    assert result.status == "open"
    assert result.updated_at == T1
    assert result.revision == 1


def test_invalid_status_transition_leaves_record_unchanged(tmp_path: Path) -> None:
    database_path = tmp_path / "invalid-transition.sqlite3"
    _seed_observation(
        database_path,
        observation=_observation(status="tracking"),
    )

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        with pytest.raises(InvalidTransition):
            unit_of_work.observations.update_status(
                OBSERVATION_ID,
                expected_revision=1,
                new_status="open",
                occurred_at=T2,
            )

        unchanged = unit_of_work.observations.get(OBSERVATION_ID)

    assert unchanged.status == "tracking"
    assert unchanged.revision == 1
    assert unchanged.updated_at == T1


def test_closed_observation_cannot_be_reopened(tmp_path: Path) -> None:
    database_path = tmp_path / "closed-reopen.sqlite3"
    _seed_observation(
        database_path,
        observation=_observation(status="closed", closed_at=T1),
    )

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        with pytest.raises(InvalidTransition):
            unit_of_work.observations.update_status(
                OBSERVATION_ID,
                expected_revision=1,
                new_status="open",
                occurred_at=T2,
            )
        unchanged = unit_of_work.observations.get(OBSERVATION_ID)

    assert unchanged.status == "closed"
    assert unchanged.closed_at == T1
    assert unchanged.revision == 1


def test_stale_revision_conflict_leaves_record_unchanged(tmp_path: Path) -> None:
    database_path = tmp_path / "revision-conflict.sqlite3"
    _seed_observation(database_path)

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        with pytest.raises(RevisionConflict) as error:
            unit_of_work.observations.update_status(
                OBSERVATION_ID,
                expected_revision=2,
                new_status="tracking",
                occurred_at=T2,
            )
        unchanged = unit_of_work.observations.get(OBSERVATION_ID)

    assert error.value.expected_revision == 2
    assert error.value.actual_revision == 1
    assert unchanged.status == "open"
    assert unchanged.revision == 1


def test_reporting_update_persists_fields_and_increments_revision(
    tmp_path: Path,
) -> None:
    database_path = tmp_path / "reporting.sqlite3"
    _seed_observation(database_path)

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        updated = unit_of_work.observations.update_reporting(
            OBSERVATION_ID,
            expected_revision=1,
            reported_to="Saha formeni",
            reported_at=T2,
            occurred_at=T3,
        )
        unit_of_work.commit()

    assert updated.reported_to == "Saha formeni"
    assert updated.reported_at == T2
    assert updated.updated_at == T3
    assert updated.revision == 2

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        assert unit_of_work.observations.get(OBSERVATION_ID) == updated


@pytest.mark.parametrize("reported_to", ["", "   "])
def test_reporting_update_rejects_empty_recipient_without_mutation(
    tmp_path: Path,
    reported_to: str,
) -> None:
    database_path = tmp_path / f"empty-reporting-{len(reported_to)}.sqlite3"
    _seed_observation(database_path)

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        with pytest.raises(InvalidRecordError):
            unit_of_work.observations.update_reporting(
                OBSERVATION_ID,
                expected_revision=1,
                reported_to=reported_to,
                reported_at=T2,
                occurred_at=T3,
            )
        unchanged = unit_of_work.observations.get(OBSERVATION_ID)

    assert unchanged.reported_to is None
    assert unchanged.reported_at is None
    assert unchanged.revision == 1


@pytest.mark.parametrize(
    ("reported_at", "occurred_at"),
    [
        ("2026-07-12T13:00:00+03:00", T3),
        (T2, "2026-07-12 11:00:00Z"),
    ],
)
def test_reporting_update_rejects_noncanonical_timestamps_without_mutation(
    tmp_path: Path,
    reported_at: str,
    occurred_at: str,
) -> None:
    database_path = tmp_path / f"invalid-time-{len(reported_at)}.sqlite3"
    _seed_observation(database_path)

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        with pytest.raises(InvalidRecordError):
            unit_of_work.observations.update_reporting(
                OBSERVATION_ID,
                expected_revision=1,
                reported_to="Saha formeni",
                reported_at=reported_at,
                occurred_at=occurred_at,
            )
        unchanged = unit_of_work.observations.get(OBSERVATION_ID)

    assert unchanged.reported_to is None
    assert unchanged.reported_at is None
    assert unchanged.revision == 1


def test_archive_persists_timestamp_and_blocks_later_mutation(tmp_path: Path) -> None:
    database_path = tmp_path / "archive.sqlite3"
    _seed_observation(database_path)

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        archived = unit_of_work.observations.archive(
            OBSERVATION_ID,
            expected_revision=1,
            occurred_at=T2,
        )
        assert archived.is_archived is True
        assert archived.archived_at == T2
        assert archived.updated_at == T2
        assert archived.revision == 2
        unit_of_work.commit()

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        with pytest.raises(ArchivedRecordError):
            unit_of_work.observations.update_status(
                OBSERVATION_ID,
                expected_revision=2,
                new_status="tracking",
                occurred_at=T3,
            )
        unchanged = unit_of_work.observations.get(OBSERVATION_ID)

    assert unchanged == archived


def test_notes_round_trip_without_silent_loss(tmp_path: Path) -> None:
    database_path = tmp_path / "notes.sqlite3"
    notes = "Demir donati ve pas payi yeniden kontrol edilecek."
    _seed_observation(database_path, observation=_observation(notes=notes))

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        stored = unit_of_work.observations.get(OBSERVATION_ID)

    assert stored.notes == notes
