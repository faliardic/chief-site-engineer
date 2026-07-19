# Issue #179 — Flutter Mobil Ajanda ve Bağlı Hatırlatıcı

Bu öğrenme notu, mobil Ajanda diliminin yalnız ne yaptığını değil; Dart
katmanlarının neden ayrıldığını, SQLite transaction ve migration sınırlarının
nasıl çalıştığını, testlerin hangi riski yakaladığını gerçek kodla açıklar.

## Büyük resim

```text
Flutter form/widget
    ↓ immutable command
AgendaApplication interface
    ↓ validation + tek clock
SqliteAgendaApplication
    ↓ transaction
mobile SQLite schema 2
```

UI doğrudan SQL çalıştırmaz. SQL katmanı da TextEditingController veya
Navigator bilmez. Böylece aynı Dart domain/application sözleşmesi Android ve
iOS'ta çalışır.

## 1. Immutable command nedir?

Log oluşturma girdisi şu gerçek sınıfta tutulur:

```dart
class CreateAgendaLogCommand {
  const CreateAgendaLogCommand({
    required this.id,
    required this.eventId,
    required this.projectId,
    required this.observedAt,
    required this.category,
    required this.description,
    this.location,
    this.notes,
  });

  final String id;
  final String eventId;
  final String projectId;
  final String observedAt;
  final AgendaCategory category;
  final String description;
  final String? location;
  final String? notes;
}
```

Satır satır anlamı:

1. `const` constructor, command'ın oluşturulduktan sonra değişmeyen value
   object olmasını destekler.
2. `id`, log row'unun UUID'sidir.
3. `eventId`, aynı transaction'da yazılacak creation event UUID'sidir.
4. `projectId`, source project bağlantısını command başından itibaren taşır.
5. `observedAt`, UI local zamanı değil, canonical UTC seconds değeridir.
6. `AgendaCategory`, serbest yazılmış ve typo taşıyan tür yerine kapalı enum'dur.
7. Opsiyonel alanlar nullable'dır; boş string service içinde `null` olur.

Form `initState` içinde log/event UUID'lerini bir kez üretir. Validation
başarısız olup kullanıcı tekrar bastığında aynı state ve aynı UUID kullanılır.
Bu, retry'nin yeni bir kayıt sanılmasını önler.

## 2. Clock neden yalnız bir kez okunur?

Serviste gerçek kod:

```dart
final now = _readClockOnce();
final observed = CseTimeCodec.decodeCanonicalUtc(command.observedAt);
if (observed.isAfter(now)) {
  throw const AgendaValidationFailure(
    'Gelecek tarihli olay kaydedilemez.',
  );
}
final createdAt = CseTimeCodec.encodeUtc(now);
```

Adım adım:

1. `clock()` tek kez çağrılır.
2. Dışarıdan gelen event time canonical parser'dan geçer.
3. Event time, aynı `now` ile future policy'ye girer.
4. `createdAt`, tekrar saat okumadan aynı `now` değerinden üretilir.
5. Log row `created_at`, `updated_at` ve event `occurred_at` aynı create anını
   taşır.

Saat üç kez okunsaydı saniye sınırında değerler farklılaşabilir, test ve audit
anlamı belirsizleşebilirdi.

## 3. İstanbul wall-clock nasıl UTC olur?

Flutter date/time picker bize timezone taşımayan yıl, ay, gün, saat ve dakika
parçaları verir. Bunları sistem timezone'una göre parse etmek yanlıştır. Açıkça
İstanbul olarak yorumlarız:

```dart
final local = timezone.TZDateTime(
  timezone.getLocation(istanbulTimezoneName),
  year,
  month,
  day,
  hour,
  minute,
  second,
);
return encodeUtc(local.toUtc());
```

Satır satır:

1. IANA adı `Europe/Istanbul` seçilir.
2. Picker parçaları bu location içinde wall-clock olarak kurulur.
3. Yıl/ay/gün/saat/dakika önce ayrı strict validation'dan geçer; Dart'ın
   `30 Şubat` değerini Mart'a yuvarlamasına izin verilmez.
4. `toUtc()` aynı gerçek anı UTC'ye çevirir.
5. `encodeUtc()` fractional kısmı olmayan exact `...SSZ` üretir.

Örnek:

```text
2026-07-19T00:00 Europe/Istanbul
-> 2026-07-18T21:00:00Z
```

Ajanda gün sorgusu da aynı sınırı kullanır:

```text
2026-07-19 İstanbul günü
start         = 2026-07-18T21:00:00Z
end exclusive = 2026-07-19T21:00:00Z
```

## 4. Schema migration neden tek transaction?

`AppDatabase.open()` bütün eksik migration'ları şu sınırda çalıştırır:

```dart
await candidate.transaction((transaction) async {
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

Anlamı:

- tablo oluşturma başarısız olursa history yazılmaz;
- history yazımı başarısız olursa `user_version` ilerlemez;
- `user_version` ilerlemezse uygulama yarım schema'yı başarılı sanmaz;
- schema `1` smoke row'u rollback dışında ve değişmeden kalır.

Test, önce gerçek schema `1` database'i oluşturur; sonra kasten yarım tablo
oluşturup exception atan schema `2` uygular. Sonuçta:

```text
PRAGMA user_version == 1
smoke_records count == 1
partial_v2 table count == 0
```

## 5. Composite foreign key neyi korur?

Reminder source bağlantısı yalnız `observation_id` taşısaydı, yanlış project
ID ile aynı loga bağlanabilirdi. Bu yüzden schema'da çift alanlı ilişki vardır:

```sql
FOREIGN KEY (observation_id, project_id)
  REFERENCES field_observations(id, project_id)
```

Bu satır şunu söyler:

> Reminder'ın observation ID ve project ID çifti, log tablosundaki aynı çiftle
> birebir eşleşmelidir.

Application service ayrıca mutation'dan önce aynı çifti sorgular. Application
validation kullanıcıya anlaşılır hata verir; database foreign key ise son
savunma katmanıdır.

## 6. Log ve event neden beraber yazılır?

Gerçek transaction özeti:

```dart
return database.transaction((transaction) async {
  // Önce project validation ve idempotent retry kontrolü.
  await transaction.insert('field_observations', logRow);
  await transaction.insert('observation_events', createdEvent);
  return log;
});
```

İkinci insert başarısızsa ilk insert commit olmaz. Böylece geçmişsiz log
oluşmaz. Reminder create de aynı yöntemi kullanır:

```dart
await transaction.insert('follow_up_items', reminderRow);
await beforeReminderEventInsert?.call(transaction);
await transaction.insert('follow_up_events', createdEvent);
```

`beforeReminderEventInsert`, yalnız testte exception üretmek için konmuş dar bir
test seam'idir. Test bu noktada hata üretir ve iki tabloda da count `0` bekler.

## 7. Append-only event nasıl uygulanır?

Event repository'sine update/delete metodu eklememek yararlıdır ama tek başına
yeterli değildir. Ham SQL yanlışlıkla geçmişi değiştirebilir. Schema trigger'ı:

```sql
CREATE TRIGGER observation_events_append_only_update
BEFORE UPDATE ON observation_events
BEGIN
  SELECT RAISE(ABORT, 'append-only event history');
END
```

Aynı koruma delete ve reminder event tablosu için de vardır. Test doğrudan ham
SQLite `UPDATE` ve `DELETE` çalıştırır; ikisinin de exception verdiğini kanıtlar.

## 8. Idempotent retry nasıl çalışır?

Servis insert'ten önce aynı row UUID'sini arar:

```dart
if (existing.isNotEmpty) {
  final log = _logFromRow(existing.single);
  if (!_sameLogCommand(log, command, description, location, notes)) {
    throw const AgendaValidationFailure(
      'Log kimliği başka bir içerikle kullanılıyor.',
    );
  }
  return log;
}
```

İki olasılık:

| Durum | Sonuç |
| --- | --- |
| Aynı UUID + aynı içerik | Mevcut kayıt döner, yeni insert/event yok |
| Aynı UUID + farklı içerik | Fail-closed conflict |

Bu davranış UI double-tap kilidinin altında ikinci güvenlik katmanıdır.

## 9. Reminder schedule nasıl çözülür?

| UI seçimi | Hesap |
| --- | --- |
| 15 dakika | `now + Duration(minutes: 15)` |
| 1 saat | `now + Duration(hours: 1)` |
| Bugün çıkmadan | İstanbul aynı gün 18:00 |
| Yarın sabah | İstanbul ertesi gün 09:00 |
| Unutma Kutusu | `next_attention_at = null` |
| Özel | strict İstanbul components → UTC |

Çözülmüş tarih `now` sonrasında değilse mutation başlamadan hata olur.
`waiting` türü zamanlıysa başlangıç durumu `waiting`; action/recheck zamanlıysa
`active`; attention yoksa her tür `inbox` başlar.

## 10. Literal arama neden LIKE kullanmıyor?

SQL:

```sql
instr(
  lower(description || ' ' || coalesce(location, '') || ' ' ||
    coalesce(notes, '') || ' ' || project_name),
  lower(?)
) > 0
```

`LIKE '%kullanıcı_girdisi%'` yazılsaydı `%` ve `_` wildcard olurdu. `instr`,
kullanıcının `% beton` metnini gerçekten yüzde işareti + boşluk + beton olarak
arar. Test hem eşleşen `% beton` hem eşleşmemesi gereken `%_missing` kullanır.

## 11. Android'deki eşzamanlı açılış yarışı

`IndexedStack`, görünmeyen Ajanda ve Hatırlatıcı state'lerini de oluşturur.
İki sayfa aynı anda read başlatabilir. Gerçek emülatör testi, ayrı DB
bağlantılarının eşzamanlı açılışında kartın yüklenmediğini yakaladı.

Çözüm:

```dart
Future<void> _databaseQueue = Future<void>.value();

