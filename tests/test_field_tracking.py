from dataclasses import replace
from datetime import date, datetime

import pytest

from app.field_tracking import (
    FOLLOW_UP_EVENT_TYPES,
    ROUTINE_OCCURRENCE_EVENT_TYPES,
    ROUTINE_TEMPLATE_EVENT_TYPES,
    FollowUpEvent,
    FollowUpEventType,
    FollowUpItem,
    FollowUpOutcome,
    FollowUpStatus,
    FollowUpViewGroup,
    RoutineOccurrence,
    RoutineOccurrenceEvent,
    RoutineOccurrenceOutcome,
    RoutineOccurrenceStatus,
    RoutineOccurrenceViewGroup,
    RoutineRecurrenceType,
    RoutineTemplate,
    RoutineTemplateEvent,
    RoutineTemplateStatus,
    build_occurrence_schedule,
    classify_follow_up,
    classify_routine_occurrence,
    create_follow_up_item,
    due_routine_dates,
    effective_follow_up_attention_at,
    is_now_attention_item,
    matches_routine_date,
    normalize_capture_text,
    plan_routine_occurrence,
    select_now_attention_items,
    validate_iso_weekday,
    validate_local_date,
    validate_local_time,
)


FOLLOW_UP_ID = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"
SECOND_FOLLOW_UP_ID = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"
TEMPLATE_ID = "cccccccc-cccc-4ccc-8ccc-cccccccccccc"
OCCURRENCE_ID = "dddddddd-dddd-4ddd-8ddd-dddddddddddd"
EVENT_ID = "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee"
PROJECT_ID = "11111111-1111-4111-8111-111111111111"
OBSERVATION_ID = "22222222-2222-4222-8222-222222222222"
CREATED_AT = "2026-07-14T08:00:00Z"
UPDATED_AT = "2026-07-14T09:00:00Z"
NOW_UTC = "2026-07-14T09:00:00Z"


def _follow_up(**overrides: object) -> FollowUpItem:
    values: dict[str, object] = {
        "follow_up_id": FOLLOW_UP_ID,
        "capture_text": "Beton öncesi kalıbı kontrol et",
        "title": "Beton öncesi kalıbı kontrol et",
        "created_at": CREATED_AT,
        "updated_at": UPDATED_AT,
        "status": FollowUpStatus.ACTIVE,
        "next_attention_at": "2026-07-14T10:00:00Z",
    }
    values.update(overrides)
    return FollowUpItem(**values)  # type: ignore[arg-type]


def _template(**overrides: object) -> RoutineTemplate:
    values: dict[str, object] = {
        "routine_template_id": TEMPLATE_ID,
        "title": "Puantajı tamamla",
        "recurrence_type": RoutineRecurrenceType.DAILY,
        "local_time": "17:00",
        "start_date": "2026-07-01",
        "created_at": CREATED_AT,
        "updated_at": UPDATED_AT,
    }
    values.update(overrides)
    return RoutineTemplate(**values)  # type: ignore[arg-type]


def _occurrence(**overrides: object) -> RoutineOccurrence:
    values: dict[str, object] = {
        "routine_occurrence_id": OCCURRENCE_ID,
        "routine_template_id": TEMPLATE_ID,
        "occurrence_local_date": "2026-07-14",
        "scheduled_local_time": "17:00",
        "scheduled_at_utc": "2026-07-14T14:00:00Z",
        "status": RoutineOccurrenceStatus.OPEN,
        "next_attention_at": "2026-07-14T10:00:00Z",
        "revision": 1,
        "created_at": CREATED_AT,
    }
    values.update(overrides)
    return RoutineOccurrence(**values)  # type: ignore[arg-type]


@pytest.mark.parametrize(
    ("raw", "expected"),
    [
        ("  Beton   öncesi\nkalıbı\tkontrol et  ", "Beton öncesi kalıbı kontrol et"),
        ("İSG: Çıkışları kontrol et!", "İSG: Çıkışları kontrol et!"),
        ("BÜYÜK küçük", "BÜYÜK küçük"),
    ],
)
def test_normalize_capture_text_preserves_meaning(raw: str, expected: str) -> None:
    assert normalize_capture_text(raw) == expected


@pytest.mark.parametrize("value", ["", "   ", "\n\t", None, 42])
def test_normalize_capture_text_rejects_empty_or_non_text(value: object) -> None:
    with pytest.raises(ValueError, match="capture_text"):
        normalize_capture_text(value)  # type: ignore[arg-type]


