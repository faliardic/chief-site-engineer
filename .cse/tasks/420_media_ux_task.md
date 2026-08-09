# Issue #420 Task — V2.3 Multiple Selection and Media Open

## Authority

- GitHub Issue: `#420`
- Binding authorization: `#issuecomment-5232628409`
- Audio correction authorization: `#issuecomment-5232827614`
- Parent Epic: `#385`
- Canonical V2 item: `V2.3 Attachment / Fotoğraf / Medya V2`
- Exact base: `f5895653b64d3c26aefcbb5256eb7a2b5f22749f`
- Worktree: `C:\Users\Fatih\AppData\Local\CSE-Worktrees\issue-420-media-ux`
- Branch: `codex/issue-420-v2-3-media-ux`

The official dirty worktree, prior Issue #420 worktrees, Issue #419, user
backup/report areas, and real user database or attachment roots are not
execution sources and must not be read or modified.

## Model and reasoning

- Codex model: current full Codex model selected by the user
- Reasoning: `Extra High`
- Reason: batch mutation atomicity, filesystem compensation, MIME integrity,
  picker compatibility, viewer routing, and visible mobile regression risk

## Validation class

`visible attachment UX / batch mutation / media open`

## Changed contracts

1. `SafeAttachmentPicker.pick(...)` remains backward compatible and a bounded
   `pickMany(...)` contract supports photo-library and file-picker batches;
   camera remains single-item.
2. Agenda create and existing-log attachment flows accept multiple photos as
   one all-or-nothing user mutation while preserving `site_photo` semantics.
3. Concrete general field evidence accepts multiple JPEG/PNG/HEIC/PDF/MP4/
   MP3/M4A/WAV attachments all-or-nothing; specialized evidence semantics stay
   unchanged.
4. JPEG/PNG use the existing in-app viewer. HEIC/PDF/video/audio use the
   existing external-open path only after integrity PASS.
5. Batch selection is guarded at maximum 20 items and 100 MiB total unless
   current APIs require a narrower tested bound. Individual store limit stays
   unchanged.

## Preserved contracts and exclusions

- Mobile schema remains `13`; backup format remains `1`.
- No dependency, plugin, manifest, permission, Android, or iOS change.
- No camera video, microphone recording, voice capture, embedded media player,
  project album, V2.4 synchronization, legacy path move, cleanup, adoption, or
  dedupe.
- No real-user database, backup, attachment-root inspection, UI dump, record
  creation, or mutation.
- Existing Agenda and Concrete single-attachment behavior remains compatible.

## Exact changed-file allowlist

Production:

- `mobile/lib/platform/attachment_gateway.dart`
- `mobile/lib/platform/concrete_attachment_gateway.dart`
- `mobile/lib/platform/managed_attachment_store.dart`
- `mobile/lib/application/agenda_application.dart`
- `mobile/lib/application/concrete_application.dart`
- `mobile/lib/domain/agenda_models.dart`
- `mobile/lib/domain/concrete_models.dart`
- `mobile/lib/features/agenda/log_form_page.dart`
- `mobile/lib/features/agenda/log_detail_page.dart`
- `mobile/lib/features/concrete/concrete_pour_detail_page.dart`
- `mobile/lib/features/concrete/concrete_attachment_viewer_page.dart`

Tests:

- `mobile/test/attachment_gateway_test.dart`
- `mobile/test/managed_attachment_store_test.dart`
- `mobile/test/concrete_attachment_gateway_test.dart`
- `mobile/test/agenda_application_test.dart`
- `mobile/test/concrete_application_test.dart`
- `mobile/test/mobile_agenda_widget_test.dart`
- `mobile/test/attachment_media_widget_test.dart`

Evidence/docs:

- `.cse/tasks/420_media_ux_task.md`
- `.cse/results/420_media_ux_result.md`
- `docs/project_decisions.md`

Any additional file requires exact Issue #420 authorization before edit.

## Validation contract

Focused tests cover picker single/many behavior and guards; all supported MIME
families; unsafe/spoofed inputs; Agenda and Concrete batch atomicity,
compensation, deterministic revisions/events, and existing specialized flows;
viewer routing and integrity-gated external open; and existing single flows.

Allowed final gates at the final source revision:

- focused affected suites;
- full `flutter test --no-pub`;
- `flutter analyze --no-pub`;
- `git diff --check`;
- exact allowlist and protected-path verification;
- `flutter build apk --debug`;
- if exactly one authorized physical device exists, data-preserving
  `adb install -r` and launch smoke only.

## Reused evidence

- PR #422 merge `f5895653b64d3c26aefcbb5256eb7a2b5f22749f`:
  shared managed store, read-only reconciliation, schema 13, backup format 1.
- PR #421 merge `c1b531c565ebacde9878809dfe2f50be1ec1bad6`:
  canonical physical/link/event persistence and Agenda/Concrete cutover.

## Device and publication

- Manual device acceptance is required after source review and is reported by
  the user; Codex must not claim manual PASS/FAIL.
- Automated build/install/launch may be completed before publication without
  uninstall, clear-data, restore, UI dump, or user-data mutation.
- After automated gates PASS: record result and Issue evidence, create one
  intentional commit, push normally, and open a Draft PR with `Part of #420`.
- Do not mark Ready, merge, or close Issue #420.

## Budget and stop conditions

- Time and run-count budget: `N/A` by binding owner authorization.
- No blind retry; rerun only after exact root-cause correction.
- Stop without scope expansion for required schema/backup/dependency/permission
  change, unsafe batch compensation, preserved-flow regression, uncertain MIME
  sniffing, integrity-gate bypass, allowlist expansion, real-user data access,
  or any non-V2.3 requirement.

## Audio correction

The physical-device acceptance in `#issuecomment-5232827614` is partial PASS:
photo, PDF, video, specialized evidence, restart, and the existing viewer/open
paths passed; selected audio did not attach. The authorized correction is
limited to MP3/M4A/WAV picker-to-store-to-Concrete batch behavior, secure
byte/container classification, visible non-destructive failure feedback, and
the corresponding focused/full/analyze/diff/build/replace-install gates.
Schema, backup format, dependency, permission, Agenda batch, photo/PDF/video,
and specialized Concrete contracts remain unchanged. PR #423 stays Draft and
manual re-acceptance is only the audio select/add/list/open/restart path.
