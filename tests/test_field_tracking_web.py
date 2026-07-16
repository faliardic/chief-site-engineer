import io
import zipfile
from pathlib import Path

import pytest

from app.application import (
    FollowUpQuery,
    RoutineOccurrenceQuery,
    RoutineTemplateQuery,
)
from app.field_tracking import (
    FollowUpStatus,
    RoutineOccurrenceOutcome,
    RoutineOccurrenceStatus,
    RoutineRecurrenceType,
    RoutineTemplateStatus,
)
from app.persistence import SCHEMA_VERSION
from app.web import create_app


NOW_UTC = "2026-07-16T09:00:00Z"


def _uuid(number: int) -> str:
    return (
        f"{number:08x}-{number:04x}-4{number % 4096:03x}-"
        f"8{number % 4096:03x}-{number:012x}"
    )


class UUIDSequence:
    def __init__(self, start: int) -> None:
        self.next_value = start

    def __call__(self) -> str:
        value = _uuid(self.next_value)
        self.next_value += 1
        return value


def _app(data_root: Path, *, now_utc: str = NOW_UTC):
    app = create_app(data_root)
    app.config.update(
        TESTING=True,
        CSE_NOW_UTC_FACTORY=lambda: now_utc,
        CSE_FOLLOW_UP_ID_FACTORY=UUIDSequence(1000),
        CSE_ROUTINE_ID_FACTORY=UUIDSequence(5000),
        CSE_BACKUP_ID_FACTORY=UUIDSequence(9000),
    )
    return app


def _create_follow_up(client, text: str = "Kalıp kotunu tekrar kontrol et") -> str:
    response = client.post(
        "/follow-ups",
        data={"capture_text": text, "return_to": "today"},
    )
    assert response.status_code == 302
    return response.headers["Location"].split("/follow-ups/", 1)[1].split("?", 1)[0]


def _create_routine(client, **overrides: object) -> str:
    data: dict[str, object] = {
        "title": "Puantajı tamamla",
        "description": "Gün sonu puantaj kontrolü",
        "project_id": "",
        "recurrence_type": "weekdays",
        "local_time": "17:00",
        "start_date": "2026-07-16",
        "end_date": "",
        "month_day": "",
        "is_important": "1",
    }
    data.update(overrides)
    response = client.post("/routines/new", data=data)
    assert response.status_code == 302
    return response.headers["Location"].split("/routines/", 1)[1].split("?", 1)[0]


def test_navigation_empty_states_shared_database_and_responsive_css(
    tmp_path: Path,
) -> None:
    app = _app(tmp_path)
    client = app.test_client()

    root = client.get("/")
    assert root.status_code == 302
    assert root.headers["Location"] == "/today"

    today = client.get("/today")
    text = today.get_data(as_text=True)
    assert today.status_code == 200
    assert all(label in text for label in ("Bugün", "Unutma Kutusu", "Rutinler", "Gözlemler"))
    assert "Şimdi ilgilen" in text
    assert "Geciken açık kayıt yok." in text
    assert "Bugün için açık rutin yok." in text
    assert 'aria-current="page"' in text
    assert 'name="viewport"' in text

    expected_database = tmp_path / "cse.sqlite3"
    assert app.config["CSE_FOLLOW_UP_SERVICE"].database_path == expected_database
    assert app.config["CSE_ROUTINE_SERVICE"].database_path == expected_database
    assert app.config["CSE_SERVICE"].database_path == expected_database
    assert SCHEMA_VERSION == 4

    css = client.get("/static/app.css").get_data(as_text=True)
    assert "min-height: 44px" in css
    assert ".dashboard-grid" in css
    assert "@media (max-width: 640px)" in css
    assert ":focus-visible" in css


