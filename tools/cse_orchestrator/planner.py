"""Deterministic, fail-closed ActionPlan v1 builder for CSE O5."""

from __future__ import annotations

import hashlib
import json
import os
import re
from dataclasses import dataclass
from pathlib import Path
from types import MappingProxyType
from typing import Any, Mapping, Sequence

from .policy import ACTION_TYPES, CAPABILITY_FOR_ACTION, PolicyDecision


SHA_PATTERN = re.compile(r"^[0-9a-f]{40}$")
FINGERPRINT_PATTERN = re.compile(r"^sha256:[0-9a-f]{64}$")
REPOSITORY_PATTERN = re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")
ACTION_REQUEST_FIELDS = frozenset(
    {
        "schema_version",
        "action_id",
        "pending_action",
        "mode",
        "cwd",
        "repository",
        "branch",
        "base_sha",
        "head_sha",
        "tree_sha",
        "argv",
        "command_family",
        "capability",
        "read_allowlist",
        "write_allowlist",
        "action_allowlist",
        "environment_allowlist",
        "timeout_seconds",
        "output_limit_bytes",
        "validation_plan",
        "source_fingerprint",
        "contract_fingerprint",
        "required_approval_level",
        "expected_success_state",
        "expected_failure_state",
        "provenance",
    }
)
COMMAND_FAMILIES = frozenset(
    {
        "pytest",
        "compileall",
        "git_diff_check",
        "flutter_test",
        "flutter_analyze",
        "build",
        "generic_command",
    }
)
EXECUTABLES = frozenset(
    {"python", "python.exe", "git", "git.exe", "flutter", "flutter.bat", "adb", "adb.exe", "codex", "codex.exe", "gradlew", "gradlew.bat"}
)
SHELL_EXECUTABLES = frozenset(
    {"cmd", "cmd.exe", "powershell", "powershell.exe", "pwsh", "pwsh.exe", "bash", "sh"}
)
SHELL_OPERATORS = frozenset({"|", "||", "&", "&&", ";", ">", ">>", "<"})
_WILDCARD_CHARS = frozenset("*?[]{}")
_SECRET_KEYS = re.compile(r"(?i)(token|password|passwd|secret|api[_-]?key|credential|authorization)")


class PlanError(ValueError):
    """An ActionPlan cannot be produced without weakening its provenance."""


def _canonical_bytes(value: Mapping[str, object]) -> bytes:
    return json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")


def _fingerprint(value: Mapping[str, object]) -> str:
    return "sha256:" + hashlib.sha256(_canonical_bytes(value)).hexdigest()


def _is_relative_to(path: Path, root: Path) -> bool:
    try:
        path.relative_to(root)
        return True
    except ValueError:
        return False


def _required_string(value: object, field: str) -> str:
    if not isinstance(value, str) or not value or "\x00" in value:
        raise PlanError(f"invalid_string:{field}")
    return value


