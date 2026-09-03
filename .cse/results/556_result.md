# Issue #556 — initial implementation / FAIL-CLOSED

## Execution record — 2026-09-02

- Process lane: STANDARD.
- Authority: issue comments 5505907861, 5507779648 and 5508092381 (locked UI contract retained).
- Branch: `codex/issue-556-inventory-active-project-context`.
- Base / unchanged HEAD: `8793f48dff881db69f63b94400f5b7746d7f012d`.
- Candidate: interactive shared AppBar chooser; Inventory dropdown and space removed; exact validated shared input; delayed adoption after successful local load; inactive/stale-load and pending-flow guards.
- Changed Dart files formatted before the sole focused invocation; candidate diff reviewed.
- Focused gate: **FAIL — 31/39 PASS, 8 FAIL, exit code 1**.
- File totals: Inventory `26/26 PASS`; global context `1/6 PASS`; bidirectional context `4/7 PASS`.
- Integrated gate: NOT RUN. Analyzer: NOT RUN. No second focused invocation.
- After failure: no production/test correction, no additional format, no commit/push/PR publication.
- Existing local candidate retained. Index empty. Tested Dart hashes unchanged after failure.
- `git diff --check`: PASS; exact allowlist: PASS; protected drift: NONE.
- Invariants: schema `22` / backup format `1` / app `0.1.0+1`.
- Full suite/build/APK/AAB/device/manual acceptance: NOT RUN.
- Manual tests: PENDING / NOT RUN; no PASS claim or #479 status mutation.
- Ready: false; merge: false. Independent review/publication not reached.

## Authorized invocation consumed

From `mobile`, using Flutter `C:\Users\Fatih\.cache\flutter-sdk\3.44.6-ee80f08\flutter\bin\flutter.bat`:

```text
flutter test --no-pub test/inventory_page_test.dart test/global_active_project_context_widget_test.dart test/project_context_bidirectional_widget_test.dart
```

## Eight exact failures

Seven failures share this exception (the failure occurred before the intended downstream assertions):

```text
The finder "Found 0 widgets with text "Proje seç": []" (used in a call to "tap()") could not find any matching widgets.
```

| File under mobile/test | Line | Exact test name |
| --- | --- | --- |
| global_active_project_context_widget_test.dart | 50 | Dashboard B opens exact Inventory B and hidden external A is adopted on return |
| global_active_project_context_widget_test.dart | 236 | active B is visible and defaults new captures without form-local retargeting |
| global_active_project_context_widget_test.dart | 337 | transient project refresh failure preserves visible and capture B context |
| global_active_project_context_widget_test.dart | 400 | Album adopts cached A without overlapping discovery and rejects stale ID |
| project_context_bidirectional_widget_test.dart | 77 | Inventory AppBar selection commits shared A once only after success and preserves A in captures |
| project_context_bidirectional_widget_test.dart | 483 | shell routes exact B and adopts Album A without hidden Attendance mutation |
| project_context_bidirectional_widget_test.dart | 621 | shell opens Puantaj on exact shared project and adopts only successful load |

Eighth failure: `shared AppBar chooser stays textual bounded and usable at 320px large text`, `global_active_project_context_widget_test.dart:125`:

```text
Expected: exactly one matching candidate
Actual: Found 0 widgets with key [<'active-project-indicator'>] (considering only hit-testable widgets with a RenderBox)
```

Preceding exact missed-tap evidence: `_openTab` at line 479 tapped `find.text('Daha').last`; its center was `Offset(293.3, 807.0)`, outside root `Size(320.0, 800.0)`. The AppBar chooser was not reached, so this is not evidence of a chooser layout defect or a narrow-screen PASS.

Read-only source confirmation: Dashboard's `actionLabel: 'Proje seç'` is rendered by `_DashboardIconAction` as an `IconButton` tooltip, not a `Text` widget; the shell NavigationBar uses `NavigationDestinationLabelBehavior.alwaysHide`. The failing harness paths use text-based finders. No correction was applied after the gate.

## Exact candidate paths and frozen Dart hashes (SHA-256)

