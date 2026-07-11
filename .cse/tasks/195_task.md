# Step 195 - Explicit Post-Merge CSE State Finalization

## Objective

Add an explicit, testable post-merge finalization path so `.cse/state/project_state.json` no longer remains in an open-draft-PR state after a successful merge.

## Repository Context

- Repository: `faliardic/chief-site-engineer`
- Issue: #5
- Base branch: `master`
- Expected base commit: `de95bc0ed7f3115bba80d4410dfa2f518fb6bfe1`
- Working branch: `step-195-post-merge-state-finalization`
- Local working directory: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`

## Reasoning Level

- Codex: extra high
- ChatGPT review: Extra High

## Authorized Changes

- `scripts/cse_status.py`
- focused tests under `tests/`
- `.cse/results/195_result.md`
- `.cse/state/project_state.json`
- directly required `.cse` usage documentation

## Required Work

1. Preserve the existing default behavior of:

   ```bash
   python scripts/cse_status.py
   ```

   as diagnostic and read-only.

2. Add an explicit post-merge state finalization interface. The exact CLI may differ, but it must require affirmative user intent and explicit metadata. A suitable direction is:

   ```bash
   python scripts/cse_status.py --finalize-state \
     --step 194 \
     --issue 3 \
     --pull-request 4 \
     --merge-commit de95bc0... \
     --state-output .cse/state/project_state.json \
     --overwrite
   ```

3. The finalized state must clearly record:
   - finalized step
   - issue number and closed/completed state
   - pull request number and merged state
   - source branch and base branch
   - merge commit SHA
   - verification/test summary
   - exports/ and ZIP status
   - `workflow_status` indicating merged/finalized
   - `merge_authorized` no longer pending
   - next recommended action

4. Do not silently claim remote GitHub state. PR/issue merged or closed metadata must be supplied explicitly. Local Git evidence may be included separately, with uncertainty visible.

5. Reuse existing JSON-writing safeguards:
   - explicit output path
   - overwrite protection
   - deterministic JSON
   - useful errors for incomplete metadata

6. Add focused tests for:
   - default command remaining read-only
   - finalization requiring explicit flag
   - required metadata validation
   - deterministic finalized state generation
   - overwrite protection
   - no Git mutation commands
   - no ZIP/export mutation

7. Run and report:
   - focused tests
   - full test suite
   - `git diff --check`
   - default status command
   - finalization command against a temporary output path
   - JSON parse validation

8. Update `.cse/results/195_result.md` and `.cse/state/project_state.json` with factual results for the open draft PR workflow. Do not mark Step 195 itself merged before it is actually merged.

## Forbidden Scope

Do not:

- automatically call GitHub APIs from the script
- automatically merge, commit, push, stage, clean, or change branches
- silently infer PR/issue remote state
- modify ZIP files
- write under `exports/`
- add hard validation or application-level automatic blocking
- add API, GUI, application database/repository access, audit behavior, backup/restore, or migration
- change existing production application behavior

## Commit and Push Permission

- Commit: allowed on `step-195-post-merge-state-finalization`
- Push: allowed to the same branch
- Pull request: update draft PR created for Step 195
- Merge: not allowed until ChatGPT review and explicit user instruction

## Required Result Files

- `.cse/results/195_result.md`
- `.cse/state/project_state.json`

## Completion Criteria

- Default status remains read-only.
- Finalization is explicit and metadata-driven.
- Finalized JSON is deterministic and overwrite-protected.
- Focused and full tests pass.
- No unrelated scope is introduced.
- Branch is pushed and draft PR is ready for review.
