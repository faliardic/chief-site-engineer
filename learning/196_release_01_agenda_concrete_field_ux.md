# Issue #196 Öğrenme Notu — Ajanda Arşivi ve Beton Belge Akışı

## Bu geliştirmede ne öğrendik?

Bir mobil ekrana `Sil`, fotoğraf ve PDF düğmesi eklemek yüzeyde küçük görünür.
Fakat çevrimdışı çalışan bir saha uygulamasında her düğmenin SQLite, dosya
sistemi, append-only geçmiş, optimistic revision ve backup/restore karşılığı
olmalıdır. UI başarılı görünüp altta yarım dosya veya bağlantısız row bırakırsa
ürün veri güvenliği sözleşmesini ihlal eder.

Bu dilimde üç temel fikir birlikte kullanıldı:

1. Kullanıcı açısından silme, fiziksel `DELETE` değil geri alınabilir archive'dır.
2. Dosya ve database tek transaction motorunu paylaşamadığı için staging,
   finalize ve telafi edici cleanup açıkça tasarlanır.
3. Ekran ve PDF metrajı ayrı hesaplar yapmaz; aynı domain `ConcreteMetrics`
   değerlerini okur.

## Gerçek kod: schema 6 → 7 ve nullable irsaliye

```dart
await transaction.execute('''
  CREATE TABLE agenda_log_attachments (
    id TEXT PRIMARY KEY,
    observation_id TEXT NOT NULL,
    project_id TEXT NOT NULL,
    attachment_type TEXT NOT NULL CHECK (attachment_type = 'site_photo'),
    mime_type TEXT NOT NULL CHECK (mime_type IN ('image/jpeg', 'image/png')),
    byte_size INTEGER NOT NULL CHECK (byte_size > 0),
    sha256 TEXT NOT NULL CHECK (length(sha256) = 64),
    relative_path TEXT NOT NULL UNIQUE,
    revision INTEGER NOT NULL DEFAULT 1 CHECK (revision >= 1),
    archived_at TEXT,
    FOREIGN KEY (observation_id, project_id)
      REFERENCES field_observations(id, project_id)
  )
''');
```

Satır satır açıklama:

1. `id`, attachment'ın bağımsız ve değişmez kimliğidir.
2. `observation_id + project_id`, fotoğrafın başka projedeki bir loga yanlış
   bağlanmasını composite foreign key ile engeller.
3. `attachment_type` bu dilimde yalnız `site_photo` kabul eder; belirsiz dosya
   türleri sisteme sessizce girmez.
4. MIME uzantıdan değil içerik sniffing sonucundan gelir ve yalnız JPEG/PNG'dir.
5. `byte_size + sha256`, restart/restore sonrasında dosyayı aynı kayıtla
   doğrulamak için kullanılır.
6. `relative_path`, cihazın absolute kökünü backup paketine sızdırmaz.
7. `revision + archived_at`, optimistic archive yaşam döngüsünü fiziksel silme
   olmadan kurar.
8. Composite FK, observation ve project çiftinin kaynak logla exact eşleşmesini
   database seviyesinde de zorunlu kılar.

İrsaliye numarasındaki eski `UNIQUE(concrete_pour_id,
delivery_note_number)` otomatik index'i yerinde değiştirilemediği için truck ve
çocuk FK grafiği aynı migration içinde yeniden kuruldu. Yeni kural şudur:

```sql
CREATE UNIQUE INDEX ux_concrete_trucks_delivery_note
ON concrete_trucks(concrete_pour_id, delivery_note_number)
WHERE delivery_note_number IS NOT NULL
  AND length(trim(delivery_note_number)) > 0;
```

Partial unique index yalnız dolu irsaliyeleri karşılaştırır. İki mikserin `NULL`
değeri çakışmaz; `IRS-10` gibi gerçek değer aynı dökümde ikinci kez kullanılamaz.
Tablo rebuild sırasında sample, follow-up ve attachment satırları eski truck
kimliklerine tekrar bağlanır. Migration'ın ortasında hata olursa SQLite bütün
rename/create/copy adımlarını rollback eder ve `user_version` 6 kalır.

