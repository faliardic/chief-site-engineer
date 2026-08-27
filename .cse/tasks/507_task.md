# Issue 507 — Inventory Map v1 Slice 0 canonical contract

## Execution identity

- Official repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Parent / V2 item: Feature Epic #506 / Inventory Map v1
- Active Issue: #507
- Canonical authority: Issue #507 comment `5431797657`
- Expected base: `1d1b818b4b630a08fe6eb77157fe92b7a460b5c3`
- Branch: `docs/issue-507-inventory-map-v1-contract`
- Validation class: `docs`
- Status: `IN_PROGRESS`

## Start-state evidence

- Repository root resolved to the official `V:` path.
- `master == origin/master == HEAD == 1d1b818b4b630a08fe6eb77157fe92b7a460b5c3`
  before the first write.
- `origin/master...master` divergence was `0/0`.
- The exact documentation branch was created from that base.
- Tracked/staged/untracked project drift was empty before the first write.
- GitHub open-PR inspection returned no open production PR.
- This file is the first authorized local write for Issue #507.

## Risk and model routing

```yaml
routing_request:
  policy_version: CSE-MRP-1.0
  task_risk: R4
  requested_model: gpt-5.6-sol
  requested_reasoning_effort: max
  execution_mode: standard
  orchestration: single-agent
  validation_class: docs
  allowed_fallback: none
  runtime_actual_model: unknown
  runtime_actual_reasoning_effort: null
  runtime_match: unverified
  fail_closed_if_visible_mismatch: true
  assistant_review_floor: gpt-5.6-sol / max
  independent_review_required: true
```

The launch surface did not expose verifiable runtime model/effort metadata.
No fallback or downgrade is inferred. The R4 independent source/contract review
floor therefore remains mandatory.

## Canonical source manifest at task start

The Git blob and file SHA-256 values below bind the local pre-read to the exact
base contents. GitHub Issue bodies/comments are bound separately by repository,
Issue number and comment ID because they are not repository blobs.

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
| `docs/v2/CSE_V2_SCOPE.md` | `f9321bc428ebf4c7d4a246a44b788bd615f9476f` | `b1e759e380f89c0c3a20d5deecedefa04fc8d48e1a654c31cb8caeed20965f96` |
| `ROADMAP.md` | `a6fb1697d52e4787f821880a73a2a27b97f185e5` | `1ece7b5fac1fa54f5a3b32206060ef21f0dfb8b8354898cacbff20643fb07a9e` |
| `docs/project_decisions.md` | `237feef1657d12c66662f1d8ed2190f0914c3b93` | `8b4bf4ca24c7bb2eb04b0a68c3a01f41d9623d6908ec6eda10e19d11586bdd29` |

GitHub authority read:

- Epic #506 body;
- Issue #507 body and owner comment `5431797657`;
- Issue #501, #502, #503 and #499 bodies for cumulative recovery,
  backup/update, restore and owner-phone safety boundaries.

## Inspected current source contracts

No source file is authorized for modification. The following paths and exact
components were read to ground the documentation contract:

- `mobile/lib/app.dart`: `CseApp`, `BootstrapGate`, `MobileShell`,
  `_MobileShellState._destinations` and its six-destination `IndexedStack`.
- `mobile/lib/bootstrap/app_bootstrap.dart`: `BootstrapSuccess`, `AppBootstrap`,
  `SqliteAgendaApplication`, `SqliteConstructionLivingPlanApplication`,
  `SqliteMaterialRequestApplication` and `SqliteAttachmentCatalogApplication`
  construction/wiring.
- `mobile/lib/storage/app_database.dart`: `AppDatabase.schemaVersion`, migration
  transaction path, `_applyConstructionLivingPlanMigration`,
  `_applyMaterialRequestMigration`, `_applyAgendaPhoneCallMigration` and
  `_applyAttachmentV2Migration`; existing `projects`, `project_locations`,
  `project_living_plan_items`, `project_living_plan_command_receipts`,
  `project_living_plan_events`, `material_requests`, `material_request_events`,
  `managed_attachments`, `attachment_links`, `attachment_link_events` and
  `agenda_phone_call_contexts` contracts.
- `mobile/lib/application/mobile_backup_application.dart`:
  `_validateDatabaseFileUnchecked`, `_requireDatabaseIntegrity`,
  `_activeAttachmentRows`, `_manifestAttachmentRows` and format-1 database /
  attachment adoption boundaries.
- `mobile/lib/application/agenda_application.dart`,
  `mobile/lib/domain/agenda_models.dart` and
  `mobile/lib/domain/project_location_models.dart`: `AgendaApplication`,
  `ProjectLocationApplication`, `ProjectLifecycleApplication`,
  `SqliteAgendaApplication`, `MobileProject` and `MobileProjectLocation`.
