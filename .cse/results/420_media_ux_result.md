# Issue #420 Result — V2.3 Multiple Selection and Media Open

## Authority and source

- Binding authorization: `#issuecomment-5232628409`
- Branch: `codex/issue-420-v2-3-media-ux`
- Linked worktree:
  `C:\Users\Fatih\AppData\Local\CSE-Worktrees\issue-420-media-ux`
- Exact base: `f5895653b64d3c26aefcbb5256eb7a2b5f22749f`
- Validation class: `visible attachment UX / batch mutation / media open`

## Delivered contract

- `pick(...)` remains compatible; `pickMany(...)` keeps camera single and adds
  bounded multi-photo / multi-file selection with denied, unavailable, cancel,
  count, and total-byte fail-safe outcomes.
- The common managed store now sniffs and stores JPEG, PNG, HEIC, PDF, MP4,
  MP3, M4A, and WAV without trusting the supplied extension. The individual
  20 MiB store limit, safe basename/root/path, symlink/non-regular rejection,
  hash, size, and MIME checks remain enforced.
- New Agenda logs receive every photo selected in one picker action through the
  existing create transaction. Existing Agenda logs receive a batch with one
  revision increment; any stage/validation/DB failure rolls the whole batch
  back and cleans only that operation's managed files.
- General Concrete evidence receives one ordered batch. Images use
  `site_photo`; PDF/video/audio use `other`. Truck, delivery-note, sample, and
  other specialized single-evidence semantics are unchanged. A successful
  batch advances the pour revision once and appends ordered evidence events.
- JPEG/PNG remain in the in-app `InteractiveViewer`. HEIC/PDF/MP4/MP3/M4A/WAV
  route to the existing `open_filex` gateway only after the application repeats
  the managed path/MIME/hash integrity gate. Failed integrity exposes only the
  diagnostic and cannot invoke external open.

## Focused validation

PASS evidence at the final production revision:

- picker single/many compatibility, camera-single behavior, permission/cancel/
  unavailable handling, 20-item and 100 MiB guard harness;
- managed-store MIME/extension/hash/path tests for all eight supported media
  families plus spoof, oversize, traversal, symlink/non-regular, collision, and
  legacy-path preservation;
- Concrete attachment gateway regression;
- Agenda create/existing-log batch atomicity, one-revision behavior, event order,
  duplicate rollback, image-only role, and compensation;
- Concrete general batch atomicity, MIME role classification, event sequence,
  one-revision behavior, duplicate rollback, legacy/shared preservation, and
  integrity-gated external open;
- Agenda multi-photo widget flow, Concrete general multi-file widget flow,
  JPEG/PNG viewer routing, external media routing, and failed-integrity UI gate;
- existing Agenda/Concrete application and widget regressions, including the
  specialized evidence flows.

Exact focused files exercised:

- `test/attachment_gateway_test.dart`
- `test/managed_attachment_store_test.dart`
- `test/concrete_attachment_gateway_test.dart`
- `test/agenda_application_test.dart`
- `test/concrete_application_test.dart`
- `test/mobile_agenda_widget_test.dart`
- `test/attachment_media_widget_test.dart`

## Final gates

- `flutter test --no-pub`: PASS, `470` tests.
- `flutter analyze --no-pub`: PASS, no issues.
- `git diff --check`: PASS.
- `flutter build apk --debug --no-pub`: PASS. The initial shell invocation
  reached its 120-second host timeout after producing the artifact; the same
  unchanged revision's failed build stage alone was rerun once and completed
  successfully in 12.6 seconds.
- Debug APK SHA-256:
  `25165179D9191384D0AB9E58679AE88388CA9F70C618CEDF506D891F48B2A3C9`.
- Build emitted the pre-existing future Kotlin built-in migration warning for
  `file_picker` / `share_plus`; no dependency or build configuration change was
  authorized or required.

## Automated physical-device smoke

- Exactly one authorized ADB device: `SM-S938B` (`ro.kernel.qemu=0`).
- Only `adb install -r` was used: `Success`.
- Explicit debug activity launch: PASS.
- No uninstall, clear-data, restore, UI dump, real-user content scan, record
  creation, attachment mutation, or backup/report access occurred.
- Manual multi-media acceptance remains an owner gate after source review.
  This result does not claim manual PASS or FAIL.

## Preserved and reused contracts

- Schema remains `13`; `app_database.dart` is unchanged.
- Backup format remains `1`; backup production files are unchanged.
- `pubspec.yaml`, lockfiles, Android/iOS manifests, permissions, plugin lists,
  and platform configuration are unchanged.
- No camera video, microphone/voice recording, embedded player, legacy move,
  reconciliation mutation, dedupe/adoption, V2.11 album, or V2.4 sync work.
- Reused merged evidence: PR #422 at the exact base for common managed store,
  read-only reconciliation, schema 13, and backup format 1; PR #421 for the
  canonical physical/link/event persistence cutover.

## Budget and publication state

- Authorization defines time/run budget as `N/A`; retries were never blind and
  were limited to exact compiler/harness corrections and the single timed-out
  build stage.
- At result creation: commit, push, and Draft PR are pending final Git and
  allowlist checks.
- Issue #420 must remain open; the Draft PR uses `Part of #420` and must not be
  marked Ready or merged by Codex.
