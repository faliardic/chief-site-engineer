# Step 200 - Handover QC Downstream Presentation Consumer Contract and Test Matrix Plan

This step defines a documentation-only contract for a future handover QC screen or export review presentation consumer.

It does not implement a consumer. It does not add API, GUI, CLI, persistence, audit, backup/restore, migration, hard validation, file/export output, generated `blocked` status, or automatic package decision behavior.

## Source Boundary

The structured source of truth for a future consumer is the existing checklist dict returned by:

```text
build_export_handover_qc_review_checklist(summary, report)
```

That checklist is built from existing export result summary/report objects. A presentation consumer must not rebuild export results, recompute checklist status, or call lower-level export writing helpers.

The optional readable presentation artifact is the Markdown string returned by:

```text
format_export_handover_qc_review_checklist_as_markdown(checklist)
```

Markdown may be displayed when explicitly supplied or selected for review notes. Markdown is not the structured source of truth and should not be parsed back into checklist fields.

## Stable Input Contract

A future consumer should expect the checklist dict to contain these top-level fields:

- `checklist_type`
- `status`
- `summary`
- `items`
- `review_notes`
- `is_read_only`
- `is_blocking`
- `requires_human_review`

The summary block may expose:

- `status`
- `total_count`
- `success_count`
- `review_count`
- `unknown_count`
- `source_summary_status`
- `message`

Each item may expose:

- `status`
- `priority`
- `file_type`
- `path`
- `message`
- `error_type`
- `technical_detail`
- `next_action_hint`
- `overwritten`

These fields support presentation and human review. They are not validation, official acceptance, official rejection, package blocking, persistence, or audit fields.

## Future View-Model Contract

A future presentation consumer may normalize the checklist into a view-model shaped for display.

That view-model should stay narrow:

```text
handover_qc_presentation_view_model
```

Expected display sections:

- heading/title for the handover QC review checklist
- status visibility label
- read-only/non-blocking metadata
- human-review indicator
- summary count rows
- ordered checklist item rows
- review notes
- optional Markdown preview or copied review text
- transfer boundary notice
- fallback/display warning when input is incomplete or unsupported

The future view-model must not include decision fields such as:

- `approved`
- `rejected`
- `blocked`
- `official_decision`
- `audit_event_id`
- `persisted_at`
- `export_written`
- `package_transfer_authorized`

Those concepts belong to separate explicit future layers, if they are ever added.

## Required Fields

For a future view-model plan, these fields are required because they define the minimum safe display contract:

- `checklist_type`
- `status`
- `summary`
- `items`
- `review_notes`
- `is_read_only`
- `is_blocking`
- `requires_human_review`

When a required field is missing, the future consumer should use a visible fallback instead of throwing a hidden decision error:

- missing `status` becomes `unknown` visibility
- missing `summary` becomes an empty summary display
- missing `items` becomes an empty item list
- missing `review_notes` becomes an empty notes list
- missing `is_read_only` defaults to read-only display
- missing `is_blocking` defaults to non-blocking display
- missing `requires_human_review` defaults to review-needed when status is not `success`

These fallbacks are display behavior only. They are not hard validation and do not reject the handover package.

## Optional Fields

Optional fields may improve presentation but must not become hidden business rules:

- item `path`
- item `file_type`
- item `message`
- item `error_type`
- item `technical_detail`
- item `next_action_hint`
- item `overwritten`
- optional Markdown preview
- optional admin/debug technical detail grouping
- optional display tone or icon derived from status

Unknown/additional fields should be ignored for decision purposes. A future consumer may expose them only in a clearly bounded debug/admin view after a separate contract says so.

## Fallback Display Behavior

Fallback behavior should keep the review flow readable and safe:

- unsupported input renders `unknown` visibility
- empty or zero-count input renders an empty item state
- missing text fields render `not available` or equivalent display text
- unknown statuses render as `unknown` or review visibility, never `blocked`
- missing optional item fields do not hide the item
- malformed item rows render a safe unsupported-item display row
- fallback display sets or preserves human-review visibility

