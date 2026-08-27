# Issue #512 — Inventory Map v1 Slice 1B task

## Authority and exact start state

- Repository: `faliardic/chief-site-engineer`
- Official local repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Parent / V2 item: Epic #506 — Inventory Map v1
- Canonical contract: Issue #507 / merged PR #508
- Completed child: Issue #509 / merged PR #511
- Current Issue: #512
- Canonical execution authority: https://github.com/faliardic/chief-site-engineer/issues/512#issuecomment-5436864329
- Expected base / synchronized `master` / `origin/master`: `d93305fd21d5e89fb300913e7ae52ae5893618b3`
- Exact branch: `codex/issue-512-inventory-transactional-application`
- Start-state open production PR count: `0`
- Start-state tracked/staged drift: `0 / 0`
- Start-state schema / Inventory tables: `20 / 7`

## Risk and model routing

```yaml
model_routing:
  policy_version: CSE-MRP-1.0
  task_risk: R4
  orchestrator:
    chatgpt_model: gpt-5.6-sol
    chatgpt_reasoning_effort: extra_high
  codex_model: gpt-5.6-sol
  codex_reasoning_effort: max
  execution_mode: standard
  orchestration: single-agent
  selection_reason: Persistence, transaction, idempotency, append-only history and integrity boundaries change together.
  routing_request_evidence: https://github.com/faliardic/chief-site-engineer/issues/512#issuecomment-5436864329
  invocation_evidence: null
  runtime_actual_model: unknown
  runtime_actual_reasoning_effort: unknown
  invocation_verification_status: unverified
  allowed_fallback: null
  review_floor:
    chatgpt_model: gpt-5.6-sol
    chatgpt_reasoning_effort: max
  fail_closed_if_mismatch: true
```

## Changed contracts

- Typed Inventory application/source/command/result/projection/failure records.
- Typed Inventory application port plus one-operation/one-database-handle SQLite adapter and active-database core.
- Exact fourteen non-photo sketch/asset/placement commands.
- Canonical intent/result/event JSON and SHA-256; global receipt replay, conflict, corruption and receipt-only no-op semantics.
- Atomic append-only Inventory events and deterministic read projections.
- Schema, backup, bootstrap, UI, attachments, version, package, platform, permissions and signing do not change.

## Exact allowlist

1. `mobile/lib/application/inventory_application.dart` — new
2. `mobile/lib/domain/inventory_models.dart` — typed Slice 1B records only; geometry behavior preserved
3. `mobile/test/inventory_application_test.dart` — new focused synthetic persistence tests
4. `mobile/test/inventory_geometry_test.dart` — conditional narrow integration regression only
5. `.cse/tasks/512_task.md`
6. `.cse/results/512_result.md`

No seventh path is authorized. Any required edit to database/schema, backup, bootstrap, UI, attachment, pubspec or platform paths is a fail-closed blocker.

## Protected boundaries

- `mobile/lib/storage/app_database.dart` and schema/migration SQL remain unchanged at exact schema `20`.
- `mobile/lib/application/mobile_backup_application.dart` and backup format `1` remain unchanged.
- Bootstrap, navigation/UI/editor, attachment lifecycle and source rows remain unchanged.
- Mobile version remains `0.1.0+1`; package remains `com.faliardic.sefim`.
- `pubspec.yaml`, `pubspec.lock`, Android/iOS, permissions and signing drift remain `0`.
- No Schedule, Reminder, Agenda, notification, Living Plan, Work Chain, material-request, attendance, concrete or attachment side effect.
- No real owner data or application sandbox access.

## Implementation objective

Implement Slice 1B only:

- immutable typed Inventory records and failures;
- `InventoryApplicationPort`, path-backed SQLite adapter and `AppDatabase` core;
- exact commands `sketch_create`, `sketch_draft_autosave`, `sketch_edit_start`, `sketch_finalize`, `sketch_draft_abandon`, `sketch_archive`, `sketch_unarchive`, `asset_create_with_placement`, `asset_update`, `asset_status_change`, `asset_quantity_change`, `asset_archive`, `asset_unarchive_with_placement`, `placement_move`;
- receipt replay before stale checks, exact conflict/corruption/no-op behavior and one transaction for source/events/receipt;
- canonical bounded event vocabulary and contiguous aggregate sequences;
- active-project availability, primary sketch, exact asset, deterministic asset list, placement chain and combined asset/placement history projections;
- typed fail-closed behavior for corrupt geometry, unavailable revisions, cross-project rows and unsupported multiple active placements.

Photo commands, schema redesign, backup/restore adoption, bootstrap exposure, UI/editor, Slice 1C, Slice 2 and later slices are out of scope.

## Source-level and focused validation authority

Run only on the final source revision, in this order:

1. exact changed/protected-path audit;
2. format touched Dart files;
3. exactly one focused invocation: `flutter test --no-pub test/inventory_application_test.dart`; include `test/inventory_geometry_test.dart` in that same invocation only if it changed;
4. at most one narrow same-scope mechanical correction and one focused retry if the first invocation exposes a proven defect;
5. after focused PASS, exactly one `flutter analyze --no-pub`;
6. at most one narrow same-scope mechanical analyzer correction and one analyzer retry;
7. `git diff --check`;
8. static schema/backup/bootstrap/UI/attachment/version/package/pubspec/platform/permission/signing drift audit;
9. final branch/worktree/staging/remote-divergence audit.

Do not run the full Flutter suite, widget/integration tests, build/APK/AAB/release gate, emulator, ADB/device, owner data or sandbox operations.

## Manual tests and artifact authority