## Gerçek kod: Ajanda edit, stale ve no-op

```dart
final current = await _requireAgendaLog(transaction, command.id);
_requireRevision(current.revision, command.expectedRevision);
final changed = current.projectId != command.projectId ||
    current.observedAt != observedAt ||
    current.category != command.category ||
    current.description != description ||
    current.location != location ||
    current.notes != notes;
if (!changed) return current;
await transaction.update(
  'field_observations',
  {
    'description': description,
    'revision': current.revision + 1,
    'updated_at': timestamp,
  },
  where: 'id = ? AND revision = ?',
  whereArgs: [command.id, command.expectedRevision],
);
await _insertObservationEvent(
  transaction,
  eventType: 'agenda_log.updated',
  payload: {'before': before, 'after': after},
);
```

- `_requireAgendaLog`, exact source row'u mutation başlamadan okur.
- `_requireRevision`, ekrandaki eski formun yeni veriyi ezmesini önler.
- `changed`, kullanıcı hiçbir alanı değiştirmediyse erken döner. Bu nedenle
  revision ve event sayısı gereksiz artmaz.
- SQL `WHERE id AND revision`, doğrulama ile update arasındaki olası yarışı da
  kapatır.
- Mutable row ile `agenda_log.updated` aynı transaction nesnesine yazılır.
- `before/after`, değişikliğin ne olduğunu gösterir; absolute path veya dosya
  byte'ı gibi hassas içerik taşımaz.

Arşiv de aynı kalıbı kullanır. Fark yalnız `archived_at` değeridir. `Sil`
komutu `DELETE FROM field_observations` çalıştırmaz. Database trigger ham SQL
yoluyla fiziksel delete denenirse de işlemi abort eder. Restore, aynı row'un
`archived_at` alanını temizleyip `agenda_log.restored` event'i ekler.

## Gerçek kod: fotoğrafın dosya + DB güvenlik sırası

```dart
final staged = await attachmentStore.stage(command.photo);
try {
  return await database.transaction((tx) async {
    final current = await _requireAgendaLog(tx, command.logId);
    _requireRevision(current.revision, command.expectedRevision);
    await tx.insert('agenda_log_attachments', staged.toRow(command));
    await _advanceAgendaLog(tx, current, timestamp);
    await _insertObservationEvent(
      tx,
      eventType: 'agenda_log.photo_attached',
      payload: {'attachment_id': command.photoId, 'sha256': staged.sha256},
    );
    return _loadAgendaLogDetail(tx, command.logId);
  });
} on Object {
  await attachmentStore.cleanup(staged.relativePath);
  rethrow;
}
```

Akışın nedeni şöyledir:

1. `stage`, içerik imzasını ve maksimum boyutu kontrol eder.
2. Staging dosyası tekrar okunur; hesaplanan SHA-256 ilk hesapla aynı olmalıdır.
3. Dosya yalnız doğrulandıktan sonra güvenli relative final yola atomik rename
   edilir.
4. Transaction exact log/revision'ı tekrar doğrular.
5. Attachment row, log revision ve event birlikte commit olur.
6. Herhangi bir DB/event hatası `catch` dalına düşer ve orphan final dosyayı
   temizler.

Dosya sistemi SQLite transaction'ına doğrudan katılamaz. Bu nedenle cleanup bir
“telafi edici işlem”dir. Başarılı archive ise cleanup çağırmaz; row ve fiziksel
byte korunur. Böylece kullanıcı fotoğrafı geri alınabilir biçimde saklar ve
backup arşivlenmiş kaydı da taşıyabilir.

