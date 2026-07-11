# CSE Repository Handoff Protocol

This directory is the repository-native handoff layer between ChatGPT, Codex, GitHub, and the project owner.

## Goal

Remove routine copy/paste between ChatGPT and Codex while keeping every task small, reviewable, testable, and reversible.

## Standard Flow

1. A GitHub issue defines the business purpose and acceptance boundary.
2. Codex works from the official local repository first:

   ```text
   V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer
   ```

3. Before branch changes, pulls, edits, commits, or pushes, Codex inspects the local working tree. If unexpected tracked, staged, or untracked project changes exist, Codex stops and reports them instead of resetting, cleaning, stashing, deleting, or overwriting.
4. Codex fetches and fast-forwards local `master` before branch work:

   ```powershell
   git fetch origin --prune
   git checkout master
   git pull --ff-only origin master
   ```

5. Codex verifies local `master`, `origin/master`, and divergence evidence before creating or checking out the step branch locally.
6. Codex creates the task file and all authorized project files physically in the official local working tree. GitHub-only file creation is incomplete.
7. Codex performs only the authorized work, writes `.cse/results/<step>_result.md`, and updates `.cse/state/project_state.json` locally.
8. Codex runs tests and all safety checks locally, including protected path diff, `exports/`, ignored ZIP, and branch divergence checks.
9. Codex commits and pushes from the official local repository only when the task explicitly authorizes it.
10. A draft pull request is opened against `master` only when the task/issue authorizes that actor to do so.
11. ChatGPT reviews the PR diff, scope, result report, checks, and review boundaries directly from GitHub.
12. Merge requires explicit user approval.
13. After a merge, Codex must fast-forward local `master` before starting the next step.

## Source of Truth

- Git history and the current pull request are the change source of truth.
- The official local repository is the execution source of truth for project file creation, edits, verification, commit, and push.
- GitHub is the synchronized remote and review surface; GitHub-only project file changes do not count as completion.
- `.cse/tasks/` contains authorized work definitions.
- `.cse/results/` contains execution reports.
- `.cse/templates/` contains canonical reusable task and result templates.
- `.cse/state/project_state.json` contains the latest merged/finalized machine-readable checkpoint. Open draft work remains represented by its task file, result report, branch, issue, and pull request until it is merged and finalized.
- ZIP files are emergency/offline backups only and must remain outside tracked repository scope.

## Safety Rules

- Never work directly on `master` for a new technical step.
- Before branch changes, pulls, edits, commits, or pushes, inspect tracked, staged, untracked, and ignored local status.
- Stop and report unexpected tracked, staged, or untracked project changes. Do not automatically reset, clean, stash, delete, or overwrite user work.
- Fast-forward local `master` from `origin/master` before creating or checking out a new step branch.
- Create/check out step branches locally and verify local/remote divergence evidence.
- Create all task, result, state, documentation, and project files physically in the official local working tree.
- Never expand scope beyond the task file.
- Never commit or push unless the task grants that permission.
- Production code changes require corresponding tests.
- Tests and `git diff --check` must pass before a change is proposed as safe.
- `exports/` must not receive unintended output.
- Ignored ZIP files must not be staged, deleted, renamed, or committed.
- After a merge, fast-forward local `master` before starting the next step.
- Hard validation, blocking behavior, migration, database/repository access, audit behavior, backup/restore, API, GUI, or CLI work requires explicit task scope.

## Naming

- Issue: `Step NNN: <purpose>`
- Branch: `step-NNN-<short-purpose>`
- Task: `.cse/tasks/NNN_task.md`
- Result: `.cse/results/NNN_result.md`
- Draft PR: `Step NNN: <purpose>`

## Human Control

The protocol automates transport and review visibility. It does not remove human approval. The project owner remains the final authority for merge, release, and scope changes.
