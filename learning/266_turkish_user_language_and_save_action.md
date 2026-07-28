# Issue #266 — Flutter localization ve güvenilir kullanıcı eylemi

## Amaç

Bu adım iki benzer görünen fakat farklı teknik problemi birlikte çözdü:

1. uygulama metinleri Türkçe olsa bile Flutter'ın kendi buton ve seçim menüsü
   etiketlerinin neden İngilizce kalabildiği;
2. bir lifecycle durum adı olan `draft` ile kullanıcının yaptığı `Kaydet`
   eyleminin neden aynı metinde birleştirilmemesi gerektiği.

## Gerçek kod akışı

Flutter'ın `TextField`, date picker ve Cupertino bileşenleri kendi yerleşik
metinlerini `MaterialLocalizations`, `WidgetsLocalizations` ve
`CupertinoLocalizations` üzerinden çözer. Yalnız uygulama içindeki `Text`
widget'larını Türkçe yazmak bu katmanı değiştirmez.

Root sözleşmesi bu nedenle şöyledir:

```dart
static const locale = Locale('tr');
static const supportedLocales = <Locale>[locale];
static const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];
```

Puantaj save akışında görünür metin değişirken mutation aynı kaldı:

```dart
FilledButton.icon(
  key: const Key('save-attendance-draft'),
  onPressed: _submitting ? null : _save,
  label: const Text('Kaydet'),
)
```

Buradaki key ve `_save` çağrısı korunarak presentation dili ile domain
lifecycle'ı ayrıldı.

## Testlerin amacı

Localization testi cihaz locale'ini İngilizce fixture'a çevirir ve CSE'nin yine
Türkçe çözüldüğünü kanıtlar. Clipboard için yalnız sentetik veri kullanılır.

Global `debugDefaultTargetPlatformOverride` test binding tarafından izlenen bir
debug değişkenidir. Test içinde değiştirilip `addTearDown` ile geç sıfırlanması
bile invariant hatası üretebilir. Bunun yerine platform yalnız widget
route'unda belirlenir:

```dart
MaterialApp(
  theme: ThemeData(platform: TargetPlatform.android),
  // ...
)
```

Dar ekran testinde `find.text('Kaydet')` tek başına yeterli değildir. `ListView`
lazy oluşturulduğu için buton henüz widget tree'de bulunmayabilir. Exact route
root ve exact semantic key kullanılarak sınırlı kaydırma yapılır:

```dart
final root = find.byKey(const Key('attendance-day-detail'));
final scrollable = find
    .descendant(of: root, matching: find.byType(Scrollable))
    .first;
await tester.scrollUntilVisible(
  find.byKey(const Key('save-attendance-draft')),
  240,
  scrollable: scrollable,
  maxScrolls: 10,
);
```

## Saha karşılığı

Şantiye şefi `Kaydet` dediğinde verinin saklanmasını bekler. `Taslak`, günün
henüz tamamlanmadığını anlatan lifecycle durumudur; ana butonun eylem adı
değildir. Değişiklik bu ayrımı kullanıcıya açık tutarken tamamlanmış gün
sözleşmesini değiştirmez.

Türkçe seçim toolbar'ı ve date picker, cihaz dili farklı olsa bile sahada
karışık dil oluşmasını önler. Read-only alanda `Kes` ve `Yapıştır` gibi
uygunsuz eylemler zorla gösterilmez.

## Şunu şöyle yaptık ki...

- Root locale'i tek Türkçe yaptık ki cihaz dili ürünün kullanıcı dilini
  değiştirmesin.
- Canonical üç Flutter delegate'ini birlikte kullandık ki Material, Widgets ve
  Cupertino yüzeyleri aynı sözleşmeye uysun.
- `Kaydet` metnini değiştirip mutation key ve command'i koruduk ki kullanıcı
  dili sadeleşirken domain davranışı değişmesin.
- Test platformunu route-local theme ile kurduk ki global Flutter test
  invariant'ı bozulmasın.
- Exact root/scrollable/key kullandık ki 320 px testi yanlış listeyi
  kaydırmasın.
- Fiziksel smoke'u yalnız `CSE266SMOKE` kayıtlarıyla yaptık ki gerçek kullanıcı
  içeriği okunmasın veya değiştirilmesin.

## Bilinçli sınırlar

- Çoklu dil ve ARB kataloğu yoktur.
- Schema/migration/persistence değişikliği yoktur.
- Gerçek clipboard içeriği test kanıtına alınmaz.
- Fiziksel silme, uninstall, clear-data veya downgrade yapılmaz.