_databaseQueue = _databaseQueue.then((_) async {
  final appDatabase = AppDatabase(...);
  await appDatabase.open();
  try {
    completer.complete(await action(appDatabase.database));
  } finally {
    await appDatabase.close();
  }
});
```

Her yeni işlem önceki `Future` tamamlandıktan sonra başlar. Bu, global database
singleton kurmadan kısa bağlantı modelini korur. Transaction içi SQL sırası
değişmez.

## 12. Widget state neden input'u koruyor?

Form controller'ları `initState` içinde oluşturulur, hata olduğunda
temizlenmez:

```dart
} on AgendaValidationFailure catch (error) {
  if (mounted) {
    setState(() => _error = error.message);
  }
}
```

Yalnız hata mesajı değişir. Test description, location ve notes alanlarını
doldurur; service validation exception'ı sonrası controller text'lerinin
aynı kaldığını doğrular.

Double tap koruması:

```dart
if (_submitting || !_formKey.currentState!.validate()) return;
setState(() => _submitting = true);
```

Test service Future'ını kasıtlı bekletir, iki kez tap yapar ve create call
sayısının `1` kaldığını doğrular.

## 13. Test kodu neyi doğruluyor?

Örnek migration assertion'ı:

```dart
expect(version, 1);
expect(smokeCount, 1);
expect(partialCount, 0);
```

- İlk satır yarım migration'ın sürümü ilerletmediğini,
- ikinci satır eski verinin korunduğunu,
- üçüncü satır partial tablo bırakılmadığını gösterir.

Örnek sıralama assertion'ı:

```dart
expect(july19.map((item) => item.id), [log3, log1, log2]);
```

- `log3` gün başlangıcındaki daha erken `observed_at` kaydıdır.
- `log1` ve `log2` aynı observed/created zamanını taşır.
- Son eşitlik ID ASC ile çözülür.

Örnek source değişmezliği:

```dart
expect(detail.log.updatedAt, source.updatedAt);
expect(detail.log.revision, source.revision);
```

Altı reminder yaratıldıktan sonra bile source log mutation görmez.

Android integration testi gerçek `sqflite` kullanır:

```text
bootstrap
-> project oluştur
-> log oluştur
-> linked inbox reminder oluştur
-> bootstrap restart
-> detail/list read
-> Ajanda kartını gör
-> Hatırlatıcı kartını gör
```

Bu test internet veya Python runtime açmaz.

## Teknik karar tablosu

| Karar | Seçilen yaklaşım | Neden |
| --- | --- | --- |
| Runtime | Flutter/Dart | Android/iOS tek sözleşme |
| Veri | cihaz-içi SQLite | offline device-of-truth |
| Mobil schema | ayrı version `2` | Python schema namespace'ini karıştırmamak |
| Event | append-only tablo + trigger | geçmişi ham SQL'e karşı da korumak |
| Source link | composite FK | yanlış project/log çiftini reddetmek |
| Command | immutable UUID taşıyan object | retry ve validation sınırı |
| Clock | create başına tek okuma | deterministic timestamp |
| Arama | `instr` | wildcard olmayan literal davranış |
| UI state | Stateful form controller | hata halinde girdiyi korumak |
| DB concurrency | service Future kuyruğu | Android shell init yarışını önlemek |
| Notification | eklenmedi | Issue kapsamı yalnız in-app reminder |
| Attachment | eklenmedi | sonraki Ajanda dilimi |

## Kod çalışma akışı

```text
Kullanıcı Logu kaydet'e basar
  -> form local components'i İstanbul olarak UTC'ye çevirir
  -> immutable command service'e gider
  -> text/UUID/timestamp/future validation
  -> clock bir kez okunur
  -> DB işlemi seri kuyruğa girer
  -> transaction project'i doğrular
  -> aynı UUID retry kontrol edilir
  -> log + created event yazılır
  -> commit
  -> form observed_at İstanbul gününü Navigator ile döndürür
  -> Ajanda o günü yeniden yükler
```

Reminder akışı:

```text
Ajanda kartı/detayı
  -> Hatırlatıcı oluştur
  -> açıklamadan önerilen ama editable title
  -> tür + schedule
  -> source project/log validation
  -> reminder + created event tek transaction
  -> Hatırlatıcı read-model
  -> detail -> source Ajanda deep-link
```

## Şunu şöyle yaptık ki...

Şunu şöyle yaptık ki kullanıcı geçmiş bir saha olayını doğru İstanbul saatinde
kaydederken CSE'ye giriş zamanı kaybolmasın; aynı logdan birden fazla reminder
üretirken her reminder ilk satırından itibaren doğru project ve source loga
bağlı olsun; Android'de hata, çift dokunma, retry veya eşzamanlı sayfa açılışı
yarım/duplicate kayıt bırakmasın. Bunun için immutable command, tek clock,
strict UTC codec, composite foreign key, append-only event, tek transaction ve
gerçek emülatör testini birlikte kullandık.

## Kapsam dışını korumak neden önemliydi?

Issue #179 reminder'ı uygulama içinde görünür yapar; OS notification teslimi
yapmaz. Attachment platform portu Issue #180'den beri vardır ama loga
bağlanmaz. Flask/web route eklenmez. Bu sınırlar, tek dilimin test edilebilir ve
rollback edilebilir kalmasını sağlar.
