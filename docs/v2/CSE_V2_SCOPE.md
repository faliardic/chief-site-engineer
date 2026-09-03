# CSE V2 Kanonik Kapsamı

**Belge türü:** Güncel ürün yürütme kapsamı
**Durum:** Kanonik V2 kapsam ve sıra kaynağı
**Tarih:** 3 Eylül 2026
**Güncel yön kaynağı:** Inventory v1 closure complete → DWG Viewer #523 next → release-readiness closure
**Değişken repository gerçeği:** Güncel SHA/PR durumu GitHub `master` ve current Issue üzerinden doğrulanır.

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

Güncel V2 teknik durum V1 metadata'sından ayrıdır: Issue #527 revised Slice 6.1,
Issue #529 correction'ı, Issue #531 Slice 6.2 ve Issue #533 / PR #534 Slice 6.3
merged Inventory predecessor'larıdır. Issue #535 / Draft PR #536 superseded
tarihsel girişimdir ve current execution base değildir. Inventory Spatial v1
Slice 7 / Issue #604 repository, backup/restore, attachment ve owner field
acceptance kapılarıyla completed/closed'dur. Güncel V2 baseline schema `22`,
mobile version `0.1.0+1` ve backup format `1`dir.
Exact güncel merge SHA kalıcı bu kapsam belgesine sabitlenmez; GitHub `master`
üzerinden doğrulanır. Bu baseline,
schedule runtime ve persistent immutable reference-schedule snapshot temeliyle
Living Plan MVP Core, 7-day UI/APK/device acceptance, Actual Progress Core ve
progress UI/isolated device acceptance, deterministic forecast core ve immutable
snapshot dependency graph persistence ve read-only downstream dependency impact
core'u, Issue #476 / PR #480 Living Plan intelligence UI implementation'ını ve
Issue #481 / PR #482 Deterministic Günlük Log v1 read modelini, Issue #483 /
PR #484 read-only İş Zinciri v1'i, Issue #485 / PR #486 İstenecek Malzemeler
v1'i, Issue #488 / PR #489 bounded-memory backup package correction'ını ve
Issue #490 / PR #491 deterministic kişi/firma önerileri Slice 1'i, Issue #492 /
PR #493 manuel telefon görüşmesi sonucu Slice 1'i ve Issue #497 / PR #498 proje
fotoğraf/video albümü Slice 1'i içerir. Issue #504 / PR #505 recovery surface'i
merge edilmiştir; bu, Issue #501 owner recovery verification'ı anlamına gelmez.
Living Plan, Material Request, kişi/firma önerileri ve Proje Albümü manual
testleri pending; Günlük Log, İş Zinciri ve Telefon görüşmesi sonucu manual
testleri deferred kalır. Bunlar mutation/reforecast, public/store release veya
genel production readiness ilanı değildir.

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
→ Issue #485 / PR #486 İstenecek Malzemeler v1 — merged / manual test pending
→ Issue #488 / PR #489 bounded-memory backup package correction — merged
→ Issue #490 / PR #491 Deterministic kişi/firma önerileri Slice 1 — merged / manual test pending
→ Issue #492 / PR #493 Telefon görüşmesi sonucu → Ajanda Slice 1 — merged / manual test deferred
→ Issue #497 / PR #498 Proje fotoğraf/video albümü Slice 1 — merged / manual test pending
→ Issue #504 / PR #505 pre-restore safety-backup recovery surface — merged / owner recovery verification pending
→ Epic #506 / Issue #507 Inventory Map v1 Slice 0 contract — historical normative foundation
→ Inventory Map v1 Slices 1–5 and Issue #527 / PR #528 revised Slice 6.1 — merged predecessors
→ Issue #529 / PR #530 correction and Issue #531 / PR #532 Slice 6.2 — merged
→ Issue #533 / PR #534 Slice 6.3 block reshape/reconciliation/lifecycle — merged
→ Inventory v1 closure — complete / Slice 7 #604 closed / #586 via PR #589 merged
→ DWG Viewer v1 / Issue #523 — next product phase; implementation not authorized
→ release-readiness closure
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
| 8 | İstenecek Malzemeler | Implemented — manual test pending |
| 9 | Deterministik kişi/firma/etiket önerileri | Implemented — Slice 1 merged; manual test pending; not complete |
| 10 | Telefon görüşmesi sonucu → Ajanda | Implemented — Slice 1 merged; manual test deferred; not complete |
| 11 | Proje fotoğraf/video albümü | Implemented — Slice 1 merged; manual test pending; not complete |
| 12 | Günlük Log Çıktısı v2 | Paused by owner decision |
| 13 | Mini hesap makinesi | Paused by owner decision |

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
- Issue #485 / PR #486 yalnız additive schema 18 material request source-of-truth,
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
- Issue #490 / PR #491 merged Slice 1, exact seçili projedeki aktif Saha Rehberi
  kişilerini ve aktif firma/işveren kayıtlarını canonical kaynak olarak okur.
