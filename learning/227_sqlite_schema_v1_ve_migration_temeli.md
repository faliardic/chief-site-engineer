# Adım 227 - SQLite Schema v1 ve Migration Temeli

## 1. Bu adımda ne yaptık?

Bu adımda Chief Site Engineer için ilk kalıcı veri omurgasını kurduk.

- Python'un kendi `sqlite3` modülüyle SQLite bağlantısı açtık.
- `schema_migrations`, `projects`, `field_observations`, `attachments` ve
  `observation_events` tablolarını schema v1 içinde tanımladık.
- Migration'ı transaction içinde ve ikinci çalıştırmada güvenli olacak şekilde
  yazdık.
- UUID, UTC timestamp, observation status, `closed_at` ve başlangıç revision
  sözleşmelerini açık Python fonksiyonlarıyla ifade ettik.
- Gerçek temporary SQLite dosyaları kullanan testlerle constraint'leri ve rollback
  davranışını doğruladık.

Bu adımın ana çıktısı bir CRUD repository değildir. Sonraki persistence
katmanlarının dayanacağı güvenli şema ve sözleşme temelidir.

## 2. Neden bunu yaptık?

### Uygulama açısından

Bellek içindeki repository uygulama kapanınca verisini kaybeder. Resmî saha
kayıtlarının proje, gözlem, ek dosya ve olay ilişkileriyle kalıcı tutulması için
bir veritabanı gerekir. Şema kurulurken status, foreign key, revision ve dosya
metadata kuralları tanımlanmazsa hatalı veri sonraki katmanlara yayılır.

### Şantiye şefi açısından

Bu yapı, saha defterinin yalnız açık olduğu sürece hatırlaması yerine kayıtların
dosyalanmasına benzer. Projesi olmayan bir gözlem, gözlemi olmayan bir fotoğraf
veya kapanış zamanı olmayan kapalı kayıt artık resmî depoya sessizce giremez.

## 3. Hangi dosyalara dokunduk?

```text
app/models.py
app/persistence/__init__.py
app/persistence/contracts.py
app/persistence/migrations.py
app/persistence/schema.py
tests/test_field_observation_storage_contracts.py
tests/test_persistence_migrations.py
docs/adr/ADR-001-sqlite-persistence-and-managed-attachments.md
docs/project_decisions.md
learning/227_sqlite_schema_v1_ve_migration_temeli.md
learning/GLOSSARY.md
```

- `app/models.py`: Eski `FieldObservationRecord` modeline geriye uyumlu
  `revision = 1` alanını ekler.
- `app/persistence/contracts.py`: UUID, UTC, status ve kapanış ilişkisi gibi
  Python seviyesindeki sözleşmeleri tutar.
- `app/persistence/schema.py`: Değişmez schema v1 SQL ifadelerini ve migration
  veri modelini tutar.
- `app/persistence/migrations.py`: Bağlantı ve transaction tabanlı migration
  runner'ını içerir.
- `app/persistence/__init__.py`: Persistence API'sinin dışarı açılan isimlerini
  tek yerde toplar.
- `tests/test_persistence_migrations.py`: Gerçek geçici database dosyasında şema
  ve constraint davranışlarını sınar.
- `tests/test_field_observation_storage_contracts.py`: UUID, UTC ve observation
  state sözleşmelerini sınar.
- ADR dosyası kalıcı mimari kararın tek ayrıntılı kaynağıdır.
- Proje kararları ve glossary dosyaları kısa karar/terim envanterini günceller.

## 4. Kod blokları üzerinden açıklama

### 4.1. Canonical UUID sözleşmesi

Gerçek kod:

```python
def validate_record_id(value: str) -> str:
    """Return a canonical UUID string or raise ``ValueError``."""

    try:
        parsed_value = UUID(value)
    except (AttributeError, TypeError, ValueError) as exc:
        raise ValueError("record id must be a canonical UUID string") from exc

    if str(parsed_value) != value:
        raise ValueError("record id must be a canonical UUID string")
    return value
```

