# Adim 030 - Uygunsuzluk Adayi Kapanis / Sonuc Modeli

## Amac

Bu adimin amaci, uygunsuzluk adayi kayitlarinin nasil sonuclandigini ve hangi gerekceyle kapatildigini temsil edecek baslangic veri modelini olusturmaktir.

Bu model, "bu uygunsuzluk adayi nasil sonuclandi, kim kapatti, hangi gerekceyle kapatti, takip gerekiyor mu, kesin uygunsuzluga donustu mu" sorularina veri modeli seviyesinde temel hazirlar.

## Eklenen Model

Bu adimda `NonconformityCandidateClosureRecord` modeli eklendi.

Bu model otomatik kapatma, otomatik durum guncelleme, kesin uygunsuzluk/NCR olusturma, veritabani sorgusu, API cevabi veya GUI ekrani degildir. Sadece kapanis ve sonuc bilgisinin hangi alanlarla tutulacagini netlestirir.

## Model Alanlari

- `candidate_id`: Kapatilan veya sonuclandirilan uygunsuzluk adayinin kodu.
- `closure_decision`: Aday kaydin nasil sonuclandirildigini anlatan karar.
- `closure_reason`: Kapanis kararinin gerekcesi.
- `closed_by`: Kaydi kapatan kisi.
- `closure_date`: Kapanis tarihi.
- `final_status`: Kapanis sonrasi nihai durum.
- `result_note`: Sonuc aciklamasi. Varsayilan deger `None`.
- `requires_follow_up`: Kapanis sonrasi takip gerekip gerekmedigi. Varsayilan deger `False`.
- `notes`: Ek not alani. Varsayilan deger `None`.

## Santiye Pratigindeki Karsiligi

Santiye sefi bir uygunsuzluk adayini sonsuza kadar acik tutmak istemez. Aday ya sahada giderilir, ya takipte kalir, ya da kesin uygunsuzluk kaydina donusmesi gerekir.

`NonconformityCandidateClosureRecord`, bu son karar anini sade sekilde kayda alir. Ornegin "korkuluk eksigi giderildi, santiye sefi tarafindan kapatildi, takip gerekiyor" veya "eksik giderilmedi, resmi NCR'a donusturulmeli" bilgisi bu modelle temsil edilir.

## Bu Adimda Ozellikle Eklenmeyenler

Bu adimda veritabani sorgusu eklenmedi.

Bu adimda API eklenmedi.

Bu adimda GUI eklenmedi.

Bu adimda otomatik kapatma eklenmedi.

Bu adimda otomatik durum guncelleme eklenmedi.

Bu adimda kesin uygunsuzluk/NCR olusturma eklenmedi.

Bu adimda JSON kayit sistemi eklenmedi.

Bu adimda dosya islemi eklenmedi.

## Sonraki Adimlara Hazirlik

Bu model ileride kapanis raporu, durum gecmisi, surec ozeti, resmi uygunsuzluk olusturma karari veya takip listesi icin temel olabilir.

Bu adimda bu mekanizmalar kurulmaz. Once kapanis ve sonuc kaydinin veri sekli netlestirilir.
