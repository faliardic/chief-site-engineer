# Issue #295 — CSE Orchestrator O5–O8 MVP

## 1. Amaç ve sınır

Bu dilim O1 Observation, O2 policy, O3 frozen result ve O4 replay oracle'ını
controlled execution hattına bağlar:

```text
observe → policy → ActionPlan → admission ledger → injected execution
→ O3 result → deterministic gate → normal push → Draft PR
```

Varsayılan davranış `dry_run`dır. Action ancak exact `execute` planı, explicit
execute flag'i, allowed policy decision, source/action fingerprint recheck'i ve
repository-dışı admission ledger birlikte mevcutsa başlayabilir.

Issue #295 doğrulamasında gerçek Codex, build, ADB/device veya GitHub mutation
Orchestrator üzerinden çalıştırılmaz. Testler yalnız injected fake process ve
GitHub client kullanır. Bu Issue'ın ordinary commit/push/Draft PR teslimatı
Orchestrator runtime'ının parçası değildir.

## 2. O5 — Immutable ActionPlan v1

`planner.build_action_plan` üç caller-owned girdiyi birleştirir:

1. O1 `Observation v1`;
2. O2 invocation admission `PolicyDecision`;
3. exact-schema action request.

Plan; run/action/Issue kimliği, mode, canonical cwd, repository/branch/base/
head/tree, exact argv, command family, capability, read/write/action/environment
allowlist, timeout/output limiti, validation planı, source/contract/action
fingerprint'leri, approval comment ID, budget delta, success/failure state ve
gate/publish provenance'ı taşır.

Action fingerprint planın executable kimliğinden, plan hash'i bütün identity
payload'ından canonical sorted compact JSON ile üretilir. Aynı input aynı
`plan_sha256` değerini verir. Public mapping yeni kopyadır; dataclass, nested
provenance ve budget mapping immutable tutulur.

Fail-closed kontroller:

- unknown action/family/executable;
- shell string veya shell executable/operator;
- wildcard argv/cwd/allowlist;
- repository dışına çıkan cwd/path;
- observation/request branch, base, head veya tree farkı;
- source/contract fingerprint eksikliği veya drift;
- denied/non-invocation policy;
- action–approval–capability uyumsuzluğu.

Plan üretimi subprocess, network veya filesystem mutation yapmaz.

## 3. O6 — Admission ledger ve controlled runner

`RuntimeLedger`, `%LOCALAPPDATA%\CSE-Orchestrator` gibi repository dışındaki
caller-selected runtime root altında run-bazlı JSON Lines tutar. Her event:

- monoton sequence;
- önceki event hash'i;
- canonical event hash'i;
- data-minimal admission veya result payload'ı

taşır. Her append öncesi ve sonrası zincir doğrulanır. Aynı action fingerprint
için ikinci admission, result-without-admission, sequence/hash-chain drift'i ve
tamper fail-closed olur. Raw stdout/stderr ledger'a girmez.

Admission event aynı kayıt içinde şunları bağlar:

- approval comment ve one-time consumption;
- policy budget delta admission'ı;
- exact plan/source/contract/action fingerprint;
- adapter, argv ve cwd invocation-start provenance'ı.

`ControlledRunner`, admission'ı append etmeden adapter'a geçmez. Environment
yalnız plan allowlist'indeki non-secret anahtarlarla kurulur. Runner exact argv
tuple, canonical cwd, timeout ve output limitini injected adapter'a verir.

Gerçek adapter yalnız explicit execute kullanımına açıktır ve `shell=False`
kullanır. Testlerde fake adapter zorunludur. Start öncesi wrapper failure,
timeout, non-zero ve success aynı O3 parser'a frozen result olarak gider.
`action_started=false` sonucu budget consumption üretmez.

## 4. O7 — Ayrı gate planları

Gate builder action çalıştırmaz; controlled runner için provenance-bound plan
üretir. Bir gate PASS'i sonraki gate approval'ı değildir.

### CHECKPOINT_COMMIT

- branch/head/tree ve parent/base;
- source manifest fingerprint;
- exact staged allowlist;
- `git diff --cached --check` validation adımı;
- single commit budget;
- expected post-commit head/tree

aynı plan provenance'ında tutulur.

### BUILD

- exact checkpoint SHA/tree;
- exact build argv/cwd/output path;
- artifact SHA/package/version/signer evidence contract;
- single build invocation budget

taşır. Build sonucu device approval değildir.

### DEVICE

- exact artifact SHA;
- yalnız sembolik device target;
- Device capability/approval;
- exact ADB argv ve retry budget

taşır. Gerçek serial, `uninstall`, `pm clear`, `clear-data` ve hard-delete plan
aşamasında reddedilir.

## 5. O8 — Normal push ve Draft PR

Publish planı yalnız `PUBLISH` action/approval/capability, exact source ve şu
argv biçimini kabul eder:

```text
git push origin <exact-branch>
```

Force flag, remote divergence, farklı base, existing PR, ready PR veya
`Closes #<issue>` olmayan body fail-closed olur. Base yalnız `master`, PR yalnız
Draft ve tekildir.

`execute_publish`, injected GitHub client ile push'tan önce duplicate open PR
kontrolü yapar. Normal push O3 generic parser'dan geçmeden PR oluşturulmaz.
Draft PR response'u da frozen generic result olarak sınıflanır. Blind retry
yoktur. Ready, merge, Issue close, branch delete ve release action'ları bu
adapter kapsamı dışındadır.

## 6. CLI MVP

Mevcut `observe` korunur ve şu komutlar eklenir:

- `plan`: canonical dry-run ActionPlan;
- `execute`: `--execute` olmadan fail-closed;
- `gate-plan`: checkpoint/build/device planı;
- `publish-plan`: normal push + Draft PR planı;
- `ledger-verify`: repository-dışı ledger hash-chain doğrulaması.

CLI JSON dosyalarını exact object olarak okur. Default mode belirtilmezse plan
komutlarında `dry_run` kullanılır. Execute explicit flag, plan mode, policy ve
fingerprint admission'larını birlikte ister.

## 7. Güvenlik ve veri minimizasyonu

- Runtime root repository içinde olamaz.
- Planner/gate builder external I/O yapmaz.
- Runner yalnız injected adapter ve exact argv kullanır.
- Secret-benzeri environment/provenance anahtarları reddedilir.
- Raw authorization/comment body veya kullanıcı verisi plan/ledger'a girmez.
- Output O3 stream hash'i ve bounded sanitized excerpt ile sınırlıdır.
- Gerçek device serial planlanmaz; yalnız caller-bound symbolic target kalır.
- Dependency, workflow, production, mobile, `.cse/state` ve
  `scripts/cse_status.py` değişmez.

## 8. Test yaklaşımı

Focused suite canonical determinism/immutability, policy/source drift, shell ve
path guard, external runtime root, admission-before-execution, duplicate/tamper,
harness/timeout/non-zero/success, budget evidence, checkpoint/build/device
provenance, destructive ADB rejection, normal push, Draft PR, duplicate PR ve
out-of-scope GitHub action'larını fake adapter'larla doğrular.

Full Python suite O1–O4 public contract regressionlarını da birlikte korur.
Gerçek Codex, build, API, ADB veya cihaz kabulü bu değişen sözleşme için gerekli
değildir ve çalıştırılmaz.
