from __future__ import annotations

import hashlib
import json
import subprocess
from copy import deepcopy
from dataclasses import dataclass, replace
from datetime import datetime, timezone
from pathlib import Path

import pytest

from tools.cse_orchestrator import cli
from tools.cse_orchestrator import workflow as workflow_module
from tools.cse_orchestrator import workflow_bootstrap as bootstrap_module
from tools.cse_orchestrator.device_smoke import ISSUE_284_SMOKE_ACTIONS
from tools.cse_orchestrator.workflow_bootstrap import (
    BootstrapAuthorizationStore,
    BootstrapError,
    ISSUE_284_BRANCH,
    ISSUE_284_CHECKPOINT_PATHS,
    ISSUE_284_READ_WRITE_ALLOWLIST,
    ISSUE_305_AUTHORIZATION_COMMENT,
    ISSUE_305_HANDOFF_AUTHORIZATION_COMMENT,
    ISSUE_305_PAUSED_HANDOFF_AUTHORIZATION_COMMENT,
    Issue284PilotProfile,
    WorkflowBootstrap,
    canonical_markdown_bytes,
    write_issue_284_completion,
)
from tools.cse_orchestrator.workflow_store import WorkflowContract, WorkflowStore


def git(root: Path, *argv: str) -> str:
    completed = subprocess.run(
        ["git", *argv],
        cwd=root,
        text=True,
        encoding="utf-8",
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        shell=False,
        check=False,
        timeout=30,
    )
    assert completed.returncode == 0, completed.stderr
    return completed.stdout.strip()


def init_repo(root: Path, branch: str) -> None:
    root.mkdir(parents=True)
    subprocess.run(
        ["git", "init", "-b", branch, str(root)],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        shell=False,
        check=True,
        timeout=30,
    )
    git(root, "config", "user.name", "CSE Test")
    git(root, "config", "user.email", "cse-test@example.invalid")


@dataclass
class FakeEvidenceClient:
    bodies: dict[int, str]
    comments: dict[int, dict[int, str]]

    def get_issue(self, issue_number: int):
        return {"number": issue_number, "body": self.bodies[issue_number]}

    def get_issue_comments(self, issue_number: int):
        return [
            {"id": comment_id, "body": body}
            for comment_id, body in self.comments[issue_number].items()
        ]


def sha(value: str | bytes) -> str:
    raw = value.encode() if isinstance(value, str) else value
    return hashlib.sha256(raw).hexdigest()


@pytest.fixture
def bootstrap_fixture(tmp_path):
    controller = tmp_path / "controller"
    target = tmp_path / "target"
    runtime = tmp_path / "runtime"
    tools = tmp_path / "tools"
    tools.mkdir()

    init_repo(controller, "master")
    (controller / "base.txt").write_text("base\n", encoding="utf-8")
    git(controller, "add", "base.txt")
    git(controller, "commit", "-m", "base")
    controller_base = git(controller, "rev-parse", "HEAD")
    (controller / "release.txt").write_text("O10.1\n", encoding="utf-8")
    git(controller, "add", "release.txt")
    git(controller, "commit", "-m", "release")
    controller_release = git(controller, "rev-parse", "HEAD")

    init_repo(target, ISSUE_284_BRANCH)
    paths = set(ISSUE_284_CHECKPOINT_PATHS) | {
        "mobile/lib/domain/agenda_models.dart",
        "mobile/pubspec.lock",
        "CHANGELOG.md",
        "ROADMAP.md",
    }
    for path in sorted(paths):
        candidate = target / path
        candidate.parent.mkdir(parents=True, exist_ok=True)
        candidate.write_text(f"base:{path}\n", encoding="utf-8")
    git(target, "add", "--", *sorted(paths))
    git(target, "commit", "-m", "base")
    parent = git(target, "rev-parse", "HEAD")
    for path in ISSUE_284_CHECKPOINT_PATHS:
        (target / path).write_text(f"checkpoint:{path}\n", encoding="utf-8")
    git(target, "add", "--", *ISSUE_284_CHECKPOINT_PATHS)
    git(target, "commit", "-m", "Add reminder all-day editing")
    checkpoint = git(target, "rev-parse", "HEAD")
    tree = git(target, "rev-parse", "HEAD^{tree}")
    blobs = {
        path: git(target, "rev-parse", f"HEAD:{path}")
        for path in (
            *ISSUE_284_CHECKPOINT_PATHS,
            "mobile/lib/domain/agenda_models.dart",
            "mobile/pubspec.lock",
        )
    }

    flutter = tools / "flutter.bat"
    adb = tools / "adb.exe"
    artifact = tmp_path / "app-debug.apk"
    flutter.write_bytes(b"flutter")
    adb.write_bytes(b"adb")
    artifact.write_bytes(b"apk")

    bodies = {284: "issue-284-body", 305: "issue-305-body"}
    comments = {
        284: {
            5159802594: "authorized checkpoint",
            5159834136: "focused pass",
            5159861939: "full analyze pass",
            5159903268: "artifact pass",
            5159955414: "orchestrator freeze",
        },
        305: {ISSUE_305_AUTHORIZATION_COMMENT: "binding authorization"},
    }
    profile = Issue284PilotProfile(
        target_parent=parent,
        target_checkpoint=checkpoint,
        target_tree=tree,
        blobs=blobs,
        artifact_path=artifact,
        artifact_sha256=sha(b"apk"),
        flutter_path=flutter,
        adb_path=adb,
        adb_sha256=sha(b"adb"),
        controller_base=controller_base,
        handoff_predecessor_revision=controller_release,
        issue_body_hashes={
            key: sha(canonical_markdown_bytes(value)) for key, value in bodies.items()
        },
        comment_hashes={
            issue: {
                comment_id: sha(canonical_markdown_bytes(body))
                for comment_id, body in values.items()
            }
            for issue, values in comments.items()
        },
        require_controller_on_origin_master=False,
    )
    client = FakeEvidenceClient(bodies, comments)
    return controller, target, runtime, profile, client


