from __future__ import annotations

import json
from pathlib import Path

import pytest

from tools.cse_orchestrator.api_planner import (
    PROPOSAL_JSON_SCHEMA,
    ApiProposalError,
    ProposalContract,
)
from tools.cse_orchestrator.automation import (
    ApiAutomationEngine,
    AutomationStatus,
    validate_api_proposal,
)
from tools.cse_orchestrator.cli import build_parser
from tools.cse_orchestrator.codex_adapter import (
    CodexChildAdapter,
    CodexChildRequest,
    CodexProcessResult,
    CodexAdapterError,
)
from tools.cse_orchestrator.github_rest import (
    GitHubRestClient,
    GitHubRestContract,
    GitHubRestError,
    GitHubRestTemplate,
    GitProcessResult,
    HostPublisher,
    HostPublishRequest,
    RestResponse,
)
from tools.cse_orchestrator.openai_client import (
    HttpResponse,
    OpenAIClientError,
    OpenAIResponsesClient,
)
from tools.cse_orchestrator.policy import PolicyDecision


FIXTURE = Path("tests/fixtures/cse_orchestrator/api_plan_response.json")
FP = "sha256:" + "1" * 64
HEAD = "1" * 40


def proposal() -> dict[str, object]:
    value = json.loads(FIXTURE.read_text(encoding="utf-8"))
    return {key: value[key] for key in ("decision", "summary", "risk", "codex_prompt")}


def contract() -> ProposalContract:
    value = json.loads(FIXTURE.read_text(encoding="utf-8"))
    return ProposalContract(
        capability="Code + Network + Publish",
        write_allowlist=tuple(value["write_allowlist"]),
        validation_commands=tuple(value["validation_commands"]),
        commit_message=str(value["commit_message"]),
        pr_title=str(value["pr_title"]),
        pr_body_prefix=str(value["pr_body_prefix"]),
        required_approval_level=str(value["required_approval_level"]),
        api_request_budget=1,
        codex_child_budget=1,
        github_pr_budget=1,
        source_fingerprint=FP,
        contract_fingerprint="sha256:" + "2" * 64,
        action_fingerprint=FP,
    )


def allowed_decision() -> PolicyDecision:
    return PolicyDecision(
        allowed=True,
        state_from="AWAITING_APPROVAL",
        state_to="ACTION_AUTHORIZED",
        required_approval_level="CODE_CHANGE",
        budget_delta={"api_request": 1, "codex_child": 1, "github_pr": 1},
    )


class FakeHttpTransport:
    def __init__(self, response: HttpResponse) -> None:
        self.response = response
        self.calls: list[dict[str, object]] = []

    def post(self, url, *, headers, body, timeout_seconds):
        self.calls.append(
            {"url": url, "headers": headers, "body": body, "timeout": timeout_seconds}
        )
        return self.response


def api_response(value: dict[str, object] | None = None, **overrides) -> HttpResponse:
    body = {
        "id": "resp_299",
        "status": "completed",
        "model": "model-from-environment",
        "output": [
            {
                "type": "message",
                "content": [
                    {"type": "output_text", "text": json.dumps(value or proposal())}
                ],
            }
        ],
        "usage": {"input_tokens": 10, "output_tokens": 20, "total_tokens": 30},
    }
    body.update(overrides)
    return HttpResponse(200, {"x-request-id": "req_299"}, json.dumps(body).encode())


def test_openai_request_is_strict_non_stored_and_environment_driven():
    transport = FakeHttpTransport(api_response())
    client = OpenAIResponsesClient.from_environment(
        {"OPENAI_API_KEY": "secret-value", "OPENAI_MODEL": "model-from-environment"},
        transport=transport,
    )
    result = client.request_proposal("bounded prompt", execute=True)
    sent = json.loads(transport.calls[0]["body"])
    assert transport.calls[0]["url"] == "https://api.openai.com/v1/responses"
    assert sent["model"] == "model-from-environment"
    assert sent["store"] is False
    assert sent["text"]["format"]["type"] == "json_schema"
    assert sent["text"]["format"]["strict"] is True
    assert sent["text"]["format"]["schema"] == PROPOSAL_JSON_SCHEMA
    assert result.metadata.total_tokens == 30
    assert "secret-value" not in json.dumps(result.public_dict())


