# Issue #117 — Backup/restore uyumluluğu ve resmî export izolasyonu

## Yetkili çalışma alanı

- Resmî yerel repository: `V:\\1_PROJECTS\\2_ACTIVE\\Python\\chief-site-engineer`
- Beklenen ve doğrulanan base: `27b5c460b9af3092ebe228d7c92a7f0aae22fcdc`
- Branch: `codex/issue-117-backup-restore-export-isolation`
- Bağlayıcı üst yol haritası: Epic #105
- Saha Takibi Epic'i: #97

## Codex seçimi

- Model: selector'daki en güçlü full Codex modeli (`GPT-5 current full Codex`)
- Reasoning: `extra high`
- Gerekçe: eski backup kabulü, fail-closed archive doğrulaması, yalnız private temporary kökte SQLite migration, observation/attachment/event ve Saha Takibi verisinin korunması, restore atomikliği ve resmî–kişisel export ayrımı aynı güvenlik sınırında doğrulanmalıdır.
- Spark, fast veya lightweight varyant kullanılmaz.

## Yapılacak iş

1. Backup format `1` için restore edilebilir schema sürümlerini tek kaynakta `(2, 3, 4)` olarak tanımlamak.
2. `verify_backup` içinde embedded database'i migration çalıştırmadan private temporary alanda doğrulamak; integrity, exact migration zinciri, observation/event/attachment count ve attachment reconciliation kontrollerini uygulamak.
3. Restore'u private temporary köke extraction, pre-migration doğrulama, gerekiyorsa schema 4'e migration, post-migration doğrulama ve tek atomic move sırasıyla yürütmek.
4. Gerçek schema 2 ve 3 fixture'larının yalnız temporary restore database üzerinde schema 4'e yükseltildiğini; kaynak archive/database ve mevcut target'ın değişmediğini test etmek.
5. Schema 4 backup/restore round-trip'inde follow-up, routine template, occurrence ve bütün append-only event geçmişini korumak.
6. Aynı resmî observation verisine sahip tracking verili/verisiz iki root'un deterministic günlük export ZIP'lerinin byte-for-byte aynı olduğunu kanıtlamak.
7. Changelog, roadmap, teknik karar, ayrıntılı learning, result ve state kayıtlarını güncellemek.

## Yetkili dosyalar

- `app/operations/backups.py`
- `tests/test_backup_restore.py`
- `tests/test_daily_export.py`
- `CHANGELOG.md`
- `ROADMAP.md`
- `docs/project_decisions.md`
- `learning/GLOSSARY.md`
- `learning/issue_117_backup_restore_export_isolation.md`
- `.cse/tasks/117_task.md`
- `.cse/results/117_result.md`
- `.cse/state/project_state.json`

`app/operations/exports.py` yalnız executable isolation testi gerçek sızıntı kanıtlarsa değiştirilebilir. `app/persistence/migrations.py` yalnız mevcut API'nin restore orchestration için yetersizliği testle kanıtlanırsa küçük ve geriye uyumlu olarak değerlendirilebilir; ön okumada böyle bir ihtiyaç bulunmamıştır.

## Korunan ve yasak kapsam

- `BACKUP_FORMAT_VERSION = 1`, daily export `format_version = 1`, exact manifest alan kümeleri, ZIP entry adları ve mevcut count anlamları değişmez.
- `app/persistence/schema.py`, migration statement'ları, field tracking mapping/repository/UoW ve application service'ler değişmez.
- `app/web/`, requirements ve workflow değişmez.
- Web/UI, scheduler/notification, mobile/offline/sync/auth, tracking export'u ve schema v5 eklenmez.
- Gerçek `CSE_DATA_ROOT` erişilmez; yalnız pytest temporary root'ları kullanılır.
- `reports/`, ignored ZIP/cache ve `exports/.gitkeep` korunur.
- Reset, clean, stash, force-push, branch deletion ve kullanıcı dosyası silme/taşıma yasaktır.

## Zorunlu doğrulama

```powershell
python -m pytest -rs tests/test_backup_restore.py tests/test_daily_export.py
python -m pytest -rs
python -m compileall -q app scripts
python -m json.tool .cse/state/project_state.json > $null
git diff --check
git diff --name-status 27b5c460b9af3092ebe228d7c92a7f0aae22fcdc...HEAD
git status --short --branch
git rev-list --left-right --count origin/master...HEAD
git rev-list --left-right --count origin/codex/issue-117-backup-restore-export-isolation...HEAD
```

Ek olarak schema version 4 ve migration dosyasının base ile aynı olduğu; application service/persistence port/UoW, web/UI/workflow/requirements diff'i bulunmadığı; backup/export format ve manifest key setlerinin değişmediği; `CSE_DATA_ROOT` boşluğu, kullanıcı dosyası hash'leri, `exports/.gitkeep` ve remote divergence doğrulanır.

## Yayın yetkisi

- Mümkünse tek güvenli commit: yetkili.
- Normal push: yetkili.
- Force push: yasak.
- Codex tarafından PR açılması: yasak.
- Merge ve branch silme: yasak.
- Push sonrasında Issue #117'ye factual completion evidence eklenir.
- Post-merge master senkronizasyonu bu görevde yapılmaz; sonraki Codex gerektiren işin başına bırakılır.