def test_quick_capture_normalizes_escapes_prg_and_keeps_event_history(
    tmp_path: Path,
) -> None:
    app = _app(tmp_path)
    client = app.test_client()

    invalid = client.post(
        "/follow-ups",
        data={"capture_text": "   ", "return_to": "inbox"},
    )
    assert invalid.status_code == 400
    assert "Başlık boş bırakılamaz" in invalid.get_data(as_text=True)
    assert 'value="   "' in invalid.get_data(as_text=True)

    follow_up_id = _create_follow_up(
        client, "  Kalıp   kotunu <script>alert(1)</script> tekrar kontrol et  "
    )
    stored = app.config["CSE_FOLLOW_UP_SERVICE"].get_follow_up(follow_up_id)
    assert stored.capture_text == "Kalıp kotunu <script>alert(1)</script> tekrar kontrol et"
    assert stored.title == stored.capture_text
    assert stored.status == FollowUpStatus.INBOX

    detail_path = f"/follow-ups/{follow_up_id}?saved=created"
    first_get = client.get(detail_path)
    second_get = client.get(detail_path)
    text = first_get.get_data(as_text=True)
    assert first_get.status_code == second_get.status_code == 200
    assert "Kayıt Unutma Kutusu" in text
    assert "eklendi." in text
    assert "Takip yakalandı" in text
    assert "İlk yakalanan not" in text
    assert "<script>" not in text
    assert "&lt;script&gt;" in text
    assert "follow_up.created" not in text
    assert len(app.config["CSE_FOLLOW_UP_SERVICE"].list_follow_ups(FollowUpQuery())) == 1
    assert len(app.config["CSE_FOLLOW_UP_SERVICE"].list_history(follow_up_id)) == 1


def test_follow_up_full_lifecycle_project_time_conversion_and_history(
    tmp_path: Path,
) -> None:
    app = _app(tmp_path)
    client = app.test_client()
    client.post("/projects/new", data={"name": "A Blok Projesi"})
    project_id = app.config["CSE_SERVICE"].list_projects()[0].project_id
    follow_up_id = _create_follow_up(client)
    base = f"/follow-ups/{follow_up_id}"

    details = client.post(
        f"{base}/details",
        data={
            "expected_revision": "1",
            "title": "Kalıp kotunu tekrar kontrol et",
            "description": "Aks 4 ölçümünü doğrula",
            "item_type": "recheck",
            "location": "A Blok",
            "related_person": "Ölçüm ekibi",
            "condition_text": "Beton öncesi",
            "deadline_at": "2026-07-17T08:30",
            "is_important": "1",
        },
    )
    assert details.status_code == 302
    assert client.post(
        f"{base}/project",
        data={"expected_revision": "2", "project_id": project_id},
    ).status_code == 302
    assert client.post(
        f"{base}/schedule",
        data={
            "expected_revision": "3",
            "next_attention_at": "2026-07-16T15:30",
            "target_status": "active",
        },
    ).status_code == 302
    assert client.post(
        f"{base}/waiting",
        data={
            "expected_revision": "4",
            "next_attention_at": "2026-07-16T16:30",
            "related_person": "Harita mühendisi",
            "condition_text": "Ölçüm föyü gelince",
        },
    ).status_code == 302
    assert client.post(
        f"{base}/move-to-inbox", data={"expected_revision": "5"}
    ).status_code == 302
    assert client.post(
        f"{base}/complete",
        data={
            "expected_revision": "6",
            "outcome_type": "completed",
            "outcome_note": "Kot doğrulandı",
        },
    ).status_code == 302
    assert client.post(
        f"{base}/reopen",
        data={"expected_revision": "7", "next_attention_at": "2026-07-17T09:00"},
    ).status_code == 302
    assert client.post(
        f"{base}/cancel",
        data={"expected_revision": "8", "outcome_note": "Plan değişti"},
    ).status_code == 302
    assert client.post(
        f"{base}/reopen",
        data={"expected_revision": "9", "next_attention_at": ""},
    ).status_code == 302

    item = app.config["CSE_FOLLOW_UP_SERVICE"].get_follow_up(follow_up_id)
    assert item.project_id == project_id
    assert item.is_important is True
    assert item.deadline_at == "2026-07-17T05:30:00Z"
    assert item.status == FollowUpStatus.INBOX
    assert item.next_attention_at is None
    assert item.capture_text == "Kalıp kotunu tekrar kontrol et"
    assert item.revision == 10

    history = app.config["CSE_FOLLOW_UP_SERVICE"].list_history(follow_up_id)
    assert [event.sequence for event in history] == list(range(1, 11))
    assert history[3].payload["next_attention_at"] == "2026-07-16T12:30:00Z"
    page = client.get(base).get_data(as_text=True)
    assert "A Blok Projesi" in page
    assert "Takip yeniden açıldı" in page
    assert "16.07.2026 15:30" in page
    assert "payload_json" not in page
    assert "follow_up." not in page


