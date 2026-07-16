from dataclasses import FrozenInstanceError, replace
from datetime import date
from pathlib import Path

import pytest

from app.application import (
    CloseRoutineOccurrence,
    CreateRoutineTemplate,
    RoutineApplicationService,
    RoutineOccurrenceQuery,
    RoutineOccurrenceView,
    RoutineTemplateQuery,
    UpdateRoutineTemplate,
)
from app.field_tracking import (
    RoutineOccurrence,
    RoutineOccurrenceEventType,
    RoutineOccurrenceOutcome,
    RoutineOccurrenceStatus,
    RoutineRecurrenceType,
    RoutineTemplate,
    RoutineTemplateEventType,
    RoutineTemplateStatus,
    build_occurrence_schedule,
)
from app.persistence import (
    InvalidRecordError,
    ProjectRecord,
    RecordNotFound,
    RevisionConflict,
    SQLiteRoutineOccurrenceEventRepository,
    SQLiteRoutineOccurrenceRepository,
    SQLiteRoutineTemplateEventRepository,
    SQLiteUnitOfWork,
)


PROJECT_ID = "11111111-1111-4111-8111-111111111111"
SECOND_PROJECT_ID = "22222222-2222-4222-8222-222222222222"
TEMPLATE_ID = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"
SECOND_TEMPLATE_ID = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"
OCCURRENCE_ID = "cccccccc-cccc-4ccc-8ccc-cccccccccccc"
SECOND_OCCURRENCE_ID = "dddddddd-dddd-4ddd-8ddd-dddddddddddd"
T0 = "2026-07-15T05:00:00Z"
T1 = "2026-07-16T05:00:00Z"
T2 = "2026-07-16T06:00:00Z"
T3 = "2026-07-16T07:00:00Z"
T4 = "2026-07-16T08:00:00Z"
AS_OF_UTC = "2026-07-16T09:00:00Z"


def _uuid(number: int) -> str:
    return (
        f"{number:08x}-{number:04x}-4{number % 4096:03x}-"
        f"8{number % 4096:03x}-{number:012x}"
    )


class Values:
    def __init__(self, values: list[str] | tuple[str, ...]) -> None:
        self._values = iter(values)
        self.calls = 0

    def __call__(self) -> str:
        self.calls += 1
        return next(self._values)


class RepeatingValue:
    def __init__(self, value: str) -> None:
        self.value = value
        self.calls = 0

    def __call__(self) -> str:
        self.calls += 1
        return self.value


class UUIDValues:
    def __init__(self, start: int = 100) -> None:
        self.next_value = start
        self.calls = 0

    def __call__(self) -> str:
        self.calls += 1
        value = _uuid(self.next_value)
        self.next_value += 1
        return value


def _service(
    database_path: Path,
    *,
    clock: object | None = None,
    uuid_factory: object | None = None,
    uow_factory: object | None = None,
) -> RoutineApplicationService:
    kwargs: dict[str, object] = {}
    if uow_factory is not None:
        kwargs["uow_factory"] = uow_factory
    return RoutineApplicationService(
        database_path,
        clock=clock or RepeatingValue(T2),  # type: ignore[arg-type]
        uuid_factory=uuid_factory or UUIDValues(),  # type: ignore[arg-type]
        local_actor="  Şantiye şefi  ",
        **kwargs,  # type: ignore[arg-type]
    )


def _create_command(**overrides: object) -> CreateRoutineTemplate:
    values: dict[str, object] = {
        "title": "Puantajı tamamla",
        "recurrence_type": RoutineRecurrenceType.DAILY,
        "local_time": "17:00",
        "start_date": "2026-07-01",
    }
    values.update(overrides)
    return CreateRoutineTemplate(**values)  # type: ignore[arg-type]


def _update_command(**overrides: object) -> UpdateRoutineTemplate:
    values: dict[str, object] = {
        "title": "Puantajı tamamla",
        "recurrence_type": RoutineRecurrenceType.DAILY,
        "local_time": "17:00",
        "start_date": "2026-07-01",
    }
    values.update(overrides)
    return UpdateRoutineTemplate(**values)  # type: ignore[arg-type]


def _template(
    routine_template_id: str = TEMPLATE_ID, **overrides: object
) -> RoutineTemplate:
    values: dict[str, object] = {
        "routine_template_id": routine_template_id,
        "title": "Puantajı tamamla",
        "recurrence_type": RoutineRecurrenceType.DAILY,
        "local_time": "09:00",
        "start_date": "2026-07-01",
        "created_at": T0,
        "updated_at": T0,
    }
    values.update(overrides)
    return RoutineTemplate(**values)  # type: ignore[arg-type]


