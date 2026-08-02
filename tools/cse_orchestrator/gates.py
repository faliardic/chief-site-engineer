"""Pure CHECKPOINT_COMMIT, BUILD, and DEVICE gate-plan contracts for CSE O7."""

from __future__ import annotations

import re
from pathlib import Path
from typing import Mapping

from .planner import ActionPlan, PlanError, build_action_plan
from .policy import PolicyDecision


SHA_PATTERN = re.compile(r"^[0-9a-f]{40}$")
FINGERPRINT_PATTERN = re.compile(r"^sha256:[0-9a-f]{64}$")
DEVICE_TARGET_PATTERN = re.compile(r"^[a-z][a-z0-9_]{2,63}$")


class GatePlanError(ValueError):
    """A mutable or costly gate is not bound to exact provenance."""


def _exact(value: Mapping[str, object], fields: set[str], label: str) -> dict[str, object]:
    if not isinstance(value, Mapping):
        raise GatePlanError(f"{label}_must_be_object")
    missing = sorted(fields - set(value))
    unknown = sorted(set(value) - fields)
    if missing:
        raise GatePlanError(f"missing_{label}_fields:{','.join(missing)}")
    if unknown:
        raise GatePlanError(f"unknown_{label}_fields:{','.join(unknown)}")
    return dict(value)


def _string(value: object, field: str) -> str:
    if not isinstance(value, str) or not value or "\x00" in value:
        raise GatePlanError(f"invalid_string:{field}")
    return value


def _sha(value: object, field: str) -> str:
    result = _string(value, field)
    if not SHA_PATTERN.fullmatch(result):
        raise GatePlanError(f"invalid_sha:{field}")
    return result


def _fingerprint(value: object, field: str) -> str:
    result = _string(value, field)
    if not FINGERPRINT_PATTERN.fullmatch(result):
        raise GatePlanError(f"invalid_fingerprint:{field}")
    return result


