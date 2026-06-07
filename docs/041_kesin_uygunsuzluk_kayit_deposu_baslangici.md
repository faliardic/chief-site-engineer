# Adim 041 - Kesin Uygunsuzluk Kayit Deposu Baslangici

## Amac

Bu adimda `NonconformityRecord` kayitlarini bellek icinde yonetmek icin kucuk ve izole bir repository sinifi eklendi.

Eklenen sinif:

```text
NonconformityRepository
```

Bu repository, kesin uygunsuzluk / NCR kayitlarini program calisirken liste icinde tutar.

## Davranislar

- `add(record)`: Bellek icindeki listeye yeni `NonconformityRecord` ekler.
- `list_all()`: Bellekteki tum kesin uygunsuzluk kayitlarini dondurur.
- `find_by_id(nonconformity_id)`: NCR kimligine gore kayit arar.
- Kayit bulunamazsa `None` dondurur.

## Model Ile Repository Arasindaki Fark

`NonconformityRecord`, kesin uygunsuzluk kaydinin veri seklini temsil eder.

`NonconformityRepository`, bu kayitlarin bellek icinde nasil tutulup bulunacagini temsil eder.

Yani model "kayit nedir?" sorusuna, repository ise "kayitlar nasil yonetilir?" sorusuna cevap verir.

## Kapsam Disi Birakilanlar

Bu adimda su mekanizmalar eklenmedi:

- JSON kayit
- SQLite
- API
- GUI
- CLI
- Dosya islemi
- Otomatik is akisi

Bu adim yalnizca bellek ici baslangic kayit deposu davranisini ekler.
