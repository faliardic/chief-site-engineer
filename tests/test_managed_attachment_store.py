import hashlib
import io
import os
from dataclasses import replace
from pathlib import Path

import pytest

from app.persistence import AttachmentMetadataRecord
from app.storage import (
    AttachmentCollisionError,
    AttachmentIOError,
    ManagedAttachmentStore,
    SourceFileError,
    UnsafeAttachmentPathError,
)


def test_stage_stream_accepts_empty_file_and_uses_managed_paths(tmp_path: Path) -> None:
    store = ManagedAttachmentStore(tmp_path / "managed", chunk_size=2)
    staged = store.stage_stream(
        io.BytesIO(b""),
        "../../empty.TXT",
        OBSERVATION_ID,
        ATTACHMENT_ID,
    )

    assert staged.size_bytes == 0
    assert staged.sha256 == hashlib.sha256(b"").hexdigest()
    assert staged.final_relative_path == (
        f"attachments/{OBSERVATION_ID}/{ATTACHMENT_ID}.txt"
    )
    assert (store.root / staged.staging_relative_path).is_file()


OBSERVATION_ID = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"
ATTACHMENT_ID = "dddddddd-dddd-4ddd-8ddd-dddddddddddd"
T1 = "2026-07-13T08:00:00Z"


def _managed_path(root: Path, relative_path: str) -> Path:
    return root.joinpath(*relative_path.split("/"))


def _metadata(
    staged: object,
    final_relative_path: str,
    *,
    sha256: str | None = None,
    size_bytes: int | None = None,
) -> AttachmentMetadataRecord:
    return AttachmentMetadataRecord(
        attachment_id=staged.attachment_id,
        observation_id=staged.observation_id,
        original_name=staged.original_name,
        stored_relative_path=final_relative_path,
        sha256=sha256 or staged.sha256,
        size_bytes=staged.size_bytes if size_bytes is None else size_bytes,
        mime_type=staged.mime_type,
        status="active",
        created_at=T1,
        created_by="Santiye sefi",
    )


def _symlink_or_skip(link: Path, target: Path, *, is_directory: bool = False) -> None:
    try:
        link.symlink_to(target, target_is_directory=is_directory)
    except (NotImplementedError, OSError) as exc:
        pytest.skip(f"symlink creation is unavailable: {exc}")


def test_stage_copy_streams_real_bytes_and_calculates_hash_and_size(
    tmp_path: Path,
) -> None:
    source = tmp_path / "Saha Fotoğrafı.JPG"
    content = b"0123456789" * 25
    source.write_bytes(content)
    store_root = tmp_path / "managed"
    store = ManagedAttachmentStore(store_root, chunk_size=7)

    staged = store.stage_copy(source, OBSERVATION_ID, ATTACHMENT_ID)

    assert staged.original_name == source.name
    assert staged.staging_relative_path == f"staging/{ATTACHMENT_ID}.part"
    assert staged.final_relative_path == (
        f"attachments/{OBSERVATION_ID}/{ATTACHMENT_ID}.jpg"
    )
    assert staged.sha256 == hashlib.sha256(content).hexdigest()
    assert staged.size_bytes == len(content)
    assert staged.mime_type == "image/jpeg"
    assert _managed_path(store_root, staged.staging_relative_path).read_bytes() == content
    assert source.read_bytes() == content


def test_finalize_keeps_managed_copy_readable_after_source_is_deleted(
    tmp_path: Path,
) -> None:
    source = tmp_path / "evidence.pdf"
    content = b"real attachment content"
    source.write_bytes(content)
    store = ManagedAttachmentStore(tmp_path / "managed")
    staged = store.stage_copy(source, OBSERVATION_ID, ATTACHMENT_ID)
    final_relative_path = store.finalize(staged)
    metadata = _metadata(staged, final_relative_path)
    source.unlink()

    verification = store.verify(metadata)
    with store.open_read(metadata) as managed_file:
        reopened_content = managed_file.read()

    assert verification.status == "valid"
    assert verification.valid is True
    assert reopened_content == content


def test_original_name_never_controls_final_basename_and_unsafe_suffix_falls_back(
    tmp_path: Path,
) -> None:
    source = tmp_path / "customer-name.extensiontoolong"
    source.write_bytes(b"content")
    store = ManagedAttachmentStore(tmp_path / "managed")

    staged = store.stage_copy(source, OBSERVATION_ID, ATTACHMENT_ID)

    assert staged.original_name == "customer-name.extensiontoolong"
    assert staged.final_relative_path == (
        f"attachments/{OBSERVATION_ID}/{ATTACHMENT_ID}.bin"
    )
    assert "customer-name" not in staged.final_relative_path


