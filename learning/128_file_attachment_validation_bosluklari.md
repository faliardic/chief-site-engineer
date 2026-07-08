# Adim 128 - FileAttachmentRecord Validation Bosluklari

## Bu adimda ne yaptik?

Bu adimda `FileAttachmentRecord` modelindeki kucuk validation bosluklarini kapattik.

Zorunlu dosya eki metadata alanlari icin su davranisi netlestirdik:

- `None` degerler kontrollu `ValueError` uretir.
- Bos string ve sadece bosluklardan olusan degerler reddedilir.
- `mime_type` de zorunlu metadata kontrolune dahil edilir.
- `file_type` once bos/None kontrolunden, sonra desteklenen dosya tipi sozlesmesinden gecirilir.

## Neden yaptik?

Dosya eki kaydi, ileride fotograf, video, PDF, belge, ses ve diger dosya kanitlarini takip edecek ana metadata modelidir.

Santiye karsiligi sudur: Bir dosya ekinin kimligi, hangi kayda bagli oldugu, dosya adi, yolu, tipi ve MIME tipi bilinmeden guvenilir bir kanit arsivi kurulamaz.

Python tarafinda `None.strip()` gibi kontrolsuz hatalar `AttributeError` uretir. Bu hata kullaniciya veya gelistiriciye hangi alanin sorunlu oldugunu temiz anlatmaz. Bu yuzden zorunlu alanlarda bilincli `ValueError` tercih edildi.

## Hangi dosyalara dokunduk?

```text
app/models.py
tests/test_models.py
CHANGELOG.md
ROADMAP.md
docs/project_decisions.md
learning/128_file_attachment_validation_bosluklari.md
```

`app/models.py`: `FileAttachmentRecord.__post_init__` validation davranisi guncellendi.

`tests/test_models.py`: Bos `mime_type` ve `None` zorunlu alan senaryolari eklendi.

Dokumantasyon dosyalari: Adim 128 karari, changelog ve roadmap kaydi eklendi.

## Guncellenen validation mantigi

```python
required_fields = (
    "attachment_id",
    "related_record_type",
    "related_record_id",
    "file_name",
    "file_path",
    "file_type",
    "mime_type",
)
for field_name in required_fields:
    value = getattr(self, field_name)
    if value is None or not value.strip():
        raise ValueError(f"{field_name} cannot be empty")
```

Bu kodun amaci:
Dosya eki kaydi icin zorunlu alanlarin bos veya eksik kalmasini engellemek.

Satir satir aciklama:

- `required_fields`: Bos birakilamayacak alan adlarini tek yerde toplar.
- `getattr(self, field_name)`: Alan degerini ismiyle okur.
- `value is None`: Alanin hic verilmemesi veya `None` verilmesi durumunu yakalar.
- `not value.strip()`: Bos string veya sadece bosluklardan olusan metni yakalar.
- `ValueError`: Hatayi kontrollu ve alan adiyla okunabilir hale getirir.

Sunu soyle yaptik ki:
Eksik dosya eki metadata bilgisi uygulama icinde sessizce veya kontrolsuz hatayla ilerlemesin.

Boyle yaptik:
Zorunlu alanlari tek bir validation dongusunde kontrol ettik.

Cunku:
Ayni zorunlu alan mantigini her alan icin ayri yazmak tekrar ve hata riskini artirir.

Boylece:
Hangi alan eksikse o alanin adiyla temiz bir `ValueError` uretilir.

## Testlerle neyi sabitledik?

Yeni testler sunlari sabitledi:

- `mime_type` bos string olamaz.
- `attachment_id` `None` olamaz.
- `related_record_type` `None` olamaz.
- `related_record_id` `None` olamaz.
- `file_name` `None` olamaz.
- `file_path` `None` olamaz.
- `file_type` `None` olamaz.

Bu testler sayesinde ileride biri validation kodunu gevsetirse testler hemen kirmiziya duser.

## Bu adimda ne yapmadik?

- `AuditEventRecord` modeline dokunmadik.
- Audit target record id format validation eklemedik.
- Persistence, repository, API, GUI veya CLI eklemedik.
- Podcast 021 olusturmadik.
- ZIP dosyasini stage etmedik.
- Commit veya push yapmadik.
