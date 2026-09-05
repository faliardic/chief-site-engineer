# Issue #659 — Project Profile / Home Result

## Current result — independent-review correction

**AUTOMATED PASS — independent re-review and manual Acceptance PENDING.**

The fixed Project Profile name header is now tap-to-edit. It calls the existing
`ProjectLifecycleApplication.renameProject` using the displayed project revision
and a fresh event ID. The canonical name remains solely in `projects.name`.
Only a successful returned project updates the header; failure preserves the
previous name and displays a safe message. Project selection is never changed
by the rename operation, including if another project is selected while it runs.

Fresh gates after this production change: **Home 10/10 + lifecycle 8/8 PASS**,
**analyzer PASS**, then one **full mobile suite 1086/1086 PASS**, exit 0.
This supersedes the prior 1082-test full-suite result for publication.

## Authority and source

- PR #661, branch `codex/issue-659-project-profile-home`; parent #617.
- Correction start: `13f1b26f75b7aa9f385aa32cc83c2527e9af78da`.
- Original implementation base: `6c2e8a5021315ecfebd35aa05947a9a264e192b7`.
- Current master: `450febd1e55277dbce4c3cacc877c2ffa4f0d69c`; only the
  acknowledged AGENTS.md narration change is ahead of the original base.
- Authority:
  https://github.com/faliardic/chief-site-engineer/issues/659#issuecomment-5549220260
- Execution time budget: 45 minutes. No reset, clean, stash or rebase.

## Exact correction paths

1. `mobile/lib/features/dashboard/project_dashboard_page.dart`
2. `mobile/test/project_dashboard_widget_test.dart`
3. `.cse/tasks/659_task.md`
4. `.cse/results/659_result.md`

All are already authorized #659 paths. The aggregate PR remains the exact
21-path change set. No new path, shared fake change, schema/migration change,
backup change or `mobile/lib/app.dart` change was required.

## Behavior and coverage

The header uses the existing owned text-entry dialog with a 160-character limit,
required trimmed name and explicit save/cancel. The name remains a fixed header,
not a reorderable row or duplicated profile metadata. The existing mutation guard
prevents overlapping writes. The lifecycle port owns revision checking, durable
project update and append-only project events; no new persistence path is added.

Added Home tests verify:
- tap name -> rename -> returned canonical name is visible;
- actual current revisions (7 then 8) and distinct new UUID event IDs;
- the same selected project and unchanged other-project record;
- no change to the existing profile fields or profile events;
- the renamed name remains visible after unmounting and reopening Home;
- stale revision and synthetic failure preserve the old name/selection and show
  understandable errors, with no applied rename;
- a pending rename updates its original project without retargeting a later
  selection or replacing that selected project's visible profile.

The local Home fake tests the UI contract. The unchanged real SQLite lifecycle
suite separately verifies durable rename, revision/event payload, child identity,
exact no-op, collision/archive rejection and transactional rollback behavior.

## Fresh executed validation

From `mobile`:

```text
flutter test --no-pub test/project_dashboard_widget_test.dart test/project_lifecycle_application_test.dart --reporter expanded
```

Initial result: 15 PASS / 3 FAIL. The three new tests incorrectly expected an
empty fake profile cache, although the existing fake synthesizes/caches built-ins
on reads. Their assertions were corrected to compare the complete pre-rename
field set exactly, preserving the intended no-duplicate/no-mutation check.
Production source did not change during that test correction.

```text
flutter test --no-pub test/project_dashboard_widget_test.dart --name '^project name ' --reporter expanded
```

Result: 3 PASS; the other 15 unchanged PASS results were reused. Focused gate is
therefore Home 10/10 + lifecycle 8/8 PASS, with no existing test removed/skipped.

```text
flutter analyze --no-pub
```

PASS, no issues found, 44.9 seconds. This is fresh analyzer evidence.

```text
flutter test --no-pub --reporter expanded
```

Run exactly once after focused/analyzer PASS: **1086 PASS / 0 FAIL**, exit 0,
test-runner elapsed time 01:29. No second full-suite run was attempted.

## Preserved implementation and prior compatibility scope

The existing schema 22 -> 23 profile rows/events, optimistic field mutations,
atomic reorder, archive/restore, project isolation and format-1 backup design are
unchanged. Earlier focused persistence gates and the prior full 1082 PASS remain
historical evidence; the new full suite includes their regressions again.

The previous 1072 PASS / 10 FAIL section authorized exactly these six additional
compatibility files; all six are byte-unchanged in this rename correction:

1. `mobile/test/agenda_page_test.dart`
2. `mobile/test/inventory_schema_migration_test.dart`
3. `mobile/test/living_plan_widget_test.dart`
4. `mobile/test/mobile_backup_widget_test.dart`
5. `mobile/test/project_context_core_routes_widget_test.dart`
6. `mobile/test/workforce_directory_widget_test.dart`

## Static checks and publication boundary

- Touched source/test format and `git diff --check`: PASS.
- Exact correction scope: 4 existing paths; aggregate PR scope: 21/21.
- Every tracked mobile file except the Home source/test matches its pre-correction
  byte hash; schema, backup, app.dart and final six compatibility tests are intact.
- Current-master conflict/mergeability and exact PR-path checks remain required
  before/after normal publication to the same Draft PR #661.
- PR disposition remains `Closes #659`, `Refs #617`.
- Independent re-review: **PENDING**; previous review's rename blocker is fixed
  in source but reviewer acceptance is not asserted by this execution.
- Manual Acceptance: **PENDING**. Keep Draft; no Ready/merge or Issue closure.
- No APK/device execution, MAIN/debug mutation or real-user-data access.


## Owner Home UI refinement result — 2026-09-05

Applied the header placement and three-column grid from the latest owner UI
comment (authority and exact boundary recorded in the task). New Project uses
the existing callback, Tools uses the unchanged sheet, and the bottom Tools
card is removed. Name and value previews ellipsize; custom fields extend down
without a count cap. Custom archive is reached through its edit dialog.
Grid drag/drop invokes the unchanged revisioned reorder command; drag targets
reject another project's field, and screen-edge auto-scroll supports later rows.

Validation on the final source:
- Focused Home + shell + global active-project + bidirectional context widget
  files together: **46 PASS / 0 FAIL** (11 seconds test execution).
- New coverage: 320/390 px at 2x text, action order/48 px targets/tooltips,
  long values, 25 custom fields plus another added field, isolation on switching,
  real pointer reorder across rows, automatic edge scrolling and order on reload.
- Existing create cancel/failure/retry assertions now exercise the direct header
  entry; all existing rename, session, mutation and route assertions remain.
- Touched Dart analyzer: **PASS**, no issues. Format: **PASS**.
- During development, the new edge-scroll test initially sent only the movement
  that starts a drag; adding the subsequent pointer movement fixed the test.
  A lint was also fixed before the final combined PASS run; neither assertion
  weakening nor persistence edits were needed.
- Full mobile suite was not repeated for this presentation correction under the
  latest owner materially-affected-validation authority. The earlier 1086 PASS
  run belongs to head 097ecff and is not claimed as a fresh full-suite result.
- Correction scope: 5 existing authorized paths; aggregate PR scope: 21/21.
  All other tracked files, including app.dart, schema, application/domain,
  backup and the six compatibility files, remain unchanged from resume head.
- Manual Acceptance and independent review of this refinement: **PENDING**.
  Same PR #661 remains Draft; no Ready/merge, APK/device or real-data operation.
  The previously delivered 097ecff APK does not contain this refinement.
