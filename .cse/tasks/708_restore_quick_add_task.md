# Issue #708 — Restore and quick-add correction task

- Lane: CRITICAL
- Issue: #708
- Pull request: #715 (Draft)
- Branch: `codex/issue-708-compliance-history`
- Base authority: `origin/master` at `337f32c704b11d2328b743262db47a0dddcf5e8f`
- Execution budget: 60 minutes

## Correction contract

- Restore the same compliance record with `expectedRevision` and append one
  `compliance.reopened` event in the same transaction.
- Reject stale or repeated restore attempts without rewriting, deduplicating, or
  duplicating events.
- Provide four quick-add cards with deterministic zero, one, and multiple-record
  behavior while keeping “Diğer” as the secondary path.
- Preserve stable record/event identity for retries, person/project isolation,
  multi-active semantics, truthful non-legal wording, and backup compatibility.
- View-only routes must not mutate state.

## Exact allowlist

1. `mobile/lib/domain/attendance_models.dart`
2. `mobile/lib/application/attendance_application.dart`
3. `mobile/lib/features/attendance/workforce_person_detail_page.dart`
4. `mobile/test/attendance_application_test.dart`
5. `mobile/test/workforce_person_profile_visual_test.dart`
6. `mobile/test/support/fake_attendance_application.dart`
7. `mobile/test/mobile_backup_application_test.dart`
8. `.cse/tasks/708_restore_quick_add_task.md`
9. `.cse/results/708_restore_quick_add_result.md`

Stop on conflict, protected-path drift, stale/double restore acceptance, identity
or isolation loss, backup incompatibility, or any required validation failure.
