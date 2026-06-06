# Adim 028 - Uygunsuzluk Adayi Durum Gecmisi Modeli

## Amac

Bu adimin amaci, uygunsuzluk adayi kayitlarinin durum degisim gecmisini temsil edecek baslangic veri modelini olusturmaktir.

Bir aday kayit acildiktan sonra incelemeye alinabilir, aksiyon karari verilebilir, takip edilebilir veya kapanabilir. Bu adim, "hangi tarihte hangi durumdan hangi duruma gecildi" sorusuna veri modeli seviyesinde temel hazirlar.

## Eklenen Model

Bu adimda `NonconformityCandidateStatusHistoryRecord` modeli eklendi.

Bu model otomatik durum guncelleme sistemi, is akisi motoru, veritabani log tablosu, API cevabi veya GUI ekrani degildir. Sadece durum degisikligi kaydinin hangi alanlarla tutulacagini netlestirir.

## Model Alanlari

- `candidate_id`: Durum gecmisi tutulan uygunsuzluk adayinin kodu.
- `old_status`: Degisiklikten onceki durum.
- `new_status`: Degisiklikten sonraki durum.
- `change_reason`: Durum degisikliginin sebebi.
- `changed_by`: Degisikligi yapan kisi.
- `change_date`: Degisikligin yapildigi tarih.
- `source_record`: Degisikligin kaynaklandigi kayit veya surec parcasi. Varsayilan deger `None`.
- `notes`: Ek not alani. Varsayilan deger `None`.

## Santiye Pratigindeki Karsiligi

Santiye sefi bir uygunsuzluk adayinin surecini geriye donuk okumak isteyebilir.

Ornegin bir aday once `open` durumda acilir. Daha sonra incelemeye alindiginda `under_review` durumuna gecirilebilir. Aksiyon karari verildiginde `action_planned`, sahada tamamlandiginda `closed` gibi durumlar kullanilabilir.

`NonconformityCandidateStatusHistoryRecord`, bu gecislerin her birini ayri kayit olarak temsil eder. Boylece "kim degistirdi, ne zaman degistirdi, neden degistirdi" bilgisi kaybolmaz.

## Bu Adimda Ozellikle Eklenmeyenler

Bu adimda veritabani sorgusu eklenmedi.

Bu adimda API eklenmedi.

Bu adimda GUI eklenmedi.

Bu adimda otomatik raporlama eklenmedi.

Bu adimda JSON kayit sistemi eklenmedi.

Bu adimda dosya islemi eklenmedi.

Bu adimda otomatik durum guncelleme veya is akisi motoru kurulmadi.

## Sonraki Adimlara Hazirlik

Bu model ileride uygunsuzluk adayi surec raporu, zaman cizelgesi, durum filtresi veya denetim izi icin temel olabilir.

Bu adimda bu mekanizmalar kurulmaz. Once durum gecmisi kaydinin veri sekli netlestirilir.
