# Issue #472 Task — Immutable Schedule Snapshot Dependency Graph Persistence

## Authority and exact execution context

- Repository: `faliardic/chief-site-engineer`
- Issue: `#472 — CSE V2.5 Slice 6: Immutable Schedule Snapshot Dependency Graph Persistence`
- Owner authority: `https://github.com/faliardic/chief-site-engineer/issues/472#issuecomment-5383397000`
- V2 item: `V2.5 — 7 Günlük Yaşayan İş Programı / İş ve Gün Planı`
- Parent Epic: `#385`
- Exact base/master: `92fa66c48af99e693688d4cc1ca5d2dae1b0828c`
- Branch: `codex/issue-472-snapshot-dependency-persistence`
- Worktree: `V:\1_PROJECTS\2_ACTIVE\Python\CSE-Worktrees\issue-472-snapshot-dependency-persistence`
- First local project-file edit: this file
- Validation class: `persistence`

```yaml
model_routing:
  policy_version: "CSE-MRP-1.0"
  task_risk: "R4"
  orchestrator:
    chatgpt_model: "gpt-5.6-sol"
    chatgpt_reasoning_effort: "max"
  codex_model: "gpt-5.6-sol"
  codex_reasoning_effort: "max"
  execution_mode: "standard"
  orchestration: "single-agent"
  selection_reason: "Schema migration, immutable historical schedule source-of-truth, rollback and backup/restore integrity."
  routing_request_evidence: "https://github.com/faliardic/chief-site-engineer/issues/472#issuecomment-5383397000"
  allowed_fallback: null
  review_floor:
    chatgpt_model: "gpt-5.6-sol"
    chatgpt_reasoning_effort: "max"
  fail_closed_if_mismatch: true
```

Invocation/runtime metadata görünmüyor; değerler tahmin edilmeyecek. Completion
record içinde `actual_model: unknown`, `actual_reasoning_effort: null`,
`invocation_verification_status: unverified`,
`runtime_verification_status: unverified` ve `mismatch_detected: null`
kullanılacak.

## Preflight evidence before first edit

- Exact worktree: PASS
- Exact branch: PASS
- Exact HEAD/base: PASS
- Issue #470 closed: PASS
- Parallel open production PR: none
- Tracked/untracked worktree status: clean
- Staged paths: `0`
- Tracked path count: `1235`
- Protected tracked path count: `1226`
- Protected manifest format: sorted `path<TAB>lowercase-sha256`, UTF-8, LF,
  final LF
- Protected manifest SHA-256:
  `60b5cd40ab3f352355383081993281aa489e1e7a5b57f2d85812a24f655ee9f9`
- Optional path 13 remains protected until concrete need is proven:
  `mobile/lib/application/mobile_backup_application.dart`
- Optional path 13 baseline SHA-256:
  `be840a55906e9d3c728fb41d16f6094cc20352032eb713fe971ae86f2f64cee4`
- Initial schema anchor: `16`
- Initial backup format anchor: `1`
- Initial app version anchor: `0.1.0+1`

## Changed contracts

1. SQLite schema advances from `16` to `17`.
2. Every newly persisted immutable schedule snapshot stores its exact resolved
   dependency graph with an explicit manifest, deterministic canonical graph
   SHA-256 and per-row integrity fingerprints.
3. A zero-edge graph is represented by an explicit manifest with count `0` and
   the canonical empty-projection hash.
4. Schema-16 historical snapshots are not backfilled or reconstructed. Missing
   manifests mean typed dependency-graph unavailable, never zero dependencies.
5. Snapshot metadata, activities, dependency manifest, dependency rows and
   integrity verification complete in one transaction or roll back together.
6. Dependency manifest and rows are immutable: no update or delete.
7. Exact snapshot-ID reads validate count, graph hash, row fingerprint and
   endpoint integrity without silent rebind to a newer/current snapshot.
8. Backup format remains `1`; schema-17 roundtrip and schema-16 migration
   compatibility preserve historical/Living Plan truth.

## Exact allowlist

1. `mobile/lib/storage/app_database.dart`
2. `mobile/lib/domain/construction_schedule_dependency_snapshot_models.dart`
3. `mobile/lib/application/construction_schedule_snapshot_repository.dart`
4. `mobile/test/app_database_test.dart`
5. `mobile/test/construction_schedule_snapshot_repository_test.dart`
6. `mobile/test/mobile_backup_application_test.dart`
7. `ROADMAP.md`
8. `docs/v2/CSE_V2_SCOPE.md`
9. `docs/project_decisions.md`
10. `CHANGELOG.md`
11. `.cse/tasks/472_task.md`
12. `.cse/results/472_result.md`

Optional path 13 may be edited only after a concrete compile/restore need is
proved before the edit:

- `mobile/lib/application/mobile_backup_application.dart`

A 14th changed path requires stop-and-report before editing.

## Protected boundaries

- No changes to Living Plan application/domain/UI/forecast code.
- No changes to project graph builder, dependency corpus repository or schedule
  date engine.
