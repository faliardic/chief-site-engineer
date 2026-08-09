# Issue #420 Task — V2.3 Managed Attachment Store

## Authority

- GitHub Issue: `#420`
- Binding authorization: `#issuecomment-5232402995`
- Parent Epic: `#385`
- Canonical V2 source: `docs/v2/CSE_V2_SCOPE.md`
- Exact base: `c1b531c565ebacde9878809dfe2f50be1ec1bad6`
- Worktree: `C:\Users\Fatih\AppData\Local\CSE-Worktrees\issue-420-managed-store`
- Branch: `codex/issue-420-v2-3-managed-store`

The official dirty worktree, the old Issue #419 worktree, user backup/report
areas, and real user database or attachment roots are not execution sources and
must not be read or modified.

## Model and reasoning

- Codex model: current full Codex model selected by the user
- Reasoning: `Extra High`
- Reason: persistence, filesystem containment, atomic staging, integrity
  classification, compensation safety, and multi-adapter regression risk

## Validation class

`persistence / managed attachment store`

## Changed contracts

This slice changes only:

1. Agenda and Concrete physical file writes delegate to one common managed
   attachment store contract.
2. New physical writes use `managed/<attachmentId>.<ext>`; existing
   `agenda/...` and `concrete/...` paths remain in place and readable.
3. Common staging/finalization enforces safe names, size, MIME sniffing,
   private-root containment, traversal/absolute-path rejection,
   symlink/non-regular-file fail-closed checks, re-read verification, atomic
   finalize, and operation-local compensation.
4. Supported binary types remain JPEG, PNG, HEIC, and PDF.
5. A read-only reconciliation application reports canonical schema-13 graph
   and managed-root integrity findings without repair or mutation.
6. Bootstrap constructs one shared managed store for Agenda and Concrete and
   does not run reconciliation automatically.

## Preserved contracts and explicit exclusions

- Mobile schema remains `13`; no migration or schema bump.
- Backup format remains `1`.
- No legacy path move, rename, consolidation, adoption, or SHA-only dedupe.
- No UI, multi-select, viewer/player, video/audio support, permission, or
  dependency changes.
- No automatic delete, relink, adopt, dedupe, metadata rewrite, file move, or
  reconciliation at bootstrap.
- Agenda/Reminder and Concrete user behavior remains unchanged.
- Unknown/cross-project source and context validation remains fail-closed.
- Tests use synthetic temporary roots only.
- Build, AAB, signing, store submission, and physical-device acceptance are
  `N/A` for this non-visible slice.

## Exact changed-file allowlist

Production — new:

- `mobile/lib/domain/attachment_models.dart`
- `mobile/lib/platform/managed_attachment_store.dart`
- `mobile/lib/application/attachment_reconciliation_application.dart`

Production — existing:

- `mobile/lib/platform/agenda_attachment_gateway.dart`
- `mobile/lib/platform/concrete_attachment_gateway.dart`
- `mobile/lib/bootstrap/app_bootstrap.dart`

Tests — new:

- `mobile/test/managed_attachment_store_test.dart`
- `mobile/test/attachment_reconciliation_application_test.dart`

Tests — existing:

- `mobile/test/concrete_attachment_gateway_test.dart`
- `mobile/test/agenda_application_test.dart`
- `mobile/test/concrete_application_test.dart`
- `mobile/test/app_bootstrap_test.dart`

Evidence/docs:

- `.cse/tasks/420_managed_store_task.md`
- `.cse/results/420_managed_store_result.md`
- `docs/project_decisions.md`

Any additional file requires exact Issue #420 authorization before edit.

## Focused validation

- Common new-write path and legacy path read/inspect preservation.
- Re-read size/hash/MIME verification and JPEG/PNG/HEIC/PDF sniffing.
- Empty, oversize, spoof, unsafe path, collision, symlink component, and
  non-regular-file rejection.
- Failure cleanup is limited to the current operation artifact.
- Agenda and Concrete adapter delegation plus existing attach/read/archive or
  detail regressions.
- Reconciliation findings: healthy, missing, size, hash, MIME, unsafe path,
  broken target, cross-project target, orphan finalized file, stale managed
  staging file, and duplicate legacy candidate.
- Reconciliation performs no file or database mutation and ignores unrelated
  staging and `incoming_backups`.
- Bootstrap shared-store wiring.

Allowed final gates, once at the final source revision:

- focused tests;
- `flutter test --no-pub` once;
- `flutter analyze --no-pub` once;
- `git diff --check`;
- exact allowlist and protected-path checks.

## Reused evidence

- PR #421 / merge `c1b531c565ebacde9878809dfe2f50be1ec1bad6`:
  schema-13 physical/link/event source-of-truth, Agenda/Concrete cutover, and
  backup format-1 compatibility.
- PR #418 / merge `50e97eedab9f77236e31051784d59045cbdb0d9b`:
  V2.3 preflight inventory and lifecycle/reconciliation boundaries.

## Budget and stop conditions

- Elapsed-time budget: `N/A` by explicit owner authorization.
- Retry/run-count budget: `N/A` by explicit owner authorization.

Work stops fail-closed for any schema-14 or backup-format bump requirement,
legacy byte/path movement or dedupe requirement, real-user attachment-root
access requirement, unsafe shared-byte compensation boundary, required
UI/permission/dependency change, video/audio or visible UX spillover, any
non-V2.3 dependency, or any required edit outside the allowlist.

## Publication

After all authorized gates pass:

1. record `.cse/results/420_managed_store_result.md` and Issue #420 evidence;
2. create one intentional commit;
3. push normally without force;
4. open a Draft PR containing `Part of #420` without closing Issue #420;
5. do not mark Ready and do not merge.
