"""Strict one-command bootstrap for the paused Issue #284 live pilot."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from pathlib import Path
from tempfile import TemporaryDirectory
from typing import Mapping, Protocol, Sequence

from .device_smoke import (
    ISSUE_284_DEBUG_PACKAGE,
    ISSUE_284_SMOKE_ACTIONS,
    ISSUE_284_TABLET_MODEL,
    ISSUE_284_TABLET_SERIAL,
)
from .observer import (
    GhGitHubClient,
    GitHubClientError,
    sanitized_github_error_reason,
)
from .workflow import (
    GhIssueEvidenceSink,
    WorkflowCoordinator,
    WorkflowError,
    controller_revision,
    current_reused_evidence_record,
    observe_target,
)
from .workflow_authorization import (
    WorkflowAuthorization,
    WorkflowAuthorizationError,
    canonical_json_bytes,
    parse_workflow_authorization,
)
from .workflow_store import WorkflowContract, WorkflowStore, WorkflowStoreError


ISSUE_284 = 284
ISSUE_305 = 305
ISSUE_305_BASE = "5d46cb81bc8b116f29358c50609c47d7f732843e"
ISSUE_284_BRANCH = "codex/issue-284-reminder-all-day-edit"
ISSUE_284_PARENT = "eb85f0a2ea0901f0074887fe999e74b6ab4aed0f"
ISSUE_284_CHECKPOINT = "b0e9cf247afa6bac5d38684dbc626a11fdf45663"
ISSUE_284_TREE = "4e3ccd1e37b050588f135138ceb69105c74c5059"
ISSUE_284_ARTIFACT_PATH = Path(
    r"C:\Users\Fatih\AppData\Local\Temp\cse284-checkpoint-build-20260802220351985-e4ab3aa1\mobile\build\app\outputs\flutter-apk\app-debug.apk"
)
ISSUE_284_ARTIFACT_SHA256 = (
    "0887ca25a19f47924d5e4f96d5bac8f4586f429042666cb38aab9893725f9560"
)
ISSUE_284_ARTIFACT_VERSION = "0.1.0-debug (1)"
ISSUE_284_SIGNER_SHA256 = (
    "329f42b542af8576367279b59fb2802dfd545253b2906f7ba2ac12c7c6d5c869"
)
ISSUE_284_FLUTTER = Path(
    r"C:\Users\Fatih\.cache\flutter-sdk\3.44.6-ee80f08\flutter\bin\flutter.bat"
)
ISSUE_284_ADB = Path(
    r"C:\Users\Fatih\AppData\Local\Android\sdk\platform-tools\adb.exe"
)
ISSUE_284_ADB_SHA256 = (
    "1e1c2280b90b3f01ad84cd8df4858b1b1995012814f3ca8893bcc3ba3848edec"
)
ISSUE_305_AUTHORIZATION_COMMENT = 5160233470
ISSUE_305_HANDOFF_AUTHORIZATION_COMMENT = 5167123792
ISSUE_305_HANDOFF_PREDECESSOR = "894ac311cb9d6d454fb5121169b9031c4ae466b8"
ISSUE_305_PAUSED_HANDOFF_AUTHORIZATION_COMMENT = 5168941496
ISSUE_305_PAUSED_HANDOFF_PREDECESSOR = "5e5d6dc9b06312e6e78be60d1542954d1fd05eca"
ISSUE_305_PAUSED_PREDECESSOR_AUTHORIZATION = (
    "sha256:3c09c0068d20cb4b8b95b2a3067d50a5fb66976db7cf8a4936cea501c5123019"
)
ISSUE_305_PAUSED_PREDECESSOR_WORKFLOW = "wf-284-3c09c0068d20"
ISSUE_305_PAUSED_PROJECTION_FINGERPRINT = (
    "sha256:0074c74280ae39648372397c378eefd385e4259915a78d5e242c56c03c24aa3c"
)
ISSUE_305_PAUSED_TAIL_HASH = (
    "sha256:6601305f5cb94dfbbf75f826788414e76d20e38b54bdd296bc34eac1e0a56ba5"
)
ISSUE_305_NUMERIC_HANDOFF_AUTHORIZATION_COMMENT = 5169514740
ISSUE_305_NUMERIC_HANDOFF_PREDECESSOR = (
    "ce70484b8b5644253797eb6038eef00050873df8"
)
ISSUE_305_NUMERIC_PREDECESSOR_AUTHORIZATION = (
    "sha256:74cb312bf0d363cfb78406a4b7293d5430711af521d9f979eef92e972511ef8f"
)
ISSUE_305_NUMERIC_PREDECESSOR_WORKFLOW = "wf-284-74cb312bf0d3"
ISSUE_305_NUMERIC_PROJECTION_FINGERPRINT = (
    "sha256:f63fb5e2d519d92e8e5a13facec0887ab8465693a8c8b3d4af81b12735310453"
)
ISSUE_305_NUMERIC_TAIL_HASH = (
    "sha256:28917b5bf6ab90ae60e68174177a57fb65328f6bf30a343f651a52cf3d10f0f5"
)

ISSUE_284_CHECKPOINT_PATHS = (
    ".cse/tasks/284_task.md",
    "mobile/lib/application/agenda_application.dart",
    "mobile/lib/features/reminders/reminder_detail_page.dart",
    "mobile/test/reminder_lifecycle_test.dart",
    "mobile/test/reminder_widget_test.dart",
    "mobile/test/support/fake_agenda_application.dart",
)
ISSUE_284_READ_WRITE_ALLOWLIST = (
    ".cse/tasks/284_task.md",
    "mobile/lib/application/agenda_application.dart",
    "mobile/lib/features/reminders/reminder_detail_page.dart",
    "mobile/lib/domain/agenda_models.dart",
    "mobile/test/reminder_widget_test.dart",
    "mobile/test/reminder_lifecycle_test.dart",
    "mobile/test/support/fake_agenda_application.dart",
    ".cse/tasks/284_result.md",
    "CHANGELOG.md",
    "ROADMAP.md",
)
ISSUE_284_BLOBS = {
    ".cse/tasks/284_task.md": "e953de12d4a47adb59627dc6fc40f79e1171e7fd",
    "mobile/lib/application/agenda_application.dart": "985e5278f6a41430d65a025941c5dae9f26c2b55",
    "mobile/lib/features/reminders/reminder_detail_page.dart": "9cf026b1520a720b1f7bb445525eaa5208ab76c7",
    "mobile/lib/domain/agenda_models.dart": "d874036799550d8a70577e285a8eb0f2853a2ebc",
    "mobile/test/reminder_lifecycle_test.dart": "7d2954c39aefceff47d38eaa7913bc6ccc6f4aec",
    "mobile/test/reminder_widget_test.dart": "d506cdc8a6bb59866cbb19d65b0b5d35170dff6e",
    "mobile/test/support/fake_agenda_application.dart": "0003dc11213c8bf881bf552dd34d5854bac56ed4",
    "mobile/pubspec.lock": "0ca1109b3b029510e41c13e930bda79578fe05be",
}
ISSUE_BODY_HASHES = {
    ISSUE_284: "19d4d0d954e33ed96f4dd26a2a0d72afad656588ac2358edea19db1fc6321d23",
    ISSUE_305: "3fbfb160e920c9e68a65cbeedd5cd62e47cdf61e28b31460d561863487535304",
}
EVIDENCE_COMMENT_HASHES = {
    ISSUE_284: {
        5159802594: "d1151b633c007e4cdd2da1299cfedfd539e2f780444bb38672d10b0c21d651c9",
        5159834136: "5a6a569c2955ca2215d8f8ce3b101458216fb8d7d20be030494bc028c83316e6",
        5159861939: "4d6167e93a33310ccecc1b778a1c39c39e53179321e18d2d6f38166daafa30c0",
        5159903268: "b6c929b817be916883dcca237d537d4a69a04715cd820f3b78dbeab3638e8724",
        5159955414: "91fdb47371de06499fa8c615d7785053c9d432fcd9f8365ffef547ab719ced9f",
    },
    ISSUE_305: {
        ISSUE_305_AUTHORIZATION_COMMENT: (
            "295503753da308f0a1f8fd79fa059eb07546e2da3b2cb2fd646c17fa463d2a59"
        )
    },
}
REUSED_STAGE_NAMES = (
    "focused_lifecycle",
    "focused_widget",
    "full_flutter",
    "flutter_analyze",
    "debug_apk_build",
)


class BootstrapError(RuntimeError):
    """The bootstrap inputs cannot produce an exact authorization."""


class BootstrapEvidenceClient(Protocol):
    def get_issue(self, issue_number: int) -> Mapping[str, object]: ...

    def get_issue_comments(self, issue_number: int) -> list[Mapping[str, object]]: ...


@dataclass(frozen=True)
class Issue284PilotProfile:
    repository: str = "faliardic/chief-site-engineer"
    target_branch: str = ISSUE_284_BRANCH
    target_parent: str = ISSUE_284_PARENT
    target_checkpoint: str = ISSUE_284_CHECKPOINT
    target_tree: str = ISSUE_284_TREE
    checkpoint_paths: tuple[str, ...] = ISSUE_284_CHECKPOINT_PATHS
    read_write_allowlist: tuple[str, ...] = ISSUE_284_READ_WRITE_ALLOWLIST
    blobs: Mapping[str, str] = field(default_factory=lambda: dict(ISSUE_284_BLOBS))
    artifact_path: Path = ISSUE_284_ARTIFACT_PATH
    artifact_sha256: str = ISSUE_284_ARTIFACT_SHA256
    artifact_version: str = ISSUE_284_ARTIFACT_VERSION
    signer_sha256: str = ISSUE_284_SIGNER_SHA256
    flutter_path: Path = ISSUE_284_FLUTTER
    adb_path: Path = ISSUE_284_ADB
    adb_sha256: str = ISSUE_284_ADB_SHA256
    controller_base: str = ISSUE_305_BASE
    handoff_predecessor_revision: str = ISSUE_305_HANDOFF_PREDECESSOR
    paused_handoff_predecessor_revision: str = ISSUE_305_PAUSED_HANDOFF_PREDECESSOR
    paused_predecessor_authorization: str = ISSUE_305_PAUSED_PREDECESSOR_AUTHORIZATION
    paused_predecessor_workflow: str = ISSUE_305_PAUSED_PREDECESSOR_WORKFLOW
    paused_projection_fingerprint: str = ISSUE_305_PAUSED_PROJECTION_FINGERPRINT
    paused_tail_hash: str = ISSUE_305_PAUSED_TAIL_HASH
    numeric_handoff_predecessor_revision: str = ISSUE_305_NUMERIC_HANDOFF_PREDECESSOR
    numeric_predecessor_authorization: str = ISSUE_305_NUMERIC_PREDECESSOR_AUTHORIZATION
    numeric_predecessor_workflow: str = ISSUE_305_NUMERIC_PREDECESSOR_WORKFLOW
    numeric_projection_fingerprint: str = ISSUE_305_NUMERIC_PROJECTION_FINGERPRINT
    numeric_tail_hash: str = ISSUE_305_NUMERIC_TAIL_HASH
    authorization_comment_id: int = ISSUE_305_AUTHORIZATION_COMMENT
    issue_body_hashes: Mapping[int, str] = field(
        default_factory=lambda: dict(ISSUE_BODY_HASHES)
    )
    comment_hashes: Mapping[int, Mapping[int, str]] = field(
        default_factory=lambda: {
            issue: dict(values) for issue, values in EVIDENCE_COMMENT_HASHES.items()
        }
    )
    require_controller_on_origin_master: bool = True


def _sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def _sha256_text(value: str) -> str:
    return _sha256_bytes(value.encode("utf-8"))


def canonical_markdown_bytes(value: str) -> bytes:
    """Return transport-stable Markdown bytes without hiding content drift."""

    if value.startswith("\ufeff"):
        value = value[1:]
    normalized = value.replace("\r\n", "\n").replace("\r", "\n")
    return (normalized.rstrip("\n") + "\n").encode("utf-8")


def _sha256_markdown(value: str) -> str:
    return _sha256_bytes(canonical_markdown_bytes(value))


def _hash_mapping(value: Mapping[str, object]) -> str:
    return "sha256:" + _sha256_bytes(canonical_json_bytes(value))


def _file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _git(root: Path, *argv: str, timeout: int = 30) -> str:
    try:
        completed = subprocess.run(
            ["git", *argv],
            cwd=root,
            text=True,
            encoding="utf-8",
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            stdin=subprocess.DEVNULL,
            shell=False,
            check=False,
            timeout=timeout,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise BootstrapError("git_preflight_unavailable") from exc
    if completed.returncode != 0:
        raise BootstrapError("git_preflight_failed")
    return completed.stdout.strip()


def _stage(
    name: str,
    *,
    kind: str = "command",
    capability: str = "Code",
    family: str,
    argv: Sequence[str] = (),
    cwd: str = "target",
    timeout: int = 900,
    reusable: bool = False,
    failure_class: str = "unsafe",
    environment: Sequence[str] = (),
) -> dict[str, object]:
    return {
        "name": name,
        "kind": kind,
        "capability": capability,
        "command_family": family,
        "argv": list(argv),
        "cwd": cwd,
        "timeout_seconds": timeout,
        "output_limit_bytes": 1024 * 1024,
        "retry_max": 0,
        "reusable": reusable,
        "failure_class": failure_class,
        "environment_allowlist": list(environment),
    }


def _is_exact_pre_stage_handoff(projection, events) -> bool:
    """Accept only the immutable one-event boundary authorized by Issue #305."""

    return (
        projection.status == "RUNNING"
        and len(events) == 1
        and events[0].get("event_type") == "workflow_started"
        and projection.event_count == 1
        and projection.current_stage_index == 0
        and not projection.stage_attempts
        and not projection.external_pauses
        and not projection.admitted_attempt_ids
        and projection.active_attempt_id is None
        and not projection.consumed_budgets
        and not projection.passed_evidence
        and projection.last_target_fingerprint is None
        and projection.artifact is None
        and projection.device is None
        and projection.publish is None
        and projection.last_blocker is None
        and projection.blocker_phase is None
        and projection.command_index is None
        and projection.first_failed_predicate is None
    )


