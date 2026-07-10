# Step 178 - Export Result Report Formatter Handover QC Usage Plan

This step plans how `format_export_result_report_as_markdown(report)` should be used in handover quality control. It is documentation-only.

## Role in Handover QC

`format_export_result_report_as_markdown(report)` converts an existing export result report dict into a readable Markdown view.

In handover QC, this output can help the outgoing site team, incoming site chief, and review owner see export result visibility in a compact form.

The formatter is not the decision authority. It does not approve a handover package and does not block a handover package.

## Input and Output

The expected input is the dict output of:

```python
build_export_result_report(...)
```

The output is a presentation-safe Markdown string.

The formatter:

- provides visibility and readability
- does not recompute export results
- does not recompute summary/report data
- does not write files
- does not create export output files
- does not create audit events
- does not produce `blocked` status
- is not hard validation

## Reading Success Reports

A success-only report should be read as export visibility.

It can show:

- overall success status
- total count
- success count
- item paths
- output and attempted paths when present

Success visibility does not replace official acceptance. The handover owner should still confirm that the correct files, scope, and package checklist are complete outside this formatter.

## Reading Failure Reports

A failure-only report should be read as a review queue.

It can show:

- review status
- failure/review count
- attempted paths
- error types
- technical details
- next action hints

Failure visibility does not automatically block the handover package. It tells reviewers what needs human attention before the package can be considered ready.

## Reading Mixed Reports

A mixed report should preserve both successful and review-needed items.

The reviewer should:

- keep successful item visibility
- inspect failed or review-needed items
- compare counts against the expected export checklist
- decide whether follow-up is needed outside the formatter

The formatter should not collapse mixed results into a single approval or rejection decision.

## Empty, Unknown, or Missing Fields

Empty item lists, unknown statuses, and missing optional fields should be treated as incomplete visibility, not hard validation failure.

The formatter may show fallback text. The handover reviewer should use that fallback as a cue to inspect the upstream report creation flow or export checklist.

The formatter should not infer missing export success, missing failure, or missing official approval.

## Export Review Checklist Placement

The Markdown output can sit in an export review checklist after the export result report is built and before any final package acceptance note is written.

Recommended checklist position:

- confirm export scope
- build export result report
- render report Markdown with `format_export_result_report_as_markdown(...)`
- review success/failure/mixed visibility
- record human follow-up decisions outside the formatter
- only then continue to package acceptance or remediation workflow

## Incoming Site Chief Visibility

For a new site chief, the formatter output can provide quick visibility into what export attempts succeeded, what needs review, and which paths or details require attention.

It should be shared as a readable status view, not as the legal or procedural proof that the handover package is complete.

## Private Area and Official Handover Separation

The outgoing site chief's private working area must remain separate from the official export/handover package.

Formatter output should describe only the report dict it receives. It should not pull data from private folders, personal notes, cache files, backup areas, or other non-export locations.

Official package contents should be selected and approved by the handover process, not by this formatter.

## Future UI or Integration Use

Future GUI, API, or CLI surfaces may show the formatter output as a presentation layer.

They should not treat this formatter as:

- hard validation
- automatic approval
- automatic blocking
- audit event creation
- export generation
- database/repository persistence
- backup/restore logic

If hard validation is needed later, it should be designed as a separate, explicit, and more controlled layer.

## Explicit Non-Scope

This step does not change code or tests.

It does not add a new helper, change formatter behavior, change `build_export_result_report(...)`, change `format_export_result_summary_as_markdown(...)`, change `write_*` or `try_write_*` helpers, write export files, leave files under `exports/`, add hard validation, add `blocked` status, add API/GUI/CLI behavior, access database/repository state, create audit events, add backup/restore behavior, commit, or push.
