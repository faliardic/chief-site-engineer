# Issue #183 Görev Sözleşmesi

- Issue: `#183 — Release 0.1 Mobil Hatırlatıcı Yaşam Döngüsü ve Bildirimler`
- Başlangıç master: `290029312f94991f154f5fe2caa8d71db254252f`
- Branch: `codex/issue-183-mobile-reminder-lifecycle-notifications`
- Commit: `Add mobile reminder lifecycle notifications`

## Bağlayıcı kapsam

- Bağımsız mobil `+ Unutma` hızlı yakalama.
- Mobil SQLite schema `2 → 3` atomik migration ve v2 veri korunumu.
- Optimistic revision ile tam tek-seferlik reminder yaşam döngüsü.
- Append-only business ve sınırlı notification event geçmişi.
- Android/iOS timezone-aware yerel bildirim zamanlama ve tap deep-link.
- Permission/plugin failure halinde SQLite kaydını koruyan operational sync state.
- Bootstrap reconciliation, missing/duplicate/orphan pending temizliği.
- Exact-alarm izni olmadan güvenli inexact Android schedule.

## Kesin kapsam dışı

- Recurring reminder veya routine template.
- Puantaj ve Beton Paketi.
- Attachment/fotoğraf.
- Cloud sync, auth, push/server notification ve çoklu cihaz.
- App Store/Play Store submission veya signing materyali.
