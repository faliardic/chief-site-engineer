# Issue #477 Task — Accelerated Workflow and Owner-Led Manual Testing

## Authority and routing

- Repository: `faliardic/chief-site-engineer`
- Issue: `#477`
- Parent: `#385`
- Permanent manual test register: `#479`
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

Owner requests:

1. CSE workflow must stop producing one authority/test/build/device loop for every narrow blocker.
2. Every new chat must reload the durable workflow rules from GitHub.
3. Codex must no longer run application behavior tests by default.
4. Each feature must receive a stable numbered manual test list.
5. Fatih may test now, report a subset, or defer all tests and continue development.
6. ChatGPT must update the permanent test register from short owner reports.

## Changed contracts

1. One bounded consolidated implementation window per Slice/correction phase.
2. Up to three same-scope narrow source corrections before owner escalation.
3. Automated application tests default to `0` unless owner explicitly opts in.
4. Codex source-level checks are limited to scope/diff, format/syntax/static analysis and drift.
5. APK/build is run only when owner requests a manual-test artifact, milestone or release build.
6. Every feature receives stable IDs in `MT-<ISSUE>-<NNN>` format.
7. GitHub Issue #479 is the permanent cross-chat manual test backlog.
8. Test states are `PENDING | PASS | FAIL | PARTIAL | DEFERRED | N/A`.
9. Manual test `PENDING/DEFERRED` does not automatically block Draft publication, merge or next-feature work; owner decides.
10. Untested behavior cannot be labeled verified, field accepted or release ready.
11. Fresh-chat full bootstrap and same-task ruleset-hash resume fast-path remain binding.
12. Dynamic master/schema/current-Issue data is removed from root instructions.

## Exact allowlist

1. `AGENTS.md`
2. `docs/protocols/CSE_WORKFLOW_ACCELERATION_PROTOCOL.md`
3. `.cse/tasks/477_task.md`
4. `.cse/results/477_result.md`

GitHub Issue #479 and Issue/PR comments are coordination metadata, not repository changed paths.

## Protected

All production/mobile source, tests, workflows, schema/migration/backup,
package/version/platform config, ROADMAP/V2 scope, and active Issue #476 source.

## Validation

- exact four-file repository allowlist;
- Markdown/readability review;
- root instructions contain no fixed current master/schema/active-Issue state;
- #479 is mandatory in fresh-chat reads;
- Codex automated application tests are disabled by default;
- manual tests may be deferred without a false verification claim;
- source-level checks and owner merge authority remain explicit;
- production/test/workflow/schema drift `0`.

No Python/Flutter/build/device gate is required for this documentation-only policy change.

## Publication

- documentation branch only;
- normal commits/push;
- Draft PR #478;
- Ready/merge only with explicit owner approval;
- Issue #476 implementation source remains untouched by this docs branch.
