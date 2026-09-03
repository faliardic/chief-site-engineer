# CSE DWG Conversion Provider Boundary

- Status: Issue #611 canonical architecture contract for DWG-003
- Base: `805bbf3f65d6ee5a4092dfb76ffdc7386a81ccd6`
- Parent: Issue #523
- Governing contract: `docs/v2/CSE_DWG_VIEWER_V1_CONTRACT.md`
- Architecture evidence: `docs/v2/CSE_DWG_EXISTING_FILE_ARCHITECTURE_AUDIT.md`

## 1. Purpose and authority

This document defines the provider-independent application boundary conceptually named `DwgConversionPort`. It locks what a conversion request means, what a usable result must prove, and how warnings and failures cross into CSE without binding application/domain code to a converter vendor, executable, SDK, REST API, cloud provider, or local runtime.

This boundary is an architecture contract, not an implementation or technology-selection record. It does not prove that real DWG conversion is viable. DWG-004 owns that real-file technology spike and go/no-go decision.

The governing lifecycle remains:

- original DWG bytes are immutable durable source-of-truth;
- a derived true vector PDF is disposable and reproducible;
- conversion failure, cancellation, timeout, or cleanup can never mutate, replace, unlink, or delete the original;
- the derived artifact is not adopted as durable source truth; and
- first general release remains viewer-only plus measurement-ready architecture, while real two-point measurement is a later, release-nonblocking phase.

## 2. Port responsibility and ownership

The conceptual operation is:

```text
DwgConversionResult convert(DwgConversionRequest request)
```

The notation does not prescribe a programming language, synchronous/asynchronous API, process boundary, or transport. A conforming adapter must:

1. resolve a caller-supplied immutable source reference for read-only access;
2. bind the bytes actually converted to the expected source SHA-256 and exact source revision identity;
3. honor the architecture-level deadline and cancellation signal;
4. produce and validate a true vector PDF or return typed failure;
5. return stable provider-neutral diagnostics and complete success provenance;
6. expose measurement evidence only when the provider supplies it honestly; and
7. relinquish or clean up only its partial/temporary derived outputs, never the source.

The caller retains ownership of the original. A returned artifact reference has a defined read-only handoff lifetime but does not imply cache adoption, durable storage, or backup inclusion. DWG-007/008 will own those later decisions.

## 3. Provider-neutral request contract

`DwgConversionRequest` contains the following conceptual inputs. Names illustrate meaning; they are not database fields or SDK types.

| Input | Requirement and invariant |
|---|---|
| `requestIdentity` | Unique operation/correlation identity. It does not replace document, revision, or physical attachment identity. |
| `physicalSourceReference` | Opaque, read-only, caller-controlled handle/reference to the exact managed original. It may support file or streamed access and must not require a vendor path or raw in-memory byte array. |
| `physicalSourceIdentity` | Stable identity of the immutable physical attachment/object selected by the caller. |
| `sourceSha256` | Expected lowercase SHA-256 of the original bytes. The bytes converted must match it; mismatch fails closed. |
| `sourceByteSize` | Expected source size for integrity, limits, progress, and later spike evidence. It is not permission to impose the current 20 MiB limit on all providers. |
| `dwgDocumentIdentity` | Stable document-identity placeholder owned by the future DWG source model. |
| `dwgRevisionIdentity` | Exact immutable source-revision placeholder. It is distinct from attachment-link revision and other source-record revisions. |
| `originalFilename` | Display/diagnostic metadata only. It is not identity, authorization, a filesystem path, or a cache-key component. |
| `requestedConversionFormatVersion` | The caller's required version of CSE's derived artifact/metadata contract. It is distinct from converter version. |
| `layoutPolicy` | Optional provider-neutral request such as all available publishable layouts, model-space only, or selected named layouts. Absence or unsupported mapping must not be silently reinterpreted. |
| `deadlineOrTimeout` | Architecture-level completion bound, independent of a particular HTTP/client/process API. |
| `cancellationSignal` | Architecture-level cooperative cancellation context. Cancellation returns a typed failed result and no adoptable artifact. |

