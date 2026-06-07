# Adim 045 - NonconformityRepository Durum Ozeti

## Amac

Bu adimda `NonconformityRepository` icine kayitlarin durumlara gore temel sayisal ozetini ureten kucuk ve izole bir davranis eklendi.

Eklenen metot:

```text
get_status_summary()
```

## Davranis

- Repository icindeki `NonconformityRecord.status` degerlerini sayar.
- Sonucu `dict` olarak dondurur.
- Ornek sonuc: `{"open": 2, "closed": 1, "in_progress": 1}`.
- Repository bos ise `{}` dondurur.
- Mevcut kayitlari degistirmez.

## Neden Gerekli?

Kesin uygunsuzluk / NCR kayitlarinda sadece listeleme yeterli degildir. Kac kayit acik, kac kayit kapali, kac kayit devam ediyor sorulari surec takibi icin onemlidir.

Bu davranis ileride dashboard, CLI, rapor ve AI soru-cevap sistemi icin temel veri hazirlar.

## Kapsam Disi Birakilanlar

Bu adimda su mekanizmalar eklenmedi:

- JSON
- SQLite
- API
- GUI
- CLI
- Dashboard
- Dosya islemi
- Otomatik is akisi

Bu davranis dashboard degildir. Sadece dashboard veya rapor gibi araclara veri hazirlayabilecek bellek ici Python metodudur.
