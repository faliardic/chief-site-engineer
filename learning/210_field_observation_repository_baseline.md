# Step 210 - FieldObservationRepository Baseline Ogrenme Notu

## Bu Adimda Ne Yaptik?

Step 210'da `FieldObservationRecord` icin cok kucuk bir repository katmani ekledik.

Repository, kayitlari simdilik sadece Python listesinin icinde tutar. Database, JSON dosyasi, SQLite, API, GUI veya attachment baglantisi yoktur.

## Eklenen Kod

`app/records.py` icindeki yeni repository:

```python
class FieldObservationRepository:
    """Stores field observation records in memory."""

    def __init__(self) -> None:
        self._records: list[FieldObservationRecord] = []

    def add(self, record: FieldObservationRecord) -> None:
        if self.find_by_id(record.observation_id) is not None:
            raise ValueError(
                f"FieldObservationRecord with id '{record.observation_id}' already exists."
            )
        self._records.append(record)

    def list_all(self) -> list[FieldObservationRecord]:
        return list(self._records)

    def count(self) -> int:
        return len(self._records)

    def find_by_id(self, observation_id: str) -> FieldObservationRecord | None:
        for record in self._records:
            if record.observation_id == observation_id:
                return record
        return None
```

## Satir Satir Aciklama

```python
class FieldObservationRepository:
```

Yeni bir class tanimliyoruz. Bu class'in sorumlulugu `FieldObservationRecord` nesnelerini bellek icinde tutmak.

```python
    """Stores field observation records in memory."""
```

Bu docstring, class'in ne yaptigini kisa anlatir: saha gozlem kayitlarini bellek icinde saklar.

```python
    def __init__(self) -> None:
        self._records: list[FieldObservationRecord] = []
```

`__init__`, repository nesnesi olustugunda calisir.

`self._records` repository'nin ic listesidir.

Baslangicta liste bostur.

Basindaki `_`, bu listenin class'in ic detayi oldugunu anlatir. Dis kod bu listeyle dogrudan oynamamalidir.

```python
    def add(self, record: FieldObservationRecord) -> None:
```

`add`, yeni bir `FieldObservationRecord` ekler.

Parametre tipi `FieldObservationRecord` olarak yazildi. Bu, Python'a ve kodu okuyan kisiye bu metoda hangi tur nesne verilmesi gerektigini soyler.

```python
        if self.find_by_id(record.observation_id) is not None:
```

Eklenecek record'un `observation_id` degeriyle daha once kayit var mi diye bakiyoruz.

`find_by_id(...)` bir record bulursa record'u dondurur. Bulamazsa `None` dondurur.

Bu yuzden `is not None`, "bu id zaten var" anlamina gelir.

```python
            raise ValueError(
                f"FieldObservationRecord with id '{record.observation_id}' already exists."
            )
```

Ayni `observation_id` ikinci kez eklenmeye calisilirsa hata uretiriz.

`ValueError`, verilen degerin bu repository icin uygun olmadigini anlatan standart Python exception'idir.

```python
        self._records.append(record)
```

Duplicate yoksa record ic listeye eklenir.

Burada record nesnesini kopyalamiyoruz veya degistirmiyoruz. Ayni nesne listeye girer.

```python
    def list_all(self) -> list[FieldObservationRecord]:
        return list(self._records)
```

`list_all`, tum kayitlari dondurur.

`return self._records` deseydik dis kod repository'nin ic listesini dogrudan degistirebilirdi.

`list(self._records)` yeni bir liste kopyasi olusturur. Listenin kendisi kopyadir; icindeki record nesneleri ayni nesnelerdir.

```python
    def count(self) -> int:
        return len(self._records)
```

`count`, repository icinde kac record oldugunu dondurur.

`len(...)`, Python'da liste uzunlugunu verir.

```python
    def find_by_id(self, observation_id: str) -> FieldObservationRecord | None:
```

`find_by_id`, verilen `observation_id` ile kayit arar.

Donus tipi `FieldObservationRecord | None` olarak yazildi. Yani bulursa record, bulamazsa `None`.

```python
        for record in self._records:
            if record.observation_id == observation_id:
                return record
        return None
```

Liste icinde sirayla gezeriz.

Ilk eslesen `observation_id` bulunursa record'u dondururuz.

Hic eslesme yoksa dongu biter ve `None` dondurulur.

## Test Kodu Ne Yapiyor?

Testlerde once küçük bir helper kullandik:

```python
def _field_observation(observation_id: str) -> FieldObservationRecord:
    return FieldObservationRecord(
        observation_id=observation_id,
        project_id="prj-001",
        observed_at="2026-07-11T18:30:00",
        location="A Blok 2. Kat",
        category="quality",
        description=f"Field observation {observation_id}",
    )
```

Bu helper, testlerde tekrar tekrar `FieldObservationRecord` yazmamizi engeller.

Her test sadece ihtiyaci olan `observation_id` degerini degistirir.

### Bos Repository Testi

```python
def test_field_observation_repository_starts_empty() -> None:
    repository = FieldObservationRepository()

    assert repository.list_all() == []
    assert repository.count() == 0
    assert repository.find_by_id("obs-missing") is None
```

Bu test sunu dogrular:

- yeni repository bos liste dondurur;
- count `0` olur;
- olmayan id icin `None` dondurulur.

### Add/List/Count/Find Testi

```python
def test_field_observation_repository_adds_lists_counts_and_finds_records() -> None:
    repository = FieldObservationRepository()
    first_record = _field_observation("obs-001")
    second_record = _field_observation("obs-002")

    repository.add(first_record)
    repository.add(second_record)

    assert repository.list_all() == [first_record, second_record]
    assert repository.count() == 2
    assert repository.find_by_id("obs-001") == first_record
    assert repository.find_by_id("obs-002") == second_record
    assert repository.find_by_id("obs-999") is None
```

Bu test sunu dogrular:

- ekleme sirasi korunur;
- count iki record icin `2` olur;
- var olan id'ler ilgili record'u dondurur;
- olmayan id `None` dondurur.

### Duplicate Id Testi

```python
def test_field_observation_repository_rejects_duplicate_id_and_accepts_different_ids() -> None:
    repository = FieldObservationRepository()
    first_record = _field_observation("obs-001")
    duplicate_record = _field_observation("obs-001")
    different_record = _field_observation("obs-002")

    repository.add(first_record)

    with pytest.raises(ValueError, match="obs-001"):
        repository.add(duplicate_record)

    repository.add(different_record)

    assert repository.list_all() == [first_record, different_record]
    assert repository.count() == 2
```

Bu test iki seyi birlikte dogrular:

- ayni `observation_id` ikinci kez eklenemez;
- farkli `observation_id` normal sekilde eklenebilir.

`pytest.raises(...)`, belirli bir hata bekledigimizi soyler.

### Liste Kopyasi Testi

```python
def test_field_observation_repository_list_all_returns_copy() -> None:
    repository = FieldObservationRepository()
    record = _field_observation("obs-001")
    repository.add(record)

    listed_records = repository.list_all()
    listed_records.clear()

    assert repository.list_all() == [record]
    assert repository.count() == 1
```

Bu testte `list_all()` ile aldigimiz listeyi disarida temizliyoruz.

Eger repository ic listesini dogrudan dondurseydi, `clear()` repository'nin icini de bosaltirdi.

Test sonucunda repository hala record'u tutuyorsa `list_all()` guvenli liste kopyasi donduruyor demektir.

## Teknik Karar Tablosu

| Konu | Karar | Neden |
| --- | --- | --- |
| Storage | Bellek ici liste | En kucuk repository baseline'i icin yeterli |
| Duplicate kontrol | `observation_id` ile | `FieldObservationRecord` icin kimlik alani bu |
| Duplicate davranisi | `ValueError` | Mevcut repository stiline yakin ve test etmesi net |
| `list_all()` donusu | Yeni liste | Dis kodun ic koleksiyonu bozmasini engeller |
| Record kopyalama | Yapilmadi | Bu adim storage baseline; object lifecycle henuz kapsamda degil |
| Persistence | Eklenmedi | Database/JSON/SQLite ayri risk ve ayri task gerektirir |
| Filters/update/archive | Eklenmedi | Step 210 sadece baseline repository davranisi |

## Kod Calisma Akisi

1. Kullanici veya test `FieldObservationRepository()` olusturur.
2. `__init__` bos `_records` listesini hazirlar.
3. `add(record)` cagrilir.
4. `add`, once `find_by_id(record.observation_id)` ile duplicate kontrol eder.
5. Id yoksa record listeye eklenir.
6. `list_all()` cagrilirsa repository yeni bir liste dondurur.
7. `count()` cagrilirsa listenin uzunlugu dondurulur.
8. `find_by_id(...)` cagrilirsa id eslesen record veya `None` dondurulur.

## Yeni Terimler

| Terim | Anlam |
| --- | --- |
| Repository | Kayitlari saklama ve bulma davranisini bir class icinde toplayan katman |
| In-memory | Verinin sadece program calisirken RAM/bellek icinde tutulmasi |
| Duplicate id | Ayni kimlik degerinin ikinci kez eklenmeye calisilmasi |
| Internal collection | Class'in kendi icinde tuttugu liste gibi veri yapisi |
| List copy | Ayni elemanlari iceren ama kendisi yeni olan liste |

## Sunu soyle yaptik ki...

Sunu soyle yaptik ki `FieldObservationRecord` icin hemen database veya API gibi buyuk bir yapi kurmadan, once en temel kayit ekleme ve bulma davranisini guvenilir hale getirelim.

Sunu soyle yaptik ki `list_all()` dis kod tarafindan yanlislikla temizlense bile repository'nin kendi ic listesi bozulmasin.

Sunu soyle yaptik ki duplicate `observation_id` ileride raporlama, attachment linking veya persistence eklenmeden once erken fark edilsin.

Sunu soyle yaptik ki Step 210, Field MVP yonunde ilerlesin ama persistence, attachment, export, GUI/API ve audit gibi daha riskli katmanlari aceleyle karistirmasin.

## Kapsam Disi Kalanlar

Bu adimda su ozellikleri bilerek eklemedik:

- filters;
- lifecycle update;
- archive/restore/delete;
- database, JSON veya SQLite persistence;
- attachment linking;
- validation/normalization;
- API, GUI veya CLI;
- audit;
- daily export ve weekly summary;
- Podcast 032.