def bootstrap(values):
    controller, target, runtime, profile, client = values
    return WorkflowBootstrap(
        target_root=target,
        runtime_root=runtime,
        controller_root=controller,
        profile=profile,
        evidence_client=client,
        now=datetime(2026, 8, 3, 12, tzinfo=timezone.utc),
    )


def test_bootstrap_generates_exact_schema_2_authorization_from_live_inputs(
    bootstrap_fixture,
):
    generated = bootstrap(bootstrap_fixture).build_authorization()

    assert generated.payload["schema_version"] == 2
    assert generated.issue == 284
    assert generated.comment_id == ISSUE_305_AUTHORIZATION_COMMENT
    assert generated.payload["target"]["branch"] == ISSUE_284_BRANCH
    assert tuple(generated.write_allowlist) == ISSUE_284_READ_WRITE_ALLOWLIST
    assert len(generated.reused_evidence) == 5
    assert {item["stage"] for item in generated.reused_evidence} == {
        "focused_lifecycle",
        "focused_widget",
        "full_flutter",
        "flutter_analyze",
        "debug_apk_build",
    }
    names = [stage.name for stage in generated.stages]
    assert names[6:15] == list(ISSUE_284_SMOKE_ACTIONS)
    assert names[-4:] == [
        "completion_docs",
        "completion_commit",
        "normal_push",
        "draft_pr",
    ]
    assert all(
        stage.argv[1:3] == ("-s", "R52W90JFN1M")
        for stage in generated.stages
        if stage.capability == "Device"
    )
    assert generated.payload["publish"] == {
        "base_branch": "master",
        "title": "Complete reminder all-day editing",
        "body_first_line": "Related to #284",
        "commit_message": "Complete reminder all-day editing",
    }


@pytest.mark.parametrize(
    "transport_value",
    [
        "# Başlık\n\nİçerik\n",
        "# Başlık\r\n\r\nİçerik\r\n",
        "# Başlık\r\rİçerik\r",
        "\ufeff# Başlık\n\nİçerik",
        "# Başlık\n\nİçerik",
    ],
)
def test_canonical_markdown_bytes_accepts_only_transport_equivalent_forms(
    transport_value,
):
    assert canonical_markdown_bytes(transport_value) == (
        "# Başlık\n\nİçerik\n".encode("utf-8")
    )


@pytest.mark.parametrize(
    "drifted",
    [
        "# Başlık\n\nİçeriX\n",
        "# Başlık\n\nİçe rik\n",
    ],
)
def test_canonical_markdown_bytes_preserves_character_and_inner_whitespace_drift(
    drifted,
):
    expected = canonical_markdown_bytes("# Başlık\n\nİçerik\n")
    assert canonical_markdown_bytes(drifted) != expected


