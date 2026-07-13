import io
import zipfile
from datetime import datetime, timedelta, timezone
from pathlib import Path

from app.web import create_app, istanbul_datetime_local_to_utc
from app.web.app import (
    event_label,
    integrity_label,
    status_label,
    utc_to_istanbul_display,
)


def test_first_use_project_and_observation_prg_flow(tmp_path: Path) -> None:
    app = create_app(tmp_path)
    client = app.test_client()

    assert client.get("/observations/new").status_code == 302
    project = client.post(
        "/projects/new", data={"name": "<b>Ornek Santiye</b>"}, follow_redirects=True
    )
    assert project.status_code == 200

    page = client.get("/observations/new")
    assert b"Yeni Gozlem" in page.data
    project_id = app.config["CSE_SERVICE"].list_projects()[0].project_id
    created = client.post(
        "/observations/new",
        data={
            "project_id": project_id,
            "location": "A <script>alert(1)</script>",
            "category": "quality",
            "description": "Kalip kontrolu",
            "notes": "Detay",
        },
        follow_redirects=False,
    )
    assert created.status_code == 302
    detail = client.get(created.headers["Location"])
    assert b"Kalip kontrolu" in detail.data
    assert b"<script>" not in detail.data
    assert b"&lt;script&gt;" in detail.data


def test_multipart_upload_download_and_verification(tmp_path: Path) -> None:
    app = create_app(tmp_path)
    client = app.test_client()
    client.post("/projects/new", data={"name": "Ornek"})
    project_id = app.config["CSE_SERVICE"].list_projects()[0].project_id
    created = client.post(
        "/observations/new",
        data={
            "project_id": project_id,
            "location": "A Blok",
            "category": "quality",
            "description": "Foto",
            "upload": (io.BytesIO(b"image-bytes"), "saha.jpg"),
        },
        content_type="multipart/form-data",
    )
    observation_id = created.headers["Location"].rsplit("/", 1)[-1]
    detail = app.config["CSE_SERVICE"].get_observation_detail(observation_id)
    attachment_id = detail.attachments[0].metadata.attachment_id

    page = client.get(created.headers["Location"])
    assert "Dosya doğrulandı".encode() in page.data
    assert b'class="attachment-preview"' in page.data
    assert f'/attachments/{attachment_id}?view=1'.encode() in page.data

    preview = client.get(f"/attachments/{attachment_id}?view=1")
    assert preview.data == b"image-bytes"
    assert preview.headers["Content-Disposition"].startswith("inline;")

    response = client.get(f"/attachments/{attachment_id}")
    assert response.data == b"image-bytes"
    assert response.headers["Content-Disposition"].startswith("attachment;")
    assert b"saha.jpg" in response.headers["Content-Disposition"].encode()
    assert str(tmp_path).encode() not in response.data
    assert str(tmp_path) not in str(response.headers)

    reopened = create_app(tmp_path)
    reopened_page = reopened.test_client().get(created.headers["Location"])
    assert b"Foto" in reopened_page.data
    assert "Dosya doğrulandı".encode() in reopened_page.data
    assert b'class="attachment-preview"' in reopened_page.data


