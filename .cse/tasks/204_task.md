# Step 204 Task

## Objective

Create a documentation/state-only fixture naming, ownership, location, and assertion checklist plan for a future handover QC presentation view-model implementation.

## Repository Context

- Repository: `faliardic/chief-site-engineer`
- Base branch: `master`
- Expected base commit: `583f8539d9522027f1578a91b0298a8bdf21a1c9`
- Working branch: `step-204-handover-qc-fixture-assertion-plan`
- Official local working directory: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Source instruction: Issue #23, "Codex execution instruction - local-first mandatory", plus the authorized Step 204 correction instruction on the current branch

## Local-First Preconditions

- Work must run in the official local repository.
- Before branch changes, pulls, edits, commits, or pushes, inspect:

```powershell
git status --short --branch
git status --ignored --short --untracked-files=all
git remote -v
```

- If unexpected tracked, staged, or untracked project changes exist, stop and report them. Do not reset, clean, stash, delete, move, or overwrite them.
- `CSE_GUNCEL_PROJE_TALIMATLARI.md` is local-only and outside Step 204 scope. It may be ignored only through `.git/info/exclude`; it must not be changed, staged, or committed, and `.gitignore` must not be changed for it.
- `chief-site-engineer_adim_080_guvenli_nokta.zip` remains local-only and ignored. It must not be opened, changed, copied, regenerated, deleted, moved, staged, or committed.

## Required Synchronization Evidence

```powershell
git fetch origin --prune
git rev-parse master
git rev-parse origin/master
git rev-list --left-right --count origin/master...master
git rev-parse HEAD
git rev-parse origin/step-204-handover-qc-fixture-assertion-plan
git rev-list --left-right --count origin/step-204-handover-qc-fixture-assertion-plan...HEAD
```

Required master evidence:

- Local `master`: `583f8539d9522027f1578a91b0298a8bdf21a1c9`
- `origin/master`: `583f8539d9522027f1578a91b0298a8bdf21a1c9`
- Master divergence: `0 0`

## Reasoning Level

- Codex: `Extra High`
- ChatGPT review: `Extra High`

## Authorized Project Files

- `.cse/tasks/204_task.md`
- `.cse/results/204_result.md`
- `.cse/state/project_state.json`
- `docs/204_handover_qc_fixture_naming_and_assertion_checklist_plan.md`
- `learning/204_handover_qc_fixture_naming_and_assertion_checklist_plan.md`
- `ROADMAP.md`
- `CHANGELOG.md`
- `docs/project_decisions.md`

## Required Plan

1. Preserve the seven canonical cases: `success_only`, `failure_only`, `mixed`, `empty_zero_count`, `missing_optional_fields`, `unknown_status_additional_fields`, and `unsupported_input_fallback`.
2. Define four separate future artifact families for every case:
   - `handover_qc_source_checklist_<case>`
   - `handover_qc_expected_view_model_<case>`
   - `handover_qc_expected_markdown_<case>`
   - `handover_qc_expected_review_visibility_<case>`
3. Document future fixture ownership under `tests/fixtures/handover_qc/` without creating that directory or any executable fixture/test file.
4. Keep `build_export_handover_qc_review_checklist(summary, report)` as structured source of truth.
5. Keep `format_export_handover_qc_review_checklist_as_markdown(checklist)` optional and display-only; Markdown must not be parsed as structured truth.
6. Define assertion boundaries for canonical wording, empty and unsupported fallbacks, immutability, no recomputation, no side effects, read-only/non-blocking semantics, private/non-transferable exclusion, and absence of decision fields or generated `blocked` state.
7. Define exactly one narrow future implementation proposal without assigning a step number:

```text
A separate explicitly authorized future task may create canonical
fixture data and fixture-contract tests for the seven documented
handover QC cases.
```

That future task may create only the seven canonical source/expected fixture sets and fixture schema/integrity tests. It may not add a presentation consumer, production behavior, API/GUI/CLI behavior, persistence, database/repository access, audit, export writing, hard validation, automatic decisions, package blocking, or generated `blocked` status.

## Two-Phase Finalization

1. Commit and push the content correction using only the task, renamed plan and learning documents, roadmap, changelog, and project decision files.
2. Record the verified content-correction local/remote SHA and `0 0` divergence in result/state, then commit and push only `.cse/results/204_result.md` and `.cse/state/project_state.json`.
3. The metadata-finalization commit cannot contain its own SHA. Final branch-head evidence belongs in the Issue #23 completion comment after the second push.

## Required Verification

- `python -m pytest`
- `git diff --check`
- `git diff -- app/models.py tests/test_models.py .github/workflows/pytest.yml` must be empty.
- Changed and staged files must match the explicit phase scope.
- Required files must physically exist and old shortened paths/references must be absent.
- `exports/` must contain only tracked `.gitkeep`.
- The ZIP and local-only instruction file must remain unchanged and ignored.
- GitHub Actions must not be re-enabled or changed.
- Final local/remote branch divergence must be `0 0`.

## Forbidden Scope

Do not add or modify executable fixtures, executable tests, production code, workflow behavior, required status checks, API/GUI/CLI behavior, persistence, database/repository behavior, audit, backup/restore, migration, hard validation, generated `blocked` status, export output, ZIP contents, automatic acceptance/rejection/approval, official transfer decisions, or package blocking.

## Publication Boundary

- Commit: allowed on the current branch.
- Ordinary Git push: allowed to the current remote branch.
- GitHub Actions: must not be re-enabled.
- Pull request creation by Codex: not allowed.
- Merge: not allowed.
- Force push: not allowed.
- Step 205: must not begin.

## Completion Criteria

- Work remains documentation/state-only.
- All required checks and integrity checks pass.
- Two scoped commits are pushed with local/remote divergence `0 0`.
- Factual final evidence is posted to Issue #23.
- The next action is ChatGPT re-inspection and Draft PR creation after final remote evidence; do not merge.
