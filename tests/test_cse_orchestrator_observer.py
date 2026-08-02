from __future__ import annotations

import json
from copy import deepcopy
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import parse_qs, urlsplit

import pytest

from tools.cse_orchestrator import authorization, cli, observer


HEAD = "36549ec5936bc9581cdebbb4985a11ec5e017fd6"
PARENT = "eb85f0a2ea0901f0074887fe999e74b6ab4aed0f"
TREE = "da79ccb09e9eca0f5d7ae0baf09692c1519c97bc"
AUTH_NOW = datetime(2026, 8, 2, tzinfo=timezone.utc)


def authorization_payload(comment_id: int = 101) -> dict[str, object]:
    return {
        "schema_version": 1,
        "repository": "faliardic/chief-site-engineer",
        "issue": 287,
        "comment_id": comment_id,
        "scope_version": 1,
        "validation_class": "python-tooling-readonly",
        "approval_level": "CODE_CHANGE",
        "capability": "Code",
        "branch": "codex/issue-287-cse-orchestrator-read-only-observer",
        "base_sha": HEAD,
        "head_sha": HEAD,
        "tree_sha": TREE,
        "action": "implement-o1-read-only-observer",
        "pending_action": "implement-o1-read-only-observer",
        "required_approval_level": "CODE_CHANGE",
        "previous_state": "SCOPE_VALIDATED",
        "resume_state": "SCOPE_VALIDATED",
        "expected_success_state": "FOCUSED_PASS",
        "supersedes_comment_id": None,
        "runtime_root": "%LOCALAPPDATA%\\CSE-Orchestrator",
        "read_allowlist": ["git:tracked-metadata", "github:issue/287"],
        "write_allowlist": [
            "tools/cse_orchestrator/authorization.py",
            "tools/cse_orchestrator/observer.py",
        ],
        "action_allowlist": [
            "git:read-only-observation",
            "github:get-issue-comments",
        ],
        "budgets": {
            "primary_max": 1,
            "correction_max": 1,
            "same_operation_retry_max": 1,
            "focused_test_max": 1,
            "compileall_max": 1,
            "full_test_max": 0,
            "integration_smoke_max": 0,
            "git_mutation_max": 0,
            "github_mutation_max": 0,
            "api_max": 0,
            "build_max": 0,
            "device_max": 0,
            "target_seconds": 2700,
            "hard_stop_seconds": 4200,
        },
        "expires_at": "2099-08-09T21:00:00Z",
        "nonce": "ce5b0da3-a9da-4d4e-b79d-3cc265e4dd48",
    }


def authorization_body(payload: dict[str, object]) -> str:
    return (
        "bounded authorization\n\n"
        f"{authorization.AUTHORIZATION_MARKER}\n"
        "```json\n"
        f"{json.dumps(payload, ensure_ascii=False, indent=2)}\n"
        "```\n"
    )


def comment(comment_id: int, payload: dict[str, object] | None = None) -> dict[str, object]:
    return {
        "id": comment_id,
        "created_at": f"2026-08-02T00:00:{comment_id % 60:02d}Z",
        "updated_at": f"2026-08-02T00:00:{comment_id % 60:02d}Z",
        "body": authorization_body(payload) if payload is not None else "ordinary note",
    }


class FakeRunner:
    def __init__(self, responses: dict[tuple[str, ...], observer.CommandResult]):
        self.responses = responses
        self.calls: list[tuple[str, ...]] = []

    def __call__(self, args: list[str] | tuple[str, ...], cwd: Path) -> observer.CommandResult:
        key = tuple(args)
        self.calls.append(key)
        return self.responses.get(
            key,
            observer.CommandResult(key, 1, "", "sanitized fake failure"),
        )


