from __future__ import annotations

import argparse
import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from tools.cse_agent_loop import (
    _correction_prompt,
    _implement_prompt,
    _issue_number,
    _review_prompt,
    _write_output,
    command_comment,
)
from tools.cse_api_bridge import BridgeError


class FakeGitHub:
    def __init__(self) -> None:
        self.items: list[dict[str, str]] = []
        self.posted: list[tuple[int, str]] = []

    def comments(self, issue_number: int):
        return list(self.items)

    def comment(self, issue_number: int, body: str) -> None:
        self.posted.append((issue_number, body))
        self.items.append({"body": body})


class AgentLoopTests(unittest.TestCase):
    def test_issue_number_requires_positive_integer(self) -> None:
        self.assertEqual(_issue_number("42"), 42)
        for value in ("", "0", "-1", "abc"):
            with self.subTest(value=value), self.assertRaises(BridgeError):
                _issue_number(value)

    def test_implementation_prompt_keeps_host_operations_out_of_codex(self) -> None:
        prompt = _implement_prompt(42, "TASK BODY")
        self.assertIn("GitHub Issue #42", prompt)
        self.assertIn("Modify only paths listed under `Allowed paths`", prompt)
        self.assertIn("Do not commit, push", prompt)
        self.assertIn("TASK BODY", prompt)

    def test_correction_prompt_contains_review_feedback(self) -> None:
        prompt = _correction_prompt(42, "TASK BODY", "1. Fix the parser", 1)
        self.assertIn("review round 1", prompt)
        self.assertIn("1. Fix the parser", prompt)
        self.assertIn("Do not broaden scope", prompt)

    def test_review_prompt_has_exact_terminal_contract(self) -> None:
        prompt = _review_prompt(42, "TASK", "DIFF", "VALIDATION")
        self.assertIn("APPROVED", prompt)
        self.assertIn("CHANGES_REQUESTED", prompt)
        self.assertIn("Do not approve if the evidence is insufficient", prompt)
        self.assertIn("DIFF", prompt)
        self.assertIn("VALIDATION", prompt)

    def test_write_output_preserves_multiline_values(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            destination = Path(temporary) / "output.txt"
            with patch.dict(os.environ, {"GITHUB_OUTPUT": str(destination)}):
                _write_output("feedback", "line one\nline two")
            value = destination.read_text(encoding="utf-8")
        self.assertEqual(
            value,
            "feedback<<CSE_EOF\nline one\nline two\nCSE_EOF\n",
        )

    def test_comment_is_idempotent_and_uses_agent_marker(self) -> None:
        github = FakeGitHub()
        args = argparse.Namespace(
            issue_number="42",
            state="RUNNING",
            message="Loop started.",
        )
        with patch("tools.cse_agent_loop._github", return_value=github):
            self.assertEqual(command_comment(args), 0)
            self.assertEqual(command_comment(args), 0)
        self.assertEqual(len(github.posted), 1)
        self.assertIn(
            "<!-- cse-agent-loop-status:RUNNING -->",
            github.posted[0][1],
        )


if __name__ == "__main__":
    unittest.main()
