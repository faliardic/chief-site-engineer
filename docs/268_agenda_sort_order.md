# Issue #268 — Deterministik Ajanda sıralaması

## Amaç

Ajanda aynı yerel gündeki kayıtları daha önce sabit olarak eskiden yeniye
getiriyordu. Son saha kaydına hızlı erişmek için yeni route varsayılanı
`En yeni üstte` oldu; kullanıcı aynı ekranda `En eski üstte` seçebilir.

Bu davranış bir UI liste hilesi değildir. Sıralama application query
sözleşmesinin parçasıdır ve filtrelerle aynı istekte uygulanır.

## Sözleşme

Domain iki değerli typed enum taşır:

```dart
enum AgendaSortOrder {
  newestFirst('En yeni üstte'),
  oldestFirst('En eski üstte');
}
```

`AgendaQuery.sortOrder` varsayılan olarak `newestFirst` değeridir.
Application katmanında yalnız enum allowlist'inden iki SQL parçası seçilir:

```dart
final orderBy = switch (query.sortOrder) {
  AgendaSortOrder.newestFirst =>
    'o.observed_at DESC, o.created_at DESC, o.id DESC',
  AgendaSortOrder.oldestFirst =>
    'o.observed_at ASC, o.created_at ASC, o.id ASC',
};
```

Bu üç alan şu anlamları korur:

- `observed_at`: olayın saha zamanı;
- `created_at`: aynı olay zamanındaki ilk deterministik tie-break;
- `id`: son deterministik tie-break.

`updated_at` kullanılmaz. Açıklama veya not düzenlemek kaydı olay zamanı
sırasından çıkarmaz. UI da sonucu ayrıca `reverse()` etmez.

## UI ve navigasyon

`AgendaPage`, `agenda-sort-order` semantic key'li kontrolü ve route-local
`_sortOrder` state'ini taşır. Sort değişince mevcut gün, aktif/arşiv, proje,
tür ve literal arama değerleriyle reload yapılır; liste güvenle başa alınır.

Detay route'una girip dönünce:

- seçili sort;
- filtreler ve arama;
- fresh detail mutation sonucu;
- güncel scroll bağlamı

aynı canlı route instance'ında korunur. Cold restart veya process-death
tercih saklama eklenmemiştir.

## Platform bağımsız static test

Windows detached worktree, `pubspec.yaml` dosyasını CRLF ile checkout
edebildiği için LF-only multiline assertion false-negative üretiyordu. Test
satır sonlarını karşılaştırmadan önce normalize eder:

```dart
final normalizedPubspec = pubspec
    .replaceAll('\r\n', '\n')
    .replaceAll('\r', '\n');
```

Yalnız multiline kontrol normalize edilmiş değeri kullanır. Dependency adı,
dört boşluk indent ve `sdk: flutter` beklentisi aynı kesinlikte kalır.

## Doğrulama

- Static configuration: `5 PASS`
- Agenda application + widget: `42 PASS`
- Combined focused: `47 PASS`
- Full Flutter: `308 PASS`
- Flutter analyze: PASS
- Schema `10`, backup formatı `1`, migration `0`

Tek disposable debug APK üretildi:

```text
SHA-256
d206dcf9a6e0cb6d6216e8477634b4b5cb5d3dacc00bc951cc7ef5f3170dbf2a
```

`R5CY21WKZFX` cihazında veri koruyan replace-install sonrasında yalnız
`CSE268SMOKE` kayıtlarıyla newest/oldest, filtreler, detail mutation ve iki
geri dönüş yolu doğrulandı. Dört sentetik log geri getirilebilir arşive
taşındı; gerçek kullanıcı kaydı açılmadı veya değiştirilmedi.

## Sınırlar

- Sort tercihi database veya preference tablosuna yazılmaz.
- Günler arası birleşik feed ve günlük export değiştirilmez.
- Schema ve backup formatı değişmez.
- Uninstall, clear-data, downgrade veya hard-delete yapılmaz.
