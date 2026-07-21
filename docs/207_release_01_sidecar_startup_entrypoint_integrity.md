# Issue #207 — Saha Sidecar Başlangıç ve Entrypoint Bütünlüğü

## Problem

Issue #202 fiziksel kabulünden sonra saha kullanıcısına kurulan debug APK native
splash ekranında kaldı. Process canlıydı; ilk log toplamada crash, ANR, SQLite,
Flutter engine veya native class yükleme hatası yoktu. İkinci log kanıtı Dart'ın
sentetik background acceptance akışını çalıştırdığını ve sabit reminder ID için
`Hatırlatıcı kimliği başka bir içerikle kullanılıyor.` hatası aldığını gösterdi.

Sentetik giriş noktası `runApp` çağrısını reminder hazırlığından sonraya
bıraktığı için exception güvenli Flutter UI'a ulaşamıyor, native splash ekranda
kalıyordu.

## Artifact zinciri kanıtı

Issue #207 başlangıcında iki ignored APK binary kernel marker'ıyla incelendi:

| Dosya | SHA-256 / marker sonucu |
|---|---|
| `build/release_gate/...issue202-sidecar-debug.apk` | `255476...` ve normal `lib/main.dart` marker'ı; sentetik marker yok |
| ortak `build/app/.../app-debug.apk` | reboot acceptance marker'ı; normal marker yok |

Bu sonuç saha loguyla birlikte sorunu daraltır: repository'deki adı verilmiş
Issue #202 artifact'i normaldir, fakat Flutter'ın ortak `app-debug.apk` yolu son
çalıştırılan sentetik target tarafından değiştirilmiştir. Eski release gate:

- normal target'ı komutta açıkça yazmıyordu;
- ortak APK'nın build başlangıcından yeni olduğunu doğrulamıyordu;
- Dart entrypoint marker'ını doğrulamıyordu;
- sentetik APK'ya farklı package kimliği vermiyordu.

Dolayısıyla ortak çıktının saha artifact'i diye kopyalanması/yeniden adlandırılması
kanıtlanabilir biçimde engellenmiyordu. Issue #207 hem üretim zincirini hem
harness açılışını fail-closed yapar.

## Yeni üretim sözleşmesi

Normal saha sidecar yalnız şu komut sözleşmesiyle üretilir:

```powershell
flutter clean
flutter pub get
flutter build apk --debug --target lib/main.dart --target-platform android-arm64
```

Kopyalamadan önce aşağıdaki sonkoşullar zorunludur:

1. clean sonrasında ortak `app-debug.apk` bulunmamalıdır;
2. yeni APK build başlangıç zamanından eski olmamalıdır;
3. APK Flutter kernel blob'u normal entrypoint marker'ını içermelidir;
4. background ve reboot sentetik marker'larını içermemelidir;
5. package `com.faliardic.chiefsiteengineer.debug` olmalıdır;
6. mevcut permission, ARM64, 16 KiB alignment ve imza kapıları geçmelidir.

Doğru artifact adı:

`chief-site-engineer-0.1.0-issue207-field-sidecar-debug.apk`

## Sentetik APK izolasyonu

Dedicated `build_mobile_acceptance_apks.ps1` iki ayrı artifact üretir:

- `chief-site-engineer-0.1.0-issue207-background-acceptance-debug.apk`;
- `chief-site-engineer-0.1.0-issue207-reboot-acceptance-debug.apk`.

İkisi de `com.faliardic.chiefsiteengineer.acceptance` application ID'sini
kullanır. Böylece normal `.debug` sandbox'ındaki Ajanda, Puantaj, Beton,
attachment, reminder ve backup verilerine erişemez. Script normal field sidecar
önceden varsa hash'ini alır ve build sonunda değişmediğini doğrular.

