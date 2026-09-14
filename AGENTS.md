# CSE Repository Execution Instructions

Bu dosya repository kökünde bütün CSE çalışmalarına uygulanır ve günlük execution için tek zorunlu giriş noktasıdır.

## 1. Authority ve güncel gerçek

Güncel gerçek sırası:

1. GitHub `master`, current Issue/PR/branch ve owner kararları;
2. bu `AGENTS.md`;
3. CSE project-specific protokolleri;
4. source-pinned ADS contract ve skills.

Kalıcı kaynaklar:

- ürün amacı/veri ilkeleri: `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`;
- ürün kapsamı: `docs/v2/CSE_V2_SCOPE.md`;
- pre-release kanonik sıra: `ROADMAP.md` Q01–Q26;
- kritik Git/veri güvenliği: `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`;
- lane/publication: `docs/protocols/CSE_WORKFLOW_ACCELERATION_PROTOCOL.md`;
- minimum validation: `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md`;
- model/review routing: ilgili CSE routing policy;
- ADS core: `.agents/ads/CORE.md`;
- ADS System Managers: `.agents/ads/SYSTEM_MANAGERS.md`;
- ADS templates: `.agents/ads/TEMPLATES.md`;
- accepted ADS source record: `.agents/ads/SOURCE.md`.

CSE project rules always remain stronger than ADS. ADS; `FAST | STANDARD | CRITICAL` risk lanes, data/repository safety, ROADMAP ordering, manual/device acceptance, review/publication gates, backup/restore/recovery boundaries or release rules cannot weaken.

Current ADS pin:
`faliardic/ai-development-system@eeee859d6f9ae659078fe4e29a3d82219cb19991`.

README, stale Issue/PR, `.cse/state`, task/result, ZIP, handoff, podcast veya sohbet hafızası current GitHub gerçeğini override edemez.

## 2. System Managers — canonical execution surfaces

CSE iki canonical System Manager kullanır:

- `LOCAL_SYSTEM_MANAGER`: local repository/terminal/tooling execution. Concrete provider Claude Code, Codex veya başka authorized local repository execution agent olabilir.
- `GITHUB_SYSTEM_MANAGER`: ChatGPT + connected GitHub capabilities üzerinden Issue/source/branch/commit/PR/review ve gerçekten mevcut GitHub-hosted validation execution.

System Manager, provider, risk lane ve topology ayrı kavramlardır.

Her task başlangıcında ayrı ayrı kaydet:

```text
CSE risk lane: FAST | STANDARD | CRITICAL
ADS topology: SINGLE | PARALLEL_READ
System Manager: LOCAL_SYSTEM_MANAGER | GITHUB_SYSTEM_MANAGER
Resolved provider
Local capability required: YES | NO
Manual acceptance owner
Execution time budget
Routing/model/effort/speed + READ/WRITE
Scope/Git authority/required gates
```

System Manager capability-first seçilir. Sabit `GitHub > Claude > Codex` sırası yoktur.

`GITHUB_SYSTEM_MANAGER` seçildiğinde ChatGPT, current task authority source implementation + commit/push/Draft PR'yi kapsıyorsa yetkili branch üzerinde repository dosyalarını değiştirebilir. Her dosya mutasyonunda tekrar owner onayı istenmez. Bu owner-approved kural, `CSE_PROJECT_INSTRUCTIONS.md` içindeki önceki “GitHub Contents API yalnız documentation-only” ve “production write yalnız repository-local Execution Agent” ifadelerine **dar, daha yeni execution-surface istisnasıdır**. Bunun dışında Project Instructions içindeki force-push, destructive reset/clean, user-data, CRITICAL, release/signing/device ve safety sınırlarının tamamı aynen geçerlidir.

`GITHUB_SYSTEM_MANAGER` fiziksel device, ADB, local filesystem, local-only profiler, local emulator, signing material veya GitHub/CI'da bulunmayan tooling'e sahipmiş gibi davranmaz. Task acceptance için bunlardan biri gerçekten gerekirse completed GitHub work korunur ve `LOCAL_CAPABILITY_REQUIRED` handoff'u üretilir.

