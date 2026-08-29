# Issue #527 — Inventory Spatial v1 Revised Slice 6.1

## Authority and execution identity

- Repository: `faliardic/chief-site-engineer`
- Official local root: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Parent / V2 item: Epic #506 / Inventory Map v1 Slice 6.1
- Canonical Issue: https://github.com/faliardic/chief-site-engineer/issues/527
- Canonical owner authority: https://github.com/faliardic/chief-site-engineer/issues/527#issuecomment-5460841100
- Expected base branch: `master`
- Expected base SHA: `f858740f6975bace9b6efd21deb1f679e4489cbf`
- Canonical branch: `codex/issue-527-inventory-spatial-foundation`
- Superseded historical PR/head: PR #526 / `d0267a7df6a6ea3646de943790484580d32ecc04`
- Critical source-truth rule: PR #526 is closed-unmerged historical evidence only. It must not be merged, rebased, cherry-picked, or mechanically transplanted.

## Preflight evidence

- Official repository root: verified exact.
- Branch: `codex/issue-527-inventory-spatial-foundation`.
- HEAD: `f858740f6975bace9b6efd21deb1f679e4489cbf`.
- `origin/master`: `f858740f6975bace9b6efd21deb1f679e4489cbf`.
- Master divergence: `0/0`.
- Local/remote canonical branch initially point to the exact base.
- Tracked/staged/untracked project changes before first write: none.
- Current schema: `20`.
- Backup container format: `1`.
- Mobile version: `0.1.0+1`.
- PR #526: closed, Draft, unmerged; its head implementation is absent from this branch.
- Manual Test Register #479: no existing `MT-527-*` entries at task start.

## Canonical source manifest

| Source | SHA-256 |
| --- | --- |
| `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md` | `5899a8fe03e8ab7ca8ce204ddf7a271686bda0668b08a828645649495539e333` |
| `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md` | `f2c00b649cd1dceb19dc0bd1d284713138dbfbd8ee3332b9581afd107a0c20d5` |
| `docs/protocols/CSE_MODEL_REASONING_ROUTING_POLICY.md` | `e1f55336657ecd79cb68cbae458341a811f0bb33867ac06b71163a5a8c8c320b` |
| `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md` | `c12a57885f31144dc15cbbd3a07ab59527489a533ce5d8b444664ecf7710440d` |
| `docs/protocols/CSE_WORKFLOW_ACCELERATION_PROTOCOL.md` | `7765bcebfb7b25b12e60fb44767d49c9d537393786fa0026561e1593073d297d` |
| `docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md` | `b1685ce1610593195282b3b7c9038009ef8cd365d7c1314cb2356fc425bb383a` |
| `docs/protocols/CSE_PROJECT_SOURCE_REGISTER.md` | `f96fc9b1ef8bd12a6a4515a707726d84ee9a86a1a28bf6f20c5217e2954212cb` |
| `docs/v2/CSE_V2_SCOPE.md` | `e9b28ce2c682126278841edd45a8f53d0f04a4d520019f5ef0186c1094a50a86` |
| `ROADMAP.md` | `5881856940260ae79961da2d8896b901b9155ffec1906285ef15acbf994c6166` |

## Model routing

```yaml
model_routing:
  policy_version: "CSE-MRP-1.0"
  task_risk: "R4"
  orchestrator:
    chatgpt_model: "gpt-5.6-sol"
    chatgpt_reasoning_effort: "max"
  codex_model: "gpt-5.6-sol"
  codex_reasoning_effort: "max"
  execution_mode: "standard"
  orchestration: "single-agent"
  selection_reason: "Direct schema migration, durable spatial identity, placement history and geometry integrity change."
  routing_request_evidence: "Issue #527 comment 5460841100"
  allowed_fallback: null
  review_floor:
    chatgpt_model: "gpt-5.6-sol"
    chatgpt_reasoning_effort: "max"
  fail_closed_if_mismatch: true
```

Invocation/runtime model metadata is not exposed by the execution surface and must be recorded as `unknown / null / unverified`, not inferred.

## Validation class and changed contracts

