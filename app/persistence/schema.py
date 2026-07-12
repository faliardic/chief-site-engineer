"""Immutable SQLite schema migrations."""

from dataclasses import dataclass


SCHEMA_VERSION = 1


@dataclass(frozen=True)
class Migration:
    """One ordered, atomic database schema change."""

    version: int
    statements: tuple[str, ...]


SCHEMA_MIGRATIONS: tuple[Migration, ...] = (
    Migration(
        version=1,
        statements=(
            """
            CREATE TABLE projects (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                created_at TEXT NOT NULL
            )
            """,
            """
            CREATE TABLE field_observations (
                id TEXT PRIMARY KEY,
                project_id TEXT NOT NULL REFERENCES projects(id),
                observed_at TEXT NOT NULL,
                location TEXT NOT NULL,
                category TEXT NOT NULL,
                description TEXT NOT NULL,
                status TEXT NOT NULL
                    CHECK(status IN ('open', 'tracking', 'closed')),
                reported_to TEXT,
                reported_at TEXT,
                created_by TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                closed_at TEXT,
                archived_at TEXT,
                revision INTEGER NOT NULL DEFAULT 1 CHECK(revision >= 1),
                CHECK(
                    (status = 'closed' AND closed_at IS NOT NULL)
                    OR
                    (status <> 'closed' AND closed_at IS NULL)
                )
            )
            """,
            """
            CREATE TABLE attachments (
                id TEXT PRIMARY KEY,
                observation_id TEXT NOT NULL REFERENCES field_observations(id),
                original_name TEXT NOT NULL,
                stored_relative_path TEXT NOT NULL UNIQUE,
                sha256 TEXT NOT NULL,
                size_bytes INTEGER NOT NULL CHECK(size_bytes >= 0),
                mime_type TEXT,
                status TEXT NOT NULL
                    CHECK(status IN ('active', 'archived', 'superseded', 'missing')),
                created_at TEXT NOT NULL,
                created_by TEXT
            )
            """,
            """
            CREATE TABLE observation_events (
                id TEXT PRIMARY KEY,
                observation_id TEXT NOT NULL REFERENCES field_observations(id),
                event_type TEXT NOT NULL,
                actor TEXT,
                occurred_at TEXT NOT NULL,
                payload_json TEXT NOT NULL
            )
            """,
        ),
    ),
)
