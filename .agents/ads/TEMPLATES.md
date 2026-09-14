# ADS — kısa çalışma şablonları

Yeni belge üretmek zorunlu değildir. Mevcut Issue/PR yeterliyse onu kullan.
Kullanıcı aynı repo/task/routing bilgisini tekrar tekrar yazmaz.

## 1. System Manager + topology seçimi

Önce execution surface seç:

```text
SYSTEM_MANAGER
Mode: LOCAL_SYSTEM_MANAGER | GITHUB_SYSTEM_MANAGER
Resolved provider:
Reason:
Local capability required: YES | NO
Manual acceptance owner: none | Fatih | project-specific
```

Ardından feature topology seç:

- `SINGLE`: yalnız Builder/WRITE.
- `PARALLEL_READ`: 1 Builder/WRITE + 1 Scout/READ + 1 Reviewer/READ.

System Manager ve topology ayrı eksenlerdir. Aynı feature içinde ikinci production
writer açılmaz. `GITHUB_SYSTEM_MANAGER` seçimi local device/ADB/profiler capability
varmış gibi davranma veya validation waiver yetkisi vermez.

## 2. Yeni işi başlat — SINGLE

```text
ADS ile bu işi SINGLE topolojisinde tamamla.
Görev/Issue:
Repo:
System Manager: LOCAL_SYSTEM_MANAGER | GITHUB_SYSTEM_MANAGER
Resolved provider:
System Manager lock revision:
Topology lock revision:
Builder routing: <model / effort / speed / WRITE>
External research: NONE | ALLOWED_WHEN_NEEDED | REQUIRED
Local capability required: YES | NO
Manual acceptance owner: none | Fatih | project-specific
Yetki ve kabul:
```

Builder erişilebilir repo/Issue bilgisini kendisi bulur. Araştırma, uygulama,
test/fix ve self-review iç çalışmadır. Baştan yetkili commit/push/Draft PR zinciri
mikro-onay için bölünmez.

## 3. Yeni işi başlat — PARALLEL_READ

```text
ADS ile bu işi PARALLEL_READ topolojisinde tamamla.
Görev/Issue:
Repo:
System Manager: LOCAL_SYSTEM_MANAGER | GITHUB_SYSTEM_MANAGER
Resolved provider:
System Manager lock revision:
Topology lock revision:
Builder routing: <model / effort / speed / WRITE>
Scout routing: <model / effort / speed / READ>
Reviewer routing: <model / effort / speed / READ>
External research: NONE | ALLOWED_WHEN_NEEDED | REQUIRED
Local capability required: YES | NO
Manual acceptance owner: none | Fatih | project-specific
Yetki ve kabul:
```

### Builder prompt

```text
Ortak PARALLEL_READ görev kaydını kullan. Rolün Builder/WRITE ve tek production
writer'dır. Kayıtlı System Manager üzerinde araştır, uygula, test et, kapsam içi
hataları düzelt, self-review yap ve baştan yetkili Git teslimini tamamla.
Scout'u beklerken ilerle. REVIEW_PASS veya CHANGES_REQUIRED yalnız exact revision
için geçerlidir. Topology/System Manager/routing/authority değiştirme.
GITHUB_SYSTEM_MANAGER kullanıyorsan local capability veya CI PASS uydurma.
```

### Scout prompt

```text
Ortak PARALLEL_READ görev kaydını kullan. Rolün Scout/READ. Current source,
contract, external evidence ve test yüzeyini bağımsız araştır. Production source,
branch veya PR değiştirme; commit/push yapma. Tek SCOUT_RESULT üret.
```

### Reviewer prompt

```text
Ortak PARALLEL_READ görev kaydını kullan. Rolün Reviewer/READ. Exact Builder
revision'ının diff ve gerçek validation kanıtını incele. Production kodunu düzeltme,
commit/push/PR yapma. Validation kanıtını GITHUB_HOSTED / HUMAN_MANUAL / LOCAL_ONLY
olarak gerçek surface ile eşleştir. Yalnız REVIEW_PASS veya CHANGES_REQUIRED ver.
```

### Lane çıktı kontratları

```text
SCOUT_RESULT
Critical findings:
Regression risks:
Relevant tests/contracts:
Recommended direction:
Builder attention:
```

```text
REVIEW_PASS
Reviewed revision:
Evidence checked:
Validation class:
Remaining required gate:
```

```text
CHANGES_REQUIRED
Reviewed revision:
Blocker:
Evidence:
Required correction:
```

## 4. Local capability handoff

`GITHUB_SYSTEM_MANAGER` üzerinde source work ilerleyebilirken task acceptance için
gerçek local capability zorunlu hale gelirse:

