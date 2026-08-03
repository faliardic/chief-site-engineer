"""Shell-free, exact-target tablet smoke runner for the Issue #284 pilot.

The coordinator calls one semantic action per workflow stage.  The production
adapter uses only ``subprocess`` argv arrays with ``shell=False``; tests inject
an in-memory adapter and never touch a real device.
"""

from __future__ import annotations

import hashlib
import re
import subprocess
import time
import xml.etree.ElementTree as ET
from dataclasses import dataclass, field
from datetime import date, datetime
from enum import Enum
from pathlib import Path
from typing import Mapping, Protocol, Sequence


ISSUE_284_TABLET_SERIAL = "R52W90JFN1M"
ISSUE_284_TABLET_MODEL = "SM-X610"
ISSUE_284_DEBUG_PACKAGE = "com.faliardic.chiefsiteengineer.debug"
ISSUE_284_SYNTHETIC_PATTERN = re.compile(r"^CSE284_O10_[0-9A-F]{12}$")
ISSUE_284_SMOKE_ACTIONS = (
    "tablet_preflight",
    "tablet_install",
    "smoke_timed_to_all_day",
    "smoke_all_day_date_change",
    "smoke_same_day_noop",
    "smoke_all_day_to_timed",
    "smoke_notification_binding",
    "smoke_cold_relaunch",
    "smoke_recoverable_cleanup",
)
FORBIDDEN_ADB_TOKENS = frozenset(
    {
        "uninstall",
        "clear",
        "clear-data",
        "--downgrade",
        "-d",
        "rm",
        "delete",
        "hard-delete",
    }
)
BOUNDS_PATTERN = re.compile(r"^\[(\d+),(\d+)\]\[(\d+),(\d+)\]$")
DAY_PATTERN = re.compile(r"^\d{4}-\d{2}-\d{2}$")
WAKEFULNESS_LINE = re.compile(r"^\s*mWakefulness=([^\s=]+)\s*$")
INTERACTIVE_LINE = re.compile(r"^\s*mInteractive=(true|false)\s*$")
DISPLAY_POWER_LINE = re.compile(r"^\s*Display Power: state=(ON|OFF)\s*$")
DISPLAY_POWER_STATE_CANDIDATE = re.compile(
    r"^Display Power:\s*state(?:\s*=|$)", re.IGNORECASE
)
WAKEFULNESS_INTERACTIVE = {
    "Awake": True,
    "1": True,
    "Asleep": False,
    "0": False,
    "Dreaming": False,
    "2": False,
    "Dozing": False,
    "3": False,
}


class DeviceSmokeError(RuntimeError):
    """A smoke action cannot continue without weakening a guard."""

    def __init__(self, reason: str, predicate: str, *, external: bool = False):
        super().__init__(reason)
        self.reason = reason
        self.predicate = predicate
        self.external = external


class PowerInteractiveState(str, Enum):
    """Data-minimal classification of supported ``dumpsys power`` signals."""

    INTERACTIVE = "interactive"
    NON_INTERACTIVE = "non_interactive"
    CONFLICTING = "conflicting"
    MALFORMED = "malformed"


def parse_power_interactive_state(output: str) -> PowerInteractiveState:
    """Parse exact line-level power signals without returning raw device output."""

    signals: list[bool] = []
    malformed = False
    for line in output.splitlines():
        stripped = line.strip()
        wakefulness = WAKEFULNESS_LINE.fullmatch(line)
        interactive = INTERACTIVE_LINE.fullmatch(line)
        display = DISPLAY_POWER_LINE.fullmatch(line)
        if wakefulness:
            wakefulness_value = WAKEFULNESS_INTERACTIVE.get(wakefulness.group(1))
            if wakefulness_value is None:
                malformed = True
            else:
                signals.append(wakefulness_value)
        elif interactive:
            signals.append(interactive.group(1) == "true")
        elif display:
            signals.append(display.group(1) == "ON")
        elif (
            re.match(r"^(mWakefulness|mInteractive)\s*=", stripped)
            or DISPLAY_POWER_STATE_CANDIDATE.match(stripped) is not None
        ):
            malformed = True
    if malformed or not signals:
        return PowerInteractiveState.MALFORMED
    if any(signals) and not all(signals):
        return PowerInteractiveState.CONFLICTING
    if all(signals):
        return PowerInteractiveState.INTERACTIVE
    return PowerInteractiveState.NON_INTERACTIVE


