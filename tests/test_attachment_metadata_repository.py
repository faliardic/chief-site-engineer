import sqlite3
from pathlib import Path

import pytest

from app.models import FieldObservationRecord
from app.persistence import (
    AttachmentMetadataRecord,
    DuplicateRecordError,
    ForeignKeyViolation,
    InvalidRecordError,
    ProjectRecord,
    RecordNotFound,
    SQLiteUnitOfWork,
    UnitOfWorkStateError,
    connect_database,
    migrate_database,
)


PROJECT_ID = "11111111-1111-4111-8111-111111111111"
OBSERVATION_ID = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"
SECOND_OBSERVATION_ID = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"
ATTACHMENT_ID = "dddddddd-dddd-4ddd-8ddd-dddddddddddd"
SECOND_ATTACHMENT_ID = "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee"
T1 = "2026-07-13T08:00:00Z"
T2 = "2026-07-13T09:00:00Z"


def _observation(observation_id: str = OBSERVATION_ID) -> FieldObservationRecord:
    return FieldObservationRecord(
        observation_id=observation_id,
        project_id=PROJECT_ID,
        observed_at=T1,
        location="A Blok 2. Kat",
        category="quality",
        description="Kalip birlesiminde aciklik goruldu.",
        created_at=T1,
        updated_at=T1,
    )


def _attachment(
    attachment_id: str = ATTACHMENT_ID,
    *,
    observation_id: str = OBSERVATION_ID,
    stored_relative_path: str | None = None,
    sha256: str = "a" * 64,
    size_bytes: int = 128,
    status: str = "active",
    created_at: str = T1,
) -> AttachmentMetadataRecord:
    path = stored_relative_path or (
        f"attachments/{observation_id}/{attachment_id}.jpg"
    )
    return AttachmentMetadataRecord(
        attachment_id=attachment_id,
        observation_id=observation_id,
        original_name="Saha Fotoğrafı.JPG",
        stored_relative_path=path,
        sha256=sha256,
        size_bytes=size_bytes,
        mime_type="image/jpeg",
        status=status,
        created_at=created_at,
        created_by="Santiye sefi",
    )


def _seed_observations(database_path: Path) -> None:
    with SQLiteUnitOfWork(database_path) as unit_of_work:
        unit_of_work.projects.add(ProjectRecord(PROJECT_ID, "Ornek Santiye", T1))
        unit_of_work.observations.add(_observation())
        unit_of_work.observations.add(_observation(SECOND_OBSERVATION_ID))
        unit_of_work.commit()


def test_attachment_add_get_and_lists_persist_deterministically(tmp_path: Path) -> None:
    database_path = tmp_path / "attachments.sqlite3"
    _seed_observations(database_path)
    first = _attachment()
    second = _attachment(
        SECOND_ATTACHMENT_ID,
        observation_id=SECOND_OBSERVATION_ID,
        created_at=T2,
    )

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        unit_of_work.attachments.add(second)
        unit_of_work.attachments.add(first)
        unit_of_work.commit()

    with SQLiteUnitOfWork(database_path) as reopened:
        assert reopened.attachments.get(ATTACHMENT_ID) == first
        assert reopened.attachments.list_all() == [first, second]
        assert reopened.attachments.list_for_observation(OBSERVATION_ID) == [first]
        assert reopened.attachments.list_for_observation(
            SECOND_OBSERVATION_ID
        ) == [second]


def test_attachment_get_missing_raises_record_not_found(tmp_path: Path) -> None:
    database_path = tmp_path / "missing.sqlite3"

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        with pytest.raises(RecordNotFound):
            unit_of_work.attachments.get(ATTACHMENT_ID)


