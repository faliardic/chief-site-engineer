# Adim 046 - NonconformityRepository Sorumlu Taraf Ozeti

## Amac

Bu adimda `NonconformityRepository` icine kayitlari sorumlu taraf degerlerine gore sayan kucuk ve izole bir ozet davranisi eklendi.

Eklenen metot:

```text
get_responsible_party_summary()
```

## Davranis

- Repository icindeki `NonconformityRecord.responsible_party` degerlerini sayar.
- Sonucu `dict` olarak dondurur.
- `responsible_party` degeri `None` olan kayitlari `unassigned` anahtari altinda toplar.
- Ornek sonuc: `{"Ahmet": 2, "Mehmet": 1, "unassigned": 1}`.
- Repository bos ise `{}` dondurur.
- Mevcut kayitlari degistirmez.

## Neden Gerekli?

Kesin uygunsuzluk / NCR kayitlarinda sadece durum sayisi degil, kayitlarin kimin sorumlulugunda oldugu da onemlidir.

Bu davranis ileride dashboard, rapor ve AI soru-cevap sistemi icin sorumlu taraf bazli temel veri hazirlar.

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
