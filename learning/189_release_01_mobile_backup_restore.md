# Issue #189 Öğrenme Notu — Mobil Tam Yedek ve Geri Yükleme

## Bu geliştirmede ne öğrendik?

Yedek “SQLite dosyasını ZIP'e koymak” değildir. SQLite ile fiziksel kanıt
dosyalarının aynı mantıksal ana ait olması, arşivin saldırgan girdileri
reddetmesi, parolanın sızmaması ve restore'un eski durumu yarım bırakmaması
gerekir. Bu nedenle üç ayrı sınırı birlikte kurduk:

1. application-wide concurrency sınırı;
2. authenticated, manifestli paket sınırı;
3. staging/swap/rollback restore sınırı.

## Gerçek kod: ortak seri coordinator

```dart
class MobileOperationCoordinator {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() operation) => _enqueue(operation);

  Future<T> runExclusive<T>(Future<T> Function() operation) =>
      _enqueue(operation);
}
```

Satır satır anlamı:

- `_tail`, kuyruğa son eklenen işin tamamlanma Future'ıdır.
- `run`, normal Ajanda/Puantaj/Beton okuma veya mutation'ını sıraya ekler.
- `runExclusive`, backup/restore niyetini görünür kılar; aynı kuyruğu kullandığı
  için kendinden önceki işi bekler ve sonraki işi doğal olarak bloklar.
- Her işin kendi `Completer`'ı vardır; hata çağırana döner ama `_tail` üzerinde
  yakalandığı için sonraki iş başlamaya devam eder.

Bootstrap'ta aynı nesne bütün service'lere verilir:

```dart
final coordinator = MobileOperationCoordinator();
final agenda = SqliteAgendaApplication(coordinator: coordinator, ...);
final attendance = SqliteAttendanceApplication(coordinator: coordinator, ...);
final concrete = SqliteConcreteApplication(coordinator: coordinator, ...);
final backup = SqliteMobileBackupApplication(coordinator: coordinator, ...);
```

Burada dört ayrı coordinator oluştursaydık her service yalnız kendisiyle seri
çalışırdı; backup başka service mutation'ının ortasına yine girebilirdi.

## Gerçek kod: authenticated encryption

```dart
final key = await Pbkdf2.hmacSha256(
  iterations: 210000,
  bits: 256,
).deriveKeyFromPassword(password: password, nonce: salt);

final box = await AesGcm.with256bits().encrypt(
  clearArchiveBytes,
  secretKey: key,
  nonce: nonce,
  aad: headerBytes,
);
```

- PBKDF2, kullanıcının metin parolasından doğrudan cipher anahtarı kullanmak
  yerine salt ve iteration ile 256-bit anahtar türetir.
- Her pakette random `salt` aynı parolanın aynı anahtarı tekrar üretmesini önler.
- Her pakette random `nonce` AES-GCM mesajını benzersizleştirir.
- `aad`, şifreleme başlığını ciphertext'e kriptografik olarak bağlar.
- AES-GCM ciphertext gizliliğini ve authentication tag ile bütünlüğü birlikte
  sağlar.

Parola manifest/state/event içine yazılmaz. Yanlış parola ile değiştirilmiş
paketi ayıran ayrıntılı bir hata da dışarı verilmez:

```dart
on SecretBoxAuthenticationError {
  throw const MobileBackupFailure(
    'wrong_password_or_tampered',
    'Parola yanlış veya yedek değiştirilmiş.',
  );
}
```

Bu ortak sonuç, saldırgana parola tahmini ile paket manipülasyonu arasında ek
oracle bilgisi vermez.

## Gerçek kod: manifest ve deterministic attachment denetimi

```dart
final rows = await database.query(
  'concrete_attachments',
  columns: ['relative_path', 'byte_size', 'sha256'],
  where: 'archived_at IS NULL',
  orderBy: 'relative_path ASC',
);

for (final row in rows) {
  final bytes = await resolveSafeRelativePath(row['relative_path']).readAsBytes();
  if (bytes.length != row['byte_size'] ||
      sha256.convert(bytes).toString() != row['sha256']) {
    throw attachmentIntegrityFailure;
  }
}
```

