# CSE Codex Repository Instructions

Bu dosya repository kökünde bütün CSE çalışmalarına uygulanır.

## 1. Kaynak otoritesi

Bilgi türüne göre yetkili kaynaklar:

1. Kalıcı ürün amacı ve veri ilkeleri: `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
2. Operasyon ve Git/Codex güvenliği: `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
3. Model ve reasoning routing: `docs/protocols/CSE_MODEL_REASONING_ROUTING_POLICY.md`
4. Risk-temelli validation: `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md`
5. **Varsayılan workflow lane, correction, local-vs-CI validation ve hızlandırılmış publication:** `docs/protocols/CSE_WORKFLOW_ACCELERATION_PROTOCOL.md`
6. **Owner'a insan-diliyle raporlama ve teknik çıktı tercümesi:** `docs/protocols/CSE_OWNER_COMMUNICATION_STANDARD.md`
7. Güncel ürün kapsamı ve sıra: `docs/v2/CSE_V2_SCOPE.md` ve `ROADMAP.md`
8. Aktif görev: current GitHub Issue/PR ve owner scope kararları
9. Kalıcı manuel test backlog'u: GitHub Issue `#479 — CSE Manual Test Register`
10. Yerel yürütme kaydı: gerektiğinde `.cse/tasks/<issue_no>_task.md` ve `.cse/results/<issue_no>_result.md`

README, eski Epic/Issue ceremony'si, ZIP, handoff, podcast, `.cse/state`, Orchestrator, Bridge, Work Mode veya sohbet hafızası current GitHub ve kanonik kaynak gerçeğini override edemez.

Sabit master SHA, schema veya aktif Issue/PR bu kalıcı dosyada tutulmaz; current durum GitHub/repository üzerinden okunur.

## 2. Zorunlu process lane

Her yeni teknik Issue başlamadan önce yalnız bir lane seçilir:

```text
FAST
STANDARD
CRITICAL
```

Lane tanımları ve standing authority kuralları `CSE_WORKFLOW_ACCELERATION_PROTOCOL.md` içindedir.

Temel kural:

> Riski karşılayan en hafif lane seçilir. Ordinary UI/context/navigation işi sırf karmaşık veya çok dosyalı diye R4/CRITICAL yapılmaz.

- `FAST`: dar UI/docs/navigation/presentation.
- `STANDARD`: cross-module behavior/context/session, fakat persistence/release-critical contract yok.
- `CRITICAL`: schema/migration/backup/restore/destructive/integrity/security/platform/release veya gerçek data-loss riski.

Somut CRITICAL trigger yoksa ağır one-shot authority zinciri yazılmaz.

## 3. Workflow önceliği

`CSE_WORKFLOW_ACCELERATION_PROTOCOL.md`, workflow/test/retry/correction/evidence yoğunluğu konularında eski Issue/authority metinlerinden daha yeni standing owner kararıdır.

FAST/STANDARD'da:

- Issue body standing execution authority'dir;
- aynı scope içinde yeni owner authority gerekmez;
- format/test-harness/analyzer/same-contract source correction aynı implementation window içindedir;
- geniş Flutter doğrulaması mümkün olduğunda PR CI'ya bırakılır;
- review kısa PASS/BLOCKER formatındadır.

Bu öncelik şunları **override etmez**:

- product scope ve exact allowlist;
- schema/migration/backup/version/permission/platform authority;
- production/debug/gerçek kullanıcı veri koruması;
- stable identity/transaction/event/history/integrity/security contract'ları;
- Ready/merge/release için owner kararı.

## 4. Yeni sohbet / resume

### Yeni görev

Bir kez oku:

1. `AGENTS.md`
2. `CSE_UNIFIED_PROJECT_SOURCE.md`
3. `CSE_PROJECT_INSTRUCTIONS.md`
4. `CSE_MODEL_REASONING_ROUTING_POLICY.md`
5. `CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md`
6. `CSE_WORKFLOW_ACCELERATION_PROTOCOL.md`
7. `CSE_OWNER_COMMUNICATION_STANDARD.md`
8. `CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md`
9. `CSE_PROJECT_SOURCE_REGISTER.md`
10. ürün işi ise `CSE_V2_SCOPE.md`
11. `ROADMAP.md`
12. current Issue/PR/branch/master
13. ilgili Issue #479 manual test kayıtları

