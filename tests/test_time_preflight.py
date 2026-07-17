import json
from pathlib import Path
import sqlite3
from uuid import uuid4

import pytest

from app.persistence import SCHEMA_MIGRATIONS, connect_database, migrate_database
from app.persistence.time_preflight import run_time_migration_preflight


AS_OF = "2026-07-17T20:00:00Z"


def create_database(path: Path, schema_version: int) -> None:
    connection = connect_database(path)
    try:
        migrate_database(
            connection, migrations=SCHEMA_MIGRATIONS[:schema_version]
        )
        connection.execute(
            "UPDATE schema_migrations SET applied_at = ?",
            ("2026-07-17T17:00:00Z",),
        )
    finally:
        connection.close()


@pytest.mark.parametrize(
    ("schema_version", "timestamp_column_count"),
    ((2, 10), (3, 26), (4, 26)),
)
def test_restore_compatible_schema_preflight_is_json_ready_and_read_only(
    tmp_path: Path, schema_version: int, timestamp_column_count: int
) -> None:
    database = tmp_path / f"schema-{schema_version}.sqlite3"
    create_database(database, schema_version)
    before_bytes = database.read_bytes()
    before_names = sorted(path.name for path in tmp_path.iterdir())

    report = run_time_migration_preflight(
        database, as_of_utc=AS_OF, database_kind="test"
    )

    assert report["schema_version"] == schema_version
    assert report["read_only"] is True
    assert report["status"] == "ready"
    assert report["summary"]["timestamp_column_count"] == timestamp_column_count
    assert len(report["timestamp_columns"]) == timestamp_column_count
    assert json.loads(json.dumps(report, ensure_ascii=False)) == report
    assert database.read_bytes() == before_bytes
    assert sorted(path.name for path in tmp_path.iterdir()) == before_names


def test_preflight_counts_risks_without_leaking_values_or_mutating_database(
    tmp_path: Path,
) -> None:
    database = tmp_path / "risk-review.sqlite3"
    create_database(database, 4)
    project_id = str(uuid4())
    observation_id = str(uuid4())
    event_id = str(uuid4())
    attachment_id = str(uuid4())
    secret = "very-sensitive-owner-content@example.invalid"
    connection = sqlite3.connect(database)
    try:
        connection.execute(
            "INSERT INTO projects (id, name, created_at) VALUES (?, ?, ?)",
            (project_id, secret, "2026-07-17T18:00:00+00:00"),
        )
        connection.execute(
            """
            INSERT INTO field_observations (
                id, project_id, observed_at, location, category, description,
                status, reported_to, reported_at, created_by, created_at,
                updated_at, revision, notes
            ) VALUES (?, ?, ?, ?, ?, ?, 'open', ?, ?, ?, ?, ?, 1, ?)
            """,
            (
                observation_id,
                project_id,
                "2026-07-17T18:30:00",
                secret,
                secret,
                secret,
                secret,
                "2026-07-17T22:00:00+03:00",
                secret,
                "2026-07-17T18:31:00Z",
                "2026-07-17T20:00:01Z",
                secret,
            ),
        )
        connection.execute(
            """
            INSERT INTO attachments (
                id, observation_id, original_name, stored_relative_path,
                sha256, size_bytes, status, created_at
            ) VALUES (?, ?, ?, ?, ?, 1, 'active', ?)
            """,
            (
                attachment_id,
                observation_id,
                secret,
                f"{observation_id}/{secret}",
                "0" * 64,
                "2026-07-17T18:32:00.000001Z",
            ),
        )
        connection.execute(
            """
            INSERT INTO observation_events (
                id, observation_id, event_type, occurred_at, payload_json
            ) VALUES (?, ?, 'observation_created', ?, ?)
            """,
            (event_id, observation_id, secret, json.dumps({"secret": secret})),
        )
        connection.commit()
    finally:
        connection.close()
    before = database.read_bytes()

    report = run_time_migration_preflight(
        database, as_of_utc=AS_OF, database_kind="temporary"
    )
    serialized = json.dumps(report, ensure_ascii=False)

    assert report["status"] == "blocked"
    assert report["summary"]["invalid_count"] == 1
    assert report["summary"]["naive_count"] == 1
    assert report["summary"]["non_utc_count"] == 1
    assert report["summary"]["noncanonical_utc_count"] == 1
    assert report["summary"]["microsecond_count"] == 1
    assert report["summary"]["future_count"] == 1
    assert secret not in serialized
    assert str(database) not in serialized
    assert database.read_bytes() == before

    observed = _column(report, "field_observations", "observed_at")
    assert observed["proposed_mapping"] == "event_time"
    assert observed["naive_count"] == 1
    assert observed["min_utc"] is None
    updated = _column(report, "field_observations", "updated_at")
    assert updated["future_allowed"] is False
    assert updated["future_count"] == 1
    attachment = _column(report, "attachments", "created_at")
    assert attachment["microsecond_count"] == 1
    assert attachment["min_utc"] == "2026-07-17T18:32:00.000001Z"


def test_preflight_requires_an_explicit_disposable_database_kind(
    tmp_path: Path,
) -> None:
    database = tmp_path / "explicit.sqlite3"
    create_database(database, 4)

    with pytest.raises(ValueError, match="temporary or test"):
        run_time_migration_preflight(
            database,
            as_of_utc=AS_OF,
            database_kind="production",  # type: ignore[arg-type]
        )


def _column(
    report: dict[str, object], table: str, column: str
) -> dict[str, object]:
    return next(
        item
        for item in report["timestamp_columns"]
        if item["table"] == table and item["column"] == column
    )
