# Issue #558 Result — Global active-project context

## Outcome

- Source base: `df55d742a9bba887bb78ef62115e68969c4ca4ea`.
- Branch: `codex/issue-558-global-active-project-context`.
- Implementation status: `IMPLEMENTED`.
- Manual test status: `PENDING`.
- Shell now resolves and caches the shared `ActiveProjectSession` selection on
  startup, session-change and project-change boundaries without selecting a
  project itself.
- Hatırlatıcı, Ajanda and Daha show the compact active-project indicator.
- Dashboard, Envanter and Puantaj do not show the indicator.
- Reminder new capture receives the shared selection only as
  `preferredProjectId`.
- Agenda mixed/global listing remains independent; new capture uses an explicit
  local filter first, otherwise the shared active project.
- Agenda capture with neither a validated local filter nor active project stays
  fail-closed and does not trigger the form's legacy first-project fallback.
- Form-local project changes do not mutate the shared session.

## Exact changed paths

- `.cse/tasks/558_task.md`
- `.cse/results/558_result.md`
- `mobile/lib/app.dart`
- `mobile/lib/features/reminders/reminders_page.dart`
- `mobile/lib/features/agenda/agenda_page.dart`
- `mobile/test/global_active_project_context_widget_test.dart`

No Puantaj, Envanter or `ActiveProjectSession` implementation path changed.

## Source-level evidence

- Changed-Dart formatter: PASS; 4 files, final idempotence `0 changed`.
- Targeted widget check: final `2/2 PASS` in
  `global_active_project_context_widget_test.dart`.
- Correction chronology:
  - initial harness run stopped at unsupported `pageBack()` lookup;
  - correction 1 used the current route Navigator; no production change;
  - the retry exposed an off-screen submit hit-test harness issue;
  - correction 2 adopted the existing bounded scroll/hit-test pattern;
  - final rerun passed both scenarios.
- `git diff --check`: PASS.
- Exact allowlist: PASS; outside-allowlist paths `0`.
- Protected drift: PASS; protected paths `0`.
- Invariants unchanged: schema `22`, backup format `1`, app version
  `0.1.0+1`; platform/pubspec/lock drift `0`.
- Broad Flutter analyze/full suite: not run locally by STANDARD Process v3;
  delegated to Draft PR CI.

## Manual acceptance and artifact

- Register: Issue #479 comment 5483499878.
- `MT-558-001..005`: `PENDING`.
- Artifact: none; APK/AAB build was not authorized.
- Publication boundary: commit/push/Draft PR only; no Ready, merge or release.
- Exact commit and Draft PR identifiers are published in GitHub completion
  evidence after this ledger is committed.

## execution_record

```yaml
issue: 558
risk: R3
requested_model: gpt-5.6-sol
requested_effort: xhigh
execution_mode: standard
orchestration: single-agent
runtime_actual_model: unknown
runtime_actual_effort: unknown
runtime_verification: unverified
routing_mismatch: null
correction_budget_used: 2/2_INITIAL_HARNESS_PLUS_1/1_OWNER_AUTHORIZED
application_test_status: 3/3_TARGETED_PASS
manual_test_status: PENDING
```

## review_recommendation

Keep the PR Draft. Run PR CI and a fresh independent review at the recorded
`gpt-5.6-sol / xhigh` floor before any owner Ready or merge decision.

## Same-scope cache consistency correction

- Authority: Issue #558 comment `5483589282`.
- Reviewed head / Draft PR: `8a200abb98049911bc680a99a8d4d502d7275162` / #559.
- Root cause confirmed: `_refreshActiveProjectOptions()` cleared the last
  validated name map on a transient read failure while the operational session
  selection remained unchanged.
- Correction: transient refresh failure now preserves the last validated
  display cache; a later successful refresh still replaces it normally.
- Correction paths: `.cse/tasks/558_task.md`, `.cse/results/558_result.md`,
  `mobile/lib/app.dart`,
  `mobile/test/global_active_project_context_widget_test.dart`.
- Regression: active B → transient project-list refresh failure → indicator B,
  Reminder default B and Agenda default B.
- First regression run: existing two scenarios passed; the new scenario stopped
  on eager-error test setup before behavior assertion.
- Harness correction: controlled completer delivered the same error after the
  shell refresh attached; production code was unchanged.
- Final targeted widget check: `3/3 PASS`.
- Changed-Dart formatter/idempotence: PASS; 2 files, `0 changed` final.
- `git diff --check`, exact allowlist and protected drift: PASS.
- Invariants unchanged: schema `22`, backup format `1`, version `0.1.0+1`;
  platform/pubspec/lock drift `0`.
- Broad Flutter analyze/full suite: not run locally; remains assigned to PR CI.
- Manual tests `MT-558-001..005`: remain `PENDING`.
- Artifact: none. Draft/Ready/merge state remains unchanged pending push and
  short re-review.

### correction_execution_record

```yaml
authority_comment: 5483589282
classification: SAME_SCOPE_CACHE_CONSISTENCY_CORRECTION
reviewed_head: 8a200abb98049911bc680a99a8d4d502d7275162
owner_authorized_correction_window: 1/1
targeted_widget_status: 3/3_PASS
manual_test_status: PENDING
```

### correction_review_recommendation

Keep PR #559 Draft and stop for the requested short re-review after the
correction commit is pushed. Do not mark Ready or merge.