Bu kodun amacı yeni kalıcı kayıt kimliğinin tek bir açık biçimde olmasını
sağlamaktır.

Satır satır açıklama:

- `def validate_record_id(value: str) -> str`: Girdinin ve başarılı dönüş
  değerinin string olduğunu anlatır.
- `UUID(value)`: Python'un standart UUID parser'ıyla metni ayrıştırır.
- `except (...)`: Bozuk metin veya yanlış tip geldiğinde düşük seviyeli hatayı
  anlaşılır bir `ValueError` olarak çevirir.
- `str(parsed_value) != value`: `{...}`, büyük harf veya baş/son boşluk gibi aynı
  UUID'nin farklı yazımlarını reddeder.
- `return value`: Doğrulanan canonical değeri değiştirmeden döndürür.

Sunu şöyle yaptık ki aynı kimlik farklı metin biçimleriyle iki ayrı kayıt gibi
görünmesin.

Şantiye karşılığı: Aynı tutanak numarasının bir yerde büyük, başka yerde süslü
parantezli yazılması yerine tek resmî numara formatı kullanılmasıdır.

### 4.2. UTC timestamp serialization

Gerçek kod:

```python
def serialize_utc_timestamp(value: datetime) -> str:
    """Serialize a timezone-aware ``datetime`` as an ISO 8601 UTC string."""

    if value.tzinfo is None or value.utcoffset() is None:
        raise ValueError("timestamp must be timezone-aware")

    utc_value = value.astimezone(timezone.utc)
    return utc_value.isoformat().replace("+00:00", "Z")
```

Satır satır açıklama:

- `tzinfo` ve `utcoffset()` kontrolleri, saat dilimi bilinmeyen naive datetime
  değerini reddeder.
- `astimezone(timezone.utc)`, örneğin İstanbul saatini aynı anın UTC karşılığına
  dönüştürür.
- `isoformat()`, tarihi makine-okunabilir ISO 8601 metnine çevirir.
- `replace("+00:00", "Z")`, UTC bilgisini kısa ve canonical `Z` son ekiyle yazar.

Sunu şöyle yaptık ki farklı saat dilimlerinden gelen saha olayları tek zaman
çizelgesinde doğru sıralanabilsin.

### 4.3. Migration transaction'ı

Gerçek kod:

```python
try:
    connection.execute("BEGIN IMMEDIATE")
    connection.execute(CREATE_MIGRATION_TABLE_SQL)
    applied_versions = {
        row[0]
        for row in connection.execute(
            "SELECT version FROM schema_migrations ORDER BY version"
        )
    }
```

Satır satır açıklama:

- `try`: Migration sırasında oluşabilecek tüm hataları tek güvenlik sınırında
  yakalamaya başlar.
- `BEGIN IMMEDIATE`: SQLite yazma transaction'ını açıkça başlatır.
- `CREATE_MIGRATION_TABLE_SQL`: Sürüm kayıt tablosunu yoksa oluşturur.
- `SELECT version`: Daha önce uygulanmış migration sürümlerini okur.
- Set comprehension `{...}`: Uygulanmış sürümlerde hızlı membership kontrolü
  için benzersiz bir set üretir.

Migration'ın SQL uygulama bölümü:

```python
for migration in migrations:
    if migration.version in applied_versions:
        continue
    for statement in migration.statements:
        connection.execute(statement)
    connection.execute(
        "INSERT INTO schema_migrations (version, applied_at) VALUES (?, ?)",
        (
            migration.version,
            serialize_utc_timestamp(datetime.now(timezone.utc)),
        ),
    )
    applied_versions.add(migration.version)
```

- Dış `for`, migration'ları sürüm sırasıyla gezer.
- `continue`, daha önce uygulanmış sürümü tekrar çalıştırmaz; idempotency sağlar.
- İç `for`, o migration'ın SQL ifadelerini sırayla uygular.
- Parametreli `INSERT`, sürüm ve uygulanma zamanını güvenli biçimde kaydeder.
- Sürüm kaydı yalnız tüm SQL ifadeleri başarılı olduktan sonra eklenir.

