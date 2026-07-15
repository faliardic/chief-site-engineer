"""Immutable SQLite schema migrations."""

from dataclasses import dataclass


SCHEMA_VERSION = 3


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
    Migration(
        version=2,
        statements=(
            "ALTER TABLE field_observations ADD COLUMN notes TEXT",
        ),
    ),
    Migration(
        version=3,
        statements=(
            """
            CREATE UNIQUE INDEX ux_field_observations_id_project
            ON field_observations(id, project_id)
            """,
            """
            CREATE TABLE follow_up_items (
                id TEXT PRIMARY KEY,
                capture_text TEXT NOT NULL CHECK(length(trim(capture_text)) > 0),
                title TEXT NOT NULL CHECK(length(trim(title)) > 0),
                description TEXT,
                item_type TEXT NOT NULL
                    CHECK(item_type IN ('action', 'waiting', 'recheck')),
                status TEXT NOT NULL
                    CHECK(status IN (
                        'inbox', 'active', 'waiting', 'completed', 'cancelled'
                    )),
                project_id TEXT REFERENCES projects(id),
                observation_id TEXT,
                location TEXT,
                related_person TEXT,
                is_important INTEGER NOT NULL DEFAULT 0
                    CHECK(is_important IN (0, 1)),
                next_attention_at TEXT,
                deadline_at TEXT,
                condition_text TEXT,
                outcome_type TEXT
                    CHECK(outcome_type IS NULL OR outcome_type IN (
                        'completed', 'not_required',
                        'converted_to_observation', 'cancelled'
                    )),
                outcome_note TEXT,
                revision INTEGER NOT NULL DEFAULT 1 CHECK(revision >= 1),
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                completed_at TEXT,
                cancelled_at TEXT,
                CHECK(observation_id IS NULL OR project_id IS NOT NULL),
                FOREIGN KEY(observation_id, project_id)
                    REFERENCES field_observations(id, project_id),
                CHECK(
                    status IN ('completed', 'cancelled')
                    OR status = 'inbox'
                    OR next_attention_at IS NOT NULL
                ),
                CHECK(
                    (
                        status = 'completed'
                        AND outcome_type IS NOT NULL
                        AND outcome_type IN (
                            'completed', 'not_required',
                            'converted_to_observation'
                        )
                        AND completed_at IS NOT NULL
                        AND cancelled_at IS NULL
                    )
                    OR
                    (
                        status = 'cancelled'
                        AND outcome_type IS NOT NULL
                        AND outcome_type = 'cancelled'
                        AND cancelled_at IS NOT NULL
                        AND completed_at IS NULL
                    )
                    OR
                    (
                        status IN ('inbox', 'active', 'waiting')
                        AND outcome_type IS NULL
                        AND outcome_note IS NULL
                        AND completed_at IS NULL
                        AND cancelled_at IS NULL
                    )
                )
            )
            """,
            """
            CREATE TABLE follow_up_events (
                id TEXT PRIMARY KEY,
                follow_up_id TEXT NOT NULL REFERENCES follow_up_items(id),
                sequence INTEGER NOT NULL CHECK(sequence >= 1),
                event_type TEXT NOT NULL CHECK(event_type IN (
                    'follow_up.created',
                    'follow_up.scheduled',
                    'follow_up.rescheduled',
                    'follow_up.waiting_started',
                    'follow_up.completed',
                    'follow_up.cancelled',
                    'follow_up.reopened',
                    'follow_up.observation_linked',
                    'follow_up.converted_to_observation'
                )),
                actor TEXT NOT NULL CHECK(length(trim(actor)) > 0),
                occurred_at TEXT NOT NULL,
                payload_json TEXT NOT NULL,
                UNIQUE(follow_up_id, sequence)
            )
            """,
            """
            CREATE TABLE routine_templates (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL CHECK(length(trim(title)) > 0),
                description TEXT,
                project_id TEXT REFERENCES projects(id),
                recurrence_type TEXT NOT NULL
                    CHECK(recurrence_type IN (
                        'daily', 'weekdays', 'weekly', 'monthly'
                    )),
                local_time TEXT NOT NULL,
                timezone TEXT NOT NULL CHECK(timezone = 'Europe/Istanbul'),
                month_day INTEGER CHECK(month_day BETWEEN 1 AND 31),
                start_date TEXT NOT NULL,
                end_date TEXT,
                status TEXT NOT NULL CHECK(status IN ('active', 'inactive')),
                is_important INTEGER NOT NULL DEFAULT 0
                    CHECK(is_important IN (0, 1)),
                revision INTEGER NOT NULL DEFAULT 1 CHECK(revision >= 1),
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                deactivated_at TEXT,
                CHECK(end_date IS NULL OR end_date >= start_date),
                CHECK(
                    (recurrence_type = 'monthly' AND month_day IS NOT NULL)
                    OR
                    (recurrence_type <> 'monthly' AND month_day IS NULL)
                ),
                CHECK(
                    (status = 'inactive' AND deactivated_at IS NOT NULL)
                    OR
                    (status = 'active' AND deactivated_at IS NULL)
                )
            )
            """,
            """
            CREATE TABLE routine_template_weekdays (
                routine_template_id TEXT NOT NULL
                    REFERENCES routine_templates(id),
                iso_weekday INTEGER NOT NULL CHECK(iso_weekday BETWEEN 1 AND 7),
                PRIMARY KEY(routine_template_id, iso_weekday)
            )
            """,
            """
            CREATE TABLE routine_occurrences (
                id TEXT PRIMARY KEY,
                routine_template_id TEXT NOT NULL REFERENCES routine_templates(id),
                occurrence_local_date TEXT NOT NULL,
                scheduled_local_time TEXT NOT NULL,
                scheduled_at_utc TEXT NOT NULL,
                status TEXT NOT NULL CHECK(status IN ('open', 'closed')),
                next_attention_at TEXT NOT NULL,
                outcome_type TEXT CHECK(outcome_type IS NULL OR outcome_type IN (
                    'completed', 'no_work', 'not_required', 'missed'
                )),
                outcome_note TEXT,
                revision INTEGER NOT NULL DEFAULT 1 CHECK(revision >= 1),
                created_at TEXT NOT NULL,
                completed_at TEXT,
                UNIQUE(routine_template_id, occurrence_local_date),
                CHECK(
                    (
                        status = 'open'
                        AND outcome_type IS NULL
                        AND outcome_note IS NULL
                        AND completed_at IS NULL
                    )
                    OR
                    (
                        status = 'closed'
                        AND outcome_type IS NOT NULL
                        AND completed_at IS NOT NULL
                    )
                )
            )
            """,
            """
            CREATE TABLE routine_template_events (
                id TEXT PRIMARY KEY,
                routine_template_id TEXT NOT NULL REFERENCES routine_templates(id),
                sequence INTEGER NOT NULL CHECK(sequence >= 1),
                event_type TEXT NOT NULL CHECK(event_type IN (
                    'routine_template.created',
                    'routine_template.updated',
                    'routine_template.deactivated'
                )),
                actor TEXT NOT NULL CHECK(length(trim(actor)) > 0),
                occurred_at TEXT NOT NULL,
                payload_json TEXT NOT NULL,
                UNIQUE(routine_template_id, sequence)
            )
            """,
            """
            CREATE TABLE routine_occurrence_events (
                id TEXT PRIMARY KEY,
                routine_occurrence_id TEXT NOT NULL
                    REFERENCES routine_occurrences(id),
                sequence INTEGER NOT NULL CHECK(sequence >= 1),
                event_type TEXT NOT NULL CHECK(event_type IN (
                    'routine_occurrence.created',
                    'routine_occurrence.snoozed',
                    'routine_occurrence.completed',
                    'routine_occurrence.no_work',
                    'routine_occurrence.not_required',
                    'routine_occurrence.missed',
                    'routine_occurrence.reopened'
                )),
                actor TEXT NOT NULL CHECK(length(trim(actor)) > 0),
                occurred_at TEXT NOT NULL,
                payload_json TEXT NOT NULL,
                UNIQUE(routine_occurrence_id, sequence)
            )
            """,
            """
            CREATE INDEX ix_follow_up_status_attention
            ON follow_up_items(status, next_attention_at)
            """,
            """
            CREATE INDEX ix_follow_up_project_status
            ON follow_up_items(project_id, status)
            """,
            """
            CREATE INDEX ix_follow_up_observation
            ON follow_up_items(observation_id)
            """,
            """
            CREATE INDEX ix_routine_template_status_project
            ON routine_templates(status, project_id)
            """,
            """
            CREATE INDEX ix_routine_occurrence_status_attention
            ON routine_occurrences(status, next_attention_at)
            """,
            """
            CREATE INDEX ix_routine_occurrence_template_date
            ON routine_occurrences(routine_template_id, occurrence_local_date)
            """,
        ),
    ),
)
