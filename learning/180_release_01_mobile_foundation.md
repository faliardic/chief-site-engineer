# Issue #180 Öğrenme Notu — Flutter Mobil Temel

## Amaç

Bu adımda CSE'nin masaüstündeki Python/Flask uygulamasından bağımsız çalışan
ilk gerçek mobil temelini kurduk. Kullanıcı telefonunda uygulamayı açtığında
internet veya bilgisayar aramadan local database hazırlansın; veri deposu
açılamıyorsa da yarım yazı bırakmadan güvenli mesaj göstersin istedik.

Bu not yalnız “Flutter klasörü ekledik” özeti değildir. Kodun hangi sınırlarla
kurulduğunu, migration transaction'ının nasıl çalıştığını, zamanın neden UTC
tutulduğunu ve testlerin hangi riski yakaladığını adım adım açıklar.

## Hangi dosyada ne yaptık?

| Dosya/alan | Görev | Neden |
| --- | --- | --- |
| `mobile/lib/main.dart` | Flutter başlangıcı | Timezone verisini ve bootstrap'ı tek girişte başlatmak |
| `mobile/lib/app.dart` | Mobil kabuk ve navigasyon | Tamamlanmamış özellikleri dürüstçe `Hazırlanıyor` göstermek |
| `mobile/lib/bootstrap/app_bootstrap.dart` | Path + SQLite açılış koordinasyonu | Ham platform hatasını UI'dan ayırmak |
| `mobile/lib/storage/app_directories.dart` | Yerel dizin sözleşmesi | Database/attachment/export/temp yollarını sandbox içinde tutmak |
| `mobile/lib/storage/app_database.dart` | Migration ve schema validation | Partial schema oluşmasını transaction ile engellemek |
| `mobile/lib/storage/smoke_record.dart` | Restart kalıcılık kanıtı | Aynı database'in tekrar açıldığını küçük bir kayıtla göstermek |
| `mobile/lib/core/time/cse_time_codec.dart` | UTC/İstanbul dönüşümü | Python ile aynı timestamp anlamını korumak |
| `mobile/lib/platform/*.dart` | Permission ve platform portları | Plugin ayrıntısını domain/application sınırından uzak tutmak |
| `mobile/test/` | Unit ve widget testleri | Hızlı ve deterministik davranış kanıtı |
| `mobile/integration_test/` | Android cihaz smoke testi | Gerçek `sqflite` platform kanalını sınamak |

## Flutter uygulaması nasıl başlıyor?

Gerçek giriş kodu:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  CseTimeCodec.initialize();
  runApp(CseApp(bootstrap: AppBootstrap.production().start()));
}
```

Satır satır:

1. `main()` bir `Future` döndürür; çünkü platform plugin'leri başlamadan önce
   Flutter binding'i hazırlamamız gerekir.
2. `WidgetsFlutterBinding.ensureInitialized()` native platform kanallarını
   kullanıma hazırlar.
3. `CseTimeCodec.initialize()` IANA timezone verisini yükler. Böylece cihazın
   kendi timezone ayarı ne olursa olsun `Europe/Istanbul` bulunabilir.
4. `AppBootstrap.production().start()` local dizinleri ve SQLite'ı hazırlar.
5. `CseApp`, bu sonucu `FutureBuilder` ile bekler. Success ise ana kabuk,
   failure ise güvenli hata ekranı açılır.

Burada önemli karar şudur: UI database exception'ını yakalamaya çalışmaz.
Bootstrap exception'ı kendi sınırında kapatır ve yalnız `BootstrapFailure`
üretir. Böylece absolute path veya SQLite teknik mesajı kullanıcıya sızmaz.

## Debug ve release neden ayrıldı?

Android build yapılandırmasında:

```kotlin
debug {
    applicationIdSuffix = ".debug"
    versionNameSuffix = "-debug"
    manifestPlaceholders["appLabel"] = "Chief Site Engineer (Debug)"
}

