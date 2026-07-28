# Issue #262 — Hatırlatıcı `Yarına ertele` uygunluğu

## Problem

`Yarına ertele` kart eylemi ekran grubuna göre gösteriliyordu. Bu yüzden
Yaklaşanlar içindeki yarın veya daha ileri tarihli kayıt ile Puantaj tarafından
yönetilen reminder üzerinde anlamsız bir generic mutation sunulabiliyordu.
Application katmanı da yarın tarihli kaydı sessiz no-op kabul ediyor, gelecekteki
ve Puantaj kaynaklı kaydı generic biçimde yarına çekebiliyordu.

## Tek uygunluk kaynağı

`isReminderEligibleForTomorrowSnooze` şu sırayla fail-closed karar verir:

1. status yalnız `active` olmalıdır;
2. `trashedAt` boş olmalıdır;
3. `attendanceDayId` boş olmalıdır;
4. timed ve all-day schedule alanlarından tam biri dolu olmalıdır;
5. timed UTC değer Europe/Istanbul yerel gününe çevrilir;
6. due yerel günü bugün veya geçmişse uygundur, yarın veya daha ileriyse uygun
   değildir.

Kart, detay ve `snoozeTomorrowMorning` application guard aynı helper'ı kullanır.
UI action'ı gizlese bile doğrudan veya stale çağrı application sınırında yeniden
kontrol edilir.

## Mutation bütünlüğü

Uygun timed reminder yarının aynı Europe/Istanbul yerel saatine taşınır. Uygun
all-day reminder yerel yarın gününe taşınır. Row update, revision artışı,
append-only `snoozed` event'i ve notification reconciliation mevcut zincirde
kalır.

Uygun olmayan çağrı transaction içinde update başlamadan reddedilir. Böylece:

- row ve revision değişmez;
- yeni event oluşmaz;
- notification binding ve native plan değişmez.

Aynı `eventId` ile retry, daha önce yazılmış `snoozed` event'ini tanıyıp current
aggregate'i döndürür. Farklı event ID ile stale revision mevcut fail-closed
mesajını korur.

## Puantaj sınırı

`attendanceDayId` taşıyan kayıt kartta ve detayda generic `Yarına ertele`
göstermez. Mevcut `Kaynak Puantaj gününe dön` deep-link'i korunur. Puantaj
recurrence/occurrence üretimi, saat ayarı ve source lifecycle bu Issue'da
değiştirilmemiştir.

## Veri ve compatibility

- Gerçek kullanıcı reminder verisi fixture olarak okunmaz.
- Schema `10` korunur.
- Backup formatı `1` korunur.
- Migration eklenmez.
- Notification permission, exact alarm, boot ve channel sözleşmeleri değişmez.
