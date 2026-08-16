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

---

## Owner-authorized post-review correction — PR #463

Yetki kaynağı:
https://github.com/faliardic/chief-site-engineer/pull/463#issuecomment-5307016099

Correction parent:
`5d352acec41f65df6d92a56908f043301e65993b`

Owner review iki blocking R4 sözleşme boşluğunu tek dar correction run içinde
kapatma yetkisi vermiştir. PR #463 `Draft` kalacaktır. Bu bölüm original primary
run/task tarihçesini değiştirmez; correction ayrı kaydedilir:

- `review_correction_runs: 1`
- `review_correction_full_suite_runs`: focused kapılar PASS olursa en fazla `1`
- orchestration: `single-agent`
- fallback/downgrade: yok

### Correction routing

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
  selection_reason: "The correction changes durable idempotency semantics and transactional read consistency for the Living Plan source-of-truth immediately before UI/device integration."
  routing_request_evidence: "https://github.com/faliardic/chief-site-engineer/pull/463#issuecomment-5307016099"
  allowed_fallback: null
  review_floor:
    chatgpt_model: "gpt-5.6-sol"
    chatgpt_reasoning_effort: "max"
  fail_closed_if_mismatch: true
```

Invocation/runtime actual model ve reasoning metadata görünür değildir;
canonical `unknown / null / unverified` değerleri kullanılacak, tahmin veya
downgrade yapılmayacaktır.

### Değişen correction sözleşmeleri

1. Her kabul edilen command, no-op dahil, immutable/append-only durable receipt
   ile event ID'sini aynı shared conflict namespace içinde rezerve eder.
2. Exact receipt replay, current projection daha sonra ilerlese bile original
   exact returned result'i mutation olmadan döndürür; farklı item/type/intent
   aynı ID ile `living_plan_event_id_conflict` verir.
3. No-op projection revision'ını ve lifecycle-event sayısını değiştirmez.
4. Receipt, applicable projection/event mutation ve returned-result
   doğrulaması tek SQLite transaction içinde atomiktir.
5. `loadLivingPlanItem`, `listLivingPlanEventHistory` ve `loadSevenDayPlan`
   projection/history okumalarını aynı `DatabaseExecutor` kullanan minimum read
   transaction içinde tek coherent SQLite snapshot'tan üretir.
6. Schema `15`, backup format `1`, public domain contracts ve immutable
   reference-schedule davranışı değişmez.

### Exact correction allowlist

Correction parent'e göre yalnız şu yedi yol değişebilir:

1. `mobile/lib/storage/app_database.dart`
2. `mobile/lib/application/construction_living_plan_application.dart`
3. `mobile/test/app_database_test.dart`
4. `mobile/test/construction_living_plan_application_test.dart`
5. `mobile/test/mobile_backup_application_test.dart`
6. `.cse/tasks/462_task.md`
7. `.cse/results/462_result.md`

Sekizinci yol gerekirse edit/commit/push yapılmadan fail-closed durulacaktır.
Schedule snapshot repository/engine, public Living Plan domain modeli, backup
production/envelope/crypto, UI/platform/config/dependency/workflow, canonical
docs/learning/roadmap, Issue #385 ve successor Slice protected kalır.

### Correction validation ve stop sınırı

Final corrected source revision üzerinde bağlayıcı sıra:

1. Changed Dart format.
2. Focused database/migration; receipt constraint/immutability/delete guard,
   cross-namespace conflict, integrity/FK dahil.
3. Focused Living Plan; no-op receipt/replay/conflict/rollback ve coherent
   concurrent-read regressions dahil.
4. Unchanged Schedule Date Engine `23/23` ve snapshot repository `11/11`.
5. Real backup/restore; schema-14 → 15 ve no-op receipt roundtrip/replay dahil.
6. `flutter analyze --no-pub`.
7. `git diff --check`.
8. Exact seven-file correction allowlist, protected/extra drift `0`, schema
   `15`, backup format `1`, integrity `ok`, empty FK check.
9. Yalnız bütün focused kapılar PASS olursa bir additional correction full
   `flutter test --no-pub`; üçüncü full run yasaktır.

Aynı failed operation exact fix sonrasında en fazla bir kez retry edilebilir.
Focused failure, tekrar bütçesi aşımı, sekizinci path ihtiyacı, schema/version/
envelope drift'i veya yeni R4 contradiction durumunda correction commit/push
yapılmadan durulur.

### Correction publication sınırı

PASS halinde existing branch üzerinde tek intentional correction commit ve
normal push yetkilidir. Exact Issue/PR evidence; correction parent/head,
seven-file correction set, total PR set, focused/full counts, receipt/replay/
conflict/rollback, coherent reads, backup/schema-14 migration, integrity/FK,
protected drift ile zorunlu `execution_record` ve `review_recommendation`
bloklarını taşıyacaktır. PR Draft kalacak; Ready, merge, UI/APK/device, Item 5
completion veya başka Slice yapılmayacaktır.
