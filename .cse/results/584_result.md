# Issue 584 — legacy transition PASS

Current transition validation: 38/38 PASS in one focused invocation. The original Agenda production and test content is unchanged. Earlier implementation/correction evidence is retained below; the final merge commit is recorded in GitHub publication metadata.

## Legacy transition — 2026-09-03

- Authority: https://github.com/faliardic/chief-site-engineer/issues/584#issuecomment-5522033988 and owner continuation.
- Local master was synchronized with --ff-only to e349ae2250b643153bff482db26791e4a659bdf0 before starting the normal merge into 438c51dd7e7d3700f0b32557ea81bd9c6a3c74d2.
- The initial attempt stopped on three conflicts outside the original six paths. Resumed that same pending merge under the additional authority; no abort/restart or history rewrite.
- Resolved mobile/lib/app.dart, mobile/test/global_active_project_context_widget_test.dart and mobile/test/widget_test.dart with exact master content. All three have zero net diff against master. No other conflicts remained.
- Net scope against master: exactly the original three Agenda production files, mobile_agenda_widget_test.dart and the two #584 task/result files. All other paths, including #580 shared-queue/lazy-tab and #581 dedicated project-create/current active-project behavior, match master.
- The three Agenda production files and mobile_agenda_widget_test.dart match the original PR head. No new product behavior, mutation-command, domain/application/storage, attachment/reminder or Concrete changes were introduced.
- Executed once from mobile/: flutter test --no-pub test/mobile_agenda_widget_test.dart --reporter expanded.
- Result: exit 0; 38/38 PASS; "All tests passed!" (00:13). No second invocation.
- Pre/post-test format: four Dart files, zero changes. Diff-check and exact six-path scope: PASS; protected drift against master: NONE.
- Log: focused test log retained locally; path not published
- No analyzer, full suite, build/APK, device or owner-data operation. Owner manual acceptance MT-584-001..006 remains DEFERRED by the 2026-09-02 decision, not PASS or field acceptance.
- Publication gate satisfied for a normal merge commit and push to the existing branch. PR #585 must remain Draft with base codex/issue-581-dashboard-project-create; no retarget/Ready/merge. The earlier independent review applies to the original head, not automatically to this transition commit.

## Original implementation — FAIL CLOSED (historical record)

- Base: 187e6f66d5ae6753afa2080c78b340ffba188eee.
- Branch: codex/issue-584-agenda-icon-first; stacked base: codex/issue-581-dashboard-project-create.
- Scope: three authorized Agenda production files, mobile_agenda_widget_test.dart, task/result evidence.
- Local list/form/detail action conversion implemented; not accepted/published because the focused gate failed.
- Callback/command/navigation method prefixes match the exact base; selected values and destructive dialog text remain unchanged.
- All four changed Dart files formatted before the single focused invocation.
- Command (mobile/): flutter test --no-pub test/mobile_agenda_widget_test.dart --reporter expanded
- Result: exit 1; 38 tests total, 27 PASS / 11 FAIL. No second invocation.
- Conditional test files unchanged and not invoked.
- No post-test source/test correction, commit, push, PR, full suite, analyze, build, device or owner-data access.
- Read-only final checks: diff --check PASS; exact six-path allowlist PASS; protected drift NONE; index empty; HEAD unchanged.
- Invariants: schema 22 / backup 1 / version 0.1.0+1.
- Parent #579/#582/#583 branches were not written.
- Manual acceptance: PENDING, separate owner gate.
- Runtime model/reasoning metadata unavailable; independent R4 review required.

## Exact failures and classification

All failures are in mobile/test/mobile_agenda_widget_test.dart.

| Failing test | Exact evidence / classification |
| --- | --- |
| Ajanda works at 320 px with filters, long Turkish text and 40 px actions | Tap on Ajanda Text at Offset(133.3, 763.0) is outside Size(320.0, 760.0); agenda-project-filter expected one, found zero (line 292). Existing shell-entry harness hit target. |
| new Agenda log keeps every photo from one multi selection | Bad state: No element at scrollUntilVisible (line 449). find.byType(Scrollable).last resolved an editable-text scrollable, not the form list; drag Offset(400.0, 600.0) misses Size(800.0, 600.0). Existing scrolling harness. |
| form deep-link preserves the exact draft and creates no records | agenda-concrete-select-category tap Offset(160.0, 826.6) is outside Size(320.0, 820.0); expected AgendaCategory.concrete, actual AgendaCategory.generalNote (line 588). Existing reveal/tap harness; Concrete source unchanged. |
| icon-first list preserves routes and state at 320/1.6 dark | A SemanticsHandle was active at the end of the test. New harness cleanup defect. |
| icon-first list preserves routes and state at 320/1.6 light | A SemanticsHandle was active at the end of the test. New harness cleanup defect. |
| icon-first form keeps values validation and photo selection at 320/1.6 dark | A SemanticsHandle was active at the end of the test. New harness cleanup defect. |
| icon-first form keeps values validation and photo selection at 320/1.6 light | A SemanticsHandle was active at the end of the test. New harness cleanup defect. |
| icon-first detail preserves edit archive restore and photos at 320/1.6 dark | A SemanticsHandle was active at the end of the test. New harness cleanup defect. |
| icon-first detail preserves edit archive restore and photos at 320/1.6 light | A SemanticsHandle was active at the end of the test. New harness cleanup defect. |
| icon save returns route result once while pending; editing=false | A SemanticsHandle was active at the end of the test. New harness cleanup defect. |
| icon save returns route result once while pending; editing=true | A SemanticsHandle was active at the end of the test. New harness cleanup defect. |

