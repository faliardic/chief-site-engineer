# Step 214 - FieldObservationRepository Reporting Update

## Bu Adimda Ne Yaptik?

Bu adimda `FieldObservationRepository` icine tek bir reporting-context update method'u ekledik:

```python
def update_reporting(
    self,
    observation_id: str,
    reported_to: str,
    reported_at: str,
) -> FieldObservationRecord | None:
    record = self.find_by_id(observation_id)
    if record is None:
        return None
    record.reported_to = reported_to
    record.reported_at = reported_at
    return record
```

Bu method, repository icinde zaten saklanan bir `FieldObservationRecord` nesnesini bulur ve sadece `reported_to` ile `reported_at` alanlarini degistirir.

## Kodun Satir Satir Aciklamasi

```python
def update_reporting(
    self,
    observation_id: str,
    reported_to: str,
    reported_at: str,
) -> FieldObservationRecord | None:
```

Bu satirlar repository icinde yeni bir method tanimlar. `observation_id`, hangi kaydin guncellenecegini belirtir. `reported_to`, bildirilen kisi/grup metnidir. `reported_at`, bildirim zamani metnidir. Donus tipi `FieldObservationRecord | None` oldugu icin method ya kaydi dondurur ya da kayit yoksa `None` dondurur.

```python
record = self.find_by_id(observation_id)
```

Burada mevcut lookup davranisini kullandik. Yeni arama algoritmasi yazmadik; repository identity sozlesmesi `find_by_id(...)` uzerinden devam eder.

```python
if record is None:
    return None
```

Verilen id yoksa method hicbir kaydi degistirmez ve `None` dondurur.

```python
record.reported_to = reported_to
record.reported_at = reported_at
```

Kayit varsa sadece iki reporting alani degisir. `status`, `closed_at`, `notes`, `created_by`, `is_archived` veya baska bir alan otomatik degismez.

```python
return record
```

Method ayni stored record nesnesini dondurur. Yeni record olusturulmaz, kopya uretilmez.

## Test Kodundan Ornekler

Reporting context set etme:

```python
record = _field_observation("obs-001")
repository.add(record)

result = repository.update_reporting(
    "obs-001",
    "Kontrol Muhendisi",
    "2026-07-11T20:05:00",
)

assert result is record
assert record.reported_to == "Kontrol Muhendisi"
assert record.reported_at == "2026-07-11T20:05:00"
```

`result is record`, method'un ayni stored object'i dondurdugunu kanitlar.

Yan etki olmamasi:

```python
record = _field_observation("obs-001", status="closed", is_archived=True)
record.closed_at = "2026-07-11T20:10:00"
record.notes = "Existing official note."
record.created_by = "fatih"
repository.add(record)

result = repository.update_reporting(
    "obs-001",
    "Kalite ekibi",
    "2026-07-11T20:15:00",
)

assert result is record
assert record.status == "closed"
assert record.closed_at == "2026-07-11T20:10:00"
assert record.notes == "Existing official note."
assert record.created_by == "fatih"
assert record.is_archived is True
```

Bu test reporting update'in status veya lifecycle alanlarini gizlice degistirmedigini gosterir.

Exact string koruma:

```python
result = repository.update_reporting(
    "obs-001",
    "  Kontrol Ekibi  ",
    " 2026-07-11T20:25:00 ",
)

assert result is record
assert record.reported_to == "  Kontrol Ekibi  "
assert record.reported_at == " 2026-07-11T20:25:00 "
```

Bu test trim, normalize, parse veya convert yapilmadigini kanitlar.

## Teknik Karar Tablosu

| Karar | Neden |
| --- | --- |
| `find_by_id(...)` kullanildi | Lookup davranisi tek yerde kalsin diye |
| Missing id icin `None` | Mevcut repository update pattern'iyle uyumlu olsun diye |
| Ayni record nesnesi donduruldu | In-memory repository davranisi acik kalsin diye |
| Yalniz iki reporting alani degisti | Step 214 kapsam disina cikmamak icin |
| Status otomatik degismedi | Bildirmek ile takip status'una almak ayri urun karari gerektirir diye |
| Timestamp uretilmedi | Zaman degeri kullanicidan explicit gelsin diye |
| Contact lookup eklenmedi | Contact normalization ayri model ve test ister diye |
| Archived record engellenmedi | Archive gating bu adimin kapsami degil diye |

## Kod Calisma Akisi

1. Repository icinde kayitlar `self._records` listesinde tutulur.
2. Kullanici veya test `update_reporting("obs-001", "Saha sefi", "2026-07-11T20:35:00")` cagirir.
3. Method `find_by_id("obs-001")` ile stored record'u arar.
4. Kayit yoksa `None` dondurur.
5. Kayit varsa `reported_to` ve `reported_at` alanlarini verilen string'lerle degistirir.
6. Ayni record nesnesini dondurur.
7. Repository count degismez, yeni record olusmaz.

## Sunu soyle yaptik ki...

Sunu soyle yaptik ki saha gozlemini kime ve ne zaman bildirdigimizi kaydedebilelim, ama bunu daha buyuk lifecycle veya contact sistemine cevirmeyelim:

- status'u otomatik `tracking` yapmadik ki bildirim ve takip karari ayri kalsin;
- current time uretmedik ki bu method sadece verilen degeri yazsin;
- contact lookup eklemedik ki ilerideki contact normalization tasarimini kilitlemeyelim;
- sadece iki alan degistirdik ki repository mutation davranisi kucuk ve testli kalsin;
- archived kaydi engellemedik ki archive access policy ayri adimda tasarlanabilsin.

## Yeni Terimler

| Terim | Anlam |
| --- | --- |
| Reporting context | Bir kaydin kime ve ne zaman bildirildigini anlatan alanlar |
| Enrichment | Mevcut kayda yeni bilgi ekleme veya mevcut bilgi alanlarini doldurma |
| Contact lookup | Metin olarak verilen kisiyi sistemdeki contact kaydiyla eslestirme islemi |
| Normalization | Farkli yazimlari tek standart deger haline getirme |
| Stable count | Update isleminden sonra repository'deki kayit sayisinin degismemesi |

## Bu Adimda Bilerek Yapmadiklarimiz

Bu adimda automatic status change, current-time generation, contact lookup, validation, enum, audit/history/task/NCR/notification/decision creation, persistence, API, GUI, CLI veya Step 215 eklemedik. Sadece stored observation kaydinin `reported_to` ve `reported_at` alanlarini explicit olarak guncelledik.
