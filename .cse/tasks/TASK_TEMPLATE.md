# CSE Task Template

## Identity
- Step:
- Issue:
- Branch:
- Base commit:
- Reasoning level:

## Goal
Describe one small, testable, reversible objective.

## Allowed Changes
- List exact files or directories that may change.

## Forbidden Scope
- No unrelated refactor.
- No production behavior outside the stated goal.
- No ZIP files.
- No export output.
- No hard validation unless explicitly authorized.
- No API/GUI/CLI, database/repository, audit, backup/restore, or migration behavior unless explicitly authorized.

## Required Checks
- `python -m pytest`
- `git diff --check`
- Confirm changed files match scope.
- Confirm `exports/` remains clean.
- Confirm ignored ZIP files remain untouched.

## Commit / Push Permission
State explicitly whether Codex may commit, push, and open a draft PR.

## Required Result
Write `.cse/results/<step>_result.md` and update `.cse/state/project_state.json` before opening or updating the draft PR.
