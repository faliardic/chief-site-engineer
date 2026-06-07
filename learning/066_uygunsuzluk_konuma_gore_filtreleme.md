# Adim 066 - Uygunsuzluk Konuma Gore Filtreleme

## Bu Adimda Ne Ogrenildi?

Bu adimda repository icinde `location` degerine gore liste filtreleme davranisi eklendi.

`list_by_location(location)` methodu, verilen konum degeriyle eslesen `NonconformityRecord` kayitlarini dondurur.

## Read-Only Davranis

`list_by_location(location)` salt okuma davranisidir.

Bu method:

- Kayit silmez.
- `location` alanini degistirmez.
- `status` alanini degistirmez.
- `is_archived` alanini degistirmez.
- Otomatik history olusturmaz.
- Otomatik workflow baslatmaz.

## Liste Filtreleme Mantigi

Repository icindeki kayitlar bellek icinde bir listede tutulur. Konuma gore filtreleme, bu liste uzerinde kosul kontrolu yapar.

Temel mantik sudur:

```python
return [record for record in self._records if record.location == location]
```

Bu ifade sadece konumu eslesen kayitlardan yeni bir liste olusturur.

## Bos Liste Neden Dogru?

Repository bos olabilir veya aranan konumla eslesen kayit olmayabilir.

Bu durumda methodun bos liste dondurmesi beklenir:

```python
[]
```

Bos liste, "bu konumda kayit yok" anlamina gelir.

## Arsivlenmis Kayitlar Neden Dahil?

Konum bilgisi aktif kayitlar kadar arsivlenmis kayitlar icin de onemlidir.

Bir kayit arsivlenmis olsa bile belirli bir blok veya mahalde yasanmis kalite problemini temsil eder. Bu nedenle konum filtresi arsivlenmis kayitlari varsayilan olarak dislamaz.

## Python Ogrenme Acisindan Ders

Bu adim su konulari pekistirir:

- Liste comprehension
- Alan degerine gore filtreleme
- Read-only method tasarimi
- Bos liste donusu
- Arsiv durumu ile filtreleme kosulunu ayri tutma

## Santiye Pratigindeki Anlami

Sahada kalite problemleri genellikle konumla birlikte anlam kazanir.

"A Blok", "3. Kat", "Kuzey cephe" veya benzeri alanlarda tekrar eden sorunlar olabilir. Konuma gore filtreleme, bu tekrar eden problemleri fark etmek icin temel repository davranisidir.
