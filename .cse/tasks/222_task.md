# Step 222 Task - Field Observation Attachment Convenience Lookup Boundary

GitHub Issue: #61

## Purpose

Plan the API boundary and future test matrix for a narrow Field
Observation-specific attachment convenience lookup.

This is a documentation/state/learning-only step. It must not implement the
helper or change production behavior.

## Base

- Repository: `faliardic/chief-site-engineer`
- Official local repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Base branch: `master`
- Required base / merge commit: `7c326740ef968e7fda3094eaf04f8dec8ecbf333`
- Latest merged safe point: Step 221 / PR #60 / Issue #59
- Required branch: `step-222-field-observation-attachment-convenience-lookup-boundary`
- Current test baseline: `471 passed`
- Latest completed podcast: Podcast 034 / Steps 216-220
- Next podcast range: Steps 221-225

## Required Scope

Create:

- `.cse/tasks/222_task.md`
- `.cse/results/222_result.md`
- `docs/222_field_observation_attachment_convenience_lookup_boundary.md`
- `learning/222_field_observation_attachment_convenience_lookup_boundary.md`

Update only as needed:

- `.cse/state/project_state.json`
- `README.md`
- `ROADMAP.md`
- `CHANGELOG.md`
- `docs/project_decisions.md`
- `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`

## Contract To Document

Future helper:

```python
def list_for_field_observation(
    self,
    observation_id: str,
) -> list[FileAttachmentRecord]:
    ...
```

Intended semantic equivalence:

```python
list_by_related_record("field_observation", observation_id)
```

The future helper should:

- be a convenience read boundary only;
- preferably delegate to the existing combined helper;
- use the exact literal `"field_observation"`;
- preserve exact and case-sensitive `observation_id` matching;
- perform no trimming, normalization, parsing, mapping, aliasing, prefix
  inference, or validation;
- preserve insertion order;
- return a new list on every call;
- return the same stored `FileAttachmentRecord` objects;
- not copy or mutate attachment metadata;
- not mutate `FieldObservationRecord`;
- not require or query `FieldObservationRepository`;
- not validate that the referenced observation exists;
- preserve existing independent and combined related-record filters.

## Future Test Matrix

Document future tests for:

1. exact matching Field Observation attachments return in insertion order;
2. same ID under another record type is excluded;
3. same record type with another ID is excluded;
4. case-different observation IDs do not match;
5. whitespace-different observation IDs do not match;
6. empty repository returns `[]`;
7. unknown observation ID returns `[]`;
8. each call returns a new list;
9. returned items are the same stored objects;
10. returned-list mutation does not alter repository contents;
11. attachment metadata is not mutated;
12. repository count and `list_all()` order remain unchanged;
13. missing observation existence is not validated;
14. convenience helper output equals
    `list_by_related_record("field_observation", observation_id)`;
15. existing independent and combined filters remain unchanged.

## Explicit Non-Scope

Do not add or change:

- production code;
- executable tests or test expectations;
- `FileAttachmentRepository` methods;
- `FieldObservationRepository` methods;
- `FieldObservationRecord` or `FileAttachmentRecord` fields or behavior;
- constants, enums, constructor validation, hard validation, or migrations;
- automatic attachment creation or linking;
- reverse attachment collections on observations;
- relationship existence validation;
- physical file operations;
- filesystem integrity checks;
- persistence/database/JSON/SQLite;
- API, GUI, CLI, PWA, or offline sync;
- export/report consumers;
- audit/history/task/NCR/notification/decision generation;
- generated `blocked` status;
- workflow files or GitHub Actions settings;
- Podcast 034;
- Podcast 035;
- Step 223 implementation;
- ignored ZIP or Desktop archive.

## Verification Required

Run:

```powershell
python -m pytest
python -m json.tool .cse\state\project_state.json
git diff --check
git diff -- app/models.py app/records.py tests/test_models.py tests/test_records.py app/attachment_integrity.py tests/test_attachment_integrity.py .github/workflows/pytest.yml docs/podcast_notes/034_adim_216_220_notebooklm_podcast_notu.md
Get-ChildItem exports -Force
```

Expected:

- full tests remain `471 passed`;
- production code and executable tests have no diff;
- protected paths have no diff;
- `exports/` contains only `.gitkeep`;
- ignored ZIP remains untouched;
- Podcast 035 does not exist;
- changed files remain within Issue #61 scope.

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
Plan field observation attachment convenience lookup boundary
```
