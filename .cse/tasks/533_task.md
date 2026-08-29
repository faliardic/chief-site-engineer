# Issue #533 — Inventory Spatial v1 Slice 6.3

## Authority and repository truth

- Issue: `#533 — Inventory Spatial v1 Slice 6.3: block reshape, placement reconciliation and lifecycle`
- Parent Epic: `#506`
- Foundation: `#527 / merged PR #528` and `#531 / merged PR #532`
- Owner authority: `https://github.com/faliardic/chief-site-engineer/issues/533#issuecomment-5463794883`
- Exact verified base: `237e2024b856a9bc71e226e958eeebb56bee9d78`
- Canonical branch: `codex/issue-533-inventory-block-lifecycle`
- Starting master/origin divergence: `0/0`
- Starting tracked worktree: clean
- Open Issue #533 branch/PR at task start: none
- Publication authority: one OPEN/DRAFT PR referencing #533 and #506
- Ready / merge / Issue close / Slice 6.4 / Slice 7: not authorized

## Risk and execution routing

- Risk: `R4`
- Requested model: `gpt-5.6-sol`
- Requested reasoning effort: `max`
- Assistant recommendation: `Extra High`
- Runtime model / effort visibility: `unknown / null / unverified`
- Execution topology: bounded parallel allowlist-owned production/test tracks
  with root integration and independent read-only R4 contract review
- Test retry budget: none
- Automated application tests: explicitly authorized only as the single exact focused gate below
- Build/artifact authority: none

## Locked changed contracts

Slice 6.3 adds bounded transform operations for already mapped active block
polygons and an explicit, typed existing-block finalize intent. Finalization
atomically reconciles active placements, stable block/floor state, revision
mapping, append-only events and command receipts. It also adds explicit detach,
archive and same-identity reattach lifecycle behavior.

Canonical ownership remains:

```text
asset -> active placement -> stable floor -> stable block -> project
active revision mapping -> stable block -> exact polygon index
```

Schema remains exact `22`. No table, migration, storage, backup, dependency,
platform, package, permission or signing behavior changes. Stable IDs, placement
keys/sequences, predecessor/successor history, photo links and prior event truth
must not be rewritten or physically deleted.

## Exact 13-path write allowlist

1. `.cse/tasks/533_task.md`
2. `.cse/results/533_result.md`
3. `docs/v2/CSE_INVENTORY_MAP_V1_CONTRACT.md`
4. `docs/v2/CSE_V2_SCOPE.md`
5. `mobile/lib/domain/inventory_models.dart`
6. `mobile/lib/application/inventory_application.dart`
7. `mobile/lib/features/inventory/inventory_sketch_canvas.dart`
8. `mobile/lib/features/inventory/inventory_sketch_editor_page.dart`
9. `mobile/lib/features/inventory/inventory_page.dart`
10. `mobile/test/inventory_application_test.dart`
11. `mobile/test/inventory_asset_core_test.dart`
12. `mobile/test/inventory_sketch_editor_test.dart`
13. `mobile/test/inventory_page_test.dart`

`mobile/test/inventory_schema_migration_test.dart` is a read-only gate.
`mobile/lib/storage/app_database.dart`, all schema/migration/backup source,
`inventory_map_view.dart`, `inventory_floor_view.dart`, bootstrap/main/app shell,
pubspec/dependencies and all platform/package/permission/signing files are
protected. Any required write outside the allowlist is an immediate stop.

## Canonical source manifest

| Source | SHA-256 |
| --- | --- |
| `AGENTS.md` | `bb00551caecbd2c19af6ccff0fe9c93acfa71aade05288b303f6006be0be616d` |
| `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md` | `5899a8fe03e8ab7ca8ce204ddf7a271686bda0668b08a828645649495539e333` |
| `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md` | `f2c00b649cd1dceb19dc0bd1d284713138dbfbd8ee3332b9581afd107a0c20d5` |
| `docs/protocols/CSE_MODEL_REASONING_ROUTING_POLICY.md` | `e1f55336657ecd79cb68cbae458341a811f0bb33867ac06b71163a5a8c8c320b` |
| `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md` | `c12a57885f31144dc15cbbd3a07ab59527489a533ce5d8b444664ecf7710440d` |
| `docs/protocols/CSE_WORKFLOW_ACCELERATION_PROTOCOL.md` | `7765bcebfb7b25b12e60fb44767d49c9d537393786fa0026561e1593073d297d` |
| `docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md` | `b1685ce1610593195282b3b7c9038009ef8cd365d7c1314cb2356fc425bb383a` |
| `docs/protocols/CSE_CODEX_INSTRUCTION_COMMENT_PROTOCOL.md` | `e6585e4a217d63d6717973121512338a3edfd24091c3eb0df6ea573ec8a797c6` |
| `docs/protocols/CSE_PROJECT_SOURCE_REGISTER.md` | `f96fc9b1ef8bd12a6a4515a707726d84ee9a86a1a28bf6f20c5217e2954212cb` |
| `docs/v2/CSE_V2_SCOPE.md` | `254ba3a4d0963cc606443a3c063ec64a475ba3def33aed5025123dc4550fcda3` |
| `docs/v2/CSE_INVENTORY_MAP_V1_CONTRACT.md` | `97cebfca87524d7642cfdcbaeedd3ad9fd6977cabe62eb2f31e4bab72fa59d75` |
| `ROADMAP.md` | `5881856940260ae79961da2d8896b901b9155ffec1906285ef15acbf994c6166` |