Satırlar:

1. Yalnız aktif attachment row'ları alınır.
2. Relative path sırası manifesti deterministik yapar.
3. Yol önce application attachment kökü içinde çözülür.
4. Fiziksel byte boyutu row ile karşılaştırılır.
5. SHA-256 byte içeriğini row ile karşılaştırır.
6. Eksik veya değişmiş kanıt varsa paket oluşturma finalize edilmez.

Restore preflight'ında kontrol ters yönde de çalışır: manifestteki attachment,
ZIP entry, staging dosyası ve SQLite row dördü exact eşleşmelidir.

## Gerçek kod: ZIP path traversal neden iki seviyede kontrol edildi?

Mantıksal yol validator'ı absolute, backslash, drive `:`, boş parça, `.` ve
`..` parçalarını reddeder:

```dart
final parts = value.split('/');
if (value.startsWith('/') ||
    value.contains(r'\') ||
    value.contains(':') ||
    parts.any((part) => part.isEmpty || part == '.' || part == '..') ||
    path.posix.normalize(value) != value) {
  throw unsafePathFailure;
}
```

ZIP kütüphanesinin yüksek seviyeli directory görünümü duplicate adları
tekilleştirebilir. Bu yüzden End Of Central Directory kaydındaki entry count ve
central offset/size sınırlarını okuyup her central header adını ayrıca topladık.
Raw ad listesinde `names.length != names.toSet().length` ise extraction başlamadan
paket reddedilir. Böylece “son dosya ilkini ezer” davranışına güvenilmez.

## Gerçek kod: transaction-safe snapshot

```dart
await active.open();
await requireIntegrity(active.database);
final escaped = snapshotFile.path.replaceAll("'", "''");
await active.database.execute("VACUUM INTO '$escaped'");
```

`VACUUM INTO`, açık SQLite connection'ın tutarlı görünümünden yeni ve bağımsız
bir database üretir. Bu işlem shared coordinator exclusive alanındadır. Ham
aktif database dosyasını açıkken kopyalamak WAL veya yarım page riski taşırdı.
Snapshot ayrıca ayrı connection ile tekrar integrity/FK/schema/smoke/read-model
kontrolünden geçer.

## Gerçek kod: restore swap ve telafi edici rollback

```text
active database     ─rename→ rollback/database.sqlite3
active attachments  ─rename→ rollback/attachments
staged database     ─rename→ active database
staged attachments  ─rename→ active attachments
        ↓
schema + integrity + FK + read-model + attachment smoke
        ↓
notification reconciliation
```

Herhangi bir alt ok hata verirse yeni aktif çift `failed_new` altına çekilir ve
rollback çifti eski konumuna geri taşınır. SQLite transaction dosya sistemi
rename'lerini kapsayamadığı için burada **compensating rollback** kullanılır.
Restore başlamadan ayrıca tam safety backup üretildiğinden, rollback'ın kendisi
de başarısız olursa recovery materyali korunur.

Safety backup neden preflight'tan sonra üretilir? Yanlış parola, bozuk arşiv,
unsupported schema veya traversal saldırısı aktif state üzerinde hiçbir iş
başlatmasın diye. Neden swap'tan önce üretilir? Kullanıcının restore öncesi
gerçek aktif halinin bağımsız kurtarma paketi olsun diye.

## Test kodu neyi doğruluyor?

Gerçek yarış testi şifrelemeyi kontrollü bekletir:

```dart
final backupFuture = backup.createBackup(command);
await encryption.entered.future;

final mutation = agenda.createProject(projectCommand);
await Future<void>.delayed(Duration.zero);
expect(mutationCompleted, isFalse);

encryption.release.complete();
await Future.wait([backupFuture, mutation]);
expect(mutationCompleted, isTrue);
```

