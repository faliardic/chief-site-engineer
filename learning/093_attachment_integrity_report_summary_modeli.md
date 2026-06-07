# Adim 093 - Attachment Integrity Report Summary Modeli

## Report Summary Modeli Nedir?

Report summary modeli, cok sayida tekil kontrol sonucunun ust ozetini tasiyan veri modelidir.

`AttachmentIntegrityReportSummary`, ileride scanner raporu uretildiginde toplam kac attachment kontrol edildigini, kacinin OK oldugunu, kac hata ve uyari bulundugunu ve her status turunden kac adet oldugunu gostermek icin hazirlandi.

## Tekil Result ile Summary Arasindaki Fark

`AttachmentIntegrityResult`, tek bir attachment icin sonucu anlatir.

`AttachmentIntegrityReportSummary`, birden fazla `AttachmentIntegrityResult` kaydinin toplu ozetidir.

Tekil result sahadaki bir kanit dosyasinin durumunu anlatirken summary, tum kontrol turunun genel saglik durumunu gosterir.

## Neden Scanner Yazmadan Once Rapor Ozeti Modellenir?

Scanner yazilmadan once scanner'in rapor ciktisinin nasil ozetlenecegi bilinmelidir.

Bu model, ileride scanner gelistirildiginde rapor formatinin degismeden kalmasina yardim eder.

Boylece scanner, dashboard, audit event ve backup dogrulama hattinin ortak bir ozet yapisi olur.

## Status Bazli Sayaclar ile Severity Bazli Sayaclar

Status bazli sayaclar belirli durum kodlarini sayar:

- `missing_file_count`
- `orphan_file_count`
- `invalid_path_count`
- `duplicate_metadata_count`
- `unreadable_file_count`

Severity bazli sayaclar sonucun onem seviyesini sayar:

- `ok_count`
- `error_count`
- `warning_count`

Bu ayrim raporda hem teknik nedeni hem de yonetsel onemi gormeyi saglar.

## Bu Adim Neden Dosya Sistemi Taramasi Degildir?

Bu adim klasor gezmez.

`os.walk`, `glob` veya fiziksel dosya kontrolu yapmaz.

Upload service, backup logic veya audit event implementasyonu eklemez.

Bu adim yalnizca eldeki `AttachmentIntegrityResult` listesinden ozet uretecek modeli ve helper fonksiyonu hazirlar.
