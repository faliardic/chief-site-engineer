# Issue #165 Öğrenme Notu — Legacy Envanteri ve Güvenli Deprecation

## Bu çalışmada ne öğrendik?

Bu Issue'da production kodu yazmadık. Bunun yerine büyük bir repository'de
“eski görünen kod” ile “güvenle kaldırılabilir kod” arasındaki farkı executable
kanıtlarla öğrendik. Sonuç önemlidir: repository'de çok sayıda legacy model ve
helper vardır, fakat bugün doğrulanmış **Silme adayı yoktur**.

Bu çelişki değildir. Bir kod current ürün yönünün parçası olmayabilir; buna
rağmen test, eski veri, restore, export parser veya karar geçmişi için hâlâ
korunması gerekebilir.

## Dört sınıfı Python öğrenen biri için açıklayalım

| Sınıf | Basit soru | Örnek |
|---|---|---|
| Aktif çekirdek | Uygulama veya veri güvenliği bugün buna bağlı mı? | SQLite migration'ları, Backup v1 |
| Dönüştürülecek | Çalışıyor ama yeni ADR yönüne kontrollü taşınacak mı? | `FieldObservationRecord`, application servisleri |
| Legacy / arşivlenecek | Current yön değil ama hâlâ bir bağı var mı? | `app/records.py`, eski handover helper'ları |
| Silme adayı | Bütün runtime, test, format, veri ve doküman bağları kanıtla bitti mi? | Bu Issue'da örnek yok |

Buradaki **deprecation**, bir şeyi hemen silmek değildir. “Yeni geliştirme bu
yüzeyi büyütmesin; replacement tamamlanınca kontrollü emeklilik
değerlendirilsin” demektir.

**Provenance**, bir kararın veya davranışın nereden geldiğini gösteren köken
bilgisidir. Eski learning/task/result dosyaları current authority olmasa da
“neden böyle yaptık?” sorusunun cevabını koruyabilir.

**Removal gate**, silmeden önce geçilmesi gereken kanıt kapısıdır. Bir kapının
cevabı bilinmiyorsa güvenli sonuç “sil” değil, “legacy olarak koru”dur.

## Repository'yi nasıl okuduk?

Önce dosya adı üzerinden tahmin yapmak yerine referans grafiğine baktık:

```powershell
rg --files app tests scripts
rg -n "FieldObservationRecord" app tests docs learning
rg -n "RESTORABLE_SCHEMA_VERSIONS|backup_format_version|format_version" app tests
rg -n "handover|devir|blocked|hard validation" app tests docs learning
```

Satır satır:

1. `rg --files` incelenecek gerçek dosya yüzeyini listeler.
2. İkinci komut bir symbol'ün yalnız tanımını değil, production ve test
   consumer'larını da bulur.
3. Üçüncü komut görünürde eski olan kodun format/restore compatibility rolünü
   araştırır.
4. Son komut eski ürün dilinin aktif runtime davranışı mı, yoksa yalnız
   tarihsel metin/test mi olduğunu ayırmaya yardım eder.

`rg` sonucu tek başına karar değildir. Örneğin dinamik import, dış consumer veya
yalnız eski backup geldiğinde çalışan parser normal call graph'ta görünmeyebilir.
Bu nedenle kaynak kod, test ve kanonik karar birlikte okundu.

## Gerçek kod örneği 1: Aynı dosyada aktif ve legacy kod olabilir

`app/models.py` başında eski attachment vocabulary ve ilk modeller vardır;
aynı dosyadaki `FieldObservationRecord` ise bugün application servisince
doğrudan kullanılır:

```python
@dataclass
class FieldObservationRecord:
    """Represents a fast official field observation for the first Field MVP."""

    observation_id: str
    project_id: str
    observed_at: str
    location: str
    category: str
    description: str
    status: str = "open"
    reported_to: str | None = None
    reported_at: str | None = None
    created_by: str | None = None
    closed_at: str | None = None
    notes: str | None = None
    is_archived: bool = False
```

Satır satır anlamı:

- `@dataclass`, alanları taşıyan sınıf için `__init__`, karşılaştırma ve temsil
  gibi standart metotları üretir.
- `observation_id` kayıt kimliğidir; repository ve route'ların kaydı bulmasını
  sağlar.
- `project_id`, observation'ın bağlı olduğu projedir. ADR-0001'e göre bu alan
  tek başına gelecekteki scope alanının yerine geçmez.
- `observed_at`, `location`, `category` ve `description` gözlemin asıl source
  içeriğidir.
- `status` yaşam döngüsüdür; scope veya archive ile aynı kavram değildir.
- `reported_*`, `created_by`, `closed_at` ve `notes` ek domain bilgisidir.
- `is_archived`, aktif/terminal status'tan ayrı arşiv görünürlüğünü taşır.

