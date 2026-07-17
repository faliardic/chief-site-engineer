# Issue #147 Görev Kaydı — MemoryIndex / RecordRef Read-Model ADR'si

## Çalışma bağlamı

- Resmî yerel repo: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Doğrulanan base commit: `ccf47a46fa4252446b1790437bc56371a028b406`
- Başlangıç `master` / `origin/master`: `ccf47a46fa4252446b1790437bc56371a028b406`
- Başlangıç divergence: `0 0`
- Branch: `codex/issue-147-memory-index-record-ref-adr`
- Bağlayıcı execution Epic: Issue #127
- Bağlayıcı phase Epic: Issue #128
- Ürün Epic'i: Issue #105
- Saha Takibi Epic'i: Issue #97
- Ön koşul: Issue #145 / PR #146 merge edilmiş ADR-0001
- Codex modeli: `standart full Codex`
- Reasoning: `High`
- Seçim gerekçesi: Değişiklik yalnız dokümantasyon, karar kaydı ve factual
  state senkronizasyonudur; production kodu, test, schema veya migration
  değiştirilmez. High reasoning, üç ayrı domain kaydının ortak read-model
  eşlemesini ve gizlilik sınırını tutarlı biçimde tanımlamak için seçildi.

## Amaç

Observation, follow-up ve routine occurrence kaynak kayıtlarını tek tabloya
taşımadan ortak Hafıza listeleme, filtreleme, literal arama, timeline ve
diagnostic ihtiyaçları için yeniden üretilebilir `MemoryIndex / RecordRef`
read-model sözleşmesini bağlayıcı ADR olarak tanımlamak.

## Yetkili dosyalar

- `docs/adr/ADR-0002-memory-index-record-ref-read-model.md`
- `learning/147_memory_index_record_ref_adr.md`
- `CHANGELOG.md`
- `ROADMAP.md`
- `docs/project_decisions.md`
- `.cse/state/project_state.json`
- `.cse/tasks/147_task.md`
- `.cse/results/147_result.md`

## Karar kapsamı

1. Kaynak domain tabloları ile append-only event geçmişinin source of truth
   kalması; read-model'in yeniden üretilebilir ve kaynakta mutation yapmayan
   türetilmiş veri olması.
2. `RecordRef` kimliği, `record_type` allowlist'i ve gelecekteki kayıt türü
   genişletme sınırı.
3. Ortak alanların kesin anlamı ve observation/follow-up/routine occurrence
   mapping tablosu.
4. Ortak status normalizasyonu, title/search text, önem, scope/project,
   archive/terminal ve deep-link kuralları.
5. Transactional projection ile explicit rebuild/backfill'i birleştiren hybrid
   güncelleme stratejisi; crash/retry/drift ve idempotent upsert davranışı.
6. Deterministic backfill sırası, tie-breaker, bakım root'u, başarısızlıkta
   partial/stale görünürlük ve source mutation yasağı.
7. Hafıza, literal arama, dashboard, haftalık özet, Hafızayı İndir envanteri ve
   diagnostic consumer sınırları.
8. ADR-0001 kapsam/gizlilik kuralları ile private veri sızıntısını fail-closed
   engelleyen çıktı sınırı.
9. Reddedilen alternatifler, uygulanmayan alanlar ve sonraki implementation
   görevleri için executable acceptance matrisi.

## Yasak kapsam

- Production Python, test, template, CSS, schema, migration, persistence,
  requirements, workflow, backup veya export formatı değiştirilmez.
- `MemoryIndex`, `RecordRef`, scope veya projection uygulanmış/migrate edilmiş
  gibi gösterilmez.
- Source domain tabloları birleştirilmez; event history replay motoru, async
  queue, scheduler, AI mutation, auth, role veya tenant eklenmez.
- Gerçek kullanıcı `CSE_DATA_ROOT` yoluna erişilmez.
- `reports/`, ignored ZIP/cache ve `exports/.gitkeep` değiştirilmez.
- Reset, clean, stash, amend, rebase, force-push, branch deletion ve kullanıcı
  dosyası silme/taşıma/üzerine yazma yapılmaz.

## Zorunlu doğrulamalar

```powershell
python -m pytest -rs
python -m compileall -q app scripts
python -m json.tool .cse/state/project_state.json > $null
git diff --check
git diff -- app tests requirements.txt pyproject.toml .github/workflows/pytest.yml
```

Ayrıca yalnız yetkili dosyaların değiştiği, `exports/` içinde yalnız
`.gitkeep` bulunduğu, `reports/` ve ignored ZIP/cache'in korunduğu ve gerçek
`CSE_DATA_ROOT` kullanılmadığı doğrulanır.

## Git ve yayın izinleri

- Tek ordinary commit: yetkili.
- Commit mesajı: `Define MemoryIndex and RecordRef ADR`
- Normal push: yetkili.
- Amend/rebase/force-push: yasak.
- PR oluşturma: Codex için yasak.
- Merge ve branch silme: yasak.
- Completion evidence: push sonrasında GitHub Issue #147 yorumuna eklenir.
- Post-merge sync: bu görevde yapılmaz; merge sonrasında sonraki gerekli Codex
  çalışmasının başında `master` fast-forward edilir.
