# Issue #527 — Inventory Spatial v1 Revised Slice 6.1 Result

## Execution identity

- Issue: `#527`
- Parent: Epic `#506`
- Canonical branch: `codex/issue-527-inventory-spatial-foundation`
- Exact parent/base: `f858740f6975bace9b6efd21deb1f679e4489cbf`
- Canonical execution authority: Issue comment `5460841100`
- Harness continuation authority: Issue comment `5461249457`
- Analyzer continuation authority: Issue comment `5461282337`
- Superseded historical evidence: closed/unmerged PR `#526`; no merge, rebase, cherry-pick, or source transplant was used.
- Runtime model/effort visibility: `unknown / null / unverified`

## Implementation result

- Status: `IMPLEMENTED — MANUAL TEST PENDING`
- Revised schema: `21`
- Backup container format: `1` (unchanged)
- Mobile version: `0.1.0+1` (unchanged)
- Package identity: unchanged
- Slice 6.2 / Slice 6.3 / Slice 7: not started
- APK/build/emulator/ADB/device/MAIN operations: not run

Implemented within the locked Slice 6.1 boundary:

- additive stable project block and ordered block-floor identities;
- immutable revision-polygon-to-block linkage and append-only spatial draft metadata;
- additive placement `floor_id` with deterministic schema20 backfill;
- fail-closed migration validation and transaction rollback;
- stable floor-aware placement create/move/unarchive behavior;
- straight arbitrary-angle block drawing, bounded close action, metadata gate,
  overlap/touch/containment rejection, autosave, finalize, and relaunch recovery;
- revised Inventory Map v1 contract and V2 scope documentation.

## Validation evidence

### Focused Flutter gate

Exact command:

```text
flutter test --no-pub test/inventory_schema_migration_test.dart test/inventory_application_test.dart test/inventory_asset_core_test.dart test/inventory_page_test.dart test/inventory_sketch_editor_test.dart test/mobile_backup_application_test.dart
```

Preserved execution history:

- initial run: `137 PASS / 4 FAIL`;
- authorized mechanical-fixture retry: `140 PASS / 1 FAIL`;
- narrow harness continuation: `141/141 PASS`;
- final status: `PASS`.

The final harness correction waits the existing exact 500 ms metadata autosave
debounce and its async completion before asserting the persisted block ID. The
metadata persistence and recovery assertions were not removed or weakened.

### Analyzer

Exact command:

```text
flutter analyze --no-pub
```

Preserved execution history:

- initial invocation: `FAIL`, one `unnecessary_non_null_assertion` warning at
  `inventory_sketch_editor_page.dart:409`;
- authorized analyzer-only correction: removed only the unnecessary `!` from
  `projection!.draftNewBlocks`;
- authorized retry: `PASS — No issues found`.

The focused 141-test set was not rerun after the behavior-neutral lint fix, as
required by comment `5461282337`.

### Source and drift gates

- `git diff --check`: `PASS`.
- Exact Issue #527 allowlist: `PASS`; changed paths are a subset of `15/15`.
- Outside-allowlist changes: `0`.
- Schema constant/migration registration: `21`.
- Migration audit: additive tables, column, indices, triggers, deterministic
  floor backfill; table rebuild, table rename, row delete, and destructive
  migration operations: `0`.
- Historical placement identity/key/sequence/x/y/quantity/end/predecessor truth:
  covered by focused migration regressions.
- Backup production source drift: `0`; format remains `1`.
- `pubspec.yaml` / `pubspec.lock` drift: `0`.
- Mobile version remains `0.1.0+1`.
- Android/iOS/platform/package/permission drift: `0`.
- Generic attachment-store production semantics drift: `0`.
- Build/artifact output was not produced or staged.

## Changed paths

1. `.cse/tasks/527_task.md`
2. `.cse/results/527_result.md`
3. `mobile/lib/storage/app_database.dart`
4. `mobile/lib/domain/inventory_models.dart`
5. `mobile/lib/application/inventory_application.dart`
6. `mobile/lib/features/inventory/inventory_sketch_editor_page.dart`
7. `mobile/test/inventory_schema_migration_test.dart`
8. `mobile/test/inventory_application_test.dart`
9. `mobile/test/inventory_asset_core_test.dart`
10. `mobile/test/inventory_page_test.dart`
11. `mobile/test/inventory_sketch_editor_test.dart`
12. `mobile/test/mobile_backup_application_test.dart`
13. `docs/v2/CSE_INVENTORY_MAP_V1_CONTRACT.md`
14. `docs/v2/CSE_V2_SCOPE.md`

