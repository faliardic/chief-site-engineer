# Issue #537 — Inventory autosave pending-command correction

## Scope and starting state

- Process lane: CRITICAL; concrete trigger: autosave integrity and stable identity.
- Authority: owner SAFE CONTINUATION plus explicit production-edit approval in
  this task; Issue #537 current-base comment 5505906105. Review floor: independent R4.
- Repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`;
  origin: `https://github.com/faliardic/chief-site-engineer.git`.
- Starting master: `89dffbe2b7caa44f50fb4426b5ebf9d1b5157dda`.
- Starting branch HEAD: `d8239455c641e93362e3be2dbfab21e5c52995cc`.
- Branch: `codex/issue-537-inventory-autosave-pending-correction`; target: `master`.
- Workspace routing: PASS. Tracked/index clean, no merge/rebase/cherry-pick/revert.
  Fetched only master and the required #537 branch, verified exact remote SHAs,
  then created the missing local tracking branch from that exact remote.
- Starting relation: master...HEAD `0 1`, exact parent/master match, committed
  delta only `.cse/tasks/537_task.md`; no pre-existing source/test delta.
- Prior #584 branch remains `438c51dd7e7d3700f0b32557ea81bd9c6a3c74d2`.
- First production edit was blocked by the approval guard without writing files;
  owner then explicitly approved this exact production/test/validation scope.
- Actual model: unknown. Actual reasoning effort: unknown.

## Exact total PR paths

1. `.cse/tasks/537_task.md` — existing task-start commit; read-only here.
2. `.cse/results/537_result.md` — this execution record.
3. `mobile/lib/features/inventory/inventory_sketch_editor_page.dart`.
4. `mobile/test/inventory_sketch_editor_test.dart`.

## Root cause and controller invariant

- A failed pending command outlived its geometry generation. Subsequent saves
  reused stale geometry, mappings, metadata and operation identity.
- A newer debounce could expire while an older save Future was running; its
  callback joined that Future. Returning immediately on the older failure lost
  the only wake-up for the newer eligible state.
- Pending reuse is now generation-aware. Same-generation failure retains the
  exact pending command. A newer generation discards only the obsolete pending
  reference before command selection, generating a fresh current-state command.
- Stale in-flight failure continues the same serialized loop, retaining force
  and debounce eligibility. A still-pending debounce remains scheduled; an
  already-eligible or forced generation drains immediately without a new edit.
- Success still verifies and acknowledges the exact submitted durable result;
  newer edits remain pending. Optimistic sketch/content revisions and receipts
  are unchanged; no cancellation, parallel drain, periodic retry or delayed rescue.

## Save-relevant state review

- Draw/close/reattach/nudge/delete flow through `_applyEditorAction`; history
  restores geometry, existing mappings, new block definitions and lifecycle state.
- Proven exceptional path: `recordRecoveredLifecycleChoice` can change captured
  lifecycle actions without changing geometry. Changed choices while work is
  pending now advance the existing generation; clean recovered choices stay local.
- Accepted action/history comparisons include save-relevant spatial fields, and
  acknowledgement comparison includes captured lifecycle actions so an older
  success cannot hide an unacknowledged newer choice.
- Selection, mode, preview, free-length toggle and identical lifecycle choices
  do not invalidate pending operation identity. No new state-version architecture.
- Initialize adopts a new baseline; discard explicitly clears pending work and
  restores the acknowledged spatial frame. Neither path was redesigned.

## Regression coverage in the candidate

- Existing same-generation failure/ack/retry/discard test is unchanged.
- Failed intermediate edit-active A + detached B: typed
  `inventory_legacy_geometry_immutable`, fresh current command, exact A/B mappings,
  original B floor IDs, no new/duplicate B, one durable autosave mutation, current
  acknowledgement and exact final reattach intent/current finalized geometry.
- Natural debounce lost-wakeup: first save gated, newer full 500 ms expires while
  it is blocked, old typed failure released, no rescue edit/force, one fresh save,
  saved state, no stale error, maximum concurrency 1, no redundant third save.
- Pending newer debounce: old failure does not accelerate or strand it; 499 + 1 ms.
- Forced current state: two gates prove the returned force Future waits for the
  successful current serialized save after stale failure.
- Lifecycle-only change: unchanged retry (including mode/selection changes) keeps
  operation ID, current save failure blocks finalization, changed choice refreshes
  identity, preserves new-block metadata and survives discard into finalize intent.

## Pre-validation candidate audit

- Touched Dart formatted before any Flutter invocation; complete source/test diff
  reviewed. Existing assertions preserved; five deterministic regressions added.
- Exact allowlist: PASS; task unchanged; protected drift: NONE.
- `git diff --check`: PASS.
- Schema / backup / mobile version: `22 / 1 / 0.1.0+1`.
- Source SHA-256: `39BB74B2BA1072B9E11CD2E8D2AE5F7F8174CC9D382E158C9ACE99A375C87E86`.
- Test SHA-256: `F850FAAE68F97D32E00FF05A6789876EE472C408E12290F779004E5FFE1FF4B6`.
- Task SHA-256: `F2888BBA5A79990A69FC39BA4FD08FF7F3FD2342D1850E6DA5B407A9F2C1318F`.

