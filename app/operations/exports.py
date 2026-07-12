"""Deterministic daily Markdown, CSV and JSON export bundles."""

import csv
import io
import os
import zipfile
from dataclasses import dataclass
from datetime import date, datetime, timedelta, timezone
from pathlib import Path
from uuid import uuid4

from app.persistence import SQLiteUnitOfWork
from app.storage import ManagedAttachmentStore
from app.storage.paths import validate_canonical_uuid

from .common import (
    atomic_rename,
    canonical_json_bytes,
    cleanup_file,
    digest_bytes,
    exclusive_output_path,
    write_zip_bytes,
)


ISTANBUL_TIMEZONE = timezone(timedelta(hours=3), name="Europe/Istanbul")
EXPORT_FILES = (
    "observations.md",
    "observations.csv",
    "observations.json",
    "attachment_manifest.json",
)


@dataclass(frozen=True)
class ExportArtifact:
    artifact_id: str
    path: Path
    record_count: int
    warning_count: int


class DailyExportService:
    def __init__(
        self,
        data_root: str | Path,
        *,
        clock=lambda: datetime.now(timezone.utc).isoformat(timespec="seconds").replace(
            "+00:00", "Z"
        ),
        uuid_factory=lambda: str(uuid4()),
    ) -> None:
        self.data_root = Path(data_root).resolve()
        self.database_path = self.data_root / "cse.sqlite3"
        self.attachment_store = ManagedAttachmentStore(
            self.data_root / "attachments"
        )
        self._clock = clock
        self._uuid_factory = uuid_factory

    def build_daily_export(
        self,
        local_date: date | str,
        output_path: str | Path | None = None,
    ) -> ExportArtifact:
        selected_date = _parse_date(local_date)
        artifact_id = str(self._uuid_factory())
        validate_canonical_uuid(artifact_id, "export_id")
        if output_path is None:
            output_path = self.data_root / "exports" / f"{artifact_id}.zip"
        output = exclusive_output_path(output_path)
        temp = output.with_name(f".{output.name}.{artifact_id}.tmp")
        if temp.exists():
            raise FileExistsError(f"temporary output already exists: {temp.name}")

        records, attachments = self._collect(selected_date)
        payloads = self._build_payloads(records, attachments)
        warning_count = sum(
            item["verification_status"] != "valid" for item in attachments
        )
        manifest = {
            "format_version": 1,
            "generated_at": self._clock(),
            "local_date": selected_date.isoformat(),
            "record_count": len(records),
            "warning_count": warning_count,
            "files": {name: digest_bytes(payloads[name]) for name in EXPORT_FILES},
        }
        payloads["export_manifest.json"] = canonical_json_bytes(manifest)
        try:
            self._write_archive(temp, payloads)
            self._verify_archive(temp, manifest)
            self._atomic_move(temp, output)
        except Exception:
            cleanup_file(temp)
            raise
        return ExportArtifact(artifact_id, output, len(records), warning_count)

    def _collect(
        self, selected_date: date
    ) -> tuple[list[dict[str, object]], list[dict[str, object]]]:
        records: list[dict[str, object]] = []
        attachment_rows: list[dict[str, object]] = []
        with SQLiteUnitOfWork(self.database_path) as unit_of_work:
            projects = {
                project.project_id: project
                for project in unit_of_work.projects.list_all()
            }
            observations = unit_of_work.observations.list_all()
            for observation in observations:
                observed = _parse_utc(observation.observed_at)
                local = observed.astimezone(ISTANBUL_TIMEZONE)
                if local.date() != selected_date:
                    continue
                events = unit_of_work.events.list_for_observation(
                    observation.observation_id
                )
                metadata = unit_of_work.attachments.list_for_observation(
                    observation.observation_id
                )
                project = projects[observation.project_id]
                records.append(
                    {
                        "observation_id": observation.observation_id,
                        "project_id": observation.project_id,
                        "project_name": project.name,
                        "observed_at_utc": observation.observed_at,
                        "observed_at_local": local.isoformat(timespec="seconds"),
                        "location": observation.location,
                        "category": observation.category,
                        "description": observation.description,
                        "notes": observation.notes,
                        "status": observation.status,
                        "reported_to": observation.reported_to,
                        "reported_at": observation.reported_at,
                        "revision": observation.revision,
                        "archived_at": observation.archived_at,
                        "event_count": len(events),
                        "event_types": [event.event_type for event in events],
                        "attachment_ids": [item.attachment_id for item in metadata],
                    }
                )
                for item in metadata:
                    verification = self.attachment_store.verify(item)
                    attachment_rows.append(
                        {
                            "attachment_id": item.attachment_id,
                            "observation_id": item.observation_id,
                            "original_name": item.original_name,
                            "stored_relative_path": item.stored_relative_path,
                            "expected_sha256": item.sha256,
                            "expected_size_bytes": item.size_bytes,
                            "verification_status": verification.status,
                            "actual_sha256": verification.actual_sha256,
                            "actual_size_bytes": verification.actual_size_bytes,
                        }
                    )
        records.sort(key=lambda item: str(item["observation_id"]))
        attachment_rows.sort(key=lambda item: str(item["attachment_id"]))
        return records, attachment_rows

    def _build_payloads(
        self,
        records: list[dict[str, object]],
        attachments: list[dict[str, object]],
    ) -> dict[str, bytes]:
        return {
            "observations.md": _markdown(records).encode("utf-8"),
            "observations.csv": _csv(records).encode("utf-8"),
            "observations.json": canonical_json_bytes(records),
            "attachment_manifest.json": canonical_json_bytes(attachments),
        }

    def _write_archive(self, path: Path, payloads: dict[str, bytes]) -> None:
        with path.open("xb") as file_handle:
            with zipfile.ZipFile(file_handle, "w") as bundle:
                for name in (*EXPORT_FILES, "export_manifest.json"):
                    write_zip_bytes(bundle, name, payloads[name])
            file_handle.flush()
            os.fsync(file_handle.fileno())

    def _atomic_move(self, source: Path, destination: Path) -> None:
        atomic_rename(source, destination)

    def _verify_archive(self, path: Path, manifest: dict[str, object]) -> None:
        expected_names = [*EXPORT_FILES, "export_manifest.json"]
        with zipfile.ZipFile(path) as bundle:
            if bundle.namelist() != expected_names:
                raise ValueError("daily export entries are invalid")
            for name, expected in manifest["files"].items():
                if digest_bytes(bundle.read(name)) != expected:
                    raise ValueError("daily export file integrity mismatch")