def test_quick_capture_factory_needs_only_capture_as_user_content() -> None:
    item = create_follow_up_item(
        follow_up_id=FOLLOW_UP_ID,
        capture_text="  Pompa   gelmeden hortumu kontrol et  ",
        created_at=CREATED_AT,
    )

    assert item.capture_text == "Pompa gelmeden hortumu kontrol et"
    assert item.title == item.capture_text
    assert item.item_type == "action"
    assert item.status == "inbox"
    assert item.project_id is None
    assert item.next_attention_at is None
    assert item.is_important is False
    assert item.revision == 1
    assert item.created_at == item.updated_at == CREATED_AT


def test_title_can_change_without_mutating_original_capture() -> None:
    original = create_follow_up_item(
        follow_up_id=FOLLOW_UP_ID,
        capture_text="Beton öncesi kontrol",
        created_at=CREATED_AT,
    )

    edited = replace(original, title="A Blok beton öncesi kalıp kontrolü")

    assert edited.title == "A Blok beton öncesi kalıp kontrolü"
    assert edited.capture_text == "Beton öncesi kontrol"


def test_follow_up_accepts_nullable_project() -> None:
    item = _follow_up(status="inbox", next_attention_at=None, project_id=None)
    assert item.project_id is None


def test_inbox_accepts_null_attention() -> None:
    assert _follow_up(status="inbox", next_attention_at=None).next_attention_at is None


@pytest.mark.parametrize("status", ["active", "waiting"])
def test_planned_open_follow_up_requires_attention(status: str) -> None:
    with pytest.raises(ValueError, match="require next_attention_at"):
        _follow_up(status=status, next_attention_at=None)


def test_observation_link_requires_project_at_domain_boundary() -> None:
    with pytest.raises(ValueError, match="observation_id requires project_id"):
        _follow_up(observation_id=OBSERVATION_ID, project_id=None)

    linked = _follow_up(observation_id=OBSERVATION_ID, project_id=PROJECT_ID)
    assert linked.observation_id == OBSERVATION_ID
    assert linked.project_id == PROJECT_ID


def test_completed_follow_up_requires_consistent_terminal_fields() -> None:
    item = _follow_up(
        status="completed",
        next_attention_at=None,
        outcome_type="completed",
        completed_at=UPDATED_AT,
    )
    assert item.status == "completed"
    assert item.outcome_type == "completed"

    with pytest.raises(ValueError, match="requires outcome_type and completed_at"):
        _follow_up(status="completed", next_attention_at=None)


def test_cancelled_follow_up_requires_cancelled_outcome_and_timestamp() -> None:
    item = _follow_up(
        status="cancelled",
        next_attention_at=None,
        outcome_type=FollowUpOutcome.CANCELLED,
        cancelled_at=UPDATED_AT,
    )
    assert item.outcome_type == "cancelled"

    with pytest.raises(ValueError, match="requires cancelled outcome"):
        _follow_up(
            status="cancelled",
            next_attention_at=None,
            outcome_type="not_required",
            cancelled_at=UPDATED_AT,
        )


def test_non_terminal_follow_up_rejects_outcome_fields() -> None:
    with pytest.raises(ValueError, match="non-terminal"):
        _follow_up(outcome_type="completed", completed_at=UPDATED_AT)


@pytest.mark.parametrize(
    ("field_name", "value", "message"),
    [
        ("follow_up_id", "NOT-A-UUID", "canonical UUID"),
        ("revision", 0, "revision"),
        ("created_at", "2026-07-14T08:00:00+00:00", "ending in Z"),
        ("status", "now", "status must be one of"),
    ],
)
def test_follow_up_rejects_invalid_identity_revision_time_and_status(
    field_name: str, value: object, message: str
) -> None:
    with pytest.raises(ValueError, match=message):
        _follow_up(**{field_name: value})


def test_effective_attention_uses_earlier_deadline() -> None:
    item = _follow_up(
        next_attention_at="2026-07-15T08:00:00Z",
        deadline_at="2026-07-14T12:00:00Z",
    )
    assert effective_follow_up_attention_at(item) == "2026-07-14T12:00:00Z"


