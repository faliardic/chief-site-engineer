# CSE Workflow Acceleration Protocol — v7

**Belge türü:** Bağlayıcı execution, correction ve publication protokolü
**Geçerlilik tarihi:** 2026-09-04

Amaç maksimum kanıt üretmek değil, değişen sözleşmenin riskini karşılayan en hafif süreçle güvenli ürünü hızla master'a taşımaktır.

Bu belge workflow lane, correction, evidence ve publication konularında eski ağır Issue/authority tariflerinden önceliklidir. Ürün/veri ilkeleri ve kritik safety sınırları override edilmez.

## 0. Zorunlu aktör dispatch'i

Her talepte lane'den önce sıradaki tek aksiyon ve aktör seçilir:

| İş | Aktör |
|---|---|
| GitHub okuma, plan, Issue/PR koordinasyonu, review, gate doğrulaması ve standing owner yetkisiyle otomatik Ready/squash merge | ChatGPT |
| Repository/local dosya değişikliği, format/diff, local Git, commit/push | Codex |
| Repository-local terminal, automated test/analyzer ve build/APK hazırlığı | Codex |
| Manuel ürün/device kabulü ve nihai davranış PASS/FAIL | Fatih; terminal komutu çalıştırmaz |
| Emulator/ADB/device execution | Yalnız exact package/device/data-safety owner delegasyonuyla Codex |

Codex gereken işte ChatGPT kullanıcının `Codex ile çalış` demesini beklemez. `Sıradaki aktör: Codex` der ve current Issue/protokolü kopyalamadan yalnız goal, allowlist, stop ve handoff'u içeren 10–15 satırlık exact görev verir.

ChatGPT'ın kendi yetkisindeki işlem mevcut owner kararıyla yapılabiliyorsa ayrıca `devam` istenmez. Her kullanıcıya teslim edilen sonuç `Sıradaki aksiyon — <aktör>: <tek uygulanabilir talimat>.` satırıyla biter; kalan iş yoksa aktör `Yok` olur.

## 1. Lane seçimi

Her iş yalnız bir lane seçer.

### FAST

Dar docs/UI/presentation/navigation işi; persistence, identity, user-data veya release-critical contract değişmez.

Örnekler:

- documentation-only;
- text, label, icon, tooltip;
- spacing/layout/empty/error state;
- mevcut contract'ı değiştirmeyen selector/context aktarımı;
- küçük deterministic harness düzeltmesi.

### STANDARD

Birden fazla ekran/modül veya session/context davranışı değişir; persistence/release-critical contract değişmez.

Örnekler:

- project-context continuity;
- cross-module callback/constructor;
- mevcut mutation'ın yeni akışta kullanılması;
- orta ölçekli feature behavior.

### CRITICAL

Aşağıdakilerden biri vardır:

- schema/migration veya backup/restore;
- stable identity/revision/transaction/event/history;
- attachment veya kullanıcı dosyası bütünlüğü;
- destructive işlem veya gerçek kullanıcı verisi;
- security/privacy/permission/signing/application ID;
- background/reboot engine;
- DWG dönüşümünde data-loss/corruption;
- release/store artifact'i.

Dosya sayısı, widget test karmaşıklığı, navigation veya callback tek başına CRITICAL gerekçesi değildir.

## 2. Göreve özel execution time budget

Her Codex handoff'u ChatGPT'nin kapsam, risk, beklenen validation/build/device işi ve mevcut blocker'a göre seçtiği açık `Execution time budget: <süre>` alanını içerir. Global sabit süre varsayılanı yoktur. Codex bu bütçe içinde tek bounded outcome üretir; yetkili inceleme, edit/fix, focused validation ve commit/push mümkünse aynı adımda tamamlanır.

Süre dolduğunda:

- yeni yöntem denenmez;
- başka davranışa geçilmez;
- kapsam genişletilmez;
- Codex durur ve mevcut çalışmayı güvenle korur; tamamlanan iş, exact blocker ve kalan tek adım raporlanır.

Görev ancak kapsam veya gerçek süre ihtiyacı gerektiriyorsa açık bütçeli alt adımlara bölünür. Codex bütçeyi kendiliğinden uzatmaz. Aynı anda yalnız bir production adımı yürür. Süre bütçesi CRITICAL veya publication kapılarını gevşetmez.

