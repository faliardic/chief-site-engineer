# Adim 094 - Attachment Integrity Report Modeli

## Report Modeli Nedir?

Report modeli, tekil sonuc listesini ve bu listenin ust ozetini birlikte tasiyan veri modelidir.

`AttachmentIntegrityReport`, attachment integrity hattinda `results` ve `summary` bilgilerini ayni kayitta toplar.

## Result, Summary ve Report Arasindaki Fark

`AttachmentIntegrityResult`, tek bir attachment icin kontrol sonucudur.

`AttachmentIntegrityReportSummary`, birden fazla result kaydinin sayisal ozetidir.

`AttachmentIntegrityReport`, hem tekil result listesini hem de summary bilgisini birlikte tasiyan ust rapor modelidir.

## Neden Scanner Yazmadan Once Report Modeli Olusturulur?

Scanner yazilmadan once scanner'in nihai rapor ciktisinin nasil gorunecegi netlesmelidir.

Bu model sayesinde ileride scanner sadece result uretmekle kalmaz, bu result listesini summary ile birlikte tutarli bir rapor olarak sunabilir.

Bu yaklasim dashboard, backup dogrulama ve audit hatti icin daha duzenli bir temel saglar.

## results Listesinin Tuple Olarak Saklanmasi

Report icindeki `results` bilgisi disaridan liste olarak verilse bile model icinde tuple olarak saklanir.

Tuple kullanimi, rapor olustuktan sonra result listesinin yanlislikla degistirilmesini zorlastirir.

Bu durum raporun daha tahmin edilebilir ve guvenilir kalmasina yardim eder.

## source ve notes Alanlari

`source`, raporun hangi kaynaktan geldigini anlatabilir. Ornegin ileride `manual_check`, `scheduled_scanner` veya `backup_restore_check` gibi degerler kullanilabilir.

`notes`, rapora insan tarafindan okunabilir ek aciklama eklemek icin kullanilir.

Bu iki alan ileride scanner, backup ve audit event hattinda rapor baglamini korumaya yardim eder.

## Bu Adim Neden Dosya Sistemi Taramasi Degildir?

Bu adim klasor gezmez.

`os.walk`, `glob` veya fiziksel dosya kontrolu yapmaz.

Upload service, backup logic veya audit event implementasyonu eklemez.

Bu adim yalnizca eldeki result listesini ve summary bilgisini birlikte tasiyan rapor modelini hazirlar.
