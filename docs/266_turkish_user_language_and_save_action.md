# Issue #266 — Türkçe kullanıcı dili ve Puantaj `Kaydet` eylemi

## Amaç

Uygulamanın büyük bölümü Türkçe metin kullansa da Flutter'ın yerleşik
Material/Cupertino eylemleri cihaz locale'ine bağlı olarak İngilizce
çözülebiliyordu. Günlük Puantaj formundaki `Taslak kaydet` etiketi de
mutation'ın gerçekten kayıt yapmadığı izlenimini oluşturuyordu.

Bu değişiklik iki yüzeyi tek dar sözleşmede hizalar:

- CSE'nin tek ürün dili olan Türkçe, root `MaterialApp` seviyesinde
  deterministik olarak uygulanır.
- Puantajın mevcut draft-save mutation'ı korunur ve kullanıcıya `Kaydet`
  olarak gösterilir.

## Uygulama

`CseApp` şu canonical delegate setini kullanır:

```dart
GlobalMaterialLocalizations.delegate
GlobalWidgetsLocalizations.delegate
GlobalCupertinoLocalizations.delegate
```

`locale` ve `supportedLocales` yalnız `Locale('tr')` değerini taşır.
`flutter_localizations` Flutter SDK dependency'sidir; üçüncü taraf paket, ARB
kataloğu veya dil seçici eklenmemiştir.

Puantaj tarafında:

- `save-attendance-draft` semantic key'i değişmedi.
- Buton metni `Kaydet` oldu.
- Hata metni `Puantaj kaydedilemedi.` olarak açıklaştırıldı.
- Save command, event ID, optimistic revision, idempotency, rollback ve
  submitting guard sözleşmeleri değişmedi.
- Kaydetme günü tamamlamaz; status `draft` kalır.

Dar envanterde `Revision`, `Entry`, `Offline` ve `Cloud sync` karışık dili
doğal Türkçe kullanıcı metinleriyle değiştirildi. Teknik kimlikler ve kalıcı
veri biçimleri çevrilmedi.

## Test yaklaşımı

Seçim toolbar testleri global
`debugDefaultTargetPlatformOverride` değiştirmez. Android bağlamı yalnız test
route'unun `ThemeData(platform: TargetPlatform.android)` değeriyle kurulur.
Böylece Flutter test binding global invariant'ı test sonunda `null` kalır.

320 px Puantaj testi generic scrollable veya kör koordinat kullanmaz:

```dart
find.byKey(const Key('attendance-day-detail'))
find.byKey(const Key('save-attendance-draft'))
```

Route root altındaki exact ilk `Scrollable` üzerinden sınırlı
`scrollUntilVisible` uygulanır.

Son geçerli sonuçlar:

- focused Flutter: `29 PASS`;
- full Flutter: `300 PASS`;
- Flutter analyze: PASS;
- `git diff --check`: PASS.

## Fiziksel kabul

Unique detached build worktree'de tek normal debug APK üretildi:

```text
SHA-256
e342ee9ff8250bafffcc70157a0a60c5a73f4d148db38ef6b6c04cf046371281
```

APK'nın applicationId ve kurulu paketle signer uyumu doğrulandı; veri koruyan
`adb install -r -g` başarılı oldu.

Yalnız `CSE266SMOKE` sentetik kayıtlarıyla:

- `Kaydet` görünürlüğü ve `Taslak kaydet` yokluğu;
- save sonrasında draft lifecycle ve ayrı `Günü tamamla`;
- editable toolbar Türkçe eylemleri;
- read-only toolbar'da `Kopyala` varlığı ile `Kes/Yapıştır` yokluğu;
- Türkçe date picker;
- normal reopen sonrası Türkçe locale

doğrulandı. Exact sentetik Ajanda kaydı güvenli arşiv akışına taşındı.
Hard-delete, gerçek kullanıcı mutation'ı, uninstall, clear-data ve downgrade
yapılmadı.

## Sınırlar

- Schema `10`, backup formatı `1`dir.
- Migration yoktur.
- Persisted tarih/saat, sayı, UTC/İstanbul codec ve database değerleri
  değişmemiştir.
- Çoklu dil, ARB, dil seçici ve repository-wide string sweep kapsam dışıdır.