Application servisindeki gerçek import:

```python
from app.models import FieldObservationRecord
```

Bu tek satır önemli bir production kanıtıdır. `app/models.py` için “eski büyük
dosya, tamamını arşivleyelim” demeyi engeller. Sınıflandırma dosya seviyesinde
değil gerektiğinde symbol/section seviyesinde yapılmalıdır.

Bu model **Dönüştürülecek** sınıfındadır: bugün aktif source modelidir; sonraki
Issue'larda explicit scope ve RecordRef projection sözleşmesine uyarlanacaktır.
Henüz çalışan replacement olmadığı için silinemez.

## Gerçek kod örneği 2: Migration geçmişi aktif çekirdektir

`app/persistence/schema.py` şu şekilde başlar:

```python
SCHEMA_VERSION = 4


@dataclass(frozen=True)
class Migration:
    """One ordered, atomic database schema change."""

    version: int
    statements: tuple[str, ...]


SCHEMA_MIGRATIONS: tuple[Migration, ...] = (
    Migration(
        version=1,
        statements=(
            """
            CREATE TABLE projects (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                created_at TEXT NOT NULL
            )
            """,
```

Satır satır:

- `SCHEMA_VERSION = 4`, uygulamanın beklediği güncel veritabanı sürümüdür.
- `@dataclass(frozen=True)`, migration tanımının çalışma sırasında yanlışlıkla
  değiştirilememesini sağlar.
- `version`, migration sırasını belirtir.
- `statements`, o sürümde atomik uygulanacak SQL komutlarıdır.
- `SCHEMA_MIGRATIONS`, ilk kurulumda da eski DB yükseltmesinde de gereken
  sıralı geçmişi taşır.
- `version=1` bugün yeni feature yazmıyor olabilir; fakat v1/v2/v3 verisini v4'e
  taşıma zincirinin başlangıcıdır.

Burada “sürüm 1 eski, silinebilir” çıkarımı tehlikelidir. Migration kodu her
normal uygulama açılışında görünür biçimde çağrılmasa bile eski bir DB veya
Backup restore edildiğinde çalışır. Bu nedenle v1-v4 migration geçmişi **Aktif
çekirdek** sınıfındadır.

## Gerçek kod örneği 3: Legacy repository'nin test bağı

`app/records.py` içindeki eski in-memory helper:

```python
RecordT = TypeVar("RecordT")


def list_records(records: list[RecordT]) -> list[RecordT]:
    return records


def count_records(records: list[RecordT]) -> int:
    return len(records)


def filter_records_by_project_id(
    records: list[RecordT],
    project_id: str,
) -> list[RecordT]:
    return [
        record
        for record in records
        if hasattr(record, "project_id") and record.project_id == project_id
    ]
```

Satır satır:

- `TypeVar("RecordT")`, helper'ın farklı record tipleriyle type-safe biçimde
  kullanılabilmesini anlatır.
- `list_records`, verilen listeyi döndürür; çok basit görünmesi consumer yok
  demek değildir.
- `count_records`, listenin eleman sayısını verir.
- `filter_records_by_project_id`, list comprehension ile yalnız eşleşen proje
  kayıtlarını seçer.
- `hasattr`, farklı record sınıflarının hepsinde `project_id` olmayabileceğini
  hesaba katar.

Current production application SQLite repository/UoW kullanır ve
`app/records.py` başka production module tarafından import edilmez. Bu yüzden
bu dosya **Legacy / arşivlenecek** sınıfındadır. Fakat `tests/test_records.py`
dosyası repository ve helper davranışlarını doğrudan ve geniş biçimde test
eder. Ayrıca NCR için tam current replacement yoktur. Dolayısıyla dosya
**Silme adayı değildir**.

Bu ayrım çok değerlidir:

```text
production consumer yok
        ≠
güvenle silinebilir
```

Eşitliğin sağ tarafı için test, fixture, veri, format, docs ve replacement
kapılarının da kapanması gerekir.

## Gerçek kod örneği 4: Test importu executable bağı gösterir

`tests/test_models.py` çok sayıda eski modeli ve helper'ı doğrudan import eder:

```python
from app.models import (
    AttachmentRecord,
    AuditEventRecord,
    FieldObservationRecord,
    FileAttachmentRecord,
    NonconformityRecord,
    TrackingRecord,
    build_export_handover_qc_review_checklist,
    build_record_id_diagnostic_report,
    build_record_id_soft_validation_report,
    format_export_result_report_as_markdown,
)
```

Bu blok bize şunları söyler:

- Import edilen symbol kaldırılırsa test collection daha assertion'a gelmeden
  hata verir.
- Testleri symbol ile birlikte silmek replacement'ın doğru olduğunu kanıtlamaz;
  yalnız eski kabul kanıtını ortadan kaldırır.
- Handover ve generic export helper'ları production consumer taşımıyor olsa da
  output örneği/regression beklentileri vardır.
- `FieldObservationRecord` aynı import listesinde olsa bile diğerlerinden farklı
  olarak production application servisinde de kullanılır.

Test referansı her zaman “bu davranış sonsuza kadar kalmalı” demek değildir.
Ama kaldırma Issue'ının hangi kabulü replacement'a taşıması veya hangi tarihsel
testi neden emekli etmesi gerektiğini açıklar.

## Gerçek kod örneği 5: Format sürümü neden sadece bir sayı değildir?

Backup kodunda restore edilebilir schema sürümleri ayrı bir kontrattır:

```python
RESTORABLE_SCHEMA_VERSIONS = (2, 3, 4)
```

Günlük Çıktı manifest'i ise tarihsel wire anahtarını korur:

```python
"format_version": 1,
```

Bu satırlar kısa olsa da anlamları büyüktür:

- `RESTORABLE_SCHEMA_VERSIONS`, verifier/restore yolunun hangi eski DB
  sürümlerini kabul ettiğini söyler.
- Tuple içindeki `2` ve `3`, eski migration/parser kodunun hâlâ kullanıcı veri
  kurtarma sözleşmesinde olduğunu gösterir.
- Günlük Çıktı'daki `format_version`, ADR-0003'ün yeni ve daha açık namespace
  kararından önceki wire anahtarıdır.
- ADR-0003 bu anahtarı v1 içinde rename etmeyi yasaklar; yeni bir format ailesi
  eski ZIP'i sessizce başka anlamda yorumlayamaz.

**Wire format**, iki program veya iki sürüm arasında dosya/mesaj üzerinde
taşınan exact alan ve byte sözleşmesidir. Python değişken adı iç ayrıntı
olabilir; ZIP manifest'indeki anahtar dış consumer için kontrat olabilir.

## Test kodu neyi doğruluyor?

Bu Issue yeni production davranışı eklemediği için yeni Python testi yazmadık.
Var olan testleri envanter kanıtı olarak kullandık ve full suite'i regresyon
kontrolü olarak çalıştırdık.

Örnek mevcut beklenti:

```python
def test_file_attachment_enum_values_define_canonical_vocabulary() -> None:
    assert FileType.IMAGE.value == "image"
    assert FileType.VIDEO.value == "video"
    assert FileType.PDF.value == "pdf"
    assert FileType.DOCUMENT.value == "document"
    assert FileType.AUDIO.value == "audio"
    assert FileType.OTHER.value == "other"
    assert AttachmentStatus.ACTIVE.value == "active"
    assert AttachmentStatus.ARCHIVED.value == "archived"
    assert AttachmentStatus.MISSING.value == "missing"
    assert AttachmentStatus.DELETED.value == "deleted"
```

Satır satır test mantığı:

- Fonksiyon adı hangi vocabulary kontratının korunduğunu anlatır.
- Her `assert`, enum üyesinin serialized string değerini exact doğrular.
- Enum Python'da kullanılmıyor gibi görünse bile eski JSON/fixture bu string'e
  bağlı olabilir.
- Bu test kaldırma kapısında “fixture/parser etkisini açıkla” gereksinimini
  doğurur.

Full kontrol:

```powershell
python -m pytest -rs
python -m compileall -q app scripts
python -m json.tool .cse/state/project_state.json > $null
git diff --check
```

- `pytest -rs`, bütün executable davranışların hâlâ geçtiğini ve skip
  nedenlerini gösterir.
- `compileall`, production/script Python dosyalarının syntax/import derleme
  seviyesinde bozulmadığını doğrular.
- `json.tool`, project state dosyasının geçerli JSON kaldığını kanıtlar.
- `git diff --check`, trailing whitespace ve bozuk patch satırlarını bulur.

Belge-only değişiklikte bile full suite gerekir; çünkü yanlışlıkla yetkisiz bir
dosyaya dokunulmadığını yalnız niyet değil diff ve test kanıtlar.

## Teknik karar tablosu

