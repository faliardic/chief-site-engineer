# Issue #525 — Inventory Map v1 Slice 6 execution task

## Authority and routing

- Parent / V2 item: Issue #506, Inventory Map v1; Slice 6 multi-floor model and Kat Görünümü.
- Canonical authority: Issue #525 comment `5460048885`.
- Expected base: `f858740f6975bace9b6efd21deb1f679e4489cbf` (`origin/master`).
- Canonical branch: `codex/issue-525-inventory-multifloor`.
- Risk: R4 (schema migration, persistent placement history, cross-floor UX).
- Requested model / effort: `gpt-5.6-sol` / `max`.
- Runtime actual model / effort: `unknown` / `unverified`.
- First repository write: this file.

## Canonical source manifest (SHA-256)

| Source | SHA-256 |
| --- | --- |
| `AGENTS.md` | `BB00551CAECBD2C19AF6CCFF0FE9C93ACFA71AADE05288B303F6006BE0BE616D` |
| `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md` | `5899A8FE03E8AB7CA8CE204DDF7A271686BDA0668B08A828645649495539E333` |
| `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md` | `F2C00B649CD1DCEB19DC0BD1D284713138DBFBD8EE3332B9581AFD107A0C20D5` |
| `docs/protocols/CSE_MODEL_REASONING_ROUTING_POLICY.md` | `E1F55336657ECD79CB68CBAE458341A811F0BB33867AC06B71163A5A8C8C320B` |
| `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md` | `C12A57885F31144DC15CBBD3A07AB59527489A533CE5D8B444664ECF7710440D` |
| `docs/protocols/CSE_WORKFLOW_ACCELERATION_PROTOCOL.md` | `7765BCEBFB7B25B12E60FB44767D49C9D537393786FA0026561E1593073D297D` |
| `docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md` | `B1685CE1610593195282B3B7C9038009EF8CD365D7C1314CB2356FC425BB383A` |
| `docs/protocols/CSE_PROJECT_SOURCE_REGISTER.md` | `F96FC9B1EF8BD12A6A4515A707726D84EE9A86A1A28BF6F20C5217E2954212CB` |
| `docs/protocols/CSE_CODEX_INSTRUCTION_COMMENT_PROTOCOL.md` | `E6585E4A217D63D6717973121512338A3EDFD24091C3EB0DF6EA573EC8A797C6` |
| `docs/v2/CSE_V2_SCOPE.md` | `3FB70A0C80C293B17A38214F4B717C1BAFE539526289EAF86A0BE1D4683AEE51` |
| `ROADMAP.md` | `5881856940260AE79961DA2D8896B901B9155FFEC1906285EF15ACBF994C6166` |
| `docs/v2/CSE_INVENTORY_MAP_V1_CONTRACT.md` | `6ED6285A565D5CC032116B5643F5565757D97ACB7ACC8325188F19DC8CD0BBCA` |

## Source-truth lock

### Existing single-primary-sketch assumptions

- Schema 20 permits exactly one non-archived primary `inventory_sketches` row per project and keeps one shared active/draft revision chain.
- Every placement version points to that sketch and to the exact active provenance revision used when the version was inserted.
- Page and map controllers currently load one primary sketch plus all project assets; map projection assumes every active asset has one active placement on that sketch.
- Quick create, move, unarchive, list-to-map focus and cluster grouping are currently x/y-only and project/sketch scoped; no floor identity exists.
- Sketch create persists an empty DRAFT; first finalize makes it ACTIVE. Edit-active creates a new DRAFT on the same sketch revision chain.
- Slice 6 will not create per-floor sketches, geometry copies, or parallel revision chains. The existing shared sketch and geometry lifecycle remains canonical.

### Schema-20 placement/sketch relationship