## Validation — authorized order, zero retries

Runner: `C:\Users\Fatih\.cache\flutter-sdk\3.44.6-ee80f08\flutter\bin\flutter.bat`.
Working directory: repository `mobile/`.

1. `flutter test --no-pub test/inventory_sketch_editor_test.dart`
   - Result: PASS; invocations: 1; tally: 54/54; exit: 0.
   - Terminal: `00:06 +54: All tests passed!`
2. `flutter test --no-pub test/inventory_geometry_test.dart test/inventory_application_test.dart test/inventory_asset_core_test.dart test/inventory_attachment_gateway_test.dart test/inventory_page_test.dart test/inventory_sketch_editor_test.dart test/inventory_schema_migration_test.dart test/app_bootstrap_test.dart test/widget_test.dart`
   - Result: PASS; invocations: 1; tally: 192/192; exit: 0.
   - Terminal: `00:17 +192: All tests passed!`
3. `flutter analyze --no-pub`
   - Result: PASS; invocations: 1; exit: 0.
   - Terminal: `No issues found! (ran in 59.0s)`

## Verified outcomes and final audit

- Same-generation retry / unchanged operation ID: PASS.
- Completed failed generation replaced by fresh current command: PASS.
- In-flight stale-failure natural-debounce wake-up: PASS.
- Still-pending debounce and forced current Future outcome: PASS.
- Exact reattach block/floor identity and current finalized geometry: PASS.
- Maximum concurrent saves: 1; no redundant third save or timer exception.
- Lifecycle-only pending state refresh and current-failure finalize block: PASS.
- Existing undo/redo, recovery, stale revision and orientation tests: PASS.
- `git diff --check`: PASS. Total PR path set: exact four-path allowlist.
- Protected drift: NONE, including application/domain/storage/schema/backup,
  pubspec/lock, platform/package/permissions and all other feature source/tests.
- Schema / backup / mobile version: `22 / 1 / 0.1.0+1`, unchanged.
- Source, test and task SHA-256 values still match the pre-validation values;
  no source/test edit occurred after the passing invocations.
- Only this documentation result record was finalized after validation.
- No generated DB/backup/APK/AAB/coverage or unrelated path is in the change set.
- Staged-path audit and final commit/push/PR identities are recorded in publication
  evidence after the single implementation commit; task file is not staged again.

## Publication boundary

- Complete local validation: PASS. One implementation/evidence commit, normal
  push and one Draft PR to master are authorized; publication follows this record.
- Final commit SHA will be recorded in post-commit Issue/PR evidence, avoiding a
  self-referential evidence commit.
- Independent R4: pending. Ready: false; merged: false; Issue closure: false.
- PR #536 remains protected: observed OPEN/DRAFT at
  `7f113fdd111bc0b668b29e2a62ca688cbe1f4590`; no writes to that PR/branch.
- `MT-535-001..007`: PENDING / NOT RUN, Issue #479 comment 5464443462.
- Device acceptance not resumed; prior acceptance evidence is not reclassified.
- Not run: baseline/full suite, build/APK/AAB, emulator/device/ADB, MAIN/package
  operations, owner data access, release gate, #556/#586, orientation/UI changes.

## Correction — unverified durable autosave receipt

This section records a fresh correction after the implementation above. The
54/54, 192/192 and 59.0s analyzer results remain historical evidence for
`9d730fdfc61421efa57c902a8f9910034c3ffee9`, not validation of this correction.

### Authority and preflight

- Authority: owner-provided explicit controller-local correction instruction for
  Issue #537 / Draft PR #587; update existing Draft PR only; independent R4.
- Process lane remains CRITICAL: receipt reconciliation and autosave integrity.
- Starting HEAD: `9d730fdfc61421efa57c902a8f9910034c3ffee9`.
- Master/base: `89dffbe2b7caa44f50fb4426b5ebf9d1b5157dda`.
- Branch: `codex/issue-537-inventory-autosave-pending-correction`.
- Clean tracked worktree/index, no in-progress Git operation; fetched only the
  required master/#537 refs; exact remote SHAs and local HEAD matched.
- Existing PR #587 verified OPEN/DRAFT, target master, two commits/four paths.
- Existing four-path total PR allowlist remains unchanged. This correction edits
  only controller, its test file and this result file.
- Task is read-only; blob verified `3ed74c604ccbd247b84afcf46d09e5ee4f8475c4`.
- No baseline Flutter invocation. Ruleset hashes unchanged.
- Actual model: unknown; actual reasoning effort: unknown.

### Blocker and narrow correction

- The original broad catch could discard an older command after the mutation
  returned a durable result but the following read/verification failed. A fresh
  command then used unverified local revisions and could become stuck on retries.
- `_PendingDraftSave.mutationResultObserved` is now set immediately after a
  mutation result returns, before any projection read/verification.
