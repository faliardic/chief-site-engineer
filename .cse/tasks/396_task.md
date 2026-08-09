# Issue #396 — Project rename/archive/restore lifecycle

- Issue: `#396`
- Base: `origin/master` / `9cf3466ef92047f49d99881c27d8ab34311dcf89`
- Branch: `codex/issue-396-v2-1c-project-lifecycle`
- Worktree: `C:\\Users\\Fatih\\AppData\\Local\\CSE-Worktrees\\issue-396`
- Validation class: `application + persistence`
- Changed contracts: stable-ID project get; active/archived lifecycle listing; rename/archive/restore with optimistic revision, atomic append-only events, no-op semantics, and one post-commit `projectChanges` signal; child-data preservation.
- Allowed production files: `mobile/lib/domain/agenda_models.dart`, `mobile/lib/application/agenda_application.dart`.
- Preferred test file: `mobile/test/project_lifecycle_application_test.dart`.
- Conditional regression files: `mobile/test/support/fake_agenda_application.dart`, `mobile/test/agenda_application_test.dart` only if compilation or narrow active-only evidence requires them.
- Required validation: focused lifecycle tests; existing Agenda application tests; full `flutter test --no-pub`; `flutter analyze --no-pub`; `git diff --check`.
- Reused evidence: schema 11 project/project-location/event tables and triggers from merged V2.1a; Project/Location application contract and existing active-project enforcement from merged V2.1b.
- Physical device acceptance: none; no UI/platform behavior changes.
- Retry budget: one correction attempt for the same failed technical step.
- Time budget: 30-minute target, 45-minute hard stop.
- Explicitly out of scope: schema/migration/index/trigger changes; database, backup, attendance/concrete application, feature/UI/navigation, state-file changes; child bulk mutation; project deletion; free-text/location-link adoption.
- Publication: commit and push only after all authorized local gates pass; Draft PR required; no Ready, merge, or automatic V2.1d start.
