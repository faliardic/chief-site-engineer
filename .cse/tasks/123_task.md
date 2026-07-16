# Issue #123 — Restart Kabulü ve Resmî Sınır Stabilizasyonu

## Amaç

Issue #119 WIP branch'i içindeki yalnız ilk gerçek PC acceptance akışını ve resmî veri sınırını dar kapsamda doğrulamak ve gerekirse stabilize etmek:

- proje, follow-up ve routine kayıt akışı;
- idempotent `/today` occurrence üretimi;
- uygulama nesnesi yeniden oluşturulduğunda SQLite kalıcılığı;
- revision ve event history kalıcılığı;
- mevcut observation route'ları;
- backup oluşturma ve indirme;
- resmî günlük export'ta observation verisinin bulunması;
- follow-up ve routine metinlerinin resmî export'a sızmaması.

## Başlangıç kanıtı

```text
repository = V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer
branch = codex/issue-119-first-testable-pc-field-tracking-ui
HEAD = origin branch = 79a6cd7e77b598c593c246356a910e5df25ee795
remote divergence = 0 0
tracked/staged worktree = clean
```

Önceden var olan untracked `reports/` kullanıcı dosyaları kapsam dışıdır ve korunur.

## Yetkili dosyalar

Yalnız gerektiği kadar:

```text
app/web/app.py
app/web/templates/
app/web/static/app.css
tests/test_field_tracking_web.py
.cse/tasks/123_task.md
.cse/results/123_result.md
```

## Zorunlu odak testi

Yalnız:

```powershell
python -m pytest -rs `
  tests/test_field_tracking_web.py::test_first_pc_acceptance_flow_survives_restart_and_keeps_export_scope
```

Test ilk çalıştırmada geçerse production kodu değiştirilmez. Failure varsa yalnız bu acceptance akışını geçirecek en küçük web/test düzeltmesi yapılır.

## Son doğrulama

```powershell
python -m compileall -q app scripts
python -m json.tool .cse/state/project_state.json > $null
git diff --check
```

Full suite çalıştırılmaz.

## Yasak kapsam

- Yeni branch oluşturma.
- Domain, application, persistence, operations, dependency veya workflow dosyalarına dokunma.
- Yeni özellik ekleme veya WIP kodunu yeniden yazma.
- Reset, clean, stash, amend, rebase, force-push veya branch silme.
- `reports/`, `exports/.gitkeep`, ignored ZIP/cache veya kullanıcı verisini değiştirme.
- PR açma veya merge talep etme.

## Teslim

- Aynı Issue #119 branch'i üzerinde tek küçük normal commit.
- Normal push ve remote divergence `0 0`.
- Issue #119 ve Issue #123'e kısa factual evidence.
