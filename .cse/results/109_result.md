# Issue 109 Result - FollowUpApplicationService Çekirdek Akışları

## Yerel çalışma gerçeği

- Resmî repo: `V:\\1_PROJECTS\\2_ACTIVE\\Python\\chief-site-engineer`
- Base/master SHA: `c08f05ed52e503d966475d256bd433957f8a9adb`
- Yerel `master` ve `origin/master`: `c08f05ed52e503d966475d256bd433957f8a9adb`
- Başlangıç master divergence: `0 0`
- Branch: `codex/issue-109-follow-up-application-service-core`
- Branch başlangıç HEAD'i: base SHA ile aynı
- Bağlayıcı ürün Epic'i: `#105`
- Saha Takibi Epic'i: `#97`

## Uygulanan public application API

Yeni `app/application/field_tracking.py` modülü ve `app.application` export yüzeyi şunları sağlar:

```text
CreateFollowUp
UpdateFollowUp
ScheduleFollowUp
FollowUpQuery
FollowUpView
FollowUpApplicationService
```

Service use-case'leri:

```text
create_follow_up
get_follow_up
list_follow_ups
update_details
schedule
move_to_inbox
set_project
list_history
```

Command/query değerleri `frozen=True, slots=True` immutable dataclass'lardır; transport, Flask formu veya UI modeli değildir. `FollowUpView` yalnız application sorgu enum'udur ve database status'u üretmez.

## Create/read/query davranışı

- `create_follow_up`, kullanıcıdan yalnız `capture_text` alır; mevcut `create_follow_up_item(...)` factory'sini kullanır.
- İlk aggregate `inbox`, projesiz, zamansız, önemsiz ve revision `1`dir.
- Enjekte edilebilir clock/UUID ile canonical UTC `Z` ve lowercase canonical UUID doğrulanır.
- Aynı transaction'da sequence `1` `follow_up.created` event'i `revision/status` payload'ı ile yazılır.
- Get ve history missing aggregate için `RecordNotFound` sınırını korur.
- Listeleme deterministic repository `created_at, id` sırasını korur; status/project/personal/observation filtrelerini service-side compose eder.
- Inbox/overdue/today/upcoming sınıflandırması mevcut `classify_follow_up(...)`; now bileşimi mevcut `select_now_attention_items(...)` ile yapılır.
- Zamana bağlı view canonical `as_of_utc` ister ve gün sınırını `ZoneInfo("Europe/Istanbul")` ile hesaplar.
- Query hiçbir mutation, lazy backfill veya event üretmez.

## Mutation, sequence ve atomiklik kararı

- Her mutation tek `SQLiteUnitOfWork` ve mevcut `BEGIN IMMEDIATE` transaction'ı içindedir.
- Event sequence repository API'si genişletilmeden aynı UoW history'sinin son sequence değerinden `+1` hesaplanır.
- Aggregate update, event append ve tek commit birlikte başarılı olur veya UoW context exit ile birlikte rollback olur.
- Event UUID/validation/insert failure ve commit failure başarılıymış gibi raporlanmaz.
- Repository portlarına `allocate_sequence`, event update/delete veya aggregate delete API'si eklenmedi.

## Revision ve no-op davranışı

- Her mutation güncel aggregate'i okur ve stale `expected_revision` değerini no-op kararından önce `RevisionConflict` ile reddeder.
- Gerçek değişiklik revision'ı tam bir artırır ve `updated_at = clock()` yapar.
- Normalize edilmiş gerçek no-op mevcut immutable kaydı döndürür; revision, `updated_at`, event, clock ve UUID tüketimi değişmez.
- Update command title whitespace'ini tek boşluğa indirir; optional text alanlarını trim eder ve boş sonucu `None` yapar. Enum/bool/canonical deadline command sınırında doğrulanır.

## Mutation event'leri

- `update_details`: yalnız title/description/item_type/location/related_person/is_important/condition_text/deadline alanlarını değiştirir; `follow_up.details_updated` payload'ı revision ve alfabetik exact `changed_fields` taşır. `capture_text` immutable kalır.
- İlk `inbox -> active/waiting` planlaması `follow_up.scheduled`; planlı kaydın status/attention değişimi `follow_up.rescheduled` üretir. Schedule deadline'ı değiştirmez.
- `move_to_inbox`, yalnız active/waiting kaydı atomik `inbox + NULL next_attention_at` yapar; deadline'ı korur ve `follow_up.moved_to_inbox` üretir.
- `set_project`, non-null parent'ı `uow.projects.get(...)` ile doğrular; observation yoksa add/change/remove yapar ve `follow_up.project_changed` üretir. Nullable proje event payload'ında JSON `null` kalır.
- Observation bağlı follow-up aynı projede no-op'tur; null veya farklı proje `InvalidRecordError` ile reddedilir.

