"""Repository ports and SQLite adapters for the first persistent Field MVP."""

import sqlite3
import re
from collections.abc import Callable
from typing import NoReturn, Protocol

from app.models import FieldObservationRecord
from app.storage.paths import validate_attachment_relative_path

from .contracts import (
    INITIAL_REVISION,
    OBSERVATION_STATUSES,
    validate_observation_state,
    validate_record_id,
    validate_utc_timestamp,
)
from .errors import (
    ArchivedRecordError,
    ConstraintViolation,
    DuplicateRecordError,
    ForeignKeyViolation,
    InvalidRecordError,
    InvalidTransition,
    RecordNotFound,
    RevisionConflict,
    UnitOfWorkStateError,
)
from .records import (
    OBSERVATION_EVENT_TYPES,
    AttachmentMetadataRecord,
    ObservationEventRecord,
    ProjectRecord,
    canonicalize_event_payload_json,
)


class ProjectRepositoryPort(Protocol):
    """Persistence-neutral project repository contract."""

    def add(self, record: ProjectRecord) -> None: ...

    def get(self, project_id: str) -> ProjectRecord: ...

    def list_all(self) -> list[ProjectRecord]: ...


class FieldObservationRepositoryPort(Protocol):
    """Persistence-neutral field observation repository contract."""

    def add(self, record: FieldObservationRecord) -> None: ...

    def get(self, observation_id: str) -> FieldObservationRecord: ...

    def list_all(self) -> list[FieldObservationRecord]: ...

    def list_by_project_id(
        self,
        project_id: str,
    ) -> list[FieldObservationRecord]: ...

    def list_by_status(self, status: str) -> list[FieldObservationRecord]: ...

    def update_details(
        self,
        observation_id: str,
        expected_revision: int,
        location: str,
        category: str,
        description: str,
        notes: str | None,
        occurred_at: str,
    ) -> FieldObservationRecord: ...

    def update_status(
        self,
        observation_id: str,
        expected_revision: int,
        new_status: str,
        occurred_at: str,
    ) -> FieldObservationRecord: ...

    def update_reporting(
        self,
        observation_id: str,
        expected_revision: int,
        reported_to: str,
        reported_at: str,
        occurred_at: str,
    ) -> FieldObservationRecord: ...

    def archive(
        self,
        observation_id: str,
        expected_revision: int,
        occurred_at: str,
    ) -> FieldObservationRecord: ...


class ObservationEventRepositoryPort(Protocol):
    """Persistence-neutral append-only observation event contract."""

    def add(self, record: ObservationEventRecord) -> None: ...

    def list_for_observation(
        self,
        observation_id: str,
    ) -> list[ObservationEventRecord]: ...


class AttachmentMetadataRepositoryPort(Protocol):
    """Persistence-neutral managed attachment metadata contract."""

    def add(self, record: AttachmentMetadataRecord) -> None: ...

    def get(self, attachment_id: str) -> AttachmentMetadataRecord: ...

    def list_for_observation(
        self,
        observation_id: str,
    ) -> list[AttachmentMetadataRecord]: ...

    def list_all(self) -> list[AttachmentMetadataRecord]: ...


class _SQLiteRepository:
    def __init__(
        self,
        connection: sqlite3.Connection,
        *,
        is_active: Callable[[], bool] | None = None,
    ) -> None:
        self._connection = connection
        self._is_active = is_active or (lambda: True)
        self._connection.row_factory = sqlite3.Row

    def _ensure_active(self) -> None:
        if not self._is_active():
            raise UnitOfWorkStateError("repository Unit of Work is no longer active")

    def _require_transaction(self) -> None:
        self._ensure_active()
        if not self._connection.in_transaction:
            raise UnitOfWorkStateError(
                "repository writes require an active Unit of Work transaction"
            )


