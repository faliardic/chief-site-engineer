"""Actual interpreter-boundary acceptance phases for Local Field MVP v0.1."""

import argparse
import hashlib
import io
import json
from collections.abc import Sequence
from pathlib import Path

from app.application import (
    CreateObservation,
    ObservationApplicationService,
    UploadStream,
)
from app.operations import BackupService, DailyExportService
from app.storage import ManagedAttachmentStore
from app.web import create_app


PHOTO_BYTES = b"local-field-mvp-real-photo-bytes"


def _service(root: Path, clock=None) -> ObservationApplicationService:
    options = {} if clock is None else {"clock": clock}
    return ObservationApplicationService(
        root / "cse.sqlite3",
        ManagedAttachmentStore(root / "attachments"),
        local_actor="subprocess-user",
        **options,
    )


def process_a(data_root: Path, handoff_path: Path) -> dict[str, object]:
    times = iter(["2026-07-13T08:00:00Z", "2026-07-13T09:00:00Z"])
    service = _service(data_root, clock=lambda: next(times))
    project = service.create_project("Subprocess Santiye")
    observation = service.create_observation(
        CreateObservation(
            project_id=project.project_id,
            location="A Blok",
            category="quality",
            description="Subprocess kontrolu",
            upload=UploadStream(io.BytesIO(PHOTO_BYTES), "photo.jpg"),
        )
    )
    detail = service.get_observation_detail(observation.observation_id)
    attachment = detail.attachments[0].metadata
    handoff = {
        "observation_id": observation.observation_id,
        "attachment_id": attachment.attachment_id,
        "sha256": hashlib.sha256(PHOTO_BYTES).hexdigest(),
        "local_date": "2026-07-13",
    }
    handoff_path.write_text(json.dumps(handoff, sort_keys=True), encoding="utf-8")
    return {"phase": "A", "attachment_status": detail.attachments[0].verification.status}


def process_b(
    data_root: Path,
    handoff_path: Path,
    export_path: Path,
    backup_path: Path,
) -> dict[str, object]:
    handoff = json.loads(handoff_path.read_text(encoding="utf-8"))
    times = iter(["2026-07-13T10:00:00Z", "2026-07-13T11:00:00Z"])
    service = _service(data_root, clock=lambda: next(times))
    detail = service.get_observation_detail(handoff["observation_id"])
    if not detail.attachments[0].verification.valid:
        raise RuntimeError("attachment did not survive Process A")
    service.update_status(handoff["observation_id"], 1, "tracking")
    updated = service.update_reporting(
        handoff["observation_id"], 2, "Saha formeni", "2026-07-13T10:30:00Z"
    )
    DailyExportService(data_root).build_daily_export(
        handoff["local_date"], export_path
    )
    backup = BackupService(data_root)
    backup.create_backup(backup_path)
    backup.verify_backup(backup_path)
    handoff["revision"] = updated.revision
    handoff_path.write_text(json.dumps(handoff, sort_keys=True), encoding="utf-8")
    return {"phase": "B", "revision": updated.revision}


def process_c(
    archive_path: Path, target_root: Path, handoff_path: Path
) -> dict[str, object]:
    handoff = json.loads(handoff_path.read_text(encoding="utf-8"))
    BackupService(archive_path.parent).restore_backup(archive_path, target_root)
    service = _service(target_root)
    detail = service.get_observation_detail(handoff["observation_id"])
    attachment = detail.attachments[0]
    if detail.observation.revision != handoff["revision"]:
        raise RuntimeError("restored revision mismatch")
    if attachment.verification.actual_sha256 != handoff["sha256"]:
        raise RuntimeError("restored attachment hash mismatch")
    expected_events = {
        "observation_created",
        "observation_status_changed",
        "observation_reporting_updated",
    }
    if {event.event_type for event in detail.events} != expected_events:
        raise RuntimeError("restored event vocabulary mismatch")
    client = create_app(target_root).test_client()
    if client.get("/observations").status_code != 200:
        raise RuntimeError("restored list route failed")
    if client.get(f"/observations/{handoff['observation_id']}").status_code != 200:
        raise RuntimeError("restored detail route failed")
    download = client.get(f"/attachments/{handoff['attachment_id']}")
    if download.data != PHOTO_BYTES:
        raise RuntimeError("restored attachment route failed")
    return {
        "phase": "C",
        "revision": detail.observation.revision,
        "attachment_status": attachment.verification.status,
    }


def parse_args(arguments: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    commands = parser.add_subparsers(dest="phase", required=True)
    first = commands.add_parser("process-a")
    first.add_argument("--data-root", required=True)
    first.add_argument("--handoff", required=True)
    second = commands.add_parser("process-b")
    second.add_argument("--data-root", required=True)
    second.add_argument("--handoff", required=True)
    second.add_argument("--export", required=True)
    second.add_argument("--backup", required=True)
    third = commands.add_parser("process-c")
    third.add_argument("--archive", required=True)
    third.add_argument("--target-root", required=True)
    third.add_argument("--handoff", required=True)
    return parser.parse_args(arguments)


def main(arguments: Sequence[str] | None = None) -> int:
    args = parse_args(arguments)
    if args.phase == "process-a":
        result = process_a(Path(args.data_root), Path(args.handoff))
    elif args.phase == "process-b":
        result = process_b(
            Path(args.data_root), Path(args.handoff), Path(args.export),
            Path(args.backup),
        )
    else:
        result = process_c(
            Path(args.archive), Path(args.target_root), Path(args.handoff)
        )
    print(json.dumps(result, sort_keys=True, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
