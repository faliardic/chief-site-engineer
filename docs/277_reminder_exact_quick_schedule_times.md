# Issue #277 — Hatırlatıcı Exact Hızlı Planlama Zamanları

## Sorun

Hatırlatıcıdaki hızlı zaman seçenekleri kullanıcıya bir sözleşme sunar. `Yarın
sabah` seçeneği ertesi İstanbul günü tam `08:00` olmalı; timed `Yarına ertele`
eski saati taşımamalıdır. Ayrıca detay ekranında sonraki haftanın pazartesi
`08:00` değerini tek dokunuşla seçme yolu yoktu.

Önceki davranış create akışında `09:00` üretirken timed snooze mevcut yerel
saati ertesi güne kopyalıyordu. Görünen seçenek ile kalıcı mutation arasında
tek bir exact resolver sözleşmesi de bulunmuyordu.

## Sözleşme

- `Yarın sabah`, operation anına göre ertesi Europe/Istanbul günü `08:00`dır.
- Timed `Yarın 08:00` quick action aynı exact değeri kullanır ve eski saati
  korumaz.
- `Hafta başına ertele`, bugün pazartesi olsa bile sonraki pazartesi
  `08:00`dır.
- Form ve detail sheet seçim yapılmadan önce exact yerel tarih/saat gösterir.
- Gösterilen preview ile mutation anındaki resolver sonucu uyuşmazsa işlem
  fail-closed reddedilir.
- All-day `Yarına ertele` all-day türünü korur; saatli notification kurulmaz.
- Canonical row, event payload ve notification binding aynı UTC değeri taşır.

## Uygulama

Europe/Istanbul gün hesabı saf domain resolver'larında toplanır:

```dart
String resolveReminderTomorrowMorningAt(DateTime nowUtc) {
  final today = CseTimeCodec.istanbulDayKey(
    CseTimeCodec.encodeUtc(nowUtc),
  );
  final tomorrow = CseTimeCodec.shiftIstanbulDay(today, 1).split('-');
  return CseTimeCodec.canonicalFromIstanbulComponents(
    year: int.parse(tomorrow[0]),
    month: int.parse(tomorrow[1]),
    day: int.parse(tomorrow[2]),
    hour: 8,
    minute: 0,
  );
}
```

Sonraki pazartesi için gün kayması `8 - local.weekday` olarak hesaplanır. Bu,
pazartesi günündeki seçimin aynı güne değil `+7 gün` sonraya gitmesini sağlar.

Form ve detail sheet, `clock.now().toUtc()` değerini bir kez yakalayıp resolver
sonucunu kullanıcıya `GG.AA.YYYY 08:00` biçiminde gösterir. Aynı canonical değer
create/reschedule command'ına taşınır. Application katmanı operation zamanında
değeri yeniden çözer ve karşılaştırır:

```dart
if (previewAttentionAt != resolvedAttentionAt) {
  throw const AgendaValidationFailure(
    'Gösterilen hızlı planlama zamanı artık geçerli değil. Yeniden seçin.',
  );
}
```

Timed snooze aynı tomorrow resolver'ını doğrudan kullanır. All-day dalı ayrı
kalır; `all_day_local_date` bir gün ileri taşınırken `next_attention_at`
`null` olur.

## Kanıt

- Old-source hedef failure: `3/3`; unrelated failure `0`.
- Focused lifecycle `48/48`, widget `46/46`, concrete regression `1/1` PASS.
- Full Flutter `333/333 PASS`; analyze clean.
- Checkpoint `952c81acc52712f4f24315576db2bbe9201d2040`.
- Exact debug APK SHA-256:
  `3395fbb73b7f36593bb5045be0a265cb759507ddc88d779f9a8049f9bfd9c4ce`.
- Samsung `SM-X610` tablet (`R52W90JFN1M`, `sw853dp`) automated wide smoke:
  PASS.
- Create tomorrow, detail next-week, timed quick action, all-day korunumu,
  canonical event/binding, native plan ve cold relaunch exact doğrulandı.
- Cleanup active `0`, geri alınabilir `3/3`; gerçek kullanıcı mutation'ı `0`.

Tablet-only PASS bu Issue'nun fiziksel tamamlanma kapısıdır. Telefon promotion
yapılmadı. Schema `10`, backup formatı `1`, migration, storage, notification
gateway, Android native ve D29.3'ün diğer maddeleri değişmedi.
