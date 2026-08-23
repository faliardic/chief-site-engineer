# Issue #470 Result — Deterministic Living Plan Forecast Core

## Authority and preflight

- Issue #470 body and owner authority comment `5383227311` were read in full.
- Isolated linked worktree:
  `V:/1_PROJECTS/2_ACTIVE/Python/CSE-Worktrees/issue-470-living-plan-forecast-core`
- Branch: `codex/issue-470-living-plan-forecast-core`
- Exact base/initial HEAD:
  `a5298556c14653bf590f65d1f67b2866a5e58298`
- Initial WIP: `0`; initial staged paths: `0`.
- Issue #468 / PR #469 were verified closed/merged; no parallel open
  production PR was found.
- First local project-file edit was `.cse/tasks/470_task.md`.
- Protected baseline: `1226` tracked paths, deterministic manifest SHA-256
  `ced172bdcf1a5f567695ed70352e1e49544239574c999361236d4255f1b71bdc`.
- Existing public `constructionDurationFinishDate` accepts the required
  calendar contract. Optional date-engine edit paths were not needed and remain
  protected.

## Implementation evidence

- Added immutable forecast result/basis/failure models.
- Added a pure `ConstructionLivingPlanForecastEngine` that validates exact
  project/snapshot/activity binding and exact reference duration/calendar/
  provenance before calculating.
- `STARTED + 0..99` uses the owner-authorized remaining-fraction formula,
  `ceil`, caller-supplied canonical UTC-midnight `asOfDate`, and the existing
  schedule finish-date helper with the exact snapshot project calendar.
- `PLANNED`, `STARTED + NULL`, `DEFERRED`, and `COMPLETED` do not invent a
  future finish. Deferred explicit progress may expose deterministic remaining
  duration while remaining paused.
- Duration status/confidence and snapshot production/duration/baseline
  provenance remain exact. No source mutation, clock read, persistence, event,
  receipt, schema, UI, quantity, downstream reforecast, learning, or AI path was
  introduced.

## Metadata preparation

- Fresh worktree package metadata was absent.
- Ran once from `mobile/`: `flutter pub get --offline`.
- `pubspec.yaml` remained
  `704ee4a64b534d14264984f68b8275570b8f87c06190ee48340830d971eabfa7`.
- `pubspec.lock` remained
  `2b75e59a051a8cfcfec3d6883b04779205c63678b0f4814a4535e50db77dc441`.
- Unexpected tracked drift after metadata preparation: `0`.

## Focused forecast gate

Primary invocation:

```text
flutter test --no-pub test/construction_living_plan_forecast_test.dart
0 PASS / 24 FAIL
```

Exact root cause: the new test fixture used `project-a` / `project-b`, which the
existing canonical `ConstructionProjectProfile` project-ID contract rejected as
`invalid_project_id` before forecast code was reached. All failures shared this
single fixture root cause.

Authorized exact correction: only the new focused test fixture project IDs were
canonicalized to `PRJ-A` / `PRJ-B`; production semantics and source bytes were
unchanged.

Exact retry:

```text
flutter test --no-pub test/construction_living_plan_forecast_test.dart
24 PASS / 0 FAIL
```

Focused primary/correction/retry budget is consumed. The date-engine production
file was not edited, so the conditional date-engine focused regression gate was
not opened.

## Truth-sync evidence

- `ROADMAP.md` candidate/apply SHA-256:
  `4b5295243322e2d2a22e907df4e7e1ce52daa3a1cfa843263f17dbec03b6b2ab`
- `docs/v2/CSE_V2_SCOPE.md` candidate/apply SHA-256:
  `97bff1c0b4dfa066b298718ae34bef918e5a1e14444d36d037de673080603797`
- `docs/project_decisions.md` candidate/apply SHA-256:
  `5e286a6c8fa254f6f08e4072de4e5dcacc34f67927213e9331dcf17681b19951`
- `CHANGELOG.md` candidate/apply SHA-256:
  `270307a2b6e2c91173baf7712123e0e9ac829f1ede7c9d6d9beb8a3a8852d1b6`