def test_openai_default_dry_run_does_not_call_transport():
    transport = FakeHttpTransport(api_response())
    client = OpenAIResponsesClient("key", "model", transport=transport)
    result = client.request_proposal("prompt")
    assert result.executed is False
    assert transport.calls == []


@pytest.mark.parametrize(
    ("environment", "reason"),
    [
        ({"OPENAI_MODEL": "m"}, "OPENAI_API_KEY"),
        ({"OPENAI_API_KEY": "k"}, "OPENAI_MODEL"),
    ],
)
def test_openai_credentials_are_required_from_environment(environment, reason):
    with pytest.raises(OpenAIClientError, match=reason):
        OpenAIResponsesClient.from_environment(environment, transport=FakeHttpTransport(api_response()))


def test_openai_duplicate_request_is_rejected_without_second_call():
    transport = FakeHttpTransport(api_response())
    client = OpenAIResponsesClient("key", "model", transport=transport)
    client.request_proposal("prompt", execute=True)
    with pytest.raises(OpenAIClientError, match="duplicate_api_request"):
        client.request_proposal("prompt", execute=True)
    assert len(transport.calls) == 1


@pytest.mark.parametrize(
    ("response", "reason"),
    [
        (HttpResponse(429, {}, b"{}"), "rate_limited"),
        (HttpResponse(500, {}, b"{}"), "api_error"),
        (api_response(status="incomplete", incomplete_details={"reason": "max_output_tokens"}), "incomplete_response"),
        (api_response(output=[{"content": [{"type": "refusal", "refusal": "no"}]}]), "refusal"),
    ],
)
def test_openai_errors_fail_closed(response, reason):
    client = OpenAIResponsesClient("key", "model", transport=FakeHttpTransport(response))
    with pytest.raises(OpenAIClientError, match=reason):
        client.request_proposal("prompt", execute=True)


def test_proposal_validation_accepts_exact_contract():
    validated = validate_api_proposal(proposal(), contract(), allowed_decision())
    assert validated.decision == "proceed"
    assert validated.write_allowlist == contract().write_allowlist
    assert validated.validation_commands == contract().validation_commands
    assert validated.commit_message == contract().commit_message
    assert validated.pr_title == contract().pr_title
    assert validated.required_approval_level == contract().required_approval_level


@pytest.mark.parametrize(
    ("mutation", "reason"),
    [
        (lambda value: value.update({"unknown": True}), "proposal_fields_invalid"),
        (lambda value: value.update({"write_allowlist": ["outside.txt"]}), "proposal_fields_invalid"),
        (lambda value: value.update({"validation_commands": ["rm -rf ."]}), "proposal_fields_invalid"),
        (lambda value: value.update({"required_approval_level": "PUBLISH"}), "proposal_fields_invalid"),
    ],
)
def test_proposal_cannot_expand_local_contract(mutation, reason):
    value = proposal()
    mutation(value)
    with pytest.raises(ApiProposalError, match=reason):
        validate_api_proposal(value, contract(), allowed_decision())


def test_policy_deny_blocks_proposal():
    denied = PolicyDecision(False, "AWAITING_APPROVAL", "BLOCKED", "CODE_CHANGE")
    with pytest.raises(ApiProposalError, match="policy_denied"):
        validate_api_proposal(proposal(), contract(), denied)


class FakeCodexProcess:
    def __init__(self, result: CodexProcessResult | None = None) -> None:
        self.result = result or CodexProcessResult(0, b"done", b"", False, False)
        self.calls: list[dict[str, object]] = []

    def run(self, argv, *, cwd, environment, prompt, timeout_seconds, output_limit_bytes):
        self.calls.append(
            {
                "argv": argv,
                "cwd": cwd,
                "environment": environment,
                "prompt": prompt,
                "timeout": timeout_seconds,
                "limit": output_limit_bytes,
            }
        )
        return self.result


