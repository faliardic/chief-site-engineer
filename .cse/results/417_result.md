# Issue #417 — V2.3a Attachment/Medya preflight sonucu

## 1. Sonuç ve kaynak revision

- Parent Epic: `#385`
- Validation class: `docs / persistence preflight`
- Examined source: `b117ab9ae41da1c486671c33d81e3ab9fde7ca59`
- Source tree: `4603e8923fb4a633ba973000cd8916fe8a086c39`
- Mobile schema: `12`
- Mobile backup format: `1`
- Production/test source change: none
- Real user database, backup or attachment byte inspection: none

Preflight conclusion:

1. Current mobile implementation has one sandbox attachment root but two
   owner-specific binary/metadata identities.
2. Schema 12 cannot represent one physical binary linked to multiple source
   records. A next schema is therefore required; the next executable child
   should use schema `13` unless its Issue finds a new repository fact.
3. Schema migration must preserve every legacy row and path 1:1. SHA equality
   is only a candidate index and never migration-time auto-merge authority.
4. Backup format `1` can remain because binary entries are still
   `logical_path + byte_size + sha256` and links remain in SQLite. Compatibility
   requires schema-aware restore auditing and synthetic schema-12 fixtures.
5. Canonical schema/adapters and format-1 compatibility must merge before the
   common-store, multi-link mutation and broad UI children.

No Issue #417 stop condition requires production implementation inside this
preflight. The executable decisions below remain proposals until their own
GitHub Issue authorizes code changes.

## 2. Exact current inventory

| Layer | Exact source | Current contract | Material gap |
| --- | --- | --- | --- |
| Sandbox roots | `mobile/lib/storage/app_directories.dart:15-123` | `cse_mobile/<environment>` contains `database`, `attachments`, `exports_backups`, `state`, and `temp_staging`; lexical root containment is checked. | A common directory is not a common identity/store. Store resolution does not inspect every symlink component. |
| Picker DTO/gate | `mobile/lib/platform/attachment_gateway.dart:3-53` | `AttachmentSource`, `SelectedAttachment`, `AttachmentPickerPort`, and `SafeAttachmentPicker`; camera/photo/file capabilities fail safely. | `SelectedAttachment` is one in-memory byte list; no multi-select/batch result. |
| Agenda store | `mobile/lib/platform/agenda_attachment_gateway.dart:31-231` | `DeviceAgendaAttachmentStore`; 20 MiB; JPEG/PNG sniff; `agenda/<logId>/<attachmentId>.<ext>`; `.part`, flush, staged re-read/hash, rename, read/inspect/cleanup. | Owner-specific path and interface; no global reconcile; no byte-size result; cleanup is not link-aware. |
| Concrete store | `mobile/lib/platform/concrete_attachment_gateway.dart:36-237` | `DeviceConcreteAttachmentStore`; 20 MiB; JPEG/PNG/HEIC/PDF; `concrete/<pourId>/<attachmentId>.<ext>`; `.part`, flush, rename, read/inspect/open/cleanup. | No staged temp re-read/hash before rename; MIME mismatch is folded into `tampered`; no global reconcile. |
| Concrete picker | `mobile/lib/platform/concrete_attachment_gateway.dart:269-313` | Camera/library use `ImagePicker.pickImage(imageQuality: 92)`; file picker accepts jpg/jpeg/png/heic/pdf with `allowMultiple: false`. | No video/audio, true multi-select or batch atomicity. |
| Agenda metadata | `mobile/lib/storage/app_database.dart:1724-1764` | Schema 7 introduced `agenda_log_attachments`; current schema 12 keeps it unchanged. | One row owns one physical path and one observation relation. |
| Concrete metadata | `mobile/lib/storage/app_database.dart:990-1024`, `1958-2029` | Schema 5 introduced and schema 7 rebuilt `concrete_attachments`; current schema 12 keeps it unchanged. | One row owns one physical path and one pour/optional-child relation. |
| Agenda application | `mobile/lib/application/agenda_application.dart:954-1107`, `1313-1532`, `3265-3341` | Create/attach stage first, then DB row/event transaction; failure cleanup; photo archive retains byte; read and Reminder projection inspect integrity. | No additional-link API, global orphan scan or photo restore API. |
| Concrete application | `mobile/lib/application/concrete_application.dart:1157-1258`, `1936-1941`, `3237-3315` | Source validation before stage and in transaction; duplicate-per-pour guard; row/revision/event transaction; failure cleanup; active read/open integrity. | No additional-link/archive/restore API or global reconcile. |
| Bootstrap | `mobile/lib/bootstrap/app_bootstrap.dart:131-161`, `195-198` | Separate Agenda and Concrete stores; one shared picker exposed under legacy field name `concreteAttachments`. | Picker sharing does not share metadata or bytes. |
| Agenda UI | `mobile/lib/features/agenda/log_form_page.dart:62`, `299-305`, `344-385`, `526-545`; `log_detail_page.dart:170-251`, `446-504` | Repeated single camera/gallery picks at create; detail attach/archive; archive text explicitly says physical byte remains. | No file picker, batch transaction, generic link or restore surface. |
| Agenda viewer | `mobile/lib/features/agenda/agenda_photo_viewer_page.dart:7-155` | In-memory thumbnail and `InteractiveViewer`; filename/MIME/size/hash and safe diagnostic. | Image-only. |
| Reminder projection | `mobile/lib/domain/agenda_models.dart:356+`; `mobile/lib/features/reminders/reminder_detail_page.dart:97-109`, `1249-1330` | `ReminderSourceAgendaMedia` deduplicates photo IDs and reads active Agenda photos without copying row/byte. | Projection is not an independent canonical link. |
| Concrete viewer | `mobile/lib/features/concrete/concrete_attachment_viewer_page.dart:8-200`; `concrete_pour_detail_page.dart:356-386`, `1008-1036` | Images render in memory; PDF opens externally through `open_filex`; metadata/diagnostic shown. | No video/audio player or thumbnail pipeline. |
| Backup | `mobile/lib/application/mobile_backup_application.dart:81-86`, `295-322`, `801-870`, `1003-1013`, `1107-1174`, `1349-1420` | Encrypted format 1; exact archive inventory; DB snapshot; attachment size/hash audit; staged migration; atomic DB+attachment swap/rollback. | Inventory is hard-coded to two legacy tables and does not reconcile orphan files in the live root. |
| Restore recovery | `mobile/lib/application/restore_recovery_application.dart:214-255` | Process-death recovery validates DB/FK and active Concrete attachment files. | Standalone recovery smoke does not audit Agenda rows or a future canonical link graph. |
| Platform policy | `mobile/pubspec.yaml:8-27`; Android manifest `:1-25`; iOS Info.plist `:29-32` | `file_picker`, `image_picker`, `open_filex`; CAMERA; broad storage/media permissions removed; iOS camera/photo purpose strings. | No video/audio/player/recorder dependency and no microphone purpose string. |

