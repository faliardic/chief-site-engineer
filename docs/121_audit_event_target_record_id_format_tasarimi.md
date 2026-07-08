# Adim 121 - Audit Event Target Record ID Format Tasarimi

## Amac

Bu dokuman `AuditEventRecord.target_record_id` alani icin ilk format tasarimini tanimlar.

Bu adim documentation-only tutuldu. Uygulama kodu, test kodu, validation, regex, enum, repository, database, JSON persistence veya otomatik audit event uretimi eklenmedi.

Amac, ileride kodlanabilecek `target_record_id` format validation davranisini once guvenli sekilde belgelemektir.

## `target_record_id` nedir?

`target_record_id`, audit event'in iliskili oldugu kaydin kimligini temsil eder.

Bu alan tek basina tam anlam tasimaz. Hangi kayit turune ait oldugu `target_record_type` alanindan anlasilir.

Ornek:

```text
event_type = attachment.linked
target_record_type = attachment
target_record_id = ATT-2026-0001
```

Bu ornekte `target_record_id`, attachment kaydinin kimligini temsil eder.

## Neden format tasarimi gerekiyor?

Audit event kayitlari ileride raporlama, filtreleme, devir paketi, backup/restore ve audit incelemesi icin okunabilir olmalidir.

`target_record_id` serbest aciklama gibi kullanilirsa hangi kaydin isaret edildigi belirsizlesir.

Yanlis:

```text
target_record_id = kalip kontrol notu guncellendi
```

Dogru:

```text
target_record_id = REC-2026-0007
```

Format tasarimi, id degerlerinin hem insan tarafindan okunabilir hem de ileride validation'a uygun olmasini hedefler.

## Ilk format yaklasimi

Bu adimda tek bir zorunlu regex dayatilmadi.

Ilk onerilen tasarim standardi:

```text
<TYPE_PREFIX>-<YEAR>-<SEQUENCE>
```

Ornekler:

```text
PRJ-2026-0001
REC-2026-0007
ATT-2026-0001
AMD-2026-0003
AIR-2026-0001
JEX-2026-0002
BCK-2026-0001
RST-2026-0001
HND-2026-0001
AUD-2026-0001
```

Bu bicim bugun koda baglanmaz. Sadece ilerideki validation ve id tasarimi icin aday sozlesme olarak kaydedilir.

## Target type / prefix aday tablosu

| target_record_type | Onerilen prefix | Ornek target_record_id |
| --- | ---: | --- |
| `project` | `PRJ` | `PRJ-2026-0001` |
| `project_record` | `REC` | `REC-2026-0007` |
| `attachment` | `ATT` | `ATT-2026-0001` |
| `attachment_metadata` | `AMD` | `AMD-2026-0003` |
| `attachment_integrity_report` | `AIR` | `AIR-2026-0001` |
| `json_export` | `JEX` | `JEX-2026-0002` |
| `backup_package` | `BCK` | `BCK-2026-0001` |
| `restore_operation` | `RST` | `RST-2026-0001` |
| `handover_package` | `HND` | `HND-2026-0001` |
| `audit_event` | `AUD` | `AUD-2026-0001` |

Prefix onerisi ileride validation icin temel olabilir.

Ancak bu adimda uygulama koduna eklenmez.

Mevcut modellerin gercek id alanlariyla cakisma olusturmamasi icin prefix validation ileride ayri degerlendirilmelidir.

## Format tasariminda esneklik

Bugun sistemde tum kayit tipleri icin nihai id uretim sistemi yoktur.

Bu nedenle `target_record_id` formati bugun zorlanmaz.

Ilk tasarim amaci, ileride audit event'lerin hangi kayitla iliskili oldugunu daha okunabilir hale getirmektir.

Prefix onerileri kalici sozlesmeye donusmeden once gercek modellerle uyum kontrolu yapilmalidir.

`target_record_id` validation geldiginde geriye donuk uyumluluk dikkate alinmalidir.

## `target_record_id` ile event_type ayrimi

`event_type`, olayin ne oldugunu soyler.

`target_record_id`, olayin hangi kayit kimligiyle ilgili oldugunu soyler.

Ornek:

```text
event_type = backup.generated
target_record_id = BCK-2026-0001
```

