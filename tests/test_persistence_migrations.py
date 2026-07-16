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
FOLLOW_UP_ID = "9ed9f7cd-36cc-4283-a457-7cb871f2dbbb"
FOLLOW_UP_EVENT_ID = "24cc9ed9-f7cd-46cc-8283-a4577cb871f2"
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


def _insert_follow_up(connection: sqlite3.Connection) -> None:
    connection.execute(
        """
        INSERT INTO follow_up_items (
            id, capture_text, title, item_type, status, is_important,
            revision, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            FOLLOW_UP_ID,
            "Kalıp kontrolünü unutma",
            "Kalıp kontrolü",
            "action",
            "inbox",
            0,
            1,
            TIMESTAMP,
            TIMESTAMP,
        ),
    )


def _insert_follow_up_event(
    connection: sqlite3.Connection,
    *,
    event_id: str = FOLLOW_UP_EVENT_ID,
    follow_up_id: str = FOLLOW_UP_ID,
    sequence: int = 1,
    event_type: str = "follow_up.created",
    payload_json: str = '{"revision":1}',
) -> None:
    connection.execute(
        """
        INSERT INTO follow_up_events (
            id, follow_up_id, sequence, event_type, actor, occurred_at,
            payload_json
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
        """,
        (
            event_id,
            follow_up_id,
            sequence,
            event_type,
            "Santiye sefi",
            TIMESTAMP,
            payload_json,
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
    assert version == SCHEMA_VERSION == 4
    assert table_names == {
        "schema_migrations",
        "projects",
        "field_observations",
        "attachments",
        "observation_events",
        "follow_up_items",
        "follow_up_events",
        "routine_templates",
        "routine_template_weekdays",
        "routine_occurrences",
        "routine_template_events",
        "routine_occurrence_events",
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

    assert first_version == second_version == SCHEMA_VERSION == 4
    assert second_tables == first_tables
    assert migration_count == 4


def test_schema_migrations_records_every_version(database: sqlite3.Connection) -> None:
    migration_rows = list(
        database.execute(
            "SELECT version, applied_at FROM schema_migrations ORDER BY version"
        )
    )

    assert [row[0] for row in migration_rows] == [1, 2, 3, 4]
    assert all(
        validate_utc_timestamp(row[1]) == row[1] for row in migration_rows
    )


def test_version_one_database_migrates_to_current_version_idempotently(
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

        assert migrate_database(connection) == 4
        assert migrate_database(connection) == 4
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
    assert versions == [1, 2, 3, 4]


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

    assert versions == [1, 2, 3, 4, 99]
    assert notes_count == 1


def _schema_signature(connection: sqlite3.Connection) -> list[tuple[object, ...]]:
    return list(
        connection.execute(
            """
            SELECT type, name, tbl_name, sql
            FROM sqlite_master
            WHERE name NOT LIKE 'sqlite_%'
            ORDER BY type, name
            """
        )
    )


def test_fresh_v4_and_v3_upgrade_produce_identical_schema(tmp_path: Path) -> None:
    fresh = connect_database(tmp_path / "fresh-v4.sqlite3")
    upgraded = connect_database(tmp_path / "upgraded-v4.sqlite3")

    try:
        assert migrate_database(fresh) == 4
        assert migrate_database(upgraded, migrations=SCHEMA_MIGRATIONS[:3]) == 3
        assert migrate_database(upgraded) == 4

        assert _schema_signature(upgraded) == _schema_signature(fresh)
        assert upgraded.execute("PRAGMA foreign_key_check").fetchall() == []
        assert fresh.execute("PRAGMA foreign_key_check").fetchall() == []
    finally:
        fresh.close()
        upgraded.close()


def test_v3_to_v4_preserves_event_row_payload_and_other_schema(
    tmp_path: Path,
) -> None:
    connection = connect_database(tmp_path / "preserved-v3.sqlite3")
    payload_json = '{ "title": "Kalıp", "revision": 1 }'

    try:
        assert migrate_database(connection, migrations=SCHEMA_MIGRATIONS[:3]) == 3
        _insert_follow_up(connection)
        _insert_follow_up_event(connection, payload_json=payload_json)
        row_before = connection.execute(
            "SELECT * FROM follow_up_events WHERE id = ?",
            (FOLLOW_UP_EVENT_ID,),
        ).fetchone()
        table_info_before = list(connection.execute("PRAGMA table_info(follow_up_events)"))
        foreign_keys_before = list(
            connection.execute("PRAGMA foreign_key_list(follow_up_events)")
        )
        other_schema_before = list(
            connection.execute(
                """
                SELECT type, name, tbl_name, sql
                FROM sqlite_master
                WHERE name NOT LIKE 'sqlite_%' AND name <> 'follow_up_events'
                ORDER BY type, name
                """
            )
        )

        assert migrate_database(connection) == 4

        row_after = connection.execute(
            "SELECT * FROM follow_up_events WHERE id = ?",
            (FOLLOW_UP_EVENT_ID,),
        ).fetchone()
        table_info_after = list(connection.execute("PRAGMA table_info(follow_up_events)"))
        foreign_keys_after = list(
            connection.execute("PRAGMA foreign_key_list(follow_up_events)")
        )
        other_schema_after = list(
            connection.execute(
                """
                SELECT type, name, tbl_name, sql
                FROM sqlite_master
                WHERE name NOT LIKE 'sqlite_%' AND name <> 'follow_up_events'
                ORDER BY type, name
                """
            )
        )
        versions = [
            row[0]
            for row in connection.execute(
                "SELECT version FROM schema_migrations ORDER BY version"
            )
        ]
    finally:
        connection.close()

    assert row_after == row_before
    assert row_after[-1] == payload_json
    assert table_info_after == table_info_before
    assert foreign_keys_after == foreign_keys_before
    assert other_schema_after == other_schema_before
    assert versions == [1, 2, 3, 4]


def test_v4_follow_up_event_constraints_and_new_types(tmp_path: Path) -> None:
    connection = connect_database(tmp_path / "v4-event-constraints.sqlite3")
    new_events = (
        (
            "ffffffff-ffff-4fff-8fff-ffffffffffff",
            "follow_up.details_updated",
            '{"changed_fields":["description","title"],"revision":2}',
        ),
        (
            "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee",
            "follow_up.moved_to_inbox",
            (
                '{"from_status":"active","previous_next_attention_at":'
                '"2026-07-12T18:30:00Z","revision":3}'
            ),
        ),
        (
            "dddddddd-dddd-4ddd-8ddd-dddddddddddd",
            "follow_up.project_changed",
            '{"from_project_id":null,"project_id":null,"revision":4}',
        ),
    )

    try:
        assert migrate_database(connection) == 4
        _insert_follow_up(connection)
        for sequence, (event_id, event_type, payload_json) in enumerate(
            new_events, start=1
        ):
            _insert_follow_up_event(
                connection,
                event_id=event_id,
                sequence=sequence,
                event_type=event_type,
                payload_json=payload_json,
            )

        stored = list(
            connection.execute(
                """
                SELECT id, sequence, event_type, payload_json
                FROM follow_up_events
                WHERE follow_up_id = ?
                ORDER BY sequence
                """,
                (FOLLOW_UP_ID,),
            )
        )

        with pytest.raises(sqlite3.IntegrityError):
            _insert_follow_up_event(
                connection,
                event_id="cccccccc-cccc-4ccc-8ccc-cccccccccccc",
                sequence=4,
                event_type="follow_up.unknown",
            )
        with pytest.raises(sqlite3.IntegrityError):
            _insert_follow_up_event(
                connection,
                event_id="bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
                sequence=1,
                event_type="follow_up.details_updated",
            )
        with pytest.raises(sqlite3.IntegrityError):
            _insert_follow_up_event(
                connection,
                event_id="aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
                follow_up_id="11111111-1111-4111-8111-111111111111",
                sequence=1,
                event_type="follow_up.project_changed",
            )
        with pytest.raises(sqlite3.IntegrityError):
            connection.execute(
                """
                INSERT INTO follow_up_events (
                    id, follow_up_id, sequence, event_type, actor, occurred_at,
                    payload_json
                ) VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    "99999999-9999-4999-8999-999999999999",
                    FOLLOW_UP_ID,
                    4,
                    "follow_up.details_updated",
                    "   ",
                    TIMESTAMP,
                    '{"revision":5}',
                ),
            )
        with pytest.raises(sqlite3.IntegrityError):
            connection.execute(
                "DELETE FROM follow_up_items WHERE id = ?", (FOLLOW_UP_ID,)
            )
    finally:
        connection.close()

    assert stored == [
        (event_id, sequence, event_type, payload_json)
        for sequence, (event_id, event_type, payload_json) in enumerate(
            new_events, start=1
        )
    ]


