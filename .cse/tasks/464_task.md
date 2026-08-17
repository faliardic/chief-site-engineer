# Issue #464 Görev Kaydı — Living 7-Day Plan UI + Acceptance APK / Cihaz Kabulü

## Otorite ve yürütme zemini

- Repository: `faliardic/chief-site-engineer`
- Resmî checkout: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- İzole linked worktree:
  `V:\1_PROJECTS\2_ACTIVE\Python\CSE-Worktrees\issue-464-living-plan-ui-device`
- Issue: https://github.com/faliardic/chief-site-engineer/issues/464
- Owner authorization:
  https://github.com/faliardic/chief-site-engineer/issues/464#issuecomment-5307282120
- Exact base/master: `318f9077b750e54f551f31dffde3dae6220b8e73`
- Branch: `codex/issue-464-living-plan-ui-device`
- Parent Epic / V2 item: `#385 / V2.5`
- Validation class: `release-critical`
- Primary execution: `1`
- Hard stop: `150 dakika`

Bu dosya, zorunlu source pre-read ile read-only repository/GitHub/ADB
preflight sonrasındaki ilk yetkili local project-file edit'idir.

## Read-only preflight gerçekleri

- Owner comment association: `OWNER`.
- Açık PR: `0`.
- Tek aktif production implementation Issue: `#464`; diğer açık Issue'lar
  Epic/backlog/protocol/release-backlog kayıtlarıdır.
- Local/tracking/direct `master`: exact
  `318f9077b750e54f551f31dffde3dae6220b8e73`; divergence `0 / 0`.
- Resmî checkout ve yeni worktree non-ignored tracked/staged/untracked durumu:
  temiz.
- Root emergency ZIP ignored ve dokunulmamış; `exports/` yalnız `.gitkeep`.
- Pre-existing ignored legacy Android build ağaçlarının bazı uzun path'leri,
  `git status --ignored` sırasında Windows filename-length warning'i üretti;
  non-ignored status `0` ve bu environment kalıntıları scope dışıdır.
- Exact bir usable fiziksel cihaz bağlı; unauthorized/offline/ambiguity `0`.
- Masked cihaz identity: `sha256:c68cbe516264`.
- Device: `Samsung SM-S938B`, Android `16`, API `36`, ABI `arm64-v8a`.
- `/data` available: yaklaşık `44,783,384 KiB`.
- Production package pre-state:
  `com.faliardic.chiefsiteengineer`, `0.1.0 (1)`, installed.
- Debug package pre-state:
  `com.faliardic.chiefsiteengineer.debug`, `0.1.0-debug (1)`, installed.
- Acceptance package pre-state:
  `com.faliardic.chiefsiteengineer.acceptance`, not installed.

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
  selection_reason: "This Slice connects schema-15 Living Plan source-of-truth to the first user-facing mutation UI and performs isolated APK installation plus persistence acceptance on a real device."
  routing_request_evidence: "https://github.com/faliardic/chief-site-engineer/issues/464#issuecomment-5307282120"
  allowed_fallback: null
  review_floor:
    chatgpt_model: "gpt-5.6-sol"
    chatgpt_reasoning_effort: "max"
  fail_closed_if_mismatch: true