def test_detail_uses_turkish_labels_local_time_and_safe_fallbacks(
    tmp_path: Path,
) -> None:
    app = create_app(tmp_path)
    client = app.test_client()
    client.post("/projects/new", data={"name": "Örnek"})
    project_id = app.config["CSE_SERVICE"].list_projects()[0].project_id
    created = client.post(
        "/observations/new",
        data={
            "project_id": project_id,
            "location": "A Blok",
            "category": "quality",
            "description": "Kalıp kontrolü",
        },
    )
    observation_id = created.headers["Location"].rsplit("/", 1)[-1]

    client.post(
        f"/observations/{observation_id}/status",
        data={"expected_revision": "1", "new_status": "tracking"},
    )
    client.post(
        f"/observations/{observation_id}/reporting",
        data={
            "expected_revision": "2",
            "reported_to": "Saha formenı",
            "reported_at": "2026-07-13T15:30",
        },
    )
    stored_detail = app.config["CSE_SERVICE"].get_observation_detail(observation_id)
    stored_event_time = stored_detail.events[0].occurred_at
    expected_local_time = (
        datetime.fromisoformat(stored_event_time.replace("Z", "+00:00"))
        .astimezone(timezone(timedelta(hours=3)))
        .strftime("%d.%m.%Y %H:%M")
    )

    page = client.get(created.headers["Location"])
    assert "Gözlem Detayı".encode() in page.data
    assert "Durumu Güncelle".encode() in page.data
    assert "Bildirilen Kişi".encode() in page.data
    assert "Bildirim Zamanı".encode() in page.data
    assert b'value="open">A' + "çık".encode() in page.data
    assert b'value="tracking" selected>Takipte' in page.data
    assert b'value="closed">Kapal' + "ı".encode() in page.data
    assert "Gözlem oluşturuldu".encode() in page.data
    assert "Durum güncellendi".encode() in page.data
    assert "Bildirim bilgisi güncellendi".encode() in page.data
    assert b"observation_created" not in page.data
    assert b"observation_status_changed" not in page.data
    assert b"observation_reporting_updated" not in page.data
    assert expected_local_time.encode() in page.data
    assert stored_event_time.encode() not in page.data
    assert stored_detail.events[0].occurred_at == stored_event_time
    assert "13.07.2026 15:30".encode() in page.data

    assert status_label("open") == "Açık"
    assert status_label("tracking") == "Takipte"
    assert status_label("closed") == "Kapalı"
    assert integrity_label("valid") == "Dosya doğrulandı"
    assert integrity_label("missing") == "Dosya bulunamadı"
    assert integrity_label("hash_mismatch") == "Dosya bütünlüğü doğrulanamadı"
    assert event_label("observation_archived") == "Gözlem arşivlendi"
    assert event_label("future_event") == "Gözlem kaydı güncellendi"
    assert utc_to_istanbul_display("2026-01-13T12:30:00Z") == "13.01.2026 15:30"

    reopened_page = create_app(tmp_path).test_client().get(created.headers["Location"])
    assert "Takipte".encode() in reopened_page.data
    assert "Saha formenı".encode() in reopened_page.data
    assert "Gözlem oluşturuldu".encode() in reopened_page.data
    assert "Durum güncellendi".encode() in reopened_page.data
    assert "Bildirim bilgisi güncellendi".encode() in reopened_page.data


def test_status_reporting_conflict_and_utc_conversion(tmp_path: Path) -> None:
    app = create_app(tmp_path)
    client = app.test_client()
    client.post("/projects/new", data={"name": "Ornek"})
    project_id = app.config["CSE_SERVICE"].list_projects()[0].project_id
    response = client.post(
        "/observations/new",
        data={"project_id": project_id, "location": "A", "category": "quality",
              "description": "Kontrol"},
    )
    observation_id = response.headers["Location"].rsplit("/", 1)[-1]

    status = client.post(
        f"/observations/{observation_id}/status",
        data={"expected_revision": "1", "new_status": "tracking"},
    )
    assert status.status_code == 302
    assert status.headers["Location"].endswith("?saved=status")
    saved_status = client.get(status.headers["Location"])
    assert "Durum bilgisi kaydedildi.".encode() in saved_status.data
    conflict = client.post(
        f"/observations/{observation_id}/status",
        data={"expected_revision": "1", "new_status": "closed"},
    )
    assert conflict.status_code == 409
    assert "başka bir işlem".encode() in conflict.data

    reporting = client.post(
        f"/observations/{observation_id}/reporting",
        data={"expected_revision": "2", "reported_to": "Formen",
              "reported_at": "2026-07-13T15:30"},
    )
    assert reporting.status_code == 302
    assert reporting.headers["Location"].endswith("?saved=reporting")
    saved_reporting = client.get(reporting.headers["Location"])
    assert "Bildirim bilgisi kaydedildi.".encode() in saved_reporting.data
    detail = app.config["CSE_SERVICE"].get_observation_detail(observation_id)
    assert detail.observation.reported_at == "2026-07-13T12:30:00Z"
    assert istanbul_datetime_local_to_utc("2026-01-13T15:30") == "2026-01-13T12:30:00Z"


