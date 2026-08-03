# Issue #305 Task — Tablet interactive preflight resume

## Authority

- GitHub Issue: `#305`
- Binding correction authorization: `5168941496`
- Canonical repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Exact base: `5e5d6dc9b06312e6e78be60d1542954d1fd05eca`
- Branch: `codex/issue-305-tablet-interactive-resume`
- Validation class: orchestrator live recovery correction
- Capability: Code + Network + Publish
- Codex reasoning: Extra High

## Changed contracts

- Production `dumpsys power` handling uses one deterministic, fail-closed parser.
- Exact `mWakefulness=Awake`, existing `mInteractive=true` and
  `Display Power: state=ON` are interactive-positive.
- Negative, conflicting and malformed power output remains blocked without raw
  dumpsys diagnostic; keyguard is independent and unchanged.
- Exact `wf-284-3c09c0068d20` paused predecessor can create one immutable
  state-preserving successor after the correction controller is merged.
- Predecessor bytes and stage/attempt/evidence/artifact state remain unchanged;
  second successor and any projection/tail/effect drift fail closed.

## Validation plan

1. Focused production power parser/preflight fixture tests.
2. Fake adapter, exact device and forbidden-operation regressions.
3. Exact paused successor, mismatch rejection, byte immutability and idempotency.
4. Workflow/bootstrap/device-smoke suites and all orchestrator tests.
5. Full Python suite and `python -m compileall -q app scripts tools`.
6. Exact 12-path allowlist, protected/mobile diff `0` and `git diff --check`.

## Safety and budgets

- Product/mobile source, Issue #284 target/ref/checkpoint/APK/live runtime,
  build/install/ADB/tablet and real-user operation: `0`.
- Force-push, amend, rebase, merge and release: `0`.
- Ordinary commit, normal push and one Draft PR are authorized only after PASS.
- Exact write allowlist is the 12 paths in authorization `5168941496`.