def child_request(tmp_path: Path) -> CodexChildRequest:
    repo = tmp_path / "repo"
    runtime = tmp_path / "runtime"
    repo.mkdir()
    runtime.mkdir()
    return CodexChildRequest(
        action_fingerprint=FP,
        repo_root=repo,
        runtime_root=runtime,
        prompt="perform exact authorized change",
        help_output="Usage: codex exec [OPTIONS] [PROMPT]\n  -  Read prompt from stdin",
        environment_allowlist=("PATH", "SYSTEMROOT"),
        timeout_seconds=120,
        output_limit_bytes=262144,
    )


def test_codex_child_uses_exact_stdin_argv_cwd_and_bounds(tmp_path):
    executable = tmp_path / "bin" / "codex.cmd"
    executable.parent.mkdir()
    executable.write_text("stub", encoding="utf-8")
    process = FakeCodexProcess()
    adapter = CodexChildAdapter(process, executable_resolver=lambda _: str(executable))
    result = adapter.execute(child_request(tmp_path), execute=True, environment={"PATH": "p", "SECRET": "x"})
    call = process.calls[0]
    assert call["argv"] == (str(executable.resolve()), "exec", "-")
    assert call["cwd"] == (tmp_path / "repo").resolve()
    assert call["environment"] == {"PATH": "p"}
    assert call["timeout"] == 120 and call["limit"] == 262144
    assert result.status == "PASS"
    assert list((tmp_path / "runtime").rglob("*prompt*")) == []


@pytest.mark.parametrize("name", ["codex", "codex.exe", "codex.cmd"])
def test_codex_executable_resolution_accepts_only_safe_platform_names(tmp_path, name):
    executable = tmp_path / "bin" / name
    executable.parent.mkdir()
    executable.write_text("stub", encoding="utf-8")
    process = FakeCodexProcess()
    CodexChildAdapter(process, executable_resolver=lambda _: str(executable)).execute(
        child_request(tmp_path), execute=True
    )
    assert process.calls[0]["argv"][0] == str(executable.resolve())


def test_codex_executable_resolution_rejects_repo_path_and_arbitrary_name(tmp_path):
    request = child_request(tmp_path)
    for executable in (request.repo_root / "codex", tmp_path / "bin" / "runner"):
        executable.parent.mkdir(exist_ok=True)
        executable.write_text("stub", encoding="utf-8")
        with pytest.raises(CodexAdapterError, match="codex_executable"):
            CodexChildAdapter(
                FakeCodexProcess(), executable_resolver=lambda _, p=executable: str(p)
            ).execute(request, execute=True)


def test_codex_default_dry_run_and_duplicate_guard(tmp_path):
    executable = tmp_path / "bin" / "codex"
    executable.parent.mkdir()
    executable.write_text("stub", encoding="utf-8")
    process = FakeCodexProcess()
    adapter = CodexChildAdapter(process, executable_resolver=lambda _: str(executable))
    request = child_request(tmp_path)
    assert adapter.execute(request).status == "DRY_RUN"
    adapter.execute(request, execute=True)
    with pytest.raises(RuntimeError, match="duplicate_codex_child"):
        adapter.execute(request, execute=True)
    assert len(process.calls) == 1


@pytest.mark.parametrize(
    ("result", "status"),
    [
        (CodexProcessResult(None, b"", b"missing", False, False), "CLI_UNAVAILABLE"),
        (CodexProcessResult(1, b"", b"authentication failed", False, False), "AUTHENTICATION_FAILURE"),
        (CodexProcessResult(1, b"", b"failed", False, False), "CHILD_FAILED"),
        (CodexProcessResult(None, b"", b"timeout", True, False), "TIMEOUT"),
    ],
)
def test_codex_failures_are_classified(tmp_path, result, status):
    executable = tmp_path / "bin" / "codex"
    executable.parent.mkdir()
    executable.write_text("stub", encoding="utf-8")
    outcome = CodexChildAdapter(
        FakeCodexProcess(result), executable_resolver=lambda _: str(executable)
    ).execute(
        child_request(tmp_path), execute=True
    )
    assert outcome.status == status


