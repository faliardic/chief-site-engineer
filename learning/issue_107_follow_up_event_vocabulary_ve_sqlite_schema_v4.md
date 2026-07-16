# Issue 107 - Follow-up Event Vocabulary ve SQLite Schema v4

## 1. Bu adımda ne yaptık?

Saha Takibi için gelecekte yazılacak `FollowUpApplicationService` üç mutation adı taşıyordu:

```text
update_details
move_to_inbox
set_project
```

Fakat mevcut event sözlüğünde bu işlemlerin anlamını doğrudan karşılayan event türleri yoktu. Yanlış bir event adını yeniden kullanmak, geçmişi okuyan kişiye yanlış bilgi verirdi. Bu nedenle yalnız şu üç event türünü ekledik:

```text
follow_up.details_updated
follow_up.moved_to_inbox
follow_up.project_changed
```

Bu adımın sınırı dardır:

- domain enum sözlüğü genişledi;
- SQLite schema version 4 oldu;
- `follow_up_events` CHECK allowed list'i genişledi;
- migration ve repository testleri genişledi;
- application service, UI, backfill ve notification yazılmadı.

Gerçek kullanıcı database'i kullanılmadı. Bütün SQLite migration testleri pytest `tmp_path` altındaki geçici dosyalarda çalışır.

## 2. Event vocabulary neden ayrı bir sözleşmedir?

Event vocabulary, geçmişte meydana gelen değişikliklerin izin verilen ad kümesidir. Event adı yalnız teknik bir string değildir; iş anlamı taşır.

Örneğin şu iki işlem aynı değildir:

```text
follow_up.rescheduled
follow_up.moved_to_inbox
```

İlkinde kayıt için yeni bir dikkat zamanı vardır. İkincisinde plan kaldırılır, kayıt Unutma Kutusu'na döner ve `next_attention_at` null olur. İkinci işlem için `rescheduled` yazılsaydı geçmiş, gerçekte olmayan yeni bir plan varmış gibi okunabilirdi.

Domain kodu şu şekilde genişledi:

```python
class FollowUpEventType(str, Enum):
    CREATED = "follow_up.created"
    SCHEDULED = "follow_up.scheduled"
    RESCHEDULED = "follow_up.rescheduled"
    WAITING_STARTED = "follow_up.waiting_started"
    COMPLETED = "follow_up.completed"
    CANCELLED = "follow_up.cancelled"
    REOPENED = "follow_up.reopened"
    OBSERVATION_LINKED = "follow_up.observation_linked"
    CONVERTED_TO_OBSERVATION = "follow_up.converted_to_observation"
    DETAILS_UPDATED = "follow_up.details_updated"
    MOVED_TO_INBOX = "follow_up.moved_to_inbox"
    PROJECT_CHANGED = "follow_up.project_changed"
```

Satır satır önemli noktalar:

1. Sınıf hâlâ `str, Enum` kalıtımı kullanır; enum değerleri JSON ve SQLite TEXT sınırında string olarak kullanılabilir.
2. Eski dokuz üye aynı sırada ve aynı değerle kalır.
3. Yeni üç üye yalnız sona eklenir; eski tuple sırası değişmez.
4. Python adı `DETAILS_UPDATED`, kalıcı dış değer `follow_up.details_updated` olur.
5. `MOVED_TO_INBOX`, planın kaldırılmasını açıkça adlandırır.
6. `PROJECT_CHANGED`, nullable proje bağlantısındaki önce/sonra değişimini adlandırır.

Allowed tuple elle ikinci kez yazılmadı:

```python
FOLLOW_UP_EVENT_TYPES = tuple(value.value for value in FollowUpEventType)
```

Bu comprehension enum üyelerini tanım sırasıyla gezer. Yeni enum değeri eklendiğinde tuple otomatik genişler. Böylece enum ile ayrı allowed-list arasında unutulmuş senkronizasyon riski azalır.

