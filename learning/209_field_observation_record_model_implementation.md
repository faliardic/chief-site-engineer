# Step 209 Learning - FieldObservationRecord Dataclass Implementasyonu

## Bu Adimda Ne Yaptik?

Step 208'de sadece `FieldObservationRecord` icin veri sozlesmesi yazmistik. Step 209'da bu sozlesmenin en kucuk production-code karsiligini ekledik.

Bu adimda iki ana dosya degisti:

- `app/models.py`: `FieldObservationRecord` dataclass'i eklendi.
- `tests/test_models.py`: bu dataclass icin focused testler eklendi.

## Sunu soyle yaptik ki...

Sunu soyle yaptik ki saha kaydi hizli kalsin:

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

Bu modelde ilk 6 alanin default degeri yok. Python dataclass bu alanlari constructor icin zorunlu kabul eder. Yani su kullanim gecerlidir:

```python
observation = FieldObservationRecord(
    observation_id="obs-001",
    project_id="prj-001",
    observed_at="2026-07-11T18:30:00",
    location="A Blok 2. Kat",
    category="quality",
    description="Kalip birlesiminde aciklik goruldu.",
)
```

Ama `reported_to` veya attachment gibi bilgiler ilk anda zorunlu degildir. Saha muhendisi once kaydi acar, sonra detay ekleyebilir.

## Kod Satir Satir Ne Yapiyor?

```python
@dataclass
class FieldObservationRecord:
```

`@dataclass`, Python'in otomatik `__init__`, `__repr__` ve field saklama davranisi uretmesini saglar. Bu projede basit domain modelleri icin mevcut stil budur.

```python
observation_id: str
project_id: str
observed_at: str
location: str
category: str
description: str
```

Bu alanlar required alanlardir. Default degerleri olmadigi icin model olusturulurken verilmelidir.

```python
status: str = "open"
```

`status` verilmezse otomatik `"open"` olur. Bu, yeni saha gozleminin varsayilan olarak acik baslamasini saglar.

```python
reported_to: str | None = None
reported_at: str | None = None
created_by: str | None = None
closed_at: str | None = None
notes: str | None = None
```

Bu alanlar opsiyoneldir. `str | None`, alanin ya metin ya da `None` olabilecegini anlatir.

```python
is_archived: bool = False
```

Kayit varsayilan olarak arsivlenmemistir. `closed` olmak ile `is_archived=True` olmak ayni sey degildir.

## Neden Validation Eklenmedi?

Issue #34 acikca hard validation, enum, `__post_init__`, whitespace validation, date parsing ve lookup davranislarini yasakladi.

Bu yuzden model su anda degerleri oldugu gibi tutar:

```python
observation = FieldObservationRecord(
    observation_id="obs-003",
    project_id="prj-001",
    observed_at="2026-07-11T19:00:00",
    location="C Blok",
    category="progress",
    description="Gunluk saha gozlem kaydi.",
    status="closed",
)

assert observation.status == "closed"
```

Bu test status'u kabul/ret mekanizmasi gibi yorumlamaz; sadece verilen degerin saklandigini kanitlar.

## Testler Neyi Dogruluyor?

### 1. Minimal construction ve defaultlar

```python
def test_field_observation_record_holds_required_values_and_defaults() -> None:
    observation = FieldObservationRecord(
        observation_id="obs-001",
        project_id="prj-001",
        observed_at="2026-07-11T18:30:00",
        location="A Blok 2. Kat",
        category="quality",
        description="Kalip birlesiminde aciklik goruldu.",
    )

    assert observation.status == "open"
    assert observation.reported_to is None
    assert observation.is_archived is False
```

Bu test, sadece required alanlarla model olusturuldugunda defaultlarin dogru geldigini gosterir.

### 2. Opsiyonel alanlar

```python
def test_field_observation_record_holds_optional_lifecycle_values() -> None:
    observation = FieldObservationRecord(
        observation_id="obs-002",
        project_id="prj-001",
        observed_at="2026-07-11T18:45:00",
        location="B Blok Saha Girisi",
        category="coordination",
        description="Malzeme istif alani icin koordinasyon notu.",
        status="tracking",
        reported_to="Saha formeni",
        is_archived=True,
    )

    assert observation.status == "tracking"
    assert observation.reported_to == "Saha formeni"
    assert observation.is_archived is True
```

Bu test, opsiyonel alanlar verildiginde modelin bunlari degistirmeden sakladigini gosterir.

### 3. Lifecycle status degerleri

```python
def test_field_observation_record_holds_documented_status_values() -> None:
    for status in ("open", "tracking", "closed"):
        observation = FieldObservationRecord(
            observation_id=f"obs-{status}",
            project_id="prj-001",
            observed_at="2026-07-11T19:00:00",
            location="C Blok",
            category="progress",
            description="Gunluk saha gozlem kaydi.",
            status=status,
        )

        assert observation.status == status
```

Bu test validation testi degildir. Sadece contract'ta yazan uc lifecycle degerinin yan etki olmadan tutuldugunu kanitlar.

## Teknik Karar Tablosu

| Karar | Neden |
| --- | --- |
| Model `@dataclass` olarak eklendi | Projedeki basit model stili ile uyumlu. |
| `__post_init__` eklenmedi | Issue #34 validation ve normalizasyonu kapsam disi tuttu. |
| Status enum eklenmedi | Bu adim value-holding odakli; hard vocabulary enforcement yok. |
| Attachment field eklenmedi | Attachment `FileAttachmentRecord` ile ayri baglanacak, record icine gomulmeyecek. |
| Repository/persistence eklenmedi | Bu adim sadece model ve test dilimi. |
| Testler rejection beklemiyor | Issue #34 validation expectation yasakladi. |

## Kod Calisma Akisi

```text
Saha gozlemi fark edilir
-> FieldObservationRecord required alanlarla olusturulur
-> status default olarak open olur
-> reported_to / notes / closed_at gibi alanlar gerekirse sonradan model olustururken verilebilir
-> attachment, export, repository ve audit islemleri bu adimda yoktur
```

## Sonuc

Step 209, Field MVP yolunda ilk production-code dilimidir. Ama bu dilim bilincli olarak kucuk tutuldu: sadece dataclass ve focused testler. Boylece sonraki adimlarda attachment, repository, persistence veya export gibi daha riskli davranislar ayri ayri ve testli sekilde ele alinabilir.
