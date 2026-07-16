# Issue #117 — Backup/Restore Uyumluluğu ve Resmî Export İzolasyonu

## Amaç

Bu adım iki ayrı veri güvenliği sorusunu executable testlerle cevapladı:

1. Eski ama desteklenen schema 2 ve schema 3 yedekleri, kaynak arşive dokunmadan güvenle schema 4'e yükseltilebilir mi?
2. Kişisel Saha Takibi verisi resmî günlük export'a hiçbir biçimde karışmadan tam backup içinde korunabilir mi?

Sonuç evettir. Buradaki önemli ayrım şudur:

```text
Tam backup
-> SQLite snapshot'ın tamamını taşır
-> kişisel tracking verisini de korur

Resmî günlük export
-> yalnız project + observation + observation event + observation attachment okur
-> kişisel tracking verisini dışarıda bırakır
```

Backup ile export aynı şey değildir. Backup veri kaybına karşı tüm yerel veri kökünü korur. Resmî günlük export ise kontrollü ve dar bir resmî çıktı sözleşmesidir.

## Çözülen saha problemi

Şantiye şefi uygulamanın eski bir sürümünde gerçek gözlem ve fotoğraf biriktirmiş olabilir. Yeni sürümde Saha Takibi tabloları eklenmiş olsa bile eski yedek şu risklerle karşılaşmamalıdır:

- Eski yedek sırf schema numarası küçük diye açılamaz hâle gelmemeli.
- Eski veritabanı doğrulanmadan migration çalıştırılmamalı.
- Migration aktif kullanıcı klasöründe veya kaynak yedek üzerinde yapılmamalı.
- Hata olursa yarım restore klasörü görünür kalmamalı.
- Kişisel takip metni resmî günlük ZIP'ine sızmamalı.
- Backup formatı gereksiz yere büyütülmemeli.

Bu adım bu riskleri dar bir restore orchestration ve gerçek SQLite fixture testleriyle kapattı.

## Hangi dosyada ne yaptık?

| Dosya | Değişiklik | Neden |
| --- | --- | --- |
| `app/operations/backups.py` | Schema 2/3/4 doğrulama ve temporary restore migration akışı | Eski yedekleri kaynak üzerinde değişiklik yapmadan güncel schema'ya getirmek |
| `tests/test_backup_restore.py` | Gerçek schema 2, 3 ve 4 fixture/test matrisi | Sadece manifest numarasıyla oynayan sahte test yerine gerçek migration zincirini doğrulamak |
| `tests/test_daily_export.py` | Tracking verili/verisiz iki root için byte eşitliği testi | Kişisel verinin resmî export'a sızmadığını kanıtlamak |
| `CHANGELOG.md` | Kullanıcıya dönük teknik değişiklik kaydı | Bu güvenlik kapısının kapsamını görünür kılmak |
| `ROADMAP.md` | Faz 2'yi tamamlandı olarak işaretleme | Sonraki dar ürün yönünü mobil runtime/veri sahipliği ADR'sine taşımak |
| `docs/project_decisions.md` | Kalıcı format ve restore kararları | Sonraki görevlerin aynı sınırları korumasını sağlamak |
| `.cse/*` | Task, result ve factual state | Yerel yürütme ve teslim kanıtını kaydetmek |

`app/operations/exports.py` değiştirilmedi. Yeni test gerçek bir sızıntı bulmadı; mevcut export kodu zaten doğru sınırda çalışıyordu.

## Yeni ve önemli teknik kavramlar

### Restore allowlist

Allowlist, kabul edilen değerlerin açık ve kapalı listesidir:

```python
RESTORABLE_SCHEMA_VERSIONS = (2, 3, 4)
```

Bu satırın anlamı:

- `2`: Observation omurgası ve notes alanı bulunan eski yedek restore edilebilir.
- `3`: İlk Saha Takibi tablolarını taşıyan yedek restore edilebilir.
- `4`: Güncel yedek doğrudan restore edilebilir.
- Diğer bütün değerler reddedilir.

