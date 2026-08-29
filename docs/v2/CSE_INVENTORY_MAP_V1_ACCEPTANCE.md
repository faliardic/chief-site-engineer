# CSE Inventory Map v1 — Integrated Acceptance Handoff

## Status

- Parent Epic: #506
- Closure Issue: #535
- Phase: Slice 6.4 Phase A
- Source head: `baa7beff186e3fee95f1fb439d92045d7ba1af4e`
- Automated integrated closure: `PASS`
- Owner acceptance: `PENDING / NOT RUN`
- Inventory Spatial v1 fully accepted: `NO`
- Phase B device execution: separate explicit owner authority required
- Slice 7 backup/restore, migration and field-acceptance closure: `NOT STARTED`

Automated Phase-A evidence proves only the tested merged source revision. It is
not owner/manual acceptance, device acceptance, MAIN eligibility, release
readiness or Slice 7 completion.

## Merged Slice 6.1–6.3 source chain

| Source | Merge commit | Role |
| --- | --- | --- |
| PR #528 | `30c45d702a90c90a910e0eee39656c452a232b1c` | Revised Slice 6.1 stable block/floor and closed-area editor foundation |
| PR #530 | `b68ceca5cf51773cb3067d9cf4090a7181935289` | Merged Agenda transient-project diagnostic correction in the source chain |
| PR #532 | `237e2024b856a9bc71e226e958eeebb56bee9d78` | Slice 6.2 Kat Görünümü and exact block/floor navigation |
| PR #534 | `baa7beff186e3fee95f1fb439d92045d7ba1af4e` | Slice 6.3 reshape, placement reconciliation and block lifecycle |

Persisted contracts at the integrated source head are SQLite schema `22`,
backup format `1` and mobile version `0.1.0+1`.

## Phase A automated integrated gate

The following exact Flutter invocation was run once from `mobile/`, with no
retry:

```text
flutter test --no-pub \
  test/inventory_geometry_test.dart \
  test/inventory_application_test.dart \
  test/inventory_asset_core_test.dart \
  test/inventory_attachment_gateway_test.dart \
  test/inventory_page_test.dart \
  test/inventory_sketch_editor_test.dart \
  test/inventory_schema_migration_test.dart \
  test/app_bootstrap_test.dart \
  test/widget_test.dart
```

Result:

- terminal tally: `187/187 PASS`;
- terminal message: `All tests passed!`;
- exit status: `0`;
- retries: `0`;
- `flutter analyze --no-pub`: `PASS — No issues found!`;
- production/test source changes in Issue #535: `0`.

The integrated gate covers the merged geometry, stable block/floor identity,
Map/List navigation and focus, floor quick-create, reshape and placement
reconciliation, detach/archive/reattach lifecycle, photo/history/receipt
retention paths, fail-closed mutation behavior, migration/runtime compatibility,
bootstrap and app-shell regressions represented by those nine test files.

## Phase B owner checklist

All items below are registered as `PENDING / NOT RUN`. A future isolated
Acceptance build/device execution requires a separate explicit owner authority.
No automated result may change these statuses to PASS.

| ID | Owner acceptance scenario | Status |
| --- | --- | --- |
| `MT-535-001` | Create and navigate a two-block, multi-floor project; verify counts, Blok/Kat context and floor quick-create. | `PENDING / NOT RUN` |
| `MT-535-002` | Use List spatial labels/filter and open exact block/floor Map focus with the existing short marker cue. | `PENDING / NOT RUN` |
| `MT-535-003` | Apply whole-block nudge and edge reshape; verify retained/reconciled markers remain sensible and inside the block. | `PENDING / NOT RUN` |
| `MT-535-004` | Detach a block; verify records remain in List as `Krokisi kaldırılmış blok` and detached markers disappear from Map. | `PENDING / NOT RUN` |
| `MT-535-005` | Reattach a same-named detached block; verify mapped context returns without duplicate visible block identity. | `PENDING / NOT RUN` |
| `MT-535-006` | Archive a block in disposable Acceptance data; verify owned records leave active flow while existing history visibility is retained. | `PENDING / NOT RUN` |
| `MT-535-007` | Relaunch the Acceptance app and verify spatial state persists offline. | `PENDING / NOT RUN` |

## Operational boundary

- Phase A performed no APK/AAB build, emulator, device, ADB, install, launch or
  MAIN-package operation.
- Phase B may use only an isolated Acceptance package after separate authority.
- MAIN remains forbidden unless the cumulative owner-phone gates and a separate
  exact MAIN authority are satisfied.
- Ready, merge, Issue closure, release/store, Slice 7 and DWG work are outside
  this handoff.