Hata güvenliği:

```python
except Exception:
    if connection.in_transaction:
        connection.rollback()
    raise
else:
    connection.commit()
```

- Herhangi bir hata olursa `rollback()` o transaction içindeki tablo ve sürüm
  değişikliklerini geri alır.
- `raise`, asıl hatayı çağıran koda yeniden bildirir; hata saklanmaz.
- Hata yoksa `commit()` bütün migration'ı kalıcılaştırır.

Sunu şöyle yaptık ki bir migration yarıda kalırsa “tabloların yarısı var ama
sürüm kaydı yok” gibi belirsiz bir database oluşmasın.

### 4.4. Veritabanı constraint'leri

Gerçek schema parçası:

```sql
status TEXT NOT NULL
    CHECK(status IN ('open', 'tracking', 'closed')),
closed_at TEXT,
revision INTEGER NOT NULL DEFAULT 1 CHECK(revision >= 1),
CHECK(
    (status = 'closed' AND closed_at IS NOT NULL)
    OR
    (status <> 'closed' AND closed_at IS NULL)
)
```

Satır satır açıklama:

- `NOT NULL`: Status boş bırakılamaz.
- İlk `CHECK`: Yalnız üç observation status değerini kabul eder.
- `DEFAULT 1`: Yeni kaydın ilk revision değerini otomatik verir.
- `CHECK(revision >= 1)`: Sıfır veya negatif revision'ı reddeder.
- Son `CHECK`: `closed` ile `closed_at` alanının birlikte tutarlı olmasını zorlar.

Sunu şöyle yaptık ki yalnız Python kodu değil, veritabanının kendisi de temel
domain kurallarını korusun.

### 4.5. Modelde başlangıç revision değeri

Gerçek kod:

```python
@dataclass
class FieldObservationRecord:
    # Mevcut alanlar burada devam eder.
    is_archived: bool = False
    revision: int = 1
```

- `revision: int = 1`, alan verilmediğinde gözlem nesnesini ilk sürümde başlatır.
- Alan sona eklendiği için mevcut constructor çağrıları bozulmaz.
- Bu adım update sırasında revision artırmaz; o davranış sonraki application
  service/repository görevidir.

## 5. Test kodları üzerinden açıklama

### 5.1. Failure injection ve rollback testi

Gerçek test kodu:

```python
def test_migration_failure_rolls_back_schema_and_version_record(tmp_path: Path) -> None:
    connection = connect_database(tmp_path / "failure.sqlite3")
    failing_migration = Migration(
        version=1,
        statements=(
            "CREATE TABLE partial_table (id TEXT PRIMARY KEY)",
            "CREATE TABLE broken_table (",
        ),
    )

    try:
        with pytest.raises(sqlite3.OperationalError):
            migrate_database(connection, migrations=(failing_migration,))

        remaining_tables = list(
            connection.execute(
                "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name"
            )
        )
    finally:
        connection.close()

    assert remaining_tables == []
```

Satır satır açıklama:

- `tmp_path / "failure.sqlite3"`: Repo dışında gerçek bir geçici SQLite dosyası
  kullanır; mock değildir.
- İlk statement geçerli bir tablo oluşturur.
- İkinci statement bilerek bozuk SQL'dir; buna failure injection denir.
- `pytest.raises(...)`, beklenen SQLite hatasının gerçekten oluştuğunu doğrular.
- `sqlite_master` sorgusu migration sonrasında kalan tabloları listeler.
- `assert remaining_tables == []`, ilk tablonun ve migration sürüm tablosunun da
  rollback edildiğini kanıtlar.

Sunu şöyle yaptık ki yalnız başarılı yolu değil, elektrik kesintisi veya bozuk
migration benzeri yarım kalma riskini de test edelim.

### 5.2. Foreign key testi

Gerçek test özü:

```python
assert database.execute("PRAGMA foreign_keys").fetchone()[0] == 1

with pytest.raises(sqlite3.IntegrityError):
    _insert_observation(
        database,
        project_id="c71c2794-160f-4c6a-b082-a840b60bf427",
    )
```

