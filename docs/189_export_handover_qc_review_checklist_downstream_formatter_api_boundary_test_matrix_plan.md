# Step 189 - Export / Handover QC Review Checklist Downstream Formatter API Boundary and Test Matrix Plan

This step defines the API boundary and future test matrix for a possible downstream formatter for:

```python
build_export_handover_qc_review_checklist(summary, report)
```

This is documentation-only.

It is not a formatter implementation.

It does not change code, tests, helper behavior, export output, database/repository behavior, audit behavior, backup/restore behavior, hard validation, or `blocked` status behavior.

## Future Formatter Purpose

A future formatter may convert an export / handover QC review checklist dict into presentation-safe Markdown or string output.

The formatter would help human reviewers read the checklist in handover QC, export review, or downstream presentation surfaces.

The formatter would not be a decision engine.

It would not approve, reject, block, validate, persist, audit, or export anything.

## Possible API

A possible future helper name is:

```python
format_export_handover_qc_review_checklist_as_markdown(checklist)
```

The name is a planning example only.

No helper is implemented in Step 189.

## Input Contract

The future formatter should accept the JSON-ready checklist dict produced by:

```python
build_export_handover_qc_review_checklist(summary, report)
```

The formatter should not use raw writer result contracts as its primary input.

The formatter should not parse existing Markdown as source of truth.

The formatter should not recompute summary/report/checklist results.

The formatter should not mutate the input checklist dict.

Unsupported input should be handled as safe presentation fallback if implemented later. It should not become hard validation, package rejection, automatic blocking, an exception-driven workflow gate, or generated `blocked` status unless a future separate step explicitly changes that boundary.

## Output Contract

The future formatter should return a string.

The string should be presentation-safe Markdown or plain presentation text.

The output should be readable by a human reviewer and should show:

- checklist type
- checklist status
- summary counts
- `is_read_only=True`
- `is_blocking=False`
- `requires_human_review`
- review notes
- checklist item list
- paths where available
- messages where available
- error types where available
- technical details where available
- next action hints where available

The output must not be interpreted as hard validation.

The output must not create automatic acceptance, approval, rejection, or blocking.

## Read-Only Boundary

The future formatter should not:

- write files
- create export output
- write under `exports/`
- call `write_*` helpers
- call `try_write_*` wrappers
- access database/repository state
- create audit events
- run backup/restore
- add API/GUI/CLI behavior
- mutate input
- recompute checklist results
- recompute summary/report results
- perform hard validation
- generate `blocked` status

## Existing Helper Preservation

The future formatter must not change behavior of:

- `build_export_handover_qc_review_checklist(...)`
- `build_export_result_summary(...)`
- `build_export_result_report(...)`
- `format_export_result_report_as_markdown(...)`
- `format_export_result_summary_as_markdown(...)`
- `write_*`
- `try_write_*`

The formatter would be a presentation consumer of checklist output.

It would not replace checklist, summary, report, existing formatter, writer, or wrapper helpers.

## Field Presentation Boundary

`is_read_only=True` should be visible in the formatted output as a read-only presentation/QC visibility signal.

`is_blocking=False` should be visible in the formatted output as a non-blocking signal.

`requires_human_review` should be presented as review visibility, not as automatic blocking.

`review_notes` should be presented as explanatory notes, not official approval, rejection, audit evidence, or workflow state.

Checklist items should be presented for human review.

They should not become automatic official acceptance, rejection, or blocking decisions.

## Edge Case Presentation Plan

Success-only checklist output should show success visibility while avoiding official acceptance language.

Failure-only checklist output should show review visibility, error details, and next action hints where available while avoiding automatic rejection or blocking language.

Mixed checklist output should show both success and review items while avoiding package-level automatic blocking.

Empty / zero-count checklist output should show limited or unknown visibility and should not imply successful completion.

Missing optional field output should use safe fallback text and should not create new validation rules.

Unknown/additional field output should remain within the presentation boundary and should not turn unknown fields into business rules, audit records, persistence, or export behavior.

Unsupported input output should remain safe and readable if a future formatter supports it. It should not produce hard validation, generated `blocked` status, export output, or implicit workflow decisions.

## Future Test Matrix

If the formatter is implemented later, at minimum it should be tested for:

- success-only checklist converts to Markdown/string
- failure-only checklist converts to Markdown/string
- mixed checklist converts to Markdown/string
- empty / zero-count checklist converts to Markdown/string
- missing optional fields display safely
- unknown/additional fields stay inside presentation boundary
- unsupported input uses safe presentation fallback
- output type is `str`
- output includes checklist type
- output includes `is_read_only` visibility
- output includes `is_blocking=False` visibility
- `requires_human_review` is not presented as blocking
- `review_notes` remain explanatory
- checklist items are readable
- input checklist dict is not mutated
- formatter writes no files
- formatter creates no export output
- formatter leaves `exports/` empty
- formatter generates no `blocked` status
- no hard validation regression is introduced
- `build_export_handover_qc_review_checklist(...)` behavior is preserved
- `build_export_result_summary(...)` behavior is preserved
- `build_export_result_report(...)` behavior is preserved
- `format_export_result_report_as_markdown(...)` behavior is preserved
- `format_export_result_summary_as_markdown(...)` behavior is preserved
- `write_*` behavior is preserved
- `try_write_*` behavior is preserved

## Downstream Consumer Boundary

Future GUI/API/CLI consumers may use a checklist formatter only as a presentation layer.

They must not treat the formatted output as:

- official acceptance
- official rejection
- package blocking
- hard validation
- generated `blocked` status
- database/repository state
- audit event source
- backup/restore trigger
- export writer

GUI/API/CLI integration remains out of scope for Step 189.

Any such integration must be a separate step with separate tests and documentation.

## Deferred Hard Validation

Hard validation remains deferred.

If hard validation is added later, it must be handled in a separate controlled phase with a separate plan, tests, documentation, and compatibility review.

The formatter boundary must not quietly introduce validation behavior.

## Explicit Non-Scope

Step 189 does not add:

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
