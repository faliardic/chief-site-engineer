# Step 214 - FieldObservationRepository Reporting Update

## Amac

Step 214, `FieldObservationRepository` icin en kucuk explicit reporting-context enrichment davranisini ekler: tek bir stored `FieldObservationRecord` kaydinin `reported_to` ve `reported_at` alanlarini `observation_id` ile bulup guncellemek.

Bu adim yalniz su method'u ekler:

```python
def update_reporting(
    self,
    observation_id: str,
    reported_to: str,
    reported_at: str,
) -> FieldObservationRecord | None:
    ...
```

## Implemented Repository Method

`app/records.py` icindeki `FieldObservationRepository` artik su method'u da saglar:

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

## Davranis Sozlesmesi

| Davranis | Step 214 Karari |
| --- | --- |
| Lookup | Existing `find_by_id(...)` davranisi kullanilir |
| Missing id | `None` dondurur |
| Found id | Stored record'un `reported_to` ve `reported_at` alanlari guncellenir |
| Return value | Ayni stored record nesnesi dondurulur |
| Supplied values | Trim, normalize, validate, map, parse veya convert edilmez |
| Contact lookup | Eklenmedi |
| Status | Otomatik degistirilmez |
| Other fields | Otomatik degistirilmez |
| Archived records | Explicit reporting update engellenmez |

## Focused Tests

`tests/test_records.py` icinde focused reporting update testleri eklendi:

1. missing `observation_id` icin `None` donmesi ve repository'nin degismemesi;
2. `reported_to` ve `reported_at` alanlarinin explicit olarak set edilmesi ve ayni record nesnesinin donmesi;
3. reporting update'in yalniz bu iki alani degistirmesi ve `status`, `closed_at`, notes, archive state ve diger degerleri korumasi;
4. coklu kayit icinde yalniz hedef record'un degismesi;
5. verilen string'lerin trim veya normalization olmadan aynen korunmasi;
6. archived record icin explicit reporting update'in engellenmemesi;
7. yeni/duplicate record olusmamasi ve repository count'un stabil kalmasi.

Focused test komutu:

```powershell
python -m pytest tests/test_records.py -k "field_observation_repository and reporting"
```

## Explicit Non-Scope

Bu adim sunlari eklemez:

- automatic status change to `tracking`;
- automatic/current-time generation;
- contact lookup, contact IDs, normalization, validation, constants, enums veya `__post_init__`;
- location, category, description, notes, creator, closed timestamp, status veya archive state update'i;
- reporting history, audit, task, NCR, notification veya decision creation;
- delete, bulk update, archive/restore, active filtering, combined query veya summaries;
- persistence, database, JSON veya SQLite;
- attachment linking, upload veya file operations;
- daily export veya weekly summary;
- API, GUI veya CLI;
- generated `blocked`;
- Step 215.

## Current Boundary

Field MVP tarafinda su an minimal observation model, bellek ici repository baseline'i, project/status filtreleri, explicit status update ve explicit reporting-context update vardir. Persistence, automatic lifecycle rules, contact normalization, attachment integration, broader filters/mutations, export/reporting consumers ve interfaces hala ayri issue gerektirir.
