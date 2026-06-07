# Adim 051 - NonconformityRepository Kayit Sayisi

## Amac

Bu adimda `NonconformityRepository` icine toplam kayit sayisini ve belirli `status` degerine sahip kayit sayisini donduren kucuk ve izole davranislar eklendi.

Eklenen metotlar:

```text
count()
count_by_status(status)
```

## count Davranisi

- Repository icindeki toplam `NonconformityRecord` sayisini int olarak dondurur.
- Bos repository icin `0` dondurur.
- Mevcut kayitlari degistirmez.

## count_by_status Davranisi

- Verilen `status` degerine sahip kayit sayisini int olarak dondurur.
- Eslesen kayit yoksa `0` dondurur.
- Mevcut kayitlari degistirmez.
- `list_by_status` davranisini bozmaz.

## Neden Gerekli?

Kesin uygunsuzluk / NCR kayitlari arttikca sadece kayit listesini gormek yeterli olmaz. Toplam kac NCR oldugunu ve kacinin acik veya kapali oldugunu hizlica bilmek gerekir.

Bu adim, ileride rapor, dashboard veya AI soru-cevap tarafina veri hazirlayabilecek basit sayma davranisini ekler.

## Kapsam Disi Birakilanlar

Bu adimda su mekanizmalar eklenmedi:

- JSON
- SQLite
- API
- GUI
- CLI
- Dashboard
- Dosya islemi
- Silme
- Arsivleme
- Otomatik is akisi

Bu davranis sadece bellek ici Python sayimidir.
