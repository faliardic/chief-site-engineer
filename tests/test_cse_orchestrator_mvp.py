from __future__ import annotations

import json
from dataclasses import FrozenInstanceError
from pathlib import Path

import pytest

from tools.cse_orchestrator import PolicyDecision
from tools.cse_orchestrator import gates, github_adapter, ledger, planner, runner


SHA_A = "a" * 40
SHA_B = "b" * 40
SHA_C = "c" * 40
SOURCE = "sha256:" + "1" * 64
CONTRACT = "sha256:" + "2" * 64


def observation(repo_root: Path) -> dict[str, object]:
    return {
        "schema_version": 1,
        "run_id": "run-295",
        "repository": "faliardic/chief-site-engineer",
        "repo_root": str(repo_root.resolve()),
        "issue": 295,
        "state": "SCOPE_VALIDATED",
        "blockers": [],
        "exit_code": 0,
        "authorization": {
            "status": "valid",
            "comment_id": 5158213215,
            "approval_level": "FULL_VALIDATION",
            "capability": "Code",
            "action": "FULL_VALIDATION",
        },
        "git": {
            "branch": "codex/issue-295-cse-orchestrator-mvp",
            "head_sha": SHA_A,
            "parent_sha": SHA_B,
            "tree_sha": SHA_C,
            "local_master_sha": SHA_B,
            "origin_master_sha": SHA_B,
            "remote_master_sha": SHA_B,
            "staged": [],
            "tracked_worktree": [],
            "tracked_fingerprint": SOURCE,
        },
    }


def decision(
    *,
    action: str = "FULL_VALIDATION",
    capability: str = "Code",
    success_state: str = "FULL_PASS",
) -> PolicyDecision:
    return PolicyDecision(
        allowed=True,
        state_from=(
            "CODEX_AUTHORIZED"
            if action in {"CODE_CHANGE", "CORRECTION"}
            else "ACTION_AUTHORIZED"
        ),
        state_to=(
            "CODEX_RUNNING"
            if action in {"CODE_CHANGE", "CORRECTION"}
            else "ACTION_RUNNING"
        ),
        required_approval_level=action,
        budget_delta={
            {
                "FULL_VALIDATION": "full_gate_used",
                "CHECKPOINT_COMMIT": "checkpoint_commit_used",
                "BUILD": "build_used",
                "DEVICE": "device_used",
                "PUBLISH": "publish_used",
            }.get(action, "primary_used"): 1
        },
    )


def action_request(repo_root: Path, **overrides: object) -> dict[str, object]:
    value: dict[str, object] = {
        "schema_version": 1,
        "action_id": "action-full-validation",
        "pending_action": "FULL_VALIDATION",
        "mode": "dry_run",
        "cwd": str(repo_root.resolve()),
        "repository": "faliardic/chief-site-engineer",
        "branch": "codex/issue-295-cse-orchestrator-mvp",
        "base_sha": SHA_B,
        "head_sha": SHA_A,
        "tree_sha": SHA_C,
        "argv": ["python", "-m", "pytest"],
        "command_family": "pytest",
        "capability": "Code",
        "read_allowlist": ["tools/cse_orchestrator"],
        "write_allowlist": [],
        "action_allowlist": ["FULL_VALIDATION"],
        "environment_allowlist": ["PATH", "PYTHONUTF8"],
        "timeout_seconds": 300,
        "output_limit_bytes": 4096,
        "validation_plan": ["python -m pytest"],
        "source_fingerprint": SOURCE,
        "contract_fingerprint": CONTRACT,
        "required_approval_level": "FULL_VALIDATION",
        "expected_success_state": "FULL_PASS",
        "expected_failure_state": "FAILED",
        "provenance": {},
    }
    value.update(overrides)
    return value


def test_action_plan_is_byte_stable_frozen_and_bound_to_policy(tmp_path: Path) -> None:
    source = observation(tmp_path)
    request = action_request(tmp_path)

    first = planner.build_action_plan(source, decision(), request)
    second = planner.build_action_plan(source, decision(), request)

    assert planner.canonical_plan_json(first) == planner.canonical_plan_json(second)
    assert first.plan_sha256 == second.plan_sha256
    assert first.action_fingerprint.startswith("sha256:")
    assert first.approval_comment_id == 5158213215
    assert first.budget_delta == {"full_gate_used": 1}
    with pytest.raises(FrozenInstanceError):
        first.mode = "execute"  # type: ignore[misc]
    with pytest.raises(TypeError):
        first.budget_delta["full_gate_used"] = 2  # type: ignore[index]


