# Issue #221 — Gerçek Tam Gün ve Kayıpsız Reminder Migration Öğrenme Notu

## Amaç

Bu adımda iki farklı problemi aynı veri sınırında çözdük:

1. Tam gün işi, gerçekte var olmayan bir saate bağlamadan saklamak.
2. Eski reminder `waiting` kayıtlarını silmeden daha sade `action/active`
   sözleşmesine taşımak.

Yeni schedule modeli şöyledir:

```text
Inbox     -> timestamp yok, yerel gün yok
Timed     -> canonical UTC timestamp var, yerel gün yok
Tam gün   -> timestamp yok, Europe/Istanbul yerel günü var
```

## Hangi dosyada ne yaptık?

| Dosya | Değişiklik | Neden |
| --- | --- | --- |
| `mobile/lib/core/time/cse_time_codec.dart` | Yerel gün validation/format | Gün kararını tek codec'te tutmak |
| `mobile/lib/domain/agenda_models.dart` | Waiting enum'larını kaldırma, all-day alanları | Production API'nin eski anlamı üretememesi |
| `mobile/lib/storage/app_database.dart` | Schema 8 ve legacy normalizasyon | Veri kaybetmeden yeni invariant |
| `mobile/lib/application/agenda_application.dart` | Create, mutation, read-model, notification | Domain sözleşmesini atomik uygulamak |
| `mobile/lib/features/reminders/*` | Bugün/Tam gün UI, waiting yüzeyini kaldırma | Saha formunu sadeleştirmek |
| `mobile/test/*` | Migration, lifecycle, widget, backup testleri | Sözleşmeyi executable kanıta çevirmek |

## Gerçek Tam gün kodu nasıl çalışıyor?

Domain modelinde timestamp'ten ayrı alan vardır:

```dart
final String? nextAttentionAt;
final String? allDayLocalDate;
```

Satır satır anlamı:

1. `nextAttentionAt`, yalnız gerçek saatli reminder'ın canonical UTC anıdır.
2. `allDayLocalDate`, yalnız `YYYY-MM-DD` biçimindeki Europe/Istanbul günüdür.
3. İki alan aynı anda dolu olamaz.
4. İkisi de boşsa kayıt inbox'tır.

Application sınırı tam gün komutunu şöyle çözer:

```dart
if (allDayLocalDate != null) {
  CseTimeCodec.validateIstanbulDay(allDayLocalDate);
  return _ResolvedReminderSchedule(
    status: ReminderStatus.active,
    nextAttentionAt: null,
    allDayLocalDate: allDayLocalDate,
  );
}
```

Satır satır:

1. Yerel gün verilmişse timed switch'e girilmez.
2. Gün, ortak `CseTimeCodec` ile gerçek takvim tarihi olarak doğrulanır.
3. Açık tam gün kaydı `active` olur.
4. `nextAttentionAt: null`, sahte saatin oluşmasını yapısal olarak engeller.
5. Seçilen gün ayrı alanda korunur.

## SQL invariant'ı

Schema 8 iki schedule alanının çakışmasını CHECK ile de engeller:

```sql
CHECK (next_attention_at IS NULL OR all_day_local_date IS NULL)
```

Bu ifade şu anlama gelir:

- timestamp doluysa yerel gün mutlaka `NULL`;
- yerel gün doluysa timestamp mutlaka `NULL`;
- ikisi de boş olabilir, fakat yalnız inbox/terminal kuralları izin verirse.

Aktif kayıt için daha güçlü kural:

```sql
status = 'active' AND (
  (next_attention_at IS NOT NULL AND all_day_local_date IS NULL)
  OR
  (next_attention_at IS NULL AND all_day_local_date IS NOT NULL)
)
```

Buradaki `OR`, aktif reminder'ın tam olarak bir schedule biçimi taşımasını
sağlar.

## Legacy waiting migration nasıl yapıldı?

Eski veri fiziksel olarak silinmedi. Yeni tabloya kopyalanırken yalnız eski
değerler normalize edildi:

```sql
CASE WHEN item_type = 'waiting' THEN 'action' ELSE item_type END,
CASE WHEN status = 'waiting' THEN 'active' ELSE status END
```

Üç legacy varyantın tamamı kapsanır:

| Eski kind | Eski status | Yeni kind | Yeni status |
| --- | --- | --- | --- |
| waiting | waiting | action | active |
| waiting | active | action | active |
| action/recheck | waiting | aynı kind | active |

`next_attention_at`, source link, revision ve notification binding SELECT ile
aynen taşınır.

## Audit neden ayrıca eklendi?

Schema dönüşümünün görünür kanıtı için her legacy kayıt event zincirinin sonuna
tek event eklenir:

```dart
'id': _migrationStableUuid(
  'schema8-legacy-waiting-normalized:$reminderId',
),
'event_type': 'legacy_waiting_normalized',
```

Satır satır:

1. Seed içinde schema amacı ve reminder kimliği birlikte yer alır.
2. Aynı kaynak kayıt aynı deterministik UUID'yi üretir.
3. Event, eski geçmişi değiştirmez; yeni sequence ile sona eklenir.
4. Restart schema 8'i yeniden çalıştırmadığı için duplicate oluşmaz.
5. Eski schema 7 backup restore edildiğinde aynı migration aynı sonucu üretir.

