from __future__ import annotations

import hashlib
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

import pytest

from tools.cse_orchestrator import cli
from tools.cse_orchestrator import workflow as workflow_module
from tools.cse_orchestrator.workflow import (
    CommandDiagnostic,
    DefaultStageExecutor,
    GhIssueEvidenceSink,
    NullEvidenceSink,
    StageExecution,
    WorkflowCoordinator,
    WorkflowError,
    observe_target,
)
from tools.cse_orchestrator.workflow_authorization import (
    WORKFLOW_AUTHORIZATION_MARKER,
    WorkflowAuthorizationError,
    canonical_json_bytes,
    parse_workflow_authorization,
    parse_workflow_authorization_comment,
    select_latest_workflow_authorization,
)
from tools.cse_orchestrator.workflow_store import (
    WorkflowContract,
    WorkflowStore,
    WorkflowStoreError,
)
from tools.cse_orchestrator.observer import GitHubClientError
from tools.cse_orchestrator.device_smoke import (
    AdapterActionResult,
    DeviceSmokeError,
    ISSUE_284_DEBUG_PACKAGE,
    ISSUE_284_SMOKE_ACTIONS,
    ISSUE_284_TABLET_MODEL,
    ISSUE_284_TABLET_SERIAL,
)


HASH = "sha256:" + "a" * 64


def run_git(root: Path, *argv: str) -> str:
    completed = subprocess.run(
        ["git", *argv],
        cwd=root,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        shell=False,
        check=False,
        timeout=30,
    )
    assert completed.returncode == 0, completed.stderr
    return completed.stdout.strip()


def git_repository(root: Path, branch: str) -> tuple[str, str]:
    root.mkdir(parents=True)
    subprocess.run(
        ["git", "init", "-b", branch, str(root)],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        shell=False,
        check=True,
        timeout=30,
    )
    run_git(root, "config", "user.name", "CSE Test")
    run_git(root, "config", "user.email", "cse-test@example.invalid")
    (root / "work.txt").write_text("base\n", encoding="utf-8")
    run_git(root, "add", "work.txt")
    run_git(root, "commit", "-m", "base")
    return run_git(root, "rev-parse", "HEAD"), run_git(
        root, "rev-parse", "HEAD^{tree}"
    )


def roots(tmp_path: Path) -> tuple[Path, Path, Path, str, str, str]:
    controller = tmp_path / "controller"
    target = tmp_path / "target"
    runtime = tmp_path / "runtime"
    controller_head, _ = git_repository(controller, "controller")
    target_head, target_tree = git_repository(target, "codex/test-workflow")
    return controller, target, runtime, controller_head, target_head, target_tree


def command_stage(
    name: str,
    *,
    failure_class: str = "unsafe",
    retry_max: int = 0,
    reusable: bool = True,
) -> dict[str, object]:
    return {
        "name": name,
        "kind": "command",
        "capability": "Code",
        "command_family": "python",
        "argv": [sys.executable, "-c", "raise SystemExit(0)"],
        "cwd": "target",
        "timeout_seconds": 30,
        "output_limit_bytes": 65536,
        "retry_max": retry_max,
        "reusable": reusable,
        "failure_class": failure_class,
        "environment_allowlist": [],
    }


def authorization_value(
    controller_head: str,
    target_head: str,
    target_tree: str,
    stages: list[dict[str, object]],
    *,
    comment_id: int = 1001,
    artifact: dict[str, object] | None = None,
    device: dict[str, object] | None = None,
    publish: dict[str, object] | None = None,
    reused_evidence: list[dict[str, object]] | None = None,
    execution: bool = True,
) -> dict[str, object]:
    retries = sum(int(item["retry_max"]) for item in stages)
    return {
        "schema_version": 1,
        "repository": "owner/repository",
        "issue": 303,
        "comment_id": comment_id,
        "scope_version": 1,
        "controller_revision": controller_head,
        "target": {
            "branch": "codex/test-workflow",
            "base_sha": target_head,
            "head_sha": target_head,
            "tree_sha": target_tree,
        },
        "read_allowlist": ["work.txt"],
        "write_allowlist": ["work.txt"],
        "capability_sequence": [item["capability"] for item in stages],
        "stages": stages,
        "reused_evidence": reused_evidence or [],
        "budgets": {
            "primary_max": 1,
            "correction_max": retries,
            "command_max": len(stages) + retries + 4,
            "commit_max": 1,
            "push_max": 1,
            "draft_pr_max": 1,
            "github_comment_max": 100,
            "hard_stop_seconds": 600,
        },
        "artifact": artifact,
        "device": device,
        "publish": publish,
        "execution": execution,
        "expires_at": "2099-01-01T00:00:00Z",
        "nonce": f"workflow-{comment_id}",
        "supersedes_comment_id": None,
    }


