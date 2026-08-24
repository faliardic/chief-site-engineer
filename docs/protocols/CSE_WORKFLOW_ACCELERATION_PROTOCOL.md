# CSE Workflow Acceleration Protocol

**Belge türü:** Bağlayıcı execution/manual-verification addendum  
**Geçerlilik tarihi:** 2026-08-24  
**Kaynak karar:** Epic #385 owner kararları, Issue #477 ve kalıcı Manual Test Register #479  
**Kapsam:** Bütün yeni CSE feature, correction, publication, resume ve new-chat işlemleri

Bu protokol, CSE geliştirmesini güvenlikten ödün vermeden hızlandırır. Ana değişiklik şudur:

> Codex uygulama davranışını varsayılan olarak test etmez. Her özellik için numaralı manuel test listesi hazırlanır; testleri owner isterse yapar, istemezse sonraya bırakılır ve geliştirme devam eder.

Çelişki halinde:

- ürün/veri ilkelerinde `CSE_UNIFIED_PROJECT_SOURCE.md`;
- model routing'de `CSE_MODEL_REASONING_ROUTING_POLICY.md`;
- repository ve data safety'de `CSE_PROJECT_INSTRUCTIONS.md`;
- automated test zorunluluğu, manuel test listesi, test erteleme ve hızlandırılmış publication konularında bu protokol

uygulanır.

## 1. Ana karar

Feature implementation ve application verification iki ayrı akıştır:

```text
implementation
→ source-level checks
→ commit/push/Draft PR
→ numbered manual test list
→ next feature may continue

owner manual test — now or later
→ PASS / FAIL / PARTIAL / DEFERRED
→ register update
```

Test yapılmaması implementation'ı otomatik olarak durdurmaz. Ancak test edilmemiş davranış `VERIFIED`, `FIELD_ACCEPTED`, `PRODUCTION_READY` veya `RELEASE_READY` olarak sunulamaz.

## 2. Codex'in varsayılan olarak çalıştırmayacağı uygulama testleri

Owner ayrıca ve açıkça belirli bir gate istemedikçe Codex şunları çalıştırmaz:

- Flutter unit testleri;
- widget testleri;
- integration testleri;
- full Flutter test suite;
- emulator/device UI testleri;
- ADB acceptance;
- PowerShell scripted UI/selector acceptance;
- acceptance package install, launch, data clear veya lifecycle testi;
- uygulamayı davranış doğrulaması amacıyla çalıştırma;
- otomatik saha kabulü;
- APK/AAB build — owner artifact veya manuel test build'i istemedikçe.

Eski Issue veya protokolde “focused test”, “full suite”, “fresh build” veya “device acceptance” yazması, yeni owner kararı sonrasında otomatik yetki sayılmaz. Current owner açıkça yeniden istemedikçe bu kapılar `NOT_RUN — OWNER-LED MANUAL TEST POLICY` olarak kaydedilir.

## 3. Codex'in varsayılan source-level kontrolleri

Codex feature implementation sonunda yalnız riske uygun ve uygulamayı çalıştırmayan kontrolleri yapar:

- exact allowlist ve changed-path kontrolü;
- protected path drift;
- format ve syntax kontrolü;
- makul ve hızlı ise static analysis;
- `git diff --check`;
- schema/migration/backup/version/permission/platform drift;
- staged/branch/head/diff doğrulaması;
- commit/push/Draft PR kanıtı.

Static analysis uygulama davranış testi değildir. Bununla birlikte static analysis PASS sonucu kullanıcı akışının çalıştığı anlamına gelmez.

Owner isterse belirli bir automated gate ayrıca yetkilendirilebilir. Bu istisna test politikasını kalıcı olarak değiştirmez; yalnız yazılan exact gate için geçerlidir.

## 4. Her feature için numaralı manuel test listesi

Kalıcı kayıt yüzeyi:

```text
GitHub Issue #479 — CSE Manual Test Register
```

Her feature implementation sonunda ChatGPT:

1. feature Issue numarasını kullanır;
2. stable test ID'leri üretir;
3. adımları ve beklenen sonucu sade biçimde yazar;
4. ilgili commit/PR/build referansını ekler;
5. test durumlarını owner bildirimine göre günceller.

ID standardı:

