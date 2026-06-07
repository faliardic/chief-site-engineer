# Adim 043 - Repository Durum Filtreleme Ogrenim Notu

## Repository Icinde Filtreleme Davranisi

Repository sadece kayit eklemek ve bulmak icin degil, kayitlari belirli kosullara gore listelemek icin de kullanilabilir.

Bu adimda `NonconformityRepository` icine `list_by_status` metodu eklendi.

## list_by_status Ne Ise Yarar?

`list_by_status(status)`, repository icindeki `NonconformityRecord` kayitlarini `status` alanina gore filtreler.

Ornegin:

```python
repository.list_by_status("open")
repository.list_by_status("closed")
```

Bu sayede acik ve kapali NCR kayitlari ayri listeler halinde okunabilir.

## Filtreleme Mantigi

Metot liste comprehension kullanir:

```python
return [record for record in self._records if record.status == status]
```

Bu ifade repository icindeki kayitlari sirayla gezer ve sadece istenen `status` degerine sahip olanlari yeni bir listeye alir.

## Eslesmeyen Kayitlarda Neden Bos Liste?

Bir filtreleme isleminde eslesen kayit bulunmamasi hata degildir.

Ornegin repository icinde `in_review` durumunda kayit yoksa sonuc dogal olarak bos listedir:

```python
[]
```

Bu, kullanicinin "bu durumda kayit yok" bilgisini sade sekilde almasini saglar.

## Neden Veritabani Sorgusu Degil?

Bu adimda JSON, SQLite veya baska bir kalici saklama katmani eklenmedi.

Bu nedenle `list_by_status`, veritabani sorgusu degil, bellek icinde Python listesi uzerinde calisan basit bir filtreleme davranisidir.

## Santiye Pratiginde Anlami

Sahada acik NCR kayitlari ile kapanmis NCR kayitlarini ayni listede okumak takip zorlugu olusturur.

Santiye sefi veya kalite ekibi acik, devam eden ve kapanmis kayitlari ayri gormek ister. Bu adim, bu ayrimin yazilim tarafindaki baslangicidir.

## Testte Ne Kontrol Edildi?

Testte ayni repository icine `open` ve `closed` durumunda kayitlar eklendi.

Sonra:

- `list_by_status("open")` sadece acik kayitlari dondurdu.
- `list_by_status("closed")` sadece kapali kaydi dondurdu.
- `list_by_status("in_review")` bos liste dondurdu.

## Kapsam Disi Birakilanlar

- JSON
- SQLite
- API
- GUI
- CLI
- Dosya islemi
- Dashboard
- Otomatik is akisi

## Kisa Ozet

Adim 043 ile `NonconformityRepository` icine durum filtreleme davranisi eklendi.

Bu adim, kesin uygunsuzluk kayitlarini bellek icinde durumlarina gore ayri okumayi mumkun hale getirir.
