# Changelog

## Step 082

- Updated `ROADMAP.md` to reflect the real Step 080 safe-point state after the Step 081 README correction.
- Summarized completed Step 001-080 phases and planned Step 081-090 as documentation/standard locking and Step 091-100 as persistence/upload/integrity/operation backbone work.
- Explicitly documented that database, real upload service, API, GUI, auth, CI, and deployment are not present yet.

## Step 081

- Updated `README.md` to reflect the real Step 080 safe-point repository state.
- Clarified that the project is currently a domain model, in-memory repository, test, documentation, learning, and podcast-note core rather than a deployed product.
- Documented the current `125 passed` test result and explicitly listed missing production features such as database, upload service, API, GUI, auth, deployment, and CI.

## Step 080

- Added a closing metadata summary for the `FileAttachmentRecord` attachment line from Step 072-079.
- Summarized usage flow, example scenarios, storage/naming standards, archive safety decisions, and metadata fields such as `original_file_name`, `uploaded_by`, `uploaded_at`, and `notes`.
- No application code, tests, new model field, repository, persistence, SQLite, JSON, API, GUI, CLI, file upload/copy/delete/move, thumbnail, preview, video playback, or streaming behavior was changed in this step.

## Step 079

- Clarified the `FileAttachmentRecord.notes` field for attachment-specific context, warnings, and short site explanations.
- Added tests confirming that attachment notes are stored when provided and default to `None` when omitted.
- No model field change, file upload, physical file copy/delete/move, notes search/filtering, repository, persistence, SQLite, JSON, API, GUI, CLI, thumbnail, preview, video playback, streaming, user/role/permission system, or large service was added in this step.

## Step 078

- Updated `FileAttachmentRecord.uploaded_at` to be optional string metadata with a default value of `None`.
- Added tests confirming that `uploaded_at` is stored when provided and defaults to `None` when omitted.
- No automatic timestamp generation, datetime parsing/formatting, user model, role/permission system, authentication, authorization, file upload, physical file copy/delete/move, repository, persistence, SQLite, JSON, API, GUI, CLI, thumbnail, preview, video playback, or streaming behavior was added in this step.

## Step 077

- Updated `FileAttachmentRecord.uploaded_by` to be optional string metadata with a default value of `None`.
- Added tests confirming that `uploaded_by` is stored when provided and defaults to `None` when omitted.
- No user model, role/permission system, authentication, authorization, file upload, physical file copy/delete/move, repository, persistence, SQLite, JSON, API, GUI, CLI, thumbnail, preview, video playback, or streaming behavior was added in this step.

## Step 076

- Added `original_file_name` as an optional metadata field on `FileAttachmentRecord`.
- Added tests confirming that the original uploaded filename is stored when provided and defaults to `None` when omitted.
- No file upload, physical file copy/delete/move, filename standardization function, repository, persistence, SQLite, JSON, API, GUI, CLI, thumbnail, preview, video playback, or streaming behavior was added in this step.

## Step 075

- Added archive safety and delete/move decision documentation for `FileAttachmentRecord` attachments.
- Documented soft-delete preference, missing file references, move history, no-overwrite guidance, audit trail planning, backup expectations, and video-specific safety notes.
- No application code, tests, new model, repository, file upload/delete/move/copy, SQLite, JSON persistence, API, GUI, CLI, thumbnail, preview, streaming, or video playback behavior was changed in this step.

## Step 074

- Added a storage folder and file naming standard document for `FileAttachmentRecord` attachments.
- Documented proposed attachment folder structure, date-based subfolders, naming template, original filename handling, metadata notes, video-specific rules, and backup/archive considerations.
- No application code, tests, repository, file upload, physical file copy/delete/move, thumbnail, video playback, preview, streaming, SQLite, JSON persistence, API, GUI, or CLI behavior was changed in this step.

## Step 073

