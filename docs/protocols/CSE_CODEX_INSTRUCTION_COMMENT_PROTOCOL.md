# CSE Codex Instruction Comment Protocol — Risk-Based v5

**Geçerlilik tarihi:** 2026-09-10

GitHub comment bir amaç değil, kalıcı ve kritik handoff gerektiğinde kullanılan araçtır.

## 1. FAST

FAST işte GitHub instruction comment oluşturulmaz.

Chat içindeki kısa görev yeterlidir:

```text
Goal:
Allowed paths:
Do not change:
Execution time budget: <ChatGPT'nin bu görev için verdiği açık süre; her Codex handoff'unda zorunlu>
Fatih validation:
Commit/push boundary:
```

Issue, comment ID, authority zinciri, routing YAML veya uzun evidence beklenmez.
FAST/`SINGLE` için bu kısa chat handoff davranışı aynen korunur.

## 2. STANDARD

STANDARD işte:

- tek Issue veya kısa self-contained task kullanılabilir;
- resume/correction için mevcut Issue yeterliyse yeni comment yazılmaz;
- kalıcı handoff gerekiyorsa 10–20 satırlık kısa comment kullanılır;
- aynı scope correction için yeni owner authority/comment turu açılmaz.

Minimum comment:

```text
Base/branch:
Goal:
Allowed paths:
Protected contracts:
Execution time budget: <ChatGPT'nin bu görev için verdiği açık süre; her Codex handoff'unda zorunlu>
Fatih validation:
Stop conditions:
Publication boundary:
```

## 3. CRITICAL

CRITICAL execution/correction/review handoff'u GitHub Issue veya PR üzerinde self-contained comment olarak yayımlanır.

Comment gerektiği kadar şunları taşır:

- owner authority;
- expected base/branch/head;
- okunacak kritik kaynaklar;
- exact allowlist;
- required behavior;
- identity/schema/backup/security gibi korunacak contractlar;
- validation ve compatibility gate;
- destructive/user-data sınırı;
- stop conditions;
- commit/push/Ready/merge/release sınırı;
- final provenance beklentisi.

## 4. Feature-içi PARALLEL_READ ortak handoff'u ve tek ana Codex execution'ı

STANDARD/CRITICAL `PARALLEL_READ` işte tek ortak kanonik task/handoff kaydı;
ortak base, goal, allowlist, protected contracts, gates, stop conditions,
topology ve lane routing'lerini taşır. Aynı bilgi Builder, Scout ve Reviewer için
üç uzun comment olarak tekrarlanmaz.

**Owner-facing varsayılan yalnız bir Codex talimatıdır.** Fatih'e ayrı Builder,
Scout ve Reviewer prompt'ları verilmez ve üç ayrı Codex sohbeti/süreci açması
istenmez. CSE Project'in verdiği tek talimat ana Codex'i `Builder/WRITE` olarak
başlatır. Ana Codex, execution yüzeyindeki native Codex collaboration/subagent
yeteneğini kullanarak tam olarak 1 `Scout/READ` ve 1 `Reviewer/READ` subagent'ını
kendisi oluşturur ve yönetir.

Lane-specific rol talimatları owner handoff'u değildir. Bunlar ana Builder'ın
kendi subagent'larına verdiği iç execution talimatlarıdır ve ortak task/routing
lock'una bağlı kalır. Builder ikinci bir writer veya Builder oluşturamaz; roster'ı
genişletemez; topology, model, reasoning effort, speed veya READ/WRITE yetkisini
kendiliğinden değiştiremez.

Scout tek `SCOUT_RESULT` üretir; Builder bu sonucu kendi çözüm döngüsünde tüketir.
Builder final exact revision/snapshot'ı hazırladığında Reviewer'a kendisi verir.
Reviewer yalnız `REVIEW_PASS` veya somut `CHANGES_REQUIRED` üretir.
`CHANGES_REQUIRED` halinde aynı task ve production branch içinde düzeltmeyi Builder
yapar ve yeni exact revision'ı aynı Reviewer'a yeniden inceletir. Fatih agentlar
arası teknik sonuç taşıyıcısı veya orchestration katmanı değildir.

