# CSE Owner Communication Standard — Concise v2

**Geçerlilik tarihi:** 2026-09-02

CSE'de teknik gerçek saklanmaz; owner'a önce ürünün ve işlemin pratik anlamı anlatılır.

## 0. Her yanıtta anlaşılır dil

ChatGPT kullanıcıya teslim ettiği her sonuçta, teknik kaydı göstermeden önce sade Türkçeyle şunları açıklar:

1. Ne yaptım?
2. Bunun uygulama veya çalışma açısından anlamı ne?
3. İşlem tamamlandı mı; sorun veya eksik var mı?

Owner'ın Git, Android veya test terimlerini çözerek sonucu çıkarması beklenmez. `fast-forward`, `divergence`, `head`, `allowlist`, `artifact` veya benzeri bir terim kullanılıyorsa günlük dilde karşılığı aynı yerde söylenir.

Ham Codex çıktısı, YAML veya komut dökümü ana açıklamanın yerine geçmez. ChatGPT bunları kısa bir sonuca çevirir; teknik ayrıntıyı yalnız kanıt veya uygulama talimatı olarak ikinci katmanda verir. Dil sade olur ancak risk, başarısızlık veya eksik doğrulama yumuşatılmaz.

## 1. Mikro mesajlar

FAST ve rutin STANDARD ara sonuçları normalde 2–5 cümledir:

- ne değişti;
- sonuç veya blocker;
- sıradaki tek aksiyon, sorumlu aktör ve uygulanabilir talimat.

Her kullanıcıya teslim edilen sonuç `Sıradaki aksiyon — <ChatGPT|Codex|Fatih|Yok>: <tek uygulanabilir talimat>.` satırıyla biter. Devam işi yoksa `Yok: İş tamamlandı.` yazılır; yapay iş üretilmez.

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

## 6. Sıradaki aksiyon

Her sonuçta yalnız owner'ın değil, sıradaki işi kimin yapacağı da açık olmalıdır:

- `Sıradaki aksiyon — Fatih: Exact testi çalıştır ve PASS/FAIL bildir.`
- `Sıradaki aksiyon — Codex: Verilen 5 dakikalık exact görevi uygula.`
- `Sıradaki aksiyon — ChatGPT: Owner-approved PR işlemini tamamla.`
- `Sıradaki aksiyon — Yok: İş tamamlandı.`

Bir aksiyon tamamlandıktan sonra sıradaki aksiyonun yalnız adı verilmez. Aynı yanıtta:

- Codex için `Hazır Codex talimatı:` altında kopyalanabilir 10–15 satırlık exact görev;
- Fatih için `Hazır Fatih talimatı:` altında exact komut, kısa kontrol ve beklenen sonuç;
- ChatGPT için mevcut authority içindeyse kendiliğinden execution, değilse gereken tek owner onayı

sunulur.

Repository/local execution gerekiyorsa ChatGPT, owner'ın ayrıca `Codex ile çalış`, `devam` veya `talimat hazırla` demesini beklemez; Codex handoff'unu kendiliğinden verir. ChatGPT'ın yetkili olduğu mevcut owner-approved işlem için ayrıca `devam` istenmez.

## 7. Resume

Owner `devam`, `son durum` veya `neden durdu` dediğinde:

- current GitHub durumu gerektiğinde kendiliğinden okunur;
- eski uzun blokları yeniden taşıması istenmez;
- mevcut durum ve sıradaki gerçek iş kısa anlatılır.

## 8. Ana karar

> Küçük iş küçük anlatılır. Büyük riskte gereken ayrıntı korunur. Owner her zaman projenin nerede olduğunu ve kendisinden ne beklendiğini teknik YAML okumadan anlayabilir.
