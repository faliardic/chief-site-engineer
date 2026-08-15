# Issue #447 Result — Project Activity Instance Graph + Scope Resolution

## Execution summary

- Validation class: `domain / read-only project graph instantiation`
- Resmî repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- İzole linked worktree: `V:\1_PROJECTS\2_ACTIVE\Python\CSE-Worktrees\issue-447`
- Exact base / `origin/master`: `8d2c62a1c58991d703d4139fe63aa5d370afe8e8`
- Branch: `codex/issue-447-project-instance-graph`
- Primary run: `1`
- Blocking correction run: `0`
- Focused retry: `1` — ilk fingerprint koşusundaki exact `lot_id` context tipi ve no-basement positive-fixture ayrımı düzeltildikten sonra
- Time budget: domain hard stop `75 dakika`; çalışma bütçe içinde tamamlandı.

## Canonical input and protected asset evidence

- Reference ZIP SHA-256: `4b083fdfaf0e88b9a331f829242af2151f5778a7431d323c3d28615ad83ed807` — exact.
- `instance_graph_reference.json` SHA-256: `b5aec3bf33e2a0b4a04fd5d2c952337f2c6b1b55d5b56925da9697e7d3565f6b` — exact.
- Activity asset physical SHA-256: `a9b225d6403168f7d3fd35494eceb4907d1ea705492700bc865add95021f42ca` — exact.
- Dependency asset physical SHA-256: `07f58de9912fe76303d18b48863b45aeaaac0f0f203aa14ebe8f8b1a8db12c86` — exact.
- `.gitattributes`: exact `mobile/assets/corpus/*.b64 -text`; `git check-attr text` iki asset için `unset`.
- Reference ZIP ve içindeki JSON/profile verileri runtime asset yapılmadı, worktree'ye kopyalanmadı ve changed-file setine girmedi.

## Implemented contracts

- `ConstructionActivity.repeatDimension` 9 exact değerli typed/fail-closed `ConstructionActivityRepeatDimension` oldu.
- PROJECT/BLOCK/BASEMENT/FLOOR/ZONE/FACADE_ELEVATION/ROOF/LOT/SYSTEM context ve human-inspectable instance ID üretimi eklendi.
- Numeric suffixler minimum iki hane; `100` truncate edilmez. Canonical `lot_id` context değeri integer kalır, yalnız ID suffix'i iki haneye formatlanır.
- `ConstructionProjectActivityInstance`, `ConstructionResolvedDependencyEdge` ve `ConstructionProjectActivityGraph` immutable/read-only modelleri eklendi.
- 20 exact scope rule explicit çözüldü; `NEXT_FLOOR == 1`, diğer rule'lar `floorOffset == 0` invariant'ı fail-closed doğrulandı.
- Instance/edge ordering, equivalent reordered block/facade determinism, missing selected endpoint no-repair davranışı, duplicate/self/unknown endpoint ve cycle güvenlik kapıları uygulandı.
- İzole instance'lar graph içinde korunup sorted `isolatedInstanceIds` ile raporlandı; yapay orphan edge üretilmedi.

## Exact reference parity

| Profil | Activity | Activity SHA-256 | Dependency | Dependency SHA-256 | Isolated | Isolated SHA-256 |
| --- | ---: | --- | ---: | --- | ---: | --- |
| `CSE-P01` | 1687 | `f194731552003f16221f658acb7fd45ab761a05fbbb09926bd4d9670b644dd5a` | 1702 | `0f9db030bd2098e1a25d649dddf7b5181ced75e51b0f7e3df55a930d473320c5` | 15 | `509a879fd5745019040a82344a8346c0a2c51835b4fb6af1aa880f97a6ee7048` |
| `CSE-P02` | 599 | `5282aa8c3c0b8e3d186cae838689e3776f93bc6c572198306670b0bdaef85100` | 644 | `921b54e397da434fd23e490313b10d2b3a46c6bb4cafbb6ad7df7a6d26d11f05` | 5 | `3b60bea4b7eb73751af98e72f2e785d8ae10dc49e8f748c95d791be57b34411d` |
| `CSE-P03` | 3537 | `401bc7ed1d232aca982c014275e46c235d509022a0276920aa619383265453ea` | 3605 | `74b7a8f768a0d7086511a2a346db1ba9db1441977605885e54d756474eec2681` | 39 | `545902672d0f17c90ccd3cde3efa4c95c56c86a8572ee6ee058268bc51cac73b` |

