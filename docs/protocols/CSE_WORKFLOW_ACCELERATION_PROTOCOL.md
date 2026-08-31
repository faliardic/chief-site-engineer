# CSE Workflow Acceleration Protocol — Development Process v3

**Belge türü:** Bağlayıcı execution / review / publication protokolü  
**Geçerlilik tarihi:** 2026-08-31  
**Kaynak owner kararı:** Issue #548  
**Kapsam:** Bütün yeni CSE feature, correction, review, publication, resume ve new-chat işlemleri

Bu protokolün amacı güvenliği azaltmak değil, güvenlik mekanizmasının geliştirme hızının önüne geçmesini engellemektir.

> CSE'de varsayılan süreç maksimum kanıt değil, riske uygun minimum yeterli kanıt üretir.

Bu belge workflow lane seçimi, retry/correction bütçesi, local-vs-CI test sorumluluğu, evidence yoğunluğu ve review derinliği konularında daha eski ağır süreç tariflerinden önceliklidir.

Değişmez üst sınırlar:

- `CSE_UNIFIED_PROJECT_SOURCE.md` ürün/veri ilkelerinde otoritedir;
- `CSE_PROJECT_INSTRUCTIONS.md` repository ve data safety'de otoritedir;
- `CSE_MODEL_REASONING_ROUTING_POLICY.md` model routing'de otoritedir;
- exact Issue scope/allowlist korunur;
- schema/migration/backup/version/permission/platform/user-data authority kendiliğinden genişlemez;
- Ready, merge, release/store ve destructive production işlemleri owner onayı olmadan yapılmaz.

---

## 1. Zorunlu process lane seçimi

Her yeni teknik Issue üç lane'den **yalnız birini** seçer.

### FAST

Kullanım alanı:

- documentation-only değişiklik;
- metin, label, icon, spacing, layout;
- küçük UI state/empty/error görünümü;
- basit navigation veya route wiring;
- mevcut contract'ı değiştirmeyen selector/context aktarımı;
- küçük test-harness veya deterministic format düzeltmesi;
- persistence/data-integrity/release-critical etkisi olmayan dar presentation işi.

Varsayılan review seviyesi: `R1-R2`.

Varsayılan yürütme:

```text
Issue
→ tek implementation window
→ source-level checks
→ commit/push/Draft PR
→ PR CI
→ kısa review
→ owner merge
```

FAST iş için ayrı one-shot execution authority yorumu gerekmez. Issue body + bu protokol standing authority'dir.

### STANDARD

Kullanım alanı:

- birden fazla ekran/modül arasında behavior değişikliği;
- project-context/session continuity;
- mevcut feature mutation'ının yeni presentation akışında kullanılması;
- source-compatible constructor/callback contract genişlemesi;
- orta ölçekli feature behavior;
- persistence/release contract'ı değiştirmeyen cross-module değişiklik.

Varsayılan review seviyesi: `R3`.

Varsayılan yürütme FAST ile aynıdır; yalnız source review ve gerekirse dar targeted local check daha dikkatli yapılır.

STANDARD iş sırf birden fazla dosya değiştirdiği veya kullanıcıya görünür olduğu için `R4` yapılmaz.

### CRITICAL

Aşağıdaki tetiklerden biri varsa kullanılır:

- schema veya migration;
- backup/restore formatı veya restore davranışı;
- destructive data operation;
- stable identity / optimistic revision / transaction / append-only history değişikliği;
- attachment/data integrity veya corruption riski;
- security/privacy-sensitive data handling;
- permission, signing, application ID, platform/runtime production ayarı;
- release artifact/store gate;
- background/reboot engine;
- DWG conversion/runtime katmanında kullanıcı dosyası veya data-loss riski;
- gerçek kullanıcı data root'una kontrollü erişim;
- failure halinde geri dönüşü zor veya veri kaybettirebilecek değişiklik.

Varsayılan review seviyesi: `R4 / R4+`.

CRITICAL işte Issue'a özel ağır gate, integration/device/release zinciri yazılabilir.

---

## 2. Lane seçme kuralı

Her zaman **riski karşılayan en hafif lane** seçilir.

Şunlar tek başına CRITICAL gerekçesi değildir:

- dosya sayısının fazla olması;
- widget testinin karmaşık olması;
- project selector değişikliği;
- navigation değişikliği;
- callback eklenmesi;
- birden fazla ekranın aynı session state'i kullanması;
- daha önce benzer işlerin R4 yapılmış olması.

R4 / ağır fail-closed process yalnız somut CRITICAL trigger ile gerekçelendirilebilir.

Belirsizlik varsa önce STANDARD seçilir; source incelemesinde gerçek CRITICAL trigger bulunursa lane yükseltilir ve owner'a kısa gerekçe bildirilir.

