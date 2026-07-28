# Issue #254 — İzole fiziksel smoke acceptance harness

## Güvenli başlangıç

- Resmî yerel repo: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Base `master`: `defeab25f4a940c43f07e42faa3fa3fd2ef905de`
- Başlangıç divergence: `0 0`
- Branch: `codex/issue-254-physical-smoke-acceptance-harness`
- Validation class: `release-critical`
- Codex modeli: current full Codex modeli
- Reasoning seviyesi: `Extra High`
- Seçim nedeni: applicationId, entrypoint, artifact marker, fiziksel cihaz
  sandbox izolasyonu ve iki süreçli kalıcılık kabulü birlikte değişiyor.
- Primary run: `1`
- Correction bütçesi: yalnız doğrulanmış blocker için en fazla `1`

## Değişen sözleşmeler

- Mevcut `com.faliardic.chiefsiteengineer.acceptance` sentetik altyapısı,
  Issue #252 kullanıcı akışını production UI/domain/application source'u
  üzerinden çalıştıran yeni bir Flutter `integration_test` hedefi kazanır.
- Yeni hedefin marker'ı ve artifact adı background/reboot ve normal launcher
  hedeflerinden ayrıdır.
- Physical smoke iki ayrı test süreciyle aynı benzersiz sentetik data root'u
  kullanır: ilk faz UI akışını `3 saat ertele` sonuna getirir; ikinci faz
  restart kalıcılığını doğrular ve yalnız sentetik reminder'ı trash'e taşır.
- Normal `lib/main.dart`, `.debug` applicationId, production/release
  applicationId, field APK ve release artifact zinciri yeni acceptance
  marker'ını fail-closed reddeder.
- Production `.debug` package yalnız package/install/inode/process metadata
  snapshot'ıyla kontrol edilir; count veya içerik okunmaz.

## Exact changed-file allowlist

1. `.cse/tasks/254_task.md`
2. `.cse/results/254_result.md`
3. `mobile/integration_test/issue252_physical_smoke_test.dart`
4. `mobile/integration_test/support/issue252_smoke_acceptance.dart`
5. `scripts/build_mobile_acceptance_apks.ps1`
6. `scripts/run_issue252_physical_smoke_acceptance.ps1`
7. `scripts/release_gate.ps1`
8. `mobile/test/background_acceptance_harness_test.dart`
9. `mobile/test/release_static_configuration_test.dart`
10. `tests/test_mobile_release_hardening.py`
11. `docs/254_physical_smoke_acceptance_harness.md`
12. `learning/254_physical_smoke_acceptance_harness.md`
13. `CHANGELOG.md`
14. `ROADMAP.md`
15. `docs/project_decisions.md`

Allowlist dışında ihtiyaç çıkarsa edit durur; kapsam kendiliğinden genişlemez.

## Uygulama

- Existing `CSE_ACCEPTANCE_HARNESS`, marker verifier ve acceptance APK builder
  genişletilir; ikinci bir E2E framework kurulmaz.
- `CSE_ENTRYPOINT_ISSUE252_SMOKE_ACCEPTANCE_V1` marker'ı yalnız yeni
  integration hedefinde bulunur.
- Acceptance test data root'u package cache altında run ID ile benzersizdir ve
  yalnız sentetik `ISSUE252-SMOKE-<timestamp>` reminder taşır.
- Phase 1:
  - `Bugün | Yarın | Diğer`;
  - formda `2 saat` ve `3 saat`;
  - 2 saat create due;
  - `Yarına ertele`, `2 saat ertele`, `3 saat ertele`;
  - son due yaklaşık işlem anı +3 saat;
  - kayıt aktif kalır.
- Phase 2:
  - aynı run ID/root ile yeni app bootstrap;
  - reminder, active status ve +3 saat due birebir korunur;
  - yalnız sentetik reminder `Sil` confirmation ile trash'e taşınır;
  - trash projection'da doğrulanır.
- Runner normal/acceptance artifact kimliğini, marker'ları ve production
  package metadata snapshot eşitliğini fail-closed doğrular.

## Doğrulama

- Focused Flutter helper/harness ve release static testleri.
- Focused Python mobile release-hardening testleri.
- `flutter test --no-pub`.
- `flutter analyze --no-pub`.
- Normal field/release gate: integration, Python ve signed artifact aşamaları
  değişmeyen kanıt nedeniyle skip edilerek bir kez.
- Synthetic acceptance APK build zinciri bir kez.
- Fiziksel cihazda yalnız `.acceptance` iki-faz integration smoke.
- Acceptance ve normal APK applicationId/entrypoint/marker kontrolleri.
- Production `.debug` path, install metadata, `ceDataInode`, `deDataInode` ve
  PID pre/post eşitliği; veri count/content okuması yok.
- `git diff --check`, exact allowlist ve protected-path kontrolü.

## Yeniden kullanılan kanıt

- Issue #252 / PR #253: production reminder davranışı ve Flutter regresyonu.
- Issues #207, #212 ve #214: background/reboot acceptance, debug signing,
  ARM64/16 KiB, permission/privacy, schema `7`, backup format `1` ve
  data-preserving upgrade.
- Bu sözleşmeler production/domain/schema/backup/signing kodu değişmediği için
  yeniden kullanılır.

## Yasak kapsam ve stop koşulları

- Production `.debug` data root, kayıt count/content veya UI okunmaz.
- Production package açılmaz, kurulmaz, durdurulmaz veya mutate edilmez.
- Uninstall, clear-data, downgrade, permission değişikliği, OCR, screenshot,
  full UI dump ve kör koordinat yoktur.
- `device-backups/`, `reports/` ve diğer kullanıcı ignored/untracked alanları
  okunmaz veya değiştirilmez.
- Blok 8, genel E2E framework ve Play/release submission kapsam dışıdır.
- Beklenmeyen tracked değişiklik, allowlist genişlemesi, marker/package sızıntısı,
  production metadata mutation'ı, yeni sertifika veya data-clear ihtiyacı,
  ikinci correction/ortam hatası ya da 180 dakika hard stop durumunda durulur.

## GitHub yetkileri

- Commit: bütün zorunlu kapılar PASS ise izinli.
- Push: yalnız başarılı commit sonrasında normal push izinli.
- Draft PR: bütün kapılar PASS ise izinli.
- Ready/merge: izinli değil.
- Force push, reset, clean, stash ve branch deletion yasaktır.