Canonical projection: UTF-8 JSON, recursively sorted object keys, compact separators; activity `instance_id ASC`, dependency exact seven-field tuple, isolated ID ascending.

## Scope and structural evidence

- 20/20 scope rule için focused positive test var. `BLOCK_TO_FIRST_FLOOR_IF_NO_BASEMENT`, canonical P02 activity applicability'si endpoint'i seçmediği için ayrı exact no-basement fixture ile positive doğrulandı; reference P02 parity yine 644 exact kaldı.
- Wrong block/floor leakage: `0`.
- NEXT_FLOOR/NEXT_BASEMENT overflow: `0`.
- No-basement bridge, last-basement bridge, top-floor-to-roof ve floor-threshold 1/2/3/4-floor cases: PASS.
- Duplicate activity instance ID, duplicate resolved edge, self edge ve invalid floorOffset kombinasyonları: fail-closed testleri PASS.
- Missing selected endpoint: edge `0`, repair `0`.
- Reference graph cycle result: `0`; ayrıca synthetic two-node cycle exact `resolved_graph_cycle` ile fail-closed.
- Generated `DERIVED-CONNECTIVITY` / `D_AI_SEED` template edge count: `0`.
- Repeated build ve reordered block/facade canonical projections: byte/order equivalent.

## Commands and exit codes

1. Reference ZIP + JSON SHA-256 precheck: exit `0`.
2. Fresh-worktree activity/dependency physical SHA-256 + `git check-attr`: exit `0`.
3. `flutter.bat pub get --offline`: exit `0`; `pubspec.yaml` / `pubspec.lock` drift `0`.
4. Changed Dart `dart.bat format`: exit `0`.
5. İlk focused üç-file koşusu: exit `1`, `101 PASS / 4 FAIL`; compile/source rule'ları geçti. Exact bulgu: canonical generator `lot_id` integer tutuyor; test ayrıca reference profillerde doğal olarak bulunmayan no-basement rule positive'ini ayrı fixture'a taşımalıydı.
6. Exact düzeltme sonrası izinli tek focused retry: exit `0`, `105/105 PASS`.
7. `flutter.bat analyze --no-pub`: exit `0`, `No issues found`.
8. `git diff --check`: exit `0`.
9. Exact allowlist classification: violation `0`; protected path drift `0`.
10. Schema/Backup/dependency-lockfile/platform classification: schema `13`, Backup `1`, dependency declarations `0`, lockfile `0`, platform `0` drift.
11. Final source revision üzerinde tek `flutter.bat test --no-pub`: exit `0`, `612/612 PASS`.

## Changed files

- `.cse/tasks/447_task.md`
- `.cse/results/447_result.md`
- `mobile/lib/domain/construction_corpus_models.dart`
- `mobile/lib/domain/construction_project_graph_models.dart`
- `mobile/lib/application/construction_corpus_repository.dart`
- `mobile/lib/application/construction_project_graph_builder.dart`
- `mobile/test/construction_project_graph_builder_test.dart`
- `mobile/test/support/construction_profile_fixtures.dart`

Allowlist dışı production edit yoktur. Corpus B64, `.gitattributes`, pubspec/lock, storage, Backup, schema/migrations, dependency declarations, platform/config ve UI değişmedi.

## Reused and intentionally omitted gates

- Reused evidence: PR #446 / merge `8d2c62a1c58991d703d4139fe63aa5d370afe8e8` schema 13, Backup format 1, canonical asset ve platform/dependency baseline; current branch drift kontrolleri ayrıca sıfırdır.
- APK/AAB, release, signing, ARM64/16 KiB, device, background/reboot ve Backup/Restore acceptance çalıştırılmadı; read-only domain/application sözleşmesi bu kapıları değiştirmiyor ve Issue #447 bunları istemiyor.
- Gerçek kullanıcı DB, backup, attachment ve device verisi okunmadı/değiştirilmedi.

## Publication state at commit evidence time

- Intentional commit ve normal push yetkili; bu dosya hazırlanırken henüz yapılmadı.
- Draft PR yetkili; bu dosya hazırlanırken henüz açılmadı.
- PR Ready, merge ve sonraki Schedule Date Engine Slice'ı yapılmadı.
