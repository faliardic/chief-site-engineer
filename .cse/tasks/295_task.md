# Issue #295 — O5–O8 Orchestrator MVP Görevi

## Otorite

- GitHub Issue: `#295`
- Execution authorization comment: `5158213215`
- Repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Branch: `codex/issue-295-cse-orchestrator-mvp`
- Exact base/master: `687af6ce247e3e309d16543d849a75a872e69064`
- Başlangıç tree: `c7471c7e7065e474251f8723821b4608a185e88f`
- Capability: `Code`; yalnız adapter sözleşmeleri için `Publish`
- Validation class: `python-tooling-controlled-execution`
- Codex reasoning: `Extra High`; multi-file execution/provenance ve regression
  riski nedeniyle en güçlü full model gerekir.

## Değişen sözleşmeler

- O1 Observation + O2 policy'den deterministic immutable ActionPlan v1.
- Repository-dışı append-only admission/result ledger.
- Explicit execute, exact argv, environment/output/timeout sınırları ve O3 result
  integration'ı olan controlled runner.
- Ayrı CHECKPOINT_COMMIT, BUILD ve DEVICE gate planları.
- Normal push + tek Draft PR için injected GitHub adapter sözleşmesi.
- Default dry-run CLI plan/execute/gate/publish/ledger komutları.

## Exact write allowlist

1. `tools/cse_orchestrator/planner.py`
2. `tools/cse_orchestrator/ledger.py`
3. `tools/cse_orchestrator/runner.py`
4. `tools/cse_orchestrator/gates.py`
5. `tools/cse_orchestrator/github_adapter.py`
6. `tools/cse_orchestrator/cli.py`
7. `tools/cse_orchestrator/__init__.py`
8. `tests/test_cse_orchestrator_mvp.py`
9. `docs/295_cse_orchestrator_o5_o8_mvp.md`
10. `learning/295_cse_orchestrator_o5_o8_mvp.md`
11. `.cse/tasks/295_task.md`
12. `.cse/results/295_result.md`
13. `CHANGELOG.md`
14. `ROADMAP.md`
15. `docs/project_decisions.md`

## Validation planı

1. Focused: `python -m pytest tests/test_cse_orchestrator_mvp.py`
2. Compile: `python -m compileall tools/cse_orchestrator`
3. Full: `python -m pytest`
4. `git diff --check`
5. Exact 15-path allowlist ve dependency/production/mobile/workflow/
   `.cse/state`/`scripts/cse_status.py` diff `0`.
6. Forbidden external-I/O ve fake adapter sınırı kontrolü.

## Bütçe ve stop

- Primary implementation: `1/1`
- Bounded same-scope correction: en fazla `1/1`
- Focused/compile/full: primary birer kez; correction sonrası yalnız etkilenen
  zincir bir kez.
- Ordinary commit/push/Draft PR: `1/1/1`
- İkinci correction/commit/push/PR, amend, force-push ve merge: `0`.

## Açık kapsam dışı

- Orchestrator üzerinden gerçek Codex/build/ADB/device/GitHub mutation.
- Dependency, workflow, production, mobile, `.cse/state` veya
  `scripts/cse_status.py` değişikliği.
- OpenAI API, O9 planner veya O10 Windows service/tray.
- Secret/raw authorization-comment body/user data/ignored kullanıcı alanı.
- Issue #284 branch/checkpoint mutation'ı.
- Ready, merge, Issue close, branch delete, tag veya release.
