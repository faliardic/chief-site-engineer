# Issue #212 — Read-Model Tekilleştirme ve Hatırlatıcı Durumu Öğrenme Notu

## Problem neden veri silerek çözülmedi?

Günlük Puantaj ayarı tek bir UI kartı değil, gelecekteki günleri hazır tutan 14
günlük bir zincir üretir. Her occurrence kendi Puantaj günü ve kendi reminder
bağlantısıdır. Bunların on üçünü silmek, sonraki günün hazır olması, restart,
backup/restore ve append-only geçmiş sözleşmelerini bozar.

Bu yüzden iki katmanı ayırdık:

- **write-model:** SQLite'taki bütün gerçek kayıtlar;
- **read-model:** belirli bir ekranda kullanıcıya gösterilen sonuç.

Tekilleştirme yalnız `Yaklaşanlar` read-model'inde çalışır.

## Gerçek kod: proje başına ilk Puantaj

`mobile/lib/application/agenda_application.dart` içindeki yardımcı:

```dart
List<MobileReminder> _collapseUpcomingAttendanceReminders(
  List<MobileReminder> reminders,
) {
  final visible = <MobileReminder>[];
  final attendanceProjects = <String>{};
  for (final reminder in reminders) {
    if (reminder.attendanceDayId == null || reminder.projectId == null) {
      visible.add(reminder);
      continue;
    }
    if (attendanceProjects.add(reminder.projectId!)) {
      visible.add(reminder);
    }
  }
  return List.unmodifiable(visible);
}
```

Satır satır:

1. Girdi, SQL'in `next_attention_at ASC` ile sıraladığı reminder listesidir.
2. `visible`, ekrana dönecek yeni listedir; kaynak liste değişmez.
3. `attendanceProjects`, hangi proje için ilk Puantajın alındığını tutar.
4. Döngü due sırasını bozmadan ilerler.
5. Puantaj bağlantısı veya proje kimliği yoksa kayıt bağımsızdır; doğrudan eklenir.
6. `Set.add` bir proje kimliğini ilk kez gördüğünde `true` döndürür.
7. Bu nedenle yalnız due sırasındaki ilk Puantaj görünür.
8. `List.unmodifiable`, tüketicinin sonuç üzerinde yanlışlıkla mutation yapmasını
   engeller.

Bu yardımcı yalnız şu sınırda çağrılır:

```dart
return group == ReminderViewGroup.upcoming
    ? _collapseUpcomingAttendanceReminders(reminders)
    : reminders;
```

Şimdi, Gecikenler, Beklenenler ve geçmiş ekranlarının sözleşmesi değiştirilmez.
İlk kayıt tamamlandığında SQL filtresinden çıkar; aynı projection bir sonraki
due kaydı ilk olarak görür. Ek bir “sıradakini aç” mutation'ı gerekmez.

## Gerçek kod: `Yarın` zaman hesabı

Mevcut application mutation'ı yeniden kullanıldı:

```dart
values['next_attention_at'] = current.nextAttentionAt == null
    ? _tomorrowMorning(now)
    : _tomorrowAtSameLocalTime(current.nextAttentionAt!, now);
```

- `nextAttentionAt == null`: yarının İstanbul takvim günü, saat 09:00.
- due varsa: due önce İstanbul yerel zamanına çevrilir; saat ve dakika korunup
  tarih yarına taşınır.
- hesap UTC'ye kanonik biçimde yazılır; UI yine İstanbul saatini gösterir.

`Yarın` için yeni bir ikinci servis yolu açılmadı. Detay ve kartlar aynı
`ReminderMutationAction.snoozeTomorrowMorning` komutuna gider. Böylece optimistic
revision, event, no-op ve native reconciliation tek yerde kalır.

Karttaki gerçek dokunma hedefi:

```dart
TextButton.icon(
  key: Key('reminder-tomorrow-${reminder.id}'),
  style: TextButton.styleFrom(minimumSize: const Size(88, 48)),
  onPressed: _tomorrowBusy.contains(reminder.id)
      ? null
      : () => _moveToTomorrow(reminder),
  icon: const Icon(Icons.wb_sunny_outlined),
  label: const Text('Yarın'),
)
```

Satır satır:

1. Her reminder benzersiz test/semantik anahtarına sahiptir.
2. 48 px yükseklik dar ekranda güvenli dokunma hedefidir.
3. ID busy set'indeyse buton pasif olur.
4. İlk dokunma bitmeden ikinci dokunma application mutation'ına ulaşamaz.
5. Kartın kendisi detaya gitmeye devam eder; `Yarın` ise doğrudan işlem yapar.