def test_follow_up_validation_conflict_and_missing_records_are_safe(
    tmp_path: Path,
) -> None:
    app = _app(tmp_path)
    client = app.test_client()
    follow_up_id = _create_follow_up(client)
    base = f"/follow-ups/{follow_up_id}"

    invalid = client.post(
        f"{base}/details",
        data={
            "expected_revision": "1",
            "title": " ",
            "description": "Korunacak açıklama",
            "item_type": "action",
            "location": "Korunacak konum",
        },
    )
    assert invalid.status_code == 400
    invalid_text = invalid.get_data(as_text=True)
    assert "Başlık boş bırakılamaz" in invalid_text
    assert "Korunacak açıklama" in invalid_text
    assert "Korunacak konum" in invalid_text
    assert "Traceback" not in invalid_text

    updated = client.post(
        f"{base}/details",
        data={
            "expected_revision": "1",
            "title": "Güncel başlık",
            "description": "",
            "item_type": "action",
            "location": "",
        },
    )
    assert updated.status_code == 302
    stale = client.post(
        f"{base}/project",
        data={"expected_revision": "1", "project_id": ""},
    )
    assert stale.status_code == 409
    assert "sayfayı yenileyin" in stale.get_data(as_text=True)
    assert client.get("/follow-ups/not-a-uuid").status_code == 404
    assert client.get(f"/follow-ups/{_uuid(777777)}").status_code == 404


def test_today_uses_istanbul_day_boundary_and_now_composition(tmp_path: Path) -> None:
    app = _app(tmp_path, now_utc="2026-07-16T20:30:00Z")
    client = app.test_client()

    important_id = _create_follow_up(client, "Önemli kutu kaydı")
    client.post(
        f"/follow-ups/{important_id}/details",
        data={
            "expected_revision": "1",
            "title": "Önemli kutu kaydı",
            "description": "",
            "item_type": "action",
            "location": "",
            "is_important": "1",
        },
    )
    due_id = _create_follow_up(client, "Bugün zamanı gelen")
    client.post(
        f"/follow-ups/{due_id}/schedule",
        data={
            "expected_revision": "1",
            "next_attention_at": "2026-07-16T23:15",
            "target_status": "active",
        },
    )
    future_id = _create_follow_up(client, "Yerel yarın kaydı")
    client.post(
        f"/follow-ups/{future_id}/schedule",
        data={
            "expected_revision": "1",
            "next_attention_at": "2026-07-17T00:15",
            "target_status": "active",
        },
    )
    overdue_id = _create_follow_up(client, "Dünden geciken kayıt")
    client.post(
        f"/follow-ups/{overdue_id}/schedule",
        data={
            "expected_revision": "1",
            "next_attention_at": "2026-07-15T23:00",
            "target_status": "active",
        },
    )
    _create_routine(
        client,
        title="Sabah saha turu",
        recurrence_type="daily",
        local_time="08:00",
    )

    page = client.get("/today").get_data(as_text=True)
    assert "Önemli kutu kaydı" in page
    assert "Bugün zamanı gelen" in page
    assert "Yerel yarın kaydı" not in page
    assert "Dünden geciken kayıt" in page
    assert "Geciken takip" in page
    assert "Sabah saha turu" in page
    assert "Geciken rutin" in page
    assert "16.07.2026 23:15" in page
    future = app.config["CSE_FOLLOW_UP_SERVICE"].get_follow_up(future_id)
    assert future.next_attention_at == "2026-07-16T21:15:00Z"


