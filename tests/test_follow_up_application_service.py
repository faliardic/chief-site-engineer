from dataclasses import FrozenInstanceError
from pathlib import Path

import pytest

from app.application import (
    CreateFollowUp,
    FollowUpApplicationService,
    FollowUpQuery,
    FollowUpView,
    ScheduleFollowUp,
    UpdateFollowUp,
)
from app.field_tracking import (
    FollowUpEventType,
    FollowUpItem,
    FollowUpItemType,
    FollowUpOutcome,
    FollowUpStatus,
)
from app.models import FieldObservationRecord
from app.persistence import (
    DuplicateRecordError,
    InvalidRecordError,
    ProjectRecord,
    RecordNotFound,
    RevisionConflict,
    SCHEMA_VERSION,
    SQLiteFollowUpEventRepository,
    SQLiteUnitOfWork,
)


FOLLOW_UP_ID = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"
SECOND_FOLLOW_UP_ID = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"
THIRD_FOLLOW_UP_ID = "cccccccc-cccc-4ccc-8ccc-cccccccccccc"
FOURTH_FOLLOW_UP_ID = "dddddddd-dddd-4ddd-8ddd-dddddddddddd"
FIFTH_FOLLOW_UP_ID = "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee"
SIXTH_FOLLOW_UP_ID = "ffffffff-ffff-4fff-8fff-ffffffffffff"
SEVENTH_FOLLOW_UP_ID = "12345678-1234-4234-8234-123456789abc"
PROJECT_ID = "11111111-1111-4111-8111-111111111111"
SECOND_PROJECT_ID = "22222222-2222-4222-8222-222222222222"
OBSERVATION_ID = "33333333-3333-4333-8333-333333333333"
EVENT_IDS = tuple(
    f"{number:08x}-{number:04x}-4{number:03x}-8{number:03x}-{number:012x}"
    for number in range(1, 20)
)
CREATED_AT = "2026-07-16T07:00:00Z"
UPDATED_AT = "2026-07-16T08:00:00Z"
LATER_AT = "2026-07-16T09:00:00Z"
NEXT_AT = "2026-07-16T12:00:00Z"


class Values:
    def __init__(self, values: tuple[str, ...] | list[str]) -> None:
        self._values = iter(values)

    def __call__(self) -> str:
        return next(self._values)


def _service(
    database_path: Path,
    *,
    ids: tuple[str, ...] = (FOLLOW_UP_ID, *EVENT_IDS),
    times: tuple[str, ...] = (CREATED_AT, UPDATED_AT, LATER_AT, NEXT_AT),
    uow_factory: object | None = None,
) -> FollowUpApplicationService:
    kwargs: dict[str, object] = {}
    if uow_factory is not None:
        kwargs["uow_factory"] = uow_factory
    return FollowUpApplicationService(
        database_path,
        clock=Values(times),
        uuid_factory=Values(ids),
        local_actor="  Şantiye şefi  ",
        **kwargs,  # type: ignore[arg-type]
    )


def _command(**overrides: object) -> UpdateFollowUp:
    values: dict[str, object] = {
        "title": "Kalıp kontrolü",
        "description": None,
        "item_type": FollowUpItemType.ACTION,
        "location": None,
        "related_person": None,
        "is_important": False,
        "condition_text": None,
        "deadline_at": None,
    }
    values.update(overrides)
    return UpdateFollowUp(**values)  # type: ignore[arg-type]


