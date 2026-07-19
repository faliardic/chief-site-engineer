# Issue #191 Görev Kaydı

## Yürütme

- Resmî repo: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Güvenli base: `b4dffed07fd71e24219d25f7e344df821002449e`
- Branch: `codex/issue-191-mobile-release-hardening-rc`
- Model: Codex standart full model
- Reasoning: Extra High
- Seçim nedeni: process-death restore recovery, Android/iOS mağaza uyumluluğu,
  secretsız signing sözleşmesi, artifact doğrulaması ve çok katmanlı regresyon
  kapıları aynı veri güvenliği ve release sınırında ele alınmaktadır.

## Yetkili kapsam

- `mobile/` altında release kimliği/varlıkları, Android izin ve API 36
  hardening'i, iOS privacy manifest'i, global güvenli hata UX'i ve restore
  process-death recovery journal'ı.
- Secretsız ve tekrarlanabilir mobil release kapıları, GitHub Actions workflow'u
  ve Windows release gate script'i.
- Privacy/store declaration paketi, RC saha kabul checklist'i, release
  dokümantasyonu ve gerekli Flutter/Python statik ya da executable testler.
- Issue #191 learning notu, changelog/roadmap/kararlar ve `.cse` factual
  kayıtları.

## Kabul kapıları

- Android merged manifest yalnız `CAMERA`, `POST_NOTIFICATIONS` ve
  `RECEIVE_BOOT_COMPLETED`; INTERNET, cleartext, exact-alarm ve broad media/
  storage izinleri yoktur; compile/target API 36 ve production/debug kimliği
  sabittir.
- Unsigned AAB, debug APK, repository-dışı geçici keystore ile ayrı signed
  artifact doğrulaması; ARM64 ve 16 KB artifact kapısı fail-closed çalışır.
- Restore journal'ın bütün swap aşamalarında process-death recovery; belirsiz
  durumda veri silmeme; v1-v5 schema fixture upgrade ve veri/event sayımı.
- iOS privacy manifest/plist/target/static archive checks; icon/splash boyut ve
  alpha kontrolleri; telemetry/secret/network endpoint audit'i.
- Flutter analyze, bütün unit/widget/integration testleri, API 36 emülatör,
  Python full suite/compileall, state JSON, `git diff --check`, exact
  changed-file allowlist ve korunan alan kontrolleri.

## Korunan sınırlar

- Gerçek kullanıcı verisi, gerçek `CSE_DATA_ROOT`, upload/signing key, Apple
  sertifikası, provisioning profile veya secret kullanılmaz.
- `reports/` okunmaz/değiştirilmez; `exports/.gitkeep`, mevcut ZIP ve ignored
  Flutter cache/build/artifact alanları korunur ve stage edilmez.
- Yeni iş modülü, cloud/auth/AI, Play Console, App Store Connect, gerçek store
  submission veya kullanıcı adına saha kabulü başlatılmaz.
- Tek ordinary commit `Harden mobile release candidate`; normal push; amend,
  rebase, force-push ve PR yoktur.
