# Issue 230 Task — Reminder detayında kaynak Ajanda fotoğrafları

- Resmî yerel repo: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Beklenen base: `f3d99ad12f5a7611fbc97023a28bc6bbb508484b`
- Branch: `codex/issue-230-reminder-source-agenda-photos`
- Validation class: `narrow-ui` + read-only domain
- Codex modeli: current full Codex model
- Reasoning seviyesi: extra high
- Seçim nedeni: fail-soft read-model, attachment integrity ve mevcut viewer
  davranışı kullanıcı detay ekranında birlikte korunmalıdır.

## Exact changed-file allowlist

- `.cse/tasks/230_task.md`
- `.cse/results/230_result.md`
- `CHANGELOG.md`
- `ROADMAP.md`
- `docs/230_reminder_source_agenda_photos.md`
- `docs/project_decisions.md`
- `learning/230_reminder_source_agenda_photos.md`
- `mobile/lib/application/agenda_application.dart`
- `mobile/lib/domain/agenda_models.dart`
- `mobile/lib/features/agenda/agenda_photo_viewer_page.dart`
- `mobile/lib/features/agenda/log_detail_page.dart`
- `mobile/lib/features/reminders/reminder_detail_page.dart`
- `mobile/test/agenda_application_test.dart`
- `mobile/test/reminder_widget_test.dart`
- `mobile/test/support/fake_agenda_application.dart`

## Yapılacak iş

- `sourceLogId` taşıyan reminder için test edilebilir, salt-okunur ve fail-soft
  kaynak Ajanda fotoğraf read-modeli
- Aktif fotoğrafların `created_at, id` sırası ve photo ID tekilleştirmesi
- Thumbnail, dosya adı, integrity, boyut ve açıklama sunumu
- Mevcut `AgendaPhotoViewerPage` ve `readAgendaPhoto` yolunun yeniden kullanımı
- Missing/tampered/invalidMime kaydın görünürlüğü ve güvenli viewer diagnostic
- Kaynak okuma hatasında reminder ana detayının açık kalması
- Trash reminder ve arşivli source log davranışının korunması
- Mevcut `Kaynak Ajanda kaydına dön` navigasyonunun korunması

## Yasak kapsam

- Reminder içinden photo add/archive/delete/edit
- Attachment metadata veya byte'ını reminder state/tablosuna kopyalama
- Schema, migration, backup, attachment store veya Android/iOS platform kodu
- Generic attachment v2, PDF/Office/DWG, video, ses, export/paylaşma
- Beton/Puantaj attachment görünürlüğü ve sonraki backlog blokları
- `device-backups/`, `reports/` ve kullanıcıya ait ignored/yerel dosyalar

## Doğrulama

- Focused `agenda_application_test.dart`
- Focused `reminder_widget_test.dart`
- Mevcut Agenda photo thumbnail/viewer yolu için ilgili widget senaryoları
- `flutter analyze --no-pub`
- `git diff --check`
- Exact changed-file allowlist ve protected schema/platform diff kontrolü
- Flutter executable yalnız:
  `C:\Users\Fatih\.cache\flutter-sdk\3.44.6-ee80f08\flutter\bin\flutter.bat`

Focused test ortak regresyon gösterirse mobile Flutter suite yalnız bir kez
çalıştırılabilir. Python full suite, migration/backup restore, Android release,
APK/AAB/signing, ARM64/16 KiB, reboot/background acceptance, production RC ve
branch içi fiziksel cihaz kabulü çalıştırılmaz.

## Bütçe ve Git

- Retry: 1 primary run + en fazla 1 exact blocking correction run
- Süre: hedef 45 dakika, hard stop 75 dakika
- Tek amaçlı commit, normal push ve Draft PR yetkilidir.
- PR body: `Closes #230`, `Parent backlog: #219`, `Depends on #227`
- Merge yasaktır.
- Post-merge sync bu görevde yapılmaz.
