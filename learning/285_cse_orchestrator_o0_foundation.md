# Issue #285 — CSE Development Orchestrator O0 Temeli

## Ne yaptık?

CSE'nin bugüne kadar GitHub Issue ve doğal dil execution yorumlarıyla uyguladığı
güvenli geliştirme disiplinini, gelecekte makine tarafından doğrulanabilecek beş
belgeye ayırdık:

- mimari;
- durum makinesi;
- güvenlik sınırı;
- approval modeli;
- O0–O10 MVP planı.

Bu çalışmada Orchestrator kodu yazılmadı. API, Codex child execution, test,
build, cihaz veya GitHub write automation başlatılmadı.

## Gerçek repository yapısı

O0 tasarımı soyut bir otomasyon varsayımından değil mevcut CSE yapılarına göre
çıkarıldı.

### Kanonik protokoller

- `CSE_UNIFIED_PROJECT_SOURCE.md`: kalıcı ürün amacı ve strateji.
- `CSE_PROJECT_INSTRUCTIONS.md`: Git, Codex ve execution güvenliği.
- `CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md`: validation class, evidence
  reuse, retry ve süre bütçeleri.
- `CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md`: GitHub-native continuation.
- `CSE_PROJECT_SOURCE_REGISTER.md`: kaynak rolleri ve erişim durumu.

Bu belgeler tek bir “en güçlü dosya” sırası oluşturmaz. Her bilgi türünün kendi
otoritesi vardır. Orchestrator operational truth sırası yalnız run admission
içindir.

### `.cse` katmanı

- `.cse/tasks/`: current Issue scope ve yürütme kaydı.
- `.cse/results/`: factual sonuç ve completion evidence.
- `.cse/state/project_state.json`: yalnız son merged/finalized snapshot.

Önemli sonuç: `.cse/state` açık branch veya en yeni GitHub yorumunun yerine
geçemez. Issue #284 branch'i açıkken state dosyasının daha eski safe point'i
göstermesi bu ayrımı gerçek repository üzerinde kanıtlar.

### Mevcut status aracı

`scripts/cse_status.py` şu faydalı yapı taşlarını gösterir:

- branch ve HEAD okuma;
- `origin/master...HEAD` divergence;
- staged ve tracked diff;
- explicit `--finalize-state` yolu.

Ancak default status akışı ignored/untracked yolları, ZIP'leri ve `exports/`
içeriğini geniş biçimde enumerate eder. O1 gerçek kullanıcı alanlarını korumak
için bu script'i doğrudan çalıştırmayacak; tracked-only observer ile explicit
finalize write yolunu ayıracaktır.

### Existing CI ve release gate

- `.github/workflows/pytest.yml`: pushed revision üzerinde Python verification.
- `.github/workflows/mobile_release_gate.yml`: explicit release-critical gate.
- `scripts/release_gate.ps1`: build, artifact ve opsiyonel device/release
  zinciri.
- `scripts/validate_mobile_release.py`: fail-closed static/artifact kontrolleri.

Orchestrator bu görevleri yeniden yazmayacak. Local admission ve approval
Orchestrator'ın; pushed commit verification CI'ın sorumluluğudur.

## Gerçek çalışma akışı

Issue #285 O0 docs koşusu aşağıdaki sırayı kullandı:

```text
Issue #284 freeze preflight
→ canonical source pre-read
→ Issue #285 ve execution comment doğrulaması
→ hedef branch local/remote yokluk kontrolü
→ exact master'dan docs branch
→ task kaydı
→ beş O0 belgesi
→ roadmap/changelog/decision/source-register hizalaması
→ result kaydı
→ docs-only deterministic kalite kontrolü
→ staging/commit/push/PR olmadan stop
```

Başlangıç gerçekleri:

```text
frozen branch: codex/issue-284-reminder-all-day-edit
frozen checkpoint: b0e9cf247afa6bac5d38684dbc626a11fdf45663
checkpoint parent: eb85f0a2ea0901f0074887fe999e74b6ab4aed0f
master/origin/remote: eb85f0a2ea0901f0074887fe999e74b6ab4aed0f
divergence: 0 1
staging: empty
tracked worktree: clean
```

Yeni branch exact `master` SHA'dan açıldı; Issue #284 branch pointer'ı
değiştirilmedi.

## Operational truth neden bu sırada?

```text
Local Git
→ local/cached/live master
→ current Issue + latest-valid authorization
→ task/result
→ append-only event store
→ finalized .cse/state snapshot
→ docs iddiaları
```

- Local Git, gerçekten hangi dosyada ve index durumunda çalışıldığını söyler.
- Canlı GitHub SHA upstream gerçeğidir; cached ref eski olabilir.
- Current Issue ve yorum action scope'unu belirler.
- Task/result bu yetkiyi kaydeder fakat genişletemez.
- Event store geçmiş observation ve transition'ları kanıtlar.
- `.cse/state` yalnız yayımlanmış checkpoint'tir.
- Serbest metin daha yüksek otoriteli kanıtı override edemez.

Çelişki otomatik fetch/reset/stash/clean ile “düzeltilmez”; fail-closed durulur.

## Machine-readable run örneği

```json
{
  "schema_version": 1,
  "run_id": "issue-285-o0-docs",
  "issue": 285,
  "authorization_comment_id": 5152282818,
  "branch": "docs/issue-285-cse-orchestrator-o0-foundation",
  "base_sha": "eb85f0a2ea0901f0074887fe999e74b6ab4aed0f",
  "state": "CODEX_RUNNING",
  "capability": "Code",
  "approval_level": "CODE_CHANGE",
  "budgets": {
    "primary_used": 1,
    "primary_max": 1,
    "correction_used": 0,
    "correction_max": 1,
    "target_seconds": 1500,
    "hard_stop_seconds": 2700
  },
  "user_data_access": false,
  "api_key_created": false
}
```

Bu JSON bir runtime dosyası değildir; O1/O2 için sözleşme örneğidir.

## Approval fingerprint örneği

Approval yalnız “tamam, devam et” metni değildir. Şunlara bağlanır:

```text
repository + issue + comment ID + canonical comment hash
+ branch + base/head/tree
+ scope version + capability + action fingerprint
+ allowlist + target + budget + expiry + nonce + previous state
```

Bu girdilerden biri değişirse eski approval sona erer. Önceki test PASS'i yeni
commit/build/device/publish izni değildir.

## State ayrımları

### `PREFLIGHT_BLOCKED`

Action başlamadan önce source, scope veya admission gerçeği doğrulanamadı.

### `BLOCKED`

Run başladıktan sonra external prerequisite, harness, toolchain veya insan
kararı olmadan ilerlenemiyor.

### `FAILED`

Yetkili action gerçek ve doğrulanmış başarısız sonuç üretti.

Bu durumlar ürün kaydına “blocked” yazmaz ve Fatih adına resmî karar vermez.
Yalnız Orchestrator process durumudur.

## Budget neden state'in parçası?

Issue #284 geçmişi aynı feature üzerinde çok sayıda bounded continuation ve
correction içerir. Hangi çağrının gerçekten başladığı, hangi retry'ın açıkça
yetkilendirildiği ve hangi frozen kanıtın yeniden kullanıldığı bilinmeden doğru
sonuç üretilemez.

Bu nedenle budget yalnız metin değildir:

```json
{
  "primary_used": 1,
  "correction_used": 0,
  "same_operation_retry_used": 0,
  "failed_stage": null,
  "last_exact_correction": null,
  "budget_extension_authorization": null
}
```

Sayaç action admission'ında artar. Wrapper parse aşamasında durduysa actual
invocation provenance olmadan tahmin edilmez.

## Issue #284 neden iyi bir O4 fixture?

