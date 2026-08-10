# Issue #420 Task — V2.3 Explicit Multi-Link and Attachment Health

## Authority

- GitHub Issue: `#420`
- Binding authorization: `#issuecomment-5233068946`
- Parent Epic: `#385`
- Canonical V2 item: `V2.3 Attachment / Fotoğraf / Medya V2`
- Exact base: `65e195fae6cfa8f1ed4c542e7c3fd3fdd100aed6`
- Worktree:
  `C:\Users\Fatih\AppData\Local\CSE-Worktrees\issue-420-multilink-health`
- Branch: `codex/issue-420-v2-3-multilink-health`

The official dirty worktree, prior Issue #420 worktrees, Issue #419, Issue #424,
user backup/report areas, and real user database or attachment roots are not
execution sources and must not be read or modified.

## Model and reasoning

- Codex model: current full Codex model selected by the user
- Reasoning: `Extra High`
- Reason: project-scoped physical/link projection, cross-project fail-closed
  validation, optimistic revision/event ordering, shared-byte preservation, and
  read-only filesystem-health visibility carry multi-layer regression risk.

## Validation class

`visible attachment reuse / explicit multi-link / read-only health visibility`

## Changed contracts

1. A project-scoped catalog projects canonical `managed_attachments` and
   `attachment_links`, including filename, MIME, size, integrity, and all source
   contexts using the same physical attachment.
2. Agenda log detail can explicitly link an existing project image physical
   attachment as a new `site_photo` link without staging or copying bytes.
3. Concrete general field evidence can explicitly link an existing project
   physical attachment; images use `site_photo`, document/video/audio use
   `other`, while specialized evidence roles remain unchanged.
4. Unknown, cross-project, invalid-context, and duplicate-active source links
   fail closed. Successful mutations preserve existing revision/event ordering.
5. Archiving one contextual link never deletes the physical attachment or any
   other active link.
6. The existing reconciliation inspection is exposed through a user-triggered,
   read-only health page; it never runs automatically at bootstrap and never
   repairs, deletes, moves, adopts, relinks, or deduplicates data.

## Preserved contracts and exclusions

- Mobile schema remains `13`; backup format remains `1`.
- No dependency, lockfile, plugin, manifest, permission, Android, or iOS change.
- No byte copy, staging, dedupe, SHA-only merge, adoption, legacy-path move, or
  cleanup for existing-physical linking.
- No M4A compatibility or attachment-size-limit work from deferred Issue #424.
- No V2.4 or other V2 item, OpenAI API, or autonomous loop.
- No real-user DB, backup, attachment-root inspection, UI dump, or mutation.

## Exact changed-file allowlist

Production:

- `mobile/lib/domain/attachment_models.dart`
- `mobile/lib/domain/agenda_models.dart`
- `mobile/lib/domain/concrete_models.dart`
- `mobile/lib/application/attachment_catalog_application.dart`
- `mobile/lib/application/attachment_reconciliation_application.dart`
- `mobile/lib/application/agenda_application.dart`
- `mobile/lib/application/concrete_application.dart`
- `mobile/lib/bootstrap/app_bootstrap.dart`
- `mobile/lib/app.dart`
- `mobile/lib/features/attachments/attachment_catalog_page.dart`
- `mobile/lib/features/attachments/attachment_health_page.dart`
- `mobile/lib/features/agenda/log_detail_page.dart`
- `mobile/lib/features/concrete/concrete_pour_detail_page.dart`

Tests:

- `mobile/test/attachment_catalog_application_test.dart`
- `mobile/test/attachment_reconciliation_application_test.dart`
- `mobile/test/agenda_application_test.dart`
- `mobile/test/concrete_application_test.dart`
- `mobile/test/attachment_catalog_widget_test.dart`
- `mobile/test/mobile_agenda_widget_test.dart`
- `mobile/test/app_bootstrap_test.dart`

Evidence/docs:

- `.cse/tasks/420_multilink_health_task.md`
- `.cse/results/420_multilink_health_result.md`
- `docs/project_decisions.md`

Any additional file requires exact Issue #420 authorization before edit.

## Focused validation

- project-scoped catalog, same-physical/multiple-link projection, and
  cross-project/unknown fail-closed behavior;
- Agenda and Concrete explicit existing-physical linking without new physical
  rows or byte operations;
- duplicate-active rejection, shared physical retention, role classification,
  revision advance, and deterministic event ordering;
- health summary/finding projection and explicit-only read-only invocation;
- visible missing, size/hash/MIME, unsafe, broken/cross-project, orphan, stale,
  and duplicate-legacy findings;
- existing Agenda multi-photo/open/archive and Concrete multi-file/open/
  specialized-evidence regressions.

Allowed final gates at the final source revision:

- focused affected suites;
- full `flutter test --no-pub`;
- `flutter analyze --no-pub`;
- `git diff --check`;
- exact allowlist and protected-path verification;
- `flutter build apk --debug --no-pub`;
- if exactly one authorized physical device exists, data-preserving
  `adb install -r` and launch smoke only.

## Reused evidence

- PR #423 merge `65e195fae6cfa8f1ed4c542e7c3fd3fdd100aed6`:
  multi-select, media open, existing Agenda/Concrete attachment regressions,
  schema 13, and backup format 1.
- PR #422 merge `f5895653b64d3c26aefcbb5256eb7a2b5f22749f`:
  shared managed store and read-only reconciliation.
- PR #421 merge `c1b531c565ebacde9878809dfe2f50be1ec1bad6`:
  canonical physical/link/event persistence.

## Device and publication

- Codex device automation is limited to exactly one authorized physical device,
  `adb install -r`, and launch smoke; no user content is inspected or mutated.
- Manual visible-slice acceptance is provided after source review and is not
  claimed by Codex.
- After every authorized gate passes: record result and Issue evidence, create
  one intentional commit, push normally, and open a Draft PR with `Part of
  #420`.
- Do not mark Ready, merge, or close Issue #420.

## Budget and stop conditions

- Time and retry/run-count budget: `N/A` by binding owner authorization.
- No blind retries; repeat only after an exact root-cause correction.
- Stop without scope expansion if schema/backup/dependency/permission changes,
  byte copy/dedupe/adoption, preserved-flow regression, mutable health behavior,
  allowlist expansion, real-user data access, or non-V2.3 work becomes required.
