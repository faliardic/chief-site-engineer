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
