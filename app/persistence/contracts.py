"""Domain and storage value contracts used by SQLite persistence."""

from uuid import UUID

from app.time_contracts import (
    parse_utc_timestamp,
    serialize_utc_timestamp,
)


OBSERVATION_STATUSES: tuple[str, ...] = ("open", "tracking", "closed")
ATTACHMENT_STATUSES: tuple[str, ...] = (
    "active",
    "archived",
    "superseded",
    "missing",
)
INITIAL_REVISION = 1


def validate_record_id(value: str) -> str:
    """Return a canonical UUID string or raise ``ValueError``."""

    try:
        parsed_value = UUID(value)
    except (AttributeError, TypeError, ValueError) as exc:
        raise ValueError("record id must be a canonical UUID string") from exc

    if str(parsed_value) != value:
        raise ValueError("record id must be a canonical UUID string")
    return value


def validate_utc_timestamp(value: str) -> str:
    """Return a canonical UTC timestamp ending in ``Z`` or raise ``ValueError``."""

    parse_utc_timestamp(value)
    return value


def validate_observation_state(status: str, closed_at: str | None) -> None:
    """Validate status vocabulary and its relationship with ``closed_at``."""

    if status not in OBSERVATION_STATUSES:
        raise ValueError(f"status must be one of {OBSERVATION_STATUSES}")
    if closed_at is not None:
        validate_utc_timestamp(closed_at)

    is_closed = status == "closed"
    has_closed_at = closed_at is not None
    if is_closed != has_closed_at:
        raise ValueError("closed status and closed_at must be set together")