@dataclass(frozen=True)
class DeviceSmokeContract:
    adb_path: Path
    serial: str
    model: str
    package: str
    artifact_path: Path
    artifact_sha256: str
    synthetic_title: str
    first_all_day: str
    second_all_day: str

    def validate(self) -> None:
        if self.serial != ISSUE_284_TABLET_SERIAL:
            raise DeviceSmokeError("tablet_serial_forbidden", "serial_is_exact_tablet")
        if self.model != ISSUE_284_TABLET_MODEL:
            raise DeviceSmokeError("tablet_model_forbidden", "model_is_exact_tablet")
        if self.package != ISSUE_284_DEBUG_PACKAGE:
            raise DeviceSmokeError("package_forbidden", "package_is_exact_debug")
        if not ISSUE_284_SYNTHETIC_PATTERN.fullmatch(self.synthetic_title):
            raise DeviceSmokeError(
                "synthetic_title_invalid", "title_is_unique_synthetic"
            )
        if not self.adb_path.is_absolute() or self.adb_path.name.lower() != "adb.exe":
            raise DeviceSmokeError("adb_path_invalid", "adb_path_is_absolute")
        if not self.artifact_path.is_absolute():
            raise DeviceSmokeError(
                "artifact_path_invalid", "artifact_path_is_absolute"
            )
        expected = self.artifact_sha256.removeprefix("sha256:")
        if not re.fullmatch(r"[0-9a-f]{64}", expected):
            raise DeviceSmokeError("artifact_hash_invalid", "artifact_hash_is_sha256")
        try:
            first = date.fromisoformat(self.first_all_day)
            second = date.fromisoformat(self.second_all_day)
        except ValueError as exc:
            raise DeviceSmokeError("smoke_day_invalid", "smoke_days_are_iso") from exc
        if second.toordinal() != first.toordinal() + 1:
            raise DeviceSmokeError(
                "smoke_day_sequence_invalid", "second_day_follows_first_day"
            )


@dataclass(frozen=True)
class AdapterActionResult:
    reused: bool = False
    details: Mapping[str, object] = field(default_factory=dict)


@dataclass(frozen=True)
class DeviceSmokeResult:
    success: bool
    classification: str
    reason_code: str | None
    first_failed_predicate: str | None
    action_started: bool
    reused: bool
    details: Mapping[str, object]


class TabletAutomationAdapter(Protocol):
    """Semantic adapter; it intentionally has no arbitrary-command method."""

    def preflight(self, contract: DeviceSmokeContract) -> AdapterActionResult: ...

    def install(self, contract: DeviceSmokeContract) -> AdapterActionResult: ...

    def timed_to_all_day(
        self, contract: DeviceSmokeContract
    ) -> AdapterActionResult: ...

    def all_day_date_change(
        self, contract: DeviceSmokeContract
    ) -> AdapterActionResult: ...

    def same_day_noop(self, contract: DeviceSmokeContract) -> AdapterActionResult: ...

    def all_day_to_timed(
        self, contract: DeviceSmokeContract
    ) -> AdapterActionResult: ...

    def notification_binding(
        self, contract: DeviceSmokeContract
    ) -> AdapterActionResult: ...

    def cold_relaunch(self, contract: DeviceSmokeContract) -> AdapterActionResult: ...

    def recoverable_cleanup(
        self, contract: DeviceSmokeContract
    ) -> AdapterActionResult: ...


def validate_adb_argv(argv: Sequence[str], *, serial: str) -> tuple[str, ...]:
    """Reject phone targeting, shell composition, and destructive ADB verbs."""

    values = tuple(str(item) for item in argv)
    if not values or Path(values[0]).name.lower() not in {"adb", "adb.exe"}:
        raise DeviceSmokeError("adb_executable_invalid", "adb_executable_is_exact")
    if any(item in {";", "&&", "||", "|"} for item in values):
        raise DeviceSmokeError("shell_composition_forbidden", "argv_is_shell_free")
    lowered = {item.lower() for item in values}
    if lowered & FORBIDDEN_ADB_TOKENS:
        raise DeviceSmokeError(
            "destructive_operation_forbidden", "adb_operation_is_non_destructive"
        )
    switches = [
        values[index + 1]
        for index, item in enumerate(values[:-1])
        if item == "-s"
    ]
    if switches != [serial]:
        raise DeviceSmokeError("adb_serial_invalid", "adb_serial_is_exact_tablet")
    return values


