"""Repository-external append-only workflow store and replayed O10 projection."""

from __future__ import annotations

import hashlib
import json
import os
import re
import tempfile
import threading
from dataclasses import dataclass, field
from pathlib import Path
from typing import Mapping

from .workflow_authorization import WorkflowAuthorization, canonical_json_bytes


GENESIS_HASH = "sha256:" + "0" * 64
HASH_PATTERN = re.compile(r"^sha256:[0-9a-f]{64}$")
WORKFLOW_ID_PATTERN = re.compile(r"^wf-[1-9][0-9]*-[0-9a-f]{12}$")
EVENT_TYPES = frozenset(
    {
        "workflow_started",
        "workflow_resumed",
        "target_observed",
        "stage_admitted",
        "stage_passed",
        "stage_reused",
        "stage_paused",
        "stage_failed",
        "github_evidence",
        "workflow_failed",
        "workflow_completed",
    }
)
WORKFLOW_STATUSES = frozenset(
    {
        "NEW",
        "RUNNING",
        "PAUSED_EXTERNAL",
        "AWAITING_USER_DECISION",
        "RESUMABLE_FAILURE",
        "UNSAFE_BLOCKED",
        "COMPLETED",
    }
)


class WorkflowStoreError(RuntimeError):
    """Workflow history, projection, or runtime placement is unsafe."""


def _hash_bytes(value: bytes) -> str:
    return "sha256:" + hashlib.sha256(value).hexdigest()


def _hash_mapping(value: Mapping[str, object]) -> str:
    return _hash_bytes(canonical_json_bytes(value))


def _is_relative_to(path: Path, root: Path) -> bool:
    try:
        path.relative_to(root)
        return True
    except ValueError:
        return False


@dataclass(frozen=True)
class WorkflowStageContract:
    name: str
    kind: str
    capability: str
    stage_fingerprint: str
    retry_max: int
    reusable: bool
    failure_class: str

    def public_dict(self) -> dict[str, object]:
        return {
            "name": self.name,
            "kind": self.kind,
            "capability": self.capability,
            "stage_fingerprint": self.stage_fingerprint,
            "retry_max": self.retry_max,
            "reusable": self.reusable,
            "failure_class": self.failure_class,
        }