Kod “4'ten küçükse her şeyi kabul et” demez. Böyle bir karşılaştırma schema 1, schema 0 veya bozuk negatif değerleri de yanlışlıkla kabul edebilirdi.

### Pre-migration doğrulama

Pre-migration, eski database henüz değiştirilmeden yapılan kontroldür:

```text
integrity_check
+ exact schema_migrations listesi
+ observation count
+ observation event count
+ attachment metadata count
+ attachment path/hash/size reconciliation
```

Bu kontrol geçmezse migration hiç başlamaz.

### Post-migration doğrulama

Post-migration, temporary database schema 4'e geldikten sonra aynı kontrollerin güncel sürüme göre tekrar yapılmasıdır. Buna repository okumaları da eklenir.

Repository okuması SQL tablosunun sadece var olduğunu değil, satırların Python domain modellerine çevrilebildiğini de doğrular.

### Round-trip

Round-trip şu tam turdur:

```text
kaynak veri kökü
-> backup
-> verify
-> yeni köke restore
-> aynı aggregate ve event'leri yeniden oku
```

Başlangıç ve bitişteki anlamlı veri aynıysa round-trip başarılıdır.

## Production kodu: schema allowlist

Gerçek kodun ilgili parçası:

```python
BACKUP_FORMAT_VERSION = 1
RESTORABLE_SCHEMA_VERSIONS = (2, 3, 4)
```

Satır satır:

1. `BACKUP_FORMAT_VERSION = 1`: ZIP ve manifest formatının değişmediğini söyler.
2. `RESTORABLE_SCHEMA_VERSIONS = (2, 3, 4)`: Aynı backup formatı içindeki hangi embedded database sürümlerinin kabul edileceğini söyler.

Bu iki sürüm birbirinden farklı kavramlardır:

| Sürüm | Neyi sürümler? |
| --- | --- |
| Backup format version | ZIP entry ve manifest sözleşmesini |
| Schema version | ZIP içindeki `cse.sqlite3` tablo/migration yapısını |

Schema 2 yedeğini kabul etmek backup formatını 2 yapmak anlamına gelmez.

## Production kodu: manifest schema doğrulaması

Gerçek kontrol:

```python
schema_version = manifest["schema_version"]
if (
    not isinstance(schema_version, int)
    or isinstance(schema_version, bool)
    or schema_version not in RESTORABLE_SCHEMA_VERSIONS
):
    raise BackupValidationError("backup schema version is unsupported")
```

Satır satır:

1. Manifest içindeki değer yerel değişkene alınır.
2. Değer `int` değilse reddedilir.
3. Python'da `bool`, `int` alt sınıfı olduğu için ayrıca reddedilir. Aksi hâlde `True == 1` gibi şaşırtıcı bir kabul oluşabilir.
4. Değer allowlist içinde değilse reddedilir.
5. Hata `BackupValidationError` olarak üst katmana çıkar.

Buradaki bool kontrolü Python öğrenirken önemlidir:

```python
isinstance(True, int)  # True
```

Bu nedenle yalnız `isinstance(value, int)` yazmak güvenli değildir.

## Production kodu: verify sırasında migration yok

Gerçek akışın özeti:

```python
def _verify_archive_contents(self, bundle, manifest):
    with tempfile.TemporaryDirectory(prefix=".cse-backup-verify-") as work:
        temporary = Path(work)
        self._extract_archive_files(bundle, temporary, manifest["files"])
        self._validate_restored_database(
            temporary,
            manifest,
            int(manifest["schema_version"]),
        )
```

Satır satır:

1. `TemporaryDirectory` yalnız doğrulama için özel bir geçici klasör açar.
2. `with` bloğu bittiğinde klasör otomatik temizlenir.
3. Arşivdeki manifest edilmiş database ve attachment dosyaları bu köke çıkarılır.
4. Doğrulama, manifestin söylediği schema sürümüne göre yapılır.
5. Bu fonksiyon `migrate_database(...)` çağırmaz.

