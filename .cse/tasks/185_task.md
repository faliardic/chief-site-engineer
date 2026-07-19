# Issue #185 Görev Sözleşmesi

- Issue: `#185 — Release 0.1 Mobil Puantaj: Personel günlük kaydı, ekip özeti ve hatırlatma`
- Resmî yerel repo: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Başlangıç master: `33a5c18a756174682358f18d69ae66341a0e6caf`
- Branch: `codex/issue-185-mobile-attendance-daily-workforce`
- Commit: `Add mobile daily attendance workflow`
- Codex modeli: standart full Codex model
- Reasoning: `Extra High`
- Seçim nedeni: atomik SQLite migration, optimistic aggregate lifecycle,
  reminder/notification koordinasyonu, native build ve geniş regresyon matrisi.

## Bağlayıcı kapsam

- Mobil SQLite schema `3 → 4` atomik migration ve mevcut Ajanda, reminder,
  notification binding ve append-only event verisinin korunması.
- Proje bazlı personel ekleme, düzenleme ve pasifleştirme.
- Günlük Puantaj aggregate'i; tam gün, yarım gün, gelmedi, izinli, fazla mesai
  ve kısa not.
- Taslak, tamamlandı, çalışma yok ve açık düzeltme/reopen yaşam döngüsü.
- Optimistic revision, idempotent command ve append-only Puantaj event geçmişi.
- Günlük/ekip toplamları, kişi-gün eşdeğeri ve fazla mesai özeti.
- Seçili çalışma günleri ve İstanbul yerel saatiyle 14 günlük idempotent Puantaj
  günü/reminder ensure işlemi.
- Puantaj günüyle reminder arasında exact bağlantı, lifecycle kapanış/reopen ve
  reminder detayından Puantaj gününe deep-link.
- UTF-8 CSV, formula injection koruması, insan-okunabilir özet, atomik staging
  ve failure cleanup.

## Kesin kapsam dışı

- Ücret, bordro, maaş, SGK ve hakediş.
- Personel fotoğrafı veya belgesi.
- Çoklu kullanıcı, onay zinciri ve cloud sync.
- Beton Paketi ve mağaza submission.
- Signing key, keystore, provisioning profile, secret veya gerçek kullanıcı
  verisi.

## Yetkili dosya alanı

- `mobile/**` Issue #185 production/test/build konfigürasyonu.
- Issue #185 `.cse/tasks`, `.cse/results`, state, README, roadmap, changelog,
  karar, docs ve learning kayıtları.
- Python/Flask production/test, Backup/Restore, Günlük Çıktı ve workflow dosyası
  değiştirilemez.

## Zorunlu doğrulama

- Dart format, `flutter analyze`, bütün Flutter unit/widget/static testleri.
- Android 36.1 emülatör integration, debug APK ve unsigned release AAB.
- iOS tracked statik uyumluluk.
- `python -m pytest`, `python -m compileall -q app scripts`.
- State JSON, `git diff --check`, exact changed-file allowlist, protected path,
  exports/reports/ignored ZIP-cache ve secret taraması.

## Yayın yetkisi

- Tek ordinary commit ve normal branch push yetkilidir.
- Amend, rebase, force-push, PR, merge veya branch deletion yetkili değildir.
