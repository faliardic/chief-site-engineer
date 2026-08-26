# Issue #497 — Project media album read-model + source navigation

## Authority

- GitHub Issue: `#497`
- Owner execution handoff: Issue comment `5428064413`
- Parent / V2 item: `V2.11 — Proje bazlı fotoğraf/video albümü`, Slice 1
- Expected base: `155e2e028b3a357fd3e158fd0779da0646c36a08`
- Branch: `codex/issue-497-project-media-album-v1`
- Worktree: `V:/1_PROJECTS/2_ACTIVE/Python/CSE-Worktrees/issue-497-project-media-album-v1`
- Initial worktree state: clean; target branch/worktree did not previously exist.
- Open PR preflight: none.

## Risk ve routing

- Risk class: `R3`
- Requested model: `gpt-5.6-sol`
- Requested reasoning effort: `max`
- Execution mode: `standard`
- Orchestration: `single-agent`
- Phone connection: `false`
- Runtime actual model/effort: `unknown / null / unverified`
- Independent review floor: required before Ready/merge.

## Scope / changed contracts

- Seçili tek bir project için yalnız `managed_attachments + attachment_links`
  truth'undan türetilen salt-okunur fotoğraf/video albümü.
- Desteklenen album MIME'ları exact olarak `image/jpeg`, `image/png`,
  `image/heic`, `video/mp4`.
- Source tipleri exact olarak `agenda_observation` ve `concrete_pour`.
- Aynı physical attachment bir kez görünür; bütün project-scoped link/context
  bilgileri korunur.
- Proje, medya türü, tarih, mahal/context ve source filtreleri; dosya adedi ve
  byte toplamı.
- Sağlıklı JPEG/PNG selected-item in-app preview; sağlıklı MP4/HEIC mevcut
  integrity-gated external-open yolu; bozuk medya görünür fakat preview/open
  fail-closed.
- Kaynak kayda mevcut detail sayfaları üzerinden navigation.
- Attachment/link/source/archive mutation, yeni binary/persistence/cache,
  capture/import, M4A veya 20 MiB contract değişikliği yok.
- Schema `19`, backup format `1`, mobile version `0.1.0+1` değişmeyecek.

## Allowed paths

1. `mobile/lib/domain/attachment_models.dart`
2. `mobile/lib/application/attachment_catalog_application.dart`
3. `mobile/lib/features/attachments/project_media_album_page.dart` (new)
4. `mobile/lib/app.dart`
5. `ROADMAP.md`
6. `docs/v2/CSE_V2_SCOPE.md`
7. `docs/project_decisions.md`
8. `CHANGELOG.md`
9. `.cse/tasks/497_task.md`
10. `.cse/results/497_result.md`

Conditional-only path:

- `mobile/lib/features/attachments/attachment_catalog_page.dart` yalnız preview
  extraction kaçınılmazsa; selection davranışı değiştirilemez. Başlangıç kararı:
  gerekmediği sürece dokunulmayacak.

## Protected / read-only paths

- `mobile/lib/platform/managed_attachment_store.dart`
- `mobile/lib/bootstrap/app_bootstrap.dart`
- `mobile/lib/storage/app_database.dart`
- `mobile/lib/features/agenda/log_detail_page.dart`
- `mobile/lib/features/concrete/concrete_pour_detail_page.dart`
- backup/restore paths
- `mobile/pubspec.yaml`, `mobile/pubspec.lock`
- Android/iOS/platform/permission paths

Allowlist genişletilmez. İhtiyaç oluşursa fail-closed owner escalation yapılır.

## Canonical source manifest (SHA-256)

Exact base `155e2e028b3a357fd3e158fd0779da0646c36a08`:

| Source | SHA-256 |
| --- | --- |
| `AGENTS.md` | `bb00551caecbd2c19af6ccff0fe9c93acfa71aade05288b303f6006be0be616d` |
| `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md` | `5899a8fe03e8ab7ca8ce204ddf7a271686bda0668b08a828645649495539e333` |
| `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md` | `f2c00b649cd1dceb19dc0bd1d284713138dbfbd8ee3332b9581afd107a0c20d5` |
| `docs/protocols/CSE_CODEX_INSTRUCTION_COMMENT_PROTOCOL.md` | `e6585e4a217d63d6717973121512338a3edfd24091c3eb0df6ea573ec8a797c6` |
| `docs/protocols/CSE_MODEL_REASONING_ROUTING_POLICY.md` | `e1f55336657ecd79cb68cbae458341a811f0bb33867ac06b71163a5a8c8c320b` |
| `docs/protocols/CSE_WORKFLOW_ACCELERATION_PROTOCOL.md` | `7765bcebfb7b25b12e60fb44767d49c9d537393786fa0026561e1593073d297d` |
| `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md` | `c12a57885f31144dc15cbbd3a07ab59527489a533ce5d8b444664ecf7710440d` |
| `docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md` | `b1685ce1610593195282b3b7c9038009ef8cd365d7c1314cb2356fc425bb383a` |
| `docs/protocols/CSE_PROJECT_SOURCE_REGISTER.md` | `f96fc9b1ef8bd12a6a4515a707726d84ee9a86a1a28bf6f20c5217e2954212cb` |
| `docs/v2/CSE_V2_SCOPE.md` | `e5e85b8f5d233d6791000c9803f3249b073e4c72bf48011bb4d726c431084035` |
| `ROADMAP.md` | `5bfd2f7ad8de59ef0fe6a9367e596df1798d0fcbb1f91ccc54b219d129d20217` |

## Required pre-edit sources

Comment order fully read before this task write: canonical repository rules,
V2 scope/roadmap, Issue #497 body/comment, Issues #426/#424, attachment domain
and catalog application/UI, protected managed store/bootstrap, `app.dart`, and
protected Agenda/Concrete detail navigation references. Issue #479 currently
contains no `MT-497-*` records.

## Source-level checks

1. exact base / clean isolated worktree
2. task file is first project write
3. exact allowlist audit
4. touched Dart formatting
5. exactly one final `flutter analyze --no-pub`
6. `git diff --check`
7. schema `19` / migration drift `0`
8. backup format `1`
9. mobile version `0.1.0+1`
10. pubspec/lock drift `0`
11. Android/iOS/platform/permission drift `0`
12. attachment write/duplication drift `0`
13. source/link/archive mutation drift `0`
14. eager whole-project byte loading `0`
15. exact source navigation review
16. final changed-path/staging/branch/divergence audit

Analyzer authority is exactly one final invocation. Failure is fail-closed; no
retry.

## Automated application tests / build

- Flutter unit tests: disabled
- Widget tests: disabled
- Integration/full suite: disabled
- Emulator/ADB/real device/scripted UI acceptance: disabled
- APK/AAB: disabled
- Application behavior testing by Codex: disabled

## Manual test register

- Register: Issue `#479`
- IDs to publish after source gates PASS: `MT-497-001..015`
- Initial/current status: `PENDING`
- Codex will not execute or mark them PASS.

## Stabilization / correction budget

- Primary implementation window: `1`
- Same-scope narrow corrections: maximum `3`
- Environment-only recovery: maximum `1` after exact root cause
- Automated application tests: `0`

## Immediate escalation conditions

- allowlist/scope expansion
- new product/design decision
- schema/migration/backup/version/dependency/permission/signing/platform change
- production/debug/real user data risk
- stable identity/transaction/event/history/integrity/security mutation
- unproven root cause or exhausted correction budget
- destructive/force/uninstall/production clear-data need

## Publication authority

If and only if source gates PASS: complete append-only result evidence, create
one narrow commit, normal push, open one Draft PR, publish Issue #497 evidence,
and stop for independent review. Do not Ready, merge, close Issue #497, declare
V2.11 complete, start V2.12, build, release, or mutate manual tests to PASS.
