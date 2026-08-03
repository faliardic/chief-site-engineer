# Issue #305 Task — Live evidence verification correction

## Authority

- GitHub Issue: `#305`
- Binding correction authorization: `5162083387`
- Canonical repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Exact base: `53ebdbc217ab1e463e70c661b379013e56f4a3b0`
- Branch: `codex/issue-305-live-evidence-correction`
- Validation class: orchestrator evidence contract correction
- Capability: Code + Network + Publish
- Codex reasoning: Extra High; byte-level evidence verification and
  fail-closed regression risk require exact source reasoning.

## Changed contracts

- GitHub Markdown evidence is hashed through one transport-stable
  `canonical_markdown_bytes(...)` contract.
- BOM, CRLF/CR and terminal-newline representation are transport-only.
- Inner whitespace and every semantic character remain hash-significant.
- Evidence drift blockers identify Issue/comment source IDs.
- Frozen hashes use current live content after the same canonicalization.
- Bootstrap's read-only GitHub evidence adapter decodes JSON as strict UTF-8,
  independent of the Windows locale.

## Validation plan

1. Hash-only live diagnostic without raw content.
2. Focused canonicalization/bootstrap tests.
3. Bootstrap + workflow + device-smoke tests.
4. All `tests/test_cse_orchestrator*.py`.
5. Full Python suite.
6. `python -m compileall -q app scripts tools`.
7. Exact 9-path allowlist, protected diff `0`, diff check and clean staging.

## Safety and budgets

- Product/mobile source, Issue #284 target/runtime, build, install, ADB, device,
  smoke and real-user data operations: `0`.
- Force-push, amend, rebase, merge and release: `0`.
- Ordinary commit, normal push and one Draft PR are authorized only after PASS.
- Exact write allowlist is the nine paths in authorization `5162083387`.
