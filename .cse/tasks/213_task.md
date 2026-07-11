# Step 213 Task

## Objective

Add the smallest explicit lifecycle mutation required by the first Field MVP: update one stored field observation's `status` by `observation_id`.

This step remains a narrow in-memory repository operation. It must not add automatic transitions, validation, timestamps, persistence, audit behavior, or broader mutation services.

## Repository Context

- Repository: `faliardic/chief-site-engineer`
- Official local repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Base branch: `master`
- Required base / merge commit: `e5842131882034eaf0cf5c8ec198f17c0f063dbe`
- Latest merged safe point: Step 212 / PR #41 / Issue #40
- Working branch: `step-213-field-observation-status-update`
- Current test baseline: `425 passed`
- Codex reasoning: High
- ChatGPT review: High

## Required Pre-Read

Before edits, read in order:

1. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
2. `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
3. GitHub Issue #42
4. `.cse/tasks/213_task.md`

Also inspect before editing:

- `docs/208_first_field_mvp_observation_record_contract.md`
- `docs/209_field_observation_record_model_implementation.md`
- `docs/210_field_observation_repository_baseline.md`
- `docs/212_field_observation_repository_project_status_filters.md`
- `app/models.py`
- `app/records.py`
- `tests/test_records.py`
- existing `NonconformityRepository.update_status(...)` pattern

If a required tracked source is missing or an unresolved permanent-rule conflict is found, stop before edits.

## Synchronization Evidence

Required before branch creation:

```text
master = origin/master = e5842131882034eaf0cf5c8ec198f17c0f063dbe
divergence = 0 0
```

Verify `C:\Users\Fatih\Documents\chieh-site-engineer` remains absent. Do not touch `C:\Users\Fatih\Desktop\fatih\chief-site-engineer`.

## Implementation

Update `FieldObservationRepository` in `app/records.py` with exactly this method:

```python
def update_status(
    self,
    observation_id: str,
    new_status: str,
) -> FieldObservationRecord | None:
    ...
```

Required behavior:

- Find the stored observation using existing `find_by_id(...)` behavior.
- Return `None` when the observation ID is missing.
- When found, assign `record.status = new_status` and return that same stored record object.
- The normal tested lifecycle examples are `open -> tracking -> closed`.
- Do not trim, normalize, validate, map, or convert `new_status`.
- Do not create status constants or enums.
- Do not automatically set or clear `closed_at`, `reported_at`, `notes`, `is_archived`, or any other field.
- Do not create history records, audit events, tasks, NCRs, notifications, or decisions.
- Existing project/status filters must immediately reflect the current stored status because they read the same record objects.
- Archived observations are not blocked from explicit status updates because archive mutation/access policy is outside this step.

## Focused Tests

Update `tests/test_records.py` with focused tests proving:

1. missing `observation_id` returns `None` and leaves repository contents unchanged;
2. an `open` observation can be explicitly updated to `tracking`, returning the same record object;
3. a `tracking` observation can be explicitly updated to `closed` without automatically changing `closed_at` or other fields;
4. only the targeted record changes when multiple observations exist;
5. `list_by_status(...)` immediately reflects the updated status and no duplicate/new record is created;
6. an archived observation can still be explicitly updated, documenting that archive gating has not yet been introduced.

Use the existing `_field_observation(...)` helper. Do not add unrelated tests.

## Explicit Non-Scope

Do not add:

- `close(...)`, `reopen(...)`, transition-rule, allowed-transition, or workflow-engine helpers;
- automatic `closed_at`, `reported_at`, audit, history, task, NCR, notification, or decision creation;
- status validation, constants, enums, normalization, or `__post_init__` behavior;
- updates for location, category, description, `reported_to`, notes, archive state, or any other field;
- delete, bulk update, archive/restore, active filtering, combined query, or summaries;
- persistence/database/JSON/SQLite;
- attachment linking/upload/file operations;
- daily export or weekly summary;
- API/GUI/CLI;
- generated `blocked`;
- Step 214 implementation.

## Step 212 Merged-Truth Update

Update repository truth so:

- Step 212 / PR #41 / Issue #40 / merge `e5842131882034eaf0cf5c8ec198f17c0f063dbe` is the latest merged safe point.
- Podcast 032 remains the latest completed podcast and covers Steps 206-210.
- The next podcast range remains Steps 211-215.
- Step 213 is active unmerged explicit status-update work.
- The Field MVP now has a minimal observation model, in-memory repository, read-only project/status filters, and one explicit status mutation operation.
- Persistence, automatic lifecycle rules, attachment integration, broader filters, export/reporting, and interfaces remain unimplemented.

## Authorized Files

Create:

- `.cse/tasks/213_task.md`
- `.cse/results/213_result.md`
- `docs/213_field_observation_repository_status_update.md`
- `learning/213_field_observation_repository_status_update.md`

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

- focused tests, for example `python -m pytest tests/test_records.py -k "field_observation_repository and status"`;
- full `python -m pytest` with test count above `425 passed`;
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

Use one consolidated Codex execution. Do not start Step 214.
