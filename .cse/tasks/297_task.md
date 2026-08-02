# Issue #297 — CSE Orchestrator canlı kontrollü pilot

## Yürütme sözleşmesi

- Resmî repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Exact base/HEAD: `7151235c0bbd81910f55ccbd1a89458b498d1f7d`
- Branch: `codex/issue-297-cse-orchestrator-live-pilot`
- Authorization comment: `5158523734`
- Validation class: `python-tooling-live-controlled-pilot`
- Capability / approval: `Code / FULL_VALIDATION`
- Codex reasoning: Extra High
- Seçim nedeni: gerçek subprocess admission, immutable plan fingerprint'i,
  append-only ledger ve tek kullanımlık yayın bütçesi birlikte doğrulanır.

## Exact action

```text
python -m pytest -o addopts= --color=no tests/test_cse_orchestrator_mvp.py
```

- Gerçek subprocess invocation bütçesi: `1`
- Retry bütçesi: `0`
- Output limiti: `262144` byte
- Environment-name allowlist: `PATH`, `PATHEXT`, `SYSTEMROOT`, `WINDIR`,
  `TEMP`, `TMP`, `USERPROFILE`, `LOCALAPPDATA`
- Environment değerleri runtime kanıtına veya repository dosyalarına yazılmaz.
- Aynı execute planı duplicate admission kontrolünde ikinci subprocess
  başlatmadan `BLOCKED` olmalıdır.

## Exact repository write allowlist

1. `.cse/tasks/297_task.md`
2. `.cse/results/297_result.md`
3. `docs/297_cse_orchestrator_live_controlled_pilot.md`
4. `learning/297_cse_orchestrator_live_controlled_pilot.md`
5. `CHANGELOG.md`
6. `ROADMAP.md`
7. `docs/project_decisions.md`

## Kabul kapıları

- O1 observer gerçek local Git ve GET-only GitHub verisini gözlemler.
- O2, `FULL_VALIDATION` için `ACTION_AUTHORIZED → ACTION_RUNNING` admission
  kararı üretir.
- Dry-run ve execute planları aynı action fingerprint'ini taşır.
- Gerçek action exit code `0`, O3 `failure_class = null`, `passed = 30` ve
  `failed = 0` üretir.
- External ledger verification PASS olur.
- Duplicate execute ikinci subprocess başlamadan `BLOCKED` olur.
- Repository diff'i exact yedi yolla sınırlı ve `git diff --check` PASS olur.
- Tek ordinary commit, tek normal push ve `master` hedefli tek Draft PR açılır;
  PR body `Closes #297` ile başlar.

## Kapsam dışı

- `tools/`, `tests/`, production, mobile, dependency, workflow,
  `.cse/state` ve `scripts/cse_status.py` değişikliği
- Gerçek build, ADB/device, OpenAI API veya Orchestrator-driven GitHub mutation
- Test retry, ikinci commit, ikinci push, ikinci PR, force-push, Ready, merge,
  Issue close, branch delete, tag veya release
