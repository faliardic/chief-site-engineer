from __future__ import annotations

import builtins
import copy
import hashlib
import json
import socket
import subprocess

import pytest

from tools.cse_orchestrator import results


FAMILIES = (
    "pytest",
    "compileall",
    "git_diff_check",
    "flutter_test",
    "flutter_analyze",
    "build",
    "generic_command",
)


def command_result(**updates: object) -> dict[str, object]:
    value: dict[str, object] = {
        "schema_version": 1,
        "command_family": "pytest",
        "action_started": True,
        "wrapper_failed": False,
        "exit_code": 0,
        "duration_ms": 1234,
        "stdout": "10 passed, 1 skipped, 2 warnings in 0.12s\n",
        "stderr": "",
        "truncated": False,
        "timed_out": False,
        "failed_stage": None,
    }
    value.update(updates)
    return value


@pytest.mark.parametrize(
    ("family", "stdout", "exit_code", "expected_failure"),
    [
        ("pytest", "3 passed in 0.01s\n", 0, None),
        ("pytest", "1 failed, 2 passed in 0.02s\n", 1, "test"),
        ("compileall", "Listing 'tools'...\n", 0, None),
        ("compileall", "*** Error compiling 'bad.py'...\nSyntaxError\n", 1, "source"),
        ("git_diff_check", "", 0, None),
        ("git_diff_check", "file.py:1: trailing whitespace.\n", 2, "source"),
        ("flutter_test", "00:01 +4: All tests passed!\n", 0, None),
        ("flutter_test", "00:01 +3 -1: Some tests failed.\n", 1, "test"),
        ("flutter_analyze", "No issues found! (ran in 1.0s)\n", 0, None),
        ("flutter_analyze", "2 issues found. (ran in 1.0s)\n", 1, "analyze"),
        ("build", "BUILD SUCCESSFUL in 2s\n", 0, None),
        ("build", "FAILURE: Build failed with an exception.\n", 1, "build"),
        ("generic_command", "done\n", 0, None),
        ("generic_command", "operation failed\n", 1, "unknown"),
    ],
)
def test_every_command_family_has_deterministic_pass_and_fail_results(
    family: str,
    stdout: str,
    exit_code: int,
    expected_failure: str | None,
) -> None:
    parsed = results.parse_command_result(
        command_result(command_family=family, stdout=stdout, exit_code=exit_code)
    )

    assert parsed.command_family == family
    assert parsed.failure_class == expected_failure
    assert parsed.budget_consumed is True


@pytest.mark.parametrize(
    ("stdout", "exit_code", "counts", "reason"),
    [
        (
            "================ 10 passed, 1 skipped, 2 warnings in 0.10s ================\n",
            0,
            {"passed": 10, "failed": 0, "skipped": 1, "errors": 0, "warnings": 2, "total": 11},
            None,
        ),
        (
            "================ 2 failed, 4 passed, 1 error in 0.20s ================\n",
            1,
            {"passed": 4, "failed": 2, "skipped": 0, "errors": 1, "warnings": 0, "total": 7},
            None,
        ),
        (
            "no tests ran in 0.01s\n",
            5,
            {"passed": 0, "failed": 0, "skipped": 0, "errors": 0, "warnings": 0, "total": 0},
            "no_tests_collected",
        ),
        (
            "ERROR collecting tests/test_bad.py\n1 error in 0.05s\n",
            2,
            {"passed": 0, "failed": 0, "skipped": 0, "errors": 1, "warnings": 0, "total": 1},
            "collection_error",
        ),
        (
            "!!!!!!!!!!!!!!!! KeyboardInterrupt !!!!!!!!!!!!!!!!\n2 passed in 1.00s\n",
            2,
            {"passed": 2, "failed": 0, "skipped": 0, "errors": 0, "warnings": 0, "total": 2},
            "interrupted",
        ),
    ],
)
def test_pytest_formats_use_only_proven_summary_tokens(
    stdout: str,
    exit_code: int,
    counts: dict[str, int],
    reason: str | None,
) -> None:
    parsed = results.parse_command_result(
        command_result(stdout=stdout, exit_code=exit_code)
    )

    assert parsed.counts == counts
    if reason is not None:
        assert reason in parsed.reasons


