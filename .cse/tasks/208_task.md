# Step 208 Task

## Objective

Define the documentation-level future data contract for the first Field MVP fast observation record named `FieldObservationRecord`.

This step returns the project from protocol/source consolidation to direct field value while keeping the work contract-only. It must not implement the model or change production behavior.

## Repository Context

- Repository: `faliardic/chief-site-engineer`
- Base branch: `master`
- Expected base commit: `23baddf413e1cdf5a5e5564fe4a559954572e45f`
- Latest merged safe point: Step 207 / PR #31 / Issue #30
- Working branch: `step-208-first-field-mvp-observation-contract`
- Official local working directory: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`

## Required Sources Read

Codex must read these sources in order before editing:

1. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
2. `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
3. GitHub Issue #32
4. `.cse/tasks/208_task.md`

If a required tracked source is missing or the task contradicts an unresolved permanent product/data/safety rule, stop before edits and report.

## Local-First Preconditions

- Work must start from the official local repository.
- Inspect the worktree before branch changes, pulls, edits, commits, or pushes.
- Do not reset, clean, stash, delete, move, rename, or overwrite user work.
- Existing ignored ZIP files must remain untouched.
- Verify `C:\Users\Fatih\Documents\chieh-site-engineer` remains absent.

## Required Master Synchronization

Before branch work, synchronize local `master` with:

```powershell
git fetch origin --prune
git checkout master
git pull --ff-only origin master
git rev-parse master
git rev-parse origin/master
git rev-list --left-right --count origin/master...master
```

Required evidence:

- Local `master` SHA: `23baddf413e1cdf5a5e5564fe4a559954572e45f`
- `origin/master` SHA: `23baddf413e1cdf5a5e5564fe4a559954572e45f`
- Master divergence: `0 0`

## Local Branch Requirement

- Create `step-208-first-field-mvp-observation-contract` locally after synchronized `master`.
- Commit and ordinary push are allowed.
- Do not force push, create a PR, merge, or delete the branch.

## Reasoning Level

- Codex: High
- ChatGPT review: High

## Authorized Changes

Create:

- `.cse/tasks/208_task.md`
- `.cse/results/208_result.md`
- `docs/208_first_field_mvp_observation_record_contract.md`
- `learning/208_first_field_mvp_observation_record_contract.md`

Update:

- `.cse/state/project_state.json`
- `README.md`
- `ROADMAP.md`
- `CHANGELOG.md`
- `docs/project_decisions.md`
- `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`

No other project file is authorized.

## Existing Boundaries To Inspect Without Modifying

- `app/models.py`
- `tests/test_models.py`
- `SiteProject`
- `SiteLocationRecord`
- `ContactPersonRecord`
- `SiteNoteRecord`
- `TrackingRecord`
- `FileAttachmentRecord`
- `DailySiteLog`
- `DailyReportRecord`

## Required Work

1. Define a documentation-level future model contract named `FieldObservationRecord`.
2. Document required future fields: `observation_id`, `project_id`, `observed_at`, `location`, `category`, and `description`.
3. Document `status` default `open` and first vocabulary: `open`, `tracking`, `closed`.
4. Document optional/deferred-at-capture fields: `reported_to`, `reported_at`, `created_by`, `closed_at`, `notes`, and `is_archived`.
5. Document relationship boundaries:
   - `project_id` relates to `SiteProject`.
   - `location` is a fast-capture V1 text/snapshot field; future structured normalization may use `SiteLocationRecord`.
   - `reported_to` is a fast-capture text/snapshot field; future identity/contact normalization may use `ContactPersonRecord`.
   - Attachments stay in separate `FileAttachmentRecord` rows with `related_record_type = "field_observation"` and `related_record_id = observation_id`.
   - Daily export and weekly summary consume observation records later.
   - No attachment list or binary data is embedded in the observation record.
6. Document behavioral boundaries:
   - Initial record creation must not require an attachment.
   - Initial record creation must not require `reported_to`.
   - Attachment or reporting may happen after initial capture.
   - `closed` is lifecycle state, not physical deletion.
   - Archive is separate from closed.
   - No automatic `blocked`, acceptance, rejection, official decision, task creation, NCR conversion, or audit event is generated.
   - Private notes are not silently copied into official records.
   - Future conversion from a private note requires explicit user action.
   - No hard validation, persistence, repository, API, GUI, CLI, migration, audit, backup/restore, or file-writing behavior is added.
7. Include an existing-model mapping and gap analysis table covering the required models.
8. Record Step 209 as the recommended implementation step only after this contract is reviewed and merged.
9. Update repository truth so Step 207 / PR #31 / Issue #30 / merge `23baddf413e1cdf5a5e5564fe4a559954572e45f` is latest merged safe point and Step 208 is active unmerged documentation/contract work.

## Required Verification

- `python -m pytest`
- `git diff --check`
- `python -m json.tool .cse/state/project_state.json`
- Changed-file scope check
- Protected path diff for `app/models.py`, `tests/test_models.py`, `.github/workflows/pytest.yml` must be empty.
- Confirm `exports/` contains only `.gitkeep`.
- Confirm ignored ZIP status/hash/time evidence is untouched.
- Confirm raw handoff ZIP and duplicate `(1)` source remain untracked.
- Confirm final local/remote branch SHA and divergence after push.
- Confirm final worktree status.

## Forbidden Scope

Do not:

- start Step 209;
- implement `FieldObservationRecord`;
- edit production code, executable tests/fixtures, or workflow files;
- create export output;
- add persistence, repository, API, GUI, CLI, migration, audit, backup/restore, hard validation, file-writing behavior, generated `blocked`, task creation, NCR conversion, or automatic official decision behavior;
- mutate ZIP, Desktop archive, ignored handoff package, or local mirror files.

## Commit and Push Permission

- Commit: allowed
- Push: allowed
- Pull request: not allowed by Codex
- Merge: not allowed

## Post-Merge Sync Boundary

After merge, local `master` must be fast-forwarded from `origin/master` before any next local step begins. The sync may be batched into the next Codex-required run when safe.

## Required Result Files

- `.cse/results/208_result.md`
- `.cse/state/project_state.json`

## Completion Criteria

- Contract is clear, reviewable, and documentation-only.
- Repository truth reflects Step 207 as merged and Step 208 as active/unmerged.
- Required checks pass.
- Required files physically exist in the official local working tree.
- No unauthorized files change.
- Branch is committed, pushed, and ready for ChatGPT review.
