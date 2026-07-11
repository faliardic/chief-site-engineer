# Step NNN Task

## Objective

Describe one small, testable, reversible outcome.

## Repository Context

- Repository: `faliardic/chief-site-engineer`
- Base branch: `master`
- Expected base commit: `<sha>`
- Working branch: `step-NNN-<purpose>`
- Official local working directory: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`

## Local-First Preconditions

- Work must start from the official local repository.
- GitHub-only project file creation or editing is incomplete.
- Before branch changes, pulls, edits, commits, or pushes, inspect:

```powershell
git status --short --branch
git status --ignored --short --untracked-files=all
```

- If unexpected tracked, staged, or untracked project changes exist, stop and report them. Do not reset, clean, stash, delete, or overwrite.
- Existing ignored ZIP files must remain untouched.

## Required Master Synchronization

Run from the official local repository before branch work:

```powershell
git fetch origin --prune
git checkout master
git pull --ff-only origin master
git rev-parse master
git rev-parse origin/master
git rev-list --left-right --count origin/master...master
```

Required evidence:

- Local `master` SHA: `<sha>`
- `origin/master` SHA: `<sha>`
- Master divergence: `0 0`

## Local Branch Requirement

- Create or check out the step branch locally after synchronized `master`.
- Record branch creation source and branch SHA.
- Verify local/remote divergence after push:

```powershell
git rev-parse HEAD
git rev-parse origin/step-NNN-<purpose>
git rev-list --left-right --count origin/step-NNN-<purpose>...HEAD
```

## Physical Local File Requirement

All task, result, state, documentation, and project files for this step must physically exist in the official local working tree before completion.

## Reasoning Level

- Codex: `<high|extra high>`
- ChatGPT review: `<High|Extra High>`

## Authorized Changes

- `.cse/tasks/NNN_task.md`
- `.cse/results/NNN_result.md`
- `.cse/state/project_state.json`
- `<path or file group>`

## Required Work

1. `<action>`
2. `<action>`

## Required Verification

- `python -m pytest`
- `git diff --check`
- `git diff -- app/models.py tests/test_models.py .github/workflows/pytest.yml` must be empty unless explicitly authorized.
- Confirm changed/staged files match scope.
- Confirm `exports/` is clean unless explicitly authorized.
- Confirm ignored ZIP files remain untouched.
- Confirm required files physically exist in the official local working tree.
- Confirm local/remote branch divergence is reported.
- Confirm final working tree status is reported.

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
- Merge: `<allowed|not allowed>`

## Post-Merge Sync Boundary

After merge, local `master` must be fast-forwarded from `origin/master` before any next step begins. Do not start future work from stale local `master`.

## Required Result Files

- `.cse/results/NNN_result.md`
- `.cse/state/project_state.json`

## Completion Criteria

- Work stays inside scope.
- Required checks pass.
- Local `master` sync evidence is recorded.
- Branch divergence evidence is recorded.
- Required files exist physically in the official local working tree.
- Result report is complete and factual.
- No unrelated files change.
- The branch is ready for ChatGPT review.
