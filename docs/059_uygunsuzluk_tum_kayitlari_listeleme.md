# Adim 059 - Uygunsuzluk Tum Kayitlari Listeleme

## Amac

Bu adimda `NonconformityRepository` icindeki tum NCR kayitlarini listeleme davranisi netlestirildi.

Tum kayit listesi, aktif veya arsivlenmis ayrimi yapmadan repository icindeki butun `NonconformityRecord` nesnelerini kapsar.

## Onemli Not

`list_all()` davranisi repository icinde zaten bulunuyordu. Bu nedenle Adim 059'da ayni method tekrar eklenmedi.

Bu adimda mevcut davranis test ve dokumantasyonla sabitlendi.

## Beklenen Davranis

`list_all()` su kurallara gore calisir:

- Aktif kayitlari dondurur.
- Arsivlenmis kayitlari da dondurur.
- Bos repository icin bos liste dondurur.
- Mevcut eklenme sirasini korur.
- Kayitlari silmez.
- `status` alanini degistirmez.
- `is_archived` alanini degistirmez.
- Otomatik history veya workflow olusturmaz.

## Archive ve Restore ile Iliskisi

`archive(nonconformity_id)` bir kaydi arsivli hale getirir, ancak kaydi repository'den cikartmaz.

`restore(nonconformity_id)` kaydi yeniden aktif hale getirir, ancak kaydin tum liste icindeki yerini degistirmez.

Bu nedenle `list_all()` hem arsivleme hem restore islemlerinden sonra toplam kayit listesini korur.

## Kapsam Disi Birakilanlar

Bu adimda sunlar eklenmedi:

- JSON kayit sistemi
- SQLite veya veritabani sorgusu
- API
- GUI
- CLI
- Dashboard
- Silme mantigi
- Otomatik arsivleme
- Otomatik durum gecmisi
- Otomatik workflow
- Buyuk refactor

## Santiye Pratigindeki Karsiligi

Sahada sadece aktif NCR kayitlarini gormek bazen yeterli degildir. Kalite hafizasi icin aktif ve arsivlenmis tum kayitlarin birlikte gorulebilmesi gerekir.

`list_all()` bu tam kayit hafizasini temsil eder. Aktif takip icin filtreli listeler kullanilirken, kalite arsivi ve denetim hafizasi icin tum liste korunur.
