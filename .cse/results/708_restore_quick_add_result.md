# Issue #708 — Restore and quick-add correction result

- Status: review blocker corrected; focused automated validation PASS;
  independent re-review PENDING
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

## Previous correction validation — `72a02c3`

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

## Review blocker correction — 2026-09-07

Starting reviewed head: `72a02c3ee34cfbf258fbd8574ddf58cc11466ba9`.
The review found that a successful save released the cached command before the
following detail read succeeded, allowing a retry to create new identities.

The UI now releases a command only during a successful detail refresh that
contains its exact ID in active or archived compliance records. A failed read or
a successful read without that ID retains the same cached record/event IDs.
Application-layer idempotency and the existing response-lost-after-save test
are unchanged.

Validation on the corrected source:

- One focused invocation of `flutter test --no-pub --concurrency=1 --reporter
  expanded test/workforce_person_profile_visual_test.dart
  test/attendance_application_test.dart`: PASS, 72 tests (51 widget, 21
  application), exit 0.
- New save-success/read-failure/retry regression: PASS, equal command record IDs
  and event IDs, exactly one stored record and one stored event.
- New successful-refresh-without-exact-ID regression: PASS, retry identities
  retained and exactly one stored record/event.
- Existing response-lost-after-save regression: PASS as a separate test.
- Format and diff-check: PASS. Correction changes only UI, its widget test and
  these two provenance files; the complete PR remains within the nine paths.
- Application/domain/shared fake/backup sources are unchanged from the reviewed
  head; protected drift: none.
- Analyzer: not rerun; no new API/type/import contract, and focused tests compile
  the changed UI and test code. Previous analyzer PASS remains historical.
- Backup validation: previous PASS reused; backup/restore contracts unchanged.
- Acceptance build/install: not run. Independent re-review of the new PR head
  and new owner Acceptance remain PENDING; PR stays Draft.
