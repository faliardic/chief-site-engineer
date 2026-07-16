# Issue 115 Result - RoutineApplicationService ve Yedi Günlük Lazy Backfill

## Sonuç

Issue #115'in tam implementation kapsamı, Epic #105 ve Issue #97 ürün sınırlarına bağlı olarak `0df88681e289b89941a55925e608186917772ee2` güvenli başlangıç noktasından uygulandı.

Resmî yerel repository:

```text
V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer
```

Çalışma branch'i:

```text
codex/issue-115-routine-application-service-backfill
```

Başlangıç doğrulaması:

```text
local master  = 0df88681e289b89941a55925e608186917772ee2
origin/master = 0df88681e289b89941a55925e608186917772ee2
divergence    = 0 0
```

## Uygulanan production davranışı

- Yeni `app/application/routines.py` modülünde immutable create/update/query/close değerleri ve public `RoutineApplicationService` eklendi.
- Template create/get/list/update/deactivate/history akışları project existence, nullable kişisel proje, optimistic revision, stale-before-no-op ve append-only event kurallarıyla uygulandı.
- Template update yalnız command allowlist'ini değiştirir; normalized no-op clock/UUID/event tüketmez ve gerçek update event'i alfabetik exact `changed_fields` taşır.
- `ensure_occurrences(as_of_utc)`, canonical UTC anını `Europe/Istanbul` gününe çevirip bugün dahil son yedi yerel günü mevcut recurrence helper'larıyla hesaplar.
- Existing `(routine_template_id, occurrence_local_date)` kaydı event/revision/clock/UUID tüketmeden döner; `add_if_absent` ve unique constraint son savunma olarak korunur.
- Yeni geçmiş gün önce open revision 1 + created event, sonra aynı transaction'da closed/missed revision 2 + missed event olur. Bugün open revision 1 kalır.
- Future veya yedi günden eski eksik occurrence üretilmez; start/end, daily/weekdays/weekly/monthly, monthly-31 ve inactive local-day sınırları korunur.
- Occurrence list/status/template/view ve history sorguları salt-okunur kalır; gizli backfill başlatmaz.
- Snooze yalnız attention'ı, close status/outcome/completed timestamp'i, reopen ise outcome temizliği ve yeni attention'ı değiştirir; schedule snapshot alanları korunur.
- Kullanıcı close komutu yalnız `completed`, `no_work`, `not_required` kabul eder; `missed` yalnız otomatik geçmiş backfill sonucudur.
- Aggregate mutation, append-only event sequence ve commit mevcut tek `BEGIN IMMEDIATE` Unit of Work transaction'ında birlikte başarılı olur veya rollback olur.

## Değişen dosyalar

```text
.cse/tasks/115_task.md
.cse/results/115_result.md
.cse/state/project_state.json
app/application/routines.py
app/application/__init__.py
tests/test_routine_application_service.py
docs/field_tracking_v0_1_contract.md
CHANGELOG.md
ROADMAP.md
docs/project_decisions.md
learning/GLOSSARY.md
learning/issue_115_routine_application_service.md
```

## Test kanıtı

Focused application-service paketi:

```text
python -m pytest -rs tests/test_routine_application_service.py
48 passed in 1.06s
```

İlgili domain/persistence/UoW/follow-up regresyon paketi:

```text
python -m pytest -rs tests/test_field_tracking.py tests/test_field_tracking_persistence.py tests/test_sqlite_unit_of_work.py tests/test_follow_up_application_service.py
224 passed in 3.91s
```

Tam regresyon paketi:

```text
python -m pytest -rs
948 passed, 7 skipped in 18.59s
```

Yedi skip, Windows ortamında symlink oluşturma ayrıcalığı bulunmayan mevcut attachment testleridir; Issue #115 kapsamıyla ilgili failure yoktur.

Focused matris şunları doğrular:

- immutable command/query normalization ve daily/weekdays/weekly/monthly validation;
- personal/project create-list ve exact created event;
- bütün template update allowlist alanları, alfabetik `changed_fields`, no-op, stale, inactive rejection ve snapshot korunması;
- deactivate, exact retry, stale-before-no-op ve history;
- bugün open revision 1 + created event;
- geçmiş gün open-create ardından closed/missed revision 2 + iki sıralı event;
- tam yedi gün, future/older exclusion, start/end clipping ve dört recurrence türü;
- monthly 31 no-shift ve inactive İstanbul yerel deactivation sınırı;
- ikinci ensure tam idempotency ve existing occurrence için sıfır clock/UUID/event tüketimi;
- date/template/occurrence deterministic return order ve unique-constraint son savunması;
- template/ensure/occurrence event ve commit failure rollback'i;
- occurrence template/status/view query ve closed-view exclusion;
- snooze no-op/stale/closed/rollback;
- üç close outcome'u, note normalization, event mapping, missed rejection ve stale;
- reopen outcome temizliği, snapshot koruması, stale/open rejection ve rollback;
- created/snoozed/completed/reopened history sequence.

## Yapısal doğrulama

```text
python -m compileall -q app scripts                       PASS
python -m json.tool .cse/state/project_state.json         PASS
git diff --check                                          PASS
SCHEMA_VERSION                                            4
CSE_DATA_ROOT                                             unset
exports                                                   yalnız .gitkeep
```

Base ile mevcut içerik hash'leri:

```text
app/persistence/schema.py
68b3f503b87eb773e555bf5d5ffa4d53cdf15f64

app/persistence/migrations.py
cf606fe8c790fc28cd326b05faff4709dbe2bf48
```

Schema, migration, mapping, repository ve Unit of Work dosyalarında değişiklik yoktur. `app/application/field_tracking.py`, `app/application/observations.py`, web/UI, requirements, workflow ve backup/export production kodu değiştirilmemiştir.

## Korunan kullanıcı dosyaları

Başlangıç ve final yerel doğrulama hash'leri aynıdır:

```text
reports/claude_CSE_Degerlendirme_Raporu.docx
3B2DB82D556D7D4591B049BCD95B03A7E2973EA43822CE2C60DC660B38899A13

reports/CSE_BAGIMSIZ_TEKNIK_URUN_DENETIM_RAPORU_2026-07-12.md
F8D3CBB2111EC7BBD12EEF673720EA3E54B2558E7545817D3E72DF18C083A1A9

chief-site-engineer_adim_080_guvenli_nokta.zip
E96CAA2115B98C54A5B030DAB265DC62AFD509BB4F6E59E2694AF0C89165C653
```

`reports/` untracked kullanıcı içeriği olarak korunmuş, ignored ZIP/cache ve `exports/.gitkeep` değiştirilmemiştir.

## Kapsam dışında kalanlar

- Web route/template/CSS/JS ve routine UI
- Scheduler, background notification veya uygulama kapalı runtime
- Backup/restore compatibility ve resmî export izolasyonu
- Mobile/PWA/offline/sync/auth
- Schema migration, mapping/repository/UoW port genişletmesi
- Legacy cleanup ve gerçek kullanıcı data root'u

## Yayın kaydı

Commit, normal push, final local/remote branch SHA ve divergence kanıtı oluşturulan commit SHA'sı ile GitHub Issue #115 completion yorumunda olgusal olarak kaydedilecektir. Codex PR açmayacak; merge veya branch silme yapılmayacaktır.

Bir sonraki dar ürün adımı Epic #105 Faz 2'deki backup/restore compatibility ve resmî export izolasyonudur; bu görev o fazı başlatmamıştır.
