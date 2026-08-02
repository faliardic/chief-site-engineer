"""Fail-closed O9 API proposal to Codex child and Draft-PR coordinator."""

from __future__ import annotations

from dataclasses import dataclass, replace
from enum import Enum
import hashlib
import json
import re
import shlex
from typing import Mapping

from .api_planner import ApiProposalError, PROPOSAL_JSON_SCHEMA, ProposalContract
from .codex_adapter import CodexAdapterError, CodexChildAdapter, CodexChildRequest
from .github_rest import (
    GitHubRestClient,
    GitHubRestContract,
    GitHubRestError,
    HostPublisher,
    HostPublishRequest,
)
from .openai_client import OpenAIClientError, OpenAIResponsesClient
from .policy import PolicyDecision


_PROPOSAL_FIELDS = ("decision", "summary", "risk", "codex_prompt")
_PROPOSAL_ONLY_SCHEMA: dict[str, object] = {
    "type": "object",
    "additionalProperties": False,
    "required": list(_PROPOSAL_FIELDS),
    "properties": {
        "decision": {"type": "string", "enum": ["proceed", "block"]},
        "summary": {"type": "string", "minLength": 1, "maxLength": 1000},
        "risk": {"type": "string", "enum": ["low", "medium", "high"]},
        "codex_prompt": {"type": "string", "minLength": 1, "maxLength": 12000},
    },
}
# OpenAIResponsesClient holds this imported schema object by reference. Keep the
# strict wire contract proposal-only without moving immutable local authority.
PROPOSAL_JSON_SCHEMA.clear()
PROPOSAL_JSON_SCHEMA.update(_PROPOSAL_ONLY_SCHEMA)

_SECRET = re.compile(
    r"(?i)(authorization\s*:\s*bearer|(?:api[_-]?key|token|secret|password)\s*[:=]|"
    r"sk-[A-Za-z0-9_-]{12,}|gh[pousr]_[A-Za-z0-9_]{12,})"
)


@dataclass(frozen=True)
class _ValidatedProposal:
    decision: str
    summary: str
    risk: str
    codex_prompt: str
    write_allowlist: tuple[str, ...]
    validation_commands: tuple[str, ...]
    commit_message: str
    pr_title: str
    pr_body_prefix: str
    required_approval_level: str
    fingerprint: str


def _proposal_text(value: object, field: str, limit: int) -> str:
    if not isinstance(value, str) or not value or len(value) > limit or "\x00" in value:
        raise ApiProposalError(f"{field}_invalid")
    if _SECRET.search(value):
        raise ApiProposalError(f"{field}_contains_secret")
    return value


def validate_api_proposal(
    value: Mapping[str, object],
    contract: ProposalContract,
    decision: PolicyDecision,
) -> _ValidatedProposal:
    """Validate model judgment, then bind execution data from local authority."""

    if not isinstance(value, Mapping) or set(value) != set(_PROPOSAL_FIELDS):
        raise ApiProposalError("proposal_fields_invalid")
    if not isinstance(contract, ProposalContract):
        raise ApiProposalError("proposal_contract_required")
    if not isinstance(decision, PolicyDecision) or not decision.allowed:
        raise ApiProposalError("policy_denied")
    if decision.state_to != "ACTION_AUTHORIZED":
        raise ApiProposalError("policy_state_invalid")
    if decision.required_approval_level != contract.required_approval_level:
        raise ApiProposalError("policy_approval_mismatch")
    if dict(decision.budget_delta or {}) != {
        "api_request": contract.api_request_budget,
        "codex_child": contract.codex_child_budget,
        "github_pr": contract.github_pr_budget,
    }:
        raise ApiProposalError("policy_budget_mismatch")
    proposal_decision = value["decision"]
    risk = value["risk"]
    if proposal_decision not in {"proceed", "block"}:
        raise ApiProposalError("decision_invalid")
    if risk not in {"low", "medium", "high"}:
        raise ApiProposalError("risk_invalid")
    summary = _proposal_text(value["summary"], "summary", 1000)
    codex_prompt = _proposal_text(value["codex_prompt"], "codex_prompt", 12000)
    encoded = json.dumps(dict(value), sort_keys=True, separators=(",", ":")).encode()
    return _ValidatedProposal(
        decision=str(proposal_decision),
        summary=summary,
        risk=str(risk),
        codex_prompt=codex_prompt,
        write_allowlist=contract.write_allowlist,
        validation_commands=contract.validation_commands,
        commit_message=contract.commit_message,
        pr_title=contract.pr_title,
        pr_body_prefix=contract.pr_body_prefix,
        required_approval_level=contract.required_approval_level,
        fingerprint="sha256:" + hashlib.sha256(encoded).hexdigest(),
    )


def _validate_host_authority(
    request: HostPublishRequest,
    contract: ProposalContract,
) -> None:
    """Require every host-owned execution field to match local authority."""

    try:
        validation_argv = tuple(
            tuple(shlex.split(command, posix=True))
            for command in contract.validation_commands
        )
    except ValueError as exc:
        raise ApiProposalError("validation_commands_invalid") from exc
    if request.write_allowlist != contract.write_allowlist:
        raise ApiProposalError("host_write_allowlist_drift")
    if request.validation_argv != validation_argv:
        raise ApiProposalError("host_validation_commands_drift")
    if request.commit_message != contract.commit_message:
        raise ApiProposalError("host_commit_message_drift")
    if request.github.title != contract.pr_title:
        raise ApiProposalError("host_pr_title_drift")
    if not request.github.body.startswith(contract.pr_body_prefix):
        raise ApiProposalError("host_pr_body_prefix_drift")