Log oluşturma formundaki fotoğraflar command içinde pending draft olarak durur.
Log create validation başarısızsa application store'a hiç yazılmaz. Kamera izni
reddedilirse picker başlamaz, açıklama/tarih/not controller'ları korunur ve
partial dosya oluşmaz.

## Gerçek kod: canlı hedef, kalan ve aşılan hesabı

```dart
double get remainingM3 => plannedVolumeM3 - actualDeliveredM3;
bool get isTargetExceeded => remainingM3 < 0;
double get excessM3 => isTargetExceeded ? -remainingM3 : 0;

final targetDifference = metrics.isTargetExceeded
    ? 'Aşılan: ${formatM3(metrics.excessM3)} m³'
    : 'Kalan: ${formatM3(metrics.remainingM3)} m³';
```

`actualDeliveredM3`, ayrı elle yazılan kolon değildir. SQL, aktif truck
satırlarından sonucu `received` veya `partial` olan hacimleri toplar. Hedef 100,
dökülen 102,5 ise `remainingM3 = -2,5` olur. Negatif değeri sıfıra sıkıştırmak
bilgiyi kaybettireceği için UI `Aşılan: 2,50 m³` gösterir.

`formatM3`, iki ondalık üretip noktayı Türkçe virgüle çevirir. Ekran ve PDF aynı
metrics ile aynı formatter'ı kullandığı için iki yerde farklı toplam oluşmaz.
Hedef update command'i dökülenden küçük değere izin verir fakat UI önce açık
uyarı gösterir. Update yalnız pour hedefini değiştirir; truck hacimleri update
listesine dahil edilmez.

## Gerçek kod: güvenli toplu tamamlama

```dart
const sourceFieldItems = {
  'inspection_notified',
  'laboratory_appointment',
};
final manualChecks = checks.where(
  (item) => item.status == ConcreteCheckStatus.pending &&
      !sourceFieldItems.contains(item.itemKey),
);
for (final item in manualChecks) {
  await tx.update('concrete_check_items', completedValues(item));
  await _insertConcreteEvent(
    tx,
    id: deterministicBulkEventId(command.eventId, item.id),
    eventType: 'check.bulk_completed',
  );
}
```

Laboratuvar randevusu ve yapı denetim bildirimi bir checkbox değil, Beton paket
alanından türetilen görevlerdir. Bunları toplu düğmeyle “tamamlandı” yapmak
source-of-truth ile çelişirdi. Bu nedenle allowlist yerine açık exclusion set'i
vardır. Manual check/follow-up, linked reminder kapanışı ve pour revision tek
transaction'dadır. Bir item event'i başarısızsa hiçbir item yarım tamamlanmaz.
Event kimliği command + item kimliğinden deterministik olduğu için aynı retry
duplicate geçmiş üretmez.

## Gerçek kod: PDF başarı sınırı

```dart
final bytes = await exportGateway.renderPdf(detail, timestamp);
if (!ConcretePackageReportFormatter.isStructurallyValidPdf(bytes)) {
  throw const AgendaValidationFailure('PDF raporu doğrulanamadı.');
}
final absolutePath = await exportGateway.stage(fileName, bytes);
try {
  await exportGateway.verify(absolutePath);
  if (share) await exportGateway.share(absolutePath, summary);
  if (save && !await exportGateway.save(fileName, absolutePath)) {
    await exportGateway.cleanup(absolutePath);
    return cancelledResult;
  }
  await insertReportExportedEvent();
  await exportGateway.cleanup(absolutePath);
  return completedResult;
} on Object {
  await exportGateway.cleanup(absolutePath);
  rethrow;
}
```

Satır satır:

1. Embedded Roboto fontlarıyla Türkçe karakterleri taşıyan PDF byte'ları render
   edilir.
