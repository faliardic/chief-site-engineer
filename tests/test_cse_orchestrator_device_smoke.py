from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path

import pytest

from tools.cse_orchestrator.device_smoke import (
    AdapterActionResult,
    DeviceSmokeError,
    DeviceSmokeRunner,
    ISSUE_284_DEBUG_PACKAGE,
    ISSUE_284_SMOKE_ACTIONS,
    ISSUE_284_TABLET_MODEL,
    ISSUE_284_TABLET_SERIAL,
    validate_adb_argv,
)


HASH = "sha256:" + "a" * 64
TITLE = "CSE284_O10_ABCDEF123456"
DAY_ONE = "2026-08-03"
DAY_TWO = "2026-08-04"


def argv(action: str, adb: str = r"C:\sdk\platform-tools\adb.exe") -> list[str]:
    return [
        adb,
        "-s",
        ISSUE_284_TABLET_SERIAL,
        "cse-smoke",
        action,
        TITLE,
        DAY_ONE,
        DAY_TWO,
        "recoverable-only",
    ]


def device() -> dict[str, object]:
    return {
        "serial": ISSUE_284_TABLET_SERIAL,
        "model": ISSUE_284_TABLET_MODEL,
        "package": ISSUE_284_DEBUG_PACKAGE,
    }


def artifact(tmp_path: Path) -> dict[str, object]:
    return {
        "path": str((tmp_path / "app-debug.apk").resolve()),
        "sha256": HASH,
        "package": ISSUE_284_DEBUG_PACKAGE,
        "version": "0.1.0-debug (1)",
        "signer": HASH,
        "checkpoint_sha": "b" * 40,
    }


@dataclass
class FakeTabletAdapter:
    connected: bool = True
    installed: bool = False
    state: str = "missing"
    revision: int = 0
    operations: list[str] = field(default_factory=list)

    def _record(self, action: str) -> bool:
        reused = action in self.operations
        if not reused:
            self.operations.append(action)
        return reused

    def preflight(self, contract):
        if not self.connected:
            raise DeviceSmokeError(
                "device_not_connected", "exact_tablet_is_listed", external=True
            )
        return AdapterActionResult(reused=self._record("tablet_preflight"))

    def install(self, contract):
        reused = self.installed
        self.installed = True
        self._record("tablet_install")
        return AdapterActionResult(reused=reused)

    def timed_to_all_day(self, contract):
        reused = self.state == f"all_day:{contract.first_all_day}"
        if not reused:
            assert self.state in {"missing", "timed"}
            self.state = f"all_day:{contract.first_all_day}"
            self.revision += 1
        self._record("smoke_timed_to_all_day")
        return AdapterActionResult(reused=reused)

    def all_day_date_change(self, contract):
        reused = self.state == f"all_day:{contract.second_all_day}"
        if not reused:
            assert self.state == f"all_day:{contract.first_all_day}"
            self.state = f"all_day:{contract.second_all_day}"
            self.revision += 1
        self._record("smoke_all_day_date_change")
        return AdapterActionResult(reused=reused)

    def same_day_noop(self, contract):
        assert self.state == f"all_day:{contract.second_all_day}"
        reused = self._record("smoke_same_day_noop")
        return AdapterActionResult(reused=reused, details={"revision": self.revision})

    def all_day_to_timed(self, contract):
        reused = self.state == "timed"
        if not reused:
            assert self.state == f"all_day:{contract.second_all_day}"
            self.state = "timed"
            self.revision += 1
        self._record("smoke_all_day_to_timed")
        return AdapterActionResult(reused=reused)

    def notification_binding(self, contract):
        assert self.state == "timed"
        return AdapterActionResult(
            reused=self._record("smoke_notification_binding"),
            details={"binding_visible": True},
        )

    def cold_relaunch(self, contract):
        assert self.state == "timed"
        return AdapterActionResult(
            reused=self._record("smoke_cold_relaunch"),
            details={"persistence": True},
        )

    def recoverable_cleanup(self, contract):
        reused = self.state == "trashed"
        if not reused:
            assert self.state == "timed"
            self.state = "trashed"
            self.revision += 1
        self._record("smoke_recoverable_cleanup")
        return AdapterActionResult(
            reused=reused, details={"trashed": True, "hard_delete": False}
        )


