from datetime import datetime, timedelta, timezone
from uuid import uuid4

import pytest

from app.models import FieldObservationRecord
from app.persistence import (
    INITIAL_REVISION,
    OBSERVATION_STATUSES,
    serialize_utc_timestamp,
    validate_observation_state,
    validate_record_id,
    validate_utc_timestamp,
)


def test_observation_status_and_initial_revision_contracts_are_explicit() -> None:
    assert OBSERVATION_STATUSES == ("open", "tracking", "closed")
    assert INITIAL_REVISION == 1


def test_field_observation_revision_defaults_to_one() -> None:
    observation = FieldObservationRecord(
        observation_id="obs-legacy-001",
        project_id="prj-legacy-001",
        observed_at="2026-07-12T18:30:00",
        location="A Blok 2. Kat",
        category="quality",
        description="Kalip birlesiminde aciklik goruldu.",
    )

    assert observation.revision == INITIAL_REVISION


def test_record_id_contract_accepts_canonical_uuid_string() -> None:
    record_id = str(uuid4())

    assert validate_record_id(record_id) == record_id


@pytest.mark.parametrize(
    "record_id",
    [
        "obs-001",
        "8B18CE4A-142F-4CA7-BAC0-6FD98CE19D27",
        "{8b18ce4a-142f-4ca7-bac0-6fd98ce19d27}",
        " 8b18ce4a-142f-4ca7-bac0-6fd98ce19d27 ",
    ],
)
def test_record_id_contract_rejects_noncanonical_values(record_id: str) -> None:
    with pytest.raises(ValueError, match="canonical UUID"):
        validate_record_id(record_id)


def test_utc_timestamp_serialization_normalizes_offset_to_z() -> None:
    istanbul_time = datetime(
        2026,
        7,
        12,
        21,
        30,
        tzinfo=timezone(timedelta(hours=3)),
    )

    assert serialize_utc_timestamp(istanbul_time) == "2026-07-12T18:30:00Z"


def test_utc_timestamp_serialization_rejects_naive_datetime() -> None:
    with pytest.raises(ValueError, match="timezone-aware"):
        serialize_utc_timestamp(datetime(2026, 7, 12, 18, 30))


def test_utc_timestamp_validation_accepts_iso_8601_z_value() -> None:
    timestamp = "2026-07-12T18:30:00Z"

    assert validate_utc_timestamp(timestamp) == timestamp


@pytest.mark.parametrize(
    "timestamp",
    [
        "2026-07-12T21:30:00+03:00",
        "2026-07-12 18:30:00Z",
        "2026-07-12T18:30:00",
        "not-a-timestamp",
    ],
)
def test_utc_timestamp_validation_rejects_noncanonical_values(
    timestamp: str,
) -> None:
    with pytest.raises(ValueError, match="UTC ISO 8601"):
        validate_utc_timestamp(timestamp)


@pytest.mark.parametrize(
    ("status", "closed_at"),
    [
        ("open", None),
        ("tracking", None),
        ("closed", "2026-07-12T18:30:00Z"),
    ],
)
def test_observation_state_contract_accepts_consistent_values(
    status: str,
    closed_at: str | None,
) -> None:
    validate_observation_state(status, closed_at)


@pytest.mark.parametrize(
    ("status", "closed_at"),
    [
        ("invalid", None),
        ("closed", None),
        ("open", "2026-07-12T18:30:00Z"),
        ("tracking", "2026-07-12T18:30:00Z"),
    ],
)
def test_observation_state_contract_rejects_invalid_or_inconsistent_values(
    status: str,
    closed_at: str | None,
) -> None:
    with pytest.raises(ValueError):
        validate_observation_state(status, closed_at)
