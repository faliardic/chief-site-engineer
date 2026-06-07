# Adim 083 - Attachment Model Karari

## Amac

Bu adimda projede ayni amaca yakin gorunen `AttachmentRecord` ve `FileAttachmentRecord` modellerinin rolleri netlestirildi.

Yeni dosya eki hatti icin ana model `FileAttachmentRecord` kabul edildi. `AttachmentRecord` ise onceki genel ek dosya modeli olarak korunacak.

## Neden Iki Attachment Modeli Risk Olusturur?

Iki benzer model ayni amacla kullanilirse proje icinde su sorunlar olusabilir:

- Yeni dosya ekinin hangi modelle tutulacagi belirsizlesir.
- Testler ve dokumantasyon farkli modelleri isaret edebilir.
- Upload servisi, integrity scanner veya ilerideki persistence katmani yanlis modele baglanabilir.
- Ayni kavram iki farkli alan setiyle temsil edildigi icin bakim maliyeti artar.

Bu nedenle modelleri silmeden once rollerini ayirmak gerekir.

## Neden FileAttachmentRecord Ana Model Secildi?

`FileAttachmentRecord`, Adim 067-080 arasinda fotograf, video, PDF, belge, ses ve diger dosya ekleri icin daha acik metadata modeli olarak gelistirildi.

Bu model su konularda daha net bir temel saglar:

- `related_record_type` ve `related_record_id` ile ana kayit baglantisi.
- `file_type` ve `mime_type` ile dosya tipi ayrimi.
- `file_path` ile dosya icerigi yerine referans tutma.
- `original_file_name`, `uploaded_by`, `uploaded_at` ve `notes` ile denetim izi ve saha baglami.

Bu nedenle yeni dosya eki gelistirmeleri `FileAttachmentRecord` uzerinden ilerlemelidir.

## Neden AttachmentRecord Hemen Silinmedi?

`AttachmentRecord`, projenin erken adimlarinda genel dosya eki referansi olarak eklendi. Adim 008 ve Adim 026 dokumantasyonu ile mevcut testler bu modeli hala kullanir.

Modeli hemen silmek:

- Eski testleri kirabilir.
- Eski karar ve learning dosyalarindaki anlatimi koparabilir.
- Gereksiz bir kirici refactor olusturabilir.

Bu nedenle `AttachmentRecord` simdilik legacy model olarak korunur. Ileride ayri bir migration veya refactor adiminda temizlenebilir.

## Upload Servisi ve Integrity Scanner Icin Anlami

Bu karar, ileride eklenecek dosya yukleme ve dosya varlik kontrolu davranislarinin hangi modele baglanacagini netlestirir.

- Upload servisi yeni kayit olusturacaksa `FileAttachmentRecord` kullanmalidir.
- Integrity scanner dosya yolu ve metadata kontrol edecekse `FileAttachmentRecord` alanlarini temel almalidir.
- `AttachmentRecord` yeni medya hatti icin genisletilmemeli, eski uyumluluk katmani olarak kalmalidir.

## Bu Adimda Yapilmayanlar

- Model alani eklenmedi.
- Model silinmedi.
- Test dosyasi degistirilmedi.
- Repository eklenmedi.
- Upload servisi eklenmedi.
- Database, API, GUI, auth, CI veya deployment eklenmedi.
- Kirici refactor yapilmadi.
