# Adim 054 - NonconformityRepository Arsivleme

## Amac

Bu adimda `NonconformityRepository` icine mevcut bir `NonconformityRecord` kaydini silmeden arsivli hale getiren kucuk ve izole bir davranis eklendi.

Eklenen metot:

```text
archive(nonconformity_id)
```

## Davranis

- Verilen `nonconformity_id` ile kayit aranir.
- Kayit bulunursa `is_archived` alani `True` yapilir.
- Guncellenen kayit dondurulur.
- Kayit bulunamazsa `None` dondurulur.
- Mevcut kayit sirasi degismez.
- Kayit silinmez.
- `status` alani degistirilmez.
- Otomatik kapanis veya durum gecmisi olusturulmaz.

## Neden Gerekli?

Kesin uygunsuzluk / NCR kayitlari kalite arsivinin parcasidir. Bir kayit aktif takipten ciksa bile tamamen silinmemeli, izlenebilir kalmalidir.

`archive` davranisi, kaydi bellek icinde arsivli olarak isaretleyerek bu ayrimin temelini olusturur.

## Kapsam Disi Birakilanlar

Bu adimda su mekanizmalar eklenmedi:

- NonconformityRecord model degisikligi
- Restore davranisi
- JSON
- SQLite
- API
- GUI
- CLI
- Dashboard
- Dosya islemi
- Silme
- Otomatik kapanis
- Otomatik durum gecmisi
- Otomatik is akisi

Bu davranis sadece bellek ici Python guncellemesidir.