All long-lived ruleset hashes match the prior task manifest. Only the merged
Slice 6.2 V2 scope and Inventory contract hashes changed and were reread.

## Locked implementation architecture

### Typed finalize lifecycle intent

- `FinalizeInventorySketchCommand` carries explicit existing stable-block
  intents: retain mapped at an exact target polygon, detach a removed active
  block, archive a removed active block, or reattach an exact detached block at
  an exact target polygon.
- The application derives canonical project, sketch, revision, block, floor and
  mapping ownership itself. Caller ownership claims are never trusted.
- A recovered draft that is missing an existing mapping but lacks a current
  explicit detach/archive intent cannot finalize. It fails closed and asks the
  owner to choose again; lifecycle intent is not hidden in draft persistence.
- Schema 22 mapping rows are immutable/no-delete. Mapping-preserving autosaves
  keep the current draft revision; mapping-changing autosaves atomically
  abandon that draft, insert one successor draft on the same active base with
  the exact target mappings, and move the sketch draft pointer. The predecessor
  draft/mappings remain evidence and receipt replay returns the same successor.

### Bounded editor transforms and validation

- Select mode keeps segment selection; selecting the same segment again
  promotes it to whole-polyline selection.
- Four accessible nudge controls move a whole mapped block exactly one
  `sketchGridStep` per action.
- A selected horizontal/vertical edge moves parallel by one grid step on its
  perpendicular axis while adjacent vertices preserve a closed polygon.
- Persisted legacy diagonal edges may be whole-translated, but edge reshape is
  rejected with a safe typed diagnostic.
- Unmapped legacy base geometry remains locked. New blocks remain editable.
- Candidate geometry is validated for bounds, polygon validity and overlap
  before editor history, autosave or persistence state changes.

### Editor history and destructive choice

- Undo/redo frames keep geometry, stable mapping identity, new-block metadata
  and pending non-destructive reattach metadata aligned.
- Undo after removing a mapped block restores its exact block/polygon mapping
  identity; redo removes the same identity again.
- Whole-delete of a mapped active block presents exactly two choices:
  `Bloğu ve envanter kayıtlarını sil` and
  `Bloğu krokiden kaldır, kayıtları koru`.
- Geometry is removed only after that explicit current-session choice.

### Atomic application reconciliation

- Retained rigid translation applies the exact common `dx/dy` to each owned
  active placement through an appended successor row.
- Non-rigid reshape leaves a placement unchanged only when it remains at a
  valid safe interior point with required deterministic inward margin.
- Otherwise it appends a successor at the nearest deterministic safe interior
  target, with squared-distance then `y` then `x` ascending tie-break ordering.
- Every successor preserves placement key, asset, floor, quantity and sequence
  continuity; the predecessor is ended with `MOVED` and never updated in place.
- Reconciliation reuses `inventory.placement_moved` with
  `reason: geometry_reconciliation`, before/after coordinates,
  predecessor/successor IDs, floor ID and revision provenance. Event payloads
  remain canonical and append-only; no persisted event enum is added.
- Detach changes the stable block to `DETACHED`, removes it from the new active
  revision mapping and preserves floors, assets, photos, placements and history
  without coordinate rewrite solely because of detach.
- Archive tombstones the block/floors and canonically archives owned active
  assets while retaining all placement/event/photo/history rows.
- Reattach reuses the exact detached block/floor IDs, names and ordinals,
  restores block/floors to active state, creates a new mapping and appends
  deterministic safe-cluster successor placements for retained active assets.
- Revision activation, mappings, block/floor lifecycle, assets, placements,
  events and receipt complete in one SQLite transaction. Any failure rolls the
  full unit back.

### Detached presentation and same-name reuse

