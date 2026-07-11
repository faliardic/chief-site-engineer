# Step 204 Task

## Objective

Create a documentation-only fixture naming and assertion checklist plan for a future handover QC presentation view-model implementation.

## Repository Context

- Repository: `faliardic/chief-site-engineer`
- Base branch: `master`
- Expected base commit: `583f8539d9522027f1578a91b0298a8bdf21a1c9`
- Working branch: `step-204-handover-qc-fixture-assertion-plan`
- Official local working directory: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Source instruction: Issue #23, "Codex execution instruction - local-first mandatory"

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

- Local `master` SHA: `583f8539d9522027f1578a91b0298a8bdf21a1c9`
- `origin/master` SHA: `583f8539d9522027f1578a91b0298a8bdf21a1c9`
- Master divergence: `0 0`

## Local Branch Requirement

- Create or check out `step-204-handover-qc-fixture-assertion-plan` locally after synchronized `master`.
- Record branch creation source and branch SHA.
- Verify local/remote divergence after push:

```powershell
git rev-parse HEAD
git rev-parse origin/step-204-handover-qc-fixture-assertion-plan
git rev-list --left-right --count origin/step-204-handover-qc-fixture-assertion-plan...HEAD
```

## Physical Local File Requirement

All task, result, state, documentation, learning, roadmap, changelog, and project decision files for this step must physically exist in the official local working tree before completion.

## Reasoning Level

- Codex: `extra high`
- ChatGPT review: `Extra High`

## Authorized Changes

- `.cse/tasks/204_task.md`
- `.cse/results/204_result.md`
- `.cse/state/project_state.json`
- `docs/204_handover_qc_fixture_assertion_plan.md`
- `learning/204_handover_qc_fixture_assertion_plan.md`
- `ROADMAP.md`
- `CHANGELOG.md`
- `docs/project_decisions.md`

## Required Work

1. Record the local-first synchronization evidence from Issue #23.
2. Create a documentation-only fixture naming plan for future handover QC presentation view-model fixtures.
3. Cover these canonical source scenarios from Step 202:
   - `success_only`
   - `failure_only`
   - `mixed`
   - `empty_zero_count`
   - `missing_optional_fields`
   - `unknown_status_additional_fields`
   - `unsupported_input_fallback`
4. Define future fixture names without creating executable fixture files:
   - `handover_qc_view_model_success_only`
   - `handover_qc_view_model_failure_only`
   - `handover_qc_view_model_mixed`
   - `handover_qc_view_model_empty_zero_count`
   - `handover_qc_view_model_missing_optional_fields`
   - `handover_qc_view_model_unknown_status_additional_fields`
   - `handover_qc_view_model_unsupported_input_fallback`
5. Define assertion checklist categories for source of truth, status labels, human-review indicators, read-only/non-blocking notices, item rows, empty state, unknown status, optional Markdown display-only handling, official/private boundary, no decision fields, no side effects, immutability, no recomputation, and no generated `blocked` status.
6. Define documentation-only future fixture metadata fields such as `source_checklist_case`, `expected_view_model_case`, `required_assertions`, `forbidden_fields`, `transfer_boundary_assertions`, and `side_effect_assertions`.
7. State that a future implementation step may convert the plan into executable fixtures/tests only with a separate explicit task.
8. Update result, state, roadmap, changelog, and project decision records with factual evidence.

## Required Verification

- `python -m pytest`
- `git diff --check`
- `git diff -- app/models.py tests/test_models.py .github/workflows/pytest.yml` must be empty.
- Confirm changed/staged files match scope.
- Confirm `exports/` is clean.
- Confirm ignored ZIP files remain untouched.
- Confirm required files physically exist in the official local working tree.
- Confirm local/remote branch divergence is reported.
- Confirm final working tree status is reported.

## Forbidden Scope

Unless explicitly authorized, do not add or modify:

- executable fixture files
- executable tests
- production code
- workflow files
- hard validation or automatic blocking
- generated `blocked` status
- API, GUI, or CLI behavior
- database or repository access
- audit event behavior
- backup/restore or migration behavior
- persistence behavior
- export output files
- ignored ZIP files
- pull request creation or merge

## Commit and Push Permission

- Commit: `allowed`
- Push: `allowed`
- Pull request: `not allowed by Codex for Issue #23`
- Merge: `not allowed`

## Post-Merge Sync Boundary

After merge, local `master` must be fast-forwarded from `origin/master` before any next step begins. Do not start future work from stale local `master`.

## Required Result Files

- `.cse/results/204_result.md`
- `.cse/state/project_state.json`

## Completion Criteria

- Work stays documentation/state-only.
- No executable fixtures, tests, production code, or workflow files are added or changed.
- Required checks pass.
- Local `master` sync evidence is recorded.
- Branch divergence evidence is recorded.
- Required files exist physically in the official local working tree.
- Result report is complete and factual.
- No unrelated files change.
- The branch is pushed for ChatGPT inspection and draft PR creation.
