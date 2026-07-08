# Adim 130 - Central Record ID Contract Plan

## Amac

Bu adimin amaci, Adim 129'da cikarilan record ID envanterine dayanarak merkezi record ID sozlesmesi icin ilk plan dokumantasyonunu hazirlamaktir.

Bu adim documentation-only / architecture planning adimidir. Kod, model, test, helper, validation veya runtime davranisi degistirilmedi.

## Arka plan: Adim 129 bulgulari

Adim 129'da su bulgular kaydedildi:

- Projede tek ve merkezi bir record ID formati yok.
- Bazi modeller explicit ID alani tasiyor, bazi modeller tasimiyor.
- Testlerde lower-case, upper-case, cok parcali prefix ve path icine gomulu ID ornekleri birlikte kullaniliyor.
- `AuditEventRecord.target_record_id` alani farkli ID ailelerini temsil edebiliyor.
- `project_record` gibi genis `target_record_type` degerleri tek bir prefix ailesine karsilik gelmiyor.

Bu nedenle `AuditEventRecord.target_record_id` icin hard format validation hemen eklenmeyecek. Once merkezi record ID contract, target type / ID family mapping ve test ornek standardizasyonu planlanacak.

## Mevcut ID format problemi

Mevcut test ve model orneklerinde ayni anda su aileler goruluyor:

- Lower-case kisa ID: `prj-001`, `log-001`, `file-att-001`, `audit-001`.
- Upper-case domain ID: `NCR-001`, `ATT-001`, `NOTE-001`, `LOG-001`.
- Cok parcali ID: `NCR-CAND-REV-001`, `NCR-CAND-CONV-001`, `MAT-DEL-001`.
- Yil iceren audit ornekleri: `ATT-2026-0001`, `REC-2026-0007`.
- Path icinde kullanilan ID: `attachments/PRJ-001/nonconformity/2026/06/07/NCR-001/photo_001.jpg`.
- Explicit ID alani olmayan modeller: `MaterialRecord`, `MeetingRecord`, `RFIRecord`, `DailyReportRecord`, `SiteNoteRecord` ve benzeri kayitlar.

Bu durum, tek bir regex veya tek bir prefix listesiyle hard validation yapmanin erken oldugunu gosterir.

## Onerilen merkezi ID ilkeleri

Merkezi ID sozlesmesi su ilkelere dayanmalidir:

1. Her ID ailesinin tek bir anlam sahibi olmali.
2. Prefix, sadece okunabilirlik icin degil, record family mapping icin de kullanilmali.
3. `target_record_type` degeri ile izinli ID aileleri ayri bir mapping tablosunda tutulmali.
4. Explicit ID alani olmayan modeller icin once ID stratejisi belirlenmeli.
5. Eski test ve dokuman ornekleri hemen kirilmamali.
6. Hard validation en son adim olmali.
7. Once documentation, sonra constants/mapping, sonra test standardizasyonu, sonra soft validation, en son hard validation uygulanmali.

## Model bazli ID sozlesmesi taslagi

