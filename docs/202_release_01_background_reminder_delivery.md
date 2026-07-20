# Issue #202 — Arka Plan Hatırlatıcı Teslimat Güvenilirliği

## Amaç

Release 0.1 saha kabulünde, uygulama açılmadan teslim edilmesi gereken bazı
yerel hatırlatıcıların ancak uygulama yeniden açıldığında görünmesi blocker
olarak ele alındı. Bu çalışma reminder source-of-truth'unu SQLite'ta tutmaya
devam ederken Android native alarm planını doğrulanabilir ve kullanıcıya
tanılanabilir hale getirir.

## Kanıtlanan kök neden

Önceki Android akışı hem tek seferlik hem saatlik planlarda
`AndroidScheduleMode.inexactAllowWhileIdle` kullanıyordu. Android'in resmi alarm
sözleşmesine göre inexact alarm trigger anından önce çalışmaz; Android 12 ve
sonrasında normal koşullarda bir saate varan sistem toleransıyla teslim
edilebilir. Doze ve üretici batarya politikaları bu aralığı daha da görünür
hale getirebilir.

Issue #202 saha bulgusu 15/30/60 dakikalık kullanıcı niyetli bildirimlerin
uygulama kapalıyken geciktiğini gösterdi. Resmi sözleşme ile gerçekleşen saha
bulgusu birlikte kök neden kanıtıdır:

- <https://developer.android.com/develop/background-work/services/alarms/schedule>
- <https://developer.android.com/training/monitoring-device-state/doze-standby>
- <https://developer.android.com/about/versions/14/changes/schedule-exact-alarms>

İkinci kök neden, ileri tarihli saatlik tekrarın native `calledAt` değerinin due
anından bir saat geriye çekilmesiydi. Plugin'in native trigger hesabı future
`calledAt` değerini doğrudan ilk alarm kabul ettiği için ilk teslimat erken
başlayabiliyordu.

Üçüncü güvenilirlik açığı, plugin schedule çağrısı exception vermediğinde
SQLite binding'in native pending kaydı yeniden okunmadan `scheduled` yapılmasıydı.

## Uygulanan sözleşme

### Android alarm planı

- Kullanıcının planladığı tek seferlik ve saatlik reminder native olarak
  `exactAllowWhileIdle` ile kurulur.
- Android 12+ için yalnız `SCHEDULE_EXACT_ALARM` özel erişimi kullanılır.
- `USE_EXACT_ALARM`, foreground service, WorkManager polling, cloud push ve
  `INTERNET` izni eklenmez.
- Özel erişim yalnız kullanıcı planlı reminder oluşturduğunda veya kullanıcı
  `Yeniden doğrula` dediğinde istenir.
- Erişim reddedilirse logical reminder SQLite'ta kalır. Platform destekliyorsa
  açıkça degraded olarak işaretlenen `inexactAllowWhileIdle` fallback kurulur;
  uygulama bunu güvenilir teslimat diye göstermez.
- Erişim daha sonra açılırsa reconciliation fallback'i iptal edip tek exact
  plana yükseltir. Duplicate logical reminder oluşmaz.

### Native plan doğrulaması

Her schedule işleminden sonra pending notification listesi yeniden okunur.
Ancak aşağıdaki üç koşul aynı anda doğruysa binding `scheduled` olabilir:

1. platform notification ID beklenen ID'dir;
2. payload içindeki reminder UUID beklenen logical reminder'dır;
3. rolling iOS planı için fiziksel slot seti tamdır.

Doğrulama başarısızsa logical row/event korunur ve binding
`native_schedule_failed` ile fail-closed olur.

### Boot ve process ölümü

`CseReminderBootReceiver`, plugin'in disk üzerindeki pending cache'ini boot,
package replacement ve desteklenen quick-boot olaylarında yeniden planlar.
Receiver'ın app-private audit kaydı yalnız şunları içerir:

- `completed` veya `failed` durumu;
- canonical UTC denetim zamanı.

Reminder başlığı, açıklaması, proje, kişi, not veya attachment bilgisi audit'e
yazılmaz. Normal process kill ve recent-apps swipe native AlarmManager planını
silmez. Android `force-stop` ise platformun kasıtlı güvenlik davranışı olarak
ayrı tanılanır; uygulama bunu aşmaya çalışmaz. Reminder detayındaki kullanıcı
uyarısı da `Zorla durdur` ile normal kapatma/swipe davranışını açıkça ayırır.

### Kullanıcı tanısı

Reminder detayındaki tanı kartı yalnız privacy-safe metadata gösterir:

- reminder UUID'nin ilk sekiz karakteri;
- `one_shot` / `hourly` schedule türü ve canonical due;
- native pending planın bulunup bulunmadığı;
- notification izni, kanal ve exact özel erişim durumu;
- batarya optimizasyonu, background restriction ve app standby bucket;
- son reconciliation ve boot reschedule zamanı/durumu;
- aktif notification post zamanı ve gecikme sınıfı.

Kullanıcı `Bildirim ayarları`, `Batarya ayarları` ve `Yeniden doğrula`
işlemlerini kendisi başlatır. Uygulama batarya optimizasyonundan otomatik muafiyet
istemez.

## Gecikme sınıfları

| Sınıf | Kural |
|---|---|
| `pending` | Native plan var, henüz aktif notification görülmedi |
| `onTime` | Post zamanı due'dan en fazla 1 dakika sonra |
| `delayed` | 1–5 dakika gecikme |
| `severelyDelayed` | 5 dakikadan fazla gecikme |
| `nativeScheduleMissing` | Logical reminder planlı fakat native pending yok |
| `deliveryUnknown` | Due veya platform sonucu değerlendirilemiyor |

## Veri ve uyumluluk

- Mobil SQLite schema `7` değişmez; migration yoktur.
- Backup format `1` değişmez.
- Reminder source-of-truth `follow_up_items`, native bağlantı
  `reminder_notification_bindings` olarak kalır.
- Optimistic revision ve append-only `follow_up_events` değişmez.
- Restore sonrası mevcut reconciliation exact erişim durumunu yeniden ölçer.
- Ajanda, Puantaj ve Beton source link/deep-link davranışları değişmez.
- Günlük Çıktı ve Python/desktop schema kapsamı genişlemez.

## Test matrisi

Otomatik testler şunları kapsar:

- 15/30/60 dakika exact native UTC/İstanbul ankrajı;
- yarın İstanbul sınırı ve ileri due saatlik ilk/sonraki tekrar;
- permission deny, channel disabled ve exact erişim reddi;
- fallback → exact upgrade, restart ve duplicate olmaması;
- schedule sonrası native pending doğrulaması;
- orphan/eksik rolling slot cleanup;
- completion/cancel/inbox geçişinde native cancellation;
- reopen ve restore reconciliation;
- boot receiver/manifest, izin allowlist'i ve privacy-safe audit statik kapıları;
- schema/backup format değişmezliği ve mevcut tüm mobil/Python regresyonları.

Fiziksel API 36 cihaz kabulü synthetic debug-sidecar verisiyle yürütülür;
gerçek kullanıcı verisi, gerçek `CSE_DATA_ROOT` veya production signing secret
kullanılmaz. Debug sidecar ve ephemeral-signed production RC ignored build
alanında tutulur.

## Tamamlanan cihaz kabulü

`R5CY21WKZFX` / SM-S938B / Android 16 (API 36) cihazında yalnız sentetik debug
paketi kullanıldı. Her ölçümde uygulama process'i normal biçimde kapatıldı ve
uygulama yeniden açılmadan platform notification kaydı gözlendi.

| Senaryo | Hedef UTC | Gözlenen UTC | Gecikme |
|---|---|---|---:|
| 15 dakika | `17:46:48` | `17:46:49` | 1,4 sn |
| 30 dakika | `18:01:48` | `18:01:50` | 2,7 sn |
| 60 dakika | `18:31:48` | `18:31:51` | 3,7 sn |
| Fiziksel reboot sonrası | `18:36:07` | `18:36:27` | 20,9 sn |

API 36 emülatörde ek olarak reboot + Doze 0,7 saniye, recent-apps swipe-away
1,2 saniye toleransla geçti. `force-stop` senaryosu due + 1 dakika boyunca
bilinçli olarak teslim üretmedi ve normal kapatma sonucundan ayrı doğrulandı.
Native pending kontrollerinde aynı logical reminder için duplicate oluşmadı.

Final ignored artifact kanıtları:

- debug sidecar SHA-256:
  `2554768a2dc99d8f498f9503ed156cf75949700f401d7adacccf218b1d1131b0`;
- ephemeral-signed production RC SHA-256:
  `2be1a895de521934610ab14e629b374ba6e0140da1d2e8c029b0fb67faaa6686`.

## Kapsam dışı

- cloud push veya internet tabanlı teslimat;
- sürekli foreground service;
- otomatik batarya optimizasyonu muafiyeti;
- store submission ve gerçek production signing;
- genel takvim entegrasyonu veya çoklu kullanıcı notification servisi.
