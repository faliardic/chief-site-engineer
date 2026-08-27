# Issue #514 Task — Inventory Map v1 Slice 1C

## Authority and start state

- Parent / V2 item: Epic #506 / Inventory Map v1 persistence Slice 1C
- Canonical contract: Issue #507 / merged PR #508 / `docs/v2/CSE_INVENTORY_MAP_V1_CONTRACT.md`
- Execution authority: https://github.com/faliardic/chief-site-engineer/issues/514#issuecomment-5442180996
- Official repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Expected base: `e36637fd8bb050c876cd510d06ce3b326b91ec19`
- Verified initial `master == origin/master`: `e36637fd8bb050c876cd510d06ce3b326b91ec19`
- Verified open production PR count before branch creation: `0`
- Verified tracked/staged drift before branch creation: `0 / 0`
- Branch: `codex/issue-514-inventory-backup-bootstrap-closure`
- Schema: exact `20`
- Backup format: exact `1`
- Mobile version: `0.1.0+1`
- Package: `com.faliardic.sefim`
- Validation class: `persistence`

## Model routing

```yaml
model_routing:
  policy_version: CSE-MRP-1.0
  task_risk: R4
  codex_model: gpt-5.6-sol
  codex_reasoning_effort: max
  execution_mode: standard
  orchestration: single-agent
  selection_reason: Populated backup/restore, bootstrap and persistence integrity closure.
  routing_request_evidence: https://github.com/faliardic/chief-site-engineer/issues/514#issuecomment-5442180996
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

## Canonical source manifest

SHA-256 values were read from the exact synchronized base before substantive edits.

| Source | SHA-256 |
| --- | --- |
| `AGENTS.md` | `bb00551caecbd2c19af6ccff0fe9c93acfa71aade05288b303f6006be0be616d` |
| `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md` | `5899a8fe03e8ab7ca8ce204ddf7a271686bda0668b08a828645649495539e333` |
| `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md` | `f2c00b649cd1dceb19dc0bd1d284713138dbfbd8ee3332b9581afd107a0c20d5` |
| `docs/protocols/CSE_CODEX_INSTRUCTION_COMMENT_PROTOCOL.md` | `e6585e4a217d63d6717973121512338a3edfd24091c3eb0df6ea573ec8a797c6` |
| `docs/protocols/CSE_MODEL_REASONING_ROUTING_POLICY.md` | `e1f55336657ecd79cb68cbae458341a811f0bb33867ac06b71163a5a8c8c320b` |
| `docs/protocols/CSE_WORKFLOW_ACCELERATION_PROTOCOL.md` | `7765bcebfb7b25b12e60fb44767d49c9d537393786fa0026561e1593073d297d` |
| `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md` | `c12a57885f31144dc15cbbd3a07ab59527489a533ce5d8b444664ecf7710440d` |
| `docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md` | `b1685ce1610593195282b3b7c9038009ef8cd365d7c1314cb2356fc425bb383a` |
| `docs/protocols/CSE_PROJECT_SOURCE_REGISTER.md` | `f96fc9b1ef8bd12a6a4515a707726d84ee9a86a1a28bf6f20c5217e2954212cb` |
| `docs/v2/CSE_V2_SCOPE.md` | `3fb70a0c80c293b17a38214f4b717c1bafe539526289eaf86a0be1d4683aee51` |
| `ROADMAP.md` | `5881856940260ae79961da2d8896b901b9155ffec1906285ef15acbf994c6166` |
| `docs/v2/CSE_INVENTORY_MAP_V1_CONTRACT.md` | `6ed6285a565d5cc032116b5643f5565757d97acb7acc8325188f19dc8cd0bbca` |

Relevant merged/source baseline:

- Slice 1A final reviewed head `7f79fc55e7c1096ab7ac1578fa1697173c97cc63`; squash merge `d93305fd21d5e89fb300913e7ae52ae5893618b3`.
- Slice 1B final reviewed head `c156af34c5ff3a8309513a5f2c1aaac98abb2e84`; squash merge/base `e36637fd8bb050c876cd510d06ce3b326b91ec19`.
- `mobile/lib/application/inventory_application.dart`: `d39e0f9eee2fccfc5ccabc159a18eecb09c9e5a36d7134f01211977ec926bd18`
- `mobile/lib/application/mobile_backup_application.dart`: `ae4fc3cd5e7111205d8ed33c20733307fe389eeee5fe613eb25a860477816271`
- `mobile/lib/bootstrap/app_bootstrap.dart`: `f605fda8e950121018d23c3dec22dbef23fd7111a4692da894c14103eb9d1a61`
- `mobile/test/mobile_backup_application_test.dart`: `d07b9569b8cdff5a71dde2c9270d84e0faf77188e174430e7f53a1a604a4b162`
- `mobile/test/app_bootstrap_test.dart`: `03d3fe87d00e97fd86ede76aa4e5a1a9c0cb7c0b23bd7479be7456088fe2535e`
- read-only `mobile/test/inventory_application_test.dart`: `bc56febf0ffb7266ba27c19462eb74e14a3d2f9ddb4fe27495f800d2e3fb0049`
- read-only `mobile/lib/storage/app_database.dart`: `73f48ac8ce08150a20fc1fb1f29afb5c0d1b37c2cd98e09511c87c30e3bc0dc1`

## Changed contracts and objective

- Expose the merged typed `InventoryApplicationPort` through `BootstrapSuccess`.
- Production bootstrap constructs a path-backed `SqliteInventoryApplication` after the temporary bootstrap DB handle is closed.
- Hand-built `BootstrapSuccess` defaults to a const zero-I/O Inventory implementation that fails every operation with `inventory_unavailable`.
- Prove a populated, non-photo Inventory graph survives production format-1 backup, preflight and normal restore with exact semantic equality.
- Prove restored typed reads, receipt replay/no-op/conflict behavior, schema/integrity/FK truth and schema-19 empty-Inventory migration compatibility.
- Preserve existing restore ownership and rollback behavior. Do not begin editor/UI work.

## Exact allowlist

1. `mobile/lib/bootstrap/app_bootstrap.dart`
2. `mobile/lib/application/inventory_application.dart` — only the safe unavailable implementation
3. `mobile/lib/application/mobile_backup_application.dart` — conditional only after a proven focused-test production gap
4. `mobile/test/app_bootstrap_test.dart`
5. `mobile/test/mobile_backup_application_test.dart`
6. `.cse/tasks/514_task.md`
7. `.cse/results/514_result.md`

No eighth path. `mobile/test/inventory_application_test.dart` and `mobile/lib/storage/app_database.dart` are read-only.

## Protected paths and contracts

- No `app_database.dart`, schema, migration or Inventory domain-model edit.
- No `app.dart`, navigation, shell, Inventory feature/editor/UI edit.
- No attachment store/catalog/album/reconciliation or manifest-query edit.
- No pubspec/lock, Android/iOS/platform/permission/signing/orientation/version/package edit.
- No Schedule, Reminder, Agenda, Living Plan, Work Chain, material request, attendance, concrete or existing attachment source mutation.
- Inventory attachment-link rows and managed Inventory attachment bytes remain zero.
- No owner phone, owner data root, build, APK/AAB, emulator, ADB or device operation.
- P0 Issues #501/#502/#503/#499 remain unresolved/cumulative and are not changed by this work.

## Validation authority

Final candidate only, exact order:

1. exact changed/protected-path audit;
2. touched Dart formatting;
3. exactly one focused invocation: `flutter test --no-pub test/app_bootstrap_test.dart test/mobile_backup_application_test.dart`;
4. only for one proven same-scope mechanical defect: one narrow correction and one focused retry;
5. after focused PASS, exactly one `flutter analyze --no-pub`;
6. only for one proven same-scope mechanical analyzer defect: one narrow correction and one analyzer retry;
7. `git diff --check`;
8. schema/backup/version/package/platform/permission/signing/attachment/static drift audit;
9. tracked backup/SQLite/staging artifact audit;
10. final branch/worktree/staging/remote-divergence audit.

Full suite, unrelated widget/integration tests, build/release gates, APK/AAB,
emulator, ADB/device, owner sandbox and owner data are forbidden.

## Manual tests and artifacts

- Manual Test Register: https://github.com/faliardic/chief-site-engineer/issues/479
- Manual test IDs: none required by authority
- Manual test status: `N/A — synthetic persistence child`
- Automated application tests: only the exact focused persistence invocation above is expressly authorized.
- Build/artifact authority: not granted.

## Stabilization and stop conditions

- Primary implementation window: `1`.
- Same-scope narrow source corrections: up to `3`, subject to the exact focused/analyzer retry limits above.
- Environment-only recovery: at most `1` after exact root cause.
- Stop before widening for any eighth path, schema/format/restore-swap/attachment redesign, production data risk, unknown source truth, destructive operation or exhausted retry/correction budget.
- `mobile_backup_application.dart` must remain unchanged unless the first focused populated round-trip proves a real production gap.

## Publication authority

- Minimal intentional commit(s), normal push and exactly one Draft PR to `master` are authorized after every gate PASSes.
- Ready, merge, Issue closure, Slice 2, build, install, release and store actions are not authorized.