| ID ailesi | Alan adi | Onerilen prefix | Ornek format | Zorunluluk durumu | Geriye uyumluluk riski | Audit target_record_type iliskisi |
| --- | --- | --- | --- | --- | --- | --- |
| Project | `project_id` | `PRJ` | `PRJ-2026-0001` veya gecici `prj-001` | Simdilik oneridir | `prj-001` ve `PRJ-001` birlikte var | `project` |
| File attachment | `attachment_id` | `ATT` | `ATT-2026-0001` | Simdilik oneridir | `att-001`, `file-att-001`, `ATT-001` birlikte var | `attachment`, `attachment_metadata` |
| Audit event | `event_id` | `AUD` veya `EVT` | `AUD-2026-0001` | Simdilik oneridir | `audit-001`, `audit-valid-001` mevcut | `audit_event` |
| Nonconformity | `nonconformity_id` | `NCR` | `NCR-2026-0001` veya mevcut `NCR-001` | Simdilik oneridir | `ncr-001` ve `NCR-001` birlikte var | `project_record` veya ileride `nonconformity` |
| Nonconformity candidate | `candidate_id` | `NCR-CAND` | `NCR-CAND-2026-0001` | Simdilik oneridir | Mevcut ornekler `NCR-CAND-001` | `project_record` veya ileride `nonconformity_candidate` |
| Candidate review | `review_id` | `NCR-CAND-REV` | `NCR-CAND-REV-2026-0001` | Simdilik oneridir | Mevcut ornek `NCR-CAND-REV-001` | `project_record` veya ileride `nonconformity_candidate_review` |
| Candidate action | `action_id` | `NCR-CAND-ACT` | `NCR-CAND-ACT-2026-0001` | Simdilik oneridir | Mevcut ornek `NCR-CAND-ACT-001` | `project_record` |
| Candidate tracking summary | `tracking_summary_id` | `NCR-CAND-TRK` | `NCR-CAND-TRK-2026-0001` | Simdilik oneridir | Mevcut ornek `NCR-CAND-TRK-001` | `project_record` |
| Candidate closure | `source_closure_id` | `NCR-CAND-CLOS` | `NCR-CAND-CLOS-2026-0001` | Simdilik oneridir | Mevcut ornek `NCR-CAND-CLOS-001` | `project_record` |
| Candidate conversion | `conversion_record_id` | `NCR-CAND-CONV` | `NCR-CAND-CONV-2026-0001` | Simdilik oneridir | Mevcut ornek `NCR-CAND-CONV-001` | `project_record` |
| Corrective action | `corrective_action_id` | `NCR-CA` | `NCR-CA-2026-0001` | Simdilik oneridir | Mevcut ornek `NCR-CA-001`; action modelinde kendi id alani yok, verification modelinde referans var | `project_record` |
| Corrective action verification | `verified_action_id` | `NCR-CAV` | `NCR-CAV-2026-0001` | Simdilik oneridir | Mevcut ornek `NCR-CAV-001` | `project_record` |
| Material delivery | Yeni explicit alan gerekebilir: `material_delivery_id` | `MAT-DEL` | `MAT-DEL-2026-0001` | Henuz model alani yok; yalnizca plan | Mevcut modelde explicit ID yok, testlerde `related_record_id="MAT-DEL-001"` var | `project_record` veya ileride `material_delivery` |
| Daily site log | `log_id` | `LOG` | `LOG-2026-0001` | Simdilik oneridir | `log-001` ve `LOG-001` birlikte var | `project_record` |
| Site note | Yeni explicit alan gerekebilir: `site_note_id` | `NOTE` | `NOTE-2026-0001` | Henuz model alani yok; yalnizca plan | Testlerde `related_record_id="NOTE-001"` var ama `SiteNoteRecord` explicit id tasimiyor | `project_record` |
| Generic project record | `record_id` | `REC` | `REC-2026-0001` | Simdilik oneridir | `trk-001`, `REC-1`, `REC-2026-0007` birlikte var | `project_record` |
| Related record | `related_record_id`, `related_id` | Hedef kaydin ailesine bagli | Hedef aileye gore degisir | Hard validation yok | Tek bir prefix olamaz; baglandigi record ailesine gore degisir | `attachment_metadata`, legacy attachment baglantilari |
| Audit target | `target_record_id` | Hedef kaydin ailesine bagli | Hedef aileye gore degisir | Hard validation yok | Mevcut farkli ornekleri kirmamak icin serbest string kalmali | `target_record_type` ile mapping gerekir |
| Explicit ID olmayan modeller | Yok | Belirlenecek | Belirlenecek | Plan gerektirir | ID eklemek model davranisini ve testleri etkileyebilir | Simdilik dogrudan hard target validation disinda tutulmali |

## target_record_type / ID ailesi eslestirme matrisi

Mevcut `AUDIT_TARGET_RECORD_TYPES` degerleri lower-case tutuluyor. Asagidaki tablo, mevcut target type degerlerine hangi ID ailelerinin baglanabilecegini plan seviyesinde onerir.

