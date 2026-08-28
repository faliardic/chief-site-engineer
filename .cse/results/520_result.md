# Issue 520 — Slice 4 execution result

Date: 2026-08-28

## Execution context

- Canonical authority: Issue #520 comment 5455488954
- Parent Epic: #506
- Base SHA: 1f92da6e330d69f9554db9e07d260919e77c20ea
- Branch: codex/issue-520-inventory-destination-kroki-list
- Requested routing: gpt-5.6-sol / max
- Runtime model / effort visibility: unknown / null / unverified
- Risk / review floor: R4 / gpt-5.6-sol max independent review
- Implementation status: IMPLEMENTED — OWNER SMOKE PENDING
- Manual test status: PENDING

The official V: repository was clean at the exact base before the mandatory
first write to .cse/tasks/520_task.md. No conflicting remote Issue #520 branch
or open PR was present at start.

## Changed paths

1. .cse/tasks/520_task.md
2. mobile/lib/app.dart
3. mobile/lib/features/inventory/inventory_page.dart
4. mobile/lib/features/inventory/inventory_map_view.dart
5. mobile/test/inventory_page_test.dart
6. mobile/test/widget_test.dart
7. .cse/results/520_result.md

Conditional bootstrap and Inventory application paths were proven sufficient
and remain unchanged. No database, schema, migration, backup, attachment,
pubspec/lock, Android, iOS, permission, signing, package, or unrelated domain
file was changed.

## Implemented contract

- Mobile shell now has exactly six ordered destinations: Başlangıç,
  Hatırlatıcı, Ajanda, Envanter, Puantaj, Daha.
- Daha exposes the existing Beton Paketi and Sicil surfaces; attendance routes
  use index 4, concrete detail routes leave Daha selected at index 5, and
  Envanter is index 3.
- InventoryPage binds to AgendaApplication.listProjects/projectChanges and the
  existing InventoryApplicationPort without bootstrap or application-port
  changes.
- Zero active projects perform zero Inventory I/O; one project auto-selects;
  many require explicit selection. Project switching clears route-local
  search/filter/view/snapshot/focus state. An unavailable selected project
  fails with inventory_project_unavailable and never silently switches.
- The no-sketch state uses exact copy “Bu projede henüz şematik kroki yok.” and
  exact action “Kroki ekle”, reuses InventorySketchEditorPage create/recover,
  and reloads canonical truth only on a true finalized return.
- Kroki and Liste derive from one page-owned canonical asset list. The map
  controller accepts exact page-owned object identities and performs no second
  application read.
- Normalized-name, category, status, and active/archive filters are
  presentation-only. Archived rows may be listed and never become markers.
- Empty Inventory, empty filtered result, no sketch, project-required,
  project-selection, corrupt geometry, unavailable project, and load failure
  are distinct safe states.
- Marker tap opens the exact existing asset detail. A valid list row switches
  to Kroki, centers its exact active placement, and shows a two-second marker
  outline plus focus icon/semantic announcement. Missing/invalid placement or
  corrupt geometry remains in Liste with a typed diagnostic.
- Focus, viewport, search, and filters are session-only; focused tests observed
  zero persistent mutation from filter/focus actions.

## Focused proof matrix

1. Exact six shell destinations/order: PASS
2. No seventh destination: PASS
3. Direct Envanter access: PASS
4. Daha → Beton Paketi/Sicil reachability: PASS
5. Notification/deep-link indexes: PASS by exact source audit
6. Zero/one/many active projects: PASS
7. Project switch clears old session/focus: PASS
8. No-sketch exact copy/action/editor launch: PASS
9. Finalize return canonical reload: PASS
10. Kroki/Liste exact same identities/source snapshot: PASS
11. Active marker/list mapping: PASS
12. Archived list filter with no archived marker: PASS
13. Name/category/status/archive filters: PASS
14. Empty Inventory vs empty search vs failure: PASS
15. Marker → exact detail identity: PASS
16. List → exact focus/center/two-second highlight: PASS
17. Missing placement/corrupt geometry remains Liste with typed failure: PASS
18. Filter/focus persistent mutation count: PASS, zero

## Validation

### Formatting

- PASS using the repository Flutter SDK Dart formatter on touched Dart files
  only.
- One environment-only recovery was used after the unqualified dart command
  was not present on PATH. The exact configured SDK was resolved at
  C:/Users/Fatih/.cache/flutter-sdk/3.44.6-ee80f08/flutter.

### Focused Flutter gate

Command:

    flutter test --no-pub test/inventory_page_test.dart test/widget_test.dart

- Invocation 1: FAIL; a single mechanical root cause produced three dropdown
  RenderFlex overflow classes across six Inventory widget cases. Final count
  was 14 passed / 6 failed.
- Authorized narrow retry after adding expanded/ellipsis constraints and a
  controller-rebind lifecycle guard: PASS, 20/20.
