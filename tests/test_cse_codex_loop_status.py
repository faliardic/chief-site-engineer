from __future__ import annotations

import json
import os
import re
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
        cls.scripts = "\n".join((cls.installer, cls.runner))

    def assert_source_order(self, source: str, *fragments: str) -> None:
        positions = [source.index(fragment) for fragment in fragments]
        self.assertEqual(positions, sorted(positions))

    def test_task_is_registered_disabled_for_interactive_limited_user(self) -> None:
        self.assertIn('$taskName = "CSE Codex Loop"', self.installer)
        self.assertIn("Register-ScheduledTask", self.installer)
        self.assertIn("Disable-ScheduledTask -TaskName $taskName", self.installer)
        self.assertIn("-LogonType Interactive", self.installer)
        self.assertIn("-RunLevel Limited", self.installer)
        self.assertIn("-Principal $principal", self.installer)
        self.assertIn('State -ne "Disabled"', self.installer)
        self.assertIn("-AllowStartIfOnBatteries", self.installer)
        self.assertIn("-DontStopIfGoingOnBatteries", self.installer)

    def test_installer_resolves_all_exact_executable_paths(self) -> None:
        for name in ("pythonPath", "codexPath", "gitPath", "ghPath"):
            self.assertIn(f"${name} = (Resolve-Path", self.installer)
            self.assertIn(f"{name.lower()[:-4]}_path", self.installer)

    def test_installer_accepts_exact_codex_application_launcher(self) -> None:
        self.assertIn(
            "Get-Command codex -CommandType Application", self.installer
        )
        self.assertIn(
            '$supportedCodexExtensions = @(".exe", ".com", ".cmd", ".bat")',
            self.installer,
        )
        self.assertIn(
            "GetExtension($codexPath).ToLowerInvariant()", self.installer
        )
        self.assertNotIn("Get-Command codex.exe", self.installer)
        self.assertNotIn("Native codex.exe was not found", self.installer)

    def test_installer_selects_one_existing_supported_codex_launcher(self) -> None:
        self.assertIn("Where-Object {", self.installer)
        self.assertIn("$candidate = [string]$_.Source", self.installer)
        self.assertIn(
            "Test-Path -LiteralPath $candidate -PathType Leaf", self.installer
        )
        self.assertIn("Select-Object -First 1", self.installer)
        self.assertLess(
            self.installer.index("Where-Object {"),
            self.installer.index("$codexPath = (Resolve-Path"),
        )

    def test_installer_persists_optional_exact_flutter_path(self) -> None:
        self.assertIn("Get-Command flutter.bat", self.installer)
        self.assertIn("$flutterPath = $null", self.installer)
        self.assertIn(
            "$flutterPath = (Resolve-Path -LiteralPath", self.installer
        )
        self.assertIn("flutter_path = $flutterPath", self.installer)

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

    def test_canonical_repo_root_is_bootstrap_only(self) -> None:
        self.assertIn(
            '$bootstrapInstallerPath = Join-Path $RepoRoot '
            '"scripts\\install_cse_codex_loop.ps1"',
            self.installer,
        )
        self.assertIn(
            "& $gitPath -C $resolvedBootstrapRepoRoot remote get-url origin",
            self.installer,
        )
        self.assertNotIn("repo_root = $resolvedBootstrapRepoRoot", self.installer)
        self.assertNotIn(
            'Join-Path $RepoRoot "scripts\\run_cse_codex_loop.ps1"',
            self.installer,
        )
        bootstrap_git_lines = [
            line.strip()
            for line in self.installer.splitlines()
            if "& $gitPath -C $resolvedBootstrapRepoRoot" in line
        ]
        self.assertEqual(len(bootstrap_git_lines), 2)
        self.assertTrue(any(" rev-parse --show-toplevel" in line for line in bootstrap_git_lines))
        self.assertTrue(any(" remote get-url origin" in line for line in bootstrap_git_lines))

    def test_dedicated_control_clone_bootstrap_is_narrow_and_fail_closed(self) -> None:
        self.assertIn(
            '$controlRepoRoot = Join-Path $runtimeRoot "control-repo"',
            self.installer,
        )
        self.assertIn("bootstrap_repository_origin_unexpected", self.installer)
        self.assertIn(
            "clone --branch master --single-branch --no-tags "
            "--no-recurse-submodules -- $originUrl $controlRepoRoot",
            self.installer,
        )
        self.assertIn("control_repository_role_unexpected", self.installer)
        self.assertIn("control_repository_dirty", self.installer)
        self.assertNotIn("Remove-Item", self.installer)

    def test_dedicated_path_and_role_are_persisted_exactly(self) -> None:
        self.assertIn(
            'repository_role = "dedicated_control_clone_v1"', self.installer
        )
        self.assertIn("repo_root = $resolvedControlRepoRoot", self.installer)
        self.assertIn(
            '$runnerPath = Join-Path $resolvedControlRepoRoot '
            '"scripts\\run_cse_codex_loop.ps1"',
            self.installer,
        )
        self.assertIn(
            "-WorkingDirectory $resolvedControlRepoRoot", self.installer
        )
        self.assertIn(
            "-File $runnerPath -RuntimeRoot $runtimeRoot -Smoke", self.installer
        )

    def test_runner_role_and_resolved_path_guards_precede_git_mutation(self) -> None:
        self.assertIn(
            '$repositoryRole -cne "dedicated_control_clone_v1"', self.runner
        )
        self.assertGreaterEqual(
            self.runner.count('throw "runtime_control_clone_unconfigured"'),
            3,
        )
        self.assertIn(
            '$expectedRepoRoot = Join-Path $RuntimeRoot "control-repo"',
            self.runner,
        )
        self.assert_source_order(
            self.runner,
            '$repositoryRole -cne "dedicated_control_clone_v1"',
            "$resolvedExpectedRepoRoot = (Resolve-Path",
            "[System.StringComparer]::OrdinalIgnoreCase.Equals(",
            "foreach ($executable",
            "fetch --no-tags --no-recurse-submodules origin master",
        )

    def test_tracked_cleanliness_ignores_untracked_and_fetch_is_fixed(self) -> None:
        self.assertGreaterEqual(
            self.scripts.count("status --porcelain=v1 --untracked-files=no"),
            4,
        )
        fetch_lines = [
            line.strip()
            for line in self.scripts.splitlines()
            if "& $gitPath" in line and " fetch " in line
        ]
        self.assertEqual(
            fetch_lines,
            [
                "& $gitPath -C $controlRepoRoot fetch --no-tags "
                "--no-recurse-submodules origin master 1>$null 2>$null",
                "& $gitPath -C $repoRoot fetch --no-tags "
                "--no-recurse-submodules origin master 1>$null 2>$null",
            ],
        )
        self.assertNotIn("--prune", self.scripts)

    def test_installer_ancestry_guard_precedes_switch(self) -> None:        update_block_start = self.installer.index("$currentHeadOutput")        update_block_end = self.installer.index(            "$finalHeadOutput", update_block_start        )        update_block = self.installer[            update_block_start:update_block_end        ]        self.assertIn("merge-base --is-ancestor", update_block)        self.assertIn(            'throw "control_repository_master_non_fast_forward"',            update_block,        )        self.assertIn(            'throw "control_repository_master_ancestry_failed"',            update_block,        )        self.assert_source_order(            update_block,            "$currentHeadOutput",            'if ($currentHead -cne $remoteMasterHead)',            "merge-base --is-ancestor",            "switch --detach refs/remotes/origin/master",        )    def test_runner_ancestry_and_final_guards_precede_python(self) -> None:
        update_block_start = self.runner.index(
            "if ($currentHead -cne $remoteMasterHead)"
        )
        update_block_end = self.runner.index("$finalHeadOutput", update_block_start)
        update_block = self.runner[update_block_start:update_block_end]
        self.assertIn("merge-base --is-ancestor", update_block)
        self.assertIn('throw "runtime_master_non_fast_forward"', update_block)
        self.assertIn(
            "switch --detach refs/remotes/origin/master", update_block
        )
        self.assert_source_order(
            update_block,
            "merge-base --is-ancestor",
            "switch --detach refs/remotes/origin/master",
        )
        self.assert_source_order(
            self.runner,
            "$finalHeadOutput",
            "$finalTrackedStatus",
            "$env:PATH =",
            '"tools.cse_codex_loop"',
            "& $pythonPath @arguments",
        )

    def test_runner_preserves_forwarding_path_and_exit_behavior(self) -> None:
        self.assertIn('"--runtime-root"', self.runner)
        self.assertIn('"--issue-number"', self.runner)
        self.assertIn('$arguments += "--smoke"', self.runner)
        self.assertIn("Push-Location -LiteralPath $repoRoot", self.runner)
        self.assertIn("$exitCode = $LASTEXITCODE", self.runner)
        self.assertIn("exit $exitCode", self.runner)
        self.assert_source_order(
            self.runner,
            "foreach ($executable",
            "$env:PATH =",
            "& $pythonPath @arguments",
        )

    def test_repository_git_paths_exclude_forbidden_operations(self) -> None:
        git_lines = [
            line.strip().lower()
            for line in self.scripts.splitlines()
            if line.strip().startswith("& $gitpath")
        ]
        forbidden_git_tokens = {
            "reset",
            "clean",
            "stash",
            "checkout",
            "branch",
            "update-ref",
            "worktree",
            "push",
        }
        for line in git_lines:
            tokens = set(re.findall(r"[^\s]+", line))
            self.assertTrue(forbidden_git_tokens.isdisjoint(tokens), line)
            self.assertNotIn("--force", tokens, line)
        for forbidden in (
            "worktree prune",
            "submodule update",
            "force-push",
            "adb",
            "data clear",
            "auth login",
            "setup-git",
        ):
            self.assertNotIn(forbidden, self.scripts.lower())


if __name__ == "__main__":
    unittest.main()
