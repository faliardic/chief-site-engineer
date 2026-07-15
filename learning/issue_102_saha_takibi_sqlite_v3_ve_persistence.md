# Issue 102 - Saha Takibi SQLite v3 ve Persistence

## 1. Bu adımda ne yaptık?

Issue #100 ile oluşturulan immutable domain kayıtlarını ilk kez SQLite içinde kalıcılaştırdık. Bu görev bir application service görevi değildir. Yalnız schema, domain-SQLite dönüşümü, repository adapter'ları ve transaction bağlantısı eklendi.

Değişen ana teknik dosyalar:

```text
app/persistence/schema.py
app/persistence/field_tracking_mapping.py
app/persistence/field_tracking_repositories.py
app/persistence/unit_of_work.py
app/persistence/__init__.py
tests/test_persistence_migrations.py
tests/test_field_tracking_persistence.py
```

Yeni tablo ailesi:

```text
follow_up_items
follow_up_events
routine_templates
routine_template_weekdays
routine_occurrences
routine_template_events
routine_occurrence_events
```

Gerçek kullanıcı data root'u üzerinde migration çalıştırılmadı. Bütün executable database testleri pytest'in `tmp_path` altındaki geçici SQLite dosyalarını kullandı.

## 2. Immutable migration ne demektir?

Mevcut schema zincirinde version 1 ve version 2 migration'ları zaten yayınlanmış geçmişi temsil eder. Bunların SQL metnini yeniden yazmadık. Yeni migration zincirin sonuna eklendi:

```python
SCHEMA_VERSION = 3

SCHEMA_MIGRATIONS: tuple[Migration, ...] = (
    Migration(version=1, statements=(...)),
    Migration(version=2, statements=(...)),
    Migration(version=3, statements=(...)),
)
```

Satır satır anlamı:

1. `SCHEMA_VERSION = 3`, uygulamanın bildiği en güncel schema sürümünü söyler.
2. Version 1 ilk observation omurgasını kurmaya devam eder.
3. Version 2 yalnız `notes` kolonunu eklemeye devam eder.
4. Version 3 yeni Saha Takibi tablolarını ve index'leri ekler.
5. Eski migration metinleri aynı kaldığı için daha önce version 2'ye gelmiş database ile boş database aynı sırayı izler.

Migration runner bütün bekleyen statement'ları `BEGIN IMMEDIATE` transaction'ında çalıştırır. Version 3'ün ortasında hata olursa hem kısmi tablolar hem version 3 satırı rollback olur.

## 3. Fresh v3 ile v2→v3 neden karşılaştırıldı?

İki yol vardır:

```text
Boş database  -> v1 -> v2 -> v3
Mevcut v2     ------------> v3
```

İki yolun sonunda `sqlite_master` içindeki table ve index SQL tanımlarının aynı olması gerekir. Testte iki ayrı geçici database açıldı ve şu signature karşılaştırıldı:

```python
SELECT type, name, tbl_name, sql
FROM sqlite_master
WHERE name NOT LIKE 'sqlite_%'
ORDER BY type, name
```

Bu test yalnız tablo adlarına bakmaz. Index adını, bağlı olduğu tabloyu ve SQLite'ın sakladığı SQL tanımını da karşılaştırır.

Version 2 upgrade testinde ayrıca şu mevcut satırlar migration öncesi ve sonrası tuple olarak birebir karşılaştırıldı:

```text
projects
field_observations
attachments
observation_events
```

Event `payload_json` metni de yeniden serialize edilmedi. Böylece whitespace veya anahtar sırası dahil mevcut payload byte içeriğinin migration tarafından değiştirilmediği kanıtlandı.

## 4. Observation ile project tutarlılığı nasıl korundu?

Bir follow-up observation'a bağlıysa aynı observation'ın projesini taşımalıdır. Yalnız iki ayrı foreign key kullanmak yeterli değildir; bu durumda var olan fakat farklı bir proje kimliği yanlışlıkla eşleşebilir.