- Aynı projedeki Reminder `related_person` geçmişi yalnız exact-string,
  provenance'ı görünür secondary source olabilir; başka projeden veya private
  kayıttan öneri üretilmez.
- Sıralama match kalitesi, canonical-source önceliği, güvenli kullanım/recency
  sinyali ve stable tie-breaker ile bounded ve deterministiktir.
- Slice 1'de canonical reusable tag kaynağı yoktur; `tag_source_unavailable`
  normal sonuçtur. Tag üretimi veya etiket icadı yapılmaz.
- Öneri seçimi yalnız form alanını doldurur; Save ayrı mutation sınırıdır.
  Query/read hatası capture akışını engellemez.

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
- Issue #492 / PR #493 merged Slice 1 Home'dan açıkça başlatılan `Görüşme sonucu`
  formunu, exact proje/mahal seçimini ve #490'ın read-only kişi/firma
  önerilerini kullanır.
- Schema `19`, Agenda row + create event + opsiyonel immutable görüşme tarafı
  bağlamını tek SQLite transaction içinde yazar.
- Taraf seçilmezse görüşme sonucu yine canonical Agenda kaydıdır. Canonical
  kişi/firma seçimi same-project stable identity ve exact display snapshot
  taşır; historical veya düzenlenmiş değer açık serbest metindir.

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
- Issue #497 / PR #498 merged Slice 1 yalnız `managed_attachments + attachment_links`
  truth'undan exact project-scoped ve physical-deduplicated album üretir.
- Albüm MIME sınırı `image/jpeg`, `image/png`, `image/heic`, `video/mp4`dür;
  PDF/audio mevcut Dosya Kataloğu'nda kalır.
- Fiziksel `created_at` İstanbul günü, gerçek stable mahal/context ve herhangi
  active/historical Ajanda/Beton linki üzerinden kombinlenebilir filtreler sunar.
- JPEG/PNG preview ve MP4/HEIC external-open yalnız seçilen item için lazy,
  bounded ve action-time integrity-gated'dir. Kırık medya görünür fakat açılmaz.
- Source/link availability ile archive durumu görünür; source kaydı yoksa ID
  korunur ve sahte detail navigation yapılmaz.

Kapanış kapısı:

- Albüm source attachment'tan türetilen read-modeldir.
- Kaynak kayda tek dokunuşla gidilebilir.
- Arşiv ve broken-media davranışı açıktır.
- Backup boyutu ve medya sınırları kullanıcıdan gizlenmez.
- Schema `19`, backup format `1`, version `0.1.0+1` değişmez; duplicate binary,
  album persistence/cache, capture/import veya source/link mutation yoktur.

Durum:

- Slice 1 merged ve manual testleri Issue #479'da pending'dir.
- V2.11 complete, verified veya release-ready ilan edilmemiştir.

### Inventory Map v1 — closure complete

Epic #506 altındaki kroki tabanlı dayanıklı saha envanteri tamamlanmış ürün
hattıdır. Merged contract ve production Slice çalışmaları ürün gerçeği olarak
korunur. Issue #535 / Draft PR #536 superseded tarihsel girişimdir; current
ancestry değildir ve sonraki tamamlanan Inventory çalışmalarını sınırlamaz.
Inventory Spatial v1 Slice 7 / Issue #604 repository, backup/restore, attachment,
isolated device ve owner field acceptance kapılarıyla completed/closed'dur.

Kanonik Slice 0 sözleşmesi:

`docs/v2/CSE_INVENTORY_MAP_V1_CONTRACT.md`

Inventory Map v1:

- direct top-level `Envanter` yüzeyi;
- sabit integer virtual canvas üzerinde şematik kroki;
- autosaved draft ve immutable finalized revision;
- exact project-isolated asset, placement, event ve receipt gerçeği;
- Kroki/Liste ortak source projection'ı;
- additive persistence ve normal backup/restore adoption'ı

hedefler. Issue #507 tarihsel docs/source-authority Slice'ıdır. Slices 1–5
production predecessors olarak tamamlanmıştır. Issue #527 revised Slice 6.1;
schema22 final stable block/floor source'unu, deterministic
`20 -> revised 21 -> 22` backfill'ini, superseded PR #526 schema21 compatibility
yolunu ve closed-area editor foundation'ını kuran merged predecessor'dır. Issue
#529 Agenda transient-project diagnostic correction'ı da merged predecessor'dır.
Issue #531 Slice 6.2 Kat Görünümü, block/floor navigation, Map/List spatial
context ve exact-floor quick-create davranışını schema/storage değiştirmeden
merged temele eklemiştir. Issue #533 / PR #534 Slice 6.3 mapped-block reshape,
placement reconciliation ve explicit detach/archive/reattach lifecycle
davranışını schema/storage değiştirmeden merged temele eklemiştir. Issue #535 /
Draft PR #536 current ancestry/source truth'u değildir. Sonraki Inventory UI
implementation'ı Issue #586 / PR #589 ile merge edilmiş; Slice 7 / Issue #604
kalıcı veri ve field acceptance kapanışını tamamlamıştır.