class FakeGitHub:
    def __init__(self, comments: list[dict[str, object]] | None = None):
        self.comments = comments or []
        self.calls: list[tuple[str, object]] = []

    def get_repository(self) -> dict[str, object]:
        self.calls.append(("GET", "repository"))
        return {
            "full_name": "faliardic/chief-site-engineer",
            "default_branch": "master",
        }

    def get_issue(self, issue_number: int) -> dict[str, object]:
        self.calls.append(("GET", f"issue/{issue_number}"))
        return {
            "number": issue_number,
            "state": "open",
            "updated_at": "2026-08-02T00:00:00Z",
            "body": "THIS ISSUE BODY MUST NOT LEAK",
        }

    def get_issue_comments(self, issue_number: int) -> list[dict[str, object]]:
        self.calls.append(("GET", f"issue/{issue_number}/comments"))
        return deepcopy(self.comments)


def result(args: tuple[str, ...], stdout: str = "", returncode: int = 0) -> observer.CommandResult:
    return observer.CommandResult(args, returncode, stdout, "" if returncode == 0 else "failure")


def git_responses(repo_root: Path) -> dict[tuple[str, ...], observer.CommandResult]:
    values = {
        ("git", "rev-parse", "--show-toplevel"): f"{repo_root.resolve()}\n",
        ("git", "branch", "--show-current"): (
            "codex/issue-287-cse-orchestrator-read-only-observer\n"
        ),
        ("git", "rev-parse", "HEAD"): f"{HEAD}\n",
        ("git", "rev-parse", "HEAD^"): f"{PARENT}\n",
        ("git", "rev-parse", "HEAD^{tree}"): f"{TREE}\n",
        ("git", "rev-parse", "refs/heads/master"): f"{HEAD}\n",
        ("git", "rev-parse", "refs/remotes/origin/master"): f"{HEAD}\n",
        ("git", "diff", "--name-status", "--cached"): "",
        ("git", "diff", "--name-status"): "",
        ("git", "remote", "get-url", "origin"): (
            "https://github.com/faliardic/chief-site-engineer.git\n"
        ),
        ("git", "ls-remote", "--heads", "origin", "refs/heads/master"): (
            f"{HEAD}\trefs/heads/master\n"
        ),
    }
    return {args: result(args, stdout) for args, stdout in values.items()}


def test_authorization_marker_and_fenced_json_parse() -> None:
    payload = authorization_payload()

    parsed = authorization.parse_authorization_comment(
        comment(101, payload),
        now=AUTH_NOW,
    )

    assert parsed.payload == payload
    assert parsed.comment_id == 101
    assert parsed.payload_hash == authorization.payload_sha256(payload)


def test_authorization_requires_schema_version_one() -> None:
    payload = authorization_payload()
    payload["schema_version"] = 2

    with pytest.raises(authorization.AuthorizationError, match="schema_version"):
        authorization.parse_authorization_comment(comment(101, payload), now=AUTH_NOW)


def test_authorization_rejects_unknown_and_missing_fields() -> None:
    unknown = authorization_payload()
    unknown["unexpected"] = True
    missing = authorization_payload()
    del missing["nonce"]

    with pytest.raises(authorization.AuthorizationError, match="unknown_fields"):
        authorization.parse_authorization_comment(comment(101, unknown), now=AUTH_NOW)
    with pytest.raises(authorization.AuthorizationError, match="missing_fields"):
        authorization.parse_authorization_comment(comment(101, missing), now=AUTH_NOW)


def test_authorization_rejects_duplicate_json_fields() -> None:
    body = (
        f"{authorization.AUTHORIZATION_MARKER}\n"
        "```json\n"
        '{"schema_version":1,"schema_version":1}\n'
        "```\n"
    )

    with pytest.raises(authorization.AuthorizationError, match="duplicate_field"):
        authorization.parse_authorization_comment({"id": 101, "body": body}, now=AUTH_NOW)


def test_authorization_rejects_transport_comment_id_mismatch() -> None:
    payload = authorization_payload(comment_id=999)

    with pytest.raises(authorization.AuthorizationError, match="comment_id_mismatch"):
        authorization.parse_authorization_comment(comment(101, payload), now=AUTH_NOW)


