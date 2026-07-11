# Step 215 Task

## Source

- GitHub Issue: `#46`
- Title: `Step 215: Add FieldObservationRepository location and category filters`
- Repository: `faliardic/chief-site-engineer`
- Official local repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Base branch: `master`
- Required base / merge commit: `768178a85844aae10c46008e28eafa23822fd631`
- Latest merged safe point: Step 214 / PR #45 / Issue #44
- Required branch: `step-215-field-observation-location-category-filters`
- Current test baseline: `438 passed`
- Codex reasoning: `High`
- ChatGPT review: `High`

## Execution Decision

Issue #46 comment says: `Codex çalışmalı`.

Reason: Step 215 requires post-merge synchronization of the official `V:` repository, local production repository/test edits, full verification, commit, ordinary push, and completion evidence on Issue #46.

## Required Pre-Read

Read in order before edits:

1. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
2. `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
3. GitHub Issue #46
4. `.cse/tasks/215_task.md`

Also inspect before editing:

- `docs/208_first_field_mvp_observation_record_contract.md`
- `docs/209_field_observation_record_model_implementation.md`
- `docs/210_field_observation_repository_baseline.md`
- `docs/212_field_observation_repository_project_status_filters.md`
- `docs/213_field_observation_repository_status_update.md`
- `docs/214_field_observation_repository_reporting_update.md`
- `app/models.py`
- `app/records.py`
- `tests/test_records.py`

Stop before edits if a required tracked source is missing or an unresolved permanent-rule conflict is found.

## Post-Merge Synchronization

Before branch creation:

```text
master = origin/master = 768178a85844aae10c46008e28eafa23822fd631
divergence = 0 0
```

Verify `C:\Users\Fatih\Documents\chieh-site-engineer` remains absent.

Do not touch `C:\Users\Fatih\Desktop\fatih\chief-site-engineer`.

## Implementation

Update `FieldObservationRepository` in `app/records.py` with exactly these methods:

```python
def list_by_location(self, location: str) -> list[FieldObservationRecord]:
    ...

def list_by_category(self, category: str) -> list[FieldObservationRecord]:
    ...
```

Required behavior:

- Filter the existing in-memory `_records` collection only.
- Use exact string equality.
- Matching is case-sensitive.
- Do not trim, normalize, parse, map, tokenize, or validate supplied values.
- Preserve insertion order.
- Return `[]` for empty repositories, unknown values, and non-matches.
- Return a new list on every call.
- Return the same stored record objects by reference; do not copy or mutate records.
- Archived matching observations remain visible because archive/active filtering is outside this step.
- Location and category filters remain independent from each other and from existing project/status filters.
- Do not introduce a combined query/filter object.

## Focused Tests

Update `tests/test_records.py` with focused tests proving:

1. `list_by_location(...)` returns exact matches in insertion order and rejects unknown, case-different, and whitespace-different values.
2. `list_by_category(...)` returns exact matches in insertion order and rejects unknown, case-different, and whitespace-different values.
3. Location, category, project, and status filters remain independent.
4. Returned filtered lists are new lists and external list mutation does not alter repository contents.
5. Archived matching records remain returned by location and category filters.
6. Empty repository calls return `[]`.
7. No record is copied, mutated, added, removed, archived, or status-changed by filtering.

Use the existing `_field_observation(...)` helper, extending it minimally only if required for location/category values. Do not add unrelated tests.

## Explicit Non-Scope

Do not add:

- structured `SiteLocationRecord` lookup or relationship resolution;
- category constants, enums, canonical vocabulary, normalization, validation, or `__post_init__` behavior;
- partial/fuzzy/contains/prefix/regex/text search;
- `reported_to`, date/time, creator, active/archive-only, notes, or description filters;
- combined query builders, filter objects, pagination, sorting, grouping, counts, or summaries;
- updates for location/category or any other field;
- close/reopen rules, automatic lifecycle behavior, timestamps, audit/history/task/NCR/notification/decision generation;
- persistence/database/JSON/SQLite;
- attachment linking/upload/file operations;
- daily export or weekly summary;
- API/GUI/CLI;
- generated `blocked`;
- Podcast 033 or Step 216 implementation.

## Step 214 Merged-Truth Update

Update repository truth so:

- Step 214 / PR #45 / Issue #44 / merge `768178a85844aae10c46008e28eafa23822fd631` is the latest merged safe point.
- Podcast 032 remains the latest completed podcast and covers Steps 206-210.
- Step 215 is active unmerged location/category filter work.
- The next natural podcast remains Podcast 033 for Steps 211-215, but it must be created only in a separate Step 216 after Step 215 merges.
- The Field MVP now has a minimal observation model, in-memory repository, project/status/location/category filters, explicit status update, and explicit reporting-context update.
- Persistence, structured location/contact normalization, attachment integration, automatic lifecycle rules, broader filters/mutations, export/reporting consumers, and interfaces remain unimplemented.

## Authorized Files

Create:

- `.cse/tasks/215_task.md`
- `.cse/results/215_result.md`
- `docs/215_field_observation_repository_location_category_filters.md`
- `learning/215_field_observation_repository_location_category_filters.md`

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

- focused tests, for example `python -m pytest tests/test_records.py -k "field_observation_repository and (location or category)"`;
- full `python -m pytest` — test count must increase above `438 passed`;
- `git diff --check`;
- `python -m json.tool .cse/state/project_state.json`;
- changed-file scope check;
- exact `app/records.py` and `tests/test_records.py` diff review;
- `app/models.py`, `tests/test_models.py`, `.github/workflows/pytest.yml`, and Podcast 032 diff — must be empty;
- verify Podcast 033 was not created;
- `exports/` check — only `.gitkeep`;
- ignored ZIP status/hash/time evidence — untouched;
- raw handoff ZIP and duplicate `(1)` source remain untracked;
- final local/remote branch SHA and divergence evidence;
- final worktree status.

## Publication And Boundaries

- Commit and ordinary push are allowed.
- Force push, PR creation by Codex, merge, and branch deletion are forbidden.
- Use one consolidated Codex execution.
- Do not start Step 216 or Podcast 033.
- Do not add persistence, structured location/category normalization, attachment integration, broader mutations, summaries, export/reporting, API/GUI/CLI, audit, backup/restore, migration, validation, generated `blocked`, workflow changes, Actions enablement, ZIP mutation, or Desktop archive mutation.