### 2.1 Agenda table, exact fields

`agenda_log_attachments` contains:

- `id` primary key;
- `observation_id + project_id` composite source FK;
- fixed `attachment_type = site_photo`;
- `original_file_name`, JPEG/PNG `mime_type`, positive `byte_size`, 64-char
  `sha256`, unique `relative_path`;
- nullable `description`, nullable `captured_at`;
- `revision`, `created_at`, `updated_at`, nullable `archived_at`;
- `UNIQUE(observation_id, sha256)`;
- physical-delete prohibition trigger.

Domain read model: `AgendaLogPhoto` and
`AgendaAttachmentIntegrity { ok, missing, tampered, invalidMime }` in
`mobile/lib/domain/agenda_models.dart:311-354`.

### 2.2 Concrete table, exact fields

`concrete_attachments` contains:

- `id` primary key and required `concrete_pour_id`;
- nullable `truck_id`, `sample_set_id`, `check_item_id`, with composite
  same-pour FKs and at-most-one CHECK;
- `evidence_type`, including legacy `delivery_receipt_scan` and canonical
  `delivery_note_scan` after the schema-7 rebuild;
- `original_file_name`, `mime_type`, positive `byte_size`, 64-char `sha256`,
  unique `relative_path`;
- required `captured_at`, nullable `description`, `created_at`, nullable
  `archived_at`;
- `UNIQUE(concrete_pour_id, sha256)`;
- physical-delete prohibition trigger.

Domain read model: `ConcreteAttachment` and
`ConcreteAttachmentIntegrity { ok, missing, tampered }` in
`mobile/lib/domain/concrete_models.dart:119-127`, `448-483`.

## 3. Current identity and link graphs

