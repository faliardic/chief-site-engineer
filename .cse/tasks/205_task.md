# Step 205 Task

## Objective

Canonicalize the current project instructions inside the repository and resynchronize the principal truth-bearing documentation/state records with the merged Step 204 safe point, without changing production, test, workflow, or product behavior.

## Repository Context

- Repository: `faliardic/chief-site-engineer`
- Issue: `#25`
- Base branch: `master`
- Expected base commit: `7e5a06ed3cb62399219f9ad66b6b2b8e6eca77a3`
- Working branch: `step-205-project-instructions-truth-sync`
- Official local working directory: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Highest-priority execution source: local-only `CSE_GUNCEL_PROJE_TALIMATLARI.md`
- Expected source SHA-256: `A03C207BE84425F793C962DFA2C9A1E09EDCF739761465FFE5C57D3BFA0E123F`

## Local-First Preconditions

Before branch changes, pulls, edits, commits, or pushes, run:

```powershell
git status --short --branch
git status --ignored --short --untracked-files=all
git remote -v
```

If unexpected tracked, staged, or untracked project changes exist, stop and report them. Do not reset, clean, stash, delete, move, rename, or overwrite user work.

The following local-only files must remain untouched:

- `CSE_GUNCEL_PROJE_TALIMATLARI.md`: ignored only through `.git/info/exclude`, unchanged, unstaged, and uncommitted
- `chief-site-engineer_adim_080_guvenli_nokta.zip`: ignored and unchanged

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

- Local `master`: `7e5a06ed3cb62399219f9ad66b6b2b8e6eca77a3`
- `origin/master`: `7e5a06ed3cb62399219f9ad66b6b2b8e6eca77a3`
- Master divergence: `0 0`

## Reasoning Level

- Codex: `High`
- ChatGPT review: `High`

## Authorized Project Files

- `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
- `README.md`
- `.cse/tasks/205_task.md`
- `.cse/results/205_result.md`
- `.cse/state/project_state.json`
- `docs/205_canonical_project_instructions_and_repository_truth_resynchronization.md`
- `learning/205_canonical_project_instructions_and_repository_truth_resynchronization.md`
- `ROADMAP.md`
- `CHANGELOG.md`
- `docs/project_decisions.md`

No other project file is authorized.

## Required Work

1. Copy the complete local instruction source to `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md` while preserving source meaning/order and proving text equivalence.
2. Keep the root source unchanged, local-only, ignored, unstaged, and uncommitted.
3. Correct README current state, test count, CI/Actions truth, product maturity, missing production capabilities, canonical instruction path, and first field-MVP direction.
4. Update machine-readable state so Step 204 and PR #24 are the latest merged/finalized safe point, Issue #23 is complete, Actions is manually disabled, required checks are disabled, and Step 205 remains documentation/state-only.
5. Update roadmap, changelog, and project decisions with the canonical instruction decision, truth correction, reliable-data-backbone-first rule, first field MVP, and Podcast 031 follow-up.
6. Create the Step 205 documentation and learning records.
7. Record only factual command evidence in result/state.

## Two-Phase Evidence Finalization

1. Commit and push the canonical/content truth synchronization without `.cse/results/205_result.md` final evidence.
2. Verify the content commit local/remote SHA equality and divergence `0 0`.
3. Finalize only result/state with the verified content SHA and factual checks, commit, and push.
4. Report the final metadata commit SHA and final divergence in the Issue #25 completion comment because a commit cannot contain its own SHA.

## Required Verification

- `python -m pytest`
- `git diff --check`
- `git diff -- app/models.py tests/test_models.py .github/workflows/pytest.yml` must be empty.
- `git diff --name-status master...HEAD`
- `git status --short --branch`
- `git status --ignored --short --untracked-files=all`
- Verify all required Step 205 files physically exist.
- Verify canonical/source SHA-256 and text equivalence.
- Verify README no longer presents Step 127 or `243 passed` as current.
- Verify state no longer presents Step 202/203 or PR #22 as the current active merged state.
- Verify `exports/` contains only `.gitkeep`.
- Verify ZIP hash, length, and timestamp are unchanged.
- Verify changed files match the authorized list.
- After push, verify local/remote branch SHA equality and divergence `0 0`.

## Forbidden Scope

Do not add or modify production code, executable tests/fixtures, `.github/workflows/pytest.yml`, GitHub Actions enablement, required status checks, API/GUI/CLI behavior, persistence/database/repository behavior, audit behavior, backup/restore or migration behavior, hard validation, generated `blocked`, export output, ZIP contents, automatic acceptance/rejection/approval, official-transfer decisions, or package blocking.

## Publication Permissions

- Commit: allowed
- Ordinary Git push: allowed
- Force push: not allowed
- PR creation by Codex: not allowed
- Merge: not allowed
- Branch deletion: not allowed
- Step 206 or product implementation: not allowed

## Post-Merge Sync Boundary

After merge, local `master` must be fast-forwarded from `origin/master` before any next step begins.

## Completion Criteria

- Canonical instructions are tracked at the required path and equivalent to the local-only source.
- README, state, roadmap, changelog, and decisions agree on Step 204 safe point and current maturity/CI truth.
- Required checks pass and changed files remain authorized.
- Content and final branch push evidence is factual with divergence `0 0`.
- Issue #25 receives completion evidence.
- Codex stops without PR, merge, Step 206, or product implementation.
