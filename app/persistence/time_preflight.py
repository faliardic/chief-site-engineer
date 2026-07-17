"""Read-only timestamp inventory for explicit disposable SQLite databases."""

from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
import sqlite3
from typing import Literal

from app.time_contracts import (
    TimestampRole,
    UTC,
    parse_utc_timestamp,
    serialize_utc_timestamp,
)


PREFLIGHT_VERSION = 1
SUPPORTED_SCHEMA_VERSIONS = (2, 3, 4)
DatabaseKind = Literal["temporary", "test"]


@dataclass(frozen=True)
class TimestampColumnSpec:
    minimum_schema: int
    table: str
    column: str
    role: TimestampRole


TIMESTAMP_COLUMNS: tuple[TimestampColumnSpec, ...] = (
    TimestampColumnSpec(
        1, "schema_migrations", "applied_at", TimestampRole.PERSISTENT_ENTRY_TIME
    ),
    TimestampColumnSpec(1, "projects", "created_at", TimestampRole.PERSISTENT_ENTRY_TIME),
    TimestampColumnSpec(1, "field_observations", "observed_at", TimestampRole.EVENT_TIME),
    TimestampColumnSpec(1, "field_observations", "reported_at", TimestampRole.EVENT_TIME),
    TimestampColumnSpec(
        1, "field_observations", "created_at", TimestampRole.PERSISTENT_ENTRY_TIME
    ),
    TimestampColumnSpec(
        1, "field_observations", "updated_at", TimestampRole.LAST_UPDATE_TIME
    ),
    TimestampColumnSpec(
        1, "field_observations", "closed_at", TimestampRole.LIFECYCLE_TIME
    ),
    TimestampColumnSpec(
        1, "field_observations", "archived_at", TimestampRole.LIFECYCLE_TIME
    ),
    TimestampColumnSpec(
        1, "attachments", "created_at", TimestampRole.PERSISTENT_ENTRY_TIME
    ),
    TimestampColumnSpec(1, "observation_events", "occurred_at", TimestampRole.EVENT_TIME),
    TimestampColumnSpec(3, "follow_up_items", "next_attention_at", TimestampRole.SCHEDULED_TIME),
    TimestampColumnSpec(3, "follow_up_items", "deadline_at", TimestampRole.SCHEDULED_TIME),
    TimestampColumnSpec(
        3, "follow_up_items", "created_at", TimestampRole.PERSISTENT_ENTRY_TIME
    ),
    TimestampColumnSpec(
        3, "follow_up_items", "updated_at", TimestampRole.LAST_UPDATE_TIME
    ),
    TimestampColumnSpec(3, "follow_up_items", "completed_at", TimestampRole.LIFECYCLE_TIME),
    TimestampColumnSpec(3, "follow_up_items", "cancelled_at", TimestampRole.LIFECYCLE_TIME),
    TimestampColumnSpec(3, "follow_up_events", "occurred_at", TimestampRole.EVENT_TIME),
    TimestampColumnSpec(
        3, "routine_templates", "created_at", TimestampRole.PERSISTENT_ENTRY_TIME
    ),
    TimestampColumnSpec(
        3, "routine_templates", "updated_at", TimestampRole.LAST_UPDATE_TIME
    ),
    TimestampColumnSpec(
        3, "routine_templates", "deactivated_at", TimestampRole.LIFECYCLE_TIME
    ),
    TimestampColumnSpec(
        3, "routine_occurrences", "scheduled_at_utc", TimestampRole.SCHEDULED_TIME
    ),
    TimestampColumnSpec(
        3, "routine_occurrences", "next_attention_at", TimestampRole.SCHEDULED_TIME
    ),
    TimestampColumnSpec(
        3, "routine_occurrences", "created_at", TimestampRole.PERSISTENT_ENTRY_TIME
    ),
    TimestampColumnSpec(
        3, "routine_occurrences", "completed_at", TimestampRole.LIFECYCLE_TIME
    ),
    TimestampColumnSpec(
        3, "routine_template_events", "occurred_at", TimestampRole.EVENT_TIME
    ),
    TimestampColumnSpec(
        3, "routine_occurrence_events", "occurred_at", TimestampRole.EVENT_TIME
    ),
)