---

## 3. FAST / STANDARD standing execution authority

FAST ve STANDARD lane'lerde Issue açıldıktan sonra tekrar tekrar owner execution authority istenmez.

Issue şu bilgileri içerdiğinde execution authorized kabul edilir:

```text
Process lane
Goal / changed contract
Expected base
Allowed/protected paths
Critical exclusions
Publication boundary
```

Aynı scope içinde aşağıdakiler otomatik yetkilidir:

- implementation;
- deterministic formatting;
- test expectation/harness düzeltmesi;
- analyzer/syntax düzeltmesi;
- aynı changed-contract içindeki dar source correction;
- PR evidence güncellemesi.

Yeni authority gereken durumlar yalnız bölüm 9'daki escalation koşullarıdır.

---

## 4. Correction bütçesi

FAST ve STANDARD için varsayılan:

```text
primary implementation: 1
same-scope correction rounds: up to 2
environment-only retry: up to 1 after exact root cause
new owner authority inside same scope: 0
```

Bir correction round, completed validation/review sonucunda bulunan aynı-scope blocker'ların **tek seferde topluca** düzeltilmesidir.

Aşağıdakiler ayrı authority gerektirmez:

- format boundary;
- test harness migration;
- stale widget key;
- compile/analyzer defect;
- allowlist içindeki fail-closed source bug;
- review sırasında bulunan aynı contract'a ait dar behavior bug.

İki correction round biter ve blocker sürerse owner escalation yapılır.

CRITICAL retry/correction bütçesi Issue'a özel olabilir.

---

## 5. Local doğrulama ile PR CI'nın ayrılması

CSE mobile PR'larında mevcut GitHub `Flutter PR` workflow'u şunları zaten çalıştırır:

- Dart format check;
- `flutter analyze`;
- full `flutter test --no-pub`.

Bu nedenle FAST/STANDARD işlerde Codex aynı geniş zinciri local olarak tekrar etmez.

### FAST local default

- exact scope/allowlist;
- changed-path review;
- deterministic format/syntax;
- `git diff --check`;
- protected drift;
- yalnız gerçekten gerekiyorsa çok dar compile/source check.

### STANDARD local default

FAST kontrollerine ek olarak, cross-module riskini erken yakalamak için **yalnız material faydası varsa** tek targeted check çalıştırılabilir.

Yerelde full Flutter suite, geniş regression paketi ve tekrar analyzer çalıştırmak varsayılan değildir.

### PR CI

Draft PR açıldıktan sonra geniş Flutter otomasyonu CI'nın sorumluluğudur.

CI failure olursa:

1. bütün failure'lar tek seferde okunur;
2. scope içindekiler tek correction round'da düzeltilir;
3. branch push edilir;
4. CI yeniden çalışır.

Her CI failure için yeni owner authority yazılmaz.

### CRITICAL

Issue'ın riskine göre gerekli local focused/integration/device/release gate ayrıca tanımlanır; PR CI bunun yerine geçmeyebilir.

---

## 6. Owner-led manual test politikası

Implementation verification ile field/manual acceptance ayrı kalır.

User-visible feature sonunda stable test ID'leri Issue #479'a kaydedilir:

```text
MT-<FEATURE_ISSUE>-001
MT-<FEATURE_ISSUE>-002
...
```

Durumlar:

```text
PENDING
PASS
FAIL
PARTIAL
DEFERRED
N/A
```

Manual test `PENDING` veya `DEFERRED` olması FAST/STANDARD development progression'ını otomatik bloke etmez.

Test edilmemiş behavior `VERIFIED`, `FIELD_ACCEPTED` veya `RELEASE_READY` diye sunulmaz.

Owner `MT-xxx PASS/FAIL` biçiminde kısa cevap verebilir; ChatGPT register'ı günceller.

---

## 7. Evidence yoğunluğu

Aynı bilgiyi Issue, task, result, PR body ve PR comment içinde uzun uzun tekrar etmek yasaktır.

### FAST

Kanonik evidence:

- Issue;
- PR diff;
- PR CI;
- gerekirse kısa Issue/PR sonucu.

`.cse` task/result yalnız local Codex yürütmesi gerçekten kullanılıyorsa veya Issue özel olarak istiyorsa gerekir; kronolojik uzun rapor yazılmaz.

### STANDARD

Kısa `.cse` task/result kullanılabilir/istenebilir; hedef 15-40 satırlık structured summary'dir.

Yeterli kayıt:

```yaml
issue: NNN
process_lane: STANDARD
base: <sha>
head: <sha>
changed_paths: [...]
local_checks: [...]
ci: PASS|FAIL|PENDING
manual_tests: PENDING|...
corrections_used: 0..2
pr: <number>
```

