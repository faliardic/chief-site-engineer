# Adim 218 - FileAttachmentRepository Related-Record Filtrelerini Ogrenmek

Bu adimda `FileAttachmentRepository` icine iki read-only filtre ekledik:

- `list_by_related_record_type(related_record_type)`
- `list_by_related_record_id(related_record_id)`

Ama amacimiz sadece iki method eklemek degildi. Bu adim, Python'da bellek ici
liste uzerinden sade filtre yazmayi, exact string karsilastirmasini, yeni liste
dondurmeyi ve stored object referanslarini korumayi da gosterir.

## Hangi Dosyada Ne Yaptik?

| Dosya | Ne yapildi? | Neden yapildi? |
| --- | --- | --- |
| `app/records.py` | `FileAttachmentRepository` icine iki filtre methodu eklendi. | Dosya eki metadata kayitlarini bagli kayit tipi veya id'sine gore okuyabilmek icin. |
| `tests/test_records.py` | Related-record filtreleri icin focused testler eklendi. | Exact match, siralama, yeni liste, object referansi ve regresyon davranislarini kilitlemek icin. |
| `docs/218_file_attachment_repository_related_record_filters.md` | Kapsam ve davranis sozlesmesi belgelendi. | Gelecekte bu methodlarin attachment entegrasyonu sanilmamasi icin. |
| `.cse/state/project_state.json`, `README.md`, `ROADMAP.md`, `CHANGELOG.md`, `docs/project_decisions.md`, `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md` | Proje durumu Step 218'e gore guncellendi. | Repo truth, test seviyesi ve kapsam siniri ayni dili konussun diye. |

## Eklenen Kod

`app/records.py` icindeki yeni methodlardan biri sudur:

```python
def list_by_related_record_type(
    self,
    related_record_type: str,
) -> list[FileAttachmentRecord]:
    return [
        record
        for record in self._records
        if record.related_record_type == related_record_type
    ]
```

Satir satir bakalim:

```python
def list_by_related_record_type(
```

Bu satir, repository icinde yeni bir method baslatir. Method adi, neye gore
listeleme yaptigini acik soyler: `related_record_type`.

```python
    self,
```

`self`, sinifin kendi nesnesidir. Bu method repository'nin icindeki `_records`
listesine bu sayede erisir.

```python
    related_record_type: str,
```

Disaridan aranacak kayit tipi string olarak alinir. Ornek: `"field_observation"`
veya `"nonconformity"`.

```python
) -> list[FileAttachmentRecord]:
```

Methodun `FileAttachmentRecord` nesnelerinden olusan bir liste dondurecegini
anlatir. Bu bir type hint'tir; Python'a ve okuyucuya niyetimizi gosterir.

```python
    return [
```

Sonucu dogrudan yeni bir liste olarak donduruyoruz.

```python
        record
        for record in self._records
```

Repository icindeki her kaydi tek tek geziyoruz. `record`, o an incelenen
`FileAttachmentRecord` nesnesidir.

```python
        if record.related_record_type == related_record_type
```

Yalniz `related_record_type` alani disaridan verilen degerle bire bir ayni olan
kayitlari listeye aliyoruz.

```python
    ]
```

List comprehension burada biter. Python bu ifadeden yeni bir liste uretir.

Ikinci method ayni fikri `related_record_id` icin uygular:

```python
def list_by_related_record_id(
    self,
    related_record_id: str,
) -> list[FileAttachmentRecord]:
    return [
        record
        for record in self._records
        if record.related_record_id == related_record_id
    ]
```

## Sunu Soyle Yaptik Ki...

Sunu soyle yaptik ki repository sade kalsin:

```python
if record.related_record_type == related_record_type
```

Burada `==` kullandik. `lower()`, `strip()`, mapping, enum veya validation
eklemedik. Boylece `"field_observation"`, `"Field_Observation"` ve
`" field_observation "` ayni kabul edilmez.

Sunu soyle yaptik ki filtreler birbirine karismasin:

```python
repository.list_by_related_record_type("field_observation")
repository.list_by_related_record_id("obs-001")
```

Type filtresi sadece `related_record_type` alanina bakar. Id filtresi sadece
`related_record_id` alanina bakar. Type filtresi id'yi, id filtresi type'i
kontrol etmez.

Sunu soyle yaptik ki disaridan donen liste bozulsa bile repository bozulmasin:

```python
listed_records = repository.list_by_related_record_type("field_observation")
listed_records.clear()
```

`clear()` donen listeyi bosaltir. Ama bu liste repository'nin kendi `_records`
listesi degildir. Method her cagrida yeni liste urettigi icin repository ic
durumu korunur.

Sunu soyle yaptik ki metadata nesneleri kopyalanmasin:

```python
assert result[0] is record
```

`is`, iki degiskenin ayni nesneyi gosterip gostermedigini kontrol eder.
Bu adimda kayit kopyasi uretmiyoruz; repository'de saklanan nesnenin kendisini
liste icinde donduruyoruz.