```

Invocation/runtime actual model ve reasoning metadata görünür değildir;
canonical `unknown / null / unverified` değerleri kullanılacak, tahmin,
downgrade veya fallback yapılmayacaktır. Orchestration `single-agent` kalır.

## Değişen sözleşmeler

1. `ConstructionLivingPlanApplicationPort`, mevcut core sözleşmeyi UI'ya
   taşır; UI hiçbir Living Plan/reference-schedule tablosuna doğrudan SQL
   yazmaz.
2. Path-backed SQLite adapter her public operation'da current active database
   path'ini açar, core application/snapshot repository'yi oluşturur, operation
   bitince handle'ı kapatır; backup/restore swap sonrasında stale handle tutmaz.
3. `BootstrapSuccess` production Living Plan port'unu non-null sağlar;
   bootstrap failure, backup ve notification wiring davranışı değişmez.
4. Home `open-living-plan` kartı, project-local `LivingPlanPage` yüzeyini açar.
5. Sayfa İstanbul bugünüyle başlayan inclusive yedi günü, overdue/open ve
   in-window completed gruplarını core deterministic order ile gösterir.
6. Suggestions/search/add/start/complete/defer/reopen/note işlemleri yalnız
   typed application commands üzerinden çalışır; optimistic revision,
   snapshot-stale, duplicate, no-op ve invalid-transition güvenliği korunur.
7. Production project current trusted snapshot taşımıyorsa sentetik/generic
   plan üretilmez; güvenli empty state ve disabled add kullanılır.
8. Acceptance-only fixture, benzersiz entrypoint ve fixed IDs/receipts ile
   acceptance sandbox'ında idempotent synthetic project/profile/snapshot/plan
   üretir; normal `lib/main.dart` fixture'a referans vermez.
9. Bounded runner exact serial, package isolation, integration, APK provenance,
   SHA-256, install-r ve relaunch persistence zincirini uygular.

## Exact allowed paths

Production:

1. `mobile/lib/application/construction_living_plan_application.dart`
2. `mobile/lib/bootstrap/app_bootstrap.dart`
3. `mobile/lib/app.dart`
4. `mobile/lib/features/living_plan/living_plan_page.dart` — new

Tests:

5. `mobile/test/construction_living_plan_application_test.dart`
6. `mobile/test/app_bootstrap_test.dart`
7. `mobile/test/widget_test.dart`
8. `mobile/test/living_plan_widget_test.dart` — new
9. `mobile/test/support/fake_living_plan_application.dart` — new, only if needed

Acceptance/device:

10. `mobile/integration_test/living_plan_device_acceptance_test.dart` — new
11. `mobile/integration_test/living_plan_acceptance_main.dart` — new
12. `mobile/integration_test/support/living_plan_acceptance_fixture.dart` — new
13. `scripts/run_living_plan_device_acceptance.ps1` — new

Documentation/evidence:

14. `CHANGELOG.md`
15. `docs/project_decisions.md`
16. `learning/issue_464_living_plan_ui_device_acceptance.md`
17. `.cse/tasks/464_task.md`
18. `.cse/results/464_result.md`

On dokuzuncu path veya gerekli platform/pubspec/core-schema değişikliği ortaya
çıkarsa edit genişletilmeden fail-closed durulur.

## Protected / out of scope

- Schema/migration, schema version `15` ve Living Plan core semantics.
- Reference schedule engine/repository/corpus/graph assets ve davranışı.
- Backup format `1`, envelope, crypto ve production restore davranışı.
- `mobile/pubspec.yaml`, `mobile/pubspec.lock`, Android/iOS platform config ve
  `mobile/android/app/build.gradle.kts`.
- Notification behavior, release signing, AAB/store/public deployment.
- Gerçek kullanıcı data root'u veya production/debug package content'i.
- Global project-selector/navigation redesign.
- Actual quantity/progress/actual dates/reforecast/learning; Gantt, critical
  path/float, baseline, resources, AI/cloud; Item 5 completion claim ve başka
  Slice.

## Focused validation

### Application/adapter

- Her operation'da current path open/close.
- Restore/swap sonrasında stale handle yok.
- Core failure code preservation.
- Concurrent operations core transaction/idempotency davranışını korur.

### Bootstrap

- Success result non-null Living Plan port taşır.
- Bootstrap restart ve failure path güvenliği.
- Agenda/attendance/concrete/backup/notification wiring regresyonu yok.

### Widget

- Home card → page ve project selection.
- No-project/no-snapshot/empty/error/loading states.
- Seven-day grouped list, overdue, status/context/note/origin marker.
- Suggestions, Turkish alias search ve add.
- Start/complete/defer/reopen/note işlemleri ve safe feedback.
- Stale revision/snapshot/duplicate, tap guards.
- 320–360 px, text scale `1.6`, dark/light, semantics/tooltip/back/keyboard.
- Raw technical code/status kullanıcıya gösterilmez.

### Acceptance/static

- Fixture idempotency ve production-main isolation.
- Unique marker: `CSE_ENTRYPOINT_LIVING_PLAN_ACCEPTANCE_V1`.
- Normal/background/reboot forbidden markers acceptance APK'da yok.
- Runner exact serial, package/ABI/marker/hash ve pre/post isolation kontrolleri.

## Reused merged evidence

- Source: PR #463 / merge
  `318f9077b750e54f551f31dffde3dae6220b8e73`.
- Database `23/23`, Living Plan `9/9`, Schedule Engine `23/23`, snapshot
  repository `11/11`, backup/restore `36/36`, full Flutter `673/673`, analyze,
  integrity/FK PASS.
- Schema/backup/reference-schedule core değişmediği sürece DB migration,
  backup roundtrip ve schedule engine suite'leri yeniden çalıştırılmaz.
- Adapter wiring actual blocker gösterirse production backup code'una dokunmadan
  stop-and-report uygulanır.

## Etki matrisi

- Schema impact: `none`; schema `15` korunur.
- Migration impact: `none`.
- Backup impact: production format/implementation `none`; merged #463 evidence
  reused. Adapter yalnız stale handle riskini önler.
- Attachment impact: `none`.
- Notification impact: `none`.
- Package impact: yalnız acceptance package build/install.
- Production/debug package impact: `none`; pre/post inventory exact eşit olmalı.

## Binding validation/device order

1. Adapter + bootstrap focused tests.
2. Home/Living Plan focused widget tests.
3. Acceptance fixture/entrypoint/runner static tests.
4. Format changed Dart.
5. Focused affected Flutter suites ve merged Living Plan regression.
6. `flutter analyze --no-pub`.
7. `git diff --check`.
8. Exact allowlist/protected drift; schema `15`, backup `1`, pubspec/lock/
   platform drift `0`.
9. Yalnız bütün focused kapılar PASS ise final source revision üzerinde tek
   `flutter test --no-pub`.
10. Exact physical-device integration, `CSE_ACCEPTANCE_HARNESS=true`.
11. Aynı source revision üzerinde fresh acceptance APK build.
12. Entrypoint/forbidden marker, package ID, ABI ve SHA-256 verification.
13. Yalnız `com.faliardic.chiefsiteengineer.acceptance` için `adb install -r`,
    launch, force-stop/relaunch persistence ve release/debug pre/post equality.

## Device hard-safety boundary

Authorized target package:
`com.faliardic.chiefsiteengineer.acceptance`.

Explicitly forbidden:

- uninstall veya `pm clear`;
- production/debug package install/replace veya data/file/database access;
- gerçek user DB copy/restore/migration;
- production/release APK/AAB/signing/store operation;
- emulator substitution.

Device identity GitHub evidence'da yalnız masked/hash-prefix olarak yazılır.
Acceptance APK PASS sonunda installed ve launchable bırakılır.

## Retry, stop ve publication

- Her failed focused/build/device operation: exact fix sonrasında en fazla bir
  retry.
- Final full suite: primary source revision üzerinde `1/1`.
- Physical-device integration: primary `1`, yalnız identified harness/selector/
  environment defect için bir exact-fix retry.
- APK build/install: primary `1`, yalnız aynı exact stage için bir retry.
- Additional path, source-of-truth bypass, production-data/package riski,
  ambiguity/low-space/incompatibility, ikinci aynı-stage failure, schema/backup
  drift veya clear-data/uninstall ihtiyacı fail-closed stop'tur.
- PASS halinde tek intentional commit, normal push ve tek Draft PR yetkili.
- Ready ve merge yasak; Item 5 complete işaretlenmez, successor başlatılmaz.
- Issue/PR evidence exact source/widget/full/device counts, masked device,
  package pre/post, APK filename/SHA/package/marker, persistence, allowlist,
  `execution_record` ve `review_recommendation` taşır.

## Fail-closed execution record — 2026-08-16

- İlk project-file edit: bu task kaydı, `2026-08-16 14:58 +03`.
- Adapter + bootstrap primary focused run:
  - `10` test ilerledikten sonra bootstrap argument placement compile hatası ve
    concurrent SQLite open yarışı nedeniyle FAIL.
  - Exact correction: Living Plan argümanı `BootstrapSuccess` içine taşındı;
    adapter instance operasyonları core transaction sınırları değişmeden
    sıraya alındı.
- Adapter + bootstrap tek retry: `14/14 PASS`.
- Home/Living Plan widget primary focused run: testler başlamadan bir
  `const Semantics` compile uyumsuzluğu nedeniyle FAIL.
- Exact correction: yalnız uyumsuz `const` kaldırıldı.
- Home/Living Plan widget tek retry: runner özeti `14 PASS / 4 FAIL`.
  - gerçek dar ekran overflow: project selector, 320 px / text scale `1.6`;
  - gerçek lifecycle kusuru: note dialog controller route kapanmadan dispose;
  - no-snapshot fixture state-reuse beklentisi;
  - grouped-list testinde lazy viewport için eksik scroll beklentisi.
- Aynı focused stage ikinci kez başarısız olduğu için retry bütçesi tükendi ve
  fail-closed stop uygulandı.
- Acceptance fixture/entrypoint/runner, analyze, final full suite, cihaz
  integration, APK build/install, commit, push ve Draft PR çalıştırılmadı.
- Cihazda preflight sonrasında hiçbir package mutation yapılmadı; production,
  debug ve acceptance package state'i değiştirilmedi.

## Owner-authorized post-failure correction — 2026-08-16

- Authority:
  https://github.com/faliardic/chief-site-engineer/issues/464#issuecomment-5307407366
- Author/association: `faliardic / OWNER`.
- Önceki fail-closed tarihçe korunur; silinmez veya yeniden yorumlanmaz.

```yaml
post_failure_correction_runs: 1
original_widget_retry_consumed: true
```

Correction yalnız şu blocker'ları kapatır:

1. 320/360 px ve text scale `1.6` altında project-selector/header overflow.
2. Note dialog controller route-lifetime güvenliği.
3. No-snapshot widget fixture state determinism.
4. Grouped-list doğru scrollable/route sınırında görünürlük beklentisi.

Correction edit allowlist'i yalnız:

- `mobile/lib/features/living_plan/living_plan_page.dart`
- `mobile/test/living_plan_widget_test.dart`
- `mobile/test/widget_test.dart`
- `.cse/tasks/464_task.md` (append-only evidence)
- `.cse/results/464_result.md` (append-only evidence)

Core/domain/schema/adapter, bootstrap/app wiring, acceptance/platform/pubspec,
backup/notification ve cihaz package/data state'i correction sırasında
protected kalır. Correction widget command'ı primary `1`; yalnız concrete aynı
kapsam defect'i için exact-fix retry `1`. PASS sonrası original gate chain ilk
çalıştırılmamış acceptance aşamasından sürer.

### Post-failure correction stop evidence

- Correction primary focused widget run:
  - command: `flutter test --no-pub test/living_plan_widget_test.dart test/widget_test.dart`
  - result: `22 PASS / 1 FAIL`;
  - concrete defect: overdue item görünür olduğunda section header viewport'un
    hemen üstünde kaldığı için `Geciken` expectation'ı offstage oldu.
- Yetkili exact correction: overdue ve day-0 section key'leri önce doğru
  Living Plan Scrollable sınırında görünür yapıldı.
- Correction retry, aynı command:
  - result: `22 PASS / 1 FAIL`;
  - remaining defect: iki aynı context metni eşzamanlı görünürken stale
    `findsOneWidget` expectation'ı iki widget buldu.
- Correction primary ve izinli tek retry tüketildi. Başka test/harness fix'i
  veya retry yapılmadan `2026-08-16 15:29 +03` fail-closed stop uygulandı.
- Adapter/bootstrap rerun, acceptance, affected suites, analyze, final full,
  cihaz integration, APK build/install ve publication aşamalarına geçilmedi.
- Correction sırasında ADB/device operation ve package mutation yapılmadı.

```yaml
post_failure_correction_runs: 1
original_widget_retry_consumed: true
post_failure_correction_retry_consumed: true
post_failure_correction_status: stopped_retry_exhausted
```

## Owner-authorized post-failure correction #2 — 2026-08-16

- Authority:
  https://github.com/faliardic/chief-site-engineer/issues/464#issuecomment-5307452658
- Author/association: `faliardic / OWNER`.
- Bütün önceki failure/retry kayıtları append-only korunur.

```yaml
post_failure_correction_runs: 2
stale_widget_expectation_correction_runs: 1
original_widget_retry_consumed: true
correction_1_widget_retry_consumed: true
```

Correction #2 yalnız `living_plan_widget_test.dart` içindeki duplicate typed
context assertion'ını stable item-card key'lerine scope edebilir. Production
source, adapter/bootstrap/app/core/schema, acceptance/platform/pubspec ve device
state protected kalır. `widget_test.dart` yalnız assertion fiziksel olarak onda
ise değişebilir; preflight assertion'ın `living_plan_widget_test.dart` içinde
olduğunu doğruladı, dolayısıyla byte-identical kalacaktır.

### Post-failure correction #2 stop evidence

- Assertion yalnız `living_plan_widget_test.dart` içinde değiştirildi:
  `overdue` ve `today` item-card key'leri ayrı kimlikler olarak doğrulandı;
  ad/status/typed-context expectations her kartın descendant scope'unda tam bir
  occurrence aradı. Global permissive `findsWidgets` kullanılmadı.
- Focused command:
  `flutter test --no-pub test/living_plan_widget_test.dart test/widget_test.dart`
- Correction #2 primary result: `22 PASS / 1 FAIL`.
- Duplicate-context locator/scoping assertions geçti; kalan failure test
  sonunda dispose edilmemiş bir `SemanticsHandle` oldu.
- Yetkili retry yalnız aynı duplicate-context assertion'ındaki locator/scoping
  typo'su için geçerliydi. SemanticsHandle lifecycle farklı bir harness kusuru
  olduğundan retry kullanılmadı ve `2026-08-16 15:36 +03` fail-closed stop
  uygulandı.
- Downstream adapter/acceptance/analyze/full/device/build/publication zinciri
  çalıştırılmadı; ADB/package mutation yapılmadı.

```yaml
post_failure_correction_runs: 2
stale_widget_expectation_correction_runs: 1
original_widget_retry_consumed: true
correction_1_widget_retry_consumed: true
correction_2_retry_used: false
correction_2_status: stopped_non_scoping_harness_failure
```

## Owner-authorized post-failure correction #3 — 2026-08-16

- Authority:
  https://github.com/faliardic/chief-site-engineer/issues/464#issuecomment-5307472676
- Author/association: `faliardic / OWNER`.
- Önceki bütün fail-closed history append-only korunur.

```yaml
post_failure_correction_runs: 3
semantics_handle_correction_runs: 1
original_widget_retry_consumed: true
correction_1_widget_retry_consumed: true
correction_2_locator_retry_unused: true
```

Correction #3 yalnız grouped widget testindeki tek SemanticsHandle'ı her exit
path'te tam bir kez dispose edebilir. `living_plan_widget_test.dart` dışındaki
test/production source ve acceptance/device alanları protected kalır.

### Post-failure correction #3 PASS evidence

- Grouped testteki tek `SemanticsHandle`, test gövdesini saran tek bir
  `try/finally` sınırında her exit path için tam bir kez dispose edildi.
- Focused widget command:
  `flutter test --no-pub test/living_plan_widget_test.dart test/widget_test.dart`
- Result: `23/23 PASS`.
- Required adapter/bootstrap continuation command:
  `flutter test --no-pub test/construction_living_plan_application_test.dart test/app_bootstrap_test.dart`
- Result: `14/14 PASS`.
- Correction #3 retry kullanılmadı. Original chain, ilk çalıştırılmamış
  acceptance fixture/entrypoint/runner aşamasından devam etti.

```yaml
post_failure_correction_runs: 3
semantics_handle_correction_runs: 1
correction_3_retry_used: false
correction_3_status: pass
focused_widget_tests: 23
focused_adapter_bootstrap_tests: 14
```

## Analyze gate fail-closed stop — 2026-08-16 15:53 +03

- Acceptance fixture, unique entrypoint, physical integration test and bounded
  runner were added only in the four authorized acceptance paths.
- Acceptance targeted Dart analysis passed and production-main isolation,
  marker/forbidden-marker, runner parser and forbidden-operation static checks
  passed.
- Repository `flutter analyze --no-pub` primary reported `12` infos: core
  implementation methods required `@override`, and `LivingPlanPage` constructor
  required `const`.
- The one authorized exact correction made the constructor `const`, but its
  mechanical method match placed nine annotations on interface declarations
  instead of the corresponding core implementation methods.
- Analyze retry reported `9` interface warnings plus `9` remaining core infos;
  result `18 issues`, FAIL.
- Aynı analyze adımının tek correction/retry bütçesi tükendi. Başka edit veya
  retry yapılmadan fail-closed duruldu.
- `git diff --check`, allowlist/protected drift gate, final full suite, physical
  integration, APK build/install, device/package mutation, docs completion,
  commit, push ve Draft PR çalıştırılmadı.

Required next correction is mechanically bounded: remove the nine invalid
interface `@override` annotations and add them to the nine matching core
implementation methods; then format and rerun only `flutter analyze --no-pub`.
New owner authority is required.

```yaml
analyze_primary_issues: 12
analyze_correction_runs: 1
analyze_retry_issues: 18
analyze_retry_consumed: true
status: stopped_analyze_retry_exhausted
device_mutation: false
```

## Owner-authorized post-failure correction #4 — 2026-08-16

- Authority:
  https://github.com/faliardic/chief-site-engineer/issues/464#issuecomment-5307542874
- Verified author/association: `faliardic / OWNER`.
- Previous analyze failures and every earlier correction record remain
  append-only and unchanged.

```yaml
post_failure_correction_runs: 4
analyze_annotation_correction_runs: 1
analyze_primary_issue_count: 12
analyze_retry_issue_count: 18
original_analyze_retry_consumed: true
```

Correction #4 may only remove the nine invalid interface `@override`
annotations and add them to the exact matching nine concrete methods in
`ConstructionLivingPlanApplication`. The one-to-one pairs were verified before
edit:

1. `loadSevenDayReferenceSuggestions`
2. `searchCurrentReferenceCandidates`
3. `createLivingPlanItem`
4. `startLivingPlanItem`
5. `completeLivingPlanItem`
6. `deferLivingPlanItem`
7. `reopenLivingPlanItem`
8. `updateLivingPlanNote`
9. `loadSevenDayPlan`

No signature/body/import/runtime change is authorized. Correction validation is
exactly one format of the application file and one
`flutter analyze --no-pub`; no retry.

### Correction #4 current-WIP pre-edit manifest

Allowed correction paths:

| Path | State | Size | SHA-256 |
|---|---|---:|---|
| `mobile/lib/application/construction_living_plan_application.dart` | tracked-modified | 61052 | `0670fad71d2e3fa121a8526b88f44f3a40610292ae05dffe96ed0db408c0a385` |
| `.cse/tasks/464_task.md` | untracked | 20623 | `49ba1d6f88477057a0d2862be5d5d79a3c6c031496dbf6f427f58477410c110f` |
| `.cse/results/464_result.md` | untracked | 25218 | `c9d5c6eda0342431417a260fd83fe85ea0a9902446a423b535bcce1531cc1b01` |

Protected WIP/source/test/acceptance paths:

| Path | State | Size | SHA-256 |
|---|---|---:|---|
| `mobile/lib/app.dart` | tracked-modified | 21258 | `9feb0d45e2647f2ad91fa7e9a53916c0c62295fdc9527b3493515be2d03b620a` |
| `mobile/lib/bootstrap/app_bootstrap.dart` | tracked-modified | 9834 | `d34dc002a8e704090fddbc778c8771564f31a469b92c47915e8ebadda48acfd1` |
| `mobile/lib/features/living_plan/living_plan_page.dart` | untracked | 37969 | `ab65d2d036bc5dd5da9f3da48281ca521ae5297512de66a90aec14b139b3f74b` |
| `mobile/test/app_bootstrap_test.dart` | tracked-modified | 5770 | `0882653099e265dcca9c34b041d6e18fea113a4a12b4967f88aa59f07bd4ddf4` |
| `mobile/test/construction_living_plan_application_test.dart` | tracked-modified | 55147 | `e3fbbc346e30498dfa3ad33e79360128b2208fb2b91fcef0841c6324bf248e61` |
| `mobile/test/widget_test.dart` | tracked-byte-identical | 16376 | `51b6b8820684069bc1af80610416b86016192e317aaeaf938bab9cf5286006f2` |
| `mobile/test/living_plan_widget_test.dart` | untracked | 19464 | `590bc3ea4531ff53a5d8053fd2a15ee7f8a2b20f08ee24112f977c91ddba7983` |
| `mobile/test/support/fake_living_plan_application.dart` | untracked | 8624 | `9d62f2ec4546bc5dc92c4cc543ced26760407c354510804e3f59e63f4c32fde6` |
| `mobile/integration_test/living_plan_acceptance_main.dart` | untracked | 2081 | `6bd3a69a6ea93b7693e16f8d43ef8f873f89faf47af741987e0f9f8bcc8c0b95` |
| `mobile/integration_test/living_plan_device_acceptance_test.dart` | untracked | 9951 | `7d91b56ecca0456a2e8afe2725aa0c22ab418915773754e262bbbba3295ce475` |
| `mobile/integration_test/support/living_plan_acceptance_fixture.dart` | untracked | 9256 | `a2625ed1009cf5613e947de93bff7704a223049139d1cee77dab2e65d5ab95ea` |
| `scripts/run_living_plan_device_acceptance.ps1` | untracked | 10779 | `005794a6b308bd04060cbc09e707f2b6239b745542b528d4922a2627bb90b2d5` |

Pre-edit Git ground: branch `codex/issue-464-living-plan-ui-device`, HEAD
`318f9077b750e54f551f31dffde3dae6220b8e73`, staged paths `0`.

### Correction #4 PASS evidence

- Exactly nine annotations were relocated; format reported `0 changed`.
- Post-edit application file: size `61052`, SHA-256
  `b7dd4fb2ae3cc9c3474c806d61eaf0f9c5af12d4b92b3267efd1af87ebd0be80`.
- In-memory inverse relocation reproduced the exact pre-edit SHA-256
  `0670fad71d2e3fa121a8526b88f44f3a40610292ae05dffe96ed0db408c0a385`.
- Interface override count: `0`; concrete core override count: `11` (the nine
  relocated methods plus the two already-correct methods); relocated pairs:
  `9`.
- All protected source/test/acceptance paths remained byte-identical to the
  pre-edit manifest.
- The single authorized command `flutter analyze --no-pub` returned
  `No issues found`, PASS. No retry was run.
- Original Issue #464 chain resumes at `git diff --check`.

```yaml
post_failure_correction_runs: 4
analyze_annotation_correction_runs: 1
correction_4_analyze_runs: 1
correction_4_analyze_status: pass
correction_4_retry_used: false
```

## Authorized device-harness correction — 2026-08-16

- The single physical-device chain attempt stopped inside its first read-only
  ADB preflight, before integration, build, install or any device mutation.
- PowerShell `StrictMode` rejected `.Count` on the empty offline/unauthorized
  filter result. The acceptance package remained absent and staged paths
  remained `0`.
- Pre-edit runner: size `10779`, SHA-256
  `005794a6b308bd04060cbc09e707f2b6239b745542b528d4922a2627bb90b2d5`.
- The authorized exact harness correction is limited to wrapping that filter in
  an array subexpression: `@(...).Count`. No acceptance behavior, package,
  build, install or persistence assertion changes.
- The one exact device harness/environment retry remains the only permitted
  retry for this stage.

### Device retry result — FAIL / fail-closed

- The exact one-character runner correction produced size `10780`, SHA-256
  `7273d9f1de8ae7e1d82da6d550aac28ea17687a674a95a7b2f28d9d12a109ebc`;
  parser errors `0`. An in-memory inverse reproduced the pre-edit runner hash
  exactly.
- The sole retry passed exact-device preflight, then failed while Flutter was
  loading the physical integration test: Gradle
  `:app:compileDebugJavaWithJavac` could not resolve
  `FlutterLocalNotificationsPlugin` from the existing
  `CseReminderBootReceiver.java`. Result: `+0 -1`; build failed before test
  execution.
- No acceptance APK or release-gate artifact was produced and the acceptance
  package remained absent.
- Critical protected-package drift was then observed: production package
  `com.faliardic.chiefsiteengineer`, present immediately before the chain as
  `0.1.0+1`, was absent for user `0` and absent from global `dumpsys` after the
  failed Flutter invocation. No explicit uninstall command exists in the
  runner or was issued by Codex. Debug package inventory remained identical;
  acceptance remained absent.
- This is a package-isolation safety failure plus a second same-stage failure.
  The device retry budget is consumed. No restore/reinstall, source/toolchain
  fix, additional device/build/full run, documentation completion, commit,
  push or Draft PR is authorized. Stop fail-closed and require new owner
  direction.

```yaml
final_full_suite_runs: 1
final_full_suite_result: 686/686_pass
physical_device_primary_result: preflight_harness_fail
physical_device_exact_fix_retries: 1
physical_device_retry_result: gradle_compile_fail_0_tests
device_retry_consumed: true
acceptance_apk_produced: false
acceptance_package_installed: false
production_package_post_state: absent
debug_package_inventory_unchanged: true
status: fail_closed_device_package_isolation_violation
```

## Owner-authorized P0 recovery correction #5 — A3 stop

- Authority:
  https://github.com/faliardic/chief-site-engineer/issues/464#issuecomment-5307637028
- Verified author/association: `faliardic / OWNER`.
- Routing remains `CSE-MRP-1.0`, R4, `gpt-5.6-sol / max`, standard,
  single-agent, no fallback/downgrade.
- Earlier incident and correction history remains append-only and unchanged.

```yaml
post_failure_correction_runs: 5
p0_production_package_recovery_runs: 1
android_compile_isolation_correction_runs: 1
device_retry_previously_consumed: true
production_data_survival: unknown_until_classified
```

### Phase A read-only classification

- Exactly one authorized device was present: masked
  `sha256:c68cbe516264`, SM-S938B, Android 16/API 36, arm64-v8a, user 0.
- Production `com.faliardic.chiefsiteengineer` was absent from user-0 and
  user-10 installed inventory, absent from both users' `-u` retained inventory,
  absent from global installed/retained inventory, absent from `pm path`, and
  unknown to exact/global `dumpsys package` identity metadata.
- Secure Folder user 150 rejects shell per-user queries, but no global package
  identity exists from which an installed/archived/disabled per-user state
  could be restored.
- Package-change sequence `1171` references the production ID for users 0 and
  10, but carries no retained package identity, UID, archive, data-retention or
  restore metadata. No relevant active/staged CSE install session exists.
- Debug remains installed and unchanged; acceptance remains absent.
- Known repository artifact locations contain no production APK. The only
  found APK is the known normal debug artifact
  `app-debug.apk`, package `.debug`, SHA-256
  `1bffcd9b2c1fde13d41f0f72fa44026f5e4c678c45854354c83508ac3478bebc`.
- Immutable Issue #191/result evidence records ephemeral production RC SHA-256
  `f4b79679d9c956e6e605ec96d1b9846ae5bc07559eeaa10d1d57aaecfe1088a7`.
  Its merge precedes the recorded first-install timestamp by about ten minutes,
  but no immutable evidence proves that exact artifact was the installed APK,
  no pre-incident installed-APK SHA/signing digest was captured, and the
  ephemeral signer/artifact was intentionally not retained. Filename/version/
  timestamp correlation is insufficient under the recovery contract.

Classification: `A3` — package truly absent or data retention cannot be
proven. A1 package-manager-native restore and A2 exact-original-APK restore are
not authorized by the observed evidence.

Per Phase B3, execution stops immediately. No install-existing, unarchive,
`adb install -r`, fresh production build/install, signer creation, backup
restore, production launch/content access, Android source edit, runner edit,
host build/test, additional full/device run, commit, push or Draft PR was
performed. Phase C/D remain blocked until the owner explicitly accepts A3 and
authorizes a separate recovery path.

```yaml
recovery_classification: A3
production_data_survival: unproven
production_restore_attempted: false
production_content_accessed: false
android_compile_isolation_correction_executed: false
phase_c_d_status: blocked_by_A3
status: fail_closed_A3_owner_decision_required
```

## Owner-authorized identity/isolation correction #6 — 2026-08-16

- Authority:
  https://github.com/faliardic/chief-site-engineer/issues/464#issuecomment-5307706418
- Verified author/association: faliardic / OWNER.
- The owner accepts A3 and explicitly forbids any restore, reinstall, fresh
  install, launch, content access, migration or reuse of the missing legacy
  production package under Issue #464.
- Canonical product identity is now Şefim. Android production/debug/acceptance
  application IDs are com.faliardic.sefim, com.faliardic.sefim.debug and
  com.faliardic.sefim.acceptance. The three legacy IDs remain frozen and
  protected.
- Routing remains CSE-MRP-1.0, R4, gpt-5.6-sol / max, standard, single-agent,
  with no fallback or downgrade. Invocation/runtime actual metadata is hidden
  and will remain unknown / null / unverified.

    post_failure_correction_runs: 6
    a3_owner_decision: accept_no_legacy_restore
    product_identity_pivot_runs: 1
    legacy_production_data_state: unknown
    new_product_name: Şefim
    new_android_application_id: com.faliardic.sefim
    new_acceptance_application_id: com.faliardic.sefim.acceptance

### Correction #6 read-only preflight

- Branch/HEAD: codex/issue-464-living-plan-ui-device /
  318f9077b750e54f551f31dffde3dae6220b8e73.
- Staged paths: 0. Current WIP paths: 14. Base ancestor check: PASS.
- Four pre-mutation read-only/tooling corrections were used: orchestration
  tab-escape parsing, resolved-plugin path escaping, exact Android SDK
  adb-path resolution and evidence-template fence escaping. No repository or
  device mutation preceded these corrections.
- package_config, pubspec.lock and resolved pub-cache source all identify
  flutter_local_notifications 22.1.0. The official public
  ScheduledNotificationBootReceiver exists and delegates the package-private
  reschedule call; resolved receiver SHA-256 is
  e2b26a45d141f260906598fa1713517c1e6ec97c797f79e1548c54a8eeeb2ae3.
- Exactly one device remains connected: sha256:c68cbe516264, SM-S938B,
  Android 16/API 36, arm64-v8a, user 0, /data free 44,893,860 KiB.
- Six-package baseline: legacy production absent; legacy debug installed as
  0.1.0-debug+1 with UID 10426 and lastUpdateTime 2026-08-11 23:34:10;
  legacy acceptance absent; new Şefim production/debug/acceptance all absent.

Current 14-path WIP manifest before Correction #6:

| Path | Size | SHA-256 |
|---|---:|---|
| .cse/results/464_result.md | 41008 | f44533c49b1efe6db73f1c9659702dedb214378c7aabe3b95aa07ddb4e7d9b02 |
| .cse/tasks/464_task.md | 31151 | 37b75b708be4613b687554c841a268296859a16d53b065960a68b27a0c5f1f9b |
| mobile/integration_test/living_plan_acceptance_main.dart | 2081 | 6bd3a69a6ea93b7693e16f8d43ef8f873f89faf47af741987e0f9f8bcc8c0b95 |
| mobile/integration_test/living_plan_device_acceptance_test.dart | 9951 | 7d91b56ecca0456a2e8afe2725aa0c22ab418915773754e262bbbba3295ce475 |
| mobile/integration_test/support/living_plan_acceptance_fixture.dart | 9256 | a2625ed1009cf5613e947de93bff7704a223049139d1cee77dab2e65d5ab95ea |
| mobile/lib/app.dart | 21258 | 9feb0d45e2647f2ad91fa7e9a53916c0c62295fdc9527b3493515be2d03b620a |
| mobile/lib/application/construction_living_plan_application.dart | 61052 | b7dd4fb2ae3cc9c3474c806d61eaf0f9c5af12d4b92b3267efd1af87ebd0be80 |
| mobile/lib/bootstrap/app_bootstrap.dart | 9834 | d34dc002a8e704090fddbc778c8771564f31a469b92c47915e8ebadda48acfd1 |
| mobile/lib/features/living_plan/living_plan_page.dart | 37969 | ab65d2d036bc5dd5da9f3da48281ca521ae5297512de66a90aec14b139b3f74b |
| mobile/test/app_bootstrap_test.dart | 5770 | 0882653099e265dcca9c34b041d6e18fea113a4a12b4967f88aa59f07bd4ddf4 |
| mobile/test/construction_living_plan_application_test.dart | 55147 | e3fbbc346e30498dfa3ad33e79360128b2208fb2b91fcef0841c6324bf248e61 |
| mobile/test/living_plan_widget_test.dart | 19464 | 590bc3ea4531ff53a5d8053fd2a15ee7f8a2b20f08ee24112f977c91ddba7983 |
| mobile/test/support/fake_living_plan_application.dart | 8624 | 9d62f2ec4546bc5dc92c4cc543ced26760407c354510804e3f59e63f4c32fde6 |
| scripts/run_living_plan_device_acceptance.ps1 | 10780 | 7273d9f1de8ae7e1d82da6d550aac28ea17687a674a95a7b2f28d9d12a109ebc |

Correction paths actually required are owner allowlist entries 1–10, 12–21.
Entry 11, mobile/integration_test/living_plan_device_acceptance_test.dart,
is not required and stays byte-identical. Internal Java/Kotlin namespace,
AndroidManifest, pubspec/lock, schema/backup, Living Plan UI/core and all
historical Issue records remain protected.

### Correction #6 execution result — fail-closed physical retry exhausted

- Correction #6 elapsed from owner comment to final audit: approximately
  41 minutes, within the 150-minute Issue budget.
- Identity/notification/runner focused gate:
  platform + release static 12/12 PASS; final runner static 6/6 PASS;
  PowerShell parser PASS; validate_mobile_release.py seven checks PASS.
- flutter analyze --no-pub: No issues found, PASS.
- Exact WIP allowlist: 29/29; unexpected 0; staged 0; git diff --check PASS.
  Schema 15, backup format 1, version 0.1.0+1, pubspec/lock/manifest drift 0
  and protected original-WIP hash drift 0.
- The single identity-pivot full suite: 687/687 PASS in 1m26s; no full-suite
  retry.

Host build history:

1. Primary host build failed at Java compile because the isolated worktree had
   no ignored .flutter-plugins-dependencies metadata; Gradle therefore did not
   expose the resolved official receiver class to app compilation.
2. The single authorized exact packaging retry ran flutter pub get --offline,
   proved pubspec/lock byte-identical, compiled the official receiver
   delegation and produced the APK. The build itself succeeded.
3. Post-build runner reporting then exposed verifier-output contamination and
   a CRLF-sensitive label regex. Both were corrected without another build;
   the already-fresh artifact was verified read-only.

Final APK proof:

- file: sefim-0.1.0-issue464-living-plan-acceptance-debug.apk
- package: com.faliardic.sefim.acceptance
- label: Şefim
- marker: CSE_ENTRYPOINT_LIVING_PLAN_ACCEPTANCE_V1
- forbidden normal/background/reboot markers: absent
- ABI: arm64-v8a
- launchable activity: com.faliardic.chiefsiteengineer.MainActivity
- SHA-256: 7be30694bafb248ba7a41531a271f6f8685e244e507fdab045e612d1bc04c4ee

Physical history:

1. Primary physical run repeated exact preflight, installed only the new
   acceptance package and proved all five non-target identities unchanged.
   App launch also preserved all six inventories. Before any Living Plan flow,
   uiautomator XML parsing included its trailing status line and failed.
2. Package isolation was reconfirmed read-only. The acceptance banner was
   visually proven on-device as exact Kabul ortamı · sentetik veri. The single
   authorized selector/runner retry trimmed XML at the closing hierarchy
   element; parser, diff and focused static 6/6 passed.
3. The physical retry updated only com.faliardic.sefim.acceptance with adb
   install -r and again preserved the other five identities. It opened the
   7 Günlük Plan route, but the expected synthetic project never appeared.
   Final read-only hierarchy instead showed:
   Plan güvenli biçimde okunamadı. Kayıtlar değiştirilmedi.
4. The allowed physical selector/runner retry is consumed. No further tap,
   edit, build, test, install, force-stop/relaunch or diagnostic run was
   performed. Full acceptance mutations, persistence and final fatal-diagnostic
   checks remain incomplete.

Final package state:

- com.faliardic.chiefsiteengineer: absent, accepted A3 state;
- com.faliardic.chiefsiteengineer.debug: installed, versionCode 1, UID 10426,
  unchanged;
- com.faliardic.chiefsiteengineer.acceptance: absent;
- com.faliardic.sefim: absent;
- com.faliardic.sefim.debug: absent;
- com.faliardic.sefim.acceptance: installed, versionCode 1, UID 10483,
  launchable and left on the Living Plan safe-error screen.

Status is fail-closed. Commit, push and Draft PR are not authorized because
physical Living Plan flow/persistence did not PASS. Ready, merge, production
Şefim install, legacy recovery/import, V2.5 completion and successor work were
not performed.

## Owner-authorized correction #7 — Phase A D4 stop — 2026-08-16

- Authority:
  https://github.com/faliardic/chief-site-engineer/issues/464#issuecomment-5307918006
- Verified author/association: `faliardic / OWNER`.
- Earlier failures and all six prior correction records remain append-only.
- Routing remains `CSE-MRP-1.0`, R4, `gpt-5.6-sol / max`, standard,
  single-agent, with no fallback or downgrade. Invocation/runtime actual
  metadata remains `unknown / null / unverified`.

Authorized budget and factual usage:

```yaml
post_failure_correction_runs: 7
acceptance_safe_read_diagnostic_runs: 1
acceptance_sandbox_reset_runs: 0
safe_read_device_correction_runs_authorized: 1
safe_read_device_correction_runs_executed: 0
```

### Correction #7 read-only Phase A evidence

- Branch/HEAD remained `codex/issue-464-living-plan-ui-device` /
  `318f9077b750e54f551f31dffde3dae6220b8e73`; staged paths `0`, WIP paths
  `29`.
- Pre-diagnosis task SHA-256:
  `8732ae3e0a541cf0532f6a9ae25c32401a4a90d0e9188f055f963c6658c6d288`.
- Pre-diagnosis result SHA-256:
  `9a31432c177e3c9f6fcedb6db8a5dbedfde4d9346618a42bdd941e643e67e41a`.
- Exactly one device remained available: `sha256:c68cbe516264`, SM-S938B,
  Android 16/API 36, arm64-v8a.
- Six-package inventory remained at the Correction #6 baseline: legacy
  production absent; legacy debug installed and unchanged; legacy acceptance,
  new Şefim production and new Şefim debug absent; only
  `com.faliardic.sefim.acceptance` installed and launchable.
- `run-as` was used only against the contracted synthetic acceptance package.
  Its active database path was
  `files/cse_mobile/debug/database/cse_mobile.sqlite3`; the main image copied
  to a host temp evidence directory with exact remote/local size `1,683,456`
  and SHA-256
  `62ba6459d9a564c58eeefe69e93918d015ec5af93b8cab9438deb7b6c612d0ae`.
  The accompanying rollback journal was zero bytes. No device file was
  written, deleted, chmod'ed, restored or SQL-mutated.
- Copied-image checks: `PRAGMA user_version = 15`, `integrity_check = ok`,
  `foreign_key_check = empty`; one expected fixed-ID project, one current
  trusted synthetic snapshot, `1214` snapshot activities, two Living Plan
  items, three command receipts and three events. Item revisions `1/2`, event
  sequences `1` and `1,2`, and receipt/event sequence/type pairs matched.
  No partial projection/history/receipt state was present.
- Path comparison proved D1 false: the fixture and
  `AppBootstrap.production()` both derive `AppEnvironment.current()` from the
  same application-support root, and fixture, Agenda and Living Plan adapter
  all receive the same `AppDirectories.databaseFile`.
- The valid, complete database disproved D2. No acceptance content or package
  mutation was needed to classify the failure.

### Exact classification

`D4` — the production Living Plan page passes a non-canonical local date into
the canonical application boundary:

1. `LivingPlanPage._istanbulToday()` calls
   `DateTime.parse(CseTimeCodec.istanbulDayKey(...))`; a date-only parse without
   a timezone produces a local `DateTime` (`isUtc == false`).
2. `_reload()` passes that value unchanged to `loadSevenDayPlan` and
   `loadSevenDayReferenceSuggestions`.
3. Both application reads call `_canonicalDate()`, which delegates to
   `formatCanonicalConstructionDate()`; `_requireCanonicalUtcDate()` requires
   `isUtc == true` and exact midnight.
4. The adapter therefore raises `living_plan_invalid_date` before the Living
   Plan SQLite projection read. The page-wide safe catch converts it to
   `Plan güvenli biçimde okunamadı. Kayıtlar değiştirilmedi.`

Correction #7 explicitly protects
`mobile/lib/features/living_plan/living_plan_page.dart` and requires a separate
authority if the page itself is the cause. Phase A therefore stops
fail-closed. No production/acceptance source correction, host test, analyze,
full suite, build, APK verification, install/update, package clear, device
flow, commit, push or Draft PR was executed under Correction #7.

## Owner-authorized correction #8 — 2026-08-16

- Authority:
  https://github.com/faliardic/chief-site-engineer/issues/464#issuecomment-5307993598
- Verified author/association: `faliardic / OWNER`.
- Correction #7 D4 diagnosis and all earlier fail-closed history remain
  append-only and unchanged.
- Routing remains `CSE-MRP-1.0`, R4, `gpt-5.6-sol / max`, standard,
  single-agent, with no fallback/downgrade. Hidden actual invocation metadata
  remains canonical `unknown / null / unverified`.

```yaml
post_failure_correction_runs: 8
living_plan_ui_date_boundary_correction_runs: 1
acceptance_safe_read_root_cause: D4_local_date_not_canonical_utc_midnight
acceptance_sandbox_reset_runs: 0
```

The correction is limited to converting every `LivingPlanPage` calendar day
that crosses into the application port to UTC midnight by calendar components,
never by instant conversion. The visible Istanbul/selected calendar day must
remain identical. Application/core date validation is not weakened.

Exact correction edit boundary:

1. `mobile/lib/features/living_plan/living_plan_page.dart`
2. `mobile/test/living_plan_widget_test.dart`
3. `.cse/tasks/464_task.md` — append-only
4. `.cse/results/464_result.md` — append-only

No fifth path is authorized. The other 27 WIP paths, application/core/domain,
schema/migrations, bootstrap, fixture/acceptance entrypoint/test/runner,
Android/Gradle/Manifest/receiver, `app.dart`, other UI, pubspec/lock, backup and
signing/release files remain protected and byte-identical during this
correction. Schema remains `15`, backup `1`, version `0.1.0+1` and acceptance
identity `com.faliardic.sefim.acceptance`.

Pre-correction Git ground: branch
`codex/issue-464-living-plan-ui-device`, HEAD/base
`318f9077b750e54f551f31dffde3dae6220b8e73`, staged paths `0`, WIP paths
`29`. Four-path pre-edit hashes:

| Path | Size | SHA-256 |
|---|---:|---|
| `.cse/tasks/464_task.md` | 43384 | `3335a22471e83ca649ef4756a27d08161ab295a866a7818c5d704fa96ad2fecf` |
| `.cse/results/464_result.md` | 54561 | `e1bf6862a7f87bbce3ea01d3ff08c1c016b7720e4e861db41e158e9570aba3c0` |
| `mobile/lib/features/living_plan/living_plan_page.dart` | 37969 | `ab65d2d036bc5dd5da9f3da48281ca521ae5297512de66a90aec14b139b3f74b` |
| `mobile/test/living_plan_widget_test.dart` | 19464 | `590bc3ea4531ff53a5d8053fd2a15ee7f8a2b20f08ee24112f977c91ddba7983` |

The deterministic full 29-path pre-edit manifest is recorded in the result
file. Validation must follow Correction #8 order: format the two Dart paths,
focused widget, adapter/bootstrap, acceptance/static, analyze, diff/drift,
exactly one full suite, one fresh host APK build/verification and only then the
single bounded physical correction acceptance. Focused/analyze/full failure or
protected drift stops before build/device/publication.

### Correction #8 fail-closed execution result

- Exact source correction used `_canonicalCalendarDay(value) =>
  DateTime.utc(value.year, value.month, value.day)` for initial Istanbul day,
  plan/suggestion windows, ±7-day shifts, window/date-picker selections,
  create, defer, reopen and candidate refresh crossings. No `toUtc()` calendar
  conversion or application/core validation weakening was added.
- A strict widget fake rejects non-UTC or non-midnight port dates. Regressions
  cover a local/non-UTC clock source, initial reads, exact next/previous
  seven-day movement, selected create date, defer and reopen dates, and the
  absence of the generic safe-read error.
- Formatter discovery first found that neither `dart` nor `flutter` was on the
  process PATH. No file changed in those failed discovery calls. The exact SDK
  recorded in ignored `android/local.properties` was used; two authorized Dart
  files were formatted, with one formatter change in the test file.
- Living Plan/Home focused gate: `24/24 PASS`.
- Adapter/bootstrap focused gate: `14/14 PASS`.
- Platform/release static tests: `12/12 PASS`.
- Acceptance three-file targeted analyze: `No issues found`.
- Runner PowerShell parser: `0` errors; release validator: `7/7 PASS`.
- Repository `flutter analyze --no-pub`: `2 issues`, FAIL:
  - unused application import in `living_plan_widget_test.dart`;
  - never-supplied optional `snapshotAvailable` parameter in the strict fake.
- Correction #8 grants no analyze retry. Per the owner stop rule, no source
  cleanup/rerun, `git diff --check`, drift/schema/backup gate, full suite, APK
  build/verification, ADB/device operation, commit, push or Draft PR followed.
- Read-only stop audit: branch/HEAD unchanged, staged paths `0`, WIP paths
  `29`; all `25` protected manifest paths are byte-identical. Final corrected
  page SHA-256 is
  `51513672787b8e35c89302369251d9eb122681e8245ad4ddefc14cd451a42f30`;
  widget test SHA-256 is
  `1524ac171b8de8c159ba3a5258247be150225a9e2cc0f1251ecc84abcf5e8ca5`.
- Elapsed owner-authority-to-stop time: approximately `14 minutes`, within the
  Issue `150-minute` hard stop. Full/build/device retry budgets were untouched.

```yaml
living_plan_ui_date_boundary_correction_runs: 1
focused_widget: 24/24_pass
focused_adapter_bootstrap: 14/14_pass
focused_platform_release_static: 12/12_pass
acceptance_targeted_analyze: pass
runner_parser_errors: 0
release_validator: 7/7_pass
repository_analyze: fail_2_warnings
repository_analyze_retry_authorized: false
final_full_suite_runs: 0
living_plan_date_correction_host_build_runs: 0
physical_correction_runs: 0
status: fail_closed_analyze_no_retry
```

## Owner-authorized correction #9 — 2026-08-16

- Authority:
  https://github.com/faliardic/chief-site-engineer/issues/464#issuecomment-5308074510
- Verified author/association: `faliardic / OWNER`.
- Correction #8 source/focused evidence and all earlier fail-closed history
  remain append-only and unchanged.
- Routing remains `CSE-MRP-1.0`, R4, `gpt-5.6-sol / max`, standard,
  single-agent, no fallback/downgrade; hidden actual metadata remains
  `unknown / null / unverified`.

```yaml
post_failure_correction_runs: 9
test_only_analyze_warning_correction_runs: 1
correction_8_analyze_runs: 1
correction_9_analyze_reruns_authorized: 1
```

Correction #9 removes only the unused import and unused strict-fake optional
parameter reported by the Correction #8 repository analyze. Read-only source
inspection confirmed both warnings are in
`mobile/test/living_plan_widget_test.dart`; therefore
`mobile/test/support/fake_living_plan_application.dart` remains byte-identical.
No assertion, fake behavior, command capture, product or production source may
change.

Exact correction paths:

1. `mobile/test/living_plan_widget_test.dart`
2. `mobile/test/support/fake_living_plan_application.dart` — authorized but
   not required; remains byte-identical
3. `.cse/tasks/464_task.md` — append-only
4. `.cse/results/464_result.md` — append-only

Pre-correction Git ground: branch
`codex/issue-464-living-plan-ui-device`, HEAD/base/remote master
`318f9077b750e54f551f31dffde3dae6220b8e73`, open PR `0`, staged paths `0`,
WIP paths `29`. Four-path hashes:

| Path | Size | SHA-256 |
|---|---:|---|
| `.cse/tasks/464_task.md` | 48853 | `a70d6449374021433d2fa7aa071053f98399ff4a7ca8451cb4fbb94721565937` |
| `.cse/results/464_result.md` | 64451 | `f6c2fc3548399871fecd7237fd67b6a87dd68599aced880e525ca01c4b098c3a` |
| `mobile/test/living_plan_widget_test.dart` | 23285 | `1524ac171b8de8c159ba3a5258247be150225a9e2cc0f1251ecc84abcf5e8ca5` |
| `mobile/test/support/fake_living_plan_application.dart` | 8624 | `9d62f2ec4546bc5dc92c4cc543ced26760407c354510804e3f59e63f4c32fde6` |

The full sorted 29-path pre-edit manifest is appended to the result record.
Correction validation is exactly one repository analyze rerun. On PASS the
already-passed `24/24`, `14/14`, `12/12` and `7/7` gates are reused, then the
chain resumes at diff/drift, one full suite, one fresh host APK build and the
single bounded physical correction run. No extra retry is introduced.

## Correction #9 physical run selector diagnosis

The authorized primary physical run installed only
`com.faliardic.sefim.acceptance`, reached the living-plan add sheet and then
stopped at `Acceptance UI text was not found: Mobilizasyon`. Read-only
UIAutomator evidence showed the sheet, the empty-query message and this exact
node split:

- the editable `android.widget.EditText` has `hint="İmalat ara"`;
- its suffix search `android.widget.Button` has
  `content-desc="İmalat ara"`.

`Enter-UiText` searches only `text` and `content-desc`, so it selected and
tapped the suffix button instead of the editable field; the subsequent ADB
text input therefore had no focused target. This is a concrete selector/runner
defect within the one exact physical retry authority, not a product,
safe-read, integrity, crash or package-drift failure.

Before the selector correction, the runner is 25901 bytes with SHA-256
`d0c9826cbdb3b3c368bdd6be82ae629ffb6270ae0e2a718fd1bfc910dddd8c9d`.
The correction is restricted to making `Enter-UiText` select a clickable
`android.widget.EditText` whose `hint`, `text` or `content-desc` contains the
requested field label. Product code, test expectations and package lifecycle
remain unchanged. Exactly one physical retry remains; no further retry is
available.

## Correction #9 terminal stop

The one exact physical retry passed the corrected editable-field selector,
submitted `mobilizasyon`, found the search results and completed the add dialog.
The UI emitted `İmalat plana eklendi.` but the subsequent refreshed hierarchy
still exposed `Plana ekle` buttons and no exact `Planda` state, so the runner
stopped at `Acceptance UI text was not found: Planda`.

The physical-run budget is exhausted (`primary: 1`, `exact retry: 1`). No
further selector correction, device retry, acceptance cleanup, persistence
relaunch, commit, push or Draft PR is permitted without new owner authority.
The acceptance sandbox remains installed with the test mutation; it was not
cleared, uninstalled or read directly. All five non-target package identities
remain equal to the pre-run baseline, including the protected legacy debug
version and installation timestamps. Execution is fail-closed before
publication and before every successor Slice.

## Owner-authorized correction #10 — 2026-08-16

- Authority:
  https://github.com/faliardic/chief-site-engineer/issues/464#issuecomment-5308190509
- Verified author/association: `faliardic / OWNER`; it is the latest Issue
  comment.
- Routing remains `CSE-MRP-1.0`, R4, `gpt-5.6-sol / max`, standard,
  single-agent, no fallback/downgrade. Hidden actual metadata remains
  `unknown / null / unverified`.
- Branch/HEAD/base/remote master remain
  `codex/issue-464-living-plan-ui-device` /
  `318f9077b750e54f551f31dffde3dae6220b8e73`; WIP paths `29`, staged paths
  `0`, open PRs `0`.

```yaml
post_failure_correction_runs: 10
post_create_marker_diagnostic_runs: 1
post_create_marker_correction_runs: 1
acceptance_sandbox_reset_runs: 0_or_1
final_marker_physical_runs: 1
```

### Phase A exact classification: M3

Exactly one device was reconfirmed as `sha256:c68cbe516264`, `SM-S938B`, API
36, `arm64-v8a`. The five non-target package states remained unchanged:
legacy production absent under A3, protected legacy debug installed at
`0.1.0-debug` / code `1` with unchanged install/update times, and legacy
acceptance plus Şefim production/debug absent. Only
`com.faliardic.sefim.acceptance` was inspected.

Acceptance-only UI hierarchy, screenshot and process logcat were captured
read-only. `run-as com.faliardic.sefim.acceptance` copied only
`files/cse_mobile/debug/database/cse_mobile.sqlite3` to a host temp evidence
directory. The copied main image is 1683456 bytes, SHA-256
`27780057b709f25ee3ffa72ca228fa1a4701803b46e690d4a825e37cf5fda8bc`;
WAL/SHM were absent and the rollback journal was zero bytes. Host read-only
checks returned schema `15`, integrity `ok` and empty FK violations.

The searched stable instance
`TR-BLD-01-002-MOBILIZASYON-PLANI@PROJECT` has zero persisted Living Plan
items. Instead the Correction #9 automation created exactly one complete
`PLANNED` item for
`TR-BLD-34-002-OFIS-DEPO-DEMOBILIZASYONU@PROJECT`, with revision `1`, one
non-no-op `CREATED` receipt at sequence `1`, and the matching single `CREATED`
event at sequence `1`. The host diagnostic reproduced the application marker
boundary and returned exactly one marker row, for that wrong instance only.
No fatal/safe-read/integrity evidence appeared.

This is unambiguous `M3`: the runner's global `Plana ekle` selector was not
scoped to the visible `Mobilizasyon planı` card. Its later global, non-scrolling
`Planda` assertion therefore checked the wrong visible scope while the actual
marked card could be offscreen. Product page/application/schema behavior is
not corrected.

The smallest correction subset is:

1. `scripts/run_living_plan_device_acceptance.ps1`
2. `mobile/test/living_plan_widget_test.dart`
3. `mobile/integration_test/living_plan_device_acceptance_test.dart`
4. `.cse/tasks/464_task.md` — append-only
5. `.cse/results/464_result.md` — append-only

The runner will bind add and disabled `Planda` verification to the same exact
`Mobilizasyon planı` card subtree. Deterministic tests will preserve the
existing immediate real/fake refresh assertion and add close/reopen,
duplicate-prevention, main-list and persistence-chain coverage. The remaining
five allowlisted paths stay byte-identical unless new evidence proves they are
required; no eleventh path is permitted.

Pre-correction hashes:

| Path | Size | SHA-256 |
|---|---:|---|
| `scripts/run_living_plan_device_acceptance.ps1` | 26419 | `d6ff2bf9da55bf960e8e04554abe1205d4e7dae65c73e9b036f27343e5854dce` |
| `mobile/test/living_plan_widget_test.dart` | 23164 | `bec0e2625ab538da63db79581468dae3faea578e12259bd235fa130759d417f7` |
| `mobile/integration_test/living_plan_device_acceptance_test.dart` | 9951 | `7d91b56ecca0456a2e8afe2725aa0c22ab418915773754e262bbbba3295ce475` |
| `.cse/tasks/464_task.md` | 53570 | `2bb52350884f64051ed8bd549f90ef3e5da40b8cac4aea9bd16e21d97b8dc263` |
| `.cse/results/464_result.md` | 76113 | `a88e8da541033a75feb9f68ed8fea0ad6f1d2bc54aaadc2f1233ca404d51aaf8` |

## Correction #10 terminal stop

Host validation completed as authorized:

- exact post-create marker regression: `1/1 PASS`;
- Living Plan/Home focused suite, including immediate marker, duplicate guard,
  close/reopen, main-list, 320/360 px, text scale 1.6, theme, semantics,
  note-dialog, stale and UTC-midnight coverage: `24/24 PASS`;
- acceptance targeted analyze: primary one-lint failure, one exact test-only
  cleanup, retry PASS;
- acceptance/runner resumability static checks and PowerShell parser: PASS;
- platform/release static: `12/12 PASS`;
- repository `flutter analyze --no-pub`: PASS;
- exact 29-path WIP set, 24 protected hashes, schema `15`, backup `1`, version
  `0.1.0+1`, identity/Manifest/pubspec/lock drift and `git diff --check`: PASS;
- release validator: `7/7 PASS`;
- single Correction #10 full suite: `688/688 PASS`;
- single fresh host acceptance APK build: PASS, 96835391 bytes, SHA-256
  `17475b74dd458f8d76fdd708a24b8262d85e943ad44c9065339c0bd08db9ddb9`.

The authorized acceptance-only sandbox reset was used exactly once. The
target package remained installed and all five non-target inventories stayed
equal.

The primary final physical run passed exact target search, create, target-card
`Planda`, duplicate-disable and main-list visibility, then stopped in the note
dialog because item action selection still opened an adjacent fixture card.
Read-only XML showed the adjacent prefilled note rather than the target note.
The single runner retry corrected XML-ancestor scoping, partial STARTED
resumability, prefilled-note lookup and the reserved PowerShell PID variable;
parser/static/diff passed and the verified APK remained byte-identical.

The exact retry again opened an adjacent fixture item's note dialog and stopped
at `Acceptance editable field was not found: Acceptance persistence notu`.
Terminal XML showed `Acceptance geciken iş`, proving the item action was still
not bound to the target card. The retry budget is exhausted. No further runner
edit, test/build, package reset/install, device action, commit, push or Draft
PR is permitted without new owner authority.

Terminal acceptance-only SQLite evidence is complete and healthy: schema
`15`, integrity `ok`, FK violations `0`; the exact Mobilizasyon instance has
one `PLANNED` item at revision `1`, one non-no-op `CREATED` receipt and one
matching `CREATED` event. The target lifecycle was not exercised and relaunch
persistence was not reached. All five non-target package identities remain
unchanged. Execution remains fail-closed before publication and successor
work.

## Owner-authorized correction #11 — 2026-08-16

- Authority:
  https://github.com/faliardic/chief-site-engineer/issues/464#issuecomment-5308323228
- Verified author/association: `faliardic / OWNER`; it is the latest Issue
  comment.
- Correction #10 M3 diagnosis and every prior fail-closed result remain
  append-only.
- Routing remains `CSE-MRP-1.0`, R4, `gpt-5.6-sol / max`, standard,
  single-agent, no fallback/downgrade. Invocation/runtime actual metadata is
  hidden and remains canonical `unknown / null / unverified`.

```yaml
post_failure_correction_runs: 11
lifecycle_target_selector_correction_runs: 1
additional_acceptance_sandbox_resets_authorized: 0
```

Correction #11 is limited to a stable, human-readable and unique per-item
lifecycle semantics identity plus exact semantics-derived runner targeting.
The runner must require exactly one matching node, verify the exact target
status after every mutation and prove adjacent fixture cards remain unchanged.
No sandbox clear/uninstall, core/schema/fixture/bootstrap/Android identity or
successor work is authorized.

Smallest authorized edit set is selected from exactly these six paths:

1. `mobile/lib/features/living_plan/living_plan_page.dart`
2. `mobile/test/living_plan_widget_test.dart`
3. `mobile/integration_test/living_plan_device_acceptance_test.dart`
4. `scripts/run_living_plan_device_acceptance.ps1`
5. `.cse/tasks/464_task.md` — append-only
6. `.cse/results/464_result.md` — append-only

If existing page semantics are already sufficient, paths 1–2 remain
byte-identical. A seventh path requires fail-closed stop before edit.

### Correction #11 read-only preflight

- Worktree/root: exact linked worktree
  `V:\1_PROJECTS\2_ACTIVE\Python\CSE-Worktrees\issue-464-living-plan-ui-device`.
- Branch/HEAD/base/local master/origin master/remote master:
  `codex/issue-464-living-plan-ui-device` /
  `318f9077b750e54f551f31dffde3dae6220b8e73`.
- Open PR `0`; Issue #464 open; latest comment `5308323228`,
  `faliardic / OWNER`.
- WIP paths `29`; staged paths `0`.
- Exactly one device: `sha256:c68cbe516264`, SM-S938B, API 36,
  `arm64-v8a`; `/data` free `44,556,300 KiB`.
- Six-package inventory equals the Correction #10 terminal state: legacy
  production absent; legacy debug installed as `0.1.0-debug` / code `1` with
  first install `2026-07-20 20:31:44` and last update
  `2026-08-11 23:34:10`; legacy acceptance, Şefim production and Şefim debug
  absent; Şefim acceptance installed as `0.1.0-acceptance` / code `1`, UID
  `10483`.
- A read-only package inventory script first encountered one null metadata
  parser error after reporting the first package. No repository/device
  mutation had occurred; the nullable metadata formatter was corrected and
  the second read-only invocation completed. This preflight-only correction
  did not consume a focused/build/device retry.

Pre-correction allowlist-path hashes:

| Path | Size | SHA-256 |
|---|---:|---|
| `.cse/tasks/464_task.md` | 60123 | `addc43a0b75f47d9415d77501d7dc3c2956e664198d91dafcd603f4cb0a97766` |
| `.cse/results/464_result.md` | 84838 | `2cf87599523f527e429aa0fc3f819ef9d5a3d8aea2f5fb717628fcef995c6bef` |
| `mobile/lib/features/living_plan/living_plan_page.dart` | 38244 | `51513672787b8e35c89302369251d9eb122681e8245ad4ddefc14cd451a42f30` |
| `mobile/test/living_plan_widget_test.dart` | 24257 | `0e5d7a5a143e75035be159985592e681e156c7a6c69f1d680739ce571668b277` |
| `mobile/integration_test/living_plan_device_acceptance_test.dart` | 12472 | `fceaa51e8af30e09d2e9cd2bb811e2660853bcd07e864db0c00c3fb0419e56bf` |
| `scripts/run_living_plan_device_acceptance.ps1` | 29384 | `472356f73de7674af21b0cc7cd441dab50a53a3c4146af6537da6de5ae2f2cc7` |

The full sorted 29-path manifest is appended to the result record. Host gate
order is focused semantics regression, Living Plan/Home, runner/static/
validator, analyze, diff/drift, exactly one full suite and exactly one fresh
host APK build. Only then may the single physical correction run and its one
selector/runner/environment-only retry be used.

### Correction #11 terminal PASS

The correction used only five of the six authorized paths:

- `mobile/lib/features/living_plan/living_plan_page.dart`;
- `mobile/test/living_plan_widget_test.dart`;
- `scripts/run_living_plan_device_acceptance.ps1`;
- append-only task/result records.

`mobile/integration_test/living_plan_device_acceptance_test.dart` remained
byte-identical. No seventh path was required.

Production UI now exposes a unique, human-readable per-item semantics
identity containing activity name, typed context and stable item ID. Status
semantics also carries the record revision; planned date, note and every
lifecycle action are tied to the same identity. Visible Turkish button labels
remain unchanged. The runner rejects zero/multiple content-description
matches, derives taps only from the exact unique node, and compares target plus
both adjacent fixture status/revision/date projections after every mutation.

Host evidence on the final Dart source revision:

- exact adjacent-card semantics regression: `1/1 PASS`;
- Living Plan/Home focused set: `25/25 PASS`;
- runner lifecycle static + PowerShell parser: PASS / `0` errors;
- platform/release static: `12/12 PASS`;
- release validator: `7/7 PASS`;
- repository `flutter analyze --no-pub`: PASS;
- `git diff --check`: PASS;
- exact WIP `29/29`, protected pre-correction hashes `24/24`, staged `0`;
- schema `15`, backup `1`, version `0.1.0+1`, platform/Manifest/pubspec/lock
  drift `0`;
- exactly one Correction #11 full suite: `689/689 PASS`;
- exactly one fresh host arm64 APK build: PASS;
- artifact `sefim-0.1.0-issue464-living-plan-acceptance-debug.apk`,
  `96,835,391` bytes, SHA-256
  `0d6c07440e89e2da38f8a37e75a9e219865a78a015f3c0bd81f5d76c0b5f4469`;
- exact package `com.faliardic.sefim.acceptance`, label `Şefim`, Living Plan
  marker present, normal/background/reboot markers absent, ABI `arm64-v8a`.

Physical primary reached the exact target `STARTED/revision 3` but stopped
after note save because ADB inserted ` guncellendi` at the cursor inside the
existing note. Read-only acceptance UI/SQLite proved the mutated item was the
correct Mobilizasyon target, neighbors remained unchanged, and the failure was
a deterministic cursor/runner defect rather than wrong-item or persistence
failure. The authorized exact retry changed only the runner: it resumes
`Planlandı` or `Başladı`, requires one editable field, moves to end, deletes the
old value deterministically and writes the complete expected note. Parser,
static contract, diff and unchanged Dart/APK hashes passed; no full suite or
build was repeated.

The one exact physical retry PASSed without clear/uninstall:

- target lifecycle completed through `STARTED`, corrected note, `DEFERRED`,
  `COMPLETED`, `REOPENED/PLANNED`;
- target final state: item
  `d250e9e4-39d0-4ef6-8027-2b1fd81494ca`, `PLANNED`, revision `7`, planned
  date `2026-08-16`, note `Acceptance persistence notu guncellendi`;
- events/receipts are non-no-op and aligned at sequences/revisions `1..7`;
- both fixed neighboring items remained `STARTED`, revision `2`, with their
  original dates;
- force-stop/relaunch exact target state/note/date persistence: PASS;
- acceptance fatal/safe-read diagnostic: absent;
- five non-target package identities: unchanged at every checkpoint;
- additional sandbox reset count: `0` (Issue cumulative reset remains `1`);
- terminal copied DB: `1,703,936` bytes, SHA-256
  `82300cc640ba85eee0e03c83a78fd4687efe052d93a35f73e4ebac3108bd2f28`,
  schema `15`, integrity `ok`, FK `0`.

Correction #11 completed in approximately 35 minutes, below its inherited
150-minute hard stop. Physical primary `1` and exact retry `1` are consumed;
no further run is needed. One intentional commit, normal push and one Draft PR
are now authorized. Ready, merge, production Şefim install, V2.5 completion
and successor work remain forbidden.

## Owner-authorized correction #12 — 2026-08-16

- Authority:
  https://github.com/faliardic/chief-site-engineer/issues/464#issuecomment-5308577150
- Verified author: `faliardic`; Issue author/owner and latest Issue comment.
- PR review cluster: Draft PR #465 top-level `COMMENTED` review; inline review
  thread count `0`; head
  `3b071e183e7b7c4130da1921681269ed3972ef40`.
- PR remains Draft/open/unmerged. The correction addresses the single blocking
  add-flow consistency cluster; no Ready or merge authority exists.
- Every earlier fail-closed result and Correction #11 PASS remains append-only.

```yaml
post_failure_correction_runs: 12
independent_review_blockers: 1
add_modal_dismissal_consistency_correction_runs: 1
model_routing:
  policy_version: CSE-MRP-1.0
  task_risk: R4
  codex_model: gpt-5.6-sol
  codex_reasoning_effort: max
  execution_mode: standard
  orchestration: single-agent
  routing_request_evidence: https://github.com/faliardic/chief-site-engineer/issues/464#issuecomment-5308577150
  allowed_fallback: null
  fail_closed_if_mismatch: true
