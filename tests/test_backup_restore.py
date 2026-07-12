import hashlib
import io
import json
import stat
import zipfile
from pathlib import Path

import pytest

from app.application import ObservationApplicationService, UploadStream
from app.operations import BackupService, BackupValidationError
from app.storage import ManagedAttachmentStore
from app.web import create_app


IDS = iter(
    [
        "11111111-1111-4111-8111-111111111111",
        "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
        "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
        "cccccccc-cccc-4ccc-8ccc-cccccccccccc",
    ]
)


def seed(root: Path) -> tuple[str, str]:
    ids = iter(
        [
            "11111111-1111-4111-8111-111111111111",
            "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
            "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
            "cccccccc-cccc-4ccc-8ccc-cccccccccccc",
        ]
    )
    service = ObservationApplicationService(
        root / "cse.sqlite3",
        ManagedAttachmentStore(root / "attachments"),
        clock=lambda: "2026-07-13T09:00:00Z",
        uuid_factory=lambda: next(ids),
    )
    project = service.create_project("Ornek")
    observation = service.create_observation(
        project.project_id,
        "A",
        "quality",
        "Kontrol",
        None,
        UploadStream(io.BytesIO(b"backup-photo"), "photo.jpg"),
    )
    detail = service.get_observation_detail(observation.observation_id)
    return observation.observation_id, detail.attachments[0].metadata.attachment_id


def rewrite_zip(source: Path, target: Path, mutate) -> None:
    with zipfile.ZipFile(source) as incoming, zipfile.ZipFile(target, "w") as outgoing:
        for info in incoming.infolist():
            name, data, changed_info = mutate(info, incoming.read(info.filename))
            outgoing.writestr(changed_info or name, data)


def test_backup_online_snapshot_verify_restore_and_reopen(tmp_path: Path) -> None:
    source = tmp_path / "source"
    observation_id, attachment_id = seed(source)
    source_files = sorted(path for path in source.rglob("*") if path.is_file())
    before = {
        path.relative_to(source).as_posix(): hashlib.sha256(path.read_bytes()).hexdigest()
        for path in source_files
    }
    archive = tmp_path / "field.csebackup.zip"
    backup = BackupService(source, clock=lambda: "2026-07-13T10:00:00Z")

    result = backup.create_backup(archive)
    manifest = backup.verify_backup(archive)
    target = tmp_path / "restored"
    restored = backup.restore_backup(archive, target)

    assert result.attachment_count == 1
    assert manifest["schema_version"] == 2
    assert restored.target_created is True
    service = ObservationApplicationService(
        target / "cse.sqlite3", ManagedAttachmentStore(target / "attachments")
    )
    detail = service.get_observation_detail(observation_id)
    assert detail.attachments[0].verification.status == "valid"
    with service.open_attachment(attachment_id) as file_handle:
        assert file_handle.read() == b"backup-photo"
    client = create_app(target).test_client()
    assert client.get(f"/observations/{observation_id}").status_code == 200
    assert client.get(f"/attachments/{attachment_id}").data == b"backup-photo"
    after = {
        path.relative_to(source).as_posix(): hashlib.sha256(path.read_bytes()).hexdigest()
        for path in sorted(path for path in source.rglob("*") if path.is_file())
    }
    assert after == before


def test_missing_or_tampered_attachment_fails_closed(tmp_path: Path) -> None:
    source = tmp_path / "source"
    observation_id, attachment_id = seed(source)
    service = ObservationApplicationService(
        source / "cse.sqlite3", ManagedAttachmentStore(source / "attachments")
    )
    metadata, _ = service.get_attachment(attachment_id)
    (source / "attachments" / metadata.stored_relative_path).write_bytes(b"tampered")
    archive = tmp_path / "invalid.zip"

    with pytest.raises(BackupValidationError):
        BackupService(source).create_backup(archive)

    assert not archive.exists()