@pytest.mark.parametrize(
    ("overrides", "match"),
    [
        ({"pending_action": "UNKNOWN"}, "unknown_action"),
        ({"argv": "python -m pytest"}, "argv_must_be_list"),
        ({"argv": ["python", "-m", "pytest", "tests/*"]}, "wildcard"),
        ({"cwd": "../outside"}, "cwd_outside_repository"),
        ({"source_fingerprint": ""}, "source_fingerprint"),
    ],
)
def test_planner_rejects_unknown_shell_wildcard_path_and_missing_fingerprint(
    tmp_path: Path, overrides: dict[str, object], match: str
) -> None:
    with pytest.raises(planner.PlanError, match=match):
        planner.build_action_plan(
            observation(tmp_path),
            decision(),
            action_request(tmp_path, **overrides),
        )


def test_planner_rejects_policy_deny_and_source_drift(tmp_path: Path) -> None:
    denied = PolicyDecision(
        allowed=False,
        state_from="ACTION_AUTHORIZED",
        state_to="BLOCKED",
        required_approval_level="FULL_VALIDATION",
        blockers=("PROVENANCE_MISMATCH",),
    )
    with pytest.raises(planner.PlanError, match="policy_denied"):
        planner.build_action_plan(
            observation(tmp_path), denied, action_request(tmp_path)
        )
    with pytest.raises(planner.PlanError, match="source_fingerprint_mismatch"):
        planner.build_action_plan(
            observation(tmp_path),
            decision(),
            action_request(tmp_path, source_fingerprint="sha256:" + "9" * 64),
        )


class FakeProcess:
    def __init__(self, result: dict[str, object]) -> None:
        self.result = result
        self.calls: list[dict[str, object]] = []
        self.ledger_path: Path | None = None

    def run(
        self,
        argv: tuple[str, ...],
        *,
        cwd: Path,
        environment: dict[str, str],
        timeout_seconds: int,
        output_limit_bytes: int,
    ) -> dict[str, object]:
        if self.ledger_path is not None:
            assert self.ledger_path.exists()
            assert "\"event_type\":\"admission\"" in self.ledger_path.read_text(
                encoding="utf-8"
            )
        self.calls.append(
            {
                "argv": argv,
                "cwd": cwd,
                "environment": environment,
                "timeout_seconds": timeout_seconds,
                "output_limit_bytes": output_limit_bytes,
            }
        )
        return dict(self.result)


def frozen_result(**overrides: object) -> dict[str, object]:
    value: dict[str, object] = {
        "schema_version": 1,
        "command_family": "pytest",
        "action_started": True,
        "wrapper_failed": False,
        "exit_code": 0,
        "duration_ms": 10,
        "stdout": "1 passed in 0.01s",
        "stderr": "",
        "truncated": False,
        "timed_out": False,
        "failed_stage": None,
    }
    value.update(overrides)
    return value


def execute_plan(tmp_path: Path) -> planner.ActionPlan:
    return planner.build_action_plan(
        observation(tmp_path),
        decision(),
        action_request(tmp_path, mode="execute"),
    )


def test_runner_records_admission_before_fake_execution_and_result(tmp_path: Path) -> None:
    plan = execute_plan(tmp_path)
    runtime_root = tmp_path.parent / f"runtime-{tmp_path.name}"
    store = ledger.RuntimeLedger(
        runtime_root=runtime_root,
        repo_root=tmp_path,
        run_id=plan.run_id,
    )
    fake = FakeProcess(frozen_result())
    fake.ledger_path = store.path
    controlled = runner.ControlledRunner(process_adapter=fake, ledger=store)

    result = controlled.execute(
        plan,
        decision(),
        execute=True,
        current_source_fingerprint=SOURCE,
        current_action_fingerprint=plan.action_fingerprint,
        environment={"PATH": "safe", "UNAPPROVED": "drop"},
    )

    assert result.success is True
    assert result.state == "FULL_PASS"
    assert result.parsed_result.budget_consumed is True
    assert fake.calls[0]["environment"] == {"PATH": "safe"}
    events = store.verify().events
    assert [event["event_type"] for event in events] == ["admission", "result"]
    admission = events[0]["payload"]
    assert admission["approval_consumed"] is True
    assert admission["budget_delta"] == {"full_gate_used": 1}
    assert admission["invocation_start"]["adapter"] == "FakeProcess"


