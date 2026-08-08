# Issue 392 Task

## Objective

Schema 10 V1 verisini değiştirmeden schema 11 stable Project/Location persistence temelini kurmak.

## V2 Context

- Parent Epic: `#385`
- V2 item: `V2.1 — Proje ve Mahal omurgası`
- Wave: `1`
- Depends on: `#390 / PR #391 / dedc75bbab29dab509002ef9fbcf2fc5c3cd48f5`
- Canonical scope: `docs/v2/CSE_V2_SCOPE.md`
- Roadmap: `ROADMAP.md`

## Repository Context

- Repository: `faliardic/chief-site-engineer`
- Base branch: `master`
- Expected base commit: `dedc75bbab29dab509002ef9fbcf2fc5c3cd48f5`
- Working branch: `codex/issue-392-v2-1a-project-location-schema`
- Official repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- User-authorized linked worktree: `C:\Users\Fatih\AppData\Local\CSE-Worktrees\issue-392`
- Codex model: current session full Codex model
- Reasoning: `Extra High`
- Selection reason: persistence, migration, foreign-key, append-only event and backup compatibility contracts are regression-sensitive.

## Required Sources Read

1. `AGENTS.md`
2. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
3. `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
4. `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md`
5. `docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md`
6. `docs/protocols/CSE_PROJECT_SOURCE_REGISTER.md`
7. `docs/v2/CSE_V2_SCOPE.md`
8. `ROADMAP.md`
9. GitHub Issue #392 and all scope comments
10. `docs/v2/CSE_V2_1_PROJECT_LOCATION_MIGRATION_PREFLIGHT.md`
11. `.cse/tasks/392_task.md`

## Local Preconditions

- The dirty official worktree is read-only for Issue #392 and remains untouched.
- The linked worktree was created directly from `origin/master` after verifying exact base `dedc75bbab29dab509002ef9fbcf2fc5c3cd48f5`.
- Linked-worktree starting HEAD/base equality, divergence `0 0`, and clean tracked/untracked state were verified.
- No real user data root, device backup, report, old build output, ignored ZIP, or unrelated worktree may be read or changed.

## Validation Contract

- Validation class: `persistence`
- Changed contracts: schema 10→11; `project_locations`; empty project/location event foundations; nullable stable `location_id` links on Ajanda, Reminder and Concrete records; unchanged legacy text snapshots.
- Focused tests: schema 11 fresh install and migration contract; atomic rollback; FK/link constraints; append-only/no-delete triggers; schema 10 backup restore compatibility when generic coverage is insufficient.
- Allowed broad gates: full Flutter test suite; `flutter analyze --no-pub`.
- Reused merged evidence: PR #382 / `7c9f65a811c9f4bca561adab6bd1f8e64e6908cc` only for unchanged V1 user-facing and release/device contracts, not for schema 11 or backup compatibility.
- Minimum physical-device/field acceptance: none.
- Retry budget: one primary run, at most one blocking correction run, same failed operation at most one retry after an exact fix.
- Time budget: 90-minute target, 120-minute hard stop.
- Stop conditions: table rebuild of existing V1 aggregates; legacy ID/text/revision/event/attachment mutation; backup format change; user-facing behavior change; unrelated location field or attachment/source-link breakage.

## Data / Compatibility Impact

- Schema impact: `AppDatabase.schemaVersion` 10→11 with contiguous migration history.
- Migration impact: additive tables, columns, indexes and narrow validation triggers only; existing aggregate tables are not rebuilt.
- Backup compatibility impact: format remains 1; schema 10 packages must stage-migrate to schema 11.
- Attachment impact: no row, file, count or source-link change.
- Notification impact: none.
- User-data access: forbidden; synthetic temporary databases only.

## Authorized Paths

- `.cse/tasks/392_task.md`
- `.cse/results/392_result.md`
- `mobile/lib/storage/app_database.dart`
- `mobile/test/app_database_test.dart`
- `mobile/test/project_location_schema_migration_test.dart` when a dedicated test file keeps coverage narrow
- `mobile/test/mobile_backup_application_test.dart` only if generic schema-10 restore coverage is insufficient
- `mobile/test/platform_notification_configuration_test.dart` only for the schema-version pin proven stale by the full Flutter suite

`.cse/state/project_state.json` is not authorized for this unmerged implementation.

## Required Work

1. Add canonical schema 11 migration to the default foundation chain.
2. Add the Project/Location tables, link columns, indexes, fail-closed constraints and immutable-history protections from Issue #392.
3. Prove fresh install and synthetic schema 10 upgrade preserve all legacy contracts and roll back atomically on failure.
4. Prove backup format 1 restores supported schema 10 data through schema 11 without attachment regression.
5. Run focused tests, the full Flutter suite, analyze, diff and exact-scope checks.

## Out of Scope

- Project/location repository or application mutations.
- Project edit/archive/restore UI.
- Mahal Kataloğu UI.
- Linking legacy rows or fuzzy/AI matching.
- V2.2 or later work.
- Backup format bump.
- Permanent delete, device, build, signing, release or ADB work.

## Required Verification

- Run only the focused and broad gates authorized above.
- `git diff --check`.
- Changed/staged files equal this task allowlist.
- No unintended export/artifact output.
- Ignored/user areas untouched.
- Final branch/local-remote divergence reported.

## Publication Permission

- Commit: `allowed after all required checks pass`
- Push: `allowed`
- Pull request: `draft required through GitHub workflow`
- Ready: `not allowed without review`
- Merge: `not allowed without explicit user decision`

## Completion Criteria

- All Issue #392 persistence and compatibility invariants are executable and pass.
- Required broad gates pass once on the final source revision.
- Result evidence distinguishes executed, reused and deliberately skipped gates.
- No unrelated files or user data are touched.
- V2.1b is not started automatically.
