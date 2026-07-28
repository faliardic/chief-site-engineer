# Issue #262 — Tek uygunluk kuralıyla güvenli reminder eylemi

## Amaç

Bir butonu yalnız UI'da gizlemek güvenli değildir. Eski ekran, deep-link veya
doğrudan application çağrısı aynı mutation'ı yine çalıştırabilir. Bu adımda
`Yarına ertele` kararını domain helper'ına taşıdık ve üç tüketiciyi aynı kurala
bağladık:

```text
MobileReminder current state
        ↓
isReminderEligibleForTomorrowSnooze
        ↓
kart görünürlüğü | detay görünürlüğü | application mutation guard
```

## Gerçek kod kuralı

Merkezi helper status, trash, source ownership ve yerel due gününü birlikte
değerlendirir:

```dart
if (reminder.status != ReminderStatus.active ||
    reminder.trashedAt != null ||
    reminder.attendanceDayId != null) {
  return false;
}

return dueDay.compareTo(istanbulToday) <= 0;
```

Timed reminder'ın kalıcı değeri UTC'dir. Karar UTC takvim gününe göre verilmez:

```dart
final dueDay = CseTimeCodec.istanbulDayKey(reminder.nextAttentionAt!);
```

Örneğin `2026-07-19T21:30:00Z`, UTC takviminde 19 Temmuz olsa da İstanbul'da
20 Temmuz 00:30'dur. İstanbul için yarın olan bu kayıt uygun değildir.

## Fail-closed application sınırı

UI action'ı gizler; fakat application mutation guard aynı helper'ı yeniden
çalıştırır:

```dart
if (!isReminderEligibleForTomorrowSnooze(
  current,
  istanbulToday: today,
)) {
  throw const AgendaValidationFailure(
    'Bu hatırlatıcı yarına ertelenemez. Tarihi veya kaynak akışı kontrol edin.',
  );
}
```

Kontrol row update ve event insert'ten önce olduğu için uygun olmayan çağrı
revision, event veya notification binding üzerinde kısmi sonuç bırakmaz.

## Idempotent retry ve stale revision farkı

Aynı `eventId` aynı isteğin retry kimliğidir. İlk istek başarıyla reminder'ı
yarına taşıdıktan sonra helper artık `false` dönecektir. Bu nedenle retry,
eligibility guard'dan önce mevcut `snoozed` event'ini tanır ve current aggregate'i
döndürür. Yeni event ID kullanan eski revision ise gerçek bir stale write'tır ve
reddedilir.

```text
aynı event ID + aynı reminder + snoozed event → current sonucu döndür
yeni event ID + eski revision                → stale failure
```

## Testlerin amacı

- Altı sentetik case bugün, gecikmiş, yarın, gelecek, Puantaj ve UTC/İstanbul
  gece yarısı ayrımını kanıtlar.
- All-day, terminal, trash ve plansız kayıt helper sınırını tamamlar.
- Application testleri uygunsuz çağrıdan önce/sonra row, revision, event ve
  notification binding'i karşılaştırır.
- Widget testleri Bugün/Gecikenler görünürlüğünü; Yarın/Yaklaşanlar ve Puantaj
  gizlemesini; 320 px, büyük yazı, dark theme ve double-tap guard'ı doğrular.
- Restart testi timed ve all-day yeni zamanının SQLite'ta korunduğunu kanıtlar.

## Şunu şöyle yaptık ki...

- Uygunluğu domain helper'ına aldık ki kart ile direct mutation farklı karar
  vermesin.
- UTC timestamp'i İstanbul gününe çevirdik ki gece yarısı sınırında yanlış
  `Yarına ertele` görünmesin.
- Puantaj kaydını source kimliğiyle dışladık ki occurrence zamanı generic
  reminder eylemiyle kaynağından kopmasın.
- Uygunsuz çağrıyı update öncesinde reddettik ki row/event/notification arasında
  kısmi state oluşmasın.
- Aynı event ID retry'ını guard öncesinde tanıdık ki başarılı isteğin ağ retry'ı
  yanlışlıkla stale veya ineligible hatasına dönüşmesin.

## Bilinçli sınırlar

Schema ve backup formatı değişmedi. Puantaj recurrence motoru, Puantaj saat ayarı,
Ajanda–Hatırlatıcı metin senkronu ve başka source reminder politikaları bu
Issue'nun kapsamına alınmadı.
