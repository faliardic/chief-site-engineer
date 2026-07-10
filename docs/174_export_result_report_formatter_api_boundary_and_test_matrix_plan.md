# Step 174 - Export Result Report Formatter API Boundary and Test Matrix Plan

This step documents the future API boundary and test matrix for a possible export result report Markdown formatter. It is documentation-only.

## Current State

Step 170 added the read-only export result summary/report helper layer.

The current helper layer includes:

- `build_export_result_summary(...)`
- `build_export_result_report(...)`
- `format_export_result_summary_as_markdown(...)`

Step 171 documented usage boundaries for those helpers.

Step 172 documented edge case standardization for incomplete, unsupported, mixed, duplicate, and fallback cases.

Step 173 documented the follow-up direction after the summary/report helper layer.

The current Markdown formatter is:

- `format_export_result_summary_as_markdown(...)`

There is no dedicated report-level Markdown formatter yet.

## Planned Future Helper

A possible future helper name is:

```text
format_export_result_report_as_markdown(report)
```

This helper is only planned in this step. It is not implemented here.

## API Boundary

The future helper should accept the dict output of `build_export_result_report(...)`.

The future helper should return a presentation-safe Markdown string.

It should not:

- write files
- create export output
- access a database or repository
- produce diagnostic or soft validation results
- recompute summary/report results
- mutate the input dict
- create `blocked` status
- trigger hard validation
- call low-level `write_*` helpers
- call `try_write_*` wrapper helpers

The planned design should prefer presentation-safe fallback text over exception-focused hard failure behavior.

Unsupported or incomplete input should be made readable for review where possible. It should not become automatic package rejection.

## Markdown Content Plan

A future Markdown report output may include:

- title
- overall status
- total success count
- total failure or review count
- path visibility
- error message visibility
- result contract item list
- human review note
- a note that the output is not hard validation

The output should be compact enough for handover QC and project log use.

Technical detail may be preserved, but it should not hide the user-facing status and review message.

## Test Matrix Plan

Future tests may cover these categories:

| Category | Expected focus |
| --- | --- |
| Empty report | Returns readable Markdown without hard failure. |
| All success results | Shows success status and success count clearly. |
| Mixed success/failure results | Shows mixed status and keeps review items visible. |
| Missing optional fields | Uses fallback display text without broken Markdown. |
| Unknown status value | Preserves review visibility without inventing stronger status. |
| Path visibility | Displays available attempted/output path information safely. |
| Error message visibility | Shows readable error or review message where present. |
| Input immutability | Does not mutate the report dict or nested item data. |
| No recomputation | Does not call export helpers or rebuild report data. |
| Markdown output is string | Always returns a string for presentation use. |
| No blocked status | Does not create or mention `blocked` as a generated status. |
| No file writing | Does not create `.md`, `.json`, or export output files. |
| No low-level helper behavior change | Does not change `write_*` helper behavior. |
| No wrapper behavior change | Does not change `try_write_*` wrapper behavior. |

This step does not add these tests. It only records the planned matrix.

## Fixed Boundaries

This step and the future helper plan must preserve these boundaries:

- No implementation in this step.
- No tests in this step.
- No `app/models.py` change.
- No `tests/test_models.py` change.
- No hard validation.
- No `blocked` status.
- No backup/restore behavior.
- No database or repository behavior.
- No API, GUI, or CLI behavior.
- No export output file generation.
- No changes to current helper behavior.
- No changes to low-level `write_*` helper behavior.
- No changes to `try_write_*` wrapper behavior.
- No conversion of the summary/report helper layer into diagnostic or audit behavior.
- No ZIP/cache/export output files in repo scope.

The formatter should remain a read-only presentation helper if it is implemented in a future step.

## Recommended Next Step

Recommended next step:

```text
Step 175 - Read-only export result report markdown formatter implementation
```

Step 175 is not started in this step.

## Explicit Non-Scope

This step does not add code, tests, helper behavior changes, export output files, hard validation, `blocked` status, backup/restore behavior, API, GUI, CLI, audit event creation, database/repository behavior, Podcast 029, ZIP/cache staging, commit, or push.
