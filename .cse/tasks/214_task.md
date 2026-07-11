# Step 214 Task

## Objective

Add the next smallest explicit enrichment operation for the first Field MVP: update one stored field observation's reporting context by `observation_id`.

This step remains a narrow in-memory repository operation. It must not change status automatically, create timestamps, add contact lookup, persistence, audit behavior, or broader mutation services.

## Repository Context

- Repository: `faliardic/chief-site-engineer`
- Official local repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Base branch: `master`
- Required base / merge commit: `45c2b2e2828dfea74121033bf01a868e6821b544`
- Latest merged safe point: Step 213 / PR #43 / Issue #42
- Working branch: `step-214-field-observation-reporting-update`
- Current test baseline: `431 passed`
- Codex reasoning: High
- ChatGPT review: High

## Required Pre-Read

Before edits, read in order:

1. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
2. `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
3. GitHub Issue #44
4. `.cse/tasks/214_task.md`

Also inspect before editing:

- `docs/208_first_field_mvp_observation_record_contract.md`
- `docs/209_field_observation_record_model_implementation.md`
- `docs/210_field_observation_repository_baseline.md`
- `docs/212_field_observation_repository_project_status_filters.md`
- `docs/213_field_observation_repository_status_update.md`
- `app/models.py`
- `app/records.py`
- `tests/test_records.py`

If a required tracked source is missing or an unresolved permanent-rule conflict is found, stop before edits.

## Synchronization Evidence

Required before branch creation:

```text
master = origin/master = 45c2b2e2828dfea74121033bf01a868e6821b544
divergence = 0 0
```

Verify `C:\Users\Fatih\Documents\chieh-site-engineer` remains absent. Do not touch `C:\Users\Fatih\Desktop\fatih\chief-site-engineer`.

## Implementation

Update `FieldObservationRepository` in `app/records.py` with exactly this method:

```python
def update_reporting(
    self,
    observation_id: str,
    reported_to: str,
    reported_at: str,
) -> FieldObservationRecord | None:
    ...
```

Required behavior:

- Find the stored observation using existing `find_by_id(...)` behavior.
- Return `None` when the observation ID is missing.
- When found, assign only:
  - `record.reported_to = reported_to`
  - `record.reported_at = reported_at`
- Return that same stored record object.
- Do not trim, normalize, validate, map, parse, or convert either supplied value.
- Do not create contact/person lookup or relationship resolution.
- Do not automatically change `status` to `tracking` or any other value.
- Do not change `closed_at`, `notes`, `created_by`, `is_archived`, or any other field.
- Do not create history records, audit events, tasks, NCRs, notifications, or decisions.
- Archived observations are not blocked from explicit reporting updates because archive gating is outside this step.

## Focused Tests

Update `tests/test_records.py` with focused tests proving:

1. missing `observation_id` returns `None` and leaves repository contents unchanged;
2. an observation can be explicitly assigned `reported_to` and `reported_at`, returning the same stored record object;
3. updating reporting context changes only those two fields and preserves `status`, `closed_at`, notes, archive state, and other values;
4. only the targeted record changes when multiple observations exist;
5. exact supplied strings are preserved without trimming or normalization;
6. an archived observation can still be explicitly updated, documenting that archive gating has not yet been introduced;
7. no duplicate/new record is created and repository count remains stable.

Use the existing `_field_observation(...)` helper. Do not add unrelated tests.

## Explicit Non-Scope

Do not add:

- automatic status change to `tracking`;
- automatic/current-time generation;
- contact lookup, contact IDs, normalization, validation, constants, enums, or `__post_init__` behavior;
- updates for location, category, description, notes, creator, closed timestamp, status, or archive state;
- reporting history, audit, task, NCR, notification, or decision creation;
- delete, bulk update, archive/restore, active filtering, combined query, or summaries;
- persistence/database/JSON/SQLite;
- attachment linking/upload/file operations;
- daily export or weekly summary;
- API/GUI/CLI;
- generated `blocked`;
- Step 215 implementation.

## Step 213 Merged-Truth Update

Update repository truth so:

- Step 213 / PR #43 / Issue #42 / merge `45c2b2e2828dfea74121033bf01a868e6821b544` is the latest merged safe point.
- Podcast 032 remains the latest completed podcast and covers Steps 206-210.
- The next podcast range remains Steps 211-215.
- Step 214 is active unmerged explicit reporting-update work.
- The Field MVP now has a minimal observation model, in-memory repository, project/status filters, explicit status update, and explicit reporting-context update.
- Persistence, automatic lifecycle rules, contact normalization, attachment integration, broader filters/mutations, export/reporting consumers, and interfaces remain unimplemented.

## Authorized Files

Create:

- `.cse/tasks/214_task.md`
- `.cse/results/214_result.md`
- `docs/214_field_observation_repository_reporting_update.md`
- `learning/214_field_observation_repository_reporting_update.md`

Update:

- `app/records.py`
- `tests/test_records.py`
- `.cse/state/project_state.json`
- `README.md`
- `ROADMAP.md`
- `CHANGELOG.md`
- `docs/project_decisions.md`
- `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`

No other project file is authorized.

## Verification

Run and record:

- focused tests, for example `python -m pytest tests/test_records.py -k "field_observation_repository and reporting"`;
- full `python -m pytest` with test count above `431 passed`;
- `git diff --check`;
- `python -m json.tool .cse/state/project_state.json`;
- changed-file scope check;
- exact `app/records.py` and `tests/test_records.py` diff review;
- `app/models.py`, `tests/test_models.py`, `.github/workflows/pytest.yml`, and Podcast 032 diff must be empty;
- `exports/` check, only `.gitkeep`;
- ignored ZIP status/hash/time evidence, untouched;
- raw handoff ZIP and duplicate `(1)` source remain untracked;
- final local/remote branch SHA and divergence evidence;
- final worktree status.

## Publication and Boundaries

Commit and ordinary push are allowed.

Force push, PR creation by Codex, merge, and branch deletion are forbidden.

Use one consolidated Codex execution. Do not start Step 215.
