# CSE Development Orchestrator Durum Makinesi

## 1. Sözleşme amacı

Bu belge bir CSE geliştirme run'ının gözlemden tamamlanmaya kadar hangi
durumlarda bulunabileceğini, geçişlerin hangi kanıtları istediğini ve hangi
koşullarda fail-closed durduğunu tanımlar. O0'da executable engine yoktur.

## 2. Durumlar

| Durum | Anlam |
| --- | --- |
| `IDLE` | Aktif run yoktur. |
| `OBSERVING` | Local Git, remote ve Issue gerçeği salt okunur toplanır. |
| `PREFLIGHT_BLOCKED` | Run başlamadan zorunlu invariant doğrulanamamıştır. |
| `SCOPE_VALIDATED` | Base, scope, allowlist, bütçe ve profile tutarlıdır. |
| `AWAITING_APPROVAL` | `pending_action`, gerekli approval, resume state ve fingerprint bağlarıyla Fatih yetkisi beklenir. |
| `CODEX_AUTHORIZED` | Yalnız bounded Codex `CODE_CHANGE` veya `CORRECTION` action'ı için tek kullanımlık yetki geçerlidir. |
| `ACTION_AUTHORIZED` | Codex dışı tek bir mutable/maliyetli action için generic, tek kullanımlık yetki geçerlidir. |
| `CODEX_RUNNING` | Yetkili Codex action'ı kabul edilip başlamıştır. |
| `ACTION_RUNNING` | Codex dışındaki yetkili mutable/maliyetli action admission sonrasında gerçekten başlamıştır. |
| `RESULT_RECEIVED` | Action sonucu ve provenance alınmıştır. |
| `DETERMINISTIC_VALIDATION` | Sonuç allowlist, source, parser ve gate kurallarıyla doğrulanır. |
| `FOCUSED_PASS` | Değişen sözleşmenin dar doğrulaması geçmiştir. |
| `FULL_PASS` | Issue'nun zorunlu tuttuğu geniş gate geçmiştir. |
| `SOURCE_VALIDATED` | Canonical ve validation source/tree eşitliği kanıtlanmıştır. |
| `CHECKPOINT_COMMITTED` | Ayrı approval ile ordinary local checkpoint oluşmuştur. |
| `ARTIFACT_BUILT` | Yetkili source'tan exact artifact üretilmiştir. |
| `DEVICE_ACCEPTANCE` | Yetkili cihaz/sentetik kullanıcı yolu kabulü geçmiştir. |
| `PUBLISH_READY` | Publish prerequisites tamamdır; publish henüz yapılmamıştır. |
| `BLOCKED` | External prerequisite veya insan kararı olmadan run ilerleyemez. |
| `FAILED` | Yetkili action doğrulanmış teknik/ürün failure'ı üretmiştir. |
| `CANCELLED` | Fatih run'ı iptal etmiş veya scope'u supersede etmiştir. |
| `COMPLETED` | Bounded run amacı ve zorunlu evidence tamamlanmıştır; merge veya release kararı değildir. |

`PREFLIGHT_BLOCKED` ve `BLOCKED` yalnız process durumudur. Ürün kaydı, resmî
karar veya kullanıcı verisi statüsü üretmez; tarihsel “sistem kendiliğinden
blocked kararı üretmez” güvenlik sınırını zayıflatmaz.

## 3. Normal geçiş yolu

```text
IDLE
→ OBSERVING
→ SCOPE_VALIDATED
→ AWAITING_APPROVAL [CODE_CHANGE veya CORRECTION]
→ CODEX_AUTHORIZED
→ CODEX_RUNNING
→ RESULT_RECEIVED
→ DETERMINISTIC_VALIDATION
→ FOCUSED_PASS
→ AWAITING_APPROVAL [FULL_VALIDATION]
→ ACTION_AUTHORIZED
→ ACTION_RUNNING
→ RESULT_RECEIVED
→ DETERMINISTIC_VALIDATION
→ FULL_PASS
→ SOURCE_VALIDATED
→ AWAITING_APPROVAL [CHECKPOINT_COMMIT]
→ ACTION_AUTHORIZED
→ ACTION_RUNNING
→ RESULT_RECEIVED
→ DETERMINISTIC_VALIDATION
→ CHECKPOINT_COMMITTED
→ AWAITING_APPROVAL [BUILD]
→ ACTION_AUTHORIZED
→ ACTION_RUNNING
→ RESULT_RECEIVED
→ DETERMINISTIC_VALIDATION
→ ARTIFACT_BUILT
→ AWAITING_APPROVAL [DEVICE]
→ ACTION_AUTHORIZED
→ ACTION_RUNNING
→ RESULT_RECEIVED
→ DETERMINISTIC_VALIDATION
→ DEVICE_ACCEPTANCE
→ PUBLISH_READY
→ AWAITING_APPROVAL [PUBLISH]
→ ACTION_AUTHORIZED
→ ACTION_RUNNING
→ RESULT_RECEIVED
→ DETERMINISTIC_VALIDATION
→ COMPLETED
```

