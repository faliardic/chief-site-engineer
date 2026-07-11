# Step 209 - FieldObservationRecord Model Implementation

## Amaç

Step 209, Step 208'de tanimlanan `FieldObservationRecord` contract'ini en kucuk production-code dilimiyle uygular.

Bu adim yalniz sunlari ekler:

- minimal `FieldObservationRecord` dataclass;
- dataclass'in required value, default value ve lifecycle status value holding davranisini dogrulayan focused testler;
- repository truth ve ogrenme kayitlari.

## Implemented Model

`app/models.py` icine mevcut dataclass stiline uygun olarak su model eklendi:

```python
@dataclass
class FieldObservationRecord:
    """Represents a fast official field observation for the first Field MVP."""

    observation_id: str
    project_id: str
    observed_at: str
    location: str
    category: str
    description: str
    status: str = "open"
    reported_to: str | None = None
    reported_at: str | None = None
    created_by: str | None = None
    closed_at: str | None = None
    notes: str | None = None
    is_archived: bool = False
```

## Required Capture Fields

The six initial capture fields have no defaults, so Python constructor usage requires them:

- `observation_id`
- `project_id`
- `observed_at`
- `location`
- `category`
- `description`

This preserves the Step 208 contract without adding custom validation.

## Defaults

| Field | Default |
| --- | --- |
| `status` | `"open"` |
| `reported_to` | `None` |
| `reported_at` | `None` |
| `created_by` | `None` |
| `closed_at` | `None` |
| `notes` | `None` |
| `is_archived` | `False` |

## Focused Tests

`tests/test_models.py` now includes focused tests for:

1. minimal construction storing required values and applying defaults;
2. optional/lifecycle fields being supplied and held unchanged;
3. documented lifecycle values `open`, `tracking`, and `closed` being stored without side effects or validation behavior.

The focused test command is:

```powershell
python -m pytest tests/test_models.py -k field_observation
```

## Explicit Non-Scope

This step does not add:

- `__post_init__`;
- enum or constants;
- hard validation or whitespace validation;
- date parsing;
- project/contact/location lookup;
- attachment creation or embedded attachment fields;
- repository, persistence, API, GUI, CLI;
- export/report generation;
- audit event, task creation, NCR conversion, decision generation, or `blocked` state;
- workflow or CI changes;
- Step 210.

## Current Boundary

`FieldObservationRecord` implementation has started only in this narrow dataclass/test scope.

Attachment linking, repository/persistence, export, reporting, API/GUI/CLI, audit, structured location/contact normalization and validation remain future work requiring separate authorized issues.