Fatih emulator/device/manual acceptance sahibi olabilir. Bu nedenle GitHub manager'ın ADB/device erişimi olmaması normal source development'ı otomatik blocker yapmaz. Manual gate gerekmeyen task'a sırf GitHub manager kullanıldığı için yeni gate eklenmez.

GitHub-managed work sonrası local write'a dönmeden önce official local clone remote truth ile güvenli senkronize edilir; local status/drift kontrol edilir ve dirty work korunur. Destructive reset/clean/stash yoktur.

## 3. Provider adapters ve execution budget

`LOCAL_SYSTEM_MANAGER` current local provider'ı gerektiğinde Claude Code olabilir; provider-specific bootstrap `CLAUDE.md` ve `.claude/` sınırında tutulur. Codex aynı local manager rolüne geri bağlanabilir. Provider değişimi risk, topology, authority veya publication kuralını değiştirmez.

Provider bootstrap yalnız seçilen manager/provider gerçekten local execution yapacaksa zorunlu okunur. `GITHUB_SYSTEM_MANAGER` task'ında sırf tarihsel current provider Claude Code diye local bootstrap zorunlu değildir.

Her `LOCAL_SYSTEM_MANAGER` Builder handoff'u ChatGPT'nin task-specific belirlediği açık `Execution time budget: <süre>` alanını taşır. Bütçe kapsam, risk, validation/build/device işi ve current blocker'a göre seçilir; global sabit süre yoktur. Bütçe dolduğunda provider yeni yaklaşım veya scope açmaz, mevcut çalışmayı güvenle korur ve exact blocker + kalan tek aksiyonu bildirir.

Local execution gerektiğinde ChatGPT kullanıcının ayrıca `Execution Agent ile çalış` demesini beklemez. `Sıradaki aktör: Execution Agent` diyerek current authority'yi tekrar etmeyen, kopyalanabilir 10–15 satırlık exact handoff hazırlar. Kullanıcıdan bu prompt'u ayrıca istemesi veya `devam` demesi beklenmez.

## 4. Yeni sohbet, resume ve ROADMAP

Yeni görevde minimum okuma:

1. `AGENTS.md`;
2. `.agents/ads/CORE.md` + `.agents/ads/SYSTEM_MANAGERS.md` + task-appropriate ADS skill;
3. current GitHub `master`, open Issue/PR ve active task;
4. `ROADMAP.md` Q01–Q26 current queue;
5. yalnız task riskinin gerektirdiği CSE protocol.

Resume sırasında değişmeyen uzun belgeleri tekrar okuma. GitHub erişimi yoksa current production truth tahmin edilmez.

ROADMAP yönlendirmesi:

- önce current açık production Issue/PR ve owner-approved parent orchestration kontrol edilir;
- parent mode `NONE` iken mevcut production task required gates'e ulaşmadan yeni production child açılmaz;
- yalnız owner-approved `MULTI_FEATURE_PARALLEL` parent lock varsa predeclared roster paralel ilerleyebilir;
- açık uygun task yoksa ROADMAP Q01→Q26 içinde current GitHub gerçeğine göre tamamlanmamış ilk uygulanabilir madde seçilir;
- `DECISION GATE` Fatih kararı olmadan implementation'a dönüşmez;
- `CRITICAL` exact Issue/allowlist/compatibility/manual-device gates olmadan yürütülmez;
- completed/merged madde ancak kanıtlı regression ile dar bug task olarak yeniden açılır;
- GitHub status ve ROADMAP çelişirse status için GitHub, sıra için ROADMAP otoritedir.

Owner talebi canonical workflow'u değiştiriyorsa önce owner kararı Issue/PR authority olarak kaydedilir ve en dar governance change uygulanır; sonra product execution'a dönülür.

## 5. Topology ve tek writer

`SINGLE`: yalnız bir Builder/WRITE.

`PARALLEL_READ`: tam olarak 1 Builder/WRITE + 1 Scout/READ + 1 Reviewer/READ.