def test_v4_failure_rolls_back_table_rebuild_rows_and_version(tmp_path: Path) -> None:
    connection = connect_database(tmp_path / "failed-v4.sqlite3")
    payload_json = '{ "revision": 1, "note": "aynen koru" }'
    failing_v4 = Migration(
        version=4,
        statements=(
            *SCHEMA_MIGRATIONS[3].statements,
            "CREATE TABLE broken_v4_table (",
        ),
    )

    try:
        assert migrate_database(connection, migrations=SCHEMA_MIGRATIONS[:3]) == 3
        _insert_follow_up(connection)
        _insert_follow_up_event(connection, payload_json=payload_json)
        table_sql_before = connection.execute(
            "SELECT sql FROM sqlite_master WHERE name = 'follow_up_events'"
        ).fetchone()[0]
        row_before = connection.execute(
            "SELECT * FROM follow_up_events WHERE id = ?",
            (FOLLOW_UP_EVENT_ID,),
        ).fetchone()

        with pytest.raises(sqlite3.OperationalError):
            migrate_database(
                connection,
                migrations=(*SCHEMA_MIGRATIONS[:3], failing_v4),
            )

        table_sql_after = connection.execute(
            "SELECT sql FROM sqlite_master WHERE name = 'follow_up_events'"
        ).fetchone()[0]
        row_after = connection.execute(
            "SELECT * FROM follow_up_events WHERE id = ?",
            (FOLLOW_UP_EVENT_ID,),
        ).fetchone()
        versions = [
            row[0]
            for row in connection.execute(
                "SELECT version FROM schema_migrations ORDER BY version"
            )
        ]
        temporary_table_count = connection.execute(
            "SELECT COUNT(*) FROM sqlite_master WHERE name = 'follow_up_events_v4'"
        ).fetchone()[0]
    finally:
        connection.close()

    assert table_sql_after == table_sql_before
    assert row_after == row_before
    assert row_after[-1] == payload_json
    assert versions == [1, 2, 3]
    assert temporary_table_count == 0


