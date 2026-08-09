# Issue #398 — Mahal Kataloğu management UI

- Issue: `#398`
- Base: `origin/master` / `227e77bbca3187b6bc5bf16afd608c025bf06158`
- Branch: `codex/issue-398-v2-1d-location-catalog-ui`
- Worktree: `C:\\Users\\Fatih\\AppData\\Local\\CSE-Worktrees\\issue-398`
- Validation class: `UI + application integration`
- Changed contracts: optional typed ProjectLocation dependency wiring; Agenda catalog entry; active-project selector; active/archived hierarchical catalog; create/rename/reparent/archive/restore UI; safe loading/empty/error/retry, stream refresh, busy protection, accessibility and compact layout.
- Preferred allowlist: `.cse/tasks/398_task.md`, `.cse/results/398_result.md`, `mobile/lib/bootstrap/app_bootstrap.dart`, `mobile/lib/app.dart`, `mobile/lib/features/agenda/agenda_page.dart`, new `mobile/lib/features/agenda/project_location_catalog_page.dart`, new `mobile/test/project_location_catalog_widget_test.dart`.
- Conditional regression files: existing Agenda/bootstrap/app widget tests only when constructor wiring requires narrow evidence.
- Required validation: focused catalog widget tests; affected Agenda widget tests; relevant ProjectLocation application tests; full `flutter test --no-pub`; `flutter analyze --no-pub`; `git diff --check`; `flutter build apk --debug`.
- Physical device smoke: replace-install preserving existing data only; no uninstall/data clear; launch; Ajanda → Mahal Kataloğu; existing project selector, active/archive filter, and back navigation only; no real-data mutation.
- Reused evidence: merged schema-11 ProjectLocation persistence/application and V2.1c project lifecycle active-project contract.
- Retry budget: one correction attempt for the same failed technical step.
- Time budget: 30-minute target, 45-minute hard stop.
- Explicitly out of scope: free-text LogForm change; Agenda/Reminder/Concrete `location_id` adoption; project lifecycle UI; schema/migration/trigger/index/backup changes; `app_database.dart` or `agenda_application.dart` semantics; attendance/concrete production; state file; destructive device operation.
- Stop on any requirement to cross those boundaries.
- Publication: commit/push only after every authorized local/device gate passes; Draft PR required; no Ready, merge, or V2.1e start.
