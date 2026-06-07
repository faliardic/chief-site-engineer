# Adim 049 - NonconformityRepository Sorumlu Taraf Guncelleme

## Amac

Bu adimda `NonconformityRepository` icine mevcut bir `NonconformityRecord` kaydinin `responsible_party` alanini bellek icinde guncelleyen kucuk ve izole bir davranis eklendi.

Eklenen metot:

```text
update_responsible_party(nonconformity_id, responsible_party)
```

## Davranis

- Verilen `nonconformity_id` ile kayit aranir.
- Kayit bulunursa `responsible_party` alani yeni degerle guncellenir.
- `responsible_party` degeri `str` veya `None` olabilir.
- Guncellenen kayit dondurulur.
- Kayit bulunamazsa `None` dondurulur.
- Mevcut kayit sirasi degismez.
- Otomatik `NonconformityAssignmentRecord` olusturulmaz.

## Neden Gerekli?

Kesin uygunsuzluk / NCR kayitlarinda sorumlu taraf zaman icinde degisebilir. Bir kayit once bir kisiye, sonra bir ekip veya firmaya devredilebilir.

Bu adim, sorumlu taraf bilgisinin repository seviyesinde bellek ici olarak guncellenebilmesi icin baslangic davranisini ekler.

## Ozetlere Etkisi

Guncelleme sonrasi mevcut filtre ve ozet davranislari yeni degeri kullanir:

- `list_by_responsible_party`
- `get_responsible_party_summary`
- `get_overview_summary`

`responsible_party` degeri `None` yapilirsa kayit sorumlu atanmamis kabul edilir ve ozetlerde `unassigned` olarak sayilir.

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
- Otomatik assignment history kaydi

Bu davranis sadece bellek ici Python guncellemesidir.
