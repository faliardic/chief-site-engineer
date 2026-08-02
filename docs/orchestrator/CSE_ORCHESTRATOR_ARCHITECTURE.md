# CSE Development Orchestrator Mimarisi

## 1. Amaç ve ürün kararı

CSE Development Orchestrator'ın ilk amacı kod üretmek değildir. İlk amaç,
mevcut CSE geliştirme disiplinini; izinleri, kanıtları, bütçeleri ve fail-closed
geçişleriyle birlikte makine tarafından doğrulanabilir hâle getirmektir.

O0 yalnız sözleşme katmanıdır. Executable Orchestrator, OpenAI API, otomatik
Codex, GitHub write, commit, build, cihaz ve release davranışı içermez.

## 2. Mimari ilkeler

1. **Önce deterministik oracle:** Gözlem, policy ve parser katmanları AI'dan
   önce güvenilir olmalıdır.
2. **Fail-closed:** Eksik, eski veya çelişkili kanıt ilerleme izni değildir.
3. **İnsan kontrolü:** Orchestrator approval oluşturamaz, kapsam genişletemez
   veya Fatih adına ürün kararı veremez.
4. **Minimum yeterli doğrulama:** Gate genişliği yalnız değişen sözleşme ve
   doğrulanmış riskle orantılıdır.
5. **Immutable provenance:** Gözlem ve sonuçlar append-only eventlerle
   kaynaklarına bağlanır; projection geçmişi yeniden yazmaz.
6. **Capability isolation:** Code, Device ve Publish ayrı süreç, izin ve veri
   sınırlarıdır.
7. **Repository dışı runtime:** Geçici state, log, approval ve evidence Git
   çalışma ağacına yazılmaz.
8. **Veri-minimal kanıt:** Raw kullanıcı içeriği yerine kimlik, hash, sayaç ve
   sonuç sınıfı tutulur.

## 3. Bileşenler

### 3.1 Observer

Observer yalnız salt-okunur gerçekleri toplar:

- canonical repository root;
- branch, HEAD, parent ve tree;
- index/staging ve tracked-worktree fingerprint;
- local `master`, cached `origin/master` ve canlı GitHub `master` SHA;
- current Issue, bütün yorumlar ve en son geçerli authorization;
- task/result/state dosyalarının varlık, hash ve revision bilgisi.

Observer otomatik fetch, pull, checkout, branch creation veya repository write
yapmaz. Ignored/untracked kullanıcı alanlarını broad biçimde enumerate etmez.

### 3.2 Policy engine

Policy engine observer çıktısını aşağıdaki sözleşmelerle değerlendirir:

- operational truth;
- state transition invariant'ları;
- approval fingerprint;
- capability allowlist'i;
- retry, correction, invocation ve süre bütçeleri;
- blocker kodları;
- evidence reuse koşulları.

Policy engine karar üretir fakat eylem çalıştırmaz. Çıktısı `allow`, `deny` veya
`awaiting_approval` sınıfı ve gerekçeli state transition önerisidir.
`awaiting_approval`; `pending_action`, `required_approval_level`,
`resume_state`, `expected_success_state`, source fingerprint ve action
fingerprint bağlarını taşır. Geçerli Codex `CODE_CHANGE`/`CORRECTION` action'ı
`CODEX_AUTHORIZED`, diğer mutable veya maliyetli action'lar ise
`ACTION_AUTHORIZED` gate'ine yönelir.

### 3.3 Append-only event store

Event store run gözlemlerini ve geçişlerini immutable olay olarak saklar.
SQLite current projection için kullanılabilir; source eventler silinmez veya
sessizce güncellenmez. Projection yeniden üretilebilir olmalıdır.

Asgari event kimliği şu girdilerin deterministik birleşimine dayanır:

```json
{
  "schema_version": 1,
  "run_id": "o0-example-run",
  "sequence": 7,
  "event_type": "state_transition",
  "source_fingerprint": "sha256:example",
  "transition": "OBSERVING->SCOPE_VALIDATED"
}
```

Bu örnek uygulama değildir; O1/O2 şema tasarımına sınır gösterir.

### 3.4 Approval verifier

Approval verifier current Issue'daki yetkiyi parse eder; comment ID, canonical
payload hash, source fingerprint, action, capability, budget, expiry ve nonce
bağını doğrular. Yetkiyi kendi kendine oluşturamaz veya genişletemez.

Verifier yalnız authorization gate'ini açar; checkpoint commit, build, device
ve publish result state'lerini doğrudan üretmez. Her action önce
`AWAITING_APPROVAL`dan doğru specialized veya generic authorized state'e
geçmeli; Codex dışı action daha sonra `ACTION_RUNNING`, `RESULT_RECEIVED` ve
`DETERMINISTIC_VALIDATION` zincirini tamamlamalıdır.

O0 ilk docs koşusu geçiş dönemi insan-okur yorumuyla yetkilidir. Future
machine-readable schema O1 ve sonraki fazlarda uygulanır.

