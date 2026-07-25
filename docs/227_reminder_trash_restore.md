# Issue #227 — Hatırlatıcı Geri Dönüşüm Kutusu

## Amaç

Kullanıcı reminder detayındaki `Sil` eylemiyle kaydı normal çalışma
görünümlerinden kaldırabilir; kayıt fiziksel olarak silinmez ve aynı lifecycle
bilgisiyle geri yüklenebilir.

## Persistence sözleşmesi

Mobil schema `8 → 9` tek migration transaction'ında ilerler.
`follow_up_items` tablosuna şu alan eklenir:

```text
trashed_at TEXT NULL
```

Değer varsa canonical UTC saniyedir. Normal reminder `NULL`, Geri Dönüşüm
Kutusu kaydı non-null değer taşır. Migration mevcut active timed, active
all-day, inbox, completed ve cancelled kayıtları `trashed_at = NULL` ile
korur.

Trash ve restore sırasında şu alanlar değiştirilmez:

- `status` ve `item_type`;
- `next_attention_at` ve `all_day_local_date`;
- deadline, condition ve outcome;
- project/Ajanda/Puantaj/Beton source kimlikleri;
- attendance/concrete link satırları;
- created time ve önceki append-only history.

Her gerçek mutation revision'ı bir artırır ve `updated_at` değerini günceller.
Fiziksel delete trigger'ı korunur.

## Event ve mutation sözleşmesi

Yeni event vocabulary:

```text
trashed
restored_from_trash
```

Event payload revision, korunmuş status, timed/all-day schedule, trash/restore
zamanı ve source kimliklerini taşır. Aynı durumu yeniden isteyen komut no-op
olur ve duplicate event üretmez. Stale revision transaction başlamadan
reddedilir.

Trash kayıtta edit, schedule, snooze, complete, cancel veya reopen yapılmaz.
Kayıt önce restore edilmelidir. Böylece trash süresince lifecycle snapshot'ı
sessizce değişmez.

## Read-model

Şu normal yüzeyler yalnız `trashed_at IS NULL` kayıtları gösterir:

- Birleşik Bugün ve inbox count;
- Yarın;
- Yaklaşanlar;
- Unutma Kutusu;
- Tekrar kontrol;
- Geçmiş;
- Ajanda, Puantaj ve Beton source detaylarındaki reminder listeleri.

`Diğer > Geri Dönüşüm Kutusu` yalnız trash kayıtları gösterir. Sıra:

1. `trashed_at DESC`;
2. `updated_at DESC`;
3. `id ASC`.

Kart başlık, korunmuş status, schedule, proje/source türü ve trash zamanını
gösterir. Boş durum `Geri Dönüşüm Kutusu boş.` metnidir.

## Notification yaşam döngüsü

Trash database/event transaction'ı commit olduktan sonra reconciliation:

```text
logical reminder trash
-> aynı platform notification ID
-> native cancel denemesi
-> binding scheduled_for = NULL
-> cancelled veya güvenli cancel_failed diagnostic
```

Gateway hatası logical trash kararını geri almaz. Restore sonrasında yalnız
`active + timed + future` kayıt native schedule için uygundur. Overdue timed,
all-day, inbox, completed ve cancelled restore işlemleri yapay alarm üretmez.

## Backup compatibility

- Backup format version `1` değişmez.
- Schema `1–8` paketleri preflight sırasında schema `9` staging DB'ye migrate
  edilir.
- Schema 9 backup `trashed_at`, event history, source linkleri ve notification
  binding kimliğini round-trip korur.
- Bilinmeyen schema `>9` fail-closed reddedilir.

## UI

Reminder detayında `Sil` confirmation metni normal listelerden kaldırmayı,
Ajanda/Puantaj/Beton kaydının silinmediğini ve restore imkânını açıklar.
Trash detail/list görünümünde minimum 44 px `Geri yükle` eylemi bulunur.
Source deep-link butonları trash detail'de korunur.

## Bilinçli kapsam dışı

- Kalıcı silme ve `DELETE`;
- otomatik retention/30 gün temizliği;
- attachment byte silme;
- Ajanda/Puantaj/Beton source kaydı mutation'ı;
- Android/iOS platform kodu ve release scriptleri;
- gerçek kullanıcı data root'u;
- project-level 18.00 ve sonraki roadmap blokları.

## Validation

Validation class `persistence`tır. Odaklı migration/rollback, reminder
lifecycle/read-model, backup schema matrisi, source application ve widget
testleri ile `flutter analyze --no-pub` çalıştırılır. Ortak regresyon olmadığı
için mobile full suite'e çıkılmaz. Python suite, release gate, APK/AAB/signing,
ARM64/16 KiB, reboot/background acceptance, production RC ve branch içi gerçek
cihaz restore çalıştırılmaz.
