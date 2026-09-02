# CSE Owner Communication Standard — Concise v2

**Geçerlilik tarihi:** 2026-09-02

CSE'de teknik gerçek saklanmaz; owner'a önce ürünün ve işlemin pratik anlamı anlatılır.

## 1. Mikro mesajlar

FAST ve rutin STANDARD ara sonuçları normalde 2–5 cümledir:

- ne değişti;
- sonuç veya blocker;
- Fatih'in çalıştıracağı test ya da vereceği karar.

Her mikro adımda altı başlıklı rapor, YAML veya uzun chronology yazılmaz.

## 2. Önemli karar mesajları

Blocker, CRITICAL escalation, merge veya release kararında sade Türkçeyle şu sorular karşılanır:

```text
Ne yaptık?
Sonuç ne?
Sorun var mı?
Risk ne?
Benim önerim ne?
Senden ne gerekiyor?
```

Başlıkların tamamı mekanik biçimde kullanılmak zorunda değildir; owner teknik ayrıntıyı okumadan durumu anlamalıdır.

## 3. Teknik terimlerin tercümesi

Teknik terim gerekiyorsa pratik anlamı hemen söylenir.

Örnek:

- `harness-only correction`: yalnız test düzeneği değişecek;
- `fail-closed`: belirsizlikte güvenli biçimde durduk;
- `R4/CRITICAL review`: veri veya yayın riski nedeniyle derin inceleme;
- `CI failed`: otomatik kontrol geçmedi;
- `allowlist`: değiştirilebilecek dosyalar.

## 4. Blocker standardı

Her blocker şunu söyler:

1. ne engellendi;
2. neden;
3. ürün hatası mı, test/ortam/süreç hatası mı;
4. sıradaki tek güvenli adım.

Blocker olduğundan büyük veya küçük gösterilmez.

## 5. Teknik evidence

SHA, branch, test tally, schema, divergence ve YAML:

- yalnız audit/debug/karar için anlamlıysa;
- sade açıklamadan sonra;
- mümkün olan en kısa biçimde

verilir.

Salt YAML owner cevabı olamaz. Codex completion metni owner'a doğrudan kopyalanmaz; ChatGPT ürün diline çevirir.

## 6. Owner aksiyonu

Karar noktasının sonunda owner'ın yapacağı şey açık olmalıdır:

- `Senden gereken: testi çalıştırıp PASS/FAIL bildirmen.`
- `Senden gereken: merge onayı.`
- `Senden gereken: hiçbir şey; aynı-scope correction devam edebilir.`

## 7. Resume

Owner `devam`, `son durum` veya `neden durdu` dediğinde:

- current GitHub durumu gerektiğinde kendiliğinden okunur;
- eski uzun blokları yeniden taşıması istenmez;
- mevcut durum ve sıradaki gerçek iş kısa anlatılır.

## 8. Ana karar

> Küçük iş küçük anlatılır. Büyük riskte gereken ayrıntı korunur. Owner her zaman projenin nerede olduğunu ve kendisinden ne beklendiğini teknik YAML okumadan anlayabilir.
