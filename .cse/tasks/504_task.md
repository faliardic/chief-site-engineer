# Issue #504 — P0 Safety Backup Recovery Surface v1

## Authority and start state

- Repository: `faliardic/chief-site-engineer`
- Official local repository root: verified against `AGENTS.md` (absolute host
  path intentionally omitted from evidence)
- Issue: `#504`
- Canonical owner authority: `#issuecomment-5429881644`
- Parent recovery incident: `#501`
- Restore safety invariant: `#503`
- Pre-update recovery gate: `#502`
- Owner-phone package policy: `#499`
- Expected base / synchronized `master` and `origin/master`:
  `187f537b4adf0647f7a5ac16f4d6fe59aff9f1fc`
- Branch: `codex/issue-504-safety-backup-recovery-surface`
- Start divergence: `0/0`
- Start tracked/staged/untracked drift: `0/0/0`
- Open production PR count at start: `0`

## Parent / V2 item

P0 recovery infrastructure required by Issue #501 and the durable restore
safety invariant in Issue #503. This task does not advance or complete another
V2 item and does not begin V2.12.

## Risk and model routing

```yaml
model_routing:
  policy_version: CSE-MRP-1.0
  task_risk: R4
  orchestrator:
    chatgpt_model: unknown
    chatgpt_reasoning_effort: unknown
  codex_model: gpt-5.6-sol
  codex_reasoning_effort: max
  execution_mode: standard
  orchestration: single-agent
  selection_reason: Backup-boundary recovery artifact discovery and export require persistence/data-integrity review.
  routing_request_evidence: https://github.com/faliardic/chief-site-engineer/issues/504#issuecomment-5429881644
  invocation_evidence: null
  invocation_verification_status: unverified
  allowed_fallback: null
  review_floor:
    chatgpt_model: gpt-5.6-sol
    chatgpt_reasoning_effort: max
  fail_closed_if_mismatch: true
```

The launch surface does not expose runtime actual model/effort metadata.
Runtime values must remain `unknown / unverified`; this is not treated as
downgrade evidence. The independent review floor remains `gpt-5.6-sol / max`.

## Changed contract

Add a narrow production, read-only/export recovery surface that:

1. lists only direct regular `safety_before_restore_*.csebackup` artifacts in
   the current environment's exact `exportsBackups` root;
2. returns immutable privacy-safe basename/size/SHA-256/timestamp metadata in
   deterministic newest-first order;
3. re-resolves and revalidates a selected basename inside the exact root at
   share time before delegating the validated file to the existing share
   gateway;
4. exposes loading, empty, safe-error, multiple-item and share-progress states
   in `Hafıza ve Yedekleme` without revealing an absolute private path.

This Slice is list + metadata + share/export only. It does not restore, merge,
reconcile, delete, rename, move, rewrite, clean, roll back, decrypt, parse,
preflight, browse a database, or inspect attachment content.

## Exact allowlist

Production:

1. `mobile/lib/application/mobile_backup_application.dart`
2. `mobile/lib/domain/mobile_backup_models.dart`
3. `mobile/lib/features/memory/memory_backup_page.dart`

Evidence:

4. `.cse/tasks/504_task.md`
5. `.cse/results/504_result.md`

Conditional test files are not authorized for edit under the current
source-resolved design. `CHANGELOG.md` and `docs/project_decisions.md` are not
needed because Issue #503/#504 already capture the durable decision.

Any additional path, conditional test edit, persistence redesign, or platform
change requires stop-and-report before edit.

## Protected paths and unchanged contracts

- `mobile/lib/storage/app_database.dart`, schema and migrations
- attachment stores and active database/attachment data
- `CseBackupCodec` encryption and backup format
- restore activation/swap algorithm and full-replacement semantics
- normal backup creation and `preflightBackup(...)`
- Android/iOS platform configuration and permissions
- package/application IDs and signing material
- `pubspec.yaml` / `pubspec.lock`
- release/build scripts

Required invariants:

- SQLite schema: exact `19`
- migration drift: `0`
- backup format: exact `1`
- package ID: `com.faliardic.sefim`
- mobile version/versionCode: source-current `0.1.0+1`
- signing/platform/permission/pubspec drift: `0`
- automatic `safety_before_restore_` creation: preserved
- owner-phone build/install/launch/device operations: `0`

## Source-level validation authority

Run only on the final source revision:

1. exact changed-path/allowlist and protected-path audit;
2. formatting of touched Dart files;
3. exactly one `flutter analyze --no-pub` invocation;
4. `git diff --check`;
5. static audit proving safety-prefix restriction, direct regular-file and
   resolved-root containment checks, action-time revalidation, no absolute UI
   path, and no restore/delete/decrypt/DB/attachment mutation;
6. schema/backup/package/version/signing/pubspec/platform drift audit;
7. branch/head/working-tree and remote divergence checks.