class FakeRestTransport:
    def __init__(self, get_response=None, post_response=None) -> None:
        self.get_response = get_response or RestResponse(200, {}, b"[]")
        self.post_response = post_response or RestResponse(
            201, {"x-github-request-id": "gh_299"}, b'{"number": 300,"state":"open","draft":true}'
        )
        self.calls: list[tuple[str, str, object]] = []

    def request(self, method, url, *, headers, body, timeout_seconds):
        self.calls.append((method, url, body))
        return self.get_response if method == "GET" else self.post_response


def rest_contract(**overrides) -> GitHubRestContract:
    values = dict(
        repository="faliardic/chief-site-engineer",
        branch="codex/issue-299-cse-orchestrator-api-automation",
        base_branch="master",
        head_sha=HEAD,
        remote_head_sha=HEAD,
        remote_divergence=(0, 0),
        issue=299,
        title="Complete API-driven CSE orchestrator automation",
        body="Closes #299\n\nO9 controlled automation.",
        draft=True,
    )
    values.update(overrides)
    return GitHubRestContract(**values)


def test_github_rest_creates_only_one_draft_pr():
    transport = FakeRestTransport()
    client = GitHubRestClient.from_environment({"GITHUB_TOKEN": "secret"}, transport=transport)
    result = client.create_draft_pull_request(rest_contract(), execute=True)
    payload = json.loads(transport.calls[1][2])
    assert [call[0] for call in transport.calls] == ["GET", "POST"]
    assert payload["draft"] is True and payload["base"] == "master"
    assert result.number == 300
    assert "secret" not in json.dumps(result.public_dict())
    with pytest.raises(GitHubRestError, match="duplicate_github_request"):
        client.create_draft_pull_request(rest_contract(), execute=True)
    assert len(transport.calls) == 2


@pytest.mark.parametrize(
    ("value", "reason"),
    [
        ({"remote_divergence": (0, 1)}, "remote_divergence"),
        ({"remote_head_sha": "2" * 40}, "head_drift"),
        ({"draft": False}, "draft_required"),
        ({"body": "Ready #299"}, "issue_prefix_invalid"),
    ],
)
def test_github_rest_contract_drift_fails_before_network(value, reason):
    transport = FakeRestTransport()
    client = GitHubRestClient("token", transport=transport)
    with pytest.raises(GitHubRestError, match=reason):
        client.create_draft_pull_request(rest_contract(**value), execute=True)
    assert transport.calls == []


def test_github_existing_pr_blocks_creation():
    transport = FakeRestTransport(get_response=RestResponse(200, {}, b'[{"number":286}]'))
    client = GitHubRestClient("token", transport=transport)
    with pytest.raises(GitHubRestError, match="existing_open_pr"):
        client.create_draft_pull_request(rest_contract(), execute=True)
    assert [call[0] for call in transport.calls] == ["GET"]


