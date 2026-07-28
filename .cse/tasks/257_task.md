# Issue #257 — Doğrulanmış acceptance artifact yeniden kullanımı

## Güvenli başlangıç

- Resmî yerel repo: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Base `master`: `defeab25f4a940c43f07e42faa3fa3fd2ef905de`
- Branch: `codex/issue-254-physical-smoke-acceptance-harness`
- Parent acceptance: Issue #254
- Parent build-root izolasyonu: Issue #256
- Validation class: `release-critical`
- Codex modeli: current full Codex modeli
- Reasoning seviyesi: `Extra High`
- Seçim nedeni: artifact provenance/hash, build sırası, ADB fail-closed sınırı
  ve production sandbox non-mutation aynı release kapısında doğrulanacaktır.
- Primary run: `1`
- Correction bütçesi: yalnız doğrulanmış blocker için en fazla `1`

## Değişen sözleşmeler

- Flutter artifact sırası:
  1. normal debug APK;
  2. background acceptance APK;
  3. reboot acceptance APK;
  4. unsigned release AAB;
  5. Issue #254 acceptance APK — son Flutter build.
- Issue #254 acceptance APK current invocation timestamp'i, exact path,
  applicationId, marker allow/deny listesi, length, last-write ve SHA-256 ile
  doğrulanır.
- Fiziksel smoke aynı exact artifact path/hash kaydını tekrar doğruladıktan
  sonra yalnız ADB install ve activity lifecycle kullanır.
- Fiziksel smoke yolunda Flutter, Gradle, clean, generic `app-debug.apk`
  keşfi veya build-root rotasyonu yoktur.
- Artifact değişmişse ilk ADB çağrısından önce fail-closed durulur.

## Exact changed-file allowlist

1. `.cse/tasks/257_task.md`
2. `.cse/results/257_result.md`
3. `scripts/release_gate.ps1`
4. `tests/test_release_gate_static.py`

Yalnız gerekli completion çapraz referansı için Issue #254/#256 task/result
dosyaları ayrıca değişebilir. Başka dosyada edit gerekirse durulur.

## Zorunlu doğrulama

- Acceptance APK'nın son Flutter build olduğunu doğrulayan focused static test.
- Physical smoke fonksiyonunda build/clean/rotation/Gradle olmadığını
  doğrulayan focused static test.
- Exact artifact path/hash/length/last-write değişikliğinde ADB başlamadığını
  doğrulayan executable Python fixture.
- Yanlış normal/background/reboot artifact adlarının reddedilmesi.
- Focused Python release-gate testleri PASS.
- Gerçek beş-artifact build zinciri PASS.
- Acceptance applicationId/entrypoint/marker/artifact/hash PASS.
- Altıncı rotasyon olmadan fiziksel iki-faz smoke PASS.
- Production `.debug` package/process/data inode metadata eşitliği PASS.
- `git diff --check`, combined exact allowlist ve protected-path kontrolü PASS.

## Yeniden kullanılan kanıt

- Issue #254: focused Flutter `11 PASS`, full Flutter `275 PASS`, Flutter
  analyze `PASS`.
- Issue #256: focused Python `11 PASS`; normal/background/reboot/Issue #254
  APK ve unsigned AAB build'leri ayrı ayrı PASS.
- Issue #252 / PR #253: reminder production davranışı.
- Issues #207/#212/#214: değişmeyen signing, ARM64/16 KiB,
  permission/privacy, schema, backup ve data-preserving contracts.

## Yasak kapsam ve stop koşulları

- Flutter production/reminder/widget/domain veya Android platform source
  değişmez.
- Physical smoke içinde build, clean, Gradle veya rotation çağrılmaz.
- Artifact mismatch sonrasında ADB veya yeni build çalışmaz.
- Production `.debug` açılmaz, kurulmaz, durdurulmaz veya mutate edilmez.
- Uninstall, clear-data, force-stop, permission mutation, process kill, ACL
  mutation ve Windows restart yoktur.
- Issue #255 stale generated dizinleri ve protected kullanıcı alanları
  okunmaz, değiştirilmez veya stage edilmez.
- Aynı blocker tek correction sonrasında sürerse fail-closed durulur.

## GitHub yetkileri

- Commit: bütün kapılar PASS ise
  `Reuse verified acceptance artifact for physical smoke`.
- Push: yalnız ordinary commit sonrasında normal push.
- Draft PR: Issue #254, #256 ve #257'yi bağlayan tek Draft PR.
- Ready/merge, force push ve destructive Git işlemleri yasaktır.
