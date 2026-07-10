# Step 171 - Export Result Summary/Report Helper Usage Documentation

This step documents how to use the Step 170 export result summary/report helpers. It is documentation-only.

## Helper Purpose

The helper layer interprets existing export wrapper result contracts:

- `build_export_result_summary(...)` creates a readable summary for one export result contract.
- `build_export_result_report(...)` creates an aggregate report for multiple result contracts.
- `format_export_result_summary_as_markdown(...)` converts a summary or report dict into readable Markdown text.

These helpers are read-only interpretation helpers. They make wrapper results easier to show in handover QC notes, admin/debug review, podcast notes, or other documentation-oriented layers.

## Usage Boundary

These helpers do not:

- write files
- call export helpers
- recompute path safety decisions
- mutate wrapper result contracts
- replace the low-level `write_*` helpers
- perform hard validation
- produce a `blocked` status

The low-level `write_json_ready_dict_to_file(...)` and `write_markdown_text_to_file(...)` helpers remain the file-writing boundary. The `try_write_json_ready_dict_to_file(...)` and `try_write_markdown_text_to_file(...)` wrappers remain the result-contract boundary. The Step 170 helpers sit above those wrappers and only interpret their results.

## Example Usage Scenarios

### Single Successful Export

A successful wrapper result can be passed to `build_export_result_summary(...)` so the upper layer can show that an export was produced. The summary keeps the path visible as text and returns a success-oriented user message.

This does not write another file and does not verify the path again. It only reports what the wrapper result already says.

### Single Failure Result

A failure wrapper result can be passed to `build_export_result_summary(...)` to create a safe user-facing message. For example, `file_exists`, `parent_missing`, `wrong_extension`, or `outside_allowed_root` can be translated into a short review message while preserving technical detail for admin/debug review.

The failure summary means the export result needs review. It does not mean the underlying records are invalid.

### Multiple Export Results

Several wrapper results can be passed to `build_export_result_report(...)`. The report keeps item order and counts success, review, and unknown items.

This is useful when one handover process may attempt both JSON and Markdown outputs, or when a future upper layer wants to summarize several export attempts together.

### Handover QC Review

In handover QC, a success result can make the produced export visible. A failure result can be shown as review/attention information so the reviewer knows why an export was not written.

Failure does not automatically block the handover package, does not invalidate records, and does not create hard validation.

### Admin/Debug Review

Admin/debug views can preserve `error_type` and `technical_detail` while keeping `safe_for_user_message` short and readable. This keeps a clean split between user-facing explanation and technical troubleshooting detail.

### Markdown Upper Layers

`format_export_result_summary_as_markdown(...)` returns Markdown text that can be included in a report, handover note, podcast preparation note, or other upper-layer documentation. It returns text only and does not create `.md` export output files.

## Integration Boundary

This step does not add API, GUI, or CLI integration. It does not build a backup/restore system. It does not create audit events. It does not add database or repository behavior. It does not produce export output files. Existing helper behavior remains unchanged.

## Next Possible Step

A possible next step is:

- Step 172 - Export result summary/report helper edge case standardization

Another possible next action is:

- Podcast 028 scope review

Neither Step 172 nor Podcast 028 is started in this step.
