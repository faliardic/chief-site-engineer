# Issue #522 — Inventory Map v1 Slice 5 execution record

## Authority and start state

- Repository: `faliardic/chief-site-engineer`
- Parent / V2 item: Epic #506 — Inventory Map v1, Slice 5
- Execution Issue: #522
- Canonical execution authority: Issue #522 comment `5457014450`
- Expected base / verified `origin/master`: `2fc46baf7f271454d437e3fd9e01492ce19f47af`
- Canonical branch: `codex/issue-522-inventory-attachment-overlap-resilience`
- Branch start HEAD: `2fc46baf7f271454d437e3fd9e01492ce19f47af`
- PR: one new Draft PR after final gates; Ready/merge/Issue closure are not authorized
- Runtime requested model / effort: `gpt-5.6-sol` / `max`
- Runtime actual model / effort: `unknown / null / unverified`
- Risk / validation class: `R4 / persistence`

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
| `docs/v2/CSE_V2_SCOPE.md` | `3fb70a0c80c293b17a38214f4b717c1bafe539526289eaf86a0be1d4683aee51` |
| `ROADMAP.md` | `5881856940260ae79961da2d8896b901b9155ffec1906285ef15acbf994c6166` |
| `docs/v2/CSE_INVENTORY_MAP_V1_CONTRACT.md` | `6ed6285a565d5cc032116b5643f5565757d97acb7acc8325188f19dc8cd0bbca` |

GitHub Issue #522 and authority comment `5457014450` are the current dynamic scope truth. `.cse/state/project_state.json` is stale factual context and does not override GitHub or the sources above. Issue #479 currently has no `MT-522` rows; the authorized short owner-smoke family will be registered as `PENDING` only after final focused gates pass.

## Objective and changed contracts

Harden the existing schema-20 Inventory flow without expanding the product:

1. optional Inventory asset photo lifecycle through the existing managed attachment backbone;
2. real `InventoryAssetDetailSheet` photo add/view/change/remove UX;
3. deterministic presentation-only marker overlap clusters and accessible controls/states;
4. offline relaunch plus first-sketch and edit-active draft recovery regression coverage.

Inventory stable identity, exact project isolation, optimistic revisions, append-only event/history, durable receipts, immutable placement/sketch history, managed attachment integrity and route-local selection remain binding.

## Exact 15-path allowlist

1. `.cse/tasks/522_task.md`
2. `mobile/lib/domain/inventory_models.dart` — only if photo/link projection or command typing requires it
3. `mobile/lib/application/inventory_application.dart`
4. `mobile/lib/platform/inventory_attachment_gateway.dart` — new thin adapter only if required
5. `mobile/lib/bootstrap/app_bootstrap.dart`
6. `mobile/lib/features/inventory/inventory_asset_detail_sheet.dart`
7. `mobile/lib/features/inventory/inventory_map_view.dart`
8. `mobile/lib/features/inventory/inventory_page.dart`
9. `mobile/lib/features/inventory/inventory_sketch_editor_page.dart` — recovery/accessibility only if required
10. `mobile/test/inventory_application_test.dart`
11. `mobile/test/inventory_asset_core_test.dart`
12. `mobile/test/inventory_page_test.dart`
13. `mobile/test/inventory_sketch_editor_test.dart`
14. `mobile/test/inventory_attachment_gateway_test.dart` — only if path 4 is created
15. `.cse/results/522_result.md`

There is no sixteenth path. Any required path outside this list is a hard stop; the allowlist will not be widened locally.

## Protected contracts and paths

- SQLite schema remains exactly `20`; no schema or migration edit.
- Backup format remains exactly `1`; no backup/restore production source edit.
- Mobile version remains `0.1.0+1`; MAIN package remains `com.faliardic.sefim`.
- `pubspec.yaml` and `pubspec.lock` drift remains `0`.
- Android/iOS production, permission, signing and plugin drift remains `0`.
- Generic `ManagedAttachmentStore`, attachment catalog/reconciliation/media album and existing attachment-link semantics are not modified.
- No existing-table rebuild/rename/drop and no destructive existing user-row mutation.
- No schedule, Reminder, notification, Work Chain, Living Plan, material request or other source mutation.
- No production/debug/MAIN data-root access; no APK/AAB, emulator, ADB or device work.
- No Slice 6 work.

## Checkpoint sequence

### Checkpoint A — Inventory photo application/storage boundary

- Reuse existing `ManagedAttachmentStore` and schema-20 `inventory_asset_attachment_links`.
- Camera/gallery selection is explicit and cancellation is a no-op.
- Validate safe path, supported image MIME, size and SHA-256.
- Add/replace archives the old active link and inserts the new active link with exact asset/project validation and append-only Inventory photo event/receipt semantics.
- Remove archives only the active link; historical link and referenced byte remain.
- DB failure compensation touches only the operation-owned new staged/final artifact; pre-existing/reference bytes are never deleted.
- Preview/read is integrity-gated and returns a typed safe diagnostic for missing/corrupt/unsupported data.
- Cross-project, archived-asset mutation, stale revision and replay conflict fail closed before partial mutation.

