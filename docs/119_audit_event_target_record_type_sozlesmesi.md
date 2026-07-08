# Adim 119 - Audit Event Target Record Type Sozlesmesi

## Amac

Bu dokuman `AuditEventRecord.target_record_type` alani icin ilk resmi type sozlesmesini tanimlar.

Bu adim documentation-only tutuldu. Uygulama kodu, test kodu, validation, enum, sabit liste, repository, database, JSON persistence veya otomatik audit event uretimi eklenmedi.

Amac, Adim 117 ve Adim 118'de netlesen `target_record_type` / `target_record_id` iliskisinden sonra, ileride kodlanabilecek target record type sabitleri ve allowed-list validation icin guvenli bir sozlesme zemini olusturmaktir.

## Neden target record type sozlesmesi gerekiyor?

Audit event kaydi, bir olay izidir. Bazi olaylar belirli bir kayitla ilgilidir; bu durumda olay yalnizca "ne oldu?" sorusuna degil, "hangi tur kayitla ilgili oldu?" sorusuna da cevap vermelidir.

`target_record_type` bu ikinci sorunun makine-okunabilir cevabidir. Bu alan serbest metin gibi birakilirsa ayni kavram farkli sekillerde yazilabilir:

```text
attachment
ek dosya
dosya eklendi
attachment record
```

Bu farklilik ileride filtreleme, raporlama, validation, audit gorunumu ve backup/handover iliskilerini zorlastirir.

## `target_record_type` nedir?

`target_record_type`, audit olayinin hangi tur kayitla ilgili oldugunu anlatan kisa ve makine-okunabilir kategori degeridir.

Bu alan:

- Olayin ne oldugunu anlatmaz.
- Olayin neden yapildigini anlatmaz.
- Insan notu veya cumle tasimaz.
- Tam kayit icerigi veya snapshot tasimaz.
- Ilgili kaydin turunu belirtir.

Ornek:

```text
event_type = attachment.linked
target_record_type = attachment
target_record_id = ATT-2026-0001
```

## Genel adlandirma kurallari

`target_record_type` degerleri su kurallara uymalidir:

- Kucuk harfli olmalidir.
- Bosluk icermemelidir.
- Turkce karakter icermemelidir.
- Makine tarafindan okunabilir olmalidir.
- Insan aciklamasi gibi yazilmamalidir.
- `reason`, `notes`, `old_value`, `new_value` alanlarinin yerine kullanilmamalidir.
- Tam kayit snapshot'i, ozel alan verisi veya aciklama tasimamali.

Dogru bicim:

```text
project_record
attachment_integrity_report
backup_package
```

Yanlis bicim:

```text
kalip kontrol notu guncellendi
ek dosya raporu
backup paketi uretildi
```

## Ilk target record type adaylari

Bu adimda asagidaki adaylar yalnizca dokumante edilir; koda baglanmaz.

| Target record type | Ne zaman kullanilir? | Target record id neyi temsil eder? | Ornek event type | Not |
| --- | --- | --- | --- | --- |
| `project` | Genel proje kaydini ilgilendiren olaylarda | Proje kimligi | `record.updated` | Proje seviyesindeki olaylar icin kullanilir. |
| `project_record` | Saha, kalite, kontrol veya takip kaydi gibi genel proje kayitlarinda | Ilgili proje kaydi kimligi | `record.updated` | Tekil kayit turu henuz ayrilmamissa guvenli genel kategori olabilir. |
| `attachment` | Dosya/ek kaydi baglama veya ayirma olaylarinda | Attachment kimligi | `attachment.linked` | Fiziksel dosya islemi degil, attachment metadata referansi icin kullanilir. |
| `attachment_metadata` | Attachment metadata alanlari guncellendiginde | Attachment metadata kimligi | `attachment.metadata_updated` | Dosya icerigi yerine metadata degisikligini isaret eder. |
| `attachment_integrity_report` | Attachment integrity raporu uretildiginde veya incelendiginde | Integrity rapor kimligi | `integrity.report_generated` | Rapor resmi kayit yerine gecmez; audit olayi rapor ciktisina referans verir. |
| `json_export` | JSON export ciktisi olusturuldugunda | Export kimligi veya guvenli export referansi | `json.exported` | JSON export kalici veri deposu degildir. |
| `backup_package` | Backup paketi uretildiginde veya dogrulandiginda | Backup paketi kimligi | `backup.generated` | Backup dosyasinin tam icerigi bu alana yazilmaz. |
| `restore_operation` | Restore sureci baslatildiginda veya tamamlandiginda | Restore operasyon kimligi | `restore.started` | Restore kapsam detaylari `notes` veya ayri raporda tutulabilir. |
| `handover_package` | Devir paketi uretildiginde veya dogrulandiginda | Handover paketi kimligi | `handover.package_generated` | Private workspace verisi ile official record ayrimi korunur. |
| `audit_event` | Bir audit olayi baska bir audit olayi ile iliskilendirildiginde | Audit event kimligi | `audit.event_created` | Audit sisteminin kendi izleri icin dikkatli kullanilir. |

Ornekler:

```text
target_record_type = attachment
target_record_id = ATT-2026-0001
event_type = attachment.linked
```

```text
target_record_type = attachment_integrity_report
target_record_id = AIR-2026-0001
event_type = integrity.report_generated
```

