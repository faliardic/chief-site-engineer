# Adim 117 - Audit Event Target Record Iliski Kurallari

## Bu adimda ne yaptik?

Bu adimda `AuditEventRecord` icindeki `target_record_type` ve `target_record_id` alanlarinin nasil kullanilmasi gerektigini dokumante ettik.

Kod degistirmedik. Test eklemedik. Validation, enum, constants, repository veya persistence eklemedik.

## Neden yaptik?

Audit event kaydi bir olay izidir. Olay bazen belirli bir kayitla ilgilidir; bazen de genel proje, sistem veya surec olayi olabilir.

Bu ayrimi ileride guvenli sekilde kodlayabilmek icin once sozlesmeyi yazdik.

## Dokunulan dosyalar

```text
docs/117_audit_event_target_record_iliski_kurallari.md
learning/117_audit_event_target_record_iliski_kurallari.md
CHANGELOG.md
ROADMAP.md
docs/project_decisions.md
docs/113_audit_event_record_baslangic_modeli.md
docs/116_audit_event_type_validation.md
learning/GLOSSARY.md
```

`docs/117_audit_event_target_record_iliski_kurallari.md`: Target record sozlesmesinin ana dokumani.

`learning/117_audit_event_target_record_iliski_kurallari.md`: Konunun ogrenme amacli aciklamasi.

`CHANGELOG.md`, `ROADMAP.md`, `docs/project_decisions.md`: Proje takip ve karar kayitlari.

`docs/113_audit_event_record_baslangic_modeli.md` ve `docs/116_audit_event_type_validation.md`: Onceki audit dokumanlarina Adim 117 baglantisi.

`learning/GLOSSARY.md`: Yeni kalici terimler.

## Target record nedir?

Target record, audit event olayinin iliskili oldugu kayittir.

Ornegin bir attachment baglandiysa target record attachment kaydi olabilir. Bir integrity raporu uretildiyse target record integrity raporu olabilir.

```text
event_type = attachment.linked
target_record_type = attachment
target_record_id = ATT-2026-0001
```

Bu ornekte olay turu attachment baglama, hedef kayit ise `ATT-2026-0001` kimlikli attachment kaydidir.

## `target_record_type` ve `target_record_id` neden ayri?

`target_record_type`, kimligin hangi kayit turune ait oldugunu soyler.

`target_record_id`, o kayit turu icindeki somut kimligi soyler.

Bu iki alan ayri tutuldugunda sistem hem turu hem de kimligi net gorebilir.

## Ikisi birlikte dolu oldugunda ne olur?

Iki alan birlikte doluysa audit event belirli bir kayda baglidir.

```text
event_type = integrity.report_generated
target_record_type = attachment_integrity_report
target_record_id = AIR-2026-0001
```

Bu kullanimda olay bir attachment integrity raporu ile iliskilidir.

## Ikisi birlikte bos oldugunda ne olur?

Iki alan birlikte `None` ise olay belirli bir kayda bagli olmayabilir.

Bu durum genel proje, sistem veya surec olaylari icin kullanilabilir.

```text
event_type = audit.validation_failed
target_record_type = None
target_record_id = None
reason = Audit event validation reddi.
```

## Tek tarafli doluluk neden sorun cikarir?

Sadece `target_record_type` doluysa kayit turu bilinir ama hangi kayit oldugu bilinmez.

Sadece `target_record_id` doluysa bir kimlik vardir ama bu kimligin hangi kayit turune ait oldugu bilinmez.

Bu nedenle tek tarafli doluluk ileride pair validation konusu olmalidir.

## Ilk target record type adaylari tablosu

| Target record type | Ne zaman kullanilir? | Target record id neyi temsil eder? | Ornek event type |
| --- | --- | --- | --- |
| `project` | Genel proje olayi proje kaydina baglanacaksa | Proje kimligi | `record.updated` |
| `project_record` | Genel saha veya kalite kaydi icin | Kayit kimligi | `record.updated` |
| `attachment` | Dosya/ek baglama veya ayirma icin | Attachment kimligi | `attachment.linked` |
| `attachment_metadata` | Dosya metadata guncellemesi icin | Metadata kimligi | `attachment.metadata_updated` |
| `attachment_integrity_report` | Integrity raporu icin | Rapor kimligi | `integrity.report_generated` |
| `json_export` | JSON export ciktisi icin | Export kimligi veya dosya referansi | `json.exported` |
| `backup_package` | Backup paketi icin | Backup paketi kimligi | `backup.generated` |
| `restore_operation` | Restore sureci icin | Restore operasyon kimligi | `restore.started` |
| `handover_package` | Devir paketi icin | Handover paketi kimligi | `handover.package_generated` |
| `audit_event` | Baska bir audit event ile iliski icin | Audit event kimligi | `audit.event_created` |