class SQLiteProjectRepository(_SQLiteRepository):
    """SQLite adapter for projects."""

    def add(self, record: ProjectRecord) -> None:
        self._require_transaction()
        _validate_id(record.project_id, "project_id")
        _validate_required_text(record.name, "project name")
        _validate_timestamp(record.created_at, "project created_at")
        try:
            self._connection.execute(
                "INSERT INTO projects (id, name, created_at) VALUES (?, ?, ?)",
                (record.project_id, record.name, record.created_at),
            )
        except sqlite3.IntegrityError as exc:
            _raise_integrity_error(exc, "project")

    def get(self, project_id: str) -> ProjectRecord:
        self._ensure_active()
        _validate_id(project_id, "project_id")
        row = self._connection.execute(
            "SELECT id, name, created_at FROM projects WHERE id = ?",
            (project_id,),
        ).fetchone()
        if row is None:
            raise RecordNotFound("project", project_id)
        return _row_to_project(row)

    def list_all(self) -> list[ProjectRecord]:
        self._ensure_active()
        rows = self._connection.execute(
            "SELECT id, name, created_at FROM projects ORDER BY created_at, id"
        )
        return [_row_to_project(row) for row in rows]


OBSERVATION_COLUMNS = """
id,
project_id,
observed_at,
location,
category,
description,
status,
reported_to,
reported_at,
created_by,
created_at,
updated_at,
closed_at,
archived_at,
revision,
notes
"""

ALLOWED_STATUS_TRANSITIONS: frozenset[tuple[str, str]] = frozenset(
    {
        ("open", "tracking"),
        ("open", "closed"),
        ("tracking", "closed"),
    }
)