Issue #527 owner-acceptance correction'ı normal yeni çizimi yatay/düşey
segmentlerle sınırlar: ilk kenar dominant pointer axis'ini, sonraki kenarlar 90°
alternation'ı kullanır; default smart alignment önceki vertex koordinatına
visible guide ile hizalar. `Serbest uzunluk` yalnız sonraki segmentin length
alignment'ını kapatır ve orthogonal kuralı korur. Legacy diagonal persisted
geometry okunmaya devam eder. Merged Slice 6.3 `Krokiyi güncelle` içinde yalnız
mapped active block için bounded whole-nudge ve orthogonal edge reshape açar;
unmapped legacy base kilitli kalır. Yeni orthogonal block append akışı korunur.

Issue #527 owner-acceptance correction'ı editorün güvenli full-screen canvas ve
compact icon-only, tooltip/Semantics etiketli toolbar temelini kurar. Issue #586 /
PR #589 current portrait sketch editor, çift edge control rail ve gesture-driven
auto-hide davranışını merge etmiştir. Global check/save action pending
debounce'u force-save/drain eder,
finalize sonucunu doğrular ve Inventory'nin canonical map projection'ını aynı
session'da yeniler. Block metadata action'ı lokal `Alanı ekle` olarak kalır;
bir draft global finalize öncesinde birden fazla block biriktirebilir.
Finalize hatasında dayanıklı draft korunur ve görünür retry sunulur. Issue #529
Agenda global safe-diagnostic correction'ı mergedir; Issue #531 bu davranışı
değiştirmez.

Issue #501, #502, #503 ve #499 P0 veri/owner-phone güvenlik kuralları korunur.
Inventory v1 closure bu bağımsız recovery, update ve MAIN-only güvenlik
kapılarını veya release kararını kendiliğinden kapatmaz.

### Current priority — DWG Viewer v1 (Issue #523)

Issue #540 UI/UX Wave 0 ve loading blocker #580 completed/closed'dur. Issue #586
Inventory final UI/UX implementation'ı PR #589 ile merge edilmiş ve Issue
completed/closed'dur. Inventory Spatial v1 Slice 7 / Issue #604 de
completed/closed olduğundan Inventory v1 closure tamamlanmıştır.

Current sıra:

```text
Inventory v1 closure — complete
→ DWG Viewer v1 / Issue #523 — next product phase; implementation not authorized
→ release-readiness closure
```

Issue #523'ün bu sırada yer alması implementation'ın başladığı, tamamlandığı veya
yetkilendirildiği anlamına gelmez. Yürütme ayrı owner authority gerektirir.

### 12. Günlük Log Çıktısı v2

Durum: `paused by owner decision`

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

Durum: `paused by owner decision`

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
| 5 | Proje albümü Slice 1 merged; Günlük Log v2 paused | V2.11 manual test/closure ve ayrı owner resume kararı |
| Completed product line | Inventory v1 through Slice 7 / Issue #604 | Repository, backup/restore, attachment, isolated device ve owner field acceptance closure complete |
| Current priority | DWG Viewer v1 / Issue #523 | Next product phase only; implementation is not started, complete or authorized |
| 6 | Mini hesap makinesi — paused | Ayrı owner resume kararı ve dar saha aracı kabulü |

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
- Inventory Map v1 dışındaki ölçülü CAD/GIS/full saha haritası
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
Issue #485 / PR #486 İstenecek Malzemeler v1'i schema `18` additive temeline
eklemiş, Issue #488 / PR #489 ise backup formatını değiştirmeden final package
buffer'ındaki kanıtlanmış ekstra büyük kopyayı kaldırmıştır. Issue #497 / PR
#498 Proje fotoğraf/video albümü Slice 1'i merge etmiştir; manual testleri
pending ve V2.11 complete değildir. Issue #504 / PR #505 recovery surface'i
mergedir; owner recovery doğrulaması ve P0 Issues #501–#503 açık kalır.

