# Issue #659 — Project Profile / Home Task

## Authority and start state

- Issue: `#659` (`UXF-020 — Project Profile / Home persistent visual transformation`)
- Parent: `#617`
- Exact base: `6c2e8a5021315ecfebd35aa05947a9a264e192b7`
- Branch: `codex/issue-659-project-profile-home`
- Lane: `CRITICAL` — additive schema/persistence, backup compatibility, transaction history, and visible Home transformation
- Initial implementation time budget: 120 minutes; previous correction time budget: 45 minutes; final six-file correction time budget: 60 minutes

Resume the preserved implementation on the authorized branch without reset/restart. Local HEAD remains at the exact execution base. On the owner-directed resume, GitHub master is `450febd1e55277dbce4c3cacc877c2ffa4f0d69c`, one AGENTS.md-only narration commit ahead; its current rule was read remotely without changing branch source. Unexpected changes, base drift, a seventh newly authorized test path (22nd total path), correction beyond the authorized test-only contracts, destructive migration, backup-format change, real-user/device mutation, or project isolation failure are stop conditions.

## Objective

Implement the owner-locked selected Project Profile as Home and the smallest real persistence contract required for:

1. fixed `Toplam kat`, `Toplam alan`, and `YİBF No` rows;
2. arbitrary custom text label/value rows;
3. tap edit, recoverable custom archive/restore, and drag reorder;
4. project-scoped optimistic revisions, atomic transactions, and append-only events;
5. side-effect-free default reads with transactional first materialization;
6. exact active-project isolation; and
7. format-1 backup/restore of values, order, stable identity, archive state, and history.

`projects.name` remains the only project-name source and the fixed profile header. Home removes the old Dashboard summaries and action tiles, retaining one compact `Araçlar` entry for already-wired actions. The New Project form and protected `mobile/lib/app.dart` remain unchanged.

## Exact write allowlist

1. `mobile/lib/storage/app_database.dart`
2. `mobile/lib/domain/agenda_models.dart`
3. `mobile/lib/application/agenda_application.dart`
4. `mobile/lib/features/dashboard/project_dashboard_page.dart`
5. `mobile/test/app_database_test.dart`
6. `mobile/test/agenda_application_test.dart`
7. `mobile/test/project_dashboard_widget_test.dart`
8. `mobile/test/widget_test.dart`
9. `mobile/test/mobile_backup_application_test.dart`
10. `mobile/test/support/fake_agenda_application.dart`
11. `.cse/tasks/659_task.md`
12. `.cse/results/659_result.md`

13. `mobile/test/platform_notification_configuration_test.dart` — current schema literal `18 -> 23` only.
14. `mobile/test/global_active_project_context_widget_test.dart` — superseded Home/Profile/Araçlar navigation plus owner-authorized existing Agenda filter-panel navigation; preserve all session/isolation/capture/failure/filter assertions.
15. `mobile/test/project_context_bidirectional_widget_test.dart` — same narrow navigation correction, including revealing the existing phone option before tapping; preserve context/mutation assertions.

16. `mobile/test/agenda_page_test.dart`
17. `mobile/test/inventory_schema_migration_test.dart`
18. `mobile/test/living_plan_widget_test.dart`
19. `mobile/test/mobile_backup_widget_test.dart`
20. `mobile/test/project_context_core_routes_widget_test.dart`
21. `mobile/test/workforce_directory_widget_test.dart`

Final owner authority: https://github.com/faliardic/chief-site-engineer/issues/659#issuecomment-5549144383
The six paths at 16–21 were copied from the 1072 PASS / 10 FAIL result record
before editing. This final correction permits changes only in these six tests:
current panel/tool navigation, revealing existing options, and stale current-schema
expectations. Existing assertions remain materially equivalent; no deletion,
skipping, product edit or seventh new path is permitted. Previously authorized
implementation remains preserved. No reset, clean, stash, rebase or restart.

## Persistence and compatibility contract

- `AppDatabase.schemaVersion`: `22 -> 23`; migration is additive only.
- Backup format remains exact `1`.
- Existing project IDs, names, revisions, archive state, and unrelated rows remain byte/value-equivalent through migration.
- Built-in labels and identities are fixed and non-archiveable; custom identities survive every lifecycle transition.
- No physical delete; profile events are append-only.
- Reorder carries the exact active field set and expected revisions in one transaction; failure preserves the prior order, revisions, and event history.
- Reads never create source rows. First edit/create/reorder may materialize the three built-ins inside the mutation transaction.

## Routing and publication contract

```yaml
routing:
  lane: CRITICAL
  task_shape: schema_persistence_backup_and_visible_home
  reasoning_target: extra_high
  independent_review_required: true
  manual_acceptance_required: true
  ready_merge_owner_gated: true
```

After every automated gate passes, publish one normal commit and branch push, then open one Draft PR to `master` containing `Closes #659` and `Refs #617`. Keep the PR Draft while Fatih manual Acceptance is `PENDING`; Ready/merge requires independent review and every Issue gate.

## Required validation

- schema 22→23 migration preservation and failed-migration rollback
- FK/integrity, stable identity, append-only history, and no-physical-delete invariants
- application default read, built-in edit, custom create/edit/archive/restore, deterministic reorder, stale rejection, project isolation, event history, and transaction rollback
- Home-only Project Profile, tap edit, custom add/archive, drag reorder, compact `Araçlar`, old-Dashboard absence, and exact active-project switch
- format-1 backup/restore round-trip with rows, values, order, archive state, stable IDs, and events
- affected suites, full mobile suite, material analyzer, formatting, exact allowlist/protected drift, and `git diff --check`

No APK or device execution is required for automated completion. Manual isolated Acceptance remains pending after the Draft PR is opened.

## Final correction execution order

Run only the six newly authorized test files first; reuse unchanged individual
PASS results if an in-scope helper correction is necessary. After all six files
PASS, run the full mobile suite exactly once. Reuse earlier focused/analyzer
PASS because production source is unchanged. Check touched-test format, exact
21-path scope, protected drift and diff whitespace. Before publication compare
with current master, require no conflict/unintended path drift, and verify the
Draft PR is mergeable. All automated gates must PASS before commit/push/Draft
PR. Manual Acceptance remains PENDING; Ready/merge requires independent review
and Fatih manual PASS. No APK/device work is part of this correction.