## 3. Execution ve kabul sahipliği

Repository-local terminal, automated test, analyzer ve build/APK hazırlığı Codex tarafından, yetkili görevin minimum yeterli kapsamıyla yürütülür. Fatih PowerShell/terminal/Git/Flutter/test/analyzer/build komutu çalıştırmaz; kendisine bu komutlar hazırlanmaz veya verilmez. Fatih yalnız manuel ürün/device kabulünü ve nihai görsel/davranış PASS/FAIL kararını verir. Emulator/ADB/device execution yalnız exact package, cihaz ve veri-koruma sınırıyla açık owner delegasyonunda yapılabilir; MAIN/Acceptance/Debug ve mevcut veri güvenliği sınırları korunur.

Codex source edit, format, changed-path review, `git diff --check`, protected drift ve minimum yeterli automated doğrulamayı yapar; sonuçları raporlar. Fatih'e yalnız manuel kabul adımları verilir.

### Non-CRITICAL one-pass teslim

FAST/STANDARD bug ve küçük/orta feature işinin varsayılanı:

`reproduce once -> fix -> one focused validation -> only-needed manual/device check -> gated automatic Ready/squash merge`

- Mevcut doğrudan ve tekrarlanabilir owner/device repro kanıtı ilk adımı karşılar; sırf automated FAIL üretmek için yeniden repro aranmaz. Source root cause yeterince belirlenmişse düzeltme başlayabilir.
- Bir başarısız repro denemesinden sonra source/runtime diagnosis veya mevcut en güçlü kanıta geçilir. Kararı değiştirmeyen diagnostic, harness ve test döngüleri yasaktır.
- Owner/device kanıtı, gerçek davranışı temsil edemeyen yapay test harness'inden üstündür. Widget/fake test PASS'i cihaz FAIL'ini geçersiz kılmaz; harness'in hatayı üretememesi tek başına fix blocker'ı olmaz.
- Düzeltme için tek focused automated validation çalıştırılır; docs-only işte minimum docs kontrolleri bu doğrulamayı karşılar. Analyzer yalnız material ihtiyaç varsa eklenir. Değişmeyen source üzerinde geçen test tekrarlanmaz.
- Manuel/device kabul yalnız runtime'a özgü davranışta veya owner açıkça istediğinde, değişen yol için bir kez yapılır. Gerekmiyorsa gerekçesiyle `GEREKMİYOR` yazılır; Codex automated PASS sonrası yetkili commit/push manuel PASS beklemez.
- Gereken manuel/device kabul Fatih'in PASS/FAIL kapısındadır. Gerekli validation/kabul FAIL veya PENDING ise commit/push yapılmaz; düzeltme §7'ye göre yürür. Required review ve task-specific validation/manual kapıları PASS veya açıkça GEREKMİYOR olduktan ve blocker, REQUEST_CHANGES, scope/allowlist/base/head drift, conflict veya mergeability sorunu bulunmadıktan sonra ChatGPT standing owner yetkisiyle PR'yi ayrıca Fatih'e sormadan otomatik Ready yapar ve squash merge eder. CRITICAL evidence ve Issue-specific gate'ler korunur; release/store ile destructive production/device/data işlemleri ayrı açık owner onayı ister.

## 4. FAST akışı

```text
clean synchronized master
→ one short-lived branch
→ mevcut kanıtı kullan veya bir kez reproduce et
→ fix / implement
→ format/diff-check + tek focused automated validation
→ yalnız gerekiyorsa Fatih manuel/device PASS
→ small commit + normal branch push
→ current master ruleset PR istiyorsa minimal Draft PR
→ required review/gate PASS sonrası automatic Ready/squash merge
→ master sync
→ next task
```

FAST için varsayılan olarak yoktur:

- Issue;
- GitHub instruction comment;
- `.cse` task/result/state;
- routing/execution YAML;
- bağımsız review;
- geniş CI, full suite veya cihaz kontrolü.

Current GitHub `master` ruleset'i PR gerektiriyorsa tek kısa ömürlü branch ve tek minimal Draft PR kullanılır. Bu repository zorunluluğu FAST işi STANDARD'a yükseltmez ve ek Issue/evidence/review töreni doğurmaz.

