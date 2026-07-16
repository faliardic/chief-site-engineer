# Issue #119 — İlk Test Edilebilir PC Saha Takibi Arayüzü

## Yetkili çalışma alanı

- Resmî yerel repository: `V:\\1_PROJECTS\\2_ACTIVE\\Python\\chief-site-engineer`
- Beklenen ve doğrulanan base: `3f71ed220ab595045ae8fd59303a048b53534e24`
- Branch: `codex/issue-119-first-testable-pc-field-tracking-ui`
- Bağlayıcı üst yol haritası: Epic #105
- Saha Takibi Epic'i: #97

## Codex seçimi

- Model: selector'daki en güçlü full Codex modeli (`GPT-5 current full Codex`)
- Reasoning: `extra high`
- Gerekçe: mevcut Flask observation yüzeyine iki transactional application service'in eklenmesi; optimistic revision, PRG, Europe/Istanbul zaman dönüşümü, responsive server-rendered arayüz, restart kalıcılığı ve geniş web regresyon matrisi birlikte güvenceye alınmalıdır.
- Spark, fast veya lightweight varyant kullanılmaz.

## Yapılacak iş

1. `create_app(data_root)` içinde aynı SQLite dosyasını kullanan observation, follow-up ve routine servislerini açık config anahtarlarıyla kurmak.
2. `/` yönlendirmesini `/today` yapmak ve `Bugün`, `Unutma Kutusu`, `Rutinler`, `Gözlemler` navigasyonunu eklemek.
3. `Bugün` görünümünde canonical `now_utc` ile idempotent occurrence üretimi, follow-up/routine zaman görünümleri ve hızlı `+ Unutma` akışını sunmak.
4. Follow-up inbox/detail/history ile details/project/schedule/waiting/inbox/complete/cancel/reopen mutation formlarını yalnız mevcut application service API'leriyle uygulamak.
5. Routine list/create/detail/deactivate ve occurrence snooze/close/reopen akışlarını yalnız mevcut application service API'leriyle uygulamak.
6. Europe/Istanbul kullanıcı zamanı dönüşümü, optimistic revision 409, validation 400/409, PRG redirect, flash mesajı, HTML escaping ve kullanıcı dostu sunum sözlüğünü sağlamak.
7. Masaüstü ve dar ekranda erişilebilir server-rendered HTML/CSS yüzeyi oluşturmak.
8. İlk PC kabul senaryosu ile navigation, boundary, stale revision, validation, restart, observation/backup/export regresyonlarını executable web testleriyle kanıtlamak.
9. Changelog, roadmap, teknik karar, ayrıntılı learning, result ve state kayıtlarını güncellemek.

## Yetkili dosyalar

- `app/web/app.py`
- `app/web/templates/base.html`
- `app/web/templates/today.html`
- `app/web/templates/follow_ups/*.html`
- `app/web/templates/routines/*.html`
- `app/web/static/app.css`
- `tests/test_field_tracking_web.py`
- Gerekiyorsa mevcut web testlerinde dar regresyon güncellemeleri
- `CHANGELOG.md`
- `ROADMAP.md`
- `docs/project_decisions.md`
- `learning/GLOSSARY.md`
- `learning/issue_119_first_testable_pc_field_tracking_ui.md`
- `.cse/tasks/119_task.md`
- `.cse/results/119_result.md`
- `.cse/state/project_state.json`

`app/application/__init__.py` yalnız gerçek import zorunluluğu testle kanıtlanırsa değiştirilebilir.

## Korunan ve yasak kapsam

- `app/field_tracking.py`, application service/domain sözleşmeleri ve `app/persistence/` değişmez.
- `app/operations/backups.py`, `app/operations/exports.py`, backup/export formatları ve manifest sözleşmeleri değişmez.
- Requirements ve workflow değişmez.
- Phone/remote access, PWA/offline/sync, notification/background scheduler, auth, attachment modeli, otomatik observation conversion, schema migration ve legacy cleanup eklenmez.
- Global singleton, background thread, scheduler, SPA/framework, haricî CSS/JS/CDN veya client-side state store eklenmez.
- Gerçek `CSE_DATA_ROOT` erişilmez; yalnız pytest temporary root'ları kullanılır.
- `reports/`, ignored ZIP/cache ve `exports/.gitkeep` korunur.
- Reset, clean, stash, force-push, branch deletion ve kullanıcı dosyası silme/taşıma/üzerine yazma yasaktır.

## Zorunlu doğrulama

```powershell
python -m pytest -rs tests/test_field_tracking_web.py
python -m pytest -rs
python -m compileall -q app scripts
python -m json.tool .cse/state/project_state.json > $null
git diff --check
git diff --name-status 3f71ed220ab595045ae8fd59303a048b53534e24...HEAD
git status --short --branch
git rev-list --left-right --count origin/master...HEAD
git rev-list --left-right --count origin/codex/issue-119-first-testable-pc-field-tracking-ui...HEAD
```

Ek olarak schema/application/persistence/backup/export protected path diff'i, mevcut observation web testleri, `SCHEMA_VERSION == 4`, `CSE_DATA_ROOT` boşluğu, kullanıcı dosyası hash'leri, `exports/.gitkeep` ve remote divergence doğrulanır.

## Yayın yetkisi

- Mümkünse tek güvenli commit: yetkili.
- Normal push: yetkili.
- Force push: yasak.
- Codex tarafından PR açılması: yasak.
- Merge ve branch silme: yasak.
- Push sonrasında Issue #119'a factual completion evidence eklenir.
- Post-merge master senkronizasyonu bu görevde yapılmaz; sonraki Codex gerektiren işin başına bırakılır.
