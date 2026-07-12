from pathlib import Path

import pytest

from app.models import FieldObservationRecord
from app.persistence import (
    ObservationEventRecord,
    ProjectRecord,
    RecordNotFound,
    SQLiteUnitOfWork,
    UnitOfWorkStateError,
    serialize_event_payload,
)


PROJECT_ID = "11111111-1111-4111-8111-111111111111"
OBSERVATION_ID = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"
EVENT_ID = "dddddddd-dddd-4ddd-8ddd-dddddddddddd"
T1 = "2026-07-12T09:00:00Z"


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
        notes="Kalici not.",
        created_at=T1,
        updated_at=T1,
    )


def _event() -> ObservationEventRecord:
    return ObservationEventRecord(
        event_id=EVENT_ID,
        observation_id=OBSERVATION_ID,
        event_type="observation_created",
        actor="Santiye sefi",
        occurred_at=T1,
        payload_json=serialize_event_payload({"status": "open"}),
    )


def test_commit_persists_records_across_new_unit_of_work_instance(
    tmp_path: Path,
) -> None:
    database_path = tmp_path / "reopen.sqlite3"

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        unit_of_work.projects.add(_project())
        unit_of_work.observations.add(_observation())
        unit_of_work.commit()

    with SQLiteUnitOfWork(database_path) as reopened:
        assert reopened.projects.get(PROJECT_ID) == _project()
        assert reopened.observations.get(OBSERVATION_ID) == _observation()


def test_context_exit_without_commit_rolls_back_all_writes(tmp_path: Path) -> None:
    database_path = tmp_path / "implicit-rollback.sqlite3"

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        unit_of_work.projects.add(_project())
        unit_of_work.observations.add(_observation())

    with SQLiteUnitOfWork(database_path) as reopened:
        with pytest.raises(RecordNotFound):
            reopened.projects.get(PROJECT_ID)
        with pytest.raises(RecordNotFound):
            reopened.observations.get(OBSERVATION_ID)


def test_exception_rolls_back_project_observation_and_event(tmp_path: Path) -> None:
    database_path = tmp_path / "exception-rollback.sqlite3"

    with pytest.raises(RuntimeError, match="injected failure"):
        with SQLiteUnitOfWork(database_path) as unit_of_work:
            unit_of_work.projects.add(_project())
            unit_of_work.observations.add(_observation())
            unit_of_work.events.add(_event())
            raise RuntimeError("injected failure")

    with SQLiteUnitOfWork(database_path) as reopened:
        with pytest.raises(RecordNotFound):
            reopened.projects.get(PROJECT_ID)
        with pytest.raises(RecordNotFound):
            reopened.observations.get(OBSERVATION_ID)
        assert reopened.events.list_for_observation(OBSERVATION_ID) == []


def test_unit_of_work_rejects_nested_entry_and_instance_reuse(tmp_path: Path) -> None:
    unit_of_work = SQLiteUnitOfWork(tmp_path / "state.sqlite3")

    with unit_of_work:
        with pytest.raises(UnitOfWorkStateError, match="already been used"):
            unit_of_work.__enter__()

    with pytest.raises(UnitOfWorkStateError, match="already been used"):
        unit_of_work.__enter__()


def test_repository_reference_rejects_use_after_context_exit(tmp_path: Path) -> None:
    database_path = tmp_path / "closed-connection.sqlite3"

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        projects = unit_of_work.projects

    with pytest.raises(UnitOfWorkStateError, match="no longer active"):
        projects.list_all()


def test_commit_requires_active_transaction(tmp_path: Path) -> None:
    unit_of_work = SQLiteUnitOfWork(tmp_path / "commit-state.sqlite3")

    with pytest.raises(UnitOfWorkStateError, match="not active"):
        unit_of_work.commit()

    with unit_of_work:
        unit_of_work.commit()
        with pytest.raises(UnitOfWorkStateError, match="already completed"):
            unit_of_work.commit()
