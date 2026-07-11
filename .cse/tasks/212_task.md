# Step 212 Task

## Objective

Extend the merged in-memory `FieldObservationRepository` with the smallest read-only visibility layer needed for the first Field MVP: exact project and status filtering.

This step must not change observation lifecycle state, add persistence, or expand into attachment/reporting behavior.

## Repository Context

- Repository: `faliardic/chief-site-engineer`
- Official local repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Base branch: `master`
- Required base / merge commit: `26509f35abb0cb706d2a085715310358cf5d2421`
- Latest merged safe point: Step 211 / PR #39 / Issue #38
- Working branch: `step-212-field-observation-project-status-filters`
- Codex reasoning: High
- ChatGPT review: High

## Required Pre-Read

Before edits, read in order:

1. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
2. `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
3. GitHub Issue #40
4. `.cse/tasks/212_task.md`

Also inspect before editing:

- `docs/208_first_field_mvp_observation_record_contract.md`
- `docs/209_field_observation_record_model_implementation.md`
- `docs/210_field_observation_repository_baseline.md`
- `docs/podcast_notes/032_adim_206_210_notebooklm_podcast_notu.md`
- `app/models.py`
- `app/records.py`
- `tests/test_records.py`
- existing `NonconformityRepository.list_by_status(...)` and generic project/status filter patterns

If a required tracked source is missing or an unresolved permanent-rule conflict is found, stop before edits.

## Synchronization Evidence

Required before branch creation:

```text
master = origin/master = 26509f35abb0cb706d2a085715310358cf5d2421
divergence = 0 0
```

Verify `C:\Users\Fatih\Documents\chieh-site-engineer` remains absent. Do not touch `C:\Users\Fatih\Desktop\fatih\chief-site-engineer`.

## Implementation

Update `FieldObservationRepository` in `app/records.py` with exactly these read-only methods:

```python
def list_by_project_id(self, project_id: str) -> list[FieldObservationRecord]:
    ...

def list_by_status(self, status: str) -> list[FieldObservationRecord]:
    ...
```

Required behavior:

- `list_by_project_id(...)` returns records whose `project_id` exactly matches the supplied value.
- `list_by_status(...)` returns records whose `status` exactly matches the supplied value.
- Matching is case-sensitive and performs no trimming, normalization, validation, enum conversion, or fallback mapping.
- Results preserve repository insertion order.
- Unknown values and an empty repository return `[]`.
- Every call returns a new collection; clearing or appending to the returned list must not mutate the repository.
- Stored record objects are returned by reference and are not copied or mutated.
- Archived records remain eligible when their project/status matches because active/archive filtering is not part of this step.

## Focused Tests

Update `tests/test_records.py` with focused tests proving:

1. project filtering returns only exact matches in insertion order and returns `[]` for unknown project IDs;
2. status filtering handles the documented `open`, `tracking`, and `closed` values and returns `[]` for unknown values;
3. project and status filtering remain independent with no implicit combined filtering;
4. mutating a returned filtered list does not mutate repository storage;
5. an archived matching observation is still returned.

Use the existing `_field_observation(...)` helper if suitable; extend it minimally with optional keyword parameters rather than duplicating large fixtures. Do not add unrelated tests.

## Explicit Non-Scope

Do not add:

- category, location, `reported_to`, date/time, text-search, archive, active, or combined-query methods;
- status update, close/reopen, archive/restore, delete, bulk operations, or mutation services;
- summaries/count-by-status/reporting;
- persistence/database/JSON/SQLite;
- attachment linking/upload/file operations;
- model validation, normalization, enums, constants, or `__post_init__`;
- API/GUI/CLI;
- audit events, task/NCR conversion, official decisions, or generated `blocked`;
- daily export or weekly summary;
- Step 213 implementation.

## Step 211 Merged-Truth Update

Update repository truth so:

- Step 211 / PR #39 / Issue #38 / merge `26509f35abb0cb706d2a085715310358cf5d2421` is the latest merged safe point.
- Podcast 032 is the latest completed podcast and covers Steps 206-210.
- The next podcast range is Steps 211-215.
- Step 212 is active unmerged project/status filter work.
- The Field MVP now has a minimal observation model, in-memory repository baseline, and read-only project/status visibility only.
- Persistence, lifecycle mutation, attachment integration, broader filters, export/reporting, and interfaces remain unimplemented.
- Current test baseline before this step is `420 passed`.

## Authorized Files

Create:

- `.cse/tasks/212_task.md`
- `.cse/results/212_result.md`
- `docs/212_field_observation_repository_project_status_filters.md`
- `learning/212_field_observation_repository_project_status_filters.md`

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

- focused tests, for example `python -m pytest tests/test_records.py -k "field_observation_repository and (project or status or filtered or archived)"`;
- full `python -m pytest` - test count must increase above the current `420 passed` baseline;
- `git diff --check`;
- `python -m json.tool .cse/state/project_state.json`;
- changed-file scope check;
- exact `app/records.py` and `tests/test_records.py` diff review;
- `app/models.py`, `tests/test_models.py`, `.github/workflows/pytest.yml`, and Podcast 032 diff - must be empty;
- `exports/` check - only `.gitkeep`;
- ignored ZIP status/hash/time evidence - untouched;
- raw handoff ZIP and duplicate `(1)` source remain untracked;
- final local/remote branch SHA and divergence evidence;
- final worktree status.

## Publication And Boundaries

Commit and ordinary push are allowed. Force push, PR creation by Codex, merge, and branch deletion are forbidden.

Use one consolidated Codex execution. Do not start Step 213.

Do not add persistence, lifecycle mutation, attachment integration, broader filters, summaries, export/reporting, API/GUI/CLI, audit, backup/restore, migration, validation, generated `blocked`, workflow changes, Actions enablement, ZIP mutation, or Desktop archive mutation.