def _item(
    follow_up_id: str,
    *,
    created_at: str,
    status: FollowUpStatus = FollowUpStatus.INBOX,
    project_id: str | None = None,
    observation_id: str | None = None,
    is_important: bool = False,
    next_attention_at: str | None = None,
    deadline_at: str | None = None,
    terminal: FollowUpStatus | None = None,
) -> FollowUpItem:
    values: dict[str, object] = {
        "follow_up_id": follow_up_id,
        "capture_text": f"Takip {follow_up_id[:4]}",
        "title": f"Takip {follow_up_id[:4]}",
        "created_at": created_at,
        "updated_at": created_at,
        "status": status,
        "project_id": project_id,
        "observation_id": observation_id,
        "is_important": is_important,
        "next_attention_at": next_attention_at,
        "deadline_at": deadline_at,
    }
    if terminal == FollowUpStatus.COMPLETED:
        values.update(
            status=FollowUpStatus.COMPLETED,
            outcome_type=FollowUpOutcome.COMPLETED,
            completed_at=created_at,
            next_attention_at=None,
        )
    elif terminal == FollowUpStatus.CANCELLED:
        values.update(
            status=FollowUpStatus.CANCELLED,
            outcome_type=FollowUpOutcome.CANCELLED,
            cancelled_at=created_at,
            next_attention_at=None,
        )
    return FollowUpItem(**values)  # type: ignore[arg-type]


def _seed_items(database_path: Path, *items: FollowUpItem) -> None:
    with SQLiteUnitOfWork(database_path) as unit_of_work:
        for item in items:
            unit_of_work.follow_ups.add(item)
        unit_of_work.commit()


def _seed_projects(database_path: Path) -> None:
    with SQLiteUnitOfWork(database_path) as unit_of_work:
        unit_of_work.projects.add(ProjectRecord(PROJECT_ID, "Birinci", CREATED_AT))
        unit_of_work.projects.add(
            ProjectRecord(SECOND_PROJECT_ID, "İkinci", CREATED_AT)
        )
        unit_of_work.commit()


def test_command_and_query_values_are_immutable_and_normalized() -> None:
    create = CreateFollowUp("  Beton   öncesi\nkontrol  ")
    update = _command(
        title="  Yeni   başlık ", description="   ", location=" A Blok "
    )
    query = FollowUpQuery(status="inbox", view="inbox")  # type: ignore[arg-type]

    assert create.capture_text == "Beton öncesi kontrol"
    assert update.title == "Yeni başlık"
    assert update.description is None
    assert update.location == "A Blok"
    assert query.status is FollowUpStatus.INBOX
    assert query.view is FollowUpView.INBOX
    with pytest.raises(FrozenInstanceError):
        create.capture_text = "değiştir"  # type: ignore[misc]


@pytest.mark.parametrize("actor", ["", "   ", None])
def test_constructor_rejects_empty_local_actor(
    tmp_path: Path, actor: object
) -> None:
    with pytest.raises(ValueError, match="local_actor"):
        FollowUpApplicationService(
            tmp_path / "cse.sqlite3", local_actor=actor  # type: ignore[arg-type]
        )


def test_create_read_list_and_history_round_trip(tmp_path: Path) -> None:
    database_path = tmp_path / "cse.sqlite3"
    service = _service(database_path)

    created = service.create_follow_up(
        CreateFollowUp("  Vinç   bakım belgesini ara  ")
    )

    assert created == FollowUpItem(
        follow_up_id=FOLLOW_UP_ID,
        capture_text="Vinç bakım belgesini ara",
        title="Vinç bakım belgesini ara",
        created_at=CREATED_AT,
        updated_at=CREATED_AT,
    )
    assert service.get_follow_up(FOLLOW_UP_ID) == created
    assert service.list_follow_ups(FollowUpQuery()) == (created,)
    history = service.list_history(FOLLOW_UP_ID)
    assert len(history) == 1
    assert history[0].sequence == 1
    assert history[0].event_type is FollowUpEventType.CREATED
    assert history[0].actor == "Şantiye şefi"
    assert history[0].occurred_at == CREATED_AT
    assert history[0].payload == {"revision": 1, "status": "inbox"}


