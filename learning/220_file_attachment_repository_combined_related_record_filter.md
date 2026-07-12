# Adim 220 - Combined Related-Record Filter Ogrenme Notu

Bu adimda `FileAttachmentRepository` icine combined related-record filter
ekledik:

```python
list_by_related_record(related_record_type, related_record_id)
```

Bu method, attachment metadata kaydinin iki alanini ayni anda kontrol eder:

```text
related_record_type
related_record_id
```

## Hangi Dosyada Ne Yaptik?

| Dosya | Ne yapildi? | Neden yapildi? |
| --- | --- | --- |
| `app/records.py` | `FileAttachmentRepository.list_by_related_record(...)` eklendi. | Type ve id ayni metadata kaydinda birlikte eslessin diye. |
| `tests/test_records.py` | `combined_related_record` focused testleri eklendi. | Exact pair, partial match rejection, yeni liste, ayni object ve regresyon davranislari kilitlensin diye. |
| `docs/220_file_attachment_repository_combined_related_record_filter.md` | Davranis sozlesmesi ve kapsam siniri yazildi. | Bu methodun convenience lookup, validation veya persistence sanilmamasi icin. |
| `learning/220_file_attachment_repository_combined_related_record_filter.md` | Python ve veri modelleme aciklamasi eklendi. | Kullanici `and`, list comprehension ve combined query mantigini ogrensin diye. |
| `.cse/state/project_state.json`, `README.md`, `ROADMAP.md`, `CHANGELOG.md`, `docs/project_decisions.md`, `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md` | Repo truth Step 220'ye gore guncellendi. | Insan ve makine tarafindan okunan proje hafizasi ayni gercegi soylesin diye. |

## Eklenen Kod

`app/records.py` icindeki yeni method:

```python
def list_by_related_record(
    self,
    related_record_type: str,
    related_record_id: str,
) -> list[FileAttachmentRecord]:
    return [
        record
        for record in self._records
        if record.related_record_type == related_record_type
        and record.related_record_id == related_record_id
    ]
```

## Satir Satir Aciklama

```python
def list_by_related_record(
```

Yeni repository method'u baslar. Method adi, related record type ve id ciftine
gore listeleme yaptigini soyler.

```python
    self,
```

`self`, repository nesnesinin kendisidir. Bu sayede method `self._records`
listesine erisir.

```python
    related_record_type: str,
    related_record_id: str,
```

Method disaridan iki string alir. Ornek:

```python
"field_observation", "obs-001"
```

```python
) -> list[FileAttachmentRecord]:
```

Methodun `FileAttachmentRecord` nesnelerinden olusan bir liste dondurecegini
anlatan type hint'tir.

```python
    return [
```

Sonuc yeni bir liste olarak dondurulur.

```python
        record
        for record in self._records
```

Repository'nin icindeki attachment metadata kayitlari sirayla gezilir.

```python
        if record.related_record_type == related_record_type
```

Once kaydin type alani verilen type ile exact olarak karsilastirilir.

```python
        and record.related_record_id == related_record_id
```

Sonra ayni kaydin id alani verilen id ile exact olarak karsilastirilir.

Buradaki `and`, iki kosulun da dogru olmasini ister. Bir kosul dogru, digeri
yanlissa record sonuc listesine girmez.

## Neden `and` Kullandik?

Step 218'de iki bagimsiz filtre vardi:

```python
list_by_related_record_type("field_observation")
list_by_related_record_id("obs-001")
```

Bunlar ayri ayri yararlidir. Ama relationship query icin yeterli degildir.

Dusunelim:

```python
field_attachment.related_record_type == "field_observation"
field_attachment.related_record_id == "shared-001"
```

```python
ncr_attachment.related_record_type == "nonconformity"
ncr_attachment.related_record_id == "shared-001"
```

Sadece id'ye bakarsak iki attachment da `shared-001` sonucuna girer.

Ama field observation attachment listesi icin su iki kosul birlikte gerekir:

```python
record.related_record_type == "field_observation"
and record.related_record_id == "shared-001"
```

Bu yuzden combined filter ekledik.

## Partial Match Nedir?

Partial match, kosullardan sadece birinin eslesmesidir.

Ornek 1:

```text
type dogru, id yanlis
```

```python
record.related_record_type == "field_observation"
record.related_record_id == "obs-002"
```

Query:

```python
list_by_related_record("field_observation", "obs-001")
```

Bu record sonuc listesine girmemelidir.

Ornek 2:

```text
id dogru, type yanlis
```

```python
record.related_record_type == "nonconformity"
record.related_record_id == "obs-001"
```

Query:

```python
list_by_related_record("field_observation", "obs-001")
```

Bu record da sonuc listesine girmemelidir.

## Sunu Soyle Yaptik Ki...

