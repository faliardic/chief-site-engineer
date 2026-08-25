# Issue #483 — Agenda–Takip İş Zinciri v1

## Authority and execution boundary

- Repository: faliardic/chief-site-engineer
- Parent Epic / V2 item: #385 / V2.7 — İş Zinciri / Bağlı Log v1
- Issue: #483
- Owner authority:
  https://github.com/faliardic/chief-site-engineer/issues/483#issuecomment-5398892085
- Exact merged base: 317fbfa66738eac21994abd824d9eda49ad70e0e
- Branch: codex/issue-483-work-chain-v1
- Isolated worktree:
  V:\1_PROJECTS\2_ACTIVE\Python\CSE-Worktrees\issue-483-work-chain-v1
- Validation class: narrow-ui with an R3 multi-source integrity read boundary
- Verification mode: owner_led_manual_testing
- Implementation status: IN_PROGRESS
- Manual test status: PENDING
- Phone connection required: No

This file is the first substantive project-file edit in the isolated worktree.

## Model routing

~~~yaml
model_routing:
  policy_version: CSE-MRP-1.0
  task_risk: R3
  requested_model: gpt-5.6-sol
  requested_reasoning_effort: xhigh
  execution_mode: standard
  orchestration: single-agent
  allowed_fallback: null
  verification_mode: owner_led_manual_testing
  selection_reason: Exact source identity, append-only history integrity, typed diagnostics and narrow UI navigation require contract-level review.
  review_floor:
    model: gpt-5.6-sol
    reasoning_effort: xhigh
  fail_closed_if_mismatch: true
~~~

Invocation/runtime model metadata is not exposed. Final evidence must use
actual_model: unknown, actual_reasoning_effort: unknown,
mismatch_detected: null and runtime_verification_status: unverified.

## Canonical source manifest

The following exact-base blobs were verified before this edit:

- AGENTS.md: 75e218af5813422a08aae08dc9df7d07507169be
- CSE_UNIFIED_PROJECT_SOURCE.md: d2f31def8ee392aab74990766e0a4822be489710
- CSE_PROJECT_INSTRUCTIONS.md: f83164280277cc1f811448a559ddbfcc78d56040
- CSE_MODEL_REASONING_ROUTING_POLICY.md: 7d099ed4e5a1205320350c663fe659e36f2c4d6a
- CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md:
  e90612f5ca5bb3f4997110142e24112e246f3b6d
- CSE_WORKFLOW_ACCELERATION_PROTOCOL.md:
  b8ce5dd678935e472e1e5351db6c60b6c87238d7
- CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md:
  a4b2c61dd83ce386d453dc684b22651aa980275f
- CSE_PROJECT_SOURCE_REGISTER.md:
  583663cf0016d5060ed90ec44d1fce8aa16f74a5
- docs/v2/CSE_V2_SCOPE.md:
  75761ac99e091f3d32d8578252c3ee7cc2c9f23c
- ROADMAP.md: 1950f20293ba24a3bbafff9bd27e643da11941c4

Issue #483 body and all current comments were read before this edit.

## Changed contract

Build a read-only canonical chain from one exact Agenda observation through its
explicit same-project follow-up relation, append-only follow-up lifecycle events
and current result projection. Both Agenda-log and follow-up entry points must
resolve the same chain. Missing, dangling, mismatched, duplicate, event-order
and terminal-projection contradictions remain typed diagnostics; no source
repair, inference or mutation is allowed. Add only the narrow safe Daily Log
source-ref entry point and one human-readable Work Chain detail surface.

## Exact initial allowlist — 12 paths

1. mobile/lib/domain/work_chain_models.dart
2. mobile/lib/application/work_chain_application.dart
3. mobile/lib/features/work_chain/work_chain_page.dart
4. mobile/lib/features/daily_log/daily_log_page.dart
5. mobile/lib/bootstrap/app_bootstrap.dart
6. mobile/lib/app.dart
7. ROADMAP.md
8. docs/v2/CSE_V2_SCOPE.md
9. docs/project_decisions.md
10. CHANGELOG.md
11. .cse/tasks/483_task.md
12. .cse/results/483_result.md

