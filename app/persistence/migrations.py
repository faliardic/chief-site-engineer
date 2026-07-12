"""Small dependency-free SQLite migration runner."""

import sqlite3
from collections.abc import Sequence
from datetime import datetime, timezone
from pathlib import Path

from .contracts import serialize_utc_timestamp
from .schema import SCHEMA_MIGRATIONS, Migration


CREATE_MIGRATION_TABLE_SQL = """
CREATE TABLE IF NOT EXISTS schema_migrations (
    version INTEGER PRIMARY KEY,
    applied_at TEXT NOT NULL
)
"""


def connect_database(database_path: str | Path) -> sqlite3.Connection:
    """Open a SQLite connection with foreign key enforcement enabled."""

    connection = sqlite3.connect(database_path, isolation_level=None)
    try:
        _enable_foreign_keys(connection)
    except Exception:
        connection.close()
        raise
    return connection


def migrate_database(
    connection: sqlite3.Connection,
    *,
    migrations: Sequence[Migration] = SCHEMA_MIGRATIONS,
) -> int:
    """Apply every pending migration in one transaction and return its version."""

    _validate_migrations(migrations)
    if connection.in_transaction:
        raise RuntimeError("migration requires a connection without an active transaction")
    _enable_foreign_keys(connection)

    try:
        connection.execute("BEGIN IMMEDIATE")
        connection.execute(CREATE_MIGRATION_TABLE_SQL)
        applied_versions = {
            row[0]
            for row in connection.execute(
                "SELECT version FROM schema_migrations ORDER BY version"
            )
        }

        known_versions = {migration.version for migration in migrations}
        unknown_versions = applied_versions - known_versions
        if unknown_versions:
            versions = ", ".join(str(version) for version in sorted(unknown_versions))
            raise RuntimeError(f"database contains unknown migration versions: {versions}")

        for migration in migrations:
            if migration.version in applied_versions:
                continue
            for statement in migration.statements:
                connection.execute(statement)
            connection.execute(
                "INSERT INTO schema_migrations (version, applied_at) VALUES (?, ?)",
                (
                    migration.version,
                    serialize_utc_timestamp(datetime.now(timezone.utc)),
                ),
            )
            applied_versions.add(migration.version)
    except Exception:
        if connection.in_transaction:
            connection.rollback()
        raise
    else:
        connection.commit()

    return max(applied_versions, default=0)


def _enable_foreign_keys(connection: sqlite3.Connection) -> None:
    connection.execute("PRAGMA foreign_keys = ON")
    enabled = connection.execute("PRAGMA foreign_keys").fetchone()[0]
    if enabled != 1:
        raise RuntimeError("SQLite foreign key enforcement could not be enabled")


def _validate_migrations(migrations: Sequence[Migration]) -> None:
    versions = [migration.version for migration in migrations]
    if versions != sorted(versions) or len(versions) != len(set(versions)):
        raise ValueError("migration versions must be unique and ordered")
    if any(version < 1 for version in versions):
        raise ValueError("migration versions must be positive integers")
