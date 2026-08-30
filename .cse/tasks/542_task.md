# Issue #542 Task — Project Dashboard v1

## Authority and starting status

- Parent / V2 program: Epic #539 — CSE UI/UX Release Readiness.
- Current Issue: #542.
- Predecessor: Issue #540 / merged PR #541.
- Owner execution authority: Issue #542 comment `5469980939`.
- Authority URL:
  <https://github.com/faliardic/chief-site-engineer/issues/542#issuecomment-5469980939>
- Execution class: `PRODUCTION_UI_IMPLEMENTATION`.
- Implementation status: `IN_PROGRESS`.
- Manual test status:
  `NOT AUTHORIZED — registration deferred to later acceptance authority`.
- Official local repository:
  `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`.
- Exact expected base: `3038e97982445017343b6dc9efc71673c671b83d`.
- Local `master`, `origin/master`, and task branch start HEAD:
  `3038e97982445017343b6dc9efc71673c671b83d`.
- Master divergence after fast-forward: `0/0`.
- Branch: `codex/issue-542-project-dashboard-v1`.
- First repository file write: this task record.
- PR #536 / branch `codex/issue-535-inventory-spatial-closure` remains
  deferred; head `7f113fdd111bc0b668b29e2a62ca688cbe1f4590` is not an
  ancestor and is not copied or cherry-picked.

## Risk and model routing

```yaml
model_routing:
  policy_version: CSE-MRP-1.0
  task_risk: R4
  orchestrator:
    requested_model: gpt-5.6-sol
    requested_reasoning_effort: max
  executor:
    requested_model: gpt-5.6-sol
    requested_reasoning_effort: max
  assistant_reasoning_recommendation: Extra High
  execution_mode: standard
  orchestration: single-agent
  selection_reason: >-
    Production UI shell and session project-context foundation changes can
    cause cross-project reads or unintended mutations, so exact source binding,
    fail-closed selection, and fresh independent R4 review are required.
  routing_request_evidence: >-
    https://github.com/faliardic/chief-site-engineer/issues/542#issuecomment-5469980939
  allowed_fallback: null
  review_floor:
    model: gpt-5.6-sol
    reasoning_effort: max
  runtime_actual_model: unknown
  runtime_actual_reasoning_effort: unknown
  invocation_evidence: null
  invocation_verification_status: unverified
  runtime_verification_status: unverified
  mismatch_detected: null
  fail_closed_if_visible_mismatch: true
```

The execution surface does not expose independently verifiable runtime model
or effort metadata. Requested values are recorded without inference; the next
gate remains a fresh independent R4 review.

## Exact-base canonical source manifest

All sources below were read from exact base `3038e979...b83d` before this first
repository file write.

