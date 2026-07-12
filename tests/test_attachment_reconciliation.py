import hashlib
from pathlib import Path

import pytest

from app.models import FieldObservationRecord
from app.persistence import (
    AttachmentMetadataRecord,
    ProjectRecord,
    SQLiteUnitOfWork,
)
from app.storage import ManagedAttachmentStore


PROJECT_ID = "11111111-1111-4111-8111-111111111111"
OBSERVATION_ID = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"
ATTACHMENT_ID = "dddddddd-dddd-4ddd-8ddd-dddddddddddd"
SECOND_ATTACHMENT_ID = "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee"
THIRD_ATTACHMENT_ID = "ffffffff-ffff-4fff-8fff-ffffffffffff"
FOURTH_ATTACHMENT_ID = "99999999-9999-4999-8999-999999999999"
T1 = "2026-07-13T08:00:00Z"


def _observation() -> FieldObservationRecord:
    return FieldObservationRecord(
        observation_id=OBSERVATION_ID,
        project_id=PROJECT_ID,
        observed_at=T1,
        location="A Blok 2. Kat",
        category="quality",
        description="Kalip birlesiminde aciklik goruldu.",
        created_at=T1,
        updated_at=T1,
    )


def _metadata(staged: object, final_path: str) -> AttachmentMetadataRecord:
    return AttachmentMetadataRecord(
        attachment_id=staged.attachment_id,
        observation_id=staged.observation_id,
        original_name=staged.original_name,
        stored_relative_path=final_path,
        sha256=staged.sha256,
        size_bytes=staged.size_bytes,
        mime_type=staged.mime_type,
        status="active",
        created_at=T1,
        created_by="Santiye sefi",
    )


def _seed_observation(database_path: Path) -> None:
    with SQLiteUnitOfWork(database_path) as unit_of_work:
        unit_of_work.projects.add(ProjectRecord(PROJECT_ID, "Ornek Santiye", T1))
        unit_of_work.observations.add(_observation())
        unit_of_work.commit()


def _write_source(path: Path, content: bytes) -> Path:
    path.write_bytes(content)
    return path


def _snapshot_files(root: Path) -> dict[str, bytes]:
    return {
        path.relative_to(root).as_posix(): path.read_bytes()
        for path in sorted(root.rglob("*"))
        if path.is_file() and not path.is_symlink()
    }


def _symlink_or_skip(link: Path, target: Path) -> None:
    try:
        link.symlink_to(target)
    except (NotImplementedError, OSError) as exc:
        pytest.skip(f"symlink creation is unavailable: {exc}")


def test_stage_finalize_metadata_commit_reopens_and_verifies_valid(
    tmp_path: Path,
) -> None:
    database_path = tmp_path / "cse.sqlite3"
    root = tmp_path / "managed"
    source = _write_source(tmp_path / "photo.jpg", b"field evidence")
    _seed_observation(database_path)
    first_store = ManagedAttachmentStore(root)
    staged = first_store.stage_copy(source, OBSERVATION_ID, ATTACHMENT_ID)
    final_path = first_store.finalize(staged)
    metadata = _metadata(staged, final_path)

    with SQLiteUnitOfWork(database_path) as unit_of_work:
        unit_of_work.attachments.add(metadata)
        unit_of_work.commit()

    second_store = ManagedAttachmentStore(root)
    with SQLiteUnitOfWork(database_path) as reopened:
        stored_metadata = reopened.attachments.get(ATTACHMENT_ID)

    assert stored_metadata == metadata
    assert second_store.verify(stored_metadata).status == "valid"