#284 şu olayları gerçek ve zengin bir sırada taşır:

- exact başlangıç source/scope;
- expected test-first failure;
- product failure ile harness failure ayrımı;
- timeout ve invocation belirsizliği;
- correction budget'ları;
- daha yeni yorumla supersede edilen dar yetkiler;
- focused/full evidence reuse;
- source-validated checkpoint;
- build/device için ayrı approval;
- bounded UI continuation ve user-data koruması.

O4 yalnız comment ID, state, hash, budget, result class ve blocker kodu gibi
sanitized metadata kullanır. Gerçek kullanıcı içeriği, device backup'ı, raw UI
dump veya app-private veri fixture'a alınmaz.

## OpenAI API neden O9'dan önce yok?

O0–O4 sistemin deterministik oracle'ıdır:

- O1 ne olduğunu gözler.
- O2 neye izin verildiğini hesaplar.
- O3 sonucun ne anlama geldiğini parse eder.
- O4 geçmişi aynı kurallarla replay eder.

Bu katmanlar güvenilir değilken AI eklemek nondeterminism, secret, ağ, maliyet
ve provenance riskini güvenlik temelinin içine taşır. O9 planner öneri
üretebilir; policy engine'in son otoritesini alamaz.

## Validation amacı

Bu Issue docs class olduğu için test/build/device gate'i çalıştırılmadı. Yapılan
kontroller yalnız değişen contract'a yöneliktir:

- exact 12-path allowlist;
- zorunlu dosya varlığı;
- whitespace/final newline;
- Markdown heading, code fence ve local link;
- conflict marker;
- production/mobile/test/workflow diff `0`;
- protokol/script/state diff `0`;
- staging boş.

Bu dar validation, güvenlik kapısını azaltmaz; değişmeyen production
sözleşmeleri için gereksiz full gate üretmez.

## Teknik kararlar

- Runtime state repository dışında `%LOCALAPPDATA%\CSE-Orchestrator\` altında
  tasarlanır.
- Event source append-only, projection yeniden üretilebilir olur.
- Code, Device ve Publish ambient permission paylaşmaz.
- Human-readable O0 auth geçiş istisnasıdır; O1+ machine-readable schema ister.
- `.cse/state` açık work authority değil, finalized snapshot'tır.
- Existing status/release araçları otomatik Orchestrator action'ı sayılmaz.
- API ve secret O9'dan önce yoktur.

## Açık karar kapıları

- Future credential backend ve Windows güvenli saklama yöntemi.
- Runtime event retention ve exact cleanup lifecycle'ı.
- O1 observer'ın repository içi modül/CLI konumu.
- Machine-readable authorization'ın exact serialization standardı.
- O10 tray/service/self-hosted runner gerekip gerekmediği.

Bu noktalar O0'da tahminle implementation kararına çevrilmedi.

## Şunu şöyle yaptık ki...

- Operational truth'u bilgi türlerine ayırdık ki `.cse/state` veya docs gerçeği
  güncel Git/GitHub kanıtını sessizce override etmesin.
- Approval'ı source ve action fingerprint'ine bağladık ki eski bir “devam et”
  yorumu yeni branch, target veya bütçeye taşınmasın.
- Capability'leri ayırdık ki kod yazabilen process cihaz veya publish yetkisini
  ambient olarak edinmesin.
- Budget sayaçlarını event yaptık ki timeout, retry ve correction geçmişi
  yorumdan yoruma kaybolmasın.
- O1'de broad ignored/untracked taramayı yasakladık ki güvenli preflight gerçek
  kullanıcı dosyalarını görünür hâle getirmesin.
- OpenAI API'yi O9'a bıraktık ki önce deterministik observer, policy, parser ve
  replay zinciri kanıtlanabilsin.
- O0'ı docs-only tuttuk ki yeni güvenlik sistemi mevcut production davranışını
  değiştirmeden önce incelemeye açık ve geri alınabilir olsun.