```text
AgendaLogPhoto.id
  ├─ owns one agenda/... physical path
  ├─ links exactly one observation + project
  └─ Reminder reads the same row as a projection

ConcreteAttachment.id
  ├─ owns one concrete/... physical path
  ├─ links exactly one concrete pour
  └─ optionally contextualizes one truck OR sample set OR check item
```

Consequences:

- A binary cannot have two source links without two metadata rows/paths.
- Hash uniqueness is owner-local, not global.
- `original_file_name`, description/capture context, source relation and
  physical digest/path live in the same row.
- Agenda and Concrete IDs are separate namespaces; a coincident UUID is not
  rejected globally.
- Reminder is correctly projection-only today and must not be migrated into a
  duplicate physical/link row.

## 4. Canonical schema proposal

### 4.1 `managed_attachments` — physical identity

Candidate fields:

| Field | Contract |
| --- | --- |
| `id` | Canonical UUID primary key; namespaced deterministic value for legacy migration. |
| `relative_path` | Non-empty portable relative path, globally unique, managed-root contained. Legacy paths stay unchanged during schema migration. |
| `mime_type` | Content-sniffed canonical MIME. |
| `byte_size` | Positive byte length. |
| `sha256` | Lowercase 64-char digest. |
| `created_at` | Canonical UTC time when the managed binary identity was created/migrated. |

Candidate indexes/invariants:

- `UNIQUE(relative_path)`;
- non-unique candidate lookup index on `(sha256, byte_size, mime_type)`;
- no unique hash constraint during legacy migration;
- no physical delete in the first executable schema;
- availability/integrity is a fresh reconciliation result, not a trusted stale
  status column.

`original_file_name`, description, capture time and archive/revision are not
physical identity. They belong to a contextual link so a shared byte may retain
different source snapshots.

### 4.2 `attachment_links` — contextual identity

Candidate fields:

| Field | Contract |
| --- | --- |
| `id` | Canonical link UUID; deterministic and source-namespaced for migration. |
| `attachment_id` | Required FK to `managed_attachments.id`. |
| `project_id` | Required project scope for every initially supported link. |
| `source_type`, `source_id` | Owning source record type/ID. Initial allowlist is Agenda observation or Concrete pour. |
| `context_type`, `context_id` | Optional exact context; initial allowlist is Concrete truck/sample/check. Both null or both non-null. |
| `role` | `site_photo` or exact Concrete evidence type; future values require an Issue/schema contract. |
| `original_file_name` | Link-local basename snapshot. |
| `description`, `captured_at` | Link-local source context. |
| `revision` | Positive optimistic revision. |
| `created_at`, `updated_at`, `archived_at` | Canonical lifecycle timestamps. |
| `legacy_source`, `legacy_id` | Nullable migration provenance; unique as a pair and never rewritten. |

Candidate constraints:

- supported source/context types are CHECK allowlists;
- unknown type, missing target and cross-project target fail closed;
- one active logical link per attachment/source/context/role via an expression
  unique index that normalizes null context;
- `UNIQUE(legacy_source, legacy_id)` for migrated rows;
- project/source/context immutability after create;
- physical delete prohibition; archive/restore changes lifecycle fields.

Polymorphic target FKs cannot be expressed by one ordinary SQLite FK. The
executable schema must pair CHECK constraints with type-specific INSERT/UPDATE
triggers and application validation, then repeat target/project validation in
the write transaction.

### 4.3 `attachment_link_events`

Candidate fields: `id`, `attachment_link_id`, positive `sequence`,
`event_type`, `occurred_at`, `payload_json`, with
`UNIQUE(attachment_link_id, sequence)` and append-only update/delete triggers.
Initial events: `link.created`, `link.archived`, `link.restored`,
`link.unlinked`. Existing Agenda/Concrete source events are not rewritten.

## 5. Legacy migration matrix

Both legacy tables migrate one row to one physical identity and one link.
Namespaced deterministic IDs avoid cross-table legacy-ID collisions. Existing
event payloads keep their original IDs; `legacy_source + legacy_id` resolves
them without historical rewrite.

### 5.1 Agenda

| Legacy value | Canonical destination |
| --- | --- |
| `agenda_log_attachments.id` | `attachment_links.legacy_id`; deterministic link ID seed `agenda_log_attachments:<id>`; deterministic physical ID seed `agenda_binary:<id>` |
| `relative_path` | `managed_attachments.relative_path`, unchanged |
| `mime_type`, `byte_size`, `sha256` | same physical fields |
| `created_at` | physical `created_at` and link `created_at` |
| `observation_id` | link `source_type=agenda_observation`, `source_id` |
| `project_id` | link `project_id` |
| `attachment_type` | link `role` |
| `original_file_name`, `description`, `captured_at` | link-local snapshots |
| `revision`, `updated_at`, `archived_at` | same link lifecycle fields |
| source provenance | `legacy_source=agenda_log_attachments` |

