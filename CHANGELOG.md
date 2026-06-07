# Changelog

## Step 051

- Added `NonconformityRepository.count` and `NonconformityRepository.count_by_status` for in-memory record counting.
- Added tests for total record counts, empty repository counts, status-specific counts, and missing status counts returning `0`.
- No JSON, SQLite, API, GUI, CLI, dashboard, file operation, delete, archive, or automatic workflow was added in this step.

## Step 050

- Added `NonconformityRepository.exists` for in-memory boolean presence checks by `nonconformity_id`.
- Added a test proving existing ids return `True`, missing ids return `False`, and existing repository data remains unchanged.
- No JSON, SQLite, API, GUI, CLI, dashboard, file operation, delete, archive, or automatic workflow was added in this step.

## Step 049

- Added `NonconformityRepository.update_responsible_party` for in-memory responsible party updates of existing NCR records.
- Added tests for updating an existing record, reflecting the new responsible party in filters and summaries, setting the responsible party to `None`, and returning `None` for a missing id.
- No JSON, SQLite, API, GUI, CLI, dashboard, file operation, automatic workflow, or automatic assignment history record was added in this step.

## Step 048

- Added `NonconformityRepository.update_status` for in-memory status updates of existing NCR records.
- Added tests for updating an existing record, reflecting the new status in filters and summaries, and returning `None` for a missing id.
- No JSON, SQLite, API, GUI, CLI, dashboard, file operation, automatic workflow, or automatic status history record was added in this step.

## Step 047

- Added `NonconformityRepository.get_overview_summary` for in-memory total, open, closed, assigned, and unassigned counts.
- Added tests for populated and empty overview summary results.
- No JSON, SQLite, API, GUI, CLI, dashboard, file operation, or automatic workflow was added in this step.

## Step 046

- Added `NonconformityRepository.get_responsible_party_summary` for in-memory responsible party count summaries.
- Added tests for counting responsible parties, grouping missing responsible parties as `unassigned`, and returning an empty dict for an empty repository.
- No JSON, SQLite, API, GUI, CLI, dashboard, file operation, or automatic workflow was added in this step.

## Step 045

- Added `NonconformityRepository.get_status_summary` for in-memory status count summaries.
- Added tests for counting multiple status values and returning an empty dict for an empty repository.
- No JSON, SQLite, API, GUI, CLI, dashboard, file operation, or automatic workflow was added in this step.

## Step 044

- Added `NonconformityRepository.list_by_responsible_party` for in-memory responsible party filtering.
- Added a test proving records can be filtered separately for Ahmet and Mehmet, with missing responsible parties returning an empty list.
- No JSON, SQLite, API, GUI, CLI, file operation, dashboard, or automatic workflow was added in this step.

## Step 043

- Added `NonconformityRepository.list_by_status` for in-memory status filtering of `NonconformityRecord` records.
- Added a test proving open and closed records are filtered separately and missing statuses return an empty list.
- No JSON, SQLite, API, GUI, CLI, file operation, dashboard, or automatic workflow was added in this step.

## Step 042

- Added duplicate `nonconformity_id` protection to `NonconformityRepository.add`.
- Added a test proving duplicate ids raise `ValueError` while different ids can still be added.
- No JSON, SQLite, API, GUI, CLI, file operation, or automatic workflow was added in this step.

## Step 041

- Added `NonconformityRepository` as a small in-memory repository for `NonconformityRecord` records.
- Added tests for adding, listing, finding by id, and returning `None` for a missing nonconformity id.
- No JSON, SQLite, API, GUI, CLI, file operation, or automatic workflow was added in this step.

## Step 040

- Added `NonconformityClosureRecord` as the starting closure model for definite nonconformity / NCR records.
- Added a test for closure values and default final status, follow-up, follow-up note, and notes behavior.
- No API, GUI, database query, JSON record system, automatic closure, automatic approval, notification, or file operation was added in this step.

## Step 039

- Added `NonconformityCorrectiveActionVerificationRecord` as the starting verification model for NCR corrective action checks.
- Added a test for verification values and default rework, next action, status, and notes behavior.
- No API, GUI, database query, JSON record system, automatic closure, automatic approval, notification, or file operation was added in this step.