- `.cse/tasks/556_task.md`
- `.cse/results/556_result.md`
- `mobile/lib/app.dart`: `C6223988CCA1AA933BF44AC8680819B5F802DF476108ED4EE285CA21A3486E8A`
- `mobile/lib/features/inventory/inventory_page.dart`: `98E3307A65047D933185E75FB9112D5EA3E3019ABD10D082C9839A514A4A7BA8`
- `mobile/test/inventory_page_test.dart`: `5611726B643EA0F478183FCF1E03BCFF80078D1FA9951CBA4FB9B8B291ACB264`
- `mobile/test/global_active_project_context_widget_test.dart`: `CC3AF3977694B19ACB8AE234411FF0498F94C31DF653125F30A896EB84F8B8EB`
- `mobile/test/project_context_bidirectional_widget_test.dart`: `1EC8DD2986AB1E5080B50983BCDC406362FF777FEB6C999B9E29265A4853D466`

Recommendation: FAIL_CLOSED. A new correction authorization is required before updating the scoped real-button/navigation finders and rerunning validation. Preserve downstream isolation, session, failure-rollback and mutation assertions; do not change Dashboard production or enlarge the viewport.

## Correction 1 — test-harness targeting only — FAIL-CLOSED

- Authority: https://github.com/faliardic/chief-site-engineer/issues/556#issuecomment-5508366579.
- The initial `31/39` failure and all eight exact failures above are preserved as history.
- Accessibility precondition: inspected the actual Dashboard build chain `dashboard-project-selection-required` -> `_ProjectStateSurface` -> `_DashboardIconAction` -> enabled `IconButton`, with `tooltip: 'Proje seç'` and matching Semantics label. The AppBar still renders `Text(label)` with the selected project name and `Aktif proje: <name>` tooltip/Semantics. No production accessibility label was added or removed.
- Correction scope: seven obsolete Dashboard text finders in the two authorized context test files; they now resolve exactly one hit-testable, enabled IconButton with the existing `Proje seç` tooltip inside the existing selection-required surface. Real `tester.tap` calls retained.
- Only the narrow-screen test's Daha/Envanter navigation targeting changed to the existing visible icons scoped inside NavigationBar. Original viewport `320x800`, scale `1.6`, pumps, test paths and downstream assertions retained.
- Only the two touched context test files were formatted. The complete correction diff was reviewed before testing.
- Production files and passing `inventory_page_test.dart` remained byte-identical to the initial failed candidate (hashes above). Task hash remained `5FB97299AA00C49D9FEBB470291184C35DA516E2F1AF4660D40CDA2881EDA79E`.
- Fresh focused invocation: **FAIL — 38/39 PASS, 1 FAIL, exit code 1**. Same exact focused command as recorded above; executed once under the new authority, zero retries.
- File totals: Inventory `26/26 PASS`; global context `5/6 PASS`; bidirectional context `7/7 PASS`.
- All seven prior Dashboard selector failures now pass. The narrow-screen test now reaches the opened chooser and fails its existing height assertion.
- Fresh integrated invocation: NOT RUN. Analyzer: NOT RUN. No narrower test, post-failure source/test correction or post-failure format.
- HEAD remains `8793f48dff881db69f63b94400f5b7746d7f012d`; index empty; no commit/push/PR. Local changes retained.
- Pre/post-test source and test hashes verified; `git diff --check` PASS; exact seven-path implementation allowlist intact; correction changes limited to the two authorized tests and this appended evidence.
- Protected drift: NONE; invariants `22 / 1 / 0.1.0+1`; no build/device/manual acceptance; manual tests remain PENDING / NOT RUN; Ready/merge false.

### Exact remaining failure

Test: `shared AppBar chooser stays textual bounded and usable at 320px large text`.

Location: `mobile/test/global_active_project_context_widget_test.dart:134`.

```text
Expected: a value less than <800>
  Actual: <800.0>
   Which: is not a value less than <800>
```

Unchanged assertion: `expect(tester.getSize(chooser).height, lessThan(800));` where `chooser` is the existing `active-project-chooser` key on AlertDialog. The control was hit-testable, the chooser opened, and the preceding width assertion passed. This run does not establish whether the measured box is the visible dialog panel or an outer full-height box; it is not a bounded-height or complete large-text PASS. No assertion was weakened and no production defect was masked.

Frozen correction test hashes (unchanged after the failed invocation):

- `mobile/test/global_active_project_context_widget_test.dart`: `3E2064556C0F89E0EF619EC93AF30855F4FF03F3C8E6FE4CB0F6D636DFCC3576`.
- `mobile/test/project_context_bidirectional_widget_test.dart`: `6F15BB9EB8F20D14573DACCE6CA71093FF83CDF6524D03DDBDB15BC3C65A65D7`.

Decision: **FAIL_CLOSED**. Further investigation/correction and validation require a new owner decision; no authority remains to retry or publish this candidate.