Codex automated PASS gerekir. Manuel/device kabul gerekiyorsa ayrıca Fatih PASS beklenir; gerekmiyorsa bu kapı publication'ı bekletmez. Gerekli kontrol FAIL/PENDING durumundayken yeni işe geçilmez.

## 5. STANDARD akışı

```text
short task/Issue
→ one short-lived branch
→ mevcut kanıtı kullan veya bir kez reproduce et
→ fix / implement
→ tek focused automated validation
→ yalnız gerekiyorsa Fatih manuel/device PASS
→ yetkili commit/push + concise evidence
→ optional single Draft PR/review
→ required review/gate PASS sonrası automatic Ready/squash merge
→ master sync
```

Kurallar:

- aynı anda en fazla bir production branch/PR;
- stacked PR yok;
- `.cse` ve routing YAML varsayılan değil;
- Issue/PR sonucu 10–15 satırı hedefler;
- bağımsız review yalnız material fayda varsa;
- normalde ilk teslimden sonra en fazla bir same-scope correction turu; çözülmezse escalation;
- current iş master'a alınmadan sonraki feature branch açılmaz.

### Protokol geçişi

Protokol kabul edildiğinde zaten açık olan legacy/stacked production PR'lar bir defalık geçiş kuyruğudur. Bu istisna yeni branch veya stack açma yetkisi değildir.

- Kuyruk çözülene kadar yeni production branch açılmaz.
- Mevcut PR'lar current master'a birer birer uyarlanır.
- Her PR için test ve blocker kanıtı bu one-pass politikasıyla yeniden değerlendirilir; değişmeyen source üzerinde geçen test tekrarlanmaz.
- Her PR required review/validation/manual ve drift/mergeability kapılarından geçmeden Ready/merge edilmez; gate'ler geçince standing owner yetkisi otomatik uygulanır.
- Sabit PR numaraları bu kalıcı protokole yazılmaz.

## 6. CRITICAL akışı

CRITICAL iş exact Issue, allowlist, validation/compatibility/rollback contract, branch, Draft PR ve bağımsız review kullanır.

Gerekli olduğunda:

- `.cse` task/result provenance;
- migration/restore fixtures;
- integrity/FK/hash;
- device/release gate;
- artifact provenance;
- rollback planı

tutulur.

Issue'ya özel bütün validation/compatibility/manual kapıları PASS veya açıkça GEREKMİYOR olduktan ve blocker/drift/mergeability sorunu bulunmadıktan sonra standing owner yetkisi Ready/squash merge için uygulanır. Release/store ve destructive production/device/data işlemleri ayrı açık owner onayı gerektirir.

## 7. Correction

FAST/STANDARD same-scope hata için yeni owner authority gerekmez.

Correction mevcut yetkili kapsam ve execution time budget içine sığıyorsa aynı adımda tamamlanır; ayrı handoff gerekiyorsa ChatGPT açık yeni bütçe atar. STANDARD bug fix'te normalde ilk teslimden sonra en fazla bir same-scope correction turu yapılır; sorun sürüyorsa yeni diagnostic/test döngüsü yerine exact blocker ile escalation yapılır.

Aynı hata için:

- mevcut owner/device ve source kanıtıyla root cause yeterince belirlenir; deterministic automated FAIL önkoşulu konmaz;
- tek dar correction yapılır;
- Codex yalnız etkilenen focused doğrulamayı bir kez çalıştırır; analyzer ve Fatih'in manuel/device kabulü yalnız ihtiyaç varsa yeniden değerlendirilir.

Yeni authority yalnız şu durumlarda gerekir:

- scope/allowlist genişlemesi;
- yeni product/design kararı;
- CRITICAL trigger;
- kullanıcı verisi/destructive risk;
- root cause'un current scope'a indirgenememesi.

## 8. Evidence

FAST minimum:

```text
changed behavior
changed paths
format/diff-check
Codex automated validation status
Fatih manual acceptance status / GEREKMİYOR gerekçesi
commit/push
PR: GEREKMİYOR | <numara>
Issue disposition: YOK | Closes #... | Refs #...
```

STANDARD kısa Issue/PR summary kullanır.

CRITICAL tam provenance tutabilir.

Aynı bilgi Issue, comment, task, result, state ve PR body içinde tekrarlanmaz.

