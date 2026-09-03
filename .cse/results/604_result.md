# Issue #604 — persistence PASS / baseline analyzer publication blocker

## Current recovery correction result

Authority: https://github.com/faliardic/chief-site-engineer/issues/604#issuecomment-5529011635

The recovery validator now recognizes Inventory links when checking physical
attachment ownership. Its required-file query selects the DISTINCT union of
generic and Inventory physical identities, then uses the unchanged path, size
and SHA-256 checks. Both current and historical Inventory photo links retain
their physical ownership. The generic broken-link query and archived legacy
Concrete optional-file predicate are unchanged, as are the restore journal,
activation, rollback and lifecycle code.

The direct regression in `restore_recovery_application_test.dart` proves an
Inventory-only relation succeeds with its exact managed file, reports
`active_attachment_missing` when absent, and reports `active_attachment_corrupt`
for both wrong size and same-size wrong hash. Restoring the expected test bytes
returns to valid state. The prior end-to-end backup regression is unchanged.

### Final authorized test invocation

```text
flutter test --no-pub test/mobile_backup_application_test.dart test/restore_recovery_application_test.dart
```

**49/49 PASS**, exit code `0`, runner elapsed `00:22`; invocation count **1**,
retry count **0**. The original Inventory photo regression now passes in full,
including archived/active photo links, exact manifest path/size/hash, live-state
restore, clean-target byte recovery, reopened active-photo read and unchanged
rows/files after receipt replay. Existing Agenda/Concrete, legacy schema and
process-death recovery tests in these two files also passed.

Per current authority, unchanged schema migration, Inventory application,
asset-core and attachment-gateway PASS results from the prior five-file gate
are reused. None of those source/test files changed in this correction; they
were not rerun. The two historical `123 PASS / 1 FAIL` results below are retained
and are not rewritten as PASS.

### Analyzer disposition and publication boundary

One `flutter analyze --no-pub` invocation returned exit code **1**, duration
48.5 seconds, with these baseline findings:

| Severity | Path / line | Diagnostic |
| --- | --- | --- |
| warning | `mobile/lib/application/inventory_application.dart:2609` | `unnecessary_non_null_assertion` |
| warning | `mobile/lib/application/inventory_application.dart:5382` | `unnecessary_non_null_assertion` |
| warning | `mobile/lib/application/inventory_application.dart:6441` | `unnecessary_non_null_assertion` |
| info | `mobile/test/widget_test.dart:1082` | `use_super_parameters` |

Both files are byte-identical to exact base
`d64b96ea5d1192f46c2c33197d03d90ef1245193` (`git diff --exit-code` = 0).
Blame places the three Inventory lines in that base commit and the widget line
in earlier commit `e349ae22`. No finding was reported in any changed file.
These files are outside the six-path allowlist; no lint cleanup or analyzer
rerun was performed.

Owner disposition:
https://github.com/faliardic/chief-site-engineer/issues/604#issuecomment-5529120433

```text
Analyzer: BASELINE_NONBLOCKING / exit 1
Errors: 0
Warnings: 3
Infos: 1
Findings in six changed paths: 0
```

This records the run accurately and does not relabel it as analyzer PASS. The
disposition authorizes Draft publication because all four findings are
pre-existing, remain outside the six-path diff, and include no analyzer error.

Exact six-path audit, protected-path drift and `git diff --check`: **PASS**.
Schema `22`, backup format `1`, version `0.1.0+1`: unchanged. Prior backup
source/test hashes still match the preserved first-correction state. Current
recovery source/test SHA-256 values:

- `restore_recovery_application.dart`:
  `2aa9a6d48f9908af27a4d357c7ebf7315fd65a451a7871c0fc26786f7516f376`
- `restore_recovery_application_test.dart`:
  `d635179f069dc62f9d6d1f333689971063e8f66f35136f3d880730f76762a6ec`

Final publication gate status: **PASS**, with analyzer disposition exactly as
recorded above. The validated six paths are ready for the single authorized
commit, normal push and Draft PR. Exact commit/PR identities remain in GitHub's
immutable branch and PR records instead of being duplicated before commit in
this same committed result file. Issue #604 stays open; Draft/Ready/merge remain
false. No Phase B/device/APK/ADB/MAIN, Issue closure, DWG or other source change
occurred. Independent CRITICAL review remains pending; field acceptance and
Inventory v1 completion are not claimed.

