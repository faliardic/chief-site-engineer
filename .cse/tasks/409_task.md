# Issue #409 — V2.2b additive registry profile schema 12

- Issue: `#409`
- Parent V2.2: `#204`
- Parent Epic: `#385`
- Preflight: `#407` / PR `#408`
- Official repository: `V:\\1_PROJECTS\\2_ACTIVE\\Python\\chief-site-engineer`
- Linked worktree: `C:\\Users\\Fatih\\AppData\\Local\\CSE-Worktrees\\issue-409`
- Exact base: `origin/master` / `5fc0e3442031b5d1ecf4f2b46f16e3213ca0c30d`
- Branch: `codex/issue-409-v2-2b-registry-profile-schema12`
- Codex model: current strongest full Codex model
- Reasoning: `Extra High`; schema migration, canonical identity, dependent Puantaj/compliance/PPE links, archive/revision/event history and backup compatibility are data-loss sensitive.
- Validation class: `persistence` — schema migration + canonical registry application contract.

## Changed contracts

- Mobile schema advances from 11 to 12 through an additive, atomic migration.
- `subcontractors` adds nullable `address`, `specialty`, `started_on`, `ended_on`.
- `workforce_members` adds nullable `address`, `started_on`.
- Subcontractor and workforce-member domain/create/update/read contracts expose the corresponding optional values.
- Existing canonical IDs, dependent FKs, archive/revision/event history and backup format 1 remain unchanged.
- New date values use the existing canonical local-date contract; legacy rows retain `NULL`.

## Authorized paths

- `mobile/lib/storage/app_database.dart`
- `mobile/lib/domain/attendance_models.dart`
- `mobile/lib/application/attendance_application.dart`
- `mobile/test/app_database_test.dart`
- `mobile/test/attendance_application_test.dart`
- `mobile/test/mobile_backup_application_test.dart`
- `.cse/tasks/409_task.md`
- `.cse/results/409_result.md`
- `docs/project_decisions.md` only if a genuinely new permanent decision is required

No new focused test file is authorized without an exact GitHub comment.

## Implementation contract

- Preserve every existing subcontractor/team/member primary key byte-for-byte.
- Preserve attendance/compliance/PPE member foreign keys without relink or regeneration.
- Preserve revisions, archive timestamps and append-only events; do not replay schema 5→6 adoption.
- Add nullable columns only; do not backfill or infer values.
- Validate optional dates with the existing project local-date contract and enforce `ended_on >= started_on` when both exist.
- Preserve required fields, optimistic revision, no-op and archive/restore semantics.
- Make profile clear/preserve behavior explicit and deterministic; unrelated updates must not erase stored values.
- Registry move keeps the canonical member ID and all dependent links.
- Keep `employment_entry` compliance metadata; do not create a second SGK structure.
- Keep backup format 1 and all attachment behavior unchanged.

## Focused validation

- schema 11→12 PK/FK/archive/revision/event preservation;
- intentional migration failure rolls back to intact schema 11;
- fresh/upgraded schema 12 column and constraint equivalence;
- legacy `NULL` profile rows remain readable;
- subcontractor/member create, update, explicit clear and restart persistence;
- unrelated update preserves profile values;
- member ID remains canonical in attendance and through registry move;
- archived member historical/new-roster and parent-first restore regressions;
- schema 11 format-1 backup restore+migrate;
- schema 12 format-1 round-trip for new fields and existing identities/history;
- physical-delete guard and append-only workforce-event regression.

## Authorized broad gates

- relevant focused migration/application/backup tests;
- related existing attendance/workforce lifecycle regression suite;
- full `flutter test --no-pub` once on the final source revision;
- `flutter analyze --no-pub`;
- `git diff --check`;
- `flutter build apk --debug` once on the final source revision.

## Reused evidence

- PR #408 / base `5fc0e3442031b5d1ecf4f2b46f16e3213ca0c30d`: existing `workforce_members.id` canonical identity graph and schema 5→6 stable-link adoption.
- Unchanged application/package/signing/background/reboot/release contracts are outside this persistence child and are not rerun.

## Minimum physical-device acceptance

- If exactly one authorized physical Android device exists, replace-install only and app-open smoke may be performed.
- No uninstall, clear-data, destructive restore or real-user-data mutation/inspection.
- No manual acceptance is required because this child adds no visible UI.

## Retry and time budget

- Primary run: 1.
- Blocking correction: at most 1.
- Same failed operation: at most 1 retry after an exact fix.
- Target: 45 minutes.
- Hard stop: 75 minutes.

## Explicit out of scope

- top-level Sicil/Saha Rehberi navigation, forms, search/filter or read-model UI;
- Puantaj selector, `+ Yeni eleman` and attendance-summary UI;
- name split, duplicate merge/cleanup or real-user-data inspection;
- workforce/compliance/PPE attachments or reminders;
- Ajanda/Work identity adoption;
- backup format bump;
- V2.2c/d/e, V2.3, release/signing/workflow/toolchain changes.

## Stop conditions

Stop without further edits if identity rewrite, automatic merge/dedup, invented non-null backfill, schema expansion beyond the six exact columns, backup-format bump, attachment redesign, UI/workflow changes, real-user-data access or an allowlist-external production path becomes necessary.

## Publication

- Do not commit or push until every authorized local gate passes.
- After PASS: factual result file, commit, normal push and Draft PR with `Closes #409`.
- Do not mark Ready or merge; do not begin V2.2c.
- Detailed completion/blocker evidence goes to Issue #409; chat output is only the Issue/comment reference.
- Post-merge sync is not part of this task.
