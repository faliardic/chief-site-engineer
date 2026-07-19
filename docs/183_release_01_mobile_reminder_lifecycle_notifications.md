# Issue #183 — Mobil Hatırlatıcı Yaşam Döngüsü ve Yerel Bildirimler

## Amaç

Bu dilim, Issue #179 ile gelen Ajanda bağlantılı minimum hatırlatıcıyı bağımsız
hızlı yakalama, tam tek-seferlik yaşam döngüsü ve Android/iOS yerel bildirim
teslimi olan yayınlanabilir mobil özelliğe dönüştürür.

Telefon source-of-truth'tur. Reminder satırı ve event geçmişi cihaz-içi
SQLite'ta tutulur. İşletim sisteminin pending notification listesi yalnız
yeniden üretilebilir teslim katmanıdır. İnternet, Flask, LAN veya bilgisayar
gerekmez.

## Kullanıcı akışı

Hatırlatıcı ekranındaki görünür `+ Unutma` düğmesi yalnız bir metinle kayıt
oluşturabilir. Kullanıcı isterse şu ayrıntıları ekler:

- proje;
- `action | waiting | recheck` türü;
- açıklama;
- mahal;
- ilgili kişi;
- önemli işareti;
- gerçek son tarih;
- koşul/not.

Hızlı zaman seçenekleri:

- 15 dakika;
- 1 saat;
- bugün çıkmadan;
- yarın sabah;
- Bekliyorum;
- yalnız Unutma Kutusu;
- özel İstanbul tarih/saat değeri.

Form immutable command üretir. Record ve event UUID'leri form açıldığında bir
kez oluşturulur. Submit sırasında düğme kapanır. Validation veya application
hatasında controller değerleri korunur. Aynı command/UUID retry edildiğinde
ikinci aggregate veya created event yazılmaz.

## Mobil schema 3

Schema `2 → 3` tek SQLite transaction içinde uygulanır. Migration sırası:

1. v2 `follow_up_events` ve `follow_up_items` tabloları geçici adlara alınır.
2. Geniş v3 aggregate ve event tabloları oluşturulur.
3. Eski Ajanda bağlantıları, reminder alanları ve event payload'ları kopyalanır.
4. Eski event'lere `occurred_at, id` sırasıyla deterministik sequence atanır.
5. Her reminder için unique platform notification integer ID bağlantısı kurulur.
6. Eski tablolar kaldırılır; append-only ve hard-delete trigger'ları yeniden
   kurulur.
7. `schema_versions` ve `PRAGMA user_version` aynı transaction'da `3` olur.

Herhangi bir adım hata verirse schema v2 ve bütün eski satırlar değişmeden
kalır.

### `follow_up_items` v3

| Alan grubu | İçerik |
| --- | --- |
| Kimlik | UUID `id`, optimistic `revision` |
| Yakalama | `capture_text`, `title`, optional `description` |
| Sınıflandırma | `item_type`, `status`, `is_important` |
| Bağlantı | optional `project_id`, optional `observation_id` |
| Saha ayrıntısı | optional `location`, `related_person`, `condition_text` |
| Zaman | `next_attention_at`, `deadline_at`, create/update/terminal zamanları |
| Sonuç | optional `outcome_type`, `outcome_note` |

Schema şu invariant'ları doğrudan korur:

- source observation varsa project zorunludur ve composite foreign key ile aynı
  projeye aittir;
- standalone reminder project taşımayabilir;
- açık reminder ya inbox'tadır ya da `next_attention_at` taşır;
- terminal reminder doğru terminal timestamp ve outcome taşır;
- aggregate fiziksel silinemez;
- revision en az `1` olur.

### Append-only event geçmişi

`follow_up_events`, aggregate içinde unique ve monoton `sequence` taşır.
Desteklenen vocabulary:

```text
created
scheduled / rescheduled
details_updated
waiting_started
snoozed
completed
cancelled
reopened
moved_to_inbox
notification_scheduled
notification_cancelled
```

Business mutation, reminder satırı ile event'i aynı transaction'da yazar.
Notification event'i yalnız operational binding gerçekten `scheduled` veya
`cancelled` durumuna geçtiğinde eklenir. Permission veya plugin exception metni
event payload'ına yazılmaz.

### Operational notification binding

`reminder_notification_bindings` tablosu şunları tutar:

- reminder UUID;
- unique, pozitif 31-bit platform notification ID;
- planlanan canonical UTC zamanı;
- `scheduled | permission_denied | unavailable | failed | cancelled` durumu;
- son sync zamanı;
- sabit ve güvenli hata kodu.

UUID için deterministik FNV-türevi 31-bit aday üretilir. Unique çakışmada lineer
probe sonraki boş ID'yi seçer. Raw exception, cihaz kimliği, dosya yolu, secret
ve kullanıcı içeriği operational tabloya yazılmaz.

## Yaşam döngüsü

Her mutation immutable `MutateReminderCommand` ve `expectedRevision` kullanır.
Application service önce mevcut revision'ı karşılaştırır. Stale değer fail-closed
conflict üretir; no-op işlem revision veya event artırmaz.

Desteklenen işlemler:

- ayrıntı düzenleme;
- schedule/reschedule ve özel tarih/saat;
- 15 dakika, 1 saat veya yarın sabaha snooze;
- waiting başlatma;
- Unutma Kutusu'na taşıma;
- tamamlandı veya artık gerekli değil outcome'u ve notu;
- iptal;
- terminal kaydı yeniden açma.

Complete, cancel veya move-to-inbox `next_attention_at` değerini kaldırır.
Complete/cancel doğru terminal timestamp ve outcome'u tek transaction'da yazar.
Reopen terminal alanları temizleyip kaydı inbox'a döndürür.

## Read-model ve ekranlar

Hatırlatıcı ekranında şu çalışan gruplar bulunur:

- Şimdi ilgilen;
- Gecikenler;
- Bugün;
- Bekliyorum;
- Tekrar kontrol;
- Yaklaşanlar;
- Unutma Kutusu;
- tamamlanan/iptal edilen geçmiş.

Sıra sözleşmesi:

```sql
next_attention_at ASC NULLS LAST,
is_important DESC,
created_at ASC,
id ASC
```

Detay ekranı aggregate alanlarını, revision'ı, notification sync durumunu,
append-only event geçmişini ve bütün lifecycle işlemlerini gösterir. Source
Ajanda kaydı varsa geri bağlantı korunur. Standalone reminder'da olmayan source
linki uydurulmaz.

## Notification orchestration

Gerçek platform adapter'ı `flutter_local_notifications ^22.0.1` sözleşmesini
kullanır; lock dosyasında doğrulanan sürüm `22.1.0`'dır.

### Schedule

- canonical UTC instant `Europe/Istanbul` timezone nesnesine çevrilir;
- payload `reminder:<UUID>` biçimindedir;
- Android `AndroidScheduleMode.inexactAllowWhileIdle` kullanır;
- Android'de `USE_EXACT_ALARM` ve `SCHEDULE_EXACT_ALARM` yoktur;
- iOS UserNotifications kullanır;
- tap callback veya cold-launch payload ilgili reminder detayını açar.

### Permission ve hata sınırı

Android 13+ `POST_NOTIFICATIONS` izni yalnız kullanıcının zamanlı reminder
oluşturma/schedule işlemi sırasında istenir. iOS initialize aşamasında otomatik
izin istemez; aynı açık kullanıcı işleminde alert/badge/sound izni ister.

İzin reddi, platform unavailable veya plugin schedule hatası SQLite transaction'ı
geri almaz. Reminder uygulamada due/overdue olarak kalır; operational sync state
kullanıcıya görünür.

### Bootstrap reconciliation

Uygulama açılışında:

1. açık ve gelecekte zamanı olan SQLite reminder'ları deterministik sıralanır;
2. platform pending listesi okunur;
3. eksik pending notification yeniden planlanır;
4. yanlış ID/payload taşıyan duplicate, stale ve orphan pending kayıtlar iptal
   edilir;
5. inbox veya terminal reminder'ın pending kaydı iptal edilir;
6. platform kapasitesini aşan daha uzak reminder'lar kaybolmaz; SQLite'ta kalır
   ve `platform_capacity` uyarısı alır;
7. başarı/hata operational binding'e güvenli kodla yazılır.

Notification swipe/dismiss aggregate status'unu değiştirmez. Sonraki
reconciliation, hâlâ açık ve gelecekte olan reminder'ın eksik pending kaydını
yeniden kurar.

## Platform yapılandırması

Android manifest:

- `POST_NOTIFICATIONS`;
- `RECEIVE_BOOT_COMPLETED`;
- plugin scheduled notification receiver;
- boot/package-replaced receiver;
- exact-alarm izni yok.

Android Gradle core-library desugaring kullanır. Release tree-shaking sırasında
notification icon kaybolmasın diye launcher icon keep resource'u eklenmiştir.

iOS `AppDelegate`, `UNUserNotificationCenter` delegate'ini bağlar. Plugin
initialize ayarları otomatik permission prompt üretmez. Native iOS archive bu
Windows ortamında çalıştırılmaz; macOS, Xcode ve repository dışı Apple signing
gerekir.

## Doğrulama matrisi

- schema 2→3 veri koruma ve failure rollback;
- standalone/linked foreign-key invariant'ları;
- event append-only, sequence ve no physical delete;
- notification ID uniqueness ve forced collision probing;
- bütün create hızlı seçenekleri;
- lifecycle, stale revision, no-op ve transaction rollback;
- source Ajanda kaydının mutation sırasında değişmemesi;
- sekiz read-model ve deterministik sıra;
- 320–430 px, 44 px hedef, input preservation ve double-submit;
- permission denied/unavailable/failure state;
- schedule/reschedule/cancel/reconciliation;
- missing/duplicate/orphan/capacity davranışı;
- cold-launch notification deep-link;
- manifest exact-alarm yokluğu ve iOS statik config;
- gerçek Android emülatörde pending create → restart → cancel;
- debug APK, unsigned release AAB, Flutter ve Python regresyonları.

## Kapsam dışı koruması

Bu Issue recurring reminder/routine, Puantaj, Beton Paketi, attachment/fotoğraf,
cloud sync, auth, push/server notification, exact-alarm permission veya mağaza
submission başlatmaz. Python/Flask production davranışı, Backup, Restore ve
Günlük Çıktı formatları değiştirilmez.
