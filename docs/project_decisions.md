# Proje Kararlari

## Issue 367 — Work Mode yönetir, yerel loop yalnız açık handoff alır

- GitHub Issue/PR koordinasyonu ve uzaktan yapılabilen geliştirme/test işleri
  ChatGPT Work Mode tarafından yürütülür.
- Windows `CSE Codex Loop`, yalnız en son trusted-owner approval yorumunda
  `CSE_LOCAL_GATE_REQUEST` exact satırı bulunan hazır görevi seçer.
- Genel `CSE_BRIDGE_APPROVED` yerel kabul değildir; explicit Issue numarası da
  bu sınırı atlayamaz.
- Dedicated control clone, pil ayarları, fail-closed güncelleme, scope,
  validation, review, publication ve cleanup sözleşmeleri değişmez.
- Platform API, API anahtarı, production/mobile ve cihaz davranışı eklenmez.

## Issue 305 — Display Power bilgi satırı state sinyali değildir

- `Display Power: state=ON|OFF` exact supported sinyaldir. State anahtarına
  benzeyen boş, unknown veya malformed aday fail closed kalır.
- Exact state anahtarı taşımayan `Display Power:` object/header/callback bilgisi
  sinyal veya malformed state değildir ve parser kararından ignore edilir.
- Wakefulness alias mapping, `mInteractive`, cross-signal conflict, bağımsız
  keyguard, exact tablet/model/package ve shell-free/destructive/real-user
  guard'ları değiştirilmez. Raw dumpsys output log/evidence değildir.
- Yeni controller handoff yalnız authorization `5170082561` içindeki exact
  32-event, fifth-pause predecessor'a açıktır. Stage, attempts/pauses/admissions,
  budgets, evidence, artifact ve sıfır effect exact korunur.
- Root ve önceki üç successor authorization/metadata/manifest/ledger byte'ları
  immutable kalır. Dördüncü successor idempotenttir; drift, rollback, corrupt
  history, duplicate veya later successor `controller_handoff_not_safe` olur.
- Product/mobile, Issue #284 runtime/target/APK ve build/install/ADB/tablet bu
  implementation run'ında değiştirilmez veya çalıştırılmaz.

## Issue 305 — Wakefulness alias'ları semantik olarak birleştirilir

- `mWakefulness` token'ları regex dalıyla değil tek mapping ile semantiğe
  çevrilir: `Awake/1` interactive, `Asleep/0`, `Dreaming/2`, `Dozing/3`
  non-interactive'dir.
- Aynı boolean semantiği bildiren tekrarlar tutarlı kabul edilir. Symbolic/
  numeric veya diğer power signal mismatch'i `conflicting`; unknown/malformed
  değer ve signal yokluğu fail-closed `malformed` sonucudur.
- Raw dumpsys output log/evidence değildir. Existing interactive/display
  desteği, bağımsız keyguard ve exact tablet/device/destructive guard'ları
  değiştirilmez.
- Yeni controller handoff yalnız authorization `5169514740` içindeki exact
  29-event, fourth-pause predecessor'a açıktır. Attempts/pauses/admissions,
  budgets, evidence, artifact ve sıfır effect exact korunur.
- Root ve iki predecessor successor authorization/metadata/manifest/ledger
  byte'ları immutable kalır. Üçüncü successor idempotenttir; drift, rollback,
  duplicate veya dördüncü successor `controller_handoff_not_safe` sonucudur.
- Product/mobile, Issue #284 runtime/target/APK ve build/install/ADB/tablet bu
  implementation run'ında değiştirilmez veya çalıştırılmaz.

## Issue 305 — Controller düzeltmesi eski workflow tarihçesini yeniden yazmaz

- Ortak GitHub GET adapter'ı stdout/stderr'i binary yakalar ve yalnız caller
  thread'de strict UTF-8 çözer. Windows locale'i API JSON contract'ına authority
  olamaz; invalid byte ve adapter hataları raw içeriksiz stable reason'dır.
- Evidence sink ortak client error'unu `WorkflowError` sınırına çevirir. CLI
  traceback veya raw comment yerine structured `UNSAFE_BLOCKED` üretir.
- Existing Issue #284 ledger yalnız `RUNNING`, tek `workflow_started`, stage `0`
  ve tüm admission/effect alanları boşsa controller handoff'a uygundur.
- Old authorization, manifest ve ledger immutable kalır. New origin/master SHA
  predecessor'ın descendant'ı ve bütün target/evidence/artifact/tool/device/
  publish/stage contract'ları exact eşitse ayrı successor authorization/workflow
  identity exclusive yazılır.
- Successor aynı SHA için idempotenttir. İkinci successor, controller rollback,
  advanced/tampered ledger veya contract drift `controller_handoff_not_safe`
  sonucudur; dar correction zincirleme authority üretmez.
- Product/mobile, Issue #284 target/APK/live runtime ve device akışı bu
  implementation run'ında değiştirilmez veya çalıştırılmaz.

## Issue 305 — Evidence hash'i içerik ile transport'u ayırır

- GitHub Markdown evidence doğrudan platforma özgü metin byte'larıyla değil,
  leading BOM'u kaldıran, CRLF/CR'ı LF yapan ve terminal newline'ı deterministic
  temsil eden `canonical_markdown_bytes(...)` üzerinden hashlenir.
- Canonicalization iç whitespace, kelime, sayı, link, başlık veya karakter
  değiştiremez. Bu alanlardaki her drift action başlamadan fail-closed kalır.
- Evidence blocker raw içerik loglamadan exact source ID taşır. Frozen hash
  değişikliği yalnız hash-only canlı diagnostic semantik eşitliği kanıtlarsa
  yapılabilir.
- Bootstrap evidence adapter'ı GitHub JSON'unu Windows locale'ine bırakmaz;
  yalnız GET argv, `shell=False` ve strict UTF-8 decode kullanır.
- Bu correction Issue #284 target/runtime state'ini veya product/mobile/device
  akışını değiştirmez; gerçek canlı pilot ayrı workflow execution'dır.

## Issue 305 — Canlı pilot authorization'ı target ve kanıttan türetilir

- Target-specific workflow JSON'u operator tarafından elle taşınmaz. Bootstrap;
  current controller revision, exact checkpoint/tree/blob, frozen Issue evidence,
  artifact/tool/device ve publish contract'ını doğrulayıp canonical schema-v2
  authorization üretir.
- Frozen Issue body/comment SHA-256 kümesi `evidence_source_fingerprint` olarak
  authorization'a girer. Reused PASS ayrıca current source/tool/command/artifact
  fingerprint'i eşleşmeden stage atlatamaz.
- İlk execute authorization'ı repository dışı immutable bootstrap store'a yazar;
  resume bu exact payload'ı yükler. Böylece yetkili completion diff'i yeni bir
  workflow üretmez ve stored payload tamper'ı metadata/contract ile reddedilir.
- Tablet smoke arbitrary shell/ADB string'i değil typed semantic action'lardır.
  Production adapter yalnız exact serial/model/debug package ve synthetic title
  kabul eder; telefon, gerçek kayıt ve destructive operation API yüzeyinde yoktur.
- Smoke adımları ayrı ledger stage'leridir. Her PASS sonrası process crash'i
  replay ile önceki stage'i çalıştırmadan sürer; device yokluğu artifact'i
  koruyan external pause'tur.
- O10.1 implementation fake-adapter validation'dır. Gerçek Issue #284 build,
  install ve tablet smoke ancak merged controller revision'da explicit bootstrap
  execute ile ayrı canlı workflow olarak başlar.

## Issue 303 — Workflow ledger otoritedir, prompt zinciri değildir

- Bir development run'ının bütün mekanik stage'leri tek machine-readable
  workflow authorization içinde exact sıralama ve budget üst sınırıyla
  bağlanabilir. Aynı scope içinde PASS sonrası yeni kullanıcı prompt'u gerekmez.
- Controller source checkout, target repository/worktree ve runtime root ayrı
  provenance alanlarıdır. Çalışan package source root'u authorization'daki temiz
  controller revision ile aynı checkout olmalıdır.
- Immutable contract manifesti ve append-only hash-chain event ledger otoritedir;
  projection cache yalnız yeniden üretilebilir hızlandırıcıdır. Cache kaybı
  workflow'u ilerletmez, ledger'dan exact state'i yeniden kurar.
- Aynı action sonuçsuz ikinci admission alamaz. Authorized correction yeni
  attempt identity taşır; exact source/tool/command/artifact fingerprint'li PASS
  ise invocation olmadan reuse edilebilir.
- External device/ağ yokluğu terminal failure değildir: artifact provenance
  korunarak `PAUSED_EXTERNAL` olur. Hash/allowlist/branch/secret drift'i
  `UNSAFE_BLOCKED`, gerçek ürün/risk kararı `AWAITING_USER_DECISION` olur.
- GitHub evidence, commit, normal push ve Draft PR duplicate-safe'tir. Merge,
  release, Ready, branch delete ve product/mobile/device kapsam genişlemesi
  workflow authorization'ın dışında kalır.

## Issue 299 — Model planı local authority değildir

- Responses API yalnız `OPENAI_API_KEY` ve `OPENAI_MODEL` environment
  değişkenleriyle, `store=false`, strict JSON Schema, bounded input/output ve
  retry `0` sözleşmesinde kullanılır. Raw prompt/response ve authorization
  header evidence veya ledger'a yazılmaz.
- Structured proposal untrusted input'tur. Unknown/missing alan, exact
  allowlist/command/approval drift'i, policy deny veya budget/fingerprint
  uyumsuzluğu dış adapter başlamadan fail-closed olur.
- Source, contract ve action fingerprint'leri model output'una verilmiş mutable
  karar alanları değildir; local immutable contract ile child request arasında
  doğrulanır. Model capability, action seti veya budget genişletemez.
- Codex child yalnız help inventory'sinde kanıtlanan exact stdin argv, exact
  repository cwd, allowlisted environment adları, `shell=false`, bounded
  timeout/output ve unique action fingerprint ile çalışır. Prompt geçici
  external runtime dosyasından stdin'e verilip silinir.
- GitHub REST adapter exact repo/branch/base/head/divergence/Issue bağını ve
  existing PR yokluğunu doğrular; yalnız tek Draft PR mutation'ı sunar. Normal
  push O8 controlled runner'da kalır. Force, Ready, merge, close, delete ve
  release endpoint'i yoktur.
- `api-run` default dry-run'dır. API, Codex child ve publish ayrı explicit
  execute gate'leridir; sonraki gate önceki gate olmadan açılamaz.
- Credentials yoksa implementation fake adapters ile doğrulanır ve live pilot
  `CREDENTIALS_MISSING` kalır. Secret istenmez, üretilmez veya repository'ye
  yazılmaz.

## Issue 297 — Gerçek action tek kullanımlık plan ve ledger ile çalışır

- İlk live pilot yalnız source değiştirmeyen exact pytest action'ını gerçek
  `SubprocessProcessAdapter` ile çalıştırır. Exact argv, cwd, source/contract/
  action fingerprint ve environment-name allowlist immutable execute planına
  bağlıdır.
- Repository pytest addopts değeri yalnız bu invocation için `-o addopts=` ile
  temizlenir; `--color=no`, O3'ün explicit `30 passed` summary token'ını
  deterministic okumasını sağlar.
- Environment yalnız sekiz allowlisted ad üzerinden process'e aktarılır;
  değerler plan, ledger, result veya repository evidence'ına yazılmaz.
- Approval consumption, `full_gate_used +1` budget admission ve
  invocation-start provenance subprocess'ten önce aynı append-only admission
  event'ine yazılır. Result event'i raw stream değil O3 veri-minimal sonucudur.
- Exit code tek başına PASS değildir. Kabul; `failure_class = null`,
  `passed = 30`, `failed = 0`, ledger verification PASS ve duplicate execute'ın
  adapter çağrısından önce BLOCKED olmasıyla birlikte sağlanır.
- Runtime ve ledger repository dışında kalır. Önceki ledger'lar immutable
  read-only kanıttır; yeni authorization yeni run/action/fingerprint ve yeni
  ledger gerektirir.
- Pilot production/mobile/tools/tests/dependency/workflow/`.cse/state`, build,
  device, OpenAI API veya Orchestrator-driven GitHub mutation yetkisi değildir.
  Ready, merge, Issue close, branch delete ve release ayrı insan kararıdır.

## Issue 295 — O5-O8 execution approval ile process arasında immutable plan ister

- O1 Observation ve O2 invocation admission doğrudan subprocess yetkisi
  değildir. Exact argv/cwd/repository/branch/base/head/tree, allowlist,
  capability, budget ve source/contract/action fingerprint bağları immutable
  `ActionPlan v1` içinde canonical hash ile dondurulur.
- Planner, gate builder ve publish-plan saf/deterministic kalır; subprocess,
  network veya filesystem mutation yapmaz. Default mode `dry_run`dır.
- Controlled action yalnız execute-mode plan, explicit execute flag, allowed
  policy decision, current source/action fingerprint recheck ve repository-dışı
  admission ledger ile başlayabilir. Real adapter `shell=False` exact argv
  kullanır; testler yalnız injected fake adapter kullanır.
- Approval consumption, budget admission ve invocation-start provenance aynı
  append-only admission event'inde tutulur. Ledger monoton sequence ve
  previous-hash zinciri taşır; duplicate action veya tamper fail-closed olur.
- Raw stdout/stderr ledger'a yazılmaz. Frozen result O3 parser üzerinden hash,
  bounded sanitized excerpt, failure class ve action-start budget evidence'ına
  dönüşür.
- CHECKPOINT_COMMIT, BUILD, DEVICE ve PUBLISH ayrı action/approval/budget
  kapılarıdır. Bir gate PASS'i sonraki gate authority'si değildir.
- Device planı gerçek serial taşımaz; yalnız sembolik target kabul eder.
  Uninstall, clear-data ve hard-delete varsayılan olarak yasaktır.
- Publish yalnız exact normal push ve `master` hedefli tek Draft PR'dır.
  Force-push, blind retry, duplicate PR, Ready, merge, Issue close, branch
  delete ve release bu adapter kapsamı dışındadır.
- Runtime root repository içinde olamaz. Secret/raw authorization-comment body,
  kullanıcı verisi ve ignored kullanıcı alanı plan/result/ledger kaynağı değildir.
- O5-O8 completion O0-O8 zorunlu Orchestrator MVP'yi tamamlar; O9 OpenAI API
  planner ve O10 service/tray ayrı future approval/faz olarak kalır.

## Issue 277 — Hatırlatıcı Exact Hızlı Planlama Zamanları

- `Yarın sabah` ve timed `Yarın 08:00`, operation anına göre
  Europe/Istanbul ertesi gün yerel `08:00` değeridir. Timed snooze mevcut
  hatırlatıcı saatini kopyalamaz.
- `Hafta başına ertele`, içinde bulunulan günü değil her zaman sonraki
  pazartesi yerel `08:00` değerini seçer; pazartesi günü sonuç `+7 gün`dür.
- Domain katmanındaki saf resolver source-of-truth'tur. Form preview'si,
  detail schedule sheet, create, reschedule ve timed snooze aynı resolver
  ailesini kullanır.
- UI seçim anındaki canonical preview'yi command'a taşır. Application,
  operation anında değeri yeniden çözer; eşleşmiyorsa sessiz fallback yerine
  fail-closed validation döndürür.
- All-day `Yarına ertele` ayrı dalda yerel günü bir artırır;
  `next_attention_at` ve saatli notification binding'i oluşturmaz.
- Canonical reminder row, append-only event payload ve notification binding
  aynı exact timestamp'i taşır. Schema `10`, backup formatı `1`, migration,
  storage DDL, gateway ve Android native sözleşmeleri değişmez.
- Tablet-only PASS bu Issue'nun fiziksel tamamlanma kapısıdır. Telefon
  promotion ve D29.3'ün diğer maddeleri kapsam dışıdır.

## Issue 272 — Delivered One-Time Notification İzolasyonu

- Native pending listesinde bulunmamak tek başına terminal kanıtı değildir.
  Source reminder aktif, trash olmayan, due, one-time ve önceki schedule
  binding'ine sahipse delivered notification preserve edilir.
- Reconciliation disposition'ı `schedulable`, `preserveDeliveredOneTime` ve
  `terminal` olarak application katmanında ayrılır. Gateway veya Android native
  API'sine yeni displayed-notification sorgusu eklenmez.
- Preserve edilen kayıt cancel/reschedule edilmez, binding'i güncellenmez ve
  kapasite tüketmez. Permission, channel, exact-alarm ve pending-query failure
  dalları aynı korumayı sürdürür.
- Terminal cleanup yalnız kendi stable platform notification ID'sini hedefler.
  Orphan ve mismatched pending payload cleanup'ı, UUID deep-link'i, optimistic
  revision ve append-only event sözleşmeleri korunur.
- Schema `10`, backup formatı `1`, migration, storage, package/signing ve native
  notification configuration değişmez.

## Issue 262 — Hatırlatıcı Yarına Ertele Uygunluğu

- `Yarına ertele` kart, detay ve direct application mutation için
  `isReminderEligibleForTomorrowSnooze` adlı tek domain helper'ından karar alır.
- Uygunluk Europe/Istanbul yerel günündedir. Timed reminder
  `next_attention_at` UTC değerinden yerel güne çevrilir; all-day reminder
  `all_day_local_date` değerini kullanır.
- Yalnız `active`, trash olmayan, `attendanceDayId == null` ve due yerel günü
  bugün veya geçmiş olan reminder uygundur. Yarın/gelecek, terminal, trash,
  Puantaj kaynaklı ve plansız reminder fail-closed reddedilir.
- Puantaj dışındaki source bağlantıları varsayımla yasaklanmaz. Ajanda veya Beton
  kaynağının schedule ownership'i ayrı açık sözleşme olmadan değiştirilmez.
- Uygun olmayan mutation row/revision/event/notification binding üzerinde
  değişiklik yapmaz. Uygun mutation aynı transaction/event ve mevcut
  notification reconciliation yolunu kullanır.
- `snoozeTomorrowMorning` aynı event ID retry'si mevcut sonucu döndürür ve
  duplicate event üretmez; yeni event ID ile stale revision fail-closed kalır.
- Schema `10`, backup formatı `1`, Puantaj recurrence/occurrence motoru ve
  notification platform sözleşmeleri değişmez.

## Issue 260 — Beton Checklist Source-of-Truth

- Açık zorunlu checklist sayısı saklanan ayrı bir sayaç değildir. Current
  `ConcreteCheckItem` satırlarında `isRequired && status == pending` kuralıyla
  üretilen domain read-model hem detay başlığının hem transition validation'ın
  source-of-truth'udur.
- `inspection_notified` ve `laboratory_appointment` system-owned kalemlerdir.
  Bulk veya `updateCheck` ile tamamlanamaz; yalnız Beton paketindeki kaynak
  alanların current değeriyle aynı transaction içinde set/clear senkronu yapılır.
- Alan-türetilmiş checklist değişikliği optimistic revision ve append-only
  `check.updated` event'i üretir. Event insert veya reminder/follow-up sync
  hatası source alan güncellemesiyle birlikte rollback olur; deterministic event
  ID aynı işlemin retry'ında duplicate history üretmez.
- UI, manuel bulk kapsamını açıkça adlandırır ve pending system-owned kalemleri
  mevcut ortak laboratuvar/yapı denetim dialog'una exact eylemlerle yönlendirir.
  Mutation dönüşü fresh detail reload edilir; ayrıca refresh gerektirilmez.
- Schema `10`, backup formatı `1`, migration, Android package/signing ve Beton
  kapanış validation'ları değiştirilmez.

## Issue 230 — Reminder Kaynak Ajanda Fotoğrafları

- Reminder kaynak medyası ayrı, salt-okunur
  `ReminderSourceAgendaMediaApplication` capability'siyle okunur; UI SQLite'a
  doğrudan erişmez ve attachment byte/metadata'sı reminder state'ine kalıcı
  olarak kopyalanmaz.
- Kaynak read-model aktif fotoğrafları `created_at, id` sırasıyla verir ve
  duplicate photo ID'yi ilk kayıt korunarak tekilleştirir. Arşivli source log
  okunabilir; arşivli fotoğraf gösterilmez.
- Thumbnail ve tam ekran açma mevcut `readAgendaPhoto` ile
  `AgendaPhotoViewerPage` yolunu paylaşır. Integrity kontrolü bypass edilmez;
  `missing`, `tampered` ve `invalidMime` kayıtlar güvenli diagnostic ile görünür
  kalır.
- Kaynak DB/attachment okuma hatası reminder ana detayını düşürmez ve kişisel
  path/hata içeriği UI'a taşınmaz.
- Schema 9, backup format 1, attachment store, platform kodu ve source
  revision/event geçmişi değişmez. Reminder detayından attachment mutation'ı
  eklenmez.

## Issue 171 - Faz 0 Closure ve Faz 1 Geçiş Kararları

- Faz 0 closure sonucu `PASS`tır. Bu karar P0.01–P0.09 merged kanıtı, current
  repository truth, compatibility, pilot/security sınırları ve final full-suite
  kontrolüne dayanır; field-ready veya production-ready iddiası değildir.
- P0.10, Issue #171 branch'i merge edilmeden Issue #128 üzerinde tamamlandı
  işaretlenemez. Issue #127 ve #128 bu çalışma sırasında kapatılmaz.
- Dört kanonik karar belgesi ayrı sorumluluk taşır:
  `docs/adr/ADR-0001-single-memory-and-record-scope.md`,
  `docs/adr/ADR-0002-memory-index-record-ref-read-model.md`,
  `docs/adr/ADR-0003-backup-memory-download-project-package.md` ve
  `docs/adr/ADR-0004-owner-only-security-and-data-ownership-threat-model.md`.
- ADR kararı production implementation değildir. Scope field/conversion,
  archive/unarchive, MemoryIndex, Hafıza UI, Hafızayı İndir, Proje Paketi, app
  lock ve encryption henüz uygulanmamıştır.
- SQLite schema `4`, restore schema allowlist `(2, 3, 4)`, Backup format `1` ve
  Günlük Çıktı format `1` current compatibility gerçeğidir; Issue #171 bunları
  veya wire manifestlerini değiştirmez.
- Legacy removal için doğrulanmış silme adayı `0` kalır. Zero-reference,
  executable replacement, eski veri ve backward compatibility kanıtı olmadan
  fiziksel silme yoktur.
- Gerçek 7/30 günlük pilot yürütülmedi. Pilot eksikliği Faz 0 karar closure'ını
  değil, gelecekteki field/release readiness kapısını açık tutar.
- Issue #171 merge'i sonrasında sıradaki tek faz Issue #129'dur. İlk dar aday
  P1.01 olay zamanı sözleşmesi ve migration preflight'tır; archive veya
  MemoryIndex işine bağımlılık sırası atlanarak başlanmaz.
- P1.01 için öneri `standart full Codex` ve `High` reasoning'dir. Gerçek schema
  migration veya daha geniş production değişikliği ayrıca yetkilendirilmeden
  bu önerinin parçası değildir.

## Issue 169 - Owner-only Güvenlik ve Veri Sahipliği Kararları

- CSE tek kullanıcı ürünüdür; bu karar auth, app lock, session, encryption veya
  cihaz güveni varmış gibi yorumlanamaz.
- Normal launcher yalnız `127.0.0.1` kullanır. LAN ayrı security gate olmadan
  güvenli production modu değildir; public exposure critical blocker'dır.
- `private | project` erişim kontrolü değil output/paylaşım uygunluğudur.
  Project ID veya MemoryIndex source scope ve revision yerine geçemez.
- Source domain kayıtları ve append-only event geçmişi truth'tur; projection,
  cache, artifact, diagnostic ve pilot log source değildir.
- Backup v1 integrity/recovery kontrolü taşır fakat şifreli değildir. Verify ve
  new-target clean Restore olmadan recovery garantisi verilmez.
- Confirmed data loss/corruption, private/wrong-project leakage, unauthorized
  LAN/public access, Backup/Restore, malicious attachment ve update integrity
  failure pilotu ve ürün genişlemesini durdurur.
- App lock/session, encrypted Backup/Hafızayı İndir, secure LAN, health
  diagnostics, redacted logs, signed update/supply-chain ve recovery drill
  ayrı executable implementation Issue'larıdır.
- GitHub kullanıcı verisi storage alanı değildir; uninstall/update data root'u
  sessizce silemez; diagnostic/pilot kayıtları minimizasyon ve retention ister.
- Issue #169 production/test/schema/migration/UI/route/CLI veya network
  davranışı değiştirmedi ve gerçek exposure/penetration testi yürütmedi.

## Issue 167 - Saha Kabul Metrikleri ve Pilot Protokolü Kararları

- Saha kabulü yalnız hız metriği değildir; performans, veri kaybı, missed follow-up, attachment bütünlüğü, Backup/Restore, haricî araca dönüş, privacy ve ölçüm bütünlüğü birlikte değerlendirilir.
- Capture süresi kullanıcı niyetinden başarılı görünürlüğe/vazgeçişe; retrieval süresi arama niyetinden doğru detail açılışına/vazgeçişe kadardır. Başarılı örneklerde median ve nearest-rank p90, bütün valid örneklerde failure rate ayrıca raporlanır.
- Performance için aktif günde ilk üç capture ve ilk iki retrieval örneklenir. Veri kaybı, missed follow-up, attachment, Backup/Restore, scope/privacy ve unsafe workaround olayları örneklenmez; census ile tamamı sayılır.
- 7 günlük gate en az 5 aktif gün, 10 capture, 8 retrieval, bütün gerçek attachment kontrolleri ve Gün 0/Gün 7 Backup verify ister. 30 günlük gate en az 20 aktif gün, 40 capture, 24 retrieval, haftalık verify ve en az bir clean Restore rehearsal ister. Minimum yoksa sonuç `INSUFFICIENT_EVIDENCE`dır.
- Confirmed veri kaybı, critical CSE kaynaklı missed follow-up, confirmed attachment integrity failure, private/wrong-project leakage ve Backup/Restore failure blocker'dır. Suspected safety olayı triage bitene kadar pilotu durdurur.
- Backup verify ile clean-target Restore ayrı metriktir. Restore yalnız var olmayan disposable hedefte; repository reopen, revision/event ve attachment reconciliation kontrolleriyle PASS olabilir.
- Doldurulmuş pilot logu source record, Backup, Hafızayı İndir veya Proje Paketi değildir. Gerçek kayıt/arama metni, source UUID, kişi/proje, attachment içerik/ad/path/hash, screenshot, ham mesaj ve absolute data-root path pilot logunda tutulmaz.
- Pilot-local `event_id` ve `incident_id`, süre, sayaç, kategori, reason/severity/evidence status ve PASS/FAIL yeterli minimum kanıttır. Hassas incident kanıtı repository veya GitHub'a konmaz; owner-controlled ayrı alanda tutulur.
- Performance warning kabul edilmiş ölçülebilir revalidation planıyla conditional olabilir. Confirmed safety/privacy blocker plan yazılarak PASS'e çevrilemez; düzeltme sonrası yeni doğrulama penceresi gerekir.
- 7 günlük devam ve 30 günlük Faz 1 kararı otomatik üretilmez; minimum kanıt ve safety gate sonrası pilot owner tarafından açıkça verilir.
- Issue #167 gerçek pilot, telemetry/analytics, otomatik timer, background job, cloud, production/test/schema/migration/UI/route/CLI, artifact formatı, ADR veya gerçek kullanıcı verisi uygulamaz.

## Issue 165 - Legacy Model Envanteri ve Deprecation Kararları

- Sınıflandırma dosya yaşına veya adına göre değil; production import/call site, test/fixture/smoke/acceptance, schema/migration/restore, Backup/export/parser, kanonik doküman ve uygulanmış replacement kanıtlarının birlikte okunmasıyla yapılır.
- Dört exact sınıf `Aktif çekirdek`, `Dönüştürülecek`, `Legacy / arşivlenecek` ve `Silme adayı`dır. Replacement yalnız ADR'de tanımlıysa değil, executable implementation ve kabul testleri varsa “mevcut” sayılır.
- `app/models.py` tek sınıfa alınmaz. `FieldObservationRecord` çalışan source model olarak `Dönüştürülecek`; eski prototip, NCR, attachment, audit, record-ID, export ve handover helper kümeleri ise ayrı legacy inventory satırlarıdır.
- SQLite schema v4, immutable v1-v4 migration geçmişi, schema 2/3 restore desteği, repository/mapper/UoW, managed attachment store, Backup v1 ve Günlük Çıktı v1 runtime veya backward compatibility nedeniyle aktif çekirdektir.
- Observation, follow-up ve routine source/application/web yüzeyleri silinmez veya tek tabloya taşınmaz; ADR-0001 scope ve ADR-0002 transactional projection gereksinimleri ayrı migration/implementation Issue'larıyla eklenir.
- Legacy handover QC/export helper zinciri, ADR-0003 Proje Paketi builder/verifier'ına rename edilmez. Yeni artifact ailesi ayrı namespace, source revalidation, manifest ve privacy acceptance ile uygulanır.
- Bir symbol/path ancak production, test/fixture, CLI/web/runtime, schema/migration/restore, Backup/export/parser ve current canonical docs bağları sıfır; replacement executable; eski veri/backward-compatibility etkisi açıklanmışsa `Silme adayı` olabilir.
- Bilinmeyen consumer veya compatibility etkisi fail-closed biçimde `Legacy / arşivlenecek` sonucunu korur. Issue #165 incelemesinde bütün olası gruplar en az bir kapıya takıldığı için doğrulanmış silme adayı yoktur.
- Learning, podcast, numaralı docs ve tamamlanmış `.cse` kayıtları current product authority değildir; fakat provenance olabilir. Canonical/superseded/archive index ve referans grafiği olmadan toplu silinmez.
- Current kullanıcı dili owner-only Tek Hafıza, `private | project`, Backup, Hafızayı İndir, Proje Paketi ve Günlük Çıktı sözlüğünü kullanır. `multi-user`, “özel alan”, handover/devir paketi, `blocked`, hard-validation ve generic export dili current yüzeylerde büyütülmez; tarihsel metin doğru provenance etiketiyle korunabilir.
- Issue #165 production kodu, test, schema, migration, persistence, UI, route, CLI, backup/export formatı, ADR veya gerçek kullanıcı verisi değiştirmez; fiziksel silme/rename/move ayrı açık Issue ve rollback planı ister.

## Issue 148 - Backup, Hafızayı İndir ve Proje Paketi Kararları

- Backup, Hafızayı İndir, Proje Paketi ve Günlük Çıktı aynı ZIP teknolojisini kullanabilse de dört ayrı artifact ailesidir; bir artifact yalnız tek aileye aittir ve manifest rename ile aileler arası conversion yapılamaz.
- Backup yalnız eksiksiz felaket kurtarmadır: bütün `private` ve `project` source kayıtlar, append-only event geçmişleri, archive durumları ve yönetilen attachment'lar alınır. Tarih/proje/tür/scope filtresiyle kısmi Backup ve paylaşılabilir proje çıktısı iddiası yasaktır.
- Restore garantisi yalnız desteklenen `backup_format_version`/schema, başarılı exact manifest-entry-checksum, SQLite integrity/migration/count, attachment reconciliation ve repository doğrulamasından sonra; yalnız yeni hedefte geçerlidir.
- Hafızayı İndir bütün owner hafızasının insan ve makine tarafından okunabilir kişisel arşividir. İki scope, bütün desteklenen türler, source içerik, project/archive/status/revision, event geçmişi, attachment inventory ve doğrulanmış managed attachment byte'ları taşınır; Restore veya import garantisi yoktur.
- Proje Paketi tek seçilmiş proje için paylaşılabilir teslim/rapor artifact'ıdır. Dahil edilen her kayıt source'tan yeniden okunarak `scope=project`, aynı selected project, revision/fingerprint, bilinen status/archive, allowlist reference, attachment ve publication guard'larından geçer; kanıt eksikse fail-closed reddedilir.
- Terminal status archive değildir. Archive kayıtlar varsayılan Proje Paketi seçiminde dışarıda kalır; yalnız açık `include_archived=true` politikasıyla “Tarihsel Ek” inventory'sinde taşınabilir.
- Project ID scope yerine geçmez. Private, başka projeye ait veya bilinmeyen reference/attachment içeriği Proje Paketi'ne warning/redaction ile sokulmaz; gerekli ilişki güvenle çözülemiyorsa bütün package başarısız olur.
- Günlük Çıktı mevcut v1 observation/date/attachment-inventory hattında kalır. Daha geniş Proje Paketi'nin alt adı değildir; follow-up/routine private tracking byte-identical izolasyonu ve beş entry'li sözleşmesi değişmez.
- Dört bağımsız namespace `backup_format_version`, `memory_download_format_version`, `project_package_format_version`, `daily_export_format_version` olarak kabul edildi. Mevcut Günlük Çıktı v1'in tarihsel wire anahtarı `format_version` kalır; rename ayrı v2 implementation ister.
- Backup v1 ve Günlük Çıktı v1 strict manifest/entry alanları genişletilmez. Hafızayı İndir ve Proje Paketi ilk implementation'ları kendi namespace'lerinde v1 ile başlar ve açık family discriminator taşır.
- Payload checksum'ı uncompressed entry byte'ları üzerinde lowercase SHA-256 ve byte size'dır. Manifest kendisini checksum listesine almaz; duplicate, case-collision, unsafe, symlink, missing veya extra entry extraction/aktivasyon öncesi reddedilir.
- Deterministic paketleme mevcut Backup/Günlük sırasını korur; future Hafızayı İndir/Proje Paketi manifest-first ve canonical UTF-8 path sırası kullanır. Sabit source/clock/id ile byte-identical artifact test edilmelidir.
- Backup'ı Doğrula Restore güvenliğini; Hafızayı İndir verifier'ı kişisel arşiv bütünlüğünü; Proje Paketi preflight/verifier'ı source eligibility ve offline privacy tutarlılığını doğrular. Verifier'lar birbirinin artifact'ını kabul etmez, source/artifact repair veya mutation yapmaz.
- Bilinmeyen aile/version, eksik eligibility kanıtı veya manifest/file çelişkisi fail-closed reddedilir; fallback parser veya alan tahmini kullanılmaz.
- Mevcut şifresiz Backup v1 ve Günlük Çıktı v1 değişmez. Future encrypted format yönü Backup ve Hafızayı İndir için zorunlu; Proje Paketi ve Günlük Çıktı için teslim kanalına bağlı opsiyonel outer envelope'dur. Algorithm, KDF ve key recovery ayrı executable Issue ister.
- Kullanıcı dili `Backup`, `Backup'ı Doğrula`, `Restore`, `Hafızayı İndir`, `Proje Paketi`, `Günlük Çıktı`, `Manifest`, `Format Sürümü`, `Bütünlük Doğrulaması` olarak sabitlendi; “Devir paketi”, “handover backup” ve “tam proje yedeği” yeni ürün dili değildir.
- Issue #148 production kodu, test, schema, migration, persistence, UI, route, CLI, wire format, encryption veya gerçek kullanıcı verisi uygulamaz.

## Issue 147 - MemoryIndex / RecordRef Read-Model Kararları

- `MemoryIndex`, ayrı observation/follow-up/routine occurrence domain kaynaklarından üretilen, source of truth olmayan ve tamamen yeniden kurulabilen ortak Hafıza read-model'idir. `RecordRef` source mutation veya otomatik repair yapamaz.
- Kanonik ref anahtarı `(record_type, source_id)` çiftidir. Tek alan isteyen consumer için kararlı token `cse-record-ref/v1/{record_type}/{source_id}` biçiminde deterministik türetilir; random surrogate kimlik kullanılmaz.
- İlk `record_type` allowlist'i `observation`, `follow_up`, `routine_occurrence` değerleridir. Yeni tür ancak source, mapping, scope, status, search, deep-link, rebuild, privacy ve test sözleşmesiyle eklenebilir.
- Ortak status `open | waiting | completed | cancelled` sözlüğüne normalize edilir; kaynak status/outcome ayrıntısı zorunlu `status_detail` alanında kayıpsız kalır. Terminal kayıt index'ten çıkarılmaz ve archive ile karıştırılmaz.
- `RecordRef`; Issue'daki minimum alanlara ek olarak `record_ref_id`, `status_detail`, `detail_path` ve dependency drift'ini de kapsayan `source_fingerprint` taşır. Mapping değişikliği `projection_version` artışı ve rebuild ister.
- Observation `occurred_at=observed_at`; follow-up `occurred_at=created_at`; routine occurrence `occurred_at=scheduled_at_utc` kullanır. Timeline eşitlik sırası sabit record type order ve source ID ile çözülür.
- Scope kaynağı ADR-0001'dir; project bağlantısından inference yapılmaz. Scope source alanı uygulanana kadar observation `project`, follow-up ve occurrence `private` compatibility mapping'i kullanılır. Sonraki source scope geçişi version bump/rebuild ister.
- Normal source mutation, append-only event ve idempotent ref upsert aynı transaction'da commit edilir. Explicit rebuild source ID'ye göre deterministic tarama, shadow generation, validation ve atomik aktivasyon kullanır; partial generation görünür olmaz.
- Drift missing/orphan/duplicate/stale revision/fingerprint/projection version/alan/privacy sınıflarında read-only diagnostic olarak görünür; source kaydı otomatik değiştirmez. Maintenance durumu `ready | stale | rebuilding | failed` olur.
- Hafıza, literal arama, timeline, dashboard, haftalık özet, Hafızayı İndir inventory ve diagnostic read-model'i okuyabilir. Mutation source application service'e gider; resmî/proje çıktısı source scope/project/archive/attachment/publication sınırlarını yeniden ve fail-closed doğrular.
- Production kodu, test, schema, migration, persistence, UI ve çıktı formatları bu ADR'de uygulanmadı.

## Issue 145 - Tek Hafıza ve Kayıt Kapsamı Kararları

- Kullanıcı ana navigasyonda ayrı kişisel/resmî uygulama dünyaları görmez; bütün kayıt türleri tek **Hafıza** arama ve timeline deneyiminde bulunabilir. Kaynak domain tabloları ve yaşam döngüleri tek tabloya birleştirilmez.
- Kayıt türü ile `private | project` kapsamı ayrı kavramlardır. Kapsam erişim rolü, tenant, status veya encryption garantisi değil, resmî/proje çıktısına seçilebilme sınırıdır.
- Proje bağlantısı kapsam değildir. Projesiz veya projeye bağlı private kayıt geçerlidir; project atama, observation link'i, AI, routine işlemi veya read-model rebuild sessiz kapsam dönüşümü yapamaz.
- Gelecekteki backfill'de bütün observation kayıtları `project`; bütün follow-up, routine template ve routine occurrence kayıtları `private` olur. Observation'a bağlı veya `converted_to_observation` sonuçlu eski follow-up da private kalır; hedef observation ayrı project kaydıdır.
- `private -> project` açık kullanıcı onayı, zorunlu project bağlantısı, optimistic revision ve aynı transaction'da append-only kapsam event'i gerektirir. Scope değişikliği kayıt türünü değiştirmez ve tek başına yayımlama sayılmaz.
- Observation, project document/plan/work package ve yayımlanmış çıktı snapshot'ları `project -> private` olamaz. Çalışma kayıtlarında geri dönüş yalnız daha önce çıktı/reference olmadığının kanıtı, açık uyarı/onay, revision ve event ile mümkündür; kanıt yoksa fail-closed reddedilir.
- Backup bütün private/project hafızayı felaket kurtarma için taşır. Hafızayı İndir iki kapsamı da açık etiketlerle içeren kişisel arşivdir. Proje Paketi, günlük ve rapor yalnız seçilen project bağlantısına sahip project kapsamlı kayıtları alır; private kayıt önce ayrı kapsam dönüşümü olmadan doğrudan seçilemez.
- Mevcut schema, migration, observation/follow-up/routine davranışı, backup format `1` ve daily export format `1` değiştirilmedi. `MemoryIndex`, kapsam alanı, migration, UI ve çıktı formatları ayrı Issue'lara bırakıldı.

## Issue 112 - Follow-up Observation Link ve Conversion Kararları

- Link ve conversion yeni command sınıfı gerektirmez; iki public service method'u mevcut canonical follow-up ID, observation ID ve expected revision değerlerini alır.
- Follow-up ve observation aynı `SQLiteUnitOfWork` içinde okunur. Stale revision, no-op/transition kararından ve observation lookup'tan önce kontrol edilir.
- Observation'ın `project_id` değeri source of truth'tur. Null follow-up project aynı mutation içinde atanır; aynı project korunur; farklı project `InvalidRecordError` ile atomik reddedilir.
- Mevcut farklı observation sessizce replace edilmez. Aynı observation/project link'i gerçek no-op'tur ve clock, UUID, revision, `updated_at` veya event tüketmez.
- `link_observation`, açık veya terminal follow-up'ın status, outcome, attention, deadline ve ayrıntı alanlarını değiştirmez. Link kişisel kaydı otomatik resmî kayda dönüştürmez.
- `convert_to_observation`, yalnız açık inbox/active/waiting kayıt için açık kullanıcı işlemidir; status completed, outcome converted, outcome note/attention null ve completed timestamp clock değeri olur.
- Conversion var olan observation/project ilişkisini kullanır veya aynı mutation içinde kurar; tek converted event üretir ve ayrıca linked event yazmaz.
- Aynı observation/project ile exact converted retry stale kontrolünden sonra no-op olabilir. Başka completed outcome veya cancelled kayıt conversion ile yeniden yazılamaz.
- Aggregate update, son history sequence + 1 event insert'i ve commit aynı mevcut `BEGIN IMMEDIATE` transaction'ında kalır; UUID validation, event insert veya commit hatası tam rollback üretir.
- Otomatik observation oluşturma/kopyalama, observation application service, schema/migration/mapping/repository/UoW, routine/backfill, web/UI, requirements ve backup/export bu görevde kapsam dışıdır.

## Issue 111 - Follow-up Bekleme ve Terminal Yaşam Döngüsü Kararları

- `MarkWaiting` ve `CompleteFollowUp`, mevcut application command yaklaşımını izleyen `frozen=True, slots=True` değerleridir; `app.application` public API'sinden export edilir.
- Waiting komutu canonical UTC `next_attention_at` ister. `related_person` ve `condition_text` trim edilir; boş sonuç `None` olur ve ikisinin birlikte boş kalması izinlidir.
- Zaten waiting olan kayıtta dikkat anı, ilgili kişi ve koşulun üçü aynıysa gerçek no-op kabul edilir. Stale revision bu karardan önce kontrol edilir; alanlardan biri farklıysa ikinci `waiting_started` event'i yerine `InvalidRecordError` üretilir.
- Complete yalnız `completed/not_required` outcome kabul eder. `converted_to_observation` ayrı açık dönüşüm use-case'ine, `cancelled` ise `cancel(...)` method'una ait kalır.
- Complete ve cancel yalnız `inbox/active/waiting` kaynak durumlarında çalışır; etkin dikkat anını temizler, deadline'ı korur ve sırasıyla `completed_at` veya `cancelled_at` değerini enjekte edilen clock'tan alır.
- Reopen yalnız `completed/cancelled` durumundan çalışır; outcome/timestamp alanlarını temizler. Nullable attention `inbox + NULL`, timestamp ise `active + timestamp` üretir; önceki outcome append-only reopened event'inde korunur.
- Bütün transition'lar aggregate/revision'ı mevcut Unit of Work içinde okur; gerçek update, son history sequence + 1 event insert'i ve commit aynı `BEGIN IMMEDIATE` transaction'ında gerçekleşir. Repository/UoW API'si genişletilmez.
- UUID validation, event insert veya commit hatası transaction'ı rollback eder. No-op clock/UUID tüketmez; açık hata türleri generic application hatasına çevrilmez.
- Observation link/convert, routine/backfill, schema/migration/mapping/repository/UoW, web/UI, requirements ve backup/export davranışları bu görevde kapsam dışıdır.

## Issue 109 - FollowUpApplicationService Çekirdek Kararları

- Application command/query sınıfları transport veya UI modeli değil, `frozen=True, slots=True` application değerleridir; service public API'si `app/application/__init__.py` üzerinden açıkça export edilir.
- Hızlı create'in tek kullanıcı içeriği `capture_text` olarak kalır; kimlik ve zaman service'in enjekte edilebilir UUID/clock bağımlılıklarıdır. Varsayılanlar canonical lowercase UUID ve canonical UTC `Z` üretir.
- Update command boundary'sinde title whitespace'i tek boşluğa indirilir; optional text alanları trim edilir ve boş sonuç `None` olur. No-op karşılaştırması bu normalize edilmiş değerlerle yapılır.
- Read/query işlemleri her zaman repository `list_all()` deterministic sırasını temel alır; status, project, personal, observation ve view filtreleri service-side uygulanarak portlara yeni sorgu API'si eklenmez.
- `overdue/today/upcoming` mevcut `classify_follow_up(...)`, `now` mevcut `select_now_attention_items(...)` ile hesaplanır. `as_of_utc` canonical UTC olarak doğrulanır ve yerel gün `ZoneInfo("Europe/Istanbul")` ile belirlenir.
- Her mutation önce aggregate'i okur ve stale revision'ı no-op kararından önce reddeder. Gerçek no-op clock/UUID tüketmez; revision, `updated_at` ve event geçmişi değişmez.
- Gerçek mutation'da immutable domain kaydının yeni revision'ı `dataclasses.replace(...)` ile üretilir; repository update, history okuma, event append ve commit aynı `SQLiteUnitOfWork` içindedir.
- Event sequence repository'ye allocator eklenmeden, aynı `BEGIN IMMEDIATE` transaction'da `list_for_follow_up(...)` sonucunun son sequence değerinden bir artırılarak hesaplanır.
- Terminal planlama/inbox transition ve observation bağlı project değiştirme `InvalidRecordError`; missing project `RecordNotFound`; stale write `RevisionConflict` olarak açık hata türleriyle korunur ve generic hatada yutulmaz.
- Bu görev terminal complete/cancel/reopen, observation link/convert, routine/backfill, UI, schema/migration, backup/export veya gerçek kullanıcı data root'u davranışını genişletmez.

## Issue 107 - Follow-up Event Vocabulary ve SQLite v4 Kararları

- Event adları mevcut anlamları yeniden kullanmak yerine gelecekteki mutation'larla birebir eşleştirilir: `update_details -> follow_up.details_updated`, `move_to_inbox -> follow_up.moved_to_inbox`, `set_project -> follow_up.project_changed`.
- Mevcut dokuz `FollowUpEventType` değeri ve sırası değiştirilmez; üç yeni değer enum'un sonuna eklenir. `FOLLOW_UP_EVENT_TYPES` enum'dan türemeye devam eder.
- Ayrıntı event payload'ı mutation sonrası `revision` ve alfabetik sıralı benzersiz `changed_fields` taşır; immutable ilk yakalama kanıtı `capture_text` değiştirilemez ve listede bulunamaz.
- Inbox event payload'ı `revision`, `from_status`, `previous_next_attention_at`; project event payload'ı `revision`, `from_project_id`, `project_id` taşır. Nullable proje değerleri JSON `null` olarak korunur.
- SQLite `CHECK` constraint doğrudan genişletilmediği için schema v4 yalnız `follow_up_events` tablosunu replacement/copy/drop/rename akışıyla yeniden kurar. Bütün adımlar migration runner'ın tek `BEGIN IMMEDIATE` transaction'ındadır.
- v1/v2/v3 migration statement içerikleri immutable geçmiş kabul edilir. V4, kolon/nullability/PK/FK/sequence/actor/payload/unique/no-cascade sözleşmesini aynen korur ve yalnız event allowed list'ine üç değer ekler.
- Existing `payload_json` migration sırasında parse veya serialize edilmez; `INSERT ... SELECT` ile metin değeri aynen taşınır. Diğer tabloların schema veya satırları değiştirilmez.
- Genel domain-SQLite event mapper ve append-only repository yeni enum değerlerini zaten taşıdığı için mapping/repository kodu değiştirilmez. Event API'si yalnız add/list ve `ORDER BY sequence` olarak kalır.
- Issue #107 application service, command/query dataclass, sequence allocator, backfill, UI/web route, notification, backup formatı veya resmî daily export uygulamaz.

## Issue 103 - Kanonik Ürün Yönü ve Repository Truth Kararları

- Issue #103'ün nihai düzeltmesi ve bağlayıcı üst yol haritası Epic #105'tir; ilk branch commit'indeki çelişen geniş kullanıcı, kurumsal gelecek ve geç mobil öncelik kararları tarihsel kalır.
- CSE, yalnız şantiye şefi tarafından kullanılan; not, takip, hatırlatıcı, hesap, fotoğraf, belge, günlük, arama ve proje hafızasını birleştiren local-first ve mobile-first kişisel saha asistanıdır.
- Ürün araç bakımından geniş, kullanıcı modeli bakımından tek sahipli kalır. Şirket, taşeron, işveren, yapı denetim ve diğer kişiler sistem kullanıcısı değil kişi/kurum veya ilgili taraf kayıt referansıdır.
- Multi-user hesap, role/tenant, firma portalı, takım collaboration, kurumsal workflow, şirket portföy dashboard'u, SaaS/billing ve çok taraflı cloud collaboration aktif veya uzun vadeli ürün hedefi değildir.
- Tek kullanıcı güvenliği kaldırmaz: uygulama kilidi/cihaz biyometrisi, güvenilen cihaz, şifreli backup, owner-only telefon-PC senkronizasyonu, güvenli yerel ağ ve açık export/devir single-owner security sınırıdır.
- Kişisel/resmî ayrımı erişim rolü değil export/devir kapsamıdır. Projeye bağlanan kişisel takip otomatik resmî olmaz; dönüşüm açık şantiye şefi işlemidir.
- `local-first`, `Windows-first` değildir. Mobil runtime, offline, notification ve owner-only sync ilk gerçek saha pilotlarından önce ele alınır.
- Local Field MVP korunur; Saha Takibi domain/recurrence ile schema v3 persistence tamamlanmıştır. Transactional application service ve lazy backfill sıradaki dar production adımıdır.
- Ürün sırası: Issue #103 yön düzeltmesi -> application service/backfill -> backup/export izolasyonu -> mobil runtime/veri ADR -> Kâğıdı Bırakma Sürümü -> offline/bildirim -> 7 günlük pilot -> 30 günlük pilot -> gelişmiş hesap -> günlük yayın zinciri -> Harita -> kanıtlanmış yardımcılar -> kişisel AI.
- Kâğıdı Bırakma Sürümü takip/rutin/attachment/arama/backup görünürlüğüne ek olarak minimum hızlı hesap şeridi ve günlük zaman çizelgesi/düzenlenebilir taslak taşır.
- Gelişmiş hesap defteri 30 günlük pilot sonrasında, immutable günlük yayınlama/revizyon zinciri ayrı sonraki fazda kalır.
- Canlı Proje Haritası source record değil read-model/projeksiyondur; dokunarak odaklanır, wheel/pinch/trackpad zoom/pan/serbest zoom içermez ve hesaplanmış balon yerine kaynak kayıt düzenlenir.
- Legacy model envanteri `Aktif çekirdek`, `Dönüştürülecek`, `Legacy/arşivlenecek`, `Silme adayı` sözlüğüyle ayrı görevdir; bu karar fiziksel silme yetkisi vermez.
- Kalıcı ürün amacı `CSE_UNIFIED_PROJECT_SOURCE.md`, operasyon/Git güvenliği `CSE_PROJECT_INSTRUCTIONS.md`, aktif kapsam current GitHub Issue, değişken repository durumu GitHub `master`/PR/Issue/branch kanıtıdır.
- `.cse/state`, README, ROADMAP, handoff, ZIP, öğrenme ve podcast çıktıları current GitHub truth'u override edemez; öğrenme/podcast production zincirini bloke etmez.
- Yeni branch standardı `codex/issue-<issue_no>-<slug>` olur. Eski `step-NNN-*` branch'ler yeniden adlandırılmaz; aynı anda yalnız bir aktif production implementation görevi ve en fazla bir incelemede PR bulunur.

## Issue 102 - Saha Takibi SQLite v3 ve Repository Kararları

- Schema v3, v1/v2 migration metinleri değiştirilmeden zincirin sonuna eklenen tek immutable migration'dır; gerçek kullanıcı data root'u bu görevde migrate edilmez.
- Observation bağlı follow-up için `field_observations(id, project_id)` composite unique parent key ve `follow_up_items(observation_id, project_id)` composite foreign key kullanılır; `ON DELETE CASCADE` kullanılmaz.
- SQLite `CHECK` kuralları enum/boolean/revision, planlı follow-up dikkat zamanı ve terminal alan birlikteliklerini korur; geçiş izni, cross-record lookup ve event payload içeriği sonraki application service sınırında kalır.
- Domain nesneleri ile SQLite satırları ayrı, açık mapper fonksiyonlarıyla dönüştürülür; SQLite'tan okunan kayıt domain constructor'ından geçirilerek bozuk kalıcı satır fail-closed reddedilir.
- Ana repository'ler add/get/deterministic query ve `expected_revision` isteyen update yüzeyi taşır. Gerçek no-op revision artırmaz; `capture_text`, oluşturma anı ve occurrence schedule snapshot alanları repository mutation'ında değiştirilemez.
- Occurrence insert'i template + Europe/Istanbul yerel tarih unique anahtarını idempotency sınırı kabul eder; aynı anahtarla tekrar çağrı yeni satır üretmek yerine mevcut domain kaydını döndürür.
- Event repository'leri yalnız add ve aggregate-history list sunar; update/delete API'si yoktur ve sıralama yalnız aggregate `sequence` değeridir.
- Altı tracking repository'si mevcut `SQLiteUnitOfWork` connection/transaction'ını paylaşır; aggregate yazısı ile event append birlikte commit veya rollback olur.
- Application service, lazy occurrence orchestration, UI, scheduler, notification, backup/restore compatibility ve export bu görevde uygulanmaz.

## Issue 100 - Saha Takibi Domain ve Saf Recurrence Uygulaması

- Mevcut `app/models.py` çok büyük olduğu için Saha Takibi kayıtları ve saf hesapları küçük, bağımsız `app/field_tracking.py` modülünde tutulur; yeni katman veya framework eklenmez.
- Domain kayıtları `frozen=True, slots=True` dataclass olarak tanımlanır. UUID, UTC, enum, revision, status/outcome ve recurrence alan değişmezleri nesne oluşturma sınırında doğrulanır.
- Canonical UUID ve UTC için ikinci helper ailesi yazılmaz; mevcut `app.persistence.contracts` yardımcıları yeniden kullanılır. Event payload determinism'i mevcut JSON serializer üzerinden korunur.
- Hızlı create factory’sinde dışarıdan verilen iş içeriği yalnız `capture_text` değeridir; whitespace normalize edilir ve ilk title aynı değere eşitlenir. Kimlik ve UTC oluşturma anı dışarıdaki application sınırının teknik girdileridir.
- `RoutineTemplate.project_id` ve `FollowUpItem.project_id` nullable kalır. Domain, observation kimliği varsa project kimliğini zorunlu tutar; observation ile project’in gerçekten aynı aggregate’e ait olduğunun lookup kontrolü sonraki application/repository görevidir.
- Recurrence hesaplayıcısı sistem saatini, database’i veya filesystem’i okumaz. Template, yerel tarih, bugün ve pencere açık argümanlardır; sonuç eski tarihten bugüne deterministiktir.
- IANA `ZoneInfo("Europe/Istanbul")` zorunluluğunu Windows’ta da çalıştırmak için `tzdata` runtime bağımlılığı eklenir; sabit `+03:00` domain kuralı yazılmaz.
- Saf occurrence planı kimlik veya event UUID üretmez. Uygun geçmiş gün `closed/missed`, bugün `open` olarak planlanır; kalıcı insert, iki aşamalı revision/event akışı sonraki transactional service görevidir.
- Inactive template bütün tarihleri koşulsuz dışlamaz: canonical UTC `deactivated_at`, `Europe/Istanbul` yerel tarihine çevrilir; yalnız recurrence ile start/end kurallarına uyan ve `local_date < deactivation_local_date` olan eksik geçmiş günler sınırlı backfill için eşleşir. Pasifleştirme yerel günü ve sonrası eşleşmez; active template davranışı değişmez.
- `now` enum/status eklenmez. “Şimdi ilgilen”, overdue + zamanı gelmiş today + önemli inbox kayıtlarını giriş sırasını koruyarak ve kimliğe göre tekilleştirerek seçen saf query composition’dır.
- Bu görev schema version, migration, repository, Unit of Work, application service, web UI, scheduler, notification, backup/restore veya export davranışı değiştirmez.

## Issue 98 - Saha Takibi v0.1 Domain ve Veri Sözleşmesi

- Saha Takibi v0.1, mevcut gözlem/attachment/export omurgasından sonraki birinci ürün önceliğidir; bu görev sözleşme ve dokümantasyon aşamasıdır, production model/schema/UI eklemez.
- Tek seferlik işler `FollowUpItem`, tekrar kuralı `RoutineTemplate`, belirli yerel günün bağımsız sonucu `RoutineOccurrence` olarak ayrılır.
- Hızlı `+ Unutma` create command’ında yalnız `capture_text` zorunludur; whitespace normalize edilir, ilk `title` AI kullanılmadan aynı değere eşitlenir ve kullanıcı title’ı daha sonra revision kontrollü mutation ile düzenleyebilir.
- `FollowUpItem.project_id` ve `RoutineTemplate.project_id` nullable’dır; projesiz kayıt kişisel çalışma alanında kalır ve sonradan projeye bağlanabilir.
- Follow-up observation’a bağlanırsa projesiz kayıt aynı transaction’da observation projesini alır; farklı mevcut proje reddedilir. SQLite `CHECK` ve composite observation/project foreign key repository bypass durumunu da engeller.
- Bütün yeni ana/event kimlikleri canonical UUID; kalıcı anlar canonical UTC `Z`; recurrence takvimi `Europe/Istanbul` yerel tarihidir.
- Follow-up status allowed list’i `inbox`, `active`, `waiting`, `completed`, `cancelled`; occurrence status’u `open`, `closed` olarak kalır.
- Açık ve zamanlanmamış follow-up yalnız `inbox` olabilir; `active` veya `waiting` mutlaka `next_attention_at` taşır. Database minimum invariant’ı `CHECK` ile, application service create/planlama transition’ını daha güçlü validation ile korur.
- Unutma Kutusu ayrı `inbox` sorgusudur. `overdue`, `today`, `upcoming` yalnız planlı `active/waiting` kayıtlar için türetilir; `now` temel domain kategorisi değildir.
- “Şimdi ilgilen” bir UI query bileşimidir: overdue + zamanı gelmiş today + önemli inbox; bu bileşim kalıcı status veya yeni domain kategorisi oluşturmaz.
- Recurrence türleri `daily`, `weekdays`, `weekly`, `monthly`; ilk `weekdays` tanımı Pazartesi–Cuma’dır ve resmî tatil otomasyonu içermez.
- Aynı template ve yerel tarih için tek occurrence, database `UNIQUE(routine_template_id, occurrence_local_date)` constraint’iyle korunur; conflict idempotent no-op’tur.
- Otomatik lazy backfill bugün dahil son yedi Europe/Istanbul yerel takvim günüyle sınırlıdır; geçmiş uygun gün yeni oluşursa `missed`, bugünün occurrence’ı `open` olur; sınırsız geçmiş üretimi yapılmaz.
- Template güncellemesi yalnız henüz üretilmemiş occurrence’ları etkiler; pasifleştirme ve occurrence sonucu geçmiş satırları değiştirmez; erteleme yalnız mevcut occurrence’ın `next_attention_at` değerini değiştirir.
- Üç event ailesi aggregate içi artan `sequence` ile deterministic ve append-only tutulur; ana mutation ile event append tek Unit of Work transaction’ında atomiktir.
- Üç ana kayıtta optimistic revision uygulanır; stale write ana kayıt/event değiştirmeden reddedilir, gerçek değişiklik olmayan çağrı revision veya event artırmaz.
- İlk implementation migration’ı mevcut schema version `2`den `3`e çıkarır; mevcut project/observation/attachment/event tablolarını değiştirmeden yedi yeni tracking tablosu ekler ve hata halinde tam rollback yapar.
- Yeni tracking tabloları mevcut SQLite snapshot backup’a otomatik girer; backup format version `1` korunur ve v0.1’de tracking count manifest alanı eklenmez.
- Schema version `2` eski backup, yalnız var olmayan yeni hedefe çıkarıldıktan sonra geçici restore kökünde schema `3`e migrate edilir; aktif/var olan data root üzerine restore reddi korunur.
- Kişisel follow-up/routine/occurrence/event verisi mevcut günlük resmî export’a varsayılan olarak girmez; export formatı, entry’leri, observation count anlamı ve manifesti değişmez.
- Ayrıntılı sözleşme `docs/field_tracking_v0_1_contract.md`; öğretici açıklama `learning/issue_098_saha_takibi_domain_ve_veri_sozlesmesi.md` içindedir.
- Sonraki işler domain/recurrence, schema/repository, transactional service, backup compatibility, export exclusion ve ancak sonrasında minimum UI olarak ayrı küçük görevlere bölünür.

## 225 Podcast 035 Note-Contained Summary Contract Karari

- Podcast 035, Steps 221-225 icin mandatory 12-section note olarak olusturulur ve Section 6 icinde Steps 001-220 tarihini kendi basina tasir.
- Strict Podcast 035+ validator yalniz required section presence kontroluyle yetinmez; previous-summary section'in gercek Markdown sinirini bulur.
- Expected prior headings `001..note.step_start-1` exactly once ve ascending order zorunludur; missing, duplicate, out-of-order ve section-disindaki headings clear error verir.
- Current-range steps previous-summary section icinde zorunlu degildir; Podcast 034 ve onceki notes legacy contract ile okunmaya devam eder.
- Note-contained summaries, rolling source cumulative summaries'nin yerine gecmez; iki katman da self-contained source ve canonical current-state amaciyla korunur.
- Rolling source latest Podcast 035 / range `221-225`; safe point Step 224 ve cumulative summary count `224` olarak yenilenir.
- Step 224, PR #66 squash merge commit `68c00edab667bbfd0467f4684921c0f6b453d4a7` ile latest merged/finalized safe point'tir; Issue #64 completed olarak kaydedilir.
- Step 225, Issue #67 ve `step-225-podcast-035-note-summary-contract` branch'i uzerinde active unmerged podcast/validator/test/documentation isidir.
- Focused `24 passed` ve full `503 passed` test kaniti urun field-ready iddiasi degildir.
- Main product code, workflow, NotebookLM automation, historical note mutation, ZIP/exports mutation ve Step 226 uygulanmamistir.

## 224 Rolling NotebookLM Podcast Source Protokolu Karari

- NotebookLM'e her podcastte yeniden source ve instruction eklemek yerine `docs/notebooklm/CSE_PODCAST_LATEST_SOURCE.md` tek stable website source olarak kullanilir.
- Permanent yorumlama sozlesmesi `docs/notebooklm/NOTEBOOKLM_INSTRUCTIONS.md` icinde tutulur ve rolling source'un en ustune tam olarak eklenir.
- Generator latest numbered podcast notunu secerek full content, 001-current-safe-step ayri ozetleri, safe point/test kaniti, deferred scope ve deterministic metadata ile birlestirir.
- `CHANGELOG.md` Step 001-223 summary inventory icin canonical makine-okunur kaynak, `ROADMAP.md` mevcut yeni adimlarin kisa baslik kaynagi ve `.cse/state/project_state.json` current safe point kaynagidir.
- Podcast 034 legacy note formatinda oldugu icin legacy required sections ile kabul edilir; Podcast 035 ve sonrasinda Issue #64'teki 12 bolumlu yeni note contract zorunludur.
- Stable public URL `https://raw.githubusercontent.com/faliardic/chief-site-engineer/master/docs/notebooklm/CSE_PODCAST_LATEST_SOURCE.md` olarak tanimlanir. NotebookLM saved website source auto-refresh davranisi dogrulanmamistir.
- Her Codex instruction model, reasoning level ve secim nedenini acikca yazar; contract/regression-sensitive islerde selector'daki en guclu full Codex model ve `extra high` reasoning kullanilir.
- Step 223, PR #65 squash merge commit `932dbf3ffd076ddc124825adce78226d2ce8fb57` ile latest merged/finalized safe point'tir; Issue #63 completed olarak kaydedilir.
- Step 224, Issue #64 ve `step-224-notebooklm-rolling-podcast-source` branch'i uzerinde aktif unmerged generator/test/documentation isidir.
- Step 224 local verification sonucu focused `15 passed` ve full suite `494 passed` olarak kaydedilir; bu urunun field-ready oldugu anlamina gelmez.
- Podcast 035, NotebookLM API/browser/upload/audio automation, ana urun UI/API/CLI, workflow, ZIP, Desktop archive, historical podcast ve exports mutation uygulanmamistir.

## 223 Field Observation Attachment Convenience Lookup Karari

- `FileAttachmentRepository.list_for_field_observation(observation_id)` helper'i eklendi.
- Helper yalniz `list_by_related_record("field_observation", observation_id)` cagrisi ile delegation yapar; ikinci bir `_records` filtering implementation'i eklenmez.
- `"field_observation"` literal degeri Step 219 contract ile ayni tutulur.
- Exact, case-sensitive, non-normalizing, validation-free, insertion-order preserving, new-list, same-object ve metadata non-mutation davranislari existing combined helper uzerinden korunur.
- Helper `FieldObservationRepository` sorgulamaz, referenced observation existence validation yapmaz, `FieldObservationRecord` veya attachment metadata mutate etmez.
- Focused tests delegation, exact match, partial match rejection, case/whitespace sensitivity, empty/unknown results, new-list behavior, same-object returns, non-mutation, count/order stability, missing existence non-validation, combined helper equivalence ve existing filter regression davranislarini kapsar.
- Step 222, PR #62 squash merge commit `8ba82cf2109df9d8cd385a5c38ee58a637afba9c` ile latest merged/finalized safe point'tir; Issue #61 completed olarak kaydedilir.
- Step 223, Issue #63 ve `step-223-field-observation-attachment-convenience-lookup` branch'i uzerinde aktif unmerged implementation/test/documentation isidir.
- Model fields, constants/enums, hard validation, `FieldObservationRepository` methods, automatic attachment creation/linking, physical file operations, persistence, API/GUI/CLI, export/report consumers, audit/history/task/NCR/decision generation, generated `blocked`, Podcast 035 ve Step 224 uygulanmamistir.

## 222 Field Observation Attachment Convenience Lookup Boundary Karari

- Future `FileAttachmentRepository.list_for_field_observation(observation_id)` helper'i documentation-only olarak planlandi; bu adim helper'i implement etmez.
- Future helper davranisi `list_by_related_record("field_observation", observation_id)` ile semantic equivalent olacak sekilde tanimlandi.
- Future implementation icin filtering logic'i kopyalamak yerine existing combined helper'a delegation tercih edilir.
- Helper exact, case-sensitive ve non-normalizing davranisi korumalidir; trim, parse, map, alias, prefix inference veya validation yapmamalidir.
- Helper `FieldObservationRepository` sorgulamamali, referenced observation existence validation yapmamali, attachment metadata veya `FieldObservationRecord` mutate etmemelidir.
- Future test matrix; exact match, partial match rejection, case/whitespace sensitivity, empty/unknown results, new-list behavior, same-object returns, non-mutation, count/order stability, missing existence non-validation, combined helper equivalence ve existing filter regression basliklarini kapsar.
- Step 221, PR #60 squash merge commit `7c326740ef968e7fda3094eaf04f8dec8ecbf333` ile latest merged/finalized safe point'tir; Issue #59 completed olarak kaydedilir.
- Step 222, Issue #61 ve `step-222-field-observation-attachment-convenience-lookup-boundary` branch'i uzerinde aktif unmerged documentation/state/learning-only isidir.
- Production code, executable tests, repository methods, model fields/behavior, constants/enums/validation, automatic attachment creation/linking, physical file operations, persistence, API/GUI/CLI, export/report consumers, audit/history/task/NCR/decision generation, generated `blocked`, Podcast 035 ve Step 223 uygulanmamistir.

## 221 Podcast 034 Steps 216-220 Karari

- Podcast 034, Steps 216-220 araligi icin documentation/state/podcast-only artifact olarak olusturuldu.
- Podcast 034; Podcast 033 kapanisi, `FileAttachmentRepository` baseline, independent related-record filtreleri, Field Observation attachment linking contract ve exact combined related-record lookup hattini kapsar.
- Bu adim production code, executable test, repository behavior, model behavior veya workflow degisikligi eklemez.
- Step 220, PR #58 squash merge commit `1623e32437e1555ab398b245c4984566c163825f` ile latest merged/finalized safe point'tir; Issue #57 completed olarak kaydedilir.
- Step 221, Issue #59 ve `step-221-podcast-034-steps-216-220` branch'i uzerinde aktif unmerged documentation/state/podcast-only isidir.
- Podcast 034 branch uzerinde fiziksel olarak olusturuldu; Step 221 merge/finalize edilene kadar Step 221 guvenli nokta veya merge claim olarak yazilmaz.
- FieldObservation-specific convenience lookup, automatic attachment creation/linking, referenced observation existence validation, physical file operations, persistence, API/GUI/CLI, export/report consumers, audit/history/task/NCR/decision generation, generated `blocked`, Podcast 035 ve Step 222 uygulanmamistir.

## 220 FileAttachmentRepository Combined Related-Record Filter Karari

- `FileAttachmentRepository.list_by_related_record(related_record_type, related_record_id)` exact combined filtre olarak eklendi.
- Method yalniz mevcut bellek ici `_records` listesini okur.
- Bir `FileAttachmentRecord`, yalniz ayni record uzerinde `record.related_record_type == related_record_type` ve `record.related_record_id == related_record_id` exact match oldugunda sonuc listesine girer.
- Karsilastirmalar case-sensitive calisir; trim, normalize, parse, map, alias, prefix inference, validation veya fallback yapilmaz.
- Empty repository, unknown pair ve partial match durumlari icin `[]` dondurulur.
- Sonuclar insertion order'i korur ve her cagri yeni liste dondurur.
- Donen elemanlar ayni stored `FileAttachmentRecord` nesneleridir; metadata alanlari kopyalanmaz veya mutate edilmez.
- Related record'un gercekten var olup olmadigi repository tarafindan kontrol edilmez.
- Step 218 independent `list_by_related_record_type(...)` ve `list_by_related_record_id(...)` filtreleri degismeden kalir.
- Step 219 Field Observation attachment linking contract implemented/documented truth olarak korunur; `list_for_field_observation(...)` convenience helper eklenmez.
- Step 219, PR #56 squash merge commit `4d006a2f49f10792a74dca068ea415ba37200797` ile latest merged/finalized safe point'tir; Issue #54 completed olarak kaydedilir.
- Podcast 033 latest completed podcast olarak Steps 211-215 araligini kapsar; Step 220 merge edildikten sonra Podcast 034 icin dogal aralik Steps 216-220 olur.
- Step 220, Issue #57 ve `step-220-file-attachment-combined-related-record-filter` branch'i uzerinde aktif unmerged combined related-record filter isidir.
- Record-type-specific convenience lookup, relationship existence validation, physical file operations, persistence, lifecycle behavior, model fields, validation/enums/constants, API/GUI/CLI, audit/history/task/NCR/decision generation, generated `blocked`, Step 221 ve Podcast 034 uygulanmamistir.

## 219 Field Observation Attachment Linking Contract Karari

- Field Observation attachment relationship, yalniz ayni `FileAttachmentRecord` uzerinde `related_record_type == "field_observation"` ve `related_record_id == FieldObservationRecord.observation_id` exact match oldugunda kurulmus sayilir.
- Iki karsilastirma da case-sensitive string equality ile yapilir; trim, normalize, parse, map, alias veya prefix inference uygulanmaz.
- `"field_observation"` literal degeri, bu contract icin Field MVP attachment relationship type degeridir; global enum, constant set, model validation veya migration eklenmez.
- Bir `FieldObservationRecord` sifir, bir veya cok attachment metadata kaydina sahip olabilir; attachment relationship alanlarinin sahibi `FileAttachmentRecord` olarak kalir.
- `FieldObservationRecord` icine attachment id listesi, reverse collection veya embedded attachment data eklenmez.
- `attachment_id`, attachment repository identity alani olarak kalir ve mevcut duplicate rejection kurallari korunur.
- Model ve repository katmani referenced observation var mi diye kontrol etmez; missing observation reference gorunur metadata durumudur, otomatik red veya onarim sebebi degildir.
- Step 218 bagimsiz `list_by_related_record_type(...)` ve `list_by_related_record_id(...)` filtreleri implemented kalir; bunlar tek basina guvenli combined relationship query olarak sunulmaz.
- Future `list_by_related_record(related_record_type, related_record_id)` helper'i, ileride uygulanirsa iki exact kosulu ayni metadata record uzerinde birlikte aramalidir.
- Future `list_for_field_observation(observation_id)` helper'i, ileride uygulanirsa `("field_observation", observation_id)` exact pair davranisina denk olmalidir.
- Step 218, PR #53 squash merge commit `62b95867165f5ff6b3aec85fc841557bc678df42` ile latest merged/finalized safe point'tir; Issue #52 completed olarak kaydedilir.
- Podcast 033 latest completed podcast olarak Steps 211-215 araligini kapsar; sonraki besli podcast araligi Steps 216-220 olur.
- Step 219, Issue #54 ve `step-219-field-observation-attachment-linking-contract` branch'i uzerinde aktif unmerged documentation/state/learning contract isidir.
- Production code, executable tests, combined related-record filter, FieldObservation convenience lookup, physical file operations, persistence, lifecycle behavior, validation/enums/constants, API/GUI/CLI, audit/history/task/NCR/decision generation, generated `blocked`, Step 220 ve Podcast 034 uygulanmamistir.

## 218 FileAttachmentRepository Related-Record Filtre Karari

- `FileAttachmentRepository`, mevcut `FileAttachmentRecord` metadata nesnelerini `related_record_type` veya `related_record_id` alanina gore read-only listeleyebilir.
- `list_by_related_record_type(related_record_type)`, yalniz `record.related_record_type == related_record_type` exact match sonucunu dondurur.
- `list_by_related_record_id(related_record_id)`, yalniz `record.related_record_id == related_record_id` exact match sonucunu dondurur.
- Filtreler case-sensitive calisir; trim, normalize, parse, map, validation, enum veya fallback yapmaz.
- Eslesmeyen, bilinmeyen, case-different veya whitespace-different degerler icin `[]` dondurulur.
- Sonuclar repository ekleme sirasini korur.
- Her filtre cagrisi yeni bir liste dondurur; disarida donen liste mutate edilirse repository storage degismez.
- Record nesneleri kopyalanmaz ve metadata alanlari mutate edilmez.
- Type filtresi ve id filtresi birbirinden bagimsiz kalir; combined type+id query eklenmez.
- Bagli `FieldObservationRecord`, `NonconformityRecord` veya baska kayit varligi kontrol edilmez.
- Step 217, PR #51 squash merge commit `075acdbc77927925092b748b77aad7c0ce13d9ef` ile latest merged/finalized safe point'tir; Issue #50 completed olarak kaydedilir.
- Podcast 033 latest completed podcast olarak Steps 211-215 araligini kapsar; sonraki besli podcast araligi Steps 216-220 olur.
- Step 218, Issue #52 ve `step-218-file-attachment-related-record-filters` branch'i uzerinde aktif unmerged related-record filter isidir.
- FieldObservation-specific attachment lookup/linking, automatic attachment creation, physical file operations, filesystem checks, path generation/normalization, persistence, lifecycle behavior, validation/enums/constants, API/GUI/CLI, audit/history/task/NCR/decision generation, generated `blocked`, Step 219 ve Podcast 034 uygulanmamistir.

## 217 FileAttachmentRepository Baseline Karari

- `FileAttachmentRepository`, mevcut `FileAttachmentRecord` metadata nesnelerini bellek icinde saklayan minimal repository olarak eklendi.
- Repository method'lari yalniz `add`, `list_all`, `count` ve `find_by_id` olarak tutulur.
- Kimlik alani `attachment_id` olarak kullanilir; duplicate detection exact ve case-sensitive calisir.
- Duplicate exact `attachment_id` `ValueError` ile reddedilir ve repository contents degismez.
- `list_all()` her cagrida yeni liste dondurur; stored record nesneleri kopyalanmaz veya mutate edilmez.
- Step 216, PR #49 squash merge commit `43345c7e57ea9a786354d9ee8348f39aaf53af8f` ile latest merged/finalized safe point'tir; Issue #48 completed olarak kaydedilir.
- Podcast 033 latest completed podcast olarak Steps 211-215 araligini kapsar; sonraki besli podcast araligi Steps 216-220 olur.
- Step 217, Issue #50 ve `step-217-file-attachment-repository-baseline` branch'i uzerinde aktif unmerged attachment metadata repository baseline isidir.
- Related-record filters, FieldObservation-specific attachment lookup/linking, automatic attachment creation, physical file operations, filesystem checks, path generation/normalization, persistence, lifecycle behavior, validation/enums/constants, API/GUI/CLI, audit/history/task/NCR/decision generation, generated `blocked`, Step 218 ve Podcast 034 uygulanmamistir.

## 216 Podcast 033 Steps 211-215 Karari

- Podcast 033, `docs/podcast_notes/033_adim_211_215_notebooklm_podcast_notu.md` dosyasinda yalniz Steps 211-215 araligini kapsayan NotebookLM kaynak notu olarak hazirlanir.
- Step 216 documentation/state/podcast-only bir adimdir; product behavior, production code veya executable test eklemez.
- Podcast 033, Step 211 Podcast 032 kapanisini; Step 212 project/status filtrelerini; Step 213 explicit status update'i; Step 214 explicit reporting update'i; Step 215 location/category filtrelerini anlatir.
- Step 212-215 davranislari automatic, validated, normalized, persistent veya field-ready application behavior gibi sunulmaz.
- Step 215, PR #47 squash merge commit `7b3361087cdb51fe1e76caa6f2cd91ff005cdfe2` ile latest merged/finalized safe point'tir; Issue #46 completed olarak kaydedilir.
- Step 216, Issue #48 ve `step-216-podcast-033-steps-211-215` branch'i uzerinde aktif unmerged podcast/state isidir.
- Podcast 032, Step 216 merge edilene kadar latest completed podcast olarak Steps 206-210 araligini kapsar.
- Podcast 033, Step 216 merge edildikten sonra latest completed podcast olur; sonraki besli podcast araligi Steps 216-220 olur.
- Podcast 034, Step 217, persistence, attachment integration, export/reporting consumers, API/GUI/CLI, audit/history/task/NCR/decision generation, hard validation, generated `blocked`, workflow changes ve ZIP/Desktop archive mutation uygulanmamistir.

## 215 FieldObservationRepository Location ve Category Filter Karari

- `FieldObservationRepository`, `list_by_location(location)` ve `list_by_category(category)` read-only filtrelerini saglar.
- `list_by_location(location)`, yalniz `record.location == location` exact match sonucunu dondurur.
- `list_by_category(category)`, yalniz `record.category == category` exact match sonucunu dondurur.
- Filtreler case-sensitive calisir; trim, normalize, parse, map, tokenize, validation, enum veya fallback yapmaz.
- Eslesmeyen, bilinmeyen, case-different veya whitespace-different degerler icin `[]` dondurulur.
- Sonuclar repository ekleme sirasini korur.
- Her filtre cagrisi yeni bir liste dondurur; disarida donen liste mutate edilirse repository storage degismez.
- Record nesneleri kopyalanmaz ve mutate edilmez; mevcut in-memory repository sozlesmesi korunur.
- Archived matching record'lar filtre sonucundan dislanmaz; active/archive-only filtre bu adimin kapsami degildir.
- Location, category, project ve status filtreleri birbirinden bagimsiz kalir; combined query/filter object eklenmez.
- Step 214, PR #45 squash merge commit `768178a85844aae10c46008e28eafa23822fd631` ile latest merged/finalized safe point'tir; Issue #44 completed olarak kaydedilir.
- Step 215, Issue #46 ve `step-215-field-observation-location-category-filters` branch'i uzerinde aktif unmerged location/category filter isidir.
- Podcast 032 latest completed podcast olarak Steps 206-210 araligini kapsar; Podcast 033, Steps 211-215 icin yalniz Step 215 merge edildikten sonra ayri Step 216 ile olusturulmalidir.
- Structured location lookup, category constants/enums/vocabulary, normalization, validation, partial/fuzzy/text search, broader filters/mutations, persistence, attachment integration, API/GUI/CLI, audit/history/task/NCR/decision generation, generated `blocked`, daily export, weekly summary, Podcast 033 ve Step 216 uygulanmamistir.

## 214 FieldObservationRepository Reporting Update Karari

- `FieldObservationRepository`, `update_reporting(observation_id, reported_to, reported_at)` explicit reporting-context enrichment method'unu saglar.
- Method existing `find_by_id(...)` lookup davranisini kullanir.
- Missing `observation_id` icin `None` dondurur ve repository contents degismez.
- Found record icin yalniz `record.reported_to = reported_to` ve `record.reported_at = reported_at` assignment'lari yapilir; ayni stored record nesnesi dondurulur.
- `reported_to` ve `reported_at` trim, normalize, validate, map, parse veya convert edilmez.
- Contact lookup, contact ID, relationship resolution veya normalization eklenmez.
- Status otomatik `tracking` veya baska bir degere alinmaz.
- `closed_at`, notes, `created_by`, `is_archived` veya baska alan otomatik set/clear edilmez.
- Archived observation kayitlari explicit reporting update'ten engellenmez; archive gating bu adimin kapsami degildir.
- Step 213, PR #43 squash merge commit `45c2b2e2828dfea74121033bf01a868e6821b544` ile latest merged/finalized safe point'tir; Issue #42 completed olarak kaydedilir.
- Step 214, Issue #44 ve `step-214-field-observation-reporting-update` branch'i uzerinde aktif unmerged explicit reporting-update isidir.
- Podcast 032 latest completed podcast olarak Steps 206-210 araligini kapsar; sonraki besli podcast araligi Steps 211-215'tir.
- Automatic status change, current-time generation, contact normalization, other field updates, reporting history, audit/task/NCR/notification/decision generation, persistence, attachment integration, API/GUI/CLI, generated `blocked`, daily export, weekly summary ve Step 215 uygulanmamistir.

## 213 FieldObservationRepository Status Update Karari

- `FieldObservationRepository`, `update_status(observation_id, new_status)` explicit status mutation method'unu saglar.
- Method existing `find_by_id(...)` lookup davranisini kullanir.
- Missing `observation_id` icin `None` dondurur ve repository contents degismez.
- Found record icin yalniz `record.status = new_status` assignment'i yapilir ve ayni stored record nesnesi dondurulur.
- `new_status` trim, normalize, validate, map veya convert edilmez; status constants veya enum eklenmez.
- `closed_at`, `reported_at`, notes, `is_archived` veya baska alan otomatik set/clear edilmez.
- Existing `list_by_status(...)` filtreleri ayni stored record nesnesini okudugu icin update'i hemen yansitir.
- Archived observation kayitlari explicit status update'ten engellenmez; archive gating bu adimin kapsami degildir.
- Step 212, PR #41 squash merge commit `e5842131882034eaf0cf5c8ec198f17c0f063dbe` ile latest merged/finalized safe point'tir; Issue #40 completed olarak kaydedilir.
- Step 213, Issue #42 ve `step-213-field-observation-status-update` branch'i uzerinde aktif unmerged explicit status-update isidir.
- Podcast 032 latest completed podcast olarak Steps 206-210 araligini kapsar; sonraki besli podcast araligi Steps 211-215'tir.
- `close(...)`, `reopen(...)`, transition rules, automatic timestamps, validation/enums/constants, other field updates, archive/restore/delete/bulk operations, persistence, attachment integration, API/GUI/CLI, audit/history/task/NCR/decision generation, generated `blocked`, daily export, weekly summary ve Step 214 uygulanmamistir.

## 212 FieldObservationRepository Project ve Status Filter Karari

- `FieldObservationRepository`, `list_by_project_id(project_id)` ve `list_by_status(status)` read-only filtrelerini saglar.
- `list_by_project_id(project_id)`, yalniz `record.project_id == project_id` exact match sonucunu dondurur.
- `list_by_status(status)`, yalniz `record.status == status` exact match sonucunu dondurur.
- Filtreler case-sensitive calisir; trim, normalize, validation, enum, fallback veya status vocabulary enforcement yapmaz.
- Eslesmeyen veya bilinmeyen degerler `[]` dondurur.
- Sonuclar repository ekleme sirasini korur.
- Her filtre cagrisi yeni bir liste dondurur; disarida donen liste mutate edilirse repository storage degismez.
- Record nesneleri kopyalanmaz ve mutate edilmez; mevcut in-memory repository sozlesmesi korunur.
- Archived matching record'lar filtre sonucundan dislanmaz; bu method'lar active/archive filtresi degildir.
- Step 211, PR #39 squash merge commit `26509f35abb0cb706d2a085715310358cf5d2421` ile latest merged/finalized safe point'tir; Issue #38 completed olarak kaydedilir.
- Step 212, Issue #40 ve `step-212-field-observation-project-status-filters` branch'i uzerinde aktif unmerged repository filter isidir.
- Podcast 032 latest completed podcast olarak Steps 206-210 araligini kapsar; sonraki besli podcast araligi Steps 211-215'tir.
- Category/location/reported_to/date-time/text-search/active/archive-only/combined filters, lifecycle mutation, summaries/reporting, persistence, attachment integration, validation/normalization/enums/constants, API/GUI/CLI, audit/task/NCR conversion, generated `blocked`, daily export, weekly summary ve Step 213 uygulanmamistir.

## 211 Podcast 032 for Steps 206-210 Karari

- Podcast 032, yalniz Steps 206-210 araligini kapsayan NotebookLM kaynak notu olarak `docs/podcast_notes/032_adim_206_210_notebooklm_podcast_notu.md` dosyasinda hazirlanir.
- Podcast 032'nin ana anlatimi: source authority and execution discipline -> reviewed observation contract -> minimal observation model -> minimal in-memory repository.
- Step 210, PR #37 squash merge commit `c7dbd94076f9e23c928f27ea377a97debad6636b` ile latest merged/finalized safe point'tir; Issue #36 completed olarak kaydedilir.
- Step 211, Issue #38 ve `step-211-podcast-032-steps-206-210` branch'i uzerinde aktif unmerged documentation/podcast isidir.
- Podcast 032, Step 211 merge edilene kadar active artifact'tir; merge sonrasinda latest completed podcast olur ve Steps 206-210 araligini kapsar.
- Sonraki besli podcast araligi Steps 211-215 olarak kaydedilir.
- Current local verification baseline `420 passed` olarak korunur.
- `FieldObservationRecord` ve minimal bellek ici `FieldObservationRepository` baseline'i implement edilmistir.
- Persistence, filters, lifecycle updates, attachment integration, reporting/export, API/GUI/CLI, audit, validation, generated `blocked`, daily export ve weekly summary henuz uygulanmamistir.
- Step 211 product behavior, production code, executable test, workflow behavior, Actions setting, ZIP mutation, Desktop archive mutation veya Step 212 baslatmaz.

## 210 FieldObservationRepository Baseline Karari

- `FieldObservationRepository`, merge edilmis `FieldObservationRecord` modeli icin minimal bellek ici repository baseline'i olarak `app/records.py` icine eklendi.
- Repository `add(record)`, `list_all()`, `count()` ve `find_by_id(observation_id)` davranislarini saglar.
- `add(record)`, ayni `observation_id` daha once eklenmisse `ValueError` uretir; farkli `observation_id` degerlerini kabul eder.
- `list_all()`, ic listedeki record nesnelerini kopyalamadan yeni bir liste dondurur; disarida dondurulen listeyi degistirmek repository'nin ic koleksiyonunu degistirmez.
- Record nesneleri repository icinde normalize edilmez, kopyalanmaz veya mutate edilmez.
- Step 209, PR #35 squash merge commit `f1fd7b8e6add21369b3d5f4c44d014994538fc1c` ile latest merged/finalized safe point'tir; Issue #34 completed olarak kaydedilir.
- Step 210, Issue #36 ve `step-210-field-observation-repository-baseline` branch'i uzerinde aktif unmerged repository-baseline isidir.
- `FieldObservationRecord` halen tek Field-MVP model implementasyonudur; `FieldObservationRepository` yalniz baseline-level bellek ici repository'dir.
- Filters, lifecycle updates, archive/restore/delete/bulk operations, persistence/database/JSON/SQLite, attachment integration, export/reporting, API/GUI/CLI, audit/task/NCR/conversion/decision generation, validation/normalization, generated `blocked`, daily export, weekly summary, Step 211 ve Podcast 032 uygulanmamistir.

## 209 Minimal FieldObservationRecord Model Karari

- `FieldObservationRecord`, ilk Field MVP resmi hizli saha gozlem kaydi icin minimal dataclass olarak `app/models.py` icine eklendi.
- Required constructor fields: `observation_id`, `project_id`, `observed_at`, `location`, `category`, `description`.
- Defaults: `status = "open"`, optional context/lifecycle fields `None`, `is_archived = False`.
- `open`, `tracking` ve `closed` lifecycle degerleri validation yan etkisi olmadan oldugu gibi tutulur.
- Focused testler minimal construction/default, optional/lifecycle field value holding ve documented status value holding davranisini dogrular.
- Step 209, Field MVP implementasyonunu yalniz bu dar dataclass/test kapsaminda baslatir.
- Attachment linking, repository/persistence, export/reporting, API/GUI/CLI, audit, structured location/contact normalization ve validation henuz uygulanmamistir.
- Step 209, PR #35 squash merge commit `f1fd7b8e6add21369b3d5f4c44d014994538fc1c` ile merge edildi ve Step 210 baslangicindaki latest merged/finalized safe point oldu.
- Step 209 kapsaminda ek Field-MVP model, repository, persistence, attachment integration veya validation eklenmedi.
- Repository baseline isi Step 210 / Issue #36 kapsaminda ayri adim olarak baslatildi.

## 208 First Field MVP Observation Record Contract Karari

- `FieldObservationRecord`, ilk Field MVP hizli saha gozlem kaydi icin gelecekte eklenecek resmi/proje kaydi contract'i olarak tanimlanir.
- Required future fields: `observation_id`, `project_id`, `observed_at`, `location`, `category`, `description`.
- `status` default degeri `open`; ilk vocabulary `open`, `tracking`, `closed`.
- Optional/deferred-at-capture fields: `reported_to`, `reported_at`, `created_by`, `closed_at`, `notes`, `is_archived`.
- `location` V1'de fast-capture text/snapshot alanidir; future structured normalization ayri adimda `SiteLocationRecord` kullanabilir.
- `reported_to` V1'de optional fast-capture text/snapshot alanidir; future identity/contact normalization ayri adimda `ContactPersonRecord` kullanabilir.
- Attachments observation record icine gomulmez; ayri `FileAttachmentRecord` satirlari `related_record_type = "field_observation"` ve `related_record_id = observation_id` ile baglanir.
- Initial record creation attachment veya `reported_to` gerektirmez; bu bilgiler sonradan eklenebilir.
- `closed` lifecycle state'tir, fiziksel silme degildir; archive closed'dan ayridir.
- Private notes resmi observation record'a sessizce kopyalanmaz; future conversion acik kullanici islemi gerektirir.
- Step 208 documentation/state/contract-only'dir; production code, executable test/fixture, workflow behavior, persistence, API/GUI/CLI, audit, migration, backup/restore, hard validation, generated `blocked`, task creation, NCR conversion, automatic official decision, export output, ZIP mutation, Step 209 veya field-MVP implementation eklenmez.
- Step 207, PR #31 squash merge commit `23baddf413e1cdf5a5e5564fe4a559954572e45f` ile latest merged/finalized safe point'tir; Issue #30 completed olarak kaydedilir.
- Step 208, Issue #32 ve `step-208-first-field-mvp-observation-contract` branch'i uzerinde aktif unmerged documentation/contract isidir.
- Step 209, bu contract review edilip merge edildikten sonra onerilen implementation adimidir.

## 207 Unified Project Source, GitHub Bootstrap ve Codex Invocation Policy Karari

- `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`, product purpose, strategy, data principles, product layers, roadmap, source-conflict resolutions ve long-term architecture icin ust tracked proje kaynagidir.
- `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`, operational workflow, Git/GitHub/Codex rules, safety, verification ve execution protocol icin yetkili kaynaktir.
- Guncel GitHub Issue ve `.cse/tasks/<step>_task.md`, yalniz mevcut step'in authorized scope'unu belirler; kalici product/data principles veya safety rules sessizce override edilemez.
- `.cse/state/project_state.json` ve ilgili `.cse/results/<step>_result.md`, factual state/evidence kayitlaridir.
- `docs/protocols/CSE_PROJECT_SOURCE_REGISTER.md`, approved source set, copied reference files, unavailable originals, no-fabrication ve no-raw-ZIP kurallarini kaydeder.
- `docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md`, yeni chat'in GitHub'dan baslamasini kalici hale getirir; normal continuation icin ZIP/handoff upload veya uzun prompt kopyalama gerekmez.
- Yeni chat'te kullanici normalde `devam` veya `GitHub'dan devam et` diyebilir; ChatGPT GitHub repository, Issue, PR ve merge state'i okuyarak sonraki aksiyonu belirler.
- ChatGPT, Codex gerekip gerekmedigine karar verir. Local execution gerekiyorsa kullaniciya `Codex çalışmalı` der ve nedenini kisaca aciklar.
- Codex local project-file edits, local tests/scripts/validation/hash/path/worktree/ignored-file/ZIP checks, branch checkout, stage/commit/push, local error resolution ve GitHub'in guvenle yapamayacagi local operations icin gerekir.
- Codex planning, reasoning, architecture, summaries, GitHub Issue/PR/diff/comment/review/merge-state inspection, Issue/comment creation, branch push edildikten sonra Draft PR creation, ready/review/merge GitHub-native actions, web research ve local evidence gerekmeyen state reporting icin normalde gerekmez.
- Default execution modeli: `1 technical step = 1 primary Codex run`, `blocking correction = at most 1 correction run`, `post-merge sync = batch into the next Codex-required run when safe`.
- Non-blocking wording veya metadata observations icin ayri Codex run uretilmez; repository truth, tests, PR review veya merge safety blocked olmadikca correction bir sonraki consolidated run'a biriktirilir.
- Bir result/state dosyasi kendi commit SHA'sini iceremiyor diye ekstra metadata commit uretilmez; final branch-head SHA ve divergence Issue completion comment ve PR metadata icinde kaydedilebilir.
- Her Codex execution edit oncesi `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`, `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`, current GitHub Issue ve `.cse/tasks/<step>_task.md` kaynaklarini bu sirayla okur. Workflow/handoff/bootstrap/source-authority task'larinda `docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md` de okunur.
- Step 206, PR #29 squash merge commit `3b05fae76766cedc8840eea6c0fc2f51440354e4` ile latest merged/finalized safe point'tir; Issue #28 completed olarak kaydedilir.
- Step 207, Issue #30 ve `step-207-codex-invocation-policy` branch'i uzerinde documentation/state/protocol aktif isidir; merge edilene kadar yeni guvenli nokta sayilmaz.
- Production code, executable test/fixture, workflow behavior, Actions enablement, required checks, API/GUI/CLI implementation, persistence, audit, backup/restore, migration, hard validation, generated `blocked`, export output, ZIP mutation, Desktop archive mutation, raw ZIP package commit, replacement handoff ZIP, Step 208 ve field-MVP implementation eklenmez.

## 206 Step 205 Merged Truth, Podcast 031 ve Instruction Authority Closure Karari

- Tracked canonical proje talimat kaynagi `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md` dosyasidir; current instruction authority icin tek yetkili kaynak budur.
- `CSE_GUNCEL_PROJE_TALIMATLARI.md` artik higher-priority override degildir; yalniz resmi yerel repoda kolay okuma icin tutulabilecek optional local mirror'dir.
- Local mirror mevcutsa canonical metinle byte-for-byte ayni icerikte tutulur, `.git/info/exclude` uzerinden ignored kalir, stage edilmez ve commitlenmez.
- Codex execution resmi local repo olan `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer` yolunda baslar; `git rev-parse --show-toplevel` sonucu bu root'a esit degilse Git veya file write yapmadan durulur.
- CSE icin otomatik `C:` clone/workspace olusturulmaz ve kullanilmaz; instruction ve completion evidence current GitHub Issue uzerinden paylasilirken local execution resmi `V:` reposunda kalir.
- Step 205, PR #26 squash merge commit `92a15f2a55e6bfda42d50b8ef7dea651ff496f62` ile latest merged/finalized safe point'tir; Issue #25 completed olarak kaydedilir.
- Step 206, Issue #28 ve `step-206-podcast-031-and-authority-closure` branch'i uzerinde documentation/state/protocol aktif isidir; merge edilene kadar yeni guvenli nokta sayilmaz.
- Podcast 031, yalniz Step 201-205 araligini kapsar; sonraki besli podcast araligi Step 206 ile baslar.
- `docs/podcast_notes/README.md` stale Step 022 current-state orneginden arindirildi; durable cadence ve factual Podcast 030/031 state ile tutulur.
- `C:\Users\Fatih\Documents\chieh-site-engineer` misspelled workspace kullanici tarafindan kaldirilmis kabul edilir ve Step 206 preflight'ta local `Test-Path` ile absent dogrulanir; bu Git history iddiasi degildir.
- `C:\Users\Fatih\Desktop\fatih\chief-site-engineer` ayri local archive riskidir; canonical origin remote bulunmadigi, silinmis interim podcast note path'i ve untracked final `005_adim_021_025_notebooklm_podcast_notu.md` onceki bilinen durum olarak kaydedilir. Bu repo Step 206'da silinmez, uzerine yazilmaz, tasinmaz veya commitlenmez.
- Production code, executable test/fixture, workflow behavior, Actions enablement, required checks, API/GUI/CLI, persistence/database/repository, audit, backup/restore, migration, hard validation, generated `blocked`, export output, ZIP mutation, Desktop archive mutation, Step 207 ve field-MVP implementation eklenmez.

## 205 Canonical Project Instructions and Repository Truth Resynchronization Karari

- Step 205 sirasinda `CSE_GUNCEL_PROJE_TALIMATLARI.md` verified local-only source olarak korunmus, tracked `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md` fresh clone/handoff fallback authority olarak eklenmisti; bu authority modeli Step 206 ile superseded edilmistir.
- Step 206 sonrasinda current instruction authority tracked `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md` dosyasidir; root dosya yalniz ignored optional mirror olarak ele alinir.
- Canonical dosya local-only source'tan initially derived edilmisti; persistent product/protocol meaning ve section order korunurken Section 4, Section 17 ve ChatGPT/GitHub/Codex workflow'u intentionally adapted edilmisti. Adaptation sonrasi equal SHA, equal line count veya full text equivalence iddiasi yapilmaz.
- Official local repository branch/file/test/commit/push execution surface, GitHub synchronized coordination/review surface olarak kalir. Kullanici normalde `devam` der; ChatGPT GitHub state/actions'i dogrudan yonetir, Codex yalniz gerekli local execution icin kullanilir ve evidence current Issue uzerinden tasinir.
- Step 205 kaydi yazildigi sirada Step 204, PR #24 squash merge commit `7e5a06ed3cb62399219f9ad66b6b2b8e6eca77a3` ile latest merged/finalized safe point olarak kaydedilmisti; bu current safe point Step 206 ile Step 205 / PR #26 gercegine guncellenmistir.
- Step 205 kaydi yazildigi sirada Step 205, merge edilene kadar documentation/state-only active branch olarak kaydedilmisti; Step 206 sirasinda Step 205 artik merged/finalized safe point'tir.
- `.github/workflows/pytest.yml` repoda vardir; automatic Actions execution account billing/runner-start constraint nedeniyle manually disabled kalir ve required status checks etkinlestirilmez.
- CSE tested domain/data/documentation core'dur, field-ready application degildir; persistence/database, real file upload, API, GUI, authentication/authorization, deployment ve complete backup/restore production capabilities henuz yoktur.
- Urun kurali reliable data backbone first, automation later, AI last olarak korunur.
- Step 205 sonrasi ilk product direction; fast observation record, attachment, location, status tracking, reported-to, daily export ve weekly summary iceren dar field MVP'dir; implementation bu adimda baslatilmaz.
- Podcast 031, Step 201-205 araligini Step 205 merge sonrasi ozetleyecek dogal documentation follow-up'tur.
- Production code, executable test/fixture, workflow behavior, Actions enablement, required checks, API/GUI/CLI, persistence/database/repository, audit, backup/restore, migration, hard validation, generated `blocked`, export output, ZIP mutasyonu, automatic decision, PR creation ve merge behavior eklenmez.

## 204 Handover QC Fixture Naming and Assertion Checklist Plan Karari

- Adim 204, Issue #23 talimatina gore future handover QC presentation view-model icin fixture naming, ownership/location ve assertion checklist planini documentation/state-only olarak sabitler.
- Structured source of truth yalniz `build_export_handover_qc_review_checklist(summary, report)` ciktisidir.
- `format_export_handover_qc_review_checklist_as_markdown(checklist)` optional display-only Markdown olarak kalir; Markdown structured truth olarak parse edilmez ve source checklist yerine gecmez.
- Yedi canonical case icin dort ayri artifact family kullanilir: `handover_qc_source_checklist_<case>`, `handover_qc_expected_view_model_<case>`, `handover_qc_expected_markdown_<case>` ve `handover_qc_expected_review_visibility_<case>`.
- Future fixture data ownership test layer'a aittir ve yalniz `tests/fixtures/handover_qc/` altinda planlanir; production code `tests/fixtures/` altindan import yapamaz ve dokumantasyon runtime dependency degildir.
- Expected Markdown optional display regression artifact'i, expected review visibility ise yalniz human-review visibility contract'idir; fixture'lar persistence, audit, export writing veya package decision mekanizmasi degildir.
- Official-transferable fixture data ile private/non-transferable bilgi ayrilir; credentials, secrets, private field notes, local cache ve user-specific non-transferable data fixture'lara giremez.
- Assertion checklist canonical wording, empty/unsupported fallback, source truth, immutability, no recomputation, no side effects, read-only/non-blocking semantics ve official/private transfer boundary'sini kapsar.
- `approved`, `rejected`, `blocked`, `official_decision`, `package_blocked`, `audit_event_id`, `persisted_at` ve `export_written` future view-model contract disinda tutulur.
- Success official approval, review/failure automatic rejection, mixed package decision ve unknown hard validation degildir; generated `blocked` veya automatic decision eklenmez.
- Tek dar future proposal, ayri acik yetkili task icinde yedi canonical case icin fixture data ve fixture-contract testleri olusturulmasidir; presentation consumer veya production feature expansion eklenemez.
- Production code, executable fixtures/tests, workflow, required status checks, API/GUI/CLI, persistence, audit, backup/restore, migration, hard validation, generated `blocked`, file/export output, ZIP mutasyonu, PR creation ve merge behavior eklenmez.

## 203 Official Local Sync Protocol Karari

- Adim 203, Issue #21 talimatina gore official local working copy protokolunu documentation-only olarak sabitler.
- Official local repository path `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer` proje dosyasi olusturma, duzenleme, verification, commit ve push icin primary working copy olarak kaydedilir.
- GitHub connector veya web/API uzerinden olusturulan dosyalar tek basina completion sayilmaz; GitHub synchronized remote ve review surface olarak kalir.
- `.cse/README.md` standard flow'u local-first hale getirir; ChatGPT/GitHub-only branch veya task creation completion olarak kabul edilmez.
- `.cse/templates/task_template.md` future task'lar icin local-first precondition, master sync evidence, local branch creation, local file presence, divergence ve post-merge sync boundary alanlarini zorunlu hale getirir.
- `.cse/templates/result_template.md` future result report'lari icin official local path, synchronized master SHA, branch SHA, divergence, local file presence, verification, protected paths, exports, ZIP, final working tree ve push result raporlamasini zorunlu hale getirir.
- Branch degistirme veya pull oncesinde `git status --short --branch` ve ignored/untracked gorunurluk ile local working tree incelenmelidir.
- Unexpected tracked, staged veya untracked project changes varsa Codex durup raporlamalidir; otomatik reset, clean, stash, delete veya overwrite yapmamalidir.
- Existing ignored ZIP emergency/offline artifact olarak kalir ve normal step calismasinda dokunulmaz.
- Local `master` sadece fast-forward-only sync ile `origin/master` durumuna getirilir; Adim 203 icin beklenen synchronized master commit `a5fcadf1108dce409d7a1ddd9928b6a9cbb730c9` olarak kaydedilir.
- Work branch `step-203-official-local-sync-protocol`, synchronized `master` uzerinden localde olusturulur.
- Required local verification `python -m pytest`, `git diff --check`, protected-path diff, changed-file scope, exports cleanliness, ZIP untouched status, divergence ve final working-tree status raporlamasini kapsar.
- Issue #21 kapsaminda Codex draft PR acmaz; branch push edilir ve ChatGPT review / PR acma sureci ayri kalir.
- Production code, tests, workflow, required status checks, API/GUI/CLI, persistence, audit, backup/restore, migration, hard validation, generated `blocked` status, export output, ZIP mutasyonu ve merge behavior eklenmez.

## 202 Canonical Handover QC View-Model Examples and Wording Karari

- Adim 202, future handover QC presentation view-model consumer'lari icin canonical example ve wording standardizasyonunu documentation-only olarak hazirlar.
- Structured source of truth `build_export_handover_qc_review_checklist(summary, report)` ciktisi olarak kalir.
- `format_export_handover_qc_review_checklist_as_markdown(checklist)` optional presentation text olarak kalir; future consumer Markdown'u structured truth olarak parse etmemelidir.
- Status wording standardi `Ready for review`, `Needs human review`, `Review status unknown` ve unknown status icin `Unknown status; treat as review visibility only` ifadelerini kullanir.
- Human-review wording standardi `Human review required` ve `No review signal from checklist` ifadelerini kullanir; bu ifadeler resmi kabul, ret veya paket karari degildir.
- Empty state, missing optional field, unknown status ve missing next-action fallback metinleri insan incelemesi icin sabitlenir.
- Canonical examples success-only, failure-only, mixed, empty/zero-count, missing optional fields, unknown status/additional fields ve unsupported input fallback kategorilerini kapsar.
- `is_read_only=True`, `is_blocking=False` ve `requires_human_review` yalniz human-review visibility semantics olarak korunur.
- Generated `blocked` status, automatic acceptance/rejection/approval/package blocking, official transfer decision, persistence, audit, backup/restore, migration ve hard validation eklenmez.
- Official transferable handover data ile private/non-transferable information ayrimi her ornekte korunur.
- Sonraki dar teknik onerim future handover QC presentation view-model icin documentation-only fixture naming and assertion checklist hazirlamaktir; implementation baslatilmaz.
- Production code, tests, workflow, required status checks, API/GUI/CLI, persistence, audit, backup/restore, migration, hard validation, generated `blocked` status, file/export output ve ZIP mutasyonu eklenmez.

## 201 Podcast 030 - Adim 196-200 NotebookLM Podcast Notu Karari

- Adim 201, Podcast 030'u documentation-only olarak hazirlar.
- Podcast 030 yalniz Adim 196-200 araligini kapsar.
- Podcast notu Step 196 minimal GitHub Actions `pytest` workflow'unu ve stabil `pytest` check adini ozetler.
- Podcast notu Step 197 explicit merged-state finalization semantigini ve billing lock'un external CI execution constraint oldugunu anlatir.
- Billing lock pytest failure, workflow-code defect veya required status check basarisi olarak siniflandirilmaz.
- Podcast notu Step 198 roadmap/current checkpoint resynchronization calismasini ozetler.
- Podcast notu Step 199 handover QC checklist phase closure ve downstream boundary review kararlarini ozetler.
- Podcast notu Step 200 downstream presentation consumer contract ve future test matrix planini ozetler.
- Local verification `413 passed` olarak factual kalir; GitHub-hosted runner execution account billing lock nedeniyle baslamamistir.
- `is_read_only=True`, `is_blocking=False` ve `requires_human_review` yalniz human-review signal semantics olarak korunur.
- Generated `blocked` status, automatic acceptance/rejection/approval/package blocking, persistence, audit, backup/restore, migration ve hard validation eklenmez.
- Official transferable handover data ile private/non-transferable information ayrimi podcast notunda acik tutulur.
- Production code, tests, workflow, required status checks, API/GUI/CLI, persistence, audit, backup/restore, migration, hard validation, generated `blocked` status, file/export output ve ZIP mutasyonu eklenmez.

## 200 Downstream Presentation Consumer Contract and Test Matrix Plan Karari

- Adim 200, future handover QC screen ve export review flow presentation consumer sozlesmesini documentation-only olarak planlar.
- Consumer input boundary structured source of truth olarak `build_export_handover_qc_review_checklist(summary, report)` ciktisidir.
- `format_export_handover_qc_review_checklist_as_markdown(checklist)` ciktisi optional presentation Markdown olarak okunabilir; future consumer Markdown'u structured source of truth olarak parse etmemelidir.
- Future view-model contract implementation-free kalir ve API/GUI/CLI consumer baslatmaz.
- Required field set `checklist_type`, `status`, `summary`, `items`, `review_notes`, `is_read_only`, `is_blocking` ve `requires_human_review` alanlarina dayanir.
- Summary ve item visibility alanlari insan incelemesi icin gorunur tutulur; missing/unknown alanlar hard validation veya automatic rejection yerine fallback display ile ele alinmalidir.
- `is_read_only=True`, `is_blocking=False` ve `requires_human_review` yalniz human-review signal semantics olarak korunur.
- Future consumer success visibility'yi official acceptance, failure/review visibility'yi automatic rejection, mixed visibility'yi package decision veya unknown visibility'yi hard validation olarak yorumlamamalidir.
- Generated `blocked` status, automatic acceptance/rejection/approval/package blocking, persistence, audit, backup/restore, migration ve hard validation eklenmez.
- Report building, checklist building, Markdown formatting, presentation consumption, human review, validation, persistence, audit ve export writing katmanlari ayri kalir.
- Official transferable handover data approved documentation, structured summary/report/checklist ve explicitly selected review Markdown/export package ile sinirlidir; private workspace notes, user-specific context, credentials/secrets, local cache ve non-transferable personal data disarida kalir.
- Future regression/test matrix success-only, failure-only, mixed, empty/zero-count, missing required/optional fields, unknown/additional fields/statuses, unsupported input, immutability, no recomputation, no file/export output, no persistence/audit side effect, no hard validation, no generated `blocked`, no automatic acceptance/rejection/blocking ve private/non-transferable exclusion basliklarini kapsamalidir.
- Sonraki dar teknik onerim future handover QC presentation view-model icin documentation-only canonical examples and wording standardization hazirlamaktir.
- Step 196-200 NotebookLM podcast note, Step 200 merge edildikten sonraki documentation follow-up olarak kaydedilir; bu adimda podcast notu olusturulmaz.
- Production code, tests, workflow, required status checks, API/GUI/CLI, persistence, audit, backup/restore, migration, hard validation, generated `blocked` status, file/export output ve ZIP mutasyonu eklenmez.

## 199 Handover QC Checklist Phase Closure and Downstream Boundary Karari

- Adim 199, Adim 181-192 export/handover QC checklist ve Markdown formatter fazini documentation-only olarak kapatir.
- `build_export_handover_qc_review_checklist(summary, report)` stable contract'i read-only JSON-ready checklist dict uretimidir; input olarak existing `build_export_result_summary(...)` ve `build_export_result_report(...)` output'lari okunur.
- `format_export_handover_qc_review_checklist_as_markdown(checklist)` stable contract'i checklist dict'i presentation-safe Markdown/string olarak sunmaktir.
- `is_read_only=True` helper zincirinin okuma/gorunurluk katmani oldugunu gosterir.
- `is_blocking=False` checklist veya formatter ciktisinin resmi paket bloklama mekanizmasi olmadigini gosterir.
- `requires_human_review` yalniz insan inceleme sinyalidir; automatic official acceptance, rejection, package blocking, hard validation veya generated `blocked` status degildir.
- Downstream consumer'lar report building, checklist building, Markdown presentation, human review, validation, persistence, audit ve export writing katmanlarini ayri tutmalidir.
- Future handover QC screen checklist/Markdown ciktisini yalniz read-only presentation icin kullanabilir; official decision veya blocking state uretmemelidir.
- Future export review flow export result summary/report/checklist zincirini gorunurluk icin okuyabilir; export file writing, overwrite, backup/restore veya audit davranisi ayri explicit scope ister.
- Future API/GUI/CLI presentation consumer bu adimda baslatilmaz; gerekiyorsa ayri task, ayri test matrix ve explicit non-blocking contract ile ele alinmalidir.
- Admin/debug visibility teknik detail, path, next action hint ve review notes bilgilerini insan incelemesine sunabilir; private/non-transferable user information'i official transferable handover data ile karistirmamalidir.
- Official transferable handover data yalniz structured report/checklist, approved documentation ve explicit export package kapsaminda ele alinmalidir; private workspace notes, user-specific context, credentials, secrets, local caches ve non-transferable personal data resmi devir paketine katilmaz.
- Sonraki dar teknik onerim future handover QC screen / export review presentation consumer icin documentation-only contract and test matrix plan hazirlanmasidir; implementation baslatilmaz.
- Production code, tests, workflow, required status checks, API/GUI/CLI, persistence, audit, backup/restore, migration, hard validation, generated `blocked` status, file/export output ve ZIP mutasyonu eklenmez.

## 198 Roadmap and Current Checkpoint Resynchronization Karari

- Adim 198, ana proje dokumantasyonunu Adim 197 guvenli noktasina gore senkronize eder.
- Guncel guvenli nokta Adim 197'dir; merge commit `947350ff9348f79965fec282c28e2fa858d7356a` olarak kaydedilir.
- Adim 193-197 araligi factual olarak ozetlenir: CSE handoff protocol, read-only status command, explicit post-merge state finalization, GitHub Actions `pytest` workflow ve finalized checkpoint/billing constraint record.
- Guncel local test sayisi `413 passed` olarak kaydedilir.
- CI bulunmadigi yonundeki eski ifade artik dogru degildir: `.github/workflows/pytest.yml` vardir.
- GitHub-hosted runner startup su anda account billing lock nedeniyle dissal olarak engellenmektedir; bu durum pytest failure veya workflow code defect olarak yorumlanmaz.
- Required status checks, basarili bir GitHub Actions `pytest` kosusu olana kadar disabled kalmalidir.
- Sonraki teknik yon handover QC/checklist phase closure ve downstream consumer boundary review olarak kaydedilir; API/GUI/CLI implementation baslatilmaz.
- Hard validation ve generated `blocked` status explicit future scope olmadan eklenmez.
- Podcast cadence review sonucu catch-up pending durum vardir: Adim 181-185, 186-190 ve 191-195 icin podcast notlari beklemededir; Adim 196-200 notu Adim 200 tamamlanmadan dogrudan gerekli degildir.
- Bu adim documentation/state-only kalir; production code, tests, workflow, exports, ZIP, persistence, audit, backup/restore, migration, deployment, release, publishing ve secrets degistirilmez.

## 197 Merged Checkpoint and Billing Constraint Karari

- Adim 197, Step 196 merge sonrasi state semantigini latest merged/finalized checkpoint olarak sabitler.
- `.cse/state/project_state.json` merged/finalized checkpoint'i temsil eder; acik draft work kendi task/result/branch/issue/PR kayitlariyla izlenir.
- GitHub billing lock, CI runner startup oncesi dissal execution constraint olarak kaydedilir.
- Billing lock pytest failure, workflow YAML failure veya required status check basarisi olarak siniflandirilmaz.

## 196 GitHub Actions Pytest Workflow Karari

- Adim 196, `.github/workflows/pytest.yml` workflow'unu ekler.
- Workflow PR-to-master ve push-to-master icin `git diff --check` ve `python -m pytest` kosacak sekilde tanimlidir.
- Workflow deployment, release, publishing, secrets, automatic merge veya branch mutation yapmaz.
- Required checks, GitHub Actions uzerinde basarili `pytest` kosusu olana kadar policy gate olarak acilmaz.

## 195 Explicit Post-Merge State Finalization Karari

- Adim 195, `scripts/cse_status.py --finalize-state` yolunu ekler.
- Finalized state yazimi yalniz explicit CLI metadata ile yapilir; GitHub issue/PR state otomatik tahmin edilmez.
- Default `python scripts/cse_status.py` read-only diagnostic komut olarak kalir.
- Script otomatik staging, cleaning, commit, push, branch change veya merge yapmaz.

## 194 Read-only CSE Status Command Karari

- Adim 194, repository handoff durumunu read-only raporlayan CSE status command'i ekler.
- Branch, HEAD, divergence, git status, diff check, exports, ZIP ve opsiyonel pytest gorunurlugu saglanir.
- Varsayilan davranis test kosmaz ve repo mutasyonu yapmaz.

## 193 GitHub-native CSE Handoff Protocol Karari

- Adim 193, `.cse/` altinda task, result, template ve project state tabanli GitHub-native ChatGPT/Codex handoff protokolunu kurar.
- Canonical reusable template dosyalari `.cse/templates/` altinda kalir.
- Duplicate `.cse/tasks/TASK_TEMPLATE.md` ve `.cse/results/RESULT_TEMPLATE.md` dosyalari repo source of truth'u karistirmamasi icin kaldirilir.
- ZIP dosyalari emergency/offline backup olarak tracked scope disinda kalir.

## 192 Export / Handover QC Checklist Formatter Test Example Karari

- Adim 192, `format_export_handover_qc_review_checklist_as_markdown(checklist)` helper'i icin test examples ve regression boundary standardini documentation-only olarak netlestirir.
- Test example kategorileri success, failure, mixed, empty, missing field, unknown status, unsupported input, no mutation, no file/export output, no hard validation, no generated `blocked` status ve existing helper regression davranislarini kapsar.
- Formatter input olarak `build_export_handover_qc_review_checklist(...)` ciktisi olan JSON-ready checklist dict'i beklemeye devam eder ve output olarak insan incelemesine uygun Markdown/string dondurur.
- Formatter checklist, summary veya report sonucunu yeniden hesaplamaz; input dict'i mutate etmez; dosya yazmaz; export uretmez; `exports/` altina cikti birakmaz.
- `is_blocking` otomatik karar, kayit reddi veya bloklama mekanizmasi degildir; `requires_human_review` yalniz insan inceleme sinyalidir.
- Unsupported input guvenli ve gorunur fallback olarak okunur; hard validation, automatic rejection veya generated `blocked` status'a donusturulmez.
- Bu adim yeni test eklemez; ileride kod/test adimi gerekirse ayri adim olmali ve Extra High reasoning onerilmelidir.
- Hard validation, automatic rejection, migration, backup/restore, API/GUI/CLI behavior, database/repository access, audit event creation ve export helper yerine dogrudan dosya yazma kapsam disidir.
- Kod/test/helper davranisi, export ciktisi, commit ve push eklenmez.

## 191 Export / Handover QC Checklist Formatter Usage Karari

- Adim 191, `format_export_handover_qc_review_checklist_as_markdown(checklist)` helper'i icin usage documentation, example standardization ve edge case yorumlama standardini documentation-only olarak netlestirir.
- Formatter input olarak `build_export_handover_qc_review_checklist(...)` ciktisi olan JSON-ready checklist dict'i bekler ve output olarak insan incelemesine uygun Markdown/string dondurur.
- Formatter helper zincirinde `build_export_result_summary(...)`, `build_export_result_report(...)`, `build_export_handover_qc_review_checklist(...)` sonrasi presentation katmanidir.
- Formatter dosya yazmaz, export uretmez, `exports/` altina cikti birakmaz, database/repository erisimi yapmaz, audit event uretmez, backup/restore veya migration baslatmaz.
- Formatter checklist, summary veya report sonucunu yeniden hesaplamaz ve input dict'i mutate etmez.
- `is_blocking` karar mekanizmasi olarak kullanilmaz; `requires_human_review` yalniz insan inceleme sinyalidir ve otomatik kabul, ret, bloklama, hard validation veya generated `blocked` status degildir.
- Success, failure, mixed, empty, missing field, unknown status ve unsupported input durumlari presentation/QC visibility olarak okunur; yeni business rule veya resmi handover karari turetilmez.
- Uygun kullanimlar handover QC review notu, future export review presentation layer, NotebookLM/insan ozetleri ve debug/admin metinsel incelemedir.
- Hard validation, otomatik kayit reddi, migration, backup/restore, API/GUI/CLI davranisi, audit event uretimi veya dosya export helper yerine dogrudan export yazimi kapsam disidir.
- Kod/test/helper davranisi, export ciktisi, commit ve push eklenmez.

## 190 Export / Handover QC Checklist Formatter Implementation Karari

- Adim 190, `format_export_handover_qc_review_checklist_as_markdown(checklist)` helper'ini read-only presentation formatter olarak ekler.
- Helper input olarak `build_export_handover_qc_review_checklist(summary, report)` ciktisi olan JSON-ready checklist dict'i bekler ve output olarak Markdown/string dondurur.
- Output checklist type, status, summary count'lari, `is_read_only`, `is_blocking`, `requires_human_review`, review notes ve checklist item listesini insan incelemesi icin gorunur kilar.
- Formatter dosya yazmaz, export uretmez, `exports/` altina cikti birakmaz, input'u mutate etmez, checklist/summary/report sonucunu yeniden hesaplamaz ve existing helper davranislarini degistirmez.
- `requires_human_review` insan incelemesi ihtiyaci olarak sunulur; formatter resmi kabul, resmi ret, otomatik bloklama, hard validation veya generated `blocked` status uretmez.
- Unsupported/missing alanlarda formatter guvenli ve okunabilir fallback Markdown uretir; tum review akisimi exception ile kirmaz.
- Existing `build_export_handover_qc_review_checklist(...)`, `build_export_result_summary(...)`, `build_export_result_report(...)`, `format_export_result_report_as_markdown(...)`, `format_export_result_summary_as_markdown(...)`, `write_*` ve `try_write_*` davranislari regression testleriyle korunur.
- API/GUI/CLI, database/repository erisimi, audit event, backup/restore, export ciktisi, hard validation ve `blocked` status kapsam disidir.

## 189 Export / Handover QC Checklist Formatter API Boundary Karari

- Adim 189, future downstream checklist formatter icin API boundary ve test matrix'i documentation-only olarak netlestirir.
- Olasil helper adi `format_export_handover_qc_review_checklist_as_markdown(checklist)` olarak kaydedilir; bu adimda helper veya formatter implementasyonu yapilmaz.
- Future formatter input olarak `build_export_handover_qc_review_checklist(summary, report)` ciktisi olan JSON-ready checklist dict'i beklemeli ve output olarak presentation-safe Markdown/string dondurmelidir.
- Formatter dosya yazmayacak, export uretmeyecek, `exports/` altina cikti birakmayacak, input'u mutate etmeyecek, checklist/summary/report sonucunu yeniden hesaplamayacak ve existing helper davranislarini degistirmeyecektir.
- Output `checklist_type`, `is_read_only=True`, `is_blocking=False`, `requires_human_review`, `review_notes` ve item listesi gorunurlugunu karar verici olmayan presentation/QC visibility olarak sunmalidir.
- Future test matrix success-only, failure-only, mixed, empty/zero-count, missing optional field, unknown/additional field, unsupported input, string output, input immutability, no file write/export output, no generated `blocked`, no hard validation ve existing helper regression basliklarini kapsamalidir.
- Future formatter karar verici otorite, hard validation, otomatik kabul/ret/bloklama, audit event, database/repository mutator, backup/restore runner veya export writer olmayacaktir.
- GUI/API/CLI entegrasyonlari bu adimda eklenmez; gerekiyorsa ayri adim, ayri test ve ayri dokumantasyonla ele alinacaktir.

## 188 Export / Handover QC Checklist Downstream Formatter Plan Karari

- Adim 188, `build_export_handover_qc_review_checklist(summary, report)` helper ciktisinin ileride Markdown veya presentation formatter ile nasil okunabilecegini documentation-only olarak planlar.
- Future formatter checklist JSON-ready dict input alabilir ve yalniz presentation-safe Markdown/string output dondurebilir.
- Formatter dosya yazmaz, export uretmez, `exports/` altina cikti birakmaz, input checklist dict'i mutate etmez, checklist sonucunu yeniden hesaplamaz ve `build_export_handover_qc_review_checklist(...)` davranisini degistirmez.
- Markdown gorunumunde `is_read_only=True`, `is_blocking=False`, `requires_human_review` ve `review_notes` karar verici olmayan QC visibility bilgisi olarak korunmalidir.
- Success-only gorunurluk resmi kabul, failure-only veya mixed gorunurluk otomatik ret ya da bloklama anlamina gelmez; empty, missing optional field ve unknown/additional field durumlari safe presentation fallback ile okunmalidir.
- Future formatter implementasyonu gerekiyorsa ayri adim, ayri test ve ayri dokumantasyonla ele alinacaktir.
- Hard validation, generated `blocked` status, API/GUI/CLI, database/repository erisimi, audit event, backup/restore ve export ciktisi kapsam disidir.

## 187 Export / Handover QC Checklist Downstream Boundary Karari

- Adim 187, `build_export_handover_qc_review_checklist(summary, report)` helper ciktisinin downstream formatter ve consumer sinirini documentation-only olarak planlar.
- Checklist output JSON-ready dict olarak kalir; future Markdown formatter, handover QC ekrani, export review akisi veya GUI/API/CLI consumer tarafindan yalniz presentation/QC visibility icin okunabilir.
- Downstream consumer'lar `is_read_only=True`, `is_blocking=False` ve `requires_human_review` alanlarinin non-blocking anlamini korumalidir.
- Checklist item'lari insan incelemesi icindir; success gorunurlugu resmi kabul/onay, failure veya mixed gorunurluk otomatik ret ya da bloklama degildir.
- Future Markdown formatter veya GUI/API/CLI entegrasyonu gerekiyorsa ayri adim, ayri test ve ayri dokumantasyonla ele alinacaktir.
- Database/repository erisimi, audit event, backup/restore, export ciktisi, hard validation ve generated `blocked` status kapsam disidir.
- Existing `build_export_handover_qc_review_checklist(...)`, `build_export_result_summary(...)`, `build_export_result_report(...)`, `format_export_result_report_as_markdown(...)`, `format_export_result_summary_as_markdown(...)`, `write_*` ve `try_write_*` davranislari korunur; downstream consumer'lar checklist output'unu mutate etmemelidir.

## 186 Export / Handover QC Checklist Helper Test Example Karari

- Adim 186, `build_export_handover_qc_review_checklist(summary, report)` helper'i icin test/example standardini guclendirir.
- Helper davranisi genisletilmez; `app/models.py` degistirilmez.
- Testler top-level checklist contract, summary alan seti, item alan seti, `review_notes` aciklayici siniri, `requires_human_review` alaninin bloklama anlamina gelmemesi, `is_read_only=True`, `is_blocking=False` ve generated `blocked` status uretilmemesi konularini sabitler.
- `format_export_result_summary_as_markdown(...)` davranisi regression testiyle korunur; mevcut summary/report/formatter/write/try_write helper zinciri degistirilmez.
- Checklist output JSON-ready, read-only ve presentation/QC visibility katmani olarak kalir; resmi kabul, resmi ret, otomatik bloklama, hard validation veya audit event degildir.
- API/GUI/CLI, database/repository erisimi, backup/restore, export ciktisi, hard validation ve `blocked` status kapsam disidir.

## 185 Export / Handover QC Checklist Helper Usage Karari

- Adim 185, `build_export_handover_qc_review_checklist(summary, report)` helper'inin usage boundary ve edge case okuma standardini documentation-only olarak netlestirir.
- Helper input olarak `build_export_result_summary(...)` ve `build_export_result_report(...)` ciktilari olan structured dict'leri bekler; formatter Markdown source of truth olarak parse edilmez.
- Output `checklist_type`, `status`, `summary`, `items`, `review_notes`, `is_read_only`, `is_blocking` ve `requires_human_review` alanlariyla JSON-ready checklist dict olarak okunur.
- `is_read_only=True`, `is_blocking=False` ve `requires_human_review` alanlari QC gorunurluk sinyalidir; resmi kabul, resmi ret, otomatik bloklama, hard validation veya generated `blocked` status degildir.
- Success-only, failure-only, mixed, empty/zero-count, missing optional field ve unknown/additional field durumlari insan incelemesini destekleyen gorunurluk olarak standardize edilir; yeni business rule veya karar otoritesi turetilmez.
- Helper dosya yazmaz, export uretmez, `exports/` altina cikti birakmaz, database/repository erisimi yapmaz, audit event uretmez, API/GUI/CLI veya backup/restore eklemez.
- Existing `build_export_result_summary(...)`, `build_export_result_report(...)`, `format_export_result_report_as_markdown(...)`, `format_export_result_summary_as_markdown(...)`, `write_*` ve `try_write_*` davranislari korunur.

## 184 Export / Handover QC Checklist Helper Implementation Karari

- Adim 184, `build_export_handover_qc_review_checklist(summary, report)` helper'ini read-only QC helper olarak ekler.
- Helper mevcut `build_export_result_summary(...)` ve `build_export_result_report(...)` ciktilarini JSON-ready checklist dict yapisina cevirir; formatter Markdown'u source of truth olarak parse etmez.
- Output `checklist_type`, gorunurluk `status`, `summary`, `items`, `review_notes`, `is_read_only=True`, `is_blocking=False` ve `requires_human_review` alanlarini icerir.
- Helper success-only, failure-only, mixed, empty/zero-count, missing optional field ve unknown/additional field durumlarini insan incelemesi icin gorunur kilar; resmi kabul, ret, otomatik bloklama, hard validation veya `blocked` status uretmez.
- Helper input mutate etmez, dosya yazmaz, export uretmez, `exports/` altina cikti birakmaz, database/repository erisimi yapmaz, audit event uretmez, API/GUI/CLI veya backup/restore eklemez.
- Existing `build_export_result_summary(...)`, `build_export_result_report(...)`, `format_export_result_report_as_markdown(...)`, `format_export_result_summary_as_markdown(...)`, `write_*` ve `try_write_*` davranislari regression testleriyle korunur.

## 183 Export / Handover QC Checklist Helper Implementation Plan Karari

- Adim 183, gelecekte yazilabilecek export / handover QC review checklist helper'i icin implementation planini documentation-only olarak hazirlar.
- Olasil helper adi `build_export_handover_qc_review_checklist(...)` olarak kaydedilir; bu adimda helper implementasyonu yapilmaz.
- Future helper structured input kullanmalidir: tercihen `build_export_result_report(...)` report dict'i veya `build_export_result_summary(...)` summary dict'i; formatter Markdown'u source of truth degil presentation text olarak kalmalidir.
- Output JSON-ready checklist dict, item listesi, gorunurluk status/priority etiketleri ve review note icerebilir; `approved`, `rejected`, `blocked`, `official_decision` veya `audit_event_id` gibi karar/bloklama alanlari olmamalidir.
- Future helper success-only, failure-only, mixed, empty/zero-count, missing optional field, unknown/additional field, input immutability, no side effect, no file write/export output, no database/repository, no audit event, no API/GUI/CLI ve no hard validation/no blocked regression testleriyle ayri adimda ele alinmalidir.
- Existing `build_export_result_summary(...)`, `build_export_result_report(...)`, `format_export_result_report_as_markdown(...)`, `write_*` ve `try_write_*` davranislari korunacaktir; hard validation sonraki ayri faza birakilir.

## 182 Export / Handover QC Checklist Boundary and Test Matrix Karari

- Adim 182, export / handover QC review checklist icin API boundary ve future test matrix'i documentation-only olarak netlestirir.
- Checklist read-only QC katmani olarak kalir; mevcut `build_export_result_summary(...)`, `build_export_result_report(...)` ve `format_export_result_report_as_markdown(report)` ciktilarini insan incelemesine tasiyabilir fakat bu helper davranislarini degistirmez.
- Checklist karar verici, otomatik onaylayici, otomatik bloklayici, hard validation, `blocked` status uretici, audit logger, database/repository mutator, backup/restore runner veya export writer degildir.
- Future helper yazilirsa input/output contract dar ve acik olacak; success-only, failure-only, mixed, empty/zero-count, missing optional field, unknown/additional field, input immutability, no file write/export output ve no hard validation/no blocked regression testleri ayri adimda ele alinacaktir.
- API/GUI/CLI entegrasyonlari, database/repository erisimi, audit event, backup/restore, export cikti dosyasi, helper implementation ve test ekleme bu adimda kapsam disidir.

## 181 Export / Handover QC Review Checklist Karari

- Adim 181, export result summary/report/formatter hattinin handover QC review checklist'e nasil baglanabilecegini documentation-only olarak planlar.
- Checklist mevcut `build_export_result_summary(...)`, `build_export_result_report(...)` ve `format_export_result_report_as_markdown(report)` ciktilarini insan incelemesine tasiyan read-only QC katmani olarak konumlandirilir.
- Checklist resmi kabul, resmi ret, otomatik bloklama, hard validation, `blocked` status, audit event, export generation, database/repository mutation veya backup/restore davranisi degildir.
- Success itemlar olumlu gorunurluk, failure/review itemlar insan incelemesi, mixed reportlar oncelikli review siralamasi, empty/missing/unknown field durumlari eksik gorunurluk sinyali olarak okunur.
- Yeni santiye sefi icin export-related success/review/path/error/next-action gorunurlugu planlanir; eski santiye sefinin ozel alani resmi handover/export paketinden ayridir.
- Future checklist helper, formatter, GUI/API/CLI veya exportable checklist dosyasi gerekiyorsa ayri adim, ayri test ve ayri dokumantasyonla ele alinmalidir.

## Podcast 029 Kapsam Karari

- Podcast 029, documentation-only NotebookLM podcast notu olarak yalniz Adim 167-180 araligini kapsar.
- Kapsam; export helper result contract wrapper integration boundary, summary/report layer plan ve implementation, usage ve edge case standardization, report formatter API boundary, read-only formatter implementation, formatter usage/test-example standardization, handover QC usage, downstream integration boundary ve Adim 180 phase closure hattidir.
- `format_export_result_report_as_markdown(report)` helper'i read-only presentation layer olarak anlatilir; dosya yazmaz, export uretmez, input mutate etmez, report sonucunu yeniden hesaplamaz ve handover karar otoritesi degildir.
- Adim 181, yeni teknik faz, hard validation, `blocked` status, API/GUI/CLI implementation, database/repository erisimi, audit event uretimi, backup/restore implementation ve export cikti dosyasi kapsam disidir.
- Bu podcast yeni helper, test, kod davranisi, commit, push veya ZIP/cache/export staging uretmez.

## 180 Export Result Report Formatter Phase Closure Karari

- Adim 180, Adim 175-179 export result report formatter fazini documentation-only olarak kapatir.
- `format_export_result_report_as_markdown(report)` helper'i `build_export_result_report(...)` ciktisini read-only presentation-safe Markdown'a ceviren yardimci olarak kalir.
- Helper dosya yazmaz, export uretmez, input'u mutate etmez, report sonucunu yeniden hesaplamaz, hard validation yapmaz ve `blocked` status uretmez.
- `build_export_result_summary(...)`, `build_export_result_report(...)`, `format_export_result_summary_as_markdown(...)`, `write_*` ve `try_write_*` helper davranislari korunur.
- Handover QC ve downstream entegrasyonlar formatter'i karar, validation, audit, persistence, backup/restore veya export writing katmani olarak kullanmamalidir.
- Adim 180 sonrasi yeni teknik adima baslanmayacak; ara sonrasi once mevcut Git/test durumu dogrulanacaktir.
- Olası sonraki isler yalniz aday olarak kaydedilir: Podcast 029 kapsam kontrolu, export/handover QC checklist plan, downstream consumer test plan ve hard validation oncesi soft/diagnostic sinir kontrolu.

## 179 Export Result Report Formatter Downstream Integration Boundary Karari

- Adim 179, `format_export_result_report_as_markdown(report)` helper'i icin downstream integration boundary'yi documentation-only olarak planlar.
- Future GUI/API/CLI, handover QC ekrani ve export review akislari formatter ciktisini yalniz read-only presentation layer olarak kullanabilir; bu adim entegrasyon eklemez.
- Downstream consumer'lar mevcut `build_export_result_report(...)` report dict contract'ina bagli kalmali ve formatter'a ham export writer veya validation gate gibi davranmamalidir.
- Presentation layer; business decision, hard validation, audit, persistence, export writing ve backup/restore katmanlarindan ayridir.
- Success gorunurlugu otomatik resmi kabul/onay anlamina gelmez; failure gorunurlugu otomatik bloklama anlamina gelmez.
- GUI/API/CLI eklenirse bu ayri adim, ayri test ve ayri dokumantasyonla yapilmalidir; hard validation ve `blocked` status kapsam disidir.

## 178 Export Result Report Formatter Handover QC Usage Karari

- Adim 178, `format_export_result_report_as_markdown(report)` helper'inin handover QC surecindeki rolunu documentation-only olarak planlar.
- Formatter ciktisi gorunurluk ve okunabilirlik saglar; devir paketini otomatik onaylamaz veya otomatik bloke etmez.
- Success-only rapor resmi kabul yerine gecmez; failure-only rapor insan incelemesine tasinir ama otomatik bloklama uretmez; mixed rapor hem basarili hem review gereken itemlari gorunur tutar.
- Empty, unknown ve missing field durumlari eksik gorunurluk olarak yorumlanir; hard validation veya `blocked` status'a donusturulmez.
- Eski santiye sefinin ozel alani resmi export/handover paketinden ayridir; formatter yalniz kendisine verilen report dict'ini sunuma cevirir.
- Future GUI/API/CLI entegrasyonlari bu formatter'i yalniz presentation layer olarak kullanmalidir; audit, database/repository, backup/restore, hard validation ve export uretimi kapsam disidir.

## 177 Export Result Report Formatter Test Example Standardization Karari

- Adim 177, `format_export_result_report_as_markdown(report)` helper'i icin test/example standardini guclendirir.
- Success-only, failure-only ve empty zero-count Markdown ornekleri stable presentation contract olarak test edilir.
- Missing optional field fallback ve additional/raw field sinirlari formatter'in presentation layer olarak kaldigini gostermek icin test edilir.
- `build_export_result_report(...)` contract regression testi, formatter test standardizasyonunun report builder davranisini degistirmedigini sabitler.
- Formatter davranisi genisletilmez; `app/models.py` degistirilmez.
- Dosya yazma, export ciktisi, hard validation, generated `blocked` status, API/GUI/CLI, database/repository erisimi, audit event ve backup/restore kapsam disidir.

## 176 Export Result Report Markdown Formatter Usage Karari

- Adim 176, `format_export_result_report_as_markdown(report)` helper'i icin usage boundary ve edge case standardini documentation-only olarak belirler.
- Helper'in input'u `build_export_result_report(...)` ciktisi olan dict, output'u presentation-safe Markdown string olarak okunur.
- Formatter yalnizca mevcut report dict'ini sunuma cevirir; kayit reddetmez, export basarisi/basarisizligini yeniden hesaplamaz, dosya sistemi yan etkisi olusturmaz ve input'u mutate etmez.
- Success-only, failure-only ve mixed report ciktilari handover/export QC icin gorunurluk saglar; karar verdiren otorite degildir.
- Empty item/count, missing field ve unknown field durumlari hard validation'a veya otomatik bloklamaya donusturulmez; formatter presentation layer sinirinda kalir.
- Summary/report/write helper davranislari, `try_write_*` wrapper davranisi, API/GUI/CLI, database/repository erisimi, audit event, backup/restore, hard validation ve `blocked` status kapsam disidir.

## 175 Export Result Report Markdown Formatter Implementation Karari

- Adim 175, `format_export_result_report_as_markdown(report)` helper'ini read-only presentation formatter olarak implemente eder.
- Helper yalniz `build_export_result_report(...)` ciktisi olan dict'i Markdown string'e cevirir; dosya yazmaz, export uretmez, database/repository erisimi yapmaz ve audit event uretmez.
- Helper summary/report sonucunu yeniden hesaplamaz, export wrapper veya builder helper cagirmadan mevcut report alanlarini okur ve input dict'i mutate etmez.
- Markdown cikti status, total/success/review/unknown count, success/failure gorunurlugu, path, error type, technical detail, next action ve overwrite bilgisini gorunur kilar.
- Hard validation, diagnostic/soft validation sonucu, `blocked` status, backup/restore, API/GUI/CLI ve export ciktisi kapsam disidir.
- Existing `build_export_result_report(...)`, `build_export_result_summary(...)`, `format_export_result_summary_as_markdown(...)`, low-level `write_*` helperlari ve `try_write_*` wrapper davranislari korunur.

## 174 Export Result Report Formatter API Boundary Karari

- Adim 174, future `format_export_result_report_as_markdown(report)` helper'i icin API boundary ve test matrix'i documentation-only olarak planlar.
- Planlanan helper yalniz `build_export_result_report(...)` ciktisi olan dict'i input olarak alip presentation-safe Markdown string dondurebilir; bu adimda implementasyon yapilmaz.
- Helper dosya yazmayacak, export uretmeyecek, database/repository erisimi yapmayacak, diagnostic veya soft validation sonucu uretmeyecek, summary/report sonucunu yeniden hesaplamayacak ve input dict'i mutate etmeyecek.
- Markdown cikti baslik, overall status, success/failure count, path gorunurlugu, error message gorunurlugu, result contract item listesi, human review note ve hard validation olmadigi bilgisini gosterebilir.
- Future test matrix empty report, all success, mixed success/failure, missing optional fields, unknown status, path visibility, error message visibility, input immutability, no recomputation, Markdown string output, no `blocked` status, no file writing, low-level `write_*` davranisini koruma ve `try_write_*` wrapper davranisini koruma basliklarini kapsayabilir.
- Hard validation, `blocked` status, backup/restore, database/repository, API/GUI/CLI, export cikti dosyasi, helper davranisi degisikligi, Podcast 029 ve ZIP/cache/export staging kapsam disidir.
- Onerilen sonraki adim Adim 175 - Read-only export result report markdown formatter implementation olarak kaydedildi; Adim 175 bu adimda baslatilmaz.

## 173 Export Result Summary/Report Follow-up Karari

- Adim 173, Adim 168-172 araliginda kurulan export result summary/report helper hatti sonrasi follow-up yonunu documentation-only olarak planlar.
- Mevcut `build_export_result_summary(...)`, `build_export_result_report(...)` ve `format_export_result_summary_as_markdown(...)` helper davranislari korunacak; bu adimda yeni helper, formatter, writer, API, GUI veya CLI eklenmeyecek.
- Olasil takip basliklari export result report Markdown formatter plani, JSON-ready formatter boundary, combined handover QC gorunumu, report test example standardization, unsupported input handling documentation ve result contract wrapper ile summary/report helper iliskisinin dokumantasyonudur.
- Summary/report helper katmani diagnostic engine veya validation gate degildir; export result gorunurluk ve ozet katmani olarak kalir.
- Low-level `write_*` helper davranisi ve `try_write_*` wrapper davranisi degistirilmeyecek.
- Hard validation, `blocked` status, backup/restore, database/repository, API/GUI/CLI, export cikti dosyasi, Podcast 029 ve ZIP/cache/export staging kapsam disidir.
- Onerilen sonraki adim Adim 174 - Export result report formatter API boundary / test matrix plan olarak kaydedildi; Adim 174 bu adimda baslatilmaz.

## Podcast 028 Kapsam Karari

- Podcast 028, documentation-only NotebookLM podcast notu olarak yalniz Adim 162-166 araligini kapsar.
- Kapsam; wrapper test matrix finalization, `try_write_*` result contract wrapper implementation, wrapper usage documentation, wrapper usage examples ve wrapper contract test implementation hattidir.
- Adim 167-172 bu podcast kapsaminda degildir; Adim 167 wrapper integration boundary, Adim 168-172 ise export result summary/report layer hattina ayrilir.
- Bu podcast yeni teknik karar, helper davranisi, kod, test, export cikti dosyasi, hard validation, `blocked` status, backup/restore, API, GUI, CLI, audit event, commit veya push uretmez.
- ZIP, backup ve cache dosyalari repo kapsamina alinmaz.

## 172 Export Result Summary/Report Edge Case Karari

- Export result summary/report helperlari edge case durumlarini hard validation'a cevirmeyecek.
- Empty contract, missing/unknown status, missing path/message/error/detail, unsupported input, empty report list, mixed report list, duplicate path ve non-string alanlar guvenli diagnostic veya review/attention ozetleri olarak yorumlanacak.
- Helperlar input'u mutate etmeyecek, dosya yazmayacak, export helper cagirmayacak ve low-level `write_*` helper davranisini degistirmeyecek.
- Missing field durumunda Markdown formatter kirik veya bos metin yerine guvenli fallback mesaj kullanacak sekilde yorumlanmalidir.
- Handover QC yorumunda unknown veya incomplete result contract attention gerektirebilir; fakat devir paketini otomatik bloke etmez, kayitlari gecersiz saymaz, migration veya otomatik duzeltme baslatmaz ve hard validation anlamina gelmez.
- Edge case standardi gelecekte test basliklarina kaynak olabilir; bu adimda test veya helper davranisi degistirilmez.

## 171 Export Result Summary/Report Usage Karari

- Adim 170 helperlari read-only yorumlama katmani olarak kullanilacak.
- `build_export_result_summary(...)` tek export result contract icin okunabilir summary uretir.
- `build_export_result_report(...)` birden fazla result contract icin toplu rapor uretir.
- `format_export_result_summary_as_markdown(...)` summary/report dict'ini okunabilir Markdown metnine cevirir.
- Bu helperlar dosya yazmaz, export helper cagirmaya baslamaz, path safety kararini yeniden hesaplamaz ve wrapper result contract'i degistirmez.
- Bu helperlar dusuk seviye `write_*` helperlarin yerine gecmez; sadece wrapper sonucunu handover QC, rapor veya admin/debug gorunurlugu icin yorumlar.
- Failure sonucu review/attention bilgisi olarak okunur; otomatik devir paketi bloklama, kayit gecersiz kilma, hard validation, `blocked` status, audit event, backup/restore, API, GUI, CLI veya database/repository davranisi uretilmez.

## 170 Export Result Summary/Report Helper Karari

- Export result summary/report katmani mevcut wrapper result contract dict'lerini okuyan read-only bir yorumlama katmani olarak eklendi.
- `build_export_result_summary(...)` tekil result contract'i `success`, `review` veya `unknown` durumlu JSON-ready ozet dict'e cevirir.
- `build_export_result_report(...)` result contract listesini toplu rapora cevirir ve sirayi korur.
- `format_export_result_summary_as_markdown(...)` summary veya report dict'ini Markdown metnine cevirir, fakat dosya yazmaz.
- Bu katman export helper cagirmayacak, path safety hesaplamasini tekrarlamayacak, low-level `write_*` helper davranisini degistirmeyecek ve wrapper result contract davranisini replace etmeyecek.
- Hata/uyari durumlari kullaniciya okunabilir mesaj olarak aktarilir; buna ragmen hard validation, `blocked` status, audit event, backup/restore, API, GUI, CLI veya otomasyon uretilmez.

## 001 Repo ve Calisma Anlasmalari

- Ilk adimda framework eklenmeyecek.
- Baslangic Python uygulamasi sade bir `main()` fonksiyonu ile kurulacak.
- Test araci olarak `pytest` kullanilacak.
- Proje dokumantasyonu Turkce tutulacak.
- Kod isimlendirmelerinde sade Ingilizce tercih edilecek.
- `data/` ve `exports/` klasorleri simdilik bos tutulacak, icerikleri genel olarak git disinda birakilacak.

## 002 Cekirdek Veri Modeli

- Cekirdek veri modelleri `dataclass` ile kurulacak.
- Veritabani bu asamada eklenmeyecek.
- JSON kayit sistemi bu asamada eklenmeyecek.
- Once veri sekli netlesecek.

## 003 Gunluk Saha Kaydi

- Gunluk saha kaydi `DailySiteLog` modeliyle temsil edilecek.
- Gunluk kayit once sadece veri modeli olarak kurulacak.
- Kalici kayit sistemi daha sonra ele alinacak.

## 004 Bellek Ici Basit Kayit Listeleme

- Listeleme ve filtreleme once bellek ici Python listeleriyle yapilacak.
- Veritabani, JSON ve dosya kayit sistemi eklenmeyecek.
- Ana fonksiyon isimleri:
  - `list_records`
  - `count_records`
  - `filter_records_by_project_id`
  - `filter_records_by_status`
- `list_records_by_project` fonksiyonu geriye uyumluluk icin gecici olarak birakildi.
- Ana dokumantasyon ve testlerde tercih edilen isim `filter_records_by_project_id` olacak.
- Ileride sade API yuzeyi icin `list_records_by_project` kaldirilabilir veya deprecated olarak isaretlenebilir.

## Learning Standardi

- `learning/` klasoru sadece kisa not degil, yazilim ogrenim arsividir.
- Learning dosyalari gercek kod bloklari uzerinden aciklanir.
- Test kodlari da aciklanir.
- Yeni terimler learning dosyasinda ve `learning/GLOSSARY.md` icinde tanimlanir.
- "Sunu yaptik / Boyle yaptik / Cunku / Boylece" anlatim yapisi korunur.

## Git Karari

- Git commit islemi bu gorevde yapilmayacak.
- Ancak repo ilk uygun stabil noktada commitlenmelidir.
- Su an Adim 001-004 tamamlandigi icin ilk commit icin uygun aday olusmustur.

## 005 Beton Dokum ve Numune Takip Baslangici

- Beton dokum ve beton numune takibi once veri modeli olarak kurulacak.
- EBIS entegrasyonu bu asamada yapilmayacak.
- Veritabani ve JSON kayit sistemi bu asamada yapilmayacak.
- `ConcretePour` ve `ConcreteSample` modelleri ileride beton takip modulunun temelini olusturacak.
- 7 gunluk ve 28 gunluk test sonuclari simdilik opsiyonel alan olarak tutulacak.

## 006 Yapi Denetim Kontrol Cagrilari

- Yapi denetim kontrol cagrilari once veri modeli olarak kurulacak.
- EBIS entegrasyonu bu asamada yapilmayacak.
- Bildirim veya takvim sistemi bu asamada yapilmayacak.
- `InspectionRequest` modeli, yapi denetim sureclerinin takip edilmesi icin temel model olacak.
- `related_pour_id` alani, ileride beton dokum kaydiyla kontrol cagrisi arasinda baglanti kurmak icin opsiyonel tutulacak.

## 007 Uygunsuzluk Kayitlari

- Uygunsuzluk kayitlari once veri modeli olarak kurulacak.
- Fotograf/dosya yukleme bu asamada yapilmayacak.
- Tutanak, PDF veya resmi yazisma uretimi bu asamada yapilmayacak.
- Veritabani ve JSON kayit sistemi bu asamada yapilmayacak.
- `NonconformityRecord` modeli, uygunsuzluklarin takip edilmesi icin temel model olacak.
- `related_inspection_request_id` alani ileride yapi denetim kontrol cagrisiyla iliski kurmak icin opsiyonel tutulacak.
- `related_pour_id` alani ileride beton dokum kaydiyla iliski kurmak icin opsiyonel tutulacak.
- `severity` ve `status` alanlari bu asamada serbest metin olarak tutulacak; enum sistemi ileride degerlendirilecek.

## 008 Dosya/Ek Arsivleme Baslangici

- Dosya/ek arsivleme once referans modeli olarak kurulacak.
- Gercek dosya kopyalama, tasima, silme veya yukleme bu asamada yapilmayacak.
- Veritabani ve JSON kayit sistemi bu asamada yapilmayacak.
- `AttachmentRecord` modeli, ileride dosya arsivleme modulunun temelini olusturacak.
- `related_model` ve `related_id` alanlari, dosya eklerinin farkli kayit tipleriyle iliskilendirilmesi icin opsiyonel tutulacak.
- `file_path` alani simdilik sadece metinsel yol referansi olarak tutulacak.

## 009 Malzeme Giris/Kullanim Kaydi Baslangici

- Malzeme takibi once veri modeli olarak baslatildi.
- Gercek stok hareketi sistemi kurulmadi.
- Malzeme giris/kullanim ayrimi simdilik `received_date`, `used_date` ve `status` alanlariyla temsil edildi.
- Irsaliye/fotograf gibi kanitlar ileride `AttachmentRecord` ile baglanabilir.
- Veritabani, JSON, API ve GUI daha sonraki adimlara birakildi.

## 010 Toplanti Tutanagi ve Aksiyon Kaydi Baslangici

- Toplanti ve aksiyon takibi once veri modeli olarak baslatildi.
- Tutanaktan otomatik gorev uretme bu adimda yapilmadi.
- Toplanti ile aksiyon arasinda kod seviyesinde iliski kurulmadi.
- Katilimcilar, gundem ve kararlar simdilik metinsel alan olarak tutuldu.
- Veritabani, JSON, API, GUI, takvim ve bildirim sistemi sonraya birakildi.
- Aksiyonlarin ileride issue/task/punch list moduluyla baglanabilecegi kaydedildi.

## 011 RFI / Submittal Lite Kaydi Baslangici

- RFI/Submittal takibi once veri modeli olarak baslatildi.
- Gercek onay akisi, retur/revizyon ve e-posta/bildirim sureci bu adimda kurulmadi.
- RFI ve Submittal kayitlari baska modellere kod seviyesinde baglanmadi.
- Teknik soru/cevap ve teknik gonderim/onay kavramlari ayri modeller olarak tutuldu.
- Veritabani, JSON, API, GUI, dosya eki ve raporlama daha sonraki adimlara birakildi.
- Ileride `AttachmentRecord` ve `MaterialRecord` ile baglanti kurulabilecegi kaydedildi.

## 012 Gunluk Rapor Ozet Modeli Baslangici

- Gunluk rapor takibi once veri modeli olarak baslatildi.
- Gercek PDF/Excel rapor uretimi bu adimda yapilmadi.
- Hava durumu yalnizca metinsel alan olarak tutuldu; API entegrasyonu yapilmadi.
- Gunluk is, iscilik, ekipman, malzeme, sorun ve is guvenligi ozetleri ayri metinsel alanlar olarak tutuldu.
- Diger modellerle kod seviyesinde iliski kurulmadı.
- Veritabani, JSON, API, GUI, dosya eki ve raporlama daha sonraki adimlara birakildi.

## 013 Proje Tarafi ve Kisi Kaydi Baslangici

- Proje tarafi ve iletisim kisisi takibi once veri modeli olarak baslatildi.
- Gercek rehber/CRM sistemi kurulmadi.
- Firma/kurum tarafi ile kisi kaydi ayri modeller olarak tutuldu.
- Bu iki model arasinda kod seviyesinde iliski kurulmadı.
- Telefon, e-posta ve vergi/kimlik numarasi dogrulamasi yapilmadi.
- Veritabani, JSON, API, GUI, arama/filtreleme ve raporlama sonraya birakildi.
- Ileride bu kayitlarin toplanti, aksiyon, RFI, submittal, malzeme ve gunluk rapor kayitlariyla baglanabilecegi kaydedildi.

## 014 Santiye Lokasyon / Mahal Kaydi Baslangici

- Santiye lokasyon/mahal takibi once veri modeli olarak baslatildi.
- Gercek lokasyon yonetim sistemi kurulmadı.
- Kat plani, harita, mahal hiyerarsisi ve arama/filtreleme bu adimda yapilmadi.
- Blok, kat, bolge, aks ve disiplin bilgileri ayri metinsel alanlar olarak tutuldu.
- Diger modellerle kod seviyesinde iliski kurulmadı.
- Veritabani, JSON, API, GUI ve raporlama sonraya birakildi.
- Ileride bu modelin kontrol, uygunsuzluk, gunluk rapor, malzeme ve ek/fotograf kayitlariyla baglanabilecegi kaydedildi.

## 015 Ekip / Iscilik Kaydi Baslangici

- Ekip/iscilik takibi once veri modeli olarak baslatildi.
- Gercek puantaj, bordro, vardiya ve performans sistemi kurulmadi.
- Ekip adi, ekip turu, firma, kisi sayisi, calisma alani ve calisma tarihi ayri alanlar olarak tutuldu.
- Diger modellerle kod seviyesinde iliski kurulmadi.
- Veritabani, JSON, API, GUI, arama/filtreleme ve raporlama sonraya birakildi.
- Ileride bu modelin gunluk rapor, lokasyon, taseron/proje tarafi ve saha ilerleme kayitlariyla baglanabilecegi kaydedildi.

## 016 Ekipman / Makine Kaydi Baslangici

- Ekipman/makine takibi once veri modeli olarak baslatildi.
- Gercek bakim, yakit, zimmet, gunluk calisma saati, operator performansi ve makine verimlilik sistemi kurulmadi.
- Ekipman adi, ekipman turu, sahip firma, seri/plaka bilgisi, calisma alani ve sorumlu kisi/ekip ayri alanlar olarak tutuldu.
- Diger modellerle kod seviyesinde iliski kurulmadi.
- Veritabani, JSON, API, GUI, arama/filtreleme ve raporlama sonraya birakildi.
- Ileride bu modelin gunluk rapor, lokasyon, ekip/iscilik, bakim ve saha ilerleme kayitlariyla baglanabilecegi kaydedildi.

## 017 Tedarikci Kaydi Baslangici

- Onceki malzeme kaydi onerisi, `MaterialRecord` zaten mevcut oldugu icin tedarikci/firma kaydi olarak revize edildi.
- Tedarikci, hizmet saglayici, ekipman kiralama firmasi ve taseron gibi firmalar once veri modeli olarak baslatildi.
- Gercek satin alma, sozlesme, fatura, irsaliye, odeme, cari hesap ve tedarikci performans sistemi kurulmadi.
- Tedarikci adi, tedarikci turu, iletisim kisisi, telefon, e-posta ve hizmet alani ayri alanlar olarak tutuldu.
- Diger modellerle kod seviyesinde iliski kurulmadi.
- Veritabani, JSON, API, GUI, arama/filtreleme ve raporlama sonraya birakildi.

## 018 Saha Notu Kaydi Baslangici

- Onceki iletisim kisisi onerisi, `ContactPersonRecord` zaten mevcut oldugu icin saha notu kaydi olarak revize edildi.
- Saha notlari, gozlemler, uyarilar, hatirlatmalar ve serbest aciklamalar once veri modeli olarak baslatildi.
- Gercek gorev yonetimi, hatirlatici, bildirim, gunluk rapor, denetim, uygunsuzluk, fotograf/dosya eki, takvim, kisi atama ve oncelik sistemi kurulmadi.
- Not basligi, not turu, konum, ilgili konu ve not tarihi ayri alanlar olarak tutuldu.
- Diger modellerle kod seviyesinde iliski kurulmadi.
- Veritabani, JSON, API, GUI, arama/filtreleme ve raporlama sonraya birakildi.

## 019 Gorev Adayi Kaydi Baslangici

- Goreve donusebilecek kucuk aksiyon adaylari once veri modeli olarak baslatildi.
- Gercek gorev yonetimi, hatirlatici, bildirim, takvim, kisi atama, oncelik, is emri ve tamamlandi/ertelendi is akisi kurulmadi.
- Gorev basligi, gorev turu, ilgili alan, kaynak ve hedef tarih ayri alanlar olarak tutuldu.
- Saha notu veya gunluk raporla kod seviyesinde iliski kurulmadi.
- Veritabani, JSON, API, GUI, arama/filtreleme ve raporlama sonraya birakildi.

## 020 Kontrol Maddesi Kaydi Baslangici

- `ChecklistItem` mevcut oldugu icin `ChecklistItemRecord` ayri ve daha spesifik kayit modeli olarak baslatildi.
- Tekil kontrol maddeleri once veri modeli olarak baslatildi.
- Gercek checklist sistemi, denetim formu, uygunsuzluk kaydi, puanlama, onay is akisi, fotograf/dosya eki ve raporlama sistemi kurulmadi.
- Kontrol maddesi basligi, kategori, ilgili alan ve kontrol referansi ayri alanlar olarak tutuldu.
- Saha notu, gorev veya gunluk raporla kod seviyesinde iliski kurulmadi.
- Veritabani, JSON, API, GUI, arama/filtreleme ve raporlama sonraya birakildi.

## 021 Kontrol Sonucu Kaydi Baslangici

- Yapilan kontrollerin basit sonuc bilgisi once veri modeli olarak baslatildi.
- Gercek checklist sistemi, denetim formu, uygunsuzluk kaydi, puanlama, onay is akisi, fotograf/dosya eki ve raporlama sistemi kurulmadi.
- Kontrol basligi, kontrol alani, sonuc, kontrol eden kisi ve kontrol tarihi ayri alanlar olarak tutuldu.
- Kontrol maddesi, saha notu, gorev veya gunluk raporla kod seviyesinde iliski kurulmadi.
- Veritabani, JSON, API, GUI, arama/filtreleme ve raporlama sonraya birakildi.

## 022 Uygunsuzluk Adayi Kaydi Baslangici

- Uygunsuzluk kaydina donusebilecek gozlem, eksik, hata, risk veya kontrol sonucu notlari once veri modeli olarak baslatildi.
- Gercek uygunsuzluk yonetimi, NCR sureci, duzeltici faaliyet, sorumlu atama, termin takibi, onay/kapatma is akisi, fotograf/dosya eki ve raporlama sistemi kurulmadi.
- Aday basligi, aday turu, konum, gozlenen sorun, tespit eden kisi ve tespit tarihi ayri alanlar olarak tutuldu.
- Kontrol sonucu, saha notu, gorev veya gunluk raporla kod seviyesinde iliski kurulmadi.
- Veritabani, JSON, API, GUI, arama/filtreleme ve raporlama sonraya birakildi.

## 023 Uygunsuzluk Adayi Degerlendirme Kaydi Baslangici

- Uygunsuzluk adayi dogrudan kesin uygunsuzluk olarak kabul edilmeyecek.
- Once degerlendirme kaydi ile incelenecek.
- Bu sayede sahada gorulen her sorun ile resmi uygunsuzluk ayrimi korunacak.
- Degerlendiren kisi, degerlendirme tarihi, sonuc, karar gerekcesi ve sonraki aksiyon ayri alanlar olarak tutuldu.
- Kesin uygunsuzluk kaydi olusturulmadi.
- Duzeltici faaliyet sistemi kurulmadı.
- Veritabani, JSON, API, GUI ve dosya islemi eklenmedi.

## 024 Uygunsuzluk Adayi Aksiyon Kaydi Baslangici

- Uygunsuzluk adayi degerlendirildikten sonra alinan ilk aksiyon karari ayri bir veri modeliyle tutulacak.
- Bu aksiyon kaydi, kesin uygunsuzluk veya duzeltici faaliyet sistemi degildir.
- Amac, sahada fark edilen aday sorunlarin degerlendirme sonrasi ne yapilacagina dair ilk karar bilgisini guvenli ve kucuk bir modelle temsil etmektir.
- Aday basligi, degerlendirme sonucu, aksiyon karari, aksiyon sorumlusu, hedef tarih ve aksiyon aciklamasi ayri alanlar olarak tutuldu.
- Kesin uygunsuzluk kaydi olusturulmadi.
- Duzeltici faaliyet sistemi kurulmadı.
- Gorev atama / sorumluluk takip akisi kurulmadı.
- Veritabani, JSON, API, GUI ve dosya islemi eklenmedi.

## 025 Uygunsuzluk Adayi Takip Durumu Ozeti Baslangici

- Uygunsuzluk adayi surecinin mevcut durumu ayri bir takip ozeti modeliyle temsil edilecek.
- Bu model gercek bir is akisi motoru degildir.
- Amac; aday kayit, degerlendirme ve aksiyon kararindan sonra surecin sahada hangi durumda oldugunu veri seviyesinde ozetlemektir.
- Aday basligi, degerlendirme sonucu, aksiyon karari, aksiyon sorumlusu, takip durumu, son guncelleme tarihi ve ozet not ayri alanlar olarak tutuldu.
- Kesin uygunsuzluk kaydi olusturulmadi.
- Duzeltici faaliyet sistemi kurulmadı.
- Gorev atama / sorumluluk takip akisi kurulmadı.
- Otomatik durum guncelleme sistemi kurulmadı.
- Veritabani, JSON, API, GUI ve dosya islemi eklenmedi.

## 026 AttachmentRecord ile Uygunsuzluk Adayi Ek Dosya Baglantisi

- Uygunsuzluk adayi icin ayri `NonconformityCandidateAttachment` modeli olusturulmadi.
- Bunun yerine mevcut genel `AttachmentRecord` kullanilacak.
- Gerekce: Ek dosya mantigi bircok kayit tipiyle ortak oldugu icin tekrar eden ozel modellerden kacinildi.
- Uygunsuzluk adayi ekleri icin `related_model` degeri `NonconformityCandidateRecord` olarak tutulacak.
- Ilgili aday kayit kodu `related_id` alaninda tutulacak.
- Gercek dosya yukleme, kopyalama, silme veya tasima islemi bu adimda eklenmedi.
- Veritabani, JSON, API ve GUI eklenmedi.

## 027 Uygunsuzluk Adayi Surec Zinciri Gorunum Modeli Baslangici

- Uygunsuzluk adayi surec parcalari tek ozet gorunum modelinde temsil edilecek.
- `NonconformityCandidateProcessViewRecord`, kontrol sonucu, aday kaydi, degerlendirme, aksiyon, takip ozeti ve ek dosya sayisini bir arada okuma amaciyla eklendi.
- Bu model veritabani sorgusu veya otomatik join mekanizmasi degildir.
- Baglanti alanlari simdilik metinsel ID alanlari olarak tutulacak.
- `attachment_count` ek dosya sayisini temsil edecek, gercek dosya sayma islemi yapmayacak.
- Veritabani, JSON, API, GUI ve otomatik raporlama eklenmedi.

## 028 Uygunsuzluk Adayi Durum Gecmisi Modeli Baslangici

- Uygunsuzluk adayi durum degisiklikleri ayri bir gecmis kaydi modeliyle temsil edilecek.
- `NonconformityCandidateStatusHistoryRecord`, eski durum, yeni durum, degisiklik sebebi, degistiren kisi ve degisiklik tarihini tutacak.
- `source_record` alani durum degisikliginin hangi kayit veya surec parcasindan kaynaklandigini metinsel olarak gosterecek.
- Bu model otomatik durum guncelleme sistemi veya is akisi motoru degildir.
- Veritabani, JSON, API, GUI, otomatik raporlama ve dosya islemi eklenmedi.

## 029 Uygunsuzluk Adayi Sorumluluk / Atama Modeli Baslangici

- Uygunsuzluk adayi sorumluluk ve atama bilgisi ayri bir veri modeliyle temsil edilecek.
- `NonconformityCandidateAssignmentRecord`, aday kaydin kime atandigini, kim tarafindan atandigini, atama tarihini, hedef tarihi, sorumluluk notunu ve onceligi tutacak.
- Bu model otomatik gorev atama, bildirim veya is emri sistemi degildir.
- `priority` alani bu adimda serbest metin olarak tutulacak ve varsayilan degeri `normal` olacak.
- `status` alani varsayilan olarak `assigned` olacak.
- Veritabani, JSON, API, GUI, otomatik bildirim ve dosya islemi eklenmedi.

## 030 Uygunsuzluk Adayi Kapanis / Sonuc Modeli Baslangici

- Uygunsuzluk adayi kapanis ve sonuc bilgisi ayri bir veri modeliyle temsil edilecek.
- `NonconformityCandidateClosureRecord`, kapanis karari, kapanis gerekcesi, kapatan kisi, kapanis tarihi, nihai durum, sonuc notu ve takip gerekliligi bilgisini tutacak.
- Bu model otomatik kapatma, otomatik durum guncelleme veya kesin uygunsuzluk/NCR olusturma sistemi degildir.
- `requires_follow_up` alani varsayilan olarak `False` olacak.
- Veritabani, JSON, API, GUI, otomatik raporlama ve dosya islemi eklenmedi.

## 031 NotebookLM Podcast Notu - Adim 026-030

- Adim 026-030 araligi icin final NotebookLM podcast notu hazirlandi.
- Podcast notu, uygunsuzluk adayinin kanit baglantisi, surec gorunumu, durum gecmisi, sorumluluk atamasi ve kapanis sonucuyla takip edilebilir bir saha surecine donusmesini ozetler.
- Bu adimda yeni model, test modeli, veritabani, JSON, API, GUI veya dosya islemi eklenmedi.

## 032 Uygunsuzluk Adayindan Kesin Uygunsuzluga Donusum Modeli Baslangici

- `NonconformityRecord` modeli zaten Adim 007'de mevcut oldugu icin Adim 032'de yeniden olusturulmadi.
- Aday kayit ile kesin uygunsuzluk kaydi arasindaki donusum ayri `NonconformityCandidateConversionRecord` modeliyle temsil edilecek.
- Bu model aday kaydin hangi NCR kaydina, kim tarafindan, ne zaman ve hangi gerekceyle donusturuldugunu tutacak.
- Bu adim otomatik NCR olusturma, otomatik donusum, duzeltici faaliyet sistemi veya onay akisi degildir.
- Veritabani, JSON, API, GUI ve dosya islemi eklenmedi.

## 033 NonconformityRecord Model Degerlendirme Raporu

- Bu adim sadece degerlendirme ve revizyon karar hazirligi olarak yapildi.
- `NonconformityRecord` modeli degistirilmedi.
- Yeni model veya test modeli eklenmedi.
- Mevcut modelin Adim 021-032 uygunsuzluk adayi ve donusum zinciriyle iliskisi raporlandi.
- Olası revizyon alanlari karar raporunda listelendi; revizyon daha sonraki ayri bir adima birakildi.

## 034 NonconformityRecord Alan Revizyonu

- Mevcut `NonconformityRecord` modeli kontrollu sekilde revize edildi.
- `nonconformity_type`, `detected_by`, `detection_date` ve `final_status` alanlari eklendi.
- `source_candidate_id` ve `conversion_record_id` alanlari bilincli olarak eklenmedi.
- Gerekce: Aday kayit ile kesin uygunsuzluk kaydi arasindaki baglanti `NonconformityCandidateConversionRecord` ile temsil ediliyor.
- Bu adimda yeni model, veritabani, JSON, API, GUI, otomatik NCR olusturma, otomatik donusum, duzeltici faaliyet sistemi, onay akisi veya dosya islemi eklenmedi.

## 035 Kesin Uygunsuzluk Surec Gorunum Modeli Baslangici

- Kesin uygunsuzluk / NCR surecini tek bakista gostermek icin `NonconformityProcessViewRecord` modeli eklendi.
- `source_candidate_id` ve `conversion_record_id` alanlari bu modelde sadece gorunum ve ozet amaciyla kullanilacak.
- Asil adaydan NCR'a donusum iliskisi `NonconformityCandidateConversionRecord` ile temsil edilmeye devam edecek.
- Bu model veritabani sorgusu, API cevabi, GUI tablosu, otomatik NCR olusturma veya duzeltici faaliyet sistemi degildir.
- Veritabani, JSON, API, GUI, otomatik donusum, onay akisi ve dosya islemi eklenmedi.

## 036 Kesin Uygunsuzluk Durum Gecmisi Modeli Baslangici

- Kesin uygunsuzluk / NCR durum degisiklikleri ayri bir gecmis kaydi modeliyle temsil edilecek.
- `NonconformityStatusHistoryRecord`, eski durum, yeni durum, degisiklik sebebi, degistiren kisi ve degisiklik tarihini tutacak.
- `source_record` alani durum degisikliginin hangi NCR kaydi veya surec parcasindan kaynaklandigini metinsel olarak gosterecek.
- Bu model otomatik durum guncelleme sistemi, is akisi motoru veya duzeltici faaliyet sistemi degildir.
- Veritabani, JSON, API, GUI, otomatik NCR olusturma, onay akisi ve dosya islemi eklenmedi.

## 037 Kesin Uygunsuzluk Sorumluluk / Atama Modeli Baslangici

- Kesin uygunsuzluk / NCR sorumluluk atamasi ayri bir veri modeliyle temsil edilecek.
- `NonconformityAssignmentRecord`, NCR kaydinin hangi kisi, ekip, firma veya sorumlu birime atandigini tutacak.
- Aday uygunsuzluk atama modeli olan `NonconformityCandidateAssignmentRecord` degistirilmedi; bu adim kesin uygunsuzluk kapsamindadir.
- `status` alani varsayilan olarak `assigned`, `notes` alani varsayilan olarak `None` olacak.
- Bu model API, GUI, otomatik atama, bildirim, onay akisi veya dosya islemi degildir.

## 038 Kesin Uygunsuzluk Duzeltici Faaliyet Modeli Baslangici

- Kesin uygunsuzluk / NCR icin planlanan duzeltici faaliyet ayri bir veri modeliyle temsil edilecek.
- `NonconformityCorrectiveActionRecord`, faaliyet basligi, aciklamasi, sorumlusu, planlanan baslangic tarihi, hedef tarihi ve tamamlanma tarihini tutacak.
- Mevcut `NonconformityRecord.corrective_action` alani degistirilmedi; bu adim daha ayrintili ve izole faaliyet kaydi seklini baslatir.
- `verification_required` varsayilan olarak `True`, `status` varsayilan olarak `planned`, `completion_date` ve `notes` varsayilan olarak `None` olacak.
- Bu model API, GUI, otomatik kapatma, onay akisi, bildirim veya dosya islemi degildir.

## 039 Kesin Uygunsuzluk Duzeltici Faaliyet Dogrulama Modeli Baslangici

- Kesin uygunsuzluk / NCR duzeltici faaliyetinin kontrol ve dogrulama sonucu ayri bir veri modeliyle temsil edilecek.
- `NonconformityCorrectiveActionVerificationRecord`, faaliyetin kim tarafindan, hangi tarihte, hangi sonuc ve notla dogrulandigini tutacak.
- `NonconformityCorrectiveActionRecord` faaliyetin kendisini; bu yeni model ise faaliyetin kontrol sonucunu temsil eder.
- `requires_rework` varsayilan olarak `False`, `next_action` varsayilan olarak `None`, `status` varsayilan olarak `verified`, `notes` varsayilan olarak `None` olacak.
- Bu model API, GUI, otomatik kapatma, otomatik onay, bildirim veya dosya islemi degildir.

## 040 Kesin Uygunsuzluk Kapatma Modeli Baslangici

- Kesin uygunsuzluk / NCR kapanis karari ayri bir veri modeliyle temsil edilecek.
- `NonconformityClosureRecord`, kapanis tarihini, kapatan kisiyi, kapanis sonucunu, kapanis gerekcesini ve dogrulanmis faaliyet baglantisini tutacak.
- `NonconformityCorrectiveActionVerificationRecord` duzeltici faaliyetin sahada uygun bulunup bulunmadigini; bu yeni model ise NCR kaydinin kapanis kararini temsil eder.
- `final_status` varsayilan olarak `closed`, `requires_follow_up` varsayilan olarak `False`, `follow_up_note` ve `notes` varsayilan olarak `None` olacak.
- Bu model API, GUI, otomatik kapatma, otomatik onay, bildirim veya dosya islemi degildir.

## 041 Kesin Uygunsuzluk Kayit Deposu Baslangici

- `NonconformityRecord` kayitlarini bellek icinde yonetmek icin `NonconformityRepository` sinifi eklendi.
- Repository sadece `NonconformityRecord` icin calisacak; genel kayit deposu veya kalici saklama katmani degildir.
- `add`, `list_all` ve `find_by_id` davranislari baslangic kapsaminda tutuldu.
- Var olmayan `nonconformity_id` aramalarinda `None` dondurulecek.
- JSON, SQLite, API, GUI, CLI, dosya islemi ve otomatik is akisi eklenmedi.

## 042 NonconformityRepository Duplicate Id Kontrolu

- `NonconformityRepository.add` davranisina ayni `nonconformity_id` degerine sahip ikinci kaydi engelleyen kontrol eklendi.
- Ayni kimlik tekrar eklenirse acik mesajli `ValueError` yukseltilecek.
- Farkli `nonconformity_id` degerlerine sahip kayitlar normal sekilde eklenmeye devam edecek.
- Bu karar veritabani unique constraint degil, bellek ici Python kontroludur.
- JSON, SQLite, API, GUI, CLI, dosya islemi ve otomatik is akisi eklenmedi.

## 043 NonconformityRepository Durum Filtreleme

- `NonconformityRepository` icine `list_by_status(status)` davranisi eklendi.
- Bu davranis sadece bellek icindeki `NonconformityRecord.status` alanina gore filtreleme yapacak.
- Eslesen kayitlar mevcut eklenme sirasini koruyarak liste olarak dondurulecek.
- Eslesen kayit yoksa bos liste dondurulecek.
- JSON, SQLite, API, GUI, CLI, dosya islemi, dashboard ve otomatik is akisi eklenmedi.

## 044 NonconformityRepository Sorumlu Filtreleme

- `NonconformityRepository` icine `list_by_responsible_party(responsible_party)` davranisi eklendi.
- Bu davranis sadece bellek icindeki `NonconformityRecord.responsible_party` alanina gore filtreleme yapacak.
- Eslesen kayitlar mevcut eklenme sirasini koruyarak liste olarak dondurulecek.
- Eslesen kayit yoksa bos liste dondurulecek.
- JSON, SQLite, API, GUI, CLI, dosya islemi, dashboard ve otomatik is akisi eklenmedi.

## 045 NonconformityRepository Durum Ozeti

- `NonconformityRepository` icine `get_status_summary()` davranisi eklendi.
- Bu davranis repository icindeki `NonconformityRecord.status` degerlerini bellek icinde sayacak.
- Sonuc `dict[str, int]` olarak dondurulecek; ornegin `{"open": 2, "closed": 1}`.
- Repository bos ise bos dict dondurulecek.
- JSON, SQLite, API, GUI, CLI, dashboard, dosya islemi ve otomatik is akisi eklenmedi.

## 046 NonconformityRepository Sorumlu Taraf Ozeti

- `NonconformityRepository` icine `get_responsible_party_summary()` davranisi eklendi.
- Bu davranis repository icindeki `NonconformityRecord.responsible_party` degerlerini bellek icinde sayacak.
- `responsible_party` degeri `None` olan kayitlar `unassigned` anahtari altinda sayilacak.
- Repository bos ise bos dict dondurulecek.
- JSON, SQLite, API, GUI, CLI, dashboard, dosya islemi ve otomatik is akisi eklenmedi.

## 047 NonconformityRepository Genel Ozet

- `NonconformityRepository` icine `get_overview_summary()` davranisi eklendi.
- Bu davranis toplam, acik, kapali, atanmis ve atanmamis kayit sayilarini bellek icinde hesaplayacak.
- Bos repository icin tum sayaclar `0` olacak sekilde sabit anahtarli dict dondurulecek.
- Bu davranis dashboard degil, dashboard/rapor/AI soru-cevap icin veri hazirlayan bellek ici Python metodudur.
- JSON, SQLite, API, GUI, CLI, dashboard, dosya islemi ve otomatik is akisi eklenmedi.

## 048 NonconformityRepository Status Guncelleme

- `NonconformityRepository` icine `update_status(nonconformity_id, new_status)` davranisi eklendi.
- Mevcut kayit bulunursa `status` alani bellek icinde guncellenecek ve guncellenen kayit dondurulecek.
- Kayit bulunamazsa `None` dondurulecek.
- Bu davranis otomatik `NonconformityStatusHistoryRecord` olusturmayacak.
- JSON, SQLite, API, GUI, CLI, dashboard, dosya islemi ve otomatik is akisi eklenmedi.

## 049 NonconformityRepository Sorumlu Taraf Guncelleme

- `NonconformityRepository` icine `update_responsible_party(nonconformity_id, responsible_party)` davranisi eklendi.
- Mevcut kayit bulunursa `responsible_party` alani bellek icinde guncellenecek ve guncellenen kayit dondurulecek.
- `responsible_party` degeri `str` veya `None` olabilir; `None` degeri ozetlerde `unassigned` olarak yorumlanmaya devam edecek.
- Kayit bulunamazsa `None` dondurulecek.
- Bu davranis otomatik `NonconformityAssignmentRecord` olusturmayacak.
- JSON, SQLite, API, GUI, CLI, dashboard, dosya islemi ve otomatik is akisi eklenmedi.

## 050 NonconformityRepository Kayit Var Mi Kontrolu

- `NonconformityRepository` icine `exists(nonconformity_id)` davranisi eklendi.
- Bu davranis verilen `nonconformity_id` degerine sahip kayit varsa `True`, yoksa `False` dondurecek.
- Varlik kontrolu `find_by_id` davranisini bozmayacak ve mevcut kayitlari degistirmeyecek.
- Bu davranis JSON veya SQLite sorgusu degil, bellek ici Python kontroludur.
- Silme, arsivleme, API, GUI, CLI, dashboard, dosya islemi ve otomatik is akisi eklenmedi.

## 051 NonconformityRepository Kayit Sayisi

- `NonconformityRepository` icine `count()` davranisi eklendi.
- `count()` repository icindeki toplam `NonconformityRecord` sayisini int olarak dondurecek.
- `NonconformityRepository` icine `count_by_status(status)` davranisi eklendi.
- `count_by_status(status)` verilen durum degerine sahip kayit sayisini int olarak dondurecek; eslesme yoksa `0` dondurecek.
- Bu davranislar mevcut kayitlari degistirmeyecek ve `list_by_status` davranisini bozmayacak.
- JSON, SQLite, API, GUI, CLI, dashboard, dosya islemi, silme, arsivleme ve otomatik is akisi eklenmedi.

## 052 NonconformityRecord Arsiv Alani

- `NonconformityRecord` icine `is_archived: bool = False` alani eklendi.
- Varsayilan deger `False` olarak belirlendi; yeni NCR kayitlari aktif/arsivlenmemis kabul edilecek.
- `is_archived=True` verilerek kaydin arsivlenmis olarak temsil edilebilmesi saglandi.
- Bu adimda repository archive/restore davranisi, otomatik arsivleme, silme veya filtreleme eklenmedi.
- JSON, SQLite, API, GUI, CLI, dashboard, dosya islemi ve otomatik is akisi eklenmedi.

## 053 NonconformityRepository Aktif / Arsiv Filtreleme

- `NonconformityRepository` icine `list_active()` davranisi eklendi.
- `list_active()` `is_archived == False` olan kayitlari mevcut eklenme sirasiyla liste olarak dondurecek.
- `NonconformityRepository` icine `list_archived()` davranisi eklendi.
- `list_archived()` `is_archived == True` olan kayitlari mevcut eklenme sirasiyla liste olarak dondurecek.
- Eslesen kayit yoksa bos liste dondurulecek ve mevcut kayitlar degistirilmeyecek.
- NonconformityRecord modeli, JSON, SQLite, API, GUI, CLI, dashboard, dosya islemi, silme, otomatik arsivleme, restore ve otomatik is akisi eklenmedi.

## 054 NonconformityRepository Arsivleme

- `NonconformityRepository` icine `archive(nonconformity_id)` davranisi eklendi.
- Mevcut kayit bulunursa `is_archived` alani bellek icinde `True` yapilacak ve guncellenen kayit dondurulecek.
- Kayit bulunamazsa `None` dondurulecek.
- Bu davranis kaydi silmeyecek, mevcut kayit sirasini degistirmeyecek ve `status` alanina dokunmayacak.
- Restore, otomatik kapanis, otomatik durum gecmisi, JSON, SQLite, API, GUI, CLI, dashboard, dosya islemi ve otomatik is akisi eklenmedi.

## 055 NonconformityRepository Restore

- `NonconformityRepository` icine `restore(nonconformity_id)` davranisi eklendi.
- Mevcut kayit bulunursa `is_archived` alani bellek icinde `False` yapilacak ve guncellenen kayit dondurulecek.
- Kayit bulunamazsa `None` dondurulecek.
- Bu davranis kaydi silmeyecek, mevcut kayit sirasini degistirmeyecek ve `status` alanina dokunmayacak.
- NonconformityRecord modeli, otomatik arsivleme, otomatik kapanis, otomatik durum gecmisi, JSON, SQLite, API, GUI, CLI, dashboard, dosya islemi ve otomatik is akisi eklenmedi.

## 056 NonconformityRepository Arsiv Ozeti

- `NonconformityRepository` icine `get_archive_summary()` davranisi eklendi.
- Bu davranis aktif, arsivlenmis ve toplam NCR kayit sayilarini `dict[str, int]` olarak dondurecek.
- Bos repository icin `{"active": 0, "archived": 0, "total": 0}` dondurulecek.
- `archive` ve `restore` davranislari sonrasi ozet degerleri guncel `is_archived` alanina gore hesaplanacak.
- Kayit silme, otomatik history, workflow, status degisimi, JSON, SQLite, API, GUI, CLI, dashboard ve dosya islemi eklenmedi.

## 057 NonconformityRepository Arsivlenmis Kayitlari Listeleme

- Mevcut `NonconformityRepository.list_archived()` davranisi Adim 057 kapsami icin netlestirildi.
- Bu davranis sadece `is_archived == True` olan NCR kayitlarini dondurecek.
- Bos repository veya arsivlenmis kayit olmayan repository icin bos liste dondurulecek.
- `restore` sonrasi aktif hale gelen kayitlar artik arsiv listesinde gorunmeyecek.
- Kayit silme, status degisimi, otomatik history, workflow, JSON, SQLite, API, GUI, CLI ve buyuk refactor eklenmedi.

## 058 NonconformityRepository Aktif Kayitlari Listeleme

- Mevcut `NonconformityRepository.list_active()` davranisi Adim 058 kapsami icin netlestirildi.
- Bu davranis sadece `is_archived == False` olan NCR kayitlarini dondurecek.
- Bos repository veya tum kayitlari arsivlenmis repository icin bos liste dondurulecek.
- `restore` sonrasi tekrar aktif hale gelen kayitlar aktif listede yeniden gorunecek.
- Kayit silme, status degisimi, otomatik history, workflow, JSON, SQLite, API, GUI, CLI ve buyuk refactor eklenmedi.

## 059 NonconformityRepository Tum Kayitlari Listeleme

- Mevcut `NonconformityRepository.list_all()` davranisi Adim 059 kapsami icin netlestirildi.
- Bu davranis aktif ve arsivlenmis tum NCR kayitlarini mevcut eklenme sirasiyla dondurecek.
- Bos repository icin bos liste dondurulecek.
- Arsivlenmis kayitlar veya aktif kayitlar dislanmayacak.
- `archive` ve `restore` islemleri kaydin tum liste icinde kalmasini saglayacak; toplam liste silme davranisi gibi calismayacak.
- Kayit silme, status degisimi, `is_archived` degisimi, otomatik history, workflow, JSON, SQLite, API, GUI, CLI ve buyuk refactor eklenmedi.

## 060 NonconformityRepository Arsiv / Listeleme Butunluk Kontrolu

- Bu adimda yeni repository methodu eklenmedi.
- Mevcut `archive`, `restore`, `list_active`, `list_archived`, `list_all` ve `get_archive_summary` davranislarinin birlikte tutarli calismasi testle sabitlendi.
- Arsivleme ve restore islemlerinin kayit silmedigi, toplam listeyi korudugu ve `status` alanini otomatik degistirmedigi dogrulandi.
- Aktif, arsivlenmis ve toplam kayit sayilarinin `get_archive_summary()` ile listeleme davranislariyla uyumlu kalmasi proje karari olarak netlestirildi.
- JSON, SQLite, API, GUI, CLI, otomatik history, workflow, silme mantigi ve buyuk refactor eklenmedi.

## 061 NotebookLM Podcast Notu Adim 056-060

- Adim 056-060 araligi icin final NotebookLM podcast notu hazirlandi.
- Bu not NCR arsiv ozeti, arsivlenmis kayit listesi, aktif kayit listesi, tum kayit listesi ve arsiv/listeleme butunluk kontrolunu tek anlatimda toplar.
- Bu adim sadece dokumantasyon ve podcast arsivi adimidir.
- Uygulama kodu, test dosyalari, JSON, SQLite, API, GUI, CLI ve workflow davranisi degistirilmedi.

## 062 NCR Arsiv / Listeleme Kullanim Ozeti

- Adim 056-060 arasinda netlesen NCR arsivleme ve listeleme davranislari icin kisa kullanim ozeti hazirlandi.
- `archive`, `restore`, `list_active`, `list_archived`, `list_all` ve `get_archive_summary` davranislarinin nasil birlikte kullanilacagi dokumante edildi.
- `is_archived` alaninin gorunurluk/arsiv durumunu, `status` alaninin ise is sureci durumunu temsil ettigi ayrim vurgulandi.
- Bu adim sadece dokumantasyon / kullanim ozeti adimidir.
- Uygulama kodu, test dosyalari, JSON, SQLite, API, GUI, CLI ve workflow davranisi degistirilmedi.

## 063 NCR Kayit Arama Plani

- NCR kayit arama ve filtreleme davranislari icin plan dokumani hazirlandi.
- Bu adimda yeni repository methodu eklenmedi.
- Mevcut arama/filtreleme davranislari varsa tekrar yazilmadan, sonraki adimlarda test ve dokumantasyonla netlestirilmesi kararlastirildi.
- Arama davranislarinin read-only kalmasi, kayit silmemesi ve arsiv gorunurlugunu acik method adi veya parametreyle ifade etmesi ilke olarak belirlendi.
- Uygulama kodu, test dosyalari, JSON, SQLite, API, GUI, CLI, query engine ve workflow davranisi degistirilmedi.

## 064 NonconformityRepository Id Ile Kayit Bulma

- Mevcut `NonconformityRepository.find_by_id()` davranisi Adim 064 kapsami icin netlestirildi.
- Bu davranis aktif, arsivlenmis ve restore edilmis NCR kayitlarini id ile bulacak.
- Eslesen kayit yoksa `None` dondurulmesi karari korundu.
- Id ile arama tum kayit hafizasi uzerinde calisacak; arsivlenmis kayitlar dislanmayacak.
- Bu davranis read-only kalacak; kayit silme, `status` degisimi, `is_archived` degisimi, otomatik history ve workflow olusturmayacak.
- Uygulama kodu, JSON, SQLite, API, GUI, CLI, query engine ve buyuk refactor eklenmedi.

## 065 NonconformityRepository Duruma Gore Filtreleme

- Mevcut `NonconformityRepository.list_by_status(status)` davranisi Adim 065 kapsami icin netlestirildi.
- `filter_by_status(status)` adinda ikinci bir method eklenmedi; mevcut adlandirma korundu.
- Status filtresinin tum kayit hafizasi uzerinde calisacagi ve arsivlenmis kayitlari varsayilan olarak dislamayacagi netlestirildi.
- Eslesen kayit yoksa veya repository bos ise bos liste dondurulmesi karari korundu.
- Bu davranis read-only kalacak; kayit silme, `status` degisimi, `is_archived` degisimi, otomatik history ve workflow olusturmayacak.
- Uygulama kodu, JSON, SQLite, API, GUI, CLI, query engine ve buyuk refactor eklenmedi.

## 066 NonconformityRepository Konuma Gore Filtreleme

- `NonconformityRepository.list_by_location(location)` davranisi eklendi.
- Konum filtresinin tum kayit hafizasi uzerinde calisacagi ve arsivlenmis kayitlari varsayilan olarak dislamayacagi netlestirildi.
- Eslesen kayit yoksa veya repository bos ise bos liste dondurulmesi karari belirlendi.
- Bu davranis read-only kalacak; kayit silme, `location` degisimi, `status` degisimi, `is_archived` degisimi, otomatik history ve workflow olusturmayacak.
- JSON, SQLite, API, GUI, CLI, query engine ve buyuk refactor eklenmedi.

## 067 Dosya ve Video Eki Plani

- Fotoğraf, video, PDF, belge, ses notu ve diger dosya ekleri icin ortak attachment yaklasimi planlandi.
- Video dosyalarinin veritabanina gomulmemesi; dosya yolu / referansi ve metadata bilgisinin tutulmasi karar olarak netlestirildi.
- Mevcut `AttachmentRecord` yaklasiminin ileride `FileAttachmentRecord` veya genisletilmis attachment modeli olarak surdurulebilecegi belirtildi.
- Ilk asamada video oynatma, sikistirma, thumbnail uretme, streaming, medya isleme, dosya yukleme, JSON, SQLite, API, GUI ve CLI eklenmeyecek.
- Bu adim sadece plan dokumantasyonu adimidir; uygulama kodu ve test dosyalari degistirilmedi.

## 068 FileAttachmentRecord Veri Modeli

- `FileAttachmentRecord` veri modeli eklendi.
- Model fotograf, video, PDF, belge, ses notu ve diger dosya ekleri icin dosya metadata ve referans bilgisini temsil edecek.
- Video dosyasi icerigi modele gomulmeyecek; `file_name`, `file_path`, `file_type`, `mime_type`, `file_size` gibi bilgiler tutulacak.
- Iliskili kayit baglantisi `related_record_type` ve `related_record_id` alanlariyla temsil edilecek.
- Repository, dosya yukleme, fiziksel dosya kopyalama, video oynatma, thumbnail uretme, JSON, SQLite, API, GUI, CLI ve persistence davranisi eklenmedi.

## 069 FileAttachmentRecord Dosya Tipi Siniflandirmasi

- `FileAttachmentRecord.file_type` icin temel kullanim siniflari `image`, `video`, `pdf`, `document`, `audio` ve `other` olarak dokumante edildi.
- Bu adimda enum, validation veya hata firlatma davranisi eklenmedi.
- Dosya tipi siniflandirmasinin model icinde metadata olarak tutulacagi netlestirildi.
- `mime_type` alaninin teknik dosya turunu, `file_type` alaninin ise proje icindeki sade sinifi temsil ettigi ayrim vurgulandi.
- Model alani degistirilmedi; repository, dosya yukleme, video oynatma, thumbnail uretme, JSON, SQLite, API, GUI ve CLI eklenmedi.

## 070 FileAttachmentRecord Iliskili Kayit Baglantisi

- `FileAttachmentRecord.related_record_type` ve `related_record_id` alanlarinin kullanim mantigi dokumante edildi.
- Dosya eklerinin ana kaydi degistirmeden veya silmeden, string tabanli basit iliski bilgisiyle ana kayda baglanacagi netlestirildi.
- Bir ana kayda birden fazla dosya eki baglanabilecegi ve ayni dosya tipinin birden fazla kez kullanilabilecegi belirtildi.
- Bu adimda foreign key, ORM relation, SQLite, JSON persistence, API, GUI, CLI, repository ve dosya yukleme davranisi eklenmedi.
- Uygulama kodu ve test dosyalari degistirilmedi.

## 071 NotebookLM Podcast Notu Adim 061-070

- Adim 061-070 araligi icin final NotebookLM podcast notu hazirlandi.
- Bu not NCR arsiv/listeleme kullanim ozetinden arama/filtreleme davranislarina ve dosya/video eki metadata altyapisina gecisi tek anlatimda toplar.
- Video dosyalarinin veritabanina gomulmeyecegi; dosya yolu/referansi ve metadata tutulacagi karar anlatimi icinde vurgulandi.
- Bu adim sadece dokumantasyon ve podcast arsivi adimidir.
- Uygulama kodu, test dosyalari, repository, dosya yukleme, video oynatma, thumbnail, SQLite, JSON persistence, API, GUI ve CLI degistirilmedi.

## 072 FileAttachmentRecord Kullanim Akisi

- `FileAttachmentRecord` icin dosya eki kullanim akisi dokumante edildi.
- Dosya eklerinin ana kayitla `related_record_type` ve `related_record_id` alanlari uzerinden iliskilendirilecegi tekrar netlestirildi.
- Modelin dosya icerigini degil, dosya yolu/referansi ve metadata bilgisini tutacagi karar olarak korundu.
- Fotograf, video, PDF, belge, ses notu, malzeme teslim irsaliyesi ve is guvenligi gozlemi gibi kullanim senaryolari aciklandi.
- Bu adim sadece dokumantasyon / kullanim akisi adimidir.
- Uygulama kodu, test dosyalari, repository, dosya yukleme, fiziksel dosya kopyalama, video oynatma, thumbnail, SQLite, JSON persistence, API, GUI ve CLI degistirilmedi.

## 073 FileAttachmentRecord Ornek Kullanim Senaryolari

- `FileAttachmentRecord` icin santiye kayit turlerine gore ornek kullanim senaryolari dokumante edildi.
- Beton dokumu, uygunsuzluk / NCR, malzeme teslimi, gunluk saha kaydi, iscilik / ekip kaydi, santiye sefi ozel notu ve denetim / kontrol kaydi senaryolari aciklandi.
- Dosyalarin veritabanina gomulmeyecegi; dosya referansi ve metadata bilgisinin tutulacagi karar tekrar korundu.
- Buyuk video dosyalarinin sistem icinde blob olarak saklanmayacagi vurgulandi.
- Bu adim sadece dokumantasyon ve ornek kullanim senaryosu adimidir.
- Uygulama kodu, test dosyalari, repository, dosya yukleme, fiziksel dosya kopyalama/silme/tasima, thumbnail, video oynatma, streaming, SQLite, JSON persistence, API, GUI ve CLI degistirilmedi.

## 074 FileAttachmentRecord Saklama ve Adlandirma Standardi

- `FileAttachmentRecord` ile temsil edilen dosya ekleri icin saklama klasor yapisi ve dosya adlandirma standardi dokumante edildi.
- Dosyanin veritabanina gomulmeyecegi; klasor, sunucu veya bulut ortaminda tutulacagi karar tekrar korundu.
- Dosya yolunun proje, kayit turu, tarih ve kayit id bilgisiyle okunabilir olmasi hedeflendi.
- Dosya adi icin once `YYYYMMDD_HHMMSS__record_type__record_id__file_type__sequence.ext` sablonu onerildi; Adim 085 ile yeni canonical path standardi `attachments/{project_id}/{record_type}/{yyyy}/{mm}/{dd}/{record_id}/{safe_file_name}` olarak kilitlendi.
- Orijinal dosya adinin ileride metadata olarak saklanabilecegi, fakat sistem kimligi olarak kullanilmayacagi belirtildi.
- Video dosyalari icin thumbnail, duration, resolution ve codec gibi bilgilerin ileride ayri metadata olarak degerlendirilebilecegi; bu adimda medya isleme eklenmeyecegi netlestirildi.
- Bu adim sadece dokumantasyon standardi adimidir.
- Uygulama kodu, test dosyalari, repository, dosya yukleme, fiziksel dosya kopyalama/silme/tasima, thumbnail, video oynatma, preview, streaming, SQLite, JSON persistence, API, GUI ve CLI degistirilmedi.

## 075 FileAttachmentRecord Arsiv Guvenligi ve Silme / Tasima Kararlari

- `FileAttachmentRecord` ekleri icin silme, tasima, kayip dosya, arsiv guvenligi ve denetim izi karar dokumantasyonu hazirlandi.
- Kalici silme yerine ileride kontrollu arsiv disi birakma / soft-delete yaklasiminin degerlendirilmesi kararlastirildi.
- Fiziksel dosya bulunamazsa bunun `missing file reference` olarak arşiv bütünlüğü uyarısı seklinde ele alinabilecegi belirtildi.
- Dosya tasinmasi halinde `file_path` veya `storage_reference` bilgisinin guncellenmesi ve tasima gecmisinin ileride loglanmasi gerektigi netlestirildi.
- Arsiv dosyalarinin uzerine yazilmasi yerine yeni versiyonun yeni dosya eki olarak tutulmasi daha guvenli yaklasim olarak belirlendi.
- Dosya ekleme, tasima, pasife alma ve silme olaylari icin ileride `AttachmentEventRecord` benzeri denetim izi modeli degerlendirilebilir.
- Bu adim sadece karar dokumantasyonu adimidir.
- Uygulama kodu, test dosyalari, yeni model, repository, dosya yukleme/silme/tasima/kopyalama, SQLite, JSON persistence, API, GUI, CLI, thumbnail, preview, streaming ve video oynatma degistirilmedi.

## 076 FileAttachmentRecord original_file_name Alani

- `FileAttachmentRecord` modeline opsiyonel `original_file_name` alani eklendi.
- Bu alan sistem tarafindan standartlastirilmis `file_name` degerinden ayri olarak, kullanicinin yukledigi dosyanin orijinal adini metadata olarak saklamak icin kullanilacak.
- `original_file_name` verilmezse varsayilan deger `None` olacak.
- Bu adimda dosya adi standartlastirma fonksiyonu, dosya yukleme sistemi, fiziksel dosya kopyalama/silme/tasima, repository, persistence, SQLite, JSON, API, GUI ve CLI eklenmedi.

## 077 FileAttachmentRecord uploaded_by Alani

- `FileAttachmentRecord.uploaded_by` alani opsiyonel string metadata olarak netlestirildi.
- Bu alan dosya ekinin kim tarafindan sisteme eklendigini saklamak icin kullanilacak.
- Kullanici modeli, rol sistemi veya yetkilendirme kurulmadan once `uploaded_by` sade bir metin alani olarak tutulacak.
- `uploaded_by` verilmezse varsayilan deger `None` olacak.
- Bu adimda kullanici modeli, rol/yetki sistemi, authentication, authorization, dosya yukleme, fiziksel dosya kopyalama/silme/tasima, repository, persistence, SQLite, JSON, API, GUI ve CLI eklenmedi.

## 078 FileAttachmentRecord uploaded_at Alani

- `FileAttachmentRecord.uploaded_at` alani opsiyonel string metadata olarak netlestirildi.
- Bu alan dosya ekinin sisteme ne zaman eklendigini saklamak icin kullanilacak.
- Otomatik tarih uretimi, datetime parsing veya tarih formatlama davranisi bu adimda eklenmeyecek.
- `uploaded_by` ve `uploaded_at` birlikte dosya eki icin basit denetim izi baslangici saglayacak.
- `uploaded_at` verilmezse varsayilan deger `None` olacak.
- Bu adimda kullanici modeli, rol/yetki sistemi, authentication, authorization, dosya yukleme, fiziksel dosya kopyalama/silme/tasima, repository, persistence, SQLite, JSON, API, GUI ve CLI eklenmedi.

## 079 FileAttachmentRecord notes Alani

- `FileAttachmentRecord.notes` alaninin dosya eki ozelindeki kullanim amaci netlestirildi.
- `notes` alaninin fotograf, video, PDF, belge veya ses ekleri icin kisa aciklama, saha baglami, uyari veya ek bilgi tutmak icin kullanilacagi belirtildi.
- `notes` alaninin dosya adi, dosya yolu, dosya tipi veya iliskili kayit bilgisi yerine gecmeyecegi kararlastirildi.
- `notes` verilmezse varsayilan deger `None` olarak kalacak.
- Bu adimda model alani degistirilmedi; dosya yukleme, fiziksel dosya kopyalama/silme/tasima, not arama/filtreleme, repository, persistence, SQLite, JSON, API, GUI ve CLI eklenmedi.

## 080 FileAttachmentRecord Metadata Butunluk Ozeti

- Adim 072-079 arasindaki `FileAttachmentRecord` / dosya eki hatti derin analiz oncesi kapanis dokumaniyla ozetlendi.
- Kullanim akisi, ornek kullanim senaryolari, saklama ve adlandirma standardi, arsiv guvenligi kararları ve metadata alanlari tek dokumanda toplandi.
- Gercek modelde bulunan `file_name`, `file_path`, `file_type`, `mime_type`, `file_size`, `related_record_type`, `related_record_id`, `uploaded_by`, `uploaded_at`, `original_file_name`, `description` ve `notes` alanlarinin anlamlari aciklandi.
- `storage_reference` gibi gercek modelde bulunmayan kavramlar ileride degerlendirilecek metadata olarak ayrildi.
- Video dosyalarinin veritabanina gomulmeyecegi; dosya yolu / referans ve metadata ile izlenecegi karar tekrar vurgulandi.
- Bu adim sadece kapanis dokumantasyonu adimidir.
- Uygulama kodu, test dosyalari, yeni model alani, repository, persistence, SQLite, JSON, API, GUI, CLI, dosya yukleme/kopyalama/silme/tasima, thumbnail, preview, video oynatma ve streaming degistirilmedi.

## 081 README Guncellik Karari

- `README.md` dosyasinin Adim 080 guvenli noktasindaki gercek repo durumunu yansitacak sekilde guncellenmesine karar verildi.
- README icinde projenin domain model, bellek ici repository, test, dokumantasyon, learning ve podcast notlari cekirdegi seviyesinde oldugu aciklandi.
- Guncel test sonucu `125 passed` olarak yazildi.
- Database, gercek upload servisi, API, GUI, auth, deployment ve CI gibi ozelliklerin henuz bulunmadigi acikca belirtildi.
- Bu adimda uygulama kodu ve test dosyalari degistirilmedi.

## 082 ROADMAP Guncellik Karari

- `ROADMAP.md` dosyasinin Adim 080 guvenli noktasi ve Adim 081 README duzeltmesi sonrasindaki gercek proje durumuna gore guncellenmesine karar verildi.
- Adim 001-080 arasindaki ana fazlar uzun ayrinti yerine okunabilir ozetler halinde duzenlendi.
- Adim 081 README duzeltmesi ve Adim 082 ROADMAP guncellemesi tamamlanmis duzeltme adimlari olarak islendi.
- Adim 083-090 araligi duzeltme, standart kilitleme ve dokumantasyon esitleme fazi olarak belirlendi.
- Adim 091-100 araligi persistence, upload, integrity, audit ve CI omurgasi fazi olarak planlandi.
- Database, gercek upload servisi, API, GUI, auth, CI ve deployment ozelliklerinin henuz bulunmadigi roadmap icinde acikca belirtildi.
- Bu adimda uygulama kodu ve test dosyalari degistirilmedi.

## 083 Attachment Model Karari

- Yeni dosya eki hatti icin ana metadata modelinin `FileAttachmentRecord` olmasina karar verildi.
- `AttachmentRecord`, onceki genel ek dosya referans modeli olarak korunacak ve legacy / onceki model olarak degerlendirilecek.
- `AttachmentRecord` bu adimda silinmedi; cunku mevcut testler, Adim 008 ve Adim 026 dokumantasyonu bu modeli referans almaya devam ediyor.
- Yeni upload servisi, integrity scanner, dosya tipi standardi ve iliskili kayit baglantisi calismalari `FileAttachmentRecord` uzerinden ilerleyecek.
- Bu adimda model alanlari degistirilmedi, veri migrasyonu yapilmadi ve kirici refactor uygulanmadi.
- Gercek upload servisi, database, API, GUI, auth, CI ve deployment henuz eklenmedi.

## 084 FileAttachmentRecord Alan Sozlesmesi

- `FileAttachmentRecord.uploaded_by` ve `uploaded_at` alanlarinin model seviyesinde opsiyonel kalmasina karar verildi.
- Bu karar, henuz auth / kullanici sistemi ve gercek upload servisi bulunmadigi icin alindi.
- Ileride upload servisi eklendiginde `uploaded_by` servis seviyesinde zorunlu tutulabilir.
- Ileride upload servisi eklendiginde `uploaded_at` servis tarafindan otomatik uretilebilir.
- Model, servis tarafindan saglanan upload metadata gecmisini tasimaya devam edecek.
- Model-level optional ile service-level required ayrimi bilincli olarak dokumante edildi.
- Bu adimda model alani eklenmedi veya silinmedi; test dosyalari degistirilmedi.

## 085 Canonical Attachment Path Standardi

- Yeni dosya eki metadata ve ilerideki upload hatti icin canonical path standardi `attachments/{project_id}/{record_type}/{yyyy}/{mm}/{dd}/{record_id}/{safe_file_name}` olarak belirlendi.
- `record_type` degerinin kucuk harfli, makine-dostu ve tutarli olmasina karar verildi.
- Tarih klasorleri `yyyy/mm/dd` formatinda tutulacak.
- `safe_file_name`, sanitize edilmis ve dosya sistemi icin guvenli hale getirilmis dosya adi anlamina gelecek.
- Physical file storage ile `FileAttachmentRecord.file_path` metadata alani ayni path standardini referans alacak.
- Bu adimda path helper fonksiyonu, gercek upload servisi, fiziksel dosya tasima/kopyalama/silme, database, API veya GUI eklenmedi.

## 086 File Type / Attachment Status Enum Hazirligi

- `FileAttachmentRecord.file_type` icin canonical deger sozlugu olarak `FileType` enumu eklendi.
- Ileride attachment yasam dongusu ve integrity kontrolleri icin `AttachmentStatus` enumu eklendi.
- `FileAttachmentRecord.file_type` alani string olarak kalmaya devam edecek; bu adimda zorunlu enum donusumu yapilmadi.
- `FileAttachmentRecord` icine yeni `status` alani eklenmedi; `AttachmentStatus` ilerideki attachment lifecycle davranislari icin hazirliktir.
- Gecersiz deger validation davranisi bu adimda eklenmedi; Adim 087 ve sonrasi icin zemin hazirlandi.
- Upload service ve integrity scanner ileride bu enumlari canonical vocabulary olarak kullanabilir.

## 087 FileAttachmentRecord Validation Karari

- `FileAttachmentRecord` icin minimal `__post_init__` validation davranisi eklendi.
- `attachment_id`, `related_record_type`, `related_record_id`, `file_name` ve `file_path` bos string olamayacak.
- `file_type` degeri `FileType` enumundaki canonical degerlerden biri olmak zorunda olacak.
- `file_size` negatif olamayacak.
- `uploaded_by` ve `uploaded_at` alanlari opsiyonel kalmaya devam edecek.
- `FileAttachmentRecord` icine `status` alani eklenmedi.
- Bu adimda path helper, upload service, fiziksel dosya islemi, database, API, GUI, auth, CI veya deployment eklenmedi.

## 088 Attachment Path Helper Karari

- Canonical attachment path standardini koda baglamak icin `build_attachment_path` helper fonksiyonu eklendi.
- Helper `attachments/{project_id}/{record_type}/{yyyy}/{mm}/{dd}/{record_id}/{safe_file_name}` formatinda path string uretir.
- `uploaded_at` degeri string, `date` veya `datetime` olarak kabul edilir.
- `file_name` bas/son bosluklardan temizlenir ve klasor ayiricilar guvenli hale getirilir.
- Helper fiziksel dosya olusturmaz, dosya kopyalamaz, metadata kaydi olusturmaz.
- Bu adimda upload service, database, API, GUI, auth, CI veya deployment eklenmedi.

## 089 Attachment Metadata Integrity Kurallari

- Ileride gelistirilecek missing/orphan scanner icin attachment metadata butunluk durumlari dokumante edildi.
- Scanner tasarimi icin `OK`, `MISSING_FILE`, `ORPHAN_FILE`, `INVALID_PATH`, `DUPLICATE_METADATA` ve `UNREADABLE_FILE` durum kodlari belirlendi.
- Scanner raporunda `status_code`, attachment reference, beklenen path, mevcut path, dosya/metadata varligi, severity, onerilen aksiyon ve kontrol zamani gibi alanlar yer alacak.
- Backup restore, upload service ve audit event hatlariyla iliski karar duzeyinde aciklandi.
- Bu adimda uygulama kodu, test dosyalari, scanner implementasyonu, dosya sistemi taramasi, upload service, database, API, GUI, auth, CI veya deployment eklenmedi.

## 090 Attachment Integrity Status Sabitleri

- Adim 089'da dokumante edilen attachment metadata butunluk durumlari kod tarafinda merkezi sabitlere donusturuldu.
- `OK`, `MISSING_FILE`, `ORPHAN_FILE`, `INVALID_PATH`, `DUPLICATE_METADATA` ve `UNREADABLE_FILE` status kodlari ortak sozluk olarak tanimlandi.
- Tum status kodlari, hata status kodlari ve uyari status kodlari icin immutable `frozenset` koleksiyonlari kullanilacak.
- `MISSING_FILE`, `INVALID_PATH`, `DUPLICATE_METADATA` ve `UNREADABLE_FILE` hata; `ORPHAN_FILE` uyari; `OK` sorun yok durumu olarak ayrildi.
- Bu adimda scanner, dosya sistemi taramasi, upload service, backup logic, audit event implementasyonu, database, API, GUI, auth, CI veya deployment eklenmedi.

## 091 Attachment Integrity Result Modeli

- Ileride scanner tarafindan uretilecek tekil attachment butunluk kontrol sonucu icin `AttachmentIntegrityResult` modeli eklendi.
- Result modeli `status_code`, `severity`, attachment reference, path bilgileri, metadata/dosya varligi, onerilen aksiyon, kontrol zamani ve not alanlarini tasir.
- `status_code` degeri merkezi attachment integrity status sabitlerinden biri olmak zorundadir.
- `severity` degeri `OK`, `WARNING` veya `ERROR` olmak zorundadir.
- `checked_at` verilmezse UTC zaman atanir.
- Bu adimda scanner, dosya sistemi taramasi, upload service, backup logic, audit event implementasyonu, database, API, GUI, auth, CI veya deployment eklenmedi.

## 092 Attachment Integrity Single Record Helper

- Tekil metadata ve dosya varligi bilgilerinden `AttachmentIntegrityResult` ureten `build_attachment_integrity_result` helper fonksiyonu eklendi.
- Helper toplu scanner degildir; yalnizca kendisine verilen boolean ve path bilgileri uzerinden karar verir.
- Karar sirasi `DUPLICATE_METADATA`, `INVALID_PATH`, `MISSING_FILE` / `ORPHAN_FILE`, `UNREADABLE_FILE`, `OK` olarak belirlendi.
- Her hata veya uyari durumu icin makine-dostu `recommended_action` degeri uretilecek.
- Metadata ve dosya birlikte yoksa anlamli scanner sonucu olmadigi icin `ValueError` ile reddedilecek.
- Bu adimda dosya sistemi taramasi, klasor gezme, upload service, backup logic, audit event implementasyonu, database, API, GUI, auth, CI veya deployment eklenmedi.

## 093 Attachment Integrity Report Summary Modeli

- Tekil `AttachmentIntegrityResult` listesinden ust rapor ozeti uretmek icin `AttachmentIntegrityReportSummary` modeli eklendi.
- `build_attachment_integrity_report_summary` helper fonksiyonu eldeki result listesini status ve severity alanlarina gore sayar.
- Bos result listesi tum sayaclari 0 olan ve UTC `generated_at` alanina sahip bir summary uretir.
- Summary sayaclari negatif olamaz; `total_checked` status ve severity sayimlariyla uyumlu olmak zorundadir.
- Bu adimda toplu scanner, dosya sistemi taramasi, klasor gezme, upload service, backup logic, audit event implementasyonu, database, API, GUI, auth, CI veya deployment eklenmedi.

## 094 Attachment Integrity Report Modeli

- Tekil result listesi ile summary bilgisini birlikte tasimak icin `AttachmentIntegrityReport` modeli eklendi.
- Report modeli `results`, `summary`, `generated_at`, `source` ve `notes` alanlarini tasir.
- `results` disaridan liste olarak verilse bile model icinde tuple olarak saklanir.
- `summary.total_checked`, `len(results)` ile uyumlu olmak zorundadir.
- `generated_at` verilmezse UTC zaman atanir; report ve summary zamanlari timezone-aware UTC olmak zorundadir.
- `build_attachment_integrity_report` helper fonksiyonu result listesinden summary uretip report dondurur.
- Bu adimda toplu scanner, dosya sistemi taramasi, klasor gezme, upload service, backup logic, audit event implementasyonu, database, API, GUI, auth, CI veya deployment eklenmedi.

## 095 Attachment Integrity Report Serializer

- `AttachmentIntegrityResult`, `AttachmentIntegrityReportSummary` ve `AttachmentIntegrityReport` modellerini dictionary formatina cevirmek icin serializer helper fonksiyonlari eklendi.
- `checked_at` ve `generated_at` gibi datetime alanlari ISO 8601 string olarak serialize edilecek.
- `None` alanlari dict icinde korunacak; bu adimda bos alanlar ciktidan atilmayacak.
- Report serializer nested result listesini result dict listesine ve summary bilgisini summary dict yapisina cevirir.
- Serializer fonksiyonlari orijinal dataclass/model nesnelerini degistirmez.
- Bu adimda JSON dosyasi yazma, `json.dump`, scanner, dosya sistemi taramasi, klasor gezme, upload service, backup logic, audit event implementasyonu, database, API, GUI, auth, CI veya deployment eklenmedi.

## 096 Ana Proje Ilkeleri ve Veri Politikasi Kararlari

- CSE icin ana proje ilkeleri dokumante edildi: once veri omurgasi, sonra otomasyon, en son AI; kucuk ve guvenilir saha hafizasi; resmi kayit ve ozel alan ayrimi.
- Resmi proje kayitlarinin fiziksel olarak silinmemesi karar olarak netlestirildi.
- NCR, tutanak, kalite kontrol, attachment metadata, audit event, fotograf/video metadata ve proje kararlari gibi kanit niteligindeki resmi kayitlarda hard delete yerine arsivleme, hukumden dusurme, revizyon veya superseded yaklasimi kullanilacak.
- Santiye Sefi Ozel Alani kisisel calisma alani olarak tanimlandi ve resmi proje kayitlarindan izole tutulmasina karar verildi.
- Yeni santiye sefinin eski santiye sefinin private workspace alanina erisemeyecegi; devir icin gerekli bilgilerin explicit handover package veya official record olarak hazirlanmasi gerektigi dokumante edildi.
- Ozel alan verileri icin ileride kullanici bazli encryption key ve crypto-shredding yaklasimi degerlendirilecek.
- Bu adimda uygulama kodu, test dosyalari, database migration, encryption, auth/permission, scanner, upload service, backup/restore implementasyonu, push veya ZIP staging yapilmadi.

## 097 NotebookLM Podcast Notu 071-080

- Adim 071-080 arasindaki `FileAttachmentRecord` metadata hatti icin final NotebookLM podcast notu olusturuldu.
- Podcast notu kullanim akisi, ornek saha senaryolari, saklama/adlandirma standardi, arsiv guvenligi, metadata alanlari ve Adim 080 guvenli kapanis noktasini birlikte ozetler.
- Bu adim sadece dokumantasyon/podcast arsivi adimidir.
- Uygulama kodu, test dosyalari, upload service, scanner, JSON dosyasi yazma, API, GUI, auth, CI veya deployment degistirilmedi.

## 098 NotebookLM Podcast Notu 081-090

- Adim 081-090 arasindaki duzeltme, standart kilitleme ve attachment integrity hazirlik hatti icin final NotebookLM podcast notu olusturuldu.
- Podcast notu README/ROADMAP guncellemesi, canonical attachment model karari, field contract, path standardi, enum hazirligi, validation, path helper, metadata integrity kurallari ve status sabitlerini birlikte ozetler.
- Bu adim sadece dokumantasyon/podcast arsivi adimidir.
- Uygulama kodu, test dosyalari, scanner, upload service, database, API, GUI, auth, CI veya deployment degistirilmedi.

## 099 NotebookLM Podcast Notu 091-096

- Adim 091-096 arasindaki attachment integrity raporlama omurgasi ve CSE veri koruma / ozel alan politikasi icin final NotebookLM podcast notu olusturuldu.
- Podcast notu `AttachmentIntegrityResult`, single-record helper, report summary, report modeli, serializer fonksiyonlari, resmi kayit silmeme karari, Santiye Sefi Ozel Alani izolasyonu ve explicit handover package yaklasimini birlikte ozetler.
- Bu adim sadece dokumantasyon/podcast arsivi adimidir.
- Uygulama kodu, test dosyalari, scanner, upload service, database, API, GUI, auth, CI veya deployment degistirilmedi.

## 100 Guvenli Nokta Final Kalite Kontrol

- Adim 081-099 arasindaki calismalar icin push oncesi final kalite kontrol dokumani olusturuldu.
- Branch durumu, son commit, `origin/master` farki, kritik podcast/politika/integrity dosyalarinin varligi ve pytest sonucu dokumante edildi.
- `chief-site-engineer_adim_080_guvenli_nokta.zip` dosyasinin untracked ve kapsam disi kalmasi karari korundu.
- Bu adim yeni ozellik gelistirme degildir; yalnizca dogrulama, guvenli nokta dokumantasyonu ve push hazirligi adimidir.
- Uygulama kodu, test dosyalari, scanner, upload service, database, API, GUI, auth, CI veya deployment degistirilmedi.

## 101 Genel Proje Denetimi ve Mimari Saglik Raporu

- Adim 100 guvenli noktasindan sonra tum proje genel kalite, mimari tutarlilik, dokumantasyon butunlugu, test kapsami, roadmap uyumu ve sonraki gelistirme yonu acisindan denetlendi.
- Denetim sonucunda attachment integrity hattinin scanner oncesi iyi hazirlandigi, veri koruma / resmi kayit / ozel alan politikasinin guclu dokumante edildigi ve testlerin temiz calistigi kaydedildi.
- README dosyasinin Adim 080 / `125 passed` bilgisinde kaldigi ve Adim 100 / `191 passed` durumuna gore guncellenmesi gerektigi tespit edildi.
- `app/models.py`, `tests/test_models.py` ve `tests/test_records.py` icin buyume riski; attachment scanner icin erken karmasiklik riski; private workspace / official record ayrimi icin model ve test ihtiyaci takip maddesi olarak belirlendi.
- Bu adim yeni ozellik gelistirme degildir; uygulama kodu ve test dosyalari degistirilmeden yalnizca denetim raporu ve gerekli dokumantasyon kayitlari olusturuldu.

## 102 README Guncellik Duzeltmesi

- `README.md` dosyasinin Adim 100 guvenli noktasi, `191 passed` test sonucu ve Adim 101 genel denetim bulgularina gore guncellenmesine karar verildi.
- Eski Adim 080 / `125 passed` bilgileri README'den kaldirildi.
- README icinde attachment integrity hatti, CSE politika dokumanlari, podcast notlari, Adim 101 denetim takip maddeleri ve sonraki teknik yonler ozetlendi.
- Bu adim sadece dokumantasyon guncelligi adimidir; uygulama kodu, test dosyalari, scanner, upload service, database, API, GUI, auth, CI veya deployment degistirilmedi.

## 103 Attachment Integrity JSON Export Baslangici

- `AttachmentIntegrityReport` nesnesini dosyaya yazmadan JSON string formatina donusturen `export_attachment_integrity_report_to_json` helper fonksiyonu eklendi.
- Helper mevcut `serialize_attachment_integrity_report` ciktisini kullanir ve `json.dumps` ile JSON string uretir.
- `ensure_ascii=False` kullanilarak Turkce karakterlerin okunabilir kalmasi kararlastirildi.
- `indent` varsayilan olarak `2` olacak; `indent=None` kompakt JSON uretmek icin kullanilabilecek.
- Bu adimda JSON dosyasi yazma, path alma, klasor olusturma, scanner, dosya sistemi taramasi, upload service, backup/restore veya audit event implementasyonu eklenmedi.

## 104 Attachment Integrity JSON File Export Tasarimi

- Adim 103'te eklenen JSON string export helper'dan sonra ileride guvenli JSON file export davranisi icin tasarim kurallari dokumante edildi.
- File export icin UTF-8 encoding, `ensure_ascii=False`, varsayilan `indent=2`, UTC timestamp'li dosya adi, acik export path, overwrite politikasi, atomic write ve JSON dogrulama beklentileri belirlendi.
- Varsayilan overwrite davranisinin `False` olmasi; ayni dosya varsa hata verilmesi; `overwrite=True` kullaniminin acik karar ve ileride audit event ile iliskilendirilmesi kararlastirildi.
- Export dosyasinin resmi kayit yerine gecmeyecegi, resmi kayitlarin snapshot ciktisi olarak degerlendirilecegi belirtildi.
- Bu adimda uygulama kodu, test dosyalari, JSON dosyasi yazma, scanner, backup/restore, audit event, private workspace exportu, API, GUI veya CLI eklenmedi.

## 105 Attachment Integrity JSON File Export Helper

- `AttachmentIntegrityReport` nesnesini verilen JSON dosya yoluna yazan `export_attachment_integrity_report_to_json_file` helper fonksiyonu eklendi.
- Helper mevcut `export_attachment_integrity_report_to_json` fonksiyonunu kullanir ve dosyayi UTF-8 encoding ile yazar.
- Varsayilan `overwrite=False` olarak belirlendi; hedef dosya varsa `FileExistsError` verilecek.
- `overwrite=True` acikca verilirse mevcut dosyanin uzerine yazilabilecek.
- Parent klasor yoksa otomatik klasor olusturulmayacak ve `FileNotFoundError` verilecek.
- Testlerde yalnizca pytest `tmp_path` kullanildi; gercek proje klasorune test dosyasi yazilmadi.
- Bu adimda scanner, klasor taramasi, backup/restore, audit event, upload service, API, GUI veya CLI eklenmedi.

## 106 CSE Urun Vizyonu ve Saha Hafizasi Stratejisi

- CSE'nin ilk rakibi buyuk insaat yonetim platformlari degil; WhatsApp gruplari, telefon galerisi, Excel listeleri, klasor karmasasi, defter notlari, mail ekleri ve "ben bunu bir yere yazmistim" duzenidir.
- CSE'nin amaci daha fazla modul eklemek degil; santiye sefinin kayit, takip, kanit, arsiv ve hatirlama problemini sade sekilde cozmektir.
- CSE once tarih, konum, kategori, fotograf/dosya, sorumlu kisi, durum, kapanis kaniti, audit/gecmis ve iliskilerden olusan guvenilir veri omurgasini kurar.
- AI ilk katman degildir; dogru kayit, guvenilir arsiv, iliskili veri ve aranabilir saha hafizasi uzerine daha sonra gelecek deger artirici katmandir.
- Gercek santiye kullanimi urun kararlarini yonlendirecek; her yeni ozellik gercek problem, kucuk arac, sahada test, duzeltme ve tekrar test dongusunden gecmelidir.
- Sahada kayit acma suresi 20-30 saniyeyi gecmemelidir.
- Yeni ozellik filtresi: Bu ozellik santiye sefinin sahada unutmamasini, kanitlamasini, takip etmesini, raporlamasini veya daha sonra geri cagirmasini kolaylastiriyor mu?

## 107 Attachment Integrity Scanner Scope Plani

- Attachment integrity scanner once dry-run ve raporlama mantiginda tasarlanacak.
- Ilk asamada dosya silme, dosya tasima, otomatik duzeltme, orphan dosya karantinaya alma veya metadata guncelleme yapilmayacak.
- Scanner yalnizca acikca verilen attachment root siniri icinde calismali; root disina cikan relative path degerleri kabul edilmemelidir.
- Absolute path davranisi ve path traversal riski ayri tasarlanacak; ilk scanner kontrolsuz proje disi path'lere cikmayacak.
- Scanner ciktisi mevcut `AttachmentIntegrityResult` ve `AttachmentIntegrityReport` hatti ile uyumlu olmali.
- Ilk kapsam `OK`, `MISSING_FILE`, `ORPHAN_FILE`, `INVALID_PATH`, `DUPLICATE_METADATA` ve `UNREADABLE_FILE` durumlarini tespit etmeye odaklanir.
- Bu adimda scanner implementasyonu, dosya sistemi taramasi, upload service, backup/restore, audit event, database, API, GUI veya CLI eklenmedi.

## 108 Attachment Integrity Scanner Input Modeli Plani

- Scanner input modeli, scanner'a verilecek `FileAttachmentRecord` metadata kayitlarini ve attachment root sinirini tarif edecek.
- Ilk asamada input modeli dosya taramasi, dosya okuma, scanner davranisi veya metadata guncellemesi uretmeyecek.
- `attachment_records` ve `attachment_root` ilk zorunlu aday alanlar olarak dusunulur.
- `include_orphan_check`, `allowed_record_types`, `checked_by`, `source`, `notes` ve `created_at` / `requested_at` opsiyonel aday alanlar olarak degerlendirilecek.
- Orphan check ayri ve riskli bir secenek olarak ele alinacak; acilirsa yalnizca attachment root altinda ve raporlama amaciyla calismalidir.
- Path traversal ve root disi erisim riski ileride test edilmelidir.
- Bu adimda dataclass, scanner helper, dosya sistemi taramasi, upload service, backup/restore, audit event, database, API, GUI veya CLI eklenmedi.

## 109 Attachment Scanner Dry-run Helper Baslangici

- Ilk dry-run helper gercek dosya sistemi taramasi yapmayacak.
- File existence bilgisi disaridan kontrollu path -> exists map ile verilecek.
- Helper mevcut `build_attachment_integrity_result` hattini kullanarak her `FileAttachmentRecord` icin `AttachmentIntegrityResult` uretecek.
- Map icinde path bulunmazsa kayit guvenli sekilde missing file olarak degerlendirilecek.
- Orphan, duplicate metadata, unreadable file, invalid path ve root disi path kontrolleri bu adimda yapilmayacak.
- Bu ayrim ileride scanner input modeli, root/path guvenligi ve orphan scan adimlarini daha guvenli ele almak icin korunacak.
- Bu adimda klasor traversal, dosya silme/tasima/kopyalama, upload service, backup/restore, audit event, database, API, GUI veya CLI eklenmedi.

## 110 Scanner Dry-run Testleri ve Kullanim Netlestirmesi

- Dry-run helper map tabanli ve gercek dosya sistemi kullanmayan yapi olarak kalacak.
- Duplicate path bu adimda hata sayilmayacak; duplicate metadata tespiti ayri adim konusudur.
- Map icinde fazla path bulunmasi orphan scan anlamina gelmez ve helper tarafindan yok sayilir.
- Path eslesmesi birebir map lookup uzerinden yapilir; benzer path degerleri eslesmis sayilmaz.
- Sonuc sirasi input record sirasi ile ayni kalmalidir.
- Root/path security ve orphan scan daha sonra ayri kapsamda ele alinacaktir.
- Bu adimda helper kapsam genisletilmedi; gercek dosya sistemi taramasi, klasor traversal, dosya silme/tasima/kopyalama, upload service, backup/restore, audit event, database, API, GUI veya CLI eklenmedi.

## 111 Attachment Integrity Rapor Kullanim Ozeti

- Attachment integrity hatti metadata -> dry-run result -> report -> serializer -> JSON export akisi olarak okunacak.
- `AttachmentIntegrityReport` resmi kayit yerine gecmez; mevcut attachment kayitlari icin butunluk kontrol ciktisidir.
- JSON export kalici veri deposu degil, rapor/snapshot ciktisidir.
- Dry-run helper dosya sistemi islemi yapmadan guvenli raporlama hatti saglar.
- Audit, backup, root/path security ve orphan scan ayri adimlarda ele alinacaktir.
- Bu adimda uygulama kodu, test dosyalari, scanner davranisi, serializer, JSON export kodu, audit event, backup/restore, database, API, GUI veya CLI degistirilmedi.

## 112 Audit Event Model Plani

- Audit event, kanit degeri tasiyan olaylarin izini tutmak icin planlanir.
- Audit event resmi kayit, JSON export, backup dosyasi veya scanner sonucu degildir.
- Ilk asamada yalnizca model plani yapilir; otomatik audit yazimi, repository veya database yoktur.
- Attachment integrity raporu ve JSON export ileride audit event uretebilecek olaylar olarak degerlendirilebilir.
- Audit event modeli ileride veri silme onleme, backup/restore ve handover package hattina zemin hazirlayacaktir.
- Bu adimda `AuditEventRecord`, audit helper, audit repository, scanner degisikligi, JSON persistence, backup/restore implementasyonu, API, GUI veya CLI eklenmedi.

## 113 AuditEventRecord Baslangic Modeli

- `AuditEventRecord`, izlenebilir audit olaylari icin sade bir dataclass baslangic modeli olarak eklendi.
- Zorunlu alanlar `event_id`, `project_id`, `event_type`, `actor` ve `occurred_at` olarak belirlendi.
- Hedef kayit, gerekce, onceki/yeni deger, kaynak ve not bilgileri opsiyonel metadata alanlari olarak tutuldu.
- Bu model resmi kayit, scanner sonucu, JSON export dosyasi, repository veya otomatik audit mekanizmasi degildir.
- Bu adimda persistence, audit helper, otomatik audit yazimi, database, API, GUI, CLI, scanner entegrasyonu, backup/restore davranisi, commit, push veya ZIP staging eklenmedi.

## 114 AuditEventRecord Validation Testleri

- `AuditEventRecord` zorunlu alanlari runtime validation ile korunur.
- Validation su asamada yalnizca bos string, whitespace-only string ve `None` degerleri engeller.
- Tarih formati, event type enum, target pair tutarliligi ve ozel alan guvenligi sonraki adimlara birakildi.
- Opsiyonel alanlar bu adimda esnek birakildi; bos string veya `None` degerleri reddedilmez.
- Audit event hala persistence veya otomatik audit sistemi degildir.

## 115 Audit Event Type Sozlesmesi

- Audit event type degerleri domain/action biciminde planlandi.
- `event_type` alani serbest aciklama alani degildir.
- Insan tarafindan okunabilir aciklamalar `reason` veya `notes` alaninda tutulacak.
- `old_value` ve `new_value` event type yerine kullanilmayacak.
- Ilk event type listesi dokumantasyon sozlesmesi olarak belirlendi.
- Event type validation ve kod sabitleri sonraki adima birakildi.
- Bu adim documentation-only tutuldu.

## 116 Audit Event Type Sabitleri ve Validation

- Event type sozlesmesi ilk asamada `AUDIT_EVENT_TYPES` tuple degeriyle tutuldu.
- Hizli membership kontrolu icin `AUDIT_EVENT_TYPE_SET` kullanildi.
- Enum tercih edilmedi; bu asamada sade ve geri alinabilir sabit yapi yeterli goruldu.
- `AuditEventRecord.event_type` artik yalnizca desteklenen event type degerlerini kabul eder.
- `event_type is required` ile `event_type is not supported` hata ayrimi korundu.
- Persistence, repository ve otomatik audit uretimi eklenmedi.

## 117 Audit Event Target Record Iliski Kurallari

- Target record iliskisi `target_record_type` ve `target_record_id` ciftiyle temsil edilecek.
- Iki alan birlikte doluysa olay belirli bir kayda baglanir.
- Iki alan birlikte bossa olay genel proje, sistem veya surec olayi olabilir.
- Tek tarafli doluluk ileride validation riski olarak ele alinacak.
- Target record alanlari aciklama, gerekce veya snapshot alani degildir.
- Event type yalnizca olay turunu, target record alanlari ise olayin iliskili oldugu kaydi belirtir.
- Pair validation ve target type sabitleri sonraki adima birakildi.
- Bu adim documentation-only tutuldu.

## 118 Audit Event Target Record Pair Validation

- `target_record_type` ve `target_record_id` alanlari pair olarak ele alinir.
- Iki alan birlikte `None` olabilir.
- Iki alan birlikte dolu olabilir.
- Tek tarafli target record referansi runtime validation ile reddedilir.
- Validation bu adimda yalnizca `None` bazlidir.
- Bos string / whitespace validation ve target type allowed-list sonraki adimlara birakildi.
- Persistence, repository ve otomatik audit uretimi eklenmedi.

## 119 Audit Event Target Record Type Sozlesmesi

- `target_record_type` icin ilk type sozlesmesi dokumante edildi.
- Target type degerleri kucuk harfli, makine tarafindan okunabilir ve sabit sozlesmeye uygun olacak sekilde planlandi.
- Ilk adaylar `project`, `project_record`, `attachment`, `attachment_metadata`, `attachment_integrity_report`, `json_export`, `backup_package`, `restore_operation`, `handover_package`, `audit_event` olarak belirlendi.
- Target record type aciklama, gerekce, snapshot veya ozel alan verisi tasimayacak.
- Allowed-list validation ve sabitlerin implementasyonu sonraki adima birakildi.
- Bu adim documentation-only tutuldu.

## 120 Audit Event Target Record Type Sabitleri ve Validation

- Target record type sozlesmesi `AUDIT_TARGET_RECORD_TYPES` tuple degeriyle koda baglandi.
- Hizli membership kontrolu icin `AUDIT_TARGET_RECORD_TYPE_SET` kullanildi.
- Enum tercih edilmedi; sade ve geri alinabilir sabit yapi yeterli goruldu.
- `AuditEventRecord.target_record_type` artik yalnizca desteklenen degerleri kabul eder.
- Pair validation ile allowed-list validation ayrimi korundu.
- `target_record_id` format validation sonraki adimlara birakildi.
- Persistence, repository ve otomatik audit uretimi eklenmedi.

## 121 Audit Event Target Record ID Format Tasarimi

- `target_record_id` icin ilk format yaklasimi dokumante edildi.
- Onerilen genel bicim `<TYPE_PREFIX>-<YEAR>-<SEQUENCE>` olarak belirlendi.
- Prefix adaylari target record type degerlerine gore tasarlandi.
- Format tasarimi bu adimda koda baglanmadi.
- Prefix validation, gercek model id alanlariyla uyum kontrolunden sonra ele alinacak.
- `target_record_id` aciklama, gerekce, snapshot veya ozel alan verisi tasimayacak.
- Bu adim documentation-only tutuldu.

## 122 Audit Event Target Record ID Validation Tasarimi

- `target_record_id` validation tasarimi iki asamali planlandi.
- Ilk asama genel format validation olabilir.
- Ikinci asama prefix / target type uyumu olabilir.
- Prefix validation gercek model id alanlariyla uyum kontrolunden once kodlanmayacak.
- Geriye donuk uyumluluk riski nedeniyle bu adim documentation-only tutuldu.
- Regex validation ve prefix validation sonraki adimlara birakildi.

## 123 Podcast 017 - Adim 097-102 NotebookLM Podcast Notu

- Podcast notlari hattinin Adim 097-102 araligindan itibaren geriden tamamlanmasina karar verildi.
- Podcast 017, eksik podcast zincirini tamamlamak icin documentation-only olarak olusturuldu.
- Podcast notlari kod davranisini degistirmez; proje hafizasini ve ogrenme aktarimini guclendirir.

## 124 Podcast 018 - Adim 103-108 NotebookLM Podcast Notu

- Podcast notlari hattinda Podcast 018 ile Adim 103-108 araligi tamamlandi.
- Podcast 018, eksik podcast zincirini sirali tamamlamak icin documentation-only olarak olusturuldu.
- Podcast notlari kod davranisini degistirmez; proje hafizasini ve ogrenme aktarimini guclendirir.

## 125 Podcast 019 - Adim 109-114 NotebookLM Podcast Notu

- Podcast notlari hattinda Podcast 019 ile Adim 109-114 araligi tamamlandi.
- Podcast 019, eksik podcast zincirini sirali tamamlamak icin documentation-only olarak olusturuldu.
- Podcast notlari kod davranisini degistirmez; proje hafizasini ve ogrenme aktarimini guclendirir.

## 126 Podcast 020 - Adim 115-120 NotebookLM Podcast Notu

- Podcast notlari hattinda Podcast 020 ile Adim 115-120 araligi tamamlandi.
- Podcast 020, eksik podcast zincirini sirali tamamlamak icin documentation-only olarak olusturuldu.
- Podcast notlari kod davranisini degistirmez; proje hafizasini ve ogrenme aktarimini guclendirir.

## 127 Guvenli Nokta Kalite Kontrol ve Dokumantasyon Temizligi

- Yeni ozellik eklenmeden once README, ROADMAP, CHANGELOG ve kalite kontrol ciktilari guncel tutulacak.
- ZIP dosyalari repo kapsami disinda kalacak; guvenli nokta arsivleri commit/stage kapsaminda olmayacak ve `.gitignore` ile dislanacak.
- Satir sonu ve whitespace gurultusunu azaltmak icin Python, Markdown ve text dosyalarinda LF satir sonu tercih edilecek.
- Guvenli nokta oncesi `python -m pytest` ve `git diff --check` kontrolleri yapilacak.
- Bu adim documentation / cleanup / quality-control adimidir; uygulama kodu, test dosyalari, yeni model, validation, business logic, API, GUI, CLI, commit, push veya ZIP staging eklenmedi.

## 128 FileAttachmentRecord Validation Bosluklari

- `FileAttachmentRecord` icin zorunlu metadata alanlari `None`, bos string ve whitespace durumlarinda kontrollu `ValueError` uretmelidir.
- `mime_type` bos birakilamaz; bu alan dosyanin kanonik metadata sozlesmesinin parcasidir.
- `file_type` once bos/None kontrolunden gecmeli, sonra desteklenen `FileType` degerleriyle karsilastirilmalidir.
- Bu adim yalnizca `FileAttachmentRecord` validation bosluklarini kapatir; `AuditEventRecord`, audit target id format validation, persistence, repository, API, GUI, CLI, podcast, commit, push veya ZIP staging eklenmedi.

## 129 Record ID Envanteri ve Audit Target ID Risk Analizi

- Audit target_record_id format validation, mevcut record ID envanteri ve merkezi ID sozlesmesi netlesmeden uygulanmayacak.
- Mevcut modellerde explicit ID alani olan ve olmayan kayit aileleri birlikte bulunuyor.
- Testlerde lower-case, upper-case, cok parcali prefix, path icine gomulu ID ve opsiyonel `None` baglanti ornekleri birlikte kullaniliyor.
- `target_record_type` ile `target_record_id` prefix eslestirmesi once merkezi bir karar tablosuna baglanmali.
- Bu adim documentation-only / architecture-decision-prep adimidir; uygulama kodu, test dosyalari, `AuditEventRecord`, target id regex validation, persistence, repository, API, GUI, CLI, podcast, commit, push veya ZIP staging eklenmedi.

## 130 Central Record ID Contract Plan

- Merkezi record ID sozlesmesi planlanmadan ve `target_record_type` / ID ailesi mapping'i netlesmeden `AuditEventRecord.target_record_id` hard validation uygulanmayacak.
- ID sozlesmesi once documentation-only olarak tutulacak; sonra constants/mapping helper, test ornek standardizasyonu, soft validation ve en son hard validation sirasi izlenecek.
- `project_record` gibi genis target type degerleri tek prefixe zorlanmayacak; coklu ID ailesi mapping'i ile ele alinacak.
- Explicit ID alani olmayan modeller icin ID stratejisi ayri karar gerektirir.
- Bu adim architecture planning adimidir; uygulama kodu, test dosyalari, helper implementasyonu, regex validation, persistence, repository, API, GUI, CLI, podcast, commit, push veya ZIP staging eklenmedi.

## 131 Record ID Constants and Mapping Helper Plan

- Record ID constants ve `target_record_type` / ID ailesi mapping helper tasarlanmadan `AuditEventRecord.target_record_id` hard validation uygulanmayacak.
- Ilk helper katmani sadece bilgi dondurmeli; model davranisini veya mevcut test orneklerini degistirmemeli.
- Soft validation helper ayri, hard validation helper ayri tasarlanacak; hard validation migration ve test standardizasyonu sonrasi degerlendirilecek.
- `project_record` gibi genis target type degerleri coklu ID ailesi mapping'i ile desteklenecek.
- Bu adim documentation-only / helper-design-planning adimidir; uygulama kodu, test dosyalari, constants implementasyonu, helper implementasyonu, regex validation, persistence, repository, API, GUI, CLI, podcast, commit, push veya ZIP staging eklenmedi.

## Podcast 021 - Adim 127-131 NotebookLM Podcast Notu

- Podcast 021, Adim 127-131 araligini guvenli nokta disiplini, attachment validation ve record ID sozlesmesi planlari ekseninde ozetler.
- Podcast notlari kod davranisini degistirmez; proje hafizasini, karar aktarimini ve NotebookLM hazirligini guclendirir.
- Bu podcastte `target_record_id` hard validation'in bilincli olarak ertelendigi ve once ID envanteri, central contract, mapping helper plani yaklasiminin secildigi acik tutulur.
- Podcast 021 documentation-only olarak tutuldu; uygulama kodu, test dosyalari, Adim 132 implementasyonu, audit validation, commit, push veya ZIP staging eklenmedi.

## 132 Record ID Constants and Mapping Helper Implementation

- Record ID constants ve `target_record_type` / ID ailesi mapping helper ilk dar kod katmani olarak eklendi.
- `RECORD_ID_PREFIXES`, `TARGET_RECORD_TYPE_TO_ID_FAMILY` ve `TARGET_RECORD_TYPE_TO_ID_PREFIXES` sozlesme bilgisini merkezi ve okunur hale getirir.
- `get_record_id_family_for_target_type` ve `get_allowed_record_id_prefixes_for_target_type` sadece bilgi dondurur; `AuditEventRecord.target_record_id` formatini zorlamaz.
- Bilinmeyen target type degerleri helper seviyesinde temiz `ValueError` alir, fakat mevcut `AuditEventRecord` constructor davranisi daraltilmaz.
- Legacy ID ornekleri korunur; hard validation ancak ID sozlesmesi, mapping, test standardizasyonu ve migration kararlari netlestikten sonra degerlendirilecek.
- Bu adimda persistence, repository, API, GUI, CLI, Podcast 022, commit, push veya ZIP staging eklenmedi.

## 133 Record ID Helper API Boundary and Test Standardization Plan

- Record ID helper API'si validation fonksiyonu gibi kullanilmayacak.
- `get_record_id_family_for_target_type` ve `get_allowed_record_id_prefixes_for_target_type` sadece mapping bilgisi dondurur; `AuditEventRecord.target_record_id` kabul/red karari vermez.
- Legacy ID ornekleri backward compatibility sinyali olarak korunacak; yeni testlerde canonical prefix ornekleri ayri ve kontrollu bicimde kullanilacak.
- Helper mapping testleri ile model validation testleri ayri tutulacak.
- Test ornek standardizasyonu ve soft validation ayri adimlarda ele alinmadan hard validation uygulanmayacak.
- Bu adim documentation-only / API-boundary-planning adimidir; uygulama kodu, test dosyalari, soft validation implementasyonu, hard validation, Podcast 022, commit, push veya ZIP staging eklenmedi.

## 134 Record ID Soft Validation Plan

- Record ID soft validation once diagnostic / uyari katmani olarak planlanacak.
- Soft validation bilgi, uyari veya rapor sonucu uretebilir; `AuditEventRecord.target_record_id` degerini reddetmek icin kullanilmayacak.
- `AuditEventRecord.__post_init__` davranisi daraltilmayacak ve legacy target id ornekleri korunacak.
- Soft validation ciktisi ileride audit raporlama, kalite kontrol ciktisi, CLI/export on kontrolu, handover package on kontrolu veya diagnostic helper icin kullanilabilir.
- `AuditEventRecord.target_record_id` hard validation, test standardizasyonu ve diagnostic cikti olgunlasmadan uygulanmayacak.
- Bu adim documentation-only / soft-validation-planning adimidir; uygulama kodu, test dosyalari, soft validation implementasyonu, hard validation, `FileAttachmentRecord` degisikligi, Podcast 022, commit, push veya ZIP staging eklenmedi.

## 135 Record ID Soft Validation Diagnostic Helper Implementation Plan

- Record ID diagnostic helper once dis kalite kontrol / raporlama katmani icin planlanacak.
- Diagnostic helper veri reddetmeyecek; `info`, `warning` veya helper giris hatasi icin `error` seviyesinde sonuc uretmeyi hedefleyecek.
- Diagnostic helper `AuditEventRecord.__post_init__` icine baglanmayacak ve hard validation olarak kullanilmayacak.
- Legacy ID ornekleri korunacak; diagnostic sonuc sadece gorunurluk ve kalite sinyali saglayacak.
- Diagnostic helper ileride audit report, QC report, CLI/export on kontrolu veya handover package on kontrolu icin kullanilabilir.
- Bu adim documentation-only / diagnostic-helper-planning adimidir; uygulama kodu, test dosyalari, diagnostic helper implementasyonu, soft validation implementasyonu, hard validation, `FileAttachmentRecord` degisikligi, Podcast 022, commit, push veya ZIP staging eklenmedi.

## 136 Record ID Diagnostic Helper Implementation

- `diagnose_record_id_for_target_type` helper'i dis kalite kontrol / raporlama / handover on kontrol katmani icin bilgi ureten kucuk bir fonksiyon olarak eklendi.
- Helper mevcut record ID mapping katmanini kullanir ve `target_record_type`, `target_record_id`, `expected_family`, `allowed_prefixes`, `observed_prefix`, `is_compatible`, `severity` ve `message` alanlarini dondurur.
- Prefix okuma uzun prefixleri once dener; `NCR-CAND`, `NCR-CA`, `MAT-DEL`, `CHK-RES`, `JSON-EXP` ve `file-att` gibi cok parcali prefixler yanlis bolunmez.
- Diagnostic helper veri reddetmez; `AuditEventRecord.__post_init__` icine baglanmadi ve `AuditEventRecord.target_record_id` hard validation eklenmedi.
- Legacy ID ornekleri korunur; `file-att-001` gibi legacy prefixler warning olarak raporlanir ama constructor tarafinda reddedilmez.
- `FileAttachmentRecord` davranisina dokunulmadi; Podcast 022 olusturulmadi, commit, push veya ZIP staging yapilmadi.

## Podcast 022 - Adim 132-136 NotebookLM Podcast Notu

- Podcast 022, record ID constants/mapping helper implementation, helper API boundary, soft validation plan, diagnostic helper plan ve diagnostic helper implementation adimlarini ozetler.
- Podcast notu, hard validation'a dogrudan gecilmeme nedenini merkezi sozlesme, mapping, test standardizasyonu, diagnostic gorunurluk ve legacy ID korunmasi ekseninde anlatir.
- `AuditEventRecord.__post_init__` icine diagnostic helper baglanmadigi ve `AuditEventRecord.target_record_id` hard validation'in hala ertelendigi acik tutulur.
- Diagnostic helper'in dis kalite kontrol, raporlama ve handover on kontrol katmani icin bilgi urettigi; veri reddetmedigi vurgulanir.
- Bu adim documentation-only podcast adimidir; uygulama kodu, test dosyalari, hard validation, commit, push veya ZIP staging eklenmedi.

## 137 Record ID Diagnostic Helper Usage Boundary Plan

- `diagnose_record_id_for_target_type` helper'i saf diagnostic fonksiyon olarak kalacak; bilgi uretir, karar verme sorumlulugu cagiran katmandadir.
- Helper handover on kontrol raporlari, audit kalite kontrol raporlari, migration oncesi envanter taramalari, admin/debug diagnostic ciktilari, test example standardization kontrolleri ve ileride export/backup/restore oncesi uyari uretimi icin kullanilabilir.
- Helper `AuditEventRecord.__post_init__` icinde, constructor validation katmani olarak, hard validation olarak, legacy kayitlari reddetmek icin, `FileAttachmentRecord` davranisini degistirmek icin veya otomatik data correction/migration icin kullanilmayacak.
- `warning` veri hatasi degil kalite kontrol uyarisi; `error` otomatik silme veya duzeltme sebebi degil helper seviyesinde diagnostic uretilemeyen giris olarak ele alinacak.
- `target_record_id` hard validation hala eklenmeyecek; `AuditEventRecord.__post_init__` degistirilmeyecek ve legacy ID ornekleri korunacak.
- Bu adim documentation-only usage-boundary adimidir; uygulama kodu, test dosyalari, hard validation, Podcast 023, commit, push veya ZIP staging eklenmedi.

## 138 Record ID Diagnostic Report Helper Plan

- Ilerideki read-only `build_record_id_diagnostic_report(...)` benzeri helper, birden fazla audit/event/record referansini tarayip her item icin `diagnose_record_id_for_target_type(...)` benzeri diagnostic sonuc uretmek uzere planlandi.
- Olası rapor alanlari `total_count`, `compatible_count`, `warning_count`, `error_count`, `items`, `summary` ve gerekirse ileride `generated_at` olarak belirlendi.
- Her item icin `index`, `target_record_type`, `target_record_id`, `expected_family`, `allowed_prefixes`, `observed_prefix`, `is_compatible`, `severity` ve `message` alanlari planlandi.
- Helper handover on kontrol, audit QC, migration oncesi envanter, backup/export oncesi uyari, admin/debug gorunurlugu ve test example standardization kontrolu icin read-only rapor uretebilir.
- Helper `AuditEventRecord.__post_init__`, constructor validation, hard validation, legacy kayit reddi, otomatik duzeltme, migration uygulamasi, `FileAttachmentRecord` davranisi, database/repository yazimi veya audit event olusturma icin kullanilmayacak.
- `target_record_id` hard validation hala eklenmeyecek; `AuditEventRecord.__post_init__` degistirilmeyecek, legacy ID ornekleri korunacak ve diagnostic report helper ileride bile once read-only kalacak.
- Bu adim documentation-only plan adimidir; uygulama kodu, test dosyalari, diagnostic report helper implementasyonu, hard validation, Podcast 023, commit, push veya ZIP staging eklenmedi.

## 139 Record ID Diagnostic Report API Boundary and Test Matrix Plan

- Olası `build_record_id_diagnostic_report(...)` helper'i icin API boundary, input/output sozlesmesi ve test example matrix planlandi; implementasyon yapilmadi.
- Ilk implementasyonun saf Python input listesiyle baslamasi, dict item (`target_record_type` / `target_record_id`) veya tuple item (`target_record_type`, `target_record_id`) bicimlerini destekleyebilmesi ve model/repository/database bagimliligi eklememesi onerildi.
- Output sozlesmesi `total_count`, `compatible_count`, `warning_count`, `error_count`, `items` ve `summary`; item sozlesmesi `index`, `target_record_type`, `target_record_id`, `expected_family`, `allowed_prefixes`, `observed_prefix`, `is_compatible`, `severity` ve `message` olarak planlandi.
- Test matrix bos input, canonical, legacy, prefix disi, bilinmeyen target type, bos `target_record_id`, karisik severity listesi, index korunumu, summary count dogrulugu, input degismezligi, exception yerine diagnostic item ve cok parcali prefix orneklerini kapsayacak.
- Helper read-only kalacak; kayit reddetmeyecek, veri degistirmeyecek, database/repository yazmayacak, audit event olusturmayacak, migration/otomatik duzeltme yapmayacak, dosya sistemi/backup/restore/export uretmeyecek, `AuditEventRecord.__post_init__` icine baglanmayacak, constructor validation veya hard validation olmayacak.
- `target_record_id` hard validation hala eklenmeyecek; `AuditEventRecord.__post_init__` degistirilmeyecek, legacy ID ornekleri korunacak ve `FileAttachmentRecord` davranisina dokunulmayacak.
- Bu adim documentation-only API-boundary/test-matrix adimidir; uygulama kodu, test dosyalari, helper implementasyonu, hard validation, Podcast 023, commit, push veya ZIP staging eklenmedi.

## 140 Read-only Record ID Diagnostic Report Helper Implementation

- `build_record_id_diagnostic_report(records)` helper'i read-only toplu diagnostic rapor helper'i olarak eklendi.
- Helper saf Python dict itemlari (`target_record_type` / `target_record_id`) ve tuple/list itemlari destekler; her gecerli item icin `diagnose_record_id_for_target_type(...)` sonucunu kullanir.
- Rapor `total_count`, `compatible_count`, `warning_count`, `error_count`, `items` ve `summary` alanlarini dondurur; itemlar input sirasini `index` ile korur.
- Eksik veya uygunsuz itemlar exception firlatmak yerine `error` severity diagnostic item uretir; helper input listesini veya dictlerini mutate etmez.
- Helper kayit reddetmez, veri degistirmez, database/repository yazmaz, audit event olusturmaz, migration/otomatik duzeltme yapmaz, dosya sistemi/backup/restore/export uretmez.
- `AuditEventRecord.__post_init__` icine baglanmadi, constructor validation veya hard validation eklenmedi, legacy ID ornekleri korunur ve `FileAttachmentRecord` davranisina dokunulmadi.
- Podcast 023 olusturulmadi; commit, push veya ZIP staging yapilmadi.

## 141 Record ID Diagnostic Report Usage and Edge Case Standardization

- `build_record_id_diagnostic_report(records)` helper'i handover on kontrol, audit QC, migration oncesi envanter, backup/export oncesi uyari listesi, admin/debug gorunurlugu, test example standardization ve veri kalitesi gozden gecirme dokumantasyonu icin read-only gorunurluk saglar.
- Helper `AuditEventRecord.__post_init__` icinde, constructor validation olarak, hard validation olarak, legacy kayitlari reddetmek icin, otomatik data correction icin, migration uygulama adimi olarak, database/repository yazmak icin, audit event olusturmak icin veya `FileAttachmentRecord` davranisini degistirmek icin kullanilmayacak.
- Bos input hata degildir; canonical ID `info` ve compatible, legacy ID `warning` ve compatible, prefix disi ID `warning` ve incompatible, bilinmeyen target type veya bos `target_record_id` ise helper seviyesinde `error` diagnostic item olarak yorumlanir.
- Uygunsuz input item raporu kesmez; exception yerine `error` diagnostic item uretir. Tuple/list inputta ilk iki eleman, dict inputta `target_record_type` ve `target_record_id` anahtarlari okunur.
- `warning_count` ve `error_count` hard validation tetiklemez; summary/count alanlari karar vermez, rapor gorunurlugu saglar.
- `target_record_id` hard validation hala eklenmeyecek, `AuditEventRecord.__post_init__` degistirilmeyecek, legacy ID ornekleri korunacak ve diagnostic report helper read-only kalacak.
- Bu adim documentation-only usage/edge-case standardization adimidir; uygulama kodu, test dosyalari, hard validation, Podcast 023, commit, push veya ZIP staging eklenmedi.

## 142 Diagnostic Report Export / Format Boundary Plan

- `build_record_id_diagnostic_report(...)` ciktisinin ileride JSON-ready dict, Markdown summary, handover QC summary ve admin/debug gorunumu olarak sunulabilmesi icin format/export siniri documentation-only olarak planlandi.
- Diagnostic helper veri uretir; format layer diagnostic report dict alir ve sunum ciktisi uretir. Format layer diagnostic sonucu yeniden hesaplamaz, veriyi degistirmez, kayit olusturmaz ve audit event uretmez.
- Olası format helper adlari `format_record_id_diagnostic_report_as_markdown(...)`, `format_record_id_diagnostic_report_as_json_ready_dict(...)` ve `build_handover_record_id_qc_summary(...)` olarak yalnizca planlandi; bu adimda implementasyon yapilmadi.
- Format layer dosya sistemine yazmayacak, database/repository yazmayacak, backup/export/restore islemini dogrudan yapmayacak, CLI/API/GUI eklemeyecek ve hard validation tetiklemeyecek.
- Handover QC sunumunda `total_count`, `warning_count`, `error_count` ve warning/error itemlari gorunur olabilir; warning/error degerleri devri otomatik engellemez, "gozden gecirilecek kayit" olarak yorumlanir.
- `warning` veri reddi degildir; `error` otomatik silme veya duzeltme sebebi degildir. Format layer severity anlamlarini degistirmeyecek.
- `target_record_id` hard validation hala eklenmeyecek, `AuditEventRecord.__post_init__` degistirilmeyecek, legacy ID ornekleri korunacak ve `build_record_id_diagnostic_report(...)` davranisi degistirilmeyecek.
- Bu adim documentation-only export/format boundary plan adimidir; uygulama kodu, test dosyalari, export helper, format helper, JSON/Markdown dosya uretimi, hard validation, Podcast 023, commit, push veya ZIP staging eklenmedi.

## 143 Soft Validation Report Layer Plan

- `build_record_id_diagnostic_report(...)` ciktisinin ileride kayit reddetmeyen soft validation report layer icin nasil yorumlanabilecegi documentation-only olarak planlandi.
- Diagnostic katman ham `info` / `warning` / `error` bilgisi uretir; soft validation report bu sonuclari "gozden gecir", "devir oncesi kontrol et" veya "legacy uyumlu ama izlenmeli" gibi kalite kontrol yorumlarina cevirir.
- Soft validation report layer handover on kontrol, audit QC raporu, export/backup oncesi risk gorunurlugu, admin/debug kalite raporu, migration oncesi veri sagligi incelemesi ve test example standardization gozden gecirme icin kullanilabilir.
- Soft validation report `AuditEventRecord.__post_init__`, constructor validation, hard validation, kayit olusturmayi engelleme, legacy kayit reddi, otomatik data correction, migration uygulamasi, database/repository yazimi, audit event olusturma veya `FileAttachmentRecord` davranisi degistirme icin kullanilmayacak.
- Olası `build_record_id_soft_validation_report(...)` helper adi yalnizca planlandi; bu adimda implementasyon yapilmadi.
- Olası soft validation seviyeleri `pass`, `review` ve `attention` olarak planlandi; `blocked` seviyesi hard validation veya engelleme anlami dogurabilecegi icin bu asamada kullanilmayacak.
- Handover ve export/backup yorumlari warning/error kayitlarini gorunur yapar, fakat devir paketini veya exportu otomatik bloke etmez ve backup/restore davranisini degistirmez.
- `target_record_id` hard validation hala eklenmeyecek, `AuditEventRecord.__post_init__` degistirilmeyecek, legacy ID ornekleri korunacak ve `build_record_id_diagnostic_report(...)` davranisi degistirilmeyecek.
- Bu adim documentation-only soft-validation-report-layer plan adimidir; uygulama kodu, test dosyalari, soft validation helper, hard validation, Podcast 023, commit, push veya ZIP staging eklenmedi.

## Podcast 023 - Adim 137-141 NotebookLM Podcast Notu

- Podcast 023, Adim 137-141 araligini diagnostic helper usage boundary, diagnostic report helper plani, API boundary/test matrix, read-only report helper implementasyonu ve edge case standardization ekseninde ozetler.
- Podcast notu, `build_record_id_diagnostic_report(...)` helper'inin neden read-only kaldigini, warning/error seviyelerinin neden kayit reddi olmadigini ve hard validation'in neden hala ertelendigini acik tutar.
- `AuditEventRecord.__post_init__` degistirilmedigi, `target_record_id` hard validation eklenmedigi, legacy ID orneklerinin korundugu ve `FileAttachmentRecord` davranisina dokunulmadigi yinelendi.
- Podcast kapsami yalniz Adim 137-141 ile sinirli tutuldu; sonraki adimlar bu podcast kapsaminda anlatilmadi ve Podcast 024 olusturulmadi.
- Bu adim documentation-only podcast adimidir; uygulama kodu, test dosyalari, hard validation, commit, push veya ZIP staging eklenmedi.

## 144 Soft Validation Report API Boundary and Test Matrix Plan

- Olasi `build_record_id_soft_validation_report(...)` helper'i icin API boundary, input/output sozlesmesi, status/severity yorumlama kurali ve test matrix documentation-only olarak planlandi.
- Ilk guvenli input sozlesmesi diagnostic report dict olarak belirlendi; helper `build_record_id_diagnostic_report(...)` ciktisini yorumlayabilir, fakat record listesi, repository veya database sorgusu almayacak sekilde planlandi.
- Olasi output sozlesmesi `status`, `total_count`, `compatible_count`, `warning_count`, `error_count`, `review_required`, `attention_required`, `messages`, `items` ve `summary` alanlarini icerebilir.
- Status seviyeleri `pass`, `review` ve `attention` olarak planlandi; `blocked` seviyesi hard validation veya engelleme anlami dogurabilecegi icin bu asamada uretilmeyecek.
- Test matrix bos diagnostic report, info-only pass, warning review, error attention, mixed warning/error attention, status onceligi, required flag mantigi, summary/count korunumu, items korunumu, input immutability, eksik alanlar, uygunsuz input tipi, unknown severity, warning'in kayit reddi olmamasi, error'in otomatik duzeltme olmamasi ve `blocked` uretilmemesini kapsayacak.
- Soft validation report helper `AuditEventRecord.__post_init__`, constructor validation, hard validation, kayit engelleme, legacy kayit reddi, otomatik data correction, migration uygulamasi, database/repository yazimi, audit event olusturma veya `FileAttachmentRecord` davranisi degistirme icin kullanilmayacak.
- `target_record_id` hard validation hala eklenmeyecek, `AuditEventRecord.__post_init__` degistirilmeyecek, legacy ID ornekleri korunacak ve `build_record_id_diagnostic_report(...)` davranisi degistirilmeyecek.
- Bu adim documentation-only API-boundary/test-matrix plan adimidir; uygulama kodu, test dosyalari, soft validation helper implementasyonu, hard validation, Podcast 024, commit, push veya ZIP staging eklenmedi.

## 145 Read-only Soft Validation Report Implementation

- `build_record_id_soft_validation_report(diagnostic_report)` helper'i read-only soft validation report katmani olarak eklendi.
- Helper input olarak `build_record_id_diagnostic_report(...)` ciktisi olan diagnostic report dict alir; record listesi, repository veya database sorgusu almaz.
- Output sozlesmesi `status`, `total_count`, `compatible_count`, `warning_count`, `error_count`, `review_required`, `attention_required`, `messages`, `items` ve `summary` alanlarini icerir.
- Status kurallari `pass`, `review` ve `attention` olarak uygulandi; `blocked` status'u uretilmez.
- `pass` warning/error olmadigini, `review` warning goruldugunu, `attention` error veya helper input sorunu goruldugunu anlatir. Bu seviyeler kayit reddi, otomatik silme, otomatik duzeltme veya migration sebebi degildir.
- Helper diagnostic report dict'ini mutate etmez; count degerlerini diagnostic report'tan okur, item ve summary bilgisini korur.
- Unknown severity exception firlatmaz; messages alaninda gorunur olur ve kayit reddi yaratmaz.
- Uygunsuz input veya eksik alanlar exception yerine `attention` seviyesinde okunur soft validation report dondurur.
- `AuditEventRecord.__post_init__` icine baglanmadi, constructor validation veya hard validation eklenmedi, legacy ID ornekleri korunur.
- `build_record_id_diagnostic_report(...)` davranisi degistirilmedi ve `FileAttachmentRecord` davranisina dokunulmadi.
- Database/repository/API/GUI/CLI, audit event olusturma, migration, otomatik duzeltme, Podcast 024, commit, push veya ZIP staging eklenmedi.

## 146 Soft Validation Report Usage and Handover QC Interpretation

- `build_record_id_soft_validation_report(...)` helper'inin usage boundary ve handover QC yorumlama standardi documentation-only olarak belgelendi.
- Helper diagnostic report dict alir, read-only soft validation report dict dondurur, `pass` / `review` / `attention` status degerlerini uretir ve `blocked` status uretmez.
- `pass`, warning veya error gorunmedigini anlatir; ek aksiyon gerekmeyen normal gorunum olarak yorumlanir.
- `review`, warning goruldugunu anlatir; legacy veya prefix disi ama reddedilmeyen kayitlar icin manuel gozden gecirme sinyalidir ve kayit reddi degildir.
- `attention`, error veya eksik/uygunsuz diagnostic input goruldugunu anlatir; manuel inceleme sinyalidir, otomatik silme, otomatik duzeltme, migration veya kayit reddi sebebi degildir.
- Handover QC icinde soft validation report yeni santiye sefine veri sagligi gorunurlugu saglar, warning/error kayitlarini gorunur yapar ve checklist icin gozden gecirilecek kayitlar uretir; devir paketini otomatik bloke etmez.
- Audit QC icinde target record type / id uyum riskini gorunur yapar; legacy kayitlari reddetmez, `AuditEventRecord.__post_init__` icine baglanmaz ve audit event olusturmaz.
- Export/backup oncesi kullanim veri kalitesi risklerini gorunur yapabilir; exportu durdurmaz, backup/restore davranisini degistirmez ve dosya sistemi islemi yapmaz.
- `messages`, `summary`, `warning_count`, `error_count`, `review_required` ve `attention_required` alanlari gorunurluk saglar; hard validation, kayit reddi veya otomatik duzeltme tetiklemez.
- Helper `AuditEventRecord.__post_init__`, constructor validation, hard validation, kayit olusturmayi engelleme, legacy kayit reddi, otomatik data correction, migration uygulamasi, database/repository yazimi, audit event olusturma, `FileAttachmentRecord` davranisi veya API/GUI/CLI entegrasyonu icin kullanilmayacak.
- `target_record_id` hard validation hala eklenmeyecek, `AuditEventRecord.__post_init__` degistirilmeyecek, legacy ID ornekleri korunacak, `build_record_id_diagnostic_report(...)` ve `build_record_id_soft_validation_report(...)` davranislari degistirilmeyecek.
- Bu adim documentation-only usage/handover-QC interpretation adimidir; uygulama kodu, test dosyalari, helper davranisi, `blocked` status, hard validation, Podcast 024, commit, push veya ZIP staging eklenmedi.

## Podcast 024 - Adim 142-146 NotebookLM Podcast Notu

- Podcast 024, Adim 142-146 araligini diagnostic report export/format boundary, soft validation report layer, API boundary/test matrix, read-only soft validation report implementation ve handover QC yorumlama ekseninde ozetler.
- Podcast notu, diagnostic report ciktisinin neden dogrudan export/helper koduna baglanmadigini ve export/format boundary'nin neden once documentation-only planlandigini acik tutar.
- Soft validation report layer'in hard validation'dan farki, `pass` / `review` / `attention` seviyelerinin pratik anlami ve `blocked` status'un neden uretilmedigi anlatilir.
- `build_record_id_soft_validation_report(...)` helper'inin raw diagnostic ciktisini read-only soft validation report'a cevirerek handover ve audit QC gorunurlugu sagladigi, fakat kayit reddetmedigi vurgulanir.
- Warning ve error sinyallerinin otomatik silme, otomatik duzeltme, migration veya kayit reddi degil manuel inceleme anlami tasidigi acik tutulur.
- `AuditEventRecord.__post_init__` degistirilmedi, hard validation eklenmedi, legacy ID ornekleri korundu ve `FileAttachmentRecord` davranisina dokunulmadi.
- Podcast kapsami yalniz Adim 142-146 ile sinirli tutuldu; Adim 147 dahil edilmedi ve Podcast 025 olusturulmadi.
- Bu adim documentation-only podcast adimidir; uygulama kodu, test dosyalari, hard validation, `blocked` status, commit, push veya ZIP staging eklenmedi.

## 147 Diagnostic / Soft Validation Format Helper Plan

- Diagnostic report ve soft validation report ciktilarinin ileride Markdown, JSON-ready dict ve handover QC summary gibi sunum formatlarina nasil donusturulecegi documentation-only olarak planlandi.
- Format layer mevcut diagnostic report dict veya soft validation report dict alacak; diagnostic sonucu yeniden hesaplamayacak, soft validation status yeniden hesaplamayacak, veriyi degistirmeyecek ve kayit reddetmeyecek.
- Olası helper adlari `format_record_id_diagnostic_report_as_markdown(...)`, `format_record_id_soft_validation_report_as_markdown(...)`, `format_record_id_diagnostic_report_as_json_ready_dict(...)`, `format_record_id_soft_validation_report_as_json_ready_dict(...)` ve `build_handover_record_id_qc_summary(...)` olarak yalnizca planlandi; implementasyon yapilmadi.
- Markdown format planinda baslik, summary, status/count alanlari, warning/error item listesi, "kayit reddi degildir" ve "hard validation degildir" notlari yer alabilir.
- JSON-ready dict Python dict olarak kalacak; dosyaya yazma, export etme, backup/restore islemi veya ozel object/datetime uretimi bu katmanda yapilmayacak.
- Handover QC summary yeni santiye sefine veri sagligi gorunurlugu saglayacak; warning/error kayitlarini "gozden gecirilecek kayitlar" olarak gosterecek, devir paketini otomatik bloke etmeyecek ve hard validation tetiklemeyecek.
- Severity/status sunum standardi `info`, `warning`, `error`, `pass`, `review` ve `attention` icin belgelendi; `blocked` status uretilmeyecek ve format layer tarafindan eklenmeyecek.
- Format layer `AuditEventRecord.__post_init__`, constructor validation, hard validation, kayit engelleme, legacy kayit reddi, otomatik data correction, migration uygulamasi, database/repository yazimi, audit event olusturma, `FileAttachmentRecord` davranisi veya API/GUI/CLI entegrasyonu icin kullanilmayacak.
- `target_record_id` hard validation hala eklenmeyecek, `AuditEventRecord.__post_init__` degistirilmeyecek, legacy ID ornekleri korunacak, `build_record_id_diagnostic_report(...)` ve `build_record_id_soft_validation_report(...)` davranislari degistirilmeyecek.
- Bu adim documentation-only format-helper-plan adimidir; uygulama kodu, test dosyalari, format helper implementasyonu, JSON/Markdown dosya uretimi, `blocked` status, hard validation, Podcast 025, commit, push veya ZIP staging eklenmedi.

## 148 Diagnostic / Soft Validation Format Helper API Boundary and Test Matrix Plan

- Diagnostic / soft validation format helper katmani icin API boundary, input/output sozlesmesi ve test matrix documentation-only olarak planlandi.
- Olası helper adlari `format_record_id_diagnostic_report_as_markdown(...)`, `format_record_id_soft_validation_report_as_markdown(...)`, `format_record_id_diagnostic_report_as_json_ready_dict(...)`, `format_record_id_soft_validation_report_as_json_ready_dict(...)` ve `build_handover_record_id_qc_summary(...)` olarak yalnizca planlandi; implementasyon yapilmadi.
- Diagnostic Markdown formatter input'u `build_record_id_diagnostic_report(...)` ciktisi, soft validation Markdown formatter input'u `build_record_id_soft_validation_report(...)` ciktisi, JSON-ready formatter input'u diagnostic veya soft validation report dict, handover QC summary input'u tercihen soft validation report dict olarak planlandi.
- Markdown output string dondurecek ve dosya yazmayacak; JSON-ready dict output primitive/list/dict degerlerle kalacak, serialize edilemeyen object icermeyecek ve dosya yazmayacak.
- Handover QC summary `status`, `review_required`, `attention_required`, `total_count`, `warning_count`, `error_count`, `review_items`, `attention_items` ve `message` gibi alanlar icerebilir; devir paketini otomatik bloke etmeyecek, kayit reddetmeyecek ve hard validation tetiklemeyecek.
- Test matrix Markdown formatter icin pass/review/attention ciktilari, warning/error item gorunurlugu, hard validation degildir notu ve `blocked` status uretilmemesini kapsayacak.
- Test matrix JSON-ready formatter icin output dict olmasi, input immutability, item count/items korunumu, serialize edilemeyen object eklenmemesi ve diagnostic/soft status yeniden hesaplanmamasini kapsayacak.
- Test matrix handover QC summary icin pass, review, attention davranisi, warning/error item listesi korunumu, devir paketinin otomatik bloke edilmemesi ve `blocked` status uretilmemesini kapsayacak.
- Unsupported input icin exception yerine okunur format/summary hatasi planlanabilir; bu davranis kayit reddi anlami dogurmayacak.
- Format layer `AuditEventRecord.__post_init__`, constructor validation, hard validation, kayit engelleme, legacy kayit reddi, otomatik data correction, migration uygulamasi, database/repository yazimi, audit event olusturma, `FileAttachmentRecord` davranisi veya API/GUI/CLI entegrasyonu icin kullanilmayacak.
- `target_record_id` hard validation hala eklenmeyecek, `AuditEventRecord.__post_init__` degistirilmeyecek, legacy ID ornekleri korunacak, `build_record_id_diagnostic_report(...)` ve `build_record_id_soft_validation_report(...)` davranislari degistirilmeyecek.
- Bu adim documentation-only API-boundary/test-matrix plan adimidir; uygulama kodu, test dosyalari, format helper implementasyonu, JSON/Markdown dosya uretimi, `blocked` status, hard validation, Podcast 025, commit, push veya ZIP staging eklenmedi.

## 149 Read-only Diagnostic / Soft Validation Format Helper Implementation

- Diagnostic / soft validation format helper katmani read-only olarak implemente edildi.
- `format_record_id_diagnostic_report_as_json_ready_dict(...)`, `format_record_id_soft_validation_report_as_json_ready_dict(...)`, `format_record_id_diagnostic_report_as_markdown(...)` ve `format_record_id_soft_validation_report_as_markdown(...)` helperlari eklendi.
- JSON-ready helperlar Python dict dondurur, input report verisini mutate etmeden kopyalar, count/status/items/messages/summary icerigini sunar ve yeni serialize edilemeyen object eklemez.
- Markdown helperlar string dondurur; baslik, count/status alanlari, warning/error veya review/attention itemlari ve "kayit reddi degildir" / "Hard validation degildir" notlarini icerir.
- Unsupported inputlarda exception yerine okunur minimal dict veya Markdown string dondurulur; bu kayit reddi anlami tasimaz.
- Formatterlar diagnostic sonucu veya soft validation status'u yeniden hesaplamaz; inputta gelen count/status degerlerini sunar.
- `blocked` output status olarak uretilmez; soft validation Markdown ciktisi `blocked` status uretilmedigini acikca belirtir.
- Testler JSON-ready output, Markdown output, input immutability, unsupported input, no recomputation, no blocked output status ve `AuditEventRecord` constructor davranisinin daralmamasini kapsar.
- `build_record_id_diagnostic_report(...)` ve `build_record_id_soft_validation_report(...)` davranislari degistirilmedi; `AuditEventRecord.__post_init__` degistirilmedi ve `FileAttachmentRecord` davranisina dokunulmadi.
- Bu adimda JSON/Markdown dosyasi, export helper, backup/restore, database/repository/API/GUI/CLI, migration, otomatik duzeltme, hard validation, Podcast 025, commit, push veya ZIP staging eklenmedi.

## 150 Handover QC Summary Usage and Format Helper Boundary

- Adim 149 format helper'larinin handover QC icinde nasil okunacagi ve nerelerde kullanilmayacagi documentation-only olarak belgelendi.
- Format helperlar mevcut report dict'lerini sunuma hazirlar; JSON-ready dict veya Markdown string dondurur, dosya uretmez, export yapmaz, veri degistirmez, diagnostic sonucu veya soft validation status yeniden hesaplamaz, kayit reddetmez ve hard validation degildir.
- Handover QC icinde format helper ciktilari yeni santiye sefine veri sagligi gorunurlugu saglar, warning/error veya review/attention kayitlarini gorunur yapar ve "gozden gecirilecek kayitlar" mantigiyla kullanilir.
- Handover QC ciktisi devir paketini otomatik bloke etmez, kayit reddetmez, hard validation tetiklemez ve `blocked` status uretmez.
- Markdown ciktilari handover notu, QC ozeti, admin/debug gorunumu veya proje ici dokumantasyon icin kullanilabilir; "Bu rapor kayit reddi degildir", "Hard validation degildir" ve "`blocked` status uretilmez" notlarini korumalidir.
- JSON-ready dict ciktilari makine tarafindan okunabilir ara temsil olabilir; bu adimda dosyaya yazilmaz, export helper degildir, backup/restore davranisi degildir, database/repository yazmaz ve input report davranisini degistirmez.
- Handover QC status yorumlari `pass` icin gorunur risk yok, `review` icin manuel gozden gecirme, `attention` icin manuel inceleme ve `blocked` icin kullanilmaz/uretilmez seklinde sabitlendi.
- Format helperlar `AuditEventRecord.__post_init__`, constructor validation, hard validation, kayit engelleme, legacy kayit reddi, otomatik data correction, migration uygulamasi, database/repository yazimi, audit event olusturma, `FileAttachmentRecord` davranisi, API/GUI/CLI entegrasyonu veya JSON/Markdown dosya exportu icin kullanilmayacak.
- `build_record_id_diagnostic_report(...)`, `build_record_id_soft_validation_report(...)` ve tum format helper davranislari degistirilmedi.
- Bu adim documentation-only usage-boundary adimidir; uygulama kodu, test dosyalari, format helper davranisi, JSON/Markdown dosya uretimi, export helper, `blocked` status, hard validation, Podcast 025, commit, push veya ZIP staging eklenmedi.

## 151 Export File Writing Boundary Plan

- Adim 149 JSON-ready dict ve Markdown string formatter helper'larindan sonra olasi JSON/Markdown dosya yazimi, export ve handover package uretimi icin guvenli sinir documentation-only olarak belgelendi.
- Format helper ile file writing helper'in ayni sorumluluk olmadigi netlestirildi; mevcut format helperlar Python dict veya Markdown string dondurur, dosya uretmez, export yapmaz, backup/restore yapmaz, database/repository yazmaz, kayit reddetmez ve hard validation tetiklemez.
- `build_record_id_diagnostic_report(...)`, `build_record_id_soft_validation_report(...)`, `format_record_id_diagnostic_report_as_json_ready_dict(...)`, `format_record_id_soft_validation_report_as_json_ready_dict(...)`, `format_record_id_diagnostic_report_as_markdown(...)` ve `format_record_id_soft_validation_report_as_markdown(...)` davranislari degistirilmeyecek olarak korundu.
- Olasi `write_record_id_diagnostic_report_json(...)`, `write_record_id_soft_validation_report_json(...)`, `write_record_id_diagnostic_report_markdown(...)`, `write_record_id_soft_validation_report_markdown(...)` ve `build_handover_qc_export_package(...)` helper adlari yalnizca gelecek plan olarak not edildi; implementasyon yapilmadi.
- Gelecekte export/file writing layer eklenirse yalniz onceden uretilmis JSON-ready dict veya Markdown string alacak; diagnostic sonucu yeniden hesaplamayacak, soft validation status yeniden hesaplamayacak, veri degistirmeyecek, kayit reddetmeyecek, audit event olusturmayacak, backup/restore davranisi ustlenmeyecek, hard validation tetiklemeyecek ve `blocked` status uretmeyecek.
- Dosya yazimi icin acik output path, proje disina yazma siniri, path traversal korumasi, overwrite politikasi, deterministik dosya adi, UTF-8 encoding, JSON serialize edilebilirlik ve Markdown insan-okurlugu gibi guvenlik prensipleri ayri planlanacak.
- Handover package ileride yeni santiye sefine veri sagligi gorunurlugu saglayabilir ve warning/error veya review/attention kayitlarini gorunur yapabilir; fakat devir paketini otomatik bloke etmeyecek, kayit reddetmeyecek, hard validation tetiklemeyecek ve eski santiye sefinin ozel alanini devretmeyecek.
- Export/file writing layer `AuditEventRecord.__post_init__`, constructor validation, hard validation, kayit olusturmayi engelleme, legacy kayit reddi, otomatik data correction, migration uygulamasi, database/repository yazimi, audit event olusturma, `FileAttachmentRecord` davranisi, API/GUI/CLI entegrasyonu veya backup/restore motoru icin kullanilmayacak.
- `target_record_id` hard validation hala eklenmeyecek, `AuditEventRecord.__post_init__` degistirilmeyecek, legacy ID ornekleri korunacak, format helper davranislari degistirilmeyecek ve `blocked` status uretilmeyecek.
- Bu adim documentation-only export/file-writing-boundary plan adimidir; uygulama kodu, test dosyalari, export/file writing helper implementasyonu, JSON/Markdown dosya uretimi, backup/restore davranisi, hard validation, Podcast 025, commit, push veya ZIP staging eklenmedi.

## Podcast 025 - Adim 147-151 NotebookLM Podcast Notu

- Podcast 025, Adim 147-151 araligini diagnostic / soft validation format helper plani, API boundary/test matrix, read-only JSON-ready dict ve Markdown formatter implementasyonu, handover QC usage boundary ve export/file writing boundary ekseninde ozetler.
- Podcast notu, diagnostic ve soft validation report ciktilarinin neden ayri format katmanina tasindigini, format helper planinin neden once documentation-only yapildigini ve API boundary/test matrix'in neden implementation'dan once belgelendigini acik tutar.
- Adim 149'da gelen JSON-ready dict ve Markdown helper'larin raporlari okunur hale getirdigi, fakat dosya uretmedigi, export yapmadigi, backup/restore davranisi eklemedigi, diagnostic sonucu veya soft validation status'u yeniden hesaplamadigi vurgulandi.
- Handover QC summary'nin yeni santiye sefine gorunurluk sagladigi, warning/error veya review/attention kayitlarini manuel inceleme icin gorunur yaptigi, fakat kayit reddi veya otomatik devir bloklama olmadigi anlatildi.
- Export/file writing boundary'nin ayri risk katmani oldugu; output path, overwrite politikasi, path traversal, UTF-8 encoding, JSON serialize edilebilirlik, Markdown insan-okurlugu ve handover package siniri gibi konular cozulmeden JSON/Markdown dosya uretimine gecilmeyecegi belgelendi.
- Hard validation ve `blocked` status'un hala kapsam disinda oldugu, `AuditEventRecord.__post_init__` ve `FileAttachmentRecord` davranislarinin degistirilmedigi yinelendi.
- Podcast kapsami yalniz Adim 147-151 ile sinirli tutuldu; Adim 152 dahil edilmedi ve Podcast 026 olusturulmadi.
- Bu adim documentation-only podcast adimidir; uygulama kodu, test dosyalari, JSON/Markdown dosya uretimi, export/file writing helper implementasyonu, hard validation, `blocked` status, commit, push veya ZIP staging eklenmedi.

## 152 Export Helper API Boundary and File Writing Safety Plan

- Adim 151 export/file writing boundary sonrasinda olasi JSON/Markdown export helper'lari icin API boundary, path safety, overwrite policy, encoding/format beklentileri ve test matrix documentation-only olarak planlandi.
- Format helper ile export helper'in ayri katmanlar oldugu yinelendi; format helper Python dict veya Markdown string dondurur, export helper ise ileride kalici dosya ciktisi uretebilir ve bu nedenle ayri path/overwrite/encoding siniri ister.
- Olasi `write_record_id_diagnostic_report_json(...)`, `write_record_id_soft_validation_report_json(...)`, `write_record_id_diagnostic_report_markdown(...)`, `write_record_id_soft_validation_report_markdown(...)` ve `write_handover_qc_summary_markdown(...)` helper adlari yalnizca gelecek plan olarak not edildi; implementasyon yapilmadi.
- JSON export helper'in input olarak JSON-ready Python dict, Markdown export helper'in input olarak Markdown string almasi ve output path'in acikca verilen guvenli path olmasi planlandi; output ileride yazilan dosya yolu veya write result dict olabilir.
- Gelecekte export helper diagnostic report veya soft validation report'u yeniden hesaplamayacak, format helper davranisini degistirmeyecek, kayit reddetmeyecek, hard validation yapmayacak, `blocked` status uretmeyecek, database/repository yazmayacak, audit event olusturmayacak, backup/restore motoru gibi davranmayacak ve API/GUI/CLI entegrasyonu eklemeyecek.
- Path safety planinda output path'in acik verilmesi, path traversal'in engellenmesi, proje koku veya izinli export klasoru disina yazimin engellenmesi, absolute/relative path davranislarinin test edilmesi, parent directory davranisinin planlanmasi, deterministik dosya adi, Windows path karakterleri ve ZIP/yedek dosyalarin export kapsamina alinmamasi belgelendi.
- Overwrite policy icin guvenli varsayilan `overwrite=False` olarak planlandi; `overwrite=True` explicit parametre ve ayri test gerektiren davranis olarak belirlendi.
- Encoding ve format planinda Markdown ve JSON icin UTF-8, JSON icin olasi deterministic indentation, JSON primitive/list/dict serialize edilebilirligi, Markdown insan-okurlugu ve format helper'dan gelen icerigin dosya yaziminda degistirilmemesi belgelendi.
- Test matrix JSON/Markdown export path safety, relative/absolute path davranisi, path traversal reddi, izinli klasor disina cikmama, overwrite davranisi, parent directory davranisi, UTF-8, JSON serialize edilebilirlik, Markdown icerik korunumu, input immutability, format helper'in yeniden hesaplanmamasi, hard validation tetiklenmemesi, `blocked` status uretilmemesi ve ZIP/yedek dosyalarin stage/export kapsamina alinmamasini kapsayacak.
- Handover export ileride yalniz explicit handover icerigi uretebilir; warning/error veya review/attention kayitlarini gorunur yapabilir, fakat eski santiye sefinin ozel alanini devretmeyecek, devir paketini otomatik bloke etmeyecek, kayit reddetmeyecek ve hard validation tetiklemeyecek.
- `target_record_id` hard validation hala eklenmeyecek, `AuditEventRecord.__post_init__` degistirilmeyecek, legacy ID ornekleri korunacak, `build_record_id_diagnostic_report(...)`, `build_record_id_soft_validation_report(...)` ve format helper davranislari degistirilmeyecek.
- Bu adim documentation-only export-helper-boundary/file-writing-safety plan adimidir; uygulama kodu, test dosyalari, export/file writing helper implementasyonu, JSON/Markdown dosya uretimi, backup/restore davranisi, hard validation, `blocked` status, Podcast 026, commit, push veya ZIP staging eklenmedi.

## 153 Path Safety and Overwrite Policy Detailed Documentation

- Adim 153 path safety ve overwrite policy konusunu documentation-only olarak detaylandirdi.
- Gelecekteki export helper'in output path'i implicit secmemesi, explicit output path istemesi ve yazma hedefini izinli export kokunun icinde tutmasi kararlastirildi.
- Relative path davranisi izinli export kokune gore cozumlenmeli; cozumlenmis hedef allowed output root disina cikiyorsa yazma yapilmamalidir.
- Absolute path davranisi ya tamamen reddedilmeli ya da cozumlenmis hedef allowed output root altinda kalacak sekilde sinirlanmalidir; Windows drive/UNC varyasyonlari test matrix'te dikkate alinmalidir.
- Parent directory davranisi belirsiz birakilmayacak; guvenli varsayilan eksik parent icin hata olabilir, otomatik olusturma ancak explicit ve allowed output root altinda planlanabilir.
- Path traversal riskleri `..`, mixed separator, encoded traversal benzeri inputlar ve dosya adi icinde separator kullanimi icin prensip duzeyinde belgelendi; yalniz string prefix kontrolu yeterli karar sayilmadi.
- `.git`, `.env`, cache, pycache, database, backup, ZIP/yedek ve source-code alanlari future export yazim kapsamindan disarida tutulacak.
- Dosya uzantisi siniri JSON export icin `.json`, Markdown export icin `.md` olarak planlandi; bos dosya adi, separator iceren ad, cok uzun ad, ozel karakterler ve Windows reserved names riski ayri ele alinacak.
- Overwrite policy icin guvenli varsayilan `overwrite=False` olarak netlestirildi; mevcut dosya explicit `overwrite=True` olmadikca ezilmeyecek ve overwrite davranisi ileride audit/log gorunurluguyle ele alinabilir.
- Atomic write icin temporary file + replace prensibi ileride degerlendirilebilir; bu adimda temporary file, replace veya file-writing kodu eklenmedi.
- Hata davranisi exception veya diagnostic result olarak ileride tasarlanabilir; hangi model secilirse secilsin kayit reddi, hard validation veya `blocked` status anlami tasimayacak.
- Read-only format helper ile file-writing export helper ayrimi korundu; format helper Python dict/Markdown string dondurur, file-writing helper ise ileride yalniz hazir ciktinin guvenli dosyaya yazilmasindan sorumlu olabilir.
- Handover QC export yalniz gorunurluk ve manuel inceleme amacli kullanilabilir; devir paketini otomatik bloke etmeyecek, kayit reddetmeyecek, eski santiye sefinin ozel alanini devretmeyecek ve backup/restore motoru olmayacak.
- `target_record_id` hard validation hala eklenmeyecek, `AuditEventRecord.__post_init__` degistirilmeyecek, legacy ID ornekleri korunacak, `FileAttachmentRecord` davranisi degistirilmeyecek ve `blocked` status uretilmeyecek.
- Bu adim documentation-only detailed-policy adimidir; uygulama kodu, test dosyalari, export/file writing helper implementasyonu, JSON/Markdown export dosyasi, backup/restore davranisi, database/repository/API/GUI/CLI, hard validation, Podcast 026, commit, push veya ZIP staging eklenmedi.

## 154 Export Helper Test Matrix Finalization

- Adim 154, Adim 155'te ele alinabilecek read-only file writing helper implementation oncesinde export helper test matrix'ini documentation-only olarak netlestirdi.
- Format helper ile file-writing export helper ayri test edilecek; format helper JSON-ready dict veya Markdown string uretir, export helper ise ileride yalniz hazir ciktinin guvenli dosya yazimindan sorumlu olabilir.
- JSON export helper testleri JSON-ready dict input, `.json` uzantisi, UTF-8 output, pretty/indent davranisi, dosya iceriginin tekrar okunup dogrulanmasi, input immutability, diagnostic/soft validation recomputation olmamasi ve dataclass/object/unserializable input icin guvenli hata davranisini kapsayacak.
- Markdown export helper testleri Markdown string input, `.md` uzantisi, UTF-8 output, Markdown iceriginin yeniden formatlanmamasi, formatter ciktisinin degistirilmemesi ve non-string input icin guvenli hata davranisini kapsayacak.
- Path safety testleri explicit output path zorunlulugu, bos path, traversal reddi, `..`, allowed output root disina cikmama, absolute/relative path davranisi, mixed separator, Windows reserved names riski ve `.git`, `.env`, cache, pycache, database, backup, ZIP/yedek alanlarina yazmama senaryolarini kapsayacak.
- Overwrite policy testleri `overwrite=False` varsayilanini, hedef dosya varken yazmama davranisini, icerigin korunmasini, explicit `overwrite=True` ile uzerine yazmayi ve yalniz hedef dosyanin degistigini dogrulamayi kapsayacak.
- Parent directory testleri parent mevcutken yazmayi, parent yokken net hata/olusturma davranisini, otomatik klasor olusturma varsa bunun yalniz allowed output root altinda olmasini ve root disinda parent olusturulmamasi kararini kapsayacak.
- Unsupported input ve hata davranisi testleri bos filename, klasor path'i, yanlis uzanti, cok uzun filename, separator iceren filename, `None` input, bos dict/string, izin hatasi, kilitli/erisilemez hedef dosya, yarim dosya birakmama ve input mutate etmeme beklentilerini kapsayacak.
- ZIP/yedek/cache dislama testleri ignored ZIP'in export girdisi/hedefi gibi kullanilmamasini, ZIP/yedek/cache dosyalarinin stage edilmemesini ve `.pytest_cache` / `__pycache__` alanlarinin export hedefi olmamasini kapsayacak.
- Atomic write temporary file + replace prensibi ileride degerlendirilebilir; bu adimda atomic write, temporary file veya replace implementasyonu yapilmadi.
- Handover QC export testleri explicit path, allowed output root, overwrite=False ile mevcut dosya koruma, warning/error veya review/attention bilgisinin yalniz gorunurluk olarak tasinmasi ve devir paketinin otomatik bloke edilmemesini kapsayacak.
- `target_record_id` hard validation hala eklenmeyecek, `AuditEventRecord.__post_init__` degistirilmeyecek, legacy ID ornekleri korunacak, `FileAttachmentRecord` davranisi degistirilmeyecek ve `blocked` status uretilmeyecek.
- Bu adim documentation-only test-matrix-finalization adimidir; uygulama kodu, test dosyalari, export/file writing helper implementasyonu, JSON/Markdown export dosyasi, backup/restore davranisi, database/repository/API/GUI/CLI, hard validation, Podcast 026, commit, push veya ZIP staging eklenmedi.

## 155 Read-only File Writing Helper Implementation

- Adim 155'te hazir JSON-ready dict ve Markdown string ciktilarini explicit output path'e yazan iki kucuk helper eklendi: `write_json_ready_dict_to_file(...)` ve `write_markdown_text_to_file(...)`.
- Helperlar read-only boundary icinde tutuldu; database/repository yazmaz, audit event uretmez, backup/restore baslatmaz, kayit degistirmez, diagnostic/soft validation sonucunu yeniden hesaplamaz ve format helper davranisini degistirmez.
- JSON helper yalniz dict input kabul eder, `.json` uzantili dosyaya UTF-8 yazar, `indent=2`, `ensure_ascii=False`, `sort_keys=True` ile deterministic cikti uretir, input dict'i mutate etmez ve unserializable object icin standart `TypeError` verir.
- Markdown helper yalniz string input kabul eder, `.md` uzantili dosyaya UTF-8 yazar, Markdown icerigini yeniden formatlamaz ve non-string input icin `TypeError` verir.
- Her iki helper icin `output_path` zorunludur, varsayilan `overwrite=False` olarak uygulandi; hedef dosya varsa explicit `overwrite=True` olmadikca yazma yapilmaz ve `FileExistsError` verilir.
- Minimum path safety policy uygulandi: bos path, `..` traversal, yanlis uzanti, existing directory target, missing parent directory, optional `allowed_root` disina cikma ve `.git`, `.env`, cache, pycache, database, backup, restore, ZIP/yedek gibi non-export alanlara yazma reddedilir.
- Parent directory otomatik olusturulmadi; parent yoksa `FileNotFoundError` verilir. Gelecekte parent olusturma istenirse explicit parametre ve ayri testlerle ele alinmalidir.
- Testler JSON/Markdown yazimi, UTF-8 korunumu, deterministic JSON, input immutability, unsupported input, overwrite davranisi, allowed_root ic/dis senaryolari, traversal reddi, missing parent, non-export area reddi, helper boundary korunumu ve `blocked` status uretilmemesini kapsar.
- Test sonucu bu adimda `319 passed` seviyesine cikti.
- `target_record_id` hard validation hala eklenmeyecek, `AuditEventRecord.__post_init__` daraltilmayacak, legacy ID ornekleri korunacak, `FileAttachmentRecord` davranisi degistirilmeyecek ve `blocked` status uretilmeyecek.
- Bu adim sinirli implementation adimidir; JSON/Markdown ornek export dosyasi repo icinde uretilmedi, backup/restore davranisi, database/repository/API/GUI/CLI, audit event uretimi, hard validation, Podcast 026, commit, push veya ZIP staging eklenmedi.

## 156 Export Helper Usage Documentation

- Adim 156, Adim 155'te eklenen `write_json_ready_dict_to_file(...)` ve `write_markdown_text_to_file(...)` helper'larinin kullanim sinirini documentation-only olarak belgelendi.
- JSON-ready dict akisi report helper -> JSON-ready formatter -> file writing helper olarak sabitlendi; file-writing helper diagnostic veya soft validation sonucunu yeniden hesaplamayacak ve input dict'i mutate etmeyecek.
- Markdown akisi report helper -> Markdown formatter -> file writing helper olarak sabitlendi; file-writing helper Markdown icerigini yeniden formatlamayacak ve input string'i degistirmeyecek.
- `allowed_root`, explicit output path, `overwrite=False` varsayilani, explicit `overwrite=True`, parent directory otomatik olusturmama, yanlis uzanti reddi, path traversal reddi ve non-export alanlara yazmama prensipleri usage dokumantasyonunda aciklandi.
- `.git`, `.env`, cache, pycache, ZIP/yedek, database, backup ve restore alanlari export hedefi olarak kullanilmayacak; `exports/` klasoru ancak explicit path ve allowed-root siniriyle guvenli aday olarak ele alinacak.
- Handover QC export senaryosu yalniz yeni santiye sefine gorunurluk ve manuel inceleme destegi olarak belgelendi; devir paketini otomatik bloke etmeyecek, kayit reddetmeyecek, audit event uretmeyecek ve backup/restore motoru olmayacak.
- Export helper usage hard validation degildir; `AuditEventRecord.__post_init__` daraltilmayacak, legacy ID ornekleri korunacak, `FileAttachmentRecord` davranisi degistirilmeyecek ve `blocked` status uretilmeyecek.
- Bu adim documentation-only usage adimidir; uygulama kodu, test dosyalari, yeni helper implementasyonu, JSON/Markdown export dosyasi, backup/restore davranisi, database/repository/API/GUI/CLI, audit event uretimi, hard validation, Podcast 026, commit, push veya ZIP staging eklenmedi.

## Podcast 026 - Adim 152-156 NotebookLM Podcast Notu

- Podcast 026, Adim 152-156 araligini export helper API boundary, path safety / overwrite policy, test matrix finalization, read-only file writing helper implementation ve usage documentation ekseninde ozetler.
- Podcast notu, formatter helper ile file-writing helper ayrimini, JSON-ready dict ve Markdown string akislarini, explicit output path yaklasimini, `allowed_root` guvenlik sinirini, path traversal reddini ve `overwrite=False` varsayilanini sade anlatimla aciklar.
- Podcast 026, Adim 155'te eklenen `write_json_ready_dict_to_file(...)` ve `write_markdown_text_to_file(...)` helper'larini tanitir; helperlarin diagnostic/soft validation sonucunu yeniden hesaplamadigini ve input mutate etmedigini vurgular.
- Test sayisinin 294 passed seviyesinden 319 passed seviyesine ciktigi, fakat `exports/` icinde repo'ya kalici JSON/Markdown export cikti dosyasi eklenmedigi not edildi.
- Handover QC export senaryosu gorunurluk ve manuel inceleme destegi olarak anlatildi; devir paketini otomatik bloke etme, kayit reddi, hard validation, `blocked` status veya backup/restore davranisi olarak sunulmadi.
- Podcast kapsami yalniz Adim 152-156 ile sinirli tutuldu; Adim 157 veya sonrasi dahil edilmedi ve Podcast 027 olusturulmadi.
- `target_record_id` hard validation hala eklenmeyecek, `AuditEventRecord.__post_init__` daraltilmayacak, legacy ID ornekleri korunacak, `FileAttachmentRecord` davranisi degistirilmeyecek ve `blocked` status uretilmeyecek.
- Bu adim documentation-only podcast adimidir; uygulama kodu, test dosyalari, yeni helper implementasyonu, JSON/Markdown export dosyasi, backup/restore davranisi, database/repository/API/GUI/CLI, audit event uretimi, hard validation, Podcast 027, commit, push veya ZIP staging eklenmedi.

## 157 Export Helper Error / Result Contract Plan

- Adim 157, Adim 155'te eklenen `write_json_ready_dict_to_file(...)` ve `write_markdown_text_to_file(...)` helper'larinin hata ve basari sozlesmesini documentation-only olarak netlestirdi.
- Mevcut dusuk seviyeli helper davranisinin korunmasina karar verildi: basarili yazim `Path` nesnesi dondurur, basarisiz yazim standart Python exception ile gorunur olur.
- String path donusu ve result dict donusu degerlendirildi; string path'in Python path islemleri icin daha zayif oldugu, result dict'in ise kullaniciya donuk katmanlarda faydali ama mevcut helper icin daha karmasik oldugu kaydedildi.
- Gelecekte result contract gerekiyorsa bunun mevcut helper return type'ini degistirmek yerine ayri wrapper/helper olarak planlanmasi daha guvenli karar olarak not edildi.
- Olasil future result contract alanlari `success`, `output_path`, `error_code`, `error_message`, `skipped_reason` ve `overwritten` olarak belgelendi; bu adimda result object implementasyonu yapilmadi.
- Path safety hata kategorileri bos path, klasor path, yanlis uzanti, traversal, `allowed_root` disina cikma ve missing parent olarak ayrildi; bu durumlarin sessizce yutulmamasi gerektigi kararlastirildi.
- Input hata kategorileri non-dict JSON input, serialize edilemeyen JSON input, non-string Markdown input ve bos icerik politikasi olarak belgelendi.
- Overwrite hata davranisi `overwrite=False` ile hedef dosya varken yazmama ve gorunur hata, `overwrite=True` ile explicit basarili yazim olarak aciklandi.
- File system hata kategorileri izin hatasi, kilitli dosya ve disk/IO hatalari olarak belgelendi; mevcut asamada bu hatalar standart Python exception olarak yukari tasinabilir.
- Handover QC veya kullaniciya donuk gelecek katmanlar exception'lari okunur mesajlara cevirebilir; bu gorunurluk manuel inceleme icindir, devir paketini otomatik bloke etmez ve kayit reddi anlami tasimaz.
- File-writing helperlar diagnostic/soft validation sonucunu yeniden hesaplamayacak, format helper davranisini degistirmeyecek ve format helper ile file-writing helper ayrimi korunacak.
- Bu adim documentation-only error/result-contract plan adimidir; uygulama kodu, test dosyalari, helper davranisi, result contract implementasyonu, JSON/Markdown export dosyasi, audit event uretimi, backup/restore davranisi, database/repository/API/GUI/CLI, hard validation, `AuditEventRecord.__post_init__`, `FileAttachmentRecord`, `blocked` status, Podcast 027, commit, push veya ZIP staging eklenmedi.

## 158 Export Helper Result Contract Implementation Plan

- Adim 158, Adim 157'de planlanan export helper error/result contract yaklasiminin ileride nasil uygulanabilecegini documentation-only olarak netlestirdi.
- Mevcut exception tabanli helper davranisi geriye uyumluluk icin korunacak; `write_json_ready_dict_to_file(...)` ve `write_markdown_text_to_file(...)` basarida `Path` dondurmeye, hatada standart Python exception vermeye devam eden dusuk seviyeli helperlar olarak kalacak.
- Result contract icin mevcut helper return type'ini dogrudan degistirmek yerine ayri wrapper/helper katmani daha guvenli yaklasim olarak belgelendi.
- Olasil future wrapper/helper adlari `try_write_json_ready_dict_to_file(...)`, `try_write_markdown_text_to_file(...)` ve `build_export_write_result(...)` olarak yalnizca plan ornegi seviyesinde not edildi; implementasyon yapilmadi.
- Onerilen result contract alanlari `success`, `output_path`, `error_code`, `error_message`, `skipped_reason`, `overwritten`, `attempted_path`, `allowed_root` ve `file_type` olarak genisletildi.
- JSON ve Markdown file-writing sonuclari icin ortak result contract kullanilabilecegi, `file_type` ve `error_code` alanlariyla JSON'a ozel ve Markdown'a ozel hatalarin ayrilabilecegi kararlastirildi.
- Path safety hata kategorileri `empty_path`, `directory_target`, `wrong_extension`, `path_traversal`, `outside_allowed_root`, `missing_parent` ve `non_export_area` gibi future `error_code` degerleriyle temsil edilebilir.
- Input validation hatalari non-dict JSON input icin `invalid_json_input`, serialize edilemeyen JSON input icin `json_not_serializable`, non-string Markdown input icin `invalid_markdown_input` gibi future `error_code` degerleriyle temsil edilebilir.
- `overwrite=False` ve hedef dosya mevcutken future wrapper'in `success=False`, `error_code="file_exists"`, `skipped_reason="overwrite_false"` ve `overwritten=False` gibi bir result dondurmesi planlandi; mevcut dusuk seviyeli helper ise `FileExistsError` davranisini koruyabilir.
- Explicit `overwrite=True` basarili yazimda `success=True`, `output_path`, `overwritten` ve bos hata alanlariyla gorunur kilinabilir; hedef dosyanin yeni mi guncellenmis mi oldugu result icinde ayrilabilir.
- Parent directory yoklugu, allowed-root disi path, wrong extension, unserializable JSON input, non-string Markdown input, permission ve IO hatalari future result contract icinde sessizce yutulmadan temsil edilmelidir.
- Handover QC ekran veya raporu ileride result contract'i export denemesi, hedef path, basari/hata, overwrite engeli, allowed-root hatasi ve kullanici aksiyonu gorunurlugu icin kullanabilir; bu kullanim manuel inceleme amaclidir.
- Result contract audit event uretmeyecek, backup/restore baslatmayacak, database/repository/API/GUI/CLI eklemeyecek, hard validation yapmayacak, `blocked` status uretmeyecek, diagnostic/soft validation report'u yeniden hesaplamayacak ve format helper ile file-writing helper ayrimini bozmayacak.
- Bu adim documentation-only implementation-plan adimidir; uygulama kodu, test dosyalari, helper davranisi, result contract implementasyonu, JSON/Markdown export dosyasi, audit event uretimi, backup/restore davranisi, database/repository/API/GUI/CLI, hard validation, `AuditEventRecord.__post_init__`, `FileAttachmentRecord`, `blocked` status, Podcast 027, commit, push veya ZIP staging eklenmedi.

## 159 Export Helper Result Contract Test Matrix Plan

- Adim 159, Adim 157-158'de planlanan export helper result contract yaklasimi ileride uygulanacaksa yazilacak testleri documentation-only olarak netlestirdi.
- Basari result contract testleri JSON ve Markdown export basarilarinda `success=True`, dogru `output_path`, dogru `file_type`, yeni dosyada `overwritten=False`, explicit overwrite senaryosunda `overwritten=True`, bos hata alanlari, normalize `attempted_path` ve dogru `allowed_root` beklentilerini kapsayacak.
- JSON input testleri JSON-ready dict basarisi, bos dict politikasi, non-dict input icin guvenli hata, serialize edilemeyen object icin hata contract'i, input immutability ve diagnostic/soft validation sonucunun yeniden hesaplanmamasini kapsayacak.
- Markdown input testleri string input basarisi, bos string politikasi, non-string input icin guvenli hata, Markdown iceriginin yeniden formatlanmamasi ve input immutability beklentilerini kapsayacak.
- Path safety testleri bos output path, klasor path, yanlis uzanti, `.json` / `.md` uzanti siniri, `..` traversal, allowed-root disi path, allowed-root ici basari, mixed separator, missing parent ve `.git`, `.env`, cache, pycache, ZIP/yedek alanlarina yazma reddi senaryolarini kapsayacak.
- Overwrite policy testleri hedef yokken `overwrite=False` basarisi, hedef varken `overwrite=False` yazmama, `success=False`, net `skipped_reason`, mevcut icerik korunumu, explicit `overwrite=True` guncellemesi ve yalniz hedef dosyanin degismesi beklentilerini kapsayacak.
- IO/permission testleri permission error, locked/erisilemez dosya ve disk/IO hata davranislarinin result contract'a sessiz basarisizlik olmadan tasinmasini planlayacak.
- Boundary regression testleri mevcut file-writing helper exception davranisinin korunmasini veya wrapper ile ayrilmasini, format helper davranislarinin degismemesini, diagnostic/soft validation report helper davranislarinin degismemesini, `AuditEventRecord.__post_init__` daraltilmamasini, `FileAttachmentRecord` davranisinin degismemesini, hard validation eklenmemesini ve `blocked` status uretilmemesini kapsayacak.
- Handover QC testleri hata contract'inin kullaniciya gosterilebilir veri tasimasini, `output_path` / `attempted_path` ayrimini, outside-allowed-root hatasini, `overwrite=False` skipped sonucunu, export basarisizliginin devir paketini otomatik bloke etmemesini ve audit event uretmemesini kapsayacak.
- Result contract alanlari icin `success`, `output_path`, `attempted_path`, `allowed_root`, `file_type`, `error_code`, `error_message`, `skipped_reason` ve `overwritten` alanlarinin basari/hata durumlarindaki test anlamlari belgelendi.
- Bu adim documentation-only test-matrix-plan adimidir; uygulama kodu, test dosyalari, helper davranisi, result contract implementasyonu, JSON/Markdown export dosyasi, audit event uretimi, backup/restore davranisi, database/repository/API/GUI/CLI, hard validation, `AuditEventRecord.__post_init__`, `FileAttachmentRecord`, `blocked` status, Podcast 027, commit, push veya ZIP staging eklenmedi.

## 160 Export Helper Result Contract API Boundary / Wrapper Plan

- Adim 160, mevcut exception tabanli file-writing helper davranisini bozmadan future result contract wrapper katmaninin nasil eklenebilecegini documentation-only olarak planladi.
- Mevcut `write_json_ready_dict_to_file(...)` ve `write_markdown_text_to_file(...)` helperlarinin dusuk seviyeli, exception tabanli ve basarida `Path` donduren davranisinin korunmasina karar verildi.
- Result contract icin mevcut helper return type'ini dogrudan degistirmek yerine ayri wrapper fonksiyonlar eklemek daha guvenli API boundary olarak belgelendi.
- Olasil future wrapper isimleri `try_write_json_ready_dict_to_file(...)` ve `try_write_markdown_text_to_file(...)` olarak planlandi; bu adimda implementasyon yapilmadi.
- Wrapper result contract alanlari `success`, `output_path`, `attempted_path`, `allowed_root`, `file_type`, `error_code`, `error_message`, `skipped_reason` ve `overwritten` olarak belirlendi.
- Wrapper inputlarinin mevcut helper inputlariyla uyumlu olmasi, diagnostic/soft validation sonucunu yeniden hesaplamamasi, format helper ciktisini degistirmemesi ve yalniz dosya yazma sonucunu raporlamasi kararlastirildi.
- Wrapper database/repository/API/GUI/CLI katmanina baglanmayacak, audit event uretmeyecek, backup/restore baslatmayacak, hard validation tetiklemeyecek ve `blocked` status uretmeyecek.
- Error mapping plani `TypeError -> input_type_error`, `ValueError -> path_or_extension_error`, `FileExistsError -> file_exists`, `PermissionError -> permission_error`, `OSError -> io_error` ve beklenmeyen exception icin `unexpected_error` olarak belgelendi.
- Ozel durumlar icin `overwrite=False` ve dosya mevcutken `success=False`, file-exists/skipped sonucu ve mevcut dosyanin korunmasi; `overwrite=True` basariliysa `success=True` ve `overwritten=True`; outside allowed root, path traversal, wrong extension ve parent missing icin net `error_code` beklentileri planlandi.
- Geriye uyumluluk icin mevcut `write_*` helperlar exception davranisini koruyacak, yeni `try_write_*` wrapperlar result contract dondurecek, eski testler kirilmayacak ve wrapper testleri ileride ayri eklenecek.
- Handover QC kullanimi wrapper sonucunu devir raporunda gorunur kilabilir; export basarisizligi otomatik blokaj, audit event, backup/restore veya hard validation anlami tasimayacak ve `blocked` status uretilmeyecek.
- Bu adim documentation-only API-boundary/wrapper-plan adimidir; uygulama kodu, test dosyalari, helper davranisi, result contract wrapper implementasyonu, JSON/Markdown export dosyasi, audit event uretimi, backup/restore davranisi, database/repository/API/GUI/CLI, hard validation, `AuditEventRecord.__post_init__`, `FileAttachmentRecord`, `blocked` status, Podcast 027, commit, push veya ZIP staging eklenmedi.

## 161 Export Helper Result Contract Wrapper Implementation Plan

- Adim 161, Adim 160'ta cizilen API boundary'ye bagli kalarak future result contract wrapper implementasyonunun sinirlarini documentation-only olarak netlestirdi.
- Mevcut `write_json_ready_dict_to_file(...)` ve `write_markdown_text_to_file(...)` helper davranislari korunacak; bu helperlar basarida `Path` donduren ve hatada exception firlatan dusuk seviyeli file-writing helperlar olarak kalacak.
- Future wrapper fonksiyonlari `try_write_json_ready_dict_to_file(...)` ve `try_write_markdown_text_to_file(...)` olarak planlandi; bu wrapperlar mevcut `write_*` helperlari cagirip exception yakalayarak result contract dondurebilir.
- Wrapperlar mevcut helperlarla ayni temel inputlari alabilir: JSON-ready dict, Markdown string, `output_path`, `allowed_root` ve `overwrite`.
- Wrapperlar basarili durumda result contract dondurecek, hata durumunda exception firlatmak yerine `success=False` result dondurecek, sessiz basarisizlik yapmayacak, dosya yazilmadiysa bunu acikca bildirecek, diagnostic/soft validation sonucunu yeniden hesaplamayacak, format helper ciktisini degistirmeyecek ve input mutate etmeyecek.
- Onerilen result contract alanlari `success`, `output_path`, `attempted_path`, `allowed_root`, `file_type`, `error_code`, `error_message`, `skipped_reason` ve `overwritten` olarak korundu.
- Basari sozlesmesi `success=True`, dolu `output_path`, dolu `attempted_path`, `file_type=json/markdown`, bos hata alanlari ve yeni dosya/overwrite senaryosuna gore `overwritten=False/True` beklentilerini tasir.
- Hata sozlesmesi `success=False`, dolu veya kontrollu `attempted_path`, bos veya kontrollu `output_path`, dolu `error_code`, kullaniciya gosterilebilir `error_message`, overwrite gibi atlama senaryolarinda `skipped_reason` ve dosya sistemi degismediyse bunun anlasilabilir olmasi beklentilerini tasir.
- Error mapping plani `TypeError -> input_type_error`, `ValueError -> path_or_extension_error`, `FileExistsError -> file_exists`, `PermissionError -> permission_error`, `OSError -> io_error` ve beklenmeyen exception icin `unexpected_error` olarak korundu; daha ozel `wrong_extension`, `path_traversal`, `outside_allowed_root`, `parent_missing`, `directory_path`, `empty_output_path`, `serialization_error` gibi error code ihtimalleri belgelendi.
- Overwrite davranisinda `overwrite=False` varsayilan kalacak; hedef dosya varsa wrapper `success=False`, net skipped/file-exists bilgisi ve `overwritten=False` dondurecek, mevcut dosya degismeyecek. `overwrite=True` basariliysa `success=True` ve `overwritten=True` beklenebilir.
- Path safety davranisinda outside allowed root, traversal, missing parent, wrong extension, directory path ve empty output path gibi hatalar result contract ile guvenli hata olarak tasinacak; `.git`, `.env`, cache, pycache, ZIP/yedek alanlari kapsam disi kalacak.
- Wrapper database/repository yazmayacak, audit event uretmeyecek, backup/restore baslatmayacak, API/GUI/CLI eklemeyecek, hard validation tetiklemeyecek, `blocked` status uretmeyecek, devir paketini otomatik bloke etmeyecek ve yalniz export yazma sonucunu raporlayacak.
- Geriye uyumluluk icin mevcut `write_*` helper testleri kirilmamali, yeni `try_write_*` wrapper testleri ayri yazilmali, exception tabanli helperlari kullanan kodlar ayni davranisi gormeli ve result contract isteyen ust katman wrapperlari kullanmalidir.
- Handover QC wrapper sonucunu "gozden gecirilecek export" gorunurlugu icin kullanabilir; `success=False` otomatik blokaj anlami tasimaz, `blocked` status uretilmez ve hata bilgisi insan incelemesine tasinir.
- Bu adim documentation-only wrapper-implementation-plan adimidir; uygulama kodu, test dosyalari, helper davranisi, result contract wrapper implementasyonu, JSON/Markdown export dosyasi, audit event uretimi, backup/restore davranisi, database/repository/API/GUI/CLI, hard validation, `AuditEventRecord.__post_init__`, `FileAttachmentRecord`, `blocked` status, Podcast 027, commit, push veya ZIP staging eklenmedi.

## 162 Export Helper Result Contract Wrapper Test Matrix Finalization

- Adim 162, future `try_write_json_ready_dict_to_file(...)` ve `try_write_markdown_text_to_file(...)` wrapperlari icin test matrix'i documentation-only olarak kesinlestirdi.
- Mevcut `write_*` helperlarin exception tabanli davranisinin korunacagi, wrapper testlerinin mevcut helper testlerinden ayri olacagi ve bu adimda implementasyon yapilmayacagi netlestirildi.
- Wrapper basari testleri JSON ve Markdown wrapperlarinda `success=True`, dogru `output_path`, dogru `attempted_path`, raporlanan `allowed_root`, dogru `file_type`, bos hata alanlari, yeni dosyada `overwritten=False` ve explicit overwrite senaryosunda `overwritten=True` beklentilerini kapsayacak.
- JSON wrapper input testleri JSON-ready dict basarisi, bos dict politikasi, non-dict input icin `success=False`, serialize edilemeyen object icin `success=False`, input immutability, diagnostic/soft validation sonucunun yeniden hesaplanmamasi ve format helper ciktisinin degistirilmemesini kapsayacak.
- Markdown wrapper input testleri string input basarisi, bos string politikasi, non-string input icin `success=False`, Markdown iceriginin yeniden formatlanmamasi ve input string'in degistirilmemesini kapsayacak.
- Path safety wrapper testleri bos output path, klasor path, yanlis uzanti, `.json` / `.md` siniri, path traversal, allowed-root disi path, allowed-root ici basari, missing parent, `.git`, `.env`, cache, pycache, ZIP/yedek reddi ve mixed separator davranisini kapsayacak.
- Overwrite wrapper testleri hedef yokken `overwrite=False` basarisi, hedef varken `overwrite=False` icin `success=False`, mevcut icerik korunumu, net `skipped_reason`, net `error_code`, hedef varken `overwrite=True` basarisi ve sadece hedef dosyanin degismesini kapsayacak.
- Error mapping testleri `TypeError -> input_type_error`, `ValueError -> path_or_extension_error` veya daha ozel kod, `FileExistsError -> file_exists`, `PermissionError -> permission_error`, `OSError -> io_error`, beklenmeyen exception icin `unexpected_error` ve ozel `wrong_extension`, `path_traversal`, `outside_allowed_root`, `parent_missing`, `directory_path`, `empty_output_path`, `serialization_error` gibi kodlari kapsayacak.
- Result contract schema testleri her result dict'in ayni anahtar setini tasimasini, `success` ve `overwritten` alanlarinin bool olmasini, `output_path`, `attempted_path`, `allowed_root`, `file_type`, `error_code`, `error_message` ve `skipped_reason` alanlarinin basari/hata durumlarinda sozlesmeye uygun dolmasini kapsayacak.
- Regression boundary testleri mevcut `write_*` helper exception davranisinin, formatter helperlarin, diagnostic/soft validation report helperlarin, `AuditEventRecord.__post_init__`, `FileAttachmentRecord`, hard validation disi davranisin, `blocked` status uretilmemesinin, backup/restore/API/GUI/CLI eklenmemesinin ve audit event uretilmemesinin korunmasini kapsayacak.
- Handover QC testleri `success=False` sonucunun otomatik blokaj olmamasini, `blocked` status uretilmemesini, hata bilgisinin insan incelemesine uygun tasinmasini, `output_path` / `attempted_path` ayrimini, outside allowed-root denemesinin raporlanmasini, overwrite skip sonucunun gorunur olmasini ve export basarisizliginin database/repository kaydi degistirmemesini kapsayacak.
- Bu adim documentation-only test-matrix-finalization adimidir; uygulama kodu, test dosyalari, helper davranisi, result contract wrapper implementasyonu, JSON/Markdown export dosyasi, audit event uretimi, backup/restore davranisi, database/repository/API/GUI/CLI, hard validation, `AuditEventRecord.__post_init__`, `FileAttachmentRecord`, `blocked` status, Podcast 027, commit, push veya ZIP staging eklenmedi.

## 163 Export Helper Result Contract Wrapper Implementation

- Adim 163, Adim 160-162'de planlanan result contract wrapper katmanini uyguladi.
- Mevcut `write_json_ready_dict_to_file(...)` ve `write_markdown_text_to_file(...)` helperlari dusuk seviyeli, exception tabanli helperlar olarak korundu; basarida `Path` dondurmeye ve hatada standart Python exception firlatmaya devam eder.
- Yeni `try_write_json_ready_dict_to_file(...)` ve `try_write_markdown_text_to_file(...)` wrapperlari eklendi; bu wrapperlar mevcut `write_*` helperlari cagirir, exception yakalar ve her durumda result dict dondurur.
- Wrapper result contract alanlari `success`, `output_path`, `attempted_path`, `allowed_root`, `file_type`, `error_code`, `error_message`, `skipped_reason` ve `overwritten` olarak sabitlendi.
- Basarili JSON ve Markdown yazimlari `success=True`, dogru `file_type`, dolu `output_path`, dolu `attempted_path`, bos hata alanlari ve yeni dosyada `overwritten=False` sonucu dondurur.
- Explicit `overwrite=True` ile mevcut hedef dosya basarili yazilirsa `overwritten=True` raporlanir; `overwrite=False` ve hedef dosya mevcutsa `success=False`, `error_code="file_exists"`, `skipped_reason="file_exists"` ve `overwritten=False` dondurulur.
- Error mapping basit ve test edilebilir tutuldu: non-dict/non-string input icin `input_type_error`, JSON serialization hatasi icin `serialization_error`, yanlis uzanti icin `wrong_extension`, path traversal icin `path_traversal`, allowed-root disi path icin `outside_allowed_root`, missing parent icin `parent_missing`, mevcut dosya icin `file_exists`, permission/IO hatalari icin `permission_error` / `io_error` ve beklenmeyen hata icin `unexpected_error`.
- Path safety, extension, traversal, non-export area, missing parent ve `allowed_root` kararlarinin mevcut `write_*` helperlarinda kalmasina karar verildi; wrapper bu kararlari yeniden hesaplamaz, yalniz result contract'a cevirir.
- JSON wrapper testleri basari, input immutability, non-dict input, serialize edilemeyen object, wrong extension, outside allowed root, path traversal, missing parent, `overwrite=False` mevcut dosya korumasi ve explicit overwrite senaryolarini kapsar.
- Markdown wrapper testleri basari, non-string input, wrong extension, outside allowed root, path traversal, missing parent, `overwrite=False` mevcut dosya korumasi ve explicit overwrite senaryolarini kapsar.
- Regression testi mevcut exception tabanli `write_*` helper davranisinin degismedigini kanitlar.
- Wrapperlar database/repository yazmaz, audit event uretmez, backup/restore baslatmaz, API/GUI/CLI eklemez, hard validation tetiklemez, `blocked` status uretmez ve export basarisizligini otomatik blokaj anlamina getirmez.
- JSON/Markdown export cikti dosyasi repo icine uretilmedi; `exports/` temiz tutuldu.
- Podcast 027 olusturulmadi; ZIP/yedek/cache dosyalari stage edilmedi.
- Bu adim kod + test + dokumantasyon adimidir; commit veya push yapilmadi.

## 164 Export Helper Result Contract Wrapper Usage Documentation

- Adim 164, Adim 163'te eklenen `try_write_json_ready_dict_to_file(...)` ve `try_write_markdown_text_to_file(...)` wrapperlarinin kullanim sinirini documentation-only olarak belgelendirdi.
- `write_json_ready_dict_to_file(...)` ve `write_markdown_text_to_file(...)` helperlarinin dusuk seviyeli, exception tabanli helperlar olarak kalacagi; `try_*` wrapperlarin ise result contract dondurecegi kullanim ayrimi netlestirildi.
- Diagnostic/soft validation report uretimi, format helper ile JSON-ready dict veya Markdown string uretilmesi, sonrasinda `write_*` veya `try_*` dosya yazma katmaninin secilmesi akisi belgelendi.
- JSON wrapper kullaniminda JSON-ready dict input, `.json` uzantili explicit output path, optional `allowed_root`, `overwrite=False` varsayilani, `success=True` ve `success=False` yorumlari aciklandi.
- Markdown wrapper kullaniminda Markdown string input, `.md` uzantili explicit output path, optional `allowed_root`, Markdown iceriginin yeniden formatlanmamasi ve `success=False` sonucunun otomatik blokaj olmamasi aciklandi.
- Result contract alanlari `success`, `output_path`, `attempted_path`, `allowed_root`, `file_type`, `error_code`, `error_message`, `skipped_reason` ve `overwritten` icin basari/hata/handover QC yorumlari belgelendi.
- Error code yorumlari `input_type_error`, `path_or_extension_error`, `file_exists`, `permission_error`, `io_error`, `unexpected_error`, `wrong_extension`, `path_traversal`, `outside_allowed_root`, `parent_missing`, `directory_path`, `empty_output_path` ve `serialization_error` icin aciklandi.
- `overwrite=False` guvenli varsayilan olarak korundu; mevcut dosya varsa `success=False`, `file_exists`, `skipped_reason` ve mevcut icerik korunumu yorumlari belgelendi.
- `overwrite=True` bilincli ve explicit tercih olarak anlatildi; basarili overwrite sonucunda `overwritten=True` alaninin handover QC tarafindan nasil okunacagi netlestirildi.
- Path safety kullaniminda explicit output path, mumkunse `allowed_root`, allowed-root disi yazim, path traversal, missing parent ve `.git`, `.env`, cache, pycache, ZIP/yedek alanlarinin kapsam disi kalmasi belgelendi.
- Handover QC yorumunda `success=True` export dosyasinin yazildigini, `success=False` export yaziminin basarisiz veya skipped oldugunu, fakat devir paketini otomatik bloke etmedigini ve `blocked` status uretmedigini netlestirdi.
- Wrapperlarin diagnostic/soft validation sonucunu yeniden hesaplamayacagi, format helper ciktisini degistirmeyecegi, input mutate etmeyecegi, database/repository yazmayacagi, audit event uretmeyecegi, backup/restore baslatmayacagi, API/GUI/CLI eklemeyecegi, hard validation tetiklemeyecegi ve `blocked` status uretmeyecegi yinelendi.
- Bu adim documentation-only adimidir; `app/models.py`, `tests/test_models.py`, helper davranisi, yeni test, JSON/Markdown export cikti dosyasi, Podcast 027, commit veya push eklenmedi.

## Podcast 027 Adim 157-161 NotebookLM Podcast Notu

- Podcast 027, Adim 157-161 araligini NotebookLM podcast uretimine uygun documentation-only not olarak ozetledi.
- Kapsam yalniz Adim 157 Export Helper Error / Result Contract Plan, Adim 158 Export Helper Result Contract Implementation Plan, Adim 159 Export Helper Result Contract Test Matrix Plan, Adim 160 Export Helper Result Contract API Boundary / Wrapper Plan ve Adim 161 Export Helper Result Contract Wrapper Implementation Plan olarak belirlendi.
- Adim 162, Adim 163, Adim 164 ve sonrasi podcast kapsam disinda tutuldu.
- Ana tema export helper error/result contract yapisinin planlanmasi, sinirlandirilmasi ve future wrapper implementasyonuna hazirlanmasi olarak kaydedildi.
- Result contract yaklasimi basari/basarisizlik durumunun standart raporlanmasi, `error_code`, `error_message`, `skipped_reason`, `attempted_path`, `output_path`, `allowed_root`, `file_type` ve `overwritten` alanlariyla okunabilir hale gelmesi olarak aciklandi.
- Exception firlatan dusuk seviyeli `write_json_ready_dict_to_file(...)` ve `write_markdown_text_to_file(...)` helperlari ile future result contract dondurebilecek `try_write_json_ready_dict_to_file(...)` ve `try_write_markdown_text_to_file(...)` wrapper katmani ayrimi anlatildi.
- CSE veri omurgasi acisindan export davranisinin daha kontrollu hale gelmesi, hata raporlamasinin standartlasmasi ve dosya yazma sonucunun ust katmana okunabilir bicimde tasinmasi vurgulandi.
- Bu gorunurlugun backup/restore, API, GUI, CLI, otomasyon, audit event uretimi, hard validation veya `blocked` status olmadigi tekrarlandi.
- Bu adim documentation-only podcast adimidir; uygulama kodu, test dosyalari, export helper davranisi, validasyon mantigi, JSON/Markdown export cikti dosyasi, hard validation, `blocked` status, backup/restore/API/GUI/CLI, audit event uretimi, ZIP staging, commit veya push eklenmedi.

## 165 Export Helper Result Contract Wrapper Usage Examples

- Adim 165, Adim 163'te eklenen `try_write_json_ready_dict_to_file(...)` ve `try_write_markdown_text_to_file(...)` wrapper helperlari icin kullanim orneklerini ve boundary/example standardini documentation-only olarak belgelendirdi.
- Wrapper helperlarin export dosya yazma sonucunu standart ve okunabilir result contract ile ust katmana tasidigi; kullanici, handover QC, future admin/debug ekranlari ve guvenli raporlama akislari icin sonuc gorunurlugu sagladigi aciklandi.
- `write_json_ready_dict_to_file(...)` ve `write_markdown_text_to_file(...)` helperlarinin dusuk seviyeli, exception tabanli ve basarida `Path` donduren helperlar olarak korunacagi; `try_*` wrapperlarin ise result contract donduren ayri katman oldugu yinelendi.
- Wrapper helperlarin mevcut dusuk seviye helper davranisini daraltmayacagi, legacy kullanimlari kirmayacagi ve exception tabanli akis isteyen kodlarin `write_*` helperlari kullanmaya devam edebilecegi belgelendi.
- Basarili JSON-ready dict export sonucu, basarili Markdown export sonucu, gecersiz/izin verilmeyen path, var olan dosyada `overwrite=False`, explicit `overwrite=True`, missing parent directory, serialize edilemeyen JSON input, gecersiz Markdown input, kullaniciya gosterilecek kisa sonuc mesaji ve handover QC summary yorumlari orneklerle aciklandi.
- `success=False` sonucunun export yaziminin basarisiz veya skipped oldugunu gosterdigi; devir paketini otomatik bloke etmedigi, hard validation veya `blocked` status anlamina gelmedigi tekrarlandi.
- Future test example standardization icin `test_try_write_json_ready_dict_to_file_returns_success_contract`, `test_try_write_markdown_text_to_file_returns_success_contract`, `test_try_write_json_ready_dict_to_file_returns_error_contract_for_invalid_path`, `test_try_write_markdown_text_to_file_does_not_mutate_input` ve `test_low_level_write_helpers_keep_exception_behavior` gibi ornek isimler belgelendi; test dosyasi olusturulmadi veya degistirilmedi.
- Bu adim documentation-only adimidir; uygulama kodu, test dosyalari, existing test matrix, export helper davranisi, JSON/Markdown export cikti dosyasi, `exports/` icerigi, hard validation, `blocked` status, backup/restore/API/GUI/CLI, audit event uretimi, database/repository davranisi, ZIP staging, commit veya push eklenmedi.

## 166 Export Helper Result Contract Wrapper Test Implementation

- Adim 166, Adim 163'te eklenen `try_write_json_ready_dict_to_file(...)` ve `try_write_markdown_text_to_file(...)` wrapper helperlarinin mevcut result contract davranisini testlerle daha gorunur hale getirdi.
- Yeni result contract semasi icat edilmedi; mevcut implementation ve mevcut testlerde kullanilan `success`, `output_path`, `attempted_path`, `allowed_root`, `file_type`, `error_code`, `error_message`, `skipped_reason` ve `overwritten` alanlari esas alindi.
- JSON wrapper icin basarili yazma sonucunda sabit success contract dondurdugu test edildi.
- Markdown wrapper icin basarili yazma sonucunda sabit success contract dondurdugu test edildi.
- Invalid path / missing parent senaryosunda JSON wrapper'in exception firlatmak yerine `success=False`, `error_code="parent_missing"` ve okunabilir hata alaniyla failure contract dondurdugu test edildi.
- Wrapper helperlarin JSON-ready dict ve Markdown text inputlarini mutate etmedigi test edildi.
- Dusuk seviye `write_json_ready_dict_to_file(...)` ve `write_markdown_text_to_file(...)` helperlarinin file-exists senaryosunda `FileExistsError` firlatan exception tabanli davranisini korudugu; wrapperlarin ayni senaryoyu failure contract olarak raporladigi regression testiyle sabitlendi.
- Testler file-writing davranisini yalniz pytest `tmp_path` altinda dogrular; repo icindeki `exports/` dizinine cikti birakilmaz.
- Bu adim test + dokumantasyon adimidir; `app/models.py`, production helper davranisi, helper imzalari, repo icinde JSON/Markdown export cikti dosyasi, hard validation, `blocked` status, backup/restore/API/GUI/CLI, audit event uretimi, database/repository davranisi, ZIP staging, commit veya push eklenmedi.

## 167 Export Helper Result Contract Wrapper Integration Boundary

- Adim 167, Adim 166'da testlerle gorunur hale gelen wrapper result contract davranisinin kullanim ve entegrasyon sinirini documentation-only olarak belgelendirdi.
- Testlerden sonra sabitlenen davranislar JSON success contract, Markdown success contract, invalid path failure contract, input immutability ve dusuk seviye `write_*` helperlarin exception tabanli davranisinin korunmasi olarak kaydedildi.
- Basarisiz dosya yazma/path senaryolarinin wrapper seviyesinde exception olarak ust katmana firlatilmayacagi; okunabilir `success=False`, `error_code`, `error_message`, `attempted_path`, `skipped_reason` ve `overwritten` alanlariyla yorumlanacagi aciklandi.
- Wrapper result contract'in ileride handover QC, admin/debug gorunumu, guvenli export ozeti veya kullaniciya gosterilecek kisa sonuc mesajlari icin kullanilabilecegi belgelendi.
- Bu adimda GUI/API/CLI entegrasyonu yapilmadi; result contract yorumlama isinin ayri katman olarak kalacagi ve wrapper helper'in dogrudan backup/restore veya audit event sistemi olmadigi netlestirildi.
- Basarili contract'in export yazma isleminin kontrollu tamamlandigini; failure/error contract'in ise ust katmana guvenli aciklama sunmak icin kullanilacagini, fakat otomatik duzeltme, hard validation veya devir paketini otomatik bloke etme anlami tasimayacagini belirtti.
- Hard validation, `blocked` status, backup/restore/API/GUI/CLI, audit event uretimi, database/repository davranisi, repo icinde export cikti dosyasi, ZIP/cache staging ve dusuk seviye helper davranisi degisikligi kapsam disi tutuldu.
- Sonraki olasi adim olarak Adim 168 icin export helper result contract summary/report layer plan veya handover QC export result interpretation plan onerildi; Adim 168 bu adimda baslatilmadi.

## 168 Export Helper Result Contract Summary Report Layer Plan

- Adim 168, Adim 163-167 araliginda olusturulan ve testlerle sabitlenen export helper result contract wrapper davranisinin ileride nasil ozetlenebilecegini ve raporlanabilecegini documentation-only olarak planladi.
- Planlanan summary/report layer amaci wrapper result contract ciktilarindan okunabilir ozet uretmek, basari ve hata durumlarini ust katmana kisa, standart ve yorumlanabilir sekilde tasimak, handover QC/admin-debug/kullanici mesaji icin zemin hazirlamak olarak belirlendi.
- Bu katmanin `write_*` file-writing helperlarinin veya `try_*` wrapper helperlarinin yerine gecmeyecegi; yalniz mevcut result contract'i yorumlayan ayri bir katman olabilecegi kaydedildi.
- Olasil ilerideki helper fikirleri `build_export_result_summary(...)`, `build_export_result_report(...)` ve `format_export_result_summary_as_markdown(...)` olarak yalniz plan seviyesinde tartisildi; implementasyon yapilmadi ve helper imzasi kilitlenmedi.
- Plan duzeyinde `operation`, `status`, `path`, `message`, `error_type`, `safe_for_user_message`, `technical_detail` ve `next_action_hint` alanlari tartisildi; bu alanlar zorunlu sema olarak kilitlenmedi.
- Handover QC yorumunda basarili export icin "export uretildi", basarisiz export icin "gozden gecirilecek export sonucu" dilinin kullanilabilecegi; failure contract'in kayitlari gecersiz yapmayacagi, devir paketini otomatik bloke etmeyecegi ve hard validation anlami tasimayacagi yinelendi.
- Future test matrix planinda success contract summary, failure contract summary, mixed result list summary, missing optional fields, unsupported input, input immutability, no blocked status ve no recomputation of low-level result basliklari belgelendi; test yazilmadi.
- Bu adim documentation-only plan adimidir; uygulama kodu, test dosyalari, existing helper davranisi, JSON/Markdown export cikti dosyasi, hard validation, `blocked` status, backup/restore/API/GUI/CLI, audit event uretimi, database/repository davranisi, ZIP/cache staging, commit veya push eklenmedi.

## 169 Export Result Summary Report API Boundary and Test Matrix Plan

- Adim 169, Adim 168'de planlanan export result summary/report layer icin API boundary ve future test matrix'i documentation-only olarak netlestirdi.
- Future summary/report helper'in yalniz wrapper result contract veya wrapper result contract listesi almasi gerektigi; dosya yazma islemi yapmayacagi, export helper cagirmayacagi, path safety kararini yeniden hesaplamayacagi, dusuk seviye `write_*` helperlarin yerine gecmeyecegi ve yalniz mevcut result contract verisini yorumlayacagi belgelendi.
- Plan duzeyinde `build_export_result_summary(...)`, `build_export_result_report(...)` ve `format_export_result_summary_as_markdown(...)` isimleri degerlendirildi; implementasyon yapilmadi, helper imzasi veya zorunlu output semasi kilitlenmedi.
- Output siniri JSON-ready dict, Markdown text veya handover QC summary olarak plan seviyesinde tartisildi; output'un yalniz raporlama/yorumlama amacli kalacagi, kayitlari gecersiz saymayacagi, devir paketini otomatik bloke etmeyecegi ve hard validation anlami tasimayacagi kaydedildi.
- Handover QC yorumunda basarili export sonucunun gorunur olabilecegi, basarisiz export sonucunun `review required` veya `attention` olarak yorumlanabilecegi, ancak `blocked` status uretilmeyecegi ve failure contract'in otomatik duzeltme veya migration baslatmayacagi belirtildi.
- Future test matrix basliklari success contract summary, failure contract summary, mixed success/failure result list, missing optional fields, unknown status, unsupported input, input immutability, no file writing, no blocked status, no hard validation, no recomputation of wrapper result, markdown summary contains safe user message ve technical detail is preserved but not overused in user-facing summary olarak belgelendi.
- Bu adim documentation-only plan adimidir; uygulama kodu, test dosyalari, existing helper davranisi, JSON/Markdown export cikti dosyasi, hard validation, `blocked` status, backup/restore/API/GUI/CLI, audit event uretimi, database/repository davranisi, ZIP/cache staging, commit veya push eklenmedi.

## Issue 92 - Ayni timestamp observation event sirasi

- Observation event gecmisi once `occurred_at`, esitlik halinde SQLite `rowid` ile siralanacak.
- Rastgele UUID event `id` degeri kronolojik tie-breaker olarak kullanilmayacak.
- `observation_events` append-only oldugu ve insert islemleri `rowid` vermedigi icin `rowid`, ayni timestamp icindeki eklenme sirasini temsil edecek.
- Cozum mevcut tabloyu, event ID/timestamp/payload degerlerini degistirmeyecek ve schema migration gerektirmeyecek.
- Reopen ve SQLite backup/restore sonrasi sira, ters leksikografik UUID kullanan regresyon testleriyle korunacak.

## Issue 93 - Tek tik dogrulanmis web yedegi

- Web yedekleri Windows dosya kilidi ve streaming cleanup yarisi olusturmamak icin `CSE_DATA_ROOT/backups/` altinda managed artifact olarak saklanacak.
- Artifact yolu kullanici girdisinden uretilmeyecek; canonical UUID artifact kimligi sunucu tarafinda olusturulacak ve download route ayni kimligi yeniden dogrulayacak.
- Mevcut `BackupService` yedegi olusturup dogrulayacak; download route artifact'i tekrar dogrulamadan dosyayi sunmayacak.
- Managed `backups/` klasoru backup girdisi olmayacak; mevcut motor yalniz SQLite snapshot ve veritabaninda kayitli attachment dosyalarini arşivleyecek.
- Basarisiz backup teknik ayrinti veya path gostermeden guvenli Turkce mesajla fail-closed olacak; restore UI, retention ve otomatik silme eklenmeyecek.

## Issue 115 - RoutineApplicationService ve Yedi Gunluk Lazy Backfill

- Routine orchestration ayri `app/application/routines.py` modulunde tutulacak; mevcut follow-up service gereksiz buyutulmeyecek.
- Command/query degerleri frozen application value object olacak; transport veya UI modeli olmayacak.
- Template title whitespace'i kararlilastirilacak, optional text trim edilip bos sonuc `None` olacak; timezone kullanici girdisi olmayacak ve `Europe/Istanbul` kalacak.
- Template update yalniz command allowlist'ini degistirecek; no-op clock/UUID/event tuketmeyecek ve gercek update event'i alfabetik exact `changed_fields` tasiyacak.
- `ensure_occurrences`, canonical `as_of_utc` anindan bugun dahil son yedi Istanbul yerel gununu uretecek; future veya daha eski eksik gun icat etmeyecek.
- Gecmis eksik occurrence once open revision 1 ve created event olarak, sonra ayni transaction'da closed/missed revision 2 ve missed event olarak yazilacak.
- Existing natural-key occurrence tamamen idempotent olacak; application pre-check ile repository `add_if_absent`/SQLite unique constraint birlikte savunma saglayacak.
- List/view sorgulari salt-okunur kalacak ve otomatik ensure/backfill calistirmayacak.
- Snooze, close ve reopen schedule snapshot alanlarini degistirmeyecek; kullanici `missed` sonucu veremeyecek.
- Schema/migration/mapping/repository/UoW portlari genisletilmeyecek; mevcut `BEGIN IMMEDIATE` transaction ve append-only event repository'leri kullanilacak.
- Web/UI, scheduler/notification, backup/export, mobile/offline/sync ve gercek kullanici data root'u ayri gorevlere birakilacak.

## Issue 117 - Backup/Restore Uyumlulugu ve Resmi Export Izolasyonu

- Backup ve daily export format surumleri `1`, exact manifest field setleri, ZIP entry adlari ve observation/event/record count anlamlari degismeyecek.
- Restore edilebilir schema allowlist'i `(2, 3, 4)` olacak; schema degeri integer olmak zorunda olacak ve manifest ile embedded `schema_migrations` zinciri birebir eslesecek.
- `verify_backup` migration calistirmayacak; embedded database ve attachment'lari private temporary alanda read-only integrity, exact migration, count ve reconciliation kontrollerinden gecirecek.
- Schema 2 veya 3 migration'i yalniz restore'un private temporary database'i uzerinde calisacak; source archive, source database, aktif data root veya var olan target uzerinde in-place migration yapilmayacak.
- Restore target'i ancak pre-migration ve post-migration database/attachment kontrolleri ile schema 4 repository okumalarinin tamami gectikten sonra tek atomic move ile gorunur olacak.
- Schema 4 tracking verisi ayri manifest count alanlariyla degil, SQLite snapshot digest'i ve restore sonrasi aggregate/event kabul testleriyle korunacak.
- Resmi daily export kodu yalniz mevcut project/observation/attachment/observation-event omurgasini okumaya devam edecek; tracking verili ve verisiz koklerin deterministic ZIP byte esitligi executable guvence olacak.
- Export izolasyon testi sizinti bulmadigi icin `app/operations/exports.py` degistirilmeyecek.

## Issue 119 - İlk Test Edilebilir PC Saha Takibi Arayüzü

- İlk PC yüzeyi yeni domain, persistence veya operations sözleşmesi üretmeyecek; mevcut `ObservationApplicationService`, `FollowUpApplicationService` ve `RoutineApplicationService` web katmanında compose edilecek.
- Üç application service aynı explicit data root içindeki tek `cse.sqlite3` dosyasını kullanacak; global singleton, ikinci database, background thread veya scheduler eklenmeyecek.
- `/` başlangıcı `/today` görünümüne yönlenecek; ana navigasyon Bugün, Unutma Kutusu, Rutinler ve Gözlemler yüzeylerini koruyacak.
- Bugün görünümü her request için tek canonical `now_utc` üretecek; routine occurrence ensure işlemi bu değerle çağrılacak ve listeler aynı zaman sınırını paylaşacak.
- “Şimdi ilgilen” yeni bir kalıcı status olmayacak; mevcut follow-up query görünümünden okunacak.
- Hızlı create formu yalnız `capture_text` taşıyacak ve yalnız `CreateFollowUp` kullanacak; başlık, status, proje veya zaman create formuna eklenmeyecek.
- Başarılı mutation'lar Post/Redirect/Get uygulayacak; refresh aynı POST'u veya event'i istemeden tekrar üretmeyecek.
- Kullanıcı `datetime-local` girdisi `Europe/Istanbul` kabul edilip application service'e canonical UTC olarak verilecek; timezone kullanıcı seçimi olmayacak.
- Web mutation formları hidden `expected_revision` taşıyacak; stale revision HTTP 409 ve yenileme mesajı, validation HTTP 400 ve güvenli kullanıcı mesajı üretecek.
- Follow-up detail ilk `capture_text` değerini değişmez kanıt olarak gösterecek; storage enum/event değerleri değişmeden Türkçe sunum sözlüğü kullanılacak.
- Routine occurrence mutation'ları schedule snapshot alanlarını değiştirmeyecek; `/today` refresh aynı template + yerel tarih occurrence/event'ini çoğaltmayacak.
- UI server-rendered HTML/CSS kalacak; SPA, UI framework, haricî CDN, client-side state store veya JavaScript zorunluluğu eklenmeyecek.
- Erişilebilirlik tabanı en az 44 px hedef, görünür `:focus-visible` durumu ve 640 px altında tek kolon responsive düzen olacak.
- İlk PC kabul akışı temporary data root üzerinde app restart, revision/history kalıcılığı, observation regresyonu, backup ve resmî export izolasyonunu birlikte kanıtlayacak.
- Resmî günlük export yalnız project/observation/attachment/observation-event omurgasını okuyacak; follow-up ve routine verisi varsayılan resmî export'a sızmayacak.
- Schema `4`, domain/application/persistence/operations sözleşmeleri, backup/export formatları, requirements ve workflow bu UI görevinde değişmeyecek.
- Mobile runtime, PWA, offline, sync, notification, auth ve gerçek kullanıcı data root'u ilk test edilebilir PC sürümünün kapsamı dışında kalacak.
- Issue #119 branch'i testleri geçmiş ve PR incelemesine hazır olabilir; PR oluşturulmadan ve merge edilmeden repository state merge claim taşımayacak.

## Issue 141 — Repository Truth ve Execution Roadmap Kararları

- Güncel merged head, Issue #119 / PR #126 / merge commit `1d4b2b7f9ace5e7d474c4893d24404ceae2faede` olarak kabul edilecek.
- Issue #127 execution programı, bağlayıcı ürün Epic'i #105'i değiştirmeden uygulanabilir bağımlılık ve faz sırası sağlar.
- Issue #128–#140 açık faz backlog'udur; bu Issue'ların açık olması aynı anda aktif production işi oldukları anlamına gelmez.
- Aynı anda yalnız bir aktif production implementation görevi kuralı korunur.
- İlk aktif iş Issue #141 repository truth ve roadmap/state senkronizasyonudur; bu iş production davranışı eklemez.
- Tek Hafıza UX ve `private | project` kapsamı, `MemoryIndex` / `RecordRef` read-model'i ile Backup / Hafızayı İndir / Proje Paketi ayrımları sonraki ayrı ADR Issue'larında kesinleştirilecek; Issue #141 veri modeli davranışını değiştirmez.
- Mevcut kişisel takip ile proje/resmî kayıt ayrımı erişim rolü değil export/devir kapsamı olarak korunur; kişisel follow-up/routine verisi bu görevde resmî günlük export'a dahil edilmez.
- Schema sürümü `4`, backup formatı `1` ve günlük export formatı `1` olarak korunur.

## Issue 173 — Olay Zamanı Sözleşmesi ve Migration Preflight

- `observed_at` / `occurred_at` olayın gerçekleştiği an, `created_at` ilk
  kalıcı CSE girişi, `updated_at` son başarılı mutation anıdır.
- Yeni kalıcı timestamp üretimi timezone-aware UTC seconds
  `YYYY-MM-DDTHH:MM:SSZ`; user presentation `Europe/Istanbul` olur.
- Explicit non-UTC offset normalize edilebilir; naive/invalid değer sessizce
  onarılmaz. Legacy six-microsecond UTC read-compatible fakat preflight
  warning'idir.
- Historical event/entry/update/lifecycle zamanları sabit `as_of` sonrasında
  blocker; schedule/attention/deadline gelecekte olabilir.
- Migration preflight yalnız çağıranın açıkça verdiği `temporary | test`
  SQLite dosyasını `mode=ro` + `query_only` ile okur; data-root discovery,
  migration, schema change ve row rewrite yapmaz.
- Preflight schema 2/3/4 timestamp allowlist'ini count/min/max/mapping ve
  warning/blocker bulgularıyla JSON-ready raporlar; raw değer, row ID, business
  content veya database path sızdırmaz.
- Schema `4`, Backup format `1`, restore allowlist `(2,3,4)` ve Günlük Çıktı
  format `1` değişmez. P1.02, archive/unarchive ve MemoryIndex ayrı Issue'dur.

## Issue 175 — Geriye Dönük Observation Create Contract

- Observation create application sınırı, UI/transport alanları yerine frozen
  `CreateObservation` command value object kabul edecek.
- `observed_at` olayın sahada gerçekleştiği an; `created_at` kaydın CSE'ye
  kalıcı giriş anıdır. Explicit geçmiş olay zamanı entry time ile ezilmeyecek.
- Omitted `observed_at`, create işleminin tek canonical clock okumasına eşit
  olacak. Aynı clock değeri `created_at`, `updated_at`, created event
  `occurred_at` ve attachment metadata `created_at` için kullanılacak.
- Yeni write girdisi yalnız UTC seconds `YYYY-MM-DDTHH:MM:SSZ` kabul edecek;
  legacy six-microsecond read compatibility yeni command write izni değildir.
- `TimestampRole.EVENT_TIME` future policy, UUID üretimi, attachment staging ve
  Unit of Work açılmadan önce uygulanacak.
- `observation_created` payload'ı `attachment_ids`, `revision`, `status`,
  `observed_at` ve `created_at` alanlarını taşıyarak olay/entry ayrımını sonraki
  Ajanda projection'ları için kayıpsız koruyacak.
- Existing attachment finalize ile SQLite commit sırası ve hata sonrası
  cleanup/reconciliation davranışı değişmeyecek.
- Schema/migration/repository, Backup/Günlük Çıktı wire formatı, yeni web formu,
  route, Ajanda UI, archive/scope, MemoryIndex ve security bu Issue'ya
  eklenmeyecek.

## Issue 180 — Flutter Mobil Temel

- Release 0.1 ana ürün runtime'ı `mobile/` altında tek Dart codebase kullanan
  Flutter Android/iOS uygulaması olacak; Python/Flask mobil runtime bağımlılığı
  olmayacak.
- Telefon ilk sürümde device of truth olacak; database ve attachment dizinleri
  platform application-support sandbox'ında tutulacak. Cloud sync ve otomatik
  masaüstü veri migration'ı yapılmayacak.
- Uygulama sürümü `0.1.0+1`, release kimliği
  `com.faliardic.chiefsiteengineer`; debug kimliği `.debug` suffix'iyle ayrı
  olacak. Dart path kökleri de `debug | release` olarak ayrılacak.
- Mobil schema namespace'i Python schema'dan bağımsız `1` ile başlayacak.
  `schema_versions` ve SQLite `user_version` tek migration transaction'ında
  ilerleyecek; başarısız migration partial tablo/history bırakmayacak.
- İlk kalıcılık kanıtı `mobile-foundation-v1` smoke kaydı olacak. Restart kaydı
  güncellemeyecek; ilk canonical `created_at` değerini koruyacak.
- Mobil timestamp write/read sözleşmesi exact UTC seconds `...Z` olacak;
  `Europe/Istanbul` yalnız presentation sınırıdır. Naive, invalid, fractional
  veya canonical olmayan mobile storage değeri fail-closed reddedilecek.
- Bootstrap database/path bozulmasında implementation detail, absolute path
  veya raw exception göstermeyecek; kullanıcıya hiçbir kayıt yazılmadığını
  belirten güvenli mesaj sunacak.
- Notification, attachment picker ve export davranışları platform portları
  arkasında kalacak. Permission denied/unavailable durumda gerçek platform
  mutation çağrılmayacak ve crash üretilmeyecek.
- Android debug ID ve release ID hem OS sandbox'ı hem Dart environment path'i
  seviyesinde ayrılacak. Release AAB'ye debug signing bağlanmayacak; keystore ve
  secret repository dışında kalacak.
- iOS project/bundle/plist/scheme tracked kalacak; Windows'ta statik config
  doğrulanacak. Native archive ve App Store signing macOS, Xcode ve Apple
  Developer hesabı gerektiren açık release blocker'ı olarak tutulacak.
- Ajanda, Hatırlatıcı, Puantaj ve Beton Paketi bu Issue'da yalnız navigasyon ve
  `Hazırlanıyor` durumu taşır; gerçek özellik davranışları ayrı mobil dikey
  dilimlerde uygulanacak.
- Python schema `4`, Backup format `1`, restore allowlist `(2,3,4)` ve Günlük
  Çıktı format `1` değiştirilmez; mobil schema veya local export dizini bu
  formatları sessizce genişletmez.

## Issue 179 — Mobil Ajanda Logu ve Bağlı Hatırlatıcı

- Ajanda source-of-truth'u mobil `field_observations`; reminder source-of-truth'u
  mobil `follow_up_items` olacak. Python tabloları mobil runtime bağımlılığı
  değil, anlam ve test oracle'ıdır.
- Mobil schema `2`, schema `1` üzerine tek atomik migration'dır; project, log,
  reminder ve append-only event tablolarını ekler, smoke verisini korur.
- Olay zamanı `observed_at`, CSE giriş zamanı `created_at`, son değişiklik
  `updated_at` olarak ayrı kalır. Storage exact UTC seconds, presentation ve
  gün sınırı `Europe/Istanbul` olur.
- Log create ve reminder create immutable command kabul eder; create clock'u
  yalnız bir kez okunur. Retry boyunca record/event UUID değişmez.
- Project/source doğrulaması ilk mutation'dan önce tamamlanır. Reminder row,
  source/project link, schedule ve creation event tek SQLite transaction'dadır.
- Event geçmişleri update/delete trigger'larıyla append-only; project/log/
  reminder fiziksel silme trigger'larıyla korunur. Revision `1` ile başlar.
- Ajanda sırası `observed_at ASC, created_at ASC, id ASC`; arama SQLite wildcard
  semantiği kullanmadan `instr` ile literal çalışır.
- Aynı application service'in SQLite açılışları shell sayfalarının eşzamanlı
  init yarışını önlemek için seri kuyruğa alınır; transaction atomikliği korunur.
- Ajanda ve Hatırlatıcı ekranları aynı Dart application sözleşmesini Android ve
  iOS'ta kullanır; Flask route, network veya Python runtime çağrısı yoktur.
- Attachment/fotoğraf, OS notification delivery, tam edit/archive ve tam
  reminder lifecycle bu Issue'ya eklenmez.
- Python schema `4`, Backup format `1`, restore allowlist `(2,3,4)` ve Günlük
  Çıktı format `1` değişmez; mobil schema `2` ayrı namespace'tir.

## Issue 183 — Mobil Reminder Yaşam Döngüsü ve Yerel Bildirimler

- Reminder business source-of-truth'u mobil SQLite `follow_up_items`;
  Android/iOS pending notification listesi yeniden üretilebilir teslim
  katmanıdır. Notification dismiss reminder status'unu değiştirmez.
- Mobil schema `2 → 3`, v2 Ajanda/reminder/event satırlarını koruyan atomik
  table rebuild migration'dır. Python schema `4`, Backup `1`, restore allowlist
  `(2, 3, 4)` ve Günlük Çıktı `1` değiştirilmez.
- Standalone reminder project/source taşımayabilir. Source observation varsa
  project zorunludur ve `(observation_id, project_id)` composite foreign key
  aynı projeyi zorunlu kılar.
- Bütün lifecycle mutation'ları immutable command + expected revision kullanır.
  Stale revision fail-closed; no-op revision/event artırmaz; row ve append-only
  sequence event tek SQLite transaction'da yazılır.
- Platform notification integer ID, UUID'den deterministik 31-bit aday ve UNIQUE
  linear probe ile collision-safe ayrılır.
- Platform teslim durumu ayrı `reminder_notification_bindings` tablosundadır.
  Raw exception, cihaz kimliği, path, secret veya kullanıcı içeriği saklanmaz;
  yalnız sabit safe error code kullanılır.
- Permission, plugin veya capacity failure SQLite reminder transaction'ını geri
  almaz. Açık kayıt due/overdue görünmeye devam eder.
- Bootstrap reconciliation eksik pending'i yeniden kurar; stale, duplicate,
  orphan, inbox ve terminal pending kayıtlarını iptal eder. iOS kapasitesinde en
  yakın due kayıtlar deterministik seçilir; diğerleri kaybolmaz.
- Android schedule `inexactAllowWhileIdle` kullanır. `USE_EXACT_ALARM` ve
  `SCHEDULE_EXACT_ALARM` izinleri bu ürün diliminde yasaktır.
- Android/iOS aynı Dart domain/application sözleşmesini kullanır. Payload yalnız
  doğrulanmış reminder UUID'siyle detaya gider; invalid payload navigation
  üretmez.
- Recurring routine, Puantaj, Beton Paketi, attachment/fotoğraf, cloud/auth,
  push/server notification, store submission ve signing kapsam dışıdır.

## Issue 185 — Mobil Günlük Puantaj ve Personel

- Puantaj source-of-truth'u mobil SQLite'tır. Bir proje + İstanbul yerel günü
  tek `attendance_day` aggregate'i oluşturur; timestamp'ler canonical UTC
  seconds kalır.
- Mobil schema `3 → 4`, mevcut Ajanda/reminder/follow-up event/notification
  binding verisini koruyan atomik migration'dır. Python schema `4`, Backup `1`,
  restore allowlist `(2, 3, 4)` ve Günlük Çıktı `1` değiştirilmez.
- Personel proje bazlıdır. Optional kod proje içinde unique; pasifleştirme ve
  entry removal logical'dır. Eski günlükler pasif personeli okumaya devam eder.
- Gün ve personel sonuç mutation'ları immutable command + expected revision
  kullanır. Stale fail-closed; no-op revision/event artırmaz; row ve monoton
  append-only event sequence aynı transaction'da yazılır.
- Günlük/ekip toplamı ve kişi-gün ayrı mutable tabloda tutulmaz; aktif entry
  satırlarından deterministik türetilir.
- Tamamlandı veya çalışma yok günü açıkça reopen edilmeden değiştirilemez.
  Lifecycle row'u, Puantaj event'i ve linked reminder mutation'ı aynı SQLite
  transaction'ında kalır.
- Puantaj reminder'ı ilk insert'ten itibaren `project_id` ve
  `attendance_day_id` taşır; exact link tablosu bir gün/bir reminder invariant'ı
  kurar. Notification pending listesi yine yeniden üretilebilir teslim katmanıdır.
- Proje setting'i `Europe/Istanbul` yerel saat ve seçili weekday'leri taşır.
  Bugünden başlayan 14 günlük pencere deterministic ID + unique anahtarlarla
  idempotent ensure edilir.
- Permission/plugin failure business day/reminder/link satırlarını geri almaz.
  Tamamlama/no-work reminder'ı kapatır; reopen linkteki exact due ile açar.
- CSV UTF-8 BOM/CRLF, deterministic sıra, quote escaping ve formula injection
  koruması kullanır. Atomic stage başarısından sonra event yazılır; sonraki
  event failure staged dosyayı güvenli kök içinde temizler.
- Ücret, bordro, maaş, SGK, hakediş, personel fotoğraf/belgesi, çoklu kullanıcı,
  onay zinciri, cloud sync, Beton Paketi, signing ve store submission kapsam
  dışıdır.

## Issue 187 — Mobil Beton Döküm Paketi

- Beton Paketi ayrı genel `PackageTemplate` motoru değil, ileride
  genelleştirilebilecek fakat bugün beton dökümüne özel tek aggregate'tir.
- Source-of-truth mobil SQLite `concrete_pours`; gerçek gelen metraj ayrı mutable
  kolon değil received/partial truck satırlarının deterministik toplamıdır.
- Mobil schema `4 → 5` mevcut Ajanda, reminder, notification ve Puantaj verisini
  koruyan atomik migration'dır. Python schema `4`, Backup `1`, restore allowlist
  `(2, 3, 4)` ve Günlük Çıktı `1` değişmez.
- Checklist, truck, sample, follow-up ve aggregate mutation'ları immutable
  command + expected revision kullanır; no-op revision/event artırmaz.
- Döküm event geçmişi deterministic sequence ve DB append-only trigger ile
  korunur. Raw absolute path, secret ve platform exception event'e yazılmaz.
- Reminder source invariant'ı observation, attendance day ve concrete pour
  kaynaklarından en fazla birini kabul eder; concrete source project ile
  composite foreign key üzerinden eşleşir.
- Package adımı ve linked reminder kapanışı tek SQLite transaction'dadır.
  Reminder'ın bağımsız mutation'ı source Beton paketini değiştirmez.
- Kanıt dosyası içerikten MIME sniff, boyut, SHA-256 ve relative path ile
  doğrulanır; final dosya hazır olmadan row yazılmaz, DB rollback orphan dosyayı
  temizler. Attachment kaynağı sonradan sessizce değiştirilemez.
- Kullanıcı açık exception ile ilerleyebilir; uygulama otomatik beton kabulü,
  reddi veya resmî teknik karar üretmez.
- Android/iOS aynı Dart sözleşmesini kullanır. Exact-alarm izni, API/cloud,
  signing, release hardening ve mağaza gönderimi bu dilime eklenmez.

## Issue 189 — Mobil Tam Yedek ve Geri Yükleme

- Mobil backup kapsamı bütün SQLite ile `concrete_attachments.archived_at IS
  NULL` satırlarının fiziksel byte'larıdır; OS pending notification türetilmiş
  durum olduğu için pakete girmez ve restore sonrası SQLite'tan uzlaştırılır.
- `.csebackup` format `1`, sınırlı authenticated başlık + PBKDF2-HMAC-SHA256 +
  AES-256-GCM şifreli ZIP ve exact size/SHA-256 manifest kullanır. Parola,
  absolute path, secret ve signing verisi kalıcılaştırılmaz.
- Tek `MobileOperationCoordinator`, Ajanda/Reminder, Puantaj, Beton ve
  backup/restore işlemlerini aynı seri sınırda tutar. Beton attachment'ın file +
  DB çok-adımlı mutation'ı da bütünüyle bu sınırdadır.
- Backup `VACUUM INTO` snapshot, SQLite integrity/FK/read-model ve attachment
  audit'inden sonra staging → self-check → atomic finalize uygular.
- Restore preflight salt-okunurdur; path/duplicate/entry/size/hash/schema/
  SQLite/FK/attachment eşliğini aktif state mutation'ından önce tamamlar.
- Eski desteklenen mobil schema yalnız staging'de migrate edilir; gelecekteki
  schema downgrade edilmez. Mobil schema `5` bu Issue'da değişmez.
- Restore merge değildir. İki kullanıcı onayı, preflight SHA token'ı, otomatik
  safety backup, database+attachments tam swap, activation smoke,
  notification reconciliation ve failure rollback zorunludur.
- Cloud provider, masaüstü import, otomatik zamanlama, release hardening,
  signing ve store submission Issue #189 kapsamı değildir.

## Issue 191 — Mobil Release Candidate Hardening

- Android production kimliği `com.faliardic.chiefsiteengineer`, compile/target
  API `36`, Java `17`, NDK `28.2.13676358` ve ARM64 release tabanıdır. Debug
  kimliği/name/veri kökü production'dan ayrı kalır.
- Merged release manifestte OS izin allowlist'i yalnız `CAMERA`,
  `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`'dır. Plugin private signature
  izni ayrı doğrulanır; broad media/storage, INTERNET, cleartext ve exact alarm
  fail-closed reddedilir.
- Release signing debug anahtarına düşmez. Gerçek key properties ve keystore
  repository dışında olmalıdır. Test kapısının ephemeral keystore'u gerçek
  upload/app-signing anahtarı değildir ve her çalışmada silinir.
- Restore journal secretsız ve relative operasyon adlarıyla sınırlıdır.
  Bootstrap `prepared`, `old_state_moved`, `new_state_activated`, `validated`
  aşamasını normal servislerden önce çözer; belirsiz durumda recovery kanıtını
  koruyup mutation açmaz.
- Mobil schema `5`, backup format `1`, Python schema `4`, desktop backup `1`,
  restore allowlist `(2, 3, 4)` ve Günlük Çıktı `1` değişmez. Eski mobil schema
  `1`–`5` yalnız restore staging alanında güncele taşınır.
- Privacy/store cevaplarının kanıt kaynağı repository dokümanlarıdır. Kaynak ve
  dependency audit'i doğru kaldığı sürece developer server'a veri/telemetry/
  ads/tracking gönderilmediği beyan edilir; kullanıcı başlatmalı OS share hedefi
  CSE'nin kontrolü değildir.
- `PrivacyInfo.xcprivacy` ve Xcode proje statik kapısı Windows'ta doğrulanır;
  native iOS archive veya App Store yüklemesi iddia edilmez. Bunlar macOS,
  Xcode 26, iOS 26 SDK, Apple hesabı ve repository-dışı signing gerektirir.
- Saha acceptance checklist'i kanıt şablonudur. Kullanıcı cihazında yapılmayan
  adımlar `not run` kalır; Codex gerçek saha kabulü veya store submission yapmaz.

## Issue 194 — Release 0.1 Saha Düzeltmeleri

- Mobil cihaz source-of-truth'u SQLite olarak kalır. Schema `5 → 6` taşeron,
  ekip, İSG belge, KKD zimmet ve append-only workforce event tablolarını ekler;
  Ajanda/reminder/Puantaj/Beton satırlarını değiştirmeden atomik ilerler.
- Legacy `workforce_members.team_name` değeri normalize edilip deterministik
  UUID ile hem taşeron hem ekip siciline bağlanır. Boş değer `Tanımsız ekip`
  olur; personel ID, attendance entry ve attendance event geçmişi korunur.
- Sicil mutation'ları immutable command + expected revision kullanır. Stale
  fail-closed, no-op revision/event artırmaz; aggregate row ve append-only event
  tek SQLite transaction'ında yazılır. Fiziksel silme yoktur.
- Aktif personeli bulunan ekip/taşeron pasifleştirilemez. Reopen sırası üstten
  alta taşeron → ekip → personeldir; böylece aktif alt kayıt archived üst kayda
  bağlanamaz.
- İSG tarih durumu yalnız deterministik read-model'dir; KKD kaydı yalnız zimmet
  geçmişidir. Uygulama hukuki uygunluk, işe kabul veya otomatik İSG kararı vermez.
- Proje kataloğu `AgendaApplication.projectChanges` üzerinden process içi canlı
  invalidation yayınlar. Kalıcı truth yine `projects` tablosudur; restart sonrası
  liste SQLite'tan okunur. Duplicate karşılaştırma trim + whitespace collapse +
  küçük harf normalization ile yapılır.
- Betonun iki saha görevi exact source link taşır ve saatlik tekrar yalnız
  platform notification katmanında `inexactAllowWhileIdle` olarak uygulanır.
  Exact-alarm izni eklenmez; permission/plugin failure SQLite reminder'ı silmez.
- `Yarın`, due varsa aynı yerel saati bir sonraki Europe/Istanbul takvim gününe,
  due yoksa ertesi gün 09:00'a taşır ve canonical UTC saklar. Row + event +
  notification binding tek mutation/reconciliation sözleşmesinde kalır; source
  observation veya Beton aggregate'i değiştirilmez.
- Future due saatlik Beton bildirimi due anında reconciliation beklemez. Android
  `due - interval` native periodic anchor + reboot cache, iOS aynı logical
  reminder altında 24 one-shot rolling horizon kullanır. iOS fiziksel ID'leri
  negative namespace'te kalır; completion/cancel grubu temizler, reopen aynı
  binding'i yeniden kurar. Exact alarm ve duplicate logical reminder yoktur.
- iOS pending kapasitesi logical reminder adediyle değil fiziksel slot maliyetiyle
  hesaplanır. Eksik rolling grup current sayılmaz; reconciliation grubu tümden
  iptal edip gelecek ilk occurrence'tan yeniden kurar.
- Mobil backup formatı `1` olarak kalır; restore allowlist mobil schema `1`–`6`
  olur. Python schema `4`, desktop Backup `1`, restore allowlist `(2, 3, 4)` ve
  Günlük Çıktı `1` değiştirilmez.

## Issue 196 — Ajanda ve Beton Saha Akışı

- Mobil schema `6 → 7` tek atomik migration'dır. Ajanda fotoğrafları exact
  observation/project composite FK, relative path, MIME/size/SHA-256, revision
  ve archive metadata'sı taşır; fiziksel delete trigger ile yasaktır.
- Ajanda `Sil` recoverable archive'dır. Active/archive filtreleri aynı
  `field_observations` source-of-truth'unu okur; restore aynı ID'yi kullanır.
  Bağlı reminder hiçbir archive/edit mutation'ında sessizce değişmez.
- Ajanda edit ve archive/restore immutable command + expected revision uygular.
  Stale fail-closed, no-op eventsizdir; başarılı mutation mutable row ile
  append-only event'i tek transaction'da yazar.
- Fotoğraf dosyası içerik sniff → boyut → staging → SHA-256 doğrulama → atomic
  finalize sırasındadır. DB/event rollback orphan dosyayı telafi edici cleanup
  ile kaldırır; archive byte'ı fiziksel silmez.
- Mikser irsaliye numarası nullable'dır. Partial unique index yalnız dolu
  normalize değerleri döküm içinde tekil tutar; v6 child FK grafiği migration
  transaction'ında exact kimliklerle yeniden kurulur.
- `delivery_note_scan` yeni canonical irsaliye kanıt türüdür;
  `delivery_receipt_scan` legacy kayıtları okunur ve eksik-kanıt hesabında eşdeğer
  kabul edilir. Scan exact truck ID'ye bağlanır; cloud OCR eklenmez.
- Beton canlı m³ read-model'i aktif received/partial truck hacminden türetilir.
  Negatif kalan clamp edilmez, `Aşılan` gösterilir. UI ve PDF aynı metrics ve
  iki ondalıklı Türkçe formatter'ı kullanır.
- Toplu tamamlama yalnız manual pending check/follow-up'ları tek transaction'da
  kapatır. Laboratuvar randevusu ve yapı denetim bildirimi source-field görevleri
  dışarıda kalır; retry deterministik item event kimlikleriyle idempotenttir.
- Beton kullanıcı ana raporu embedded açık lisanslı fontla PDF'dir. Share ve
  kullanıcı kontrollü belge save ayrı mutation'dır; cancel/hata event üretmez,
  staged dosya temizlenir. Broad storage izni eklenmez.
- `.csebackup` formatı `1`, Python schema `4`, desktop Backup `1`, restore
  allowlist `(2, 3, 4)` ve Günlük Çıktı `1` değişmez. Mobil restore staging
  allowlist'i `1`–`7` olur ve arşivlenmiş Ajanda fotoğraf byte'larını da taşır.

## Issue 198 — Kalıcı Mobil Yedek İçe Aktarma

- Picker provider/cache path'i hiçbir application veya UI state'inde source-of-
  truth değildir. Seçim dönmeden paket app-private `incoming_backups` root'una
  tamamen import edilir.
- Import `withReadStream`, 512 MiB hard limit, exclusive `.part`, incremental
  SHA-256, flush/close, tekrar size/hash kontrolü ve same-directory atomic rename
  sırasını kullanır. Path fallback yalnız picker call içinde tüketilebilir.
- `PickedBackupPackage` stable path, safe original basename, byte size, SHA-256
  ve import operation ID taşır. Preflight ve restore aynı immutable package
  metadata'sını kullanır.
- Preflight/restore yalnız exact incoming final veya uygulamanın kendi
  `exports_backups` direct-child dosyasını kabul eder. Regular-file ve resolved
  root, size ve SHA her işlem öncesi tekrar doğrulanır.
- Wrong password/preflight/restore failure incoming paketi retry için korur;
  restore success temizler. Yeni seçim eskiyi temizler, picker cancel mevcut
  seçimi korur, ekran kapanışı terk edilen seçimi best-effort temizler.
- Bootstrap yalnız incoming direct-child orphan `.part` ve 24 saati aşmış final
  paketleri temizler. Unknown ad, directory, symlink, belirsiz veya root dışı
  path hiçbir zaman cleanup hedefi değildir.
- Debug sidecar application ID `com.faliardic.chiefsiteengineer.debug` kalır ve
  production RC ile yan yana kurulabilir. Sidecar preflight aktif veriyi
  değiştirmez; otomatik restore/uninstall yoktur.
- Mobil schema `7`, `.csebackup` format `1`, restore journal, schema `1`–`7`
  allowlist, broad storage/media izin yokluğu ve offline device-of-truth
  değişmez.

## Issue 200 — Mikser Dialog Lifecycle Güvenliği

- Mikser controller sahipliği parent sayfada değildir. `_TruckDialog` kendi
  controller'larını `initState()` içinde oluşturur ve yalnız State `dispose()`
  çağrısında kapatır; parent yalnız immutable `_TruckDraft?` alır.
- Dialog submit guard senkron `_closing` bayrağıdır. Aynı event-loop içindeki
  ikinci submit, ikinci `Navigator.pop` veya ikinci DB mutation üretemez.
- Save failure form girdisini kaybetmez. Draft ile truck ID ve event ID birlikte
  saklanır; kullanıcı açıkça yeniden açtığında aynı logical mutation kimliği
  kullanılır ve güncel detail/revision yeniden okunur.
- Save success sonrası page read-model yeniden yüklenir; mikser notu ve revision
  görünür. Mevcut transactional `truck.updated` before/after, no-op ve optimistic
  stale kuralları application service'te değişmez.
- Beton ve Ajanda modal text controller'ları ortak State-owned dialog standardını
  kullanır. Reverse transition güvenliği zaman gecikmesi tahminine bağlı değildir.
- Fatal framework diagnostic, DB commit sonucu bilinmiyorsa veri yazılmadığını
  iddia etmez; uygulamayı yeniden açma, ilgili kaydı kontrol etme ve işlemi kör
  tekrarlamama talimatı verir.
- Mobil schema `7`, backup format `1`, restore journal, permission allowlist ve
  offline device-of-truth değişmez; ErrorWidget güvenlik sınırı kaldırılmaz.

## Issue 202 — Arka Plan Hatırlatıcı Teslimat Güvenilirliği

- Android'in resmi `setAndAllowWhileIdle` inexact toleransı ile 15/30/60 dakika
  kapalı-uygulama saha gecikmesi birlikte kök neden kanıtıdır. Kullanıcı niyetli
  reminder'lar `exactAllowWhileIdle` kullanır.
- Android 12+ özel erişimi `SCHEDULE_EXACT_ALARM` ile kullanıcı tarafından
  yönetilir ve yalnız kullanıcı planlı reminder/retry akışında istenir.
  `USE_EXACT_ALARM`, foreground service, internet ve cloud push eklenmez.
- Exact erişim reddinde logical reminder/event/binding korunur. Uygun platformda
  inexact fallback kurulabilir fakat binding `unavailable` ve
  `exact_alarm_permission_required` kalır; UI teslimat garantisi vermez.
- Native schedule başarı ölçütü plugin çağrısının exception vermemesi değildir.
  Pending platform ID, payload reminder ID ve rolling completeness schedule
  sonrası yeniden okunup doğrulanmadan binding `scheduled` olamaz.
- Android future saatlik repeat ankrajı plugin 22.1 native sözleşmesine göre
  `calledAt = due` değeridir; eski `due - interval` yaklaşımı ilk trigger'ı bir
  saat erken kurabildiği için kaldırılmıştır.
- Boot receiver plugin pending cache'ini yeniden planlar ve yalnız
  `completed/failed` ile UTC zamanını app-private audit'e yazar. Reminder
  başlığı, açıklaması, proje, kişi ve not tanı/audit kapsamı dışındadır.
- Reminder detay tanısı izin, kanal, exact erişim, native pending, batarya
  optimizasyonu, background restriction, standby bucket, boot sonucu ve
  gecikme sınıfını gösterir. Ayar ekranları yalnız kullanıcı eylemiyle açılır.
- Mobil schema `7`, backup format `1`, Python schema `4`, restore allowlist,
  Günlük Çıktı sürümü ve offline SQLite source-of-truth değişmez.

## Issue 207 — Saha Sidecar Entrypoint Güvenliği

- Normal saha sidecar source-of-truth giriş noktası yalnız `mobile/lib/main.dart`
  dosyasıdır. Release gate clean sonrasında açık `--target lib/main.dart` kullanır.
- Ortak Flutter `app-debug.apk` bir dağıtım artifact'i değildir. Yalnız aynı build
  çağrısının başlangıç zamanından yeni olduğu ve normal Dart marker'ını içerdiği
  kanıtlanırsa issue207 field sidecar adına kopyalanabilir.
- Normal marker `CSE_ENTRYPOINT_NORMAL_LIB_MAIN_DART_V1`; background ve reboot
  acceptance marker'ları farklıdır. Normal artifact'te sentetik marker görülmesi
  fail-closed release gate hatasıdır.
- Sentetik acceptance APK'ları normal `.debug` yerine `.acceptance` application
  ID ile ayrı Android sandbox kullanır. Artifact adları background/reboot amacını
  açıkça taşır ve field sidecar yolunu değiştiremez.
- Sentetik harness `runApp` çağrısını bootstrap veya reminder mutation sonrasına
  bırakmaz. Async hata güvenli UI'a dönüşür; sabit ID bulunduğunda farklı due ile
  ikinci create mutation yapılmaz.
- Fiziksel saha düzeltmesi uninstall veya data clear kullanmaz; yalnız aynı
  `com.faliardic.chiefsiteengineer.debug` package üzerine `adb install -r`
  uygulanır. Schema `7`, backup format `1` ve gerçek kullanıcı kayıtları okunmaz.

## Issue 212 — Reminder Pilot Kullanım Sözleşmesi

- Günlük Puantajın 14 günlük occurrence/reminder zinciri fiziksel olarak korunur;
  yalnız `Yaklaşanlar` read-model'i `attendanceDayId + projectId` sınırında due
  sırasındaki ilk kaydı gösterir. Bağımsız reminder'lar gruplanmaz.
- `Yarın` bütün gerekli kart/detail/deep-link yüzeylerinde aynı
  `snoozeTomorrowMorning` mutation'ını kullanır. Due'nun İstanbul saat/dakikası
  korunur; due yoksa yarın 09:00 seçilir.
- Teslim edilmemiş aktif kayıtta geçmiş due önce `Gecikti` sınıfına girer ve
  kritik native-plan kartı gösterilmez. Future native-plan eksikliği kritik,
  terminal kayıt diagnostic'siz kalır.
- Eylem sırası `Tamamla`, `Yarın`, kısa ertelemeler, `Yeni tarih`, ardından diğer
  lifecycle eylemleri ve en sonda geçerli diagnostic olacak biçimde sabittir.
- Mobil schema `7`, `.csebackup` format `1`, `.debug` application ID ve offline
  device-of-truth değişmez. Fiziksel kabul uninstall/data clear kullanmaz; yalnız
  doğrulanmış backup sonrasında `adb install -r` uygulanır.
- Windows release/acceptance build'leri clean öncesinde yalnız yeniden
  üretilebilir `mobile/build`, `.dart_tool` ve `ios/Flutter/ephemeral`
  ağaçlarının read-only özniteliğini kaldırır; işlem başarısızsa eski artifact
  ile devam etmek yerine fail-closed durur.

## Issue 214 — Yarın Hatırlatıcı Görünümü

- `Yarın`, ayrı `ReminderViewGroup` read-model'idir; application saati bir kez
  okunup Europe/Istanbul bugün anahtarı `+1` kaydırılır ve yarının yerel
  `[00:00, sonraki 00:00)` sınırları kanonik UTC SQL parametresi olur.
- Yalnız `active | waiting` ve due değeri aralıkta olan kayıtlar seçilir. UTC
  tarih parçası, terminal durum, due-null veya “şimdi + 24 saat” yaklaşımı filtre
  kararı vermez.
- Issue #212 Puantaj tekilleştirme helper'ı `Yaklaşanlar` ve `Yarın` arasında
  paylaşılır; source reminder/link/event satırları değişmez.
- Yarın filtresi salt-okunurdur. Bu gruptaki kart hızlı `Yarın` mutation'ını
  göstermez; detail ve Şimdi/Gecikenler/Yaklaşanlar eylemleri korunur.
- Filtre ChoiceChip'leri `Wrap` içinde minimum 48 px yüksekliktedir. Boş durumda
  yalnız sade kullanıcı mesajı gösterilir, notification diagnostic'i yoktur.
- Mobil schema `7`, `.csebackup` format `1`, exact alarm/boot reconciliation,
  `.debug` application ID ve offline SQLite source-of-truth değişmez.

## Issue 220 — Roadmap 2026.3.1 Günlük Güvenilirlik Sırası

- #193 Release 0.1 gerçek cihaz pilotu açık kalır; Release 0.1.1 günlük
  güvenilirlik/sadeleştirme işleri pilotu kapatmaz veya tamamlanmış göstermez.
- Universal Capture production implementation'ından önce #219 yorumundaki
  düzeltilmiş sıra uygulanır: reminder scheduling, birleşik Bugün,
  trash/restore, Ajanda kaynak attachment görünürlüğü, Beton sınıfı/zaman
  çizgisi, Beton keyword önerisi, attachment v2, albüm, #204 Puantaj UX,
  İstenecek Malzemeler, prompt export, mini hesap makinesi ve ertelenmiş hava
  uyarıları.
- İlk production child #221'dir. Bu docs-only branch Blok 1 veya sonraki
  production davranışını başlatmaz.
- Reminder içindeki legacy `Bekliyorum` kaldırılır; gelecekteki `Beklediklerim`
  Open Loop modelinde ayrı kayıt türüdür. `Tam gün`, sahte saat ile temsil
  edilmez.
- Silme ilk aşamada recoverable archive/trash'tır; otomatik hard-delete yoktur.
  Attachment tek fiziksel dosya + çoklu kayıt bağlantısı ilkesini izler.
- Beton keyword yalnız öneri/deep-link üretir. İlk AI adımı kaynaklı prompt
  export'tur; otomatik Beton creation, embedded AI ve sessiz mutasyon yoktur.
- Hava durumu, haricî servis/eşik/offline tasarımı sonrasına ertelenir.
  Güvenli, salt-okunur gömülü DWG/Office/proje dokümanı viewer nihai ürün
  hedefidir fakat ertelenmiştir. İki yönlü PC sync ve ileri mühendislik
  hesapları da ertelenir; BIM/DWG/Office düzenleme, authoring ve teknik karar
  motoru kesin kapsam dışıdır.
- Validation class `docs` olarak sabittir. Exact allowlist, Markdown
  başlık/bağlantı/Issue referansı, `git diff --check` ve production diff boşluğu
  yeterlidir; full suite, analyze, artifact, release gate, backup/restore ve
  fiziksel cihaz çalıştırılmaz.

## Issue 221 — Reminder Bugün, Tam Gün ve Legacy Waiting Normalizasyonu

- Mobil reminder schedule üç ayrık biçim taşır: inbox için iki schedule alanı
  da `NULL`; timed için yalnız canonical UTC `next_attention_at`; tam gün için
  yalnız Europe/Istanbul `all_day_local_date`. Tam gün, uydurma 09:00/18:00/
  23:59 timestamp'i ile temsil edilmez.
- Reminder `item_type` yalnız `action | recheck`, açık status yalnız
  `inbox | active` olur. `waiting` enum, form, filtre ve mutation API'sinden
  kaldırılır; Open Loop `Beklediklerim` bu schema içinde modellenmez.
- Schema `7 → 8` tek transaction'dır. Legacy kind/status waiting varyantları
  `action/active` olur; schedule, project/Ajanda/Puantaj/Beton kaynak bağları,
  importance, description, notification binding, revision ve mevcut event
  geçmişi korunur.
- Her dönüştürülen legacy reminder için kaynak kimliğinden türetilen
  deterministik tek `legacy_waiting_normalized` event'i, mevcut maksimum
  sequence'in sonuna eklenir. Tarihsel `waiting_started` event'i silinmez;
  production application yeni waiting event'i üretemez.
- Terminal reminder schedule bilgisini kaybetmez. Reopen, schedule varsa
  `active`, yoksa `inbox` olur. Notification reconciliation yalnız
  `status = active` ve gerçek `next_attention_at` taşıyan timed kayıtları native
  planlar; all-day binding `cancelled` kalır.
- `.csebackup` format `1` korunur. Schema `1–7` backup'ları restore sırasında
  schema `8` olur; daha yeni bilinmeyen schema fail-closed reddedilir.
- Validation class `persistence`tır. Schema migration/rollback, FK ve event
  bütünlüğü, schema `1–7` restore matrisi, all-day backup round-trip, reminder
  lifecycle/application/widget testleri ve `flutter analyze` yeterlidir.
  Android release gate, AAB/signing, reboot/background acceptance, production
  RC ve gerçek cihaz restore bu Issue'da çalıştırılmaz.

## Issue 225 — Birleşik Bugün Reminder Read-Modeli

- Hatırlatıcı ana yüzeyinin varsayılanı `Bugün`dür. Ana filtre sayısı
  `Bugün | Yarın | Diğer` ile sınırlıdır; Yaklaşanlar, Unutma Kutusu, Tekrar
  kontrol ve Geçmiş `Diğer` menüsünden açılır.
- Bugün read-modeli tek `asOfUtc` okuması ve kanonik `CseTimeCodec` üzerinden
  `overdue | timedToday | allDayToday | inboxCount` üretir. UI kendi
  DateTime karşılaştırmasını yapmaz.
- Aktif timed kayıt `next_attention_at < asOfUtc` olduğunda gecikmiştir.
  Geçmiş yerel gün all-day her saatte; bugünkü all-day ise Europe/Istanbul
  18:00:00 ve sonrasında gecikmiştir.
- Sınıflandırma reminder kimliğini önce tekilleştirir. Böylece kaynak
  Puantaj/Beton olsa da aynı logical reminder iki bölümde veya iki kart olarak
  gösterilmez.
- Saatli bugün en erken saat, sonra importance/created/id; tam gün importance,
  created/id; geciken logical schedule, importance, created/id sırasındadır.
- Bu karar yalnız application read-model ve presentation katmanıdır. Schema 8,
  backup format 1, notification gateway, platform kodu ve project-level 18:00
  ayarı değişmez.

## Issue 227 — Reminder Trash/Restore Yaşam Döngüsü

- Trash, reminder status'u değildir. `inbox | active | completed | cancelled`
  aynen korunur; görünürlük nullable canonical UTC `trashed_at` ile belirlenir.
- `Sil` fiziksel `DELETE`, `cancelled` veya `completed` üretmez. Gerçek mutation
  olarak revision/updated time artırır ve append-only `trashed` event'i yazar.
  Restore yalnız `trashed_at = NULL` yapıp `restored_from_trash` event'i ekler.
- Trash durumundayken başka lifecycle mutation'ı reddedilir. Aynı trash/restore
  komutunun tekrarı no-op'tur; stale revision ana kayıt ve event history'yi
  değiştirmeden fail-closed durur.
- Normal reminder read-model ve source detay listeleri yalnız
  `trashed_at IS NULL` kayıtları gösterir. Trash listesi `trashed_at DESC`,
  `updated_at DESC`, `id ASC` sırasındadır.
- Ajanda/Puantaj/Beton source ve link kayıtları trash ile değişmez. Source
  otomasyonları trash reminder'ın korunmuş status/schedule/outcome değerlerini
  sessizce değiştirmez.
- Notification binding/platform ID aggregate kimliği olarak korunur. Trash
  reconcile native planı iptal edip `scheduled_for = NULL` yazar; gateway
  hatası persistence kararını geri almaz. Restore yalnız active, timed ve
  gelecekteki schedule için planlama yapar.
- Mobil schema `9`, backup format `1`dir. Schema `1–8` restore migration zinciri
  korunur; schema 9 trash/event geçmişini eksiksiz round-trip taşır.
- Kalıcı silme, retention, attachment byte temizliği ve source cascade ayrı
  gelecekteki politika/Issue olmadan eklenmez.

## Issue 234 — Beton Sınıfı ve Yönetilen Ajanda Projeksiyonu

- Mobil schema `10`, paket snapshot'ını değiştirmeden proje Beton sınıfı
  kataloğunu ve paket bağlamını ayrı tablolarda tutar. Paket–sınıf ve
  paket–Ajanda ilişkileri `project_id` composite FK sınırındadır; aynı Ajanda
  kaydı yalnız bir Beton paketine bağlanabilir.
- Legacy `concrete_class` değerleri trim, ardışık boşluk ve case normalizasyonu
  ile proje bazında deterministik seed edilir. Snapshot metni aynen korunur;
  whitespace-empty legacy değer migration'ı sessiz düzeltmek yerine atomik
  olarak fail-closed durdurur.
- Katalog archive/restore optimistic revision ve append-only event üretir.
  Arşivli sınıf yeni pakette seçilemez; eski paket snapshot ve sınıf bağlantısı
  değişmez. Fiziksel silme yoktur.
- Kullanıcı lifecycle'ı timestamp'lerden türeyen `Planlandı → Devam ediyor →
  Tamamlandı` projection'ıdır; ayrıntılı Beton status enum'u checklist, takip ve
  kapanış kuralları için korunur.
- `Dökümü başlat`, draft veya prepared pakette aynı zorunlu checklist
  validation'ını uygular; ilk `actual_started_at` değerini korur. `Dökümü
  bitir`, en az bir mikser ister ve ilk `actual_ended_at` değerini korur;
  follow-up veya closed durumuna otomatik geçmez.
- İlk başarılı başlangıç Beton update/event, Ajanda row/event ve linki tek
  SQLite transaction'da oluşturur. Bitiş aynı Ajanda kaydını günceller; ikinci
  log veya Ajanda kaynaklı ek reminder üretmez.
- Yönetilen Ajanda kaydı Beton aggregate'inin saha günlüğü projeksiyonudur.
  Ajanda application bağımsız ana metin editini ve archive/restore mutation'ını
  reddeder; UI bunu açıkça gösterip kaynak Beton paketine döner.
- Başlamış legacy paketin eksik Ajanda bağlantısı gerçek başlangıç/bitiş
  zamanlarıyla idempotent onarılır. İptal ve reopen gerçek timestamp geçmişini
  silmez; sahte bitiş üretilmez.
- `.csebackup` format `1` değişmez. Schema `1–9` paketleri schema `10`a
  migrate edilir; schema 10 katalog, bağ, gerçek zaman ve append-only geçmişi
  round-trip taşır.

## Issue 264 — Liste state'i route-local tutulur

- Ajanda, Hatırlatıcı, Beton ve Puantaj scroll controller/state sahipliği canlı
  liste route'undadır; global mutable singleton veya random key kullanılmaz.
- Detail push öncesi offset snapshot alınır. Async fresh reload sonrası restore,
  layout tamamlandığında güncel scroll extent içine clamp edilerek yapılır.
- Reload sırasında son geçerli content korunur; geçici boş extent kullanıcıyı
  listenin başına düşürmez.
- Hızlı iki dokunma route-local guard ile tek detail push üretir. Direct
  deep-link sahte liste geçmişi oluşturmaz.
- Cold restart/process-death pixel restoration, schema, backup ve genel router
  bu kararın kapsamı dışındadır.

## Issue 266 — Tek ürün dili root Flutter locale'inde sabitlenir

- CSE'nin mevcut tek ürün dili Türkçedir. Root `MaterialApp`, yalnız
  `Locale('tr')` ve canonical Material/Widgets/Cupertino delegate setini
  kullanır; cihaz locale'i yerleşik kullanıcı eylemlerini İngilizceye
  çeviremez.
- `flutter_localizations` Flutter SDK dependency'sidir. Üçüncü taraf
  localization paketi, ARB kataloğu, çoklu dil veya dil seçici eklenmez.
- Puantaj `draft` bir lifecycle durumudur; ana kullanıcı eyleminin adı değildir.
  Görünür eylem `Kaydet` olur fakat `save-attendance-draft` key'i, command,
  event ID, revision, rollback, idempotency ve submitting guard korunur.
- Seçim toolbar eylemleri bağlama göre gösterilir. Editable alanda uygun Türkçe
  eylemler görünür; read-only alanda `Kes` ve `Yapıştır` zorla gösterilmez.
- Test platform davranışı global debug override ile değil route-local theme ile
  kurulur. Dar ekran görünürlüğü exact route scrollable ve semantic key
  üzerinden doğrulanır.
- Schema `10`, backup formatı `1`, persisted zaman/sayı codec'leri ve
  notification/persistence sözleşmeleri bu kararın kapsamı dışındadır.

## Issue 268 — Ajanda sırası application query sözleşmesidir

- Ajanda yeni route varsayılanı `AgendaSortOrder.newestFirst` olur; kullanıcı
  `oldestFirst` seçebilir. Kullanıcı etiketleri `En yeni üstte` ve
  `En eski üstte`dir.
- Her iki yön `observed_at`, `created_at`, `id` alanlarının aynı yöndeki
  üç seviyeli SQL sırasıdır. Serbest SQL yönü veya UI `reverse()` kullanılmaz.
- `updated_at` sıralamaya katılmaz; içerik güncellemesi kaydın saha olay
  zamanındaki konumunu değiştirmez.
- Sort gün, aktif/arşiv, proje, tür ve literal arama ile aynı `AgendaQuery`
  içinde taşınır. Detail reload ve route dönüşü canlı route-local state'i
  korur.
- Sort cold restart preference'ı değildir. Schema `10`, backup formatı `1`,
  günlük çıktı ve persistence sözleşmeleri değiştirilmez.
- Static localization dependency testi yalnız CRLF/LF satır sonlarını
  normalize eder; dependency adı, indent ve `sdk: flutter` exact contract'ı
  korunur.

## Issue 275 — Ajanda arama odağı route-local ve kullanıcı niyetine bağlıdır

- Arama text/controller state'i ile focus/caret/IME state'i ayrı
  sözleşmelerdir. Text ve literal query canlı route içinde korunabilir; focus
  ve IME yalnız explicit kullanıcı search tap'iyle etkinleşir.
- `AgendaPage`, exact search alanına ait route-local `FocusNode`u oluşturur ve
  controller ile birlikte dispose eder. Global singleton, autofocus toggle,
  random key veya kalıcı preference kullanılmaz.
- Detail push öncesi search node unfocus edilir. Fresh reload, filtre/sort ve
  scroll offset restore korunur; dönüşte focus/caret/IME restore edilmez.
- Liste `ScrollViewKeyboardDismissBehavior.onDrag` uygular; arama alanında
  başlayan gerçek drag text/query churn üretmeden klavyeyi kapatır. Odaksız
  drag, fling, momentum ve yön değiştirme focus oluşturmaz.
- Fiziksel kabul için Samsung `SM-X610` tablet PASS'i kullanıcı tarafından
  Issue #275 tamamlanma kapısı seçilmiştir. Telefon promotion ayrı talebe kadar
  ertelenmiş ve yapılmamıştır.
- Bu karar schema `10`, backup formatı `1`, migration `0`, persistence,
  application query, notification, Android native ve genel router
  sözleşmelerini değiştirmez.

## Issue 280 — Podcast geçmişi legacy adım ve canonical Issue dönemlerini ayırır

- Legacy numaralı geliştirme dönemi Adım `001–225` ile kapanır. Podcast
  `001–035` tarihsel kayıttır ve yeni current-state senkronunda değiştirilmez.
- Podcast `036` ile dosya range türü `issue` olur. Issue aralığı kesintisiz adım
  geçmişi değildir; generator yalnız `CHANGELOG.md` içindeki gerçek
  `## Issue #NNN - ...` bölümlerini toplar ve eksik numaraları uydurmaz.
- Aynı podcast numarası `adim` ve `issue` dosyalarında birlikte kullanılamaz.
  Legacy `adim` strict önceki-başlık kontrolü geriye uyumlu korunur; `issue`
  notuna sahte kesintisiz önceki adım zorunluluğu uygulanmaz.
- Canonical state küçük ve insan-okunabilir tutulur. Merged safe point, paused
  aktif iş ve blocked Draft PR ayrı alanlardır; birleşmemiş davranış merged
  capability gibi sunulmaz.
- Stable NotebookLM public source yolu değişmez. Source ve manifest ağ
  erişimsiz, UTF-8 ve byte-for-byte deterministik üretilir.
- Bu karar production davranışı, mobil schema `10`, backup formatı `1`,
  migration, native platform ve cihaz paketini değiştirmez.

## Issue 285 — Orchestrator önce güvenlik oracle'ını kurar

- CSE Development Orchestrator'ın ilk amacı otomatik kod üretmek değil; mevcut
  scope, approval, provenance, evidence reuse, retry ve fail-closed kurallarını
  makine tarafından doğrulanabilir hâle getirmektir.
- Run admission operational truth sırası local Git; local/cached/live master;
  current Issue ve latest-valid authorization; task/result; repository dışı
  append-only event store; finalized `.cse/state` snapshot; docs iddialarıdır.
  Bu sıra bilgi-türü bazlı kanonik kaynak rollerini değiştirmez.
- `.cse/state/project_state.json` açık branch veya current authorization
  otoritesi değildir; yalnız merged/finalized snapshot'tır. Açık iş Issue,
  yorum, branch, task ve result ile temsil edilir.
- `PREFLIGHT_BLOCKED`, `BLOCKED` ve `FAILED` yalnız Orchestrator process
  durumlarıdır. Ürün kaydı veya Fatih adına resmî blocked kararı üretmez.
- Approval repository, Issue/comment hash, branch/base/head/tree, scope,
  capability, action, allowlist, target, budget, expiry ve nonce'a bağlı tek
  kullanımlık fingerprint'tir. Orchestrator approval oluşturamaz veya
  genişletemez.
- Code, Device ve Publish ayrı capability/process sınırlarıdır. Profile geçişi
  yeni observation, approval ve budget admission gerektirir; ambient yetki
  devredilmez.
- Runtime state `%LOCALAPPDATA%\CSE-Orchestrator\` altında repository dışında
  tutulur. Raw gerçek kullanıcı içeriği, broad UI/log/DB verisi ve secret
  plaintext event, manifest, log veya evidence içinde tutulmaz.
- `scripts/cse_status.py` mevcut diagnosis/finalize envanteridir fakat broad
  ignored/untracked/ZIP/export taraması nedeniyle O1 observer olarak doğrudan
  çalıştırılmaz. O1 tracked-only read ile explicit state write sorumluluklarını
  ayırır.
- O0–O4 deterministik oracle katmanıdır. OpenAI API ilk kez O9'da ayrı secret,
  network, cost ve nondeterminism kararıyla değerlendirilebilir.
- Issue #284 yalnız sanitized comment/state/hash/budget/provenance sequence'i
  olarak O4 replay fixture kaynağıdır; gerçek kullanıcı veya cihaz içeriği
  fixture'a alınmaz.
- Bu karar docs/governance kapsamındadır; production/mobile/test/workflow,
  schema, migration, backup, build, device, commit, publish ve release
  davranışı eklemez.

## Issue 287 — O1 gözlemi action kararından ayrılır

- O1'in tek görevi local Git, live GitHub, machine authorization ve exact CSE
  kayıtlarından deterministic/sanitized Observation v1 üretmektir. Approval
  consumption, action admission ve policy kararı O1 kapsamına girmez.
- Machine authorization yalnız exact marker ve fenced JSON'dan alınır;
  duplicate/unknown/missing alan, transport comment-ID farkı, non-UTC expiry
  veya source fingerprint drift'i fail-closed sonuçtur.
- Authorization fingerprint'i sorted, whitespace'siz UTF-8 canonical JSON
  byte'larının SHA-256 değeridir. Daha yeni yorum yalnız schema-valid ve açık
  `supersedes_comment_id` bağıyla önceki yetkiyi değiştirebilir.
- Git observer yalnız tracked metadata ve staged/tracked diff'i okur. Mutating
  Git aileleri subprocess başlamadan reddedilir; ignored/untracked, ZIP,
  export, cache ve kullanıcı alanı taranmaz.
- GitHub adapter yalnız repository, exact Issue ve paginated comments için GET
  kullanır. Raw Issue/comment body evidence output'una girmez.
- Runtime root repository'nin içinde olamaz. Sanitized JSON unique dış run
  klasörüne temporary file, flush/fsync ve atomik `os.replace` ile yazılır.
- `scripts/cse_status.py` broad tarihsel diagnosis/finalize davranışı nedeniyle
  değiştirilmez veya O1 olarak doğrudan yeniden kullanılmaz.
- O2, full validation, live integration, commit, publish, OpenAI API, build ve
  device ayrı Issue/approval gerektirir.

## Issue 289 — O2 policy kararı runner ve persistence'tan ayrılır

- O0 state tablosu executable exact transition setidir. Bütün non-terminal
  states explicit cancellation taşır; terminal state devamı yeni run ister.
- Transition eventleri immutable ve canonical SHA-256 kimliklidir. Exact replay
  idempotenttir; aynı event ID ile farklı payload history rewrite sayılıp
  reddedilir. O2 kalıcı event store yazmaz.
- Policy input'u exact şemadır ve caller mapping'ini değiştirmez. Unknown veya
  eksik state/action/approval/capability/budget/evidence alanı normalize edilmez;
  fail-closed karar üretir.
- Approval seviyesi sıralıdır fakat admission exact action, capability,
  source/scope/action/capability/budget fingerprint ve expiry bağı ister. Daha
  üst fakat farklı action approval'ı ambient yetki değildir.
- Action invocation öncesi hard stop ve ilgili counter doğrulanır; policy yalnız
  `budget_delta` önerir. Approval consumption, budget mutation ve
  invocation-start provenance persistence'ı O2 kapsamında değildir.
- Same-operation retry yalnız exact `CORRECTION` fingerprint'i ve ayrı retry
  bütçesiyle admit edilir. Aynı source full gate'i tekrar çalıştırılmaz; exact
  source+contract evidence reuse veya explicit `not_required` gerekir.
- Policy filesystem, subprocess veya network kullanmaz ve action çalıştırmaz.
  O3 parser, SQLite, runner, GitHub write, API, build ve device ayrı faz/approval
  sınırında kalır.

## Issue 291 — O3 result evidence runner ve policy'den ayrılır

- O3 yalnız caller tarafından dondurulmuş exact-schema command result mapping'i
  ayrıştırır; action başlatmaz, approval/budget tüketmez ve success state seçmez.
- Supported family seti `pytest`, `compileall`, `git_diff_check`,
  `flutter_test`, `flutter_analyze`, `build` ve `generic_command` ile explicit
  kalır. Unknown family veya uyumsuz schema fail-closed reddedilir.
- Action başlamadı/harness failure, timeout, truncation, malformed output ve
  exit/output contradiction ayrı provenance evidence'ıdır. Invocation budget
  yalnız action gerçekten başladıysa consumed olarak raporlanır; sayaç yazılmaz.
- Count yalnız kanıtlanmış summary token'ından üretilir. Kanıt yokluğu `null`,
  explicit sıfır sonucu `0`dır; warnings test toplamına eklenmez.
- Raw stdout/stderr kalıcı result'a kopyalanmaz. Exact UTF-8 stream hash'i ile
  secret, e-posta ve Windows kullanıcı yolu maskelenmiş bounded excerpt taşınır.
- Parser filesystem, subprocess veya network erişimi yapmaz. Runner,
  append-only admission/result persistence, GitHub write, API, gerçek build ve
  device sonraki ayrı Issue/approval sınırındadır.

## Issue 293 — O4 replay transcript değil sanitize karar zinciridir

- Issue #284 replay fixture'ı raw comment body veya command stream kopyalamaz;
  yalnız exact 19 comment/event identity, scope, approval/capability,
  fingerprint, allowlist/budget, result class, blocker/gate ve evidence kimliği
  taşır.
- Device target yalnız `tablet_primary` sembolüdür. Gerçek kullanıcı kaydı,
  cihaz seri/modeli, app-private data, backup, UI dump, log, credential veya
  Windows kullanıcı yolu fixture kaynağı olamaz.
- GitHub authorization, task/result ve `.cse_state` kayıtlarından üst
  authority'dir. Daha yeni ordinary/lower-authority kayıt explicit
  supersession olmadan approval veya budget genişletemez.
- Aynı authorization ikinci started action üretemez. Action başlangıcı
  kanıtlanmayan tool timeout invocation budget tüketmiş sayılmaz; source,
  harness, timeout ve test result sınıfları ayrı korunur.
- Reused evidence exact identity; checkpoint build/device zinciri exact
  commit-parent-tree provenance'ı ister. Publish authorization/budget fixture'da
  yoktur.
- Replay engine yalnız in-memory immutable mapping değerlendirir; filesystem,
  subprocess veya network kullanmaz ve action çalıştırmaz.
- Final summary Issue #284 için completion/publication iddiası değildir.
  Checkpoint frozen/unpublished, state `ACTION_AUTHORIZED` ve next gate `DEVICE`
  olarak korunur.
## Issue 301 — Git ve publish sahipliği host'tadır

- Nested Codex yalnız exact allowlist dosyalarını düzenler ve test çalıştırır;
  branch, index, commit, push ve PR yetkisi taşımaz.
- Final SHA child öncesi contract girdisi değildir. Host child PASS sonrasında
  exact base/scope/worktree doğrulayıp final validation, staging, tek commit ve
  tek normal push yapar; REST contract push sonrası provenance'dan oluşur.
- Codex executable shell açmadan bir kez çözülür; yalnız güvenli platform
  basename'leri ve repository/runtime dışındaki mevcut dosya kabul edilir.
- Host publish isteğinin allowlist, doğrulama komutları, commit mesajı ve Draft
  PR metadatası API çağrısından önce yerel ProposalContract ile birebir
  bağlanır; bağımsız host girdisi bu otoriteyi genişletemez.

## Issue 305 — Tablet interactive sinyali ve paused controller devri

- Power preflight yalnız exact line-level `mWakefulness`, `mInteractive` ve
  `Display Power` sinyallerini merkezi enum parser'da birleştirir. Bütün bulunan
  sinyaller positive değilse veya output malformed ise interactive PASS verilmez.
- Power ve keyguard farklı güvenlik kapılarıdır; Awake sonucu unlocked anlamına
  gelmez. Raw dumpsys output kalıcı diagnostic veya workflow evidence değildir.
- Paused controller handoff yalnız binding authorization'daki exact predecessor
  authorization/workflow, projection fingerprint, tail, stage, attempt, blocker
  ve sıfır-effect state'i için açılır.
- Predecessor authorization/manifest/ledger immutable kalır. Successor yeni
  identity altında aynı event payload history'sini atomik seed eder; semantic
  projection eşit değilse yayınlanmaz. Böylece önceki validation/build/artifact
  stage'leri ve attempt sayaçları resetlenmez.
- Aynı controller successor'ı idempotenttir; başka controller revision,
  rollback, projection/tail/effect drift veya eksik successor history
  `controller_handoff_not_safe` ile durur.

## Issue 420 — Attachment fiziksel kimliği bağlamsal linkten ayrılır

- Schema 13'te dosyanın taşınabilir yol, MIME, boyut ve SHA-256 kimliği
  `managed_attachments`; Agenda/Beton kaynak ve çocuk bağlamı ise
  `attachment_links` içinde tutulur. Link yaşam döngüsü append-only
  `attachment_link_events` ile kanıtlanır.
- Schema 12 cutover'ı her legacy satırı ayrı fiziksel kayıt ve ayrı link olarak
  atomik taşır. Aynı SHA-256 otomatik birleştirme yetkisi değildir; migration
  attachment byte'ı okumaz, taşımaz veya silmez.
- Mevcut Agenda ve Beton API kimlikleri legacy provenance üzerinden korunur.
  Yeni yazımlar canonical tablolara gider; bilinmeyen, cross-project veya
  yanlış çocuk bağlamı SQLite seviyesinde fail-closed reddedilir.
- Backup formatı 1 kalır. Schema 13 paketleri bağlı aktif/arşiv tüm fiziksel
  dosyaları birer kez taşır; schema 12 restore denetimi eski Agenda-tümü ve
  Concrete-aktif kuralını kaynak schema bilgisiyle korur.
- Recovery canonical source/context/project/event grafiğini ve gerekli fiziksel
  dosyaları denetler. Schema 12'den taşınmış arşivli Concrete kaydının tarihsel
  olarak opsiyonel byte'ı sentetik biçimde zorunlu yapılmaz.
- Yeni Agenda ve Beton attachment byte'ları feature klasörleri yerine tek ortak
  store tarafından `managed/<attachmentId>.<ext>` yoluna yazılır. Mevcut
  `agenda/...` ve `concrete/...` yolları taşınmadan salt-okunur uyumla korunur.
- Ortak store safe basename, boyut, sniff edilmiş MIME, private-root containment,
  symlink/non-regular-file reddi ve `.part` dosyasını yeniden okuyarak
  size/hash/MIME doğrulaması sonrasında atomik finalize uygular. Failure
  compensation yalnız o operasyonun yeni artifact'ına dokunur.
- Reconciliation schema-13 metadata, canonical link target'ları, managed final
  dosyaları ve yalnız `managed-<uuid>.part` staging pattern'ini salt-okunur
  sınıflandırır. Delete/adopt/relink/dedupe/rewrite/move yapmaz ve bootstrap'ta
  otomatik çalışmaz.
- Çoklu seçim tekli `pick(...)` uyumluluğunu koruyan ayrı bir picker yeteneğidir.
  Kamera tek dosya; fotoğraf arşivi ve dosya seçici en çok 20 öğe / 100 MiB
  toplam batch sınırıyla fail-safe çalışır.
- Yeni Ajanda logundaki çoklu fotoğraflar create transaction'ına; mevcut log ve
  genel Beton kanıtları ise tek kullanıcı işlemi başına tek revision artışına
  bağlanır. Herhangi bir stage/validation/DB hatasında bütün batch rollback olur
  ve compensation yalnız o işlemin yeni managed yollarını hedefler.
- Genel Beton resimleri `site_photo`, PDF/video/ses dosyaları `other` rolündedir;
  mikser, irsaliye ve numune gibi uzmanlaşmış tekli rol akışları değişmez.
- JPEG/PNG uygulama içi `InteractiveViewer` ile kalır. HEIC/PDF/MP4/MP3/M4A/WAV
  yalnız path, MIME, boyut ve SHA-256 bütünlüğü doğrulandıktan sonra mevcut
  `open_filex` geçidine verilir; embedded player veya yeni dependency eklenmez.
- Proje-kapsamlı dosya kataloğu canonical fiziksel kayıtları linklerinden
  türetir; aynı fiziksel kaydın bütün Ajanda/Beton bağlarını ve salt-okunur
  integrity durumunu gösterir. SHA-256 eşitliği fiziksel kayıtları birleştirmez.
- “Mevcut dosyayı bağla” işlemi yeni byte üretmez veya stage etmez; seçilen
  fiziksel kimliğe kullanıcı açık seçimiyle yeni link/event ekler. Agenda yalnız
  JPEG/PNG/HEIC `site_photo`; Beton genel kanıtı image için `site_photo`, diğer
  shipping MIME aileleri için `other` kullanır.
- Katalog ve mutation katmanı unknown/cross-project/duplicate source seçimini
  fail-closed reddeder. Tek contextual linkin arşivlenmesi fiziksel kaydı ve
  diğer bağları koruyan schema-13 sözleşmesini değiştirmez.
- Dosya sağlığı ekranı existing reconciliation matrisini yalnız kullanıcı
  ekranı açtığında salt-okunur çalıştırır. Bootstrap otomatik inspect, repair,
  delete, move, adopt, relink veya dedupe yapmaz.

## Issue 427 — Ajanda fotoğraf export/share doğrulanmış byte kopyasıdır

- Ajanda fotoğrafını cihaza kaydetme ve paylaşma işlemleri yalnız mevcut
  `readAgendaPhoto(photo.id)` integrity kapısından geçen byte'ları kullanır;
  managed source path/byte/hash ile attachment, link, revision ve event state'i
  değişmez.
- Save mevcut `file_picker` sistem Save flow'una exact byte kopyasını verir;
  kullanıcı iptali normal no-op'tur. Share mevcut `share_plus` sistem sheet'ini
  kullanır ve kopyayı yalnız UUID ile ayrılmış operation staging klasöründe,
  güvenli/orijinale en yakın basename ile üretip işlem sonrasında temizler.
- JPEG/PNG MIME-byte uyumu platform çağrısından önce yeniden doğrulanır. Unsafe
  basename karakterleri fail-safe sanitize edilir; dependency, permission,
  manifest, schema veya Backup formatı genişletilmez.

## Issue 420 final closure — Kapanış production diff yerine executable veri kanıtıdır

- V2.3 attachment kapanışı yeni ürün davranışı eklemez. Schema 13 / Backup
  format 1 üzerinde source ve ayrı temiz target kullanan sentetik round-trip;
  physical ID, çoklu Agenda/Concrete link/event grafiği, managed + legacy path,
  exact byte/size/SHA/MIME ve yeniden açılış bütünlüğünü production diff `0` ile
  kanıtlar.
- Aynı SHA-256'ya sahip iki fiziksel kimlik restore sonrasında da ayrı tutulur;
  SHA eşitliği migration, backup veya restore için dedupe yetkisi değildir.
- Final debug artifact temiz dependency/registrant üretimiyle oluşturulur;
  registrant, plugin sınıfları ve ARM64 runtime inventory install öncesi
  doğrulanır. Fiziksel cihaz kabulü data-preserving `install -r` ve cold-launch
  smoke ile sınırlıdır; gerçek cihazda restore yapılmaz.
- PR Ready ve V2.3 owner closure, source review sonrasında mevcut Agenda/Concrete
  attachment, shared link, cold reopen, Dosya Kataloğu ve Dosya Sağlığı için
  manuel kullanıcı kabulü gerektirir.

## Issue 432 — Ajanda–Hatırlatıcı bağı 0..N read-model olarak görünürdür

- Bir Ajanda kaydı sıfır veya birden çok Hatırlatıcıya kaynak olabilir. Aktif ve
  çöpteki bağlı kayıtlar aynı deterministik sorgudan ayrı read-model
  koleksiyonlarına bölünür; source bağlantısı veya lifecycle durumu değişmez.
- Ajanda app-bar Hatırlatıcı eylemi bağlı kayıt seçmez ve her zaman yeni kayıt
  oluşturma anlamındadır. Mevcut bağlı kayıtlar yalnız kendi exact kimlikli
  kartlarından açılır; arşivli veya Beton tarafından yönetilen Ajanda yeni
  Hatırlatıcı üretemez.
- Kaynak Ajanda arşivlendiğinde Hatırlatıcı yaşam döngüsü ve read-only kaynak
  fotoğrafları korunur; Hatırlatıcı detayında kaynak arşiv durumu ayrıca
  görünür kılınır. Archive/trash/complete durumları birbirine çevrilmez.

## Issue 434 — Ajanda → Hatırlatıcı sync açık, tek hedefli ve atomiktir

- Sync yalnız çağıranın seçtiği `title | description | location` logical
  alanlarını transaction içindeki güncel Ajanda satırından exact bağlı
  Hatırlatıcıya taşır. `captureText`, source/project bağı, lifecycle, plan,
  deadline, importance, kişi/koşul/outcome ve notification binding değişmez.
- Source ve target revision birlikte doğrulanır. Gerçek diff yoksa revision veya
  event üretilmez; diff varsa yalnız target revision bir artar ve source satırı
  immutable kalır.
- Reminder `details_updated` ve Ajanda
  `agenda_log.reminder_sync_applied` eventleri aynı operation kimliği ve
  deterministic selected/copied field özetiyle tek SQLite transaction içinde
  yazılır. İki eventten herhangi biri başarısızsa target update dahil tamamı
  rollback olur.
- Exact başarılı retry, iki event payloadındaki canonical operation/result
  fingerprint'ini stale revision kontrolünden önce tanır ve önceki sonucu
  idempotent döndürür. Aynı event/operation kimliğinin farklı hedef, alan veya
  payload ile kullanımı fail-closed reddedilir; yeni ledger veya schema gerekmez.
- Stable source mahal arşivlenmiş olsa da mevcut source linki salt-okunur
  aktarılabilir; bu işlem mahalı restore etmez veya yeni aktif seçim gibi
  yorumlamaz. Reverse, toplu veya background sync yoktur.

## Issue 437 — Ajanda → Hatırlatıcı sync yalnız görünür diff ve açık onayla başlar

- Sync eylemi yalnız exact açık Hatırlatıcı detayında; kaynak Ajanda güvenli,
  aktif ve aynı proje/link bağlamındaysa, hedef çöpte/terminal değilse ve izinli
  üç alandan en az biri gerçekten farklıysa görünür. Ajanda tarafında toplu veya
  `first` hedef seçimi yapılmaz.
- Confirmation yalnız farklı `Başlık | Açıklama | Mahal` satırlarını mevcut ve
  gelecek kullanıcı-dostu değerlerle gösterir. Bütün diffler varsayılan seçili
  olabilir; kullanıcı alanları çıkarabilir, seçim kalmazsa mutation kapalıdır.
- UI command içine yeni field value koymaz. Fresh operation/source/target event
  UUID'leri, preview source/target revision'ları ve yalnız seçilmiş field seti
  mevcut Slice 2 transactionına gönderilir; gerçek source değerleri mutation
  anında application katmanında yeniden türetilir.
- Başarı ve no-op sonrasında source/target yeniden yüklenir. Stale veya
  validation failure optimistic text rewrite üretmez; hata gösterilir ve güvenli
  reload sonrası yeni diff kullanıcıya tekrar sunulur. Dialog ve mutation busy
  guard ile tek çağrı üretir.
- Source photo/media, arşiv banner'ı ve çift yönlü navigation mevcut sırasını ve
  salt-okunur davranışını korur; schema 13, Backup format 1, lifecycle,
  notification, attachment, platform ve dependency sözleşmeleri değişmez.

## Issue 439 — V2.4 kapanışı yeni davranış değil karakterizasyon kanıtıdır

- Ajanda ve Hatırlatıcı ayrı source-of-truth olarak kalır. Ajanda 1 →
  Hatırlatıcı 0..N bağı exact kart/read-model ile görünür; create yolu mevcut
  hedef açma yolundan ayrıdır.
- Ajanda → Hatırlatıcı sync yalnız exact açık hedefte, gerçek
  `title | description | location` diffi, açık alan seçimi ve kullanıcı onayıyla
  başlar. Reverse/toplu/background sync ve otomatik lifecycle mapping yoktur.
- Mutation iki revisionı ve kalıcı link/proje/lifecycle bağlamını transaction
  içinde doğrular; source'u değiştirmez, yalnız gerçek target diffini yazar ve
  iki taraflı eventleri aynı operation kimliğiyle atomik üretir. Exact retry
  idempotent, fingerprint/kimlik collisionı fail-closed kalır.
- Source link ve salt-okunur source media archive/trash/restore/reopen boyunca
  korunur. Schema 13, Backup format 1, attachment, notification, dependency,
  permission ve platform sözleşmeleri değişmez.
- Issue #439 closure PR'ı merge edilmeden Epic #385 içindeki V2.4 tamamlandı
  sayılmaz ve V2.5 current direction yapılmaz; Ready ve merge owner/review
  kapılarına bağlıdır.

## Issue 460 — Güncel ürün yönü 7 Günlük Yaşayan İş Programıdır

- V2 13 maddelik paket olarak kalır; Items 1–4 complete, revised Item 5
  `7 Günlük Yaşayan İş Programı / İş ve Gün Planı` current ve not complete'tir.
  Eski Item 6 iş/gün planı semantiği Item 5'e alınır; Günlük Log Çıktısı v1
  Item 6'ya taşınır.
- CSE teknik olarak binlerce inşaat aktivitesi ve deterministik bağımlılık
  taşıyabilir; şantiye şefi aktiviteyi arar, yakın plana birkaç işlemle ekler ve
  yalnız önündeki yedi günü güncel tutar. Living Plan, Primavera klonu veya
  approved/contractual baseline değildir.
- PR #444/#446/#448/#456/#459 zincirindeki Activity Catalog, typed Project
  Profile/Dependency Catalog, Project Activity Instance Graph, Schedule Date
  Engine ve persistent immutable reference snapshots merged technical
  foundation'dır. Safe merge
  `447916be0b3ddd2af75b0fe85f8c7f710f29c1cd`, schema `14`, backup format `1`
  ve mobile version `0.1.0+1` current'tır.
- Reference schedule suggestion/history olarak immutable kalır. Living-plan
  kullanıcı kararları stable project/activity-instance/snapshot kimliklerine
  referans veren ayrı mutable/evented katmanda tutulur; user action reference
  schedule'ı sessizce yeniden yazmaz.
- UI'dan önce yalnız tek dar Living Plan MVP Core slice'ı gelebilir. Immediate
  successor 7-day UI + APK/device acceptance'tır; araya broad backend programı
  girmez.
- Critical path/float, full Gantt/Primavera replacement, approved baseline,
  automatic reforecast, productivity learning, resource optimization ve
  AI/cloud planning ilk usable UI/device pilotundan sonradır.
- Bu karar source/state truth-sync'tir; Living Plan production behavior,
  UI/APK/device acceptance, public/store release veya production readiness
  iddiası üretmez.