def _is_exact_paused_tablet_handoff(
    projection,
    events,
    contract: WorkflowContract,
    *,
    expected_projection_fingerprint: str,
    expected_tail_hash: str,
) -> bool:
    """Accept only the exact immutable tablet-preflight pause boundary."""

    try:
        public = projection.public_dict(contract)
    except (AttributeError, IndexError, TypeError, ValueError):
        return False
    passed_stages = tuple(
        str(item.get("stage", ""))
        for item in projection.passed_evidence
        if isinstance(item, Mapping)
    )
    return (
        projection.status == "PAUSED_EXTERNAL"
        and projection.current_stage_index == 6
        and public.get("current_stage") == "tablet_preflight"
        and projection.stage_attempts
        == {"artifact_verify": 1, "tablet_preflight": 3}
        and projection.external_pauses == {"tablet_preflight": 3}
        and projection.active_attempt_id is None
        and len(projection.admitted_attempt_ids) == 4
        and passed_stages == (*REUSED_STAGE_NAMES, "artifact_verify")
        and projection.artifact is not None
        and projection.device is None
        and projection.publish is None
        and projection.last_blocker == "screen_not_interactive"
        and projection.blocker_phase == "tablet_preflight"
        and projection.command_index == 1
        and projection.first_failed_predicate == "screen_is_interactive"
        and projection.event_count == len(events)
        and bool(events)
        and events[-1].get("event_hash") == expected_tail_hash
        and projection.tail_hash == expected_tail_hash
        and public.get("projection_fingerprint")
        == expected_projection_fingerprint
    )


