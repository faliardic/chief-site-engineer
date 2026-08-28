# Issue #516 Task — Inventory Map v1 Slice 2

## Authority and start state

- Parent / V2 item: Epic #506 / Inventory Map v1, Slice 2
- Canonical execution authority: https://github.com/faliardic/chief-site-engineer/issues/516#issuecomment-5447720489
- Canonical contract: Issue #507 / merged PR #508 / `docs/v2/CSE_INVENTORY_MAP_V1_CONTRACT.md`
- Expected base: `6492736fbb645a54af7a0f9403a5912f934ba2b7`
- Branch: `codex/issue-516-inventory-landscape-sketch-editor`
- Start audit: `master == origin/master == expected base`; open production PR `0`; tracked/staged drift `0`; conflicting Inventory editor source `0`
- Existing foundation: Issues #509, #512 and #514; merged PRs #511, #513 and #515
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

- Landscape-only `4096 x 3072` schematic-sketch editor with exact DRAW / SELECT / PAN behavior.
- Immutable candidate geometry, deterministic selection/delete, session-only undo/redo capped at 100.
- Presentation-only fit/pan/zoom with `0.5x..4.0x`; source remains integer virtual coordinates.
- Exact 500 ms acknowledged autosave, serialized save state, durable DRAFT recovery and safe retry/discard/back/lifecycle handling.
- Explicit create/recover and edit-active launch intents using the existing Inventory application port.
- Existing transactional finalize command only after exact latest durable acknowledgement.
- Route-scoped landscape entry and awaited restoration to the exact standard orientation set.

## Exact allowlist

1. `mobile/lib/features/inventory/inventory_sketch_editor_page.dart` — new
2. `mobile/lib/features/inventory/inventory_sketch_canvas.dart` — new
3. `mobile/lib/application/inventory_application.dart` — conditional only for a proven narrow integration gap
4. `mobile/test/inventory_sketch_editor_test.dart` — new
5. `mobile/test/inventory_geometry_test.dart` — conditional assertions only
6. `.cse/tasks/516_task.md`
7. `.cse/results/516_result.md`

No eighth path is authorized. Current source inspection shows no application-port gap, so path 3 is presently not planned; the merged port already exposes create, primary load, start-edit, autosave and finalize with exact optimistic revisions.

## Protected paths and contracts

- Read-only: `inventory_models.dart`, `inventory_application_test.dart`, `app_database.dart`, bootstrap, `app.dart`, backup source, attachment source and all platform files.
- No schema/migration, backup-format, attachment, pubspec/lock, shell/navigation, platform, permission, signing, package or version mutation.
- No asset/placement/photo Slice 3 behavior and no Envanter shell/List/Kroki Slice 4 behavior.
- No schedule, Reminder, notification, Agenda, Living Plan, Work Chain, material-request, attendance or concrete mutation.
- No real owner data, owner sandbox, build, install or owner-phone operation.

## Source-level and focused checks

Final-candidate sequence is exact:

1. exact changed/protected-path audit;
2. format touched Dart files;
3. exactly one focused invocation: `flutter test --no-pub test/inventory_geometry_test.dart test/inventory_sketch_editor_test.dart`;
4. only one proven same-scope mechanical correction and one focused retry if required;
5. after focused PASS, exactly one `flutter analyze --no-pub`;
6. only one proven same-scope analyzer correction and one analyzer retry if required;
7. `git diff --check`;
8. schema 20 / backup 1 / version 0.1.0+1 / package and protected-drift audit;
9. tracked artifact audit;
10. final branch/head/staging/worktree/remote-divergence audit.

Automated application tests are disabled except for the exact focused domain/widget invocation explicitly authorized above. Full suite, unrelated tests, integration tests, build/APK/AAB, emulator, ADB/device and scripted acceptance are forbidden.

## Manual Test Register

- Register: https://github.com/faliardic/chief-site-engineer/issues/479
- Planned stable IDs: `MT-516-001..012`
- Families: open draw; closed draw; SELECT delete; undo/redo; pan/pinch/zoom/fit; autosave; successful back-save; failed back-save retry/discard; relaunch recovery; finalize; ACTIVE edit; orientation restoration.
- Manual test status: `PENDING`
- These tests will be recorded after publication and will not be run or marked PASS by Codex.

## Build, budget, escalation and publication

- Build/artifact authority: not granted.
- Primary implementation: `1`; same-scope narrow source corrections: up to `3`; focused retry: at most `1`; analyzer retry: at most `1`; environment recovery: at most `1` after exact cause.
- Immediate escalation: eighth/protected path, new product decision, schema/backup/platform/permission/signing/package/version change, source identity/history/transaction redesign, owner-data risk, unproven root cause, exhausted correction budget or destructive operation.
- Publication authority: minimal commit(s), normal push and exactly one Draft PR to `master` only after all gates PASS.
- Not authorized: Ready, merge, Issue/Epic close, Slice 3, build/install/device/release.

## Canonical source manifest at task start

All hashes are SHA-256 of the exact merged files read before the first write:

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
record_id.dart 95a618bd02ec0750ec719b3bbf8d4ff3235f4272d66cb977da6b0ab890381c29
inventory_geometry_test.dart c0f2c4eede81d96e2660445dde02a1f34916b17b4e4eb8c9d587418d304275ae
inventory_application_test.dart bc56febf0ffb7266ba27c19462eb74e14a3d2f9ddb4fe27495f800d2e3fb0049
app.dart e99a1c2064a80504f89fd9ba41d2bd96316101ae8b8726b8cb5a96763b296517
509_result.md 0f0a4b083e7ae8a024158543dbeef0cd33c5be7160bbac0f11736a3e5d988009
512_result.md 0cba903603cd902b1e9a013eb733bf22e007dffd984c6beede4d5524dbabbdb3
514_result.md 9972c69d9b97c29f7a2914857a433e9d985d42f6fb07687cde3810dcbfdbd093
Android app build e83ff986dd52920d110bf64f5ba757b5cba9a40c294347394eb99dbdcca4bc28
Android main manifest 183f2b7dbcd4f4413e0947e26b4d27bef1eaef1530062732a24e13c9ec7c352d
iOS Info.plist de7235168b47210ef89d172858e6e7cbbf8434c7a10d0243650e6ba3b50f21fd
iOS project c6de724828bf3a579853cc5bd3f0a85a4252f7d3f2b4005d80478e9d1ff8e7e2
```

Issue #516 body, authority comment `5447720489`, Epic #506, merged predecessor PR state, and Issue #479 MT-516 absence were also read from current GitHub truth before this write.
