# Issue #194 Öğrenme Notu — Saha Düzeltmeleri

## Bu geliştirmede ne öğrendik?

Bir ekranda “taşeron seç” alanı eklemek yalnız UI işi değildir. Eski Puantaj
satırlarının hangi kişiye ait olduğunu korumak, yeni hiyerarşinin database
tarafında da geçerli olmasını sağlamak, archive/reopen sırasını tanımlamak ve
backup/restore'un aynı bağlantıları taşıdığını kanıtlamak gerekir.

Benzer biçimde reminder kartındaki `Yarın` düğmesi yalnız tarihe bir gün eklemek
değildir. Europe/Istanbul takvim günü, UTC storage, saatlik platform bildirimi,
optimistic revision ve source kaydını değiştirmeme aynı sözleşmenin parçalarıdır.

## Gerçek kod: schema 5 → 6 legacy eşlemesi

```dart
final rawName = (row['team_name']! as String).trim();
final name = rawName.isEmpty ? 'Tanımsız ekip' : rawName;
final normalized = _normalizeRegistryName(name);
final subcontractorId = _migrationStableUuid(
  'legacy-subcontractor:$projectId:$normalized',
);
final teamId = _migrationStableUuid(
  'legacy-team:$projectId:$normalized',
);
await transaction.update(
  'workforce_members',
  {'subcontractor_id': subcontractorId, 'team_id': teamId},
  where: 'project_id = ? AND team_name = ?',
  whereArgs: [projectId, row['team_name']],
);
```

Satır satır açıklama:

1. Eski serbest metin ekip adı okunur ve kenar boşlukları kaldırılır.
2. Boş değer kaybolmaz; kullanıcıya görünür `Tanımsız ekip` grubuna çevrilir.
3. Normalization, farklı boşluk ve harf büyüklüklerinin aynı sicili göstermesini
   sağlar.
4. Taşeron kimliği proje + normalized ad girdisinden deterministik üretilir.
5. Ekip kimliği ayrı namespace kullanır; aynı metin olsa bile taşeron kimliğiyle
   çakışmaz.
6. Son işlem personel satırını silip yeniden eklemez. Yalnız exact foreign key
   alanlarını mevcut personel ID'sine yazar. Attendance geçmişi bu yüzden aynı
   kişiyi göstermeye devam eder.

Migration tek SQLite transaction'ında çalışır. Tablo veya trigger adımlarından
biri hata verirse schema sürümü ilerlemez ve yarım bağlı personel kalmaz.

## Gerçek kod: aggregate ve event aynı transaction'da

```dart
return _withDatabase(
  now,
  (database) => database.transaction((tx) async {
    await _requireProject(tx, command.projectId);
    await tx.insert('subcontractors', {
      'id': command.id,
      'project_id': command.projectId,
      'name': name,
      'name_normalized': normalized,
      'status': WorkforceRecordStatus.active.storageValue,
      'revision': 1,
      'created_at': timestamp,
      'updated_at': timestamp,
    });
    await _insertWorkforceEvent(
      tx,
      id: command.eventId,
      type: 'subcontractor',
      aggregateId: command.id,
      projectId: command.projectId,
      eventType: 'subcontractor.created',
      occurredAt: timestamp,
      payload: {'name': name},
    );
    return _loadSubcontractor(tx, command.id);
  }),
);
```

`_requireProject` parent kaydı mutation öncesinde doğrular. `tx.insert` mutable
güncel durumu, `_insertWorkforceEvent` ise değişmez geçmişi yazar. İki yazma aynı
transaction nesnesini kullandığı için event başarısızsa taşeron satırı da commit
olmaz. Dönüşte tekrar database'ten okumak trigger/default sonuçlarının domain
modeline yansımasını sağlar.

Güncelleme komutlarında `expectedRevision` önce karşılaştırılır. Stale komut
fail-closed durur. Alanlar değişmediyse no-op kabul edilir; revision ve event
sayısı artmaz.

## Gerçek kod: canlı proje kataloğu

