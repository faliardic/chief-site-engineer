# Adim 051 - Repository Kayit Sayisi Ogrenim Notu

## Repository Icinde Sayma Davranisi

Repository sadece kayit eklemek, bulmak veya filtrelemek icin kullanilmaz. Bazen kayitlarin kac adet oldugunu bilmek gerekir.

Bu adimda `NonconformityRepository` icine `count` ve `count_by_status` metotlari eklendi.

## count Ne Ise Yarar?

`count()`, repository icindeki toplam `NonconformityRecord` sayisini dondurur.

Bos repository icin sonuc `0` olur.

## count_by_status Ne Ise Yarar?

`count_by_status(status)`, verilen `status` degerine sahip kayitlarin sayisini dondurur.

Ornegin:

```text
count_by_status("open") -> acik kayit sayisi
count_by_status("closed") -> kapali kayit sayisi
```

Eslesen kayit yoksa sonuc `0` olur.

## Sayma Mantigi

Toplam kayit sayisi icin Python'daki `len(...)` kullanilir:

```python
return len(self._records)
```

Status bazli sayim icin mevcut `list_by_status` davranisinin sonucu sayilir:

```python
return len(self.list_by_status(status))
```

Bu yaklasim mevcut filtreleme davranisiyla uyumludur.

## count_by_status ile list_by_status Arasindaki Fark

`list_by_status(status)` eslesen kayitlarin listesini dondurur.

`count_by_status(status)` ise eslesen kayitlarin kendisini degil, sadece adetini dondurur.

Listeye ihtiyac yoksa sayi dondurmek daha sade ve dogrudur.

## Eslesmeyen Kayit Icin Neden 0?

Sayma davranisinda eslesme yoksa "hic kayit yok" anlamina gelen `0` dondurmek dogaldir.

Bu, hata uretmeden rapor ve ozetlerde kullanilabilir bir sonuc verir.

## Neden JSON veya SQLite Sorgusu Degil?

Bu adimda kalici saklama katmani yoktur.

Kayitlar Python listesi icinde, bellek uzerinde tutulur. Bu nedenle sayma davranisi da simdilik bellek ici Python sayimi olarak kalir.

## Santiye Pratiginde Anlami

Santiye kalite takibinde toplam NCR sayisi, acik NCR sayisi ve kapali NCR sayisi yonetim icin temel gostergelerdir.

Bu sayilar, hangi konularin acik kaldigini ve kalite surecinin ne kadar ilerledigini hizlica gormeye yardim eder.

## Testte Ne Kontrol Edildi?

Ilk test, bos repository icin `count()` sonucunun `0` oldugunu ve kayit eklendikten sonra toplam kayit sayisinin dogru dondugunu dogrular.

Ikinci test, `count_by_status` davranisinin `open`, `closed` ve eslesmeyen status degerleri icin dogru sayilari dondurdugunu dogrular.

## Kapsam Disi Birakilanlar

- JSON
- SQLite
- API
- GUI
- CLI
- Dashboard
- Dosya islemi
- Silme
- Arsivleme
- Otomatik is akisi

## Kisa Ozet

Adim 051 ile `NonconformityRepository` icine toplam kayit sayisi ve status bazli kayit sayisi davranislari eklendi.

Bu adim, ileride rapor, dashboard ve AI soru-cevap sistemlerine veri hazirlayabilecek basit sayma temelini guclendirir.