2. Header `%PDF-` ve final `%%EOF` yapısı staging öncesinde kontrol edilir.
3. Dosya app-private staging alanına yazılır ve diskten tekrar doğrulanır.
4. Share ile save aynı çağrıda yürütülmez; kullanıcı niyeti tek ve açıktır.
5. Save picker `null` döndürürse kullanıcı iptal etmiştir; bu başarı değildir.
6. `report.exported`, ancak platform share/save başarılı olduktan sonra yazılır.
7. İptal veya exception her dalda staged dosyayı temizler.

Android'de `FilePicker.saveFile(bytes: ...)` Storage Access Framework benzeri
kullanıcı kontrollü hedef seçimidir. Uygulama broad storage izni istemez ve
seçilen hedefin absolute yolunu PDF içeriğine yazmaz.

## Test kodu neyi doğruluyor?

```dart
test('log edit no-op stale rollback archive restore and reminder link are safe',
    () async {
  final edited = await agenda.updateAgendaLog(validEdit);
  expect(edited.revision, 2);
  expect((await agenda.updateAgendaLog(noOp)).revision, 2);
  await expectLater(agenda.updateAgendaLog(stale), throwsValidationFailure);
  final archived = await agenda.mutateAgendaLogArchive(archiveCommand);
  expect(archived.log.archivedAt, isNotNull);
  expect(archived.reminders.single.id, originalReminderId);
});
```

Bu test yalnız buton yazısını kontrol etmez. Revision'ın artmasını, no-op'ta
sabit kalmasını, stale komutun reddini, event rollback'ini, arşiv filtresini,
restore'u ve bağlı reminder kimliği/durumunun değişmemesini birlikte doğrular.

Fotoğraf testinde gerçek temporary root kullanılır: create ile fotoğrafın aynı
başarı sınırına girmesi, duplicate hash, event failure cleanup, archive sonrası
fiziksel byte'ın kalması, restart okuması ve byte değiştirildiğinde tamper tanısı
çalıştırılır. Widget testi kamera izni reddinde form metnini karşılaştırır.

Migration testi gerçek schema 6 fixture'ı açar; log/reminder/attendance/sicil/
Beton/truck/child/event satırlarını v7 sonrası exact karşılaştırır ve
`PRAGMA foreign_key_check` sonucunu boş bekler. Ayrı test v7 adımında enjekte
edilen hata sonrası `user_version = 6` ve eski satırların değişmediğini kanıtlar.

Beton testleri şunları ayrıca yürütür:

- iki boş irsaliye, sonradan irsaliye ekleme ve dolu duplicate reddi;
- truck edit/no-op/stale/restart ve before/after event;
- aynı truck'a birden fazla `delivery_note_scan`, legacy scan ve hash tamper;
- hedef azaltma/artırma, kalan/aşılan ve truck satırlarının korunması;
- bulk transaction failure rollback ve idempotent retry;
- PDF yapısı, Türkçe domain girdisi, share/save ayrı başarıları, save cancel,
  plugin/stage failure cleanup ve başarısızlıkta event yokluğu;
- schema `1`–`7` backup staging migration ve arşivlenmiş Ajanda fotoğrafının
  exact byte/hash/relative-path round-trip'i.

## Teknik karar tablosu

| Karar | Seçilen çözüm | Neden |
| --- | --- | --- |
| Ajanda `Sil` | `archived_at` + restore | FK, reminder ve geçmiş kaybolmaz |
| Fotoğraf bağı | observation + project composite FK | Cross-project yanlış bağ fail-closed olur |
| Dosya yazma | sniff → stage → hash → atomic finalize | Partial veya sahte uzantılı dosya kalmaz |
| DB hatası | telafi edici dosya cleanup | SQLite ve filesystem birlikte rollback olamaz |
| İrsaliye unique | nullable kolon + partial unique index | Boşlar çatışmaz, dolu değer korunur |
| Legacy kanıt | eski ve yeni enum birlikte okunur | Mevcut saha verisi kaybolmaz |
| Metraj | truck'lardan türetilen read-model | İkinci, drift eden toplam kolonu oluşmaz |
| Aşım | negatif kalanı `Aşılan` göster | Gerçek fazla döküm gizlenmez |
| Bulk | manual item'lar tek transaction | Source-field görevleri sahte kapanmaz |
| PDF font | repository asset'i açık lisanslı Roboto | Offline Türkçe ve deterministik render |
| Telefona kaydet | kullanıcı kontrollü belge picker | Broad storage izni gerekmez |
| Backup | format 1, schema allowlist 1–7 | Paket formatı gereksiz değişmez |

