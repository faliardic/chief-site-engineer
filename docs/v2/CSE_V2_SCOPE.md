# CSE V2 Kanonik Kapsamı

**Belge türü:** Güncel ürün yürütme kapsamı
**Durum:** Kanonik V2 kapsam ve sıra kaynağı
**Tarih:** 25 Ağustos 2026
**Güncel yön kaynağı:** Issue #485 — İstenecek Malzemeler v1 source-of-truth + lifecycle UI
**Güncel güvenli `master`:** `dbe370e61b5ece843238c35e049bbaa4e7df19cb` / PR #484

## 1. Belgenin rolü

Bu belge, CSE V2 içinde hangi ürün işlerinin yapılacağını, hangi sırayla
ilerleneceğini ve hangi çalışmaların V2 dışında kalacağını belirler.

Kaynak otoritesi bilgi türüne göre ayrılır:

| Bilgi türü | Yetkili kaynak |
| --- | --- |
| Kalıcı ürün amacı ve veri ilkeleri | `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md` |
| Güncel V2 ürün kapsamı ve bağımlılıkları | Bu belge |
| Ayrıntılı yürütme sırası | `ROADMAP.md` |
| Operasyon ve güvenlik kuralları | `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md` |
| Doğrulama genişliği ve bütçesi | `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md` |
| Aktif teknik dilim | Güncel GitHub Issue |

Eski roadmap, Epic, Orchestrator, Bridge, Work Mode, handoff, podcast veya
`.cse/state` kayıtları tarihsel bağlam sağlayabilir; fakat bu belgedeki güncel
V2 kapsamını genişletemez veya değiştiremez.

## 2. V1 kapanış gerçeği

CSE V1, proje sahibinin kararıyla tamamlanmış ürün fazıdır.

- Son doğrulanmış V1 baseline commit'i:
  `7c9f65a811c9f4bca561adab6bd1f8e64e6908cc`
- Son baseline PR'ı: #382
- Mobil sürüm: `0.1.0+1`
- Mobil SQLite schema: `10`
- `.csebackup` formatı: `1`
- Canonical timezone: `Europe/Istanbul`
- Android compile/target SDK: `36 / 36`
- Proje sahibi V1'i yaklaşık bir ay gerçek sahada kullanmıştır.
- Bu saha kullanımı, geriye dönük günlük test kanıtı uydurulacağı anlamına
  gelmez.
- V1'in tamamlanması, Google Play/App Store yayını veya kamuya açık production
  release yapıldığı anlamına gelmez.
- V1 modülleri dondurulmamıştır; V2 içinde güvenli biçimde geliştirilmeye devam
  eder.

V1 tarihsel baseline'dır. V2, aynı offline-first mobil ürünü yeniden yazmak
yerine bu baseline üzerinde ilerler.

Güncel merged V2 teknik baseline'ı V1 metadata'sından ayrıdır: mobile version
`0.1.0+1`, SQLite schema `17`, backup format `1` ve son güvenli merge
`dbe370e61b5ece843238c35e049bbaa4e7df19cb` / PR #484 değeridir. Bu baseline,
schedule runtime ve persistent immutable reference-schedule snapshot temeliyle
Living Plan MVP Core, 7-day UI/APK/device acceptance, Actual Progress Core ve
progress UI/isolated device acceptance, deterministic forecast core ve immutable
snapshot dependency graph persistence ve read-only downstream dependency impact
core'u, Issue #476 / PR #480 Living Plan intelligence UI implementation'ını ve
Issue #481 / PR #482 Deterministic Günlük Log v1 read modelini ve Issue #483 /
PR #484 read-only İş Zinciri v1'i içerir. Living
Plan UI manual testleri pending, Günlük Log manual testleri deferred kalır; mutation/
reforecast, public/store release veya genel production readiness ilanı değildir.

## 3. V2'nin amacı

V2'nin amacı yeni modül sayısını büyütmek değil, sahadaki bilgiyi bir kez
yakalayıp doğru proje, mahal, kişi, dosya, iş ve günlük bağlamında tekrar
kullanılabilir hâle getirmektir.

Ana yön:

```text
Proje/Mahal, Saha Rehberi, Attachment ve Ajanda omurgası — complete
→ schedule runtime + persistent reference snapshots — merged
→ Living 7-Day Plan MVP Core — merged / PR #463
→ 7-day UI + APK/device acceptance — merged / PR #465
→ Issue #466 Actual Progress Core — merged / PR #467
→ Issue #468 Progress UI + Isolated Device Acceptance — merged / PR #469
→ Issue #470 Deterministic Living Plan Forecast Core — merged / PR #471
→ Issue #472 Immutable Snapshot Dependency Graph Persistence — merged / PR #473
→ Issue #474 Read-only Downstream Dependency Impact Core — merged / PR #475
→ Issue #476 Living Plan Intelligence UI — merged / PR #480 / manual test pending
→ Issue #481 / PR #482 Deterministic Günlük Log v1 — merged / manual test deferred
→ Issue #483 / PR #484 Agenda–Takip İş Zinciri v1 — merged / manual test deferred
→ Issue #485 İstenecek Malzemeler v1 — current
→ schedule mutation/reforecast, actual quantity ve productivity learning — not started
```

CSE teknik olarak derin, operasyonel olarak sade kalır: binlerce inşaat
aktivitesi ve deterministik bağımlılık içeride bulunabilir; şantiye şefi
aktiviteyi arar, yakın plana birkaç işlemle ekler ve yalnız önündeki yedi günü
güncel tutar. Bu living site plan, Primavera klonu veya resmî/kontratsal
baseline değildir.

## 4. Kanonik 13 maddelik V2 paketi

| No | Ürün ailesi | Durum |
| ---: | --- | --- |
| 1 | Proje ve Mahal omurgası | Complete |
| 2 | Sicil / Puantaj V2 / Saha Rehberi | Complete |
| 3 | Attachment / Fotoğraf / Medya V2 | Complete |
| 4 | Ajanda V2 + Ajanda–Hatırlatıcı kontrollü senkron | Complete |
| 5 | 7 Günlük Yaşayan İş Programı / İş ve Gün Planı | Implemented — manual test pending |
| 6 | Günlük Log Çıktısı v1 | Implemented — manual test deferred; completion not declared |
| 7 | İş Zinciri / Bağlı Log v1 | Implemented — manual test deferred; completion not declared |
| 8 | İstenecek Malzemeler | Current — not complete |
| 9 | Deterministik kişi/firma/etiket önerileri | Planned |
| 10 | Telefon görüşmesi sonucu → Ajanda | Planned |
| 11 | Proje fotoğraf/video albümü | Planned |
| 12 | Günlük Log Çıktısı v2 | Planned |
| 13 | Mini hesap makinesi | Planned |

### 1. Proje ve Mahal omurgası

Amaç:

- Proje kayıtlarını düzenleme ve arşivleme yaşam döngüsüne taşımak.
- Mahal/konum kayıtlarına stable ID vermek.
- Ajanda, Hatırlatıcı, Puantaj, Beton ve sonraki V2 kayıtlarını aynı proje ve
  mahal kimliklerine bağlamak.
- İsim değişikliğinin geçmiş kayıt bağlantılarını bozmamasını sağlamak.

Kapanış kapısı:

- Proje ve mahal kimlikleri stable'dır.
- Eski kayıtlar migration sonrasında aynı bağlama bağlıdır.
- Archive/restore fiziksel veri kaybı üretmez.
- Backup/restore round-trip korunur.

### 2. Sicil / Puantaj V2 / Saha Rehberi

Amaç:

- Taşeron, ekip, personel, kişi ve firma kayıtlarını ortak kimlik omurgasında
  toplamak.
- Puantajın aynı personel kimliklerini kullanmasını sağlamak.
- Kişi/firma iletişim bilgilerini saha rehberinde erişilebilir kılmak.
- Arşivlenen kişi ve firmaların geçmiş puantajını korumak.

Kapanış kapısı:

- Aynı kişi Puantaj ve Sicil'de tek ID ile temsil edilir.
- Aktif/arşiv ayrımı yeni gün seçimini ve geçmiş görünümünü doğru etkiler.
- İSG/SGK/KKD ve belge bağları kaybolmaz.
- Gerçek saha seçimi kalabalık ve tekrar eden isim listesi üretmez.