```text
MT-<FEATURE_ISSUE>-001
MT-<FEATURE_ISSUE>-002
MT-<FEATURE_ISSUE>-003
```

Bir ID yayımlandıktan sonra başka davranış için yeniden kullanılmaz. Test kapsamı değişirse yeni ID eklenir veya eski ID açıklaması revision notuyla güncellenir.

## 5. Manuel test durumları

```text
PENDING   — owner henüz test etmedi veya karar vermedi
PASS      — owner beklenen davranışı doğruladı
FAIL      — owner hata bildirdi
PARTIAL   — listenin bir kısmı doğrulandı
DEFERRED  — owner testi sonraya bıraktı
N/A       — current kapsam/build için uygulanamaz
```

Owner kısa format kullanabilir:

```text
MT-476-003 PASS
MT-476-006 FAIL — +N gün görünmedi
MT-476 kalanlar DEFERRED
```

ChatGPT Issue #479'u günceller. Kullanıcıdan task/result/YAML/ADB evidence hazırlaması istenmez.

## 6. Testi erteleme ve geliştirmeye devam etme

Owner “sonraya bırak”, “test etmeyeceğim”, “devam et” veya eşdeğer karar verirse:

- ilgili MT kayıtları `DEFERRED` yapılır;
- feature `IMPLEMENTED — MANUAL TEST DEFERRED` olarak kaydedilir;
- Draft PR, review, merge ve sonraki feature owner kararına göre ilerleyebilir;
- açık test backlog'u Issue #479'da korunur;
- ileride aynı stable test ID'leriyle devam edilir.

Manual test `PENDING` veya `DEFERRED` olması fail-closed nedeni değildir.

Yüksek riskli schema/migration/backup/security değişikliğinde de owner test erteleme kararı verebilir; ancak completion ve PR açıkça `UNVERIFIED HIGH-RISK BEHAVIOR` yazar. Release/store/public-production ilanı ayrıca owner kararı olmadan yapılmaz.

## 7. Implementation ve verification status

Her feature iki ayrı status taşır:

```text
implementation_status:
  NOT_STARTED
  IN_PROGRESS
  IMPLEMENTED
  MERGED

manual_test_status:
  PENDING
  PARTIAL
  PASS
  FAIL
  DEFERRED
```

Örnek:

```text
implementation_status: IMPLEMENTED
manual_test_status: DEFERRED
claim: IMPLEMENTED — MANUAL TEST DEFERRED
```

Codex veya ChatGPT test yapılmadığı halde `PASS` yazamaz. Eski automated test evidence'ı farklı source revision içinse current owner test sonucu yerine geçmez.

## 8. FAIL sonucunun yönetimi

Owner bir MT maddesine `FAIL` bildirirse:

1. ChatGPT Issue #479 kaydını günceller;
2. feature Issue/PR'ına bağlantı ekler;
3. exact test ID ve owner notuna bağlı dar correction Issue'su açar veya current Issue'yu yeniden açar;
4. Codex yalnız gerekli source düzeltmesini yapar;
5. test durumu yeniden `PENDING` olur;
6. owner isterse tekrar test eder.

Codex aynı hatayı otomatik cihaz testiyle yeniden üretmeye zorlanmaz; owner'ın verdiği açıklama ve güvenli source incelemesi correction başlangıcı olabilir.

## 9. Build ve test artifact politikası

APK/AAB her feature sonunda otomatik üretilmez.

Build yalnız:

- owner `test edeceğim`, `APK hazırla` veya artifact istediğinde;
- milestone/release build'i açıkça istendiğinde;
- belirli compile gate owner tarafından ayrıca yetkilendirildiğinde

çalıştırılır.

Build yoksa feature yine commit/push/Draft PR aşamasına geçebilir.

Artifact üretilirse kaydedilir:

```text
source commit
package/application ID
version
size
SHA-256
manual test IDs
```

Owner testi sonraya bıraktığında eski artifact varsa source revision eşleşmesi korunur; yeni source değişirse eski artifact stale olarak işaretlenir.

## 10. Feature sonunda ChatGPT çıktısı

Her feature sonunda ChatGPT kullanıcıya en az şunları verir:

```text
Feature / Issue
Implementation durumu
PR/commit durumu
Manual test status
Numbered test list veya #479 bağlantısı
Test şimdi mi, sonra mı kararı
Sonraki roadmap işi
```

