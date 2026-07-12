# Step 218 Task

## GitHub Source

- Issue: `#52`
- Title: `Step 218: Add FileAttachmentRepository related-record filters`
- Repository: `faliardic/chief-site-engineer`
- Official local repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Required base branch: `master`
- Required base / merge commit: `075acdbc77927925092b748b77aad7c0ce13d9ef`
- Latest merged safe point: Step 217 / PR #51 / Issue #50
- Required branch: `step-218-file-attachment-related-record-filters`
- Current test baseline: `453 passed`
- Latest completed podcast: Podcast 033 / Steps 211-215
- Next podcast range: Steps 216-220

## Required Pre-Read

Read before implementation:

1. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
2. `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
3. GitHub Issue #52 and its execution decision comment
4. `.cse/tasks/218_task.md`

Also inspect:

- `app/models.py`, especially `FileAttachmentRecord`
- `app/records.py`
- `tests/test_records.py`
- `docs/217_file_attachment_repository_baseline.md`
- `learning/217_file_attachment_repository_baseline.md`
- `docs/068_dosya_eki_kaydi_modeli.md`
- `docs/080_file_attachment_metadata_butunluk_ozeti.md`
- `docs/089_attachment_metadata_integrity_kurallari.md`
- `docs/podcast_notes/033_adim_211_215_notebooklm_podcast_notu.md`

Stop before edits if a required tracked source is missing or an unresolved permanent-rule conflict is found.

## Goal

Extend `FileAttachmentRepository` with two narrow read-only filters for existing attachment metadata:

```python
def list_by_related_record_type(
    self,
    related_record_type: str,
) -> list[FileAttachmentRecord]:
    ...

def list_by_related_record_id(
    self,
    related_record_id: str,
) -> list[FileAttachmentRecord]:
    ...
```

This is a metadata visibility extension only. It must not add combined filtering, Field Observation-specific convenience lookup, automatic linking, file behavior, persistence, validation, or lifecycle rules.

## Required Behavior

- Filter only the existing in-memory `_records` collection.
- Use exact string equality.
- Matching is case-sensitive.
- Do not trim, normalize, map, parse, validate, or resolve relationships.
- Preserve insertion order.
- Return `[]` for empty repositories, unknown values, and non-matches.
- Return a new list on every call.
- Return the same stored record objects by reference.
- Do not copy or mutate metadata records.
- The type and ID filters must remain independent from each other.
- Do not infer or verify that a related record actually exists.
- Do not add a combined type+ID filter.

## Focused Tests

Update `tests/test_records.py` using the existing `_file_attachment(...)` helper.

Tests must prove:

1. `list_by_related_record_type(...)` returns exact matches in insertion order and rejects unknown, case-different, and whitespace-different values.
2. `list_by_related_record_id(...)` returns exact matches in insertion order and rejects unknown, case-different, and whitespace-different values.
3. Type and ID filters remain independent when records share one field but differ in the other.
4. Empty repository calls return `[]`.
5. Returned lists are new lists and external list mutation does not alter repository contents.
6. Returned items are the same stored objects and attachment metadata remains unchanged.
7. Filtering does not add, remove, or reorder records and repository count remains stable.
8. Existing `FileAttachmentRepository`, `FieldObservationRepository`, and `NonconformityRepository` behaviors remain unchanged.

Do not duplicate model-validation tests already owned by `tests/test_models.py`.

## Documentation And State

Create:

- `.cse/results/218_result.md`
- `docs/218_file_attachment_repository_related_record_filters.md`
- `learning/218_file_attachment_repository_related_record_filters.md`

Update:

- `app/records.py`
- `tests/test_records.py`
- `.cse/state/project_state.json`
- `README.md`
- `ROADMAP.md`
- `CHANGELOG.md`
- `docs/project_decisions.md`
- `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`

Record that Step 217 / PR #51 / Issue #50 / merge `075acdbc77927925092b748b77aad7c0ce13d9ef` is the latest merged safe point, Podcast 033 remains latest completed, next podcast range remains Steps 216-220, and Step 218 is active unmerged related-record filter work.

## Explicit Non-Scope

Do not add combined related-record filtering, record-type-specific convenience methods, lookup into other repositories, automatic attachment creation, relationship validation, physical file operations, filesystem checks, path generation/normalization, persistence, lifecycle behavior, validation/enums/constants, API/GUI/CLI, audit/history/task/NCR/notification/decision generation, Step 219, or Podcast 034.

## Verification

Run and record:

- focused tests such as `python -m pytest tests/test_records.py -k "file_attachment_repository and related_record"`;
- full `python -m pytest`, with test count above `453 passed`;
- `git diff --check`;
- `python -m json.tool .cse/state/project_state.json`;
- changed-file scope check;
- exact `app/records.py` and `tests/test_records.py` diff review;
- empty diffs for `app/models.py`, `tests/test_models.py`, `app/attachment_integrity.py`, `tests/test_attachment_integrity.py`, `.github/workflows/pytest.yml`, and Podcast 033;
- Podcast 034 absence;
- `exports/` only `.gitkeep`;
- ignored ZIP status/hash/time evidence;
- raw handoff ZIP and duplicate `(1)` source remain untracked;
- final local/remote branch SHA and divergence evidence;
- final worktree status.

## Publication Boundaries

Commit and ordinary push are allowed. Force push, PR creation by Codex, merge, and branch deletion are forbidden.
