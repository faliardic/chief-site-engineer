from __future__ import annotations

import hashlib
import json
import subprocess
from dataclasses import dataclass
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
    Issue284PilotProfile,
    WorkflowBootstrap,
    write_issue_284_completion,
)


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
        issue_body_hashes={key: sha(value) for key, value in bodies.items()},
        comment_hashes={
            issue: {comment_id: sha(body) for comment_id, body in values.items()}
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