def test_bootstrap_accepts_bom_eol_and_terminal_newline_transport(
    bootstrap_fixture,
):
    *_, client = bootstrap_fixture
    client.bodies[284] = "\ufeffissue-284-body\r\n"
    client.bodies[305] = "issue-305-body\r"
    for comment_id, body in client.comments[284].items():
        client.comments[284][comment_id] = f"\ufeff{body}\r\n"
    client.comments[305][ISSUE_305_AUTHORIZATION_COMMENT] = (
        "binding authorization\n"
    )

    generated = bootstrap(bootstrap_fixture).build_authorization()

    assert generated.issue == 284


@pytest.mark.parametrize("issue_number", [284, 305])
def test_issue_body_drift_reason_identifies_source(bootstrap_fixture, issue_number):
    *_, client = bootstrap_fixture
    client.bodies[issue_number] += "X"

    with pytest.raises(
        BootstrapError,
        match=rf"^evidence_issue_body_drift_{issue_number}$",
    ):
        bootstrap(bootstrap_fixture).build_authorization()


@pytest.mark.parametrize(
    ("issue_number", "comment_id"),
    [
        (284, 5159834136),
        (305, ISSUE_305_AUTHORIZATION_COMMENT),
    ],
)
def test_comment_drift_reason_identifies_source(
    bootstrap_fixture,
    issue_number,
    comment_id,
):
    *_, client = bootstrap_fixture
    client.comments[issue_number][comment_id] += " X"

    with pytest.raises(
        BootstrapError,
        match=rf"^evidence_comment_drift_{issue_number}_{comment_id}$",
    ):
        bootstrap(bootstrap_fixture).build_authorization()


def test_bootstrap_translates_shared_github_error_to_source_specific_reason(
    bootstrap_fixture,
):
    instance = bootstrap(bootstrap_fixture)

    class BrokenEvidence:
        def get_issue(self, issue_number):
            raise bootstrap_module.GitHubClientError("github_get_utf8_invalid")

        def get_issue_comments(self, issue_number):
            raise AssertionError("comments must not be read after issue failure")

    instance.evidence_client = BrokenEvidence()
    with pytest.raises(
        BootstrapError,
        match="^evidence_issue_read_failed_284_github_get_utf8_invalid$",
    ):
        instance.build_authorization()


def test_bootstrap_dry_run_shows_authorization_and_does_not_persist(
    bootstrap_fixture, monkeypatch
):
    controller, target, runtime, _, _ = bootstrap_fixture
    monkeypatch.setattr(workflow_module, "CONTROLLER_SOURCE_ROOT", controller.resolve())
    instance = bootstrap(bootstrap_fixture)
    result = instance.run(execute=False)
    assert result["status"] == "DRY_RUN"
    assert result["authorization"]["schema_version"] == 2
    assert result["workflow"]["next_action"] == "focused_lifecycle"
    assert not BootstrapAuthorizationStore(runtime, target).exists


@pytest.mark.parametrize("drift", ["target", "artifact", "evidence"])
def test_bootstrap_target_artifact_and_recorded_evidence_tamper_fail_closed(
    bootstrap_fixture, drift
):
    _, target, _, profile, client = bootstrap_fixture
    if drift == "target":
        (target / "mobile/lib/application/agenda_application.dart").write_text(
            "tampered\n", encoding="utf-8"
        )
    elif drift == "artifact":
        profile.artifact_path.write_bytes(b"tampered")
    else:
        client.comments[284][5159834136] = "tampered evidence"
    with pytest.raises(BootstrapError, match="dirty|drift|mismatch"):
        bootstrap(bootstrap_fixture).build_authorization()


def test_external_bootstrap_authorization_is_immutable_and_tamper_evident(
    bootstrap_fixture,
):
    _, target, runtime, _, _ = bootstrap_fixture
    instance = bootstrap(bootstrap_fixture)
    authorization = instance.build_authorization()
    store = BootstrapAuthorizationStore(runtime, target)
    store.save(authorization, target)
    assert store.load(target).fingerprint == authorization.fingerprint

    value = json.loads(store.authorization_path.read_text(encoding="utf-8"))
    value["nonce"] = "tampered"
    store.authorization_path.write_text(json.dumps(value), encoding="utf-8")
    with pytest.raises(BootstrapError, match="tampered"):
        store.load(target)


