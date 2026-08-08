# Issue NNN Task

## Objective

Describe one small, testable, reversible outcome.

## V2 Context

- Parent Epic: `#385`
- V2 item: `<V2.x — name>`
- Wave: `<1-6>`
- Depends on: `<issues/merged contracts or none>`
- Canonical scope: `docs/v2/CSE_V2_SCOPE.md`
- Roadmap: `ROADMAP.md`

## Repository Context

- Repository: `faliardic/chief-site-engineer`
- Base branch: `master`
- Expected base commit: `<sha>`
- Working branch: `codex/issue-NNN-<slug>`
- Official local working directory: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`

## Required Sources Read

1. `AGENTS.md`
2. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
3. `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
4. `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md`
5. `docs/v2/CSE_V2_SCOPE.md`
6. `ROADMAP.md`
7. current GitHub Issue and scope comments
8. `.cse/tasks/NNN_task.md`

For workflow/bootstrap/source-authority tasks also read the new-chat bootstrap and source register.

## Local Preconditions

- Inspect tracked, staged, untracked and ignored status before any write.
- Do not reset, clean, stash, delete or overwrite unexpected user work.
- Fast-forward local `master` from `origin/master`; required divergence: `0 0`.
- Keep ignored ZIP, device backups, reports and user artifacts untouched.

## Validation Contract

- Validation class: `<docs|narrow-ui|domain|persistence|release-critical>`
- Changed contracts: `<list>`
- Focused tests: `<list>`
- Allowed broad gates: `<none|full Flutter|analyze|build|release gate|device etc.>`
- Reused merged evidence: `<list or none>`
- Minimum physical-device/field acceptance: `<scenario or none>`
- Retry budget: `<value>`
- Time budget: `<value>`
- Stop conditions: `<list>`

## Data / Compatibility Impact

- Schema impact: `<none|details>`
- Migration impact: `<none|details>`
- Backup compatibility impact: `<none|details>`
- Attachment impact: `<none|details>`
- Notification impact: `<none|details>`
- User-data access: `<forbidden by default|explicit allowed boundary>`

## Authorized Paths

- `.cse/tasks/NNN_task.md`
- `.cse/results/NNN_result.md`
- `<exact path or bounded file group>`

`.cse/state/project_state.json` is changed only when the Issue explicitly requires a canonical merged/finalized state update.

## Required Work

1. `<action>`
2. `<action>`

## Out of Scope

- `<explicit non-goals>`
- no unrelated schema/migration/backup/audit/API/GUI/CLI/release/device expansion
- no hidden hard-delete or automatic formal decision

## Required Verification

- Run only the focused and broad gates authorized above.
- `git diff --check`
- changed/staged files equal the Issue allowlist
- no unintended export/artifact output
- ignored/user areas untouched
- final branch/local-remote divergence reported

## Publication Permission

- Commit: `<allowed|not allowed>`
- Push: `<allowed|not allowed>`
- Pull request: `<draft|required|not allowed>`
- Ready: `<allowed|not allowed>`
- Merge: `<allowed|not allowed>`

## Completion Criteria

- User-visible acceptance is satisfied.
- Data/compatibility invariants are preserved.
- Required checks pass.
- Result report is factual and distinguishes executed, reused and skipped gates.
- No unrelated file changes.
- Next V2 dependency is not started automatically unless explicitly authorized.
