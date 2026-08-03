# Issue #305 Task — Display Power header resume

## Authority

- GitHub Issue: `#305`
- Binding correction authorization: `5170082561`
- Canonical repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Exact base: `d83efc2e1c07dc13a53df66753f7f59b7115c053`
- Branch: `codex/issue-305-display-power-header-resume`
- Validation class: orchestrator live recovery correction
- Capability: Code + Network + Publish
- Codex reasoning: Extra High
- Selection reason: parser semantics, immutable runtime provenance and
  regression-sensitive successor-chain logic require contract-level reasoning.

## Changed contracts

- Only exact `Display Power: state...` candidates participate in display-state
  validation; benign non-state object/header information is ignored.
- Exact ON/OFF, wakefulness aliases, interactive/display conflict, keyguard and
  all device/user safety guards remain unchanged and fail closed.
- Exact `wf-284-22b98a6db3d0` fifth-pause predecessor can create one immutable,
  state-preserving fourth successor after the correction controller is merged.
- Full predecessor chain bytes and current stage/attempt/pause/admission/budget/
  evidence/artifact state remain preserved; drift and later successor stop.

## Validation plan

1. Exact live parser/header and malformed state-candidate fixtures.
2. Existing aliases, interactive/display/keyguard, fake adapter and forbidden
   operation regressions.
3. Exact fifth-pause successor, full-chain immutability, mismatch rejection,
   contract drift and idempotency.
4. Workflow/bootstrap/device-smoke suites and all orchestrator tests.
5. Full Python suite and `python -m compileall -q app scripts tools`.
6. Exact 12-path allowlist, protected/mobile diff `0` and `git diff --check`.

## Safety, reuse and budgets

- Reused unchanged contracts: Issue #284 target/checkpoint/blob/artifact/tool/
  device/publish/stage contract; prior passed test/analyze/build/artifact state.
- Physical-device acceptance: `0`; authorization explicitly forbids live
  runtime, build/install/ADB/tablet operations in this implementation run.
- Primary run: `1`; bounded correction: at most `1`.
- Product/mobile source, Issue #284 target/APK/live runtime and real-user
  operation: `0`.
- Force-push, amend, rebase, merge and release: `0`.
- Ordinary commit, normal push and one Draft PR are authorized only after PASS.
- Exact write allowlist is the 12 paths in authorization `5170082561`.
