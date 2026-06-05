# 008 Dosya/Ek Arsivleme Baslangici

## Dosya/Ek Arsivleme Nedir?

Dosya/ek arsivleme, santiye kayitlariyla ilgili belge, fotograf veya diger eklerin sistem icinde takip edilebilmesi icin referans bilgilerinin tutulmasidir.

## Santiye Sefi Hangi Tur Dosyalari Takip Etmek Ister?

Santiye sefi fotograflar, ruhsatlar, tutanaklar, beton dokum belgeleri, numune raporlari, yapi denetim formlari, uygunsuzluk ekleri ve gunluk saha kaydi eklerini takip etmek isteyebilir.

## AttachmentRecord Modeli Hangi Bilgileri Temsil Eder?

`AttachmentRecord`, ek kimligi, proje kimligi, baslik, dosya adi, dosya turu, dosya yolu, iliskili model, iliskili kayit kimligi, yukleyen kisi, yukleme tarihi, notlar ve durum bilgisini temsil eder.

## file_name ve file_path Farki Nedir?

`file_name`, dosyanin adidir. `file_path`, dosyanin bilgisayarda veya ileride bir depolama alaninda bulundugu yolu ifade eder. Bu asamada `file_path` sadece metinsel referans olarak tutulur.

## related_model ve related_id Alanlari Neden Var?

`related_model`, ekin hangi kayit turuyle ilgili oldugunu belirtir. `related_id`, o kaydin kimligini tutar. Ornegin `related_model = "ConcretePour"` ve `related_id = "POUR-001"` ekin bir beton dokum kaydiyla ilgili oldugunu anlatir.

## Bu Model Beton Dokum, Yapi Denetim, Uygunsuzluk veya Gunluk Saha Kaydiyla Nasil Iliskilendirilebilir?

Bir ek, `ConcretePour`, `InspectionRequest`, `NonconformityRecord` veya `DailySiteLog` gibi farkli kayitlarla iliskilendirilebilir. Bu nedenle iliski alanlari serbest metin ve opsiyonel tutuldu.

## Bu Asamada Neden Gercek Dosya Kopyalama, Yukleme, Silme, Veritabani veya JSON Eklenmedi?

Bu adimda amac dosyanin kendisini yonetmek degil, dosya referansinin hangi bilgilerden olusacagini netlestirmektir. Gercek dosya islemleri, veritabani ve JSON kayit sistemi daha sonra ele alinabilir.

## Bu Model Ileride Hangi Modullere Temel Olacak?

`AttachmentRecord` ileride dosya arsivi, fotograf ekleri, belge takibi, kayitlara ek baglama, raporlama ve dis depolama entegrasyonu modullerine temel olacaktir.
