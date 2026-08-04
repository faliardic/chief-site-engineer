# Minimal ChatGPT–OpenAI API Bridge

## Purpose

The bridge removes Fatih from the prompt-relay loop.

```text
ChatGPT task Issue + approval comment
→ Windows Task Scheduler
→ local repository-external worktree
→ OpenAI Responses API with bounded file tools
→ deterministic validation and publication
→ Draft PR
→ ChatGPT review
```

The bridge deliberately avoids the former controller SHA, projection, tail-hash
and successor-chain design. It protects only the main risks and stops on unknown
or high-risk conditions.

## Main safety guards

1. Only `faliardic/chief-site-engineer` and the configured canonical checkout
   are accepted.
2. The canonical checkout is never switched to a task branch. Every task runs
   in `%LOCALAPPDATA%\CSE-Bridge\worktrees\issue-N`.
3. The model writes only paths listed in the task Issue.
4. The model cannot call shell, Git, GitHub, credentials, ADB or device tools.
5. Validation commands are parsed without a shell and limited to approved
   Python, Flutter and `git diff --check` command families.
6. Commit, normal push and Draft PR happen only after scope and validation PASS.
7. Only one correction pass is permitted.
8. Force-push, merge, release, hard reset/clean, branch deletion and real-user
   or device-data operations remain outside the bridge.
9. The OpenAI API key is stored with the current Windows user's DPAPI protection
   as a PowerShell SecureString export. It is decrypted only into the launcher
   process environment and is cleared after the worker exits.
10. GitHub authentication comes from the existing `gh auth` session and is not
    persisted by the bridge.

## One-time setup

From the canonical repository, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install_cse_bridge.ps1
```

The installer:

- verifies the exact `python`, `git`, `gh` executables and current GitHub login;
- asks for the OpenAI API key through a secure prompt only when no encrypted key
  is already installed;
- stores the key under `%LOCALAPPDATA%\CSE-Bridge` using user-bound encryption;
- writes non-secret model, repository and executable-path configuration;
- runs the bridge once in the foreground before claiming success;
- registers the `CSE Bridge` Scheduled Task with the current Windows identity,
  interactive logon and limited run level so mapped drives such as `V:` remain
  visible without administrator privileges;
- starts the registered Scheduled Task immediately and requires a fresh
  `worker-status.json` state within 30 seconds before claiming installation
  success;
- removes the task and reports a stable failure reason if the actual Scheduled
  Task cannot launch;
- repeats every five minutes after both foreground and scheduled launch checks
  pass.

No administrator permission is required. To replace the key, run with
`-ResetKey`. To remove the scheduled task while preserving credentials, run
with `-Uninstall`.

## Runtime diagnostics

Every worker invocation writes repository-external diagnostics:

- `%LOCALAPPDATA%\CSE-Bridge\worker-status.json` — atomic state, exit code,
  stable reason and UTC update time;
- `%LOCALAPPDATA%\CSE-Bridge\worker-last.log` — bounded launcher/worker output
  without the API key.

A valid lock whose process is still alive prevents concurrent workers. A lock
left by a dead process is recovered automatically.

## Task format

```markdown
<!-- cse-bridge-task:v1 -->

## Repository
faliardic/chief-site-engineer

## Base
master

## Branch
codex/example-task

## Goal
Describe the change.

## Allowed paths
- path/or/glob

## Validation commands
- python -m pytest tests/example.py
- python -m compileall -q app scripts tools
- git diff --check

## Commit
Exact commit subject

## Draft PR
Exact PR title
Related to #123
```

ChatGPT adds a trusted Issue comment containing exactly:

```text
CSE_BRIDGE_APPROVED
```

The scheduled worker selects one approved, non-terminal task and posts one of:

- `RUNNING`
- `PASS`
- `FAILED`
- `NEEDS_HUMAN`

## OpenAI API loop

The bridge calls the Responses API using the locally configured model. The
model receives only these bounded tools:

- read a tracked, non-protected text file;
- search tracked text files;
- write or exactly replace an allowlisted file;
- list changed paths;
- finish with a summary.

The host, not the model, owns validation, commit, push and Draft PR creation.
Temporary API transport retries are separate from the single coding correction
budget.

## Worktree lifecycle

Before a task starts, the local worker verifies the canonical repository and
origin, fetches the exact base, checks that the task branch does not already
exist remotely, and creates a detached repository-external worktree. The
existing bridge then creates the task branch inside that worktree.

After a successful publish, only the bridge-owned worktree and local task branch
are removed; the remote branch and Draft PR remain. On failure, the worktree is
preserved for diagnosis. A lock file prevents concurrent workers.

## Human-on-exception boundary

Fatih is interrupted only for:

- product or scope decisions;
- real-user-data or destructive-operation risk;
- physical device action;
- missing local API/GitHub configuration;
- one correction failing to reach PASS;
- an unknown high-risk condition.