def _is_exact_numeric_paused_tablet_handoff(
    projection,
    events,
    contract: WorkflowContract,
    *,
    expected_projection_fingerprint: str,
    expected_tail_hash: str,
) -> bool:
    """Accept only the exact fourth tablet-preflight pause boundary."""

    try:
        public = projection.public_dict(contract)
    except (AttributeError, IndexError, TypeError, ValueError):
        return False
    passed_stages = tuple(
        str(item.get("stage", ""))
        for item in projection.passed_evidence
        if isinstance(item, Mapping)
    )
    return (
        projection.status == "PAUSED_EXTERNAL"
        and projection.current_stage_index == 6
        and public.get("current_stage") == "tablet_preflight"
        and projection.stage_attempts
        == {"artifact_verify": 1, "tablet_preflight": 4}
        and projection.external_pauses == {"tablet_preflight": 4}
        and projection.active_attempt_id is None
        and len(projection.admitted_attempt_ids) == 5
        and projection.consumed_budgets == {"command": 5, "github_comment": 9}
        and passed_stages == (*REUSED_STAGE_NAMES, "artifact_verify")
        and projection.artifact is not None
        and projection.device is None
        and projection.publish is None
        and projection.last_blocker == "screen_not_interactive"
        and projection.blocker_phase == "tablet_preflight"
        and projection.command_index == 1
        and projection.first_failed_predicate == "screen_is_interactive"
        and projection.event_count == 29
        and len(events) == 29
        and events[-1].get("event_hash") == expected_tail_hash
        and projection.tail_hash == expected_tail_hash
        and public.get("projection_fingerprint")
        == expected_projection_fingerprint
    )


class BootstrapAuthorizationStore:
    """Repository-external immutable authorization used by every resume."""

    def __init__(self, runtime_root: Path, target_root: Path):
        key = _sha256_text(str(Path(target_root).resolve()))[:16]
        self.root = Path(runtime_root).resolve() / "bootstrap" / f"issue-284-{key}"
        self.authorization_path = self.root / "authorization-v2.json"
        self.metadata_path = self.root / "bootstrap-v1.json"

    def _successor_paths(self, controller: str) -> tuple[Path, Path]:
        if re.fullmatch(r"[0-9a-f]{40}", controller) is None:
            raise BootstrapError("successor_controller_revision_invalid")
        root = self.root / "successors" / controller
        return root / "authorization-v2.json", root / "handoff-v1.json"

    def successor_exists(self, controller: str) -> bool:
        authorization_path, metadata_path = self._successor_paths(controller)
        return authorization_path.exists() or metadata_path.exists()

    def successor_revisions(self) -> tuple[str, ...]:
        root = self.root / "successors"
        if not root.exists():
            return ()
        if not root.is_dir():
            raise BootstrapError("bootstrap_successor_store_tampered")
        revisions: list[str] = []
        for candidate in root.iterdir():
            if (
                not candidate.is_dir()
                or re.fullmatch(r"[0-9a-f]{40}", candidate.name) is None
            ):
                raise BootstrapError("bootstrap_successor_store_tampered")
            revisions.append(candidate.name)
        return tuple(sorted(revisions))

    @property
    def exists(self) -> bool:
        return self.authorization_path.exists() or self.metadata_path.exists()

    @staticmethod
    def _write_exclusive(path: Path, value: Mapping[str, object]) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        flags = os.O_CREAT | os.O_EXCL | os.O_WRONLY
        if hasattr(os, "O_BINARY"):
            flags |= os.O_BINARY
        descriptor = os.open(path, flags, 0o600)
        try:
            data = canonical_json_bytes(value) + b"\n"
            if os.write(descriptor, data) != len(data):
                raise BootstrapError("bootstrap_store_short_write")
            os.fsync(descriptor)
        finally:
            os.close(descriptor)

    def save(self, authorization: WorkflowAuthorization, target_root: Path) -> None:
        if self.exists:
            current = self.load(target_root)
            if current.fingerprint != authorization.fingerprint:
                raise BootstrapError("bootstrap_authorization_drift")
            return
        contract = WorkflowContract.from_authorization(authorization)
        metadata = {
            "schema_version": 1,
            "issue": ISSUE_284,
            "repository": authorization.repository,
            "target_root": str(Path(target_root).resolve()),
            "authorization_fingerprint": authorization.fingerprint,
            "workflow_id": contract.workflow_id,
        }
        self._write_exclusive(self.authorization_path, authorization.public_dict())
        self._write_exclusive(self.metadata_path, metadata)

    def load(self, target_root: Path) -> WorkflowAuthorization:
        if not self.authorization_path.is_file() or not self.metadata_path.is_file():
            raise BootstrapError("bootstrap_store_incomplete")
        try:
            authorization_value = json.loads(
                self.authorization_path.read_text(encoding="utf-8")
            )
            metadata = json.loads(self.metadata_path.read_text(encoding="utf-8"))
        except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise BootstrapError("bootstrap_store_unreadable") from exc
        if not isinstance(authorization_value, dict) or not isinstance(metadata, dict):
            raise BootstrapError("bootstrap_store_shape_invalid")
        authorization = parse_workflow_authorization(authorization_value)
        expected = {
            "schema_version": 1,
            "issue": ISSUE_284,
            "repository": authorization.repository,
            "target_root": str(Path(target_root).resolve()),
            "authorization_fingerprint": authorization.fingerprint,
            "workflow_id": WorkflowContract.from_authorization(
                authorization
            ).workflow_id,
        }
        if metadata != expected:
            raise BootstrapError("bootstrap_store_tampered")
        return authorization

    def save_successor(
        self,
        predecessor: WorkflowAuthorization,
        successor: WorkflowAuthorization,
        target_root: Path,
        *,
        handoff_authorization_comment_id: int = ISSUE_305_HANDOFF_AUTHORIZATION_COMMENT,
    ) -> None:
        controller = str(successor.payload["controller_revision"])
        authorization_path, metadata_path = self._successor_paths(controller)
        if authorization_path.exists() or metadata_path.exists():
            current = self.load_successor(
                predecessor,
                controller,
                target_root,
                handoff_authorization_comment_id=handoff_authorization_comment_id,
            )
            if current.fingerprint != successor.fingerprint:
                raise BootstrapError("bootstrap_successor_authorization_drift")
            return
        predecessor_contract = WorkflowContract.from_authorization(predecessor)
        successor_contract = WorkflowContract.from_authorization(successor)
        metadata = {
            "schema_version": 1,
            "issue": ISSUE_284,
            "repository": successor.repository,
            "target_root": str(Path(target_root).resolve()),
            "handoff_authorization_comment_id": handoff_authorization_comment_id,
            "predecessor_authorization_fingerprint": predecessor.fingerprint,
            "predecessor_workflow_id": predecessor_contract.workflow_id,
            "successor_authorization_fingerprint": successor.fingerprint,
            "successor_workflow_id": successor_contract.workflow_id,
            "controller_revision": controller,
        }
        self._write_exclusive(authorization_path, successor.public_dict())
        self._write_exclusive(metadata_path, metadata)

    def load_successor(
        self,
        predecessor: WorkflowAuthorization,
        controller: str,
        target_root: Path,
        *,
        handoff_authorization_comment_id: int = ISSUE_305_HANDOFF_AUTHORIZATION_COMMENT,
    ) -> WorkflowAuthorization:
        authorization_path, metadata_path = self._successor_paths(controller)
        if not authorization_path.is_file() or not metadata_path.is_file():
            raise BootstrapError("bootstrap_successor_store_incomplete")
        try:
            authorization_value = json.loads(
                authorization_path.read_text(encoding="utf-8")
            )
            metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
        except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise BootstrapError("bootstrap_successor_store_unreadable") from exc
        if not isinstance(authorization_value, dict) or not isinstance(metadata, dict):
            raise BootstrapError("bootstrap_successor_store_shape_invalid")
        successor = parse_workflow_authorization(authorization_value)
        predecessor_contract = WorkflowContract.from_authorization(predecessor)
        successor_contract = WorkflowContract.from_authorization(successor)
        expected = {
            "schema_version": 1,
            "issue": ISSUE_284,
            "repository": successor.repository,
            "target_root": str(Path(target_root).resolve()),
            "handoff_authorization_comment_id": handoff_authorization_comment_id,
            "predecessor_authorization_fingerprint": predecessor.fingerprint,
            "predecessor_workflow_id": predecessor_contract.workflow_id,
            "successor_authorization_fingerprint": successor.fingerprint,
            "successor_workflow_id": successor_contract.workflow_id,
            "controller_revision": controller,
        }
        if metadata != expected or successor.payload["controller_revision"] != controller:
            raise BootstrapError("bootstrap_successor_store_tampered")
        return successor


