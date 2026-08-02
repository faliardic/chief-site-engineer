# Issue #299 — Untrusted API planını güvenli action'a bağlamak

## Öğrenme amacı

Bir modelin structured JSON üretmesi, o JSON'un doğru veya yetkili olduğu
anlamına gelmez. O9'da API yalnız öneri üretir; yerel O1–O8 sözleşmesi action
admission kaynağı olmaya devam eder.

## Request neden strict schema kullanır?

Responses request'i model ID'sini environment'tan alır ve output biçimini
kapalı bir JSON Schema ile sınırlar:

```python
payload = {
    "model": model_from_environment,
    "input": bounded_prompt,
    "store": False,
    "text": {
        "format": {
            "type": "json_schema",
            "name": "cse_orchestrator_proposal",
            "schema": PROPOSAL_JSON_SCHEMA,
            "strict": True,
        }
    },
}
```

`additionalProperties=false`, modelin bilinmeyen alanlarla örtülü capability
veya komut eklemesini zorlaştırır. Buna rağmen schema tek başına yeterli
değildir; API output'u hâlâ untrusted input'tur.

## Yerel validator neyi yeniden kanıtlar?

Validator modelin listesini subset olarak kabul etmez; exact local contract
ile aynı sıra ve içerikte olmasını ister:

```python
if writes != contract.write_allowlist:
    raise ApiProposalError("write_allowlist_drift")
if commands != contract.validation_commands:
    raise ApiProposalError("validation_commands_drift")
```

Ayrıca O2 kararı `allowed`, hedef state `ACTION_AUTHORIZED`, approval seviyesi
ve budget delta exact olmalıdır. Source/contract/action fingerprint'leri model
proposal'ında bulunmaz; immutable local contract ve child request arasında
eşleştirilir. Böylece model bu değerleri seçemez veya genişletemez.

## API ve child neden tek kullanımlık?

Her dış adapter process-local admission guard taşır:

```python
if self._request_used:
    raise OpenAIClientError("duplicate_api_request")
self._request_used = True
```

Codex tarafında anahtar action fingerprint'tir. Duplicate kontrolü
subprocess'ten önce yapılır. Retry `0` sözleşmesi adapter içinde otomatik retry
olmamasıyla korunur.

## Codex prompt neden stdin'den geçer?

Exact argv üç parçadır:

```python
("codex", "exec", "-")
```

Prompt command line argümanına konulmaz. Repository dışındaki runtime root'ta
geçici tutulur, stdin'e verilir ve hemen silinir. `subprocess.run(...,
shell=False)` ikinci bir shell parse katmanı oluşturmaz. Cwd, environment-name
allowlist, timeout ve output limiti caller sözleşmesinden gelir.

## GitHub neden iki HTTP adımı görür?

İlk adım read-only existing-PR preflight'idir. İkinci adım, ancak preflight
boşsa tek Draft PR mutasyonudur:

```text
GET open PR by exact head/base
→ none
→ POST one draft pull request
```

Local/remote head drift veya divergence varsa GET/POST başlamadan önce
reddedilir. Adapter Ready, merge, close, delete veya release endpoint'i
sunmaz.

## Testlerin amacı

Focused fake-adapter suite şu sınıfları gerçek network veya child olmadan
doğrular:

- strict, non-stored Responses payload ve environment-only model/key;
- refusal, incomplete, rate limit, API error ve duplicate request;
- proposal allowlist/command/approval/policy/budget/fingerprint drift'i;
- exact Codex argv/cwd/environment/timeout/output ve duplicate child;
- missing CLI, authentication, timeout ve non-zero classification;
- exact Draft PR payload, existing PR, divergence, head drift ve duplicate;
- default dry-run ve ayrı API/Codex/publish execute kapıları.

Full Python suite, O1–O8 regression davranışının korunmasını kanıtlar.

## Şunu şöyle yaptık ki...

Modelin proposal alanlarını strict schema ile sınırladık ki parser belirsiz
normalizasyon yapmasın. Proposal'ı yerel exact contract ile yeniden doğruladık
ki model Issue authority'sini genişletemesin. API key, model ve GitHub token'ı
yalnız environment'dan aldık ki secret source veya evidence'a yerleşmesin.
Child ve REST mutation'ını ayrı explicit kapılara böldük ki API planı tek başına
mutation yetkisine dönüşmesin.

## Bu koşuda canlı pilot neden çalışmadı?

Gerekli credential adları mevcut değildi ve Codex help envanteri tek denemede
okunamadı. Sözleşme secret istemeyi, üretmeyi ve retry'ı yasakladığı için fake
adapter testleriyle implementation tamamlandı; gerçek API, child ve REST
invocation başlatılmadı.
