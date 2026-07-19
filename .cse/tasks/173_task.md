# Issue #173 Görev Kaydı

## Kimlik

- Issue: `#173 — P1.01: Olay zamanı sözleşmesi ve migration preflight`
- Parent phase Epic: `#129`
- Parent execution Epic: `#127`
- Branch: `codex/issue-173-p1-01-time-contract-migration-preflight`
- Base: `master` / `16dfec0e0eec76bea2370781c52f63c74ae91b96`
- Model: `standart full Codex`
- Reasoning: `High`
- Seçim nedeni: Kullanıcı ve Issue, dar bir canonical zaman sözleşmesi ile
  salt-okunur migration preflight için standart full Codex ve High reasoning'i
  açıkça seçti; kapsam schema migration veya gerçek veri dönüşümü içermiyor.

## Amaç

`occurred_at` / `observed_at`, `created_at` ve `updated_at` anlamlarını
kesinleştirmek; UTC saklama ile `Europe/Istanbul` sunumunu merkezi ve test
edilebilir yapmak; yalnız açıkça verilen disposable temp/test SQLite dosyalarını
inceleyen veri-minimal, JSON-ready ve salt-okunur migration preflight üretmektir.

## Yetkili Dosyalar

1. `app/time_contracts.py`
2. `app/persistence/time_preflight.py`
3. `app/persistence/contracts.py`
4. `app/persistence/migrations.py`
5. `app/field_tracking.py`
6. `app/application/observations.py`
7. `app/application/field_tracking.py`
8. `app/application/routines.py`
9. `app/web/app.py`
10. `app/operations/backups.py`
11. `app/operations/exports.py`
12. `tests/test_time_contracts.py`
13. `tests/test_time_preflight.py`
14. `tests/test_backup_restore.py`
15. `tests/test_daily_export.py`
16. `README.md`
17. `ROADMAP.md`
18. `CHANGELOG.md`
19. `docs/project_decisions.md`
20. `docs/173_time_contract_and_migration_preflight.md`
21. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
22. `learning/173_time_contract_and_migration_preflight.md`
23. `learning/GLOSSARY.md`
24. `.cse/state/project_state.json`
25. `.cse/tasks/173_task.md`
26. `.cse/results/173_result.md`

Liste, zorunlu kaynak araştırmasından sonra dar uygulanabilir üst sınırdır;
gerekmeyen yetkili dosyaya sırf listede olduğu için dokunulmaz. Bu listenin
dışındaki repository dosyaları değiştirilemez.

## Zorunlu Ön Okuma ve Araştırma

- `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
- `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
- GitHub Issue #173 ve bütün yorumları
- ADR-0001, ADR-0002 ve Faz 0 closure belgesi
- Observation, follow-up, routine ve event zaman alanları
- Application clock, SQLite schema/migration/mapper/repository call-site'ları
- Backup/Restore, Günlük Çıktı ve web zaman yüzeyleri
- Bu task kaydı, ilk yetkili yerel dosya olarak oluşturulduktan sonra tekrar okunur.

## Uygulama Sözleşmesi

- Kalıcı canonical an `YYYY-MM-DDTHH:MM:SSZ` biçiminde timezone-aware UTC'dir.
- Aware non-UTC değer açıkça UTC'ye normalize edilir; naive veya invalid değer
  fail-closed reddedilir.
- Varsayılan üretim hassasiyeti saniyedir; microsecond davranışı açık precision
  seçimiyle deterministiktir.
- UTC now sabit clock ile test edilebilir; yerel sistem timezone'una güvenmez.
- Kullanıcı sunumu `Europe/Istanbul` ile yapılır.
- Gelecek zaman politikası alan anlamına göre açık ve deterministiktir.

## Salt-Okunur Preflight

- Yalnız çağıranın açıkça verdiği temp/test database path'i açılır.
- SQLite `mode=ro` ve `query_only` kullanılır; migration, schema değişikliği ve
  row rewrite yapılmaz.
- Schema `2`, `3` ve `4` restore compatibility kapsamında incelenir.
- Sonuç schema version, timestamp column envanteri, row/null/parse/naive/
  non-UTC/microsecond/future sayaçları, min/max, proposed mapping, warning ve
  blocker bulgularını içerir.
- Raw satır içeriği, row id, açıklama, not, kişi, path veya payload raporlanmaz.
- `as_of` çağıran tarafından açıkça verilir; gerçek saat ve data-root keşfi yoktur.

## Yasak Kapsam

- Gerçek kullanıcı data root'u, Backup, attachment, log veya pilot içeriği okunmaz.
- `CSE_DATA_ROOT` unset kalır; `reports/`, ignored ZIP/cache ve `exports/.gitkeep`
  korunur.
- Schema bump, migration çalıştırma/ekleme, satır düzeltme veya otomatik data-root
  keşfi yapılmaz.
- P1.02 form/route/UI, archive/unarchive, scope, MemoryIndex, Backup v2,
  mobile/offline ve security implementation başlatılmaz.
- Reset, clean, stash, rebase, amend, force-push, delete, move veya branch silme
  yapılmaz.
- Codex PR açmaz ve merge yapmaz.

## Doğrulama

```powershell
python -m pytest -rs
python -m compileall -q app scripts
python -m json.tool .cse/state/project_state.json > $null
git diff --check
git diff --name-status 16dfec0e0eec76bea2370781c52f63c74ae91b96..HEAD
git status --short --branch
git status --ignored --short --untracked-files=all
```

Ek kapılar: UTC round-trip, offset normalization, Istanbul sunumu, naive/invalid
fail-closed, saniye/microsecond precision, past/future policy, generic DST,
fixed clock, schema 2/3/4 preflight, database byte değişmezliği, sensitive-content
leakage yokluğu ve Backup/Restore/Günlük Çıktı regresyon testleridir.

## Yayın

- Tek ordinary commit: `Define time contract and migration preflight`
- Normal push
- Issue #173 completion evidence yorumu
- PR yok
- Amend, rebase ve force-push yok
