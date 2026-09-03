# Issue #609 — DWG Existing File Architecture Audit Task

## Authority and start state

- Issue: `#609` (`DWG-002 — Existing File Architecture Audit`)
- Parent: `#523`
- Owner handoff: `#609` comment `5530588578`
- Exact base: `e52a92f8ba5bd59156f2d5f5df4770e2958e0171`
- Branch: `codex/issue-609-dwg-file-architecture-audit`
- Lane: `CRITICAL` — attachment, backup/restore, stable identity, and future DWG data-loss boundaries
- Execution time budget: 35 minutes

## Objective

Produce a read-only source audit that determines:

1. whether original DWG bytes can reuse the existing managed attachment file backbone;
2. every current `.dwg` MIME, extension, picker, size, and memory-path blocker;
3. whether a disposable derived vector-PDF cache root already exists;
4. how current backup creation and restore treat linked, unlinked, and orphan managed files;
5. how physical attachment identity, link identity, source-record revision, and a future DWG revision identity differ; and
6. which work is reusable, later extension, later new architecture, or requires a spike.

This task records architecture evidence only. It does not implement storage, schema, backup, platform, conversion, rendering, or measurement behavior.

## Canonical inputs

- `AGENTS.md`
- GitHub Issue `#609`, including the owner handoff comment
- GitHub parent Issue `#523`, including its current addendum
- `docs/v2/CSE_DWG_VIEWER_V1_CONTRACT.md`

## Read-only source evidence set

- `mobile/lib/storage/app_directories.dart` — `AppDirectories`
- `mobile/lib/bootstrap/app_bootstrap.dart` — `AppBootstrap.production`
- `mobile/lib/platform/managed_attachment_store.dart` — `ManagedAttachmentStore`, `DeviceManagedAttachmentStore`, `sniffMime`, `extensionForMime`
- `mobile/lib/platform/attachment_gateway.dart` — `SafeAttachmentPicker`
- `mobile/lib/platform/concrete_attachment_gateway.dart` — `FlutterAttachmentPickerPort`
- `mobile/lib/platform/inventory_attachment_gateway.dart` — `DeviceInventoryAttachmentGateway`
- `mobile/lib/storage/app_database.dart` — `AppDatabase`, `_applyAttachmentFoundationMigration`, `_applyInventoryFoundationMigration`
- `mobile/lib/application/attachment_catalog_application.dart` — `SqliteAttachmentCatalogApplication`
- `mobile/lib/application/attachment_reconciliation_application.dart` — `SqliteAttachmentReconciliationApplication`
- `mobile/lib/application/inventory_application.dart` — Inventory attachment link lifecycle
- `mobile/lib/application/mobile_backup_application.dart` — `SqliteMobileBackupApplication`, `CseBackupCodec`, `CseBackupArchiveCodec`
- `mobile/lib/platform/mobile_backup_gateway.dart` — incoming backup staging
- `mobile/lib/platform/export_gateway.dart` — `LocalExportStager`
- `mobile/lib/domain/attachment_models.dart` — attachment catalog and integrity identities
- `mobile/pubspec.yaml` — current version and dependency evidence only

## Write allowlist

Exactly these paths may change:

- `.cse/tasks/609_task.md`
- `.cse/results/609_result.md`
- `docs/v2/CSE_DWG_EXISTING_FILE_ARCHITECTURE_AUDIT.md`

Any fourth path, production/test/schema/backup/platform/pubspec edit, unexpected worktree drift, unresolved product conflict, or need to select a vendor/dependency/storage root/schema/PDF renderer is a stop condition.

## Routing and review contract

```yaml
routing:
  lane: CRITICAL
  task_shape: documentation_and_read_only_source_audit
  reasoning_target: extra_high
  independent_review_required: true
  ready_merge_owner_gated: true
```

The publication target is one minimal commit, a normal push, and one Draft PR with `Closes #609` and `Refs #523`. Ready, merge, Issue closure, vendor selection, and implementation are outside this execution.

## Validation contract

- Documentation consistency against the canonical inputs and cited source symbols
- Exact three-path changed-file set
- Protected production/test/schema/backup/platform/pubspec drift: zero
- `git diff --check`
- No build, test, analyzer, APK, device, or real-DWG execution
