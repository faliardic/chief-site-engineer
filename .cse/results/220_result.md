# Step 220 Result - FileAttachmentRepository Combined Related-Record Filter

## Summary

Step 220 implemented `FileAttachmentRepository.list_by_related_record(...)` as
the exact combined related-record filter documented in Step 219.

The method matches only when `related_record_type` and `related_record_id`
both match on the same stored `FileAttachmentRecord`.

## Synchronization Evidence

Official local repository:

```text
V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer
```

Post-merge synchronization:

```text
master = origin/master = 4d006a2f49f10792a74dca068ea415ba37200797
divergence = 0 0
```

Misspelled workspace check:

```text
C:\Users\Fatih\Documents\chieh-site-engineer
False
```

Working branch:

```text
step-220-file-attachment-combined-related-record-filter
```

## Scope Completed

- Added `FileAttachmentRepository.list_by_related_record(...)`.
- Added 10 focused `combined_related_record` tests.
- Created `.cse/tasks/220_task.md`.
- Created `docs/220_file_attachment_repository_combined_related_record_filter.md`.
- Created `learning/220_file_attachment_repository_combined_related_record_filter.md`.
- Updated `.cse/state/project_state.json`.
- Updated `README.md`.
- Updated `ROADMAP.md`.
- Updated `CHANGELOG.md`.
- Updated `docs/project_decisions.md`.
- Updated `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`.

## Implemented Behavior

```python
def list_by_related_record(
    self,
    related_record_type: str,
    related_record_id: str,
) -> list[FileAttachmentRecord]:
    return [
        record
        for record in self._records
        if record.related_record_type == related_record_type
        and record.related_record_id == related_record_id
    ]
```

The implementation:

- filters only the in-memory `_records` list;
- requires type and id to match on the same record;
- uses exact, case-sensitive string equality;
- does not trim, normalize, parse, map, alias, infer, or validate;
- preserves insertion order;
- returns a new list every call;
- returns the same stored record objects;
- does not copy or mutate metadata;
- does not verify related-record existence;
- leaves independent type/id filters unchanged.

## Verification

Focused pytest:

```text
python -m pytest tests\test_records.py -k "file_attachment_repository and combined_related_record"
10 passed, 106 deselected in 0.30s
```

Full pytest:

```text
python -m pytest
471 passed in 1.11s
```

JSON validation:

```text
python -m json.tool .cse\state\project_state.json
passed
```

Whitespace diff validation:

```text
git diff --check
passed; only Git line-ending warning for .cse/state/project_state.json
```

Changed-file scope before result file:

```text
.cse/state/project_state.json
CHANGELOG.md
README.md
ROADMAP.md
app/records.py
docs/project_decisions.md
docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md
tests/test_records.py
.cse/tasks/220_task.md
docs/220_file_attachment_repository_combined_related_record_filter.md
learning/220_file_attachment_repository_combined_related_record_filter.md
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

Forbidden convenience helper check:

```text
rg -n "list_for_field_observation" app
no matches
```

Podcast 034 check:

```text
docs/podcast_notes/034*
no files
```

Exports:

```text
exports/.gitkeep only
```

Ignored ZIP evidence:

```text
chief-site-engineer_adim_080_guvenli_nokta.zip
Length: 326209
LastWriteTime: 7.06.2026 14:30:04
SHA256: E96CAA2115B98C54A5B030DAB265DC62AFD509BB4F6E59E2694AF0C89165C653
```

Untracked/ignored source evidence before staging:

```text
?? .cse/tasks/220_task.md
?? docs/220_file_attachment_repository_combined_related_record_filter.md
?? learning/220_file_attachment_repository_combined_related_record_filter.md
!! chief-site-engineer_adim_080_guvenli_nokta.zip
```

Duplicate `(1)` source check:

```text
none found
```

Pre-publication branch evidence:

```text
branch: step-220-file-attachment-combined-related-record-filter
HEAD: 4d006a2f49f10792a74dca068ea415ba37200797
origin/master...HEAD divergence: 0 0
```

Final post-push local/remote SHA and divergence evidence will be posted to
GitHub Issue #57 after the commit is pushed.
