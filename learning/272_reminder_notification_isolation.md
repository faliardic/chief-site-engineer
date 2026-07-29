# Issue #272 — Hatırlatıcı Bildirim İzolasyonu Öğrenimi

## Gerçek hata modeli

Bir one-time notification'ın iki farklı yaşam durumu vardır:

```text
future + native pending  → henüz teslim edilmedi
due + native pending yok → teslim edilmiş olabilir
```

İkinci satırı otomatik olarak “terminal” saymak yanlıştır. Terminal olmayı
source reminder status/trash/inbox sözleşmesi belirler; Android pending listesi
yalnız gelecekte bekleyen schedule'ları gösterir.

## Kod akışı

`AgendaApplication._reconcileReminderNotifications` önce her reminder için
disposition üretir:

```dart
enum _NotificationDisposition {
  schedulable,
  preserveDeliveredOneTime,
  terminal,
}
```

Koruma koşulu aktif + trash olmayan + next attention bulunan + due zamanı geçmiş
+ one-time + `scheduledFor != null` birleşimidir. Bu kayıt:

```text
cancel listesine girmez
schedule listesine girmez
binding update almaz
capacity tüketmez
```

Terminal reminder ise binding gerçekten cleanup gerektiriyorsa exact platform
ID iptal edilir. Böylece B complete eylemi A/C notification'larına dokunmaz.

## Test yaklaşımı

Fake notification gateway pending ve displayed kümelerini ayrı taşır.
`deliverAll`, pending kayıtları displayed kümeye geçirir; targeted `cancel(id)`
yalnız aynı ID'yi iki kümeden kaldırır. Bu model, platformdaki teslim sonrası
pending-listeden kaybolma davranışını Flutter testinde görünür kılar.

Ana regresyon testi A/B/C delivered one-time reminder kurar, B'yi tamamlar ve
yalnız B ID'sinin iptal edildiğini doğrular. Aynı sözleşme cancel, trash,
restart/reconcile, snooze, permission/channel, exact fallback, pending-query
failure, capacity, orphan/mismatch ve deep-link senaryolarıyla çevrelenir.

## Teknik karar

Displayed-notification sorgusu için gateway/native genişletmesi yapılmadı.
Source state ve mevcut binding, delivered one-time korumasını application
katmanında deterministik biçimde tanımlamak için yeterlidir. Böylece migration,
platform API'si ve backup uyumluluğu riski eklenmez.

## Şunu şöyle yaptık ki...

Teslim edilmiş reminder'ı ayrı bir disposition ile koruduk ki Android pending
listesinin sınırlı anlamı source reminder yaşam döngüsünü yanlışlıkla ezmesin.
Terminal cleanup'ı exact ID ile bıraktık ki tek kayıt eylemi ilgisiz
notification'ları kapatmasın. Fake gateway'de pending/displayed ayrımı kurduk ki
gerçek platform hatası baseline'da kırmızı, düzeltmeden sonra deterministik
yeşil kanıt üretsin.
