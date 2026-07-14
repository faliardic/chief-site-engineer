import hashlib
import io
import json
import sqlite3
import zipfile
from pathlib import Path

import pytest

from app.persistence import SCHEMA_VERSION
from app.web import create_app


def _digest_file(path: Path) -> dict[str, object]:
    data = path.read_bytes()
    return {"sha256": hashlib.sha256(data).hexdigest(), "size_bytes": len(data)}


def _digest_bytes(data: bytes) -> dict[str, object]:
    return {"sha256": hashlib.sha256(data).hexdigest(), "size_bytes": len(data)}


def _create_observation(app, *, with_attachment: bool) -> tuple[str, Path | None]:
    client = app.test_client()
    client.post("/projects/new", data={"name": "Yedek Testi"})
    project_id = app.config["CSE_SERVICE"].list_projects()[0].project_id
    data: dict[str, object] = {
        "project_id": project_id,
        "location": "A Blok",
        "category": "Kalite",
        "description": "Yedeklenecek gözlem",
    }
    if with_attachment:
        data["upload"] = (io.BytesIO(b"verified-photo-bytes"), "saha.jpg")
    created = client.post(
        "/observations/new",
        data=data,
        content_type="multipart/form-data",
    )
    observation_id = created.headers["Location"].rsplit("/", 1)[-1]
    detail = app.config["CSE_SERVICE"].get_observation_detail(observation_id)
    if not detail.attachments:
        return observation_id, None
    metadata = detail.attachments[0].metadata
    path = app.config["CSE_DATA_ROOT"] / "attachments" / Path(
        *metadata.stored_relative_path.split("/")
    )
    return observation_id, path


def _artifact_id(response) -> str:
    return response.headers["Location"].rsplit("/", 1)[-1]


def _artifact_path(root: Path, artifact_id: str) -> Path:
    return root / "backups" / f"{artifact_id}.csebackup.zip"


def test_backup_surface_and_verified_download_with_attachment(
    tmp_path: Path,
) -> None:
    app = create_app(tmp_path)
    observation_id, attachment_path = _create_observation(
        app, with_attachment=True
    )
    assert attachment_path is not None
    client = app.test_client()
    database = tmp_path / "cse.sqlite3"
    database_before = _digest_file(database)
    attachment_before = _digest_file(attachment_path)

    page = client.get("/observations")
    assert page.status_code == 200
    assert "Tam veri yedeği".encode() in page.data
    assert "Yedek oluştur ve indir".encode() in page.data
    assert b'<form method="post" action="/backups">' in page.data
    assert b'name="output' not in page.data
    assert b'name="file' not in page.data

    outside = tmp_path.parent / "user-selected.csebackup.zip"
    created = client.post(
        "/backups",
        data={"output_path": str(outside), "file_name": outside.name},
    )
    assert created.status_code == 302
    artifact_id = _artifact_id(created)
    artifact_path = _artifact_path(tmp_path, artifact_id)
    assert artifact_path.is_file()
    assert not outside.exists()

    download = client.get(created.headers["Location"])
    assert download.status_code == 200
    assert download.mimetype == "application/zip"
    disposition = download.headers["Content-Disposition"]
    assert disposition.startswith("attachment;")
    assert ".csebackup.zip" in disposition
    assert str(tmp_path) not in str(download.headers)
    assert str(tmp_path).encode() not in download.data
    assert download.data == artifact_path.read_bytes()

    manifest = app.config["CSE_BACKUP_SERVICE"].verify_backup(artifact_path)
    assert manifest["schema_version"] == SCHEMA_VERSION
    assert manifest["observation_count"] == 1
    assert manifest["event_count"] == 1
    assert manifest["attachment_count"] == 1
    with zipfile.ZipFile(io.BytesIO(download.data)) as bundle:
        assert set(bundle.namelist()) == {"manifest.json", *manifest["files"]}
        assert json.loads(bundle.read("manifest.json")) == manifest
        for name, expected in manifest["files"].items():
            assert _digest_bytes(bundle.read(name)) == expected

    assert _digest_file(database) == database_before
    assert _digest_file(attachment_path) == attachment_before
    reopened = create_app(tmp_path)
    reopened_detail = reopened.config["CSE_SERVICE"].get_observation_detail(
        observation_id
    )
    assert reopened_detail.observation.description == "Yedeklenecek gözlem"
    assert len(reopened_detail.attachments) == 1