Agenda/Reminder domain, application, storage and notification sources are
protected read-only references. A thirteenth path requires evidence and owner
authority before edit.

## Frozen initial projection

- HEAD: 317fbfa66738eac21994abd824d9eda49ad70e0e
- Initial tracked/staged/untracked state: empty / empty / empty
- Tracked tree: 1256 paths
- Protected projection: 1249 paths
- Protected aggregate SHA-256:
  fd0a1121469a4e50b88a57c729c26ef7544780e77be4c0b8b30a19992c4dba1b
- Platform-production projection: 75 paths
- Platform aggregate SHA-256:
  dd9cd1dc6bb537165f5575d47f3a6752e1d12958aa54dffe9102f6a4d5721d25
- Pubspec/lock aggregate SHA-256:
  ab37300ba9523a3c43ebed3b91b026d682ce961ef3b3cecf2063d54e10665b24
- mobile/pubspec.yaml blob:
  db98edf573813302a0b1be5f763abfa562f96825
- mobile/pubspec.lock blob:
  0ca1109b3b029510e41c13e930bda79578fe05be

## Source-level verification only

1. Format touched Dart files.
2. Run exactly one final flutter analyze --no-pub.
3. Verify exact 12-path allowlist and protected drift.
4. Run git diff --check.
5. Verify schema 17, backup format 1 and version 0.1.0+1.
6. Verify pubspec/lock drift 0 and platform-production drift 0.

Do not run Flutter tests, APK/AAB build, emulator/ADB/device operations,
scripted UI acceptance, install, launch or package clear. If the single analyzer
reports any lint/style issue, fail closed without an implicit retry.

## Publication boundary

Only all-PASS source gates permit IMPLEMENTED — MANUAL TEST PENDING, one
minimal intentional commit, normal push, one Draft PR, Issue/PR evidence and
MT-483 manual-test registration in #479. Ready, merge, Issue close, V2.7
completion, Epic checkbox and V2.8 remain forbidden.

## Implementation and source-level verification

The protected Agenda/Reminder domain, application and schema were audited
read-only. The implementation uses only the exact
`field_observations.id → follow_up_items.observation_id` relationship and
append-only `follow_up_events`; it does not infer, repair or mutate links.

Implemented within the authorized boundary:

- immutable Work Chain root/follow-up/event/result/diagnostic models;
- a read-only SQLite application with Agenda-log and follow-up entry points that
  converge on one canonical chain;
- deterministic follow-up/event ordering and typed project/source/sequence/
  terminal-projection diagnostics;
- a read-only Turkish detail UI with source IDs, lifecycle, archive/trash and
  exact result visibility;
- the narrow Daily Log stable source-ref action and bootstrap wiring;
- current ROADMAP/V2 scope truth-sync plus factual decision/changelog records.

Touched Dart formatting completed. The exactly one authorized final
`flutter analyze --no-pub` invocation passed with `No issues found`.
No Flutter test, APK/build, ADB/device or scripted acceptance was run.

## Owner correction — comment 5399511793

Correction resumed from published head
`232522a6816b6c326d916ccacd15d77a06e255e2` with a clean worktree and
staged path count 0. Owner authority added only
`mobile/lib/application/daily_log_application.dart` as the thirteenth allowed
path; the original twelve-path boundary otherwise remains unchanged.

The narrow correction projects `follow_up_items.observation_id` into the Daily
Log reminder entry only when that explicit Agenda root exists. Daily Log now
exposes the Work Chain action for a reminder only when the same entry carries
that Agenda root; independent, Attendance and Concrete reminders keep no false
Work Chain action. A valid Agenda root with zero follow-ups is a normal empty
chain and no longer produces `followUpMissing`. Diagnostic UI displays the exact
safety copy:

- `Bağlantının bir kısmı okunamadı.`
- `Kaynak kayıt değiştirilmedi.`

Touched Dart formatting completed with 0 formatter changes. The exactly one
authorized correction `flutter analyze --no-pub` invocation passed with
`No issues found! (ran in 5.3s)`. No Flutter test, APK/build, ADB/device or
scripted acceptance was run.
