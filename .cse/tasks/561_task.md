# Issue #561 — Puantaj active-project adoption + hidden-mutation safety

- Parent / V2 item: #554 / #539, after #558 and PR #560
- Owner authority: Issue #561 comment 5488533818
- Expected base: `bffe537d6a04947dd42e71c19df2d39e7d55c915`
- Branch: `codex/issue-561-attendance-active-project-safety`
- Process lane: accelerated STANDARD, R4 mutation-safety review
- Requested execution: `gpt-5.6-sol / high`
- Runtime execution evidence: model `unknown`, effort `null`, invocation `unverified`
- Independent review floor: `gpt-5.6-sol / xhigh`

## Changed contracts

- Hidden Puantaj must not discover projects or enter `ensureDay` / rolling-occurrence mutation paths.
- Visible Puantaj validates and loads only the exact shared active project.
- Null, stale, or unavailable shared project IDs remain fail-closed; no first-project fallback.
- A deliberate local Puantaj project change updates shared context only after its exact load succeeds.
- The compact active-project indicator includes the visible Puantaj tab.

## Exact allowlist

1. `.cse/tasks/561_task.md`
2. `.cse/results/561_result.md`
3. `mobile/lib/app.dart`
4. `mobile/lib/features/attendance/attendance_page.dart`
5. `mobile/test/attendance_widget_test.dart`
6. `mobile/test/project_context_bidirectional_widget_test.dart`

Attendance application/domain/repository/storage, database/coordinator, `ActiveProjectSession`, Inventory, schema/migrations, backup/restore, version/platform and unrelated feature paths are protected.

## Validation and publication

- Automated application tests: owner-authorized one focused widget invocation only, covering the two changed widget-test files.
- No full suite, `flutter analyze`, APK, emulator, device, Ready or merge.
- Source checks: touched-Dart format, exact allowlist/protected drift, `git diff --check`, schema/backup/version invariants `22 / 1 / 0.1.0+1`.
- Manual test register: `MT-561-001..003`, initially `PENDING`.
- Build/artifact authority: none.
- Same-scope correction budget: at most one mechanical retry.
- Immediate escalation: scope/allowlist expansion, database/coordinator/session implementation change, schema/version/platform change, or unproven mutation safety.
- Publication authority: one commit, push, and Draft PR; stop before Ready/merge.

## Canonical source manifest

`AGENTS.md fef003f07e47e7578d1db8f164a1e459ed08909e`; unified source `d2f31def8ee392aab74990766e0a4822be489710`; project instructions `f83164280277cc1f811448a559ddbfcc78d56040`; routing `7d099ed4e5a1205320350c663fe659e36f2c4d6a`; minimum validation `e90612f5ca5bb3f4997110142e24112e246f3b6d`; acceleration `473308a212213450ea44d669109b0cc3b82d9e68`; owner communication `a86a91b53778eb3d45bb4a8458ca652d7d7ce2cc`; bootstrap `af1974ecd2c53ceb67245c8eb1242b03fb1a82ef`; source register `583663cf0016d5060ed90ec44d1fce8aa16f74a5`; V2 scope `12bf27e27dde086a396aa063d16c148410906ea7`; roadmap `61037f291f18b3434d740fdb096bdce6a0f9b885`.
