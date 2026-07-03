# Adim 115 - Audit Event Type Sozlesmesi

## Amac

Bu dokuman `AuditEventRecord.event_type` alani icin ilk resmi sozlesmeyi tanimlar.

Bu adim documentation-only tutuldu. Uygulama kodu, test kodu, validation, enum, sabit liste, repository, database, JSON persistence veya otomatik audit event uretimi eklenmedi.

## Neden event type sozlesmesi gerekiyor?

Audit event kaydi ileride sistemdeki kritik olaylari izlenebilir hale getirecek.

`event_type` alani bu olaylarin makine tarafindan okunabilir kisa tur bilgisidir. Bu alan serbest aciklama gibi kullanilirsa filtreleme, raporlama, audit trail inceleme ve ilerideki validation davranislari tutarsiz hale gelir.

Bu nedenle kodlamadan once ilk sozlesme dokumante edilir.

## Genel adlandirma bicimi

Event type degerleri kucuk harfli, Turkce karakter icermeyen, bosluksuz ve nokta ayrimli stringler olarak planlanir.

Onerilen bicim:

```text
domain.action
```

Ornek:

```text
record.created
integrity.report_generated
json.export_failed
```

## Domain/action yapisi

`domain`, olay ailesini veya sistem alanini anlatir.

`action`, o alanda gerceklesen kisa eylemi anlatir.

Ilk domain adaylari:

```text
record
attachment
integrity
json
backup
restore
handover
audit
```

Ilk action adaylari:

```text
created
updated
archived
restored
checked
exported
generated
linked
unlinked
validated
failed
```

## Ilk event type adaylari

Ilk adaylar, CSE'nin mevcut model, attachment integrity, JSON export, backup/restore, handover ve audit hazirlik hattina gore gruplandi.

Bu liste bu adimda kod sabiti veya enum degildir; dokumantasyon sozlesmesidir.

Adim 116 ile bu ilk sozlesme `AUDIT_EVENT_TYPES` ve `AUDIT_EVENT_TYPE_SET` sabitleriyle koda baglandi.

Validation yalnizca desteklenen event type listesindeki degerleri kabul edecek kadar dar tutuldu. Domain/action yapisi hala dokumantasyon sozlesmesinin ana ilkesidir.

## Kayit olaylari

```text
record.created
record.updated
record.archived
record.restored
```

## Attachment olaylari

```text
attachment.linked
attachment.unlinked
attachment.metadata_updated
```

## Attachment integrity olaylari

```text
integrity.checked
integrity.report_generated
integrity.issue_detected
```

## JSON export olaylari

```text
json.exported
json.export_failed
```

## Backup / restore olaylari

```text
backup.generated
backup.validated
restore.started
restore.completed
restore.failed
```

## Handover olaylari

```text
handover.package_generated
handover.package_validated
```

## Audit sistem olaylari

```text
audit.event_created
audit.validation_failed
```

## Sozlesme kurallari

- Event type degerleri kucuk harfli olmali.
- Bosluk icermemeli.
- Turkce karakter icermemeli.
- Nokta ayrimli domain/action bicimi kullanilmali.
- Event type, olayi anlatmali; kullanici arayuzu etiketi gibi yazilmamali.
- Event type, serbest aciklama alani degildir.
- `reason`, `notes`, `old_value`, `new_value` alanlarinin yerine kullanilmamali.
- `event_type` kisa, makine tarafindan okunabilir ve sabit sozlesmeye uygun olmali.
- Insan tarafindan okunabilir aciklama gerekiyorsa bu bilgi `reason` veya `notes` alanina yazilmali.

## Event type ile reason/notes ayrimi

`event_type`, olayin sabit tur bilgisidir.

`reason`, bu olayin neden yapildigini anlatir.

`notes`, insan tarafindan okunabilir ek baglam veya sinirlama bilgisini tasir.

Dogru ayrim:

```text
event_type: record.archived
reason: NCR kapanis sonrasi aktif listeden arsive alindi.
notes: Arsivleme manuel kalite kontrol onayi sonrasi kaydedildi.
```

Yanlis kullanim:

```text
event_type: NCR kapanis sonrasi aktif listeden arsive alindi
```

## Event type ile old_value/new_value ayrimi

`event_type` olayin turunu anlatir.

`old_value` ve `new_value`, olaydan onceki ve sonraki degerleri veya durum ozetini anlatir.

Dogru ayrim:

```text
event_type: record.updated
old_value: status=open
new_value: status=closed
```

Yanlis kullanim:

```text
event_type: status open iken closed oldu
```

## Bu adimda bilincli olarak yapilmayanlar

Bu adimda event type enum eklenmedi.

Bu adimda event type sabitleri eklenmedi.

Bu adimda event type validation eklenmedi.

Bu adimda `AuditEventRecord.__post_init__` kodu degistirilmedi.

Bu adimda yeni test eklenmedi veya mevcut test guncellenmedi.

Bu adimda otomatik event type uretimi, migration, JSON schema, repository, database, API, GUI, CLI veya scanner baglantisi eklenmedi.

## Adim 116'ya baglanti

Adim 116 icin uygun sonraki konu, audit event type validation veya sabit sozlesme implementasyonudur.

Bu adimda sozlesme yalnizca dokumante edildi. Bir sonraki adimda bu sozlesmenin kod seviyesinde enum, constants veya validation ile desteklenip desteklenmeyecegi ayrica ele alinabilir.
