# Step 207 Task

## Objective

Add the unified project source and permanent Codex invocation / batched execution policy, update GitHub-native new-chat bootstrap rules, and refresh repository truth after the Step 206 merge.

This is documentation/state/protocol work only.

## Required Sources Read

Codex must read these sources before editing:

1. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
2. `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
3. GitHub Issue #30, including all scope-extension comments
4. `.cse/tasks/207_task.md`

Additional source read for this workflow/source-authority task:

- `docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md` after it is created

If a required tracked source is missing after it should exist, or the current task contradicts an unresolved permanent rule, stop before further edits and report.

## Repository Context

- Repository: `faliardic/chief-site-engineer`
- Issue: `#30`
- Base branch: `master`
- Expected base commit: `3b05fae76766cedc8840eea6c0fc2f51440354e4`
- Latest merged safe point: Step 206 / PR #29 / Issue #28
- Working branch: `step-207-codex-invocation-policy`
- Official local working directory: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`

## Reasoning Level

- Codex: `High`
- ChatGPT review: `High`

## Synchronized Master Evidence

Required before branch work:

- Local `master`: `3b05fae76766cedc8840eea6c0fc2f51440354e4`
- `origin/master`: `3b05fae76766cedc8840eea6c0fc2f51440354e4`
- Master divergence: `0 0`

The Step 207 branch already exists on GitHub and must be checked out locally rather than recreated.

## Authorized Tracked Files

- `.cse/tasks/207_task.md`
- `.cse/results/207_result.md`
- `.cse/state/project_state.json`
- `.cse/README.md`
- `.cse/templates/task_template.md`
- `.cse/templates/result_template.md`
- `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
- `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
- `docs/protocols/CSE_PROJECT_SOURCE_REGISTER.md`
- `docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md`
- `docs/reference_sources/**` only for genuinely accessible, non-fabricated source files
- `README.md`
- `ROADMAP.md`
- `CHANGELOG.md`
- `docs/project_decisions.md`
- `docs/207_codex_invocation_and_batched_execution_policy.md`
- `learning/207_codex_invocation_and_batched_execution_policy.md`

## Authorized Local-Only File

- `CSE_GUNCEL_PROJE_TALIMATLARI.md`: update only as ignored local mirror of `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`; keep unstaged and uncommitted.

## Required Work

1. Create `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md` from the approved source file `CHIEF_SITE_ENGINEER_EXE_BIRLESTIRILMIS_PROJE_KAYNAGI.md` without reconstructing or shortening it.
2. Create `docs/protocols/CSE_PROJECT_SOURCE_REGISTER.md`.
3. Copy genuinely accessible non-duplicate reference sources into `docs/reference_sources/` using ASCII-safe filenames.
4. Add the authority model separating unified product source, operational instructions, issue/task scope, and state/result evidence.
5. Add mandatory Codex pre-read rules to canonical instructions, `.cse/README.md`, and task/result templates.
6. Add the ChatGPT decision rule: say `Codex çalışmalı` only when local execution is needed and explain why.
7. Add Codex-required / Codex-not-required categories.
8. Add batched execution, post-merge sync batching, and metadata-churn avoidance policy.
9. Add GitHub-native new-chat bootstrap document and references.
10. Update Step 206 merged truth: Step 206 / PR #29 / Issue #28 / merge commit `3b05fae76766cedc8840eea6c0fc2f51440354e4` is latest safe point; Step 207 is active unmerged documentation/protocol work.
11. Keep Podcast 031 as latest and next podcast range as Steps 206-210.
12. Sync ignored root mirror with canonical instructions.

## Required Verification

- `python -m pytest`
- `git diff --check`
- `python -m json.tool .cse/state/project_state.json`
- `git diff -- app/models.py tests/test_models.py .github/workflows/pytest.yml` must be empty.
- Changed/staged files match authorized scope.
- `exports/` contains only `.gitkeep`.
- Ignored ZIP remains unchanged.
- Canonical/root mirror SHA-256 and text equivalence.
- Unified source physically exists in the official `V:` working tree.
- Unified source is referenced by canonical instructions, `.cse/README.md`, and both templates.
- Source register exists and classifies every project source.
- No duplicate `(1)` source copy is tracked.
- Raw handoff ZIP is not tracked.
- Required-source pre-read fields exist in task/result templates.
- Result confirms the four-source pre-read order.
- Branch SHA/divergence after push.

## Forbidden Scope

No production code, executable tests/fixtures, workflow changes, Actions enablement, required checks, API/GUI/CLI implementation, persistence, audit, backup/restore, migration, hard validation, generated `blocked`, export output, ZIP mutation, Desktop archive mutation, Step 208, field-MVP implementation, raw ZIP package commit, replacement handoff ZIP, PR creation by Codex, merge, force push, or branch deletion.

## Commit and Push Permission

- Commit: `allowed`
- Push: `allowed`
- Pull request creation by Codex: `not allowed`
- Merge: `not allowed`
- Force push: `not allowed`
- Branch deletion: `not allowed`

## Completion Criteria

- Work stays inside authorized documentation/state/protocol scope.
- Required sources are read and conflicts are reported factually.
- Required local checks pass.
- Branch is pushed with local/remote divergence `0 0`.
- Factual completion evidence is posted to GitHub Issue #30.
