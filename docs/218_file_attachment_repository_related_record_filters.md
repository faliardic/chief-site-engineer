# Adim 218 - FileAttachmentRepository Related-Record Filtreleri

Bu adimda mevcut `FileAttachmentRepository`, kayitli dosya eki metadata nesnelerini
bagli olduklari kayit tipi veya kayit id'si uzerinden listeleyebilir hale getirildi.

Bu davranis fiziksel dosya islemi degildir. Repository yalnizca bellekte duran
`FileAttachmentRecord` nesnelerinin `related_record_type` ve `related_record_id`
alanlarini okur.

## Eklenen Methodlar

`app/records.py` icinde `FileAttachmentRepository` sinifina iki method eklendi:

```python
def list_by_related_record_type(
    self,
    related_record_type: str,
) -> list[FileAttachmentRecord]:
    ...
```

```python
def list_by_related_record_id(
    self,
    related_record_id: str,
) -> list[FileAttachmentRecord]:
    ...
```

## Davranis Sozlesmesi

- Filtreler yalniz mevcut bellek ici `_records` listesini okur.
- Karsilastirma exact string equality ile yapilir.
- Karsilastirma case-sensitive davranir.
- Trim, normalize, map, parse veya validate islemi yapilmaz.
- Eslestirme bulunamazsa `[]` dondurulur.
- Insertion order korunur.
- Her cagri yeni bir liste dondurur.
- Liste icindeki elemanlar ayni stored `FileAttachmentRecord` nesneleridir.
- Metadata alanlari kopyalanmaz veya mutate edilmez.
- Type filtresi ve id filtresi birbirinden bagimsizdir.
- Bagli kaydin gercekten var olup olmadigi kontrol edilmez.

## Bilerek Eklenmeyenler

- Combined `related_record_type + related_record_id` filtresi.
- `list_for_field_observation(...)` gibi kayit tipine ozel convenience method.
- `FieldObservationRepository` veya `NonconformityRepository` icine attachment lookup.
- Otomatik dosya eki olusturma veya baglama.
- Fiziksel dosya kopyalama, silme, tasima, okuma veya path kontrolu.
- JSON, SQLite, database veya persistence.
- Validation, enum, constants veya lifecycle kurallari.
- API, GUI veya CLI.
- Audit, history, task, NCR, notification veya decision generation.
- Podcast 034 veya Step 219.

## Test Kapsami

`tests/test_records.py` icinde related-record filtreleri icin focused testler eklendi.
Bu testler su konulari kilitler:

- `related_record_type` icin exact match, siralama, unknown/case/whitespace davranisi.
- `related_record_id` icin exact match, siralama, unknown/case/whitespace davranisi.
- Type ve id filtrelerinin birbirinden bagimsiz kalmasi.
- Bos repository icin `[]` donmesi.
- Donen listelerin yeni liste olmasi.
- Donen kayitlarin ayni stored object olmasi.
- Metadata alanlarinin degismemesi.
- Filtreleme sirasinda kayit sayisi ve repository siralamasinin degismemesi.
- Mevcut `FileAttachmentRepository`, `FieldObservationRepository` ve
  `NonconformityRepository` davranislarinin korunmasi.

## Saha Acisindan Anlami

Bu adim, dosya eki metadata'sini "hangi kayda bagli?" sorusu icin daha okunur
hale getirir. Ornegin ileride bir saha gozlemi veya uygunsuzluk kaydi acildiginda,
ona bagli fotograflari listeleme ihtiyaci dogabilir. Bu adim bu ihtiyacin en
kucuk ve testli repository temelini atar.

Yine de bu henuz tam attachment entegrasyonu degildir. Dosyanin diskte varligi,
path guvenligi, upload/download akisi veya bagli record'un varligi bu adimda
kontrol edilmez.