Parent tarafta şu composite unique key oluşturuldu:

```sql
CREATE UNIQUE INDEX ux_field_observations_id_project
ON field_observations(id, project_id);
```

Child tarafta iki kolon birlikte referans veriyor:

```sql
CHECK(observation_id IS NULL OR project_id IS NOT NULL),
FOREIGN KEY(observation_id, project_id)
    REFERENCES field_observations(id, project_id)
```

Satır satır anlamı:

1. Observation yoksa `project_id` null olabilir; kayıt kişisel alanda kalır.
2. Observation varsa ilk `CHECK`, project kimliğini zorunlu yapar.
3. Composite foreign key, iki değerin aynı parent satırında birlikte bulunmasını ister.
4. Başka bir geçerli projenin kimliği kullanılsa bile çift observation satırıyla eşleşmeyeceği için insert/update reddedilir.
5. Foreign key'de `ON DELETE CASCADE` yoktur; parent silme geçmiş tracking kayıtlarını sessizce silemez.

## 5. Database CHECK ile domain/application validation farkı

Her iş kuralını SQL içine taşımadık. Katmanların sorumluluğu şöyledir:

| Kural | Domain constructor | SQLite | Gelecek application service |
| --- | --- | --- | --- |
| UUID/UTC/canonical enum | Doğrular | Enum ve temel kolon sınırını korur | Komut girdisini hazırlar |
| `active/waiting` dikkat zamanı | Zorunlu tutar | `NULL` birleşimini `CHECK` ile reddeder | Planlama transition'ını yönetir |
| Observation-project aynı çift | Yalnız observation varsa project ister | Composite foreign key ile gerçek eşleşmeyi korur | Observation'ı okuyup doğru projeyi atar |
| Terminal outcome/zaman | Nesne birlikteliğini doğrular | Bypass'a karşı minimum birlikteliği korur | İzin verilen transition ve event'i yönetir |
| Weekly weekday ilişkisi | Weekly için dolu, diğerleri için boş ister | Relation değerini 1..7 sınırlar | Create/update use-case'ini yönetir |
| Event payload içeriği | JSON object ve deterministic serialization | TEXT ve event enum/sequence sınırı | Revision ve before/after anlamını üretir |

SQLite `CHECK` için önemli ayrıntı üç-değerli mantıktır. SQL koşulu `TRUE`, `FALSE` veya `NULL/UNKNOWN` dönebilir. `CHECK`, yalnız kesin `FALSE` sonucunu reddeder. Bu nedenle terminal outcome kontrolünde yalnız `outcome_type IN (...)` yazmak yeterli değildir:

```sql
status = 'completed'
AND outcome_type IS NOT NULL
AND outcome_type IN ('completed', 'not_required', 'converted_to_observation')
AND completed_at IS NOT NULL
```

`outcome_type IS NOT NULL` açıkça yazıldığı için eksik outcome ile tamamlanmış satır `UNKNOWN` üzerinden constraint'i geçemez.

## 6. Domain-SQLite mapper nasıl çalışır?

Mapper, domain nesnesini SQL parametre sözlüğüne çevirir:

```python
def routine_occurrence_to_row(record: RoutineOccurrence) -> dict[str, object]:
    return {
        "id": record.routine_occurrence_id,
        "routine_template_id": record.routine_template_id,
        "occurrence_local_date": record.occurrence_local_date,
        "scheduled_local_time": record.scheduled_local_time,
        "scheduled_at_utc": record.scheduled_at_utc,
        "status": record.status.value,
        "next_attention_at": record.next_attention_at,
        "outcome_type": (
            record.outcome_type.value if record.outcome_type is not None else None
        ),
        "outcome_note": record.outcome_note,
        "revision": record.revision,
        "created_at": record.created_at,
        "completed_at": record.completed_at,
    }
```

Burada:

- Python enum'u `.value` ile SQLite TEXT değerine dönüşür.
- `None` değeri SQLite `NULL` olur.
- UTC ve yerel tarih metinleri değiştirilmez; domain'de doğrulanmış canonical snapshot korunur.
- Boolean alanlar açıkça `0/1` integer'a çevrilir.