```text
LOCAL_CAPABILITY_REQUIRED
Task/revision:
Current System Manager: GITHUB_SYSTEM_MANAGER
Completed GitHub work:
Exact remaining local operation:
Source change required before handoff: YES | NO
Recommended System Manager: LOCAL_SYSTEM_MANAGER
Remote canonical revision:
Required local status/drift check:
Preserved scope/risk/topology/WRITE authority:
```

Bu handoff yeni scope veya WRITE authority değildir. Local execution başlamadan
önce dirty local work korunur ve remote/local drift doğrulanır.

## 5. Validation evidence

```text
VALIDATION_EVIDENCE
Exact revision:
Class: GITHUB_HOSTED | HUMAN_MANUAL | LOCAL_ONLY
Command/check:
Environment/surface:
Result: PASS | FAIL | NOT_RUN | UNAVAILABLE
Evidence location:
Invalidation trigger:
```

`GITHUB_HOSTED` yalnız gerçekten çalıştırılmış GitHub Actions/check/tooling için
PASS olabilir. Manual test Fatih'e atanmışsa `HUMAN_MANUAL` olarak kaydedilir.
GitHub surface'te olmayan zorunlu test `LOCAL_ONLY` olarak handoff edilir; PASS
uydurulmaz.

## 6. Multi-feature parent kickoff — MULTI_FEATURE_PARALLEL

Bu mode açıkça opt-in'dir; `SINGLE` / `PARALLEL_READ` yerine geçmez.

```text
Parent orchestration: MULTI_FEATURE_PARALLEL (explicit opt-in).
Parent task / authority record / lock revision:
Exact target-main revision:
Pilot limit: MAX_OPEN_FEATURES = 3 (owner/review/authority wait dahil).
Feature roster (en fazla 3):
- Feature/task + Issue:
  Branch/worktree veya GitHub branch + Draft PR:
  System Manager: LOCAL_SYSTEM_MANAGER | GITHUB_SYSTEM_MANAGER
  Resolved provider + System Manager lock revision:
  Feature topology: SINGLE | PARALLEL_READ + topology lock revision:
  Lane roster + model/effort/speed/READ-WRITE / tek production writer:
  Scope, Git authority ve korunacak gate'ler:
  Relation: INDEPENDENT | COORDINATION_REQUIRED | DEPENDENCY_BLOCKED
  Shared contract/dependency:
  SHARED_INTEGRATION_SURFACE: yok veya dar yüzey + tek sorumlu:
Shared runtime/local capability resources ve sıra:
Cross-feature event alanları:
Yasaklar: cross-feature WRITE; ikinci writer; scope/routing/authority inheritance;
silent System Manager switch; self-open fourth feature; automatic merge/release.
```

Aynı path tek başına global serialization değildir. Her feature kendi manager ve
topology lock'ını taşır.

## 7. Bounded cross-feature handoff kontratları

### Per-feature status/update

```text
FEATURE_STATUS
Parent task + lock revision:
Feature task/Issue + feature topology lock revision:
System Manager + manager lock revision:
Branch/worktree + exact feature revision:
Exact target-main revision:
Observed state + tamamlanan kullanıcı davranışı:
Touched areas / shared contract change:
Validation/review evidence + exact revision:
Dependency/conflict/shared-surface/capability/owner blocker:
Freshness observed-at + source:
Next authorized action:
```

### Cross-feature conflict

```text
CROSS_FEATURE_CONFLICT
Parent task + lock revision / Exact target-main revision:
Reporting feature/task + System Manager + exact revision:
Affected feature/task + System Manager + exact revision:
Touched area / shared contract / conflict evidence:
Classification: mechanical | non-mechanical/product behavior
Recorded owner:
Blocked portion / independently progressable portion:
Freshness observed-at + source:
Requested bounded action:
Explicit non-authority: no cross-feature WRITE/routing/scope/manager/owner override.
```

### Dependency signal

```text
DEPENDENCY_SIGNAL
Parent task + lock revision / Exact target-main revision:
Producer feature/task + exact revision:
Consumer feature/task + exact revision:
Prerequisite contract/artifact + required condition:
State/evidence: available | DEPENDENCY_BLOCKED
Blocked consumer portion / independently progressable portion:
Invalidation trigger:
Freshness observed-at + source:
Next responsible feature/lane:
```

### Shared integration surface handoff

```text
SHARED_INTEGRATION_HANDOFF
Parent task + lock revision / Exact target-main revision:
SHARED_INTEGRATION_SURFACE exact dar kapsam:
Kayıtlı tek sorumlu feature/entegratör + WRITE authority:
Contributing feature/task + exact revisions:
System Manager per feature:
Expected mechanical wiring / shared contract:
Validation evidence + exact revision pair'leri:
Known conflict veya non-mechanical decision:
Freshness observed-at + source:
```

