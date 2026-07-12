"""Domain and storage value contracts used by SQLite persistence."""

from datetime import datetime, timedelta, timezone
from uuid import UUID


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


def serialize_utc_timestamp(value: datetime) -> str:
    """Serialize a timezone-aware ``datetime`` as an ISO 8601 UTC string."""

    if value.tzinfo is None or value.utcoffset() is None:
        raise ValueError("timestamp must be timezone-aware")

    utc_value = value.astimezone(timezone.utc)
    return utc_value.isoformat().replace("+00:00", "Z")


def validate_utc_timestamp(value: str) -> str:
    """Return a canonical UTC timestamp ending in ``Z`` or raise ``ValueError``."""

    error_message = "timestamp must be a UTC ISO 8601 value ending in Z"
    if (
        not isinstance(value, str)
        or value != value.strip()
        or len(value) < 20
        or value[10] != "T"
        or not value.endswith("Z")
    ):
        raise ValueError(error_message)

    try:
        parsed_value = datetime.fromisoformat(f"{value[:-1]}+00:00")
    except ValueError as exc:
        raise ValueError(error_message) from exc

    if parsed_value.utcoffset() != timedelta(0):
        raise ValueError(error_message)
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
