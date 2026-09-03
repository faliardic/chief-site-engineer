# Issue #609 — DWG Existing File Architecture Audit Result

## Outcome

`PASS — AUDIT DOCUMENTED; INDEPENDENT CRITICAL ARCHITECTURE REVIEW PENDING`

The repository audit found a reusable secure managed-file backbone, but no as-is DWG ingestion path and no existing disposable derived-PDF cache. Original DWG support requires later extension of type/size/stream handling plus a new DWG document/revision model. Derived vector PDF requires a new backup-excluded cache boundary and regeneration identity.

Primary output: `docs/v2/CSE_DWG_EXISTING_FILE_ARCHITECTURE_AUDIT.md`

## Key findings

- `DeviceManagedAttachmentStore` supplies safe relative paths, generated physical identity, atomic staging, byte-size/SHA-256 verification, and inspection that can be reused for immutable original bytes.
- `.dwg` is currently blocked by the picker extension list, MIME magic recognition, MIME-to-extension mapping, managed final-path pattern, and a 20 MiB store limit. Full-byte picker/stage APIs make larger-file memory behavior a required spike.
- `managed_attachments` does not MIME-enum block DWG, but existing generic and Inventory link tables cannot represent a DWG document/revision lineage.
- Physical attachment identity, link identity/link revision, source-record revision, and future DWG revision identity are separate concepts and must remain separate.
- No current application root is a disposable, reproducible cache. A linked managed derived PDF would enter backup enumeration, including through an archived link.
- Backup creation includes only managed attachments referenced by generic or Inventory link relations; restore verifies the manifest and atomically replaces the database plus entire attachments root. Future original DWG adoption must extend that relation boundary; derived cache must remain outside it.
- Current audited facts remain schema `22`, backup format `1`, and mobile version `0.1.0+1`; no implementation decision changes them.

## Decision summary

| Question | Decision |
|---|---|
| Original DWG physical storage | `EXTEND_LATER` |
| Managed physical identity/integrity | `REUSE` |
| DWG metadata/link adoption | `NEW_REQUIRED_LATER` |
| Source revision model | `NEW_REQUIRED_LATER` |
| Derived vector-PDF cache root | `NEW_REQUIRED_LATER` |
| Backup inclusion/exclusion | `EXTEND_LATER` |
| Restore behavior | `EXTEND_LATER` |
| Cache regeneration | `NEW_REQUIRED_LATER` |
| Schema need | `NEW_REQUIRED_LATER` |
| Dependency/platform need | `SPIKE_REQUIRED` |

## Scope and validation

- Changed paths: exactly the three Issue #609 allowlisted documentation/provenance paths.
- Production/test/schema/backup/platform/pubspec drift: zero.
- `git diff --check`: PASS.
- Documentation/source consistency: PASS against the Issue #609 evidence set.
- Build/test/analyzer/APK/device/real-DWG execution: intentionally not run.
- Vendor, cloud/local mode, exact storage root, schema, dependency, and PDF renderer selection: deferred by contract.

## Publication state

- One minimal audit commit and normal branch push are authorized after final scope checks.
- Draft PR body must contain `Closes #609` and `Refs #523`.
- Independent CRITICAL architecture review is pending on the Draft PR.
- Ready, merge, and Issue closure remain owner-gated.
