# Issue #415 — V2.2e closure, persistence and field acceptance

- Issue: `#415`
- Parent V2.2: `#204`
- Parent Epic: `#385`
- Foundation chain: `#407` / PR `#408`, `#409` / PR `#410`, `#411` /
  PR `#412`, `#413` / PR `#414`
- Official repository:
  `V:\\1_PROJECTS\\2_ACTIVE\\Python\\chief-site-engineer`
- Linked worktree:
  `C:\\Users\\Fatih\\AppData\\Local\\CSE-Worktrees\\issue-415`
- Exact base: `origin/master` /
  `142d59b7b6f4af1ce85931a29db703c9f14db8a3`
- Branch: `codex/issue-415-v2-2e-closure`
- Codex model: current strongest full Codex model
- Reasoning: `Extra High`; closure combines canonical identity, schema 12,
  migration/restart, backup format 1, archive/history, Puantaj roster behavior,
  physical replace-upgrade and release/static regression evidence.
- Validation class: cross-feature persistence + backup/restart + physical-field
  acceptance + release/static regression.

## Execution mode

This is validation-first closure. No new production behavior is expected.
Production or test source changes are not authorized. If an executable closure
contract is missing or a gate exposes a real blocker, stop without editing that
source and request an exact narrow authorization in Issue #415.

## Closure contracts

- `workforce_members.id` remains the only canonical person identity used by
  attendance, compliance and PPE relations.
- Schema remains `12`; schema 11→12 migration preserves stable identity and
  additive nullable subcontractor/member profile fields.
- Explicit clear is deterministic; unrelated edit and archive/restore do not
  silently erase profile values.
- First-level Sicil remains the final navigation destination and preserves
  project/search/active/archive/subcontractor/team behavior plus nested
  Workforce/Puantaj compatibility.
- Archived members remain visible in historical attendance but cannot become
  new candidates; restored members with active parents can become candidates.
- Puantaj candidates remain current-project, active-subcontractor and
  active-team/member scoped. Filter changes preserve selected/persisted rows.
- Inline `+ Yeni eleman` uses the existing canonical create command, does not
  persist attendance before roster Save and saves the exact new member ID.
- Existing stale/no-op/double-submit/atomic roster behavior and the
  non-blocking, non-legal SGK/İSG/OSGB warning remain intact.
- Backup format remains `1`; schema 11 format-1 restore migrates to schema 12,
  and schema 12 round-trip preserves IDs, FKs, profile fields, archive flags,
  revisions, events and attendance history.

## Authorized changed-file allowlist

- `.cse/tasks/415_task.md`
- `.cse/results/415_result.md`
- `docs/project_decisions.md` only if validation produces a genuinely new
  closure decision

Production and test files are protected unless Issue #415 later grants an
exact file/path and exact correction authorization.

## Focused automated validation

- `mobile/test/attendance_application_test.dart`
- `mobile/test/attendance_widget_test.dart`
- `mobile/test/workforce_directory_widget_test.dart`
- `mobile/test/attendance_roster_selector_widget_test.dart`
- schema 11→12 identity/profile migration coverage in
  `mobile/test/app_database_test.dart`
- schema 11→12 and schema 12 format-1 round-trip coverage in
  `mobile/test/mobile_backup_application_test.dart`
- ProjectLocation/current-schema regressions
- navigation/static platform/configuration regressions

Before running gates, map the existing test names/assertions to all twelve
Issue closure behaviors. A missing executable contract is a stop condition,
not permission to add a test.

## Broad local gates

- Final `git diff --check` and exact allowlist/protected-path checks.
- One full `flutter test --no-pub` on the unchanged tracked source revision.
- `flutter analyze --no-pub`.
- One `flutter build apk --debug`.
- Verify package/application ID, schema literal `12`, backup format literal `1`
  and absence of tracked dependency/config drift.

Do not run AAB/signing/store publication, version bump, destructive restore,
background/reboot or unrelated release gates.

## Backup and restart evidence

Use only disposable/temp automated test areas. Do not read or restore real user
data. Required executable evidence covers schema 12 full round-trip, schema 11
format-1 restore+migrate, canonical IDs/FKs/profile/archive/revision/event/count
preservation and fail-closed unsupported/failure behavior.

## Physical-device acceptance

Only after every local gate passes:

- exactly one authorized physical Android device, expected `SM-X610`;
- `ro.kernel.qemu=0`;
- only `adb install -r` and launch;
- no uninstall, clear-data, restore, UI dump, user-content reading or Codex
  Sicil/Puantaj mutation;
- manual data-preserving acceptance steps remain in ChatGPT chat and only the
  PASS/FAIL/N/A result is recorded on GitHub.

## Reused evidence

- Canonical identity/FK graph: Issue `#407` / PR `#408`.
- Schema 12 profile/application and format-1 compatibility: Issue `#409` /
  PR `#410`.
- First-level Sicil/profile/history surface: Issue `#411` / PR `#412`.
- Subcontractor-first roster, canonical inline create and physical field UX:
  Issue `#413` / PR `#414`.
- Unchanged signing, ARM64/16 KiB, background/reboot, permission/privacy and
  store contracts are not rerun.

## Safety, retry and time budget

- Original dirty worktree remains read-only with its existing four tracked
  modifications; do not list or read its untracked contents.
- Do not touch user backup/report/device-backup or real data areas.
- No reset, clean, stash, restore, checkout, delete, overwrite or force push.
- Primary validation run: 1.
- Blocking correction: none automatically; exact GitHub authorization required.
- Same-operation evidence retry: one only for lost output/exit evidence without
  a source change.
- Target: 45 minutes.
- Hard stop: 75 minutes.

## Stop and publication

Stop fail-closed for any production behavior need, source-test gap, schema or
backup-format change, canonical ID/FK loss, backup/restart/archive/history loss,
full gate failure, allowlist-external edit need, real-user mutation need or
release/toolchain change need.

After every authorized closure gate and manual acceptance passes, create the
factual result artifact, one documentation-only commit, normal push and a Draft
PR containing `Closes #415`. Do not mark Ready or merge, do not close Parent
#204, and do not start V2.3. Detailed output goes to Issue #415; final chat
output is only the Issue/comment reference except for manual acceptance steps.
