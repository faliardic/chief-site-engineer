# CSE V2 — Kanonik Ürün Yol Haritası

**Durum:** Güncel yürütme sırası
**Tarih:** 27 Ağustos 2026
**V2 kapsam kaynağı:** `docs/v2/CSE_V2_SCOPE.md`
**Güncel yön truth-sync:** Epic #506 / Issue #507 — Inventory Map v1
**Değişken repository gerçeği:** Güncel SHA/PR durumu GitHub `master` ve current Issue üzerinden doğrulanır.

## 1. Güncel ürün durumu

CSE V1 tamamlanmış ve proje sahibi tarafından yaklaşık bir ay gerçek sahada
kullanılmıştır. V2 Items 1–4 tamamlanmış; schedule runtime, immutable
reference-schedule snapshots, Living Plan MVP/ilk cihaz kabulü, actual-progress
core, progress UI/isolated cihaz kabulü, deterministic forecast core, immutable
snapshot dependency graph persistence ve read-only downstream impact PR #475'e
kadar, Living Plan intelligence UI PR #480'e, Deterministic Günlük Log v1 ise
PR #482'ye, İş Zinciri v1 PR #484'e, İstenecek Malzemeler v1 PR #486'ya
bounded-memory backup package correction PR #489'a, deterministic kişi/firma
önerileri Slice 1 PR #491'e, manuel telefon görüşmesi sonucu Slice 1 PR #493'e,
proje fotoğraf/video albümü Slice 1 PR #498'e ve P0 recovery surface PR #505'e
kadar merge edilmiştir. PR #505 owner recovery verification'ı değildir.
Güncel teknik ve ürün durumu:

| Alan | Değer |
| --- | --- |
| V1 baseline commit | `7c9f65a811c9f4bca561adab6bd1f8e64e6908cc` |
| Current repository truth | GitHub `master` ve current Issue; exact task snapshot'ı task/result evidence'ındadır |
| Mobil sürüm | `0.1.0+1` |
| SQLite schema | `19` |
| `.csebackup` formatı | `1` |
| Canonical timezone | `Europe/Istanbul` |
| Android compile/target SDK | `36 / 36` |
| Saha durumu | Owner tarafından yaklaşık bir ay kullanıldı |
| Store/public release | İlan edilmedi |

V1'in tamamlanması, modüllerin dondurulduğu anlamına gelmez. V2 aynı
offline-first mobil ürün üzerinde ilerler. Issue #472 / PR #473 yalnız bundan
sonra oluşturulan immutable schedule snapshot'ların resolved dependency edge
setini manifest/count/hash ile saklayan merged schema 17 temelidir. Issue #474 /
PR #475 exact forecast/snapshot/dependency-graph binding'inden salt-okunur
downstream impact üreten merged predecessor'dır. Issue #476 / PR #480 bu exact
read-only intelligence katmanlarını Living Plan UI'da görünür kılan merged
`IMPLEMENTED — MANUAL TEST PENDING` predecessor'dır; Item 5 final completion
ilanı değildir. Issue #481 / PR #482 mevcut source kayıtlarından salt-okunur
Deterministic Günlük Log v1'i `IMPLEMENTED — MANUAL TEST DEFERRED` olarak
merge etmiştir. Issue #483 / PR #484 exact Ajanda–takip bağından read-only İş
Zinciri projection'ını, Issue #485 / PR #486 additive schema `18` material
request source-of-truth ve lifecycle UI'yı merged temele eklemiştir. Issue #488 /
PR #489 backup formatını değiştirmeyen bounded-memory package correction'ıdır.
Issue #490 / PR #491 deterministic kişi/firma önerileri Slice 1'i merged temele
eklemiştir; V2.9 complete değildir. Issue #492 / PR #493 Telefon görüşmesi
sonucu → Ajanda Slice 1'i schema `19` temeline merge etmiştir; manual testleri
deferred kalır ve V2.10 complete değildir. Issue #497 / PR #498 Proje
fotoğraf/video albümü Slice 1'i merge etmiştir; manual testleri pending ve
V2.11 complete değildir. Epic #506 / Issue #507 Inventory Map v1 Slice 0
current docs-only product-development işidir; Inventory production behavior'ı
henüz uygulanmamıştır. V2.12 ve sonraki planlı ürün işleri paused'dır.
Public/store production release ilan edilmemiştir.

## 2. Kaynak otoritesi

