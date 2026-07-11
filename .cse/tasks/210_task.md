# Step 210 Task

## Objective

Add the smallest in-memory repository foundation for the merged `FieldObservationRecord` model so the first Field MVP can store, list, count, and retrieve observation records without introducing persistence or broader workflow behavior.

## Repository Context

- Repository: `faliardic/chief-site-engineer`
- Base branch: `master`
- Expected base commit: `f1fd7b8e6add21369b3d5f4c44d014994538fc1c`
- Latest merged safe point: Step 209 / PR #35 / Issue #34
- Working branch: `step-210-field-observation-repository-baseline`
- Official local working directory: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`

## Required Sources Read

Codex must read these sources in order before editing:

1. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
2. `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
3. GitHub Issue #36
4. `.cse/tasks/210_task.md`

Also inspect before editing:

- `docs/208_first_field_mvp_observation_record_contract.md`
- `docs/209_field_observation_record_model_implementation.md`
- `app/models.py`
- `app/records.py`
- `tests/test_records.py`
- current `NonconformityRepository` add/list/count/find/duplicate patterns

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

- Local `master` SHA: `f1fd7b8e6add21369b3d5f4c44d014994538fc1c`
- `origin/master` SHA: `f1fd7b8e6add21369b3d5f4c44d014994538fc1c`
- Master divergence: `0 0`

## Local Branch Requirement

- Create `step-210-field-observation-repository-baseline` locally after synchronized `master`.
- Commit and ordinary push are allowed.
- Do not force push, create a PR, merge, or delete the branch.

## Reasoning Level

- Codex: High
- ChatGPT review: High

## Authorized Changes

Create:

- `.cse/tasks/210_task.md`
- `.cse/results/210_result.md`
- `docs/210_field_observation_repository_baseline.md`
- `learning/210_field_observation_repository_baseline.md`

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

## Required Implementation

Update `app/records.py` to import `FieldObservationRecord` and add:

```python
class FieldObservationRepository:
    """Stores field observation records in memory."""

    def __init__(self) -> None:
        self._records: list[FieldObservationRecord] = []

    def add(self, record: FieldObservationRecord) -> None:
        ...

    def list_all(self) -> list[FieldObservationRecord]:
        ...

    def count(self) -> int:
        ...

    def find_by_id(self, observation_id: str) -> FieldObservationRecord | None:
        ...
```

Required behavior:

- `add(...)` appends a new record.
- Duplicate `observation_id` is rejected with `ValueError`.
- A different observation ID remains accepted after a duplicate attempt.
- `list_all()` returns a copy of the internal list, matching the existing repository safety style.
- `count()` returns the current number of stored records.
- `find_by_id(...)` returns the matching record or `None`.
- Record objects themselves are not copied or mutated.

## Required Tests

Update `tests/test_records.py` to import `FieldObservationRecord` and `FieldObservationRepository` and add focused tests proving:

1. a new repository is empty, count is zero, and missing lookup returns `None`;
2. records can be added, listed in insertion order, counted, and found by ID;
3. duplicate `observation_id` is rejected while a different ID can still be added;
4. mutating the list returned by `list_all()` does not mutate the repository internal collection.

Use concise local helper construction only when it improves readability.

## Repository Truth Updates

Update repository truth so:

- Step 209 / PR #35 / Issue #34 / merge `f1fd7b8e6add21369b3d5f4c44d014994538fc1c` is the latest merged safe point.
- Step 210 is active unmerged repository-baseline work.
- `FieldObservationRecord` remains the only Field-MVP model implemented.
- `FieldObservationRepository` is only in-memory and baseline-level.
- Persistence, attachment integration, filters, updates, export/reporting and interfaces remain unimplemented.
- Podcast 031 remains latest.
- Steps 206-210 become ready for Podcast 032 only after Step 210 merges; do not create Podcast 032 in this step.
- Recommended next step after merge: Step 211 - Podcast 032 for Steps 206-210.

## Required Verification

- Focused repository tests: `python -m pytest tests/test_records.py -k field_observation_repository`
- Full `python -m pytest`; test count must increase above the current `416 passed` baseline.
- `git diff --check`
- `python -m json.tool .cse/state/project_state.json`
- Changed-file scope check.
- Exact `app/records.py` and `tests/test_records.py` diff review.
- `app/models.py` and `.github/workflows/pytest.yml` diff must be empty.
- Confirm `exports/` contains only `.gitkeep`.
- Confirm ignored ZIP status/hash/time evidence is untouched.
- Confirm raw handoff ZIP and duplicate `(1)` source remain untracked.
- Confirm final local/remote branch SHA and divergence after push.
- Confirm final worktree status.

## Forbidden Scope

Do not:

- start Step 211 or create Podcast 032;
- add project/status/category/location/reported-to filters;
- add status updates, close/reopen, archive/restore, delete, or bulk operations;
- add repository summaries or reporting;
- add persistence/database/JSON/SQLite;
- add attachment linking or file operations;
- add validation or normalization inside `FieldObservationRecord`;
- add API/GUI/CLI;
- add audit events, task/NCR conversion, decisions, generated `blocked`, daily export or weekly summary.

## Commit and Push Permission

- Commit: allowed
- Push: allowed
- Pull request: not allowed by Codex
- Merge: not allowed

## Post-Merge Sync Boundary

After merge, local `master` must be fast-forwarded from `origin/master` before any next local step begins. The sync may be batched into the next Codex-required run when safe.

## Required Result Files

- `.cse/results/210_result.md`
- `.cse/state/project_state.json`

## Completion Criteria

- `FieldObservationRepository` exists and follows existing in-memory repository safety style.
- Focused tests pass and prove only baseline add/list/count/find/duplicate/list-copy behavior.
- Repository truth reflects Step 209 as merged and Step 210 as active/unmerged.
- Required checks pass.
- Required files physically exist in the official local working tree.
- No unauthorized files change.
- Branch is committed, pushed, and ready for ChatGPT review.