Native collaboration/subagent yeteneğinin bu execution yüzeyinde gerçekten
kullanılamadığı gözlenirse üç manuel Codex session'ı varsayılan fallback yapılmaz
ve topology sessizce `SINGLE`'a düşürülmez. Ana Codex exact capability blocker ile
`ROUTING_ESCALATION_REQUIRED` döndürür. Manuel üç-session `PARALLEL_READ` yalnız
Fatih'in ayrıca açıkça seçtiği task-specific fallback kararıyla kullanılabilir.

ADS Reviewer, zorunlu ChatGPT/owner review veya manual/device gate'inin yerine
geçmez. CSE'nin feature başına tek production writer, tek task/branch/PR,
data-safety ve
publication sınırları aynen korunur.

## 5. Opt-in MULTI_FEATURE_PARALLEL parent lock

Parent mode varsayılan `NONE`'dır. Yalnız owner-approved parent Issue/comment
aşağıdaki alanları exact kaydederse `MULTI_FEATURE_PARALLEL` kullanılabilir:

```text
Parent orchestration: MULTI_FEATURE_PARALLEL
Parent lock revision / exact target master:
Limits: MAX_OPEN_FEATURES = 3; MAX_OWNER_ACCEPTANCE_PENDING = 1
Feature roster (en fazla 3): Issue; branch; canonical-derived worktree; Draft PR;
  scope/allowlist/protected paths; SINGLE|PARALLEL_READ lock; tek Builder/WRITE
Pairwise relation: INDEPENDENT | COORDINATION_REQUIRED | DEPENDENCY_BLOCKED
Classification basis: Workflow Acceleration default relation guidance; exception authority: yok veya exact owner record
SHARED_INTEGRATION_SURFACE: exact path/contract + tam olarak bir owning feature
Cross-feature freshness fields ve serial integration order:
Shared runtime resource lease/serialization:
Stops: same-path writer overlap; hidden sibling dependency; stale evidence;
  automatic fourth/replacement feature; automatic merge/device/release
```

Parent status yalnız koordinasyondur; ROADMAP veya feature authority'sinin yerine
geçmez. Her feature kendi Issue/handoff ve kanıtını korur. Parent lock'ın
oluşturulması feature açmaz; roster activation ayrıca açıkça yetkilendirilir.
Schema/migration/generated DB, recovery/owner-data, application/domain/persistence/
event/history, package/signing/permission/platform/release, MAIN owner-device,
cross-cutting refactor, unmerged-sibling dependency ve non-mechanical shared-contract
conflict kaydı yoksa `DEPENDENCY_BLOCKED` / single-feature varsayılır.

## 6. Kullanıcıya cevap

Comment oluşturulduysa kullanıcıya:

- Issue/PR;
- comment ID/link;
- tek cümlelik pratik amaç

verilir. Uzun comment tekrar chat'e yapıştırılmaz; kullanıcı isterse gösterilir.

`PARALLEL_READ` seçildiğinde owner'a verilen `Hazır Codex talimatı` yine tektir;
Scout/Reviewer için ek kullanıcı prompt'u üretilmez.

## 7. GitHub yazma erişimi yoksa

Comment oluşturulduğu iddia edilmez. CRITICAL iş başlamaz; geçici chat taslağı canonical handoff sayılmaz.

FAST/uygun STANDARD iş, owner'ın current chat talimatıyla ve diğer güvenlik sınırları uygunsa devam edebilir.

## 8. Ana karar

> GitHub instruction comment FAST için yasak gereksiz törendir, STANDARD için koşullu araçtır, CRITICAL için kalıcı güvenlik sözleşmesidir. `PARALLEL_READ` owner-facing olarak tek ana Codex talimatıyla yürür; Scout ve Reviewer ana Builder'ın native read-only subagent'larıdır.
