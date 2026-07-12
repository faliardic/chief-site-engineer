"""Managed attachment file store with explicit integrity and safety checks."""

import hashlib
import mimetypes
import os
import stat
from collections.abc import Iterable, Iterator
from contextlib import contextmanager
from dataclasses import dataclass
from pathlib import Path
from typing import TYPE_CHECKING, BinaryIO

from .paths import (
    build_attachment_relative_path,
    build_staging_relative_path,
    validate_attachment_relative_path,
    validate_canonical_uuid,
    validate_posix_relative_path,
    validate_staging_relative_path,
)

if TYPE_CHECKING:
    from app.persistence.records import AttachmentMetadataRecord


class AttachmentStoreError(Exception):
    """Base class for managed attachment store errors."""


class UnsafeAttachmentPathError(AttachmentStoreError):
    """A path escapes or violates the managed-root contract."""


class SourceFileError(AttachmentStoreError):
    """The source is missing, unsafe or not a regular file."""


class AttachmentCollisionError(AttachmentStoreError):
    """A staging or final destination already exists."""


class AttachmentIntegrityError(AttachmentStoreError):
    """Staged or finalized bytes do not match their integrity contract."""


class AttachmentIOError(AttachmentStoreError):
    """A copy, flush, fsync, read or rename operation failed."""


class StagingCleanupError(AttachmentIOError):
    """A failed stage copy also failed to remove its partial staging file."""


@dataclass(frozen=True)
class StagedAttachment:
    attachment_id: str
    observation_id: str
    original_name: str
    staging_relative_path: str
    final_relative_path: str
    sha256: str
    size_bytes: int
    mime_type: str | None


@dataclass(frozen=True)
class AttachmentVerification:
    status: str
    relative_path: str
    expected_sha256: str
    actual_sha256: str | None
    expected_size_bytes: int
    actual_size_bytes: int | None

    @property
    def valid(self) -> bool:
        return self.status == "valid"


@dataclass(frozen=True)
class AttachmentReconciliationReport:
    valid_attachment_ids: tuple[str, ...]
    missing_attachment_ids: tuple[str, ...]
    size_mismatch_attachment_ids: tuple[str, ...]
    hash_mismatch_attachment_ids: tuple[str, ...]
    unsafe_metadata_attachment_ids: tuple[str, ...]
    orphan_finalized_files: tuple[str, ...]
    stale_staging_files: tuple[str, ...]
    unsafe_files: tuple[str, ...]

    def to_dict(self) -> dict[str, list[str]]:
        return {
            "valid_attachment_ids": list(self.valid_attachment_ids),
            "missing_attachment_ids": list(self.missing_attachment_ids),
            "size_mismatch_attachment_ids": list(
                self.size_mismatch_attachment_ids
            ),
            "hash_mismatch_attachment_ids": list(
                self.hash_mismatch_attachment_ids
            ),
            "unsafe_metadata_attachment_ids": list(
                self.unsafe_metadata_attachment_ids
            ),
            "orphan_finalized_files": list(self.orphan_finalized_files),
            "stale_staging_files": list(self.stale_staging_files),
            "unsafe_files": list(self.unsafe_files),
        }


