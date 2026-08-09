# Issue #420 Result — Explicit Multi-Link and Attachment Health

## Source identity and scope

- Exact base: `65e195fae6cfa8f1ed4c542e7c3fd3fdd100aed6`
- Branch: `codex/issue-420-v2-3-multilink-health`
- Worktree: `C:\Users\Fatih\AppData\Local\CSE-Worktrees\issue-420-multilink-health`
- Validation class: `visible attachment reuse / explicit multi-link / read-only health visibility`
- Production, test, and evidence changes remain inside the exact allowlist in
  `#issuecomment-5233068946`.

## Delivered contracts

- Added a project-scoped, read-only catalog over canonical
  `managed_attachments` and `attachment_links`, including physical metadata,
  integrity, and every project link.
- Added explicit Agenda image and Concrete general-evidence reuse flows. They
  create a new contextual link/event and advance the source revision without
  staging, copying, moving, deduplicating, or adopting attachment bytes.
- Unknown/cross-project targets and same-source duplicate physical/digest links
  fail closed. Agenda accepts JPEG/PNG/HEIC as `site_photo`; Concrete maps
  shipping images to `site_photo` and document/video/audio to `other`.
- Added a user-opened, read-only health page exposing the complete existing
  reconciliation problem matrix. Bootstrap exposes the service but never runs
  inspection or repair automatically.

## Validation evidence

- Focused application/widget and affected Agenda/Concrete/media/bootstrap
  regression chain: **PASS, 93 tests**.
- Final focused attachment catalog widget suite after the analyzer-only
  collection refactor: **PASS, 3 tests**.
- Full `flutter test --no-pub`: **PASS, 480 tests**.
- `flutter analyze --no-pub`: **PASS, no issues**.
- `git diff --check`: **PASS** before evidence finalization; repeated in the
  final publication preflight.
- `flutter build apk --debug --no-pub`: **PASS**.
- Debug APK SHA-256:
  `D97C5C68F1B743D7CBABA91C9481760427F14EE32E4489C808DB60F3F691B72E`.
- Conditional device gate: `adb devices -l` returned no attached device, so no
  install or launch was attempted. No real user record, database, attachment,
  backup, or report content was inspected or mutated.

## Preserved and reused evidence

- Mobile schema remains **13** and backup format remains **1**.
- `app_database.dart`, backup production code, `pubspec.yaml`, lockfile, plugin,
  permission, Android, and iOS files have no diff.
- Reused PR #421 canonical physical/link/event persistence evidence, PR #422
  shared-store/reconciliation evidence, and PR #423 multi-select/media/open
  regressions at the authorized base.
- The Gradle build emitted the existing future Kotlin built-in migration
  warning for `file_picker` and `share_plus`; dependency/toolchain work is
  outside this Issue and did not fail the build.

## Budget, safety, and publication boundary

- Binding time/retry budget is `N/A`; no blind retry was used. A stale orphan
  Flutter test process was terminated after exact PID/command-line
  identification. Harness-only and analyzer-reported corrections were narrow
  and were followed by the affected gate only.
- The official dirty worktree and user backup/report/data areas remained
  read-only and untouched. Official untracked paths were neither enumerated nor
  read.
- Publication is one intentional commit and normal push followed by a Draft PR
  containing `Part of #420`. Issue #420 stays open; Ready, merge, and the final
  V2.3 closure slice are not part of this result.
