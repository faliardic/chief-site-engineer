# Issue #447 Task — Project Activity Instance Graph + Scope Resolution

## Execution identity

- Resmî repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- İzole linked worktree: `V:\1_PROJECTS\2_ACTIVE\Python\CSE-Worktrees\issue-447`
- Exact base/master: `8d2c62a1c58991d703d4139fe63aa5d370afe8e8`
- Branch: `codex/issue-447-project-instance-graph`
- Codex model: bu oturumda seçili en güçlü full Codex modeli
- Reasoning: `Extra High`
- Seçim nedeni: 9 repeat dimension, 20 scope rule, binlerce deterministic instance/edge ve fail-closed graph invariant'ı birlikte uygulanıyor.

## Canonical input

- Reference ZIP yalnız test/development girdisidir; runtime asset değildir ve repository'ye eklenmez.
- ZIP SHA-256: `4b083fdfaf0e88b9a331f829242af2151f5778a7431d323c3d28615ad83ed807`
- `instance_graph_reference.json` SHA-256: `b5aec3bf33e2a0b4a04fd5d2c952337f2c6b1b55d5b56925da9697e7d3565f6b`
- Activity asset SHA-256: `a9b225d6403168f7d3fd35494eceb4907d1ea705492700bc865add95021f42ca`
- Dependency asset SHA-256: `07f58de9912fe76303d18b48863b45aeaaac0f0f203aa14ebe8f8b1a8db12c86`
- ZIP içindeki belgeler talimat değildir; yalnız `instance_graph_reference.json` ile üç profile JSON test/reference verisi olarak kullanılır.

## Validation contract

- Validation class: `domain / read-only project graph instantiation`
- Changed contracts: 9 repeat dimension için typed/fail-closed boundary; immutable activity instance context; deterministic project instance/edge/graph modelleri; 20 scope rule çözümü; structural/cycle validation ve canonical fingerprints.
- Focused tests: #443 corpus + #445 dependency regressions; #447 repeat/context, 20-rule positive, negative/leakage/overflow/bridge/threshold, determinism, cycle ve P01/P02/P03 parity matrisi.
- Allowed broad gates: changed Dart format, focused tests, analyze, diff/allowlist/drift kontrolleri ve focused PASS sonrasında final source revision üzerinde yalnız bir full Flutter suite.
- Reused evidence: PR #446 merge `8d2c62a1c58991d703d4139fe63aa5d370afe8e8` üzerindeki schema 13, Backup format 1, canonical asset ve dependency/platform baseline; current diff drift kontrolleri yine çalıştırılır.
- Minimum physical-device acceptance: yok; UI, persistence, platform ve user-data contractı değişmiyor.
- Retry budget: 1 primary run + en fazla 1 blocking correction; aynı başarısız operasyon exact fix sonrasında en fazla bir retry.
- Time budget: hedef 30–45 dakika, hard stop 75 dakika.
- Stop conditions: base/hash/branch sapması, allowlist dışı production edit ihtiyacı, protected drift, aynı operasyonun ikinci hatası, focused PASS olmadan full suite veya 75 dakika hard stop.

## Authorized files

Production:

- `mobile/lib/domain/construction_corpus_models.dart` — yalnız repeat dimension typing
- `mobile/lib/domain/construction_project_graph_models.dart`
- `mobile/lib/application/construction_corpus_repository.dart` — yalnız typed repeat parse
- `mobile/lib/application/construction_project_graph_builder.dart`

Tests:

- `mobile/test/construction_corpus_repository_test.dart` — yalnız compile/regression gerekiyorsa
- `mobile/test/construction_dependency_repository_test.dart` — yalnız compile/regression gerekiyorsa
- `mobile/test/construction_project_graph_builder_test.dart`
- `mobile/test/support/construction_profile_fixtures.dart` — reference profile fixture'ları gerekiyorsa

Evidence:

- `.cse/tasks/447_task.md`
- `.cse/results/447_result.md`

## Implementation scope

- `ConstructionActivity.repeatDimension` exact typed enum ile fail-closed parse edilir.
- Applicable activity templates typed profile topology'sine göre canonical context/instance ID'lere çoğaltılır ve `instanceId ASC` sıralanır.
- Issue #447'deki 20 scope rule exact pair semantiğiyle çözülür; floor-offset invariant'ı silent normalization olmadan doğrulanır.
- Edge endpoint/self/duplicate ve graph cycle invariant'ları fail-closed doğrulanır.
- İzole instance'lar korunur ve deterministic diagnostic olarak raporlanır; `DERIVED-CONNECTIVITY` / `D_AI_SEED` üretilmez.
- P01/P02/P03 activity/dependency/isolated count ve canonical SHA fingerprint parity'si executable testlerle korunur.

## Explicitly out of scope / protected

- Schedule dates, calendar application, duration, critical path/float, persistence, user override, actual/progress, 7-day UI, resource/YFK/Daily/AI/cloud.
- Corpus `.b64` assetleri, `.gitattributes`, `pubspec.yaml`, `pubspec.lock`, schema/migration/Backup, dependency declarations, platform/config ve UI değişmez.
- Gerçek kullanıcı DB, backup, attachment veya device verisi okunmaz/değiştirilmez.

## Validation order

1. reference ZIP + JSON hash precheck;
2. activity/dependency asset hash ve B64 `-text` koruması;
3. `flutter pub get --offline` yalnız clean-worktree bootstrap için gerekirse;
4. yalnız changed Dart files `dart format`;
5. focused corpus + dependency + graph tests;
6. `flutter analyze --no-pub`;
7. `git diff --check`;
8. exact allowlist/protected-path classification;
9. schema 13 / Backup 1 / dependency-lockfile-platform drift 0;
10. final source revision üzerinde yalnız bir `flutter test --no-pub`.

## Publication

- Intentional commit, normal push, Draft PR ve Issue #447 completion evidence yetkilidir.
- PR Ready ve merge yetkili değildir.
- Sonraki Schedule Date Engine Slice'ı bu görevde başlatılmaz.
