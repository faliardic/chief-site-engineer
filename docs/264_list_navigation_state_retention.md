# Issue #264 — Detay dönüşünde liste bağlamını koruma

## Problem

Ajanda ve Hatırlatıcı listeleri detay dönüşünde async reload başlatırken geçici
olarak boş extent üretiyordu. Flutter scroll position bu kısa aralıkta geçerli
extent içine clamp edildiği için kullanıcı listenin başına dönüyordu. Puantaj
state alanlarını route içinde tutsa da reload sonrasında eski offset'i açıkça
geri yüklemiyordu. Beton zaten daha iyi davranıyordu; fakat dört ekran aynı
navigation ve lifecycle garantisine sahip değildi.

## Dar çözüm

Her liste kendi `ScrollController` ve route-local state'inin sahibidir:

```dart
final ScrollController _scrollController = ScrollController();
double? _pendingRestoreOffset;
bool _openingDetail = false;
```

Detay açılmadan önce offset snapshot alınır. Detay kapanınca güncel data reload
edilir ve ancak yeni frame'in extent'i hazır olduğunda güvenli restore yapılır:

```dart
_pendingRestoreOffset = _scrollController.hasClients
    ? _scrollController.offset
    : null;

await _reload();
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (!mounted || !_scrollController.hasClients) return;
  final target = _pendingRestoreOffset!.clamp(
    _scrollController.position.minScrollExtent,
    _scrollController.position.maxScrollExtent,
  );
  _scrollController.jumpTo(target);
});
```

Ajanda ve Hatırlatıcı reload sırasında son geçerli list content'ini korur.
Böylece controller, data kaynağının geçici yükleme state'i yüzünden sıfır
extent görmez. Kayıt archive/trash ile gruptan çıkmışsa post-frame clamp yeni
listenin gerçek extent'ine göre karar verir.

## State sahipliği

- seçili gün, proje, kategori, status ve alt görünüm state'i mevcut route
  instance'ında kalır;
- Ajanda arama metni aynı route'a ait explicit controller ile korunur;
- iki liste instance'ı controller veya mutable state paylaşmaz;
- controller `dispose` sırasında bırakılır;
- random key, global singleton ve eager list render eklenmez.

## Navigation güvenliği

Route-local `_openingDetail` guard, ilk push tamamlanmadan gelen ikinci dokunmayı
reddeder. Guard `finally` içinde bırakılır; hata veya normal pop sonrasında route
yeniden kullanılabilir. App bar back ve Android system back aynı Future
tamamlanma zincirini çalıştırır.

Direct detail/notification/Puantaj deep-link akışı sahte bir liste geçmişi
oluşturmaz. Bu değişiklik yalnız bir liste route'u üzerinden yapılan push/pop
ömrünü etkiler.

## Compatibility

- schema `10`
- backup formatı `1`
- migration `0`
- application/domain mutation sözleşmesi değişikliği `0`
- notification/occurrence/router rewrite `0`
