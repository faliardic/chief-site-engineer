# CSE Workflow Acceleration Protocol — v4

**Belge türü:** Bağlayıcı execution, correction ve publication protokolü
**Geçerlilik tarihi:** 2026-09-02

Amaç maksimum kanıt üretmek değil, değişen sözleşmenin riskini karşılayan en hafif süreçle güvenli ürünü hızla master'a taşımaktır.

Bu belge workflow lane, correction, evidence ve publication konularında eski ağır Issue/authority tariflerinden önceliklidir. Ürün/veri ilkeleri ve kritik safety sınırları override edilmez.

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

## 3. Test sahipliği

Codex test, analyzer, build, emulator, ADB veya device işlemi çalıştırmaz.

Codex yalnız:

- exact source edit;
- değişen dosyalarda format;
- changed-path diff review;
- `git diff --check`;
- protected path ve kritik contract drift kontrolü

yapar ve Fatih'e exact doğrulama komutlarını verir.

Fatih focused/full test, analyzer, build, APK/install, device ve ürün kabulünü çalıştırır.

## 4. FAST akışı

```text
clean synchronized master
→ one micro edit
→ format/diff-check
→ Fatih validation
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
→ Fatih validation
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
- Fatih yeniden gerekli testi çalıştırır.

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
Fatih test status
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
- Codex test/analyzer/build/device invocation: 0
- user PASS olmadan FAST commit/push: 0
- stacked PR: 0
- aynı anda production PR: en fazla 1
- CRITICAL işte ağır güvenlik süreci: %100

## 12. Ana karar

> CSE'nin varsayılan döngüsü küçük işte mikro edit ve owner testidir. Branch/PR/review yalnız değişen risk bunu gerektirdiğinde kullanılır. Ağır süreç gerçek veri, integrity ve release riskine ayrılır.
