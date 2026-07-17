# Issue #147 Öğrenme Notu — MemoryIndex / RecordRef Read-Model ADR'si

## Amaç

Bu adımda production kodu yazmadan şu soruya kesin cevap verdik:

> Observation, follow-up ve rutin gerçekleşmeler ayrı domain kayıtları olarak
> kalırken kullanıcı bunları tek Hafıza listesinde nasıl güvenli ve kararlı
> biçimde görebilir?

Cevap, kaynak kayıtları tek tabloya taşımak değil; kaynaklardan tekrar tekrar
üretilebilen bir **read-model** kurmaktır. Bu read-model'in koleksiyon adı
`MemoryIndex`, her ortak satırının adı `RecordRef` olarak seçildi.

## Önce mevcut kodu okuyalım

### Observation neden ayrı bir domain kaydıdır?

Mevcut `app/models.py` içindeki gerçek kayıt özeti şöyledir:

```python
@dataclass
class FieldObservationRecord:
    observation_id: str
    project_id: str
    observed_at: str
    location: str
    category: str
    description: str
    status: str = "open"
    is_archived: bool = False
    revision: int = 1
    created_at: str | None = None
    updated_at: str | None = None
    archived_at: str | None = None
```

Satır satır anlamı:

- `@dataclass`, yalnız veri taşıyan bir Python sınıfı üretir.
- `observation_id`, observation'ın değişmez kaynak kimliğidir.
- `project_id` zorunludur; observation proje/resmî kayıt ailesindedir.
- `observed_at`, sahadaki olayın ne zaman görüldüğünü söyler.
- `location`, `category` ve `description` observation'a özgü içeriktir.
- `status`, `open`, `tracking` veya `closed` yaşam döngüsünü taşır.
- `is_archived` ve `archived_at`, kapanmadan farklı bir arşiv kavramıdır.
- `revision`, optimistic concurrency için her gerçek değişiklikte artar.
- `created_at` ile `updated_at`, olay zamanı değil kayıt zamanlarıdır.

Buradaki `observed_at`, ortak timeline için doğal `occurred_at` kaynağıdır.

### Follow-up neden observation ile aynı satır değildir?

Mevcut `app/field_tracking.py` durum sözlüğü şöyledir:

```python
class FollowUpStatus(str, Enum):
    INBOX = "inbox"
    ACTIVE = "active"
    WAITING = "waiting"
    COMPLETED = "completed"
    CANCELLED = "cancelled"
```

- `Enum`, izin verilen değerleri açık bir listeye sınırlar.
- `INBOX`, henüz planlanmamış hızlı yakalamadır.
- `ACTIVE`, planlı açık iştir.
- `WAITING`, başka kişi veya koşul için beklenen açık iştir.
- `COMPLETED`, tamamlanmış terminal durumdur.
- `CANCELLED`, iptal edilmiş terminal durumdur.

Observation'ın `tracking` durumu ile follow-up'ın `waiting` durumu aynı kelime
ve aynı yaşam döngüsü değildir. Bu yüzden source tabloları birleştirmiyoruz.
Ortak filtre için ikisini daha küçük bir sözlüğe map ediyor, ayrıntıyı ayrıca
`status_detail` içinde saklıyoruz.

### Routine occurrence neden template bağımlılığı taşır?

Mevcut occurrence kaydı şöyledir:

```python
@dataclass(frozen=True, slots=True)
class RoutineOccurrence:
    routine_occurrence_id: str
    routine_template_id: str
    occurrence_local_date: str
    scheduled_local_time: str
    scheduled_at_utc: str
    status: RoutineOccurrenceStatus
    next_attention_at: str
    revision: int
    created_at: str
    outcome_type: RoutineOccurrenceOutcome | None = None
    outcome_note: str | None = None
    completed_at: str | None = None
```

- `frozen=True`, nesnenin yerinde değiştirilmesini engeller; mutation yeni nesne
  üreterek yapılır.
- `slots=True`, alan kümesini sabitler ve küçük veri nesnelerinde gereksiz
  attribute sözlüğünü kaldırır.
- `routine_occurrence_id`, gerçekleşmenin kaynak kimliğidir.
- `routine_template_id`, hangi şablondan üretildiğini gösterir.
- `occurrence_local_date` ve `scheduled_local_time`, İstanbul yerel takvim
  snapshot'ıdır.