def test_runner_fails_closed_on_duplicate_tamper_drift_and_implicit_execute(
    tmp_path: Path,
) -> None:
    plan = execute_plan(tmp_path)
    store = ledger.RuntimeLedger(
        runtime_root=tmp_path.parent / f"runtime-{tmp_path.name}",
        repo_root=tmp_path,
        run_id=plan.run_id,
    )
    fake = FakeProcess(frozen_result())
    controlled = runner.ControlledRunner(process_adapter=fake, ledger=store)
    with pytest.raises(runner.ExecutionError, match="explicit_execute_required"):
        controlled.execute(
            plan,
            decision(),
            execute=False,
            current_source_fingerprint=SOURCE,
            current_action_fingerprint=plan.action_fingerprint,
        )
    controlled.execute(
        plan,
        decision(),
        execute=True,
        current_source_fingerprint=SOURCE,
        current_action_fingerprint=plan.action_fingerprint,
    )
    with pytest.raises(ledger.LedgerError, match="duplicate_action"):
        controlled.execute(
            plan,
            decision(),
            execute=True,
            current_source_fingerprint=SOURCE,
            current_action_fingerprint=plan.action_fingerprint,
        )
    text = store.path.read_text(encoding="utf-8")
    store.path.write_text(text.replace("FULL_PASS", "FAILED", 1), encoding="utf-8")
    with pytest.raises(ledger.LedgerError, match="hash_mismatch"):
        store.verify()


@pytest.mark.parametrize(
    ("raw", "failure", "consumed"),
    [
        (
            frozen_result(
                action_started=False,
                wrapper_failed=True,
                exit_code=None,
                stdout="",
                failed_stage="adapter",
            ),
            "harness",
            False,
        ),
        (
            frozen_result(exit_code=None, timed_out=True, stdout=""),
            "timeout",
            True,
        ),
        (
            frozen_result(exit_code=1, stdout="1 failed in 0.01s"),
            "test",
            True,
        ),
    ],
)
def test_runner_freezes_failure_classes_and_budget_consumption(
    tmp_path: Path, raw: dict[str, object], failure: str, consumed: bool
) -> None:
    plan = execute_plan(tmp_path)
    store = ledger.RuntimeLedger(
        runtime_root=tmp_path.parent / f"runtime-{tmp_path.name}",
        repo_root=tmp_path,
        run_id=plan.run_id,
    )
    result = runner.ControlledRunner(
        process_adapter=FakeProcess(raw), ledger=store
    ).execute(
        plan,
        decision(),
        execute=True,
        current_source_fingerprint=SOURCE,
        current_action_fingerprint=plan.action_fingerprint,
    )
    assert result.success is False
    assert result.parsed_result.failure_class == failure
    assert result.parsed_result.budget_consumed is consumed


def test_runtime_ledger_must_be_outside_repository(tmp_path: Path) -> None:
    with pytest.raises(ledger.LedgerError, match="runtime_root_inside_repository"):
        ledger.RuntimeLedger(
            runtime_root=tmp_path / "runtime",
            repo_root=tmp_path,
            run_id="run-295",
        )


def gate_request(
    tmp_path: Path, action: str, capability: str, family: str, argv: list[str]
) -> dict[str, object]:
    success = {
        "CHECKPOINT_COMMIT": "CHECKPOINT_COMMITTED",
        "BUILD": "ARTIFACT_BUILT",
        "DEVICE": "DEVICE_ACCEPTANCE",
    }[action]
    return action_request(
        tmp_path,
        action_id=f"action-{action.lower()}",
        pending_action=action,
        argv=argv,
        command_family=family,
        capability=capability,
        action_allowlist=[action],
        required_approval_level=action,
        expected_success_state=success,
    )


