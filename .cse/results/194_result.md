# Issue #194 Yerel Sonuç Kaydı

## Teslim

- Mobil SQLite schema `5 → 6`; deterministik legacy taşeron/ekip eşlemesi,
  exact personel/Puantaj geçmişi korunumu ve atomik rollback/retry.
- Optimistic taşeron → ekip → personel sicili, logical archive/reopen,
  append-only workforce event, İSG belge read-model'i ve KKD zimmet geçmişi.
- Ajanda ana ekranından proje oluşturma ve Ajanda/Hatırlatıcı/Puantaj/Beton
  ekranlarında restart gerektirmeyen canlı proje kataloğu.
- Beton için exact iki saatlik inexact saha görevi ve kullanıcıdan kod istemeyen
  deterministik numune seti akışı.
- Reminder kartında Europe/Istanbul takvim sözleşmeli `Yarın` işlemi.
- Backup format `1` içinde mobil schema `1`–`6` staging migration ve schema `6`
  sicil/bağlantı/event exact round-trip'i.

## Yerel doğrulama

- Flutter analyze: `No issues found`.
- Flutter unit/widget suite: `147 passed`.
- Android API 36 emülatör integration: `1 passed`; schema 6 sicili, İSG/KKD,
  Puantaj, exact Beton görevleri, notification, restart ve backup/restore geçti.
- Android debug ARM64 APK: üretildi ve emülatöre kuruldu.
- Unsigned ARM64 release AAB: `20,211,483 byte`; native/manifest kapısı geçti.
- Repository-dışı ephemeral PKCS12 ile signed AAB: `20,219,868 byte`; signer
  doğrulandı, geçici keystore/parola finalde temp köküyle silindi.
- Universal ephemeral RC APK: `20,520,886 byte`; signer, ARM64 ve
  `zipalign -c -P 16 -v 4` doğrulandı.
- RC APK SHA-256:
  `8463783cc7c6a23e13bd166088449ade9c2889b348c299569eba401fd2ac8516`.
- Android source/merged manifest: API 36, izin allowlist, no INTERNET/cleartext,
  no broad storage/media ve no exact alarm kapıları geçti.
- iOS privacy manifest, iPhone target, plugin privacy inventory ve statik proje
  uyumluluğu geçti; native archive/store submission iddia edilmedi.
- Schema 5→6 rollback/retry, deterministic case/space/boş legacy mapping,
  personel ID/attendance entry-event korunumu ve restart kalıcılığı geçti.
- Sicil duplicate/stale/no-op/archive/reopen/event; İSG tarih sınırları ve KKD
  lifecycle; 320 px selector/registry/person tab ve input/double-tap testleri geçti.
- Reminder aynı yerel saat/ertesi 09:00, canonical UTC, source mutation yokluğu,
  event/revision ve periodic reconciliation testleri geçti.
- Backup schema `1`–`6` migration, schema `6` full round-trip ve gelecek schema
  fail-closed regresyonları geçti; format sürümü `1` kaldı.
- Python full suite: `1002 passed, 7 skipped`.
- `python -m compileall -q app scripts`, state JSON ve `git diff --check` geçti.
- Exact changed-file allowlist, protected Python/web/desktop/release config diff,
  exports, ignored ZIP/build/cache/RC ve changed-file secret taraması temiz.

## Güvenlik sınırı

- Gerçek kullanıcı verisi, gerçek `CSE_DATA_ROOT`, upload/signing key, Apple
  sertifikası, provisioning profile veya secret kullanılmadı.
- `reports/` okunmadı/değiştirilmedi; root `exports/` yalnız `.gitkeep` kaldı.
- ZIP, Flutter cache/build, unsigned/signed AAB ve RC APK ignored/stage dışı kaldı.
- Play Console/App Store Connect, PR, merge veya gerçek saha kabulü yapılmadı.
