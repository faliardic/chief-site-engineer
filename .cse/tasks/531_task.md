# Issue #531 — Inventory Spatial v1 Slice 6.2

## Authority and repository truth

- Issue: `#531 — Inventory Spatial v1 Slice 6.2: Kat Görünümü and block-floor navigation`
- Parent Epic: `#506`
- Foundation: `#527 / merged PR #528`
- Pre-slice correction: `#529 / merged PR #530`
- Owner authority: `https://github.com/faliardic/chief-site-engineer/issues/531#issuecomment-5463482840`
- Exact verified base: `b68ceca5cf51773cb3067d9cf4090a7181935289`
- Canonical branch: `codex/issue-531-inventory-floor-navigation`
- Starting master/origin divergence: `0/0`
- Starting tracked worktree: clean
- Open PRs at task start: none
- Publication authority: one OPEN/DRAFT PR referencing #531 and #506
- Ready / merge / Issue close / Slice 6.3 / Slice 7: not authorized

## Risk and execution routing

- Risk: `R4`
- Requested model: `gpt-5.6-sol`
- Requested reasoning effort: `max`
- Assistant recommendation: `Extra High`
- Runtime model / effort visibility: `unknown / null / unverified`
- Execution topology: root-owned writes with bounded parallel read-only source inspection
- Test retry budget: none

## Locked changed contracts

Slice 6.2 adds route-local canonical block/floor selection, a real `Kat
Görünümü`, shared Map/List spatial selectors and filtering, exact-floor list
focus, and exact-floor quick create through the existing canonical Inventory
create/placement path. It adds no persisted UI filter state, storage subsystem,
schema or migration.

Canonical ownership remains:

```text
asset -> active placement -> floor -> block -> project
```

The one shared active block polygon remains geometry truth for every floor.
Historical placement rows, stable IDs, events, receipts and attachment links
must not be rewritten by navigation/filtering.

## Exact 13-path write allowlist

1. `.cse/tasks/531_task.md`
2. `.cse/results/531_result.md`
3. `docs/v2/CSE_INVENTORY_MAP_V1_CONTRACT.md`
4. `docs/v2/CSE_V2_SCOPE.md`
5. `mobile/lib/domain/inventory_models.dart`
6. `mobile/lib/application/inventory_application.dart`
7. `mobile/lib/features/inventory/inventory_page.dart`
8. `mobile/lib/features/inventory/inventory_map_view.dart`
9. `mobile/lib/features/inventory/inventory_asset_quick_form.dart`
10. `mobile/lib/features/inventory/inventory_floor_view.dart`
11. `mobile/test/inventory_application_test.dart`
12. `mobile/test/inventory_asset_core_test.dart`
13. `mobile/test/inventory_page_test.dart`

`mobile/test/inventory_sketch_editor_test.dart` and
`mobile/test/inventory_schema_migration_test.dart` are read-only gates.
`mobile/lib/storage/app_database.dart`, all migration/storage/backup source,
bootstrap/main/app shell, sketch editor/canvas, pubspec/dependencies and all
platform/package/permission/signing files are protected. Any required path
outside the allowlist is an immediate stop.

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
| `docs/v2/CSE_V2_SCOPE.md` | `4bbbdac92cc716c321701358f701ec284f1dfab1dc2461b334ac6e288d6f10cc` |
| `docs/v2/CSE_INVENTORY_MAP_V1_CONTRACT.md` | `2bebc6e29ac62bad8572bc0774531aec47c825f4b6398189e782354e1abb9b69` |
| `ROADMAP.md` | `5881856940260ae79961da2d8896b901b9155ffec1906285ef15acbf994c6166` |

## Locked implementation architecture

### Canonical spatial UI state

- nullable selected active block ID = all blocks;
- nullable selected floor ID = all floors of the selected block;
- a selected floor is legal only under the selected active block;
- block/project/reload changes deterministically clear or revalidate incompatible IDs;
- invalid canonical projection state fails closed with typed/user-safe feedback;
- UI filter state is never persisted.

