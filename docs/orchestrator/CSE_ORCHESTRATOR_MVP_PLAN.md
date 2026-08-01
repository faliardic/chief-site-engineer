# CSE Development Orchestrator MVP Planı

## 1. Program ilkesi

Orchestrator programı deterministik güvenlik oracle'ını AI ve action runner'dan
önce kurar. Her faz ayrı GitHub Issue, changed-contract listesi, capability,
approval, budget ve minimum yeterli validation planı gerektirir.

Bu yatay geliştirme programı CSE'nin production ürün roadmap sırasını değiştirmez
ve açık production Issue'larının yerine geçmez.

## 2. Faz özeti

| Faz | Amaç | Mutable action |
| --- | --- | --- |
| O0 | Mimari ve güvenlik sözleşmesi | Yalnız docs, açık yetkiyle |
| O1 | Read-only Git/GitHub observer | Repository/GitHub write yok |
| O2 | State machine ve policy engine | Action execution yok |
| O3 | Test/build/result parser | Test/build başlatma yok |
| O4 | Issue #284 replay fixtures | Codex/API/device yok |
| O5 | Codex dry-run | Source write yok |
| O6 | Controlled Codex execution | Exact allowlist ve approval |
| O7 | Commit/build/device approval gates | Her action ayrı approval |
| O8 | GitHub evidence ve Draft PR adapter | Bounded publish approval |
| O9 | OpenAI API planner | Ayrı secret/network kararları |
| O10 | Opsiyonel tray/service/self-hosted runner | Ayrı operasyon ve threat model |

## 3. O0 — Mimari ve güvenlik sözleşmesi

Teslimatlar:

- architecture;
- state machine;
- security boundary;
- approval model;
- MVP plan;
- learning ve kanonik kayıt hizalaması.

Acceptance:

- operational truth ve drift davranışı açık;
- bütün state ve blocker kodları tanımlı;
- capability ve approval sınırları açık;
- runtime state repository dışında;
- production implementation, API, build ve device action `0`.

## 4. O1 — Read-only Git/GitHub observer

### 4.1 Exact minimum teslimat

1. Canonical repository root doğrulaması.
2. Branch, HEAD, parent, tree, staging ve tracked-worktree fingerprint.
3. Local `master`, cached `origin/master` ve canlı remote `master` karşılaştırması.
4. Current Issue ve bütün yorumların read-only alınması.
5. Latest-valid authorization parse sonucu.
6. Task/result/state dosyalarının varlık, revision ve hash gözlemi.
7. Operational-truth drift'lerinin standart blocker kodlarına dönüştürülmesi.
8. Sanitized JSON observation'ın stdout ve repository dışı runtime root'a yazılması.
9. Deterministik exit code.

### 4.2 O1 yasakları

- fetch, pull, checkout veya branch creation;
- repository file write veya `.cse/state` finalization;
- `git status --ignored --untracked-files=all`;
- repository-wide ZIP/export/user-path scan;
- test, analyze veya build;
- Codex invocation;
- GitHub write;
- device veya gerçek kullanıcı verisi erişimi.

### 4.3 Mevcut script geçişi

`scripts/cse_status.py` doğrudan O1 değildir. Git head/divergence collector
mantığı fixture'larla ayrıştırılabilir; ignored/untracked/ZIP/export taraması ve
explicit `--finalize-state` write yolu observer process'inden ayrı kalır.

## 5. O2 — State machine ve policy engine

Prerequisite: O1 observation schema ve drift fixture'ları PASS.

Teslimatlar:

- transition table'ın executable saf fonksiyonu;
- state entry/exit invariant'ları;
- approval/capability/budget admission;
- blocker mapping;
- append-only event ve projection;
- invalid transition, duplicate event ve replay idempotency fixture'ları.

O2 action çalıştırmaz. Policy sonucu yalnız `allow`, `deny` veya
`awaiting_approval` olur.

## 6. O3 — Test/build/result parser

Prerequisite: O2 deterministik admission ve event replay PASS.

Teslimatlar:

- supported command-family result schema;
- action-started ve wrapper-failed ayrımı;
- exit code, duration, test count ve failure class parser'ları;
- stdout/stderr sanitization ve hash;
- failed-stage ve budget-consumption sonucu;
- malformed/truncated/timeout fixture'ları.

O3 test veya build başlatmaz; yalnız frozen output parse eder.

## 7. O4 — Issue #284 replay fixtures

Prerequisite: O1–O3 oracle zinciri PASS.

### 7.1 Sanitized fixture içeriği