class DeviceSmokeRunner:
    """Dispatch one authorized, idempotent semantic tablet action."""

    def __init__(self, adapter: TabletAutomationAdapter | None = None):
        self.adapter = adapter

    @staticmethod
    def contract_from_authorization(
        argv: Sequence[str],
        *,
        device: Mapping[str, object],
        artifact: Mapping[str, object],
    ) -> tuple[str, DeviceSmokeContract]:
        values = tuple(str(item) for item in argv)
        if len(values) != 9 or values[1] != "-s" or values[3] != "cse-smoke":
            raise DeviceSmokeError(
                "smoke_argv_invalid", "smoke_argv_matches_exact_shape"
            )
        action = values[4]
        if action not in ISSUE_284_SMOKE_ACTIONS:
            raise DeviceSmokeError("smoke_action_invalid", "smoke_action_is_allowlisted")
        serial = str(device.get("serial", ""))
        validate_adb_argv(values[:3] + values[3:], serial=serial)
        contract = DeviceSmokeContract(
            adb_path=Path(values[0]),
            serial=serial,
            model=str(device.get("model", "")),
            package=str(device.get("package", "")),
            artifact_path=Path(str(artifact.get("path", ""))),
            artifact_sha256=str(artifact.get("sha256", "")),
            synthetic_title=values[5],
            first_all_day=values[6],
            second_all_day=values[7],
        )
        if values[8] != "recoverable-only":
            raise DeviceSmokeError(
                "cleanup_contract_invalid", "cleanup_is_recoverable_only"
            )
        contract.validate()
        return action, contract

    def run(
        self,
        argv: Sequence[str],
        *,
        device: Mapping[str, object],
        artifact: Mapping[str, object],
    ) -> DeviceSmokeResult:
        action_started = False
        try:
            action, contract = self.contract_from_authorization(
                argv, device=device, artifact=artifact
            )
            adapter = self.adapter or AdbTabletAutomationAdapter(contract.adb_path)
            methods = {
                "tablet_preflight": adapter.preflight,
                "tablet_install": adapter.install,
                "smoke_timed_to_all_day": adapter.timed_to_all_day,
                "smoke_all_day_date_change": adapter.all_day_date_change,
                "smoke_same_day_noop": adapter.same_day_noop,
                "smoke_all_day_to_timed": adapter.all_day_to_timed,
                "smoke_notification_binding": adapter.notification_binding,
                "smoke_cold_relaunch": adapter.cold_relaunch,
                "smoke_recoverable_cleanup": adapter.recoverable_cleanup,
            }
            action_started = True
            outcome = methods[action](contract)
            return DeviceSmokeResult(
                True,
                "unsafe",
                None,
                None,
                True,
                outcome.reused,
                {
                    "device": {
                        "serial": contract.serial,
                        "model": contract.model,
                        "package": contract.package,
                        "action": action,
                        "reused": outcome.reused,
                        **dict(outcome.details),
                    }
                },
            )
        except DeviceSmokeError as exc:
            return DeviceSmokeResult(
                False,
                "external" if exc.external else "unsafe",
                exc.reason,
                exc.predicate,
                action_started,
                False,
                {},
            )


