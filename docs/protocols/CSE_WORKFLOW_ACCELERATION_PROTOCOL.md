# CSE Workflow Acceleration Protocol

**Belge türü:** Bağlayıcı execution/stabilization addendum
**Geçerlilik tarihi:** 2026-08-23
**Kaynak karar:** Epic #385 owner decision ve Issue #477
**Kapsam:** Bütün yeni CSE Slice, correction, test, build, device acceptance,
resume ve new-chat işlemleri

Bu protokol, güvenlik sınırlarını korurken aynı-kapsamlı mikro-authority ve
tekrarlanan pahalı gate döngülerini kaldırır.

Çelişki halinde:

- ürün/veri ilkelerinde `CSE_UNIFIED_PROJECT_SOURCE.md`;
- model routing'de `CSE_MODEL_REASONING_ROUTING_POLICY.md`;
- genel risk-temelli validation'da
  `CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md`;
- konsolide stabilizasyon, digest invalidation, acceptance senaryoları ve
  resume hızında bu protokol

uygulanır.

## 1. Ana karar

> Bir Slice/correction phase, her dar blocker'da yeniden başlatılmaz. Aynı
> Issue, allowlist ve changed-contract içinde kalan teşhis ve dar correction'lar
> tek bounded consolidated stabilization window içinde tamamlanır.

Varsayılan pencere:

```text
primary implementation: 1
same-scope narrow corrections: up to 3
environment-only retry: 1 after exact diagnosis
final full suite: 1
final artifact build: 1
final full device acceptance: 1
```

Her correction için yeni owner authority gerekmez; owner escalation yalnız bu
protokolde listelenen gerçek kapsam/veri/sözleşme sınırlarında istenir.

## 2. Dar correction koşulları

Bir correction bütün koşulları sağlamalıdır:

- current Issue ve exact allowlist içinde;
- changed contract aynı;
- exact root cause kanıtlı;
- yeni ürün/tasarım kararı yok;
- schema/migration/backup/version/permission/signing/platform değişikliği yok;
- production/debug/gerçek kullanıcı data riski yok;
- stable identity/transaction/event/history/integrity/security contractı
  değişmiyor;
- correction ve focused doğrulama evidence'a kaydediliyor.

Dar correction örnekleri:

- analyzer/lint semantic-no-op;
- mevcut contractı doğru uygulayan regression fix;
- acceptance fixture state/calendar hizası;
- runner selector/observability;
- aynı fixture defect sınıfında konsolide stale-state cleanup;
- generated-state read-only/cache düzeltmesi.

## 3. Anında fail-closed / owner escalation

- allowlist veya ürün kapsamı genişlemesi;
- yeni ürün/tasarım kararı;
- schema, migration, backup formatı, version, permission, signing veya platform
  production ayarı;
- production/debug/real data erişimi veya mutation riski;
- stable identity, transaction, event/history, integrity veya security contractı;
- kök nedenin kanıtlanamaması;
- üç tracked correction'ın tükenmesi;
- force-push, uninstall, production clear-data veya destructive işlem;
- artifact provenance/digest belirsizliği.

Fail-closed, her küçük selector veya generated-cache hatasında yeni owner
yorumuyla işi bölmek için kullanılmaz.

## 4. Source ve artifact digestleri

Task/result mümkün olduğunda şunları kaydeder:

```text
ruleset_digest
runner_digest
fixture_digest
dart_source_digest
persistence_digest
apk_input_digest
device_scenario_digest
artifact_sha256
```

Kanıt yeniden kullanımı:

| Değişiklik | Invalidated gate |
| --- | --- |
| Docs/evidence | syntax/diff |
| Runner-only | runner static + ilgili device scenario |
| Fixture | focused fixture + analyze; finalde full/build/device |
| UI/application/domain | ilgili focused + analyze; finalde gerekli full/build/device |
| Persistence/schema | migration/integrity/round-trip/full/data-safe device |
| Generated cleanup | tracked/protected drift; executable gate yok |

Kurallar:

- Aynı source digest üzerinde PASS full suite tekrar edilmez.
- Runner-only değişiklik `apk_input_digest`i değiştirmiyorxa rebuild yoktur.
- APK input değişirse eski APK stale'dir.
- Correction sırasında focused gate; broad gate final candidate üzerinde.
- Evidence append executable evidence'ı stale yapmaz.
- Interruption önceki bağımsız PASS gate'i sıfırlamaz.

## 5. Fresh-chat ve resume

### Fresh chat / yeni görev

Kanonik kaynaklar tam okunur ve blob/hash manifesti task'a yazılır.

### Aynı görevde resume

Ruleset hashleri aynıysa yalnız:

- yeni Issue/authority yorumları;
- task/result EOF;
- son failure diagnostics;
- branch/head/diff/staged;
- kalan correction/gate budget

okunur. Bütün uzun belgeler yeniden yüklenmez.

Hash değişmişse yalnız değişen canonical belge ve etkilediği alt kaynak okunur.

Kullanıcının daha önce GitHub'a yazılmış instruction/result bloklarını yeniden
taşıması beklenmez.

## 6. Acceptance mode

### `CleanAcceptance`

Normal UI/feature kabulünde varsayılan:

- yalnız izole sentetik acceptance package;
- Issue yetkisiyle yalnız acceptance datası başlangıçta temizlenebilir;
- production/debug package ve data korunur;
- deterministik clock/calendar;
- idempotent fixture;
- persistence aynı koşu içinde force-stop/relaunch ile kanıtlanır.

### `UpgradeAcceptance`

