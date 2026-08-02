"""Data-minimal normal-push and Draft-PR contracts for CSE O8."""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path
from typing import Mapping, Protocol

from .planner import ActionPlan, PlanError, build_action_plan
from .policy import PolicyDecision
from .results import ParsedCommandResult, parse_command_result
from .runner import ControlledRunner, ExecutionResult


SHA_PATTERN = re.compile(r"^[0-9a-f]{40}$")
FORBIDDEN_PUBLISH_ACTIONS = frozenset(
    {"READY", "MERGE", "ISSUE_CLOSE", "BRANCH_DELETE", "RELEASE"}
)


class PublishError(RuntimeError):
    """Publish provenance or single-Draft-PR safety failed closed."""


class GitHubClient(Protocol):
    def find_open_pull_request(self, *, branch: str, base_branch: str) -> int | None: ...

    def create_draft_pull_request(
        self, payload: dict[str, object]
    ) -> dict[str, object]: ...


@dataclass(frozen=True)
class PublishResult:
    push_result: ExecutionResult
    github_result: ParsedCommandResult | None
    pull_request: Mapping[str, object] | None

    def public_dict(self) -> dict[str, object]:
        return {
            "schema_version": 1,
            "push_result": self.push_result.public_dict(),
            "github_result": (
                self.github_result.public_dict() if self.github_result else None
            ),
            "pull_request": dict(self.pull_request or {}),
        }


def _exact(value: Mapping[str, object], fields: set[str]) -> dict[str, object]:
    if not isinstance(value, Mapping):
        raise PublishError("publish_contract_must_be_object")
    if set(value) != fields:
        raise PublishError("publish_contract_fields_invalid")
    return dict(value)


def _required_string(value: object, field: str) -> str:
    if not isinstance(value, str) or not value or "\x00" in value:
        raise PublishError(f"invalid_string:{field}")
    return value


def build_publish_plan(
    observation: Mapping[str, object],
    decision: PolicyDecision,
    action_request: Mapping[str, object],
    publish_contract: Mapping[str, object],
) -> ActionPlan:
    contract = _exact(
        publish_contract,
        {
            "branch",
            "head_sha",
            "base_branch",
            "base_sha",
            "remote_divergence",
            "related_issue",
            "title",
            "body",
            "draft",
            "existing_pr",
        },
    )
    if action_request.get("pending_action") != "PUBLISH":
        raise PublishError("publish_action_required")
    actions = action_request.get("action_allowlist")
    if not isinstance(actions, list) or actions != ["PUBLISH"]:
        if isinstance(actions, list) and any(
            item in FORBIDDEN_PUBLISH_ACTIONS for item in actions
        ):
            raise PublishError("out_of_scope_publish_action")
        raise PublishError("publish_action_allowlist_invalid")
    branch = _required_string(contract["branch"], "branch")
    head_sha = _required_string(contract["head_sha"], "head_sha")
    base_sha = _required_string(contract["base_sha"], "base_sha")
    if not SHA_PATTERN.fullmatch(head_sha) or not SHA_PATTERN.fullmatch(base_sha):
        raise PublishError("publish_sha_invalid")
    if contract["base_branch"] != "master":
        raise PublishError("publish_base_must_be_master")
    if contract["remote_divergence"] != [0, 0]:
        raise PublishError("remote_divergence")
    if contract["draft"] is not True:
        raise PublishError("draft_required")
    if contract["existing_pr"] is not False:
        raise PublishError("duplicate_pr")
    issue = contract["related_issue"]
    if isinstance(issue, bool) or not isinstance(issue, int) or issue < 1:
        raise PublishError("related_issue_invalid")
    body = _required_string(contract["body"], "body")
    if body.splitlines()[0] != f"Closes #{issue}":
        raise PublishError("related_issue_prefix_invalid")
    contract["title"] = _required_string(contract["title"], "title")
    contract["body"] = body
    argv = action_request.get("argv")
    expected_argv = ["git", "push", "origin", branch]
    if argv != expected_argv:
        raise PublishError("normal_push_argv_required")
    if any(
        isinstance(item, str) and ("force" in item.lower() or item == "-f")
        for item in argv
    ):
        raise PublishError("force_push_forbidden")
    if action_request.get("branch") != branch or action_request.get("head_sha") != head_sha:
        raise PublishError("publish_source_mismatch")
    request = dict(action_request)
    request["provenance"] = {"publish": contract}
    try:
        return build_action_plan(observation, decision, request)
    except PlanError as exc:
        raise PublishError(str(exc)) from exc


def _github_frozen_result(
    *,
    action_started: bool,
    success: bool,
    failed_stage: str | None = None,
) -> ParsedCommandResult:
    return parse_command_result(
        {
            "schema_version": 1,
            "command_family": "generic_command",
            "action_started": action_started,
            "wrapper_failed": not action_started,
            "exit_code": 0 if action_started and success else (1 if action_started else None),
            "duration_ms": 0,
            "stdout": "draft pull request created" if success else "",
            "stderr": "github adapter failed" if not success else "",
            "truncated": False,
            "timed_out": False,
            "failed_stage": failed_stage,
        }
    )


def execute_publish(
    plan: ActionPlan,
    controlled_runner: ControlledRunner,
    github_client: GitHubClient,
    decision: PolicyDecision,
    *,
    execute: bool,
    current_source_fingerprint: str,
    current_action_fingerprint: str,
) -> PublishResult:
    """Execute one admitted normal push, then one injected Draft-PR creation."""

    if plan.pending_action != "PUBLISH":
        raise PublishError("publish_plan_required")
    publish = plan.provenance.get("publish")
    if not isinstance(publish, Mapping):
        raise PublishError("publish_provenance_missing")
    branch = _required_string(publish.get("branch"), "branch")
    base_branch = _required_string(publish.get("base_branch"), "base_branch")
    existing = github_client.find_open_pull_request(
        branch=branch,
        base_branch=base_branch,
    )
    if existing is not None:
        raise PublishError("duplicate_pr")
    push_result = controlled_runner.execute(
        plan,
        decision,
        execute=execute,
        current_source_fingerprint=current_source_fingerprint,
        current_action_fingerprint=current_action_fingerprint,
    )
    if not push_result.success:
        return PublishResult(
            push_result=push_result,
            github_result=None,
            pull_request=None,
        )
    payload = {
        "title": publish["title"],
        "body": publish["body"],
        "head": branch,
        "base": base_branch,
        "draft": True,
    }
    try:
        response = github_client.create_draft_pull_request(payload)
    except Exception as exc:
        result = _github_frozen_result(
            action_started=False,
            success=False,
            failed_stage=f"github_adapter:{type(exc).__name__}",
        )
        return PublishResult(
            push_result=push_result,
            github_result=result,
            pull_request=None,
        )
    if (
        not isinstance(response, dict)
        or isinstance(response.get("number"), bool)
        or not isinstance(response.get("number"), int)
        or response.get("state") != "open"
        or response.get("draft") is not True
    ):
        result = _github_frozen_result(
            action_started=True,
            success=False,
            failed_stage="github_response_validation",
        )
        return PublishResult(
            push_result=push_result,
            github_result=result,
            pull_request=None,
        )
    return PublishResult(
        push_result=push_result,
        github_result=_github_frozen_result(action_started=True, success=True),
        pull_request={
            "number": response["number"],
            "state": "open",
            "draft": True,
        },
    )
