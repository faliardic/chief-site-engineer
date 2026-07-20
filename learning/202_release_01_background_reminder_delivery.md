# Issue #202 — Android Arka Plan Hatırlatıcısını Güvenilir Kurmayı Öğrenmek

Bu not, Python öğrenen bir geliştiricinin de takip edebileceği şekilde logical
reminder, native alarm, reconciliation ve platform izni arasındaki farkı gerçek
kod üzerinden açıklar.

## Problem: Veritabanında kayıt olması teslimat demek değildir

Bir reminder oluşturulduğunda iki ayrı gerçek vardır:

1. SQLite'taki **logical reminder**: Kullanıcının kaydı ve yaşam döngüsüdür.
2. Android AlarmManager'daki **native schedule**: İşletim sisteminin gelecekte
   uygulama process'i yokken çalıştıracağı plandır.

SQLite transaction başarıyla biter fakat native schedule kurulamazsa reminder'ı
silmek veri kaybıdır. Tersine, plugin exception vermedi diye native planı
kontrol etmeden `scheduled` yazmak yanlış başarı beyanıdır. Issue #202 bu iki
durumu birbirinden ayırır.

## Gerçek kod 1: İzin durumunu ayrıştırmak

`mobile/lib/platform/notification_gateway.dart` içindeki enum:

```dart
enum NotificationPermissionState {
  granted,
  denied,
  channelDisabled,
  exactAlarmDenied,
  unavailable,
}
```

Satır satır anlamı:

- `granted`: notification gösterimi, kanal ve gereken exact erişim kullanılabilir.
- `denied`: Android notification izni kapalıdır.
- `channelDisabled`: genel izin açık olsa bile `cse_reminders` kanalı kapalıdır.
- `exactAlarmDenied`: reminder korunur fakat exact teslimat garanti edilemez.
- `unavailable`: plugin veya platform sorgusu güvenle tamamlanamamıştır.

Bu ayrım önemlidir. Tek bir `false` değeri kullanıcıya hangi ayarı düzeltmesi
gerektiğini söylemez.

## Gerçek kod 2: Exact ve degraded planı ayrı metotlarla kurmak

Üretim gateway'i aynı request'i iki açık moddan biriyle kurar:

```dart
Future<void> schedule(ReminderNotificationRequest request) async {
  await _schedule(request, exact: true);
}

Future<void> scheduleInexactFallback(
  ReminderNotificationRequest request,
) async {
  await _schedule(request, exact: false);
}
```

Satır satır:

- Normal `schedule`, güvenilir kullanıcı reminder'ı için `exact: true` gönderir.
- Özel erişim reddedilmişse ayrı isimli fallback çağrılır.
- Fallback'in farklı metot olması, yanlışlıkla güvenilir plan gibi
  işaretlenmesini zorlaştırır.

Android schedule mode seçimi:

```dart
androidScheduleMode: exact
    ? AndroidScheduleMode.exactAllowWhileIdle
    : AndroidScheduleMode.inexactAllowWhileIdle,
```

- Koşul doğruysa AlarmManager Doze içinde de exact kullanıcı alarmını kurar.
- Koşul yanlışsa sistem toleranslı best-effort plan kurulur.
- Application service fallback binding'ine
  `exact_alarm_permission_required` yazar; UI garanti iddiasında bulunmaz.

## Gerçek kod 3: Saatlik future due ankrajı

Önceki hatalı yaklaşım due anından interval çıkarıyordu. Doğru kod:

```dart
await withClock(
  Clock.fixed(instant),
  () => _plugin.periodicallyShowWithDuration(
    id: request.platformId,
    repeatDurationInterval: interval,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  ),
);
```

Satır satır:

- `instant`, kullanıcının seçtiği canonical UTC ilk due anıdır.
- `Clock.fixed(instant)`, plugin'in native `calledAt` alanını tam due anına
  sabitler.
- `repeatDurationInterval`, sonraki saatlerin aynı platform planından
  üretilmesini sağlar.
- Yeni logical reminder satırı oluşturulmaz; bir reminder bir native repeat
  zincirine bağlı kalır.

## Gerçek kod 4: Schedule çağrısından sonra kanıt istemek

Application service'in temel kontrolü:

```dart
await notificationGateway.schedule(request);
final verified = await notificationGateway.pendingNotifications();
final nativeSchedulePresent = verified.any(
  (pending) =>
      pending.platformId == binding.platformNotificationId &&
      pending.reminderId == reminder.id &&
      pending.scheduleComplete,
);
if (!nativeSchedulePresent) {
  throw StateError('native schedule missing after schedule');
}
```

