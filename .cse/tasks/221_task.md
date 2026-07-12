# Step 221 Task - Podcast 034 for Steps 216-220

GitHub Issue: #59

## Purpose

Create Podcast 034 as the Turkish NotebookLM source note for Steps 216-220.

This is a documentation/state/podcast-only step. It must not change production
behavior, executable tests, repository methods, model behavior, workflows, or
protected files.

## Base

- Repository: `faliardic/chief-site-engineer`
- Official local repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Base branch: `master`
- Required base / merge commit: `1623e32437e1555ab398b245c4984566c163825f`
- Latest merged safe point: Step 220 / PR #58 / Issue #57
- Required branch: `step-221-podcast-034-steps-216-220`
- Current test baseline: `471 passed`
- Latest completed podcast before this branch: Podcast 033 / Steps 211-215
- Current podcast range: Steps 216-220

## Required Scope

Create:

- `.cse/tasks/221_task.md`
- `.cse/results/221_result.md`
- `docs/podcast_notes/034_adim_216_220_notebooklm_podcast_notu.md`

Update only as needed:

- `.cse/state/project_state.json`
- `README.md`
- `ROADMAP.md`
- `CHANGELOG.md`
- `docs/project_decisions.md`
- `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`

No production code, executable test, workflow, Podcast 033, Podcast 035, Step
222 implementation, ignored ZIP, Desktop archive, or exports output is
authorized.

## Podcast Scope

Podcast 034 covers only Steps 216-220:

1. Step 216: Podcast 033 for Steps 211-215 and transition into the attachment
   repository range.
2. Step 217: Minimal in-memory `FileAttachmentRepository` baseline.
3. Step 218: Independent `related_record_type` and `related_record_id` filters.
4. Step 219: Exact Field Observation attachment linking contract.
5. Step 220: Combined `list_by_related_record(...)` filter requiring type and
   id to match on the same attachment record.

Required narrative:

```text
observation repository maturity
-> attachment metadata repository
-> independent relationship lookups
-> explicit observation-link contract
-> exact combined relationship lookup
```

## Required Podcast Content

The podcast note must clearly explain:

- the main theme of the period;
- chronological Step 216-220 narrative;
- `FieldObservationRecord` and `FileAttachmentRecord` relationship meaning;
- why attachment-owned metadata remains the relationship source;
- exact and case-sensitive matching behavior;
- zero-to-many attachment relationship;
- why the combined filter rejects partial matches;
- test progression and final `471 passed` evidence;
- real construction-site value: finding evidence attached to a specific
  observation;
- current boundaries and intentionally deferred work;
- next development direction after Step 221.

It must state that CSE is still an in-memory, test-backed metadata core and is
not yet a field-ready or production-ready application.

## Verification Required

Run:

```powershell
python -m pytest
python -m json.tool .cse\state\project_state.json
git diff --check
git diff -- app/models.py app/records.py tests/test_models.py tests/test_records.py app/attachment_integrity.py tests/test_attachment_integrity.py .github/workflows/pytest.yml docs/podcast_notes/033_adim_211_215_notebooklm_podcast_notu.md
Get-ChildItem exports -Force
```

Expected:

- full tests remain `471 passed`;
- production code and executable tests have no diff;
- protected paths have no diff;
- `exports/` contains only `.gitkeep`;
- ignored ZIP remains untouched;
- Podcast 035 does not exist;
- changed files remain within Issue #59 scope.

## Publication

Commit and ordinary push are authorized.

Forbidden:

- force push;
- PR creation;
- merge;
- branch deletion;
- reset/clean/stash/delete/move/rename/overwrite operations outside the
  requested scope.

Suggested commit message:

```text
Add podcast 034 for steps 216 to 220
```
