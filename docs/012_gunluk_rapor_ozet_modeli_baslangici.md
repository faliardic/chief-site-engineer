# 012 Gunluk Rapor Ozet Modeli Baslangici

Bu adimin amaci, gunluk santiye raporu takibine sade bir veri modeliyle baslangic yapmaktir.

Bu adim gercek rapor uretim sistemi degildir. PDF/Excel cikti, fotograf eki, otomatik rapor olusturma veya rapor arsivleme akisi kurulmaz.

Veritabani, JSON kayit sistemi, API, GUI ve hava durumu entegrasyonu eklenmemistir.

`DailyReportRecord`, gunluk rapor ozet bilgisini temsil eder. Rapor tarihi, hava durumu, yapilan isler, iscilik, ekipman, malzeme, sorunlar, is guvenligi, hazirlayan kisi, durum ve not bilgisini tutar.

Bu adimda diger modellerle kod seviyesinde iliski kurulmaz.

Ileride `AttachmentRecord`, `MaterialRecord`, `NonconformityRecord`, `MeetingActionRecord`, `RFIRecord` ve `SubmittalRecord` ile baglanti kurulabilir.