SQLite'tan domain'e dönüşte doğrudan doğrulanmamış bir dict döndürülmez:

```python
return RoutineOccurrence(
    routine_occurrence_id=row["id"],
    routine_template_id=row["routine_template_id"],
    occurrence_local_date=row["occurrence_local_date"],
    scheduled_local_time=row["scheduled_local_time"],
    scheduled_at_utc=row["scheduled_at_utc"],
    status=RoutineOccurrenceStatus(row["status"]),
    next_attention_at=row["next_attention_at"],
    revision=row["revision"],
    created_at=row["created_at"],
    ...
)
```

Domain constructor tekrar çalıştığı için database'te beklenmeyen bir satır varsa hata fail-closed biçimde `InvalidRecordError` sınırına çevrilir.

Event payload okumasında JSON metni de canonical object olarak yeniden doğrulanır. Event geçmişi domain'e döndüğünde `payload` yine immutable mapping olur.

## 7. Repository port ve SQLite adapter ayrımı

Port, storage teknolojisini söylemeden beklenen işlemleri adlandırır:

```python
class FollowUpEventRepositoryPort(Protocol):
    def add(self, record: FollowUpEvent) -> None: ...
    def list_for_follow_up(self, follow_up_id: str) -> list[FollowUpEvent]: ...
```

SQLite adapter bu davranışı SQL ile uygular. Event port'unda `update` veya `delete` bulunmaz. Böylece append-only sözleşme API yüzeyinden de görünür olur.

Ana repository'ler şunları taşır:

```text
add / add_if_absent
get
deterministic list/query
update(..., expected_revision=...)
```

Follow-up ve template `list_by_project_id(None)` sorgusu kişisel çalışma alanını açıkça `WHERE project_id IS NULL` ile okur. `None` değeri “bütün projeler” anlamına gelmez.

## 8. Optimistic revision ve no-op akışı

Update primitive'i önce mevcut kaydı okur:

```python
current = self.get(record.follow_up_id)
_require_current_revision(current.revision, expected_revision, record.follow_up_id)

if replace(record, revision=current.revision) == current:
    return current

_require_next_revision(record.revision, expected_revision)
```

Çalışma sırası:

1. Caller'ın beklediği revision doğrulanır.
2. Database'teki actual revision farklıysa `RevisionConflict` oluşur.
3. Candidate ile current arasındaki tek fark revision ise bu gerçek mutation değildir.
4. No-op çağrı SQL update yapmadan mevcut kaydı döndürür.
5. Gerçek değişiklikte yeni revision tam olarak `expected_revision + 1` olmalıdır.
6. SQL `WHERE id = :id AND revision = :expected_revision` ile ikinci bir yarış savunması sağlar.

Repository ayrıca ilk yakalama metni `capture_text`, `created_at` ve occurrence schedule snapshot alanlarını immutable kabul eder. Kullanıcının sonradan değiştirebildiği `title` ise update ile kalıcılaştırılır.

## 9. Occurrence idempotency nasıl çalışır?

Database doğal anahtarı:

```sql
UNIQUE(routine_template_id, occurrence_local_date)
```

Repository primitive'i:

```python
def add_if_absent(self, record: RoutineOccurrence) -> RoutineOccurrence:
    try:
        self._connection.execute("INSERT INTO routine_occurrences ...", row)
    except sqlite3.IntegrityError as exc:
        existing = self._find_by_template_date(
            record.routine_template_id,
            record.occurrence_local_date,
        )
        if existing is not None:
            return existing
        _raise_integrity_error(exc, "routine occurrence")
    return record
```

Bu bir ensure/backfill orchestration değildir. Yalnız düşük seviyeli idempotent insert primitive'idir:

```text
İlk çağrı      -> INSERT -> yeni occurrence
Aynı anahtar   -> unique conflict -> mevcut occurrence
Başka hata     -> explicit persistence error
```

