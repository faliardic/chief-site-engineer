# Issue #187 Öğrenme Notu — Mobil Beton Döküm Paketi

## Bu geliştirmede ne öğrendik?

Beton dökümü tek bir tabloya sığan basit form değildir. Dökümün planı,
kontrolleri, mikserleri, numuneleri, dosya kanıtları, takipleri ve reminder'ları
birlikte tutarlı kalmalıdır. Bu yüzden ana teknik fikir bir **aggregate** ve onu
koruyan **application service** oldu.

## Gerçek kod: immutable komut ve optimistic revision

Truck kaydı için komut değerleri sonradan değiştirilemez:

```dart
class SaveConcreteTruckCommand {
  const SaveConcreteTruckCommand({
    required this.id,
    required this.pourId,
    required this.eventId,
    required this.expectedPourRevision,
    required this.expectedTruckRevision,
    required this.sequenceNo,
    required this.vehiclePlate,
    required this.deliveryNoteNumber,
    required this.volumeM3,
    required this.result,
  });
}
```

Satır satır anlamı:

- `id`: retry boyunca aynı kalan truck UUID'sidir.
- `pourId`: truck'ın başka pakete bağlanmasını engelleyen aggregate kimliğidir.
- `eventId`: aynı mutation geçmişinin ikinci kez üretilmesini önler.
- `expectedPourRevision`: kullanıcının ekranda gördüğü package revision'ıdır.
- `expectedTruckRevision`: yeni truck için `0`, update için mevcut revision'dır.
- `sequenceNo` ve `deliveryNoteNumber`: aynı dökümde unique alanlardır.
- `volumeM3`: yalnız pozitif, finite değer kabul eder.
- `result`: received/held/returned/partial kontrollü vocabulary'sidir.

Application service update'i şu SQL koşuluyla yapar:

```dart
final changed = await database.update(
  'concrete_trucks',
  {...values, 'revision': truck.revision + 1, 'updated_at': timestamp},
  where: 'id = ? AND revision = ?',
  whereArgs: [truck.id, truck.revision],
);
if (changed != 1) throw _staleFailure();
```

`WHERE id = ? AND revision = ?` önemli: başka işlem revision'ı değiştirdiyse
update sıfır satır etkiler ve eski ekran verisi fail-closed reddedilir.

## Gerçek kod: türetilen metraj

Gerçek gelen beton için düzenlenebilir ikinci bir toplam kolonu oluşturmadık:

```dart
final actual = trucks
    .where(
      (item) =>
          item.result == ConcreteTruckResult.received ||
          item.result == ConcreteTruckResult.partial,
    )
    .fold<double>(0, (sum, item) => sum + item.volumeM3);
final variance = actual - pour.plannedVolumeM3;
```

Satırlar:

1. Yalnız teslim alınan veya kısmi kabul edilen truck'lar seçilir.
2. Her truck'ın irsaliye metrajı toplanır.
3. Planlanan metraj çıkarılarak fark hesaplanır.

Böylece truck satırı ile toplamın birbirinden kopması mümkün olmaz.

## Gerçek kod: dosya önce, row sonra

Kanıt byte'ı önce staging'e yazılıp atomik finalize edilir:

```dart
await temporary.writeAsBytes(bytes, flush: true);
await temporary.rename(destination.path);
return StagedConcreteAttachment(
  relativePath: relativePath,
  mimeType: mime,
  byteSize: bytes.length,
  sha256Value: sha256.convert(bytes).toString(),
);
```

- `flush: true`, byte'ların işletim sistemi buffer'ında beklememesini ister.
- `rename`, yarım dosyayı final ad altında göstermeden finalize eder.
- DB yalnız uygulama köküne göre relative path görür.
- SHA-256 aynı binary duplicate ve sonradan bozulma kontrolünü sağlar.

DB transaction başarısız olursa application service şunu yapar:

```dart
try {
  return await writeAttachmentRowAndEvent();
} on Object {
  await attachmentStore.cleanup(staged.relativePath);
  rethrow;
}
```

Yani event insert dahi hata verse orphan final dosya bırakılmaz. File staging
hata verirse transaction henüz başlamadığı için partial row oluşmaz.

## Gerçek kod: package adımı ve reminder birlikte

Takip tamamlandığında aynı transaction içinde:

```text
concrete_follow_up_items.status = completed
        ↓
follow_up_items.status = completed
        ↓
follow_up_events += completed
        ↓
reminder_notification_bindings = cancelled
        ↓
concrete_pour_events += follow_up.linked
```