The source reference and expected identity travel together. An adapter cannot substitute a mutable path, newly fetched object, latest revision, or same-name file without detecting and reporting the identity/hash mismatch.

The request never carries a vendor token, executable path, SDK object, REST endpoint, cache path, renderer choice, or persistence row shape. Credentials and network/privacy policy belong to a separately authorized provider adapter.

## 4. Typed result algebra

Every completed call returns one and only one result status:

| Status | Required meaning |
|---|---|
| `SUCCESS` | A usable artifact is present; it passes PDF, true-vector, integrity, page-count, source-binding, and provenance validation. There are no warning or error diagnostics. |
| `SUCCESS_WITH_WARNINGS` | The same usable-artifact validations pass, and at least one structured warning is present. The caller must not downgrade or hide those warnings. No error diagnostic is allowed. |
| `FAILED` | No artifact is adoptable for viewing or caching. At least one structured error explains the failure domain. Any partial output is quarantined/cleaned as derived temporary data and cannot be surfaced as success. |

Status is not inferred from nullable fields or vendor text. These invariants apply:

- an absent, corrupt, non-PDF, raster-only, incomplete, source-mismatched, or unvalidated output cannot be `SUCCESS` or `SUCCESS_WITH_WARNINGS`;
- missing font/XREF, unsupported entities, unresolved layouts, or vector-fidelity uncertainty cannot silently become clean `SUCCESS`;
- a warning-bearing vector PDF may remain usable for ordinary viewing only when minimum output validation passes and every fidelity risk remains visible;
- a risk that prevents a trustworthy minimum drawing view is an error and therefore `FAILED`;
- measurement metadata absence alone does not make an otherwise valid viewer artifact fail; it produces the appropriate warning/readiness state; and
- cancellation and timeout are typed `FAILED` results, not thrown-away ambiguous outcomes.

Transport and provider failures are distinct from conversion/fidelity warnings through stable diagnostic domains and codes. An implementation may use exceptions internally, but it must normalize them into this result algebra before crossing the application boundary.

## 5. Successful derived-artifact contract

Both successful statuses expose one `DwgDerivedVectorPdf` concept with all mandatory provenance below.

| Field | Contract |
|---|---|
| `artifactReference` | Read-only file/stream/spool/reference abstraction with an explicit handoff lifetime. Raw `bytes` may be one adapter option, but whole-result memory materialization is not required. |
| `mediaType` | Must identify PDF. A mislabeled or non-PDF payload fails output validation. |
| `vectorValidation` | Must be `CONFIRMED_VECTOR` through the validation approach accepted by the later technology spike. Raster screenshot/image-only PDF output cannot pass. |
| `pdfByteSize` | Positive byte length of the exact returned artifact. |
| `pdfSha256` | Lowercase SHA-256 of the exact returned artifact bytes. |
| `pageCount` | Positive validated page count. |
| `pages` | Provider-neutral page descriptors where available: page identity/index, PDF page geometry, rotation, and layout/model-space association evidence. Missing mapping is diagnosed rather than invented. |
| `sourceBinding` | Exact echo of physical source identity, source SHA-256, DWG document identity, and DWG revision identity from the request. Any mismatch fails output validation. |
| `converterIdentity` | Stable provider/converter product or engine identity; not user-facing vendor prose. |
| `converterVersion` | Exact converter version/build identity capable of distinguishing output-affecting changes. |
| `conversionFormatVersion` | Version of CSE's derived artifact/metadata contract actually produced. It must satisfy the requested version. |
| `generatedAtUtc` | Unambiguous generation timestamp used as provenance, not as cache validity by itself. |
| `measurementMetadata` | Optional evidence described in section 7. It is never fabricated to complete a success result. |

The result may additionally expose duration and bounded provider execution evidence for spike/diagnostic use. Those values do not replace the mandatory integrity and provenance fields.

