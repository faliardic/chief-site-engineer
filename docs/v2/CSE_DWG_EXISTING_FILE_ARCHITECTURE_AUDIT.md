# CSE DWG Existing File Architecture Audit

- Status: Issue #609 architecture evidence for DWG-002
- Base: `e52a92f8ba5bd59156f2d5f5df4770e2958e0171`
- Parent: Issue #523
- Contract: `docs/v2/CSE_DWG_VIEWER_V1_CONTRACT.md`

## 1. Decision summary

The original DWG can reuse the existing managed-file security backbone, but it cannot use the current ingestion contract unchanged. Safe relative paths, generated physical identity, byte size, SHA-256 verification, atomic stage/finalize, inspection, and link-based backup enumeration are reusable. Current file picking, MIME sniffing, extension mapping, managed-path validation, in-memory staging, and the 20 MiB store limit reject or constrain DWG.

The repository has no disposable, reproducible derived-artifact cache root. The current `attachments` root is durable managed storage; `exports_backups` is durable user output; and `temp_staging` is transaction/recovery scratch space. None has the ownership, cache-key, invalidation, or regeneration semantics required by the DWG viewer contract.

The future architecture therefore has two distinct lifecycles:

- Original DWG: durable and backup-relevant, using an extended managed-file backbone plus a new DWG document/revision domain model.
- Derived vector PDF: disposable and reproducible, using a later dedicated cache boundary outside managed attachment backup enumeration.

This audit does not choose a converter/vendor, cloud versus local conversion, an exact storage root, a schema shape, or a PDF renderer. Those choices remain with DWG-003/DWG-004 and later authorized implementation work.

## 2. Current file roots and ownership

`mobile/lib/storage/app_directories.dart` — `AppDirectories.fromSupportRoot` derives an environment-scoped application-support root and defines these children:

| Root | Current owner/purpose | DWG conclusion |
|---|---|---|
| `database` | SQLite database file | Metadata authority, not a binary/cache root. |
| `attachments` | Durable managed attachment bytes | Candidate for original DWG after ingestion extension; not a disposable cache. |
| `exports_backups` | Final exported/backup packages | User-facing durable output; not a viewer cache. |
| `state` | Backup/restore state and journals | Recovery coordination; not a content root. |
| `temp_staging` | Atomic staging, restore preparation/rollback, incoming backup staging | Short transaction scratch space; not a reopenable derived cache. |

`mobile/lib/bootstrap/app_bootstrap.dart` — `AppBootstrap.production` obtains the application-support directory, constructs `AppDirectories`, performs backup recovery before opening the database, and shares one `DeviceManagedAttachmentStore` across attachment features. This is evidence for one current durable managed-file backbone.

No production source under `mobile/lib` requests an application cache directory or system temporary directory. `mobile/lib/platform/export_gateway.dart` — `LocalExportStager.stage` finalizes staged output into `exports_backups`, while `mobile/lib/platform/mobile_backup_gateway.dart` uses `temp_staging/incoming_backups` for imported backup packages. Neither is a derived-view cache.

## 3. Original DWG and the managed attachment backbone

### 3.1 Reusable guarantees

`mobile/lib/platform/managed_attachment_store.dart` — `DeviceManagedAttachmentStore.stage` currently provides:

- basename-only original file names;
- generated UUID physical names under `attachments/managed`;
- safe relative-path resolution and symlink rejection;
- staging to a `.part` file, flush, reread verification, and atomic rename;
- persisted byte size, SHA-256, detected MIME type, and creation time;
- cleanup of partial/final files on a failed stage.

`DeviceManagedAttachmentStore.inspect` rechecks path safety, file type, size, SHA-256, and MIME. `mobile/lib/domain/attachment_models.dart` — `ManagedAttachmentIntegrity` and `ProjectAttachmentCatalogItem` expose the computed integrity result separately from database identity.

These properties fit the original-DWG requirement: immutable source bytes should be durably identified and integrity-verifiable. Reuse means extending this backbone, not silently treating an unsupported file as an existing supported attachment type.