@dataclass(frozen=True)
class WorkflowContract:
    workflow_id: str
    repository: str
    issue: int
    authorization_comment_id: int
    authorization_fingerprint: str
    controller_revision: str
    target: Mapping[str, object]
    stages: tuple[WorkflowStageContract, ...]
    budgets: Mapping[str, int]
    write_allowlist_fingerprint: str
    artifact_contract_fingerprint: str | None
    device_contract_fingerprint: str | None
    publish_contract_fingerprint: str | None
    contract_fingerprint: str

    @classmethod
    def from_authorization(cls, value: WorkflowAuthorization) -> "WorkflowContract":
        workflow_id = f"wf-{value.issue}-{value.fingerprint.split(':', 1)[1][:12]}"
        stages = tuple(
            WorkflowStageContract(
                name=stage.name,
                kind=stage.kind,
                capability=stage.capability,
                stage_fingerprint=_hash_mapping(stage.public_dict()),
                retry_max=stage.retry_max,
                reusable=stage.reusable,
                failure_class=stage.failure_class,
            )
            for stage in value.stages
        )
        payload = {
            "schema_version": 1,
            "workflow_id": workflow_id,
            "repository": value.repository,
            "issue": value.issue,
            "authorization_comment_id": value.comment_id,
            "authorization_fingerprint": value.fingerprint,
            "controller_revision": value.payload["controller_revision"],
            "target": dict(value.target),
            "stages": [item.public_dict() for item in stages],
            "budgets": dict(value.budgets),
            "write_allowlist_fingerprint": _hash_mapping(
                {"paths": list(value.write_allowlist)}
            ),
            "artifact_contract_fingerprint": (
                _hash_mapping(value.payload["artifact"])
                if isinstance(value.payload["artifact"], Mapping)
                else None
            ),
            "device_contract_fingerprint": (
                _hash_mapping(value.payload["device"])
                if isinstance(value.payload["device"], Mapping)
                else None
            ),
            "publish_contract_fingerprint": (
                _hash_mapping(value.payload["publish"])
                if isinstance(value.payload["publish"], Mapping)
                else None
            ),
        }
        fingerprint = _hash_mapping(payload)
        return cls(
            workflow_id=workflow_id,
            repository=value.repository,
            issue=value.issue,
            authorization_comment_id=value.comment_id,
            authorization_fingerprint=value.fingerprint,
            controller_revision=str(value.payload["controller_revision"]),
            target=dict(value.target),
            stages=stages,
            budgets=dict(value.budgets),
            write_allowlist_fingerprint=str(payload["write_allowlist_fingerprint"]),
            artifact_contract_fingerprint=payload["artifact_contract_fingerprint"],  # type: ignore[arg-type]
            device_contract_fingerprint=payload["device_contract_fingerprint"],  # type: ignore[arg-type]
            publish_contract_fingerprint=payload["publish_contract_fingerprint"],  # type: ignore[arg-type]
            contract_fingerprint=fingerprint,
        )

    @classmethod
    def from_dict(cls, value: Mapping[str, object]) -> "WorkflowContract":
        expected = {
            "schema_version",
            "workflow_id",
            "repository",
            "issue",
            "authorization_comment_id",
            "authorization_fingerprint",
            "controller_revision",
            "target",
            "stages",
            "budgets",
            "write_allowlist_fingerprint",
            "artifact_contract_fingerprint",
            "device_contract_fingerprint",
            "publish_contract_fingerprint",
            "contract_fingerprint",
        }
        if set(value) != expected or value.get("schema_version") != 1:
            raise WorkflowStoreError("workflow_contract_fields_invalid")
        workflow_id = value["workflow_id"]
        if not isinstance(workflow_id, str) or not WORKFLOW_ID_PATTERN.fullmatch(workflow_id):
            raise WorkflowStoreError("workflow_id_invalid")
        raw_stages = value["stages"]
        if not isinstance(raw_stages, list) or not raw_stages:
            raise WorkflowStoreError("workflow_contract_stages_invalid")
        stages: list[WorkflowStageContract] = []
        stage_fields = {
            "name",
            "kind",
            "capability",
            "stage_fingerprint",
            "retry_max",
            "reusable",
            "failure_class",
        }
        for item in raw_stages:
            if not isinstance(item, Mapping) or set(item) != stage_fields:
                raise WorkflowStoreError("workflow_stage_contract_invalid")
            if not isinstance(item["stage_fingerprint"], str) or not HASH_PATTERN.fullmatch(item["stage_fingerprint"]):
                raise WorkflowStoreError("workflow_stage_fingerprint_invalid")
            stages.append(WorkflowStageContract(**dict(item)))  # type: ignore[arg-type]
        contract = cls(
            workflow_id=workflow_id,
            repository=str(value["repository"]),
            issue=int(value["issue"]),
            authorization_comment_id=int(value["authorization_comment_id"]),
            authorization_fingerprint=str(value["authorization_fingerprint"]),
            controller_revision=str(value["controller_revision"]),
            target=dict(value["target"]),  # type: ignore[arg-type]
            stages=tuple(stages),
            budgets={str(key): int(item) for key, item in dict(value["budgets"]).items()},  # type: ignore[arg-type]
            write_allowlist_fingerprint=str(value["write_allowlist_fingerprint"]),
            artifact_contract_fingerprint=value["artifact_contract_fingerprint"],  # type: ignore[arg-type]
            device_contract_fingerprint=value["device_contract_fingerprint"],  # type: ignore[arg-type]
            publish_contract_fingerprint=value["publish_contract_fingerprint"],  # type: ignore[arg-type]
            contract_fingerprint=str(value["contract_fingerprint"]),
        )
        if contract.contract_fingerprint != _hash_mapping(contract.identity_payload()):
            raise WorkflowStoreError("workflow_contract_hash_mismatch")
        return contract

    def identity_payload(self) -> dict[str, object]:
        return {
            "schema_version": 1,
            "workflow_id": self.workflow_id,
            "repository": self.repository,
            "issue": self.issue,
            "authorization_comment_id": self.authorization_comment_id,
            "authorization_fingerprint": self.authorization_fingerprint,
            "controller_revision": self.controller_revision,
            "target": dict(self.target),
            "stages": [item.public_dict() for item in self.stages],
            "budgets": dict(self.budgets),
            "write_allowlist_fingerprint": self.write_allowlist_fingerprint,
            "artifact_contract_fingerprint": self.artifact_contract_fingerprint,
            "device_contract_fingerprint": self.device_contract_fingerprint,
            "publish_contract_fingerprint": self.publish_contract_fingerprint,
        }

    def public_dict(self) -> dict[str, object]:
        return {**self.identity_payload(), "contract_fingerprint": self.contract_fingerprint}


