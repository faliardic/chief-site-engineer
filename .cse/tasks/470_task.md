# Issue #470 Task — Deterministic Living Plan Forecast Core

## Authority and execution routing

- Repository: `faliardic/chief-site-engineer`
- Issue: `#470 — CSE V2.5 Slice 5: Deterministic Living Plan Forecast Core`
- Owner authority: Issue comment `5383227311`
- Exact base/master: `a5298556c14653bf590f65d1f67b2866a5e58298`
- Branch: `codex/issue-470-living-plan-forecast-core`
- V2 item: Item 5 — 7 Günlük Yaşayan İş Programı / İş ve Gün Planı
- Parent evolution: CSE V2.5 Living Plan; Item 5 remains current and not complete
- Policy: `CSE-MRP-1.0`
- Risk: `R4` (schedule/forecast correctness)
- Validation class: `domain`
- Requested Codex model: `gpt-5.6-sol`
- Requested reasoning effort: `max`
- Execution mode: `standard`
- Orchestration: `single-agent`
- Review floor: independent ChatGPT review after Draft PR
- Allowed fallback: none without new owner authority
- Fail closed on model/routing mismatch when runtime metadata proves a mismatch; hidden runtime metadata is recorded as unverified and is not guessed

## Objective and changed contract

Create a pure, deterministic, read-only Living Plan forecast core. For a
`STARTED` item with explicit progress `0..99`, bind to the item's exact
reference snapshot/project/activity instance and calculate:

- `remainingFraction = (100 - progress) / 100`
- `remainingDurationDays = referenceDurationDays * remainingFraction`
- `remainingRoundedSchedulingDays = ceil(remainingDurationDays)`
- forecast finish from caller-supplied canonical UTC-midnight `asOfDate`, the
  exact snapshot project calendar, and existing
  `constructionDurationFinishDate`
- signed finish variance in calendar days against the exact reference finish

The result preserves reference duration status, confidence, duration source,
seed provenance, production status, and baseline status. It never silently
rebinds to a newer snapshot and never reads the clock.

No future finish forecast is produced for `PLANNED`, `STARTED` with unknown
progress, `DEFERRED`, or `COMPLETED`. `DEFERRED` remains paused; a deterministic
remaining duration may be exposed only from its explicit progress while finish
and variance remain null. A non-milestone positive remainder rounds to at least
one scheduling day; a zero-duration milestone remains zero.

## Hard boundaries

- No Living Plan item, planned date, reference schedule, snapshot, successor,
  database, event, or receipt mutation.
- No persisted forecast, schema change, migration, backup format change, UI,
  bootstrap, quantity, reforecast propagation, productivity learning, AI,
  notification, Android/iOS, APK, ADB, device, release, signing, or store work.
- `schemaVersion = 16`, backup format `1`, and app version `0.1.0+1` remain
  unchanged.
- `pubspec.yaml`, `pubspec.lock`, platform production files, device acceptance
  runner, and all protected source files remain byte-identical.

## Exact edit allowlist

1. `mobile/lib/domain/construction_living_plan_forecast_models.dart`
2. `mobile/lib/application/construction_living_plan_forecast.dart`
3. `mobile/test/construction_living_plan_forecast_test.dart`
4. `ROADMAP.md`
5. `docs/v2/CSE_V2_SCOPE.md`
6. `docs/project_decisions.md`
7. `CHANGELOG.md`
8. `.cse/tasks/470_task.md`
9. `.cse/results/470_result.md`

Optional only after concrete necessity is proven before editing:

10. `mobile/lib/application/construction_schedule_date_engine.dart`
11. `mobile/test/construction_schedule_date_engine_test.dart`

Read-only audit proved the existing public finish-date helper already accepts
the required exact calendar contract. Therefore optional paths 10–11 are not
needed and remain protected. A 10th changed path without separately proven
optional need, or any 12th changed path, is a terminal fail-closed condition.

## Required focused coverage

- exact snapshot/project/activity binding; typed failure for every mismatch
- `PLANNED` no forecast
- `STARTED + NULL` no forecast
- `STARTED` progress `0`, `47`, and `99`
- fractional duration rounding and zero-duration milestone behavior
- working-day Sunday/holiday handling and calendar-day behavior
- `DEFERRED` paused
- `COMPLETED` no future forecast
- negative, zero, and positive finish variance
- duration confidence/status/provenance preserved exactly
- inputs not mutated
- identical inputs produce identical results
- invalid canonical date/progress/duplicate or missing binding fail closed

