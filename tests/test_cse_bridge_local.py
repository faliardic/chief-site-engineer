from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from tools.cse_api_bridge import BridgeError
from tools.cse_bridge_local import (
    CommandResult,
    SingleInstanceLock,
    create_worktree,
    normalize_origin,
    task_worktree,
    validate_repository,
)


class OriginTests(unittest.TestCase):
    def test_common_github_origins_normalize(self) -> None:
        expected = "faliardic/chief-site-engineer"
        self.assertEqual(
            normalize_origin(
                "https://github.com/faliardic/chief-site-engineer.git"
            ),
            expected,
        )
        self.assertEqual(
            normalize_origin("git@github.com:faliardic/chief-site-engineer.git"),
            expected,
        )


class LockTests(unittest.TestCase):
    def test_lock_is_exclusive_and_removed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "worker.lock"
            with SingleInstanceLock(path):
                self.assertTrue(path.exists())
                with self.assertRaisesRegex(
                    BridgeError, "bridge_already_running"
                ):
                    with SingleInstanceLock(path):
                        pass
            self.assertFalse(path.exists())


class RepositoryTests(unittest.TestCase):
    def test_repository_identity_is_checked(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            outputs = iter(
                [
                    CommandResult(0, str(root)),
                    CommandResult(
                        0,
                        "https://github.com/faliardic/chief-site-engineer.git\n",
                    ),
                ]
            )

            def fake(argv, cwd, timeout):
                return next(outputs)

            validate_repository(
                root,
                "faliardic/chief-site-engineer",
                fake,
            )

    def test_wrong_origin_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            outputs = iter(
                [
                    CommandResult(0, str(root)),
                    CommandResult(0, "https://github.com/other/repo.git"),
                ]
            )

            def fake(argv, cwd, timeout):
                return next(outputs)

            with self.assertRaisesRegex(
                BridgeError, "origin_repository_mismatch"
            ):
                validate_repository(
                    root,
                    "faliardic/chief-site-engineer",
                    fake,
                )


class WorktreeTests(unittest.TestCase):
    def test_worktree_is_repository_external(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            runtime = Path(temporary) / "runtime"
            path = task_worktree(runtime, 316)
            self.assertEqual(
                path,
                runtime.resolve() / "worktrees" / "issue-316",
            )

    def test_create_worktree_uses_exact_base(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary) / "repo"
            runtime = Path(temporary) / "runtime"
            root.mkdir()
            calls = []

            def fake(argv, cwd, timeout):
                calls.append(tuple(argv))
                if tuple(argv[:2]) == ("git", "ls-remote"):
                    return CommandResult(2)
                return CommandResult(0)

            path = create_worktree(
                root,
                runtime,
                316,
                "master",
                "codex/issue-316-bridge-smoke-test",
                fake,
            )
            self.assertEqual(
                path,
                runtime.resolve() / "worktrees" / "issue-316",
            )
            self.assertIn(
                ("git", "fetch", "origin", "master", "--prune"),
                calls,
            )
            self.assertIn(
                (
                    "git",
                    "worktree",
                    "add",
                    "--detach",
                    str(path),
                    "origin/master",
                ),
                calls,
            )


if __name__ == "__main__":
    unittest.main()