@dataclass
class WorkflowProjection:
    workflow_id: str
    repository: str
    issue: int
    contract_fingerprint: str
    authorization_fingerprint: str
    controller_revision: str
    target: dict[str, object]
    status: str = "NEW"
    current_stage_index: int = 0
    stage_attempts: dict[str, int] = field(default_factory=dict)
    external_pauses: dict[str, int] = field(default_factory=dict)
    passed_evidence: list[dict[str, object]] = field(default_factory=list)
    consumed_budgets: dict[str, int] = field(default_factory=dict)
    admitted_attempt_ids: list[str] = field(default_factory=list)
    active_attempt_id: str | None = None
    artifact: dict[str, object] | None = None
    device: dict[str, object] | None = None
    publish: dict[str, object] | None = None
    last_target_fingerprint: str | None = None
    last_blocker: str | None = None
    blocker_phase: str | None = None
    command_index: int | None = None
    first_failed_predicate: str | None = None
    event_count: int = 0
    tail_hash: str = GENESIS_HASH

    def public_dict(self, contract: WorkflowContract) -> dict[str, object]:
        current = (
            contract.stages[self.current_stage_index].name
            if self.current_stage_index < len(contract.stages)
            else None
        )
        value = {
            "schema_version": 1,
            "workflow_id": self.workflow_id,
            "repository": self.repository,
            "issue": self.issue,
            "contract_fingerprint": self.contract_fingerprint,
            "authorization_fingerprint": self.authorization_fingerprint,
            "controller_revision": self.controller_revision,
            "target": dict(self.target),
            "status": self.status,
            "current_stage_index": self.current_stage_index,
            "current_stage": current,
            "next_action": None if self.status == "COMPLETED" else current,
            "stage_attempts": dict(sorted(self.stage_attempts.items())),
            "external_pauses": dict(sorted(self.external_pauses.items())),
            "passed_evidence": list(self.passed_evidence),
            "consumed_budgets": dict(sorted(self.consumed_budgets.items())),
            "admitted_attempt_ids": list(self.admitted_attempt_ids),
            "active_attempt_id": self.active_attempt_id,
            "artifact": self.artifact,
            "device": self.device,
            "publish": self.publish,
            "last_target_fingerprint": self.last_target_fingerprint,
            "last_blocker": self.last_blocker,
            "blocker_phase": self.blocker_phase,
            "command_index": self.command_index,
            "first_failed_predicate": self.first_failed_predicate,
            "event_count": self.event_count,
            "tail_hash": self.tail_hash,
        }
        return {**value, "projection_fingerprint": _hash_mapping(value)}


@dataclass(frozen=True)
class WorkflowVerification:
    valid: bool
    contract: WorkflowContract
    projection: WorkflowProjection
    events: tuple[Mapping[str, object], ...]


