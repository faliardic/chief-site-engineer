# Issue #287 Task — CSE Orchestrator O1 read-only observer

## Authority

- GitHub Issue: `#287`
- Primary authorization comment: `5155504289`
- Pagination correction authorization comment: `5155637555`
- Marker: `<!-- cse-orchestrator-authorization:v1 -->`
- Primary canonical payload SHA-256:
  `c17d94dae41b5e872224cbaa3661c22593d72d3d50a5eecb6ab040a83ee18a43`
- Correction canonical payload SHA-256:
  `e4ea079a2933b917ac47d90c4a12a20faf71f1567a989476bcc9c12504a6cab8`
- Approval: `CORRECTION`
- Capability: `Code`
- Action: `fix-o1-pagination-test-harness`
- Scope version: `2`; supersedes comment `5155504289`
- Validation class: `python-tooling-readonly`
- Expected result state: `FOCUSED_PASS`

## Source fingerprint

- Canonical repository:
  `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Repository identity: `faliardic/chief-site-engineer`
- Branch: `codex/issue-287-cse-orchestrator-read-only-observer`
- Base/HEAD: `36549ec5936bc9581cdebbb4985a11ec5e017fd6`
- Tree: `da79ccb09e9eca0f5d7ae0baf09692c1519c97bc`
- Issue #284 protected pointer:
  `b0e9cf247afa6bac5d38684dbc626a11fdf45663`
- Authorization expiry: `2026-08-09T21:00:00Z`

## Changed contracts

- Observation v1 schema and canonical serialization.
- Strict machine-readable authorization v1 parsing and supersession.
- Tracked-only Git and GET-only GitHub observation.
- Exact task/result/state record metadata collection.
- Deterministic blocker precedence and exit codes.
- Repository-external atomic runtime output and sanitization.

O2 policy/action admission, approval consumption, Codex child execution,
GitHub write, build, device and production behavior do not change.

## Exact read allowlist

1. `git:tracked-metadata`
2. `git:refs/heads/master`
3. `git:refs/remotes/origin/master`
4. `git:refs/heads/codex/issue-284-reminder-all-day-edit`
5. `github:repository/faliardic/chief-site-engineer`
6. `github:issue/287`
7. `github:issue/287/comments`
8. `AGENTS.md`
9. `README.md`
10. `ROADMAP.md`
11. `CHANGELOG.md`
12. `docs/project_decisions.md`
13. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
14. `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
15. `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md`
16. `docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md`
17. `docs/protocols/CSE_PROJECT_SOURCE_REGISTER.md`
18. `docs/orchestrator/CSE_ORCHESTRATOR_ARCHITECTURE.md`
19. `docs/orchestrator/CSE_ORCHESTRATOR_STATE_MACHINE.md`
20. `docs/orchestrator/CSE_ORCHESTRATOR_SECURITY_BOUNDARY.md`
21. `docs/orchestrator/CSE_ORCHESTRATOR_APPROVAL_MODEL.md`
22. `docs/orchestrator/CSE_ORCHESTRATOR_MVP_PLAN.md`
23. `.cse/tasks/287_task.md`
24. `.cse/results/287_result.md`
25. `.cse/state/project_state.json`
26. `scripts/cse_status.py`
27. `tests/test_cse_status.py`
28. `pyproject.toml`
29. `requirements.txt`

## Exact write allowlist

1. `.cse/tasks/287_task.md`
2. `.cse/results/287_result.md`
3. `tools/__init__.py`
4. `tools/cse_orchestrator/__init__.py`
5. `tools/cse_orchestrator/authorization.py`
6. `tools/cse_orchestrator/observer.py`
7. `tools/cse_orchestrator/cli.py`
8. `tests/test_cse_orchestrator_observer.py`
9. `docs/287_cse_orchestrator_o1_read_only_observer.md`
10. `learning/287_cse_orchestrator_o1_read_only_observer.md`
11. `CHANGELOG.md`
12. `ROADMAP.md`
13. `docs/project_decisions.md`

## Exact action allowlist

- `edit:exact-write-allowlist`
- `git:read-only-observation`
- `github:get-repository`
- `github:get-issue`
- `github:get-issue-comments`
- `python:pytest-focused-tests/test_cse_orchestrator_observer.py`
- `python:compileall-tools/cse_orchestrator`
- `git:diff-check`
- `validation:exact-allowlist`
- `validation:protected-path-diff-zero`

## Budget

- Primary run: `1/1`, completed before this correction
- Correction: `1/1`, authorized by comment `5155637555`
- Same-operation retry: `0`
- Correction focused pytest retry: `1`
- Compileall: `1`
- Full test / integration smoke: `0/0`
- Git/GitHub mutation: `0/0`
- API/build/device: `0/0/0`
- Target / hard stop: `2700 / 4200` seconds

## Authorized focused validation

1. `python -m pytest tests/test_cse_orchestrator_observer.py` — one correction
   invocation.
2. If focused PASS:
   `python -m compileall tools/cse_orchestrator` — exactly once.
3. `git diff --check`.
4. Exact 13-path allowlist and protected/dependency/state diff checks.
5. Staging remains empty.

Full Python validation, live Issue observation and runtime integration smoke
require a separate `FULL_VALIDATION` authorization.

## Protected data and paths

- No ignored/untracked broad enumeration.
- No `reports/`, `device-backups/`, `exports/`, ZIP/cache or credential reads.
- No real user content, app-private data or secret output.
- Runtime output may exist only below repository-external
  `%LOCALAPPDATA%\CSE-Orchestrator`.
- `scripts/cse_status.py`, `.cse/state/project_state.json`, production, mobile,
  workflows and dependency manifests are read-only or out of scope.

## Stop conditions

- Authorization/source/tree/branch/expiry drift.
- Allowlist or budget drift.
- Correction focused test failure or timeout; no second correction or retry.
- Runtime root inside repository.
- Need for a mutating Git/GitHub command or user/credential access.
- Need for dependency, production, mobile, workflow or `.cse/state` changes.

## Completion boundary

PASS leaves every change unstaged. Commit, push, PR and GitHub mutation remain
separate approval gates. The next action is a separate `FULL_VALIDATION`
authorization.

## Pagination correction record

- Exact query parsing correction: applied only to the fake paginated comments
  API fixture with `urlsplit` and `parse_qs`.
- Correction focused pytest: `1/1`; exit `0`; `64 passed in 0.51s`;
  invocation duration `2.403s`.
- Compileall: `1/1`; exit `0`; invocation duration `0.255s`.
- Narrow quality checks: `git diff --check` PASS; cumulative allowlist `13/13`;
  dependency, protected path, `scripts/cse_status.py` and `.cse/state` diffs
  `0`; staging empty.
