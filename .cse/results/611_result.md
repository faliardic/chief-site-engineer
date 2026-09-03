# Issue #611 — DWG Conversion Provider Boundary Result

## Outcome

`PASS — PROVIDER-INDEPENDENT CONTRACT DOCUMENTED; INDEPENDENT CRITICAL ARCHITECTURE REVIEW PENDING`

Primary output: `docs/v2/CSE_DWG_CONVERSION_PROVIDER_BOUNDARY.md`

The contract defines a conceptual `DwgConversionPort` without choosing a converter, vendor, cloud/local mode, PDF renderer, schema, cache root, transport, or dependency. It binds conversion to an immutable source identity/hash/revision and allows only a validated true vector PDF to cross as a usable result.

## Locked boundaries

- Request: exact physical source reference/identity, SHA-256, byte size, future stable DWG document/revision placeholders, original filename as metadata only, requested conversion-format version, optional provider-neutral layout policy, deadline, and cancellation.
- Results: explicit `SUCCESS`, `SUCCESS_WITH_WARNINGS`, and `FAILED` invariants; partial or unvalidated output cannot silently become success.
- Artifact: read-only reference/stream/bytes abstraction, true-vector confirmation, PDF size/SHA-256, positive page count, page/layout metadata where available, exact source echo, converter identity/version, conversion-format version, and generated-at provenance.
- Diagnostics: stable provider-neutral codes with severity/domain, including source corruption/version/hash, transport/provider/converter failure, missing XREF/font, unsupported entities, layout/fidelity uncertainty, unavailable unit/scale/transform, timeout/cancel, and output validation failure.
- Measurement: evidence-only metadata with `EVIDENCE_AVAILABLE`, `CALIBRATION_REQUIRED`, or `UNAVAILABLE`; no invented unit, scale, transform, or port-granted `TRUSTED` state.
- Cache compatibility: `source SHA-256 + exact source revision + converter identity + converter version + conversion-format version`.
- Size/memory: the current 20 MiB/full-byte ingestion model is recorded, but the port permits stream/file/spool references and does not require whole-source or whole-result RAM materialization.

## Scope and validation

- Changed paths: exactly the three Issue #611 allowlisted documentation/provenance paths.
- Production/test/schema/backup/platform/pubspec drift: zero.
- DWG-001/DWG-002 and locked release-decision consistency: PASS.
- Vendor/cloud/local/renderer/schema/cache-root/dependency selection: none.
- `git diff --check`: PASS.
- Test/analyzer/build/APK/device/real-DWG execution: intentionally not run.
- Schema `22`, backup format `1`, and mobile version `0.1.0+1`: unchanged read-only facts.

## Publication state

- One minimal documentation commit and normal branch push are authorized after final scope checks.
- Draft PR body must contain `Closes #611` and `Refs #523`.
- Independent CRITICAL architecture review is pending on the Draft PR.
- Ready, merge, and Issue closure remain owner-gated.
