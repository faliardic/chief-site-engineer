# Issue #207 — Flutter APK'nın Hangi `main()` Fonksiyonuyla Üretildiğini Öğrenmek

## Neden dosya adı yeterli değildir?

Flutter Android debug build'i farklı Dart hedefleri için aynı fiziksel yolu
kullanabilir:

```text
mobile/build/app/outputs/flutter-apk/app-debug.apk
```

Şu iki komutun hedefi farklı olsa da çıktı yolu aynıdır:

```powershell
flutter build apk --debug --target lib/main.dart
flutter build apk --debug --target integration_test/background_reboot_sidecar_main.dart
```

İkinci komut ilk dosyayı değiştirir. Bir script yalnız `app-debug.apk` var mı
diye bakıp onu kopyalarsa dosya adı doğru, içindeki Dart `main()` fonksiyonu
yanlış olabilir. Buna **stale/ambiguous artifact** problemi denir.

## Gerçek kanıtı nasıl okuduk?

Debug APK bir ZIP arşividir. Dart debug programı şu entry içinde bulunur:

```text
assets/flutter_assets/kernel_blob.bin
```

Her entrypoint'e benzersiz ve kullanılan bir sabit ekledik:

```dart
const cseNormalEntrypointMarker =
    'CSE_ENTRYPOINT_NORMAL_LIB_MAIN_DART_V1';

Future<void> main() async {
  debugPrint(cseNormalEntrypointMarker);
  // normal uygulama bootstrap'ı
}
```

Satır satır:

1. `const`, marker'ın değişmez olduğunu belirtir.
2. Benzersiz metin hangi `main()` fonksiyonunun derlendiğini söyler.
3. `debugPrint` sabiti gerçekten kullanır; derleyicinin gereksiz diye kaldırma
   riski azalır.
4. Verifier kernel blob içinde bu byte dizisini arar.

Sentetik hedeflerin marker'ları farklıdır. Normal APK doğrulaması hem normal
marker'ı ister hem iki sentetik marker'ı yasaklar. Yalnız olumlu kontrol yapmak
yeterli değildir; yanlış kodun bulunmadığını da kanıtlarız.

## Python verifier kodu

Gerçek kodun özü şöyledir:

```python
with zipfile.ZipFile(apk) as archive:
    kernel = archive.read("assets/flutter_assets/kernel_blob.bin")

if expected_marker.encode("utf-8") not in kernel:
    raise ValueError("expected Flutter entrypoint marker is missing")

for marker in forbidden_markers:
    if marker.encode("utf-8") in kernel:
        raise ValueError("forbidden Flutter entrypoint marker is present")
```

Satır satır:

1. APK ZIP olarak salt okunur açılır.
2. Yalnız Flutter kernel entry'si okunur.
3. Beklenen marker byte'a çevrilir ve doğrudan binary içinde aranır.
4. Marker yoksa kopyalama başlamadan build başarısızdır.
5. Her yasak marker ayrıca aranır.
6. Normal ve sentetik kod karışmışsa işlem fail-closed kapanır.

## Clean build neden tek başına yetmez?

Release gate üç katman kullanır:

```powershell
flutter clean
flutter build apk --debug --target lib/main.dart
```

Ardından:

```powershell
if ($apk.LastWriteTimeUtc -lt $normalBuildStarted) {
    throw 'Debug sidecar APK predates the explicit lib/main.dart build.'
}
```

Son olarak binary marker verifier çalışır. Clean eski dosyayı kaldırır; timestamp
yeni komutun çıktı ürettiğini; marker ise doğru entrypoint'in üretildiğini
kanıtlar. Üç kontrol farklı hata sınıflarını yakalar.

## Application ID neden ayrıldı?

Android `applicationId`, uygulamanın sandbox kimliğidir. Gradle kararı:

```kotlin
applicationIdSuffix = if (acceptanceHarnessBuild) {
    ".acceptance"
} else {
    ".debug"
}
```

- Normal saha sidecar: `com.faliardic.chiefsiteengineer.debug`
- Sentetik harness: `com.faliardic.chiefsiteengineer.acceptance`

Sentetik APK build'i `android-arm64,android-x64` hedeflerini birlikte içerir.
`android-arm64` saha cihazıyla mimari uyumluluğu, `android-x64` ise API 36
emülatörde gerçek açılış ve aynı-ID tekrar testini sağlar.

Farklı application ID, farklı SQLite/files dizini ve farklı uygulama kaydı
demektir. Sentetik sabit ID'ler artık saha debug verisiyle çarpışamaz.

## `runApp` neden önce çağrıldı?

Eski akış:

```text
bootstrap -> reminder create -> diagnostic -> runApp
                         |
                         +-- exception -> native splash ekranda kalır
```

