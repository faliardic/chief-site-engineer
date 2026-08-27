# Issue #509 — Inventory Map v1 Slice 1A Persistence Foundation

## Authority and repository state

- Parent / V2 item: Epic #506 — Inventory Map v1
- Canonical contract: Issue #507 / merged PR #508 / `docs/v2/CSE_INVENTORY_MAP_V1_CONTRACT.md`
- Active Issue: #509
- Owner execution authority: https://github.com/faliardic/chief-site-engineer/issues/509#issuecomment-5434091440
- Official repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Expected base: `02069ffd6c8cfde35bc9a2bd337ad5e6b082ab68`
- Verified local `master` / `origin/master`: `02069ffd6c8cfde35bc9a2bd337ad5e6b082ab68`
- Master divergence at start: `0/0`
- Open production PR count at start: `0`
- Branch: `codex/issue-509-inventory-schema20-geometry-foundation`
- Initial tracked/staged drift: `0/0`
- First authorized local write: this file

## Model routing

```yaml
model_routing:
  policy_version: CSE-MRP-1.0
  task_risk: R4
  orchestrator:
    chatgpt_model: gpt-5.6-sol
    chatgpt_reasoning_effort: max
  codex_model: gpt-5.6-sol
  codex_reasoning_effort: max
  execution_mode: standard
  orchestration: single-agent
  selection_reason: Additive SQLite migration, persistence invariants, canonical geometry and backup smoke adoption.
  routing_request_evidence: https://github.com/faliardic/chief-site-engineer/issues/509#issuecomment-5434091440
  allowed_fallback: null
  review_floor:
    chatgpt_model: gpt-5.6-sol
    chatgpt_reasoning_effort: max
  fail_closed_if_mismatch: true
  invocation_evidence: null
  invocation_verification_status: unverified
  runtime_actual_model: unknown
  runtime_actual_reasoning_effort: unknown
```

The execution surface does not expose independently verifiable runtime model or
reasoning metadata. No mismatch is visible; runtime actual remains unverified.

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

GitHub sources read: Epic #506, Issue #509 body and owner comment
`5434091440`, Manual Test Register #479, and P0 boundaries #501/#502/#503/#499.

## Objective and changed contracts

Implement only Inventory Map v1 Slice 1A:

1. pure deterministic geometry version-1 domain codec/validator/fingerprint;
2. additive SQLite schema `19 -> 20` with the seven exact Inventory tables,
   planned indices and fail-closed triggers;
3. schema-20 table-presence adoption in the existing backup DB-smoke boundary;
4. focused synthetic geometry and persistence tests.

Changed contracts:

- SQLite schema: `19 -> 20`, additive only;
- new exact seven-table Inventory persistence boundary;
- canonical virtual geometry: canvas `4096 x 3072`, grid `64`, placement
  quantization `4`, geometry version `1`, bounded immutable canonical JSON and
  SHA-256;
- current backup DB-smoke required-table set.

Unchanged contracts:

- backup format `1`;
- mobile version `0.1.0+1`;
- package `com.faliardic.sefim`;
- pubspec/lock, Android/iOS, permissions, signing and orientation;
- existing tables, rows, attachment bytes and restore activation semantics;
- Inventory application commands/bootstrap/UI/photos;
- Reminder, notification, schedule, Living Plan, Work Chain and other source
  records.

## Exact allowlist

1. `mobile/lib/domain/inventory_models.dart` — new
2. `mobile/lib/storage/app_database.dart`
3. `mobile/lib/application/mobile_backup_application.dart`
4. `mobile/test/inventory_geometry_test.dart` — new
5. `mobile/test/inventory_schema_migration_test.dart` — new
6. `mobile/test/app_database_test.dart` — conditional focused regression only
7. `mobile/test/mobile_backup_application_test.dart` — conditional DB-smoke regression only
8. `.cse/tasks/509_task.md`
9. `.cse/results/509_result.md`

Any tenth path or any need for application/bootstrap/UI/platform/pubspec/
attachment-store/protocol/roadmap edits is a stop-and-report condition.

## Required implementation behavior

- Decode accepts only the exact semantic JSON shape (input key order and
  insignificant whitespace may differ), rejects unknown/missing keys and
  always emits fixed-key-order whitespace-free canonical JSON.
- Geometry structures and exposed collections are immutable; empty DRAFT
  geometry is valid while finalizable geometry requires the canonical minimum.
- Schema 20 creates exactly the contract tables, indices and additive triggers,
  with exact project isolation, lifecycle/identity immutability, partial
  uniqueness, range/quantization/quantity guards, non-branching placement
  history, append-only receipts/events and no physical delete.
- Migration failure rolls back every schema-20 object/history/version write and
  leaves schema 19 usable without changing existing rows.
- Backup adoption changes only the current database required-table list.

## Validation authority

Validation class: `persistence`.

Final-source order:

1. exact changed/protected path audit;
2. format touched Dart;
3. one focused Flutter test invocation containing only new/touched authorized tests;
4. only for a proven same-scope mechanical defect: one narrow correction and
   exactly one focused retry;
5. after focused PASS, exactly one `flutter analyze --no-pub` invocation;
6. only for a proven same-scope analyzer defect: one narrow correction and
   exactly one analyzer retry;
7. `git diff --check`;
8. additive migration and protected drift audit;
9. final branch/head/worktree/staging/remote-divergence audit.

Forbidden: full Flutter suite, widget/integration tests, build/APK/AAB/release
gate, emulator, ADB, physical device, owner real data or app sandbox access.

Automated application tests are disabled generally, but the exact focused
synthetic geometry/migration invocation is explicitly authorized by Issue #509.

## Manual test, build and publication

- Manual Test Register: #479
- Manual test IDs: none required for this non-visible persistence child
- Manual test status: `N/A — synthetic persistence child`
- Build/artifact authority: none
- Owner-phone installation authority: false
- First owner-phone eligibility: Slice 6 only, after Issue #502 PASS and separate authority
- Publication: minimal commit(s), normal push, one Draft PR, Issue/PR evidence
- Ready/merge/Issue closure/Slice 1B authority: not granted

## Stabilization budget and stop conditions

- Primary implementation window: `1`
- Same-scope narrow correction budget: up to `3`, while the final test/analyzer
  invocation budgets remain exact
- Focused test retry: at most `1`, only after proven mechanical correction
- Analyzer retry: at most `1`, only after proven mechanical correction
- Environment-only recovery: at most `1` after exact root cause

Stop immediately for allowlist expansion, contract ambiguity/redesign, need to
rebuild/rename/drop/rewrite an existing DB object, unsafe invariant weakening,
schema-19 rollback uncertainty, backup/attachment-byte change, owner data/device
risk, destructive operation or visible routing mismatch.

## Required final classification

Success only:

`SLICE_1A_IMPLEMENTED — SYNTHETIC PERSISTENCE TESTS PASS — INDEPENDENT REVIEW REQUIRED`

Otherwise publish one precise fail-closed blocker state. Completion evidence
must include final SHA, exact paths, test/analyzer/diff results, schema/backup/
version/platform impact, Draft PR status, execution record and R4 review
recommendation.