def test_v2_upgrade_preserves_existing_rows_and_event_payload_exactly(
    tmp_path: Path,
) -> None:
    connection = connect_database(tmp_path / "preserved-v2.sqlite3")
    attachment_id = "7ff50c62-4ed0-4c21-8d0e-e8ce97c98bb6"
    event_id = "8fabee8d-2494-4bb8-97cb-d308e86fd74c"
    payload_json = '{"description":"kalıp","revision":1}'

    try:
        assert migrate_database(connection, migrations=SCHEMA_MIGRATIONS[:2]) == 2
        _insert_project(connection)
        _insert_observation(connection)
        _insert_attachment(
            connection,
            attachment_id,
            "attachments/preserved/photo.jpg",
        )
        connection.execute(
            """
            INSERT INTO observation_events (
                id, observation_id, event_type, actor, occurred_at, payload_json
            ) VALUES (?, ?, ?, ?, ?, ?)
            """,
            (
                event_id,
                OBSERVATION_ID,
                "observation_created",
                "Santiye sefi",
                TIMESTAMP,
                payload_json,
            ),
        )
        before = {
            table: list(connection.execute(f"SELECT * FROM {table} ORDER BY rowid"))
            for table in (
                "projects",
                "field_observations",
                "attachments",
                "observation_events",
            )
        }

        assert migrate_database(connection) == 4
        after = {
            table: list(connection.execute(f"SELECT * FROM {table} ORDER BY rowid"))
            for table in before
        }
    finally:
        connection.close()

    assert after == before
    assert after["observation_events"][0][-1] == payload_json


def test_v3_failure_rolls_back_partial_schema_and_version(tmp_path: Path) -> None:
    connection = connect_database(tmp_path / "failed-v3.sqlite3")
    failing_v3 = Migration(
        version=3,
        statements=(
            "CREATE TABLE partial_tracking_table (id TEXT PRIMARY KEY)",
            "CREATE TABLE broken_tracking_table (",
        ),
    )

    try:
        assert migrate_database(connection, migrations=SCHEMA_MIGRATIONS[:2]) == 2
        with pytest.raises(sqlite3.OperationalError):
            migrate_database(
                connection,
                migrations=(*SCHEMA_MIGRATIONS[:2], failing_v3),
            )
        tables = {
            row[0]
            for row in connection.execute(
                "SELECT name FROM sqlite_master WHERE type = 'table'"
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

    assert "partial_tracking_table" not in tables
    assert "broken_tracking_table" not in tables
    assert versions == [1, 2]


def test_v3_tracking_tables_do_not_use_on_delete_cascade(
    database: sqlite3.Connection,
) -> None:
    tracking_tables = (
        "follow_up_items",
        "follow_up_events",
        "routine_templates",
        "routine_template_weekdays",
        "routine_occurrences",
        "routine_template_events",
        "routine_occurrence_events",
    )
    definitions = {
        table: database.execute(
            "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = ?",
            (table,),
        ).fetchone()[0]
        for table in tracking_tables
    }

    assert all("ON DELETE CASCADE" not in sql.upper() for sql in definitions.values())
    assert all(
        row[6] == "NO ACTION"
        for table in tracking_tables
        for row in database.execute(f"PRAGMA foreign_key_list({table})")
    )


def test_v3_declares_required_tracking_indexes_and_composite_foreign_key(
    database: sqlite3.Connection,
) -> None:
    index_names = {
        row[0]
        for row in database.execute(
            "SELECT name FROM sqlite_master WHERE type = 'index'"
        )
    }
    follow_up_foreign_keys = list(
        database.execute("PRAGMA foreign_key_list(follow_up_items)")
    )
    composite_rows = [
        row
        for row in follow_up_foreign_keys
        if row[2] == "field_observations"
    ]

    assert {
        "ux_field_observations_id_project",
        "ix_follow_up_status_attention",
        "ix_follow_up_project_status",
        "ix_follow_up_observation",
        "ix_routine_template_status_project",
        "ix_routine_occurrence_status_attention",
        "ix_routine_occurrence_template_date",
    } <= index_names
    assert {(row[3], row[4]) for row in composite_rows} == {
        ("observation_id", "id"),
        ("project_id", "project_id"),
    }
    assert len({row[0] for row in composite_rows}) == 1
