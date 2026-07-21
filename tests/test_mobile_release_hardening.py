import subprocess
import sys
import zipfile
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

    assert "chief-site-engineer-0.1.0-issue207-field-sidecar-debug.apk" in gate
    assert "'--target', 'lib\\main.dart'" in gate
    assert "CSE_ENTRYPOINT_NORMAL_LIB_MAIN_DART_V1" in gate
    assert "Flutter clean left a stale app-debug.apk" in gate
    assert "SCHEDULE_EXACT_ALARM allow" in gate
    assert "com.faliardic.chiefsiteengineer.debug" in gate
    assert "chief-site-engineer-0.1.0-rc-ephemeral.apk" in gate
    assert "Debug sidecar contains a forbidden broad storage/media permission" in gate
    assert "SIDECAR_SHA256.txt" in gate


def test_synthetic_acceptance_artifacts_are_isolated_from_field_sidecar() -> None:
    script = (
        REPOSITORY_ROOT / "scripts" / "build_mobile_acceptance_apks.ps1"
    ).read_text(encoding="utf-8")
    gradle = (
        REPOSITORY_ROOT / "mobile" / "android" / "app" / "build.gradle.kts"
    ).read_text(encoding="utf-8")

    assert "CSE_ACCEPTANCE_HARNESS" in gradle
    assert '".acceptance"' in gradle
    assert "issue207-background-acceptance-debug.apk" in script
    assert "issue207-reboot-acceptance-debug.apk" in script
    assert "android-arm64,android-x64" in script
    assert "issue207-field-sidecar-debug.apk" in script
    assert "changed the normal field sidecar artifact" in script


def test_flutter_apk_entrypoint_verifier_fails_closed(tmp_path: Path) -> None:
    apk = tmp_path / "synthetic.apk"
    with zipfile.ZipFile(apk, "w") as archive:
        archive.writestr(
            "assets/flutter_assets/kernel_blob.bin",
            b"prefix CSE_ENTRYPOINT_BACKGROUND_ACCEPTANCE_V1 suffix",
        )

    passed = subprocess.run(
        [
            sys.executable,
            "scripts/verify_flutter_apk_entrypoint.py",
            "--apk",
            str(apk),
            "--expected-marker",
            "CSE_ENTRYPOINT_BACKGROUND_ACCEPTANCE_V1",
            "--forbidden-marker",
            "CSE_ENTRYPOINT_NORMAL_LIB_MAIN_DART_V1",
        ],
        cwd=REPOSITORY_ROOT,
        check=False,
        capture_output=True,
        text=True,
    )
    assert passed.returncode == 0, passed.stderr

    rejected = subprocess.run(
        [
            sys.executable,
            "scripts/verify_flutter_apk_entrypoint.py",
            "--apk",
            str(apk),
            "--expected-marker",
            "CSE_ENTRYPOINT_NORMAL_LIB_MAIN_DART_V1",
        ],
        cwd=REPOSITORY_ROOT,
        check=False,
        capture_output=True,
        text=True,
    )
    assert rejected.returncode != 0
    assert "expected Flutter entrypoint marker is missing" in rejected.stderr