## Gerçek kod: gecikme önce, altyapı arızası sonra

Tanı sınıflandırmasının ilgili kısmı:

```dart
if (!due.isAfter(now)) return ReminderDeliveryDelayClass.overdue;
if (nativePresent) return ReminderDeliveryDelayClass.pending;
return ReminderDeliveryDelayClass.nativeScheduleMissing;
```

Sıra önemlidir. Due geçmişse native pending kaydının bulunmaması artık geçmiş
işi bir “kritik planlama arızası” gibi sunmaz. Kayıt `Gecikti` olur. Due hâlâ
gelecekteyse native plan yokluğu gerçek teslimat riski olduğu için kritik kalır.

Terminal kayıtların detay UI'ı diagnostic kartı ayrıca gizler. Tamamlanmış veya
iptal edilmiş bir reminder'ın artık gelecekte teslim edilmesi beklenmez.

## Test kodu neyi doğruluyor?

Puantaj zincirinin fiziksel olarak korunduğu ve UI projeksiyonunun küçüldüğü
aynı testte doğrulanır:

```dart
expect(await _count(directories.databaseFile, 'follow_up_items'), 29);
expect(upcoming, hasLength(3));
expect(attendanceItems, hasLength(2));
expect(upcoming.map((item) => item.id), contains(independent.id));
```

Satır satır:

1. İki proje × 14 Puantaj ve bir bağımsız reminder = 29 fiziksel kayıt kalır.
2. Yaklaşanlar read-model'i yalnız üç kayıt döndürür.
3. Bunların ikisi proje başına birer Puantajdır.
4. Bağımsız reminder grouping sırasında kaybolmamıştır.

`Yarın` no-op testi event ve native plan sayısını birlikte kontrol eder:

```dart
expect(unchanged.revision, scheduled.revision);
expect(await agenda.listReminderEvents(scheduled.id), hasLength(eventCount));
expect(notifications.scheduled, hasLength(nativeScheduleCount));
```

Hedef zaten yarın aynı yerel saatteyse revision artmaz, event eklenmez ve native
plan gereksiz yere tekrar yazılmaz. Transaction hook testi ise `Yarın`
mutation'ını ortada düşürür; logical reminder, event ve binding birlikte eski
halinde kalır. Widget testi pending future ile çift dokunuşu, typed stale hata
ile mesajın kullanıcıya görünmesini ölçer.

## Teknik karar tablosu

| Karar | Seçim | Neden |
|---|---|---|
| Tekilleştirme katmanı | `Yaklaşanlar` read-model'i | Fiziksel Puantaj/reminder/event kayıtlarını korur |
| Group anahtarı | `projectId`, yalnız `attendanceDayId != null` | Bağımsız reminder'ları yanlışlıkla birleştirmez |
| Görünen kayıt | Due sırasındaki ilk | Kullanıcının gerçek bir sonraki işini gösterir |
| `Yarın` servisi | Mevcut mutation | Revision, no-op, rollback ve reconciliation tek sözleşmede kalır |
| Due olan saat | İstanbul saat/dakikası korunur | UTC farkı kullanıcı niyetini değiştirmez |
| Due olmayan saat | Yarın 09:00 İstanbul | Deterministik ve saha için anlaşılır varsayılan |
| Geçmiş aktif tanısı | `Gecikti` | İş durumu, yanlış altyapı alarmından önce gelir |
| Gelecek native eksikliği | Kritik tanı korunur | Gerçek notification teslimat riski görünür kalır |
| Schema/backup | `7` / `1` aynı | Projection ve enum değişikliği migration gerektirmez |
| Windows build önkoşulu | Yalnız üretilmiş ağaçlarda read-only özniteliğini kaldır | Temiz build'i deterministik kılar; kaynak ve cihaz verisine dokunmaz |

## Saha build'i neden üretilmiş dizin özniteliğini düzeltiyor?

Windows üzerindeki `V:` çalışma alanında Flutter'ın daha önce ürettiği bazı
dosyalar read-only özniteliği taşıyabiliyor. `flutter clean` bu dosyayı
kaldıramadığında eski `app-debug.apk` kalabilir. Bu durumda yeni sidecar'ı eski
çıktı sanma riski olduğu için release kapısı sessizce devam etmez.

