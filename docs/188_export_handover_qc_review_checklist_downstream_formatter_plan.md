# Step 188 - Export / Handover QC Review Checklist Downstream Formatter Plan

This step plans a possible future presentation formatter for:

```python
build_export_handover_qc_review_checklist(summary, report)
```

This is documentation-only.

It is not a formatter implementation.

It does not change code, tests, helper behavior, export output, database/repository behavior, audit behavior, backup/restore behavior, hard validation, or `blocked` status behavior.

## Formatter Purpose

A future downstream formatter may turn the checklist JSON-ready dict into a presentation-safe Markdown or string report.

The formatter would help a human reviewer read:

- checklist status
- summary counts
- item visibility
- paths
- messages
- error types
- technical details
- next action hints
- read-only / non-blocking flags
- review notes

The formatter would be a presentation layer only.

It would not become the authority for handover approval, rejection, or blocking.

## Input Contract

A future formatter should accept the checklist JSON-ready dict produced by:

```python
build_export_handover_qc_review_checklist(summary, report)
```

The formatter should not parse raw export writer contracts as its primary input.

The formatter should not parse existing Markdown as source of truth.

The formatter should not mutate the checklist dict.

The formatter should not recompute checklist status, counts, or item results.

## Output Contract

A future formatter should return only presentation-safe text.

Likely output forms:

- Markdown string
- plain presentation string

The formatter should not:

- write files
- create export output
- create files under `exports/`
- call `write_*` helpers
- call `try_write_*` wrappers
- access database/repository state
- create audit events
- run backup/restore
- add API/GUI/CLI behavior
- perform hard validation
- generate `blocked` status

## Required Visibility

The Markdown/string output should preserve these checklist meanings:

- `is_read_only=True` means the checklist is read-only visibility.
- `is_blocking=False` means the checklist does not block a package.
- `requires_human_review` means inspection visibility, not blocking.
- `review_notes` are explanatory notes, not official decisions.

The formatted output should make clear that the report is for human review.

It should not imply automatic approval, automatic rejection, or automatic blocking.

## Scenario Views

Success-only checklist view:

- show successful item visibility
- show success counts
- preserve `is_read_only=True`
- preserve `is_blocking=False`
- avoid presenting success as official acceptance

Failure-only checklist view:

- show review item visibility
- show path, error type, technical detail, and next action hints where available
- show `requires_human_review`
- avoid presenting failure as automatic rejection or blocking

Mixed checklist view:

- show both success and review items
- keep successful items visible
- keep review items visible for human attention
- avoid turning mixed visibility into automatic package blocking

Empty / zero-count checklist view:

- show limited or unknown visibility
- show zero counts
- avoid presenting empty data as success or failure proof

Missing optional field view:

- use safe fallback text
- avoid creating new validation rules
- avoid implying that missing optional fields block the package

Unknown/additional field view:

- stay within presentation/QC visibility
- avoid silently turning unknown fields into business rules
- avoid adding hidden approval, rejection, persistence, or audit behavior

## Handover QC and Export Review Use

A future formatter could support:

- handover QC review notes
- incoming site chief visibility
- export review workflow summaries
- admin/debug review of export output status
- presentation-only GUI/API/CLI surfaces

Those uses must remain read-only.

They must not mutate checklist output.

They must not decide the handover package outcome.

## Existing Helper Behavior

Any future formatter must preserve:

- `build_export_handover_qc_review_checklist(...)`
- `build_export_result_summary(...)`
- `build_export_result_report(...)`
- `format_export_result_report_as_markdown(...)`
- `format_export_result_summary_as_markdown(...)`
- `write_*`
- `try_write_*`

The formatter would consume checklist output.

It would not replace checklist building, report building, summary building, existing formatters, or file-writing helpers.

## Implementation Boundary

If a formatter is implemented later, it must be a separate step.

That future step needs:

- a clear helper name
- explicit input/output contract
- tests for success-only, failure-only, mixed, empty, missing optional field, and unknown/additional field views
- tests for no mutation
- tests for no file writing
- tests for no export output
- tests for no hard validation
- tests for no generated `blocked` status
- documentation for handover QC interpretation

Step 188 does not implement that formatter.

## Explicit Non-Scope

Step 188 does not add:

- code changes
- test changes
- new helper
- new formatter
- API endpoint
- GUI
- CLI command
- database/repository access
- audit event
- backup/restore
- export output file
- `exports/` output
- hard validation
- generated `blocked` status
- commit
- push