```text
target_record_type = backup_package
target_record_id = BCK-2026-0001
event_type = backup.generated
```

## Target record type ile event type ayrimi

`event_type`, olayin ne oldugunu soyler.

`target_record_type`, olayin hangi tur kayitla ilgili oldugunu soyler.

`target_record_id`, olayin hangi kayit kimligiyle ilgili oldugunu soyler.

Yanlis kullanim:

```text
target_record_type = kalip kontrol notu guncellendi
```

Dogru kullanim:

```text
event_type = record.updated
target_record_type = project_record
target_record_id = REC-2026-0007
reason = Kalip kontrol notu guncellendi.
```

Bu ayrim sayesinde event type olay sozlugunu, target record type ise kayit turu sozlugunu temiz tutar.

## Target record type ile reason/notes ayrimi

`reason`, olayin neden yapildigini aciklar.

`notes`, insan tarafindan okunacak ek nottur.

`target_record_type` bu iki alanin yerine kullanilmaz. Bu alan "neden?" veya "ek aciklama nedir?" sorularina cevap vermez.

Ornek:

```text
event_type = attachment.metadata_updated
target_record_type = attachment_metadata
target_record_id = AMD-2026-0004
reason = Dosya tipi yanlis girildigi icin duzeltildi.
notes = Saha fotografi PDF olarak isaretlenmisti.
```

## Target record type ile old_value/new_value ayrimi

`old_value`, eski degerin kisa ve guvenli ozetidir.

`new_value`, yeni degerin kisa ve guvenli ozetidir.

`target_record_type` onceki veya yeni deger bilgisi tasimaz. Degisiklik ozetleri target record type alanina yazilirsa kayit turu kavrami bozulur.

Dogru ayrim:

```text
event_type = record.updated
target_record_type = project_record
target_record_id = REC-2026-0007
old_value = status=open
new_value = status=closed
```

## Ozel alan ve snapshot tasimama siniri

`target_record_type` yalnizca kayit turu bilgisidir.

Bu alana sunlar yazilmamalidir:

- Tam kayit snapshot'i.
- Ozel alan verisi.
- Belge icerigi.
- Fotograf/video dosya yolu.
- Kullanici notu.
- Gerekce cumlesi.
- Onceki/yeni deger ozeti.

Bu sinir ileride audit event kayitlarinin raporlanabilir, filtrelenebilir ve guvenli kalmasi icin onemlidir.

## Ileride kodlanabilecek validation tasarimi

Bu adimda kodlama yapilmadi. Ileride asagidaki validation davranislari eklenebilir:

- `target_record_type` doluysa desteklenen target type listesinde olmalidir.
- `target_record_type` bos string veya whitespace ise reddedilmelidir.
- `target_record_id` bos string veya whitespace ise reddedilmelidir.
- `target_record_type` / `target_record_id` pair validation korunmalidir.
- Allowed-list validation, pair validation'dan sonra calismalidir.
- Hata mesajlari alan adlarini icermelidir.

Onerilen gelecek hata mesajlari:

```text
target_record_type is required when target_record_id is provided
target_record_id is required when target_record_type is provided
target_record_type is not supported
```

Validation sira onerisi:

1. Zorunlu audit event alanlari kontrol edilir.
2. Event type desteklenen listede mi kontrol edilir.
3. `target_record_type` ve `target_record_id` pair validation calisir.
4. Bos string / whitespace kontrolu calisir.
5. `target_record_type` allowed-list kontrolu calisir.

Bu sira, once iliski hatasini, sonra icerik hatasini anlasilir hale getirir.

Adim 120'de bu sozlesmenin ilk kismi `AUDIT_TARGET_RECORD_TYPES` ve `AUDIT_TARGET_RECORD_TYPE_SET` sabitleriyle koda baglandi.

Adim 120 validation davranisi, `target_record_type` alanini desteklenen target type listesiyle sinirlar. Bos string ve whitespace target reference degerleri de reddedilir.

`target_record_id` format validation henuz eklenmedi. Bu nedenle `target_record_id` degeri bos olmadigi surece prefix, tarih, UUID veya varlik kontrolunden gecmez.

## Bu adimda bilincli olarak yapilmayanlar

Bu adimda target type constants eklenmedi.

Bu adimda target type enum eklenmedi.

Bu adimda target type allowed-list validation eklenmedi.

Bu adimda `AuditEventRecord.__post_init__` degistirilmedi.

Bu adimda test eklenmedi veya mevcut test guncellenmedi.

Bu adimda target record id format validation, bos string / whitespace validation, database iliski modeli, foreign key implementasyonu, repository, migration, JSON schema, API, GUI veya CLI davranisi eklenmedi.

## Adim 120'ye baglanti

Bu sozlesme, Adim 120 icin guvenli hazirliktir.

Onerilen sonraki adim:

```text
Adim 120 - Audit event target record type sabitleri ve validation
```

Adim 120'de bu dokumandaki aday liste sabitlere baglanabilir ve `target_record_type` icin allowed-list validation davranisi testlerle eklenebilir.

Adim 120 bu baglantiyi uygulamaya gecirdi; sonraki tasarim konusu `target_record_id` format sozlesmesi veya audit event serialization olabilir.
