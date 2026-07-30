# Issue #275 — Ajanda Arama Odağı ve Klavye İzolasyonu Öğrenimi

## Gerçek hata modeli

Bir metin alanının içeriğiyle etkileşim durumu aynı şey değildir:

```text
text/query  → kullanıcının route-local arama bağlamı
focus/caret → şu anda hangi input'un kullanıcı etkileşimini aldığı
IME         → platform klavyesinin görünür durumu
```

Ajanda detail sayfasından geri gelindiğinde text/query korunabilir. Bunun focus
ve IME'yi de geri getirmesi ise kullanıcı niyeti değildir. Scroll gesture'ı da
arama alanının üzerinde başlasa bile bir search tap'i sayılmamalıdır.

## Kod akışı

Arama alanı için state'in sahip olduğu ayrı bir `FocusNode` oluşturuldu:

```dart
final FocusNode _searchFocusNode = FocusNode();
```

Detail navigation öncesi mevcut scroll offset alınır ve focus kapatılır:

```dart
final restoreOffset = _currentScrollOffset;
_searchFocusNode.unfocus();
await Navigator.of(context).push<void>(...);
if (mounted) await _reload(restoreOffset: restoreOffset);
```

Bu sırada `_searchController.text`, `_search`, gün, proje, kategori, arşiv ve
sort state'i aynı canlı route'ta kalır. Fresh reload güncel kaydı getirir;
post-frame offset restore ise yeni extent içine clamp edilir. Focus restore
edilmez.

Liste tarafındaki gesture sözleşmesi Flutter'ın yerleşik davranışıyla
tanımlanır:

```dart
keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag
```

Alan dışı tap de exact search node'unu kapatır:

```dart
onTapOutside: (_) => _searchFocusNode.unfocus()
```

Controller ve focus node birlikte dispose edilir. Böylece route dışına yaşam
döngüsü sızmaz.

## Test yaklaşımı

Dört yeni widget regresyonu birbirinden farklı kullanıcı niyetlerini ayırır:

1. App-bar back ile detail dönüşü text/query ve non-zero offset'i korur;
   focus/IME kapalıdır.
2. Android system back aynı sözleşmeyi korur.
3. Focus açıkken arama alanında başlayan gerçek drag listeyi kaydırır,
   focus/IME'yi kapatır ve yeni query çağrısı üretmez.
4. Odaksız drag, fling ve yön değiştirme focus/IME oluşturmaz.

Test helper'ı exact `agenda-literal-search` altındaki tek `EditableText`
üzerinden focus node'u okur. Böylece offstage veya başka text input'ların test
sonucunu yanlış pozitif yapması engellenir. Ayrı telefon boyutlarına yakın
widget viewport'ları ve gerçek `Scrollable` state'i kullanılarak non-zero
offset de assertion'a bağlanır.

Tablet wide smoke aynı ayrımı gerçek IME ve UI hierarchy üzerinde doğrular:
focus açık drag klavyeyi kapatır; app-bar/system back text, query, filtre ve
kart fingerprint'ini korur; odaksız momentum focus üretmez.

## Teknik karar

Global `FocusManager` müdahalesi, autofocus toggle'ı, route key yenileme veya
arama text'ini temizleme kullanılmadı. Sorunun sahibi Ajanda route'u olduğu
için çözüm de aynı state'in sahip olduğu exact `FocusNode` ile sınırlandı.
Flutter'ın `onDrag` keyboard dismissal davranışı scroll ve tap gesture ayrımını
ek bir gesture recognizer yazmadan sağlar.

Schema `10`, backup formatı `1`, migration `0`, application query ve
persistence sözleşmeleri değişmedi. Telefon promotion ürün davranışının parçası
değil, kullanıcı tarafından ertelenmiş ayrı fiziksel kabul adımıdır.

## Şunu şöyle yaptık ki...

Arama text/query state'ini focus/IME state'inden ayırdık ki detail dönüşü
kullanıcı bağlamını korurken klavyeyi kendiliğinden açmasın. Detail push öncesi
exact focus node'u kapattık ki hem app-bar hem system back aynı deterministik
sonucu versin. Listeye yerleşik `onDrag` dismissal verdik ki arama alanında
başlayan gerçek scroll metni veya sorguyu değiştirmeden klavyeyi kapatsın.
