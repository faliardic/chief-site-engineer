# Issue #198 — Geçici Picker Yolundan Kalıcı Incoming Pakete

Bu notta Android dosya seçicisinin verdiği geçici yolu neden application state
olarak saklamadığımızı, büyük dosyayı nasıl stream ile atomik içe aldığımızı ve
preflight/restore zincirini aynı SHA ile nasıl bağladığımızı kod üzerinden
inceleyeceğiz.

## 1. Sorunu doğru katmanda tanımlamak

Eski sözleşme şuna yakındı:

```dart
Future<String?> pickPackage();
```

Bu `String` hakkında şu soruların cevabı yoktu:

- Yol uygulama alanında mı, provider cache'inde mi?
- Dosyanın seçim anındaki boyutu neydi?
- Seçimden sonra byte'lar değişti mi?
- Hangi seçim işlemi bu dosyayı oluşturdu?
- Cleanup bu yolu güvenle silebilir mi?

Bu nedenle ham string yerine immutable bir value object kullandık:

```dart
class PickedBackupPackage {
  const PickedBackupPackage({
    required this.stablePath,
    required this.originalFileName,
    required this.byteSize,
    required this.sha256,
    required this.importOperationId,
  });

  final String stablePath;
  final String originalFileName;
  final int byteSize;
  final String sha256;
  final String importOperationId;
}
```

Satır satır anlamı:

1. `stablePath`, yalnız app-private incoming veya internal backup kökünü gösterir.
2. `originalFileName`, kullanıcıya ait absolute path'i değil güvenli basename'i
   taşır.
3. `byteSize`, sonradan file length ile yeniden karşılaştırılır.
4. `sha256`, aynı byte dizisini preflight ve restore'a bağlar.
5. `importOperationId`, final dosya adı ve cleanup yetkisini birbirine bağlar.

Bu nesne yalnız bilgi taşır; dosya yazmaz veya silmez. Dosya sistemi davranışı
platform gateway'de, restore kararı application service'te kalır.

## 2. Stream neden gerekli?

`readAsBytes()` bütün dosyayı belleğe alır. Güvenlik sınırımız 512 MiB ise bu,
picker anında gereksiz büyük RAM basıncı demektir. `file_picker` bu yüzden şöyle
çağrılır:

```dart
final result = await FilePicker.platform.pickFiles(
  allowMultiple: false,
  withData: false,
  withReadStream: true,
  type: FileType.custom,
  allowedExtensions: const ['csebackup'],
);
```

- `withData: false`: bütün dosyayı `Uint8List` olarak istemeyiz.
- `withReadStream: true`: byte parçalarını sırayla tüketiriz.
- `FileType.custom`: yalnız `.csebackup` seçim yüzeyini açar.

Provider stream vermezse `PlatformFile.path` fallback'i vardır. Önemli ayrım:
fallback path UI'ye döndürülmez; aynı `pickPackage()` çağrısı tamamlanmadan açılıp
private alana kopyalanır.

## 3. `.part` + flush + hash + rename akışı

Kopyanın çekirdeği sadeleştirilmiş biçimde şöyledir:

```dart
await partial.create(exclusive: true);
final output = partial.openWrite();
final digestInput = sha256.startChunkedConversion(digestOutput);
var copiedBytes = 0;

await for (final chunk in sourceStream) {
  copiedBytes += chunk.length;
  if (copiedBytes > maximumPackageBytes) {
    throw const MobileBackupFailure('oversize_package', '...');
  }
  digestInput.add(chunk);
  output.add(chunk);
}

digestInput.close();
await output.flush();
await output.close();
```

Satır satır:

1. `exclusive: true`, aynı operation ID dosyası zaten varsa overwrite etmez.
2. `openWrite`, byte'ları disk sink'ine yollar.
3. Chunked SHA converter, RAM'de bütün dosyayı biriktirmeden digest üretir.
4. Sayaç her chunk'ta büyür; sınır geçildiği anda stream kesilir.
5. Aynı chunk hem hash'e hem dosyaya gider; iki farklı okuma sırası oluşmaz.
6. `flush`, buffered byte'ların işletim sistemine gönderilmesini ister.
7. `close`, handle'ı rename öncesi kapatır.

