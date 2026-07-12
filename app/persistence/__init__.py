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
from .schema import SCHEMA_VERSION, Migration

__all__ = [
    "ATTACHMENT_STATUSES",
    "INITIAL_REVISION",
    "OBSERVATION_STATUSES",
    "SCHEMA_VERSION",
    "Migration",
    "connect_database",
    "migrate_database",
    "serialize_utc_timestamp",
    "validate_observation_state",
    "validate_record_id",
    "validate_utc_timestamp",
]
