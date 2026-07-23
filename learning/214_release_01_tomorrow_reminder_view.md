# Issue #214 — İstanbul Takvim Günüyle Yarın Projection'ı

## Neden UTC tarih parçasına bakmadık?

SQLite'taki reminder zamanı kanonik UTC biçimindedir. Kullanıcının “yarın”
dediği ise Europe/Istanbul takvim günüdür. Örneğin:

```text
UTC:       2026-07-22 21:30
İstanbul:  2026-07-23 00:30
```

UTC string `2026-07-22` ile başladığı hâlde kullanıcı için bu kayıt 23 Temmuz,
yani yarındır. `substring(0, 10)` veya UTC `DATE()` karşılaştırması yanlış kartı
üretirdi.

## Gerçek kod: yarını yerel takvimden üretmek

`mobile/lib/application/agenda_application.dart` içindeki hazırlık:

```dart
final now = _readClockOnce();
final today = CseTimeCodec.istanbulDayKey(CseTimeCodec.encodeUtc(now));
final bounds = CseTimeCodec.istanbulDayBounds(today);
final tomorrow = CseTimeCodec.shiftIstanbulDay(today, 1);
final tomorrowBounds = CseTimeCodec.istanbulDayBounds(tomorrow);
```

Satır satır:

1. Saat tek kez okunur; sorgu sırasında gün sınırı değişmez.
2. `now` kanonik UTC olur ve İstanbul yerel gün anahtarına çevrilir.
3. Bugünün sınırı mevcut Bugün/Gecikenler/Yaklaşanlar grupları için korunur.
4. Takvim günü `+1` kaydırılır; 23:59 üzerine süre ekleme yapılmaz.
5. Yarının yerel 00:00 sınırları kanonik UTC olarak üretilir.

Takvim günü kaydırmak önemlidir. “Şimdiye 24 saat ekle” yarının tüm gününü değil,
yalnız aynı saatten sonraki 24 saati verir.

## Gerçek kod: yarı açık SQL aralığı

Yeni switch kolu:

```dart
ReminderViewGroup.tomorrow => (
  "f.status IN ('active', 'waiting') AND "
      'f.next_attention_at >= ? AND f.next_attention_at < ?',
  <Object?>[tomorrowBounds.start, tomorrowBounds.endExclusive],
),
```

Satır satır:

1. Yalnız kullanıcı açısından açık olan `active` ve `waiting` seçilir.
2. `>= start`, yarın 00:00 kaydını dahil eder.
3. `< endExclusive`, sonraki gün 00:00 kaydını hariç tutar.
4. Parametreler kanonik UTC'dir; string sırası kronolojik sırayla aynıdır.
5. `NULL` değer aralık koşulunu sağlamaz; Unutma Kutusu ayrıca görünmez.

Bu `[başlangıç, bitiş)` biçimine **yarı açık aralık** denir. Yan yana iki gün
aynı 00:00 kaydını iki kez sahiplenmez.

## Gerçek kod: Puantaj helper'ını paylaşmak

Issue #212 helper'ı artık iki projection için kullanılır:

```dart
return group == ReminderViewGroup.upcoming ||
        group == ReminderViewGroup.tomorrow
    ? _collapseAttendanceRemindersByProject(reminders)
    : reminders;
```

Helper SQL'in due sırasını bozmadan ilerler. `attendanceDayId` veya `projectId`
yoksa reminder bağımsızdır ve doğrudan eklenir. Aynı proje kimliği ikinci kez
görüldüğünde yalnız UI sonucundan atlanır; DB satırı, link ve event silinmez.

## Gerçek kod: filtre ile mutation'ı ayırmak

Kart eylemi koşulu `Yarın` grubunu bilerek içermez:

```dart
final showTomorrow =
    (_group == ReminderViewGroup.now ||
        _group == ReminderViewGroup.overdue ||
        _group == ReminderViewGroup.upcoming) &&
    (reminder.status == ReminderStatus.active ||
        reminder.status == ReminderStatus.waiting);
```

Buradaki iki “Yarın” farklı kavramdır:

- filtre: yarın due kayıtları okur, mutation yapmaz;
- eylem: reminder due değerini yarına taşır.

Yarın listesindeki kayıt zaten bu güne aittir. Bu yüzden kart eylemi gizlenir;
detay sayfasındaki genel yaşam döngüsü eylemi değişmez.

Filtre dokunma hedefi:

```dart
ConstrainedBox(
  constraints: const BoxConstraints(minHeight: 48),
  child: ChoiceChip(
    key: Key('reminder-group-${group.name}'),
    label: Text(_label(group)),
    selected: _group == group,
    onSelected: (_) {
      setState(() => _group = group);
      _reload();
    },
  ),
)
```

`Wrap` dar ekranda yeni satır açar; `ConstrainedBox` her filtreyi en az 48 px
tutar. Chip yalnız grubu değiştirir ve source-of-truth'tan yeniden okur.

## Test kodu neyi doğruluyor?

Timezone sınır testinin beklenen sonucu:

```dart
expect(tomorrow.map((item) => item.id), [
  tomorrow0000.id,
  utcDateDiffers.id,
  waiting.id,
  tomorrow2359.id,
]);
```

Satır satır:

1. Yerel yarın 00:00 başlangıca eşit olduğu için dahildir.
2. UTC tarihi “bugün”, İstanbul tarihi “yarın” olan 00:30 kaydı dahildir.
3. `waiting` takip edilebilir açık durum olduğu için dahildir.
4. Yerel 23:59 bitişten küçük olduğu için dahildir.
5. Sonraki 00:00, bugün/geçmiş, terminal ve due-null kayıtlar ayrı assertion ile
   dışlanır.