def test_first_pc_acceptance_flow_survives_restart_and_keeps_export_scope(
    tmp_path: Path,
) -> None:
    first = _app(tmp_path)
    first.config["CSE_SERVICE"]._clock = lambda: NOW_UTC
    client = first.test_client()

    client.post("/projects/new", data={"name": "PC Kabul Projesi"})
    project_id = first.config["CSE_SERVICE"].list_projects()[0].project_id
    follow_up_id = _create_follow_up(client, "Kalıp kotunu tekrar kontrol et")
    assert "Kalıp kotunu tekrar kontrol et" in client.get(
        "/follow-ups/inbox"
    ).get_data(as_text=True)
    assert "İlk yakalanan not" in client.get(
        f"/follow-ups/{follow_up_id}"
    ).get_data(as_text=True)

    assert client.post(
        f"/follow-ups/{follow_up_id}/details",
        data={
            "expected_revision": "1",
            "title": "Kalıp kotunu tekrar kontrol et",
            "description": "Kabul akışı",
            "item_type": "recheck",
            "location": "Kalıp alanı",
            "is_important": "1",
        },
    ).status_code == 302
    assert client.post(
        f"/follow-ups/{follow_up_id}/project",
        data={"expected_revision": "2", "project_id": project_id},
    ).status_code == 302
    assert client.post(
        f"/follow-ups/{follow_up_id}/schedule",
        data={
            "expected_revision": "3",
            "next_attention_at": "2026-07-16T13:00",
            "target_status": "active",
        },
    ).status_code == 302
    assert "Kalıp kotunu tekrar kontrol et" in client.get(
        "/today"
    ).get_data(as_text=True)
    assert client.post(
        f"/follow-ups/{follow_up_id}/waiting",
        data={
            "expected_revision": "4",
            "next_attention_at": "2026-07-16T14:00",
            "related_person": "Harita ekibi",
            "condition_text": "Ölçüm gelince",
        },
    ).status_code == 302
    waiting_page = client.get(f"/follow-ups/{follow_up_id}").get_data(as_text=True)
    assert "Harita ekibi" in waiting_page
    assert "Ölçüm gelince" in waiting_page
    assert client.post(
        f"/follow-ups/{follow_up_id}/complete",
        data={
            "expected_revision": "5",
            "outcome_type": "completed",
            "outcome_note": "Kontrol edildi",
        },
    ).status_code == 302
    assert f"/follow-ups/{follow_up_id}" not in client.get(
        "/today"
    ).get_data(as_text=True)
    assert client.post(
        f"/follow-ups/{follow_up_id}/reopen",
        data={"expected_revision": "6", "next_attention_at": ""},
    ).status_code == 302

    routine_id = _create_routine(client)
    first_today = client.get("/today")
    second_today = client.get("/today")
    assert "Puantajı tamamla" in first_today.get_data(as_text=True)
    assert "Puantajı tamamla" in second_today.get_data(as_text=True)
    routine_service = first.config["CSE_ROUTINE_SERVICE"]
    occurrences = routine_service.list_occurrences(
        RoutineOccurrenceQuery(routine_template_id=routine_id)
    )
    assert len(occurrences) == 1
    occurrence = occurrences[0]
    assert len(routine_service.list_occurrence_history(occurrence.routine_occurrence_id)) == 1
    assert client.post(
        f"/routine-occurrences/{occurrence.routine_occurrence_id}/close",
        data={
            "expected_revision": "1",
            "outcome_type": "no_work",
            "outcome_note": "Bugün ekip yoktu",
        },
    ).status_code == 302

    second = _app(tmp_path)
    second.config["CSE_SERVICE"]._clock = lambda: NOW_UTC
    reopened = second.test_client()
    reopened_follow_up = second.config["CSE_FOLLOW_UP_SERVICE"].get_follow_up(
        follow_up_id
    )
    reopened_occurrence = second.config["CSE_ROUTINE_SERVICE"].list_occurrences(
        RoutineOccurrenceQuery(routine_template_id=routine_id)
    )[0]
    assert reopened_follow_up.revision == 7
    assert len(second.config["CSE_FOLLOW_UP_SERVICE"].list_history(follow_up_id)) == 7
    assert reopened_occurrence.status == RoutineOccurrenceStatus.CLOSED
    assert reopened_occurrence.outcome_type == RoutineOccurrenceOutcome.NO_WORK
    assert len(
        second.config["CSE_ROUTINE_SERVICE"].list_occurrence_history(
            reopened_occurrence.routine_occurrence_id
        )
    ) == 2

    observation = reopened.post(
        "/observations/new",
        data={
            "project_id": project_id,
            "location": "A Blok",
            "category": "Kalite",
            "description": "Kabul gözlemi",
        },
    )
    assert observation.status_code == 302
    assert "Kabul gözlemi" in reopened.get(
        observation.headers["Location"]
    ).get_data(as_text=True)

    backup = reopened.post("/backups")
    assert backup.status_code == 302
    assert reopened.get(backup.headers["Location"]).status_code == 200
    export = reopened.post("/exports/daily", data={"local_date": "2026-07-16"})
    assert export.status_code == 302
    export_download = reopened.get(export.headers["Location"])
    assert export_download.status_code == 200
    with zipfile.ZipFile(io.BytesIO(export_download.data)) as archive:
        exported_content = b"\n".join(
            archive.read(name) for name in archive.namelist() if not name.endswith("/")
        )
    assert "Kabul gözlemi".encode() in exported_content
    assert "Kalıp kotunu tekrar kontrol et".encode() not in exported_content
    assert "Puantajı tamamla".encode() not in exported_content


