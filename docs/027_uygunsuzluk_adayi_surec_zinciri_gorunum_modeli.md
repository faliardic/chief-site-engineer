# Adim 027 - Uygunsuzluk Adayi Surec Zinciri Gorunum Modeli

## Amac

Bu adimin amaci, uygunsuzluk adayi surecinin parcalarini tek bakista gosterecek baslangic veri modelini olusturmaktir.

Adim 021 kontrol sonucu kaydini, Adim 022 uygunsuzluk adayi kaydini, Adim 023 degerlendirme kaydini, Adim 024 aksiyon kaydini, Adim 025 takip ozeti kaydini, Adim 026 ise ek dosya baglantisini netlestirmisti. Adim 027 bu parcalari tek ozet kayitta temsil eden gorunum modelini ekler.

## Eklenen Model

Bu adimda `NonconformityCandidateProcessViewRecord` modeli eklendi.

Bu model gercek veritabani sorgusu, otomatik join, API cevabi, GUI tablosu veya raporlama sistemi degildir. Sadece surec parcalarinin hangi alanlarla tek ozet kayitta temsil edilecegini netlestirir.

## Model Alanlari

- `candidate_id`: Uygunsuzluk adayi kaydinin kodu.
- `check_result_id`: Iliskili kontrol sonucu kaydinin kodu. Varsayilan deger `None`.
- `review_id`: Iliskili degerlendirme kaydinin kodu. Varsayilan deger `None`.
- `action_id`: Iliskili aksiyon kaydinin kodu. Varsayilan deger `None`.
- `tracking_summary_id`: Iliskili takip ozeti kaydinin kodu. Varsayilan deger `None`.
- `attachment_count`: Iliskili ek dosya sayisi. Varsayilan deger `0`.
- `current_status`: Surecin guncel durumu. Varsayilan deger `open`.
- `last_update_date`: Son guncelleme tarihi. Varsayilan deger `None`.
- `process_summary`: Surecin kisa ozeti. Varsayilan deger `None`.
- `notes`: Ek not alani. Varsayilan deger `None`.

## Santiye Pratigindeki Karsiligi

Santiye sefi bir uygunsuzluk adayina baktiginda sadece aday kaydin kendisini degil, bu adayla ilgili kontrol sonucunu, degerlendirme sonucunu, alinan aksiyonu, takip durumunu ve ekli kanit dosyasi sayisini da gormek ister.

`NonconformityCandidateProcessViewRecord`, bu bilgileri tek ozet satirda temsil eder. Boylece sistem ileride bir liste, rapor veya ekran hazirlayacaksa hangi bilgileri yan yana gosterecegini veri seviyesinde bilir.

## Bu Adimda Ozellikle Eklenmeyenler

Bu adimda veritabani sorgusu eklenmedi.

Bu adimda API eklenmedi.

Bu adimda GUI eklenmedi.

Bu adimda otomatik raporlama eklenmedi.

Bu adimda JSON kayit sistemi eklenmedi.

Bu adimda dosya islemi eklenmedi.

Bu adimda kesin uygunsuzluk veya duzeltici faaliyet sistemi kurulmadi.

## Sonraki Adimlara Hazirlik

Bu model ileride surec listesi, filtreleme, raporlama, durum etiketi veya kullanici arayuzu icin temel olabilir.

Bu adimda bu mekanizmalar kurulmaz. Once surec gorunum kaydinin alanlari netlestirilir.
