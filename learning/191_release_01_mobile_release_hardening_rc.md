# Issue #191 Öğrenme Notu — Mobil Release Candidate Hardening

## Bu geliştirmede ne öğrendik?

Release hardening yalnız “release build alındı” demek değildir. Kaynak izinleri,
plugin merge sonucu, native binary alignment, signing sınırı, crash recovery,
privacy beyanı ve kullanıcıya gösterilen hata davranışı aynı kanıt zincirinde
uyuşmalıdır. Tek bir kapının geçmesi diğerlerinin geçtiğini kanıtlamaz.

Bu Issue mobil schema'yı değiştirmedi. Yeni davranış, restore dosya swap'ının
process kill sonrasında da deterministik çözülebilmesi ve build artefaktlarının
mağaza teknik gereksinimleriyle kontrol edilmesidir.

## Gerçek kod: process-death restore journal

```dart
Future<RestoreRecoveryOutcome> recoverBeforeBootstrap() async {
  final entry = await _read();
  if (entry == null) return RestoreRecoveryOutcome.noJournal;
  switch (entry.phase) {
    case RestoreJournalPhase.prepared:
      await _restoreAvailableOldComponents(entry, requireRollback: false);
      await validateActiveState();
      await _cleanupOperation(entry);
      await _clearJournal();
      return RestoreRecoveryOutcome.rolledBack;
    // Diğer aşamalar aynı fail-closed kararı açıkça uygular.
  }
}
```

Satır satır anlamı:

1. `_read()` atomik primary/`.next` journal slotlarından en yeni geçerli aşamayı
   okur; çelişen operation ID'leri kabul etmez.
2. Journal yoksa normal bootstrap devam edebilir.
3. `prepared`, iki eski bileşenin henüz taşınmamış olabileceği aşamadır; bu
   nedenle rollback alanında bulunan parçalar geri konur, bulunmayan parçaların
   aktif yerde kalması zorunludur.
4. `validateActiveState()` SQLite integrity/FK ile bütün aktif attachment
   size/SHA-256 değerlerini doğrular.
5. Staging ve journal ancak doğrulanmış bir aktif çift oluşunca temizlenir.

Önemli ara durum şudur: database rollback alanına taşınmış fakat attachment
taşıma çağrısı başlamadan process ölmüş olabilir. `prepared` aşamasında iki
rollback parçasını birden zorunlu tutmak kurtarılabilir veriyi yanlışlıkla
“ambiguous” sayardı. Kod bu yüzden var olan eski parçayı geri getirir ve diğer
parçanın aktif yerde bulunmasını şart koşar.

## Gerçek kod: dış signing sözleşmesi

```kotlin
val signingPropertiesFile = System.getenv("CSE_KEY_PROPERTIES_FILE")
val signingRequired = System.getenv("CSE_REQUIRE_SIGNING") == "true"

if (signingRequired && signingPropertiesFile.isNullOrBlank()) {
    throw GradleException("External release signing was required but not configured.")
}
```

İlk satır repository içine konmayan properties dosyasının yolunu environment'tan
alır. İkinci satır CI veya release operatörünün signing'i açıkça zorunlu kılıp
kılmadığını belirler. Üçüncü blok “release” adı altında debug key'e sessiz düşmek
yerine eksik sözleşmeyi build başlamadan durdurur. Properties ve keystore'un
repository dışında olduğu ayrıca path kontrolüyle doğrulanır.

Yerel test kapısındaki ephemeral keystore bu üretim sözleşmesini sınar; gerçek
upload key değildir. Random parola yalnız process environment/properties içinde
geçici yaşar ve `finally` ile temp kökü silinir.

## Gerçek kod: merged manifest neden kaynak manifestten farklıdır?

```python
permissions = {
    element.attrib[ANDROID_NAME]
    for element in merged_root.findall("uses-permission")
}
unexpected = permissions - allowed_os_permissions - allowed_private_permissions
if unexpected:
    raise ReleaseValidationError("unexpected merged permission")
```

Bir Flutter plugin'i kendi Android manifestini uygulama manifestine merge eder.
Yalnız `src/main/AndroidManifest.xml` okumak plugin'in eklediği izni kaçırabilir.
Test bu yüzden Gradle'ın gerçek release merge çıktısını okur. OS izin allowlist'i
ile uygulamaya özel `signature` izin ayrı tutulur; yeni bir sensitive izin
geldiğinde kapı fail-closed durur.

## Gerçek kod: 16 KiB artefakt kontrolü

```powershell
& $zipalign -c -P 16 -v 4 $rcApk
& $apksigner verify --verbose --print-certs $rcApk
```

İlk satır universal APK içindeki paylaşımlı native kütüphanelerin 16 KiB page
alignment sözleşmesini resmi Android aracıyla kontrol eder. İkinci satır APK'nın
gerçekten imzalı ve doğrulanabilir olduğunu kanıtlar. Kaynak kodda NDK sürümü
yazması bu iki artefakt sonucunun yerine geçmez.

