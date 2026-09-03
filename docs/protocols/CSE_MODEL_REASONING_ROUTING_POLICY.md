# CSE Model ve Reasoning Routing Policy — v2

**Geçerlilik tarihi:** 2026-09-02

Bu belge model ve reasoning seçimini yönlendirir; günlük işte metadata töreni üretmez. Güncel model adları ve availability kalıcı repository gerçeği değildir; execution yüzeyindeki mevcut seçeneklerden doğrulanır.

## 1. Risk tabanı

| Lane | Önerilen reasoning | Review |
|---|---|---|
| FAST | High | Rutin source/diff kontrolü |
| STANDARD | Extra High | Cross-module source/diff review gerektiğinde |
| CRITICAL | Max | Bağımsız derin review |

Dokümantasyon ve mekanik işte daha güçlü model seçmek zorunlu değildir. Contract, regression, parser/formatter, persistence veya data-integrity işinde daha hafif reasoning'e sessiz downgrade yapılmaz.

## 2. FAST ve STANDARD

FAST/STANDARD için varsayılan olarak şunlar yazılmaz:

- `model_routing` YAML;
- requested/actual model karşılaştırma tablosu;
- invocation evidence;
- `execution_record`;
- `review_recommendation`.

Görev talimatında yalnız gerektiğinde şu kısa satır yeterlidir:

```text
Reasoning: High | Extra High
Why: <tek cümle>
```

Runtime model/effort görünmüyorsa FAST/STANDARD execution sırf bu nedenle bloke edilmez. Görünür gerçek mismatch kaliteyi etkiliyorsa durulur ve owner'a bildirilir.

## 3. CRITICAL

CRITICAL görev exact model/reasoning request, review floor ve görünür invocation evidence kullanabilir.

Minimum kayıt:

```yaml
model_routing:
  lane: CRITICAL
  requested_model: <current available model>
  requested_reasoning: max
  actual_model: <visible value or unknown>
  actual_reasoning: <visible value or unknown>
  review_floor: CRITICAL
```

Görünür mismatch varsa fail-closed durulur. Runtime metadata görünmüyorsa `unknown` yazılır; değer tahmin edilmez. Bu belirsizlik review'da dikkate alınır fakat tek başına geçmiş kanıtı geçersiz kılmaz.

## 4. Execution mode ve orchestration

- Tek executor varsayılandır.
- Multi-agent/Ultra yalnız owner açıkça isterse ve bağımsız alt işler gerçekten paralel yürüyebiliyorsa kullanılır.
- `pro`, model veya reasoning seviyesi değildir.
- Reasoning seçimi, her Codex handoff'unda ChatGPT'nin kapsam/risk, beklenen validation/build/device işi ve blocker'a göre açıkça verdiği execution time budget'ı kaldırmaz; global sabit süre varsayılanı yoktur.

## 5. Ana karar

> Model yönlendirme kaliteyi destekler; FAST/STANDARD işlerde task/result/YAML üretim amacı hâline gelmez. Ayrıntılı routing evidence yalnız gerçek CRITICAL riskte tutulur.