`mobile/lib/features/inventory/inventory_page.dart` remained unchanged because
the revised Slice 6.1 contract did not require a production page mutation.

## Manual test register

- Register: Issue `#479`
- `MT-527-001..010`: `PENDING / NOT RUN`
- Codex did not mark any owner-led manual test PASS.
- Implementation status and manual-test status remain separate.

## Publication boundary

- One minimal implementation commit is authorized after staged verification.
- Push target: `codex/issue-527-inventory-spatial-foundation`.
- PR must remain `OPEN/DRAFT` and reference `#527` and `#506`.
- Ready, merge, Issue closure, subsequent Slice work, build, APK, device, ADB,
  emulator, and MAIN operations remain forbidden.

```yaml
execution_record:
  issue: 527
  parent_issue: 506
  exact_parent: f858740f6975bace9b6efd21deb1f679e4489cbf
  implementation_status: IMPLEMENTED
  manual_test_status: PENDING
  focused_gate: 141/141 PASS
  analyzer: PASS
  schema: 21
  backup_format: 1
  version: 0.1.0+1
  ready: false
  merged: false
  runtime_model: unknown
  runtime_reasoning_effort: null
  runtime_routing_verified: false
review_recommendation: FRESH_INDEPENDENT_R4_REVIEW
```

## Narrow R4 correction — block metadata index preservation

- Authority: Issue #527 comment `5461346053`.
- Independent review: `5057414379`.
- Exact reviewed parent: `66c08f6c860bed04ea63cc35d849db7d8a5cae4b`.
- Blocker: `NEW_BLOCK_METADATA_INDEX_DRIFT_ON_POLYGON_DELETE`.
- Correction paths: exact `3/3` subset; production/test changes are limited to
  `inventory_sketch_editor_page.dart` and `inventory_sketch_editor_test.dart`;
  this section is append-only evidence.

Correction behavior:

- removed polygon-index-keyed metadata rebinding;
- added bounded metadata undo/redo history parallel to geometry history;
- deterministically remapped surviving new-block definitions by exact unchanged
  polygon geometry after index-changing deletion;
- preserved surviving block ID, display name, floor IDs/names/order, and metadata;
- restored/reapplied exact metadata frames across undo/redo without cross-wire;
- kept existing/base/mapped polygon, schema, application persistence, migration,
  backup, package/version, platform, permission, and unrelated UI contracts
  unchanged.

Regression evidence:

- creates distinct A and B block/floor identities;
- deletes whole A and proves only B geometry remains at index `0` with B's exact
  block/floor identities and display name;
- proves two undo/redo cycles do not bind A identity to B;
- force-autosaves and reloads through a fresh controller with exact B metadata;
- finalizes and proves the emitted remaining mapping belongs to B, not A.

Validation:

- Historical broad focused gate: `141/141 PASS` preserved and not rerun.
- Exact narrow command:
  `flutter test --no-pub test/inventory_sketch_editor_test.dart`
- Narrow result: `32/32 PASS`.
- `flutter analyze --no-pub`: `PASS — No issues found`.
- `git diff --check`: `PASS`.
- Correction path audit: `PASS`, outside exact three paths `0`.
- Full PR original Issue #527 allowlist audit: `PASS`, outside paths `0`.
- Schema `21`; backup format `1`; version `0.1.0+1`.
- Pubspec/platform/package/permission/protected drift from reviewed parent: `0`.
- Manual tests `MT-527-001..010`: remain `PENDING / NOT RUN`.
- Build/APK/device/ADB/emulator/MAIN: not run.

```yaml
execution_record:
  issue: 527
  correction: NEW_BLOCK_METADATA_INDEX_DRIFT_ON_POLYGON_DELETE
  reviewed_parent: 66c08f6c860bed04ea63cc35d849db7d8a5cae4b
  historical_broad_gate: 141/141 PASS
  narrow_gate: 32/32 PASS
  analyzer: PASS
  schema: 21
  backup_format: 1
  version: 0.1.0+1
  manual_test_status: PENDING
  ready: false
  merged: false
review_recommendation: FRESH_INDEPENDENT_R4_REREVIEW
```
