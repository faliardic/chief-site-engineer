# Issue #454 Task — Schedule Seed Catalog + Forward Schedule Date Engine

## Execution identity

- Resmî repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- İzole linked worktree: `V:\1_PROJECTS\2_ACTIVE\Python\CSE-Worktrees\issue-454-schedule-date-engine-20260816T002925794Z`
- Exact base/master: `6d55947f73097e3ee71246fbc1496ba1f6878f01`
- Branch: `codex/issue-454-schedule-date-engine`
- Issue/result identity: `454`
- Birinci teknik otorite: `CSE_Issue_449_Schedule_Date_Engine_Codex_Task.md`
- Birinci otorite SHA-256: `25bbf579325fb336721bbde6ccb571eade671ea129fad86edc3b993d84f0b909`
- Canonical input ZIP: `CSE_Corpus_Runtime_Schedule_Date_Input_v0_3.zip`
- Expected ZIP SHA-256: `fd2d99f1d8569ad1683bc69d5abb7de6f79c24aa0362e7c3231eabc168dd988a`

## Model routing

- Policy: `CSE-MRP-1.0`
- Risk: `R4`
- Requested Codex model: `gpt-5.6-sol`
- Requested reasoning effort: `max`
- Execution mode: `standard`
- Orchestration: `single-agent`
- Fallback/downgrade: yok
- Selection reason: schedule seed authority, UTC date-only takvim, FS/SS
  propagation, deterministic fingerprint ve sonraki persistence/7-day-plan
  bağımlılığı kritik bir core contract oluşturur.
- Runtime metadata görünürlüğü: `actual_model: unknown`,
  `actual_reasoning_effort: unknown`, `mismatch_detected: null`,
  `runtime_verification_status: unverified`.

## Product and validation classification

- V2 item: `N/A — explicit owner-authorized post-V2 read-only corpus runtime
  research slice`; bu görev V2 milestone kapsamını veya sırasını değiştirmez.
- Parent Epic: `N/A`; teknik foundation zinciri Issue #443 / PR #444,
  Issue #445 / PR #446 ve Issue #447 / PR #448'dir.
- Validation class: `domain / read-only schedule date propagation`.
- Changed contracts: validated 316-row schedule seed catalog; UTC date-only
  calendar helpers; inclusive duration calculation; deterministic topological
  FS/SS + WORKING_DAY lag propagation; independently testable post-validation;
  P01/P02/P03 canonical reference schedule parity.
- Reused evidence: PR #448 exact base üzerinde schema 13, Backup format 1,
  activity/dependency asset ve dependency/platform baseline. Bu görevde exact
  hash/drift kontrolleri yeniden çalıştırılır; persistence/release gate'leri
  tekrarlanmaz.

## Contract impacts

- Schema impact: yok; AppDatabase schema `13` değişmez.
- Migration impact: yok.
- Backup impact: yok; format `1` ve Backup application değişmez.
- Attachment impact: yok.
- Notification impact: yok.
- Platform/dependency impact: yok; lockfile ve Android/iOS/config değişmez.
- Physical-device acceptance: yok; UI, persistence, platform ve user-data
  davranışı değişmiyor.

## Authorized paths

Production:

- `mobile/assets/corpus/cse_construction_schedule_seed_catalog_v0_3.b64`
- `mobile/lib/domain/construction_schedule_models.dart`
- `mobile/lib/application/construction_schedule_seed_repository.dart`
- `mobile/lib/application/construction_schedule_date_engine.dart`
- `mobile/pubspec.yaml` — yalnız yeni asset kaydı

Narrow shared typing, yalnız strict compile gerektirirse:

- `mobile/lib/domain/construction_corpus_models.dart`
- `mobile/lib/domain/construction_project_graph_models.dart`

Tests:

- `mobile/test/construction_schedule_seed_repository_test.dart`
- `mobile/test/construction_schedule_date_engine_test.dart`
- `mobile/test/support/construction_profile_fixtures.dart` — yalnız reference
  reuse gerekirse

Evidence:

- `.cse/tasks/454_task.md`
- `.cse/results/454_result.md`

Allowlist dışı production edit gerekirse edit yapmadan Issue #454'e exact
gerekçe yazılır ve durulur.

## Implementation scope