## Correction 2 — static measurement diagnosis before editing

- Authority: https://github.com/faliardic/chief-site-engineer/issues/556#issuecomment-5508488904.
- Classification: **A — wrong measurement target**, established statically; no exploratory Flutter invocation.
- Exact finder: `find.byKey(const Key('active-project-chooser'))`; keyed widget: `AlertDialog` in `mobile/lib/app.dart`.
- Test physical size: `320 x 800`; device-pixel ratio: `1.0`; logical viewport: `320 x 800`; text scale: `1.6`. No logical/physical unit mismatch caused the failure.
- Previously reported measurement: height `800.0`. The prior stdout did not emit width; the outer wrapper's `320 x 800` bounds follow from the viewport and layout source, rather than a new runtime measurement.
- Flutter runner source inspected: `C:\Users\Fatih\.cache\flutter-sdk\3.44.6-ee80f08\flutter\packages`.
- `flutter_test/lib/src/controller.dart:2176` measures the keyed element's first RenderBox, not the innermost visible surface.
- `flutter/lib/src/material/dialog.dart:942` builds a `Dialog`; its non-fullscreen build at lines 264–320 is `Semantics -> AnimatedPadding -> MediaQuery -> Align -> ConstrainedBox -> Material(type: MaterialType.card)`. Thus the keyed AlertDialog exposes the outer `RenderSemanticsAnnotations` box. The Align expands under finite viewport constraints (`rendering/shifted_box.dart:478`); padding plus Align makes that outer box full-window. The measured 800.0 is not the Material panel or the modal barrier.
- The visible panel is the unique descendant `Material` with `MaterialType.card`. `Dialog` uses default insets `horizontal: 40, vertical: 24` (`dialog.dart:32`), plus keyboard insets, and `showDialog` uses SafeArea by default. CSE sets no dialog inset/constraint override. In this zero-inset test, the panel is therefore bounded by width `240` and height `752`, strictly below the logical viewport height `800`.
- Application content has `ConstrainedBox(maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.5)` = `400` logical pixels, with a shrink-wrapped scrollable ListView. AlertDialog uses a minimum-height Column with Flexible content. These are existing constraints, not proposed production changes.
- Permitted correction: within the single failing test, locate the existing card Material under the existing chooser key; measure that panel; compare against `tester.view.physicalSize / tester.view.devicePixelRatio`; retain strict height `<` and every subsequent interaction/identity/accessibility assertion.
- Outcome A means `app.dart` and all other production files remain read-only. Passing Inventory/bidirectional tests, task file and all seven corrected selectors remain unchanged. Previous `31/39` and `38/39` histories remain intact above.
- Validation for this authority: NOT YET RUN at diagnosis time; one focused, then conditional integrated, then conditional analyzer invocation; zero retries.

### Correction 2 focused outcome — FAIL-CLOSED (recorded on next authority)

- The third overall focused invocation ran exactly once under comment 5508488904: **FAIL — 38/39 PASS, 1 FAIL, exit code 1**. Inventory `26/26 PASS`; global context `5/6 PASS`; bidirectional context `7/7 PASS`.
- Measured visible chooser: `Material(type: MaterialType.card)` under `active-project-chooser`, `Size(240.0, 321.4)`; logical viewport `Size(320.0, 800.0)`; DPR `1.0`; text scale `1.6`. Width comparison and strict height `<` comparison passed. No production layout correction was required.
- The same test reached end-of-test verification and then failed with the exact exception below. This was not a complete narrow-screen/accessibility PASS.

```text
A SemanticsHandle was active at the end of the test.
All SemanticsHandle instances must be disposed by calling dispose() on the SemanticsHandle.

#0 WidgetTester._verifySemanticsHandlesWereDisposed (package:flutter_test/src/widget_tester.dart:1074:7)
#1 WidgetTester._endOfTestVerifications (package:flutter_test/src/widget_tester.dart:1063:5)
#2 TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1968:22)
```

- Failing test: `shared AppBar chooser stays textual bounded and usable at 320px large text` in `mobile/test/global_active_project_context_widget_test.dart`.
- No post-failure file edit, retry, integrated test, analyzer, commit, push, PR, build or device/manual acceptance occurred under that authority. This outcome is appended now under new comment 5508612720; all prior records remain intact.
- Preserved test SHA-256: `5EB39DAC0A347A98DEE93F76B835E4FA939D804029D51FEE2B558F3A58880DB4`. All other source/test/task hashes match the correction 1 preserved candidate. HEAD remained `8793f48dff881db69f63b94400f5b7746d7f012d`.