### 3.2 Exact current DWG blockers

| Evidence | Current rule | Consequence for `.dwg` |
|---|---|---|
| `mobile/lib/platform/concrete_attachment_gateway.dart` — `FlutterAttachmentPickerPort.pick` / `pickMany` | Custom extension allowlist is `jpg`, `jpeg`, `png`, `heic`, `pdf`, `mp4`, `mp3`, `m4a`, `wav`. | The generic file picker does not admit `.dwg`. |
| `mobile/lib/platform/inventory_attachment_gateway.dart` — `DeviceInventoryAttachmentGateway` | Inventory accepts camera/photo-library input and only JPEG/PNG/HEIC MIME types; file picker input is unsupported. | Inventory photo ingestion cannot be repurposed for DWG. |
| `mobile/lib/platform/managed_attachment_store.dart` — `sniffMime` | Recognizes JPEG, PNG, HEIC, PDF, MP4, MP3, M4A, and WAV magic signatures only. | DWG bytes fail with `unsupported_mime`. |
| Same file — `extensionForMime` | Maps only the same media/PDF MIME set. | No managed `.dwg` final extension can be produced. |
| Same file — `managedFinalPathPattern` | Accepts only `jpg|png|heic|pdf|mp4|mp3|m4a|wav`. | A `.dwg` final managed path fails current path validation, inspection, and cleanup. |
| Same file — `DeviceManagedAttachmentStore.maximumBytes` | Defaults to 20 MiB. | A DWG above 20 MiB is rejected even if type support is added. |
| Same file — `ManagedAttachmentStore.stage(List<int>)` and picker `withData: true` | The complete source is passed and verified as in-memory bytes. | Large-file memory viability is unproven and requires a bounded spike before limits are expanded. |
| `mobile/lib/application/mobile_backup_application.dart` — `CseBackupArchiveCodec.maximumEntryBytes` | A decoded archive entry is limited to 128 MiB; the backup service also limits encrypted packages to 512 MiB and expanded archives to 768 MiB. | Any future larger-DWG policy must be checked end to end, not only at the attachment store. |

The database itself does not enumerate attachment MIME values. `mobile/lib/storage/app_database.dart` — `_applyAttachmentFoundationMigration` requires only a non-empty `managed_attachments.mime_type` and a safe relative path. The immediate type blocks are in picker/store code, while size and memory constraints cross ingestion and backup boundaries.

## 4. Existing metadata and four separate identities

`mobile/lib/storage/app_database.dart` — `_applyAttachmentFoundationMigration` defines `managed_attachments` with physical `id`, unique `relative_path`, `mime_type`, `byte_size`, `sha256`, and `created_at`. It has no project owner, source record, revision chain, original file name, or DWG document identity.

The same migration defines `attachment_links`. A link has its own `id`, the physical `attachment_id`, `project_id`, source type/id, role, original file name, link `revision`, and lifecycle timestamps. Its supported sources and roles cover the current agenda/concrete domain, not DWG. Identity guards prevent changing an existing link's attachment/project/source/context identity.

`_applyInventoryFoundationMigration` defines the separate `inventory_asset_attachment_links` relation. `mobile/lib/application/inventory_application.dart` updates the Inventory link revision when a photo is replaced or archived and creates a new managed physical row for replacement bytes. That link revision is not the Inventory asset revision and is not a drawing-content revision.

The required identity boundaries are:

| Concept | Current representation | Meaning and DWG rule |
|---|---|---|
| Physical attachment identity | `managed_attachments.id`, path, size, SHA-256 | Identifies and verifies one immutable byte object. Reusable for original DWG bytes. It does not describe a drawing's revision lineage. |
| Link identity | `attachment_links.id` or `inventory_asset_attachment_links.id` | Identifies one project/source relationship and its archive/update lifecycle. Link `revision` tracks link mutation only. It must not become DWG content revision. |
| Source-record revision | Domain records such as observations, pours, assets, and sketches maintain their own revision fields | Protects optimistic updates to that domain record. It is independent of physical bytes and link revision. |
| Future DWG revision identity | No current table/model | Must identify one stable drawing document and ordered immutable source revisions, with the active revision explicit. It must reference physical attachments rather than overwrite them. |

