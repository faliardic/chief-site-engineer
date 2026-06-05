# Adim 015 - Ekip / Iscilik Kaydi Baslangici

## Amac

Bu adimin amaci, santiyedeki ekipleri ve iscilik gruplarini ileride takip edebilmek icin sade bir veri modeli baslangici olusturmaktir.

## Bu Adim Ne Degildir?

Bu adim gercek puantaj, bordro, vardiya, performans veya insan kaynaklari sistemi degildir.

Maas hesabi, performans takibi, vardiya plani, is gucu planlama algoritmasi, veritabani, JSON kayit sistemi, API, GUI/web arayuzu ve Excel/PDF cikti eklenmemistir.

## WorkforceRecord Neyi Temsil Eder?

`WorkforceRecord`, santiyedeki bir ekip veya iscilik grubuna ait temel bilgiyi temsil eder.

Bu model ekip adini, ekip turunu, bagli oldugu firmayi, kisi sayisini, calisma alanini, calisma tarihini ve o gun yapilan isin kisa aciklamasini tutar.

## Model Alanlari

- `crew_name`: Ekip veya iscilik grubu adi.
- `crew_type`: Ekip turu.
- `company`: Bagli firma veya taseron.
- `worker_count`: Kisi sayisi.
- `work_area`: Calisilan mahal, blok, kat veya alan.
- `work_date`: Calisma tarihi.
- `task_description`: Yapilan isin kisa aciklamasi.
- `status`: Kaydin durum bilgisi. Varsayilan deger `active`.
- `notes`: Serbest not alani.

## Kod Seviyesinde Iliski Kurulmadi

Bu adimda `WorkforceRecord`, `ProjectPartyRecord`, `ContactPersonRecord`, `SiteLocationRecord` veya `DailyReportRecord` ile kod seviyesinde baglanmadi.

Bu tercih, modeli sade tutmak ve once ekip/iscilik bilgisinin hangi alanlardan olusacagini netlestirmek icin yapildi.

## Ileride Neye Temel Olacak?

Bu model ileride gunluk rapor, lokasyon/mahal, proje tarafi/taseron, malzeme, is programi ve saha ilerleme kayitlariyla baglanabilir.

Bu baglantilar sonraki adimlarda ihtiyac netlestikce kurulacaktir.
