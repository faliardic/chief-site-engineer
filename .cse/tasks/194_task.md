# Step 194 - Automated Local CSE Status Report Command

## Objective

Add a small, read-only local command that gathers the standard CSE handoff checks and emits a deterministic human-readable summary plus JSON output.

## Repository Context

- Repository: `faliardic/chief-site-engineer`
- Issue: #3
- Base branch: `master`
- Expected base commit: `51d6bc9283fab92bc303d0d96b6a17768d28979e`
- Working branch: `step-194-cse-status-report`
- Local working directory: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`

## Reasoning Level

- Codex: extra high
- ChatGPT review: Extra High

## Authorized Changes

- `scripts/cse_status.py`
- focused tests under `tests/`
- `.cse/results/194_result.md`
- `.cse/state/project_state.json`
- documentation files only when directly required for command usage

## Required Work

1. Implement a read-only status command, preferably runnable as:

   ```bash
   python scripts/cse_status.py
   ```

2. Support an explicit pytest option so tests are not run silently by every lightweight status check. A reasonable interface is:

   ```bash
   python scripts/cse_status.py --run-tests
   ```

3. Gather and report:
   - current branch
   - HEAD commit SHA and message
   - `origin/master...HEAD` divergence when the remote ref exists
   - staged files
   - tracked working-tree changes
   - ignored files visibility
   - `git diff --check`
   - `exports/` contents and cleanliness
   - ZIP files visible in the working tree, with no mutation
   - pytest result when `--run-tests` is supplied

4. Emit both:
   - concise human-readable terminal output
   - deterministic JSON suitable for handoff/state use

5. Use subprocess calls safely:
   - argument lists, not shell interpolation
   - captured stdout/stderr
   - explicit return-code handling
   - useful behavior when Git, `origin/master`, or pytest is unavailable

6. Add focused tests. Mock subprocess/filesystem boundaries where appropriate; do not require destructive repository operations.

7. Update `.cse/results/194_result.md` and `.cse/state/project_state.json` with factual final results.

## Required Verification

- `python -m pytest`
- `git diff --check`
- Confirm changed files match authorized scope.
- Confirm `exports/` remains clean.
- Confirm ignored ZIP files remain untouched.
- Confirm no unrelated production application files changed.
- Run the new command without tests.
- Run the new command with `--run-tests`.
- Validate emitted JSON parses successfully.

## Forbidden Scope

Do not:

- stage files automatically
- delete or clean ignored files or caches
- commit, push, merge, or change branches from inside the script
- write under `exports/`
- modify ZIP files
- introduce hard validation or automatic blocking
- generate application-level `blocked` status
- add API, GUI, database/repository application access, audit behavior, backup/restore, or migration behavior
- change existing production application behavior

## Output and Mutation Boundary

The command is diagnostic only. Writing JSON is allowed only when the user explicitly supplies an output-path option; default execution must not modify the repository. If an output path is implemented, use explicit overwrite protection unless `--overwrite` is supplied.

## Commit and Push Permission

- Commit: allowed on `step-194-cse-status-report`
- Push: allowed to the same branch
- Pull request: update draft PR #4
- Merge: not allowed

## Required Result Files

- `.cse/results/194_result.md`
- `.cse/state/project_state.json`

## Completion Criteria

- The command is read-only by default.
- Required checks are visible and machine-readable.
- Focused tests pass.
- Full test suite passes.
- No unrelated scope is introduced.
- Branch is pushed and draft PR #4 is ready for ChatGPT review.
