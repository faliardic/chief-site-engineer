"""Verified SQLite snapshot backup and fail-closed restore."""

import json
import os
import re
import shutil
import sqlite3
import tempfile
import zipfile
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from uuid import uuid4

from app.persistence import AttachmentMetadataRecord, SCHEMA_VERSION
from app.storage import ManagedAttachmentStore
from app.storage.paths import validate_attachment_relative_path

from .common import (
    atomic_rename,
    canonical_json_bytes,
    cleanup_file,
    deterministic_zip_info,
    digest_file,
    digest_stream,
    exclusive_output_path,
    validate_safe_archive_name,
    write_zip_bytes,
    zip_info_is_symlink,
)


BACKUP_FORMAT_VERSION = 1
SHA256_PATTERN = re.compile(r"^[0-9a-f]{64}$")


class BackupValidationError(Exception):
    """A backup or restore input failed a fail-closed validation."""


@dataclass(frozen=True)
class BackupArtifact:
    path: Path
    attachment_count: int
    observation_count: int
    event_count: int


@dataclass(frozen=True)
class RestoreResult:
    target_created: bool
    attachment_count: int


class BackupService:
    def __init__(
        self,
        data_root: str | Path,
        *,
        clock=lambda: datetime.now(timezone.utc).isoformat(timespec="seconds").replace(
            "+00:00", "Z"
        ),
    ) -> None:
        self.data_root = Path(data_root).resolve()
        self.database_path = self.data_root / "cse.sqlite3"
        self._clock = clock

    def create_backup(self, output_path: str | Path) -> BackupArtifact:
        output = exclusive_output_path(output_path)
        work = Path(tempfile.mkdtemp(prefix=".cse-backup-", dir=output.parent))
        temp_archive = work / "archive.tmp"
        snapshot = work / "cse.sqlite3"
        try:
            attachment_store = ManagedAttachmentStore(
                self.data_root / "attachments"
            )
            self._snapshot_database(snapshot)
            metadata, schema_version, observation_count, event_count = (
                _read_snapshot_inventory(snapshot)
            )
            if schema_version != SCHEMA_VERSION:
                raise BackupValidationError("snapshot schema version is unsupported")
            attachment_files: list[tuple[str, Path, dict[str, object]]] = []
            for item in metadata:
                verification = attachment_store.verify(item)
                if not verification.valid:
                    raise BackupValidationError(
                        f"attachment {item.attachment_id} is {verification.status}"
                    )
                source = attachment_store.root.joinpath(
                    *item.stored_relative_path.split("/")
                )
                digest = digest_file(source)
                if digest != {"sha256": item.sha256, "size_bytes": item.size_bytes}:
                    raise BackupValidationError("attachment changed during backup")
                attachment_files.append((item.stored_relative_path, source, digest))
            attachment_files.sort(key=lambda item: item[0])

            files: dict[str, dict[str, object]] = {
                "cse.sqlite3": digest_file(snapshot)
            }
            attachments_manifest: list[dict[str, object]] = []
            for relative, _source, digest in attachment_files:
                files[relative] = digest
                attachments_manifest.append({"path": relative, **digest})
            manifest = {
                "backup_format_version": BACKUP_FORMAT_VERSION,
                "created_at": self._clock(),
                "schema_version": schema_version,
                "attachment_count": len(metadata),
                "observation_count": observation_count,
                "event_count": event_count,
                "files": files,
                "attachments": attachments_manifest,
            }
            self._write_backup_archive(
                temp_archive, snapshot, attachment_files, manifest
            )
            self.verify_backup(temp_archive)
            self._atomic_move(temp_archive, output)
            return BackupArtifact(
                output, len(metadata), observation_count, event_count
            )
        except BackupValidationError:
            cleanup_file(temp_archive)
            raise
        except Exception as exc:
            cleanup_file(temp_archive)
            raise BackupValidationError(f"backup failed: {exc}") from exc
        finally:
            shutil.rmtree(work, ignore_errors=True)

    def verify_backup(self, archive_path: str | Path) -> dict[str, object]:
        archive = Path(archive_path)
        if not archive.is_file():
            raise BackupValidationError("backup archive does not exist")
        try:
            with zipfile.ZipFile(archive) as bundle:
                infos = bundle.infolist()
                names = [info.filename for info in infos]
                if len(names) != len(set(names)):
                    raise BackupValidationError("backup contains duplicate entries")
                for info in infos:
                    try:
                        validate_safe_archive_name(info.filename)
                    except ValueError as exc:
                        raise BackupValidationError(str(exc)) from exc
                    if info.is_dir() or zip_info_is_symlink(info):
                        raise BackupValidationError(
                            "backup contains directory or symlink entry"
                        )
                if "manifest.json" not in names:
                    raise BackupValidationError("backup manifest is missing")
                try:
                    manifest = json.loads(bundle.read("manifest.json"))
                except (KeyError, UnicodeDecodeError, json.JSONDecodeError) as exc:
                    raise BackupValidationError("backup manifest is invalid") from exc
                self._validate_manifest(manifest)
                files = manifest["files"]
                expected_names = {"manifest.json", *files.keys()}
                if set(names) != expected_names:
                    raise BackupValidationError(
                        "backup contains missing or unmanifested entries"
                    )
                for name, expected in files.items():
                    with bundle.open(name) as file_handle:
                        actual = digest_stream(file_handle)
                    if actual != expected:
                        raise BackupValidationError(
                            f"backup file integrity mismatch: {name}"
                        )
                return manifest
        except BackupValidationError:
            raise
        except (OSError, zipfile.BadZipFile) as exc:
            raise BackupValidationError("backup archive is unreadable") from exc

    def restore_backup(
        self, archive_path: str | Path, target_root: str | Path
    ) -> RestoreResult:
        target = Path(target_root).resolve()
        if target.exists():
            raise BackupValidationError("restore target must not exist")
        manifest = self.verify_backup(archive_path)
        target.parent.mkdir(parents=True, exist_ok=True)
        temporary = Path(
            tempfile.mkdtemp(prefix=f".{target.name}.restore-", dir=target.parent)
        )
        moved = False
        try:
            with zipfile.ZipFile(archive_path) as bundle:
                files = manifest["files"]
                self._extract_entry(
                    bundle, "cse.sqlite3", temporary / "cse.sqlite3",
                    files["cse.sqlite3"],
                )
                for name, expected in sorted(files.items()):
                    if name == "cse.sqlite3":
                        continue
                    relative = validate_safe_archive_name(name)
                    destination = temporary / "attachments" / Path(*relative.parts)
                    self._extract_entry(bundle, name, destination, expected)
            self._validate_restored_database(temporary, manifest)
            self._atomic_move(temporary, target)
            moved = True
            return RestoreResult(True, int(manifest["attachment_count"]))
        except BackupValidationError:
            raise
        except Exception as exc:
            raise BackupValidationError(f"restore failed: {exc}") from exc
        finally:
            if not moved:
                try:
                    shutil.rmtree(temporary)
                except OSError as cleanup_error:
                    raise BackupValidationError(
                        f"restore failed and temporary cleanup failed: {cleanup_error}"
                    ) from cleanup_error

    def _snapshot_database(self, destination: Path) -> None:
        if not self.database_path.is_file():
            raise BackupValidationError("source database does not exist")
        source = sqlite3.connect(self.database_path)
        target = sqlite3.connect(destination)
        try:
            source.backup(target)
        finally:
            target.close()
            source.close()

    def _write_backup_archive(
        self,
        path: Path,
        snapshot: Path,
        attachments: list[tuple[str, Path, dict[str, object]]],
        manifest: dict[str, object],
    ) -> None:
        with path.open("xb") as raw:
            with zipfile.ZipFile(raw, "w") as bundle:
                write_zip_bytes(bundle, "manifest.json", canonical_json_bytes(manifest))
                self._write_file_entry(bundle, "cse.sqlite3", snapshot)
                for relative, source, _digest in sorted(attachments):
                    self._write_file_entry(bundle, relative, source)
            raw.flush()
            os.fsync(raw.fileno())

    def _write_file_entry(
        self, bundle: zipfile.ZipFile, name: str, source: Path
    ) -> None:
        with source.open("rb") as incoming, bundle.open(
            deterministic_zip_info(name), "w"
        ) as outgoing:
            while chunk := incoming.read(1024 * 1024):
                outgoing.write(chunk)

    def _extract_entry(
        self,
        bundle: zipfile.ZipFile,
        name: str,
        destination: Path,
        expected: dict[str, object],
    ) -> None:
        destination.parent.mkdir(parents=True, exist_ok=True)
        with bundle.open(name) as source, destination.open("xb") as target:
            digest = __import__("hashlib").sha256()
            size = 0
            while chunk := source.read(1024 * 1024):
                target.write(chunk)
                digest.update(chunk)
                size += len(chunk)
            target.flush()
            os.fsync(target.fileno())
        if {"sha256": digest.hexdigest(), "size_bytes": size} != expected:
            raise BackupValidationError("restored file integrity mismatch")

    def _validate_restored_database(
        self, temporary_root: Path, manifest: dict[str, object]
    ) -> None:
        database = temporary_root / "cse.sqlite3"
        connection = sqlite3.connect(database)
        try:
            integrity = connection.execute("PRAGMA integrity_check").fetchone()[0]
            if integrity != "ok":
                raise BackupValidationError("restored database integrity check failed")
            versions = {
                row[0]
                for row in connection.execute(
                    "SELECT version FROM schema_migrations ORDER BY version"
                )
            }
            if versions != set(range(1, SCHEMA_VERSION + 1)):
                raise BackupValidationError("restored database migration version is unknown")
            metadata = _read_attachment_metadata(connection)
            observation_count = connection.execute(
                "SELECT COUNT(*) FROM field_observations"
            ).fetchone()[0]
            event_count = connection.execute(
                "SELECT COUNT(*) FROM observation_events"
            ).fetchone()[0]
        except sqlite3.DatabaseError as exc:
            raise BackupValidationError("restored database is invalid") from exc
        finally:
            connection.close()
        if observation_count != manifest["observation_count"]:
            raise BackupValidationError("restored observation count mismatch")
        if event_count != manifest["event_count"]:
            raise BackupValidationError("restored event count mismatch")
        store = ManagedAttachmentStore(temporary_root / "attachments")
        report = store.reconcile(metadata)
        if (
            len(report.valid_attachment_ids) != len(metadata)
            or report.missing_attachment_ids
            or report.size_mismatch_attachment_ids
            or report.hash_mismatch_attachment_ids
            or report.unsafe_metadata_attachment_ids
            or report.orphan_finalized_files
            or report.stale_staging_files
            or report.unsafe_files
        ):
            raise BackupValidationError("restored attachment reconciliation failed")

    def _validate_manifest(self, manifest: object) -> None:
        if not isinstance(manifest, dict):
            raise BackupValidationError("backup manifest must be an object")
        required = {
            "backup_format_version",
            "created_at",
            "schema_version",
            "attachment_count",
            "observation_count",
            "event_count",
            "files",
            "attachments",
        }
        if set(manifest) != required:
            raise BackupValidationError("backup manifest fields are invalid")
        if manifest["backup_format_version"] != BACKUP_FORMAT_VERSION:
            raise BackupValidationError("backup format version is unsupported")
        if manifest["schema_version"] != SCHEMA_VERSION:
            raise BackupValidationError("backup schema version is unsupported")
        files = manifest["files"]
        if not isinstance(files, dict) or "cse.sqlite3" not in files:
            raise BackupValidationError("backup file manifest is invalid")
        for name, expected in files.items():
            try:
                path = validate_safe_archive_name(name)
            except ValueError as exc:
                raise BackupValidationError(str(exc)) from exc
            if name != "cse.sqlite3":
                if len(path.parts) != 3 or path.parts[0] != "attachments":
                    raise BackupValidationError("attachment archive path is invalid")
            if (
                not isinstance(expected, dict)
                or set(expected) != {"sha256", "size_bytes"}
                or not isinstance(expected["sha256"], str)
                or SHA256_PATTERN.fullmatch(expected["sha256"]) is None
                or not isinstance(expected["size_bytes"], int)
                or expected["size_bytes"] < 0
            ):
                raise BackupValidationError("backup digest metadata is invalid")
        attachments = manifest["attachments"]
        if not isinstance(attachments, list):
            raise BackupValidationError("attachment manifest is invalid")
        expected_attachment_rows = [
            {"path": name, **files[name]}
            for name in sorted(files)
            if name != "cse.sqlite3"
        ]
        if attachments != expected_attachment_rows:
            raise BackupValidationError("attachment manifest does not match files")
        attachment_paths = [item["path"] for item in attachments]
        expected_paths = sorted(name for name in files if name != "cse.sqlite3")
        if sorted(attachment_paths) != expected_paths:
            raise BackupValidationError("attachment manifest does not match files")
        if manifest["attachment_count"] != len(attachments):
            raise BackupValidationError("attachment count is invalid")
        for count_name in ("attachment_count", "observation_count", "event_count"):
            count = manifest[count_name]
            if not isinstance(count, int) or isinstance(count, bool) or count < 0:
                raise BackupValidationError("backup count metadata is invalid")

    def _atomic_move(self, source: Path, destination: Path) -> None:
        atomic_rename(source, destination)


