# Issue 112 Task - Follow-up Observation Bağlantısı ve Resmî Gözleme Dönüşüm

## Yetkili kaynaklar

- GitHub Issue: `#112` ve bütün yorumları
- Bağlayıcı üst yol haritası: Epic `#105`
- Saha Takibi ürün Epic'i: `#97`
- Tamamlanan bağımlılık: Issue `#111` / PR `#113`
- Resmî yerel repo: `V:\\1_PROJECTS\\2_ACTIVE\\Python\\chief-site-engineer`
- Base branch: `master`
- Beklenen base commit: `c1182a43500814887a5f804d95dab09019912cc6`
- Çalışma branch'i: `codex/issue-112-follow-up-observation-link-convert`

## Model ve reasoning seçimi

- Codex modeli: current selector'daki en güçlü full Codex modeli (bu çalışma: GPT-5)
- Reasoning seviyesi: `Extra High`
- Seçim nedeni: Kişisel/resmî veri sınırı, observation-project çapraz değişmezleri, terminal conversion, optimistic revision/no-op ve atomik aggregate+event rollback birlikte doğrulanacaktır.

## Amaç

Mevcut `FollowUpApplicationService` sınırına yalnız şu açık kullanıcı işlemlerini eklemek:

```text
link_observation
convert_to_observation
```

## Yetkili dosyalar

- `app/application/field_tracking.py`
- Yeni public class gerekirse `app/application/__init__.py`
- `tests/test_follow_up_application_service.py`
- `docs/field_tracking_v0_1_contract.md`
- `CHANGELOG.md`
- `ROADMAP.md`
- `docs/project_decisions.md`
- `learning/issue_112_follow_up_observation_link_conversion.md`
- Gerekirse `learning/GLOSSARY.md`
- `.cse/tasks/112_task.md`
- `.cse/results/112_result.md`
- `.cse/state/project_state.json`

## Yapılacak iş

1. `link_observation` ile mevcut observation'ı follow-up'a bağla; observation projesini source of truth kabul et.
2. Projesiz follow-up'a observation projesini aynı mutation içinde ata; aynı projeyi koru, farklı projeyi reddet.
3. Aynı observation bağlantısını stale kontrolünden sonra gerçek no-op say; farklı mevcut observation'ı sessizce değiştirme.
4. Link işleminde açık veya terminal lifecycle alanlarını değiştirme ve kişisel kaydı otomatik resmî kayda dönüştürme.
5. `convert_to_observation` ile yalnız açık follow-up'ı var olan observation'a bağlayıp `converted_to_observation` sonucu ile tamamla.
6. Conversion sırasında attention'ı temizle, deadline/ayrıntıları koru ve ayrıca `observation_linked` event'i üretme.
7. Exact converted retry'ı stale kontrolünden sonra no-op say; diğer terminal sonuçları ve farklı project/observation birleşimlerini reddet.
8. Gerçek mutation için aggregate update ve tek append-only event'i aynı Unit of Work transaction'ında commit et.
9. Focused test matrisiyle link/conversion status, project, observation, no-op, stale, payload, sıra ve rollback sınırlarını doğrula.
10. Türkçe sözleşme, karar, learning, roadmap, changelog, task/result/state kayıtlarını olgusal kanıtla güncelle.

## Yasak kapsam

- Otomatik observation oluşturma veya follow-up metninden observation içeriği kopyalama
- Observation formu/UI veya `ObservationApplicationService` değişikliği
- Routine application service veya occurrence lazy backfill
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
git diff --name-status c1182a43500814887a5f804d95dab09019912cc6...HEAD
git status --short --branch
git rev-list --left-right --count origin/master...HEAD
git rev-list --left-right --count origin/codex/issue-112-follow-up-observation-link-convert...HEAD
```

Ayrıca `SCHEMA_VERSION == 4`; schema/migration/mapping/repository/UoW diff'inin boş olduğu; observation service, web/UI, requirements, workflow ve backup/export production diff'inin bulunmadığı; `CSE_DATA_ROOT` değerinin unset ve erişilmemiş olduğu; `reports/`, ignored ZIP ve `exports/.gitkeep` hash koruması ile final remote divergence'ın `0 0` olduğu doğrulanır.

## Git ve teslim yetkisi

- Mümkünse tek güvenli commit oluşturulur.
- Branch normal push ile `origin` üzerine gönderilir.
- Factual completion evidence Issue #112'ye eklenir.
- Codex PR açmaz, merge yapmaz ve branch silmez.
