# Issue #272 — Hatırlatıcı Bildirim İzolasyonu

## Sorun

Android, teslim edilmiş bir one-time notification'ı artık
`pendingNotificationRequests()` sonucunda döndürmez. Önceki reconciliation,
source reminder hâlâ aktif ve gecikmiş olsa bile bu yokluğu terminal sinyali
gibi ele alabiliyordu. Başka bir reminder tamamlandığında teslim edilmiş peer
notification ID'leri de iptal listesine giriyordu.

## Çözüm

Application reconciliation üç disposition kullanır:

1. `schedulable`: Gelecekte planlanması veya pending kaydıyla eşleştirilmesi
   gereken reminder.
2. `preserveDeliveredOneTime`: Aktif, trash olmayan, due zamanı geçmiş,
   tek-seferlik ve daha önce schedule binding'i bulunan reminder.
3. `terminal`: Completed/cancelled/trashed/inbox veya gerçekten temizlenmesi
   gereken binding.

`preserveDeliveredOneTime` native pending listesinde yoksa bu beklenen delivered
durumudur. Application bu kaydı cancel/reschedule etmez, binding alanlarını
değiştirmez ve kapasite hesabına katmaz. Native pending'de hâlâ eşleşen exact
payload varsa kayıt kabul edilir, yine planlama churn'ü üretilmez.

Terminal temizlik exact `platformNotificationId` üzerinden yapılır. Gateway
API'si, Android native kodu, notification payload UUID'si ve persistence şeması
değişmemiştir.

## Hata ve fallback dalları

Initialize, permission denied, channel-disabled restart, exact-alarm fallback
ve pending-query failure dalları preserve disposition'ını terminale düşürmez.
Orphan veya mismatched payload pending kayıtları mevcut hedefli cleanup
sözleşmesini korur. Cancel hatası source mutation'ı geri almaz; yalnız hedef
binding güvenli hata durumuna geçer.

## Kanıt

- Eski kaynakta baseline: `32 PASS / 1 expected FAIL`; B complete A/B/C
  ID'lerini birlikte hedefledi.
- Yeni kaynakta reminder lifecycle: `44/44 PASS`.
- Full Flutter: `320/320 PASS`; analyze: `0 issue`.
- Exact cihazda üç delivered one-time notification ile B complete sonrası A/C
  korundu. Restart reconcile, A snooze, C cancel ve C deep-link doğru hedefte
  kaldı.
- Schema `10`, backup formatı `1`, migration `0`; gateway/native/storage diff
  `0`.

Bu Issue genel notification framework'ünü, özel sesleri, background/reboot
motorunu, backup/restore'u veya D29.2 Ajanda odağını değiştirmez.
