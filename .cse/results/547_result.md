# Issue #547 — Execution Result

- Process lane / review: `STANDARD / R3`
- Exact base: `0ec8a241336fbf9afae38226e5faf988b1481163`
- Branch: `codex/issue-547-project-context-wave-2b1`
- Implementation status: `IMPLEMENTED — MANUAL TEST PENDING`
- Manual test status: `PENDING`

## Result

- Dashboard project context now flows to the authorized core routes, and a
  deliberate validated route-local selection flows back to the shell.
- Concrete, Workforce Directory, Project Media Album, and Phone Call Result
  validate explicit initial project IDs before project-scoped work and retain
  legacy no-initial fallback.
- Concrete and Workforce entry from `Daha` fails closed when shell context is
  absent or ambiguous.
- Agenda mixed/global semantics, Attendance session behavior, and dependent
  invalidation/cancel behavior remain protected.

## Correction and validation evidence

- Normal corrections used: `2 / 2`, both deterministic harness corrections.
- Additional correction: owner-authorized
  `ONE_FINAL_HARNESS_ONLY_CORRECTION`, limited to the new widget harness.
- Exact targeted discovery check: `PASS` (`+1 All tests passed`).
- Earlier full Issue #547 widget-file run: four scenarios passed; the sole
  failure was the now-corrected eager error fixture.
- Changed-Dart format check: `PASS`, 9 files, 0 changed.
- Full `git diff --check`: `PASS`.
- Allowlist/protected-drift check: `PASS`; no `ActiveProjectSession`, storage,
  Inventory/DWG, platform/package, or unauthorized Attendance drift.
- Schema / backup / version: `22 / 1 / 0.1.0+1` (`PASS`).
- Broad Flutter validation: not run locally by authority; delegated to PR CI.
- Build/device/ADB/manual acceptance: not run; no artifact authorized.

## Publication state

- Changed paths: 11 authorized paths; `mobile/test/widget_test.dart` unchanged.
- Manual register target: Issue #479, `MT-547-001..006`, all `PENDING`.
- Commit/push/Draft PR evidence is published on GitHub after commit creation.
- Ready: not authorized. Merge: not authorized.

```yaml
execution_record:
  actual_model: unknown
  actual_reasoning_effort: null
  runtime_verification: unverified
review_recommendation: DRAFT_PR_FOR_SHORT_REVIEW
```

## Owner manual-test product correction — MT-547-001 FAIL

- Authority: Issue #547 comment `5482883231`, process lane `STANDARD`.
- Failing owner-tested source: PR #552 head
  `2a0439515cfed339432f5507f1513fe7d83d6fa1`.
- Observed: Dashboard selection worked, but `Daha → Beton Paketi` and
  `Daha → Sicil` did not open. `MT-547-001` is `FAIL` pending owner re-test.
- Source-level root cause: both More handlers performed a redundant shell
  `listProjects()` validation before navigation. A validation failure returned
  null and redirected to the already-selected Dashboard, producing an apparent
  silent no-op. Both destination pages already perform fail-closed explicit-ID
  validation and expose bounded retry/selection recovery before scoped work.
- Authorized correction: pass only the current session candidate ID into the
  destination page; keep null-session redirect behavior and destination-owned
  operational validation. No Attendance/Puantaj mutation is introduced.
- Production correction changed only `mobile/lib/app.dart`; Concrete and
  Workforce page-entry implementations were not changed.
- Regression harness now exercises Dashboard project B followed by both More
  entries under a synthetic first discovery failure. Each route remains open
  with its bounded retry, performs zero scoped work before validation, and uses
  B for the first scoped read after retry. The existing no-session fail-closed
  and hidden Attendance mutation assertions remain intact.
- Focused source analysis: `app.dart` PASS; bidirectional widget test source
  PASS. Changed-Dart format and full/staged diff checks PASS.
- Automated widget/device/ADB acceptance and APK build were not run under this
  correction authority. Broad Flutter execution remains PR CI; owner will
  manually re-test a separately authorized fresh Acceptance APK.
- Protected drift: none. Invariants remain `22 / 1 / 0.1.0+1`.
- Publication: correction commit/push evidence is recorded on Issue #547 and
  Draft PR #552. Ready/merge remain blocked; `MT-547-001` remains `FAIL` until
  owner re-test.