def test_fake_adapter_runs_full_issue_284_smoke_and_every_step_is_idempotent(
    tmp_path,
):
    fake = FakeTabletAdapter()
    runner = DeviceSmokeRunner(fake)
    artifact_value = artifact(tmp_path)

    for action in ISSUE_284_SMOKE_ACTIONS:
        result = runner.run(argv(action), device=device(), artifact=artifact_value)
        assert result.success is True
        assert result.reason_code is None
        revision = fake.revision
        repeated = runner.run(argv(action), device=device(), artifact=artifact_value)
        assert repeated.success is True
        assert repeated.reused is True
        assert fake.revision == revision

    assert fake.installed is True
    assert fake.state == "trashed"
    assert fake.operations == list(ISSUE_284_SMOKE_ACTIONS)


def test_device_absence_pauses_external_without_install_or_smoke(tmp_path):
    fake = FakeTabletAdapter(connected=False)
    result = DeviceSmokeRunner(fake).run(
        argv("tablet_preflight"), device=device(), artifact=artifact(tmp_path)
    )
    assert result.success is False
    assert result.classification == "external"
    assert result.reason_code == "device_not_connected"
    assert fake.operations == []


@pytest.mark.parametrize(
    ("mutation", "reason"),
    [
        (lambda value: value.update(serial="PHONE123"), "adb_serial_invalid"),
        (lambda value: value.update(model="SM-S938B"), "tablet_model_forbidden"),
        (lambda value: value.update(package="com.example.production"), "package_forbidden"),
    ],
)
def test_phone_model_package_guards_fail_before_adapter(
    tmp_path, mutation, reason
):
    target = device()
    mutation(target)
    fake = FakeTabletAdapter()
    result = DeviceSmokeRunner(fake).run(
        argv("tablet_preflight"), device=target, artifact=artifact(tmp_path)
    )
    assert result.success is False
    assert result.reason_code == reason
    assert result.action_started is False
    assert fake.operations == []


def test_real_user_title_and_non_recoverable_cleanup_contract_are_rejected(tmp_path):
    values = argv("smoke_timed_to_all_day")
    values[5] = "Fatih gerçek hatırlatıcı"
    result = DeviceSmokeRunner(FakeTabletAdapter()).run(
        values, device=device(), artifact=artifact(tmp_path)
    )
    assert result.success is False
    assert result.reason_code == "synthetic_title_invalid"

    values = argv("smoke_recoverable_cleanup")
    values[8] = "hard-delete"
    result = DeviceSmokeRunner(FakeTabletAdapter()).run(
        values, device=device(), artifact=artifact(tmp_path)
    )
    assert result.success is False
    assert result.reason_code == "destructive_operation_forbidden"


@pytest.mark.parametrize(
    "operation",
    [
        ("uninstall", ISSUE_284_DEBUG_PACKAGE),
        ("shell", "pm", "clear", ISSUE_284_DEBUG_PACKAGE),
        ("install", "-d", "artifact.apk"),
        ("shell", "rm", "/data/local/tmp/value"),
    ],
)
def test_destructive_adb_operations_are_rejected(operation):
    with pytest.raises(DeviceSmokeError, match="destructive_operation_forbidden"):
        validate_adb_argv(
            (r"C:\sdk\platform-tools\adb.exe", "-s", ISSUE_284_TABLET_SERIAL, *operation),
            serial=ISSUE_284_TABLET_SERIAL,
        )


def test_every_targeted_adb_command_requires_exact_single_tablet_serial():
    with pytest.raises(DeviceSmokeError, match="adb_serial_invalid"):
        validate_adb_argv(
            (r"C:\sdk\platform-tools\adb.exe", "devices", "-l"),
            serial=ISSUE_284_TABLET_SERIAL,
        )
    with pytest.raises(DeviceSmokeError, match="adb_serial_invalid"):
        validate_adb_argv(
            (r"C:\sdk\platform-tools\adb.exe", "-s", "PHONE123", "get-state"),
            serial=ISSUE_284_TABLET_SERIAL,
        )