Migration/historical compatibility:

- eski acceptance state korunur;
- preconditions explicit;
- Clean mode ile karıştırılmaz.

Mode belirtilmemişse destructive package-data işlemi yapılmaz.

## 7. Device scenario sistemi

Önerilen scenario'lar:

```text
fixture_boot
lifecycle_core
progress_forecast
downstream_impact
relaunch_persistence
full_final_acceptance
```

Correction sırasında düşen scenario çalıştırılabilir. Publication öncesi Issue
gerekli görüyorsa bir full-final acceptance çalıştırılır.

Stable `ValueKey`/semantics tercih edilir. `text` ve `content-desc` yüzeyleri
açıkça ayrılır. Raw coordinate son çaredir.

## 8. İlk-hatada otomatik diagnostics

Her failed device invocation aynı invocation içinde şunları toplar:

```text
scenario/checkpoint/caller
last successful step
current package/activity/window
bounded UI hierarchy
screenshot
visible text/content-desc/stable keys
acceptance PID-filtered logcat
fixture stage/error code
related synthetic item/snapshot/state
artifact SHA-256
source/input digests
read-only durable projection summary
```

Bu diagnostic `catch/finally` adımı ikinci device acceptance invocation sayılmaz.
Yalnız “UI text not found” mesajı yeterli evidence değildir.

## 9. ADB ve package isolation maliyeti

Full package inventory:

- preflight;
- install before/after;
- mutation/relaunch boundary;
- final;
- failure diagnostics

checkpointlerinde alınır.

Her tap/swipe sonrası bütün paketler için pahalı `dumpsys` tekrarlanmaz. Ara
adımlarda foreground package/activity kontrolü yeterlidir. Finalde non-target
package isolation exact karşılaştırılır.

Production/debug package başlatılmaz, okunmaz, temizlenmez veya mutate edilmez.

## 10. Generated-state ve Gradle/OpenJDK

Tracked/protected drift `0` ise somut blocker için:

```text
mobile/build/
mobile/ios/Flutter/ephemeral/
```

gibi worktree-local generated alanlar temizlenebilir; yeniden owner authority
gerekmez.

- tracked source/config/test değişmez;
- read-only attribute yalnız generated pathte kaldırılır;
- unrelated Java/OpenJDK/Gradle süreçleri topluca kapatılmaz;
- process yalnız exact worktree daemon lock'u kanıtlanırsa durdurulur;
- aynı anda yalnız bir build çalışır;
- termal hostta worker/priority sınırlaması kullanılabilir.

Güvenilir completion, maksimum CPU kullanımından daha değerlidir.

## 11. Broad gate sırası

```text
primary implementation
→ focused tests
→ correction 1..3 + affected focused gates
→ final analyze
→ final full suite if required
→ final fresh build if required
→ final device acceptance
→ Draft review/publication
```

Şu anti-pattern yasaktır:

```text
correction → full → build → device
correction → full → build → device
```

Broad gate yalnız invalidation gerekiyorsa tekrarlanır.

## 12. Early Draft PR

Focused + analyze PASS ve Issue yetkisi varsa:

```text
WIP commit → normal push → Draft PR
```

ile şu işler paralel yürüyebilir:

- CI full suite;
- local build/device;
- independent source/diff review.

Draft Ready/merge değildir; eksik gate'i gizlemez. Force/amend/rebase yoktur.

## 13. Timebox davranışı

Süre hedefi otomatik reset veya yeni authority üretmez.

Re-evaluation sırasında:

- aynı scope mu;
- correction budget kaldı mı;
- hangi gate hâlâ valid;
- ayrı toolchain Issue gerekir mi;
- owner escalation koşulu oluştu mu

kontrol edilir.

Bütçe ve kapsam uygunsa aynı stabilization window devam eder.

## 14. Issue/task zorunlu alanları

```text
Expected base:
Risk/model routing:
Validation class:
Changed contracts:
Allowed/protected paths:
Ruleset/source/artifact digests:
Focused/broad gates:
Reused evidence:
Acceptance mode/scenarios:
Stabilization/correction budget:
Generated-state authority:
Immediate escalation conditions:
Publication authority:
```

## 15. Completion evidence

```text
Current head/diff:
Correction count and root causes:
Focused/broad gates:
Reused evidence and digests:
Generated-state actions:
Artifact package/size/SHA:
Device scenarios/checkpoints:
Failure diagnostics:
Schema/backup/version/platform impact:
Commit/push/Draft/Ready/merge:
Remaining blocker or next gate:
```

`execution_record` ve `review_recommendation` zorunludur. Runtime actual
model/effort görünmüyorsa `unknown / null / unverified` kullanılır.

## 16. Merge sınırı

Bu hızlandırma protokolü şunları otomatik yetkilendirmez:

- Ready;
- merge;
- Issue/Epic closure;
- roadmap checkbox;
- release/store;
- sonraki production item.

Bunlar açık owner kararı gerektirir.

## 17. Başarı ölçütleri

```text
owner authorities per Issue: initial + at most one true escalation
full suite per source digest: at most 1
build per APK input digest: at most 1 + one environment retry
full device acceptance: 1 final + bounded scenario correction
failure diagnostic completeness: 100%
runner-only correction rebuild: 0
stale synthetic acceptance poison: 0
generated read-only authority loops: 0
```

## 18. Ana cümle

> CSE güvenliğini owner-authority sayısıyla değil; dar scope, exact allowlist,
> source/artifact digest, deterministic fixture, automatic diagnostics,
> independent review ve explicit merge gate ile korur.
