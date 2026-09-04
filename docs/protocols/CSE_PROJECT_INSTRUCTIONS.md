# CSE Proje Talimatları — Git ve Veri Güvenliği

**Belge türü:** Bağlayıcı güvenlik ve repository protokolü
**Güncelleme tarihi:** 2026-09-04

Bu belge günlük workflow'u tekrar etmez. Günlük lane, süre, test sahipliği ve publication için `AGENTS.md` ile `CSE_WORKFLOW_ACCELERATION_PROTOCOL.md` uygulanır. Bu belge kritik Git, kullanıcı verisi ve repository güvenliği için yetkilidir.

## 1. Ürün ve veri sınırı

CSE yalnız şantiye şefi tarafından kullanılan local-first ve mobile-first kişisel saha asistanıdır.

Değişmez ilkeler:

- resmî kayıtlar fiziksel olarak silinmez; arşivlenir, pasifleştirilir, hükümsüz kılınır veya yeni revizyonla değiştirilir;
- kanıt niteliği taşıyan davranış açık görev kapsamında audit izi bırakır;
- medya veritabanına gömülmez; dosya, metadata ve bütünlük birlikte korunur;
- private ve project output verisi ayrıdır;
- sistem kendiliğinden `blocked` veya resmî kabul/ret kararı üretmez;
- `requires_human_review` yalnız insan inceleme sinyalidir;
- multi-user/tenant/SaaS aktif ürün hedefi değildir;
- hard validation, migration, persistence, backup/restore, permission ve release ayrı açık kapsam ister.

Kalıcı ürün amacı için `CSE_UNIFIED_PROJECT_SOURCE.md` üst kaynaktır.

## 2. Güncel durum kaynağı

Güncel durum yalnız şunlardan okunur:

1. GitHub `master` HEAD;
2. current Issue/PR/branch ve owner scope kararları;
3. ilgili commit diff ve gerçekleşmiş test kanıtı;
4. gerekiyorsa resmî yerel repository durumu.

Kalıcı protokollere master SHA, schema, aktif Issue/PR, test sayısı veya roadmap snapshot'ı gömülmez.

README, `.cse/state`, task/result, ZIP, handoff, podcast veya sohbet hafızası current GitHub gerçeğini override edemez.

## 3. Resmî yerel çalışma kopyası

Production kodu, test, build, cihaz ve normal local Git yürütmesi için resmî repository:

```text
V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer
```

Local edit öncesinde:

- repository root doğrulanır;
- `git status --short --branch` okunur;
- master/origin divergence kontrol edilir;
- yarım merge/rebase/cherry-pick bulunmadığı doğrulanır;
- beklenmeyen değişiklik varsa işlem durur.

CSE için otomatik alternatif clone/workspace production execution kaynağı yapılmaz.

Documentation-only policy/source güncellemesi, owner açıkça isterse authenticated GitHub yüzeyinde ayrı branch üzerinden yapılabilir. Bu istisna production kodu, test, schema, artifact veya kullanıcı verisi düzenleme yetkisi vermez. Sonraki local işten önce resmî repository `--ff-only` senkronlanır.

## 4. Git güvenliği ve Issue disposition

- Force-push yoktur.
- Destructive reset/clean/stash yoktur.
- Beklenmeyen kullanıcı değişikliği silinmez veya üzerine yazılmaz.
- Branch/ref yalnız fast-forward veya geçerli owner yetkisi kapsamında gate'leri geçmiş squash merge ile ilerletilir.
- Hard-delete ve branch deletion otomatik yapılmaz.
- Ignored ZIP, backup, report veya kullanıcı artifact'larına dokunulmaz.
- Merge sonrası local master bir sonraki local değişiklikten önce `git pull --ff-only` ile senkronlanır.
- Issue closure açık owner disposition'ıyla kontrol edilir.
- Tek amaçlı ve tamamen tamamlanmış bir implementation Issue'su için PR body açıkça `Closes #...` kullanıyorsa, standing merge yetkisi otomatik Issue kapanışını da kapsar.
- Parent, umbrella, manuel acceptance, release veya devam kapsamı bulunan Issue'lar `Refs #...` ile açık bırakılır.
- Issue'nun tamamen tamamlandığı belirsizse `Refs` kullanılır; otomatik kapanış yapılmaz.
- Standing owner yetkisi yalnız PR Ready/squash merge içindir. Required herhangi bir gate FAIL/PENDING iken Ready/merge yapılmaz. Required source/diff review ile task-specific validation ve gerekli manual/device acceptance PASS veya açıkça GEREKMİYOR ise; blocker, REQUEST_CHANGES, scope/allowlist/base/head drift, conflict ve mergeability sorunu yoksa ChatGPT ayrıca Fatih'e sormadan Ready ve squash merge işlemlerini yürütür.
- CRITICAL PR'lerde bu yetki ancak Issue'ya özel bütün validation/compatibility/manual kapıları geçtikten sonra kullanılabilir. Release/store ve destructive production/device/data işlemleri ayrı açık owner onayı ister.
- Fatih standing Ready/merge yetkisini sonraki bir owner talimatıyla iptal edebilir veya askıya alabilir.

## 5. Kullanıcı verisi ve cihaz güvenliği

