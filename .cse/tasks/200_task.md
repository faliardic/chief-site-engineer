# Step 200 - Handover QC Downstream Presentation Consumer Contract and Test Matrix Plan

## Objective

Define a documentation-only downstream presentation consumer contract and future regression/test matrix for handover QC screen and export review flow consumers, without implementing any consumer, API, GUI, CLI, persistence, or decision logic.

## Repository Context

- Repository: `faliardic/chief-site-engineer`
- Issue: #15
- Pull request: #16, to be created as draft
- Base branch: `master`
- Expected base commit: `9a7c2cb116932eb909f2a2025a3afed8c7c8681e`
- Working branch: `step-200-downstream-consumer-contract-plan`

## Reasoning Level

- Codex: Extra High
- ChatGPT review: Extra High

## Authorized Changes

- `docs/200_handover_qc_downstream_presentation_consumer_contract_test_matrix_plan.md`
- `learning/200_handover_qc_downstream_presentation_consumer_contract_test_matrix_plan.md`
- `ROADMAP.md`
- `CHANGELOG.md`
- `docs/project_decisions.md`
- `.cse/results/200_result.md`
- `.cse/state/project_state.json`
- directly required documentation only

## Required Work

1. Define the downstream presentation consumer input boundary around the existing outputs of:
   - `build_export_handover_qc_review_checklist(summary, report)`
   - `format_export_handover_qc_review_checklist_as_markdown(checklist)`
2. Specify a future presentation consumer/view-model contract without implementing it.
3. Separate required fields, optional fields, fallback display behavior, status visibility, item visibility, review notes, and human-review indicators.
4. Preserve the established semantics:
   - `is_read_only=True`
   - `is_blocking=False`
   - `requires_human_review` is only a human-review signal
   - no generated `blocked` status
   - no automatic acceptance, rejection, approval, or package blocking
5. Preserve official transferable handover data versus private/non-transferable information separation.
6. Keep report building, checklist building, Markdown formatting, presentation consumption, human review, validation, persistence, audit, and export writing as separate layers.
7. Define a future test matrix covering at minimum:
   - success-only
   - failure-only
   - mixed
   - empty/zero-count
   - missing required and optional fields
   - unknown/additional fields and unknown statuses
   - unsupported input
   - input immutability
   - no report/checklist recomputation
   - no file/export output
   - no persistence or audit side effect
   - no hard validation
   - no generated `blocked` status
   - no automatic acceptance/rejection/blocking
   - private/non-transferable information exclusion
8. Define one narrow recommended next technical step without implementing it.
9. Record the Step 196-200 NotebookLM podcast note as the next documentation follow-up after Step 200 is merged; do not create it in this step.
10. Update docs, learning, result, roadmap, changelog, decisions, and active open-PR state factually.

## Required Verification

- `python -m pytest`
- `git diff --check`
- `git diff -- app/models.py tests/test_models.py .github/workflows/pytest.yml` must be empty
- `exports/` remains clean
- ZIP files remain untouched
- changed-file scope matches authorization

## Forbidden Scope

- no production code or test behavior changes
- no GitHub Actions workflow modification
- no required status checks
- no API/GUI/CLI implementation
- no database/repository persistence
- no audit, backup/restore, migration, or hard validation
- no generated `blocked` status
- no file/export output generation
- no automatic merge

## Commit and Push Permission

- Commit: allowed on `step-200-downstream-consumer-contract-plan`
- Push: allowed to the same branch
- Pull request: update draft PR #16
- Merge: not allowed until ChatGPT review and explicit user instruction

## Completion Criteria

- Consumer contract and layer boundaries are explicit.
- Non-blocking and private/official separation semantics are preserved.
- Future regression/test matrix is complete and implementation-free.
- Full local tests pass.
- Protected code/test/workflow files remain unchanged.
- Branch is pushed and draft PR #16 is ready for review.
