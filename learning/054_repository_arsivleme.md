# Adim 054 - Repository Arsivleme Ogrenim Notu

## Repository Icinde Arsivleme Davranisi

Repository icinde kayitlari silmeden arsivli hale getirmek, kaydin izlenebilir kalmasini saglar.

Bu adimda `NonconformityRepository` icine `archive` metodu eklendi.

## archive Ne Ise Yarar?

`archive(nonconformity_id)`, verilen NCR kimligine sahip kaydi bulur ve kaydin `is_archived` alanini `True` yapar.

Kayit bulunursa guncellenen kayit dondurulur. Kayit bulunamazsa `None` dondurulur.

## Silme ile Arsivleme Arasindaki Fark

Silme, kaydin sistemden kaldirilmasi anlamina gelir.

Arsivleme ise kaydi sistemde tutar, ancak aktif takip listesinden ayirir. Bu nedenle kalite kayitlari icin arsivleme daha izlenebilir bir yaklasimdir.

## is_archived Alani Nasil Degistirilir?

Metot once kaydi bulur:

```python
record = self.find_by_id(nonconformity_id)
```

Kayit varsa alan guncellenir:

```python
record.is_archived = True
```

Bu islem sadece bellek icindeki Python nesnesini degistirir.

## Bulunmayan Kayit Icin Neden None?

Aranan `nonconformity_id` repository icinde yoksa arsivlenecek kayit da yoktur.

Bu durumda `None` dondurmek, `find_by_id`, `update_status` ve `update_responsible_party` davranislariyla tutarlidir.

## Status Alani Neden Degistirilmedi?

Arsivleme, kaydin aktif takipten ayrilmasini temsil eder. `status` ise kaydin is surecindeki durumunu temsil eder.

Bu iki bilgi farklidir. Bu nedenle arsivleme sirasinda `status` alani degistirilmedi.

## Neden JSON veya SQLite Guncellemesi Degil?

Bu adimda kalici saklama katmani yoktur.

Repository kayitlari Python listesi icinde, bellek uzerinde tutulur. Bu nedenle arsivleme de simdilik bellek ici Python guncellemesi olarak kalir.

## Santiye Pratiginde Anlami

Santiye kalite kayitlari denetim ve izlenebilirlik icin korunmalidir.

Bir NCR kaydi aktif takipten ciksa bile tamamen silinmemeli; arsivlenerek kalite hafizasinda kalmalidir.

## Testte Ne Kontrol Edildi?

Ilk test, mevcut kaydin arsivlendigini, guncellenen kaydin donduruldugunu, `status` alaninin degismedigini ve kaydin aktif listeden arsiv listesine gectigini dogrular.

Ikinci test, olmayan `nonconformity_id` icin `None` dondugunu ve mevcut kaydin degismedigini dogrular.

## Kapsam Disi Birakilanlar

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

## Kisa Ozet

Adim 054 ile `NonconformityRepository` icinde kayit silmeden arsivleme davranisi eklendi.

Bu adim, kalite kayitlarini aktif takipten ayirirken izlenebilirligi koruyan sade bir bellek ici temel saglar.