### Kat Görünümü

- dedicated `inventory_floor_view.dart` presentation boundary;
- active blocks side by side in stable block ordinal order;
- floors vertical by stable ordinal with visually higher ordinals above lower;
- counts use only non-archived assets with one valid active placement on the exact floor;
- floor/block/project counts never double-count an asset;
- floor row -> exact block/floor Map;
- floor list affordance -> exact block/floor List;
- floor `+` -> normal create flow with exact floor intent;
- detached/archived lifecycle and fake polygons remain out of scope.

### Shared Map/List spatial behavior

- compact `Blok` and `Kat` selectors;
- block options `Tümü` plus active blocks;
- floor options `Tüm katlar` plus selected-block floors; neutral/disabled for all blocks;
- Map/List spatial filtering composes with existing search/category/status/archive filters;
- valid active rows show `Asset · Block · Floor`;
- archived/no-active-placement rows invent no current spatial label;
- list focus selects exact block/floor, switches Map, then reuses existing exact marker focus.

### Exact-floor create

- `CreateInventoryAssetCommand` gains optional backwards-compatible floor intent;
- existing map-tap create remains supported without explicit floor;
- explicit floor must belong to project and to the containing active block polygon/current revision;
- wrong-project/wrong-block intent fails before mutation;
- resulting canonical floor ID remains in placement/event/receipt/history truth;
- deterministic grid-quantized strictly-interior target uses a stable spread index;
- no provable safe point -> `inventory_safe_interior_unavailable`, no write;
- no random coordinate and no geometry mutation.

## Automated acceptance matrix

Every result is reported only as `AUTOMATED PASS` or `BLOCKED`:

- `AT-531-001`: two active blocks with different floor counts render separate stable stacks.
- `AT-531-002`: floor/block/project active counts are exact; archived/ended placements excluded.
- `AT-531-003`: floor tap selects exact block/floor Map and only matching markers.
- `AT-531-004`: block switch cannot retain a cross-block floor.
- `AT-531-005`: spatial labels and all/block/all-floors/specific-floor filters compose with existing filters.
- `AT-531-006`: List focus resolves exact block/floor before existing marker focus.
- `AT-531-007`: floor `+` uses normal create with exact floor ownership.
- `AT-531-008`: repeated quick creates use deterministic distinct small-spread strictly-interior targets.
- `AT-531-009`: missing/detached/no-active polygon quick create fails closed with no write.
- `AT-531-010`: explicit wrong-block/cross-project floor intent fails at application boundary.
- `AT-531-011`: map-tap quick create remains backwards compatible.
- `AT-531-012`: normal create/move/archive/list/map/history regressions remain green.
- `AT-531-013`: schema 22, backup 1, version 0.1.0+1 and protected drift 0.

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

No retry, broader/full suite, build, APK, device, emulator, ADB or MAIN operation
is authorized.

## Manual acceptance

No existing `MT-531` entry was present at task start. Proposed stable owner
items, all `PENDING / NOT RUN`:

- `MT-531-001`: Kat Görünümü stacks/counts and exact floor Map/List navigation.
- `MT-531-002`: block/floor selectors, spatial list labels and list-to-map focus.
- `MT-531-003`: floor-row quick create and deterministic in-polygon placement.

Automated evidence must never be inferred as owner/manual PASS.

## Immediate stop conditions

- any required write outside the exact allowlist;
- schema/storage/migration/backup/bootstrap/app-shell/sketch-editor change need;
- geometry mutation, reshape/reconciliation or detached lifecycle need;
- unproven safe-interior behavior or canonical ownership ambiguity;
- any authorized no-retry focused/analyzer failure;
- destructive Git/data action, build/device/MAIN need or scope expansion.

## Publication boundary

On full PASS: one minimal commit, normal push, one OPEN/DRAFT PR referencing
#531 and #506, Issue/PR evidence, stable manual register entries and STOP for
fresh independent R4 review. Do not mark Ready, merge, close Issue/Epic, infer
manual PASS, start Slice 6.3/7 or perform any release/device operation.
