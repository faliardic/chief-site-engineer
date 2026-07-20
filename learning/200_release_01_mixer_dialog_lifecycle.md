# Issue #200 — Flutter Dialog Yaşam Döngüsünü Güvenli Yönetmek

Bu öğrenme notunda bir dialog kapatılırken `showDialog` future'ının tamamlanması
ile dialog widget ağacının gerçekten dispose edilmesi arasındaki farkı
inceleyeceğiz. Örneğimiz Beton Paketi'ndeki yeni/mevcut mikser formudur.

## 1. Hata neden yalnız bazen görünüyordu?

Eski akış sadeleştirilmiş biçimde şöyleydi:

```dart
final plate = TextEditingController();
final draft = await showDialog<_TruckDraft>(
  context: context,
  builder: (_) => TextField(controller: plate),
);
plate.dispose();
```

Kod ilk bakışta mantıklı görünür: dialog sonucu geldi, controller artık gereksiz
sanılır. Flutter route lifecycle'ında ise iki ayrı olay vardır:

1. `Navigator.pop` result future'ını tamamlar.
2. Route reverse transition ile ekrandan ayrılır.
3. Son animasyon frame'leri render edilir.
4. Route widget ağacı unmount olur ve State `dispose()` çalışır.

Parent üçüncü adım tamamlanmadan `plate.dispose()` çağırırsa TextField hâlâ aynı
controller'ı kullanabilir. Bu zamanlama cihaz, frame süresi ve klavye durumuna
göre değişebildiği için hata aralıklıdır.

## 2. Sahiplik kuralı

Kaynağı kullanan State, kaynağın sahibi olmalıdır. Yeni dialog iskeleti:

```dart
class _TruckDialog extends StatefulWidget {
  const _TruckDialog({required this.current, required this.initialDraft});

  final ConcreteTruck? current;
  final _TruckDraft? initialDraft;

  @override
  State<_TruckDialog> createState() => _TruckDialogState();
}
```

Satır satır:

1. Dialog artık `StatefulBuilder` closure'ı değildir; gerçek bir StatefulWidget'tır.
2. `current`, edit akışındaki mevcut persistent kaydı taşır.
3. `initialDraft`, başarısız mutation sonrası korunan kullanıcı girdisidir.
4. Parent controller değil yalnız domain/read-model verisi verir.

Controller oluşturma dialog State'e taşınır:

```dart
class _TruckDialogState extends State<_TruckDialog> {
  late final TextEditingController _plate;
  late final TextEditingController _deliveryNote;
  late final TextEditingController _volume;
  late final TextEditingController _note;
  late final TextEditingController _reason;

  @override
  void initState() {
    super.initState();
    final current = widget.current;
    final draft = widget.initialDraft;
    _plate = TextEditingController(
      text: draft?.plate ?? current?.vehiclePlate,
    );
  }
}
```

- `late final`, controller'ın State ömründe bir kez atanacağını anlatır.
- Önce retry draft, yoksa current record okunur.
- TextField ile controller aynı State ağacında yaşar.
- Parent dialog kapanış zamanlamasına müdahale etmez.

## 3. Dispose doğru yerde nasıl çalışıyor?

```dart
@override
void dispose() {
  _plate.dispose();
  _deliveryNote.dispose();
  _volume.dispose();
  _note.dispose();
  _reason.dispose();
  super.dispose();
}
```

Buradaki sıra önemlidir:

1. State'in sahip olduğu kaynaklar kapatılır.
2. Son olarak `super.dispose()` çağrılır.
3. Flutter bu methodu ancak route widget ağacını gerçekten kaldırırken çağırır.
4. Reverse animation sürerken controller'lar geçerli kalır.

Bu nedenle çözüm sabit bir milisaniye beklemeye dayanmaz. Tema animasyon süresi
değişse bile sahiplik kuralı geçerlidir.

## 4. Immutable draft neden kullanıldı?

Parent sayfaya TextEditingController göndermek yerine value object döndürülür:

```dart
class _TruckDraft {
  const _TruckDraft({
    required this.plate,
    required this.deliveryNote,
    required this.volume,
    required this.result,
    required this.arrivedAt,
    required this.unloadingStartedAt,
    required this.unloadingEndedAt,
    required this.note,
    required this.reason,
  });

  final String plate;
  final String deliveryNote;
  final double volume;
  final ConcreteTruckResult result;
  final String? arrivedAt;
  final String? unloadingStartedAt;
  final String? unloadingEndedAt;
  final String note;
  final String reason;
}
```