@pytest.mark.parametrize(
    ("attention", "expected"),
    [
        ("2026-07-13T20:00:00Z", FollowUpViewGroup.OVERDUE),
        ("2026-07-14T10:00:00Z", FollowUpViewGroup.TODAY),
        ("2026-07-14T22:00:00Z", FollowUpViewGroup.UPCOMING),
    ],
)
def test_follow_up_planned_groups_use_istanbul_local_date(
    attention: str, expected: FollowUpViewGroup
) -> None:
    assert (
        classify_follow_up(
            _follow_up(next_attention_at=attention), date(2026, 7, 14)
        )
        == expected
    )


def test_follow_up_inbox_and_terminal_group_boundaries() -> None:
    assert (
        classify_follow_up(
            _follow_up(status="inbox", next_attention_at=None), date(2026, 7, 14)
        )
        == FollowUpViewGroup.INBOX
    )
    assert (
        classify_follow_up(
            _follow_up(
                status="completed",
                next_attention_at=None,
                outcome_type="completed",
                completed_at=UPDATED_AT,
            ),
            date(2026, 7, 14),
        )
        is None
    )


@pytest.mark.parametrize(
    ("item", "expected"),
    [
        (_follow_up(next_attention_at="2026-07-13T20:00:00Z"), True),
        (_follow_up(next_attention_at="2026-07-14T08:00:00Z"), True),
        (_follow_up(next_attention_at="2026-07-14T10:00:00Z"), False),
        (_follow_up(status="inbox", next_attention_at=None, is_important=True), True),
        (_follow_up(status="inbox", next_attention_at=None, is_important=False), False),
    ],
)
def test_now_attention_predicate_is_ui_composition(
    item: FollowUpItem, expected: bool
) -> None:
    assert is_now_attention_item(item, NOW_UTC) is expected


def test_now_attention_selection_deduplicates_by_follow_up_id() -> None:
    overdue = _follow_up(next_attention_at="2026-07-13T20:00:00Z")
    important = _follow_up(
        follow_up_id=SECOND_FOLLOW_UP_ID,
        status="inbox",
        next_attention_at=None,
        is_important=True,
    )

    assert select_now_attention_items([overdue, overdue, important], NOW_UTC) == (
        overdue,
        important,
    )


def test_now_is_not_a_domain_view_group() -> None:
    assert "now" not in {group.value for group in FollowUpViewGroup}
    assert "now" not in {group.value for group in RoutineOccurrenceViewGroup}


def test_daily_recurrence_and_inclusive_date_boundaries() -> None:
    template = _template(start_date="2026-07-10", end_date="2026-07-12")
    assert not matches_routine_date(template, date(2026, 7, 9))
    assert matches_routine_date(template, date(2026, 7, 10))
    assert matches_routine_date(template, date(2026, 7, 12))
    assert not matches_routine_date(template, date(2026, 7, 13))


@pytest.mark.parametrize(
    ("local_date", "expected"),
    [
        (date(2026, 7, 13), True),
        (date(2026, 7, 17), True),
        (date(2026, 7, 18), False),
        (date(2026, 7, 19), False),
    ],
)
def test_weekdays_recurrence_excludes_weekend(
    local_date: date, expected: bool
) -> None:
    template = _template(recurrence_type="weekdays")
    assert matches_routine_date(template, local_date) is expected


def test_weekly_recurrence_uses_selected_iso_weekdays() -> None:
    template = _template(recurrence_type="weekly", weekdays=frozenset({1, 3, 5}))
    assert matches_routine_date(template, date(2026, 7, 13))
    assert not matches_routine_date(template, date(2026, 7, 14))
    assert matches_routine_date(template, date(2026, 7, 15))


@pytest.mark.parametrize(
    ("month_day", "local_date", "expected"),
    [
        (28, date(2026, 2, 28), True),
        (29, date(2028, 2, 29), True),
        (30, date(2026, 4, 30), True),
        (31, date(2026, 7, 31), True),
        (31, date(2026, 4, 30), False),
        (29, date(2026, 2, 28), False),
    ],
)
def test_monthly_recurrence_never_shifts_missing_month_day(
    month_day: int, local_date: date, expected: bool
) -> None:
    template = _template(
        recurrence_type="monthly", month_day=month_day, start_date="2020-01-01"
    )
    assert matches_routine_date(template, local_date) is expected