- All four files retained UTF-8 without BOM and LF line endings.
- Truth-sync marks Issue #468 / PR #469 merged and Issue #470 current, read-only,
  deterministic forecast core. Item 5 remains current/not complete; forecast UI,
  actual quantity, dependency reforecast, productivity learning, production/store
  readiness, Ready, and merge are not declared.

## Remaining gates

- `flutter analyze --no-pub`
- `git diff --check` and exact allowlist/protected/schema/backup/version/
  pubspec-lock/platform drift
- only after every prior gate passes, exactly one full `flutter test --no-pub`
- publication only after complete PASS

## Analyze and final host verification

```text
flutter analyze --no-pub
No issues found! (ran in 19.7s)
```

The first read-only drift checker stopped because its embedded expected runner
SHA literal contained a transcription error. Repository actual runner SHA was
`af809cc3aa41e5c75a1d6f82ddd24f396f190d85060aeebd63cde74b47405628`,
which exactly matched the preflight baseline. No file was edited. The checker
literal was corrected and the same read-only host verification completed PASS:

- `git diff --check`: PASS
- exact changed paths: `9/9`
- staged paths: `0`
- protected tracked paths: `1226`
- protected manifest SHA-256:
  `ced172bdcf1a5f567695ed70352e1e49544239574c999361236d4255f1b71bdc`
- protected/source drift: `0`
- optional date-engine/test drift: `0`
- schema: `16`
- backup format: `1`
- app version: `0.1.0+1`
- pubspec/lock/platform production drift: `0`

## Full Flutter gate

Exactly one invocation ran only after focused, analyze, and host drift gates
passed:

```text
flutter test --no-pub
719 PASS / 0 FAIL
```

The full-suite primary budget is consumed. No APK, build, ADB, physical-device,
signing, release, or store command was run; Issue #470 explicitly excludes those
gates for this pure read-only core.

## Completion summary

- Exact reference project/snapshot/activity binding is fail-closed and never
  silently adopts a newer snapshot.
- Progress `0`, `47`, `99`, fractional duration, milestone, working-day Sunday/
  holiday, calendar-day, paused/completed/no-progress basis, signed variance,
  provenance preservation, purity, and deterministic replay are covered.
- Living Plan/storage/reference schedule/application/UI/bootstrap/platform and
  device runner protected bytes are unchanged.
- Schema/migration impact: none; schema remains `16`.
- Backup impact: none; format remains `1`.
- Attachment/notification impact: none.
- Physical-device acceptance: not applicable and prohibited for this Slice.
- Item 5 remains current and not complete. Forecast UI, quantity, dependency
  reforecast, productivity learning, Ready, merge, Issue close, and successor
  work were not started.

```yaml
execution_record:
  issue: 470
  authority_comment_id: 5383227311
  policy_version: CSE-MRP-1.0
  task_risk: R4
  validation_class: domain
  requested_model: gpt-5.6-sol
  requested_reasoning_effort: max
  actual_model: unknown
  actual_reasoning_effort: null
  execution_mode: standard
  orchestration: single-agent
  allowed_fallback: null
  invocation_verification_status: unverified
  runtime_verification_status: unverified
  mismatch_detected: null
  base_commit: a5298556c14653bf590f65d1f67b2866a5e58298
  branch: codex/issue-470-living-plan-forecast-core
  focused_primary: failed_fixture_contract
  focused_exact_retry: 24_pass_0_fail
  analyze: pass
  full_flutter_test: 719_pass_0_fail
  apk_device: not_run_prohibited
  protected_drift: 0
  final_status: pass_pending_publication
```

```yaml
review_recommendation:
  status: independent_chatgpt_review_required
  draft_only: true
  ready: false
  merge: false
  review_focus:
    - exact origin snapshot binding and typed failures
    - remaining-duration rounding and existing calendar-helper reuse
    - basis-specific nullability and signed variance
    - confidence/provenance preservation and absence of mutation
```