@pytest.mark.parametrize("source_kind", ["directory", "broken_symlink", "special"])
def test_stage_copy_rejects_non_regular_sources(
    tmp_path: Path,
    source_kind: str,
) -> None:
    store = ManagedAttachmentStore(tmp_path / "managed")
    if source_kind == "directory":
        source = tmp_path / "directory"
        source.mkdir()
    elif source_kind == "broken_symlink":
        source = tmp_path / "broken-link"
        _symlink_or_skip(source, tmp_path / "missing-target")
    else:
        source = Path(os.devnull)

    with pytest.raises(SourceFileError):
        store.stage_copy(source, OBSERVATION_ID, ATTACHMENT_ID)


def test_stage_copy_rejects_source_symlink(tmp_path: Path) -> None:
    target = tmp_path / "target.jpg"
    target.write_bytes(b"content")
    source = tmp_path / "source-link.jpg"
    _symlink_or_skip(source, target)
    store = ManagedAttachmentStore(tmp_path / "managed")

    with pytest.raises(SourceFileError, match="symlink"):
        store.stage_copy(source, OBSERVATION_ID, ATTACHMENT_ID)


def test_store_rejects_symlink_root(tmp_path: Path) -> None:
    real_root = tmp_path / "real-root"
    real_root.mkdir()
    linked_root = tmp_path / "linked-root"
    _symlink_or_skip(linked_root, real_root, is_directory=True)

    with pytest.raises(UnsafeAttachmentPathError, match="symlink"):
        ManagedAttachmentStore(linked_root)


def test_stage_copy_rejects_staging_symlink(tmp_path: Path) -> None:
    source = tmp_path / "photo.jpg"
    source.write_bytes(b"content")
    root = tmp_path / "managed"
    store = ManagedAttachmentStore(root)
    outside = tmp_path / "outside.part"
    outside.write_bytes(b"outside")
    staging_link = root / "staging" / f"{ATTACHMENT_ID}.part"
    _symlink_or_skip(staging_link, outside)

    with pytest.raises(UnsafeAttachmentPathError, match="symlink"):
        store.stage_copy(source, OBSERVATION_ID, ATTACHMENT_ID)

    assert outside.read_bytes() == b"outside"


def test_existing_staging_and_final_destination_are_not_overwritten(
    tmp_path: Path,
) -> None:
    source = tmp_path / "photo.jpg"
    source.write_bytes(b"first content")
    root = tmp_path / "managed"
    store = ManagedAttachmentStore(root)
    first_stage = store.stage_copy(source, OBSERVATION_ID, ATTACHMENT_ID)
    staging_path = _managed_path(root, first_stage.staging_relative_path)

    with pytest.raises(AttachmentCollisionError, match="staging"):
        store.stage_copy(source, OBSERVATION_ID, ATTACHMENT_ID)
    assert staging_path.read_bytes() == b"first content"

    final_path = store.finalize(first_stage)
    second_stage = store.stage_copy(source, OBSERVATION_ID, ATTACHMENT_ID)
    with pytest.raises(AttachmentCollisionError, match="destination"):
        store.finalize(second_stage)

    assert _managed_path(root, final_path).read_bytes() == b"first content"
    assert _managed_path(root, second_stage.staging_relative_path).exists()


@pytest.mark.parametrize("failure_point", ["read", "fsync"])
def test_copy_or_fsync_failure_cleans_partial_staging_and_leaves_no_final(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
    failure_point: str,
) -> None:
    source = tmp_path / "photo.jpg"
    source.write_bytes(b"content")
    root = tmp_path / "managed"
    store = ManagedAttachmentStore(root)
    if failure_point == "read":
        monkeypatch.setattr(
            store,
            "_read_chunk",
            lambda source_file: (_ for _ in ()).throw(OSError("read failure")),
        )
    else:
        monkeypatch.setattr(
            store,
            "_flush_and_sync",
            lambda staging_file: (_ for _ in ()).throw(OSError("fsync failure")),
        )

    with pytest.raises(AttachmentIOError, match="failure"):
        store.stage_copy(source, OBSERVATION_ID, ATTACHMENT_ID)

    assert not (root / "staging" / f"{ATTACHMENT_ID}.part").exists()
    assert not (root / "attachments" / OBSERVATION_ID).exists()
    assert source.read_bytes() == b"content"


