# Issue #185 Öğrenme Notu — Mobil Günlük Puantaj

Bu not yalnız ne değiştiğini değil, kodun neden bu sınırlarda kurulduğunu ve
testlerin hangi hataları yakaladığını açıklar. Örnekler gerçek Issue #185 Dart
kodundan alınmıştır.

## Hangi dosya ne yapıyor?

| Dosya | Görev | Neden ayrı? |
| --- | --- | --- |
| `mobile/lib/domain/attendance_models.dart` | Enum, read-model ve immutable command'lar | UI ve SQLite ayrıntısı domain sözleşmesine sızmasın |
| `mobile/lib/storage/app_database.dart` | Schema 4, migration, foreign key/check/trigger | Son savunma hattı database olsun |
| `mobile/lib/application/attendance_application.dart` | Validation, transaction, revision, event, reminder koordinasyonu | Çok adımlı mutation tek güvenli sınırda kalsın |
| `mobile/lib/platform/attendance_export_gateway.dart` | CSV, staging cleanup ve share port | Dosya/plugin davranışı application testinden ayrılabilsin |
| `mobile/lib/features/attendance/*` | Personel, gün, ayar ve liste ekranları | UI yalnız command kurup sonucu göstersin |
| `mobile/test/attendance_application_test.dart` | Gerçek SQLite davranış testleri | Transaction ve kalıcılık mock ile gizlenmesin |
| `mobile/test/attendance_widget_test.dart` | 320 px, form koruma, lifecycle ve deep-link | Kullanıcı akışı domain testiyle sınırlı kalmasın |

## 1. Aggregate neden günlük Puantaj günü?

Bir `attendance_day`, bir proje ve bir yerel tarihteki bütün personel
sonuçlarının tutarlılık sınırıdır. Birden fazla kişi aynı gün içinde değişse de
tek `revision` artırılır ve tek event zinciri oluşur.

Gerçek schema parçası:

```sql
CREATE TABLE attendance_days (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL REFERENCES projects(id),
  local_date TEXT NOT NULL,
  status TEXT NOT NULL CHECK (
    status IN ('draft', 'completed', 'no_work')
  ),
  revision INTEGER NOT NULL DEFAULT 1 CHECK (revision >= 1),
  completed_at TEXT,
  UNIQUE (project_id, local_date),
  UNIQUE (id, project_id)
)
```

Satır satır anlamı:

1. `id`, deep-link ve event'lerin kullandığı değişmez kimliktir.
2. `project_id`, günün hangi şantiyeye ait olduğunu zorunlu kılar.
3. `local_date`, duvar saati değil `Europe/Istanbul` takvim günüdür.
4. `status`, yalnız tanımlı üç yaşam döngüsü durumunu kabul eder.
5. `revision`, kullanıcının eski ekranla yeni veriyi ezmesini önler.
6. `UNIQUE (project_id, local_date)`, aynı güne ikinci aggregate açılmasını
   database seviyesinde durdurur.
7. `UNIQUE (id, project_id)`, reminder'ın composite foreign key kurabilmesini
   sağlar.

Tarih anahtarını UTC gününden üretmedik. Örneğin İstanbul'da `00:30`, bir
önceki UTC gününe denk gelebilir. Günlük Puantaj kullanıcı takvimine göre
çalışmalıdır; event ve reminder anları ise yine canonical UTC saklanır.

## 2. Sonuç ve kişi-gün hesabı

Domain enum'u hesap katsayısını sonuçla birlikte taşır:

```dart
enum AttendanceResult {
  fullDay('full_day', 'Tam gün', 1),
  halfDay('half_day', 'Yarım gün', 0.5),
  absent('absent', 'Gelmedi', 0),
  leave('leave', 'İzinli', 0);

  const AttendanceResult(
    this.storageValue,
    this.label,
    this.dayEquivalent,
  );
}
```

- `storageValue`, SQLite'taki kararlı makine değeridir.
- `label`, kullanıcıya gösterilen Türkçe karşılıktır.
- `dayEquivalent`, türetilmiş toplamın tek tanımıdır.
- `halfDay` değerinin `0.5` olması yarım günü iki farklı yerde yeniden
  yorumlamamızı önler.