def persisted_pre_stage(values):
    controller, target, runtime, _, _ = values
    instance = bootstrap(values)
    predecessor = instance.build_authorization()
    bootstrap_store = BootstrapAuthorizationStore(runtime, target)
    bootstrap_store.save(predecessor, target)
    contract = WorkflowContract.from_authorization(predecessor)
    workflow_store = WorkflowStore(
        runtime_root=runtime,
        repo_root=target,
        workflow_id=contract.workflow_id,
    )
    workflow_store.start(contract)
    return instance, predecessor, bootstrap_store, workflow_store


def advance_controller(controller: Path) -> str:
    path = controller / "handoff.txt"
    current = path.read_text(encoding="utf-8") if path.exists() else ""
    path.write_text(current + "shared utf8 handoff\n", encoding="utf-8")
    git(controller, "add", "handoff.txt")
    git(controller, "commit", "-m", "controller handoff")
    return git(controller, "rev-parse", "HEAD")


def pause_successor_at_exact_tablet_preflight(
    values, authorization
) -> tuple[WorkflowStore, object]:
    _, target, runtime, _, _ = values
    contract = WorkflowContract.from_authorization(authorization)
    store = WorkflowStore(
        runtime_root=runtime,
        repo_root=target,
        workflow_id=contract.workflow_id,
    )
    store.start(contract)
    source = "sha256:" + "1" * 64
    store.append("target_observed", {"source_fingerprint": source})
    reused = {item["stage"]: item for item in authorization.reused_evidence}
    for index in range(5):
        stage = contract.stages[index]
        store.append(
            "stage_reused",
            {
                "stage_index": index,
                "stage": stage.name,
                "evidence": dict(reused[stage.name]),
                "details": {"target_after_fingerprint": source},
            },
        )
    artifact_stage = contract.stages[5]
    store.append(
        "stage_admitted",
        {
            "stage_index": 5,
            "stage": "artifact_verify",
            "attempt": 1,
            "attempt_id": "sha256:" + sha("artifact-attempt"),
            "stage_fingerprint": artifact_stage.stage_fingerprint,
            "budget_counter": "command",
        },
    )
    store.append(
        "stage_passed",
        {
            "stage_index": 5,
            "stage": "artifact_verify",
            "evidence": {
                "stage": "artifact_verify",
                "evidence_fingerprint": "sha256:" + sha("artifact-evidence"),
            },
            "details": {
                "artifact": dict(authorization.payload["artifact"]),
                "target_after_fingerprint": source,
            },
        },
    )
    preflight_stage = contract.stages[6]
    for attempt in range(1, 4):
        store.append(
            "stage_admitted",
            {
                "stage_index": 6,
                "stage": "tablet_preflight",
                "attempt": attempt,
                "attempt_id": "sha256:" + sha(f"preflight-attempt-{attempt}"),
                "stage_fingerprint": preflight_stage.stage_fingerprint,
                "budget_counter": "command",
            },
        )
        store.append(
            "stage_paused",
            {
                "stage": "tablet_preflight",
                "reason_code": "screen_not_interactive",
                "command_index": 1,
                "first_failed_predicate": "screen_is_interactive",
            },
        )
        if attempt < 3:
            store.append("workflow_resumed", {"stage_index": 6})
    return store, store.verify()


def exact_paused_successor_fixture(values):
    controller, target, runtime, profile, client = values
    _, root_authorization, bootstrap_store, _ = persisted_pre_stage(values)
    first_controller = advance_controller(controller)
    first_authorization, _, _ = bootstrap(values).authorization(persist=True)
    first_store, paused = pause_successor_at_exact_tablet_preflight(
        values, first_authorization
    )
    paused_public = paused.projection.public_dict(paused.contract)
    paused_profile = replace(
        profile,
        paused_handoff_predecessor_revision=first_controller,
        paused_predecessor_authorization=first_authorization.fingerprint,
        paused_predecessor_workflow=paused.contract.workflow_id,
        paused_projection_fingerprint=paused_public["projection_fingerprint"],
        paused_tail_hash=paused.projection.tail_hash,
    )
    return (
        (controller, target, runtime, paused_profile, client),
        root_authorization,
        first_authorization,
        bootstrap_store,
        first_store,
        paused,
    )