| Karar | Neden | Reddedilen kısa yol | Sonraki executable kanıt |
|---|---|---|---|
| Dosya yerine symbol/section seviyesinde sınıflandır | `app/models.py` hem aktif hem legacy içerir | Dosyanın tamamını legacy saymak | Import graph + application/persistence testleri |
| Silme adayı sayısını sıfır tut | Her görünen aday en az bir kapıda takıldı | “Production import yoksa sil” | Sıfır runtime/test/fixture/format/docs bağı |
| Migration geçmişini aktif çekirdek say | Eski DB/Backup restore için çalışır | Yalnız son schema SQL'ini tutmak | Schema 2/3→4 ve v4 round-trip fixture'ları |
| Legacy handover helper'ını Proje Paketi diye rename etme | Yeni family privacy/source-verification garantileri farklı | İsim değiştirerek replacement iddiası | ADR-0003 family-specific builder/verifier testleri |
| Tarihsel docs'u provenance olarak koru | Karar ve öğrenme kökeni değerlidir | Toplu eski docs temizliği | Canonical/superseded/archive index ve reference graph |
| Belirsizlikte fail-closed legacy kal | Repo dışı consumer/gerçek veri bilinmeyebilir | Bilinmeyeni “yok” saymak | Açık veri/consumer audit'i ve rollback planı |

## Kod çalışma akışı

Inventory çalışmasının düşünce akışı şöyledir:

```text
symbol/path bul
    ↓
production import/call site tara
    ↓
test/fixture/smoke/acceptance bağını tara
    ↓
schema/migration/backup/export/restore bağını tara
    ↓
kanonik ADR ve uygulanmış replacement durumunu karşılaştır
    ↓
aktif mi? → Aktif çekirdek
taşınacak çalışan kaynak mı? → Dönüştürülecek
current değil ama herhangi bir bağ var mı? → Legacy / arşivlenecek
bütün kapılar executable kanıtla kapandı mı? → Silme adayı
```

Burada son ok en zor olandır. “Replacement tasarlandı” yeterli değildir;
replacement'ın kodu ve kabul testleri çalışmalıdır. “Test bağı var ama testi de
sileriz” de yeterli değildir; testin koruduğu kontratın artık neden gerekmediği
kanıtlanmalıdır.

## Şunu şöyle yaptık ki...

Şunu şöyle yaptık ki, legacy yüzeyleri tek bir “eski kod” torbasına atmak yerine
her grubun runtime, test, veri/format, kanonik karar, replacement ve kaldırma
kapısını aynı inventory satırında görünür yaptık. Böylece sonraki Issue bir
dosyayı yalnız adına bakarak silmeyecek; hangi executable kabulü önce kurması
gerektiğini bilecek.

Şunu şöyle yaptık ki, `app/models.py` dosyasını bütün olarak sınıflandırmadık;
aktif `FieldObservationRecord` ile eski prototip/helper kümelerini ayırdık.
Böylece çalışan observation zincirini yanlışlıkla legacy ilan etmedik.

Şunu şöyle yaptık ki, eski migration ve artifact formatlarını “geçmiş” değil
“uyumluluk için aktif” kabul ettik. Böylece güncel testlerde görünmeyebilecek
gerçek restore ve dış consumer riskini kararın içine aldık.

Şunu şöyle yaptık ki, bu Issue'da fiziksel silme, rename, schema veya production
değişikliği yapmadık. Inventory ve davranış değişikliğini ayrı review/commit
yüzeylerinde tutarak rollback ve denetimi kolaylaştırdık.

## Yeni terimler sözlüğü

Bu Issue kalıcı global sözlüğü değiştirmedi; görev allowlist'i yalnız sekiz
dosyayı kapsıyordu. Burada kullanılan terimler:

- **Deprecation:** Yeni kullanımını durdurup kontrollü emekliliğe hazırlama.
- **Inventory:** Symbol/path, bağımlılık, replacement ve risklerin yapılandırılmış
  envanteri.
- **Provenance:** Kararın/verinin kökenini ve değişim geçmişini gösteren kanıt.
- **Removal gate:** Fiziksel kaldırmadan önce geçilmesi zorunlu koşul.
- **Call graph:** Hangi kodun hangi fonksiyon/modül/symbol'ü çağırdığını gösteren
  ilişki ağı.
- **Fixture:** Teste sabit örnek veri veya dosya sağlayan girdi.
- **Wire format:** Dosya veya mesajın dış consumer'la paylaşılan exact biçimi.
- **Backward compatibility:** Yeni sürümün desteklenen eski veri ve artifact'ları
  okuyabilme/işleyebilme özelliği.
- **Fail-closed:** Kanıt eksik veya belirsiz olduğunda güvenli biçimde reddetme.
- **Read-only inventory:** Kaynakları inceleyip sınıflandıran, production verisi
  veya davranışı değiştirmeyen çalışma.

Bu terimler ileride kalıcı glossary'ye eklenecekse, bunu `learning/GLOSSARY.md`
dosyasını açıkça yetkilendiren ayrı bir Issue yapmalıdır.
