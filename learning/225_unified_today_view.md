# Issue #225 — Birleşik Bugün Read-Modeli Öğrenme Notu

## Amaç

Bu adımda reminder verisini değiştirmeden, kullanıcının “Bugün ne yapmalıyım?”
sorusuna tek application çıktısıyla cevap verdik. Aynı source kayıtlar yeni
tabloya kopyalanmadı; yalnız görünüm için sınıflandırıldı.

## Hangi dosyada ne yaptık?

| Dosya | Değişiklik | Neden |
| --- | --- | --- |
| `mobile/lib/application/agenda_application.dart` | Saf Bugün sınıflandırıcısı ve SQLite read-model | Zaman kararını UI'dan çıkarmak |
| `mobile/lib/features/reminders/reminders_page.dart` | Üç bölüm ve sade filtreler | Filtre seçmeden bugünü göstermek |
| `mobile/test/agenda_application_test.dart` | 18.00, sınır, tekilleştirme ve sıralama testleri | Ürün sözleşmesini executable yapmak |
| `mobile/test/reminder_widget_test.dart` | Bölüm, label, menü ve erişilebilirlik testleri | Kullanıcı yüzeyini doğrulamak |
| `mobile/test/support/fake_agenda_application.dart` | Bugün capability fake'i | Widget testini gerçek DB'den ayırmak |

## Saf sınıflandırma nasıl çalışıyor?

Özet fonksiyon:

```dart
ReminderTodayOverview buildReminderTodayOverview(
  Iterable<MobileReminder> reminders, {
  required DateTime asOfUtc,
})
```

Satır satır anlamı:

1. `reminders`, kalıcı kaynaklardan okunmuş aday kayıtlardır.
2. `asOfUtc`, sınıflandırmanın tek zaman referansıdır.
3. Fonksiyon saat okumaz; aynı input aynı output'u üretir.
4. UTC değer Europe/Istanbul yerel gün ve saate codec ile çevrilir.
5. Sonuç üç görünür liste ve bir inbox sayısıdır.

Önce kimlik tekilleştirmesi yapılır:

```dart
final unique = <String, MobileReminder>{};
for (final reminder in reminders) {
  unique.putIfAbsent(reminder.id, () => reminder);
}
```

Bu kodda:

1. Map anahtarı logical reminder kimliğidir.
2. Aynı reminder query/join nedeniyle iki kez gelirse ilk temsilci korunur.
3. Puantaj/Beton source türü kimliği değiştirmez.
4. Sonraki sınıflandırma her reminder'ı yalnız bir kez görür.

## 18.00 kuralı

```dart
final localNow = CseTimeCodec.toIstanbul(asOf);
final allDayCutoffReached = localNow.hour >= 18;
```

Satır satır:

1. `asOf`, canonical UTC string'dir.
2. `toIstanbul`, UTC tarih parçasına bakmak yerine gerçek yerel saati üretir.
3. Saat 17 iken eşik false'tur; dakika ve saniye ne olursa olsun kayıt Tam gün
   bölümünde kalır.
4. Saat tam 18 olduğunda eşik true olur ve kayıt Gecikenler'e geçer.
5. Project ayarı veya yeni database kolonu yoktur.

All-day dalı:

```dart
if (allDayLocalDate.compareTo(today) < 0 ||
    (allDayLocalDate == today && allDayCutoffReached)) {
  overdue.add(reminder);
} else if (allDayLocalDate == today) {
  allDayToday.add(reminder);
}
```

Geçmiş gün her saatte gecikmiştir. Bugünün günü yalnız eşik sonrasında
gecikmiştir. Yarın ve daha ileri gün Bugün sonucuna girmez.

## Timed reminder kararı

```dart
if (due.isBefore(asOfUtc)) {
  overdue.add(reminder);
} else if (CseTimeCodec.istanbulDayKey(nextAttentionAt) == today) {
  timedToday.add(reminder);
}
```

Burada `isBefore`, Issue'daki kesin `< asOfUtc` kuralıdır. Due tam `asOfUtc`
ile eşitse henüz gecikmiş sayılmaz. Yerel gün karşılaştırması UTC gününe göre
yanlış `Yarın` etiketi oluşmasını engeller.

## SQLite neden sınıflandırma yapmıyor?

SQLite sorgusu yalnız gerekli adayları daraltır:

```sql
status = 'inbox'
OR (
  status = 'active'
  AND (
    next_attention_at < today_end
    OR all_day_local_date <= today
  )
)
```

18.00 ve bölüm kararları saf Dart fonksiyonundadır. Böylece:

- testler gerçek saat beklemez;
- UI aynı kararı tekrar etmez;
- SQL timezone mantığı taşımak zorunda kalmaz;
- schema değişmez.

## UI akışı

