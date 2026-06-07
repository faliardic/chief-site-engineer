# Adim 055 - NonconformityRepository Restore

## Amac

Bu adimda `NonconformityRepository` icine arsivlenmis bir `NonconformityRecord` kaydini silmeden tekrar aktif hale getiren kucuk ve izole bir davranis eklendi.

Eklenen metot:

```text
restore(nonconformity_id)
```

## Davranis

- Verilen `nonconformity_id` ile kayit aranir.
- Kayit bulunursa `is_archived` alani `False` yapilir.
- Guncellenen kayit dondurulur.
- Kayit bulunamazsa `None` dondurulur.
- Mevcut kayit sirasi degismez.
- Kayit silinmez.
- `status` alani degistirilmez.
- Otomatik kapanis veya durum gecmisi olusturulmaz.

## Neden Gerekli?

Bir NCR kaydi yanlislikla arsivlenmis olabilir veya yeniden aktif takip gerektirebilir.

`restore` davranisi, kaydi silmeden ve yeniden olusturmadan arsivden aktif listeye almanin bellek ici temelini saglar.

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
- Otomatik kapanis
- Otomatik durum gecmisi
- Otomatik is akisi

Bu davranis sadece bellek ici Python guncellemesidir.
