import sqlite3
from collections.abc import Iterator
from pathlib import Path

import pytest

from app.persistence import (
    Migration,
    SCHEMA_MIGRATIONS,
    SCHEMA_VERSION,
    connect_database,
    migrate_database,
    validate_utc_timestamp,
)


PROJECT_ID = "8b18ce4a-142f-4ca7-bac0-6fd98ce19d27"
OBSERVATION_ID = "d4a3a544-859c-43b4-a06d-2ec81c4738b8"
TIMESTAMP = "2026-07-12T18:30:00Z"


@pytest.fixture
def database(tmp_path: Path) -> Iterator[sqlite3.Connection]:
    database_path = tmp_path / "chief-site-engineer.sqlite3"
    connection = connect_database(database_path)
    migrate_database(connection)
    yield connection
    connection.close()


def _insert_project(connection: sqlite3.Connection, project_id: str = PROJECT_ID) -> None:
    connection.execute(
        "INSERT INTO projects (id, name, created_at) VALUES (?, ?, ?)",
        (project_id, "Ornek Santiye", TIMESTAMP),
    )


def _insert_observation(
    connection: sqlite3.Connection,
    observation_id: str = OBSERVATION_ID,
    *,
    project_id: str = PROJECT_ID,
    status: str = "open",
    closed_at: str | None = None,
    revision: int | None = None,
) -> None:
    columns = [
        "id",
        "project_id",
        "observed_at",
        "location",
        "category",
        "description",
        "status",
        "created_at",
        "updated_at",
        "closed_at",
    ]
    values: list[object] = [
        observation_id,
        project_id,
        TIMESTAMP,
        "A Blok 2. Kat",
        "quality",
        "Kalip birlesiminde aciklik goruldu.",
        status,
        TIMESTAMP,
        TIMESTAMP,
        closed_at,
    ]
    if revision is not None:
        columns.append("revision")
        values.append(revision)

    placeholders = ", ".join("?" for _ in values)
    connection.execute(
        f"INSERT INTO field_observations ({', '.join(columns)}) "
        f"VALUES ({placeholders})",
        values,
    )


