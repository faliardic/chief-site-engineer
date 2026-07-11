# Step 217 Task

## GitHub Source

- Issue: `#50`
- Title: `Step 217: Add minimal FileAttachmentRepository baseline`
- Repository: `faliardic/chief-site-engineer`
- Official local repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Required base branch: `master`
- Required base / merge commit: `43345c7e57ea9a786354d9ee8348f39aaf53af8f`
- Latest merged safe point: Step 216 / PR #49 / Issue #48
- Required branch: `step-217-file-attachment-repository-baseline`
- Current test baseline: `445 passed`
- Latest completed podcast: Podcast 033 / Steps 211-215
- Next podcast range: Steps 216-220

## Required Pre-Read

Read before implementation:

1. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
2. `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
3. GitHub Issue #50 and its execution decision comment
4. `.cse/tasks/217_task.md`

Also inspect:

- `app/models.py`
- `app/records.py`
- `tests/test_records.py`
- `tests/test_models.py`
- `docs/068_dosya_eki_kaydi_modeli.md`
- `docs/080_file_attachment_metadata_butunluk_ozeti.md`
- `docs/089_attachment_metadata_integrity_kurallari.md`
- `docs/208_first_field_mvp_observation_record_contract.md`
- `docs/podcast_notes/033_adim_211_215_notebooklm_podcast_notu.md`

Stop before edits if a required tracked source is missing or an unresolved permanent-rule conflict is found.

## Goal

Add a minimal in-memory `FileAttachmentRepository` baseline for already-created `FileAttachmentRecord` metadata objects.

The repository must store metadata records only. It must not read, copy, upload, move, delete, validate, inspect, normalize, or generate physical files. It must not link attachments specifically to `FieldObservationRecord` yet. Related-record filters belong to a later explicit step.

## Implementation Scope

Update `app/records.py` to import `FileAttachmentRecord` and add:

```python
class FileAttachmentRepository:
    """Stores file attachment metadata records in memory."""

    def __init__(self) -> None:
        self._records: list[FileAttachmentRecord] = []

    def add(self, record: FileAttachmentRecord) -> None:
        ...

    def list_all(self) -> list[FileAttachmentRecord]:
        ...

    def count(self) -> int:
        ...

    def find_by_id(self, attachment_id: str) -> FileAttachmentRecord | None:
        ...
```

Required behavior:

- Store only existing `FileAttachmentRecord` objects in memory.
- Reject duplicate `attachment_id` values with `ValueError`.
- Duplicate detection must use exact, case-sensitive identity matching.
- Accept distinct attachment IDs without changing records.
- Preserve insertion order.
- `list_all()` must return a new list on every call.
- Returned records must be the same stored objects by reference.
- Do not copy or mutate records.
- `count()` returns the current number of stored metadata records.
- `find_by_id(...)` returns the same stored object when found and `None` when missing.
- Do not add validation beyond the existing `FileAttachmentRecord` constructor contract.
- Do not trim, normalize, map, parse, change paths, change file names, change MIME/file types, or touch optional metadata.

## Focused Tests

Update `tests/test_records.py` with a minimal `_file_attachment(...)` helper and focused tests proving:

1. a new repository is empty, count is zero, and missing lookup returns `None`;
2. adding one valid record stores and returns the same object;
3. multiple distinct records preserve insertion order;
4. duplicate exact `attachment_id` is rejected and repository contents remain unchanged;
5. case-different attachment IDs remain distinct;
6. `list_all()` returns a new list and external list mutation does not alter repository contents;
7. repository operations do not mutate attachment metadata fields;
8. existing `FieldObservationRepository` and `NonconformityRepository` behavior remains unchanged.

Do not duplicate model-validation tests owned by `tests/test_models.py`.

## Documentation And State

Create:

- `.cse/results/217_result.md`
- `docs/217_file_attachment_repository_baseline.md`
- `learning/217_file_attachment_repository_baseline.md`

Update:

- `.cse/state/project_state.json`
- `README.md`
- `ROADMAP.md`
- `CHANGELOG.md`
- `docs/project_decisions.md`
- `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`

Record that Step 216 / PR #49 / Issue #48 / merge `43345c7e57ea9a786354d9ee8348f39aaf53af8f` is the latest merged safe point, Podcast 033 is the latest completed podcast, and Step 217 is active unmerged attachment metadata repository baseline work.

## Explicit Non-Scope

Do not add related-record filters, Field Observation-specific attachment lookup or linking, automatic `FileAttachmentRecord` creation, physical file operations, filesystem checks, path generation, path normalization, allowed-root enforcement, persistence, status/archive lifecycle behavior, validation, enums, constants, API/GUI/CLI, audit/history/task/NCR/notification/decision generation, Step 218, or Podcast 034.

## Verification

Run and record:

- focused tests such as `python -m pytest tests/test_records.py -k "file_attachment_repository"`;
- full `python -m pytest`, with test count above `445 passed`;
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