@pytest.mark.parametrize(
    "overrides",
    [
        {"recurrence_type": "weekly", "weekdays": frozenset()},
        {"recurrence_type": "daily", "weekdays": frozenset({1})},
        {"recurrence_type": "monthly", "month_day": None},
        {"recurrence_type": "monthly", "month_day": 32},
        {"recurrence_type": "daily", "month_day": 1},
        {"end_date": "2026-06-30"},
    ],
)
def test_template_rejects_invalid_recurrence_field_combinations(
    overrides: dict[str, object]
) -> None:
    with pytest.raises(ValueError):
        _template(**overrides)


def test_template_accepts_nullable_project_and_rejects_bad_project_uuid() -> None:
    assert _template(project_id=None).project_id is None
    with pytest.raises(ValueError, match="project_id"):
        _template(project_id="project-1")


def test_inactive_template_requires_timestamp_and_matches_no_new_date() -> None:
    inactive = _template(status="inactive", deactivated_at=UPDATED_AT)
    assert not matches_routine_date(inactive, date(2026, 7, 14))

    with pytest.raises(ValueError, match="requires deactivated_at"):
        _template(status="inactive")
    with pytest.raises(ValueError, match="active template"):
        _template(status="active", deactivated_at=UPDATED_AT)


@pytest.mark.parametrize(
    ("validator", "valid", "invalid"),
    [
        (validate_local_date, "2026-07-14", "14.07.2026"),
        (validate_local_time, "09:05", "9:05"),
        (validate_iso_weekday, 7, 8),
    ],
)
def test_local_value_validators_are_exact(
    validator: object, valid: object, invalid: object
) -> None:
    assert validator(valid) == valid  # type: ignore[operator]
    with pytest.raises(ValueError):
        validator(invalid)  # type: ignore[operator]


def test_due_window_is_today_inclusive_bounded_and_sorted() -> None:
    due = due_routine_dates(_template(), date(2026, 7, 14))
    assert due == tuple(date(2026, 7, day) for day in range(8, 15))
    assert date(2026, 7, 7) not in due
    assert all(value <= date(2026, 7, 14) for value in due)


def test_due_window_intersects_template_start_and_end() -> None:
    template = _template(start_date="2026-07-11", end_date="2026-07-13")
    assert due_routine_dates(template, date(2026, 7, 14)) == (
        date(2026, 7, 11),
        date(2026, 7, 12),
        date(2026, 7, 13),
    )


@pytest.mark.parametrize("window_days", [0, -1, True, 1.5])
def test_due_window_rejects_invalid_size(window_days: object) -> None:
    with pytest.raises(ValueError, match="window_days"):
        due_routine_dates(
            _template(), date(2026, 7, 14), window_days  # type: ignore[arg-type]
        )


def test_schedule_uses_zoneinfo_and_preserves_snapshots() -> None:
    schedule = build_occurrence_schedule(_template(), date(2026, 7, 14))
    assert schedule.occurrence_local_date == "2026-07-14"
    assert schedule.scheduled_local_time == "17:00"
    assert schedule.scheduled_at_utc == "2026-07-14T14:00:00Z"
    assert schedule.next_attention_at == schedule.scheduled_at_utc


def test_template_rejects_unsupported_timezone() -> None:
    with pytest.raises(ValueError, match="timezone"):
        _template(timezone="UTC")


def test_occurrence_plan_marks_past_missed_and_today_open() -> None:
    template = _template()
    missed = plan_routine_occurrence(
        template, date(2026, 7, 13), date(2026, 7, 14)
    )
    current = plan_routine_occurrence(
        template, date(2026, 7, 14), date(2026, 7, 14)
    )

    assert missed.status == "closed"
    assert missed.outcome_type == "missed"
    assert current.status == "open"
    assert current.outcome_type is None


def test_occurrence_plan_rejects_future_or_non_matching_date() -> None:
    with pytest.raises(ValueError, match="future"):
        plan_routine_occurrence(
            _template(), date(2026, 7, 15), date(2026, 7, 14)
        )
    with pytest.raises(ValueError, match="does not match"):
        plan_routine_occurrence(
            _template(recurrence_type="weekdays"),
            date(2026, 7, 12),
            date(2026, 7, 14),
        )


def test_recurrence_functions_reject_datetime_instead_of_local_date() -> None:
    with pytest.raises(ValueError, match="must be a date"):
        matches_routine_date(_template(), datetime(2026, 7, 14, 12, 0))


