# Adim 122 - Audit Event Target Record ID Validation Tasarimi

## Amac

Bu dokuman, Adim 121'de dokumante edilen `AuditEventRecord.target_record_id` format yaklasimini validation tasarimina donusturur.

Bu adim documentation-only tutuldu. Uygulama kodu, test kodu, regex validation, prefix validation, ID generator, repository, database, JSON persistence veya otomatik audit event uretimi eklenmedi.

Amac, ileride kodlanabilecek `target_record_id` validation davranisini once guvenli sekilde belgelemektir.

## Neden validation tasarimi gerekiyor?

`target_record_id`, audit event'in hangi kayit kimligiyle iliskili oldugunu anlatir.

Adim 121'de onerilen genel bicim su sekildeydi:

```text
<TYPE_PREFIX>-<YEAR>-<SEQUENCE>
```

Bu bicimin hemen koda baglanmasi risklidir. Cunku sistemde tum kayit tipleri icin nihai id uretim mekanizmasi henuz yoktur.

Bu nedenle once validation'in hangi asamalarda, hangi hata mesajlariyla ve hangi geriye uyumluluk riskleriyle ele alinacagi tasarlanir.

## Genel format validation yaklasimi

Ilk kod adiminda yalnizca genel yapinin kontrol edilmesi onerilir.

Onerilen genel pattern:

```regex
^[A-Z]{3}-[0-9]{4}-[0-9]{4}$
```

Bu pattern su bicimi hedefler:

```text
AAA-2026-0001
```

Kabul edilebilir ornekler:

```text
PRJ-2026-0001
REC-2026-0007
ATT-2026-0001
AIR-2026-0001
BCK-2026-0001
```

Reddedilebilecek ornekler:

```text
record-2026-0001
REC-26-001
REC-2026-1
REC_2026_0001
Kalip kontrol notu guncellendi
```

Bu adimda bu pattern koda eklenmedi.

## Prefix / target type uyumu yaklasimi

Ikinci veya ayri bir kod adiminda `target_record_type` ile `target_record_id` prefix'i arasinda uyum kontrolu yapilabilir.

Gecerli olabilecek ornek:

```text
target_record_type = attachment
target_record_id = ATT-2026-0001
```

Ileride reddedilebilecek ornek:

```text
target_record_type = attachment
target_record_id = REC-2026-0001
```

Bu kontrol hemen kodlanmamalidir. Once gercek model id alanlari ve mevcut ornek kayitlar ile uyum kontrolu yapilmalidir.

## Target type / prefix esleme tasarimi

| target_record_type | Onerilen prefix |
| --- | --- |
| `project` | `PRJ` |
| `project_record` | `REC` |
| `attachment` | `ATT` |
| `attachment_metadata` | `AMD` |
| `attachment_integrity_report` | `AIR` |
| `json_export` | `JEX` |
| `backup_package` | `BCK` |
| `restore_operation` | `RST` |
| `handover_package` | `HND` |
| `audit_event` | `AUD` |

Bu esleme bu adimda koda eklenmez.

## Hata mesaji tasarimi

Ileride kullanilabilecek hata mesajlari:

```text
target_record_id is required
target_record_id format is not supported
target_record_id prefix does not match target_record_type
```

Ayrimi:

- `target_record_id is required`: Deger bos veya whitespace.
- `target_record_id format is not supported`: Genel pattern yanlis.
- `target_record_id prefix does not match target_record_type`: Genel pattern dogru ama prefix/type eslesmesi yanlis.

Bu mesajlar alan adini ve hata nedenini birlikte tasimalidir.

## Validation sirasi tasarimi

Ileride kodlanabilecek onerilen sira:

1. Required field validation.
2. Event type allowed-list validation.
3. Target record pair validation.
4. Target record type allowed-list validation.
5. `target_record_type` bos/whitespace kontrolu.
6. `target_record_id` bos/whitespace kontrolu.
7. `target_record_id` genel format kontrolu.
8. Prefix / target type uyumu kontrolu.

Bu sira bu adimda yalnizca tasarimdir; kod degisikligi yapilmadi.

## Geriye donuk uyumluluk riski

Sistemde tum kayit tipleri icin nihai id uretim mekanizmasi henuz yoktur.

Mevcut modellerin id alanlari onerilen formatla birebir uyumlu olmayabilir.

Bu nedenle prefix validation, gercek model id uretim kararlari netlesmeden kodlanmamalidir.

Genel format validation bile ileride mevcut kayitlarla cakisma yaratabilir.

Validation kodlanmadan once gercek model id alanlari ve ornek kayitlar gozden gecirilmelidir.

## `target_record_id` ile event_type ayrimi

`event_type`, olayin ne oldugunu soyler.

`target_record_id`, olayin hangi kayit kimligiyle ilgili oldugunu soyler.

Ornek:

```text
event_type = record.updated
target_record_id = REC-2026-0007
```

## `target_record_id` ile target_record_type ayrimi

`target_record_type`, olayin hangi tur kayitla ilgili oldugunu soyler.

`target_record_id`, o tur icindeki tekil kaydin kimligini soyler.

Ornek:

```text
target_record_type = attachment
target_record_id = ATT-2026-0001
```

## `target_record_id` ile reason/notes ayrimi

`reason`, olayin neden yapildigini aciklar.

`notes`, insan tarafindan okunacak ek nottur.

Yanlis kullanim:

```text
target_record_id = kalip kontrol notu guncellendi
```

Dogru kullanim:

```text
event_type = record.updated
target_record_type = project_record
target_record_id = REC-2026-0007
reason = Kalip kontrol notu guncellendi.
```

## `target_record_id` ile old_value/new_value ayrimi

`old_value`, eski degerin kisa ve guvenli ozetidir.

`new_value`, yeni degerin kisa ve guvenli ozetidir.

`target_record_id`, degisen degeri degil, degisiklikten etkilenen kaydin kimligini tasir.

## Bu adimda bilincli olarak yapilmayanlar

Bu adimda regex validation eklenmedi.

Bu adimda prefix validation, ID generator, ID normalizer, existing id migration, `AuditEventRecord.__post_init__` degisikligi, test ekleme veya mevcut test guncelleme yapilmadi.

Bu adimda target type sabitleri, event type sabitleri, database iliski modeli, foreign key implementasyonu, repository, migration, JSON schema, API, GUI veya CLI davranisi degistirilmedi.

## Adim 123'e baglanti

Onerilen sonraki adim:

```text
Adim 123 - Audit event serialization tasarimi veya target record id format validation
```

Adim 123'te audit event serialization tasarimi ele alinabilir veya bu dokumandaki genel format validation kodlanabilir.