- `scheduled_at_utc`, aynı planın kalıcı UTC karşılığıdır.
- `next_attention_at`, snooze ile değişebilir; olayın özgün plan zamanı değildir.
- `status` ve `outcome_type`, açık/kapalı yaşam döngüsünü anlatır.
- Kayıtta title, project ve importance alanı bulunmaz; bugünkü UI bunları
  template bağlamından alır.

Son madde önemlidir: projector template'i okursa template revision'ını da drift
hesabına katmalıdır. Aksi halde template başlığı değiştiğinde `RecordRef`in eski
kaldığını anlayamayız.

## Teknik kavramlar

### Read-model

Yazma kurallarını yönetmeyen, belirli okuma ihtiyaçları için hazırlanmış
türetilmiş veri görünümüdür. Source of truth değildir.

### Projection

Kaynak veriyi kararlı kurallarla read-model alanlarına dönüştürme işlemidir.

### Source of truth

Bir bilginin nihai ve yetkili kaynağıdır. Bu ADR'de domain aggregate satırı ile
append-only event geçmişidir.

### Idempotency

Aynı işlemi tekrar çalıştırınca ikinci bir kayıt veya farklı sonuç üretmeme
özelliğidir. Aynı source iki kez project edilirse tek `RecordRef` kalır.

### Composite key

Bir satırı tek alan yerine birden fazla alanın birlikte tanımlamasıdır. Burada:

```text
(record_type, source_id)
```

### Fingerprint

Projection girdilerinin canonical gösteriminden hesaplanan SHA-256 özetidir.
Girdi değiştiğinde özet değişir ve drift görünür olur.

### Drift

Source truth ile türetilmiş read-model arasındaki eksik, fazla veya eski değer
farkıdır. Drift source'u otomatik değiştirme yetkisi vermez.

### Shadow generation

Aktif index'i yarım bırakmadan, yeni index neslini ayrı yerde tamamlayıp bütün
kontrollerden sonra atomik biçimde aktif etme yaklaşımıdır.

## Kimlik kararını adım adım anlamak

Yalnız `source_id` yeterli değildir. İki farklı domain tablosunda teorik olarak
aynı UUID bulunabilir. Bu yüzden anahtar türü de taşır:

```python
key = (record_type, source_id)
```

Tek string isteyen consumer için rastgele UUID üretmek yerine deterministic bir
token kullanıyoruz:

```python
record_ref_id = f"cse-record-ref/v1/{record_type}/{source_id}"
```

Satır satır:

- `f"..."`, Python f-string ile değişkenleri metne yerleştirir.
- `cse-record-ref`, token'ın hangi sözleşmeye ait olduğunu belli eder.
- `v1`, formatın ileride kontrollü değişebilmesini sağlar.
- `record_type`, aynı UUID'nin farklı domain türlerindeki çakışmasını önler.
- `source_id`, source aggregate'e geri dönmeyi sağlar.

Bu değer rebuild sonrasında değişmez. Auto-increment veya random UUID kullansak
aynı source restore/rebuild sonrasında farklı bir ref kimliği alabilirdi.

## Ortak alan mapping'i

| Ortak alan | Observation | Follow-up | Routine occurrence |
| --- | --- | --- | --- |
| `occurred_at` | `observed_at` | `created_at` | `scheduled_at_utc` |
| `project_id` | source project | nullable source project | mevcutta template project |
| `scope` | `project` compatibility | `private` compatibility | `private` compatibility |
| `importance` | `False` | `is_important` | mevcutta template `is_important` |
| `archived_at` | source alan | `None` | `None` |
| `title` | description | title | template title + yerel tarih |
| `source_revision` | observation revision | follow-up revision | occurrence revision |

“Compatibility” sözcüğü şu nedenle kullanıldı: ADR-0001 scope kararını verdi
ama source tablolara scope alanı henüz eklenmedi. Projection implementation'ı
olmayan bir alan varmış gibi davranamaz. İlk sürüm ADR-0001'in deterministic
backfill kuralını kullanır; gerçek source scope alanı eklendiğinde
`projection_version` artar ve index yeniden kurulur.

## Status neden iki alana ayrıldı?

