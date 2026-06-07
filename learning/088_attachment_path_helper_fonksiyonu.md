# Adim 088 - Attachment Path Helper Fonksiyonu

## Amac

Bu adimda canonical attachment path standardini koda baglayan `build_attachment_path` helper fonksiyonu eklendi.

Standart:

```text
attachments/{project_id}/{record_type}/{yyyy}/{mm}/{dd}/{record_id}/{safe_file_name}
```

## Path Helper Neden Gerekir?

Path helper, dosya yolu metnini her yerde elle yazmak yerine tek bir fonksiyonla uretmeyi saglar.

Bu sayede dokumantasyonda kilitlenen standart kod tarafinda da ayni bicimde kullanilir.

## Elle Path Yazmak Neden Risklidir?

Elle path yazildiginda su hatalar olusabilir:

- Tarih klasorleri eksik yazilabilir.
- `record_type` farkli bicimde yazilabilir.
- Dosya adi icinde klasor ayirici kalabilir.
- Ayni proje icinde farkli klasor duzenleri ortaya cikabilir.

Bu hatalar upload service, integrity scanner ve backup davranislarini zorlastirir.

## safe_file_name Normalizasyonu Neden Gerekir?

Kullanici dosya adinda bosluk, slash veya backslash gibi karakterler bulunabilir.

Helper bu adimda:

- Bas ve sondaki bosluklari temizler.
- `/` ve `\` karakterlerini `_` haline getirir.
- Bos dosya adini reddeder.

Boylece dosya adi path icinde ek klasor olusturmaz.

## Helper Neden Dosya Olusturmaz?

Bu helper sadece path string uretir.

Bu adimda fiziksel dosya kopyalama, tasima, silme veya upload davranisi eklenmez. Bu ayrim helper fonksiyonun sade ve test edilebilir kalmasini saglar.

## Upload Service ve Integrity Scanner Icin Zemin

Ileride upload service bu helper ile dosyanin nereye yazilacagini belirleyebilir.

Integrity scanner ise `FileAttachmentRecord.file_path` degerinin canonical standartla uyumlu olup olmadigini kontrol edebilir.

## Bu Adimda Yapilmayanlar

- Upload service eklenmedi.
- Fiziksel dosya islemi eklenmedi.
- Database, API, GUI, auth, CI veya deployment eklenmedi.
- `FileAttachmentRecord` icine yeni alan eklenmedi.