Her run bütün optional durumlara uğramaz. `FULL_VALIDATION`, build, device veya
publish atlanacaksa manifestte explicit `not_required` ya da geçerli
`reused_evidence` gerekçesi ve source revision tutulur. Sessiz skip geçerli
değildir.
## 4. Geçiş tablosu

| Kaynak | Hedef | Zorunlu kanıt |
| --- | --- | --- |
| `IDLE` | `OBSERVING` | Benzersiz run ID ve `SAFE_READ` sınırı |
| `OBSERVING` | `SCOPE_VALIDATED` | Operational truth uyumu, exact base, temiz admission state, geçerli Issue/scope |
| `OBSERVING` | `PREFLIGHT_BLOCKED` | Failed invariant ve standart blocker kodu |
| `SCOPE_VALIDATED` | `AWAITING_APPROVAL` | Codex action'ı için `pending_action`, `required_approval_level`, `resume_state`, `expected_success_state=FOCUSED_PASS`, capability ve source/action fingerprint taslağı |
| `FOCUSED_PASS` | `AWAITING_APPROVAL` | `pending_action=FULL_VALIDATION`, `required_approval_level=FULL_VALIDATION`, `resume_state=FOCUSED_PASS`, `expected_success_state=FULL_PASS` ve source/action fingerprint'leri |
| `SOURCE_VALIDATED` | `AWAITING_APPROVAL` | `pending_action=CHECKPOINT_COMMIT`, `required_approval_level=CHECKPOINT_COMMIT`, `resume_state=SOURCE_VALIDATED`, `expected_success_state=CHECKPOINT_COMMITTED` ve source/action fingerprint'leri |
| `CHECKPOINT_COMMITTED` | `AWAITING_APPROVAL` | `pending_action=BUILD`, `required_approval_level=BUILD`, `resume_state=CHECKPOINT_COMMITTED`, `expected_success_state=ARTIFACT_BUILT` ve checkpoint/action fingerprint'leri |
| `ARTIFACT_BUILT` | `AWAITING_APPROVAL` | `pending_action=DEVICE`, `required_approval_level=DEVICE`, `resume_state=ARTIFACT_BUILT`, `expected_success_state=DEVICE_ACCEPTANCE` ve artifact/target/action fingerprint'leri |
| `PUBLISH_READY` | `AWAITING_APPROVAL` | `pending_action=PUBLISH`, `required_approval_level=PUBLISH`, `resume_state=PUBLISH_READY`, `expected_success_state=COMPLETED` ve branch/commit/remote action fingerprint'leri |
| `AWAITING_APPROVAL` | `CODEX_AUTHORIZED` | `pending_action` bounded Codex action'ıdır; approval level `CODE_CHANGE` veya `CORRECTION`dır; one-time approval geçerli ve tüketilmemiştir |
| `AWAITING_APPROVAL` | `ACTION_AUTHORIZED` | `pending_action` Codex dışıdır; required level, expected success state ve exact action'a bağlı one-time approval geçerli ve tüketilmemiştir |
| `CODEX_AUTHORIZED` | `CODEX_RUNNING` | Codex invocation gerçekten başlarken approval consumption, budget admission ve invocation-start provenance tek append-only admission event'inde kaydedilir |
| `ACTION_AUTHORIZED` | `ACTION_RUNNING` | `FULL_VALIDATION`, `CHECKPOINT_COMMIT`, `BUILD`, `DEVICE` veya `PUBLISH` invocation'ı gerçekten başlarken approval consumption, budget admission ve invocation-start provenance tek append-only admission event'inde kaydedilir |
| `CODEX_RUNNING` | `RESULT_RECEIVED` | Exit code/result, duration ve sanitized stdout/stderr hashleri |
| `ACTION_RUNNING` | `RESULT_RECEIVED` | Exit code/result, duration ve sanitized stdout/stderr hashleri |
| `RESULT_RECEIVED` | `DETERMINISTIC_VALIDATION` | Parse edilebilir sanitized result; `pending_action`, `expected_success_state`, fingerprint ve admission-event bağları korunmuştur |
| `DETERMINISTIC_VALIDATION` | `FOCUSED_PASS` | `pending_action` `CODE_CHANGE` veya `CORRECTION`; focused gate PASS |
| `DETERMINISTIC_VALIDATION` | `FULL_PASS` | `pending_action=FULL_VALIDATION`; ayrı full gate PASS |
| `DETERMINISTIC_VALIDATION` | `CHECKPOINT_COMMITTED` | `pending_action=CHECKPOINT_COMMIT`; ordinary commit, parent/subject ve exact staged allowlist doğrulanmıştır |
| `DETERMINISTIC_VALIDATION` | `ARTIFACT_BUILT` | `pending_action=BUILD`; artifact exact checkpoint ve build provenance'ına bağlanmıştır |
| `DETERMINISTIC_VALIDATION` | `DEVICE_ACCEPTANCE` | `pending_action=DEVICE`; exact target'taki veri-minimal acceptance sonucu doğrulanmıştır |
| `DETERMINISTIC_VALIDATION` | `COMPLETED` | `pending_action=PUBLISH`; bounded publish sonucu ve completion evidence doğrulanmıştır |
| `DETERMINISTIC_VALIDATION` | `FAILED` | Doğrulanmış source/test/analyze/action failure'ı |
| `DETERMINISTIC_VALIDATION` | `BLOCKED` | Toolchain, harness, provenance veya external blocker |
| `FOCUSED_PASS` | `SOURCE_VALIDATED` | Full gate explicit `not_required` veya geçerli reused evidence |
| `FULL_PASS` | `SOURCE_VALIDATED` | Source/tree eşitliği ve post-gate drift `0` |
| `CHECKPOINT_COMMITTED` | `PUBLISH_READY` | Build ve device explicit `not_required` veya geçerli reused evidence; action çalıştırılmamıştır |
| `ARTIFACT_BUILT` | `PUBLISH_READY` | Device explicit `not_required` veya geçerli reused evidence; action çalıştırılmamıştır |
| `DEVICE_ACCEPTANCE` | `PUBLISH_READY` | Completion evidence ve publish prerequisites |
| `PUBLISH_READY` | `COMPLETED` | Publish bu run için explicit `not_required`; Git/GitHub mutation olmadan bounded run tamamlanmıştır |