### 5.2 Concrete

| Legacy value | Canonical destination |
| --- | --- |
| `concrete_attachments.id` | `attachment_links.legacy_id`; deterministic link ID seed `concrete_attachments:<id>`; deterministic physical ID seed `concrete_binary:<id>` |
| `relative_path` | `managed_attachments.relative_path`, unchanged |
| `mime_type`, `byte_size`, `sha256` | same physical fields |
| `created_at` | physical `created_at`, link `created_at` and additive `updated_at` |
| `concrete_pour_id` | link `source_type=concrete_pour`, `source_id` |
| joined `concrete_pours.project_id` | link `project_id`; missing/mismatch aborts migration |
| one of `truck_id/sample_set_id/check_item_id` | exact link `context_type/context_id`; all null means no child context |
| `evidence_type` | link `role`, including legacy receipt value unchanged |
| `original_file_name`, `description`, `captured_at` | link-local snapshots |
| `archived_at` | link `archived_at` |
| no legacy revision/update field | additive link `revision=1`, `updated_at=created_at`; no legacy value is overwritten |
| source provenance | `legacy_source=concrete_attachments` |

### 5.3 Migration invariants

- Legacy row counts equal mapping counts per source table.
- Every mapping resolves one physical row and one link row.
- Every path, hash, size, MIME, filename, timestamp, archive state and target ID
  is equal to its legacy source value or documented additive default.
- No file is read, moved, renamed, copied, deleted or deduplicated in the SQLite
  schema transaction.
- Same SHA/size/MIME across rows produces separate physical identities and a
  `duplicate_legacy_candidate` diagnostic until a later store child verifies
  actual bytes and an explicit consolidation policy.
- Duplicate relative path across legacy namespaces, missing target/project,
  invalid context cardinality or deterministic-ID collision aborts the whole
  migration.
- Rollback leaves schema 12 and both legacy tables intact.
- Cutover must be atomic with compatibility query/write adapters; a merged
  release may not maintain unsynchronized legacy and canonical sources.

## 6. Target allowlist and project-scope contract

| Target/context | First canonical schema | Contract |
| --- | --- | --- |
| Agenda observation/log | `supported` source | Observation exists; link project equals observation project. Archived observation remains historical; new link requires active source. |
| Reminder source media | `projection-only` | Resolve the Agenda link/photo; create no reminder-owned link or binary. |
| Concrete pour | `supported` source | Pour exists; link project equals pour project. New link requires active/eligible source. |
| Concrete truck | `supported` context | Truck exists and belongs to the same pour/project. |
| Concrete sample set | `supported` context | Sample set exists and belongs to the same pour/project. |
| Concrete check item | `supported` context | Check exists and belongs to the same pour/project. |
| Project | `supported scope-only` | Required `project_id`; not a standalone source link in schema 13. Project-album behavior remains V2.11. |
| Project location/Mahal | `deferred` | Initially derived through the source record. Direct context needs an explicit same-project adoption child. |
| Workforce person/Sicil | `deferred` | V2.2 intentionally added no person attachment. Requires explicit use case, role and archive visibility. |
| Job/İş Zinciri | `deferred` | No V2.6/V2.7 source table exists yet. Unknown future ID cannot be stored early. |
| Unknown type | unsupported | DB CHECK/application rejects; never reinterpret or silently retarget. |

Validation order for every new/additional link:

1. validate IDs/type/role before staging;
2. resolve active source/context and exact project;
3. stage/verify only if a new binary is required;
4. repeat target/project validation inside the DB transaction;
5. insert link, source event and link event atomically;
6. stale, missing, archived-new-target or cross-project input fails closed.

Target archive does not silently archive/delete a link or byte. Historical
visibility derives from both link lifecycle and source lifecycle. A new active
link cannot target an archived source/context.

## 7. Lifecycle, retention and delete matrix

