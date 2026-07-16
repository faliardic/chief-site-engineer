# Issue 107 Task - Follow-up Event Vocabulary ve SQLite Schema v4

## Yetkili kaynaklar

- GitHub Issue: `#107` ve son execution yorumu
- Bağlayıcı üst yol haritası: Epic `#105`
- Saha Takibi ürün sözleşmesi: Epic `#97` ve `docs/field_tracking_v0_1_contract.md`
- Önceki tamamlanan iş: Issue `#103`, squash-merge PR `#106`
- Resmî yerel repo: `V:\\1_PROJECTS\\2_ACTIVE\\Python\\chief-site-engineer`
- Base branch: `master`
- Beklenen base commit: `c6632ace7897f1a57c13d9a838b93752438f1eb3`
- Çalışma branch'i: `codex/issue-107-follow-up-event-vocabulary-v4`

## Model ve reasoning seçimi

- Codex modeli: current selector'daki en güçlü full Codex modeli (bu çalışma: GPT-5)
- Reasoning seviyesi: `Extra High`
- Seçim nedeni: Append-only event sözleşmesi, immutable SQLite migration metinleri, transaction rollback davranışı ve mevcut verinin byte-for-byte korunması birlikte doğrulanacaktır.

## Amaç

Gelecekteki `FollowUpApplicationService` mutation'larının audit anlamını karşılayacak üç event türünü domain ve SQLite CHECK sözleşmesine eklemek; schema v3 verisini değiştirmeden schema v4'e yükseltmek. Bu görev application service uygulamaz.

## Yetkili dosyalar

- `app/field_tracking.py`
- `app/persistence/schema.py`
- Gerekliyse yalnız event mapping/repository sözleşmesi dosyaları
- `docs/field_tracking_v0_1_contract.md`
- `tests/test_field_tracking.py`
- `tests/test_persistence_migrations.py`
- `tests/test_field_tracking_persistence.py`
- Gerekli regresyon testleri
- `CHANGELOG.md`
- `ROADMAP.md`
- `docs/project_decisions.md`
- `learning/issue_107_follow_up_event_vocabulary_ve_sqlite_schema_v4.md`
- Gerekirse `learning/GLOSSARY.md`
- `.cse/tasks/107_task.md`
- `.cse/results/107_result.md`
- `.cse/state/project_state.json`

## Yapılacak iş

1. Mevcut enum sıra ve değerlerini koruyarak sona `follow_up.details_updated`, `follow_up.moved_to_inbox` ve `follow_up.project_changed` ekle.
2. `FOLLOW_UP_EVENT_TYPES` türetilmiş sözleşmesinin yeni değerleri otomatik taşıdığını ve payload JSON determinism/validation davranışının korunduğunu doğrula.
3. `SCHEMA_VERSION` değerini `3`ten `4`e çıkar ve v1/v2/v3 migration statement içeriklerine dokunmadan tek immutable v4 migration ekle.
4. `follow_up_events` tablosunu aynı kolon, constraint, FK ve veriyle yeniden kur; yalnız CHECK event listesini genişlet. Mevcut satırların bütün alanlarını ve `payload_json` metnini aynen kopyala.
5. Fresh v4 ile v3 fixture -> v4 imzalarını, rollback/idempotency/future-version davranışını ve yeni event round-trip'lerini test et.
6. Event-payload sözleşmesini, teknik kararı ve ayrıntılı Türkçe öğrenme kaydını güncelle.
7. State/result kayıtlarını yalnız komutla doğrulanmış olgularla güncelle.

## Event payload sözleşmesi

- `follow_up.details_updated`: en az `revision` ve alfabetik sıralı benzersiz string `changed_fields`; immutable `capture_text` listede bulunmaz.
- `follow_up.moved_to_inbox`: en az `revision`, `from_status`, `previous_next_attention_at`; sonuç `status=inbox` ve `next_attention_at=NULL` anlamına gelir.
- `follow_up.project_changed`: en az `revision`, `from_project_id`, `project_id`; nullable project değerleri JSON `null` olarak korunur.

## Yasak kapsam

- Application/query service, command/query dataclass, backfill veya UI/web route eklenmez.
- Notification, PWA, mobile, offline, auth, sync veya legacy cleanup yapılmaz.
- Repository'ye update/delete/sequence allocator API eklenmez.
- Backup formatı/manifesti ve günlük resmî export davranışı değiştirilmez.
- v1/v2/v3 migration statement içerikleri değiştirilmez.
- Gerçek kullanıcı data root'una erişilmez veya migration uygulanmaz.
- `reports/`, `exports/`, ignored ZIP/cache ve kullanıcı dosyaları değiştirilmez.
- Reset, clean, stash, force-push, branch silme veya PR açma yoktur.

## Yerel doğrulama

```powershell
python -m pytest -rs
python -m compileall -q app scripts
python -m json.tool .cse/state/project_state.json > $null
git diff --check
git diff --name-status c6632ace7897f1a57c13d9a838b93752438f1eb3...HEAD
git status --short --branch
git rev-list --left-right --count origin/master...HEAD
git rev-list --left-right --count origin/codex/issue-107-follow-up-event-vocabulary-v4...HEAD
```

Ayrıca v1/v2/v3 migration statement içeriği base ile eşit; `CSE_DATA_ROOT` unset ve erişilmemiş; `reports/`, ZIP ve `exports/` korunmuş; production web/application-service diff'i boş; branch local/remote divergence `0 0` olmalıdır.

## Git ve teslim yetkisi

- Mümkünse tek güvenli commit oluşturulur.
- Branch normal push ile `origin` üzerine gönderilir.
- Factual completion evidence Issue #107'ye eklenir.
- Codex PR açmaz, merge yapmaz ve branch silmez.
