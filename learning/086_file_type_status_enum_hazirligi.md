# Adim 086 - File Type / Attachment Status Enum Hazirligi

## Amac

Bu adimda `FileAttachmentRecord` hatti icin `file_type` ve ilerideki attachment status degerlerinde kullanilacak hafif enum hazirligi yapildi.

Eklenen enumlar:

- `FileType`
- `AttachmentStatus`

## Serbest Metin file_type / status Neden Risklidir?

Serbest metin kullanildiginda ayni kavram farkli sekillerde yazilabilir.

Ornek:

- `image`
- `Image`
- `photo`
- `jpg`

Bu farkliliklar filtreleme, raporlama, upload servisi ve integrity scanner davranislarini zorlastirir.

Status tarafinda da benzer risk vardir. Bir dosya eki aktif mi, arsivlenmis mi, kayip mi, silinmis mi sorularina tutarli cevap vermek icin ortak sozluk gerekir.

## Enum Neden Gerekir?

Enum, sinirli degerleri isimlendirerek tutar.

`FileType.IMAGE.value` degeri `"image"` olur.

Bu sayede kod icinde stringleri elle tekrar tekrar yazmak yerine ortak ve okunabilir bir kaynak kullanilabilir.

## Neden Bu Adimda Agir Validation Yapilmadi?

Bu adim sadece enum hazirligidir.

`FileAttachmentRecord.file_type` alani string olarak kalmaya devam eder. Gecersiz deger verildiginde hata firlatan bir validation davranisi bu adimda eklenmedi.

Bunun nedeni:

- Mevcut testleri kirmamak.
- Modeli aniden daha kati hale getirmemek.
- Upload servisi ve validation stratejisini ayri bir adimda tasarlamak.

## Adim 087 Validation Testlerine Nasil Zemin Hazirlar?

Enumlar eklendigi icin sonraki adimda validation testleri su sorulari netlestirebilir:

- Hangi file_type degerleri kabul edilmeli?
- Gecersiz file_type icin hata mi donmeli?
- Attachment status hangi durumlarda degismeli?
- Validation model seviyesinde mi servis seviyesinde mi olmali?

Bu adim, bu sorular icin ortak deger listesini hazirlar.

## Upload Service ve Integrity Scanner Icin Faydasi

Upload service, dosya yuklenirken `FileType` degerlerini kullanarak dosya turunu standartlastirabilir.

Integrity scanner, dosya ekinin durumu icin `AttachmentStatus` degerlerini kullanabilir:

- `active`
- `archived`
- `missing`
- `deleted`

Boylece raporlama ve kontrol davranislari ayni kelimeleri kullanir.

## Bu Adimda Yapilmayanlar

- Agir validation eklenmedi.
- `FileAttachmentRecord.file_type` alan tipi degistirilmedi.
- `FileAttachmentRecord` icine `status` alani eklenmedi.
- Upload servisi eklenmedi.
- Path helper yazilmadi.
- Database, API, GUI, auth, CI veya deployment eklenmedi.
