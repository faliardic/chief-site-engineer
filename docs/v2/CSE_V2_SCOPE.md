# CSE V2 Kanonik Kapsamı

**Belge türü:** Güncel ürün yürütme kapsamı
**Durum:** Kanonik V2 kapsam ve sıra kaynağı
**Tarih:** 21 Ağustos 2026
**Güncel yön kaynağı:** Issue #468 — Progress UI + Isolated Device Acceptance
**Güncel güvenli `master`:** `3eca007c34951095b24b1b0791146a533b3a8a6d` / PR #467

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
`0.1.0+1`, SQLite schema `16`, backup format `1` ve son güvenli merge
`3eca007c34951095b24b1b0791146a533b3a8a6d` / PR #467 değeridir. Bu baseline,
schedule runtime ve persistent immutable reference-schedule snapshot temeliyle
Living Plan MVP Core, 7-day UI/APK/device acceptance ve Actual Progress Core'u
içerir. Issue #468 Progress UI + Isolated Device Acceptance current evolution'dır;
public/store release veya genel production readiness ilanı değildir.

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
→ Issue #468 Progress UI + Isolated Device Acceptance — current
→ actual quantity, reforecast ve productivity learning — not started
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
| 5 | 7 Günlük Yaşayan İş Programı / İş ve Gün Planı | Current — not complete |
| 6 | Günlük Log Çıktısı v1 | Planned |
| 7 | İş Zinciri / Bağlı Log v1 | Planned |
| 8 | İstenecek Malzemeler | Planned |
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
- Issue #468 current evolution olarak bu gerçeği kartlarda görünür kılar, yalnız
  `STARTED`/`DEFERRED` item için `0..99` editini açar ve isolated acceptance
  paketinde lifecycle/relaunch persistence kanıtını hedefler.
- Actual quantity, reforecast ve project-specific productivity learning
  başlamamıştır.
- Item 5 final completion'ı sonraki owner kararı ve executable evidence ile
  belirlenir; bu belge Items 6–13'ü yeniden sıralamaz.

### 6. Günlük Log Çıktısı v1

Amaç:

- Seçili gün ve proje için Ajanda, Puantaj, Beton, açık takip ve living-plan /
  progress kayıtlarından kaynaklı bir günlük taslağı üretmek.
- Kişisel ve resmî kapsamı karıştırmamak.
- İlk sürümde sade, insan okunabilir ve doğrulanabilir çıktı vermek.

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
PR #467'dir. Issue #468 progress UI + isolated device acceptance current Living
Plan evolution'ıdır. Actual quantity, reforecast ve project-specific productivity
learning başlamamıştır. Item 5'in final completion sınırı sonraki owner kararı
ile executable evidence'a bağlıdır.

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
merged predecessor zinciridir. Güncel güvenli `master`
`3eca007c34951095b24b1b0791146a533b3a8a6d`, schema `16` ve backup format
`1`dir.

Güncel canonical faz:

```text
Living Plan MVP Core — merged / PR #463
→ 7-day UI + APK/device acceptance — merged / PR #465
→ Issue #466 Actual Progress Core — merged / PR #467
→ Issue #468 Progress UI + Isolated Device Acceptance — current
```

Issue #466 / PR #467 nullable actual-progress source-of-truth foundation'ını
schema `16` merged temeline ekler: `NULL` bilinmeyen/raporlanmamış, açık item
explicit progress `0..99`, `COMPLETED` exact `100`dür. Optimistic revision,
durable idempotency/no-op receipt ve append-only event sözleşmesi korunur.
Issue #468 bu progress gerçeğinin dar UI/edit ve isolated device acceptance current
evolution'ıdır; merged değildir. Actual quantity, reforecast ve project-specific
productivity learning başlamamıştır. Item 5 `Current — not complete` kalır;
public/store release veya genel production readiness ilan edilmez. Final
completion sonraki owner kararı ve executable evidence'a bağlıdır; Items 6–13'ün
sırası ve durumu değişmez.
