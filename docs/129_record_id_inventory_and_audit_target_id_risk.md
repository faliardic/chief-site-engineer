# Adim 129 - Record ID Envanteri ve Audit Target ID Risk Analizi

## Amac

Bu adimin amaci, `AuditEventRecord.target_record_id` icin format validation eklemeden once projedeki mevcut record ID alanlarini, testlerde kullanilan ornek kimlikleri ve olasi kirilma risklerini belgelemektir.

Bu adim documentation-only / architecture-decision-prep adimidir. Kod, test, validation veya runtime davranisi degistirilmedi.

## Incelenen kapsam

Incelenen dosyalar:

- `app/models.py`
- `tests/test_models.py`
- `tests/test_records.py`
- `tests/test_attachment_integrity.py`
- `docs/project_decisions.md`
- `ROADMAP.md`
- `CHANGELOG.md`
- `learning/GLOSSARY.md`

Bu inceleme, audit target id validation eklemek icin yeterli merkezi ID sozlesmesi olup olmadigini anlamaya odaklandi.

## Model bazli ID alanlari

| Model | ID alanlari | Not |
| --- | --- | --- |
| `SiteProject` | `project_id` | Proje kimligi. |
| `ChecklistItem` | `item_id` | Eski checklist item kimligi. |
| `TrackingRecord` | `record_id`, `project_id` | Genel takip kaydi. |
| `ArchiveDocument` | `document_id`, `project_id` | Arsiv belge kimligi ve proje baglantisi. |
| `DailySiteLog` | `log_id`, `project_id` | Gunluk saha kaydi kimligi. |
| `ConcretePour` | `pour_id`, `project_id` | Beton dokum kimligi. |
| `ConcreteSample` | `sample_id`, `pour_id`, `project_id` | Numune, dokum ve proje baglantisi. |
| `InspectionRequest` | `request_id`, `project_id`, `related_pour_id` | Denetim cagrisi ve opsiyonel dokum baglantisi. |
| `NonconformityRecord` | `nonconformity_id`, `project_id`, `related_inspection_request_id`, `related_pour_id` | Ana NCR kaydi ve iliskili kayit baglantilari. |
| `AttachmentRecord` | `attachment_id`, `project_id`, `related_id` | Legacy attachment modeli; `related_model` ile birlikte kullanilir. |
| `FileAttachmentRecord` | `attachment_id`, `related_record_id` | Canonical attachment modeli; `related_record_type` ile birlikte kullanilir. |
| `MaterialRecord` | Yok | Baslik/metadata kaydi; explicit record id yok. |
| `MeetingRecord` | Yok | Explicit record id yok. |
| `MeetingActionRecord` | Yok | Explicit record id yok. |
| `RFIRecord` | Yok | Explicit RFI id yok. |
| `SubmittalRecord` | Yok | Explicit submittal id yok. |
| `DailyReportRecord` | Yok | Explicit report id yok. |
| `ProjectPartyRecord` | `tax_or_id_no` | Bu alan record id degil, dis kimlik/vergi no bilgisidir. |
| `ContactPersonRecord` | Yok | Explicit contact id yok. |
| `SiteLocationRecord` | Yok | Explicit location id yok. |
| `WorkforceRecord` | Yok | Explicit workforce id yok. |
| `EquipmentRecord` | Yok | `serial_or_plate` dis ekipman kimligi olabilir; record id degildir. |
| `SupplierRecord` | Yok | Explicit supplier id yok. |
| `SiteNoteRecord` | Yok | Explicit note id yok. |
| `TaskCandidateRecord` | Yok | Explicit task candidate id yok. |
| `ChecklistItemRecord` | Yok | Explicit record id yok. |
| `CheckResultRecord` | Yok | Explicit check result id yok. |
| `NonconformityCandidateRecord` | Yok | Aday kayit baslikla temsil ediliyor; explicit candidate id yok. |
| `NonconformityCandidateReviewRecord` | Yok | Review kaydi icin explicit id yok. |
| `NonconformityCandidateActionRecord` | Yok | Action kaydi icin explicit id yok. |
| `NonconformityCandidateTrackingSummaryRecord` | Yok | Tracking summary icin explicit id yok. |
| `NonconformityCandidateProcessViewRecord` | `candidate_id`, `check_result_id`, `review_id`, `action_id`, `tracking_summary_id` | Surec gorunumu baglanti ID'lerini tasir. |
| `NonconformityCandidateStatusHistoryRecord` | `candidate_id` | Aday kayit baglantisi. |
| `NonconformityCandidateAssignmentRecord` | `candidate_id` | Aday kayit baglantisi. |
| `NonconformityCandidateClosureRecord` | `candidate_id` | Aday kayit baglantisi. |
| `NonconformityCandidateConversionRecord` | `candidate_id`, `nonconformity_id`, `source_closure_id` | Adaydan NCR'a donusum baglantisi. |
| `NonconformityProcessViewRecord` | `nonconformity_id`, `source_candidate_id`, `conversion_record_id` | NCR surec gorunumu baglantilari. |
| `NonconformityStatusHistoryRecord` | `nonconformity_id` | NCR baglantisi. |
| `NonconformityAssignmentRecord` | `nonconformity_id` | NCR baglantisi. |
| `NonconformityCorrectiveActionRecord` | `nonconformity_id` | NCR baglantisi; kendi action id alani yok. |
| `NonconformityCorrectiveActionVerificationRecord` | `corrective_action_id`, `nonconformity_id` | Duzeltici faaliyet ve NCR baglantisi. |
| `NonconformityClosureRecord` | `nonconformity_id`, `verified_action_id` | NCR kapatma ve dogrulama aksiyonu baglantisi. |
| `AuditEventRecord` | `event_id`, `project_id`, `target_record_id` | Audit olayi ve opsiyonel hedef kayit baglantisi. |

