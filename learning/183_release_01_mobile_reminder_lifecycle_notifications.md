# Öğrenme Notu — Mobil Reminder Yaşam Döngüsü ve Bildirim Reconciliation

Bu adımda bir Flutter uygulamasında business kaydını işletim sisteminin
notification tesliminden nasıl ayırdığımızı, SQLite migration'ını veri
kaybetmeden nasıl yaptığımızı ve optimistic revision ile yarışan güncellemeleri
nasıl engellediğimizi inceliyoruz.

## 1. İki farklı doğruyu ayırmak

Reminder için iki farklı katman vardır:

```text
SQLite follow_up_items
    = işin gerçek durumu

Android/iOS pending notifications
    = yeniden üretilebilir teslim kopyası
```

Telefon bildirimi kullanıcı tarafından swipe edilince OS kaydı kaybolabilir.
Bu, şantiyedeki işin tamamlandığı anlamına gelmez. Bu nedenle reminder status'u
yalnız application service mutation'ıyla değişir.

Akış:

```text
Kullanıcı işlemi
  -> SQLite row + append-only event transaction
  -> transaction commit
  -> OS schedule/cancel denemesi
  -> operational sync state
  -> gerekirse sonraki bootstrap'ta reconciliation
```

Burada OS çağrısı SQLite transaction'ın içine konulmaz. Platform plugin çağrısı
geri alınabilir bir database işlemi değildir. Önce kalıcı gerçeği güvenceye
alırız; sonra teslim katmanını ona yaklaştırırız.

## 2. Schema 2 → 3 rebuild migration

SQLite'ta çok sayıda constraint'i aynı anda değiştirmek için mevcut tabloyu
`ALTER COLUMN` ile yamamak yerine kontrollü rebuild kullandık.

Gerçek migration fikrinin sadeleştirilmiş hali:

```sql
ALTER TABLE follow_up_events RENAME TO follow_up_events_v2;
ALTER TABLE follow_up_items RENAME TO follow_up_items_v2;

CREATE TABLE follow_up_items (... yeni v3 kolonları ve CHECK'ler ...);

INSERT INTO follow_up_items (...)
SELECT
  id,
  title AS capture_text,
  title,
  NULL AS description,
  item_type,
  status,
  project_id,
  observation_id,
  ...
FROM follow_up_items_v2;
```

Satır satır anlamı:

1. Event tablosu önce geçici ada alınır; eski reminder tablosuna bağlı foreign
   key'in yönetimi kolaylaşır.
2. Aggregate tablosu geçici ada alınır.
3. Yeni v3 tablo bütün yeni invariant'larla tek seferde kurulur.
4. Eski `title`, hem `capture_text` hem `title` alanına kayıpsız başlangıç değeri
   olur.
5. v2'de olmayan optional alanlar `NULL` veya güvenli default alır.
6. Eski project/observation bağlantıları aynen kopyalanır.

Migration runner bütün adımları tek transaction içinde çalıştırır:

```dart
await candidate.transaction((transaction) async {
  for (final migration in pendingMigrations) {
    await migration.apply(transaction);
    await transaction.insert('schema_versions', {...});
    await transaction.execute(
      'PRAGMA user_version = ${migration.version}',
    );
  }
});
```

Satır satır:

- `transaction`: migration'ın yarım kalmasını önler.
- `migration.apply`: tabloları ve veriyi dönüştürür.
- `schema_versions`: hangi migration'ın ne zaman uygulandığını append-only
  geçmişte tutar.
- `user_version`: SQLite'ın hızlı schema sürüm göstergesidir.
- Herhangi bir exception: bütün tablo rename/copy/drop işlemleri rollback olur.

## 3. Constraint'ler neden yalnız Dart'ta bırakılmadı?

Önemli invariant'ların schema tarafından da korunması gerekir:

```sql
CHECK (observation_id IS NULL OR project_id IS NOT NULL),

CHECK (
  (status = 'inbox' AND next_attention_at IS NULL)
  OR (status IN ('active', 'waiting') AND next_attention_at IS NOT NULL)
  OR status IN ('completed', 'cancelled')
),

FOREIGN KEY (observation_id, project_id)
  REFERENCES field_observations(id, project_id)
```

Birinci CHECK:

- source observation yoksa standalone reminder serbesttir;
- source observation varsa project zorunludur.

İkinci CHECK:

- inbox reminder zamanı olmadan saklanır;
- active/waiting reminder görünmesi gereken zamanı taşır;
- terminal kayıtların zaman zorunluluğu yoktur.

Composite foreign key:

- observation UUID'sinin bulunması tek başına yetmez;
- observation ile reminder aynı project ID'yi taşımalıdır.

Bu savunma iki katmanlıdır:

| Katman | Görev |
| --- | --- |
| Dart validation | Kullanıcıya anlaşılır ve erken hata verir |
| SQLite constraint | Bug, eski client veya doğrudan SQL hatasını engeller |

## 4. Immutable create command ve idempotency

Create girdisi değiştirilebilir form state'i değil, immutable command'dır:

```dart
class CreateReminderCommand {
  const CreateReminderCommand({
    required this.id,
    required this.eventId,
    required this.title,
    required this.kind,
    required this.schedule,
    this.projectId,
    this.sourceLogId,
  });

  final String id;
  final String eventId;
  final String title;
  final ReminderKind kind;
  final ReminderScheduleKind schedule;
  final String? projectId;
  final String? sourceLogId;
}
```

Satır satır:

- `const`: nesne kurulduktan sonra alanları değişmez.
- `id`: aggregate UUID'sidir; retry boyunca sabit kalır.
- `eventId`: created event UUID'sidir; aynı retry ikinci event üretmez.
- `projectId`: standalone reminder için optional'dır.
- `sourceLogId`: yalnız Ajanda bağlantılı reminder'da bulunur.

Relative schedule idempotency için önemli ayrıntı vardır. Kullanıcı “15 dakika”
seçtiğinde ilk kayıt zamanı `created_at` olur. Retry bir dakika sonra gelirse
“şimdiden 15 dakika” yeniden hesaplanmamalıdır. Karşılaştırma, eski reminder'ın
`created_at` anından schedule'ı yeniden kurar:

```dart
final originalSchedule = _resolveScheduleValues(
  command.schedule,
  command.customAttentionAt,
  command.kind,
  CseTimeCodec.decodeCanonicalUtc(reminder.createdAt),
);
```

Böylece aynı UUID + aynı command aynı aggregate'i döndürür.

## 5. Optimistic revision

Mobil ekranda reminder revision `7` iken başka bir işlem onu `8` yaptıysa eski
ekranın kaydetmesi yeni bilgiyi ezmemelidir.

Command:

```dart
MutateReminderCommand(
  reminderId: reminder.id,
  eventId: RecordId.randomUuid(),
  expectedRevision: reminder.revision,
  action: ReminderMutationAction.complete,
)
```

Application kontrolü:

```dart
if (current.revision != command.expectedRevision) {
  throw const AgendaValidationFailure(
    'Hatırlatıcı başka bir işlemle değişti. Ekranı yenileyin.',
  );
}
```

SQL de aynı korumayı tekrarlar:

```dart
final updated = await transaction.update(
  'follow_up_items',
  {...values, 'revision': current.revision + 1},
  where: 'id = ? AND revision = ?',
  whereArgs: [current.id, current.revision],
);

if (updated != 1) {
  throw const AgendaValidationFailure('Revision conflict');
}
```

İki kontrolün farkı:

- Dart kontrolü normal stale ekranı erken yakalar.
- SQL `WHERE revision = ?`, iki eşzamanlı transaction arasında son savunmadır.

## 6. No-op neden event üretmez?

Kullanıcı zaten inbox olan açık kayda yeniden “Yeniden aç” gibi etkisiz bir
işlem gönderirse audit geçmişi şişmemelidir.

```dart
_applyReminderMutation(values: values, ...);

if (_sameReminderValues(current, values)) {
  return (reminder: current, changed: false);
}
```

Önce expected revision kontrol edilir. Böylece stale command “nasıl olsa no-op”
denilerek kabul edilmez. Sonra yeni değerler eskiyle aynıysa:

- UPDATE yok;
- revision artışı yok;
- event insert yok;
- notification orchestration yok.

## 7. Row + event tek transaction

Bir lifecycle mutation'ın temel sınırı:

```dart
return database.transaction((transaction) async {
  await transaction.update('follow_up_items', updatedValues, ...);

  final nextSequence = await readNextSequence(transaction);

  await transaction.insert('follow_up_events', {
    'id': command.eventId,
    'follow_up_id': current.id,
    'sequence': nextSequence,
    'event_type': eventType,
    'occurred_at': updatedAt,
    'payload_json': safePayload,
  });
});
```