Her non-terminal durum `CANCELLED` durumuna geçebilir. External prerequisite
kaybı `BLOCKED`, doğrulanmış action failure'ı `FAILED` üretir. Terminal durumdan
devam etmek yeni run ve yeni authorization gerektirir.
## 5. Entry ve exit invariant'ları

### 5.1 `OBSERVING`

Entry:

- process read-only profile'dadır;
- repository ve GitHub write capability yoktur;
- protected/ignored kullanıcı alanı enumerate edilmez.

Exit:

- bütün observation alanları kaynak ve timestamp taşır;
- cached ve canlı remote ayrımı açıktır;
- belirsiz değer PASS'e çevrilmez.

### 5.2 `SCOPE_VALIDATED`

Entry:

- current Issue ve latest-valid authorization belirlenmiştir;
- exact branch/base/head/tree ve allowlist tutarlıdır;
- validation class, reused evidence ve bütçeler tanımlıdır.

Exit:

- action, capability ve approval level tek anlamlıdır;
- scope dışı ihtiyaç yoktur.

### 5.3 `AWAITING_APPROVAL`

Entry:

- `pending_action`, `required_approval_level` ve `expected_success_state` tek
  anlamlıdır;
- `resume_state`, approval istenen son doğrulanmış state'i gösterir;
- source fingerprint ve action fingerprint current branch, HEAD/tree, scope,
  capability, target ve budget ile bağlıdır.

