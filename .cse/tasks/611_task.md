# Issue #611 — DWG Conversion Provider Boundary Task

## Authority and start state

- Issue: `#611` (`DWG-003 — Provider-independent conversion boundary and result contract`)
- Parent: `#523`
- Predecessor: `#609`, merged through PR `#610`
- Exact base: `805bbf3f65d6ee5a4092dfb76ffdc7386a81ccd6`
- Branch: `codex/issue-611-dwg-conversion-boundary`
- Lane: `CRITICAL` — conversion fidelity, source integrity, diagnostics, and future cache identity contract
- Execution time budget: 25 minutes

## Objective

Define a provider-independent conceptual `DwgConversionPort` request/result boundary that:

1. binds conversion to an exact immutable original DWG identity and SHA-256;
2. returns only a validated true vector PDF as a usable success artifact;
3. locks `SUCCESS`, `SUCCESS_WITH_WARNINGS`, and `FAILED` result semantics;
4. locks a minimum stable provider-neutral diagnostic taxonomy;
5. exposes artifact integrity, page, source-binding, converter, format-version, and generated-at provenance;
6. preserves honest measurement-readiness evidence without inventing unit, scale, transform, or trust;
7. supplies the provenance needed for later deterministic cache identity; and
8. avoids making whole-source or whole-result RAM materialization part of the application contract.

This task is documentation-only. It does not implement conversion, storage, schema, cache, rendering, transport, or measurement behavior.

## Canonical inputs

- `AGENTS.md`
- GitHub Issue `#611`
- GitHub parent Issue `#523`, including its current execution addendum
- `docs/v2/CSE_DWG_VIEWER_V1_CONTRACT.md`
- `docs/v2/CSE_DWG_EXISTING_FILE_ARCHITECTURE_AUDIT.md`
- `docs/v2/CSE_PRODUCT_RELEASE_DECISIONS_2026-08-30.md`

## Contract questions

- What exact immutable source binding crosses the port?
- What metadata is mandatory for a usable vector-PDF result?
- Which invariants separate clean success, warning-bearing success, and failure?
- How are source, transport, provider, conversion fidelity, measurement readiness, operation, and output validation failures distinguished without vendor leakage?
- Which inputs let DWG-007/008 later derive and invalidate a deterministic cache key?
- How does the boundary remain compatible with large-file streaming while current CSE ingestion remains 20 MiB/full-byte?

## Write allowlist

Exactly these paths may change:

- `.cse/tasks/611_task.md`
- `.cse/results/611_result.md`
- `docs/v2/CSE_DWG_CONVERSION_PROVIDER_BOUNDARY.md`

Any fourth path, production/test/schema/backup/platform/pubspec edit, real provider choice, cloud/local decision, PDF renderer choice, storage/schema/cache implementation, real-DWG access, or current product-contract conflict is a stop condition.

## Routing and publication contract

```yaml
routing:
  lane: CRITICAL
  task_shape: documentation_contract
  reasoning_target: extra_high
  independent_review_required: true
  ready_merge_owner_gated: true
```

After validation, publish one minimal commit by normal push and open one Draft PR to `master` with `Closes #611` and `Refs #523`. Ready, merge, Issue closure, and implementation remain outside this execution.

## Validation contract

- Exact consistency with DWG-001 immutable-source/vector-output/measurement-ready rules
- Exact consistency with DWG-002 identity, 20 MiB/full-memory, backup, and cache findings
- No vendor, cloud/local, PDF renderer, schema, cache root, or dependency selection
- Exact three-path changed-file set
- Production/test/schema/backup/platform/pubspec drift: zero
- `git diff --check`
- No test, analyzer, build, APK, device, or real-DWG execution