release {
    manifestPlaceholders["appLabel"] = "Chief Site Engineer"
}
```

Release kimliği:

```text
com.faliardic.chiefsiteengineer
```

Debug kimliği:

```text
com.faliardic.chiefsiteengineer.debug
```

Android bu iki kimliği iki farklı uygulama sandbox'ı kabul eder. Dart tarafında
da `debug` ve `release` dizin segmentleri ayrıdır. İki katmanlı ayrım, test
kaydının gerçek yayın verisine karışma riskini azaltır.

Release build'e debug signing bağlamadık. Bu nedenle AAB build edilebilir ama
repository'de keystore veya secret yoktur. Gerçek Play signing ayrı güvenli
release adımında yapılır.

## Yerel path sözleşmesi nasıl korunuyor?

Temel factory şu fikri uygular:

```dart
final root = Directory(
  path.normalize(
    path.join(supportRoot.path, 'cse_mobile', environment.storageSegment),
  ),
);
```

Ardından her child için:

```dart
if (!path.isWithin(normalizedRoot, candidate)) {
  throw const PathContractViolation(
    'application directory escaped its environment root',
  );
}
```

Satır satır:

1. Platform bize application-support kökünü verir.
2. `path.join` işletim sistemine uygun separator kullanır.
3. `path.normalize` `.` ve benzeri path parçalarını kararlı hâle getirir.
4. Child absolute path tekrar normalize edilir.
5. `path.isWithin` child'ın gerçekten root altında olduğunu kanıtlar.
6. Kanıt yoksa directory oluşturulmadan exception üretilir.

Bu kontrol traversal riskini azaltır. Ayrıca mobil runtime repository
`exports/` klasörünü veya desktop `CSE_DATA_ROOT` değerini hiç keşfetmez.

## SQLite migration neden tek transaction?

Migration runner'ın kalbi:

```dart
await candidate.transaction((transaction) async {
  final versionRows = await transaction.rawQuery('PRAGMA user_version');
  final currentVersion = Sqflite.firstIntValue(versionRows) ?? 0;

  for (final migration in migrations.where(
    (item) => item.version > currentVersion,
  )) {
    await migration.apply(transaction);
    await transaction.insert('schema_versions', {
      'version': migration.version,
      'applied_at': CseTimeCodec.encodeUtc(clock()),
    });
    await transaction.execute(
      'PRAGMA user_version = ${migration.version}',
    );
  }
});
```

Satır satır:

1. `candidate.transaction(...)` içindeki her write aynı SQLite transaction'ına
   girer.
2. `PRAGMA user_version` database'in hangi migration seviyesinde olduğunu
   söyler.
3. Yalnız mevcut sürümden büyük migration'lar seçilir.
4. `migration.apply` tablo/index değişikliğini yapar.
5. Aynı transaction içinde append-only `schema_versions` history satırı yazılır.
6. Aynı transaction içinde SQLite `user_version` ilerletilir.
7. Herhangi bir await exception üretirse transaction bütünüyle rollback olur.

Neden yalnız `user_version` kullanmadık? Çünkü `schema_versions` bize her
uygulanan adımın canonical zamanını ve kesintisiz sırasını doğrulama olanağı
verir. Neden yalnız history kullanmadık? Çünkü SQLite araçlarıyla hızlı sürüm
okuması için `user_version` standart bir metadata alanıdır. İkisini birlikte
doğrulamak drift'i yakalar.

## İlk schema ne içeriyor?

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

Bu tablolar henüz Ajanda veya Hatırlatıcı verisi değildir. `smoke_records`,
database'in gerçekten kalıcı olduğunu kanıtlayan küçük foundation kaydıdır.
Feature tabloları kendi Issue'larında migration zincirine eklenecektir.

## Smoke kayıt restart'ı nasıl kanıtlıyor?

Repository önce aynı ID'yi arar:

```dart
final rows = await transaction.query(
  'smoke_records',
  where: 'id = ?',
  whereArgs: [foundationRecordId],
  limit: 1,
);