- Added example usage scenarios for `FileAttachmentRecord` across concrete pours, NCR records, material deliveries, daily site records, workforce records, chief private notes, and inspection records.
- Reiterated that attachments store file references and metadata, not embedded file contents or video blobs.
- No application code, tests, repository, file upload, physical file copy, file delete/move, thumbnail, video playback, streaming, SQLite, JSON persistence, API, GUI, or CLI behavior was changed in this step.

## Step 072

- Added a usage flow document for `FileAttachmentRecord`.
- Documented how photo, video, PDF, document, and audio attachments can be linked to main records through file references and metadata.
- No application code, tests, repository, file upload, physical file copy, video playback, thumbnail generation, SQLite, JSON persistence, API, GUI, or CLI behavior was changed in this step.

## Step 071

- Added the final NotebookLM podcast note for Step 061-070.
- Summarized the transition from NCR archive/listing documentation to search/filtering behavior and file attachment metadata/reference modeling.
- No application code, tests, repository, file upload, video playback, thumbnail generation, SQLite, JSON persistence, API, GUI, or CLI behavior was changed in this step.

## Step 070

- Added a usage summary for `FileAttachmentRecord.related_record_type` and `related_record_id`.
- Documented how file attachments can link to NCR, site note, daily log, material delivery, inspection, safety observation, concrete pour, and chief private note records.
- No application code, tests, repository, file upload, foreign key, ORM relation, SQLite, JSON persistence, API, GUI, or CLI behavior was changed in this step.

## Step 069

- Documented and tested the basic `FileAttachmentRecord.file_type` classification values: `image`, `video`, `pdf`, `document`, `audio`, and `other`.
- Added model tests showing each file type as metadata/reference, including MIME type and filename examples.
- No model field change, enum, validation, repository, file upload, video playback, thumbnail generation, JSON, SQLite, API, GUI, or CLI behavior was added in this step.

## Step 068

- Added `FileAttachmentRecord` as a dataclass model for photo, video, PDF, document, audio, and other file attachment metadata references.
- Added tests for required values, optional defaults, video metadata representation, and related record linking.
- No repository, file upload, physical file copy, video playback, thumbnail generation, JSON, SQLite, API, GUI, CLI, or persistence behavior was added in this step.

## Step 067

- Added a plan document for file, photo, video, PDF, document, and audio attachments.
- Clarified that video files should not be embedded in the database; only file references and metadata should be stored.
- No application code, tests, JSON, SQLite, API, GUI, CLI, file upload, video playback, thumbnail generation, streaming, or media processing was added in this step.

## Step 066

- Added `NonconformityRepository.list_by_location` for in-memory NCR filtering by `location`.
- Added focused tests for empty repositories, matching locations, missing locations, archived records, and restored records.
- No JSON, SQLite, API, GUI, CLI, query engine, delete behavior, automatic history, or workflow behavior was added in this step.

## Step 065

- Confirmed the existing `NonconformityRepository.list_by_status` behavior as the NCR status filtering behavior.
- Added focused tests for empty repositories, matching statuses, missing statuses, archived records, and restored records.
- No application code, JSON, SQLite, API, GUI, CLI, query engine, delete behavior, automatic history, or workflow behavior was changed in this step.

## Step 064

- Confirmed the existing `NonconformityRepository.find_by_id` behavior as the NCR id lookup behavior.
- Added focused tests for empty repositories, active records, missing ids, archived records, and restored records.
- No application code, JSON, SQLite, API, GUI, CLI, query engine, delete behavior, automatic history, or workflow behavior was changed in this step.

## Step 063

- Added a plan document for future NCR search and filtering behavior in `NonconformityRepository`.
- Outlined possible small steps for id lookup, status filtering, location filtering, text search, archive filtering, date range filtering, and responsible party filtering.
- No application code, tests, JSON, SQLite, API, GUI, CLI, query engine, or workflow behavior was changed in this step.

## Step 062

