# Issue 507 — Inventory Map v1 Slice 0 result

## Outcome

```text
DOCUMENTATION IMPLEMENTED — INDEPENDENT CONTRACT REVIEW PENDING
```

Issue #507 produced the implementation-grade canonical contract for Inventory
Map v1 and truth-synchronized current V2 product direction. It did not implement
or execute production, schema, test, build, artifact, emulator, ADB or device
behavior.

## Repository identity and start state

- Official local root: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Branch: `docs/issue-507-inventory-map-v1-contract`
- Expected and verified base:
  `1d1b818b4b630a08fe6eb77157fe92b7a460b5c3`
- `master` at start: `1d1b818b4b630a08fe6eb77157fe92b7a460b5c3`
- `origin/master` at start and pre-publication refresh:
  `1d1b818b4b630a08fe6eb77157fe92b7a460b5c3`
- Master divergence at start and pre-publication refresh: `0/0`
- Open PRs before publication: none
- Initial worktree: no tracked, staged or untracked project drift

The final commit SHA, pushed remote SHA, remote divergence and Draft PR number
cannot be embedded in their own single intentional commit. They are recorded in
the Issue/PR completion evidence and final execution report, per the repository
metadata-churn rule.

## Exact changed paths

1. `.cse/tasks/507_task.md`
2. `.cse/results/507_result.md`
3. `docs/v2/CSE_INVENTORY_MAP_V1_CONTRACT.md`
4. `docs/v2/CSE_V2_SCOPE.md`
5. `ROADMAP.md`
6. `docs/project_decisions.md`

No seventh path is required or changed.

## Canonical contract decisions

- Direct top-level shell order is
  `Başlangıç / Hatırlatıcı / Ajanda / Envanter / Puantaj / Daha`; `Daha`
  contains the existing Beton Paketi and Sicil entry points.
- Inventory is bound to one explicitly selected active project ID. Cross-project
  sketch/revision/asset/placement/photo relations fail closed.
- Normal Envanter viewing remains portrait-capable; only the editor route is
  landscape-scoped and must restore the standard orientation set on every exit,
  error and lifecycle path.
- User-visible drawing truth is always a `şematik kroki`, never CAD/measured
  truth.
- Geometry version is `1`; canvas is `4096 x 3072` (`4:3`) with inclusive
  integer bounds, sketch grid step `64`, placement quantization `4` and
  lower-multiple exact-half ties.
- Geometry uses fixed-key-order whitespace-free canonical JSON plus lowercase
  SHA-256. Limits are `64` polylines, `1024` points per polyline, `4096` total
  points and `4096` total segments.
- Sketch revision states are exactly `DRAFT`, `ACTIVE`, `SUPERSEDED` and
  `ABANDONED`; changed drafts autosave after `500 ms`. Finalized revisions are
  immutable, edit starts a new draft and physical delete is forbidden.
- Asset categories/statuses, stored positive integer total quantity, one-v1-
  placement/future-multiple invariant, history-preserving placement versions,
  append-only events and durable idempotency/no-op receipts are exact.
- `Kroki` and `Liste` derive from the same asset/active-placement records.
- Slice 4 first produces an internally usable integrated flow. Slice 6 is the
  first point that can become eligible for owner-phone MAIN installation, only
  after Issue #502 PASS for the exact data/candidate and separate authority.

## Proposed persistence plan

The later Slice 1 migration is exactly additive schema `19 -> 20` with seven
new tables:

1. `inventory_sketches`
2. `inventory_sketch_revisions`
3. `inventory_assets`
4. `inventory_asset_placements`
5. `inventory_command_receipts`
6. `inventory_events`
7. `inventory_asset_attachment_links`

Existing tables are not rebuilt, renamed, dropped or rewritten. No legacy user
row, synthetic backfill or attachment byte is created/mutated by migration.
Backup format stays `1`; later DB smoke, migration and round-trip gates must
adopt all seven tables.

Optional Inventory photos reuse `managed_attachments` and the existing managed
store. The additive Inventory link table avoids rebuilding current
`attachment_links`; catalog/album/reconciliation and backup byte queries later
union the relation and package each physical ID once. Link creation never copies
a byte merely to attach it to Inventory.

## Source inspection evidence

The task record binds the complete canonical-source blob/SHA-256 manifest. The
contract was grounded in these current source components without editing them:

- `mobile/lib/app.dart`: `MobileShell`, six destinations and `IndexedStack`;
- `mobile/lib/bootstrap/app_bootstrap.dart`: `BootstrapSuccess` and typed SQLite
  application wiring;
