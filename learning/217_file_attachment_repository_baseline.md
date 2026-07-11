# Step 217 - FileAttachmentRepository Baseline Ogrenme Notu

## Amac

Bu dosya, Step 217'de eklenen `FileAttachmentRepository` sinifini Python ogrenme acisindan aciklar.

Bu adimda yeni bir model olusturmadik. Zaten var olan `FileAttachmentRecord` nesnelerini bellekte tutan kucuk bir repository ekledik.

## Hangi Dosyalarda Ne Yaptik?

| Dosya | Ne yapildi? | Neden yapildi? |
| --- | --- | --- |
| `app/records.py` | `FileAttachmentRecord` import edildi ve `FileAttachmentRepository` eklendi. | Attachment metadata record'larini bellek icinde ekleme, listeleme, sayma ve id ile bulma davranisi icin. |
| `tests/test_records.py` | `_file_attachment(...)` helper'i ve 8 focused repository testi eklendi. | Repository'nin dar davranis sozlesmesini kanitlamak icin. |
| `docs/217_file_attachment_repository_baseline.md` | Teknik kapsam ve sinir dokumante edildi. | Dosya operasyonu, linking ve persistence eklenmedigini kalici olarak aciklamak icin. |
| `.cse/state/project_state.json` | Step 217 active work ve Step 216 latest safe point bilgisi kaydedildi. | Makine okunabilir proje durumunu guncel tutmak icin. |

## Eklenen Kod

`app/records.py` icindeki yeni sinif:

```python
class FileAttachmentRepository:
    """Stores file attachment metadata records in memory."""

    def __init__(self) -> None:
        self._records: list[FileAttachmentRecord] = []

    def add(self, record: FileAttachmentRecord) -> None:
        if self.find_by_id(record.attachment_id) is not None:
            raise ValueError(
                f"FileAttachmentRecord with id '{record.attachment_id}' already exists."
            )
        self._records.append(record)

    def list_all(self) -> list[FileAttachmentRecord]:
        return list(self._records)

    def count(self) -> int:
        return len(self._records)

    def find_by_id(self, attachment_id: str) -> FileAttachmentRecord | None:
        for record in self._records:
            if record.attachment_id == attachment_id:
                return record
        return None
```

## Satir Satir Aciklama

```python
class FileAttachmentRepository:
```

Bu satir yeni bir class tanimlar. Class, birlikte calisan veri ve fonksiyonlari ayni isim altinda toplar.

```python
"""Stores file attachment metadata records in memory."""
```

Bu bir docstring'dir. Sinifin ne yaptigini kisa aciklar.

```python
def __init__(self) -> None:
    self._records: list[FileAttachmentRecord] = []
```

`__init__`, siniftan yeni nesne olusturulunca otomatik calisir.

`self._records`, repository'nin ic listesi olur.

`list[FileAttachmentRecord]`, bu listenin `FileAttachmentRecord` nesneleri tutmasi beklendigini anlatan type hint'tir.

```python
def add(self, record: FileAttachmentRecord) -> None:
```

`add`, repository'ye yeni bir metadata record ekler.

`record: FileAttachmentRecord`, bu method'a bir `FileAttachmentRecord` verilmesi beklendigini soyler.

`-> None`, method'un basarili olunca bir deger dondurmedigini anlatir.

```python
if self.find_by_id(record.attachment_id) is not None:
```

Yeni record eklenmeden once ayni `attachment_id` ile mevcut kayit var mi diye bakilir.

`is not None`, "bir kayit bulundu" anlamina gelir.

```python
raise ValueError(...)
```

Ayni id zaten varsa hata firlatilir. Bu sayede ayni attachment metadata kimligi iki kez repository'ye girmez.

```python
self._records.append(record)
```

Duplicate yoksa record ic listeye eklenir.

```python
def list_all(self) -> list[FileAttachmentRecord]:
    return list(self._records)
```

`list_all`, tum kayitlari verir.

Burada `self._records` dogrudan dondurulmez. `list(self._records)` ile yeni bir liste kopyasi dondurulur.

Onemli ayrim: Liste kopyalanir ama icindeki record nesneleri kopyalanmaz. Yani kullanici donen listeyi temizlerse repository'nin ic listesi bozulmaz; ama listedeki record ayni record nesnesidir.

```python
def count(self) -> int:
    return len(self._records)
```

`count`, repository icindeki record sayisini dondurur.

```python
def find_by_id(self, attachment_id: str) -> FileAttachmentRecord | None:
```

`find_by_id`, verilen attachment id ile kayit arar.

Donus tipi `FileAttachmentRecord | None` olarak yazildi. Bu, "kayit bulunursa record, bulunamazsa None" demektir.

```python
for record in self._records:
    if record.attachment_id == attachment_id:
        return record
return None
```

Repository icindeki her record sirasiyla kontrol edilir. `==` exact ve case-sensitive karsilastirma yapar. `att-001` ile `ATT-001` farkli kabul edilir.

## Test Helper'i

Testlerde tekrar tekrar uzun `FileAttachmentRecord(...)` yazmamak icin helper ekledik:

```python
def _file_attachment(
    attachment_id: str,
    *,
    related_record_type: str = "nonconformity",
    related_record_id: str = "NCR-001",
    file_name: str = "photo_001.jpg",
    file_path: str = "attachments/PRJ-001/nonconformity/NCR-001/photo_001.jpg",
    file_type: str = "image",
    mime_type: str = "image/jpeg",
    uploaded_at: str | None = "2026-07-11T20:00:00",
    uploaded_by: str | None = "Santiye sefi",
    original_file_name: str | None = "IMG_0001.JPG",
    description: str | None = "Saha kanit fotografi.",
    notes: str | None = "Mevcut metadata aynen korunmali.",
    file_size: int | None = 2048,
) -> FileAttachmentRecord:
    return FileAttachmentRecord(...)
```

Buradaki `*`, `attachment_id` disindaki parametrelerin isimle verilmesini zorunlu yapar.

Ornek:

```python
_file_attachment("att-002", file_name="photo_002.jpg")
```

Bu, testleri okunabilir tutar.

## Testler Neyi Dogruladi?

| Test | Neyi kanitlar? |
| --- | --- |
| `test_file_attachment_repository_starts_empty` | Yeni repository bos liste, `0` count ve missing id icin `None` dondurur. |
| `test_file_attachment_repository_adds_and_finds_same_record_object` | Eklenen record ayni nesne olarak bulunur. |
| `test_file_attachment_repository_preserves_insertion_order_for_distinct_records` | Farkli record'lar ekleme sirasiyla listelenir. |
| `test_file_attachment_repository_rejects_duplicate_exact_id_without_changing_contents` | Duplicate exact id reddedilir ve mevcut liste bozulmaz. |
| `test_file_attachment_repository_keeps_case_different_ids_distinct` | `att-001` ve `ATT-001` farkli id kabul edilir. |
| `test_file_attachment_repository_list_all_returns_copy` | Donen listeyi disarida degistirmek repository ic listesini degistirmez. |
| `test_file_attachment_repository_does_not_mutate_attachment_metadata_fields` | Repository record alanlarini trim/normalize/update etmez. |
| `test_file_attachment_repository_does_not_change_existing_record_repositories` | Existing `FieldObservationRepository` ve `NonconformityRepository` davranislari korunur. |

## Teknik Karar Tablosu

| Karar | Neden? | Alternatif neden ertelendi? |
| --- | --- | --- |
| In-memory repository kullanildi. | Mevcut proje pattern'i bu ve test etmesi kolay. | Persistence ayri riskli adim gerektirir. |
| Kimlik `attachment_id` oldu. | `FileAttachmentRecord` icindeki dogal metadata kimligi bu alan. | Related-record filtreleri bu adimin kapsami degil. |
| Duplicate detection exact/case-sensitive. | Proje son adimlarda exact string davranisini bilincli koruyor. | Normalization yeni kural ve validation demek olurdu. |
| `list_all()` liste kopyasi dondurur. | Disaridan liste mutation'i repository storage'i bozmasin. | Record nesnelerini kopyalamak mevcut in-memory repository pattern'ine aykiri olurdu. |
| Dosya sistemi hic kullanilmadi. | Step 217 metadata repository baseline'dir. | Upload/scanner/path safety ayri gorevlerdir. |

## Kod Calisma Akisi

```text
FileAttachmentRecord olusturulur
-> FileAttachmentRepository.add(record) cagrilir
-> repository ayni attachment_id var mi diye find_by_id ile bakar
-> yoksa record ic listeye eklenir
-> list_all/count/find_by_id repository ic listesinden cevap verir
```

Duplicate durumda akis:

```text
FileAttachmentRepository.add(record)
-> find_by_id(record.attachment_id) mevcut record bulur
-> ValueError firlatilir
-> yeni record eklenmez
-> eski repository icerigi korunur
```

## Yeni Terimler

### Repository

Repository, record nesnelerini saklama ve onlara erisme davranisini kapsulleyen siniftir. Bu adimda repository sadece bellekte calisir.

### In-memory

In-memory, verinin sadece program calisirken RAM icinde tutulmasi demektir. Program kapaninca bu repository icindeki veriler kalici olarak saklanmaz.

### Metadata

Metadata, dosyanin kendisi degil; dosya hakkindaki bilgidir. Ornek: dosya adi, dosya yolu, dosya tipi, MIME tipi, yukleyen kisi ve iliskili kayit id.

### Case-sensitive

Case-sensitive, buyuk/kucuk harfin farkli kabul edilmesi demektir. `att-001` ve `ATT-001` ayni sayilmaz.

### Mutation

Mutation, bir nesnenin mevcut alanlarini degistirmek demektir. Step 217 repository record metadata alanlarini mutate etmez.

### Type hint

Type hint, Python kodunda bir degiskenin veya fonksiyon donusunun hangi tipte olmasi beklendigini gosteren ipucudur. Ornek: `list[FileAttachmentRecord]`.

## Sunu Soyle Yaptik Ki...

Sunu soyle yaptik ki dosya eki hattini bir anda buyutup riskli hale getirmeyelim:

- Sadece metadata record repository'si ekledik.
- Fiziksel dosyaya dokunmadik.
- Observation-specific attachment linking eklemedik.
- Persistence veya JSON kayit eklemedik.
- Validation kurallarini genisletmedik.
- Mevcut repository davranis desenini kullandik.

Boylece CSE, attachment hattinda ilk repository temelini atmis oldu; ama dosya operasyonlari, upload flow ve kalici veri saklama daha sonra ayri, kucuk ve testli adimlarla ele alinacak.