def test_checkpoint_build_and_device_are_distinct_provenance_bound_gate_plans(
    tmp_path: Path,
) -> None:
    obs = observation(tmp_path)
    checkpoint_request = gate_request(
        tmp_path,
        "CHECKPOINT_COMMIT",
        "Code",
        "generic_command",
        ["git", "commit", "-m", "Checkpoint"],
    )
    checkpoint = gates.build_checkpoint_plan(
        obs,
        decision(action="CHECKPOINT_COMMIT", success_state="CHECKPOINT_COMMITTED"),
        checkpoint_request,
        {
            "branch": checkpoint_request["branch"],
            "head_sha": SHA_A,
            "tree_sha": SHA_C,
            "source_manifest_fingerprint": SOURCE,
            "staged_allowlist": ["tools/cse_orchestrator/planner.py"],
            "parent_sha": SHA_B,
            "base_sha": SHA_B,
            "expected_head_sha": "d" * 40,
            "expected_tree_sha": "e" * 40,
            "commit_budget": 1,
        },
    )
    build = gates.build_build_plan(
        obs,
        decision(action="BUILD", success_state="ARTIFACT_BUILT"),
        gate_request(tmp_path, "BUILD", "Code", "build", ["python", "build.py"]),
        {
            "checkpoint_sha": SHA_A,
            "checkpoint_tree_sha": SHA_C,
            "output_path": "dist/app.bin",
            "artifact_contract": {
                "sha256": "sha256:" + "3" * 64,
                "package": "cse.app",
                "version": "1.0.0",
                "signer": "release",
            },
            "build_budget": 1,
        },
    )
    device = gates.build_device_plan(
        obs,
        decision(
            action="DEVICE", capability="Device", success_state="DEVICE_ACCEPTANCE"
        ),
        gate_request(
            tmp_path, "DEVICE", "Device", "generic_command", ["adb", "install", "app.apk"]
        ),
        {
            "artifact_sha256": "sha256:" + "3" * 64,
            "device_target": "tablet_primary",
            "adb_argv": ["adb", "install", "app.apk"],
            "retry_budget": 1,
        },
    )
    assert checkpoint.provenance["gate"] == "CHECKPOINT_COMMIT"
    assert "git diff --cached --check" in checkpoint.validation_plan
    assert build.provenance["gate"] == "BUILD"
    assert device.provenance["device_target"] == "tablet_primary"
    assert len({checkpoint.action_fingerprint, build.action_fingerprint, device.action_fingerprint}) == 3


@pytest.mark.parametrize(
    "argv",
    [
        ["adb", "-s", "R58M123456", "install", "app.apk"],
        ["adb", "uninstall", "cse.app"],
        ["adb", "shell", "pm", "clear", "cse.app"],
    ],
)
def test_device_gate_rejects_serial_and_destructive_actions(
    tmp_path: Path, argv: list[str]
) -> None:
    request = gate_request(tmp_path, "DEVICE", "Device", "generic_command", argv)
    with pytest.raises(gates.GatePlanError):
        gates.build_device_plan(
            observation(tmp_path),
            decision(
                action="DEVICE", capability="Device", success_state="DEVICE_ACCEPTANCE"
            ),
            request,
            {
                "artifact_sha256": "sha256:" + "3" * 64,
                "device_target": "tablet_primary",
                "adb_argv": argv,
                "retry_budget": 1,
            },
        )


def publish_request(tmp_path: Path, argv: list[str] | None = None) -> dict[str, object]:
    return action_request(
        tmp_path,
        action_id="action-publish",
        pending_action="PUBLISH",
        argv=argv
        or [
            "git",
            "push",
            "origin",
            "codex/issue-295-cse-orchestrator-mvp",
        ],
        command_family="generic_command",
        capability="Publish",
        action_allowlist=["PUBLISH"],
        required_approval_level="PUBLISH",
        expected_success_state="COMPLETED",
    )


def publish_contract(**overrides: object) -> dict[str, object]:
    value: dict[str, object] = {
        "branch": "codex/issue-295-cse-orchestrator-mvp",
        "head_sha": SHA_A,
        "base_branch": "master",
        "base_sha": SHA_B,
        "remote_divergence": [0, 0],
        "related_issue": 295,
        "title": "Complete CSE orchestrator MVP execution pipeline",
        "body": "Closes #295\n\nData-minimal evidence.",
        "draft": True,
        "existing_pr": False,
    }
    value.update(overrides)
    return value


class FakeGitHub:
    def __init__(self, existing: int | None = None) -> None:
        self.existing = existing
        self.created: list[dict[str, object]] = []

    def find_open_pull_request(self, *, branch: str, base_branch: str) -> int | None:
        return self.existing

    def create_draft_pull_request(self, payload: dict[str, object]) -> dict[str, object]:
        self.created.append(dict(payload))
        return {"number": 296, "state": "open", "draft": True}