Immutable demek, alanların nesne oluşturulduktan sonra değişmemesidir. Parent
şunları kazanır:

- controller lifecycle bilgisine ihtiyaç duymaz;
- bütün form değerlerini tek snapshot olarak alır;
- validation failure sonrası aynı değerleri yeniden açabilir;
- testte command ile draft değerlerini doğrudan karşılaştırabilir.

## 5. Double tap neden senkron guard ister?

Sadece parent `_mutating` bayrağı yeterli değildir. Dialog iki submit callback'i
aynı frame içinde üretebilir. Dialog içi guard:

```dart
bool _closing = false;

void _submit() {
  if (_closing) return;
  // Parse ve validation burada yapılır.
  _closing = true;
  Navigator.pop(context, draft);
}
```

Satır satır:

1. İkinci callback `_closing == true` görür ve çıkar.
2. Guard `await` öncesinde senkron değiştirilir; event-loop yarış penceresi yoktur.
3. Tek `Navigator.pop` tek draft future sonucu üretir.
4. Parent tek `saveTruck` çağrısı başlatır.

Widget testi callback'i aynı frame içinde iki kez çağırır:

```dart
final save = find.byKey(const Key('save-concrete-truck'));
final saveCallback = tester.widget<FilledButton>(save).onPressed!;
saveCallback();
saveCallback();
await tester.pumpAndSettle();

expect(concrete.saveTruckCalls, 1);
```

Bu test ikinci fiziksel tap'in transition overlay tarafından yutulmasına güvenmez;
doğrudan dialog guard'ını zorlar.

## 6. Mutation failure'da kullanıcı girdisi nasıl korunuyor?

Save validation veya optimistic stale hatası draft'ı kaybettirmemelidir. Retry
nesnesi form snapshot'ına logical mutation kimliğini ekler:

```dart
class _TruckRetry {
  const _TruckRetry({
    required this.draft,
    required this.currentTruckId,
    required this.truckId,
    required this.eventId,
  });

  final _TruckDraft draft;
  final String? currentTruckId;
  final String truckId;
  final String eventId;
}
```

Neden hem `truckId` hem `eventId` saklanır?

- Yeni retry'da farklı truck ID üretmek duplicate logical kayıt riski doğurur.
- Farklı event ID üretmek append-only history'de aynı kullanıcı niyetini iki
  ayrı event gibi gösterebilir.
- Aynı kimlikler transaction sonucunun belirsiz olduğu durumda idempotent
  sözleşmeyi güçlendirir.

Failure akışı:

```text
Dialog draft döndürür
        |
        v
saveTruck(command) ---- başarı ----> detail reload, retry temizle
        |
       hata
        v
güncel detail reload
        |
        v
draft + truckId + eventId sakla
        |
        v
"Son mikser girdisini yeniden aç"
```

Edit retry açılırken current truck güncel detail içinden ID ile yeniden bulunur.
Bu, eski revision nesnesini körlemesine yeniden kullanmayı önler.

## 7. Validation alanları neden dialog içinde kalıyor?

Result `received` değilse reason zorunludur:

```dart
if (_result != ConcreteTruckResult.received &&
    _reason.text.trim().isEmpty) {
  validationMessage = 'Teslim alındı dışındaki sonuçlarda neden zorunludur.';
}
```

Dropdown `received → held → received → held` değişirken reason TextField widget'ı
ağaçtan çıkıp geri girebilir. Controller dialog State'te kaldığı için kullanıcı
yazısı ve lifecycle geçerliliği korunur. Geliş/boşaltma zamanları controller
değil State value alanlarıdır ve immutable draft'a kopyalanır.

## 8. Ortak text dialog standardı

Audit sırasında mikser dışında local controller oluşturan modal helper'lar da
bulundu. Basit tek alanlı formlar için `OwnedTextInputDialog` oluşturuldu:

```dart
class OwnedTextInputDialog extends StatefulWidget {
  const OwnedTextInputDialog({
    required this.title,
    required this.label,
    required this.confirmLabel,
    this.validator,
  });
}
```

Bu dialog:

- controller'ı kendi `initState()` methodunda oluşturur;
- kendi `dispose()` methodunda kapatır;
- validation mesajını girdiyi silmeden gösterir;
- `_closing` ile double submit'i engeller;
- parent'a yalnız `String?` döndürür.

