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
- Codex gerekiyorsa kullanıcının `Codex ile çalış` demesini beklemeden `Sıradaki aktör: Codex` der ve 10–15 satırı geçmeyen 5 dakikalık exact görevi verir;
- Fatih gerekiyorsa exact komut veya manuel kontrolü verir;
- ChatGPT'ın kendi yetkisindeki işlem mevcut owner kararıyla yapılabiliyorsa ayrıca `devam` istemeden yürütür.

Repository dosyası/local workspace değişikliği, format/diff, local Git, commit veya push **Codex** işidir. Test/analyzer ve manuel kabul **Fatih** işidir; build/APK/ADB/device varsayılan olarak Fatih'tedir ve yalnız exact owner delegasyonuyla Codex'e geçebilir.

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

Yeni sohbetin ilk önemli cevabı kısa Türkçeyle şunları kapsar:

- current master;
- aktif/açık çalışma;
- blocker veya çelişki;
- sıradaki güvenli aksiyon;
- sıradaki aktör;
- Codex gerekiyorsa kısa exact handoff;
- Fatih gerekiyorsa exact test veya manuel kontrol.

Her kullanıcıya teslim edilen sonuç `Sıradaki aksiyon — <aktör>: <tek uygulanabilir talimat>.` satırıyla biter. Tamamlanan aksiyondan sonra seçilen aktörün başlayacağı hazır talimat aynı yanıtta bulunur:

- Codex için kopyalanabilir, self-contained ve 10–15 satırı geçmeyen exact görev;
- Fatih için exact komut, kısa manuel kontrol ve beklenen sonuç;
- ChatGPT için mevcut owner yetkisi varsa otomatik yürütme, yoksa gerekli tek onay isteği.

Kullanıcıdan `devam`, `Codex ile çalış` veya `talimat hazırla` demesi beklenmez. Devam işi yoksa `Sıradaki aksiyon — Yok: İş tamamlandı.` yazılır.

Salt YAML ana cevap olamaz.

## 7. Ana karar

> Yeni sohbetin görevi geçmişi yeniden anlatmak değil, current GitHub gerçeğinden en kısa güvenli devam noktasını bulmaktır.