class AutomationStatus(str, Enum):
    DRY_RUN = "DRY_RUN"
    API_COMPLETED = "API_COMPLETED"
    CHILD_COMPLETED = "CHILD_COMPLETED"
    PUBLISHED = "PUBLISHED"
    BLOCKED = "BLOCKED"


@dataclass(frozen=True)
class ApiAutomationResult:
    status: AutomationStatus
    reason: str | None
    api: dict[str, object] | None
    codex: dict[str, object] | None
    github: dict[str, object] | None

    def public_dict(self) -> dict[str, object]:
        return {
            "schema_version": 1,
            "status": self.status.value,
            "reason": self.reason,
            "api": self.api,
            "codex": self.codex,
            "github": self.github,
        }


def _reason(exc: Exception) -> str:
    message = str(exc).split(":", 1)[0]
    return message if message else type(exc).__name__


class ApiAutomationEngine:
    """Coordinate injected adapters while retaining local policy authority."""

    def __init__(
        self,
        *,
        openai_client: OpenAIResponsesClient,
        codex_adapter: CodexChildAdapter,
        github_client: GitHubRestClient,
        host_publisher: HostPublisher | None = None,
    ) -> None:
        self._openai = openai_client
        self._codex = codex_adapter
        self._github = github_client
        self._host = host_publisher or HostPublisher()

    def run(
        self,
        *,
        prompt: str,
        proposal_contract: ProposalContract,
        policy_decision: PolicyDecision,
        codex_request: CodexChildRequest,
        github_contract: GitHubRestContract | None = None,
        host_publish_request: HostPublishRequest | None = None,
        execute: bool = False,
        publish: bool = False,
        execute_api: bool | None = None,
        execute_codex: bool | None = None,
        execute_publish: bool | None = None,
    ) -> ApiAutomationResult:
        api_gate = execute if execute_api is None else execute_api
        codex_gate = execute if execute_codex is None else execute_codex
        publish_gate = publish if execute_publish is None else execute_publish
        if codex_request.action_fingerprint != proposal_contract.action_fingerprint:
            return ApiAutomationResult(
                AutomationStatus.BLOCKED,
                "action_fingerprint_drift",
                None,
                None,
                None,
            )
        if codex_gate and not api_gate:
            return ApiAutomationResult(AutomationStatus.BLOCKED, "api_gate_required", None, None, None)
        if publish_gate and not codex_gate:
            return ApiAutomationResult(AutomationStatus.BLOCKED, "codex_gate_required", None, None, None)
        if publish_gate and host_publish_request is None:
            return ApiAutomationResult(AutomationStatus.BLOCKED, "host_publish_request_required", None, None, None)
        if publish_gate:
            try:
                _validate_host_authority(host_publish_request, proposal_contract)
            except ApiProposalError as exc:
                return ApiAutomationResult(AutomationStatus.BLOCKED, _reason(exc), None, None, None)
        if not api_gate:
            return ApiAutomationResult(AutomationStatus.DRY_RUN, None, None, None, None)
        try:
            if publish_gate:
                self._host.preflight(host_publish_request, execute=True)
            envelope = self._openai.request_proposal(prompt, execute=True)
            if envelope.proposal is None:
                raise ApiProposalError("proposal_missing")
            proposal = validate_api_proposal(
                envelope.proposal,
                proposal_contract,
                policy_decision,
            )
            if proposal.decision != "proceed":
                raise ApiProposalError("model_blocked")
            if not codex_gate:
                return ApiAutomationResult(
                    AutomationStatus.API_COMPLETED,
                    None,
                    envelope.public_dict(),
                    None,
                    None,
                )
            if publish_gate:
                self._host.verify_baseline(host_publish_request, execute=True)
            child = self._codex.execute(
                replace(codex_request, prompt=proposal.codex_prompt),
                execute=True,
            )
            if child.status != "PASS":
                return ApiAutomationResult(
                    AutomationStatus.BLOCKED,
                    child.status,
                    envelope.public_dict(),
                    child.public_dict(),
                    None,
                )
            if not publish_gate:
                return ApiAutomationResult(
                    AutomationStatus.CHILD_COMPLETED,
                    None,
                    envelope.public_dict(),
                    child.public_dict(),
                    None,
                )
            resolved_contract = self._host.publish(host_publish_request, execute=True)
            pull_request = self._github.create_draft_pull_request(resolved_contract, execute=True)
            return ApiAutomationResult(
                AutomationStatus.PUBLISHED,
                None,
                envelope.public_dict(),
                child.public_dict(),
                pull_request.public_dict(),
            )
        except (OpenAIClientError, ApiProposalError, CodexAdapterError, GitHubRestError) as exc:
            return ApiAutomationResult(AutomationStatus.BLOCKED, _reason(exc), None, None, None)
