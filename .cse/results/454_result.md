# Issue #454 Result — Schedule Seed Catalog + Forward Schedule Date Engine

## Execution summary

- Validation class: `domain / read-only schedule date propagation`
- Exact base: `6d55947f73097e3ee71246fbc1496ba1f6878f01`
- Branch: `codex/issue-454-schedule-date-engine`
- İzole linked worktree:
  `V:\1_PROJECTS\2_ACTIVE\Python\CSE-Worktrees\issue-454-schedule-date-engine-20260816T002925794Z`
- Primary run: `1`
- Issue-scoped correction run: `1 / 1`
- Full Flutter run: `1 / 1`, yalnız focused PASS sonrasında
- Teknik yürütme süresi: yaklaşık `21 dakika`; `30–45 dakika` hedefi ve
  `75 dakika` hard stop içinde.

## Canonical and protected input evidence

- Input ZIP SHA-256:
  `fd2d99f1d8569ad1683bc69d5abb7de6f79c24aa0362e7c3231eabc168dd988a`
- Committed seed B64 SHA-256:
  `b80ebe90f57fa71bafcaee5102acfe3dda29368f53cd5a164b248b6530b9587e`
- Decoded seed JSON SHA-256:
  `6504b81825b56dd85caeee042b1980cbeb4e8ced0d0c81084369b1486be111b4`
- Schedule reference SHA-256:
  `cd4a42e91e3fbc4f3c01bac32cb3340e5b9c540a8be80be02f6e497b9c1f57db`
- Activity asset SHA-256:
  `a9b225d6403168f7d3fd35494eceb4907d1ea705492700bc865add95021f42ca`
- Dependency asset SHA-256:
  `07f58de9912fe76303d18b48863b45aeaaac0f0f203aa14ebe8f8b1a8db12c86`
- Seed physical contract: `316` row, `313 WORKING_DAY`, `3 CALENDAR_DAY`,
  `4` milestone; confidence `1 / 295 / 20`; status `1 / 295 / 20`.
- Seed ID/duration/status/confidence değerleri merged activity authority ile
  `316 / 316` birebir eşleşti.
- Canonical ZIP, decoded JSON ve profile/reference bundle repository'ye
  eklenmedi; yalnız compiled B64 runtime asset eklendi.

## Implemented contracts

- Tipli ve unknown değerlerde fail-closed calendar type, duration status ve
  duration confidence modelleri eklendi.
- Repository exact metadata/count/key doğrulaması, duplicate/missing/extra ID,
  malformed duration, activity-authority mismatch ve forbidden raw/price/
  resource field reddi uygular.
- UTC midnight `YYYY-MM-DD`, Monday `0`–Sunday `6`, configurable workday,
  holiday, next-workday ve working-day lag yardımcıları eklendi.
- Duration raw değeri korunur; scheduling day `ceil`, finish inclusive ve
  zero-day milestone exact uygulanır.
- Deterministic topological forward pass yalnız FS/SS ve WORKING_DAY lag kabul
  eder; multiple predecessor candidate'larında maximum kullanır.
- İzole node'lar root olarak tutulur ve işaretlenir; artificial veya
  `DERIVED-CONNECTIVITY` edge üretilmez.
- Return öncesi ve bağımsız çağrılabilir post-validation; graph/instance/seed,
  canonical date, duration finish, root, FS/SS, count, marker ve violation
  invariants'larını fail-closed doğrular.
- Output marker'ları exact: `TEST_SEED_ONLY`, `NOT_FOR_PRODUCTION`,
  `NOT_A_BASELINE`; critical-path/float alanı yoktur.

## Exact schedule parity

| Profil | Instance / edge | Schedule | Schedule SHA-256 | Root / leaf / isolated |
| --- | --- | --- | --- | --- |
| `P01` | `1687 / 1702` | `2026-09-01` – `2028-06-20` | `7b5cfff33f01cfff5f8430d5e6742d2ed2e18ddffe0c313e422e5e56c0116709` | `106 / 127 / 15`, exact SHA parity |
| `P02` | `599 / 644` | `2026-09-01` – `2027-07-19` | `f1e186407c68dbdba8b377eadeaf881c667bdc7b48a84ae24b432a179b82962a` | `27 / 43 / 5`, exact SHA parity |
| `P03` | `3537 / 3605` | `2026-09-01` – `2028-10-20` | `7772c14a62088f01c44996cb930374d5fa83f7dd982ef9ddff7eeea0023be545` | `232 / 244 / 39`, exact SHA parity |