Sonra partial dosya baştan stream ile yeniden okunur:

```dart
final inspection = await _inspectFile(partial);
if (inspection.byteSize != copiedBytes ||
    inspection.sha256 != copiedDigest) {
  throw const MobileBackupFailure(
    'package_import_verification_failed',
    'Seçilen yedek güvenli alana alınamadı.',
  );
}
await partial.rename(destination.path);
```

Bu ikinci okuma “yazmayı denedik” ile “diskte doğrulanmış byte var” arasındaki
farkı kapatır. Partial ve destination aynı directory'de olduğundan rename dosya
sistemi düzeyinde atomiktir: tüketici ya eski durumu ya final dosyayı görür;
yarım final adını görmez.

## 4. Cleanup neden path string'i silmemeli?

Tehlikeli yaklaşım:

```dart
await File(userSuppliedPath).delete();
```

Bu kod path traversal, yanlış state veya test hatasında root dışı bir dosyayı
silebilir. Güvenli cleanup üç kanıt ister:

```dart
final expected = _resolveIncomingChild(
  '${package.importOperationId}.csebackup',
);
final candidate = path.normalize(path.absolute(package.stablePath));
if (candidate != expected.path) return;

final type = await FileSystemEntity.type(candidate, followLinks: false);
if (type == FileSystemEntityType.file) {
  await File(candidate).delete();
}
```

1. Operation ID izin verilen karakter sözleşmesine uyar.
2. Beklenen final ad uygulama tarafından yeniden türetilir.
3. Gelen path bu exact ada eşit değilse silme yapılmaz.
4. `followLinks: false`, symlink'i regular file gibi takip etmez.

Bu bir **capability** yaklaşımıdır: sadece operation ID + exact incoming path
çifti cleanup yetkisi verir.

## 5. Preflight ve restore aynı paketi nasıl kullanıyor?

Application service artık şunu kabul eder:

```dart
Future<MobileBackupPreflight> preflightBackup(
  PickedBackupPackage package,
  String password,
);
```

Önce `_requireAllowedPackage(package)` çalışır. Bu method:

- metadata formatını;
- incoming veya `exports_backups` direct-child olmasını;
- regular file olmasını;
- resolved gerçek path'in aynı güvenli root altında kalmasını;
- byte size ve SHA-256 eşleşmesini

doğrular. Bundan sonra decrypt/archive/schema/SQLite/attachment kontrolleri
çalışır.

Preflight sonucu aynı package nesnesini taşır:

```dart
return MobileBackupPreflight(
  package: package,
  manifest: prepared.archive.manifest,
  migratedSchemaVersion: AppDatabase.schemaVersion,
);
```

Restore command da `preflight.package` ve `preflight.packageSha256` kullanır.
Restore öncesi dosya yeniden size/SHA kontrolünden geçer. Böylece bir saldırgan
veya hatalı process preflight'tan sonra final dosyayı değiştirirse aktif SQLite
swap başlamadan fail-closed olur.

## 6. Lifecycle karar tablosu

| Olay | Stable incoming | Aktif SQLite | Neden |
|---|---|---|---|
| Picker cancel | Mevcut seçim korunur | Değişmez | Cancel yeni intent üretmez |
| Yeni seçim başarılı | Yeni kalır, eski temizlenir | Değişmez | Tek UI selection |
| Copy/hash/rename hata | Partial/final temizlenir | Değişmez | Yarım import yok |
| Wrong password | Paket korunur | Değişmez | Parola retry mümkün |
| Unsupported/corrupt | Paket korunur | Değişmez | İnceleme aktif truth'a dokunmaz |
| Restore failure | Paket korunur | Eski state rollback/korunur | Retry ve tanı mümkün |
| Restore success | Paket temizlenir | Yeni state doğrulanmıştır | Artık incoming gerekmez |
| Ekran kapanışı | Best-effort cleanup | Değişmez | Terk edilen seçim tutulmaz |
| Process kill | Bootstrap cleanup | Değişmez | Orphan/expired bakım |