def parsed_authorization(
    controller_head: str,
    target_head: str,
    target_tree: str,
    stages: list[dict[str, object]],
    **kwargs,
):
    return parse_workflow_authorization(
        authorization_value(
            controller_head, target_head, target_tree, stages, **kwargs
        ),
        now=datetime(2026, 8, 2, tzinfo=timezone.utc),
    )


def pass_result(*, details: dict[str, object] | None = None, reused: bool = False):
    return StageExecution(True, "unsafe", None, None, (), details or {}, reused)


def failure_result(classification: str, reason: str = "bounded_failure"):
    diagnostic = CommandDiagnostic(
        "gate",
        "python",
        HASH,
        1,
        True,
        1,
        4,
        False,
        False,
        HASH,
        HASH,
        reason,
        "command_exit_zero",
    )
    return StageExecution(
        False,
        classification,
        reason,
        "command_exit_zero",
        (diagnostic,),
        {},
    )


class ScriptedExecutor:
    def __init__(self, scripts: dict[str, list[StageExecution]] | None = None):
        self.scripts = scripts or {}
        self.calls: list[str] = []

    def execute(self, stage, authorization, *, controller_root, target_root):
        self.calls.append(stage.name)
        values = self.scripts.get(stage.name)
        return values.pop(0) if values else pass_result()


class RecordingSink:
    def __init__(self, fail_key: str | None = None):
        self.fail_key = fail_key
        self.calls: list[str] = []

    def emit(self, *, workflow_id, evidence_key, payload):
        self.calls.append(evidence_key)
        if evidence_key == self.fail_key:
            self.fail_key = None
            raise WorkflowError("simulated_process_crash")
        return {"reused": False, "comment_id": len(self.calls)}


def coordinator(
    authorization,
    controller: Path,
    target: Path,
    runtime: Path,
    executor=None,
    sink=None,
):
    workflow_module.CONTROLLER_SOURCE_ROOT = controller.resolve()
    return WorkflowCoordinator(
        authorization=authorization,
        controller_root=controller,
        target_root=target,
        runtime_root=runtime,
        executor=executor,
        evidence_sink=sink or RecordingSink(),
    )


def test_authorization_comment_is_exact_and_latest_supersession_is_deterministic(
    tmp_path,
):
    controller, target, _, controller_head, target_head, target_tree = roots(tmp_path)
    del controller, target
    first = authorization_value(
        controller_head, target_head, target_tree, [command_stage("gate_a")]
    )
    body = f"{WORKFLOW_AUTHORIZATION_MARKER}\n```json\n{json.dumps(first)}\n```"
    parsed = parse_workflow_authorization_comment(
        {"id": 1001, "body": body},
        now=datetime(2026, 8, 2, tzinfo=timezone.utc),
    )
    assert parsed.comment_id == 1001

    second = authorization_value(
        controller_head,
        target_head,
        target_tree,
        [command_stage("gate_a")],
        comment_id=1002,
    )
    second["supersedes_comment_id"] = 1001
    selection = select_latest_workflow_authorization(
        [
            {"id": 1001, "body": body},
            {
                "id": 1002,
                "body": (
                    f"{WORKFLOW_AUTHORIZATION_MARKER}\n```json\n"
                    f"{json.dumps(second)}\n```"
                ),
            },
        ],
        now=datetime(2026, 8, 2, tzinfo=timezone.utc),
    )
    assert selection.status == "valid"
    assert selection.comment_id == 1002


@pytest.mark.parametrize(
    ("mutation", "reason"),
    [
        (lambda value: value.update({"unknown": True}), "unknown_workflow"),
        (
            lambda value: value.update({"nonce": "token=ghp_not_allowed_value"}),
            "invalid_string",
        ),
        (
            lambda value: value.update({"controller_revision": "0" * 39}),
            "invalid_sha",
        ),
    ],
)
def test_authorization_malformed_scope_and_secret_fail_closed(tmp_path, mutation, reason):
    _, _, _, controller_head, target_head, target_tree = roots(tmp_path)
    value = authorization_value(
        controller_head, target_head, target_tree, [command_stage("gate_a")]
    )
    mutation(value)
    with pytest.raises(WorkflowAuthorizationError, match=reason):
        parse_workflow_authorization(
            value, now=datetime(2026, 8, 2, tzinfo=timezone.utc)
        )