The eight new tests reached end-of-test verification without a preceding behavior assertion failure, but are FAIL, not PASS. addTearDown disposal did not occur before WidgetTester._verifySemanticsHandlesWereDisposed. No correction was applied after the gate.

## Execution record

FAIL values below mean the acceptance gate is not satisfied; they do not assert an unproven domain defect.

~~~yaml
execution_record:
  issue: 584
  diagnostic_base: 187e6f66d5ae6753afa2080c78b340ffba188eee
  branch: codex/issue-584-agenda-icon-first
  production_scope:
    - mobile/lib/features/agenda/agenda_page.dart
    - mobile/lib/features/agenda/log_form_page.dart
    - mobile/lib/features/agenda/log_detail_page.dart
  icon_first_list: FAIL
  icon_first_form: FAIL
  icon_first_detail: FAIL
  visible_state_values_preserved: PASS
  destructive_dialog_text_preserved: PASS
  focused_tests: FAIL
  focused_test_count: 38
  passed: 27
  failed: 11
  protected_drift: NONE
  invariants: 22 / 1 / 0.1.0+1
  pr: null
  draft: null
  ready: false
  merged: false
review_recommendation:
  decision: FAIL_CLOSED
~~~

No PR exists for this local work, so draft is null rather than a fabricated PR state. Local changes remain uncommitted for a separately authorized continuation; no new technical slice started.

## Correction round 1/2 — preparation

- Authority: https://github.com/faliardic/chief-site-engineer/issues/584#issuecomment-5505047760
- The original 27/38 failure record above is preserved verbatim.
- Correction edits: mobile/test/mobile_agenda_widget_test.dart and this evidence file only.
- Eight new test cases now dispose their own SemanticsHandle in try/finally before end-of-test verification; all semantics assertions retained.
- Shell entry now targets the real Ajanda NavigationDestination, not the deliberately hidden label. The NavigationBar is fixed, not a scrollable.
- The three interaction paths identify the exact route ListView/Viewport/Scrollable, reveal the full interactive target, assert all four bounds plus hitTestable, and use real tester.tap.
- Photo-selection, Concrete category/navigation, captured fields and mutation assertions retained. No viewport/text-scale changes, skips, callback invocation or masked failures.
- Preserved production SHA-256 values (before and after format):
  - agenda_page.dart: 10C08D621340F8FCA17BF74EBDE36A3BD97EB3E9458375F4B89C6F586EC01AE7
  - log_form_page.dart: D4CCAAB1993DF102305E65F0AC3BA7459CA9EFE82F788C020849CECE0F8142EE
  - log_detail_page.dart: 1516B47F83CF014B4D2949D6EEEE58884B6537611FF122A671050FD6D83714A8
- All four locally changed Dart files formatted. Production bytes unchanged.
- Correction focused invocation: NOT RUN yet. Any remaining geometry failure must stop this round without production edits.

## Correction round 1/2 — final local validation

- Executed once from mobile/: flutter test --no-pub test/mobile_agenda_widget_test.dart
- Result: exit 0; 38/38 PASS; runner completed with "All tests passed!" (00:16).
- All eight SemanticsHandle cases passed with per-test try/finally disposal and unchanged accessibility assertions.
- All three interaction cases passed with exact route-owned scrolling, complete control bounds, hitTestable and real taps. No remaining inaccessible-control geometry was found; no production correction was needed.
- Existing downstream project/filter/category/draft/photo-command/navigation/route-result assertions preserved.
- Final diff --check: PASS. Exact six-path allowlist: PASS. Protected drift: NONE.
- Final invariants: 22 / 1 / 0.1.0+1. Parent branch heads unchanged.
- Correction writes only the primary test and this result; the three production SHA-256 values remain identical to the preparation record.
- No second correction test invocation, full suite, broad analyze, build, APK/AAB, device or owner-data operation.
- Flutter PR workflow targets master only; this stacked PR base does not trigger that workflow. No CI PASS claim.
- Publication authorized after these checks: one commit/push on codex/issue-584-agenda-icon-first and one Draft PR targeting codex/issue-581-dashboard-project-create.
- Independent R4 review is next. Ready/merge false; owner manual acceptance remains PENDING.

~~~yaml
correction_validation:
  issue: 584
  correction_round: 1/2
  base: 187e6f66d5ae6753afa2080c78b340ffba188eee
  previous_focused: FAIL_27_OF_38
  semantics_handle_cleanup: PASS
  deterministic_real_scroll: PASS
  real_hit_test_and_tap_preserved: PASS
  production_changed_in_correction: false
  focused_tests: PASS
  focused_test_count: 38
  protected_drift: NONE
  invariants: 22 / 1 / 0.1.0+1
  publication_snapshot: BEFORE_COMMIT_PUSH_PR
  ready: false
  merged: false
review_recommendation:
  decision: INDEPENDENT_R4_REVIEW
~~~