| Source | Git blob | SHA-256 |
| --- | --- | --- |
| `AGENTS.md` | `75e218af5813422a08aae08dc9df7d07507169be` | `bb00551caecbd2c19af6ccff0fe9c93acfa71aade05288b303f6006be0be616d` |
| `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md` | `d2f31def8ee392aab74990766e0a4822be489710` | `5899a8fe03e8ab7ca8ce204ddf7a271686bda0668b08a828645649495539e333` |
| `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md` | `f83164280277cc1f811448a559ddbfcc78d56040` | `f2c00b649cd1dceb19dc0bd1d284713138dbfbd8ee3332b9581afd107a0c20d5` |
| `docs/protocols/CSE_CODEX_INSTRUCTION_COMMENT_PROTOCOL.md` | `23eb5c4d72ce3858f097292f7fa1d3fb713d3b7e` | `e6585e4a217d63d6717973121512338a3edfd24091c3eb0df6ea573ec8a797c6` |
| `docs/protocols/CSE_MODEL_REASONING_ROUTING_POLICY.md` | `7d099ed4e5a1205320350c663fe659e36f2c4d6a` | `e1f55336657ecd79cb68cbae458341a811f0bb33867ac06b71163a5a8c8c320b` |
| `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md` | `e90612f5ca5bb3f4997110142e24112e246f3b6d` | `c12a57885f31144dc15cbbd3a07ab59527489a533ce5d8b444664ecf7710440d` |
| `docs/protocols/CSE_WORKFLOW_ACCELERATION_PROTOCOL.md` | `b8ce5dd678935e472e1e5351db6c60b6c87238d7` | `7765bcebfb7b25b12e60fb44767d49c9d537393786fa0026561e1593073d297d` |
| `docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md` | `af1974ecd2c53ceb67245c8eb1242b03fb1a82ef` | `b1685ce1610593195282b3b7c9038009ef8cd365d7c1314cb2356fc425bb383a` |
| `docs/protocols/CSE_PROJECT_SOURCE_REGISTER.md` | `583663cf0016d5060ed90ec44d1fce8aa16f74a5` | `f96fc9b1ef8bd12a6a4515a707726d84ee9a86a1a28bf6f20c5217e2954212cb` |
| `docs/v2/CSE_V2_SCOPE.md` | `12bf27e27dde086a396aa063d16c148410906ea7` | `09972df385cfc5a91303521fc7cc3232413c0189eff46d69d438f66f5581b190` |
| `ROADMAP.md` | `61037f291f18b3434d740fdb096bdce6a0f9b885` | `7cbe3bf9b496a621c1f2ccf07a639b09235fa25f3d6669fb7056837ab08384fc` |
| `docs/v2/CSE_UI_UX_RELEASE_READINESS_AUDIT.md` | `b874699d76bc419c18d1c99e05cff965343ea192` | `5a5b531805effe461b6dd0838931fc313eb0ada3214d621735caf3c0d19d8ca8` |
| `docs/v2/CSE_PRODUCT_RELEASE_DECISIONS_2026-08-30.md` | `2d9f0e57f202e7f8e6e2303d76b27ccff3bac45f` | `7b72b69301f4962b9e944861dd3ec6c1a7fc6d0a803cdfb7d7dbec7ab32b0a0c` |

GitHub/repository truth read before this file write:

- Issue #542 body and owner authority comment `5469980939`;
- parent Epic #539;
- predecessor Issue #540 task/result and merged Wave 0 audit;
- the only open PR, deferred Draft PR #536;
- Issue #479 comments and absence of `MT-542-*` records;
- exact local/remote master, branch, operation, staged and worktree state.

## Locked baseline and changed contracts

- SQLite schema: exact `22` from `AppDatabase.schemaVersion`.
- Backup format: exact `1` from `CseBackupCodec.formatVersion` and recovery
  codec constants.
- Mobile version: exact `0.1.0+1` from `mobile/pubspec.yaml`.
- Changed contracts:
  - menu Home becomes presentation-only Project Dashboard v1;
  - a session-only, non-persistent active-project selection foundation is
    introduced;
  - `ReminderFormPage` gains one backward-compatible optional preferred-project
    starting value for standalone capture.
- Stable identity, optimistic revision, append-only event/history,
  transaction, source-of-truth, notification, schema, migration, backup,
  version, dependency, platform, permission and Inventory contracts remain
  unchanged.

## Exact write allowlist

1. `.cse/tasks/542_task.md`
2. `.cse/results/542_result.md`
3. `mobile/lib/app.dart`
4. `mobile/lib/features/dashboard/project_dashboard_page.dart`
5. `mobile/lib/features/project_context/active_project_session.dart`
6. `mobile/lib/features/reminders/reminder_form_page.dart`
7. `mobile/test/project_dashboard_widget_test.dart`
8. `mobile/test/active_project_session_test.dart`
9. `mobile/test/reminder_widget_test.dart`
10. `mobile/test/widget_test.dart`

Every other path is protected. An additional required path is an immediate
stop-and-report condition; the allowlist will not be expanded autonomously.

## Authorized implementation

1. Replace `Başlangıç` menu content with an active-project Dashboard carrying
   Istanbul-local date, direct `+ Unutma` / `+ Ajanda kaydı`, read-only Bugün,
   7 Günlük Plan and open-material summaries, project tools, and secondary
   safety/tools routes.
2. Reconcile the session selection against `AgendaApplication.listProjects()`
   and `projectChanges`: zero selects none, one may auto-select, and multiple
   without a valid selection requires an explicit choice with no first-project
   read fallback.
3. Load exact selected project/day only through the authorized read ports.
   Dashboard rendering/retry must not call `AttendanceApplication.ensureDay`
   or any create/update/archive/event/revision/notification mutation.