## Correction 3 — exact SemanticsHandle lifecycle — pre-validation record

- Authority: https://github.com/faliardic/chief-site-engineer/issues/556#issuecomment-5508612720.
- The exact failing test creates its own handle with `final semantics = tester.ensureSemantics()`. Its existing `addTearDown(semantics.dispose)` is replaced by a local `try/finally` around the same test body, with `semantics.dispose()` exactly once in `finally`, before the test body completes (also when an assertion throws).
- Scope: only this test and this appended evidence. No production file, other test, task file, previously corrected selector, sizing comparison or downstream assertion is changed. No exception swallowing, semantics disabling, extra pump/delay or viewport/text-scale change.
- Previous focused histories remain `31/39`, `38/39` (outer-wrapper height), `38/39` (SemanticsHandle lifetime). They are not rewritten as passes.
- Validation under this authority: NOT YET RUN at this pre-validation point. One fresh focused invocation, then integrated only on focused PASS, then analyzer only on integrated PASS; zero retries. Any failure stops all later gates and publication without further edits.

### Correction 3 completed gates — analyzer FAIL-CLOSED (recorded on next authority)

- Under comment 5508612720, exactly one focused invocation passed **39/39**, then exactly one integrated invocation passed **54/54**, then exactly one `flutter analyze --no-pub` invocation failed with exit code `1`.
- Focused command: `flutter test --no-pub test/inventory_page_test.dart test/global_active_project_context_widget_test.dart test/project_context_bidirectional_widget_test.dart`.
- Integrated command: `flutter test --no-pub test/active_project_session_test.dart test/global_active_project_context_widget_test.dart test/project_context_bidirectional_widget_test.dart test/inventory_page_test.dart test/widget_test.dart`.
- The narrow-screen/accessibility test passed, including handle disposal, real interactions, downstream project-context checks and no-overflow assertion. Both runs measured the same chooser `240 x 321.4`, logical viewport `320 x 800`, DPR `1.0`, text scale `1.6`.
- Exact analyzer diagnostics (all `info`, but gate exit code `1`):

```text
Statements in an if should be enclosed in a block. Try wrapping the statement in a block - lib\app.dart:398:7 - curly_braces_in_flow_control_structures
Statements in an if should be enclosed in a block. Try wrapping the statement in a block - lib\features\inventory\inventory_page.dart:938:7 - curly_braces_in_flow_control_structures
Statements in an if should be enclosed in a block. Try wrapping the statement in a block - lib\features\inventory\inventory_page.dart:1619:7 - curly_braces_in_flow_control_structures
3 issues found. (ran in 31.3s)
```

- After the analyzer failure: no file edit, retry, narrower test, commit, push, PR or build/device/manual acceptance. This historical outcome is appended under new comment 5508691422.
- Passing test SHA-256 values: Inventory `5611726B643EA0F478183FCF1E03BCFF80078D1FA9951CBA4FB9B8B291ACB264`; global context `5E3CFE8F95615465F524998B54642E35836A9EFBDF13319E1CE22C1FDD475ACA`; bidirectional context `6F15BB9EB8F20D14573DACCE6CA71093FF83CDF6524D03DDBDB15BC3C65A65D7`.

## Correction 4 — three mechanical analyzer brace fixes — pre-validation record

- Authority: https://github.com/faliardic/chief-site-engineer/issues/556#issuecomment-5508691422.
- Confirmed all three reported locations are existing single-statement `return;` condition bodies: `app.dart` `_selectAppBarProject`; `inventory_page.dart` `selectProject` and `_openQuickCreate`.
- Exact correction adds one brace pair around each existing return only. Conditions, evaluation order, async behavior, return values and surrounding control flow remain unchanged; no fourth production location changes.
- Only the two authorized production Dart files are formatted. All test files, the task record, previously corrected selectors, chooser measurements and SemanticsHandle lifecycle remain frozen.
- Current branch/base remain `codex/issue-556-inventory-active-project-context` / `8793f48dff881db69f63b94400f5b7746d7f012d`. Existing implementation is preserved; no reset/stash/recreation.
- This authority permits one fresh focused, conditional integrated, conditional analyzer round. Validation is NOT YET RUN at this pre-validation point; every prior failed-run entry remains unchanged. Any invocation failure stops further correction/retry/publication.

## Final local validation — PASS — 2026-09-02

