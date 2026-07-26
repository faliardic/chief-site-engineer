# Issue 227 Result — Hatırlatıcı Geri Dönüşüm Kutusu

## Başlangıç

- Resmî repo: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- `master = origin/master = f24e968220c57d6057720ccebe403103ccba17b3`
- Master divergence: `0 0`
- Branch: `codex/issue-227-reminder-trash-restore`
- Başlangıçta tracked/staged değişiklik ve açık PR: `0`
- `device-backups/`, `reports/` ve ignored kullanıcı/build dosyaları
  değiştirilmedi.

## Uygulanan sözleşme

- Mobil schema `8 → 9`, nullable canonical UTC `trashed_at`
- `moveToTrash` / `restoreFromTrash`
- `trashed` / `restored_from_trash` append-only event'leri
- Normal reminder/source read-model dışlaması ve deterministik Trash listesi
- `Sil` confirmation, `Diğer > Geri Dönüşüm Kutusu`, `Geri yükle`
- Status/schedule/outcome/source/link korunumu
- Native cancel ve restore eligibility reconciliation
- Backup format `1`, schema `1–8 → 9`, schema 9 trash/event round-trip

## Doğrulama

- `flutter test --no-pub test/app_database_test.dart`: `18/18 PASS`
- `flutter test --no-pub test/reminder_lifecycle_test.dart`: `22/22 PASS`
- `flutter test --no-pub test/agenda_application_test.dart`: `16/16 PASS`
- `flutter test --no-pub test/mobile_backup_application_test.dart`:
  `28/28 PASS`
- `flutter test --no-pub test/reminder_widget_test.dart`: `25/25 PASS`
- `flutter test --no-pub test/attendance_application_test.dart test/concrete_application_test.dart`:
  `29/29 PASS`
- `flutter analyze --no-pub`: `No issues found`

Migration koşusunda eski schema version sabitleri; lifecycle/widget koşularında
yalnız yeni fixture zaman/scroll düzeni tek dar retry ile düzeltildi. Production
contract çözümü değiştirilmedi.

## Çalıştırılmayan geniş kapılar

Focused zincir ortak regresyon göstermediği için conditional mobile full suite
çalıştırılmadı. Issue talimatıyla Python full suite, Android release gate,
APK/AAB/signing, ARM64/16 KiB, reboot/background acceptance, production RC,
gerçek cihaz restore ve branch içi fiziksel cihaz kabulü çalıştırılmadı.

## Yeniden kullanılan merged kanıt

- PR #223: schema 8, all-day ve backup format 1 temeli
- PR #226: Birleşik Bugün read-modeli
- PR #206: notification engine ve reconciliation
- PR #217: minimum yeterli validation protocol

## Bütçe ve sınırlar

- Validation class: `persistence`
- Primary run: `1`
- Blocking correction: `1` içinde konsolide dar fixture/baseline düzeltmeleri
- Hedef 90 dakika / hard stop 120 dakika aşılmadı.
- Fiziksel/permanent delete, retention, attachment temizliği, source record
  mutation'ı, platform/release scripti ve gerçek kullanıcı data root erişimi
  eklenmedi.

## Publication

Bu dosya pre-publication factual evidence'tir. Commit SHA, remote divergence,
push ve Draft PR bağlantısı Issue #227 completion yorumunda tutulur; metadata
için ikinci commit üretilmez. Merge yapılmaz.