- Validation class: `persistence` / R4.
- Automated application tests: explicitly authorized by current owner authority for the exact focused six-file Flutter test set.
- Changed contracts:
  - direct additive schema `20 -> revised 21`;
  - project-owned stable blocks / closed areas;
  - block-owned stable ordered floors;
  - immutable sketch-revision polygon to stable block linkage;
  - placement ownership through stable `floor_id`, deriving block through the floor;
  - deterministic schema20 default block/floor backfill without placement-history rewrite;
  - straight-segment closed-polygon creation, metadata gate and overlap/integrity rejection;
  - current exposed Inventory placement writes always resolve a valid same-project block/floor context.

## Locked source design

1. Preserve geometry v1 canonical JSON and every historical sketch/revision byte and checksum. Do not reinterpret or rewrite schema20 geometry.
2. Add normalized schema21 spatial sources:
   - `inventory_blocks`: stable project-owned identity, bounded normalized name, stable order and lifecycle-ready `ACTIVE | DETACHED | ARCHIVED` state;
   - `inventory_floors`: stable block-owned identity, stable positive ordinal and bounded mutable display name;
   - `inventory_sketch_revision_block_polygons`: immutable mapping from exact sketch revision + polygon index to one stable block;
   - additive `inventory_asset_placements.floor_id`, backfilled for all active and historical placements and required for every future placement version.
3. Validate schema20 relationships before the first schema21 mutation. Any corrupt/cross-project source fails inside the single database-open transaction so DDL/backfill rolls back atomically.
4. For every project with Inventory spatial data, create one deterministic UUID default block named `Varsayılan Alan`, one deterministic UUID floor named `1. Kat`, and backfill every historical placement to that floor without changing placement ID/key/sequence/x/y/quantity/end/predecessor truth. The migrated default block is `DETACHED` until a polygon is explicitly linked later.
5. Active block names are unique under the existing Inventory Turkish-aware normalization. Floors use stable ordinal `1..N`; identity is independent of display name.
6. New block polygons are validated separately from preserved legacy geometry: at least three distinct vertices, non-zero area, no self-intersection, and no ambiguous overlap/touch/containment with another active block polygon.
7. Finalize carries bounded block definitions for newly completed polygons. Existing mapped polygons retain the same block IDs across revisions; this slice does not implement reshape/detach/reattach lifecycle UI.
8. Initial new sketches finalize only with closed, metadata-complete block polygons. Existing legacy geometry remains readable and immutable; edit flow may append safe new block polygons without rewriting existing mapped geometry.
9. Placement create/move/unarchive infers a deterministic same-project floor from the active revision and target point. Within the same block it preserves the existing floor; otherwise it uses the target block's matching ordinal when available, then ordinal 1. Migrated single detached-default projects remain usable. Unowned, cross-project or ambiguous placement writes fail closed before persistent mutation.
10. Straight-line UX remains tap/direction based: each committed edge is one straight segment at any angle. The allowed editor page adds a live proposed-edge preview, bounded first-vertex snap, explicit `Alanı kapat`, and a dedicated block-name/floor-count prompt after closure. Undo/cancel/autosave/revision safety remains intact.
11. Slice 6.2 floor navigation and Slice 6.3 block move/reshape/detach/reattach UI are not implemented.

## Exact modification allowlist

1. `.cse/tasks/527_task.md`
2. `.cse/results/527_result.md`
3. `mobile/lib/storage/app_database.dart`
4. `mobile/lib/domain/inventory_models.dart`
5. `mobile/lib/application/inventory_application.dart`
6. `mobile/lib/features/inventory/inventory_sketch_editor_page.dart`
7. `mobile/lib/features/inventory/inventory_page.dart`
8. `mobile/test/inventory_schema_migration_test.dart`
9. `mobile/test/inventory_application_test.dart`
10. `mobile/test/inventory_asset_core_test.dart`
11. `mobile/test/inventory_page_test.dart`
12. `mobile/test/inventory_sketch_editor_test.dart`
13. `mobile/test/mobile_backup_application_test.dart`
14. `docs/v2/CSE_INVENTORY_MAP_V1_CONTRACT.md`
15. `docs/v2/CSE_V2_SCOPE.md`

Read-only inspection outside this list is allowed. Any required write outside it is an immediate stop.

## Protected / zero-drift areas