def _positive(value: object, field: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value < 1:
        raise GatePlanError(f"invalid_positive_integer:{field}")
    return value


def _path(value: object, field: str) -> str:
    result = _string(value, field).replace("\\", "/")
    if Path(result).is_absolute() or any(
        part in {"", ".", ".."} for part in result.split("/")
    ) or any(char in result for char in "*?[]{}"):
        raise GatePlanError(f"invalid_path:{field}")
    return result


def _strings(value: object, field: str, *, allow_empty: bool = False) -> list[str]:
    if not isinstance(value, list) or not all(
        isinstance(item, str) and item and "\x00" not in item for item in value
    ):
        raise GatePlanError(f"invalid_string_list:{field}")
    if not allow_empty and not value:
        raise GatePlanError(f"empty_string_list:{field}")
    if len(value) != len(set(value)):
        raise GatePlanError(f"duplicate_string_list:{field}")
    return list(value)


def _with_gate(
    request: Mapping[str, object],
    *,
    action: str,
    contract: Mapping[str, object],
    validation: str | None = None,
) -> dict[str, object]:
    result = dict(request)
    if result.get("pending_action") != action:
        raise GatePlanError("gate_action_mismatch")
    if result.get("required_approval_level") != action:
        raise GatePlanError("gate_approval_mismatch")
    if result.get("action_allowlist") != [action]:
        raise GatePlanError("gate_action_allowlist_mismatch")
    result["provenance"] = {"gate": action, **dict(contract)}
    if validation is not None:
        current = _strings(result.get("validation_plan"), "validation_plan", allow_empty=True)
        if validation not in current:
            current.append(validation)
        result["validation_plan"] = current
    return result


def build_checkpoint_plan(
    observation: Mapping[str, object],
    decision: PolicyDecision,
    action_request: Mapping[str, object],
    checkpoint_contract: Mapping[str, object],
) -> ActionPlan:
    fields = {
        "branch",
        "head_sha",
        "tree_sha",
        "source_manifest_fingerprint",
        "staged_allowlist",
        "parent_sha",
        "base_sha",
        "expected_head_sha",
        "expected_tree_sha",
        "commit_budget",
    }
    contract = _exact(checkpoint_contract, fields, "checkpoint")
    contract["branch"] = _string(contract["branch"], "branch")
    for field in (
        "head_sha",
        "tree_sha",
        "parent_sha",
        "base_sha",
        "expected_head_sha",
        "expected_tree_sha",
    ):
        contract[field] = _sha(contract[field], field)
    contract["source_manifest_fingerprint"] = _fingerprint(
        contract["source_manifest_fingerprint"], "source_manifest_fingerprint"
    )
    staged = _strings(contract["staged_allowlist"], "staged_allowlist")
    contract["staged_allowlist"] = [_path(item, "staged_allowlist") for item in staged]
    contract["commit_budget"] = _positive(contract["commit_budget"], "commit_budget")
    if contract["commit_budget"] != 1:
        raise GatePlanError("checkpoint_commit_budget_must_equal_one")
    if action_request.get("branch") != contract["branch"]:
        raise GatePlanError("checkpoint_branch_mismatch")
    if action_request.get("head_sha") != contract["head_sha"]:
        raise GatePlanError("checkpoint_head_mismatch")
    if action_request.get("tree_sha") != contract["tree_sha"]:
        raise GatePlanError("checkpoint_tree_mismatch")
    try:
        return build_action_plan(
            observation,
            decision,
            _with_gate(
                action_request,
                action="CHECKPOINT_COMMIT",
                contract=contract,
                validation="git diff --cached --check",
            ),
        )
    except PlanError as exc:
        raise GatePlanError(str(exc)) from exc


def build_build_plan(
    observation: Mapping[str, object],
    decision: PolicyDecision,
    action_request: Mapping[str, object],
    build_contract: Mapping[str, object],
) -> ActionPlan:
    fields = {
        "checkpoint_sha",
        "checkpoint_tree_sha",
        "output_path",
        "artifact_contract",
        "build_budget",
    }
    contract = _exact(build_contract, fields, "build")
    contract["checkpoint_sha"] = _sha(contract["checkpoint_sha"], "checkpoint_sha")
    contract["checkpoint_tree_sha"] = _sha(
        contract["checkpoint_tree_sha"], "checkpoint_tree_sha"
    )
    contract["output_path"] = _path(contract["output_path"], "output_path")
    artifact = _exact(
        contract["artifact_contract"],
        {"sha256", "package", "version", "signer"},
        "artifact_contract",
    )
    artifact["sha256"] = _fingerprint(artifact["sha256"], "artifact_sha256")
    for field in ("package", "version", "signer"):
        artifact[field] = _string(artifact[field], f"artifact_{field}")
    contract["artifact_contract"] = artifact
    contract["build_budget"] = _positive(contract["build_budget"], "build_budget")
    if contract["build_budget"] != 1:
        raise GatePlanError("build_budget_must_equal_one")
    try:
        return build_action_plan(
            observation,
            decision,
            _with_gate(action_request, action="BUILD", contract=contract),
        )
    except PlanError as exc:
        raise GatePlanError(str(exc)) from exc


def build_device_plan(
    observation: Mapping[str, object],
    decision: PolicyDecision,
    action_request: Mapping[str, object],
    device_contract: Mapping[str, object],
) -> ActionPlan:
    fields = {"artifact_sha256", "device_target", "adb_argv", "retry_budget"}
    contract = _exact(device_contract, fields, "device")
    contract["artifact_sha256"] = _fingerprint(
        contract["artifact_sha256"], "artifact_sha256"
    )
    target = _string(contract["device_target"], "device_target")
    if not DEVICE_TARGET_PATTERN.fullmatch(target):
        raise GatePlanError("symbolic_device_target_required")
    contract["device_target"] = target
    argv = _strings(contract["adb_argv"], "adb_argv")
    if argv != action_request.get("argv") or Path(argv[0]).name.lower() not in {
        "adb",
        "adb.exe",
    }:
        raise GatePlanError("adb_argv_mismatch")
    lowered = [item.lower() for item in argv]
    if "-s" in lowered or "--serial" in lowered:
        raise GatePlanError("device_serial_forbidden")
    destructive_sequences = (
        ("uninstall",),
        ("pm", "clear"),
        ("clear-data",),
        ("hard-delete",),
    )
    flattened = " ".join(lowered)
    if any(" ".join(sequence) in flattened for sequence in destructive_sequences):
        raise GatePlanError("destructive_device_action_forbidden")
    contract["adb_argv"] = argv
    contract["retry_budget"] = _positive(contract["retry_budget"], "retry_budget")
    try:
        return build_action_plan(
            observation,
            decision,
            _with_gate(action_request, action="DEVICE", contract=contract),
        )
    except PlanError as exc:
        raise GatePlanError(str(exc)) from exc
