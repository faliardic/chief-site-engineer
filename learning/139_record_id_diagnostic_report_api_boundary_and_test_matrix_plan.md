# Adim 139 - Record ID Diagnostic Report API Boundary and Test Matrix Plan

## Sunu yaptik

Olası `build_record_id_diagnostic_report(...)` helper'i icin API boundary, input/output sozlesmesi ve test example matrix planladik.

Bu adimda kod yazmadik. Test yazmadik. Helper implementasyonu yapmadik.

## Boyle yaptik

Helper'in ileride yalnizca input listesini okuyup diagnostic rapor dondurmesini planladik.

Olası input bicimleri:

```python
{"target_record_type": "...", "target_record_id": "..."}
```

veya:

```python
("project_record", "PRJ-001")
```

Ilk implementasyon icin saf Python input listesi daha guvenli olur. Model, repository veya database bagimliligi eklenmemelidir.

## Output nasil dusunuldu?

Rapor dict olabilir:

- `total_count`
- `compatible_count`
- `warning_count`
- `error_count`
- `items`
- `summary`

Her item tekil diagnostic helper sonucuna benzer alanlar tasir:

- `index`
- `target_record_type`
- `target_record_id`
- `observed_prefix`
- `is_compatible`
- `severity`
- `message`

## Test matrix neden onemli?

Toplu rapor helper'i tek kayitlik helperdan daha fazla edge case tasir.

Bos liste, tek canonical kayit, legacy kayit, prefix disi kayit, bilinmeyen target type, bos ID, karisik liste, index korunumu ve input degismezligi ayri ayri test edilmelidir.

Cok parcali prefixler de korunmalidir:

- `NCR-CAND`
- `NCR-CA`
- `MAT-DEL`
- `CHK-RES`
- `JSON-EXP`
- `file-att`

Bu prefixler ilk tireden yanlis bolunmemelidir.

## Boundary neden bu kadar sert?

Diagnostic report helper raporlama aracidir.

Yapmamasi gerekenler:

- Kayit reddetmek.
- Veri degistirmek.
- Database veya repository yazmak.
- Audit event olusturmak.
- Migration yapmak.
- Otomatik duzeltme yapmak.
- Dosya sistemi, backup, restore veya export uretmek.
- Constructor validation veya hard validation olmak.

Bu sinir korunursa helper guvenli bir kalite kontrol gorunurlugu saglar.

## Ana ders

API boundary ve test matrix, implementasyondan once yazildiginda helper'in niyeti net kalir.

Bu sayede Adim 140'ta read-only implementasyon yapilsa bile helper'in hard validation'a veya otomatik veri degisikligine kaymasi engellenir.

Hard validation yine en sona birakilir.