Event insert hata verirse row update de rollback olur. “Completed row var ama
completed event yok” veya tersi bir yarım durum kalmaz.

`sequence` neden var?

- iki event aynı UTC saniyesinde oluşabilir;
- random UUID kronolojik sıra değildir;
- aggregate içindeki `1, 2, 3...` sequence kesin kullanıcı geçmişini verir.

## 8. Deterministik platform notification ID

Android notification API integer ID ister; reminder kimliği UUID'dir.

Basitleştirilmiş algoritma:

```dart
var candidate = 2166136261;
for (final value in reminderId.codeUnits) {
  candidate ^= value;
  candidate = (candidate * 16777619) & 0x7fffffff;
}
if (candidate == 0) candidate = 1;

while (idAlreadyUsed(candidate)) {
  candidate = candidate == 2147483647 ? 1 : candidate + 1;
}
```

Satır satır:

- Sabit başlangıç ve UUID code unit'leri aynı UUID için aynı adayı üretir.
- `& 0x7fffffff`, değeri pozitif 31-bit Android integer aralığında tutar.
- `0`, bilinçli olarak kullanılmaz.
- UNIQUE tablo sorgusu gerçek çakışmayı görür.
- Lineer probe bir sonraki boş integer'ı seçer.

Hash fonksiyonu tek başına collision-free değildir. Collision-safe yapan şey
UNIQUE constraint ve probe işlemidir.

## 9. Gerçek platform schedule

Platform adapter'ındaki temel çağrı:

```dart
await plugin.zonedSchedule(
  id: request.platformId,
  title: request.title,
  body: request.body,
  scheduledDate: TZDateTime.from(instant, istanbulLocation),
  notificationDetails: details,
  androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  payload: 'reminder:${request.reminderId}',
);
```

Satır satır:

- `platformId`: SQLite'ta kalıcı unique integer eşlemedir.
- `scheduledDate`: canonical UTC instant, İstanbul timezone nesnesinde temsil
  edilir.
- `inexactAllowWhileIdle`: exact-alarm özel izni istemez.
- `payload`: notification tap'in hangi reminder'ı açacağını taşır.

Bu Issue'da manifest'e şunlar eklenmez:

```text
android.permission.USE_EXACT_ALARM
android.permission.SCHEDULE_EXACT_ALARM
```

## 10. Permission reddedilirse neden kayıt kalır?

Doğru sıra şöyledir:

```text
1. Reminder + created event + binding COMMIT
2. Kullanıcıdan notification izni iste
3. İzin reddedilirse binding = permission_denied
4. Reminder listede due/overdue görünmeye devam etsin
```

Yanlış sıra “önce izin, sonra reminder” olurdu. İzin dialog'u kapanırsa veya
plugin hata verirse kullanıcının yazdığı iş kaybolabilirdi.

Operational state sabit kod taşır:

```text
permission_denied
plugin_unavailable
pending_query_failed
schedule_failed
cancel_failed
platform_capacity
```

Raw exception metni saklanmaz; çünkü içinde platform path'i, cihaz ayrıntısı
veya beklenmeyen hassas bilgi bulunabilir.

## 11. Reconciliation algoritması

SQLite'tan uygun reminder'lar şu sırayla alınır:

```sql
ORDER BY
  CASE WHEN next_attention_at IS NULL THEN 1 ELSE 0 END,
  next_attention_at ASC,
  is_important DESC,
  created_at ASC,
  id ASC
```

Sonra:

```text
SQLite desired set
       |
       +-- OS'ta eksik --------> schedule
       +-- eski saat ----------> cancel + schedule
       +-- terminal/inbox -----> cancel
       +-- kapasite dışı ------> unavailable/platform_capacity

OS pending set
       |
       +-- yanlış payload -----> cancel
       +-- orphan ID ----------> cancel
       +-- duplicate source ---> yalnız doğru binding kalsın
```

Uygulama kapanıp açıldığında veya cihaz reboot olduğunda aynı algoritma yeniden
çalışabilir. İşlem idempotenttir: doğru pending kayıt tekrar schedule edilmez.

## 12. Notification tap deep-link

Plugin callback payload'ı doğrular:

```dart
if (!payload.startsWith('reminder:')) return null;
final reminderId = payload.substring('reminder:'.length);
return RecordId.isUuid(reminderId) ? reminderId : null;
```

