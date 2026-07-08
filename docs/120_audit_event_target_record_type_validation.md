# Adim 120 - Audit Event Target Record Type Validation

## Amac

Bu adimda Adim 119'da dokumante edilen `AuditEventRecord.target_record_type` sozlesmesi dar kapsamli olarak koda baglandi.

Hedef, audit event target reference alanlarinin serbest metin gibi dagilmasini engellemek ve ilk desteklenen target record type listesini model seviyesinde korumaktir.

Bu adimda database, repository, persistence, JSON audit export, otomatik audit uretimi, scanner baglantisi, auth, middleware, API veya GUI eklenmedi.

## Eklenen sabitler

`AuditEventRecord` modelinin yakinina iki sabit eklendi:

```python
AUDIT_TARGET_RECORD_TYPES: tuple[str, ...] = (
    "project",
    "project_record",
    "attachment",
    "attachment_metadata",
    "attachment_integrity_report",
    "json_export",
    "backup_package",
    "restore_operation",
    "handover_package",
    "audit_event",
)

AUDIT_TARGET_RECORD_TYPE_SET: frozenset[str] = frozenset(AUDIT_TARGET_RECORD_TYPES)
```

## `AUDIT_TARGET_RECORD_TYPES`

`AUDIT_TARGET_RECORD_TYPES`, desteklenen target record type degerlerinin sirali ve degistirilmeyen tuple sozlesmesidir.

Bu liste dokumantasyon, test ve ilerideki validation davranisi icin tek kaynak gibi kullanilir.

## `AUDIT_TARGET_RECORD_TYPE_SET`

`AUDIT_TARGET_RECORD_TYPE_SET`, tuple degerlerinden uretilen `frozenset` yapisidir.

Amaci membership kontrolunu sade ve hizli tutmaktir:

```python
if self.target_record_type not in AUDIT_TARGET_RECORD_TYPE_SET:
    raise ValueError("target_record_type is not supported")
```

## Eklenen validation davranisi

`AuditEventRecord.__post_init__` icinde mevcut validation sirasi korundu ve target reference icerik validation'i eklendi.

Davranis:

- `target_record_type` ve `target_record_id` birlikte `None` ise gecerlidir.
- Sadece biri `None` ise mevcut pair validation mesaji korunur.
- Ikisi birlikte verildiyse `target_record_type` bos string veya whitespace olamaz.
- Ikisi birlikte verildiyse `target_record_id` bos string veya whitespace olamaz.
- `target_record_type`, `AUDIT_TARGET_RECORD_TYPE_SET` icinde olmalidir.

Hata mesajlari:

```text
target_record_type and target_record_id must be provided together
target_record_type is required
target_record_id is required
target_record_type is not supported
```

## Pair validation ile allowed-list validation ayrimi

Pair validation, iki alanin birlikte kullanilip kullanilmadigini kontrol eder.

Allowed-list validation, `target_record_type` degerinin desteklenen sozlukte olup olmadigini kontrol eder.

Bu ayrim korundu. Boylece eksik alan hatasi ile desteklenmeyen deger hatasi birbirine karismaz.

Adim 120'de target type allowed-list validation koda eklendi.

Adim 121'de `target_record_id` format tasarimi ayri bir dokuman olarak ele alindi.

`target_record_id` format validation henuz koda eklenmedi. Type validation ve id format validation ayri karar hatlari olarak korunur.

## Bos string / whitespace target reference davranisi

Adim 118'de pair validation yalnizca `None` bazliydi. Bu nedenle `target_record_type=""` ve `target_record_id=""` birlikte verildiginde gecici olarak kabul edilebiliyordu.

Adim 120 ile target reference alanlari icin bos string ve whitespace degerleri reddedilir.

Bu davranis yalnizca target reference alanlarini kapsar. `reason`, `notes`, `old_value`, `new_value` gibi opsiyonel metadata alanlarinin genel validation'i bu adimda eklenmedi.

## Desteklenen target record type listesi

| Target record type |
| --- |
| `project` |
| `project_record` |
| `attachment` |
| `attachment_metadata` |
| `attachment_integrity_report` |
| `json_export` |
| `backup_package` |
| `restore_operation` |
| `handover_package` |
| `audit_event` |

## Neden enum yerine tuple/frozenset kullanildi?

Bu adimda enum tercih edilmedi.

Gerekce:

- Event type sabitleriyle ayni sade yapi korunur.
- Tuple dokumantasyon ve testlerde kolay okunur.
- `frozenset` membership kontrolu icin yeterlidir.
- Bu sozlesme ileride gerekirse enum veya daha zengin bir type sistemine tasinabilir.
- Bu adimda gereksiz soyutlama eklenmez.

## Bu adimda bilincli olarak yapilmayanlar

Bu adimda target record id format validation eklenmedi.

Bu adimda target record id prefix validation, target record existence kontrolu, foreign key implementasyonu, database, repository, migration, JSON export/import, audit event persistence veya otomatik audit event uretimi eklenmedi.

Bu adimda enum class, alias sistemi, config dosyasi, event type validation degisikligi, UUID validation, ISO tarih validation, `old_value` / `new_value` validation veya opsiyonel alanlarin genel validation'i eklenmedi.

## Test kapsami

Bu adimda 6 yeni model testi eklendi:

- Target type sabit listesi ilk sozlesme degerlerini icerir.
- Target type set tuple ile uyumludur ve duplicate yoktur.
- Desteklenen target type kabul edilir.
- Desteklenmeyen target type reddedilir.
- Bos veya whitespace target record type reddedilir.
- Bos veya whitespace target record id reddedilir.

Final test sonucu:

```text
243 passed
```

## Adim 121'e baglanti

Onerilen sonraki adim:

```text
Adim 121 - Audit event target record id format tasarimi veya audit event serialization tasarimi
```

Target record type sozlesmesi artik koda baglandigi icin sonraki adimda target record id format sozlesmesi veya audit event'in tasinabilir serialization tasarimi ele alinabilir.

Adim 121 bu format sozlesmesini documentation-only olarak ele alir; prefix validation, regex validation veya id generator davranisi bu adimda eklenmez.