## First correction result (historical)

Authority: https://github.com/faliardic/chief-site-engineer/issues/604#issuecomment-5528949585

The authorized correction changed only the two attachment enumeration queries
in `mobile/lib/application/mobile_backup_application.dart`. Each now selects
DISTINCT managed metadata using the union of generic and Inventory link
attachment IDs. Generic legacy manifest filters are unchanged and remain
inside the generic relation subquery. Inventory archived/current links both
retain their physical bytes. Manifest validation runs after the existing
database migration/smoke checks, so legacy databases have the empty Inventory
relation without requiring a new schema or migration path.

The previous three-file state was preserved; the original regression test
remains byte-for-byte unchanged. One correction gate invocation, with exactly
the same five files listed below, returned **123 PASS / 1 FAIL**, exit code `1`,
runner elapsed `00:23`. Correction invocation count: **1**, retry count: **0**.
This is separate from the historical Phase-A `123 PASS / 1 FAIL` result below.

The original `attachmentCount == 2` assertion and exact manifest path/size/hash
comparison now passed. Backup creation and preflight accepted both Inventory
files. The same test then failed at its first `restoreBackup` call:

```text
MobileBackupFailure(restore_rollback_failed)
mobile/lib/application/mobile_backup_application.dart:1449
test/mobile_backup_application_test.dart:329
```

Source inspection found a further protected-path blocker in
`mobile/lib/application/restore_recovery_application.dart`:

- `validateActiveState()` at line 276 treats a managed physical record as an
  orphan whenever it has no generic `attachment_links` row, even if an exact
  Inventory photo link owns it; it raises `active_attachment_graph_invalid`.
- The byte validation query at line 287 also enumerates only generic links.
- Both `completeValidated()` and `rollbackToOld()` call that validator. This
  explains, from source, why Inventory-only photos can reject both the restored
  state and validation of the prior state, surfacing `restore_rollback_failed`.

That recovery file is read-only under the current four-path allowlist and was
not edited. No recovery bypass, fabricated generic link, assertion weakening,
second correction or retry was performed. Assertions after the failing restore
(including clean-target recovery/photo replay) remain unverified.

Current preserved changes are exactly the four authorized paths: task, result,
existing backup regression, and backup application source. Format/diff checks
pass; all other tracked source/test/docs/platform paths remain unchanged.
Schema `22`, format `1`, version `0.1.0+1` remain unchanged. Analyzer, commit,
push and Draft PR were not run because the gate failed. No Phase B/device,
Ready/merge, Issue closure or DWG action occurred.

Tested production SHA-256:
`51b62afd6c7cd14906a1ab6264aa06c21f0647a8502c3d5ac90c466a11bbec17`.
Test SHA-256 remains
`aa81bee1e2b3697d930fda6823d3a6cea7ab1ea30399bb11b16485e7743d9d09`.

STOP: a new narrow owner decision is required before changing the recovery
validator and authorizing its focused regression/gate. Preserve this branch
and all unpublished work; do not bypass restore integrity or rollback checks.

## Original Phase-A result (historical)

Authority and execution boundary: [task record](../tasks/604_task.md).
Base remains `d64b96ea5d1192f46c2c33197d03d90ef1245193`; branch:
`codex/issue-604-inventory-slice7-closure`.

## Coverage audit and minimal addition