def test_canonical_payload_hash_is_sorted_utf8_json() -> None:
    payload = authorization_payload()
    reordered = dict(reversed(list(payload.items())))

    assert authorization.canonical_json_bytes(payload) == authorization.canonical_json_bytes(
        reordered
    )
    assert authorization.payload_sha256(payload) == authorization.payload_sha256(reordered)
    assert b" " not in authorization.canonical_json_bytes(payload)


def test_authorization_validates_required_types_and_nested_budget_schema() -> None:
    wrong_type = authorization_payload()
    wrong_type["write_allowlist"] = "not-a-list"
    wrong_budget = authorization_payload()
    wrong_budget["budgets"] = {"primary_max": 1, "unexpected": 2}

    with pytest.raises(authorization.AuthorizationError, match="write_allowlist"):
        authorization.parse_authorization_comment(comment(101, wrong_type), now=AUTH_NOW)
    with pytest.raises(authorization.AuthorizationError, match="budget_fields"):
        authorization.parse_authorization_comment(comment(101, wrong_budget), now=AUTH_NOW)


@pytest.mark.parametrize(
    ("field", "value", "reason"),
    [
        ("approval_level", "UNSUPPORTED", "approval_level_invalid"),
        ("capability", "Unknown", "capability_invalid"),
        ("pending_action", "different-action", "pending_action_mismatch"),
    ],
)
def test_authorization_validates_approval_capability_and_action(
    field: str,
    value: str,
    reason: str,
) -> None:
    payload = authorization_payload()
    payload[field] = value
    if field == "approval_level":
        payload["required_approval_level"] = value

    with pytest.raises(authorization.AuthorizationError, match=reason):
        authorization.parse_authorization_comment(comment(101, payload), now=AUTH_NOW)


def test_authorization_enforces_strict_utc_expiry() -> None:
    non_utc = authorization_payload()
    non_utc["expires_at"] = "2099-08-09T21:00:00+03:00"
    expired = authorization_payload()
    expired["expires_at"] = "2020-08-09T21:00:00Z"

    with pytest.raises(authorization.AuthorizationError, match="expires_at_utc"):
        authorization.parse_authorization_comment(comment(101, non_utc), now=AUTH_NOW)
    with pytest.raises(authorization.AuthorizationExpired, match="authorization_expired"):
        authorization.parse_authorization_comment(comment(101, expired), now=AUTH_NOW)


def test_authorization_selection_missing_valid_expired_and_invalid() -> None:
    missing = authorization.select_latest_authorization([comment(1)], now=AUTH_NOW)
    valid = authorization.select_latest_authorization(
        [comment(101, authorization_payload())],
        now=AUTH_NOW,
    )
    expired_payload = authorization_payload()
    expired_payload["expires_at"] = "2020-01-01T00:00:00Z"
    expired = authorization.select_latest_authorization(
        [comment(101, expired_payload)],
        now=AUTH_NOW,
    )
    invalid_payload = authorization_payload()
    invalid_payload["schema_version"] = 2
    invalid = authorization.select_latest_authorization(
        [comment(101, invalid_payload)],
        now=AUTH_NOW,
    )

    assert missing.status == "missing"
    assert valid.status == "valid"
    assert expired.status == "expired"
    assert invalid.status == "invalid"


def test_only_schema_valid_explicit_supersession_replaces_authorization() -> None:
    first = authorization_payload(101)
    replacement = authorization_payload(103)
    replacement["supersedes_comment_id"] = 101

    selected = authorization.select_latest_authorization(
        [comment(101, first), comment(102), comment(103, replacement)],
        now=AUTH_NOW,
    )

    assert selected.status == "valid"
    assert selected.comment_id == 103


def test_normal_or_invalid_newer_comment_cannot_expand_valid_authorization() -> None:
    first = authorization_payload(101)
    invalid = authorization_payload(103)
    invalid["supersedes_comment_id"] = 101
    invalid["unexpected"] = "scope expansion"

    selected = authorization.select_latest_authorization(
        [comment(101, first), comment(102), comment(103, invalid)],
        now=AUTH_NOW,
    )

    assert selected.status == "valid"
    assert selected.comment_id == 101