- `absent` ve `leave`, sahada bulunan kişi sayısına ve kişi-güne eklenmez.

Toplamlar kaydedilmez; entry listesinden her okumada türetilir. Böylece entry
değişip toplam satırı değişmezse oluşacak veri drift'i mümkün olmaz.

## 3. Optimistic revision nasıl koruyor?

UI bir günü okuduğunda örneğin revision `3` görür. Kaydet command'ı bunu taşır:

```dart
SaveAttendanceRosterCommand(
  dayId: detail.day.id,
  eventId: eventId,
  expectedRevision: detail.day.revision,
  values: values,
)
```

Application service önce database'deki gün revision'ını okur. Eşleşmiyorsa
işleme başlamadan stale conflict döndürür. Eşleşiyorsa SQL update de aynı koşulu
tekrar kullanır:

```dart
final count = await transaction.update(
  'attendance_days',
  {
    'revision': day.revision + 1,
    'updated_at': timestamp,
  },
  where: 'id = ? AND revision = ?',
  whereArgs: [day.id, day.revision],
);
if (count != 1) throw staleFailure();
```

Satır satır:

1. Yeni değer eski revision'ın tam bir fazlasıdır.
2. `WHERE` hem kimliği hem beklenen revision'ı sınırlar.
3. Başka işlem arada yazdıysa update sayısı `0` olur.
4. Exception transaction'ı rollback eder; entry/event yarım kalmaz.

No-op ayrı bir konudur. Kullanıcı aynı değerleri tekrar kaydediyorsa revision ve
event artırılmaz. Böylece geçmiş gerçek değişiklikleri anlatır.

## 4. Logical removal neden kullanıldı?

Entry tablosunda `removed_at` bulunur. Bir sonuç günlük aktif listeden çıkarılsa
da fiziksel satır silinmez. Aynı personel tekrar eklenirse aynı unique
`(attendance_day_id, workforce_member_id)` satırı yeni değerlerle ve
`removed_at = NULL` olarak etkinleşir.

Bu yaklaşım:

- aggregate event geçmişinin anlamını korur;
- eski personelin pasifleştirilmesinden etkilenmez;
- yanlışlıkla `DELETE` ile kanıt kaybını önler;
- aynı kişi/gün için duplicate satır üretmez.

`attendance_day.no_work` geçişi bütün aktif entry'leri aynı transaction'da
logical olarak kaldırır ve kaldırılan kimlikleri event payload'ına yazar.

## 5. Event geçmişi neden append-only?

Her event için bir sonraki sequence transaction içinde hesaplanır:

```dart
final rows = await transaction.rawQuery(
  '''
  SELECT COALESCE(MAX(sequence), 0) + 1 AS next_sequence
  FROM attendance_events
  WHERE attendance_day_id = ?
  ''',
  [dayId],
);

await transaction.insert('attendance_events', {
  'id': id,
  'attendance_day_id': dayId,
  'sequence': rows.single['next_sequence'],
  'event_type': eventType,
  'occurred_at': occurredAt,
  'payload_json': jsonEncode(payload),
});
```

1. Sequence yalnız ilgili aggregate içinde hesaplanır.
2. Boş geçmişte `COALESCE` sonucu `1` olur.
3. `UNIQUE (attendance_day_id, sequence)` duplicate sıra değerini reddeder.
4. Row ve event aynı transaction'da olduğu için sequence hesabı yarım business
   değişikliği üretmez.
5. Trigger, event'e sonradan `UPDATE` veya `DELETE` yapılmasını engeller.

Event geçmişi audit ürünü veya çok kullanıcılı onay sistemi değildir. Buradaki
amacı, tek kullanıcılı local uygulamada aggregate değişimlerini geri izlenebilir
ve test edilebilir tutmaktır.

## 6. Reminder exact bağlantısı nasıl kuruluyor?

Puantaj reminder'ı sonradan gevşek metin eşlemesiyle aranmaz. İlk insert'te
`attendance_day_id` ve `project_id` taşır; link tablosu da bire bir ilişkiyi
saklar:

```sql
CREATE TABLE attendance_day_reminder_links (
  attendance_day_id TEXT PRIMARY KEY REFERENCES attendance_days(id),
  reminder_id TEXT NOT NULL UNIQUE REFERENCES follow_up_items(id),
  due_at TEXT NOT NULL,
  created_at TEXT NOT NULL
)
```

- Gün kimliği primary key olduğu için bir güne ikinci otomatik reminder yoktur.
- Reminder kimliği unique olduğu için bir reminder iki güne bağlanamaz.
- `due_at`, reopen sırasında ilk schedule anlamını kaybetmemeyi sağlar.
- Reminder tablosundaki composite foreign key project mismatch'i reddeder.

Gün `completed` veya `no_work` olursa gün row'u, Puantaj event'i, reminder
status'u ve reminder event'i aynı SQLite transaction'da yazılır. Ardından
notification reconciliation yapılır. Plugin failure business kaydını rollback
etmez; yalnız teslim state'i etkilenir.

## 7. Önümüzdeki 14 gün neden idempotent?

Ayar `Europe/Istanbul` saatini ve seçili weekday sayılarını taşır. Ensure akışı:

```text
tek clock oku
-> İstanbul'da bugünün tarihini bul
-> offset 0..13 için yerel günü üret
-> weekday seçiliyse day ensure
-> exact linked reminder ensure
-> due wall-clock değerini canonical UTC'ye çevir
-> notification reconciliation
```

Day ve reminder kimlikleri sabit proje/tarih girdilerinden deterministik
üretilir. Ayrıca database unique anahtarları vardır. Bu yüzden bootstrap,
settings save veya manuel tekrar aynı 14 occurrence'ı ikinci kez yaratmaz.

Reopen due anını `now + ...` diye yeniden hesaplamaz; linkteki exact `due_at`
değerini kullanır. Geçmiş due geçmişte kalır ve reminder gecikmiş görünür. Bu,
geçmiş Puantaj düzeltmesini sahte bir gelecek reminder'a dönüştürmez.

## 8. CSV güvenliği ve atomiklik

Gerçek hücre koruması:

```dart
static String cell(String input) {
  final safe = input.isNotEmpty && '=+-@'.contains(input[0])
      ? "'$input"
      : input;
  return '"${safe.replaceAll('"', '""')}"';
}
```

1. Boş hücrede ilk karakter okunmaz.
2. Spreadsheet formülü başlatabilen dört karakter kontrol edilir.
3. Başına apostrof eklemek içeriği formül değil literal metin yapar.
4. İç çift tırnak iki çift tırnağa çevrilir.
5. Bütün hücre quote içine alınır.

Byte çıktısı UTF-8 BOM ile başlar ve CRLF kullanır. Türkçe Excel uyumluluğu
iyileşirken encoding tahmini azaltılır.

Export sırası önemlidir:

```text
deterministic bytes üret
-> temp dosyaya yaz
-> atomik final rename
-> attendance_day.csv_exported event'i yaz
-> istenirse platform share sheet'i aç
```

Event yazımı başarısızsa staged dosya uygulama export kökü doğrulandıktan sonra
temizlenir. Stage başarısızsa event yoktur. Böylece event “dosya hazır” derken
dosyanın aslında oluşmadığı bir durum üretilmez.

## 9. Test kodu neyi doğruluyor?

Örnek application testi:

```dart
await attendance.ensureRollingOccurrences();
await attendance.ensureRollingOccurrences();

expect(await count('attendance_days'), 14);
expect(await count('attendance_day_reminder_links'), 14);
expect(await count('follow_up_items'), 14);
```

İlk çağrı 14 günlük pencereyi kurar. İkinci çağrı aynı komutun tekrar güvenli
olduğunu sınar. Her üç sayının da 14 kalması day, link ve reminder katmanlarında
duplicate olmadığını kanıtlar.

Rollback testi event insert öncesi kontrollü exception üretir:

```dart
final failing = SqliteAttendanceApplication(
  beforeAttendanceEventInsert: (_) async {
    throw StateError('forced failure');
  },
);

await expectLater(failing.ensureDay(command), throwsStateError);
expect(await count('attendance_days'), 0);
expect(await count('attendance_events'), 0);
```

- Hook, gerçek transaction sınırının içinde patlar.
- Day insert daha önce çalışmış olsa da rollback ile sayı `0` olur.
- Event sayısının da `0` olması yarım geçmiş olmadığını gösterir.

Widget testleri ayrıca:

- 320 px genişlikte yatay overflow olmadığını;
- minimum 44 px touch target'ı;
- uzun Türkçe personel/ekip metnini;
- validation sonrası form değerlerinin kaldığını;
- submit sırasında duplicate command üretilmediğini;
- tamamla/no-work/reopen görünürlüğünü;
- notification tap'in reminder yerine doğrudan Puantaj gününü açtığını

doğrular.

Migration testi v3'e Ajanda, reminder, event ve notification binding satırları
yazar; v4 açılışından sonra aynı değerlerin byte/anlam olarak yerinde olduğunu
kontrol eder. Ayrı failure migration testi v4 SQL hatasında user version'ın `3`
ve eski tablonun okunabilir kaldığını doğrular.

## Teknik karar tablosu

| Karar | Seçilen | Seçilmeyen | Gerekçe |
| --- | --- | --- | --- |
| Gün anahtarı | İstanbul `YYYY-MM-DD` | UTC günü | Saha günü kullanıcının takvimidir |
| Storage anı | Canonical UTC seconds | Naive datetime | Tek ve karşılaştırılabilir zaman sözleşmesi |
| Değişiklik güvenliği | Optimistic revision | Sessiz last-write-wins | Stale ekran veri ezmesin |
| Silme | Pasifleştirme/logical removal | Physical delete | Tarihçe ve eski günlük okunabilsin |
| Toplam | Read sırasında türetme | Ayrı mutable toplam row'u | Drift riski olmasın |
| Hatırlatma | Exact FK + link | Metin/tarih eşlemesi | Yanlış gün/proje bağı kurulmasın |
| Schedule | Rolling 14 gün, idempotent | Sınırsız pending | Platform kapasitesi ve tekrar güvenliği |
| Export | Atomic stage + cleanup | Doğrudan final write | Yarım dosya ve yanlış success event'i olmasın |
| CSV hücresi | Formula prefix koruması | Ham kullanıcı metni | Spreadsheet çalıştırılabilir formül yorumlamasın |

## Şunu şöyle yaptık ki...

- Şunu, yani günlük personel değişikliklerini tek `attendance_day` aggregate'i
  içinde yaptık ki bir personel satırı kaydolup diğerinin yarım kalması mümkün
  olmasın.
- Personeli fiziksel silmek yerine pasifleştirdik ki geçmiş Puantaj kayıtları
  okunmaya devam etsin.
- `completed` günü yalnız explicit reopen ile düzenlenebilir yaptık ki geçmiş
  düzeltmesi görünmez bir overwrite olmasın.
- Reminder'ı ilk insert'ten itibaren gün ve projeye bağladık ki sonradan metin
  benzerliğiyle yanlış kayıt eşleşmesin.
- Notification plugin sonucunu business kaydından ayırdık ki izin reddi veya
  telefon API arızası Puantaj reminder'ını kaybettirmesin.
- CSV event'ini ancak atomik stage sonrasında yazdık ki geçmişte görünür bir
  export olayının karşılığında yarım veya hiç dosya bulunmaması engellensin.
- Gerçek kullanıcı data root'u yerine test temp dizinleri kullandık ki geliştirme
  ve doğrulama kullanıcı saha verisine dokunmasın.

## Bu dilimde özellikle yapılmayanlar

Ücret, bordro, maaş, SGK, hakediş, fotoğraf/belge, çoklu kullanıcı, onay zinciri,
cloud sync, Beton Paketi, store submission ve signing materyali eklenmedi. Bu
sınır teknik eksiklik değil, Issue #185'in bilinçli ürün sınırıdır.