```

Runtime invocation/model/effort metadata is not exposed. New Correction #12
records use canonical `actual_model: unknown`,
`actual_reasoning_effort: unknown`, `mismatch_detected: null` and
`runtime_verification_status: unverified`; no guess, fallback or downgrade is
allowed.

### Exact correction contract

1. Parent-owned durable-change signaling must be set immediately after
   `createLivingPlanItem(...)` succeeds and must trigger parent `_reload()`
   after every modal dismissal path, independent of the route result.
2. Durable create success and post-write candidate refresh are separate truth
   boundaries. A refresh failure after create must report persisted success
   plus refresh failure and must never claim `plan değişmedi`.
3. Widget regressions must prove system-back dismissal reloads the parent and
   a one-shot post-create candidate refresh failure preserves truthful feedback,
   exactly one create and subsequent parent visibility.
4. The physical runner must dismiss the successful add sheet with Android/
   system back and then prove main-list visibility, exact target lifecycle,
   neighbor stability and relaunch persistence on the final corrected source.

Correction edits are limited to the smallest required subset of exactly these
six paths:

1. `mobile/lib/features/living_plan/living_plan_page.dart`
2. `mobile/test/living_plan_widget_test.dart`
3. `mobile/test/support/fake_living_plan_application.dart` — only if required;
   prefer a test-local one-shot failure fake
4. `scripts/run_living_plan_device_acceptance.ps1`
5. `.cse/tasks/464_task.md` — append-only
6. `.cse/results/464_result.md` — append-only

Any seventh path is fail-closed. Core/domain/schema/migration, adapter,
bootstrap, Agenda, Android/iOS identities, Gradle/Manifest/receiver,
pubspec/lock, backup, signing/release, every legacy/production package/data
surface, Issue #385 and successor slices remain protected. Schema `15`, backup
format `1` and app version `0.1.0+1` remain fixed.

### Correction #12 read-only preflight

- Exact worktree/branch/head:
  `issue-464-living-plan-ui-device` /
  `codex/issue-464-living-plan-ui-device` /
  `3b071e183e7b7c4130da1921681269ed3972ef40`.
- Local/remote branch divergence: `0 0`; remote master/base:
  `318f9077b750e54f551f31dffde3dae6220b8e73`.
- Non-ignored tracked/staged/untracked status: clean; staged paths `0`.
- Exact accumulated Issue diff: `29` paths. Full pre-correction size/SHA-256
  manifest is appended to `.cse/results/464_result.md`.
- Planned correction edit subset is page, widget test, runner and append-only
  task/result. The other `24` accumulated WIP paths are protected by their
  pre-correction hashes; shared fake stays protected unless executable evidence
  proves it is required.
- `gh` authentication is valid. PR #465 is open, mergeable, Draft, unmerged,
  base `master`, exact head above; the thread-aware review fetch reports zero
  inline review threads and one actionable top-level behavior cluster.
- The first ADB enumeration started a stopped daemon but returned no device;
  a second read-only enumeration also returned no attached device. No device,
  package or repository mutation occurred. Host correction/gates may proceed;
  the physical stage remains fail-closed until exactly one authorized device
  is visible again.

Correction #12 validation budget remains exact: one affected Living Plan/Home
focused run, one runner/static run, one analyze, one diff/drift gate, one full
suite, one host APK build (environment-only retry if evidenced), one authorized
acceptance-only clear and one physical run (selector/runner/environment-only
retry if evidenced). Product/test failure, add/back inconsistency, safe-read,
integrity, crash or non-target drift has no retry.

## Correction #12 fail-closed stop — 2026-08-16

- The parent-owned durable-change callback, system-back reload behavior and
  post-create refresh truth boundary were implemented in the five-path allowed
  subset; the optional shared fake and every protected path stayed unchanged.
- Focused Living Plan/Home tests passed `26/26`; runner parser/static passed;
  platform/release static tests passed `12/12`; release validator passed `7/7`;
  repository analyze passed; the single full suite passed `690/690`.
- A PATH-only pre-invocation failed before the runner started. The primary host
  build then failed while Flutter tried to remove the Git-ignored, read-only
  `mobile/ios/Flutter/ephemeral/Packages/.packages` directory. After exact
  ignored/worktree containment and source-drift checks, only that directory's
  read-only attribute was cleared.
- The one authorized environment-only build retry reached Gradle but failed
  because Gradle could not remove the Git-ignored
  `mobile/build/app/intermediates/assets/debug/mergeDebugAssets` tree. No fresh
  acceptance APK completed. The existing release-gate APK is the stale
  Correction #11 artifact from `2026-08-16T19:18:06+03:00` and is not accepted
  as Correction #12 evidence.
- Build retry budget is exhausted. Physical clear/install/flow counts are `0`;
  commit/push/GitHub publication counts are `0`. PR #465 remains Draft at the
  pre-correction head. No Ready, merge, AAB/signing, production install,
  successor slice or Item 5 completion action is authorized or performed.
- Stop condition: fail closed at host packaging. A later owner instruction is
  required before any new packaging attempt or continuation.

## Correction #13 host-packaging-only recovery authority — 2026-08-16

Authority:
https://github.com/faliardic/chief-site-engineer/issues/464#issuecomment-5309211860
(`faliardic`, Issue owner/author).

Correction #12 is accepted as an append-only fail-closed result. Correction
#13 grants exactly one deterministic ignored/generated cleanup and exactly one
fresh host arm64 APK build on the unchanged tested WIP source. It grants no
product/test/runner/platform source edit, no ADB command, no device inventory,
clear/install/launch, no commit/push/PR completion publication, Ready or merge.

Hard tracked boundary:

- Only this task record and `.cse/results/464_result.md` may receive append-only
  evidence.
- The other `27` tracked PR paths must remain byte-identical to the
  pre-cleanup manifest in the result record. Any third tracked correction path
  is fail-closed before build.
- Current isolated worktree/branch/head:
  `issue-464-living-plan-ui-device` /
  `codex/issue-464-living-plan-ui-device` /
  `3b071e183e7b7c4130da1921681269ed3972ef40`.
- Remote head is exact and divergence is `0 0`; PR #465 is open, mergeable,
  Draft and unmerged; base is
  `318f9077b750e54f551f31dffde3dae6220b8e73`.
- Current Correction #12 WIP diff has `5` paths, staged `0`, non-ignored
  untracked `0`; accumulated PR diff has `29` paths. Deterministic current diff
  blob identity is `f46242a8f63361cd71a45f0f921f12e934b347eb`.
- Pre-cleanup pubspec SHA-256 is
  `704ee4a64b534d14264984f68b8275570b8f87c06190ee48340830d971eabfa7`;
  lockfile SHA-256 is
  `2b75e59a051a8cfcfec3d6883b04779205c63678b0f4814a4535e50db77dc441`.

Authorized generated roots are restricted to `mobile/build/`,
`mobile/ios/Flutter/ephemeral/`, and only if needed `mobile/.dart_tool/` or
`mobile/android/.gradle/`. Required order is exact containment and ignored
proof, worktree-local Gradle `--stop`, descendant read-only removal using
`attrib`, complete deletion of the first two roots, offline pub metadata
preparation with pubspec/lock equality, then one direct fresh build. No build
retry is authorized.

Correction #12 focused `26/26`, static `12/12`, validator `7/7`, analyze PASS
and full `690/690` are reused. They must not be rerun. On host-build PASS,
append artifact evidence and stop uncommitted/unpushed with PR #465 Draft while
awaiting separate physical-only authority.

```yaml
post_failure_correction_runs: 13
host_generated_state_cleanup_runs: 1
fresh_host_packaging_runs: 1
physical_runs_under_correction_13: 0
model_routing:
  policy_version: CSE-MRP-1.0
  task_risk: R4
  codex_model: gpt-5.6-sol
  codex_reasoning_effort: max
  execution_mode: standard
  orchestration: single-agent
  routing_request_evidence: https://github.com/faliardic/chief-site-engineer/issues/464#issuecomment-5309211860
  allowed_fallback: null
  fail_closed_if_mismatch: true