### Revision-pinned integration handoff

```text
INTEGRATION_HANDOFF
Parent task + lock revision:
Feature task/Issue + branch/Draft PR:
System Manager + manager lock revision:
Exact feature revision:
Exact target-main revision:
Authorized scope + touched areas:
Validation/review evidence bound to this revision pair:
Required gates + current disposition:
Shared-surface/dependency/conflict/capability state:
Freshness observed-at + source:
Invalidation: feature revision veya target main değişirse etki analizi gerekir.
Authorized next action / explicit exclusions:
```

### Owner attention

```text
OWNER_ATTENTION_REQUIRED
Parent + feature task / lock revisions:
System Manager + exact feature revision / Exact target-main revision:
Decision class: product | acceptance | authority
Single decision question:
Options, evidence, impact ve öneri:
Paused/blocked exact portion + korunmuş çalışma:
Other already-authorized roster features unaffected:
Freshness observed-at + source / answer record location:
Explicitly suppressed routine technical traffic:
```

### Parent resume/restart

```text
MULTI_FEATURE_RESUME
Parent task / authority record / preserved lock revision:
Preserved parent Exact target-main revision:
Current observed main revision + divergence:
MAX_OPEN_FEATURES = 3 / current open count:
Feature roster: task/Issue + System Manager + branch/worktree + exact revision:
Preserved System Manager/topology/routing lock revisions + tek writers:
Relation/dependency/shared-surface owner + runtime/local capability sıra:
Pending review/owner/authority/integration/manual gates:
Freshness check source/time per status/handoff:
Stale veya invalidated evidence + yeniden gereken kontrol:
Next authorized action per eligible feature:
Explicitly not authorized: new/fourth feature, cross-feature WRITE, second writer,
silent manager/routing change, automatic merge/release/adoption.
```

Stale status active/readiness/completion kanıtı değildir.

## 8. Danışma ve routing escalation

```text
CONSULTATION_REQUIRED
Task/repo/exact revision:
Current System Manager:
Requested role:
Single decision question:
Evidence:
Tried paths / learned:
Options + recommendation:
Stopped operation / preserved work:
Authorized response location:
```

```text
ROUTING_ESCALATION_REQUIRED
Task/repo/exact revision + routing lock:
Current System Manager:
Current topology / lane routing:
Observed host support or capacity evidence:
Alternative causes checked:
Proposed new routing + expected benefit:
Explicit auto-escalation authority:
Preserved work / decision owner:
```

Manager değişikliği routing escalation değildir. Local capability ihtiyacı için
`LOCAL_CAPABILITY_REQUIRED` kullan.

## 9. Tam görev sözleşmesi

```text
Görev / kanonik kayıt:
Repo / current canonical revision:
Amaç / kabul edilen davranış:
Kapsam / kapsam dışı:
Başlangıç branch/base/head ve local/remote drift:
System Manager: LOCAL_SYSTEM_MANAGER | GITHUB_SYSTEM_MANAGER
Resolved provider:
System Manager lock revision:
Local capability required: YES | NO
Manual acceptance owner:
Parent orchestration: NONE | MULTI_FEATURE_PARALLEL
Parent lock / Exact target-main revision / MAX_OPEN_FEATURES / Feature roster:
Feature topology: SINGLE | PARALLEL_READ
Topology lock revision:
Lane roster + model / reasoning effort / speed / READ-WRITE:
Routing authority:
Feature relation: INDEPENDENT | COORDINATION_REQUIRED | DEPENDENCY_BLOCKED
SHARED_INTEGRATION_SURFACE:
External research: NONE | ALLOWED_WHEN_NEEDED | REQUIRED
Yetkili işlemler: inspect / write / test / commit / push / PR / merge / device / release
Validation: GITHUB_HOSTED | HUMAN_MANUAL | LOCAL_ONLY
Required independent review / owner gate:
Stop/budget conditions:
Consultation/decision record:
```

## 10. Proje benimseme

```text
Proje kanonik repo/branch:
Benimseme onayı ve kapsamı:
ADS sürümü ve exact source commit:
Core: .agents/ads/CORE.md
System managers: .agents/ads/SYSTEM_MANAGERS.md
Templates: .agents/ads/TEMPLATES.md
Skill keşif konumu ve doğrulama:
Korunan project-specific stronger rules:
Görev/kanıt/stop kayıt yeri:
Validation/device/secret sınırları:
Pilot sonucu: NOT_RUN | gerçek kanıt
```

`tools/prepare_adoption.py` yalnız yerleşimi hazırlar. Dry-run varsayılandır,
`--apply` açıkça gerekir, mevcut hedef dosyalar ezilmez ve target `AGENTS.md`
otomatik değiştirilmez. Benimseme ayrı child review/authority ile etkinleşir.