def test_invalid_injected_uuid_or_clock_is_rejected_without_rows(
    tmp_path: Path,
) -> None:
    database_path = tmp_path / "invalid.sqlite3"
    invalid_uuid = FollowUpApplicationService(
        database_path,
        clock=lambda: CREATED_AT,
        uuid_factory=lambda: "NOT-A-UUID",
    )
    with pytest.raises(ValueError, match="canonical UUID"):
        invalid_uuid.create_follow_up(CreateFollowUp("Kontrol"))

    invalid_clock = FollowUpApplicationService(
        database_path,
        clock=lambda: "2026-07-16T07:00:00+00:00",
        uuid_factory=lambda: FOLLOW_UP_ID,
    )
    with pytest.raises(ValueError, match="ending in Z"):
        invalid_clock.create_follow_up(CreateFollowUp("Kontrol"))
    with SQLiteUnitOfWork(database_path) as unit_of_work:
        assert unit_of_work.follow_ups.list_all() == []


def test_duplicate_create_rolls_back_new_event(tmp_path: Path) -> None:
    database_path = tmp_path / "duplicate.sqlite3"
    original = _service(database_path).create_follow_up(CreateFollowUp("İlk"))
    duplicate = _service(
        database_path, ids=(FOLLOW_UP_ID, EVENT_IDS[5])
    )

    with pytest.raises(DuplicateRecordError):
        duplicate.create_follow_up(CreateFollowUp("İkinci"))

    check = FollowUpApplicationService(database_path)
    assert check.get_follow_up(FOLLOW_UP_ID) == original
    assert len(check.list_history(FOLLOW_UP_ID)) == 1


