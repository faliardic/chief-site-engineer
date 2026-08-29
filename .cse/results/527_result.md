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

## 2026-08-29 — owner-acceptance orthogonal drawing correction

Authorities:

- Canonical owner-acceptance correction: Issue #527 comment `5462090995`.
- Narrow analyzer continuation: Issue #527 comment `5462274022`.
- Exact parent/head before this correction:
  `53a5606098cfa074d1b396c3e261de8a05b8aa1f`.
- Branch: `codex/issue-527-inventory-spatial-foundation`.

Implemented behavior:

- Normal new drawing commits only horizontal or vertical segments.
- The first segment uses the pointer-dominant axis; following segments alternate
  by 90 degrees.
- Smart alignment uses eligible prior working-polyline vertex coordinates and
  exposes a non-color-only alignment-guide Semantics surface.
- `Serbest uzunluk` bypasses vertex-length alignment for exactly one next
  segment, keeps that segment orthogonal, and restores smart alignment after
  commit.
- Persisted legacy diagonal geometry remains readable and unchanged; no global
  domain or schema rejection was introduced.
- `editActive` rejects finalized/base geometry mutation locally before autosave
  and exposes the explicit safe UI message. Base-preserving orthogonal block
  append continues through autosave, reload, and finalize.
- Existing A+B whole-polygon delete, metadata identity, undo/redo, and finalize
  mapping coverage remains active.
- `mobile/lib/application/inventory_application.dart` was not changed: the
  real regression proved its existing immutable-prefix and append/finalize
  contracts sufficient.

Validation evidence:

- Touched Dart formatting: `PASS`.
- Exact focused editor/application/page gate final result: `62/62 PASS`.
- Under analyzer continuation `5462274022`, the focused gate was not rerun and
  the authorized `62/62 PASS` result was preserved.
- The prior analyzer invocation found exactly one test-only
  `unnecessary_non_null_assertion` at
  `mobile/test/inventory_application_test.dart:1680`.
- Continuation correction removed only the exact unnecessary `!`; assertion
  strength and product behavior were unchanged.
- Continuation analyzer invocation count: exactly `1`.
- `flutter analyze --no-pub`: `PASS` — `No issues found!`.
- Full `git diff --check`: `PASS`.
- Staged `git diff --check`: `PASS`.
- Changed-path count including this evidence: `8`; authority allowlist: `10`;
  outside-allowlist drift: `0`.
- Schema: `22`; backup format: `1`; mobile version: `0.1.0+1`.
- Gradle/package/permission/manifest/dependency/pubspec/platform drift beyond
  the parent head: `0`.
- APK/build/device/ADB/MAIN: `NOT RUN`.
- Manual tests `MT-527-001..010`: remain `PENDING / NOT RUN`; no PASS inferred.
- Ready/merge/Slice 6.2/Slice 6.3: `NOT PERFORMED`.

```yaml
execution_record:
  issue: 527
  correction: OWNER_ACCEPTANCE_ORTHOGONAL_DRAWING
  analyzer_continuation: 5462274022
  exact_parent: 53a5606098cfa074d1b396c3e261de8a05b8aa1f
  branch: codex/issue-527-inventory-spatial-foundation
  focused_gate: PASS_62_OF_62
  focused_gate_rerun_under_continuation: false
  analyzer_invocations_under_continuation: 1
  analyzer_result: PASS
  changed_paths: 8
  outside_allowlist_drift: 0
  application_source_changed: false
  schema: 22
  backup_format: 1
  mobile_version: 0.1.0+1
  protected_platform_drift: 0
  build: NOT_RUN
  device: NOT_RUN
  main_touched: false
  manual_test_status: PENDING
  ready: false
  merged: false
  runtime_model: unknown
  runtime_reasoning_effort: null
  runtime_routing_verified: false
review_recommendation: FRESH_INDEPENDENT_R4_REREVIEW
```

## Schema 22 compatibility correction — superseded schema 21

- Authorities: Issue #527 comments `5461456833`, `5461543841`,
  `5461589116`, and `5461624921`.
- Exact committed parent: `8d279b34babee6838de950bc1d6edd13f7b0622b`.
- Target PR: `#528`, kept `OPEN/DRAFT` throughout correction execution.
- Final schema: `22`; backup format: `1`; mobile version: `0.1.0+1`.

Compatibility behavior:

- retained the production path `20 -> revised 21 -> 22`;
- added exact shape classification for revised-v21, superseded PR #526-v21,
  and mixed/unknown signatures;
- converted only the exact superseded-v21 signature to the final block-owned
  schema while preserving every floor and placement identity/history field;
- created one deterministic detached compatibility block per represented
  project, preserved legacy draft polygon counts with empty definitions, and
  invented no active polygon mapping;
- rejected mixed/unknown signatures and corrupt cross-project floor placement
  relationships before destructive conversion;
- retained the canonical placement project-availability trigger in both final
  schema paths;