### 3. Attachment / Fotoğraf / Medya V2

Amaç:

- Fotoğraf, video, ses ve belge için ortak attachment ve link sözleşmesi kurmak.
- Aynı fiziksel dosyanın modüller arasında gereksiz kopyalanmasını önlemek.
- Kaynak kayıt, proje, mahal, kişi ve iş bağlantılarını korumak.
- MIME, hash, boyut, güvenli path, staging ve backup bütünlüğünü sürdürmek.

Kapanış kapısı:

- Bir dosya birden çok kayda güvenli biçimde bağlanabilir.
- Orphan, broken link ve hash uyuşmazlığı görünürdür.
- Çoklu seçim ve temel viewer/player akışı çalışır.
- Backup/restore dosya ve linkleri eksiksiz korur.

### 4. Ajanda V2 ve kontrollü Ajanda–Hatırlatıcı senkronu

Amaç:

- Ajanda logunu saha olaylarının canonical zaman çizgisi olarak geliştirmek.
- Ajanda kaydından Hatırlatıcı oluşturmayı ve karşılıklı görünürlüğü
  güvenilirleştirmek.
- Kullanıcı açıkça seçmediği sürece metin veya durumların sessizce birbirini
  yeniden yazmamasını sağlamak.
- Düzenleme geçmişi, kaynak bağlantısı ve attachment görünürlüğünü korumak.

Kapanış kapısı:

- Ajanda ve Hatırlatıcı ayrı source-of-truth kayıtlar olarak kalır.
- Kullanıcı kontrollü senkron açık ve geri izlenebilirdir.
- Duplicate oluşturma ve stale revision kısmi mutation bırakmaz.
- Arşiv/çöp durumunda kaynak bağlantısı kaybolmaz.

### 5. 7 Günlük Yaşayan İş Programı / İş ve Gün Planı

Amaç:

- Projeye özgü güncel yedi günlük pencereyi göstermek.
- İnşaat aktivite kataloğunda arama yapıp ilgili aktiviteyi birkaç işlemle
  yakın plana eklemek.
- Aktivite adı ile blok/kat/mahal bağlamını birlikte göstermek.
- Öneri tarih ve süreyi onaylı baseline gibi sunmamak.
- `Planlandı`, `Başladı`, `Tamamlandı`, `Ertelendi` durumlarını ve kısa saha
  notunu offline korumak.
- Normal backup/restore zincirinde Living Plan verisini geri getirmek.

Mimari sınır:

- Immutable reference schedule suggestion/history olarak kalır.
- Living-plan kullanıcı kararları ayrı mutable/evented katmanda tutulur.
- Living plan stable project/activity-instance/snapshot kimliklerine referans
  verir; kullanıcı işlemi reference schedule'ı sessizce yeniden yazmaz.
- Düşük güvenli/test-seed süreleri yalnız öneridir, resmî süre değildir.
- Güncel tarih penceresi trusted snapshot repository sınırını yeniden kullanır.
- Living Plan MVP Core PR #463 ve 7-day UI/APK/device acceptance PR #465 ile
  merged predecessor zinciridir.

Kapanış kapısı:

- Yedi günlük pencere, arama/ekleme, konum bağlamı, minimum durum seti ve kısa
  not kullanıcıya sade biçimde sunulur.
- Reopen sonrasında plan offline korunur ve normal backup/restore ile geri gelir.
- User decision/reference schedule ayrımı test ve review ile doğrulanır.
- PR #465 ile merged ilk usable UI/APK/device kabulü Item 5'in ilk kullanıcı
  kapısıdır; tek başına final completion değildir.
- Issue #466 / PR #467 merged nullable actual-progress source-of-truth
  foundation'ını taşır: `NULL` bilinmeyen/raporlanmamış, açık item explicit
  progress `0..99`, `COMPLETED` exact `100`dür.
- Optimistic revision, durable idempotency/no-op receipt ve append-only event
  sözleşmesi korunur.
- Issue #468 / PR #469 bu gerçeği kartlarda görünür kılan, yalnız
  `STARTED`/`DEFERRED` item için `0..99` editini açan ve isolated acceptance
  paketinde lifecycle/relaunch persistence'ı kanıtlayan merged predecessor'dır.
