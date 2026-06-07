# Adim 048 - Repository Status Guncelleme Ogrenim Notu

## Repository Icinde Guncelleme Davranisi

Repository sadece kayit eklemek, listelemek veya ozetlemek icin kullanilmaz. Bazen mevcut bir kaydin alanini guncellemek de gerekir.

Bu adimda `NonconformityRepository` icine `update_status` metodu eklendi.

## update_status Ne Ise Yarar?

`update_status(nonconformity_id, new_status)`, verilen NCR kimligine sahip kaydi bulur ve kaydin `status` alanini yeni degerle gunceller.

Kayit bulunursa guncellenen kayit dondurulur. Kayit bulunamazsa `None` dondurulur.

## Arama ve Guncelleme Mantigi

Metot once `find_by_id` benzeri arama mantigini kullanir:

```python
record = self.find_by_id(nonconformity_id)
if record is None:
    return None
record.status = new_status
return record
```

Bu yaklasim mevcut repository davranisina uyumludur.

## Bulunmayan Kayit Icin Neden None?

Repository icinde aranan kayit yoksa guncellenecek nesne de yoktur.

Bu durumda `None` dondurmek, `find_by_id` davranisiyla tutarlidir ve "kayit bulunamadi" bilgisini sade sekilde verir.

## Neden Otomatik Status History Uretilmedi?

Bu adim sadece status alanini bellek icinde gunceller.

Otomatik `NonconformityStatusHistoryRecord` uretmek daha genis is kurallari gerektirir: eski durum, degisiklik sebebi, degistiren kisi ve tarih gibi bilgiler gerekir. Bu nedenle bu adimda otomatik history kaydi olusturulmadi.

## Neden JSON veya SQLite Guncellemesi Degil?

Bu adimda JSON, SQLite veya baska bir kalici saklama katmani eklenmedi.

Bu nedenle guncelleme sadece Python nesnesi uzerinde, bellek icinde yapilir.

## Santiye Pratiginde Anlami

NCR kayitlari sahada durum degistirir:

```text
open -> in_progress -> verified -> closed
```

Bu ilerleyis, kalite takibinin temelidir. Ancak bu adim sadece mevcut durum degerini gunceller; resmi durum gecmisi veya onay akisi kurmaz.

## Testte Ne Kontrol Edildi?

Ilk test, mevcut kaydin `status` alaninin guncellendigini ve yeni durumun filtre/ozet davranislarina yansidigini dogrular.

Ikinci test, olmayan `nonconformity_id` icin `None` dondugunu ve mevcut kaydin degismedigini dogrular.

## Kapsam Disi Birakilanlar

- JSON
- SQLite
- API
- GUI
- CLI
- Dashboard
- Dosya islemi
- Otomatik is akisi
- Otomatik status history kaydi

## Kisa Ozet

Adim 048 ile `NonconformityRepository` icine bellek ici status guncelleme davranisi eklendi.

Bu adim, kesin uygunsuzluk kayitlarinin durumunu repository icinde guncelleyebilmek icin kucuk ama onemli bir temel saglar.
