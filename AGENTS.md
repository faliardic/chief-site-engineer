# CSE Codex Repository Instructions

Bu dosya repository kökünde bütün CSE çalışmalarına uygulanır ve günlük execution için tek zorunlu giriş noktasıdır.

## 1. Güncel gerçek ve kaynak otoritesi

- Güncel repository gerçeği: GitHub `master`, current Issue/PR/branch ve owner kararları.
- Kalıcı ürün amacı ve veri ilkeleri: `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`.
- Güncel ürün kapsamı ve sıra: `docs/v2/CSE_V2_SCOPE.md` ve `ROADMAP.md`.
- Kritik Git ve veri güvenliği: `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`.
- Lane ve publication ayrıntıları: `docs/protocols/CSE_WORKFLOW_ACCELERATION_PROTOCOL.md`.
- Test/gate ayrıntıları: `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md`.

Sabit master SHA, schema, app version, aktif Issue/PR veya roadmap ilerlemesi kalıcı protokollerde tutulmaz. Bunlar her görevde GitHub/repository üzerinden okunur.

README, eski Issue/PR, `.cse/state`, task/result, ZIP, handoff, podcast veya sohbet hafızası current GitHub gerçeğini override edemez.

## 2. Yeni sohbet ve resume

Yeni görevde zorunlu okuma:

1. `AGENTS.md`
2. current GitHub `master`, açık Issue/PR ve aktif görev
3. yalnız değişen sözleşmenin gerektirdiği koşullu kaynak

Koşullu okuma:

- ürün/veri kararı: Unified Source;
- ürün kapsamı/sırası: V2 Scope ve Roadmap;
- Git veya kullanıcı verisi riski: Project Instructions;
- test/gate kararı: Minimum Validation;
- STANDARD/CRITICAL publication: Workflow Acceleration;
- kritik model/review ihtiyacı: Model Routing;
- kalıcı kritik handoff: Codex Instruction Comment Protocol.

Aynı görev resume ediliyorsa değişmeyen uzun kaynaklar tekrar okunmaz. Kullanıcı `devam` dediğinde current GitHub durumu bulunur ve sıradaki gerçek işlem yapılır.

GitHub'a erişilemiyorsa güncel durum tahmin edilmez ve production işi başlatılmaz.

Owner talebi AGENTS.md veya canonical çalışma kuralını değiştiriyorsa asıl teknik/ürün işi durur. Önce karar current GitHub authority olarak kaydedilir; en dar protokol değişikliği hazırlanır, review ve owner merge kapısından geçirilir. Master güncellenip güncel AGENTS.md yeniden okunduktan sonra asıl teknik işe dönülür. Bu sıra Ready/merge yetkisini kendiliğinden vermez.

## 3. Zorunlu aktör yönlendirmesi ve sıradaki aksiyon

ChatGPT/Work Mode her kullanıcı talebinde execution başlamadan önce sıradaki tek işi ve sorumlu aktörü belirler:

- **ChatGPT:** current GitHub okuma, planlama, Issue/PR koordinasyonu, review ve owner-approved Ready/merge;
- **Codex:** repository-local terminal, automated test, analyzer, build/APK hazırlığı, dosya değişikliği, format/diff ve local Git/commit/push;
- **Fatih:** yalnız manuel ürün/device kabulü ve nihai görsel/davranış PASS/FAIL kararı; PowerShell/terminal komutu çalıştırmaz;
- **Codex device exception:** Fatih exact package, cihaz ve veri-koruma sınırıyla açıkça devrederse emulator/ADB/device işlemi ChatGPT'nin göreve özel verdiği execution time budget içinde Codex'e geçebilir. PASS/FAIL ve ürün kabulü Fatih'te kalır.

Repository veya local execution gerekiyorsa ChatGPT, kullanıcının `Codex ile çalış` demesini beklemez. Açıkça `Sıradaki aktör: Codex` der ve current Issue/kuralları tekrar etmeyen, 10–15 satırı geçmeyen exact handoff verir. `CSE_PROJECT_INSTRUCTIONS.md` içindeki açık documentation-only owner istisnası dışında ChatGPT/Work Mode, GitHub Contents API üzerinden repository dosyası değiştirmez.

