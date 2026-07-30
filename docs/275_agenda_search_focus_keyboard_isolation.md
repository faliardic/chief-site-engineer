# Issue #275 — Ajanda Arama Odağı ve Klavye İzolasyonu

## Sorun

Ajanda arama metninin route-local korunması gerekir; fakat bu koruma arama
alanının odak, imleç ve açık klavye durumunu detail dönüşünde yeniden
etkinleştirmemelidir. Benzer biçimde uzun listede drag, fling, momentum veya yön
değiştirme kullanıcı açıkça arama alanına dokunmadıkça aramayı
odaklamamalıdır.

Önceki örtük focus yaşam döngüsü, text/query korunumu ile klavye görünürlüğünü
aynı state gibi ele almaya açıktı. Bu da özellikle detail push/pop ve arama
alanı üzerinde başlayan scroll gesture'ında istenmeyen klavye dönüşü riski
oluşturuyordu.

## Sözleşme

- Arama text'i ve literal query canlı Ajanda route'u içinde korunur.
- Detail dönüşünde gün, filtre, sıralama, güncel veri ve scroll bağlamı korunur.
- Focus, caret ve IME yalnız kullanıcının açık arama tap'iyle etkinleşir.
- Detail push, kullanıcı drag'i ve alan dışı tap arama odağını kapatır.
- Odaksız drag, fling, momentum ve yön değiştirme arama odağı oluşturmaz.
- Bu davranış global singleton, autofocus, random key, route rebuild veya
  kalıcı preference kullanmaz.

## Uygulama

`AgendaPage` arama controller'ından ayrı, route-local bir `FocusNode` taşır:

```dart
final TextEditingController _searchController = TextEditingController();
final FocusNode _searchFocusNode = FocusNode();
```

Her iki nesnenin yaşam döngüsü aynı route state'ine aittir:

```dart
_searchController.dispose();
_searchFocusNode.dispose();
```

Detail push öncesi focus açıkça kapatılır. Mevcut offset snapshot'ı ve dönüşteki
fresh reload akışı değiştirilmez:

```dart
final restoreOffset = _currentScrollOffset;
_searchFocusNode.unfocus();
await Navigator.of(context).push<void>(...);
if (mounted) await _reload(restoreOffset: restoreOffset);
```

Search alanı exact node'u kullanır; liste ise kullanıcı drag'inde klavyeyi
kapatan yerleşik Flutter davranışını uygular:

```dart
TextField(
  controller: _searchController,
  focusNode: _searchFocusNode,
  onTapOutside: (_) => _searchFocusNode.unfocus(),
)
```

```dart
ListView(
  controller: _scrollController,
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
)
```

## Kanıt

- Corrected baseline: `20/20 PASS`; eski davranışın üç hedef assertion'ı
  `3/3 expected FAIL`, unrelated failure `0`.
- Focused widget: `24/24 PASS`; Agenda application: `22/22 PASS`.
- Full Flutter: `324/324 PASS`; analyze: `0 issue`.
- Exact APK checkpoint:
  `48dcae00a89798aba2c1274b5d964e8229448a0a`.
- Exact APK SHA-256:
  `B0CE311E17C045C9B5580F0BB0D70AA33759697FCEA4640D962294E0E48E8190`.
- Samsung `SM-X610` tablet (`R52W90JFN1M`, `sw853dp`) automated wide smoke:
  PASS.
- App-bar back, Android system back, detail mutation, odaklı/odaksız drag,
  fling/momentum/yön değiştirme, sort/proje/tür/arşiv filtreleri, non-zero
  offset, cold relaunch ve sentetik persistence doğrulandı.
- `16/16` sentetik kayıt geri alınabilir arşive taşındı; gerçek kullanıcı
  mutation'ı `0`.

Kullanıcı tablet PASS'i bu Issue'nun fiziksel tamamlanma kapısı olarak
yetkilendirdi. Telefon install/smoke ayrı talebe kadar ertelendi ve
yapılmadı.

Bu Issue schema, backup, migration, persistence, notification, Android native,
genel router veya D29.3 davranışını değiştirmez.
