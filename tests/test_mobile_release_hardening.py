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
