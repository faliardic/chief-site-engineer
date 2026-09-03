# CSE New Chat GitHub Bootstrap — Dynamic v2

Repository: `faliardic/chief-site-engineer`
Default branch: `master`

Bu belge yeni sohbetin ZIP, eski SHA veya manuel handoff istemeden current GitHub gerçeğinden devam etmesini tanımlar.

## 1. Zorunlu başlangıç

Yeni sohbet yalnız şu sırayı uygular:

1. current `master` üzerindeki `AGENTS.md`;
2. current master HEAD;
3. açık Issue/PR/branch durumu;
4. aktif görev ve owner'ın son scope kararı;
5. yalnız değişen sözleşmenin gerektirdiği koşullu protokol.

Sabit SHA, schema, app version, aktif V2 item, test sayısı veya PR listesi bu bootstrap belgesinde tutulmaz.

## 2. Koşullu okuma

- ürün amacı/veri ilkesi: Unified Project Source;
- kapsam/sıra: V2 Scope ve Roadmap;
- Git/kullanıcı verisi: Project Instructions;
- lane/publication: Workflow Acceleration;
- test/gate: Minimum Validation;
- kritik model/review: Model Routing;
- kalıcı kritik handoff: Codex Instruction Comment Protocol;
- kritik provenance: ilgili `.cse` task/result.

FAST veya rutin resume sırasında bütün uzun kaynaklar yeniden okunmaz.

## 3. `devam` davranışı

Kullanıcı `devam` veya `GitHub'dan devam et` dediğinde ChatGPT:

- current GitHub durumunu okur;
- birden fazla açık iş varsa bağımlılık ve blocker'ı belirler;
- önce sıradaki tek güvenli aksiyonu ve sorumlu aktörü seçer;
- aynı authority metnini tekrar üretmez;
- Codex gerekiyorsa kullanıcının `Codex ile çalış` demesini beklemeden `Sıradaki aktör: Codex` der ve 10–15 satırı geçmeyen exact görevi verir; her handoff'ta kapsam/risk, beklenen validation/build/device işi ve blocker'a göre ChatGPT'nin belirlediği açık `Execution time budget: <süre>` bulunur, global sabit süre varsayılmaz;
- Fatih gerekiyorsa yalnız manuel ürün/device kabul adımlarını verir; terminal komutu vermez;
- ChatGPT'ın kendi yetkisindeki işlem mevcut owner kararıyla yapılabiliyorsa ayrıca `devam` istemeden yürütür.

Repository-local terminal, automated test, analyzer ve build/APK hazırlığı Codex tarafından, yetkili görevin minimum yeterli kapsamıyla yürütülür. Fatih PowerShell/terminal/Git/Flutter/test/analyzer/build komutu çalıştırmaz; kendisine bu komutlar hazırlanmaz veya verilmez. Fatih yalnız manuel ürün/device kabulünü ve nihai görsel/davranış PASS/FAIL kararını verir. Emulator/ADB/device execution yalnız exact package, cihaz ve veri-koruma sınırıyla açık owner delegasyonunda yapılabilir; MAIN/Acceptance/Debug ve mevcut veri güvenliği sınırları korunur.

Kullanıcıdan eski prompt/result/YAML kopyalaması istenmez.

## 4. Current-state sınırı

README, `.cse/state`, task/result, ZIP, handoff, podcast veya sohbet hafızası current GitHub gerçeğini override edemez.

GitHub'a erişilemiyorsa:

- durum tahmin edilmez;
- eski SHA/Issue üzerinden production işi başlatılmaz;
- erişilemeyen bilgi açıkça belirtilir.

## 5. Handoff

- FAST: chat içindeki kısa exact görev yeterlidir; GitHub comment zorunlu değildir.
- STANDARD: kalıcılık gerçekten gerekiyorsa kısa Issue/comment kullanılabilir.
- CRITICAL: self-contained GitHub instruction comment zorunludur.

## 6. İlk cevap

Yeni sohbetin ilk önemli cevabı önce owner'ın anlayacağı sade Türkçeyle şunları kapsar:

- ChatGPT'ın neyi kontrol ettiği veya yaptığı;
- bunun uygulama ve çalışma açısından pratik anlamı;
- sonucun başarılı, eksik veya engelli olup olmadığı;
- aktif/açık çalışma ve blocker;
- sıradaki güvenli aksiyon ve aktör;
- Codex gerekiyorsa kısa exact handoff;
- Fatih gerekiyorsa yalnız manuel ürün/device kabul adımları.

Master SHA, branch, divergence ve benzeri teknik kanıtlar sade sonuçtan sonra verilir; açıklamasız teknik terim ana cevap olamaz.

Her kullanıcıya teslim edilen sonuç `Sıradaki aksiyon — <aktör>: <tek uygulanabilir talimat>.` satırıyla biter. Tamamlanan aksiyondan sonra seçilen aktörün başlayacağı hazır talimat aynı yanıtta bulunur:

- Codex için kopyalanabilir, self-contained ve 10–15 satırı geçmeyen exact görev;
- Fatih için yalnız kısa manuel ürün/device kontrolü ve beklenen sonuç; terminal komutu verilmez;
- ChatGPT için mevcut owner yetkisi varsa otomatik yürütme, yoksa gerekli tek onay isteği.

Kullanıcıdan `devam`, `Codex ile çalış` veya `talimat hazırla` demesi beklenmez. Devam işi yoksa `Sıradaki aksiyon — Yok: İş tamamlandı.` yazılır.

Salt YAML ana cevap olamaz.

## 7. Ana karar

> Yeni sohbetin görevi geçmişi yeniden anlatmak değil, current GitHub gerçeğinden en kısa güvenli devam noktasını bulmaktır.