class SQLiteFieldObservationRepository(_SQLiteRepository):
    """SQLite adapter for field observations with optimistic revision checks."""

    def add(self, record: FieldObservationRecord) -> None:
        self._require_transaction()
        _validate_observation_for_add(record)
        try:
            self._connection.execute(
                """
                INSERT INTO field_observations (
                    id,
                    project_id,
                    observed_at,
                    location,
                    category,
                    description,
                    status,
                    reported_to,
                    reported_at,
                    created_by,
                    created_at,
                    updated_at,
                    closed_at,
                    archived_at,
                    revision,
                    notes
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    record.observation_id,
                    record.project_id,
                    record.observed_at,
                    record.location,
                    record.category,
                    record.description,
                    record.status,
                    record.reported_to,
                    record.reported_at,
                    record.created_by,
                    record.created_at,
                    record.updated_at,
                    record.closed_at,
                    record.archived_at,
                    record.revision,
                    record.notes,
                ),
            )
        except sqlite3.IntegrityError as exc:
            _raise_integrity_error(exc, "field observation")

    def get(self, observation_id: str) -> FieldObservationRecord:
        self._ensure_active()
        _validate_id(observation_id, "observation_id")
        row = self._connection.execute(
            f"SELECT {OBSERVATION_COLUMNS} FROM field_observations WHERE id = ?",
            (observation_id,),
        ).fetchone()
        if row is None:
            raise RecordNotFound("field observation", observation_id)
        return _row_to_observation(row)

    def list_all(self) -> list[FieldObservationRecord]:
        self._ensure_active()
        return self._list(
            f"SELECT {OBSERVATION_COLUMNS} FROM field_observations "
            "ORDER BY observed_at, id"
        )

    def list_by_project_id(
        self,
        project_id: str,
    ) -> list[FieldObservationRecord]:
        self._ensure_active()
        _validate_id(project_id, "project_id")
        return self._list(
            f"SELECT {OBSERVATION_COLUMNS} FROM field_observations "
            "WHERE project_id = ? ORDER BY observed_at, id",
            (project_id,),
        )

    def list_by_status(self, status: str) -> list[FieldObservationRecord]:
        self._ensure_active()
        if status not in OBSERVATION_STATUSES:
            raise InvalidRecordError(f"status must be one of {OBSERVATION_STATUSES}")
        return self._list(
            f"SELECT {OBSERVATION_COLUMNS} FROM field_observations "
            "WHERE status = ? ORDER BY observed_at, id",
            (status,),
        )

    def update_details(
        self,
        observation_id: str,
        expected_revision: int,
        location: str,
        category: str,
        description: str,
        notes: str | None,
        occurred_at: str,
    ) -> FieldObservationRecord:
        """Update only the editable text fields with optimistic concurrency."""

        self._require_transaction()
        _validate_id(observation_id, "observation_id")
        _validate_revision(expected_revision)
        _validate_required_text(location, "location")
        _validate_required_text(category, "category")
        _validate_required_text(description, "description")
        if notes is not None and not isinstance(notes, str):
            raise InvalidRecordError("notes must be a string or None")
        _validate_timestamp(occurred_at, "occurred_at")

        current = self.get(observation_id)
        self._validate_mutation_target(current, expected_revision)
        editable_before = (
            current.location,
            current.category,
            current.description,
            current.notes,
        )
        editable_after = (location, category, description, notes)
        if editable_before == editable_after:
            return current

        cursor = self._connection.execute(
            """
            UPDATE field_observations
            SET location = ?,
                category = ?,
                description = ?,
                notes = ?,
                updated_at = ?,
                revision = revision + 1
            WHERE id = ? AND revision = ? AND archived_at IS NULL
            """,
            (
                location,
                category,
                description,
                notes,
                occurred_at,
                observation_id,
                expected_revision,
            ),
        )
        if cursor.rowcount != 1:
            self._raise_mutation_failure(observation_id, expected_revision)
        return self.get(observation_id)

    def update_status(
        self,
        observation_id: str,
        expected_revision: int,
        new_status: str,
        occurred_at: str,
    ) -> FieldObservationRecord:
        self._require_transaction()
        _validate_id(observation_id, "observation_id")
        _validate_revision(expected_revision)
        _validate_timestamp(occurred_at, "occurred_at")
        if new_status not in OBSERVATION_STATUSES:
            raise InvalidRecordError(
                f"status must be one of {OBSERVATION_STATUSES}"
            )

        current = self.get(observation_id)
        self._validate_mutation_target(current, expected_revision)
        if current.status == new_status:
            return current
        if (current.status, new_status) not in ALLOWED_STATUS_TRANSITIONS:
            raise InvalidTransition(
                f"status transition {current.status!r} -> {new_status!r} is not allowed"
            )

        closed_at = occurred_at if new_status == "closed" else None
        cursor = self._connection.execute(
            """
            UPDATE field_observations
            SET status = ?,
                closed_at = ?,
                updated_at = ?,
                revision = revision + 1
            WHERE id = ? AND revision = ? AND archived_at IS NULL
            """,
            (
                new_status,
                closed_at,
                occurred_at,
                observation_id,
                expected_revision,
            ),
        )
        if cursor.rowcount != 1:
            self._raise_mutation_failure(observation_id, expected_revision)
        return self.get(observation_id)

    def update_reporting(
        self,
        observation_id: str,
        expected_revision: int,
        reported_to: str,
        reported_at: str,
        occurred_at: str,
    ) -> FieldObservationRecord:
        self._require_transaction()
        _validate_id(observation_id, "observation_id")
        _validate_revision(expected_revision)
        _validate_required_text(reported_to, "reported_to")
        _validate_timestamp(reported_at, "reported_at")
        _validate_timestamp(occurred_at, "occurred_at")

        current = self.get(observation_id)
        self._validate_mutation_target(current, expected_revision)
        cursor = self._connection.execute(
            """
            UPDATE field_observations
            SET reported_to = ?,
                reported_at = ?,
                updated_at = ?,
                revision = revision + 1
            WHERE id = ? AND revision = ? AND archived_at IS NULL
            """,
            (
                reported_to,
                reported_at,
                occurred_at,
                observation_id,
                expected_revision,
            ),
        )
        if cursor.rowcount != 1:
            self._raise_mutation_failure(observation_id, expected_revision)
        return self.get(observation_id)

    def archive(
        self,
        observation_id: str,
        expected_revision: int,
        occurred_at: str,
    ) -> FieldObservationRecord:
        self._require_transaction()
        _validate_id(observation_id, "observation_id")
        _validate_revision(expected_revision)
        _validate_timestamp(occurred_at, "occurred_at")

        current = self.get(observation_id)
        self._validate_mutation_target(current, expected_revision)
        cursor = self._connection.execute(
            """
            UPDATE field_observations
            SET archived_at = ?,
                updated_at = ?,
                revision = revision + 1
            WHERE id = ? AND revision = ? AND archived_at IS NULL
            """,
            (occurred_at, occurred_at, observation_id, expected_revision),
        )
        if cursor.rowcount != 1:
            self._raise_mutation_failure(observation_id, expected_revision)
        return self.get(observation_id)

    def _list(
        self,
        query: str,
        parameters: tuple[object, ...] = (),
    ) -> list[FieldObservationRecord]:
        rows = self._connection.execute(query, parameters)
        return [_row_to_observation(row) for row in rows]

    def _validate_mutation_target(
        self,
        current: FieldObservationRecord,
        expected_revision: int,
    ) -> None:
        if current.is_archived:
            raise ArchivedRecordError(
                f"field observation '{current.observation_id}' is archived"
            )
        if current.revision != expected_revision:
            raise RevisionConflict(
                current.observation_id,
                expected_revision,
                current.revision,
            )

    def _raise_mutation_failure(
        self,
        observation_id: str,
        expected_revision: int,
    ) -> NoReturn:
        current = self.get(observation_id)
        self._validate_mutation_target(current, expected_revision)
        raise ConstraintViolation(
            f"field observation '{observation_id}' could not be updated"
        )


class SQLiteObservationEventRepository(_SQLiteRepository):
    """SQLite append-only adapter for observation events."""

    def add(self, record: ObservationEventRecord) -> None:
        self._require_transaction()
        _validate_id(record.event_id, "event_id")
        _validate_id(record.observation_id, "observation_id")
        if record.event_type not in OBSERVATION_EVENT_TYPES:
            raise InvalidRecordError(
                f"event_type must be one of {OBSERVATION_EVENT_TYPES}"
            )
        if record.actor is not None:
            _validate_required_text(record.actor, "actor")
        _validate_timestamp(record.occurred_at, "occurred_at")
        try:
            payload_json = canonicalize_event_payload_json(record.payload_json)
        except ValueError as exc:
            raise InvalidRecordError(str(exc)) from exc

        try:
            self._connection.execute(
                """
                INSERT INTO observation_events (
                    id,
                    observation_id,
                    event_type,
                    actor,
                    occurred_at,
                    payload_json
                ) VALUES (?, ?, ?, ?, ?, ?)
                """,
                (
                    record.event_id,
                    record.observation_id,
                    record.event_type,
                    record.actor,
                    record.occurred_at,
                    payload_json,
                ),
            )
        except sqlite3.IntegrityError as exc:
            _raise_integrity_error(exc, "observation event")

    def list_for_observation(
        self,
        observation_id: str,
    ) -> list[ObservationEventRecord]:
        self._ensure_active()
        _validate_id(observation_id, "observation_id")
        rows = self._connection.execute(
            """
            SELECT id, observation_id, event_type, actor, occurred_at, payload_json
            FROM observation_events
            WHERE observation_id = ?
            ORDER BY occurred_at, rowid
            """,
            (observation_id,),
        )
        return [_row_to_event(row) for row in rows]


class SQLiteAttachmentMetadataRepository(_SQLiteRepository):
    """SQLite adapter for managed attachment metadata."""

    def add(self, record: AttachmentMetadataRecord) -> None:
        self._require_transaction()
        _validate_attachment_metadata(record)
        try:
            self._connection.execute(
                """
                INSERT INTO attachments (
                    id,
                    observation_id,
                    original_name,
                    stored_relative_path,
                    sha256,
                    size_bytes,
                    mime_type,
                    status,
                    created_at,
                    created_by
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    record.attachment_id,
                    record.observation_id,
                    record.original_name,
                    record.stored_relative_path,
                    record.sha256,
                    record.size_bytes,
                    record.mime_type,
                    record.status,
                    record.created_at,
                    record.created_by,
                ),
            )
        except sqlite3.IntegrityError as exc:
            _raise_integrity_error(exc, "attachment metadata")

    def get(self, attachment_id: str) -> AttachmentMetadataRecord:
        self._ensure_active()
        _validate_id(attachment_id, "attachment_id")
        row = self._connection.execute(
            """
            SELECT id, observation_id, original_name, stored_relative_path,
                   sha256, size_bytes, mime_type, status, created_at, created_by
            FROM attachments
            WHERE id = ?
            """,
            (attachment_id,),
        ).fetchone()
        if row is None:
            raise RecordNotFound("attachment metadata", attachment_id)
        return _row_to_attachment_metadata(row)

    def list_for_observation(
        self,
        observation_id: str,
    ) -> list[AttachmentMetadataRecord]:
        self._ensure_active()
        _validate_id(observation_id, "observation_id")
        rows = self._connection.execute(
            """
            SELECT id, observation_id, original_name, stored_relative_path,
                   sha256, size_bytes, mime_type, status, created_at, created_by
            FROM attachments
            WHERE observation_id = ?
            ORDER BY created_at, id
            """,
            (observation_id,),
        )
        return [_row_to_attachment_metadata(row) for row in rows]

    def list_all(self) -> list[AttachmentMetadataRecord]:
        self._ensure_active()
        rows = self._connection.execute(
            """
            SELECT id, observation_id, original_name, stored_relative_path,
                   sha256, size_bytes, mime_type, status, created_at, created_by
            FROM attachments
            ORDER BY created_at, id
            """
        )
        return [_row_to_attachment_metadata(row) for row in rows]