- `mobile/lib/application/material_request_application.dart` and
  `mobile/lib/domain/material_request_models.dart`:
  `MaterialRequestApplicationPort`, `SqliteMaterialRequestApplication`,
  optimistic revision, transaction, replay and append-only event patterns.
- `mobile/lib/application/construction_living_plan_application.dart` and
  `mobile/lib/domain/construction_living_plan_models.dart`:
  `ConstructionLivingPlanApplicationPort`,
  `SqliteConstructionLivingPlanApplication`, durable command receipt,
  idempotent/no-op and verified history patterns.
- `mobile/lib/application/attachment_catalog_application.dart`,
  `mobile/lib/domain/attachment_models.dart` and
  `mobile/lib/platform/managed_attachment_store.dart`:
  `AttachmentCatalogApplication`, `SqliteAttachmentCatalogApplication`,
  `AttachmentCatalogMediaAccess` and `ManagedAttachmentStore`.

## Objective and changed contracts

Produce one implementation-grade normative contract for the first usable
`Kroki Tabanlı Dayanıklı Saha Envanteri v1`, with no unresolved material
product decision before Slice 1. The contract MUST lock:

- direct top-level `Envanter` access within a bounded six-destination shell;
- exact active-project isolation and shared Kroki/List source truth;
- an integer virtual geometry system, deterministic normalization/fingerprint,
  safe limits and revision compatibility;
- autosaved draft, immutable finalized revision and no-delete lifecycle;
- durable asset/lot, history-preserving placement and append-only event model;
- an additive schema `19 -> 20` proposal, backup-format-1 adoption and shared
  attachment-binary strategy;
- exact editor/view interaction semantics and Slices 1–6 ownership;
- cumulative P0 rules from Issues #501, #502, #503 and #499.

Truth-sync MUST state that V2.12 and later planned product work is paused,
Inventory Map v1 under Epic #506 is current, P0 owner-phone data safety retains
precedence, and Inventory is not yet implemented.

## Exact allowed paths

1. `.cse/tasks/507_task.md`
2. `.cse/results/507_result.md`
3. `docs/v2/CSE_INVENTORY_MAP_V1_CONTRACT.md`
4. `docs/v2/CSE_V2_SCOPE.md`
5. `ROADMAP.md`
6. `docs/project_decisions.md`

Any seventh path requires fail-closed stop and owner escalation.

## Protected and forbidden scope

- Production code, tests, SQLite code/migrations, Android/iOS/platform files,
  `pubspec.yaml`, `pubspec.lock`, signing, permissions, protocols, `AGENTS.md`,
  `CHANGELOG.md` and `.cse/state` MUST NOT change.
- Current facts remain schema `19`, backup format `1`, mobile version
  `0.1.0+1`, package `com.faliardic.sefim`.
- Flutter/Dart analysis, unit/widget/integration tests, builds, emulator, ADB,
  device operations and owner-phone installs are not authorized.
- Issue #501 remains unresolved until owner verification; no P0 Issue is closed
  or marked complete by this documentation Slice.

## Validation plan

Run only:

1. exact six-path allowlist audit;
2. Markdown syntax, heading and relative-link consistency checks;
3. unresolved placeholder, state-name, table-name and numeric-geometry
   consistency searches;
4. `git diff --check`;
5. protected-diff audits for `mobile/`, tests, schema/migrations,
   Android/iOS/platform, pubspec/lock, protocols and `AGENTS.md`;
6. static fact audit for schema `19`, backup format `1`, version `0.1.0+1`,
   package `com.faliardic.sefim` and the exact master-at-start SHA;
7. branch/head/divergence/final working-tree evidence after publication.

Automated application tests: disabled by owner authority.
Manual application tests: not applicable to this docs-only Slice; no PASS may
be inferred for Inventory or existing V2.11 tests.
Build/artifact authority: none.

## Stabilization and stop conditions

- Primary documentation implementation window: `1`.
- Narrow same-scope corrections: within current workflow budget only.
- Stop before publication for repository drift, seventh path, unresolved
  material product decision, unbounded navigation redesign, non-additive or
  cross-project-unsafe schema proposal, pixel/float source geometry, or any
  need for production/test/build/device work.

## Publication authority

If and only if all documentation gates pass:

- one intentional docs-only commit;
- normal push of the exact branch;
- one Draft PR to `master`;
- concise Issue and PR evidence;
- stop for independent source/contract review.

Ready, merge, Issue closure, Slice 1 implementation, build, artifact and phone
operations are not authorized. Post-merge local synchronization is not part of
this execution because merge authority is absent.