def test_reconciliation_reports_orphan_missing_hash_size_and_staging(
    tmp_path: Path,
) -> None:
    root = tmp_path / "managed"
    store = ManagedAttachmentStore(root)

    valid_stage = store.stage_copy(
        _write_source(tmp_path / "valid.jpg", b"valid"),
        OBSERVATION_ID,
        ATTACHMENT_ID,
    )
    valid_path = store.finalize(valid_stage)
    valid = _metadata(valid_stage, valid_path)

    hash_stage = store.stage_copy(
        _write_source(tmp_path / "hash.jpg", b"hash content"),
        OBSERVATION_ID,
        SECOND_ATTACHMENT_ID,
    )
    hash_path = store.finalize(hash_stage)
    hash_mismatch = AttachmentMetadataRecord(
        **{**_metadata(hash_stage, hash_path).__dict__, "sha256": "0" * 64}
    )

    size_stage = store.stage_copy(
        _write_source(tmp_path / "size.jpg", b"size content"),
        OBSERVATION_ID,
        THIRD_ATTACHMENT_ID,
    )
    size_path = store.finalize(size_stage)
    size_mismatch = AttachmentMetadataRecord(
        **{**_metadata(size_stage, size_path).__dict__, "size_bytes": 999}
    )

    orphan_stage = store.stage_copy(
        _write_source(tmp_path / "orphan.jpg", b"orphan"),
        OBSERVATION_ID,
        FOURTH_ATTACHMENT_ID,
    )
    orphan_path = store.finalize(orphan_stage)

    stale_id = "77777777-7777-4777-8777-777777777777"
    stale = store.stage_copy(
        _write_source(tmp_path / "stale.jpg", b"stale"),
        OBSERVATION_ID,
        stale_id,
    )

    missing_id = "66666666-6666-4666-8666-666666666666"
    missing = AttachmentMetadataRecord(
        attachment_id=missing_id,
        observation_id=OBSERVATION_ID,
        original_name="missing.jpg",
        stored_relative_path=f"attachments/{OBSERVATION_ID}/{missing_id}.jpg",
        sha256=hashlib.sha256(b"missing").hexdigest(),
        size_bytes=7,
        mime_type="image/jpeg",
        status="active",
        created_at=T1,
        created_by=None,
    )
    unsafe_id = "55555555-5555-4555-8555-555555555555"
    unsafe = AttachmentMetadataRecord(
        attachment_id=unsafe_id,
        observation_id=OBSERVATION_ID,
        original_name="unsafe.jpg",
        stored_relative_path="../outside.jpg",
        sha256="a" * 64,
        size_bytes=1,
        mime_type="image/jpeg",
        status="active",
        created_at=T1,
        created_by=None,
    )

    report = store.reconcile(
        [size_mismatch, unsafe, valid, missing, hash_mismatch]
    )

    assert report.valid_attachment_ids == (ATTACHMENT_ID,)
    assert report.missing_attachment_ids == (missing_id,)
    assert report.hash_mismatch_attachment_ids == (SECOND_ATTACHMENT_ID,)
    assert report.size_mismatch_attachment_ids == (THIRD_ATTACHMENT_ID,)
    assert report.unsafe_metadata_attachment_ids == (unsafe_id,)
    assert report.orphan_finalized_files == (orphan_path,)
    assert report.stale_staging_files == (stale.staging_relative_path,)
    assert report.to_dict()["valid_attachment_ids"] == [ATTACHMENT_ID]


def test_reconciliation_is_read_only_for_files_and_metadata(tmp_path: Path) -> None:
    root = tmp_path / "managed"
    store = ManagedAttachmentStore(root)
    stage = store.stage_copy(
        _write_source(tmp_path / "photo.jpg", b"content"),
        OBSERVATION_ID,
        ATTACHMENT_ID,
    )
    final_path = store.finalize(stage)
    metadata = _metadata(stage, final_path)
    stale = store.stage_copy(
        _write_source(tmp_path / "stale.jpg", b"stale"),
        OBSERVATION_ID,
        SECOND_ATTACHMENT_ID,
    )
    records = [metadata]
    before_files = _snapshot_files(root)
    before_records = tuple(records)

    first_report = store.reconcile(records)
    second_report = store.reconcile(records)

    assert first_report == second_report
    assert first_report.stale_staging_files == (stale.staging_relative_path,)
    assert _snapshot_files(root) == before_files
    assert tuple(records) == before_records


def test_reconciliation_reports_symlink_without_following_it(tmp_path: Path) -> None:
    root = tmp_path / "managed"
    store = ManagedAttachmentStore(root)
    outside = tmp_path / "outside.jpg"
    outside.write_bytes(b"outside")
    unsafe_path = root / "attachments" / "unsafe-link.jpg"
    _symlink_or_skip(unsafe_path, outside)

    report = store.reconcile([])

    assert report.unsafe_files == ("attachments/unsafe-link.jpg",)
    assert report.orphan_finalized_files == ()
    assert outside.read_bytes() == b"outside"
