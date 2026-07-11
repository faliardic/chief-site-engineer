# Step NNN Task

## Objective

Describe one small, testable, reversible outcome.

## Repository Context

- Repository: `faliardic/chief-site-engineer`
- Base branch: `master`
- Expected base commit: `<sha>`
- Working branch: `step-NNN-<purpose>`
- Local working directory: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`

## Reasoning Level

- Codex: `<high|extra high>`
- ChatGPT review: `<High|Extra High>`

## Authorized Changes

- `<path or file group>`

## Required Work

1. `<action>`
2. `<action>`

## Required Verification

- `python -m pytest`
- `git diff --check`
- Confirm staged files match scope.
- Confirm `exports/` is clean unless explicitly authorized.
- Confirm ignored ZIP files remain untouched.
- Confirm unrelated production code and tests are unchanged.

## Forbidden Scope

Unless explicitly authorized, do not add or modify:

- hard validation or automatic blocking
- generated `blocked` status
- API, GUI, or CLI behavior
- database or repository access
- audit event behavior
- backup/restore or migration behavior
- export output files
- ignored ZIP files

## Commit and Push Permission

- Commit: `<allowed|not allowed>`
- Push: `<allowed|not allowed>`
- Pull request: `<draft|required|not allowed>`

## Required Result Files

- `.cse/results/NNN_result.md`
- `.cse/state/project_state.json`

## Completion Criteria

- Work stays inside scope.
- Required checks pass.
- Result report is complete and factual.
- No unrelated files change.
- The branch is ready for ChatGPT review.
