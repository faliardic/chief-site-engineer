# Issue #417 — V2.3a canonical Attachment/Medya preflight

- Issue: `#417`
- Parent Epic: `#385`
- V2 item: `V2.3 — Attachment / Fotoğraf / Medya V2`
- Source inventory: `#385 / issuecomment-5231823605`
- Previous closure: `V2.2 / PR #416`
- Official repository:
  `V:\\1_PROJECTS\\2_ACTIVE\\Python\\chief-site-engineer`
- Linked worktree:
  `C:\\Users\\Fatih\\AppData\\Local\\CSE-Worktrees\\issue-417`
- Exact base: `origin/master` /
  `b117ab9ae41da1c486671c33d81e3ab9fde7ca59`
- Branch: `codex/issue-417-v2-3a-attachment-media-preflight`
- Codex model: current strongest full Codex model
- Reasoning: `Extra High`; this preflight defines the identity, migration,
  lifecycle, integrity and backup boundary for all executable V2.3 children.
- Validation class: `docs / persistence preflight`

## Execution mode

This task is contract/evidence-only. Inspect the repository and existing tests
read-only, then record factual preflight evidence. Do not change production,
schema, migration, application, UI, platform, manifest, dependency or test
source. If current evidence cannot support a deterministic contract, stop and
report the exact gap instead of broadening scope.

## Changed contracts

No production contract changes in this Issue. The preflight must define the
candidate and executable-child boundaries for:

- physical binary identity separate from contextual link identity;
- schema-12 Agenda/Concrete legacy row migration;
- supported, deferred and projection-only target types;
- project-scope and cross-project fail-closed validation;
- shared-byte archive, unlink, restore, retention and delete semantics;
- integrity/reconciliation result categories;
- multi-file/multi-link atomicity and compensation;
- next-schema need and backup format-1 compatibility;
- persistence-first sequencing before picker/viewer/player or recording work.

## Authorized changed-file allowlist

- `.cse/tasks/417_task.md`
- `.cse/results/417_result.md`

No production or executable test source is authorized. A missing
characterization contract is a stop condition and requires an exact Issue
authorization before any test edit.

## Required source inventory

Record exact file, table, column, class/symbol and test references for:

- Agenda and Concrete attachment database metadata;
- managed directories, staging/finalized paths and path-safety checks;
- picker and device stores;
- Agenda/Concrete application transactions and compensation;
- Agenda, Reminder and Concrete UI/viewer projections;
- backup manifest, database inventory, restore audit and swap/rollback;
- current characterization, schema-migration and backup tests;
- historical PC managed-store/reconciliation concepts, without treating the
  PC schema as mobile source-of-truth.

## Required result matrices

`.cse/results/417_result.md` must include:

1. exact current inventory and binary/link graphs;
2. canonical binary and link identity proposal;
3. legacy Agenda/Concrete field-by-field migration matrix;
4. target support/project-scope matrix;
5. lifecycle/retention/delete matrix;
6. integrity/reconciliation result matrix;
7. atomicity/compensation matrix;
8. schema-12 to next-schema decision and rationale;
9. backup format-1 compatibility matrix;
10. verified V2.3 child sequence;
11. first executable child exact allowlist, focused tests and stop conditions.

## Reused evidence

- PC attachment foundation: PR `#76` — conceptual staging/reconciliation only.
- Mobile Agenda slice: PR `#182`.
- Concrete attachment/evidence slice: PR `#188`.
- Mobile backup/restore: PR `#190`.
- Agenda attachment metadata/UI regressions: PR `#197`.
- Reminder source-photo projection: PR `#231`.
- V2.2 closure/base: PR `#416` /
  `b117ab9ae41da1c486671c33d81e3ab9fde7ca59`.

These are source pointers, not permission to assume unverified behavior.

## Validation

- exact two-file task/result allowlist;
- Markdown and internal consistency review;
- `git diff --check`;
- protected production/test/schema/workflow path diff is empty;
- original dirty worktree tracked state remains unchanged;
- no real user data, backup, report or attachment binary is read.

Focused Flutter/Python tests, analyze, build, release and device gates are not
run because tracked executable source is unchanged and current tests are only
inspected as characterization evidence.

## Retry and time budget

- Primary run: `1`.
- Blocking correction: at most `1`, only with exact GitHub authorization.
- Same failed operation: at most `1` retry after an exact fix.
- Target: `45 minutes`.
- Hard stop: `75 minutes`.

## Safety and protected scope

- Original dirty official worktree remains read-only with its existing four
  tracked changes; do not enumerate or read untracked contents.
- Do not touch `device-backups/`, `reports/`, backup/user data or old build
  output areas.
- No reset, clean, stash, restore, checkout, delete, overwrite or force push.
- No schema bump, migration/backfill, store/application/UI rewrite, dedupe,
  cleanup, user-file scan, format bump, permission/privacy or V2.4 work.

## Stop conditions

Stop without implementation for legacy ID/path/context loss; ambiguous
dedupe/merge; unsafe shared-byte lifecycle; unresolved format-1 conflict;
real-user-file access need; cross-project fail-closed ambiguity; production or
test edit need; schema bump implementation need; or permission/recording scope.

## Publication

After the evidence and all documentation gates pass, create one evidence-only
commit, normal push and a Draft PR containing `Closes #417`. Do not mark Ready,
merge, start V2.3b or change Epic #385. Detailed completion evidence goes to
Issue #417; chat output remains the Issue/comment reference.