Project ownership currently enters through link rows. `mobile/lib/application/attachment_catalog_application.dart` — `SqliteAttachmentCatalogApplication.listProjectAttachments` selects physical rows through `attachment_links.project_id` and groups links by physical attachment ID. Inventory uses its separate project-scoped relation. Consequently, adding a physical managed DWG row alone would not establish project adoption, a source record, or a revision chain.

The first-release `source-revision visibility` contract therefore needs a future explicit DWG revision model. Neither `managed_attachments.id`, a link `revision`, nor another source record's optimistic revision can safely substitute for it.

## 5. Derived vector-PDF cache and backup boundary

There is no suitable derived cache today:

- `attachments/managed` is reconciled as durable managed storage.
- `exports_backups` holds finalized exports/backups.
- `temp_staging` supports short atomic operations and recovery.
- no cache key combines original identity/hash, DWG revision, converter identity/version, and derived-format version;
- no invalidation or regenerate-on-miss service exists.

`mobile/lib/application/attachment_reconciliation_application.dart` — `SqliteAttachmentReconciliationApplication` treats a managed-pattern file with no `managed_attachments` row as an orphan finalized file and scans `.part` files as stale staging. A derived `.pdf` copied into `attachments/managed` without managed metadata would therefore be an orphan, not a cache entry.

Backup inclusion is relation-driven, not directory-driven. `mobile/lib/application/mobile_backup_application.dart` — `SqliteMobileBackupApplication._activeAttachmentRows` selects distinct managed paths whose IDs appear in either `attachment_links` or `inventory_asset_attachment_links`. The query does not filter archived links.

That produces three materially different outcomes:

| Placement/registration | Current backup result | Why it is not a valid derived cache design |
|---|---|---|
| File only under `attachments/managed` | Not enumerated; reconciliation reports an orphan when the name matches the managed pattern. | No ownership, cache key, or lifecycle. |
| `managed_attachments` row with no link | Not enumerated by backup creation. | Still uses the durable managed namespace; restore activation replaces the whole attachments root with the manifest set, so survival is neither promised nor cache-managed. |
| Managed row linked through either current relation | Automatically included, including when the link is archived. | A reproducible derived PDF would consume backup space and be restored as durable source data. |

Therefore the vector PDF must not be modeled as an ordinary linked managed attachment. A later dedicated derived-cache boundary must be excluded from backup enumeration by construction and be safe to delete/rebuild without affecting the original DWG, its revision metadata, or its file link.

## 6. Backup and restore proof

Current facts at the audited base are `AppDatabase.schemaVersion == 22`, `CseBackupCodec.formatVersion == 1`, and mobile version `0.1.0+1`.

`SqliteMobileBackupApplication._createBackupInside`:

1. checks SQLite integrity;
2. enumerates linked managed physical attachments through `_activeAttachmentRows`;
3. snapshots the database;
4. verifies each attachment's byte size and SHA-256; and
5. creates and verifies a package containing the manifest, database snapshot, and enumerated attachment bytes.

`CseBackupArchiveCodec.encode` stores attachment entries beneath `attachments/<relative path>`. Decode rejects unsafe paths, symlinks, duplicate/unexpected entries, oversize entries, and manifest size/hash mismatches.

Restore preparation validates the decrypted archive, database compatibility/integrity/foreign keys, manifest/database attachment relation, and actual attachment bytes. Restore activation moves the active database and entire active attachments directory to a rollback area, promotes the prepared database and prepared attachments root, revalidates them, and rolls back on failure.

These mechanisms are reusable for durable original DWG bytes only after the future DWG relation is part of authoritative backup enumeration and restore validation. Merely inserting `managed_attachments` metadata is insufficient because unlinked rows are not selected. The derived PDF cache should be absent from the package and regenerated after restore on first demand.

