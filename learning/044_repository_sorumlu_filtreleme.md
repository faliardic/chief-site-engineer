# Adim 044 - Repository Sorumlu Filtreleme Ogrenim Notu

## Repository Icinde Sorumlu Kisiye Gore Filtreleme

Repository, kayitlari sadece durum veya kimlige gore degil, sorumlu tarafa gore de listeleyebilir.

Bu adimda `NonconformityRepository` icine `list_by_responsible_party` metodu eklendi.

## list_by_responsible_party Ne Ise Yarar?

`list_by_responsible_party(responsible_party)`, repository icindeki `NonconformityRecord` kayitlarini `responsible_party` alanina gore filtreler.

Ornegin:

```python
repository.list_by_responsible_party("Ahmet")
repository.list_by_responsible_party("Mehmet")
```

Bu sayede belirli bir kisi, ekip veya firmanin sorumlulugundaki NCR kayitlari ayri listelenebilir.

## Filtreleme Mantigi

Metot liste comprehension kullanir:

```python
return [
    record
    for record in self._records
    if record.responsible_party == responsible_party
]
```

Bu ifade repository icindeki kayitlari sirayla gezer ve sadece istenen `responsible_party` degerine sahip olanlari yeni bir listeye alir.

## Eslesmeyen Kayitlarda Neden Bos Liste?

Bir sorumlu tarafa ait kayit bulunmamasi hata degildir.

Ornegin repository icinde `Ayse` sorumlulugunda kayit yoksa sonuc dogal olarak bos listedir:

```python
[]
```

Bu, "bu sorumlu icin kayit yok" bilgisini sade sekilde verir.

## Neden Veritabani Sorgusu Degil?

Bu adimda JSON, SQLite veya baska bir kalici saklama katmani eklenmedi.

Bu nedenle `list_by_responsible_party`, veritabani sorgusu degil, bellek icinde Python listesi uzerinde calisan basit bir filtreleme davranisidir.

## Santiye Pratiginde Anlami

Sahada NCR kayitlarini sorumlu kisi, ekip veya firmaya gore ayri gormek takip disiplinini guclendirir.

Bir santiye sefi "Ahmet'in uzerinde hangi NCR kayitlari var?" veya "Mehmet hangi uygunsuzluklari takip ediyor?" sorularini hizli cevaplamak ister.

Bu adim, bu ihtiyacin repository seviyesindeki baslangicidir.

## Testte Ne Kontrol Edildi?

Testte ayni repository icine `Ahmet` ve `Mehmet` sorumlulugunda kayitlar eklendi.

Sonra:

- `list_by_responsible_party("Ahmet")` sadece Ahmet kayitlarini dondurdu.
- `list_by_responsible_party("Mehmet")` sadece Mehmet kaydini dondurdu.
- `list_by_responsible_party("Ayse")` bos liste dondurdu.

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

Adim 044 ile `NonconformityRepository` icine sorumlu tarafa gore filtreleme davranisi eklendi.

Bu adim, kesin uygunsuzluk kayitlarini bellek icinde kisi, ekip veya firma sorumluluguna gore ayri okumayi mumkun hale getirir.
