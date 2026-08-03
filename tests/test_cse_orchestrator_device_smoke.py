from __future__ import annotations

import hashlib
from dataclasses import dataclass, field
from pathlib import Path

import pytest

from tools.cse_orchestrator.device_smoke import (
    AdbTabletAutomationAdapter,
    AdapterActionResult,
    DeviceSmokeContract,
    DeviceSmokeError,
    DeviceSmokeRunner,
    ISSUE_284_DEBUG_PACKAGE,
    ISSUE_284_SMOKE_ACTIONS,
    ISSUE_284_TABLET_MODEL,
    ISSUE_284_TABLET_SERIAL,
    PowerInteractiveState,
    parse_power_interactive_state,
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


class FixtureAdbTabletAutomationAdapter(AdbTabletAutomationAdapter):
    def __init__(self, adb_path: Path, power: str, *, window: str = "showing=false"):
        super().__init__(adb_path)
        self.outputs = {
            ("devices", "-l"): (
                "List of devices attached\n"
                f"{ISSUE_284_TABLET_SERIAL} device product:gts9fewifi "
                "model:SM-X610 transport_id:1\n"
            ),
            ("get-state",): "device\n",
            ("shell", "getprop", "ro.product.model"): "SM-X610\n",
            ("shell", "getprop", "sys.boot_completed"): "1\n",
            ("shell", "dumpsys", "power"): power,
            ("shell", "dumpsys", "window", "policy"): window,
            (
                "shell",
                "cmd",
                "package",
                "list",
                "packages",
                "android",
            ): "package:android\n",
        }
        self.calls: list[tuple[str, ...]] = []

    def _run(self, contract, *arguments, **kwargs):
        key = tuple(arguments)
        self.calls.append(key)
        return self.outputs[key].encode("utf-8")


def production_contract(tmp_path: Path) -> DeviceSmokeContract:
    apk = tmp_path / "app-debug.apk"
    apk.write_bytes(b"fixture-apk")
    return DeviceSmokeContract(
        adb_path=(tmp_path / "adb.exe").resolve(),
        serial=ISSUE_284_TABLET_SERIAL,
        model=ISSUE_284_TABLET_MODEL,
        package=ISSUE_284_DEBUG_PACKAGE,
        artifact_path=apk.resolve(),
        artifact_sha256="sha256:" + hashlib.sha256(b"fixture-apk").hexdigest(),
        synthetic_title=TITLE,
        first_all_day=DAY_ONE,
        second_all_day=DAY_TWO,
    )


@pytest.mark.parametrize(
    "power",
    [
        "POWER MANAGER (dumpsys power)\n  mWakefulness=Awake\n",
        "POWER MANAGER (dumpsys power)\n  mInteractive=true\n",
        "POWER MANAGER (dumpsys power)\nDisplay Power: state=ON\n",
    ],
)
def test_production_preflight_accepts_each_exact_interactive_power_shape(
    tmp_path, power
):
    contract = production_contract(tmp_path)
    result = FixtureAdbTabletAutomationAdapter(contract.adb_path, power).preflight(
        contract
    )

    assert result.details == {
        "boot_completed": True,
        "interactive": True,
        "power_state": "interactive",
        "unlocked": True,
    }


@pytest.mark.parametrize(
    "power",
    [
        "  mWakefulness=Asleep\n",
        "  mWakefulness=Dozing\n",
        "  mWakefulness=Dreaming\n",
        "  mInteractive=false\n",
        "Display Power: state=OFF\n",
        "  mWakefulness=Awake\n  mInteractive=false\n",
        "  mWakefulness=Awake\n  mInteractive=TRUE\n",
        "  mWakefulness=AWAKE\n",
        "POWER MANAGER (dumpsys power)\n",
    ],
)
def test_production_preflight_rejects_negative_conflicting_and_malformed_power(
    tmp_path, power
):
    contract = production_contract(tmp_path)

    with pytest.raises(DeviceSmokeError) as raised:
        FixtureAdbTabletAutomationAdapter(contract.adb_path, power).preflight(contract)

    assert raised.value.reason == "screen_not_interactive"
    assert raised.value.predicate == "screen_is_interactive"
    assert raised.value.external is True
    assert str(raised.value) == "screen_not_interactive"
    assert power.strip() not in str(raised.value)


def test_power_parser_returns_only_data_minimal_deterministic_states():
    assert (
        parse_power_interactive_state("mWakefulness=Awake\nmInteractive=true\n")
        is PowerInteractiveState.INTERACTIVE
    )
    assert (
        parse_power_interactive_state("mWakefulness=Dozing\nDisplay Power: state=OFF\n")
        is PowerInteractiveState.NON_INTERACTIVE
    )
    assert (
        parse_power_interactive_state("mWakefulness=Awake\nDisplay Power: state=OFF\n")
        is PowerInteractiveState.CONFLICTING
    )
    assert (
        parse_power_interactive_state("mWakefulness = Awake\n")
        is PowerInteractiveState.MALFORMED
    )


def test_keyguard_remains_an_independent_unchanged_preflight_gate(tmp_path):
    contract = production_contract(tmp_path)
    adapter = FixtureAdbTabletAutomationAdapter(
        contract.adb_path,
        "  mWakefulness=Awake\n",
        window="WINDOW MANAGER POLICY STATE\n  mShowingLockscreen=true\n",
    )

    with pytest.raises(DeviceSmokeError) as raised:
        adapter.preflight(contract)

    assert raised.value.reason == "keyguard_locked"
    assert raised.value.predicate == "keyguard_is_unlocked"
    assert ("shell", "dumpsys", "power") in adapter.calls
    assert ("shell", "dumpsys", "window", "policy") in adapter.calls
