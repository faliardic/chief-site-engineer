import json
import subprocess
import sys
from pathlib import Path


def phase(*arguments: str) -> dict[str, object]:
    result = subprocess.run(
        [sys.executable, "-m", "app.acceptance", *arguments],
        cwd=Path(__file__).parents[1],
        text=True,
        capture_output=True,
        check=False,
    )
    assert result.returncode == 0, result.stderr
    return json.loads(result.stdout)


def test_real_process_a_b_c_restart_export_backup_restore(tmp_path: Path) -> None:
    source = tmp_path / "source"
    handoff = tmp_path / "handoff.json"
    export = tmp_path / "daily.zip"
    backup = tmp_path / "field.csebackup.zip"
    restored = tmp_path / "restored"

    first = phase("process-a", "--data-root", str(source), "--handoff", str(handoff))
    assert first["phase"] == "A"
    second = phase(
        "process-b", "--data-root", str(source), "--handoff", str(handoff),
        "--export", str(export), "--backup", str(backup),
    )
    assert second["phase"] == "B"
    third = phase(
        "process-c", "--archive", str(backup), "--target-root", str(restored),
        "--handoff", str(handoff),
    )
    assert third == {"attachment_status": "valid", "phase": "C", "revision": 3}
    assert export.is_file() and backup.is_file()
    assert (restored / "cse.sqlite3").is_file()