def test_publish_plan_and_fake_adapter_allow_one_normal_push_and_draft_pr(
    tmp_path: Path,
) -> None:
    publish_decision = decision(
        action="PUBLISH", capability="Publish", success_state="COMPLETED"
    )
    request = publish_request(tmp_path)
    request["mode"] = "execute"
    plan = github_adapter.build_publish_plan(
        observation(tmp_path), publish_decision, request, publish_contract()
    )
    store = ledger.RuntimeLedger(
        runtime_root=tmp_path.parent / f"runtime-{tmp_path.name}",
        repo_root=tmp_path,
        run_id=plan.run_id,
    )
    process = FakeProcess(frozen_result(command_family="generic_command", stdout="pushed"))
    client = FakeGitHub()
    result = github_adapter.execute_publish(
        plan,
        runner.ControlledRunner(process_adapter=process, ledger=store),
        client,
        publish_decision,
        execute=True,
        current_source_fingerprint=SOURCE,
        current_action_fingerprint=plan.action_fingerprint,
    )
    assert result.pull_request == {"number": 296, "state": "open", "draft": True}
    assert process.calls[0]["argv"] == (
        "git",
        "push",
        "origin",
        "codex/issue-295-cse-orchestrator-mvp",
    )
    assert client.created[0]["body"].startswith("Closes #295")
    assert client.created[0]["draft"] is True


@pytest.mark.parametrize(
    ("request_argv", "contract_overrides"),
    [
        (["git", "push", "--force", "origin", "branch"], {}),
        (None, {"draft": False}),
        (None, {"base_branch": "develop"}),
        (None, {"body": "Related to #295"}),
        (None, {"remote_divergence": [1, 0]}),
    ],
)
def test_publish_plan_rejects_force_ready_wrong_base_body_and_divergence(
    tmp_path: Path,
    request_argv: list[str] | None,
    contract_overrides: dict[str, object],
) -> None:
    with pytest.raises(github_adapter.PublishError):
        github_adapter.build_publish_plan(
            observation(tmp_path),
            decision(action="PUBLISH", capability="Publish", success_state="COMPLETED"),
            publish_request(tmp_path, request_argv),
            publish_contract(**contract_overrides),
        )


def test_duplicate_pr_is_rejected_before_push(tmp_path: Path) -> None:
    publish_decision = decision(
        action="PUBLISH", capability="Publish", success_state="COMPLETED"
    )
    plan = github_adapter.build_publish_plan(
        observation(tmp_path), publish_decision, publish_request(tmp_path), publish_contract()
    )
    store = ledger.RuntimeLedger(
        runtime_root=tmp_path.parent / f"runtime-{tmp_path.name}",
        repo_root=tmp_path,
        run_id=plan.run_id,
    )
    process = FakeProcess(frozen_result(command_family="generic_command"))
    with pytest.raises(github_adapter.PublishError, match="duplicate_pr"):
        github_adapter.execute_publish(
            plan,
            runner.ControlledRunner(process_adapter=process, ledger=store),
            FakeGitHub(existing=286),
            publish_decision,
            execute=True,
            current_source_fingerprint=SOURCE,
            current_action_fingerprint=plan.action_fingerprint,
        )
    assert process.calls == []


@pytest.mark.parametrize("action", ["READY", "MERGE", "ISSUE_CLOSE", "BRANCH_DELETE", "RELEASE"])
def test_publish_adapter_rejects_out_of_scope_actions(tmp_path: Path, action: str) -> None:
    request = publish_request(tmp_path)
    request["action_allowlist"] = [action]
    with pytest.raises((planner.PlanError, github_adapter.PublishError)):
        github_adapter.build_publish_plan(
            observation(tmp_path),
            decision(action="PUBLISH", capability="Publish", success_state="COMPLETED"),
            request,
            publish_contract(),
        )


def test_cli_defaults_to_dry_run_and_requires_explicit_execute(tmp_path: Path) -> None:
    dry = planner.build_action_plan(
        observation(tmp_path), decision(), action_request(tmp_path)
    )
    assert dry.mode == "dry_run"
    assert json.loads(planner.canonical_plan_json(dry))["mode"] == "dry_run"
    execute = execute_plan(tmp_path)
    store = ledger.RuntimeLedger(
        runtime_root=tmp_path.parent / f"runtime-{tmp_path.name}",
        repo_root=tmp_path,
        run_id=execute.run_id,
    )
    with pytest.raises(runner.ExecutionError, match="explicit_execute_required"):
        runner.ControlledRunner(
            process_adapter=FakeProcess(frozen_result()), ledger=store
        ).execute(
            execute,
            decision(),
            execute=False,
            current_source_fingerprint=SOURCE,
            current_action_fingerprint=execute.action_fingerprint,
        )
