# Issue #561 — execution result

## Product result

Puantaj now remains dormant while its IndexedStack tab is hidden. Launch, Dashboard project changes, shell rebuilds, and project-change signals do not start Puantaj project discovery, `ensureDay`, or rolling-occurrence work. On deliberate entry it validates and loads only the exact shared active project; null, stale, and unavailable IDs remain non-operational with no first-project fallback.

A deliberate Puantaj selector change is reported to the shared active-project session only after the exact project load succeeds. A failed local load restores the prior visible selection and does not retarget the shared session. The compact active-project indicator is visible on Puantaj.

## Exact changed paths

1. `.cse/tasks/561_task.md`
2. `.cse/results/561_result.md`
3. `mobile/lib/app.dart`
4. `mobile/lib/features/attendance/attendance_page.dart`
5. `mobile/test/attendance_widget_test.dart`
6. `mobile/test/project_context_bidirectional_widget_test.dart`

No attendance application/domain/repository/storage, database/coordinator, `ActiveProjectSession`, Inventory, schema, backup, version, platform, package, or unrelated feature path changed.

## Validation evidence

- Touched-Dart format: PASS.
- Owner-authorized focused widget gate:
  `flutter test --no-pub test/attendance_widget_test.dart test/project_context_bidirectional_widget_test.dart`
- First gate result: deterministic test-harness failure because two new direct page mounts lacked a `Scaffold` / Material ancestor; production shell regressions progressed.
- Authorized same-scope mechanical retry: added only the missing test harness `Scaffold` wrappers.
- Final focused gate: PASS, `21` tests.
- Covered behavior: hidden launch and hidden B→A/project signals produce zero Puantaj mutation calls; visible entry loads exact B/A; null/stale selection does not fall back; failed local selection does not change the shared indicator/session; successful B→A selection updates both.
- Full suite: not run by owner instruction.
- `flutter analyze`: not run by owner instruction.
- APK/emulator/device: not run and not authorized.

Final source gate records exact allowlist, protected drift, `git diff --check`, changed-Dart format, and invariants `schema 22 / backup 1 / app 0.1.0+1`.

## Manual test register

- `MT-561-001` — Dashboard active B → Puantaj opens on B and shows B in the top-right indicator: `PENDING`.
- `MT-561-002` — Puantaj deliberate B→A selector change loads A and shared project surfaces retain A: `PENDING`.
- `MT-561-003` — Normal launch/tab changes without opening Puantaj create no unexpected Puantaj day/rolling work or loading stall: `PENDING`.

Implementation status: `IMPLEMENTED — MANUAL TEST PENDING`.

## Publication state

One commit, branch push, and Draft PR are authorized after final source gates. Ready, merge, APK, install, release, and Issue closure are not authorized.

## execution_record

```yaml
issue: 561
authority_comment: 5488533818
base: bffe537d6a04947dd42e71c19df2d39e7d55c915
branch: codex/issue-561-attendance-active-project-safety
process: accelerated_STANDARD_R4
requested_model: gpt-5.6-sol
requested_effort: high
actual_model: unknown
actual_effort: null
runtime_verified: false
focused_gate_final: PASS_21
mechanical_retry_used: 1
implementation_status: IMPLEMENTED
manual_test_status: PENDING
artifact: none
ready: false
merge: false
```

## review_recommendation

`FRESH_INDEPENDENT_R4` at `gpt-5.6-sol / xhigh`, emphasizing zero hidden mutation, exact shared-project validation, and success-only session adoption.