## Kod çalışma akışı

```text
Uygulama açılışı
  -> SQLite user_version oku
  -> v6 ise tek transaction'da agenda attachment + truck graph rebuild
  -> integrity/FK/schema history doğrula
  -> notification reconciliation
  -> active Ajanda ve Beton read-model'lerini göster

Ajanda fotoğraf ekleme
  -> capability/permission
  -> kamera veya sistem picker
  -> MIME sniff + boyut
  -> staging write + SHA-256 verify + atomic finalize
  -> log/revision/source validation
  -> photo row + log revision + event tek transaction
  -> hata: orphan dosya cleanup, form/log korunur
  -> başarı: thumbnail -> zoom/pan viewer

Beton mikser ve belge
  -> truck kartına dokun
  -> nullable irsaliye + zaman/hacim/not düzenle
  -> expected truck + pour revision
  -> truck row + truck.updated event tek transaction
  -> irsaliye tara -> kullanıcı onayı -> exact truck attachment
  -> detail yeniden yükle -> canlı dökülen/kalan/aşılan

PDF
  -> exact pour revision/read-model
  -> aynı metrics ile PDF render
  -> structure verify -> stage -> disk verify
  -> yalnız share veya yalnız save
  -> başarıdan sonra report.exported
  -> staging cleanup
  -> iptal/hata: event yok + cleanup
```

## Şunu şöyle yaptık ki...

- Ajanda `Sil` eylemini archive yaptık ki kullanıcı kaydı listeden kaldırırken
  reminder, foreign key ve event geçmişi geri döndürülemez biçimde kaybolmasın.
- Stale kontrolünü hem uygulama doğrulamasında hem revision'lı SQL update'te
  yaptık ki açık kalmış eski form yeni saha bilgisini ezmesin.
- Fotoğrafı içerikten tanıyıp hash doğruladıktan sonra finalize ettik ki sahte
  uzantı ve yarım byte dosyası source-of-truth olmasın.
- DB/event hatasında finalize dosyasını temizledik ki bağlantısız orphan kanıt
  kullanıcı depolamasında kalmasın.
- Arşivlenen fotoğrafın byte'ını silmedik ki restore ve backup geri alınabilirlik
  sözleşmesini gerçekten korusun.
- İrsaliye numarasını nullable ve partial unique yaptık ki saha görevlisi mikseri
  numara gelmeden kaydedebilsin ama gerçek duplicate irsaliye engellensin.
- Legacy ve yeni irsaliye kanıt türünü birlikte saydık ki v6 kayıtları upgrade
  sonrasında “eksik kanıt” görünmesin.
- Metrajı aktif mikserlerden türettik ki ekran ile PDF farklı source-of-truth
  üretmesin.
- Negatif kalanı sıfıra clamp etmedik ki hedef aşımı açıkça görülsün.
- Source-field Beton görevlerini bulk dışında tuttuk ki doldurulmamış laboratuvar
  veya yapı denetim alanı sahte biçimde tamamlanmasın.
- PDF event'ini share/save sonrasına koyduk ki kullanıcı iptalini veya plugin
  hatasını başarılı export gibi kaydetmeyelim.
- SAF/belge picker kullandık ki broad depolama izni eklemeden kullanıcı hedefi
  kendisi seçsin.
- Backup formatını artırmayıp schema allowlist'ini 7'ye çıkardık ki eski paketler
  taşınabilir kalırken yeni fotoğraf, scan, archive ve event geçmişi de korunsun.
