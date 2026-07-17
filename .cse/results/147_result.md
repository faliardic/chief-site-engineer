# Issue #147 Sonuç Kaydı — MemoryIndex / RecordRef Read-Model ADR'si

## Sonuç özeti

Observation, follow-up ve routine occurrence kaynaklarını tek source tabloya
taşımadan ortak Hafıza listeleme, filtreleme, literal arama, timeline, dashboard,
özet ve diagnostic ihtiyaçlarına bağlayan yeniden üretilebilir
`MemoryIndex / RecordRef` read-model sözleşmesi hazırlandı.

Çalışma yalnız yetkili documentation/state/task/result dosyalarını değiştirdi.
Production Python, test, schema, migration, persistence, UI, template, CSS,
requirements, workflow, backup/export formatı ve gerçek kullanıcı verisi
değiştirilmedi.

## Başlangıç repository kanıtı

- Resmî yerel yol: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Doğrulanan repository root:
  `V:/1_PROJECTS/2_ACTIVE/Python/chief-site-engineer`
- `origin/master` fetch sonrasında local `master` fast-forward edildi.
- Senkronize local `master`:
  `ccf47a46fa4252446b1790437bc56371a028b406`
- Senkronize `origin/master`:
  `ccf47a46fa4252446b1790437bc56371a028b406`
- Master divergence: `0 0`
- Issue branch'i: `codex/issue-147-memory-index-record-ref-adr`
- Base commit: `ccf47a46fa4252446b1790437bc56371a028b406`
- Branch tam olarak bu base commit'ten oluşturuldu.
- Başlangıçta yalnız Issue tarafından korunması istenen untracked `reports/`
  vardı; beklenmeyen tracked veya staged proje değişikliği yoktu.
- Push öncesi remote Issue branch'i mevcut değildi.

## Değişen yetkili dosyalar

- `docs/adr/ADR-0002-memory-index-record-ref-read-model.md`
- `learning/147_memory_index_record_ref_adr.md`
- `CHANGELOG.md`
- `ROADMAP.md`
- `docs/project_decisions.md`
- `.cse/state/project_state.json`
- `.cse/tasks/147_task.md`
- `.cse/results/147_result.md`

Yetki listesi dışında proje dosyası değiştirilmedi.

## Kabul edilen bağlayıcı kararlar

### Source of truth ve kimlik

- Domain aggregate satırı + append-only event history source of truth'tur.
- `MemoryIndex` yeniden üretilebilir projection/cache'tir; source mutation,
  sessiz repair veya scope dönüşümü yapamaz.
- Kanonik ref anahtarı `(record_type, source_id)` çiftidir.
- Kararlı tekil token
  `cse-record-ref/v1/{record_type}/{source_id}` biçiminde deterministik
  türetilir; random surrogate kullanılmaz.
- İlk allowlist `observation`, `follow_up`, `routine_occurrence` değerleridir.

### Ortak alan ve mapping

- Issue'daki minimum alanlara `record_ref_id`, `status_detail`, `detail_path`
  ve `source_fingerprint` eklendi.
- Ortak status `open | waiting | completed | cancelled` sözlüğüdür; kaynak
  status/outcome ayrıntısı `status_detail` içinde kayıpsız kalır.
- Observation `occurred_at=observed_at`; follow-up
  `occurred_at=created_at`; routine occurrence
  `occurred_at=scheduled_at_utc` kullanır.
- Title/search text için Unicode NFKC, whitespace normalization, sabit alan
  sırası ve newline birleşimi seçildi; source metin mutate edilmez.
- Routine occurrence'ın bugünkü template title/project/importance bağımlılığı
  template revision dahil fingerprint ile görünür kılındı; gelecekte source
  snapshot'a geçiş projection version artışı ve rebuild ister.
- Terminal kayıt index'te kalır; terminal status ile archive ayrı kavramdır.

### Projection ve rebuild

- Normal source mutation, append-only event ve idempotent ref upsert aynı
  SQLite Unit of Work transaction'ında commit edilir.
- Composite key mevcut ve fingerprint/version aynıysa upsert no-op'tur;
  duplicate ref oluşturmaz.
- Full rebuild kayıt türü sabit sırası ve source ID tie-breaker'ıyla
  deterministic tarama yapar.
