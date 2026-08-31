# CSE Owner Communication Standard

**Belge türü:** Bağlayıcı owner iletişim protokolü  
**Geçerlilik tarihi:** 2026-08-31  
**Kaynak owner kararı:** Issue #551  
**Kapsam:** Bütün CSE ChatGPT/Codex durum, review, blocker, completion, merge, resume ve roadmap iletişimleri

Bu protokolün amacı ürün sahibinin teknik süreç içinde ne olduğunu anlayabilmesi, gerektiğinde müdahale edebilmesi ve karar verebilmesidir.

> CSE'de teknik gerçek saklanmaz; fakat owner'a önce teknik jargon değil, ürünün ve işlemin pratik anlamı anlatılır.

## 1. Zorunlu iki katmanlı anlatım

Owner'a verilen her önemli durum/sonuç mesajı iki katmanlı düşünülür.

### Katman 1 — İnsan diliyle zorunlu özet

Önce sade Türkçe kullanılır. Mümkün olduğunda şu sıra izlenir:

1. **Ne yaptık?** — kullanıcı/ürün açısından yapılan iş.
2. **Sonuç ne?** — şu anda ne çalışıyor veya iş hangi aşamada.
3. **Sorun var mı?** — varsa gerçek problem, teknik olmayan dille.
4. **Risk ne?** — düşük / orta / kritik ve kısa sebebi.
5. **Benim önerim ne?** — devam / düzelt / merge / dur vb.
6. **Senden ne gerekiyor?** — owner kararı/aksiyonu; gerekmiyorsa açıkça `Hiçbir şey`.

Bu başlıkların hepsi her mikro mesajda zorunlu değildir; fakat owner'ın bir karar vermesi, blocker anlaması veya proje durumunu takip etmesi gereken mesajlarda ilk katman bunları kapsamalıdır.

### Katman 2 — Teknik ayrıntı yalnız gerektiğinde

SHA, branch, R1/R2/R3/R4, CI, harness, fixture, allowlist, invariant, analyzer, schema, migration, divergence, exact head ve execution record gibi teknik ayrıntılar:

- yalnız karar, audit, debug veya izlenebilirlik için anlamlıysa;
- sade açıklamadan sonra;
- mümkünse kısa bir `Teknik not` bölümünde

verilir.

Owner teknik ayrıntıyı okumadan da temel durumu anlayabilmelidir.

## 2. Teknik terimi anında tercüme etme kuralı

Bir teknik terim kullanmak gerekiyorsa pratik anlamı hemen söylenir.

Örnekler:

- `harness-only correction` → `yalnız test düzeneğini düzelt; uygulama koduna dokunma`.
- `REPO_STATE_MISMATCH` → `yerel repo beklediğimiz Git durumunda değil; kodlamaya güvenle başlanamadı`.
- `fail-closed` → `belirsizlikte ilerlemek yerine güvenli biçimde durduk`.
- `R4 review` → `veri/ürün riski yüksek olduğu için daha derin kaynak incelemesi`.
- `CI failed` → `GitHub'ın otomatik kontrolü geçmedi`.
- `fixture error` → `uygulama değil, test için hazırlanan sahte veri/düzenek hata üretiyor`.
- `allowlist` → `bu işte değiştirilmesine izin verilen dosyalar listesi`.

Teknik terimin kendisini kullanmak zorunlu değilse sade Türkçe tercih edilir.

## 3. Ürün anlamını teknik implementasyondan önce anlat

Owner'a önce şu soru cevaplanır:

> Bu değişiklik uygulamada neyi değiştirecek veya neden yapılıyor?

Örnek:

Yanlış başlangıç:

> `ActiveProjectSession callback boundary corrected; 4/5 targeted tests pass.`

Doğru başlangıç:

> `B projesini seçtiğinde Beton, Albüm ve diğer proje ekranlarının tekrar A projesine dönmemesini sağlıyoruz. Kod tarafı tamamlandı; kalan problem uygulamada değil, son otomatik testin kendi düzeneğinde.`

Teknik sayı ve test detayları bundan sonra verilebilir.

## 4. Blocker anlatım standardı

Her blocker owner'a şu üç şeyi açıkça söylemelidir:

- **Ne engellendi?**
- **Neden?**
- **Bu ürün hatası mı, test/ortam/süreç hatası mı?**

Örnek:

> `Kodlama durmadı çünkü uygulamada yeni hata bulduk` demek yerine gerçek durum test harness ise `Uygulama tarafında yeni hata bulmadık; otomatik testin kendi hazırlığı bozuk olduğu için kontrol tamamlanamadı` denir.

Owner'a teknik blocker'ı olduğundan daha büyük veya daha küçük gösterme.

## 5. Risk anlatım standardı

Risk, teknik sınıf adıyla değil pratik sonuçla açıklanır.

- **Düşük:** UI/metin/test düzeneği gibi kullanıcı verisini tehlikeye atmayan değişiklik.
- **Orta:** birden fazla ekran/akış etkileniyor fakat veri modeli veya destructive işlem yok.
- **Kritik:** veri kaybı, migration, backup/restore, güvenlik, izin, release veya kullanıcı dosyası riski var.

`R3`, `R4` gibi sınıflar yalnız teknik not olarak eklenir.

## 6. Owner aksiyonu görünür olmalı

Her karar noktasında mesajın sonunda owner'ın yapması gereken şey net olmalıdır.

Örnekler:

- `Senden gereken: Merge onayı.`
- `Senden gereken: Bu davranışın A mı B mi olacağına karar vermen.`
- `Senden gereken: Hiçbir şey; teknik düzeltme aynı kapsam içinde devam edebilir.`

Owner'ın teknik rapordan aksiyonu kendisinin çıkarması beklenmez.

## 7. Uzun execution record'ların yeri

YAML, SHA listeleri, test tally, branch divergence ve benzeri kayıtlar audit/evidence için saklanabilir; ancak owner mesajının ana gövdesi olamaz.

Bir execution record gerekiyorsa:

1. önce insan diliyle özet;
2. sonra kısa teknik kayıt;
3. yalnız gerekli alanlar.

Owner'a salt YAML veya salt Codex çıktısı ile cevap verilmez.

## 8. Resume / `devam` davranışı

Owner `devam`, `son durum`, `ne oldu`, `neden durdu` gibi kısa mesaj verdiğinde:

- önce ürün dilinde current state anlatılır;
- önceki teknik blokları owner'a tekrar yapıştırması istenmez;
- current GitHub durumu gerektiğinde kendiliğinden okunur;
- sıradaki gerçek iş ve owner aksiyonu net söylenir.

## 9. Codex çıktısını tercüme etme sorumluluğu

Codex teknik completion/blocker raporu üretirse ChatGPT bunu owner'a doğrudan kopyalamaz.

ChatGPT:

1. teknik sonucu okur;
2. ürün anlamını çıkarır;
3. hata türünü sınıflandırır: `ürün / test / ortam / süreç`;
4. owner'a sade Türkçe özet verir;
5. gerekiyorsa teknik ayrıntıyı ikinci katmanda ekler.

## 10. Minimum owner mesaj şablonu

Önemli durumlarda varsayılan şablon:

```text
Ne yaptık?
<ürün diliyle 1-3 cümle>

Sonuç ne?
<mevcut gerçek durum>

Sorun var mı?
<yok / varsa sade açıklama>

Risk ne?
<Düşük / Orta / Kritik — kısa neden>

Benim önerim
<devam / düzelt / merge / dur>

Senden gereken
<karar/aksiyon veya Hiçbir şey>
```

Mesaj küçükse bu yapı daha kısa ve doğal biçimde birleştirilebilir.

## 11. Teknik doğruluk korunur

Sade anlatım:

- teknik gerçeği gizlemek;
- blocker'ı küçümsemek;
- test edilmemiş şeyi çalışıyor diye sunmak;
- uncertainty'yi yok saymak

anlamına gelmez.

Amaç doğruluğu azaltmak değil, doğruluğu **anlaşılır hale getirmektir**.

## 12. Ana karar

> CSE'de owner'a önce ürünün ve işlemin pratik anlamı anlatılır. Teknik jargon ikinci katmandır. Owner, SHA/YAML/R4/harness bilgisi okumadan projenin nerede olduğunu, neyin yanlış gittiğini, riskin ne olduğunu ve kendisinden ne beklendiğini anlayabilmelidir.