| Operation/state | Canonical result |
| --- | --- |
| Attach a new binary | Validate all targets, stage/flush/re-read/hash, finalize, then one DB transaction creates physical row, links and events. |
| Add a link to an existing binary | Reconcile physical identity as healthy; write link/events only; no byte copy. |
| Archive source target | Preserve link and byte. Normal active UI may hide it; historical view remains resolvable. |
| Archive attachment in one source UI | Archive that link only, increment revision and append event. Physical identity is unchanged. |
| Unlink | Recoverable link archive with explicit `link.unlinked` event; not DELETE. |
| Restore link | Same link ID; target must still exist and be same-project. An archived target is not reactivated implicitly. |
| All links archived | Retain physical byte. New canonical backups include it as historical managed data. |
| Hard-delete link metadata | Forbidden in initial executable children. |
| Hard-delete physical byte | Forbidden while any active/historical link exists. General purge policy is a separate explicit Issue. |
| Orphan finalized file | Retain and report. No automatic adoption, delete or guessed owner. |
| Stale staging file | Report separately. Cleanup requires exact managed staging policy and must not scan user areas. |
| Missing physical file | Link remains; read/open blocked; visible diagnostic; required backup fails closed. |
| Hash/MIME/size mismatch | Link remains; read/open blocked; visible diagnostic; backup fails closed. |
| Broken/cross-project target | Link remains historical; no silent retarget; diagnostic and new mutation fail closed. |

## 8. Integrity/reconciliation result matrix

| Result | Required checks/action |
| --- | --- |
| `healthy` | Safe managed path; regular non-symlink file; exact size/hash/content MIME; all targets same-project and resolvable. |
| `missing_file` | Metadata/link exists, file absent. Do not read/open or emit successful full backup. |
| `size_mismatch` | Separate from hash mismatch for diagnosis. |
| `hash_mismatch` | Exact digest differs. Do not relabel or rewrite metadata. |
| `mime_mismatch` | Magic-byte MIME differs/unsupported; separate from tamper. |
| `unsafe_path` | Absolute/traversal/outside root, symlink component or non-regular file. Never follow/open/delete automatically. |
| `broken_target` | Source/context row absent or invalid cardinality. Preserve evidence and fail new mutation. |
| `cross_project_target` | Link/source/context project mismatch. Fail closed; never coerce project. |
| `orphan_finalized_file` | Managed final file has no physical metadata identity. Report only. |
| `stale_staging_file` | Managed staging entry is outside any live operation. Report separately. |
| `duplicate_legacy_candidate` | Multiple physical identities share hash/size/MIME. Do not migration-merge. |

Current mobile gaps that V2.3c must close:

- Agenda has distinct invalid MIME but Concrete folds it into tampered.
- Neither store inspect compares recorded byte size.
- Store resolution is lexical and lacks the PC store's full symlink/component
  defense.
- No mobile root scan identifies orphan finalized or stale staging files.
- Current backup enumerates DB rows and does not reject extra orphan files in
  the live attachment root.

The PC `ManagedAttachmentStore` in `app/storage/attachments.py:54-570`
provides useful staging, fsync, symlink and reconciliation concepts. Its
`attachments` table (`app/persistence/schema.py:54-66`) still directly owns one
observation and is not the mobile canonical schema.

## 9. Atomicity and compensation contract

Selected model: **all-or-nothing application result with file compensation and
restart reconciliation**.

```text
validate every source/context/project
→ sniff/hash all selected inputs
→ reuse one verified existing physical identity where exact byte equality is proven
  OR stage every new unique binary
→ flush + re-read + size/hash/MIME verify all staging files
→ finalize all new files
→ repeat target/project validation in one SQLite transaction
→ insert physical rows, links, source events and link events
→ commit
```

Failure matrix:

| Failure point | Required outcome |
| --- | --- |
| Validation or staging failure | No DB mutation; discard only this operation's exact staging descriptors. |
| One finalize fails after earlier finalizes | No DB mutation; compensate all newly finalized files from this operation. Cleanup failure becomes visible orphan diagnostic. |
| Finalize succeeds, DB transaction fails/stales | Roll back DB; delete only newly finalized, unreferenced files. Reused existing bytes are never cleaned. |
| Process dies after finalize, before DB commit | Restart reconciliation reports orphan finalized files; no guessed link. |
| DB commit succeeds | Every returned link exists; no partial per-file success is reported. |
| Existing binary reuse | Re-hash existing file and compare selected bytes, size and MIME; SHA equality alone is insufficient. |

This ordering prevents `DB committed / file finalize failed` by design. SQLite
is never committed before all required files are final and verified.

## 10. Schema decision

