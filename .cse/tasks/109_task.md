# Issue 109 Task - FollowUpApplicationService Çekirdek Akışları

## Yetkili kaynaklar

- GitHub Issue: `#109` ve bütün yorumları
- Bağlayıcı üst yol haritası: Epic `#105`
- Saha Takibi ürün Epic'i: `#97`
- Önceki tamamlanan bağımlılık: Issue `#107` / PR `#108`
- Resmî yerel repo: `V:\\1_PROJECTS\\2_ACTIVE\\Python\\chief-site-engineer`
- Base branch: `master`
- Beklenen base commit: `c08f05ed52e503d966475d256bd433957f8a9adb`
- Çalışma branch'i: `codex/issue-109-follow-up-application-service-core`

## Model ve reasoning seçimi

- Codex modeli: current selector'daki en güçlü full Codex modeli (bu çalışma: GPT-5)
- Reasoning seviyesi: `Extra High`
- Seçim nedeni: Application-service transition sözleşmesi, atomik aggregate+event yazımı, optimistic revision/no-op, deterministic query ve gerçek kullanıcı verisi güvenliği birlikte doğrulanacaktır.

## Amaç

Saha Takibi'nin ilk gerçek transactional application-service sınırını yalnız şu use-case'lerle uygulamak:

```text
create_follow_up
get_follow_up
list_follow_ups
update_details
schedule
move_to_inbox
set_project
list_history
```

## Yetkili dosyalar

- `app/application/field_tracking.py`
- `app/application/__init__.py`
- `tests/test_follow_up_application_service.py`
- Gerçek zorunluluk halinde `docs/field_tracking_v0_1_contract.md`
- `CHANGELOG.md`
- `ROADMAP.md`
- `docs/project_decisions.md`
- `learning/issue_109_follow_up_application_service_core.md`
- Gerekirse `learning/GLOSSARY.md`
- `.cse/tasks/109_task.md`
- `.cse/results/109_result.md`
- `.cse/state/project_state.json`

## Yapılacak iş

1. Immutable `CreateFollowUp`, `UpdateFollowUp`, `ScheduleFollowUp` ve `FollowUpQuery` değerlerini, kalıcı olmayan `FollowUpView` sorgu enum'unu ekle.
2. Enjekte edilebilir canonical UTC clock, canonical UUID factory ve trim edilmiş non-empty local actor kullanan `FollowUpApplicationService` oluştur.
3. Hızlı capture kaydını `create_follow_up_item(...)` ile oluştur; aggregate ve `follow_up.created` event'ini aynı UoW içinde yaz.
4. Bütün follow-up sorgularını repository deterministic sırasını koruyarak service-side compose et; zaman görünümlerinde mevcut domain helper'larını kullan.
5. Ayrıntı, planlama, inbox'a taşıma ve proje değişikliklerini stale revision/no-op sınırıyla uygula; her gerçek mutation'ı doğru event ve payload ile tek transaction'da commit et.
6. Aggregate içi event sequence değerini aynı `BEGIN IMMEDIATE` UoW içinde mevcut history'nin son sequence değerinden üret; repository API'sini genişletme.
7. Focused test matrisiyle create/read/query/mutation/no-op/stale/rollback/commit failure/project-observation sınırlarını doğrula.
8. Türkçe karar, learning, roadmap, changelog, task/result/state kayıtlarını olgusal kanıtla güncelle.

## Yasak kapsam

- `mark_waiting`, `complete`, `cancel`, `reopen`
- `link_observation`, `convert_to_observation`
- `RoutineApplicationService` ve occurrence ensure/lazy backfill
- Web route, template, CSS, JavaScript veya UI
- Mobile/PWA/offline/notification/auth/sync
- Schema v5, migration veya repository port değişikliği
- Backup formatı, manifesti veya daily export içeriği
- Legacy model temizliği
- Gerçek kullanıcı `CSE_DATA_ROOT` erişimi
- `reports/`, ignored ZIP/cache veya `exports/.gitkeep` değişikliği
- Reset, clean, stash, force-push, branch silme veya PR açma

## Yerel doğrulama

```powershell
python -m pytest -rs tests/test_follow_up_application_service.py
python -m pytest -rs
python -m compileall -q app scripts
python -m json.tool .cse/state/project_state.json > $null
git diff --check
git diff --name-status c08f05ed52e503d966475d256bd433957f8a9adb...HEAD
git status --short --branch
git rev-list --left-right --count origin/master...HEAD
git rev-list --left-right --count origin/codex/issue-109-follow-up-application-service-core...HEAD
```

Ayrıca `SCHEMA_VERSION == 4`, schema/migration diff'inin boş olduğu, `CSE_DATA_ROOT` değerinin unset ve erişilmemiş olduğu, `reports/`, ignored ZIP ve `exports/.gitkeep` koruması, web/UI/backup/export production diff'inin boş olduğu ve final remote divergence'ın `0 0` olduğu doğrulanır.

## Git ve teslim yetkisi

- Mümkünse tek güvenli commit oluşturulur.
- Branch normal push ile `origin` üzerine gönderilir.
- Factual completion evidence Issue #109'a eklenir.
- Codex PR açmaz, merge yapmaz ve branch silmez.
