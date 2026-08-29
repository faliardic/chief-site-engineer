# Issue #535 Task — Inventory Spatial v1 Slice 6.4 Phase A

## Authority and status

- Parent / V2 item: Epic #506 — Inventory Map v1
- Current Issue: #535
- Canonical execution authority: Issue #535 comment `5464356178`
- Authority URL: <https://github.com/faliardic/chief-site-engineer/issues/535#issuecomment-5464356178>
- Execution phase: Slice 6.4 Phase A — integrated regression closure
- Implementation status: `IN_PROGRESS`
- Manual test status: `PENDING / NOT RUN`
- Official local repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Expected base: `baa7beff186e3fee95f1fb439d92045d7ba1af4e`
- Synchronized local `master`: `baa7beff186e3fee95f1fb439d92045d7ba1af4e`
- Synchronized `origin/master`: `baa7beff186e3fee95f1fb439d92045d7ba1af4e`
- Master divergence at start: `0/0`
- Branch: `codex/issue-535-inventory-spatial-closure`
- First repository write: this file

## Risk and model routing

```yaml
policy: CSE-MRP-1.0
task_risk: R4
requested_model: gpt-5.6-sol
requested_reasoning_effort: max
assistant_reasoning_recommendation: Extra High
execution_mode: local Codex execution
orchestration: single primary agent; no delegated implementation
allowed_fallback: none for a visible mismatch
runtime_actual_model: unknown
runtime_actual_reasoning_effort: null
runtime_actual_verification: unverified
review_floor: fresh independent R4 review
fail_closed_if_visible_mismatch: true
```

The launch surface does not expose independently verifiable runtime model and
effort metadata. The owner request is recorded exactly; runtime actuals are not
inferred. The review floor therefore remains fresh independent R4 review.

## Canonical source manifest

The following tracked authorities were read for this new task. Hashes are
SHA-256 values computed on the exact base before this first write.

| Source | Lines | Bytes | SHA-256 |
| --- | ---: | ---: | --- |
| `AGENTS.md` | 306 | 11038 | `bb00551caecbd2c19af6ccff0fe9c93acfa71aade05288b303f6006be0be616d` |
| `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md` | 1365 | 50475 | `5899a8fe03e8ab7ca8ce204ddf7a271686bda0668b08a828645649495539e333` |
| `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md` | 638 | 28426 | `f2c00b649cd1dceb19dc0bd1d284713138dbfbd8ee3332b9581afd107a0c20d5` |
| `docs/protocols/CSE_MODEL_REASONING_ROUTING_POLICY.md` | 185 | 8423 | `e1f55336657ecd79cb68cbae458341a811f0bb33867ac06b71163a5a8c8c320b` |
| `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md` | 328 | 9437 | `c12a57885f31144dc15cbbd3a07ab59527489a533ce5d8b444664ecf7710440d` |
| `docs/protocols/CSE_WORKFLOW_ACCELERATION_PROTOCOL.md` | 334 | 11480 | `7765bcebfb7b25b12e60fb44767d49c9d537393786fa0026561e1593073d297d` |
| `docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md` | 243 | 8472 | `b1685ce1610593195282b3b7c9038009ef8cd365d7c1314cb2356fc425bb383a` |
| `docs/protocols/CSE_CODEX_INSTRUCTION_COMMENT_PROTOCOL.md` | 284 | 8712 | `e6585e4a217d63d6717973121512338a3edfd24091c3eb0df6ea573ec8a797c6` |
| `docs/protocols/CSE_PROJECT_SOURCE_REGISTER.md` | 96 | 5569 | `f96fc9b1ef8bd12a6a4515a707726d84ee9a86a1a28bf6f20c5217e2954212cb` |
| `docs/v2/CSE_V2_SCOPE.md` | 690 | 36599 | `7e988d10ce55e147a6e6a197597a458d5e1ac57078ce7d1dcba3a58f294e12bb` |
| `ROADMAP.md` | 499 | 23061 | `5881856940260ae79961da2d8896b901b9155ffec1906285ef15acbf994c6166` |

GitHub repository truth also read before this write:

- Issue #535 body and authority comment `5464356178`;
- Issue #479 relevant `MT-535-*` state: no existing entries;
- merged PR chain #528, #530, #532 and #534;
- open PR list: empty at task start;
- secondary `.cse/state/project_state.json`: stale factual mirror and not used
  to override current GitHub/repository truth.

## Locked source chain and contracts

- PR #528 merge commit `30c45d702a90c90a910e0eee39656c452a232b1c`
  — revised Slice 6.1 foundation.
