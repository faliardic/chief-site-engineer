# Adim 116 - Audit Event Type Sabitleri ve Validation

## Amac

Bu adimda Adim 115'te dokumante edilen `AuditEventRecord.event_type` sozlesmesi dar kapsamli olarak koda baglandi.

Hedef, ilk event type adaylarini merkezi sabitler halinde tutmak ve `AuditEventRecord` olusturulurken desteklenmeyen event type degerlerini reddetmektir.

## Eklenen sabitler

Iki sabit eklendi:

- `AUDIT_EVENT_TYPES`
- `AUDIT_EVENT_TYPE_SET`

Bu sabitler event type sozlesmesini koda tasir. Bu adimda enum, class yapisi veya config dosyasi eklenmedi.

## `AUDIT_EVENT_TYPES`

`AUDIT_EVENT_TYPES`, desteklenen event type degerlerinin sirali tuple listesidir.

Bu yapi sozlesmenin okunabilir ana kaynagidir.

## `AUDIT_EVENT_TYPE_SET`

`AUDIT_EVENT_TYPE_SET`, `AUDIT_EVENT_TYPES` degerlerinden uretilen `frozenset` yapisidir.

Bu yapi validation sirasinda hizli membership kontrolu yapmak icin kullanilir.

## Eklenen validation davranisi

Mevcut zorunlu alan validation davranisi korundu.

Ek olarak, `event_type` dolu ve bosluklardan arinmis olsa bile `AUDIT_EVENT_TYPE_SET` icinde degilse `ValueError` yukseltir.

Hata mesaji:

```text
event_type is not supported
```

## `event_type is required` ve `event_type is not supported` ayrimi

Iki hata ayrimi bilincli olarak korundu:

- `event_type` bos, whitespace veya `None` ise: `event_type is required`
- `event_type` dolu ama sozlesme disiysa: `event_type is not supported`

Bu ayrim kullaniciya ve ilerideki servis katmanina sorunun turunu daha net anlatir.

## Ilk desteklenen event type listesi

```text
record.created
record.updated
record.archived
record.restored
attachment.linked
attachment.unlinked
attachment.metadata_updated
integrity.checked
integrity.report_generated
integrity.issue_detected
json.exported
json.export_failed
backup.generated
backup.validated
restore.started
restore.completed
restore.failed
handover.package_generated
handover.package_validated
audit.event_created
audit.validation_failed
```

## Neden enum yerine tuple/frozenset kullanildi?

Bu asamada event type sozlesmesi yeni olgunlasiyor.

Tuple ve frozenset kullanimi sade, okunabilir ve geri alinabilir bir yapi saglar. Enum daha resmi ve daha agir bir sozlesme hissi verir. Bu adimda ihtiyac yalnizca merkezi liste ve membership kontroludur.

Bu nedenle:

- tuple okunabilir sozlesme listesi olarak kullanildi
- frozenset hizli membership kontrolu icin kullanildi
- enum sonraki daha olgun bir adima birakildi

## Bu adimda bilincli olarak yapilmayanlar

Bu adimda database, repository, migration, JSON import/export, audit event persistence veya otomatik audit event uretimi eklenmedi.

Bu adimda decorator, middleware, auth/user/role sistemi, scanner baglantisi, attachment integrity kodu degisikligi, backup/restore davranisi, handover package implementasyonu, API, GUI, CLI veya yeni dependency eklenmedi.

Bu adimda event type enum, alias sistemi, config tasima, target record pair validation, UUID validation, tarih format validation, `old_value` / `new_value` validation veya opsiyonel alan validation eklenmedi.

## Test kapsami

Eklenen testler sunlari dogrular:

- `AUDIT_EVENT_TYPES` ilk sozlesme degerlerini icerir.
- `AUDIT_EVENT_TYPE_SET`, tuple ile ayni icerige sahiptir.
- Tuple icinde duplicate event type yoktur.
- Desteklenen event type ile `AuditEventRecord` olusturulabilir.
- Desteklenmeyen event type `ValueError` ile reddedilir.

Mevcut required field validation testleri korunur.

## Target record iliskisiyle sinir

Bu adimdaki `event_type` validation yalnizca olay turunu dogrular.

`target_record_type` ve `target_record_id` iliskisi ayri bir sozlesme olarak Adim 117'de dokumante edildi.

Event type validation, target record iliski tutarliligini kontrol etmez.

## Adim 117'ye baglanti

Adim 117 icin uygun sonraki konu, audit event target record iliski kurallari dokumantasyonu veya validation tasarimidir.

Event type sozlesmesi koda baglandigi icin artik `target_record_type` ve `target_record_id` alanlarinin hangi eventlerde nasil kullanilacagi karar seviyesinde ele alinabilir.
