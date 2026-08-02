"""Repository-external append-only, tamper-evident runtime ledger for CSE O6."""

from __future__ import annotations

import hashlib
import json
import os
import re
import threading
from dataclasses import dataclass
from pathlib import Path
from types import MappingProxyType
from typing import Mapping

from .planner import ActionPlan


HASH_PATTERN = re.compile(r"^sha256:[0-9a-f]{64}$")
RUN_ID_PATTERN = re.compile(r"^[A-Za-z0-9_.-]{1,128}$")
GENESIS_HASH = "sha256:" + "0" * 64


class LedgerError(RuntimeError):
    """Ledger provenance, append-only ordering, or runtime location is unsafe."""


def _canonical_bytes(value: Mapping[str, object]) -> bytes:
    return json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")


def _hash(value: Mapping[str, object]) -> str:
    return "sha256:" + hashlib.sha256(_canonical_bytes(value)).hexdigest()


def _is_relative_to(path: Path, root: Path) -> bool:
    try:
        path.relative_to(root)
        return True
    except ValueError:
        return False


@dataclass(frozen=True)
class LedgerVerification:
    valid: bool
    event_count: int
    tail_hash: str
    events: tuple[Mapping[str, object], ...]


class RuntimeLedger:
    """Append only admission/result evidence outside the repository."""

    def __init__(self, *, runtime_root: Path, repo_root: Path, run_id: str) -> None:
        self.runtime_root = Path(runtime_root).resolve()
        self.repo_root = Path(repo_root).resolve()
        if _is_relative_to(self.runtime_root, self.repo_root):
            raise LedgerError("runtime_root_inside_repository")
        if not isinstance(run_id, str) or not RUN_ID_PATTERN.fullmatch(run_id):
            raise LedgerError("run_id_invalid")
        self.run_id = run_id
        self.path = self.runtime_root / "runs" / run_id / "ledger-v1.jsonl"
        self._lock = threading.Lock()

    def _read_events(self) -> list[dict[str, object]]:
        if not self.path.exists():
            return []
        if not self.path.is_file():
            raise LedgerError("ledger_not_regular_file")
        events: list[dict[str, object]] = []
        try:
            with self.path.open("r", encoding="utf-8", newline="") as stream:
                for sequence, line in enumerate(stream, start=1):
                    if not line.endswith("\n"):
                        raise LedgerError("ledger_final_newline_missing")
                    try:
                        value = json.loads(line)
                    except json.JSONDecodeError as exc:
                        raise LedgerError("ledger_json_invalid") from exc
                    if not isinstance(value, dict):
                        raise LedgerError("ledger_event_not_object")
                    if value.get("sequence") != sequence:
                        raise LedgerError("ledger_sequence_invalid")
                    events.append(value)
        except UnicodeDecodeError as exc:
            raise LedgerError("ledger_encoding_invalid") from exc
        return events

    def verify(self) -> LedgerVerification:
        events = self._read_events()
        previous = GENESIS_HASH
        seen_actions: set[str] = set()
        expected_fields = {
            "schema_version",
            "run_id",
            "sequence",
            "event_type",
            "previous_hash",
            "payload",
            "event_hash",
        }
        for event in events:
            if set(event) != expected_fields:
                raise LedgerError("ledger_event_fields_invalid")
            if event["schema_version"] != 1 or event["run_id"] != self.run_id:
                raise LedgerError("ledger_identity_mismatch")
            if event["event_type"] not in {"admission", "result"}:
                raise LedgerError("ledger_event_type_invalid")
            if event["previous_hash"] != previous:
                raise LedgerError("ledger_chain_mismatch")
            event_hash = event["event_hash"]
            if not isinstance(event_hash, str) or not HASH_PATTERN.fullmatch(event_hash):
                raise LedgerError("ledger_hash_invalid")
            identity = {key: value for key, value in event.items() if key != "event_hash"}
            if _hash(identity) != event_hash:
                raise LedgerError("ledger_hash_mismatch")
            payload = event["payload"]
            if not isinstance(payload, dict):
                raise LedgerError("ledger_payload_invalid")
            action = payload.get("action_fingerprint")
            if not isinstance(action, str) or not HASH_PATTERN.fullmatch(action):
                raise LedgerError("ledger_action_fingerprint_invalid")
            if event["event_type"] == "admission":
                if action in seen_actions:
                    raise LedgerError("duplicate_action")
                seen_actions.add(action)
            elif action not in seen_actions:
                raise LedgerError("result_without_admission")
            previous = event_hash
        frozen_events = tuple(
            MappingProxyType(json.loads(json.dumps(event))) for event in events
        )
        return LedgerVerification(
            valid=True,
            event_count=len(events),
            tail_hash=previous,
            events=frozen_events,
        )

    def _append(self, event_type: str, payload: Mapping[str, object]) -> Mapping[str, object]:
        with self._lock:
            verification = self.verify()
            if event_type == "admission":
                action = payload.get("action_fingerprint")
                for event in verification.events:
                    if (
                        event["event_type"] == "admission"
                        and event["payload"]["action_fingerprint"] == action  # type: ignore[index]
                    ):
                        raise LedgerError("duplicate_action")
            identity: dict[str, object] = {
                "schema_version": 1,
                "run_id": self.run_id,
                "sequence": verification.event_count + 1,
                "event_type": event_type,
                "previous_hash": verification.tail_hash,
                "payload": json.loads(
                    json.dumps(
                        dict(payload),
                        ensure_ascii=False,
                        sort_keys=True,
                        separators=(",", ":"),
                    )
                ),
            }
            event = {**identity, "event_hash": _hash(identity)}
            data = _canonical_bytes(event) + b"\n"
            self.path.parent.mkdir(parents=True, exist_ok=True)
            flags = os.O_APPEND | os.O_CREAT | os.O_WRONLY
            if hasattr(os, "O_BINARY"):
                flags |= os.O_BINARY
            descriptor = os.open(self.path, flags, 0o600)
            try:
                written = os.write(descriptor, data)
                if written != len(data):
                    raise LedgerError("ledger_short_write")
                os.fsync(descriptor)
            finally:
                os.close(descriptor)
            self.verify()
            return MappingProxyType(event)

    def append_admission(self, plan: ActionPlan, *, adapter_name: str) -> Mapping[str, object]:
        if not isinstance(plan, ActionPlan):
            raise LedgerError("action_plan_required")
        if not isinstance(adapter_name, str) or not adapter_name:
            raise LedgerError("adapter_name_required")
        return self._append(
            "admission",
            {
                "plan_sha256": plan.plan_sha256,
                "action_id": plan.action_id,
                "pending_action": plan.pending_action,
                "source_fingerprint": plan.source_fingerprint,
                "contract_fingerprint": plan.contract_fingerprint,
                "action_fingerprint": plan.action_fingerprint,
                "approval_comment_id": plan.approval_comment_id,
                "approval_consumed": True,
                "budget_delta": dict(plan.budget_delta),
                "invocation_start": {
                    "adapter": adapter_name,
                    "argv_fingerprint": _hash({"argv": list(plan.argv)}),
                    "cwd_fingerprint": _hash({"cwd": plan.cwd}),
                    "plan_mode": plan.mode,
                },
            },
        )

    def append_result(
        self,
        plan: ActionPlan,
        result: Mapping[str, object],
    ) -> Mapping[str, object]:
        if not isinstance(plan, ActionPlan):
            raise LedgerError("action_plan_required")
        if not isinstance(result, Mapping):
            raise LedgerError("result_mapping_required")
        return self._append(
            "result",
            {
                "plan_sha256": plan.plan_sha256,
                "action_fingerprint": plan.action_fingerprint,
                "result": dict(result),
            },
        )
