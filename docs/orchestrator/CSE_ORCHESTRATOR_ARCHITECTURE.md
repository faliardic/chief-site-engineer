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

O0 ilk docs koşusu geçiş dönemi insan-okur yorumuyla yetkilidir. Future
machine-readable schema O1 ve sonraki fazlarda uygulanır.

### 3.5 Capability runner

Capability runner gelecekte yalnız policy engine tarafından kabul edilmiş tek
profile ve exact action fingerprint'i çalıştırabilir. Her profile ayrı process,
environment, readable-path ve writable-path sınırı gerekir.

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