CSV_FIELDS = (
    "observation_id",
    "project_id",
    "project_name",
    "observed_at_utc",
    "observed_at_local",
    "location",
    "category",
    "description",
    "notes",
    "status",
    "reported_to",
    "reported_at",
    "revision",
    "archived_at",
    "event_count",
    "event_types",
    "attachment_ids",
)


def _csv(records: list[dict[str, object]]) -> str:
    output = io.StringIO(newline="")
    writer = csv.DictWriter(output, fieldnames=CSV_FIELDS, lineterminator="\n")
    writer.writeheader()
    for record in records:
        row = dict(record)
        row["event_types"] = ";".join(record["event_types"])
        row["attachment_ids"] = ";".join(record["attachment_ids"])
        writer.writerow(row)
    return output.getvalue()


def _markdown(records: list[dict[str, object]]) -> str:
    lines = ["# Günlük Saha Gözlemleri", ""]
    if not records:
        return "\n".join((*lines, "Bu gün için gözlem yok.", ""))
    for record in records:
        lines.extend(
            (
                f"## {_md(record['description'])}",
                "",
                f"- Gözlem ID: `{record['observation_id']}`",
                f"- Proje: {_md(record['project_name'])} (`{record['project_id']}`)",
                f"- Zaman (UTC): `{record['observed_at_utc']}`",
                f"- Zaman (Europe/Istanbul): `{record['observed_at_local']}`",
                f"- Konum: {_md(record['location'])}",
                f"- Kategori: {_md(record['category'])}",
                f"- Durum / revision: `{record['status']}` / `{record['revision']}`",
                f"- Bildirilen: {_md(record['reported_to'] or '-')}",
                f"- Not: {_md(record['notes'] or '-')}",
                f"- Event sayısı: `{record['event_count']}`",
                f"- Attachment ID: {_md(', '.join(record['attachment_ids']) or '-')}",
                "",
            )
        )
    return "\n".join(lines)


def _md(value: object) -> str:
    return str(value).replace("\\", "\\\\").replace("|", "\\|").replace("\n", " ")


def _parse_date(value: date | str) -> date:
    if isinstance(value, datetime):
        raise ValueError("local_date must be a date or YYYY-MM-DD")
    if isinstance(value, date):
        return value
    try:
        parsed = date.fromisoformat(value)
    except (TypeError, ValueError) as exc:
        raise ValueError("local_date must use YYYY-MM-DD") from exc
    if parsed.isoformat() != value:
        raise ValueError("local_date must use YYYY-MM-DD")
    return parsed


def _parse_utc(value: str) -> datetime:
    parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    if parsed.tzinfo != timezone.utc:
        raise ValueError("timestamp must be canonical UTC")
    return parsed