def test_exact_pre_stage_controller_handoff_is_immutable_and_idempotent(
    bootstrap_fixture,
):
    controller, target, runtime, _, _ = bootstrap_fixture
    _, predecessor, store, old_workflow = persisted_pre_stage(bootstrap_fixture)
    old_authorization = store.authorization_path.read_bytes()
    old_metadata = store.metadata_path.read_bytes()
    old_ledger = old_workflow.ledger_path.read_bytes()
    controller_head = advance_controller(controller)

    successor, resumed, predecessor_id = bootstrap(bootstrap_fixture).authorization(
        persist=True
    )
    successor_contract = WorkflowContract.from_authorization(successor)

    assert resumed is True
    assert predecessor_id == WorkflowContract.from_authorization(predecessor).workflow_id
    assert successor.payload["controller_revision"] == controller_head
    assert successor.fingerprint != predecessor.fingerprint
    assert successor_contract.workflow_id != predecessor_id
    assert bootstrap_module._is_exact_pre_stage_handoff(
        old_workflow.verify().projection, old_workflow.verify().events
    )
    assert store.authorization_path.read_bytes() == old_authorization
    assert store.metadata_path.read_bytes() == old_metadata
    assert old_workflow.ledger_path.read_bytes() == old_ledger

    successor_authorization, successor_metadata = store._successor_paths(controller_head)
    metadata = json.loads(successor_metadata.read_text(encoding="utf-8"))
    assert successor_authorization.is_file()
    assert metadata["handoff_authorization_comment_id"] == (
        ISSUE_305_HANDOFF_AUTHORIZATION_COMMENT
    )
    assert metadata["predecessor_workflow_id"] == predecessor_id
    assert metadata["successor_workflow_id"] == successor_contract.workflow_id

    successor_workflow = WorkflowStore(
        runtime_root=runtime,
        repo_root=target,
        workflow_id=successor_contract.workflow_id,
    )
    assert successor_workflow.start(successor_contract).status == "RUNNING"
    assert successor_workflow.root.parent == runtime.resolve() / "workflows"
    assert old_workflow.ledger_path.read_bytes() == old_ledger

    repeated, repeated_resumed, repeated_predecessor = bootstrap(
        bootstrap_fixture
    ).authorization(persist=True)
    assert repeated.fingerprint == successor.fingerprint
    assert repeated_resumed is True
    assert repeated_predecessor == predecessor_id
    assert store.authorization_path.read_bytes() == old_authorization
    assert old_workflow.ledger_path.read_bytes() == old_ledger

    advance_controller(controller)
    with pytest.raises(BootstrapError, match="^controller_handoff_not_safe$"):
        bootstrap(bootstrap_fixture).authorization(persist=True)


def test_exact_paused_tablet_successor_preserves_history_and_all_predecessor_bytes(
    bootstrap_fixture,
):
    (
        paused_values,
        _,
        first_authorization,
        store,
        first_workflow,
        paused,
    ) = exact_paused_successor_fixture(bootstrap_fixture)
    controller, target, runtime, _, _ = paused_values
    first_authorization_path, first_metadata_path = store._successor_paths(
        str(first_authorization.payload["controller_revision"])
    )
    immutable = {
        "root_authorization": store.authorization_path.read_bytes(),
        "root_metadata": store.metadata_path.read_bytes(),
        "first_authorization": first_authorization_path.read_bytes(),
        "first_metadata": first_metadata_path.read_bytes(),
        "manifest": first_workflow.manifest_path.read_bytes(),
        "ledger": first_workflow.ledger_path.read_bytes(),
    }
    successor_controller = advance_controller(controller)

    successor, resumed, predecessor_id = bootstrap(paused_values).authorization(
        persist=True
    )
    successor_contract = WorkflowContract.from_authorization(successor)
    successor_store = WorkflowStore(
        runtime_root=runtime,
        repo_root=target,
        workflow_id=successor_contract.workflow_id,
    )
    successor_verification = successor_store.verify()

    assert resumed is True
    assert predecessor_id == paused.contract.workflow_id
    assert successor.payload["controller_revision"] == successor_controller
    assert successor_contract.workflow_id != paused.contract.workflow_id
    assert successor_verification.projection.status == "PAUSED_EXTERNAL"
    assert successor_verification.projection.current_stage_index == 6
    assert successor_verification.projection.stage_attempts == {
        "artifact_verify": 1,
        "tablet_preflight": 3,
    }
    assert successor_verification.projection.active_attempt_id is None
    assert successor_verification.projection.device is None
    assert successor_verification.projection.publish is None
    assert bootstrap_module.WorkflowBootstrap._same_continuation_state(
        paused, successor_verification
    )
    assert store.authorization_path.read_bytes() == immutable["root_authorization"]
    assert store.metadata_path.read_bytes() == immutable["root_metadata"]
    assert first_authorization_path.read_bytes() == immutable["first_authorization"]
    assert first_metadata_path.read_bytes() == immutable["first_metadata"]
    assert first_workflow.manifest_path.read_bytes() == immutable["manifest"]
    assert first_workflow.ledger_path.read_bytes() == immutable["ledger"]

    second_authorization_path, second_metadata_path = store._successor_paths(
        successor_controller
    )
    metadata = json.loads(second_metadata_path.read_text(encoding="utf-8"))
    assert second_authorization_path.is_file()
    assert metadata["handoff_authorization_comment_id"] == (
        ISSUE_305_PAUSED_HANDOFF_AUTHORIZATION_COMMENT
    )
    successor_bytes = {
        "authorization": second_authorization_path.read_bytes(),
        "metadata": second_metadata_path.read_bytes(),
        "manifest": successor_store.manifest_path.read_bytes(),
        "ledger": successor_store.ledger_path.read_bytes(),
    }

    repeated, repeated_resumed, repeated_predecessor = bootstrap(
        paused_values
    ).authorization(persist=True)
    assert repeated.fingerprint == successor.fingerprint
    assert repeated_resumed is True
    assert repeated_predecessor == predecessor_id
    assert second_authorization_path.read_bytes() == successor_bytes["authorization"]
    assert second_metadata_path.read_bytes() == successor_bytes["metadata"]
    assert successor_store.manifest_path.read_bytes() == successor_bytes["manifest"]
    assert successor_store.ledger_path.read_bytes() == successor_bytes["ledger"]

    advance_controller(controller)
    with pytest.raises(BootstrapError, match="^controller_handoff_not_safe$"):
        bootstrap(paused_values).authorization(persist=True)


