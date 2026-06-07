# Adim 065 - Uygunsuzluk Duruma Gore Filtreleme

## Amac

Bu adimda `NonconformityRepository` icindeki status filtreleme davranisi test ve dokumantasyonla netlestirildi.

Repository icinde bu davranis mevcut adlandirmayla su method uzerinden saglanir:

```text
list_by_status(status)
```

## Onemli Not

`filter_by_status(status)` adi altinda yeni bir method eklenmedi. Cunku repository icinde ayni ihtiyaci karsilayan `list_by_status(status)` davranisi zaten vardi.

Bu adimda mevcut davranis tekrar yazilmadi; ek testlerle sabitlendi.

## Beklenen Davranis

`list_by_status(status)` su kurallara gore calisir:

- Verilen `status` degeriyle eslesen NCR kayitlarini dondurur.
- Eslesen kayit yoksa bos liste dondurur.
- Repository bos ise bos liste dondurur.
- Aktif kayitlari filtreleyebilir.
- Arsivlenmis kayitlari varsayilan olarak dislamaz.
- Kayitlari silmez.
- `status` alanini degistirmez.
- `is_archived` alanini degistirmez.
- Otomatik history veya workflow olusturmaz.

## Arsiv Kayitlari Neden Dislanmaz?

Status filtresi tum repository hafizasi uzerinde calisir. Bir kayit arsivlenmis olsa bile status bilgisi kalite gecmisinin parcasidir.

Bu nedenle `is_archived == True` olan kayitlar, status degeri eslesiyorsa `list_by_status(status)` sonucunda yer alabilir.

Aktif veya arsiv ayrimi yapmak gerekiyorsa `list_active()` ve `list_archived()` davranislari kullanilmalidir.

## Restore Sonrasi Beklenti

Bir kayit once arsivlenip sonra restore edilirse, status degeri degismez. Bu nedenle ayni status filtresi kaydi bulmaya devam eder.

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

Bu adim sadece mevcut bellek ici status filtreleme davranisini netlestirir.

## Santiye Pratigindeki Karsiligi

Santiye sefi acik, kapali veya devam eden NCR kayitlarini ayri gormek isteyebilir.

Status filtreleme davranisi, "Açık uygunsuzluklar neler?" veya "Kapalı ama arşivde duran NCR kayıtları hangileri?" gibi sorulara temel cevap altyapisini hazirlar.