```text
RemindersPage açılır
-> ReminderTodayApplication çağrılır
-> ReminderTodayOverview gelir
-> boş olmayan bölüm başlıkları çizilir
-> her reminder tek kart olur
-> inbox varsa ikincil görünüm eylemi gösterilir
```

Ana ChoiceChip'ler yalnız `Bugün`, `Yarın` ve `Diğer`dir. `Diğer`, mevcut dört
ikincil read-modeli bottom sheet üzerinden seçer.

## Kart etiketi neden section'dan gelir?

Tek timestamp farklı yüzeylerde farklı kullanıcı anlamı taşır:

| Bölüm | Etiket |
| --- | --- |
| Geciken timed | `Gecikti • tarih/saat` |
| Saatli bugün | `Bugün • HH:mm` |
| Tam gün | `Tam gün` |
| Yarın timed | `Yarın • HH:mm` |
| Yarın all-day | `Yarın • Tam gün` |

Label, storage değerini değiştirmez. `Yarın` action butonu ise label'dan ayrı,
mevcut snooze mutation'ıdır.

## Test kodu neyi doğruluyor?

Application testi saati iki kez ilerletir:

```dart
now = DateTime.utc(2026, 12, 31, 14, 59, 59); // İstanbul 17:59:59
final beforeCutoff = await agenda.getReminderTodayOverview();

now = DateTime.utc(2026, 12, 31, 15); // İstanbul 18:00:00
final atCutoff = await agenda.getReminderTodayOverview();
```

İlk okumada bugünkü all-day `allDayToday` içindedir. İkinci okumada aynı kayıt
`overdue` içindedir. 31 Aralık → 1 Ocak örnekleri yıl sınırını da doğrular.

Aynı test:

- timed geçmiş/gelecek ayrımını;
- inbox ve terminal dışlamasını;
- importance/created/id sırasını;
- hiçbir kimliğin iki bölümde olmadığını;
- yarın timed/all-day kayıtların Bugün dışında kaldığını

kontrol eder.

Widget testleri:

- açılışta Bugün chip'inin seçili olduğunu;
- üç bölümün aynı scroll yüzeyinde göründüğünü;
- boş bölümün saklandığını;
- yalnız üç ana ChoiceChip bulunduğunu;
- `Diğer` menüsündeki dört görünümü;
- inbox count eylemini;
- Bugün kartında yanlış `Yarın •` label'ı olmadığını;
- Yarın action touch target'ının korunduğunu

doğrular.

## Teknik karar tablosu

| Karar | Alternatif | Neden |
| --- | --- | --- |
| Saf application classifier | UI içinde DateTime koşulları | Tek test edilebilir karar noktası |
| Tek `asOfUtc` | Her kartta `DateTime.now()` | Yarış ve sınır tutarsızlığını önler |
| ID ile tekilleştirme | Source türüne göre kart | Logical reminder tek karttır |
| 18.00 sabit ürün varsayımı | Project DB ayarı | Bitişik schema migration açmamak |
| Üç ana filtre | Sekiz ChoiceChip | Saha ekranını sade tutmak |
| İkincil bottom sheet | Görünümleri silmek | Mevcut erişimi korumak |

## Yeni terim

`Birleşik Bugün Read-Modeli`, aktif reminder'ları tek bir zaman referansında
Gecikenler, Saatli bugün ve Tam gün bölümlerine ayıran, inbox sayısını ayrıca
taşıyan ve storage kaydını değiştirmeyen application projeksiyonudur. Kalıcı
tanım `learning/GLOSSARY.md` içine eklendi.

## Şunu şöyle yaptık ki...

- Şunu şöyle yaptık ki saat 18.00 sınırında iki farklı ekran kararı oluşmasın:
  tek `asOfUtc` değerini Europe/Istanbul saatine çevirdik.
- Şunu şöyle yaptık ki aynı reminder Puantaj veya Beton bağlantısı nedeniyle
  iki kez görünmesin: sınıflandırmadan önce ID ile tekilleştirdik.
- Şunu şöyle yaptık ki kullanıcı bugünkü işi görmek için sekiz filtre arasında
  dolaşmasın: varsayılan ekranda üç bölümü birlikte gösterdik.
- Şunu şöyle yaptık ki eski görünümler kaybolmasın: dört ikincil görünümü
  `Diğer` bottom sheet'inde koruduk.
- Şunu şöyle yaptık ki yeni UI işi veri riskine dönüşmesin: schema, backup ve
  notification katmanlarını değiştirmedik.

## Bilinçli olarak yapılmayanlar

Project-level 18.00 ayarı, trash/restore, attachment görünürlüğü, Beton/Puantaj
ürün genişletmeleri, release altyapısı ve ana uygulama navigasyon dönüşümü bu
adımda başlatılmadı.
