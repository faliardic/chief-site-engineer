# Issue #455 Task — CSE-MRP-1.0 Model ve Reasoning Routing Policy

## Execution identity

- Resmî repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- İzole linked worktree: `V:\1_PROJECTS\2_ACTIVE\Python\CSE-Worktrees\issue-455-model-reasoning-routing-20260816T011006Z`
- Exact base/master: `6d55947f73097e3ee71246fbc1496ba1f6878f01`
- Branch: `docs/issue-455-model-reasoning-routing-policy`
- V2 item: `N/A — docs-only protocol/source-authority`
- Parent Epic: `N/A — protocol governance`

## Model routing

```yaml
model_routing:
  policy_version: "CSE-MRP-1.0"
  task_risk: "R3"
  orchestrator:
    chatgpt_model: "gpt-5.6-sol"
    chatgpt_reasoning_effort: "xhigh"
  codex_model: "gpt-5.6-sol"
  codex_reasoning_effort: "xhigh"
  execution_mode: "standard"
  orchestration: "single-agent"
  selection_reason: "Birden fazla canonical kaynakta kalıcı source-authority ve execution protocol değişikliği."
  allowed_fallback: null
  review_floor:
    chatgpt_model: "gpt-5.6-sol"
    chatgpt_reasoning_effort: "xhigh"
  fail_closed_if_mismatch: true
```

Requested invocation kanıtı Issue #455 owner authorization yorumundaki exact
routing kaydıdır. Runtime actual model/effort metadata'sı görünmüyorsa tahmin
edilmez; completion kaydı `unknown / null / unverified` kullanır.

## Validation contract

- Validation class: `docs`
- Changed contracts: model/reasoning/execution/orchestration eksenleri; R0–R4 routing; task header; runtime fail-closed kaydı; review floor ve iki completion YAML bloğu.
- Focused tests: required phrase/search, Markdown fence/table/YAML tutarlılığı, `git diff --check`, exact allowlist ve protected production/#454/schedule drift kontrolleri.
- Allowed broad gates: yok.
- Reused evidence: exact merged master `6d55947f73097e3ee71246fbc1496ba1f6878f01`; production/schema/backup/device davranışı değişmediği için mevcut merged kanıt geçerlidir.
- Schema/migration/backup/attachment/notification impact: yok.
- Minimum physical-device acceptance: yok.
- Retry budget: 1 primary execution + en fazla 1 blocking correction; aynı başarısız operasyon exact fix sonrasında en fazla 1 retry.
- Time budget: hedef 10–15 dakika, hard stop 25 dakika.
- Stop conditions: routing invocation kanıtı yokluğu/görünür mismatch, authority çelişkisi, allowlist dışı edit ihtiyacı, #454 veya schedule drift'i, ikinci aynı hata veya hard stop.

## Authorized files

- `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
- `AGENTS.md`
- `docs/protocols/CSE_MODEL_REASONING_ROUTING_POLICY.md`
- `docs/protocols/CSE_PROJECT_SOURCE_REGISTER.md`
- `.cse/tasks/455_task.md`
- `.cse/results/455_result.md`

## Explicitly out of scope / protected

- Unified product source ve `ROADMAP.md`.
- Product/runtime/test/schema/migration/backup/attachment/corpus/schedule kodu ve assetleri.
- Issue #454 branch/task/result/code/review blocker'ları.
- Flutter/Python full suite, APK/AAB, device, backup/restore ve release gate.
- PR Ready, merge ve sonraki production/persistence/7 günlük plan Slice'ı.

## Publication

- Intentional commit, normal push, Issue completion evidence ve Draft PR yetkilidir.
- PR Ready ve merge yetkili değildir.