def project_workflow_events(
    contract: WorkflowContract,
    events: tuple[Mapping[str, object], ...],
) -> WorkflowProjection:
    projection = WorkflowProjection(
        workflow_id=contract.workflow_id,
        repository=contract.repository,
        issue=contract.issue,
        contract_fingerprint=contract.contract_fingerprint,
        authorization_fingerprint=contract.authorization_fingerprint,
        controller_revision=contract.controller_revision,
        target=dict(contract.target),
    )
    for event in events:
        event_type = str(event["event_type"])
        payload = event["payload"]
        if not isinstance(payload, Mapping):
            raise WorkflowStoreError("workflow_event_payload_invalid")
        if event_type == "workflow_started":
            if projection.status != "NEW" or projection.event_count != 0:
                raise WorkflowStoreError("workflow_started_order_invalid")
            if payload != {
                "contract_fingerprint": contract.contract_fingerprint,
                "authorization_fingerprint": contract.authorization_fingerprint,
            }:
                raise WorkflowStoreError("workflow_started_identity_mismatch")
            projection.status = "RUNNING"
        elif event_type == "workflow_resumed":
            if projection.status not in {"PAUSED_EXTERNAL", "RESUMABLE_FAILURE"}:
                raise WorkflowStoreError("workflow_resume_state_invalid")
            if payload.get("stage_index") != projection.current_stage_index:
                raise WorkflowStoreError("workflow_resume_stage_invalid")
            projection.status = "RUNNING"
            projection.last_blocker = None
            projection.blocker_phase = None
            projection.command_index = None
            projection.first_failed_predicate = None
        elif event_type == "target_observed":
            fingerprint = payload.get("source_fingerprint")
            if not isinstance(fingerprint, str) or not HASH_PATTERN.fullmatch(fingerprint):
                raise WorkflowStoreError("target_fingerprint_invalid")
            projection.last_target_fingerprint = fingerprint
        elif event_type == "stage_admitted":
            if projection.status != "RUNNING":
                raise WorkflowStoreError("stage_admission_state_invalid")
            index = payload.get("stage_index")
            if index != projection.current_stage_index or not isinstance(index, int):
                raise WorkflowStoreError("stage_admission_index_invalid")
            stage = contract.stages[index]
            if payload.get("stage") != stage.name:
                raise WorkflowStoreError("stage_admission_name_invalid")
            expected_attempt = projection.stage_attempts.get(stage.name, 0) + 1
            if payload.get("attempt") != expected_attempt:
                raise WorkflowStoreError("stage_attempt_invalid")
            if payload.get("stage_fingerprint") != stage.stage_fingerprint:
                raise WorkflowStoreError("stage_contract_drift")
            attempt_id = payload.get("attempt_id")
            if (
                not isinstance(attempt_id, str)
                or not HASH_PATTERN.fullmatch(attempt_id)
                or attempt_id in projection.admitted_attempt_ids
                or projection.active_attempt_id is not None
            ):
                raise WorkflowStoreError("stage_attempt_identity_invalid")
            projection.admitted_attempt_ids.append(attempt_id)
            projection.active_attempt_id = attempt_id
            projection.stage_attempts[stage.name] = expected_attempt
            budget = payload.get("budget_counter")
            if not isinstance(budget, str) or not budget:
                raise WorkflowStoreError("stage_budget_counter_invalid")
            projection.consumed_budgets[budget] = (
                projection.consumed_budgets.get(budget, 0) + 1
            )
        elif event_type in {"stage_passed", "stage_reused"}:
            if projection.status != "RUNNING":
                raise WorkflowStoreError("stage_pass_state_invalid")
            index = payload.get("stage_index")
            if index != projection.current_stage_index or not isinstance(index, int):
                raise WorkflowStoreError("stage_pass_index_invalid")
            stage = contract.stages[index]
            if payload.get("stage") != stage.name:
                raise WorkflowStoreError("stage_pass_name_invalid")
            if event_type == "stage_passed" and projection.active_attempt_id is None:
                raise WorkflowStoreError("stage_result_without_admission")
            if event_type == "stage_reused" and projection.active_attempt_id is not None:
                raise WorkflowStoreError("stage_reuse_after_admission")
            evidence = payload.get("evidence")
            if not isinstance(evidence, Mapping):
                raise WorkflowStoreError("stage_evidence_invalid")
            fingerprint = evidence.get("evidence_fingerprint")
            if not isinstance(fingerprint, str) or not HASH_PATTERN.fullmatch(fingerprint):
                raise WorkflowStoreError("stage_evidence_fingerprint_invalid")
            projection.passed_evidence.append(dict(evidence))
            details = payload.get("details")
            if details is not None and not isinstance(details, Mapping):
                raise WorkflowStoreError("stage_details_invalid")
            details = dict(details or {})
            if "artifact" in details:
                projection.artifact = dict(details["artifact"])
            if "device" in details:
                projection.device = dict(details["device"])
            if "publish" in details:
                projection.publish = {
                    **dict(projection.publish or {}),
                    **dict(details["publish"]),
                }
            target_after = details.get("target_after_fingerprint")
            if target_after is not None:
                if not isinstance(target_after, str) or not HASH_PATTERN.fullmatch(target_after):
                    raise WorkflowStoreError("target_after_fingerprint_invalid")
                projection.last_target_fingerprint = target_after
            projection.current_stage_index += 1
            projection.active_attempt_id = None
            projection.last_blocker = None
            projection.blocker_phase = None
            projection.command_index = None
            projection.first_failed_predicate = None
        elif event_type == "stage_paused":
            if projection.status != "RUNNING":
                raise WorkflowStoreError("stage_pause_state_invalid")
            stage = contract.stages[projection.current_stage_index]
            if payload.get("stage") != stage.name:
                raise WorkflowStoreError("stage_pause_name_invalid")
            if projection.active_attempt_id is None:
                raise WorkflowStoreError("stage_pause_without_admission")
            projection.external_pauses[stage.name] = (
                projection.external_pauses.get(stage.name, 0) + 1
            )
            projection.status = "PAUSED_EXTERNAL"
            projection.active_attempt_id = None
            projection.last_blocker = str(payload.get("reason_code"))
            projection.blocker_phase = stage.name
            projection.command_index = payload.get("command_index")  # type: ignore[assignment]
            projection.first_failed_predicate = str(
                payload.get("first_failed_predicate")
            )
        elif event_type == "stage_failed":
            if projection.status != "RUNNING":
                raise WorkflowStoreError("stage_failure_state_invalid")
            stage = contract.stages[projection.current_stage_index]
            if payload.get("stage") != stage.name:
                raise WorkflowStoreError("stage_failure_name_invalid")
            classification = payload.get("classification")
            if projection.active_attempt_id is None and payload.get("command_index") != 0:
                raise WorkflowStoreError("stage_failure_without_admission")
            attempts = projection.stage_attempts.get(stage.name, 0)
            if classification == "resumable" and attempts <= stage.retry_max:
                projection.status = "RESUMABLE_FAILURE"
            elif classification == "decision":
                projection.status = "AWAITING_USER_DECISION"
            else:
                projection.status = "UNSAFE_BLOCKED"
            projection.active_attempt_id = None
            projection.last_blocker = str(payload.get("reason_code"))
            projection.blocker_phase = stage.name
            projection.command_index = payload.get("command_index")  # type: ignore[assignment]
            projection.first_failed_predicate = str(
                payload.get("first_failed_predicate")
            )
        elif event_type == "github_evidence":
            if not isinstance(payload.get("evidence_key"), str):
                raise WorkflowStoreError("github_evidence_key_invalid")
            projection.consumed_budgets["github_comment"] = (
                projection.consumed_budgets.get("github_comment", 0) + 1
            )
        elif event_type == "workflow_failed":
            if projection.status != "RUNNING":
                raise WorkflowStoreError("workflow_failure_state_invalid")
            projection.status = "UNSAFE_BLOCKED"
            projection.last_blocker = str(payload.get("reason_code"))
            projection.blocker_phase = str(payload.get("phase"))
            projection.command_index = payload.get("command_index")  # type: ignore[assignment]
            projection.first_failed_predicate = str(
                payload.get("first_failed_predicate")
            )
        elif event_type == "workflow_completed":
            if (
                projection.status != "RUNNING"
                or projection.current_stage_index != len(contract.stages)
            ):
                raise WorkflowStoreError("workflow_completed_order_invalid")
            projection.status = "COMPLETED"
        else:
            raise WorkflowStoreError("workflow_event_type_invalid")
        projection.event_count = int(event["sequence"])
        projection.tail_hash = str(event["event_hash"])
    if projection.status not in WORKFLOW_STATUSES:
        raise WorkflowStoreError("workflow_projection_status_invalid")
    return projection


