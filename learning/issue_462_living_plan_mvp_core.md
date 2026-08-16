# Issue 462 — Living 7-Day Plan MVP Core

## 1. Bu adımda ne yaptık?

Immutable reference schedule'ın üstüne, şantiye şefinin yakın dönem kararını
tutan ayrı bir Living Plan çekirdeği ekledik. Yeni katman şunları saklar:

- hangi stable project activity instance seçildi;
- seçimin hangi exact reference snapshot'tan geldiği;
- kullanıcının planladığı gün;
- `PLANNED / STARTED / COMPLETED / DEFERRED` durumu;
- kısa not;
- her gerçek değişikliğin append-only event geçmişi.

Schema `14 → 15` oldu; backup formatı `1` kaldı. Bu adım UI, APK veya cihaz
kabulü değildir.

## 2. Neden bunu yaptık?

Reference schedule teknik öneridir: aktivitenin takvimde nerede başlamasının
mantıklı olduğunu gösterir ve geçmiş snapshot'ları immutable tutar. Şantiye
şefinin “bu işi salı günü sahaya alıyorum, ekip başladı, sonra perşembeye
erteledim” kararı ise başka bir gerçektir.

Bu iki gerçeği aynı satırda tutarsak kullanıcı kararı teknik schedule'ı sessizce
yeniden yazabilir. Ayrı Living Plan katmanı sayesinde:

- teknik önerinin provenance/history bilgisi kaybolmaz;
- saha kararı değişebilir ve event geçmişiyle geri izlenebilir;
- yeni schedule snapshot üretildiğinde eski saha kararı başka origin'e
  bağlanmaz;
- ilk UI Slice'ı hazır typed read/mutation sınırlarını kullanabilir.

Şantiye benzetmesi: reference schedule, planlama ofisinin revizyon numaralı iş
programıdır. Living Plan ise şantiye şefinin önündeki yedi günlük koordinasyon
tahtasıdır. Tahtadaki karar değişebilir; eski iş programının paftası değiştirilmez.

## 3. Hangi dosyalara dokunduk?

```text
mobile/lib/storage/app_database.dart
mobile/lib/domain/construction_living_plan_models.dart
mobile/lib/application/construction_living_plan_application.dart
mobile/lib/application/construction_schedule_snapshot_repository.dart
mobile/test/app_database_test.dart
mobile/test/construction_living_plan_application_test.dart
mobile/test/mobile_backup_application_test.dart
mobile/test/platform_notification_configuration_test.dart
CHANGELOG.md
docs/project_decisions.md
learning/issue_462_living_plan_mvp_core.md
.cse/tasks/462_task.md
.cse/results/462_result.md
```

- `app_database.dart`: additive schema-15 tabloları, index'leri ve trigger'ları.
- `construction_living_plan_models.dart`: typed status/event/item/candidate ve
  command modelleri.
- `construction_living_plan_application.dart`: trusted read, create, lifecycle,
  idempotency ve seven-day query akışları.
- `construction_schedule_snapshot_repository.dart`: full snapshot
  materialize etmeden metadata/profile ve dar window satırlarını döndüren helper.
- Test dosyaları: migration, reference read, mutation, rollback,
  snapshot-replacement ve gerçek backup/restore senaryoları.

## 4. Composite reference bağı nasıl çalışıyor?

Schema-15 migration'ın temel bağı şöyledir:

```sql
CREATE UNIQUE INDEX project_schedule_snapshot_activities_living_plan_ref
ON project_schedule_snapshot_activities(
  snapshot_id, project_id, instance_id, activity_id
);

FOREIGN KEY (
  reference_snapshot_id,
  project_id,
  activity_instance_id,
  activity_id
) REFERENCES project_schedule_snapshot_activities(
  snapshot_id,
  project_id,
  instance_id,
  activity_id
)
```

Satır satır anlamı:

1. Parent index dört değerin birlikte tek bir schedule activity satırını
   göstermesini sağlar.
2. Living Plan satırı yalnız snapshot ID taşımaz; project, instance ve activity
   ID de aynı parent satırında bulunmalıdır.
3. Başka projenin geçerli activity ID'si kullanılsa bile composite çift
   eşleşmez ve insert reddedilir.
