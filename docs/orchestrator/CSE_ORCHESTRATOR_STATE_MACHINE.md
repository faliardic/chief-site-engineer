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
| `AWAITING_APPROVAL` | Sonraki mutable/maliyetli action için Fatih yetkisi beklenir. |
| `CODEX_AUTHORIZED` | Exact source ve action için tek kullanımlık yetki geçerlidir. |
| `CODEX_RUNNING` | Yetkili Codex action'ı kabul edilip başlamıştır. |
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
| `COMPLETED` | Yetkili amaç ve zorunlu evidence tamamlanmıştır. |

`PREFLIGHT_BLOCKED` ve `BLOCKED` yalnız process durumudur. Ürün kaydı, resmî
karar veya kullanıcı verisi statüsü üretmez; tarihsel “sistem kendiliğinden
blocked kararı üretmez” güvenlik sınırını zayıflatmaz.

## 3. Normal geçiş yolu

```text
IDLE
→ OBSERVING
→ SCOPE_VALIDATED
→ AWAITING_APPROVAL
→ CODEX_AUTHORIZED
→ CODEX_RUNNING
→ RESULT_RECEIVED
→ DETERMINISTIC_VALIDATION
→ FOCUSED_PASS
→ FULL_PASS
→ SOURCE_VALIDATED
→ CHECKPOINT_COMMITTED
→ ARTIFACT_BUILT
→ DEVICE_ACCEPTANCE
→ PUBLISH_READY
→ COMPLETED
```

Her run bütün optional durumlara uğramaz. Atlanan gate manifestte
`not_required` veya `reused_evidence` gerekçesi ve source revision ile tutulur.
Sessiz skip geçerli değildir.

## 4. Geçiş tablosu

| Kaynak | Hedef | Zorunlu kanıt |
| --- | --- | --- |
| `IDLE` | `OBSERVING` | Benzersiz run ID ve `SAFE_READ` sınırı |
| `OBSERVING` | `SCOPE_VALIDATED` | Operational truth uyumu, exact base, temiz admission state, geçerli Issue/scope |
| `OBSERVING` | `PREFLIGHT_BLOCKED` | Failed invariant ve standart blocker kodu |
| `SCOPE_VALIDATED` | `AWAITING_APPROVAL` | Sonraki action, profile ve fingerprint taslağı |
| `AWAITING_APPROVAL` | `CODEX_AUTHORIZED` | Geçerli, tüketilmemiş, source'a bağlı approval |
| `CODEX_AUTHORIZED` | `CODEX_RUNNING` | Budget admission event'i ve exact action fingerprint |
| `CODEX_RUNNING` | `RESULT_RECEIVED` | Exit/result, elapsed time ve provenance |
| `RESULT_RECEIVED` | `DETERMINISTIC_VALIDATION` | Parse edilebilir sanitized result |
| `DETERMINISTIC_VALIDATION` | `FOCUSED_PASS` | Değişen sözleşmenin focused gate PASS'i |
| `DETERMINISTIC_VALIDATION` | `FAILED` | Doğrulanmış source/test/analyze/action failure'ı |
| `DETERMINISTIC_VALIDATION` | `BLOCKED` | Toolchain, harness, provenance veya external blocker |
| `FOCUSED_PASS` | `FULL_PASS` | Issue'nun zorunlu tuttuğu full gate PASS'i |
| `FOCUSED_PASS` | `SOURCE_VALIDATED` | Full gate `not_required` veya geçerli reused evidence |
| `FULL_PASS` | `SOURCE_VALIDATED` | Source/tree eşitliği ve post-gate drift `0` |
| `SOURCE_VALIDATED` | `AWAITING_APPROVAL` | Commit/build/device gibi yeni action için ayrı approval ihtiyacı |
| `SOURCE_VALIDATED` | `CHECKPOINT_COMMITTED` | `CHECKPOINT_COMMIT` approval ve exact staged allowlist |
| `CHECKPOINT_COMMITTED` | `ARTIFACT_BUILT` | `BUILD` approval ve artifact provenance |
| `ARTIFACT_BUILT` | `DEVICE_ACCEPTANCE` | `DEVICE` approval, exact target ve veri-minimal PASS |
| `DEVICE_ACCEPTANCE` | `PUBLISH_READY` | Completion evidence ve publish prerequisites |
| `PUBLISH_READY` | `COMPLETED` | Issue kapsamındaki son yetkili action tamamlandı |

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

### 5.3 `CODEX_AUTHORIZED`

Entry:

- fingerprint current source ile eşleşir;
- approval tüketilmemiş ve süresi dolmamıştır;
- budget yeterlidir.

Exit:

- admission event'i append-only yazılmıştır;
- approval tüketim kuralı atomik olarak uygulanmıştır.

### 5.4 `DETERMINISTIC_VALIDATION`

Entry:

- action gerçekten başladı mı bilgisi provenance ile sabittir;
- result parser output'u schema-valid'dir;
- source drift kontrol edilmiştir.

Exit:

- PASS, FAILED veya BLOCKED sınıfı tahminsizdir;
- consumed budget ve exact failed stage kaydedilmiştir.

### 5.5 `COMPLETED`

Entry:

- Issue'nun zorunlu bütün gate'leri PASS, `not_required` veya geçerli reused
  evidence durumundadır;
- unauthorized action yoktur;
- final evidence veri-minimaldir.

Exit yoktur. Yeni iş yeni run'dır.

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