## 7. Bootstrap reconciliation

Bootstrap bütün staging ağacını silmez. Yalnız `incoming_backups` direct
child'larını inceler:

```text
temp_staging/
└── incoming_backups/
    ├── <operation>.part       -> bootstrap'ta orphan temizlenir
    ├── <operation>.csebackup  -> 24 saatten eskiyse temizlenir
    ├── keep.txt               -> bilinmeyen ad, dokunulmaz
    └── subdir/                -> directory, dokunulmaz
```

Root dışındaki benzer adlı dosya hiçbir zaman listeye girmez. `followLinks:
false` sayesinde link hedefi takip edilmez. Cleanup hata verirse bootstrap aktif
SQLite erişimini engellemez; sonraki açılış tekrar dener.

## 8. Test kodu neyi kanıtlıyor?

Örnek source-loss testi:

```dart
final imported = await gateway.pickPackage();
await source.delete();

expect(await File(imported!.stablePath).readAsBytes(), bytes);
expect(imported.sha256, sha256.convert(bytes).toString());
```

- İlk satır dönmeden private copy tamamlanmıştır.
- İkinci satır provider cache kaybını simüle eder.
- Sonraki okumalar dış source'a değil stable path'e gider.

Wrong-password retry testi:

```dart
await expectLater(
  application.preflightBackup(imported, 'yanlis-parola'),
  _failureCode('wrong_password_or_tampered'),
);
expect(await File(imported.stablePath).exists(), isTrue);

final preflight = await application.preflightBackup(imported, correctPassword);
```

İlk preflight cryptographic olarak reddedilir ama paket silinmez. Aynı typed
metadata ve aynı SHA ile ikinci deneme yapılır.

Failure injection testleri üç ayrı sınırı doğrular:

- stream `addError` → copy failure;
- copy sonrası partial byte değiştirme → hash failure;
- rename öncesi hook exception → rename failure.

Üçünde de incoming root içinde `.part` veya final kalmadığı test edilir.

API 36 integration testi gerçek Android dosya sistemi üzerinde provider-cache
benzeri bir source stream'i import eder, source'u siler, preflight + restore
yapar ve restore success sonrası stable incoming dosyanın temizlendiğini
doğrular.

## 9. Sidecar ile production RC neden ayrıdır?

Debug build'in application ID'si
`com.faliardic.chiefsiteengineer.debug` olduğu için mevcut production RC ile yan
yana kurulabilir. Sidecar yalnız dışa alınmış gerçek paketin preflight'ını
kanıtlamak için kullanılabilir; production verisini otomatik restore etmez.

Release gate:

- debug sidecar package ID'sini `aapt2` ile;
- storage/media izin yokluğunu artifact manifestinden;
- debug ve RC signer'ını;
- ARM64 native inventory ve 16 KiB alignment'ı;
- iki artifact'ın SHA-256 değerini

doğrular. Ephemeral key repository dışında üretilir ve gate sonunda silinir.

## Şunu şöyle yaptık ki...

Geçici picker path'ini daha uzun süre saklamaya çalışmadık; picker'ın verdiği
erişim henüz geçerliyken byte'ları private incoming root'a stream ettik ki UI
ile preflight arasındaki süre artık dosya sağlayıcısının cache ömrüne bağlı
olmasın.

Cleanup'a genel bir “path sil” yetkisi vermedik; operation ID'den exact final
adı yeniden türettik ve yalnız regular direct-child dosyayı sildik ki belirsiz
veya root dışı kullanıcı dosyası hiçbir hata yolunda hedef olamasın.

Preflight sonucuna yalnız SHA string'i değil aynı typed package'ı koyduk ki
restore path, size, SHA ve import kimliğini tek kanonik seçimden alsın; kırılgan
çoklu state zinciri oluşmasın.

Schema veya backup formatını yükseltmedik; sorun veri modelinde değil picker
erişiminin yaşam süresindeydi. Böylece schema `1`–`7` fixture'ları, format `1`,
restore journal, rollback ve notification reconciliation olduğu gibi kaldı.