ChatGPT bir kerede uygulanabilir, sade test listesi çıkarır. Kod içi düşük seviyeli unit-test senaryolarını kullanıcıya yüklemez; yalnız sahada/uygulamada anlamlı davranışları listeler.

## 11. New-chat davranışı

Her yeni CSE sohbeti şu kaynağı okur:

```text
GitHub Issue #479 — CSE Manual Test Register
```

Yeni sohbet şu bilgileri kendisi bulur:

- hangi feature'lar implement edildi;
- hangi testler `PENDING`, `PASS`, `FAIL`, `PARTIAL` veya `DEFERRED`;
- owner'ın en son verdiği test notları;
- sıradaki development işi.

Kullanıcıdan önceki test listesini veya sonuçlarını tekrar yapıştırması istenmez.

## 12. Konsolide implementation window

Varsayılan pencere:

```text
primary implementation: 1
same-scope narrow source corrections: up to 3
environment-only recovery: exact root cause sonrası at most 1
automated application tests: 0 unless owner explicitly opts in
manual test list publication: required
```

Dar correction koşulları:

- current Issue ve exact allowlist içinde;
- changed contract aynı;
- kök neden yeterince açık;
- yeni ürün/tasarım kararı yok;
- schema/migration/backup/version/permission/platform authority aşılmıyor;
- production/debug/gerçek kullanıcı data riski yok.

Her dar source correction için yeni owner authority gerekmez. Manual test ertelemesi correction bütçesini tüketmez.

## 13. Anında fail-closed / owner escalation

- allowlist veya ürün kapsamı genişlemesi;
- yeni ürün/tasarım kararı;
- schema, migration, backup formatı, version, permission, signing veya platform production ayarı değişikliği;
- production/debug/gerçek kullanıcı verisi riski;
- stable identity, transaction, event/history, integrity veya security contract değişikliği;
- kök nedenin güvenli source düzeltmesine indirgenememesi;
- correction bütçesinin tükenmesi;
- destructive/force/uninstall/production clear-data ihtiyacı;
- artifact provenance belirsizliği.

Automated test yapılmaması, manual test `PENDING` veya `DEFERRED` olması escalation nedeni değildir.

## 14. Publication ve merge

- Yeni teknik iş doğrudan `master` üzerinde geliştirilmez.
- PR önce Draft açılır.
- Source-level kontroller PASS olduğunda Draft publication yapılabilir.
- Manual test listesi yayımlanmadan feature tamamlanmış sayılmaz.
- Manual testler `PENDING` veya `DEFERRED` iken owner onayıyla Ready/merge ve sonraki feature mümkündür.
- PR açıklaması test durumunu açıkça yazar.
- Merge varsayılan squash merge'dir.
- Ready, merge, Issue/Epic closure, release/store ve roadmap geçişi owner kararı gerektirir.

## 15. Issue/task zorunlu alanları

```text
Expected base:
Risk/model routing:
Changed contracts:
Allowed/protected paths:
Source-level checks:
Automated application tests: disabled unless owner explicitly requests
Manual test register: #479
Manual test IDs:
Manual test status:
Build/artifact authority:
Implementation/correction budget:
Immediate escalation conditions:
Publication authority:
```

## 16. Completion evidence

```text
Current head/diff:
Implementation status:
Source-level checks:
Automated application tests not run and why:
Manual test IDs and status:
Owner-reported results:
Artifact package/size/SHA if any:
Schema/backup/version/platform impact:
Commit/push/Draft/Ready/merge:
Remaining manual test backlog:
Next roadmap item:
```

`execution_record` ve `review_recommendation` zorunludur. Runtime actual model/effort görünmüyorsa `unknown / null / unverified` kullanılır.

## 17. Başarı ölçütleri

```text
Codex automated app/device tests per normal feature: 0
numbered manual test list per feature: 1
owner report format burden: one-line test IDs accepted
manual test deferral blocks next development: no
unverified feature mislabeled verified: 0
persistent cross-chat manual test register: 100%
```

## 18. Ana cümle

> CSE'de Codex kodu uygular ve source-level kontrolleri yapar. Uygulamanın davranış testleri owner'a aittir. Her özellik için stable numaralı test listesi oluşturulur; owner test ederse sonuçlar kaydedilir, test etmezse liste ertelenir ve geliştirme devam eder.
