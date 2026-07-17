# Issue #171 Görev Kaydı

## Kimlik

- Issue: `#171 — P0.10: Faz 0 kapanış doğrulaması ve Faz 1 geçiş kapısı`
- Parent phase Epic: `#128`
- Parent execution Epic: `#127`
- Parent product Epic: `#105`
- Branch: `codex/issue-171-phase-0-closure-validation`
- Base: `master` / `3024ea45421593cfd03375b8594832ce27d684ab`
- Model: `standart full Codex`
- Reasoning: `High`
- Seçim nedeni: Dört ADR, legacy envanteri, pilot protokolü, tehdit modeli,
  repository truth ve GitHub Epic durumlarını tek kanıt zincirinde uzlaştıran
  documentation/state-only kapanış çalışmasıdır; Extra High gerekmez.

## Amaç

Faz 0'ın merged Issue/PR/commit kanıtlarını repository truth ile karşılaştırmak,
dört ADR'yi current kanonik yüzeylerden erişilebilir kılmak, drift'i yetkili
dokümanlarda kapatmak, Faz 0 sonucunu kanıt matrisinden üretmek ve Faz 1 için
tek dar sıradaki Issue adayını seçmektir.

## Yetkili Dosyalar

1. `README.md`
2. `ROADMAP.md`
3. `CHANGELOG.md`
4. `docs/project_decisions.md`
5. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
6. `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
7. `docs/171_phase_0_closure_validation.md`
8. `learning/171_phase_0_closure_validation.md`
9. `.cse/state/project_state.json`
10. `.cse/tasks/171_task.md`
11. `.cse/results/171_result.md`

Bu listenin dışındaki repository dosyaları değiştirilemez.

## Zorunlu Ön Okuma

- `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
- `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
- ADR-0001, ADR-0002, ADR-0003 ve ADR-0004
- `docs/165_legacy_model_inventory_and_deprecation_plan.md`
- `docs/167_field_acceptance_metrics_and_pilot_protocol.md`
- GitHub Issue #127, #128, #129, #171 ve bütün yorumları
- Epic #105, #97 ve #140
- Issue #141, #143, #145, #147, #148, #165, #167 ve #169 kanıtları
- Merged PR #142, #144, #146, #159, #164, #166, #168 ve #170 kanıtları
- README, ROADMAP, CHANGELOG, project decisions ve project state
- Production/test/schema/backup/export/web yüzeyleri yalnız read-only doğrulama

## Güvenlik ve Kapsam Sınırları

- Production Python, test, schema, migration, persistence, UI, route, CLI,
  session veya artifact wire formatı değiştirilemez.
- Gerçek kullanıcı data root'u, Backup, attachment, log veya gerçek pilot
  içeriği okunamaz.
- `reports/`, ignored ZIP/cache ve `exports/.gitkeep` korunur.
- `CSE_DATA_ROOT` unset kalır.
- Faz 1 implementation, branch, Issue veya PR başlatılmaz.
- Reset, clean, stash, rebase, amend, force-push, delete, move veya branch silme
  yapılmaz.
- Codex PR açmaz ve merge yapmaz.

## Closure Sözleşmesi

- Ana dokümanda en az on zorunlu alanlı closure kanıt matrisi bulunur.
- Dört ADR'nin karar kapsamı ile uygulanmış production davranışı ayrılır.
- Legacy removal gate, 7/30 günlük pilotun yürütülmediği sınır ve current MVP
  security posture açık kalır.
- Schema `4`, Backup format `1`, Günlük Çıktı format `1`; Hafızayı İndir ve
  Proje Paketi implementation sürümleri `null / uygulanmadı` olarak korunur.
- Faz 0 sonucu yalnız `PASS | CONDITIONAL PASS | FAIL` sözlüğünden seçilir.
- Sıradaki tek öneri Issue #129 içindeki P1.01 zaman sözleşmesi ve migration
  preflight'tır; bu branch yalnız bağlayıcı öneriyi kaydeder.

## GitHub Hizalama

- Issue #128 gövdesinde P0.01–P0.09 yalnız merged kanıtla tamamlandı işaretlenir.
- P0.10 bu branch merge edilmeden tamamlandı işaretlenmez.
- Issue #128 kapanmaz; closure sonucu ve gap'ler yorumlanır.
- Issue #127, Faz 0 merged alt işleri ve sıradaki tek aktif faz olarak Faz 1 / #129
  bilgisiyle güncellenir; kapanmaz.
- Kullanılan GitHub body/comment işlemleri ve doğrulama sonuçları result kaydına
  alınır.

## Doğrulama

```powershell
python -m pytest -rs
python -m compileall -q app scripts
python -m json.tool .cse/state/project_state.json > $null
git diff --check
git diff -- app tests requirements.txt pyproject.toml .github/workflows/pytest.yml
git diff --name-status 3024ea45..HEAD
git status --short --branch
git status --ignored --short --untracked-files=all
```

Ek kapılar:

- exact allowlist `11/11`;
- production/test/dependency/workflow diff boş;
- tek ordinary commit;
- normal push;
- Issue #171 completion evidence;
- PR yok.

## Commit

```text
Close Phase 0 and define Phase 1 entry gate
```
