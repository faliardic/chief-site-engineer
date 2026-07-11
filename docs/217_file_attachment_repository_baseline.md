# Step 217 - FileAttachmentRepository Baseline

## Amac

Bu adimda mevcut `FileAttachmentRecord` metadata nesneleri icin minimal bellek ici `FileAttachmentRepository` baseline'i eklendi.

Repository yalniz daha once olusturulmus metadata record nesnelerini bellekte saklar. Fiziksel dosya okumaz, kopyalamaz, yuklemez, tasimaz, silmez, kontrol etmez veya normalize etmez.

## Eklenen Sinif

`app/records.py` icine su sinif eklendi:

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

## Davranis Sozlesmesi

- Repository yalniz `FileAttachmentRecord` nesnelerini bellekte tutar.
- Kimlik alani `attachment_id` olarak kullanilir.
- Duplicate `attachment_id` exact ve case-sensitive eslesme ile reddedilir.
- Duplicate durumda `ValueError` firlatilir.
- Case-different attachment id degerleri farkli kimlikler olarak kabul edilir.
- `list_all()` her cagrida yeni bir liste dondurur.
- Donen listedeki record nesneleri kopyalanmaz; repository icindeki ayni nesnelerdir.
- `count()` mevcut record sayisini dondurur.
- `find_by_id(...)` bulunan record icin ayni stored nesneyi, bulunamayan id icin `None` dondurur.
- Repository record alanlarini mutate etmez.

## Test Kapsami

`tests/test_records.py` icinde `test_file_attachment_repository_...` testleri eklendi.

Testler sunlari dogrular:

- yeni repository bos baslar;
- tek record eklendiginde ayni nesne bulunur;
- coklu record ekleme sirasi korunur;
- duplicate exact `attachment_id` reddedilir ve mevcut liste degismez;
- case-different id degerleri farkli record olarak saklanir;
- `list_all()` disaridan mutate edilemeyen liste kopyasi dondurur;
- repository metadata alanlarini degistirmez;
- mevcut `FieldObservationRepository` ve `NonconformityRepository` davranislari korunur.

## Neden Bu Kadar Dar?

Dosya eki hattinda iki ayri konu vardir:

1. metadata kaydini bellekte temsil etmek;
2. fiziksel dosyayi yuklemek, saklamak, tasimak, taramak veya dogrulamak.

Bu adim yalniz birinci konuyu ele alir.

Bu ayrim onemlidir. Cunku dosya yukleme, dosya sistemi erisimi, path guvenligi, upload flow, persistence, audit ve attachment integrity scanner davranislari daha yuksek riskli konulardir. Bunlar ileride ayri issue ile ele alinmalidir.

## Santiye Pratigindeki Karsiligi

Sahada bir fotograf, video, PDF veya belge kanit olarak bir kayda baglanabilir. `FileAttachmentRecord`, bu dosyanin kendisini degil; dosya adi, dosya yolu, dosya tipi, MIME tipi, yukleyen kisi, yukleme zamani ve iliskili kayit kimligi gibi metadata bilgilerini tasir.

`FileAttachmentRepository`, bu metadata kayitlarini gecici bellek ici koleksiyon olarak saklar. Boylece ileride observation attachment linking, upload service, persistence veya scanner gelmeden once metadata record listesi icin temel davranis testli hale gelir.

## Ozellikle Eklenmeyenler

Bu adimda sunlar eklenmedi:

- `list_by_related_record_type`;
- `list_by_related_record_id`;
- combined related-record filtering;
- `FieldObservationRecord` icin attachment lookup veya linking;
- observation'dan otomatik `FileAttachmentRecord` olusturma;
- upload, download, copy, move, rename, delete;
- preview, thumbnail, compression veya ZIP davranisi;
- filesystem existence/readability/integrity check;
- path generation veya normalization;
- allowed-root enforcement;
- persistence/database/JSON/SQLite;
- status/archive lifecycle behavior;
- yeni validation, enum, constants veya hard validation;
- API, GUI veya CLI;
- audit/history/task/NCR/notification/decision generation;
- Step 218 veya Podcast 034.

## Sonraki Dar Adim

Bu baseline merge edildikten sonra attachment hattinda dogal sonraki adimlar sunlardan biri olabilir:

- related-record filtrelerini ayri ve explicit olarak eklemek;
- field observation attachment linking sozlesmesini once dokumante etmek;
- upload service oncesi path ve persistence sinirlarini tekrar netlestirmek.

Bu adimlarin hicbiri Step 217 kapsaminda baslatilmadi.