- Rebuild inactive/shadow generation'ı doğruladıktan sonra atomik aktive eder;
  partial generation kullanıcıya görünmez.
- Maintenance durumu `ready | stale | rebuilding | failed` vocabulary'sidir.
- Drift missing/orphan/duplicate/stale revision/fingerprint/version/field/privacy
  sınıflarında read-only diagnostic'tir; source'u otomatik düzeltmez.

### Consumer ve gizlilik sınırı

- Hafıza list/filter/timeline, literal search, dashboard, haftalık özet,
  Hafızayı İndir inventory ve diagnostic read-model'i okuyabilir.
- Mutation deep link üzerinden kaynak application service'e gider.
- Hafızayı İndir ve resmî/proje çıktıları içerik için source kayıtları yeniden
  okur.
- Proje Paketi/günlük/rapor source `scope=project`, aynı project, archive,
  attachment ve publication sınırlarını fail-closed yeniden doğrular.
- Project bağlantısı scope inference değildir; private kayıt resmî çıktıya
  sızamaz.
- Debug/cache/shadow/diagnostic yüzeyleri private title/search metnini
  varsayılan log veya export'a koyamaz.

## Yerel doğrulama

- `CSE_DATA_ROOT`: `UNSET`
- `python -m pytest -rs`: `983 passed, 7 skipped in 22.83s`
- Yedi skip: Windows ortamında symlink oluşturma ayrıcalığı bulunmayan mevcut
  attachment güvenlik testleri
- `python -m compileall -q app scripts`: `PASS`
- `python -m json.tool .cse/state/project_state.json > $null`: `PASS`
- `git diff --check`: `PASS`
- `git diff -- app tests requirements.txt pyproject.toml .github/workflows/pytest.yml`:
  boş
- Schema sürümü: `4` (değişmedi)
- Backup format sürümü: `1` (değişmedi)
- Günlük export format sürümü: `1` (değişmedi)
- Bütün zorunlu Issue #147 dosyaları fiziksel olarak yerelde mevcut.

## Korunan yollar ve çıktılar

- `reports/`: iki untracked kullanıcı dosyası olarak korundu; okunmadı,
  değiştirilmedi ve stage edilmedi.
- Ignored ZIP: `chief-site-engineer_adim_080_guvenli_nokta.zip` mevcut,
  `326209` byte; stage edilmedi.
- `python -m compileall` tarafından kullanılan ignored `__pycache__` alanları
  source veya commit kapsamına alınmadı.
- `exports/`: yalnız `.gitkeep` içeriyor.
- Gerçek kullanıcı data root'una erişilmedi.

## Uygulanmayan alanlar

- `MemoryIndex` / `RecordRef` Python modeli veya SQLite tablosu eklenmedi.
- Schema, migration, repository, mapper, Unit of Work veya projector yazılmadı.
- Scope field/event/backfill uygulanmadı.
- Rebuild CLI, scheduler, background worker veya async queue eklenmedi.
- Hafıza UI, route, template, CSS, literal search veya dashboard değiştirilmedi.
- Backup, Hafızayı İndir, Proje Paketi veya daily export formatı değiştirilmedi.
- Auth, role, tenant, encryption veya AI mutation eklenmedi.

## Git ve yayın durumu

Bu result dosyası commit öncesinde olgusal olarak hazırlandı:

- Commit: henüz oluşturulmadı.
- Push: henüz yapılmadı.
- Remote branch divergence: push sonrasında Issue #147 completion comment'inde
  kaydedilecek.
- Pull request: oluşturulmadı; Codex PR açmayacak.
- Merge: yapılmadı ve merge iddiası yok.

Final branch SHA, normal push sonucu ve remote divergence; metadata churn
oluşturmamak için Issue #147 completion evidence yorumunda tutulacaktır.

## Sonraki dar adım

Branch normal push ile yayımlandıktan ve GitHub incelemesi tamamlandıktan sonra
Draft PR akışı ChatGPT/GitHub sorumluluğunda ilerletilir. Faz 0 sırası Backup /
Hafızayı İndir / Proje Paketi ayrım ADR'siyle devam eder; production
`MemoryIndex` implementation'ı ayrıca yetkili Issue ve executable test ister.
