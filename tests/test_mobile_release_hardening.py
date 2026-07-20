import subprocess
import sys
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]


def test_mobile_release_static_gate_passes() -> None:
    completed = subprocess.run(
        [sys.executable, "scripts/validate_mobile_release.py"],
        cwd=REPOSITORY_ROOT,
        check=False,
        capture_output=True,
        text=True,
    )

    assert completed.returncode == 0, completed.stderr
    assert "Android source permission and API 36 contract" in completed.stdout
    assert "tracked signing-secret absence" in completed.stdout


def test_release_gate_keeps_debug_sidecar_and_production_rc_distinct() -> None:
    gate = (REPOSITORY_ROOT / "scripts" / "release_gate.ps1").read_text(
        encoding="utf-8"
    )

    assert "chief-site-engineer-0.1.0-issue200-sidecar-debug.apk" in gate
    assert "com.faliardic.chiefsiteengineer.debug" in gate
    assert "chief-site-engineer-0.1.0-rc-ephemeral.apk" in gate
    assert "Debug sidecar contains a forbidden broad storage/media permission" in gate
    assert "SIDECAR_SHA256.txt" in gate