- Builder seçilen System Manager üzerinde tek production writer'dır.
- Scout ve Reviewer kesin READ-only'dir.
- Aynı feature içinde `LOCAL_SYSTEM_MANAGER` ve `GITHUB_SYSTEM_MANAGER` eşzamanlı iki writer olamaz.
- Tek feature = tek production branch + tek Draft PR.
- Stacked PR veya path-partitioned multi-writer yoktur.
- Topology, roster, System Manager, role, READ/WRITE, model, effort veya speed sessizce değişmez.
- Required independent reviewer identity, owner review veya device gate bir ADS Reviewer ile otomatik karşılanmaz.

`MULTI_FEATURE_PARALLEL` yalnız owner-approved parent orchestration mode'dur; `SINGLE/PARALLEL_READ` yerine geçmez. Pilot limitleri `MAX_OPEN_FEATURES = 3` ve `MAX_OWNER_ACCEPTANCE_PENDING = 1` olarak korunur. Her feature ayrı Issue, branch/worktree veya GitHub branch, Draft PR, scope/allowlist, risk lane, System Manager, topology lock ve tek writer taşır.

Pairwise relation `INDEPENDENT | COORDINATION_REQUIRED | DEPENDENCY_BLOCKED` olarak kaydedilir. `SHARED_INTEGRATION_SURFACE` exact dar path/contract ve tek owner belirtir. Stale status authority değildir. Integration evidence exact feature revision + exact target-master revision'a bağlıdır.

## 6. Risk lanes

Her task yalnız bir CSE lane kullanır:

### FAST
Dar docs/text/icon/tooltip/spacing/layout/presentation/basic navigation veya persistence contract değiştirmeyen küçük UI işi.

### STANDARD
Birden fazla ekran/modül, session/project context veya persistence/release-critical olmayan orta ölçekli davranış değişikliği.

### CRITICAL
Schema/migration, backup/restore, stable identity/revision, transaction/event/history, attachment/user-file integrity, destructive operation, security/privacy, permission/signing/application ID, background/reboot, DWG conversion data-loss risk, real user data root veya release/store işi.

Detailed lane/publication rules `CSE_WORKFLOW_ACCELERATION_PROTOCOL.md` ve `CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md` içindedir. Concrete CRITICAL trigger yoksa iş sırf dosya/saat sayısı nedeniyle ağır sürece yükseltilmez.

## 7. Validation ve test ownership

Validation gerçek execution surface ile etiketlenir:

- `GITHUB_HOSTED`: gerçekten çalışmış GitHub Actions/check/tooling;
- `HUMAN_MANUAL`: Fatih'in gerçek manuel/device acceptance'ı;
- `LOCAL_ONLY`: local host/device/tooling gerektiren kontrol.

GitHub Actions/check çalışmadıysa PASS uydurulmaz. Source/diff review, test execution değildir. Required local-only validation varsa GitHub source work korunur ve yalnız exact local gate `LOCAL_CAPABILITY_REQUIRED` ile devredilir.

Fatih terminal/Git/Flutter/test/analyzer/build komutu çalıştırmaz; manuel ürün/device acceptance ve nihai davranış PASS/FAIL kararının sahibidir. Local mechanical emulator/ADB/device execution ancak exact package/device/data-safety owner delegation ile `LOCAL_SYSTEM_MANAGER`a verilebilir.

Aynı exact source revision + relevant environment için geçen test gereksiz tekrarlanmaz. Full suite her mikro adımda değil, CSE protocolünün gerektirdiği milestone/release gate'inde çalıştırılır.

## 8. Git, publication ve Issue disposition

