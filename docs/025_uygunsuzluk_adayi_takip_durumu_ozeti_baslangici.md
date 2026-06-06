# Adim 025 - Uygunsuzluk Adayi Takip Durumu Ozeti Baslangici

## Amac

Bu adimin amaci, uygunsuzluk adayi surecinin guncel takip durumunu tek satirlik ozet bilgi olarak temsil eden sade bir veri modeli eklemektir.

Adim 022'de uygunsuzluk adayi kaydi, Adim 023'te degerlendirme kaydi, Adim 024'te aksiyon karari kaydi eklenmisti. Adim 025 bu zincirin guncel durumunu ozetleyen veri modelini ekler.

## Eklenen Model

Bu adimda `NonconformityCandidateTrackingSummaryRecord` modeli eklendi.

Model, bir uygunsuzluk adayinin su ana kadarki degerlendirme ve aksiyon durumunu veri seviyesinde ozetler. Bu model gercek takip akisi, gorev atama sistemi, otomatik durum guncelleme veya kesin uygunsuzluk yonetimi degildir.

## Model Alanlari

- `candidate_title`: Takip ozeti yapilan uygunsuzluk adayinin basligi.
- `review_result`: Aday icin verilen degerlendirme sonucu.
- `action_decision`: Aday icin alinan aksiyon karari.
- `action_owner`: Aksiyonla iliskili kisi veya ekip.
- `tracking_status`: Guncel takip durumu.
- `last_update_date`: Son takip guncelleme tarihi.
- `summary_note`: Surecin kisa ozeti.
- `status`: Takip ozeti kaydinin genel durumu. Varsayilan deger `active`.
- `notes`: Ek not alani. Varsayilan deger `None`.

## Santiye Pratigindeki Karsiligi

Santiye sefi bir uygunsuzluk adayinin hangi durumda oldugunu hizlica gormek isteyebilir. Aday kayit acilmis, degerlendirilmis, aksiyon karari alinmis olabilir; ancak hala sahada aksiyon bekliyor olabilir.

`NonconformityCandidateTrackingSummaryRecord`, bu bilgiyi tek ozet kayit halinde tutar. Ornegin "korkuluk eksigi icin aksiyon bekleniyor" gibi bir durum, son guncelleme tarihiyle beraber kayda alinabilir.

## Bu Adimda Ozellikle Eklenmeyenler

Bu adimda veritabani eklenmedi.

Bu adimda JSON kayit sistemi eklenmedi.

Bu adimda API eklenmedi.

Bu adimda GUI eklenmedi.

Bu adimda dosya/fotograf eki eklenmedi.

Bu adimda kesin uygunsuzluk yonetimi baslatilmadi.

Bu adimda duzeltici faaliyet sistemi kurulmadı.

Bu adimda gorev atama veya otomatik takip akisi kurulmadı.

Bu adim yalnizca uygunsuzluk adayi surecinin takip durumunu ozetleyen veri modelini ekler.

## Sonraki Adimlara Hazirlik

Bu model ileride surec zinciri gorunumu, takip listesi, raporlama veya kullanici arayuzu icin temel olabilir.

Bu adimda bu baglantilar kurulmaz. Once ozet takip bilgisinin hangi alanlarla tutulacagi netlestirilir.

## Adim 021-025 Araliginin Kapanisi

Adim 021-025 araliginda kontrol sonucu, uygunsuzluk adayi, aday degerlendirmesi, aday aksiyonu ve takip durumu ozeti modelleri eklendi.

Bu aralik tamamlandigi icin Adim 025 commitlendikten sonra final NotebookLM podcast notu hazirlanacaktir.
