# Step 212 - FieldObservationRepository Project ve Status Filtreleri

## Bu Adimda Ne Yaptik?

Bu adimda `FieldObservationRepository` icine iki kucuk okuma fonksiyonu ekledik:

- `list_by_project_id(project_id)`;
- `list_by_status(status)`.

Bu fonksiyonlar yeni kayit olusturmaz, mevcut kaydi degistirmez, status'u validate etmez, metni trim etmez ve buyuk/kucuk harf duzeltmesi yapmaz. Sadece repository icindeki kayitlari okur ve birebir eslesenleri yeni bir liste icinde dondurur.

## Uygulama Kodu

`app/records.py` icindeki kod:

```python
def list_by_project_id(self, project_id: str) -> list[FieldObservationRecord]:
    return [record for record in self._records if record.project_id == project_id]

def list_by_status(self, status: str) -> list[FieldObservationRecord]:
    return [record for record in self._records if record.status == status]
```

## Kodun Satir Satir Aciklamasi

```python
def list_by_project_id(self, project_id: str) -> list[FieldObservationRecord]:
```

Bu satir repository icin yeni bir method tanimlar. `project_id` parametresi disaridan gelen arama degeridir. Donus tipi `list[FieldObservationRecord]` olarak yazildi; yani sonuc bir veya daha fazla saha gozlem kaydi iceren liste olur.

```python
return [record for record in self._records if record.project_id == project_id]
```

Bu satir bir list comprehension'dir. `self._records` icindeki her `record` gezilir. Sadece `record.project_id == project_id` kosulunu saglayan record'lar yeni listeye girer.

Buradaki `==` birebir karsilastirma yapar:

- `"prj-001"` ile `"prj-001"` eslesir;
- `"PRJ-001"` ile `"prj-001"` eslesmez;
- `" prj-001 "` ile `"prj-001"` eslesmez.

```python
def list_by_status(self, status: str) -> list[FieldObservationRecord]:
```

Bu satir status'a gore filtreleme method'unu tanimlar. `status` disaridan gelen arama degeridir.

```python
return [record for record in self._records if record.status == status]
```

Bu satir repository icindeki kayitlardan sadece `record.status` degeri verilen `status` ile birebir ayni olanlari dondurur. `open`, `tracking` ve `closed` degerleri bu adimda sadece metin olarak tutulur; enum, validation veya normalization eklenmez.

## Test Kodundan Ornekler

Project filter icin temel test fikri:

```python
first_record = _field_observation("obs-001", project_id="prj-001")
other_project_record = _field_observation("obs-002", project_id="prj-002")
second_record = _field_observation("obs-003", project_id="prj-001")

repository.add(first_record)
repository.add(other_project_record)
repository.add(second_record)

assert repository.list_by_project_id("prj-001") == [first_record, second_record]
```

Bu test sunu dogrular:

- `prj-001` kayitlari secilir;
- `prj-002` kaydi araya eklenmis olsa bile sonuc disinda kalir;
- sonuc sirasi repository'ye eklenme sirasini korur;
- record nesneleri ayni nesneler olarak doner.

Status filter icin temel test fikri:

```python
open_record = _field_observation("obs-001", status="open")
tracking_record = _field_observation("obs-002", status="tracking")
closed_record = _field_observation("obs-003", status="closed")

repository.add(open_record)
repository.add(tracking_record)
repository.add(closed_record)

assert repository.list_by_status("open") == [open_record]
assert repository.list_by_status("tracking") == [tracking_record]
assert repository.list_by_status("closed") == [closed_record]
```

Bu test `status` alaninin sadece okunarak filtrelendigini gosterir. Status gecis kurali, kapatma islemi veya validation eklenmez.

## Donen Liste Neden Yeni Liste?

Bu test davranisi ozellikle onemlidir:

```python
project_records = repository.list_by_project_id("prj-001")
project_records.clear()

assert repository.list_by_project_id("prj-001") == [first_record, second_record]
```

`project_records.clear()` disarida donen listeyi bosaltir. Eger repository kendi ic listesini direkt dondurseydi, bu islem storage'i da bozabilirdi. Biz filtre fonksiyonlarinda list comprehension kullandigimiz icin her cagri yeni liste uretir.

Ancak record nesneleri kopyalanmaz. Yani liste yeni listedir, ama icindeki `FieldObservationRecord` nesneleri repository'deki ayni nesnelerdir. Bu Step 210'daki `list_all()` sozlesmesiyle uyumludur.

## Teknik Karar Tablosu

| Karar | Neden |
| --- | --- |
| Exact match kullanildi | Repository behavior tahmin edilebilir ve test edilebilir kalsin diye |
| Case-sensitive davranis korundu | Gizli normalization ileride veri yorumunu degistirmesin diye |
| Trim yapilmadi | Kullanici girdisi temizleme isi repository filtre method'una karismasin diye |
| Her cagri yeni liste dondurur | Disaridan liste mutate edilince storage bozulmasin diye |
| Record nesneleri kopyalanmadi | Mevcut in-memory repository sozlesmesiyle uyumlu kalsin diye |
| Archived matching records dahil edildi | Bu method'lar active/archive filtresi degil, sadece project/status filtresi olsun diye |
| Combined filter eklenmedi | Step 212 kapsam disina cikmamak icin |

## Kod Calisma Akisi

1. Kullanici veya test repository olusturur.
2. `FieldObservationRecord` nesneleri `repository.add(record)` ile eklenir.
3. `list_by_project_id("prj-001")` cagrilirsa repository tum kayitlari sirayla gezer.
4. `record.project_id == "prj-001"` olanlari yeni listeye ekler.
5. Yeni liste dondurulur.
6. Ayni mantik `list_by_status("open")` icin `record.status == "open"` karsilastirmasiyla calisir.

## Sunu soyle yaptik ki...

Sunu soyle yaptik ki repository yavas yavas buyurken her adimin davranisi net kalsin:

- filtreleri sadece okuma fonksiyonu yaptik ki lifecycle update veya archive davranisi bu adima karismasin;
- birebir string karsilastirmasi kullandik ki hidden normalization olmasin;
- yeni liste dondurduk ki disaridan liste uzerinde yapilan degisiklik repository storage'ini bozmasin;
- archived kayitlari dislamadik ki bu fonksiyonlar active/archive filtresi gibi davranmasin;
- testleri dar tuttuk ki Step 212 yalniz project/status gorunurlugunu kanitlasin.

## Yeni Terimler

| Terim | Anlam |
| --- | --- |
| Read-only filter | Veriyi degistirmeden sadece okuyan ve eslesenleri donduren filtre |
| Exact match | Iki degerin birebir ayni olmasi |
| Case-sensitive | Buyuk/kucuk harf farkinin anlamli olmasi |
| List comprehension | Python'da bir koleksiyondan yeni liste uretmenin kisa yolu |
| Mutate | Bir nesneyi yerinde degistirmek |

## Bu Adimda Bilerek Yapmadiklarimiz

Bu adimda status validation, enum, combined query, active/archive-only filter, database, JSON persistence, attachment linking, API, GUI, CLI veya raporlama eklemedik. Bu sinir sayesinde repository'nin en kucuk okuma davranisini net sekilde test ettik.