Automated application tests are disabled by owner-led policy. Do not run or
edit Flutter unit, widget, integration or full tests. Do not build APK/AAB, run
an emulator, use ADB/device, install, launch, or access owner real data.

If the primary final analyzer fails from an exact same-scope source defect, use
the bounded same-scope correction budget and the minimum-validation protocol's
single exact-fix retry. No further analyzer invocation is authorized.

## Manual test register

- Register: GitHub Issue `#479`
- IDs: `MT-504-001..007`
- Status: `PENDING`
- Codex must not execute or mark these tests PASS.

Minimum coverage:

1. recovery section renders;
2. current automatic safety backup appears;
3. metadata is plausible and no private path appears;
4. selected backup can be shared/saved;
5. multiple backups are newest-first;
6. export does not restore/merge/delete/mutate current data;
7. empty and error states fail safely.

## Build and artifact authority

No APK, AAB, install, launch, emulator, ADB, owner-phone operation, release
gate, or other runtime artifact is authorized.

## Stabilization budget

```text
primary implementation: 1
same-scope narrow source corrections: up to 3
environment-only recovery: at most 1 after exact root cause
automated application tests: 0
primary analyzer invocations: exactly 1
exact-fix correction retries: at most 1
```

## Immediate escalation conditions

- allowlist expansion or conditional test edit;
- schema/migration/backup/version/permission/signing/platform change;
- restore algorithm, encryption codec, DB, attachment or active-data access;
- arbitrary path sharing or an absolute private path reaching UI/evidence;
- new product/design decision beyond Issue #503/#504;
- destructive/force/uninstall/clear-data requirement;
- analyzer failure that cannot be resolved inside the remaining exact budget.

## Publication authority

If all authorized source gates pass:

- create minimal intentional commit(s);
- push normally to the exact branch;
- open one Draft PR to `master`;
- publish Issue and PR evidence;
- register `MT-504-001..007` as PENDING in Issue #479;
- stop for independent ChatGPT source/diff/evidence review.

Not authorized: Ready, merge, Issue closure, parent-Issue closure, owner-phone
installation, release/store publication, or beginning V2.12.

## Canonical source manifest

| Path | Git blob | SHA-256 |
| --- | --- | --- |
| `AGENTS.md` | `75e218af5813422a08aae08dc9df7d07507169be` | `bb00551caecbd2c19af6ccff0fe9c93acfa71aade05288b303f6006be0be616d` |
| `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md` | `d2f31def8ee392aab74990766e0a4822be489710` | `5899a8fe03e8ab7ca8ce204ddf7a271686bda0668b08a828645649495539e333` |
| `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md` | `f83164280277cc1f811448a559ddbfcc78d56040` | `f2c00b649cd1dceb19dc0bd1d284713138dbfbd8ee3332b9581afd107a0c20d5` |
| `docs/protocols/CSE_CODEX_INSTRUCTION_COMMENT_PROTOCOL.md` | `23eb5c4d72ce3858f097292f7fa1d3fb713d3b7e` | `e6585e4a217d63d6717973121512338a3edfd24091c3eb0df6ea573ec8a797c6` |
| `docs/protocols/CSE_MODEL_REASONING_ROUTING_POLICY.md` | `7d099ed4e5a1205320350c663fe659e36f2c4d6a` | `e1f55336657ecd79cb68cbae458341a811f0bb33867ac06b71163a5a8c8c320b` |
| `docs/protocols/CSE_WORKFLOW_ACCELERATION_PROTOCOL.md` | `b8ce5dd678935e472e1e5351db6c60b6c87238d7` | `7765bcebfb7b25b12e60fb44767d49c9d537393786fa0026561e1593073d297d` |
| `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md` | `e90612f5ca5bb3f4997110142e24112e246f3b6d` | `c12a57885f31144dc15cbbd3a07ab59527489a533ce5d8b444664ecf7710440d` |
| `docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md` | `af1974ecd2c53ceb67245c8eb1242b03fb1a82ef` | `b1685ce1610593195282b3b7c9038009ef8cd365d7c1314cb2356fc425bb383a` |
| `docs/protocols/CSE_PROJECT_SOURCE_REGISTER.md` | `583663cf0016d5060ed90ec44d1fce8aa16f74a5` | `f96fc9b1ef8bd12a6a4515a707726d84ee9a86a1a28bf6f20c5217e2954212cb` |
| `docs/v2/CSE_V2_SCOPE.md` | `f9321bc428ebf4c7d4a246a44b788bd615f9476f` | `b1e759e380f89c0c3a20d5deecedefa04fc8d48e1a654c31cb8caeed20965f96` |
| `ROADMAP.md` | `a6fb1697d52e4787f821880a73a2a27b97f185e5` | `1ece7b5fac1fa54f5a3b32206060ef21f0dfb8b8354898cacbff20643fb07a9e` |