## Dogru / yanlis kullanim ornekleri

Dogru:

```text
event_type = backup.generated
target_record_type = backup_package
target_record_id = BCK-2026-0001
reason = Manuel guvenli nokta oncesi backup paketi uretildi.
```

Yanlis:

```text
target_record_type = Manuel guvenli nokta oncesi backup paketi uretildi
target_record_id = backup paketi hazirlandi
```

Yanlis kullanimda hedef kayit alanlari aciklama gibi kullanilmistir. Aciklama `reason` veya `notes` alanina yazilmalidir.

## `event_type`, `target_record_type`, `target_record_id`, `reason`, `notes`, `old_value`, `new_value` ayrimi

`event_type`, ne oldugunu soyler.

`target_record_type`, hangi tur kayitla ilgili oldugunu soyler.

`target_record_id`, hangi kayitla ilgili oldugunu soyler.

`reason`, neden oldugunu aciklar.

`notes`, ek insan notudur.

`old_value` ve `new_value`, degisen degerin kisa ve guvenli ozetidir.

```text
event_type = record.updated
target_record_type = project_record
target_record_id = REC-2026-0007
reason = Kalip kontrol notu guncellendi.
old_value = status=open
new_value = status=closed
notes = Guncelleme saha kontrolu sonrasi kaydedildi.
```

## Teknik karar tablosu

| Sunu yaptik | Boyle yaptik | Cunku | Boylece |
| --- | --- | --- | --- |
| Target record sozlesmesi yazdik | `target_record_type` ve `target_record_id` kurallarini dokumante ettik | Audit event hangi kayda ait net gorulmeli | Iliski dili tutarli hale gelir |
| Iki alani birlikte ele aldik | Pair mantigini anlattik | Tek tarafli doluluk belirsizlik uretir | Ileride validation daha guvenli tasarlanir |
| Aciklamayi ayirdik | `reason` ve `notes` alanlarini vurguladik | Target alanlari yorum tasimamali | Kayit referansi ile insan aciklamasi karismaz |
| Degisim bilgisini ayirdik | `old_value` ve `new_value` alanlarini ayri tuttuk | Once/sonra bilgisi hedef kayit kimligi degildir | Audit izi daha temiz okunur |
| Kod yazmadik | Documentation-only ilerledik | Once sozlesme netlesmeli | Sonraki adimda kod karari daha saglam olur |

## "Sunu soyle yaptik ki..." bolumu

Sunu yaptik:
`target_record_type` ve `target_record_id` alanlarini birlikte dusunduk.

Soyle yaptik:
Iki alan birlikte doluysa belirli kayda bagli, birlikte bossa genel olay olabilir dedik.

Ki:
Audit event kaydi hangi kayda isaret ettigini belirsiz birakmasin.

Sunu yaptik:
Target record alanlarini aciklama alanlarindan ayirdik.

Soyle yaptik:
Aciklama icin `reason` ve `notes`, degisim ozeti icin `old_value` ve `new_value` alanlarini isaret ettik.

Ki:
Kayit kimligi, gerekce ve degisim bilgisi birbirine karismasin.

## Bilincli olarak yapilmayanlar

Bu adimda uygulama kodu degistirilmedi.

Bu adimda test dosyasi degistirilmedi.

Bu adimda target record validation, target type constants, target type enum veya pair validation eklenmedi.

Bu adimda database, repository, migration, foreign key implementasyonu, JSON import/export, audit persistence veya otomatik audit event uretimi eklenmedi.

Bu adimda scanner, attachment integrity kodu, backup/restore davranisi, handover package implementasyonu, API, GUI, CLI veya yeni dependency eklenmedi.

## Mini sozluk

`Target Record`: Audit event olayinin iliskili oldugu kayit.

`Target Record Type`: Iliskili kaydin turunu anlatan makine-okunabilir kategori.

`Target Record ID`: Iliskili kaydin kimligini anlatan alan.

`Pair Validation`: Iki alanin birlikte anlamli kullanilip kullanilmadigini kontrol etme davranisi.

`Foreign Key`: Veritabaninda bir kaydin baska bir kaydi kimlik uzerinden isaret etmesi.

## Adim 118'e baglanti

Bu adim target record iliski kurallarini dokumante etti.

Adim 118 icin uygun sonraki konu, audit event target record validation veya target type sabitleridir. Bu sonraki adimda pair validation veya target type allowed-list kod seviyesinde ele alinabilir.
