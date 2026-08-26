# Issue #490 result — Deterministic person/company suggestions Slice 1

## Outcome

`IMPLEMENTED — MANUAL TEST PENDING`

The exact selected-project, read-only suggestion boundary and its first
Reminder consumer are implemented. It does not add suggestion persistence,
schema/migration, backup, notification, platform or dependency behavior.

## Delivered source contract

- `ContextSuggestion` exposes person/company kind, exact stored display value,
  source type, nullable-only-for-history source identity, exact project,
  reason code and deterministic rank signals.
- `SqliteContextSuggestionApplication` runs through the shared mobile operation
  queue, opens a read-only non-singleton SQLite handle, requires schema `18`,
  and closes the handle in `finally`.
- Primary sources are exact-project active Saha Rehberi people and active
  Firma / İşveren rows. Exact-project Reminder free text is a secondary source
  only with explicit historical provenance.
- Ranking is deterministic and bounded to a caller limit of `1..8`, default
  `6`. Comparison normalization never replaces the exact stored display text.
- No project yields no project-scoped suggestion. Malformed candidates are
  skipped; query/read failure leaves Reminder capture usable.
- The Reminder form keeps free text. Selecting a suggestion changes only the
  existing related-person controller; the existing Save action remains the
  separate mutation boundary.
- No reusable canonical tag source was available; Slice 1 does not reinterpret
  role/team/specialty/category data or invent tag identity.

## Exact changed-path allowlist

1. `mobile/lib/domain/context_suggestion_models.dart`
2. `mobile/lib/application/context_suggestion_application.dart`
3. `mobile/lib/bootstrap/app_bootstrap.dart`
4. `mobile/lib/features/reminders/reminder_form_page.dart`
5. `mobile/lib/app.dart`
6. `ROADMAP.md`
7. `docs/v2/CSE_V2_SCOPE.md`
8. `docs/project_decisions.md`
9. `CHANGELOG.md`
10. `.cse/tasks/490_task.md`
11. `.cse/results/490_result.md`
12. `mobile/lib/features/reminders/reminders_page.dart` — pre-edit wiring
    consequence recorded at owner Issue comment `5424770963`.

## Source-level verification

- Exact base/master before work:
  `ffff4010499bb8c31cbe4679cd2e0e4c5f2816fc`.
- Isolated branch: `codex/issue-490-context-suggestions-v1`.
- Touched Dart formatting: PASS with the repository-recorded bundled Dart SDK.
- Offline package metadata prep: PASS; `pubspec.yaml` and `pubspec.lock` hashes
  remained byte-identical.
- `flutter analyze --no-pub`: exactly one invocation, PASS,
  `No issues found`.
- Pre-evidence `git diff --check`: PASS.
- Exact allowlist before adding this result file: `11/12`; adding this file
  completes the authorized `12/12` set.
- Unexpected/protected drift: `0`.
- Staged paths before publication: `0`.
- Schema: exact `18`.
- Backup format: exact `1`.
- App version: exact `0.1.0+1`.
- `pubspec.yaml` / `pubspec.lock` drift: `0`.
- Android/iOS platform-production drift: `0`.
- Suggestion application write/mutation SQL audit: `0`.

## Tests and artifact boundary

- Flutter unit/widget/integration/full tests: not run.
- Emulator, ADB/device and scripted acceptance: not run.
- APK/AAB build: not run.
- These omissions are required by owner authority and are not represented as
  application verification.
- Manual Test Register: Issue #479.
- `MT-490-001..010`: `PENDING`.

## Publication boundary

- One intentional commit: authorized; pending at this self-containing evidence
  capture point.
- Normal push: authorized; pending.
- One Draft PR: authorized; pending.
- Ready: false.
- Merge: false.
- Issue #490 close: false.
- V2.9 Slice 2: not started.
- V2.10: not started.

## execution_record

```yaml
policy_version: CSE-MRP-1.0
task_risk: R4
requested_model: gpt-5.6-sol
requested_reasoning_effort: max
assistant_reasoning_recommendation: Extra High
actual_model: unknown
actual_reasoning_effort: null
invocation_verification_status: unverified
execution_mode: standard
orchestration: single-agent
verification_mode: owner_led_manual_testing
phone_connection_required: false
implementation_status: IMPLEMENTED
manual_test_status: PENDING
automated_application_tests_run: false
build_run: false
device_run: false
```

## review_recommendation

Independent ChatGPT source/diff review should verify exact-project isolation,
read-only/coordinator/handle-close behavior, deterministic ranking and stable
tie-breakers, explicit historical provenance, Reminder select-versus-Save
separation, non-blocking failure behavior and exact 12-path scope. Keep the PR
Draft; do not infer manual-test PASS, Ready, merge or V2.9 completion.

## Correction — project-switch suggestion isolation

Owner authority:
`https://github.com/faliardic/chief-site-engineer/issues/490#issuecomment-5425133761`

- Resume head/upstream: `2b757e4701b7eb440179b0b9134f9efd293d4a2a`.
- Resume branch: `codex/issue-490-context-suggestions-v1` / Draft PR #491.
- Resume worktree/stage: clean / `0`.
- Exact root cause: a real project change cleared visible suggestions but did
  not cancel a pending debounce or invalidate the current suggestion generation
  until after the awaited location reload. An old-project completion could
  therefore repopulate stale suggestions during that await.
- Narrow correction: `_selectProject()` now synchronously cancels the pending
  suggestion debounce and increments `_suggestionLoadGeneration` immediately
  after the same-project no-op guard and before `setState` or any `await`.
  Existing visible-clear, location reload, new exact-project scheduling and
  in-flight generation guard remain unchanged.
- Production correction diff against the published PR head: exactly one file
  and two added statements in
  `mobile/lib/features/reminders/reminder_form_page.dart`.
- Touched Dart format: PASS, `0` formatter changes after the correction.
- Exactly one authorized correction `flutter analyze --no-pub` retry: PASS,
  `No issues found`.
- Pre-evidence `git diff --check`: PASS.
- Schema `18`, backup format `1`, version `0.1.0+1`: unchanged.
- Pubspec/lock, Android/iOS platform-production and protected source drift: `0`.
- New write/mutation path: `0`.
- Ranking, source, model/application, Reminder Save/notification and all other
  product semantics: unchanged.
- Flutter unit/widget/integration/full tests, build, emulator, ADB/device and
  scripted UI acceptance: not run by exact authority.
- `MT-490-001..010` remain `PENDING`; implementation classification remains
  `IMPLEMENTED — MANUAL TEST PENDING`.
- Correction publication target: one correction commit, normal push to the
  existing branch, PR #491 remains Draft, then independent re-review.

```yaml
correction_execution_record:
  task_risk: R4
  requested_model: gpt-5.6-sol
  requested_reasoning_effort: max
  assistant_reasoning_recommendation: Extra High
  actual_model: unknown
  actual_reasoning_effort: null
  invocation_verification_status: unverified
  phone_connection_required: false
  correction_scope: project_switch_suggestion_generation_invalidation
```