def _row_to_project(row: sqlite3.Row) -> ProjectRecord:
    return ProjectRecord(
        project_id=row["id"],
        name=row["name"],
        created_at=row["created_at"],
    )


def _row_to_observation(row: sqlite3.Row) -> FieldObservationRecord:
    return FieldObservationRecord(
        observation_id=row["id"],
        project_id=row["project_id"],
        observed_at=row["observed_at"],
        location=row["location"],
        category=row["category"],
        description=row["description"],
        status=row["status"],
        reported_to=row["reported_to"],
        reported_at=row["reported_at"],
        created_by=row["created_by"],
        closed_at=row["closed_at"],
        notes=row["notes"],
        is_archived=row["archived_at"] is not None,
        revision=row["revision"],
        created_at=row["created_at"],
        updated_at=row["updated_at"],
        archived_at=row["archived_at"],
    )


def _row_to_event(row: sqlite3.Row) -> ObservationEventRecord:
    return ObservationEventRecord(
        event_id=row["id"],
        observation_id=row["observation_id"],
        event_type=row["event_type"],
        actor=row["actor"],
        occurred_at=row["occurred_at"],
        payload_json=row["payload_json"],
    )


def _row_to_attachment_metadata(row: sqlite3.Row) -> AttachmentMetadataRecord:
    return AttachmentMetadataRecord(
        attachment_id=row["id"],
        observation_id=row["observation_id"],
        original_name=row["original_name"],
        stored_relative_path=row["stored_relative_path"],
        sha256=row["sha256"],
        size_bytes=row["size_bytes"],
        mime_type=row["mime_type"],
        status=row["status"],
        created_at=row["created_at"],
        created_by=row["created_by"],
    )