- No changes to `pubspec.yaml`, `pubspec.lock`, Android/iOS/platform,
  notification, attachment, release/store or device-acceptance files.
- No historical graph guessing/backfill, snapshot supersede during migration,
  new snapshot generation during migration or Living Plan reference mutation.
- No dependency propagation/impact engine, planned-date/reference schedule
  mutation, forecast UI, quantity, productivity learning, AI, Gantt, critical
  path or float.
- No APK, ADB or device operation.

## Required focused evidence

### Schema/migration

- Fresh DB schema 17.
- Schema 16 to 17 migration.
- Legacy snapshots and activities unchanged; no dependency backfill.
- Dependency tables, FKs, indexes and immutability triggers.
- Invalid enum, self-edge and orphan endpoints rejected.

### Repository persistence/load/integrity

- Exact dependency graph roundtrip with stable edge order.
- Explicit zero-edge manifest.
- Input edge order variation produces the same projection hash.
- Graph/project/corpus mismatch remains fail-closed.
- Dependency insert failure rolls back the full new snapshot and leaves the
  previous current snapshot current.
- Successful persist atomically supersedes its predecessor only after the
  complete write succeeds.
- Manifest count/hash mismatch and row tamper/fingerprint mismatch fail closed.
- Legacy manifest absence yields typed unavailable.
- Exact snapshot read never substitutes a current/newer snapshot.
- Existing activity/history/window and Issue #470 legacy forecast behavior
  remain intact.

### Backup/restore

- Schema-17 backup/restore preserves manifest, rows, count/hash and immutable
  graph reads.
- Schema-16 backup restores/migrates to schema 17 without invented graph data.
- Living Plan references/progress/history remain preserved.
- Backup format stays `1`.

## Authorized validation order

1. Format changed Dart only.
2. `flutter test --no-pub test/app_database_test.dart`
3. `flutter test --no-pub test/construction_schedule_snapshot_repository_test.dart`
4. `flutter test --no-pub test/mobile_backup_application_test.dart`
5. `flutter analyze --no-pub`
6. `git diff --check`
7. Exact allowlist/protected/version/pubspec-lock/platform drift checks.
8. Only if every prior gate passes, exactly one `flutter test --no-pub`.
9. No build, APK or device gate.

## Retry, time and stop controls

- Primary execution budget: `1`.
- Each failed focused/analyze/full gate: at most one exact correction and one
  retry for the concrete defect.
- The authority sets no standalone numeric persistence time limit; the exact
  scope, per-operation retry budget and stop conditions are binding throughout.
- Migration data loss, historical backfill, snapshot rebind, FK/integrity
  contradiction or rollback failure observed twice is terminal fail-closed.
- Stop before edit if a 14th path, backup-format bump, existing snapshot/activity
  rewrite, guessed historical graph, Living Plan reference mutation, schedule
  date-engine change, propagation engine, UI or device work is required.

## Publication boundary

Only complete PASS authorizes minimal intentional commit(s), normal push and
exactly one Draft PR with exact Issue/PR evidence. No force, amend, rebase,
Ready, merge, Issue close, Item 5 completion or downstream successor work.

## 2026-08-23 — Narrow allowlist correction / resume authority

- New owner authority:
  `https://github.com/faliardic/chief-site-engineer/issues/472#issuecomment-5383468808`
- The prior fail-closed preflight is accepted as correct.
- Newly authorized path 13:
  `mobile/test/platform_notification_configuration_test.dart`
- Authority within path 13 is limited to the exact static assertion update
  `static const schemaVersion = 16` to `static const schemaVersion = 17`.
- `mobile/lib/application/mobile_backup_application.dart` is no longer
  conditionally authorized and is protected. Its resume SHA-256 is
  `be840a55906e9d3c728fb41d16f6094cc20352032eb713fe971ae86f2f64cee4`.
- A 14th path is a hard stop.
- Resume state: exact base/branch, staged `0`, tracked source drift `0`, WIP
  only task/result evidence, and all test/analyze/full budgets unconsumed.
- Revised protected tracked path count: `1225`.
- Revised protected manifest SHA-256:
  `b183be031213b05a9c6b45d7a2b14f9f1dfe8394dd11480e6c6a4a82c20e5541`.

Revised gate order adds exactly one focused
`flutter test --no-pub test/platform_notification_configuration_test.dart`
after backup focused and before analyze. All original schema-17, legacy
unavailable/no-backfill, atomic rollback, backup-format-1 and publication
boundaries remain unchanged.

## Implementation and AppDatabase primary gate

- Offline worktree metadata preparation completed with pinned Flutter
  `pub get --offline`; `pubspec.yaml` SHA-256 remained
  `704ee4a64b534d14264984f68b8275570b8f87c06190ee48340830d971eabfa7` and
  `pubspec.lock` SHA-256 remained
  `2b75e59a051a8cfcfec3d6883b04779205c63678b0f4814a4535e50db77dc441`.
- AppDatabase focused primary invocation completed `24 PASS / 1 FAIL`.
- Exact failure: the pre-existing schema-15→16 focused fixture opened the
  unrestricted current migration chain and therefore observed `user_version=17`
  while asserting `16`; the new schema-16→17 test itself passed.
