# Issue #458 Task — Persistent Reference-Schedule Snapshot Foundation

## Yetki ve yürütme kimliği

- Current Issue: https://github.com/faliardic/chief-site-engineer/issues/458
- Owner authorization: https://github.com/faliardic/chief-site-engineer/issues/458#issuecomment-5305832941
- Resmî repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- İzole linked worktree: `V:\1_PROJECTS\2_ACTIVE\Python\CSE-Worktrees\issue-458-schedule-snapshot-20260816T050816999Z`
- Exact base: `df3090eb3c47c39cd77c6a0070fe8384f6b82b08`
- Branch: `codex/issue-458-schedule-snapshot-foundation`
- Validation class: `persistence`
- Task risk: `R4`

```yaml
model_routing:
  policy_version: "CSE-MRP-1.0"
  task_risk: "R4"
  orchestrator:
    chatgpt_model: "gpt-5.6-sol"
    chatgpt_reasoning_effort: "max"
  codex_model: "gpt-5.6-sol"
  codex_reasoning_effort: "max"
  execution_mode: "standard"
  orchestration: "single-agent"
  selection_reason: "SQLite migration, immutable persistence, atomic replacement, fingerprint integrity ve backup/restore uyumluluğu birlikte R4 kapsamındadır."
  routing_request_evidence: "https://github.com/faliardic/chief-site-engineer/issues/458#issuecomment-5305832941"
  allowed_fallback: null
  review_floor:
    chatgpt_model: "gpt-5.6-sol"
    chatgpt_reasoning_effort: "max"
  fail_closed_if_mismatch: true
```

Launch surface invocation ve runtime actual model/reasoning metadata'sını göstermediği için bunlar tahmin edilmeyecek; result kaydında `unknown / null / unverified` kullanılacaktır. Görünür bir uyuşmazlık olursa fail-closed durulur.

## Değişen sözleşmeler

1. Mobile SQLite şeması `13 -> 14` yükselir.
2. Her proje için tek current ve immutable history sağlayan reference-schedule snapshot metadata/activity tabloları eklenir.
3. Persist edilecek schedule, aynı profile/graph/seed girdileriyle mevcut `ConstructionScheduleDateEngine.validateSchedule` sınırından geçer; repository scheduler olmaz.
4. Persisted projection fingerprint'i Issue #458'deki exact alanlar, sıralama ve canonical JSON kurallarıyla belirlenir.
5. Current snapshot replacement tek SQLite transaction içinde atomik olur; ara hata eski current durumu ve bütün satırları geri alır.
6. Current/id/history/date-window read yolları deterministic ve fail-closed olur.
7. Backup envelope/format varsayılan olarak `1` kalır; schema-14 round trip ile schema-13 format-1 restore/migrate uyumluluğu korunur.

## Yetkili dosyalar

Production allowlist:

- `mobile/lib/storage/app_database.dart`
- `mobile/lib/domain/construction_schedule_models.dart` veya tek yeni dar schedule-persistence model dosyası
- `mobile/lib/application/construction_schedule_snapshot_repository.dart`
- `mobile/lib/application/construction_schedule_persistence_application.dart` yalnız gerekirse
- `mobile/lib/application/mobile_backup_application.dart` yalnız gerçek restore uyumluluğu production değişikliği gerektirirse

Test allowlist:

- `mobile/test/app_database_test.dart`
- `mobile/test/construction_schedule_snapshot_repository_test.dart`
- `mobile/test/construction_schedule_date_engine_test.dart` yalnız gerekirse
- `mobile/test/mobile_backup_application_test.dart`
- yalnız gerekirse tek dar migration/restore test dosyası

Evidence allowlist:

- `.cse/tasks/458_task.md`
- `.cse/results/458_result.md`

## Yapılacak iş

- Schema 14 tablolarını, CHECK/FK/unique-current/index/immutability trigger sözleşmelerini eklemek.
- Fresh schema-14 ve 13-to-14 migration davranışını doğrulamak.
- Typed snapshot persistence modellerini mutable living-plan modellerinden ayırmak.
- Validated schedule'ı atomik yeni current snapshot olarak persist etmek.
- Current snapshot, snapshot-by-id, newest-first history ve inclusive date-window overlap sorgularını eklemek.
- Exact canonical persisted projection SHA-256 üretmek ve load sırasında bütün metadata/row/fingerprint invariant'larını fail-closed doğrulamak.
- Mid-insert failure injection ile transaction rollback kanıtlamak.
- Schema-14 backup/restore round trip ve schema-13 format-1 restore ardından schema-14 migration uyumluluğunu gerçek application path üzerinden doğrulamak.
- Corpus/dependency/schedule-seed asset fingerprint drift'ini `0` tutmak.

## Yasak kapsam ve stop koşulları

- Schedule Date Engine dışında ikinci bir scheduling truth veya repository içinde scheduling rule üretmek yasaktır.
- 7 günlük UI, progress/actual, reforecast, productivity learning, duration override, critical path, approved baseline, notifications, Issue #459 veya sonraki slice yasaktır.
- Corpus/dependency/schedule-seed asset değişikliği; `.gitattributes`, `pubspec.yaml`, lockfile, platform/config, unrelated UI ve backup crypto/envelope değişikliği yasaktır.
- Backup format bump sessizce yapılamaz; schema-13 format-1 uyumluluğu korunamazsa fail-closed durulur.
- Allowlist dışı production edit, destructive action, gerçek kullanıcı verisine erişim, routing mismatch veya beklenmeyen worktree değişikliği stop koşuludur.
- `git clean`, reset, stash, force push, Ready ve merge yasaktır.

## Minimum yeterli doğrulama ve sırası

1. Exact base/schema/backup/source fingerprint preflight.
2. Migration ve database focused testleri.
3. Snapshot persistence focused testleri.
4. Schedule Date Engine regression/parity focused testleri.
5. Backup/restore ve backward-compat focused testleri.
6. `dart format --set-exit-if-changed` ve `flutter analyze`.
7. `git diff --check`, allowlist/protected-path ve asset fingerprint drift kontrolü.
8. SQLite integrity/FK kanıtı.
9. Yalnız bütün focused gate'ler PASS olduktan sonra tek full `flutter test`.

APK, cihaz, release, notification, reboot veya platform gate'i çalıştırılmayacaktır; değişen sözleşme UI/platform değildir. Değişmeyen release kanıtları yeniden çalıştırılmayacaktır.

## Bütçeler

- Primary execution: bir birleşik teknik run.
- Blocking correction: en fazla bir correction run.
- Aynı başarısız focused aşama: source/fixture/debug düzeltmesinden sonra en fazla bir tekrar.
- Full suite: focused PASS sonrasında en fazla bir kez; source değişmeden tekrar yok.
- Time budget: R4 persistence görevi Issue'a özgüdür; owner numeric sınır koymamıştır. Yürütme yukarıdaki run/retry sınırlarıyla bounded kalacak, stop koşulunda yeni çözüm zinciri başlatılmayacaktır.

## Yayın izinleri

- Focused ve full doğrulama PASS ise intentional commit ve normal push yetkilidir.
- Draft PR açılacaktır.
- PR Ready yapılmayacak ve merge edilmeyecektir.
- Completion evidence Issue #458'e eklendikten sonra durulacaktır.
- Post-merge sync bu görevde yoktur; merge yetkisi verilmemiştir.
