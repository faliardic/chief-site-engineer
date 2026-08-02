# Issue #299 — CSE Orchestrator O9 API otomasyonu

## Yürütme sözleşmesi

- Authorization comment: `5158650771`
- Validation class: `api-driven-controlled-automation`
- Exact base: `d19e0ac84a2f7a5856dbb7e2ee451f6eea177b8f`
- Branch: `codex/issue-299-cse-orchestrator-api-automation`
- Capability: `Code + Network + Publish`
- Exact write allowlist: Issue body'deki `16/16` yol
- Primary implementation: `1`
- Bounded correction: en fazla `1`
- OpenAI API / Codex child / REST Draft PR budget: `1/1/1`, retry `0`
- Ordinary commit / push / Draft PR: `1/1/1`

## Değişen sözleşme

- Environment-only OpenAI Responses API client, strict structured proposal ve
  data-minimal response metadata;
- untrusted proposal için local policy, allowlist, capability, budget ve
  fingerprint revalidation;
- exact argv, shell-free, bounded ve duplicate-safe Codex child adapter;
- exact source'a bağlı tek Draft PR GitHub REST adapter;
- default dry-run, ayrı explicit API/Codex/publish kapılı `api-run` CLI.

## Validation

1. `python -m pytest -o addopts= --color=no tests/test_cse_orchestrator_api_automation.py`
2. `python -m compileall tools/cse_orchestrator`
3. `python -m pytest -o addopts= --color=no`
4. exact allowlist, secret/forbidden-I/O/protected-path ve `git diff --check`

Credentials yoksa live pilot `CREDENTIALS_MISSING` kalır; secret istenmez veya
üretilmez. Dependency, production/mobile, workflow, `.cse/state`,
`scripts/cse_status.py`, build/device ve yayın sonrası Ready/merge/close/delete
kapsam dışıdır.