- Gerçek kullanıcı data root'u yalnız açık CRITICAL authority ile okunur/değiştirilir.
- MAIN/production ve debug paketleri sıradan automation tarafından başlatılmaz, temizlenmez veya mutate edilmez.
- Uninstall, clear-data, hard-delete, restore veya destructive migration ayrı owner onayı ister.
- Test projesi ve package kimliği açıkça doğrulanır.
- ADB seri numarası, yerel yol, imzalama bilgisi ve kişisel veri public evidence'a yazılmaz.

## 6. Kritik sözleşmeler

Aşağıdakiler yalnız CRITICAL lane'de değiştirilebilir:

- schema/migration;
- backup/restore formatı;
- stable identity ve optimistic revision;
- transaction, append-only event/history;
- attachment ve kullanıcı dosyası bütünlüğü;
- permission, signing, application ID ve platform ayarları;
- security/privacy;
- background/reboot engine;
- DWG dönüşümünde data-loss/corruption riski;
- release/store artifact'i.

Issue exact allowlist, compatibility, rollback, test ve stop koşullarını taşır.

## 7. Workflow ve test yönlendirmesi

- Lane ve publication: `CSE_WORKFLOW_ACCELERATION_PROTOCOL.md`.
- Test/gate seçimi, Codex execution ve owner manuel kabulü: `CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md`.
- Model/review seçimi: `CSE_MODEL_REASONING_ROUTING_POLICY.md`.

Bu belge bütün görevlerde full suite veya `.cse` ledger zorunlu kılmaz.

## 8. Roller

### Codex

- yalnız izinli dosya ve davranışta çalışır;
- her handoff'ta ChatGPT'nin açıkça atadığı göreve özel execution time budget'a uyar; global sabit süre varsaymaz, bütçe dolunca çalışmayı güvenle koruyup durur ve exact blocker/kalan aksiyonu raporlar;
- repository-local terminal, automated test, analyzer ve build/APK hazırlığını yetkili görev kapsamında çalıştırır; manuel ürün kabulü vermez;
- emulator/ADB/device işlemini yalnız Fatih'in exact package/device/data-safety sınırıyla açık delegasyonunda çalıştırabilir;
- format, diff, scope ve Git güvenliğini kontrol eder;
- non-CRITICAL işte Codex automated PASS sonrası, manuel/device kabul gerekmiyorsa yetkili commit/push yapabilir; kabul gerekiyorsa ayrıca Fatih PASS bekler;
- belirsizlik veya yeni CRITICAL trigger'da durur.

### ChatGPT

- her talepte execution öncesi current GitHub durumunu, lane'i, sıradaki tek aksiyonu ve sorumlu aktörü belirler;
- repository/local execution gerekiyorsa kullanıcının `Codex ile çalış` demesini beklemeden kısa exact Codex handoff'u verir; Fatih'e terminal/Git/Flutter/test/analyzer/build komutu vermez;
- bu belgenin 3. bölümündeki açık documentation-only owner istisnası dışında GitHub Contents API üzerinden repository dosyası değiştirmez;
- kendi yetkisindeki mevcut owner-approved koordinasyonu ayrıca `devam` istemeden yürütür;
- kullanıcıya ürün anlamını açıklar ve her teslim edilen sonucu `Sıradaki aksiyon — <aktör>: <tek uygulanabilir talimat>.` satırıyla bitirir;
- gereksiz Issue/comment/PR/metadata üretmez;
- merge öncesinde incelenen PR body'ye göre hangi Issue'ların kapanacağını ve hangilerinin açık kalacağını açıklar;
- required review/validation/manual ve drift/mergeability kapılarını fail-closed doğrular; gate'ler geçince standing owner yetkisiyle Ready/squash merge'i otomatik yürütür.

### Fatih

- ürün kapsamı ve nihai risk kararının sahibidir;
- yalnız manuel ürün/device kabulünü ve nihai davranış PASS/FAIL kararını verir; terminal komutu çalıştırmaz;
- mekanik emulator/ADB/device execution'ını yalnız exact güvenlik sınırlarıyla Codex'e açıkça devredebilir;
- PASS/FAIL ve ürün kabulü kararını kendisi verir;
- standing yetki yürürlükteyken required gate'leri geçen PR'ler için ChatGPT'den yeni Ready/merge onayı istenmez; Fatih bu yetkiyi sonraki owner talimatıyla iptal edebilir veya askıya alabilir;
- release/store ve destructive production/device/data işlemlerini ayrı açıkça onaylar;
- incelenen PR body'de açıkça `Closes` ile belirtilen tekil Issue closure'ını standing merge yetkisi kapsamında bırakır; `Refs` Issue'lar açık kalır.

## 9. Ana karar

> Repository ve kullanıcı verisi güvenliği değişmez. Günlük çalışma töreni bu belgeye değil `AGENTS.md` içindeki risk-temelli lane'e göre yürür; required gate'ler geçince standing owner yetkisi Ready/squash merge ve açık `Closes` disposition'ı için otomatik uygulanır. Release/store, destructive işlemler ve gerçek kritik sözleşmeler ayrı owner onayıyla ağır güvenlik sürecinde kalır.
