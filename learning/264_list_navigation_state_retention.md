# Issue #264 — Flutter listesinde route-local state nasıl korunur?

## Amaç

Bir detail sayfasından geri gelince yalnız filtre metninin korunması yeterli
değildir. Kullanıcının gördüğü bağlam; route state'i, async data, scroll extent
ve navigation Future'ının birlikte doğru sırada yönetilmesine bağlıdır.

```text
liste state'i
  ├─ gün / proje / filtre / arama
  ├─ mevcut data snapshot'ı
  ├─ scroll offset
  └─ detail navigation guard
              ↓
        detail push / pop
              ↓
      fresh reload + post-frame clamp
```

## Asıl hata neden oluştu?

Scroll offset tek başına controller içinde durur. Reload sırasında liste geçici
olarak boş widget'a dönüşürse `maxScrollExtent` sıfıra iner. Controller eski
offset'i saklasa bile Flutter onu artık geçersiz aralıkta tuttuğu için başa
clamp eder.

Bu nedenle iki kural birlikte gerekir:

1. reload boyunca son geçerli list content'ini gereksiz yere yok etme;
2. fresh data render edildikten sonra offset'i yeni extent'e göre geri yükle.

## Gerçek kod yaklaşımı

Her route ayrı controller sahibidir:

```dart
final _scrollController = ScrollController();

@override
void dispose() {
  _scrollController.dispose();
  super.dispose();
}
```

Detay öncesinde yalnız controller client'a bağlıysa snapshot alınır:

```dart
final offset = _scrollController.hasClients
    ? _scrollController.offset
    : 0.0;
```

Reload biter bitmez `jumpTo` çağırmak erken olabilir. Yeni child'lar aynı
frame'de henüz layout olmamıştır. Bu yüzden restore post-frame yapılır ve extent
küçülmesi hesaba katılır:

```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (!mounted || !_scrollController.hasClients) return;
  final position = _scrollController.position;
  _scrollController.jumpTo(
    offset.clamp(position.minScrollExtent, position.maxScrollExtent),
  );
});
```

## Double-tap neden ayrı bir state sorunudur?

İki hızlı dokunma iki detail route push ederse ilk pop liste reload'unu
başlatırken ikinci detail hâlâ stack üzerinde kalabilir. Bu yalnız görsel
duplicate değildir; hangi offset snapshot'ının son geçerli olduğu da belirsiz
hale gelir.

```dart
if (_openingDetail) return;
setState(() => _openingDetail = true);
try {
  await Navigator.of(context).push(...);
  await _reloadAndRestore();
} finally {
  if (mounted) setState(() => _openingDetail = false);
}
```

Guard route-local olduğu için iki ayrı liste instance'ı birbirini bloke etmez.

## Testlerin amacı

- Uzun sentetik liste testi detay öncesi ve sonrası görünür kart bölgesini
  karşılaştırır.
- Async reload testi geçici loading state'inin offset'i düşürmediğini kanıtlar.
- Mutation testi kartın fresh içeriğini ve eski bağlamı aynı anda doğrular.
- Archive/trash testi küçülen extent'in exception üretmeden clamp edildiğini
  kanıtlar.
- İki instance testi global controller/state sızıntısını yakalar.
- Dispose testi controller callback'inin ölü route'a yazmadığını doğrular.
- Double-tap testi tek detail push garantisini verir.
- 320 px, büyük yazı, dark theme ve açık klavye fixture'ları restore
  callback'inin overflow üretmediğini kontrol eder.
- Direct deep-link fixture'ları liste geçmişi olmayan açılışların değişmediğini
  kanıtlar.

## Şunu şöyle yaptık ki...

- Controller'ı route içinde tuttuk ki iki liste instance'ı state paylaşmasın.
- Offset'i detail push öncesinde aldık ki reload başlamadan son kullanıcı
  konumunu kaybetmeyelim.
- Son geçerli listeyi loading sırasında koruduk ki extent geçici olarak sıfıra
  düşmesin.
- Restore'u post-frame ve clamp ile yaptık ki arşivlenen/taşınan kayıt sonrası
  overscroll veya exception oluşmasın.
- Navigation guard'ı `finally` ile bıraktık ki hem duplicate push önlensin hem
  hata sonrasında ekran kilitli kalmasın.
- Arama controller'ını explicit yönettik ki açık klavye ve detail dönüşünde
  kullanıcı metni aynı route state'inde kalsın.

## Bilinçli sınırlar

Bu çözüm cold restart veya process-death sonrasında exact pixel offset saklamaz.
Yeni preference tablosu, schema/migration, global router veya kalıcı scroll
restoration eklenmedi. Değişiklik aynı canlı route instance'ının in-memory
ömrüyle sınırlıdır.
