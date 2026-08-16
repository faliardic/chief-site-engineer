# Issue #462 Görev Kaydı — Living 7-Day Plan MVP Core

## Kimlik ve yürütme zemini

- Repository: `faliardic/chief-site-engineer`
- Resmî yerel repository:
  `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- İzole linked worktree:
  `V:\1_PROJECTS\2_ACTIVE\Python\CSE-Worktrees\issue-462-living-plan-mvp-core`
- Branch: `codex/issue-462-living-plan-mvp-core`
- Base branch: `master`
- Exact base: `189d947afbc9dcd78ad57d0724f985a6f3889d37`
- GitHub Issue: https://github.com/faliardic/chief-site-engineer/issues/462
- Owner authorization:
  https://github.com/faliardic/chief-site-engineer/issues/462#issuecomment-5306776142
- Task/result identity: `462`
- Validation class: `persistence / domain application`
- Task risk: `R4`

Exact base, synchronized local/remote `master`, açık production PR yokluğu,
Issue body/izin yorumu ve linked-worktree temizliği read-only preflight ile
doğrulandı. Bu görev kaydı preflight sonrasındaki ilk yerel edittir.

## Model routing

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
  selection_reason: "Schema-15 durable Living Plan decisions, append-only events, optimistic concurrency, trusted schedule references, and backup/restore compatibility are R4 boundaries immediately before the first UI/device slice."
  routing_request_evidence: "https://github.com/faliardic/chief-site-engineer/issues/462#issuecomment-5306776142"
  allowed_fallback: null
  review_floor:
    chatgpt_model: "gpt-5.6-sol"
    chatgpt_reasoning_effort: "max"
  fail_closed_if_mismatch: true
```

Invocation/runtime actual model ve reasoning metadata görünür değildir;
`unknown / null / unverified` semantiği kullanılacaktır. Model tahmin edilmeyecek,
fallback veya downgrade uygulanmayacaktır. Yürütme tek ajandır; delegation yoktur.

## Amaç ve değişen sözleşmeler

- `AppDatabase` schema `14 → 15` additive migration alacaktır.
- Immutable reference schedule ile mutable/evented Living Plan ayrı kalacaktır.
- Living Plan projection satırı, exact persisted snapshot activity ve aynı
  projeye composite referans verecektir; origin/display kolonları immutable,
  physical delete yasak olacaktır.
- Lifecycle eventleri append-only, deterministic payload'lı ve projection ile
  aynı SQLite transaction içinde olacaktır.
- Create, start, complete, defer, reopen ve note update işlemleri optimistic
  revision, exact event-id idempotency, no-op ve clock-regression korumalarıyla
  uygulanacaktır.
- Trusted current snapshot üzerinden yedi günlük suggestion ve Turkish
  name/alias search typed read boundary'leri sağlanacaktır.
- Living seven-day query overdue açık işleri koruyacak ve origin snapshot'ın
  current/superseded durumunu salt-okunur türetecektir.
- Existing item snapshot A'ya bağlı kalacak; snapshot B geldiğinde silent rebind
  olmayacak, stale A ile yeni create fail-closed olacaktır.
- Backup envelope format `1` kalacak; schema-15 round-trip ve format-1
  schema-14 restore/migrate uyumluluğu gerçek backup yolu üzerinden
  doğrulanacaktır.

## Preflight ile daraltılmış exact path allowlist

1. `mobile/lib/storage/app_database.dart`
2. `mobile/lib/domain/construction_living_plan_models.dart` — new
3. `mobile/lib/application/construction_living_plan_application.dart` — new
4. `mobile/lib/application/construction_schedule_snapshot_repository.dart` —
   yalnız trusted window metadata/profile/activity döndüren dar typed helper
5. `mobile/test/app_database_test.dart`
6. `mobile/test/construction_living_plan_application_test.dart` — new
7. `mobile/test/mobile_backup_application_test.dart`
8. `mobile/test/platform_notification_configuration_test.dart` — yalnız stale
   current-schema literal beklentisi