def _positive_int(value: object, field: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value < 1:
        raise PlanError(f"invalid_positive_integer:{field}")
    return value


def _string_list(value: object, field: str, *, allow_empty: bool = True) -> tuple[str, ...]:
    if not isinstance(value, list) or not all(
        isinstance(item, str) and item and "\x00" not in item for item in value
    ):
        raise PlanError(f"{field}_must_be_string_list")
    if not allow_empty and not value:
        raise PlanError(f"{field}_must_not_be_empty")
    if len(value) != len(set(value)):
        raise PlanError(f"duplicate_{field}")
    return tuple(value)


def _safe_repo_paths(value: object, field: str) -> tuple[str, ...]:
    paths = _string_list(value, field)
    for item in paths:
        normalized = item.replace("\\", "/")
        parts = normalized.split("/")
        if (
            Path(item).is_absolute()
            or any(char in item for char in _WILDCARD_CHARS)
            or any(part in {"", ".", ".."} for part in parts)
        ):
            raise PlanError(f"invalid_allowlist_path:{field}:{item}")
    return paths


def _json_safe(value: object, path: str = "provenance") -> object:
    if value is None or isinstance(value, (str, int, bool)):
        if isinstance(value, str) and "\x00" in value:
            raise PlanError(f"invalid_provenance:{path}")
        return value
    if isinstance(value, list):
        return [_json_safe(item, f"{path}[]") for item in value]
    if isinstance(value, Mapping):
        result: dict[str, object] = {}
        for key, item in value.items():
            if not isinstance(key, str) or not key or _SECRET_KEYS.search(key):
                raise PlanError(f"forbidden_provenance_key:{path}")
            result[key] = _json_safe(item, f"{path}.{key}")
        return result
    raise PlanError(f"invalid_provenance:{path}")


def _deep_freeze(value: object) -> object:
    if isinstance(value, Mapping):
        return MappingProxyType({key: _deep_freeze(item) for key, item in value.items()})
    if isinstance(value, list | tuple):
        return tuple(_deep_freeze(item) for item in value)
    return value


def _thaw(value: object) -> object:
    if isinstance(value, Mapping):
        return {str(key): _thaw(item) for key, item in value.items()}
    if isinstance(value, tuple):
        return [_thaw(item) for item in value]
    return value


@dataclass(frozen=True)
class ActionPlan:
    schema_version: int
    run_id: str
    action_id: str
    issue: int
    pending_action: str
    mode: str
    cwd: str
    repository: str
    branch: str
    base_sha: str
    head_sha: str
    tree_sha: str
    argv: tuple[str, ...]
    command_family: str
    capability: str
    read_allowlist: tuple[str, ...]
    write_allowlist: tuple[str, ...]
    action_allowlist: tuple[str, ...]
    environment_allowlist: tuple[str, ...]
    timeout_seconds: int
    output_limit_bytes: int
    validation_plan: tuple[str, ...]
    source_fingerprint: str
    contract_fingerprint: str
    action_fingerprint: str
    approval_comment_id: int
    required_approval_level: str
    budget_delta: Mapping[str, int]
    expected_success_state: str
    expected_failure_state: str
    provenance: Mapping[str, object]
    plan_sha256: str

    def identity_payload(self) -> dict[str, object]:
        return {
            "schema_version": self.schema_version,
            "run_id": self.run_id,
            "action_id": self.action_id,
            "issue": self.issue,
            "pending_action": self.pending_action,
            "mode": self.mode,
            "cwd": self.cwd,
            "repository": self.repository,
            "branch": self.branch,
            "base_sha": self.base_sha,
            "head_sha": self.head_sha,
            "tree_sha": self.tree_sha,
            "argv": list(self.argv),
            "command_family": self.command_family,
            "capability": self.capability,
            "read_allowlist": list(self.read_allowlist),
            "write_allowlist": list(self.write_allowlist),
            "action_allowlist": list(self.action_allowlist),
            "environment_allowlist": list(self.environment_allowlist),
            "timeout_seconds": self.timeout_seconds,
            "output_limit_bytes": self.output_limit_bytes,
            "validation_plan": list(self.validation_plan),
            "source_fingerprint": self.source_fingerprint,
            "contract_fingerprint": self.contract_fingerprint,
            "action_fingerprint": self.action_fingerprint,
            "approval_comment_id": self.approval_comment_id,
            "required_approval_level": self.required_approval_level,
            "budget_delta": dict(self.budget_delta),
            "expected_success_state": self.expected_success_state,
            "expected_failure_state": self.expected_failure_state,
            "provenance": _thaw(self.provenance),
        }

    def public_dict(self) -> dict[str, object]:
        return {**self.identity_payload(), "plan_sha256": self.plan_sha256}

    @classmethod
    def from_dict(cls, value: Mapping[str, object]) -> "ActionPlan":
        if not isinstance(value, Mapping):
            raise PlanError("plan_must_be_object")
        expected = set(cls.__dataclass_fields__)
        if set(value) != expected:
            raise PlanError("plan_fields_invalid")
        mutable = dict(value)
        plan = cls(
            schema_version=int(mutable["schema_version"]),
            run_id=_required_string(mutable["run_id"], "run_id"),
            action_id=_required_string(mutable["action_id"], "action_id"),
            issue=_positive_int(mutable["issue"], "issue"),
            pending_action=_required_string(mutable["pending_action"], "pending_action"),
            mode=_required_string(mutable["mode"], "mode"),
            cwd=_required_string(mutable["cwd"], "cwd"),
            repository=_required_string(mutable["repository"], "repository"),
            branch=_required_string(mutable["branch"], "branch"),
            base_sha=_required_string(mutable["base_sha"], "base_sha"),
            head_sha=_required_string(mutable["head_sha"], "head_sha"),
            tree_sha=_required_string(mutable["tree_sha"], "tree_sha"),
            argv=_string_list(mutable["argv"], "argv", allow_empty=False),
            command_family=_required_string(mutable["command_family"], "command_family"),
            capability=_required_string(mutable["capability"], "capability"),
            read_allowlist=_string_list(mutable["read_allowlist"], "read_allowlist"),
            write_allowlist=_string_list(mutable["write_allowlist"], "write_allowlist"),
            action_allowlist=_string_list(mutable["action_allowlist"], "action_allowlist", allow_empty=False),
            environment_allowlist=_string_list(mutable["environment_allowlist"], "environment_allowlist"),
            timeout_seconds=_positive_int(mutable["timeout_seconds"], "timeout_seconds"),
            output_limit_bytes=_positive_int(mutable["output_limit_bytes"], "output_limit_bytes"),
            validation_plan=_string_list(mutable["validation_plan"], "validation_plan"),
            source_fingerprint=_required_string(mutable["source_fingerprint"], "source_fingerprint"),
            contract_fingerprint=_required_string(mutable["contract_fingerprint"], "contract_fingerprint"),
            action_fingerprint=_required_string(mutable["action_fingerprint"], "action_fingerprint"),
            approval_comment_id=_positive_int(mutable["approval_comment_id"], "approval_comment_id"),
            required_approval_level=_required_string(mutable["required_approval_level"], "required_approval_level"),
            budget_delta=MappingProxyType(dict(mutable["budget_delta"])),  # type: ignore[arg-type]
            expected_success_state=_required_string(mutable["expected_success_state"], "expected_success_state"),
            expected_failure_state=_required_string(mutable["expected_failure_state"], "expected_failure_state"),
            provenance=_deep_freeze(_json_safe(mutable["provenance"])),  # type: ignore[arg-type]
            plan_sha256=_required_string(mutable["plan_sha256"], "plan_sha256"),
        )
        _validate_built_plan(plan)
        return plan


def canonical_plan_json(plan: ActionPlan) -> str:
    if not isinstance(plan, ActionPlan):
        raise TypeError("action_plan_required")
    return _canonical_bytes(plan.public_dict()).decode("utf-8")


def _validate_command(argv: tuple[str, ...]) -> None:
    if not argv:
        raise PlanError("argv_must_not_be_empty")
    executable = Path(argv[0]).name.lower()
    if executable in SHELL_EXECUTABLES:
        raise PlanError("shell_executable_forbidden")
    if executable not in EXECUTABLES:
        raise PlanError(f"executable_not_allowed:{executable}")
    for item in argv:
        if any(char in item for char in _WILDCARD_CHARS):
            raise PlanError("wildcard_argv_forbidden")
        if item in SHELL_OPERATORS or "\r" in item or "\n" in item:
            raise PlanError("shell_operator_forbidden")


def _validate_built_plan(plan: ActionPlan) -> None:
    if plan.schema_version != 1:
        raise PlanError("unsupported_plan_schema")
    if plan.pending_action not in ACTION_TYPES:
        raise PlanError("unknown_action")
    if plan.mode not in {"dry_run", "execute"}:
        raise PlanError("invalid_mode")
    if plan.command_family not in COMMAND_FAMILIES:
        raise PlanError("unknown_command_family")
    if plan.capability != CAPABILITY_FOR_ACTION[plan.pending_action]:
        raise PlanError("capability_mismatch")
    if plan.required_approval_level != plan.pending_action:
        raise PlanError("approval_level_mismatch")
    if plan.action_allowlist != (plan.pending_action,):
        raise PlanError("action_allowlist_mismatch")
    for value, field in (
        (plan.base_sha, "base_sha"),
        (plan.head_sha, "head_sha"),
        (plan.tree_sha, "tree_sha"),
    ):
        if not SHA_PATTERN.fullmatch(value):
            raise PlanError(f"invalid_sha:{field}")
    for value, field in (
        (plan.source_fingerprint, "source_fingerprint"),
        (plan.contract_fingerprint, "contract_fingerprint"),
        (plan.action_fingerprint, "action_fingerprint"),
        (plan.plan_sha256, "plan_sha256"),
    ):
        if not FINGERPRINT_PATTERN.fullmatch(value):
            raise PlanError(f"invalid_fingerprint:{field}")
    _validate_command(plan.argv)
    expected_plan_hash = _fingerprint(plan.identity_payload())
    if plan.plan_sha256 != expected_plan_hash:
        raise PlanError("plan_hash_mismatch")


def build_action_plan(
    observation: Mapping[str, object],
    decision: PolicyDecision,
    action_request: Mapping[str, object],
) -> ActionPlan:
    """Build one immutable plan without subprocess, filesystem, or network I/O."""

    if not isinstance(observation, Mapping):
        raise PlanError("observation_must_be_object")
    if observation.get("schema_version") != 1:
        raise PlanError("observation_schema_invalid")
    if observation.get("state") != "SCOPE_VALIDATED":
        raise PlanError("observation_not_scope_validated")
    if observation.get("blockers") != [] or observation.get("exit_code") != 0:
        raise PlanError("observation_blocked")
    if not isinstance(decision, PolicyDecision) or not decision.allowed:
        raise PlanError("policy_denied")
    if decision.state_to not in {"CODEX_RUNNING", "ACTION_RUNNING"}:
        raise PlanError("policy_not_invocation_admission")
    if not isinstance(action_request, Mapping):
        raise PlanError("action_request_must_be_object")
    missing = sorted(ACTION_REQUEST_FIELDS - set(action_request))
    unknown = sorted(set(action_request) - ACTION_REQUEST_FIELDS)
    if missing:
        raise PlanError(f"missing_action_request_fields:{','.join(missing)}")
    if unknown:
        raise PlanError(f"unknown_action_request_fields:{','.join(unknown)}")
    request = dict(action_request)
    if request["schema_version"] != 1:
        raise PlanError("action_request_schema_invalid")

    action = _required_string(request["pending_action"], "pending_action")
    if action not in ACTION_TYPES:
        raise PlanError("unknown_action")
    if decision.required_approval_level != action:
        raise PlanError("policy_approval_mismatch")
    capability = _required_string(request["capability"], "capability")
    if capability != CAPABILITY_FOR_ACTION[action]:
        raise PlanError("capability_mismatch")
    expected_success = _required_string(
        request["expected_success_state"], "expected_success_state"
    )
    if decision.state_from == "UNKNOWN" or not expected_success:
        raise PlanError("policy_state_invalid")

    git = observation.get("git")
    authorization = observation.get("authorization")
    if not isinstance(git, Mapping) or not isinstance(authorization, Mapping):
        raise PlanError("observation_provenance_missing")
    if authorization.get("status") != "valid":
        raise PlanError("authorization_invalid")
    approval_comment_id = _positive_int(
        authorization.get("comment_id"), "approval_comment_id"
    )

    repo_root = Path(_required_string(observation.get("repo_root"), "repo_root")).resolve()
    cwd_raw = _required_string(request["cwd"], "cwd")
    if any(char in cwd_raw for char in _WILDCARD_CHARS):
        raise PlanError("wildcard_cwd_forbidden")
    cwd = Path(cwd_raw)
    if not cwd.is_absolute():
        raise PlanError("cwd_outside_repository")
    cwd = cwd.resolve()
    if not _is_relative_to(cwd, repo_root):
        raise PlanError("cwd_outside_repository")

    identity_matches = {
        "repository": (request["repository"], observation.get("repository")),
        "branch": (request["branch"], git.get("branch")),
        "base_sha": (request["base_sha"], git.get("origin_master_sha")),
        "head_sha": (request["head_sha"], git.get("head_sha")),
        "tree_sha": (request["tree_sha"], git.get("tree_sha")),
    }
    mismatches = [field for field, values in identity_matches.items() if values[0] != values[1]]
    if mismatches:
        raise PlanError(f"provenance_mismatch:{','.join(mismatches)}")
    repository = _required_string(request["repository"], "repository")
    if not REPOSITORY_PATTERN.fullmatch(repository):
        raise PlanError("repository_invalid")

    source_fingerprint = _required_string(
        request["source_fingerprint"], "source_fingerprint"
    )
    if not FINGERPRINT_PATTERN.fullmatch(source_fingerprint):
        raise PlanError("source_fingerprint_invalid")
    if source_fingerprint != git.get("tracked_fingerprint"):
        raise PlanError("source_fingerprint_mismatch")
    contract_fingerprint = _required_string(
        request["contract_fingerprint"], "contract_fingerprint"
    )
    if not FINGERPRINT_PATTERN.fullmatch(contract_fingerprint):
        raise PlanError("contract_fingerprint_invalid")

    argv_value = request["argv"]
    if not isinstance(argv_value, list):
        raise PlanError("argv_must_be_list")
    argv = _string_list(argv_value, "argv", allow_empty=False)
    _validate_command(argv)
    read_allowlist = _safe_repo_paths(request["read_allowlist"], "read_allowlist")
    write_allowlist = _safe_repo_paths(request["write_allowlist"], "write_allowlist")
    action_allowlist = _string_list(
        request["action_allowlist"], "action_allowlist", allow_empty=False
    )
    environment_allowlist = _string_list(
        request["environment_allowlist"], "environment_allowlist"
    )
    for name in environment_allowlist:
        if not re.fullmatch(r"[A-Z][A-Z0-9_]*", name) or _SECRET_KEYS.search(name):
            raise PlanError(f"environment_name_forbidden:{name}")
    provenance_value = _json_safe(request["provenance"])
    if not isinstance(provenance_value, dict):
        raise PlanError("provenance_must_be_object")

    action_identity = {
        "action_id": request["action_id"],
        "pending_action": action,
        "cwd": str(cwd),
        "repository": repository,
        "branch": request["branch"],
        "base_sha": request["base_sha"],
        "head_sha": request["head_sha"],
        "tree_sha": request["tree_sha"],
        "argv": list(argv),
        "command_family": request["command_family"],
        "capability": capability,
        "read_allowlist": list(read_allowlist),
        "write_allowlist": list(write_allowlist),
        "action_allowlist": list(action_allowlist),
        "environment_allowlist": list(environment_allowlist),
        "timeout_seconds": request["timeout_seconds"],
        "output_limit_bytes": request["output_limit_bytes"],
        "validation_plan": request["validation_plan"],
        "source_fingerprint": source_fingerprint,
        "contract_fingerprint": contract_fingerprint,
        "provenance": provenance_value,
    }
    action_fingerprint = _fingerprint(action_identity)
    budget_delta = dict(decision.budget_delta or {})
    if any(
        not isinstance(key, str)
        or isinstance(value, bool)
        or not isinstance(value, int)
        or value < 0
        for key, value in budget_delta.items()
    ):
        raise PlanError("budget_delta_invalid")

    fields: dict[str, Any] = {
        "schema_version": 1,
        "run_id": _required_string(observation.get("run_id"), "run_id"),
        "action_id": _required_string(request["action_id"], "action_id"),
        "issue": _positive_int(observation.get("issue"), "issue"),
        "pending_action": action,
        "mode": _required_string(request["mode"], "mode"),
        "cwd": str(cwd),
        "repository": repository,
        "branch": _required_string(request["branch"], "branch"),
        "base_sha": _required_string(request["base_sha"], "base_sha"),
        "head_sha": _required_string(request["head_sha"], "head_sha"),
        "tree_sha": _required_string(request["tree_sha"], "tree_sha"),
        "argv": argv,
        "command_family": _required_string(request["command_family"], "command_family"),
        "capability": capability,
        "read_allowlist": read_allowlist,
        "write_allowlist": write_allowlist,
        "action_allowlist": action_allowlist,
        "environment_allowlist": environment_allowlist,
        "timeout_seconds": _positive_int(request["timeout_seconds"], "timeout_seconds"),
        "output_limit_bytes": _positive_int(request["output_limit_bytes"], "output_limit_bytes"),
        "validation_plan": _string_list(request["validation_plan"], "validation_plan"),
        "source_fingerprint": source_fingerprint,
        "contract_fingerprint": contract_fingerprint,
        "action_fingerprint": action_fingerprint,
        "approval_comment_id": approval_comment_id,
        "required_approval_level": _required_string(request["required_approval_level"], "required_approval_level"),
        "budget_delta": MappingProxyType(dict(sorted(budget_delta.items()))),
        "expected_success_state": expected_success,
        "expected_failure_state": _required_string(request["expected_failure_state"], "expected_failure_state"),
        "provenance": _deep_freeze(provenance_value),
    }
    provisional = ActionPlan(**fields, plan_sha256="sha256:" + "0" * 64)
    plan = ActionPlan(**fields, plan_sha256=_fingerprint(provisional.identity_payload()))
    _validate_built_plan(plan)
    return plan


def current_environment(plan: ActionPlan, source: Mapping[str, str] | None = None) -> dict[str, str]:
    """Return only explicitly admitted non-secret environment names."""

    values = source if source is not None else os.environ
    return {name: values[name] for name in plan.environment_allowlist if name in values}
