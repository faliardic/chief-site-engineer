# Adim 136 - Record ID Diagnostic Helper Implementation

## Sunu yaptik

`diagnose_record_id_for_target_type(target_record_type, target_record_id)` helper fonksiyonunu ekledik.

Bu fonksiyon bir record ID degerini hedef kayit turune gore yorumlar ve dict olarak diagnostic sonuc dondurur.

Ornek:

```python
diagnostic = diagnose_record_id_for_target_type(
    "attachment",
    "ATT-2026-0001",
)
```

Bu sonuc `observed_prefix`, `is_compatible`, `severity` ve okunabilir `message` gibi alanlar icerir.

## Boyle yaptik

Helper once mevcut mapping helperlarini kullanir:

```python
expected_family = get_record_id_family_for_target_type(target_record_type)
allowed_prefixes = get_allowed_record_id_prefixes_for_target_type(
    target_record_type
)
```

Sonra allowed prefixleri uzunluktan kisaya siralar. Boylece `NCR-CAND`, `MAT-DEL` veya `file-att` gibi cok parcali prefixler ilk tireden yanlis kesilmez.

Eger allowed prefix bulunursa sonuc compatible olur. Canonical prefix ise `info`, legacy prefix ise `warning` dondurulur.

Eger allowed prefix bulunmazsa helper yine exception firlatmaz. `observed_prefix` icin ilk tire oncesini kullanir ve `warning` dondurur.

## Cunku

CSE icinde mevcut ID ornekleri tek bicimde degil. Canonical `ATT-...` ornekleri de var, legacy `file-att-...` ornekleri de var.

Bu nedenle hemen hard validation eklemek mevcut anlamli ornekleri kirabilir.

Diagnostic helper once gorunurluk saglar:

- Hangi ID canonical gorunuyor?
- Hangi ID legacy gorunuyor?
- Hangi ID prefix disi ama reddedilmiyor?
- Hangi target type helper seviyesinde bilinmiyor?

## Boylece

Audit, kalite kontrol, raporlama veya handover on kontrol katmanlari ileride bu bilgiyi kullanabilir.

Ama model constructor davranisi degismedi:

- `AuditEventRecord.__post_init__` icine baglanmadi.
- `target_record_id` hard validation eklenmedi.
- Legacy ID ornekleri korunur.
- `FileAttachmentRecord` davranisina dokunulmadi.

Podcast 022 bu adimda olusturulmadi.