def test_duplicate_attachment_id_and_path_raise_explicit_errors(
    tmp_path: Path,
) -> None:
    database_path = tmp_path / "duplicates.sqlite3"
    _seed_observations(database_path)
    first = _attachment()

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        unit_of_work.attachments.add(first)
        unit_of_work.commit()

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        with pytest.raises(DuplicateRecordError) as id_error:
            unit_of_work.attachments.add(first)

    duplicate_path = (
        f"attachments/{OBSERVATION_ID}/{SECOND_ATTACHMENT_ID}.jpg"
    )
    connection = connect_database(database_path)
    try:
        migrate_database(connection)
        connection.execute("BEGIN IMMEDIATE")
        connection.execute(
            """
            INSERT INTO attachments (
                id, observation_id, original_name, stored_relative_path,
                sha256, size_bytes, mime_type, status, created_at, created_by
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                "99999999-9999-4999-8999-999999999999",
                OBSERVATION_ID,
                "legacy.jpg",
                duplicate_path,
                "b" * 64,
                64,
                "image/jpeg",
                "active",
                T1,
                None,
            ),
        )
        connection.commit()
    finally:
        connection.close()

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        with pytest.raises(DuplicateRecordError) as path_error:
            unit_of_work.attachments.add(
                _attachment(
                    SECOND_ATTACHMENT_ID,
                    stored_relative_path=duplicate_path,
                )
            )

    assert isinstance(id_error.value.__cause__, sqlite3.IntegrityError)
    assert isinstance(path_error.value.__cause__, sqlite3.IntegrityError)


def test_attachment_missing_observation_fk_raises_explicit_error(
    tmp_path: Path,
) -> None:
    database_path = tmp_path / "foreign-key.sqlite3"

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        with pytest.raises(ForeignKeyViolation) as error:
            unit_of_work.attachments.add(_attachment())

    assert isinstance(error.value.__cause__, sqlite3.IntegrityError)


@pytest.mark.parametrize(
    "changes",
    [
        {"sha256": "A" * 64},
        {"sha256": "a" * 63},
        {"size_bytes": -1},
        {"status": "missing"},
        {"stored_relative_path": "/attachments/file.jpg"},
        {"stored_relative_path": "attachments/../file.jpg"},
        {"stored_relative_path": "attachments\\obs\\file.jpg"},
        {"stored_relative_path": "attachments//file.jpg"},
        {
            "stored_relative_path": (
                f"attachments/{SECOND_OBSERVATION_ID}/{ATTACHMENT_ID}.jpg"
            )
        },
        {
            "stored_relative_path": (
                f"attachments/{OBSERVATION_ID}/{SECOND_ATTACHMENT_ID}.jpg"
            )
        },
    ],
)
def test_invalid_attachment_metadata_is_rejected_before_write(
    tmp_path: Path,
    changes: dict[str, object],
) -> None:
    database_path = tmp_path / "invalid.sqlite3"
    _seed_observations(database_path)
    values: dict[str, object] = {
        "stored_relative_path": None,
        "sha256": "a" * 64,
        "size_bytes": 128,
        "status": "active",
    }
    values.update(changes)

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        with pytest.raises(InvalidRecordError):
            unit_of_work.attachments.add(
                _attachment(
                    stored_relative_path=values["stored_relative_path"],
                    sha256=values["sha256"],
                    size_bytes=values["size_bytes"],
                    status=values["status"],
                )
            )
        assert unit_of_work.attachments.list_all() == []


def test_attachment_write_rolls_back_without_explicit_commit(tmp_path: Path) -> None:
    database_path = tmp_path / "rollback.sqlite3"
    _seed_observations(database_path)

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        unit_of_work.attachments.add(_attachment())

    with SQLiteUnitOfWork(database_path) as reopened:
        assert reopened.attachments.list_all() == []


def test_attachment_repository_reference_rejects_use_after_context(
    tmp_path: Path,
) -> None:
    database_path = tmp_path / "lifecycle.sqlite3"

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        attachments = unit_of_work.attachments

    with pytest.raises(UnitOfWorkStateError, match="no longer active"):
        attachments.list_all()
