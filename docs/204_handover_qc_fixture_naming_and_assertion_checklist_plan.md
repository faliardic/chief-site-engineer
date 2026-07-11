# Step 204 - Handover QC Fixture Naming and Assertion Checklist Plan

## Purpose

This step converts the Step 202 canonical handover QC presentation examples into a documentation-only fixture naming and assertion checklist plan.

The plan is for a future handover QC presentation view-model implementation. This step does not create executable fixture files, executable tests, production code, API behavior, GUI behavior, CLI behavior, persistence, audit behavior, export output, ZIP output, hard validation, or package decision logic.

It also fixes deterministic artifact-family names and future test-layer ownership/location without creating any fixture directory or executable file.

## Source of Truth

Future fixtures should be derived from the structured checklist dict produced by:

```text
build_export_handover_qc_review_checklist(summary, report)
```

Optional Markdown remains display-only text produced by:

```text
format_export_handover_qc_review_checklist_as_markdown(checklist)
```

Future consumers must not parse Markdown as structured truth. Markdown may be displayed as a preview only. It is an optional display regression artifact and never replaces the structured source checklist.

## Fixture Naming Standard

These names are reserved for future fixture or test-data implementation. They are not created as executable files in this step.

| `case_id` | `source_checklist_fixture_name` | `expected_view_model_fixture_name` | `expected_markdown_fixture_name` | `expected_review_visibility_fixture_name` | `primary_assertion_focus` |
| --- | --- | --- | --- | --- | --- |
| `success_only` | `handover_qc_source_checklist_success_only` | `handover_qc_expected_view_model_success_only` | `handover_qc_expected_markdown_success_only` | `handover_qc_expected_review_visibility_success_only` | Success visibility remains review-ready, not official approval |
| `failure_only` | `handover_qc_source_checklist_failure_only` | `handover_qc_expected_view_model_failure_only` | `handover_qc_expected_markdown_failure_only` | `handover_qc_expected_review_visibility_failure_only` | Human review is visible, not automatic rejection or blocking |
| `mixed` | `handover_qc_source_checklist_mixed` | `handover_qc_expected_view_model_mixed` | `handover_qc_expected_markdown_mixed` | `handover_qc_expected_review_visibility_mixed` | Mixed rows remain visible without package decision logic |
| `empty_zero_count` | `handover_qc_source_checklist_empty_zero_count` | `handover_qc_expected_view_model_empty_zero_count` | `handover_qc_expected_markdown_empty_zero_count` | `handover_qc_expected_review_visibility_empty_zero_count` | Empty-state wording is shown without hard validation |
| `missing_optional_fields` | `handover_qc_source_checklist_missing_optional_fields` | `handover_qc_expected_view_model_missing_optional_fields` | `handover_qc_expected_markdown_missing_optional_fields` | `handover_qc_expected_review_visibility_missing_optional_fields` | Missing optional fields use presentation fallback text |
| `unknown_status_additional_fields` | `handover_qc_source_checklist_unknown_status_additional_fields` | `handover_qc_expected_view_model_unknown_status_additional_fields` | `handover_qc_expected_markdown_unknown_status_additional_fields` | `handover_qc_expected_review_visibility_unknown_status_additional_fields` | Unknown status remains review visibility only |
| `unsupported_input_fallback` | `handover_qc_source_checklist_unsupported_input_fallback` | `handover_qc_expected_view_model_unsupported_input_fallback` | `handover_qc_expected_markdown_unsupported_input_fallback` | `handover_qc_expected_review_visibility_unsupported_input_fallback` | Safe fallback notice is shown without parsing Markdown |

## Future Fixture Metadata Shape

If a future step creates fixture files, each fixture should identify the documentation source and expected display contract with fields equivalent to:

```text
source_checklist_case
expected_view_model_case
required_assertions
forbidden_fields
transfer_boundary_assertions
side_effect_assertions
```

The metadata should remain descriptive. It must not introduce persistence, audit IDs, export writes, package decisions, or official approval/rejection state.

## Future Ownership and Location

Fixture data may be created only by a separate explicitly authorized future test-layer task. Its future location contract is:

```text
tests/fixtures/handover_qc/source_checklists/<case>.json
tests/fixtures/handover_qc/expected_view_models/<case>.json
tests/fixtures/handover_qc/expected_markdown/<case>.md
tests/fixtures/handover_qc/expected_review_visibility/<case>.json
```

Future fixture-contract tests may live only in:

```text
tests/test_handover_qc_view_model_fixtures.py
```

Ownership rules:

1. The future test layer owns fixture data under `tests/fixtures/handover_qc/`.
2. Production code must not import from `tests/fixtures/`.
3. This documentation is the specification source, not a runtime dependency.
4. Source checklist fixtures represent the structured checklist contract.
5. Expected view-model fixtures represent presentation mapping expectations only.
6. Expected Markdown fixtures are optional display regression artifacts only.
7. Expected review-visibility fixtures represent human-review visibility only.
8. Official handover fixtures must exclude private or non-transferable information.
9. Credentials, secrets, private field notes, local caches, and user-specific non-transferable information must not enter fixtures.
10. Fixtures are not persistence, audit, export-writing, or package-decision mechanisms.

