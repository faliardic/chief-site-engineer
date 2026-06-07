# Adim 048 - NonconformityRepository Status Guncelleme

## Amac

Bu adimda `NonconformityRepository` icine mevcut bir `NonconformityRecord` kaydinin `status` alanini bellek icinde guncelleyen kucuk ve izole bir davranis eklendi.

Eklenen metot:

```text
update_status(nonconformity_id, new_status)
```

## Davranis

- Verilen `nonconformity_id` ile kayit aranir.
- Kayit bulunursa `status` alani `new_status` degeriyle guncellenir.
- Guncellenen kayit dondurulur.
- Kayit bulunamazsa `None` dondurulur.
- Mevcut kayit sirasi degismez.
- Otomatik `NonconformityStatusHistoryRecord` olusturulmaz.

## Neden Gerekli?

Kesin uygunsuzluk / NCR kayitlari sahada durum degistirir. Bir kayit once `open`, sonra `in_progress`, daha sonra `verified` veya `closed` olabilir.

Bu adim, bu durum degisikligini repository seviyesinde bellek ici olarak yapmanin baslangicidir.

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
- Otomatik status history kaydi

Bu davranis sadece bellek ici Python guncellemesidir.
