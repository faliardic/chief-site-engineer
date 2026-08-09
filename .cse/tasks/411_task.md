# Issue #411 — V2.2c first-level Sicil / Saha Rehberi

- Issue: `#411`
- Parent V2.2: `#204`
- Parent Epic: `#385`
- Foundation: `#409` / PR `#410`
- Official repository: `V:\\1_PROJECTS\\2_ACTIVE\\Python\\chief-site-engineer`
- Linked worktree: `C:\\Users\\Fatih\\AppData\\Local\\CSE-Worktrees\\issue-411`
- Exact base: `origin/master` / `8abb67aac6831f180ae8216a27a33c13837742ce`
- Branch: `codex/issue-411-v2-2c-sicil-field-directory`
- Codex model: current strongest full Codex model
- Reasoning: `Extra High`; first-level navigation, project scope, canonical
  workforce identity, lifecycle mutations, attendance history and existing
  deep-link indices must remain coherent.
- Validation class: multi-surface UI + canonical registry read-model/lifecycle
  (`domain` with broad UI gates explicitly required by the Issue).

## Changed contracts

- Add a first-level Sicil destination without changing existing destination
  indices 0–4.
- Add a project-scoped field directory with deterministic search and active,
  subcontractor and team filters.
- Reuse existing subcontractor/team/member lifecycle and canonical
  `workforce_members.id` source-of-truth.
- Adopt schema-12 optional profile fields in existing forms and details.
- Add a read-only person attendance summary/history derived from existing
  attendance entries and the canonical member ID.

## Authorized paths

- `mobile/lib/app.dart`
- `mobile/lib/domain/attendance_models.dart`
- `mobile/lib/application/attendance_application.dart`
- `mobile/lib/features/attendance/attendance_page.dart` only for backward-compatible nested entry
- `mobile/lib/features/attendance/workforce_page.dart`
- `mobile/lib/features/attendance/workforce_registry_page.dart`
- `mobile/lib/features/attendance/workforce_person_detail_page.dart`
- `mobile/lib/features/attendance/workforce_directory_page.dart`
- `mobile/test/attendance_application_test.dart`
- `mobile/test/attendance_widget_test.dart`
- `mobile/test/workforce_directory_widget_test.dart`
- `.cse/tasks/411_task.md`
- `.cse/results/411_result.md`

Navigation/static regression files are not authorized without a new exact
GitHub comment.

## Protected contracts and out of scope

- No `app_database.dart`, schema, migration or backfill change.
- Schema remains 12 and backup format remains 1.
- No parallel person identity, fuzzy dedupe/merge or ID regeneration.
- No attachment/compliance/PPE data-model redesign.
- No Puantaj selector, new-roster or attendance-result redesign.
- No real-user-data inspection or required mutation.
- No V2.2d/e, V2.3, release, signing, workflow or toolchain work.

## Validation

- Focused attendance application and directory/widget/navigation tests.
- Existing attendance/workforce lifecycle regressions.
- `git diff --check` and exact allowlist/protected-path checks.
- One full `flutter test --no-pub` on the final source revision.
- `flutter analyze --no-pub`.
- One `flutter build apk --debug` on the final source revision.
- After local PASS: exactly one authorized physical device, replace-install
  only, read-only/navigation smoke and manual acceptance in the ChatGPT chat.

## Retry and time budget

- Primary run: 1.
- Blocking correction: at most 1.
- Same failed operation: at most one retry after an exact fix.
- Target: 45 minutes.
- Hard stop: 75 minutes.

## Stop and publication

Stop fail-closed on any schema/migration need, new identity, fuzzy merge,
attachment redesign, Puantaj workflow change, required real-data mutation,
unsafe first-level navigation contract or allowlist-external production need.

Do not commit or push until local plus device/manual gates pass. After PASS,
create factual result evidence, one commit, normal push and a Draft PR with
`Closes #411`. Do not mark Ready or merge; do not start V2.2d. Detailed results
go to Issue #411; chat output is only the Issue/comment reference except that
manual acceptance steps remain in chat.