### 3.5 Capability runner

Capability runner gelecekte yalnız policy engine tarafından kabul edilmiş tek
profile ve exact action fingerprint'i çalıştırabilir. Her profile ayrı process,
environment, readable-path ve writable-path sınırı gerekir.

`CODEX_AUTHORIZED`, bounded `CODE_CHANGE`/`CORRECTION` action'ını
`CODEX_RUNNING`e; `ACTION_AUTHORIZED` ise Codex dışındaki exact
`FULL_VALIDATION`, `CHECKPOINT_COMMIT`, `BUILD`, `DEVICE` veya `PUBLISH`
action'ını `ACTION_RUNNING`e kabul eder.

`ACTION_RUNNING` entry'sinde `pending_action`, `required_approval_level`,
`resume_state`, `expected_success_state`, source/action fingerprint ve admission
event bağları korunur. Approval consumption, budget admission ve
invocation-start provenance aynı append-only admission event'inde atomik olarak
kaydedilir. Wrapper eylemi gerçekten başlatmadıysa consumption veya invocation
tahmin edilmez.

Her runner sonucu önce `RESULT_RECEIVED` içinde exit code/result, duration ve
sanitized stdout/stderr hashlerine bağlanır. Ardından
`DETERMINISTIC_VALIDATION`, korunmuş `pending_action` ve
`expected_success_state` bağına göre PASS result state'ini, `FAILED`ı veya
`BLOCKED`ı seçer. Codex dışı mutable/maliyetli bir action bu generic execution
zincirini atlayamaz.

O0'da runner implementation'ı yoktur.
### 3.6 Evidence assembler

Evidence assembler; source hash, command fingerprint, exit code, sayaç, süre,
stdout/stderr hashleri ve sanitized sonucu bir run manifestine bağlar. Raw
secret, gerçek kullanıcı içeriği ve broad UI hierarchy kabul etmez.

## 4. Operational truth

Run admission ve yürütme güvenliği sırası:

1. Local Git branch, HEAD, index/staging ve tracked worktree.
2. Local `master`, cached `origin/master` ve canlı remote GitHub `master` SHA.
3. Current GitHub Issue ve en son geçerli authorization.
4. Local task/result kayıtları.
5. Local Orchestrator append-only event store.
6. `.cse/state/project_state.json` finalized snapshot.
7. Dokümantasyon ve serbest metin durum iddiaları.

Bu sıra bilgi-türü bazlı kanonik kaynakları değiştirmez. Kalıcı ürün amacı
unified project source'ta, Git/Codex güvenliği project instructions'ta,
validation genişliği minimum sufficient validation protocol'de kalır.

### 4.1 Drift davranışı

- Local worktree gerçeği ile task iddiası çelişirse local Git kazanır ve run
  durur.
- Cached `origin/master` canlı remote SHA ile çelişirse `STATE_DRIFT` oluşur;
  otomatik fetch yapılmaz.
- Task/result current Issue yetkisini genişletemez.
- Event store geçmişi kanıtlar; güncel Git veya GitHub gerçeğini override
  edemez.
- `.cse/state` yalnız yayımlanmış/finalized safe point'tir; açık branch'i
  temsil etmek zorunda değildir.
- Dokümantasyon daha yüksek otoriteli kanıtla çelişirse ilerleme izni vermez.

### 4.2 Publication live-truth sınırı

Publication'ın güncel gerçeği canlı yürütme yüzeylerinden okunur:

- local branch, HEAD, index ve tracked worktree için local Git;
- remote branch ve commit için live remote Git;
- authorization ve completion evidence için GitHub Issue #285 yorumları;
- PR state, head/base ve review metadata'sı için GitHub PR #286.

Task ve result dosyaları bounded run'ların tarihsel/factual kaydıdır;
`CHANGELOG.md` teknik sözleşme değişikliklerini kaydeder. Bu yüzeyler live
publication state'ini mirror veya override etmez. Bilinen commit ve PR
kimlikleri yalnız stable tarihsel referans olarak tutulabilir.

## 5. Run manifesti

Asgari manifest alanları:

```json
{
  "schema_version": 1,
  "run_id": "example",
  "repository": "faliardic/chief-site-engineer",
  "issue": 285,
  "branch": "docs/issue-285-cse-orchestrator-o0-foundation",
  "base_sha": "eb85f0a2ea0901f0074887fe999e74b6ab4aed0f",
  "head_sha": "eb85f0a2ea0901f0074887fe999e74b6ab4aed0f",
  "authorization_comment_id": 5152282818,
  "approval_level": "CODE_CHANGE",
  "capability": "Code",
  "state": "CODEX_RUNNING",
  "blocker_code": null,
  "budgets": {
    "primary_used": 1,
    "primary_max": 1,
    "correction_used": 0,
    "correction_max": 1
  },
  "source_fingerprint": "sha256:example",
  "sanitized_evidence": []
}
```

Örnek değerler schema anlatımı içindir; runtime state değildir.