def test_device_authorization_requires_exact_serial_and_blocks_destructive_argv(
    tmp_path,
):
    _, _, _, controller_head, target_head, target_tree = roots(tmp_path)
    artifact = {
        "path": "artifact.apk",
        "sha256": HASH,
        "package": "example.package",
        "version": "1",
        "signer": HASH,
        "checkpoint_sha": target_head,
    }
    device = {"serial": "TABLET1", "model": "SM-X610", "package": "example.package"}
    stage = command_stage("device_gate")
    stage.update(
        {
            "capability": "Device",
            "command_family": "adb",
            "argv": ["adb", "-s", "TABLET1", "uninstall", "example.package"],
        }
    )
    value = authorization_value(
        controller_head,
        target_head,
        target_tree,
        [stage],
        artifact=artifact,
        device=device,
    )
    with pytest.raises(WorkflowAuthorizationError, match="forbidden_operation"):
        parse_workflow_authorization(
            value, now=datetime(2026, 8, 2, tzinfo=timezone.utc)
        )


def test_same_process_progression_and_bounded_resumable_retry(tmp_path):
    controller, target, runtime, controller_head, target_head, target_tree = roots(
        tmp_path
    )
    auth = parsed_authorization(
        controller_head,
        target_head,
        target_tree,
        [
            command_stage("gate_a"),
            command_stage("gate_b", failure_class="resumable", retry_max=1),
            command_stage("gate_c"),
        ],
    )
    executor = ScriptedExecutor(
        {"gate_b": [failure_result("resumable"), pass_result()]}
    )
    result = coordinator(auth, controller, target, runtime, executor).run(execute=True)
    assert result["status"] == "COMPLETED"
    assert executor.calls == ["gate_a", "gate_b", "gate_b", "gate_c"]
    assert result["stage_attempts"] == {"gate_a": 1, "gate_b": 2, "gate_c": 1}
    assert len(result["admitted_attempt_ids"]) == len(
        set(result["admitted_attempt_ids"])
    )


@pytest.mark.parametrize("crash_after", ["gate_a", "gate_b", "gate_c"])
def test_crash_restart_resumes_after_every_gate_without_reexecution(
    tmp_path, crash_after
):
    controller, target, runtime, controller_head, target_head, target_tree = roots(
        tmp_path
    )
    auth = parsed_authorization(
        controller_head,
        target_head,
        target_tree,
        [command_stage("gate_a"), command_stage("gate_b"), command_stage("gate_c")],
    )
    first = ScriptedExecutor()
    with pytest.raises(WorkflowError, match="simulated_process_crash"):
        coordinator(
            auth,
            controller,
            target,
            runtime,
            first,
            RecordingSink(f"gate_pass_{crash_after}"),
        ).run(execute=True)
    second = ScriptedExecutor()
    result = coordinator(
        auth, controller, target, runtime, second, RecordingSink()
    ).run(execute=True)
    assert result["status"] == "COMPLETED"
    crash_index = ["gate_a", "gate_b", "gate_c"].index(crash_after)
    assert first.calls == ["gate_a", "gate_b", "gate_c"][: crash_index + 1]
    assert second.calls == ["gate_a", "gate_b", "gate_c"][crash_index + 1 :]


def test_stale_or_missing_projection_recovers_from_authoritative_ledger(tmp_path):
    controller, target, runtime, controller_head, target_head, target_tree = roots(
        tmp_path
    )
    auth = parsed_authorization(
        controller_head, target_head, target_tree, [command_stage("gate_a")]
    )
    flow = coordinator(auth, controller, target, runtime, ScriptedExecutor())
    assert flow.run(execute=True)["status"] == "COMPLETED"
    flow.store.projection_path.unlink()
    with pytest.raises(WorkflowStoreError, match="projection_missing"):
        flow.store.verify()
    assert coordinator(
        auth, controller, target, runtime, ScriptedExecutor()
    ).run(execute=True)["status"] == "COMPLETED"
    assert flow.store.verify().valid is True


def test_invalid_event_is_rejected_before_append_and_does_not_corrupt_ledger(
    tmp_path,
):
    controller, target, runtime, controller_head, target_head, target_tree = roots(
        tmp_path
    )
    auth = parsed_authorization(
        controller_head, target_head, target_tree, [command_stage("gate_a")]
    )
    contract = WorkflowContract.from_authorization(auth)
    store = WorkflowStore(
        runtime_root=runtime,
        repo_root=target,
        workflow_id=contract.workflow_id,
    )
    started = store.start(contract)
    assert started.event_count == 1
    with pytest.raises(WorkflowStoreError, match="stage_result_without_admission"):
        store.append(
            "stage_passed",
            {
                "stage_index": 0,
                "stage": "gate_a",
                "evidence": {"evidence_fingerprint": HASH},
                "details": {},
            },
        )
    verified = store.verify()
    assert verified.projection.event_count == 1
    assert len(verified.events) == 1