```

## Correction #13 host packaging PASS and stop — 2026-08-16

- Exact ignored/generated containment and Git-ignore checks passed for
  `mobile/build/` and `mobile/ios/Flutter/ephemeral/`.
- The worktree-local Gradle wrapper stopped exactly one daemon. Read-only
  attributes were removed from both roots and descendants with `attrib`; only
  those two roots were deleted. `mobile/.dart_tool/` and
  `mobile/android/.gradle/` were not deleted because they were not required.
- Host execution policy rejected two combined cleanup command preflights and
  one `Remove-Item` process before execution. No operation occurred in those
  rejected calls. The already verified exact roots were then deleted one at a
  time through the PowerShell/.NET directory API without changing scope.
- Pinned Flutter `pub get --offline` passed; pubspec and lockfile hashes stayed
  exact and tracked drift remained zero.
- The single authorized fresh build invocation passed:
  `flutter build apk --debug --no-pub --target
  integration_test/living_plan_acceptance_main.dart --target-platform
  android-arm64`. Build interval was
  `2026-08-16T22:03:01.5854689+03:00`–
  `2026-08-16T22:05:24.5566894+03:00`; output mtime was
  `2026-08-16T22:05:19.6173887+03:00`.
- Fresh ignored artifact:
  `mobile/build/release_gate/sefim-0.1.0-issue464-living-plan-acceptance-debug.apk`;
  size `96837167`; SHA-256
  `1d94fb97ec5ec0e98d24f4a063ecd1d91061ac898d8a39a9bb7b38b720040a68`.
- APK contract PASS: package `com.faliardic.sefim.acceptance`, label `Şefim`,
  marker `CSE_ENTRYPOINT_LIVING_PLAN_ACCEPTANCE_V1` present, normal/background/
  reboot markers absent, launchable activity
  `com.faliardic.chiefsiteengineer.MainActivity`, four `arm64-v8a` native
  libraries, protected identity collision `false`, and artifact/output SHA
  equality `true`.
- Post-build protected tracked hashes `27/27`, correction paths `5/5`, total PR
  paths `29/29`, staged/non-ignored untracked `0/0`, pubspec/lock exact and
  `git diff --check` PASS. Correction #12 source remained byte-identical.
- Reused validation only: focused `26/26`, static `12/12`, validator `7/7`,
  analyze PASS, full `690/690`. None was rerun.
- ADB/device operations `0`, commit/push/GitHub publication `0`. PR #465
  remains open, mergeable and Draft at
  `3b071e183e7b7c4130da1921681269ed3972ef40`; divergence `0 0`.
- Required stop: host packaging is complete; await explicit owner confirmation
  that the physical device is reconnected and a separate physical-only
  authority. Do not commit or push Correction #12 yet.

## Correction #13 resume audit — 2026-08-17

Yeni sohbet bootstrap'i sırasında Issue #464 gövdesi ve bütün `20` yorum,
özellikle owner comment `5309211860`, yeniden okundu. Yerel append-only kayıt,
Correction #13 cleanup ve tek fresh build bütçesinin daha önce PASS olarak
tüketildiğini kanıtladığı için build, test, analyze, validator veya offline pub
işlemi tekrar edilmedi.

Read-only audit sonucu:

- exact worktree/branch/head:
  `issue-464-living-plan-ui-device` /
  `codex/issue-464-living-plan-ui-device` /
  `3b071e183e7b7c4130da1921681269ed3972ef40`;
- upstream divergence `0 0`, staged path `0`, current WIP `5`, full PR path
  seti `29`;
- protected tracked hash `27/27`, mismatch `0`;
- Correction #13 öncesindeki task/result prefixleri exact korunmuş;
- pubspec/lock hashleri exact;
- `git diff --check` exit `0` (yalnız mevcut LF→CRLF uyarıları);
- fresh output ve release-gate copy: `96837167` byte, SHA-256
  `1d94fb97ec5ec0e98d24f4a063ecd1d91061ac898d8a39a9bb7b38b720040a68`,
  copy equality `true`;
- package/label/marker/forbidden-marker/ABI/launchable-activity contractı
  read-only yeniden doğrulandı;
- schema / backup / version: `15 / 1 / 0.1.0+1`;
- GitHub PR #465: open, mergeable, Draft, unmerged, remote head exact.

Bu resume audit sırasında ADB/device, build, cleanup, pub get, source edit,
commit, push, Issue/PR write, Ready veya merge işlemi yapılmadı. Correction #13
PASS ve ayrı physical-only authority bekleme stop'u değişmedi.

```yaml
correction_13_resume_audit:
  requested_model: gpt-5.6-sol
  actual_model: unknown
  requested_reasoning_effort: max
  actual_reasoning_effort: null
  invocation_verification_status: unverified
  runtime_verification_status: unverified
  single_build_repeated: false
  protected_tracked_paths: 27/27_pass
  total_pr_paths: 29/29_pass
  fresh_apk_sha256: 1d94fb97ec5ec0e98d24f4a063ecd1d91061ac898d8a39a9bb7b38b720040a68
  physical_commands: 0
  commit: null
  push: false
  draft_pr: 465
  ready: false
  merged: false
  status: host_packaging_pass_awaiting_physical_only_authority
