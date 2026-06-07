# Adim 087 - FileAttachmentRecord Validation Testleri

## Amac

Bu adimda `FileAttachmentRecord` icin temel validation davranislari eklendi.

Hedef, dosya eki metadata kaydinin daha en basta bozuk veya eksik bilgilerle olusmasini engellemektir.

## Validation Neden Gerekir?

Validation, kayit olusurken temel kurallarin kontrol edilmesidir.

Dosya eki metadata kaydi eksik kimlik, bos dosya yolu veya gecersiz dosya tipiyle olusursa ileride upload service, integrity scanner, rapor veya backup hatti yanlis calisabilir.

## Bos ID ve Iliski Alanlari Neden Risklidir?

`attachment_id` bos olursa dosya eki kaydi kimliksiz kalir.

`related_record_type` veya `related_record_id` bos olursa dosyanin hangi ana kayda ait oldugu bilinmez.

Bu durumda saha kaniti dosya olarak dursa bile hangi NCR, beton dokumu veya gunluk kayitla iliskili oldugu kaybolur.

## Gecersiz file_type Neden Risklidir?

`file_type` serbest metin olarak yanlis yazilirsa dosya tipi filtreleme ve raporlama bozulur.

Ornegin `image` yerine `photo` yazilmasi, ileride sadece gorsel ekleri listeleyen bir davranisin bu kaydi kacirmasina neden olabilir.

Bu nedenle `file_type`, `FileType` enumundaki canonical degerlerden biri olmalidir.

## Negatif file_size Neden Risklidir?

Dosya boyutu negatif olamaz.

Negatif `file_size`, metadata kaydinin bozuk oldugunu gosterir. Bu deger raporlama, limit kontrolu veya backup hesaplarinda hataya neden olabilir.

## Neden uploaded_by / uploaded_at Hala Opsiyonel?

Projede henuz kullanici sistemi, auth ve gercek upload service yoktur.

Bu nedenle `uploaded_by` ve `uploaded_at` alanlari model seviyesinde opsiyonel kalir.

Ileride upload service geldiginde bu alanlar servis seviyesinde zorunlu tutulabilir veya otomatik doldurulabilir.

## Path Helper, Upload Service ve Integrity Scanner Icin Zemin

Bu validation adimi, sonraki teknik adimlara zemin hazirlar:

- Path helper bos dosya yolu olmayan kayitlarla calisir.
- Upload service gecersiz metadata kaydi olusturmaz.
- Integrity scanner dosya tipi, dosya yolu ve boyut bilgisini daha guvenilir kontrol eder.

## Bu Adimda Yapilmayanlar

- Path helper yazilmadi.
- Upload service eklenmedi.
- Fiziksel dosya islemi eklenmedi.
- Database, API, GUI, auth, CI veya deployment eklenmedi.
- `FileAttachmentRecord` icine `status` alani eklenmedi.