**Decision proposal: schema 13 is required.**

Proof:

- Schema 12 stores physical metadata and contextual owner in the same row.
- Both legacy tables require one unique path per row.
- Neither table can point two contextual rows at one physical identity.
- A common link table cannot be added without a new migration and application
  cutover.

Schema 13 must be additive/cutover-safe at the transaction boundary. It must
not move bytes. The executable child must create/populate/verify canonical
tables and update compatibility reads/writes in the same branch; shipping dual
unsynchronized truth is prohibited. Downgrade remains unsupported. Any need to
move/dedupe actual files moves to V2.3c after schema migration is complete.

## 11. Backup format 1 compatibility matrix

Current exact behavior:

- `CseBackupCodec.formatVersion = 1`.
- Manifest `BackupManifestFile` contains only `logical_path`, `byte_size`,
  `sha256` (`mobile/lib/domain/mobile_backup_models.dart:8-39`).
- `_activeAttachmentRows` selects active Concrete rows plus all Agenda rows,
  including archived Agenda (`mobile_backup_application.dart:1349-1359`).
- Restore demands exact manifest/DB row/path/size/hash equality and swaps DB +
  attachment root atomically.

| Scenario | Required schema-13 behavior |
| --- | --- |
| New schema-13 backup | One manifest entry per canonical physical identity, even with many links; DB snapshot carries all links/events. |
| Active/historical links | Include every physical byte referenced by canonical active or historical links; missing/tampered/unsafe/orphan state blocks a successful full backup. |
| Schema-12 format-1 restore | Stage old DB/files, run deterministic 12→13 migration, then audit using the original schema-12 inclusion rule: active Concrete + all Agenda. |
| Archived Concrete in old backup | Format 1 historically did not require its byte. Preserve its row/link; if byte is absent, expose `missing_file` after migration rather than inventing content or failing an otherwise valid legacy manifest. |
| Archived Agenda in old backup | Byte is required and must remain exact. |
| Same physical, many links | One archive file; every link survives in SQLite and resolves to the same attachment ID. |
| Duplicate legacy candidates | Keep separate paths/physical IDs in the first migration and manifest; no auto-merge. |
| Restore process death | Recovery must audit canonical physical rows and link FKs/project/targets, not only active Concrete rows. |
| Extra/orphan archive entry | Existing exact-entry rejection remains. |
| Live-root orphan before backup | New reconciliation blocks successful full backup until explicitly classified; no silent omission. |

Format `1` need not change because its physical-file manifest is already
independent of owner/link metadata. A format bump is a stop condition if the
executable fixture disproves this matrix.

Required synthetic compatibility fixtures:

- schema 12 with active/archived Agenda and Concrete rows;
- same SHA under different legacy rows/paths;
- cross-table UUID collision fixture;
- source/context/project mismatch rollback;
- schema-12 format-1 restore into schema 13;
- schema-13 format-1 round-trip with one physical identity and at least two
  links;
- missing archived Concrete byte in a valid legacy package;
- missing archived Agenda byte fail-closed;
- post-swap failure and process-death recovery with canonical rows/links.

## 12. Existing executable evidence and gaps

Reused current tests:

- `mobile/test/agenda_application_test.dart:1165` — staging, attach,
  diagnostics, archive, restart and compensation.
- `mobile/test/agenda_application_test.dart:1281`, `1391` — Reminder source
  media ordering/read-only/archive/trash and integrity states/photo-ID dedupe.
- `mobile/test/concrete_attachment_gateway_test.dart:30`, `61` — MIME/hash,
  atomic logical path, tamper, spoof, traversal, size and collision.
- `mobile/test/concrete_application_test.dart:1037`, `1202` — exact
  pour/child links, source validation, duplicate and DB-failure cleanup.
- `mobile/test/mobile_agenda_widget_test.dart:1830` — camera denial preserves
  form and creates no row.
- `mobile/test/reminder_widget_test.dart:691-854` — source photo viewer and
  safe diagnostics.
- `mobile/test/concrete_widget_test.dart:302-346` — evidence metadata and
  current image viewer.
- `mobile/test/app_database_test.dart:758`, `1110`, `2205` — schema 4→5,
  schema 6→7 and rollback evidence.
- `mobile/test/mobile_backup_application_test.dart:138`, `392`, `589`,
  `907-1106` — schema-12 format-1 round-trip, full fixture, rollback,
  manifest/path/hash/size/missing-file fail-closed behavior.
