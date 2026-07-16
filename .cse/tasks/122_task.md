# Issue #122 — Rutin Ekranları ve Occurrence Yaşam Döngüsü Stabilizasyonu

## Amaç

Issue #119 WIP branch'i içindeki yalnız rutin ve occurrence web yüzeyini dar kapsamda doğrulamak ve gerekirse stabilize etmek:

- rutin list/create/detail/deactivate akışları;
- daily, weekdays, weekly ve monthly recurrence şekilleri;
- recurrence validation ve form değerlerinin korunması;
- `/today` occurrence üretiminin idempotent olması;
- snooze, close ve reopen revision davranışı;
- invalid veya bulunmayan rutin/occurrence kimliklerinin 404 güvenliği.

## Başlangıç kanıtı

```text
repository = V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer
branch = codex/issue-119-first-testable-pc-field-tracking-ui
HEAD = origin branch = 2295a00e77738717450b35941d535391c7f12ed3
remote divergence = 0 0
tracked/staged worktree = clean
```

Önceden var olan untracked `reports/` kullanıcı dosyaları kapsam dışıdır ve korunur.

## Yetkili dosyalar

Yalnız gerektiği kadar:

```text
app/web/app.py
app/web/templates/routines/list.html
app/web/templates/routines/new.html
app/web/templates/routines/detail.html
app/web/templates/today.html
app/web/static/app.css
tests/test_field_tracking_web.py
.cse/tasks/122_task.md
.cse/results/122_result.md
```

## Zorunlu odak testleri

Yalnız:

```powershell
python -m pytest -rs `
  tests/test_field_tracking_web.py::test_routine_creation_supports_every_recurrence_shape `
  tests/test_field_tracking_web.py::test_routine_conditional_validation_preserves_safe_form_values `
  tests/test_field_tracking_web.py::test_today_occurrence_is_idempotent_and_mutations_use_revisions `
  tests/test_field_tracking_web.py::test_routine_missing_records_are_404
```

Failure varsa yalnız bu dört kabul akışını geçirecek en küçük düzeltme yapılır.

## Son doğrulama

```powershell
python -m compileall -q app scripts
python -m json.tool .cse/state/project_state.json > $null
git diff --check
```

Full suite ve restart acceptance çalıştırılmaz.

## Yasak kapsam

- Yeni branch oluşturma.
- Follow-up template veya mutation WIP kodunu değiştirme.
- Domain, application, persistence, operations, dependency veya workflow dosyalarına dokunma.
- Reset, clean, stash, amend, rebase, force-push veya branch silme.
- `reports/`, `exports/.gitkeep`, ignored ZIP/cache veya kullanıcı verisini değiştirme.
- PR açma veya merge talep etme.

## Teslim

- Aynı Issue #119 branch'i üzerinde tek küçük normal commit.
- Normal push ve remote divergence `0 0`.
- Issue #119 ve Issue #122'ye kısa factual evidence.