## 3. Üç payload sözleşmesi nasıl çalışır?

### 3.1 Ayrıntı güncelleme

Örnek payload:

```python
{
    "revision": 2,
    "changed_fields": ["description", "title"],
}
```

Kurallar:

- `revision`, mutation sonrasındaki aggregate revision'ıdır.
- `changed_fields` yalnız gerçekten değişen alanları taşır.
- Liste alfabetik sıralı ve benzersiz string değerlerden oluşur.
- İlk yakalama kanıtı `capture_text` immutable olduğu için bu listede bulunamaz.
- Bütün follow-up snapshot'ı payload'a kopyalanmaz.

Deterministic JSON sonucu:

```json
{"changed_fields":["description","title"],"revision":2}
```

Burada object anahtarları serializer tarafından canonical sıralanır. Liste sırası ise application service tarafından anlamlı ve deterministic biçimde üretilmelidir.

### 3.2 Unutma Kutusu'na taşıma

Örnek payload:

```python
{
    "revision": 3,
    "from_status": "active",
    "previous_next_attention_at": "2026-07-15T08:00:00Z",
}
```

Bu payload neden önceki değeri taşır?

Mutation sonrasında ana kayıt şuna dönüşür:

```text
status = inbox
next_attention_at = NULL
```

Önceki status ve dikkat zamanı ana kayıttan silinmiş olur. Append-only event, geçmişte planın ne olduğunu korur.

### 3.3 Proje değiştirme

Örnek payload:

```python
{
    "revision": 4,
    "from_project_id": None,
    "project_id": "8b18ce4a-142f-4ca7-bac0-6fd98ce19d27",
}
```

Python `None`, JSON içinde `null` olur:

```json
{"from_project_id":null,"project_id":"8b18ce4a-142f-4ca7-bac0-6fd98ce19d27","revision":4}
```

Null değer atlanmaz; çünkü “önceden projesizdi” bilgisi event anlamının bir parçasıdır. Observation bağlı follow-up'ta proje tek başına değiştirilemez; bu lifecycle kontrolü gelecek application service sorumluluğudur.

## 4. Neden SQLite table rebuild kullandık?

SQLite, mevcut bir tablodaki `CHECK(event_type IN (...))` metnini doğrudan düzenleyen genel bir `ALTER CONSTRAINT` komutu sunmaz. Eski migration'ı değiştirmek de yasaktır; çünkü o migration daha önce uygulanmış database'lerin tarihidir.

Bu nedenle yeni v4 migration şu yolu izler:

```text
follow_up_events_v4 oluştur
-> eski satırları aynen kopyala
-> eski follow_up_events tablosunu düşür
-> replacement tabloyu follow_up_events adıyla yeniden adlandır
```

Yeni tablo tanımının özü:

```sql
CREATE TABLE follow_up_events_v4 (
    id TEXT PRIMARY KEY,
    follow_up_id TEXT NOT NULL REFERENCES follow_up_items(id),
    sequence INTEGER NOT NULL CHECK(sequence >= 1),
    event_type TEXT NOT NULL CHECK(event_type IN (
        'follow_up.created',
        'follow_up.scheduled',
        'follow_up.rescheduled',
        'follow_up.waiting_started',
        'follow_up.completed',
        'follow_up.cancelled',
        'follow_up.reopened',
        'follow_up.observation_linked',
        'follow_up.converted_to_observation',
        'follow_up.details_updated',
        'follow_up.moved_to_inbox',
        'follow_up.project_changed'
    )),
    actor TEXT NOT NULL CHECK(length(trim(actor)) > 0),
    occurred_at TEXT NOT NULL,
    payload_json TEXT NOT NULL,
    UNIQUE(follow_up_id, sequence)
)
```

Satır satır sözleşme:

1. `id TEXT PRIMARY KEY`, event kimliğini ve primary key davranışını korur.
2. `follow_up_id ... REFERENCES follow_up_items(id)`, aynı parent foreign key'i korur.
3. `sequence >= 1`, sıfır veya negatif event sırasını reddeder.
4. `event_type IN (...)`, yalnız eski dokuz ve yeni üç türü kabul eder.
5. `actor` null olamaz ve whitespace-only olamaz.
6. `occurred_at` ve `payload_json` zorunlu kalır.
7. `UNIQUE(follow_up_id, sequence)`, aynı aggregate içinde iki event'in aynı sırayı kullanmasını engeller.
8. Foreign key'e `ON DELETE CASCADE` eklenmez; parent silme geçmişi sessizce silemez.

Kopyalama SQL'i şöyledir:

```sql
INSERT INTO follow_up_events_v4 (
    id, follow_up_id, sequence, event_type, actor, occurred_at,
    payload_json
)
SELECT
    id, follow_up_id, sequence, event_type, actor, occurred_at,
    payload_json
FROM follow_up_events
```

Burada `payload_json` parse edilmez ve yeniden serialize edilmez. SQL TEXT değeri doğrudan yeni satıra taşınır. Böylece boşluklar ve JSON anahtar sırası dâhil eski metin korunur.

## 5. Immutable migration ve rollback akışı

Migration zinciri artık kavramsal olarak şöyledir:

```python
SCHEMA_VERSION = 4

SCHEMA_MIGRATIONS = (
    Migration(version=1, statements=(...)),
    Migration(version=2, statements=(...)),
    Migration(version=3, statements=(...)),
    Migration(version=4, statements=(...)),
)
```

V1, v2 ve v3 statement içerikleri değiştirilmedi. V4 yalnız sona eklendi.

Migration runner şu transaction sınırını kullanır:

```python
connection.execute("BEGIN IMMEDIATE")
for migration in migrations:
    for statement in migration.statements:
        connection.execute(statement)
    connection.execute(
        "INSERT INTO schema_migrations (version, applied_at) VALUES (?, ?)",
        (...),
    )
connection.commit()
```

Bir statement hata verirse:

```python
except Exception:
    if connection.in_transaction:
        connection.rollback()
    raise
```

Bu yüzden v4 içinde create, copy, drop ve rename bitmiş görünse bile version satırından önce veya sonra aynı transaction'da bir hata oluşursa bütün DDL işlemleri rollback edilir. Test, hata sonrasında eski v3 tablo SQL'ini, event satırını ve `[1, 2, 3]` version listesini yeniden okuyarak bunu kanıtlar.

## 6. Mapper ve repository neden değişmedi?

Mevcut mapper event türünü genel olarak enum değerinden alır:

```python
def _event_to_row(record, aggregate_column, aggregate_id):
    return {
        "id": record.event_id,
        aggregate_column: aggregate_id,
        "sequence": record.sequence,
        "event_type": record.event_type.value,
        "actor": record.actor,
        "occurred_at": record.occurred_at,
        "payload_json": record.payload_json,
    }
```

Okuma da aynı enum sınıfını kullanır:

```python
event_type=FollowUpEventType(row["event_type"])
```

Enum yeni türleri bildiği için mapper'a özel `if/elif` eklemek gerekmez.

Repository listesi de türden bağımsızdır:

```sql
SELECT id, follow_up_id, sequence, event_type, actor, occurred_at, payload_json
FROM follow_up_events
WHERE follow_up_id = ?
ORDER BY sequence
```

Bu nedenle aynı timestamp ve ters UUID sırası olsa bile tek belirleyici `sequence` olur. Event repository'sine `update`, `delete` veya `allocate_sequence` method'u eklenmedi.

## 7. Testler neyi doğruluyor?

### 7.1 Domain vocabulary ve JSON

Tuple testi eski sıranın korunup yeni türlerin sona eklendiğini exact olarak doğrular:

```python
assert FOLLOW_UP_EVENT_TYPES == (
    "follow_up.created",
    ...,
    "follow_up.converted_to_observation",
    "follow_up.details_updated",
    "follow_up.moved_to_inbox",
    "follow_up.project_changed",
)
```

Set eşitliği, enum ile türetilmiş tuple arasında eksik veya fazladan değer olmadığını doğrular:

```python
assert set(FOLLOW_UP_EVENT_TYPES) == {
    member.value for member in FollowUpEventType
}
```

Payload testi üç örneğin canonical JSON sonucunu exact string olarak karşılaştırır. Mevcut unknown event testi de `follow_up.unknown` değerinin fail-closed reddedildiğini korur.

### 7.2 Fresh v4 ve v3→v4 schema signature

İki geçici database kurulur:

```text
fresh     : v1 -> v2 -> v3 -> v4
upgraded  : v1 -> v2 -> v3, sonra v4
```

İkisinde şu sorgu sonucu karşılaştırılır:

```sql
SELECT type, name, tbl_name, sql
FROM sqlite_master
WHERE name NOT LIKE 'sqlite_%'
ORDER BY type, name
```

Bu yalnız tablo adlarını değil, saklanan table/index SQL tanımlarını da karşılaştırır.

### 7.3 Byte-for-byte payload korunumu

V3 fixture'a canonical olmayan boşluk taşıyan şu payload yazılır:

```python
payload_json = '{ "title": "Kalıp", "revision": 1 }'
```

V4 sonrasında aynı kolon yeniden okunur:

```python
assert row_after == row_before
assert row_after[-1] == payload_json
```

Bu test, migration'ın JSON'u normalize etmediğini açıkça gösterir.

### 7.4 Constraint testleri

Geçici v4 database'te şu durumlar doğrulanır:

- üç yeni event türü insert edilir ve sequence sırasında okunur;
- `follow_up.unknown` CHECK tarafından reddedilir;
- aynı `(follow_up_id, sequence)` çifti reddedilir;
- olmayan follow-up foreign key'i reddedilir;
- whitespace-only actor reddedilir;
- child event varken follow-up delete işlemi reddedilir; cascade oluşmaz.

### 7.5 Tam rebuild rollback testi

Test, gerçek v4 statement'larının sonuna bilinçli bozuk SQL ekler:

```python
failing_v4 = Migration(
    version=4,
    statements=(
        *SCHEMA_MIGRATIONS[3].statements,
        "CREATE TABLE broken_v4_table (",
    ),
)
```

Hata, replacement tablo rename edildikten sonra oluşur. Buna rağmen test şunları bekler:

```python
assert table_sql_after == table_sql_before
assert row_after == row_before
assert versions == [1, 2, 3]
assert temporary_table_count == 0
```

Bu, rollback testinin yalnız ilk statement hatasını değil, rebuild'in tamamına yakın bir noktadaki hatayı da kapsamasını sağlar.

## 8. Teknik karar tablosu

| Karar | Seçilen yaklaşım | Neden | Bilinçli olarak yapılmayan |
| --- | --- | --- | --- |
| Event adları | Üç yeni ve açık mutation adı | Audit anlamı yanlış mevcut adlara yüklenmesin | `rescheduled` veya `updated` gibi belirsiz adları yeniden kullanmak |
| Enum sırası | Yeni değerleri sona eklemek | Eski tuple sözleşmesini korumak | Mevcut değerleri alfabetik yeniden sıralamak |
| SQLite değişimi | Tek v4 table rebuild migration | CHECK list'i güvenle genişletmek | V3 SQL metnini geriye dönük düzenlemek |
| Veri kopyası | Açık yedi kolonlu `INSERT ... SELECT` | Alan ve payload metnini aynen korumak | JSON parse/serialize veya data backfill |
| Repository | Mevcut genel mapper ve add/list | Yeni enum değerleri zaten genel akıştan geçiyor | Tür başına repository method'u eklemek |
| Sequence | Mevcut caller/application sorumluluğu | Bu görev vocabulary/schema preflight'ıdır | Allocator API eklemek |
| Service | Henüz yok | Faz 1'i küçük ve test edilebilir tutmak | Command/query/backfill/UI yazmak |
| Backup/export | Kod değişmedi | Format ve resmî çıktı sınırı ayrı Faz 2 işidir | Manifest alanı veya tracking export eklemek |