def _validate_observation_for_add(record: FieldObservationRecord) -> None:
    _validate_id(record.observation_id, "observation_id")
    _validate_id(record.project_id, "project_id")
    _validate_timestamp(record.observed_at, "observed_at")
    _validate_required_text(record.location, "location")
    _validate_required_text(record.category, "category")
    _validate_required_text(record.description, "description")
    try:
        validate_observation_state(record.status, record.closed_at)
    except ValueError as exc:
        raise InvalidRecordError(str(exc)) from exc

    if record.reported_to is not None:
        _validate_required_text(record.reported_to, "reported_to")
    if record.reported_at is not None:
        _validate_timestamp(record.reported_at, "reported_at")
    if (record.reported_to is None) != (record.reported_at is None):
        raise InvalidRecordError("reported_to and reported_at must be set together")

    if record.created_at is None or record.updated_at is None:
        raise InvalidRecordError("created_at and updated_at are required")
    _validate_timestamp(record.created_at, "created_at")
    _validate_timestamp(record.updated_at, "updated_at")
    if record.archived_at is not None:
        _validate_timestamp(record.archived_at, "archived_at")
    if record.is_archived != (record.archived_at is not None):
        raise InvalidRecordError("is_archived and archived_at must be consistent")
    if record.revision != INITIAL_REVISION:
        raise InvalidRecordError(
            f"new field observation revision must be {INITIAL_REVISION}"
        )
    if record.notes is not None and not isinstance(record.notes, str):
        raise InvalidRecordError("notes must be a string or None")


