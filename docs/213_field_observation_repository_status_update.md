# Step 213 - FieldObservationRepository Status Update

## Amac

Step 213, `FieldObservationRepository` icin en kucuk explicit lifecycle mutation davranisini ekler: tek bir stored `FieldObservationRecord` kaydinin `status` alanini `observation_id` ile bulup guncellemek.

Bu adim yalniz su method'u ekler:

```python
def update_status(
    self,
    observation_id: str,
    new_status: str,
) -> FieldObservationRecord | None:
    ...
```

## Implemented Repository Method

`app/records.py` icindeki `FieldObservationRepository` artik su method'u da saglar:

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

## Davranis Sozlesmesi

| Davranis | Step 213 Karari |
| --- | --- |
| Lookup | Existing `find_by_id(...)` davranisi kullanilir |
| Missing id | `None` dondurur |
| Found id | Stored record'un `status` alani `new_status` olur |
| Return value | Ayni stored record nesnesi dondurulur |
| Status value | Trim, normalize, validate, map veya convert edilmez |
| Constants/enums | Eklenmedi |
| `closed_at` | Otomatik set edilmez |
| Other fields | Otomatik degistirilmez |
| Filters | `list_by_status(...)` guncel stored status'u hemen gorur |
| Archived records | Explicit status update engellenmez |

## Focused Tests

`tests/test_records.py` icinde focused status update testleri eklendi:

1. missing `observation_id` icin `None` donmesi ve repository'nin degismemesi;
2. `open -> tracking` guncellemesinin ayni record nesnesini dondurmesi;
3. `tracking -> closed` guncellemesinin `closed_at` veya diger alanlari otomatik degistirmemesi;
4. coklu kayit icinde yalniz hedef record'un degismesi;
5. `list_by_status(...)` sonucunun status update'i hemen yansitmasi ve yeni/duplicate record olusmamasi;
6. archived record icin explicit status update'in engellenmemesi.

Focused test komutu:

```powershell
python -m pytest tests/test_records.py -k "field_observation_repository and status"
```

## Explicit Non-Scope

Bu adim sunlari eklemez:

- `close(...)`, `reopen(...)`, transition-rule, allowed-transition veya workflow-engine helper;
- otomatik `closed_at`, `reported_at`, audit, history, task, NCR, notification veya decision creation;
- status validation, constants, enums, normalization veya `__post_init__`;
- location, category, description, `reported_to`, notes, archive state veya baska alan update'i;
- delete, bulk update, archive/restore, active filtering, combined query veya summaries;
- persistence, database, JSON veya SQLite;
- attachment linking, upload veya file operations;
- daily export veya weekly summary;
- API, GUI veya CLI;
- generated `blocked`;
- Step 214.

## Current Boundary

Field MVP tarafinda su an minimal observation model, bellek ici repository baseline'i, read-only project/status filtreleri ve tek explicit status mutation operation vardir. Otomatik lifecycle kurallari, timestamp set etme, validation, attachment integration, persistence, broader mutation servisleri ve raporlama hala ayri issue gerektirir.