- başlangıç approval comment `5140760422`;
- exact base, branch ve scope fingerprint;
- test-first baseline sonucu;
- source, harness ve tool-timeout ayrımı;
- correction ve continuation comment sequence'i;
- her adımın allowlist/budget değişimi;
- focused/full evidence reuse;
- checkpoint approval `5146083446`;
- checkpoint `b0e9cf247afa6bac5d38684dbc626a11fdf45663`;
- build/device approval `5146161593`;
- son bounded continuation `5147042969`.

### 7.2 Replay assertion'ları

- Eski yorum latest-valid authorization'ı override edemez.
- Budget yalnız explicit yeni yorumla genişler.
- Aynı failure kör retry üretmez.
- Action başlamadıysa invocation provenance olmadan tüketilmiş sayılmaz.
- Scope/source drift fail-closed durur.
- Frozen bloblarda geçerli evidence yeniden kullanılabilir.
- Task ve `.cse/state` GitHub'daki daha yeni authorization'ı override edemez.
- Unauthorized build/device/publish action `0` kalır.

Fixture; gerçek kullanıcı içeriği, tablet backup'ı, raw UI dump, app-private
veri, secret veya cihaz dosyası içermez. O4 Codex/API/build/ADB çalıştırmaz.

## 8. O5 — Codex dry-run

Prerequisite: O4 replay matrix PASS.

Dry-run:

- exact prompt/action manifesti üretir;
- expected read/write/validation planını gösterir;
- approval ve budget admission'ı simüle eder;
- Codex'i source write yetkisiyle çalıştırmaz;
- Git veya GitHub mutation yapmaz.

Acceptance, aynı input için deterministik plan/fingerprint ve zero source diff'tir.

## 9. O6 — Controlled Codex execution

Prerequisite: O5 dry-run provenance PASS ve ayrı security review.

İlk scope dar docs veya test fixture değişikliği olmalıdır. Code profile:

- exact worktree;
- exact read/write allowlist;
- one primary ve bounded correction;
- no publish/device credentials;
- post-action deterministic validation;
- fail-closed source drift.

Production source ilk O6 pilotu olarak varsayılmaz.

## 10. O7 — Commit/build/device approval gates

Prerequisite: O6 kontrollü source execution PASS.

Her gate ayrı action'dır:

1. `CHECKPOINT_COMMIT`
2. `BUILD`
3. `DEVICE`

Commit source validation'ı, build exact checkpoint provenance'ı, device exact
artifact/serial/package/sentetik veri sınırını ister. Bir gate'in PASS'i sonraki
gate'in approval'ı değildir.

## 11. O8 — GitHub evidence ve Draft PR adapter

Prerequisite: O7 evidence chain ve Publish profile isolation PASS.

Teslimatlar:

- exact branch/head/base publish admission;
- normal push; force-push yasağı;
- Draft PR payload ve related-Issue bağı;
- veri-minimal completion evidence;
- remote result parse;
- merge/release kararının kapsam dışında kalması.

## 12. O9 — OpenAI API planner

OpenAI API ilk kez O9'da değerlendirilebilir çünkü O0–O4 deterministik oracle,
O5 dry-run ve O6–O8 bounded action/evidence katmanlarını önce kanıtlar.

O9 ayrı olarak şunları karara bağlamalıdır:

- model ve output schema;
- nondeterminism sınırı;
- prompt/source minimization;
- credential backend;
- network/timeout/cost budget;
- data retention;
- planner output'unun yalnız öneri olması;
- policy engine'in AI output'una rağmen son otorite kalması.

API key repository, event, manifest, log veya evidence içine yazılamaz.

## 13. O10 — Opsiyonel Windows operasyon yüzeyi

Tray/service veya self-hosted runner zorunlu MVP değildir. Ancak bütün önceki
fazlar PASS ve ayrı threat model hazırsa değerlendirilebilir.

Ek kararlar:

- service account ve session isolation;
- Windows startup/update lifecycle;
- credential access;
- local notification/UI;
- crash recovery;
- runtime-root cleanup;
- self-hosted runner'ın repository/user-data sınırı.

## 14. Faz admission checklist'i

Her yeni O-Issue şu alanları taşır:

- changed contracts;
- validation class;
- exact base/branch;
- source/read/write/action allowlist;
- approval level ve capability;
- reused evidence;
- retry/correction/invocation/time budget;
- user-data ve secret sınırı;
- stop conditions;
- explicit out-of-scope;
- final publish/merge/release authority.

Eksik alan yeni fazın başlamasına izin vermez.