def test_external_device_pause_preserves_artifact_and_resume_skips_build(
    tmp_path, monkeypatch
):
    controller, target, runtime, controller_head, target_head, target_tree = roots(
        tmp_path
    )
    artifact_path = tmp_path / "artifact.apk"
    artifact_path.write_bytes(b"bounded-apk")
    digest = "sha256:" + hashlib.sha256(b"bounded-apk").hexdigest()
    artifact = {
        "path": str(artifact_path),
        "sha256": digest,
        "package": "example.package",
        "version": "1",
        "signer": HASH,
        "checkpoint_sha": target_head,
    }
    device = {"serial": "TABLET1", "model": "SM-X610", "package": "example.package"}
    build = command_stage("build_artifact")
    device_stage = command_stage("device_preflight", failure_class="external")
    device_stage.update(
        {
            "capability": "Device",
            "command_family": "adb",
            "argv": ["adb", "-s", "TABLET1", "get-state"],
        }
    )
    auth = parsed_authorization(
        controller_head,
        target_head,
        target_tree,
        [build, device_stage],
        artifact=artifact,
        device=device,
    )
    monkeypatch.setattr(workflow_module, "_tool_fingerprint", lambda stage: HASH)
    first = ScriptedExecutor(
        {
            "build_artifact": [pass_result(details={"artifact": artifact})],
            "device_preflight": [failure_result("external", "device_not_connected")],
        }
    )
    paused = coordinator(auth, controller, target, runtime, first).run(execute=True)
    assert paused["status"] == "PAUSED_EXTERNAL"
    assert paused["artifact"]["sha256"] == digest
    second = ScriptedExecutor()
    completed = coordinator(auth, controller, target, runtime, second).run(execute=True)
    assert completed["status"] == "COMPLETED"
    assert first.calls == ["build_artifact", "device_preflight"]
    assert second.calls == ["device_preflight"]


def test_artifact_tamper_blocks_resume_without_build_retry(tmp_path, monkeypatch):
    controller, target, runtime, controller_head, target_head, target_tree = roots(
        tmp_path
    )
    artifact_path = tmp_path / "artifact.apk"
    artifact_path.write_bytes(b"original")
    digest = "sha256:" + hashlib.sha256(b"original").hexdigest()
    artifact = {
        "path": str(artifact_path),
        "sha256": digest,
        "package": "example.package",
        "version": "1",
        "signer": HASH,
        "checkpoint_sha": target_head,
    }
    device = {"serial": "TABLET1", "model": "SM-X610", "package": "example.package"}
    build = command_stage("build_artifact")
    device_stage = command_stage("device_preflight", failure_class="external")
    device_stage.update(
        {"capability": "Device", "command_family": "adb", "argv": ["adb", "-s", "TABLET1", "get-state"]}
    )
    auth = parsed_authorization(
        controller_head,
        target_head,
        target_tree,
        [build, device_stage],
        artifact=artifact,
        device=device,
    )
    monkeypatch.setattr(workflow_module, "_tool_fingerprint", lambda stage: HASH)
    first = ScriptedExecutor(
        {
            "build_artifact": [pass_result(details={"artifact": artifact})],
            "device_preflight": [failure_result("external", "device_not_connected")],
        }
    )
    assert coordinator(auth, controller, target, runtime, first).run(execute=True)[
        "status"
    ] == "PAUSED_EXTERNAL"
    artifact_path.write_bytes(b"tampered")
    second = ScriptedExecutor()
    with pytest.raises(WorkflowError, match="projected_artifact_hash_mismatch"):
        coordinator(auth, controller, target, runtime, second).run(execute=True)
    assert second.calls == []


def evidence_fingerprint(value: dict[str, object]) -> str:
    return "sha256:" + hashlib.sha256(canonical_json_bytes(value)).hexdigest()


