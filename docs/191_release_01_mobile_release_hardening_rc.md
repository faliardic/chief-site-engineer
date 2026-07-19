# Issue #191 — Release 0.1 Mobil Release Candidate Hardening

## Amaç ve değişmeyen ürün sınırı

Bu dilim Flutter mobil CSE `0.1.0+1` uygulamasını yeni iş modülü eklemeden
Android saha RC üretimi ve mağaza teknik ön kabul kapılarına hazırlar. Telefon
device-of-truth, mobil SQLite schema `5` business source-of-truth'tur. Ajanda,
Hatırlatıcı, Puantaj, Beton ve `.csebackup` davranışları korunur.

Gerçek upload/app-signing key, Apple sertifikası, kullanıcı verisi, cloud,
Play Console/App Store Connect gönderimi veya kullanıcı adına saha kabulü bu
Issue kapsamında değildir.

## Android kabul sınırı

Release build açıkça API `36`, Java `17`, NDK `28.2.13676358` ve ARM64 kullanır.
Production application ID `com.faliardic.chiefsiteengineer`; debug ID
`.debug` suffix'iyle ayrıdır. Main manifest otomatik OS backup ve cleartext'i
kapatır. Release merged manifest kapısı:

- yalnız `CAMERA`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED` OS izinlerini;
- AndroidX'in package-private `signature` korumalı receiver iznini;
- `INTERNET`, broad media/storage ve exact-alarm yokluğunu doğrular.

`validate_mobile_release.py` source, merged manifest, Gradle sabitleri, native
ARM64 inventory, icon boyutları, iOS plist/privacy ve secret/network audit'ini
tek fail-closed statik kapıda toplar.

## 16 KiB ve signing artefakt zinciri

Windows release gate şu zinciri çalıştırır:

```text
unsigned ARM64 AAB
  -> bundletool 1.18.3 universal APK
  -> repository-dışı ephemeral test keystore ile imza
  -> zipalign -c -P 16 -v 4
  -> apksigner / jarsigner doğrulaması
  -> SHA-256 checksum
```

Bundletool JAR SHA-256'sı scriptte sabittir. Unsigned ve ephemeral-signed
artefakt adları karıştırılmaz. Test keystore ve random parola sistem temp
dizininde oluşturulur, loglanmaz ve `finally` temizliğinde silinir. Gerçek Play
release'i ayrı app-signing/upload-key sözleşmesini kullanmalıdır.

## Restore process-death journal

Exception rollback'i process kill veya güç kesintisinde çalışamayacağı için swap
öncesinde küçük bir journal atomik yazılır:

```text
prepared
  -> old_state_moved
  -> new_state_activated
  -> validated
  -> journal + staging/rollback cleanup
```

Journal yalnız doğrulanmış operation ID, relative staging adları, monoton phase
sequence ve canonical UTC timestamp taşır. Parola, package içeriği ya da mutlak
kullanıcı yolu taşımaz. Bootstrap önce journal recovery'yi çalıştırır; bu
tamamlanmadan database service, mutation veya notification reconciliation açmaz.

`prepared` ve `old_state_moved` eski çifte dönülür. `new_state_activated` ve
`validated` aktif yeni çiftin SQLite integrity/FK ve attachment SHA kontrolü
başarılıysa tamamlanır; aksi halde eski çift geri gelir. Eksik/çelişkili recovery
materyalinde veri silinmez, journal/rollback alanı korunur ve kullanıcı yalnız
safe diagnostic kod görür.

## Eski schema ve veri korunumu

Backup format `1` içindeki mobil schema `1`, `2`, `3`, `4` fixture'ları restore
staging alanında atomik olarak schema `5`'e migrate edilir. Schema `5` tam
fixture round-trip'i Ajanda, reminder, notification binding, Puantaj, Beton,
attachment ve append-only event kayıtlarını byte/count düzeyinde korur.
Bilinmeyen gelecek schema downgrade edilmez ve aktif state mutation başlamadan
reddedilir. Bu Issue yeni migration veya schema bump eklemez.

## Privacy, iOS ve görünür release kimliği

`docs/privacy/` altında Türkçe/İngilizce policy, taşınabilir HTML, Play Data
Safety, Apple App Privacy, izin amacı ve SDK manifest envanteri bulunur. Audit
analytics, ads, tracking, hidden network endpoint veya developer server'a veri
aktarımı olmadığını statik olarak denetler. Kullanıcı başlatmalı OS share/export
hedef uygulamanın sorumluluğundadır; backup parolası kurtarılamaz ve uninstall
öncesi backup alınmalıdır.

iOS target'a parse edilebilir `PrivacyInfo.xcprivacy` eklenir. Tracking false,
collected data ve tracking domains boş, uygulamanın direct required-reason API
listesi boş kalır. Locked plugin privacy manifestleri envanterlenir. İlk sürüm
iPhone-only'dir. Windows yalnız statik proje kapısını çalıştırır; gerçek archive
macOS + Xcode 26/iOS 26 SDK + Apple Developer + dış signing gerektirir.

Default Flutter icon/splash yerine haricî asset kullanmadan generator ile proje
mülkiyetinde CSE işareti üretilir. Android adaptive/round icon ve iOS zorunlu
boyutları test edilir; 1024 px AppIcon alpha içermez.

## Güvenli hata UX'i ve regresyon

Top-level Flutter/zone boundary raw exception ve stack trace yerine sabit safe
diagnostic yüzeyi gösterir. Startup/recovery hatası “veriye dokunulmadı” ve
recovery alanının korunduğu bilgisini verir. Kamera/bildirim permission failure,
low-storage/file-write cleanup ve double-tap davranışları mevcut domain testleri
ile korunur. Widget kapısı 320/430 px, 1.6 text scale ve dark/light mode'u
overflow olmadan çalıştırır.

## Tekrarlanabilir kapılar ve hesap bağımlı blocker'lar

Secretsız GitHub Actions workflow'u `workflow_dispatch` ile Flutter `3.44.6`,
Java 17, analyze/test/build, manifest/privacy/16 KiB, Python/compileall ve diff
kapılarını tanımlar. Windows script aynı sözleşmeyi yerel emulator ve geçici
signing zinciriyle çalıştırır. Build/RC çıktıları ignored kalır.

`docs/release/mobile_rc_field_acceptance_checklist.md` bütün gerçek cihaz
adımlarını başlangıçta `not run` tutar. Gerçek upload key oluşturma, Play App
Signing enrollment, closed testing, privacy URL hosting, macOS archive,
TestFlight ve store submission tamamlanmış sayılmaz.