Database bağlantısı salt-okunur açılır:

```python
def _connect_read_only_database(database: Path) -> sqlite3.Connection:
    return sqlite3.connect(f"{database.resolve().as_uri()}?mode=ro", uri=True)
```

`mode=ro`, doğrulama kodu yanlışlıkla bir write SQL'i çalıştırmaya kalkarsa SQLite seviyesinde yazmayı engeller.

## Production kodu: exact migration zinciri

Gerçek kontrol:

```python
versions = [
    row[0]
    for row in connection.execute(
        "SELECT version FROM schema_migrations ORDER BY version"
    )
]
if versions != list(range(1, expected_schema_version + 1)):
    raise BackupValidationError(
        "restored database migration version is unknown"
    )
```

Örnekler:

| Manifest schema | Embedded liste | Sonuç |
| --- | --- | --- |
| 2 | `[1, 2]` | Kabul |
| 3 | `[1, 2, 3]` | Kabul |
| 4 | `[1, 2, 3, 4]` | Kabul |
| 3 | `[1, 2]` | Ret: manifest/database uyuşmazlığı |
| 4 | `[1, 3, 4]` | Ret: migration gap'i |
| 4 | `[1, 2, 3, 4, 99]` | Ret: future/unknown sürüm |

Önceki `set(...)` yaklaşımı yerine sıralı liste karşılaştırması kullanılması, hem eksiksizliği hem doğru sırayı görünür yapar.

## Production kodu: restore çalışma akışı

Gerçek kodun sadeleştirilmiş biçimi:

```python
manifest = self.verify_backup(archive_path)
self._extract_archive_files(bundle, temporary, manifest["files"])

source_schema_version = int(manifest["schema_version"])
self._validate_restored_database(
    temporary, manifest, source_schema_version
)

if source_schema_version < SCHEMA_VERSION:
    self._migrate_restored_database(temporary / "cse.sqlite3")

self._validate_restored_database(
    temporary, manifest, SCHEMA_VERSION
)
self._validate_current_repositories(temporary / "cse.sqlite3")
self._atomic_move(temporary, target)
```

Satır satır çalışma mantığı:

1. Arşivin path, duplicate, symlink, manifest ve digest sözleşmesi doğrulanır.
2. Arşiv target'a değil, görünmeyen temporary restore köküne çıkarılır.
3. Embedded database kendi eski schema sürümüne göre tekrar doğrulanır.
4. Sürüm eskiyse migration yalnız temporary `cse.sqlite3` üzerinde çalışır.
5. Database güncel schema 4 kurallarına göre yeniden doğrulanır.
6. Repository'ler bütün observation ve tracking kayıtlarını okumaya zorlanır.
7. Bütün kapılar geçerse temporary klasör tek atomic move ile target olur.

Akış diyagramı:

```text
Kaynak ZIP
   |
   v
Archive verify (değişiklik yok)
   |
   v
Private temporary restore root
   |
   v
Pre-migration DB + count + attachment check
   |
   +-- hata --> temporary temizle, target oluşturma
   |
   v
Gerekirse schema 2/3 -> 4 migration
   |
   +-- hata --> rollback + temporary temizle
   |
   v
Post-migration DB + repository check
   |
   +-- hata --> temporary temizle, target oluşturma
   |
   v
Tek atomic move
   |
   v
Yeni görünür target root
```

## Neden migration yalnız temporary database üzerinde?

Üç veri yüzeyi vardır:

| Yüzey | Değiştirilebilir mi? | Gerekçe |
| --- | --- | --- |
| Kaynak backup ZIP | Hayır | Geri dönüş kanıtıdır |
| Aktif `CSE_DATA_ROOT` | Hayır | Gerçek kullanıcı verisidir |
| Private temporary restore root | Evet | Hata hâlinde tamamı atılabilir |

