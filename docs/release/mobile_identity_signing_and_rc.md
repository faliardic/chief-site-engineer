# Mobil Kimlik, Signing ve Release Candidate Sözleşmesi

## Sabit ürün kimliği

| Alan | Release | Debug |
|---|---|---|
| Görünür ad | Şefim | Şefim (Debug) |
| Android application ID | `com.faliardic.sefim` | `com.faliardic.sefim.debug` |
| iOS bundle ID | `com.faliardic.sefim` | `com.faliardic.sefim.debug` |
| Uygulama sürümü | `0.1.0+1` | `0.1.0+1-debug` davranışı |

Sentetik Android kabul paketi `com.faliardic.sefim.acceptance` kimliğini ve
cihaz etiketinde tam `Şefim` adını kullanır; uygulama içinde
`Kabul ortamı · sentetik veri` uyarısı görünür. Eski
`com.faliardic.chiefsiteengineer`, `.debug` ve `.acceptance` kimlikleri
dondurulmuştur. Şefim bu paketleri kurmaz, açmaz, değiştirmez veya veri
köklerini paylaşmaz; yeni OS sandbox'ında temiz yerel veritabanıyla başlar.

Release tabanı Flutter `3.44.6`, Dart `3.12.2`, Java 17 bytecode, Android
compile/target API 36 ve NDK `28.2.13676358`'dir. İlk Apple sürümü iPhone
target family `1` ile sınırlandırılmıştır.

## Google Play App Signing yönü

Gerçek yayın için Google app-signing key'i Google Play App Signing'de tutulur;
geliştiricide bundan ayrı bir upload key bulunur. Repository hiçbir gerçek key,
parola veya sertifika taşımaz. Issue #191 gerçek upload key üretmez ve Play
Console kaydı yapmaz.

Gradle yalnız `CSE_KEY_PROPERTIES_FILE` ile verilen **repository dışındaki**
properties dosyasını kabul eder. Signed build özellikle istenmişse
`CSE_REQUIRE_SIGNING=true` kullanılır; dosya yok/eksikse build açık hata verir.
Release hiçbir zaman debug key'e sessizce düşmez. Signing istenmiyorsa AAB
bilinçli olarak unsigned üretilir.

Örnek dış dosya:

```properties
storeFile=ephemeral-release-gate.jks
storePassword=<runtime-only>
keyAlias=cse-ephemeral
keyPassword=<runtime-only>
```

Repository'deki `mobile/android/key.properties.example` yalnız alan
sözleşmesidir; gerçek değer içermez.

## Secretsız test signing'i

`scripts/release_gate.ps1`, sistem temp dizininde rastgele parolalı ephemeral
keystore üretir. Unsigned AAB ile ephemeral-signed AAB/APK adlarını ayrı tutar,
signer doğrulamasını çalıştırır ve `finally` içinde temp key/properties'i siler.
Bu test sertifikası upload key değildir ve update sürekliliği sağlamaz.

İnsan tarafından kullanılacak doğrulamalar:

```powershell
jarsigner -verify -strict -verbose -certs app-release-ephemeral-signed.aab
keytool -printcert -jarfile app-release-ephemeral-signed.aab
Get-FileHash app-release-rc.apk -Algorithm SHA256
```

## Android RC kurulumu

Gate'in ephemeral-signed universal APK'sı release davranışına yakın saha RC'si
olarak kurulabilir; artifact `mobile/build/release_gate/` altında ignored kalır
ve commitlenmez. Debug uygulaması farklı ID ile yan yana durabilir. Aynı
production ID'ye sahip başka sertifikalı test/release varsa imza uyuşmazlığı
nedeniyle update yapılamaz: önce doğrulanmış `.csebackup` alınır, sonra mevcut
uygulamanın kaldırılmasının cihaz verisini sileceği kabul edilerek işlem yapılır.

RC checksum'u her build'de gate sonunda üretilir; repository'ye sabit artifact
veya checksum commitlenmez.

## Apple blocker checklist

Windows üzerinde iOS archive/signing taklit edilmez. Gönderimden önce macOS'ta:

1. Xcode 26 ve iOS 26 SDK kurulu olmalı (`xcodebuild -version`,
   `xcodebuild -showsdks`).
2. Apple Developer hesabı, `com.faliardic.sefim` kaydı, distribution
   certificate ve provisioning profile hesap sahibi tarafından sağlanmalı.
3. `flutter pub get` ve `flutter build ios --release --no-codesign` statik
   compile kapısını geçmeli.
4. `xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner
   -configuration Release -sdk iphoneos -archivePath build/ios/CSE.xcarchive
   archive` gerçek team/signing ayarlarıyla çalıştırılmalı.
5. Archive Organizer'da Privacy Report, embedded SDK privacy manifestleri,
   signatures, AppIcon ve iPhone target incelenmeli.
6. Ancak hesap sahibi onayından sonra export/TestFlight/App Store Connect
   düşünülebilir. Issue #191 bunların hiçbirini yapmaz.

Apple'ın 28 Nisan 2026'dan beri geçerli yayın tabanı Xcode 26 ve iOS 26 SDK'dır:
https://developer.apple.com/news/upcoming-requirements/