def test_exact_fingerprint_pass_evidence_is_reused_without_action_admission(tmp_path):
    controller, target, runtime, controller_head, target_head, target_tree = roots(
        tmp_path
    )
    stage = command_stage("gate_a")
    base = parsed_authorization(controller_head, target_head, target_tree, [stage])
    observation = observe_target(target)
    reusable = {
        "stage": "gate_a",
        "source_fingerprint": observation.source_fingerprint,
        "tool_fingerprint": workflow_module._tool_fingerprint(base.stages[0]),
        "command_fingerprint": workflow_module._command_fingerprint(base.stages[0]),
        "artifact_fingerprint": None,
    }
    reusable["evidence_fingerprint"] = evidence_fingerprint(reusable)
    auth = parsed_authorization(
        controller_head,
        target_head,
        target_tree,
        [stage],
        comment_id=1002,
        reused_evidence=[reusable],
    )
    executor = ScriptedExecutor()
    result = coordinator(auth, controller, target, runtime, executor).run(execute=True)
    assert result["status"] == "COMPLETED"
    assert executor.calls == []
    assert result["stage_attempts"] == {}


def publish_contract() -> dict[str, object]:
    return {
        "base_branch": "master",
        "title": "Complete resumable CSE orchestrator workflow",
        "body_first_line": "Related to #303",
        "commit_message": "Complete resumable CSE orchestrator workflow",
    }


def non_command_stage(name: str, kind: str) -> dict[str, object]:
    return {
        "name": name,
        "kind": kind,
        "capability": "Publish",
        "command_family": kind,
        "argv": [],
        "cwd": "target",
        "timeout_seconds": 30,
        "output_limit_bytes": 65536,
        "retry_max": 0,
        "reusable": False,
        "failure_class": "unsafe",
        "environment_allowlist": [],
    }


def test_commit_and_push_are_duplicate_safe(tmp_path):
    controller, target, _, controller_head, target_head, target_tree = roots(tmp_path)
    del controller
    bare = tmp_path / "remote.git"
    subprocess.run(
        ["git", "init", "--bare", str(bare)],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=True,
        timeout=30,
    )
    run_git(target, "remote", "add", "origin", str(bare))
    (target / "work.txt").write_text("authorized change\n", encoding="utf-8")
    auth = parsed_authorization(
        controller_head,
        target_head,
        target_tree,
        [non_command_stage("commit_gate", "commit")],
        publish=publish_contract(),
    )
    executor = DefaultStageExecutor()
    first_commit = executor.execute(
        auth.stages[0], auth, controller_root=target, target_root=target
    )
    second_commit = executor.execute(
        auth.stages[0], auth, controller_root=target, target_root=target
    )
    assert first_commit.success is True and first_commit.reused is False
    assert second_commit.success is True and second_commit.reused is True

    push_value = authorization_value(
        controller_head,
        target_head,
        target_tree,
        [non_command_stage("push_gate", "push")],
        publish=publish_contract(),
    )
    push_auth = parse_workflow_authorization(
        push_value, now=datetime(2026, 8, 2, tzinfo=timezone.utc)
    )
    first_push = executor.execute(
        push_auth.stages[0], push_auth, controller_root=target, target_root=target
    )
    second_push = executor.execute(
        push_auth.stages[0], push_auth, controller_root=target, target_root=target
    )
    assert first_push.success is True and first_push.reused is False
    assert second_push.success is True and second_push.reused is True


class FakePrExecutor(DefaultStageExecutor):
    def __init__(self, responses: list[bytes]):
        self.responses = responses
        self.argv: list[tuple[str, ...]] = []

    def _command(self, stage, argv, cwd, index, environment=None):
        self.argv.append(argv)
        output = self.responses.pop(0)
        return (
            CommandDiagnostic(
                stage.name,
                stage.command_family,
                HASH,
                index,
                True,
                0,
                1,
                False,
                False,
                HASH,
                HASH,
                None,
                None,
            ),
            output,
        )


def test_draft_pr_is_created_once_and_then_reused(tmp_path):
    controller, target, _, controller_head, target_head, target_tree = roots(tmp_path)
    del controller
    auth = parsed_authorization(
        controller_head,
        target_head,
        target_tree,
        [non_command_stage("draft_pr_gate", "draft_pr")],
        publish=publish_contract(),
    )
    pr = {
        "number": 304,
        "isDraft": True,
        "state": "OPEN",
        "url": "https://example.invalid/pr/304",
        "title": publish_contract()["title"],
    }
    creator = FakePrExecutor([b"[]", b"", json.dumps([pr]).encode()])
    created = creator.execute(
        auth.stages[0], auth, controller_root=target, target_root=target
    )
    reuser = FakePrExecutor([json.dumps([pr]).encode()])
    reused = reuser.execute(
        auth.stages[0], auth, controller_root=target, target_root=target
    )
    assert created.success is True and created.reused is False
    assert reused.success is True and reused.reused is True
    assert sum(argv[:3] == ("gh", "pr", "create") for argv in creator.argv) == 1
    assert all(argv[:3] != ("gh", "pr", "create") for argv in reuser.argv)