class WorkflowStore:
    """Immutable manifest + append-only events + verified projection cache."""

    def __init__(
        self,
        *,
        runtime_root: Path,
        repo_root: Path,
        workflow_id: str,
    ) -> None:
        self.runtime_root = Path(runtime_root).resolve()
        self.repo_root = Path(repo_root).resolve()
        if _is_relative_to(self.runtime_root, self.repo_root):
            raise WorkflowStoreError("runtime_root_inside_repository")
        if not WORKFLOW_ID_PATTERN.fullmatch(workflow_id):
            raise WorkflowStoreError("workflow_id_invalid")
        self.workflow_id = workflow_id
        self.root = self.runtime_root / "workflows" / workflow_id
        self.manifest_path = self.root / "contract-v1.json"
        self.ledger_path = self.root / "workflow-v1.jsonl"
        self.projection_path = self.root / "projection-v1.json"
        self._lock = threading.Lock()

    def _write_exclusive(self, path: Path, value: Mapping[str, object]) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        flags = os.O_CREAT | os.O_EXCL | os.O_WRONLY
        if hasattr(os, "O_BINARY"):
            flags |= os.O_BINARY
        descriptor = os.open(path, flags, 0o600)
        try:
            data = canonical_json_bytes(value) + b"\n"
            if os.write(descriptor, data) != len(data):
                raise WorkflowStoreError("workflow_manifest_short_write")
            os.fsync(descriptor)
        finally:
            os.close(descriptor)

    def ensure_contract(self, contract: WorkflowContract) -> None:
        if contract.workflow_id != self.workflow_id:
            raise WorkflowStoreError("workflow_contract_id_mismatch")
        if not self.manifest_path.exists():
            self._write_exclusive(self.manifest_path, contract.public_dict())
            return
        try:
            value = json.loads(self.manifest_path.read_text(encoding="utf-8"))
        except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise WorkflowStoreError("workflow_contract_unreadable") from exc
        existing = WorkflowContract.from_dict(value)
        if existing.public_dict() != contract.public_dict():
            raise WorkflowStoreError("workflow_contract_drift")

    def load_contract(self) -> WorkflowContract:
        try:
            value = json.loads(self.manifest_path.read_text(encoding="utf-8"))
        except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise WorkflowStoreError("workflow_contract_unreadable") from exc
        if not isinstance(value, dict):
            raise WorkflowStoreError("workflow_contract_not_object")
        return WorkflowContract.from_dict(value)

    def _read_events(self) -> tuple[Mapping[str, object], ...]:
        if not self.ledger_path.exists():
            return ()
        if not self.ledger_path.is_file():
            raise WorkflowStoreError("workflow_ledger_not_file")
        events: list[dict[str, object]] = []
        previous = GENESIS_HASH
        expected_fields = {
            "schema_version",
            "workflow_id",
            "sequence",
            "event_type",
            "previous_hash",
            "payload",
            "event_hash",
        }
        try:
            with self.ledger_path.open("r", encoding="utf-8", newline="") as stream:
                for sequence, line in enumerate(stream, start=1):
                    if not line.endswith("\n"):
                        raise WorkflowStoreError("workflow_ledger_final_newline_missing")
                    value = json.loads(line)
                    if not isinstance(value, dict) or set(value) != expected_fields:
                        raise WorkflowStoreError("workflow_event_fields_invalid")
                    if (
                        value["schema_version"] != 1
                        or value["workflow_id"] != self.workflow_id
                        or value["sequence"] != sequence
                        or value["event_type"] not in EVENT_TYPES
                        or value["previous_hash"] != previous
                        or not isinstance(value["payload"], dict)
                    ):
                        raise WorkflowStoreError("workflow_event_identity_invalid")
                    event_hash = value["event_hash"]
                    if not isinstance(event_hash, str) or not HASH_PATTERN.fullmatch(event_hash):
                        raise WorkflowStoreError("workflow_event_hash_invalid")
                    identity = {key: item for key, item in value.items() if key != "event_hash"}
                    if _hash_mapping(identity) != event_hash:
                        raise WorkflowStoreError("workflow_event_hash_mismatch")
                    previous = event_hash
                    events.append(value)
        except json.JSONDecodeError as exc:
            raise WorkflowStoreError("workflow_ledger_json_invalid") from exc
        except UnicodeDecodeError as exc:
            raise WorkflowStoreError("workflow_ledger_encoding_invalid") from exc
        return tuple(events)

    def _write_projection(
        self,
        projection: WorkflowProjection,
        contract: WorkflowContract,
    ) -> None:
        self.root.mkdir(parents=True, exist_ok=True)
        temporary: Path | None = None
        try:
            with tempfile.NamedTemporaryFile(
                mode="wb",
                prefix=".projection-",
                suffix=".tmp",
                dir=self.root,
                delete=False,
            ) as stream:
                temporary = Path(stream.name)
                stream.write(canonical_json_bytes(projection.public_dict(contract)) + b"\n")
                stream.flush()
                os.fsync(stream.fileno())
            os.replace(temporary, self.projection_path)
        finally:
            if temporary is not None and temporary.exists():
                temporary.unlink()

    def verify(
        self, *, allow_projection_recovery: bool = False
    ) -> WorkflowVerification:
        contract = self.load_contract()
        events = self._read_events()
        projection = project_workflow_events(contract, events)
        expected = projection.public_dict(contract)
        if self.projection_path.exists():
            try:
                cached = json.loads(self.projection_path.read_text(encoding="utf-8"))
            except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
                raise WorkflowStoreError("workflow_projection_unreadable") from exc
            if cached != expected:
                if not allow_projection_recovery:
                    raise WorkflowStoreError("workflow_projection_mismatch")
                self._write_projection(projection, contract)
        elif events:
            if not allow_projection_recovery:
                raise WorkflowStoreError("workflow_projection_missing")
            self._write_projection(projection, contract)
        return WorkflowVerification(True, contract, projection, events)

    def append(self, event_type: str, payload: Mapping[str, object]) -> Mapping[str, object]:
        if event_type not in EVENT_TYPES or not isinstance(payload, Mapping):
            raise WorkflowStoreError("workflow_append_invalid")
        with self._lock:
            verification = self.verify(allow_projection_recovery=True)
            identity: dict[str, object] = {
                "schema_version": 1,
                "workflow_id": self.workflow_id,
                "sequence": len(verification.events) + 1,
                "event_type": event_type,
                "previous_hash": verification.projection.tail_hash,
                "payload": json.loads(canonical_json_bytes(payload)),
            }
            event = {**identity, "event_hash": _hash_mapping(identity)}
            events = (*verification.events, event)
            projection = project_workflow_events(verification.contract, events)
            data = canonical_json_bytes(event) + b"\n"
            self.root.mkdir(parents=True, exist_ok=True)
            flags = os.O_APPEND | os.O_CREAT | os.O_WRONLY
            if hasattr(os, "O_BINARY"):
                flags |= os.O_BINARY
            descriptor = os.open(self.ledger_path, flags, 0o600)
            try:
                if os.write(descriptor, data) != len(data):
                    raise WorkflowStoreError("workflow_ledger_short_write")
                os.fsync(descriptor)
            finally:
                os.close(descriptor)
            self._write_projection(projection, verification.contract)
            self.verify()
            return event

    def start(self, contract: WorkflowContract) -> WorkflowProjection:
        self.ensure_contract(contract)
        verification = self.verify(allow_projection_recovery=True)
        if verification.events:
            return verification.projection
        self.append(
            "workflow_started",
            {
                "contract_fingerprint": contract.contract_fingerprint,
                "authorization_fingerprint": contract.authorization_fingerprint,
            },
        )
        return self.verify().projection


def find_workflow_ids(
    *,
    runtime_root: Path,
    repository: str,
    issue: int,
) -> tuple[str, ...]:
    root = Path(runtime_root).resolve() / "workflows"
    if not root.is_dir():
        return ()
    matches: list[str] = []
    for candidate in sorted(root.iterdir(), key=lambda item: item.name):
        if not candidate.is_dir() or not WORKFLOW_ID_PATTERN.fullmatch(candidate.name):
            continue
        manifest = candidate / "contract-v1.json"
        try:
            value = json.loads(manifest.read_text(encoding="utf-8"))
            contract = WorkflowContract.from_dict(value)
        except (OSError, UnicodeDecodeError, json.JSONDecodeError, WorkflowStoreError):
            continue
        if contract.repository == repository and contract.issue == issue:
            matches.append(contract.workflow_id)
    return tuple(matches)
