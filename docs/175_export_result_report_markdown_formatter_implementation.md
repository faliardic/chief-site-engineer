# Step 175 - Export Result Report Markdown Formatter Implementation

This step implements the dedicated read-only Markdown formatter for export result reports.

## Scope

The new helper is:

```python
format_export_result_report_as_markdown(report)
```

It accepts the dict output produced by `build_export_result_report(...)` and returns a presentation-safe Markdown string.

The helper is a formatter only. It reads the already prepared report fields and presents them for handover QC, admin/debug review, or project log use.

## Behavior

The Markdown output shows:

- overall report status
- total count
- success count
- failure/review count
- unknown count
- safe user-facing report message
- item status
- item file type
- item path
- output path and attempted path when present
- allowed root when present
- error type
- technical detail
- next action hint
- overwrite visibility

This keeps success and failure visibility available without changing the report contract.

## Read-only Boundary

`format_export_result_report_as_markdown(...)` does not:

- write files
- create export output
- access a database or repository
- call export writer helpers
- call `try_write_*` wrapper helpers
- recompute summary/report results
- mutate the input dict
- produce diagnostic or soft validation results
- create audit events
- trigger hard validation
- produce `blocked` status

The helper prefers readable fallback text for incomplete presentation input.

## Preserved Behavior

This step preserves the existing behavior of:

- `build_export_result_report(...)`
- `build_export_result_summary(...)`
- `format_export_result_summary_as_markdown(...)`
- `write_json_ready_dict_to_file(...)`
- `write_markdown_text_to_file(...)`
- `try_write_json_ready_dict_to_file(...)`
- `try_write_markdown_text_to_file(...)`

The new helper does not replace the existing summary formatter. It only adds a report-specific presentation helper.

## Test Coverage

Step 175 adds tests for:

- successful export result report Markdown formatting
- failed export result report Markdown formatting
- mixed success/failure visibility
- count and summary visibility
- error/failure message visibility
- Markdown output as a string
- input dict immutability
- no file writing
- no export output creation
- no generated `blocked` status
- no report recomputation
- unsupported input fallback
- existing summary formatter regression
- existing write helper and `try_write_*` wrapper behavior preservation through the existing regression suite

## Explicit Non-Scope

This step does not add API, GUI, CLI, database/repository behavior, backup/restore behavior, hard validation, audit event creation, diagnostic or soft validation output, export output files, commit, push, or ZIP/cache staging.
