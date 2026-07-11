# Step 213 - FieldObservationRepository Status Update

## Bu Adimda Ne Yaptik?

Bu adimda `FieldObservationRepository` icine tek bir guncelleme method'u ekledik:

```python
def update_status(
    self,
    observation_id: str,
    new_status: str,
) -> FieldObservationRecord | None:
    record = self.find_by_id(observation_id)
    if record is None:
        return None
    record.status = new_status
    return record
```

Bu method, repository icinde zaten saklanan bir `FieldObservationRecord` nesnesini bulur ve sadece `status` alanini degistirir.

## Kodun Satir Satir Aciklamasi

```python
def update_status(
    self,
    observation_id: str,
    new_status: str,
) -> FieldObservationRecord | None:
```

Bu satirlar repository icinde yeni bir method tanimlar. `observation_id`, hangi kaydin guncellenecegini belirtir. `new_status`, kayda yazilacak yeni status metnidir. Donus tipi `FieldObservationRecord | None` oldugu icin method ya kaydi dondurur ya da kayit yoksa `None` dondurur.

```python
record = self.find_by_id(observation_id)
```

Burada yeni arama mantigi yazmadik. Mevcut `find_by_id(...)` davranisini kullandik. Bu, repository icindeki identity lookup sozlesmesini tek yerde tutar.

```python
if record is None:
    return None
```

Eger verilen `observation_id` repository icinde yoksa method hicbir kaydi degistirmez ve `None` dondurur.

```python
record.status = new_status
```

Kayit varsa sadece `status` alani degistirilir. Bu satir bir mutation'dir: var olan nesnenin icindeki alan yerinde degisir.

```python
return record
```

Method ayni stored record nesnesini dondurur. Yeni `FieldObservationRecord` olusturulmaz, kopya uretilmez.

## Test Kodundan Ornekler

Open kaydin tracking'e gecmesi:

```python
record = _field_observation("obs-001", status="open")
repository.add(record)

result = repository.update_status("obs-001", "tracking")

assert result is record
assert record.status == "tracking"
```

Burada `result is record` onemlidir. `==` deger esitligini, `is` ise ayni nesne olup olmadigini kontrol eder. Repository ayni stored nesneyi dondurdugu icin filtreler ve lookup ayni status degisimini gorur.

Closed status'a gecerken otomatik yan etki olmamasi:

```python
record = _field_observation("obs-001", status="tracking")
record.reported_at = "2026-07-11T19:00:00"
record.notes = "Reported to site team."
repository.add(record)

result = repository.update_status("obs-001", "closed")

assert result is record
assert record.status == "closed"
assert record.closed_at is None
assert record.reported_at == "2026-07-11T19:00:00"
assert record.notes == "Reported to site team."
```

Bu test, `status = "closed"` yazmanin otomatik `closed_at` timestamp'i uretmedigini ve baska alanlara dokunmadigini kanitlar.

Status filtresinin update'i hemen gormesi:

```python
repository.update_status("obs-001", "tracking")

assert repository.list_by_status("open") == []
assert repository.list_by_status("tracking") == [record, existing_tracking_record]
assert repository.count() == 2
```

`list_by_status(...)`, repository icindeki ayni record nesnelerini okudugu icin status update sonucunu hemen gorur. Yeni record olusmadigi icin count degismez.

## Teknik Karar Tablosu

| Karar | Neden |
| --- | --- |
| `find_by_id(...)` kullanildi | Identity lookup tek sozlesmede kalsin diye |
| Missing id icin `None` | Mevcut repository update pattern'iyle uyumlu olsun diye |
| Ayni record nesnesi donduruldu | In-memory repository davranisi acik ve test edilebilir kalsin diye |
| Sadece `status` degistirildi | Step 213 kapsam disina cikmamak icin |
| Status validate edilmedi | Step 209 value-holding ve Step 212 exact string davranisi korunuyor diye |
| `closed_at` otomatik set edilmedi | Lifecycle timestamp kurali ayri tasarim ve test ister diye |
| Archived record engellenmedi | Archive gating bu adimin kapsami degil diye |

## Kod Calisma Akisi

1. Repository icinde kayitlar `self._records` listesinde tutulur.
2. Kullanici veya test `update_status("obs-001", "tracking")` cagirir.
3. Method `find_by_id("obs-001")` ile stored record'u arar.
4. Kayit yoksa `None` dondurur.
5. Kayit varsa `record.status` alanina yeni string degeri yazar.
6. Ayni record nesnesini dondurur.
7. `list_by_status(...)`, sonraki cagrida ayni nesneyi okudugu icin guncel status'u gorur.

## Sunu soyle yaptik ki...

Sunu soyle yaptik ki status lifecycle icin ilk mutation davranisi kucuk, okunabilir ve testli kalsin:

- yeni workflow engine yazmadik ki guncelleme kurallari karismasin;
- `closed_at` otomatik set etmedik ki timestamp politikasini aceleyle gizli davranisa cevirmeyelim;
- validation veya enum eklemedik ki mevcut dataclass value-holding sozlesmesini bozmayalim;
- archived kaydi engellemedik ki archive policy ayri adimda tasarlanabilsin;
- status filtresiyle birlikte test ettik ki repository'nin ayni stored record nesnelerini okudugu gorunsun.

## Yeni Terimler

| Terim | Anlam |
| --- | --- |
| Mutation | Var olan nesnenin bir alanini yerinde degistirmek |
| Stored record | Repository icinde saklanan record nesnesi |
| Same object | Python'da `is` ile kontrol edilen ayni nesne kimligi |
| Side effect | Asil hedef disinda baska alan veya sistem davranisinin degismesi |
| Lifecycle mutation | Bir kaydin surec durumunu degistiren update islemi |

## Bu Adimda Bilerek Yapmadiklarimiz

Bu adimda `close(...)`, `reopen(...)`, allowed transition kurallari, status validation, enum, otomatik timestamp, audit event, history, task/NCR uretimi, persistence, API, GUI, CLI veya Step 214 eklemedik. Sadece repository icindeki tek record'un `status` alanini explicit olarak guncelledik.