Her Codex handoff'u ChatGPT'nin göreve özel belirlediği açık `Execution time budget: <süre>` alanını taşır. Bütçe; kapsam, risk, beklenen validation/build/device işi ve mevcut blocker'a göre seçilir.

ChatGPT'ın kendi yetkisindeki işlem mevcut owner kararıyla yapılabiliyorsa ayrıca `devam` istemeden yürütülür. Kullanıcıya teslim edilen her sonuç şu satırla biter:

`Sıradaki aksiyon — <ChatGPT|Codex|Fatih|Yok>: <tek uygulanabilir talimat>.`

Bir aksiyon tamamlandığında yalnız sonraki işin adı söylenmez; aynı yanıtta başlamaya hazır talimat da hazırlanır:

- **Codex:** `Hazır Codex talimatı:` altında current kaynakları tekrar etmeyen, kopyalanabilir 10–15 satırlık exact görev;
- **Fatih:** `Hazır Fatih talimatı:` altında yalnız kısa manuel ürün/device kontrolü ve beklenen sonuç; terminal komutu verilmez;
- **ChatGPT:** mevcut owner yetkisi varsa sonraki koordinasyon işlemini kendiliğinden yürütür; yeni yetki gerekiyorsa yalnız gerekli tek onay cümlesini verir;
- **Yok:** devam işi veya hazırlanacak talimat bulunmadığını açıklar.

Kullanıcıdan sıradaki prompt'u yazması, `devam` demesi veya Codex talimatını ayrıca istemesi beklenmez. Hazır talimat, seçilen aktörün ek açıklama istemeden başlayabileceği kadar self-contained olur.

Devam işi kalmadığında `Sıradaki aksiyon — Yok: İş tamamlandı.` yazılır; yapay yeni iş üretilmez.

## 4. Zorunlu lane seçimi

Her iş yalnız bir lane kullanır:

FAST/STANDARD için varsayılan one-pass akışı:

`reproduce once -> fix -> one focused validation -> only-needed manual/device check -> owner merge gate`

Doğrudan, tekrarlanabilir owner/device kanıtı ve yeterince belirlenmiş source root cause varsa düzeltme öncesi deterministic automated FAIL zorunlu değildir. Owner/device kanıtı, hatayı temsil edemeyen yapay test harness'inden üstündür; widget/fake test PASS'i cihazdaki hatayı geçersiz kılmaz. Bir başarısız repro denemesinden sonra source/runtime diagnosis veya mevcut en güçlü kanıta geçilir; kararı değiştirmeyen diagnostic/test döngüleri yapılmaz.

Focused validation yeterliyse analyzer yalnız material ihtiyaçta, manuel/device kabul yalnız runtime'a özgü davranışta veya owner açıkça istediğinde yapılır. Manuel/device kabul gerekmeyen non-CRITICAL işte Codex automated PASS sonrası commit/push manuel PASS beklemez. Gereken kabulde Fatih PASS/FAIL kapısı korunur; gerekli kontrol FAIL/PENDING ise publication kapalı kalır. Ready/merge yetkisi bundan bağımsız owner kapısıdır. CRITICAL validation ve güvenlik kapıları aynen uygulanır.

### FAST

Dar documentation, metin, icon, tooltip, spacing, layout, presentation, basit navigation veya persistence contract'ını değiştirmeyen küçük UI işi.

FAST varsayılanı:

- temiz ve senkron yerel `master`;
- tek davranış;
- ChatGPT'nin açıkça belirlediği göreve özel execution time budget;
- Issue, `.cse` task/result ve routing YAML yok;
- current GitHub `master` ruleset'i PR istiyorsa tek kısa ömürlü branch ve tek minimal Draft PR; bu zorunluluk işi STANDARD'a yükseltmez;
- Codex format, changed-path review, `git diff --check` ve minimum yeterli automated doğrulamayı yapar;
- bağımsız review, geniş CI, full suite ve cihaz kontrolü yalnız somut ihtiyaç varsa;
- test/analyzer/build execution Codex'te, manuel ürün/device kabulü Fatih'tedir;
- gereken manuel/device kabulde Fatih `PASS` bildirmeden commit veya push yapılmaz; kabul gerekmiyorsa Codex automated PASS yeterlidir;
- gerekli doğrulama/kabul FAIL/PENDING durumundayken yeni işe geçilmez.

### STANDARD

Birden fazla ekran/modül, session/project context veya persistence/release-critical olmayan orta ölçekli behavior değişikliği.

STANDARD varsayılanı:

- tek kısa Issue veya self-contained görev özeti;
- tek kısa ömürlü branch;
- açık execution time budget içinde mümkünse inceleme, fix, focused validation ve yetkili commit/push tek adımda;
- test/analyzer/build execution Codex'te, manuel ürün/device kabulü Fatih'te;
- `.cse` ve routing YAML varsayılan olarak yok;
- bağımsız diff review değer üretiyorsa tek Draft PR;
- mevcut iş master'a alınmadan yeni production branch açılmaz;
- stacked PR yasaktır.

### CRITICAL

Schema/migration, backup/restore, stable identity/revision, transaction/event/history, attachment veya kullanıcı dosyası bütünlüğü, destructive işlem, security/privacy, permission/signing/application ID, background/reboot, DWG conversion data-loss riski, gerçek kullanıcı data root'u veya release/store işi.

CRITICAL varsayılanı:

- exact Issue, allowlist ve stop conditions;
- branch ve Draft PR;
- gerekli `.cse` provenance;
- Issue'ya özel validation/compatibility/device/release gate;
- bağımsız derin review;
- Ready/merge/release için owner kararı.

Somut CRITICAL trigger yoksa iş ağır sürece yükseltilmez.

## 5. Göreve özel süre bütçesi ve test sahipliği

Her Codex execution/correction/commit görevi, handoff'ta ChatGPT tarafından açıkça verilen execution time budget ile sınırlıdır. Global sabit süre varsayılanı yoktur. Yetkili kapsam ve süreye sığan inceleme, düzenleme, focused validation ve commit/push gereksiz ayrı mikro adımlara bölünmez; publication kapıları korunur.

Bütçe dolduğunda Codex durur:

- yeni yaklaşım başlatılmaz;
- kapsam genişletilmez;
- mevcut çalışma güvenle korunur; tamamlanan değişiklik, exact blocker ve kalan tek adım raporlanır.

Repository-local terminal, automated test, analyzer ve build/APK hazırlığı Codex tarafından, yetkili görevin minimum yeterli kapsamıyla yürütülür. Fatih PowerShell/terminal/Git/Flutter/test/analyzer/build komutu çalıştırmaz; kendisine bu komutlar hazırlanmaz veya verilmez. Fatih yalnız manuel ürün/device kabulünü ve nihai görsel/davranış PASS/FAIL kararını verir. Emulator/ADB/device execution yalnız exact package, cihaz ve veri-koruma sınırıyla açık owner delegasyonunda yapılabilir; MAIN/Acceptance/Debug ve mevcut veri güvenliği sınırları korunur.

Codex kaynak düzenleme, format, diff ve Git kapsam kontrollerini yapar; automated execution sonuçlarını raporlar. Fatih'e yalnız manuel kabul adımları verilir; nihai davranış kabulü Codex'e devredilmez.

Aynı source revision üzerinde geçen test tekrarlanmaz. Full suite her mikro adımda değil, birleşik milestone veya release kapısında çalıştırılır.

## 6. Değişmez güvenlik sınırları

