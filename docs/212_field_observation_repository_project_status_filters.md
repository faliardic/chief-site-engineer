# Step 212 - FieldObservationRepository Project and Status Filters

## Amac

Step 212, `FieldObservationRepository` icin en kucuk read-only gorunurluk katmanini ekler.

Bu adim yalniz iki filtre davranisi ekler:

- `list_by_project_id(project_id)`;
- `list_by_status(status)`.

Bu filtreler repository icindeki mevcut `FieldObservationRecord` nesnelerini degistirmez, kopyalamaz ve validate etmez. Yalniz verilen metin degeri ile record alanini birebir karsilastirir.

## Implemented Repository Methods

`app/records.py` icindeki `FieldObservationRepository` artik su iki method'u da saglar:

```python
def list_by_project_id(self, project_id: str) -> list[FieldObservationRecord]:
    return [record for record in self._records if record.project_id == project_id]

def list_by_status(self, status: str) -> list[FieldObservationRecord]:
    return [record for record in self._records if record.status == status]
```

## Davranis Sozlesmesi

| Davranis | Step 212 Karari |
| --- | --- |
| Project filter | `project_id` exact match |
| Status filter | `status` exact match |
| Case sensitivity | Buyuk/kucuk harf duyarlidir |
| Trim/normalize | Yapilmaz |
| Unknown/empty result | `[]` |
| Sira | Ekleme sirasi korunur |
| Donen liste | Her cagri yeni liste dondurur |
| Record object | Kopyalanmaz, mutate edilmez |
| Archived records | Eslesen archived record'lar da doner |
| Combined filtering | Eklenmedi |

## Focused Tests

`tests/test_records.py` icinde bes focused test eklendi:

1. `project_id` filtresinin exact match, insertion order ve unknown result davranisi;
2. `status` filtresinin `open`, `tracking`, `closed` ve unknown result davranisi;
3. project ve status filtrelerinin birbirinden bagimsiz calismasi;
4. donen filtered list mutate edilse bile repository storage'in degismemesi;
5. eslesen archived observation kaydinin filtrelerden dislanmamasi.

Focused test komutu:

```powershell
python -m pytest tests/test_records.py -k "field_observation_repository and (project or status or filtered or archived)"
```

## Explicit Non-Scope

Bu adim sunlari eklemez:

- category, location, reported_to, date-time, text-search, active/archive-only veya combined-query filtreleri;
- status update, close, reopen, archive, restore, delete veya bulk mutation servisleri;
- summary, count-by-status veya reporting;
- persistence, database, JSON veya SQLite;
- attachment linking, upload veya file operations;
- model validation, normalization, enum, constants veya `__post_init__`;
- API, GUI veya CLI;
- audit, task, NCR conversion, official decision veya generated `blocked`;
- daily export, weekly summary veya Step 213.

## Current Boundary

Field MVP tarafinda su an minimal observation model, bellek ici repository baseline'i ve read-only project/status gorunurlugu vardir. Daha genis filtreleme, lifecycle mutation, attachment integration, persistence ve raporlama ayri issue'larda ele alinmalidir.