```dart
final result = await _withDatabase(now, (database) {
  return database.transaction((transaction) async {
    // duplicate doğrulama ve INSERT
    return (project: project, changed: true);
  });
});
if (result.changed) _projectChanges.add(null);
return result.project;
```

Önce SQLite transaction başarıyla biter. Ancak bundan sonra stream'e değişiklik
sinyali yazılır. Böylece UI başarısız veya rollback olmuş bir projeyi varmış gibi
göstermez. Dinleyiciler sinyal içeriğini source-of-truth saymaz; kendi proje
listelerini SQLite'tan tekrar okur. Uygulama restart olduğunda stream geçmişi
gerekmemesinin nedeni budur.

Duplicate denetimi SQL `lower(trim(name))` ile sınırlı bırakılmadı. Dart helper
ardışık whitespace'i de tek boşluğa indirir; `Saha  A` ile ` saha a ` aynı aktif
proje kabul edilir.

## Gerçek kod: `Yarın` takvim işlemi

```dart
values['next_attention_at'] = current.nextAttentionAt == null
    ? _tomorrowMorning(now)
    : _tomorrowAtSameLocalTime(current.nextAttentionAt!, now);
```

İlk dal Unutma Kutusu kaydı için ertesi İstanbul günü 09:00 üretir. İkinci dal
mevcut due anını önce İstanbul yerel saate çevirir, takvim tarihini bir artırır ve
aynı saat/dakikayı canonical UTC'ye geri çevirir. `Duration(days: 1)` ile UTC'ye
körlemesine ekleme yapılmaz; takvim niyeti açık kalır.

Mutation aynı reminder satırının revision'ını artırıp `snoozed` event'i ekler.
Linked source observation/Beton aggregate'i bu transaction'ın update hedefi
değildir. UI busy anahtarı da aynı reminder ID'sine ikinci dokunuşu engeller.

## Gerçek kod: saatlik inexact notification

```dart
await withClock(
  Clock.fixed(instant.subtract(interval)),
  () => plugin.periodicallyShowWithDuration(
    id: request.platformId,
    repeatDurationInterval: interval,
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    payload: 'reminder:${request.reminderId}',
  ),
);
```

Android plugin'i ilk native tetiklemeyi `calledAt + interval` olarak hesaplar.
Satır satır akış şöyledir:

1. `instant`, SQLite binding'deki canonical UTC due anıdır.
2. `interval`, bu Beton görevi için 60 dakikadır.
3. `Clock.fixed(instant.subtract(interval))`, plugin'in native mesaja yazdığı
   `calledAt` değerini due'dan tam bir interval öncesine sabitler.
4. Native taraf `calledAt + interval` hesabıyla ilk alarmı due anına koyar.
5. `inexactAllowWhileIdle` exact-alarm izni istemez; Android receiver her teslim
   sonrasında sonraki saatlik alarmı platform cache'inden kurar.

Bu kayıt uygulama process'i kapansa veya cihaz reboot etse de Android'in pending
alarm/receiver sözleşmesinde kalır. Due anında Dart kodunun ya da reconciliation'ın
çalışması gerekmez.

iOS time-interval repeat API'si ayrı bir future başlangıç kabul etmediği için aynı
çağrıyı kullanmak due'dan önce bildirim üretirdi. Bu nedenle iOS yolu şöyledir:

```dart
for (var slot = 0; slot < 24; slot += 1) {
  await plugin.zonedSchedule(
    id: rollingPlatformId(rootPlatformId, slot),
    scheduledDate: firstOccurrence.add(interval * slot),
    payload: 'reminder:$reminderId|rolling:$rootPlatformId:$slot:24',
  );
}
```

- Döngü tek SQLite reminder için 24 fiziksel platform occurrence'ı oluşturur.
- `slot = 0` due, `slot = 1` due + 1 saat, `slot = 2` due + 2 saattir.
- Fiziksel ID negative namespace'tedir; positive SQLite binding ID ile veya yeni
  bir logical reminder satırıyla karışmaz.