Projection'ın salt-okunur kaldığı da ölçülür:

```dart
expect(
  (await agenda.getReminderDetail(tomorrow0000.id)).revision,
  tomorrow0000.revision,
);
expect(await agenda.listReminderEvents(tomorrow0000.id), hasLength(1));
```

Listeyi açmak revision artırmamış ve yeni event yazmamıştır.

Puantaj testinde fiziksel ve görünür adet birlikte tutulur:

```dart
expect(physicalTomorrowAttendance, 3);
expect(attendanceItems, hasLength(2));
expect(attendanceItems.map((item) => item.projectId).toSet(), {
  project1,
  project2,
});
```

Aynı projeye ait iki yarın occurrence fiziksel olarak kalır; iki proje için
yalnız iki temsilci kart görünür. Bağımsız yarın reminder'ı üçüncü karttır.

Widget testi 320 px dark ve 430 px light yapılandırmalarında filtreyi görünür
kılar, 48 px yüksekliği ölçer, karttaki hızlı mutation'ın yokluğunu ve karttan
detay sayfasına geçildiğini doğrular. Detaydaki `snooze-tomorrow` ayrıca
korunmuştur.

## Teknik karar tablosu

| Karar | Seçim | Neden |
|---|---|---|
| Gün anlamı | Europe/Istanbul yerel takvimi | Kullanıcı niyeti ve mevcut time contract |
| Aralık | `[00:00, sonraki 00:00)` | Sınırda çakışma veya boşluk üretmez |
| Saat okuma | Bir kez | Gece yarısı yarışını önler |
| Filtre katmanı | Mevcut `ReminderViewGroup` read-model'i | Schema/migration gerektirmez |
| Puantaj grouping | Ortak proje helper'ı | Upcoming ile aynı deterministic sözleşme |
| Yarın kart eylemi | Gizli | Filtre ve mutation isim çakışmasını önler |
| Detay eylemi | Korundu | Genel lifecycle yeteneğini kaldırmaz |
| Empty state | Sade kullanıcı mesajı | Teknik diagnostic olmayan gerçek boşluk |
| Schema/backup | `7` / `1` | Yalnız query/UI değişti |

## Kod çalışma akışı

```text
Kullanıcı Yarın filtresine dokunur
    |
    +-- clock bir kez okunur
    +-- UTC now -> İstanbul bugün anahtarı
    +-- bugün + 1 -> yarın anahtarı
    +-- yarın yerel 00:00 sınırları -> kanonik UTC
    +-- SQL active/waiting ve [start, end) sorgusu
    +-- due/id deterministic sıralama
    +-- Puantaj ise proje başına ilk kayıt
    +-- bağımsız reminder ise aynen koru
    +-- UI kartı göster; hızlı Yarın mutation'ı gösterme
    +-- karta dokunulursa aynı reminder detail'ini aç
```

## Şunu şöyle yaptık ki...

Şunu şöyle yaptık ki, “yarın” kavramını UTC dosya biçiminden değil kullanıcının
Europe/Istanbul takviminden türettik; gece yarısı ve UTC tarih farkı kayıtları
yanlış gruba düşmesin. Puantaj zincirini silmeden proje başına yalnız en erken
yarın kartını gösterdik ki saha listesi sade kalırken rolling horizon ve native
planlar korunsun. Yarın filtresindeki kart mutation'ını gizledik ki kullanıcı
filtre adıyla erteleme komutunu karıştırmasın; detay ve diğer üç yüzeydeki eylem
yeteneği kaybolmasın.

## Yeni terimler

- **Yarı açık zaman aralığı:** Başlangıcı dahil, bitişi hariç `[start, end)`
  aralığıdır.
- **Yerel takvim projection'ı:** UTC saklanan kayıtları kullanıcı timezone'ının
  gün sınırlarıyla seçen read-model'dir.

## Bilerek değiştirmediklerimiz

- SQLite schema `7` ve `.csebackup` format `1`;
- reminder oluşturma/mutation/event sözleşmesi;
- exact notification, payload/deep-link ve boot reconciliation;
- 14 günlük Puantaj occurrence üretimi ve fiziksel kayıtlar;
- debug package kimliği ve cihazdaki kullanıcı verisi;
- Şimdi ilgilen, Gecikenler, Yaklaşanlar kartlarındaki hızlı `Yarın`;
- reminder detayındaki genel `Yarın` eylemi.

## Saha kanıtını nasıl yorumladık?

Fiziksel cihazda kurulumdan hemen önce ve sonra, uygulama açılmadan alınan aynı
DB hash'i gerçek veri-koruma kapısıdır. Uygulama daha sonra normal bootstrap ve
notification reconciliation çalıştırabilir; bu yüzden sonraki DB hash'inin
değişmesi tek başına veri kaybı değildir. Son snapshot'ta schema `7`, SQLite
`integrity_check=ok` ve sıfır foreign-key ihlali ayrıca doğrulanmıştır.

Yarın görünümünde gerçek başlıklar okunmadan yalnız yapısal sayılar tutuldu:

```text
yarın fiziksel Puantaj = 1
yarın benzersiz proje = 1
yarın bağımsız reminder = 0
beklenen görünür kart = 1
gerçek görünür kart = 1
```

Otomatik test ise daha zor olan üç fiziksel Puantaj / iki proje senaryosunu
kurar. Böylece tek projeli gerçek cihaz kabulü ile çok occurrence'lı test kabulü
birbirini tamamlar.
