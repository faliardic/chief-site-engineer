# CSE Agent Loop MVP

The CSE Agent Loop reduces the operator workflow to one approved GitHub Issue.
After merge, a scheduled GitHub Actions workflow selects the oldest approved CSE
task, runs Codex in a bounded workspace, executes the Issue's deterministic
validation commands, opens a Draft PR, and asks a separate ChatGPT reviewer to
approve the diff or request one correction round.

## Status flow

```text
CSE_BRIDGE_APPROVED
→ CODEX implementation
→ deterministic validation
→ Draft PR
→ ChatGPT review
→ optional Codex correction
→ ChatGPT re-review
→ READY_FOR_FATIH | NEEDS_HUMAN | FAILED
```

GitHub Issue comments are the shared control plane. The workflow uses the
existing `cse-bridge-task:v1` Issue contract and the repository's existing task
parser, trusted approval checks, write allowlist, protected-path rules and
validation-command policy.

## Safety boundaries

- No automatic merge or release.
- Codex cannot perform GitHub publication; host steps commit, push and create the Draft PR.
- Issue-declared allowed paths are enforced before every commit.
- Issue-declared validation commands are executed by the host without a shell.
- The loop is bounded to the initial implementation plus one correction round.
- Terminal outcomes are `PASS`, `NEEDS_HUMAN` or `FAILED`.
- Product, device, user-data, backup and release operations remain prohibited unless separately and explicitly authorized outside this workflow.

## Required repository configuration

- GitHub Actions secret: `OPENAI_API_KEY`
- Optional repository variable: `CSE_REVIEW_MODEL` (default: `gpt-5.6`)

The workflow uses OpenAI's official `openai/codex-action@v1` for implementation
and the official OpenAI Python SDK for the independent reviewer. The existing
Windows Scheduled Task remains disabled and is not part of this MVP.

## Activation

The workflow becomes active only after its PR is reviewed and merged to the
default branch. It polls every five minutes and can also be run manually with a
specific approved Issue number.
