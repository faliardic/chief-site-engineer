# Adim 136 - Record ID Diagnostic Helper Implementation

## Amac

Bu adimda Adim 135 planina dayanarak `diagnose_record_id_for_target_type(target_record_type, target_record_id)` helper fonksiyonu eklendi.

Helper, record ID degerini reddetmez. Sadece dis kalite kontrol, diagnostic, raporlama ve handover on kontrol katmanlari icin okunabilir bilgi uretir.

## Eklenen helper

Helper `app/models.py` icinde mevcut record ID mapping katmaninin yanina eklendi.

Kullandigi mevcut sozlesmeler:

- `RECORD_ID_PREFIXES`
- `TARGET_RECORD_TYPE_TO_ID_FAMILY`
- `TARGET_RECORD_TYPE_TO_ID_PREFIXES`
- `get_record_id_family_for_target_type`
- `get_allowed_record_id_prefixes_for_target_type`

Donen dict alanlari:

- `target_record_type`
- `target_record_id`
- `expected_family`
- `allowed_prefixes`
- `observed_prefix`
- `is_compatible`
- `severity`
- `message`

## Prefix okuma yaklasimi

Helper once ilgili target type icin allowed prefix listesini uzunluktan kisaya siralar.

Bu tercih, cok parcali prefixlerin yanlis bolunmesini engeller:

- `NCR-CAND`
- `NCR-CA`
- `MAT-DEL`
- `CHK-RES`
- `JSON-EXP`
- `file-att`

Eslestirme su iki basit kosulla yapilir:

- `record_id == prefix`
- `record_id.startswith(prefix + "-")`

Allowed prefix eslesmesi yoksa `observed_prefix` ilk tire oncesindeki bolum olarak okunur. Bu fallback validation degildir; sadece raporlamayi okunur tutar.

## Severity karari

- `info`: Canonical prefix ile uyumlu gorunen ID.
- `warning`: Legacy prefix ile uyumlu gorunen ID veya allowed prefix disinda kalan ama reddedilmeyen ID.
- `error`: Bilinmeyen `target_record_type` veya bos/gecersiz `target_record_id` gibi helper seviyesinde diagnostic uretilemeyen giris.

`error` sonucu model constructor davranisina tasinmaz. Bu seviye sadece helper cikti sozlugunun diagnostic bilgisidir.

## Bilincli sinirlar

- Diagnostic helper veri reddetmez.
- `AuditEventRecord.__post_init__` icine baglanmadi.
- `AuditEventRecord.target_record_id` hard validation eklenmedi.
- Legacy ID ornekleri korunur.
- `FileAttachmentRecord` davranisina dokunulmadi.
- Persistence, repository, API, GUI, CLI, database, auth veya upload servisi eklenmedi.
- Podcast 022 bu adimda olusturulmadi.

## Test kapsami

`tests/test_models.py` icinde odakli testler eklendi:

- Canonical `attachment` / `ATT-2026-0001` icin `info` diagnostic.
- Legacy `attachment` / `file-att-001` icin `warning` diagnostic.
- Prefix disi `project_record` / `XYZ-001` icin exception atmayan `warning` diagnostic.
- Bilinmeyen `unknown_record` icin `error` diagnostic.
- Bos `target_record_id` icin okunur `error` diagnostic.
- `AuditEventRecord` constructor davranisinin prefix disi `target_record_id` degerini kabul etmeye devam ettigi test.

## Sonuc

Adim 136, record ID uyumlulugu icin ilk calisan diagnostic katmani ekledi. Bu katman henuz validation kapisi degildir; raporlama ve kalite gorunurlugu icin bilgi uretir.
