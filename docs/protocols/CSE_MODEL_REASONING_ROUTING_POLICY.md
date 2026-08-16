# CSE Model ve Reasoning Routing Policy

**Policy version:** `CSE-MRP-1.0`
**As-of:** 16 Ağustos 2026
**Kaynak Issue:** #455
**Durum:** Bağlayıcı model/reasoning/execution/orchestration routing sözleşmesi

Bu belge CSE görevlerinde ChatGPT ve Codex seçiminin nasıl kaydedileceğini,
runtime kanıtının nasıl yorumlanacağını ve review floor'un nasıl korunacağını
belirler. Ürün kapsamı, Git güvenliği ve validation genişliği kendi kanonik
kaynaklarında kalır.

## 1. Resmî ve değişken kaynaklar

16 Ağustos 2026 itibarıyla kullanılan resmî dayanaklar:

- [OpenAI model kataloğu](https://developers.openai.com/api/docs/models)
- [Latest model guidance](https://developers.openai.com/api/docs/guides/latest-model)

Model adı, alias, selector görünürlüğü, desteklenen reasoning değeri,
availability, deprecation ve retirement bilgisi değişkendir. Aşağıdaki
durumlardan birinde yeni görev/config/scheduled work bu iki resmî kaynak ve
varsa resmî deprecation kaynağı üzerinden yeniden doğrulanır:

- selector veya API katalog etiketi bu belgeden farklıysa;
- istenen model/effort görünmüyor veya çalışmıyorsa;
- retirement/deprecation tarihi yazılacaksa;
- kalıcı config ya da scheduled work yeni bir modele bağlanacaksa;
- bu as-of tarihinden sonra katalog gerçeği hakkında karar verilecekse.

Güncel resmî kaynakla doğrulanmayan retirement tarihi politika gerçeği olarak
yazılmaz. `gpt-5.5` yalnız açık comparison/reproduction ihtiyacıyla seçilebilir;
yeni CSE işi için varsayılan değildir. Contract, regression veya kritik işte
fast/lightweight varyant nihai executor ya da reviewer olamaz.

## 2. Birbirinden bağımsız dört eksen

| Eksen | CSE değerleri | Anlam |
| --- | --- | --- |
| Model | `gpt-5.6-sol \| gpt-5.6-terra \| gpt-5.6-luna` | İşin gereken yetenek/maliyet profili |
| Reasoning effort | `high \| xhigh \| max` | Seçilen modelin düşünme derinliği |
| Execution mode | `standard \| pro` | Yürütmenin standart veya pro reasoning modu |
| Orchestration | `single-agent \| Ultra` | Tek executor veya açıkça yetkilendirilmiş multi-agent yürütme |

UI eşlemesi: `High -> high`, `Extra High -> xhigh`, `Max -> max`.

- `gpt-5.6-sol`: karmaşık, açık uçlu, kritik veya yüksek değerli iş.
- `gpt-5.6-terra`: iyi tanımlı günlük üretim ve dokümantasyon işi.
- `gpt-5.6-luna`: kesin tarifli, mekanik, tekrarlanabilir düşük riskli iş.
- `pro`, model veya reasoning effort değildir; `ChatGPT Pro` planıyla da
  karıştırılmaz.
- `standard` varsayılandır. `pro` yalnız ölçülmüş kalite ihtiyacı, resmî
  availability ve current Issue'daki açık seçim birlikte varsa kullanılır.
- `Ultra`, reasoning effort değildir. Anlamlı bağımsız alt işlere bölünebilen
  multi-agent yürütmedir ve açık paralel çalışma yetkisi olmadan seçilmez.
- `max`, tek seçili modelde daha derin reasoning'dir; multi-agent anlamına
  gelmez.

Eski birleşik `Instant / Medium / High / Extra High / Pro Standard / Pro
Extended` dizisi kullanılmaz.

## 3. CSE risk matrisi

| Risk | İş | Codex | ChatGPT review floor |
| --- | --- | --- | --- |
| R0 | Mekanik, kesin, production kararı içermeyen | Luna / High | Luna veya Terra / High |
| R1 | Docs-only, Issue/task, rutin Git preflight | Terra / High | Terra / High |
| R2 | Dar, iyi tanımlı production değişikliği | Terra / Extra High | Sol / High; contract/regression ise Extra High |
| R3 | Çoklu modül, domain, parser/formatter, validation, regression | Sol / Extra High | Sol / Extra High |
| R4 | Persistence, migration, veri bütünlüğü, schedule engine, corpus omurgası, backup/restore, security | Sol / Max | Sol / Max |

CSE teknik işlerinde minimum `high`; code/helper/contract/parser/formatter/
validation/regression tabanı `xhigh`dır. R4 için `gpt-5.6-sol / max`
değerlendirmesi zorunludur. Çoklu kanonik source-authority değişikliği, kod
değiştirmese bile çelişki riski nedeniyle R3 olabilir.

## 4. İş başlamadan zorunlu routing kaydı

ChatGPT seçimi, herhangi bir edit/test/build/commit öncesinde current Issue ve
`.cse/tasks/<issue_no>_task.md` içinde kaydedilir:

```yaml
model_routing:
  policy_version: "CSE-MRP-1.0"
  task_risk: "R3"
  orchestrator:
    chatgpt_model: "gpt-5.6-sol"
    chatgpt_reasoning_effort: "xhigh"
  codex_model: "gpt-5.6-sol"
  codex_reasoning_effort: "xhigh"
  execution_mode: "standard"
  orchestration: "single-agent"
  selection_reason: "Exact görev riski ve değişen sözleşme."
  allowed_fallback: null
  review_floor:
    chatgpt_model: "gpt-5.6-sol"
    chatgpt_reasoning_effort: "xhigh"
  fail_closed_if_mismatch: true
```

R3/R4 için otomatik fallback veya downgrade yasaktır. İstenen model/effort
selector ya da invocation config'inde kanıtlanamıyorsa execution başlamaz.
Görünür actual model/effort requested değerle uyuşmuyorsa fail-closed durulur.

## 5. Runtime doğrulaması ve execution record

Her Codex sonucu ve `.cse/results/<issue_no>_result.md` şu bloğu taşır:

```yaml
execution_record:
  requested_model: "gpt-5.6-sol"
  actual_model: "unknown"
  requested_reasoning_effort: "xhigh"
  actual_reasoning_effort: "unknown"
  execution_mode: "standard"
  orchestration: "single-agent"
  mismatch_detected: null
  runtime_verification_status: "unverified"
```

Runtime actual model/effort'i göstermiyorsa tahmin yapılmaz. Bu durumda exact
değerler `unknown`, `mismatch_detected: null` ve
`runtime_verification_status: unverified` olur. Metadata'nın gizli olması tek
başına mismatch kanıtı veya downgrade yetkisi değildir; ancak requested
selector/invocation kanıtı yine zorunludur.

`mismatch_detected: false` yalnız actual model ve actual effort görünür olup
requested değerlerle exact eşitse yazılır. Görünür uyuşmazlıkta
`mismatch_detected: true` yazılır ve fail-closed stop uygulanır.

## 6. Review recommendation

Her Codex sonucu ve `.cse/results/<issue_no>_result.md` ayrıca şu bloğu taşır:

```yaml
review_recommendation:
  risk_observed: "R3"
  recommended_chatgpt_model: "gpt-5.6-sol"
  recommended_reasoning_effort: "xhigh"
  recommended_mode: "standard"
  recommendation_reason: "Canonical source-authority değişikliği."
  must_review:
    - "allowlist ve source-authority tutarlılığı"
    - "runtime verification belirsizliği"
  residual_uncertainty: "Runtime actual model/effort görünmüyor."
  escalation_condition: "Unexpected diff, kanıt çelişkisi veya daha yüksek risk."
```

Codex recommendation görev başındaki review floor'u düşüremez; yalnız korur
veya yükseltir:

```text
final_review = max(task review floor, Codex recommendation, observed actual risk)
```

Risk sırası `R0 < R1 < R2 < R3 < R4` kabul edilir. `BLOCKED`, `PARTIAL`,
`UNVERIFIED`, test eksikliği, unexpected diff veya kanıt çelişkisi review'u en
az bir risk kademesi yükseltir; R4 üst sınırdır. Codex PASS merge yetkisi
değildir. ChatGPT diff/source/evidence review yapar; Ready ve merge yalnız
ayrıca yetkilendirildiğinde ilerler.
