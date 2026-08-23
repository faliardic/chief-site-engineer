# Issue #477 Task — Consolidated Stabilization and Durable New-Chat Rules

## Authority and routing

- Repository: `faliardic/chief-site-engineer`
- Issue: `#477`
- Parent: `#385`
- Type: documentation / execution protocol
- Base: `cc7c49fa30b50aae09b349eb0bfa1161c5cdc814`
- Branch: `docs/issue-477-workflow-acceleration`
- Validation class: `docs`
- Policy: `CSE-MRP-1.0`
- Risk: `R3`
- Requested model: `gpt-5.6-sol`
- Requested reasoning effort: `xhigh`
- Execution mode: `standard`
- Orchestration: `single-agent`
- Allowed fallback: `null`
- Owner request: çalışma tarzını GitHub'da güncelle ve her yeni sohbet için
  kalıcı kurala bağla.

## Changed contracts

1. One bounded consolidated stabilization window per Slice/correction phase.
2. Up to three root-cause-proven same-scope narrow corrections.
3. Focused validation after corrections; expensive gates on the final candidate.
4. Source/artifact-digest evidence reuse and invalidation.
5. Deterministic clean acceptance and separate upgrade acceptance.
6. Scenario-based device acceptance and first-failure diagnostics.
7. Generated-state cleanup without repeated authority when tracked drift is zero.
8. Fresh-chat full bootstrap and same-task resume hash fast-path.
9. Dynamic repository state removed from root instructions.
10. Early Draft PR may parallelize CI/local device/review without granting merge.

## Exact allowlist

1. `AGENTS.md`
2. `docs/protocols/CSE_WORKFLOW_ACCELERATION_PROTOCOL.md`
3. `.cse/tasks/477_task.md`
4. `.cse/results/477_result.md`

Existing long protocol files remain unchanged in this narrow commit. Root
`AGENTS.md` makes the acceleration protocol mandatory in every fresh chat and
gives it narrow precedence only for workflow/retry mechanics. Product/data
safety, repository safety and owner merge authority are not weakened.

## Protected

All production/mobile source, tests, workflows, schema/migration/backup,
package/version/platform config, ROADMAP/V2 scope, and active Issue #476 source.

## Validation

- exact four-file docs allowlist;
- Markdown/readability and trailing-whitespace review;
- root instructions contain no fixed current master/schema/active-Issue state;
- fresh-chat and resume hash behavior explicit;
- correction budget and immediate escalation consistent;
- acceleration protocol mandatory in fresh-chat reads;
- production/test/workflow/schema drift `0`.

No Python/Flutter/build/device gate is required.

## Publication

One docs commit, normal push and one Draft PR. No Ready, merge, Issue closure or
production successor work.
