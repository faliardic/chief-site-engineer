# Adim 069 - Dosya Eki Tipi Siniflandirmasi

## Bu Adimda Ne Ogrenildi?

Bu adimda `FileAttachmentRecord.file_type` alaninda hangi temel dosya tipi degerlerinin kullanilacagi netlestirildi.

Model degismedi. Sadece farkli dosya tiplerinin modelde metadata olarak saklanabildigi testlerle gosterildi.

## Temel Siniflar

Bu adimda su temel degerler standart kabul edildi:

- `image`
- `video`
- `pdf`
- `document`
- `audio`
- `other`

## Metadata Olarak Saklama

`file_type`, dosya icerigini saklamaz. Sadece dosyanin hangi sinifa girdigini anlatan metinsel metadata alanidir.

Ornek:

```python
FileAttachmentRecord(
    attachment_id="file-att-video-002",
    related_record_type="daily_log",
    related_record_id="LOG-001",
    file_name="ilerleme_videosu.mp4",
    file_path="attachments/PRJ-001/daily_log/2026/10/03/LOG-001/ilerleme_videosu.mp4",
    file_type="video",
    mime_type="video/mp4",
    uploaded_by="Santiye sefi",
    uploaded_at="2026-10-03T09:30:00",
)
```

Bu kayit video dosyasinin icerigini tutmaz. Sadece video dosyasina ait referans bilgisini tutar.

## MIME Tipi Ile Farkı

`file_type` proje icindeki sade siniftir: `image`, `video`, `pdf` gibi.

`mime_type` daha teknik dosya tipidir: `image/jpeg`, `video/mp4`, `application/pdf` gibi.

Ikisi birlikte kullanildiginda hem kullaniciya okunabilir bir sinif hem de teknik dosya turu saklanmis olur.

## Neden Validation Yok?

Bu adimda enum veya validation eklenmedi.

Cunku amac once kullanim standardini test ve dokumantasyonla sabitlemektir. Ileride sistem buyudukce bu degerler enum veya dogrulama kurallariyla sinirlandirilabilir.

## Python Ogrenme Acisindan Ders

Bu adim su konulari pekistirir:

- Model davranisini degistirmeden kullanim standardi olusturma
- Metadata alanlarini test etme
- Dosya uzantisi ve MIME tipi ayrimi
- Enum eklemeden once testlerle kavrami netlestirme

## Santiye Pratigindeki Anlami

Saha ekleri farkli turlerde olabilir. Fotograf kalite kaniti olabilir, video ilerleme takibi olabilir, PDF tutanak olabilir, belge teslim formu olabilir, ses dosyasi hizli saha notu olabilir.

Dosya tipi siniflandirmasi, bu eklerin daha sonra filtrelenebilmesi, raporlanabilmesi ve denetlenebilmesi icin temel hazirlar.
