"""Strict workflow-level authorization for the resumable O10 coordinator."""

from __future__ import annotations

import hashlib
import json
import re
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Mapping


WORKFLOW_AUTHORIZATION_MARKER = (
    "<!-- cse-orchestrator-workflow-authorization:v1 -->"
)
FENCED_JSON_PATTERN = re.compile(r"```json\s*(\{.*?\})\s*```", re.DOTALL)
REPOSITORY_PATTERN = re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")
SHA_PATTERN = re.compile(r"^[0-9a-f]{40}$")
HASH_PATTERN = re.compile(r"^(?:sha256:)?[0-9a-f]{64}$")
UTC_PATTERN = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$")
NAME_PATTERN = re.compile(r"^[a-z][a-z0-9_-]{1,63}$")
SECRET_PATTERN = re.compile(
    r"(?i)(authorization\s*:\s*bearer|(?:api[_-]?key|token|secret|password)"
    r"\s*[:=]|sk-[A-Za-z0-9_-]{12,}|gh[pousr]_[A-Za-z0-9_]{12,})"
)

TOP_LEVEL_FIELDS = frozenset(
    {
        "schema_version",
        "repository",
        "issue",
        "comment_id",
        "scope_version",
        "controller_revision",
        "target",
        "read_allowlist",
        "write_allowlist",
        "capability_sequence",
        "stages",
        "reused_evidence",
        "budgets",
        "artifact",
        "device",
        "publish",
        "execution",
        "expires_at",
        "nonce",
        "supersedes_comment_id",
    }
)
REUSED_EVIDENCE_FIELDS = frozenset(
    {
        "stage",
        "source_fingerprint",
        "tool_fingerprint",
        "command_fingerprint",
        "artifact_fingerprint",
        "evidence_fingerprint",
    }
)
TARGET_FIELDS = frozenset({"branch", "base_sha", "head_sha", "tree_sha"})
STAGE_FIELDS = frozenset(
    {
        "name",
        "kind",
        "capability",
        "command_family",
        "argv",
        "cwd",
        "timeout_seconds",
        "output_limit_bytes",
        "retry_max",
        "reusable",
        "failure_class",
        "environment_allowlist",
    }
)
BUDGET_FIELDS = frozenset(
    {
        "primary_max",
        "correction_max",
        "command_max",
        "commit_max",
        "push_max",
        "draft_pr_max",
        "github_comment_max",
        "hard_stop_seconds",
    }
)
ARTIFACT_FIELDS = frozenset(
    {"path", "sha256", "package", "version", "signer", "checkpoint_sha"}
)
DEVICE_FIELDS = frozenset({"serial", "model", "package"})
PUBLISH_FIELDS = frozenset(
    {"base_branch", "title", "body_first_line", "commit_message"}
)

CAPABILITIES = frozenset({"Code", "Device", "Publish"})
STAGE_KINDS = frozenset(
    {"command", "artifact_verify", "commit", "push", "draft_pr", "issue_comment"}
)
FAILURE_CLASSES = frozenset({"unsafe", "resumable", "external", "decision"})


class WorkflowAuthorizationError(ValueError):
    """The workflow authorization is not exact or cannot be trusted."""

    def __init__(self, reason: str):
        super().__init__(reason)
        self.reason = reason


@dataclass(frozen=True)
class WorkflowStageAuthorization:
    name: str
    kind: str
    capability: str
    command_family: str
    argv: tuple[str, ...]
    cwd: str
    timeout_seconds: int
    output_limit_bytes: int
    retry_max: int
    reusable: bool
    failure_class: str
    environment_allowlist: tuple[str, ...]

    def public_dict(self) -> dict[str, object]:
        return {
            "name": self.name,
            "kind": self.kind,
            "capability": self.capability,
            "command_family": self.command_family,
            "argv": list(self.argv),
            "cwd": self.cwd,
            "timeout_seconds": self.timeout_seconds,
            "output_limit_bytes": self.output_limit_bytes,
            "retry_max": self.retry_max,
            "reusable": self.reusable,
            "failure_class": self.failure_class,
            "environment_allowlist": list(self.environment_allowlist),
        }