Yeni akış:

```text
runApp -> acceptance_starting UI -> async bootstrap/reminder
                                      |
                                      +-- success -> sonuç satırları
                                      +-- failure -> acceptance_failed
```

Widget'ın güvenli çalıştırıcısı:

```dart
Future<void> _runSafely() async {
  try {
    final lines = await widget.runner();
    if (mounted) setState(() => _lines = lines);
  } on Object {
    if (mounted) setState(() => _lines = const ['acceptance_failed']);
  }
}
```

Raw exception kullanıcıya yazılmaz. `mounted` kontrolü async iş bittiğinde
widget hâlâ ağaçta mı sorusunu yanıtlar; dispose edilmiş State üzerinde
`setState` çağrısını engeller.

## Sabit ID idempotency kodu

```dart
try {
  return SyntheticReminderResolution(
    reminder: await agenda.getReminderDetail(command.id),
    created: false,
  );
} on AgendaValidationFailure {
  return SyntheticReminderResolution(
    reminder: await agenda.createReminder(command),
    created: true,
  );
}
```

Mevcut ID bulunursa command'in yeni `dueAt` değeriyle create tekrar edilmez.
Kayıt yoksa bir kez oluşturulur. Bu, aynı harness APK'sının ikinci açılışını
güvenli yapar.

## Test kodu neyi doğruluyor?

```dart
final resolution = await findOrCreateSyntheticReminder(
  agenda: agenda,
  command: commandWithDifferentDue,
);

expect(resolution.created, isFalse);
expect(agenda.createReminderCalls, 0);
```

Test özellikle aynı ID ve farklı due kullanır. En önemli assertion
`createReminderCalls == 0` satırıdır; identity collision mutation yoluna hiç
girilmediğini kanıtlar.

Fail-safe widget testi runner'a özel hata attırır, `acceptance_failed` metnini
bekler ve özel hata ayrıntısının ekranda olmadığını doğrular.

Python testi sahte APK oluşturur. Doğru marker ile CLI exit code `0`; yanlış
beklenen marker ile non-zero olur. Böylece release gate verifier'ı gerçek build
beklemeden hızlı regresyon testine sahiptir.

## Teknik karar tablosu

| Karar | Seçim | Neden |
|---|---|---|
| Normal target | Açık `lib/main.dart` | Default/stale target belirsizliğini kaldırır |
| Artifact kanıtı | Timestamp + binary marker | Dosya adı ve komut başarısı tek başına yeterli değildir |
| Sentetik kimlik | `.acceptance` application ID | Saha `.debug` verisini sandbox düzeyinde ayırır |
| Harness UI sırası | `runApp` önce | Async hata native splash'ı kilitleyemez |
| Sabit ID | Var olanı reuse | Farklı due ile identity collision üretmez |
| Fiziksel upgrade | Yalnız `adb install -r` | Mevcut debug app data korunur |

## Kod çalışma akışı

```text
release_gate.ps1
    |
    +-- CSE_ACCEPTANCE_HARNESS temizle
    +-- flutter clean
    +-- flutter build apk --target lib/main.dart
    +-- timestamp doğrula
    +-- normal marker var mı?
    +-- sentetik marker yok mu?
    +-- field sidecar adına kopyala
    +-- package / permission / ARM64 / 16K / imza kapıları

build_mobile_acceptance_apks.ps1
    |
    +-- CSE_ACCEPTANCE_HARNESS=true
    +-- background target -> farklı dosya
    +-- reboot target -> farklı dosya
    +-- package == .acceptance
    +-- normal field sidecar hash'i değişmedi
```

## Şunu şöyle yaptık ki...

Şunu şöyle yaptık ki, bir APK'nın güvenilirliğini dosya adına veya son çalışan
Flutter komutuna bağlamadık. Clean build, açık target, zaman sonkoşulu, binary
marker ve application ID izolasyonunu birlikte kullandık. Sentetik acceptance
uygulamasını da önce UI açacak ve mevcut sabit ID'yi yeniden oluşturmayacak
şekilde kurduk ki hem saha verisi korunsun hem hiçbir exception splash ekranının
arkasında görünmez kalmasın.

## Yeni terimler

- **Entrypoint marker:** APK içinde hangi Dart `main()` hedefinin derlendiğini
  kanıtlayan benzersiz sabit.
- **Artifact provenance:** Bir build çıktısının hangi kaynak, target ve komuttan
  geldiğini yeniden doğrulayabilme kanıtı.
- **Stale artifact:** Güncel komut yerine önceki build'den kalmış çıktı.
- **Sandbox isolation:** Farklı application ID ile uygulama verilerini işletim
  sistemi seviyesinde ayırma.
