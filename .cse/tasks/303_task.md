# Issue #303 Task — O10 resumable one-command development automation

## Authority

- GitHub Issue: `#303`
- Binding execution authorization: `5159977900`
- Bootstrap clarification: `5159980303`
- Canonical repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Exact base: `d97a30891dacd0fdbb25d6e00fc653dfaafd5370`
- Branch: `codex/issue-303-cse-orchestrator-resumable-workflow`
- Validation class: orchestrator domain/tooling
- Codex reasoning: Extra High
- Capability: Code + Network + Publish

## Changed contracts

- Tek `workflow-run` çağrısıyla yeni veya mevcut workflow keşfi ve aynı
  process içinde deterministic gate ilerlemesi.
- Machine-readable workflow authorization, repository-dışı append-only store
  ve eventlerden yeniden üretilebilir projection.
- Controller checkout ile target repository/worktree provenance ayrımı.
- External pause, user decision, authorized retry, unsafe blocker ve completed
  workflow sınıfları.
- Exact fingerprint altında PASS evidence/artifact reuse; duplicate-safe
  commit, push, Draft PR ve GitHub evidence davranışı.
- Stable stage/command-index/first-failed-predicate diagnostics ve veri-minimal
  redaction.

## Exact write allowlist

Issue #303 gövdesindeki 28 path exact üst sınırdır. `mobile/`, production ürün
kodu, workflow YAML, dependency manifest, `.cse/state/`, Issue #284 ref/source,
device ve kullanıcı veri alanları korunur.

## Validation

1. Focused workflow/coordinator tests.
2. Bütün `tests/test_cse_orchestrator*.py`.
3. Full Python suite.
4. `python -m compileall -q app scripts tools`.
5. CLI `workflow-run/status/verify` e2e.
6. Crash/restart/resume, artifact reuse, duplicate-safe publish, tamper ve
   redaction testleri.
7. Exact 28-path allowlist ve protected-path diff `0`.

## Budgets and publication

- Primary implementation run: `1`.
- Same-scope bounded correction: at most `1`.
- Normal push: at most `1`.
- Draft PR POST: at most `1`.
- Force-push, amend, rebase, merge, release: `0`.
- Product/mobile/device action: `0`.
- PASS sonrasında ordinary commit
  `Complete resumable CSE orchestrator workflow`, normal push ve `master`
  hedefli Draft PR yetkilidir; PR body ilk satırı `Related to #303` olur.

## Implementation closure

- O10 source, tests, docs ve learning exact allowlist içinde tamamlandı.
- Final source validation: focused `20/20`, orchestrator `271/271`, full Python
  `1,276 PASS / 7 SKIP`, compileall exit `0`.
- CLI e2e, crash/resume, artifact reuse, duplicate-safe publish, tamper ve
  redaction senaryoları focused suite içinde PASS.
- Product/mobile/device/Issue #284 mutation yapılmadı.