def test_backup_without_attachment_and_two_outputs_do_not_overwrite(
    tmp_path: Path,
) -> None:
    app = create_app(tmp_path)
    _create_observation(app, with_attachment=False)
    client = app.test_client()

    first = client.post("/backups")
    second = client.post("/backups")
    assert first.status_code == second.status_code == 302
    first_id = _artifact_id(first)
    second_id = _artifact_id(second)
    assert first_id != second_id
    first_path = _artifact_path(tmp_path, first_id)
    second_path = _artifact_path(tmp_path, second_id)
    assert first_path.is_file() and second_path.is_file()
    first_digest = _digest_file(first_path)

    first_manifest = app.config["CSE_BACKUP_SERVICE"].verify_backup(first_path)
    second_manifest = app.config["CSE_BACKUP_SERVICE"].verify_backup(second_path)
    assert first_manifest["attachment_count"] == 0
    assert second_manifest["attachment_count"] == 0
    assert set(first_manifest["files"]) == {"cse.sqlite3"}

    app.config["CSE_BACKUP_ID_FACTORY"] = lambda: first_id
    collision = client.post("/backups")
    assert collision.status_code == 409
    assert "Yedek oluşturulamadı".encode() in collision.data
    assert _digest_file(first_path) == first_digest
    assert sorted(path.name for path in (tmp_path / "backups").iterdir()) == sorted(
        [first_path.name, second_path.name]
    )


@pytest.mark.parametrize("failure", ["missing", "tampered", "unsafe"])
def test_missing_tampered_or_unsafe_attachment_fails_closed(
    tmp_path: Path, failure: str
) -> None:
    app = create_app(tmp_path)
    _observation_id, attachment_path = _create_observation(
        app, with_attachment=True
    )
    assert attachment_path is not None
    if failure == "missing":
        attachment_path.unlink()
    elif failure == "tampered":
        attachment_path.write_bytes(b"tampered")
    else:
        connection = sqlite3.connect(tmp_path / "cse.sqlite3")
        try:
            connection.execute(
                "UPDATE attachments SET stored_relative_path = ?",
                ("../unsafe.jpg",),
            )
            connection.commit()
        finally:
            connection.close()
    database_before = _digest_file(tmp_path / "cse.sqlite3")
    attachment_before = (
        _digest_file(attachment_path) if attachment_path.exists() else None
    )

    response = app.test_client().post("/backups")

    assert response.status_code == 409
    assert "Yedek oluşturulamadı".encode() in response.data
    assert "Veri ve dosya bütünlüğünü".encode() in response.data
    assert b"Traceback" not in response.data
    assert b"BackupValidationError" not in response.data
    assert str(tmp_path).encode() not in response.data
    backups = tmp_path / "backups"
    assert backups.is_dir()
    assert list(backups.iterdir()) == []
    assert _digest_file(tmp_path / "cse.sqlite3") == database_before
    assert (
        _digest_file(attachment_path) if attachment_path.exists() else None
    ) == attachment_before


def test_backup_download_rejects_invalid_id_traversal_and_corrupt_artifact(
    tmp_path: Path,
) -> None:
    app = create_app(tmp_path)
    _create_observation(app, with_attachment=False)
    client = app.test_client()

    assert client.get("/backups").status_code == 405
    assert client.get("/backups/not-a-uuid").status_code == 404
    assert (
        client.get("/backups/00000000-0000-4000-8000-000000000000").status_code
        == 404
    )
    assert client.get("/backups/%2e%2e%2fcse.sqlite3").status_code == 404

    created = client.post("/backups")
    artifact_path = _artifact_path(tmp_path, _artifact_id(created))
    artifact_path.write_bytes(b"corrupt archive")
    response = client.get(created.headers["Location"])

    assert response.status_code == 409
    assert "Yedek oluşturulamadı".encode() in response.data
    assert b"Traceback" not in response.data
    assert str(tmp_path).encode() not in response.data
