# Step 219 Task - Field Observation Attachment Linking Contract

GitHub Issue: #54

## Purpose

Define the narrow metadata-linking contract between `FieldObservationRecord`
and existing `FileAttachmentRecord` objects before adding any
observation-specific repository method.

This step is documentation/state/learning-only. It must not change production
code, executable tests, model validation, repository behavior, physical files,
or persistence.

## Base

- Repository: `faliardic/chief-site-engineer`
- Official local repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Base branch: `master`
- Required base / merge commit: `62b95867165f5ff6b3aec85fc841557bc678df42`
- Latest merged safe point: Step 218 / PR #53 / Issue #52
- Required branch: `step-219-field-observation-attachment-linking-contract`
- Current test baseline: `461 passed`
- Latest completed podcast: Podcast 033 / Steps 211-215
- Next podcast range: Steps 216-220

## Required Scope

Create:

- `.cse/tasks/219_task.md`
- `.cse/results/219_result.md`
- `docs/219_field_observation_attachment_linking_contract.md`
- `learning/219_field_observation_attachment_linking_contract.md`

Update:

- `.cse/state/project_state.json`
- `README.md`
- `ROADMAP.md`
- `CHANGELOG.md`
- `docs/project_decisions.md`
- `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`

No other project file is authorized.

## Contract To Document

A `FileAttachmentRecord` represents metadata linked to a field observation only
when both of these exact conditions are true:

```text
related_record_type == "field_observation"
related_record_id == FieldObservationRecord.observation_id
```

Required semantics:

- both comparisons are exact string equality;
- comparisons are case-sensitive;
- no trimming, normalization, parsing, mapping, aliasing, or prefix inference;
- literal `field_observation` is the Field MVP attachment relationship type for
  this contract only;
- no global enum, constants, model validation, or migration in this step.

## Cardinality And Ownership

- One field observation may have zero, one, or many attachment metadata records.
- Each `FileAttachmentRecord` contains one singular related-record type/id pair.
- Different attachments may point to the same observation ID.
- `attachment_id` remains attachment repository identity and stays unique under
  existing rules.
- Linking does not mutate the observation record.
- Linking does not place attachment IDs inside `FieldObservationRecord`.
- The attachment metadata record owns the relationship fields.

## Existence And Orphan Behavior

- Model and repository layers do not verify that the referenced observation
  currently exists.
- A metadata record may temporarily reference a missing observation.
- No automatic deletion, repair, relinking, blocking, NCR, task, audit event, or
  warning object is generated.
- Future service/integrity layers may inspect relationship existence, outside
  this step.

## Read Boundary To Document Only

Existing independent filters may be composed by a caller, but they are not a
safe combined relationship query because an ID can be shared by different record
types.

Document future repository boundary without implementing it:

```python
def list_by_related_record(
    self,
    related_record_type: str,
    related_record_id: str,
) -> list[FileAttachmentRecord]:
    ...
```

Document future Field Observation convenience helper without implementing it:

```python
def list_for_field_observation(
    self,
    observation_id: str,
) -> list[FileAttachmentRecord]:
    ...
```

## Future Test Matrix To Document

1. exact type+ID pair matches in insertion order;
2. same ID under a different type is excluded;
3. same type with a different ID is excluded;
4. case and whitespace variants do not match;
5. empty/unknown queries return `[]`;
6. each call returns a new list;
7. same stored objects are returned without mutation;
8. repository count/order remain stable;
9. missing observation existence is not validated by the repository;
10. a Field Observation convenience helper, if later added, is equivalent to
    exact pair `("field_observation", observation_id)`.

## Explicit Non-Scope

Do not add or change production code, executable tests,
`list_by_related_record(...)`, `list_for_field_observation(...)`, model fields,
constructors, `__post_init__`, enums, constants, hard validation, automatic
relationship existence checks, reverse attachment collections on
`FieldObservationRecord`, physical file behavior, filesystem checks, path
generation/normalization, persistence/database/JSON/SQLite, lifecycle behavior,
API/GUI/CLI, audit/history/task/NCR/notification/decision generation, generated
`blocked`, Step 220, or Podcast 034.

## Verification Required

- `python -m pytest` must remain `461 passed`.
- `git diff --check`.
- `python -m json.tool .cse/state/project_state.json`.
- Changed-file scope check.
- Exact review of contract and future test matrix.
- Protected-path diffs empty for code/test/workflow/Podcast 033.
- Verify `list_by_related_record` and `list_for_field_observation` are not
  implemented in `app/`.
- Verify Podcast 034 was not created.
- Verify `exports/` contains only `.gitkeep`.
- Verify ignored ZIP hash/time evidence remains untouched.
- Verify raw handoff ZIP and duplicate `(1)` source remain untracked.
- Record final local/remote branch SHA, divergence, and worktree status.

## Publication

Commit and ordinary push are allowed. Force push, PR creation by Codex, merge,
and branch deletion are forbidden.