| Required evidence | Existing executable coverage / disposition |
| --- | --- |
| Fresh schema 22; 19 -> 22; 20 -> revised 21 -> 22; superseded 21 -> 22 | Reused all nine `inventory_schema_migration_test.dart` cases, including exact preserved rows, legacy draft metadata, structural no-op, rollback, mixed/corrupt signatures and FK/integrity. |
| Populated spatial row truth, geometry hashes, placement chains, event/receipt integrity and replay | Reused `format 1 backup restores populated Inventory with exact replayable truth` and its eleven-table snapshot/integrity helpers. |
| Draft recovery, history and project isolation | Reused `inventory_application_test.dart` durable draft recreation, legacy protection, photo/history lifecycle, exact-floor/cross-project no-write, transaction/receipt and block lifecycle regressions; `inventory_asset_core_test.dart` retained unchanged. |
| Attachment path/hash/MIME and unsafe/corrupt behavior | Reused the four `inventory_attachment_gateway_test.dart` cases. |
| Inventory link plus managed bytes through backup/restore | Gap: the existing populated round-trip explicitly expected Inventory photo links and the manifest to be empty. Extended only that test, with real SQLite commands and the managed file gateway rooted in synthetic temporary directories. |

The extension creates an archived/replaced and an active Inventory photo, with
no generic `attachment_links` rows to mask missing Inventory adoption. It
requires both physical files in format 1, exact source/restore link and managed
metadata rows, a clean-target byte/path/size/hash/MIME check, active photo read
after reopen and idempotent photo-command replay without extra files or rows.
The existing populated row/replay/rollback assertions were retained.

## Single authorized invocation

From official repository `mobile`, using the already configured SDK executable
`C:\Users\Fatih\.cache\flutter-sdk\3.44.6-ee80f08\flutter\bin\flutter.bat`:

```text
flutter test --no-pub test/inventory_schema_migration_test.dart test/mobile_backup_application_test.dart test/inventory_attachment_gateway_test.dart test/inventory_application_test.dart test/inventory_asset_core_test.dart
```

- Result: **123 PASS / 1 FAIL**, exit code `1`, runner elapsed `00:40`.
- Invocation count: **1**; retry count: **0**.
- Failing case: `format 1 backup restores populated Inventory with exact replayable truth`.
- Failure location: `mobile/test/mobile_backup_application_test.dart:301`.
- Exact assertion: `created.summary.attachmentCount`; expected `2`, actual `0`.
- Before the failure, real photo commands produced two managed metadata rows
  and two exact Inventory links (one archived, one active); the generic link
  table was empty. Backup creation and preflight returned successfully.
- The later round-trip/clean-target/replay assertions in the extended case
  were **not reached** and are not claimed PASS.
- Tested file SHA-256:
  `aa81bee1e2b3697d930fda6823d3a6cea7ab1ea30399bb11b16485e7743d9d09`.
- No test/source edit was made after the failed invocation.

## Original read-only source diagnosis

`mobile/lib/application/mobile_backup_application.dart:1627`
(`_activeAttachmentRows`) selects managed files only through `attachment_links`.
The backup creator uses those rows at line 903 to construct its file manifest.
`_manifestAttachmentRows` at line 1635 likewise joins only `attachment_links`.
Neither query includes `inventory_asset_attachment_links`.

Therefore files linked only by Inventory are omitted from the package and from
the DB/manifest consistency check. Merely including the Inventory link table
in the database smoke table list does not preserve its physical files. This is
a production backup-adoption blocker, not a weakened fixture assertion.

## Original preserved state and next gate

- Changed paths: this result, `.cse/tasks/604_task.md`, and
  `mobile/test/mobile_backup_application_test.dart` only.
- Test format and `git diff --check`: PASS.
- Production/schema/backup/platform/dependency sources: unchanged.
- Read-only constants: schema `22`, backup format `1`, mobile `0.1.0+1`.
- Analyzer: NOT RUN; its prerequisite persistence PASS was not met.
- Scope/Roadmap truth-sync and publication: not advanced after the failing gate.
- Commit/push/Draft PR: NOT DONE.
- Phase B/device/APK/ADB/MAIN/Ready/merge/Issue closure/DWG: NOT DONE.
- Field acceptance: pending, not authorized by Phase A.

STOP under the authority comment's production-defect and failed-gate rules.
Preserve the unpublished test and evidence on this branch. The next decision
is a narrow owner correction authority for
`mobile/lib/application/mobile_backup_application.dart`, retaining the existing
test/evidence paths and separately authorizing one new focused invocation.
Both creation and manifest validation must include Inventory-only current and
historical attachment relations without changing format/schema or legacy
compatibility; any further production path still requires STOP.