## 9. Publication ve Issue disposition

- FAST: Codex automated PASS ve yalnız gerekiyorsa Fatih manuel/device PASS sonrası tek kısa branch'te küçük commit ve normal push; current `master` ruleset'i PR istiyorsa tek minimal Draft PR ve required review/gate PASS sonrası ChatGPT'nin otomatik Ready/squash merge'i.
- STANDARD: tek branch; gerekiyorsa tek Draft PR; squash merge varsayılanı.
- CRITICAL: Issue'ya özel publication ve review zinciri.
- Force-push yok.
- Stacked PR yok.
- APK mümkün olduğunda birleşik güncel master'dan üretilir.
- Tek amaçlı implementation Issue'su PR merge'iyle bütünüyle tamamlanıyorsa PR body `Closes #...` kullanır.
- Parent, umbrella, manuel acceptance, release veya devam işi içeren Issue'lar `Refs #...` kullanır ve açık kalır.
- Standing merge yetkisi, yalnız incelenen PR body'de açıkça `Closes` ile belirtilen tek amaçlı Issue'nun merge ile otomatik kapanışını da kapsar. Belirsizlikte `Refs` kullanılır ve otomatik closure yapılmaz.

Standing owner yetkisi yalnız PR Ready/squash merge işlemini kapsar. Required herhangi bir gate FAIL/PENDING iken Ready/merge yapılmaz. Required source/diff review ile task-specific validation ve gerekli manual/device acceptance PASS veya açıkça GEREKMİYOR ise; blocker, REQUEST_CHANGES, scope/allowlist/base/head drift, conflict ve mergeability sorunu yoksa ChatGPT ayrıca Fatih'e sormadan PR'yi Ready yapar ve squash merge eder. CRITICAL PR'lerde Issue-specific validation/compatibility/manual kapılarının tamamı önce geçmelidir. Fatih bu standing yetkiyi sonraki bir owner talimatıyla iptal edebilir veya askıya alabilir. Merge öncesinde ChatGPT hangi Issue'ların kapanacağını ve hangilerinin açık kalacağını sade Türkçeyle belirtir.

## 10. Escalation

Normal akış şu tetiklerden birinde durur:

- yeni kritik sözleşme;
- gerçek kullanıcı verisi;
- destructive işlem;
- beklenmeyen path değişikliği;
- source truth belirsizliği;
- çözümün mevcut scope'u aşması;
- STANDARD same-scope correction turu sonunda sorunun sürmesi.

Mesaj kısa olur:

```text
STOP — CRITICAL ESCALATION
Trigger: <neden>
Required decision: <tek karar>
```

Yalnız STANDARD correction turu tükendiyse `STOP — CORRECTION ESCALATION` kullanılır; somut CRITICAL trigger yoksa lane yükseltilmez.

## 11. Başarı ölçütleri

- Her Codex handoff'unda ChatGPT-assigned explicit execution time budget: %100
- FAST Issue/`.cse`/routing YAML: 0
- FAST publication current master ruleset uyumu: %100
- FAST short-lived branch/minimal PR: ruleset gerektiriyorsa tam 1
- Codex manuel ürün kabulü kararı: 0
- Fatih'e terminal execution görevi/komutu verme: 0
- exact owner delegasyonu olmadan Codex emulator/ADB/device invocation: 0
- gerekli automated veya manuel/device PASS olmadan non-CRITICAL commit/push: 0
- stacked PR: 0
- aynı anda production PR: en fazla 1
- kararı değiştirmeyen diagnostic/test tekrarı: 0
- tamamlanmış tekil Issue için açık `Closes`; devam eden takip için açık `Refs`: %100
- CRITICAL işte ağır güvenlik süreci: %100

## 12. Ana karar

> Non-CRITICAL varsayılanı one-pass teslim, göreve özel süre bütçesi, tek focused validation ve yalnız gereken manuel/device kabulüdür. Publication current GitHub ruleset'inin izin verdiği en hafif branch/PR yoluyla yürür; required gate'ler geçince standing owner yetkisi Ready/squash merge ve açık `Closes` disposition'ı için otomatik uygulanır. CRITICAL veri/release güvenliği ile ayrı release/store ve destructive işlem onayları korunur.