def _read_snapshot_inventory(
    snapshot: Path,
) -> tuple[list[AttachmentMetadataRecord], int, int, int]:
    connection = sqlite3.connect(snapshot)
    connection.row_factory = sqlite3.Row
    try:
        versions = [
            row[0]
            for row in connection.execute(
                "SELECT version FROM schema_migrations ORDER BY version"
            )
        ]
        schema_version = max(versions, default=0)
        metadata = _read_attachment_metadata(connection)
        observation_count = connection.execute(
            "SELECT COUNT(*) FROM field_observations"
        ).fetchone()[0]
        event_count = connection.execute(
            "SELECT COUNT(*) FROM observation_events"
        ).fetchone()[0]
        return metadata, schema_version, observation_count, event_count
    except sqlite3.DatabaseError as exc:
        raise BackupValidationError("snapshot database is invalid") from exc
    finally:
        connection.close()


def _read_attachment_metadata(
    connection: sqlite3.Connection,
) -> list[AttachmentMetadataRecord]:
    connection.row_factory = sqlite3.Row
    rows = connection.execute(
        """
        SELECT id, observation_id, original_name, stored_relative_path,
               sha256, size_bytes, mime_type, status, created_at, created_by
        FROM attachments
        ORDER BY created_at, id
        """
    )
    records = [
        AttachmentMetadataRecord(
            row["id"], row["observation_id"], row["original_name"],
            row["stored_relative_path"], row["sha256"], row["size_bytes"],
            row["mime_type"], row["status"], row["created_at"], row["created_by"],
        )
        for row in rows
    ]
    for record in records:
        try:
            validate_attachment_relative_path(
                record.stored_relative_path,
                record.observation_id,
                record.attachment_id,
            )
        except ValueError as exc:
            raise BackupValidationError("snapshot attachment path is invalid") from exc
    return records