def test_paused_handoff_rejects_every_projection_and_effect_mismatch(
    bootstrap_fixture,
):
    paused_values, _, _, _, _, paused = exact_paused_successor_fixture(
        bootstrap_fixture
    )
    profile = paused_values[3]
    mismatches = [
        ("status", "RUNNING"),
        ("current_stage_index", 7),
        ("stage_attempts", {"artifact_verify": 1, "tablet_preflight": 4}),
        ("external_pauses", {"tablet_preflight": 2}),
        ("active_attempt_id", "sha256:" + "a" * 64),
        ("artifact", None),
        ("device", {"installed": True}),
        ("publish", {"commit_sha": "b" * 40}),
        ("last_blocker", "device_not_connected"),
        ("blocker_phase", "tablet_install"),
        ("command_index", 0),
        ("first_failed_predicate", "tablet_state_is_device"),
    ]
    for field, value in mismatches:
        projection = deepcopy(paused.projection)
        setattr(projection, field, value)
        assert not bootstrap_module._is_exact_paused_tablet_handoff(
            projection,
            paused.events,
            paused.contract,
            expected_projection_fingerprint=profile.paused_projection_fingerprint,
            expected_tail_hash=profile.paused_tail_hash,
        ), field


def test_paused_handoff_rejects_projection_fingerprint_and_tail_mismatch(
    bootstrap_fixture,
):
    paused_values, _, _, _, _, paused = exact_paused_successor_fixture(
        bootstrap_fixture
    )
    profile = paused_values[3]

    assert not bootstrap_module._is_exact_paused_tablet_handoff(
        paused.projection,
        paused.events,
        paused.contract,
        expected_projection_fingerprint="sha256:" + "0" * 64,
        expected_tail_hash=profile.paused_tail_hash,
    )
    assert not bootstrap_module._is_exact_paused_tablet_handoff(
        paused.projection,
        paused.events,
        paused.contract,
        expected_projection_fingerprint=profile.paused_projection_fingerprint,
        expected_tail_hash="sha256:" + "0" * 64,
    )