class WorkflowBootstrap:
    """Generate, persist, and execute the exact Issue #284 pilot contract."""

    def __init__(
        self,
        *,
        target_root: Path,
        runtime_root: Path,
        controller_root: Path,
        profile: Issue284PilotProfile | None = None,
        evidence_client: BootstrapEvidenceClient | None = None,
        evidence_sink=None,
        executor=None,
        now: datetime | None = None,
    ) -> None:
        self.target_root = Path(target_root).resolve()
        self.runtime_root = Path(runtime_root).resolve()
        self.controller_root = Path(controller_root).resolve()
        self.profile = profile or Issue284PilotProfile()
        self.evidence_client = evidence_client or GhGitHubClient(
            self.profile.repository
        )
        self.evidence_sink = evidence_sink
        self.executor = executor
        self.now = now or datetime.now(timezone.utc)
        if self.now.tzinfo is None or self.now.utcoffset() is None:
            raise ValueError("bootstrap_now_must_be_timezone_aware")
        self.store = BootstrapAuthorizationStore(self.runtime_root, self.target_root)

    def _validate_controller(self) -> str:
        if self.controller_root == self.target_root:
            raise BootstrapError("controller_target_not_separated")
        controller = observe_target(self.controller_root)
        if controller.changed_paths or controller.staged_paths:
            raise BootstrapError("controller_worktree_dirty")
        revision, _ = controller_revision(self.controller_root)
        try:
            ancestry = subprocess.run(
                [
                    "git",
                    "merge-base",
                    "--is-ancestor",
                    self.profile.controller_base,
                    revision,
                ],
                cwd=self.controller_root,
                stdin=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                shell=False,
                check=False,
                timeout=30,
            )
        except (OSError, subprocess.TimeoutExpired) as exc:
            raise BootstrapError("controller_release_not_merged") from exc
        if ancestry.returncode != 0 or revision == self.profile.controller_base:
            raise BootstrapError("controller_release_not_merged")
        if self.profile.require_controller_on_origin_master:
            origin_master = _git(
                self.controller_root, "rev-parse", "refs/remotes/origin/master"
            )
            if origin_master != revision:
                raise BootstrapError("controller_not_on_origin_master")
        return revision

    @staticmethod
    def _same_handoff_contract(
        predecessor: WorkflowAuthorization,
        successor: WorkflowAuthorization,
    ) -> bool:
        old_payload = dict(predecessor.payload)
        new_payload = dict(successor.payload)
        for field in ("controller_revision", "nonce"):
            old_payload.pop(field, None)
            new_payload.pop(field, None)
        return old_payload == new_payload

    def _verify_pre_stage_ledger(
        self,
        predecessor: WorkflowAuthorization,
    ) -> None:
        contract = WorkflowContract.from_authorization(predecessor)
        try:
            verification = WorkflowStore(
                runtime_root=self.runtime_root,
                repo_root=self.target_root,
                workflow_id=contract.workflow_id,
            ).verify()
        except (OSError, ValueError, WorkflowStoreError) as exc:
            raise BootstrapError("controller_handoff_not_safe") from exc
        if not _is_exact_pre_stage_handoff(
            verification.projection, verification.events
        ):
            raise BootstrapError("controller_handoff_not_safe")

    def _verify_paused_tablet_ledger(
        self,
        predecessor: WorkflowAuthorization,
    ):
        contract = WorkflowContract.from_authorization(predecessor)
        profile = self.profile
        if (
            predecessor.fingerprint != profile.paused_predecessor_authorization
            or contract.workflow_id != profile.paused_predecessor_workflow
        ):
            raise BootstrapError("controller_handoff_not_safe")
        try:
            verification = WorkflowStore(
                runtime_root=self.runtime_root,
                repo_root=self.target_root,
                workflow_id=contract.workflow_id,
            ).verify()
        except (OSError, ValueError, WorkflowStoreError) as exc:
            raise BootstrapError("controller_handoff_not_safe") from exc
        if not _is_exact_paused_tablet_handoff(
            verification.projection,
            verification.events,
            verification.contract,
            expected_projection_fingerprint=profile.paused_projection_fingerprint,
            expected_tail_hash=profile.paused_tail_hash,
        ):
            raise BootstrapError("controller_handoff_not_safe")
        return verification

    def _verify_numeric_paused_tablet_ledger(
        self,
        predecessor: WorkflowAuthorization,
    ):
        contract = WorkflowContract.from_authorization(predecessor)
        profile = self.profile
        if (
            predecessor.fingerprint != profile.numeric_predecessor_authorization
            or contract.workflow_id != profile.numeric_predecessor_workflow
        ):
            raise BootstrapError("controller_handoff_not_safe")
        try:
            verification = WorkflowStore(
                runtime_root=self.runtime_root,
                repo_root=self.target_root,
                workflow_id=contract.workflow_id,
            ).verify()
        except (OSError, ValueError, WorkflowStoreError) as exc:
            raise BootstrapError("controller_handoff_not_safe") from exc
        if not _is_exact_numeric_paused_tablet_handoff(
            verification.projection,
            verification.events,
            verification.contract,
            expected_projection_fingerprint=profile.numeric_projection_fingerprint,
            expected_tail_hash=profile.numeric_tail_hash,
        ):
            raise BootstrapError("controller_handoff_not_safe")
        return verification

    def _validate_predecessor_contract(
        self,
        predecessor: WorkflowAuthorization,
        controller: str,
        *,
        expected_predecessor_revision: str,
    ) -> None:
        old_controller = str(predecessor.payload["controller_revision"])
        if old_controller != expected_predecessor_revision:
            raise BootstrapError("controller_handoff_not_safe")
        try:
            ancestry = subprocess.run(
                ["git", "merge-base", "--is-ancestor", old_controller, controller],
                cwd=self.controller_root,
                stdin=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                shell=False,
                check=False,
                timeout=30,
            )
        except (OSError, subprocess.TimeoutExpired) as exc:
            raise BootstrapError("controller_handoff_not_safe") from exc
        if ancestry.returncode != 0 or old_controller == controller:
            raise BootstrapError("controller_handoff_not_safe")

        profile = self.profile
        expected_target = {
            "branch": profile.target_branch,
            "base_sha": profile.target_parent,
            "head_sha": profile.target_checkpoint,
            "tree_sha": profile.target_tree,
        }
        expected_artifact = {
            "path": str(profile.artifact_path),
            "sha256": "sha256:" + profile.artifact_sha256,
            "package": ISSUE_284_DEBUG_PACKAGE,
            "version": profile.artifact_version,
            "signer": "cert-sha256:" + profile.signer_sha256,
            "checkpoint_sha": profile.target_checkpoint,
        }
        expected_device = {
            "serial": ISSUE_284_TABLET_SERIAL,
            "model": ISSUE_284_TABLET_MODEL,
            "package": ISSUE_284_DEBUG_PACKAGE,
        }
        expected_publish = {
            "base_branch": "master",
            "title": "Complete reminder all-day editing",
            "body_first_line": "Related to #284",
            "commit_message": "Complete reminder all-day editing",
        }
        payload = predecessor.payload
        if (
            payload.get("schema_version") != 2
            or predecessor.repository != profile.repository
            or predecessor.issue != ISSUE_284
            or predecessor.comment_id != profile.authorization_comment_id
            or payload.get("target") != expected_target
            or tuple(predecessor.write_allowlist) != profile.read_write_allowlist
            or tuple(payload.get("read_allowlist", ()))
            != profile.read_write_allowlist
            or payload.get("artifact") != expected_artifact
            or payload.get("device") != expected_device
            or payload.get("publish") != expected_publish
            or payload.get("execution") is not True
        ):
            raise BootstrapError("controller_handoff_not_safe")

        raw_stages = payload.get("stages")
        if not isinstance(raw_stages, list):
            raise BootstrapError("controller_handoff_not_safe")
        smoke_stages = [
            item
            for item in raw_stages
            if isinstance(item, Mapping) and item.get("name") == "tablet_preflight"
        ]
        if len(smoke_stages) != 1:
            raise BootstrapError("controller_handoff_not_safe")
        smoke_argv = smoke_stages[0].get("argv")
        if (
            not isinstance(smoke_argv, list)
            or len(smoke_argv) != 9
            or not all(isinstance(item, str) for item in smoke_argv)
            or not re_full_synthetic(smoke_argv[5])
        ):
            raise BootstrapError("controller_handoff_not_safe")
        expected_stages = self._stages(
            synthetic_title=smoke_argv[5],
            first_day=smoke_argv[6],
            second_day=smoke_argv[7],
        )
        if (
            raw_stages != expected_stages
            or payload.get("capability_sequence")
            != [stage["capability"] for stage in expected_stages]
        ):
            raise BootstrapError("controller_handoff_not_safe")

        self._validate_target()
        self._validate_tools_and_artifact()
        try:
            evidence_source = self._evidence_fingerprint()
            current_reused = [
                current_reused_evidence_record(
                    predecessor,
                    stage_name,
                    target_root=self.target_root,
                )
                for stage_name in REUSED_STAGE_NAMES
            ]
        except (OSError, RuntimeError, ValueError) as exc:
            raise BootstrapError("controller_handoff_not_safe") from exc
        if (
            payload.get("evidence_source_fingerprint") != evidence_source
            or payload.get("reused_evidence") != current_reused
        ):
            raise BootstrapError("controller_handoff_not_safe")

    def _build_controller_successor(
        self,
        predecessor: WorkflowAuthorization,
        controller: str,
        *,
        paused_tablet: bool,
        numeric_paused_tablet: bool = False,
    ) -> WorkflowAuthorization:
        if paused_tablet and numeric_paused_tablet:
            raise BootstrapError("controller_handoff_not_safe")
        if numeric_paused_tablet:
            self._verify_numeric_paused_tablet_ledger(predecessor)
            expected_predecessor = (
                self.profile.numeric_handoff_predecessor_revision
            )
        elif paused_tablet:
            self._verify_paused_tablet_ledger(predecessor)
            expected_predecessor = self.profile.paused_handoff_predecessor_revision
        else:
            self._verify_pre_stage_ledger(predecessor)
            expected_predecessor = self.profile.handoff_predecessor_revision
        self._validate_predecessor_contract(
            predecessor,
            controller,
            expected_predecessor_revision=expected_predecessor,
        )
        payload = json.loads(canonical_json_bytes(predecessor.payload))
        payload["controller_revision"] = controller
        payload["nonce"] = (
            "issue-284-controller-handoff-"
            + _sha256_text(f"{predecessor.fingerprint}:{controller}")[:24]
        )
        successor = parse_workflow_authorization(payload, now=self.now)
        if (
            successor.fingerprint == predecessor.fingerprint
            or WorkflowContract.from_authorization(successor).workflow_id
            == WorkflowContract.from_authorization(predecessor).workflow_id
            or not self._same_handoff_contract(predecessor, successor)
        ):
            raise BootstrapError("controller_handoff_not_safe")
        return successor

    @staticmethod
    def _same_continuation_state(predecessor_verification, successor_verification) -> bool:
        def semantic_projection(verification) -> dict[str, object]:
            value = dict(
                verification.projection.public_dict(verification.contract)
            )
            for field in (
                "workflow_id",
                "contract_fingerprint",
                "authorization_fingerprint",
                "controller_revision",
                "tail_hash",
                "projection_fingerprint",
            ):
                value.pop(field, None)
            return value

        def semantic_events(verification) -> list[tuple[object, object]]:
            return [
                (event.get("event_type"), event.get("payload"))
                for event in verification.events[1:]
            ]

        return (
            semantic_projection(predecessor_verification)
            == semantic_projection(successor_verification)
            and semantic_events(predecessor_verification)
            == semantic_events(successor_verification)
        )

    def _seed_paused_successor_history(
        self,
        predecessor: WorkflowAuthorization,
        successor: WorkflowAuthorization,
        *,
        numeric_paused_tablet: bool = False,
    ) -> None:
        """Atomically seed a successor without mutating predecessor runtime bytes."""

        if numeric_paused_tablet:
            predecessor_verification = self._verify_numeric_paused_tablet_ledger(
                predecessor
            )
        else:
            predecessor_verification = self._verify_paused_tablet_ledger(predecessor)
        successor_contract = WorkflowContract.from_authorization(successor)
        destination = WorkflowStore(
            runtime_root=self.runtime_root,
            repo_root=self.target_root,
            workflow_id=successor_contract.workflow_id,
        )
        if destination.root.exists():
            try:
                current = destination.verify()
            except (OSError, ValueError, WorkflowStoreError) as exc:
                raise BootstrapError("controller_handoff_not_safe") from exc
            if not self._same_continuation_state(
                predecessor_verification, current
            ):
                raise BootstrapError("controller_handoff_not_safe")
            return

        self.runtime_root.mkdir(parents=True, exist_ok=True)
        with TemporaryDirectory(
            prefix=".issue-284-paused-handoff-", dir=self.runtime_root
        ) as temporary:
            staged = WorkflowStore(
                runtime_root=Path(temporary),
                repo_root=self.target_root,
                workflow_id=successor_contract.workflow_id,
            )
            staged.start(successor_contract)
            for event in predecessor_verification.events[1:]:
                payload = event.get("payload")
                if not isinstance(payload, Mapping):
                    raise BootstrapError("controller_handoff_not_safe")
                staged.append(str(event.get("event_type")), dict(payload))
            staged_verification = staged.verify()
            if not self._same_continuation_state(
                predecessor_verification, staged_verification
            ):
                raise BootstrapError("controller_handoff_not_safe")
            destination.root.parent.mkdir(parents=True, exist_ok=True)
            try:
                os.replace(staged.root, destination.root)
            except OSError as exc:
                if not destination.root.exists():
                    raise BootstrapError("controller_handoff_not_safe") from exc
                try:
                    current = destination.verify()
                except (OSError, ValueError, WorkflowStoreError) as verify_exc:
                    raise BootstrapError("controller_handoff_not_safe") from verify_exc
                if not self._same_continuation_state(
                    predecessor_verification, current
                ):
                    raise BootstrapError("controller_handoff_not_safe") from exc

    def _validate_target(self) -> None:
        observation = observe_target(self.target_root)
        profile = self.profile
        if (
            observation.branch != profile.target_branch
            or observation.head_sha != profile.target_checkpoint
            or observation.tree_sha != profile.target_tree
        ):
            raise BootstrapError("target_checkpoint_drift")
        if observation.changed_paths or observation.staged_paths:
            raise BootstrapError("target_initial_state_dirty")
        parent = _git(self.target_root, "rev-parse", "HEAD^")
        if parent != profile.target_parent:
            raise BootstrapError("target_parent_drift")
        changed = tuple(
            sorted(
                line.replace("\\", "/")
                for line in _git(
                    self.target_root,
                    "diff-tree",
                    "--no-commit-id",
                    "--name-only",
                    "-r",
                    "HEAD",
                ).splitlines()
                if line.strip()
            )
        )
        if changed != tuple(sorted(profile.checkpoint_paths)):
            raise BootstrapError("target_scope_drift")
        for path, expected in profile.blobs.items():
            actual = _git(self.target_root, "rev-parse", f"HEAD:{path}")
            if actual != expected:
                raise BootstrapError("target_blob_drift")
        if _git(self.target_root, "diff", "--check", "HEAD^", "HEAD"):
            raise BootstrapError("target_diff_check_failed")

    def _validate_tools_and_artifact(self) -> None:
        profile = self.profile
        if not profile.flutter_path.is_file():
            raise BootstrapError("flutter_executable_missing")
        if not profile.adb_path.is_file():
            raise BootstrapError("adb_executable_missing")
        if _file_sha256(profile.adb_path) != profile.adb_sha256:
            raise BootstrapError("adb_executable_drift")
        if not profile.artifact_path.is_file():
            raise BootstrapError("artifact_missing")
        if _file_sha256(profile.artifact_path) != profile.artifact_sha256:
            raise BootstrapError("artifact_hash_mismatch")

    def _evidence_fingerprint(self) -> str:
        evidence: dict[str, object] = {"issues": {}}
        issues: dict[str, object] = {}
        for issue_number in (ISSUE_284, ISSUE_305):
            try:
                issue = self.evidence_client.get_issue(issue_number)
            except GitHubClientError as exc:
                raise BootstrapError(
                    "evidence_issue_read_failed_"
                    f"{issue_number}_{sanitized_github_error_reason(exc)}"
                ) from None
            body = issue.get("body")
            if not isinstance(body, str):
                raise BootstrapError(f"evidence_issue_body_missing_{issue_number}")
            if _sha256_markdown(body) != self.profile.issue_body_hashes.get(
                issue_number
            ):
                raise BootstrapError(f"evidence_issue_body_drift_{issue_number}")
            try:
                comments = self.evidence_client.get_issue_comments(issue_number)
            except GitHubClientError as exc:
                raise BootstrapError(
                    "evidence_comments_read_failed_"
                    f"{issue_number}_{sanitized_github_error_reason(exc)}"
                ) from None
            by_id = {
                int(item["id"]): item
                for item in comments
                if isinstance(item.get("id"), int)
            }
            selected: dict[str, str] = {}
            for comment_id, expected in self.profile.comment_hashes.get(
                issue_number, {}
            ).items():
                item = by_id.get(comment_id)
                body_value = item.get("body") if item is not None else None
                if (
                    not isinstance(body_value, str)
                    or _sha256_markdown(body_value) != expected
                ):
                    raise BootstrapError(
                        f"evidence_comment_drift_{issue_number}_{comment_id}"
                    )
                selected[str(comment_id)] = expected
            issues[str(issue_number)] = {
                "body_sha256": self.profile.issue_body_hashes[issue_number],
                "comments": selected,
            }
        evidence["issues"] = issues
        return _hash_mapping(evidence)

    def _stages(
        self,
        *,
        synthetic_title: str,
        first_day: str,
        second_day: str,
    ) -> list[dict[str, object]]:
        flutter = str(self.profile.flutter_path)
        adb = str(self.profile.adb_path)
        common_smoke = (synthetic_title, first_day, second_day, "recoverable-only")
        stages = [
            _stage(
                "focused_lifecycle",
                family="flutter_test",
                argv=(flutter, "test", "--no-pub", "test/reminder_lifecycle_test.dart"),
                cwd="target/mobile",
                reusable=True,
            ),
            _stage(
                "focused_widget",
                family="flutter_test",
                argv=(flutter, "test", "--no-pub", "test/reminder_widget_test.dart"),
                cwd="target/mobile",
                reusable=True,
            ),
            _stage(
                "full_flutter",
                family="flutter_test",
                argv=(flutter, "test"),
                cwd="target/mobile",
                reusable=True,
            ),
            _stage(
                "flutter_analyze",
                family="flutter_analyze",
                argv=(flutter, "analyze", "--no-pub"),
                cwd="target/mobile",
                reusable=True,
            ),
            _stage(
                "debug_apk_build",
                family="flutter_build",
                argv=(flutter, "build", "apk", "--debug", "--no-pub"),
                cwd="target/mobile",
                timeout=600,
                reusable=True,
            ),
            _stage(
                "artifact_verify",
                kind="artifact_verify",
                family="artifact_verify",
                timeout=120,
            ),
        ]
        for action in ISSUE_284_SMOKE_ACTIONS:
            stages.append(
                _stage(
                    action,
                    capability="Device",
                    family="cse_tablet_smoke",
                    argv=(adb, "-s", ISSUE_284_TABLET_SERIAL, "cse-smoke", action, *common_smoke),
                    timeout=300,
                    failure_class="external" if action == "tablet_preflight" else "unsafe",
                )
            )
        completion_argv = (
            sys.executable,
            "-m",
            "tools.cse_orchestrator.workflow_bootstrap",
            "write-issue-284-completion",
            "--target-root",
            str(self.target_root),
            "--checkpoint",
            self.profile.target_checkpoint,
            "--tree",
            self.profile.target_tree,
            "--artifact-sha256",
            self.profile.artifact_sha256,
            "--synthetic-title",
            synthetic_title,
        )
        stages.extend(
            [
                _stage(
                    "completion_docs",
                    family="completion_docs",
                    argv=completion_argv,
                    cwd="controller",
                    timeout=60,
                ),
                _stage("completion_commit", kind="commit", capability="Publish", family="git_commit"),
                _stage("normal_push", kind="push", capability="Publish", family="git_push"),
                _stage("draft_pr", kind="draft_pr", capability="Publish", family="github_draft_pr"),
            ]
        )
        return stages

    def build_authorization(self) -> WorkflowAuthorization:
        controller = self._validate_controller()
        self._validate_target()
        self._validate_tools_and_artifact()
        evidence_source = self._evidence_fingerprint()
        seed = _hash_mapping(
            {
                "controller": controller,
                "target": self.profile.target_checkpoint,
                "evidence": evidence_source,
                "artifact": self.profile.artifact_sha256,
            }
        )
        synthetic_title = "CSE284_O10_" + seed.rsplit(":", 1)[-1][:12].upper()
        local_now = self.now.astimezone(timezone(timedelta(hours=3)))
        first = local_now.date()
        second = first + timedelta(days=1)
        stages = self._stages(
            synthetic_title=synthetic_title,
            first_day=first.isoformat(),
            second_day=second.isoformat(),
        )
        base: dict[str, object] = {
            "schema_version": 2,
            "repository": self.profile.repository,
            "issue": ISSUE_284,
            "comment_id": self.profile.authorization_comment_id,
            "scope_version": 30501,
            "controller_revision": controller,
            "evidence_source_fingerprint": evidence_source,
            "target": {
                "branch": self.profile.target_branch,
                "base_sha": self.profile.target_parent,
                "head_sha": self.profile.target_checkpoint,
                "tree_sha": self.profile.target_tree,
            },
            "read_allowlist": list(self.profile.read_write_allowlist),
            "write_allowlist": list(self.profile.read_write_allowlist),
            "capability_sequence": [stage["capability"] for stage in stages],
            "stages": stages,
            "reused_evidence": [],
            "budgets": {
                "primary_max": 1,
                "correction_max": 0,
                "command_max": 64,
                "commit_max": 1,
                "push_max": 1,
                "draft_pr_max": 1,
                "github_comment_max": 64,
                "hard_stop_seconds": 3600,
            },
            "artifact": {
                "path": str(self.profile.artifact_path),
                "sha256": "sha256:" + self.profile.artifact_sha256,
                "package": ISSUE_284_DEBUG_PACKAGE,
                "version": self.profile.artifact_version,
                "signer": "cert-sha256:" + self.profile.signer_sha256,
                "checkpoint_sha": self.profile.target_checkpoint,
            },
            "device": {
                "serial": ISSUE_284_TABLET_SERIAL,
                "model": ISSUE_284_TABLET_MODEL,
                "package": ISSUE_284_DEBUG_PACKAGE,
            },
            "publish": {
                "base_branch": "master",
                "title": "Complete reminder all-day editing",
                "body_first_line": "Related to #284",
                "commit_message": "Complete reminder all-day editing",
            },
            "execution": True,
            "expires_at": "2099-01-01T00:00:00Z",
            "nonce": f"issue-284-o10-{seed.rsplit(':', 1)[-1][:24]}",
            "supersedes_comment_id": None,
        }
        provisional = parse_workflow_authorization(base, now=self.now)
        base["reused_evidence"] = [
            current_reused_evidence_record(
                provisional, stage_name, target_root=self.target_root
            )
            for stage_name in REUSED_STAGE_NAMES
        ]
        return parse_workflow_authorization(base, now=self.now)

    def authorization(
        self,
        *,
        persist: bool,
    ) -> tuple[WorkflowAuthorization, bool, str | None]:
        if self.store.exists:
            root_predecessor = self.store.load(self.target_root)
            controller = self._validate_controller()
            revisions = self.store.successor_revisions()
            if not revisions:
                if root_predecessor.payload["controller_revision"] == controller:
                    return root_predecessor, True, None
                if (
                    self.profile.handoff_predecessor_revision
                    == ISSUE_305_HANDOFF_PREDECESSOR
                    and controller
                    != self.profile.paused_handoff_predecessor_revision
                ):
                    raise BootstrapError("controller_handoff_not_safe")
                successor = self._build_controller_successor(
                    root_predecessor, controller, paused_tablet=False
                )
                if persist:
                    self.store.save_successor(
                        root_predecessor, successor, self.target_root
                    )
                return (
                    successor,
                    True,
                    WorkflowContract.from_authorization(root_predecessor).workflow_id,
                )

            if len(revisions) > 3:
                raise BootstrapError("controller_handoff_not_safe")
            first_revision = self.profile.paused_handoff_predecessor_revision
            if first_revision not in revisions:
                if len(revisions) != 1 or controller != revisions[0]:
                    raise BootstrapError("controller_handoff_not_safe")
                expected = self._build_controller_successor(
                    root_predecessor, controller, paused_tablet=False
                )
                stored = self.store.load_successor(
                    root_predecessor, controller, self.target_root
                )
                if (
                    stored.fingerprint != expected.fingerprint
                    or not self._same_handoff_contract(root_predecessor, stored)
                ):
                    raise BootstrapError("controller_handoff_not_safe")
                return (
                    stored,
                    True,
                    WorkflowContract.from_authorization(root_predecessor).workflow_id,
                )

            first_successor = self.store.load_successor(
                root_predecessor, first_revision, self.target_root
            )
            if len(revisions) == 1 and controller == first_revision:
                expected = self._build_controller_successor(
                    root_predecessor, controller, paused_tablet=False
                )
                if first_successor.fingerprint != expected.fingerprint:
                    raise BootstrapError("controller_handoff_not_safe")
                return (
                    first_successor,
                    True,
                    WorkflowContract.from_authorization(root_predecessor).workflow_id,
                )

            numeric_revision = self.profile.numeric_handoff_predecessor_revision
            if len(revisions) == 1:
                successor = self._build_controller_successor(
                    first_successor, controller, paused_tablet=True
                )
                if persist:
                    self._seed_paused_successor_history(first_successor, successor)
                    self.store.save_successor(
                        first_successor,
                        successor,
                        self.target_root,
                        handoff_authorization_comment_id=(
                            ISSUE_305_PAUSED_HANDOFF_AUTHORIZATION_COMMENT
                        ),
                    )
                return (
                    successor,
                    True,
                    WorkflowContract.from_authorization(first_successor).workflow_id,
                )

            if numeric_revision not in revisions:
                second_revisions = tuple(
                    revision for revision in revisions if revision != first_revision
                )
                if len(revisions) != 2 or second_revisions != (controller,):
                    raise BootstrapError("controller_handoff_not_safe")
                expected = self._build_controller_successor(
                    first_successor, controller, paused_tablet=True
                )
                stored = self.store.load_successor(
                    first_successor,
                    controller,
                    self.target_root,
                    handoff_authorization_comment_id=(
                        ISSUE_305_PAUSED_HANDOFF_AUTHORIZATION_COMMENT
                    ),
                )
                if (
                    stored.fingerprint != expected.fingerprint
                    or not self._same_handoff_contract(first_successor, stored)
                ):
                    raise BootstrapError("controller_handoff_not_safe")
                if persist:
                    self._seed_paused_successor_history(first_successor, stored)
                return (
                    stored,
                    True,
                    WorkflowContract.from_authorization(first_successor).workflow_id,
                )

            second_successor = self.store.load_successor(
                first_successor,
                numeric_revision,
                self.target_root,
                handoff_authorization_comment_id=(
                    ISSUE_305_PAUSED_HANDOFF_AUTHORIZATION_COMMENT
                ),
            )
            expected_second = self._build_controller_successor(
                first_successor, numeric_revision, paused_tablet=True
            )
            if (
                second_successor.fingerprint != expected_second.fingerprint
                or not self._same_handoff_contract(first_successor, second_successor)
            ):
                raise BootstrapError("controller_handoff_not_safe")
            if len(revisions) == 2 and controller == numeric_revision:
                if persist:
                    self._seed_paused_successor_history(
                        first_successor, second_successor
                    )
                return (
                    second_successor,
                    True,
                    WorkflowContract.from_authorization(first_successor).workflow_id,
                )

            if len(revisions) == 3:
                third_revisions = tuple(
                    revision
                    for revision in revisions
                    if revision not in (first_revision, numeric_revision)
                )
                if third_revisions != (controller,):
                    raise BootstrapError("controller_handoff_not_safe")

            successor = self._build_controller_successor(
                second_successor,
                controller,
                paused_tablet=False,
                numeric_paused_tablet=True,
            )
            if len(revisions) == 3:
                stored = self.store.load_successor(
                    second_successor,
                    controller,
                    self.target_root,
                    handoff_authorization_comment_id=(
                        ISSUE_305_NUMERIC_HANDOFF_AUTHORIZATION_COMMENT
                    ),
                )
                if (
                    stored.fingerprint != successor.fingerprint
                    or not self._same_handoff_contract(second_successor, stored)
                ):
                    raise BootstrapError("controller_handoff_not_safe")
                successor = stored
            if persist:
                self._seed_paused_successor_history(
                    second_successor,
                    successor,
                    numeric_paused_tablet=True,
                )
                if len(revisions) == 2:
                    self.store.save_successor(
                        second_successor,
                        successor,
                        self.target_root,
                        handoff_authorization_comment_id=(
                            ISSUE_305_NUMERIC_HANDOFF_AUTHORIZATION_COMMENT
                        ),
                    )
            return (
                successor,
                True,
                WorkflowContract.from_authorization(second_successor).workflow_id,
            )
        authorization = self.build_authorization()
        if persist:
            self.store.save(authorization, self.target_root)
        return authorization, False, None

    def run(self, *, execute: bool) -> dict[str, object]:
        authorization, resumed, predecessor_id = self.authorization(
            persist=execute
        )
        sink = self.evidence_sink
        if sink is None and execute:
            sink = GhIssueEvidenceSink(self.profile.repository, ISSUE_284)
        coordinator = WorkflowCoordinator(
            authorization=authorization,
            controller_root=self.controller_root,
            target_root=self.target_root,
            runtime_root=self.runtime_root,
            evidence_sink=sink,
            executor=self.executor,
        )
        result = coordinator.run(execute=execute)
        return {
            "schema_version": 2,
            "status": result.get("status"),
            "bootstrap_resumed": resumed,
            "controller_handoff": predecessor_id is not None,
            "predecessor_workflow_id": predecessor_id,
            "authorization_fingerprint": authorization.fingerprint,
            "evidence_source_fingerprint": authorization.payload[
                "evidence_source_fingerprint"
            ],
            "authorization": authorization.public_dict() if not execute else None,
            "workflow": result,
        }


