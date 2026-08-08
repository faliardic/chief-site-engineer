# CSE V2 Kanonik Kapsamı

**Belge türü:** Güncel ürün yürütme kapsamı
**Durum:** Kanonik V2 kapsam ve sıra kaynağı
**Tarih:** 8 Ağustos 2026
**Kaynak Issue:** #383
**Başlangıç `master`:** `7c9f65a811c9f4bca561adab6bd1f8e64e6908cc`

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

## 3. V2'nin amacı

V2'nin amacı yeni modül sayısını büyütmek değil, sahadaki bilgiyi bir kez
yakalayıp doğru proje, mahal, kişi, dosya, iş ve günlük bağlamında tekrar
kullanılabilir hâle getirmektir.

Ana yön:

```text
Proje bağlamını kur
→ Kişi ve saha kimliklerini birleştir
→ Dosya ve medyayı ortaklaştır
→ Ajanda ve Hatırlatıcı ilişkisini güvenilirleştir
→ Günlük işi ve iş zincirini görünür kıl
→ Günlük çıktıyı kaynaklardan üret
```

## 4. Kanonik 13 maddelik V2 paketi

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

### 5. Günlük Log Çıktısı v1

Amaç:

- Seçili gün ve proje için Ajanda, Puantaj, Beton ve açık Hatırlatıcı
  kayıtlarından kaynaklı bir günlük taslağı üretmek.
- Kişisel ve resmî kapsamı karıştırmamak.
- İlk sürümde sade, insan okunabilir ve doğrulanabilir çıktı vermek.

Kapanış kapısı:

- Her satır kaynak kayda geri bağlanabilir.
- Kullanıcı seçimi olmadan private kayıt resmî çıktıya girmez.
- Çıktı deterministik sıra ve tarih kullanır.
- Aynı veri tekrar yazılmadan günlük taslağı hazırlanır.

### 6. İş / Yapılacaklar / Gün Planı

Amaç:

- Hatırlatıcıdan farklı olarak süresi, önceliği, durumu ve gün planındaki yeri
  bulunan iş kaydı oluşturmak.
- Bugün, yaklaşan, geciken ve tamamlanan işleri sade biçimde göstermek.
- İşleri proje, mahal, kişi, dosya ve Ajanda kayıtlarıyla bağlamak.

Kapanış kapısı:

- İş ve reminder semantiği karışmaz.
- İş durumu revision ve event geçmişiyle izlenir.
- Gün planı 30 saniye içinde kritik işleri gösterir.
- Fiziksel silme yerine geri alınabilir yaşam döngüsü kullanılır.

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
| 3 | Günlük Log v1; İş/Gün Planı; İş Zinciri | Günlük saha akışının tek bağlamda çalışması |
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
- Look-ahead, WBS ve Gantt-lite
- PC senkronizasyonu
- Çok kullanıcılı, tenant veya firma portalı yaklaşımları
- Orchestrator, Bridge ve Work Mode'un aktif ürün roadmap'i hâline gelmesi

Bu başlıklar V2 child Issue'larına yan kapsam olarak eklenemez.

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

## 9. İlk production yönü

V2'nin ilk production maddesi **Proje ve Mahal omurgasıdır**.

Önerilen child sıra:

1. Proje düzenleme/arşivleme ve stable mahal sözleşmesi
2. Mahal schema ve migration planı
3. Repository/application implementation
4. Proje/Mahal yönetim UI'sı
5. Ajanda, Hatırlatıcı, Puantaj ve Beton adoption/migration
6. Backup/restore compatibility
7. Saha kabulü

Issue #383 yalnız repository truth-sync işidir. Bu Issue merge edilmeden V2
production implementation'ı başlamaz.
