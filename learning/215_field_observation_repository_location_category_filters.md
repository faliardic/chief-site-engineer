# Step 215 Ogrenme Notu - Location ve Category Filter

## Amac

Bu adimda `FieldObservationRepository` icine iki yeni okuma method'u ekledik:

- `list_by_location(location)`
- `list_by_category(category)`

Bu method'lar sahadaki gozlem kayitlarini konuma veya kategoriye gore gormeyi saglar. Ornegin "A Blok 2. Kat" icin tum gozlemleri veya "quality" kategorisindeki kayitlari listeleyebiliriz.

## Degisen Dosyalar

| Dosya | Ne yapildi? | Neden? |
| --- | --- | --- |
| `app/records.py` | `list_by_location` ve `list_by_category` eklendi | Repository icinde read-only location/category gorunurlugu icin |
| `tests/test_records.py` | 7 focused test eklendi | Exact match, yeni liste, archived kayit ve no-mutation davranislarini kilitlemek icin |
| `docs/215_field_observation_repository_location_category_filters.md` | Davranis sozlesmesi yazildi | Gelecekte scope genislemesini engellemek icin |
| `.cse/state/project_state.json` | Repository truth guncellendi | Step 214 merged, Step 215 active ayrimini kaydetmek icin |

## Production Code

Eklenen kod:

```python
def list_by_location(self, location: str) -> list[FieldObservationRecord]:
    return [record for record in self._records if record.location == location]

def list_by_category(self, category: str) -> list[FieldObservationRecord]:
    return [record for record in self._records if record.category == category]
```

## Satir Satir Aciklama

```python
def list_by_location(self, location: str) -> list[FieldObservationRecord]:
```

Bu satir repository class'i icinde yeni bir method tanimlar. Method disaridan bir `location` string'i alir ve sonuc olarak `FieldObservationRecord` nesnelerinden olusan bir liste dondurur.

```python
return [record for record in self._records if record.location == location]
```

Bu satir bir list comprehension kullanir. `self._records` icindeki her `record` tek tek okunur. Sadece `record.location == location` olan kayitlar yeni listeye eklenir.

Burada onemli nokta sudur: `==` exact string equality kullanir. Yani `"A Blok 2. Kat"` ile `"A BLOK 2. KAT"` ayni sayilmaz. `"A Blok 2. Kat"` ile `"A Blok 2. Kat "` da ayni sayilmaz.

```python
def list_by_category(self, category: str) -> list[FieldObservationRecord]:
```

Bu satir kategori filtresi icin ayni sekilde yeni bir method tanimlar.

```python
return [record for record in self._records if record.category == category]
```

Bu satir yalniz `record.category == category` olan kayitlari dondurur. Kategori normalize edilmez, kucuk harfe cevrilmez, bosluklari trim edilmez.

## Test Kodu Ornegi

Location filtresi icin ornek test:

```python
first_record = _field_observation("obs-001", location="A Blok 2. Kat")
other_location_record = _field_observation("obs-002", location="B Blok Zemin")
second_record = _field_observation("obs-003", location="A Blok 2. Kat")

repository.add(first_record)
repository.add(other_location_record)
repository.add(second_record)

assert repository.list_by_location("A Blok 2. Kat") == [
    first_record,
    second_record,
]
```

Bu test sunu dogrular:

1. `first_record` ve `second_record` ayni location degerine sahiptir.
2. `other_location_record` farkli location degerine sahiptir.
3. Repository ekleme sirasini korur.
4. Sonuc yeni liste olsa da icindeki nesneler stored record nesnelerinin aynisidir.

Category filtresi icin ornek test:

```python
first_record = _field_observation("obs-001", category="quality")
other_category_record = _field_observation("obs-002", category="safety")
second_record = _field_observation("obs-003", category="quality")

repository.add(first_record)
repository.add(other_category_record)
repository.add(second_record)

assert repository.list_by_category("quality") == [first_record, second_record]
```

Bu test de ayni mantigi kategori alanina uygular.

## Teknik Karar Tablosu

| Karar | Secilen yol | Neden? |
| --- | --- | --- |
| Match sekli | Exact string equality | V1 hizli kayit snapshot alanlarini oldugu gibi okumak icin |
| Case sensitivity | Korundu | Kullanici verisini sessizce degistirmemek icin |
| Trim/normalize | Yapilmadi | Gizli veri donusumu eklememek icin |
| Donen liste | Yeni liste | Disaridan liste mutate edilirse repository storage bozulmasin diye |
| Record nesnesi | Ayni stored object | Mevcut in-memory repository davranisi ile uyumlu olsun diye |
| Archived kayitlar | Dahil | Archive/active filtering bu adimin kapsami degil |
| Combined filter | Eklenmedi | Step 215 yalniz iki dar read-only filtre olsun diye |

## Kod Calisma Akisi

1. Kullanici veya test `repository.list_by_location("A Blok 2. Kat")` cagirir.
2. Repository, `self._records` listesindeki kayitlari sirayla okur.
3. Her kayit icin `record.location == "A Blok 2. Kat"` kontrol edilir.
4. Eslesen kayitlar yeni bir listeye eklenir.
5. Yeni liste dondurulur.
6. Repository icindeki `_records` listesi degismez.
7. Record alanlari degismez.

Kategori filtresi ayni akisla calisir; tek fark `record.category` alaninin okunmasidir.

## Sunu soyle yaptik ki...

Sunu soyle yaptik ki, saha kayitlarini konum ve kategoriye gore gorebilelim ama henuz urunu karmasik bir sorgu motoruna cevirmeyelim.

Sunu soyle yaptik ki, `"quality"` ile `"Quality"` arasinda sessiz normalizasyon olmasin. Cunku bu asamada repository sadece veriyi oldugu gibi saklayan ve okuyan sade bir bellek ici katmandir.

Sunu soyle yaptik ki, filtre sonucundaki liste disarida temizlense veya degistirilse bile repository icindeki gercek kayit listesi bozulmasin.

Sunu soyle yaptik ki, archived kayitlar beklenmedik sekilde kaybolmasin. Archive gorunurlugu daha sonra ayri active/archive filtresi ile ele alinmalidir.

## Yeni Terimler

| Terim | Anlam |
| --- | --- |
| Exact string equality | Iki metnin karakter karakter ayni olmasi |
| Case-sensitive | Buyuk/kucuk harf farkinin onemli olmasi |
| Normalize etmek | Veriyi ortak formata donusturmek, ornegin kucuk harfe cevirmek veya bosluklari temizlemek |
| Read-only filter | Kayitlari degistirmeden yalniz eslesenleri donduren method |
| List comprehension | Python'da bir listeden kosula gore yeni liste uretme yazim bicimi |

## Bilincli Olarak Eklenmeyenler

- Combined query yok.
- Location normalization yok.
- Category enum veya constants yok.
- Active/archive-only filter yok.
- Persistence yok.
- API, GUI veya CLI yok.
- Podcast 033 yok.
- Step 216 yok.
