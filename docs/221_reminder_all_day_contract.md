# Issue #221 — Reminder Bugün, Gerçek Tam Gün ve Legacy Bekliyorum Sözleşmesi

## Amaç

Bu değişiklik mobil reminder veri sözleşmesini üç açık schedule biçimine
ayırır:

| Biçim | `next_attention_at` | `all_day_local_date` | Native saatli bildirim |
| --- | --- | --- | --- |
| Inbox | `NULL` | `NULL` | Yok |
| Timed | Canonical UTC timestamp | `NULL` | Mevcut motorla planlanır |
| Tam gün | `NULL` | Europe/Istanbul `YYYY-MM-DD` | Üretilmez |

Tam gün kayıt sahte 09:00, 18:00 veya 23:59 değeri taşımaz. Seçilen yerel
takvim gününde `Bugün`/`Yarın` read-model'ine katılır.

## Domain ve kullanıcı yüzeyi

- `ReminderKind`: `action | recheck`
- `ReminderStatus`: `inbox | active | completed | cancelled`
- Reminder schedule, view-group ve mutation API'sinde waiting yoktur.
- Formda tek dokunuşlu `Bugün`, `Yarın • Tam gün` ve `Tam gün` anahtarı vardır.
- Tam gün açıkken tarih seçimi kalır, saat alanı gösterilmez.
- Timed 15 dakika, 1 saat, bugün çıkmadan, yarın sabah ve özel tarih/saat
  davranışları korunur.
- Terminal kayıtlar önceki schedule bilgisini korur. Reopen schedule varsa
  `active`, yoksa `inbox` olur.

## Schema 8 migration

Schema 8, `follow_up_items` tablosunu yeni CHECK kurallarıyla atomik olarak
yeniden kurar. `all_day_local_date` nullable yerel takvim günü alanıdır.

Legacy normalizasyon:

```sql
CASE WHEN item_type = 'waiting' THEN 'action' ELSE item_type END
CASE WHEN status = 'waiting' THEN 'active' ELSE status END
```

Şunlar birebir korunur:

- `next_attention_at` ve deadline;
- project, Ajanda, Puantaj ve Beton kaynak bağları;
- description, ilgili kişi, önem ve koşul;
- notification binding kimliği ve schedule değeri;
- revision, created/updated/terminal zamanları;
- mevcut append-only event geçmişi.

Her etkilenen kayıt için
`schema8-legacy-waiting-normalized:<reminder-id>` seed'inden deterministik event
kimliği üretilir. Event tipi `legacy_waiting_normalized`, sequence değeri mevcut
event zincirinin sonrasıdır. Tarihsel `waiting_started` event'leri geçmiş kanıtı
olarak korunur; yeni application mutation'ı bu event'i üretemez.

Migration ve `schema_versions`/`PRAGMA user_version` ilerlemesi tek SQLite
transaction'ındadır. Hata, yeni tabloları ve normalizasyonu birlikte rollback
eder.

## Notification sözleşmesi

Reconciliation yalnız şu kaydı native plan adayı yapar:

```text
status = active
AND next_attention_at != NULL
AND due gelecekte
```

All-day reminder `next_attention_at` taşımadığı için native schedule isteği
oluşturmaz. Binding kaydı korunur fakat `scheduled_for = NULL` ve
`sync_state = cancelled` olur. Timed reminder'ın permission, exact/inexact
fallback, capacity, snooze, completion, cancel, reopen ve reconciliation
akışları aynı notification motorunda kalır.

## Backup ve restore compatibility

- Backup format version: `1` — değişmedi.
- Kabul edilen eski mobil schema: `1–7`.
- Restore hedefi: schema `8`.
- Schema 7 waiting backup'ı restore edildiğinde aynı action/active
  normalizasyonunu ve tek migration event'ini üretir.
- Schema 8 all-day kayıt format 1 backup/restore round-trip'ında yerel gününü
  korur.
- Bilinmeyen daha yeni schema fail-closed reddedilir.

## Validation kapsamı

Validation class `persistence`tır. Odaklı kanıt:

- schema 7→8 başarı, rollback, FK, source link, binding ve restart testleri;
- reminder lifecycle/application/read-model testleri;
- Bugün/Tam gün/waiting-yok widget testleri;
- backup format 1 all-day round-trip ve schema 1–7 restore matrisi;
- Europe/Istanbul gün/yıl/ay sınırı codec testleri;
- `flutter analyze`, schema static araması ve `git diff --check`.

Android release gate, AAB/signing, ARM64/16 KiB, reboot/background acceptance,
production RC ve gerçek cihaz restore bu Issue'nun kapsamı değildir.

## Kapsam dışı kalanlar

- birleşik Bugün ekranı ve filtrelerin nihai tasarımı;
- 18.00 saatsiz iş gecikme kuralı;
- reminder geri dönüşüm kutusu;
- attachment görünürlüğü;
- Open Loop `Beklediklerim`;
- Beton/Puantaj/malzeme/AI/hesap makinesi/hava durumu geliştirmeleri;
- Issue #216 release/PowerShell altyapısı.