Acceptance APK'ları `android-arm64,android-x64` hedefleriyle üretilir. Böylece
ARM64 fiziksel cihaz zincirinden ayrı tutulurken API 36 x64 emülatörde de sabit
ID tekrarının gerçek Android açılış davranışı sınanabilir.

## Harness açılış güvenliği

Sentetik uygulama artık `runApp` çağrısını hemen yapar. Bootstrap ve reminder
hazırlığı görünür `acceptance_starting` ekranından sonra yürür. Hata oluşursa
raw exception/metin gösterilmeden `acceptance_failed` görünür.

Sabit reminder ID zaten varsa kayıt yeniden kullanılır; farklı `dueAt` ile
`createReminder` tekrar çağrılmaz. Yeni ID yalnız gerçekten bulunamadığında bir
kez oluşturulur. Böylece identity collision splash ekranını kilitleyemez.

## Veri ve kapsam sınırı

- Mobil SQLite schema `7` değişmez; migration yoktur.
- Backup format `1` değişmez.
- Normal debug application ID değişmez.
- Fiziksel düzeltmede uninstall ve app data clear yasaktır.
- Kurulum yalnız `adb install -r` ile aynı package üzerine yapılır.
- Codex gerçek Ajanda/Puantaj/Beton içeriğini okumaz; yalnız normal ana ekranın
  ve kullanıcı tarafından kontrol edilebilir modül girişlerinin görünürlüğünü
  privacy-safe biçimde doğrular.
- Store submission, gerçek signing ve production kullanıcı verisi kapsam dışıdır.

## Test matrisi

- entrypoint verifier beklenen marker'da geçer, eksik/forbidden marker'da durur;
- release script açık normal target, clean ve stale timestamp kontrolü taşır;
- acceptance script farklı artifact adı/application ID kullanır;
- sentetik sabit ID ikinci create mutation üretmez;
- async runner hatası splash yerine privacy-safe fail UI gösterir;
- Flutter analyze/full suite, API 36 integration ve Python full suite geçer;
- release/static/iOS privacy/ARM64/16 KiB ve ephemeral signing kapıları geçer;
- fiziksel cihazda `install -r`, normal ana ekran, modül görünürlüğü ve 15 dakika
  reminder teslimatı doğrulanır.

## Tamamlama kanıtı

- Normal saha sidecar `adb install -r` ile R5CY21WKZFX üzerine kurulmuştur;
  uninstall ve app data clear kullanılmamıştır.
- Normal `MainActivity` 784 ms'de açılmış, normal entrypoint marker'ı görülmüş,
  process/focus doğru `.debug` package üzerinde kalmış ve fatal crash
  oluşmamıştır.
- Gerçek kayıt içerikleri okunmamış; Ajanda, Puantaj ve Beton modülleri normal
  ana ekrandan kullanıcı denetimine açık bırakılmıştır.
- Yeni sentetik saha reminder'ı 15 dakika seçeneğiyle oluşturulmuş, uygulama
  Home'a alınıp `am kill` ile process durdurulmuş ve kullanıcı uygulamayı yeniden
  açmadan platform notification kaydı oluşmuştur.
- Background ve reboot acceptance APK'ları API 36 x64 emülatörde iki ardışık
  açılışta `acceptance_ready` göstermiş; ikinci açılışlarda sabit kimlik
  `reused` olmuş ve fatal crash oluşmamıştır.

Artefakt SHA-256 değerleri:

- normal sidecar: `f28caf50229259b3f15f79f1ec07a027790d95c5356de96bdeaac0183b33406b`;
- ephemeral production RC APK: `fa1a16febb6aa1bdae418f017ddc2042afc49eeb1205c2ea27ba40ee14a4e7f2`;
- background acceptance APK: `915d73bfbab53f2976db42d5b68f36f524b015a823216083f672f50ac8452945`;
- reboot acceptance APK: `fa25e097f075fed68ca20d774d6128b15ab5887aab8a6e0b54ce5126137c3b1b`.
