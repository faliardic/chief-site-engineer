# Step 223 Task - Field Observation Attachment Convenience Lookup

GitHub Issue: #63

## Purpose

Implement the narrow Field Observation-specific attachment lookup planned in
Step 222.

Add only this convenience method to `FileAttachmentRepository`:

```python
def list_for_field_observation(
    self,
    observation_id: str,
) -> list[FileAttachmentRecord]:
    return self.list_by_related_record("field_observation", observation_id)
```

This is a small production-code and executable-test step. The method must
delegate to the existing exact combined helper and must not duplicate `_records`
filtering logic.

## Base

- Repository: `faliardic/chief-site-engineer`
- Official local repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Base branch: `master`
- Required base / merge commit: `8ba82cf2109df9d8cd385a5c38ee58a637afba9c`
- Latest merged safe point: Step 222 / PR #62 / Issue #61
- Required branch: `step-223-field-observation-attachment-convenience-lookup`
- Current test baseline: `471 passed`
- Latest completed podcast: Podcast 034 / Steps 216-220
- Next podcast range: Steps 221-225

## Required Scope

Modify:

- `app/records.py`
- `tests/test_records.py`

Create:

- `.cse/tasks/223_task.md`
- `.cse/results/223_result.md`
- `docs/223_field_observation_attachment_convenience_lookup.md`
- `learning/223_field_observation_attachment_convenience_lookup.md`

Update only as needed:

- `.cse/state/project_state.json`
- `README.md`
- `ROADMAP.md`
- `CHANGELOG.md`
- `docs/project_decisions.md`
- `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
- `learning/GLOSSARY.md`

## Required Behavior

`list_for_field_observation(observation_id)` must:

- delegate to `list_by_related_record(...)`;
- use the exact literal `"field_observation"`;
- preserve exact and case-sensitive `observation_id` matching;
- perform no trimming, normalization, parsing, mapping, aliasing, prefix
  inference, or validation;
- preserve insertion order;
- return a new list on every call through the existing combined helper;
- return the same stored `FileAttachmentRecord` objects;
- not copy or mutate attachment metadata;
- not mutate or query `FieldObservationRecord`;
- not require or query `FieldObservationRepository`;
- not validate that the referenced observation exists;
- preserve existing independent and combined related-record filters.

## Required Tests

Add focused tests covering:

- delegation to the combined helper;
- exact Field Observation matches in insertion order;
- same-id/different-type and same-type/different-id exclusion;
- case-different and whitespace-different observation id behavior;
- empty repository and unknown observation id;
- new-list behavior and external list mutation safety;
- same stored object returns and metadata non-mutation;
- count and `list_all()` order stability;
- missing observation existence non-validation;
- equivalence with `list_by_related_record("field_observation", observation_id)`;
- existing independent and combined filter regression coverage.

Focused selector:

```powershell
python -m pytest tests\test_records.py -k "file_attachment_repository and field_observation and convenience"
```

## Explicit Non-Scope

Do not add or change:

- model fields or constructor behavior;
- constants or enums;
- hard validation or migrations;
- `FieldObservationRepository` methods;
- automatic attachment creation or linking;
- reverse attachment collections on observations;
- relationship existence validation;
- physical file upload/download/copy/move/rename/delete;
- filesystem integrity behavior;
- persistence/database/JSON/SQLite;
- API, GUI, CLI, PWA, or offline sync;
- export/report consumers;
- audit/history/task/NCR/notification/decision generation;
- generated `blocked` status;
- workflow files or GitHub Actions settings;
- Podcast 034;
- Podcast 035;
- Step 224 implementation;
- ignored ZIP or Desktop archive.

## Verification Required

Run:

```powershell
python -m pytest tests\test_records.py -k "file_attachment_repository and field_observation and convenience"
python -m pytest
python -m json.tool .cse\state\project_state.json
git diff --check
git diff -- app/models.py tests/test_models.py app/attachment_integrity.py tests/test_attachment_integrity.py .github/workflows/pytest.yml docs/podcast_notes/034_adim_216_220_notebooklm_podcast_notu.md
Get-ChildItem exports -Force
```

Expected:

- focused tests pass;
- full test count increases above `471 passed`;
- JSON validation and `git diff --check` pass;
- only authorized production/test files change;
- protected paths have no diff;
- `exports/` contains only `.gitkeep`;
- ignored ZIP remains untouched;
- Podcast 035 does not exist;
- changed files remain within Issue #63 scope plus glossary update required by
  repo learning rules.

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
Add field observation attachment convenience lookup
```
