# Issue #659 — Project Profile / Home Result

## Current result

**AUTOMATED PASS — manual Acceptance and independent review PENDING.**

The final six-file compatibility correction passes all 48 tests in those files.
The full mobile suite was then run exactly once: **1082 PASS / 0 FAIL**, exit 0,
test-runner elapsed time 01:24. The preserved implementation may be committed,
pushed normally and opened as a Draft PR. Ready/merge remains blocked pending
independent review and Fatih's isolated Acceptance PASS.

## Authority and preserved source

- Issue #659; parent #617; CRITICAL persistence and visible Home transformation.
- Branch: `codex/issue-659-project-profile-home`.
- Preserved implementation base: `6c2e8a5021315ecfebd35aa05947a9a264e192b7`.
- Current master: `450febd1e55277dbce4c3cacc877c2ffa4f0d69c`; only the
  acknowledged AGENTS.md narration-rule change is ahead of the original base.
  Its current rule was read without altering branch source.
- Final owner authority:
  https://github.com/faliardic/chief-site-engineer/issues/659#issuecomment-5549144383
- Final correction budget: 60 minutes. No reset, clean, stash, rebase or restart.

## Exact six newly writable paths

Copied into this result record before any final-round test edits from its
previous **1072 PASS / 10 FAIL** section:

1. `mobile/test/agenda_page_test.dart`
2. `mobile/test/inventory_schema_migration_test.dart`
3. `mobile/test/living_plan_widget_test.dart`
4. `mobile/test/mobile_backup_widget_test.dart`
5. `mobile/test/project_context_core_routes_widget_test.dart`
6. `mobile/test/workforce_directory_widget_test.dart`

The total authorized change set is the original revised 15 plus these six:
**21 paths**, including task/result provenance. No seventh new path was touched.

## Preserved implementation

Additive schema 22 -> 23 stores Project Profile fields and append-only events;
backup format remains exact 1. Project name remains solely in `projects.name`.
Built-in values and custom text fields persist with stable identity, optimistic
revision, recoverable archive/restore, transactional reorder and project
isolation. Home shows the selected Project Profile and compact Araçlar entry.
New Project and protected `mobile/lib/app.dart` remain unchanged from the base.

## Final test-only changes and assertion preservation

- Agenda opens and cancels the existing filter panel to inspect project state.
  The preceding dialog finishes closing before tapping. Deliberately pending
  fresh/stale reads, exact selected project, query counts, stale-result rejection
  and rendering assertions are retained.
- Plan, core routes and Workforce enter through Project Profile -> Araçlar;
  core routes select the project through the shared project control. Options
  are revealed and confirmed hit-testable before taps. Existing destination,
  exact-project, isolation, session and mutation assertions are retained.
- Backup reveals the existing picker for both selections. Picker-cancel and
  abandoned-import disposal assertions remain unchanged.
- Inventory current-schema expectations alone move 22 -> 23. Historical
  migration/rollback version 20/21/22 checks remain. The schema-19 preservation
  comparison separately identifies the exact nine newly authorized Profile
  schema objects; every pre-existing non-Inventory object's SQL and all prior
  representative rows remain exactly equal. Inventory graph, identity, FK,
  integrity, append-only, no-physical-delete and rollback assertions remain.
- Test counts are unchanged: Agenda 1, Inventory 9, Plan 16, Backup 5,
  core routes 7, Workforce 7. No test was removed or skipped in this correction.
  All prior assertions are verbatim except six Inventory current-version
  expectations; additional visibility/schema-object assertions were added.
- Every pre-existing tracked mobile file outside these six matches its
  pre-correction byte hash, including all production sources and prior tests.

## Executed validation

From `mobile`:

```text
flutter test --no-pub test/agenda_page_test.dart test/inventory_schema_migration_test.dart test/living_plan_widget_test.dart test/mobile_backup_widget_test.dart test/project_context_core_routes_widget_test.dart test/workforce_directory_widget_test.dart --reporter expanded
```

First six-file result: 47 PASS / 1 FAIL. Agenda's filter tap was blocked by the
closing project-create dialog. After the narrow transition-wait correction:

```text
flutter test --no-pub test/agenda_page_test.dart --reporter expanded
```

Result: 1 PASS; the other 47 unchanged PASS results were reused. All six files
were therefore PASS before the single full-suite run:

```text
flutter test --no-pub --reporter expanded
```

Result: **1082 PASS / 0 FAIL**, exit 0, elapsed 01:24. No second full-suite run.

## Reused prior evidence

No additional production change was made during test-only corrections, so the
prior focused/analyzer PASS gates were not rerun separately:

- Home 6/6; shell 19/19; database migration/integrity/rollback 27/27.
- Application persistence/transaction/revision 36/36; format-1 backup/restore 40/40.
- Combined database/application/Home 69/69; responsive shell 3/3.
- Material analyzer PASS, no issues found.

Historical full-suite results were 1066 PASS / 16 FAIL and 1072 PASS / 10 FAIL.
The latter consisted of five Inventory failures plus one in each of the other
five newly authorized files. All are resolved by the final full-suite PASS.

## Static checks and publication boundary

- Touched-test format and `git diff --check`: PASS.
- Full authorized-path review: exact 21/21; no extra path.
- Protected drift: PASS; all tracked mobile files outside the six unchanged.
- `mobile/lib/app.dart`: zero diff from the implementation base/current master.
- Current-master movement: only acknowledged AGENTS.md change, disjoint from
  all authorized paths; branch source was not reset or rebased.
- Authorized output: normal commit/push and one mergeable Draft PR to master.
  Exact commit and PR identities are recorded by GitHub publication metadata.
- PR disposition: `Closes #659`, `Refs #617`.
- Manual Acceptance: **PENDING**. Independent deep review: **PENDING**.
- No APK build/install, device execution, MAIN/debug mutation, user-data access,
  Ready or merge was performed during this correction.