4. Schedule snapshot activity zaten update/delete trigger'larıyla immutable'dır.
   Bu yüzden origin daha sonra superseded olsa da kaybolmaz veya değişmez.

Şunu şöyle yaptık ki Living Plan item'ı gerçek ve aynı projeye ait persisted
schedule activity'ye bağlı olsun: dört kolonlu composite foreign key kullandık.

## 5. Projection ile event neden tek transaction içinde?

Mutation'ın sadeleştirilmiş gerçek akışı şöyledir:

```dart
final updated = await transaction.update(
  'project_living_plan_items',
  {
    'planned_date': formatCanonicalConstructionDate(resulting.plannedDate),
    'status': resulting.status.storageValue,
    'note': resulting.note,
    'revision': resulting.revision,
    'updated_at': occurredAt,
    'status_changed_at': CseTimeCodec.encodeUtc(statusChanged),
  },
  where: 'id = ? AND revision = ?',
  whereArgs: [itemId, expectedRevision],
);

await _insertEvent(
  transaction,
  eventId: eventId,
  item: resulting,
  eventType: eventType,
  occurredAt: occurredAt,
  payload: payload,
);
```

Burada:

- `WHERE ... revision = ?`, caller'ın okuduğu revision hâlâ güncelse update
  yapar.
- Result revision her gerçek değişiklikte tam bir artar.
- Event aynı `transaction` nesnesiyle insert edilir.
- Event insert hata verirse transaction rollback olur; projection update de
  kalmaz.
- Database trigger'ı event sequence'in o andaki item revision'ına ve event
  zamanının item `updated_at` değerine eşit olduğunu ayrıca kontrol eder.

Şunu şöyle yaptık ki “durum değişti ama geçmiş yazılamadı” veya “event var ama
güncel satır değişmedi” gibi yarım gerçek oluşmasın: projection ve eventi tek
SQLite transaction'a bağladık.

## 6. Exact event replay nasıl idempotent kalıyor?

Her event payload'ı üç canonical bölüm taşır:

```json
{
  "change": {
    "previous_status": "PLANNED",
    "status": "STARTED"
  },
  "intent": {
    "expected_revision": 1,
    "operation": "STARTED"
  },
  "result": {
    "note": null,
    "planned_date": "2026-09-05",
    "revision": 2,
    "status": "STARTED",
    "status_changed_at": "2026-08-16T09:00:01Z",
    "updated_at": "2026-08-16T09:00:01Z"
  }
}
```

- `intent`, caller'ın yapmak istediği exact operation'ı temsil eder.
- `change`, audit için önceki/yeni değerleri açıklar.
- `result`, o event üretildiği andaki projection sonucunu saklar.

Aynı event ID tekrar gelirse application önce stored `intent` ile yeni komutun
canonical intent'ini karşılaştırır. Item/type/intent aynıysa yeni revision/event
üretmez. Daha sonraki mutation'lar yapılmış olsa bile stored `result` ile o
eventin ürettiği sonuç yeniden kurulabilir. Aynı ID farklı intent için
`living_plan_event_id_conflict` olur.

## 7. Trusted suggestion ve search yolları neden farklı?

Yedi günlük ekran yolu yalnız tarih penceresine değen schedule satırlarını ister:

```dart
final window = await snapshotRepository.loadCurrentActivityWindow(
  projectId: projectId,
  windowStart: windowStart,
  windowEnd: windowEnd,
);
```

Bu helper aynı database transaction içinde:

1. projenin sole current snapshot metadata/profile satırını okur;
2. stored activity count bütünlüğünü kontrol eder;
3. yalnız `start_date <= windowEnd AND finish_date >= windowStart` satırlarını
   trusted row parser'dan geçirir.

Explicit catalog search ise kullanıcının binlerce immutable activity içinde
arama yaptığı ayrı bir eylemdir; current full snapshot'ı yüklemesine bu ilk
core'da izin verilir.

Her iki yol schedule satırını typed graph instance ve corpus template ile
birleştirir. Project/corpus version/instance/activity kimliklerinden biri
uyuşmazsa sonuç tahmin edilmez. Block/floor/basement gibi context, instance ID
metnini parçalayarak değil `ConstructionProjectActivityContext` nesnesinden
alınır.

## 8. Seven-day query hangi kayıtları getiriyor?

