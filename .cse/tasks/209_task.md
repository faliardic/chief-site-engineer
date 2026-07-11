# Step 209 Task

## Objective

Implement the reviewed Step 208 contract as the smallest production-code slice of the first Field MVP: a minimal `FieldObservationRecord` dataclass with focused value/default tests.

## Repository Context

- Repository: `faliardic/chief-site-engineer`
- Base branch: `master`
- Expected base commit: `335fb83c989f3fbf1057d88ebe02045174efcdc9`
- Latest merged safe point: Step 208 / PR #33 / Issue #32
- Working branch: `step-209-field-observation-record-model`
- Official local working directory: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`

## Required Sources Read

Codex must read these sources in order before editing:

1. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
2. `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
3. GitHub Issue #34
4. `.cse/tasks/209_task.md`

Also inspect before editing:

- `docs/208_first_field_mvp_observation_record_contract.md`
- `app/models.py`
- `tests/test_models.py`
- nearby simple dataclass and test patterns, especially `TrackingRecord`, `SiteNoteRecord`, `SiteLocationRecord`, and `ContactPersonRecord`

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

- Local `master` SHA: `335fb83c989f3fbf1057d88ebe02045174efcdc9`
- `origin/master` SHA: `335fb83c989f3fbf1057d88ebe02045174efcdc9`
- Master divergence: `0 0`

## Local Branch Requirement

- Create `step-209-field-observation-record-model` locally after synchronized `master`.
- Commit and ordinary push are allowed.
- Do not force push, create a PR, merge, or delete the branch.

## Reasoning Level

- Codex: High
- ChatGPT review: High

## Authorized Changes

Create:

- `.cse/tasks/209_task.md`
- `.cse/results/209_result.md`
- `docs/209_field_observation_record_model_implementation.md`
- `learning/209_field_observation_record_model_implementation.md`

Update:

- `app/models.py`
- `tests/test_models.py`
- `.cse/state/project_state.json`
- `README.md`
- `ROADMAP.md`
- `CHANGELOG.md`
- `docs/project_decisions.md`
- `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`

No other project file is authorized.

## Required Implementation

Add this minimal dataclass to `app/models.py` using the existing model style:

```python
@dataclass
class FieldObservationRecord:
    """Represents a fast official field observation for the first Field MVP."""

    observation_id: str
    project_id: str
    observed_at: str
    location: str
    category: str
    description: str
    status: str = "open"
    reported_to: str | None = None
    reported_at: str | None = None
    created_by: str | None = None
    closed_at: str | None = None
    notes: str | None = None
    is_archived: bool = False
```

Placement should be coherent with nearby field record models. Do not reorganize unrelated code.

## Required Tests

Update `tests/test_models.py` to import `FieldObservationRecord` and add focused tests proving:

1. Minimal construction stores all required values and applies every default.
2. All optional/lifecycle fields can be supplied and are held unchanged.
3. The documented lifecycle values `open`, `tracking`, and `closed` are held without side effects or validation behavior.

Tests must not introduce rejection or validation expectations.

## Behavioral Boundaries

- The six capture fields remain required by the Python constructor because they have no defaults.
- `status` defaults to `open`.
- Optional context/lifecycle fields default to `None`.
- `is_archived` defaults to `False`.
- The dataclass stores supplied `open`, `tracking`, and `closed` values unchanged.
- Do not add `__post_init__`, enum, constants, hard validation, whitespace validation, date parsing, project lookup, contact lookup, or automatic normalization.
- Do not create attachments inside the record.
- Do not generate audit events, tasks, NCR conversions, decisions, or `blocked` state.
- Do not alter existing models or their behavior.

## Repository Truth Updates

Update repository truth so:

- Step 208 / PR #33 / Issue #32 / merge `335fb83c989f3fbf1057d88ebe02045174efcdc9` is the latest merged safe point.
- Step 209 is active unmerged model/test work.
- `FieldObservationRecord` implementation has started only in this narrow dataclass/test scope.
- Attachment linking, repository/persistence, export, reporting, API/GUI/CLI, audit and validation remain unimplemented.
- Podcast 031 remains latest; the next podcast range remains Steps 206-210.

## Required Verification

- Full `python -m pytest`; test count must increase above the current `413 passed` baseline.
- Focused FieldObservationRecord tests.
- `git diff --check`
- `python -m json.tool .cse/state/project_state.json`
- Changed-file scope check.
- Review exact `app/models.py` and `tests/test_models.py` diff.
- `.github/workflows/pytest.yml` diff must be empty.
- Confirm `exports/` contains only `.gitkeep`.
- Confirm ignored ZIP status/hash/time evidence is untouched.
- Confirm raw handoff ZIP and duplicate `(1)` source remain untracked.
- Confirm final local/remote branch SHA and divergence after push.
- Confirm final worktree status.

## Forbidden Scope

Do not:

- start Step 210;
- add repository/persistence;
- add attachment service, embedded attachment fields, or automatic attachment creation;
- add structured location/contact relationships;
- add export/report generation;
- add API/GUI/CLI;
- add audit, backup/restore, migration, hard validation, generated `blocked`, workflow changes, Actions enablement, ZIP mutation, Desktop archive mutation, or any additional Field-MVP model.

## Commit and Push Permission

- Commit: allowed
- Push: allowed
- Pull request: not allowed by Codex
- Merge: not allowed

## Post-Merge Sync Boundary

After merge, local `master` must be fast-forwarded from `origin/master` before any next local step begins. The sync may be batched into the next Codex-required run when safe.

## Required Result Files

- `.cse/results/209_result.md`
- `.cse/state/project_state.json`

## Completion Criteria

- Minimal dataclass exists and follows existing model style.
- Focused tests pass and prove value/default behavior only.
- Repository truth reflects Step 208 as merged and Step 209 as active/unmerged.
- Required checks pass.
- Required files physically exist in the official local working tree.
- No unauthorized files change.
- Branch is committed, pushed, and ready for ChatGPT review.