- `mobile/test/restore_recovery_application_test.dart:41-131` — journal phase
  recovery and safe relative metadata.
- `mobile/test/platform_notification_configuration_test.dart:15-23`, `84-88`
  — CAMERA/purpose strings and broad media permission removal.

Missing executable contracts are exactly the schema-13/many-link/migration,
global reconciliation, batch atomicity, video/audio/player and canonical
backup cases listed above. No current test was edited to pretend these exist.

## 13. Verified child sequence

1. **V2.3a — Issue #417:** contract/migration/backup preflight.
2. **V2.3b:** schema 13 canonical physical/link/event tables, deterministic
   schema-12 migration, compatibility application queries and backup format-1
   migration/restore audit.
3. **V2.3c:** common managed store, staged re-verification, symlink-safe path
   handling and global integrity/reconciliation.
4. **V2.3d:** Agenda/Concrete canonical link mutations and only explicitly
   authorized V2.2 source-link adoption.
5. **V2.3e:** multi-select/batch UX and basic supported viewer/player surface.
6. **V2.3f:** backup/restore/restart and data-preserving device closure.

Camera/microphone recording and their permission/privacy/release gates remain a
separate optional child unless repository truth later proves they are required
for V2.3 closure. V2.11 project album and V2.4 Ajanda behavior do not enter
these children.

## 14. First executable child — exact proposed contract

Proposed title:

`CSE V2.3b: schema 13 canonical attachment/link foundation and schema-12 migration`

Validation class: `persistence`.

### Exact production allowlist

- `mobile/lib/storage/app_database.dart`
- `mobile/lib/application/agenda_application.dart`
- `mobile/lib/application/concrete_application.dart`
- `mobile/lib/application/mobile_backup_application.dart`
- `mobile/lib/application/restore_recovery_application.dart`
- `mobile/test/attachment_schema_migration_test.dart`
- `mobile/test/app_database_test.dart`
- `mobile/test/agenda_application_test.dart`
- `mobile/test/concrete_application_test.dart`
- `mobile/test/mobile_backup_application_test.dart`
- `mobile/test/restore_recovery_application_test.dart`
- `docs/project_decisions.md`
- that Issue's `.cse/tasks/<issue>_task.md` and
  `.cse/results/<issue>_result.md`

No platform store, picker, UI, manifest, dependency, permission or media byte
move belongs to V2.3b.

### Focused validation

- schema-12 synthetic migration/mapping/collision/rollback fixture;
- schema-13 fresh install invariants/FK/triggers;
- Agenda/Concrete current attach/read/archive/detail regressions on canonical
  queries;
- schema-12 format-1 restore→13 and schema-13 format-1 many-link round-trip;
- restore process-death recovery against canonical physical/link graph;
- one full `flutter test --no-pub` because schema/backup source changes;
- `flutter analyze --no-pub`;
- `git diff --check` and exact allowlist/protected-path checks.

Debug/release build, signing, AAB, permission and physical-device gates are not
minimum sufficient for behavior-preserving schema/adapter work. Synthetic temp
database/filesystem integration is required; real user data remains forbidden.

### V2.3b stop conditions

- format-1 bump becomes necessary;
- file move/read/dedupe is needed during schema migration;
- legacy field/ID/path/archive/context cannot map exactly;
- canonical and legacy truth must coexist unsynchronized;
- cross-project validation cannot be enforced by DB + application;
- production UI/platform/permission changes are required;
- migration/full affected suite/backup rollback fails after the single allowed
  correction/retry budget.

## 15. Issue #417 validation and safety evidence

- Required canonical sources, Issue #417 body and all comments were read.
- Linked worktree was created directly from exact `origin/master` and began at
  divergence `0 0`, with a clean tracked/untracked state.
- Repository/schema/store/application/UI/test inspection was read-only.
- Broad Flutter/Python/analyze/build/device gates were intentionally not run:
  executable source did not change and this Issue is documentation/preflight.
- No real user data root, backup package, attachment file, report or device was
  read or mutated.
- Original dirty official worktree was not switched, restored, reset, cleaned,
  stashed or written.
- Changed-file allowlist before publication is limited to this task file and
  result file.
- Primary run count: `1`.
- Blocking correction/retry count: `0`.

Commit, push, divergence, Draft PR and final Git status are reported in Issue
#417 completion evidence after the publication gates pass; they are not
predicted inside this result artifact.
