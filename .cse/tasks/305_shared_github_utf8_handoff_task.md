# Issue #305 Task — Shared GitHub UTF-8 workflow recovery

## Authority

- GitHub Issue: `#305`
- Binding correction authorization: `5167123792`
- Canonical repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Exact base: `894ac311cb9d6d454fb5121169b9031c4ae466b8`
- Branch: `codex/issue-305-shared-github-utf8-handoff`
- Validation class: orchestrator recovery correction
- Capability: Code + Network + Publish
- Codex reasoning: Extra High

## Changed contracts

- Shared `GhGitHubClient` captures binary stdout/stderr and performs explicit
  strict UTF-8 decode on the caller thread.
- Executable/decode/JSON/pagination failures are stable and data-minimal.
- `GhIssueEvidenceSink` translates shared client failures to `WorkflowError`;
  CLI emits structured `UNSAFE_BLOCKED` without traceback.
- Existing Issue #284 live runtime can hand off only from controller
  `894ac311...` at the exact one-event pre-stage boundary.
- Old authorization/ledger stay immutable; one deterministic successor
  authorization and workflow identity continue in the same external runtime.

## Validation plan

1. Shared GET binary/UTF-8, real subprocess cp1254 and invalid UTF-8 tests.
2. Evidence sink and CLI no-traceback structured blocker tests.
3. Exact pre-stage successor, all admission/effect rejection, tamper,
   immutability and idempotency tests.
4. Bootstrap/workflow/device-smoke suites.
5. All orchestrator tests.
6. Full Python suite and `python -m compileall -q app scripts tools`.
7. Exact 13-path allowlist, protected diff `0`, diff-check and clean staging.

## Safety and budgets

- Product/mobile source, Issue #284 target/ref/checkpoint, APK, live runtime,
  build/install/ADB/tablet and real-user data operation: `0`.
- Force-push, amend, rebase, merge and release: `0`.
- Ordinary commit, normal push and one Draft PR are authorized only after PASS.
- Exact write allowlist is the 13 paths in authorization `5167123792`.
