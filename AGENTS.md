# CSE Codex Repository Instructions

Bu dosya repository kökünde bütün CSE çalışmalarına uygulanır.

## 1. Kaynak otoritesi

Bilgi türüne göre yetkili kaynaklar:

1. Kalıcı ürün amacı ve veri ilkeleri:
   `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
2. Operasyon ve Git/Codex güvenliği:
   `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
3. Model ve reasoning routing:
   `docs/protocols/CSE_MODEL_REASONING_ROUTING_POLICY.md`
4. Risk-temelli validation:
   `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md`
5. Hızlandırılmış çalışma, owner-led manual test ve test-erteleme kuralları:
   `docs/protocols/CSE_WORKFLOW_ACCELERATION_PROTOCOL.md`
6. Güncel ürün kapsamı ve sıra:
   `docs/v2/CSE_V2_SCOPE.md` ve `ROADMAP.md`
7. Aktif görev ve owner authority:
   current GitHub Issue ve bütün kapsam/izin yorumları
8. Kalıcı manuel test backlog'u:
   GitHub Issue `#479 — CSE Manual Test Register`
9. Yerel yürütme kanıtı:
   `.cse/tasks/<issue_no>_task.md` ve `.cse/results/<issue_no>_result.md`

README, eski roadmap/Epic, ZIP, handoff, podcast, `.cse/state`, Orchestrator,
Bridge, Work Mode veya sohbet hafızası current GitHub ve kanonik kaynak
gerçeğini override edemez.

Bu kalıcı dosyada sabit master SHA, schema, aktif Issue/PR veya test sayısı
tutulmaz. Değişken durum her görevde GitHub/repository üzerinden okunur.

## 2. Yeni sohbet ve resume

### Yeni sohbet / yeni görev

Bir kez tam oku:

1. `AGENTS.md`
2. `CSE_UNIFIED_PROJECT_SOURCE.md`
3. `CSE_PROJECT_INSTRUCTIONS.md`
4. `CSE_MODEL_REASONING_ROUTING_POLICY.md`
5. `CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md`
6. `CSE_WORKFLOW_ACCELERATION_PROTOCOL.md`
7. `CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md`
8. `CSE_PROJECT_SOURCE_REGISTER.md`
9. Ürün işi ise `CSE_V2_SCOPE.md`
10. `ROADMAP.md`
11. current Issue, owner-authority yorumları, açık PR/branch/diff
12. GitHub Issue #479 içindeki ilgili manuel test kayıtları
13. ilgili task/result ve son failure evidence

Kanonik kaynakların blob/hash manifestini task kaydına yaz.

### Aynı görevde resume/correction

Ruleset hashleri değişmediyse bütün uzun belgeleri tekrar okuma. Yalnız:

- yeni Issue/authority yorumları;
- task/result EOF;
- branch/head/diff/staged;
- kalan implementation/correction bütçesi;
- Issue #479 içindeki ilgili test durum değişiklikleri

okunur. Hash değişmişse yalnız değişen kanonik kaynak yeniden okunur.

Kullanıcı yeni sohbette yalnız `devam` veya `GitHub'dan devam et` diyebilmelidir;
daha önce verdiği instruction/result bloklarını tekrar taşıması beklenmez.

## 3. Yeni workflow kuralının önceliği

`CSE_WORKFLOW_ACCELERATION_PROTOCOL.md`, workflow, retry, automated testing,
manuel test listesi ve test erteleme konularında eski zorunlu full-test/build/
device veya `one correction / one retry` kurallarıyla çelişirse daha yeni ve
daha özel kural olarak uygulanır.

Bu öncelik şunları gevşetmez:

- ürün/veri güvenliği;
- current Issue allowlist ve changed-contract sınırı;
- schema/migration/backup/version/permission/platform authority;
- production/debug/gerçek kullanıcı verisi koruması;
- Ready, merge, release ve owner onayı.

## 4. Değişmez güvenlik ilkeleri

- CSE tek sahipli, owner-only, local-first ve mobile-first kalır.
- Aynı anda yalnız bir production implementation Issue'su aktiftir.
- Gerçek kullanıcı data root'u açık authority olmadan okunmaz/değiştirilmez.
- Production/debug paketleri acceptance veya otomasyon tarafından okunmaz,
  başlatılmaz, temizlenmez veya mutate edilmez.