class FakeGitProcess:
    def __init__(self, branch: str, base: str, paths: tuple[str, ...]) -> None:
        self.branch = branch
        self.base = base
        self.head = base
        self.paths = paths
        self.calls: list[tuple[str, ...]] = []

    def run(self, argv, *, cwd, timeout_seconds, output_limit_bytes):
        self.calls.append(argv)
        answers = {
            ("git", "branch", "--show-current"): self.branch + "\n",
            ("git", "rev-parse", "HEAD"): self.head + "\n",
            ("git", "rev-parse", "origin/master"): self.base + "\n",
            ("git", "diff", "--name-only"): "\n".join(self.paths) + "\n",
            ("git", "diff", "--cached", "--name-only"): "",
            ("git", "status", "--porcelain", "--untracked-files=all"): "\n".join(
                f" M {path}" for path in self.paths
            ) + "\n",
            ("git", "merge-base", "HEAD", "origin/master"): self.base + "\n",
            ("git", "diff", "--cached", "--check"): "",
        }
        if argv[:3] == ("git", "add", "--"):
            return GitProcessResult(0, b"", b"", False, False)
        if argv[:2] == ("git", "commit"):
            self.head = "2" * 40
            return GitProcessResult(0, b"committed", b"", False, False)
        if argv[:3] == ("git", "push", "origin"):
            return GitProcessResult(0, b"pushed", b"", False, False)
        if argv == ("git", "rev-parse", f"origin/{self.branch}"):
            return GitProcessResult(0, (self.head + "\n").encode(), b"", False, False)
        if argv == ("git", "rev-list", "--left-right", "--count", f"origin/{self.branch}...HEAD"):
            return GitProcessResult(0, b"0\t0\n", b"", False, False)
        if argv == ("git", "rev-list", "--left-right", "--count", "origin/master...HEAD"):
            return GitProcessResult(0, b"0\t1\n", b"", False, False)
        if argv == ("git", "diff", "--cached", "--name-only") and any(
            call[:3] == ("git", "add", "--") for call in self.calls
        ):
            return GitProcessResult(0, ("\n".join(self.paths) + "\n").encode(), b"", False, False)
        if argv == ("git", "status", "--porcelain", "--untracked-files=all") and self.head != self.base:
            return GitProcessResult(0, b"", b"", False, False)
        return GitProcessResult(0, answers.get(argv, "").encode(), b"", False, False)


def publish_request(tmp_path: Path) -> HostPublishRequest:
    paths = ("tools/cse_orchestrator/automation.py", "tests/test_cse_orchestrator_api_automation.py")
    for path in paths:
        candidate = tmp_path / path
        candidate.parent.mkdir(parents=True, exist_ok=True)
        candidate.write_text(path, encoding="utf-8")
    return HostPublishRequest(
        repo_root=tmp_path,
        branch="codex/issue-301-cse-orchestrator-live-api-pilot",
        expected_base_sha="1" * 40,
        write_allowlist=paths,
        validation_argv=(("python", "-m", "compileall", "tools/cse_orchestrator"),),
        commit_message="Complete live API-driven orchestrator pilot",
        github=GitHubRestTemplate(
            repository="faliardic/chief-site-engineer",
            branch="codex/issue-301-cse-orchestrator-live-api-pilot",
            base_branch="master",
            expected_base_sha="1" * 40,
            issue=301,
            title="Complete live API-driven orchestrator pilot",
            body="Closes #301\n\nPre-live pilot.",
            draft=True,
        ),
    )


def test_host_publisher_validates_stages_commits_pushes_and_resolves_provenance(tmp_path):
    request = publish_request(tmp_path)
    process = FakeGitProcess(request.branch, request.expected_base_sha, request.write_allowlist)
    contract = HostPublisher(process).publish(request, execute=True)
    assert contract.head_sha == "2" * 40
    assert contract.remote_head_sha == contract.head_sha
    assert contract.remote_divergence == (0, 0)
    assert [call for call in process.calls if call[:2] == ("git", "commit")] == [
        ("git", "commit", "-m", request.commit_message)
    ]
    assert [call for call in process.calls if call[:2] == ("git", "push")] == [
        ("git", "push", "origin", request.branch)
    ]


def test_host_preflight_accepts_authorized_dirty_baseline_and_detects_content_drift(tmp_path):
    request = publish_request(tmp_path)
    process = FakeGitProcess(request.branch, request.expected_base_sha, request.write_allowlist)
    publisher = HostPublisher(process)
    publisher.preflight(request, execute=True)
    publisher.verify_baseline(request, execute=True)
    (tmp_path / request.write_allowlist[0]).write_text("changed", encoding="utf-8")
    with pytest.raises(GitHubRestError, match="baseline_fingerprint_drift"):
        publisher.verify_baseline(request, execute=True)


