# Adim 140 - Record ID Diagnostic Report Helper Implementation

## Sunu yaptik

`build_record_id_diagnostic_report(records)` helper fonksiyonunu ekledik.

Bu helper birden fazla record ID referansini okur, her biri icin diagnostic item uretir ve toplu summary dondurur.

## Boyle yaptik

Helper saf Python input listesiyle calisir.

Dict input:

```python
{"target_record_type": "attachment", "target_record_id": "ATT-2026-0001"}
```

Tuple input:

```python
("attachment", "ATT-2026-0001")
```

Her item icin mevcut tekil helper cagrilir:

```python
diagnose_record_id_for_target_type(target_record_type, target_record_id)
```

Sonra `total_count`, `compatible_count`, `warning_count`, `error_count`, `items` ve `summary` alanlari hesaplanir.

## Cunku

Tekil helper bir kaydi yorumlar. Handover on kontrol, audit QC veya migration oncesi envanter gibi durumlarda birden fazla kaydin birlikte gorulmesi gerekir.

Toplu report helper bu gorunurlugu saglar.

## Read-only sinir

Helper read-only kalir:

- Kayit reddetmez.
- Veri degistirmez.
- Input'u mutate etmez.
- Database veya repository yazmaz.
- Audit event olusturmaz.
- Migration veya otomatik duzeltme yapmaz.
- Dosya sistemi, backup, restore veya export uretmez.

Bu nedenle helper raporlama aracidir, validation kapisi degildir.

## Uygunsuz itemlar

Uygunsuz item raporu kesmez.

`object()`, `{}` veya `("project_record",)` gibi itemlar exception yerine `error` diagnostic item uretir.

Bu sayede toplu rapor, tek hatali item yuzunden tamamen durmaz.

## Ana ders

Diagnostic report helper, kalite gorunurlugunu artirir ama kayit davranisini degistirmez.

Hard validation hala eklenmedi. `AuditEventRecord.__post_init__` degismedi. Legacy ID ornekleri korunur.

Bu sira CSE icin guvenlidir: once gorunurluk, sonra standartlasma, en son gerekirse hard validation.