def test_viewport_mobile_css_restart_and_upload_limit(tmp_path: Path) -> None:
    first = create_app(tmp_path)
    client = first.test_client()
    client.post("/projects/new", data={"name": "Kalici Proje"})

    second = create_app(tmp_path)
    page = second.test_client().get("/observations")
    assert b"Kalici Proje" in page.data
    assert b'name="viewport"' in page.data
    css = second.test_client().get("/static/app.css")
    assert b"min-height: 44px" in css.data
    assert b".detail-actions" in css.data
    assert b"grid-template-columns: repeat(2, minmax(0, 1fr))" in css.data
    assert b".attachment-preview" in css.data
    assert b"max-width: 100%" in css.data
    assert second.config["MAX_CONTENT_LENGTH"] == 25 * 1024 * 1024


def test_non_image_and_missing_attachment_do_not_render_broken_preview(
    tmp_path: Path,
) -> None:
    app = create_app(tmp_path)
    client = app.test_client()
    client.post("/projects/new", data={"name": "Örnek"})
    project_id = app.config["CSE_SERVICE"].list_projects()[0].project_id
    created = client.post(
        "/observations/new",
        data={
            "project_id": project_id,
            "location": "A",
            "category": "quality",
            "description": "Metin eki",
            "upload": (io.BytesIO(b"saha notu"), "not.txt"),
        },
        content_type="multipart/form-data",
    )
    detail = app.config["CSE_SERVICE"].get_observation_detail(
        created.headers["Location"].rsplit("/", 1)[-1]
    )
    attachment = detail.attachments[0]

    valid_page = client.get(created.headers["Location"])
    assert "Dosya doğrulandı".encode() in valid_page.data
    assert b'class="attachment-preview"' not in valid_page.data
    assert "İndir".encode() in valid_page.data

    managed_file = (
        app.config["CSE_SERVICE"].attachment_store.root
        / attachment.metadata.stored_relative_path
    )
    managed_file.unlink()
    missing_page = client.get(created.headers["Location"])
    assert "Dosya bulunamadı".encode() in missing_page.data
    assert "Dosya güvenli biçimde sunulamıyor.".encode() in missing_page.data
    assert b'class="attachment-preview"' not in missing_page.data


def test_invalid_attachment_is_not_served_and_upload_limit_returns_413(
    tmp_path: Path,
) -> None:
    app = create_app(tmp_path)
    client = app.test_client()
    client.post("/projects/new", data={"name": "Ornek"})
    project_id = app.config["CSE_SERVICE"].list_projects()[0].project_id
    created = client.post(
        "/observations/new",
        data={
            "project_id": project_id, "location": "A", "category": "quality",
            "description": "Foto", "upload": (io.BytesIO(b"original"), "saha.jpg"),
        },
        content_type="multipart/form-data",
    )
    observation_id = created.headers["Location"].rsplit("/", 1)[-1]
    detail = app.config["CSE_SERVICE"].get_observation_detail(observation_id)
    attachment = detail.attachments[0]
    managed = app.config["CSE_SERVICE"].attachment_store.root
    (managed / attachment.metadata.stored_relative_path).write_bytes(b"tampered")

    response = client.get(
        f"/attachments/{attachment.metadata.attachment_id}"
    )
    assert response.status_code == 409
    preview = client.get(
        f"/attachments/{attachment.metadata.attachment_id}?view=1"
    )
    assert preview.status_code == 409
    page = client.get(created.headers["Location"])
    assert "Dosya bütünlüğü doğrulanamadı".encode() in page.data
    assert b'class="attachment-preview"' not in page.data

    app.config["MAX_CONTENT_LENGTH"] = 128
    too_large = client.post(
        "/observations/new",
        data={
            "project_id": project_id, "location": "A", "category": "quality",
            "description": "Buyuk", "upload": (io.BytesIO(b"x" * 1024), "big.bin"),
        },
        content_type="multipart/form-data",
    )
    assert too_large.status_code == 413


