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

## Owner manual-acceptance route-adoption correction

- Authority: Issue #558 comment `5488293972`.
- Exact failing head / Draft PR: `6f4684bf0dbef88eb1e3eb99b9c7075d53b82e3b`
  / #559.
- Owner evidence: `MT-558-005` failed at the exact head for Dashboard B →
  Proje Albümü → local A; the Album error recovered only after project retry.
- Root cause confirmed: Album selection starts its local catalog discovery and
  reports the new ID in the same event. Shell adoption then started Agenda
  project discovery against the same SQLite path. The first cache-hit
  correction removed that direct read; the controlled test further proved that
  an immediate Dashboard epoch rebuild would otherwise start another Agenda
  discovery while the Album read was still in flight.
- Final correction: shell retains the last successfully validated active
  `MobileProject` options; cached A is adopted without fresh discovery. Album
  adoption defers Dashboard epoch reconstruction until the route closes, after
  the local Album reload is complete. Cache misses retain fresh Agenda
  validation, and an ID absent from Agenda active options remains fail-closed.
- Exact changed paths: `mobile/lib/app.dart`,
  `mobile/test/global_active_project_context_widget_test.dart`,
  `.cse/tasks/558_task.md`, `.cse/results/558_result.md`.
- Protected drift: none. `ProjectMediaAlbumPage`, `ActiveProjectSession`,
  AppDatabase/coordinator, Puantaj, Envanter, schema/migration, backup/version
  and platform paths are unchanged.

### Validation evidence

- Targeted widget gate: final `4/4 PASS`.
- Controlled regression proves: B → local A with catalog discovery held in
  flight → Agenda `listProjects()` count unchanged and overlap count `0` →
  shared session A → Dashboard, Hatırlatıcı, Ajanda and Daha visibly A.
- The same regression selects an Album-only stale ID, observes one fresh Agenda
  validation and proves the shared session remains A.
- Correction chronology:
  - first run stopped at two deterministic compilation issues (missing
    `MobileProject` import and invalid const test fixture access);
  - second run passed the existing three cases and exposed the immediate
    Dashboard epoch discovery overlap;
  - Dashboard reconstruction was deferred to Album route completion;
  - final run passed all four cases.
- Changed-file static analysis: PASS; `No issues found`.
- Changed-Dart format/idempotence: PASS; final `0 changed`.
- Full `git diff --check`: PASS.
- Exact allowlist/protected drift: PASS; outside paths `0`.
- Invariants unchanged: schema `22`, backup format `1`, app version
  `0.1.0+1`; platform/pubspec/lock drift `0`.
- Broad Flutter validation/full suite: not run locally; remains assigned to PR
  CI under the STANDARD lane.
- APK/AAB: not built, as explicitly prohibited.
- Manual status: `MT-558-005` owner-reported `FAIL` at the failing head;
  correction re-test is `PENDING`. No Issue #479 register mutation was made
  outside the four-path correction allowlist.

### manual_acceptance_correction_execution_record

```yaml
issue: 558
authority_comment: 5488293972
classification: OWNER_MANUAL_ACCEPTANCE_ROUTE_ADOPTION_CORRECTION
failing_head: 6f4684bf0dbef88eb1e3eb99b9c7075d53b82e3b
pr: 559
risk: R3
requested_model: gpt-5.6-sol
requested_effort: xhigh
execution_mode: standard
orchestration: single-agent
runtime_actual_model: unknown
runtime_actual_effort: unknown
runtime_verification: unverified
routing_mismatch: null
targeted_widget_status: 4/4_PASS
manual_test_status: MT-558-005_FAIL_AT_OLD_HEAD_RETEST_PENDING
artifact_status: NOT_BUILT
ready_authorized: false
merge_authorized: false
```

### manual_acceptance_correction_review_recommendation

Keep PR #559 Draft. Re-review the correction commit, then owner re-test
`MT-558-005` on a separately authorized fresh Acceptance build. Do not mark
Ready or merge under this authority.