class ManagedAttachmentStore:
    """Store attachment bytes below one explicit managed root."""

    def __init__(self, root: str | Path, *, chunk_size: int = 1024 * 1024) -> None:
        if not isinstance(chunk_size, int) or isinstance(chunk_size, bool) or chunk_size < 1:
            raise ValueError("chunk_size must be a positive integer")
        self.root = Path(os.path.abspath(os.fspath(root)))
        self.chunk_size = chunk_size
        self._initialize_root()

    def stage_copy(
        self,
        source_path: str | Path,
        observation_id: str,
        attachment_id: str,
    ) -> StagedAttachment:
        try:
            validate_canonical_uuid(observation_id, "observation_id")
            validate_canonical_uuid(attachment_id, "attachment_id")
        except ValueError as exc:
            raise UnsafeAttachmentPathError(str(exc)) from exc

        source = Path(source_path)
        source_stat = self._validate_source(source)
        original_name = source.name
        staging_relative = build_staging_relative_path(attachment_id)
        final_relative = build_attachment_relative_path(
            observation_id,
            attachment_id,
            original_name,
        )
        staging_path = self._managed_path(staging_relative)
        created_staging = False

        try:
            with self._open_source(source, source_stat) as source_file:
                try:
                    staging_file = staging_path.open("xb")
                except FileExistsError as exc:
                    raise AttachmentCollisionError(
                        f"staging destination already exists: {staging_relative}"
                    ) from exc
                created_staging = True
                with staging_file:
                    digest = hashlib.sha256()
                    size_bytes = 0
                    while True:
                        chunk = self._read_chunk(source_file)
                        if not chunk:
                            break
                        written = staging_file.write(chunk)
                        if written != len(chunk):
                            raise OSError("partial staging write")
                        digest.update(chunk)
                        size_bytes += written
                    self._flush_and_sync(staging_file)
        except AttachmentCollisionError:
            raise
        except Exception as exc:
            if created_staging:
                try:
                    staging_path.unlink(missing_ok=True)
                except OSError as cleanup_error:
                    raise StagingCleanupError(
                        f"stage copy failed ({exc}); cleanup failed ({cleanup_error})"
                    ) from cleanup_error
            if isinstance(exc, AttachmentStoreError):
                raise
            raise AttachmentIOError(str(exc)) from exc

        mime_type, _ = mimetypes.guess_type(original_name)
        return StagedAttachment(
            attachment_id=attachment_id,
            observation_id=observation_id,
            original_name=original_name,
            staging_relative_path=staging_relative,
            final_relative_path=final_relative,
            sha256=digest.hexdigest(),
            size_bytes=size_bytes,
            mime_type=mime_type,
        )

    def finalize(self, staged: StagedAttachment) -> str:
        self._validate_staged_descriptor(staged)
        staging_path = self._managed_path(staged.staging_relative_path)
        self._require_regular_managed_file(staging_path, "staging file")
        actual_sha256, actual_size = self._hash_managed_file(staging_path)
        if actual_size != staged.size_bytes or actual_sha256 != staged.sha256:
            raise AttachmentIntegrityError("staging file hash or size mismatch")

        final_path = self._managed_path(staged.final_relative_path, check_final=False)
        self._ensure_directory(final_path.parent)
        self._assert_no_symlink_components(final_path)
        if final_path.exists():
            raise AttachmentCollisionError(
                f"final destination already exists: {staged.final_relative_path}"
            )
        try:
            self._atomic_move(staging_path, final_path)
        except OSError as exc:
            raise AttachmentIOError(str(exc)) from exc
        return staged.final_relative_path

    def discard_staged(self, staged: StagedAttachment) -> None:
        self._validate_staged_descriptor(staged)
        staging_path = self._managed_path(staged.staging_relative_path)
        self._require_regular_managed_file(staging_path, "staging file")
        try:
            staging_path.unlink()
        except OSError as exc:
            raise AttachmentIOError(str(exc)) from exc

    def verify(self, metadata: "AttachmentMetadataRecord") -> AttachmentVerification:
        try:
            validate_attachment_relative_path(
                metadata.stored_relative_path,
                metadata.observation_id,
                metadata.attachment_id,
            )
            path = self._managed_path(metadata.stored_relative_path)
        except (ValueError, UnsafeAttachmentPathError):
            return self._verification(metadata, "unsafe_path", None, None)

        if not path.exists() and not path.is_symlink():
            return self._verification(metadata, "missing", None, None)
        try:
            actual_sha256, actual_size = self._hash_managed_file(path)
        except UnsafeAttachmentPathError:
            return self._verification(metadata, "unsafe_path", None, None)
        except AttachmentIOError:
            if not path.exists():
                return self._verification(metadata, "missing", None, None)
            raise

        if actual_size != metadata.size_bytes:
            return self._verification(
                metadata,
                "size_mismatch",
                actual_sha256,
                actual_size,
            )
        if actual_sha256 != metadata.sha256:
            return self._verification(
                metadata,
                "hash_mismatch",
                actual_sha256,
                actual_size,
            )
        return self._verification(metadata, "valid", actual_sha256, actual_size)

    @contextmanager
    def open_read(
        self,
        metadata: "AttachmentMetadataRecord",
    ) -> Iterator[BinaryIO]:
        try:
            validate_attachment_relative_path(
                metadata.stored_relative_path,
                metadata.observation_id,
                metadata.attachment_id,
            )
            path = self._managed_path(metadata.stored_relative_path)
        except ValueError as exc:
            raise UnsafeAttachmentPathError(str(exc)) from exc
        with self._open_managed_regular(path) as file_handle:
            yield file_handle

    def reconcile(
        self,
        metadata_records: Iterable["AttachmentMetadataRecord"],
    ) -> AttachmentReconciliationReport:
        valid: list[str] = []
        missing: list[str] = []
        size_mismatch: list[str] = []
        hash_mismatch: list[str] = []
        unsafe_metadata: list[str] = []
        known_paths: set[str] = set()

        records = sorted(metadata_records, key=lambda record: record.attachment_id)
        for record in records:
            verification = self.verify(record)
            if verification.status != "unsafe_path":
                known_paths.add(record.stored_relative_path)
            category = {
                "valid": valid,
                "missing": missing,
                "size_mismatch": size_mismatch,
                "hash_mismatch": hash_mismatch,
                "unsafe_path": unsafe_metadata,
            }[verification.status]
            category.append(record.attachment_id)

        orphan_files, unsafe_final_files = self._scan_finalized_files(known_paths)
        stale_staging, unsafe_staging_files = self._scan_staging_files()
        return AttachmentReconciliationReport(
            valid_attachment_ids=tuple(sorted(valid)),
            missing_attachment_ids=tuple(sorted(missing)),
            size_mismatch_attachment_ids=tuple(sorted(size_mismatch)),
            hash_mismatch_attachment_ids=tuple(sorted(hash_mismatch)),
            unsafe_metadata_attachment_ids=tuple(sorted(unsafe_metadata)),
            orphan_finalized_files=tuple(sorted(orphan_files)),
            stale_staging_files=tuple(sorted(stale_staging)),
            unsafe_files=tuple(
                sorted((*unsafe_final_files, *unsafe_staging_files))
            ),
        )

    def _initialize_root(self) -> None:
        self._assert_no_symlink_components(self.root)
        if self.root.exists() and not self.root.is_dir():
            raise UnsafeAttachmentPathError("managed root must be a directory")
        self.root.mkdir(parents=True, exist_ok=True)
        self._assert_no_symlink_components(self.root)
        self._ensure_directory(self.root / "staging")
        self._ensure_directory(self.root / "attachments")

    def _managed_path(
        self,
        relative_path: str,
        *,
        check_final: bool = True,
    ) -> Path:
        try:
            relative = validate_posix_relative_path(relative_path)
        except ValueError as exc:
            raise UnsafeAttachmentPathError(str(exc)) from exc
        candidate = self.root.joinpath(*relative.parts)
        if os.path.commonpath((self.root, candidate)) != os.fspath(self.root):
            raise UnsafeAttachmentPathError("path escapes managed root")
        target = candidate if check_final else candidate.parent
        self._assert_no_symlink_components(target)
        return candidate

    def _ensure_directory(self, directory: Path) -> None:
        if os.path.commonpath((self.root, directory)) != os.fspath(self.root):
            raise UnsafeAttachmentPathError("directory escapes managed root")
        relative_parts = directory.relative_to(self.root).parts
        current = self.root
        for part in relative_parts:
            current = current / part
            if current.is_symlink():
                raise UnsafeAttachmentPathError(
                    f"managed path contains symlink: {current}"
                )
            if current.exists():
                if not current.is_dir():
                    raise UnsafeAttachmentPathError(
                        f"managed directory component is not a directory: {current}"
                    )
            else:
                current.mkdir()

    def _assert_no_symlink_components(self, path: Path) -> None:
        absolute = Path(os.path.abspath(os.fspath(path)))
        current = Path(absolute.anchor)
        for part in absolute.parts[1:]:
            current = current / part
            if current.is_symlink():
                raise UnsafeAttachmentPathError(
                    f"managed path contains symlink: {current}"
                )

    def _validate_source(self, source: Path) -> os.stat_result:
        try:
            source_stat = os.lstat(source)
        except OSError as exc:
            raise SourceFileError(f"source file is unavailable: {source}") from exc
        if stat.S_ISLNK(source_stat.st_mode):
            raise SourceFileError("source file cannot be a symlink")
        if not stat.S_ISREG(source_stat.st_mode):
            raise SourceFileError("source must be a regular file")
        return source_stat

    @contextmanager
    def _open_source(
        self,
        source: Path,
        expected_stat: os.stat_result,
    ) -> Iterator[BinaryIO]:
        flags = os.O_RDONLY | getattr(os, "O_BINARY", 0) | getattr(os, "O_NOFOLLOW", 0)
        try:
            descriptor = os.open(source, flags)
        except OSError as exc:
            raise SourceFileError(f"source file could not be opened: {source}") from exc
        try:
            opened_stat = os.fstat(descriptor)
            if not stat.S_ISREG(opened_stat.st_mode):
                raise SourceFileError("opened source is not a regular file")
            if (opened_stat.st_dev, opened_stat.st_ino) != (
                expected_stat.st_dev,
                expected_stat.st_ino,
            ):
                raise SourceFileError("source file changed before copy")
            with os.fdopen(descriptor, "rb") as file_handle:
                descriptor = -1
                yield file_handle
        finally:
            if descriptor >= 0:
                os.close(descriptor)

    @contextmanager
    def _open_managed_regular(self, path: Path) -> Iterator[BinaryIO]:
        self._assert_no_symlink_components(path)
        try:
            before = os.lstat(path)
        except OSError as exc:
            raise AttachmentIOError(f"managed file is unavailable: {path}") from exc
        if stat.S_ISLNK(before.st_mode) or not stat.S_ISREG(before.st_mode):
            raise UnsafeAttachmentPathError("managed file must be regular and non-symlink")
        flags = os.O_RDONLY | getattr(os, "O_BINARY", 0) | getattr(os, "O_NOFOLLOW", 0)
        try:
            descriptor = os.open(path, flags)
        except OSError as exc:
            raise AttachmentIOError(f"managed file could not be opened: {path}") from exc
        try:
            opened = os.fstat(descriptor)
            if not stat.S_ISREG(opened.st_mode):
                raise UnsafeAttachmentPathError("opened managed file is not regular")
            if (opened.st_dev, opened.st_ino) != (before.st_dev, before.st_ino):
                raise UnsafeAttachmentPathError("managed file changed before open")
            with os.fdopen(descriptor, "rb") as file_handle:
                descriptor = -1
                yield file_handle
        finally:
            if descriptor >= 0:
                os.close(descriptor)

    def _require_regular_managed_file(self, path: Path, label: str) -> None:
        self._assert_no_symlink_components(path)
        try:
            file_stat = os.lstat(path)
        except OSError as exc:
            raise AttachmentIOError(f"{label} is unavailable") from exc
        if stat.S_ISLNK(file_stat.st_mode) or not stat.S_ISREG(file_stat.st_mode):
            raise UnsafeAttachmentPathError(f"{label} must be regular and non-symlink")

    def _validate_staged_descriptor(self, staged: StagedAttachment) -> None:
        try:
            validate_staging_relative_path(
                staged.staging_relative_path,
                staged.attachment_id,
            )
            expected_final = build_attachment_relative_path(
                staged.observation_id,
                staged.attachment_id,
                staged.original_name,
            )
        except ValueError as exc:
            raise UnsafeAttachmentPathError(str(exc)) from exc
        if staged.final_relative_path != expected_final:
            raise UnsafeAttachmentPathError("final path does not match staged metadata")

    def _hash_managed_file(self, path: Path) -> tuple[str, int]:
        digest = hashlib.sha256()
        size = 0
        with self._open_managed_regular(path) as file_handle:
            while True:
                chunk = file_handle.read(self.chunk_size)
                if not chunk:
                    break
                digest.update(chunk)
                size += len(chunk)
        return digest.hexdigest(), size

    def _verification(
        self,
        metadata: "AttachmentMetadataRecord",
        status: str,
        actual_sha256: str | None,
        actual_size: int | None,
    ) -> AttachmentVerification:
        return AttachmentVerification(
            status=status,
            relative_path=metadata.stored_relative_path,
            expected_sha256=metadata.sha256,
            actual_sha256=actual_sha256,
            expected_size_bytes=metadata.size_bytes,
            actual_size_bytes=actual_size,
        )

    def _scan_finalized_files(
        self,
        known_paths: set[str],
    ) -> tuple[list[str], list[str]]:
        orphan_files: list[str] = []
        unsafe_files: list[str] = []
        attachments_root = self.root / "attachments"
        for directory, directory_names, file_names in os.walk(
            attachments_root,
            topdown=True,
            followlinks=False,
        ):
            directory_path = Path(directory)
            for name in list(directory_names):
                child = directory_path / name
                if child.is_symlink():
                    unsafe_files.append(child.relative_to(self.root).as_posix())
                    directory_names.remove(name)
            for name in file_names:
                child = directory_path / name
                relative = child.relative_to(self.root).as_posix()
                if child.is_symlink() or not child.is_file():
                    unsafe_files.append(relative)
                elif relative not in known_paths:
                    orphan_files.append(relative)
        return orphan_files, unsafe_files

    def _scan_staging_files(self) -> tuple[list[str], list[str]]:
        stale_files: list[str] = []
        unsafe_files: list[str] = []
        staging_root = self.root / "staging"
        for child in sorted(staging_root.iterdir(), key=lambda path: path.name):
            relative = child.relative_to(self.root).as_posix()
            if child.is_symlink() or not child.is_file():
                unsafe_files.append(relative)
            else:
                stale_files.append(relative)
        return stale_files, unsafe_files

    def _read_chunk(self, source_file: BinaryIO) -> bytes:
        return source_file.read(self.chunk_size)

    def _flush_and_sync(self, staging_file: BinaryIO) -> None:
        staging_file.flush()
        os.fsync(staging_file.fileno())

    def _atomic_move(self, source: Path, destination: Path) -> None:
        os.rename(source, destination)
