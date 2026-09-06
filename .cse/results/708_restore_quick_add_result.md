# Issue #708 — Restore and quick-add correction result

- Status: implementation and focused automated validation PASS
- Base: `origin/master` at `337f32c704b11d2328b743262db47a0dddcf5e8f`
- Branch: `codex/issue-708-compliance-history`
- Pull request: #715 remains Draft
- Manual owner Acceptance: PENDING; no product PASS/FAIL decision was made

## Implemented evidence

- Restore keeps the same record ID, checks `expectedRevision`, clears
  `archived_at`, advances `updated_at` and `revision`, and appends the
  next-sequence `compliance.reopened` event atomically.
- Stale and double restore, cross-person/project access, and duplicate event IDs
  fail closed without partial record or event changes.
- The four primary quick-add cards implement `0 -> + Ekle`, `1 -> exact detail`,
  and `2+ -> deterministic N kayıt`; “Diğer” remains secondary.
- Quick-add retry identity and idempotency, view-only behavior, multi-active
  records, existing wording, and backup round-trip behavior are covered.

## Validation evidence

- `dart format`: PASS
- `flutter analyze --no-pub`: PASS
- `test/attendance_application_test.dart`: PASS
- `test/mobile_backup_application_test.dart`: PASS, including reopened lifecycle
  round-trip
- `test/workforce_person_profile_visual_test.dart`: PASS, including 320/390 px,
  2x text scale, >=48dp/Semantics, deterministic cards, and view-only checks
- `git diff --check`: PASS
- Exact nine-path allowlist / protected-drift check: PASS

Independent review and a new owner Acceptance run remain publication gates.
