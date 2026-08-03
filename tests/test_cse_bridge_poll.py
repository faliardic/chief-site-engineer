from __future__ import annotations

import unittest

from tools.cse_bridge_poll import task_ready


TASK = {
    "number": 10,
    "body": "<!-- cse-bridge-task:v1 -->\n## Repository\nexample/repo",
}


class PollerTests(unittest.TestCase):
    def test_trusted_approval_makes_task_ready(self) -> None:
        comments = [
            {
                "body": "CSE_BRIDGE_APPROVED",
                "author_association": "OWNER",
                "created_at": "2026-08-03T19:00:00Z",
            }
        ]
        self.assertTrue(task_ready(TASK, comments))

    def test_untrusted_approval_is_ignored(self) -> None:
        comments = [
            {
                "body": "CSE_BRIDGE_APPROVED",
                "author_association": "NONE",
                "created_at": "2026-08-03T19:00:00Z",
            }
        ]
        self.assertFalse(task_ready(TASK, comments))

    def test_waiting_config_requires_newer_approval(self) -> None:
        comments = [
            {
                "body": "CSE_BRIDGE_APPROVED",
                "author_association": "OWNER",
                "created_at": "2026-08-03T19:00:00Z",
            },
            {
                "body": "<!-- cse-bridge-status:WAITING_CONFIG -->",
                "author_association": "NONE",
                "created_at": "2026-08-03T19:01:00Z",
            },
        ]
        self.assertFalse(task_ready(TASK, comments))
        comments.append(
            {
                "body": "CSE_BRIDGE_APPROVED",
                "author_association": "OWNER",
                "created_at": "2026-08-03T19:02:00Z",
            }
        )
        self.assertTrue(task_ready(TASK, comments))

    def test_running_requires_newer_approval_after_interruption(self) -> None:
        comments = [
            {
                "body": "CSE_BRIDGE_APPROVED",
                "author_association": "OWNER",
                "created_at": "2026-08-03T19:00:00Z",
            },
            {
                "body": "<!-- cse-bridge-status:RUNNING -->",
                "created_at": "2026-08-03T19:01:00Z",
            },
        ]
        self.assertFalse(task_ready(TASK, comments))

    def test_terminal_task_is_never_selected(self) -> None:
        comments = [
            {
                "body": "CSE_BRIDGE_APPROVED",
                "author_association": "OWNER",
                "created_at": "2026-08-03T19:00:00Z",
            },
            {
                "body": "<!-- cse-bridge-status:PASS -->",
                "created_at": "2026-08-03T19:01:00Z",
            },
            {
                "body": "CSE_BRIDGE_APPROVED",
                "author_association": "OWNER",
                "created_at": "2026-08-03T19:02:00Z",
            },
        ]
        self.assertFalse(task_ready(TASK, comments))

    def test_pull_request_is_not_a_task(self) -> None:
        issue = dict(TASK, pull_request={"url": "x"})
        self.assertFalse(task_ready(issue, []))


if __name__ == "__main__":
    unittest.main()