- Payload root ID, slot ve toplam sayıyı taşır. Pending okuması 24 kaydı tek
  logical pending'e katlar; eksik grup `scheduleComplete = false` olur.
- Schedule ortada hata verirse o çağrıda yazılan fiziksel ID'ler temizlenir.
- Completion/cancel payload root'una ait bütün fiziksel kayıtları iptal eder.

`pendingNotificationSlotCost(60)` iOS için `24`, normal tek seferlik bildirim için
`1` döndürür. Böylece application service 60 pending sınırını logical reminder
sayısıyla değil gerçekten kullanılacak platform slotuyla hesaplar.

## Test kodu neyi doğruluyor?

```dart
test('schema 5 to 6 maps legacy teams atomically and preserves exact history',
    () async {
  await arrangeSchema5Fixture(databasePath);
  await expectLater(openWithInjectedV6Failure(), throwsA(isA<Exception>()));
  expect(await readUserVersion(databasePath), 5);

  final migrated = await openNormally(databasePath);
  expect(await migrated.rawQuery('SELECT id FROM workforce_members'),
      contains({'id': originalMemberId}));
  expect(await attendanceHistory(migrated), originalAttendanceHistory);
});
```

Test yalnız yeni tablonun varlığını sormaz. Önce gerçek schema 5 fixture'ı kurar,
v6 içinde hata enjekte edip `user_version` ve eski verinin rollback kaldığını
görür. Sonra aynı dosyayı normal açarak retry migration'ı çalıştırır; personel
ID'si ile attendance entry/event geçmişini karşılaştırır. Case/space eşitliği ve
boş `Tanımsız ekip` de fixture içinde bulunur.

Application testleri duplicate, stale, no-op, logical archive, üstten alta
reopen, append-only sıra, İSG tarih sınırları ve KKD iade invariant'ını kapsar.
Widget testleri 320 px ekranda yerinde yeni taşeron/ekip, validation input
korunumu, personel sekmeleri ve double-tap davranışını çalıştırır.

Concrete testleri exact iki label, source/project linki, 60 dakikalık binding,
`Yarın` sonrası due/+1/+2 platform occurrence'ı, terminated-app kalıcılığı, alan
tamamlama/reopen, cancel, duplicate üretmeme ve kodsuz numune sırasını doğrular.
Reminder testleri yerel aynı saat/ertesi 09:00, UTC storage, source mutation
yokluğu, event/revision, eksik rolling grup onarımı ve refresh güvenliğini
kanıtlar. Backup testi schema `1`–`6` staging migration ile v6 sicil bağlantısı
ve geçmişini exact round-trip karşılaştırır.

Platform testindeki temel kanıt şöyledir:

```dart
expect(arguments['calledAt'], due.subtract(oneHour).millisecondsSinceEpoch);
expect(arguments['repeatIntervalMilliseconds'], 3600000);
expect(iosCalls[0].scheduledDateTime, '2026-07-21T09:00:00');
expect(iosCalls[1].scheduledDateTime, '2026-07-21T10:00:00');
expect(iosCalls[2].scheduledDateTime, '2026-07-21T11:00:00');
expect(await countRows('follow_up_items'), 8);
```

İlk iki assertion Android native mesajındaki future anchor ve saatlik aralığı
kontrol eder. Sonraki üç assertion İstanbul saatinde due, +1 ve +2 saat iOS
kayıtlarını doğrular. Son assertion platformda çok sayıda fiziksel kayıt olsa da
SQLite'ta sekiz Beton follow-up'ından fazlasının oluşmadığını kanıtlar.

## Teknik karar tablosu