- validated the final relationship graph plus SQLite foreign-key and physical
  integrity before clearing the temporary deferred-FK mode used by the floor
  table rebuild.

Triage and corrections:

- fresh-v21 classification initially rejected the canonical
  `inventory_asset_placements_project_available_update` trigger; the revised
  signature now requires and preserves it;
- the superseded-v21 test fixture redundantly recreated that v20 trigger and
  failed with SQLite code `1`; the redundant fixture DDL was removed;
- the superseded floor-table rebuild produced a valid final graph but retained
  SQLite's deferred implicit-delete counter, causing `COMMIT` to fail with
  SQLite code `787`; after exact final `foreign_key_check` and
  `integrity_check` validation, the superseded path restores
  `defer_foreign_keys=OFF` before commit while `foreign_keys` enforcement stays
  enabled.

Validation evidence:

- corrected preservation test: `1/1 PASS`;
- exact schema21 compatibility gate: `3/3 PASS`;
- exact six-file focused gate: `146/146 PASS`;
- `flutter analyze --no-pub`: `PASS — No issues found`;
- full `git diff --check`: `PASS`;
- exact correction allowlist: `6/6`, outside paths `0`;
- protected production application/UI/domain drift: `0`;
- pubspec/lock, Android/iOS, package and permission drift: `0`;
- schema `22`; backup format `1`; version `0.1.0+1`;
- diagnostic instrumentation residue: `0`;
- Flutter full suite/build/APK/device/ADB/emulator/MAIN: not run;
- manual tests `MT-527-001..010`: `PENDING / NOT RUN`.

```yaml
execution_record:
  issue: 527
  correction: SUPERSEDED_SCHEMA21_TO_FINAL_SCHEMA22_COMPATIBILITY
  exact_parent: 8d279b34babee6838de950bc1d6edd13f7b0622b
  schema: 22
  backup_format: 1
  version: 0.1.0+1
  preservation_gate: 1/1 PASS
  schema21_compatibility_gate: 3/3 PASS
  focused_gate: 146/146 PASS
  analyzer: PASS
  allowlist: 6/6 PASS
  protected_drift: 0
  manual_test_status: PENDING
  ready: false
  merged: false
  runtime_model: unknown
  runtime_reasoning_effort: null
  runtime_routing_verified: false
review_recommendation: FRESH_INDEPENDENT_R4_REREVIEW
```

## Narrow acceptance-label correction — isolated harness

- Authority: Issue #527 narrow acceptance-label correction authority.
- Exact parent: `d00284bd10bfff8b38006a557b9a8af0ecb57457`.
- Target: existing PR `#528`, retained `OPEN/DRAFT`.
- Source correction: only the `CSE_ACCEPTANCE_HARNESS=true` debug
  `appLabel` changed from `Şefim` to `Şefim (Acceptance)`.
- Release `appLabel` remains `Şefim`; package/application ID, permissions,
  signing, SDK levels, version, dependencies, manifests, and MAIN behavior are
  unchanged.

Validation evidence:

- Pre-build `git diff --check`: `PASS`.
- Acceptance debug APK build invocation count: exactly `1`.
- Build command:
  `CSE_ACCEPTANCE_HARNESS=true flutter build apk --debug --no-pub --target lib/main.dart --target-platform android-arm64`.
- Build result: `PASS`.
- Artifact: `mobile/build/app/outputs/flutter-apk/app-debug.apk`.
- Package: `com.faliardic.sefim.acceptance`.
- Application label: `Şefim (Acceptance)`.
- Version name: `0.1.0-acceptance`; version code: `1`.
- APK size: `127407944` bytes.
- APK SHA-256:
  `50e8f5d34ceb9126d72363d21c05bbe6c924cdee8316199280d66e38b860b8bd`.
- AAPT metadata verification: `PASS`; APK signature verification: `PASS`
  (APK Signature Scheme v2, one signer).
- Install/uninstall/clear-data/device migration/launch/ADB/MAIN: `NOT RUN`.
- Flutter tests and analyzer: `NOT RUN` under this narrow authority.
- Manual tests `MT-527-001..010`: remain `PENDING / NOT RUN`.

```yaml
execution_record:
  issue: 527
  correction: ACCEPTANCE_DEBUG_APP_LABEL
  exact_parent: d00284bd10bfff8b38006a557b9a8af0ecb57457
  build_invocations: 1
  build_result: PASS
  package: com.faliardic.sefim.acceptance
  label: Şefim (Acceptance)
  version_name: 0.1.0-acceptance
  apk_bytes: 127407944
  apk_sha256: 50e8f5d34ceb9126d72363d21c05bbe6c924cdee8316199280d66e38b860b8bd
  install: NOT_RUN
  device_launch: NOT_RUN
  main_touched: false
  manual_test_status: PENDING
  ready: false
  merged: false
  runtime_model: unknown
  runtime_reasoning_effort: null
  runtime_routing_verified: false
review_recommendation: FRESH_INDEPENDENT_R4_REREVIEW
```