def test_finalize_failure_preserves_staging_and_leaves_no_final(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    source = tmp_path / "photo.jpg"
    source.write_bytes(b"content")
    root = tmp_path / "managed"
    store = ManagedAttachmentStore(root)
    staged = store.stage_copy(source, OBSERVATION_ID, ATTACHMENT_ID)
    monkeypatch.setattr(
        store,
        "_atomic_move",
        lambda source_path, destination_path: (_ for _ in ()).throw(
            OSError("rename failure")
        ),
    )

    with pytest.raises(AttachmentIOError, match="rename failure"):
        store.finalize(staged)

    assert _managed_path(root, staged.staging_relative_path).exists()
    assert not _managed_path(root, staged.final_relative_path).exists()
    report = store.reconcile([])
    assert report.stale_staging_files == (staged.staging_relative_path,)


def test_discard_only_removes_verified_staging_file(tmp_path: Path) -> None:
    source = tmp_path / "photo.jpg"
    source.write_bytes(b"content")
    root = tmp_path / "managed"
    store = ManagedAttachmentStore(root)
    staged = store.stage_copy(source, OBSERVATION_ID, ATTACHMENT_ID)
    unsafe = replace(staged, staging_relative_path=staged.final_relative_path)

    with pytest.raises(UnsafeAttachmentPathError):
        store.discard_staged(unsafe)
    assert _managed_path(root, staged.staging_relative_path).exists()

    store.discard_staged(staged)
    assert not _managed_path(root, staged.staging_relative_path).exists()


def test_verify_distinguishes_valid_missing_size_hash_and_unsafe_path(
    tmp_path: Path,
) -> None:
    source = tmp_path / "photo.jpg"
    source.write_bytes(b"content")
    store = ManagedAttachmentStore(tmp_path / "managed")
    staged = store.stage_copy(source, OBSERVATION_ID, ATTACHMENT_ID)
    final_path = store.finalize(staged)
    valid = _metadata(staged, final_path)

    assert store.verify(valid).status == "valid"
    assert store.verify(replace(valid, size_bytes=999)).status == "size_mismatch"
    assert store.verify(replace(valid, sha256="0" * 64)).status == "hash_mismatch"
    assert store.verify(replace(valid, stored_relative_path="../escape")).status == (
        "unsafe_path"
    )

    _managed_path(store.root, final_path).unlink()
    assert store.verify(valid).status == "missing"


def test_open_read_rejects_unsafe_path(tmp_path: Path) -> None:
    store = ManagedAttachmentStore(tmp_path / "managed")
    metadata = AttachmentMetadataRecord(
        attachment_id=ATTACHMENT_ID,
        observation_id=OBSERVATION_ID,
        original_name="outside.jpg",
        stored_relative_path="../outside.jpg",
        sha256=hashlib.sha256(b"outside").hexdigest(),
        size_bytes=7,
        mime_type="image/jpeg",
        status="active",
        created_at=T1,
        created_by=None,
    )

    with pytest.raises(UnsafeAttachmentPathError):
        with store.open_read(metadata):
            pass


def test_open_read_rejects_final_symlink(tmp_path: Path) -> None:
    root = tmp_path / "managed"
    store = ManagedAttachmentStore(root)
    outside = tmp_path / "outside.jpg"
    outside.write_bytes(b"outside")
    final_relative = f"attachments/{OBSERVATION_ID}/{ATTACHMENT_ID}.jpg"
    final_path = _managed_path(root, final_relative)
    final_path.parent.mkdir(parents=True)
    _symlink_or_skip(final_path, outside)
    metadata = AttachmentMetadataRecord(
        attachment_id=ATTACHMENT_ID,
        observation_id=OBSERVATION_ID,
        original_name="outside.jpg",
        stored_relative_path=final_relative,
        sha256=hashlib.sha256(b"outside").hexdigest(),
        size_bytes=7,
        mime_type="image/jpeg",
        status="active",
        created_at=T1,
        created_by=None,
    )

    assert store.verify(metadata).status == "unsafe_path"
    with pytest.raises(UnsafeAttachmentPathError):
        with store.open_read(metadata):
            pass


def test_finalize_rejects_managed_symlink_component(tmp_path: Path) -> None:
    source = tmp_path / "photo.jpg"
    source.write_bytes(b"content")
    root = tmp_path / "managed"
    store = ManagedAttachmentStore(root)
    staged = store.stage_copy(source, OBSERVATION_ID, ATTACHMENT_ID)
    external_directory = tmp_path / "external"
    external_directory.mkdir()
    observation_directory = root / "attachments" / OBSERVATION_ID
    _symlink_or_skip(observation_directory, external_directory, is_directory=True)

    with pytest.raises(UnsafeAttachmentPathError, match="symlink"):
        store.finalize(staged)

    assert _managed_path(root, staged.staging_relative_path).exists()
    assert list(external_directory.iterdir()) == []
