# Issue #179 Görev Sözleşmesi

- Issue: `#179 — Release 0.1 Mobil Ajanda Dilimi 1`
- Başlangıç master: `0e081f2c8616f990d56c6fe60f746dd4a5bc7f6d`
- Branch: `codex/issue-179-mobile-agenda-log-reminder-slice`
- Commit: `Add mobile agenda log reminder slice`

## Bağlayıcı kapsam

- Flutter/Dart ve cihaz-içi SQLite içinde günlük Ajanda logu.
- Europe/Istanbul gün sınırı ve canonical UTC saniye saklama.
- Immutable create command, tek clock okuması ve idempotent retry.
- Logdan project/source bağlantılı reminder oluşturma.
- Append-only log ve reminder event geçmişi.
- Ajanda ve Hatırlatıcı mobil ekranları ile çift yönlü navigation.
- Schema 1 → 2 atomik migration ve tam test/build kapısı.

## Kesin kapsam dışı

- Flask/web geliştirmesi.
- Attachment/fotoğraf bağlama.
- Native notification teslimi.
- Tam edit/archive veya reminder yaşam döngüsü.
- Cloud, auth, sync, AI ve mağaza submission.