## Step 038

- Added `NonconformityCorrectiveActionRecord` as the starting corrective action model for definite nonconformity / NCR records.
- Added a test for corrective action values and default verification, status, completion date, and notes behavior.
- No API, GUI, database query, JSON record system, automatic closure, approval workflow, notification, or file operation was added in this step.

## Step 037

- Added `NonconformityAssignmentRecord` as the starting responsibility assignment model for definite nonconformity / NCR records.
- Added a test for assignment values and default `status` / `notes` behavior.
- No API, GUI, database query, JSON record system, automatic assignment, notification, approval workflow, or file operation was added in this step.

## Step 036

- Added `NonconformityStatusHistoryRecord` as the starting model for definite nonconformity / NCR status change history.
- Added tests for NCR status history values and optional field defaults.
- No database query, API, GUI, automatic status update, automatic NCR creation, corrective action system, approval workflow, JSON record system, or file operation was added in this step.

## Step 035

- Added `NonconformityProcessViewRecord` as the starting view model for definite nonconformity / NCR process summaries.
- Added tests for NCR process view values and optional field defaults.
- No database query, API, GUI, automatic NCR creation, automatic conversion, corrective action system, approval workflow, JSON record system, or file operation was added in this step.

## Step 034

- Revised the existing `NonconformityRecord` model with additional optional fields for type, detection actor, detection date, and final status.
- Updated the existing `NonconformityRecord` test to verify the new default values.
- Did not add `source_candidate_id` or `conversion_record_id`; candidate-to-NCR links remain represented by `NonconformityCandidateConversionRecord`.

## Step 033

- Added a decision preparation report evaluating the existing `NonconformityRecord` model after the candidate-to-NCR process chain.
- Documented existing fields, potentially missing fields, and the relationship with `NonconformityCandidateConversionRecord`.
- No model, test model, database query, API, GUI, JSON record system, automatic NCR creation, or corrective action system was added in this step.

## Step 032

- Added `NonconformityCandidateConversionRecord` as the starting conversion link model between candidate records and existing `NonconformityRecord` NCR records.
- Kept the existing `NonconformityRecord` model from Step 007 unchanged.
- No database query, API, GUI, automatic NCR creation, automatic conversion, corrective action system, approval workflow, JSON record system, or file operation was added in this step.

## Step 031

- Added final NotebookLM podcast notes for Steps 026-030.
- Summarized attachment evidence, process view, status history, assignment, and closure records as one nonconformity candidate tracking narrative.
- No new model, test model, database query, API, GUI, JSON record system, or file operation was added in this step.

## Step 030

- Added `NonconformityCandidateClosureRecord` as the starting closure and result model for nonconformity candidates.
- Added tests for closure values and optional field defaults.
- No database query, API, GUI, automatic closure, automatic status update, NCR creation, JSON record system, or file operation was added in this step.

## Step 029

- Added `NonconformityCandidateAssignmentRecord` as the starting responsibility and assignment model for nonconformity candidates.
- Added tests for assignment values and optional field defaults.
- No database query, API, GUI, automatic notification, automatic task assignment, JSON record system, or file operation was added in this step.

## Step 028

- Added `NonconformityCandidateStatusHistoryRecord` as the starting model for nonconformity candidate status change history.
- Added tests for status history values and optional field defaults.
- No database query, API, GUI, automatic reporting, JSON record system, or file operation was added in this step.

## Step 027

- Added `NonconformityCandidateProcessViewRecord` as the starting view model for nonconformity candidate process chains.
- Added tests for process view values and default empty-link state.
- No database query, API, GUI, automatic reporting, JSON record system, or file operation was added in this step.

## Step 026

- Documented the use of the existing `AttachmentRecord` model for nonconformity candidate evidence files.
- Added a test showing `AttachmentRecord.related_model` and `related_id` linking to `NonconformityCandidateRecord`.
- No new `NonconformityCandidateAttachment` model, database, API, GUI, JSON record system, or file operation was added in this step.