Sunu soyle yaptik ki id carpisma riski sonuc listesine karismasin:

```python
if record.related_record_type == related_record_type
and record.related_record_id == related_record_id
```

Bu iki kosul ayni `record` uzerinde birlikte kontrol edilir.

Sunu soyle yaptik ki repository sade ve read-only kalsin:

```python
return [
    record
    for record in self._records
    ...
]
```

Kod sadece `_records` listesini okur. Ekleme, silme, repair, validation veya
related observation lookup yapmaz.

Sunu soyle yaptik ki disaridan donen liste repository icini bozmasin:

```python
listed_records = repository.list_by_related_record("field_observation", "obs-001")
listed_records.clear()
```

`clear()` sadece disaridan donen listeyi bosaltir. Repository'nin kendi
`_records` listesi bozulmaz; cunku method her cagrida yeni liste uretir.

Sunu soyle yaptik ki metadata kopyalanmasin:

```python
assert result[0] is record
```

`is`, ayni object reference'i kontrol eder. Method record kopyasi uretmez;
stored `FileAttachmentRecord` nesnesinin kendisini listeye koyar.

## Testler Neyi Dogruladi?

| Test grubu | Neyi kanitlar? |
| --- | --- |
| Exact pair | Type ve id birlikte eslesirse kayitlar insertion order ile doner. |
| Same id / different type | Sadece id eslesmesi yeterli degildir. |
| Same type / different id | Sadece type eslesmesi yeterli degildir. |
| Case/whitespace | Buyuk-kucuk harf ve bosluk farklari exact match'i bozar. |
| Empty/unknown | Bos repository ve bilinmeyen pair `[]` dondurur. |
| New list | Her cagri yeni liste uretir, dis mutation repository'yi bozmaz. |
| Same object | Donen kayitlar stored object referanslaridir. |
| Metadata non-mutation | Filtre record alanlarini degistirmez. |
| Count/order stable | Filtering repository count ve `list_all()` sirasini degistirmez. |
| Missing existence | Repository related observation var mi diye bakmaz. |
| Regression | Existing independent filters ve diger repository davranislari korunur. |

Focused test komutu:

```powershell
python -m pytest tests/test_records.py -k "file_attachment_repository and combined_related_record"
```

## Teknik Karar Tablosu

| Karar | Secilen davranis | Neden |
| --- | --- | --- |
| Match kurali | Type + id ayni record uzerinde birlikte | Safe relationship query icin iki alan da gerekli. |
| String davranisi | Exact, case-sensitive | Step 218 ve Step 219 contract ile uyumlu. |
| Normalization | Yok | Gizli veri degistirme veya alias davranisi olmasin. |
| Donus tipi | Yeni liste | Dis liste mutation'i repository storage'i bozmasin. |
| Nesne davranisi | Same stored object | Metadata kopyalama/mutation yapilmasin. |
| Existence validation | Yok | Repository metadata filtresidir; service/integrity layer ayri konu. |
| Convenience helper | Yok | `list_for_field_observation(...)` ayri future step olabilir. |
| Physical file behavior | Yok | Upload/scanner/path/persistence daha riskli ayri katmanlardir. |

## Kod Calisma Akisi

```text
FileAttachmentRepository.list_by_related_record(type, id)
-> repository._records listesini sirayla gezer
-> her record icin type exact match mi bakar
-> ayni record icin id exact match mi bakar
-> iki kosul da dogruysa record'u yeni sonuc listesine koyar
-> sonuc listesini dondurur
-> repository count/order/metadata degismez
```

## Yeni Terimler

**Combined filter**: Birden fazla kosulu ayni filtrede birlikte kullanan
listeleme davranisi.

**Partial match**: Kosullardan sadece birinin eslesmesi. Bu adimda partial match
sonuca girmez.

**Boolean `and`**: Python'da iki kosulun da dogru olmasini isteyen mantik
operatoru.

**Object reference**: Bir listenin icindeki elemanin nesnenin kopyasi degil,
aynisi olmasi.

**Read-only method**: Veri eklemeyen, silmeyen veya degistirmeyen method.

**Regression test**: Yeni ozellik eklenirken mevcut davranislarin bozulmadigini
kontrol eden test.

## Bu Adimdan Sonra Ne Henuz Yok?

- `list_for_field_observation(...)` yok.
- Field Observation'a ozel convenience lookup yok.
- Related observation var mi kontrolu yok.
- Attachment auto-create veya auto-link yok.
- Dosya upload/download yok.
- Dosya sistemi kontrolu yok.
- Persistence yok.
- API, GUI veya CLI yok.
- Audit, task, NCR veya blocking yok.
- Podcast 034 yok.

Bu sinirlar korundugu icin Step 220, kucuk ama guvenilir bir repository davranisi
olarak kalir.