- Kalıcı ürün amacı ve veri ilkeleri:
  `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
- Güncel V2 kapsamı:
  `docs/v2/CSE_V2_SCOPE.md`
- Güncel yürütme sırası:
  bu `ROADMAP.md`
- Operasyon ve güvenlik:
  `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
- Aktif teknik kapsam:
  güncel GitHub Issue

Eski roadmap fazları, Epic #97/#105/#127–#140, Orchestrator O0–O10 programı,
Bridge, Work Mode ve PR #259 tarihsel kayıttır. Bunlar güncel V2 sırasını
override etmez ve aktif ürün blocker'ı sayılmaz.

## 3. V2 ana bağımlılık zinciri

```text
Proje/Mahal — complete
→ Saha Rehberi — complete
→ Attachment v2 — complete
→ Ajanda v2 — complete
→ schedule runtime + persistent reference snapshots — merged foundation
→ 7 Günlük Yaşayan İş Programı — implemented / manual test pending
→ Günlük Log v1 — implemented / manual test deferred
→ İş Zinciri — implemented / manual test deferred
→ Proje albümü Slice 1 — implemented / manual test pending
→ Inventory Map v1 — current / Slice 0 docs only
→ V2.12 and later planned work — paused
```

Temel kural:

> Teknik sistem binlerce aktivite ve deterministik bağımlılık taşıyabilir;
> şantiye şefinin ana akışı ise aktiviteyi bulup yakın plana birkaç işlemle
> eklemek ve yalnız önündeki yedi günü güncel tutmak kadar sade kalır.

## 4. Dalga 1 — Kimlik ve bağlam omurgası

### V2.1 — Proje ve Mahal omurgası

Öncelik: `P0 foundation`

Durum: `complete`

Teslimatlar:

- Proje düzenleme ve recoverable archive/restore
- Stable mahal/konum kimliği
- Duplicate/normalization kuralları
- Eski kayıtların kontrollü migration'ı
- Ajanda, Hatırlatıcı, Puantaj ve Beton bağlarının korunması
- Backup/restore compatibility

Geçiş kapısı:

- Proje veya mahal adı değişse dahi source bağlantısı bozulmaz.
- Eski schema'dan yükseltme atomik ve testlidir.
- Saha kullanıcısı aktif/arşivli bağlamı güvenle yönetebilir.

Önerilen child Issue sırası:

1. Domain ve migration preflight
2. Schema/repository/application
3. Yönetim UI'sı
4. Mevcut modül adoption'ı
5. Backup/restore ve saha kabulü

### V2.2 — Sicil / Puantaj V2 / Saha Rehberi

Öncelik: `P0 data identity`

Durum: `complete`

Teslimatlar:

- Ortak kişi ve firma kimliği
- Taşeron → ekip → personel hiyerarşisi
- Puantajın canonical personel ID kullanması
- Aktif/arşiv yaşam döngüsü
- İletişim ve saha rehberi görünümü
- Mevcut belge/KKD/İSG/SGK bağlarının korunması

Geçiş kapısı:

- Aynı kişi farklı modüllerde duplicate kimlik oluşturmaz.
- Arşivlenen kişi geçmiş Puantajda kalır, yeni güne varsayılan eklenmez.
- Saha rehberi gerçek kullanımda hızlı ve filtrelenebilir durumdadır.

## 5. Dalga 2 — Ortak dosya ve günlük kayıt omurgası

### V2.3 — Attachment / Fotoğraf / Medya V2

Öncelik: `P0 integrity`

Durum: `complete`

Teslimatlar:

- Ortak attachment ve entity-link sözleşmesi
- Fotoğraf, video, ses ve belge desteği
- Çoklu seçim
- MIME/hash/size/path doğrulaması
- Atomik staging ve orphan diagnostic
- Tek dosya, çoklu kayıt bağlantısı
- Backup/restore bütünlüğü

Geçiş kapısı:

- Aynı binary farklı modüller için yeniden kopyalanmaz.
- Kırık bağlantı ve bozuk dosya görünürdür.
- Source kayıt ve exact attachment bağı korunur.

### V2.4 — Ajanda V2 ve kontrollü Ajanda–Hatırlatıcı senkronu

Öncelik: `P0 daily flow`

Durum: `complete`

Teslimatlar:

- Saha olay zaman çizgisi
- Kaynaklı Hatırlatıcı oluşturma
- Çift yönlü navigasyon ve durum görünürlüğü
- Kullanıcı kontrollü metin/durum senkronu
- Attachment görünürlüğü
- Revision/event geçmişi
- Duplicate/stale/rollback güvenliği