- İlk assert foreign key enforcement'ın bağlantıda açık olduğunu kanıtlar.
- Database içinde bulunmayan project ID ile observation eklenmeye çalışılır.
- `IntegrityError`, ilişkisiz kaydın veritabanı tarafından reddedildiğini gösterir.

Diğer testler fresh migration, ikinci kez güvenli çalıştırma, v1 sürüm kaydı,
duplicate primary key, geçersiz status, revision alt sınırı, negatif attachment
size, duplicate relative path ve `closed`/`closed_at` tutarsızlığını sınar.

## 6. Kodun çalışma akışı

```text
Database yolu alınır
-> sqlite3 bağlantısı açılır
-> PRAGMA foreign_keys = ON uygulanır ve doğrulanır
-> migrate_database çağrılır
-> migration listesi sıralı/benzersiz mi kontrol edilir
-> BEGIN IMMEDIATE ile transaction başlar
-> schema_migrations tablosu yoksa oluşturulur
-> uygulanmış sürümler okunur
-> v1 uygulanmışsa atlanır
-> v1 uygulanmamışsa domain tabloları sırayla oluşturulur
-> v1 ve UTC applied_at kaydı eklenir
-> başarıda commit yapılır
-> hatada rollback yapılır ve hata yeniden yükseltilir
```

Şema kurulduktan sonraki insert akışı:

```text
Uygulama UUID/UTC/state sözleşmelerini doğrular
-> SQL insert gönderilir
-> SQLite foreign key, unique ve CHECK constraint'lerini uygular
-> geçerliyse kayıt yazılır
-> geçersizse IntegrityError oluşur
```

## 7. Yeni öğrenilen yazılım kavramları

### Migration

Database şemasını bir sürümden sonraki sürüme taşıyan sıralı değişikliktir.

Bu projedeki karşılığı: `Migration(version=1, statements=(...))` schema v1
tablolarını kurar.

Şantiye benzetmesi: Revizyon numarası belli uygulama projesine göre kontrollü
imalat yapmak gibidir.

### Transaction ve atomicity

Transaction, bir grup veritabanı işlemini tek bütün olarak ele alır. Atomicity,
bu grubun ya tamamen olması ya da hiç olmaması özelliğidir.

Bu projedeki karşılığı: Tablolar ve v1 sürüm kaydı aynı transaction içindedir.

Şantiye benzetmesi: Bir teslim tutanağının ekleriyle birlikte geçerli olması;
yarım imzalı hâlin resmî teslim sayılmaması gibidir.

### Idempotency

Aynı işlemin tekrar çalıştırıldığında ilk başarılı sonuçtan farklı veya bozuk bir
durum oluşturmamasıdır.

Bu projedeki karşılığı: `migrate_database(connection)` ikinci çağrıda v1'i atlar.

### Optimistic concurrency ve revision

Optimistic concurrency, aynı kaydı iki işlem güncellerken kilidi uzun süre tutmak
yerine okunan revision ile güncel revision'ı karşılaştırma yaklaşımıdır.

Bu projedeki karşılığı: İlk revision `1` olarak başlar. Karşılaştırma ve artırma
sonraki update servisinde uygulanacaktır.

### Reconciliation

Birbiriyle ilişkili iki storage alanının farklılıklarını sonradan bulup raporlama
veya düzeltme sürecidir.

Bu projedeki karşılığı: Gelecekte SQLite attachment metadata ile yönetilen file
store başlangıçta karşılaştırılacaktır.

## 8. “Şunu şöyle yaptık ki...” teknik karar tablosu