@dataclass(frozen=True)
class WorkflowAuthorization:
    payload: Mapping[str, object]
    fingerprint: str
    expires_at: datetime
    stages: tuple[WorkflowStageAuthorization, ...]

    @property
    def repository(self) -> str:
        return str(self.payload["repository"])

    @property
    def issue(self) -> int:
        return int(self.payload["issue"])

    @property
    def comment_id(self) -> int:
        return int(self.payload["comment_id"])

    @property
    def target(self) -> Mapping[str, object]:
        return self.payload["target"]  # type: ignore[return-value]

    @property
    def budgets(self) -> Mapping[str, int]:
        return self.payload["budgets"]  # type: ignore[return-value]

    @property
    def write_allowlist(self) -> tuple[str, ...]:
        return tuple(self.payload["write_allowlist"])  # type: ignore[arg-type]

    @property
    def execution_authorized(self) -> bool:
        return self.payload["execution"] is True

    @property
    def reused_evidence(self) -> tuple[Mapping[str, object], ...]:
        return tuple(self.payload["reused_evidence"])  # type: ignore[arg-type]

    def public_dict(self) -> dict[str, object]:
        return json.loads(canonical_json_bytes(self.payload))


@dataclass(frozen=True)
class WorkflowAuthorizationSelection:
    status: str
    authorization: WorkflowAuthorization | None = None
    comment_id: int | None = None
    reason: str | None = None

    def public_dict(self) -> dict[str, object]:
        return {
            "status": self.status,
            "comment_id": self.comment_id,
            "fingerprint": (
                self.authorization.fingerprint if self.authorization else None
            ),
            "reason": self.reason,
        }