def test_git_observation_parses_root_branch_head_parent_and_tree(tmp_path: Path) -> None:
    runner = FakeRunner(git_responses(tmp_path))

    collected, blockers = observer.collect_git_observation(tmp_path, runner)

    assert blockers == []
    assert collected["branch"] == "codex/issue-287-cse-orchestrator-read-only-observer"
    assert collected["head_sha"] == HEAD
    assert collected["parent_sha"] == PARENT
    assert collected["tree_sha"] == TREE


def test_canonical_root_mismatch_is_provenance_blocker(tmp_path: Path) -> None:
    responses = git_responses(tmp_path)
    key = ("git", "rev-parse", "--show-toplevel")
    responses[key] = result(key, f"{tmp_path / 'different'}\n")

    _, blockers = observer.collect_git_observation(tmp_path, FakeRunner(responses))

    assert "PROVENANCE_MISMATCH" in blockers


def test_staged_and_tracked_lists_are_sorted_and_fingerprinted(tmp_path: Path) -> None:
    responses = git_responses(tmp_path)
    responses[("git", "diff", "--name-status", "--cached")] = result(
        ("git", "diff", "--name-status", "--cached"),
        "M\tz.py\nA\ta.py\n",
    )
    responses[("git", "diff", "--name-status")] = result(
        ("git", "diff", "--name-status"),
        "M\ty.py\nM\tb.py\n",
    )
    runner = FakeRunner(responses)

    first, _ = observer.collect_git_observation(tmp_path, runner)
    second, _ = observer.collect_git_observation(tmp_path, FakeRunner(responses))

    assert first["staged"] == ["A\ta.py", "M\tz.py"]
    assert first["tracked_worktree"] == ["M\tb.py", "M\ty.py"]
    assert first["tracked_fingerprint"] == second["tracked_fingerprint"]
    assert first["tracked_fingerprint"].startswith("sha256:")


def test_git_observation_never_enumerates_ignored_or_untracked(tmp_path: Path) -> None:
    runner = FakeRunner(git_responses(tmp_path))

    observer.collect_git_observation(tmp_path, runner)

    flattened = [" ".join(call) for call in runner.calls]
    assert not any("status --ignored" in call for call in flattened)
    assert not any("untracked-files" in call for call in flattened)
    assert not any("rglob" in call for call in flattened)


@pytest.mark.parametrize(
    "verb",
    [
        "fetch",
        "pull",
        "checkout",
        "switch",
        "reset",
        "stash",
        "clean",
        "add",
        "commit",
        "merge",
        "rebase",
        "cherry-pick",
        "push",
        "gc",
        "prune",
    ],
)
def test_mutating_git_command_families_are_rejected(verb: str) -> None:
    assert observer.is_allowed_read_only_command(("git", verb)) is False


def test_default_command_runner_refuses_mutation_before_subprocess(tmp_path: Path) -> None:
    with pytest.raises(ValueError, match="read_only_allowlist"):
        observer.run_read_only_command(("git", "fetch", "origin"), tmp_path)


@pytest.mark.parametrize(
    "args",
    [
        ("git", "rev-parse", "HEAD"),
        ("git", "branch", "--show-current"),
        ("git", "diff", "--name-status", "--cached"),
        ("git", "diff", "--name-status"),
        ("git", "remote", "get-url", "origin"),
        ("git", "ls-remote", "--heads", "origin", "refs/heads/master"),
        (
            "git",
            "ls-files",
            "--error-unmatch",
            "--",
            ".cse/tasks/287_task.md",
        ),
        ("git", "hash-object", "--", ".cse/state/project_state.json"),
    ],
)
def test_exact_read_only_git_command_shapes_are_allowed(args: tuple[str, ...]) -> None:
    assert observer.is_allowed_read_only_command(args) is True