def test_ledger_projection_and_manifest_tamper_fail_closed(tmp_path):
    controller, target, runtime, controller_head, target_head, target_tree = roots(
        tmp_path
    )
    auth = parsed_authorization(
        controller_head, target_head, target_tree, [command_stage("gate_a")]
    )
    flow = coordinator(auth, controller, target, runtime, ScriptedExecutor())
    assert flow.run(execute=True)["status"] == "COMPLETED"

    projection = json.loads(flow.store.projection_path.read_text(encoding="utf-8"))
    projection["status"] = "RUNNING"
    flow.store.projection_path.write_text(json.dumps(projection), encoding="utf-8")
    with pytest.raises(WorkflowStoreError, match="projection_mismatch"):
        flow.store.verify()
    flow.store._write_projection(
        flow.store.verify(allow_projection_recovery=True).projection,
        flow.store.load_contract(),
    )

    lines = flow.store.ledger_path.read_text(encoding="utf-8").splitlines()
    first = json.loads(lines[0])
    first["payload"]["authorization_fingerprint"] = HASH
    lines[0] = json.dumps(first, sort_keys=True, separators=(",", ":"))
    flow.store.ledger_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    with pytest.raises(WorkflowStoreError, match="event_hash_mismatch"):
        flow.store.verify()


def test_issue_evidence_is_duplicate_safe_and_redacts_raw_payload(monkeypatch):
    sink = GhIssueEvidenceSink("owner/repository", 303)

    class Comments:
        values: list[dict[str, object]] = []

        def get_issue_comments(self, issue):
            return list(self.values)

    comments = Comments()
    sink._client = comments
    calls: list[tuple[str, ...]] = []

    def fake_run(argv, **kwargs):
        calls.append(argv)
        return {
            "exit_code": 0,
            "truncated": False,
            "timed_out": False,
            "stdout": b'{"id":123}',
            "stderr": b"",
        }

    monkeypatch.setattr(workflow_module, "_run_process", fake_run)
    result = sink.emit(
        workflow_id="wf-303-aaaaaaaaaaaa",
        evidence_key="gate_pass_test",
        payload={"status": "PASS", "raw_user_content": "private-user-record"},
    )
    assert result == {"reused": False, "comment_id": 123}
    assert "private-user-record" not in " ".join(calls[0])
    marker = (
        "<!-- cse-orchestrator-workflow-evidence:v1:"
        "wf-303-aaaaaaaaaaaa:gate_pass_test -->"
    )
    comments.values = [{"id": 123, "body": marker}]
    reused = sink.emit(
        workflow_id="wf-303-aaaaaaaaaaaa",
        evidence_key="gate_pass_test",
        payload={"status": "PASS"},
    )
    assert reused == {"reused": True, "comment_id": 123}
    assert len(calls) == 1


def test_issue_evidence_translates_shared_github_failure() -> None:
    sink = GhIssueEvidenceSink("owner/repository", 303)

    class BrokenComments:
        def get_issue_comments(self, issue):
            raise GitHubClientError("github_get_utf8_invalid")

    sink._client = BrokenComments()
    with pytest.raises(WorkflowError, match="^github_get_utf8_invalid$"):
        sink.emit(
            workflow_id="wf-303-aaaaaaaaaaaa",
            evidence_key="workflow_started",
            payload={"status": "RUNNING", "raw": "private-github-content"},
        )


def test_cli_returns_structured_blocker_for_evidence_read_failure(
    tmp_path, monkeypatch, capsys
) -> None:
    sink = GhIssueEvidenceSink("owner/repository", 303)

    class BrokenComments:
        def get_issue_comments(self, issue):
            raise GitHubClientError("github_get_utf8_invalid")

    sink._client = BrokenComments()

    def fail_from_sink(args):
        return sink.emit(
            workflow_id="wf-303-aaaaaaaaaaaa",
            evidence_key="workflow_started",
            payload={"status": "RUNNING", "raw": "private-github-content"},
        )

    monkeypatch.setattr(cli, "_workflow_bootstrap", fail_from_sink)
    exit_code = cli.main(
        [
            "workflow-bootstrap",
            "--issue",
            "284",
            "--target-root",
            str(tmp_path / "target"),
            "--runtime-root",
            str(tmp_path / "runtime"),
        ]
    )
    captured = capsys.readouterr()
    assert exit_code == 14
    assert json.loads(captured.out) == {
        "schema_version": 1,
        "status": "UNSAFE_BLOCKED",
        "reason": "github_get_utf8_invalid",
    }
    assert captured.err == ""
    assert "private-github-content" not in captured.out
    assert "Traceback" not in captured.out


