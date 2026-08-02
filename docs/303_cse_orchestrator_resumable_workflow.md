# Issue #303 — O10 resumable one-command workflow

## Amaç

O10, operatorün her test/build/device/publish kapısı için yeni prompt taşımasını
kaldırır. Bir kez doğrulanmış workflow-level authorization; exact stage
sırasını, capability'leri, target'ları ve bütçeleri dondurur. Coordinator PASS
sonrasında aynı process içinde ilerler, gerçek dış koşulda pause eder ve aynı
komut yeniden çağrıldığında append-only state'ten devam eder.

## Komut yüzeyi

```powershell
python -m tools.cse_orchestrator.cli workflow-run `
  --issue 303 `
  --repo-root V:\path\to\target-worktree `
  --runtime-root C:\external\cse-runtime
```

`workflow-run` varsayılan olarak dry-run'dır. Gerçek execution için hem
authorization payload'ında `execution: true` hem CLI'da `--execute` gerekir.

```powershell
python -m tools.cse_orchestrator.cli workflow-status `
  --issue 303 --repo-root V:\path\to\target-worktree `
  --runtime-root C:\external\cse-runtime

python -m tools.cse_orchestrator.cli workflow-verify `
  --issue 303 --repo-root V:\path\to\target-worktree `
  --runtime-root C:\external\cse-runtime
```

`workflow-status` ledger'dan replay edilmiş current stage ve next action'ı
okur. `workflow-verify`, immutable manifest, hash-chain ledger, projection
cache ve varsa projected artifact SHA-256 bağını salt okunur doğrular.

## Sözleşme bileşenleri

- `workflow_authorization.py`: marker + fenced JSON yorumunu strict şemayla
  ayrıştırır; canonical fingerprint ve latest-valid supersession üretir.
- `workflow_store.py`: repository dışı immutable contract, append-only event
  ledger ve atomik projection cache sağlar.
- `workflow.py`: target preflight, deterministic stage seçimi, command
  diagnostics, reuse, pause/resume, correction ve duplicate-safe publish
  adapter'larını koordine eder.
- `cli.py`: GitHub yorumundan authorization discovery veya test/admin amaçlı
  exact local payload ile run/status/verify komutlarını sunar.

## Fail-closed sınırlar

- Controller checkout, target repository ve runtime root farklıdır. Controller
  path, gerçekten import edilen Orchestrator package source root'uyla eşleşir.
- Yeni workflow exact branch/HEAD/tree ve tamamen temiz target ister. Existing
  paused workflow yalnız ledger'daki son source fingerprint korunuyorsa devam
  eder.
- Changed path'lerin tamamı write allowlist içinde olmalıdır. Completion ayrıca
  boş staging ve temiz target worktree ister.
- Device stage yalnız exact device contract, `adb -s <serial>` ve destructive
  olmayan argv ile parse edilir.
- Raw stdout/stderr, Issue/comment body veya kullanıcı içeriği ledger/Issue
  evidence'a yazılmaz; yalnız bounded metadata ve SHA-256 taşınır.
- Merge, release, Ready, force-push, rebase, amend, uninstall ve clear-data
  action'ları yoktur.

## Resume ve idempotency

`stage_admitted` benzersiz attempt identity taşır. Result gelmeden ikinci
admission mümkün değildir. Resumable failure yalnız stage retry + global
correction + invocation budget birlikte kaldığında yeni attempt alır.

Build/artifact stage'i PASS olduktan sonra device external blocker üretirse
projection artifact path/hash/package/version/signer/checkpoint alanlarını
korur. Resume önce artifact hashini yeniden doğrular; build stage'ini tekrar
çalıştırmaz. Commit, push, Draft PR ve Issue evidence için mevcut exact sonuç
reuse edilir; farklı mevcut sonuç unsafe provenance drift'idir.

## Kabul kanıtı

O10 acceptance; focused coordinator, bütün orchestrator, full Python ve
compileall kapılarının yanında şu senaryoları da otomatik test eder:

- her gate sonrasında process crash ve yeni coordinator instance ile resume;
- stale/missing projection cache'in authoritative ledger'dan recovery'si;
- external device pause, artifact preservation ve build skip;
- artifact/ledger/projection/authorization tamper;
- exact fingerprint PASS reuse ve duplicate attempt engeli;
- duplicate-safe comment/commit/push/Draft PR;
- secret ve raw-user-content redaction;
- CLI workflow-run/status/verify e2e.

Canlı Issue #284 device resume pilotu bu implementation teslimatının bir
mutation adımı değildir. Ayrı authorization ile O10 kabul zincirinin sonraki
mekanik aşamasıdır.