def test_local_cached_and_live_master_equality_and_drift(tmp_path: Path) -> None:
    equal, equal_blockers = observer.collect_git_observation(
        tmp_path,
        FakeRunner(git_responses(tmp_path)),
    )
    responses = git_responses(tmp_path)
    key = ("git", "rev-parse", "refs/remotes/origin/master")
    responses[key] = result(key, f"{PARENT}\n")
    drift, drift_blockers = observer.collect_git_observation(tmp_path, FakeRunner(responses))

    assert equal["local_master_sha"] == equal["remote_master_sha"] == HEAD
    assert equal_blockers == []
    assert drift["origin_master_sha"] == PARENT
    assert "STATE_DRIFT" in drift_blockers


def test_live_remote_unavailable_is_source_failure(tmp_path: Path) -> None:
    responses = git_responses(tmp_path)
    key = ("git", "ls-remote", "--heads", "origin", "refs/heads/master")
    responses[key] = result(key, returncode=1)

    _, blockers = observer.collect_git_observation(tmp_path, FakeRunner(responses))

    assert "SOURCE_FAILURE" in blockers


def test_github_observation_uses_gets_and_metadata_hash_excludes_body() -> None:
    comments = [
        {
            "id": 2,
            "created_at": "2026-08-02T00:00:02Z",
            "updated_at": "2026-08-02T00:00:02Z",
            "body": "SECRET BODY TWO",
        },
        {
            "id": 1,
            "created_at": "2026-08-02T00:00:01Z",
            "updated_at": "2026-08-02T00:00:01Z",
            "body": "SECRET BODY ONE",
        },
    ]
    source = FakeGitHub(comments)

    collected, raw_comments, blockers = observer.collect_github_observation(
        "faliardic/chief-site-engineer",
        287,
        source,
    )

    assert blockers == []
    assert source.calls == [
        ("GET", "repository"),
        ("GET", "issue/287"),
        ("GET", "issue/287/comments"),
    ]
    assert collected["comment_count"] == 2
    assert "SECRET" not in json.dumps(collected)
    assert raw_comments[0]["body"]
    reordered = list(reversed(comments))
    assert collected["comments_metadata_hash"] == observer.comments_metadata_hash(reordered)


def test_gh_client_uses_get_only_and_paginates() -> None:
    calls: list[tuple[str, ...]] = []
    first_page = [{"id": value} for value in range(100)]

    def api_runner(args: tuple[str, ...]) -> observer.CommandResult:
        calls.append(args)
        endpoint = args[-1]
        page = parse_qs(urlsplit(endpoint).query).get("page", ["1"])
        if page == ["1"]:
            return observer.CommandResult(args, 0, json.dumps(first_page), "")
        if page == ["2"]:
            return observer.CommandResult(args, 0, json.dumps([{"id": 100}]), "")
        return observer.CommandResult(args, 0, "{}", "")

    client = observer.GhGitHubClient("faliardic/chief-site-engineer", api_runner=api_runner)

    comments = client.get_issue_comments(287)

    assert len(comments) == 101
    assert all(call[:4] == ("gh", "api", "--method", "GET") for call in calls)
    assert not any(any(word in call for word in ("POST", "PATCH", "DELETE")) for call in calls)


def test_exact_record_collector_reads_only_three_paths(tmp_path: Path) -> None:
    task = tmp_path / ".cse" / "tasks" / "287_task.md"
    state = tmp_path / ".cse" / "state" / "project_state.json"
    task.parent.mkdir(parents=True)
    state.parent.mkdir(parents=True)
    task.write_text("SECRET TASK CONTENT", encoding="utf-8")
    state.write_text("SECRET STATE CONTENT", encoding="utf-8")
    responses: dict[tuple[str, ...], observer.CommandResult] = {}
    for relative, sha in (
        (".cse/tasks/287_task.md", "a" * 40),
        (".cse/state/project_state.json", "b" * 40),
    ):
        ls_args = ("git", "ls-files", "--error-unmatch", "--", relative)
        hash_args = ("git", "hash-object", "--", relative)
        responses[ls_args] = result(ls_args, f"{relative}\n")
        responses[hash_args] = result(hash_args, f"{sha}\n")
    result_args = (
        "git",
        "ls-files",
        "--error-unmatch",
        "--",
        ".cse/results/287_result.md",
    )
    responses[result_args] = result(result_args, returncode=1)
    runner = FakeRunner(responses)

    records = observer.collect_exact_records(tmp_path, 287, runner)

    assert set(records) == {"task", "result", "project_state"}
    assert records["task"] == {
        "path": ".cse/tasks/287_task.md",
        "exists": True,
        "tracked": True,
        "blob_hash": "a" * 40,
        "content_included": False,
    }
    assert records["result"]["exists"] is False
    assert records["project_state"]["content_included"] is False
    assert all(call[1] in {"ls-files", "hash-object"} for call in runner.calls)
    assert all(".cse/" not in " ".join(call) or "287_" in " ".join(call) or "project_state.json" in " ".join(call) for call in runner.calls)