Geçiş kapısı:

- Ajanda ve Hatırlatıcı ayrı source-of-truth olarak kalır.
- Kullanıcı onayı olmadan sessiz yeniden yazma yoktur.
- Archive/trash sonrasında kaynak bağı kaybolmaz.

Kapanış durumu:

- Issue #432 / #434 / #437 dilimleri ve Issue #439 final closure merged
  `master` üzerindedir.
- Items 1–4 complete'tir; revised Item 5 current direction'dır.

## 6. Dalga 3 — Günlük iş yönetimi

### V2.5 — 7 Günlük Yaşayan İş Programı / İş ve Gün Planı

Öncelik: `P0 current site-management loop`

Durum: `implemented — manual test pending; final completion ilan edilmedi`

- Projeye özgü güncel yedi günlük pencere
- İnşaat aktivite kataloğunda arama ve birkaç işlemle plana ekleme
- Aktivite adı ile blok/kat/mahal bağlamı
- Onaylı baseline gibi sunulmayan öneri tarih ve süre
- Minimum durumlar: `Planlandı`, `Başladı`, `Tamamlandı`, `Ertelendi`
- Kısa saha notu, offline persistence ve normal backup/restore
- Immutable reference schedule'dan ayrı mutable/evented kullanıcı karar katmanı
- Stable project/activity-instance/snapshot kimliklerine referans
- Kullanıcı işlemiyle reference schedule'ı sessizce yeniden yazmama

Issue #466 / PR #467 ile merged schema 16 actual-progress source-of-truth
temelinde `NULL` raporlanmamış/bilinmeyen ilerleme, açık item için explicit
`0..99`, tamamlanan item için exact `100` anlamındadır. Optimistic revision,
durable idempotency/no-op receipt ve append-only event sözleşmesi korunur.

Issue #468 / PR #469 bu progress gerçeğini kartlarda görünür kılan, yalnız
`STARTED`/`DEFERRED` item için `0..99` editini açan ve isolated acceptance
paketinde lifecycle/relaunch persistence'ı kanıtlayan merged predecessor'dır.
Issue #470 / PR #471 item'ın exact bound reference snapshot süresinden read-only
deterministic kalan süre/finish tahmini üreten, Issue #472 / PR #473 ise yalnız
yeni schedule snapshot'ların exact resolved dependency graph'ını immutable ve
fingerprint'li saklayan merged predecessor'lardır. Historical snapshot'lara
graph backfill yapılmaz; manifest yokluğu zero-edge değil typed unavailable'dır.
Issue #474 / PR #475 exact origin forecast/snapshot/graph binding'iyle deterministic
topological sırada bütün incoming constraint'lerin maksimumunu uygulayan
salt-okunur downstream impact merged predecessor'dır. Aktiviteyi reference
tarihinden erkene çekmez; source finish-only gecikmesi outgoing SS constraint'ini
yanlış kaydırmaz. Issue #476 / PR #480 exact historical binding'i koruyarak
forecast ve positive downstream impact'i sade kart/detail UI olarak gösteren
merged implementation'dır. Manual Test Register #479 borcu görünür kalır;
V2.5 final completion ilan edilmez. Schedule/Living Plan/reference mutation ve
reforecast, actual quantity ile project-specific productivity learning başlamaz.

### V2.6 — Günlük Log Çıktısı v1

Öncelik: `P1 reporting after usable living plan`

Durum: `implemented — manual test deferred; completion not declared`

- Ajanda, Puantaj, Beton, açık takip ve living-plan/progress kaynaklı günlük
  taslak
- Proje/gün filtresi
- Deterministik sıra
- Private/project kapsam kontrolü
- Kaynak kayda geri bağlantı
- İlk insan okunabilir çıktı
- Issue #481 yalnız read-only projection, typed section-unavailable davranışı,
  deterministic plain-text preview ve `Metni kopyala` yüzeyini kapsar
- Yeni persistence table, migration, event/receipt, PDF/file/share artifact,
  AI summary veya source mutation yoktur
- Issue #481 / PR #482 `IMPLEMENTED — MANUAL TEST DEFERRED` olarak merge
  edilmiştir; MT-481-001..012 borcu #479'da korunur
- V2.6 completion ayrı owner kararı gerektirir

### V2.7 — İş Zinciri / Bağlı Log v1

Öncelik: `P1 traceability`

Durum: `implemented — manual test deferred; completion not declared`

