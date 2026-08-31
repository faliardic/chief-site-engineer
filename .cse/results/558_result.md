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
correction_budget_used: 2/2
application_test_status: 2/2_TARGETED_PASS
manual_test_status: PENDING
```

## review_recommendation

Keep the PR Draft. Run PR CI and a fresh independent review at the recorded
`gpt-5.6-sol / xhigh` floor before any owner Ready or merge decision.
