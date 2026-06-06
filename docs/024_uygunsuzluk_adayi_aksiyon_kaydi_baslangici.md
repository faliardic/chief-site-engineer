# Adim 024 - Basit Uygunsuzluk Adayi Aksiyon Kayit Modeli Baslangici

## Amac

Bu adimin amaci, degerlendirilmis bir uygunsuzluk adayi icin alinan basit aksiyon kararini sade bir veri modeliyle temsil etmektir.

Adim 023'te uygunsuzluk adayinin degerlendirme bilgisi kayda alinmisti. Adim 024'te ise bu degerlendirmeden sonra ne yapilacagina dair ilk karar bilgisi veri seviyesinde tutulur.

## Eklenen Model

Bu adimda `NonconformityCandidateActionRecord` modeli eklendi.

Model, degerlendirilen uygunsuzluk adaylari icin basit aksiyon kararini veri seviyesinde tutar. Bu model kesin uygunsuzluk kaydi, duzeltici faaliyet sistemi, gorev atama sistemi veya takip akisi degildir.

## Model Alanlari

- `candidate_title`: Aksiyonun bagli oldugu uygunsuzluk adayi basligi.
- `review_result`: Onceki degerlendirme sonucu.
- `action_decision`: Alinan karar veya aksiyon turu.
- `action_owner`: Aksiyondan sorumlu kisi veya ekip.
- `target_date`: Hedef tarih.
- `action_description`: Aksiyonun kisa aciklamasi.
- `status`: Aksiyon kaydinin durumu. Varsayilan deger `planned`.
- `notes`: Ek not alani. Varsayilan deger `None`.

## Santiye Pratigindeki Karsiligi

Santiye sefi bir uygunsuzluk adayini degerlendirdikten sonra bu aday icin ne yapilacagini belirleyebilir. Ornegin bir korkuluk eksigi icin "gorev adayi ac", "saha ekibine bildir" veya "takip et" gibi ilk aksiyon karari alinabilir.

`NonconformityCandidateActionRecord`, bu ilk karar bilgisini sade sekilde kayda alir. Kararin turu, sorumlusu, hedef tarihi ve kisa aciklamasi tutulur; ancak bu henuz resmi gorev atama veya duzeltici faaliyet sureci degildir.

## Bu Adimda Ozellikle Eklenmeyenler

Bu adimda veritabani eklenmedi.

Bu adimda JSON kayit sistemi eklenmedi.

Bu adimda API eklenmedi.

Bu adimda GUI eklenmedi.

Bu adimda dosya/fotograf eki eklenmedi.

Bu adimda kesin uygunsuzluk yonetimi baslatilmadi.

Bu adimda duzeltici faaliyet sistemi kurulmadı.

Bu adimda gorev atama veya takip akisi kurulmadı.

Bu adim yalnizca degerlendirilen uygunsuzluk adayi icin basit aksiyon kararini tutan veri modelini ekler.

## Sonraki Adimlara Hazirlik

Bu model ileride uygunsuzluk adayi takip durumu, gorev adayi, kesin uygunsuzluk kaydi veya duzeltici faaliyet adayi gibi kayitlarla iliskilendirilebilir.

Bu adimda bu baglantilar kurulmaz. Once aksiyon karari bilgisinin hangi alanlarla tutulacagi netlestirilir.