Fallbacks must not:

- recompute export results
- mutate input
- write files
- create exports
- persist state
- create audit records
- hard-fail the package
- generate `blocked`
- accept, reject, approve, or block automatically

## Status Visibility

Status is a display signal.

Recommended interpretation:

- `success`: positive visibility, not official acceptance
- `review`: human-review visibility, not automatic rejection
- `unknown`: limited visibility, not hard validation failure

The future consumer may use color, icon, or label choices for readability, but those choices must not imply official package decision authority.

## Item Visibility

Checklist items should remain ordered as provided by the checklist helper.

The presentation consumer may display:

- status
- priority
- file type
- path
- message
- error type
- technical detail
- next action hint
- overwrite visibility

The consumer must not use item visibility to write export output, repair files, mutate paths, retry writes, persist decisions, or create audit records.

## Review Notes

`review_notes` are explanatory human-review copy.

They should be displayed as review context, not as binding policy. They do not authorize package acceptance, package rejection, export writing, audit creation, persistence, or hard validation.

## Human-Review Indicator

`requires_human_review` is only a human-review signal.

When true, a future consumer may show a review-needed badge, warning label, or review queue marker.

When false, a future consumer may show positive visibility, but must not imply official handover acceptance.

The stable non-blocking meaning remains:

```text
is_read_only=True
is_blocking=False
requires_human_review=<human review signal only>
```

No generated `blocked` status is allowed.

## Layer Separation

These layers remain separate:

- report building
- checklist building
- Markdown formatting
- presentation consumption
- human review
- validation
- persistence
- audit
- export writing

The future presentation consumer may only sit in the presentation consumption layer. It must not collapse validation, audit, persistence, export writing, or official handover decision behavior into display code.

## Official Transfer Boundary

Official transferable handover data may include:

- approved project documentation
- structured export result summary/report data
- handover QC checklist dict selected for review
- presentation Markdown explicitly selected for review notes
- explicit export package output from a separate export-writing flow

Private or non-transferable information must remain excluded:

- private workspace notes
- user-specific context
- credentials and secrets
- local cache files
- non-transferable personal information
- informal notes not approved for official transfer

The consumer contract should keep this boundary visible and should not copy private/non-transferable data into official handover output.

## Future Regression/Test Matrix

A future implementation step should cover these cases before any consumer is introduced:

- success-only checklist input
- failure-only checklist input
- mixed success/review checklist input
- empty or zero-count checklist input
- missing required top-level fields
- missing optional summary or item fields
- unknown/additional top-level fields
- unknown/additional item fields
- unknown status values
- unsupported input type
- input immutability
- no report recomputation
- no checklist recomputation
- no Markdown parsing as source of truth
- no file writing
- no export output
- no `exports/` mutation
- no persistence side effect
- no audit side effect
- no backup/restore side effect
- no migration side effect
- no hard validation
- no generated `blocked` status
- no automatic acceptance
- no automatic rejection
- no automatic approval
- no package blocking
- private/non-transferable information exclusion
- official-transferable data remains explicit and bounded
- protected helper behavior remains unchanged

The future tests should assert that presentation behavior does not change `build_export_handover_qc_review_checklist(...)` or `format_export_handover_qc_review_checklist_as_markdown(...)`.

## Recommended Next Technical Step

The next narrow technical step should remain documentation-only:

```text
Define canonical future view-model examples and display wording for success, review, mixed, empty, missing-field, and unsupported handover QC presentation cases.
```

That step should not implement API, GUI, CLI, persistence, audit, backup/restore, migration, hard validation, generated `blocked` status, export output, or official package decision behavior.

## Podcast Follow-Up

The Step 196-200 NotebookLM podcast note is recorded as the next documentation follow-up after Step 200 is merged.

This step does not create that podcast note.

## Completion Boundary

Step 200 defines the consumer contract and future test matrix only.

It preserves existing helper behavior and keeps PR #16 as a draft review item until explicit review and merge approval.
