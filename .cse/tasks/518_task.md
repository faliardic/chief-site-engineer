# Issue #518 Task — Inventory Map v1 Slice 3

## Authority and start state

- Parent / V2 item: Epic #506 / Inventory Map v1, Slice 3
- Canonical execution authority: https://github.com/faliardic/chief-site-engineer/issues/518#issuecomment-5451176703
- Canonical contract: Issue #507 / merged PR #508 / `docs/v2/CSE_INVENTORY_MAP_V1_CONTRACT.md`
- Predecessor: Issue #516 / merged PR #517
- Expected base: `d3cad2e3ab74b9ab285efa0bfa8900cb541cad16`
- Branch: `codex/issue-518-inventory-asset-placement-core`
- Start audit: `master == origin/master == expected base`; open production PR `0`; tracked/staged drift `0`; conflicting Slice-3 feature files `0`
- Schema / backup / version / MAIN package: `20` / `1` / `0.1.0+1` / `com.faliardic.sefim`

## Risk and execution routing

- Task risk: `R4`
- Requested model / effort: `gpt-5.6-sol` / `max`
- Runtime actual model / effort: `unknown` / `null` / `unverified`
- Independent review floor: `gpt-5.6-sol/max` / Extra High
- Execution mode: `standard`
- Orchestration: `single-agent`
- Validation class: `domain_widget`

## Changed contracts

- Standalone normal map-view core for one explicit project with one exact non-archived primary sketch and exact ACTIVE revision.
- Empty-map inverse-transform capture with inclusive `4096 x 3072` bounds, exact step-4 quantization and lower half-step tie.
- Quick durable asset creation through the existing atomic `CreateInventoryAssetCommand`, with one placement whose quantity equals total quantity.
- Marker projection directly from canonical `listAssets`, with exact detail intent, non-color-only name/quantity/status semantics and minimum 48x48 hit target.
- Exact asset detail plus optimistic metadata/status/quantity commands, confirmed history-preserving move, recoverable archive/unarchive and canonical history.
- Canonical reload after every successful mutation; session preview/selection is never durable source truth.

Direct source inspection proves the merged Inventory port, domain commands and read projections already cover this Slice. No application/domain/schema mutation is planned.

## Exact allowlist

1. `mobile/lib/features/inventory/inventory_map_view.dart` — new
2. `mobile/lib/features/inventory/inventory_asset_quick_form.dart` — new
3. `mobile/lib/features/inventory/inventory_asset_detail_sheet.dart` — new
4. `mobile/lib/application/inventory_application.dart` — conditional only for a proven narrow integration gap
5. `mobile/lib/domain/inventory_models.dart` — conditional only for a proven narrow typed projection gap
6. `mobile/test/inventory_asset_core_test.dart` — new
7. `mobile/test/inventory_application_test.dart` — conditional same-scope assertions only
8. `.cse/tasks/518_task.md`
9. `.cse/results/518_result.md`

No tenth path is authorized. Current source inspection shows no path 4, 5 or 7 change is necessary.

## Protected paths and contracts

- Read-only: existing sketch canvas/editor, `app.dart`, `app_database.dart`, backup, bootstrap, attachment/catalog/reconciliation, pubspec/lock and platform files.
- No shell/navigation/project-picker/List sibling/search/filter/list-map focus, overlap clustering or Inventory photo behavior.
- No schema/migration, backup-format, dependency, permission, signing, package, version or platform mutation.
- No coordinate overwrite, second map/list source, hard delete, partial multi-aggregate mutation or silent multiple-placement selection.
- No Reminder, notification, Agenda, Living Plan, Work Chain, Puantaj, Beton or unrelated module mutation.
- No real owner data, owner sandbox, build, install or owner-phone operation.

## Source-level and focused checks

Final-candidate sequence is exact:

1. exact changed/protected-path audit;
2. format touched Dart files;
3. exactly one focused invocation: `flutter test --no-pub test/inventory_application_test.dart test/inventory_asset_core_test.dart`;
4. only one proven same-scope mechanical correction and one focused retry if required;
5. after focused PASS, exactly one `flutter analyze --no-pub`;
6. only one proven same-scope analyzer correction and one analyzer retry if required;
7. `git diff --check`;
8. schema 20 / backup 1 / version 0.1.0+1 / package and protected-drift audit;
9. tracked SQLite/test DB/backup/APK/AAB/generated-artifact audit;
10. final branch/head/staging/worktree/remote-divergence audit.

The exact focused domain/widget invocation is explicitly authorized. Full suite, unrelated tests, integration tests, build/APK/AAB, emulator, ADB/device, scripted acceptance and owner-data operations are forbidden.

## Manual Test Register

