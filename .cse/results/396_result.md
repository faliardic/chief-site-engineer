# Issue #396 — Completion evidence

## Repository and scope

- Official repository: `V:\\1_PROJECTS\\2_ACTIVE\\Python\\chief-site-engineer`
- Authorized linked worktree: `C:\\Users\\Fatih\\AppData\\Local\\CSE-Worktrees\\issue-396`
- Base: `origin/master` / `9cf3466ef92047f49d99881c27d8ab34311dcf89`
- Branch: `codex/issue-396-v2-1c-project-lifecycle`
- Initial linked-worktree evidence: `HEAD == origin/master`, divergence `0 0`, tracked/untracked clean.
- The original D29.5 dirty worktree was inspected only with tracked/read-only Git commands and was not mutated. Its tracked changes and untracked user areas were left in place.

## Implemented contract

- Added backward-compatible archived state to `MobileProject` plus lifecycle commands, filters, and typed project events.
- Added the narrow `ProjectLifecycleApplication` without extending `AgendaApplication`.
- Added stable-ID get, deterministic active/archived record lists, optimistic rename, archive, restore, and ordered event history.
- Every real lifecycle mutation updates the aggregate and inserts its `project_events` row in one SQLite transaction; event failure rolls back the aggregate.
- `projectChanges` is published once after a successful commit and never for failure or semantic/terminal no-op.
- Archive/restore performs no child update, rewrite, delete, or physical purge.
- Schema remains 11 and backup format remains 1; no migration, trigger, index, storage, backup, UI, navigation, attendance, or concrete production file changed.

## Validation run

- Focused `flutter test --no-pub test/project_lifecycle_application_test.dart`: PASS, 8/8 (rerun after the lint-only import correction).
- Existing Agenda application regression `flutter test --no-pub test/agenda_application_test.dart`: PASS, 22/22.
- Full `flutter test --no-pub`: PASS, 383/383.
- `flutter analyze --no-pub`: first run found one unnecessary test import; the single authorized correction removed it, and the retry PASSed with no issues.
- `git diff --check`: PASS.
- Allowlist check: PASS; only the task/result records, two preferred production files, and the new preferred focused test are changed.

Focused acceptance covers active-only `listProjects`, active/archived stable-ID reads and deterministic listing, rename payload/revision/no-op/stale/collision/archive rejection, archive/restore revision and terminal no-op behavior, child preservation, restore collision, event-ID rollback, ordered append-only events, unsupported storage, safe malformed/missing IDs, join-derived renamed project display, and exact change-stream cardinality.

The child-preservation fixture verifies unchanged IDs/counts/project IDs across `project_locations`, `field_observations`, `follow_up_items`, `attendance_days`, `concrete_pours`, an Agenda attachment, aggregate event histories, a concrete class event, and a concrete-pour context link.

## Proportional validation and budgets

- Reused merged evidence: schema-11 project/location/event tables and append-only triggers from V2.1a; active-project enforcement and Project/Location application transaction patterns from V2.1b.
- Not run by Issue design: build, signing, AAB, ADB, physical device, backup/restore, background/reboot, ARM64/16 KiB, or release gate. No platform/UI/release contract changed.
- Retry budget: one analyze correction used; no failed test retry and no repeated full gate.
- Time budget: completed within the 30-minute target and 45-minute hard stop.
- Infrastructure findings: none during local validation. GitHub Actions state will be recorded after publication; unchanged-source manual rerun will not be used if the known billing lock prevents job start.

## Publication state at record time

- Commit: pending final allowlist review.
- Push: pending commit.
- Pull request: Draft required after push; Ready and merge are not authorized.
- Final commit SHA and Draft PR URL are recorded in GitHub/Issue completion metadata to avoid a metadata-only follow-up commit.
