import os
import shutil
import subprocess
import hashlib
from pathlib import Path

import pytest


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
RELEASE_GATE = REPOSITORY_ROOT / "scripts" / "release_gate.ps1"
def _source() -> str:
    return RELEASE_GATE.read_text(encoding="utf-8")


def _function_body(source: str, name: str) -> str:
    start = source.index(f"function {name} {{")
    next_function = source.find("\nfunction ", start + 1)
    end = len(source) if next_function == -1 else next_function
    return source[start:end]


def _powershell() -> str | None:
    return shutil.which("pwsh") or shutil.which("powershell")


def _copy_gate_fixture(tmp_path: Path) -> tuple[Path, Path]:
    scripts = tmp_path / "scripts"
    mobile = tmp_path / "mobile"
    scripts.mkdir()
    mobile.mkdir()
    copied_gate = scripts / "release_gate.ps1"
    copied_gate.write_text(_source(), encoding="utf-8")
    return copied_gate, mobile


def _write_mock_flutter(tmp_path: Path) -> Path:
    mock = tmp_path / "mock_flutter.ps1"
    mock.write_text(
        """
$buildRoot = Join-Path (Get-Location).Path 'build'
New-Item -ItemType Directory -Force -Path $buildRoot | Out-Null
[IO.File]::WriteAllText(
    $env:CSE_TEST_FLUTTER_MARKER,
    ($args -join ' '),
    [Text.UTF8Encoding]::new($false)
)
exit 0
""".strip(),
        encoding="utf-8",
    )
    return mock


def _write_mock_adb(tmp_path: Path) -> Path:
    mock = tmp_path / "mock_adb.ps1"
    mock.write_text(
        """
[IO.File]::WriteAllText(
    $env:CSE_TEST_ADB_MARKER,
    ($args -join ' '),
    [Text.UTF8Encoding]::new($false)
)
exit 0
""".strip(),
        encoding="utf-8",
    )
    return mock


def test_atomic_rotation_is_unique_and_non_destructive() -> None:
    source = _source()
    body = _function_body(source, "Move-ExistingFlutterBuildRoot")

    assert "build.release-gate-{0}-{1}-stale" in body
    assert "[IO.Directory]::Move($buildRoot, $quarantineRoot)" in body
    assert body.index("Test-Path -LiteralPath $quarantineRoot") < body.index(
        "[IO.Directory]::Move($buildRoot, $quarantineRoot)"
    )
    assert "Remove-Item" not in body
    assert "Invoke-Flutter -Arguments @('clean')" not in source


def test_rename_failure_precedes_flutter_invocation() -> None:
    source = _source()
    body = _function_body(source, "Invoke-IsolatedFlutterBuild")

    assert body.index("Move-ExistingFlutterBuildRoot") < body.index(
        "Invoke-Flutter -Arguments $Arguments"
    )
    assert "catch" not in body


def test_normal_and_acceptance_build_kinds_are_distinct() -> None:
    source = _source()

    assert "'normal-debug-apk'" in source
    assert "'release-aab-unsigned'" in source
    assert "'release-aab-signed'" in source
    assert "'background-acceptance-apk'" in source
    assert "'reboot-acceptance-apk'" in source
    assert "'issue254-acceptance-apk'" in source
    assert "New-BuildInvocationId" in source


def test_artifact_freshness_and_identity_contracts_remain_fail_closed() -> None:
    gate = _source()

    assert "LastWriteTimeUtc -lt $started" in gate
    assert "LastWriteTimeUtc -lt $normalBuildStarted" in gate
    assert "CSE_ENTRYPOINT_NORMAL_LIB_MAIN_DART_V1" in gate
    assert "CSE_ENTRYPOINT_ISSUE252_SMOKE_ACCEPTANCE_V1" in gate
    assert "com.faliardic.chiefsiteengineer.acceptance" in gate
    assert "issue254-physical-smoke-acceptance-debug.apk" in gate
    assert "issue212-reminder-pilot-ux-debug.apk" in gate
    assert "Get-FileHash -LiteralPath $destination -Algorithm SHA256" in gate
    assert "LastWriteUtcTicks" in gate


def test_issue254_acceptance_is_the_last_flutter_build() -> None:
    source = _source()
    main = source[source.index("try {\n    if ($RunIssue254PhysicalSmoke") :]

    normal = main.index("-Kind 'normal-debug-apk'")
    background = main.index("-Kind 'background-acceptance-apk'")
    reboot = main.index("-Kind 'reboot-acceptance-apk'")
    unsigned = main.index("-Kind 'release-aab-unsigned'")
    issue254 = main.index("-Kind 'issue254-acceptance-apk'")
    physical = main.index("Invoke-VerifiedAcceptancePhysicalSmoke")

    assert normal < background < reboot < unsigned < issue254 < physical
    assert "Invoke-IsolatedFlutterBuild" not in main[issue254:physical]
    assert "CSE_ISSUE254_RUN_ID=$AcceptanceRunId" in main[issue254:physical]


