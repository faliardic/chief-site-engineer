"""Canonical timestamp semantics shared by CSE application layers."""

from collections.abc import Callable
from datetime import datetime, timezone
from enum import Enum
import re
from typing import Literal
from zoneinfo import ZoneInfo


UTC = timezone.utc
ISTANBUL_TIMEZONE_NAME = "Europe/Istanbul"
ISTANBUL_TIMEZONE = ZoneInfo(ISTANBUL_TIMEZONE_NAME)
TimestampPrecision = Literal["seconds", "microseconds"]

_UTC_TIMESTAMP_PATTERN = re.compile(
    r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{6})?Z"
)


class TimestampRole(str, Enum):
    """Stable meanings used by storage and migration review."""

    EVENT_TIME = "event_time"
    PERSISTENT_ENTRY_TIME = "persistent_entry_time"
    LAST_UPDATE_TIME = "last_update_time"
    SCHEDULED_TIME = "scheduled_time"
    LIFECYCLE_TIME = "lifecycle_time"

    @property
    def allows_future(self) -> bool:
        """Only an explicit schedule/attention/deadline may be in the future."""

        return self is TimestampRole.SCHEDULED_TIME


def system_utc_clock() -> datetime:
    """Return the current aware UTC instant without using the local timezone."""

    return datetime.now(UTC)


def serialize_utc_timestamp(
    value: datetime, *, precision: TimestampPrecision = "seconds"
) -> str:
    """Normalize an aware datetime to deterministic UTC storage text."""

    if not isinstance(value, datetime) or value.tzinfo is None:
        raise ValueError("timestamp must be timezone-aware")
    try:
        offset = value.utcoffset()
    except (OverflowError, TypeError, ValueError) as exc:
        raise ValueError("timestamp must be timezone-aware") from exc
    if offset is None:
        raise ValueError("timestamp must be timezone-aware")
    if precision not in ("seconds", "microseconds"):
        raise ValueError("precision must be seconds or microseconds")

    utc_value = value.astimezone(UTC)
    if precision == "seconds":
        utc_value = utc_value.replace(microsecond=0)
    return utc_value.isoformat(timespec=precision).replace("+00:00", "Z")


def parse_utc_timestamp(value: str) -> datetime:
    """Parse canonical UTC text, accepting legacy six-digit microseconds."""

    error_message = "timestamp must be a UTC ISO 8601 value ending in Z"
    if not isinstance(value, str) or _UTC_TIMESTAMP_PATTERN.fullmatch(value) is None:
        raise ValueError(error_message)
    try:
        parsed = datetime.fromisoformat(f"{value[:-1]}+00:00")
    except ValueError as exc:
        raise ValueError(error_message) from exc
    if parsed.utcoffset() != UTC.utcoffset(None):
        raise ValueError(error_message)
    return parsed


def parse_aware_timestamp(value: str) -> datetime:
    """Parse an ISO timestamp with an explicit offset; never assume local time."""

    error_message = "timestamp must include an explicit timezone offset"
    if (
        not isinstance(value, str)
        or value != value.strip()
        or len(value) < 20
        or value[10] != "T"
    ):
        raise ValueError(error_message)
    candidate = f"{value[:-1]}+00:00" if value.endswith("Z") else value
    try:
        parsed = datetime.fromisoformat(candidate)
    except ValueError as exc:
        raise ValueError(error_message) from exc
    if parsed.tzinfo is None or parsed.utcoffset() is None:
        raise ValueError(error_message)
    return parsed


def normalize_utc_timestamp(
    value: str, *, precision: TimestampPrecision = "seconds"
) -> str:
    """Normalize explicitly offset ISO text to canonical UTC storage text."""

    return serialize_utc_timestamp(parse_aware_timestamp(value), precision=precision)


def utc_now(
    *,
    clock: Callable[[], datetime] = system_utc_clock,
    precision: TimestampPrecision = "seconds",
) -> str:
    """Read an injectable aware clock and return canonical UTC text."""

    return serialize_utc_timestamp(clock(), precision=precision)


def to_timezone(value: str, timezone_name: str) -> datetime:
    """Convert canonical UTC text to an explicit IANA timezone."""

    try:
        target = ZoneInfo(timezone_name)
    except (KeyError, TypeError) as exc:
        raise ValueError("timezone_name must identify an available IANA timezone") from exc
    return parse_utc_timestamp(value).astimezone(target)


def to_istanbul(value: str) -> datetime:
    """Convert canonical UTC text to the CSE presentation timezone."""

    return parse_utc_timestamp(value).astimezone(ISTANBUL_TIMEZONE)


def format_istanbul_timestamp(value: str, pattern: str) -> str:
    """Format canonical UTC text for an Istanbul user surface."""

    return to_istanbul(value).strftime(pattern)


def validate_temporal_policy(
    value: str, *, role: TimestampRole, as_of_utc: str
) -> str:
    """Reject future historical facts while permitting explicit schedules."""

    instant = parse_utc_timestamp(value)
    as_of = parse_utc_timestamp(as_of_utc)
    if not role.allows_future and instant > as_of:
        raise ValueError(f"{role.value} must not be in the future")
    return value


__all__ = [
    "ISTANBUL_TIMEZONE",
    "ISTANBUL_TIMEZONE_NAME",
    "TimestampPrecision",
    "TimestampRole",
    "UTC",
    "format_istanbul_timestamp",
    "normalize_utc_timestamp",
    "parse_aware_timestamp",
    "parse_utc_timestamp",
    "serialize_utc_timestamp",
    "system_utc_clock",
    "to_istanbul",
    "to_timezone",
    "utc_now",
    "validate_temporal_policy",
]
