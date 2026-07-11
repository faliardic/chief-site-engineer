# Step 206 Task

## Objective

Finalize the Step 205 merged truth, add Podcast 031 for Steps 201-205, refresh podcast cadence documentation, and close the instruction-authority gap by making the tracked canonical protocol the single authoritative project instruction source.

This is documentation/state/protocol work only. It must not add product behavior.

## Repository Context

- Repository: `faliardic/chief-site-engineer`
- Issue: `#28`
- Base branch: `master`
- Expected base commit: `92a15f2a55e6bfda42d50b8ef7dea651ff496f62`
- Working branch: `step-206-podcast-031-and-authority-closure`
- Official local working directory: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Required latest safe point after master sync: Step 205, PR #26 merged, Issue #25 completed

## Reasoning Level

- Codex: `High`
- ChatGPT review: `High`

## Mandatory Workspace Preflight

Before any Git operation or file write:

```powershell
Set-Location 'V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer'

$expected = (Resolve-Path 'V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer').Path
$actual = (git rev-parse --show-toplevel)

if ((Resolve-Path $actual).Path -ne $expected) {
    throw 'Wrong repository root. Stop without changing anything.'
}

git status --short --branch
git status --ignored --short --untracked-files=all
git remote -v
Test-Path 'C:\Users\Fatih\Documents\chieh-site-engineer'
```

Expected misspelled workspace result: `False`.

Do not recreate, clone into, or use that misspelled path. Do not modify the separate Desktop archive repository:

```text
C:\Users\Fatih\Desktop\fatih\chief-site-engineer
```

## Required Master Synchronization

```powershell
git fetch origin --prune
git checkout master
git pull --ff-only origin master
git rev-parse master
git rev-parse origin/master
git rev-list --left-right --count origin/master...master
```

Required evidence:

- Local `master`: `92a15f2a55e6bfda42d50b8ef7dea651ff496f62`
- `origin/master`: `92a15f2a55e6bfda42d50b8ef7dea651ff496f62`
- Master divergence: `0 0`

## Authorized Tracked Files

- `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
- `README.md`
- `.cse/tasks/206_task.md`
- `.cse/results/206_result.md`
- `.cse/state/project_state.json`
- `ROADMAP.md`
- `CHANGELOG.md`
- `docs/project_decisions.md`
- `docs/podcast_notes/031_adim_201_205_notebooklm_podcast_notu.md`
- `docs/podcast_notes/README.md`
- `docs/206_step_205_merged_truth_podcast_031_and_instruction_authority_closure.md`
- `learning/206_step_205_merged_truth_podcast_031_and_instruction_authority_closure.md`

No other tracked project file is authorized.

## Authorized Local-Only File

- `CSE_GUNCEL_PROJE_TALIMATLARI.md`: update only as an ignored local mirror that exactly matches `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`; keep unstaged and uncommitted.

Do not modify `.gitignore`; the mirror remains excluded through `.git/info/exclude`.

## Required Work

1. Make `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md` the single authoritative project instruction source.
2. Define `CSE_GUNCEL_PROJE_TALIMATLARI.md` as an optional local convenience mirror only.
3. Update the local mirror to match the canonical content exactly while leaving it ignored, unstaged, and uncommitted.
4. Record canonical and mirror SHA-256 values and text equivalence in `.cse/results/206_result.md`.
5. Harden the official workspace rule with exact root verification, wrong-root stop behavior, no automatic `C:` clone/workspace, and GitHub Issue evidence exchange.
6. Update repository truth so Step 205 / PR #26 / Issue #25 / merge commit `92a15f2a55e6bfda42d50b8ef7dea651ff496f62` is the latest merged/finalized safe point.
7. During this branch, record active work as Issue #28 / Step 206 / `step-206-podcast-031-and-authority-closure`; do not write final Step 206 merge claims.
8. Create Podcast 031 for Steps 201-205 only.
9. Refresh `docs/podcast_notes/README.md` so it uses durable cadence and factual Podcast 030/031 state rather than stale Step 022 status.
10. Record the Desktop archive repository risk as unresolved and non-blocking without touching it.

## Required Verification

- `python -m pytest`
- `git diff --check`
- `git diff -- app/models.py tests/test_models.py .github/workflows/pytest.yml` must be empty.
- `git diff --name-status master...HEAD`
- `git status --short --branch`
- `git status --ignored --short --untracked-files=all`
- `python -m json.tool .cse/state/project_state.json`
- Verify exact official repository root.
- Verify misspelled `C:` workspace remains absent.
- Verify canonical/root mirror SHA-256 and text equivalence.
- Verify all required files physically exist in the official `V:` working tree.
- Verify protected path diff is empty.
- Verify `exports/` contains only `.gitkeep`.
- Verify ignored ZIP remains unchanged.
- Verify Desktop archive repository remains untouched.
- Verify Podcast 031 covers exactly Steps 201-205.
- Verify old Step 022 podcast README current-state text is removed.
- Verify README/state/roadmap/canonical instructions agree on Step 205 as latest safe point and Step 206 as active work.

## Forbidden Scope

Do not add or modify production code, executable tests/fixtures, workflow behavior, Actions enablement, required checks, API/GUI/CLI behavior, persistence/database/repository behavior, audit behavior, backup/restore or migration behavior, hard validation, generated `blocked`, export output, ZIP contents, Desktop archive contents, Step 207, field-MVP implementation, automatic acceptance/rejection/approval, official-transfer decisions, or package blocking.

## Publication Permissions

- Commit: allowed
- Ordinary Git push: allowed
- Force push: forbidden
- PR creation by Codex: forbidden
- Merge: forbidden
- Branch deletion: forbidden

After push, verify local/remote branch SHA equality and divergence `0 0`, add factual completion evidence to Issue #28, and stop.