def test_physical_smoke_has_no_build_clean_or_rotation_path() -> None:
    source = _source()
    body = _function_body(source, "Invoke-VerifiedAcceptancePhysicalSmoke")

    assert body.index("Assert-VerifiedAcceptanceArtifactUnchanged") < body.index(
        "Invoke-AdbText"
    )
    for forbidden in (
        "Invoke-Flutter",
        "Invoke-IsolatedFlutterBuild",
        "Move-ExistingFlutterBuildRoot",
        "gradlew",
        "app-debug.apk",
        "flutter clean",
        "flutter build",
    ):
        assert forbidden not in body
    assert "'install', '-r', $ArtifactRecord.Path" in body
    assert "KEYCODE_HOME" in body
    assert "0x10008000" in body


def test_wrong_artifact_kinds_are_rejected_before_physical_smoke() -> None:
    body = _function_body(_source(), "Assert-VerifiedAcceptanceArtifactUnchanged")

    assert "issue254-physical-smoke-acceptance-debug.apk" in body
    assert "issue254-acceptance-apk" in body
    assert "Physical smoke requires the exact verified Issue #254" in body


@pytest.mark.skipif(_powershell() is None, reason="PowerShell is unavailable")
def test_isolated_command_rotates_then_starts_flutter(tmp_path: Path) -> None:
    gate, mobile = _copy_gate_fixture(tmp_path)
    build = mobile / "build"
    build.mkdir()
    (build / "sentinel.txt").write_text("previous", encoding="utf-8")
    marker = tmp_path / "flutter-started.txt"
    mock = _write_mock_flutter(tmp_path)
    env = os.environ.copy()
    env["CSE_TEST_FLUTTER_MARKER"] = str(marker)

    completed = subprocess.run(
        [
            _powershell(),
            "-NoProfile",
            "-File",
            str(gate),
            "-RunIsolatedFlutterCommand",
            "-BuildKind",
            "normal-debug-apk",
            "-BuildRunId",
            "run-001",
            "-FlutterCommand",
            str(mock),
            "-FlutterArguments",
            "build",
        ],
        check=False,
        capture_output=True,
        text=True,
        env=env,
    )

    assert completed.returncode == 0, completed.stderr
    quarantine = mobile / "build.release-gate-normal-debug-apk-run-001-stale"
    assert (quarantine / "sentinel.txt").read_text(encoding="utf-8") == "previous"
    assert marker.read_text(encoding="utf-8") == "build"
    assert build.is_dir()


@pytest.mark.skipif(_powershell() is None, reason="PowerShell is unavailable")
def test_existing_quarantine_target_blocks_flutter(tmp_path: Path) -> None:
    gate, mobile = _copy_gate_fixture(tmp_path)
    build = mobile / "build"
    build.mkdir()
    quarantine = mobile / "build.release-gate-normal-debug-apk-run-002-stale"
    quarantine.mkdir()
    marker = tmp_path / "flutter-started.txt"
    mock = _write_mock_flutter(tmp_path)
    env = os.environ.copy()
    env["CSE_TEST_FLUTTER_MARKER"] = str(marker)

    completed = subprocess.run(
        [
            _powershell(),
            "-NoProfile",
            "-File",
            str(gate),
            "-RunIsolatedFlutterCommand",
            "-BuildKind",
            "normal-debug-apk",
            "-BuildRunId",
            "run-002",
            "-FlutterCommand",
            str(mock),
            "-FlutterArguments",
            "build",
            "apk",
        ],
        check=False,
        capture_output=True,
        text=True,
        env=env,
    )

    assert completed.returncode != 0
    assert "already exists" in (completed.stdout + completed.stderr)
    assert build.is_dir()
    assert quarantine.is_dir()
    assert not marker.exists()


@pytest.mark.skipif(_powershell() is None, reason="PowerShell is unavailable")
def test_artifact_hash_change_blocks_adb(tmp_path: Path) -> None:
    gate, _ = _copy_gate_fixture(tmp_path)
    artifact = (
        tmp_path
        / "chief-site-engineer-0.1.0-issue254-"
        "physical-smoke-acceptance-debug.apk"
    )
    artifact.write_bytes(b"verified acceptance fixture")
    stat = artifact.stat()
    dotnet_ticks = stat.st_mtime_ns // 100 + 621_355_968_000_000_000
    actual_hash = hashlib.sha256(artifact.read_bytes()).hexdigest()
    wrong_hash = ("0" if actual_hash[0] != "0" else "1") + actual_hash[1:]
    adb_marker = tmp_path / "adb-started.txt"
    mock_adb = _write_mock_adb(tmp_path)
    env = os.environ.copy()
    env["CSE_TEST_ADB_MARKER"] = str(adb_marker)

    completed = subprocess.run(
        [
            _powershell(),
            "-NoProfile",
            "-File",
            str(gate),
            "-RunVerifiedAcceptanceSmokeOnly",
            "-VerifiedAcceptanceArtifactPath",
            str(artifact),
            "-VerifiedAcceptanceSha256",
            wrong_hash,
            "-VerifiedAcceptanceLength",
            str(stat.st_size),
            "-VerifiedAcceptanceLastWriteUtcTicks",
            str(dotnet_ticks),
            "-AcceptanceRunId",
            "20260727210000",
            "-AdbCommand",
            str(mock_adb),
            "-AndroidDevice",
            "fixture-device",
        ],
        check=False,
        capture_output=True,
        text=True,
        env=env,
    )

    assert completed.returncode != 0
    assert "SHA-256 changed" in (completed.stdout + completed.stderr)
    assert not adb_marker.exists()