## Değişen dosyalar

```text
.cse/results/109_result.md
.cse/state/project_state.json
.cse/tasks/109_task.md
CHANGELOG.md
ROADMAP.md
app/application/__init__.py
app/application/field_tracking.py
docs/field_tracking_v0_1_contract.md
docs/project_decisions.md
learning/GLOSSARY.md
learning/issue_109_follow_up_application_service_core.md
tests/test_follow_up_application_service.py
```

Schema/migration, repository/mapping/UoW, observation service, web/UI, backup/export, workflow ve requirements production dosyalarında diff yoktur.

## Yerel doğrulama

```text
Focused:
python -m pytest -rs tests/test_follow_up_application_service.py
36 passed in 0.81s

İlgili domain/persistence/UoW/application regresyonları:
python -m pytest -rs tests/test_field_tracking.py tests/test_field_tracking_persistence.py tests/test_sqlite_unit_of_work.py tests/test_observation_application_service.py tests/test_follow_up_application_service.py
169 passed in 2.04s

Full suite:
python -m pytest -rs
831 passed, 7 skipped in 15.09s

python -m compileall -q app scripts
PASS

python -m json.tool .cse/state/project_state.json
PASS

git diff --check
PASS
```

Yedi skip, Windows ortamında symlink oluşturma ayrıcalığı bulunmamasına ait mevcut koşullu testlerdir.

Ek doğrulamalar:

- `SCHEMA_VERSION == 4`.
- `app/persistence/schema.py`, migration, mapping, repository ve UoW diff'i boş.
- Web, backup/export production, workflow ve requirements diff'i boş.
- Command/query immutability ve inputların mutation görmemesi test edildi.
- Event failure update/schedule/inbox/project mutation'larının dördünde aggregate/history rollback ile test edildi.
- Duplicate create, invalid injected clock/UUID ve commit failure yarım kayıt bırakmadan test edildi.

## Güvenlik ve korunan alanlar

- `CSE_DATA_ROOT`: unset; gerçek kullanıcı data root'una erişilmedi ve migration uygulanmadı.
- Bütün executable database testleri pytest geçici dizinlerinde çalıştı.
- `reports/` kullanıcı dosyaları untracked ve korunmuş durumda:
  - `claude_CSE_Degerlendirme_Raporu.docx` SHA-256 `3B2DB82D556D7D4591B049BCD95B03A7E2973EA43822CE2C60DC660B38899A13`
  - `CSE_BAGIMSIZ_TEKNIK_URUN_DENETIM_RAPORU_2026-07-12.md` SHA-256 `F8D3CBB2111EC7BBD12EEF673720EA3E54B2558E7545817D3E72DF18C083A1A9`
- Ignored ZIP yerinde ve stage dışındadır; SHA-256 `E96CAA2115B98C54A5B030DAB265DC62AFD509BB4F6E59E2694AF0C89165C653`.
- `exports/` yalnız `.gitkeep` içerir.

## Kesin kapsam dışı kalanlar

- Terminal `mark_waiting/complete/cancel/reopen` yaşam döngüleri
- Observation link/convert işlemleri
- `RoutineApplicationService` ve occurrence ensure/lazy backfill
- Web route/template/CSS/JavaScript ve bütün UI
- Mobile/PWA/offline/notification/auth/sync
- Schema v5/migration
- Backup formatı/manifesti ve daily export içeriği
- Legacy cleanup ve gerçek kullanıcı data root'u

## Publication durumu

Bu result dosyası tek commit'ten önce olgusal yerel kanıt olarak yazıldı. Commit SHA, normal push sonucu ve remote branch divergence `0 0` kanıtı metadata churn oluşturmamak için push sonrasında Issue #109 completion comment'inde kaydedilecektir.

- PR: Codex tarafından açılmayacak.
- Merge: Yetkili değil.
- Branch deletion: Yetkili değil.
- Sonraki dar iş: Epic #105 Faz 1'in terminal/observation veya routine/backfill dilimi; bu branch içinde başlatılmadı.