- P01/P02/P03 root, leaf ve isolated listelerinin altı reference SHA-256 değeri
  ayrı ayrı exact PASS.
- Repeated build byte/order equivalence: PASS.
- Workday Sunday violations: `0`.
- Workday holiday violations: `0`.
- `DERIVED-CONNECTIVITY` / synthetic dependency count: `0`.
- Deliberately corrupted FS schedule bağımsız post-validation tarafından exact
  fail-closed reddedildi.

## Validation evidence

1. Canonical ZIP/B64/decoded/reference hash ve physical count precheck: PASS.
2. Offline `flutter pub get --offline`: PASS; dependency/lockfile drift `0`.
3. Changed Dart format: PASS.
4. İlk focused run: `129 PASS / 11 FAIL`. Kök neden tek Dart generic
   inference noktası (`List<dynamic>`) ve bir negatif testin daha erken physical
   count guard'ına takılmasıydı.
5. Yetkili tek correction sonrası focused existing corpus/dependency/graph +
   new seed/date run: `140 / 140 PASS`.
6. `flutter analyze --no-pub`: PASS, `No issues found`.
7. `git diff --check`: PASS.
8. Exact allowlist: PASS; violation `0`.
9. Protected drift: schema `13`, Backup format `1`, dependency declarations
   `0`, lockfile `0`, Android/iOS/config `0`, existing assets `0` drift.
10. Final source revision üzerindeki tek `flutter test --no-pub`:
    `647 / 647 PASS`.

İlk PATH tabanlı format çağrısı repository mutation üretmeden Flutter'ın shell
PATH'inde bulunmamasıyla başlamadı; repository'de kayıtlı exact Flutter
`3.44.6` / Dart `3.12.2` toolchain yolu kullanılarak aynı preflight adımı
başarıyla sürdürüldü.

## Changed files and scope

- `.cse/tasks/454_task.md`
- `.cse/results/454_result.md`
- `mobile/assets/corpus/cse_construction_schedule_seed_catalog_v0_3.b64`
- `mobile/lib/domain/construction_schedule_models.dart`
- `mobile/lib/application/construction_schedule_seed_repository.dart`
- `mobile/lib/application/construction_schedule_date_engine.dart`
- `mobile/pubspec.yaml` — yalnız yeni asset satırı
- `mobile/test/construction_schedule_seed_repository_test.dart`
- `mobile/test/construction_schedule_date_engine_test.dart`
- `mobile/test/support/construction_profile_fixtures.dart` — canonical schedule
  reference calendar reuse

Allowlist dışı production edit yoktur. Existing activity/dependency B64,
`.gitattributes`, lockfile, dependency declarations, persistence/migration,
Backup, Android/iOS/config, UI ve gerçek kullanıcı verisi değişmedi.

## Reused and intentionally omitted gates

- Reused merged evidence: PR #448 exact base üzerindeki schema 13, Backup
  format 1, activity/dependency asset ve platform/dependency baseline; current
  branch exact hash/object drift kontrolleri ayrıca PASS.
- APK/AAB, signing, release, ARM64/16 KiB, device, background/reboot ve
  Backup/Restore acceptance çalıştırılmadı; read-only domain/application
  boundary bunları değiştirmiyor ve Issue #454 yetkilendirmiyor.
- Persistence/living 7-day plan ve Issue #455 başlatılmadı.

## Publication state at evidence time

- Intentional commit ve normal push yetkili; bu kayıt hazırlanırken pending.
- Draft PR yetkili; bu kayıt hazırlanırken pending.
- PR Ready, merge, deploy ve sonraki Slice yasak; uygulanmadı.

```yaml
execution_record:
  routing_policy: "CSE-MRP-1.0"
  risk_class: "R4"
  requested_model: "gpt-5.6-sol"
  requested_reasoning_effort: "max"
  requested_mode: "standard"
  orchestration: "single-agent"
  fallback_or_downgrade_allowed: false
  actual_model: "unknown"
  actual_reasoning_effort: "unknown"
  mismatch_detected: null
  runtime_verification_status: "unverified"
  primary_runs: 1
  correction_runs: 1
  focused_attempts: 2
  full_suite_attempts: 1
  result: "PASS"
```

```yaml
review_recommendation:
  risk_observed: "R4"
  recommended_chatgpt_model: "gpt-5.6-sol"
  recommended_reasoning_effort: "max"
  recommended_mode: "standard"
```