- Issue #470 / PR #471 item'ın exact bound reference snapshot süresini progress
  ile read-only ve deterministik yorumlayan merged predecessor'dır.
- Issue #472 / PR #473 yalnız yeni schedule snapshot'ların kendi exact resolved
  dependency graph'ını immutable manifest/count/hash ile saklayan merged
  predecessor'dır. Historical snapshot'lara backfill yapılmaz; manifest yokluğu
  zero-edge değil typed unavailable'dır.
- Issue #474 / PR #475 exact origin forecast/snapshot/graph binding'inden deterministic
  topological sırada bütün incoming constraint'lerin maksimumunu uygulayan
  salt-okunur downstream impact merged predecessor'dır. Aktiviteyi reference
  tarihinden erkene çekmez ve source finish-only gecikmesini outgoing SS'e
  yanlış taşımaz.
- Issue #476 / PR #480 bu exact forecast/impact bilgisini yalnız `STARTED +
  explicit progress` item kartında ve read-only detail'de gösteren merged
  implementation'dır; legacy unavailable graph için impact uydurmaz ve manual
  testleri #479'da pending kalır.
- Schedule/Living Plan/reference mutation ve reforecast, actual
  quantity ile project-specific productivity learning başlamamıştır.
- Item 5 final completion'ı sonraki owner kararı ve executable evidence ile
  belirlenir; bu belge Items 6–13'ü yeniden sıralamaz.

### 6. Günlük Log Çıktısı v1

Amaç:

- Seçili gün ve proje için Ajanda, Puantaj, Beton, açık takip ve living-plan /
  progress kayıtlarından kaynaklı bir günlük taslağı üretmek.
- Kişisel ve resmî kapsamı karıştırmamak.
- İlk sürümde sade, insan okunabilir ve doğrulanabilir çıktı vermek.
- Issue #481 / PR #482 exact project + İstanbul local day için read-only
  deterministic projection, typed section-unavailable ve plain-text clipboard
  preview'ı `IMPLEMENTED — MANUAL TEST DEFERRED` olarak merge etmiştir;
  MT-481-001..012 borcu #479'da korunur.
- Yeni persistence table/migration/event/receipt, PDF/file/share artifact, AI
  summary veya source mutation bu Slice'ta yoktur; V2.6 completion ayrı owner
  kararı gerektirir.

Kapanış kapısı:

- Her satır kaynak kayda geri bağlanabilir.
- Kullanıcı seçimi olmadan private kayıt resmî çıktıya girmez.
- Çıktı deterministik sıra ve tarih kullanır.
- Aynı veri tekrar yazılmadan günlük taslağı hazırlanır.

### 7. İş Zinciri / Bağlı Log v1

Amaç:

- Bir işin başlangıç, takip, bekleme, kontrol ve sonuç kayıtlarını tek zincirde
  göstermek.
- Ağır workflow motoru kurmadan kaynak ilişkilerini görünür kılmak.
- Ajanda, Hatırlatıcı, iş, kişi, dosya ve sonuç kaydını aynı bağlamda toplamak.
- Issue #483 yalnız exact `field_observations.id` kökünü, explicit
  `follow_up_items.observation_id` bağını, append-only lifecycle eventlerini ve
  current sonucu read-only projekte eder.
- Agenda ve follow-up entry point'leri aynı canonical zincire gider; project,
  source ve history bütünlük sorunları typed diagnostic üretir.
- Inference, repair, source mutation, notification/sync değişikliği, schema veya
  generic work-chain persistence yoktur.

Kapanış kapısı:

- Zincirde her öğe kendi source-of-truth kaydına bağlıdır.
- Hesaplanmış zincir doğrudan düzenlenmez.
- Kırık bağlantı sessizce başka kayda bağlanmaz.
- Kullanıcı işin neden açık veya kapalı olduğunu görebilir.

### 8. İstenecek Malzemeler

Amaç:

- Tam satın alma veya ERP sistemi kurmadan sahadaki malzeme ihtiyacını izlemek.
- Malzeme, miktar/birim, ihtiyaç tarihi, öncelik, açıklama ve durum tutmak.
- İlk durum zincirini `İhtiyaç var → İstendi → Geldi / İptal` ile sınırlamak.
- Issue #485 yalnız additive schema 18 material request source-of-truth,
  append-only events, optimistic revision, same-project mahal/Living Plan
  linkleri ve sade Home UI'yı kapsar.
- Backup format 1 ve version 0.1.0+1 değişmez; satın alma/ERP, tedarikçi,
  fiyat, stok, kısmi teslim, notification, attachment ve AI kapsam dışıdır.

Kapanış kapısı:

- Kayıt proje ve mahal bağlamına bağlıdır.
- Durum değişiklikleri geçmişi korur.
- İrsaliye ve teslimat sistemi bu dilime gizlice eklenmez.
- Gün planı ve günlük logla kaynaklı ilişki kurulabilir.

### 9. Deterministik kişi/firma/etiket önerileri

Amaç:

- Mevcut kayıt ve kullanım sıklığından açıklanabilir öneriler üretmek.
- Yeni kişi, firma veya etiket uydurmamak.
- Kullanıcı seçmeden kalıcı mutation yapmamak.
- Offline ve deterministik kalmak.

Kapanış kapısı:

- Önerinin kaynağı açıklanabilir.
- Aynı girdide aynı öneri sırası oluşur.
- Private/project kapsamı korunur.
- Düşük güven durumunda öneri göstermemek kabul edilir.

### 10. Telefon görüşmesi sonucu → Ajanda

Amaç:

- Telefon görüşmesinin sonucunu kullanıcı tarafından birkaç saniyede Ajanda'ya
  aktarmak.
- Arama kaydı, rehber veya çağrı geçmişini izinsiz okumamak.
- İlgili kişi/firma, proje, mahal ve takip gereksinimini kullanıcı seçimiyle
  bağlamak.

Kapanış kapısı:

- Kullanıcı açıkça başlatır ve metni onaylar.
- CSE görüşmenin yapıldığını, gönderildiğini veya okunduğunu otomatik iddia
  etmez.
- Gerekirse bağlı Hatırlatıcı veya iş ayrı kullanıcı işlemiyle oluşturulur.
- Android izinleri gereksiz genişletilmez.

### 11. Proje fotoğraf/video albümü

Amaç:

- Ortak attachment omurgasındaki medyayı proje, mahal, tarih, kategori ve kaynak
  kayda göre göstermek.
- Galeri ile kayıt ekranı arasında duplicate dosya üretmemek.
- Büyük medya, thumbnail ve depolama kullanımını görünür kılmak.

Kapanış kapısı:

- Albüm source attachment'tan türetilen read-modeldir.
- Kaynak kayda tek dokunuşla gidilebilir.
- Arşiv ve broken-media davranışı açıktır.
- Backup boyutu ve medya sınırları kullanıcıdan gizlenmez.

### 12. Günlük Log Çıktısı v2

Amaç:

- v1 saha kullanımından sonra günlük taslağı seçilebilir bölümler, iş zincirleri,
  materyal ihtiyaçları, medya ve kaynak bağlantılarıyla geliştirmek.
- Yayımlanmış snapshot ile canlı taslağı ayırmak.
- Revizyon veya ek modelini açık biçimde kurmak.

Kapanış kapısı:

- Yayımlanmış günlük sessizce yeniden yazılmaz.
- Yeni düzeltme revision/ek olarak izlenir.
- Kaynak kimlikleri ve exact attachment bağlantıları korunur.
- Private veri sızıntısı regresyonla engellenir.

### 13. Mini hesap makinesi

Amaç:

- Uygulama içinde temel dört işlem, oran/yüzde ve kontrollü sonuç aktarımı
  sağlamak.
- Sonucu ilgili sayısal alana kullanıcı onayıyla taşımak.
- İleri mühendislik hesap motorunu bu dilime almamak.

Kapanış kapısı:

- Arbitrary code veya `eval` yolu yoktur.
- Decimal separator ve hata durumları açıktır.
- Sonuç kullanıcı onayı olmadan başka kaydı değiştirmez.
- İleri metraj ve mühendislik hesapları ayrı kapsam olarak kalır.

## 5. Geliştirme dalgaları

| Dalga | Kapsam | Geçiş kapısı |
| --- | --- | --- |
| 1 | Proje/Mahal; Sicil/Puantaj/Saha Rehberi | Stable kimlik ve migration güveni |
| 2 | Attachment/Medya V2; Ajanda V2 | Ortak dosya ve kaynak bağlantısı |
| 3 | Living 7-Day Plan; Günlük Log v1; İş Zinciri | Yaşayan yakın plan ve kaynaklı günlük akışı |
| 4 | İstenecek Malzemeler; öneriler; telefon görüşmesi | Yardımcı akışların ana omurgaya bağlanması |
| 5 | Proje albümü; Günlük Log v2 | Medya ve yayımlanmış snapshot güveni |
| 6 | Mini hesap makinesi | Dar saha aracı kabulü |

Aynı anda yalnız bir production implementation Issue'su aktif olur. Bir dalga
içindeki maddeler dahi bağımlılık sırasına göre ayrı child Issue'larla
uygulanır.

## 6. V2 dışında kalan işler

Aşağıdaki başlıklar silinmez; V2 sonrasına taşınır:

- Universal Capture
- Voice Capture ve Asistan Gelen Kutusu
- Open Loop
- Sabah Brifingi ve Akşam Kapanışı
- Büyük Resim ve Saha Nabzı
- Beton Paketi V2
- Kalite ve İSG özel dikeyleri
- Doküman Hafızası
- Şantiye krokisi/haritası
- Gömülü AI ve semantik arama
- Full-project Gantt editing ve Primavera replacement
- Approved/contractual baseline, critical path ve float hesapları
- Resource/material/machine optimization
- PC senkronizasyonu
- Çok kullanıcılı, tenant veya firma portalı yaklaşımları
- Orchestrator, Bridge ve Work Mode'un aktif ürün roadmap'i hâline gelmesi

Bu başlıklar V2 child Issue'larına yan kapsam olarak eklenemez.

Issue #466 Actual Progress Core yukarıdaki kategorik V2-dışı listede değildir;
nullable/evented/idempotent source-of-truth foundation'ını kuran merged
PR #467'dir. Issue #468 progress UI + isolated device acceptance merged PR
#469, Issue #470 deterministic read-only forecast core merged PR #471 ve Issue
#472 immutable snapshot dependency graph persistence merged PR #473'tür. Issue
#474 / PR #475 exact bağlı immutable girdilerden schedule mutation üretmeden
downstream projected impact hesaplayan merged predecessor'dır. Issue #476 / PR
#480 exact historical binding'i read-only UI'ya taşıyan merged implementation'dır;
legacy graph backfill ve reforecast başlamamıştır. Issue #481 / PR #482 Günlük
Log v1 read-modelini `IMPLEMENTED — MANUAL TEST DEFERRED` olarak merge etmiştir.
Issue #483 explicit stable Ajanda–takip bağından read-only İş Zinciri v1 kuran
current evolution'dır; V2.5, V2.6 ve V2.7 final completion ilanları ayrı owner
kararına bağlıdır.

## 7. V2 çalışma kuralları

1. Her production işi ayrı, küçük ve geri alınabilir GitHub Issue'dur.
2. Her Issue tek V2 maddesine ve mümkünse tek değişen sözleşmeye bağlıdır.
3. Migration varsa eski schema yükseltme ve backup compatibility kanıtı gerekir.
4. Gerçek kullanıcı data root'u otomasyon tarafından okunmaz veya değiştirilmez.
5. Mobil davranış offline-first ve owner-only kalır.
6. Append-only event, optimistic revision ve geri alınabilir arşiv/çöp ilkeleri
   korunur.
7. Kullanıcı onayı olmadan resmî karar, otomatik kapatma veya kapsam dönüşümü
   yapılmaz.
8. Değişmeyen geniş release/device kanıtları gereksiz yere tekrarlanmaz.
9. Saha bulguları `P0`, `P1`, `P2`, `P3` önem sınıfıyla kaydedilir.
10. P0 veri kaybı, yanlış bağlama veya backup bozulması yeni kapsamdan önce
    çözülür.
11. Geçmiş Issue, PR, podcast ve test kanıtları geriye dönük olarak yeniden
    yazılmaz.
12. GitHub Release veya store yayını yalnız ayrı release kapısıyla ilan edilir.

## 8. Her V2 maddesi için Definition of Done

- Kullanıcı problemi ve kapsam dışı alanlar açık.
- Stable kimlik ve source-of-truth sınırı belirli.
- Gerekli migration/compatibility testleri mevcut.
- Focused testler ve riskin gerektirdiği geniş kapılar PASS.
- `git diff --check` temiz.
- Gerçek kullanıcı verisi erişimi yok.
- Backup/schema/version etkisi açıkça raporlanmış.
- Gerekli saha kabulü tamamlanmış.
- Dokümantasyon uygulanan davranışı planlardan ayırıyor.
- Draft PR review ve açık kullanıcı merge kararı bulunuyor.

## 9. Güncel production yönü

V2 Items 1–4 complete'tir. Activity Catalog Runtime, typed Project Profile ve
Dependency Catalog, Project Activity Instance Graph, deterministic Schedule
Date Engine ve persistent immutable reference-schedule snapshots PR #444,
#446, #448, #456 ve #459 ile merged temeldir. Living Plan MVP Core PR #463 ve
7-day UI/APK/device acceptance PR #465 ve Actual Progress Core PR #467 ile
merged predecessor zinciridir. Progress UI + isolated device acceptance PR
#469 ile merged predecessor'a eklenmiş, deterministic forecast core PR #471 ve
immutable snapshot dependency graph persistence PR #473 ve downstream impact
core PR #475 ve Living Plan intelligence UI PR #480 ile merge edilmiştir.
Güncel güvenli `master` `bce486c92604ee38ec74c9d5300c3157794f7924`,
schema `17` ve backup format `1`dir.

Güncel canonical faz:

```text
Living Plan MVP Core — merged / PR #463
→ 7-day UI + APK/device acceptance — merged / PR #465
→ Issue #466 Actual Progress Core — merged / PR #467
→ Issue #468 Progress UI + Isolated Device Acceptance — merged / PR #469
→ Issue #470 Deterministic Living Plan Forecast Core — merged / PR #471
→ Issue #472 Immutable Snapshot Dependency Graph Persistence — merged / PR #473
→ Issue #474 Read-only Downstream Dependency Impact Core — merged / PR #475
→ Issue #476 Living Plan Intelligence UI — merged / PR #480 / manual test pending
→ Issue #481 / PR #482 Deterministic Günlük Log v1 — merged / manual test deferred
→ Issue #483 / PR #484 Agenda–Takip İş Zinciri v1 — merged / manual test deferred
→ Issue #485 İstenecek Malzemeler v1 — current
```

Issue #466 / PR #467 nullable actual-progress source-of-truth foundation'ını
schema `16` merged temeline ekler: `NULL` bilinmeyen/raporlanmamış, açık item
explicit progress `0..99`, `COMPLETED` exact `100`dür. Optimistic revision,
durable idempotency/no-op receipt ve append-only event sözleşmesi korunur.
Issue #468 / PR #469 bu progress gerçeğinin dar UI/edit ve isolated device
acceptance, Issue #470 / PR #471 exact origin snapshot duration'ını progress ile
read-only yorumlayan forecast core ve Issue #472 / PR #473 yalnız yeni schedule
snapshot'ın exact resolved dependency graph'ını immutable saklayan merged
predecessor'lardır; legacy graph backfill yapılmaz. Issue #474 / PR #475 bu exact
forecast/snapshot/graph binding'inden salt-okunur downstream projected impact
hesaplayan merged predecessor'dır. Issue #476 / PR #480 exact bound forecast/
impact'i Living Plan kart/detail UI'da gösteren merged implementation'dır;
manual testleri #479'da pending kalır. Issue #481 / PR #482 exact project ve
İstanbul günü için salt-okunur deterministic Günlük Log v1 projection'ını
`IMPLEMENTED — MANUAL TEST DEFERRED` olarak merge etmiştir. Issue #483 yalnız
explicit stable Ajanda–takip bağını lifecycle ve sonuçla read-only görünür kılan
current V2.7 Slice'ıdır. Schedule mutation/reforecast, actual quantity,
productivity learning, daily-log/work-chain persistence ve public/store release
başlamaz. V2.5, V2.6 ve V2.7 final completion ilanları ayrı owner kararına bağlıdır.
