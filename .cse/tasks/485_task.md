# Issue #485 Task

## Identity and authority

- Repository: `faliardic/chief-site-engineer`
- Parent Epic: `#385`
- V2 item: `V2.8 — İstenecek Malzemeler`
- Issue: `#485 — CSE V2.8 Slice 1: İstenecek Malzemeler source-of-truth + saha listesi`
- Owner authority: Issue #485 comment `5408466364`
- Exact merged base: `dbe370e61b5ece843238c35e049bbaa4e7df19cb`
- Branch: `codex/issue-485-material-requests-v1`
- Isolated worktree: `V:\1_PROJECTS\2_ACTIVE\Python\CSE-Worktrees\issue-485-material-requests-v1`
- Implementation status: `IN_PROGRESS`
- Manual test status: `PENDING`

## Risk and model routing

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
  selection_reason: Additive schema migration, persistent source-of-truth, append-only history, optimistic revision and transactional integrity.
  routing_request_evidence: https://github.com/faliardic/chief-site-engineer/issues/485#issuecomment-5408466364
  allowed_fallback: null
  review_floor:
    chatgpt_model: gpt-5.6-sol
    chatgpt_reasoning_effort: max
  fail_closed_if_mismatch: true
```

Runtime actual model/effort and invocation metadata are not exposed. Completion
evidence must record `actual_model: unknown`, `actual_reasoning_effort: null`,
`mismatch_detected: null` and unverified invocation/runtime status.

## Changed contracts

- SQLite schema advances `17 -> 18` through one additive-only migration.
- `material_requests` becomes the canonical request source-of-truth.
- `material_request_events` stores immutable append-only lifecycle history.
- Create/update/transition writes source row and exactly one event atomically.
- Lifecycle is limited to `needed -> requested|cancelled`,
  `requested -> received|cancelled`, and explicit
  `received|cancelled -> needed` reopen.
- Optimistic revision and event-ID replay/collision checks fail closed.
- Nullable location and Living Plan links must belong to the exact request
  project; neither linked source may be mutated.
- Backup format remains `1`; app version remains `0.1.0+1`.

## Exact allowlist — 12 paths

1. `mobile/lib/storage/app_database.dart`
2. `mobile/lib/domain/material_request_models.dart`
3. `mobile/lib/application/material_request_application.dart`
4. `mobile/lib/features/material_requests/material_requests_page.dart`
5. `mobile/lib/bootstrap/app_bootstrap.dart`
6. `mobile/lib/app.dart`
7. `ROADMAP.md`
8. `docs/v2/CSE_V2_SCOPE.md`
9. `docs/project_decisions.md`
10. `CHANGELOG.md`
11. `.cse/tasks/485_task.md`
12. `.cse/results/485_result.md`

A thirteenth path requires an exact compile/static reason written to Issue
#485 evidence before edit and owner escalation. The task does not infer such
need.

## Protected read-only references

- Agenda and Reminder source files
- Living Plan source files
- Project Location source files
- backup/restore application files
- `mobile/pubspec.yaml` and `mobile/pubspec.lock`
- Android/iOS and all platform-production files
- real user data and production/debug package data

## Source-level checks

1. Format only touched Dart files.
2. Run exactly one final `flutter analyze --no-pub`.
3. Run `git diff --check`.
4. Verify exact 12-path allowlist and protected drift 0.
5. Verify schema exact `18` and source-audit the migration as additive-only.
6. Verify backup format exact `1` and version exact `0.1.0+1`.
7. Verify pubspec/lock and platform-production drift 0.
8. Verify staged, branch, head and worktree state before publication.

## Automated application testing and artifacts

- Flutter unit/widget/integration/full tests: disabled by owner-led manual
  testing policy and explicit authority.
- Emulator, ADB/device and scripted acceptance: disabled.
- APK/AAB build: not authorized.
- Real user data access: forbidden.
- Manual Test Register: Issue #479.
- Manual test IDs: stable `MT-485-*` list will be published after source-level
  implementation; initial status `PENDING`.

## Implementation and correction budget

- Primary implementation window: 1.
- Same-scope narrow source corrections: up to 3.
- Environment-only recovery: at most 1 after exact root cause.
- Automated application test budget: 0.

Immediate owner escalation is required for any allowlist expansion, non-additive
migration, backup/version/permission/platform change, stable identity or event/
transaction contract expansion, destructive operation, real-user-data risk or
new product/design decision.

## Explicitly out of scope

Purchasing/ERP, suppliers, pricing/RFQ, invoice/payment, inventory/warehouse,
partial receipt, automatic reminder/notification, attachments, AI, material
forecasting, Living Plan mutation/reforecast, cloud sync, background jobs and
V2.9 implementation.

## Publication authority

Only all-PASS source gates permit `IMPLEMENTED — MANUAL TEST PENDING`, minimal
intentional commit(s), normal non-force push, one Draft PR, Issue/PR evidence
and stable MT-485 registration in #479. Ready, merge, Issue #485 closure, V2.8
completion and V2.9 remain unauthorized.

## Canonical exact-base source manifest

- `AGENTS.md`: blob `75e218af5813422a08aae08dc9df7d07507169be`, SHA-256 `bb00551caecbd2c19af6ccff0fe9c93acfa71aade05288b303f6006be0be616d`
- `CSE_UNIFIED_PROJECT_SOURCE.md`: blob `d2f31def8ee392aab74990766e0a4822be489710`, SHA-256 `5899a8fe03e8ab7ca8ce204ddf7a271686bda0668b08a828645649495539e333`
- `CSE_PROJECT_INSTRUCTIONS.md`: blob `f83164280277cc1f811448a559ddbfcc78d56040`, SHA-256 `f2c00b649cd1dceb19dc0bd1d284713138dbfbd8ee3332b9581afd107a0c20d5`
- `CSE_MODEL_REASONING_ROUTING_POLICY.md`: blob `7d099ed4e5a1205320350c663fe659e36f2c4d6a`, SHA-256 `e1f55336657ecd79cb68cbae458341a811f0bb33867ac06b71163a5a8c8c320b`
- `CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md`: blob `e90612f5ca5bb3f4997110142e24112e246f3b6d`, SHA-256 `c12a57885f31144dc15cbbd3a07ab59527489a533ce5d8b444664ecf7710440d`
- `CSE_WORKFLOW_ACCELERATION_PROTOCOL.md`: blob `b8ce5dd678935e472e1e5351db6c60b6c87238d7`, SHA-256 `7765bcebfb7b25b12e60fb44767d49c9d537393786fa0026561e1593073d297d`
- `CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md`: blob `a4b2c61dd83ce386d453dc684b22651aa980275f`, SHA-256 `acf77c5088be704519230d087d9426772fe62c0dfd4a6ba6fe33a4626fac5041`
- `CSE_PROJECT_SOURCE_REGISTER.md`: blob `583663cf0016d5060ed90ec44d1fce8aa16f74a5`, SHA-256 `f96fc9b1ef8bd12a6a4515a707726d84ee9a86a1a28bf6f20c5217e2954212cb`
- `docs/v2/CSE_V2_SCOPE.md`: blob `a1bdf0d328b83b78af2e1238a13eb99fcfedb227`, SHA-256 `31c6747484558882fe2931867d2b7958ff1e24f86967bc607ac41b200fe48792`
- `ROADMAP.md`: blob `42cccd3dc9ca3ac59530e047d3075cdfa106583f`, SHA-256 `d25d0e540f42bbe5480353b308f67655051163e937db34995ea02e116f7b5b78`

## Frozen preflight

- `origin/master`, local `master` and exact base:
  `dbe370e61b5ece843238c35e049bbaa4e7df19cb`.
- Master divergence: `0 0`.
- Worktree branch/head exact and initial tracked/staged state: clean / 0.
- Target task/result paths did not exist before this first project-file edit.
- Issue #485 body and its sole owner authority comment were read in full.
- Open PR count: 0.
- Issue #479 contained no existing `MT-485-*` entry at task start.
## Final analyzer gate — FAIL / fail-closed

- Touched Dart formatting parsed all six authorized Dart files. The worktree had
  no generated package metadata; the official worktree had the exact same
  `pubspec.lock` SHA-256, so only ignored `.dart_tool/package_config.json`,
  `package_graph.json` and `version` were copied byte-identically.
- The contract's exactly one `flutter analyze --no-pub` invocation exited
  `1` with `13` `prefer_interpolation_to_compose_strings` info lints.
  No compile error or semantic diagnostic was reported.
- A second analyzer invocation is not authorized. No post-analyzer source edit,
  Flutter test, build, APK, emulator, ADB, device or scripted acceptance was
  performed.
- Failure-state checks before evidence: changed paths `11/12` (result file
  not yet created), unexpected path `0`, staged `0`,
  `git diff --check` PASS, platform-production drift `0`,
  pubspec/lock drift `0`, schema `18`, backup format `1`,
  version `0.1.0+1`.
- Publication is blocked. No commit, push, Draft PR, Issue publication evidence
  or MT-485 register mutation is authorized from this failed gate.
## Owner-authorized interpolation correction and analyzer retry — PASS

Authority: Issue #485 owner comment `5412555097`.

- Resume preflight: exact base/head
  `dbe370e61b5ece843238c35e049bbaa4e7df19cb`, exact branch, changed paths
  `12/12`, unexpected `0` and staged `0`.
- The pre-correction SHA-256 manifest was frozen for all 12 WIP paths.
- Only the analyzer-reported 13
  `prefer_interpolation_to_compose_strings` lints were corrected:
  one expression in `material_request_application.dart` and twelve lint
  sites across eleven expressions in `material_requests_page.dart`.
- Correction was string composition to Dart interpolation only. User-visible
  text, whitespace, punctuation, null handling, ordering, validation, SQL,
  migration and lifecycle behavior were unchanged.
- The other ten WIP paths remained byte-identical through correction. Touched
  Dart formatting ran only for the two corrected files and reported
  `0 changed`.
- Exactly one newly authorized `flutter analyze --no-pub` invocation:
  PASS, exit `0`, `No issues found`.
- No Flutter unit/widget/integration/full test, APK/AAB build, emulator, ADB,
  device, scripted acceptance, install, launch or real-user-data access ran.

## Final publication gates — PASS

- Exact allowlist: `12/12`; unexpected/protected path drift: `0`.
- Staged paths before publication: `0`.
- `git diff --check`: PASS.
- Schema source: one exact `schemaVersion = 18` registration.
- Migration source audit: additive-only; two new material tables plus their
  indexes/triggers. Added existing-table rename/rebuild or existing-row
  rewrite SQL: `0`.
- Backup format: exact `1`.
- Version: exact `0.1.0+1`.
- `pubspec.yaml` / `pubspec.lock` drift: `0`.
- Android/iOS platform-production drift: `0`.
- Publication status: `IMPLEMENTED — MANUAL TEST PENDING`.
- Ready, merge, Issue closure, V2.8 completion, Epic checkbox and V2.9 remain
  unauthorized.

## Stable manual test handoff

All entries are `PENDING` and will be registered in Issue #479:

- `MT-485-001`: Home entry and exact project selector.
- `MT-485-002`: Minimal project + material-name create.
- `MT-485-003`: Full optional-field create and display.
- `MT-485-004`: Quantity/unit pair and positive-number validation.
- `MT-485-005`: Same-project active mahal option/link isolation.
- `MT-485-006`: Same-project Living Plan item option/link isolation.
- `MT-485-007`: Deterministic open-list priority/date/stable ordering.
- `MT-485-008`: Needed to requested lifecycle/history.
- `MT-485-009`: Needed to cancelled lifecycle/history.
- `MT-485-010`: Requested to received lifecycle/history.
- `MT-485-011`: Requested to cancelled lifecycle/history.
- `MT-485-012`: Received explicit reopen.
- `MT-485-013`: Cancelled explicit reopen.
- `MT-485-014`: Ordered append-only detail history and revision visibility.
- `MT-485-015`: Offline relaunch persistence.
- `MT-485-016`: Backup/restore preservation without format change.
- `MT-485-017`: No automatic reminder/notification or Living Plan mutation.

## Independent-review correction authority 5413025911 — analyzer FAIL / fail-closed

- Resume preflight verified exact published head
  `a53c88ec869b1465023313ba30a4543c6cf38541`, branch
  `codex/issue-485-material-requests-v1`, clean worktree and staged `0`.
- The frozen pre-correction SHA-256 manifest covered all existing 12 authorized
  paths.
- The three independent review blockers were corrected only in the four
  authorized Dart source files:
  - four malformed dynamic Material Request timestamp references now resolve
    the loop-selected column; the separate event timestamp trigger was not
    changed;
  - Material Request database open/action/close now runs inside the existing
    shared `MobileOperationCoordinator`, supplied by bootstrap;
  - quantity validation and submit use one comma/point normalizer, while display
    preserves the stored double text instead of fixed two-decimal rounding.
- Touched Dart formatting ran for exactly those four files and reported
  `4 files / 0 changed`.
- The authority's exactly one new `flutter analyze --no-pub` invocation exited
  `1`. It reported four `unnecessary_brace_in_string_interps` info findings,
  all at the newly corrected dynamic timestamp expressions:
  `app_database.dart:4134:47`, `:4136:47`, `:4150:47`, and `:4152:47`.
- These findings are directly related to the correction, but the exactly-one
  analyzer budget is consumed. No second source edit, analyzer retry,
  application test, build, APK, emulator, ADB, device or scripted acceptance
  was performed.
- Publication is blocked at the analyzer gate. No correction commit, push,
  Issue/PR evidence update, Ready, merge, closure or roadmap successor action is
  authorized from this state.
- `MT-485-001..019` remain `PENDING`.

## Final lint correction authority 5413317956 — source gates PASS

- Canonical owner authority was read from GitHub in full.
- Resume point: published head
  `a53c88ec869b1465023313ba30a4543c6cf38541`, exact branch, existing local
  6-path correction WIP, staged `0`, total allowlist `12/12`.
- Only the four authorized `NEW.$columnName` semantic-no-op brace removals
  were applied in `mobile/lib/storage/app_database.dart`.
- Generated SQL continues to resolve each loop-selected timestamp column:
  `created_at`, `updated_at`, `status_changed_at`, `requested_at`,
  `received_at`, and `cancelled_at`.
- The other five local WIP files remained byte-identical to the frozen resume
  manifest during this source correction.
- Touched Dart formatting: PASS, `1 file / 0 changed`.
- Exactly one newly authorized `flutter analyze --no-pub`: PASS, exit `0`,
  `No issues found`.
- Final source gates: exact `12/12` allowlist, unexpected/protected drift
  `0`, staged `0`, `git diff --check` PASS, schema `18`,
  additive-only migration with existing table rename/rebuild and existing
  user-row rewrite statements `0`, backup format `1`, version
  `0.1.0+1`, pubspec/lock drift `0`, platform-production drift `0`.
- No Flutter tests, integration tests, scripted acceptance, APK build, emulator
  or ADB/device action ran during source validation.
- Source publication is authorized. The acceptance-only APK build and user-0
  install/launch remain the next owner-authorized stages after commit/push.
- `MT-485-001..019` remain `PENDING`.

## Acceptance debug arm64 primary build — FAIL / fail-closed

- Source correction was committed as
  `bf5120989193a315da100d32cefd50451d6d4d74`, normally pushed, and published
  to Draft PR #486 / Issue #485 evidence.
- One primary build invocation ran with
  `CSE_ACCEPTANCE_HARNESS=true`, debug, `--no-pub`,
  `--target-platform android-arm64`, Gradle worker `1`, parallel disabled,
  and persistent daemon disabled through invocation-local options.
- Build result: FAIL, exit `1`, task `:app:compileDebugJavaWithJavac`.
- Exact compiler failure:
  `CseReminderBootReceiver.java:25: cannot find symbol
  ScheduledNotificationBootReceiver`.
- Read-only diagnosis found the public class in the pinned
  `flutter_local_notifications 22.1.0` plugin source, while the app-module
  compilation did not resolve it on its compile surface.
- This is a tracked source/dependency compile integration blocker, not a
  worktree-local stale/read-only generated-state failure in the two
  cleanup-authorized roots. No cleanup or build retry was performed.
- Fresh expected output
  `mobile/build/app/outputs/flutter-apk/app-debug.apk` does not exist.
- Device preflight, package inventory, install, launch and diagnostics were not
  opened. Production, normal debug, acceptance and Secure Folder packages were
  untouched.
- No Flutter tests, integration tests or scripted acceptance ran.
- Fail-closed stop: no APK identity/hash is available and no device handoff is
  permitted from this build result.

## Android receiver reflection correction and fresh acceptance build — PASS

Authority: Issue #485 owner comment `5413546078`.

- Resume point preserved published head
  `bf5120989193a315da100d32cefd50451d6d4d74`, existing two append-only
  evidence paths, staged `0`, and all prior source-correction bytes.
- Allowlist expanded only by the authorized receiver Java source and its
  platform static-contract test; total PR path set is exact `14/14`.
- Receiver now loads exact runtime class
  `com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver`
  with `Class.forName`, constrains it with
  `asSubclass(BroadcastReceiver.class)`, performs no-arg reflective
  construction, and delegates `onReceive(context, intent)`.
- Audit state becomes `completed` only after normal delegation return.
  `ReflectiveOperationException` or `RuntimeException` records `failed`.
- Supported boot filters, `cse_reminder_boot_audit`, `at_utc`, privacy-safe
  fields, and the direct-reschedule prohibition are preserved.
- Static contract now asserts exact runtime class, subclass constraint, no-arg
  construction and delegation; existing audit/no-title/no-body/no-direct-
  reschedule assertions remain.
- Touched Dart test formatting: PASS, `1 file / 1 changed`.
- Flutter tests and full analyzer were not run. Prior analyzer PASS evidence
  remains current for unchanged Dart production source.
- Source/static gates: `git diff --check` PASS, exact `14/14`, unexpected
  drift `0`, only authorized Android Java platform drift, manifest/Gradle
  drift `0`, schema `18`, backup `1`, version `0.1.0+1`,
  pubspec/lock drift `0`.
- Single fresh acceptance debug arm64 build: PASS.
- Artifact:
  - path:
    `mobile/build/app/outputs/flutter-apk/app-debug.apk`
  - bytes: `93036159`
  - SHA-256:
    `F6CC0D8365F7FD62C618352FFC960A8C248244A9A3035EC3D62528FC84BD23C2`
  - package: `com.faliardic.sefim.acceptance`
  - label: `Şefim`
  - versionName/versionCode: `0.1.0-acceptance` / `1`
  - launchable activity:
    `com.faliardic.chiefsiteengineer.MainActivity`
  - ABI: exact `arm64-v8a`
- Device preflight/install/launch remain unopened until this correction is
  committed and pushed.