- Manual Test Register: Issue #479
- Manual test IDs/status: `N/A — synthetic persistence child`; no `MT-512-*` entries exist or are required.
- Build/artifact authority: not granted.
- Owner-phone install/device authority: not granted; operations must remain `0`.

## Stabilization budget and immediate escalation

- Primary implementation window: `1`.
- Focused same-scope mechanical correction/retry: at most `1`.
- Analyzer same-scope mechanical correction/retry: at most `1`.
- Stop immediately for an allowlist expansion, schema/contract redesign, backup/platform/permission/signing change, owner-data risk, integrity ambiguity, destructive action or need to weaken canonical behavior.

## Publication authority

On complete PASS: minimal intentional commit(s), normal push, exactly one Draft PR to `master`, Issue/PR evidence, then stop for independent R4 review.

Not authorized: Ready, merge, Issue closure, Slice 1C, Slice 2, build, install, release/store or owner-phone operation.

Success classification:

`SLICE_1B_IMPLEMENTED — TRANSACTIONAL PERSISTENCE TESTS PASS — INDEPENDENT REVIEW REQUIRED`

## Canonical source manifest

| Source | Git blob | SHA-256 |
| --- | --- | --- |
| `AGENTS.md` | `75e218af5813422a08aae08dc9df7d07507169be` | `bb00551caecbd2c19af6ccff0fe9c93acfa71aade05288b303f6006be0be616d` |
| `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md` | `d2f31def8ee392aab74990766e0a4822be489710` | `5899a8fe03e8ab7ca8ce204ddf7a271686bda0668b08a828645649495539e333` |
| `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md` | `f83164280277cc1f811448a559ddbfcc78d56040` | `f2c00b649cd1dceb19dc0bd1d284713138dbfbd8ee3332b9581afd107a0c20d5` |
| `docs/protocols/CSE_CODEX_INSTRUCTION_COMMENT_PROTOCOL.md` | `23eb5c4d72ce3858f097292f7fa1d3fb713d3b7e` | `e6585e4a217d63d6717973121512338a3edfd24091c3eb0df6ea573ec8a797c6` |
| `docs/protocols/CSE_MODEL_REASONING_ROUTING_POLICY.md` | `7d099ed4e5a1205320350c663fe659e36f2c4d6a` | `e1f55336657ecd79cb68cbae458341a811f0bb33867ac06b71163a5a8c8c320b` |
| `docs/protocols/CSE_WORKFLOW_ACCELERATION_PROTOCOL.md` | `b8ce5dd678935e472e1e5351db6c60b6c87238d7` | `7765bcebfb7b25b12e60fb44767d49c9d537393786fa0026561e1593073d297d` |
| `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md` | `e90612f5ca5bb3f4997110142e24112e246f3b6d` | `c12a57885f31144dc15cbbd3a07ab59527489a533ce5d8b444664ecf7710440d` |
| `docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md` | `af1974ecd2c53ceb67245c8eb1242b03fb1a82ef` | `b1685ce1610593195282b3b7c9038009ef8cd365d7c1314cb2356fc425bb383a` |
| `docs/protocols/CSE_PROJECT_SOURCE_REGISTER.md` | `583663cf0016d5060ed90ec44d1fce8aa16f74a5` | `f96fc9b1ef8bd12a6a4515a707726d84ee9a86a1a28bf6f20c5217e2954212cb` |
| `docs/v2/CSE_V2_SCOPE.md` | `f25b54b5329f87efe9a2862e4fa2ca9d614e77f2` | `3fb70a0c80c293b17a38214f4b717c1bafe539526289eaf86a0be1d4683aee51` |
| `ROADMAP.md` | `c0398a334e966b2eafca8cfe7b0dbe93e455af6b` | `5881856940260ae79961da2d8896b901b9155ffec1906285ef15acbf994c6166` |
| `docs/v2/CSE_INVENTORY_MAP_V1_CONTRACT.md` | `88dcc047645536b3eb500d4aaced8b19786651fd` | `6ed6285a565d5cc032116b5643f5565757d97acb7acc8325188f19dc8cd0bbca` |
| `mobile/lib/domain/inventory_models.dart` | `2e6b6c9c485f065c1630950611b26610097fde73` | `bf48ffa59d39ddfcfa85018b5cc3c897b56d544c1e4daba273d85f8a947c0f38` |
| `mobile/lib/storage/app_database.dart` | `5a76ca3c326bc0ea5f5b3ebb7286ece2911cc005` | `73f48ac8ce08150a20fc1fb1f29afb5c0d1b37c2cd98e09511c87c30e3bc0dc1` |
| `mobile/test/inventory_schema_migration_test.dart` | `04c5f8efd0bc567f039ed3ec3c4bbf99ffc6a372` | `7eb1a19c1de1f7f45e0d967eef2e6e51e8c7fd76f0b6d66ba5cea75e74e7b5c1` |
| `mobile/lib/application/construction_living_plan_application.dart` | `824ae1899d501e6d6a71a3e28c5fdb28c16ecf6a` | `7bdcbeb3a4ede0c12f46ee70918709ae3c8d6a12f5971d791bfe9e17164f4c52` |

## GitHub evidence read

- Parent Issue #506 body.
- Issue #509 body, correction evidence `5436085225`, independent R4 re-review and merge completion `5436799027`.
- PR #511 merged source/head `7f79fc55e7c1096ab7ac1578fa1697173c97cc63` into `d93305fd21d5e89fb300913e7ae52ae5893618b3`.
- Issue #512 body and canonical authority comment `5436864329`.
- Issue #479: no `MT-512-*` entry; status remains `N/A — synthetic persistence child`.
- P0 Issues #501, #502, #503 and #499 read as cumulative data/device boundaries.