- Başlangıç, takip, bekleme, kontrol ve sonuç bağlantıları
- Source-of-truth kayıtları değiştirmeyen read-model
- Kırık bağlantı diagnostic'i
- İşin neden açık/kapalı olduğunun görünürlüğü
- Issue #483 yalnız exact `field_observations.id` → `follow_up_items.observation_id`
  bağını, append-only follow-up lifecycle'ını ve current sonucu read-only
  projekte eder; iki exact entry point aynı canonical zincire gider
- Kırık/mismatched ilişki typed diagnostic üretir; repair, inference, schema,
  notification/sync mutation veya generic workflow graph eklenmez

Dalga 3 kapanış kapısı:

- Kullanıcı gün içindeki işi, kanıtı ve sonucu tekrar yazmadan izleyebilir.
- Günlük taslak kaynak kayıtlarla açıklanabilir.
- Ağır workflow motoru veya otomatik saha kararı eklenmemiştir.

## 7. Dalga 4 — Yardımcı saha akışları

### V2.8 — İstenecek Malzemeler

- Malzeme, miktar/birim, ihtiyaç tarihi, öncelik ve açıklama
- `İhtiyaç var → İstendi → Geldi / İptal`
- Proje/mahal/iş bağlantısı
- Tam satın alma, teklif, sipariş ve ERP kapsam dışı
- Issue #485 / PR #486 schema `17 → 18` additive migration ile material request
  source-of-truth, optimistic revision, atomic append-only lifecycle
  eventleri ve Home'dan sade açık/geçmiş UI kuran merged Slice'tır
- Backup format `1` ve version `0.1.0+1` değişmez; manual testler #479'da PENDING izlenir

### V2.9 — Deterministik kişi/firma/etiket önerileri

- Mevcut kayıtlardan açıklanabilir öneri
- Offline, deterministik ve kullanıcı onaylı
- Yeni kişi/firma uydurmama
- Kalıcı mutation öncesi açık seçim
- Issue #490 / PR #491 merged Slice 1 exact seçili projedeki aktif Saha Rehberi kişileri
  ve aktif firma/işveren kayıtlarını canonical source olarak kullanır
- Aynı projedeki exact-string Reminder geçmişi yalnız provenance'ı görünür
  secondary source'tur; cross-project/private leakage yoktur
- Bounded sıra match kalitesi, canonical öncelik, güvenli usage/recency ve stable
  tie-breaker ile deterministiktir
- Öneri seçimi yalnız mevcut form alanını doldurur; Save ayrı mutation
  sınırıdır ve query/read failure capture'ı bloke etmez
- Reusable canonical tag kaynağı henüz yoktur; Slice 1 tag üretmez ve V2.9'u
  complete ilan etmez

### V2.10 — Telefon görüşmesi sonucu → Ajanda

- Kullanıcı tarafından başlatılan hızlı görüşme sonucu kaydı
- Kişi/firma/proje/mahal bağlamı
- Hatırlatıcı yalnız kayıt detayındaki ayrı mevcut kullanıcı işlemi
- Çağrı geçmişi ve rehber için gereksiz izin yok
- Gönderildi/okundu iddiası yok
- Issue #492 / PR #493 merged Slice 1 Agenda row, create event ve opsiyonel immutable
  phone-call taraf context'ini exact bir SQLite transaction içinde yazar
- Schema `19` yalnız additive `agenda_phone_call_contexts` tablosunu ekler;
  backup format `1` ve version `0.1.0+1` olarak kalır
- Canonical kişi/firma exact project ve active source ile fail-closed
  doğrulanır; manual edit veya historical değer serbest metindir
- Otomatik Reminder, notification veya çağrı entegrasyonu yoktur
- Manual testler #479'da deferred kalır; V2.10 completion ilanı değildir

## 8. Dalga 5 — Medya ve yayımlanmış günlük

### V2.11 — Proje fotoğraf/video albümü

- Ortak attachment read-modeli
- Proje, mahal, tarih, kategori ve kaynak filtreleri
- Thumbnail/player sınırı
- Depolama ve backup boyutu görünürlüğü
- Kaynak kayda hızlı geçiş
- Issue #497 / PR #498 merged Slice 1 mevcut `managed_attachments + attachment_links`
  gerçeğini exact project-scoped ve physical-deduplicated read-model olarak
  projekte eder; yalnız JPEG/PNG/HEIC/MP4 albüme girer
- CSE'ye eklenme tarihi, stable mahal/context ve Ajanda/Beton source filtreleri
  kombinlenebilir; JPEG/PNG preview ve MP4/HEIC open seçilen item için lazy ve
  integrity-gated'dir
