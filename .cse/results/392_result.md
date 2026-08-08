# Issue 392 Result

## Outcome

Issue #392 için schema 10 verisini değiştirmeden schema 11 Project/Location persistence temeli tamamlandı. Çalışma yalnız kullanıcı tarafından yetkilendirilen linked worktree içinde yürütüldü; resmî kirli çalışma kopyası ve içindeki tracked/untracked kullanıcı dosyaları değiştirilmedi.

## Source and Workspace

- Repository: `faliardic/chief-site-engineer`
- Base: `origin/master`
- Exact base commit: `dedc75bbab29dab509002ef9fbcf2fc5c3cd48f5`
- Branch: `codex/issue-392-v2-1a-project-location-schema`
- Worktree: `C:\Users\Fatih\AppData\Local\CSE-Worktrees\issue-392`
- Validation class: `persistence`
- Backup format: unchanged at `1`
- Database schema: `10 -> 11`

## Implemented Contract

- `project_locations` canonical table, project-scoped hierarchy, revision/timestamp/archive fields and active sibling-name uniqueness were added.
- Cross-project parents, self-parenting, post-creation `project_id` changes and physical location deletion fail closed.
- Empty `project_events` and `project_location_events` foundations use the exact allowed vocabularies and append-only histories.
- `field_observations`, `follow_up_items` and `concrete_pours` received nullable `location_id` foreign keys.
- Record-to-location project consistency is enforced on insert and update.
- The migration is additive; existing V1 aggregate tables are not rebuilt and no legacy row is auto-linked.
- Schema 10 legacy IDs, free-text locations, revisions, histories, context links and attachment metadata remain byte-value equivalent at the SQLite row level, apart from the three newly added null columns.
- Backup format 1 stages and restores schema 10 packages through schema 11, including attachment files and hashes.

## Focused Validation

- `flutter test --no-pub test/project_location_schema_migration_test.dart test/app_database_test.dart test/mobile_backup_application_test.dart`: **55/55 passed**.
- PR #393 review correction sonrası `flutter test --no-pub test/project_location_schema_migration_test.dart`: **4/4 passed**; Project-A location Project-B'ye taşınamadı, Ajanda/Reminder/Concrete linkleri aynı kaldı ve FK check temiz kaldı.
- `flutter test --no-pub test/platform_notification_configuration_test.dart`: **6/6 passed** after updating its explicit schema pin from 10 to 11.
- Fresh schema 11, contiguous migration history, schema 10 preservation, atomic rollback, foreign keys, immutable location-project identity, hierarchy constraints, event vocabularies, append-only/no-delete protection and backup restore were exercised with synthetic temporary data.

## Broad Validation

- First `flutter test --no-pub` run found one stale source-text assertion that still pinned schema 10.
- After the exact test-only correction, the initial implementation full-suite retry passed: **367/367**.
- PR #393 review correction changed the production migration; the explicitly required final-source full Flutter suite passed: **367/367**.
- Final-source `flutter analyze --no-pub`: **passed, no issues found**.
- `git diff --check`: **passed**.

## Reused and Skipped Evidence

- PR #382 / `7c9f65a811c9f4bca561adab6bd1f8e64e6908cc` was reused only for unchanged V1 user-facing and release/device contracts. It was not treated as schema 11 or backup compatibility evidence.
- Build, signing, AAB, ARM64/16 KiB, ADB, physical-device, reboot/background, notification, uninstall/data-clear and production backup/restore gates were not run because Issue #392 changes only the persistence/backup migration contract and explicitly authorizes synthetic focused tests plus the Flutter suite/analyzer.
- No real user database, backup archive, report, old build output or ignored user area was read or changed.

## Budget and Exceptions

- The primary implementation run used one exact failed-operation retry after the narrow stale schema-pin fix.
- The single blocking correction run authorized by PR #393 review was used for `project_locations.project_id` immutability and its regression proof.
- No GitHub Actions rerun was requested because the account billing lock remains an external runner-start blocker.
- The configured Dart executable was not on `PATH`; formatting was completed with the repository-compatible bundled Flutter SDK path. This did not change product scope or require an infrastructure fix.
- The 90-minute target and 120-minute hard stop were respected.
- No out-of-scope infrastructure issue was taken into the feature branch.

## Publication

Commit SHA, push equality/divergence and Draft PR URL are recorded in the GitHub Issue completion comment after publication, avoiding a metadata-only follow-up commit. Merge and ready-for-review transitions remain unauthorized.
