# Issue #141 Görev Kaydı — Repository Truth ve Kanonik Durum Senkronizasyonu

## Çalışma bağlamı

- Resmî yerel repo: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Beklenen ve doğrulanan base commit: `1d4b2b7f9ace5e7d474c4893d24404ceae2faede`
- Branch: `codex/issue-141-repository-truth-roadmap-sync`
- Bağlayıcı execution Epic: Issue #127
- Bağlayıcı phase Epic: Issue #128
- Codex modeli: selector'da görünen güncel standart full Codex modeli
- Reasoning: `High`
- Seçim nedeni: production davranışı değiştirmeyen, çok dosyalı repository truth ve state senkronizasyonu

## Amaç

PR #126 ile merge edilen Issue #119 gerçeğini README, ROADMAP, CHANGELOG,
proje kararları ve `.cse/state/project_state.json` içinde olgusal biçimde
senkronlamak; Issue #127 ile #128–#140 faz haritasını görünür kılmak.

## Yetkili dosyalar

- `README.md`
- `ROADMAP.md`
- `CHANGELOG.md`
- `docs/project_decisions.md`
- `.cse/state/project_state.json`
- `.cse/tasks/141_task.md`
- `.cse/results/141_result.md`

## Yapılacak işler

1. Son merged safe point'i Issue #119 / PR #126 / merge commit
   `1d4b2b7f9ace5e7d474c4893d24404ceae2faede` olarak kaydetmek.
2. İlk PC Saha Takibi web yüzeyinin çalışan kabiliyetlerini README ve
   ROADMAP'ta güncellemek; stale "henüz merge edilmedi" ve "UI yok"
   ifadelerini current-state bölümlerinden kaldırmak.
3. Issue #127 execution programını ve #128–#140 faz haritasını görünür kılmak.
4. CHANGELOG ve proje karar kaydına Issue #141'in documentation/state-only
   kapsamını eklemek.
5. State dosyasında `current_safe_point`, `official_local_sync` ve
   `active_work` alanlarını olgusal değerlerle güncellemek.
6. Gerçek test, diff, protected path, exports, ZIP/cache ve Git kanıtlarını
   `.cse/results/141_result.md` içinde kaydetmek.

## Yasak kapsam

- Production Python, test, template, CSS, schema, migration, requirements,
  workflow, backup veya export formatı değiştirilmez.
- Gerçek kullanıcı `CSE_DATA_ROOT` yoluna erişilmez.
- `reports/`, ignored ZIP/cache veya `exports/.gitkeep` değiştirilmez.
- Reset, clean, stash, amend, rebase, force-push, branch deletion ve kullanıcı
  dosyası silme/taşıma/üzerine yazma yapılmaz.
- Merge edilmiş gibi gösterilmeyen yeni production davranışı eklenmez.
- Tek Hafıza, `MemoryIndex` veya çıktı türleri için veri modeli davranışı
  uygulanmaz; bunlar sonraki ADR Issue'larına bırakılır.

## Zorunlu doğrulamalar

```powershell
python -m pytest -rs
python -m compileall -q app scripts
python -m json.tool .cse/state/project_state.json > $null
git diff --check
git diff -- app tests requirements.txt pyproject.toml .github/workflows/pytest.yml
```

Ayrıca yalnız yetkili dosyaların değiştiği, `exports/` içinde yalnız
`.gitkeep` bulunduğu, `reports/` ile ignored ZIP/cache'in korunduğu ve gerçek
`CSE_DATA_ROOT` kullanılmadığı doğrulanır.

## Git ve yayın izinleri

- Tek ordinary commit: yetkili.
- Önerilen commit mesajı: `Sync repository truth after first PC field tracking UI`
- Normal push: yetkili.
- Amend/rebase/force-push: yasak.
- PR oluşturma: Codex için yasak; ChatGPT/GitHub akışına bırakılır.
- Merge ve branch silme: yasak.
- Post-merge sync: bu görevin başında tamamlandı; sonraki merge sonrasında
  gerektiğinde sonraki Codex çalışmasının başında yapılır.
