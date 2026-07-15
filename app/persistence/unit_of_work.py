"""Transaction boundary for SQLite repositories."""

import sqlite3
from pathlib import Path
from types import TracebackType

from .errors import UnitOfWorkStateError
from .field_tracking_repositories import (
    SQLiteFollowUpEventRepository,
    SQLiteFollowUpRepository,
    SQLiteRoutineOccurrenceEventRepository,
    SQLiteRoutineOccurrenceRepository,
    SQLiteRoutineTemplateEventRepository,
    SQLiteRoutineTemplateRepository,
)
from .migrations import connect_database, migrate_database
from .repositories import (
    SQLiteAttachmentMetadataRepository,
    SQLiteFieldObservationRepository,
    SQLiteObservationEventRepository,
    SQLiteProjectRepository,
)


class SQLiteUnitOfWork:
    """Own one connection and one explicit transaction for repository work."""

    def __init__(self, database_path: str | Path) -> None:
        self._database_path = database_path
        self._connection: sqlite3.Connection | None = None
        self._projects: SQLiteProjectRepository | None = None
        self._observations: SQLiteFieldObservationRepository | None = None
        self._events: SQLiteObservationEventRepository | None = None
        self._attachments: SQLiteAttachmentMetadataRepository | None = None
        self._follow_ups: SQLiteFollowUpRepository | None = None
        self._follow_up_events: SQLiteFollowUpEventRepository | None = None
        self._routine_templates: SQLiteRoutineTemplateRepository | None = None
        self._routine_template_events: SQLiteRoutineTemplateEventRepository | None = None
        self._routine_occurrences: SQLiteRoutineOccurrenceRepository | None = None
        self._routine_occurrence_events: (
            SQLiteRoutineOccurrenceEventRepository | None
        ) = None
        self._used = False
        self._completed = False

    @property
    def projects(self) -> SQLiteProjectRepository:
        if self._projects is None:
            raise UnitOfWorkStateError("Unit of Work is not active")
        return self._projects

    @property
    def observations(self) -> SQLiteFieldObservationRepository:
        if self._observations is None:
            raise UnitOfWorkStateError("Unit of Work is not active")
        return self._observations

    @property
    def events(self) -> SQLiteObservationEventRepository:
        if self._events is None:
            raise UnitOfWorkStateError("Unit of Work is not active")
        return self._events

    @property
    def attachments(self) -> SQLiteAttachmentMetadataRepository:
        if self._attachments is None:
            raise UnitOfWorkStateError("Unit of Work is not active")
        return self._attachments

    @property
    def follow_ups(self) -> SQLiteFollowUpRepository:
        if self._follow_ups is None:
            raise UnitOfWorkStateError("Unit of Work is not active")
        return self._follow_ups

    @property
    def follow_up_events(self) -> SQLiteFollowUpEventRepository:
        if self._follow_up_events is None:
            raise UnitOfWorkStateError("Unit of Work is not active")
        return self._follow_up_events

    @property
    def routine_templates(self) -> SQLiteRoutineTemplateRepository:
        if self._routine_templates is None:
            raise UnitOfWorkStateError("Unit of Work is not active")
        return self._routine_templates

    @property
    def routine_template_events(self) -> SQLiteRoutineTemplateEventRepository:
        if self._routine_template_events is None:
            raise UnitOfWorkStateError("Unit of Work is not active")
        return self._routine_template_events

    @property
    def routine_occurrences(self) -> SQLiteRoutineOccurrenceRepository:
        if self._routine_occurrences is None:
            raise UnitOfWorkStateError("Unit of Work is not active")
        return self._routine_occurrences

    @property
    def routine_occurrence_events(self) -> SQLiteRoutineOccurrenceEventRepository:
        if self._routine_occurrence_events is None:
            raise UnitOfWorkStateError("Unit of Work is not active")
        return self._routine_occurrence_events

    def __enter__(self) -> "SQLiteUnitOfWork":
        if self._used:
            raise UnitOfWorkStateError("Unit of Work instance has already been used")
        self._used = True

        connection: sqlite3.Connection | None = None
        try:
            connection = connect_database(self._database_path)
            migrate_database(connection)
            connection.execute("BEGIN IMMEDIATE")
            self._connection = connection

            def is_active() -> bool:
                return self._connection is connection

            self._projects = SQLiteProjectRepository(
                connection,
                is_active=is_active,
            )
            self._observations = SQLiteFieldObservationRepository(
                connection,
                is_active=is_active,
            )
            self._events = SQLiteObservationEventRepository(
                connection,
                is_active=is_active,
            )
            self._attachments = SQLiteAttachmentMetadataRepository(
                connection,
                is_active=is_active,
            )
            self._follow_ups = SQLiteFollowUpRepository(
                connection,
                is_active=is_active,
            )
            self._follow_up_events = SQLiteFollowUpEventRepository(
                connection,
                is_active=is_active,
            )
            self._routine_templates = SQLiteRoutineTemplateRepository(
                connection,
                is_active=is_active,
            )
            self._routine_template_events = SQLiteRoutineTemplateEventRepository(
                connection,
                is_active=is_active,
            )
            self._routine_occurrences = SQLiteRoutineOccurrenceRepository(
                connection,
                is_active=is_active,
            )
            self._routine_occurrence_events = SQLiteRoutineOccurrenceEventRepository(
                connection,
                is_active=is_active,
            )
        except Exception:
            if connection is not None:
                if connection.in_transaction:
                    connection.rollback()
                connection.close()
            self._connection = None
            raise
        return self

    def commit(self) -> None:
        connection = self._require_active_connection()
        if self._completed or not connection.in_transaction:
            raise UnitOfWorkStateError("Unit of Work transaction is already completed")
        connection.commit()
        self._completed = True

    def rollback(self) -> None:
        connection = self._require_active_connection()
        if self._completed or not connection.in_transaction:
            raise UnitOfWorkStateError("Unit of Work transaction is already completed")
        connection.rollback()
        self._completed = True

    def __exit__(
        self,
        exc_type: type[BaseException] | None,
        exc: BaseException | None,
        traceback: TracebackType | None,
    ) -> bool:
        connection = self._connection
        if connection is not None:
            try:
                if connection.in_transaction:
                    connection.rollback()
            finally:
                connection.close()
                self._connection = None
                self._projects = None
                self._observations = None
                self._events = None
                self._attachments = None
                self._follow_ups = None
                self._follow_up_events = None
                self._routine_templates = None
                self._routine_template_events = None
                self._routine_occurrences = None
                self._routine_occurrence_events = None
        return False

    def _require_active_connection(self) -> sqlite3.Connection:
        if self._connection is None:
            raise UnitOfWorkStateError("Unit of Work is not active")
        return self._connection
