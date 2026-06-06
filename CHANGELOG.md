# Changelog

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