Yedi günlük pencereyi hesaplama ve hangi günler için bu primitive'in çağrılacağını seçme Task 4/5 application service sorumluluğunda kalır.

## 10. Event sırası neden timestamp veya UUID değildir?

Üç event query'si aynı mantığı kullanır:

```sql
SELECT ...
FROM follow_up_events
WHERE follow_up_id = ?
ORDER BY sequence
```

Sıralamada yalnız `sequence` vardır. Test, sequence 2 event'ini daha erken timestamp ile önce insert eder; sequence 1 event'ini daha geç timestamp ile sonra insert eder. Okuma sonucu yine `[1, 2]` olur.

Her event tablosunda şu unique kural bulunur:

```sql
UNIQUE(aggregate_id, sequence)
```

Aynı aggregate için duplicate sequence `DuplicateRecordError` olur. Farklı aggregate'ler kendi sequence 1 değerlerine sahip olabilir.

## 11. Unit of Work atomikliği

`SQLiteUnitOfWork` altı yeni adapter'ı mevcut connection ile oluşturur:

```python
self._follow_ups = SQLiteFollowUpRepository(connection, is_active=is_active)
self._follow_up_events = SQLiteFollowUpEventRepository(
    connection, is_active=is_active
)
```

Aynı yapı template ve occurrence repository/event çiftleri için de kullanılır. Ayrı connection açılmadığı için şu iki yazı aynı transaction içindedir:

```python
unit_of_work.follow_ups.update(changed, expected_revision=1)
unit_of_work.follow_up_events.add(event)
unit_of_work.commit()
```

Event insert duplicate sequence nedeniyle başarısız olursa context manager açık transaction'ı rollback eder. Test yeniden açılan Unit of Work içinde aggregate revision'ının eski değerinde kaldığını doğrular.

Akış:

```text
BEGIN IMMEDIATE
  -> aggregate INSERT/UPDATE
  -> event INSERT
  -> ikisi başarılıysa COMMIT
  -> herhangi biri hatalıysa ROLLBACK
```

Bu görev event'i hangi use-case'in üreteceğini uygulamaz; yalnız iki yazının birlikte güvenli yapılabileceği transaction altyapısını sağlar.

## 12. Test kodu neyi doğruluyor?

Örnek idempotency testi:

```python
assert unit_of_work.routine_occurrences.add_if_absent(original) == original
assert unit_of_work.routine_occurrences.add_if_absent(duplicate_date) == original
assert unit_of_work.routine_occurrences.list_for_template(TEMPLATE_ID) == [
    original
]
```

Satır satır:

1. İlk çağrı yeni occurrence'ı ekler ve aynı domain kaydını döndürür.
2. İkinci kaydın UUID'si farklı olsa bile template + tarih aynıdır; mevcut ilk kayıt döner.
3. Liste sorgusu database'te yalnız tek satır bulunduğunu kanıtlar.

Örnek transaction rollback testi:

```python
with pytest.raises(DuplicateRecordError):
    with SQLiteUnitOfWork(database_path) as unit_of_work:
        unit_of_work.follow_ups.update(changed, expected_revision=1)
        unit_of_work.follow_up_events.add(duplicate_sequence_event)

with SQLiteUnitOfWork(database_path) as unit_of_work:
    assert unit_of_work.follow_ups.get(FOLLOW_UP_ID) == original
```

İlk blokta aggregate update başarılı görünür, event insert reddedilir ve context çıkışı rollback yapar. İkinci blok yeni connection açarak rollback'in yalnız memory içinde değil gerçek geçici SQLite dosyasında korunduğunu doğrular.

Migration/repository focused testleri şu alanları kapsar:

- fresh v3 ve v2→v3 aynı schema;
- v2 verileri ve event payload'ı birebir korunur;
- migration hatası kısmi tablo/version bırakmaz;
- composite observation-project foreign key çalışır;
- `active/waiting + NULL` dikkat zamanı reddedilir;
- terminal follow-up outcome birlikteliği korunur;
- template weekday relation round-trip/update olur;
- occurrence template+tarih idempotency ve database unique kuralı çalışır;
- üç event ailesi yalnız sequence ile sıralanır ve duplicate sequence reddeder;
- repository yüzeyinde hard delete/event update yoktur;
- bütün tracking foreign key'lerinde delete action `NO ACTION` kalır;
- aggregate + event commit/rollback atomiktir.

## 13. Teknik karar tablosu

| Konu | Seçim | Neden |
| --- | --- | --- |
| Schema değişimi | Tek version 3 migration | Eski migration geçmişini immutable tutmak |
| Domain dönüşümü | Ayrı açık mapper modülü | SQL kolon adları ile domain alanlarını görünür ayırmak |
| Repository sözleşmesi | Protocol port + SQLite adapter | Application sınırını storage ayrıntısından ayırmak |
| Weekday saklama | Relation table | Bir template'in birden fazla ISO weekday değerini normalize tutmak |
| Occurrence tekrar insert | `add_if_absent` | Restart/yarış durumunda duplicate satır üretmemek |
| Event sırası | Yalnız `sequence` | Timestamp/UUID tie-breaker belirsizliğini kaldırmak |
| Delete davranışı | API yok, cascade yok | Audit/geçmiş kaybını önlemek |
| Transaction | Mevcut Unit of Work connection'ı | Aggregate ve event'i atomik tutmak |
| Gerçek data root | Dokunulmadı | Migration'ı yalnız izole test database'lerinde doğrulamak |

## 14. Şunu şöyle yaptık ki...

Schema v3'ü eski migration'ları değiştirerek değil yeni immutable adım olarak ekledik ki hem yeni kurulum hem mevcut version 2 kullanıcı verisi aynı güvenli sonuca gelsin.

Observation ve project kimliklerini composite foreign key ile birlikte bağladık ki iki ayrı geçerli kimliğin yanlış bir çift oluşturması repository bypass edildiğinde bile kalıcılaşmasın.

SQLite satırını doğrudan dict olarak dışarı vermek yerine domain constructor'ına geri taşıdık ki kalıcı verideki beklenmeyen bir bozulma sessizce application katmanına yayılmasın.

Occurrence insert'ini template + yerel tarih anahtarında idempotent yaptık ki sonraki lazy backfill/restart orchestration'ı aynı günü tekrar hesapladığında duplicate occurrence üretmesin.

Event repository'lerine update/delete koymadık ve okumayı yalnız sequence ile yaptık ki geçmiş hem append-only hem deterministik kalsın.

Bütün yeni adapter'ları aynı Unit of Work connection'ına bağladık ki aggregate değişip event yazılamazsa ya da event yazılıp aggregate değişemezse yarım transaction kalmasın.

Application service, UI, backup ve export davranışını bu adıma eklemedik ki Task 3/5 yalnız schema ve persistence sözleşmesini küçük, okunabilir ve executable biçimde tamamlasın.

## 15. Çalıştırılan kalite kontrolleri

Focused migration/repository komutu:

```text
python -m pytest -rs tests/test_persistence_migrations.py tests/test_field_tracking_persistence.py tests/test_sqlite_repositories.py tests/test_sqlite_unit_of_work.py
```

Sonuç:

```text
62 passed
```

Tam regression komutu:

```text
python -m pytest -rs
```

Sonuç:

```text
788 passed, 7 skipped
```

Yedi skip, Windows ortamında symlink oluşturma ayrıcalığı bulunmayan mevcut koruma testleridir. Bu görevden kaynaklanan failure kalmadı.

Syntax ve diff kontrolleri:

```text
python -m compileall -q app scripts
git diff --check
```

Her iki komut da başarılı ve çıktısız tamamlandı. Testler yalnız geçici database kullandı; repo `exports/` alanına, backup/ZIP artifact'lerine veya gerçek kullanıcı data root'una çıktı yazılmadı.