@pytest.mark.parametrize(
    ("recurrence", "weekdays", "month_day", "expected_weekdays", "expected_month_day"),
    [
        ("daily", [], "", frozenset(), None),
        ("weekdays", [], "", frozenset(), None),
        ("weekly", ["1", "4"], "", frozenset({1, 4}), None),
        ("monthly", [], "16", frozenset(), 16),
    ],
)
def test_routine_creation_supports_every_recurrence_shape(
    tmp_path: Path,
    recurrence: str,
    weekdays: list[str],
    month_day: str,
    expected_weekdays: frozenset[int],
    expected_month_day: int | None,
) -> None:
    app = _app(tmp_path)
    client = app.test_client()
    routine_id = _create_routine(
        client,
        recurrence_type=recurrence,
        weekdays=weekdays,
        month_day=month_day,
    )

    template = app.config["CSE_ROUTINE_SERVICE"].get_template(routine_id)
    assert template.recurrence_type == RoutineRecurrenceType(recurrence)
    assert template.weekdays == expected_weekdays
    assert template.month_day == expected_month_day
    assert template.timezone == "Europe/Istanbul"
    assert template.is_important is True
    detail = client.get(f"/routines/{routine_id}").get_data(as_text=True)
    assert "Puantajı tamamla" in detail
    assert "Rutin oluşturuldu" in detail
    assert "routine_template.created" not in detail


@pytest.mark.parametrize(
    ("recurrence", "weekdays", "month_day", "message"),
    [
        ("weekly", [], "", "en az bir gün seçin"),
        ("monthly", [], "32", "1 ile 31"),
    ],
)
def test_routine_conditional_validation_preserves_safe_form_values(
    tmp_path: Path,
    recurrence: str,
    weekdays: list[str],
    month_day: str,
    message: str,
) -> None:
    app = _app(tmp_path)
    response = app.test_client().post(
        "/routines/new",
        data={
            "title": "Puantaj <script>alert(1)</script>",
            "description": "Formda kalsın",
            "recurrence_type": recurrence,
            "local_time": "17:00",
            "start_date": "2026-07-16",
            "end_date": "",
            "weekdays": weekdays,
            "month_day": month_day,
        },
    )
    text = response.get_data(as_text=True)
    assert response.status_code == 400
    assert message in text
    assert "Formda kalsın" in text
    assert "<script>" not in text
    assert "&lt;script&gt;" in text
    assert "Traceback" not in text


def test_today_occurrence_is_idempotent_and_mutations_use_revisions(
    tmp_path: Path,
) -> None:
    app = _app(tmp_path)
    client = app.test_client()
    routine_id = _create_routine(client)

    assert client.get("/today").status_code == 200
    assert client.get("/today").status_code == 200
    service = app.config["CSE_ROUTINE_SERVICE"]
    occurrences = service.list_occurrences(
        RoutineOccurrenceQuery(routine_template_id=routine_id)
    )
    assert len(occurrences) == 1
    occurrence = occurrences[0]
    assert occurrence.status == RoutineOccurrenceStatus.OPEN
    assert occurrence.occurrence_local_date == "2026-07-16"

    closed = client.post(
        f"/routine-occurrences/{occurrence.routine_occurrence_id}/close",
        data={
            "expected_revision": "1",
            "return_to": "today",
            "outcome_type": "completed",
            "outcome_note": "Puantaj gönderildi",
        },
    )
    assert closed.status_code == 302
    assert closed.headers["Location"].endswith("/today?saved=occurrence_closed")
    stale = client.post(
        f"/routine-occurrences/{occurrence.routine_occurrence_id}/close",
        data={"expected_revision": "1", "outcome_type": "completed"},
    )
    assert stale.status_code == 409
    assert "sayfayı yenileyin" in stale.get_data(as_text=True)

    reopened = client.post(
        f"/routine-occurrences/{occurrence.routine_occurrence_id}/reopen",
        data={"expected_revision": "2", "next_attention_at": "2026-07-16T18:00"},
    )
    assert reopened.status_code == 302
    snoozed = client.post(
        f"/routine-occurrences/{occurrence.routine_occurrence_id}/snooze",
        data={"expected_revision": "3", "next_attention_at": "2026-07-16T19:00"},
    )
    assert snoozed.status_code == 302

    stored = service.list_occurrences(
        RoutineOccurrenceQuery(routine_template_id=routine_id)
    )[0]
    assert stored.status == RoutineOccurrenceStatus.OPEN
    assert stored.outcome_type is None
    assert stored.next_attention_at == "2026-07-16T16:00:00Z"
    assert stored.revision == 4
    history = service.list_occurrence_history(stored.routine_occurrence_id)
    assert [event.sequence for event in history] == [1, 2, 3, 4]
    assert history[1].payload["outcome_type"] == RoutineOccurrenceOutcome.COMPLETED.value