4. Keep section loading, empty, unavailable/error and retry states isolated.
5. Reuse existing production routes. Pass selected project/day only where the
   existing route contract supports it; global module adoption is Wave 2.
6. Preserve Reminder source-log precedence, allow explicit personal selection,
   reject invalid preferred projects, and keep existing callers compatible.

## Explicit deferrals and forbidden work

- Persistent project preference/settings/schema storage.
- Global project-context adoption, navigation/More redesign, project
  lifecycle/search UI, Inventory continuation/card/acceptance/merge, DWG,
  onboarding, telemetry, privacy/KVKK, freemium/paywall, AI, critical-path or
  contractual-delay claims, background jobs and new DB services.
- Application/domain/storage/schema/migration/bootstrap/pubspec/lock/platform
  edits, dependencies, production/debug/user-data access, build, APK/AAB,
  emulator/device/ADB/install/launch and manual acceptance.

## Validation authority and strict gate order

1. Focused gate exactly once, retry `0`:

   ```text
   flutter test --no-pub test/project_dashboard_widget_test.dart test/active_project_session_test.dart test/reminder_widget_test.dart test/widget_test.dart
   ```

   Any failure stops execution without patch or rerun.
2. Only after focused PASS, regression gate exactly once, retry `0`:

   ```text
   flutter test --no-pub test/daily_log_application_test.dart test/construction_living_plan_application_test.dart test/material_request_application_test.dart test/mobile_agenda_widget_test.dart
   ```

   Any failure stops execution.
3. Only after both test gates PASS, run `flutter analyze --no-pub` exactly once.
4. Run changed-Dart
   `dart format --output=none --set-exit-if-changed` exactly once. If formatting
   is required, stop unless the change is purely deterministic formatting
   inside the allowlist.
5. Run full and staged `git diff --check`; prove allowlist `10/10-or-fewer`,
   protected drift `0`, schema `22`, backup `1`, version `0.1.0+1`.

No full suite, build or device/manual gate is authorized. The exact focused and
regression invocations are the Issue-specific override of the default
owner-led application-test policy.

## Manual tests and artifacts

- Manual Test Register: Issue #479.
- Current `MT-542-*` entries: none.
- This implementation authority explicitly defers any needed manual-test IDs
  to a later separate acceptance authority; this execution will not infer PASS
  or write the register.
- Manual test status: `NOT RUN / NOT AUTHORIZED`.
- Build/artifact authority: none.

## Stabilization and immediate escalation conditions

- Primary implementation window: `1`.
- Same-scope narrow corrections: at most `3`, but product/test failure after an
  authorized gate has retry budget `0` and stops immediately.
- Environment-only recovery: at most `1` after exact root-cause proof.
- Immediate stop: allowlist expansion, new product decision, schema/migration/
  backup/version/permission/signing/platform change, data/integrity/security
  risk, destructive operation, source-truth ambiguity, unproven root cause, or
  exhausted correction budget.

## Publication authority

- One minimal implementation commit after every authorized gate PASS.
- Normal push to `codex/issue-542-project-dashboard-v1`.
- One Draft PR to `master`, referencing #542, #540 and #539.
- Concise Issue and PR evidence comments.
- Ready, merge, Issue/Epic closure, Wave 2, Inventory, DWG and release/store:
  not authorized.
- Next gate: `FRESH_INDEPENDENT_R4`.

## Required completion evidence

The result and final report must separate exact base/head and changed paths;
implementation/correction status; focused, regression, analyze, format and
diff-check outcomes; application/manual/device/build tests not run; manual-test
registration deferral; schema/backup/version/platform impact; commit/push/Draft
PR state; Ready/merge/closure state; `execution_record`; and
`review_recommendation`.

## Narrow correction window — comment 5470248072

- Preserved-state validation resume used one real focused invocation and
  stopped at `FAIL +89 -4`; retry count remained `0`.
- Correction authority:
  <https://github.com/faliardic/chief-site-engineer/issues/542#issuecomment-5470248072>