def _validate_id(value: str, field_name: str) -> None:
    try:
        validate_record_id(value)
    except ValueError as exc:
        raise InvalidRecordError(f"{field_name}: {exc}") from exc


def _validate_timestamp(value: str, field_name: str) -> None:
    try:
        validate_utc_timestamp(value)
    except ValueError as exc:
        raise InvalidRecordError(f"{field_name}: {exc}") from exc


def _validate_required_text(value: str, field_name: str) -> None:
    if not isinstance(value, str) or not value.strip():
        raise InvalidRecordError(f"{field_name} cannot be empty")


def _validate_revision(value: int) -> None:
    if not isinstance(value, int) or isinstance(value, bool) or value < 1:
        raise InvalidRecordError("expected_revision must be an integer >= 1")


def _validate_attachment_metadata(record: AttachmentMetadataRecord) -> None:
    _validate_id(record.attachment_id, "attachment_id")
    _validate_id(record.observation_id, "observation_id")
    _validate_required_text(record.original_name, "original_name")
    try:
        validate_attachment_relative_path(
            record.stored_relative_path,
            record.observation_id,
            record.attachment_id,
        )
    except ValueError as exc:
        raise InvalidRecordError(f"stored_relative_path: {exc}") from exc
    if re.fullmatch(r"[0-9a-f]{64}", record.sha256) is None:
        raise InvalidRecordError("sha256 must be 64 lowercase hexadecimal characters")
    if (
        not isinstance(record.size_bytes, int)
        or isinstance(record.size_bytes, bool)
        or record.size_bytes < 0
    ):
        raise InvalidRecordError("size_bytes must be an integer >= 0")
    if record.mime_type is not None:
        _validate_required_text(record.mime_type, "mime_type")
    if record.status != "active":
        raise InvalidRecordError("new attachment status must be 'active'")
    _validate_timestamp(record.created_at, "created_at")
    if record.created_by is not None:
        _validate_required_text(record.created_by, "created_by")


def _raise_integrity_error(
    error: sqlite3.IntegrityError,
    record_type: str,
) -> NoReturn:
    message = str(error)
    if "FOREIGN KEY constraint failed" in message:
        raise ForeignKeyViolation(
            f"{record_type} references a missing parent record"
        ) from error
    if "UNIQUE constraint failed" in message or "PRIMARY KEY" in message:
        raise DuplicateRecordError(f"duplicate {record_type}") from error
    raise ConstraintViolation(
        f"{record_type} constraint failed: {message}"
    ) from error