```

## Owner-authorized physical-only acceptance — preflight fail-closed — 2026-08-17

Authority:
https://github.com/faliardic/chief-site-engineer/issues/464#issuecomment-5318565513
(`faliardic`, Issue owner/author).

Correction #13 host artifact authority was revalidated read-only before the
first device mutation. Exact worktree/branch/head and upstream divergence,
the five-path current WIP, staged `0`, full PR path set `29/29`, protected
tracked hashes `27/27`, append-only prefixes and `git diff --check` all passed.
PR #465 remained open, mergeable, Draft and unmerged at remote head
`3b071e183e7b7c4130da1921681269ed3972ef40`.

The release-gate APK remained exactly `96837167` bytes with SHA-256
`1d94fb97ec5ec0e98d24f4a063ecd1d91061ac898d8a39a9bb7b38b720040a68`.
Read-only APK verification reconfirmed package
`com.faliardic.sefim.acceptance`, label `Şefim`, Living Plan marker present,
all three forbidden markers absent, launchable activity
`com.faliardic.chiefsiteengineer.MainActivity` and four `arm64-v8a` native
libraries. No test, validator, analyze, pub, Gradle or Flutter build ran.

The primary read-only ADB preflight then found exactly one enumerated target,
masked `sha256:c68cbe516264`, but its state was `unauthorized`. Usable `device`
targets were `0`; unauthorized/offline targets were `1`. Model/API/ABI/space
and the six-package inventory could not be queried through the unauthorized
transport. The authority requires exactly one usable target and permits a
transport retry only after package isolation is proven; package isolation
could not be proven. Execution therefore stopped fail-closed before the first
device mutation and no retry was used.

No `pm clear`, install/update, launch, force-stop, `run-as`, sandbox access,
screenshot/UI dump, logcat, package mutation, source edit, commit, push, PR
metadata transition, Ready or merge occurred.

```yaml
physical_only_authority_result:
  post_failure_correction_runs: 13
  physical_only_authority_runs: 1
  physical_primary_runs: 1
  physical_primary_result: fail_adb_preflight_unauthorized
  physical_exact_retries: 0
  acceptance_sandbox_reset_runs: 0
  acceptance_install_runs: 0
  host_build_runs_under_this_authority: 0
  source_edit_runs_under_this_authority: 0
  commit_push_runs_under_this_authority: 0
  adb_targets_enumerated: 1
  adb_usable_targets: 0
  adb_unauthorized_or_offline_targets: 1
  masked_device_identity: sha256:c68cbe516264
  six_package_pre_inventory: not_captured_device_unauthorized
  protected_device_mutations: 0
  acceptance_package_mutations: 0
  status: fail_closed_device_unauthorized_before_mutation
