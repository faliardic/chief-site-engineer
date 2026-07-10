# Step 177 - Export Result Report Formatter Test Example Standardization

This step strengthens the test/example standard for `format_export_result_report_as_markdown(report)` without expanding formatter behavior.

## Scope

The focus is test and documentation standardization.

The formatter remains:

- read-only
- presentation-only
- file-system side-effect free
- non-validating
- independent from API, GUI, CLI, database/repository, audit, backup, and restore behavior

`app/models.py` is not changed in this step.

## Added Test Standards

Step 177 adds stable examples for:

- success-only report Markdown
- failure-only report Markdown
- empty item list / zero count report Markdown
- missing optional fields and fallback text
- additional or raw fields staying outside the rendered presentation
- `build_export_result_report(...)` contract regression

The existing tests already covered mixed success/failure visibility, input immutability, string output, no file writing, no generated `blocked` status, no recomputation, and `format_export_result_summary_as_markdown(...)` regression. This step keeps those tests and adds more explicit examples around them.

## Success-only Example

The success-only example fixes the expected Markdown shape for one successful item:

- `Status: success`
- total count `1`
- success count `1`
- review count `0`
- unknown count `0`
- item path visibility
- output path and attempted path visibility
- overwrite visibility
- read-only notes

The formatter does not verify the current file system. It only renders the report dict.

## Failure-only Example

The failure-only example fixes the expected Markdown shape for one review item:

- `Status: review`
- success count `0`
- failure/review count `1`
- attempted path visibility
- error type visibility
- technical detail visibility
- next action visibility

This is a review presentation, not record rejection or hard validation.

## Empty Report Example

The empty report example fixes the expected Markdown shape for zero items and zero counts.

It shows that an empty report remains readable and does not become a hard validation failure or automatic block.

## Missing and Additional Fields

Missing optional fields use presentation fallback text such as `not available` or a generic item message.

Additional fields and raw contract fields that are not part of the report presentation remain unrendered. This protects the boundary that the formatter presents existing report fields; it does not rebuild or reinterpret raw result contracts.

## Regression Boundaries

The test standard preserves these behaviors:

- `format_export_result_report_as_markdown(...)` does not mutate input
- it does not write files
- it does not create export output
- it does not produce `blocked` status
- it does not recompute report results
- `build_export_result_report(...)` behavior remains unchanged
- `format_export_result_summary_as_markdown(...)` behavior remains unchanged
- `write_*` and `try_write_*` helper behavior remains unchanged

## Explicit Non-Scope

This step does not add export writers, export files, hard validation, generated `blocked` status, API, GUI, CLI, database/repository access, audit events, backup/restore behavior, commit, push, or ZIP/cache staging.