This audit finds no evidence that backup format version 1 must change solely because the original has a `.dwg` extension: the archive already carries safe logical paths, byte size, and SHA-256. It also does not prove that version 1 is sufficient for the future DWG schema. That compatibility decision belongs to the authorized schema/backup implementation and its migration tests.

## 7. Future cache regeneration contract boundary

The later cache owner must be able to decide deterministically that a derivative is stale or missing. At minimum, its identity needs inputs equivalent to:

- physical original attachment identity and SHA-256;
- stable DWG document identity and exact DWG revision identity;
- converter identity/version;
- derived artifact format/version; and
- generated artifact integrity metadata.

A missing, corrupt, incompatible, or source-mismatched derived PDF should cause safe cache invalidation and regeneration. It must never mutate or delete the original. Converter behavior, location, service provider, PDF renderer, and exact cache root remain deliberately undecided.

## 8. Decision matrix

| Architecture question | Decision | Evidence and consequence |
|---|---|---|
| Original DWG physical storage | `EXTEND_LATER` | Reuse managed safe-path/UUID/atomic-write/size/hash/inspect guarantees, but add explicitly authorized DWG MIME/magic/extension plus a proven size/streaming policy. Current code rejects `.dwg`. |
| Managed physical attachment identity and integrity | `REUSE` | `managed_attachments` and `DeviceManagedAttachmentStore.inspect` already separate immutable byte identity from computed integrity. |
| DWG metadata/link adoption | `NEW_REQUIRED_LATER` | Current generic and Inventory link relations cannot represent a DWG document/revision lifecycle. A new project-scoped DWG domain relation is required; exact schema is deferred. |
| Source revision model | `NEW_REQUIRED_LATER` | Physical attachment IDs, link revisions, and existing source-record revisions have different meanings; no DWG revision chain exists. |
| Derived vector-PDF cache root | `NEW_REQUIRED_LATER` | No current root has disposable, reproducible, backup-excluded cache semantics. Exact root is deferred. |
| Backup inclusion/exclusion | `EXTEND_LATER` | Future original-DWG relations must join backup enumeration; the dedicated derived cache must stay outside it. Current linked managed PDFs would be included, including archived links. |
| Restore behavior | `EXTEND_LATER` | Reuse manifest/hash/database validation and atomic promote/rollback for originals after relation adoption; restore no derived cache and regenerate later. |
| Cache regeneration | `NEW_REQUIRED_LATER` | No current cache key, invalidation, converter-version, or regenerate-on-miss service exists. |
| Schema need | `NEW_REQUIRED_LATER` | Stable DWG document/revision identity and derivative traceability cannot be represented without new metadata. No schema is selected or changed here. |
| Dependency/platform need | `SPIKE_REQUIRED` | Durable storage primitives exist, but large-file streaming and conversion/rendering feasibility are unproven. DWG-003/DWG-004 must decide without this audit selecting a dependency or platform. |

## 9. Constraints preserved

- Original DWG remains immutable durable source-of-truth.
- Derived vector PDF remains disposable/reproducible cache.
- Trial or subscription expiry must not delete the original, its revision metadata, or its file link.
- Coordinate/unit/trust-ready measurement architecture is not collapsed into attachment or link revision; real two-point measurement remains phase 2 and release-nonblocking.
- No vendor, cloud/local conversion mode, exact storage root, schema, renderer, dependency, or platform change is selected.
- No production, test, schema, backup, platform, or pubspec file is modified by this audit.
- No real DWG, build, test, analyzer, APK, or device execution is used as evidence.

## 10. Handoff to later DWG work

DWG-003 can use this audit to evaluate conversion/renderer and large-file constraints without reopening the immutable-original decision. DWG-004 can define the minimum schema/cache implementation only after converter/cache-key inputs are known. Any implementation must preserve the identity separation and backup boundary proved above.