def _occurrence(
    routine_occurrence_id: str = OCCURRENCE_ID,
    *,
    template: RoutineTemplate | None = None,
    local_date: str = "2026-07-16",
    next_attention_at: str | None = None,
    status: RoutineOccurrenceStatus = RoutineOccurrenceStatus.OPEN,
    outcome_type: RoutineOccurrenceOutcome | None = None,
    outcome_note: str | None = None,
    completed_at: str | None = None,
    revision: int = 1,
) -> RoutineOccurrence:
    template = template or _template()
    schedule = build_occurrence_schedule(template, date.fromisoformat(local_date))
    return RoutineOccurrence(
        routine_occurrence_id=routine_occurrence_id,
        routine_template_id=template.routine_template_id,
        occurrence_local_date=local_date,
        scheduled_local_time=schedule.scheduled_local_time,
        scheduled_at_utc=schedule.scheduled_at_utc,
        status=status,
        next_attention_at=next_attention_at or schedule.next_attention_at,
        outcome_type=outcome_type,
        outcome_note=outcome_note,
        revision=revision,
        created_at=T1,
        completed_at=completed_at,
    )


def _seed_projects(database_path: Path) -> None:
    with SQLiteUnitOfWork(database_path) as unit_of_work:
        unit_of_work.projects.add(ProjectRecord(PROJECT_ID, "Birinci", T0))
        unit_of_work.projects.add(ProjectRecord(SECOND_PROJECT_ID, "İkinci", T0))
        unit_of_work.commit()


def _seed_templates(database_path: Path, *templates: RoutineTemplate) -> None:
    with SQLiteUnitOfWork(database_path) as unit_of_work:
        for template in templates:
            if template.revision == 1:
                unit_of_work.routine_templates.add(template)
                continue
            initial = replace(
                template,
                status=RoutineTemplateStatus.ACTIVE,
                deactivated_at=None,
                revision=1,
                updated_at=template.created_at,
            )
            unit_of_work.routine_templates.add(initial)
            unit_of_work.routine_templates.update(template, expected_revision=1)
        unit_of_work.commit()


def _seed_occurrences(database_path: Path, *occurrences: RoutineOccurrence) -> None:
    with SQLiteUnitOfWork(database_path) as unit_of_work:
        for occurrence in occurrences:
            if occurrence.revision == 1:
                unit_of_work.routine_occurrences.add_if_absent(occurrence)
                continue
            initial = replace(
                occurrence,
                status=RoutineOccurrenceStatus.OPEN,
                outcome_type=None,
                outcome_note=None,
                completed_at=None,
                revision=1,
            )
            unit_of_work.routine_occurrences.add_if_absent(initial)
            unit_of_work.routine_occurrences.update(
                occurrence, expected_revision=1
            )
        unit_of_work.commit()


def test_application_values_are_immutable_normalized_and_validate_queries() -> None:
    command = _create_command(
        title="  Günlük   saha\nraporu ", description="   ", project_id=None
    )
    query = RoutineOccurrenceQuery(
        status="open", view="today", as_of_utc=AS_OF_UTC  # type: ignore[arg-type]
    )

    assert command.title == "Günlük saha raporu"
    assert command.description is None
    assert query.status is RoutineOccurrenceStatus.OPEN
    assert query.view is RoutineOccurrenceView.TODAY
    with pytest.raises(FrozenInstanceError):
        command.title = "değiştir"  # type: ignore[misc]
    with pytest.raises(ValueError, match="cannot be used together"):
        RoutineTemplateQuery(project_id=PROJECT_ID, personal_only=True)
    with pytest.raises(ValueError, match="requires as_of_utc"):
        RoutineOccurrenceQuery(view=RoutineOccurrenceView.OVERDUE)


@pytest.mark.parametrize(
    ("recurrence_type", "weekdays", "month_day"),
    [
        ("daily", frozenset(), None),
        ("weekdays", frozenset(), None),
        ("weekly", frozenset({1, 3, 5}), None),
        ("monthly", frozenset(), 31),
    ],
)
def test_create_supports_all_recurrence_types(
    tmp_path: Path,
    recurrence_type: str,
    weekdays: frozenset[int],
    month_day: int | None,
) -> None:
    database_path = tmp_path / f"{recurrence_type}.sqlite3"
    created = _service(database_path).create_template(
        _create_command(
            recurrence_type=recurrence_type,
            weekdays=weekdays,
            month_day=month_day,
        )
    )

    assert created.recurrence_type.value == recurrence_type
    assert created.weekdays == weekdays
    assert created.month_day == month_day


@pytest.mark.parametrize(
    "overrides",
    [
        {"title": "   "},
        {"local_time": "9:00"},
        {"start_date": "16.07.2026"},
        {"start_date": "2026-07-16", "end_date": "2026-07-15"},
        {"recurrence_type": "weekly", "weekdays": frozenset()},
        {"recurrence_type": "daily", "weekdays": frozenset({1})},
        {"recurrence_type": "monthly", "month_day": None},
        {"recurrence_type": "monthly", "month_day": 32},
        {"recurrence_type": "daily", "month_day": 1},
    ],
)
def test_template_commands_reject_invalid_values(overrides: dict[str, object]) -> None:
    with pytest.raises(ValueError):
        _create_command(**overrides)


@pytest.mark.parametrize("actor", ["", "   ", None])
def test_constructor_rejects_empty_actor(tmp_path: Path, actor: object) -> None:
    with pytest.raises(ValueError, match="local_actor"):
        RoutineApplicationService(
            tmp_path / "actor.sqlite3", local_actor=actor  # type: ignore[arg-type]
        )


