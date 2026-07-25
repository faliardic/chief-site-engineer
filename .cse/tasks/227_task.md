# Issue 227 Task — Hatırlatıcı geri dönüşüm kutusu

- Resmî yerel repo: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Beklenen base: `f24e968220c57d6057720ccebe403103ccba17b3`
- Branch: `codex/issue-227-reminder-trash-restore`
- Validation class: `persistence`
- Codex modeli: current full Codex model
- Reasoning seviyesi: extra high
- Seçim nedeni: atomik SQLite migration, backup compatibility, optimistic revision, append-only event ve notification reconciliation birlikte değişiyor.

## Yetkili kapsam

- `mobile/lib/storage/app_database.dart`
- Reminder domain/application modelleri
- Reminder detail/list UI
- Mobile backup compatibility
- İlgili focused test ve test support dosyaları
- `CHANGELOG.md`, ilgili docs/learning ve `docs/project_decisions.md`
- Bu task’ın factual result/state kayıtları

## Yapılacak iş

- Schema `8 → 9` atomik migration ve nullable canonical UTC `trashed_at`
- `moveToTrash` / `restoreFromTrash` lifecycle ve append-only event’ler
- Trash kayıtların bütün normal reminder sorgu/count yüzeylerinden dışlanması
- `Diğer > Geri Dönüşüm Kutusu`, `Sil` confirmation ve `Geri yükle`
- Status/schedule/outcome/source link korunumu ve notification cancel/reconciliation
- Backup format `1` korunarak schema `1–8 → 9` restore compatibility ve schema 9 round-trip

## Yasak kapsam

- Fiziksel/permanent delete, retention veya attachment byte temizliği
- Ajanda, Puantaj veya Beton source kaydını değiştirme/silme
- Android/iOS platform implementation veya release scriptleri
- Gerçek kullanıcı data root’u
- Project-level 18.00, Beton timeline ve sonraki backlog blokları
- `device-backups/`, `reports/` ve kullanıcıya ait ignored/yerel dosyalar

## Doğrulama

- Focused app database/migration testleri
- Focused reminder lifecycle/application/read-model testleri
- Focused mobile backup testleri
- Focused reminder widget testleri
- `flutter analyze --no-pub`
- Schema/static API kontrolleri, `git diff --check`, exact changed-file allowlist
- Flutter executable yalnız:
  `C:\Users\Fatih\.cache\flutter-sdk\3.44.6-ee80f08\flutter\bin\flutter.bat`

Conditional mobile full suite yalnız focused testler ortak regresyon gösterirse bir kez çalıştırılabilir.
Python full suite, Android release gate, APK/AAB/signing, ARM64/16 KiB,
reboot/background acceptance, production RC ve branch içi fiziksel cihaz kabulü
çalıştırılmaz.

## Bütçe ve Git

- Retry: 1 primary run + en fazla 1 exact blocking correction run
- Süre: hedef 90 dakika, hard stop 120 dakika
- Tek amaçlı commit, normal push ve Draft PR yetkilidir.
- PR body: `Closes #227`, `Parent backlog: #219`, `Depends on #225`
- Merge yasaktır.
- Post-merge sync bu görevde yapılmaz.
