# Adim 037 - Kesin Uygunsuzluk Sorumluluk / Atama Modeli

## Amac

Bu adimda kesin uygunsuzluk / NCR kaydinin hangi kisi, ekip, firma veya sorumlu birime atandigini temsil edecek kucuk ve izole bir veri modeli eklendi.

Model adi:

```text
NonconformityAssignmentRecord
```

Bu model, kesin uygunsuzlugun takibinden kimin sorumlu oldugunu, atamayi kimin yaptigini, sorumluluk kapsamini ve hedef tarihi kayit altina almak icin kullanilir.

## Model Alanlari

- `nonconformity_id`: Atama yapilan kesin uygunsuzluk / NCR kaydi.
- `assigned_to`: Atanan kisi, ekip, firma veya birim.
- `assigned_role`: Atanan tarafin rolu veya sorumluluk tipi.
- `assigned_by`: Atamayi yapan kisi.
- `assigned_date`: Atamanin yapildigi tarih.
- `responsibility_scope`: Atanan tarafin sorumluluk kapsami.
- `due_date`: Beklenen takip veya sonuc tarihi. Varsayilan deger `None`.
- `status`: Atama durumu. Varsayilan deger `assigned`.
- `notes`: Ek aciklama alani. Varsayilan deger `None`.

## Santiye Karsiligi

Kesin uygunsuzluk kaydi acildiktan sonra sahada en kritik sorulardan biri sudur:

"Bu kaydi kim takip edecek?"

Bir NCR kalite ekibine, saha muhendisine, alt yuklenici firmaya veya belirli bir sorumlu birime atanabilir. `NonconformityAssignmentRecord`, bu sorumluluk bilgisini sade bir veri kaydi olarak tutar.

## Sistem Mimarisi Acisindan Karar

Bu adimda atama bilgisi `NonconformityRecord` modelinin icine eklenmedi. Bunun yerine ayri bir dataclass modeli tanimlandi.

Bu karar, kesin uygunsuzluk kaydinin temel bilgileri ile sorumluluk atamasi bilgisini ayri tutar.

## Kapsam Disi Birakilanlar

Bu adimda su mekanizmalar eklenmedi:

- API
- GUI
- Veritabani sorgusu
- JSON kayit sistemi
- Otomatik atama
- Bildirim
- Onay akisi
- Dosya islemi

Bu adim yalnizca kesin uygunsuzluk sorumluluk atamasi icin veri modelini, testini ve dokumantasyonunu hazirlar.
