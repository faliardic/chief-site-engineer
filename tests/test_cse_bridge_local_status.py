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
    def test_default_model_is_general_responses_model(self) -> None:
        installer = Path("scripts/install_cse_bridge.ps1").read_text(encoding="utf-8")
        self.assertIn('[string]$Model = "gpt-5.1"', installer)
        self.assertNotIn('[string]$Model = "gpt-5.1-codex"', installer)


if __name__ == "__main__":
    unittest.main()