def test_compileall_and_diff_check_keep_stage_specific_failure_evidence() -> None:
    compile_result = results.parse_command_result(
        command_result(
            command_family="compileall",
            stdout="*** Error compiling 'tools/bad.py'...\nSyntaxError\n",
            exit_code=1,
            failed_stage="compile",
        )
    )
    diff_result = results.parse_command_result(
        command_result(
            command_family="git_diff_check",
            stdout="file.py:7: new blank line at EOF.\n",
            exit_code=2,
            failed_stage="diff-check",
        )
    )

    assert compile_result.failure_class == "source"
    assert compile_result.failed_stage == "compile"
    assert "compile_error" in compile_result.reasons
    assert diff_result.failure_class == "source"
    assert diff_result.failed_stage == "diff-check"
    assert "whitespace_error" in diff_result.reasons


def test_flutter_summaries_extract_only_explicit_counts() -> None:
    test_result = results.parse_command_result(
        command_result(
            command_family="flutter_test",
            stdout="00:01 +12 -2 ~1: Some tests failed.\n",
            exit_code=1,
        )
    )
    analyze_result = results.parse_command_result(
        command_result(
            command_family="flutter_analyze",
            stdout="warning • one\nerror • two\n2 issues found.\n",
            exit_code=1,
        )
    )

    assert test_result.counts == {
        "passed": 12,
        "failed": 2,
        "skipped": 1,
        "errors": 0,
        "warnings": 0,
        "total": 15,
    }
    assert analyze_result.counts == {
        "passed": None,
        "failed": None,
        "skipped": None,
        "errors": 1,
        "warnings": 1,
        "total": 2,
    }


def test_wrapper_failure_before_action_does_not_consume_invocation_budget() -> None:
    parsed = results.parse_command_result(
        command_result(
            action_started=False,
            wrapper_failed=True,
            exit_code=None,
            duration_ms=0,
            stdout="",
            stderr="runner could not start",
        )
    )

    assert parsed.action_started is False
    assert parsed.wrapper_failed is True
    assert parsed.failure_class == "harness"
    assert parsed.budget_consumed is False
    assert parsed.reasons == ("action_not_started", "wrapper_failure")


def test_timeout_after_start_consumes_budget_and_precedes_command_failure() -> None:
    parsed = results.parse_command_result(
        command_result(
            timed_out=True,
            exit_code=None,
            stdout="2 passed in 1.00s\n",
            failed_stage="focused-test",
        )
    )

    assert parsed.failure_class == "timeout"
    assert parsed.budget_consumed is True
    assert parsed.timed_out is True
    assert parsed.failed_stage == "focused-test"
    assert "timeout" in parsed.reasons


def test_truncated_and_malformed_output_are_explicit() -> None:
    truncated = results.parse_command_result(
        command_result(stdout="3 passed in 0.01s\n", truncated=True)
    )
    malformed = results.parse_command_result(
        command_result(stdout="pytest produced ???\n", exit_code=0)
    )

    assert truncated.truncated is True
    assert "output_truncated" in truncated.reasons
    assert malformed.failure_class == "provenance"
    assert "output_unrecognized" in malformed.reasons


@pytest.mark.parametrize(
    ("stdout", "exit_code"),
    [
        ("1 failed, 2 passed in 0.10s\n", 0),
        ("3 passed in 0.10s\n", 1),
        ("BUILD SUCCESSFUL in 1s\n", 1),
        ("FAILURE: Build failed.\n", 0),
    ],
)
def test_exit_code_and_output_contradictions_fail_as_provenance(
    stdout: str,
    exit_code: int,
) -> None:
    family = "build" if "BUILD" in stdout or "Build" in stdout else "pytest"
    parsed = results.parse_command_result(
        command_result(command_family=family, stdout=stdout, exit_code=exit_code)
    )

    assert parsed.failure_class == "provenance"
    assert "exit_output_contradiction" in parsed.reasons


