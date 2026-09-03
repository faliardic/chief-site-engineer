# Issue #604 — Inventory Spatial v1 Slice 7 Phase A

## Current recovery correction authority

- Owner authority: https://github.com/faliardic/chief-site-engineer/issues/604#issuecomment-5529011635
- Resume confirmed original branch/head, master/origin `0/0`, no open PR or
  in-progress Git operation, and exactly the four preserved changed paths.
  Prior backup production/test SHA-256 values match the first correction result.
- Exact current write allowlist: `.cse/tasks/604_task.md`,
  `.cse/results/604_result.md`,
  `mobile/lib/application/mobile_backup_application.dart`,
  `mobile/test/mobile_backup_application_test.dart`,
  `mobile/lib/application/restore_recovery_application.dart`,
  `mobile/test/restore_recovery_application_test.dart`.
- Correct only Inventory ownership and required file enumeration in recovery
  active-state validation. Preserve generic/legacy filters, graph failures,
  physical identities, restore lifecycle, schema/format/version and all existing
  end-to-end assertions. Add direct healthy/missing/corrupt recovery evidence.
- Reuse unchanged schema/application/asset/gateway PASS evidence. Run exactly
  once: `flutter test --no-pub test/mobile_backup_application_test.dart test/restore_recovery_application_test.dart`.
  Retry `0`; FAIL stops. PASS permits one analyzer invocation, scope/protected
  checks and one commit/push/Draft PR, then STOP for independent CRITICAL review.
- Execution time budget: 25 minutes from 2026-09-03 16:46 UTC, deadline 17:11 UTC.
  Requested model/reasoning: `gpt-5.6-sol` / `max`; actual runtime metadata:
  `unknown`. All device/Phase B/Ready/merge/closure/DWG boundaries remain closed.

## First narrow correction authority (historical)

- Owner correction: https://github.com/faliardic/chief-site-engineer/issues/604#issuecomment-5528949585
- Resume verified on the original branch/head with exactly the three preserved
  Phase-A changed files, empty index, master/origin `0/0`, no open PR or
  in-progress Git operation. No reset/clean/stash or branch recreation.
- Current exact write allowlist supersedes the original Phase-A list below:
  `.cse/tasks/604_task.md`, `.cse/results/604_result.md`,
  `mobile/test/mobile_backup_application_test.dart`,
  `mobile/lib/application/mobile_backup_application.dart` only.
- Correction: include Inventory photo relations in backup creation and manifest
  validation, with DISTINCT managed physical metadata and unchanged generic
  legacy filters. No schema/format/version or restore/lifecycle change.
- Existing test SHA-256 before correction:
  `aa81bee1e2b3697d930fda6823d3a6cea7ab1ea30399bb11b16485e7743d9d09`.
- One new invocation of the original five-file gate is authorized; retry `0`.
  On PASS, one analyzer invocation and exact scope/protected checks precede one
  commit, normal push and Draft PR. Publication stops for independent CRITICAL
  review. Scope/Roadmap files are read-only under this correction authority.
- Execution time budget: 30 minutes, starting 2026-09-03 16:40 UTC; deadline
  17:10 UTC. Requested model/reasoning remain `gpt-5.6-sol` / `max`; actual runtime
  model/reasoning remain unavailable (`unknown`).

## Original Phase-A authority (historical)

- Authority: https://github.com/faliardic/chief-site-engineer/issues/604#issuecomment-5528250533
- Parent: #506; Phase A persistence verification only.
- Exact base: `d64b96ea5d1192f46c2c33197d03d90ef1245193`.
- Official repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`.
- Branch: `codex/issue-604-inventory-slice7-closure`.
- Preflight: clean tracked/staged/untracked status; master/origin divergence `0/0`; GitHub master equals base; no in-progress Git operation or open PR.
- First repository file write: this task record.
- Execution time budget: 45 minutes, starting 2026-09-03 16:27 UTC; deadline 17:12 UTC.

```yaml
model_routing:
  lane: CRITICAL
  requested_model: gpt-5.6-sol
  requested_reasoning: max
  actual_model: unknown
  actual_reasoning: unknown
  review_floor: CRITICAL
assistant_reasoning_recommendation: Max
```

## Read authority

Current AGENTS.md, Issue #604 and its authority comment, Inventory Map v1
contract, Project Instructions, Minimum Validation, Workflow Acceleration and
Model Routing were read before branching. Current GitHub authority controls
over historical slice/status references in the contract. Scope and Roadmap are
truth-sync targets, not authority to start another slice.

## Exact seven-path write allowlist

1. `.cse/tasks/604_task.md`
2. `.cse/results/604_result.md`
3. `mobile/test/inventory_schema_migration_test.dart`
4. `mobile/test/mobile_backup_application_test.dart`
5. `mobile/test/inventory_attachment_gateway_test.dart`
6. `docs/v2/CSE_V2_SCOPE.md`
7. `ROADMAP.md`

## Execution and stop boundary

Audit existing executable persistence/migration/attachment coverage first.
Reuse valid assertions; add only minimal test coverage for an unproven Inventory
photo-link and managed bytes/path/size/hash round-trip. Production, storage,
schema, backup, platform, package, signing and other test sources are read-only.

Run exactly once from `mobile`, after final test edits/format:

```text
flutter test --no-pub test/inventory_schema_migration_test.dart test/mobile_backup_application_test.dart test/inventory_attachment_gateway_test.dart test/inventory_application_test.dart test/inventory_asset_core_test.dart
```

If FAIL, stop without retry or source fix. If PASS, run `flutter analyze --no-pub`
once; verify diff whitespace, exact allowlist/protected drift and unchanged
schema `22`, backup format `1`, mobile version `0.1.0+1`. Record actual results
and truth-sync only owner-resumed Slice 7 Phase A. On PASS, one minimal commit,
normal push and Draft PR with `Refs #604` and `Refs #506`; stop for independent
CRITICAL review.

Any production defect, unexpected drift, new path, integrity failure or budget
expiry stops execution. Phase B/device/APK/ADB/MAIN/prod/debug/legacy mutation,
real-user restore, uninstall/clear-data, toolchain changes, Ready/merge/Issue
closure and DWG work are not authorized. Field acceptance remains pending.
