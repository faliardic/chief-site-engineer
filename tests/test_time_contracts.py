from datetime import datetime, timedelta, timezone

import pytest

from app.time_contracts import (
    TimestampRole,
    format_istanbul_timestamp,
    normalize_utc_timestamp,
    parse_utc_timestamp,
    serialize_utc_timestamp,
    to_timezone,
    utc_now,
    validate_temporal_policy,
)


def test_utc_round_trip_and_non_utc_offset_normalization() -> None:
    source = datetime(2026, 7, 17, 22, 15, tzinfo=timezone(timedelta(hours=3)))

    stored = serialize_utc_timestamp(source)

    assert stored == "2026-07-17T19:15:00Z"
    assert parse_utc_timestamp(stored) == datetime(
        2026, 7, 17, 19, 15, tzinfo=timezone.utc
    )
    assert normalize_utc_timestamp("2026-07-17T22:15:00+03:00") == stored


def test_istanbul_presentation_uses_named_timezone() -> None:
    assert (
        format_istanbul_timestamp("2026-01-17T09:30:00Z", "%d.%m.%Y %H:%M")
        == "17.01.2026 12:30"
    )


@pytest.mark.parametrize(
    "value",
    (
        datetime(2026, 7, 17, 19, 15),
        "2026-07-17T19:15:00",
        "not-a-time",
    ),
)
def test_naive_and_invalid_values_fail_closed(value: object) -> None:
    if isinstance(value, datetime):
        with pytest.raises(ValueError, match="timezone-aware"):
            serialize_utc_timestamp(value)
    elif value.endswith("00"):
        with pytest.raises(ValueError, match="explicit timezone"):
            normalize_utc_timestamp(value)
    else:
        with pytest.raises(ValueError, match="ending in Z"):
            parse_utc_timestamp(value)


def test_precision_is_explicit_and_deterministic() -> None:
    value = datetime(2026, 7, 17, 19, 15, 0, 123456, tzinfo=timezone.utc)

    assert serialize_utc_timestamp(value) == "2026-07-17T19:15:00Z"
    microseconds = serialize_utc_timestamp(value, precision="microseconds")
    assert microseconds == "2026-07-17T19:15:00.123456Z"
    assert parse_utc_timestamp(microseconds) == value


def test_past_and_future_policy_depends_on_timestamp_role() -> None:
    as_of = "2026-07-17T19:15:00Z"
    past = "2026-07-17T19:14:59Z"
    future = "2026-07-17T19:15:01Z"

    assert (
        validate_temporal_policy(
            past, role=TimestampRole.EVENT_TIME, as_of_utc=as_of
        )
        == past
    )
    assert (
        validate_temporal_policy(
            future, role=TimestampRole.SCHEDULED_TIME, as_of_utc=as_of
        )
        == future
    )
    for role in (
        TimestampRole.EVENT_TIME,
        TimestampRole.PERSISTENT_ENTRY_TIME,
        TimestampRole.LAST_UPDATE_TIME,
        TimestampRole.LIFECYCLE_TIME,
    ):
        with pytest.raises(ValueError, match="must not be in the future"):
            validate_temporal_policy(future, role=role, as_of_utc=as_of)


def test_generic_dst_fold_keeps_two_distinct_instants() -> None:
    first = to_timezone("2026-11-01T05:30:00Z", "America/New_York")
    second = to_timezone("2026-11-01T06:30:00Z", "America/New_York")

    assert first.strftime("%Y-%m-%d %H:%M") == second.strftime("%Y-%m-%d %H:%M")
    assert first.utcoffset() != second.utcoffset()
    assert first.fold == 0
    assert second.fold == 1


def test_utc_now_uses_the_injected_aware_clock() -> None:
    fixed = datetime(
        2026,
        7,
        17,
        22,
        15,
        0,
        987654,
        tzinfo=timezone(timedelta(hours=3)),
    )

    assert utc_now(clock=lambda: fixed) == "2026-07-17T19:15:00Z"
    assert (
        utc_now(clock=lambda: fixed, precision="microseconds")
        == "2026-07-17T19:15:00.987654Z"
    )
