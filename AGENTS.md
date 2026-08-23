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
5. Konsolide stabilizasyon, digest, acceptance ve hızlandırma:
   `docs/protocols/CSE_WORKFLOW_ACCELERATION_PROTOCOL.md`
6. Güncel ürün kapsamı ve sıra:
   `docs/v2/CSE_V2_SCOPE.md` ve `ROADMAP.md`
7. Aktif görev ve owner authority:
   current GitHub Issue ve bütün kapsam/izin yorumları
8. Yerel yürütme kanıtı:
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
12. ilgili task/result ve son failure evidence

Kanonik kaynakların blob/hash manifestini task kaydına yaz.

### Aynı görevde resume/correction

Ruleset hashleri değişmediyse bütün uzun belgeleri tekrar okuma. Yalnız:

- yeni Issue/authority yorumları;
- task/result EOF;
- son failure diagnostics;
- branch/head/diff/staged;
- kalan correction/gate bütçesi

okunur. Hash değişmişse yalnız değişen kanonik kaynak yeniden okunur.

Kullanıcı yeni sohbette yalnız `devam` veya `GitHub'dan devam et` diyebilmelidir;
daha önce verdiği instruction/result bloklarını tekrar taşıması beklenmez.

## 3. Yeni workflow kuralının önceliği

`CSE_WORKFLOW_ACCELERATION_PROTOCOL.md`, workflow-acceleration ve retry bütçesi
konularında eski `one correction / one retry` mikro-döngüsüyle çelişirse daha
yeni ve daha özel kural olarak uygulanır.

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
- Production/debug paketleri acceptance tarafından okunmaz, başlatılmaz,
  temizlenmez veya mutate edilmez.
- Stable identity, optimistic revision, append-only event/history, transaction,
  backup/restore ve attachment bütünlüğü korunur.
- Force-push, destructive reset/clean/stash, hard-delete ve beklenmeyen kullanıcı
  değişikliğinin üzerine yazma varsayılan yasaktır.
- Ready, merge, Issue/Epic closure, release/store ve sonraki ürün maddesi açık
  owner onayı gerektirir.

## 5. Konsolide stabilizasyon

Her Slice/correction phase tek bounded stabilization window içinde yürütülür:

```text
primary implementation: 1
same-scope narrow corrections: en fazla 3
environment-only retry: exact root cause sonrası en fazla 1
final full suite: 1
final artifact build: 1
final full device acceptance: 1
```

Dar correction için:

- current Issue/allowlist/changed-contract içinde kal;
- exact root cause kanıtla;
- yalnız invalidated focused gate'i çalıştır;
- correction ve kalan bütçeyi evidence'a yaz;
- broad gate'leri final candidate'a bırak.

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

## 6. Gate ve artifact yeniden kullanımı

- Aynı source digest üzerinde PASS full suite tekrar edilmez.
- Runner-only değişiklik APK input digest'ini değiştirmiyorsa rebuild yoktur.
- APK input digest değişirse eski APK stale'dir.
- Fixture/UI/application değişikliğinde ilgili focused + analyze çalışır; gerekli
  full/build/device final candidate üzerinde çalışır.
- Docs/evidence append executable kanıtı stale yapmaz.
- Generated-state cleanup tracked/protected drift üretmiyorsa executable gate
  tekrarı istemez.
- Test/build/device kesilirse geçerli önceki PASS kapıları sıfırlanmaz.

## 7. Acceptance ve diagnostics

Her cihaz Issue'su mode seçer:

- `CleanAcceptance`: normal feature/UI kabulü; izole sentetik data,
  deterministik clock/calendar ve idempotent fixture.
- `UpgradeAcceptance`: migration/historical compatibility; eski acceptance data
  korunur.

Device akışı mümkün olduğunda senaryolara ayrılır. Correction sırasında yalnız
düşen senaryo, publication öncesi gerekiyorsa bir full-final acceptance çalışır.

Her device failure aynı invocation içinde en az şunları üretir:

- scenario/checkpoint/caller ve son başarılı adım;
- current package/activity/window;
- bounded UI hierarchy ve screenshot;
- visible text/content-desc/key özeti;
- acceptance PID-filtered diagnostics;
- fixture stage/error ve ilgili sentetik state;
- APK SHA-256 ve source/input digest.

Yalnız `text not found` mesajı yeterli evidence değildir.

## 8. Generated state ve termal güvenlik

Tracked/protected drift `0` ise somut blocker için worktree-local generated
alanlar temizlenebilir; her defasında yeni authority gerekmez:

- `mobile/build/`
- `mobile/ios/Flutter/ephemeral/`
- Issue'da eşdeğer olarak listelenen generated cache/output

Temizlik tracked source/config/test dosyasına dokunmaz. Unrelated Java/OpenJDK/
Gradle süreçleri kapatılmaz; process kill yalnız exact worktree daemon lock'u
kanıtlanırsa uygulanır.

Aynı anda tek build çalıştırılır. Termal olarak sınırlı hostta worker ve process
priority sınırlandırılır; güvenilir completion, maksimum CPU kullanımından daha
değerlidir.

## 9. GitHub ve publication

- Production branch: `codex/issue-<issue_no>-<slug>`
- Documentation branch: `docs/issue-<issue_no>-<slug>`
- Yeni teknik iş doğrudan `master` üzerinde geliştirilmez.
- PR önce Draft açılır.
- Focused/analyze PASS sonrasında erken Draft PR açılabilir; CI, local
  build/device ve independent review paralel yürüyebilir.
- Erken Draft PR Ready/merge yetkisi değildir.
- Merge varsayılan squash merge'dir.
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
Validation class:
Changed contracts:
Allowed/protected paths:
Focused/broad gates:
Reused evidence ve source/artifact digests:
Acceptance mode/scenarios:
Stabilization/correction budget:
Generated-state authority:
Immediate escalation conditions:
Publication authority:
```

## 12. Completion evidence

Final rapor source/head, exact changed paths, correction kök nedenleri, gate
sonuçları, reused evidence/digest gerekçesi, artifact package/size/SHA-256,
device scenarios/diagnostics, schema/backup/version/platform etkisi ve
commit/push/Draft/Ready/merge durumunu açıkça ayırır.

`execution_record` ve `review_recommendation` zorunludur. Runtime actual
model/effort görünmüyorsa `unknown / null / unverified` kullanılır.

## 13. Ana karar

> CSE güvenli ve dar kapsamlı kalır; ancak aynı sözleşme içindeki teşhis,
> correction ve acceptance işlemleri tek konsolide stabilizasyon penceresinde
> tamamlanır. Full test, build ve cihaz zinciri correction başına değil final
> candidate başına çalıştırılır.