- Added a concise usage summary for NCR archive and listing behavior from Step 056-060.
- Documented `archive`, `restore`, `list_active`, `list_archived`, `list_all`, and `get_archive_summary` as the core repository usage flow.
- No application code, tests, JSON, SQLite, API, GUI, CLI, or workflow behavior was changed in this step.

## Step 061

- Added the final NotebookLM podcast note for Step 056-060.
- Summarized NCR archive summary, archived listing, active listing, full listing, and archive/listing consistency behavior for podcast production.
- No application code, tests, JSON, SQLite, API, GUI, CLI, or workflow behavior was changed in this step.

## Step 060

- Added an integrated consistency test for `NonconformityRepository` archive, restore, active listing, archived listing, full listing, and archive summary behavior.
- Confirmed that archive and restore keep the full record list intact and do not change `status` values automatically.
- No application code change, delete behavior, JSON, SQLite, API, GUI, CLI, large refactor, automatic history, or workflow was added in this step.

## Step 059

- Confirmed the existing `NonconformityRepository.list_all` behavior as the full NCR listing behavior.
- Added focused tests for empty repositories, active-only repositories, mixed active/archived records, and restore updates preserving the full record list.
- No delete behavior, JSON, SQLite, API, GUI, CLI, large refactor, automatic history, workflow, status change, or archive flag change was added in this step.

## Step 058

- Confirmed the existing `NonconformityRepository.list_active` behavior as the active NCR listing behavior.
- Added focused tests for empty repositories, active-only repositories, mixed active/archived records, and restore updates returning records to active listings.
- No delete behavior, JSON, SQLite, API, GUI, CLI, large refactor, automatic history, workflow, or status change was added in this step.

## Step 057

- Confirmed the existing `NonconformityRepository.list_archived` behavior as the archived NCR listing behavior.
- Added focused tests for empty repositories, active-only repositories, and restore updates removing records from archived listings.
- No delete behavior, JSON, SQLite, API, GUI, CLI, large refactor, automatic history, workflow, or status change was added in this step.

## Step 056

- Added `NonconformityRepository.get_archive_summary` for in-memory active, archived, and total NCR counts.
- Added tests for empty archive summaries, mixed active/archived record counts, and restore updates without changing totals.
- No delete behavior, JSON, SQLite, API, GUI, CLI, dashboard, automatic history, workflow, or status change was added in this step.

## Step 055

- Added `NonconformityRepository.restore` for in-memory restore by setting `is_archived=False`.
- Added tests proving restore returns the updated record, moves it from archived to active filters, preserves status and insert order, and returns `None` for missing ids.
- No model change, JSON, SQLite, API, GUI, CLI, dashboard, file operation, delete, automatic archive, automatic closure, or automatic workflow was added in this step.

## Step 054

- Added `NonconformityRepository.archive` for in-memory archiving by setting `is_archived=True`.
- Added tests proving archiving returns the updated record, moves it from active to archived filters, preserves status and insert order, and returns `None` for missing ids.
- No model change, restore behavior, JSON, SQLite, API, GUI, CLI, dashboard, file operation, delete, automatic closure, or automatic workflow was added in this step.

## Step 053

- Added `NonconformityRepository.list_active` and `NonconformityRepository.list_archived` for in-memory filtering by `is_archived`.
- Added tests proving active and archived records are returned separately, insert order is preserved, and missing archived records return an empty list.
- No model change, JSON, SQLite, API, GUI, CLI, dashboard, file operation, delete, automatic archive, restore, or automatic workflow was added in this step.

## Step 052

- Added `is_archived: bool = False` to `NonconformityRecord` as a small archive marker field.
- Added tests proving the default archive state is `False` and records can be created with `is_archived=True`.
- No repository archive/restore behavior, JSON, SQLite, API, GUI, CLI, dashboard, file operation, delete, or automatic workflow was added in this step.

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
