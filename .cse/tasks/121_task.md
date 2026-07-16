# Issue #121 — Follow-up Detay ve Yaşam Döngüsü Stabilizasyonu

## Amaç

Issue #119 WIP branch'i içindeki yalnız follow-up detay ve mutation yüzeyini dar kapsamda doğrulamak ve gerekirse stabilize etmek:

- follow-up ayrıntısı ve event history;
- details ve project mutation formları;
- schedule, waiting ve move-to-inbox işlemleri;
- complete, cancel ve reopen işlemleri;
- optimistic revision conflict ve validation güvenliği;
- Europe/Istanbul `datetime-local` dönüşümü.

## Başlangıç kanıtı

```text
repository = V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer
branch = codex/issue-119-first-testable-pc-field-tracking-ui
HEAD = origin branch = 426dd04dcfed781203a7ed8ea1f9091a5266e1a9
remote divergence = 0 0
tracked/staged worktree = clean
```

Önceden var olan untracked `reports/` kullanıcı dosyaları kapsam dışıdır ve korunur.

## Yetkili dosyalar

Yalnız gerektiği kadar:

```text
app/web/app.py
app/web/templates/follow_ups/detail.html
app/web/templates/follow_ups/inbox.html
app/web/templates/today.html
app/web/static/app.css
tests/test_field_tracking_web.py
.cse/tasks/121_task.md
.cse/results/121_result.md
```

## Zorunlu odak testleri

Yalnız:

```powershell
python -m pytest -rs `
  tests/test_field_tracking_web.py::test_follow_up_full_lifecycle_project_time_conversion_and_history `
  tests/test_field_tracking_web.py::test_follow_up_validation_conflict_and_missing_records_are_safe
```

Testler ilk çalıştırmada geçerse production kodu değiştirilmez. Failure varsa yalnız bu iki kabul akışını geçirecek en küçük düzeltme yapılır.

## Son doğrulama

```powershell
python -m compileall -q app scripts
python -m json.tool .cse/state/project_state.json > $null
git diff --check
```

Full suite, routine testleri ve restart acceptance çalıştırılmaz.

## Yasak kapsam

- Yeni branch oluşturma.
- Routine template veya occurrence WIP kodunu değiştirme.
- Domain, application, persistence, operations, dependency veya workflow dosyalarına dokunma.
- Reset, clean, stash, amend, rebase, force-push veya branch silme.
- `reports/`, `exports/.gitkeep`, ignored ZIP/cache veya kullanıcı verisini değiştirme.
- PR açma veya merge talep etme.

## Teslim

- Aynı Issue #119 branch'i üzerinde tek küçük normal commit.
- Normal push ve remote divergence `0 0`.
- Issue #119 ve Issue #121'e kısa factual evidence.
