# Adim 032 - Uygunsuzluk Adayindan Kesin Uygunsuzluga Donusum Modeli

## Amac

Bu adimin amaci, mevcut `NonconformityRecord` modelini yeniden olusturmadan, bir uygunsuzluk adayinin kesin uygunsuzluk / NCR kaydina donusum baglantisini temsil edecek baslangic veri modelini olusturmaktir.

On kontrolde `NonconformityRecord` modelinin Adim 007'de zaten eklendigi goruldu. Bu nedenle Adim 032'de yeni `NonconformityRecord` olusturulmadi.

## Eklenen Model

Bu adimda `NonconformityCandidateConversionRecord` modeli eklendi.

Bu model otomatik NCR olusturma, otomatik donusum, duzeltici faaliyet sistemi, onay akisi, veritabani sorgusu, API cevabi veya GUI ekrani degildir. Sadece aday kayit ile mevcut kesin uygunsuzluk kaydi arasindaki donusum iliskisinin hangi alanlarla tutulacagini netlestirir.

## Model Alanlari

- `candidate_id`: Donusume konu olan uygunsuzluk adayinin kodu.
- `nonconformity_id`: Baglanan kesin uygunsuzluk / NCR kaydinin kodu.
- `conversion_decision`: Donusum karari.
- `conversion_reason`: Donusum kararinin gerekcesi.
- `converted_by`: Donusum kararini veren veya kaydi olusturan kisi.
- `conversion_date`: Donusum tarihi.
- `source_closure_id`: Donusum kararinin kaynaklandigi kapanis kaydi. Varsayilan deger `None`.
- `status`: Donusum kaydinin durumu. Varsayilan deger `converted`.
- `notes`: Ek not alani. Varsayilan deger `None`.

## Onemli Kavram Ayrimi

`NonconformityCandidateRecord`, suphe, aday veya incelenecek saha bulgusudur.

`NonconformityRecord`, kesin uygunsuzluk veya NCR kaydidir.

`NonconformityCandidateConversionRecord`, aday kaydin kesin uygunsuzluk kaydina donusum baglantisidir.

Bu ayrim sayesinde aday bilgi ile kesin uygunsuzluk kaydi birbirine karistirilmaz.

## Santiye Pratigindeki Karsiligi

Sahada gorulen bir sorun once aday olarak kaydedilebilir. Daha sonra degerlendirme, aksiyon, takip ve kapanis adimlarindan sonra bu aday icin "artik kesin uygunsuzluk kaydi acilmali" karari verilebilir.

`NonconformityCandidateConversionRecord`, bu karar izini tutar. Ornegin `NCR-CAND-001` aday kaydi, `NCR-001` kesin uygunsuzluk kaydina donusturulduysa; bu donusumun kararini, gerekcesini, tarihini ve yapan kisiyi kayda alir.

## Bu Adimda Ozellikle Eklenmeyenler

Bu adimda yeni `NonconformityRecord` modeli eklenmedi.

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

Bu model ileride aday surecinden resmi NCR kaydina gecis raporu, denetim izi, onay akisi veya duzeltici faaliyet baslatma kararlarini destekleyebilir.

Bu adimda bu mekanizmalar kurulmaz. Once donusum baglantisinin veri sekli netlestirilir.
