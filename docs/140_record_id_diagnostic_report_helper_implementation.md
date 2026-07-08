# Adim 140 - Record ID Diagnostic Report Helper Implementation

## Amac

Bu adimda Adim 138-139 planlarina dayanarak `build_record_id_diagnostic_report(records)` helper fonksiyonu eklendi.

Helper read-only diagnostic report uretir. Hard validation degildir, constructor validation degildir, kayit reddetmez ve veri degistirmez.

## Eklenen helper

`build_record_id_diagnostic_report(records)` helper'i `app/models.py` icinde record ID helper katmanina eklendi.

Desteklenen input item bicimleri:

- Dict item: `{"target_record_type": "...", "target_record_id": "..."}`
- Tuple/list item: `("project_record", "PRJ-001")`

Helper her item icin mevcut `diagnose_record_id_for_target_type(...)` helper'ini kullanir.

## Donen rapor alanlari

Helper dict dondurur:

- `total_count`
- `compatible_count`
- `warning_count`
- `error_count`
- `items`
- `summary`

`summary` alani sade tutuldu:

```python
{
    "total": ...,
    "compatible": ...,
    "warnings": ...,
    "errors": ...,
}
```

## Item alanlari

Her item su alanlari icerir:

- `index`
- `target_record_type`
- `target_record_id`
- `expected_family`
- `allowed_prefixes`
- `observed_prefix`
- `is_compatible`
- `severity`
- `message`

`index`, input sirasini korur.

## Uygunsuz item davranisi

Eksik veya uygunsuz item raporu kesmez.

Ornek uygunsuz itemlar:

- `object()`
- `{}`
- `("project_record",)`

Bu itemlar exception firlatmak yerine `error` severity degerine sahip diagnostic item uretir.

## Read-only sinir

Helper read-only kalir:

- Kayit reddetmez.
- Veri degistirmez.
- Input listesini veya input dictlerini mutate etmez.
- Database veya repository yazmaz.
- Audit event olusturmaz.
- Migration veya otomatik duzeltme yapmaz.
- Dosya sistemi, backup, restore veya export uretmez.
- `AuditEventRecord.__post_init__` icine baglanmadi.
- Constructor validation degildir.
- Hard validation degildir.

## Korunan kararlar

- `target_record_id` hard validation eklenmedi.
- `AuditEventRecord.__post_init__` degismedi.
- Legacy ID ornekleri korunur.
- `FileAttachmentRecord` davranisina dokunulmadi.
- Podcast 023 bu adimda olusturulmadi.

## Test kapsami

`tests/test_models.py` icinde odakli testler eklendi:

- Bos input listesi summary davranisi.
- Tek canonical kayit.
- Tek legacy kayit.
- Tek prefix disi kayit.
- Bilinmeyen target type.
- Bos `target_record_id`.
- Karisik `info` + `warning` + `error` listesi.
- Index korunumu.
- Input immutability.
- Tuple input.
- Uygunsuz itemlar icin exception yerine error item.
- `AuditEventRecord` constructor davranisinin daralmadigi.

## Sonuc

Adim 140, record ID diagnostic hattina ilk read-only toplu rapor helper'ini ekledi.

Bu helper kalite kontrol ve raporlama gorunurlugu saglar; veri reddetme, veri degistirme, migration veya hard validation davranisi baslatmaz.
