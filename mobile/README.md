# CSE mobil uygulama temeli

Bu klasör Chief Site Engineer 0.1.0 için tek Dart codebase kullanan Flutter
Android/iOS uygulamasıdır. Mobil runtime Python/Flask sunucusuna bağlanmaz;
cihaz-içi SQLite ve uygulamaya özel yerel dosya dizinleriyle offline çalışır.

## Sabit kimlikler

| Alan | Değer |
| --- | --- |
| Flutter proje adı | `chief_site_engineer` |
| Uygulama adı | `Chief Site Engineer` |
| Sürüm/build | `0.1.0+1` |
| Android release application ID | `com.faliardic.chiefsiteengineer` |
| Android debug application ID | `com.faliardic.chiefsiteengineer.debug` |
| iOS release bundle ID | `com.faliardic.chiefsiteengineer` |
| iOS debug bundle ID | `com.faliardic.chiefsiteengineer.debug` |
| Mobil schema version | `2` |
| Sunum timezone | `Europe/Istanbul` |

Debug ve release farklı platform kimlikleri ve farklı `debug` / `release` veri
kökleri kullanır. Böylece geliştirme kaydı yayın verisine karışmaz.

## Yerel veri dizinleri

Platformun application-support dizini altında şu uygulama içi yapı kurulur:

```text
cse_mobile/<debug|release>/
├── database/cse_mobile.sqlite3
├── attachments/
├── exports_backups/
└── temp_staging/
```

Bütün child yollar ortak environment kökü altında doğrulanır. Relative path ve
root dışına kaçış fail-closed reddedilir. Repository `exports/` klasörü mobil
runtime tarafından kullanılmaz.

## SQLite bootstrap ve Ajanda migration'ı

İlk açılışta tek transaction içinde:

1. `schema_versions` tablosu oluşturulur.
2. `smoke_records` tablosu oluşturulur.
3. Migration sürümü ve canonical UTC uygulama zamanı yazılır.
4. SQLite `user_version` aynı sürüme alınır.

Herhangi bir adım başarısız olursa transaction rollback olur. Bootstrap hata
detayını veya path'i kullanıcıya sızdırmaz ve kayıt yazıldığı iddiasında
bulunmaz. Başarılı açılışta `mobile-foundation-v1` smoke kaydı bir kez eklenir;
restart aynı `created_at` değerini okur.

Schema `2`, schema `1` verisini koruyan tek atomik migration ile şunları ekler:

- `projects`;
- günlük log source-of-truth'u `field_observations`;
- append-only `observation_events`;
- loga project + observation foreign key'iyle bağlı `follow_up_items`;
- append-only `follow_up_events`.

Event tabloları update/delete trigger'larıyla salt eklemelidir. Project, log ve
reminder fiziksel silinemez. Log/reminder kayıtlarında UUID, revision,
`created_at`, `updated_at` ve gelecekte archive/lifecycle uyumlu alanlar bulunur.
Migration veya transaction hatasında yarım tablo, reminder veya event kalmaz.

## Mobil Ajanda ve Hatırlatıcı

Ajanda, seçili `Europe/Istanbul` gününü `observed_at`, `created_at`, ID sırasıyla
gösterir. Bugün/önceki/sonraki/tarih seçimi; proje/tür filtresi ve wildcard
yorumlamayan literal arama vardır. Log formu geçmiş zamanı kabul eder, gelecek
ve invalid zamanı mutation öncesi reddeder; hata halinde form state'i korunur.

Her kart ve log detayından reminder oluşturulabilir. Önerilen metin açıklamadan
gelir ve değiştirilebilir. `action | waiting | recheck`; 15 dakika, 1 saat,
bugün çıkmadan, yarın sabah, Unutma Kutusu ve özel tarih/saat desteklenir.
Reminder ilk insert'ten itibaren source log ve project ID taşır; creation row ve
event tek transaction'dadır. Hatırlatıcı ekranı Unutma Kutusu, Bugün,
Yaklaşanlar ve source Ajanda deep-link'ini sunar.

## Zaman sözleşmesi

- Kalıcı an: aware UTC, exact `YYYY-MM-DDTHH:MM:SSZ`.
- Precision: seconds; microsecond yeni mobile storage değeri değildir.
- Kullanıcı sunumu: `Europe/Istanbul`.
- Naive, invalid veya canonical olmayan read değeri reddedilir.
- Explicit offset girdisi önce UTC'ye normalize edilebilir.
- Datetime-local girdisi yalnız açık İstanbul wall-clock decoder'ıyla canonical
  UTC'ye çevrilir; storage katmanı naive değeri kabul etmez.

Python fixture eşliği:

```text
2026-07-12T21:30:00+03:00
-> 2026-07-12T18:30:00Z
-> 12.07.2026 21:30:00 Europe/Istanbul
```

## Geliştirici komutları

Flutter `3.44.6 stable` ve Dart `3.12.2` ile doğrulanmıştır:

```powershell
cd mobile
flutter pub get
dart format lib test integration_test
flutter analyze
flutter test
flutter build apk --debug
flutter build appbundle --release
```

Android emülatör integration smoke testi:

```powershell
flutter test integration_test/app_smoke_test.dart -d <android-device-id>
```

## iOS sınırı

Tracked iOS project, scheme, `Info.plist`, iOS 13 deployment target, bundle
kimlikleri, sürüm/build değişkenleri ve camera/photo açıklamaları mevcuttur.
Native iOS archive/TestFlight/App Store build'i yalnız macOS + Xcode üzerinde
çalışır. Gerçek signing için ayrıca Apple Developer hesabı, takım seçimi ve
repository dışında tutulan provisioning/certificate gerekir.

## Secret ve signing

- Keystore, signing key, provisioning profile ve certificate commitlenmez.
- Android release build'e debug signing bağlanmaz.
- Üretilen release AAB doğrulamada unsigned'dır; mağaza signing ayrı release
  hardening adımında güvenli dış konfigürasyonla sağlanır.
- Build çıktıları ve yerel Flutter/Gradle cache'leri ignored kalır.

## Bilinçli olarak eklenmeyenler

- Cloud backend veya sync
- Kullanıcı hesabı/auth server
- Masaüstü verisinin otomatik migration'ı
- Log attachment/fotoğraf bağlama
- Tam reminder complete/snooze/cancel yaşam döngüsü
- Puantaj veya Beton Paketi davranışı
- Gerçek notification delivery, camera/file picker plugin'i veya store submission
