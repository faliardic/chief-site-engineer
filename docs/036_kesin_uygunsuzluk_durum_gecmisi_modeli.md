# Adim 036 - Kesin Uygunsuzluk Durum Gecmisi Modeli

## Amac

Bu adimda kesin uygunsuzluk / NCR kayitlarinin durum degisim gecmisini temsil edecek baslangic veri modeli eklendi.

Model adi:

```text
NonconformityStatusHistoryRecord
```

Bu model, bir kesin uygunsuzlugun hangi tarihte hangi durumdan hangi duruma gectigini, degisiklik sebebini ve degisikligi yapan kisiyi kayit altina almak icin kullanilir.

## Model Alanlari

- `nonconformity_id`: Durum degisikligi yapilan kesin uygunsuzluk / NCR kaydi.
- `old_status`: Degisiklikten onceki durum.
- `new_status`: Degisiklikten sonraki durum.
- `change_reason`: Durum degisikliginin gerekcesi.
- `changed_by`: Durum degisikligini yapan kisi.
- `change_date`: Durum degisikliginin yapildigi tarih.
- `source_record`: Degisikligin kaynaklandigi kayit veya surec parcasi. Varsayilan deger `None`.
- `notes`: Ek aciklama alani. Varsayilan deger `None`.

## Santiye Karsiligi

Kesin uygunsuzluk kaydi tek bir durumdan ibaret degildir. Bir NCR once acilabilir, sonra incelemeye alinabilir, aksiyon bekleyebilir, saha duzeltmesi tamamlanabilir ve sonunda kapatilabilir.

`NonconformityStatusHistoryRecord`, bu gecislerin her birini ayri kayit olarak temsil eder. Boylece su sorularin cevabi kaybolmaz:

- Bu NCR ne zaman acildi?
- Ne zaman incelemeye alindi?
- Ne zaman aksiyon bekleme durumuna gecti?
- Ne zaman kapatildi?
- Durumu kim degistirdi?
- Degisiklik hangi gerekceyle yapildi?

## Sistem Mimarisi Acisindan Karar

Bu adimda durum gecmisi, mevcut `NonconformityRecord` modelinin icine liste olarak eklenmedi. Bunun yerine ayri bir dataclass modeli tanimlandi.

Bu tercih, guncel durum ile durum gecmisi arasindaki farki netlestirir:

- `NonconformityRecord.status`: Kaydin mevcut durumunu gosterir.
- `NonconformityStatusHistoryRecord`: Kaydin durum degisim izini temsil eder.

## Kapsam Disi Birakilanlar

Bu adimda su mekanizmalar eklenmedi:

- Veritabani sorgusu
- API
- GUI
- Otomatik durum guncelleme
- Otomatik NCR olusturma
- Duzeltici faaliyet sistemi
- Onay akisi
- JSON kayit sistemi
- Dosya islemi

Bu adim yalnizca kesin uygunsuzluk durum gecmisi icin veri modelini, testini ve dokumantasyonunu hazirlar.