Exit:

- yalnız `CODE_CHANGE` veya `CORRECTION` Codex action'ı
  `CODEX_AUTHORIZED`a geçer;
- diğer mutable/maliyetli action'lar `ACTION_AUTHORIZED`a geçer;
- bekleme durumu approval'ı tüketmez; drift yeni observation ve approval ister.

### 5.4 `CODEX_AUTHORIZED`

Entry:

- fingerprint current source ile eşleşir;
- approval tüketilmemiş ve süresi dolmamıştır;
- pending action bounded Codex `CODE_CHANGE` veya `CORRECTION`dır;
- expected success state `FOCUSED_PASS` ve budget yeterlidir.

Exit:

- invocation gerçekten başlarken admission event'i append-only yazılmıştır;
- approval consumption, budget admission ve invocation-start provenance aynı
  eventte atomik olarak uygulanmıştır.

### 5.5 `ACTION_AUTHORIZED`

Entry:

- pending action Codex dışındaki exact mutable/maliyetli action'dır;
- required approval level ve expected success state action ile exact eşleşir;
- approval tüketilmemiştir; source/action fingerprint'leri ve budget geçerlidir.

Exit:

- yalnız exact action runner'ına geçişe izin verir;
- bu state tek başına approval tüketimi, invocation veya success sonucu değildir;
- başka capability veya sonraki action için authorization devredilemez.

### 5.6 `ACTION_RUNNING`

Entry:

- `pending_action`; `FULL_VALIDATION`, `CHECKPOINT_COMMIT`, `BUILD`, `DEVICE`
  veya `PUBLISH` değerlerinden exact biridir;
- `required_approval_level`, `resume_state`, `expected_success_state`,
  source/action fingerprint ve admission event bağı korunmuştur;
- action'ın gerçekten başladığı invocation-start provenance ile kanıtlanmıştır;
- approval consumption, budget admission ve invocation-start provenance aynı
  append-only admission event'inde atomik olarak kaydedilmiştir.

Exit:

- yalnız `RESULT_RECEIVED`a geçilir;
- wrapper action'ı başlatmadıysa bu state'e girildiği veya approval/invocation
  tüketildiği tahmin edilmez.

### 5.7 `RESULT_RECEIVED`

Entry:

- exit code/result, duration ve sanitized stdout/stderr hashleri kayıtlıdır;
- `pending_action`, `expected_success_state`, source/action fingerprint'leri ve
  admission event bağı korunmuştur.

Exit:

- yalnız schema-valid sanitized result `DETERMINISTIC_VALIDATION`a geçer.

### 5.8 `DETERMINISTIC_VALIDATION`

Entry:

- action gerçekten başladı mı bilgisi provenance ile sabittir;
- result parser output'u schema-valid'dir;
- source drift kontrol edilmiştir;
- `pending_action` ile `expected_success_state` eşleşmesi doğrulanmıştır.

Exit:

- `pending_action`a göre PASS sonucu `FOCUSED_PASS`, `FULL_PASS`,
  `CHECKPOINT_COMMITTED`, `ARTIFACT_BUILT`, `DEVICE_ACCEPTANCE` veya
  `COMPLETED` olur;
- doğrulanmış action failure `FAILED`; toolchain, harness, provenance veya
  external prerequisite `BLOCKED` olur;
- consumed budget ve exact failed stage kaydedilmiştir.

### 5.9 `COMPLETED`

Entry:

- Issue'nun zorunlu bütün gate'leri PASS, `not_required` veya geçerli reused
  evidence durumundadır;
- unauthorized action yoktur;
- final evidence veri-minimaldir;
- run'ın bounded amacı tamamlanmıştır.

`COMPLETED` yalnız bu run'ın sonucudur. PR'ı Ready yapma, merge, Issue close,
branch delete veya release kararı üretmez; bunların her biri Fatih'in ayrı exact
approval'ını ve gerekiyorsa ayrı run'ı ister. Exit yoktur. Yeni iş yeni run'dır.
## 6. Bütçe alanları