Pencere `windowStart ... windowStart + 6 gün` inclusive'dir:

```text
open ve planned_date < windowStart      -> dahil, isOverdue = true
open ve planned_date <= windowEnd       -> dahil
completed ve tarih pencere içinde       -> dahil
open ve tarih windowEnd sonrasında      -> hariç
completed ve tarih pencere dışında      -> hariç
```

Sıralama önce overdue open, sonra pencere içi open, sonra pencere içi completed;
devamında planned date, status priority, activity name ve item ID'dir. Böylece
dün bitmemiş iş bugünkü tahtadan kaybolmaz.

Origin snapshot marker salt-okunurdur. Snapshot B, A'yı supersede ettiğinde A
origin'li item yine A'yı gösterir; query yalnız `originSnapshotIsCurrent=false`
üretir.

## 9. Test kodu üzerinden açıklama

Rollback testinin özü şöyledir:

```dart
final failingMutation = ConstructionLivingPlanApplication(
  database: database,
  snapshotRepository: snapshotRepository,
  clock: () => now,
  graphLoader: (_) async => scenario.graph,
  corpusLoader: () async => scenario.corpus,
  beforeEventInsert: () async => throw StateError('injected event failure'),
);

await expectLater(
  failingMutation.startLivingPlanItem(command),
  throwsA(isA<StateError>()),
);

expect((await application.loadLivingPlanItem(item.id))?.revision, 1);
expect(await application.listLivingPlanEventHistory(item.id), hasLength(1));
```

Test, projection update ile event insert arasına bilinçli hata koyar. Sonra item
revision'ının ve event sayısının değişmediğini doğrular. Bu yalnız exception
atıldığını değil, transaction'ın iki tarafı birlikte geri aldığını kanıtlar.

Diğer focused testler şunları executable olarak kapsar:

- fresh schema 15 ve additive 14→15;
- canonical date/timestamp/note/status ve composite FK;
- Turkish ad/alias search, deterministic ordering, limit ve existing marker;
- stale snapshot race ve regenerated snapshot duplicate'i;
- start/direct complete/defer/complete/reopen/note matrixi;
- stale revision, exact replay, conflict, no-op ve backward clock;
- overdue/open/completed seven-day sınıflandırması;
- schema-15 gerçek backup round-trip ve format-1 schema-14 restore/migrate.

## 10. Kodun çalışma akışı

Create akışı:

1. Komut UUID, project/snapshot/instance, canonical planned date ve notu
   doğrulanır.
2. Aynı event ID daha önce başarıyla işlendi mi diye idempotency sınırı okunur.
3. Current trusted full snapshot, graph ve corpus ile exact candidate çözülür.
4. SQLite transaction başlar.
5. Expected snapshot'ın hâlâ sole current snapshot olduğu tekrar doğrulanır.
6. Exact persisted schedule activity composite kimliği tekrar doğrulanır.
7. Project/instance duplicate'i kontrol edilir.
8. `PLANNED`, revision `1` projection insert edilir.
9. `CREATED`, sequence `1` event aynı transaction'da insert edilir.
10. Stored projection/history tekrar okunup doğrulandıktan sonra sonuç döner.

Lifecycle akışı:

1. Event replay check stale revision kontrolünden önce yapılır.
2. Yeni event ise current item ve expected revision karşılaştırılır.
3. No-op ise yazmadan current item döner.
4. Transition/date/note ve clock kontrol edilir.
5. Projection compare-and-update ile revision bir artırılır.
6. Canonical event insert edilir.
7. Herhangi bir hata iki yazımı birlikte rollback eder.

## 11. Yeni öğrenilen yazılım kavramları

### Composite foreign key

Bir child satırın parent'a tek kolonla değil, birkaç kolonun birlikte oluşturduğu
exact kimlikle bağlanmasıdır.

Bu projedeki karşılığı: Living Plan origin'i aynı snapshot/project/instance/
activity dörtlüsünü göstermek zorundadır.

Şantiye benzetmesi: yalnız pafta numarasını değil, proje + revizyon + detay +
poz numarasını birlikte yazarak doğru çizime referans vermek gibidir.

### Projection

Event geçmişinden bağımsız olarak hızlı okunabilen güncel durum satırıdır.