if (rows.isNotEmpty) {
  return _fromRow(rows.single);
}
```

Kayıt varsa update yapılmaz. Yoksa bir kez eklenir. Test ilk açılışta clock'u
08:00, ikinci açılışta 09:00 yapar. İkinci sonuç hâlâ 08:00 taşıyorsa kayıt
silinip yeniden üretilmemiştir; aynı SQLite dosyasından okunmuştur.

## UTC ve İstanbul zamanı nasıl ayrıldı?

Canonical storage örneği:

```text
2026-07-12T18:30:00Z
```

Sunum:

```text
12.07.2026 21:30:00
```

Codec'in write bölümü:

```dart
static String encodeUtc(DateTime value) {
  if (!value.isUtc) {
    throw const TimeContractViolation('timestamp must be aware UTC');
  }
  final seconds = DateTime.utc(
    value.year,
    value.month,
    value.day,
    value.hour,
    value.minute,
    value.second,
  );
  return '${_four(seconds.year)}-${_two(seconds.month)}-${_two(seconds.day)}'
      'T${_two(seconds.hour)}:${_two(seconds.minute)}:${_two(seconds.second)}Z';
}
```

Satır satır:

1. `isUtc` false ise cihaz local saatini sessizce UTC sanmayız.
2. Yeni `DateTime.utc` yalnız year..second parçalarını alır.
3. Millisecond/microsecond deterministic olarak çıkarılır.
4. Padding helper'ları exact iki ve dört haneli alan üretir.
5. Son karakter her zaman `Z` olur.

Read regex'i offset, boşluk ve fractional second kabul etmez. Explicit offset
normalization ayrı method'dur. Bu ayrım “okurken her şeyi sessizce düzeltme”
hatasını önler.

## Permission denied neden exception değildir?

Kamera örneğinde akış:

```text
Kullanıcı kamera seçer
-> SafeCapabilityService izin ister
-> denied ise picker çağrılmaz
-> unavailable ise picker çağrılmaz
-> granted ise AttachmentPickerPort çağrılır
-> plugin hatası unavailable sonucuna çevrilir
```

Bu foundation gerçek plugin'i henüz seçmez. Port, sonraki feature diliminin
`image_picker`, document picker veya notification plugin'ini güvenli sınırdan
takmasını sağlar. İzin yokken native API'yi zorlamamak hem crash'i hem gereksiz
izin döngüsünü önler.

## Export staging nasıl güvenli tutuldu?

```dart
if (fileName.isEmpty || path.basename(fileName) != fileName) {
  throw const PathContractViolation(
    'export file name must be a basename',
  );
}
```

Dosya önce `temp_staging/<name>.part` içine flush edilir, sonra aynı app root
içindeki `exports_backups/<name>` hedefine rename edilir. Hedef zaten varsa
üzerine yazılmaz. Dışarı paylaşma işlemi `ExportSharePort` ile ayrıdır.

## Test kodu neyi doğruluyor?

### 1. Migration rollback testi

Test ikinci migration'da tablo oluşturduktan sonra bilerek hata fırlatır:

```dart
DatabaseMigration(
  version: 2,
  apply: (transaction) async {
    await transaction.execute(
      'CREATE TABLE partial_write (id INTEGER)',
    );
    throw StateError('intentional migration failure');
  },
)
```

Sonra raw database açılır ve şunlar beklenir:

```dart
expect(version, 0);
expect(tables, isEmpty);
```

Bu, yalnız exception döndüğünü değil, gerçekten partial state kalmadığını
kanıtlar.

### 2. Python zaman fixture eşliği

```dart
expect(
  CseTimeCodec.normalizeAware('2026-07-12T21:30:00+03:00'),
  '2026-07-12T18:30:00Z',
);
```

Desktop Python testiyle aynı değer kullanıldığı için iki runtime aynı saha
anını farklı yorumlamaz.

### 3. Permission denied testi

Fake gateway `denied` döndürür. Test picker call sayısının `0` kaldığını
doğrular. Yalnız UI mesajına bakmak yerine gerçek platform mutation sınırını
ölçer.

### 4. Widget testi

Başlangıç, Hatırlatıcı, Ajanda, Puantaj ve Beton Paketi label'ları aranır.
Ajanda'ya dokunulunca `Hazırlanıyor` görünmelidir. Bootstrap failure testinde
navigation hiç oluşmamalıdır.

### 5. Android integration testi

Gerçek Android emülatöründe:

1. Temp sandbox oluşturulur.
2. Gerçek `sqflite` factory ile bootstrap çalışır.
3. Database kapanır.
4. Aynı path farklı clock ile yeniden açılır.
5. Smoke `created_at` değişmemelidir.
6. Flutter shell pump edilir ve offline temel metni bulunur.

Unit test host adapter'ını, integration test gerçek Android platform kanalını
kullanır. İkisini birlikte çalıştırmak daha güçlü kanıttır.

## Teknik karar tablosu

| Karar | Seçilen yaklaşım | Seçilmeyen yaklaşım | Gerekçe |
| --- | --- | --- | --- |
| Mobil runtime | Flutter/Dart | Flask webview/PWA-only | Android+iOS tek codebase ve gerçek store kabuğu |
| Database | Cihaz-içi SQLite | Cloud API | Offline-first ve device of truth |
| Migration | Tek transaction + history | Ayrı DDL/write zinciri | Partial schema bırakmamak |
| Zaman | UTC storage, İstanbul sunum | Local wall-clock storage | Cihaz timezone değişiminden etkilenmemek |
| Ortam ayrımı | ID + path çift sınırı | Tek database | Debug verisini release'den ayırmak |
| Platform erişimi | Port + safe coordinator | UI'dan doğrudan plugin | Permission denied ve plugin hatasını yönetmek |
| Release signing | Repo dışında | Debug key'i release'e bağlamak | Secret sızıntısını ve sahte store-ready iddiasını önlemek |
| iOS kabul | Static config + açık blocker | Windows'ta build olmuş gibi yazmak | iOS archive yalnız macOS/Xcode'da çalışır |

## Kod çalışma akışı

```text
main
-> Flutter binding
-> timezone initialize
-> production AppEnvironment seç
-> platform application-support path al
-> environment dizinlerini validate/create et
-> SQLite aç
-> migration transaction çalıştır
-> schema/history doğrula
-> smoke kaydı oku veya bir kez ekle
-> database'i kapat
-> BootstrapSuccess
-> mobil navigasyon kabuğu
```

Hata akışı:

```text
path/database/migration/schema hatası
-> varsa database'i kapat
-> raw exception'ı UI'a taşıma
-> BootstrapFailure
-> "Hiçbir kayıt yazılmadı" güvenli ekranı
```

## Şunu şöyle yaptık ki...

Şunu şöyle yaptık ki, mobil uygulama ilk günden yalnız güzel bir ekran değil,
veri kökü, migration, zaman ve hata davranışı tanımlı güvenilir bir temel olsun:
feature sayfalarını erken doldurmak yerine `Hazırlanıyor` bıraktık; SQLite
migration'larını tek transaction'a aldık; debug/release verisini iki sınırla
ayırdık; izin reddinde native çağrıyı hiç yapmadık; iOS build'ini Windows'ta
tamamlanmış göstermeyip gerçek macOS/Xcode blocker'ını açık kaydettik.

## Sınırlar ve sonraki iş

Bu adımda yapılmayanlar:

- Ajanda günlük log davranışı;
- logdan bağlı Hatırlatıcı;
- gerçek notification delivery;
- camera/photo/file picker plugin implementasyonu;
- mobil backup/restore manifest'i;
- desktop→mobile import;
- cloud sync;
- Play Store/App Store submission.

Sonraki dar mobil dilim mevcut `field_observations` ve `follow_up_items`
sözleşmesini Flutter tarafına taşırken bu foundation'ın path, time, migration ve
platform portlarını kullanmalıdır.
