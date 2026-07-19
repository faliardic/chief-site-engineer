import json
import io
import subprocess
import sys
from pathlib import Path

from app.application import (
    CreateObservation,
    ObservationApplicationService,
    UploadStream,
)
from app.storage import ManagedAttachmentStore


def seed(root: Path) -> None:
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
    service.create_observation(
        CreateObservation(
            project_id=project.project_id,
            location="A",
            category="quality",
            description="Kontrol",
            upload=UploadStream(io.BytesIO(b"backup-photo"), "photo.jpg"),
        )
    )


def run_cli(*arguments: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, "-m", "app.ops", *arguments],
        cwd=Path(__file__).parents[1],
        text=True,
        capture_output=True,
        check=False,
    )


def test_operations_cli_export_backup_verify_and_restore(tmp_path: Path) -> None:
    source = tmp_path / "source"
    seed(source)
    export = tmp_path / "daily.zip"
    backup = tmp_path / "field.csebackup.zip"
    target = tmp_path / "restored"

    commands = [
        ("export-daily", "--data-root", str(source), "--date", "2026-07-13",
         "--output", str(export)),
        ("backup", "--data-root", str(source), "--output", str(backup)),
        ("verify-backup", "--archive", str(backup)),
        ("restore", "--archive", str(backup), "--target-root", str(target)),
    ]
    for command in commands:
        result = run_cli(*command)
        assert result.returncode == 0, result.stderr
        payload = json.loads(result.stdout)
        assert payload["ok"] is True
        assert str(tmp_path) not in result.stdout

    assert export.is_file()
    assert backup.is_file()
    assert (target / "cse.sqlite3").is_file()


def test_operations_cli_failure_is_nonzero_and_safe(tmp_path: Path) -> None:
    result = run_cli("verify-backup", "--archive", str(tmp_path / "missing.zip"))
    assert result.returncode != 0
    payload = json.loads(result.stderr)
    assert payload["ok"] is False
    assert str(tmp_path) not in result.stderr
