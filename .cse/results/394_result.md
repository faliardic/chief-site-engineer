# Issue 394 Result

## Outcome

Issue #394 için schema 11 üzerinde UI'dan bağımsız `ProjectLocationApplication` sözleşmesi tamamlandı. Mevcut `SqliteAgendaApplication` proje davranışını tekrar etmeden yeni interface'i implement eder; ayrı repository katmanı eklenmedi.

## Source and Workspace

- Repository: `faliardic/chief-site-engineer`
- Base: `origin/master`
- Exact base commit: `407c4c572f68b1bbacda124adc2044ec24df6644`
- Branch: `codex/issue-394-v2-1b-project-location-application`
- Worktree: `C:\Users\Fatih\AppData\Local\CSE-Worktrees\issue-394`
- Validation class: `application + persistence`
- Database schema: unchanged at `11`
- Backup format: unchanged at `1`

## Implemented Contract

- `MobileProjectLocation`, typed archive filter, semantic event types and create/rename/reparent/archive commands were added without exposing `normalized_name` as domain source-of-truth.
- A separate `ProjectLocationApplication` interface shares existing `projectChanges`, `listProjects()` and `createProject()` implementation.
- Active/archived reads, stable-ID get and sequence-ordered event history are deterministic.
- Create requires an active project, canonical non-empty display name and an optional active same-project parent; duplicate active sibling names and conflicting ID reuse fail closed.
- Rename, reparent, archive and restore use exact optimistic revision, one SQLite transaction, revision increment, canonical UTC `updated_at`, semantic append-only events and commit-only notification.
- Reparent supports root and rejects cross-project/archived/self/descendant parents.
- Archive rejects any active descendant; restore requires an active parent and rejects active sibling-name collisions.
- Repeated archive/restore terminal commands and semantic no-ops do not append a second event or notification.
- Event insertion failure rolls back the aggregate update, revision and notification.

## Changed Files

- `.cse/tasks/394_task.md`
- `.cse/results/394_result.md`
- `mobile/lib/domain/project_location_models.dart`
- `mobile/lib/application/agenda_application.dart`
- `mobile/test/project_location_application_test.dart`

No fake, schema, backup, feature/UI or `.cse/state` file changed.

## Focused Validation

- `flutter test --no-pub test/project_location_application_test.dart`: **8/8 passed**.
- `flutter test --no-pub test/agenda_application_test.dart`: **22/22 passed**.
- The focused suite covers active/archive filtering, deterministic ordering, create constraints, normalized siblings, optimistic rename, reparent/cycle rules, archive/restore hierarchy, event payload/order, atomic rollback, exact notification count, immutable project identity and append-only storage compatibility.

## Broad Validation

- `flutter test --no-pub`: **375/375 passed**.
- First `flutter analyze --no-pub` found one unnecessary test import.
- After removing only that import, the affected focused suite again passed **8/8** and the single exact analyze retry passed with **no issues found**.
- The full suite was not repeated after a non-semantic unused-import removal, in accordance with the final-source affected-stage rule.
- `git diff --check`: **passed**.

## Reused and Skipped Evidence

- PR #393 / `407c4c572f68b1bbacda124adc2044ec24df6644` was reused for unchanged schema 11 migration, backup format 1 compatibility, schema trigger/index integrity, location-project immutability and preserved V1 text/link contracts.
- Migration/backup suites were not rerun because Issue #394 changes no schema, migration, backup or V1 record-link behavior.
- Build, signing, AAB, ARM64/16 KiB, ADB, physical-device, notification, reboot/background and release gates were not run because no user-facing or platform contract changed.
- No real user database, backup, report, build output or ignored user area was read or changed.

## Budget and Exceptions

- Primary Codex run count: `1`.
- Blocking correction run count: `0`.
- The analyze operation used its single allowed exact-fix retry.
- The 90-minute target and 120-minute hard stop were respected.
- No out-of-scope infrastructure issue was taken into the branch.

## Workspace Safety

The original dirty worktree remained read-only. No stash, reset, clean, restore, checkout, commit or user-file access was performed there. All Issue #394 file edits, dependency setup and validation ran only in the authorized linked worktree.

## Publication

Final commit SHA, push equality/divergence, Draft PR URL and any automatic GitHub Actions billing annotation are recorded in the Issue completion comment after publication. Ready-for-review and merge remain unauthorized.