Migration yarıda kalırsa temporary root silinir. Kaynak ZIP ve aktif veri kökü aynı kalır.

## Repository-level post-validation nasıl çalışıyor?

Restore sonrasında yalnız `PRAGMA integrity_check` yeterli değildir. SQLite dosyası fiziksel olarak sağlam olsa bile bir satır domain enum'una veya UUID sözleşmesine uymayabilir.

Bu nedenle kod şu repository okumalarını yapar:

```python
with SQLiteUnitOfWork(database) as unit_of_work:
    observations = unit_of_work.observations.list_all()
    follow_ups = unit_of_work.follow_ups.list_all()
    templates = unit_of_work.routine_templates.list_all()

    for follow_up in follow_ups:
        unit_of_work.follow_up_events.list_for_follow_up(
            follow_up.follow_up_id
        )

    for template in templates:
        occurrences = unit_of_work.routine_occurrences.list_for_template(
            template.routine_template_id
        )
```

Bu okuma sırasında SQL satırları Python dataclass ve enum değerlerine map edilir. Bozuk bir kayıt varsa target görünür olmadan hata alınır.

## Test fixture: neden gerçek schema 2 ve schema 3?

Yanlış test yaklaşımı şuna benzerdi:

```python
# YANLIŞ YAKLAŞIM
manifest["schema_version"] = 2
```

Bu yalnız etiketi değiştirir. Embedded database hâlâ schema 4 ise gerçek eski yedek davranışı test edilmez.

Doğru yaklaşımda migration subset'i kullanıldı:

```python
migrate_database(
    connection,
    migrations=SCHEMA_MIGRATIONS[:schema_version],
)
```

Schema 2 fixture için:

```python
SCHEMA_MIGRATIONS[:2]
```

Schema 3 fixture için:

```python
SCHEMA_MIGRATIONS[:3]
```

Ardından gerçek project, observation, attachment, observation event ve schema 3 için tracking satırları doğrudan o sürümün tablolarına yazıldı. Manifest digest ve count değerleri bu gerçek dosyadan hesaplandı.

## Schema 2 testinin doğruladıkları

Test akışı:

```python
create_legacy_root(source, 2)
build_backup_fixture(source, archive, schema_version=2)
BackupService(source).restore_backup(archive, target)
```

Doğrulananlar:

- Final migration listesi `[1, 2, 3, 4]`.
- Project/observation/attachment/observation-event satırları aynı.
- Observation event `payload_json` metni aynı.
- Attachment byte içeriği ve hash'i aynı.
- Yedi tracking tablosu boş.
- Observation application service restored root'u okuyabiliyor.
- Web observation detail route'u restored root üzerinde açılıyor.
- Kaynak database ve ZIP digest'i değişmiyor.

## Schema 3 testinin doğruladıkları

Schema 3 fixture şunları taşır:

- bir follow-up;
- bir follow-up event;
- bir routine template;
- bir missed occurrence;
- template ve occurrence event geçmişi.

Özellikle payload metni boşluklarıyla birlikte korunur:

```python
LEGACY_FOLLOW_UP_PAYLOAD = (
    '{ "title": "Kalıp", "revision": 1 }'
)
```

Test migration öncesi ve sonrası tracking tablolarında `SELECT *` sonuçlarını karşılaştırır. Böylece yalnız parse edilmiş JSON anlamı değil, gerçek `payload_json` text'i de korunur.

## Schema 4 tam round-trip testi

Güncel fixture application service'lerle üretildi:

```text
Observation + attachment
Follow-up create
Follow-up details update
Follow-up -> observation conversion
Routine template create
Geçmiş missed occurrence
Bugünkü open occurrence
Snooze
Close
Reopen
```

Restore sonrasında:

- Aggregate satırları aynı.
- Revision değerleri aynı.
- Natural key aynı.
- Occurrence schedule snapshot alanları aynı.
- Event sequence listeleri aynı.
- Payload JSON metinleri aynı.
- Follow-up ve routine application service sorguları aynı sonucu döndürüyor.
- İkinci backup yine format version 1 ve aynı manifest alan kümesini kullanıyor.

## Hata atomikliği testleri

| Hata | Test tekniği | Beklenen sonuç |
| --- | --- | --- |
| Pre-migration observation count uyuşmazlığı | Manifest count gerçek DB count'tan farklı | Target yok |
| Migration statement failure | Temporary DB üzerinde geçerli bir CREATE ardından bozuk CREATE | Transaction rollback, target yok |
| Post-migration repository validation failure | Validation helper'a kontrollü hata enjekte etme | Target yok |
| Existing target | Marker dosyalı var olan klasör | Marker değişmez |
| Unknown/future schema | Allowlist dışı manifest | Extraction/migration yok |
| Migration gap | Embedded liste `[1, 3, 4]` | Verify fail-closed |

Her hata testinde restore temporary klasörünün kalmadığı da kontrol edilir.

## Resmî export izolasyonu testi

İki ayrı root üretildi:

```text
Root A
-> project
-> observation
-> observation event
-> attachment

Root B
-> Root A ile aynı resmî veri
-> follow-up + details + conversion
-> routine template
-> missed/open occurrence
-> snooze/close/reopen tracking event'leri
```

İki export aynı clock ve UUID ile üretildi:

```python
deterministic_export = {
    "clock": lambda: "2026-07-13T10:00:00Z",
    "uuid_factory": lambda: (
        "dddddddd-dddd-4ddd-8ddd-dddddddddddd"
    ),
}
```

Ana kabul:

```python
assert output_a.read_bytes() == output_b.read_bytes()
```

Bu tek assertion şunların hepsini birlikte kapsar:

- ZIP entry sırası;
- her entry'nin byte içeriği;
- manifest alanları;
- record/warning count;
- file digest değerleri;
- Markdown/CSV/JSON/attachment manifest çıktıları.

Ek olarak bütün entry'ler birleştirilip şu özel token'lar aranır:

```text
follow-up metni
routine başlığı
tracking UUID'leri
converted_to_observation
follow_up.details_updated
routine_occurrence.reopened
tracking count adları
```

Hiçbiri bulunmaz. Follow-up observation'a bağlanmış ve conversion sonucu taşımış olsa bile follow-up metni resmî export'a girmez. Zaten resmî olan observation kendi normal kurallarıyla export edilir.

## Teknik karar tablosu

| Karar | Seçilen yaklaşım | Seçilmeyen yaklaşım | Neden |
| --- | --- | --- | --- |
| Eski schema kabulü | Açık `(2, 3, 4)` allowlist | `schema <= 4` | Schema 1/0/negatif değerleri fail-closed reddetmek |
| Verify davranışı | Temporary extraction + read-only SQLite | Kaynak ZIP içinde in-place işlem | Kaynağı değiştirmemek |
| Migration yeri | Temporary restore DB | Source DB veya active root | Hata atomikliği |
| Migration zinciri | Exact `[1..manifest_schema]` | Yalnız max version | Gap ve mismatch'i yakalamak |
| Tracking backup güvencesi | SQLite digest + restore kabul testi | Manifest tracking count alanları | Format version 1'i korumak |
| Post-check | Integrity + count + reconciliation + repository reads | Yalnız integrity_check | Domain mapping bozukluklarını da yakalamak |
| Export izolasyonu | Byte-identical iki-root regresyonu | Yalnız “kod tracking tablosu okumuyor” yorumu | Executable kanıt üretmek |
| Export production kodu | Değişmedi | Gereksiz refactor | Test gerçek sızıntı bulmadı |

## Şunu şöyle yaptık ki...

