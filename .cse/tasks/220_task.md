# Step 220 Task - FileAttachmentRepository Combined Related-Record Filter

GitHub Issue: #57

## Purpose

Implement the exact combined relationship query documented in Step 219.

This step adds only `FileAttachmentRepository.list_by_related_record(...)`.
The method must require `related_record_type` and `related_record_id` to match
on the same stored `FileAttachmentRecord`.

## Base

- Repository: `faliardic/chief-site-engineer`
- Official local repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Base branch: `master`
- Required base / merge commit: `4d006a2f49f10792a74dca068ea415ba37200797`
- Latest merged safe point: Step 219 / PR #56 / Issue #54
- Required branch: `step-220-file-attachment-combined-related-record-filter`
- Current test baseline: `461 passed`
- Latest completed podcast: Podcast 033 / Steps 211-215
- Current podcast range: Steps 216-220
- Codex reasoning: Extra High
- ChatGPT review: Extra High

## Required Scope

Create:

- `.cse/tasks/220_task.md`
- `.cse/results/220_result.md`
- `docs/220_file_attachment_repository_combined_related_record_filter.md`
- `learning/220_file_attachment_repository_combined_related_record_filter.md`

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

## Implementation

Add this method to `FileAttachmentRepository`:

```python
def list_by_related_record(
    self,
    related_record_type: str,
    related_record_id: str,
) -> list[FileAttachmentRecord]:
    ...
```

Required behavior:

- filter only existing in-memory `_records`;
- a record matches only when both fields match on the same record;
- use exact string equality;
- matching is case-sensitive;
- no trim, normalize, parse, map, alias, prefix inference, or validation;
- preserve insertion order;
- return `[]` for empty repositories, unknown pairs, and partial matches;
- return a new list on every call;
- return same stored record objects by reference;
- do not copy or mutate metadata;
- do not verify that the referenced related record exists;
- keep existing independent type and ID filters unchanged.

## Focused Tests

Add focused tests in `tests/test_records.py` using existing `_file_attachment(...)`
helper for:

1. exact type+ID pair matches return in insertion order;
2. same ID under a different type is excluded;
3. same type with a different ID is excluded;
4. case-different and whitespace-different type or ID values do not match;
5. empty repository and unknown pair return `[]`;
6. each call returns a new list and external list mutation does not alter repository contents;
7. returned items are the same stored objects and metadata remains unchanged;
8. filtering preserves repository count and `list_all()` order;
9. missing related-record existence is not validated;
10. existing independent filters, baseline repository methods,
    `FieldObservationRepository`, and `NonconformityRepository` remain unchanged.

Focused test selector should match:

```text
file_attachment_repository and combined_related_record
```

## Explicit Non-Scope

Do not add:

- `list_for_field_observation(...)` or any record-type-specific convenience method;
- lookup into `FieldObservationRepository`, `NonconformityRepository`, or another repository;
- automatic attachment creation, relationship validation, repair, deletion,
  relinking, warning, task, NCR, audit, or blocking;
- physical file upload/download/copy/move/rename/delete/preview/thumbnail/compression/ZIP behavior;
- filesystem existence/readability/integrity checks;
- path generation, normalization, allowed-root enforcement, or file writing;
- persistence/database/JSON/SQLite;
- status/archive/lifecycle behavior;
- new model fields, validation, enums, constants, migration, hard validation, or generated `blocked`;
- API/GUI/CLI;
- Podcast 034 or Step 221 implementation.

## Verification Required

- Focused tests:
  `python -m pytest tests/test_records.py -k "file_attachment_repository and combined_related_record"`.
- Full `python -m pytest`; test count must increase above `461 passed`.
- `git diff --check`.
- `python -m json.tool .cse/state/project_state.json`.
- Changed-file scope check.
- Exact `app/records.py` and `tests/test_records.py` diff review.
- Verify protected path diffs are empty.
- Verify `list_for_field_observation` is not implemented in `app/`.
- Verify Podcast 034 was not created.
- Verify `exports/` contains only `.gitkeep`.
- Verify ignored ZIP hash/time evidence remains untouched.
- Verify raw handoff ZIP and duplicate `(1)` source remain untracked.
- Record final local/remote branch SHA, divergence, and worktree status.

## Publication

Commit and ordinary push are allowed. Force push, PR creation by Codex, merge,
and branch deletion are forbidden.