Bu projedeki karşılığı: `project_living_plan_items` item'ın güncel planned date,
status ve note değerlerini taşır; geçmiş events tablosundadır.

### Optimistic revision

Kayıt okunurken görülen revision'ın update anında hâlâ aynı olmasını isteyen
yarış korumasıdır.

Bu projedeki karşılığı: `WHERE id = ? AND revision = ?` yalnız stale olmayan
komutu uygular.

Bu kavramlar repository'nin mevcut kalıcı sözlüğünde kullanılan genel
persistence/event terimleridir; Issue #462 exact allowlist'i dışında yeni bir
kalıcı glossary entry gerektiren yeni ürün terimi oluşturulmadı.

## 12. “Şunu şöyle yaptık ki...” teknik karar tablosu

| Şunu yaptık | Böyle yaptık | Çünkü | Böylece |
| --- | --- | --- | --- |
| Saha kararını schedule'dan ayırdık | Ayrı projection/event tabloları kurduk | Teknik öneri kullanıcı kararıyla rewrite edilmemeli | Provenance ve saha kararı birlikte korunur |
| Exact origin bağı kurduk | Dört kolonlu composite FK kullandık | Tek snapshot veya activity ID aynı proje/instance doğruluğunu kanıtlamaz | Cross-project/mismatched origin insert fail olur |
| Mutation'ı atomik yaptık | Projection update ve event insert'i tek transaction'a aldık | Yarım audit/projection kabul edilemez | Hata iki tarafı birlikte rollback eder |
| Retry'ı güvenli yaptık | Event ID + canonical intent/result sakladık | Mobil retry ikinci revision üretmemeli | Exact replay idempotent, farklı intent conflict olur |
| Overdue işi görünür tuttuk | Open `planned_date <= windowEnd` sorguladık | Bitmemiş iş pencere başlangıcından eski olabilir | Geciken iş yedi günlük tahtadan kaybolmaz |
| Origin'i değiştirmedik | Superseded marker yalnız read-model oldu | Yeni schedule eski saha kararını sahiplenmemeli | Silent rebind oluşmaz |
| Backup formatını sabit tuttuk | Tam SQLite image ve additive migration kullandık | Yeni tablo envelope değişikliği gerektirmiyor | Format-1 backward compatibility korunur |

## 13. Bu adımda bilinçli olarak ne yapmadık?

- Widget, page, route, navigation veya bootstrap wiring eklemedik.
- APK/AAB, cihaz, notification, reboot, release/store gate çalıştırmadık.
- Reference schedule activity/date/duration satırlarını mutation ile
  değiştirmedik.
- Actual start/finish, percent complete, quantity, productivity veya reforecast
  alanı eklemedik.
- Gantt, critical path/float, approved baseline, resource optimization veya AI
  davranışı eklemedik.
- Backup format/version/crypto production kodunu değiştirmedik.
- Eski Living Plan item'larını yeni snapshot'a reconcile/rebind etmedik.

## 14. Mini sözlük

- **Current snapshot:** Proje için `superseded_at IS NULL` olan tek trusted
  reference schedule snapshot.
- **Origin snapshot:** Living Plan item oluşturulurken seçimin geldiği ve daha
  sonra değişmeyen snapshot.
- **No-op:** Etkili date/status/note değişmediği için revision veya event
  üretmeyen komut.
- **Clock regression:** Yeni audit zamanının item'ın son `updated_at` zamanından
  geride olması.
- **Fail closed:** Kimlik/version/integrity uyuşmazlığında tahmin veya kısmi
  sonuç yerine işlemi durdurmak.

## 15. Sonraki adıma bağlantı

Bu core bağımsız review ve merge sonrasında immediate successor, yalnız Living
7-Day Plan UI + APK / gerçek cihaz kabul Slice'ıdır. UI artık:

- yedi günlük trusted önerileri listeleyebilir;
- current reference içinde Türkçe arama yapabilir;
- seçimi Living Plan'a ekleyebilir;
- overdue ve pencere içi item'ları gösterebilir;
- start/complete/defer/reopen/note komutlarını revision ile gönderebilir.

Bu öğrenme belgesi sonraki Slice'ı başlatmaz; yalnız hazır application
boundary'lerinin nasıl ve neden kurulduğunu açıklar.
