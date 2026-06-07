# Adim 058 - Uygunsuzluk Aktif Kayitlari Listeleme

## Amac

Bu adimda `NonconformityRepository` icindeki aktif NCR kayitlarini listeleme davranisi netlestirildi.

Aktif kayit, `is_archived == False` olan kesin uygunsuzluk kaydidir. Bu kayitlar silinmemis, arsive alinmamis ve normal takip listesinde gorunmesi gereken NCR kayitlaridir.

## Onemli Not

`list_active()` davranisi onceki adimlarda zaten repository icinde bulunuyordu. Bu nedenle Adim 058'de ayni method tekrar eklenmedi.

Bu adimda mevcut davranis test ve dokumantasyonla sabitlendi.

## Beklenen Davranis

`list_active()` su kurallara gore calisir:

- Sadece `is_archived == False` olan kayitlari dondurur.
- `is_archived == True` olan arsivlenmis kayitlari dondurmez.
- Bos repository icin bos liste dondurur.
- Tum kayitlar arsivlenmisse bos liste dondurur.
- Kayitlari silmez.
- `status` alanini degistirmez.
- Otomatik history veya workflow olusturmaz.

## Archive ve Restore ile Iliskisi

`archive(nonconformity_id)` cagrisi bir kaydin `is_archived` alanini `True` yapar. Bu durumda kayit artik aktif listeden cikar.

`restore(nonconformity_id)` cagrisi kaydin `is_archived` alanini tekrar `False` yapar. Bu durumda kayit yeniden aktif listede gorunur.

Bu davranis sadece bellek icindeki Python nesneleri uzerinde calisir.

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

Sahada aktif NCR kayitlari gunluk takip icin onemlidir. Santiye sefi acik ve aktif kalan kalite problemlerini hizlica gorebilmelidir.

Arsivlenmis kayitlar kalite hafizasinda kalir, ancak gunluk takip listesinde aktif is gibi gorunmemelidir. `list_active()` bu ayrimi kucuk ve anlasilir bir repository davranisi olarak temsil eder.
