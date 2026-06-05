# 002 Cekirdek Veri Modeli

## Bu Adimda Olusturulan Modeller

- `SiteProject`: Santiyeyi ve temel proje bilgilerini temsil eder.
- `ChecklistItem`: Sahada kontrol edilecek maddeleri temsil eder.
- `TrackingRecord`: Gunluk veya periyodik takip kayitlarini temsil eder.
- `ArchiveDocument`: Projeye ait arsiv belgelerini temsil eder.

## Ileride Temel Olacak Moduller

Bu modeller ileride kontrol listeleri, saha takip ekranlari, belge arsivi, raporlama ve veri kayit katmani icin temel olacaktir.

## Neden Bu Asamada Veritabani Kurulmadi?

Bu adimda amac kalici kayit sistemi kurmak degil, sistemin hangi temel verilerle calisacagini netlestirmektir. Veritabani secimi daha sonra gercek kullanim senaryolari, kayit hacmi ve erisim ihtiyaclari netlesince yapilacaktir.

## Santiye Sefi Acisindan Anlami

- `SiteProject`, takip edilen santiyenin kimlik kartidir.
- `ChecklistItem`, kontrol edilmesi gereken is veya kalite maddesidir.
- `TrackingRecord`, sahada gorulen bir durumun, isin veya sorumlulugun kaydidir.
- `ArchiveDocument`, ruhsat, tutanak, proje, fotograf veya benzeri belgelerin arsiv temsilidir.