def test_runtime_root_inside_repository_is_user_data_risk(tmp_path: Path) -> None:
    assert observer.runtime_root_is_safe(tmp_path, tmp_path) is False
    assert observer.runtime_root_is_safe(tmp_path, tmp_path / "runtime") is False
    assert observer.runtime_root_is_safe(tmp_path, tmp_path.parent / "external-runtime") is True


def test_atomic_runtime_write_uses_sorted_json_and_os_replace(
    monkeypatch: pytest.MonkeyPatch,
    tmp_path: Path,
) -> None:
    runtime_root = tmp_path / "runtime"
    replacements: list[tuple[Path, Path]] = []
    real_replace = observer.os.replace

    def tracked_replace(source: str | Path, target: str | Path) -> None:
        replacements.append((Path(source), Path(target)))
        real_replace(source, target)

    monkeypatch.setattr(observer.os, "replace", tracked_replace)

    written, output_path = observer.write_observation_atomic(
        {"schema_version": 1, "z": 2, "a": 1},
        runtime_root,
        "run-001",
    )

    assert output_path == runtime_root / "runs" / "run-001" / "observation.json"
    assert replacements and replacements[0][1] == output_path
    assert not replacements[0][0].exists()
    text = output_path.read_text(encoding="utf-8")
    assert json.loads(text) == written
    assert text.index('"a"') < text.index('"z"')
    assert written["runtime_output_path"] == str(output_path)


def test_observation_valid_authorization_is_scope_validated(tmp_path: Path) -> None:
    payload = authorization_payload(101)
    observation = observer.observe_repository(
        repo_root=tmp_path,
        repository="faliardic/chief-site-engineer",
        issue_number=287,
        runtime_root=tmp_path.parent / "runtime",
        command_runner=FakeRunner(git_responses(tmp_path)),
        github_client=FakeGitHub([comment(101, payload)]),
        now=AUTH_NOW,
        run_id="run-valid",
        write_runtime=False,
    )

    assert observation["state"] == "SCOPE_VALIDATED"
    assert observation["exit_code"] == 0
    assert observation["blockers"] == []
    assert observation["authorization"]["status"] == "valid"


def test_observation_missing_authorization_is_clean_observing(tmp_path: Path) -> None:
    observation = observer.observe_repository(
        repo_root=tmp_path,
        repository="faliardic/chief-site-engineer",
        issue_number=287,
        runtime_root=tmp_path.parent / "runtime",
        command_runner=FakeRunner(git_responses(tmp_path)),
        github_client=FakeGitHub([comment(102)]),
        now=AUTH_NOW,
        run_id="run-missing",
        write_runtime=False,
    )

    assert observation["state"] == "OBSERVING"
    assert observation["exit_code"] == 0


