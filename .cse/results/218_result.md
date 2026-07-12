# Step 218 Result - FileAttachmentRepository Related-Record Filters

## Summary

Step 218 implemented two read-only related-record filters on the existing
in-memory `FileAttachmentRepository`:

- `list_by_related_record_type(related_record_type)`
- `list_by_related_record_id(related_record_id)`

The filters use exact, case-sensitive string equality against the existing
in-memory `_records` list. They preserve insertion order, return a new list on
each call, return the same stored `FileAttachmentRecord` objects, and do not
copy or mutate metadata.

## Scope Completed

- Added `FileAttachmentRepository.list_by_related_record_type(...)`.
- Added `FileAttachmentRepository.list_by_related_record_id(...)`.
- Added focused tests for exact matching, unknown/case/whitespace behavior,
  independent type/id filters, empty repository behavior, new-list returns,
  same-object returns, metadata non-mutation, stable count/order, and existing
  repository regression coverage.
- Added `docs/218_file_attachment_repository_related_record_filters.md`.
- Added `learning/218_file_attachment_repository_related_record_filters.md`.
- Updated README, ROADMAP, CHANGELOG, project decisions, unified project source,
  and `.cse/state/project_state.json`.

## Explicitly Not Added

- No combined type+id filter.
- No `list_for_field_observation(...)` convenience method.
- No lookup into `FieldObservationRepository`, `NonconformityRepository`, or any
  other repository.
- No automatic attachment creation, validation, linking, lifecycle behavior, or
  relationship resolution.
- No physical file operation, filesystem check, path generation, path
  normalization, persistence, database, JSON storage, API, GUI, CLI, audit,
  history, task, NCR, notification, decision generation, Step 219, or Podcast
  034.

## Verification

Focused pytest:

```text
python -m pytest tests\test_records.py -k "file_attachment_repository and related_record"
8 passed, 98 deselected in 0.26s
```

Full pytest:

```text
python -m pytest
461 passed in 1.07s
```

JSON state validation:

```text
python -m json.tool .cse\state\project_state.json
passed
```

Whitespace diff validation:

```text
git diff --check
passed
```

Protected-path diff:

```text
app/models.py
tests/test_models.py
app/attachment_integrity.py
tests/test_attachment_integrity.py
.github/workflows/pytest.yml
docs/podcast_notes/033_adim_211_215_notebooklm_podcast_notu.md

no diff
```

Exports:

```text
exports/.gitkeep only
```

Ignored ZIP evidence:

```text
chief-site-engineer_adim_080_guvenli_nokta.zip
SHA256: E96CAA2115B98C54A5B030DAB265DC62AFD509BB4F6E59E2694AF0C89165C653
LastWriteTime: 7.06.2026 14:30:04
```

Untracked source check before staging:

```text
.cse/tasks/218_task.md
docs/218_file_attachment_repository_related_record_filters.md
learning/218_file_attachment_repository_related_record_filters.md
```

Duplicate `(1)` source check:

```text
none found
```

Branch evidence before staging:

```text
branch: step-218-file-attachment-related-record-filters
HEAD: 075acdbc77927925092b748b77aad7c0ce13d9ef
origin/master...HEAD divergence: 0 0
```
