# Issue 107 Result - Follow-up Event Vocabulary ve SQLite Schema v4

## Yerel çalışma gerçeği

- Resmî repo: `V:\\1_PROJECTS\\2_ACTIVE\\Python\\chief-site-engineer`
- Base/master SHA: `c6632ace7897f1a57c13d9a838b93752438f1eb3`
- Yerel `master` ve `origin/master`: `c6632ace7897f1a57c13d9a838b93752438f1eb3`
- Başlangıç master divergence: `0 0`
- Branch: `codex/issue-107-follow-up-event-vocabulary-v4`
- Branch başlangıç HEAD'i: base SHA ile aynı
- Bağlayıcı ürün Epic'i: `#105`
- Saha Takibi Epic'i: `#97`

## Uygulanan production kapsamı

`FollowUpEventType` mevcut sıra ve değerleri korunarak yalnız şu üç değerle genişletildi:

```text
follow_up.details_updated
follow_up.moved_to_inbox
follow_up.project_changed
```

`SCHEMA_VERSION = 4` yapıldı. V1/v2/v3 migration statement içerikleri değiştirilmeden zincirin sonuna tek v4 migration eklendi. V4:

1. aynı kolon, nullability, PK, FK, sequence CHECK, actor CHECK, payload ve unique sözleşmesiyle replacement `follow_up_events_v4` tablosunu kurar;
2. mevcut yedi kolonu açık `INSERT ... SELECT` ile aynen kopyalar;
3. eski tabloyu düşürür;
4. replacement tabloyu `follow_up_events` olarak yeniden adlandırır.

Allowed CHECK list'i eski dokuz tür ile yalnız üç yeni türden oluşur. `ON DELETE CASCADE` eklenmedi.

Mapping, repository ve Unit of Work kodunda değişiklik gerekmedi. Mevcut genel enum mapper yeni türleri round-trip eder; event repository yalnız `add/list` sunmaya ve yalnız `ORDER BY sequence` kullanmaya devam eder.

## Payload sözleşmesi

- `follow_up.details_updated`: mutation sonrası `revision` ve alfabetik sıralı benzersiz string `changed_fields`; immutable `capture_text` listede bulunmaz.
- `follow_up.moved_to_inbox`: mutation sonrası `revision`, `from_status`, `previous_next_attention_at`; ana kayıt sonucu `inbox + NULL next_attention_at` anlamındadır.
- `follow_up.project_changed`: mutation sonrası `revision`, `from_project_id`, `project_id`; nullable proje değerleri JSON `null` olarak korunur.

Bu görev payload'ları üretecek application service'i uygulamaz.

## Değişen dosyalar

```text
.cse/tasks/107_task.md
.cse/results/107_result.md
.cse/state/project_state.json
CHANGELOG.md
ROADMAP.md
app/field_tracking.py
app/persistence/schema.py
docs/field_tracking_v0_1_contract.md
docs/project_decisions.md
learning/GLOSSARY.md
learning/issue_107_follow_up_event_vocabulary_ve_sqlite_schema_v4.md
tests/test_field_tracking.py
tests/test_field_tracking_persistence.py
tests/test_persistence_migrations.py
```

Production application service, web, mapping, repository, Unit of Work, backup/export ve workflow dosyalarında diff yoktur.

## Migration ve persistence kanıtı

- Fresh database schema v4'e gelir.
- Schema v3 fixture v4'e yükselir.
- Fresh v4 ve upgraded v4 `sqlite_master` signature değerleri eşittir.
- V3 event satırının bütün kolonları ve canonical olmayan whitespace taşıyan `payload_json` metni v4 sonrasında birebir aynıdır.
- Üç yeni tür database insert ve repository round-trip testlerinden geçer.
- Unknown event CHECK tarafından reddedilir.
- Duplicate aggregate sequence reddedilir.
- Foreign key, actor CHECK ve no-cascade davranışı korunur.
- Gerçek v4 rebuild statement'larının sonuna eklenen bozuk SQL tam rollback yapar; eski tablo/satır geri gelir, replacement kalmaz ve version listesi `[1, 2, 3]` kalır.
- Migration runner idempotency ve unknown future version fail-closed regresyonları geçer.
- Base ile current v1/v2/v3 statement eşitliği: `true`
- V1/v2/v3 statement fingerprint: `a3d2786da2e3c7b07b64b04c261877b82b82484c5315c09434093e0dea3dc63c`

## Yerel doğrulama

```text
Focused:
python -m pytest -rs tests/test_field_tracking.py tests/test_persistence_migrations.py tests/test_field_tracking_persistence.py
135 passed in 0.77s

Full suite:
python -m pytest -rs
795 passed, 7 skipped in 12.22s

python -m compileall -q app scripts
PASS

python -m json.tool .cse/state/project_state.json
PASS

git diff --check
PASS
```

Yedi skip, Windows ortamında symlink oluşturma ayrıcalığı bulunmamasına ait mevcut koşullu testlerdir.

## Güvenlik ve korunan alanlar

- `CSE_DATA_ROOT`: unset; gerçek kullanıcı data root'una erişilmedi ve migration uygulanmadı.
- Bütün executable database testleri pytest geçici dizinlerinde çalıştı.
- `reports/` kullanıcı dosyaları untracked ve korunmuş durumda:
  - `claude_CSE_Degerlendirme_Raporu.docx` SHA-256 `3B2DB82D556D7D4591B049BCD95B03A7E2973EA43822CE2C60DC660B38899A13`
  - `CSE_BAGIMSIZ_TEKNIK_URUN_DENETIM_RAPORU_2026-07-12.md` SHA-256 `F8D3CBB2111EC7BBD12EEF673720EA3E54B2558E7545817D3E72DF18C083A1A9`
- Ignored ZIP yerinde ve stage dışındadır; SHA-256 `E96CAA2115B98C54A5B030DAB265DC62AFD509BB4F6E59E2694AF0C89165C653`.
- `exports/` yalnız `.gitkeep` içerir.
- Backup formatı/manifest alan kümesi ve daily export production davranışı değiştirilmedi.
- `FollowUpApplicationService`, `RoutineApplicationService`, command/query dataclass, lazy backfill, UI/web route, notification, mobile/offline/auth/sync veya legacy cleanup eklenmedi.

## Publication durumu

Bu result dosyası tek commit'ten önce olgusal yerel kanıt olarak yazıldı. Commit SHA, normal push sonucu ve remote branch divergence `0 0` kanıtı metadata churn oluşturmamak için push sonrasında Issue #107 completion comment'inde kaydedilecektir.

- PR: Codex tarafından açılmayacak.
- Merge: Yetkili değil.
- Branch deletion: Yetkili değil.
- Sonraki dar iş: GitHub review sonrasında Epic #105 Faz 1 application service görevleri; bu branch içinde başlatılmadı.
