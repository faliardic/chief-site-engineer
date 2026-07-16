# Issue #124 — Web Paketi ve Tam Regresyon WIP Finalizasyonu

## Amaç

Issue #119 WIP branch'ini ilk kez toplu ve sıralı olarak doğrulamak:

1. bütün `tests/test_field_tracking_web.py` paketi;
2. mevcut web/observation/backup/export regresyonları;
3. full pytest paketi;
4. compile, JSON, diff ve protected-path kontrolleri;
5. gerçek kullanıcı verisi ve artifact sınırı.

Bu görev feature veya Issue #119 dokümantasyon finalizasyonu değildir. Test failure yoksa production kodu değiştirilmez.

## Başlangıç kanıtı

```text
repository = V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer
branch = codex/issue-119-first-testable-pc-field-tracking-ui
HEAD = origin branch = 5a03396cf21366a5a3843eb981e5baf933f184e1
remote divergence = 0 0
tracked/staged worktree = clean
```

Önceden var olan untracked `reports/` kullanıcı dosyaları kapsam dışıdır ve korunur.

## Zorunlu test sırası

### 1. Web paketi

```powershell
python -m pytest -rs tests/test_field_tracking_web.py
```

### 2. İlgili regresyonlar

Issue metnindeki `tests/test_web_app.py` ve `tests/test_observation_web_edit.py` repository'de yoksa eşdeğer gerçek dosyalar belirlenir. Sahte dosya oluşturulmaz.

Mevcut eşdeğer dosyalar:

```powershell
python -m pytest -rs `
  tests/test_field_web_app.py `
  tests/test_web_backup.py `
  tests/test_backup_restore.py `
  tests/test_daily_export.py
```

`tests/test_field_web_app.py`, observation create/detail/edit/status/reporting ile web export akışlarını birlikte içerir.

### 3. Full suite

```powershell
python -m pytest -rs
```

## Son doğrulama

```powershell
python -m compileall -q app scripts
python -m json.tool .cse/state/project_state.json > $null
git diff --check
git diff --name-status 3f71ed220ab595045ae8fd59303a048b53534e24...HEAD
git status --short --branch
git rev-list --left-right --count origin/master...HEAD
git rev-list --left-right --count origin/codex/issue-119-first-testable-pc-field-tracking-ui...HEAD
```

Ayrıca `SCHEMA_VERSION == 4`, protected-path diff'i, `CSE_DATA_ROOT`, `reports/`, ignored ZIP/cache ve `exports/.gitkeep` sınırları doğrulanır.

## Yetkili dosyalar

Test failure yoksa yalnız:

```text
.cse/tasks/124_task.md
.cse/results/124_result.md
```

Gerçek WIP web regression failure varsa Issue #124 allowlist'i içindeki en küçük web/test düzeltmesi yapılabilir.

## Yasak kapsam

- Yeni branch oluşturma.
- Failure yokken production veya test kodu değiştirme.
- Domain, application, persistence, operations, dependency veya workflow dosyalarına dokunma.
- `CHANGELOG.md`, `ROADMAP.md`, project decisions, learning veya project state finalizasyonuna geçme.
- Reset, clean, stash, amend, rebase, force-push veya branch silme.
- `reports/`, `exports/.gitkeep`, ignored ZIP/cache veya kullanıcı verisini değiştirme.
- PR açma veya merge yapma.

## Teslim

- Aynı Issue #119 branch'i üzerinde tek küçük normal commit.
- Normal push ve remote divergence `0 0`.
- Issue #119 ve Issue #124'e factual evidence.
