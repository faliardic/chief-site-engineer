# Issue #445 Task — Typed Project Profile + Dependency Catalog Runtime

## Execution identity

- Resmî repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- İzole linked worktree: `V:\1_PROJECTS\2_ACTIVE\Python\CSE-Worktrees\issue-445`
- Exact base/master: `b82c1841860cdc26794e6ecab9c3cb7c1e4abac2`
- Branch: `codex/issue-445-project-profile-dependency-runtime`
- Codex model: bu oturumda seçili en güçlü full Codex modeli
- Reasoning: `Extra High`
- Seçim nedeni: typed profile, recursive applicability ve 362 dependency için kalıcı fail-closed graph sözleşmesi birlikte kuruluyor.

## Canonical input

- Input ZIP yalnız çalışma girdisidir; repository'ye eklenmez.
- ZIP SHA-256: `6d5cf112af3ce6e0bee377bac032e6a9de8204fb5a11efd71b2a4bcf3c3d77dd`
- Dependency asset SHA-256: `07f58de9912fe76303d18b48863b45aeaaac0f0f203aa14ebe8f8b1a8db12c86`
- Decoded dependency JSON SHA-256: `145f52622b3badf72e9f43107157a67f154056077aeb35d8f531661999ab68a1`
- Physical contract: 316-ID merged activity authority, 362 dependency template, 29 applicability field; bütün dependency endpoint'leri activity authority kümesinde çözülür.

## Validation contract

- Validation class: `domain / read-only graph contract`
- Changed contracts: typed/fail-closed project profile, exact 29-field applicability map, dependency model/load validation, shared recursive condition semantics ve deterministic selected-activity filtering.
- Focused tests: existing `construction_corpus_repository_test.dart` regressions plus new profile/dependency matrix.
- Allowed broad gates: offline pub get, changed Dart format, focused tests, analyze, diff/allowlist classification ve final source revision üzerinde bir full Flutter suite.
- Reused evidence: exact base'teki schema 13, Backup format 1 ve dependency/lockfile/platform sözleşmeleri; protected-path diff'i sıfır kalmalıdır.
- Minimum physical-device acceptance: yok; UI/persistence/platform/user-data yolu değişmiyor.
- Retry budget: 1 primary run + en fazla 1 blocking correction; aynı başarısız operasyon exact fix sonrası en fazla bir retry.
- Time budget: hedef 30–45 dakika, hard stop 75 dakika.
- Stop conditions: canonical hash/contract sapması, allowlist dışı production ihtiyacı, protected drift, aynı operasyonun ikinci hatası, release/device ihtiyacı veya 75 dakika hard stop.

## Authorized files

Production:

- `mobile/assets/corpus/cse_construction_dependency_catalog_v0_3.b64`
- `mobile/lib/domain/construction_corpus_models.dart`
- `mobile/lib/application/construction_corpus_repository.dart` — yalnız shared profile/applicability contract gerekirse
- `mobile/lib/application/construction_dependency_repository.dart`
- `mobile/pubspec.yaml`

Tests:

- `mobile/test/construction_corpus_repository_test.dart`
- `mobile/test/construction_dependency_repository_test.dart`
- gerekirse `mobile/test/support/construction_profile_fixtures.dart`

Evidence:

- `.cse/tasks/445_task.md`
- `.cse/results/445_result.md`

## Implementation scope

- Issue #445 canonical enum ve validation sözleşmeleriyle typed `ConstructionProjectProfile` oluştur.
- Deterministic `toApplicabilityMap()` exact 29 corpus field üretir.
- Canonical dependency assetini stable corpus path'e byte-for-byte yerleştir ve `pubspec.yaml` asset kaydını ekle.
- Typed `ConstructionDependency` ve enumlarını ekle.
- Bundled dependency repository exact metadata/count/enum/reference/condition doğrulaması yapar ve merged activity corpusunu authority olarak kullanır.
- Dependency condition değerlendirmesi Issue #443 tri-state applicability engine'ini reuse eder.
- `dependenciesForSelectedActivities(...)` yalnız iki endpoint seçili ve condition kesin match ise deterministic sonuç döndürür.

## Explicitly out of scope

- scopeRule/floorOffset resolution veya BLOCK/FLOOR/BASEMENT instance graph;
- schedule/date/critical-path calculation;
- SQLite, migration, profile/activity persistence veya Backup değişikliği;
- UI, 7-day plan, platform/config, dependency/lockfile değişikliği;
- YFK raw text/price/resource engine, project learning/actual, V2.5 Daily Output ve AI/cloud;
- sonraki Schedule/Instantiation Issue.

## Validation order

1. canonical ZIP/asset/decoded JSON precheck;
2. dependency asset hash;
3. `flutter pub get --offline`;
4. yalnız changed Dart files `dart format`;
5. focused corpus + profile/dependency tests;
6. `flutter analyze --no-pub`;
7. `git diff --check`;
8. exact allowlist/protected-path classification;
9. schema 13 / Backup 1 / dependency-lockfile-platform drift 0;
10. final source revision üzerinde yalnız bir `flutter test --no-pub`.

## Publication

- Intentional commit, normal push, Draft PR ve Issue #445 completion evidence yetkilidir.
- PR Ready ve merge yetkili değildir.
- Post-merge sync bu görevde yapılmaz.