- Authorized exact correction pins only that historical fixture's final open to
  `AppDatabase.foundationMigrations.take(16)`. Production migration/schema logic
  is unchanged by the correction; one AppDatabase retry remains.

## Fail-closed stop after AppDatabase retry

- The single AppDatabase retry completed `24 PASS / 1 FAIL`.
- The historical schema-15→16 fixture passed after its exact pin.
- Exact retry failure: the new schema-16→17 fixture was also accidentally pinned
  to `foundationMigrations.take(16)`, so its schema-17 objects were not created;
  the expected nine-object set was compared with an empty set at line 1371.
- Concrete mechanism: the first multi-file `apply_patch` partially applied the
  intended historical-fixture edit before its evidence-file context failed; the
  subsequent single-file correction matched a second identical constructor and
  added the same pin to the schema-16→17 fixture.
- AppDatabase primary, one correction and one retry budgets are exhausted.
- No further edit or test is authorized. Repository, backup, platform static,
  analyze, drift and full-suite gates remain unopened. Stop fail-closed without
  commit, push or PR.

## Owner authority 5384034629 — exact fixture resume

- The owner classifies the exhausted AppDatabase result as a test-fixture defect
  and grants one narrow correction plus one exact AppDatabase focused rerun.
- Correction scope is only `mobile/test/app_database_test.dart`; task/result
  evidence remains EOF append-only.
- Historical schema-15→16 pin at line 1089 remains exact. The unintended pin in
  the schema-16→17 `upgraded` fixture was removed; expected schema-17 object
  assertions and production source were not changed.
- Corrected app-database test SHA-256:
  `5cd320ac9310bb0ba2acf6b57dfc6289369ad1a37372cb4207fc63b2ceff0d15`.
- Correction-excluded WIP manifest: `10` paths, deterministic SHA-256
  `a3e927d2ede0945d52c59e559abebff316ae67c4a30bf0c367fb4c87ff8f9a1c`;
  exact pre/post hashes and sizes matched. Staged remains `0`.
- On AppDatabase PASS, resume only the unopened repository → backup → platform
  static → analyze → drift → single full-suite chain. On FAIL, append evidence
  and stop without another edit/invocation.

### AppDatabase resumed focused gate

- Exact owner-authorized rerun:
  `flutter test --no-pub test/app_database_test.dart`.
- Result: `25/25 PASS`.
- Historical schema-15→16 pin and schema-16→17 migration/no-backfill contract
  both passed. The AppDatabase gate is closed PASS and will not be rerun.
- Continue at the unopened schedule snapshot repository focused gate.

### Repository focused primary and correction

- Primary command completed `14 PASS / 1 FAIL`.
- Exact defect: the expected/actual dependency projections contained identical
  values, but `orderedEquals` compared the map elements without deep equality.
- Correction preserves all expected edge values/order and changes only the
  failing dependency-map matcher to `equals`.
- A generic patch first matched the earlier activity-ID matcher; read-only
  verification caught it before retry, restored it to `orderedEquals`, and
  confirmed the only `equals(const [` occurrence is the dependency projection at
  line 148. Repository retry remains exactly one.

- Repository focused retry result: `15/15 PASS`.
- Repository gate is closed PASS and will not be rerun. Continue at unopened
  backup/restore focused gate.

- Backup/restore focused primary result: `36/36 PASS`.
- Schema-17 graph roundtrip, schema-16→17 no-backfill restore and Living Plan
  progress/history preservation passed. Continue at unopened platform static
  focused gate.

- Platform notification/static focused primary result: `6/6 PASS`.
- The exact schema-17 assertion passed with all unchanged notification/platform
  expectations. Continue at unopened `flutter analyze --no-pub` gate.

- `flutter analyze --no-pub` primary result: PASS, `No issues found`.
- Continue at exact diff/allowlist/protected/schema/backup/version/pubspec-lock/
  platform drift gate. Full suite remains unopened until every drift check PASS.

- `git diff --check`: PASS; only informational LF→CRLF checkout warnings.
- Exact active allowlist: `13/13`; staged `0`; unexpected path drift `0`.
- Protected tracked manifest: `1225` paths, SHA-256
  `b183be031213b05a9c6b45d7a2b14f9f1dfe8394dd11480e6c6a4a82c20e5541`.
- Schema `17`, backup format `1`, app version `0.1.0+1`, pubspec/lock hashes
  and platform-production drift `0`: PASS.
- All pre-full gates PASS. Exactly one full `flutter test --no-pub` is opened.

## Full suite and publication handoff

- Exact single full invocation: `flutter test --no-pub`.
- Result: `724/724 PASS` in approximately `66s`.
- Full-suite budget is consumed PASS; no rerun is authorized or needed.
- No APK, ADB or device operation was run.
- Proceed only through final worktree verification, one minimal intentional
  commit, normal push, one Draft PR, Issue+PR evidence, then stop for independent
  ChatGPT review. No Ready, merge, Issue close or successor work.
