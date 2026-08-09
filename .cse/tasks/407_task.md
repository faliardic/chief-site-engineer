# Issue #407 — V2.2a canonical Sicil/Puantaj identity and migration preflight

- Issue: `#407`
- Parent V2.2: `#204`
- Parent Epic: `#385`
- Previous closure: `#405` / PR `#406`
- Official repository: `V:\\1_PROJECTS\\2_ACTIVE\\Python\\chief-site-engineer`
- Linked worktree: `C:\\Users\\Fatih\\AppData\\Local\\CSE-Worktrees\\issue-407`
- Exact base: `origin/master` / `dcf25ba29aa4443785cabd5f8bdd29d825008759`
- Branch: `codex/issue-407-v2-2a-identity-migration-preflight`
- Codex model: current strongest full Codex model
- Reasoning: `Extra High`; personel/taşeron/ekip identity, tarihsel Puantaj, İSG/SGK/KKD bağları ve migration kararı veri kaybı/duplicate riskine duyarlı.
- Validation class: `domain/data identity + migration preflight`.

## Objective / changed contract

- Production contract uygulanmaz; mevcut schema/domain/application/UI/test gerçeği kanıtlanır.
- Taşeron, ekip, personel, Puantaj, İSG/SGK/KKD ve attachment identity graph çıkarılır.
- `no migration`, `schema migration`, `data migration/backfill` ve `read-model/UI-only adoption` kararları ayrı sınıflandırılır.
- Önerilen canonical identity, backward compatibility, backup etkisi, V2.2 child sequence ve ilk production child sınırı evidence olarak yazılır.

## Authorized paths

- `.cse/tasks/407_task.md`
- `.cse/results/407_result.md`
- Read-only repository/schema/application/test inspection.
- Preflight bulgusunu kanıtlamak için gerekirse yalnız dar test/evidence dosyaları.

## Validation

- Repository/schema/application/test inspection.
- Mevcut ilgili focused testler yalnız baseline kanıt gerekiyorsa çalıştırılır.
- Evidence diff için `git diff --check`.
- Production source değişmediği için full Flutter/analyze/build/device gate yok.

## Retry / time budget

- Primary run: 1.
- Blocking correction: en fazla 1.
- Aynı operation exact fix sonrası en fazla 1 retry.
- Hedef: 45 dakika.
- Hard stop: 75 dakika.

## Protected / stop conditions

- Production source, schema, migration/backfill, table/column/index/trigger ve UI değişikliği yok.
- Fuzzy/heuristic person merge veya gerçek kullanıcı data-root inspection yok.
- Attachment V2 redesign, backup format bump, V2.2b/V2.3 implementation ve release/workflow işi yok.
- Bu ihtiyaçlardan biri çıkarsa edit yapmadan Issue #407'ye exact blocker yazılır.

## Publication

- Evidence netleşince `.cse` task/result commit'i, normal push ve Draft PR yetkili.
- Ready/merge yapılmaz; V2.2b production implementation başlatılmaz.
- Ayrıntılı sonuç Issue #407 yorumuna yazılır; sohbet yalnız Issue/comment referansı taşır.
- Post-merge sync bu görevde yapılmaz.