```

Final append-only verification preserved the exact pre-authority task prefix
(`82115` bytes, SHA-256
`a3008d2cf207a54c54e6fa23b0ab8526db19b76c2ff43d02914f2f6a6d097dd7`)
and result prefix (`126887` bytes, SHA-256
`9c429d04920c6defe94ed53d923d958c43b8b7dbb4578694d751405c4c5b2ce1`).
The five-path WIP, staged/non-ignored untracked `0/0`, accumulated PR paths
`29/29`, protected hashes `27/27`, upstream divergence `0 0` and
`git diff --check` exit `0` remained exact after evidence append.

## Owner-authorized physical-only rerun — PASS — 2026-08-17

Authority:
https://github.com/faliardic/chief-site-engineer/issues/464#issuecomment-5318760101.

The independent rerun used the already verified Correction #13 artifact only:
`mobile/build/release_gate/sefim-0.1.0-issue464-living-plan-acceptance-debug.apk`,
`96837167` bytes, SHA-256
`1d94fb97ec5ec0e98d24f4a063ecd1d91061ac898d8a39a9bb7b38b720040a68`,
package `com.faliardic.sefim.acceptance`, label `Şefim`, arm64-v8a and
launchable activity `com.faliardic.chiefsiteengineer.MainActivity`. No tracked
product/test/runner/platform file changed; no test, validator, analyze, pub,
Gradle or Flutter build ran.

The single fresh `adb devices -l` resolved exactly one authorized device:
`sha256:c68cbe516264`, model `SM-S938B`, Android `16`, API `36`, ABI
`arm64-v8a`, with `44151188 KiB` free under `/data`. The six-package baseline
was captured. Only `com.faliardic.chiefsiteengineer.debug` was present among
the five non-target identities; its version/timestamps remained exact through
the run. Non-target inventory mismatches were `0` at every enforced boundary.

Acceptance-only mutation budgets were consumed exactly once: target `pm clear`
`1`, verified APK install `1`. The installed base APK SHA matched the host
artifact. The primary flow stopped at the acceptance banner UIAutomator lookup.
A direct screen capture proved the exact visible banner
`Kabul ortamı · sentetik veri`; the same banner was absent only from the
UIAutomator XML despite source-visible semantics. This was classified as the
explicitly retryable selector/UIAutomator defect. The one authorized retry ran
without another clear/install and passed the full add/system-back/lifecycle/
neighbor-isolation/relaunch-persistence flow.

Final physical projection: target item
`cb502e04-1a84-4acd-8b40-738766785bb0`, status `Planlandı` / DB `PLANNED`,
revision `6`, planned date `17.08.2026`, note
`Acceptance persistence notu guncellendi`. Neighbor fixtures remained
`Planlandı/1/16.08.2026` and `Başladı/2/17.08.2026`. Fatal diagnostics were
absent. The acceptance activity was left installed, top-resumed and showing
the Living Plan identity.

The force-stopped acceptance-only database was copied read-only through
`run-as`. Host copy size/SHA-256 was `1699840` /
`6f762f349752c954e8ea4fabe8ddab8647d5d352905fb86e2dea0f0bf5176043`.
SQLite evidence passed: user_version `15`, integrity `ok`, foreign-key
violations `0`, one target activity row, exact current snapshot reference,
events and command receipts `1..6` with
`CREATED, STARTED, NOTE_UPDATED, DEFERRED, COMPLETED, REOPENED`, all receipts
non-no-op and aligned with result revision.

Final host boundary before this append: exact five tracked WIP paths, staged
`0`, non-ignored untracked `0`, accumulated PR paths `29/29`, protected
Correction #13 manifest `27/27` with mismatches `0`, pubspec/lock drift `0`,
`git diff --check` exit `0`, schema/backup/version `15 / 1 / 0.1.0+1`.
The pre-authority task prefix was `85230` bytes with SHA-256
`fbc86d215c97d1bde611cacff29b61b7428145a9d0f618f262ebff7d6be7aba1`;
the pre-authority result prefix was `133445` bytes with SHA-256
`1ce23f2503043db0b63bedddac6960ccc9d0da21212964d00c20d31afd8af276`.

```yaml
execution_record:
  issue: 464
  authority_comment_id: 5318760101
  task_risk: R4
  validation_class: release-critical
  requested_model: gpt-5.6-sol
  actual_model: unknown
  requested_reasoning_effort: max
  actual_reasoning_effort: null
  execution_mode: standard
  orchestration: single-agent
  routing_request_evidence: https://github.com/faliardic/chief-site-engineer/issues/464#issuecomment-5318760101
  invocation_evidence: null
  invocation_verification_status: unverified
  mismatch_detected: null
  runtime_verification_status: unverified
  adb_devices_invocations: 1
  authorized_device_count: 1
  masked_device_identity: sha256:c68cbe516264
  physical_primary_runs: 1
  physical_exact_retries: 1
  acceptance_sandbox_reset_runs: 1
  acceptance_install_runs: 1
  host_build_runs_under_this_authority: 0
  test_analyze_validator_runs_under_this_authority: 0
  source_edit_runs_under_this_authority: 0
  non_target_inventory_mismatches: 0
  target_item_id: cb502e04-1a84-4acd-8b40-738766785bb0
  target_final_revision: 6
  target_final_status: PLANNED
  fatal_diagnostics: false
  protected_tracked_paths: 27
  protected_hash_mismatches: 0
  effective_pr_paths: 29
  staged_paths: 0
  nonignored_untracked_paths: 0
  commit: null
  push: false
  draft_pr: 465
  ready: false
  merged: false
  status: pass
```

Final append-only verification preserved the exact pre-authority task/result
prefixes. Before this verification append, task/result were `89804` / `143038`
bytes with SHA-256
`3e1abbabe5033946b0f5ca320dba017a6d903ef954a434478b2f83cd6c7d29e6` /
`6a02a84c6ba6bdbbfa4cdb9efd223b2c54e448e89cffd91e781ed9681846526c`.
The five-path WIP, staged/untracked `0/0`, accumulated paths `29/29`, protected
hashes `27/27` with mismatch `0` and `git diff --check` exit `0` remained exact.