- `inventory_asset_placements` is an immutable version chain keyed by stable `placement_key`; only the one-way terminal transition (`ended_at` + `end_reason`) updates an existing row.
- Composite foreign keys preserve exact asset, sketch, provenance revision and predecessor identity/project relations.
- The predecessor trigger requires the same placement key, asset and sketch, the next sequence, and a terminal predecessor.
- Active placement inserts require the current active revision of the non-archived sketch and an active asset; active placement quantity equals the single asset quantity contract.
- Asset/sketch/event/receipt/photo-link tables and existing placement ids, keys, sequences, sketch ids, provenance ids, x/y and terminal history are preservation-critical.

## Exact schema-21 migration design

The migration is additive and executes inside the existing `AppDatabase.open()` migration transaction:

1. Bump only `AppDatabase.schemaVersion` from 20 to 21 and append migration 21.
2. Create `inventory_floors` with stable `id`, exact `project_id`, positive contiguous `ordinal`, trimmed display name (1..80 runes enforced in application; 1..80 characters guarded in SQL), optimistic `revision`, canonical `created_at`/`updated_at`, and unique `(id, project_id)` plus `(project_id, ordinal)`.
3. Add `floor_id TEXT REFERENCES inventory_floors(id)` to `inventory_asset_placements`; SQLite requires this new column to be nullable during `ALTER TABLE`.
4. Before backfill, fail closed if any existing placement cannot resolve its exact project/asset/sketch/provenance/predecessor graph or if existing Inventory foreign keys are invalid.
5. Create exactly one deterministic floor for every project represented by an Inventory sketch or placement. Its id is `_migrationStableUuid('inventory-floor-v1:' + project_id)`, name is `1. Kat`, ordinal is `1`, revision is `1`, and both timestamps reuse that canonical project's `projects.created_at` value.
6. Temporarily drop only `inventory_asset_placements_terminal_update` and `inventory_asset_placements_project_available_update`, because the controlled backfill must update historical and possibly archived-project placement rows. Update only the new `floor_id` column on every existing placement version.
7. Verify exact backfill cardinality and integrity: one default floor per relevant project; no placement with null/missing/cross-project floor; all pre-existing preservation-critical columns remain byte-for-byte unchanged in the migration regression fixture.
8. Recreate the terminal and project-availability triggers. The recreated terminal trigger adds `floor_id` to immutable placement source fields.
9. Add insert guards requiring non-null floor identity and exact `(floor_id, project_id)` ownership. Add floor guarded-update, canonical timestamp, project-availability and no-physical-delete triggers.
10. Add a floor-aware placement index on `(project_id, floor_id, sketch_id, ended_at, y, x, id)`.
11. Do not rebuild, rename or drop an existing table; do not update/delete any pre-existing column or user row outside the controlled new `floor_id` backfill.

This design is safe because all changes and verification occur in the migration transaction: any preflight, backfill or postflight failure rolls schema 21 back completely, leaving the schema-20 database intact.

## Locked application architecture and contracts

- One shared sketch geometry/revision chain per project.
- Stable `InventoryFloorRecord` identities; rename changes only display name, revision and updated timestamp, while id and ordinal remain immutable.
- Initial floor count is requested only for first-sketch finalization; application creates `1. Kat ... N. Kat` atomically before that first ACTIVE revision is published. Edit-active finalize cannot create or replace floors.
- Floor rename is an optimistic transactional row mutation. Existing Inventory receipt/event tables are not rebuilt and their vocabulary is unchanged; authority requires stable identity plus revision/timestamps for this rename boundary.
- `floor_id` is part of every new placement version. Quantity changes retain it. Same-floor moves create the usual successor with the same floor; cross-floor moves create the usual successor with a different floor while preserving the full placement chain.
- Quick create receives the selected floor through an allowlisted floor-scoped application delegate; `inventory_asset_quick_form.dart` remains untouched.
- Kat Görünümü shows ordered floors and active-record counts; Genel/Tümü shows all floors and total. Selecting a floor changes only projection/filter context, never shared geometry.
- Map receives only active placements on the selected floor; clustering therefore remains floor-local. Target selection retains priority over marker/cluster actions.
- List shows canonical floor label and offers all/specific floor filtering. List-to-map focus selects the asset's exact floor before switching to map, then pans to exact x/y and preserves the existing two-second non-color-only focus indicator.
- Move/unarchive target capture uses the currently selected floor and keeps project-boundary cancellation semantics.
- Production backup/restore source, backup format, attachment-store semantics, photo links, platform/permissions/packages and app version remain unchanged.