def run_time_migration_preflight(
    database_path: str | Path,
    *,
    as_of_utc: str,
    database_kind: DatabaseKind,
) -> dict[str, object]:
    """Inspect an explicit temp/test database without migrating or mutating it."""

    if database_kind not in ("temporary", "test"):
        raise ValueError("database_kind must be temporary or test")
    as_of = parse_utc_timestamp(as_of_utc)
    path = Path(database_path).resolve(strict=True)
    if not path.is_file():
        raise ValueError("database_path must identify an existing SQLite file")

    uri = f"{path.as_uri()}?mode=ro"
    connection = sqlite3.connect(uri, uri=True)
    connection.row_factory = sqlite3.Row
    try:
        connection.execute("PRAGMA query_only = ON")
        schema_version = _read_schema_version(connection)
        findings: list[dict[str, object]] = []
        columns: list[dict[str, object]] = []

        if schema_version not in SUPPORTED_SCHEMA_VERSIONS:
            findings.append(
                {
                    "level": "blocker",
                    "code": "unsupported_schema_version",
                    "schema_version": schema_version,
                }
            )
        else:
            for spec in TIMESTAMP_COLUMNS:
                if spec.minimum_schema <= schema_version:
                    report = _inspect_column(connection, spec, as_of)
                    columns.append(report)
                    findings.extend(_column_findings(report, spec))
    finally:
        connection.close()

    summary = _summarize(columns)
    levels = {finding["level"] for finding in findings}
    status = (
        "blocked"
        if "blocker" in levels
        else "review_required"
        if "warning" in levels
        else "ready"
    )
    return {
        "preflight_version": PREFLIGHT_VERSION,
        "database_kind": database_kind,
        "read_only": True,
        "schema_version": schema_version,
        "supported_schema_versions": list(SUPPORTED_SCHEMA_VERSIONS),
        "as_of_utc": as_of_utc,
        "status": status,
        "summary": summary,
        "timestamp_columns": columns,
        "findings": findings,
    }


def _read_schema_version(connection: sqlite3.Connection) -> int | None:
    row = connection.execute(
        "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
        ("schema_migrations",),
    ).fetchone()
    if row is None:
        return None
    version_row = connection.execute(
        "SELECT MAX(version) AS version FROM schema_migrations"
    ).fetchone()
    value = version_row["version"]
    return value if isinstance(value, int) else None


def _inspect_column(
    connection: sqlite3.Connection,
    spec: TimestampColumnSpec,
    as_of: datetime,
) -> dict[str, object]:
    table_info = connection.execute(
        f"PRAGMA table_info({_quote_identifier(spec.table)})"
    ).fetchall()
    metadata = next((row for row in table_info if row["name"] == spec.column), None)
    if metadata is None:
        return {
            "table": spec.table,
            "column": spec.column,
            "proposed_mapping": spec.role.value,
            "future_allowed": spec.role.allows_future,
            "present": False,
            "nullable": None,
            **_empty_counts(),
            "min_utc": None,
            "max_utc": None,
        }

    values = connection.execute(
        f"SELECT {_quote_identifier(spec.column)} AS value "
        f"FROM {_quote_identifier(spec.table)}"
    )
    counts = _empty_counts()
    aware_instants: list[datetime] = []
    for row in values:
        counts["row_count"] += 1
        value = row["value"]
        if value is None:
            counts["null_count"] += 1
            continue
        parsed, classification = _classify_timestamp(value)
        if parsed is None:
            counts[classification] += 1
            continue
        counts["parseable_count"] += 1
        if classification == "naive_count":
            counts["naive_count"] += 1
            if _has_fraction(value):
                counts["microsecond_count"] += 1
            continue

        aware_instants.append(parsed.astimezone(UTC))
        if parsed.utcoffset() != UTC.utcoffset(None):
            counts["non_utc_count"] += 1
        if _has_fraction(value):
            counts["microsecond_count"] += 1
        try:
            parse_utc_timestamp(value)
        except (TypeError, ValueError):
            if parsed.utcoffset() == UTC.utcoffset(None):
                counts["noncanonical_utc_count"] += 1
        else:
            counts["canonical_utc_count"] += 1
        if parsed.astimezone(UTC) > as_of:
            counts["future_count"] += 1

    return {
        "table": spec.table,
        "column": spec.column,
        "proposed_mapping": spec.role.value,
        "future_allowed": spec.role.allows_future,
        "present": True,
        "nullable": not bool(metadata["notnull"]),
        **counts,
        "min_utc": _serialize_boundary(min(aware_instants)) if aware_instants else None,
        "max_utc": _serialize_boundary(max(aware_instants)) if aware_instants else None,
    }