## Validation order and retry budget

1. Exactly one primary focused forecast test invocation.
2. Date-engine focused regression only if its production file is edited (not
   currently authorized by necessity).
3. Exactly one primary `flutter analyze --no-pub` invocation.
4. `git diff --check` plus exact allowlist/protected/schema/backup/version/
   pubspec-lock/platform drift checks.
5. Only if every previous gate passes, exactly one full
   `flutter test --no-pub` invocation.

Each executable gate has one primary invocation. After a concrete failure, at
most one exact correction and one retry of that same gate are available. A
second exact source-binding, calendar, or silent-rebinding contradiction is
terminal. Target time is 80 minutes; hard stop is 140 minutes.

If a fresh linked worktree lacks generated package metadata, offline metadata
preparation may run once before the focused gate, guarded by byte-identical
`pubspec.yaml`, `pubspec.lock`, and protected tracked hashes. It is not a test
or build gate.

## Preflight evidence

- Worktree: `V:/1_PROJECTS/2_ACTIVE/Python/CSE-Worktrees/issue-470-living-plan-forecast-core`
- Branch: `codex/issue-470-living-plan-forecast-core`
- HEAD: `a5298556c14653bf590f65d1f67b2866a5e58298`
- Initial tracked/untracked WIP: `0`
- Initial staged paths: `0`
- Protected tracked path count (all tracked paths except exact 9-path
  allowlist): `1226`
- Protected manifest SHA-256:
  `ced172bdcf1a5f567695ed70352e1e49544239574c999361236d4255f1b71bdc`
- Date engine SHA-256:
  `97335b4b3b81fb1885e70aca45b68097204d7dd7b26c5a0688c699ddf570d6d9`
- Date engine test SHA-256:
  `b69f1b895c0c896211f6010a993bfb23dceb8650f80def165c2e68291520a243`
- Database SHA-256:
  `d7696e526d5039fad8fa2cf792b43879d73f02f1f30d67aca45973a1eea8f7e0`
- Living Plan application SHA-256:
  `7bdcbeb3a4ede0c12f46ee70918709ae3c8d6a12f5971d791bfe9e17164f4c52`
- Living Plan domain SHA-256:
  `3d45ec9e2b9c455cd243209e2bfc4108f7ad15e648eec6f1a03e0876eec81a37`
- Snapshot repository SHA-256:
  `6198efc58f2e0f3aacf77b45c85c4f3abfbf335bf7e2aef2bf46e4808d55d697`
- Living Plan UI SHA-256:
  `f331620db03685482b7538e82ea952a985bcd44a78f71ff0788b2dde0f8b3a15`
- `pubspec.yaml` SHA-256:
  `704ee4a64b534d14264984f68b8275570b8f87c06190ee48340830d971eabfa7`
- `pubspec.lock` SHA-256:
  `2b75e59a051a8cfcfec3d6883b04779205c63678b0f4814a4535e50db77dc441`

## Completion boundary

Only complete PASS authorizes one minimal intentional commit, normal push, one
Draft PR, and exact evidence on Issue #470 and the PR. No force push, amend,
rebase, Ready, merge, Issue close, Item 5 completion, successor work, or
downstream schedule shifting is authorized. Stop for independent ChatGPT
review.

## Execution completion

- Offline metadata preparation: PASS; pubspec/lock drift `0`.
- Focused forecast primary: `0/24` because the new fixture used non-canonical
  project IDs before forecast code was reached.
- Exact test-fixture-only correction: `project-a/project-b` → `PRJ-A/PRJ-B`.
- Focused forecast exact retry: `24/24 PASS`; focused retry budget consumed.
- Conditional date-engine focused regression: not run because optional
  date-engine production/test paths remained byte-identical.
- `flutter analyze --no-pub`: PASS, no issues.
- Diff/allowlist/protected/schema/backup/version/pubspec-lock/platform gate:
  PASS; exact `9/9` paths, staged `0`, protected drift `0`.
- Full `flutter test --no-pub`: exactly one invocation, `719/719 PASS`.
- APK/build/ADB/device/release/store gates: not run; prohibited and unnecessary
  for this pure read-only domain slice.
- Publication is authorized only with the final evidence bytes included in the
  same single intentional commit; Draft remains Draft and independent review is
  the stop point.