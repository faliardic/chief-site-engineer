# Issue #409 — completion evidence

## Execution identity

- Validation class: `persistence` — schema migration + canonical registry application contract.
- Linked worktree: `C:\Users\Fatih\AppData\Local\CSE-Worktrees\issue-409`.
- Branch: `codex/issue-409-v2-2b-registry-profile-schema12`.
- Exact base and pre-publication HEAD: `5fc0e3442031b5d1ecf4f2b46f16e3213ca0c30d`.
- Pre-publication `HEAD...origin/master`: `0 0`.
- Reasoning: Extra High because the change crosses schema migration, stable
  identity, dependent attendance/compliance/PPE links, archive/revision/event
  history and backup compatibility.
- Elapsed coordination time from Issue creation through final local build
  evidence was approximately 53 minutes: above the 45-minute target because of
  explicit stop/authorization cycles, but within the 75-minute hard stop.
- Primary implementation run: 1.
- Ordinary blocking correction budget: 1/1, used for the stale future-schema
  backup fixture.
- Exceptional correction: 1, limited by comment `#5231025907` to the stale
  platform current-schema pin.
- Environment evidence retry: 1, explicitly authorized by comment
  `#5230971627` after the first full-suite exit evidence was lost.

## Changed contracts

- Mobile schema advances atomically from 11 to 12.
- `subcontractors` adds nullable `address`, `specialty`, `started_on` and
  `ended_on` columns.
- `workforce_members` adds nullable `address` and `started_on` columns.
- Subcontractor and workforce-member create/update/read contracts expose those
  optional fields without changing canonical IDs.
- Update commands distinguish preserve, set and explicit clear; unrelated
  updates do not erase stored profile values.
- Existing local-date validation is reused and subcontractor
  `ended_on >= started_on` is enforced when both values exist.
- Backup format remains `1`; no backfill, identity rewrite, fuzzy merge,
  attachment redesign, UI or Puantaj workflow change was introduced.

## Changed files

- `.cse/tasks/409_task.md`
- `.cse/results/409_result.md`
- `mobile/lib/storage/app_database.dart`
- `mobile/lib/domain/attendance_models.dart`
- `mobile/lib/application/attendance_application.dart`
- `mobile/test/app_database_test.dart`
- `mobile/test/attendance_application_test.dart`
- `mobile/test/mobile_backup_application_test.dart`
- `mobile/test/project_location_schema_migration_test.dart` — narrow allowlist
  authorization in comment `#5230933776`.
- `mobile/test/platform_notification_configuration_test.dart` — exact
  current-schema pin exception in comment `#5231025907`.

No `docs/project_decisions.md` change was necessary because Issue #409 and its
tests fully specify the new contract.

## Focused validation

- `test/app_database_test.dart`: PASS, 21/21 in the focused combined run.
- `test/attendance_application_test.dart`: PASS, 16/16 in the focused combined
  run.
- `test/mobile_backup_application_test.dart`: PASS, 32/32 after the single
  exact future-schema fixture correction.
- `test/project_location_schema_migration_test.dart`: PASS, 4/4.
- `test/platform_notification_configuration_test.dart`: PASS, 6/6 after the
  exact schema-12 pin correction.

The focused evidence covers schema 11-to-12 PK/FK/archive/revision/event
preservation, intentional rollback, fresh/upgraded schema equivalence, nullable
legacy rows, profile persistence/preserve/clear/restart, stable registry move,
historical archived members, schema-11 restore+migrate and schema-12 format-1
round-trip behavior.

## Broad gates

- Final corrected-revision `flutter test --no-pub`: PASS, 430/430, exit 0.
- `flutter analyze --no-pub`: PASS, no issues found.
- Final pre-result `git diff --check`: PASS.
- Exact changed-file allowlist comparison: PASS, zero unexpected paths.
- Production diff path check: PASS; only the three authorized production files
  changed.
- `flutter build apk --debug`: PASS.
- Debug APK:
  `mobile/build/app/outputs/flutter-apk/app-debug.apk`.
- Debug APK SHA-256:
  `9930F350D461CE29DE8605A2E2DB979903E7B93F31101D40F81D126EC1C9A996`.
- Debug APK size: `170644422` bytes.

The build emitted only a non-blocking future Kotlin built-in migration warning
for existing plugins. Release/signing/toolchain changes are outside #409 and
were not added to this branch.

## Reused and intentionally omitted evidence

- Canonical `workforce_members.id` identity graph and schema 5-to-6 stable-link
  adoption are reused from PR #408 / base
  `5fc0e3442031b5d1ecf4f2b46f16e3213ca0c30d`; #409 does not rewrite that
  graph.
- Application/package ID, signing, ARM64/16 KiB, permission/privacy,
  background delivery and reboot reconciliation are unchanged and were not
  rerun.
- AAB/release gates and destructive backup/restore/device checks were not run
  because #409 is not release-critical and does not change those contracts.

## Physical-device decision

No physical-device install/open smoke was run. This child adds no visible UI,
manual acceptance is not required, and opening the schema-12 build on a device
with existing data could itself perform a database migration. Skipping the
optional smoke preserves the explicit no-real-user-data-mutation boundary.

## Protected workspace evidence

- The official dirty worktree was inspected read-only only and remains on
  `codex/d29-5-backup-result-visibility-manual` at
  `7c9f65a811c9f4bca561adab6bd1f8e64e6908cc` with the same four tracked
  modifications recorded before #409.
- Its untracked contents were not enumerated or read.
- User backup/report/device-backup/data areas were not read or changed.
- No stash, restore, checkout, reset, clean, delete, overwrite or force push
  was used.
- V2.2c was not started.

## Publication record policy

This evidence file is authored before commit and intentionally does not embed
its own commit SHA. Final branch SHA, push divergence and Draft PR metadata are
recorded in the Issue completion comment and PR to avoid metadata-only commits.
Ready and merge are not authorized.