def test_corrupt_archive_hash_and_extra_entry_are_rejected(tmp_path: Path) -> None:
    source = tmp_path / "source"
    seed(source)
    valid = tmp_path / "valid.zip"
    BackupService(source).create_backup(valid)
    corrupt = tmp_path / "corrupt.zip"
    rewrite_zip(
        valid,
        corrupt,
        lambda info, data: (
            info.filename,
            b"corrupt" if info.filename == "cse.sqlite3" else data,
            None,
        ),
    )
    extra = tmp_path / "extra.zip"
    with zipfile.ZipFile(valid) as incoming, zipfile.ZipFile(extra, "w") as outgoing:
        for info in incoming.infolist():
            outgoing.writestr(info, incoming.read(info.filename))
        outgoing.writestr("extra.txt", b"unexpected")

    for archive in (corrupt, extra):
        with pytest.raises(BackupValidationError):
            BackupService(source).verify_backup(archive)


def test_corrupt_attachment_archive_hash_is_rejected(tmp_path: Path) -> None:
    source = tmp_path / "source"
    seed(source)
    valid = tmp_path / "valid.zip"
    BackupService(source).create_backup(valid)
    corrupt = tmp_path / "corrupt-attachment.zip"
    rewrite_zip(
        valid,
        corrupt,
        lambda info, data: (
            info.filename,
            b"tampered" if info.filename.startswith("attachments/") else data,
            None,
        ),
    )

    with pytest.raises(BackupValidationError):
        BackupService(source).verify_backup(corrupt)


def test_missing_manifested_archive_entry_is_rejected(tmp_path: Path) -> None:
    source = tmp_path / "source"
    seed(source)
    valid = tmp_path / "valid.zip"
    BackupService(source).create_backup(valid)
    missing = tmp_path / "missing-entry.zip"
    with zipfile.ZipFile(valid) as incoming, zipfile.ZipFile(missing, "w") as outgoing:
        for info in incoming.infolist():
            if info.filename.startswith("attachments/"):
                continue
            outgoing.writestr(info, incoming.read(info.filename))

    with pytest.raises(BackupValidationError):
        BackupService(source).verify_backup(missing)


@pytest.mark.parametrize("unsafe_name", ["../evil", "/absolute", "bad\\name"])
def test_unsafe_archive_names_are_rejected(tmp_path: Path, unsafe_name: str) -> None:
    archive = tmp_path / "unsafe.zip"
    with zipfile.ZipFile(archive, "w") as bundle:
        bundle.writestr("manifest.json", b"{}")
        bundle.writestr(unsafe_name, b"evil")

    with pytest.raises(BackupValidationError):
        BackupService(tmp_path).verify_backup(archive)


@pytest.mark.parametrize(
    "unsafe_attachment_path",
    [
        (
            "attachments/aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/"
            "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb.jpg:stream"
        ),
        (
            "attachments/C:/"
            "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb.jpg"
        ),
        (
            "attachments/not-a-canonical-uuid/"
            "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb.jpg"
        ),
        (
            "attachments/aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/"
            "not-a-canonical-uuid.jpg"
        ),
    ],
)
def test_attachment_archive_path_is_rejected_before_restore_extraction(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
    unsafe_attachment_path: str,
) -> None:
    archive = tmp_path / "unsafe-attachment-path.zip"
    database_bytes = b"database-placeholder"
    attachment_bytes = b"attachment-placeholder"
    database_digest = {
        "sha256": hashlib.sha256(database_bytes).hexdigest(),
        "size_bytes": len(database_bytes),
    }
    attachment_digest = {
        "sha256": hashlib.sha256(attachment_bytes).hexdigest(),
        "size_bytes": len(attachment_bytes),
    }
    manifest = {
        "backup_format_version": 1,
        "created_at": "2026-07-13T10:00:00Z",
        "schema_version": 2,
        "attachment_count": 1,
        "observation_count": 1,
        "event_count": 1,
        "files": {
            "cse.sqlite3": database_digest,
            unsafe_attachment_path: attachment_digest,
        },
        "attachments": [
            {"path": unsafe_attachment_path, **attachment_digest}
        ],
    }
    with zipfile.ZipFile(archive, "w") as bundle:
        bundle.writestr("manifest.json", json.dumps(manifest))
        bundle.writestr("cse.sqlite3", database_bytes)
        bundle.writestr(unsafe_attachment_path, attachment_bytes)

    backup = BackupService(tmp_path)
    extraction_called = False

    def fail_if_extracted(*_args: object) -> None:
        nonlocal extraction_called
        extraction_called = True

    monkeypatch.setattr(backup, "_extract_entry", fail_if_extracted)
    with pytest.raises(BackupValidationError):
        backup.verify_backup(archive)
    target = tmp_path / "must-not-exist"
    with pytest.raises(BackupValidationError):
        backup.restore_backup(archive, target)

    assert extraction_called is False
    assert not target.exists()


