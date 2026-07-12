"""Explicit exception contract for SQLite persistence adapters."""


class PersistenceError(Exception):
    """Base class for persistence-facing errors."""


class InvalidRecordError(PersistenceError):
    """A record violates a domain or storage input contract."""


class DuplicateRecordError(PersistenceError):
    """A primary key or unique value already exists."""


class ForeignKeyViolation(PersistenceError):
    """A referenced parent record does not exist."""


class ConstraintViolation(PersistenceError):
    """A database constraint rejected a write."""


class RecordNotFound(PersistenceError):
    """The requested record does not exist."""

    def __init__(self, record_type: str, record_id: str) -> None:
        self.record_type = record_type
        self.record_id = record_id
        super().__init__(f"{record_type} '{record_id}' was not found")


class RevisionConflict(PersistenceError):
    """The caller's expected revision is stale."""

    def __init__(
        self,
        record_id: str,
        expected_revision: int,
        actual_revision: int,
    ) -> None:
        self.record_id = record_id
        self.expected_revision = expected_revision
        self.actual_revision = actual_revision
        super().__init__(
            f"record '{record_id}' revision conflict: expected "
            f"{expected_revision}, actual {actual_revision}"
        )


class InvalidTransition(PersistenceError):
    """An observation status transition is not allowed."""


class ArchivedRecordError(PersistenceError):
    """An archived observation cannot be mutated."""


class UnitOfWorkStateError(PersistenceError):
    """The Unit of Work lifecycle is being used incorrectly."""
