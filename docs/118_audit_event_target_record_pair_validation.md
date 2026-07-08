# Adim 118 - Audit Event Target Record Pair Validation

## Amac

Bu adimda Adim 117'de dokumante edilen `target_record_type` ve `target_record_id` iliski kurali dar kapsamli olarak koda baglandi.

Hedef, tek tarafli target record referanslarini engellemektir.

## Eklenen pair validation davranisi

`AuditEventRecord.__post_init__` icinde `target_record_type` ve `target_record_id` alanlari birlikte kontrol edilir.

Kural:

- Iki alan birlikte `None` ise gecerlidir.
- Iki alan birlikte `None` degilse gecerlidir.
- Sadece biri `None` ise gecersizdir.

Hata mesaji:

```text
target_record_type and target_record_id must be provided together
```

## Gecerli durumlar

```text
target_record_type = None
target_record_id = None
```

```text
target_record_type = project_record
target_record_id = REC-2026-0007
```

```text
target_record_type = ""
target_record_id = ""
```

Son ornek bu adimda gecerlidir; cunku validation yalnizca `None` bazlidir.

## Gecersiz durumlar

```text
target_record_type = project_record
target_record_id = None
```

```text
target_record_type = None
target_record_id = REC-2026-0007
```

Bu iki durumda target record iliskisi tek tarafli kalir ve `ValueError` yukseltir.

## Neden yalnizca `None` bazli validation yapildi?

Adim 117 sozlesmesinin ilk kod karsiligi, iki alanin birlikte kullanilmasi gerektigini korumaktir.

Bu adimda icerik dogrulama, target type sozlugu veya kimlik formati gibi daha genis kurallar eklenmedi. Once pair mantigi kucuk ve test edilebilir sekilde sabitlendi.

## Bos string / whitespace validation neden ertelendi?

Adim 114'te opsiyonel alanlarin bos string olarak kalabilmesi bilincli olarak korunmustu.

Bu nedenle bu adimda `target_record_type=""` veya `target_record_id=""` degerleri icerik olarak reddedilmedi. Bos string ve whitespace validation sonraki ayri bir adimda ele alinabilir.

## Target type allowed-list neden eklenmedi?

Target type adaylari Adim 117'de dokumante edildi ancak bu adimda koda baglanmadi.

Allowed-list eklemek daha genis bir sozlesme karari gerektirir. Bu adim sadece pair validation ile sinirlidir.

Adim 119'da `target_record_type` degerleri icin ayri type sozlesmesi dokumante edildi.

Bu nedenle Adim 118 pair validation'i target type allowed-list kontrolu yapmaz. Bu validation yalnizca `target_record_type` ve `target_record_id` alanlarinin birlikte kullanilip kullanilmadigini kontrol eder.

Target type degerinin desteklenen listede olup olmadigi, bos string / whitespace kontrolu ve daha ayrintili icerik validation'i sonraki ayri adimlarin konusudur.

## Test kapsami

Eklenen testler sunlari dogrular:

- `target_record_type` tek basina verilemez.
- `target_record_id` tek basina verilemez.

Mevcut testler iki alanin birlikte `None` kalabildigini, birlikte dolu olabildigini ve opsiyonel bos stringlerin bu asamada reddedilmedigini korur.

## Bu adimda bilincli olarak yapilmayanlar

Bu adimda target type constants, target type enum veya target type allowed-list validation eklenmedi.

Bu adimda target record id format validation, target record type bos string validation, target record id bos string validation, event type degisikligi, UUID validation, ISO tarih validation, `old_value` / `new_value` validation veya opsiyonel alanlarin genel validation'i eklenmedi.

Bu adimda database, repository, migration, foreign key implementasyonu, JSON import/export, audit event persistence, otomatik audit event uretimi, scanner baglantisi, API, GUI, CLI veya yeni dependency eklenmedi.

## Adim 119'a baglanti

Adim 119 icin uygun sonraki konu, audit event target record type sozlesmesi dokumantasyonudur.

Pair validation artik temel tek tarafli referans riskini engelledigi icin sonraki adimda target type sozlugu veya bos string/whitespace icerik validation'i degerlendirilebilir.

Adim 119 bu sozlesmeyi documentation-only olarak ele alir; target type constants ve allowed-list validation implementasyonu Adim 120 veya sonraki adimlara birakilir.
