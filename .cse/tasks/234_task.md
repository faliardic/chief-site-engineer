# Issue 234 Task — Beton Sınıfı ve Döküm Zaman Çizgisi

- Resmî yerel repo: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Beklenen base: `b45e09913a3a306075bcbae14cb958275aef16c1`
- Branch: `codex/issue-234-concrete-class-timeline`
- Validation class: `persistence` + cross-domain vertical slice
- Retry: 1 primary run + en fazla 1 exact blocking correction run
- Süre: hedef 120 dakika, hard stop 180 dakika

## Exact changed-file allowlist

- `.cse/tasks/234_task.md`
- `.cse/results/234_result.md`
- `CHANGELOG.md`
- `ROADMAP.md`
- `docs/234_concrete_class_timeline.md`
- `docs/project_decisions.md`
- `learning/234_concrete_class_timeline.md`
- `mobile/lib/app.dart`
- `mobile/lib/application/agenda_application.dart`
- `mobile/lib/application/concrete_application.dart`
- `mobile/lib/application/mobile_backup_application.dart`
- `mobile/lib/domain/agenda_models.dart`
- `mobile/lib/domain/concrete_models.dart`
- `mobile/lib/features/agenda/agenda_page.dart`
- `mobile/lib/features/agenda/log_detail_page.dart`
- `mobile/lib/features/concrete/concrete_pour_detail_page.dart`
- `mobile/lib/features/concrete/concrete_pour_form_page.dart`
- `mobile/lib/storage/app_database.dart`
- `mobile/integration_test/app_smoke_test.dart`
- `mobile/test/app_database_test.dart`
- `mobile/test/concrete_application_test.dart`
- `mobile/test/concrete_widget_test.dart`
- `mobile/test/mobile_agenda_widget_test.dart`
- `mobile/test/mobile_backup_application_test.dart`

## Uygulama sözleşmesi

- Schema `9 → 10` atomik migration, proje sınıf kataloğu, deterministik legacy
  seed ve composite FK'li paket bağlamı
- Aktif katalog seçimi, dar sınıf ekleme, archive/restore ve snapshot koruması
- Timestamp'ten türeyen üç aşamalı görünüm; idempotent başlat/bitir
- İlk başlangıçta tek yönetilen Ajanda row/event/link; bitişte aynı kaydı
  güncelleme ve bütün adımlarda transaction rollback
- Ajanda detail managed read-only görünümü ve çift yönlü deep-link
- Başlamış legacy paket için idempotent Ajanda repair
- Backup format `1`; schema `1–9 → 10` restore ve schema 10 round-trip

## Doğrulama

- `app_database_test.dart`
- `concrete_application_test.dart`
- `agenda_application_test.dart`
- `concrete_widget_test.dart`
- `mobile_agenda_widget_test.dart`
- `mobile_backup_application_test.dart`
- `flutter analyze --no-pub`
- `git diff --check`
- exact allowlist, schema/static API ve protected platform diff kontrolü

Focused testler ortak regresyon göstermedikçe mobile full suite çalıştırılmaz.
Python suite, Android release gate, APK/AAB/signing, ARM64/16 KiB,
reboot/background, production RC ve fiziksel cihaz kabulü çalıştırılmaz.

Flutter executable yalnız:
`C:\Users\Fatih\.cache\flutter-sdk\3.44.6-ee80f08\flutter\bin\flutter.bat`.

Tek amaçlı commit, normal push ve Draft PR yetkilidir. PR body `Closes #234`,
`Parent backlog: #219`, `Depends on #230` içerir. Merge yasaktır.