The exact algorithm for confirming vector content belongs to DWG-004. Until that spike accepts a validation method, no implementation may claim `CONFIRMED_VECTOR` in production merely because a file has a `.pdf` extension or PDF header.

## 6. Stable diagnostic envelope and taxonomy

Every diagnostic crosses the port in a provider-neutral envelope:

| Field | Meaning |
|---|---|
| `code` | Stable machine-readable code from the taxonomy below. A code cannot be renamed or reused for different semantics silently. |
| `severity` | `WARNING` or `ERROR`. `WARNING` implies a usable artifact can still exist; `ERROR` requires `FAILED`. |
| `domain` | `SOURCE`, `TRANSPORT`, `PROVIDER`, `CONVERSION`, `LAYOUT`, `MEASUREMENT`, `OPERATION`, or `OUTPUT_VALIDATION`. |
| `safeMessageKey` | Stable application-owned key for safe/localized UI copy; not raw vendor text. |
| `scope` | Optional bounded page/layout/entity/reference context without secrets or arbitrary local paths. |
| `providerEvidence` | Optional bounded, sanitized debug evidence such as native code/text. It never becomes branching logic or the user-facing contract. |

Minimum stable codes are:

| Code | Domain | Minimum semantics and status impact |
|---|---|---|
| `SOURCE_CORRUPT` | `SOURCE` | DWG structure is corrupt/unreadable: `ERROR`, `FAILED`. |
| `SOURCE_VERSION_UNSUPPORTED` | `SOURCE` | DWG version is unsupported: `ERROR`, `FAILED`. |
| `SOURCE_HASH_MISMATCH` | `SOURCE` | Resolved/read source does not match requested SHA-256: `ERROR`, `FAILED`. |
| `SOURCE_READ_FAILED` | `SOURCE` | Exact source cannot be read safely: `ERROR`, `FAILED`. |
| `SOURCE_SIZE_UNSUPPORTED` | `SOURCE` | Selected adapter/provider cannot safely accept this size: `ERROR`, `FAILED`; it is not a universal CSE size policy. |
| `TRANSPORT_UNAVAILABLE` | `TRANSPORT` | Required adapter transport cannot be established: `ERROR`, `FAILED`. |
| `TRANSPORT_FAILED` | `TRANSPORT` | Transfer/protocol failed before a validated result: `ERROR`, `FAILED`. |
| `CONVERTER_UNAVAILABLE` | `PROVIDER` | Converter service/runtime is unavailable: `ERROR`, `FAILED`. |
| `CONVERTER_FAILED` | `CONVERSION` | Converter reports/causes conversion failure: `ERROR`, `FAILED`. |
| `XREF_MISSING` | `CONVERSION` | One or more external references are unavailable. At least `WARNING`; use `ERROR` when minimum trustworthy view is not possible. |
| `FONT_MISSING` | `CONVERSION` | One or more source fonts are unavailable/substituted. At least `WARNING`; use `ERROR` when minimum trustworthy view is not possible. |
| `ENTITY_UNSUPPORTED` | `CONVERSION` | One or more objects/entities are unsupported. At least `WARNING`; use `ERROR` when omitted/altered content defeats minimum trustworthy view. |
| `LAYOUT_MAPPING_UNRESOLVED` | `LAYOUT` | Requested or produced page-to-layout/model-space association is unresolved. At least `WARNING`; `ERROR` if requested output cannot be identified safely. |
| `VECTOR_FIDELITY_UNCERTAIN` | `CONVERSION` | Vector/content fidelity cannot be established. At least `WARNING`; `ERROR` when the artifact cannot satisfy the viewer minimum. |
| `UNIT_UNAVAILABLE` | `MEASUREMENT` | Source unit cannot be proved. `WARNING` on an otherwise valid viewer result; never guess a unit. |
| `SCALE_UNAVAILABLE` | `MEASUREMENT` | Scale/model-to-paper relationship cannot be proved. `WARNING` on an otherwise valid viewer result; never guess scale. |
| `TRANSFORM_UNAVAILABLE` | `MEASUREMENT` | PDF-page-to-source/model transform cannot be proved. `WARNING` on an otherwise valid viewer result; never invent a transform. |
| `TIMEOUT` | `OPERATION` | Architecture deadline expired: `ERROR`, `FAILED`. |
| `CANCELLED` | `OPERATION` | Caller cancellation was honored: `ERROR`, `FAILED`. |
| `OUTPUT_MISSING` | `OUTPUT_VALIDATION` | Provider returned no candidate artifact: `ERROR`, `FAILED`. |
| `OUTPUT_NOT_PDF` | `OUTPUT_VALIDATION` | Candidate is not a valid PDF: `ERROR`, `FAILED`. |
| `OUTPUT_NOT_VECTOR` | `OUTPUT_VALIDATION` | Candidate is raster-only or cannot meet accepted true-vector validation: `ERROR`, `FAILED`. |
| `OUTPUT_INTEGRITY_INVALID` | `OUTPUT_VALIDATION` | Size/hash/readback integrity is invalid: `ERROR`, `FAILED`. |
| `OUTPUT_PAGE_METADATA_INVALID` | `OUTPUT_VALIDATION` | Page count/required page structure is invalid or contradictory: `ERROR`, `FAILED`. |
| `OUTPUT_SOURCE_BINDING_INVALID` | `OUTPUT_VALIDATION` | Result provenance does not exactly bind to the request source/revision: `ERROR`, `FAILED`. |