Satır satır:

- İlk satır native plugin'e planı gönderir.
- İkinci satır plugin'in disk/native pending read-model'ını yeniden okur.
- `platformId`, fiziksel alarm kimliğinin doğru olduğunu kanıtlar.
- `reminderId`, payload'ın başka logical kayda ait olmadığını kanıtlar.
- `scheduleComplete`, iOS saatlik rolling planındaki 24 slotun tamam olduğunu
  kanıtlar.
- Kanıt yoksa exception application katmanında sabit güvenli hata koduna
  çevrilir; SQLite reminder row silinmez.

Bu desenin adı **postcondition verification**'dır: Bir komutun başarısını
sadece komutun hata vermemesinden değil, komuttan sonra beklenen durumun
gerçekleşmesinden doğrularız.

## Gerçek kod 5: Erişim reddinde veri kaybetmemek

Exact özel erişim yokken uygulama şu sırayı uygular:

```text
logical reminder zaten transaction ile kaydedildi
        |
        v
mevcut native pending aynı reminder mı?
   | evet                         | hayır
   v                              v
pending'i koru             inexact fallback dene
   |                              |
   +--------------+---------------+
                  v
binding = unavailable + exact_alarm_permission_required
```

Kullanıcı daha sonra exact erişimi açıp `Yeniden doğrula` dediğinde binding'deki
safe error code, mevcut pending planın exact diye yanlış kabul edilmesini
engeller. Fallback iptal edilir ve postcondition doğrulamalı exact plan kurulur.

## Gerçek kod 6: Android native tanı kanalı

`MainActivity.kt` yalnız metadata döndürür:

```kotlin
return mapOf(
    "permissionState" to permissionState,
    "channelState" to channelState,
    "exactAlarmState" to exactState,
    "batteryOptimizationState" to batteryState,
    "backgroundRestrictionState" to backgroundState,
    "standbyBucket" to standbyBucket,
    "bootRescheduleState" to bootState,
)
```

Bu map'te reminder başlığı, açıklama, proje, kişi veya saha notu yoktur. Flutter
tarafı UUID'nin yalnız ilk sekiz karakterini gösterir. Bu yaklaşım
**privacy-safe diagnostics** olarak adlandırılır: Sorunu çözmek için gerekli
teknik kanıt tutulur, kullanıcı içeriği tutulmaz.

## Boot receiver neden gerekli?

Android reboot sırasında RAM ve AlarmManager planları yeniden kurulur. Plugin
pending cache'i app-private storage'da kalır. Receiver:

```java
try {
  FlutterLocalNotificationsPlugin.rescheduleNotifications(context);
} catch (RuntimeException error) {
  state = "failed";
}
```

- `BOOT_COMPLETED` geldiğinde plugin pending cache'ini okur.
- Her reminder için aynı native schedule yeniden kurulur.
- Receiver yalnız `completed/failed` ve UTC zamanı kaydeder.
- Sonraki uygulama açılışındaki reconciliation gerçek pending listesini tekrar
  doğrular; boot audit tek başına başarı kanıtı sayılmaz.

## Force-stop ile process kill aynı şey değildir

| Olay | Android davranışı | CSE yaklaşımı |
|---|---|---|
| Home / recent-apps swipe | UI task kapanır, alarm devam eder | Pozitif kapalı-app kabul senaryosu |
| Normal process kill | Process yok edilir, alarm devam eder | Pozitif kapalı-app kabul senaryosu |
| Reboot | Receiver pending planı yeniden kurar | Boot audit + teslimat testi |
| Force-stop | Android alarm/broadcast teslimatını kullanıcı yeniden açana kadar engeller | Ayrı tanı; bypass edilmez |
| Doze / battery saver | Normal işler ertelenir; allow-while-idle alarm kuralları geçerlidir | Exact access + gecikme sınıfı |

Foreground service eklemek force-stop sözleşmesini güvenli biçimde çözmez ve
sürekli süreç/batarya maliyeti getirir. Bu nedenle kapsam dışıdır.
Reminder detay kartı da kullanıcıya `Zorla durdur` işleminin normal kapatma ve
swipe ile aynı olmadığını söyler; böylece iki farklı platform sonucu tek hata
gibi sunulmaz.

## Test kodu nasıl çalışıyor?

Saatlik ankraj testi:

```dart
expect(arguments['calledAt'], dueAt.millisecondsSinceEpoch);
expect(arguments['repeatIntervalMilliseconds'], 3600000);
expect(platform['scheduleMode'], 'exactAllowWhileIdle');
```

- İlk assertion future due'nun bir saat erkene çekilmediğini doğrular.
- İkinci assertion tekrar aralığının tam 60 dakika olduğunu doğrular.
- Üçüncü assertion native Android modunun exact olduğunu doğrular.

Postcondition testinde fake gateway schedule çağrısını kabul eder fakat pending
listeye kayıt eklemez:

```dart
notifications.omitPendingAfterSchedule = true;
final detail = await agenda.getReminderLifecycleDetail(reminder.id);
expect(detail.notification.syncState, NotificationSyncState.failed);
expect(detail.notification.safeErrorCode, 'native_schedule_failed');
```

Bu test exception atmayan fakat native plan bırakmayan plugin senaryosunu
simüle eder. Logical reminder yine okunabildiği için partial veri kaybı yoktur.

Fallback upgrade testi şu davranışı kanıtlar:

1. exact erişim `denied`;
2. bir inexact fallback ve bir logical reminder var;
3. binding güvenilir teslimat iddia etmiyor;
4. erişim `granted` olduğunda reconciliation çalışıyor;
5. fallback iptal edilip tek exact pending kalıyor;
6. ikinci reconciliation duplicate schedule oluşturmuyor.

## Teknik karar tablosu

| Karar | Seçilen | Neden | Reddedilen |
|---|---|---|---|
| Android zamanlama | Kullanıcı yönetimli `SCHEDULE_EXACT_ALARM` | 15/30/60 dakika saha kabulü ve resmi inexact tolerans sözleşmesi | Sessiz inexact başarı |
| Store politikası | `SCHEDULE_EXACT_ALARM` | Kullanıcının açıp kapatabildiği özel erişim | Broad `USE_EXACT_ALARM` |
| Erişim reddi | Logical row + açık degraded fallback | Veri kaybı yok, yanlış garanti yok | Reminder'ı silmek |
| Başarı ölçütü | Schedule + pending postcondition | Native plan kanıtlanır | Exception çıkmamasını başarı saymak |
| Process kapalı teslimat | AlarmManager + boot receiver | Platform-native ve kalıcı | Foreground service/polling |
| Tanı | İçeriksiz metadata | Gizlilik ve saha teşhisi | Başlık/not loglamak |
| Veri şeması | Schema `7` değişmez | Mevcut binding alanları yeterli | Gereksiz migration |

## Kod çalışma akışı

```text
Kullanıcı reminder planlar
        |
        v
SQLite transaction: row + append-only event + binding
        |
        v
notification + channel + exact erişim kontrolü
        |
        +-- granted --> exact native schedule
        |                    |
        |                    v
        |              pending postcondition
        |                    |
        |             +------+------+
        |             |             |
        |           var           yok
        |             |             |
        |       scheduled      failed + safe code
        |
        +-- exact denied --> inexact fallback + explicit unavailable
        |
        +-- notification/channel denied --> row korunur + ayar tanısı
```

## Şunu şöyle yaptık ki...

Şunu şöyle yaptık ki, kullanıcı hatırlatıcısı önce güvenilir SQLite transaction
içinde kaydedilsin; native Android schedule bundan sonra kurulsun ve pending
read-model ile kanıtlanmadan `scheduled` yazılmasın. Exact erişim yoksa kayıt
silinmesin, fakat inexact fallback de sessizce güvenilir gösterilmesin. Böylece
uygulama kapalıyken teslimat düzeldi, plugin veya izin hatasında kullanıcı verisi
korundu ve saha tanısı kullanıcı içeriğini loglamadan yapılabilir hale geldi.

## Yeni terimler

- **Postcondition verification:** Bir işlemden sonra beklenen durumun gerçekten
  oluştuğunu ayrı bir okuma ile doğrulama.
- **Exact alarm special access:** Android 12+ üzerinde kullanıcının sistem
  ayarından yönettiği, kesin zamanlı alarm kurma özel erişimi.
- **Degraded fallback:** Asıl garanti verilemediğinde çalışan fakat sınırlaması
  açıkça gösterilen yedek davranış.
- **App standby bucket:** Android'in uygulamayı kullanım sıklığına göre
  background çalışma sınıfına yerleştirmesi.
- **Boot reschedule audit:** Reboot sonrası pending planların yeniden kurulma
  denemesini içeriksiz durum/zaman metadata'sıyla kaydetme.