def test_invalid_authorization_is_preflight_blocked_exit_twelve(tmp_path: Path) -> None:
    invalid = authorization_payload(101)
    invalid["schema_version"] = 2
    observation = observer.observe_repository(
        repo_root=tmp_path,
        repository="faliardic/chief-site-engineer",
        issue_number=287,
        runtime_root=tmp_path.parent / "runtime",
        command_runner=FakeRunner(git_responses(tmp_path)),
        github_client=FakeGitHub([comment(101, invalid)]),
        now=AUTH_NOW,
        run_id="run-invalid",
        write_runtime=False,
    )

    assert observation["state"] == "PREFLIGHT_BLOCKED"
    assert observation["exit_code"] == 12
    assert {item["code"] for item in observation["blockers"]} == {"APPROVAL_EXPIRED"}


@pytest.mark.parametrize("field", ["branch", "base_sha", "head_sha", "tree_sha"])
def test_authorization_source_mismatch_is_provenance_exit_thirteen(
    field: str,
    tmp_path: Path,
) -> None:
    payload = authorization_payload(101)
    payload[field] = "f" * 40 if field != "branch" else "wrong-branch"

    observation = observer.observe_repository(
        repo_root=tmp_path,
        repository="faliardic/chief-site-engineer",
        issue_number=287,
        runtime_root=tmp_path.parent / "runtime",
        command_runner=FakeRunner(git_responses(tmp_path)),
        github_client=FakeGitHub([comment(101, payload)]),
        now=AUTH_NOW,
        run_id=f"run-mismatch-{field}",
        write_runtime=False,
    )

    assert observation["exit_code"] == 13
    assert "PROVENANCE_MISMATCH" in {item["code"] for item in observation["blockers"]}


def test_authorization_comment_id_mismatch_is_provenance_exit_thirteen(
    tmp_path: Path,
) -> None:
    payload = authorization_payload(999)

    observation = observer.observe_repository(
        repo_root=tmp_path,
        repository="faliardic/chief-site-engineer",
        issue_number=287,
        runtime_root=tmp_path.parent / "runtime",
        command_runner=FakeRunner(git_responses(tmp_path)),
        github_client=FakeGitHub([comment(101, payload)]),
        now=AUTH_NOW,
        run_id="run-comment-mismatch",
        write_runtime=False,
    )

    assert observation["exit_code"] == 13
    assert observation["blockers"] == [
        {"code": "PROVENANCE_MISMATCH", "reason": "comment_id_mismatch"}
    ]


def test_blocker_precedence_keeps_all_blockers_and_uses_highest_exit(tmp_path: Path) -> None:
    responses = git_responses(tmp_path)
    origin_key = ("git", "rev-parse", "refs/remotes/origin/master")
    remote_key = ("git", "ls-remote", "--heads", "origin", "refs/heads/master")
    responses[origin_key] = result(origin_key, f"{PARENT}\n")
    responses[remote_key] = result(remote_key, returncode=1)
    invalid = authorization_payload(101)
    invalid["schema_version"] = 2

    observation = observer.observe_repository(
        repo_root=tmp_path,
        repository="faliardic/chief-site-engineer",
        issue_number=287,
        runtime_root=tmp_path / "unsafe-runtime",
        command_runner=FakeRunner(responses),
        github_client=FakeGitHub([comment(101, invalid)]),
        now=AUTH_NOW,
        run_id="run-precedence",
        write_runtime=False,
    )

    codes = [item["code"] for item in observation["blockers"]]
    assert codes[0] == "USER_DATA_RISK"
    assert {"USER_DATA_RISK", "APPROVAL_EXPIRED", "SOURCE_FAILURE"}.issubset(codes)
    assert observation["exit_code"] == 14


def test_master_drift_is_exit_ten_when_no_higher_blocker(tmp_path: Path) -> None:
    responses = git_responses(tmp_path)
    key = ("git", "rev-parse", "refs/remotes/origin/master")
    responses[key] = result(key, f"{PARENT}\n")

    observation = observer.observe_repository(
        repo_root=tmp_path,
        repository="faliardic/chief-site-engineer",
        issue_number=287,
        runtime_root=tmp_path.parent / "runtime",
        command_runner=FakeRunner(responses),
        github_client=FakeGitHub(),
        now=AUTH_NOW,
        run_id="run-drift",
        write_runtime=False,
    )

    assert observation["exit_code"] == 10
    assert observation["blockers"] == [{"code": "STATE_DRIFT", "reason": "master_sha_mismatch"}]


