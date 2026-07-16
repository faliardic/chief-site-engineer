# Issue #115 — RoutineApplicationService ve yedi günlük lazy backfill

## Yetkili çalışma alanı

- Resmî yerel repository: `V:\\1_PROJECTS\\2_ACTIVE\\Python\\chief-site-engineer`
- Beklenen ve doğrulanan base: `0df88681e289b89941a55925e608186917772ee2`
- Branch: `codex/issue-115-routine-application-service-backfill`
- Bağlayıcı üst yol haritası: Epic #105
- Saha Takibi Epic'i: #97

## Codex seçimi

- Model: selector'daki en güçlü full Codex modeli (`GPT-5 current full Codex`)
- Reasoning: `extra high`
- Gerekçe: recurrence/template lifecycle, yedi günlük idempotent üretim, geçmiş günün aynı transaction'da `missed` kapanışı, optimistic revision/no-op, append-only sequence ve gerçek kullanıcı verisi güvenliği birlikte korunmalıdır.
- Spark, fast veya lightweight varyant kullanılmaz.

## Yapılacak iş

1. `app/application/routines.py` içinde immutable command/query değerlerini ve `RoutineApplicationService` sınıfını eklemek.
2. Template create/get/list/update/deactivate/history use-case'lerini uygulamak.
3. Son yedi `Europe/Istanbul` yerel günü için idempotent `ensure_occurrences` orchestration'ını uygulamak.
4. Geçmiş eksik occurrence'ı önce open revision 1 + created event, sonra aynı transaction'da closed/missed revision 2 + missed event olarak kaydetmek.
5. Occurrence list/view/history, snooze, close ve reopen yaşam döngüsünü uygulamak.
6. Aggregate mutation, append-only event ve commit atomikliğini; stale-before-no-op ve failure rollback davranışını testlerle kanıtlamak.
7. Contract, changelog, roadmap, karar, ayrıntılı learning, result ve state kayıtlarını güncellemek.

## Yetkili dosyalar

- `app/application/routines.py`
- `app/application/__init__.py`
- `tests/test_routine_application_service.py`
- `docs/field_tracking_v0_1_contract.md`
- `CHANGELOG.md`
- `ROADMAP.md`
- `docs/project_decisions.md`
- `learning/GLOSSARY.md`
- `learning/issue_115_routine_application_service.md`
- `.cse/tasks/115_task.md`
- `.cse/results/115_result.md`
- `.cse/state/project_state.json`

`app/field_tracking.py` yalnız mevcut helper'ların yetersizliği testle kanıtlanırsa değiştirilebilir. Mevcut ön okumada böyle bir ihtiyaç bulunmamıştır.

## Korunan ve yasak kapsam

- `app/persistence/schema.py`, migration, mapping, repository ve UoW portları değişmez.
- `app/application/observations.py`, `app/web/`, requirements ve workflow değişmez.
- Web/UI, scheduler/notification, mobile/offline/sync, backup/restore veya export davranışı eklenmez.
- Gerçek `CSE_DATA_ROOT` erişilmez.
- `reports/`, ignored ZIP/cache ve `exports/.gitkeep` korunur.
- Reset, clean, stash, force-push, branch deletion ve kullanıcı dosyası silme/taşıma yasaktır.

## Zorunlu doğrulama

```powershell
python -m pytest -rs tests/test_routine_application_service.py
python -m pytest -rs
python -m compileall -q app scripts
python -m json.tool .cse/state/project_state.json > $null
git diff --check
git diff --name-status 0df88681e289b89941a55925e608186917772ee2...HEAD
git status --short --branch
git rev-list --left-right --count origin/master...HEAD
git rev-list --left-right --count origin/codex/issue-115-routine-application-service-backfill...HEAD
```

Ek olarak schema version 4, protected path diff yokluğu, `CSE_DATA_ROOT` boşluğu, `reports/`/ZIP hash'leri, `exports/.gitkeep` ve remote divergence doğrulanır.

## Yayın yetkisi

- Mümkünse tek güvenli commit: yetkili.
- Normal push: yetkili.
- Force push: yasak.
- Codex tarafından PR açılması: yasak.
- Merge ve branch silme: yasak.
- Push sonrasında Issue #115'e factual completion evidence eklenir.
- Post-merge master senkronizasyonu bu görevde yapılmaz; sonraki Codex gerektiren işin başına bırakılır.