### Aynı Issue resume/correction

Ruleset hashleri değişmediyse uzun kaynakları tekrar okuma. Yalnız:

- current lane;
- yeni Issue/PR yorumları;
- branch/head/diff;
- kalan correction budget;
- ilgili manual test değişiklikleri

okunur.

Kullanıcı `devam` dediğinde aynı authority metni yeniden üretilmez; current lane'e göre doğrudan sıradaki gerçek işlem yapılır.

## 5. Değişmez güvenlik ilkeleri

- CSE owner-only, local-first ve mobile-first kalır.
- Aynı anda yalnız bir production implementation Issue'su aktiftir.
- Gerçek kullanıcı data root'u açık CRITICAL authority olmadan okunmaz/değiştirilmez.
- Production/debug paketleri sıradan automation tarafından başlatılmaz, temizlenmez veya mutate edilmez.
- Stable identity, optimistic revision, append-only event/history, transaction, backup/restore ve attachment bütünlüğü korunur.
- Force-push, destructive reset/clean/stash, hard-delete ve beklenmeyen kullanıcı değişikliğinin üzerine yazma varsayılan yasaktır.
- Ready, merge, Issue/Epic closure, release/store ve destructive production işlemleri owner onayı gerektirir.

## 6. Local validation vs PR CI

Mobile PR'larında `.github/workflows/flutter_pr.yml` zaten format + analyze + full Flutter test çalıştırır.

Bu nedenle FAST/STANDARD local execution varsayılanı:

- exact scope/allowlist;
- changed-path diff review;
- deterministic format/syntax;
- `git diff --check`;
- protected/schema/backup/version/platform drift;
- STANDARD'da yalnız material fayda varsa tek dar targeted check.

Local full Flutter suite + broad regression + analyzer zinciri, aynı kontroller PR CI'da çalışacaksa varsayılan olarak tekrarlanmaz.

CI failure tek correction round'da topluca ele alınır. Her failure için yeni authority istenmez.

CRITICAL işte Issue'a özel local/integration/device/release gate tanımlanabilir.

## 7. Owner-led manuel test

Uygulama davranışı ve field acceptance owner-led kalır.

User-visible feature sonunda ChatGPT Issue #479'a stable test ID'leri ekler:

```text
MT-<FEATURE_ISSUE>-001
MT-<FEATURE_ISSUE>-002
...
```

Durumlar:

```text
PENDING | PASS | FAIL | PARTIAL | DEFERRED | N/A
```

Manual test `PENDING/DEFERRED` olması development progression'ını otomatik bloke etmez; ancak behavior `VERIFIED/FIELD_ACCEPTED/RELEASE_READY` diye sunulamaz.

## 8. Correction window

FAST/STANDARD varsayılanı:

```text
primary implementation: 1
same-scope correction rounds: 2
environment-only retry: 1 after exact root cause
new owner authority inside same scope: 0
```

Correction round içinde aynı completed CI/review sonucundaki blocker'lar topluca düzeltilir.

Yeni authority yalnız gerçek escalation için gerekir:

- scope/allowlist genişlemesi;
- yeni product/design kararı;
- CRITICAL trigger;
- user-data/destructive risk;
- root cause'un scope içi correction'a indirgenememesi;
- iki correction round'un tükenmesi.

## 9. Evidence yoğunluğu

Aynı bilgiyi Issue/task/result/PR/comment içinde tekrar tekrar yazma.

- FAST: Issue + PR diff + CI ana evidence'dır; `.cse` ledger optional/brief.
- STANDARD: gerekiyorsa 15-40 satırlık concise `.cse` summary.
- CRITICAL: full chronology/provenance tutulabilir.

Completion minimum:

```yaml
issue: NNN
process_lane: FAST|STANDARD|CRITICAL
base: <sha>
head: <sha>
changed_paths: [...]
local_checks: [...]
ci: PASS|FAIL|PENDING
manual_tests: PENDING|...
corrections_used: 0..2
pr: <number>
```

## 10. Review

FAST review:

```text
PASS
```

veya

```text
BLOCKER
- exact defect
- narrow correction
```

STANDARD review aynı şekilde kısa fakat cross-module source/diff odaklıdır.

CRITICAL review R4 evidence kullanabilir.

Format/harness/same-scope source defect FAST/STANDARD'da governance turu açmaz; correction budget kullanılır.

## 11. GitHub publication

- Production branch: `codex/issue-<issue_no>-<slug>`
- Documentation branch: `docs/issue-<issue_no>-<slug>`
- Yeni teknik iş doğrudan `master` üzerinde geliştirilmez.
- PR önce Draft açılır.
- FAST/STANDARD Draft PR sonrası PR CI broad gate'dir.
- Manual test PENDING/DEFERRED iken owner kararıyla merge mümkündür.
- Merge varsayılan squash merge'dir.
- Owner `merge et`, `ready` veya eşdeğer açık talimat verdiğinde ayrıca authority aranmaz.

## 12. Yerel yürütme

Resmî repo:

```text
V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer
```

Local execution gerekiyorsa doğru root ve Git durumu doğrulanır. Beklenmeyen değişiklikte reset/clean/stash yapılmaz.

STANDARD/CRITICAL local Codex task'ında concise task ledger kullanılabilir. FAST işlerde task ledger sırf ceremony için oluşturulmaz.

## 13. Issue/task minimum alanları

FAST/STANDARD:

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

CRITICAL Issue riskin gerektirdiği ayrıntılı provenance/validation alanlarını ekler.

## 14. Build / artifact

APK/AAB her feature sonunda üretilmez.

Build yalnız owner artifact/manual test istediğinde veya CRITICAL/release gate açıkça gerektirdiğinde çalıştırılır.

Artifact varsa source commit, package ID, version, size ve SHA-256 kaydedilir.

## 15. Owner iletişim standardı

Bütün CSE ChatGPT/Codex çıktıları `docs/protocols/CSE_OWNER_COMMUNICATION_STANDARD.md` kuralına uyar.

Owner'a önce **ürün ve pratik anlam** anlatılır; teknik jargon ikinci katmandır.

Önemli durumlarda cevap şu soruları sade Türkçe ile kapsar:

```text
Ne yaptık?
Sonuç ne?
Sorun var mı?
Risk ne?
Benim önerim ne?
Senden ne gerekiyor?
```

Kurallar:

- salt YAML/execution record owner cevabı olamaz;
- SHA, R4, harness, fixture, allowlist, invariant, CI/analyzer gibi terimler ana açıklama olamaz;
- teknik terim gerekiyorsa pratik anlamı hemen tercüme edilir;
- Codex blocker/completion metni owner'a doğrudan kopyalanmaz; ChatGPT önce ürün diline çevirir;
- owner teknik ayrıntıyı okumadan projenin nerede olduğunu ve kendisinden ne beklendiğini anlayabilmelidir;
- teknik evidence silinmez veya çarpıtılmaz; gerekirse ikinci katmanda verilir.

## 16. Current migration

Issue #547 ve sonraki ordinary UI/context işleri `CSE_WORKFLOW_ACCELERATION_PROTOCOL.md` uyarınca FAST/STANDARD'a taşınır.

#547 varsayılanı:

```yaml
process_lane: STANDARD
review_level: R3
local_full_flutter_gate_required: false
pr_ci_is_broad_gate: true
same_scope_corrections_without_new_authority: 2
```

Product scope/allowlist/Attendance protection aynen korunur.

## 17. Ana karar

> CSE'nin varsayılan döngüsü Issue → implementation → Draft PR → CI → kısa review → owner merge'dür. Ağır fail-closed süreç yalnız gerçek CRITICAL risklerde kullanılır. Owner'a her zaman önce yapılan işin ürün/pratik anlamı sade Türkçeyle anlatılır; teknik jargon ve execution evidence ikinci katmandır.
