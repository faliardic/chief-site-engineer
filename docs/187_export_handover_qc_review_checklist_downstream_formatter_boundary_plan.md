# Step 187 - Export / Handover QC Review Checklist Downstream Formatter Boundary Plan

This step documents the downstream boundary for the JSON-ready output of:

```python
build_export_handover_qc_review_checklist(summary, report)
```

This is a documentation-only boundary plan.

It is not a downstream formatter implementation.

It is not an API, GUI, or CLI implementation.

It does not change code, tests, helper behavior, export output, database/repository behavior, audit behavior, backup/restore behavior, hard validation, or `blocked` status behavior.

## Downstream Boundary

The checklist helper output remains a JSON-ready dict.

That dict can be a future input for presentation or QC visibility consumers such as:

- Markdown checklist formatter
- handover QC review screen
- export review workflow
- GUI consumer
- API consumer
- CLI consumer

Those future consumers must treat the checklist as read-only visibility data.

They must not treat it as a decision authority.

They must not mutate the helper output.

They must not recompute export success or failure from presentation fields.

## Markdown Formatter Boundary

A future Markdown formatter may read the checklist dict and render it as presentation-safe text.

That formatter must remain separate from:

- export result building
- checklist building
- business approval
- business rejection
- blocking decisions
- hard validation
- audit event creation
- database/repository persistence
- backup/restore behavior
- export file writing

If a Markdown formatter is added, it must be a separate step with separate tests and documentation.

Step 187 does not add that formatter.

## Handover QC Screen Boundary

A future handover QC screen may show the checklist output to a human reviewer.

The screen may use:

- checklist status visibility
- summary counts
- item status/priority
- paths
- messages
- error type
- technical detail
- next action hints
- review notes
- `requires_human_review`

The screen must not convert those fields into automatic acceptance, rejection, or blocking.

Human review remains separate from the checklist output.

## Export Review Workflow Boundary

A future export review workflow may use the checklist for review visibility.

Success items are positive visibility, not official acceptance.

Failure or mixed items are review visibility, not automatic rejection.

`requires_human_review=True` means the checklist should be inspected by a person.

It does not mean the handover package is blocked.

`is_blocking=False` must be preserved by downstream consumers.

`is_read_only=True` must be preserved by downstream consumers.

## GUI/API/CLI Consumer Boundary

Future GUI/API/CLI consumers may use the checklist output only for presentation or QC visibility.

They must not add implicit behavior such as:

- automatic approval
- automatic rejection
- automatic blocking
- generated `blocked` status
- hard validation
- database/repository writes
- audit event creation
- backup/restore execution
- export file generation

If GUI, API, or CLI integration is needed, it must be planned, implemented, tested, and documented in a separate step.

Step 187 does not add any GUI, API, or CLI surface.

## Existing Helper Behavior

Downstream planning must preserve:

- `build_export_handover_qc_review_checklist(...)`
- `build_export_result_summary(...)`
- `build_export_result_report(...)`
- `format_export_result_report_as_markdown(...)`
- `format_export_result_summary_as_markdown(...)`
- `write_*`
- `try_write_*`

The checklist helper remains a consumer of existing summary/report outputs.

It does not replace builders, formatters, writers, or wrapper helpers.

## Deferred Hard Validation

Hard validation remains deferred.

Any future hard validation must be a separate controlled phase with its own plan, tests, documentation, and compatibility review.

The downstream checklist boundary must not quietly introduce hard validation through formatter, screen, workflow, GUI, API, or CLI code.

## Explicit Non-Scope

Step 187 does not add:

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