def test_daily_export_web_flow_returns_managed_zip_without_path_leak(
    tmp_path: Path,
) -> None:
    app = create_app(tmp_path)
    client = app.test_client()
    client.post("/projects/new", data={"name": "Ornek"})
    project_id = app.config["CSE_SERVICE"].list_projects()[0].project_id
    created = client.post(
        "/observations/new",
        data={
            "project_id": project_id,
            "location": "A",
            "category": "quality",
            "description": "Export",
        },
    )
    observation_id = created.headers["Location"].rsplit("/", 1)[-1]
    observed_at = app.config["CSE_SERVICE"].get_observation_detail(
        observation_id
    ).observation.observed_at
    local_date = (
        datetime.fromisoformat(observed_at.replace("Z", "+00:00"))
        .astimezone(timezone(timedelta(hours=3)))
        .date()
        .isoformat()
    )

    response = client.post("/exports/daily", data={"local_date": local_date})
    assert response.status_code == 302
    download = client.get(response.headers["Location"])
    assert download.status_code == 200
    assert download.mimetype == "application/zip"
    assert str(tmp_path).encode() not in download.data
    assert str(tmp_path) not in str(download.headers)
    with zipfile.ZipFile(io.BytesIO(download.data)) as bundle:
        assert "export_manifest.json" in bundle.namelist()


def test_observation_list_search_preserves_filters_and_handles_literal_input(
    tmp_path: Path,
) -> None:
    app = create_app(tmp_path)
    client = app.test_client()
    client.post("/projects/new", data={"name": "İstanbul Projesi"})
    project_id = app.config["CSE_SERVICE"].list_projects()[0].project_id
    first = client.post(
        "/observations/new",
        data={
            "project_id": project_id,
            "location": "A Blok",
            "category": "Kalite",
            "description": "Kalıp kontrolü",
            "notes": "Literal %_' <etiket>",
        },
    )
    client.post(
        "/observations/new",
        data={
            "project_id": project_id,
            "location": "B Blok",
            "category": "Güvenlik",
            "description": "Korkuluk kontrolü",
        },
    )
    first_id = first.headers["Location"].rsplit("/", 1)[-1]
    app.config["CSE_SERVICE"].update_reporting(
        first_id, 1, "Şantiye Şefi", "2026-07-13T10:00:00Z"
    )

    unfiltered = client.get("/observations", query_string={"q": "   "})
    assert "Kalıp kontrolü".encode() in unfiltered.data
    assert "Korkuluk kontrolü".encode() in unfiltered.data

    combined = client.get(
        "/observations",
        query_string={
            "project_id": project_id,
            "status": "open",
            "q": "şefİ",
        },
    )
    assert combined.status_code == 200
    assert "Kalıp kontrolü".encode() in combined.data
    assert "Korkuluk kontrolü".encode() not in combined.data
    assert f'value="{project_id}" selected'.encode() in combined.data
    assert b'value="open" selected' in combined.data
    assert 'value="şefİ"'.encode() in combined.data
    assert "Filtreleri Temizle".encode() in combined.data

    literal = client.get("/observations", query_string={"q": "%_' <etiket>"})
    assert literal.status_code == 200
    assert "Kalıp kontrolü".encode() in literal.data
    assert b"<etiket>" not in literal.data
    assert b"&lt;etiket&gt;" in literal.data

    empty = client.get("/observations", query_string={"q": "<script>"})
    assert empty.status_code == 200
    assert "Aramanızla eşleşen gözlem bulunamadı.".encode() in empty.data
    assert b"<script>" not in empty.data
    assert b"&lt;script&gt;" in empty.data

    too_long = client.get("/observations", query_string={"q": "x" * 201})
    assert too_long.status_code == 400
    assert "Arama metni en fazla 200 karakter olabilir.".encode() in too_long.data
    assert b"Traceback" not in too_long.data


