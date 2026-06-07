# Adim 053 - NonconformityRepository Aktif / Arsiv Filtreleme

## Amac

Bu adimda `NonconformityRepository` icine `NonconformityRecord` kayitlarini `is_archived` alanina gore aktif ve arsivlenmis olarak ayiran kucuk ve izole davranislar eklendi.

Eklenen metotlar:

```text
list_active()
list_archived()
```

## list_active Davranisi

- `is_archived == False` olan kayitlari liste olarak dondurur.
- Eslesen kayit yoksa bos liste dondurur.
- Mevcut eklenme sirasini korur.
- Mevcut kayitlari degistirmez.

## list_archived Davranisi

- `is_archived == True` olan kayitlari liste olarak dondurur.
- Eslesen kayit yoksa bos liste dondurur.
- Mevcut eklenme sirasini korur.
- Mevcut kayitlari degistirmez.

## Neden Gerekli?

Kesin uygunsuzluk / NCR kayitlari silinmeden aktif ve arsivlenmis olarak ayrilabilmelidir.

Bu davranis, ileride rapor, dashboard veya kalite arsivi sorgulari icin temel bir bellek ici filtreleme saglar.

## Kapsam Disi Birakilanlar

Bu adimda su mekanizmalar eklenmedi:

- NonconformityRecord model degisikligi
- JSON
- SQLite
- API
- GUI
- CLI
- Dashboard
- Dosya islemi
- Silme
- Otomatik arsivleme
- Restore
- Otomatik is akisi

Bu davranis sadece bellek ici Python filtrelemesidir.
