"""Strict local validation for untrusted O9 API proposals."""

from __future__ import annotations

import hashlib
import json
import re
from dataclasses import dataclass
from typing import Mapping

from .policy import PolicyDecision


PROPOSAL_FIELDS = (
    "decision",
    "risk",
    "summary",
    "codex_prompt",
    "write_allowlist",
    "validation_commands",
    "commit_message",
    "pr_title",
    "pr_body_prefix",
    "required_approval_level",
)

PROPOSAL_JSON_SCHEMA: dict[str, object] = {
    "type": "object",
    "additionalProperties": False,
    "required": list(PROPOSAL_FIELDS),
    "properties": {
        "decision": {"type": "string", "enum": ["proceed", "block"]},
        "risk": {"type": "string", "enum": ["low", "medium", "high"]},
        "summary": {"type": "string", "minLength": 1, "maxLength": 1000},
        "codex_prompt": {"type": "string", "minLength": 1, "maxLength": 12000},
        "write_allowlist": {
            "type": "array",
            "items": {"type": "string"},
            "maxItems": 64,
        },
        "validation_commands": {
            "type": "array",
            "items": {"type": "string"},
            "maxItems": 32,
        },
        "commit_message": {"type": "string", "minLength": 1, "maxLength": 200},
        "pr_title": {"type": "string", "minLength": 1, "maxLength": 200},
        "pr_body_prefix": {"type": "string", "minLength": 1, "maxLength": 200},
        "required_approval_level": {"type": "string", "minLength": 1, "maxLength": 64},
    },
}

_SECRET = re.compile(
    r"(?i)(authorization\s*:\s*bearer|(?:api[_-]?key|token|secret|password)\s*[:=]|sk-[A-Za-z0-9_-]{12,}|gh[pousr]_[A-Za-z0-9_]{12,})"
)
_FINGERPRINT = re.compile(r"^sha256:[0-9a-f]{64}$")


class ApiProposalError(ValueError):
    """The model proposal conflicts with the immutable local contract."""


def _tuple_of_strings(value: object, field: str) -> tuple[str, ...]:
    if not isinstance(value, list) or any(
        not isinstance(item, str) or not item or "\x00" in item for item in value
    ):
        raise ApiProposalError(f"{field}_invalid")
    if len(set(value)) != len(value):
        raise ApiProposalError(f"{field}_duplicates")
    return tuple(value)


@dataclass(frozen=True)
class ProposalContract:
    capability: str
    write_allowlist: tuple[str, ...]
    validation_commands: tuple[str, ...]
    commit_message: str
    pr_title: str
    pr_body_prefix: str
    required_approval_level: str
    api_request_budget: int
    codex_child_budget: int
    github_pr_budget: int
    source_fingerprint: str
    contract_fingerprint: str
    action_fingerprint: str

    def __post_init__(self) -> None:
        if self.capability != "Code + Network + Publish":
            raise ApiProposalError("capability_invalid")
        for field in ("write_allowlist", "validation_commands"):
            values = getattr(self, field)
            if not isinstance(values, tuple) or not values or len(set(values)) != len(values):
                raise ApiProposalError(f"{field}_invalid")
        if (self.api_request_budget, self.codex_child_budget, self.github_pr_budget) != (1, 1, 1):
            raise ApiProposalError("budget_invalid")
        if any(
            not _FINGERPRINT.fullmatch(value)
            for value in (
                self.source_fingerprint,
                self.contract_fingerprint,
                self.action_fingerprint,
            )
        ):
            raise ApiProposalError("fingerprint_invalid")


@dataclass(frozen=True)
class ApiProposal:
    decision: str
    risk: str
    summary: str
    codex_prompt: str
    write_allowlist: tuple[str, ...]
    validation_commands: tuple[str, ...]
    commit_message: str
    pr_title: str
    pr_body_prefix: str
    required_approval_level: str
    fingerprint: str

    def public_dict(self) -> dict[str, object]:
        return {
            "decision": self.decision,
            "risk": self.risk,
            "summary": self.summary,
            "write_allowlist": list(self.write_allowlist),
            "validation_commands": list(self.validation_commands),
            "commit_message": self.commit_message,
            "pr_title": self.pr_title,
            "pr_body_prefix": self.pr_body_prefix,
            "required_approval_level": self.required_approval_level,
            "fingerprint": self.fingerprint,
        }


def _required_text(value: object, field: str, limit: int) -> str:
    if not isinstance(value, str) or not value or len(value) > limit or "\x00" in value:
        raise ApiProposalError(f"{field}_invalid")
    if _SECRET.search(value):
        raise ApiProposalError(f"{field}_contains_secret")
    return value


def _fingerprint(value: Mapping[str, object]) -> str:
    encoded = json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode()
    return "sha256:" + hashlib.sha256(encoded).hexdigest()


def validate_api_proposal(
    value: Mapping[str, object],
    contract: ProposalContract,
    decision: PolicyDecision,
) -> ApiProposal:
    """Treat API output as untrusted input and bind it to local O1-O8 authority."""

    if not isinstance(value, Mapping) or set(value) != set(PROPOSAL_FIELDS):
        raise ApiProposalError("proposal_fields_invalid")
    if not isinstance(contract, ProposalContract):
        raise ApiProposalError("proposal_contract_required")
    if not isinstance(decision, PolicyDecision) or not decision.allowed:
        raise ApiProposalError("policy_denied")
    if decision.state_to != "ACTION_AUTHORIZED":
        raise ApiProposalError("policy_state_invalid")
    if decision.required_approval_level != contract.required_approval_level:
        raise ApiProposalError("policy_approval_mismatch")
    budget = dict(decision.budget_delta or {})
    if budget != {
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
    writes = _tuple_of_strings(value["write_allowlist"], "write_allowlist")
    commands = _tuple_of_strings(value["validation_commands"], "validation_commands")
    if writes != contract.write_allowlist:
        raise ApiProposalError("write_allowlist_drift")
    if commands != contract.validation_commands:
        raise ApiProposalError("validation_commands_drift")
    fields = {
        "summary": _required_text(value["summary"], "summary", 1000),
        "codex_prompt": _required_text(value["codex_prompt"], "codex_prompt", 12000),
        "commit_message": _required_text(value["commit_message"], "commit_message", 200),
        "pr_title": _required_text(value["pr_title"], "pr_title", 200),
        "pr_body_prefix": _required_text(value["pr_body_prefix"], "pr_body_prefix", 200),
        "required_approval_level": _required_text(
            value["required_approval_level"], "required_approval_level", 64
        ),
    }
    comparisons = {
        "commit_message": contract.commit_message,
        "pr_title": contract.pr_title,
        "pr_body_prefix": contract.pr_body_prefix,
        "required_approval_level": contract.required_approval_level,
    }
    for field, expected in comparisons.items():
        if fields[field] != expected:
            reason = "approval_drift" if field == "required_approval_level" else f"{field}_drift"
            raise ApiProposalError(reason)
    frozen = {
        **dict(value),
        "write_allowlist": list(writes),
        "validation_commands": list(commands),
    }
    return ApiProposal(
        decision=str(proposal_decision),
        risk=str(risk),
        summary=fields["summary"],
        codex_prompt=fields["codex_prompt"],
        write_allowlist=writes,
        validation_commands=commands,
        commit_message=fields["commit_message"],
        pr_title=fields["pr_title"],
        pr_body_prefix=fields["pr_body_prefix"],
        required_approval_level=fields["required_approval_level"],
        fingerprint=_fingerprint(frozen),
    )
