# Adim 055 - Repository Restore Ogrenim Notu

## Repository Icinde Restore Davranisi

Repository icinde arsivlenmis bir kaydi tekrar aktif hale getirmek gerekebilir.

Bu adimda `NonconformityRepository` icine `restore` metodu eklendi.

## restore Ne Ise Yarar?

`restore(nonconformity_id)`, verilen NCR kimligine sahip kaydi bulur ve kaydin `is_archived` alanini `False` yapar.

Kayit bulunursa guncellenen kayit dondurulur. Kayit bulunamazsa `None` dondurulur.

## archive ve restore Arasindaki Fark

`archive(nonconformity_id)` kaydin `is_archived` alanini `True` yapar.

`restore(nonconformity_id)` kaydin `is_archived` alanini tekrar `False` yapar.

Bu iki metot birlikte, kaydi silmeden aktif ve arsiv durumlari arasinda yonetmeye yarar.

## is_archived Alani Nasil Tekrar False Yapilir?

Metot once kaydi bulur:

```python
record = self.find_by_id(nonconformity_id)
```

Kayit varsa alan guncellenir:

```python
record.is_archived = False
```

Bu islem sadece bellek icindeki Python nesnesini degistirir.

## Bulunmayan Kayit Icin Neden None?

Aranan `nonconformity_id` repository icinde yoksa restore edilecek kayit da yoktur.

Bu durumda `None` dondurmek, `find_by_id`, `update_status`, `update_responsible_party` ve `archive` davranislariyla tutarlidir.

## Status Alani Neden Degistirilmedi?

Restore, kaydin arsiv durumunu degistirir. `status` ise kaydin is surecindeki durumunu temsil eder.

Bir kayit `closed` durumundayken arsivden aktif listeye alinabilir; bu onun is sureci status degerinin degismesi anlamina gelmez.

## Neden JSON veya SQLite Guncellemesi Degil?

Bu adimda kalici saklama katmani yoktur.

Repository kayitlari Python listesi icinde, bellek uzerinde tutulur. Bu nedenle restore islemi de simdilik bellek ici Python guncellemesi olarak kalir.

## Santiye Pratiginde Anlami

Santiye kalite kayitlari silinmeden aktif ve arsiv durumlari arasinda yonetilmelidir.

Bir NCR kaydi tekrar incelenmesi gerektiginde yeniden kayit acmak yerine mevcut kaydi restore etmek izlenebilirligi korur.

## Testte Ne Kontrol Edildi?

Ilk test, arsivli mevcut kaydin restore edildigini, guncellenen kaydin donduruldugunu, `status` alaninin degismedigini ve kaydin arsiv listesinden aktif listeye gectigini dogrular.

Ikinci test, olmayan `nonconformity_id` icin `None` dondugunu ve mevcut kaydin degismedigini dogrular.

## Kapsam Disi Birakilanlar

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

## Kisa Ozet

Adim 055 ile `NonconformityRepository` icinde arsivlenmis kaydi tekrar aktif hale getiren bellek ici restore davranisi eklendi.

Bu adim, kalite kayitlarini silmeden aktif ve arsiv durumlari arasinda yonetmek icin sade bir temel saglar.
