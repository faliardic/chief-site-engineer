# Issue 394 Task

## Objective

Schema 11 Project/Location temelinin üzerine UI'dan bağımsız, test edilebilir ve mevcut SQLite application mimarisini tekrar etmeyen `ProjectLocationApplication` sözleşmesini kurmak.

## Repository Context

- Repository: `faliardic/chief-site-engineer`
- Base branch: `master`
- Exact base commit: `407c4c572f68b1bbacda124adc2044ec24df6644`
- Working branch: `codex/issue-394-v2-1b-project-location-application`
- Official dirty repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- User-authorized linked worktree: `C:\Users\Fatih\AppData\Local\CSE-Worktrees\issue-394`
- Codex model: current full Codex model
- Reasoning: `Extra High`
- Selection reason: optimistic revision, transactional event history, hierarchy cycle detection and fail-closed persistence rules are regression-sensitive.

## Required Sources

1. `AGENTS.md`
2. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
3. `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
4. `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md`
5. GitHub Issue #394 and all scope/permission comments
6. `.cse/tasks/394_task.md`
7. `docs/v2/CSE_V2_SCOPE.md`
8. `ROADMAP.md`

The first four tracked sources are byte-identical to the fully read Issue #392 base sources; their blob equality was verified against the exact Issue #394 base before worktree creation.

## Local Preconditions

- `origin/master` and the linked-worktree starting HEAD equal the exact base commit.
- Starting divergence is `0 0` and tracked/untracked state is clean.
- The existing dirty official worktree remains read-only; its untracked user areas are not listed, read or changed.
- No real user data, backup, report, build output or device area may be accessed.

## Validation Contract

- Validation class: `application + persistence`
- Changed contracts: new ProjectLocation domain model/interface; SQLite location reads/mutations; optimistic concurrency; hierarchy invariants; semantic append-only events; commit-only change notifications.
- Focused tests: new ProjectLocation application suite and relevant existing Agenda application tests.
- Allowed broad gates: one final full Flutter suite, `flutter analyze --no-pub`, `git diff --check`.
- Reused evidence: PR #393 / `407c4c572f68b1bbacda124adc2044ec24df6644` for unchanged schema 11 migration, backup format 1, trigger/index and V1 text/link contracts.
- Minimum physical-device acceptance: none.
- Retry budget: one primary run, at most one blocking correction run, same failed operation at most one exact-fix retry.
- Time budget: 90-minute target, 120-minute hard stop.
- Stop conditions: schema/migration or trigger/index change; backup change; V1 text/link adoption; UI/navigation; Project rename/archive/restore lifecycle.

## Authorized Paths

- `.cse/tasks/394_task.md`
- `.cse/results/394_result.md`
- `mobile/lib/domain/project_location_models.dart`
- `mobile/lib/application/agenda_application.dart`
- `mobile/test/project_location_application_test.dart`
- `mobile/test/support/fake_agenda_application.dart` only if the separate interface is actually implemented by that fake

The following are explicitly unauthorized: `mobile/lib/storage/app_database.dart`, backup implementation/tests, feature/UI files and `.cse/state/project_state.json`.

## Required Work

1. Add the minimum `MobileProjectLocation` domain/read contract without exposing normalized storage data.
2. Add a separate `ProjectLocationApplication` interface while sharing existing project list/create/change behavior.
3. Implement deterministic reads and transactional create/rename/reparent/archive/restore operations in `SqliteAgendaApplication`.
4. Enforce UUIDs, active project/parent rules, revision checks, sibling duplicates, descendant-cycle prevention, archive/restore hierarchy rules and exact semantic events.
5. Emit `projectLocationChanges` exactly once after successful commits and never after failures.
6. Add focused executable coverage for every Issue #394 acceptance invariant.

## Out of Scope

- Schema version or migration changes.
- Backup format, restore or encryption changes.
- V1 free-text/location-link adoption.
- Project rename/archive/restore lifecycle.
- UI, navigation or Mahal Kataloğu screens.
- V2.1c or later work.

## Publication

- Commit/push: allowed only after all authorized local gates pass.
- Draft PR: required.
- Ready: forbidden in this task.
- Merge: forbidden without explicit user approval.
- V2.1c is not started automatically.