| Karar | Seçilen çözüm | Neden |
| --- | --- | --- |
| Legacy ekip | Deterministik taşeron + ekip UUID | Retry aynı bağlantıyı üretir |
| Boş legacy değer | `Tanımsız ekip` | Personel kaybolmaz, seçim yapılabilir |
| Sicil geçmişi | Mutable row + append-only event | Güncel görünüm ve audit kanıtı ayrılır |
| Silme | Logical archive | Puantaj geçmişi ve foreign key korunur |
| Reopen | Taşeron → ekip → personel | Aktif child archived parent'a bağlanmaz |
| İSG/KKD | Kayıt/read-model, hukuki karar yok | Ürünün yetki sınırını aşmaz |
| Proje yenileme | Commit sonrası signal + SQLite reload | Rollback UI'a sızmaz, restart kalıcıdır |
| `Yarın` | İstanbul takvim hesabı → UTC | Kullanıcının yerel saat niyeti korunur |
| Android saatlik bildirim | Future native anchor + inexact periodic | Due anında app/reconciliation gerekmez |
| iOS saatlik bildirim | 24 fiziksel kaydı tek logical rolling grup say | Future başlangıç korunur, reminder çoğalmaz |
| Platform kapasitesi | Fiziksel slot maliyeti | iOS pending sınırı sessizce aşılmaz |
| Backup | Format 1 içinde schema allowlist 1–6 | Paket formatı gereksiz değişmez |

## Kod çalışma akışı

```text
Uygulama açılışı
  -> SQLite schema sürümünü oku
  -> schema 5 ise tek transaction'da v6 tabloları + legacy linkler + trigger'lar
  -> başarısızsa rollback; başarılıysa schema 6
  -> application service'leri aç
  -> pending notification reconciliation
  -> UI SQLite read-model'lerini göster

Yeni personel
  -> proje
  -> taşeron seç veya oluştur
  -> yalnız o taşeronun ekibini seç veya oluştur
  -> immutable command + validation
  -> personel row + workforce event tek transaction
  -> Puantaj exact person/team ID kullanır

Reminder Yarın
  -> açık/stale revision doğrula
  -> Istanbul sonraki takvim günü hesapla
  -> UTC due + revision + event yaz
  -> source kaydına dokunma
  -> eski platform grubunu iptal et
  -> Android: future due anchor'lı inexact periodic kaydı yaz
  -> iOS: due, +1 ... +23 saat rolling kayıtlarını yaz
  -> uygulama kapansa da platform due ve sonraki saatleri teslim eder
  -> completion/cancel bütün fiziksel grubu temizler
  -> Beton source reopen aynı logical binding'i yeniden planlar
```

## “Şunu şöyle yaptık ki...”

- Legacy personel satırını yeniden üretmeyip yalnız exact sicil linklerini
  yazdık ki Puantaj geçmişindeki kişi kimliği değişmesin.
- Migration kimliklerini deterministik ürettik ki failure sonrası retry yeni ve
  farklı taşeron/ekip kayıtları oluşturmasın.
- Archive ve reopen sırasını database/application invariant'ıyla tanımladık ki
  aktif personel pasif bir organizasyon kaydının altında kalmasın.
- Proje değişiklik sinyalini transaction sonrasında yayınladık ki rollback olmuş
  proje açık ekranlarda geçici olarak görünmesin.
- İSG/KKD'yi read-model ve kayıt geçmişi olarak tuttuk ki uygulama hukuki uygunluk
  veya işe kabul kararı verdiğini iddia etmesin.
- `Yarın` hesabını İstanbul takviminde yapıp UTC sakladık ki kullanıcı aynı yerel
  saati görürken storage sözleşmesi değişmesin.
- Saatlik Beton bildirimini inexact periodic kurduk ki exact-alarm izni eklemeden
  saha hatırlatması devam etsin.
- Future due bilgisini Android native anchor'ına ve iOS rolling horizon'a baştan
  yazdık ki reminder'ın başlaması uygulamanın yeniden açılmasına bağlı kalmasın.
- iOS fiziksel occurrence'larını negative ID ve root payload ile grupladık ki
  platformda çok kayıt varken SQLite'ta duplicate logical reminder oluşmasın.
- Completion/cancel sırasında root grubunu, reopen sırasında aynı binding'i
  kullandık ki yarım bağlı veya ikinci bir Beton görevi kalmasın.
- Permission/plugin hatasında reminder'ı koruduk ki teslim katmanı arızası iş
  kaydını kaybettirmesin.
