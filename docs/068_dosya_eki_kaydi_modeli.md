# Adim 068 - Dosya Eki Kaydi Modeli

## Amac

Bu adimda fotograf, video, PDF, belge, ses notu ve benzeri dosya eklerini temsil edecek `FileAttachmentRecord` veri modeli eklendi.

Bu model dosyanin kendisini tasimaz. Dosya yolu, dosya adi, dosya tipi, MIME tipi ve iliskili kayit bilgisi gibi metadata alanlarini tutar.

## Eklenen Model

```text
FileAttachmentRecord
```

Model `app/models.py` icine eklendi. Bu proje stilinde veri modelleri dataclass olarak `app/models.py` dosyasinda tutulur.

## Alanlar

Zorunlu alanlar:

- `attachment_id`
- `related_record_type`
- `related_record_id`
- `file_name`
- `file_path`
- `file_type`
- `mime_type`
- `uploaded_by`
- `uploaded_at`

Opsiyonel alanlar:

- `description`
- `notes`
- `file_size`

Opsiyonel alanlar verilmezse `None` olur.

## Dosya Tipi Ornekleri

`file_type` alaninda su degerler kullanilabilir:

- `image`
- `video`
- `pdf`
- `document`
- `audio`
- `other`

## Video Eki Mantigi

Video eki icin model sadece metadata ve referans tutar.

Ornek:

- `file_name`: `beton-dokum-oncesi.mp4`
- `file_path`: `attachments/ncr/NCR-002/beton-dokum-oncesi.mp4`
- `file_type`: `video`
- `mime_type`: `video/mp4`

Video dosyasinin icerigi modele gomulmez. Video oynatma, sikistirma, thumbnail uretme veya streaming bu adimda eklenmedi.

## Iliskili Kayit Mantigi

`related_record_type` ve `related_record_id` alanlari, dosya ekinin hangi kayda bagli oldugunu temsil eder.

Ornek:

- `related_record_type`: `nonconformity`
- `related_record_id`: `NCR-003`

Bu sayede ayni model ileride NCR, saha notu, gunluk kayit, beton dokum kaydi veya baska kayit turleriyle kullanilabilir.

## Kapsam Disi Birakilanlar

Bu adimda sunlar eklenmedi:

- Repository
- Dosya yukleme sistemi
- Dosyayi fiziksel klasore kopyalama
- Dosya var mi kontrolu
- Video oynatma
- Thumbnail veya onizleme uretme
- JSON
- SQLite
- API
- GUI
- CLI
- Buyuk refactor

Bu adim sadece veri modeli baslangicidir.

## Santiye Pratigindeki Karsiligi

Sahada bir uygunsuzluk fotografla, videoyla, PDF raporuyla veya belgeyle desteklenebilir.

`FileAttachmentRecord`, bu dosyanin nerede oldugunu, hangi kayda bagli oldugunu ve ne tur dosya oldugunu kayit altina alir. Boylece kalite kanitlari dosyanin kendisi sisteme gomulmeden izlenebilir hale gelir.