def test_create_event_failure_and_commit_failure_roll_back_aggregate(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    event_database = tmp_path / "event.sqlite3"
    monkeypatch.setattr(
        SQLiteFollowUpEventRepository,
        "add",
        lambda *_: (_ for _ in ()).throw(InvalidRecordError("event failed")),
    )
    with pytest.raises(InvalidRecordError, match="event failed"):
        _service(event_database).create_follow_up(CreateFollowUp("Kontrol"))
    with SQLiteUnitOfWork(event_database) as unit_of_work:
        assert unit_of_work.follow_ups.list_all() == []

    monkeypatch.undo()

    class CommitFailingUnitOfWork(SQLiteUnitOfWork):
        def commit(self) -> None:
            raise OSError("commit failed")

    commit_database = tmp_path / "commit.sqlite3"
    service = _service(
        commit_database,
        uow_factory=lambda: CommitFailingUnitOfWork(commit_database),
    )
    with pytest.raises(OSError, match="commit failed"):
        service.create_follow_up(CreateFollowUp("Kontrol"))
    with SQLiteUnitOfWork(commit_database) as unit_of_work:
        assert unit_of_work.follow_ups.list_all() == []


def test_query_filters_compose_and_preserve_repository_order(tmp_path: Path) -> None:
    database_path = tmp_path / "queries.sqlite3"
    _seed_projects(database_path)
    with SQLiteUnitOfWork(database_path) as unit_of_work:
        unit_of_work.observations.add(
            FieldObservationRecord(
                observation_id=OBSERVATION_ID,
                project_id=PROJECT_ID,
                observed_at=CREATED_AT,
                location="A Blok",
                category="quality",
                description="Kontrol",
                created_at=CREATED_AT,
                updated_at=CREATED_AT,
            )
        )
        unit_of_work.commit()
    personal = _item(FOLLOW_UP_ID, created_at="2026-07-16T05:00:00Z")
    project_inbox = _item(
        SECOND_FOLLOW_UP_ID,
        created_at="2026-07-16T06:00:00Z",
        project_id=PROJECT_ID,
    )
    observed_active = _item(
        THIRD_FOLLOW_UP_ID,
        created_at="2026-07-16T07:00:00Z",
        status=FollowUpStatus.ACTIVE,
        project_id=PROJECT_ID,
        observation_id=OBSERVATION_ID,
        next_attention_at=NEXT_AT,
    )
    _seed_items(database_path, observed_active, project_inbox, personal)
    service = FollowUpApplicationService(database_path)

    assert service.list_follow_ups(FollowUpQuery()) == (
        personal,
        project_inbox,
        observed_active,
    )
    assert service.list_follow_ups(FollowUpQuery(personal_only=True)) == (
        personal,
    )
    assert service.list_follow_ups(FollowUpQuery(project_id=PROJECT_ID)) == (
        project_inbox,
        observed_active,
    )
    assert service.list_follow_ups(
        FollowUpQuery(
            status=FollowUpStatus.ACTIVE,
            project_id=PROJECT_ID,
            observation_id=OBSERVATION_ID,
        )
    ) == (observed_active,)
    assert service.list_follow_ups(
        FollowUpQuery(status=FollowUpStatus.ACTIVE, view=FollowUpView.INBOX)
    ) == ()


def test_time_views_use_istanbul_day_and_now_composition(tmp_path: Path) -> None:
    database_path = tmp_path / "views.sqlite3"
    overdue = _item(
        FOLLOW_UP_ID,
        created_at="2026-07-15T01:00:00Z",
        status=FollowUpStatus.ACTIVE,
        next_attention_at="2026-07-15T20:59:59Z",
    )
    due_today = _item(
        SECOND_FOLLOW_UP_ID,
        created_at="2026-07-15T02:00:00Z",
        status=FollowUpStatus.WAITING,
        next_attention_at="2026-07-15T21:00:00Z",
    )
    later_today = _item(
        THIRD_FOLLOW_UP_ID,
        created_at="2026-07-15T03:00:00Z",
        status=FollowUpStatus.ACTIVE,
        next_attention_at="2026-07-16T12:00:00Z",
    )
    upcoming = _item(
        FOURTH_FOLLOW_UP_ID,
        created_at="2026-07-15T04:00:00Z",
        status=FollowUpStatus.ACTIVE,
        next_attention_at="2026-07-16T21:00:00Z",
    )
    important_inbox = _item(
        FIFTH_FOLLOW_UP_ID,
        created_at="2026-07-15T05:00:00Z",
        is_important=True,
    )
    unimportant_inbox = _item(
        SEVENTH_FOLLOW_UP_ID,
        created_at="2026-07-15T04:30:00Z",
        is_important=False,
    )
    terminal = _item(
        SIXTH_FOLLOW_UP_ID,
        created_at="2026-07-15T06:00:00Z",
        terminal=FollowUpStatus.COMPLETED,
    )
    _seed_items(
        database_path,
        overdue,
        due_today,
        later_today,
        upcoming,
        unimportant_inbox,
        important_inbox,
        terminal,
    )
    service = FollowUpApplicationService(database_path)
    as_of = "2026-07-15T21:30:00Z"  # 2026-07-16 00:30 Europe/Istanbul

    assert service.list_follow_ups(
        FollowUpQuery(view="overdue", as_of_utc=as_of)  # type: ignore[arg-type]
    ) == (overdue,)
    assert service.list_follow_ups(
        FollowUpQuery(view="today", as_of_utc=as_of)  # type: ignore[arg-type]
    ) == (due_today, later_today)
    assert service.list_follow_ups(
        FollowUpQuery(view="upcoming", as_of_utc=as_of)  # type: ignore[arg-type]
    ) == (upcoming,)
    assert service.list_follow_ups(
        FollowUpQuery(view="now", as_of_utc=as_of)  # type: ignore[arg-type]
    ) == (overdue, due_today, important_inbox)
    assert service.list_follow_ups(FollowUpQuery(view="inbox")) == (  # type: ignore[arg-type]
        unimportant_inbox,
        important_inbox,
    )


@pytest.mark.parametrize("view", ["overdue", "today", "upcoming", "now"])
def test_timed_query_requires_canonical_as_of(view: str) -> None:
    with pytest.raises(ValueError, match="requires as_of_utc"):
        FollowUpQuery(view=view)  # type: ignore[arg-type]
    with pytest.raises(ValueError, match="ending in Z"):
        FollowUpQuery(
            view=view, as_of_utc="2026-07-16T00:00:00+00:00"  # type: ignore[arg-type]
        )


def test_query_rejects_personal_project_combination_and_invalid_ids() -> None:
    with pytest.raises(ValueError, match="cannot be used together"):
        FollowUpQuery(project_id=PROJECT_ID, personal_only=True)
    with pytest.raises(ValueError, match="canonical UUID"):
        FollowUpQuery(observation_id="not-an-id")


def test_update_details_changes_only_allowlist_and_exact_event(tmp_path: Path) -> None:
    database_path = tmp_path / "update.sqlite3"
    service = _service(database_path)
    created = service.create_follow_up(CreateFollowUp("İlk yakalama kanıtı"))
    updated = service.update_details(
        FOLLOW_UP_ID,
        1,
        _command(
            title="  Yeni   başlık ",
            description=" Ayrıntı ",
            item_type=FollowUpItemType.RECHECK,
            location=" B Blok ",
            related_person=" Ahmet ",
            is_important=True,
            condition_text=" Beton öncesi ",
            deadline_at=NEXT_AT,
        ),
    )

    assert updated.revision == 2
    assert updated.updated_at == UPDATED_AT
    assert updated.capture_text == created.capture_text
    assert updated.status == created.status
    assert updated.project_id == created.project_id
    assert updated.observation_id == created.observation_id
    assert updated.next_attention_at == created.next_attention_at
    assert updated.created_at == created.created_at
    assert updated.title == "Yeni başlık"
    assert updated.description == "Ayrıntı"
    history = service.list_history(FOLLOW_UP_ID)
    assert [event.sequence for event in history] == [1, 2]
    assert history[-1].event_type is FollowUpEventType.DETAILS_UPDATED
    assert history[-1].payload == {
        "changed_fields": [
            "condition_text",
            "deadline_at",
            "description",
            "is_important",
            "item_type",
            "location",
            "related_person",
            "title",
        ],
        "revision": 2,
    }
    assert "capture_text" not in history[-1].payload["changed_fields"]


def test_update_details_no_op_and_stale_revision_leave_state_unchanged(
    tmp_path: Path,
) -> None:
    database_path = tmp_path / "update-noop.sqlite3"
    service = _service(database_path)
    created = service.create_follow_up(CreateFollowUp("Kalıp kontrolü"))
    same = service.update_details(FOLLOW_UP_ID, 1, _command())

    assert same == created
    assert len(service.list_history(FOLLOW_UP_ID)) == 1
    with pytest.raises(RevisionConflict):
        service.update_details(
            FOLLOW_UP_ID, 99, _command(title="Yeni başlık")
        )
    assert service.get_follow_up(FOLLOW_UP_ID) == created
    assert len(service.list_history(FOLLOW_UP_ID)) == 1


@pytest.mark.parametrize(
    "overrides",
    [
        {"title": "   "},
        {"item_type": "unsupported"},
        {"is_important": 1},
        {"deadline_at": "2026-07-16T12:00:00+00:00"},
    ],
)
def test_update_command_rejects_invalid_title_type_bool_or_timestamp(
    overrides: dict[str, object],
) -> None:
    with pytest.raises(ValueError):
        _command(**overrides)


@pytest.mark.parametrize("target", [FollowUpStatus.ACTIVE, FollowUpStatus.WAITING])
def test_first_schedule_supports_active_and_waiting(
    tmp_path: Path, target: FollowUpStatus
) -> None:
    database_path = tmp_path / f"schedule-{target.value}.sqlite3"
    service = _service(database_path)
    service.create_follow_up(CreateFollowUp("Planla"))

    scheduled = service.schedule(
        FOLLOW_UP_ID, 1, ScheduleFollowUp(NEXT_AT, target)
    )

    assert scheduled.status is target
    assert scheduled.next_attention_at == NEXT_AT
    assert scheduled.revision == 2
    event = service.list_history(FOLLOW_UP_ID)[-1]
    assert event.event_type is FollowUpEventType.SCHEDULED
    assert event.payload == {
        "from_status": "inbox",
        "next_attention_at": NEXT_AT,
        "previous_next_attention_at": None,
        "revision": 2,
        "status": target.value,
    }


def test_reschedule_changes_status_and_attention_then_no_op(tmp_path: Path) -> None:
    database_path = tmp_path / "reschedule.sqlite3"
    service = _service(database_path)
    service.create_follow_up(CreateFollowUp("Planla"))
    first = service.schedule(
        FOLLOW_UP_ID, 1, ScheduleFollowUp(NEXT_AT, FollowUpStatus.ACTIVE)
    )
    rescheduled = service.schedule(
        FOLLOW_UP_ID,
        2,
        ScheduleFollowUp(LATER_AT, FollowUpStatus.WAITING),
    )
    same = service.schedule(
        FOLLOW_UP_ID,
        3,
        ScheduleFollowUp(LATER_AT, FollowUpStatus.WAITING),
    )

    assert first.revision == 2
    assert rescheduled.revision == same.revision == 3
    assert rescheduled.updated_at == LATER_AT
    assert [event.event_type for event in service.list_history(FOLLOW_UP_ID)] == [
        FollowUpEventType.CREATED,
        FollowUpEventType.SCHEDULED,
        FollowUpEventType.RESCHEDULED,
    ]


def test_schedule_rejects_invalid_input_terminal_and_stale_revision(
    tmp_path: Path,
) -> None:
    with pytest.raises(ValueError, match="target_status"):
        ScheduleFollowUp(NEXT_AT, FollowUpStatus.INBOX)
    with pytest.raises(ValueError, match="ending in Z"):
        ScheduleFollowUp(
            "2026-07-16T12:00:00+00:00", FollowUpStatus.ACTIVE
        )

    database_path = tmp_path / "schedule-invalid.sqlite3"
    terminal = _item(
        FOLLOW_UP_ID,
        created_at=CREATED_AT,
        terminal=FollowUpStatus.COMPLETED,
    )
    _seed_items(database_path, terminal)
    service = FollowUpApplicationService(database_path)
    with pytest.raises(InvalidRecordError, match="terminal"):
        service.schedule(
            FOLLOW_UP_ID, 1, ScheduleFollowUp(NEXT_AT, FollowUpStatus.ACTIVE)
        )

    open_database = tmp_path / "schedule-stale.sqlite3"
    open_service = _service(open_database)
    created = open_service.create_follow_up(CreateFollowUp("Planla"))
    with pytest.raises(RevisionConflict):
        open_service.schedule(
            FOLLOW_UP_ID, 2, ScheduleFollowUp(NEXT_AT, FollowUpStatus.ACTIVE)
        )
    assert open_service.get_follow_up(FOLLOW_UP_ID) == created
    assert len(open_service.list_history(FOLLOW_UP_ID)) == 1


@pytest.mark.parametrize("initial", [FollowUpStatus.ACTIVE, FollowUpStatus.WAITING])
def test_move_to_inbox_clears_attention_and_preserves_deadline(
    tmp_path: Path, initial: FollowUpStatus
) -> None:
    database_path = tmp_path / f"inbox-{initial.value}.sqlite3"
    service = _service(database_path)
    service.create_follow_up(CreateFollowUp("Planı kaldır"))
    detailed = service.update_details(
        FOLLOW_UP_ID, 1, _command(title="Planı kaldır", deadline_at=NEXT_AT)
    )
    planned = service.schedule(
        FOLLOW_UP_ID,
        detailed.revision,
        ScheduleFollowUp(LATER_AT, initial),
    )
    moved = service.move_to_inbox(FOLLOW_UP_ID, planned.revision)

    assert moved.status is FollowUpStatus.INBOX
    assert moved.next_attention_at is None
    assert moved.deadline_at == NEXT_AT
    assert moved.revision == planned.revision + 1
    event = service.list_history(FOLLOW_UP_ID)[-1]
    assert event.event_type is FollowUpEventType.MOVED_TO_INBOX
    assert event.payload == {
        "from_status": initial.value,
        "previous_next_attention_at": LATER_AT,
        "revision": moved.revision,
    }


def test_move_to_inbox_no_op_terminal_and_stale_boundaries(tmp_path: Path) -> None:
    database_path = tmp_path / "inbox-boundaries.sqlite3"
    service = _service(database_path)
    created = service.create_follow_up(CreateFollowUp("Kutuda"))
    assert service.move_to_inbox(FOLLOW_UP_ID, 1) == created
    assert len(service.list_history(FOLLOW_UP_ID)) == 1
    with pytest.raises(RevisionConflict):
        service.move_to_inbox(FOLLOW_UP_ID, 2)

    terminal_database = tmp_path / "inbox-terminal.sqlite3"
    _seed_items(
        terminal_database,
        _item(
            FOLLOW_UP_ID,
            created_at=CREATED_AT,
            terminal=FollowUpStatus.CANCELLED,
        ),
    )
    with pytest.raises(InvalidRecordError, match="active or waiting"):
        FollowUpApplicationService(terminal_database).move_to_inbox(
            FOLLOW_UP_ID, 1
        )


def test_set_project_add_change_remove_and_payloads(tmp_path: Path) -> None:
    database_path = tmp_path / "project.sqlite3"
    _seed_projects(database_path)
    service = _service(database_path)
    service.create_follow_up(CreateFollowUp("Projeyi seç"))

    added = service.set_project(FOLLOW_UP_ID, 1, PROJECT_ID)
    changed = service.set_project(FOLLOW_UP_ID, 2, SECOND_PROJECT_ID)
    removed = service.set_project(FOLLOW_UP_ID, 3, None)

    assert [added.project_id, changed.project_id, removed.project_id] == [
        PROJECT_ID,
        SECOND_PROJECT_ID,
        None,
    ]
    assert [added.revision, changed.revision, removed.revision] == [2, 3, 4]
    events = service.list_history(FOLLOW_UP_ID)
    assert [event.sequence for event in events] == [1, 2, 3, 4]
    assert events[-1].payload == {
        "from_project_id": SECOND_PROJECT_ID,
        "project_id": None,
        "revision": 4,
    }
    assert events[-1].payload_json.endswith('"project_id":null,"revision":4}')


def test_set_project_missing_same_observation_and_stale_boundaries(
    tmp_path: Path,
) -> None:
    database_path = tmp_path / "project-boundaries.sqlite3"
    _seed_projects(database_path)
    service = _service(database_path)
    created = service.create_follow_up(CreateFollowUp("Projeyi seç"))
    with pytest.raises(RecordNotFound):
        service.set_project(
            FOLLOW_UP_ID,
            1,
            "99999999-9999-4999-8999-999999999999",
        )
    assert service.get_follow_up(FOLLOW_UP_ID) == created
    assert service.set_project(FOLLOW_UP_ID, 1, None) == created
    assert len(service.list_history(FOLLOW_UP_ID)) == 1
    with pytest.raises(RevisionConflict):
        service.set_project(FOLLOW_UP_ID, 2, PROJECT_ID)

    linked_database = tmp_path / "linked.sqlite3"
    with SQLiteUnitOfWork(linked_database) as unit_of_work:
        unit_of_work.projects.add(ProjectRecord(PROJECT_ID, "Birinci", CREATED_AT))
        unit_of_work.projects.add(
            ProjectRecord(SECOND_PROJECT_ID, "İkinci", CREATED_AT)
        )
        unit_of_work.observations.add(
            FieldObservationRecord(
                observation_id=OBSERVATION_ID,
                project_id=PROJECT_ID,
                observed_at=CREATED_AT,
                location="A Blok",
                category="quality",
                description="Kontrol",
                created_at=CREATED_AT,
                updated_at=CREATED_AT,
            )
        )
        linked = _item(
            FOLLOW_UP_ID,
            created_at=CREATED_AT,
            project_id=PROJECT_ID,
            observation_id=OBSERVATION_ID,
        )
        unit_of_work.follow_ups.add(linked)
        unit_of_work.commit()

    linked_service = FollowUpApplicationService(linked_database)
    assert linked_service.set_project(FOLLOW_UP_ID, 1, PROJECT_ID) == linked
    for project_id in (None, SECOND_PROJECT_ID):
        with pytest.raises(InvalidRecordError, match="observation-linked"):
            linked_service.set_project(FOLLOW_UP_ID, 1, project_id)
    assert linked_service.get_follow_up(FOLLOW_UP_ID) == linked


@pytest.mark.parametrize("operation", ["update", "schedule", "inbox", "project"])
def test_event_failure_rolls_back_each_real_mutation(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
    operation: str,
) -> None:
    database_path = tmp_path / f"rollback-{operation}.sqlite3"
    if operation == "project":
        _seed_projects(database_path)
    service = _service(database_path)
    service.create_follow_up(CreateFollowUp("Atomik kayıt"))
    if operation == "inbox":
        service.schedule(
            FOLLOW_UP_ID, 1, ScheduleFollowUp(NEXT_AT, FollowUpStatus.ACTIVE)
        )
    before = service.get_follow_up(FOLLOW_UP_ID)
    history_before = service.list_history(FOLLOW_UP_ID)
    monkeypatch.setattr(
        SQLiteFollowUpEventRepository,
        "add",
        lambda *_: (_ for _ in ()).throw(InvalidRecordError("event failed")),
    )

    with pytest.raises(InvalidRecordError, match="event failed"):
        if operation == "update":
            service.update_details(
                FOLLOW_UP_ID,
                before.revision,
                _command(title="Değişen başlık"),
            )
        elif operation == "schedule":
            service.schedule(
                FOLLOW_UP_ID,
                before.revision,
                ScheduleFollowUp(NEXT_AT, FollowUpStatus.WAITING),
            )
        elif operation == "inbox":
            service.move_to_inbox(FOLLOW_UP_ID, before.revision)
        else:
            service.set_project(FOLLOW_UP_ID, before.revision, PROJECT_ID)

    assert service.get_follow_up(FOLLOW_UP_ID) == before
    assert service.list_history(FOLLOW_UP_ID) == history_before


def test_get_and_history_reject_missing_or_noncanonical_identity(
    tmp_path: Path,
) -> None:
    service = FollowUpApplicationService(tmp_path / "missing.sqlite3")
    with pytest.raises(RecordNotFound):
        service.get_follow_up(FOLLOW_UP_ID)
    with pytest.raises(RecordNotFound):
        service.list_history(FOLLOW_UP_ID)
    with pytest.raises(ValueError, match="canonical UUID"):
        service.get_follow_up("not-an-id")


def test_repository_ports_and_schema_are_not_expanded(tmp_path: Path) -> None:
    assert SCHEMA_VERSION == 4
    with SQLiteUnitOfWork(tmp_path / "ports.sqlite3") as unit_of_work:
        assert not hasattr(unit_of_work.follow_ups, "delete")
        assert not hasattr(unit_of_work.follow_up_events, "update")
        assert not hasattr(unit_of_work.follow_up_events, "delete")
        assert not hasattr(unit_of_work.follow_up_events, "allocate_sequence")