def test_host_publisher_dry_run_has_no_process_calls(tmp_path):
    request = publish_request(tmp_path)
    process = FakeGitProcess(request.branch, request.expected_base_sha, request.write_allowlist)
    assert HostPublisher(process).publish(request).head_sha == request.expected_base_sha
    assert process.calls == []


def test_host_publisher_rejects_mutating_validation_argv(tmp_path):
    request = publish_request(tmp_path)
    request = HostPublishRequest(
        **{**request.__dict__, "validation_argv": (("git", "reset", "--hard"),)}
    )
    with pytest.raises(GitHubRestError, match="validation_argv_forbidden"):
        HostPublisher(FakeGitProcess(request.branch, request.expected_base_sha, request.write_allowlist)).publish(request)


class FakeHostPublisher:
    def __init__(self, resolved: GitHubRestContract) -> None:
        self.resolved = resolved
        self.preflight_calls = 0
        self.verify_calls = 0
        self.publish_calls = 0

    def preflight(self, request, *, execute=False):
        self.preflight_calls += 1

    def verify_baseline(self, request, *, execute=False):
        self.verify_calls += 1

    def publish(self, request, *, execute=False):
        self.publish_calls += 1
        return self.resolved


def test_automation_defaults_to_dry_run_without_adapter_calls(tmp_path):
    openai_transport = FakeHttpTransport(api_response())
    openai = OpenAIResponsesClient("key", "model", transport=openai_transport)
    process = FakeCodexProcess()
    rest = FakeRestTransport()
    engine = ApiAutomationEngine(
        openai_client=openai,
        codex_adapter=CodexChildAdapter(process),
        github_client=GitHubRestClient("token", transport=rest),
    )
    result = engine.run(
        prompt="plan exact work",
        proposal_contract=contract(),
        policy_decision=allowed_decision(),
        codex_request=child_request(tmp_path),
        github_contract=rest_contract(),
    )
    assert result.status is AutomationStatus.DRY_RUN
    assert openai_transport.calls == [] and process.calls == [] and rest.calls == []


def test_automation_rejects_model_attempt_to_control_immutable_scope(tmp_path):
    expanded = proposal()
    expanded["write_allowlist"] = ["outside.txt"]
    openai = OpenAIResponsesClient("key", "model", transport=FakeHttpTransport(api_response(expanded)))
    process = FakeCodexProcess()
    engine = ApiAutomationEngine(
        openai_client=openai,
        codex_adapter=CodexChildAdapter(process),
        github_client=GitHubRestClient("token", transport=FakeRestTransport()),
    )
    result = engine.run(
        prompt="plan",
        proposal_contract=contract(),
        policy_decision=allowed_decision(),
        codex_request=child_request(tmp_path),
        github_contract=rest_contract(),
        execute=True,
    )
    assert result.status is AutomationStatus.BLOCKED
    assert result.reason == "proposal_fields_invalid"
    assert process.calls == []


def test_automation_rejects_fingerprint_drift_before_api(tmp_path):
    openai_transport = FakeHttpTransport(api_response())
    engine = ApiAutomationEngine(
        openai_client=OpenAIResponsesClient("key", "model", transport=openai_transport),
        codex_adapter=CodexChildAdapter(FakeCodexProcess()),
        github_client=GitHubRestClient("token", transport=FakeRestTransport()),
    )
    request = child_request(tmp_path)
    request = CodexChildRequest(
        **{**request.__dict__, "action_fingerprint": "sha256:" + "3" * 64}
    )
    result = engine.run(
        prompt="plan",
        proposal_contract=contract(),
        policy_decision=allowed_decision(),
        codex_request=request,
        github_contract=rest_contract(),
        execute=True,
    )
    assert result.status is AutomationStatus.BLOCKED
    assert result.reason == "action_fingerprint_drift"
    assert openai_transport.calls == []


