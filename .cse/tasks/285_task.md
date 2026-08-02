# Issue #285 Task — CSE Development Orchestrator O0 temeli

## Authority

- GitHub Issue: `#285`
- Execution comment: `5152282818`
- Validation class: `docs`
- Exact base: `eb85f0a2ea0901f0074887fe999e74b6ab4aed0f`
- Branch: `docs/issue-285-cse-orchestrator-o0-foundation`
- Codex reasoning: `Extra High`

## Objective

CSE geliştirme disiplinini otomatik kod yazmadan önce makine tarafından
doğrulanabilir kılacak O0 mimari, durum makinesi, güvenlik, approval ve MVP
sözleşmelerini belgelemek.

## Changed Contracts

- Orchestrator component ve operational-truth sınırları.
- State machine, invariant ve blocker sözleşmesi.
- One-time approval fingerprint ve insan kontrolü.
- Code, Device ve Publish capability ayrımı.
- Retry, correction, invocation ve süre bütçelerinin makine alanları.
- Repository dışı runtime-state ve secret sınırı.
- O1–O10 faz programı.

Production, mobile, test, workflow, schema, migration, backup ve kullanıcı
davranışı değişmez.

## Required Sources Read

1. `AGENTS.md`
2. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
3. `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
4. `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md`
5. `docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md`
6. `docs/protocols/CSE_PROJECT_SOURCE_REGISTER.md`
7. `README.md`
8. `ROADMAP.md`
9. `docs/project_decisions.md`
10. `.cse/state/project_state.json`
11. GitHub Issue #285 ve bütün yorumları
12. İlgili #105, #127, #215 ve #284 kanıtları

## Start Gate Evidence

- Başlangıç branch'i: `codex/issue-284-reminder-all-day-edit`
- Başlangıç HEAD/checkpoint:
  `b0e9cf247afa6bac5d38684dbc626a11fdf45663`
- Checkpoint parent:
  `eb85f0a2ea0901f0074887fe999e74b6ab4aed0f`
- Local `master`, `origin/master`, canlı GitHub `master`:
  `eb85f0a2ea0901f0074887fe999e74b6ab4aed0f`
- Başlangıç divergence: `origin/master...HEAD = 0 1`
- Başlangıç staging: boş
- Başlangıç tracked worktree: temiz
- Hedef branch local/remote varlık kontrolü: yok
- Issue #284 branch pointer'ı branch oluşturma sonrasında da exact checkpoint'te.

## Exact Cumulative Allowlist

1. `docs/orchestrator/CSE_ORCHESTRATOR_ARCHITECTURE.md`
2. `docs/orchestrator/CSE_ORCHESTRATOR_STATE_MACHINE.md`
3. `docs/orchestrator/CSE_ORCHESTRATOR_SECURITY_BOUNDARY.md`
4. `docs/orchestrator/CSE_ORCHESTRATOR_APPROVAL_MODEL.md`
5. `docs/orchestrator/CSE_ORCHESTRATOR_MVP_PLAN.md`
6. `learning/285_cse_orchestrator_o0_foundation.md`
7. `ROADMAP.md`
8. `CHANGELOG.md`
9. `docs/project_decisions.md`
10. `docs/protocols/CSE_PROJECT_SOURCE_REGISTER.md`
11. `.cse/tasks/285_task.md`
12. `.cse/results/285_result.md`

## Reused Evidence

- Exact merged canonical source revision:
  `eb85f0a2ea0901f0074887fe999e74b6ab4aed0f`.
- Issue #215 minimum yeterli doğrulama ve bütçe sözleşmesi.
- Mevcut `.github/workflows/pytest.yml` ve
  `.github/workflows/mobile_release_gate.yml` görev sınırları.
- Issue #284 yorum zinciri ve checkpoint yalnız sanitized O4 replay tasarım
  kaynağıdır; hiçbir cihaz veya kullanıcı verisi okunmaz.
- `scripts/cse_status.py` mevcut diagnosis/finalize sorumluluk envanteri.

## Allowed Validation

- Scoped changed/untracked allowlist subset kontrolü.
- Zorunlu docs/task/result varlık kontrolü.
- `git diff --check`.
- Final newline ve trailing-whitespace kontrolü.
- Markdown heading, code-fence ve repository-local link kontrolü.
- Conflict-marker kontrolü.
- Production/mobile/test/workflow diff `0`.
- `AGENTS.md`, protokoller, scripts ve `.cse/state` diff `0`.
- Staging boşluk kontrolü.

## Explicitly Not Allowed

- Flutter veya Python testleri.
- Analyze, build veya release gate.
- ADB veya cihaz işlemi.
- API çağrısı veya API anahtarı/secret işlemi.
- Orchestrator implementation veya Codex child execution.
- GitHub mutation.
- Stage, commit, push, PR, merge veya release.
- Gerçek kullanıcı alanı veya ignored/protected içerik okuması.

## Budget

- Primary docs run: `1`
- Correction: en fazla `1`
- İkinci scope/solution genişlemesi: `0`
- Hedef süre: `25 dakika`
- Hard stop: `45 dakika`

## Stop Conditions

- Base, branch, source veya Issue #284 freeze drift'i.
- Allowlist dışı dosya ihtiyacı.
- Production/test/workflow/protokol değişikliği ihtiyacı.
- Gerçek kullanıcı alanı veya secret erişimi ihtiyacı.
- Implementation gereksinimi.
- Retry veya hard-stop bütçesinin tükenmesi.
- Çözülemeyen kaynak-otoritesi çelişkisi.

## Completion Boundary

Docs kalite kontrolünden sonra bütün değişiklikler unstaged bırakılır. Commit,
push, PR veya GitHub yorumu oluşturulmaz. Sıradaki mutable adım ayrı
`CHECKPOINT_COMMIT` approval'ıdır.