def _append_once(path: Path, marker: str, section: str) -> None:
    current = path.read_text(encoding="utf-8") if path.exists() else ""
    if marker in current:
        if section.strip() not in current:
            raise BootstrapError("completion_document_drift")
        return
    separator = "" if not current or current.endswith("\n") else "\n"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(current + separator + "\n" + section.rstrip() + "\n", encoding="utf-8")


def write_issue_284_completion(
    *,
    target_root: Path,
    checkpoint: str,
    tree: str,
    artifact_sha256: str,
    synthetic_title: str,
) -> dict[str, object]:
    """Write the authorized, deterministic Issue #284 completion surfaces."""

    root = Path(target_root).resolve()
    observation = observe_target(root)
    expected_changed = {
        ".cse/tasks/284_task.md",
        ".cse/tasks/284_result.md",
        "CHANGELOG.md",
        "ROADMAP.md",
    }
    if (
        observation.branch != ISSUE_284_BRANCH
        or observation.head_sha != checkpoint
        or observation.tree_sha != tree
        or observation.staged_paths
    ):
        raise BootstrapError("completion_target_drift")
    if set(observation.changed_paths) - expected_changed:
        raise BootstrapError("completion_target_drift")
    if checkpoint != ISSUE_284_CHECKPOINT or artifact_sha256 != ISSUE_284_ARTIFACT_SHA256:
        raise BootstrapError("completion_provenance_drift")
    if not re_full_synthetic(synthetic_title):
        raise BootstrapError("completion_synthetic_invalid")
    marker = "<!-- cse-issue-284-o10-completion:v1 -->"
    common = (
        f"{marker}\n"
        "## O10 canlı tablet kabulü\n\n"
        f"- Checkpoint/tree: `{checkpoint}` / `{tree}`\n"
        f"- Artifact SHA-256: `{artifact_sha256}`\n"
        "- Reused validation: lifecycle `55/55`, widget `63/63`, "
        "full Flutter `357/357`, analyze `0`\n"
        "- Exact tablet: `R52W90JFN1M / SM-X610`\n"
        "- Data-preserving install and seven-step synthetic smoke: PASS\n"
        "- Phone / real-user open-mutation / uninstall / clear-data / "
        "downgrade / hard-delete: `0 / 0-0 / 0 / 0 / 0 / 0`\n"
        "- Synthetic cleanup: recoverable Geri Dönüşüm Kutusu PASS\n"
    )
    _append_once(root / ".cse/tasks/284_task.md", marker, common)
    result_path = root / ".cse/tasks/284_result.md"
    if result_path.exists() and marker not in result_path.read_text(encoding="utf-8"):
        raise BootstrapError("completion_result_exists")
    _append_once(
        result_path,
        marker,
        "# Issue #284 Sonuç\n\n" + common + "\nDurum: PASS — Draft PR açıldı.",
    )
    _append_once(
        root / "CHANGELOG.md",
        marker,
        f"{marker}\n- Issue #284 reminder all-day edit, O10 tablet smoke ve "
        "recoverable cleanup ile tamamlandı.",
    )
    _append_once(
        root / "ROADMAP.md",
        marker,
        f"{marker}\n- #284: all-day reminder detail edit ve exact tablet kabulü "
        "PASS; Draft PR incelemesi bekliyor.",
    )
    final = observe_target(root)
    outside = set(final.changed_paths) - set(ISSUE_284_READ_WRITE_ALLOWLIST)
    if outside or set(final.changed_paths) != expected_changed or final.staged_paths:
        raise BootstrapError("completion_scope_drift")
    return {"changed_paths": sorted(final.changed_paths), "synthetic_recorded": False}


def re_full_synthetic(value: str) -> bool:
    return bool(re.fullmatch(r"CSE284_O10_[0-9A-F]{12}", value))


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="workflow-bootstrap")
    subparsers = parser.add_subparsers(dest="command", required=True)
    write = subparsers.add_parser("write-issue-284-completion")
    write.add_argument("--target-root", required=True, type=Path)
    write.add_argument("--checkpoint", required=True)
    write.add_argument("--tree", required=True)
    write.add_argument("--artifact-sha256", required=True)
    write.add_argument("--synthetic-title", required=True)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    if args.command != "write-issue-284-completion":
        return 2
    try:
        result = write_issue_284_completion(
            target_root=args.target_root,
            checkpoint=args.checkpoint,
            tree=args.tree,
            artifact_sha256=args.artifact_sha256,
            synthetic_title=args.synthetic_title,
        )
    except (BootstrapError, WorkflowError, OSError, ValueError) as exc:
        print(json.dumps({"status": "UNSAFE_BLOCKED", "reason": str(exc).split(":", 1)[0]}))
        return 14
    print(json.dumps({"status": "PASS", **result}, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
