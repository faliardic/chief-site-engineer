# Step 202 - Canonical Handover QC View-Model Examples and Wording Standardization

## Objective

Define documentation-only canonical examples and wording standards for the future handover QC downstream presentation view-model planned in Step 200, without implementing a consumer or changing production behavior.

## Repository Context

- Repository: `faliardic/chief-site-engineer`
- Issue: #19
- Base branch: `master`
- Expected base commit: `3918bfbe73d79ea6dcb9228ebcbd2818322965ec`
- Working branch: `step-202-canonical-view-model-wording`

## Reasoning Level

- Codex: Extra High
- ChatGPT review: Extra High

## Authorized Changes

- `docs/202_handover_qc_canonical_view_model_examples_and_wording_standardization.md`
- `learning/202_handover_qc_canonical_view_model_examples_and_wording_standardization.md`
- `ROADMAP.md`
- `CHANGELOG.md`
- `docs/project_decisions.md`
- `.cse/results/202_result.md`
- `.cse/state/project_state.json`
- directly required documentation only

## Required Work

1. Create canonical structured examples for future downstream presentation consumers using `build_export_handover_qc_review_checklist(summary, report)` output as the source of truth.
2. Cover at minimum:
   - success-only
   - failure-only
   - mixed
   - empty/zero-count
   - missing optional fields
   - unknown status/additional fields
   - unsupported input fallback
3. Standardize user-visible wording for:
   - status labels
   - human-review indicators
   - empty states
   - missing-field fallback text
   - unknown-status visibility
   - item-level next-action hints
4. Preserve:
   - `is_read_only=True`
   - `is_blocking=False`
   - `requires_human_review` as a human-review signal only
   - no generated `blocked` status
   - no automatic acceptance, rejection, approval, or package blocking
5. Treat `format_export_handover_qc_review_checklist_as_markdown(checklist)` only as optional presentation output; do not define Markdown parsing as a source of structured truth.
6. Preserve official-transferable versus private/non-transferable separation in every example.
7. Define regression expectations for wording stability, fallback safety, input immutability, no recomputation, no file/export output, no persistence/audit side effects, no hard validation, and no generated `blocked` status.
8. Update docs/learning/result/state/roadmap/changelog/decisions factually.
9. Define one narrow next technical step without implementing it.

## Required Verification

- `python -m pytest`
- `git diff --check`
- `git diff -- app/models.py tests/test_models.py .github/workflows/pytest.yml` must be empty
- changed-file scope matches authorization
- `exports/` remains clean
- ZIP files remain untouched

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

- Commit: allowed on `step-202-canonical-view-model-wording`
- Push: allowed to the same branch
- Pull request: update the Step 202 draft PR
- Merge: not allowed until ChatGPT review and explicit user instruction

## Completion Criteria

- Canonical examples are complete and internally consistent.
- User-visible wording and fallback text are standardized.
- Read-only/non-blocking semantics remain explicit.
- Official/private separation is preserved.
- Full local tests pass.
- No protected code/test/workflow files change.
- Branch is pushed and the draft PR is ready for review.
