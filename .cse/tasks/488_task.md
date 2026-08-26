# Issue #488 — Bounded-memory backup package assembly

## Authority and execution

- Repository: `faliardic/chief-site-engineer`
- Issue: `#488 — P0 current backup codec can OOM on large encrypted backups`
- Owner authority: `https://github.com/faliardic/chief-site-engineer/issues/488#issuecomment-5424304199`
- Official local repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Isolated linked worktree: `V:\1_PROJECTS\2_ACTIVE\Python\CSE-Worktrees\issue-488-backup-codec-bounded-memory`
- Expected base/master: `6d91c7588befdec448b70bb3c73522ab956c48a5`
- Branch: `codex/issue-488-backup-codec-bounded-memory`
- Parent/product priority: P0 backup reliability correction
- Validation class: `persistence`, constrained by owner-led manual testing
- Policy version: `CSE-MRP-1.0`
- Task risk: `R4`

```yaml
model_routing:
  policy_version: "CSE-MRP-1.0"
  task_risk: "R4"
  codex_model: "gpt-5.6-sol"
  codex_reasoning_effort: "max"
  execution_mode: "standard"
  orchestration: "single-agent"
  selection_reason: "Backup codec memory behavior is a high-risk persistence and recovery boundary."
  routing_request_evidence: "https://github.com/faliardic/chief-site-engineer/issues/488#issuecomment-5424304199"
  allowed_fallback: null
  review_floor:
    chatgpt_model: "gpt-5.6-sol"
    chatgpt_reasoning_effort: "max"
  fail_closed_if_mismatch: true
```

Runtime model/effort metadata is not visible in this execution surface. The
request is recorded without inferring runtime actual values.

## Canonical source manifest

| Source | SHA-256 | Lines |
| --- | --- | ---: |
| `AGENTS.md` | `BB00551CAECBD2C19AF6CCFF0FE9C93ACFA71AADE05288B303F6006BE0BE616D` | 306 |
| `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md` | `5899A8FE03E8AB7CA8CE204DDF7A271686BDA0668B08A828645649495539E333` | 1365 |
| `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md` | `F2C00B649CD1DCEB19DC0BD1D284713138DBFBD8EE3332B9581AFD107A0C20D5` | 638 |
| `docs/protocols/CSE_MODEL_REASONING_ROUTING_POLICY.md` | `E1F55336657ECD79CB68CBAE458341A811F0BB33867AC06B71163A5A8C8C320B` | 185 |
| `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md` | `C12A57885F31144DC15CBBD3A07AB59527489A533CE5D8B444664ECF7710440D` | 328 |
| `docs/protocols/CSE_WORKFLOW_ACCELERATION_PROTOCOL.md` | `7765BCEBFB7B25B12E60FB44767D49C9D537393786FA0026561E1593073D297D` | 334 |
| `docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md` | `ACF77C5088BE704519230D087D9426772FE62C0DFD4A6BA6FE33A4626FAC5041` | 201 |
| `docs/protocols/CSE_PROJECT_SOURCE_REGISTER.md` | `F96FC9B1EF8BD12A6A4515A707726D84EE9A86A1A28BF6F20C5217E2954212CB` | 96 |
| `docs/v2/CSE_V2_SCOPE.md` | `94252C456618452B075E10DE7BF27758C9E8FEFFA878BDF1D264FA2C8AC14053` | 522 |
| `ROADMAP.md` | `D7533E0DC4463517CA370DB244ECCEABF11F87DE339FB30D19199A4F8101F9F7` | 412 |

Current Issue/authority and Issue #479 manual-test entries were read from
GitHub. Current repository/Issue evidence overrides stale embedded metadata in
older canonical documents.

## Preflight

- Exact worktree root: PASS
- Exact branch: PASS
- HEAD equals expected base: PASS
- Worktree clean before first edit: PASS
- Staged paths: `0`
- Existing source target is exact:
  `Uint8List.fromList([...aad, ...box.cipherText, ...box.mac.bytes])`
- Current schema source: `18`
- Current backup format: `1`
- Current app version: `0.1.0+1`

Protected baseline hashes:

| Path | SHA-256 |
| --- | --- |
| `mobile/pubspec.yaml` | `704EE4A64B534D14264984F68B8275570B8F87C06190EE48340830D971EABFA7` |
| `mobile/pubspec.lock` | `2B75E59A051A8CFCFEC3D6883B04779205C63678B0F4814A4535E50DB77DC441` |
| `mobile/android/app/build.gradle.kts` | `E83FF986DD52920D110BF64F5BA757B5CBA9A40C294347394EB99DBDCCA4BC28` |
| `mobile/android/app/src/main/AndroidManifest.xml` | `183F2B7DBCD4F4413E0947E26B4D27BEF1EAEF1530062732A24E13C9EC7C352D` |
| `mobile/ios/Runner/Info.plist` | `DE7235168B47210EF89D172858E6E7CBBF8434C7A10D0243650E6BA3B50F21FD` |

## Changed contract

Replace only the final encrypted backup package spread assembly with one
exact-size `Uint8List` and direct bounded `setRange` copies. Byte order remains
exactly:

```text
aad || ciphertext || mac
```

Backup format, magic/header, AAD, salt, nonce, KDF, ciphertext, MAC, decrypt,
archive and restore behavior remain unchanged.

## Exact allowed paths

1. `mobile/lib/application/mobile_backup_application.dart`
2. `.cse/tasks/488_task.md`
3. `.cse/results/488_result.md`

Any fourth changed path is an immediate fail-closed stop.

## Prohibited scope

- No schema, migration, backup-format or version change.
- No crypto/header/AAD/nonce/salt/MAC/decrypt/archive/restore semantic change.
- No dependency, `pubspec.yaml`, `pubspec.lock`, Android, iOS or platform edit.
- No Flutter unit/widget/integration/full tests.
- No APK/AAB build, emulator, ADB or physical-device work.
- No Ready, merge, Issue close, release/store claim or V2.9 work.

## Source-level validation

1. Format only the touched Dart file.
2. Exactly one final `flutter analyze --no-pub`.
3. Exact diff and 3-path allowlist review.
4. `git diff --check`.
5. Schema exactly `18`.
6. Backup format exactly `1`.
7. Version exactly `0.1.0+1`.
8. `pubspec.yaml`/`pubspec.lock` drift `0`.
9. Android/iOS/platform-production drift `0`.
10. No unrelated production drift.

If analyzer fails, stop without a second correction/analyzer invocation.

## Manual verification and publication

- Manual Test Register: `https://github.com/faliardic/chief-site-engineer/issues/479`
- `MT-488-001`: `PENDING`
- `MT-488-002`: `PENDING`
- `MT-488-003`: `PENDING`
- Automated application tests: disabled by owner-led manual testing policy.
- Build/artifact authority: none.
- Implementation budget: one narrow correction.
- Publication authority after all source gates PASS: one focused commit, normal
  push and one Draft PR against `master`.
- Final status claim: `IMPLEMENTED — MANUAL TEST PENDING`.
- Stop for independent ChatGPT source/diff review; no Ready or merge.