- CSE owner-only, local-first ve mobile-first kalır.
- Gerçek kullanıcı data root'u açık CRITICAL authority olmadan okunmaz/değiştirilmez.
- Production/debug paketleri sıradan automation tarafından başlatılmaz, temizlenmez veya mutate edilmez.
- Stable identity, optimistic revision, append-only event/history, transaction, backup/restore ve attachment bütünlüğü korunur.
- Force-push, destructive reset/clean/stash, hard-delete ve beklenmeyen kullanıcı değişikliğinin üzerine yazma yasaktır.
- Beklenmeyen tracked/untracked değişiklikte işlem durur; otomatik temizleme yapılmaz.
- Ready, merge, Issue closure, release/store ve destructive production işlemleri owner onayı gerektirir.

## 7. Git, publication ve Issue disposition

- FAST: Codex automated PASS ve gerekiyorsa Fatih manuel/device PASS sonrası tek kısa branch'te küçük commit ve normal push; current `master` ruleset'i PR istiyorsa tek minimal Draft PR, owner-approved squash merge ve `master` sync.
- STANDARD: en fazla bir aktif production branch/PR; squash merge varsayılanı.
- CRITICAL: Issue'ya özel branch/PR/review zinciri.
- Force-push yapılmaz.
- Stacked PR oluşturulmaz.
- Protokol kabul edildiğinde zaten açık olan legacy/stacked production PR'lar bir defalık geçiş kuyruğudur; yeni stack açma yetkisi vermez. Kuyruk çözülene kadar yeni production branch açılmaz; mevcut PR'lar current master'a birer birer uyarlanır ve Ready/merge/close yalnız owner kararıyla yürütülür.
- Cihaz APK'sı mümkün olduğunda güncel birleşik master'dan üretilir.
- Merge sonrası local master bir sonraki local işten önce `--ff-only` senkronlanır.
- Tek amaçlı implementation Issue'su PR ile bütünüyle sonuçlanıyorsa PR body `Closes #...` kullanır.
- Parent, umbrella, manuel acceptance, release veya devam işi içeren Issue'lar `Refs #...` kullanır ve açık kalır.
- Owner merge onayı yalnız incelenen PR body'de açıkça `Closes` ile belirtilen Issue kapanışını da kapsar; belirsizlikte otomatik Issue closure yapılmaz.

## 8. Evidence ve çıktı

FAST completion en fazla şu bilgileri taşır:

```text
Değişen davranış: <tek cümle>
Değişen dosyalar: <liste>
Codex kontrolleri: format / diff-check
Codex automated validation: PENDING | PASS | FAIL
Fatih manuel kabulü: GEREKMİYOR (<gerekçe>) | PENDING | PASS | FAIL
Commit/push: yapılmadı | <sha>
PR: GEREKMİYOR | <numara>
Issue disposition: YOK | Closes #... | Refs #...
```

STANDARD sonucu kısa Issue/PR kaydıdır. CRITICAL ayrıntılı provenance taşıyabilir.

Aynı bilgi Issue, comment, task, result, state ve PR body içinde tekrar edilmez.

ChatGPT kullanıcıya teslim ettiği her yanıtta önce sade Türkçeyle şunları anlatır:

- ne yaptığını;
- bunun uygulama veya çalışma açısından ne anlama geldiğini;
- işlemin başarılı mı, eksik mi, engelli mi olduğunu.

SHA, branch, divergence, allowlist, YAML ve benzeri teknik kanıtlar bu açıklamadan sonra ikinci katmanda verilir. Teknik terim gerekliyse hemen günlük dilde karşılığı açıklanır. Ham Codex çıktısı ana cevap olarak kopyalanmaz; ChatGPT sonucu owner'ın tek okumada anlayacağı dile çevirir. Kısalık, anlaşılabilirliği bozacak kadar bilgi eksiltme gerekçesi değildir.

## 9. Ana karar

> Non-CRITICAL işte göreve özel süre bütçesiyle one-pass teslim, tek focused validation ve yalnız gereken manuel kabul; publication current GitHub ruleset'inin izin verdiği en hafif branch/PR yoluyla yürür. Gerçek veri/release riskinde tam güvenlik süreci uygulanır. Ready/merge ve açıkça belirtilen Issue closure owner kapısında kalır.
