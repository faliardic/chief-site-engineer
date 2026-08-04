from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.cse_api_bridge import BridgeError
from tools.cse_bridge_local import SingleInstanceLock, write_status


class LockRecoveryTests(unittest.TestCase):
    def test_dead_pid_lock_is_recovered(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "worker.lock"
            path.write_text("12345", encoding="ascii")
            with SingleInstanceLock(path, checker=lambda pid: False):
                self.assertNotEqual(path.read_text(encoding="ascii"), "12345")
            self.assertFalse(path.exists())

    def test_live_pid_lock_is_preserved(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "worker.lock"
            path.write_text("12345", encoding="ascii")
            with self.assertRaisesRegex(BridgeError, "bridge_already_running"):
                with SingleInstanceLock(path, checker=lambda pid: True):
                    pass
            self.assertTrue(path.exists())


class StatusTests(unittest.TestCase):
    def test_status_is_written_atomically(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            runtime = Path(temporary)
            write_status(runtime, "FAILED", 1, "test_reason")
            payload = json.loads(
                (runtime / "worker-status.json").read_text(encoding="utf-8")
            )
            self.assertEqual(payload["state"], "FAILED")
            self.assertEqual(payload["exit_code"], 1)
            self.assertEqual(payload["reason"], "test_reason")
            self.assertIn("updated_at", payload)
            self.assertFalse((runtime / "worker-status.tmp").exists())


class InstallerContractTests(unittest.TestCase):
    def installer(self) -> str:
        return Path("scripts/install_cse_bridge.ps1").read_text(encoding="utf-8")

    def test_default_model_is_general_responses_model(self) -> None:
        installer = self.installer()
        self.assertIn('[string]$Model = "gpt-5.1"', installer)
        self.assertNotIn('[string]$Model = "gpt-5.1-codex"', installer)

    def test_scheduled_task_uses_interactive_limited_principal(self) -> None:
        installer = self.installer()
        self.assertIn("New-ScheduledTaskPrincipal", installer)
        self.assertIn("-LogonType Interactive", installer)
        self.assertIn("-RunLevel Limited", installer)
        self.assertIn("-Principal $principal", installer)

    def test_scheduled_task_launch_is_verified_from_new_status(self) -> None:
        installer = self.installer()
        self.assertIn("Start-ScheduledTask -TaskName $taskName", installer)
        self.assertIn("Remove-Item -LiteralPath $statusPath", installer)
        self.assertIn("worker-status.json", installer)
        self.assertIn("$attempt -lt 30", installer)
        self.assertIn('@("STARTING", "RUNNING", "PASS", "SKIPPED")', installer)
        self.assertIn("scheduled_task_no_status", installer)


if __name__ == "__main__":
    unittest.main()