def test_source_failure_is_exit_eleven_when_live_remote_fails(tmp_path: Path) -> None:
    responses = git_responses(tmp_path)
    key = ("git", "ls-remote", "--heads", "origin", "refs/heads/master")
    responses[key] = result(key, returncode=1)

    observation = observer.observe_repository(
        repo_root=tmp_path,
        repository="faliardic/chief-site-engineer",
        issue_number=287,
        runtime_root=tmp_path.parent / "runtime",
        command_runner=FakeRunner(responses),
        github_client=FakeGitHub(),
        now=AUTH_NOW,
        run_id="run-source-failure",
        write_runtime=False,
    )

    assert observation["exit_code"] == 11


def test_observation_output_is_sanitized_and_contains_no_raw_command_or_comment_body(
    tmp_path: Path,
) -> None:
    payload = authorization_payload(101)
    comments = [comment(101, payload)]
    comments[0]["body"] = str(comments[0]["body"]) + "\nSUPERSECRET"
    responses = git_responses(tmp_path)
    responses[("git", "diff", "--name-status")] = observer.CommandResult(
        ("git", "diff", "--name-status"),
        0,
        "M\tsafe.py\n",
        "RAW STDERR SECRET",
    )

    observation = observer.observe_repository(
        repo_root=tmp_path,
        repository="faliardic/chief-site-engineer",
        issue_number=287,
        runtime_root=tmp_path.parent / "runtime",
        command_runner=FakeRunner(responses),
        github_client=FakeGitHub(comments),
        now=AUTH_NOW,
        run_id="run-sanitized",
        write_runtime=False,
    )
    rendered = json.dumps(observation, sort_keys=True)

    assert "SUPERSECRET" not in rendered
    assert "RAW STDERR SECRET" not in rendered
    assert "THIS ISSUE BODY MUST NOT LEAK" not in rendered
    assert "comment_body" not in rendered


def test_runtime_write_does_not_change_repository_files(tmp_path: Path) -> None:
    sentinel = tmp_path / "sentinel.txt"
    sentinel.write_text("unchanged", encoding="utf-8")
    before = sentinel.read_bytes()

    observation = observer.observe_repository(
        repo_root=tmp_path,
        repository="faliardic/chief-site-engineer",
        issue_number=287,
        runtime_root=tmp_path.parent / "runtime-output",
        command_runner=FakeRunner(git_responses(tmp_path)),
        github_client=FakeGitHub(),
        now=AUTH_NOW,
        run_id="run-write",
        write_runtime=True,
    )

    assert sentinel.read_bytes() == before
    output_path = Path(observation["runtime_output_path"])
    assert output_path.is_file()
    assert tmp_path.resolve() not in output_path.resolve().parents


def test_cli_observe_prints_parseable_sorted_json(
    monkeypatch: pytest.MonkeyPatch,
    capsys: pytest.CaptureFixture[str],
    tmp_path: Path,
) -> None:
    expected = {"schema_version": 1, "state": "OBSERVING", "exit_code": 0}
    monkeypatch.setattr(cli, "observe_repository", lambda **kwargs: expected)

    exit_code = cli.main(
        [
            "observe",
            "--repo-root",
            str(tmp_path),
            "--repository",
            "faliardic/chief-site-engineer",
            "--issue",
            "287",
            "--runtime-root",
            str(tmp_path.parent / "runtime"),
        ]
    )

    captured = capsys.readouterr()
    assert exit_code == 0
    assert json.loads(captured.out) == expected
    assert captured.out.index('"exit_code"') < captured.out.index('"schema_version"')
    assert captured.err == ""


def test_cli_supports_only_observe_and_usage_errors_exit_two() -> None:
    parser = cli.build_parser()

    with pytest.raises(SystemExit) as exc_info:
        parser.parse_args(["mutate"])

    assert exc_info.value.code == 2