def _insert_attachment(
    connection: sqlite3.Connection,
    attachment_id: str,
    stored_relative_path: str,
    *,
    size_bytes: int = 1024,
) -> None:
    connection.execute(
        """
        INSERT INTO attachments (
            id,
            observation_id,
            original_name,
            stored_relative_path,
            sha256,
            size_bytes,
            status,
            created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            attachment_id,
            OBSERVATION_ID,
            "saha-fotografi.jpg",
            stored_relative_path,
            "a" * 64,
            size_bytes,
            "active",
            TIMESTAMP,
        ),
    )


def test_fresh_database_migrates_to_current_schema(tmp_path: Path) -> None:
    database_path = tmp_path / "fresh.sqlite3"
    connection = connect_database(database_path)

    try:
        version = migrate_database(connection)
        table_names = {
            row[0]
            for row in connection.execute(
                "SELECT name FROM sqlite_master WHERE type = 'table'"
            )
        }
        observation_columns = {
            row[1]
            for row in connection.execute(
                "PRAGMA table_info(field_observations)"
            )
        }
    finally:
        connection.close()

    assert database_path.is_file()
    assert version == SCHEMA_VERSION == 2
    assert table_names == {
        "schema_migrations",
        "projects",
        "field_observations",
        "attachments",
        "observation_events",
    }
    assert "notes" in observation_columns


def test_migration_is_idempotent(tmp_path: Path) -> None:
    connection = connect_database(tmp_path / "idempotent.sqlite3")

    try:
        first_version = migrate_database(connection)
        first_tables = list(
            connection.execute(
                "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name"
            )
        )
        second_version = migrate_database(connection)
        second_tables = list(
            connection.execute(
                "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name"
            )
        )
        migration_count = connection.execute(
            "SELECT COUNT(*) FROM schema_migrations"
        ).fetchone()[0]
    finally:
        connection.close()

    assert first_version == second_version == SCHEMA_VERSION == 2
    assert second_tables == first_tables
    assert migration_count == 2


def test_schema_migrations_records_every_version(database: sqlite3.Connection) -> None:
    migration_rows = list(
        database.execute(
            "SELECT version, applied_at FROM schema_migrations ORDER BY version"
        )
    )

    assert [row[0] for row in migration_rows] == [1, 2]
    assert all(
        validate_utc_timestamp(row[1]) == row[1] for row in migration_rows
    )


def test_version_one_database_migrates_to_version_two_idempotently(
    tmp_path: Path,
) -> None:
    connection = connect_database(tmp_path / "v1-to-v2.sqlite3")

    try:
        assert migrate_database(connection, migrations=SCHEMA_MIGRATIONS[:1]) == 1
        columns_before = {
            row[1]
            for row in connection.execute(
                "PRAGMA table_info(field_observations)"
            )
        }

        assert migrate_database(connection) == 2
        assert migrate_database(connection) == 2
        columns_after = {
            row[1]
            for row in connection.execute(
                "PRAGMA table_info(field_observations)"
            )
        }
        versions = [
            row[0]
            for row in connection.execute(
                "SELECT version FROM schema_migrations ORDER BY version"
            )
        ]
    finally:
        connection.close()

    assert "notes" not in columns_before
    assert "notes" in columns_after
    assert versions == [1, 2]


def test_foreign_keys_are_enabled_and_violation_is_rejected(
    database: sqlite3.Connection,
) -> None:
    assert database.execute("PRAGMA foreign_keys").fetchone()[0] == 1

    with pytest.raises(sqlite3.IntegrityError):
        _insert_observation(
            database,
            project_id="c71c2794-160f-4c6a-b082-a840b60bf427",
        )


def test_duplicate_primary_key_is_rejected(database: sqlite3.Connection) -> None:
    _insert_project(database)

    with pytest.raises(sqlite3.IntegrityError):
        _insert_project(database)


def test_invalid_observation_status_is_rejected(database: sqlite3.Connection) -> None:
    _insert_project(database)

    with pytest.raises(sqlite3.IntegrityError):
        _insert_observation(database, status="invalid")


def test_revision_defaults_to_one_and_values_below_one_are_rejected(
    database: sqlite3.Connection,
) -> None:
    _insert_project(database)
    _insert_observation(database)

    revision = database.execute(
        "SELECT revision FROM field_observations WHERE id = ?",
        (OBSERVATION_ID,),
    ).fetchone()[0]

    assert revision == 1

    with pytest.raises(sqlite3.IntegrityError):
        _insert_observation(
            database,
            observation_id="5f728996-5763-4b30-b4d0-25297cf56db6",
            revision=0,
        )


def test_negative_attachment_size_is_rejected(database: sqlite3.Connection) -> None:
    _insert_project(database)
    _insert_observation(database)

    with pytest.raises(sqlite3.IntegrityError):
        _insert_attachment(
            database,
            "c325af7a-f6e4-45cc-b1a2-97ffc1d24053",
            "attachments/observation/photo-1.jpg",
            size_bytes=-1,
        )


def test_duplicate_stored_relative_path_is_rejected(
    database: sqlite3.Connection,
) -> None:
    _insert_project(database)
    _insert_observation(database)
    stored_path = "attachments/observation/photo-1.jpg"
    _insert_attachment(
        database,
        "bc5ad367-52c7-4276-bcb8-e00dd2252811",
        stored_path,
    )

    with pytest.raises(sqlite3.IntegrityError):
        _insert_attachment(
            database,
            "d7e36e9c-9d63-4a93-bf4a-81e22f901334",
            stored_path,
        )


@pytest.mark.parametrize(
    ("status", "closed_at"),
    [
        ("closed", None),
        ("open", TIMESTAMP),
        ("tracking", TIMESTAMP),
    ],
)
def test_closed_status_and_closed_at_inconsistency_is_rejected(
    database: sqlite3.Connection,
    status: str,
    closed_at: str | None,
) -> None:
    _insert_project(database)

    with pytest.raises(sqlite3.IntegrityError):
        _insert_observation(database, status=status, closed_at=closed_at)


def test_migration_failure_rolls_back_schema_and_version_record(tmp_path: Path) -> None:
    connection = connect_database(tmp_path / "failure.sqlite3")
    failing_migration = Migration(
        version=1,
        statements=(
            "CREATE TABLE partial_table (id TEXT PRIMARY KEY)",
            "CREATE TABLE broken_table (",
        ),
    )

    try:
        with pytest.raises(sqlite3.OperationalError):
            migrate_database(connection, migrations=(failing_migration,))

        remaining_tables = list(
            connection.execute(
                "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name"
            )
        )
    finally:
        connection.close()

    assert remaining_tables == []


def test_unknown_future_migration_version_is_rejected_without_schema_change(
    tmp_path: Path,
) -> None:
    connection = connect_database(tmp_path / "future-version.sqlite3")

    try:
        migrate_database(connection)
        connection.execute(
            "INSERT INTO schema_migrations (version, applied_at) VALUES (?, ?)",
            (99, TIMESTAMP),
        )

        with pytest.raises(RuntimeError, match="unknown migration versions: 99"):
            migrate_database(connection)

        versions = [
            row[0]
            for row in connection.execute(
                "SELECT version FROM schema_migrations ORDER BY version"
            )
        ]
        notes_count = connection.execute(
            "SELECT COUNT(*) FROM pragma_table_info('field_observations') "
            "WHERE name = 'notes'"
        ).fetchone()[0]
    finally:
        connection.close()

    assert versions == [1, 2, 99]
    assert notes_count == 1
