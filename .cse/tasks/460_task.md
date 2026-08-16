# Issue #460 Görev Kaydı — CSE V2 Living 7-Day Plan Truth-Sync

## Kimlik ve yürütme zemini

- Repository: `faliardic/chief-site-engineer`
- Resmî yerel repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- İzole linked worktree: `V:\1_PROJECTS\2_ACTIVE\Python\CSE-Worktrees\issue-460-v2-truth-sync-20260816T000000Z`
- Branch: `docs/issue-460-v2-living-plan-truth-sync`
- Base branch: `master`
- Exact expected base: `447916be0b3ddd2af75b0fe85f8c7f710f29c1cd`
- GitHub Issue: https://github.com/faliardic/chief-site-engineer/issues/460
- Owner authorization: https://github.com/faliardic/chief-site-engineer/issues/460#issuecomment-5306495364
- Task/result identity: `460`
- Validation class: `docs / canonical source-authority truth-sync`
- Task risk: `R3`

## Model routing

```yaml
model_routing:
  policy_version: "CSE-MRP-1.0"
  task_risk: "R3"
  orchestrator:
    chatgpt_model: "gpt-5.6-sol"
    chatgpt_reasoning_effort: "xhigh"
  codex_model: "gpt-5.6-sol"
  codex_reasoning_effort: "xhigh"
  execution_mode: "standard"
  orchestration: "single-agent"
  selection_reason: "Multiple canonical product/source authorities and machine-readable state must be reconciled without rewriting history or starting production work."
  routing_request_evidence: "https://github.com/faliardic/chief-site-engineer/issues/460#issuecomment-5306495364"
  allowed_fallback: null
  review_floor:
    chatgpt_model: "gpt-5.6-sol"
    chatgpt_reasoning_effort: "xhigh"
  fail_closed_if_mismatch: true
```

Invocation ve runtime actual metadata görünmüyorsa değerler tahmin edilmeyecek;
`unknown / null / unverified` semantiği kullanılacaktır. Otomatik fallback veya
downgrade yasaktır. Görünür model/effort uyuşmazlığında fail-closed durulur.

## Amaç ve değişen sözleşmeler

Tracked canonical ürün kaynakları ile machine-readable state, sahibin güncel
ürün kararıyla eşitlenecektir:

- 13 maddelik V2 paketi korunacak; yalnız Items `1..4` complete kalacaktır.
- Revised Item 5, `7 Günlük Yaşayan İş Programı / İş ve Gün Planı`, current
  product direction olacaktır.
- Eski Item 6 iş/gün planı semantiği revised Item 5 içinde korunacak; Günlük Log
  Çıktısı v1 Item 6'ya taşınacaktır.
- Merged schedule runtime ve immutable persistent snapshot foundation through
  PR #459 kaydedilecektir.
- Human-readable ve machine-readable current truth; safe merge
  `447916be0b3ddd2af75b0fe85f8c7f710f29c1cd`, schema `14`, backup format `1`
  ve mobile version `0.1.0+1` üzerinde anlaşacaktır.
- Living plan, immutable reference schedule'dan ayrı mutable/evented kullanıcı
  kararı katmanı olarak tariflenecektir; reference schedule sessizce yeniden
  yazılmayacaktır.
- Look-ahead/WBS, living-plan kararıyla çatışacak biçimde kategorik V2 dışı
  sayılmayacaktır. Full Gantt/Primavera replacement, approved baseline,
  critical path, automatic reforecast, productivity learning ve resource
  optimization pre-UI MVP dışında kalacaktır.
- Current phase `truth-sync complete / Living Plan MVP Core ready` olacaktır.
- Item 5 complete, Living Plan UI/APK/device acceptance, public/store release
  veya production readiness iddiası üretilmeyecektir.

## Exact final path allowlist

1. `ROADMAP.md`
2. `docs/v2/CSE_V2_SCOPE.md`
3. `docs/v2/CSE_V2_TRANSITION_DECISION.md`
4. `README.md`
5. `mobile/README.md`
6. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
7. `docs/project_decisions.md`
8. `.cse/state/project_state.json`
9. `CHANGELOG.md`
10. `.cse/tasks/460_task.md`
11. `.cse/results/460_result.md`

Preflight gereksiz bir yolu çıkarabilir; yeni yol ekleyemez. Historical task,
result, ADR, podcast, merged PR evidence ve old Issue/PR kayıtları yeniden
yazılamaz.

## Minimum yeterli doğrulama

- Exact base/master ve PR #459 merge doğrulaması.
- Task dosyasının substantive editlerden önce oluşturulduğunun doğrulanması.
- Final changed-file kümesinin exact allowlist içinde ve beklenen küme ile aynı
  olduğunun doğrulanması.
- `.cse/state/project_state.json` parse kontrolü.
- Edited canonical sources içinde stale/çelişkili current-direction ifade
  taraması.
- Item numaralarının contiguous `1..13` ve yalnız Items `1..4` complete olması.
- Look-ahead/WBS ile full Gantt/Primavera sınırının güncel kararla uyumu.
- Schema `14`, backup format `1`, mobile version `0.1.0+1`, safe merge ve current
  direction tutarlılığı.
- Available Markdown/readability/link kontrolleri.
- `git diff --check`.
- Production/mobile source, test, schema, migration, backup, platform,
  workflow ve dependency drift'inin `0` olması.
- Historical evidence path drift'inin `0` olması.

## Validation bütçesi ve yeniden kullanılan kanıt

- Focused tests: JSON/Markdown/link/readability, phrase/item/state ve Git diff
  kontrolleri.
- Allowed broad gates: none.
- Reused evidence: PR #459 merge commit
  `447916be0b3ddd2af75b0fe85f8c7f710f29c1cd`; database `22/22`, snapshot
  repository `11/11`, Schedule Engine `23/23`, backup/restore `36/36`, full
  Flutter `663/663`, analyze/integrity/FK PASS. Production sözleşmeleri bu docs
  görevinde değişmediği için tekrar çalıştırılmaz.
- Minimum physical-device acceptance: none.
- Retry budget: `1` primary run; yalnız blocking correction için en fazla `1`
  correction run; aynı başarısız operasyonda exact fix sonrası en fazla `1`
  retry.
- Time budget: docs default target `10–15` dakika, hard stop `25` dakika.

No Flutter/Python test, build, APK/AAB, device, backup roundtrip, release veya
full gate çalıştırılacaktır.

## Yasak kapsam ve stop koşulları

- Production source, mobile source, test, schema/migration, backup, platform,
  workflow, dependency, UI, APK/device, deploy veya sonraki Slice değişikliği
  yasaktır.
- Issue #385 body mutation yasaktır.
- Canonical veya ignored ZIP stage/commit/değişikliği yasaktır.
- Ready, merge ve Living Plan production implementation yasaktır.
- Exact base mismatch, PR #459'un merged olmaması, additional path ihtiyacı,
  13-item uzlaşmazlığı, state representation engeli, visible routing mismatch,
  final edited docs/state çelişkisi veya protected drift halinde commit/push
  yapılmadan durulur.

## Publication sınırı

PASS halinde yalnız:

1. bir intentional documentation/state commit;
2. normal push;
3. bir Draft PR;
4. Issue #460 completion evidence ve zorunlu `execution_record` ile
   `review_recommendation` blokları

yetkilidir. PR Ready yapılmayacak ve merge edilmeyecektir. Post-merge local
master sync bu execution'ın parçası değildir; merge ayrıca yetkilendirildikten
sonraki Codex-required run'a bırakılır.
