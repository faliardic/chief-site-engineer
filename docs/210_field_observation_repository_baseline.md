# Step 210 - FieldObservationRepository Baseline

## Amac

Step 210, Step 209'da merge edilen `FieldObservationRecord` modeli icin en kucuk bellek ici repository temelini ekler.

Bu adim yalniz sunlari ekler:

- `FieldObservationRepository` class'i;
- `add`, `list_all`, `count` ve `find_by_id` repository davranislari;
- duplicate `observation_id` reddi;
- `list_all()` ic koleksiyonu koruyan liste kopyasi davranisi;
- focused repository testleri ve repository truth kayitlari.

## Implemented Repository

`app/records.py` icine mevcut `NonconformityRepository` stiline yakin su repository eklendi:

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

## Davranis Sozlesmesi

| Davranis | Step 210 Karari |
| --- | --- |
| Storage | Sadece bellek ici liste |
| Identity | `observation_id` |
| Duplicate id | `ValueError` |
| Listeleme | Ekleme sirasini korur |
| `list_all()` | Yeni liste kopyasi dondurur |
| Record object | Kopyalanmaz ve mutate edilmez |
| Missing lookup | `None` |

## Focused Tests

`tests/test_records.py` icindeki focused repository testleri sunlari dogrular:

1. yeni repository bos baslar, count `0` olur, olmayan id lookup `None` dondurur;
2. eklenen record'lar insertion order ile listelenir, count artar, `find_by_id` eklenen record nesnesini dondurur;
3. duplicate `observation_id` reddedilir, farkli id kabul edilir;
4. `list_all()` ile donen listeyi mutate etmek repository'nin ic listesini degistirmez.

Focused test komutu:

```powershell
python -m pytest tests/test_records.py -k field_observation_repository
```

## Explicit Non-Scope

Bu adim sunlari eklemez:

- filters;
- lifecycle updates;
- archive, restore, delete veya bulk operations;
- summaries veya reporting;
- database, JSON, SQLite veya baska persistence;
- attachment linking veya file operations;
- `FieldObservationRecord` icinde validation/normalization;
- API, GUI veya CLI;
- audit, task, NCR conversion, automatic decision generation veya generated `blocked`;
- daily export veya weekly summary;
- Step 211 veya Podcast 032.

## Current Boundary

`FieldObservationRecord` halen tek Field-MVP model implementasyonudur.

`FieldObservationRepository` yalniz baseline-level bellek ici repository'dir. Daha ileri davranislar ayri issue ve ayri dogrulama gerektirir.
