# Adim 069 - Dosya Eki Tipi Siniflandirmasi

## Amac

Bu adimda `FileAttachmentRecord.file_type` alaninda kullanilacak temel dosya tipi siniflandirmasi test ve dokumantasyonla netlestirildi.

Bu adimda enum, validation veya hata firlatma davranisi eklenmedi. `file_type` alani serbest metin olarak kalir; ancak proje icinde kullanilacak temel degerler standartlastirilir.

## Temel Dosya Tipleri

Temel siniflar:

- `image`
- `video`
- `pdf`
- `document`
- `audio`
- `other`

## Davranis

`FileAttachmentRecord`, farkli `file_type` degerlerini metadata olarak saklar.

- `image`: Fotograf veya gorsel eklerini temsil eder.
- `video`: Video eklerini temsil eder.
- `pdf`: PDF tutanak, rapor veya belge eklerini temsil eder.
- `document`: Word, Excel veya metin benzeri belge eklerini temsil eder.
- `audio`: Ses notu eklerini temsil eder.
- `other`: Siniflandirilamayan dosya referanslarini temsil eder.

Model dosya icerigini tutmaz. Sadece dosya adi, dosya yolu, dosya tipi, MIME tipi ve iliskili kayit bilgisini tutar.

## Video Icin Not

`file_type="video"` ve `mime_type="video/mp4"` kullanilarak video dosyasi metadata olarak temsil edilebilir.

Bu adimda video oynatma, thumbnail uretme, sikistirma, streaming veya medya isleme eklenmedi.

## Neden Enum Eklenmedi?

Bu adimda amac uygulamayi katilastirmak degil, kullanim standardini netlestirmektir.

Enum veya validation ileride ihtiyac olursa eklenebilir. Simdilik modelin sade kalmasi ve testlerle beklenen kullanim orneklerinin gorunur olmasi tercih edildi.

## Kapsam Disi Birakilanlar

Bu adimda sunlar eklenmedi:

- Enum
- Validation
- Hata firlatma davranisi
- Repository
- Dosya yukleme sistemi
- Dosya var mi kontrolu
- Video oynatma
- Thumbnail veya onizleme uretme
- JSON
- SQLite
- API
- GUI
- CLI
- Buyuk refactor

## Santiye Pratigindeki Karsiligi

Sahada bir kayda fotograf, video, PDF rapor, Word belgesi, Excel tablosu veya ses notu eklenebilir.

Dosya tipi siniflandirmasi, bu eklerin ne oldugunu hizli anlamayi saglar. Boylece kalite kanitlari ve saha arsivi daha okunabilir hale gelir.
