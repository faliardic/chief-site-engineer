# Adim 117 - Audit Event Target Record Iliski Kurallari

## Amac

Bu dokuman `AuditEventRecord.target_record_type` ve `target_record_id` alanlari icin ilk iliski sozlesmesini tanimlar.

Bu adim documentation-only tutuldu. Uygulama kodu, test kodu, validation, enum, sabit liste, repository, database, JSON persistence veya otomatik audit event uretimi eklenmedi.

## Neden target record iliski kurallari gerekiyor?

Audit event kaydi bir olay izidir. Bazi olaylar belirli bir kayitla ilgilidir; bazi olaylar ise genel proje, sistem veya surec olayi olabilir.

Target record alanlari, audit event'in hangi kayitla ilgili oldugunu makine tarafindan okunabilir sekilde anlatmak icin gerekir.

Bu alanlar serbest aciklama gibi kullanilirsa audit event kaydi hem insanlar hem de ilerideki kod icin belirsiz hale gelir.

## `target_record_type` nedir?

`target_record_type`, audit olayinin hangi tur kayitla iliskili oldugunu belirtir.

Bu alan insan aciklamasi degildir. Makine tarafindan okunabilir kisa kategori degeridir.

Ornek degerler:

```text
attachment
attachment_integrity_report
project_record
handover_package
```

## `target_record_id` nedir?

`target_record_id`, audit olayinin iliskili oldugu kaydin kimligini belirtir.

Bu kimlik `target_record_type` alanindaki kayit turune ait olmalidir.

Bu alan aciklama, not veya gerekce alani degildir. Aciklama gerekiyorsa `reason` veya `notes` kullanilmalidir.

## Temel iliski kurallari

1. `target_record_type` tek basina dolu kalmamalidir.
2. `target_record_id` tek basina dolu kalmamalidir.
3. Ikisi birlikte doluysa audit event belirli bir kayitla iliskilidir.
4. Ikisi birlikte `None` ise audit event genel proje, sistem veya surec olayi olabilir.
5. `target_record_type` serbest aciklama alani degildir.
6. `target_record_id` aciklama, not veya gerekce alani degildir.
7. Kayit hakkinda insan aciklamasi gerekiyorsa `reason` veya `notes` kullanilmalidir.
8. Onceki/yeni deger farki gerekiyorsa `old_value` ve `new_value` kullanilmalidir.
9. Target record alanlari ozel alan verisi veya tam kayit snapshot'i tasimamalidir.
10. Target record iliskisi resmi kaydin yerine gecmez; yalnizca audit olayinin hangi kayitla ilgili oldugunu gosterir.

## Ikisi birlikte dolu oldugunda anlami

`target_record_type` ve `target_record_id` birlikte doluysa olay belirli bir kayitla iliskilidir.

Ornek:

```text
event_type = attachment.linked
target_record_type = attachment
target_record_id = ATT-2026-0001
```

Bu ornekte olay bir attachment kaydi ile iliskilidir.

## Ikisi birlikte bos oldugunda anlami

Iki alan birlikte `None` ise olay belirli bir kayda bagli olmak zorunda degildir.

Bu durum genel proje, sistem veya surec olaylari icin kullanilabilir.

Ornek:

```text
event_type = audit.validation_failed
target_record_type = None
target_record_id = None
reason = Audit event kaydi required field validation nedeniyle reddedildi.
```

## Tek tarafli doluluk neden riskli?

Sadece `target_record_type` doluysa hangi kayda bakilacagi bilinmez.

Sadece `target_record_id` doluysa bu kimligin hangi kayit turune ait oldugu bilinmez.

Bu nedenle tek tarafli doluluk ileride pair validation icin risk olarak ele alinmalidir.

Adim 118'de `target_record_type` ve `target_record_id` icin ilk pair validation eklendi.

Bu validation yalnizca `None` bazli tek tarafli dolulugu engeller. Target type allowed-list, bos string validation ve whitespace validation henuz eklenmedi.

