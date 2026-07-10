# Step 176 - Export Result Report Markdown Formatter Usage and Edge Cases

This step standardizes how `format_export_result_report_as_markdown(report)` should be used and read. It is documentation-only.

## Purpose

`format_export_result_report_as_markdown(report)` is a read-only presentation helper for export result reports.

It expects the dict output of:

```python
build_export_result_report(...)
```

It returns a presentation-safe Markdown string that can be shown in handover QC notes, export review summaries, admin/debug notes, or project log text.

The formatter only converts the existing report dict into a readable presentation. It does not decide whether an export passed or failed.

## Fixed Boundary

The formatter:

- does not write files
- does not create export output files
- does not mutate the input dict
- does not recompute export success or failure
- does not recompute summary/report results
- does not change `build_export_result_summary(...)`
- does not change `build_export_result_report(...)`
- does not change `format_export_result_summary_as_markdown(...)`
- does not change low-level `write_*` helper behavior
- does not change `try_write_*` wrapper behavior
- is not hard validation
- does not reject records
- does not produce `blocked` status
- does not add API, GUI, CLI, database/repository, audit, backup, or restore behavior

The helper is a visibility layer. It supports human review in handover/export QC, but it is not an automatic blocking or approval mechanism.

## Success-only Reports

For a report where every item has `status: success`, the Markdown should be read as a success visibility summary.

Expected interpretation:

- overall status is success
- total and success counts should match
- review and unknown counts should be zero
- item paths show what the report already says was written
- the formatter does not verify that files currently exist

The formatter does not rerun path checks and does not recreate export results.

## Failure-only Reports

For a report where every item has review/failure status, the Markdown should be read as a human review summary.

Expected interpretation:

- overall status is review
- success count is zero
- failure/review count is visible
- attempted paths remain visible when available
- error type and technical detail remain visible when present

This is not a record rejection. It is a readable statement that one or more export attempts need review.

## Mixed Reports

For mixed success/failure reports, the Markdown should keep both sides visible.

Expected interpretation:

- successful item paths remain visible
- failed/review item paths and messages remain visible
- total, success, review, and unknown counts should be read from the report
- the formatter does not collapse the report into only success or only failure

Mixed reports are useful when a batch export partly succeeded and partly needs manual attention.

## Empty or Missing Items

If the report has no items, the Markdown should be treated as a presentation fallback. It can show count fields if they are present, and it can state that no export result items are available.

If count fields are missing, the formatter should stay in presentation mode and use readable fallback text. Missing fields do not become hard validation failures.

Empty or incomplete report data should be reviewed by the caller or user. The formatter itself does not infer a stronger decision.

## Missing or Unknown Fields

The formatter may encounter missing or unknown fields in a report dict.

Expected interpretation:

- missing paths mean path display may fall back to "not available"
- missing messages mean a generic item message may be shown
- unknown status values remain presentation data unless explicitly normalized for safe display
- technical detail is shown only when already present

The formatter should not call builders or wrappers to fill missing fields. It should not reinterpret raw result contracts as a fresh report.

## Handover QC Reading

In handover QC or export review screens, the Markdown should be read as supporting evidence for human review.

Recommended reading order:

- read the overall status and counts first
- compare success/review/unknown counts
- scan item messages
- inspect paths and attempted paths
- inspect error type and technical detail where present
- decide next human action outside the formatter

The Markdown is not the authority for business decisions. It is a compact view of the already built report.

## Explicit Non-Scope

This step does not change code or tests.

It does not add a new helper, change formatter behavior, write export files, leave files under `exports/`, add hard validation, add `blocked` status, add API/GUI/CLI behavior, access database/repository state, create audit events, add backup/restore behavior, commit, or push.
