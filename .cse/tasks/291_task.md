# Issue #291 — O3 Deterministic Result Parser Görevi

## Otorite

- GitHub Issue: `#291`
- Execution authorization comment: `5157795815`
- Branch: `codex/issue-291-cse-orchestrator-result-parser`
- Exact base: `583b43c24c5070d30f684674eb52ad69ca4d8108`
- Başlangıç tree: `656c5ab11f3f5631d964951fde1c11ed04e90d25`
- Capability: `Code`
- Approval: bounded tek koşuluk delivery

## Değişen sözleşmeler

- Frozen command-result girdisinin strict ve immutable O3 şeması.
- `pytest`, `compileall`, `git_diff_check`, `flutter_test`,
  `flutter_analyze`, `build` ve `generic_command` aileleri için deterministic
  parse sonucu.
- Action başlamadı/harness failure ile başlamış invocation, timeout,
  truncation, malformed output ve exit/output çelişkisi ayrımı.
- Kanıtlanmış sayımlar, invocation budget sonucu, raw stream SHA-256 değerleri
  ve bounded sanitized excerpt.
- Byte-stable canonical JSON ve unknown/uyumsuz girdide fail-closed rejection.

## Validation planı

- Validation class: `python-tooling-deterministic`
- Focused: `python -m pytest tests/test_cse_orchestrator_results.py`
- Compile: `python -m compileall tools/cse_orchestrator`
- Full: `python -m pytest`
- Dar kalite: `git diff --check`, exact 10-path allowlist ve protected-path
  diff `0`.
- Reused evidence: O1 observer ve O2 policy full Python suite içinde regression
  olarak yeniden doğrulanır; ayrı live smoke kullanılmaz.
- Fiziksel cihaz kabulü: `0`; değişen sözleşme in-memory Python parser'dır.

## Bütçe ve stop sınırı

- Primary implementation: `1/1`
- Bounded same-scope correction: en fazla `1/1`
- Focused/compile/full invocation: primary zincirde birer kez; yalnız bounded
  correction gerekirse etkilenen zincir bir kez tekrarlanır.
- Ordinary commit/push/Draft PR: `1/1/1`
- İkinci commit, push veya PR; force-push ve merge: `0`.
- Bir gate failure'ında yalnız aynı allowlist içinde tek correction uygulanır;
  ikinci çözüm zinciri başlatılmaz.

## Exact write allowlist

1. `.cse/tasks/291_task.md`
2. `.cse/results/291_result.md`
3. `tools/cse_orchestrator/results.py`
4. `tools/cse_orchestrator/__init__.py`
5. `tests/test_cse_orchestrator_results.py`
6. `docs/291_cse_orchestrator_o3_result_parser.md`
7. `learning/291_cse_orchestrator_o3_result_parser.md`
8. `CHANGELOG.md`
9. `ROADMAP.md`
10. `docs/project_decisions.md`

## Açık kapsam dışı

- Gerçek test/build/action runner veya admission persistence.
- Subprocess, network, filesystem, Git/GitHub write adapter'ı.
- OpenAI API, Flutter build, ADB ve cihaz.
- Dependency, workflow, production, mobile, `.cse/state` ve
  `scripts/cse_status.py` değişikliği.