## Step 025

- Added `NonconformityCandidateTrackingSummaryRecord` model for Step 025.
- The model summarizes the current tracking status of nonconformity candidate processes at the data level.
- No database, API, GUI, JSON record system, file operation, final nonconformity management, corrective action system, or task tracking workflow was added in this step.

## Step 024

- Added `NonconformityCandidateActionRecord` model for Step 024.
- The model keeps simple action decisions for reviewed nonconformity candidates at the data level.
- No database, API, GUI, JSON record system, file operation, final nonconformity management, or corrective action system was added in this step.

## Step 023

- Added `NonconformityCandidateReviewRecord` model for Step 023.
- The model keeps nonconformity candidate review results at the data level.
- No database, API, GUI, JSON record system, or file operation was added in this step.

## Step 022

- Added `NonconformityCandidateRecord` model as the starting point for simple nonconformity candidate records.
- Added tests for nonconformity candidate values and default open status.
- Added documentation and learning material for the nonconformity candidate record model.

## Step 021

- Added `CheckResultRecord` model as the starting point for simple check result records.
- Added tests for check result values and default recorded status.
- Added documentation and learning material for the check result record model.

## Step 020

- Added `ChecklistItemRecord` model as the starting point for simple checklist item records.
- Added tests for checklist item record values and default pending status.
- Added documentation and learning material for the checklist item record model.

## Step 019

- Added `TaskCandidateRecord` model as the starting point for simple task candidate tracking.
- Added tests for task candidate values and default open status.
- Added documentation and learning material for the task candidate record model.

## Step 018

- Added `SiteNoteRecord` model as the starting point for simple site note tracking.
- Added tests for site note values and default open status.
- Added documentation and learning material for the revised site note record step.

## Step 017

- Added `SupplierRecord` model as the starting point for supplier and service provider tracking.
- Added tests for supplier values and default active status.
- Added documentation and learning material for the revised supplier record step.

## Step 016

- Added `EquipmentRecord` model as the starting point for equipment and machine tracking.
- Added tests for equipment values and default available status.
- Added documentation and learning material for the equipment record model.

## Step 015

- Added `WorkforceRecord` model as the starting point for crew and workforce tracking.
- Added tests for workforce values and default active status.
- Added documentation and learning material for the workforce record model.

## Step 014

- Added `SiteLocationRecord` model as the starting point for site location and work area tracking.
- Added tests for site location values and default active status.
- Added documentation and learning material for the site location record model.

## Step 013

- Added `ProjectPartyRecord` model as the starting point for project party tracking.
- Added `ContactPersonRecord` model as the starting point for contact person tracking.
- Added tests, documentation, and learning material for project party/contact records.

## Step 012

- Added `DailyReportRecord` model as the starting point for daily site report summaries.
- Added tests for daily report values and default draft status.
- Added documentation and learning material for the daily report summary model.

## Step 011

- Added `RFIRecord` model as the starting point for technical question tracking.
- Added `SubmittalRecord` model as the starting point for technical submission tracking.
- Added tests, documentation, and learning material for RFI/Submittal lite records.

## Step 010

- Added `MeetingRecord` model as the starting point for meeting minutes.
- Added `MeetingActionRecord` model as the starting point for meeting action tracking.
- Added tests, documentation, and learning material for meeting/action record models.

## Step 009

- Added `MaterialRecord` model as the starting point for material entry and usage tracking.
- Added tests for material record values and default status.
- Added documentation and learning material for the material record model.

## 008 Dosya/Ek Arsivleme Baslangici

- `AttachmentRecord` modeli eklendi.
- Dosya/ek arsiv referansi model testi eklendi.
- Adim 008 docs dosyasi olusturuldu.
- Adim 008 learning dosyasi yeni kod bloklu standarda gore olusturuldu.
- `learning/GLOSSARY.md` ve `docs/project_decisions.md` guncellendi.

## 007 Uygunsuzluk Kayitlari