- Focused invocation count: 2; retry count: 1 of 1.
- No full suite, integration suite, build, APK/AAB, emulator, ADB, device, or
  scripted acceptance was run.

### Analyzer

Command:

    flutter analyze --no-pub

- Invocation 1: FAIL with 24 same-class mechanical
  prefer_interpolation_to_compose_strings info lints; no compile or semantic
  error.
- Authorized mechanical retry after exact interpolation-only correction:
  PASS — No issues found.
- Analyzer invocation count: 2; retry count: 1 of 1.

### Source/drift gates

- git diff --check: PASS
- Exact correction/implementation path audit: PASS, 7/11 authorized paths
- Schema: 20, unchanged; database/migration drift: 0
- Backup format: 1, unchanged
- Mobile version: 0.1.0+1, unchanged
- MAIN package: com.faliardic.sefim, unchanged
- pubspec.yaml / pubspec.lock drift: 0
- Android/iOS/platform/permission/signing drift: 0
- READ_CALL_LOG / READ_CONTACTS / phone-state / call permission additions: 0
- Generated tracked artifact drift: 0
- Automatic Reminder/notification/Work Chain mutation added: 0
- Staged drift before publication: 0

## Manual smoke and publication boundary

- MT-520-001..005: PENDING; to be registered in Issue #479 during publication.
- Owner phone install / build authority: false; no artifact produced.
- Draft PR publication is authorized after commit/push.
- Ready=false, merge=false, Issue closure=false, Slice 5 start=false.
- Commit SHA, Draft PR URL, Issue/PR evidence URLs, and Manual Test Register URL
  are recorded in the GitHub publication comments because a commit cannot
  contain its own resulting SHA.

## Stabilization use

- Primary implementation window: 1 used.
- Same-scope corrections: 2 used (focused mechanical UI correction; analyzer
  interpolation-only correction), 1 remains.
- Environment-only recovery: 1 used, 0 remains.

## Handoff

execution_record:

    issue: 520
    parent_epic: 506
    base_sha: 1f92da6e330d69f9554db9e07d260919e77c20ea
    branch: codex/issue-520-inventory-destination-kroki-list
    schema: 20
    backup_format: 1
    mobile_version: 0.1.0+1
    focused: PASS 20/20 (invocations 2, retry 1)
    analyzer: PASS (invocations 2, retry 1)
    git_diff_check: PASS
    changed_paths: 7
    protected_drift: 0
    platform_permission_drift: 0
    draft_pr: pending publication
    manual_smoke_register: MT-520-001..005 PENDING; pending publication
    ready: false
    merged: false
    next_slice_started: false

review_recommendation:

    mode: GITHUB_REVIEW
    floor: gpt-5.6-sol/max
    recommendation: INDEPENDENT_R4_SOURCE_DIFF_FOCUSED_TEST_REVIEW

## Narrow R4 correction — review 5053677408

### Authority and baseline

- Correction authority: Issue #520 narrow R4 correction supplied by owner.
- Independent blocker review:
  `https://github.com/faliardic/chief-site-engineer/pull/521#pullrequestreview-5053677408`
- Additional analyzer retry authority:
  `https://github.com/faliardic/chief-site-engineer/issues/520#issuecomment-5456100417`
- Exact blocked HEAD: `81ed0b02ae4a63cfc1880b5bcf4e4b932dbba631`
- Branch: `codex/issue-520-inventory-destination-kroki-list`
- Remote divergence before correction publication: `0/0`
- Ruleset hashes recorded in the task remain unchanged.

### Exact correction paths

1. `mobile/lib/features/inventory/inventory_page.dart`
2. `mobile/lib/features/inventory/inventory_map_view.dart`
3. `mobile/test/inventory_page_test.dart`
4. `.cse/results/520_result.md`

No application/domain/storage/schema/migration/backup/bootstrap, attachment,
pubspec/lock, Android/iOS/platform/permission, package, or version path changed.
`app.dart`, `inventory_asset_core_test.dart`, and `widget_test.dart` were proven
unnecessary and remain unchanged.

### Corrected behavior

- The production `InventoryPage` now retains the exact
  `project_id + asset_id + InventoryAssetDetailController` identity while a
  real detail sheet transitions into move or unarchive target selection.
- Detail-sheet controllers remain alive across modal reverse transitions and
  are disposed only after the route-host widget has actually unmounted.
- During target selection, valid map taps call the exact detail controller's
  `previewMove` or `previewUnarchive`; marker and empty-map taps cannot open
  quick-create in this mode.
- A page-level cancel returns to the same detail without persistent mutation.
  A selected target returns to the same detail with the existing Slice-3
  confirmation action enabled.
- Existing `confirmMove` and `confirmUnarchive` mutation/domain/storage
  semantics remain unchanged and their existing canonical reload callback
  refreshes page/map truth after success.