- Phase C1 classification completed before correction edits:
  1. Dashboard material empty copy: `TEST_HARNESS`; the exact production
     copy is present, the empty fake returned successfully, and the lazy
     `ListView` had not built the below-viewport material card.
  2. Dashboard semantics handle: `TEST_HARNESS`; test-owned handle disposal
     in teardown occurs after Flutter end-of-test semantics verification.
  3. Reminder source-log precedence: `TEST_HARNESS`; the test used a
     success-popping form as `MaterialApp.home`, leaving an empty Navigator
     before replacing the root. Production selection keeps `log.projectId`
     before `preferredProjectId`.
  4. Dashboard quick-action back navigation: `TEST_HARNESS`; both production
     forms use `MaterialPageRoute` plus `AppBar`, while `tester.pageBack()`
     did not resolve the Turkish Material back button and fell through to
     its Cupertino assertion.
- Narrow correction changes test harness behavior only: scroll the lazy
  Dashboard list before asserting material copy, dispose semantics before
  test completion, host submit/popping reminder forms on a real pushed
  route, and tap the actual Material `BackButton`.
- Product/source contracts are unchanged. No production source correction,
  #543 handling change, allowlist expansion, schema/backup/version/platform
  change, build, device or manual acceptance is included.
- Authorized correction validation: same focused four-file gate once, retry
  `0`; original regression/static/publication sequence only after focused
  PASS.

## Final test-only correction — comment 5470297974

- The authorized correction-focused invocation completed at `+92 -1`, exit
  `1`; the three earlier harness failures passed.
- The sole remaining failure was classified `TEST_HARNESS`: the source-log
  precedence test's submit control remained outside the test viewport, so the
  rendered button was never tapped and no command was emitted.
- Comment `5470297974` authorized one test-only edit to
  `mobile/test/reminder_widget_test.dart`.
- The test now reaches the existing submit control through rendered scrolling
  and visibility semantics. Product code and the exact source-log project
  precedence assertion were not changed.
- The resulting full focused gate completed at `+93`, exit `0`.

## Superseding one-shot closure — comment 5470387671

- Authority URL:
  <https://github.com/faliardic/chief-site-engineer/issues/542#issuecomment-5470387671>
- Comment `5470387671` supersedes comment `5470325556` for all remaining
  execution. Comment `5470325556` was not executed as a separate authority.
- Mandatory preflight passed on branch
  `codex/issue-542-project-dashboard-v1` at exact HEAD
  `3038e97982445017343b6dc9efc71673c671b83d`, with staged `0`, no Git
  operation in progress, all nine initial changed paths inside the original
  allowlist, and schema/version/backup facts `22 / 0.1.0+1 / 1`.
- The initial changed-Dart format check found six of eight writable Dart paths
  requiring normalization. One authorized mechanical format pass changed only
  those six allowlisted paths; therefore the historical `+93` evidence was
  invalidated and the focused gate was rerun.
- Post-format focused gate: `+93`, exit `0`.
- The first attempt to start the verified regression invocation stopped before
  Flutter loaded any test because the Codex process helper returned
  `helper_unknown_error: setup refresh had errors`. The authority's one global
  infrastructure-only retry was used with the exact same Flutter/test
  arguments and zero source/test edits.
- Verified regression retry using the four exact files named by comment
  `5470387671`: `+78`, exit `0`.
- The first analyzer gate produced one deterministic in-scope diagnostic:
  `prefer_const_constructors_in_immutables` at the new
  `ProjectDashboardPage` constructor. Classification: `PRODUCT_542`; exact
  root cause: the immutable widget constructor lacked the `const` modifier.
- The one bounded stabilization round was used for that single-token production
  correction. No contract, behavior, path or assertion was expanded.
- Complete post-stabilization final cycle:
  - focused four-file gate: `+93`, exit `0`;
  - verified regression four-file gate: `+78`, exit `0`;
  - `flutter analyze --no-pub`: `No issues found`, exit `0`;
  - eight-path Dart format check: `0 changed`, exit `0`;
  - full and staged `git diff --check`: PASS;
  - original ten-path allowlist respected; conditional regression test write
    paths were not edited;
  - schema `22`, backup format `1`, mobile version `0.1.0+1`, Inventory,
    application/domain/storage/platform and protected-path contracts unchanged.
- Historical regression `+42 -2` remains recorded as
  `INVALID_AUTHORITY_PATHS`; it is not a product regression and was not reused
  as the verified gate.
- Build, APK/AAB, device/ADB, application launch and manual acceptance were not
  run and were not authorized. `MT-542-*` registration remains deferred; no
  manual PASS is claimed.