- `mobile/lib/storage/app_database.dart`: schema/migration transactions,
  project/location, Living Plan receipt/event, material-request event and
  attachment/link/phone-context tables/triggers;
- `mobile/lib/application/mobile_backup_application.dart`: schema preflight,
  integrity/FK, DB smoke and managed-attachment manifest queries;
- Agenda project/location applications/models;
- Material Request and Living Plan optimistic revision, replay/no-op receipt,
  transaction and append-only history patterns;
- Attachment catalog/models and `ManagedAttachmentStore`.

## Truth synchronization

- `docs/v2/CSE_V2_SCOPE.md` and `ROADMAP.md` now identify Epic #506 / Issue #507
  Inventory Map v1 as current product-development priority.
- V2.12 and later planned product work is paused by owner decision.
- Issue #497 / PR #498 is recorded as merged Slice 1 with manual tests pending;
  V2.11 completion is not claimed.
- Issue #504 / PR #505 recovery surface is recorded as merged without claiming
  Issue #501 owner recovery verification.
- P0 Issues #501, #502, #503 and #499 retain cumulative precedence for every
  owner-phone operation.
- Dynamic SHA/PR truth remains on GitHub; dated Issue #507 base evidence is
  bound in task/result rather than presented as a rolling permanent snapshot.
- No Inventory implementation, completion, verification or release claim was
  introduced.

## Documentation validation

- Exact six-path allowlist: `PASS` (`6/6`, outside `0`)
- Markdown fence balance: `PASS`
- Heading-level and duplicate-contract-heading consistency: `PASS`
- Markdown relative-link existence / external-link syntax: `PASS`
- Exact proposed table-set consistency: `PASS` (`7/7`)
- Unresolved placeholder scan: `PASS` (`0`)
- Revision-state consistency: `PASS`
- Geometry numeric consistency: `PASS`
- Outdated album-current wording scan: `PASS` (`0`)
- `git diff --check`: `PASS`
- Protected production/protocol diff: `PASS` (`0`)

Current unchanged facts verified from source:

- SQLite schema: `19`
- Backup format: `1`
- Mobile version: `0.1.0+1`
- MAIN package: `com.faliardic.sefim`
- Task-start master: `1d1b818b4b630a08fe6eb77157fe92b7a460b5c3`

## Explicitly not run or changed

- Flutter/Dart analyze: not run; not authorized
- Unit/widget/integration/full tests: not run; not authorized
- APK/AAB build: not run; not authorized
- Emulator/ADB/device/owner-phone: not run; not authorized
- Production files changed: `0`
- Test files changed: `0`
- Schema/migration code changed: `0`
- Android/iOS/platform/permission files changed: `0`
- Pubspec/lock files changed: `0`
- Protocol/`AGENTS.md` files changed: `0`
- Build/artifact count: `0`

No Inventory manual test was executed or marked PASS. The contract only defines
future child-Issue manual-test families. Existing V2.11 manual tests remain
pending; existing P0 Issues remain open.

## Publication boundary

- Publication authority: one docs-only commit, normal push and Draft PR only.
- Ready: not authorized
- Merge: not authorized
- Issue closure: not authorized
- Slice 1 implementation: not authorized
- Owner-phone install: not authorized
- Final state target: stop for independent source/contract review.

## Execution record

```yaml
execution_record:
  issue: 507
  parent_issue: 506
  task_risk: R4
  requested_model: gpt-5.6-sol
  requested_reasoning_effort: max
  runtime_actual_model: unknown
  runtime_actual_reasoning_effort: null
  runtime_match: unverified
  execution_mode: standard
  orchestration: single-agent
  base_sha: 1d1b818b4b630a08fe6eb77157fe92b7a460b5c3
  validation_class: docs
  production_code_authorized: false
  owner_phone_install_authorized: false
  publication_authority: DRAFT_ONLY
  production_files_changed: 0
  test_files_changed: 0
  builds_run: 0
  device_operations: 0
```

## Review recommendation

```yaml
review_recommendation:
  decision: INDEPENDENT_REVIEW_REQUIRED
  readiness: DRAFT_ONLY
  review_floor: gpt-5.6-sol / max
  ready_recommended: false
  merge_recommended: false
  focus:
    - geometry normalization, bounds, limits and revision compatibility
    - seven-table schema-20 project/FK/revision/event/receipt invariants
    - total quantity and history-preserving placement transitions
    - additive attachment-link and format-1 backup adoption
    - six-destination navigation and orientation restoration
    - cumulative P0 owner-phone data-safety gates
```