- Process lane: STANDARD; final correction authority: comment 5508691422. This is correction 4 in the explicit owner-authorized chronology above, not an unapproved retry of an earlier failed gate.
- Latest scope delta: exactly three brace pairs at the reported return statements in the two authorized production files, plus this evidence. Token comparison before/after formatting confirmed no condition, statement, order, async contract or fourth source location changed.
- All three test files are byte-identical to the prior `39/39` and `54/54` passing versions; task file remains unchanged. Production/test hashes were rechecked after validation and match the pre-validation candidate.
- Final focused command, run once from `mobile`: `flutter test --no-pub test/inventory_page_test.dart test/global_active_project_context_widget_test.dart test/project_context_bidirectional_widget_test.dart` — **39/39 PASS**, exit `0` (Inventory 26, global context 6, bidirectional context 7).
- Final integrated command, run once only after focused PASS: `flutter test --no-pub test/active_project_session_test.dart test/global_active_project_context_widget_test.dart test/project_context_bidirectional_widget_test.dart test/inventory_page_test.dart test/widget_test.dart` — **54/54 PASS**, exit `0`.
- Final analyzer command, run once only after both test gates PASS: `flutter analyze --no-pub` — **PASS**, exit `0`, exact output `No issues found! (ran in 28.3s)`.
- Both final test runs retained measured chooser `Size(240.0, 321.4)` against logical viewport `Size(320.0, 800.0)`, DPR `1.0`, text scale `1.6`. Strict height bound, visible label, accessibility, real taps, project-context assertions, no-overflow check and SemanticsHandle lifecycle all passed.
- No second invocation within this authority, post-test source/test correction, full Flutter suite, build/APK/AAB, emulator/device/ADB, MAIN launch or manual acceptance.

### Immutable validation chronology

| Attempt / authority | Focused | Integrated | Analyzer | Outcome at that time |
| --- | --- | --- | --- | --- |
| Initial implementation | 31/39; 8 FAIL | NOT RUN | NOT RUN | FAIL-CLOSED |
| Correction 1 / 5508366579 | 38/39; outer-wrapper measurement FAIL | NOT RUN | NOT RUN | FAIL-CLOSED |
| Correction 2 / 5508488904 | 38/39; SemanticsHandle FAIL | NOT RUN | NOT RUN | FAIL-CLOSED |
| Correction 3 / 5508612720 | 39/39 PASS | 54/54 PASS | 3 brace diagnostics; exit 1 | FAIL-CLOSED |
| Correction 4 / 5508691422 | 39/39 PASS | 54/54 PASS | No issues; exit 0 | Final local PASS |

### Final candidate / publication boundary

- Base: `8793f48dff881db69f63b94400f5b7746d7f012d`; branch: `codex/issue-556-inventory-active-project-context`; Draft PR target: `master`.
- Exact implementation paths remain the seven listed above: two production files, three test files, task and result. `git diff --check` and exact allowlist checks PASS; protected drift NONE.
- Invariants: schema `22` / backup format `1` / app `0.1.0+1`. Domain/application/storage/schema/migration/backup/autosave/identity/#586/platform/package/permission paths remain untouched.
- Final source SHA-256: `mobile/lib/app.dart` = `B1FD8F827EDE7471138F871122FD397AF93E9EBB312A3761D110DDF41CB23D46`; `mobile/lib/features/inventory/inventory_page.dart` = `872E716A04D14937E771060723D0FF765F36C98F41AF647B2D8DD8AD3502E64E`.
- Final test SHA-256: Inventory = `5611726B643EA0F478183FCF1E03BCFF80078D1FA9951CBA4FB9B8B291ACB264`; global context = `5E3CFE8F95615465F524998B54642E35836A9EFBDF13319E1CE22C1FDD475ACA`; bidirectional context = `6F15BB9EB8F20D14573DACCE6CA71093FF83CDF6524D03DDBDB15BC3C65A65D7`.
- Manual register: [#479 comment 5508768226](https://github.com/faliardic/chief-site-engineer/issues/479#issuecomment-5508768226), stable `MT-556-001..005` all **PENDING**, not executed. No field-acceptance or release-readiness claim.
- All local gates now permit one minimal implementation/evidence commit, normal branch push and one Draft PR to master. The commit containing this result identifies the tested candidate; the final commit SHA and PR URL are recorded by the publication metadata, without an extra evidence-only commit.
- PR CI: PENDING at this pre-publication record; local PASS is not a CI claim. Publication must stop for independent review. Ready false; merged false; #586 not started.
