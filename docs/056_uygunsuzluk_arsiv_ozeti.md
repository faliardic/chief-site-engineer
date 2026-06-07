# Adim 056 - Uygunsuzluk Arsiv Ozeti

## Amac

Bu adimda `NonconformityRepository` icine aktif, arsivlenmis ve toplam NCR kayit sayilarini veren kucuk ve izole bir bellek ici ozet davranisi eklendi.

Eklenen metot:

```text
get_archive_summary()
```

## Davranis

Metot su yapida bir sozluk dondurur:

```python
{
    "active": 3,
    "archived": 2,
    "total": 5,
}
```

- `active`: `is_archived == False` olan NCR kayit sayisi.
- `archived`: `is_archived == True` olan NCR kayit sayisi.
- `total`: repository icindeki toplam NCR kayit sayisi.

Bos repository icin sonuc:

```python
{
    "active": 0,
    "archived": 0,
    "total": 0,
}
```

## Neden Gerekli?

Arsivleme ve restore davranislari eklendikten sonra sistemin aktif ve arsiv kayit sayilarini tek bakista gostermesi gerekir.

Bu ozet, ileride dashboard, rapor veya AI soru-cevap sistemi icin veri hazirlayabilecek kucuk bir temel davranistir.

## Kapsam Disi Birakilanlar

Bu adimda su mekanizmalar eklenmedi:

- Kayit silme
- JSON
- SQLite
- API
- GUI
- CLI
- Dashboard
- Dosya islemi
- Otomatik history
- Otomatik workflow
- Otomatik status degisimi

Bu davranis sadece bellek ici Python ozetidir.
