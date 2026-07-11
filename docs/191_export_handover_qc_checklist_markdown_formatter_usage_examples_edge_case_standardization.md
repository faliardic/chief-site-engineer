# Step 191 - Export / Handover QC Checklist Markdown Formatter Usage, Examples, and Edge Case Standardization

This step documents the usage boundary for:

```python
format_export_handover_qc_review_checklist_as_markdown(checklist)
```

It is documentation-only. It does not change helper behavior, tests, exports, API, GUI, CLI, database/repository behavior, audit behavior, backup/restore behavior, commits, or push state.

## Purpose

The formatter converts the JSON-ready dict output from:

```python
build_export_handover_qc_review_checklist(summary, report)
```

into presentation-safe Markdown text for human review.

The formatter is a presentation helper. It makes the checklist easier to inspect, quote, paste into handover review notes, or read in admin/debug contexts.

## Input Contract

The expected input is the checklist dict returned by:

```python
build_export_handover_qc_review_checklist(...)
```

That checklist is normally built after:

```python
build_export_result_summary(...)
build_export_result_report(...)
```

The Markdown formatter should not parse raw export files, inspect repository state, or rebuild summary/report/checklist data from lower-level inputs.

## Output Contract

The output is a human-readable Markdown string.

The Markdown may show:

- checklist type
- checklist status
- summary counts
- `is_read_only`
- `is_blocking`
- `requires_human_review`
- review notes
- checklist items
- item path/message/status details when present
- error type, technical detail, and next action hints when present

The output is for reading and review. It is not a machine enforcement layer.

## Read-Only Boundary

The formatter does not:

- write files
- create export output
- write under `exports/`
- access database/repository state
- create audit events
- call backup/restore flows
- call migration flows
- add API, GUI, or CLI behavior

## Recompute Boundary

The formatter does not recompute:

- checklist result
- summary result
- report result
- path safety
- export success/failure
- handover acceptance/rejection state

It consumes the checklist it is given and renders that data as Markdown.

## Mutation Boundary

The formatter must not mutate the input checklist dict.

Callers can keep the checklist dict as the structured source of truth and treat the Markdown as a read-only presentation copy.

## Blocking Boundary

The formatter does not produce `blocked` status.

The formatter must not turn `is_blocking` into a decision mechanism.

The formatter must not turn `requires_human_review` into automatic approval, automatic rejection, automatic blocking, hard validation, or official handover package status.

`requires_human_review` is only a signal that a human should inspect the checklist.

## Helper Chain Position

The expected helper chain is:

```text
build_export_result_summary(...)
build_export_result_report(...)
build_export_handover_qc_review_checklist(...)
format_export_handover_qc_review_checklist_as_markdown(...)
```

Each layer has a separate responsibility:

- summary/report helpers interpret export result contracts
- checklist helper creates JSON-ready handover QC review structure
- Markdown formatter creates presentation-safe human-readable text
- file-writing helpers, if used elsewhere, remain separate and explicit

## Expected Usage Places

Appropriate usage examples:

- handover QC review note
- future export review screen presentation layer
- NotebookLM / human-readable summary
- debug/admin textual inspection
- manual review context where the structured checklist already exists

The formatter can make review material easier to read, but it should not become the official decision source.

## Places Not To Use This Formatter

Do not use the formatter for:

- hard validation
- automatic record rejection
- automatic handover approval
- automatic handover blocking
- migration
- backup/restore
- API behavior
- GUI behavior
- CLI behavior
- audit event creation
- direct export writing instead of a file export helper
- parsing Markdown back into structured data
- replacing `build_export_handover_qc_review_checklist(...)`

## Example Reading Standards

### Success Checklist

A success checklist means the current checklist data is readable as positive export/handover QC visibility.

It does not mean official handover acceptance.

### Failure Checklist

A failure checklist means review details should be visible to a human reviewer.

It does not mean automatic rejection, automatic blocking, hard validation failure, or generated `blocked` status.

### Mixed Checklist

A mixed checklist should show both success and review items.

Mixed visibility means the reviewer can inspect positive and attention-needed items together. It is not a package decision.

### Empty Checklist

An empty checklist should remain readable as limited/no-item visibility.

Empty output should not create new failure semantics or infer that an export is approved.

### Missing Field

Missing optional fields should use safe fallback wording such as `not available`.

Missing fields are presentation gaps unless a separate upstream helper explicitly defines them otherwise.

### Unknown Status

Unknown status values should remain visible as unknown/review-oriented presentation data.

Unknown status must not become hard validation, automatic blocking, or generated `blocked` status.

### Unsupported Input

Unsupported input should be presented with safe Markdown fallback behavior.

The formatter should avoid breaking a human review flow merely because the input shape is not the expected checklist dict.

## Documentation-Only Scope

Step 191 adds documentation and examples only.

It does not add:

- new helper
- test
- export file
- hard validation
- `blocked` status
- API/GUI/CLI behavior
- database/repository access
- audit event
- backup/restore behavior
- migration behavior
- commit
- push
