# Step 202 - Handover QC Canonical View-Model Examples and Wording Standardization

## Purpose

This step standardizes documentation-only examples and wording for a future handover QC presentation view-model. The structured output of `build_export_handover_qc_review_checklist(summary, report)` remains the canonical source of truth.

`format_export_handover_qc_review_checklist_as_markdown(checklist)` remains optional presentation text. Future consumers may display it as a preview, but must not parse Markdown as structured truth.

This step does not implement a screen, API, CLI, GUI, persistence layer, audit layer, hard validation, export mutation, ZIP mutation, or package decision logic.

## Canonical Source Boundary

Future presentation consumers should read the checklist dict as the stable source:

```text
build_export_handover_qc_review_checklist(summary, report)
```

The future view-model may expose display fields such as:

```text
handover_qc_presentation_view_model
- title
- status_label
- status_tone
- human_review_indicator
- read_only_notice
- non_blocking_notice
- summary_rows
- item_rows
- review_notes
- transfer_boundary_notice
- optional_markdown_preview
- fallback_notice
```

The future view-model must not add decision fields such as:

```text
approved
rejected
blocked
official_decision
package_blocked
audit_event_id
persisted_at
export_written
```

## Standard Wording

Status labels:

- `success`: `Ready for review`
- `review`: `Needs human review`
- `unknown`: `Review status unknown`
- any unrecognized status: `Unknown status; treat as review visibility only`

Human-review indicators:

- `requires_human_review=True`: `Human review required`
- `requires_human_review=False`: `No review signal from checklist`

Read-only and non-blocking notices:

- `Read-only QC visibility`
- `Does not block package transfer`

Fallback text:

- Empty items: `No checklist items are available for display. Review the source export summary/report before making a handover decision.`
- Missing optional field: `Not available`
- Missing item next action: `Review source export result before deciding next action`
- Unsupported input: `Checklist unavailable; review the source export summary/report before making a handover decision.`

These phrases are presentation wording only. `No review signal from checklist` does not mean official acceptance. `Human review required` does not mean automatic rejection, hard validation, or package blocking.

## Transfer Boundary Required in Every Example

Every future presentation example must preserve the separation below.

Official transferable handover data:

- approved project documentation
- structured export result summary
- structured export result report
- handover QC checklist
- explicitly selected presentation Markdown
- explicit export package from a separate export-writing flow

Private or non-transferable data excluded from handover:

- private workspace notes
- user-specific context
- credentials or secrets
- local cache files
- non-transferable personal information
- informal notes not approved for official transfer

## Example 1 - Success-Only Checklist

Canonical structured source excerpt:

```python
{
    "checklist_type": "export_handover_qc_review",
    "status": "success",
    "summary": {
        "status": "success",
        "total_count": 1,
        "success_count": 1,
        "review_count": 0,
        "unknown_count": 0,
        "message": "1 export result ready for handover QC review.",
    },
    "items": [
        {
            "status": "success",
            "path": "example/handover_summary.json",
            "message": "Export result is readable.",
            "next_action": "Confirm this item during human handover review.",
        }
    ],
    "review_notes": [
        "Checklist is read-only and does not approve or reject a handover package."
    ],
    "is_read_only": True,
    "is_blocking": False,
    "requires_human_review": False,
}
```

Canonical future view-model excerpt:

```python
{
    "title": "Handover QC Review",
    "status_label": "Ready for review",
    "status_tone": "success",
    "human_review_indicator": "No review signal from checklist",
    "read_only_notice": "Read-only QC visibility",
    "non_blocking_notice": "Does not block package transfer",
    "decision_notice": "Visibility only; not official acceptance.",
    "transfer_boundary_notice": "Official transferable handover data remains separate from private/non-transferable information.",
}
```

Official-transferable data is limited to the structured summary/report/checklist and explicitly selected presentation output. Private notes, secrets, local cache, and user-specific context remain excluded.

## Example 2 - Failure-Only Checklist

Canonical structured source excerpt:

```python
{
    "status": "review",
    "summary": {
        "total_count": 1,
        "success_count": 0,
        "review_count": 1,
        "unknown_count": 0,
    },
    "items": [
        {
            "status": "review",
            "path": "example/handover_summary.json",
            "error_type": "parent_missing",
            "message": "Parent export directory is missing.",
            "next_action": "Review the export target path before handover.",
        }
    ],
    "is_read_only": True,
    "is_blocking": False,
    "requires_human_review": True,
}
```

Canonical future view-model excerpt:

```python
{
    "status_label": "Needs human review",
    "status_tone": "review",
    "human_review_indicator": "Human review required",
    "non_blocking_notice": "Does not block package transfer",
    "item_rows": [
        {
            "status_label": "Needs human review",
            "path": "example/handover_summary.json",
            "next_action": "Review the export target path before handover.",
        }
    ],
}
```

This view is not an automatic rejection or package block. Official handover material and private/non-transferable information remain separated.

## Example 3 - Mixed Checklist

Canonical structured source excerpt:

```python
{
    "status": "review",
    "summary": {
        "total_count": 2,
        "success_count": 1,
        "review_count": 1,
        "unknown_count": 0,
    },
    "items": [
        {
            "status": "success",
            "path": "example/approved_documents.json",
            "message": "Export result is readable.",
            "next_action": "Confirm this item during human handover review.",
        },
        {
            "status": "review",
            "path": "example/private_notes.json",
            "message": "Item requires review before any official transfer decision.",
            "next_action": "Verify that private information is excluded from the official package.",
        },
    ],
    "is_read_only": True,
    "is_blocking": False,
    "requires_human_review": True,
}
```

Canonical future view-model excerpt:

```python
{
    "status_label": "Needs human review",
    "human_review_indicator": "Human review required",
    "summary_rows": [
        {"label": "Total", "value": 2},
        {"label": "Ready", "value": 1},
        {"label": "Needs review", "value": 1},
    ],
    "decision_notice": "Mixed visibility is not a package decision.",
}
```

The example path names are illustrative display values only. They do not create export files and do not authorize private material for transfer.

## Example 4 - Empty or Zero-Count Checklist

Canonical structured source excerpt:

```python
{
    "status": "unknown",
    "summary": {
        "total_count": 0,
        "success_count": 0,
        "review_count": 0,
        "unknown_count": 0,
    },
    "items": [],
    "is_read_only": True,
    "is_blocking": False,
    "requires_human_review": True,
}
```

Canonical future view-model excerpt:

```python
{
    "status_label": "Review status unknown",
    "status_tone": "unknown",
    "human_review_indicator": "Human review required",
    "empty_state": "No checklist items are available for display. Review the source export summary/report before making a handover decision.",
    "non_blocking_notice": "Does not block package transfer",
}
```

Empty display is visibility for human review only. It is not hard validation and does not generate `blocked`.

## Example 5 - Missing Optional Fields

Canonical structured source excerpt:

```python
{
    "status": "review",
    "items": [
        {
            "status": "review",
            "message": "Optional display fields were not provided.",
        }
    ],
    "is_read_only": True,
    "is_blocking": False,
    "requires_human_review": True,
}
```

Canonical future view-model excerpt:

```python
{
    "status_label": "Needs human review",
    "item_rows": [
        {
            "status_label": "Needs human review",
            "path": "Not available",
            "error_type": "Not available",
            "technical_detail": "Not available",
            "next_action": "Review source export result before deciding next action",
        }
    ],
}
```

Missing optional fields use display fallbacks. They do not become rejection, approval, package blocking, persistence, audit, or migration behavior.

## Example 6 - Unknown Status and Additional Fields

Canonical structured source excerpt:

```python
{
    "status": "delayed",
    "summary": {
        "total_count": 1,
        "success_count": 0,
        "review_count": 0,
        "unknown_count": 1,
    },
    "items": [
        {
            "status": "delayed",
            "path": "example/handover_summary.json",
            "extra_debug_field": "ignored for package decisions",
        }
    ],
    "is_read_only": True,
    "is_blocking": False,
    "requires_human_review": True,
    "additional_context": "presentation consumers may ignore this",
}
```

Canonical future view-model excerpt:

```python
{
    "status_label": "Unknown status; treat as review visibility only",
    "status_tone": "unknown",
    "human_review_indicator": "Human review required",
    "item_rows": [
        {
            "status_label": "Unknown status; treat as review visibility only",
            "path": "example/handover_summary.json",
            "next_action": "Review source export result before deciding next action",
        }
    ],
}
```

Unknown or additional fields remain visible only where useful. They must not be converted into automatic package approval, rejection, blocking, or hard validation.

## Example 7 - Unsupported Input Fallback

Canonical structured source condition:

```python
"not-a-checklist-dict"
```

Canonical future view-model excerpt:

```python
{
    "status_label": "Review status unknown",
    "status_tone": "unknown",
    "human_review_indicator": "Human review required",
    "fallback_notice": "Checklist unavailable; review the source export summary/report before making a handover decision.",
    "item_rows": [],
    "read_only_notice": "Read-only QC visibility",
    "non_blocking_notice": "Does not block package transfer",
}
```

Unsupported input fallback is safe presentation behavior. It does not parse Markdown, mutate exports, write files, generate audit events, or decide the official package state.

## Regression Expectations

Future implementation or tests that use these examples should protect:

- stable wording for status labels, human-review indicators, empty states, missing-field fallbacks, unknown-status visibility, and item-level next-action hints
- `build_export_handover_qc_review_checklist(summary, report)` as structured source of truth
- optional Markdown output as display-only text, not structured truth
- input immutability
- no recomputation of summary, report, or checklist results inside presentation consumers
- no file writing, export output, ZIP mutation, or `exports/` mutation
- no persistence, audit event, backup/restore, migration, API, GUI, or CLI behavior
- no hard validation
- no generated `blocked` status
- no automatic acceptance, rejection, approval, official transfer decision, or package blocking
- `is_read_only=True`, `is_blocking=False`, and `requires_human_review` as human-review visibility semantics only
- official transferable handover data kept separate from private/non-transferable information in every example

## Next Narrow Technical Step

After this documentation-only step is merged, the next narrow technical step should be a documentation-only fixture naming and assertion checklist for a future handover QC presentation view-model implementation. That future step should still avoid implementing API, GUI, CLI, persistence, audit, export writing, hard validation, or package decision logic.