| Mevcut target_record_type | Kavramsal aile adi | Izinli ID aileleri | Not |
| --- | --- | --- | --- |
| `project` | `PROJECT` | `project_id` / `PRJ` | `prj-001` backward compatibility riski var. |
| `project_record` | `PROJECT_RECORD` | `NCR`, `NCR-CAND`, `LOG`, `NOTE`, `MAT-DEL`, `REC`, `CHK-RES`, diger saha kayitlari | Cok genis oldugu icin hard prefix validation icin en riskli target type. |
| `attachment` | `FILE_ATTACHMENT` | `ATT`, `file-att`, legacy `att` | Canonical ve legacy attachment ornekleri birlikte var. |
| `attachment_metadata` | `FILE_ATTACHMENT_METADATA` | `ATT`, `file-att`, hedef kaydin `related_record_id` ailesi | Hem attachment kimligi hem iliskili kayit kimligi baglami gerekebilir. |
| `attachment_integrity_report` | `ATTACHMENT_INTEGRITY_REPORT` | Gelecekte `AIR` veya `ATT-INT-RPT` | Henuz merkezi report id yok. |
| `json_export` | `JSON_EXPORT` | Gelecekte `JSON-EXP` | Henuz merkezi export id yok. |
| `backup_package` | `BACKUP_PACKAGE` | Gelecekte `BCK` | Henuz merkezi backup id yok. |
| `restore_operation` | `RESTORE_OPERATION` | Gelecekte `RST` | Henuz merkezi restore operation id yok. |
| `handover_package` | `HANDOVER_PACKAGE` | Gelecekte `HND` | Henuz merkezi handover package id yok. |
| `audit_event` | `AUDIT_EVENT` | `AUD` veya `EVT`, mevcut `audit-*` | Event id ailesi netlesmeli. |

Bu matris hard validation degildir. Bir sonraki adimda constants veya helper mapping tasarimi icin aday tablodur.

## Geriye uyumluluk riskleri

- `project_id` testleri lower-case `prj-001` kullaniyor; canonical `PRJ-*` karari hemen uygulanirsa testler kirilir.
- `attachment_id` icin `att-001`, `file-att-001` ve `ATT-001` birlikte var.
- `nonconformity_id` icin hem `ncr-001` hem `NCR-001` kullaniliyor.
- `target_record_id` testlerinde `REC-1`, `REC-2026-0007`, `ATT-2026-0001` ve `NCR-001` birlikte var.
- `project_record` target type degeri cok genis; tek prefixe indirgenemez.
- Explicit ID alani olmayan modeller icin audit hedefi tanimlamak once model veya service-level ID stratejisi gerektirir.
- Path standardi icindeki ID'ler ile model alanlarindaki ID'ler ayni case ve formatta olmayabilir.

## Asamali gecis plani

### Phase 1: Documentation-only contract

- Merkezi ID aileleri ve prefix adaylari dokumante edilir.
- Hard validation eklenmez.
- Mevcut testler ve eski ornekler korunur.

### Phase 2: Helper constants / mapping

- Kod davranisini degistirmeyen constants veya mapping tasarimi hazirlanir.
- Ornek: `RECORD_ID_FAMILIES`, `TARGET_TYPE_TO_ID_FAMILIES`.
- Bu asamada helper sadece sozlesme okuma ve dokumantasyon amacli olabilir.

### Phase 3: Test examples standardization

- Yeni test ornekleri canonical ID ailesine gore yazilmaya baslanir.
- Eski testler backward compatibility amaciyla korunur veya net ayrilir.
- Lower-case / upper-case gecis karari dokumante edilir.

### Phase 4: Non-breaking warnings or soft validation

- Hard hata yerine raporlama, helper sonucu veya soft validation kullanilir.
- Uyumsuz ID'ler sistem davranisini kirmadan gorunur hale getirilir.

### Phase 5: Hard validation only after migration

- Mevcut veri, test ornekleri ve model alanlari merkezi sozlesmeye hizalandiktan sonra hard validation degerlendirilir.
- `AuditEventRecord.target_record_id` format validation ancak bu asamada uygulanabilir.

## Bu adimda bilincli olarak yapilmayanlar

- `app/models.py` degistirilmedi.
- Test dosyalari degistirilmedi.
- `AuditEventRecord.target_record_id` hard validation eklenmedi.
- Regex validation, prefix validation veya helper implementasyonu eklenmedi.
- `FileAttachmentRecord` veya baska bir model degistirilmedi.
- Podcast 021 olusturulmadi.
- Commit veya push yapilmadi.

## Sonraki guvenli teknik adim

Adim 131 icin en guvenli teknik adim, `record ID constants and mapping helper plan` veya `target record type to ID family mapping helper` dokumantasyonudur.

Bu adim, hard validation eklemeden once su sorulari netlestirmelidir:

- Mapping kodda hangi isimlerle temsil edilecek?
- Mevcut `AUDIT_TARGET_RECORD_TYPES` degerleriyle uyum nasil korunacak?
- `project_record` gibi genis target type degerleri coklu ID ailesini nasil tasiyacak?
- Helper sadece bilgi mi dondurecek, yoksa soft validation sonucu da uretecek mi?
