# Adim 047 - NonconformityRepository Genel Ozet

## Amac

Bu adimda `NonconformityRepository` icine toplam kayit sayisini, acik/kapanmis kayit sayilarini ve sorumlu atanmis/atanmamis kayit sayilarini veren kucuk ve izole bir genel ozet davranisi eklendi.

Eklenen metot:

```text
get_overview_summary()
```

## Davranis

Metot su anahtarlari iceren bir `dict` dondurur:

- `total`: Tum kayit sayisi.
- `open`: `status == "open"` olan kayit sayisi.
- `closed`: `status == "closed"` olan kayit sayisi.
- `assigned`: `responsible_party` degeri `None` olmayan kayit sayisi.
- `unassigned`: `responsible_party` degeri `None` olan kayit sayisi.

Bos repository icin tum degerler `0` olarak dondurulur.

## Neden Gerekli?

Bu davranis ileride dashboard, CLI, rapor veya AI soru-cevap sistemi icin temel veri hazirlar. Ancak bu adimda bunlardan hicbiri eklenmez.

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

Bu davranis sadece bellek ici Python metodudur.
