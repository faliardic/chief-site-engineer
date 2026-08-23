# Issue #474 Task — Read-only Downstream Dependency Impact Core

## Authority and routing

- Repository: `faliardic/chief-site-engineer`
- Issue: `#474`; parent Epic: `#385`; V2 item: `V2.5`
- Authority: `https://github.com/faliardic/chief-site-engineer/issues/474#issuecomment-5384117949`
- Base: `9fc53da006689ff4c1e5e5c8a134cef3f35e8e77`
- Branch: `codex/issue-474-downstream-dependency-impact`
- Worktree: `V:\1_PROJECTS\2_ACTIVE\Python\CSE-Worktrees\issue-474-downstream-dependency-impact`
- Policy/risk: `CSE-MRP-1.0 / R4`
- Requested orchestrator/executor: `gpt-5.6-sol / max`
- Execution/orchestration: `standard / single-agent`
- Allowed fallback: `null`; fail closed on visible mismatch
- Review floor: `gpt-5.6-sol / max`
- Runtime metadata hidden: record `unknown / null / unverified`; do not guess
- Validation class: `domain`; target/hard stop: `45/75 minutes`

## Preflight

- Exact root/branch/head: PASS; staged: `0`; initial status: clean
- `master == origin/master == base`; divergence: `0 0`
- Issue #472 closed; no parallel open production PR
- Protected projection: every tracked path outside the allowlist, sorted
  `path<TAB>lowercase SHA-256`, LF plus final LF
- Protected count/SHA-256:
  `1232 / 98ebe86acd5c3e538d770edeb506c6fdf8383b8d8f2076a78562c9bf97a5da6b`
- This file is the first local project-file edit.

## Contract

Create a pure deterministic read-only impact engine from the exact bound
forecast, exact immutable snapshot, and exact persisted dependency graph.
For each downstream activity recompute every incoming constraint:

```text
projectedStart = max(referenceStart, all incoming candidate starts)
```

Only later starts are impacted; never pull earlier. Recompute finish with the
exact reference duration/calendar. Source effective start remains reference
start; only positive-delay forecast finish becomes effective finish, so a
source outgoing SS edge cannot shift from finish delay alone.

Fail closed on project/snapshot/provenance/reference mismatch, missing or
duplicate source, count/SHA mismatch, orphan endpoint, duplicate edge key,
self-edge, or cycle. Never rebind a legacy snapshot to a current/newer graph.
Produce deterministic topological immutable results and basis:
`SOURCE_FORECAST_UNAVAILABLE`, `NO_POSITIVE_SOURCE_DELAY`,
`SOURCE_DELAY_NO_DOWNSTREAM_SHIFT`, or `DOWNSTREAM_DELAY_PROJECTED`.

## Exact allowlist

1. `mobile/lib/domain/construction_living_plan_dependency_impact_models.dart`
2. `mobile/lib/application/construction_living_plan_dependency_impact.dart`
3. `mobile/lib/application/construction_schedule_date_engine.dart`
4. `mobile/test/construction_living_plan_dependency_impact_test.dart`
5. `mobile/test/construction_schedule_date_engine_test.dart`
6. `ROADMAP.md`
7. `docs/v2/CSE_V2_SCOPE.md`
8. `docs/project_decisions.md`
9. `CHANGELOG.md`
10. `.cse/tasks/474_task.md`
11. `.cse/results/474_result.md`

A 12th path requires stop before edit. Storage, snapshot repository/dependency
models, Living Plan/forecast core, UI, graph/corpus, pubspec/lock, platform,
backup, acceptance, attachment/notification/release/store paths are protected.

## Required tests and validation order

Focused impact tests cover exact/wrong bindings; source/provenance/count/SHA/
endpoint/edge/cycle integrity; unavailable/zero/early/positive-zero-edge bases;
FS chain/branch; multiple predecessors non-controlling and controlling;
unrelated nodes; source SS; shifted downstream SS; lag/weekend/holiday;
working/calendar-day successors; duration preservation; edge-order/repeat
determinism; input/list immutability; and no mutation.

1. Expose/reuse the existing pure dependency-candidate helper unchanged.
2. Implement models/engine; format changed Dart only.
3. Focused date-engine test.
4. Focused impact test.
5. `flutter analyze --no-pub`.
6. Diff/allowlist/protected/schema17/backup1/version0.1.0+1/pubspec-lock/platform.
7. Only all PASS: exactly one `flutter test --no-pub`.

Each failed focused/analyze/full gate allows at most one exact correction and
one retry. No APK/ADB/device/build.

## Out of scope and publication

No database/storage write, Living Plan/reference/forecast mutation, event/
receipt, new snapshot, UI, actual quantity, multiple-live aggregation,
productivity learning, recovery, baseline/critical-path/float, Gantt, AI,
notification, release/store, schema/backup/version change, Item 5 completion,
or successor work.

After every gate PASS: minimal intentional commit(s), normal push without
force/amend/rebase, exactly one Draft PR, exact Issue+PR evidence, then stop for
independent review. No Ready, merge, Issue close, or successor.
