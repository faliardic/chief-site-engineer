# Adim 023 - Basit Uygunsuzluk Adayi Degerlendirme Kayit Modeli Baslangici

## Amac

Bu adimin amaci, Adim 022'de eklenen uygunsuzluk adayi kaydinin degerlendirme bilgisini sade bir veri modeliyle temsil etmektir.

Sahada fark edilen her eksik, hata, risk veya gozlem hemen kesin uygunsuzluk olarak kabul edilmeyebilir. Once bu aday bilginin kim tarafindan incelendigi, ne zaman degerlendirildigi, hangi sonuca varildigi ve bundan sonra ne yapilacagi kayda alinmalidir.

## Eklenen Model

Bu adimda `NonconformityCandidateReviewRecord` modeli eklendi.

Model, uygunsuzluk adayinin degerlendirme sonucunu veri seviyesinde tutar. Bu model kesin uygunsuzluk kaydi, NCR sureci veya duzeltici faaliyet sistemi degildir.

## Model Alanlari

- `candidate_title`: Degerlendirilen uygunsuzluk adayinin basligi.
- `reviewed_by`: Degerlendirmeyi yapan kisi.
- `review_date`: Degerlendirme tarihi.
- `review_result`: Degerlendirme sonucu.
- `decision_reason`: Kararin gerekcesi.
- `next_action`: Bundan sonra yapilacak islem.
- `status`: Degerlendirme kaydinin durumu. Varsayilan deger `reviewed`.
- `notes`: Ek not alani. Varsayilan deger `None`.

## Santiye Pratigindeki Karsiligi

Santiye sefi sahada bir uygunsuzluk adayi gordugunde bu bilginin hemen resmi uygunsuzluk kaydina donusup donusmeyecegine karar vermek zorunda kalabilir.

`NonconformityCandidateReviewRecord`, bu karar anini sade sekilde kayda alir. Ornegin bir korkuluk eksigi once aday olarak yazilir, sonra santiye sefi tarafindan degerlendirilir. Degerlendirme sonucunda takip gerektigi, neden bu karar verildigi ve sonraki aksiyonun ne oldugu kaydedilebilir.

## Bu Adimda Ozellikle Eklenmeyenler

Bu adimda veritabani eklenmedi.

Bu adimda JSON kayit sistemi eklenmedi.

Bu adimda API eklenmedi.

Bu adimda GUI eklenmedi.

Bu adimda dosya/fotograf eki eklenmedi.

Bu adimda kesin uygunsuzluk yonetimi baslatilmadi.

Bu adimda duzeltici faaliyet sistemi kurulmadı.

Bu adim yalnizca uygunsuzluk adayinin degerlendirme bilgisini tutan veri modelini ekler.

## Sonraki Adimlara Hazirlik

Bu model ileride uygunsuzluk karari, aksiyon baglantisi, gorev adayi, kontrol sonucu veya duzeltici faaliyet adayi gibi kayitlarla iliskilendirilebilir.

Bu adimda bu baglantilar kurulmaz. Once degerlendirme bilgisinin hangi alanlarla tutulacagi netlestirilir.