class AdbTabletAutomationAdapter:
    """Data-minimal ADB/UI adapter for the exact Issue #284 tablet path."""

    _turkish_months = (
        "",
        "Ocak",
        "Şubat",
        "Mart",
        "Nisan",
        "Mayıs",
        "Haziran",
        "Temmuz",
        "Ağustos",
        "Eylül",
        "Ekim",
        "Kasım",
        "Aralık",
    )
    _turkish_weekdays = (
        "Pazartesi",
        "Salı",
        "Çarşamba",
        "Perşembe",
        "Cuma",
        "Cumartesi",
        "Pazar",
    )

    def __init__(self, adb_path: Path):
        self.adb_path = Path(adb_path)

    @staticmethod
    def _artifact_digest(path: Path) -> str:
        digest = hashlib.sha256()
        with path.open("rb") as stream:
            for chunk in iter(lambda: stream.read(1024 * 1024), b""):
                digest.update(chunk)
        return "sha256:" + digest.hexdigest()

    def _run(
        self,
        contract: DeviceSmokeContract,
        *arguments: str,
        targeted: bool = True,
        timeout: int = 30,
        output_limit: int = 2 * 1024 * 1024,
    ) -> bytes:
        argv = (str(self.adb_path),)
        if targeted:
            argv += ("-s", contract.serial)
        argv += tuple(arguments)
        if targeted:
            validate_adb_argv(argv, serial=contract.serial)
        elif argv != (str(self.adb_path), "devices", "-l"):
            raise DeviceSmokeError(
                "untargeted_adb_forbidden", "untargeted_command_is_devices_list"
            )
        try:
            completed = subprocess.run(
                list(argv),
                stdin=subprocess.DEVNULL,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                shell=False,
                check=False,
                timeout=timeout,
            )
        except subprocess.TimeoutExpired as exc:
            raise DeviceSmokeError(
                "adb_timeout", "adb_command_completed", external=True
            ) from exc
        except OSError as exc:
            raise DeviceSmokeError(
                "adb_unavailable", "adb_process_started", external=True
            ) from exc
        if len(completed.stdout) > output_limit or len(completed.stderr) > output_limit:
            raise DeviceSmokeError("adb_output_unbounded", "adb_output_is_bounded")
        if completed.returncode != 0:
            raise DeviceSmokeError(
                "adb_command_failed", "adb_exit_code_zero", external=True
            )
        return completed.stdout

    @staticmethod
    def _decode(value: bytes) -> str:
        try:
            return value.decode("utf-8").strip()
        except UnicodeDecodeError as exc:
            raise DeviceSmokeError("adb_output_invalid", "adb_output_is_utf8") from exc

    def _assert_target_ready(self, contract: DeviceSmokeContract) -> None:
        devices = self._decode(
            self._run(contract, "devices", "-l", targeted=False)
        ).splitlines()[1:]
        matches = [line for line in devices if line.split(maxsplit=1)[0] == contract.serial]
        if not matches:
            raise DeviceSmokeError(
                "device_not_connected", "exact_tablet_is_listed", external=True
            )
        state_fields = matches[0].split() if len(matches) == 1 else []
        if len(matches) != 1 or len(state_fields) < 2 or state_fields[1] != "device":
            reason = "device_unauthorized" if "unauthorized" in matches[0] else "device_not_ready"
            raise DeviceSmokeError(reason, "tablet_state_is_device", external=True)
        state = self._decode(self._run(contract, "get-state"))
        if state != "device":
            raise DeviceSmokeError("device_not_ready", "get_state_is_device", external=True)
        model = self._decode(
            self._run(contract, "shell", "getprop", "ro.product.model")
        )
        if model != contract.model:
            raise DeviceSmokeError("tablet_model_mismatch", "model_is_exact_tablet")

    def preflight(self, contract: DeviceSmokeContract) -> AdapterActionResult:
        self._assert_target_ready(contract)
        if not contract.artifact_path.is_file():
            raise DeviceSmokeError(
                "artifact_missing", "artifact_path_exists", external=True
            )
        if self._artifact_digest(contract.artifact_path) != contract.artifact_sha256:
            raise DeviceSmokeError("artifact_hash_mismatch", "artifact_sha256_matches")
        boot = self._decode(
            self._run(contract, "shell", "getprop", "sys.boot_completed")
        )
        if boot != "1":
            raise DeviceSmokeError("device_not_booted", "sys_boot_completed_is_one", external=True)
        power_state = parse_power_interactive_state(
            self._decode(self._run(contract, "shell", "dumpsys", "power"))
        )
        if power_state is not PowerInteractiveState.INTERACTIVE:
            raise DeviceSmokeError("screen_not_interactive", "screen_is_interactive", external=True)
        window = self._decode(
            self._run(contract, "shell", "dumpsys", "window", "policy")
        )
        if not re.search(
            r"showing=false|isStatusBarKeyguard=false|mShowingLockscreen=false",
            window,
        ):
            raise DeviceSmokeError("keyguard_locked", "keyguard_is_unlocked", external=True)
        package_manager = self._decode(
            self._run(contract, "shell", "cmd", "package", "list", "packages", "android")
        )
        if "package:android" not in package_manager:
            raise DeviceSmokeError(
                "package_manager_unavailable", "package_manager_is_accessible", external=True
            )
        return AdapterActionResult(
            details={
                "boot_completed": True,
                "interactive": True,
                "power_state": PowerInteractiveState.INTERACTIVE.value,
                "unlocked": True,
            }
        )

    def _installed_apk_path(self, contract: DeviceSmokeContract) -> str | None:
        value = self._decode(
            self._run(contract, "shell", "pm", "path", contract.package)
        )
        paths = [line.removeprefix("package:") for line in value.splitlines() if line.startswith("package:")]
        return paths[0] if len(paths) == 1 else None

    def _installed_digest(self, contract: DeviceSmokeContract) -> str | None:
        path = self._installed_apk_path(contract)
        if path is None:
            return None
        value = self._decode(
            self._run(contract, "shell", "toybox", "sha256sum", path, timeout=120)
        )
        digest = value.split(maxsplit=1)[0] if value else ""
        return "sha256:" + digest if re.fullmatch(r"[0-9a-f]{64}", digest) else None

    def install(self, contract: DeviceSmokeContract) -> AdapterActionResult:
        self._assert_target_ready(contract)
        if self._installed_digest(contract) == contract.artifact_sha256:
            return AdapterActionResult(reused=True, details={"installed": True})
        output = self._decode(
            self._run(
                contract,
                "install",
                "-r",
                "-g",
                str(contract.artifact_path),
                timeout=300,
                output_limit=1024 * 1024,
            )
        )
        if "Success" not in output:
            raise DeviceSmokeError("install_failed", "install_result_is_success")
        if self._installed_digest(contract) != contract.artifact_sha256:
            raise DeviceSmokeError(
                "installed_artifact_mismatch", "installed_apk_matches_artifact"
            )
        return AdapterActionResult(details={"installed": True})

    @staticmethod
    def _bounds(value: str) -> tuple[int, int]:
        match = BOUNDS_PATTERN.fullmatch(value)
        if match is None:
            raise DeviceSmokeError("ui_bounds_invalid", "target_bounds_are_valid")
        x1, y1, x2, y2 = (int(item) for item in match.groups())
        if x2 <= x1 or y2 <= y1:
            raise DeviceSmokeError("ui_bounds_empty", "target_bounds_have_area")
        return ((x1 + x2) // 2, (y1 + y2) // 2)

    def _nodes(self, contract: DeviceSmokeContract) -> tuple[Mapping[str, str], ...]:
        raw = self._run(
            contract,
            "exec-out",
            "uiautomator",
            "dump",
            "/dev/tty",
            timeout=30,
        )
        start = raw.find(b"<?xml")
        end = raw.rfind(b"</hierarchy>")
        if start < 0 or end < start:
            raise DeviceSmokeError("ui_hierarchy_unavailable", "ui_hierarchy_is_xml", external=True)
        try:
            root = ET.fromstring(raw[start : end + len(b"</hierarchy>")])
        except ET.ParseError as exc:
            raise DeviceSmokeError("ui_hierarchy_invalid", "ui_hierarchy_is_xml") from exc
        # Raw hierarchy is never returned, logged, or persisted.  Only bounded
        # attributes needed to match an allowlisted/synthetic target survive.
        return tuple(dict(node.attrib) for node in root.iter("node"))

    @staticmethod
    def _matching_nodes(
        nodes: Sequence[Mapping[str, str]], label: str
    ) -> tuple[Mapping[str, str], ...]:
        return tuple(
            item
            for item in nodes
            if item.get("text") == label or item.get("content-desc") == label
        )

    def _screen_size(self, contract: DeviceSmokeContract) -> tuple[int, int]:
        value = self._decode(self._run(contract, "shell", "wm", "size"))
        match = re.search(r"(?:Override|Physical) size:\s*(\d+)x(\d+)", value)
        if match is None:
            raise DeviceSmokeError("screen_size_unknown", "screen_size_is_available")
        return int(match.group(1)), int(match.group(2))

    def _swipe(self, contract: DeviceSmokeContract, *, upward: bool) -> None:
        width, height = self._screen_size(contract)
        x = width // 2
        y1, y2 = (int(height * 0.78), int(height * 0.30))
        if not upward:
            y1, y2 = y2, y1
        self._run(
            contract,
            "shell",
            "input",
            "swipe",
            str(x),
            str(y1),
            str(x),
            str(y2),
            "250",
        )

    def _tap_exact(
        self,
        contract: DeviceSmokeContract,
        label: str,
        *,
        max_scrolls: int = 0,
    ) -> None:
        for attempt in range(max_scrolls + 1):
            matches = self._matching_nodes(self._nodes(contract), label)
            if len(matches) == 1:
                x, y = self._bounds(matches[0].get("bounds", ""))
                width, height = self._screen_size(contract)
                if not (0 < x < width and 0 < y < height):
                    raise DeviceSmokeError(
                        "ui_target_outside_screen", "tap_center_is_inside_screen"
                    )
                self._run(
                    contract, "shell", "input", "tap", str(x), str(y)
                )
                time.sleep(0.25)
                return
            if len(matches) > 1:
                raise DeviceSmokeError(
                    "ui_target_ambiguous", "exact_target_match_count_is_one"
                )
            if attempt < max_scrolls:
                self._swipe(contract, upward=True)
                time.sleep(0.2)
        raise DeviceSmokeError("ui_target_missing", "exact_target_is_visible")

    def _has_exact(self, contract: DeviceSmokeContract, label: str) -> bool:
        return len(self._matching_nodes(self._nodes(contract), label)) == 1

    def _launch(self, contract: DeviceSmokeContract) -> None:
        component = f"{contract.package}/com.faliardic.chiefsiteengineer.MainActivity"
        self._run(contract, "shell", "am", "start", "-W", "-n", component)
        time.sleep(0.5)

    def _find_and_open_synthetic(self, contract: DeviceSmokeContract) -> bool:
        if self._has_exact(contract, contract.synthetic_title):
            nodes = self._nodes(contract)
            # A detail page exposes action text; a list card does not.
            if any(
                self._matching_nodes(nodes, label)
                for label in ("Yeni tarih", "Geri yükle", "Sil")
            ):
                return True
            self._tap_exact(contract, contract.synthetic_title)
            return True
        if self._has_exact(contract, "Hatırlatıcı"):
            self._tap_exact(contract, "Hatırlatıcı")
        for view in ("Bugün", "Yarın"):
            try:
                self._tap_exact(contract, view)
            except DeviceSmokeError as exc:
                if exc.reason not in {"ui_target_missing", "ui_target_ambiguous"}:
                    raise
            for _ in range(13):
                matches = self._matching_nodes(
                    self._nodes(contract), contract.synthetic_title
                )
                if len(matches) == 1:
                    self._tap_exact(contract, contract.synthetic_title)
                    return True
                if len(matches) > 1:
                    raise DeviceSmokeError(
                        "synthetic_match_ambiguous",
                        "synthetic_title_match_count_is_one",
                    )
                self._swipe(contract, upward=True)
        return False

    def _ensure_detail(self, contract: DeviceSmokeContract) -> None:
        self._assert_target_ready(contract)
        self._launch(contract)
        if not self._find_and_open_synthetic(contract):
            raise DeviceSmokeError(
                "synthetic_record_missing", "synthetic_record_is_exactly_identified"
            )
        if not self._has_exact(contract, contract.synthetic_title):
            raise DeviceSmokeError(
                "synthetic_detail_mismatch", "opened_record_is_exact_synthetic"
            )

    def _create_timed_if_missing(self, contract: DeviceSmokeContract) -> bool:
        self._assert_target_ready(contract)
        self._launch(contract)
        if self._find_and_open_synthetic(contract):
            return True
        if self._has_exact(contract, "Hatırlatıcı"):
            self._tap_exact(contract, "Hatırlatıcı")
        self._tap_exact(contract, "+ Unutma", max_scrolls=4)
        nodes = self._nodes(contract)
        fields = [
            item
            for item in nodes
            if item.get("text") == "Hatırlatıcı metni"
            or item.get("content-desc") == "Hatırlatıcı metni"
        ]
        if len(fields) != 1:
            raise DeviceSmokeError(
                "synthetic_input_missing", "title_input_match_count_is_one"
            )
        x, y = self._bounds(fields[0].get("bounds", ""))
        self._run(contract, "shell", "input", "tap", str(x), str(y))
        self._run(
            contract,
            "shell",
            "input",
            "text",
            contract.synthetic_title,
        )
        self._tap_exact(contract, "Hatırlatıcı oluştur", max_scrolls=12)
        if self._has_exact(contract, "Anladım"):
            self._tap_exact(contract, "Anladım")
        if not self._find_and_open_synthetic(contract):
            raise DeviceSmokeError(
                "synthetic_create_unverified", "created_synthetic_is_visible"
            )
        return False

    @staticmethod
    def _formatted_day(value: str) -> str:
        parsed = date.fromisoformat(value)
        return f"{parsed.day:02d}.{parsed.month:02d}.{parsed.year:04d} • Tam gün"

    def _tap_calendar_day(self, contract: DeviceSmokeContract, value: str) -> None:
        parsed = date.fromisoformat(value)
        labels = (
            f"{parsed.day} {self._turkish_months[parsed.month]} {parsed.year} "
            f"{self._turkish_weekdays[parsed.weekday()]}",
            f"{parsed.day} {self._turkish_months[parsed.month]} {parsed.year}",
        )
        nodes = self._nodes(contract)
        matches = tuple(
            item
            for item in nodes
            if item.get("content-desc") in labels or item.get("text") in labels
        )
        if len(matches) == 1:
            x, y = self._bounds(matches[0].get("bounds", ""))
            self._run(contract, "shell", "input", "tap", str(x), str(y))
            time.sleep(0.2)
        elif len(matches) > 1:
            raise DeviceSmokeError(
                "calendar_day_ambiguous", "calendar_day_match_count_is_one"
            )

    def _schedule_all_day(self, contract: DeviceSmokeContract, value: str) -> None:
        self._tap_exact(contract, "Yeni tarih", max_scrolls=12)
        self._tap_exact(contract, "Tam gün", max_scrolls=8)
        self._tap_calendar_day(contract, value)
        self._tap_exact(contract, "İleri")
        if not self._has_exact(contract, self._formatted_day(value)):
            raise DeviceSmokeError(
                "all_day_preview_mismatch", "all_day_preview_is_exact"
            )
        self._tap_exact(contract, "Tam gün planla")
        time.sleep(0.4)
        if not self._has_exact(contract, self._formatted_day(value)):
            raise DeviceSmokeError(
                "all_day_persistence_mismatch", "detail_all_day_is_exact"
            )

    def _revision(self, contract: DeviceSmokeContract) -> str:
        nodes = self._nodes(contract)
        values = [item.get("text", "") for item in nodes]
        try:
            index = values.index("Revision")
        except ValueError as exc:
            raise DeviceSmokeError("revision_missing", "revision_is_visible") from exc
        for candidate in values[index + 1 : index + 5]:
            if candidate.isdigit():
                return candidate
        raise DeviceSmokeError("revision_value_missing", "revision_value_is_visible")

    def timed_to_all_day(self, contract: DeviceSmokeContract) -> AdapterActionResult:
        reused_create = self._create_timed_if_missing(contract)
        if self._has_exact(contract, self._formatted_day(contract.first_all_day)):
            return AdapterActionResult(reused=True)
        if self._has_exact(contract, "Takvim günü"):
            raise DeviceSmokeError(
                "unexpected_all_day_state", "first_all_day_state_is_exact"
            )
        self._schedule_all_day(contract, contract.first_all_day)
        if self._has_exact(contract, "Bildirim planlandı"):
            raise DeviceSmokeError(
                "stale_timed_binding_visible", "all_day_has_no_timed_binding"
            )
        return AdapterActionResult(details={"synthetic_reused": reused_create})

    def all_day_date_change(self, contract: DeviceSmokeContract) -> AdapterActionResult:
        self._ensure_detail(contract)
        expected = self._formatted_day(contract.second_all_day)
        if self._has_exact(contract, expected):
            return AdapterActionResult(reused=True)
        if not self._has_exact(contract, self._formatted_day(contract.first_all_day)):
            raise DeviceSmokeError(
                "all_day_source_state_invalid", "first_all_day_state_is_exact"
            )
        self._schedule_all_day(contract, contract.second_all_day)
        return AdapterActionResult()

    def same_day_noop(self, contract: DeviceSmokeContract) -> AdapterActionResult:
        self._ensure_detail(contract)
        if not self._has_exact(contract, self._formatted_day(contract.second_all_day)):
            raise DeviceSmokeError(
                "same_day_source_state_invalid", "second_all_day_state_is_exact"
            )
        before = self._revision(contract)
        self._schedule_all_day(contract, contract.second_all_day)
        after = self._revision(contract)
        if after != before:
            raise DeviceSmokeError(
                "same_day_revision_churn", "same_day_revision_is_unchanged"
            )
        return AdapterActionResult(details={"revision": before})

    def all_day_to_timed(self, contract: DeviceSmokeContract) -> AdapterActionResult:
        self._ensure_detail(contract)
        if self._has_exact(contract, "Sonraki dikkat zamanı") and not self._has_exact(
            contract, "Takvim günü"
        ):
            return AdapterActionResult(reused=True)
        if not self._has_exact(contract, self._formatted_day(contract.second_all_day)):
            raise DeviceSmokeError(
                "timed_conversion_source_invalid", "second_all_day_state_is_exact"
            )
        self._tap_exact(contract, "Yeni tarih", max_scrolls=12)
        self._tap_exact(contract, "15 dakika", max_scrolls=2)
        time.sleep(0.4)
        if self._has_exact(contract, "Takvim günü") or not self._has_exact(
            contract, "Sonraki dikkat zamanı"
        ):
            raise DeviceSmokeError(
                "timed_conversion_failed", "timed_state_is_visible"
            )
        return AdapterActionResult()

    def notification_binding(self, contract: DeviceSmokeContract) -> AdapterActionResult:
        self._ensure_detail(contract)
        if not self._has_exact(contract, "Bildirim planlandı"):
            raise DeviceSmokeError(
                "notification_binding_missing", "timed_binding_is_visible"
            )
        if self._has_exact(contract, "Takvim günü"):
            raise DeviceSmokeError(
                "stale_all_day_visible", "timed_state_clears_all_day"
            )
        return AdapterActionResult(details={"binding_visible": True})

    def cold_relaunch(self, contract: DeviceSmokeContract) -> AdapterActionResult:
        self._assert_target_ready(contract)
        self._run(contract, "shell", "am", "force-stop", contract.package)
        self._launch(contract)
        if not self._find_and_open_synthetic(contract):
            raise DeviceSmokeError(
                "cold_relaunch_record_missing", "synthetic_persists_after_relaunch"
            )
        if not self._has_exact(contract, "Sonraki dikkat zamanı"):
            raise DeviceSmokeError(
                "cold_relaunch_state_mismatch", "timed_state_persists_after_relaunch"
            )
        return AdapterActionResult(details={"persistence": True})

    def recoverable_cleanup(self, contract: DeviceSmokeContract) -> AdapterActionResult:
        self._ensure_detail(contract)
        if self._has_exact(contract, "Geri yükle"):
            return AdapterActionResult(reused=True, details={"trashed": True})
        self._tap_exact(contract, "Sil", max_scrolls=12)
        if not self._has_exact(contract, "Hatırlatıcı silinsin mi?"):
            raise DeviceSmokeError(
                "trash_confirmation_missing", "recoverable_confirmation_is_visible"
            )
        self._tap_exact(contract, "Sil")
        time.sleep(0.4)
        if not self._has_exact(contract, contract.synthetic_title) or not self._has_exact(
            contract, "Geri yükle"
        ):
            raise DeviceSmokeError(
                "recoverable_cleanup_failed", "synthetic_is_recoverably_trashed"
            )
        return AdapterActionResult(details={"trashed": True, "hard_delete": False})