## Ilk target record type adaylari

| Target record type | Ne zaman kullanilir? | Target record id neyi temsil eder? | Ornek event type |
| --- | --- | --- | --- |
| `project` | Genel proje olayi belirli bir proje kaydina baglanacaksa | Proje kimligi | `record.updated` |
| `project_record` | Saha, kalite veya takip kaydi gibi genel proje kayitlari icin | Ilgili kayit kimligi | `record.updated` |
| `attachment` | Dosya/ek kaydi baglama veya ayirma olaylari icin | Attachment kimligi | `attachment.linked` |
| `attachment_metadata` | Attachment metadata guncelleme olaylari icin | Attachment metadata kimligi | `attachment.metadata_updated` |
| `attachment_integrity_report` | Integrity raporu uretme veya inceleme olaylari icin | Rapor kimligi | `integrity.report_generated` |
| `json_export` | JSON export ciktisi olaylari icin | Export kimligi veya dosya referansi | `json.exported` |
| `backup_package` | Backup paketi uretme veya dogrulama olaylari icin | Backup paketi kimligi | `backup.generated` |
| `restore_operation` | Restore sureci olaylari icin | Restore operasyon kimligi | `restore.started` |
| `handover_package` | Devir paketi uretme veya dogrulama olaylari icin | Handover paketi kimligi | `handover.package_generated` |
| `audit_event` | Audit sisteminin baska bir audit event ile iliskili olmasi durumunda | Audit event kimligi | `audit.event_created` |

## Target record ile event type ayrimi

`event_type`, ne oldugunu soyler.

`target_record_type`, hangi tur kayitla ilgili oldugunu soyler.

`target_record_id`, hangi kayitla ilgili oldugunu soyler.

`reason`, neden oldugunu aciklar.

`notes`, ek insan notudur.

`old_value` ve `new_value`, degisen degerin kisa ve guvenli ozetidir.

Dogru kullanim:

```text
event_type = record.updated
target_record_type = project_record
target_record_id = REC-2026-0007
reason = Kalip kontrol notu guncellendi.
old_value = status=open
new_value = status=closed
```

Yanlis kullanim:

```text
target_record_type = kalip kontrol notu guncellendi
```

Dogru ayrim:

```text
target_record_type = project_record
reason = Kalip kontrol notu guncellendi.
```

## Target record ile reason/notes ayrimi

Target record alanlari kayit turu ve kimlik bilgisini tasir.

`reason` olayin gerekcesini, `notes` ise ek insan aciklamasini tasir.

Target record alanlari cumle, yorum veya saha notu tasimamalidir.

## Target record ile old_value/new_value ayrimi

Target record alanlari hangi kaydin etkilendigini gosterir.

`old_value` ve `new_value`, olaydan onceki ve sonraki deger ozetini gosterir.

Bu nedenle once/sonra durum bilgisi target record alanlarina yazilmamalidir.

## Ozel alan ve snapshot tasimama siniri

Target record alanlari ozel alan verisi, tam kayit snapshot'i, belge icerigi veya insan aciklamasi tasimamalidir.

Bu alanlar yalnizca tur ve kimlik referansi icindir.

## Bu adimda bilincli olarak yapilmayanlar

Bu adimda `target_record_type` allowed-list eklenmedi.

Bu adimda `target_record_type`, `target_record_id` veya pair validation eklenmedi.

Bu adimda `AuditEventRecord.__post_init__` degistirilmedi.

Bu adimda test eklenmedi veya mevcut test guncellenmedi.

Bu adimda target record enum, constants, repository baglantisi, database iliski modeli, foreign key tasarimi, JSON schema, migration, API veya GUI davranisi eklenmedi.

## Adim 118'e baglanti

Adim 118 icin uygun sonraki konu, audit event target record validation veya target type sabitleridir.

Bu adimda kurallar yalnizca dokumante edildi. Sonraki adimda pair validation veya target type allowed-list kod seviyesinde ele alinabilir.