## Gerçek kod: top-level güvenli hata sınırı

```dart
runZonedGuarded(
  () => runApp(ChiefSiteEngineerApp(fatalFailure: fatalFailure)),
  (error, stackTrace) => fatalFailure.value = 'runtime_unhandled',
);
```

Uygulama callback'leri guarded zone içinde başlar. Yakalanmayan nesnenin metni
ve stack'i UI'a taşınmaz; sabit safe code görünür. Debug ayrıntısını kullanıcı
ekranına dökmemek cihaz yolunu, plugin mesajını veya kayıt içeriğini yanlışlıkla
sızdırma riskini azaltır. Recovery ekranı ayrıca veriye dokunulmadığını söyler.

## Test kodu neyi doğruluyor?

```dart
for (final phase in RestoreJournalPhase.values) {
  test('bootstrap recovers process death after ${phase.name}', () async {
    await _arrangeInterruptedRestore(directories, phase);
    final result = await AppBootstrap(/* test root */).start();
    expect(result, isA<BootstrapSuccess>());
  });
}
```

Loop dört journal aşamasını aynı acceptance biçiminde çalıştırır. Fixture gerçek
SQLite dosyalarını ve attachment köklerini rename eder; yalnız mock flag kontrol
etmez. Ayrı test database taşınıp attachment yerinde kalmış `prepared` ara
durumunu, eksik rollback materyalinin korunmasını ve journal'ın parola/absolute
path taşımamasını doğrular.

Schema testleri v1–v4 paketlerini restore staging'inde v5'e migrate eder; v5
full fixture round-trip'i bütün domain/event/attachment sayımlarını karşılaştırır.
Widget testleri raw exception/stack yokluğunu, 320/430 px, büyük text scale ve
dark/light görünümü kontrol eder. Python statik test Gradle, manifest, plist,
privacy, asset, secret ve network sözleşmesini aynı validator üzerinden sınar.

## Teknik karar tablosu

| Karar | Seçilen çözüm | Neden |
| --- | --- | --- |
| Crash recovery | Küçük atomik journal + phase machine | Process kill exception handler çalıştırmayabilir |
| Belirsiz recovery | Veri silme yok, journal/rollback korunur | Yanlış cleanup geri döndürülemez kayıp yaratabilir |
| Android izin denetimi | Merged release manifest allowlist | Plugin izinleri kaynak manifestte görünmeyebilir |
| Signing | Repository-dışı explicit contract | Debug key'e sessiz fallback production kimliğini bozar |
| 16 KiB | Universal APK + `zipalign -P 16` | Kaynak ayarı yerine gerçek artefakt kanıtı gerekir |
| Privacy | Policy + store matrices + SDK/source audit | Console cevabının repository kanıtıyla tutarlı olması gerekir |
| iOS Windows kapısı | Plist/project/plugin statik doğrulama | Native archive yalnız macOS/Xcode'da gerçektir |
| Release asset | Deterministik repo-owned generator | Telif ve default Flutter asset riskini kaldırır |
| Hata ekranı | Sabit safe diagnostic code | Raw exception/path/içerik sızıntısını önler |

## Kod çalışma akışı

```text
Uygulama açılışı
  -> güvenli environment root doğrulaması
  -> restore journal recovery
     -> eski state rollback VEYA yeni state doğrulama/tamamlama
     -> ambiguous ise normal servisleri açmadan güvenli hata
  -> SQLite bootstrap/migration
  -> application service'leri
  -> notification reconciliation
  -> mobil UI

Release kapısı
  -> pub/analyze/unit-widget
  -> debug APK + Android emulator integration
  -> unsigned ARM64 AAB
  -> merged manifest/privacy/native inventory
  -> ephemeral dış signing
  -> bundletool universal APK
  -> 16 KiB + signer + SHA-256
  -> Python/compileall/state/diff/protected-path audit
```

## “Şunu şöyle yaptık ki...”

- Restore journal'ı küçük ve secretsız tuttuk ki process kill kanıtı kurtarma
  için yeterli olsun ama parola, package veya kullanıcı yolu sızdırmasın.
- Recovery'yi servislerden önce çalıştırdık ki notification veya mutation yarım
  database/attachment çiftine dokunamasın.
- İzinleri merged manifestte denetledik ki plugin güncellemesi görünmeden broad
  yetki ekleyemesin.
- Test signing'ini ephemeral ve dışarıda tuttuk ki signed build yolu kanıtlansın
  ama gerçek upload key taklit edilmesin veya repository'ye girmesin.
- iOS archive'ı Windows'ta yapılmış saymadık ki statik hazırlık ile gerçek Apple
  signing/dağıtım kanıtını birbirine karıştırmayalım.
- Saha checklist'ini `not run` bıraktık ki kurulabilir RC üretmek kullanıcının
  gerçek cihaz kabulünü yanlışlıkla tamamlanmış göstermesin.
