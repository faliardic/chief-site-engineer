# Step 215 - FieldObservationRepository Location and Category Filters

## Amac

Step 215, `FieldObservationRepository` icin iki dar read-only gorunurluk davranisi ekler:

- `list_by_location(location)`;
- `list_by_category(category)`.

Bu adim, Steps 211-215 Field MVP dilimini location/category gorunurlugu ile kapatir. Davranis yalniz bellek ici repository kayitlarini okur; record'lari degistirmez, kopyalamaz, normalize etmez ve validation eklemez.

## Implemented Repository Methods

`app/records.py` icindeki `FieldObservationRepository` artik su iki method'u da saglar:

```python
def list_by_location(self, location: str) -> list[FieldObservationRecord]:
    return [record for record in self._records if record.location == location]

def list_by_category(self, category: str) -> list[FieldObservationRecord]:
    return [record for record in self._records if record.category == category]
```

## Davranis Sozlesmesi

| Davranis | Step 215 Karari |
| --- | --- |
| Location filter | `location` exact match |
| Category filter | `category` exact match |
| Case sensitivity | Buyuk/kucuk harf duyarlidir |
| Trim/normalize | Yapilmaz |
| Parse/map/tokenize | Yapilmaz |
| Validation | Eklenmedi |
| Unknown/empty result | `[]` |
| Sira | Ekleme sirasi korunur |
| Donen liste | Her cagri yeni liste dondurur |
| Record object | Kopyalanmaz, mutate edilmez |
| Archived records | Eslesen archived record'lar da doner |
| Filter independence | Location, category, project ve status filtreleri birbirinden bagimsizdir |
| Combined filtering | Eklenmedi |

## Focused Tests

`tests/test_records.py` icinde yedi focused test eklendi:

1. `list_by_location(...)` exact match, insertion order, unknown, case-different ve whitespace-different davranisi;
2. `list_by_category(...)` exact match, insertion order, unknown, case-different ve whitespace-different davranisi;
3. location, category, project ve status filtrelerinin birbirinden bagimsiz kalmasi;
4. donen location/category filtered listelerin yeni liste olmasi ve dis liste mutation'inin repository storage'i degistirmemesi;
5. eslesen archived observation kayitlarinin location/category filtrelerinden dislanmamasi;
6. bos repository icin location/category filtrelerinin `[]` dondurmesi;
7. filtreleme sirasinda record kopyasi, record mutation'i, yeni record, silme, archive degisikligi veya status degisikligi olmamasi.

Focused test komutu:

```powershell
python -m pytest tests/test_records.py -k "field_observation_repository and (location or category)"
```

## Explicit Non-Scope

Bu adim sunlari eklemez:

- structured `SiteLocationRecord` lookup veya relationship resolution;
- category constants, enums, canonical vocabulary, normalization, validation veya `__post_init__`;
- partial, fuzzy, contains, prefix, regex veya text search;
- `reported_to`, date/time, creator, active/archive-only, notes veya description filtreleri;
- combined query builder, filter object, pagination, sorting, grouping, count veya summary;
- location/category veya baska alan update'i;
- close/reopen rules, automatic lifecycle behavior veya timestamp;
- audit/history/task/NCR/notification/decision generation;
- persistence, database, JSON veya SQLite;
- attachment linking, upload veya file operations;
- daily export veya weekly summary;
- API, GUI veya CLI;
- generated `blocked`;
- Podcast 033 veya Step 216.

## Current Boundary

Field MVP tarafinda su an minimal observation model, bellek ici repository baseline'i, read-only project/status/location/category filtreleri, explicit status update ve explicit reporting-context update vardir.

Persistence, structured location/contact normalization, attachment integration, automatic lifecycle rules, broader filters/mutations, export/reporting consumers ve interfaces hala ayri issue gerektirir.
