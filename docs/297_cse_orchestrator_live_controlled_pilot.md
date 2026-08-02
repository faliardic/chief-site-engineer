# CSE Orchestrator ilk canlı kontrollü pilot

## Amaç

Issue #297, O0–O8 Orchestrator MVP zincirini ilk kez injected fake process
adapter yerine gerçek `SubprocessProcessAdapter` ile çalıştırdı. Action,
repository source'unu değiştirmeyen tek bir odaklı pytest komutuydu:

```text
python -m pytest -o addopts= --color=no tests/test_cse_orchestrator_mvp.py
```

`-o addopts=` repository pytest seçeneklerini yalnız bu invocation için
temizledi. `--color=no`, O3 parser'ın deterministic olarak okuyabildiği explicit
`30 passed` özetinin ANSI renk kodu taşımamasını sağladı.

## Kontrollü zincir

```text
real Git/GitHub observation
→ deterministic FULL_VALIDATION admission
→ canonical dry-run plan
→ canonical execute plan
→ append-only admission event
→ shell=False real subprocess
→ O3 parsed result
→ append-only result event
→ ledger verification
→ duplicate admission rejection
```

### O1 gözlemi

- Branch ve HEAD:
  `codex/issue-297-cse-orchestrator-live-pilot` @
  `7151235c0bbd81910f55ccbd1a89458b498d1f7d`
- Tree: `00e7d8794b6fe3fde0deb0e420f5e29e55f8f911`
- Tracked source fingerprint:
  `sha256:6179f49a4a6d4c4415a345ea8d796a45bc51649f4f0befe88ca731fcd0eabdad`
- Observer run ID: `2fca64c41ec44ca998abf188101a2e84`
- Staging ve tracked worktree observation anında boştu.

O1 raw Issue/comment body veya kullanıcı verisi taşımadı. Human-readable
authorization comment `5158523734`, exact action ve budget fingerprint'leriyle
planning observation'a bağlandı.

### O2 admission

O2 policy, immutable input için `FULL_VALIDATION` admission'ını allowed olarak
üretti:

```text
ACTION_AUTHORIZED → ACTION_RUNNING
budget_delta = full_gate_used +1
```

Approval consumption, budget admission ve invocation-start provenance aynı
external append-only admission event'inde kaydedildi.

### O5 planları

- Dry-run plan SHA:
  `sha256:7fc39e88e6fb255c7e4ffdf8b953818050adcb8e4b45e39e7753a67c090ed535`
- Execute plan SHA:
  `sha256:fe86a8e073f43562224ec1bcc38823833641378e8ba251a87c81561bcff74cc3`
- Ortak action fingerprint:
  `sha256:a999539ceea3a1f5fa33068a79ea34c378c02043d1b417d78d92c02eb0f90192`

Mode ve plan SHA ayrıdır; argv, cwd, source, contract, action identity,
allowlist ve capability aynıdır.

### O6 ve O3 sonucu

- Real adapter: `SubprocessProcessAdapter`
- `shell`: `false`
- Gerçek subprocess invocation: `1`
- Output limiti: `262144` byte
- Environment-name allowlist: `PATH`, `PATHEXT`, `SYSTEMROOT`, `WINDIR`,
  `TEMP`, `TMP`, `USERPROFILE`, `LOCALAPPDATA`
- Environment değerleri plan, result, ledger veya repository evidence'ına
  yazılmadı.
- Exit code: `0`
- Failure class: `null`
- Passed/failed/total: `30/0/30`
- Truncated: `false`
- Final state: `FULL_PASS`

Raw stdout/stderr ledger'a alınmadı. O3 yalnız stream hash'leri, bounded
sanitized excerpt ve deterministic count alanlarını üretti.

### Ledger ve duplicate koruması

External ledger iki event taşıdı:

1. `admission`
2. `result`

Ledger verification PASS ve tail hash şudur:

```text
sha256:54350f429891a3987e2d9bd02a13db51a52f64a3b9fc1047667f9b9032be68c6
```

Aynı execute planı ikinci kez sunulduğunda ledger action fingerprint'ini daha
önce admitted gördü ve `duplicate_action` ile `BLOCKED` döndürdü. İkinci
subprocess başlamadı; ledger event sayısı ve tail hash değişmedi.

## Güvenlik ve kapsam sonucu

- Runtime girdileri ve ledger repository dışında kaldı.
- Önceki pilot ledger'ları değiştirilmedi.
- Production, mobile, tools, tests, dependency, workflow, `.cse/state` ve
  `scripts/cse_status.py` değiştirilmedi.
- Build, ADB/device, OpenAI API veya Orchestrator üzerinden GitHub mutation
  çalıştırılmadı.
- Repository değişikliği yalnız veri-minimal docs/task/result evidence'ıdır.
- Ready, merge, Issue close, branch delete, tag ve release ayrı yetki ister.
