# Issue #547 Task — Project Context Continuity Wave 2B.1

## Authority

- Parent / V2 item: Epic #539 / Wave 2B.1
- Issue: #547
- Owner authority: comment `5481714672` (`ONE-SHOT EXECUTION AUTHORITY`)
- Predecessor: Issue #545 / merged PR #546
- Expected base: `82413401384f3bfa2cfb04defe9dbb1aa98a7b6a`
- Branch: `codex/issue-547-project-context-wave-2b1`
- Required stop: `FRESH_INDEPENDENT_R4`
- Ready authorized: no
- Merge authorized: no

## Routing and risk

- Classification: R4
- Requested model / reasoning: `gpt-5.6-sol / max`
- Runtime actual model / effort: `unknown / null`
- Runtime verification: `unverified`
- Mismatch detected: `null`
- Independent review floor: R4, `gpt-5.6-sol / max`
- Execution mode: single-agent

## Canonical source manifest

Read from `origin/master` at the exact base before implementation:

| Source | Git blob |
| --- | --- |
| `AGENTS.md` | `75e218af5813422a08aae08dc9df7d07507169be` |
| `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md` | `d2f31def8ee392aab74990766e0a4822be489710` |
| `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md` | `f83164280277cc1f811448a559ddbfcc78d56040` |
| `docs/protocols/CSE_MODEL_REASONING_ROUTING_POLICY.md` | `7d099ed4e5a1205320350c663fe659e36f2c4d6a` |
| `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md` | `e90612f5ca5bb3f4997110142e24112e246f3b6d` |
| `docs/protocols/CSE_WORKFLOW_ACCELERATION_PROTOCOL.md` | `b8ce5dd678935e472e1e5351db6c60b6c87238d7` |
| `docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md` | `af1974ecd2c53ceb67245c8eb1242b03fb1a82ef` |
| `docs/protocols/CSE_CODEX_INSTRUCTION_COMMENT_PROTOCOL.md` | `23eb5c4d72ce3858f097292f7fa1d3fb713d3b7e` |
| `docs/protocols/CSE_PROJECT_SOURCE_REGISTER.md` | `583663cf0016d5060ed90ec44d1fce8aa16f74a5` |
| `docs/v2/CSE_V2_SCOPE.md` | `12bf27e27dde086a396aa063d16c148410906ea7` |
| `ROADMAP.md` | `61037f291f18b3434d740fdb096bdce6a0f9b885` |

Current Issue #547, authority comment, predecessor PR #546, open PR state,
Issue #479, the Wave 0 project-context findings, and the repository state mirror
were also read before implementation. The state mirror is stale secondary data
and does not override current GitHub/repository truth.

## Changed contracts

- A deliberate, validated route-local project selection may request a shared
  active-project update through an optional callback.
- Shell validation must use a fresh `agenda.listProjects()` result before
  `ActiveProjectSession.select`.
- Dashboard context must seed Album, Workforce Directory, and Phone Call Result.
- Concrete, Workforce Directory, Album, and Phone Call Result must fail closed
  for explicit stale/unvalidated initial project IDs while preserving legacy
  no-initial fallback.
- `Daha` routes for Concrete and Workforce must never silently choose an
  arbitrary project when shell context is absent or ambiguous.
- Agenda mixed/global Reminder and source-bound semantics remain unchanged.

## Exact write allowlist

1. `.cse/tasks/547_task.md`
2. `.cse/results/547_result.md`
3. `mobile/lib/app.dart`
4. `mobile/lib/features/living_plan/living_plan_page.dart`
5. `mobile/lib/features/daily_log/daily_log_page.dart`
6. `mobile/lib/features/material_requests/material_requests_page.dart`
7. `mobile/lib/features/concrete/concrete_page.dart`
8. `mobile/lib/features/attendance/workforce_directory_page.dart`
9. `mobile/lib/features/attachments/project_media_album_page.dart`
10. `mobile/lib/features/agenda/phone_call_result_page.dart`
11. `mobile/test/project_context_bidirectional_widget_test.dart`
12. `mobile/test/widget_test.dart`

