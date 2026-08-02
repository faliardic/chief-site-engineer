# Issue #289 — CSE Orchestrator O2 State ve Policy Engine

## 1. Amaç ve sınır

O2, O1 `Observation v1` ile machine-readable authorization'dan hazırlanmış
immutable policy girdisini değerlendirir. Sonuç yalnız state transition ve
action-admission kararıdır. O2 subprocess başlatmaz, network veya filesystem
okumaz/yazmaz, approval üretmez ya da tüketmez ve action çalıştırmaz.

Bu ayrım önemlidir: policy `ACTION_RUNNING`e admission verebilir fakat runner
değildir. Gerçek invocation, append-only admission persistence ve result parser
sonraki Orchestrator fazlarındadır.

## 2. Executable state sözleşmesi

`tools/cse_orchestrator/state.py`, O0 tablosundaki bütün izinli transition'ları
`State` ve `ALLOWED_TRANSITIONS` içinde sabitler. Yasak veya unknown transition
`can_transition` için false, event projection için fail-closed
`TransitionError` üretir.

Terminal states:

- `PREFLIGHT_BLOCKED`
- `BLOCKED`
- `FAILED`
- `CANCELLED`
- `COMPLETED`

Bütün non-terminal states explicit `CANCELLED` geçişine sahiptir. Immutable
`TransitionEvent` kimliği sorted compact UTF-8 payload'ın SHA-256 değeridir.
Projection exact aynı event replay'ini no-op kabul eder; event-ID collision,
run/sequence/state farkı veya yasak transition geçmişi değiştiremez.

## 3. Policy input sınırı

`evaluate_policy(mapping)` exact alanlı bir in-memory mapping kabul eder:

- `state_from`, önerilen `state_to`;
- `pending_action`, `required_approval_level`, `resume_state` ve
  `expected_success_state`;
- capability ve current source/contract/scope/action/capability/budget
  fingerprint'leri;
- current authorization metadata'sı;
- sayaçların used/max değerleri ve full-gate revision;
- same-operation retry bağı;
- standard blocker listesi;
- reused evidence ve explicit optional-gate disposition listesi;
- caller tarafından verilen UTC `evaluated_at`.

Sistem saati input yerine kullanılmaz. Böylece aynı input aynı kararı üretir.
Top-level, authorization, fingerprint, budget, retry, evidence ve gate
nesnelerinde unknown veya eksik alan fail-closed reddedilir. Caller mapping'i
değiştirilmez.

## 4. Approval ve capability admission

Action bağları şöyledir:

| Action | Capability | Authorized state | Success state | Budget counter |
| --- | --- | --- | --- | --- |
| `CODE_CHANGE` | `Code` | `CODEX_AUTHORIZED` | `FOCUSED_PASS` | `primary` |
| `CORRECTION` | `Code` | `CODEX_AUTHORIZED` | `FOCUSED_PASS` | `correction` |
| `FULL_VALIDATION` | `Code` | `ACTION_AUTHORIZED` | `FULL_PASS` | `full_gate` |
| `CHECKPOINT_COMMIT` | `Code` | `ACTION_AUTHORIZED` | `CHECKPOINT_COMMITTED` | `checkpoint_commit` |
| `BUILD` | `Code` | `ACTION_AUTHORIZED` | `ARTIFACT_BUILT` | `build` |
| `DEVICE` | `Device` | `ACTION_AUTHORIZED` | `DEVICE_ACCEPTANCE` | `device` |
| `PUBLISH` | `Publish` | `ACTION_AUTHORIZED` | `COMPLETED` | `publish` |

Approval sıra bilgisi explicit olsa da admission action-bound kalır: daha üst
seviye fakat farklı action approval'ı exact action fingerprint'inin yerini
tutmaz. Expiry, supersession, önceki consumption, yetersiz level, capability
farkı veya source/scope/action/capability/budget drift'i approval'ı geçersiz
kılar.

`SCOPE_VALIDATED → AWAITING_APPROVAL` sonucu `allowed=false` ve
`approval_required` gerekçesini taşır. `CODE_CHANGE`/`CORRECTION` yalnız
`CODEX_AUTHORIZED`; diğer beş mutable/maliyetli action yalnız
`ACTION_AUTHORIZED` yönüne kabul edilir. `ACTION_AUTHORIZED`dan success state'e
doğrudan geçiş transition tablosunda yoktur.

## 5. Budget, retry ve reused evidence

Invocation admission'ından önce ilgili used/max sayacı ve hard stop kontrol
edilir. Admission kararı yalnız `budget_delta` önerir; sayacı yazmaz. Bounded
same-operation retry yalnız `CORRECTION`, exact failed action ve current action
fingerprint'iyle hem `correction` hem `same_operation_retry` bütçesini tüketme
önerisi üretir.

Aynı source fingerprint üzerinde tamamlanmış full gate tekrar çalıştırılmaz;
karar `full_gate_revision_reuse_required` ile fail-closed kalır. Önceki evidence
yalnız `PASS`, exact source fingerprint ve exact contract fingerprint birlikte
eşleşirse taşınır.

Optional gate sessiz geçilemez. İlgili skip transition'ı her gate için:

- gerekçeli `not_required`; veya
- gerekçeli `reused` ve exact evidence

taşır. Eksik gerekçe `SCOPE_DRIFT`, fingerprint farkı
`PROVENANCE_MISMATCH` üretir.

## 6. Blocker ve canonical output

Policy bilinen blocker'ların tamamını korur ve O0 güvenlik precedence'ına göre
sıralar. Unknown blocker genişletilmez; fail-closed `SCOPE_DRIFT` olur.

Asgari karar yüzeyi:

```json
{
  "allowed": false,
  "blockers": [],
  "budget_delta": {},
  "reasons": ["approval_required"],
  "required_approval_level": "CODE_CHANGE",
  "reused_evidence": [],
  "state_from": "SCOPE_VALIDATED",
  "state_to": "AWAITING_APPROVAL"
}
```

`canonical_decision_json` bu nesneyi whitespace'siz, sorted-key, UTF-8 uyumlu
JSON olarak üretir. Output'ta clock, random ID, I/O sonucu veya caller'a ait raw
içerik bulunmaz.

## 7. Validation yaklaşımı

Focused test matrisi bütün izinli/yasak transition'ları, terminal/replay
davranışını, approval/capability/drift/budget/retry/reuse sözleşmelerini,
blocker precedence'ını, input immutability'yi ve canonical output'u kapsar.
Haricî I/O guard testi `open`, `subprocess.run` ve `socket.socket` çağrılarını
fail ettirirken policy kararının yine üretildiğini doğrular.

Full Python suite O1 observer'ın gerilemediğini kanıtlar. Flutter, build, API,
ADB ve device gate'leri değişen sözleşmeyle ilgili değildir ve bu Issue'da
çalıştırılmaz.
