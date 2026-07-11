# CSE Repository Handoff Protocol

This directory is the repository-native handoff layer between ChatGPT, Codex, GitHub, and the project owner.

## Goal

Remove routine copy/paste between ChatGPT and Codex while keeping every task small, reviewable, testable, and reversible.

## Standard Flow

1. A GitHub issue defines the business purpose and acceptance boundary.
2. ChatGPT creates a dedicated task branch from the current safe `master` commit.
3. ChatGPT writes the exact task into `.cse/tasks/<step>_task.md`.
4. Codex reads that task file from the repository and performs only the authorized work.
5. Codex writes `.cse/results/<step>_result.md` and updates `.cse/state/project_state.json`.
6. Codex commits and pushes only when the task explicitly authorizes it.
7. A draft pull request is opened against `master`.
8. ChatGPT reviews the PR diff, scope, result report, checks, and review boundaries directly from GitHub.
9. Merge requires explicit user approval.

## Source of Truth

- Git history and the current pull request are the change source of truth.
- `.cse/tasks/` contains authorized work definitions.
- `.cse/results/` contains execution reports.
- `.cse/templates/` contains canonical reusable task and result templates.
- `.cse/state/project_state.json` contains the latest machine-readable handoff state.
- ZIP files are emergency/offline backups only and must remain outside tracked repository scope.

## Safety Rules

- Never work directly on `master` for a new technical step.
- Never expand scope beyond the task file.
- Never commit or push unless the task grants that permission.
- Production code changes require corresponding tests.
- Tests and `git diff --check` must pass before a change is proposed as safe.
- `exports/` must not receive unintended output.
- Ignored ZIP files must not be staged, deleted, renamed, or committed.
- Hard validation, blocking behavior, migration, database/repository access, audit behavior, backup/restore, API, GUI, or CLI work requires explicit task scope.

## Naming

- Issue: `Step NNN: <purpose>`
- Branch: `step-NNN-<short-purpose>`
- Task: `.cse/tasks/NNN_task.md`
- Result: `.cse/results/NNN_result.md`
- Draft PR: `Step NNN: <purpose>`

## Human Control

The protocol automates transport and review visibility. It does not remove human approval. The project owner remains the final authority for merge, release, and scope changes.
