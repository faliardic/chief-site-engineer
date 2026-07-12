# Adim 220 - FileAttachmentRepository Combined Related-Record Filter

Bu adimda `FileAttachmentRepository`, attachment metadata kayitlarini
`related_record_type` ve `related_record_id` alanlari birlikte eslesecek sekilde
listeleyebilir hale getirildi.

Bu davranis Step 219'da dokumante edilen exact relationship query sinirinin
ilk production implementation'idir.

## Eklenen Method

`app/records.py` icindeki `FileAttachmentRepository` sinifina su method eklendi:

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

## Davranis Sozlesmesi

- Method yalniz mevcut bellek ici `_records` koleksiyonunu okur.
- Bir record ancak iki kosul ayni record uzerinde birlikte dogruysa eslesir:

```text
record.related_record_type == related_record_type
record.related_record_id == related_record_id
```

- Karsilastirmalar exact string equality ile yapilir.
- Karsilastirmalar case-sensitive davranir.
- Trim, normalize, parse, map, alias veya prefix inference yapilmaz.
- Validation yapilmaz.
- Insertion order korunur.
- Empty repository, unknown pair veya partial match icin `[]` dondurulur.
- Her cagri yeni liste dondurur.
- Liste icindeki elemanlar ayni stored `FileAttachmentRecord` nesneleridir.
- Metadata alanlari kopyalanmaz veya mutate edilmez.
- Related record'un gercekten var olup olmadigi kontrol edilmez.
- Step 218 ile gelen independent type ve id filtreleri degismeden kalir.

## Neden Combined Filter Gerekliydi?

Step 218 iki bagimsiz filtre eklemisti:

```python
list_by_related_record_type("field_observation")
list_by_related_record_id("obs-001")
```

Bu filtreler tek tek yararlidir, fakat safe relationship query sayilmaz.
Cunku ayni id degeri farkli record type altinda kullanilabilir.

Ornek:

```text
FileAttachmentRecord A:
  related_record_type = "field_observation"
  related_record_id = "shared-001"

FileAttachmentRecord B:
  related_record_type = "nonconformity"
  related_record_id = "shared-001"
```

`list_by_related_record_id("shared-001")` iki kaydi da dondurebilir. Ancak field
observation attachment iliskisi icin type ve id ayni metadata kaydinda birlikte
eslesmelidir.

`list_by_related_record("field_observation", "shared-001")` bu nedenle yalniz
`FileAttachmentRecord A` kaydini dondurur.

## Test Kapsami

`tests/test_records.py` icinde `combined_related_record` focused testleri
eklendi.

Bu testler sunlari dogrular:

- Exact type+ID pair eslesen kayitlar insertion order ile doner.
- Ayni id, farkli type altinda ise sonuc disinda kalir.
- Ayni type, farkli id altinda ise sonuc disinda kalir.
- Case-different ve whitespace-different type/id degerleri exact query ile
  eslesmez.
- Empty repository ve unknown pair `[]` dondurur.
- Her cagri yeni liste dondurur.
- Disarida donen liste mutate edilirse repository contents bozulmaz.
- Donen elemanlar ayni stored object referanslaridir.
- Metadata alanlari mutate edilmez.
- Filtering repository count ve `list_all()` order davranisini degistirmez.
- Missing related-record existence repository tarafindan validate edilmez.
- Existing independent filters, baseline attachment repository methods,
  `FieldObservationRepository` ve `NonconformityRepository` davranislari korunur.

Focused test komutu:

```powershell
python -m pytest tests/test_records.py -k "file_attachment_repository and combined_related_record"
```

## Bilerek Eklenmeyenler

Bu adimda sunlar eklenmedi:

- `list_for_field_observation(...)` convenience helper.
- Baska record-type-specific convenience method.
- `FieldObservationRepository`, `NonconformityRepository` veya baska repository
  lookup'i.
- Automatic attachment creation.
- Relationship validation, repair, deletion, relinking, warning, task, NCR,
  audit veya blocking.
- Physical file upload/download/copy/move/rename/delete/preview/thumbnail/
  compression/ZIP davranisi.
- Filesystem existence/readability/integrity check.
- Path generation, normalization, allowed-root enforcement veya file writing.
- Persistence/database/JSON/SQLite.
- Status/archive/lifecycle behavior.
- Model field, validation, enum, constant, migration veya hard validation.
- API/GUI/CLI.
- Podcast 034.
- Step 221 implementation.

## Saha Acisindan Anlam

Bu adim, bir saha gozlemine veya baska bir kayda bagli attachment metadata
kayitlarini daha guvenli okumak icin en kucuk repository davranisini ekler.

Bir santiye sefi ileride saha gozlemi detayinda attachment listesi gormek
istediginde, sistemin yalniz id'ye bakmasi yeterli olmayacaktir. Ayni id farkli
kayit tiplerinde kullanilabilir. Bu nedenle combined filter, type ve id'yi ayni
metadata kaydinda birlikte arar.

Bu henuz field-ready attachment UI veya upload/persistence akisi degildir.
Yalnizca attachment metadata repository icinde dogru relationship query
temelidir.

## Sonraki Dogal Dokumantasyon Adimi

Step 220, Steps 216-220 araligini teknik olarak tamamlayan adimdir. Podcast 034
bu adimda olusturulmadi. Step 220 merge edildikten sonra Podcast 034 icin dogal
dokumantasyon araligi Steps 216-220 olur.
