# Issue #413 — V2.2d subcontractor-first Puantaj roster flow

- Issue: `#413`
- Parent V2.2: `#204`
- Parent Epic: `#385`
- Foundations: `#407` / PR `#408`, `#409` / PR `#410`, `#411` / PR `#412`
- Official repository: `V:\\1_PROJECTS\\2_ACTIVE\\Python\\chief-site-engineer`
- Linked worktree: `C:\\Users\\Fatih\\AppData\\Local\\CSE-Worktrees\\issue-413`
- Exact base: `origin/master` / `9907291ab7d771f7d96475b225c8df38d2c7377c`
- Branch: `codex/issue-413-v2-2d-puantaj-roster-flow`
- Codex model: current strongest full Codex model
- Reasoning: `Extra High`; the change combines attendance roster mutation,
  canonical person identity, archived-history safety, inline Sicil creation,
  optimistic revision/event behavior and physical field UX.
- Validation class: canonical attendance workflow + multi-surface UI/lifecycle
  (`domain` with the broad Flutter gates explicitly required by the Issue).

## Changed contracts

- Replace the broad all-person roster candidate list with project-scoped,
  subcontractor-first active canonical member selection.
- Preserve every existing selected/historical attendance entry when filters
  change; archived members remain historical-only candidates.
- Add `+ Yeni eleman` through the existing canonical
  `CreateWorkforceMemberCommand` contract with current project, selected
  subcontractor and an active team.
- Keep the new person as a Sicil record even if the roster is not saved; create
  the attendance entry only through the existing roster save action.
- Show the required non-blocking SGK/İSG/OSGB reminder without producing a
  legal/compliance decision or record.
- Preserve stable `workforce_members.id`, same-project/active validation,
  revision/event and day-transition semantics.

## Authorized paths

- `mobile/lib/features/attendance/attendance_day_page.dart`
- `mobile/lib/features/attendance/workforce_page.dart` only if inline form
  reuse or preselection is proven necessary
- `mobile/lib/features/attendance/workforce_person_detail_page.dart` only if a
  canonical `Sicilde aç` action is proven necessary
- `mobile/lib/application/attendance_application.dart` only if a narrow query
  or orchestration need is proven
- `mobile/lib/domain/attendance_models.dart` only if a new read/UI contract is
  proven necessary
- `mobile/test/attendance_widget_test.dart`
- `mobile/test/attendance_application_test.dart`
- `mobile/test/attendance_roster_selector_widget_test.dart`
- `.cse/tasks/413_task.md`
- `.cse/results/413_result.md`

An allowlist-external static/navigation regression literal is not edited
without a new exact GitHub authorization.

## Protected contracts and out of scope

- `mobile/lib/storage/app_database.dart`, schema and migrations do not change;
  schema remains `12`.
- Backup/restore production and format do not change; backup format remains
  `1`.
- No parallel/global person identity, fuzzy duplicate merge, historical label
  snapshot, compliance/KKD redesign or workforce attachment expansion.
- No Sicil first-level navigation redesign, Ajanda/İş person adoption,
  release/signing/workflow/toolchain change, V2.2e closure or V2.3 work.
- No real user data inspection or Codex mutation; no uninstall, clear-data or
  destructive restore.

## Focused validation

- Attendance application coverage for canonical active/same-project roster,
  archived history/restore, exact stable member IDs, duplicate prevention,
  stale revision and unchanged roster/day mutations.
- Roster-selector widget coverage for subcontractor/team scoping, candidate
  summaries, selected-row preservation, inline creation, zero-active-team
  fail-closed behavior, pre-save non-persistence, exact roster save,
  double-submit and the non-legal warning.
- Existing attendance/lifecycle/navigation regressions.

## Broad validation

- Final `git diff --check` and exact allowlist/protected-path checks.
- One full `flutter test --no-pub` on the final source revision.
- `flutter analyze --no-pub`.
- One `flutter build apk --debug` on the final source revision.
- After all local gates pass: exactly one authorized physical Android device,
  replace-install only, then the manual acceptance steps in ChatGPT.

## Reused evidence

- Canonical `workforce_members.id` identity and attendance FK graph: Issue
  `#407` / PR `#408`.
- Schema-12 profile/application and backup-format-1 compatibility: Issue
  `#409` / PR `#410`.
- First-level Sicil, profile UI and attendance history read-model: Issue `#411`
  / PR `#412`.
- Application/package ID, signing, ARM64/16 KiB, permission/privacy,
  background/reboot and destructive backup/restore contracts are unchanged and
  are not rerun.

## Retry and time budget

- Primary run: 1.
- Blocking correction: at most 1.
- Same failed operation: at most one retry after an exact fix.
- Target: 45 minutes.
- Hard stop: 75 minutes.

## Stop and publication

Stop fail-closed on any schema/migration need, replacement identity, fuzzy
merge, relaxed active/project validation, historical row rewrite/loss,
attachment redesign, backup bump, automatic compliance decision, required real
user mutation or allowlist-external production path.

Do not commit or push until all authorized local and device/manual gates pass.
After PASS, create factual result evidence, one commit, normal push and a Draft
PR with `Closes #413`. Do not mark Ready or merge; do not start V2.2e. Detailed
execution results go to Issue #413; chat output is only the Issue/comment
reference except that manual acceptance steps remain in chat.
