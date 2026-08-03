# Issue #305 Task — O10.1 live pilot closure automation

## Authority

- GitHub Issue: `#305`
- Binding execution authorization: `5160233470`
- Canonical repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Exact base: `5d46cb81bc8b116f29358c50609c47d7f732843e`
- Branch: `codex/issue-305-orchestrator-live-pilot-closure`
- Validation class: orchestrator tooling / fake-adapter acceptance
- Capability: Code + Network + Publish
- Codex reasoning: Extra High

## Changed contracts

- `workflow-bootstrap --issue 284 --target-root ... --runtime-root ...` tek
  giriş komutu; dry-run + explicit execute.
- Current controller/target/evidence/artifact'ten schema-v2 strict workflow
  authorization üretimi ve external immutable bootstrap store.
- Existing lifecycle/widget/full/analyze/build PASS kanıtının exact current
  source/tool/command/artifact fingerprint'iyle reuse'u.
- Exact tablet/package, synthetic-only record ve recoverable-only cleanup
  sınırında shell-free reusable smoke runner.
- Artifact sonrası device absence pause'u; aynı authorization/ledger ile build
  tekrar etmeden resume.
- Smoke PASS sonrası completion docs, ordinary commit, normal push ve Draft PR
  stage'lerinin aynı Issue #284 workflow'unda ilerlemesi.

## Exact write allowlist

Issue #305 gövdesindeki exact 16 path üst sınırdır. Product/mobile feature
source, dependency/workflow manifestleri, Issue #284 branch/ref/checkpoint ve
gerçek cihaz state'i bu implementation run'ında değiştirilemez.

## Validation

1. Focused bootstrap + fake smoke tests.
2. Focused workflow/coordinator tests.
3. Bütün `tests/test_cse_orchestrator*.py`.
4. Full Python suite.
5. `python -m compileall -q app scripts tools`.
6. Exact 16-path allowlist ve protected-path diff `0`.

## Budgets and publication

- Primary implementation: `1`.
- Same-scope bounded correction: `1`; focused assertion labels were aligned
  with the earlier strict fail-closed predicates.
- Normal push / Draft PR: at most `1 / 1`.
- Force-push/amend/rebase/merge/release: `0`.
- Product/mobile/build/install/ADB/device: `0`.
- PASS sonrasında ordinary commit `Complete orchestrator live pilot automation`,
  normal push ve `master` hedefli tek Draft PR yetkilidir.

## Implementation closure

- Final focused bootstrap/smoke: `19/19 PASS`.
- Artifact pause/resume + every-smoke-stage crash subset: `10/10 PASS`.
- All orchestrator: `300/300 PASS`.
- Full Python: `1,305 PASS / 7 SKIP`.
- Compileall: exit `0`.
- Gerçek build/install/ADB/device ve product/mobile mutation: `0`.