Ajanda proje oluşturma, Beton gerekçe, hedef hacim ve numune adedi bu standardı
kullanır. Çok alanlı field notification formu ise kendi dedicated State'ine
sahiptir.

## 9. Diagnostic mesajı neden değişti?

Framework render hatası ile DB mutation aynı anda ilerliyorsa global hata
handler'ı commit sonucunu bilemez. Eski `Yeni kayıt yazılmadı` cümlesi kanıtsız
bir güvenceydi.

Yeni yaklaşım:

```dart
'İşlem sonucu doğrulanamadı. Uygulamayı kapatıp yeniden açın, '
'ilgili kaydı kontrol edin ve aynı işlemi kontrol etmeden tekrarlamayın.'
```

Bu metin üç güvenli eylem verir:

1. Yeni bir mutation başlatmadan uygulamayı yeniden aç.
2. Source-of-truth SQLite'tan ilgili kaydı kontrol et.
3. Sonucu görmeden aynı işlemi tekrar etme.

`ErrorWidget.builder` kaldırılmadı; ham exception/stack trace kullanıcıya
gösterilmiyor.

## 10. Teknik karar tablosu

| Karar | Seçim | Neden |
|---|---|---|
| Controller sahibi | Dialog State | Reverse transition ile aynı lifecycle |
| Parent sonucu | Immutable draft | UI kaynağı değil değer snapshot'ı |
| Double tap | Senkron `_closing` | İkinci pop/mutation penceresini kapatır |
| Failure girdisi | Explicit reopen retry | Kullanıcı yazısı kaybolmaz |
| Retry kimliği | Aynı truck/event ID | Duplicate logical mutation riski azalır |
| Basit modal | Shared StatefulWidget | Audit standardı tekrar kullanılabilir |
| Fatal mesaj | Commit sonucu belirsiz | Kanıtsız `yazılmadı` iddiası yok |
| Schema/format | Değişmedi | Hata UI lifecycle katmanındaydı |

## 11. Testler neyi kanıtlıyor?

Widget test matrisi:

- null irsaliyeli mevcut mikser edit edilir;
- yeni mikser eklenir;
- cancel mutation çağırmaz;
- reverse transition frame'leri ayrı ayrı pump edilir;
- save callback iki kez tetiklenir ama fake application bir çağrı görür;
- received dışı reason alanı açılır, kapanır ve tekrar açılır;
- mevcut geliş/boşaltma zamanları command'da aynen korunur;
- save success sonrası plaka, hacim, not ve revision ekranda görünür;
- save failure sonrası aynı input explicit reopen ile geri gelir;
- her akış sonunda `tester.takeException()` null'dır.

Application testleri ayrıca gerçek SQLite üzerinde:

- `truck.updated` event'inin before/after payload'ını;
- no-op save'in pour/truck revision ve event sayısını artırmadığını;
- stale revision'ın mutation öncesi reddedildiğini;
- null irsaliyenin sonradan doldurulabildiğini;
- canlı m³ hesabını

doğrulamaya devam eder.

API 36 integration testi sentetik backup restore eder, restore edilmiş null
irsaliyeli mikser kartını gerçek Flutter UI'dan açar, düzenler, reverse animation
frame'lerini pump eder ve SQLite'ta tek `truck.updated` event'i ile revision `2`
görür.

## Şunu şöyle yaptık ki...

Controller dispose'a yalnız gecikme eklemedik; controller'ları onları render eden
dialog State'e taşıdık ki güvenlik tema animasyon süresi veya cihaz frame hızına
bağlı olmasın.

Dialog sonucu olarak mutable UI nesneleri taşımadık; immutable draft döndürdük ki
parent yalnız veriyle çalışsın ve failure sonrası kullanıcı girdisini lifecycle
bağımsız saklayabilsin.

Retry sırasında yeni truck/event kimliği üretmedik; aynı logical mutation
kimliğini koruduk ki belirsiz failure sonrasında duplicate kayıt/event riski
artmasın.

Global diagnostic'te kesin bilmediğimiz `yazılmadı` iddiasını kaldırdık ki
kullanıcı körlemesine retry etmek yerine uygulamayı yeniden açıp gerçek kaydı
source-of-truth üzerinden kontrol etsin.

Schema veya backup formatını yükseltmedik; hata SQLite veri modelinde değil
Flutter widget lifecycle sahipliğindeydi. Böylece mobil schema `7`, backup format
`1`, restore journal ve mevcut transaction/event invariant'ları korunmuş oldu.
