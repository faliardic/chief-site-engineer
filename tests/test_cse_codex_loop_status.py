from __future__ import annotations

import json
import os
import tempfile
import unittest
from pathlib import Path

from tools.cse_codex_loop import CommandResult, RunArtifacts


class RunStatusTests(unittest.TestCase):
    def test_status_is_atomic_run_and_issue_aware(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            runtime = Path(temporary)
            artifacts = RunArtifacts.create(
                runtime, 345, run_id="20260804T200000Z-12345678"
            )
            artifacts.update("RUNNING", "review", None)
            run_status = json.loads(
                (artifacts.run_root / "status.json").read_text(encoding="utf-8")
            )
            worker_status = json.loads(
                (runtime / "worker-status.json").read_text(encoding="utf-8")
            )
            self.assertEqual(run_status, worker_status)
            self.assertEqual(run_status["run_id"], artifacts.run_id)
            self.assertEqual(run_status["issue_number"], 345)
            self.assertEqual(run_status["phase"], "review")
            self.assertFalse((artifacts.run_root / "status.json.tmp").exists())

    def test_rotation_keeps_only_bounded_newest_runs(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            runtime = Path(temporary)
            first = RunArtifacts.create(runtime, None, max_runs=2, run_id="run-1")
            os.utime(first.run_root, (1, 1))
            second = RunArtifacts.create(runtime, None, max_runs=2, run_id="run-2")
            os.utime(second.run_root, (2, 2))
            third = RunArtifacts.create(runtime, None, max_runs=2, run_id="run-3")
            self.assertFalse(first.run_root.exists())
            self.assertTrue(second.run_root.exists())
            self.assertTrue(third.run_root.exists())

    def test_command_logs_remove_prompts_and_secrets(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            artifacts = RunArtifacts.create(
                Path(temporary), 345, run_id="secret-free-run"
            )
            prompt = "private full prompt"
            result = CommandResult(
                1,
                f"{prompt} token=ghp_abcdefghijklmnopqrstuvwxyz",
                "Authorization: Bearer top-secret-value",
            )
            artifacts.record_command(
                "codex", result, include_output=True, sensitive=(prompt,)
            )
            logs = "".join(
                (artifacts.run_root / name).read_text(encoding="utf-8")
                for name in ("stdout.log", "stderr.log")
            )
            self.assertNotIn(prompt, logs)
            self.assertNotIn("ghp_abcdefghijklmnopqrstuvwxyz", logs)
            self.assertNotIn("top-secret-value", logs)
            self.assertIn("[REDACTED]", logs)


class InstallerSourceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.installer = Path("scripts/install_cse_codex_loop.ps1").read_text(
            encoding="utf-8"
        )
        cls.runner = Path("scripts/run_cse_codex_loop.ps1").read_text(
            encoding="utf-8"
        )
        cls.source = Path("tools/cse_codex_loop.py").read_text(encoding="utf-8")

    def test_task_is_registered_disabled_for_interactive_limited_user(self) -> None:
        self.assertIn('$taskName = "CSE Codex Loop"', self.installer)
        self.assertIn("Register-ScheduledTask", self.installer)
        self.assertIn("Disable-ScheduledTask -TaskName $taskName", self.installer)
        self.assertIn("-LogonType Interactive", self.installer)
        self.assertIn("-RunLevel Limited", self.installer)
        self.assertIn("-Principal $principal", self.installer)
        self.assertIn('State -ne "Disabled"', self.installer)

    def test_installer_resolves_all_exact_executable_paths(self) -> None:
        for name in ("pythonPath", "codexPath", "gitPath", "ghPath"):
            self.assertIn(f"${name} = (Resolve-Path", self.installer)
            self.assertIn(f"{name.lower()[:-4]}_path", self.installer)

    def test_new_loop_never_invokes_the_old_api_bridge_or_key_file(self) -> None:
        combined = "\n".join((self.installer, self.runner, self.source))
        self.assertNotIn("cse_api_bridge.py", combined)
        self.assertNotIn("openai_api_key.xml", combined)
        self.assertNotIn("OPENAI_API_KEY", combined)
        self.assertNotIn('-TaskName "CSE Bridge"', self.installer)

    def test_smoke_is_manual_and_read_only(self) -> None:
        self.assertIn("[switch]$Smoke", self.installer)
        self.assertIn("-Smoke", self.installer)
        self.assertIn('"read-only"', self.source)
        self.assertIn("CSE_CODEX_EXEC_PASS", self.source)


if __name__ == "__main__":
    unittest.main()
