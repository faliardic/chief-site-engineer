# Adim 056 - Uygunsuzluk Arsiv Ozeti Ogrenim Notu

## Repository Icinde Arsiv Ozeti

Repository icinde kayitlari aktif ve arsiv olarak ayirmak tek basina yeterli olmayabilir. Bazen bu gruplarin kac kayit icerdigini tek bakista gormek gerekir.

Bu adimda `NonconformityRepository` icine `get_archive_summary` metodu eklendi.

## get_archive_summary Ne Ise Yarar?

`get_archive_summary()`, repository icindeki NCR kayitlarini arsiv durumuna gore sayar.

Dondurdugu sozluk uc anahtar icerir:

```python
{
    "active": 3,
    "archived": 2,
    "total": 5,
}
```

## Sayma Mantigi

`active`, `is_archived == False` olan kayitlarin sayisidir.

`archived`, `is_archived == True` olan kayitlarin sayisidir.

`total`, repository icindeki toplam kayit sayisidir.

Metot mevcut `list_active`, `list_archived` ve `count` davranislarina dayanir. Bu sayede ayni arsiv mantigi tekrar yazilmaz.

## Bos Repository Icin Neden Sifirli Dict?

Repository bos olsa bile ozetin anahtarlari ayni kalir:

```python
{
    "active": 0,
    "archived": 0,
    "total": 0,
}
```

Bu, rapor veya dashboard tarafinda ozetin daha kolay okunmasini saglar.

## Archive ve Restore Sonrasi Nasil Guncellenir?

`archive` bir kaydin `is_archived` alanini `True` yapar. Bu durumda `archived` sayisi artar ve `active` sayisi azalir.

`restore` bir kaydin `is_archived` alanini `False` yapar. Bu durumda `active` sayisi artar ve `archived` sayisi azalir.

Her iki durumda da `total` degismez, cunku kayit silinmez.

## Neden JSON veya SQLite Degil?

Bu adimda kalici saklama katmani yoktur.

Kayitlar Python listesi icinde, bellek uzerinde tutulur. Bu nedenle arsiv ozeti simdilik bellek ici Python sayimi olarak kalir.

## Santiye Pratiginde Anlami

Santiye kalite takibinde kac NCR kaydinin aktif takipte, kacinin arsivde oldugunu bilmek onemlidir.

Bu bilgi, kalite arsivinin buyuklugunu ve guncel takip yukunu ayirmaya yardim eder.

## Testte Ne Kontrol Edildi?

Ilk test, bos repository icin tum sayilarin `0` dondugunu dogrular.

Ikinci test, aktif ve arsivlenmis kayitlarin dogru sayildigini dogrular.

Ucuncu test, restore sonrasi `active` sayisinin arttigini, `archived` sayisinin azaldigini ve `total` sayisinin degismedigini dogrular.

## Kapsam Disi Birakilanlar

- Kayit silme
- JSON
- SQLite
- API
- GUI
- CLI
- Dashboard
- Dosya islemi
- Otomatik history
- Otomatik workflow
- Otomatik status degisimi

## Kisa Ozet

Adim 056 ile `NonconformityRepository`, aktif, arsivlenmis ve toplam NCR kayit sayilarini tek sozlukte donduren bellek ici arsiv ozeti davranisi kazandi.

Bu adim, arsivleme ve restore davranislarinin sayisal etkisini takip etmek icin sade bir temel saglar.
