# Step 196 - GitHub Actions Pytest Workflow

## Objective
Add a minimal, deterministic GitHub Actions workflow that runs the repository test suite automatically for pull requests and pushes to `master`.

## Repository Context
- Repository: `faliardic/chief-site-engineer`
- Issue: #7
- Base branch: `master`
- Expected base commit: `e98ba58554857e2719b1c4e1315e8edd31f2f919`
- Working branch: `step-196-github-actions-pytest`

## Reasoning Level
- Codex: extra high
- ChatGPT review: Extra High

## Authorized Changes
- `.github/workflows/**`
- dependency/setup files only when strictly required for CI
- `.cse/results/196_result.md`
- `.cse/state/project_state.json`
- directly required tests or documentation only

## Required Work
1. Add one focused CI workflow with a stable job/check name suitable for later branch-protection selection.
2. Trigger on:
   - pull requests targeting `master`
   - pushes to `master`
3. Use `actions/checkout` and `actions/setup-python` current stable major versions.
4. Use a supported stable Python version compatible with the repository.
5. Install only required test/runtime dependencies. Inspect the repository first; do not invent a packaging migration.
6. Run `python -m pytest`.
7. Include a whitespace/diff integrity check where valid for the checked-out commit without mutating the repository.
8. Keep permissions minimal and do not require secrets.
9. Validate YAML and, where possible, run local tests before push.
10. Update `.cse/results/196_result.md` and `.cse/state/project_state.json` factually.

## Required Verification
- `python -m pytest`
- `git diff --check`
- changed-file scope matches authorization
- workflow YAML parses or is structurally validated
- `exports/` remains clean
- ZIP files remain untouched
- no unrelated production behavior changes

## Forbidden Scope
- no deployment or release workflow
- no package publishing
- no secrets or cloud credentials
- no automatic merge
- no branch mutation from the workflow
- no API/GUI/application database/repository behavior
- no audit, backup/restore, migration, or hard validation

## Commit and Push Permission
- Commit: allowed on `step-196-github-actions-pytest`
- Push: allowed to the same branch
- Pull request: update the Step 196 draft PR
- Merge: not allowed until ChatGPT review and explicit user instruction

## Completion Criteria
- CI check runs on PRs and `master` pushes.
- Job/check name is stable and documented.
- Full local tests pass.
- Workflow remains minimal and non-deploying.
- Branch is pushed and draft PR is ready for review.