Adapters may add new provider-neutral codes later. They must not branch application behavior on native vendor strings, and DWG-005 may refine diagnostic fields or add codes without weakening or changing the meaning of the locked minimum codes.

## 7. Measurement-ready metadata boundary

`measurementMetadata` carries evidence for a later measurement system; it does not implement measurement or grant final trust. Where genuinely available it may preserve, per page/layout:

- layout and model/paper-space identity;
- PDF page geometry and coordinate convention;
- source coordinate convention;
- source unit plus evidence/provenance;
- viewport, plot-scale, or model-to-paper relationship plus evidence;
- PDF-page-to-source/model transform plus evidence; and
- the converter metadata version that defines those fields.

The provider boundary reports a readiness hint only:

- `EVIDENCE_AVAILABLE`: relevant metadata was returned, but downstream verification is still required before later classification as `TRUSTED`;
- `CALIBRATION_REQUIRED`: automatic unit/scale/transform cannot be proved, but later explicit user calibration may be possible; or
- `UNAVAILABLE`: reliable mapping cannot be supplied for that page/layout.

The port does not invent `TRUSTED`. It never infers unit from filename, locale, drawing convention, page size, or magnitude; never derives scale from screen pixels; and never fabricates a transform to make fields complete. Missing unit, scale, or transform produces its stable diagnostic and an honest readiness state.

Measurement evidence absence alone does not invalidate a true-vector PDF for ordinary viewing. It normally produces `SUCCESS_WITH_WARNINGS`, `CALIBRATION_REQUIRED` or `UNAVAILABLE`. If the same condition also means drawing/page fidelity cannot satisfy the viewer minimum, the adapter emits the separate fidelity/output error and returns `FAILED`.

Real two-point measurement, calibration UI, unit formatting, coordinate verification, and measurement trust classification implementation remain later work and are not first-general-release blockers.

## 8. Cache identity compatibility

The result exposes enough immutable provenance for DWG-007/008 to derive this conceptual validity tuple later:

```text
source SHA-256
+ exact DWG source revision identity
+ converter identity
+ converter version
+ conversion-format version
```

Every component participates in compatibility. A mismatch invalidates reuse; generated-at time and original filename do not make mismatched content valid. Physical source/document identity remains part of source binding even though byte/revision/converter/format inputs drive cache compatibility.

This port neither creates a cache record nor selects a cache root. Returning a valid artifact authorizes only later validated adoption; it does not change the derived PDF into durable source truth or include it in backup.