Burada `backup.generated` olay turudur; `BCK-2026-0001` ise ilgili backup paketinin kimligidir.

## `target_record_id` ile target_record_type ayrimi

`target_record_type`, kaydin turunu soyler.

`target_record_id`, o tur icindeki tekil kaydi soyler.

Ornek:

```text
target_record_type = attachment_integrity_report
target_record_id = AIR-2026-0001
```

Ikisi birlikte anlam kazanir. `AIR-2026-0001` tek basina yorumlanmamalidir.

## `target_record_id` ile reason/notes ayrimi

`reason`, olayin neden yapildigini aciklar.

`notes`, insan tarafindan okunacak ek nottur.

`target_record_id` aciklama, gerekce veya saha notu tasimaz.

Yanlis:

```text
target_record_id = kalip kontrol notu guncellendi
```

Dogru:

```text
event_type = record.updated
target_record_type = project_record
target_record_id = REC-2026-0007
reason = Kalip kontrol notu guncellendi.
```

## `target_record_id` ile old_value/new_value ayrimi

`old_value`, eski degerin kisa ve guvenli ozetidir.

`new_value`, yeni degerin kisa ve guvenli ozetidir.

`target_record_id`, degisen degeri tasimaz. Sadece ilgili kaydin kimligini tasir.

Dogru ayrim:

```text
target_record_id = REC-2026-0007
old_value = status=open
new_value = status=closed
```

## Ozel alan ve snapshot tasimama siniri

`target_record_id` tam kayit snapshot'i, ozel alan verisi, belge icerigi, fotograf yolu veya uzun aciklama tasimamalidir.

Bu alan yalnizca kayit kimligi icindir.

Ozel alan verisi veya tam kayit icerigi gerekiyorsa bu bilgi ayri guvenli rapor, resmi kayit veya serializer tasarimi icinde ele alinmalidir.

## Ileride kodlanabilecek validation tasarimi

Bu adimda kodlama yapilmadi. Ileride su validation davranislari eklenebilir:

- `target_record_id` bos string veya whitespace olamaz.
- `target_record_id` aciklama cumlesi gibi kullanilamaz.
- `target_record_id` icin genel pattern kontrolu eklenebilir.
- `target_record_type` ile prefix uyumu kontrol edilebilir.
- Ornek: `target_record_type="attachment"` ise id `ATT-` prefix'iyle baslayabilir.
- Prefix kontrolu gercek kayit modelleriyle uyum kontrolu yapilmadan uygulanmamalidir.
- Pair validation ve target type allowed-list validation korunmalidir.

Onerilen gelecek hata mesajlari:

```text
target_record_id is required
target_record_id format is not supported
target_record_id prefix does not match target_record_type
```

Bu hata mesajlari bu adimda koda eklenmedi.

Adim 122'de `target_record_id` validation tasarimi ayrica dokumante edildi.

Adim 121'deki format tasarimi hala koda baglanmadi. Regex validation ve prefix validation henuz eklenmedi.

ID format tasarimi ve ID validation tasarimi ayri karar hatlari olarak korunur. Format tasarimi hedef bicimi anlatir; validation tasarimi ise bu bicimin ileride hangi sirayla ve hangi hata mesajlariyla kontrol edilebilecegini tarif eder.

## Bu adimda bilincli olarak yapilmayanlar

Bu adimda `target_record_id` regex validation eklenmedi.

Bu adimda prefix validation, ID generator, ID normalizer, existing id migration, `AuditEventRecord.__post_init__` degisikligi, test ekleme veya mevcut test guncelleme yapilmadi.

Bu adimda target type sabitleri, event type sabitleri, database iliski modeli, foreign key implementasyonu, repository, migration, JSON schema, API, GUI veya CLI davranisi degistirilmedi.

## Adim 122'ye baglanti

Onerilen sonraki adim:

```text
Adim 122 - Audit event target record id validation tasarimi veya serialization tasarimi
```

Adim 122'de bu dokumandaki format onerisi validation tasarimina donusturulebilir veya audit event serialization hatti ele alinabilir.

Adim 122 bu validation tasarimini documentation-only olarak ele alir; `AuditEventRecord.__post_init__`, testler, regex veya prefix kontrolu degistirilmez.