## Exact writable allowlist (17 paths)

1. `.cse/tasks/525_task.md`
2. `.cse/results/525_result.md`
3. `mobile/lib/storage/app_database.dart`
4. `mobile/lib/domain/inventory_models.dart`
5. `mobile/lib/application/inventory_application.dart`
6. `mobile/lib/features/inventory/inventory_page.dart`
7. `mobile/lib/features/inventory/inventory_map_view.dart`
8. `mobile/lib/features/inventory/inventory_sketch_editor_page.dart`
9. `mobile/lib/features/inventory/inventory_asset_detail_sheet.dart`
10. `mobile/test/inventory_schema_migration_test.dart`
11. `mobile/test/inventory_application_test.dart`
12. `mobile/test/inventory_asset_core_test.dart`
13. `mobile/test/inventory_page_test.dart`
14. `mobile/test/inventory_sketch_editor_test.dart`
15. `mobile/test/mobile_backup_application_test.dart`
16. `docs/v2/CSE_INVENTORY_MAP_V1_CONTRACT.md`
17. `docs/v2/CSE_V2_SCOPE.md`

Any additional path, unsafe migration condition, protected-source need, unknown production/debug data risk or new product decision is an immediate fail-closed stop.

## Required regression proof

1. Populated schema-20 fixture migrates to schema 21 with one deterministic floor and byte-for-byte preservation of shared sketch/revisions, assets, every placement version/key/x/y, events, receipts and photo links.
2. First finalize auto-generates ordered floors and rejects invalid/replayed floor creation.
3. Rename `2. Kat` to `Bodrum Kat` preserves floor id, ordinal and placement ownership.
4. Quick create persists the selected floor.
5. Same-floor and cross-floor move both append a successor and preserve predecessor history/floor ownership.
6. Per-floor active counts and all-floor total are canonical.
7. Selected-floor map projection isolates markers.
8. Cluster grouping/chooser/zoom/focus behavior remains floor-local and target-selection precedence remains intact.
9. List shows floor label and filters by floor.
10. List tap selects exact floor, opens shared map at exact x/y and keeps two-second focus.
11. Relaunch reloads stable floors, names, selected data and placements.
12. First-sketch and edit-active draft recovery remain valid; only first finalize asks for floor count.

## Validation and publication budget

- Format touched Dart files only.
- Exactly one focused application-test invocation:
  `flutter test --no-pub test/inventory_schema_migration_test.dart test/inventory_application_test.dart test/inventory_asset_core_test.dart test/inventory_page_test.dart test/inventory_sketch_editor_test.dart test/mobile_backup_application_test.dart`
- At most one retry only for a proven same-scope mechanical test-harness defect.
- After focused PASS, run `flutter analyze --no-pub` once; at most one mechanical lint-only retry if authority permits.
- Run `git diff --check` and exact allowlist/protected/schema21/backup1/version0.1.0+1/pubspec/platform/permission/package/artifact/worktree/divergence audits.
- Automated application tests are explicitly enabled only for the focused invocation above. No full suite, build, APK, emulator, ADB, device or MAIN-package operation.
- Manual smoke IDs will be appended to Issue #479 as `PENDING`; no PASS will be inferred.
- If gates pass: minimal implementation commit(s), normal push, one OPEN/DRAFT PR referencing #525 and #506, Issue/PR evidence, then stop for fresh independent R4 review.
- Ready=false; merge=false; Slice 7 not started.

## Stabilization / correction budget

- Primary implementation window: 1.
- Same-scope narrow corrections: maximum 3 under repository protocol, subject to the stricter current authority gates.
- Environment-only recovery: maximum 1 after exact root-cause proof.
- Immediate escalation: unsafe migration, allowlist expansion, schema/backup/version/permission/platform drift, destructive action, or inability to preserve stable identity/history.
