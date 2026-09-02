# Issue #586 — Inventory edge controls and portrait editor

- Repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`.
- Owner authority: current chat request and https://github.com/faliardic/chief-site-engineer/issues/586.
- Base/master: `415316a9cc2dfe76ff71098841ae369c864bf5b6`; master/origin divergence `0 0`; clean initial worktree/index.
- Branch: `codex/issue-586-inventory-edge-controls`; Draft PR target `master`.
- Process lane: CRITICAL / R4 (platform orientation lifecycle); validation class narrow-ui with explicit orientation/gesture gates.
- Goal: left view rail, grouped right tool rail, bounded textual panels, exact editActive corner action, portrait editor and 600 ms gesture-idle hide/show without viewport mutation.
- All issue-body locked values, callbacks, safety surfaces and protected contracts remain binding.
- Exact allowlist: this task; `.cse/results/586_result.md`; `mobile/lib/features/inventory/{inventory_page,inventory_map_view,inventory_sketch_editor_page}.dart`; `mobile/test/{inventory_page_test,inventory_sketch_editor_test}.dart`; conditional `mobile/test/inventory_asset_core_test.dart` only for direct interaction-callback coverage; `docs/v2/CSE_INVENTORY_MAP_V1_CONTRACT.md`.
- Protected: PR #536; app.dart; #537 autosave/receipt/finalize correctness; #556 session adoption; domain/application/storage/schema/migration/backup/identity/clustering/quick-create/target-selection/attachments; dependency/package/permission/platform files.
- No reset/stash; no tenth path; no full suite/build/APK/AAB/emulator/device/ADB/MAIN; no Ready/merge/closure.
- Format changed Dart before one focused gate: `flutter test --no-pub test/inventory_page_test.dart test/inventory_sketch_editor_test.dart test/inventory_asset_core_test.dart`.
- Only after focused PASS: one `flutter analyze --no-pub`; then diff/allowlist/protected drift and invariants `22 / 1 / 0.1.0+1`.
- Correction ceiling: one same-scope blocking correction per minimum-validation protocol; no blind retry or analyzer rerun; any unresolved failure stops publication.
- Implementation/validation time budget: target 20–30 minutes, hard stop 45 minutes; no scope expansion on expiry.
- PASS publication: minimal implementation/evidence commit, normal push, Draft PR, independent R4 review stop. Manual MT-586 tests remain PENDING in #479.

```yaml
model_routing:
  policy_version: CSE-MRP-1.0
  task_risk: R4
  requested_model: gpt-5.6-sol
  requested_reasoning_effort: max
  execution_mode: standard
  orchestration: single-agent
  routing_request_evidence: https://github.com/faliardic/chief-site-engineer/issues/586
  selection_reason: Editor orientation and map-gesture lifecycle with protected durable draft behavior.
  allowed_fallback: null
  review_floor: gpt-5.6-sol / max / independent R4
  actual_model: unknown
  actual_reasoning_effort: unknown
  invocation_evidence: null
  invocation_verification_status: unverified
  runtime_verification_status: unverified
  mismatch_detected: null
  fail_closed_if_mismatch: true
```

## Execution stop

See `.cse/results/586_result.md`: both focused invocations returned 129/130 with the same new dialog-bound assertion failure. The sole correction attempt failed before applying due to the agent's wrong command directory; the test sequence was not gated and repeated unchanged content. No further correction/test/analyzer/publication was performed. Preserve local changes for a narrowly authorized continuation.
