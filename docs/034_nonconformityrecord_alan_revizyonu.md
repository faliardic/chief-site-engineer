# Adim 034 - NonconformityRecord Alan Revizyonu

## Amac

Bu adimin amaci, mevcut `NonconformityRecord` modelini Adim 033 degerlendirme raporuna gore kontrollu sekilde revize etmektir.

Bu adimda yeni `NonconformityRecord` modeli olusturulmadi. Mevcut model korunarak ek alanlarla genisletildi.

## Yapilan Revizyon

Mevcut `NonconformityRecord` modeline su alanlar eklendi:

- `nonconformity_type`
- `detected_by`
- `detection_date`
- `final_status`

Bu alanlar opsiyonel olarak eklendi. Boylece mevcut test ve kullanimlarda zorunlu yeni deger verme ihtiyaci olusmaz.

## Bilincli Olarak Eklenmeyen Alanlar

Su alanlar eklenmedi:

- `source_candidate_id`
- `conversion_record_id`

Gerekce: Aday kayit ile kesin uygunsuzluk kaydi arasindaki donusum baglantisi Adim 032'de eklenen `NonconformityCandidateConversionRecord` modeliyle temsil edilmektedir. Ayni baglanti bilgisini `NonconformityRecord` icinde tekrar etmek model sorumluluklarini karistirabilir.

## Guncellenen Model Mantigi

`NonconformityRecord`, kesin uygunsuzluk / NCR kaydinin kendisini temsil etmeye devam eder.

`NonconformityCandidateConversionRecord`, aday kaydin hangi kesin uygunsuzluk kaydina donustugunu temsil eder.

Bu ayrim korunarak `NonconformityRecord` sadece kesin uygunsuzluk kaydinin ic bilgisini daha iyi tasiyacak sekilde genisletildi.

## Guncellenen Test Mantigi

Mevcut `test_nonconformity_record_holds_values_and_defaults` testi genisletildi.

Yeni alanlar icin su varsayilanlar dogrulandi:

- `nonconformity_type is None`
- `detected_by is None`
- `detection_date is None`
- `final_status is None`

Yeni test eklenmedi. Mevcut model davranisi degistigi icin mevcut testin kapsami genisletildi.

## Santiye Pratigindeki Karsiligi

Kesin uygunsuzluk kaydi artik sadece baslik, aciklama ve durum bilgisiyle kalmaz. Uygunsuzlugun turu, kimin tarafindan tespit edildigi, tespit tarihi ve kapanis sonrasi nihai durum bilgisi icin de alan hazirlanmis olur.

Ancak aday kayittan gelip gelmedigi bilgisi bu modelin icine tekrar yazilmaz. Bu baglanti ayri donusum kaydinda tutulur. Boylece "kesin uygunsuzluk kaydi" ile "adaydan kesin kayda donusum izi" farkli sorumluluklar olarak kalir.

## Bu Adimda Ozellikle Eklenmeyenler

Bu adimda yeni model olusturulmadi.

Bu adimda veritabani sorgusu eklenmedi.

Bu adimda API eklenmedi.

Bu adimda GUI eklenmedi.

Bu adimda otomatik NCR olusturma eklenmedi.

Bu adimda otomatik donusum eklenmedi.

Bu adimda duzeltici faaliyet sistemi eklenmedi.

Bu adimda onay akisi eklenmedi.

Bu adimda JSON kayit sistemi eklenmedi.

Bu adimda dosya islemi eklenmedi.
