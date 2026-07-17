# Issue #165 Görev Kaydı — Legacy Model Envanteri ve Deprecation Planı

## Çalışma bağlamı

- Resmî yerel repo: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Doğrulanan base commit: `4d31200753d8c24cefbce949849be67d1683b887`
- Başlangıç `master` / `origin/master`: `4d31200753d8c24cefbce949849be67d1683b887`
- Başlangıç divergence: `0 0`
- Branch: `codex/issue-165-legacy-inventory-deprecation-plan`
- Bağlayıcı execution Epic: Issue #127
- Bağlayıcı phase Epic: Issue #128
- Ürün Epic'i: Issue #105
- Saha Takibi Epic'i: Issue #97
- Ön koşul: Issue #148 / PR #164 merge edildi
- Codex modeli: `standart full Codex`
- Reasoning: `High`
- Seçim gerekçesi: Read-only inventory; yıllar içinde oluşmuş model, helper,
  repository, runtime, test, compatibility ve tarihsel dokümantasyon
  yüzeylerini exact referanslarla sınıflandırıp yanlış silme/regresyon riskini
  görünür kılmayı gerektirir.

## Amaç

Repository içindeki önemli model, helper, repository, application service,
route, script, test, schema/format compatibility ve dokümantasyon yüzeylerini
kanıta dayalı olarak şu dört sınıftan birine atamak:

```text
Aktif çekirdek
Dönüştürülecek
Legacy / arşivlenecek
Silme adayı
```

Hiçbir production/test/schema dosyası veya legacy aday bu Issue'da fiziksel
olarak değiştirilmez, taşınmaz, yeniden adlandırılmaz veya silinmez.

## Yetkili dosyalar

- `docs/165_legacy_model_inventory_and_deprecation_plan.md`
- `learning/165_legacy_model_inventory_and_deprecation_plan.md`
- `CHANGELOG.md`
- `ROADMAP.md`
- `docs/project_decisions.md`
- `.cse/state/project_state.json`
- `.cse/tasks/165_task.md`
- `.cse/results/165_result.md`

## Kanıt ve karar kapsamı

1. `app/models.py`, `app/field_tracking.py` ve domain/helper kümeleri.
2. `app/application/`, `app/persistence/`, `app/operations/`, `app/web/`.
3. `scripts/`, launcher ve maintenance komutları.
4. Doğrudan import, fixture, route/call site ve behavioral test bağımlılıkları.
5. Schema/migration, backup/restore/export/parser compatibility kapıları.
6. Current ADR/protocol/README/ROADMAP/decision bağımlılıkları.
7. Learning, podcast, `.cse` ve superseded dokümantasyonun provenance sınırı.
8. Multi-user, handover, özel alan, `blocked`, hard-validation ve export-helper
   terminoloji/plan kalıntıları.
9. Her inventory satırı için replacement, future action, removal gate ve risk.
10. Silme adayının yalnız bütün Issue kapıları kanıtlanırsa kullanılabilmesi.

## Yasak kapsam

- Production Python, test, schema, migration, persistence, template, static,
  requirements, workflow, backup/export formatı değiştirilmez.
- Dosya silme, rename, move, import graph rewrite veya runtime deprecation
  davranışı uygulanmaz.
- ADR-0001/0002/0003 değişmez.
- Scope field, archive, MemoryIndex, output-family, hard validation, `blocked`
  status veya replacement implementation eklenmez.
- Gerçek kullanıcı `CSE_DATA_ROOT` yoluna erişilmez.
- `reports/`, ignored ZIP/cache ve `exports/.gitkeep` değiştirilmez.
- Reset, clean, stash, amend, rebase, force-push ve branch deletion yapılmaz.

## Zorunlu doğrulamalar

```powershell
python -m pytest -rs
python -m compileall -q app scripts
python -m json.tool .cse/state/project_state.json > $null
git diff --check
git diff -- app tests requirements.txt pyproject.toml .github/workflows/pytest.yml
git diff --name-status 4d312007..HEAD
git status --short --branch
git status --ignored --short --untracked-files=all
```

Ayrıca yalnız sekiz yetkili dosyanın değiştiği, hiçbir delete/rename olmadığı,
`exports/` içinde yalnız `.gitkeep` bulunduğu, `reports/` ve ignored ZIP/cache'in
korunduğu ve `CSE_DATA_ROOT` değerinin unset kaldığı doğrulanır.

## Git ve yayın izinleri

- Tek ordinary commit: yetkili.
- Commit mesajı: `Inventory legacy models and define deprecation gates`
- Normal push: yetkili.
- Amend/rebase/force-push: yasak.
- PR oluşturma: Codex için yasak.
- Merge ve branch silme: yasak.
- Completion evidence: push sonrasında GitHub Issue #165 yorumuna eklenir.