Step 204 does not physically create `tests/fixtures/`, any JSON/Markdown fixture, or any test file.

## Assertion Checklist - All Future Fixtures

Every future fixture or test derived from this plan should assert:

- Structured source contract: the consumer reads the checklist dict from `build_export_handover_qc_review_checklist(summary, report)`.
- Optional Markdown boundary: `format_export_handover_qc_review_checklist_as_markdown(checklist)` output is display-only and not parsed as source truth.
- Status labels use the Step 202 wording:
  - `Ready for review`
  - `Needs human review`
  - `Review status unknown`
  - `Unknown status; treat as review visibility only`
- Human-review indicators use:
  - `Human review required`
  - `No review signal from checklist`
- Read-only and non-blocking notices use:
  - `Read-only QC visibility`
  - `Does not block package transfer`
- Empty items use:
  - `No checklist items are available for display. Review the source export summary/report before making a handover decision.`
- Missing optional fields use:
  - `Not available`
- Missing item next action uses:
  - `Review source export result before deciding next action`
- Unsupported input uses:
  - `Checklist unavailable; review the source export summary/report before making a handover decision.`
- `is_read_only=True` remains a presentation/QC visibility signal.
- `is_blocking=False` remains non-blocking.
- `requires_human_review` remains a human-review visibility signal only.
- Official transferable handover data remains separate from private/non-transferable information.
- Input objects are not mutated.
- Summary, report, or checklist results are not recomputed inside the presentation consumer.
- No file writing, export output, ZIP mutation, or `exports/` mutation occurs.
- No persistence, database/repository access, audit event, backup/restore, or migration behavior occurs.
- No API, GUI, or CLI behavior is implied by the fixture plan.
- No hard validation is added.
- No generated `blocked` status is added.
- No automatic acceptance, rejection, approval, official transfer decision, or package blocking is added.

## Forbidden Future View-Model Fields

Future tests should explicitly reject decision or side-effect fields such as:

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

If a future product requirement needs one of these fields, it must be handled in a separate explicit task with a separate design and test review.

## Case-Specific Assertion Notes

### `handover_qc_expected_view_model_success_only`

- Expected status label: `Ready for review`.
- Expected human-review indicator: `No review signal from checklist`.
- Must not mean official approval, acceptance, or transfer completion.
- Must still show read-only and non-blocking notices.

### `handover_qc_expected_view_model_failure_only`

- Expected status label: `Needs human review`.
- Expected human-review indicator: `Human review required`.
- Must not mean automatic rejection, hard validation, or package blocking.
- Item rows should expose the review reason and next-action hint for a human reviewer.

### `handover_qc_expected_view_model_mixed`

- Expected overall status label: `Needs human review`.
- Must show success and review item rows without collapsing them into a package decision.
- Must preserve item-level visibility for both completed and review-needed outputs.

### `handover_qc_expected_view_model_empty_zero_count`

- Expected fallback: `No checklist items are available for display. Review the source export summary/report before making a handover decision.`
- Must not create an error state, blocked state, or hard validation failure.

### `handover_qc_expected_view_model_missing_optional_fields`

- Expected missing optional field fallback: `Not available`.
- Expected missing next action fallback: `Review source export result before deciding next action`.
- Must not reject the checklist because optional display fields are absent.

### `handover_qc_expected_view_model_unknown_status_additional_fields`

- Expected unknown status label: `Unknown status; treat as review visibility only`.
- Additional fields may be preserved for display only where useful.
- Additional fields must not create package decisions, audit records, persistence state, or blocking behavior.

### `handover_qc_expected_view_model_unsupported_input_fallback`

- Expected fallback: `Checklist unavailable; review the source export summary/report before making a handover decision.`
- Must not parse Markdown to recover structured truth.
- Must not write files, mutate exports, create audit events, or decide official package state.

## Future Test Conversion Boundary

```text
A separate explicitly authorized future task may create canonical
fixture data and fixture-contract tests for the seven documented
handover QC cases.
```

That future task may create only the seven canonical source/expected fixture sets, test naming/location and schema/integrity, test expected view-model and review-visibility contracts, and verify that optional Markdown remains display-only. It may not add a presentation consumer, production behavior, API/GUI/CLI behavior, persistence, database/repository access, audit, export writing, package decisions, hard validation, generated `blocked`, or production feature expansion.

That future step should preserve this order:

1. Structured checklist source.
2. Presentation view-model derivation.
3. Optional Markdown preview display.
4. Human review outside the generated data.
5. Official transfer decision outside the view-model.

This Step 204 branch intentionally stops at documentation and state records.

## Local-First Evidence Required for This Step

Completion of this step requires the official local repository evidence recorded in `.cse/results/204_result.md` and `.cse/state/project_state.json`, including synchronized master SHA, verified content-correction SHA and divergence, changed files, pytest, diff check, protected path diff, physical local file presence, `exports/` status, ignored local-only file integrity, push result, and final working-tree status.