- Generic `ManagedAttachmentStore` semantics and original-photo bytes/catalog/reconciliation.
- Production backup/restore implementation and backup container format `1`.
- `pubspec.yaml`, `pubspec.lock`, dependencies and mobile version `0.1.0+1`.
- Android/iOS manifests, Gradle, package identity, permissions and platform production files.
- MAIN package/device state.
- Unrelated modules, Slice 6.2, Slice 6.3 and Slice 7.

## Validation authority and budget

1. Format touched Dart files.
2. Run exactly one focused set containing:

   ```text
   flutter test --no-pub test/inventory_schema_migration_test.dart test/inventory_application_test.dart test/inventory_asset_core_test.dart test/inventory_page_test.dart test/inventory_sketch_editor_test.dart test/mobile_backup_application_test.dart
   ```

3. Only after focused PASS, run `flutter analyze --no-pub` once.
4. Run `git diff --check`, exact allowlist audit, schema21/additive migration audit, backup/version/pubspec/platform/permission/package/artifact drift audit.
5. Stage the exact allowlist and run staged `git diff --check` before commit.

Required automated evidence covers deterministic backfill, exact historical preservation, corruption rollback, straight arbitrary-angle segments, valid close/self-intersection rejection, bounded metadata, stable identities/order, multiple non-overlapping blocks, overlap rejection, relaunch persistence, owned placement writes and backup-format drift `0`.

Retry: only one failed focused-test retry after an exact proven mechanical harness/fixture correction. Product/source-contract failure stops execution. No full suite, build, APK, emulator, ADB or device operation.

## Manual test register

- Register: GitHub Issue #479.
- Planned IDs: `MT-527-001..010`.
- Initial status: `PENDING / NOT RUN`.
- Codex must not mark owner manual tests PASS.

## Implementation window and stop conditions

- Primary implementation window: `1`.
- Same-scope narrow corrections: up to `3`, subject to current authority and exact root cause.
- Environment-only recovery: at most `1` after proven environment cause.
- Immediate stop: allowlist expansion; unsafe migration proof; data-loss or hard-delete need; geometry/history identity rewrite; backup/version/permission/platform/package change; Slice 6.2/6.3 design requirement; unexpected user change; requested model mismatch evidence.

## Publication authority

After every authorized gate passes:

- create one minimal implementation commit;
- push `codex/issue-527-inventory-spatial-foundation` normally;
- open one OPEN/DRAFT PR referencing #527 and #506;
- publish exact head/parent/paths/test/analyzer/schema/backup/version/drift evidence to Issue and PR;
- publish `MT-527-001..010` as `PENDING / NOT RUN` to Issue #479;
- stop for fresh independent R4 review.

Ready, merge, Issue closure, Slice 6.2, APK/build/device/ADB/emulator and MAIN operations are forbidden.

## Owner acceptance correction authority — comment 5462090995

- Exact parent/head: `53a5606098cfa074d1b396c3e261de8a05b8aa1f`.
- Target: existing PR `#528`, which must remain `OPEN/DRAFT`.
- Risk/routing: `R4`; requested model `gpt-5.6-sol`; requested effort
  `max`; runtime routing remains independently unverified.
- Owner acceptance supersedes the earlier arbitrary-angle new-drawing
  expectation. Preserved legacy/finalized diagonal geometry remains readable.

Locked correction behavior:

- normal new drawing persists only horizontal/vertical segments;
- first segment uses dominant pointer axis, then segment axes alternate by 90°;
- smart alignment is default and deterministically targets a relevant prior
  vertex coordinate in the intended direction;
- smart alignment exposes a visible preview/guide;
- `Serbest uzunluk` disables vertex-length alignment for the next segment only,
  never disables orthogonality, and resets after that segment commits;
- edit-active finalized/base geometry remains immutable locally and any edit
  attempt is rejected before autosave with an explicit safe UI message;
- edit-active may append a new orthogonal block and must autosave, reload, and
  finalize without Slice 6.3 reconciliation;
- the existing A+B delete/metadata identity regression remains required.

Exact write allowlist:

1. `.cse/tasks/527_task.md`
2. `.cse/results/527_result.md`
3. `docs/v2/CSE_INVENTORY_MAP_V1_CONTRACT.md`
4. `docs/v2/CSE_V2_SCOPE.md`
5. `mobile/lib/features/inventory/inventory_sketch_canvas.dart`
6. `mobile/lib/features/inventory/inventory_sketch_editor_page.dart`
7. `mobile/lib/application/inventory_application.dart` only if the append
   regression proves a real application save defect
8. `mobile/test/inventory_sketch_editor_test.dart`
9. `mobile/test/inventory_application_test.dart`
10. `mobile/test/inventory_page_test.dart` only if required for the locked UI
    message

Validation budget:

- format touched Dart files;
- run exactly once:
  `flutter test --no-pub test/inventory_sketch_editor_test.dart test/inventory_application_test.dart test/inventory_page_test.dart`;
- only after focused PASS, run `flutter analyze --no-pub` exactly once;
- then `git diff --check`, exact allowlist and protected/schema/backup/version/
  package/platform/permission/dependency drift audits;
- stage exact changed allowlist and run staged `git diff --check` before the
  minimal correction commit.

Hard stops:

- no schema/domain-wide orthogonal rejection or legacy geometry rewrite;
- no finalized/base reshape, placement reconciliation, Slice 6.2/6.3 work;
- no Gradle/package/permission/manifest/dependency change;
- no APK/build/device/ADB/MAIN operation;
- no MT PASS inference, Ready, merge, or Issue closure.

## Owner acceptance blocker/UI correction — comment 5462564747

- Exact parent/head: `9855a377119a1e02485535744019dabbccac3d08`.
- Target: existing PR `#528`, which must remain `OPEN/DRAFT`.
- Risk/routing: `R4`; requested model `gpt-5.6-sol`; requested effort
  `max`; runtime routing remains independently unverified.
- Separate global safe-diagnostic issue `#529` is explicitly out of scope.

Locked behavior:

- keep landscape and make the sketch editor a full-screen canvas without the
  large AppBar or horizontal text toolbar;
- provide one compact RIGHT-side icon-only toolbar with tooltip, Semantics
  label, and a non-color-only selected mode state;
- expose a prominent final check/save icon and a compact draft/save-status
  overlay;
- valid geometry plus complete block metadata may invoke finalization while
  autosave is pending: the existing force-save/drain must complete before
  verified `finalizeDraft()` and successful route result `true`;
- finalization failure must preserve the durable draft, stay in the editor, and
  show explicit retryable feedback;
- successful create/edit finalization must cause InventoryPage to reload
  canonical active geometry in the same session;
- metadata dialog action is local `Alanı ekle`; it never auto-finalizes the
  whole sketch, and multiple blocks remain drawable in one draft;
- orthogonal drawing, smart alignment, one-shot `Serbest uzunluk`, legacy
  diagonal readability, and edit-active base immutability remain unchanged.

Exact write allowlist:

1. `.cse/tasks/527_task.md`
2. `.cse/results/527_result.md`
3. `docs/v2/CSE_INVENTORY_MAP_V1_CONTRACT.md`
4. `docs/v2/CSE_V2_SCOPE.md`
5. `mobile/lib/features/inventory/inventory_sketch_editor_page.dart`
6. `mobile/lib/features/inventory/inventory_page.dart`
7. `mobile/test/inventory_sketch_editor_test.dart`
8. `mobile/test/inventory_page_test.dart`

Validation budget:

- format touched Dart files;
- run exactly once:
  `flutter test --no-pub test/inventory_sketch_editor_test.dart test/inventory_page_test.dart`;
- only after focused PASS, run `flutter analyze --no-pub` exactly once;
- then full/staged `git diff --check`, exact allowlist and protected/schema/
  backup/version/package/platform/permission/dependency drift audits;
- append result evidence, create one minimal correction commit, push the same
  branch, publish Issue/PR evidence, and stop for fresh independent R4 review.

Hard stops:

- schema `22`, backup format `1`, and version `0.1.0+1` remain unchanged;
- no app/bootstrap/global diagnostic correction for `#529`;
- no APK/build/device/ADB/MAIN operation;
- no MT PASS inference, Ready, merge, Issue closure, Slice 6.2, or Slice 6.3.
