# Adim 118 - Audit Event Target Record Pair Validation

## Bu adimda ne yaptik?

Bu adimda `AuditEventRecord.target_record_type` ve `target_record_id` alanlari icin pair validation ekledik.

Bu validation, target record iliskisinin tek tarafli kalmasini engeller.

## Neden yaptik?

Audit event bir kayda baglaniyorsa hem kayit turunu hem de kayit kimligini bilmelidir.

Sadece kayit turu varsa hangi kaydin hedef oldugu bilinmez. Sadece kayit id varsa bu kimligin hangi kayit turune ait oldugu bilinmez.

Bu nedenle iki alan birlikte ele alindi.

## Dokunulan dosyalar

```text
app/models.py
tests/test_models.py
docs/118_audit_event_target_record_pair_validation.md
learning/118_audit_event_target_record_pair_validation.md
CHANGELOG.md
ROADMAP.md
docs/project_decisions.md
docs/117_audit_event_target_record_iliski_kurallari.md
learning/GLOSSARY.md
```

`app/models.py`: Pair validation eklendi.

`tests/test_models.py`: Tek tarafli target record referansi icin iki test eklendi.

Dokumantasyon ve learning dosyalari karar ve ogrenme kaydi icin guncellendi.

## Pair validation nedir?

Pair validation, iki alanin birlikte anlamli kullanilip kullanilmadigini kontrol eder.

Bu adimda pair olan alanlar:

```text
target_record_type
target_record_id
```

## Neden `target_record_type` ve `target_record_id` birlikte ele alinir?

`target_record_type`, hedef kaydin turunu soyler.

`target_record_id`, hedef kaydin kimligini soyler.

Bu iki bilgi birlikte anlamlidir. Biri olmadan digeri eksik kalir.

## Gecerli / gecersiz durum tablosu

| `target_record_type` | `target_record_id` | Sonuc | Neden |
| --- | --- | --- | --- |
| `None` | `None` | Gecerli | Olay genel proje/sistem/surec olayi olabilir |
| `project_record` | `REC-2026-0007` | Gecerli | Olay belirli bir kayda baglanir |
| `project_record` | `None` | Gecersiz | Kayit turu var ama kimlik yok |
| `None` | `REC-2026-0007` | Gecersiz | Kimlik var ama kayit turu yok |
| `""` | `""` | Gecerli | Bu adim yalnizca `None` bazli validation yapar |

## Gercek `__post_init__` kod blogu

```python
def __post_init__(self) -> None:
    required_fields = (
        "event_id",
        "project_id",
        "event_type",
        "actor",
        "occurred_at",
    )
    for field_name in required_fields:
        value = getattr(self, field_name)
        if value is None or not value.strip():
            raise ValueError(f"{field_name} is required")

    if self.event_type not in AUDIT_EVENT_TYPE_SET:
        raise ValueError("event_type is not supported")

    target_type_is_set = self.target_record_type is not None
    target_id_is_set = self.target_record_id is not None
    if target_type_is_set != target_id_is_set:
        raise ValueError(
            "target_record_type and target_record_id must be provided together"
        )
```

Bu kodda pair validation required field ve event type validation sonrasinda calisir.

## Gercek test kodu blogu

```python
def test_audit_event_record_rejects_target_record_type_without_id() -> None:
    values = _valid_audit_event_kwargs()
    values["target_record_type"] = "project_record"

    with pytest.raises(
        ValueError,
        match="target_record_type and target_record_id must be provided together",
    ):
        AuditEventRecord(**values)
```

## Testlerin satir satir aciklamasi

- `values = _valid_audit_event_kwargs()` gecerli audit event verisi olusturur.
- `values["target_record_type"] = "project_record"` sadece target record type alanini doldurur.
- `target_record_id` verilmedigi icin `None` kalir.
- `with pytest.raises(...)` model olusturmanin hata vermesi gerektigini soyler.
- `match=...` hata mesajinda iki alan adinin da bulundugunu kontrol eder.
- `AuditEventRecord(**values)` modeli olusturmaya calisir.

Ikinci yeni test ayni mantigi ters yonden dener: `target_record_id` doludur ama `target_record_type` `None` kalir.

## Neden yalnizca `None` bazli validation yapildi?

Bu adimda amac tek tarafli target reference riskini kapatmaktir.

Bos string, whitespace, target type allowed-list veya target id format kontrolu daha genis kapsamli icerik validation konularidir. Onlari bu adima eklemek Step 114'te korunmus olan opsiyonel bos string davranisini bozabilirdi.

## Teknik karar tablosu

| Sunu yaptik | Boyle yaptik | Cunku | Boylece |
| --- | --- | --- | --- |
| Pair validation ekledik | Iki alanin `None` durumunu karsilastirdik | Target record referansi tek tarafli kalmamali | Eksik hedef kayit iliskisi reddedilir |
| Required validation'i koruduk | Yeni kontrolu mevcut required kontrolunden sonra ekledik | Bos zorunlu alan hatalari ayni kalmali | Hata ayrimi bozulmaz |
| Event type validation'i koruduk | Pair kontrolu event type kontrolunden sonra calisti | Once olay turu sozlesmesi dogrulanmali | Mevcut event type testleri korunur |
| Bos stringleri reddetmedik | Yalnizca `is not None` kontrolu kullandik | Bu adim None bazli sinirda kalmali | Opsiyonel bos string davranisi bozulmaz |
| Target type listesi eklemedik | Allowed-list sonraya birakildi | Target type sozlugu ayri karar ister | Degisiklik kucuk ve geri alinabilir kalir |

## "Sunu soyle yaptik ki..." bolumu

Sunu yaptik:
`target_record_type` ve `target_record_id` alanlarini birlikte kontrol ettik.

Soyle yaptik:
Iki alanin `None` olup olmadigini boolean degerlere cevirip karsilastirdik.

Ki:
Sadece kayit turu veya sadece kayit kimligiyle eksik audit hedefi olusmasin.

Sunu yaptik:
Bos string ve whitespace validation eklemedik.

Soyle yaptik:
Kontrolu yalnizca `None` bazli tuttuk.

Ki:
Adim 114'te korunan opsiyonel bos string davranisi bozulmasin.

## Bilincli olarak yapilmayanlar

Bu adimda target type constants, target type enum veya target type allowed-list validation eklenmedi.

Bu adimda target record id format validation, target record type bos string validation, target record id bos string validation, event type degisikligi, UUID validation, ISO tarih validation, `old_value` / `new_value` validation veya opsiyonel alanlarin genel validation'i eklenmedi.

Bu adimda database, repository, migration, foreign key implementasyonu, JSON import/export, audit event persistence, otomatik audit event uretimi, scanner baglantisi, API, GUI, CLI veya yeni dependency eklenmedi.

## Mini sozluk

`Pair Validation`: Birlikte anlamli olan iki alanin birlikte dolu veya birlikte bos olmasini kontrol etme davranisi.

`None-Based Validation`: Bir alanin yalnizca `None` olup olmadigina bakarak yapilan validation.

`Single-Sided Target Reference`: Target record iliskisinde sadece type veya sadece id alaninin dolu olmasi.

`Target Reference`: Audit event olayinin hangi kayda isaret ettigini gosteren tur ve kimlik referansi.

## Adim 119'a baglanti

Bu adim pair validation'i ekledi.

Adim 119 icin uygun sonraki konu, audit event target record type sabitleri veya target record icerik validation tasarimidir. Sonraki adimda target type allowed-list, bos string/whitespace validation veya target id format kurallari karar seviyesinde ele alinabilir.