def test_observation_edit_prg_escape_restart_conflict_and_allowlist(
    tmp_path: Path,
) -> None:
    app = create_app(tmp_path)
    client = app.test_client()
    client.post("/projects/new", data={"name": "Örnek"})
    project_id = app.config["CSE_SERVICE"].list_projects()[0].project_id
    created = client.post(
        "/observations/new",
        data={
            "project_id": project_id,
            "location": "A Blok",
            "category": "Kalite",
            "description": "Kalıp kontrolü",
            "notes": "Eski not",
        },
    )
    observation_id = created.headers["Location"].rsplit("/", 1)[-1]
    original = app.config["CSE_SERVICE"].get_observation_detail(observation_id)

    edit_page = client.get(f"/observations/{observation_id}/edit")
    assert edit_page.status_code == 200
    assert "Gözlemi Düzenle".encode() in edit_page.data
    assert b'value="A Blok"' in edit_page.data
    assert "Kalıp kontrolü".encode() in edit_page.data
    assert "İptal".encode() in edit_page.data

    updated = client.post(
        f"/observations/{observation_id}/edit",
        data={
            "expected_revision": "1",
            "location": "B Blok",
            "category": "Güvenlik",
            "description": "<script>alert(1)</script>",
            "notes": "Yeni not",
            "project_id": "22222222-2222-4222-8222-222222222222",
            "status": "closed",
            "reported_to": "Değişmemeli",
            "reported_at": "2026-07-13T15:30",
        },
    )
    assert updated.status_code == 302
    assert updated.headers["Location"].endswith("?saved=details")
    saved = client.get(updated.headers["Location"])
    assert "Gözlem bilgileri kaydedildi.".encode() in saved.data
    assert "Gözlem bilgileri güncellendi".encode() in saved.data
    assert b"observation_details_updated" not in saved.data
    assert b"<script>alert(1)</script>" not in saved.data
    assert b"&lt;script&gt;alert(1)&lt;/script&gt;" in saved.data

    detail = app.config["CSE_SERVICE"].get_observation_detail(observation_id)
    assert detail.observation.revision == 2
    assert detail.observation.project_id == original.observation.project_id
    assert detail.observation.status == original.observation.status
    assert detail.observation.reported_to == original.observation.reported_to
    assert detail.observation.reported_at == original.observation.reported_at
    assert detail.attachments == original.attachments
    assert detail.events[-1].payload == {
        "changed_fields": ["location", "category", "description", "notes"],
        "revision": 2,
    }

    conflict = client.post(
        f"/observations/{observation_id}/edit",
        data={
            "expected_revision": "1",
            "location": "Çakışan konum",
            "category": "Kalite",
            "description": "Çakışan açıklama",
            "notes": "Çakışan not",
        },
    )
    assert conflict.status_code == 409
    assert "sayfayı yenileyin".encode() in conflict.data
    assert "Çakışan konum".encode() in conflict.data
    after_conflict = app.config["CSE_SERVICE"].get_observation_detail(observation_id)
    assert after_conflict.observation == detail.observation
    assert after_conflict.events == detail.events

    invalid = client.post(
        f"/observations/{observation_id}/edit",
        data={
            "expected_revision": "2",
            "location": "   ",
            "category": "Kalite",
            "description": "Girilen açıklama",
            "notes": "Formda kalsın",
        },
    )
    assert invalid.status_code == 400
    assert "Girdileri kontrol edip yeniden deneyin.".encode() in invalid.data
    assert "Girilen açıklama".encode() in invalid.data
    assert "Formda kalsın".encode() in invalid.data

    reopened = create_app(tmp_path)
    reopened_detail = reopened.config["CSE_SERVICE"].get_observation_detail(
        observation_id
    )
    assert reopened_detail.observation == detail.observation
    assert reopened_detail.events == detail.events
    reopened_page = reopened.test_client().get(f"/observations/{observation_id}")
    assert "Gözlem bilgileri güncellendi".encode() in reopened_page.data


def test_archived_observation_has_no_edit_surface(tmp_path: Path) -> None:
    app = create_app(tmp_path)
    client = app.test_client()
    client.post("/projects/new", data={"name": "Örnek"})
    project_id = app.config["CSE_SERVICE"].list_projects()[0].project_id
    created = client.post(
        "/observations/new",
        data={
            "project_id": project_id,
            "location": "A",
            "category": "Kalite",
            "description": "Arşiv testi",
        },
    )
    observation_id = created.headers["Location"].rsplit("/", 1)[-1]
    app.config["CSE_SERVICE"].archive_observation(observation_id, 1)

    detail = client.get(created.headers["Location"])
    assert "Gözlemi Düzenle".encode() not in detail.data
    assert "Durumu Güncelle".encode() not in detail.data
    assert "Bildirim Bilgisi".encode() not in detail.data
    direct = client.get(f"/observations/{observation_id}/edit")
    assert direct.status_code == 409
    assert "Arşivlenmiş gözlem düzenlenemez.".encode() in direct.data