## 6. Repository dışı runtime kökü

Önerilen Windows kökü:

```text
%LOCALAPPDATA%\CSE-Orchestrator\
├── state\orchestrator.sqlite3
├── runs\
├── logs\
├── approvals\
├── evidence\
└── worktrees\metadata\
```

- `state`: event indexleri ve yeniden üretilebilir projection.
- `runs`: manifest ve lifecycle metadata.
- `logs`: sanitized command output ve hashler.
- `approvals`: fingerprint, consumption ve expiry metadata.
- `evidence`: veri-minimal doğrulama kanıtı.
- `worktrees`: yalnız temporary worktree kimliği ve provenance metadata.

Credential backend seçimi O0 sonrasında ayrı karar gerektirir. Secret plaintext
bu kökteki manifest/event/log/evidence içine de yazılamaz.

## 7. Local Orchestrator ve CI ayrımı

Local Orchestrator şunların sahibidir:

- run admission ve local source gerçeği;
- approval/capability/budget doğrulaması;
- local action provenance;
- minimum yeterli validation planı;
- sanitized local evidence;
- remote CI sonucunun salt-okunur parse edilmesi.

CI şunların sahibidir:

- pushed commit üzerinde bağımsız remote verification;
- mevcut `pytest.yml` kapsamındaki Python gate'i;
- yalnız açık release-critical yetkide mobile release gate;
- remote log ve artifact provenance.

Workflow dosyasının varlığı PASS kanıtı değildir. CI; local worktree admission,
Fatih approval'ı veya cihaz target kararının yerine geçmez. Orchestrator da
değişmeyen revision üzerinde geniş gate'i tekrar çalıştırmaz.

## 8. Mevcut altyapı geçişi

`scripts/cse_status.py` Git head/divergence ve explicit state finalization
davranışları için envanter kaynağıdır. Mevcut default komut ignored/untracked,
ZIP ve export alanlarını geniş taradığı için O1 olarak doğrudan kullanılamaz.
O1, güvenli tracked-only observer'ı explicit finalize write yolundan ayırır.

`scripts/release_gate.ps1` ile `scripts/validate_mobile_release.py`
release-critical doğrulamanın mevcut sahipleridir. O0 bu araçları değiştirmez,
çağırmaz veya yeniden uygulamaz.

## 9. O0 tamamlanma sınırı

O0 tamamlandığında:

- mimari sözleşme vardır;
- executable Orchestrator yoktur;
- runtime database oluşturulmamıştır;
- API key veya secret oluşturulmamıştır;
- GitHub, commit, build veya cihaz otomasyonu yoktur;
- production davranışı değişmemiştir.

## 10. O10 resumable workflow coordinator

O10, O1-O9 parçalarını silmeden veya action state modelini yeniden
yorumlamadan ayrı bir workflow projection altında birleştirir:

```text
machine authorization
→ controller/target/tool preflight
→ immutable workflow contract
→ append-only event admission/result
→ deterministic next stage
→ PASS/reuse | pause | decision | retry | unsafe block
→ clean target + publish provenance
→ COMPLETED
```

- `workflow_authorization.py`, Issue yorumundaki exact repository, Issue,
  controller revision, target checkpoint, allowlist, capability sequence,
  stage planı, budgets ve optional artifact/device/publish hedeflerini canonical
  SHA-256 fingerprint'e bağlar. Unknown alan, secret biçimi, expiry,
  supersession veya device serial/argv drift'i reddedilir.
- `workflow_store.py`, repository dışındaki immutable contract manifesti ile
  append-only hash-chain event ledger'ını tutar. Projection yalnız bu ledger'dan
  yeniden üretilir; stale/missing cache mutating resume sırasında ledger'dan
  güvenle onarılır, read-only verify ise cache tamper'ını bildirir.
- `workflow.py`, controller source checkout'unu target Git deposundan ve runtime
  kökünden ayırır. Aynı process içinde PASS sonrası sıradaki stage'e geçer;
  external blocker'da artifact'i koruyup pause eder; correction bütçesindeki
  resumable failure'a yeni attempt identity verir.
- Command evidence raw stream taşımaz. Stage, family, argv hash, command index,
  exit, duration, timeout/truncation, stdout/stderr hash, stable reason ve ilk
  başarısız predicate saklanır.
- Commit, push, Draft PR ve Issue evidence önce mevcut exact sonucu arar.
  Exact eşleşme reuse, farklı sonuç provenance blocker'ıdır; ikinci mutation
  yapılmaz.

Controller checkout, target repository ve runtime root üç farklı resolved
path'tir. CLI'daki controller root ayrıca çalışan package'ın gerçek source
root'una eşit olmalıdır. Böylece başka bir temiz Git deposunun revision'ı,
değiştirilmiş controller kodunun provenance'i olarak gösterilemez.

O10 merge veya release yetkisi vermez. Product/mobile ve fiziksel cihaz action'ı
yalnız current machine authorization exact stage/capability/target sınırında
çalışabilir.