Bu zincir web'de beş ayrı mutation değildir. Tek SQLite transaction rollback
olursa bütün satırlar eski halinde kalır. Reminder ekranındaki bağımsız snooze
ise source Beton package revision'ını değiştirmez.

## Migration neden table rebuild kullandı?

SQLite mevcut CHECK/composite foreign key sözleşmesini güvenilir biçimde
genişletmek için çoğu zaman tabloyu yeniden kurmayı gerektirir:

```sql
ALTER TABLE follow_up_items RENAME TO follow_up_items_v4;
CREATE TABLE follow_up_items (
  ...,
  concrete_pour_id TEXT,
  FOREIGN KEY (concrete_pour_id, project_id)
    REFERENCES concrete_pours(id, project_id),
  CHECK (
    (observation_id IS NOT NULL)
    + (attendance_day_id IS NOT NULL)
    + (concrete_pour_id IS NOT NULL) <= 1
  )
);
INSERT INTO follow_up_items (..., concrete_pour_id)
SELECT ..., NULL FROM follow_up_items_v4;
```

Eski satırlar concrete source taşımadığı için `NULL` ile birebir korunur. Bütün
adımlar migration transaction'ındadır. Bir SQL hata verirse v4 tablo/veri ve
`user_version` birlikte geri gelir.

## Test kodu neyi doğruluyor?

Örnek rollback testi:

```dart
final failing = SqliteConcreteApplication(
  ...,
  beforeConcreteEventInsert: (_) async {
    throw StateError('intentional event failure');
  },
);
await expectLater(failing.createPour(command), throwsStateError);
expect(await count('concrete_pours'), 0);
expect(await count('follow_up_items'), 0);
expect(await count('concrete_pour_events'), 0);
```

Hook event yazımından hemen önce kontrollü hata üretir. Beklenti yalnız exception
değildir; package, reminder ve event sayılarının üçünün de sıfır olması atomik
rollback kanıtıdır.

Attachment testi gerçek dosyayı değiştirip diagnostic'i de kontrol eder:

```dart
expect(await store.inspect(path, hash), ConcreteAttachmentIntegrity.ok);
await file.writeAsBytes(tamperedBytes);
expect(
  await store.inspect(path, hash),
  ConcreteAttachmentIntegrity.tampered,
);
```

Widget testi 320 px viewport'ta overflow olmadığını, form validation'ından sonra
girilen kodun kaldığını ve iki hızlı submit'in tek create çağrısı yaptığını
doğrular.

## Teknik karar tablosu

| Karar | Neden | Kaçınılan risk |
| --- | --- | --- |
| Beton-specific aggregate | Release 0.1 sahada test edilebilir dar kapsam | Erken genel PackageTemplate karmaşıklığı |
| UTC storage / İstanbul sunumu | Tek gerçek an, doğru saha duvar saati | Naive zaman ve gün kayması |
| Truck'tan türetilen total | Tek source-of-truth | Elle toplam/truck ayrışması |
| Composite source FK | Package ve project birlikte doğrulanır | Cross-project reminder linki |
| SHA-256 + relative path | Integrity ve taşınabilir mantıksal ad | Absolute path sızıntısı, sessiz bozulma |
| File finalize sonra DB row | Dosya gerçekten hazır olmadan başarı yok | Kırık attachment row |
| Row + event + reminder tek transaction | Ya hep ya hiç | Yarım bağlı takip/reminder |
| Explicit exception | Kullanıcı kararı görünür kalır | Otomatik teknik kabul/red |

## Kod çalışma akışı

```text
Kullanıcı komutu
  → UUID/canonical UTC/metraj/source validation
  → serialized SQLite açılışı
  → BEGIN TRANSACTION
  → expected revision doğrulaması
  → child row mutation
  → aggregate revision + 1
  → monoton append-only event
  → reminder/binding orchestration (gerekiyorsa)
  → COMMIT
  → platform notification reconciliation (safe retry)
  → güncel detail read-model
```

## “Şunu şöyle yaptık ki...”

Şunu şöyle yaptık ki: beton dökümünün checklist, truck, numune, kanıt ve reminder
parçaları ayrı tablolarda okunabilir kalsın; fakat kullanıcı tek bir adım
tamamladığında transaction sınırı bu parçaların yarım veya birbiriyle çelişkili
kalmasına izin vermesin. Dosya sistemini SQLite transaction'ına sokamadığımız
için önce güvenli atomik dosya finalize, sonra DB transaction ve hata halinde
telafi edici orphan cleanup kullandık. Böylece permission, plugin, file veya event
hatası kullanıcıya sahte başarı göstermez ve gerçek kayıt sessizce kaybolmaz.