def test_symlink_and_duplicate_entries_are_rejected(tmp_path: Path) -> None:
    symlink_archive = tmp_path / "symlink.zip"
    info = zipfile.ZipInfo("attachments/link")
    info.create_system = 3
    info.external_attr = (stat.S_IFLNK | 0o777) << 16
    with zipfile.ZipFile(symlink_archive, "w") as bundle:
        bundle.writestr("manifest.json", b"{}")
        bundle.writestr(info, b"target")
    duplicate_archive = tmp_path / "duplicate.zip"
    with pytest.warns(UserWarning, match="Duplicate name"):
        with zipfile.ZipFile(duplicate_archive, "w") as bundle:
            bundle.writestr("manifest.json", b"{}")
            bundle.writestr("manifest.json", b"{}")

    for archive in (symlink_archive, duplicate_archive):
        with pytest.raises(BackupValidationError):
            BackupService(tmp_path).verify_backup(archive)


def test_existing_target_and_restore_failure_leave_target_unchanged(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    source = tmp_path / "source"
    seed(source)
    archive = tmp_path / "valid.zip"
    backup = BackupService(source)
    backup.create_backup(archive)
    existing = tmp_path / "existing"
    existing.mkdir()
    marker = existing / "keep.txt"
    marker.write_text("keep")

    with pytest.raises(BackupValidationError):
        backup.restore_backup(archive, existing)
    assert marker.read_text() == "keep"

    target = tmp_path / "new-target"
    monkeypatch.setattr(
        backup,
        "_validate_restored_database",
        lambda *_: (_ for _ in ()).throw(BackupValidationError("injected")),
    )
    with pytest.raises(BackupValidationError):
        backup.restore_backup(archive, target)
    assert not target.exists()


def test_snapshot_and_archive_rename_failure_leave_no_final(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    source = tmp_path / "source"
    seed(source)
    snapshot_output = tmp_path / "snapshot-failed.zip"
    snapshot_backup = BackupService(source)
    monkeypatch.setattr(
        snapshot_backup,
        "_snapshot_database",
        lambda *_: (_ for _ in ()).throw(OSError("snapshot failed")),
    )
    with pytest.raises(BackupValidationError):
        snapshot_backup.create_backup(snapshot_output)
    assert not snapshot_output.exists()

    rename_output = tmp_path / "rename-failed.zip"
    rename_backup = BackupService(source)
    monkeypatch.setattr(
        rename_backup,
        "_atomic_move",
        lambda *_: (_ for _ in ()).throw(OSError("rename failed")),
    )
    with pytest.raises(BackupValidationError):
        rename_backup.create_backup(rename_output)
    assert not rename_output.exists()

    write_output = tmp_path / "write-failed.zip"
    write_backup = BackupService(source)
    monkeypatch.setattr(
        write_backup,
        "_write_backup_archive",
        lambda *_: (_ for _ in ()).throw(OSError("archive write failed")),
    )
    with pytest.raises(BackupValidationError):
        write_backup.create_backup(write_output)
    assert not write_output.exists()


def test_existing_backup_output_is_not_overwritten(tmp_path: Path) -> None:
    source = tmp_path / "source"
    seed(source)
    output = tmp_path / "existing.zip"
    output.write_bytes(b"keep")

    with pytest.raises(FileExistsError):
        BackupService(source).create_backup(output)

    assert output.read_bytes() == b"keep"
