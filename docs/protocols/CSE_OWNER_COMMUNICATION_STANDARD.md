# CSE Owner Communication Standard — Concise v5

**Geçerlilik tarihi:** 2026-09-09

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

Non-CRITICAL işte one-pass akışının sonucu anlatılır: mevcut repro kanıtı, fix, tek focused validation ve yalnız gereken manuel/device kabul. Owner/device kanıtı yapay harness'te üretilemiyor diye owner'dan yeniden repro veya deterministic automated FAIL sağlaması istenmez. Kararı değiştirmeyen diagnostic/test turları açılmaz.

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

Merge kararında ayrıca incelenen PR body'ye göre Issue disposition açıklanır:

```text
Bu merge ile:
- #XXX otomatik kapanacak;
- #YYY yalnız referans olarak kalacak ve açık kalacak.
```

Kapanacak Issue yoksa bu açıkça belirtilir. Belirsiz veya yanlış `Closes`/`Refs` kullanımı varsa merge öncesinde düzeltilir.

## 3. Teknik terimlerin tercümesi

Teknik terim gerekiyorsa pratik anlamı hemen söylenir.

Örnek:

- `harness-only correction`: yalnız test düzeneği değişecek;
- `fail-closed`: belirsizlikte güvenli biçimde durduk;
- `R4/CRITICAL review`: veri veya yayın riski nedeniyle derin inceleme;
- `CI failed`: otomatik kontrol geçmedi;
- `allowlist`: değiştirilebilecek dosyalar;
- `Closes #...`: PR merge olduğunda belirtilen tekil Issue otomatik kapanacak;
- `Refs #...`: PR Issue'yu ilişkilendirir ancak açık bırakır.

## 4. Blocker standardı

Her blocker şunu söyler:

1. ne engellendi;
2. neden;
3. ürün hatası mı, test/ortam/süreç hatası mı;
4. sıradaki tek güvenli adım.

Blocker olduğundan büyük veya küçük gösterilmez. Non-CRITICAL işte runtime/device FAIL, widget/fake test PASS ile geçersiz sayılmaz; gerçek davranışı temsil edemeyen harness tek başına düzeltmeyi engellemez. Bir başarısız repro denemesinden sonra kaynak/runtime incelemesine veya mevcut en güçlü kanıta geçilir; owner diagnostic bürokrasiye katılmaz.

## 5. Teknik evidence

SHA, branch, test tally, schema, divergence ve YAML:

- yalnız audit/debug/karar için anlamlıysa;
- sade açıklamadan sonra;
- mümkün olan en kısa biçimde

verilir.

Salt YAML owner cevabı olamaz. Codex completion metni owner'a doğrudan kopyalanmaz; ChatGPT ürün diline çevirir.

## 6. Sıradaki aksiyon, publication ve Issue closure

Her sonuçta yalnız owner'ın değil, sıradaki işi kimin yapacağı da açık olmalıdır:

- `Sıradaki aksiyon — Fatih: Manuel ürün kontrolünü yap ve davranış PASS/FAIL kararını bildir.`
- `Sıradaki aksiyon — Codex: Verilen exact görevi handoff'taki execution time budget içinde uygula.`
- `Sıradaki aksiyon — ChatGPT: Owner-approved PR işlemini tamamla.`
- `Sıradaki aksiyon — Yok: İş tamamlandı.`

Bir aksiyon tamamlandıktan sonra sıradaki aksiyonun yalnız adı verilmez. Aynı yanıtta:

- Codex için `Hazır Codex talimatı:` altında kopyalanabilir 10–15 satırlık exact görev ve ChatGPT'nin kapsam/risk, beklenen validation/build/device işi ve blocker'a göre belirlediği açık `Execution time budget: <süre>`;
- Fatih için `Hazır Fatih talimatı:` altında yalnız manuel ürün/device kontrolü ve beklenen sonuç; terminal komutu verilmez;
- ChatGPT için mevcut authority içindeyse kendiliğinden execution, değilse gereken tek owner onayı

sunulur.

`PARALLEL_READ` seçildiğinde de owner-facing `Hazır Codex talimatı` **yalnız bir tanedir**. Bu tek talimat ana Codex'i `Builder/WRITE` olarak başlatır ve Builder'ın native Codex collaboration/subagent yeteneğiyle tam 1 `Scout/READ` ve 1 `Reviewer/READ` oluşturup yönetmesini ister. Fatih'e üç ayrı agent prompt'u verilmez; üç ayrı Codex sohbeti/süreci açması veya Scout/Reviewer sonuçlarını Builder'a taşıması istenmez.

Scout sonucunu Builder kendi tüketir. Builder final exact revision/snapshot'ı Reviewer'a kendisi verir; `CHANGES_REQUIRED` varsa aynı task içinde düzeltir ve Reviewer'a yeniden inceletir. Owner'a ancak gerçek owner/authority veya manuel/device gate'i, native subagent capability için `ROUTING_ESCALATION_REQUIRED`, ya da tek kanonik final sonuç döner.

Native subagent/collaboration yeteneği execution yüzeyinde gerçekten kullanılamıyorsa ChatGPT/Codex bunu üç manuel session'la sessizce telafi etmez ve topology'yi `SINGLE`'a düşürmez. Manuel üç-session çalışma ancak Fatih ayrıca açıkça fallback olarak seçerse kullanılabilir.

Repository/local execution gerekiyorsa ChatGPT, owner'ın ayrıca `Codex ile çalış`, `devam` veya `talimat hazırla` demesini beklemez; Codex handoff'unu kendiliğinden verir. ChatGPT'ın yetkili olduğu mevcut owner-approved işlem için ayrıca `devam` istenmez.

Fatih'e yalnız gerçekten owner kararı veya manuel/device kabul gerektiren aksiyon verilir. Non-CRITICAL işte manuel/device kabul gerekmiyorsa kısa gerekçeyle `GEREKMİYOR` yazılır; Codex automated PASS sonrası commit/push için manuel PASS istenmez. Gereken manuel/device kabulde Fatih PASS/FAIL kapısı korunur. Automated PASS, manuel PASS veya Ready/merge/release yetkisi gibi sunulmaz.

Her Codex handoff'unda açık süre bütçesi zorunludur; global sabit süre kullanılmaz. Bütçe dolarsa Codex çalışmayı güvenle koruyup durur, yeni yaklaşım başlatmadan exact blocker ve kalan tek aksiyonu bildirir. CRITICAL ve owner Ready/merge/release kapıları değişmez.

Tek amaçlı implementation Issue'su incelenen PR body'de açıkça `Closes #...` ile belirtilmişse owner'ın `merge et` kararı o otomatik kapanışı da kapsar; ikinci bir Issue closure onayı istenmez. Parent, umbrella, manuel acceptance, release veya devam işi `Refs #...` ile açık kalır. PR body disposition'ı belirsizse merge edilmez.

## 7. Resume

Owner `devam`, `son durum` veya `neden durdu` dediğinde:

- current GitHub durumu gerektiğinde kendiliğinden okunur;
- eski uzun blokları yeniden taşıması istenmez;
- mevcut durum ve sıradaki gerçek iş kısa anlatılır.

## 8. Ana karar

> Küçük iş küçük anlatılır. Büyük riskte gereken ayrıntı korunur. Owner her zaman projenin nerede olduğunu, merge ile hangi Issue'nun kapanacağını ve kendisinden ne beklendiğini teknik YAML okumadan anlayabilir. `PARALLEL_READ` owner'a tek ana Codex talimatı olarak görünür; Scout ve Reviewer orchestration'ı ana Builder'ın iç işidir.