- Restore edilebilir sürümleri açık tuple yaptık ki eski veya future schema'lar tahminle kabul edilmesin.
- Bool değerini ayrıca reddettik ki Python'ın `bool`/`int` ilişkisi schema doğrulamasını gevşetmesin.
- Verify sırasında database'i salt-okunur açtık ki doğrulama kaynak içeriği değiştiremesin.
- Manifest schema ile exact migration listesini karşılaştırdık ki yalnız en büyük sürüme bakıp aradaki eksik migration'ı kaçırmayalım.
- Eski database'i önce kendi sürümünde doğruladık ki bozuk veriye migration uygulamayalım.
- Migration'ı yalnız temporary restore root'ta çalıştırdık ki hata gerçek kullanıcı verisini veya kaynak yedeği etkilemesin.
- Post-migration repository okumaları ekledik ki yalnız fiziksel SQLite bütünlüğünü değil Python domain kabulünü de kanıtlayalım.
- Target'ı en son tek atomic move ile görünür yaptık ki yarım restore kullanıcıya başarılı klasör gibi görünmesin.
- Schema 2/3 testlerinde gerçek migration subset'i kullandık ki manifest etiketi değiştiren sahte geriye uyumluluk testi yazmayalım.
- Schema 4 testinde application service'lerle gerçek event history oluşturduk ki yalnız boş tracking tablolarını değil yaşam döngüsünü koruyalım.
- Export için iki root'un ZIP byte'larını karşılaştırdık ki kişisel/resmî ayrımı yorum değil çalıştırılabilir sözleşme olsun.
- Export testi geçtiğinde production export koduna dokunmadık ki doğru çalışan dar sözleşmeye gereksiz risk eklemeyelim.

## Testlerin neyi doğruladığı

Focused dosyalar:

```powershell
python -m pytest -rs tests/test_backup_restore.py tests/test_daily_export.py
```

Bu paket şu başlıkları kapsar:

- current schema 4 backup create/verify;
- exact format/manifest sözleşmesi;
- schema 2/3/4 embedded migration eşleşmesi;
- schema bool/old/future/gap/mismatch reddi;
- unsafe path, duplicate, symlink, digest ve unmanifested entry regresyonları;
- schema 2→4 resmî veri/attachment/event korunması;
- schema 3→4 tracking/event payload korunması;
- schema 4 full tracking lifecycle round-trip;
- pre/migration/post hata atomikliği;
- existing target koruması;
- resmî export byte eşitliği ve tracking token yokluğu.

Tam test paketi ayrıca migration, persistence, application service, web, launcher, attachment ve diğer tarihsel modüllerin geriye uyumluluğunu kontrol eder.

## Bilinçli olarak eklenmeyenler

- Backup format version 2
- Manifest tracking count alanları
- Kişisel tracking export'u
- Schema 5
- Yeni migration statement
- Web backup UI değişikliği
- Mobil/PWA/offline/sync
- Scheduler veya notification
- Gerçek kullanıcı data root'u üzerinde restore denemesi
- Existing target üzerine yazma
- Source archive'ı güncelleme

## Gerçek şantiye karşılığı

Bu adımın kullanıcıya sağladığı güvence şudur:

> Eski CSE yedeğim desteklenen bir sürümdeyse önce kendi hâliyle doğrulanır, güvenli geçici alanda güncellenir ve yalnız tamamen sağlamsa yeni klasör olarak görünür. Kişisel takiplerim tam yedekte korunur ama resmî günlük çıktısına karışmaz.

Bu, ilk test edilebilir PC sürümünden önce gerekli veri güvenliği kapısıdır.

## Sonraki dar adım

Epic #105 sırasına göre sonraki faz mobil runtime ve veri sahipliği ADR'sidir. Bu learning notu mobil teknoloji kararı vermez; yalnız backup/restore ve resmî export güvenlik kapısının tamamlandığını açıklar.