def _classify_timestamp(value: object) -> tuple[datetime | None, str]:
    if not isinstance(value, str) or value != value.strip() or len(value) < 19:
        return None, "invalid_count"
    candidate = f"{value[:-1]}+00:00" if value.endswith("Z") else value
    try:
        parsed = datetime.fromisoformat(candidate)
    except ValueError:
        return None, "invalid_count"
    if parsed.tzinfo is None or parsed.utcoffset() is None:
        return parsed, "naive_count"
    return parsed, "aware"


def _has_fraction(value: object) -> bool:
    return isinstance(value, str) and len(value) > 19 and value[19] == "."


def _empty_counts() -> dict[str, int]:
    return {
        "row_count": 0,
        "null_count": 0,
        "parseable_count": 0,
        "canonical_utc_count": 0,
        "noncanonical_utc_count": 0,
        "invalid_count": 0,
        "naive_count": 0,
        "non_utc_count": 0,
        "microsecond_count": 0,
        "future_count": 0,
    }


def _column_findings(
    report: dict[str, object], spec: TimestampColumnSpec
) -> list[dict[str, object]]:
    common = {"table": spec.table, "column": spec.column}
    if not report["present"]:
        return [{"level": "blocker", "code": "missing_timestamp_column", **common}]

    findings: list[dict[str, object]] = []
    for count_name, level, code in (
        ("invalid_count", "blocker", "unparseable_timestamp"),
        ("naive_count", "blocker", "naive_timestamp"),
        ("non_utc_count", "warning", "non_utc_offset"),
        (
            "noncanonical_utc_count",
            "warning",
            "noncanonical_utc_representation",
        ),
        ("microsecond_count", "warning", "legacy_microsecond_precision"),
    ):
        count = report[count_name]
        if count:
            findings.append({"level": level, "code": code, "count": count, **common})
    future_count = report["future_count"]
    if future_count and not spec.role.allows_future:
        findings.append(
            {
                "level": "blocker",
                "code": "future_historical_timestamp",
                "count": future_count,
                **common,
            }
        )
    return findings


def _summarize(columns: list[dict[str, object]]) -> dict[str, int]:
    count_names = tuple(_empty_counts())
    return {
        "timestamp_column_count": len(columns),
        **{
            name: sum(int(column[name]) for column in columns)
            for name in count_names
        },
    }


def _serialize_boundary(value: datetime) -> str:
    precision = "microseconds" if value.microsecond else "seconds"
    return serialize_utc_timestamp(value, precision=precision)


def _quote_identifier(value: str) -> str:
    return f'"{value.replace(chr(34), chr(34) * 2)}"'


__all__ = [
    "PREFLIGHT_VERSION",
    "SUPPORTED_SCHEMA_VERSIONS",
    "TIMESTAMP_COLUMNS",
    "run_time_migration_preflight",
]
