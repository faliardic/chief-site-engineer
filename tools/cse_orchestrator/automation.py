"""Fail-closed O9 API proposal to Codex child and Draft-PR coordinator."""

from __future__ import annotations

from dataclasses import dataclass, replace
from enum import Enum

from .api_planner import ApiProposalError, ProposalContract, validate_api_proposal
from .codex_adapter import CodexAdapterError, CodexChildAdapter, CodexChildRequest
from .github_rest import GitHubRestClient, GitHubRestContract, GitHubRestError
from .openai_client import OpenAIClientError, OpenAIResponsesClient
from .policy import PolicyDecision


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
    ) -> None:
        self._openai = openai_client
        self._codex = codex_adapter
        self._github = github_client

    def run(
        self,
        *,
        prompt: str,
        proposal_contract: ProposalContract,
        policy_decision: PolicyDecision,
        codex_request: CodexChildRequest,
        github_contract: GitHubRestContract,
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
        if not api_gate:
            return ApiAutomationResult(AutomationStatus.DRY_RUN, None, None, None, None)
        try:
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
            pull_request = self._github.create_draft_pull_request(
                github_contract,
                execute=True,
            )
            return ApiAutomationResult(
                AutomationStatus.PUBLISHED,
                None,
                envelope.public_dict(),
                child.public_dict(),
                pull_request.public_dict(),
            )
        except (OpenAIClientError, ApiProposalError, CodexAdapterError, GitHubRestError) as exc:
            return ApiAutomationResult(AutomationStatus.BLOCKED, _reason(exc), None, None, None)