Ortak dashboard basit bir açık/bekleyen/tamamlanan/iptal filtresi ister. Fakat
source ayrıntısını silmek istemeyiz.

```text
status        = ortak filtre
status_detail = kaynak ayrıntısı
```

Örnekler:

| Source değer | `status` | `status_detail` |
| --- | --- | --- |
| observation `tracking` | `open` | `tracking` |
| follow-up `waiting` | `waiting` | `waiting` |
| follow-up completed/not_required | `completed` | `completed:not_required` |
| occurrence closed/missed | `completed` | `closed:missed` |

Böylece ortak filtre kolaylaşır ama “çalışma yok”, “gerekli değil” veya
“missed” gibi kaynak anlamları kaybolmaz.

## Search text nasıl üretilecek?

Bu ADR semantic arama veya AI eklemez. Yalnız literal aramaya kararlı bir metin
hazırlar. Kavramsal projector kodu şöyle görünür:

```python
def build_search_text(parts: list[str | None]) -> str:
    normalized: list[str] = []
    for part in parts:
        if part is None:
            continue
        value = normalize_nfkc_and_whitespace(part)
        if value:
            normalized.append(value)
    return "\n".join(normalized)
```

Satır satır:

- Fonksiyon nullable metin parçaları listesi alır.
- `normalized`, geçerli parçaları sabit sırada biriktirir.
- `None` alanlar atlanır.
- Her parça Unicode NFKC ve whitespace kuralından geçer.
- Normalization sonrası boş değer eklenmez.
- Parçalar newline ile birleşir; alan sınırları kaybolmaz.

Bu kod ADR'deki algoritmayı öğretmek için verilmiştir; Issue #147 production
fonksiyonu eklememiştir.

## Transaction akışı

Mevcut servisler source mutation ile event'i aynı Unit of Work içinde commit
ediyor. Gelecekte projector bunun yanına eklenir:

```text
Kullanıcı mutation ister
-> güncel aggregate ve expected revision doğrulanır
-> yeni aggregate yazılır
-> append-only event yazılır
-> aynı aggregate'den RecordRef üretilir
-> composite key ile idempotent upsert yapılır
-> tek commit
```

Hata akışı:

```text
RecordRef upsert başarısız
-> transaction rollback
-> aggregate mutation kalıcı değil
-> event kalıcı değil
-> eski index/source tutarlılığı korunur
```

Bu tasarım crash sonrasında “source güncel ama Hafıza sessizce eski” aralığını
normal mutation yolunda kapatır.

## Rebuild neden aktif tabloyu silerek başlamıyor?

Şu yaklaşım tehlikelidir:

```text
aktif index'i sil
-> kayıtları sırayla yeniden ekle
-> ortada hata oluşur
-> kullanıcı yarım index görür
```

Seçilen yaklaşım:

```text
shadow generation oluştur
-> bütün kayıtları doldur
-> uniqueness/count/fingerprint/privacy doğrula
-> tek transaction ile active generation yap
```

Bir hata olursa eski doğrulanmış generation kalır ve `stale/failed` durumu
görünür olur. İlk generation bile oluşmamışsa sistem boş sonucu başarı gibi
göstermez.

## Teknik karar tablosu

| Karar | Seçim | Neden | Reddedilen |
| --- | --- | --- | --- |
| Source modeli | Ayrı domain tabloları | Yaşam döngüleri farklı | Tek source tablo |
| Ref anahtarı | `(record_type, source_id)` | Türler arası çakışmayı önler | Yalnız source ID |
| Tekil token | Deterministic v1 string | Rebuild/restore kararlılığı | Random UUID |
| Status | Ortak status + detail | Ortak filtre ve kayıpsız ayrıntı | Source status'u silmek |
| Güncelleme | Transactional upsert + rebuild | Crash güvenliği ve repair yolu | Yalnız async projector |
| Rebuild | Shadow generation | Partial görünürlüğü önler | Yerinde delete/refill |
| Drift | Read-only diagnostic | Source truth korunur | Otomatik source repair |
| Scope | ADR-0001 source/compatibility | Private sızıntısını önler | Project ID'den inference |
| Resmî output | Source'u yeniden doğrula | Projection stale olabilir | Index'i tek otorite yapmak |

## Test kodu nasıl görünmeli?