def test_cli_workflow_run_status_verify_end_to_end(tmp_path, monkeypatch, capsys):
    controller, target, runtime, controller_head, target_head, target_tree = roots(
        tmp_path
    )
    value = authorization_value(
        controller_head, target_head, target_tree, [command_stage("gate_a")]
    )
    authorization_path = tmp_path / "authorization.json"
    authorization_path.write_text(json.dumps(value), encoding="utf-8")
    monkeypatch.setattr(cli, "GhIssueEvidenceSink", lambda repository, issue: NullEvidenceSink())
    monkeypatch.setattr(workflow_module, "CONTROLLER_SOURCE_ROOT", controller.resolve())
    common = [
        "--issue",
        "303",
        "--repo-root",
        str(target),
        "--runtime-root",
        str(runtime),
        "--repository",
        "owner/repository",
        "--controller-root",
        str(controller),
    ]
    assert cli.main(["workflow-run", *common, "--authorization", str(authorization_path)]) == 0
    dry_run = json.loads(capsys.readouterr().out)
    assert dry_run["status"] == "DRY_RUN"
    assert cli.main(
        ["workflow-run", *common, "--authorization", str(authorization_path), "--execute"]
    ) == 0
    completed = json.loads(capsys.readouterr().out)
    assert completed["status"] == "COMPLETED"
    workflow_id = completed["workflow_id"]
    assert cli.main(["workflow-status", *common, "--workflow-id", workflow_id]) == 0
    status = json.loads(capsys.readouterr().out)
    assert status["next_action"] is None
    assert cli.main(["workflow-verify", *common, "--workflow-id", workflow_id]) == 0
    verified = json.loads(capsys.readouterr().out)
    assert verified["verification"] == {
        "ledger": True,
        "projection": True,
        "artifact": {"present": False, "valid": True, "fingerprint": None},
    }


def test_controller_target_separation_and_target_scope_drift_fail_closed(tmp_path):
    controller, target, runtime, controller_head, target_head, target_tree = roots(
        tmp_path
    )
    auth = parsed_authorization(
        controller_head, target_head, target_tree, [command_stage("gate_a")]
    )
    with pytest.raises(WorkflowError, match="controller_target_not_separated"):
        coordinator(auth, target, target, runtime, ScriptedExecutor()).run(execute=True)
    (target / "outside.txt").write_text("drift\n", encoding="utf-8")
    with pytest.raises(WorkflowError, match="target_initial_state_dirty|target_allowlist_drift"):
        coordinator(auth, controller, target, runtime, ScriptedExecutor()).run(
            execute=True
        )


class WorkflowFakeTabletAdapter:
    def __init__(self, *, connected: bool = True):
        self.connected = connected
        self.calls: list[str] = []

    def _pass(self, action: str):
        self.calls.append(action)
        return AdapterActionResult()

    def preflight(self, contract):
        if not self.connected:
            raise DeviceSmokeError(
                "device_not_connected", "exact_tablet_is_listed", external=True
            )
        return self._pass("tablet_preflight")

    def install(self, contract):
        return self._pass("tablet_install")

    def timed_to_all_day(self, contract):
        return self._pass("smoke_timed_to_all_day")

    def all_day_date_change(self, contract):
        return self._pass("smoke_all_day_date_change")

    def same_day_noop(self, contract):
        return self._pass("smoke_same_day_noop")

    def all_day_to_timed(self, contract):
        return self._pass("smoke_all_day_to_timed")

    def notification_binding(self, contract):
        return self._pass("smoke_notification_binding")

    def cold_relaunch(self, contract):
        return self._pass("smoke_cold_relaunch")

    def recoverable_cleanup(self, contract):
        return self._pass("smoke_recoverable_cleanup")


def smoke_stage(name: str, adb_path: Path) -> dict[str, object]:
    return {
        "name": name,
        "kind": "command",
        "capability": "Device",
        "command_family": "cse_tablet_smoke",
        "argv": [
            str(adb_path),
            "-s",
            ISSUE_284_TABLET_SERIAL,
            "cse-smoke",
            name,
            "CSE284_O10_ABCDEF123456",
            "2026-08-03",
            "2026-08-04",
            "recoverable-only",
        ],
        "cwd": "target",
        "timeout_seconds": 30,
        "output_limit_bytes": 65536,
        "retry_max": 0,
        "reusable": False,
        "failure_class": "external" if name == "tablet_preflight" else "unsafe",
        "environment_allowlist": [],
    }


