# Adim 052 - NonconformityRecord Arsiv Alani

## Amac

Bu adimda `NonconformityRecord` icine kaydin arsivlenip arsivlenmedigini temsil eden kucuk ve izole bir boolean alan eklendi.

Eklenen alan:

```text
is_archived: bool = False
```

## Davranis

- Yeni `NonconformityRecord` olusturuldugunda `is_archived` varsayilan olarak `False` gelir.
- `is_archived=True` verilirse kayit arsivlenmis olarak temsil edilebilir.
- Var olan model alanlari korunur.
- Bu adimda arsivleme metodu veya repository filtreleme davranisi eklenmez.

## Neden Gerekli?

Kesin uygunsuzluk / NCR kayitlari kalite arsivinin parcasidir. Bu kayitlar silinmek yerine arsivlenmis olarak isaretlenebilmelidir.

`is_archived` alani, ileride silme yerine pasiflestirme veya arsivleme davranislari icin temel olusturur.

## Kapsam Disi Birakilanlar

Bu adimda su mekanizmalar eklenmedi:

- Repository archive/restore davranisi
- JSON
- SQLite
- API
- GUI
- CLI
- Dashboard
- Dosya islemi
- Silme
- Otomatik arsivleme
- Otomatik is akisi

Bu adim sadece model icinde arsiv durumunu temsil eden alan ekler.