- Active list rows preserve list-to-map exact focus. Archived list rows now
  deterministically open their exact archived detail for recoverable
  unarchive.
- The full canonical non-archived projection set is validated before
  search/filter presentation selection. Any invalid active projection clears
  the map snapshot, forces Liste-safe presentation, and exposes a typed
  diagnostic instead of rendering a partial healthy marker subset.
- Archived assets remain valid list-only records. Search/category/status/archive
  filtering remains presentation-only and mutation-free.

### Focused regression evidence

Command:

    flutter test --no-pub test/inventory_page_test.dart

- Invocation 1: FAIL at 11/12. Exact root cause: the new full-set map
  validation re-ran during a list-row focus diagnostic and replaced the more
  specific `inventory_active_placement_unavailable` code with the general
  projection-integrity code. Persistent mutation count remained zero.
- Narrow correction: fail-closed map state now preserves an already-recorded
  more-specific Liste diagnostic.
- Invocation 2: PASS, 12/12.
- A test-only null-aware collection lint was then corrected without changing
  production semantics.
- Final focused invocation 3: PASS, 12/12.
- Real production widget regressions cover:
  - marker -> real detail -> move -> map target -> enabled confirmation ->
    canonical reload;
  - move target cancel -> zero persistent mutation;
  - archived list row -> exact real archived detail -> unarchive -> map target
    -> enabled confirmation -> canonical reload;
  - move/unarchive target-mode map taps -> no `InventoryAssetQuickForm`;
  - one valid active projection plus one invalid active projection -> no
    partial marker subset, Liste-safe typed diagnostic, zero mutation.
- No injected `assetDetailLauncher` was used for the correction proofs.
- `inventory_asset_core_test.dart` was not touched and therefore was not added
  to the minimum focused command. `app.dart` was unchanged, so `widget_test.dart`
  was not run.

### Analyzer and source gates

Command:

    flutter analyze --no-pub

- Invocation 1: FAIL only on one test-only `use_null_aware_elements` info lint.
- Exact mechanical lint correction applied.
- The initial retry attempt was blocked before process creation because no
  additional analyzer authority was then available; it was not an analyzer
  invocation.
- Issue #520 comment `5456100417` granted exactly one additional invocation.
- Authorized analyzer invocation 2: PASS — `No issues found`.
- Touched Dart formatting: PASS, exact three Dart paths only.
- `git diff --check`: PASS.
- Exact correction allowlist: PASS, 4/5 authorized paths used.
- Schema: 20, unchanged; database/migration drift: 0.
- Backup format: 1, unchanged.
- Mobile version: 0.1.0+1, unchanged.
- `pubspec.yaml` / `pubspec.lock` drift: 0.
- Android/iOS/platform/permission/signing drift: 0.
- `READ_CALL_LOG`, `READ_CONTACTS`, phone-state/call permission additions: 0.
- Protected application/domain/bootstrap/storage drift: 0.
- Full suite, build, APK/AAB, emulator, ADB/device, scripted UI acceptance, and
  manual phone test cycle were not run.

### Manual test and publication boundary

- MT-520-001..005 remain PENDING; no manual test status was changed.
- No new phone test cycle was requested or run.
- Same-scope stabilization budget: final authorized correction used; 0 remains.
- Publication authority after all gates PASS: one minimal correction commit,
  normal push to the existing PR #521 branch, correction evidence comments.
- PR #521 must remain OPEN / DRAFT. Ready=false, merge=false, Issue
  closure=false, Slice 5 start=false.
- The correction commit SHA and GitHub evidence URLs are recorded in the
  publication comments because a commit cannot contain its own resulting SHA.

execution_record:

    issue: 520
    parent_epic: 506
    correction_review: 5053677408
    analyzer_retry_authority: 5456100417
    base_sha: 1f92da6e330d69f9554db9e07d260919e77c20ea
    blocked_head: 81ed0b02ae4a63cfc1880b5bcf4e4b932dbba631
    branch: codex/issue-520-inventory-destination-kroki-list
    runtime_model: unknown
    runtime_reasoning_effort: null
    focused: PASS 12/12 (final invocation 3)
    analyzer: PASS (actual invocations 2)
    git_diff_check: PASS
    correction_changed_paths: 4
    schema: 20
    backup_format: 1
    mobile_version: 0.1.0+1
    protected_drift: 0
    platform_permission_drift: 0
    manual_smoke: MT-520-001..005 PENDING
    draft_pr: 521
    ready: false
    merged: false
    next_slice_started: false

review_recommendation:

    mode: GITHUB_REVIEW
    floor: gpt-5.6-sol/max
    recommendation: FRESH_INDEPENDENT_R4_SOURCE_DIFF_FOCUSED_TEST_REREVIEW
