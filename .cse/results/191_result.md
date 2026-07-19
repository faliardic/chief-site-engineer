# Issue #191 Yerel Sonuç Kaydı

## Teslim

- Android API 36, ARM64/16 KiB, merged permission ve dış signing release kapısı.
- Restore process-death journal ve bootstrap öncesi fail-closed recovery.
- Mobil schema v1–v5 migration/korunum regresyonu.
- Privacy/store beyan paketi ve iOS privacy/static archive kapısı.
- Proje mülkiyetinde release icon/splash, güvenli global hata UX'i.
- Secretsız GitHub Actions ve tek komut Windows RC release gate'i.

## Yerel doğrulama

- Flutter analyze: `No issues found`.
- Flutter unit/widget suite: `133 passed`.
- Android API 36 emülatör integration: `1 passed`; Ajanda, reminder,
  notification, Puantaj, Beton attachment, backup/restore ve restart akışı geçti.
- Android debug APK: üretildi.
- Unsigned ARM64 release AAB: `20,009,646 byte`; `jar is unsigned` doğrulandı.
- Repository-dışı ephemeral PKCS12 ile signed AAB: signer doğrulandı; geçici
  keystore ve parola finalde silindi.
- Universal RC APK: `20,324,278 byte`; ARM64, APK v2/v3 signer ve
  `zipalign -c -P 16 -v 4` geçti.
- RC APK SHA-256:
  `f4b79679d9c956e6e605ec96d1b9846ae5bc07559eeaa10d1d57aaecfe1088a7`.
- Android main/merged manifest allowlist; no INTERNET/cleartext/exact alarm/
  broad media-storage; API 36/NDK/ARM64 kapıları geçti.
- iOS privacy manifest, iPhone-only Xcode project, plugin privacy inventory,
  AppIcon boyut/no-alpha ve static archive hazırlık kapısı geçti.
- Mobil schema v1–v4 backup fixture migration'ları ile v5 full fixture korunum
  testleri; unknown newer schema fail-closed testi geçti. Mobil schema `5` kaldı.
- Restore journal'ın dört aşaması, tek bileşen taşınmış ara durum ve ambiguous
  recovery materyalini koruma testleri geçti.
- Python full suite: `1002 passed, 7 skipped`.
- `python -m compileall -q app scripts`, state JSON ve `git diff --check` geçti.
- Exact changed-file allowlist: beklenen `81`, gerçek `81`, unexpected/missing `0`.
- Python schema/migration/repository, desktop Backup/restore/Günlük Çıktı,
  requirements/pubspec ve mobil schema/version diff'i boş kaldı.
- Secretsız workflow dosyası statik doğrulandı; GitHub Actions workflow_dispatch
  bu görevde tetiklenmedi.

## Güvenlik sınırı

- Gerçek kullanıcı verisi, gerçek `CSE_DATA_ROOT`, upload/signing key, Apple
  sertifikası, provisioning profile veya secret kullanılmadı.
- `reports/` okunmadı/değiştirilmedi; root `exports/` yalnız `.gitkeep` kaldı.
- ZIP, Flutter cache/build ve RC artefaktları ignored kaldı ve stage edilmedi.
- Play Console/App Store Connect, PR, merge veya gerçek saha kabulü yapılmadı.
