# CSE Workflow Acceleration Protocol — v4

**Belge türü:** Bağlayıcı execution, correction ve publication protokolü
**Geçerlilik tarihi:** 2026-09-02

Amaç maksimum kanıt üretmek değil, değişen sözleşmenin riskini karşılayan en hafif süreçle güvenli ürünü hızla master'a taşımaktır.

Bu belge workflow lane, correction, evidence ve publication konularında eski ağır Issue/authority tariflerinden önceliklidir. Ürün/veri ilkeleri ve kritik safety sınırları override edilmez.

## 0. Zorunlu aktör dispatch'i

Her talepte lane'den önce sıradaki tek aksiyon ve aktör seçilir:

| İş | Aktör |
|---|---|
| GitHub okuma, plan, Issue/PR koordinasyonu, review, owner-approved Ready/merge | ChatGPT |
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

## 2. Beş dakikalık execution

Her Codex invocation yalnız bir bounded outcome üretir ve 5 dakikada hard-stop olur.

Süre dolduğunda:

- yeni yöntem denenmez;
- başka davranışa geçilmez;
- kapsam genişletilmez;
- tamamlanan iş, blocker ve kalan tek adım raporlanır.

Büyük STANDARD/CRITICAL görevler birden fazla bağımsız 5 dakikalık mikro adıma bölünebilir. Aynı anda yalnız bir production adımı yürür.

## 3. Execution ve kabul sahipliği

Repository-local terminal, automated test, analyzer ve build/APK hazırlığı Codex tarafından, yetkili görevin minimum yeterli kapsamıyla yürütülür. Fatih PowerShell/terminal/Git/Flutter/test/analyzer/build komutu çalıştırmaz; kendisine bu komutlar hazırlanmaz veya verilmez. Fatih yalnız manuel ürün/device kabulünü ve nihai görsel/davranış PASS/FAIL kararını verir. Emulator/ADB/device execution yalnız exact package, cihaz ve veri-koruma sınırıyla açık owner delegasyonunda yapılabilir; MAIN/Acceptance/Debug ve mevcut veri güvenliği sınırları korunur.

Codex source edit, format, changed-path review, `git diff --check`, protected drift ve minimum yeterli automated doğrulamayı yapar; sonuçları raporlar. Fatih'e yalnız manuel kabul adımları verilir.

## 4. FAST akışı

```text
clean synchronized master
→ one micro edit
→ format/diff-check
→ Codex automated validation
→ Fatih manuel kabulü
→ PASS
→ small commit/push
→ next micro step
```

FAST için varsayılan olarak yoktur:

- Issue;
- remote feature branch;
- PR;
- GitHub instruction comment;
- `.cse` task/result/state;
- routing/execution YAML;
- bağımsız review;
- CI bekleme.

Fatih PASS bildirmeden commit/push yapılmaz. FAIL/PENDING durumunda yeni işe geçilmez.

## 5. STANDARD akışı

```text
short task/Issue
→ one short-lived branch
→ bounded micro edits
→ Codex automated validation
→ Fatih manuel kabulü
→ concise evidence
→ optional single Draft PR/review
→ owner merge
→ master sync
```

Kurallar:

- aynı anda en fazla bir production branch/PR;
- stacked PR yok;
- `.cse` ve routing YAML varsayılan değil;
- Issue/PR sonucu 10–15 satırı hedefler;
- bağımsız review yalnız material fayda varsa;
- current iş master'a alınmadan sonraki feature branch açılmaz.

### Protokol geçişi

Protokol kabul edildiğinde zaten açık olan legacy/stacked production PR'lar bir defalık geçiş kuyruğudur. Bu istisna yeni branch veya stack açma yetkisi değildir.

- Kuyruk çözülene kadar yeni production branch açılmaz.
- Mevcut PR'lar current master'a birer birer uyarlanır.
- Her PR için test ve blocker kanıtı yeniden değerlendirilir.
- Ready, merge veya close işlemi owner'ın ayrı kararıyla yapılır.
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

Ready, merge, release/store ve destructive production işlemi owner onayı gerektirir.

## 7. Correction

FAST/STANDARD same-scope hata için yeni owner authority gerekmez.

Her correction ayrı 5 dakikalık mikro adımdır. Aynı hata için:

- exact root cause belirlenir;
- tek dar correction yapılır;
- Codex yalnız gerekli automated doğrulamayı çalıştırır; Fatih gerekiyorsa manuel kabulü yeniden değerlendirir.

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
Fatih manual acceptance status
commit/push
```

STANDARD kısa Issue/PR summary kullanır.

CRITICAL tam provenance tutabilir.

Aynı bilgi Issue, comment, task, result, state ve PR body içinde tekrarlanmaz.

## 9. Publication

- FAST: user PASS sonrası normal commit/push.
- STANDARD: tek branch; gerekiyorsa tek Draft PR; squash merge varsayılanı.
- CRITICAL: Issue'ya özel publication ve review zinciri.
- Force-push yok.
- Stacked PR yok.
- APK mümkün olduğunda birleşik güncel master'dan üretilir.

Owner `merge et`, `ready` veya eşdeğer açık karar verdiğinde ayrıca authority aranmaz; ancak test/critical blocker varsa ilerlenmez.

## 10. Escalation

Normal akış şu tetiklerden birinde durur:

- yeni kritik sözleşme;
- gerçek kullanıcı verisi;
- destructive işlem;
- beklenmeyen path değişikliği;
- source truth belirsizliği;
- çözümün mevcut scope'u aşması.

Mesaj kısa olur:

```text
STOP — CRITICAL ESCALATION
Trigger: <neden>
Required decision: <tek karar>
```

## 11. Başarı ölçütleri

- FAST Codex işlemi 5 dakikanın altında: %100
- FAST Issue/PR/`.cse`: 0
- Codex manuel ürün kabulü kararı: 0
- Fatih'e terminal execution görevi/komutu verme: 0
- exact owner delegasyonu olmadan Codex emulator/ADB/device invocation: 0
- user PASS olmadan FAST commit/push: 0
- stacked PR: 0
- aynı anda production PR: en fazla 1
- CRITICAL işte ağır güvenlik süreci: %100

## 12. Ana karar

> CSE'nin varsayılan döngüsü küçük işte mikro edit, Codex automated doğrulaması ve owner manuel kabulüdür. Branch/PR/review yalnız değişen risk bunu gerektirdiğinde kullanılır. Ağır süreç gerçek veri, integrity ve release riskine ayrılır.
