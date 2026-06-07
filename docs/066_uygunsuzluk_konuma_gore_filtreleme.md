# Adim 066 - Uygunsuzluk Konuma Gore Filtreleme

## Amac

Bu adimda `NonconformityRepository` icine NCR kayitlarini `location` alanina gore filtreleyen kucuk ve read-only bir davranis eklendi.

Eklenen method:

```text
list_by_location(location)
```

## Beklenen Davranis

`list_by_location(location)` su kurallara gore calisir:

- Verilen `location` degeriyle eslesen NCR kayitlarini dondurur.
- Eslesen kayit yoksa bos liste dondurur.
- Repository bos ise bos liste dondurur.
- Aktif kayitlari filtreleyebilir.
- Arsivlenmis kayitlari varsayilan olarak dislamaz.
- Kayitlari silmez.
- `location` alanini degistirmez.
- `status` alanini degistirmez.
- `is_archived` alanini degistirmez.
- Otomatik history veya workflow olusturmaz.

## Arsiv Kayitlari Neden Dislanmaz?

Konum filtresi tum repository hafizasi uzerinde calisir. Bir kayit arsivlenmis olsa bile konum bilgisi kalite gecmisinin parcasidir.

Bu nedenle `is_archived == True` olan kayitlar, konum degeri eslesiyorsa `list_by_location(location)` sonucunda yer alabilir.

Aktif veya arsiv ayrimi gerekiyorsa `list_active()` ve `list_archived()` davranislari ayrica kullanilmalidir.

## Restore Sonrasi Beklenti

Bir kayit once arsivlenip sonra restore edilirse, `location` degeri degismez. Bu nedenle ayni konum filtresi kaydi bulmaya devam eder.

Restore islemi sadece `is_archived` alanini `False` yapar.

## Kapsam Disi Birakilanlar

Bu adimda sunlar eklenmedi:

- JSON
- SQLite
- API
- GUI
- CLI
- Buyuk refactor
- Silme mantigi
- Yeni query engine
- Otomatik history
- Otomatik workflow

Bu adim sadece bellek ici konuma gore filtreleme davranisi ekler.

## Santiye Pratigindeki Karsiligi

Santiye sefi belirli bir blok, kat, mahal veya saha bolgesindeki NCR kayitlarini ayri gormek isteyebilir.

Konuma gore filtreleme, "A Blok'taki uygunsuzluklar neler?" veya "Bu bolgede daha once kalite sorunu yasandi mi?" gibi sorular icin temel altyapiyi hazirlar.
