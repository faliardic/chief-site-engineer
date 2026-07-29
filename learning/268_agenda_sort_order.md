# Issue #268 — Deterministik sıralama ve route-local state

## Amaç

Bu adım, “listeyi ters çevir” gibi basit görünen bir UI isteğinin neden query,
tie-break ve navigasyon state'i birlikte düşünülerek uygulanması gerektiğini
gösterir.

Ajanda için iki kullanıcı ihtiyacı vardır:

1. son saha kaydına hızlı erişmek;
2. kronolojik inceleme gerektiğinde ilk kayıttan başlayabilmek.

## Gerçek kod akışı

Sort domain/read-model sözleşmesidir:

```dart
enum AgendaSortOrder {
  newestFirst('En yeni üstte'),
  oldestFirst('En eski üstte');
}

class AgendaQuery {
  const AgendaQuery({
    required this.istanbulDay,
    // ...
    this.sortOrder = AgendaSortOrder.newestFirst,
  });
}
```

Application katmanı enum üzerinden sabit SQL seçer:

```dart
final orderBy = switch (query.sortOrder) {
  AgendaSortOrder.newestFirst =>
    'o.observed_at DESC, o.created_at DESC, o.id DESC',
  AgendaSortOrder.oldestFirst =>
    'o.observed_at ASC, o.created_at ASC, o.id ASC',
};
```

Burada üç alan gereklidir. Yalnız `observed_at` kullanılsaydı aynı olay
zamanındaki kayıtların sırası database yürütmesine göre değişebilirdi.
`created_at` ve `id`, sonucu her çalıştırmada aynı yapan tie-break alanlarıdır.

UI seçimi route içinde tutulur:

```dart
AgendaSortOrder _sortOrder = AgendaSortOrder.newestFirst;

AgendaQuery(
  istanbulDay: _selectedDay,
  projectId: _projectId,
  category: _category,
  literalSearch: _search,
  archiveFilter: _archiveFilter,
  sortOrder: _sortOrder,
);
```

Böylece sort, filtrelerden sonra client-side uygulanmaz; filtrelerle aynı
read-model isteğinin parçası olur.

## Testlerin amacı

Application testleri:

- iki yönü ve default değeri;
- aynı `observed_at` için `created_at`/`id` tie-break'lerini;
- içerik update sonrasında sıranın değişmemesini;
- aktif/arşiv ve bütün filtre kombinasyonlarını

kanıtlar.

Widget testleri:

- `agenda-sort-order` semantic key'ini;
- iki exact Türkçe etiketi;
- uzun listede güvenli scroll reset'ini;
- detail push/pop ve async reload sonrasında sort/filter/search/offset
  korunmasını;
- 320 px, büyük metin ve koyu tema davranışını

doğrular.

Windows detached worktree'de CRLF checkout edilen `pubspec.yaml`, LF-only
multiline testinde false-negative üretti. Production dosyasını veya
`pubspec.yaml` satır sonlarını değiştirmek yerine test girdisi normalize
edildi. Exact indent ve `sdk: flutter` kontrolü korunarak yalnız platform
farkı kaldırıldı.

## Saha karşılığı

Şantiye şefi Ajanda'yı açtığında son kayıt en üstte görünür. Kronolojik
inceleme için `En eski üstte` seçildiğinde proje, tür ve arama filtresi
kaybolmaz. Bir kaydın açıklamasını düzeltmek, onu gerçek olay zamanından
koparıp listenin başka yerine taşımaz.

Fiziksel smoke'ta aynı sentetik proje ve gün içinde `06:00`, `06:10`,
`06:20`, `06:30` kayıtları kullanıldı. Her iki yön, filtreler ve detail
mutation doğrulandı; dört kayıt geri getirilebilir arşive taşındı.

## Şunu şöyle yaptık ki...

- Sort'u typed query alanı yaptık ki UI ile persistence farklı sıralama
  üretmesin.
- Üç seviyeli SQL tie-break kullandık ki aynı olay zamanında sonuç
  deterministik olsun.
- `updated_at` alanını dışarıda bıraktık ki açıklama düzeltmesi olay
  kronolojisini bozmasın.
- Seçimi route-local tuttuk ki detail dönüşünde bağlam korunsun fakat yeni
  preference veya migration oluşmasın.
- Static testte yalnız satır sonlarını normalize ettik ki Windows ve Unix
  checkout'ları aynı exact localization contract'ını doğrulasın.
- Fiziksel kabulü yalnız `CSE268SMOKE` kayıtlarıyla yaptık ki gerçek kullanıcı
  kaydı açılmasın veya değiştirilmesin.

## Bilinçli sınırlar

- Cold restart sort tercihi yoktur.
- Günlük export sırası değiştirilmemiştir.
- Schema/migration/backup formatı değişmemiştir.
- Gerçek kullanıcı kaydı, uninstall, clear-data, downgrade ve hard-delete
  yoktur.
