"""Fail-closed observer, planning, execution, gate, publish, and ledger CLI."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
from typing import Mapping, Sequence

from .gates import GatePlanError, build_build_plan, build_checkpoint_plan, build_device_plan
from .api_planner import ApiProposalError, ProposalContract
from .automation import ApiAutomationEngine
from .codex_adapter import CodexAdapterError, CodexChildAdapter, CodexChildRequest
from .github_adapter import PublishError, build_publish_plan
from .github_rest import (
    GitHubRestClient,
    GitHubRestError,
    GitHubRestTemplate,
    HostPublisher,
    HostPublishRequest,
)
from .ledger import LedgerError, RuntimeLedger
from .observer import REPOSITORY_PATTERN, observe_repository
from .openai_client import OpenAIClientError, OpenAIResponsesClient
from .planner import ActionPlan, PlanError, build_action_plan, current_environment
from .policy import PolicyDecision
from .runner import ControlledRunner, ExecutionError, SubprocessProcessAdapter


def _positive_issue(value: str) -> int:
    try:
        issue = int(value)
    except ValueError as exc:
        raise argparse.ArgumentTypeError("issue must be a positive integer") from exc
    if issue < 1:
        raise argparse.ArgumentTypeError("issue must be a positive integer")
    return issue


def _repository(value: str) -> str:
    if not REPOSITORY_PATTERN.fullmatch(value):
        raise argparse.ArgumentTypeError("repository must be owner/name")
    return value


def _strict_path(value: str) -> Path:
    if not value or "\x00" in value:
        raise argparse.ArgumentTypeError("path is invalid")
    return Path(value)


def _read_object(path: Path) -> dict[str, object]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError("json_object_required")
    return value


def _decision(value: Mapping[str, object]) -> PolicyDecision:
    expected = {
        "allowed",
        "state_from",
        "state_to",
        "required_approval_level",
        "blockers",
        "budget_delta",
        "reused_evidence",
        "reasons",
    }
    if set(value) != expected:
        raise ValueError("policy_decision_fields_invalid")
    blockers = value["blockers"]
    reasons = value["reasons"]
    reused = value["reused_evidence"]
    budget = value["budget_delta"]
    if (
        not isinstance(blockers, list)
        or not all(isinstance(item, str) for item in blockers)
        or not isinstance(reasons, list)
        or not all(isinstance(item, str) for item in reasons)
        or not isinstance(reused, list)
        or not all(isinstance(item, dict) for item in reused)
        or not isinstance(budget, dict)
    ):
        raise ValueError("policy_decision_types_invalid")
    return PolicyDecision(
        allowed=value["allowed"] is True,
        state_from=str(value["state_from"]),
        state_to=str(value["state_to"]),
        required_approval_level=(
            str(value["required_approval_level"])
            if value["required_approval_level"] is not None
            else None
        ),
        blockers=tuple(blockers),
        budget_delta={str(key): int(item) for key, item in budget.items()},
        reused_evidence=tuple(dict(item) for item in reused),
        reasons=tuple(reasons),
    )


def _json_inputs(parser: argparse.ArgumentParser, *, contract: bool = False) -> None:
    parser.add_argument("--observation", required=True, type=_strict_path)
    parser.add_argument("--decision", required=True, type=_strict_path)
    parser.add_argument("--request", required=True, type=_strict_path)
    if contract:
        parser.add_argument("--contract", required=True, type=_strict_path)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="python -m tools.cse_orchestrator.cli",
        description="CSE Development Orchestrator read-only observer",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)
    observe = subparsers.add_parser(
        "observe",
        help="Collect one sanitized, read-only Observation v1",
    )
    observe.add_argument("--repo-root", required=True, type=_strict_path)
    observe.add_argument("--repository", required=True, type=_repository)
    observe.add_argument("--issue", required=True, type=_positive_issue)
    observe.add_argument("--runtime-root", required=True, type=_strict_path)

    plan = subparsers.add_parser("plan", help="Produce canonical dry-run ActionPlan v1")
    _json_inputs(plan)

    execute = subparsers.add_parser(
        "execute", help="Execute one exact admitted plan; requires --execute"
    )
    execute.add_argument("--plan", required=True, type=_strict_path)
    execute.add_argument("--decision", required=True, type=_strict_path)
    execute.add_argument("--repo-root", required=True, type=_strict_path)
    execute.add_argument("--runtime-root", required=True, type=_strict_path)
    execute.add_argument("--source-fingerprint", required=True)
    execute.add_argument("--action-fingerprint", required=True)
    execute.add_argument("--execute", action="store_true")

    gate = subparsers.add_parser(
        "gate-plan", help="Produce checkpoint, build, or device ActionPlan v1"
    )
    _json_inputs(gate, contract=True)
    gate.add_argument("--gate", choices=("checkpoint", "build", "device"), required=True)

    publish = subparsers.add_parser(
        "publish-plan", help="Produce normal-push plus Draft-PR ActionPlan v1"
    )
    _json_inputs(publish, contract=True)

    verify = subparsers.add_parser(
        "ledger-verify", help="Verify the external append-only runtime ledger"
    )
    verify.add_argument("--repo-root", required=True, type=_strict_path)
    verify.add_argument("--runtime-root", required=True, type=_strict_path)
    verify.add_argument("--run-id", required=True)

    api_run = subparsers.add_parser(
        "api-run", help="Plan or explicitly execute the O9 controlled API chain"
    )
    api_run.add_argument("--contract", required=True, type=_strict_path)
    api_run.add_argument("--repo-root", required=True, type=_strict_path)
    api_run.add_argument("--runtime-root", required=True, type=_strict_path)
    api_run.add_argument("--execute-api", action="store_true")
    api_run.add_argument("--execute-codex", action="store_true")
    api_run.add_argument("--execute-publish", action="store_true")
    return parser


def _api_run(args: argparse.Namespace) -> dict[str, object]:
    value = _read_object(args.contract)
    expected = {
        "prompt",
        "proposal_contract",
        "policy_decision",
        "codex",
        "github",
        "host",
    }
    if set(value) != expected:
        raise ValueError("api_run_contract_fields_invalid")
    prompt = value["prompt"]
    proposal_value = value["proposal_contract"]
    codex_value = value["codex"]
    github_value = value["github"]
    host_value = value["host"]
    if not isinstance(prompt, str) or not isinstance(proposal_value, dict):
        raise ValueError("api_run_contract_invalid")
    if not isinstance(codex_value, dict) or not isinstance(github_value, dict) or not isinstance(host_value, dict):
        raise ValueError("api_run_contract_invalid")
    proposal_fields = set(ProposalContract.__dataclass_fields__)
    if set(proposal_value) != proposal_fields:
        raise ValueError("proposal_contract_fields_invalid")
    proposal_contract = ProposalContract(
        **{
            **proposal_value,
            "write_allowlist": tuple(proposal_value["write_allowlist"]),
            "validation_commands": tuple(proposal_value["validation_commands"]),
        }
    )
    codex_expected = {
        "action_fingerprint",
        "help_output",
        "environment_allowlist",
        "timeout_seconds",
        "output_limit_bytes",
    }
    if set(codex_value) != codex_expected:
        raise ValueError("codex_contract_fields_invalid")
    github_expected = set(GitHubRestTemplate.__dataclass_fields__)
    if set(github_value) != github_expected:
        raise ValueError("github_contract_fields_invalid")
    codex_request = CodexChildRequest(
        action_fingerprint=str(codex_value["action_fingerprint"]),
        repo_root=args.repo_root,
        runtime_root=args.runtime_root,
        prompt="validated API proposal pending",
        help_output=str(codex_value["help_output"]),
        environment_allowlist=tuple(codex_value["environment_allowlist"]),
        timeout_seconds=int(codex_value["timeout_seconds"]),
        output_limit_bytes=int(codex_value["output_limit_bytes"]),
    )
    github_template = GitHubRestTemplate(**github_value)
    host_expected = {"branch", "expected_base_sha", "write_allowlist", "validation_argv", "commit_message"}
    if set(host_value) != host_expected:
        raise ValueError("host_contract_fields_invalid")
    validation_argv = host_value["validation_argv"]
    if not isinstance(validation_argv, list) or any(
        not isinstance(argv, list) or not all(isinstance(item, str) for item in argv)
        for argv in validation_argv
    ):
        raise ValueError("host_validation_argv_invalid")
    host_request = HostPublishRequest(
        repo_root=args.repo_root,
        branch=str(host_value["branch"]),
        expected_base_sha=str(host_value["expected_base_sha"]),
        write_allowlist=tuple(host_value["write_allowlist"]),
        validation_argv=tuple(tuple(argv) for argv in validation_argv),
        commit_message=str(host_value["commit_message"]),
        github=github_template,
    )
    if args.execute_api:
        openai = OpenAIResponsesClient.from_environment(os.environ)
    else:
        openai = OpenAIResponsesClient(None, os.environ.get("OPENAI_MODEL"))
    if args.execute_publish:
        github = GitHubRestClient.from_environment(os.environ)
    else:
        github = GitHubRestClient(None)
    return ApiAutomationEngine(
        openai_client=openai,
        codex_adapter=CodexChildAdapter(),
        github_client=github,
    ).run(
        prompt=prompt,
        proposal_contract=proposal_contract,
        policy_decision=_decision(value["policy_decision"]),
        codex_request=codex_request,
        host_publish_request=host_request,
        execute_api=args.execute_api,
        execute_codex=args.execute_codex,
        execute_publish=args.execute_publish,
    ).public_dict()


def main(argv: Sequence[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if args.command == "observe":
        try:
            observation = observe_repository(
                repo_root=args.repo_root,
                repository=args.repository,
                issue_number=args.issue,
                runtime_root=args.runtime_root,
            )
        except (OSError, RuntimeError, ValueError):
            observation = {
                "schema_version": 1,
                "state": "PREFLIGHT_BLOCKED",
                "blockers": [
                    {"code": "SOURCE_FAILURE", "reason": "observer_initialization_failed"}
                ],
                "exit_code": 11,
            }
        print(json.dumps(observation, ensure_ascii=False, indent=2, sort_keys=True))
        return int(observation.get("exit_code", 11))

    if args.command == "api-run":
        try:
            result = _api_run(args)
        except (
            OSError,
            ValueError,
            json.JSONDecodeError,
            ApiProposalError,
            OpenAIClientError,
            CodexAdapterError,
            GitHubRestError,
        ) as exc:
            result = {
                "schema_version": 1,
                "status": "BLOCKED",
                "reason": str(exc).split(":", 1)[0],
            }
        print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
        return 0 if result.get("status") in {"DRY_RUN", "API_COMPLETED", "CHILD_COMPLETED", "PUBLISHED"} else 12

    try:
        if args.command == "plan":
            request = _read_object(args.request)
            request.setdefault("mode", "dry_run")
            result = build_action_plan(
                _read_object(args.observation),
                _decision(_read_object(args.decision)),
                request,
            ).public_dict()
        elif args.command == "gate-plan":
            request = _read_object(args.request)
            request.setdefault("mode", "dry_run")
            builders = {
                "checkpoint": build_checkpoint_plan,
                "build": build_build_plan,
                "device": build_device_plan,
            }
            result = builders[args.gate](
                _read_object(args.observation),
                _decision(_read_object(args.decision)),
                request,
                _read_object(args.contract),
            ).public_dict()
        elif args.command == "publish-plan":
            request = _read_object(args.request)
            request.setdefault("mode", "dry_run")
            result = build_publish_plan(
                _read_object(args.observation),
                _decision(_read_object(args.decision)),
                request,
                _read_object(args.contract),
            ).public_dict()
        elif args.command == "execute":
            plan = ActionPlan.from_dict(_read_object(args.plan))
            store = RuntimeLedger(
                runtime_root=args.runtime_root,
                repo_root=args.repo_root,
                run_id=plan.run_id,
            )
            result = ControlledRunner(
                process_adapter=SubprocessProcessAdapter(plan.command_family),
                ledger=store,
            ).execute(
                plan,
                _decision(_read_object(args.decision)),
                execute=args.execute,
                current_source_fingerprint=args.source_fingerprint,
                current_action_fingerprint=args.action_fingerprint,
                environment=current_environment(plan),
            ).public_dict()
        elif args.command == "ledger-verify":
            verification = RuntimeLedger(
                runtime_root=args.runtime_root,
                repo_root=args.repo_root,
                run_id=args.run_id,
            ).verify()
            result = {
                "valid": verification.valid,
                "event_count": verification.event_count,
                "tail_hash": verification.tail_hash,
            }
        else:
            return 2
    except (
        OSError,
        ValueError,
        json.JSONDecodeError,
        PlanError,
        GatePlanError,
        PublishError,
        LedgerError,
        ExecutionError,
    ) as exc:
        result = {
            "schema_version": 1,
            "state": "BLOCKED",
            "reason": str(exc),
        }
        print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
        return 13
    print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