Current V2 facts schema `22`, backup format `1` ve version `0.1.0+1`dir; bu
truth-sync bunları değiştirmez. Exact current SHA ve son
PR kalıcı burada dondurulmaz; GitHub `master` current repository truth'udur.
Her Issue task başlangıç snapshot'ını kendi task/result kanıtında ayrıca bağlar.

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
→ Issue #485 / PR #486 İstenecek Malzemeler v1 — merged / manual test pending
→ Issue #488 / PR #489 bounded-memory backup package correction — merged
→ Issue #490 / PR #491 Deterministic kişi/firma önerileri Slice 1 — merged / manual test pending
→ Issue #492 / PR #493 Telefon görüşmesi sonucu → Ajanda Slice 1 — merged / manual test deferred
→ Issue #497 / PR #498 Proje fotoğraf/video albümü Slice 1 — merged / manual test pending
→ Issue #504 / PR #505 recovery surface — merged / owner recovery verification pending
→ Epic #506 / Issue #507 Inventory Map v1 Slice 0 canonical contract — historical normative foundation
→ Inventory Map v1 Slices 1–5 — production predecessors complete / manual status per Issue #479
→ Issue #527 / PR #528 revised Inventory Spatial v1 Slice 6.1 — merged predecessor
→ Issue #529 / PR #530 transient project diagnostic correction — merged predecessor
→ Issue #531 / PR #532 Inventory Spatial v1 Slice 6.2 — merged predecessor
→ Issue #533 / PR #534 Inventory Spatial v1 Slice 6.3 — merged predecessor
→ Inventory v1 closure — complete / Slice 7 #604 closed / #586 via PR #589 merged
→ DWG Viewer v1 / Issue #523 — next product phase; implementation not authorized
→ release-readiness closure
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
`IMPLEMENTED — MANUAL TEST DEFERRED` olarak merge etmiştir. Issue #483 / PR #484
explicit stable Ajanda–takip bağını lifecycle ve sonuçla read-only görünür kılan
merged V2.7 Slice'ıdır. Issue #485 / PR #486 material request source-of-truth ve
lifecycle UI'yı schema `18` additive temeline ekleyen merged V2.8 Slice'ıdır;
manual testleri pending kalır. Issue #490 / PR #491 V2.9 Slice 1'de seçili proje
için read-only deterministic kişi/firma öneri sınırını ve ilk Reminder
consumer'ını merged temele eklemiştir; V2.9 completion ilanı değildir.
Issue #492 / PR #493 V2.10 Slice 1 bu kaynağı manual phone-call result capture'da
yeniden kullanarak schema `19` temeline merge edilmiştir; manual testleri
deferred ve V2.10 completion kararı ayrıdır. Issue #497 / PR #498 V2.11 Slice 1
existing attachment/link truth'tan salt-okunur project media album ve exact
source navigation kurar; manual testleri pending'dir ve V2.11 completion ilanı
değildir.

Epic #506 altındaki Inventory Map v1 korunmuş tarihsel implementation hattıdır.
Issue #527, superseded PR #526 veya `d0267a7...` source'unu taşımadan revised
Slice 6.1'i exact master temelinden yeniden kuran merged predecessor'dır. Revised schema21 stable
project-owned block, block-owned ordered floor, immutable revision/polygon
mapping ve placement `floor_id` foundation'ını kurar; final schema22 hem normal
`20 -> 21 -> 22` zincirini hem de korunmuş superseded PR #526 schema21 verisinin
kayıpsız dönüşümünü destekler. Schema20 geometry, tüm placement history,
event/photo truth ve backup format `1` korunur. Issue #531 Slice 6.2 bu
foundation üzerinde aktif blockları stable ordinal sırasıyla Kat Görünümü'nde
sunar; route-local block/floor seçimi, exact floor Map/List focus, canonical
count/label ve strict-interior exact-floor quick create ekler. UI selection
persist edilmez; schema/storage/migration değişmez. Issue #533 / PR #534 Slice
6.3 mapped block whole-nudge/edge reshape, append-only placement reconciliation,
explicit detach/archive ve same-identity reattach lifecycle'ını merged temele
ekler; schema exact `22` kalır. Issue #535 / Draft PR #536 superseded tarihsel
girişimdir ve current ancestry değildir. Issue #586 / PR #589 current Inventory
UI implementation'ını, Slice 7 / Issue #604 ise persistence ve field acceptance
closure'ını tamamlamıştır.
`docs/v2/CSE_INVENTORY_MAP_V1_CONTRACT.md` güncel normative sınırdır.

Issue #501 recovery verification, Issue #502 external verified backup/update
gate'i, Issue #503 newer-live-data-safe restore yönü ve Issue #499 owner-phone
MAIN-only identity kuralı bütün owner-phone operasyonlarından önce gelir.
Inventory closure bunları kapatmaz. Güncel ürün sırası Inventory v1 closure
complete → DWG Viewer v1 / Issue #523 next → release-readiness closure'dır.
Issue #523 implementation complete, started veya authorized değildir. V2.12 ve
sonraki eski planlı ürün işleri owner resume kararına kadar paused kalır.
V2.5–V2.11 final completion ilanları ve public/store release ayrı owner
kararlarına bağlıdır.