```json
{
  "primary_used": 1,
  "primary_max": 1,
  "correction_used": 0,
  "correction_max": 1,
  "same_operation_retry_used": 0,
  "same_operation_retry_max": 1,
  "full_gate_revision": null,
  "build_used": 0,
  "build_max": 0,
  "install_used": 0,
  "install_max": 0,
  "device_used": 0,
  "device_max": 0,
  "elapsed_seconds": 0,
  "target_seconds": 1500,
  "hard_stop_seconds": 2700,
  "failed_stage": null,
  "last_exact_correction": null,
  "budget_extension_authorization": null
}
```

Kurallar:

- Sayaç action başlamadan kontrol edilir ve admission event'iyle artırılır.
- Parser/tool wrapper action'ı başlatmadıysa invocation tüketimi tahmin edilmez.
- Aynı failure yalnız exact correction sonrasında bir kez tekrar edilir.
- Yeni yorum açıkça genişletmedikçe sayaçlar sıfırlanmaz.
- Aynı source revision üzerinde aynı full gate ikinci kez çalıştırılmaz.
- Toolchain failure bütün zinciri değil yalnız failed stage'i etkiler.
- Hard stop yeni solution chain veya geniş gate admission'ını reddeder.

## 7. Blocker kodları

| Kod | Kullanım |
| --- | --- |
| `SOURCE_FAILURE` | Gerekli source okunamıyor veya içerik doğrulanamıyor. |
| `TEST_FAILURE` | Yetkili test davranış failure'ı gösteriyor. |
| `ANALYZE_FAILURE` | Yetkili analyze gate başarısız. |
| `SCOPE_DRIFT` | Issue, task, action veya diff scope dışına çıktı. |
| `STATE_DRIFT` | Local/cached/remote/task/state gerçekleri çelişiyor. |
| `ALLOWLIST_VIOLATION` | Read/write/action hedefi allowlist dışında. |
| `RETRY_BUDGET_EXHAUSTED` | Yetkili retry/correction kalmadı. |
| `TIME_BUDGET_EXHAUSTED` | Hard stop aşıldı. |
| `TOOLCHAIN_FAILURE` | SDK, runner veya environment action'ı engelledi. |
| `AUTOMATION_HARNESS_FAILURE` | Harness product sonucu üretemedi. |
| `DEVICE_UNAVAILABLE` | Exact cihaz target hazır değil. |
| `DEVICE_UI_TARGET_NOT_FOUND` | Exact sentetik UI target güvenle bulunamadı. |
| `USER_DATA_RISK` | Devam gerçek kullanıcı verisi riski doğuruyor. |
| `APPROVAL_EXPIRED` | Fingerprint drift, expiry veya consumption oluştu. |
| `PROVENANCE_MISMATCH` | Source, tree, artifact veya result bağı uyuşmuyor. |

Blocker event'i; failed invariant, exact observation, source fingerprint,
consumed budget, reused evidence, yasak sonraki action ve Fatih'ten gereken tek
kararı taşır.

## 8. Append-only transition event örneği

```json
{
  "schema_version": 1,
  "event_id": "sha256:example",
  "run_id": "o4-replay-example",
  "sequence": 12,
  "event_type": "state_transition",
  "state_from": "DETERMINISTIC_VALIDATION",
  "state_to": "BLOCKED",
  "blocker_code": "AUTOMATION_HARNESS_FAILURE",
  "authorization_comment_id": 5152282818,
  "source_fingerprint": "sha256:example-source",
  "budget_snapshot": {
    "primary_used": 1,
    "correction_used": 0
  },
  "sanitized_evidence_hash": "sha256:example-evidence"
}
```

Event kimliği, payload'ın canonical serialization'ından türetilir. Aynı event
ID ile farklı payload kabul edilmez; replay idempotent kalır.

## 9. Evidence reuse

Evidence yalnız şu durumda yeniden kullanılabilir:

- doğruladığı contract değişmemiştir;
- source/blob/tree fingerprint eşleşir;
- gate sonucu ve kapsamı açıktır;
- environment bağı sonucu geçersiz kılmıyordur;
- current Issue reuse'a izin verir.

Reuse yeni PASS üretmez; önceki PASS'in current run'a neden taşınabildiğini
kanıtlar.
