# Issue #420 Task — V2.3 Attachment Foundation

## Authority

- GitHub Issue: `#420`
- Binding authorization: `#issuecomment-5232186989`
- Regression-test allowlist authorization: `#issuecomment-5232214442`
- Parent Epic: `#385`
- Canonical V2 source: `docs/v2/CSE_V2_SCOPE.md`
- Exact base: `50e97eedab9f77236e31051784d59045cbdb0d9b`
- Worktree: `C:\Users\Fatih\AppData\Local\CSE-Worktrees\issue-420`
- Branch: `codex/issue-420-v2-3-attachment-foundation`

Issue #419 is not an execution source for this task and is not reopened. Its
working tree or uncommitted changes must not be read, copied, or modified.

## Validation class

`persistence / attachment foundation`

## Changed contracts

This first V2.3 slice changes only:

1. canonical physical attachment identity and contextual link persistence;
2. lossless schema migration/cutover for existing Agenda and Concrete
   attachment metadata;
3. Agenda and Concrete persistence adapters while preserving their existing
   user behavior;
4. fail-closed project/source/context integrity for attachment links;
5. schema-aware format-1 backup/restore round-trip without changing the backup
   format version.

No attachment bytes are read, moved, deleted, or deduplicated by migration.
Equal SHA-256 values do not authorize automatic physical-record merging.

## Explicitly out of scope

- multiple selection;
- viewer/player or video/audio UI;
- shared managed-file store or reconciliation UX;
- any new user-facing surface;
- V2.4 and all non-V2.3 product work;
- release/AAB/signing/store submission;
- OpenAI API, autonomous loop, Bridge, Orchestrator, or Work Mode;
- physical-device acceptance for this persistence-only slice;
- real user database, backup, attachment, `device-backups/`, or `reports/`
  access/mutation.

## Exact changed-file allowlist

Production:

- `mobile/lib/storage/app_database.dart`
- `mobile/lib/application/agenda_application.dart`
- `mobile/lib/application/concrete_application.dart`
- `mobile/lib/application/mobile_backup_application.dart`
- `mobile/lib/application/restore_recovery_application.dart`

Tests:

- `mobile/test/attachment_schema_migration_test.dart`
- `mobile/test/app_database_test.dart`
- `mobile/test/agenda_application_test.dart`
- `mobile/test/concrete_application_test.dart`
- `mobile/test/mobile_backup_application_test.dart`
- `mobile/test/restore_recovery_application_test.dart`
- `mobile/test/platform_notification_configuration_test.dart`
- `mobile/test/project_lifecycle_application_test.dart`
- `mobile/test/project_location_schema_migration_test.dart`

Evidence/docs:

- `.cse/tasks/420_task.md`
- `.cse/results/420_result.md`
- `docs/project_decisions.md`

Any additional file requires a new exact authorization comment before edit.

## Focused validation contract

- fresh canonical schema invariants;
- lossless Agenda migration of ID/path/project/archive/context;
- lossless Concrete migration of ID/path/pour/child/archive/context;
- no automatic SHA merge;
- fail-closed rollback for duplicate path, missing target, cross-project, and
  invalid context fixtures;
- Agenda attach/read/archive and Reminder source-photo projection regressions;
- Concrete attach/read/detail/source-validation regressions;
- schema-12 format-1 restore to the new schema;
- new-schema format-1 physical/link round-trip;
- canonical attachment/link graph validation during restore recovery.

Allowed broad gates, once at final source revision:

- affected/full `flutter test --no-pub`;
- `flutter analyze --no-pub`;
- `git diff --check`;
- exact allowlist and protected-path checks.

## Reused evidence

- V2.3 preflight inventory: Issue #417 / PR #418 / merged master
  `50e97eedab9f77236e31051784d59045cbdb0d9b`.
- Existing merged Agenda, Concrete, and backup characterization tests remain
  valid where their behavior is unchanged.

## Budget and stop conditions

Time and retry/run-count budgets are explicitly N/A. Work still stops
fail-closed for:

- legacy ID/path/project/context/archive loss;
- migration requiring attachment-byte read/move/delete/dedupe;
- a required backup format change;
- inability to preserve Agenda/Concrete attachment behavior;
- inability to enforce unknown/cross-project links fail-closed;
- any required production edit outside the allowlist;
- any real user data access requirement;
- any dependency on a non-V2.3 feature.

## Publication

After all authorized gates pass:

1. record completion evidence in `.cse/results/420_result.md` and Issue #420;
2. create one intentional commit;
3. push normally without force;
4. open a Draft PR without closing Issue #420;
5. do not mark Ready and do not merge.
