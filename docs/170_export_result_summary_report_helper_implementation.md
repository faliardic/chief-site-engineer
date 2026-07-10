# Step 170 - Export Result Summary/Report Helper Implementation

This step adds the first read-only implementation layer for interpreting export helper result contracts.

## Scope

The new helpers work with result contract data already returned by the wrapper helpers:

- `build_export_result_summary(result_contract)`
- `build_export_result_report(result_contracts)`
- `format_export_result_summary_as_markdown(summary)`

They do not call the export helpers, do not write files, and do not recompute path safety. The lower-level `write_*` helpers still keep their existing exception behavior. The `try_*` wrappers still keep their existing result contract behavior.

## Summary Helper

`build_export_result_summary(...)` accepts one export result contract dict and returns a JSON-ready summary dict. It translates raw fields such as `success`, `output_path`, `attempted_path`, `file_type`, `error_code`, `error_message`, and `overwritten` into a user-facing status and message.

The status values are intentionally limited:

- `success` for `success=True`
- `review` for `success=False`
- `unknown` when the input cannot be interpreted as a normal success/failure contract

No `blocked` status is produced.

## Report Helper

`build_export_result_report(...)` accepts a list or tuple of result contracts and produces an aggregate report. It preserves item order and counts successful, review, and unknown items.

Unsupported input is converted into a safe diagnostic item instead of raising. This keeps the helper useful for handover QC and admin/debug display without becoming hard validation.

## Markdown Formatter

`format_export_result_summary_as_markdown(...)` renders either a single summary or an aggregate report as Markdown text. It returns a string only. It does not create `.md` files and does not call `write_markdown_text_to_file(...)`.

## Test Coverage

Step 170 adds tests for:

- success summary output
- failure summary output
- unknown status handling
- missing optional fields
- mixed success/failure/unknown report lists
- unsupported input
- input immutability
- safe Markdown messages
- no file writing
- no `blocked` status

## Explicit Non-Scope

This step does not add backup/restore behavior, API, GUI, CLI, audit events, hard validation, repository/database writes, export output files, or a push/commit operation.
