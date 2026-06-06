# Adim 029 - Uygunsuzluk Adayi Sorumluluk / Atama Modeli

## Amac

Bu adimin amaci, uygunsuzluk adayi kayitlarinin kime atandigini, kim tarafindan atandigini, ne zamana kadar sonuc bekledigini ve oncelik seviyesini temsil edecek baslangic veri modelini olusturmaktir.

Bu model, "bu uygunsuzluk adayini kim takip edecek, kime atandi, kim atadi, ne zamana kadar sonuclanmali" sorularina veri modeli seviyesinde temel hazirlar.

## Eklenen Model

Bu adimda `NonconformityCandidateAssignmentRecord` modeli eklendi.

Bu model otomatik gorev atama, bildirim, is emri, veritabani sorgusu, API cevabi veya GUI ekrani degildir. Sadece sorumluluk ve atama bilgisinin hangi alanlarla tutulacagini netlestirir.

## Model Alanlari

- `candidate_id`: Atama yapilan uygunsuzluk adayinin kodu.
- `assigned_to`: Takipten sorumlu kisi veya ekip.
- `assigned_by`: Atamayi yapan kisi.
- `assignment_date`: Atamanin yapildigi tarih.
- `due_date`: Sonuc beklenen hedef tarih. Varsayilan deger `None`.
- `responsibility_note`: Sorumluluk aciklamasi. Varsayilan deger `None`.
- `priority`: Oncelik seviyesi. Varsayilan deger `normal`.
- `status`: Atama kaydinin durumu. Varsayilan deger `assigned`.
- `notes`: Ek not alani. Varsayilan deger `None`.

## Santiye Pratigindeki Karsiligi

Santiye sefi bir uygunsuzluk adayini gordugunde bu aday sahada takip edilmelidir. Ancak takip sorumlusu, hedef tarihi ve onceligi net degilse aday kayit acik kalabilir.

`NonconformityCandidateAssignmentRecord`, aday kaydin kime zimmetlendigini ve kim tarafindan atandigini sade sekilde tutar. Ornegin "korkuluk eksigi saha muhendisine atandi, 18 Haziran'a kadar takip edilecek, oncelik yuksek" bilgisi bu modelle temsil edilir.

## Bu Adimda Ozellikle Eklenmeyenler

Bu adimda veritabani sorgusu eklenmedi.

Bu adimda API eklenmedi.

Bu adimda GUI eklenmedi.

Bu adimda otomatik bildirim eklenmedi.

Bu adimda otomatik gorev atama eklenmedi.

Bu adimda JSON kayit sistemi eklenmedi.

Bu adimda dosya islemi eklenmedi.

## Sonraki Adimlara Hazirlik

Bu model ileride atama listesi, sorumlu kisi filtresi, hedef tarih takibi, oncelik etiketi veya bildirim sistemi icin temel olabilir.

Bu adimda bu mekanizmalar kurulmaz. Once sorumluluk ve atama kaydinin veri sekli netlestirilir.