## Testlerde gorulen ID ornekleri

Testlerde tek bir ID bicimi kullanilmiyor. Ornekler birkac gruba ayriliyor.

Lower-case ve tireli ornekler:

- `prj-001`
- `log-001`
- `trk-001`
- `doc-001`
- `pour-001`
- `sample-001`
- `insp-001`
- `ncr-001`
- `ncr-archived-001`
- `att-001`
- `att-ncr-cand-001`
- `file-att-001`
- `audit-001`
- `audit-valid-001`
- `audit-supported-001`

Upper-case prefix ornekleri:

- `NCR-001`
- `NCR-088`
- `ATT-001`
- `ATT-2026-0001`
- `REC-1`
- `REC-2026-0007`
- `NCR-CAND-001`
- `NCR-CAND-REV-001`
- `NCR-CAND-ACT-001`
- `NCR-CAND-TRK-001`
- `NCR-CAND-CLOS-001`
- `NCR-CAND-CONV-001`
- `NCR-CA-001`
- `NCR-CAV-001`
- `CHK-RES-001`
- `CP-000123`
- `NOTE-001`
- `LOG-001`
- `MAT-DEL-001`

Path icinde gorulen ID ornekleri:

- `attachments/PRJ-001/nonconformity/2026/06/07/NCR-001/photo_001.jpg`
- `attachments/PRJ-001/nonconformity/2026/06/07/NCR-1/photo.jpg`
- `attachments/ncr/NCR-001/korkuluk-eksigi.jpg`
- `attachments/site-notes/NOTE-001/saha-duzeni.jpg`
- `attachments/daily-logs/LOG-001/ilerleme-videosu.mp4`

`None` veya opsiyonel baglanti ornekleri:

- `AuditEventRecord.target_record_id` target reference yokken `None` kalabiliyor.
- `AttachmentIntegrityResult.attachment_id` bazi serializer testlerinde `None` olabiliyor.
- `related_pour_id`, `related_inspection_request_id`, `source_candidate_id`, `conversion_record_id` gibi alanlar opsiyonel kalabiliyor.

## Mevcut ID format durumu

Mevcut durumda merkezi ve tum modelleri kapsayan bir record ID formati yoktur.

Gozlenen durum:

- Bazi modeller explicit ID alanina sahip degil.
- Bazi ID alanlari lower-case prefix kullaniyor: `prj-001`, `log-001`, `file-att-001`.
- Bazi ID alanlari upper-case prefix kullaniyor: `NCR-001`, `ATT-001`, `NOTE-001`.
- Bazi ID alanlari cok parcali prefix kullaniyor: `NCR-CAND-REV-001`, `MAT-DEL-001`.
- Bazi ID alanlari path standardi icinde kullaniliyor.
- `project_record` gibi audit target type degerleri tek bir prefix'e karsilik gelmiyor; birden fazla kayit ailesini temsil edebilir.

Bu tablo, `target_record_id` icin hemen regex veya prefix validation eklemenin erken oldugunu gosterir.

## Audit target_record_id validation riski

`AuditEventRecord.target_record_id` su anda serbest string olarak kalmali, fakat bos string / whitespace ve tek tarafli target reference kontrolleri korunmalidir.

Riskler:

- Prefix bazli validation eklenirse `project_record` icin `NCR-001`, `LOG-001`, `NOTE-001`, `MAT-DEL-001`, `CP-000123`, `REC-1` gibi farkli prefixleri ayni anda desteklemek gerekir.
- `attachment` veya `attachment_metadata` icin hem `ATT-001` hem `file-att-001` ailesiyle karsilasilabilir.
- `project` icin `prj-001` ve pathlerdeki `PRJ-001` ayrimi netlesmeden case-sensitive validation risklidir.
- Cok parcali prefixler, basit `<PREFIX>-<YEAR>-<SEQUENCE>` tasarimina hemen uymayabilir.
- Explicit ID alani olmayan modeller icin audit target id nasil uretilecek sorusu henuz cevaplanmadi.
- Mevcut testler `target_record_id` icin `NCR-001`, `ATT-2026-0001`, `REC-1` ve `REC-2026-0007` gibi farkli bicimleri kullaniyor.

Bu nedenle target id validation dogrudan `AuditEventRecord` icine eklenirse hem mevcut test niyetini daraltabilir hem de ileride merkezi ID sozlesmesiyle cakisabilir.

## Onerilen karar

Audit target id format validation, merkezi record ID sozlesmesi netlesmeden uygulanmamalidir.

Onerilen sira:

1. Merkezi record ID sozlesmesi planlanir.
2. Hangi model ailesinin hangi prefix veya ID bicimini kullanacagi belirlenir.
3. Explicit ID alani olmayan modeller icin id stratejisi kararlastirilir.
4. `target_record_type` ile izinli ID aileleri arasinda tablo hazirlanir.
5. Ancak bundan sonra `AuditEventRecord.target_record_id` icin format validation tasarlanir.

## Sonraki guvenli teknik adim

Adim 130 icin en guvenli teknik adim, `central record ID contract plan` hazirlamaktir.

Bu plan su sorulari cevaplamalidir:

- Her record ailesi icin canonical prefix ne olacak?
- Lower-case ve upper-case ID ornekleri nasil ele alinacak?
- Explicit ID alani olmayan modeller icin ID eklenecek mi, yoksa audit target disinda mi tutulacak?
- `target_record_type` ile ID prefix ailesi arasindaki eslestirme nasil tutulacak?
- Backward compatibility icin mevcut test ID ornekleri nasil korunacak?