All other paths are read-only. Attendance production/application/domain/storage,
`ActiveProjectSession`, application/domain/storage/schema/migration/bootstrap,
platform/package files, Inventory, and DWG are protected.

## Validation contract

- Focused gate: one invocation containing the seven existing focused test files
  plus `test/project_context_bidirectional_widget_test.dart`.
- Regression gate: one invocation, only after focused PASS, containing the four
  authorized regression files.
- `flutter analyze --no-pub`: one invocation.
- Changed-Dart format check.
- Full and staged `git diff --check`.
- Exact allowlist and protected-drift checks.
- Schema / backup / version invariants: `22 / 1 / 0.1.0+1`.
- Automated application tests are enabled only for the owner-authorized focused
  and regression gates above; build, device, ADB, and manual acceptance remain
  unauthorized.

## Manual tests and artifact authority

- Manual test register: Issue #479
- Stable IDs: `MT-547-*`, to be added as `PENDING` after successful gates.
- Manual test status: `PENDING`
- Build/artifact authority: none

## Stabilization and escalation

- Primary implementation window: 1
- Same-scope stabilization: one bounded batched correction round after an exact
  deterministic failure classification.
- Deterministic test retry: 0
- Environment-only recovery: 1; consumed before workload by correcting an
  invalid local `git switch` option combination. No repository content changed.
- Immediate stop: allowlist expansion, new product decision, schema/migration/
  backup/version/permission/platform change, protected production path need,
  data-integrity risk, unproven root cause, or exhausted correction budget.

## Publication authority

If every gate passes: append result evidence, create one commit, push the exact
branch, create exactly one Draft PR referencing #547/#545/#546/#539, add the
manual tests to Issue #479 as `PENDING`, publish exact evidence to the Issue and
PR, do not mark Ready, do not merge, and stop at `FRESH_INDEPENDENT_R4`.

## Execution chronology

- Preflight: official root and origin verified; tracked, staged, and untracked
  state clean; no merge/rebase/cherry-pick/revert state.
- GitHub: exact authority loaded; PR #546 merged at the exact base; deferred
  Inventory PR #536 remains open and untouched; no pre-existing `MT-547-*` rows.
- Branch: created from exact `origin/master`; initial divergence `0/0`.
- Status: implementation inspection in progress.

## Process v3 supersession and final recovery (authoritative)

- The earlier R4/local-matrix wording above is retained as historical evidence
  but is superseded by owner comments `5482063488` and `5482388860`.
- Current lane: `STANDARD`; review level: `R3`; exact base:
  `0ec8a241336fbf9afae38226e5faf988b1481163`.
- The authorized recovery advanced local `master` to the exact base and rebased
  this branch once without conflicts. The recovery ledger commit became
  `66c38ada9cebd2f7a29ac260c983fbbae6a9ec44`.
- Production implementation stayed inside the original Issue #547 allowlist.
- Two normal same-scope corrections fixed deterministic test-harness defects.
  The remaining eager `Future.error` fixture defect then received the explicit
  `ONE_FINAL_HARNESS_ONLY_CORRECTION` authority.
- That final exception changed only
  `mobile/test/project_context_bidirectional_widget_test.dart`: discovery
  failures are now created lazily when `listProjects()` is invoked, preserving
  all fail-closed and zero-scoped-call assertions.
- The exact previously failing discovery test passed after the correction.
- STANDARD source-level closure passed: changed-Dart format, full diff check,
  exact allowlist, protected drift, and invariants `22 / 1 / 0.1.0+1`.
- Broad Flutter validation is intentionally not rerun locally; it belongs to PR
  CI under the current authority.
- Publication target: one implementation commit, branch push, one Draft PR,
  manual tests `MT-547-*` recorded as `PENDING`, then stop at
  `DRAFT_PR_FOR_SHORT_REVIEW`.
