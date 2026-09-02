# CSE Codex Repository Instructions

Bu dosya repository kökünde bütün CSE çalışmalarına uygulanır ve günlük execution için tek zorunlu giriş noktasıdır.

## 1. Güncel gerçek ve kaynak otoritesi

- Güncel repository gerçeği: GitHub `master`, current Issue/PR/branch ve owner kararları.
- Kalıcı ürün amacı ve veri ilkeleri: `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`.
- Güncel ürün kapsamı ve sıra: `docs/v2/CSE_V2_SCOPE.md` ve `ROADMAP.md`.
- Kritik Git ve veri güvenliği: `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`.
- Lane ve publication ayrıntıları: `docs/protocols/CSE_WORKFLOW_ACCELERATION_PROTOCOL.md`.
- Test/gate ayrıntıları: `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md`.

Sabit master SHA, schema, app version, aktif Issue/PR veya roadmap ilerlemesi kalıcı protokollerde tutulmaz. Bunlar her görevde GitHub/repository üzerinden okunur.

README, eski Issue/PR, `.cse/state`, task/result, ZIP, handoff, podcast veya sohbet hafızası current GitHub gerçeğini override edemez.

## 2. Yeni sohbet ve resume

Yeni görevde zorunlu okuma:

1. `AGENTS.md`
2. current GitHub `master`, açık Issue/PR ve aktif görev
3. yalnız değişen sözleşmenin gerektirdiği koşullu kaynak

Koşullu okuma:

- ürün/veri kararı: Unified Source;
- ürün kapsamı/sırası: V2 Scope ve Roadmap;
- Git veya kullanıcı verisi riski: Project Instructions;
- test/gate kararı: Minimum Validation;
- STANDARD/CRITICAL publication: Workflow Acceleration;
- kritik model/review ihtiyacı: Model Routing;
- kalıcı kritik handoff: Codex Instruction Comment Protocol.

Aynı görev resume ediliyorsa değişmeyen uzun kaynaklar tekrar okunmaz. Kullanıcı `devam` dediğinde current GitHub durumu bulunur ve sıradaki gerçek işlem yapılır.

GitHub'a erişilemiyorsa güncel durum tahmin edilmez ve production işi başlatılmaz.

## 3. Zorunlu lane seçimi

Her iş yalnız bir lane kullanır:

### FAST

Dar documentation, metin, icon, tooltip, spacing, layout, presentation, basit navigation veya persistence contract'ını değiştirmeyen küçük UI işi.

FAST varsayılanı:

- temiz ve senkron yerel `master`;
- tek davranış;
- en fazla 5 dakikalık Codex işlemi;
- Issue, remote branch, PR, `.cse` task/result ve routing YAML yok;
- Codex yalnız format, changed-path review ve `git diff --check` yapar;
- test/analyzer/build/device işlemlerini Fatih çalıştırır;
- Fatih `PASS` bildirmeden commit veya push yapılmaz;
- FAIL/PENDING durumunda yeni işe geçilmez.

### STANDARD

Birden fazla ekran/modül, session/project context veya persistence/release-critical olmayan orta ölçekli behavior değişikliği.

STANDARD varsayılanı:

- tek kısa Issue veya self-contained görev özeti;
- tek kısa ömürlü branch;
- 5 dakikalık Codex mikro adımları;
- test/analyzer/build/device işlemleri Fatih'te;
- `.cse` ve routing YAML varsayılan olarak yok;
- bağımsız diff review değer üretiyorsa tek Draft PR;
- mevcut iş master'a alınmadan yeni production branch açılmaz;
- stacked PR yasaktır.

### CRITICAL

Schema/migration, backup/restore, stable identity/revision, transaction/event/history, attachment veya kullanıcı dosyası bütünlüğü, destructive işlem, security/privacy, permission/signing/application ID, background/reboot, DWG conversion data-loss riski, gerçek kullanıcı data root'u veya release/store işi.

CRITICAL varsayılanı:

- exact Issue, allowlist ve stop conditions;
- branch ve Draft PR;
- gerekli `.cse` provenance;
- Issue'ya özel validation/compatibility/device/release gate;
- bağımsız derin review;
- Ready/merge/release için owner kararı.

Somut CRITICAL trigger yoksa iş ağır sürece yükseltilmez.

## 4. Beş dakika ve test sahipliği

Tek bir Codex execution/correction/commit işlemi 5 dakikayı geçmez.

Beş dakika dolduğunda:

- yeni yaklaşım başlatılmaz;
- kapsam genişletilmez;
- tamamlanan değişiklik, blocker ve kalan tek adım raporlanır.

Codex:

- test, analyzer, build, emulator, ADB veya cihaz işlemi çalıştırmaz;
- exact kullanıcı test komutunu ve manuel kontrolü verir;
- yalnız kaynak düzenleme, format, diff ve Git kapsam kontrolünü yapar.

Fatih:

- focused/full testleri;
- analyzer ve build'i;
- APK/install ve cihaz kabulünü;
- ürün davranışı ve görsel kabulü çalıştırır.

Aynı source revision üzerinde geçen test tekrarlanmaz. Full suite her mikro adımda değil, birleşik milestone veya release kapısında çalıştırılır.

## 5. Değişmez güvenlik sınırları

- CSE owner-only, local-first ve mobile-first kalır.
- Gerçek kullanıcı data root'u açık CRITICAL authority olmadan okunmaz/değiştirilmez.
- Production/debug paketleri sıradan automation tarafından başlatılmaz, temizlenmez veya mutate edilmez.
- Stable identity, optimistic revision, append-only event/history, transaction, backup/restore ve attachment bütünlüğü korunur.
- Force-push, destructive reset/clean/stash, hard-delete ve beklenmeyen kullanıcı değişikliğinin üzerine yazma yasaktır.
- Beklenmeyen tracked/untracked değişiklikte işlem durur; otomatik temizleme yapılmaz.
- Ready, merge, Issue closure, release/store ve destructive production işlemleri owner onayı gerektirir.

## 6. Git ve publication

- FAST: user PASS sonrası küçük commit ve normal push; test öncesi commit/push yok.
- STANDARD: en fazla bir aktif production branch/PR; squash merge varsayılanı.
- CRITICAL: Issue'ya özel branch/PR/review zinciri.
- Force-push yapılmaz.
- Stacked PR oluşturulmaz.
- Protokol kabul edildiğinde zaten açık olan legacy/stacked production PR'lar bir defalık geçiş kuyruğudur; yeni stack açma yetkisi vermez. Kuyruk çözülene kadar yeni production branch açılmaz; mevcut PR'lar current master'a birer birer uyarlanır ve Ready/merge/close yalnız owner kararıyla yürütülür.
- Cihaz APK'sı mümkün olduğunda güncel birleşik master'dan üretilir.
- Merge sonrası local master bir sonraki local işten önce `--ff-only` senkronlanır.

## 7. Evidence ve çıktı

FAST completion en fazla şu bilgileri taşır:

```text
Değişen davranış: <tek cümle>
Değişen dosyalar: <liste>
Codex kontrolleri: format / diff-check
Fatih testi: PENDING | PASS | FAIL
Commit/push: yapılmadı | <sha>
```

STANDARD sonucu kısa Issue/PR kaydıdır. CRITICAL ayrıntılı provenance taşıyabilir.

Aynı bilgi Issue, comment, task, result, state ve PR body içinde tekrar edilmez.

Owner'a önce ürün/pratik anlam sade Türkçeyle anlatılır. Teknik YAML ve execution evidence yalnız gerektiğinde ikinci katmanda verilir.

## 8. Ana karar

> Düşük riskte hızlı ve owner-testli master akışı; orta riskte tek kısa branch; gerçek veri/release riskinde tam güvenlik süreci. Güvenlik küçük UI işlerine değil, gerçekten zarar verebilecek sözleşmelere yoğunlaştırılır.