## 9. Kodun çalışma akışı

Yeni event gelecekte yazıldığında katmanlar şöyle çalışacaktır:

```text
Gelecek application service mutation'ı doğrular
-> yeni FollowUpItem revision nesnesini üretir
-> uygun FollowUpEventType seçer
-> minimum payload'ı oluşturur
-> FollowUpEvent deterministic JSON üretir
-> Unit of Work aggregate update yapar
-> aynı transaction'da event repository add yapar
-> commit
```

Bugün bu görevin uyguladığı bölüm:

```text
Enum yeni adı kabul eder
-> mapper enum.value değerini SQL parametresine koyar
-> schema v4 CHECK yeni adı kabul eder
-> repository sequence sırasıyla geri okur
-> mapper string'i aynı enum üyesine çevirir
```

Henüz uygulanmayan bölüm:

```text
command validation
optimistic mutation orchestration
no-op kararı
changed_fields üretimi
event sequence atama
lazy backfill
web/API/UI
```

## 10. Yeni teknik terimler

- **Event vocabulary:** Kalıcı event kayıtlarında izin verilen, her biri belirli iş anlamı taşıyan ad kümesi.
- **SQLite table rebuild:** Doğrudan değiştirilemeyen tablo constraint'ini güncellemek için replacement tablo oluşturma, veri kopyalama, eski tabloyu düşürme ve replacement'ı yeniden adlandırma tekniği.
- **Schema signature:** `sqlite_master` içindeki tablo/index adları ve SQL tanımlarından üretilen, iki migration yolunun aynı şemaya ulaştığını karşılaştıran yapı.
- **Byte-for-byte korunma:** Metnin parse edilmeden veya yeniden serialize edilmeden aynı karakter dizisi olarak taşınması.
- **Replacement table:** Rebuild sırasında yeni constraint'lerle oluşturulan geçici yeni tablo.

Kalıcı terimler `learning/GLOSSARY.md` dosyasına da eklendi.

## 11. Şunu şöyle yaptık ki...

- Üç event'i enum'un sonuna ekledik ki eski event sırası ve anlamı değişmesin.
- `FOLLOW_UP_EVENT_TYPES` tuple'ını enum'dan türetmeye devam ettik ki iki allowed-list birbirinden kopmasın.
- `capture_text` alanını `changed_fields` dışında tuttuk ki ilk saha yakalaması sonradan değiştirilmiş gibi görünmesin.
- Nullable proje değerlerini JSON `null` olarak koruduk ki “projesizden projeye” ve “projeden projesize” geçişler eksik bilgi bırakmasın.
- V1/v2/v3 SQL metinlerini değiştirmeyip v4'ü sona ekledik ki daha önce migrate edilmiş database'lerin tarihi yeniden yazılmasın.
- `follow_up_events` tablosunu transaction içinde yeniden kurduk ki yalnız CHECK allowed list'i genişlesin ve diğer schema davranışları sabit kalsın.
- Payload metnini `INSERT ... SELECT` ile aynen taşıdık ki whitespace ve anahtar sırası dâhil mevcut audit verisi değişmesin.
- Bozuk SQL'i rebuild statement'larının sonuna ekleyen rollback testi yazdık ki drop/rename sonrasında bile tam geri dönüş kanıtlansın.
- Mapping ve repository kodunu değiştirmedik ki gerekli olmayan yeni dallanma ve API karmaşası oluşmasın.
- Application service yazmadık ki Issue #107 vocabulary/schema preflight sınırında küçük, anlaşılır ve test edilebilir kalsın.