| Şunu yaptık | Böyle yaptık | Çünkü | Böylece |
| --- | --- | --- | --- |
| Yerel kalıcılık temeli kurduk | Standard library `sqlite3` kullandık | Ek servis ve paket ihtiyacı yok | Sade ve taşınabilir başlangıç oluştu |
| Şemayı sürümledik | `schema_migrations` ve `Migration` tanımladık | Şema değişiklikleri izlenmeli | Fresh ve mevcut database aynı runner ile ilerler |
| Migration'ı atomik yaptık | `BEGIN IMMEDIATE`, `commit`, `rollback` kullandık | Yarım şema güvenli değildir | Hata tüm v1 değişikliğini geri alır |
| Tekrar çalıştırmayı güvenli yaptık | Uygulanmış version değerini atladık | Başlangıçta runner tekrar çağrılabilir | Duplicate tablo/sürüm oluşmaz |
| İlişkileri koruduk | Foreign key enforcement'ı her bağlantıda açtık | SQLite bunu bağlantı bazında yönetir | Yetim observation/attachment reddedilir |
| Durum kurallarını koruduk | Python validator ve SQL CHECK kullandık | Tek katman yeterli güvence vermez | Hata erken ve storage sınırında yakalanır |
| Kimliği standartlaştırdık | Canonical UUID string doğruladık | Aynı kimliğin farklı yazımları karışıklık yaratır | Tek açık ID biçimi oluşur |
| Zamanı standartlaştırdık | Timezone-aware datetime'ı UTC `Z` biçimine çevirdik | Yerel saatler farklı yorumlanabilir | Olaylar tek zaman çizelgesinde sıralanır |
| Attachment binary'yi ayırdık | DB'de relative path/hash/size/lifecycle metadata tuttuk | Büyük binary'yi DB'ye gömmek yönetimi zorlaştırır | Yönetilen file store ve bütünlük kontrolü mümkün olur |

## 9. Bu adımda bilinçli olarak ne yapmadık?

- SQLite CRUD repository adapter yazmadık.
- Unit of Work veya application service eklemedik.
- Existing `FieldObservationRepository.update_status` davranışını değiştirmedik.
- Status transition ve revision artırma işlemini uygulamadık.
- Attachment dosyasını kopyalamadık, hash hesaplamadık veya finalize etmedik.
- Startup reconciliation çalıştırmadık.
- UI, API, CLI veya web framework eklemedik.
- ORM veya üçüncü taraf dependency eklemedik.
- Backup/restore, daily export, auth, private area, cloud sync, multi-user,
  offline sync veya encryption uygulamadık.
- README, ROADMAP, state, podcast, viewer, ZIP ve `exports/` içeriğini
  değiştirmedik.

## 10. Mini sözlük

- **SQLite:** Uygulama içine gömülü çalışan, sunucu gerektirmeyen ilişkisel
  veritabanı.
- **Schema:** Tabloların, alanların, ilişkilerin ve constraint'lerin yapısı.
- **Migration:** Schema'yı kontrollü biçimde yeni sürüme taşıyan değişiklik.
- **Transaction:** Birden fazla database işlemini tek iş birimi yapan sınır.
- **Rollback:** Başarısız transaction değişikliklerini geri alma işlemi.
- **Idempotent:** Tekrar çalıştırıldığında sonucu bozmayan davranış.
- **UUID:** Dağıtık ortamda benzersiz kayıt kimliği üretmeye uygun 128-bit kimlik.
- **UTC:** Dünyadaki saat dilimlerinin ortak zaman referansı.
- **Revision:** Kaydın kaçıncı güncel sürümde olduğunu gösteren sayaç.
- **PRAGMA:** SQLite bağlantı davranışını ayarlayan özel komut ailesi.
- **Failure injection:** Hata yolunu test etmek için kontrollü biçimde hata
  üretme tekniği.

Kalıcı terimler ayrıca `learning/GLOSSARY.md` dosyasına eklendi.

## 11. Sonraki adıma bağlantı

Schema v1 ve değer sözleşmeleri hazır olduğu için sonraki adımda SQLite repository
adapter'ı bu tablolara CRUD işlemleri uygulayabilir. O adımda revision karşılaştırma,
status transition, event yazımı ve transaction sınırı ayrıca tasarlanmalıdır.

Attachment copy/finalize ve startup reconciliation ise repository CRUD'dan farklı
bir application-service/storage koordinasyonu olarak ayrı tutulmalıdır.
