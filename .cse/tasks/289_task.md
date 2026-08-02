# Issue #289 — O2 Deterministic State ve Policy Engine Görevi

## Otorite

- GitHub Issue: `#289`
- Execution authorization comment: `5157554712`
- Canonical payload SHA-256:
  `506ec5b738148571fcadda73389228b0dbbd20ec7ae1630f757fd27a81d5f3a8`
- Branch: `codex/issue-289-cse-orchestrator-state-policy`
- Base/başlangıç HEAD: `453b0c505bff95e1afb0a7546a77983176f39e45`
- Başlangıç tree: `109a1d159b847ae983504549e2f073a49ef6cf80`
- Capability: `Code`
- Approval: `CODE_CHANGE`

## Değişen sözleşmeler

- O0 state transition tablosunun executable ve immutable projection biçimi.
- Observation/authorization verisinden pure deterministic action-admission
  kararı.
- Approval seviyesi, capability, fingerprint drift, budget, retry/correction,
  reused evidence, optional gate ve blocker precedence doğrulamaları.
- Byte-stable canonical policy output'u.

## Validation planı

- Validation class: `python-tooling-deterministic`
- Focused: `python -m pytest tests/test_cse_orchestrator_policy.py`
- Compile: `python -m compileall tools/cse_orchestrator`
- Full: `python -m pytest`
- Dar kalite: `git diff --check`, exact 11-path allowlist ve protected-path
  diff `0`.
- Reused evidence: O1 observer davranışı full Python suite içinde yeniden
  doğrulanır; ayrı live smoke veya merged gate ikamesi kullanılmaz.
- Fiziksel cihaz kabulü: `0`; değişen sözleşme cihaz veya mobile değildir.

## Bütçe ve stop sınırı

- Primary implementation: `1/1`
- Bounded same-scope correction: en fazla `1/1`
- Same-operation retry: en fazla `1/1`
- Focused/compile/full invocation: her biri en fazla `2`; ikinci invocation
  yalnız bounded correction sonrası gereken zincir içindir.
- Hedef süre: `3600` saniye; hard stop: `5400` saniye.
- Bir gate failure'ında yalnız aynı allowlist içinde tek correction yapılır;
  ikinci correction veya yeni çözüm zinciri başlatılmaz.

## Exact write allowlist

1. `.cse/tasks/289_task.md`
2. `.cse/results/289_result.md`
3. `tools/cse_orchestrator/state.py`
4. `tools/cse_orchestrator/policy.py`
5. `tools/cse_orchestrator/__init__.py`
6. `tests/test_cse_orchestrator_policy.py`
7. `docs/289_cse_orchestrator_o2_state_policy_engine.md`
8. `learning/289_cse_orchestrator_o2_state_policy_engine.md`
9. `CHANGELOG.md`
10. `ROADMAP.md`
11. `docs/project_decisions.md`

## Açık kapsam dışı

- Subprocess, network veya filesystem action runner'ı.
- SQLite/event-store persistence ve approval consumption persistence.
- Git/GitHub write adapter'ı, commit, push, PR veya merge.
- OpenAI API, build, Flutter, ADB ve cihaz.
- Dependency, workflow, production, mobile, `.cse/state` ve
  `scripts/cse_status.py` değişikliği.

PASS sonrasında değişiklikler unstaged kalır; sıradaki tek yetki kapısı ayrı
`CHECKPOINT_COMMIT` yorumudur.
