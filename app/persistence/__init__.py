"""SQLite persistence foundation for Chief Site Engineer."""

from .contracts import (
    ATTACHMENT_STATUSES,
    INITIAL_REVISION,
    OBSERVATION_STATUSES,
    serialize_utc_timestamp,
    validate_observation_state,
    validate_record_id,
    validate_utc_timestamp,
)
from .migrations import connect_database, migrate_database
from .errors import (
    ArchivedRecordError,
    ConstraintViolation,
    DuplicateRecordError,
    ForeignKeyViolation,
    InvalidRecordError,
    InvalidTransition,
    PersistenceError,
    RecordNotFound,
    RevisionConflict,
    UnitOfWorkStateError,
)
from .records import (
    OBSERVATION_EVENT_TYPES,
    ObservationEventRecord,
    ProjectRecord,
    serialize_event_payload,
)
from .repositories import (
    FieldObservationRepositoryPort,
    ObservationEventRepositoryPort,
    ProjectRepositoryPort,
    SQLiteFieldObservationRepository,
    SQLiteObservationEventRepository,
    SQLiteProjectRepository,
)
from .schema import SCHEMA_MIGRATIONS, SCHEMA_VERSION, Migration
from .unit_of_work import SQLiteUnitOfWork

__all__ = [
    "ATTACHMENT_STATUSES",
    "ArchivedRecordError",
    "ConstraintViolation",
    "DuplicateRecordError",
    "FieldObservationRepositoryPort",
    "ForeignKeyViolation",
    "INITIAL_REVISION",
    "InvalidRecordError",
    "InvalidTransition",
    "OBSERVATION_EVENT_TYPES",
    "OBSERVATION_STATUSES",
    "ObservationEventRecord",
    "ObservationEventRepositoryPort",
    "PersistenceError",
    "ProjectRecord",
    "ProjectRepositoryPort",
    "RecordNotFound",
    "RevisionConflict",
    "SCHEMA_MIGRATIONS",
    "SCHEMA_VERSION",
    "SQLiteFieldObservationRepository",
    "SQLiteObservationEventRepository",
    "SQLiteProjectRepository",
    "SQLiteUnitOfWork",
    "UnitOfWorkStateError",
    "Migration",
    "connect_database",
    "migrate_database",
    "serialize_utc_timestamp",
    "serialize_event_payload",
    "validate_observation_state",
    "validate_record_id",
    "validate_utc_timestamp",
]