def test_open_and_closed_occurrence_invariants() -> None:
    assert _occurrence().outcome_type is None
    closed = _occurrence(
        status="closed",
        outcome_type="no_work",
        outcome_note="Sahada çalışma yoktu.",
        completed_at=UPDATED_AT,
    )
    assert closed.outcome_type == "no_work"

    with pytest.raises(ValueError, match="open occurrence"):
        _occurrence(outcome_type="completed", completed_at=UPDATED_AT)
    with pytest.raises(ValueError, match="closed occurrence"):
        _occurrence(status="closed")


@pytest.mark.parametrize(
    ("attention", "expected"),
    [
        ("2026-07-14T08:59:59Z", RoutineOccurrenceViewGroup.OVERDUE),
        ("2026-07-14T09:00:00Z", RoutineOccurrenceViewGroup.TODAY),
        ("2026-07-14T22:00:00Z", RoutineOccurrenceViewGroup.UPCOMING),
    ],
)
def test_open_occurrence_view_groups(
    attention: str, expected: RoutineOccurrenceViewGroup
) -> None:
    assert classify_routine_occurrence(
        _occurrence(next_attention_at=attention), NOW_UTC
    ) == expected


def test_closed_occurrence_has_no_open_view_group() -> None:
    occurrence = _occurrence(
        status="closed", outcome_type="completed", completed_at=UPDATED_AT
    )
    assert classify_routine_occurrence(occurrence, NOW_UTC) is None


def test_event_vocabularies_match_contract() -> None:
    assert FOLLOW_UP_EVENT_TYPES == (
        "follow_up.created",
        "follow_up.scheduled",
        "follow_up.rescheduled",
        "follow_up.waiting_started",
        "follow_up.completed",
        "follow_up.cancelled",
        "follow_up.reopened",
        "follow_up.observation_linked",
        "follow_up.converted_to_observation",
    )
    assert ROUTINE_TEMPLATE_EVENT_TYPES == (
        "routine_template.created",
        "routine_template.updated",
        "routine_template.deactivated",
    )
    assert ROUTINE_OCCURRENCE_EVENT_TYPES == (
        "routine_occurrence.created",
        "routine_occurrence.snoozed",
        "routine_occurrence.completed",
        "routine_occurrence.no_work",
        "routine_occurrence.not_required",
        "routine_occurrence.missed",
        "routine_occurrence.reopened",
    )


@pytest.mark.parametrize(
    ("event_class", "aggregate_name", "aggregate_id", "event_type"),
    [
        (FollowUpEvent, "follow_up_id", FOLLOW_UP_ID, "follow_up.created"),
        (
            RoutineTemplateEvent,
            "routine_template_id",
            TEMPLATE_ID,
            "routine_template.created",
        ),
        (
            RoutineOccurrenceEvent,
            "routine_occurrence_id",
            OCCURRENCE_ID,
            "routine_occurrence.created",
        ),
    ],
)
def test_event_records_validate_and_canonicalize_payload(
    event_class: type[object],
    aggregate_name: str,
    aggregate_id: str,
    event_type: str,
) -> None:
    event = event_class(
        event_id=EVENT_ID,
        sequence=1,
        event_type=event_type,
        actor="Santiye şefi",
        occurred_at=CREATED_AT,
        payload={"z": 2, "revision": 1, "a": {"ş": "değer"}},
        **{aggregate_name: aggregate_id},
    )
    assert event.payload_json == '{"a":{"ş":"değer"},"revision":1,"z":2}'


@pytest.mark.parametrize(
    ("overrides", "message"),
    [
        ({"sequence": 0}, "sequence"),
        ({"actor": "   "}, "actor"),
        ({"occurred_at": "2026-07-14T08:00:00+00:00"}, "ending in Z"),
        ({"event_type": "follow_up.unknown"}, "event_type"),
        ({"payload": {}}, "revision"),
        ({"payload": {"revision": 0}}, "revision"),
        ({"payload": {"revision": 1, "bad": float("nan")}}, "JSON object"),
    ],
)
def test_event_rejects_invalid_sequence_type_actor_time_or_payload(
    overrides: dict[str, object], message: str
) -> None:
    values: dict[str, object] = {
        "event_id": EVENT_ID,
        "follow_up_id": FOLLOW_UP_ID,
        "sequence": 1,
        "event_type": FollowUpEventType.CREATED,
        "actor": "Santiye şefi",
        "occurred_at": CREATED_AT,
        "payload": {"revision": 1},
    }
    values.update(overrides)
    with pytest.raises(ValueError, match=message):
        FollowUpEvent(**values)  # type: ignore[arg-type]
