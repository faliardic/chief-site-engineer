# Issue #173 Sonuç Kaydı

## Sonuç

Issue #173 zaman sözleşmesi ve salt-okunur migration preflight, resmî repository
`V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer` içinde tamamlandı ve yerel
doğrulamaları geçti.

Bu çalışma schema migration uygulandığı veya gerçek kullanıcı satırlarının temiz
olduğu iddiası değildir. Gerçek data root açılmadı.

## Başlangıç repository kanıtı

```text
master = 16dfec0e0eec76bea2370781c52f63c74ae91b96
origin/master = 16dfec0e0eec76bea2370781c52f63c74ae91b96
divergence = 0 0
branch = codex/issue-173-p1-01-time-contract-migration-preflight
branch base = 16dfec0e0eec76bea2370781c52f63c74ae91b96
```

Başlangıçta yalnız kullanıcıya ait untracked `reports/` vardı; korundu ve içeriği
okunmadı. `CSE_DATA_ROOT` unset kaldı. `exports/` yalnız `.gitkeep` içerdi.

## Uygulanan production sözleşmesi

- `app/time_contracts.py` aware UTC normalization, seconds/microseconds
  precision, canonical/aware parse, injectable clock, `Europe/Istanbul`
  presentation, IANA timezone dönüşümü ve role-based future policy sağlar.
- Yeni timestamp write'ları `YYYY-MM-DDTHH:MM:SSZ` üretir.
- Legacy six-microsecond UTC değeri read-compatible kalır ve preflight warning'i
  olarak görünür; satır rewrite yapılmaz.
- Naive veya invalid değer fail-closed reddedilir. Web stored naive timestamp'i
  artık sessizce UTC saymaz.
- Observation, follow-up, routine, migration metadata, Backup manifest, Günlük
  Çıktı ve web clock/presentation çağrıları canonical helper'a bağlandı.
- `app/attachment_integrity.py` içindeki aware UTC `datetime` rapor saatleri
  SQLite storage text olmadığı için araştırma envanterine alındı, değiştirilmedi.

## Salt-okunur preflight

`app/persistence/time_preflight.py`:

- yalnız explicit existing path ve `database_kind=temporary | test` kabul eder;
- SQLite'ı URI `mode=ro` ve `PRAGMA query_only = ON` ile açar;
- schema 2 için 10, schema 3/4 için 26 timestamp kolonu inceler;
- row/null/parseable/canonical/noncanonical/invalid/naive/non-UTC/microsecond/
  future count, min/max, proposed mapping, nullable/present ve finding üretir;
- historical future, invalid, naive, missing column ve unsupported schema'yı
  blocker; non-UTC, noncanonical UTC ve microseconds durumunu warning sayar;
- future schedule/attention/deadline değerine izin verir;
- raw timestamp, row ID, business content veya database path raporlamaz;
- migration, schema change, data-root discovery ve row rewrite yapmaz.

## Compatibility

```text
SCHEMA_VERSION = 4
RESTORABLE_SCHEMA_VERSIONS = (2, 3, 4)
BACKUP_FORMAT_VERSION = 1
daily export format_version = 1
```

Schema migration zinciri, Backup/Restore formatı ve Günlük Çıktı wire alanları
değişmedi. Backup/Restore ve Günlük Çıktı mevcut regresyon testleri canonical
helper değişiklikleriyle birlikte geçti.

## Test kanıtı

Final full suite:

```text
python -m pytest -rs
997 passed, 7 skipped in 28.73s
```

Yedi skip, Windows symlink oluşturma ayrıcalığı bulunmayan mevcut güvenlik
testleridir; failure yoktur.

Yeni test matrisi:

- UTC round-trip ve non-UTC offset normalization;
- Istanbul presentation;
- naive/invalid fail-closed;
- seconds ve explicit six-microsecond precision;
- past/future role policy;
- generic DST fold;
- fixed aware clock;
- restore-compatible schema 2/3 ve current schema 4 preflight;
- database byte ve directory entry değişmezliği;
- sensitive content ve database path leakage yokluğu;
- JSON round-trip.

İlk full-suite çalışması test fixture migration saatini gerçek clock'tan aldığı
için sabit `as_of` sınırını çalışma sırasında geçti. Fixture migration metadata'sı
snapshot öncesinde sabit UTC'ye çekildi; final suite deterministik biçimde geçti.
Production preflight davranışı bu düzeltmede değiştirilmedi.

## Kalite ve güvenlik kapıları

```text
python -m compileall -q app scripts                         PASS
python -m json.tool .cse/state/project_state.json > $null   PASS
git diff --check                                            PASS
requirements / pyproject / workflow / schema diff           EMPTY
master == origin/master                                     PASS
master divergence                                           0 0
exports                                                      only .gitkeep
CSE_DATA_ROOT                                                unset
existing PR for branch                                      0
```

Gerçek kullanıcı database'i, Backup, attachment, log veya pilot içeriği
okunmadı. Untracked `reports/`, ignored ZIP ve cache dosyaları korunup stage
kapsamı dışında bırakılacaktır.

## Değişen dosyalar

1. `.cse/tasks/173_task.md`
2. `.cse/results/173_result.md`
3. `.cse/state/project_state.json`
4. `CHANGELOG.md`
5. `README.md`
6. `ROADMAP.md`
7. `app/time_contracts.py`
8. `app/field_tracking.py`
9. `app/application/observations.py`
10. `app/application/field_tracking.py`
11. `app/application/routines.py`
12. `app/persistence/contracts.py`
13. `app/persistence/migrations.py`
14. `app/persistence/time_preflight.py`
15. `app/operations/backups.py`
16. `app/operations/exports.py`
17. `app/web/app.py`
18. `tests/test_time_contracts.py`
19. `tests/test_time_preflight.py`
20. `docs/173_time_contract_and_migration_preflight.md`
21. `docs/project_decisions.md`
22. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
23. `learning/173_time_contract_and_migration_preflight.md`
24. `learning/GLOSSARY.md`

Task allowlist'i içindeki `tests/test_backup_restore.py` ve
`tests/test_daily_export.py` değiştirilmedi; mevcut regression kanıtı olarak
çalıştırıldı.

## Yayın durumu

Tek ordinary commit ve normal push yetkilidir. Amend, rebase, force-push, PR,
merge ve branch silme yasaktır. Commit/push/final remote SHA, yayın sonrasında
Issue #173 completion evidence yorumunda kaydedilecektir.

## Sonraki dar adım

P1.02 geriye dönük observation create contract'ı ancak Issue #173 review/merge
sonrası ayrı ve açık Issue ile başlayabilir. Bu branch form, route, schema
migration, archive/unarchive veya MemoryIndex başlatmaz.