def test_toolchain_failure_is_distinct_from_generic_command_failure() -> None:
    parsed = results.parse_command_result(
        command_result(
            command_family="generic_command",
            stdout="",
            stderr="python: command not found\n",
            exit_code=127,
        )
    )

    assert parsed.failure_class == "toolchain"
    assert "toolchain_unavailable" in parsed.reasons


def test_raw_streams_are_hashed_and_excerpt_is_bounded_and_sanitized() -> None:
    stdout = (
        "token=secret-value\n"
        "email fatih@example.com\n"
        "path C:\\Users\\Fatih\\private\\report.txt\n"
        + "x" * 500
        + "\n"
    )
    stderr = "Authorization: Bearer ghp_abcdefghijklmnopqrstuvwxyz123456\n"
    parsed = results.parse_command_result(
        command_result(
            command_family="generic_command",
            stdout=stdout,
            stderr=stderr,
        )
    )
    public = parsed.public_dict()

    assert public["stdout_hash"] == "sha256:" + hashlib.sha256(
        stdout.encode("utf-8")
    ).hexdigest()
    assert public["stderr_hash"] == "sha256:" + hashlib.sha256(
        stderr.encode("utf-8")
    ).hexdigest()
    excerpt = "\n".join(public["sanitized_excerpt"])
    assert "secret-value" not in excerpt
    assert "fatih@example.com" not in excerpt
    assert "Fatih" not in excerpt
    assert "ghp_" not in excerpt
    assert "[REDACTED]" in excerpt
    assert "[EMAIL]" in excerpt
    assert "%USERPROFILE%" in excerpt
    assert len(public["sanitized_excerpt"]) <= results.MAX_EXCERPT_LINES
    assert all(
        len(line) <= results.MAX_EXCERPT_CHARS for line in public["sanitized_excerpt"]
    )
    assert "stdout" not in public
    assert "stderr" not in public


def test_unknown_family_invalid_schema_and_unknown_fields_fail_closed() -> None:
    cases = [
        (command_result(command_family="mystery"), "unknown_command_family"),
        (command_result(schema_version=2), "unsupported_schema_version"),
        ({**command_result(), "surprise": True}, "unknown_fields"),
    ]

    for value, reason in cases:
        with pytest.raises(results.ResultInputError, match=reason):
            results.parse_command_result(value)


@pytest.mark.parametrize(
    "updates",
    [
        {"action_started": False, "wrapper_failed": False},
        {"action_started": False, "timed_out": True},
        {"exit_code": True},
        {"duration_ms": -1},
        {"stdout": b"bytes are not accepted"},
        {"failed_stage": ""},
    ],
)
def test_incompatible_or_invalid_input_fails_closed(updates: dict[str, object]) -> None:
    with pytest.raises(results.ResultInputError):
        results.parse_command_result(command_result(**updates))


def test_unknown_counts_remain_unknown_and_are_never_estimated() -> None:
    parsed = results.parse_command_result(
        command_result(command_family="generic_command", stdout="done 99 things\n")
    )

    assert parsed.counts == {
        "passed": None,
        "failed": None,
        "skipped": None,
        "errors": None,
        "warnings": None,
        "total": None,
    }


def test_input_is_immutable_and_canonical_json_is_byte_stable() -> None:
    value = command_result()
    original = copy.deepcopy(value)

    first = results.parse_command_result(value)
    second = results.parse_command_result(dict(reversed(list(value.items()))))
    first_json = results.canonical_result_json(first)
    second_json = results.canonical_result_json(second)

    assert value == original
    assert first_json == second_json
    assert first_json == json.dumps(
        json.loads(first_json),
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    )
    assert "secret" not in first_json


def test_parser_has_no_subprocess_network_or_filesystem_access(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    def forbidden(*args: object, **kwargs: object) -> object:
        raise AssertionError("external I/O is forbidden")

    monkeypatch.setattr(subprocess, "run", forbidden)
    monkeypatch.setattr(socket, "socket", forbidden)
    monkeypatch.setattr(builtins, "open", forbidden)

    parsed = results.parse_command_result(command_result())

    assert parsed.failure_class is None
