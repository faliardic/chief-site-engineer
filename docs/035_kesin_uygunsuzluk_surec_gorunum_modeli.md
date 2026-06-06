# Adim 035 - Kesin Uygunsuzluk Surec Gorunum Modeli

## Amac

Bu adimin amaci, kesin uygunsuzluk / NCR surecini tek bakista gosterecek baslangic gorunum modelini olusturmaktir.

`NonconformityProcessViewRecord`, bir kesin uygunsuzluk kaydinin temel bilgilerini, adaydan donusum baglantisini, mevcut durumunu ve takip ozetini tek kayitta temsil eder.

## Eklenen Model

Bu adimda `NonconformityProcessViewRecord` modeli eklendi.

Bu model veritabani sorgusu, otomatik join, API cevabi, GUI tablosu veya raporlama sistemi degildir. Sadece kesin uygunsuzluk surecinin tek ozet kayitta hangi alanlarla okunabilecegini netlestirir.

## Model Alanlari

- `nonconformity_id`: Kesin uygunsuzluk / NCR kaydinin kodu.
- `source_candidate_id`: Kaynak uygunsuzluk adayi kodu. Varsayilan deger `None`.
- `conversion_record_id`: Adaydan NCR'a donusum kaydi kodu. Varsayilan deger `None`.
- `title`: Kesin uygunsuzluk basligi. Varsayilan deger `None`.
- `nonconformity_type`: Kesin uygunsuzluk turu. Varsayilan deger `None`.
- `severity`: Onem seviyesi. Varsayilan deger `medium`.
- `responsible_party`: Sorumlu taraf. Varsayilan deger `None`.
- `current_status`: Guncel surec durumu. Varsayilan deger `open`.
- `final_status`: Nihai durum. Varsayilan deger `None`.
- `last_update_date`: Son guncelleme tarihi. Varsayilan deger `None`.
- `process_summary`: Surec ozet metni. Varsayilan deger `None`.
- `notes`: Ek not alani. Varsayilan deger `None`.

## Donusum Baglantisi Notu

`source_candidate_id` ve `conversion_record_id` alanlari bu modelde dogrudan islem kaydi olarak kullanilmaz. Bunlar sadece gorunum ve ozet amaciyla bulunur.

Asil adaydan kesin uygunsuzluga donusum iliskisi `NonconformityCandidateConversionRecord` modeliyle temsil edilmeye devam eder.

## Santiye Pratigindeki Karsiligi

Santiye sefi kesin uygunsuzluk kaydina baktiginda sadece NCR numarasini degil, bu kaydin bir adaydan gelip gelmedigini, hangi donusum kaydiyla baglandigini, onem seviyesini, sorumlusunu, guncel durumunu ve kisa takip ozetini tek satirda gormek isteyebilir.

`NonconformityProcessViewRecord`, bu ihtiyac icin baslangic gorunum modelidir. Bir liste, rapor veya arayuz ileride hazirlanacaksa hangi bilgilerin yan yana okunacagini veri seviyesinde tarif eder.

## Bu Adimda Ozellikle Eklenmeyenler

Bu adimda veritabani sorgusu eklenmedi.

Bu adimda API eklenmedi.

Bu adimda GUI eklenmedi.

Bu adimda otomatik NCR olusturma eklenmedi.

Bu adimda otomatik donusum eklenmedi.

Bu adimda duzeltici faaliyet sistemi eklenmedi.

Bu adimda onay akisi eklenmedi.

Bu adimda JSON kayit sistemi eklenmedi.

Bu adimda dosya islemi eklenmedi.

## Sonraki Adimlara Hazirlik

Bu model ileride NCR listesi, raporlama, filtreleme, surec panosu veya kullanici arayuzu icin temel olabilir.

Bu adimda bu mekanizmalar kurulmaz. Once kesin uygunsuzluk surec gorunum kaydinin veri sekli netlestirilir.
