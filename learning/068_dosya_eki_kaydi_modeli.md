# Adim 068 - Dosya Eki Kaydi Modeli

## Bu Adimda Ne Ogrenildi?

Bu adimda yeni bir dataclass modeli eklendi: `FileAttachmentRecord`.

Bu model, dosya ekinin kendisini degil, dosya hakkindaki metadata ve referans bilgisini temsil eder.

## Neden Ayrica FileAttachmentRecord?

Projede daha once `AttachmentRecord` modeli vardi. Bu model genel dosya eki referansi icin baslangic sagladi.

`FileAttachmentRecord` ise fotograf, video, PDF, belge ve ses notu gibi dosyalari daha acik alan adlariyla temsil etmek icin baslangic modelidir.

## Dataclass Mantigi

Model `@dataclass` ile tanimlandi. Bu, Python'in alanlari otomatik olarak constructor icine almasini saglar.

Basit kullanim:

```python
FileAttachmentRecord(
    attachment_id="file-att-001",
    related_record_type="nonconformity",
    related_record_id="NCR-001",
    file_name="korkuluk_eksigi.jpg",
    file_path="attachments/PRJ-001/nonconformity/2026/10/02/NCR-001/korkuluk_eksigi.jpg",
    file_type="image",
    mime_type="image/jpeg",
    uploaded_by="Santiye sefi",
    uploaded_at="2026-10-02T09:30:00",
)
```

## Zorunlu ve Opsiyonel Alanlar

Zorunlu alanlar dosya ekini tanimlamak ve hangi kayda bagli oldugunu bilmek icin gereklidir.

Opsiyonel alanlar:

- `description`
- `notes`
- `file_size`

Bu alanlar verilmezse `None` olur.

## Video Nasil Temsil Edilir?

Video dosyasi icin `file_type="video"` ve `mime_type="video/mp4"` gibi degerler kullanilir.

Model video icerigini saklamaz. Sadece dosya adi, dosya yolu ve metadata bilgilerini tutar.

Bu ayrim onemlidir, cunku video dosyalari buyuk olabilir. Dosyanin kendisini modele gommek yerine referans bilgisini tutmak daha guvenli ve sade bir baslangictir.

## Iliskili Kayit Bilgisi

`related_record_type` dosyanin hangi kayit turune bagli oldugunu anlatir.

`related_record_id` ise dosyanin hangi kayit kimligine baglandigini belirtir.

Ornegin:

```text
related_record_type = "nonconformity"
related_record_id = "NCR-003"
```

Bu ifade dosya ekinin bir NCR kaydina bagli oldugunu anlatir.

## Bu Adimda Ne Eklenmedi?

Bu adimda repository, dosya yukleme, klasore kopyalama, video oynatma, thumbnail uretme, JSON, SQLite, API, GUI veya CLI eklenmedi.

Sadece veri modeli ve model testleri eklendi.

## Python Ogrenme Acisindan Ders

Bu adim su konulari pekistirir:

- Dataclass ile veri modeli olusturma
- Zorunlu ve opsiyonel alan ayrimi
- Metadata kavrami
- Dosya icerigi ile dosya referansi ayrimi
- Model testleriyle varsayilan degerleri dogrulama

## Santiye Pratigindeki Anlami

Bir saha kaydina fotograf, video veya PDF baglamak icin once dosya hakkindaki temel bilgilerin duzenli tutulmasi gerekir.

`FileAttachmentRecord`, bu duzeni kurar. Dosyanin hangi kayda ait oldugu, nerede durdugu ve hangi turde oldugu izlenebilir hale gelir.