## R4 correction attempt — comment 5470503734

- Fresh independent R4 record: PR #544 review `5061586143`.
- Classification: `R4-542-01 — TEST_EVIDENCE_FALSE_POSITIVE`.
- Required starting state passed at exact local/upstream HEAD
  `f58e1cfb723cf86236764154a08f68c0c3b5d495`, branch
  `codex/issue-542-project-dashboard-v1`, staged/tracked/untracked scope clean,
  no Git operation in progress, and parent exact base `3038e979...b83d`.
- Production tree baseline: `9399539d668edabe7eef193292870099fd07632d`.
  The four reusable regression files were hashed before the edit.
- The test-only correction used the existing routed-form harness, added
  rendered visibility handling, and changed both nullable standalone
  assertions to require `createReminderCalls == 1` plus a non-null emitted
  command before checking `projectId == null`. Source-log precedence was also
  reasserted after positive command emission.
- Required focused gate result: `+92 -1`, exit `1`.
- Exact remaining failure: in
  `preferred project can be changed to personal before save`, the submit
  control center remained at `y=612` outside the `600`-pixel test viewport.
  Flutter emitted the prohibited hit-test warning; no tap reached the control,
  and the strengthened assertion correctly observed
  `createReminderCalls: expected 1, actual 0`.
- This confirms the R4 false-positive diagnosis and proves the first visibility
  hardening was insufficient. It does not prove a production defect.
- Comment `5470503734` authorized one correction cycle. That focused invocation
  consumed the cycle, so no second edit or focused rerun was inferred.
- Analyze, format and publication gates were not reached. No correction commit,
  push, PR update, Ready, merge or closure action was performed. The exact
  uncommitted correction/evidence state is preserved for a new explicit
  authority.

## R4 Reminder harness closure — comment 5470562373

- Authority URL:
  <https://github.com/faliardic/chief-site-engineer/issues/542#issuecomment-5470562373>
- Preserved-state preflight passed: local/upstream/remote PR head remained
  `f58e1cfb723cf86236764154a08f68c0c3b5d495`, PR #544 remained OPEN/DRAFT,
  staged was empty, and writable drift was exactly the three authorized paths.
- Production Dart and all four verified regression files remained byte-identical
  to published head. Production tree baseline remained
  `9399539d668edabe7eef193292870099fd07632d`.
- The primary harness edit added one shared UI submit helper that:
  - finds exact `Key('submit-reminder')`;
  - resolves that control's actual ancestor `Scrollable`;
  - uses rendered `scrollUntilVisible` plus at most six small upward drags;
  - requires exactly one `submit.hitTestable()` result before a normal tap;
  - pumps through the real submit and route-pop lifecycle without suppressing
    hit-test diagnostics.
- The helper is used by the standalone personal, invalid/archived preferred and
  source-log precedence saves. The personal form is hosted on a real pushed
  `MaterialPageRoute` and proves a successful return to its opener.
- Each binding branch now proves exact positive command emission before project
  binding:
  - personal save: `createReminderCalls == 1`, non-null command,
    `projectId == null`;
  - invalid/archived preferred save: `createReminderCalls == 1`, non-null
    command, `projectId == null`;
  - source-log save: `createReminderCalls == 1`, non-null command,
    `projectId == agendaProjectId`.
- Focused invocation 1/2: `+93`, exit `0`; no corrected Reminder submit hit-test
  warning appeared. The optional adaptive edit/invocation was not used.
- `flutter analyze --no-pub`: `No issues found`, exit `0`.
- Changed-Dart format precheck required deterministic formatting of the one
  writable Dart path. Mechanical format was applied only to
  `mobile/test/reminder_widget_test.dart`; final format check reported
  `0 changed`, exit `0`.
- Full and staged `git diff --check`: PASS. Final correction drift remained
  exactly the three authorized paths; staged remained empty before commit.
- Prior verified regression `+78 PASS` was reused because production Dart and
  all four regression files remained byte-identical to published head.
- Schema `22`, backup format `1`, mobile version `0.1.0+1` and all protected
  boundaries remain unchanged. Build/device/manual work was not run.
- Next successful publication gate: one new narrow commit, normal push, Issue/PR
  evidence update, then `FRESH_INDEPENDENT_R4_REREVIEW`.
