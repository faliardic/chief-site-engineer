# Issue NNN Task

## Objective

Describe one bounded, reversible outcome.

## Process Lane

- Process lane: `<FAST|STANDARD|CRITICAL>`
- Review level: `<R1/R2|R3|R4/R4+>`
- Why this lane: `<one sentence>`

Use the lightest lane that safely covers the changed contract. Ordinary UI/context/navigation work must not default to CRITICAL/R4.

## Context

- Parent Epic / roadmap item: `<issue/item>`
- Depends on: `<issues/merged contracts or none>`
- Canonical scope: `docs/v2/CSE_V2_SCOPE.md`
- Roadmap: `ROADMAP.md`

## Repository

- Repository: `faliardic/chief-site-engineer`
- Base branch: `master`
- Expected base commit: `<sha>`
- Working branch: `<codex/issue-NNN-slug|docs/issue-NNN-slug>`
- Official local working directory: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`

## Required Sources

1. `AGENTS.md`
2. `docs/protocols/CSE_WORKFLOW_ACCELERATION_PROTOCOL.md`
3. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
4. `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
5. current GitHub Issue / PR / branch
6. `ROADMAP.md`
7. relevant Issue #479 manual-test entries

Read deeper protocol/source files only when the changed contract needs them. Resume does not reread unchanged long sources.

## Goal / Changed Contract

- Goal: `<one paragraph>`
- Changed contract(s): `<list>`
- User-visible result: `<list>`

## Allowed / Protected Paths

Allowed:

- `<exact path or bounded group>`

Protected:

- `<critical paths/contracts>`

If another path is required, stop only when the need is a real scope/critical escalation. Same-scope format/harness/analyzer/source corrections stay inside the current execution window.

## Critical Exclusions

- Schema/migration: `<none|details>`
- Backup/restore: `<none|details>`
- Permission/signing/platform: `<none|details>`
- User-data/destructive access: `<forbidden|explicit boundary>`
- Inventory/DWG/release impact: `<none|details>`

Any newly discovered CRITICAL trigger requires escalation.

## Local Checks

### FAST default

- exact scope/allowlist
- changed-path diff review
- deterministic format/syntax
- `git diff --check`
- protected drift

### STANDARD default

FAST checks plus at most one targeted local check only when materially useful.

Do not duplicate the full Flutter format/analyze/test chain locally when PR CI will run it.

### CRITICAL

List issue-specific focused/integration/device/release gates:

- `<gate>`

## PR CI Expectation

For mobile changes, existing `Flutter PR` CI is the broad gate:

```text
format
flutter analyze
full flutter test
```

CI failure is handled as one same-scope correction round where possible; no new owner authority is required for each failure.

## Manual Test Register

- Register: GitHub Issue #479
- IDs: `<MT-NNN-001... or pending creation>`
- Status: `<PENDING|PASS|FAIL|PARTIAL|DEFERRED|N/A>`

Manual test PENDING/DEFERRED does not automatically block continued development or owner-approved merge.

## Correction Budget

FAST/STANDARD default:

```text
primary implementation: 1
same-scope correction rounds: 2
environment-only retry: 1
new owner authority inside same scope: 0
```

CRITICAL may define a custom bounded budget.

## Required Work

1. `<action>`
2. `<action>`

## Out of Scope

- `<explicit non-goals>`
- no unrelated product/schema/backup/release expansion

## Publication Boundary

- Commit: `<allowed|not allowed>`
- Push: `<allowed|not allowed>`
- Pull request: `<Draft required|not allowed>`
- Ready: `owner approval required`
- Merge: `owner approval required; squash default`

FAST/STANDARD Issue body + standing protocol are sufficient execution authority. Do not add a separate one-shot authority unless a real escalation occurs.

## Completion Evidence

Keep evidence concise.

FAST/STANDARD preferred summary:

```yaml
issue: NNN
process_lane: FAST|STANDARD
base: <sha>
head: <sha>
changed_paths: [...]
local_checks: [...]
ci: PASS|FAIL|PENDING
manual_tests: PENDING|...
corrections_used: 0..2
pr: <number>
```

CRITICAL may use full provenance chronology.

## Completion Criteria

- changed contract is implemented;
- scope/protected boundaries are preserved;
- local minimum checks pass;
- Draft PR is published when authorized;
- PR CI state is recorded;
- manual test status is truthful;
- no unrelated changes;
- next roadmap item is not started before current publication/review boundary is respected.
