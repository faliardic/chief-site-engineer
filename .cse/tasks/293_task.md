# Issue #293 — O4 Issue #284 Sanitized Replay Görevi

## Otorite

- GitHub Issue: `#293`
- Execution authorization comment: `5158063537`
- Replay source: Issue `#284` ve exact `19/19` yorum
- Branch: `codex/issue-293-cse-orchestrator-issue-284-replay`
- Exact base: `e3e32a65c1a8fa589e879c91c1494cf73b606ac3`
- Başlangıç tree: `42929cc32300852be993253e712eb5d74d9d5428`
- Capability: `Code`
- Validation class: `python-tooling-deterministic`

## Değişen sözleşmeler

- Issue #284 yorum zincirinin raw body taşımayan 19-event sanitize fixture'ı.
- Latest-valid authorization, explicit supersession ve GitHub > task/result >
  `.cse_state` source precedence replay'i.
- Scope/allowlist/budget extension, blind retry, invocation-start, failure
  class, drift ve reused-evidence bağları.
- Checkpoint commit/parent/tree provenance'ı ile build/device/publish gate'i.
- Byte-stable, immutable ve sahte completion üretmeyen canonical replay özeti.

## Validation planı

- Focused: `python -m pytest tests/test_cse_orchestrator_replay.py`
- Compile: `python -m compileall tools/cse_orchestrator`
- Full: `python -m pytest`
- Fixture: JSON syntax ve forbidden-pattern scan.
- Dar kalite: `git diff --check`, exact 11-path allowlist ve protected-path
  diff `0`.
- Fiziksel cihaz: `0`; fixture hedefi yalnız `tablet_primary` sembolüdür.
- Reused evidence: O1–O3 regression full Python suite içinde doğrulanır.

## Bütçe ve stop sınırı

- Primary implementation: `1/1`
- Bounded same-scope correction: en fazla `1/1`
- Focused/compile/full invocation: primary zincirde birer kez; yalnız correction
  gerekirse etkilenen zincir bir kez tekrarlanır.
- Ordinary commit/push/Draft PR: `1/1/1`
- İkinci correction, commit, push veya PR; force-push ve merge: `0`.

## Exact write allowlist

1. `tools/cse_orchestrator/replay.py`
2. `tests/fixtures/cse_orchestrator/issue_284_replay.json`
3. `tests/test_cse_orchestrator_replay.py`
4. `docs/293_cse_orchestrator_o4_issue_284_replay.md`
5. `learning/293_cse_orchestrator_o4_issue_284_replay.md`
6. `.cse/tasks/293_task.md`
7. `.cse/results/293_result.md`
8. `tools/cse_orchestrator/__init__.py`
9. `CHANGELOG.md`
10. `ROADMAP.md`
11. `docs/project_decisions.md`

## Açık kapsam dışı

- Issue #284 branch/checkpoint mutation'ı veya publication'ı.
- Gerçek Codex, test/build, API, ADB, device veya GitHub adapter action'ı.
- SQLite/event-store persistence.
- Raw comment body, kullanıcı kaydı, device serial, app-private veri, UI dump,
  log, credential veya yerel kullanıcı yolu.
- Dependency, workflow, production, mobile, `.cse/state` ve
  `scripts/cse_status.py` değişikliği.