- `NonconformityRecord` modeli eklendi.
- Uygunsuzluk kaydi model testi eklendi.
- Adim 007 docs dosyasi olusturuldu.
- Adim 007 learning dosyasi yeni kod bloklu standarda gore olusturuldu.
- `learning/GLOSSARY.md` ve `docs/project_decisions.md` guncellendi.

## 006 Yapi Denetim Kontrol Cagrilari

- `InspectionRequest` modeli eklendi.
- Yapi denetim kontrol cagrisi model testi eklendi.
- Adim 006 docs dosyasi olusturuldu.
- Adim 006 learning dosyasi yeni kod bloklu standarda gore olusturuldu.
- `learning/GLOSSARY.md` ve `docs/project_decisions.md` guncellendi.

## 005 Beton Dokum ve Numune Takip Baslangici

- `ConcretePour` modeli eklendi.
- `ConcreteSample` modeli eklendi.
- Beton dokum ve numune takip model testleri eklendi.
- Adim 005 docs dosyasi olusturuldu.
- Adim 005 learning dosyasi yeni kod bloklu standarda gore olusturuldu.
- `learning/GLOSSARY.md` ve `docs/project_decisions.md` guncellendi.

## Adim 004 Sonrasi Dokumantasyon ve Repo Sagligi Duzeltmesi

- README guncellendi.
- ROADMAP durumlari tutarli hale getirildi.
- `docs/project_decisions.md` Adim 002-004 ve learning kararlariyla genisletildi.
- `list_records_by_project` geriye uyumluluk karari dokumante edildi.
- CHANGELOG okunabilir sira ile duzenlendi.

## 001 Repo ve Calisma Anlasmalari Duzeltmesi

- Learning dosyasina mini sozluk eklendi.
- `learning/GLOSSARY.md` olusturuldu.
- Yeni teknik terimlerin tanimlanmasi proje kurali haline getirildi.

## 001 Tamamlayici Repo Duzeltmesi

- `ROADMAP.md` eklendi.
- `archive/` klasoru ve `.gitkeep` eklendi.
- Roadmap ve archive terimleri learning sozlugune eklendi.

## 002 Cekirdek Veri Modeli

- Cekirdek veri modelleri olusturuldu.
- Model testleri eklendi.
- Adim 002 dokumantasyonu olusturuldu.
- Learning dosyasi ve sozluk guncellendi.

## 003 Gunluk Saha Kaydi

- `DailySiteLog` modeli eklendi.
- Gunluk saha kaydi model testleri eklendi.
- Adim 003 dokumantasyonu olusturuldu.
- Learning dosyasi ve sozluk guncellendi.

## Learning Standardi

- Learning standardi olusturuldu.
- Learning dosyalarinin yazilim ogretme amaci netlestirildi.
- Yeni terimlerin tanimlanmasi ve `learning/GLOSSARY.md` guncellemesi guclendirildi.

## Learning Standardi Kod Bloklari Duzeltmesi

- Learning standardi kod bloklari uzerinden aciklama yapacak sekilde guclendirildi.
- Learning dosyalarinda test kodu aciklamasi zorunlu hale getirildi.
- Teknik karar tablosu ve kod calisma akisi bolumleri standarda eklendi.

## 004 Listeleme ve Filtreleme Fonksiyonlari

- `app/records.py` icinde basit listeleme ve filtreleme fonksiyonlari eklendi.
- `tests/test_records.py` icinde fonksiyon testleri eklendi.
- `learning/004_listeleme_filtreleme_fonksiyonlari.md` gercek kod bloklari uzerinden yazildi.

## 004 Hizalama Duzeltmesi

- Adim 004 fonksiyon isimleri standartlastirildi.
- `filter_records_by_project_id`, `list_records`, `count_records` ve `filter_records_by_status` yapisi netlestirildi.
- Learning dosyasi yeni kod bloklu standarda gore hizalandi.

## 001-003 Learning Standardi Genisletmesi

- Adim 001, 002 ve 003 learning dosyalari yeni kod bloklu CSE Learning Standardi'na gore genisletildi.
- Eski kisa learning notlari detayli yazilim ogretim dosyalarina donusturuldu.
- `learning/GLOSSARY.md` eksik terimlerle guclendirildi.
