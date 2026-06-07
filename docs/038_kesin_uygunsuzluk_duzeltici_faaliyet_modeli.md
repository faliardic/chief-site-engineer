# Adim 038 - Kesin Uygunsuzluk Duzeltici Faaliyet Modeli

## Amac

Bu adimda kesin uygunsuzluk / NCR kaydi icin yapilacak duzeltici faaliyeti temsil eden kucuk ve izole bir veri modeli eklendi.

Model adi:

```text
NonconformityCorrectiveActionRecord
```

Bu model, kesin uygunsuzlugu gidermek icin hangi faaliyetin planlandigini, sorumlusunu, planlanan baslangic tarihini, hedef tarihini ve faaliyet durumunu kayit altina almak icin kullanilir.

## Model Alanlari

- `nonconformity_id`: Duzeltici faaliyet baglanan kesin uygunsuzluk / NCR kaydi.
- `action_title`: Duzeltici faaliyet basligi.
- `action_description`: Duzeltici faaliyetin aciklamasi.
- `responsible_party`: Faaliyetten sorumlu kisi, ekip, firma veya birim.
- `planned_start_date`: Planlanan baslangic tarihi.
- `due_date`: Hedef bitis tarihi.
- `completion_date`: Tamamlanma tarihi. Varsayilan deger `None`.
- `verification_required`: Dogrulama gerekip gerekmedigi. Varsayilan deger `True`.
- `status`: Faaliyet durumu. Varsayilan deger `planned`.
- `notes`: Ek aciklama alani. Varsayilan deger `None`.

## Uygunsuzluk Kaydi Ile Farki

`NonconformityRecord`, kesin uygunsuzlugun kendisini temsil eder. Yani sahadaki problemin ne oldugunu, nerede oldugunu, kim tarafindan tespit edildigini ve mevcut durumunu anlatir.

`NonconformityCorrectiveActionRecord` ise bu problemi gidermek icin planlanan faaliyeti temsil eder. Yani "ne yapilacak, kim yapacak, ne zaman baslayacak, ne zamana kadar tamamlanacak" sorularina odaklanir.

## Santiye Karsiligi

Bir NCR acildiginda yalnizca problemi kaydetmek yeterli degildir. Saha ekiplerinin neyi duzeltecegi, sorumlunun kim oldugu ve duzeltmenin ne zamana kadar tamamlanacagi da izlenmelidir.

Bu model, kesin uygunsuzluk ile duzeltici faaliyet takibini birbirinden ayirarak daha okunabilir bir surec zemini olusturur.

## Kapsam Disi Birakilanlar

Bu adimda su mekanizmalar eklenmedi:

- API
- GUI
- Veritabani sorgusu
- JSON kayit sistemi
- Otomatik kapatma
- Onay akisi
- Bildirim
- Dosya islemi

Bu adim yalnizca kesin uygunsuzluk duzeltici faaliyet kaydi icin veri modelini, testini ve dokumantasyonunu hazirlar.
