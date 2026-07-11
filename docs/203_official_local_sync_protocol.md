# Step 203 - Official Local Sync Protocol

## Purpose

Step 203 records the local-first protocol required for Codex execution after Issue #21. The official local repository working copy is the primary place where project files must be created, edited, verified, committed, and pushed.

Official local repository path:

```text
V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer
```

GitHub remains the synchronized remote and review surface. GitHub connector or web/API state alone is not sufficient evidence that project files were created correctly.

## Safety Rule

Before changing branches, pulling, creating a branch, editing files, or committing, inspect the local working tree:

```powershell
git status --short --branch
git status --ignored --short --untracked-files=all
```

If unexpected tracked, staged, or untracked project changes are present, stop and report them. Do not reset, clean, stash, delete, or overwrite user changes automatically.

The existing ignored ZIP is an emergency/offline artifact and must remain untouched.

## Required Sync Sequence

Use the official local repository only:

```powershell
Set-Location 'V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer'

git status --short --branch
git remote -v
git fetch origin --prune

git checkout master
git pull --ff-only origin master

git rev-parse master
git rev-parse origin/master
git rev-list --left-right --count origin/master...master
```

For Step 203, both `master` and `origin/master` must equal:

```text
a5fcadf1108dce409d7a1ddd9928b6a9cbb730c9
```

The divergence result must be:

```text
0 0
```

Then create the local Step 203 branch from synchronized `master`:

```powershell
git checkout -b step-203-official-local-sync-protocol
```

If a future task already has a local branch, inspect status first, then use fast-forward-only synchronization. Do not overwrite local work.

## Local File Presence Requirement

Completion requires the authorized files to physically exist in the official local working tree. For Step 203, that includes:

- `.cse/tasks/203_task.md`
- `docs/203_official_local_sync_protocol.md`
- `learning/203_official_local_sync_protocol.md`
- `.cse/results/203_result.md`
- `.cse/state/project_state.json`
- `ROADMAP.md`
- `CHANGELOG.md`
- `docs/project_decisions.md`

For later steps, apply the same rule to that step's task, docs, learning, result, state, and authorized project documentation files.

## Required Local Verification

Run verification from the official local repository:

```powershell
git rev-parse HEAD
git rev-parse origin/<branch>
git rev-list --left-right --count origin/<branch>...HEAD
git status --short --branch
python -m pytest
git diff --check
git diff -- app/models.py tests/test_models.py .github/workflows/pytest.yml
```

Also confirm:

- `exports/` contains only `.gitkeep`
- ignored ZIP files remain untouched
- no production code, tests, or workflow behavior changed unless explicitly authorized by the issue/task
- no generated `blocked` status, hard validation, API/GUI/CLI, persistence, audit, backup/restore, migration, export output, or ZIP mutation was added unless explicitly authorized

## Commit and Push Rule

Stage only authorized files:

```powershell
git add -- <authorized files>
git diff --cached --name-status
git diff --cached --check
```

Commit from the official local repository and push the branch:

```powershell
git commit -m "<step summary>"
git push origin <branch>
```

For Issue #21, Codex must not open the draft PR. ChatGPT will inspect the pushed branch and open the draft PR.

## Required Report Fields

Each local-first execution should report:

- exact local path used
- pre-sync branch and status
- synchronized `origin/master` SHA
- local `master` SHA after pull
- local branch SHA
- remote branch SHA
- divergence result
- changed files committed
- pytest result
- `git diff --check` result
- protected-path diff result
- final `git status --short --branch`
- export status
- ignored ZIP status
- correction or work commit SHA and push result

## Boundary

This protocol is documentation/state guidance only. It does not add production code, tests, workflow changes, required checks, API/GUI/CLI behavior, persistence, audit, backup/restore, migration, hard validation, export output, ZIP mutation, or automatic merge behavior.