Geçersiz payload navigation üretmez. Geçerli UUID stream'e eklenir. Mobil shell:

```dart
notificationTaps.listen((reminderId) {
  setState(() => selectedIndex = remindersTab);
  Navigator.of(context).push(
    ReminderDetailPage(reminderId: reminderId),
  );
});
```

Cold launch için plugin'in initial launch details değeri aynı doğrulamadan geçer.

## 13. Test kodunu okuma

Migration failure testi şu fikri doğrular:

```dart
DatabaseMigration(
  version: 3,
  apply: (transaction) async {
    await transaction.execute('CREATE TABLE partial_v3 (id TEXT)');
    throw StateError('intentional v3 failure');
  },
)
```

Beklentiler:

```dart
expect(userVersion, 2);
expect(originalProjectCount, 1);
expect(partialTableCount, 0);
```

Yani hata yalnız “exception geldi” diye test edilmez; önceki schema ve verinin
gerçekten korunduğu da ölçülür.

Revision testi:

```dart
await expectLater(
  application.mutateReminder(
    commandWith(expectedRevision: 1),
  ),
  throwsA(isA<AgendaValidationFailure>()),
);
```

Event rollback testi, event insert öncesi kontrollü hook ile hata üretir ve
sonra hem row revision'ının hem event count'un değişmediğini okur.

Notification testleri fake gateway üzerinden şunları ölçer:

- request çağrısı oldu mu;
- pending ID/payload doğru mu;
- orphan ID cancel edildi mi;
- schedule failure reminder row'u kaybettirdi mi;
- platform kapasitesi aşılınca daha uzak reminder SQLite'ta kaldı mı.

Gerçek Android emülatör testi ayrıca plugin kanalını kullanır:

```text
create scheduled reminder
-> gerçek pending listesinde 1 kayıt
-> yeni bootstrap/restart
-> SQLite bağlantısı korunmuş
-> complete
-> gerçek pending listesinde 0 kayıt
```

## 14. Teknik karar tablosu

| Karar | Seçim | Neden |
| --- | --- | --- |
| Source-of-truth | SQLite | OS notification silinebilir ve yeniden üretilebilir |
| Migration | Atomik table rebuild | Çoklu yeni kolon ve constraint güvenle eklenir |
| Concurrency | Optimistic revision | Eski ekran yeni bilgiyi sessizce ezmez |
| Audit | Append-only sequence | Aynı saniyedeki event sırası nettir |
| Platform ID | Stable hash + UNIQUE probe | Deterministik ve collision-safe |
| Android schedule | Inexact allow while idle | Exact-alarm özel izni gerekmez |
| Permission | DB commit sonrasında açık kullanıcı işlemi | Reddetme reminder kaybı üretmez |
| Plugin hata kaydı | Sabit safe error code | Raw exception/hassas bilgi sızmaz |
| Restart | Reconciliation | Pending teslim katmanı SQLite'tan onarılır |
| iOS capacity | En yakın 60 | Reminder kaybolmaz, uzak kayıt görünür uyarı alır |

## 15. Şunu şöyle yaptık ki...

- SQLite reminder'ı OS bildiriminden ayırdık ki bildirimi kapatmak işi
  tamamlamasın.
- Schema v2 tablolarını atomik rebuild ettik ki eski Ajanda ve linked reminder
  satırları kaybolmasın.
- Mutation'lara expected revision koyduk ki stale mobil ekran sessiz overwrite
  yapmasın.
- No-op karşılaştırmasını event insert'ten önce yaptık ki audit geçmişi gereksiz
  kayıtlarla şişmesin.
- Row ve event'i aynı transaction'da yazdık ki yarım yaşam döngüsü oluşmasın.
- Permission'ı SQLite commit'inden sonra istedik ki kullanıcı reddetse bile
  yazdığı reminder kaybolmasın.
- Raw plugin hatası yerine safe error code sakladık ki path, cihaz bilgisi veya
  secret sızmasın.
- Pending listeyi bootstrap'ta reconcile ettik ki restart, reboot, swipe veya
  plugin geçici hatası kalıcı reminder kaybına dönüşmesin.
- Android'de inexact schedule kullandık ki mağaza açısından hassas exact-alarm
  izinleri eklenmesin.
- Notification payload'ını doğrulanmış UUID ile sınırladık ki tap yalnız gerçek
  reminder detayına gitsin.