- Detached blocks are excluded from active Map/Katlar selectors and markers.
- Retained active assets remain in List with exact label
  `Krokisi kaldırılmış blok`; Map focus fails safely and invents no polygon.
- New block metadata input normalizes the name. Exactly one detached name match
  visibly offers reuse and requires confirmation; reattach preserves exact
  block/floor identities. Ambiguous active/detached duplicates fail closed.

## Automated acceptance matrix

Every result is reported only as `AUTOMATED PASS` or `BLOCKED`:

- `AT-533-001`: mapped whole-block nudge preserves stable mapping identity and valid polygon.
- `AT-533-002`: rigid translation moves owned active placements by exact `dx/dy`, retaining floor and relative spacing.
- `AT-533-003`: orthogonal edge reshape leaves safely interior placements unchanged.
- `AT-533-004`: outside/boundary placements receive nearest deterministic safe-interior successor with margin.
- `AT-533-005`: placement history is append-only and exact geometry-reconciliation event provenance is emitted.
- `AT-533-006`: self-intersection, overlap or out-of-canvas candidate leaves editor/autosave/persistence unchanged.
- `AT-533-007`: injected reconciliation failure rolls back revision, mapping, lifecycle, placement, event and receipt changes.
- `AT-533-008`: detach removes active mapping, sets `DETACHED`, retains block/floor/assets/photos/history and hides Map marker.
- `AT-533-009`: detached List shows `Krokisi kaldırılmış blok`; Map focus fails safely.
- `AT-533-010`: archive tombstones block/floors/assets without deleting placement/event/photo history.
- `AT-533-011`: exact same-name detached suggestion and confirmation reuses block/floor IDs.
- `AT-533-012`: reattach produces deterministic safe cluster and appended placement successors.
- `AT-533-013`: duplicate active/detached name ambiguity is prevented before mutation.
- `AT-533-014`: undo/redo preserves exact mapping and pending lifecycle identity.
- `AT-533-015`: Slice 6.2 floor navigation, create, focus and spatial regressions remain green.
- `AT-533-016`: schema 22, backup 1, version 0.1.0+1 and protected drift 0.

## Validation authority

After implementation and touched Dart formatting, exactly one focused Flutter
invocation is authorized:

```text
flutter test --no-pub test/inventory_application_test.dart test/inventory_asset_core_test.dart test/inventory_page_test.dart test/inventory_sketch_editor_test.dart test/inventory_schema_migration_test.dart
```

If and only if focused PASS:

1. run `flutter analyze --no-pub` exactly once;
2. run full and staged `git diff --check`;
3. audit the exact 13-path allowlist;
4. verify schema `22`, backup `1`, version `0.1.0+1`;
5. verify storage/migration/backup/bootstrap/main/app-shell, pubspec/dependency,
   Android/iOS/package/permission/signing drift `0`;
6. append result evidence, create one minimal commit, push and open one Draft PR;
7. publish Issue/PR evidence and stop for fresh independent R4 review.

No retry, broader/full suite, build, APK, device, emulator, ADB or MAIN
operation is authorized.

## Manual acceptance

No existing `MT-533` entry was present in Issue #479 at task start. Proposed
stable owner items, all `PENDING / NOT RUN`:

- `MT-533-001`: whole-block nudge and rigid placement delta.
- `MT-533-002`: edge reshape and deterministic inward reconciliation.
- `MT-533-003`: invalid transform and rollback safety.
- `MT-533-004`: detach, exact List label and Map isolation.
- `MT-533-005`: archive tombstone with retained history/photos.
- `MT-533-006`: same-ID/floor-ID detached reattach and marker cluster.
- `MT-533-007`: duplicate-name ambiguity fail-closed.
- `MT-533-008`: undo/redo and recovered-draft lifecycle re-prompt.
- `MT-533-009`: Slice 6.2 navigation/create/focus regression smoke.

Automated evidence must never be inferred as owner/manual PASS.

## Stabilization and immediate stop conditions

- Primary implementation window: one.
- Same-scope correction budget is bounded by canonical protocol, but this
  authority grants no test or analyzer retry.
- Stop on any required write outside the exact allowlist; schema/storage/
  migration/backup/platform/dependency need; ambiguous ownership/recovery
  behavior; unproven atomicity; new product decision; focused or analyzer
  failure; destructive Git/data action; build/device/MAIN need; or scope
  expansion.

## Publication boundary

On full PASS: one minimal commit, normal push, one OPEN/DRAFT PR referencing
#533 and #506, Issue/PR evidence, stable manual register entries and STOP for
fresh independent R4 review. Do not mark Ready, merge, close Issue/Epic, infer
manual PASS, start Slice 6.4/7 or perform any release/device operation.