- Force-push yoktur.
- Destructive reset/clean/stash yoktur.
- Unexpected tracked/untracked veya dirty local work silinmez/üzerine yazılmaz.
- Required review/validation/manual gate FAIL/PENDING iken Ready/merge yoktur.
- Required gates PASS/GEREKMİYOR, blocker/REQUEST_CHANGES/scope/base-head drift/conflict/mergeability sorunu yoksa current task publication authority kapsamındaki authorized Builder/System Manager standing owner authority ile Ready + squash merge yapabilir.
- Bu koşullar sağlandığında Ready/merge için Fatih'ten ikinci bir açık onay istenmez; standing owner authority yeterlidir. Tekrar onay talebi yeni bir owner gate oluşturmaz ve normal task completion akışını durdurmaz.
- Yalnız task authority'nin açıkça ayırdığı gerçek owner/manual acceptance, release/store/signing, destructive production/device/data işlemi veya yeni product/authority kararı gerekiyorsa `OWNER_WAIT` kullanılır.
- CRITICAL merge yalnız Issue-specific bütün validation/compatibility/manual gates sonrası mümkündür.
- Release/store, signing ve destructive production/device/data işlemleri ayrı explicit owner approval ister.
- `Closes #...` yalnız merge ile gerçekten tamamlanan tek amaçlı Issue için; parent/umbrella/manual-acceptance/release/continuing kapsam `Refs #...` olarak açık kalır.
- Merge sonrası local `master` bir sonraki local write öncesi safe `--ff-only` sync mantığıyla güncellenir; dirty work korunur.

#502 recoverability/owner-data preservation, #503 restore safety ve #504 recovery boundaries P0 otoriteleridir. Worktree/manager ayrımı runtime resource izolasyonu kanıtı değildir; physical device, signing, recovery/migration fixture, shared build outputs ve güvenli parallel mutation'ı kanıtlanmamış global caches gerektiğinde serial owner lease kullanır.

## 9. Çıktı ve kullanıcıya aktarım

Kullanıcıya önce sade Türkçe anlam ver; SHA/branch/allowlist/test harness ikinci katmandır.

Her teslim şunları ayırır:

```text
Değişen davranış
Exact revision
System Manager + provider
Validation: GITHUB_HOSTED | HUMAN_MANUAL | LOCAL_ONLY
Review/gate durumu
Commit/push/PR/merge ayrı gerçek durumları
Remaining gate + owner
```

Kullanıcıya teslim edilen sonuç şu satırla biter:

`Sıradaki aksiyon — <ChatGPT|Execution Agent|Fatih|Yok>: <tek uygulanabilir talimat>.`

`Sıradaki aksiyon — Fatih` yalnız gerçekten owner product/authority kararı, manual/device acceptance veya ayrı release/destructive onayı bekleniyorsa kullanılır; sırf Draft PR'ı Ready yapıp merge etmek için tekrar onay istemek amacıyla kullanılmaz.

Bir aksiyon tamamlandığında yalnız sonraki işin adı verilmez; aynı yanıtta seçilen aktörün başlayabileceği hazır talimat da hazırlanır. `Execution Agent` için 10–15 satırlık exact handoff ve execution time budget; Fatih için yalnız kısa manual/device kontrolü verilir. ChatGPT kendi standing authority'sindeki sonraki koordinasyon işini kullanıcıdan yeni `devam` istemeden yürütür.

`Execution Agent` burada local execution gerektiğinde `LOCAL_SYSTEM_MANAGER` Builder'ının kullanıcı-facing kısa adıdır. GitHub-managed source task'larında sıradaki aktör doğrudan ChatGPT olabilir.

## 10. ADS path resolution

Adopted skill'lerde source-context path'ler CSE içinde şöyle çözülür:

- `CORE.md` -> `.agents/ads/CORE.md`;
- `SYSTEM_MANAGERS.md` -> `.agents/ads/SYSTEM_MANAGERS.md`;
- `TEMPLATES.md` -> `.agents/ads/TEMPLATES.md`.

Root'a bu ADS dosyalarının kopyası oluşturulmaz. Path alias ADS bytes veya authority değiştirmez.

## 11. Ana karar

> CSE owner-only, local-first/mobile-first ürün olmaya devam eder; execution surface artık provider kotasına bağlı değildir. GitHub-capable normal source/Git/Issue/PR work `GITHUB_SYSTEM_MANAGER` ile, local-only capability gerçekten gerektiğinde `LOCAL_SYSTEM_MANAGER` ile yürütülebilir. CSE risk lanes, data/repository safety, publication, manual acceptance ve release/destructive gates her iki manager için aynen bağlayıcıdır.