9. `CHANGELOG.md`
10. `docs/project_decisions.md`
11. `learning/issue_462_living_plan_mvp_core.md` — new
12. `.cse/tasks/462_task.md` — new
13. `.cse/results/462_result.md` — new

Read-only preflight, `attachment_schema_migration_test.dart` ve
`project_location_schema_migration_test.dart` içinde stale current-schema
literal beklentisi bulunmadığını gösterdi; bu iki yol allowlist'ten çıkarıldı.
Başka production/test/doc yolu gerekirse edit yapılmadan fail-closed durulacaktır.

## Minimum yeterli doğrulama ve bağlayıcı sıra

1. Task kaydı ilk edit kanıtı.
2. Focused `app_database_test.dart`.
3. Focused `construction_living_plan_application_test.dart`.
4. Existing `construction_schedule_date_engine_test.dart` ve
   `construction_schedule_snapshot_repository_test.dart` regression/parity.
5. Focused gerçek `mobile_backup_application_test.dart`; schema-15 Living Plan
   round-trip ve schema-14 format-1 restore/migrate dahil.
6. Changed Dart dosyaları format.
7. `flutter analyze --no-pub`.
8. `git diff --check`.
9. Exact allowlist/protected-drift classification.
10. SQLite `integrity_check = ok` ve empty `foreign_key_check` kanıtı.
11. Yalnız bütün focused kapılar PASS ettikten sonra final source/test revision
    üzerinde bir kez `flutter test --no-pub`.

Reused merged evidence: exact base PR #461 merge
`189d947afbc9dcd78ad57d0724f985a6f3889d37`; database `22/22`, snapshot
repository `11/11`, Schedule Engine `23/23`, backup/restore `36/36`, full
Flutter `663/663`, analyze/integrity/FK PASS. Değişen schema/application
sözleşmeleri için ilgili focused ve final full kanıtlar yeniden üretilecektir.

Minimum physical-device acceptance: none. UI/platform davranışı değişmediği ve
Issue açıkça yasakladığı için APK/AAB, signing, device, notification, reboot,
release ve store kapıları çalıştırılmayacaktır.

## Retry, süre ve stop sınırı

- Primary implementation: `1`.
- Blocking correction: en fazla `1`.
- Aynı başarısız operation: exact fix sonrasında en fazla `1` retry.
- Target: `45–60` dakika.
- Hard stop: `90` dakika.
- Final full suite: final source revision üzerinde en fazla `1` kez.

Focused test, backup, analyze, integrity/FK, allowlist veya protected-drift
başarısızlığında partial core yayımlanmaz. Additional path, backup format/crypto
değişikliği, schedule/graph/corpus semantic değişikliği, görünür routing
mismatch veya exact base drift halinde commit/push öncesi fail-closed durulur.

## Açık kapsam dışı

- UI/widget/page/route/navigation/bootstrap wiring.
- APK/AAB, physical device, release/store ve notification işi.
- Actual start/finish, quantity, percent complete, reforecast, productivity
  learning, Gantt, critical path/float, approved baseline, resource/AI/cloud.
- Schedule engine, graph/dependency/corpus behavior veya compiled asset değişimi.
- Backup production envelope, format, crypto veya platform değişimi.
- Issue #385 mutation, gerçek kullanıcı DB/backup/attachment/device verisi.
- Immediate UI/APK successor veya başka herhangi bir Slice.

## Publication sınırı

Tüm kapılar PASS olursa yalnız bir intentional commit, normal push, bir Draft
PR ve Issue #462 completion evidence yetkilidir. Evidence; schema/backup test
sayılarını, transition matrixini, snapshot-replacement davranışını, backup
round-trip'i, allowlist/drift'i ve zorunlu `execution_record` ile
`review_recommendation` bloklarını içerecektir. PR Ready yapılmayacak, merge
edilmeyecek ve sonraki Slice başlatılmayacaktır.