- Kırık medya ve okunamayan/arşivli source/link görünür kalır; preview/open veya
  sahte source navigation yapılmaz
- Schema `19`, backup format `1`, version `0.1.0+1` değişmez; yeni binary,
  persistence, cache, capture/import veya source/link mutation yoktur

Durum: `implemented — manual test pending; completion not declared`

### Current priority — Inventory Map v1 (Epic #506)

- V2.12 ve sonraki planlı ürün işi owner kararıyla paused'dır.
- Epic #506 kroki tabanlı dayanıklı saha envanteri current product-development
  priority'sidir.
- Issue #507 yalnız normative contract/truth-sync Slice 0'dır; Inventory source,
  schema, navigation, editor, test, build veya device davranışı uygulanmış
  değildir.
- Slices 1–6'nın exact sınırı
  `docs/v2/CSE_INVENTORY_MAP_V1_CONTRACT.md` içindedir.
- P0 Issues #501, #502, #503 ve #499 bütün owner-phone operasyonlarından önce
  gelir; source development ve Draft PR install authority üretmez.

### V2.12 — Günlük Log Çıktısı v2

Durum: `paused by owner decision`

- v1 saha bulgularına dayalı geliştirme
- Seçilebilir bölümler
- İş zinciri, malzeme ve medya ilişkileri
- Canlı taslak ile yayımlanmış immutable snapshot ayrımı
- Revision/ek modeli
- Private veri sızıntısı regresyonu

## 9. Dalga 6 — Dar saha aracı

### V2.13 — Mini hesap makinesi

Durum: `paused by owner decision`

- Temel dört işlem
- Oran ve yüzde
- Decimal separator ve hata durumları
- Sonucun ilgili alana kullanıcı onayıyla aktarılması
- `eval`, arbitrary code ve ileri mühendislik hesapları yok

## 10. V2 dışında kalanlar

Aşağıdaki başlıklar V2 milestone'una alınmaz:

- Universal Capture
- Voice Capture / Asistan Gelen Kutusu
- Open Loop
- Sabah Brifingi / Akşam Kapanışı
- Büyük Resim / Saha Nabzı
- Beton Paketi V2
- Kalite / İSG özel dikeyleri
- Doküman Hafızası
- Inventory Map v1 dışındaki ölçülü CAD/GIS/full saha haritası
- Gömülü AI ve semantik arama
- Full-project Gantt editing ve Primavera replacement
- Approved/contractual baseline, critical path ve float hesapları
- Resource/material/machine optimization
- PC senkronizasyonu
- Multi-user, tenant, firma portalı ve SaaS
- Orchestrator, Bridge ve Work Mode geliştirmeleri

Bu başlıklar ayrı post-V2 backlog'da tarihsel olarak korunur.

## 11. Yürütme disiplini

1. Aynı anda yalnız bir production implementation Issue'su aktiftir.
2. Her Issue tek V2 maddesine ve dar değişen sözleşmeye bağlıdır.
3. `P0` veri kaybı, yanlış bağlama ve backup bozulması yeni özellikten önce
   çözülür.
4. Migration varsa eski schema ve backup compatibility test edilir.
5. Gerçek kullanıcı data root'u otomasyona açılmaz.
6. Değişmeyen release/device kapıları gereksiz tekrar edilmez.
7. Merge, release ve store yayını ayrı kullanıcı kararı gerektirir.
8. Geçmiş Issue/PR/test/podcast kayıtları geriye dönük yeniden yazılmaz.
9. Living Plan için yalnız tek dar MVP Core dilimi UI'dan önce gelebilir;
   immediate successor 7-day UI + APK/device kabulüdür.

## 12. Güncel işlem

Güncel canonical faz:

```text
Living 7-Day Plan — implemented / manual test pending; final completion yok
→ Issue #466 / PR #467 actual-progress source-of-truth core — merged
→ Issue #468 / PR #469 progress UI + isolated device acceptance — merged
→ Issue #470 / PR #471 deterministic read-only forecast core — merged
→ Issue #472 / PR #473 immutable snapshot dependency graph persistence — merged
→ Issue #474 / PR #475 read-only downstream dependency impact core — merged
→ Issue #476 / PR #480 Living Plan intelligence UI — merged / manual test pending
→ Issue #481 / PR #482 Deterministic Günlük Log v1 — merged / manual test deferred
→ Issue #483 / PR #484 Agenda–Takip İş Zinciri v1 — merged / manual test deferred
→ Issue #485 / PR #486 İstenecek Malzemeler v1 — merged / manual test pending
→ Issue #488 / PR #489 bounded-memory backup package correction — merged
→ Issue #490 / PR #491 deterministic kişi/firma önerileri Slice 1 — merged / manual test pending
→ Issue #492 / PR #493 Telefon görüşmesi sonucu → Ajanda Slice 1 — merged / manual test deferred
→ Issue #497 / PR #498 Proje fotoğraf/video albümü Slice 1 — merged / manual test pending
→ Issue #504 / PR #505 recovery surface — merged / owner recovery verification pending
→ Epic #506 / Issue #507 Inventory Map v1 Slice 0 contract — current / docs only
→ Inventory Map v1 Slices 1–6 — not started
→ V2.12 and later planned product work — paused by owner decision
```

Items 1–4 complete'tir. Activity Catalog Runtime, typed Project Profile ve
Dependency Catalog, Project Activity Instance Graph, deterministic Schedule
Date Engine ve immutable persistent reference-schedule snapshots PR #444, #446,
#448, #456 ve #459 zinciriyle merged temeldir.

Issue #466 / PR #467 nullable actual-progress source-of-truth foundation'ını,
optimistic revision ve durable idempotency/no-op receipt sözleşmesini merged
temele ekler. Issue #468 / PR #469 progress UI ve isolated device acceptance,
Issue #470 / PR #471 exact origin snapshot duration'ını progress ile read-only
yorumlayan deterministic forecast core, Issue #472 / PR #473 ise yalnız yeni
snapshot'ların exact dependency graph'ını immutable saklayan merged
predecessor'lardır; legacy graph backfill yapılmaz. Issue #474 / PR #475 bu exact
immutable girdilerden schedule mutation üretmeden downstream projected impact
hesaplayan merged predecessor'dır. Issue #476 / PR #480 exact item snapshot'ından
forecast/impact'i read-only gösteren merged implementation'dır; manual testleri
#479'da pending kalır. Issue #481 / PR #482 exact project ve İstanbul günü için
read-only, deterministic Günlük Log v1 projection'ını `IMPLEMENTED — MANUAL
TEST DEFERRED` olarak merge etmiştir. Issue #483 / PR #484 explicit stable
Ajanda–takip bağını lifecycle ve sonuçla read-only görünür kılan merged V2.7
Slice'ıdır. Issue #485 / PR #486 material request source-of-truth ve lifecycle
UI'yı schema `18` additive temeline eklemiştir; manual testleri pending kalır.
Issue #490 / PR #491 V2.9 Slice 1 yalnız read-only deterministic kişi/firma öneri
sınırını ve Reminder first-consumer wiring'ini merged temele ekler. Issue #492 /
PR #493 V2.10 Slice 1 manual phone-call result capture ve immutable taraf
provenance'ını schema `19` ile merged temele eklemiştir; manual testleri deferred
ve V2.10 completion kararı ayrıdır. Issue #497 / PR #498 V2.11 Slice 1 existing
attachment truth'tan salt-okunur project media album ve source navigation kurar;
manual testleri pending ve V2.11 completion ilanı değildir.

Current product-development priority Epic #506 Inventory Map v1'dir. Issue #507
yalnız Slice 0 contract/truth-sync üretir. Production code, proposed schema 20,
Envanter navigation, landscape editor, test, build ve owner-phone behavior'ı
henüz yoktur. Slices 1–6 ayrı Issue ve authorization gerektirir.

Issue #501 recovery incident owner tarafından verified değildir. Issue #502
verified external backup/update gate'i, Issue #503 newer-live-data-safe restore
gereksinimi ve Issue #499 MAIN-only owner-phone identity kuralı cumulatively
önceliklidir. V2.12 ve sonraki planlı ürün işleri ayrı owner resume kararına
kadar paused; V2.5–V2.11 completion ilanları ayrı owner kararına bağlıdır.

## 13. Tarihsel roadmap sınırı

31 Temmuz 2026 ve öncesindeki geniş Asistan-Öncelikli roadmap, Orchestrator
O0–O10 programı ve eski Faz 1–12 Epic'leri Git geçmişinde ve ilgili
Issue'larda korunur. Tamamlanmamış maddeler tamamlanmış sayılmaz. Güncel
production sırası yalnız bu roadmap ve `docs/v2/CSE_V2_SCOPE.md` üzerinden
belirlenir.