def test_create_get_list_and_history_cover_personal_and_project_templates(
    tmp_path: Path,
) -> None:
    database_path = tmp_path / "create.sqlite3"
    _seed_projects(database_path)
    ids = UUIDValues()
    service = _service(database_path, clock=RepeatingValue(T1), uuid_factory=ids)
    personal = service.create_template(_create_command())
    project = service.create_template(
        _create_command(title="İSG turu", project_id=PROJECT_ID)
    )

    assert service.get_template(personal.routine_template_id) == personal
    assert service.list_templates(RoutineTemplateQuery(personal_only=True)) == (
        personal,
    )
    assert service.list_templates(RoutineTemplateQuery(project_id=PROJECT_ID)) == (
        project,
    )
    history = service.list_template_history(personal.routine_template_id)
    assert len(history) == 1
    assert history[0].sequence == 1
    assert history[0].event_type is RoutineTemplateEventType.CREATED
    assert history[0].actor == "Şantiye şefi"
    assert history[0].payload == {
        "local_time": "17:00",
        "project_id": None,
        "recurrence_type": "daily",
        "revision": 1,
        "status": "active",
    }


def test_create_missing_project_event_failure_and_commit_failure_roll_back(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    missing_database = tmp_path / "missing-project.sqlite3"
    with pytest.raises(RecordNotFound):
        _service(missing_database).create_template(
            _create_command(project_id=PROJECT_ID)
        )

    event_database = tmp_path / "event-failure.sqlite3"
    monkeypatch.setattr(
        SQLiteRoutineTemplateEventRepository,
        "add",
        lambda *_: (_ for _ in ()).throw(InvalidRecordError("event failed")),
    )
    with pytest.raises(InvalidRecordError, match="event failed"):
        _service(event_database).create_template(_create_command())
    with SQLiteUnitOfWork(event_database) as unit_of_work:
        assert unit_of_work.routine_templates.list_all() == []
    monkeypatch.undo()

    class CommitFailingUnitOfWork(SQLiteUnitOfWork):
        def commit(self) -> None:
            raise OSError("commit failed")

    commit_database = tmp_path / "commit-failure.sqlite3"
    service = _service(
        commit_database,
        uow_factory=lambda: CommitFailingUnitOfWork(commit_database),
    )
    with pytest.raises(OSError, match="commit failed"):
        service.create_template(_create_command())
    with SQLiteUnitOfWork(commit_database) as unit_of_work:
        assert unit_of_work.routine_templates.list_all() == []


def test_update_allowlist_exact_changed_fields_and_snapshot_preservation(
    tmp_path: Path,
) -> None:
    database_path = tmp_path / "update.sqlite3"
    _seed_projects(database_path)
    original = _template(project_id=None)
    occurrence = _occurrence(template=original)
    _seed_templates(database_path, original)
    _seed_occurrences(database_path, occurrence)
    service = _service(database_path, clock=RepeatingValue(T2))

    updated = service.update_template(
        TEMPLATE_ID,
        1,
        _update_command(
            title="  Yeni   rutin ",
            description=" Açıklama ",
            project_id=PROJECT_ID,
            recurrence_type="weekly",
            weekdays=frozenset({2, 4}),
            local_time="16:30",
            start_date="2026-07-02",
            end_date="2026-12-31",
            is_important=True,
        ),
    )

    assert updated.revision == 2
    assert updated.timezone == "Europe/Istanbul"
    assert updated.created_at == T0
    assert updated.deactivated_at is None
    history = service.list_template_history(TEMPLATE_ID)
    assert history[0].event_type is RoutineTemplateEventType.UPDATED
    assert history[0].payload == {
        "changed_fields": [
            "description",
            "end_date",
            "is_important",
            "local_time",
            "project_id",
            "recurrence_type",
            "start_date",
            "title",
            "weekdays",
        ],
        "revision": 2,
    }
    with SQLiteUnitOfWork(database_path) as unit_of_work:
        assert unit_of_work.routine_occurrences.get(OCCURRENCE_ID) == occurrence


def test_update_noop_consumes_no_clock_or_uuid_and_stale_wins(tmp_path: Path) -> None:
    database_path = tmp_path / "update-noop.sqlite3"
    _seed_templates(database_path, _template())
    clock = RepeatingValue(T2)
    ids = UUIDValues()
    service = _service(database_path, clock=clock, uuid_factory=ids)

    command = _update_command(local_time="09:00")
    assert service.update_template(TEMPLATE_ID, 1, command) == _template()
    assert clock.calls == 0
    assert ids.calls == 0
    with pytest.raises(RevisionConflict):
        service.update_template(TEMPLATE_ID, 2, command)
    assert clock.calls == 0
    assert ids.calls == 0


def test_update_covers_month_day_and_weekday_allowlist_fields(tmp_path: Path) -> None:
    database_path = tmp_path / "update-month-day.sqlite3"
    weekly = _template(
        recurrence_type=RoutineRecurrenceType.WEEKLY,
        weekdays=frozenset({1}),
    )
    _seed_templates(database_path, weekly)
    service = _service(database_path)

    updated = service.update_template(
        TEMPLATE_ID,
        1,
        _update_command(
            recurrence_type=RoutineRecurrenceType.MONTHLY,
            month_day=31,
            local_time="09:00",
        ),
    )

    assert updated.month_day == 31
    assert updated.weekdays == frozenset()
    assert service.list_template_history(TEMPLATE_ID)[0].payload == {
        "changed_fields": ["month_day", "recurrence_type", "weekdays"],
        "revision": 2,
    }


def test_update_rejects_inactive_and_rolls_back_event_failure(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    inactive_database = tmp_path / "inactive.sqlite3"
    inactive = _template(
        status=RoutineTemplateStatus.INACTIVE,
        deactivated_at=T1,
        revision=2,
        updated_at=T1,
    )
    _seed_templates(inactive_database, inactive)
    with pytest.raises(InvalidRecordError, match="inactive"):
        _service(inactive_database).update_template(
            TEMPLATE_ID, 2, _update_command(title="Değiştir")
        )

    database_path = tmp_path / "update-event.sqlite3"
    _seed_templates(database_path, _template())
    monkeypatch.setattr(
        SQLiteRoutineTemplateEventRepository,
        "add",
        lambda *_: (_ for _ in ()).throw(InvalidRecordError("event failed")),
    )
    with pytest.raises(InvalidRecordError, match="event failed"):
        _service(database_path).update_template(
            TEMPLATE_ID, 1, _update_command(title="Değiştir")
        )
    with SQLiteUnitOfWork(database_path) as unit_of_work:
        assert unit_of_work.routine_templates.get(TEMPLATE_ID) == _template()


def test_deactivate_history_exact_retry_and_stale_before_retry(tmp_path: Path) -> None:
    database_path = tmp_path / "deactivate.sqlite3"
    _seed_templates(database_path, _template())
    clock = RepeatingValue(T2)
    ids = UUIDValues()
    service = _service(database_path, clock=clock, uuid_factory=ids)

    inactive = service.deactivate_template(TEMPLATE_ID, 1)
    assert inactive.status is RoutineTemplateStatus.INACTIVE
    assert inactive.deactivated_at == T2
    assert inactive.updated_at == T2
    assert inactive.revision == 2
    history = service.list_template_history(TEMPLATE_ID)
    assert history[0].event_type is RoutineTemplateEventType.DEACTIVATED
    assert history[0].payload == {
        "deactivated_at": T2,
        "from_status": "active",
        "revision": 2,
        "status": "inactive",
    }
    calls = (clock.calls, ids.calls)
    assert service.deactivate_template(TEMPLATE_ID, 2) == inactive
    assert (clock.calls, ids.calls) == calls
    with pytest.raises(RevisionConflict):
        service.deactivate_template(TEMPLATE_ID, 1)


def test_ensure_today_creates_open_occurrence_and_exact_event(tmp_path: Path) -> None:
    database_path = tmp_path / "today.sqlite3"
    template = _template(start_date="2026-07-16")
    _seed_templates(database_path, template)
    service = _service(database_path, clock=RepeatingValue(T2))

    ensured = service.ensure_occurrences(AS_OF_UTC)

    assert len(ensured) == 1
    occurrence = ensured[0]
    assert occurrence.status is RoutineOccurrenceStatus.OPEN
    assert occurrence.revision == 1
    assert occurrence.occurrence_local_date == "2026-07-16"
    history = service.list_occurrence_history(occurrence.routine_occurrence_id)
    assert len(history) == 1
    assert history[0].event_type is RoutineOccurrenceEventType.CREATED
    assert history[0].payload == {
        "occurrence_local_date": "2026-07-16",
        "revision": 1,
        "routine_template_id": TEMPLATE_ID,
        "scheduled_at_utc": "2026-07-16T06:00:00Z",
        "status": "open",
    }


def test_ensure_past_creates_open_then_closes_missed_in_one_transaction(
    tmp_path: Path,
) -> None:
    database_path = tmp_path / "past.sqlite3"
    template = _template(start_date="2026-07-15", end_date="2026-07-15")
    _seed_templates(database_path, template)
    clock = Values((T1, T2))
    service = _service(database_path, clock=clock)

    occurrence = service.ensure_occurrences(AS_OF_UTC)[0]

    assert occurrence.status is RoutineOccurrenceStatus.CLOSED
    assert occurrence.outcome_type is RoutineOccurrenceOutcome.MISSED
    assert occurrence.revision == 2
    assert occurrence.created_at == T1
    assert occurrence.completed_at == T2
    history = service.list_occurrence_history(occurrence.routine_occurrence_id)
    assert [event.sequence for event in history] == [1, 2]
    assert [event.event_type for event in history] == [
        RoutineOccurrenceEventType.CREATED,
        RoutineOccurrenceEventType.MISSED,
    ]
    assert history[1].payload == {
        "from_status": "open",
        "occurrence_local_date": "2026-07-15",
        "outcome_type": "missed",
        "revision": 2,
    }


def test_ensure_uses_exact_seven_day_window_without_future_or_older_dates(
    tmp_path: Path,
) -> None:
    database_path = tmp_path / "seven.sqlite3"
    _seed_templates(database_path, _template(start_date="2020-01-01"))

    ensured = _service(database_path).ensure_occurrences(AS_OF_UTC)

    assert [item.occurrence_local_date for item in ensured] == [
        f"2026-07-{day:02d}" for day in range(10, 17)
    ]
    assert all(
        item.status is RoutineOccurrenceStatus.CLOSED for item in ensured[:-1]
    )
    assert ensured[-1].status is RoutineOccurrenceStatus.OPEN


@pytest.mark.parametrize(
    ("template", "expected_dates"),
    [
        (
            _template(
                start_date="2026-07-12",
                end_date="2026-07-14",
            ),
            ["2026-07-12", "2026-07-13", "2026-07-14"],
        ),
        (
            _template(
                recurrence_type=RoutineRecurrenceType.WEEKDAYS,
                start_date="2026-07-10",
            ),
            [
                "2026-07-10",
                "2026-07-13",
                "2026-07-14",
                "2026-07-15",
                "2026-07-16",
            ],
        ),
        (
            _template(
                recurrence_type=RoutineRecurrenceType.WEEKLY,
                weekdays=frozenset({1, 4}),
                start_date="2026-07-10",
            ),
            ["2026-07-13", "2026-07-16"],
        ),
        (
            _template(
                recurrence_type=RoutineRecurrenceType.MONTHLY,
                month_day=16,
                start_date="2020-01-01",
            ),
            ["2026-07-16"],
        ),
    ],
)
def test_ensure_clips_dates_and_honors_recurrence_types(
    tmp_path: Path, template: RoutineTemplate, expected_dates: list[str]
) -> None:
    database_path = tmp_path / f"clip-{template.recurrence_type.value}.sqlite3"
    _seed_templates(database_path, template)

    ensured = _service(database_path).ensure_occurrences(AS_OF_UTC)

    assert [item.occurrence_local_date for item in ensured] == expected_dates


def test_monthly_31_is_not_shifted_and_inactive_cutoff_is_local_day(
    tmp_path: Path,
) -> None:
    monthly_database = tmp_path / "monthly.sqlite3"
    monthly = _template(
        recurrence_type=RoutineRecurrenceType.MONTHLY,
        month_day=31,
        start_date="2020-01-01",
    )
    _seed_templates(monthly_database, monthly)
    assert _service(monthly_database).ensure_occurrences(AS_OF_UTC) == ()

    inactive_database = tmp_path / "inactive-cutoff.sqlite3"
    inactive = _template(
        start_date="2026-07-10",
        status=RoutineTemplateStatus.INACTIVE,
        deactivated_at="2026-07-14T21:30:00Z",
        updated_at="2026-07-14T21:30:00Z",
        revision=2,
    )
    _seed_templates(inactive_database, inactive)
    ensured = _service(inactive_database).ensure_occurrences(AS_OF_UTC)
    assert [item.occurrence_local_date for item in ensured] == [
        "2026-07-10",
        "2026-07-11",
        "2026-07-12",
        "2026-07-13",
        "2026-07-14",
    ]


def test_second_ensure_is_idempotent_and_consumes_no_clock_or_uuid(
    tmp_path: Path,
) -> None:
    database_path = tmp_path / "idempotent.sqlite3"
    _seed_templates(database_path, _template(start_date="2026-07-15"))
    clock = RepeatingValue(T2)
    ids = UUIDValues()
    service = _service(database_path, clock=clock, uuid_factory=ids)

    first = service.ensure_occurrences(AS_OF_UTC)
    calls = (clock.calls, ids.calls)
    second = service.ensure_occurrences(AS_OF_UTC)

    assert second == first
    assert (clock.calls, ids.calls) == calls
    assert [
        len(service.list_occurrence_history(item.routine_occurrence_id))
        for item in second
    ] == [2, 1]


def test_existing_occurrence_uses_no_clock_uuid_or_event(tmp_path: Path) -> None:
    database_path = tmp_path / "existing.sqlite3"
    template = _template(start_date="2026-07-16")
    existing = _occurrence(template=template)
    _seed_templates(database_path, template)
    _seed_occurrences(database_path, existing)
    clock = RepeatingValue(T2)
    ids = UUIDValues()
    service = _service(database_path, clock=clock, uuid_factory=ids)

    assert service.ensure_occurrences(AS_OF_UTC) == (existing,)
    assert clock.calls == 0
    assert ids.calls == 0
    assert service.list_occurrence_history(OCCURRENCE_ID) == ()


def test_ensure_return_order_is_date_template_and_occurrence_id(tmp_path: Path) -> None:
    database_path = tmp_path / "order.sqlite3"
    first = _template(TEMPLATE_ID, start_date="2026-07-15")
    second = _template(SECOND_TEMPLATE_ID, start_date="2026-07-15")
    _seed_templates(database_path, second, first)

    ensured = _service(database_path).ensure_occurrences(AS_OF_UTC)

    assert [
        (item.occurrence_local_date, item.routine_template_id) for item in ensured
    ] == [
        ("2026-07-15", TEMPLATE_ID),
        ("2026-07-15", SECOND_TEMPLATE_ID),
        ("2026-07-16", TEMPLATE_ID),
        ("2026-07-16", SECOND_TEMPLATE_ID),
    ]


def test_unique_constraint_final_defense_writes_no_event_for_existing_row(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    database_path = tmp_path / "unique-defense.sqlite3"
    template = _template(start_date="2026-07-16")
    existing = _occurrence(template=template)
    _seed_templates(database_path, template)
    _seed_occurrences(database_path, existing)
    monkeypatch.setattr(
        SQLiteRoutineOccurrenceRepository,
        "get_by_template_date",
        lambda *_: (_ for _ in ()).throw(RecordNotFound("routine occurrence", "x")),
    )

    ensured = _service(database_path).ensure_occurrences(AS_OF_UTC)

    assert ensured == (existing,)
    monkeypatch.undo()
    service = RoutineApplicationService(database_path)
    assert service.list_occurrence_history(OCCURRENCE_ID) == ()


def test_ensure_event_and_commit_failures_roll_back_all_occurrences(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    event_database = tmp_path / "ensure-event.sqlite3"
    _seed_templates(event_database, _template(start_date="2026-07-16"))
    monkeypatch.setattr(
        SQLiteRoutineOccurrenceEventRepository,
        "add",
        lambda *_: (_ for _ in ()).throw(InvalidRecordError("event failed")),
    )
    with pytest.raises(InvalidRecordError, match="event failed"):
        _service(event_database).ensure_occurrences(AS_OF_UTC)
    with SQLiteUnitOfWork(event_database) as unit_of_work:
        assert unit_of_work.routine_occurrences.list_for_template(TEMPLATE_ID) == []
    monkeypatch.undo()

    class CommitFailingUnitOfWork(SQLiteUnitOfWork):
        def commit(self) -> None:
            raise OSError("commit failed")

    commit_database = tmp_path / "ensure-commit.sqlite3"
    _seed_templates(commit_database, _template(start_date="2026-07-16"))
    service = _service(
        commit_database,
        uow_factory=lambda: CommitFailingUnitOfWork(commit_database),
    )
    with pytest.raises(OSError, match="commit failed"):
        service.ensure_occurrences(AS_OF_UTC)
    with SQLiteUnitOfWork(commit_database) as unit_of_work:
        assert unit_of_work.routine_occurrences.list_for_template(TEMPLATE_ID) == []


def test_list_occurrence_filters_views_and_does_not_backfill(tmp_path: Path) -> None:
    database_path = tmp_path / "list.sqlite3"
    template = _template(start_date="2026-07-01")
    _seed_templates(database_path, template)
    overdue = _occurrence(
        OCCURRENCE_ID,
        template=template,
        local_date="2026-07-14",
        next_attention_at="2026-07-16T08:59:59Z",
    )
    today = _occurrence(
        SECOND_OCCURRENCE_ID,
        template=template,
        local_date="2026-07-16",
        next_attention_at="2026-07-16T10:00:00Z",
    )
    closed = _occurrence(
        _uuid(50),
        template=template,
        local_date="2026-07-15",
        status=RoutineOccurrenceStatus.CLOSED,
        outcome_type=RoutineOccurrenceOutcome.COMPLETED,
        completed_at=T2,
        revision=2,
    )
    _seed_occurrences(database_path, overdue, today, closed)
    service = _service(database_path)

    assert service.list_occurrences(
        RoutineOccurrenceQuery(status=RoutineOccurrenceStatus.OPEN)
    ) == (overdue, today)
    assert service.list_occurrences(
        RoutineOccurrenceQuery(
            routine_template_id=TEMPLATE_ID,
            view=RoutineOccurrenceView.OVERDUE,
            as_of_utc=AS_OF_UTC,
        )
    ) == (overdue,)
    assert service.list_occurrences(
        RoutineOccurrenceQuery(view=RoutineOccurrenceView.TODAY, as_of_utc=AS_OF_UTC)
    ) == (today,)
    assert service.list_occurrences(
        RoutineOccurrenceQuery(view=RoutineOccurrenceView.UPCOMING, as_of_utc=AS_OF_UTC)
    ) == ()
    assert service.list_occurrence_history(OCCURRENCE_ID) == ()


def test_snooze_noop_stale_closed_and_exact_event(tmp_path: Path) -> None:
    database_path = tmp_path / "snooze.sqlite3"
    template = _template()
    occurrence = _occurrence(template=template)
    _seed_templates(database_path, template)
    _seed_occurrences(database_path, occurrence)
    clock = RepeatingValue(T2)
    ids = UUIDValues()
    service = _service(database_path, clock=clock, uuid_factory=ids)

    snoozed = service.snooze_occurrence(OCCURRENCE_ID, 1, T4)
    assert snoozed.next_attention_at == T4
    assert snoozed.revision == 2
    assert snoozed.scheduled_at_utc == occurrence.scheduled_at_utc
    history = service.list_occurrence_history(OCCURRENCE_ID)
    assert history[0].event_type is RoutineOccurrenceEventType.SNOOZED
    assert history[0].payload == {
        "next_attention_at": T4,
        "previous_next_attention_at": occurrence.next_attention_at,
        "revision": 2,
    }
    calls = (clock.calls, ids.calls)
    assert service.snooze_occurrence(OCCURRENCE_ID, 2, T4) == snoozed
    assert (clock.calls, ids.calls) == calls
    with pytest.raises(RevisionConflict):
        service.snooze_occurrence(OCCURRENCE_ID, 1, T4)

    closed = service.close_occurrence(
        OCCURRENCE_ID,
        2,
        CloseRoutineOccurrence(RoutineOccurrenceOutcome.COMPLETED),
    )
    with pytest.raises(InvalidRecordError, match="open"):
        service.snooze_occurrence(OCCURRENCE_ID, closed.revision, T3)


@pytest.mark.parametrize(
    ("outcome", "event_type"),
    [
        (RoutineOccurrenceOutcome.COMPLETED, RoutineOccurrenceEventType.COMPLETED),
        (RoutineOccurrenceOutcome.NO_WORK, RoutineOccurrenceEventType.NO_WORK),
        (
            RoutineOccurrenceOutcome.NOT_REQUIRED,
            RoutineOccurrenceEventType.NOT_REQUIRED,
        ),
    ],
)
def test_close_three_outcomes_note_normalization_and_event_mapping(
    tmp_path: Path,
    outcome: RoutineOccurrenceOutcome,
    event_type: RoutineOccurrenceEventType,
) -> None:
    database_path = tmp_path / f"close-{outcome.value}.sqlite3"
    template = _template()
    occurrence = _occurrence(template=template, next_attention_at=T4)
    _seed_templates(database_path, template)
    _seed_occurrences(database_path, occurrence)
    service = _service(database_path, clock=RepeatingValue(T2))

    closed = service.close_occurrence(
        OCCURRENCE_ID,
        1,
        CloseRoutineOccurrence(outcome, "  Sonuç notu  "),
    )

    assert closed.status is RoutineOccurrenceStatus.CLOSED
    assert closed.outcome_type is outcome
    assert closed.outcome_note == "Sonuç notu"
    assert closed.completed_at == T2
    assert closed.next_attention_at == T4
    assert closed.scheduled_at_utc == occurrence.scheduled_at_utc
    history = service.list_occurrence_history(OCCURRENCE_ID)
    assert history[0].event_type is event_type
    assert history[0].payload == {
        "from_status": "open",
        "outcome_note": "Sonuç notu",
        "outcome_type": outcome.value,
        "revision": 2,
    }
    with pytest.raises(InvalidRecordError, match="open"):
        service.close_occurrence(
            OCCURRENCE_ID, 2, CloseRoutineOccurrence(outcome)
        )


def test_close_rejects_missed_and_stale_revision() -> None:
    with pytest.raises(ValueError, match="outcome_type"):
        CloseRoutineOccurrence(RoutineOccurrenceOutcome.MISSED)


def test_close_stale_revision_is_rejected_before_clock_or_event(tmp_path: Path) -> None:
    database_path = tmp_path / "close-stale.sqlite3"
    template = _template()
    occurrence = _occurrence(template=template)
    _seed_templates(database_path, template)
    _seed_occurrences(database_path, occurrence)
    clock = RepeatingValue(T2)
    ids = UUIDValues()
    service = _service(database_path, clock=clock, uuid_factory=ids)

    with pytest.raises(RevisionConflict):
        service.close_occurrence(
            OCCURRENCE_ID,
            2,
            CloseRoutineOccurrence(RoutineOccurrenceOutcome.COMPLETED),
        )
    assert clock.calls == 0
    assert ids.calls == 0
    assert service.list_occurrence_history(OCCURRENCE_ID) == ()


def test_reopen_clears_outcome_preserves_snapshot_and_appends_event(
    tmp_path: Path,
) -> None:
    database_path = tmp_path / "reopen.sqlite3"
    template = _template()
    closed = _occurrence(
        template=template,
        status=RoutineOccurrenceStatus.CLOSED,
        outcome_type=RoutineOccurrenceOutcome.NO_WORK,
        outcome_note="Çalışma yoktu",
        completed_at=T2,
        revision=2,
    )
    _seed_templates(database_path, template)
    _seed_occurrences(database_path, closed)
    service = _service(database_path, clock=RepeatingValue(T3))

    reopened = service.reopen_occurrence(OCCURRENCE_ID, 2, T4)

    assert reopened.status is RoutineOccurrenceStatus.OPEN
    assert reopened.outcome_type is None
    assert reopened.outcome_note is None
    assert reopened.completed_at is None
    assert reopened.next_attention_at == T4
    assert reopened.revision == 3
    assert reopened.scheduled_at_utc == closed.scheduled_at_utc
    history = service.list_occurrence_history(OCCURRENCE_ID)
    assert history[0].event_type is RoutineOccurrenceEventType.REOPENED
    assert history[0].payload == {
        "next_attention_at": T4,
        "previous_outcome_type": "no_work",
        "revision": 3,
        "status": "open",
    }
    with pytest.raises(RevisionConflict):
        service.reopen_occurrence(OCCURRENCE_ID, 2, T4)
    with pytest.raises(InvalidRecordError, match="closed"):
        service.reopen_occurrence(OCCURRENCE_ID, 3, T4)


def test_occurrence_mutation_event_and_commit_failures_roll_back(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    event_database = tmp_path / "mutation-event.sqlite3"
    template = _template()
    occurrence = _occurrence(template=template)
    _seed_templates(event_database, template)
    _seed_occurrences(event_database, occurrence)
    monkeypatch.setattr(
        SQLiteRoutineOccurrenceEventRepository,
        "add",
        lambda *_: (_ for _ in ()).throw(InvalidRecordError("event failed")),
    )
    with pytest.raises(InvalidRecordError, match="event failed"):
        _service(event_database).snooze_occurrence(OCCURRENCE_ID, 1, T4)
    with SQLiteUnitOfWork(event_database) as unit_of_work:
        assert unit_of_work.routine_occurrences.get(OCCURRENCE_ID) == occurrence
    monkeypatch.undo()

    reopen_database = tmp_path / "reopen-event.sqlite3"
    closed = replace(
        occurrence,
        status=RoutineOccurrenceStatus.CLOSED,
        outcome_type=RoutineOccurrenceOutcome.NO_WORK,
        completed_at=T2,
        revision=2,
    )
    _seed_templates(reopen_database, template)
    _seed_occurrences(reopen_database, closed)
    monkeypatch.setattr(
        SQLiteRoutineOccurrenceEventRepository,
        "add",
        lambda *_: (_ for _ in ()).throw(InvalidRecordError("event failed")),
    )
    with pytest.raises(InvalidRecordError, match="event failed"):
        _service(reopen_database).reopen_occurrence(OCCURRENCE_ID, 2, T4)
    with SQLiteUnitOfWork(reopen_database) as unit_of_work:
        assert unit_of_work.routine_occurrences.get(OCCURRENCE_ID) == closed
    monkeypatch.undo()

    class CommitFailingUnitOfWork(SQLiteUnitOfWork):
        def commit(self) -> None:
            raise OSError("commit failed")

    commit_database = tmp_path / "mutation-commit.sqlite3"
    _seed_templates(commit_database, template)
    _seed_occurrences(commit_database, occurrence)
    service = _service(
        commit_database,
        uow_factory=lambda: CommitFailingUnitOfWork(commit_database),
    )
    with pytest.raises(OSError, match="commit failed"):
        service.close_occurrence(
            OCCURRENCE_ID,
            1,
            CloseRoutineOccurrence(RoutineOccurrenceOutcome.COMPLETED),
        )
    with SQLiteUnitOfWork(commit_database) as unit_of_work:
        assert unit_of_work.routine_occurrences.get(OCCURRENCE_ID) == occurrence


def test_occurrence_full_history_sequence_through_snooze_close_reopen(
    tmp_path: Path,
) -> None:
    database_path = tmp_path / "history.sqlite3"
    _seed_templates(database_path, _template(start_date="2026-07-16"))
    service = _service(
        database_path,
        clock=Values((T1, T2, T3, T4)),
        uuid_factory=UUIDValues(),
    )
    occurrence = service.ensure_occurrences(AS_OF_UTC)[0]
    occurrence = service.snooze_occurrence(
        occurrence.routine_occurrence_id, 1, T3
    )
    occurrence = service.close_occurrence(
        occurrence.routine_occurrence_id,
        2,
        CloseRoutineOccurrence(RoutineOccurrenceOutcome.COMPLETED),
    )
    service.reopen_occurrence(occurrence.routine_occurrence_id, 3, T4)

    history = service.list_occurrence_history(occurrence.routine_occurrence_id)
    assert [event.sequence for event in history] == [1, 2, 3, 4]
    assert [event.event_type for event in history] == [
        RoutineOccurrenceEventType.CREATED,
        RoutineOccurrenceEventType.SNOOZED,
        RoutineOccurrenceEventType.COMPLETED,
        RoutineOccurrenceEventType.REOPENED,
    ]


def test_schema_version_and_forbidden_repository_apis_remain_unchanged() -> None:
    from app.persistence import SCHEMA_VERSION

    assert SCHEMA_VERSION == 4
    assert not hasattr(SQLiteRoutineOccurrenceRepository, "delete")
    assert not hasattr(SQLiteRoutineOccurrenceEventRepository, "update")
    assert not hasattr(SQLiteRoutineOccurrenceEventRepository, "delete")
    assert not hasattr(SQLiteRoutineOccurrenceEventRepository, "allocate_sequence")
