# Step 179 - Export Result Report Formatter Downstream Integration Boundary Plan

This step documents the downstream integration boundary for `format_export_result_report_as_markdown(report)`. It is documentation-only.

## Boundary Definition

`format_export_result_report_as_markdown(report)` is a presentation-layer helper.

It accepts an existing export result report dict and returns readable Markdown text. Downstream consumers may use that Markdown for display, handover QC review, export review notes, or operator-facing summaries.

This step does not add GUI, API, CLI, handover QC screen, export review workflow, or any other integration.

## What Downstream Consumers May Do Later

Future GUI, API, or CLI work may use the formatter output as a read-only display value.

Possible future uses include:

- showing export report Markdown in a handover QC screen
- including the Markdown in an export review checklist view
- rendering the Markdown in an operator-facing CLI summary
- returning a formatted read-only presentation in an API response

Each future integration must be implemented in a separate step with its own tests and documentation.

## What Downstream Consumers Must Not Do

Downstream consumers must not treat this formatter as:

- an export writer
- a raw export helper
- a database/repository operation
- an audit event producer
- a backup/restore operation
- a hard validation gate
- an automatic approval mechanism
- an automatic blocking mechanism
- a source of `blocked` status

The formatter should not be connected to data mutation, file writing, export generation, or automatic business decisions.

## Handover QC Screen Boundary

A future handover QC screen may display the formatter output after `build_export_result_report(...)` has already produced a report dict.

The screen may help a reviewer see:

- success item visibility
- failure/review item visibility
- mixed result visibility
- paths and attempted paths
- error types and technical details

The screen should not convert formatter output into automatic package approval or automatic package blocking.

## Export Review Checklist Boundary

In a future export review checklist, the formatter output may appear after the report is built and before a human reviewer records a decision.

The checklist should keep these responsibilities separate:

- report builders create report data
- the formatter renders report data
- reviewers make review decisions
- validation layers, if added later, validate explicitly
- writers write files only through explicit writer helpers

The formatter must remain a view over the existing report dict contract.

## Report Dict Contract

Downstream consumers should depend on the existing report dict contract produced by `build_export_result_report(...)`.

They should not pass raw export writer inputs and expect the formatter to build or repair a report.

They should not expect the formatter to recompute counts, infer missing outcomes, run path safety, or normalize business decisions.

Unknown, missing, or additional fields should remain presentation-layer concerns unless a future explicit validation layer is designed.

## Success and Failure Visibility

Success visibility means the report says an item succeeded. It does not mean official package acceptance.

Failure or review visibility means the report says an item needs attention. It does not mean automatic blocking.

Mixed visibility means the downstream view should show both successful and review-needed items without collapsing them into one approval or rejection decision.

## Presentation and Decision Layer Separation

The formatter belongs to the presentation layer.

Business decision, validation, audit, persistence, and export-writing layers must stay separate.

If hard validation is needed later, it should be designed as a separate controlled layer with:

- explicit input and output contracts
- separate tests
- separate documentation
- clear review/approval rules
- no hidden dependency on formatter text

## Explicit Non-Scope

This step does not change code or tests.

It does not add a new helper, GUI, API endpoint, CLI command, database/repository access, audit event, backup/restore behavior, export output file, hard validation, `blocked` status, file writing, or downstream integration.

It does not change `format_export_result_report_as_markdown(...)`, `build_export_result_report(...)`, `format_export_result_summary_as_markdown(...)`, `write_*`, or `try_write_*` behavior.

It does not commit or push.