- Register: https://github.com/faliardic/chief-site-engineer/issues/479
- Planned stable IDs: `MT-518-001..014`
- Families: quick create; required/OTHER fields; marker semantics; marker-to-exact-detail; metadata; status; quantity; move preview/cancel/confirm; same-coordinate no-op; archive; unarchive target; history; relaunch persistence.
- Manual test status: `PENDING`
- Prior `MT-516-001..012` remain `PENDING` and are not run or altered.
- Slice-3 manual tests will be registered after source publication and will not be run or marked PASS by Codex.

## Build, budget, escalation and publication

- Build/artifact authority: not granted.
- Primary implementation: `1`; same-scope narrow source corrections: up to `3`; focused retry: at most `1`; analyzer retry: at most `1`; environment recovery: at most `1` after exact cause.
- Immediate escalation: tenth/protected path; new product decision; schema/backup/attachment/shell/dependency/platform/permission/signing/package/version change; transaction/identity/history redesign; coordinate overwrite; partial create; hard delete; silent multiple-placement selection; owner-data risk; unproven cause; exhausted retry.
- Publication authority: minimal intentional commit(s), normal push and exactly one Draft PR to `master` only after all gates PASS.
- Not authorized: Ready, merge, Issue/Epic close, Slice 4, build/install/device/release.

## Canonical source manifest at task start

All hashes are SHA-256 of the exact merged files read or unchanged canonical ruleset files verified before the first write:

```text
AGENTS.md bb00551caecbd2c19af6ccff0fe9c93acfa71aade05288b303f6006be0be616d
CSE_UNIFIED_PROJECT_SOURCE.md 5899a8fe03e8ab7ca8ce204ddf7a271686bda0668b08a828645649495539e333
CSE_PROJECT_INSTRUCTIONS.md f2c00b649cd1dceb19dc0bd1d284713138dbfbd8ee3332b9581afd107a0c20d5
CSE_CODEX_INSTRUCTION_COMMENT_PROTOCOL.md e6585e4a217d63d6717973121512338a3edfd24091c3eb0df6ea573ec8a797c6
CSE_MODEL_REASONING_ROUTING_POLICY.md e1f55336657ecd79cb68cbae458341a811f0bb33867ac06b71163a5a8c8c320b
CSE_WORKFLOW_ACCELERATION_PROTOCOL.md 7765bcebfb7b25b12e60fb44767d49c9d537393786fa0026561e1593073d297d
CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md c12a57885f31144dc15cbbd3a07ab59527489a533ce5d8b444664ecf7710440d
CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md b1685ce1610593195282b3b7c9038009ef8cd365d7c1314cb2356fc425bb383a
CSE_PROJECT_SOURCE_REGISTER.md f96fc9b1ef8bd12a6a4515a707726d84ee9a86a1a28bf6f20c5217e2954212cb
CSE_V2_SCOPE.md 3fb70a0c80c293b17a38214f4b717c1bafe539526289eaf86a0be1d4683aee51
ROADMAP.md 5881856940260ae79961da2d8896b901b9155ffec1906285ef15acbf994c6166
CSE_INVENTORY_MAP_V1_CONTRACT.md 6ed6285a565d5cc032116b5643f5565757d97acb7acc8325188f19dc8cd0bbca
inventory_models.dart 7e69122a362ef55582f6fb0bc52c934a477e374cdf19deac567e3a4a48f4f84e
inventory_application.dart 6d510c292b44e66a4c6a981904846f9c9a3332905968eb8726ed764f0fc5abcc
inventory_application_test.dart bc56febf0ffb7266ba27c19462eb74e14a3d2f9ddb4fe27495f800d2e3fb0049
inventory_sketch_canvas.dart f38bfa2f9ef46556ea85c4a4ab33eb4c1237c5a82cb7bb1b523e5bf6e94c9c89
inventory_sketch_editor_page.dart c3f8a66b8761120a6d15991d8aaad5c28559b454d6a95988abd09891dcd2e559
app.dart e99a1c2064a80504f89fd9ba41d2bd96316101ae8b8726b8cb5a96763b296517
app_database.dart 73f48ac8ce08150a20fc1fb1f29afb5c0d1b37c2cd98e09511c87c30e3bc0dc1
record_id.dart 95a618bd02ec0750ec719b3bbf8d4ff3235f4272d66cb977da6b0ab890381c29
mobile_backup_application.dart ae4fc3cd5e7111205d8ed33c20733307fe389eeee5fe613eb25a860477816271
app_bootstrap.dart cc4217fd47a80193ebbadc0cb1d9e029564c79e4ced4b61becba61f3c21015bf
pubspec.yaml 704ee4a64b534d14264984f68b8275570b8f87c06190ee48340830d971eabfa7
pubspec.lock 2b75e59a051a8cfcfec3d6883b04779205c63678b0f4814a4535e50db77dc441
```

Issue #506, Issue #518, owner authority comment `5451176703`, merged PR #517 final source/evidence and Issue #479 current `MT-516-001..012 = PENDING` truth were also read from GitHub before this first write.