Tarihsel `waiting_started` event'i silinmez. Bu event geçmişte ne olduğunu
kanıtlar; fakat enum ve mutation kaldırıldığı için production kodu yeni bir
`waiting_started` üretemez.

## Notification akışı

Notification eligibility:

```dart
item.reminder.status == ReminderStatus.active &&
item.reminder.nextAttentionAt != null
```

Tam gün kaydın timestamp'i olmadığı için gateway'e `schedule(...)` çağrısı
gitmez. Bu, “sabah 09.00 varsayalım” gibi gizli ürün kararını engeller.

Timed reminder'larda mevcut akış değişmez:

```text
record mutation
-> binding reconciliation
-> permission/exact-inexact kontrolü
-> native schedule
-> pending schedule doğrulaması
```

## Terminal schedule neden korunuyor?

Eski complete/cancel mutation'ı `next_attention_at = NULL` yapıyordu. Bu,
“hangi schedule ile kapatılmıştı?” bilgisini ana kayıttan siliyordu.

Yeni karar:

```text
complete/cancel -> status ve outcome değişir, schedule korunur
reopen          -> schedule varsa active, yoksa inbox
```

Notification binding terminal durumda iptal edilir; schedule bilgisinin
korunması native bildirimin açık kalması anlamına gelmez.

## Test kodu neyi doğruluyor?

Migration fixture'ı schema 7 veritabanına şu varyantları yazar:

```dart
itemType: 'waiting', status: 'waiting'
itemType: 'waiting', status: 'active'
itemType: 'action',  status: 'waiting'
```

Sonra schema 8 açılır ve test:

- üç kaydın da kaybolmadığını;
- action/active sonucunu;
- Ajanda/Puantaj/Beton source linklerini;
- exact revision ve due değerini;
- platform notification ID ve schedule'ını;
- üç deterministik audit event'ini;
- event sequence sırasını;
- `PRAGMA foreign_key_check` sonucunun boşluğunu;
- restart sonrası duplicate event olmadığını

doğrular.

Backup testi schema `1–7` paketlerini tek tek oluşturur:

```dart
for (final schemaVersion in [1, 2, 3, 4, 5, 6, 7]) {
  // format 1 paketi hazırla, preflight et ve schema 8'e restore et
}
```

Schema 7 fixture'ı özellikle waiting kayıt taşır. Böylece migration yalnız yeni
kurulan database'te değil, eski backup restore zincirinde de çalışır.

Widget testi:

- `Bugün` hızlı eylemini;
- `Tam gün` switch'ini;
- açıkken tarih alanının kaldığını;
- saat alanının görünmediğini;
- `Bekliyorum` metni/eylemi bulunmadığını

kontrol eder.

## Teknik karar tablosu

| Karar | Alternatif | Neden seçildi |
| --- | --- | --- |
| Ayrı `all_day_local_date` | 09.00 gibi fake UTC | Gerçek ürün anlamını korur |
| Backup format `1` | Yeni format sürümü | Container biçimi değişmedi |
| Tablo rebuild migration | Yalnız nullable kolon ekleme | Waiting CHECK'lerini gerçekten kaldırır |
| Deterministik audit event | Event yazmamak | Dönüşümü izlenebilir yapar |
| Terminal schedule korunumu | Complete'te schedule silme | Geçmiş anlam kaybını önler |
| All-day notification yok | Varsayılan saat seçme | Kullanıcı seçmediği saati üretmez |

## Yeni terim

`Tam gün hatırlatıcı`, gerçek saat taşımayan; yalnız Europe/Istanbul yerel
takvim günüyle saklanan ve ilk sürümde native saatli notification üretmeyen
reminder'dır. Kalıcı tanım `learning/GLOSSARY.md` dosyasına eklendi.

## Şunu şöyle yaptık ki...

- Şunu şöyle yaptık ki kullanıcı seçmediği bir saat sistem tarafından
  uydurulmasın: all-day kayıtta timestamp'i zorunlu olarak `NULL` bıraktık.
- Şunu şöyle yaptık ki eski `Bekliyorum` kayıtları kaybolmasın: schema 7
  satırlarını yeni tabloya source link, revision, binding ve geçmişiyle taşıdık.
- Şunu şöyle yaptık ki migration tekrarında çift event oluşmasın:
  reminder kimliğinden deterministik event UUID'si türettik.
- Şunu şöyle yaptık ki kapatılmış reminder'ın geçmiş schedule anlamı
  silinmesin: complete/cancel mutation'larında schedule alanlarını koruduk.
- Şunu şöyle yaptık ki all-day kayıt native notification hatası gibi
  görünmesin: detail diagnostic'ini yalnız timed kayıtta gösterdik.

## Bilinçli olarak yapılmayanlar

Birleşik Bugün ekranı, 18.00 gecikme kuralı, recycle bin, attachment, Open Loop
`Beklediklerim`, Beton veya release altyapısı bu değişikliğe eklenmedi.