### Checkpoint B — Real detail-sheet photo UX

- Photo absent: `Fotoğraf ekle`.
- Healthy photo: verified preview plus explicit change/remove actions.
- Camera and gallery only; picker cancel leaves zero mutation.
- Archived assets may view existing history/photo but photo mutation controls are disabled.
- Failure/corrupt states are visible, safe and do not claim success.
- Existing metadata, quantity, move, archive/unarchive and history contracts remain unchanged.

### Checkpoint C — Overlap/cluster and accessibility

- Apply filters before clustering, after canonical integrity validation.
- Treat each marker as a `48 x 48` logical-pixel hit area and deterministically merge overlapping areas, including overlap across spatial-bucket boundaries; render two or more connected markers as one count cluster.
- Internal order is normalized asset name then stable asset ID.
- Cluster interaction follows zoom/center then deterministic chooser at max zoom; it never mutates source coordinates.
- Target-selection mode has precedence over cluster/detail/quick-create.
- Marker and cluster targets are at least `48 x 48`, expose semantic labels and non-color-only status/selection/count cues.
- Safe loading/no-sketch/no-assets/no-filter-results/corrupt/map-unavailable/error states and large text remain usable.

### Checkpoint D — Offline relaunch and draft recovery

- Recreate application/controller state against the same persisted synthetic SQLite and managed roots.
- Finalized sketch, assets, placements and photo relation survive relaunch.
- Exactly one active project auto-selects; multiple projects remain explicit selection.
- First-sketch `DRAFT` and edit-active `DRAFT` reopen the exact durable revision/geometry.
- Recovered undo/redo stacks are empty while durable geometry is retained.
- Failed or pending save blocks exit; no silent abandon/finalize/repair/project switch.

### Checkpoint E — Final focused gates and publication

- Complete exact changed/protected audits and evidence.
- Run only the authority-defined focused validation budget below.
- On PASS, create minimal commit(s), push this same branch, open one Draft PR referencing #522/#506, publish Issue/PR evidence, register short `MT-522` owner-smoke rows as `PENDING`, and stop for fresh independent R4 review.

## Validation budget

Authorized final sequence:

1. exact changed-path and protected-path audit;
2. format only touched Dart files;
3. exactly one focused Flutter test invocation containing only directly affected Inventory/attachment test files;
4. at most one narrow mechanical retry of that same focused invocation;
5. exactly one `flutter analyze --no-pub` after focused PASS;
6. at most one narrow mechanical analyzer retry;
7. `git diff --check`;
8. verify schema `20`, backup `1`, version `0.1.0+1`, MAIN package and protected/platform/permission/pubspec drift `0`;
9. verify no tracked DB, backup, APK or generated artifacts;
10. verify branch, staging, working tree and origin/master divergence.

Not authorized: full Flutter suite, integration/full application suite beyond the exact focused invocation, build/APK/AAB, emulator, ADB, device/MAIN operations or scripted device acceptance.

Any non-mechanical focused-test or analyzer failure is fail-closed: do not broaden scope or consume an unauthorized retry.

## Manual tests and artifact authority

- Automated application tests: explicitly authorized only as the single final focused invocation above.
- Manual tests: short `MT-522-*` owner-smoke family will be registered `PENDING`; Codex does not execute or mark PASS.
- Build/artifact authority: none.
- Current implementation status: `IN_PROGRESS`.
- Current manual-test status: `PENDING` (registration deferred until final source gates PASS).

## Stabilization budget and immediate escalation

- One bounded primary implementation window.
- Same-scope narrow corrections: at most three under the repository acceleration protocol, but this authority's test/analyzer invocation limits remain stricter.
- Environment-only recovery: at most one after exact root-cause evidence.

Stop immediately for allowlist expansion, schema/migration/backup/version/permission/platform change, generic attachment-store/catalog/reconciliation/album production change, destructive operation, real data-root access, unproven attachment ownership/cleanup, cross-project identity risk, transaction/event/history integrity change outside the authority, or inability to prove the root behavior inside the exact validation budget.

## Publication boundary

PASS authorizes minimal commit(s), normal push, one Draft PR and evidence comments. It does not authorize Ready, merge, Issue #522 closure, Inventory v1 completion, release/store publication, Slice 6, or any phone/MAIN operation. Final state must stop at `IMPLEMENTED — MANUAL TEST PENDING — FRESH INDEPENDENT R4 REVIEW REQUIRED`.