Bu Issue test eklemedi; çünkü production implementation yok. Sonraki görevde
aşağıdaki gibi executable testler gerekir:

```python
def test_same_source_is_projected_idempotently(memory_index, projector):
    source = observation_fixture(revision=3)

    first = projector.upsert_observation(source)
    second = projector.upsert_observation(source)

    assert first.record_ref_id == second.record_ref_id
    assert memory_index.count() == 1
    assert second.source_revision == 3
```

Satır satır test açıklaması:

- Test, geçici/izole bir `memory_index` ve projector fixture'ı alır.
- Revision 3 olan aynı source observation hazırlanır.
- Source ilk kez project edilir.
- Aynı source ikinci kez project edilir.
- İki dönüşte kararlı ref kimliğinin aynı olduğu doğrulanır.
- Index'te duplicate oluşmadığı, count'un bir kaldığı doğrulanır.
- Source revision'ın doğru taşındığı kontrol edilir.

Transaction rollback testi:

```python
def test_projection_failure_rolls_back_source_and_event(service, uow):
    uow.memory_index.fail_next_upsert = True

    with pytest.raises(ProjectionError):
        service.update_status(OBSERVATION_ID, expected_revision=1, new_status="tracking")

    assert uow.observations.get(OBSERVATION_ID).revision == 1
    assert uow.events.list_for_observation(OBSERVATION_ID) == [CREATED_EVENT]
```

- İlk satır, projection yazısını kontrollü olarak başarısız yapar.
- Mutation'ın hata üretmesi beklenir.
- Observation revision'ın artmadığı doğrulanır.
- Yeni status event'inin kalıcı olmadığı; yalnız eski created event'in kaldığı
  doğrulanır.

Rebuild testi ayrıca iki çalıştırmada aynı sıra/fingerprint'i, ortadaki hatada
shadow generation'ın active olmamasını ve private metnin diagnostic log'a
girmemesini doğrulamalıdır.

## Tüketici sınırını bir örnekle okuyalım

Bir private follow-up'ın `project_id` değeri dolu olabilir. Hafıza filtresi bu
kaydı projeyle ilişkili gösterebilir. Fakat Proje Paketi üretirken şu kontrol
zorunludur:

```text
MemoryIndex adayı bulur
-> source follow-up yeniden okunur
-> source scope kontrol edilir
-> scope private ise export reddedilir
-> project ID dolu olması kararı değiştirmez
```

Bu iki aşama, read-model'in kullanım kolaylığı ile resmî çıktı güvenliğini
birbirinden ayırır.

## Şunu şöyle yaptık ki...

Şunu şöyle yaptık ki, kullanıcı üç ayrı kayıt sisteminde arama yapmak zorunda
kalmasın ama kolaylık uğruna source yaşam döngüleri ve private/resmî sınırı
bozulmasın:

- source tabloları ayrı bıraktık;
- ortak görünümü yeniden üretilebilir projection yaptık;
- ref kimliğini composite source kimliğinden deterministic türettik;
- ortak status'u filtre için küçülttük, kaynak ayrıntısını ayrıca koruduk;
- normal mutation'ı projection ile aynı transaction'a bağladık;
- rebuild'i shadow generation ve explicit maintenance ile sınırlandırdık;
- drift'i görünür diagnostic yaptık, otomatik source repair'i yasakladık;
- resmî output'un source scope/project değerini yeniden doğrulamasını zorunlu
  tuttuk.

## Bu adımda bilinçli olarak yapılmayanlar

- Python `RecordRef` dataclass'ı yazılmadı.
- SQLite `memory_index` tablosu veya migration eklenmedi.
- Projector, repository, Unit of Work, CLI veya background worker yazılmadı.
- Hafıza ekranı, route, template veya CSS değiştirilmedi.
- Scope alanı/backfill'i uygulanmadı.
- Backup, Hafızayı İndir veya Proje Paketi formatı değiştirilmedi.
- Test eklenmedi; yukarıdaki testler sonraki implementation için öğretici kabul
  örnekleridir.

Bu sınır önemlidir: ADR bize **ne yapılacağını ve hangi değişmezlerin
korunacağını** söyler; implementation görevi bunun **nasıl kodlanacağını ve
çalıştığını testlerle** kanıtlar.
