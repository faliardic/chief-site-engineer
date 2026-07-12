import io
from pathlib import Path

from app.web import create_app, istanbul_datetime_local_to_utc


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
    assert b"valid" in page.data
    response = client.get(f"/attachments/{attachment_id}")
    assert response.data == b"image-bytes"
    assert b"saha.jpg" in response.headers["Content-Disposition"].encode()
    assert str(tmp_path).encode() not in response.data

    reopened = create_app(tmp_path)
    reopened_page = reopened.test_client().get(created.headers["Location"])
    assert b"Foto" in reopened_page.data
    assert b"valid" in reopened_page.data


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
    conflict = client.post(
        f"/observations/{observation_id}/status",
        data={"expected_revision": "1", "new_status": "closed"},
    )
    assert conflict.status_code == 409
    assert b"baska bir islem" in conflict.data

    reporting = client.post(
        f"/observations/{observation_id}/reporting",
        data={"expected_revision": "2", "reported_to": "Formen",
              "reported_at": "2026-07-13T15:30"},
    )
    assert reporting.status_code == 302
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
    assert second.config["MAX_CONTENT_LENGTH"] == 25 * 1024 * 1024


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