- Stable identity, optimistic revision, append-only event/history, transaction,
  backup/restore ve attachment bütünlüğü korunur.
- Force-push, destructive reset/clean/stash, hard-delete ve beklenmeyen kullanıcı
  değişikliğinin üzerine yazma varsayılan yasaktır.
- Ready, merge, Issue/Epic closure, release/store ve sonraki ürün maddesi açık
  owner onayı gerektirir.

## 5. Owner-led manuel uygulama testi — bağlayıcı varsayılan

> Uygulama davranışını varsayılan olarak Codex değil, owner test eder.

Codex, owner'ın ayrıca ve açıkça belirli bir gate için istemediği sürece
uygulamayı test etmez.

### Varsayılan olarak çalıştırılmayacaklar

- `flutter test` ve diğer unit/widget testleri;
- integration testleri veya full Flutter suite;
- emülatör testi;
- ADB/device acceptance;
- scripted UI/selector testleri;
- acceptance package install/launch/clear-data akışı;
- uygulamayı davranış doğrulaması amacıyla çalıştırma;
- APK/AAB build — yalnız owner artifact veya manuel test build'i istediğinde.

### Codex'in varsayılan source-level kontrolleri

- exact allowlist ve diff/scope kontrolü;
- yalnız değişen dosyalarda format/syntax kontrolü;
- gerekli ve makul ise static analysis;
- `git diff --check`;
- protected/schema/backup/version/platform drift kontrolü;
- commit/push/Draft PR kanıtı.

Bu kontroller manuel uygulama testinin yerine geçtiği iddiasını taşımaz.

### Her özellikte zorunlu manuel test listesi

Her feature implementation sonunda ChatGPT:

1. GitHub Issue #479'a numaralı testler ekler;
2. ID biçimini `MT-<FEATURE_ISSUE>-<NNN>` olarak korur;
3. adım ve beklenen sonucu kısa yazar;
4. feature/PR/build referansını kaydeder;
5. owner'ın bildirdiği sonuçlara göre listeyi günceller.

Durumlar:

```text
PENDING
PASS
FAIL
DEFERRED
PARTIAL
N/A
```

Owner yalnız `MT-476-003 PASS` gibi kısa bir bildirim verebilir. ChatGPT kayıt
yüzeyini günceller; owner'ın rapor veya YAML hazırlaması gerekmez.

### Testi sonraya bırakma

Owner test etmek istemezse ilgili testler `DEFERRED` olarak kalır ve sonraki
özelliğe geçilebilir. Bu durum:

- implementation'ı veya Draft PR publication'ını otomatik bloke etmez;
- merge kararını owner'a bırakır;
- feature'ın `VERIFIED`, `FIELD_ACCEPTED` veya `RELEASE_READY` sayılmasına izin
  vermez;
- durumun `IMPLEMENTED — MANUAL TEST PENDING/DEFERRED` olarak yazılmasını
  gerektirir.

Owner daha sonra test sonucu bildirirse aynı stable test ID'leri güncellenir.
`FAIL` sonucu çıkarsa test ID'sine bağlı dar correction Issue'su açılır.

## 6. Konsolide implementation/stabilizasyon penceresi

Her Slice/correction phase tek bounded implementation window içinde yürütülür:

```text
primary implementation: 1
same-scope narrow corrections: en fazla 3
environment-only recovery: exact root cause sonrası en fazla 1
automated application tests: 0 unless owner explicitly opts in
manual test checklist: every feature
```

Dar correction için:

- current Issue/allowlist/changed-contract içinde kal;
- exact root cause kanıtla;
- yalnız source-level invalidated kontrolü çalıştır;
- correction ve kalan bütçeyi evidence'a yaz;
- yeni ürün/tasarım kararı üretme.

Her dar blocker için yeni owner authority istenmez.

### Anında fail-closed / owner escalation

- allowlist veya kapsam genişlemesi;
- yeni ürün/tasarım kararı;
- schema/migration/backup/version/permission/signing/platform değişimi;
- production/debug/gerçek kullanıcı verisi riski;
- stable identity/transaction/event/history/integrity/security değişimi;
- kök nedenin kanıtlanamaması;
- üç correction bütçesinin tükenmesi;
- destructive/force/uninstall/production clear-data ihtiyacı.