- Input ZIP dışarıdaki geçici dizinde hash/count ile doğrulanır; ZIP, decoded
  seed JSON ve reference bundle repository'ye eklenmez.
- Yalnız compiled B64 runtime asset commit edilir ve pubspec'e kaydedilir.
- Unknown enum/string, malformed duration, duplicate/missing/extra seed,
  activity metadata mismatch ve forbidden raw/price/resource field fail-closed
  reddedilir.
- UTC midnight ve canonical `YYYY-MM-DD` kullanılır; Monday `0` ↔ Dart
  weekday `1` mapping'i explicit yapılır.
- Duration `ceil`, inclusive finish ve zero-day milestone semantiği exacttır.
- Deterministic topological forward pass yalnız `FS`, `SS` ve `WORKING_DAY`
  lag kabul eder; cycle ve future enum fail-closed olur.
- İzole node root olarak korunur ve işaretlenir; artificial veya
  `DERIVED-CONNECTIVITY` edge eklenmez.
- Çıktı `TEST_SEED_ONLY`, `NOT_FOR_PRODUCTION`, `NOT_A_BASELINE` marker'larını
  görünür taşır; critical path/float alanı üretmez.
- P01/P02/P03 count/date/root/leaf/isolated/fingerprint parity exact korunur.

## Focused tests

- Existing corpus/dependency/graph regression testleri.
- Seed B64/decoded hash, metadata/count/status/confidence ve activity authority
  cross-check testleri; duplicate/missing/extra/unknown/malformed/forbidden
  negative testleri.
- UTC canonical date, weekday, workday, holiday, next/add workday ve invalid
  date testleri.
- Zero/working/calendar/fractional duration testleri.
- FS0/FS1/SS0/SS1, Sunday/holiday, multi-predecessor max, successor
  normalization, cycle/unknown relation/lag ve deliberate post-validation
  corruption testleri.
- P01/P02/P03 exact schedule/count/date/fingerprint parity, deterministic repeat,
  isolated roots, zero synthetic dependency ve zero Sunday/holiday violation.

## Validation order and broad gates

1. ZIP, B64, decoded seed JSON ve reference JSON hashleri.
2. Physical seed count/status/confidence dağılımı.
3. Existing activity/dependency asset hashleri ve `.gitattributes` B64 kuralı.
4. Fresh Windows checkout byte stability; offline pub get yalnız gerekirse.
5. Changed Dart format.
6. Focused existing + new tests.
7. Final source revision üzerinde focused PASS.
8. `flutter analyze --no-pub`.
9. `git diff --check`, exact allowlist ve protected drift.
10. Schema/Backup/dependency/lockfile/platform kontrolü.
11. Yalnız focused PASS sonrasında bir kez `flutter test --no-pub`.

Allowed broad gate yalnız final source revision üzerindeki tek full Flutter
suite'tir. APK/device/backup/restore/release/signing/background/reboot gate'i
yetkili değildir ve read-only boundary korunursa çalıştırılmaz.

## Budgets and stop conditions

- Primary execution budget: `1`.
- Issue-scoped correction budget: en fazla `1`.
- Aynı başarısız operasyon: exact fix sonrasında en fazla bir retry.
- Time target: `30–45 dakika`.
- Hard stop: `75 dakika`.
- Stop: base/hash/count/branch sapması; allowlist dışı production edit;
  protected drift; requested model downgrade; repeated blocker; focused PASS
  olmadan full suite; gerçek user data ihtiyacı; 75 dakika hard stop.

## Explicitly out of scope

- Persistence, SQLite, migration, Backup, attachment, notification, platform,
  UI, critical path/float, baseline approval, user override,
  quantity/productivity/resource engine, actual/progress/reforecast, 7-day plan,
  YFK price/raw analysis/resource coefficients, AI/cloud ve Issue #455.
- Gerçek kullanıcı DB, backup, attachment, device veya Recovery 5 protected
  file contents okunmaz/değiştirilmez.

## Publication authority

- Result evidence, intentional commit, normal push, Issue completion comment ve
  Draft PR yetkilidir.
- PR Ready, merge, deploy, release, branch deletion ve force-push yasaktır.
- Draft PR sonrasında durulur; persistence/living 7-day-plan veya Issue #455
  başlatılmaz.
- Post-merge sync bu görevde uygulanmaz; merge yetkisi yoktur.