### CRITICAL

Tam chronology, provenance ve risk evidence tutulabilir.

---

## 8. Review mimarisi

ChatGPT review sonucu varsayılan olarak kısa olur.

FAST:

```text
PASS
```

veya

```text
BLOCKER
- <exact defect>
- <required narrow correction>
```

STANDARD:

```text
PASS — no blocking finding
```

veya blocker'ların tamamı tek listede verilir.

CRITICAL review ayrıntılı R4 evidence kullanabilir.

Review sırasında format, harness veya aynı scope source defect bulunursa FAST/STANDARD correction budget kullanılır; yeni governance turu açılmaz.

---

## 9. Anında escalation / CRITICAL'e yükseltme

Aşağıdakilerden biri oluşursa normal FAST/STANDARD execution durur:

- allowlist veya product scope genişlemesi gerekiyor;
- yeni owner product/design kararı gerekiyor;
- schema/migration/backup/version/permission/signing/platform değişikliği ortaya çıkıyor;
- production/debug/gerçek kullanıcı data riski doğuyor;
- stable identity/transaction/event/history/integrity/security contract etkileniyor;
- destructive/force/uninstall/production clear-data gerekiyor;
- DWG/user-file conversion değişikliği data-loss/corruption riski taşıyor;
- root cause aynı scope source correction'a indirgenemiyor;
- iki correction round tüketildi;
- artifact provenance belirsiz.

Escalation mesajı kısa olmalıdır:

```text
STOP — CRITICAL ESCALATION
Trigger: <one sentence>
Required new authority/scope: <one sentence>
```

---

## 10. Publication ve merge

FAST/STANDARD:

1. source-level checks;
2. commit + push;
3. Draft PR;
4. PR CI;
5. ChatGPT short review;
6. owner merge approval;
7. squash merge;
8. sonraki roadmap item.

Manual testler PENDING/DEFERRED kalabilir.

Ready/merge owner onayı gerektirir; ancak owner açıkça `merge et`, `ready`, `devam et ve merge et` veya eşdeğer karar verdiğinde tekrar ayrı authority aranmaz.

CRITICAL publication Issue'a özel olabilir.

---

## 11. Issue/task minimum alanları

FAST/STANDARD için ağır instruction blokları yerine:

```text
Process lane:
Goal / changed contract:
Expected base:
Allowed paths:
Protected / critical exclusions:
Local checks:
CI expectation:
Manual test register:
Correction budget: 2
Publication boundary:
```

CRITICAL Issue eski ayrıntılı validation/provenance alanlarını kullanabilir.

---

## 12. New-chat / resume davranışı

Yeni sohbet:

1. `AGENTS.md` ve bu protokolü okur;
2. current GitHub Issue/PR/master durumunu bulur;
3. process lane'i okur;
4. aynı issue resume ise önceki uzun authority metnini yeniden üretmez;
5. kullanıcı `devam` dediğinde current lane'e göre doğrudan sıradaki gerçek işi yapar.

FAST/STANDARD issue'da sırf eski bir authority yorumunda ağır gate yazıyor diye eski ceremony yeniden canlandırılmaz; **daha yeni owner workflow kararı olarak bu protokol workflow/test/retry/evidence yoğunluğunu override eder**. Product scope, allowlist ve critical exclusions override edilmez.

---

## 13. Current migration rule — Issue #547 ve sonrası

Issue #547 ve merge edilmemiş sonraki ordinary UI/context işleri varsayılan olarak bu protokole taşınır.

#547 için:

```yaml
process_lane: STANDARD
product_scope: unchanged
allowlist: unchanged
attendance_protection: unchanged
local_full_flutter_gate_required: false
pr_ci_is_broad_gate: true
same_scope_corrections_without_new_authority: 2
review_level: R3
```

Somut CRITICAL trigger çıkmadıkça yeni R4 one-shot authority zinciri açılmaz.

---

## 14. Başarı ölçütleri

```text
ordinary UI/context issue uses R4 ceremony: 0
new owner authority for same-scope format/harness correction: 0
local full Flutter suite duplicated before PR CI: 0 by default
same-scope blockers grouped into one correction round: 100%
manual test backlog preserved: 100%
critical data/release changes still use heavy process: 100%
```

---

## 15. Ana cümle

> CSE'nin varsayılan çalışma döngüsü Issue → implementation → Draft PR → CI → kısa review → owner merge'dür. FAST/STANDARD işler ağır governance zincirine dönüştürülmez. Ağır fail-closed süreç yalnız gerçek CRITICAL risklerde kullanılır.
