# Issue #120 — Bugün, Unutma Kutusu ve Hızlı Yakalama Stabilizasyonu

## Amaç

Issue #119 WIP checkpoint'i içindeki yalnız ilk PC yüzeyini dar kapsamda doğrulamak ve gerekirse stabilize etmek:

- `/` yönlendirmesi ve üst navigasyon;
- boş `Bugün` ve `Unutma Kutusu` görünümleri;
- hızlı `+ Unutma` yakalama akışı;
- follow-up ayrıntısında ilk yakalama metni ve oluşturulma geçmişi;
- ortak SQLite servis bağlantısı;
- responsive ve `:focus-visible` temel CSS davranışı.

## Başlangıç kanıtı

```text
repository = V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer
branch = codex/issue-119-first-testable-pc-field-tracking-ui
HEAD = origin branch = 37f905e9d30255c39edc1db6ea4125544531c8d8
remote divergence = 0 0
tracked/staged worktree = clean
```

Önceden var olan untracked `reports/` kullanıcı dosyaları kapsam dışıdır ve korunur.

## Yetkili dosyalar

Yalnız gerektiği kadar:

```text
app/web/app.py
app/web/templates/base.html
app/web/templates/today.html
app/web/templates/follow_ups/inbox.html
app/web/templates/follow_ups/detail.html
app/web/static/app.css
tests/test_field_tracking_web.py
.cse/tasks/120_task.md
.cse/results/120_result.md
```

## Zorunlu odak testleri

Yalnız:

```powershell
python -m pytest -rs `
  tests/test_field_tracking_web.py::test_navigation_empty_states_shared_database_and_responsive_css `
  tests/test_field_tracking_web.py::test_quick_capture_normalizes_escapes_prg_and_keeps_event_history
```

Testler ilk çalıştırmada geçerse production kodu değiştirilmez. Failure varsa yalnız bu iki kabul akışını geçirecek en küçük düzeltme yapılır.

## Son doğrulama

```powershell
python -m compileall -q app scripts
python -m json.tool .cse/state/project_state.json > $null
git diff --check
```

Full suite, follow-up tam lifecycle ve rutin testleri çalıştırılmaz.

## Yasak kapsam

- Yeni branch oluşturma.
- Routine template veya lifecycle WIP kodunu değiştirme.
- Domain, application, persistence, operations, dependency veya workflow dosyalarına dokunma.
- Reset, clean, stash, amend, rebase, force-push veya branch silme.
- `reports/`, `exports/.gitkeep`, ignored ZIP/cache veya kullanıcı verisini değiştirme.
- PR açma veya merge talep etme.

## Teslim

- Aynı Issue #119 branch'i üzerinde tek küçük normal commit.
- Normal push ve remote divergence `0 0`.
- Issue #119 ve Issue #120'ye kısa factual evidence.
