# Issue #180 — Release 0.1 Mobil Temel

## Amaç

Bu dilim CSE 0.1.0 için gerçek Android/iOS Flutter runtime temelini kurar.
Responsive Flask web yüzeyi korunur fakat mobil uygulamanın çalışma
bağımlılığı değildir. Telefon ilk sürümde ana veri cihazıdır ve temel kabuk
internet, bilgisayar, LAN veya cloud backend olmadan açılır.

## Teslim edilen yüzey

`mobile/` tek Dart codebase içinde şunları taşır:

- Android Kotlin platform projesi;
- iOS Swift platform projesi;
- Başlangıç, Hatırlatıcı, Ajanda, Puantaj ve Beton Paketi navigasyonu;
- tamamlanmamış dört özellik alanında açık `Hazırlanıyor` görünümü;
- cihaz-içi SQLite bootstrap ve migration runner;
- platform application-support dizin sözleşmesi;
- UTC/Europe-Istanbul zaman codec'i;
- permission, attachment picker, notification ve export portları;
- unit, widget ve Android integration smoke testleri.

Ajanda, Hatırlatıcı, Puantaj ve Beton Paketi iş davranışı uygulanmamıştır. Bu
Issue yalnız mağazaya uygun büyüyebilen kabuk ve güvenilir local veri temelidir.

## Sabit ürün kimliği

| Sözleşme | Değer |
| --- | --- |
| Uygulama adı | Chief Site Engineer |
| Flutter package | `chief_site_engineer` |
| Sürüm/build | `0.1.0+1` |
| Release application/bundle ID | `com.faliardic.chiefsiteengineer` |
| Debug application/bundle ID | `com.faliardic.chiefsiteengineer.debug` |
| Flutter | `3.44.6 stable` |
| Dart | `3.12.2` |
| Android target/compile SDK | Flutter stable sözleşmesi, doğrulamada Android 36 |
| iOS deployment target | 13.0 |

Release ve debug hem platform sandbox kimliği hem application-support altındaki
`release` / `debug` segmentiyle ayrılır. Debug verisinin release uygulamasında
görünmesi iki ayrı sınırla engellenir.

## Yerel dizin sözleşmesi

`AppDirectories`, platformun verdiği absolute application-support kökünden şu
yapıyı üretir:

```text
cse_mobile/<environment>/
├── database/
│   └── cse_mobile.sqlite3
├── attachments/
├── exports_backups/
└── temp_staging/
```

Her child path normalize edilir ve environment root içinde olduğu doğrulanır.
Relative support root veya root dışına kaçan child path kabul edilmez. Mobil
runtime repository kökündeki `exports/` veya gerçek `CSE_DATA_ROOT` yolunu
keşfetmez.

## SQLite ve migration sözleşmesi

Mobil schema sürümü Python desktop schema'sından bağımsızdır ve `1` olarak
başlar. İlk migration:

```sql
CREATE TABLE schema_versions (
  version INTEGER PRIMARY KEY,
  applied_at TEXT NOT NULL
);

CREATE TABLE smoke_records (
  id TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  created_at TEXT NOT NULL
);
```

Migration zinciri `1..N` kesintisiz olmak zorundadır. Açılışta mevcut
`PRAGMA user_version` okunur; gereken bütün migration'lar, history insert'leri
ve `user_version` ilerlemesi tek SQLite transaction'ında çalışır. Future veya
uyumsuz schema sürümü fail-closed reddedilir.

Transaction sonrasında:

- `user_version` latest version ile eşleşir;
- history satır sayısı migration sayısıyla eşleşir;
- version değerleri 1'den başlayan kesintisiz sıradadır;
- bütün `applied_at` değerleri canonical UTC seconds'tır.

Migration veya validation hatasında database kapatılır, raw exception dışarı
taşınmaz ve bootstrap `BootstrapFailure` döndürür. Testte ikinci migration tablo
oluşturduktan sonra zorla hata üretir; rollback sonrasında `user_version = 0`
ve hiçbir partial tablo olmadığı doğrulanır.

## Restart kalıcılığı

Başarılı bootstrap `mobile-foundation-v1` kimlikli smoke kaydı yoksa ekler.
Kayıt varsa yeniden yazmaz. İkinci bootstrap farklı bir clock kullansa bile ilk
`created_at` korunur. Bu davranış iki düzeyde test edilir:

1. Host SQLite FFI unit testi database'i kapatıp yeniden açar.
2. Android 36.1 emülatör integration testi gerçek `sqflite` platform kanalında
   aynı temp application path'iyle iki bootstrap çalıştırır.

## Zaman sözleşmesi

Mobil kalıcı timestamp:

```text
YYYY-MM-DDTHH:MM:SSZ
```

Kurallar:

- write için UTC `DateTime` zorunludur;
- millisecond/microsecond deterministic biçimde seconds'a düşürülür;
- canonical read offset, boşluk, fractional second, naive veya invalid değer
  kabul etmez;
- normalization girdisi açık `Z` veya `±HH:MM` offset taşır;
- kullanıcı sunumu yalnız `Europe/Istanbul` üzerinden yapılır.

Python ortak fixture'ı mobilde aynıdır:

```text
2026-07-12T21:30:00+03:00
-> 2026-07-12T18:30:00Z
-> 12.07.2026 21:30:00
```

## Platform capability sınırları

Foundation gerçek feature plugin'lerini erken bağlamaz. Bunun yerine:

- `PermissionGateway`;
- `AttachmentPickerPort`;
- `LocalNotificationPort`;
- `ExportSharePort`

tanımlanır. Safe coordinator önce capability iznini sorgular. Sonuç `denied`
veya `unavailable` ise picker/scheduler çağrılmaz. Platform exception'ı kullanıcı
akışını crash ettirmez ve `unavailable` sonucuna çevrilir.

Android manifest yalnız dar izin hazırlığını taşır:

- `POST_NOTIFICATIONS`;
- `CAMERA`;
- `READ_MEDIA_IMAGES`;
- yalnız Android 12 ve altı için `READ_EXTERNAL_STORAGE`.

Broad storage veya background execution izni yoktur. iOS `Info.plist` camera ve
photo library kullanım açıklamalarını Türkçe taşır. Gerçek picker/notification
delivery sonraki özellik Issue'sunda port arkasına eklenir.

Export staging yalnız uygulamanın `temp_staging` dizinine yazar, flush eder ve
aynı application root içindeki `exports_backups` hedefine rename eder. Path
traversal ve overwrite reddedilir. Kullanıcıya dışarı paylaşma platform işlemi
`ExportSharePort` arkasında ayrı kalır.

## Build ve test kanıtı

Yerel doğrulamada:

- `flutter analyze`: temiz;
- `flutter test`: 19 passed;
- Android integration: 1 passed;
- Android debug APK: üretildi;
- Android release AAB: 43.9 MB, üretildi;
- AAB signing: unsigned, repository signing key içermiyor;
- `Info.plist`: geçerli XML;
- iOS bundle/version/deployment değerleri: statik doğrulandı.

Android emülatörü testten sonra kapatılmıştır. Build artifact'ları
`mobile/.gitignore` kapsamında commitlenmez.

## iOS açık platform blocker'ı

Windows Flutter tool'u `flutter build ios` subcommand'ını sunmaz. Bu nedenle
native archive/TestFlight/App Store build'i bu makinede çalıştırılamaz. Kapanış
için ayrı release ortamında şunlar gerekir:

1. macOS;
2. uyumlu Xcode ve iOS SDK;
3. Apple Developer hesabı ve Team seçimi;
4. repository dışında tutulan certificate/provisioning profile;
5. `flutter build ipa` veya Xcode archive doğrulaması.

Bu blocker Android temelini veya tracked iOS project configuration'ını geçersiz
kılmaz; fakat gerçek App Store readiness tamamlandı iddiasını engeller.

## Veri taşınabilirliği

Issue #180 gerçek desktop verisini taşımaz. Gelecekteki explicit import için şu
anlamlar korunur ve sessiz mapping yapılmaz:

- record ID;
- canonical timestamp;
- kaynak schema version;
- attachment SHA-256;
- backup manifest.

Import, attachment hash doğrulaması ve mobil backup/restore ayrı Issue'dur.

## Değişmeyen Python sözleşmeleri

- Python SQLite schema: `4`
- Restore allowlist: `(2, 3, 4)`
- Backup format: `1`
- Günlük Çıktı format: `1`

Mobil SQLite schema bu namespace'leri değiştirmez. Python source, migration,
restore allowlist, Backup ve Günlük Çıktı production kodu değiştirilmemiştir.