- PR #530 merge commit `b68ceca5cf51773cb3067d9cf4090a7181935289`
  — Agenda transient-project diagnostic correction in the merged chain.
- PR #532 merge commit `237e2024b856a9bc71e226e958eeebb56bee9d78`
  — Slice 6.2 floor navigation.
- PR #534 merge commit `baa7beff186e3fee95f1fb439d92045d7ba1af4e`
  — Slice 6.3 block lifecycle reconciliation.
- SQLite schema: exact `22`.
- Backup format: exact `1`.
- Mobile version: exact `0.1.0+1`.
- Changed contract: documentation/evidence-only integrated closure; no product,
  schema, storage, migration, dependency, platform, package, permission,
  signing, test, bootstrap, `main.dart`, or `app.dart` behavior change.

## Exact write allowlist

1. `.cse/tasks/535_task.md`
2. `.cse/results/535_result.md`
3. `docs/v2/CSE_INVENTORY_MAP_V1_CONTRACT.md`
4. `docs/v2/CSE_V2_SCOPE.md`
5. `docs/v2/CSE_INVENTORY_MAP_V1_ACCEPTANCE.md`

Every production Dart path, every test path, storage/migration, pubspec and
lockfile, platform/package/permission/signing, bootstrap/main/app, workflow,
artifact, export and state path is protected. Any need outside the five paths
is an immediate stop-and-report condition.

## Authorized work

1. Create this task record and an initial factual result record.
2. Run the exact nine-file integrated Flutter gate once, with no retry.
3. On failure, record exact terminal tally, failing test, assertion/exception
   and source evidence; do not run analyzer or publish and stop.
4. On pass, run `flutter analyze --no-pub` exactly once.
5. Create the compact Inventory Map v1 acceptance handoff, update only the two
   allowed canonical documents, and preserve the distinction between automated
   closure and pending owner acceptance.
6. Complete full and staged diff/scope/drift audits.
7. If every gate passes, create one minimal documentation-only commit, push the
   canonical branch, open one Draft PR referencing #535 and #506, publish Issue
   and PR evidence, and register `MT-535-001..007` in Issue #479 as
   `PENDING / NOT RUN`.
8. Stop for fresh independent R4 review and separate Phase-B authority.

## Exact validation authority

The only authorized Flutter test invocation is, from `mobile/`, exactly once:

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

Retry budget: `0`.

Only after that invocation passes:

- `flutter analyze --no-pub` exactly once;
- full `git diff --check`;
- exact changed-path and protected-drift audit;
- schema `22`, backup `1`, version `0.1.0+1` audit;
- full and staged diff review;
- staged `git diff --check`;
- branch/head/worktree/divergence checks.

No formatter is needed or authorized because Dart/test files are read-only and
the writable production surface is Markdown only.

## Manual tests and build authority

- `MT-535-001..007`: `PENDING / NOT RUN`.
- Manual Test Register: Issue #479.
- Automated Phase-A evidence must not be inferred as owner/manual PASS.
- Build/artifact authority: none.
- APK, AAB, emulator, device, ADB, MAIN package, acceptance installation and
  launch: forbidden in this phase.
- Phase B requires a separate explicit owner authority.

## Stabilization and stop conditions

- Automated gate invocations: one.
- Automated gate retries: zero.
- Product/test corrections under Issue #535: zero.
- Analyzer invocations after gate PASS: one; analyzer retries: zero.
- Stop immediately on any test failure, analyzer failure, allowlist expansion,
  product/source defect, schema/storage/migration need, protected drift,
  destructive operation need, or source-truth uncertainty.
- Do not start Slice 7 or DWG work.

## Publication authority

- One minimal documentation-only commit: authorized only after every gate and
  audit passes.
- Normal push to `codex/issue-535-inventory-spatial-closure`: authorized.
- One Draft PR referencing #535 and #506: authorized.
- Issue and PR evidence comments: authorized.
- Manual Test Register #479 comment: authorized only with all seven tests
  `PENDING / NOT RUN`.
- Ready: not authorized.
- Merge: not authorized.
- Issue closure: not authorized.
- Release/store/publication: not authorized.

## Required completion evidence

The result and final report must include source/base/head, changed paths, exact
test tally and exit, analyzer result, full/staged diff checks, exact allowlist
and protected drift, schema/backup/version/platform/package/permission impact,
manual test status, commit/push/Draft PR state, Ready/merge state,
`execution_record`, and `review_recommendation`.