## 9. Local/cloud/provider neutrality

A future adapter may invoke a local executable/native converter, a cloud conversion service, or another provider. All must return the same request/result semantics above.

Provider adapters own their invocation details, transport mapping, native error normalization, temporary-output cleanup, and capability declarations. Application/domain code sees no CLI flags, endpoint URLs, SDK classes, vendor tokens, credential formats, or native exception strings.

This neutrality is not authorization for cloud processing. Network/offline behavior, privacy, data residency, credentials, retention, security, cost, and failure recovery must be evaluated before any cloud adapter is authorized. This document chooses neither cloud nor local execution.

PDF rendering is downstream of conversion and is not a responsibility of `DwgConversionPort`. No PDF renderer is selected or implemented here.

## 10. File-size and streaming boundary

DWG-002 proves that the current `DeviceManagedAttachmentStore` defaults to 20 MiB and that existing picker/stage APIs materialize full bytes in memory. Backup handling has additional independent entry/package limits. These are current implementation facts, not the conversion port's universal DWG limit.

The provider-neutral boundary must permit:

- read-only source handles/references that can be streamed or reopened;
- output handles/streams/spool references whose size is not required to fit in RAM;
- incremental hashing and bounded copying/validation;
- cancellation and timeout without losing the original; and
- adapter capability/size rejection through `SOURCE_SIZE_UNSUPPORTED` rather than memory exhaustion or silent truncation.

The port must not require callers to provide `List<int>`-style whole-file bytes or require results to return one whole in-memory byte array. An adapter may use bytes internally for a safely bounded file, but that is not the application contract.

Exact file-reference/stream implementation, supported size ceiling, memory profile, transfer strategy, and provider-specific limits are DWG-004 spike inputs. This document does not change the current 20 MiB ingestion limit or any backup limit.

## 11. Safety and adoption invariants

- Source access is read-only and bound to expected identity/hash/revision.
- No status permits source overwrite, deletion, relocation, unlinking, or metadata revision mutation.
- A partial candidate output is never a usable artifact or cache entry.
- Successful output always has validated true-vector status, size, SHA-256, positive page count, exact source binding, and converter/format provenance.
- `SUCCESS_WITH_WARNINGS` is visibly distinct from clean `SUCCESS` through structured diagnostics.
- Failure domain is stable even when adapter-native details differ.
- Trial/subscription state is outside conversion and cannot delete original bytes, source/revision metadata, or file links.
- The conversion boundary performs no viewer rendering, measurement UI, storage adoption, backup, entitlement, or telemetry persistence.

## 12. Explicit exclusions

This contract does not define or implement:

- converter/provider/vendor choice;
- cloud-versus-local execution decision;
- PDF renderer or viewer implementation;
- Flutter/native bridge;
- executable, REST, SDK, or credential integration;
- schema/migration or durable DWG document tables;
- exact original or derived-cache storage root;
- derived cache record, adoption, invalidation, or lifecycle;
- backup/restore changes;
- real DWG conversion or technology viability;
- exact streaming implementation or final file-size limit;
- two-point measurement, calibration, or measurement UI;
- telemetry implementation; or
- entitlement/paywall behavior.

Schema remains `22`, backup format remains `1`, and mobile version remains `0.1.0+1` as read-only facts at this contract base.

## 13. Handoff

The next exact sequence is:

1. DWG-004 — perform the real DWG to true vector-PDF technology spike and record the conversion go/no-go; do not implement schema or cache.
2. DWG-005 — refine the converter diagnostics contract using spike findings where needed without weakening this minimum taxonomy.
3. DWG-006 — define the durable DWG source record only after conversion viability is proven.
4. DWG-007 — define the derived cache record and deterministic cache identity.
5. DWG-008 — define cache adoption, invalidation, regeneration, cleanup, and restore-time lifecycle.

PDF renderer selection and implementation belong to the later viewer phase, not DWG-003 or DWG-004.
