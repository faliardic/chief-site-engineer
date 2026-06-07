# Adim 085 - Attachment Path Standard

## Amac

Bu adimda dosya eki hatti icin tek canonical path standardi belirlendi.

Standart:

```text
attachments/{project_id}/{record_type}/{yyyy}/{mm}/{dd}/{record_id}/{safe_file_name}
```

## Neden Dosya Yolu Standardi Gerekir?

Dosya ekleri arttikca ayni tur dosyalar farkli klasor mantiklariyla saklanirsa sistemin okunabilirligi azalir.

Standart yol, bir dosyanin hangi projeye, hangi kayit turune, hangi tarihe ve hangi ana kayda ait oldugunu klasor yolundan anlamayi saglar.

## Eski Farkli Path Ornekleri Neden Risklidir?

Farkli dokumanlarda farkli path ornekleri bulunursa ileride su sorunlar olusabilir:

- Upload servisi hangi klasor yapisini kullanacagini bilemez.
- Integrity scanner hangi yolu dogru kabul edecegini karistirir.
- Backup kurallari dosyalari eksik kapsayabilir.
- Ayni kayda ait dosyalar farkli klasorlerde dagilabilir.
- `file_path` metadata alani ile fiziksel dosya yeri uyumsuz hale gelebilir.

## Canonical Path Semasi

```text
attachments/{project_id}/{record_type}/{yyyy}/{mm}/{dd}/{record_id}/{safe_file_name}
```

Ornekler:

```text
attachments/PRJ-001/nonconformity/2026/06/07/NCR-00012/photo_001.jpg
attachments/PRJ-001/concrete/2026/06/07/CP-000123/slump_test.pdf
attachments/PRJ-001/site_note/2026/06/07/SN-00045/site_photo.jpg
```

## Alanlarin Anlami

`project_id`: Dosyanin ait oldugu proje kimligi.

`record_type`: Dosyanin bagli oldugu ana kayit turu. Kucuk harfli ve makine-dostu olmalidir.

`yyyy`: Dort haneli yil klasoru.

`mm`: Iki haneli ay klasoru.

`dd`: Iki haneli gun klasoru.

`record_id`: Dosyanin bagli oldugu ana kayit kimligi.

`safe_file_name`: Dosya sistemi icin guvenli hale getirilmis dosya adi.

## Upload Service, Integrity Scanner ve Backup Icin Faydasi

Bu standart ileride uc temel hatti kolaylastirir:

- Upload service dosyayi nereye koyacagini bilir.
- Integrity scanner `FileAttachmentRecord.file_path` ile fiziksel dosya yerini tutarli kontrol edebilir.
- Backup hatti tum attachment kokunu ve tarih/kayit yapisini duzenli yedekleyebilir.

## Bu Adimda Yapilmayanlar

- Path helper fonksiyonu yazilmadi.
- Upload servisi eklenmedi.
- Fiziksel dosya kopyalama, tasima veya silme eklenmedi.
- Database, API, GUI, auth, CI veya deployment eklenmedi.
- Test dosyalari degistirilmedi.