@pytest.mark.parametrize(
    ("field", "value"),
    [
        ("status", "UNSAFE_BLOCKED"),
        ("event_count", 2),
        ("current_stage_index", 1),
        ("stage_attempts", {"focused_lifecycle": 1}),
        ("external_pauses", {"tablet_preflight": 1}),
        ("admitted_attempt_ids", ["sha256:" + "a" * 64]),
        ("active_attempt_id", "sha256:" + "b" * 64),
        ("consumed_budgets", {"command": 1}),
        ("passed_evidence", [{"stage": "focused_lifecycle"}]),
        ("last_target_fingerprint", "sha256:" + "c" * 64),
        ("artifact", {"sha256": "sha256:" + "d" * 64}),
        ("device", {"serial": "R52W90JFN1M"}),
        ("publish", {"commit_sha": "e" * 40}),
        ("last_blocker", "blocked"),
        ("blocker_phase", "focused_lifecycle"),
        ("command_index", 1),
        ("first_failed_predicate", "stage_succeeded"),
    ],
)
def test_controller_handoff_rejects_every_admission_and_effect_field(
    bootstrap_fixture, field, value
):
    _, _, _, workflow_store = persisted_pre_stage(bootstrap_fixture)
    verification = workflow_store.verify()
    projection = deepcopy(verification.projection)
    setattr(projection, field, value)

    assert not bootstrap_module._is_exact_pre_stage_handoff(
        projection, verification.events
    )


def test_controller_handoff_rejects_advanced_or_tampered_old_ledger(
    bootstrap_fixture,
):
    controller, _, _, _, _ = bootstrap_fixture
    _, _, _, workflow_store = persisted_pre_stage(bootstrap_fixture)
    workflow_store.append(
        "target_observed", {"source_fingerprint": "sha256:" + "a" * 64}
    )
    advance_controller(controller)
    with pytest.raises(BootstrapError, match="^controller_handoff_not_safe$"):
        bootstrap(bootstrap_fixture).authorization(persist=True)


def test_controller_handoff_rejects_hash_tampered_old_ledger(bootstrap_fixture):
    controller, _, _, _, _ = bootstrap_fixture
    _, _, _, workflow_store = persisted_pre_stage(bootstrap_fixture)
    ledger = workflow_store.ledger_path.read_bytes()
    workflow_store.ledger_path.write_bytes(ledger.replace(b"workflow_started", b"workflow_tampered"))
    advance_controller(controller)

    with pytest.raises(BootstrapError, match="^controller_handoff_not_safe$"):
        bootstrap(bootstrap_fixture).authorization(persist=True)


def test_cli_exposes_single_workflow_bootstrap_entry_point(
    tmp_path, monkeypatch, capsys
):
    captured: dict[str, object] = {}

    class FakeBootstrap:
        class Profile:
            repository = "faliardic/chief-site-engineer"

        profile = Profile()

        def __init__(self, **kwargs):
            captured.update(kwargs)

        def run(self, *, execute: bool):
            captured["execute"] = execute
            return {"schema_version": 2, "status": "DRY_RUN"}

    monkeypatch.setattr(cli, "WorkflowBootstrap", FakeBootstrap)
    target = tmp_path / "target"
    runtime = tmp_path / "runtime"
    controller = tmp_path / "controller"
    exit_code = cli.main(
        [
            "workflow-bootstrap",
            "--issue",
            "284",
            "--target-root",
            str(target),
            "--runtime-root",
            str(runtime),
            "--controller-root",
            str(controller),
        ]
    )
    assert exit_code == 0
    assert json.loads(capsys.readouterr().out)["status"] == "DRY_RUN"
    assert captured == {
        "target_root": target,
        "runtime_root": runtime,
        "controller_root": controller,
        "execute": False,
    }


def test_completion_docs_are_allowlisted_and_duplicate_safe(
    bootstrap_fixture, monkeypatch
):
    _, target, _, profile, _ = bootstrap_fixture
    monkeypatch.setattr(
        bootstrap_module, "ISSUE_284_CHECKPOINT", profile.target_checkpoint
    )
    monkeypatch.setattr(
        bootstrap_module, "ISSUE_284_ARTIFACT_SHA256", profile.artifact_sha256
    )
    kwargs = {
        "target_root": target,
        "checkpoint": profile.target_checkpoint,
        "tree": profile.target_tree,
        "artifact_sha256": profile.artifact_sha256,
        "synthetic_title": "CSE284_O10_ABCDEF123456",
    }
    first = write_issue_284_completion(**kwargs)
    first_diff = git(target, "diff")
    second = write_issue_284_completion(**kwargs)
    assert second == first
    assert git(target, "diff") == first_diff
    assert first["changed_paths"] == [
        ".cse/tasks/284_result.md",
        ".cse/tasks/284_task.md",
        "CHANGELOG.md",
        "ROADMAP.md",
    ]