## Test Kodunu Okuyalim

Bir testin kucuk hali soyledir:

```python
def test_file_attachment_repository_related_record_type_filter_exact_matches_in_order() -> None:
    repository = FileAttachmentRepository()
    first = _file_attachment(
        "att-001",
        related_record_type="field_observation",
        related_record_id="obs-001",
    )
    second = _file_attachment(
        "att-002",
        related_record_type="field_observation",
        related_record_id="obs-002",
    )

    repository.add(first)
    repository.add(second)

    assert repository.list_by_related_record_type("field_observation") == [
        first,
        second,
    ]
```

Bu test sunlari dogrular:

- Repository bos baslar.
- Iki attachment metadata kaydi eklenir.
- Ikisi de ayni `related_record_type` degerine sahiptir.
- Filtre sonucu ekleme sirasini korur.
- Sonuc yeni bir liste olsa da icindeki nesneler ayni record nesneleridir.

Case-sensitive davranisi icin su fikir test edilir:

```python
repository.list_by_related_record_type("field_observation")
repository.list_by_related_record_type("Field_Observation")
```

Bu iki cagri ayni sonucu vermemelidir. Cunku Python string karsilastirmasinda
`"field_observation" == "Field_Observation"` sonucu `False` olur.

Whitespace davranisi icin su fikir test edilir:

```python
repository.list_by_related_record_id("NCR-001")
repository.list_by_related_record_id("NCR-001 ")
```

Sonda bir bosluk varsa bu artik farkli bir string'dir. Method otomatik `strip()`
yapmadigi icin eslesme olmaz.

## Teknik Karar Tablosu

| Karar | Secilen davranis | Neden |
| --- | --- | --- |
| Filtre tipi | Iki ayri method | Type ve id filtreleri bagimsiz kalsin. |
| Karsilastirma | Exact string equality | Veri oldugu gibi okunsun; gizli normalizasyon olmasin. |
| Harf duyarliligi | Case-sensitive | Stored metadata degeri neyse o esas alinsin. |
| Bosluk davranisi | Trim yok | Kullanici veya upstream veri hatasi sessizce saklanmasin. |
| Donus tipi | Yeni liste | Disaridan liste mutasyonu repository icini bozmasin. |
| Nesne davranisi | Ayni stored object | Metadata kopyalama/mutasyon yapilmasin. |
| Bagli record kontrolu | Yok | Bu adim sadece attachment metadata repository filtresidir. |
| Combined filtre | Yok | Kapsam buyumesin; gerekirse ayri adimda tasarlanir. |

## Kod Calisma Akisi

1. `FileAttachmentRepository()` ile bos repository olusturulur.
2. `repository.add(record)` ile `FileAttachmentRecord` nesneleri `_records`
   listesine eklenir.
3. `list_by_related_record_type("field_observation")` cagrilirsa repository
   `_records` listesini bastan sona gezer.
4. Her kaydin `related_record_type` alani verilen string ile bire bir
   karsilastirilir.
5. Eslesenler yeni bir listeye alinir.
6. Liste dondurulur.
7. Repository'nin `_records` listesi, kayit sirasi ve metadata alanlari
   degismez.

`list_by_related_record_id(...)` icin akis aynidir; sadece bakilan alan
`related_record_id` olur.

## Yeni Terimler

**Read-only filter**: Kayitlari sadece okuyan, veri eklemeyen, silmeyen veya
degistirmeyen filtre davranisi.

**Exact string equality**: Iki string'in karakter karakter tamamen ayni olmasi.
Buyuk/kucuk harf ve bosluk farklari eslesmeyi bozar.

**Case-sensitive**: Buyuk ve kucuk harfin farkli kabul edilmesi.

**List comprehension**: Python'da bir listeyi gezip kosula uyan elemanlardan
yeni liste olusturmanin kisa yolu.

**Insertion order**: Kayitlar hangi sirayla eklendiyse listelemede o sirayla
gelmesi.

**Object reference**: Bir degiskenin nesnenin kopyasini degil, bellekteki ayni
nesneyi gostermesi.

**Mutation**: Bir nesnenin veya listenin ic durumunu degistirmek.

**Combined query**: Birden fazla kosulu ayni anda uygulayan sorgu. Bu adimda
bilerek eklenmedi.

## Bu Adimdan Sonra Ne Henuz Yok?

Bu adim, attachment metadata icin sadece iki basit filtre ekledi. Henuz sunlar
yok:

- Dosyanin diskte var olup olmadigini kontrol etmek.
- Dosya upload/download yapmak.
- Dosya yolu uretmek veya normalize etmek.
- Bagli `FieldObservationRecord` veya `NonconformityRecord` nesnesini bulmak.
- Type ve id'yi ayni anda filtreleyen combined query.
- API, GUI, CLI veya database.

Bu sinir iyi bir seydir. Kucuk ve testli ilerleyince, ileride attachment
entegrasyonu eklenirken hangi parcanin zaten guvenilir oldugunu net biliriz.