- Both stale-generation discard paths exclude result-observed pending work.
  Verification/read failures preserve its exact command/operation ID, expose the
  truthful error and return false without issuing a stale-revision current save.
- Explicit force replays that exact receipt identity, verifies/adopts the durable
  draft and revisions, acknowledges only that submitted generation, then drains
  the current state with a fresh operation and the verified revisions.
- The flag stays on the same pending object through retries (including a replay
  failure). Verified acknowledgement, explicit discard and projection adoption
  already remove that object; no separate controller flag can leak across drafts.
- Genuine pre-result stale failures still use the previous serialized
  debounce/force continuation. No new drain, timer, delayed recovery or retry loop.

### One added deterministic regression

`durable older result survives transient verification load failure before fresh current save`

- Empty draft; normal 500ms starts gated N; N+1's full debounce expires while N
  is blocked; only then a one-shot `failLoadCount` is armed and N is released.
- Before force: one submitted command/one durable mutation, advanced durable
  projection but unchanged local acknowledgement/revisions, truthful failed state,
  no N+1 submission with stale revisions and no finalize.
- One force request: gated replay verification proves the same old command object,
  operation ID/intent and no duplicate mutation; a separate current-save gate
  proves old-state acknowledgement and revision adoption before N+1 completes.
- Fresh N+1 command uses N's verified sketch revision, content revision and draft
  ID. Force completes only after current acknowledgement; total mutations two,
  concurrency one, no fourth command after a further debounce or async exception.
- All previous 54 tests and their assertions are unchanged; fake application
  implementation is unchanged. Expected new tallies: 55 focused / 193 integrated.

### Correction pre-validation audit

- Two touched Dart files formatted; complete source/test diff reviewed.
- Source diff: 11 additions / 4 deletions, only phase tracking and discard guards.
- Test diff: exactly one added test, 146 additions / 0 deletions.
- Task blob unchanged; exact allowlist PASS; protected drift NONE.
- `git diff --check`: PASS. Schema / backup / version: `22 / 1 / 0.1.0+1`.
- Source SHA-256: `3A198DB0D2F390ED641A178A3E1BF571EECB40B1CC71268DA7D2D641DD720BDA`.
- Test SHA-256: `E0337C564C06EACDAA1E188FD05F497ADB0BE12321BD98B296F91F8028D6798D`.

### Fresh correction validation — one invocation per gate, zero retries

Same exact Flutter runner and `mobile/` working directory as recorded above.

1. `flutter test --no-pub test/inventory_sketch_editor_test.dart`
   - Correction result: PASS; invocation count: 1; tally: 55/55; exit: 0.
   - Exact terminal: `00:05 +55: All tests passed!`
2. `flutter test --no-pub test/inventory_geometry_test.dart test/inventory_application_test.dart test/inventory_asset_core_test.dart test/inventory_attachment_gateway_test.dart test/inventory_page_test.dart test/inventory_sketch_editor_test.dart test/inventory_schema_migration_test.dart test/app_bootstrap_test.dart test/widget_test.dart`
   - Correction result: PASS; invocation count: 1; tally: 193/193; exit: 0.
   - Exact terminal: `00:15 +193: All tests passed!`
3. `flutter analyze --no-pub`
   - Correction result: PASS; invocation count: 1; exit: 0.
   - Exact terminal: `No issues found! (ran in 36.0s)`

### Correction verified outcomes and final audit

- Post-result verification identity preserved: PASS.
- Exact old receipt replay verified without another old-state mutation: PASS.
- Fresh current generation uses reconciled draft/revisions: PASS.
- Same-generation retry and genuine pre-result lost-wakeup correction: PASS.
- Maximum concurrent saves: 1. New test durable mutations: exactly 2 (N and N+1).
- All 54 previous focused tests plus exactly one new regression: 55/55 PASS.
- Integrated tally matches expected 193/193. Retry count: 0 for all three gates.
- `git diff --check`: PASS; correction paths exactly controller/test/result;
  total PR paths still the same four; protected drift NONE.
- Task blob remains `3ed74c604ccbd247b84afcf46d09e5ee4f8475c4`.
- Schema / backup / version remain `22 / 1 / 0.1.0+1`.
- New source/test SHA-256 values above were rechecked after validation and match;
  no post-validation source/test change. Only this result documentation finalized.
- No generated or unrelated artifact in the change set. Exact staged scope is
  checked before the one correction commit and reported in publication evidence.
- Fresh independent R4 re-review remains pending; no device/manual acceptance.

### Correction publication boundary

- Complete fresh PASS achieved. One correction commit and normal push to the
  existing branch follow this record; no new branch/PR, amendment, rebase or merge.
- Exact final SHA and publication audit belong in Issue #537 / PR #587 evidence
  after commit, avoiding a self-referential evidence commit.
- PR stays Draft; Ready=false; merged=false; independent R4 re-review required.
- No full suite/build/APK/AAB/device/ADB/release or owner-data operations.
- No UI/orientation/application/domain/storage/schema/backup/#556/#586 changes.
- Manual/device acceptance remains unresumed; MT-535-001..007 PENDING / NOT RUN.