Testlerin owner tarafından `PENDING` veya `DEFERRED` bırakılması fail-closed
nedeni değildir.

## 7. Test listesi ve implementation durumunun ayrılması

Implementation ve manuel doğrulama iki ayrı durumdur:

```text
implementation_status:
  NOT_STARTED | IN_PROGRESS | IMPLEMENTED | MERGED
manual_test_status:
  PENDING | PARTIAL | PASS | FAIL | DEFERRED
```

Codex completion raporu otomatik test yapılmadığını açıkça belirtir. PASS test
uydurmaz ve daha önceki farklı source revision'a ait sonucu current davranışın
kanıtı gibi sunmaz.

Test listesi değişiklikten etkilenirse yalnız ilgili MT satırları yeniden
`PENDING` yapılır; geçmiş owner sonuçları not olarak korunur.

## 8. Build ve artifact davranışı

APK/AAB varsayılan olarak her feature sonunda üretilmez.

Build yalnız:

- owner `test edeceğim` veya artifact istediğinde;
- release/milestone build kararı verildiğinde;
- owner belirli bir compile gate'i açıkça yetkilendirdiğinde

çalıştırılır.

Build istenmezse implementation commit/push/Draft PR aşamasına geçebilir.
Build üretilirse package, size, SHA-256 ve ilgili source commit kaydedilir.

## 9. GitHub ve publication

- Production branch: `codex/issue-<issue_no>-<slug>`
- Documentation branch: `docs/issue-<issue_no>-<slug>`
- Yeni teknik iş doğrudan `master` üzerinde geliştirilmez.
- PR önce Draft açılır.
- Source-level kontroller PASS olduktan sonra Draft PR açılabilir.
- Manual testler `PENDING` veya `DEFERRED` iken Draft publication ve sonraki
  development başlayabilir.
- `PENDING/DEFERRED` durumunda PR ve completion açıkça
  `IMPLEMENTED — MANUAL TEST PENDING/DEFERRED` yazar.
- Merge varsayılan squash merge'dir ve owner onayı gerektirir.
- Açık owner talebiyle documentation-only canonical rule güncellemesi ayrı docs
  branch/Draft PR üzerinde GitHub-native hazırlanabilir; production dosyası
  içeremez ve merge öncesi independent review ister.

## 10. Yerel yürütme

Resmî yerel repo:

```text
V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer
```

Local execution gereken işte doğru root, master/origin divergence ve bütün Git
durumu doğrulanır. Beklenmeyen değişiklikte reset/clean/stash uygulanmaz. İlk
substantive local edit `.cse/tasks/<issue_no>_task.md` olmalıdır.

## 11. Issue/task zorunlu alanları

```text
Parent / V2 item:
Expected base:
Risk ve model routing:
Changed contracts:
Allowed/protected paths:
Source-level checks:
Automated application tests: disabled unless owner explicitly requests
Manual test IDs / register link:
Manual test status:
Build/artifact authority:
Stabilization/correction budget:
Immediate escalation conditions:
Publication authority:
```

## 12. Completion evidence

Final rapor şunları açıkça ayırır:

- source/head ve exact changed paths;
- implementation ve correction durumu;
- source-level kontroller;
- Codex tarafından çalıştırılmayan application testleri;
- Issue #479'daki manuel test ID'leri ve durumları;
- artifact varsa package/size/SHA-256;
- schema/backup/version/platform etkisi;
- commit/push/Draft/Ready/merge durumu.

`execution_record` ve `review_recommendation` zorunludur. Runtime actual
model/effort görünmüyorsa `unknown / null / unverified` kullanılır.

## 13. Ana karar

> Codex özelliği uygular, source-level kalite ve scope kontrollerini yapar,
> numaralı manuel test listesini ChatGPT'ye devreder ve geliştirmeye devam eder.
> Uygulama davranışını owner isterse test eder; istemezse testler kayıtlı şekilde
> ertelenir. Test yapılmaması başarı kanıtı değildir, fakat sonraki feature'a
> geçişi otomatik olarak durdurmaz.