Bu test yalnız coordinator sınıfını değil, aynı coordinator verilen gerçek
`SqliteAgendaApplication` ile backup service'i doğrular.

Rollback testi swap sonrasına hata enjekte eder:

```dart
final failing = SqliteMobileBackupApplication(
  restoreHooks: MobileRestoreHooks(
    afterSwapBeforeSmoke: () async => throw StateError('injected'),
  ),
  ...,
);

await expectLater(failing.restoreBackup(command), throwsRestoreFailure);
expect(await fixtureSnapshot(), activeStateBeforeRestore);
```

Bir başka test notification reconciliation callback'ini düşürür. İkisinde de
eski row/event/link değerleri exact geri gelir. Full fixture testi Ajanda,
reminder, notification binding, Puantaj, Beton, append-only event ve attachment
byte'larını backup sonrası değiştirip restore ile birebir geri alır.

Widget testleri 320 px'te validation input preservation'ı, hızlı iki dokunmanın
tek backup oluşturmasını ve restore için checkbox + ayrı modal olmak üzere iki
explicit onay gerektiğini doğrular.

## Teknik karar tablosu

| Karar | Neden | Kaçınılan risk |
| --- | --- | --- |
| Tek shared coordinator | Bütün mobil source mutation'ları aynı sınırda | Cross-service snapshot yarışı |
| `VACUUM INTO` snapshot | Açık SQLite'tan tutarlı bağımsız kopya | WAL/page düzeyinde bozuk kopya |
| PBKDF2 + AES-256-GCM | Paroladan anahtar ve authenticated encryption | Düz ZIP, sessiz ciphertext/header tamper |
| Manifest size + SHA-256 | SQLite ve her kanıtı exact doğrulama | Eksik/değişmiş attachment |
| Raw central-directory kontrolü | Duplicate adı kütüphane tekilleştirmesinden önce görme | ZIP overwrite saldırısı |
| Preflight token | Seçilen dosyanın onaydan sonra değişmediğini doğrulama | TOCTOU paket değişimi |
| Safety backup + rollback pair | Aktif state'i tamamen geri kurabilme | Yarım restore/veri kaybı |
| Notification'ı pakete almama | OS pending listesi türetilmiş durumdur | Duplicate/orphan platform bildirimi |
| Parolayı state'e yazmama | Secret yaşamını işlem belleğiyle sınırlama | Kalıcı credential sızıntısı |

## Kod çalışma akışı

```text
Kullanıcı: Yedek oluştur
  → parola/confirmation validation
  → shared exclusive coordinator
  → SQLite integrity/FK + VACUUM INTO
  → active attachment size/hash audit
  → manifest + ZIP
  → PBKDF2 + AES-GCM
  → decrypt/decode self-check
  → .part → atomic .csebackup finalize
  → safe summary

Kullanıcı: Geri yükle
  → picker + parola
  → salt-okunur tam preflight
  → özet + ilk onay
  → modal ikinci onay
  → paket SHA token yeniden doğrulama
  → automatic safety backup
  → staging → rollback/active swap
  → smoke + attachment audit
  → pending notification reconciliation
  → başarı; hata ise eski çift rollback
```

## “Şunu şöyle yaptık ki...”

Şunu şöyle yaptık ki: telefonun SQLite kayıtları ile sahadaki kanıt byte'ları
tek kurtarma anını temsil etsin; backup başka bir mutation'ın ortasına girmesin,
paket parola bilinmeden okunamasın, değiştirilmiş veya saldırgan arşiv aktif
alana yaklaşamasın ve restore'un son doğrulaması dahi hata verse kullanıcının
önceki mobil hafızası tam çift olarak geri gelsin. OS bildirimi gibi yeniden
üretilebilir durumu pakete taşımayıp SQLite'tan uzlaştırdık; böylece backup
source-of-truth'u korurken duplicate/orphan platform durumunu çoğaltmadı.
