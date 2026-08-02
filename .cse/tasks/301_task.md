# Issue #301 — Host-owned live API publication

## Yürütme sözleşmesi

- Authorization comment: `5159253790`
- Validation class: `api-live-pilot-and-sequencing-fix`
- Exact base: `1640e2028156cbe75f4e9530fd5f154cf344c04e`
- Branch: `codex/issue-301-cse-orchestrator-live-api-pilot`
- Model/reasoning: mevcut tam Codex modeli, `Extra High`; executable ve Git
  provenance değişikliği regresyon hassastır.
- Capability: `Code + Network + Publish`
- Exact write allowlist: Issue gövdesindeki `13/13` yol.
- Primary implementation: `1`; bounded same-scope correction: en fazla `1`.
- Pre-live oturumunda API, nested child, stage, commit, push ve PR: `0`.

## Değişen sözleşmeler

- Nested child yalnız exact dosya editleri ve testlerden sorumludur; Git write
  veya publish yapmaz.
- Host child PASS sonrasında branch/base/scope/worktree doğrulaması, final test,
  exact staging, tek commit, tek normal push, provenance ve tek Draft PR yapar.
- `codex`, `codex.exe` ve `codex.cmd` shell açmadan güvenli çözülür.
- Default dry-run ve fail-closed davranış korunur.

## Doğrulama ve sınırlar

- Focused, compileall, full Python, diff-check, exact allowlist, secret,
  forbidden-I/O ve protected-path kontrolleri.
- Fiziksel cihaz kabulü gerekmez; mobile/production sözleşmesi değişmez.
- Dependency, workflow, `.cse/state`, `scripts/cse_status.py`, Issue #284,
  Ready/merge/close/delete/tag/release kapsam dışıdır.
- Time budget: `75 dakika`; live action retry bütçesi `0`.