def _duplicate_rejector(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise WorkflowAuthorizationError(f"duplicate_field:{key}")
        result[key] = value
    return result


def canonical_json_bytes(value: Mapping[str, object]) -> bytes:
    return json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")


def _fingerprint(value: Mapping[str, object]) -> str:
    return "sha256:" + hashlib.sha256(canonical_json_bytes(value)).hexdigest()


def _exact(value: object, fields: frozenset[str], label: str) -> dict[str, Any]:
    if not isinstance(value, Mapping):
        raise WorkflowAuthorizationError(f"{label}_must_be_object")
    missing = sorted(fields - set(value))
    unknown = sorted(set(value) - fields)
    if missing:
        raise WorkflowAuthorizationError(f"missing_{label}_fields:{','.join(missing)}")
    if unknown:
        raise WorkflowAuthorizationError(f"unknown_{label}_fields:{','.join(unknown)}")
    return dict(value)


def _string(value: object, field: str, *, limit: int = 4096) -> str:
    if (
        not isinstance(value, str)
        or not value
        or "\x00" in value
        or len(value) > limit
        or SECRET_PATTERN.search(value)
    ):
        raise WorkflowAuthorizationError(f"invalid_string:{field}")
    return value


def _integer(value: object, field: str, *, minimum: int = 0) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value < minimum:
        raise WorkflowAuthorizationError(f"invalid_integer:{field}")
    return value


def _string_list(
    value: object,
    field: str,
    *,
    allow_empty: bool = True,
    limit: int = 1024,
) -> tuple[str, ...]:
    if not isinstance(value, list):
        raise WorkflowAuthorizationError(f"invalid_string_list:{field}")
    result = tuple(_string(item, field, limit=limit) for item in value)
    if not allow_empty and not result:
        raise WorkflowAuthorizationError(f"empty_string_list:{field}")
    if len(result) != len(set(result)):
        raise WorkflowAuthorizationError(f"duplicate_list_item:{field}")
    return result


def _relative_path(value: object, field: str) -> str:
    path = _string(value, field).replace("\\", "/")
    candidate = Path(path)
    if (
        candidate.is_absolute()
        or path.startswith("/")
        or any(part in {"", ".", ".."} for part in path.split("/"))
        or any(char in path for char in "*?[]{}")
        or path.startswith(".git/")
    ):
        raise WorkflowAuthorizationError(f"invalid_path:{field}")
    return path


def _sha(value: object, field: str) -> str:
    result = _string(value, field)
    if not SHA_PATTERN.fullmatch(result):
        raise WorkflowAuthorizationError(f"invalid_sha:{field}")
    return result


def _hash(value: object, field: str) -> str:
    result = _string(value, field)
    if not HASH_PATTERN.fullmatch(result):
        raise WorkflowAuthorizationError(f"invalid_hash:{field}")
    return result if result.startswith("sha256:") else f"sha256:{result}"


def _expiry(value: object) -> datetime:
    text = _string(value, "expires_at")
    if not UTC_PATTERN.fullmatch(text):
        raise WorkflowAuthorizationError("expires_at_utc_required")
    try:
        return datetime.strptime(text, "%Y-%m-%dT%H:%M:%SZ").replace(
            tzinfo=timezone.utc
        )
    except ValueError as exc:
        raise WorkflowAuthorizationError("expires_at_utc_invalid") from exc


def _stage(value: object, index: int) -> WorkflowStageAuthorization:
    item = _exact(value, STAGE_FIELDS, f"stage_{index}")
    name = _string(item["name"], f"stages[{index}].name", limit=64)
    if not NAME_PATTERN.fullmatch(name):
        raise WorkflowAuthorizationError(f"stage_name_invalid:{index}")
    kind = _string(item["kind"], f"stages[{index}].kind", limit=32)
    if kind not in STAGE_KINDS:
        raise WorkflowAuthorizationError(f"stage_kind_invalid:{name}")
    capability = _string(item["capability"], f"stages[{index}].capability", limit=16)
    if capability not in CAPABILITIES:
        raise WorkflowAuthorizationError(f"stage_capability_invalid:{name}")
    family = _string(item["command_family"], f"stages[{index}].command_family", limit=64)
    argv = _string_list(item["argv"], f"stages[{index}].argv", limit=2048)
    if kind == "command" and not argv:
        raise WorkflowAuthorizationError(f"stage_argv_required:{name}")
    if kind != "command" and argv:
        raise WorkflowAuthorizationError(f"stage_argv_forbidden:{name}")
    cwd = _string(item["cwd"], f"stages[{index}].cwd", limit=16)
    if cwd not in {"controller", "target"}:
        raise WorkflowAuthorizationError(f"stage_cwd_invalid:{name}")
    timeout = _integer(item["timeout_seconds"], f"stages[{index}].timeout_seconds", minimum=1)
    output_limit = _integer(
        item["output_limit_bytes"], f"stages[{index}].output_limit_bytes", minimum=1024
    )
    retry_max = _integer(item["retry_max"], f"stages[{index}].retry_max")
    if not isinstance(item["reusable"], bool):
        raise WorkflowAuthorizationError(f"stage_reusable_invalid:{name}")
    failure_class = _string(
        item["failure_class"], f"stages[{index}].failure_class", limit=16
    )
    if failure_class not in FAILURE_CLASSES:
        raise WorkflowAuthorizationError(f"stage_failure_class_invalid:{name}")
    environment = _string_list(
        item["environment_allowlist"],
        f"stages[{index}].environment_allowlist",
        limit=128,
    )
    return WorkflowStageAuthorization(
        name=name,
        kind=kind,
        capability=capability,
        command_family=family,
        argv=argv,
        cwd=cwd,
        timeout_seconds=timeout,
        output_limit_bytes=output_limit,
        retry_max=retry_max,
        reusable=item["reusable"],
        failure_class=failure_class,
        environment_allowlist=environment,
    )


def parse_workflow_authorization(
    value: Mapping[str, object],
    *,
    transport_comment_id: int | None = None,
    now: datetime | None = None,
) -> WorkflowAuthorization:
    payload = _exact(value, TOP_LEVEL_FIELDS, "workflow_authorization")
    if payload["schema_version"] != 1:
        raise WorkflowAuthorizationError("schema_version_must_be_1")
    repository = _string(payload["repository"], "repository")
    if not REPOSITORY_PATTERN.fullmatch(repository):
        raise WorkflowAuthorizationError("repository_invalid")
    _integer(payload["issue"], "issue", minimum=1)
    comment_id = _integer(payload["comment_id"], "comment_id", minimum=1)
    if transport_comment_id is not None and comment_id != transport_comment_id:
        raise WorkflowAuthorizationError("comment_id_mismatch")
    _integer(payload["scope_version"], "scope_version", minimum=1)
    _sha(payload["controller_revision"], "controller_revision")

    target = _exact(payload["target"], TARGET_FIELDS, "target")
    _string(target["branch"], "target.branch")
    for field in ("base_sha", "head_sha", "tree_sha"):
        _sha(target[field], f"target.{field}")
    payload["target"] = target

    read_allowlist = tuple(
        _relative_path(item, "read_allowlist")
        for item in _string_list(payload["read_allowlist"], "read_allowlist")
    )
    write_allowlist = tuple(
        _relative_path(item, "write_allowlist")
        for item in _string_list(
            payload["write_allowlist"], "write_allowlist", allow_empty=False
        )
    )
    if len(set(read_allowlist)) != len(read_allowlist):
        raise WorkflowAuthorizationError("duplicate_list_item:read_allowlist")
    if len(set(write_allowlist)) != len(write_allowlist):
        raise WorkflowAuthorizationError("duplicate_list_item:write_allowlist")
    payload["read_allowlist"] = list(read_allowlist)
    payload["write_allowlist"] = list(write_allowlist)

    raw_stages = payload["stages"]
    if not isinstance(raw_stages, list) or not raw_stages:
        raise WorkflowAuthorizationError("stages_must_be_nonempty_list")
    stages = tuple(_stage(item, index) for index, item in enumerate(raw_stages))
    names = [item.name for item in stages]
    if len(names) != len(set(names)):
        raise WorkflowAuthorizationError("duplicate_stage_name")
    payload["stages"] = [item.public_dict() for item in stages]

    raw_capabilities = payload["capability_sequence"]
    if not isinstance(raw_capabilities, list) or not raw_capabilities:
        raise WorkflowAuthorizationError("capability_sequence_invalid")
    capabilities = tuple(
        _string(item, "capability_sequence", limit=16)
        for item in raw_capabilities
    )
    if any(item not in CAPABILITIES for item in capabilities):
        raise WorkflowAuthorizationError("capability_sequence_invalid")
    if capabilities != tuple(item.capability for item in stages):
        raise WorkflowAuthorizationError("capability_sequence_stage_mismatch")
    payload["capability_sequence"] = list(capabilities)

    if any(item.capability == "Device" for item in stages) and payload["device"] is None:
        raise WorkflowAuthorizationError("device_capability_requires_device_contract")

    raw_evidence = payload["reused_evidence"]
    if not isinstance(raw_evidence, list):
        raise WorkflowAuthorizationError("reused_evidence_must_be_list")
    evidence: list[dict[str, object]] = []
    evidence_stages: set[str] = set()
    for index, raw in enumerate(raw_evidence):
        item = _exact(raw, REUSED_EVIDENCE_FIELDS, f"reused_evidence_{index}")
        stage_name = _string(item["stage"], f"reused_evidence[{index}].stage", limit=64)
        if stage_name not in names or stage_name in evidence_stages:
            raise WorkflowAuthorizationError("reused_evidence_stage_invalid")
        evidence_stages.add(stage_name)
        item["stage"] = stage_name
        for field in (
            "source_fingerprint",
            "tool_fingerprint",
            "command_fingerprint",
            "evidence_fingerprint",
        ):
            item[field] = _hash(item[field], f"reused_evidence[{index}].{field}")
        if item["artifact_fingerprint"] is not None:
            item["artifact_fingerprint"] = _hash(
                item["artifact_fingerprint"],
                f"reused_evidence[{index}].artifact_fingerprint",
            )
        expected_evidence = _fingerprint(
            {key: current for key, current in item.items() if key != "evidence_fingerprint"}
        )
        if item["evidence_fingerprint"] != expected_evidence:
            raise WorkflowAuthorizationError("reused_evidence_fingerprint_invalid")
        evidence.append(item)
    payload["reused_evidence"] = evidence

    budgets = _exact(payload["budgets"], BUDGET_FIELDS, "budgets")
    for field in sorted(BUDGET_FIELDS):
        budgets[field] = _integer(
            budgets[field],
            f"budgets.{field}",
            minimum=1 if field in {"primary_max", "hard_stop_seconds"} else 0,
        )
    if budgets["primary_max"] != 1:
        raise WorkflowAuthorizationError("primary_max_must_equal_one")
    kind_budget = {
        "commit": "commit_max",
        "push": "push_max",
        "draft_pr": "draft_pr_max",
        "issue_comment": "github_comment_max",
    }
    for kind, budget_field in kind_budget.items():
        if sum(stage.kind == kind for stage in stages) > budgets[budget_field]:
            raise WorkflowAuthorizationError(f"stage_budget_insufficient:{kind}")
    command_count = sum(stage.kind in {"command", "artifact_verify"} for stage in stages)
    if command_count > budgets["command_max"]:
        raise WorkflowAuthorizationError("stage_budget_insufficient:command")
    if sum(stage.retry_max for stage in stages) > budgets["correction_max"]:
        raise WorkflowAuthorizationError("correction_budget_insufficient")
    payload["budgets"] = budgets

    artifact = payload["artifact"]
    if artifact is not None:
        artifact = _exact(artifact, ARTIFACT_FIELDS, "artifact")
        artifact["path"] = _string(artifact["path"], "artifact.path")
        artifact["sha256"] = _hash(artifact["sha256"], "artifact.sha256")
        for field in ("package", "version", "signer"):
            artifact[field] = _string(artifact[field], f"artifact.{field}")
        artifact["checkpoint_sha"] = _sha(
            artifact["checkpoint_sha"], "artifact.checkpoint_sha"
        )
        payload["artifact"] = artifact

    device = payload["device"]
    if device is not None:
        device = _exact(device, DEVICE_FIELDS, "device")
        for field in sorted(DEVICE_FIELDS):
            device[field] = _string(device[field], f"device.{field}")
        if artifact is None:
            raise WorkflowAuthorizationError("device_requires_artifact")
        payload["device"] = device
        serial = str(device["serial"])
        forbidden = {"uninstall", "clear", "clear-data", "--downgrade", "-d"}
        for stage in stages:
            if stage.capability != "Device":
                continue
            if stage.kind != "command" or not stage.argv:
                raise WorkflowAuthorizationError(
                    f"device_stage_must_be_command:{stage.name}"
                )
            if Path(stage.argv[0]).name.lower() not in {"adb", "adb.exe"}:
                raise WorkflowAuthorizationError(
                    f"device_stage_must_use_adb:{stage.name}"
                )
            serial_switches = [
                stage.argv[index + 1]
                for index, item in enumerate(stage.argv[:-1])
                if item == "-s"
            ]
            if serial_switches != [serial]:
                raise WorkflowAuthorizationError(
                    f"device_stage_serial_invalid:{stage.name}"
                )
            if {item.lower() for item in stage.argv} & forbidden:
                raise WorkflowAuthorizationError(
                    f"device_stage_forbidden_operation:{stage.name}"
                )

    publish = payload["publish"]
    if publish is not None:
        publish = _exact(publish, PUBLISH_FIELDS, "publish")
        for field in sorted(PUBLISH_FIELDS):
            publish[field] = _string(publish[field], f"publish.{field}")
        if publish["base_branch"] != "master":
            raise WorkflowAuthorizationError("publish_base_must_be_master")
        prefix = publish["body_first_line"]
        if prefix not in {f"Related to #{payload['issue']}", f"Closes #{payload['issue']}"}:
            raise WorkflowAuthorizationError("publish_issue_prefix_invalid")
        payload["publish"] = publish

    if not isinstance(payload["execution"], bool):
        raise WorkflowAuthorizationError("execution_must_be_boolean")
    expires_at = _expiry(payload["expires_at"])
    current = now or datetime.now(timezone.utc)
    if current.tzinfo is None or current.utcoffset() is None:
        raise ValueError("now_must_be_timezone_aware")
    if current.astimezone(timezone.utc) >= expires_at:
        raise WorkflowAuthorizationError("authorization_expired")
    _string(payload["nonce"], "nonce", limit=256)
    supersedes = payload["supersedes_comment_id"]
    if supersedes is not None:
        _integer(supersedes, "supersedes_comment_id", minimum=1)

    normalized = json.loads(canonical_json_bytes(payload))
    return WorkflowAuthorization(
        payload=normalized,
        fingerprint=_fingerprint(normalized),
        expires_at=expires_at,
        stages=stages,
    )


def parse_workflow_authorization_comment(
    comment: Mapping[str, object],
    *,
    now: datetime | None = None,
) -> WorkflowAuthorization:
    comment_id = _integer(comment.get("id"), "transport_comment_id", minimum=1)
    body = comment.get("body")
    if not isinstance(body, str) or body.count(WORKFLOW_AUTHORIZATION_MARKER) != 1:
        raise WorkflowAuthorizationError("authorization_marker_count_invalid")
    tail = body.split(WORKFLOW_AUTHORIZATION_MARKER, 1)[1]
    matches = FENCED_JSON_PATTERN.findall(tail)
    if len(matches) != 1 or tail.count("```json") != 1:
        raise WorkflowAuthorizationError("authorization_json_fence_count_invalid")
    try:
        value = json.loads(matches[0], object_pairs_hook=_duplicate_rejector)
    except WorkflowAuthorizationError:
        raise
    except (json.JSONDecodeError, TypeError) as exc:
        raise WorkflowAuthorizationError("authorization_json_invalid") from exc
    if not isinstance(value, dict):
        raise WorkflowAuthorizationError("authorization_payload_must_be_object")
    return parse_workflow_authorization(
        value,
        transport_comment_id=comment_id,
        now=now,
    )


def select_latest_workflow_authorization(
    comments: Iterable[Mapping[str, object]],
    *,
    now: datetime | None = None,
) -> WorkflowAuthorizationSelection:
    candidates = sorted(
        (
            item
            for item in comments
            if isinstance(item.get("body"), str)
            and WORKFLOW_AUTHORIZATION_MARKER in str(item.get("body"))
        ),
        key=lambda item: int(item.get("id", 0)),
    )
    if not candidates:
        return WorkflowAuthorizationSelection(status="missing")
    active: WorkflowAuthorization | None = None
    last_error: WorkflowAuthorizationSelection | None = None
    for comment in candidates:
        comment_id = int(comment.get("id", 0)) or None
        try:
            candidate = parse_workflow_authorization_comment(comment, now=now)
        except WorkflowAuthorizationError as exc:
            last_error = WorkflowAuthorizationSelection(
                status="invalid",
                comment_id=comment_id,
                reason=exc.reason,
            )
            continue
        supersedes = candidate.payload["supersedes_comment_id"]
        if active is None and supersedes is None:
            active = candidate
        elif active is not None and supersedes == active.comment_id:
            active = candidate
        else:
            last_error = WorkflowAuthorizationSelection(
                status="invalid",
                comment_id=candidate.comment_id,
                reason="supersession_chain_invalid",
            )
    if active is not None:
        return WorkflowAuthorizationSelection(
            status="valid",
            authorization=active,
            comment_id=active.comment_id,
        )
    return last_error or WorkflowAuthorizationSelection(status="missing")