def schema2_smoke_authorization(
    controller_head: str,
    target_head: str,
    target_tree: str,
    stages: list[dict[str, object]],
    artifact: dict[str, object],
):
    value = authorization_value(
        controller_head,
        target_head,
        target_tree,
        stages,
        artifact=artifact,
        device={
            "serial": ISSUE_284_TABLET_SERIAL,
            "model": ISSUE_284_TABLET_MODEL,
            "package": ISSUE_284_DEBUG_PACKAGE,
        },
    )
    value["schema_version"] = 2
    value["evidence_source_fingerprint"] = HASH
    value["budgets"]["command_max"] = 64
    return parse_workflow_authorization(
        value, now=datetime(2026, 8, 2, tzinfo=timezone.utc)
    )


def test_schema2_device_absence_pauses_then_same_workflow_resumes_after_artifact(
    tmp_path,
):
    controller, target, runtime, controller_head, target_head, target_tree = roots(
        tmp_path
    )
    adb = tmp_path / "adb.exe"
    adb.write_bytes(b"fake-adb")
    apk = tmp_path / "app-debug.apk"
    apk.write_bytes(b"exact-apk")
    artifact = {
        "path": str(apk),
        "sha256": "sha256:" + hashlib.sha256(b"exact-apk").hexdigest(),
        "package": ISSUE_284_DEBUG_PACKAGE,
        "version": "0.1.0-debug (1)",
        "signer": HASH,
        "checkpoint_sha": target_head,
    }
    stages = [non_command_stage("artifact_verify", "artifact_verify")]
    stages.extend(smoke_stage(name, adb) for name in ISSUE_284_SMOKE_ACTIONS)
    auth = schema2_smoke_authorization(
        controller_head, target_head, target_tree, stages, artifact
    )
    fake = WorkflowFakeTabletAdapter(connected=False)
    first = coordinator(
        auth,
        controller,
        target,
        runtime,
        DefaultStageExecutor(tablet_adapter=fake),
    ).run(execute=True)
    assert first["status"] == "PAUSED_EXTERNAL"
    assert first["current_stage"] == "tablet_preflight"
    assert first["artifact"]["sha256"] == artifact["sha256"]
    assert first["stage_attempts"] == {"artifact_verify": 1, "tablet_preflight": 1}

    fake.connected = True
    second = coordinator(
        auth,
        controller,
        target,
        runtime,
        DefaultStageExecutor(tablet_adapter=fake),
    ).run(execute=True)
    assert second["status"] == "COMPLETED"
    assert second["stage_attempts"]["artifact_verify"] == 1
    assert second["stage_attempts"]["tablet_preflight"] == 2
    assert fake.calls == list(ISSUE_284_SMOKE_ACTIONS)


@pytest.mark.parametrize("crash_after", ISSUE_284_SMOKE_ACTIONS)
def test_crash_after_every_smoke_step_resumes_without_reexecuting_that_step(
    tmp_path, crash_after
):
    controller, target, runtime, controller_head, target_head, target_tree = roots(
        tmp_path
    )
    adb = tmp_path / "adb.exe"
    adb.write_bytes(b"fake-adb")
    apk = tmp_path / "app-debug.apk"
    apk.write_bytes(b"exact-apk")
    artifact = {
        "path": str(apk),
        "sha256": "sha256:" + hashlib.sha256(b"exact-apk").hexdigest(),
        "package": ISSUE_284_DEBUG_PACKAGE,
        "version": "0.1.0-debug (1)",
        "signer": HASH,
        "checkpoint_sha": target_head,
    }
    stages = [smoke_stage(name, adb) for name in ISSUE_284_SMOKE_ACTIONS]
    auth = schema2_smoke_authorization(
        controller_head, target_head, target_tree, stages, artifact
    )
    fake = WorkflowFakeTabletAdapter()
    with pytest.raises(WorkflowError, match="simulated_process_crash"):
        coordinator(
            auth,
            controller,
            target,
            runtime,
            DefaultStageExecutor(tablet_adapter=fake),
            RecordingSink(fail_key=f"gate_pass_{crash_after}"),
        ).run(execute=True)
    before = list(fake.calls)
    assert before.count(crash_after) == 1

    completed = coordinator(
        auth,
        controller,
        target,
        runtime,
        DefaultStageExecutor(tablet_adapter=fake),
        RecordingSink(),
    ).run(execute=True)
    assert completed["status"] == "COMPLETED"
    assert fake.calls.count(crash_after) == 1
    assert fake.calls == list(ISSUE_284_SMOKE_ACTIONS)