def test_automation_publish_chain_requires_explicit_publish(tmp_path):
    openai = OpenAIResponsesClient("key", "model", transport=FakeHttpTransport(api_response()))
    process = FakeCodexProcess()
    rest = FakeRestTransport()
    engine = ApiAutomationEngine(
        openai_client=openai,
        codex_adapter=CodexChildAdapter(process),
        github_client=GitHubRestClient("token", transport=rest),
        host_publisher=FakeHostPublisher(rest_contract()),
    )
    request = publish_request(tmp_path)
    local_contract = contract()
    local_contract = ProposalContract(
        **{
            **local_contract.__dict__,
            "write_allowlist": request.write_allowlist,
            "validation_commands": tuple(" ".join(argv) for argv in request.validation_argv),
            "commit_message": request.commit_message,
            "pr_title": request.github.title,
            "pr_body_prefix": "Closes #301",
        }
    )
    result = engine.run(
        prompt="plan",
        proposal_contract=local_contract,
        policy_decision=allowed_decision(),
        codex_request=child_request(tmp_path),
        host_publish_request=request,
        execute=True,
        publish=True,
    )
    assert result.status is AutomationStatus.PUBLISHED
    assert len(process.calls) == 1
    assert [call[0] for call in rest.calls] == ["GET", "POST"]
    assert engine._host.preflight_calls == 1
    assert engine._host.verify_calls == 1
    assert engine._host.publish_calls == 1


@pytest.mark.parametrize(
    ("field", "reason"),
    [
        ("write_allowlist", "host_write_allowlist_drift"),
        ("validation_argv", "host_validation_commands_drift"),
        ("commit_message", "host_commit_message_drift"),
        ("pr_title", "host_pr_title_drift"),
        ("pr_body_prefix", "host_pr_body_prefix_drift"),
    ],
)
def test_automation_rejects_host_drift_from_local_contract_before_api(tmp_path, field, reason):
    request = publish_request(tmp_path)
    local = contract()
    matching = {
        **local.__dict__,
        "write_allowlist": request.write_allowlist,
        "validation_commands": tuple(" ".join(argv) for argv in request.validation_argv),
        "commit_message": request.commit_message,
        "pr_title": request.github.title,
        "pr_body_prefix": "Closes #301",
    }
    local = ProposalContract(**matching)
    if field == "write_allowlist":
        request = HostPublishRequest(**{**request.__dict__, field: ("outside.txt",)})
    elif field == "validation_argv":
        request = HostPublishRequest(
            **{**request.__dict__, field: (("python", "-m", "pytest", "outside"),)}
        )
    elif field == "commit_message":
        request = HostPublishRequest(**{**request.__dict__, field: "Different commit"})
    else:
        github = GitHubRestTemplate(
            **{
                **request.github.__dict__,
                "title" if field == "pr_title" else "body": "Different value",
            }
        )
        request = HostPublishRequest(**{**request.__dict__, "github": github})
    transport = FakeHttpTransport(api_response())
    result = ApiAutomationEngine(
        openai_client=OpenAIResponsesClient("key", "model", transport=transport),
        codex_adapter=CodexChildAdapter(FakeCodexProcess()),
        github_client=GitHubRestClient("token", transport=FakeRestTransport()),
    ).run(
        prompt="plan",
        proposal_contract=local,
        policy_decision=allowed_decision(),
        codex_request=child_request(tmp_path),
        host_publish_request=request,
        execute=True,
        publish=True,
    )
    assert result.status is AutomationStatus.BLOCKED
    assert result.reason == reason
    assert transport.calls == []


def test_api_run_cli_defaults_to_dry_run_and_has_separate_execute_gates(tmp_path):
    args = build_parser().parse_args(
        [
            "api-run",
            "--contract",
            str(tmp_path / "contract.json"),
            "--repo-root",
            str(tmp_path / "repo"),
            "--runtime-root",
            str(tmp_path / "runtime"),
        ]
    )
    assert args.command == "api-run"
    assert args.execute_api is False
    assert args.execute_codex is False
    assert args.execute_publish is False
