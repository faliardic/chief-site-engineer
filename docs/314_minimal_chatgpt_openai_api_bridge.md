# Minimal ChatGPT–OpenAI API Bridge

## Purpose

The bridge removes Fatih from the prompt-relay loop.

```text
ChatGPT task Issue + approval comment
→ GitHub Actions
→ OpenAI Responses API with bounded file tools
→ deterministic validation and publication
→ Draft PR
→ ChatGPT review
```

The bridge is deliberately smaller than the former Orchestrator design. It does
not use workflow projections, successor runtimes, controller SHA handoffs or a
new approval for every gate.

## Main safety guards

1. Only the configured repository and `master` base are accepted.
2. Every task uses a new `codex/*` branch on an ephemeral GitHub runner.
3. The model can write only paths listed in the task Issue.
4. The model cannot run shell, Git, GitHub, credentials, ADB or device tools.
5. Validation commands are parsed without a shell and limited to approved
   Python, Flutter and `git diff --check` families.
6. Commit, push and Draft PR happen only after scope and validation PASS.
7. Only one correction pass is permitted.
8. Force-push, merge, release, hard reset/clean, branch deletion and device-data
   operations are outside the bridge.
9. Secrets are read from GitHub Actions secrets and are never passed to model
   tools or written to Issue comments.

## One-time setup

After the bootstrap PR is merged, configure:

- repository secret `OPENAI_API_KEY`;
- repository variable `CSE_BRIDGE_MODEL`.

No local daemon or recurring PowerShell command is required.

## Task format

```markdown
<!-- cse-bridge-task:v1 -->

## Repository
faliardic/chief-site-engineer

## Base
master

## Branch
codex/example-task

## Goal
Describe the change.

## Allowed paths
- path/or/glob

## Validation commands
- python -m pytest tests/example.py
- python -m compileall -q app scripts tools
- git diff --check

## Commit
Exact commit subject

## Draft PR
Exact PR title
Related to #123
```

ChatGPT adds a trusted Issue comment containing exactly:

```text
CSE_BRIDGE_APPROVED
```

That comment starts the GitHub Actions workflow. The bridge posts one of these
machine-readable states back to the Issue:

- `RUNNING`
- `PASS`
- `FAILED`
- `NEEDS_HUMAN`

## OpenAI API loop

The bridge calls the Responses API using the model selected by
`CSE_BRIDGE_MODEL`. The model receives only these tools:

- read a tracked, non-protected text file;
- search tracked text files;
- write or exactly replace an allowlisted file;
- list changed paths;
- finish with a summary.

The host, not the model, owns validation, commit, push and Draft PR creation.
Transport retries for temporary API errors are separate from the single coding
correction budget.

## Human-on-exception boundary

Fatih is interrupted only for:

- product or scope decisions;
- real-user-data or destructive-operation risk;
- physical device action;
- missing API configuration;
- one correction failing to reach PASS;
- an unknown high-risk condition.
