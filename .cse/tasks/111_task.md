# Issue 111 Task - Follow-up Bekleme ve Terminal Yaşam Döngüleri

## Yetkili kaynaklar

- GitHub Issue: `#111` ve bütün yorumları
- Bağlayıcı üst yol haritası: Epic `#105`
- Saha Takibi ürün Epic'i: `#97`
- Tamamlanan bağımlılık: Issue `#109` / PR `#110`
- Resmî yerel repo: `V:\\1_PROJECTS\\2_ACTIVE\\Python\\chief-site-engineer`
- Base branch: `master`
- Beklenen base commit: `230a7238f01066e784f369d1793df2d4f3375f4d`
- Çalışma branch'i: `codex/issue-111-follow-up-terminal-lifecycle`

## Model ve reasoning seçimi

- Codex modeli: current selector'daki en güçlü full Codex modeli (bu çalışma: GPT-5)
- Reasoning seviyesi: `Extra High`
- Seçim nedeni: Dört yaşam döngüsü geçişi; optimistic revision, no-op, append-only event sırası ve transaction rollback sınırlarıyla birlikte doğrulanacaktır.

## Amaç

Mevcut `FollowUpApplicationService` sınırına yalnız şu yaşam döngüsü işlemlerini eklemek:

```text
mark_waiting
complete
cancel
reopen
```

## Yetkili dosyalar

- `app/application/field_tracking.py`
- `app/application/__init__.py`
- `tests/test_follow_up_application_service.py`
- `docs/field_tracking_v0_1_contract.md`
- `CHANGELOG.md`
- `ROADMAP.md`
- `docs/project_decisions.md`
- `learning/issue_111_follow_up_terminal_lifecycle.md`
- Gerekirse `learning/GLOSSARY.md`
- `.cse/tasks/111_task.md`
- `.cse/results/111_result.md`
- `.cse/state/project_state.json`

## Yapılacak iş

1. Immutable `MarkWaiting` ve `CompleteFollowUp` komutlarını doğrulama ve normalizasyon kurallarıyla ekle.
2. `mark_waiting` ile inbox/active kayıtları waiting durumuna geçir; aynı waiting değerlerini stale kontrolünden sonra gerçek no-op say.
3. `complete` ile açık kayıtları yalnız `completed` veya `not_required` outcome'u kullanarak tamamla.
4. `cancel` ile açık kayıtları cancelled outcome'u ve normalize edilmiş notla iptal et.
5. `reopen` ile terminal kaydı attention verilmediğinde inbox, verildiğinde active olarak yeniden aç; terminal alanları temizle.
6. Her gerçek mutation için aggregate update ve append-only event'i aynı UoW transaction'ında sakla; sıra numarasını mevcut history'den üret.
7. Focused test matrisiyle durumlar, outcome'lar, no-op, stale revision, payload, sıra, alan koruma ve event/commit rollback davranışlarını doğrula.
8. Türkçe sözleşme, karar, learning, roadmap, changelog, task/result/state kayıtlarını olgusal kanıtla güncelle.

## Yasak kapsam

- Observation link/convert akışları
- Routine application service veya occurrence üretimi
- Persistence schema, migration, mapping, repository portu veya UoW değişikliği
- Web route, template, CSS, JavaScript veya UI
- Mobile/PWA/offline/notification/auth/sync
- Backup/export formatı veya production veri erişimi
- Legacy model temizliği
- Gerçek kullanıcı `CSE_DATA_ROOT` erişimi
- `reports/`, ignored ZIP/cache veya `exports/.gitkeep` değişikliği
- Reset, clean, stash, force-push, branch silme, PR açma veya merge

## Yerel doğrulama

```powershell
python -m pytest -rs tests/test_follow_up_application_service.py
python -m pytest -rs
python -m compileall -q app scripts
python -m json.tool .cse/state/project_state.json > $null
git diff --check
git diff --name-status 230a7238f01066e784f369d1793df2d4f3375f4d...HEAD
git status --short --branch
git rev-list --left-right --count origin/master...HEAD
git rev-list --left-right --count origin/codex/issue-111-follow-up-terminal-lifecycle...HEAD
```

Ayrıca `SCHEMA_VERSION == 4`, schema/migration diff'inin boş olduğu, `CSE_DATA_ROOT` değerinin unset ve erişilmemiş olduğu; `reports/`, ignored ZIP ve `exports/.gitkeep` hash koruması; web/UI/backup/export production diff'inin boş olduğu ve final remote divergence'ın `0 0` olduğu doğrulanır.

## Git ve teslim yetkisi

- Mümkünse tek güvenli commit oluşturulur.
- Branch normal push ile `origin` üzerine gönderilir.
- Factual completion evidence Issue #111'e eklenir.
- Codex PR açmaz, merge yapmaz ve branch silmez.