def test_routine_missing_records_are_404(tmp_path: Path) -> None:
    app = _app(tmp_path)
    client = app.test_client()
    missing_template_id = _uuid(777777)
    missing_occurrence_id = _uuid(888888)

    assert client.get("/routines/not-a-uuid").status_code == 404
    assert client.get(f"/routines/{missing_template_id}").status_code == 404
    assert client.post(
        f"/routines/{missing_template_id}/deactivate",
        data={"expected_revision": "1"},
    ).status_code == 404

    occurrence_requests = (
        (
            "snooze",
            {"expected_revision": "1", "next_attention_at": "2026-07-16T18:00"},
        ),
        (
            "close",
            {"expected_revision": "1", "outcome_type": "completed"},
        ),
        (
            "reopen",
            {"expected_revision": "1", "next_attention_at": "2026-07-16T18:00"},
        ),
    )
    for action, data in occurrence_requests:
        response = client.post(
            f"/routine-occurrences/{missing_occurrence_id}/{action}", data=data
        )
        assert response.status_code == 404


def test_routine_deactivation_conflict_and_missing_occurrence_are_safe(
    tmp_path: Path,
) -> None:
    app = _app(tmp_path)
    client = app.test_client()
    routine_id = _create_routine(client, start_date="2026-07-17")

    response = client.post(
        f"/routines/{routine_id}/deactivate", data={"expected_revision": "1"}
    )
    assert response.status_code == 302
    template = app.config["CSE_ROUTINE_SERVICE"].get_template(routine_id)
    assert template.status == RoutineTemplateStatus.INACTIVE
    assert template.revision == 2
    stale = client.post(
        f"/routines/{routine_id}/deactivate", data={"expected_revision": "1"}
    )
    assert stale.status_code == 409
    assert client.get("/today").status_code == 200
    assert not app.config["CSE_ROUTINE_SERVICE"].list_occurrences(
        RoutineOccurrenceQuery(routine_template_id=routine_id)
    )
    assert client.post(
        f"/routine-occurrences/{_uuid(888888)}/close",
        data={"expected_revision": "1", "outcome_type": "completed"},
    ).status_code == 404


def test_restart_keeps_field_data_and_existing_observation_backup_flows(
    tmp_path: Path,
) -> None:
    first = _app(tmp_path)
    client = first.test_client()
    follow_up_id = _create_follow_up(client, "Kalıcı saha takibi")
    routine_id = _create_routine(client, start_date="2026-07-17")
    client.post("/projects/new", data={"name": "Kalıcı Proje"})

    second = _app(tmp_path)
    reopened = second.test_client()
    assert "Kalıcı saha takibi" in reopened.get(
        f"/follow-ups/{follow_up_id}"
    ).get_data(as_text=True)
    assert "Puantajı tamamla" in reopened.get(
        f"/routines/{routine_id}"
    ).get_data(as_text=True)
    assert "Kalıcı Proje" in reopened.get("/observations").get_data(as_text=True)

    backup = reopened.post("/backups")
    assert backup.status_code == 302
    download = reopened.get(backup.headers["Location"])
    assert download.status_code == 200
    assert download.mimetype == "application/zip"
    assert str(tmp_path) not in str(download.headers)
    assert str(tmp_path).encode() not in download.data
    with zipfile.ZipFile(io.BytesIO(download.data)) as archive:
        assert "manifest.json" in archive.namelist()
        assert any(name.endswith("cse.sqlite3") for name in archive.namelist())


def test_routine_list_queries_and_turkish_empty_views(tmp_path: Path) -> None:
    app = _app(tmp_path)
    client = app.test_client()
    assert "Henüz rutin tanımlanmadı" in client.get("/routines").get_data(as_text=True)
    assert "Unutma Kutusu boş" in client.get(
        "/follow-ups/inbox"
    ).get_data(as_text=True)
    _create_routine(client, start_date="2026-07-17")
    assert len(
        app.config["CSE_ROUTINE_SERVICE"].list_templates(RoutineTemplateQuery())
    ) == 1
    assert client.get("/routines/not-a-uuid").status_code == 404