Her iki build betiğinde kullanılan yardımcı şöyledir:

```powershell
function Clear-GeneratedReadOnlyAttributes {
    $attrib = Join-Path $env:SystemRoot 'System32\attrib.exe'
    foreach ($generatedRoot in @(
        (Join-Path $mobileRoot 'build'),
        (Join-Path $mobileRoot '.dart_tool'),
        (Join-Path $mobileRoot 'ios\Flutter\ephemeral')
    )) {
        if (-not (Test-Path -LiteralPath $generatedRoot)) { continue }
        Invoke-Checked -Command $attrib -Arguments @('-R', $generatedRoot)
        Invoke-Checked -Command $attrib -Arguments @(
            '-R', (Join-Path $generatedRoot '*'), '/S', '/D'
        )
    }
}
```

Satır satır:

1. Windows'un kendi `attrib.exe` yolu açıkça çözülür.
2. Allowlist yalnız Flutter'ın yeniden ürettiği üç ağacı kapsar.
3. `-LiteralPath`, wildcard ile yanlış bir kökün seçilmesini engeller.
4. İlk çağrı kökün, ikinci çağrı `-R /S /D` ile alt ağacın yalnız read-only
   özniteliğini kaldırır.
5. `Invoke-Checked` komut başarısızsa build'i durdurur; eski artifact üzerinden
   devam edilmez.

Kaynak kod, doküman, Android paket sandbox'ı, SQLite dosyası ve backup bu
allowlist'te değildir. Yardımcı `flutter clean` öncesinde çalışır; clean sonrası
mevcut APK kontrolü, timestamp ve entrypoint marker doğrulaması yine zorunludur.

## Kod çalışma akışı

```text
Yaklaşanlar açılır
    |
    +-- SQL aktif, future kayıtları due sırasıyla okur
    +-- bağımsız reminder -> doğrudan görünür
    +-- Puantaj -> projectId ilk kez görülüyorsa görünür
    +-- sonraki aynı-proje Puantajlar DB'de kalır, UI'da atlanır

Yarın dokunulur
    |
    +-- busy guard
    +-- expectedRevision ile snoozeTomorrowMorning
    +-- due varsa yerel saati koru / yoksa 09:00
    +-- transaction: reminder + event + binding
    +-- commit sonrası native reconciliation
    +-- ekranı source-of-truth'tan yeniden oku

Detay tanısı okunur
    |
    +-- delivered ise gecikme süresini sınıflandır
    +-- delivered değil ve due <= now -> Gecikti
    +-- future + native var -> Bekliyor
    +-- future + native yok -> kritik Native plan bulunamadı
```

## Şunu şöyle yaptık ki...

Şunu şöyle yaptık ki, kullanıcı yalnız sıradaki Puantajı görürken arkadaki 14
günlük zincirin hiçbir kaydını feda etmedik. `Yarın` eylemini bütün gerekli
yüzeylerde aynı application mutation'ına bağladık ki çift dokunuş, stale
revision, no-op, transaction rollback ve native yeniden planlama birbirinden
ayrılmasın. Geçmiş due kaydı da önce gerçek iş durumu olan `Gecikti` diye
sınıflandırıldı ki kullanıcı çözmesi gerekmeyen kritik altyapı alarmıyla
karşılaşmasın.

Üretilmiş Flutter ağacındaki Windows read-only özniteliğini dar bir allowlist
ile kaldırdık ki clean build kapısı eski APK yüzünden belirsiz kalmasın; hata
durumunda durarak kaynak dosyalara veya cihazdaki `.debug` verisine yönelmesin.

## Yeni terimler

- **Read-model tekilleştirme:** Kaynak kayıtları silmeden, belirli bir görünümde
  aynı iş zincirinin yalnız temsilci kaydını gösterme.
- **Projection:** Kalıcı veriden bir ekran veya rapor için türetilen okuma şekli.
- **Business-state precedence:** Kullanıcının iş durumunu, yalnız geçerli olduğu
  yerde altyapı tanısından önce sınıflandırma kuralı.

## Bilerek değiştirmediklerimiz

- 14 günlük occurrence üretimi ve linked reminder kayıtları;
- SQLite schema `7` ve `.csebackup` format `1`;
- notification payload/deep-link kimliği;
- append-only event ve optimistic revision sözleşmeleri;
- gelecekte due olup native planı olmayan kayıtların kritik tanısı;
- `.debug` application ID ve cihazdaki kullanıcı verisi.
