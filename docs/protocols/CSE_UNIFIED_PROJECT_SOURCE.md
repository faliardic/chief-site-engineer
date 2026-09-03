# CHIEF SITE ENGINEER exe - Birleştirilmiş Proje Kaynağı

**Belge türü:** Kanonik ürün ve veri ilkeleri kaynağı
**Sürüm tarihi:** 2026-09-02
**Durum:** Tracked kanonik ürün kaynağı; dinamik çalışma durumu içermez
**Kanonik repo yolu:** `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`

Bu belge, CHIEF SITE ENGINEER exe projesinin kalıcı ürün yönünü, veri ilkelerini, saha modelini ve tarihsel sözleşmelerini birleştirir. Değişken repository durumu ile GitHub/Codex çalışma kuralları burada kopyalanmaz; `AGENTS.md` ve onun yönlendirdiği güncel protokollerden okunur.

Eski belgeler tarihsel ve destekleyici kaynak olarak korunur. Ürün ve veri ilkelerinde bu belge; execution ve current-state konularında `AGENTS.md`, kanonik protokoller ve güncel GitHub kanıtı esas alınır.

---

## 1. Birleştirilen Kaynaklar

Bu kaynak hazırlanırken aşağıdaki proje kaynakları birlikte incelenmiştir:

1. `Şantiye Şefi İçin Dünya Örneklerine Dayalı Kontrol, Takip ve Arşivleme Sistemi Yol Haritası.pdf`
2. `CHIEF_SITE_ENGINEER_Guncel_Yol_Haritasi_Ozel_Alan_Ekli.pdf`
3. `CSE_CHAT_HANDOFF_PROTOCOL_SOURCE_PACKAGE.zip`
4. `1. CSE önce güvenilir veri omurgası.txt`
5. `CSE_STRATEGIC_PRODUCT_DIRECTION.md`
6. `CSE_GUNCEL_PROJE_TALIMATLARI.md`
7. `STEP_204_CODEX_DUZELTME_TALIMATI.md`
8. Bu sohbet içinde kesinleştirilen Step 206, Step 207, Step 208, Step 209, Step 210 ve Step 211 kararları
9. Güncel GitHub Issue/PR/merge gerçekliği

### Kaynakların kullanım biçimi

- Dünya örnekleri raporu: ürün ve mimari yön için araştırma kaynağıdır.
- Özel alan ekli yol haritası: uzun vadeli modül ve veri modeli kaynağıdır.
- Stratejik ürün yönü: güncel ürün konumlandırmasının ana kaynağıdır.
- Güvenilir veri omurgası metni: değişmez veri ilkelerinin özüdür.
- Güncel proje talimatı: çalışma ve yönetişim kurallarının temelidir.
- Chat Handoff paketi: sohbet devri için tarihsel protokol kaynağıdır; içindeki bazı kurallar güncelliğini yitirmiştir.
- Step 204 talimatı: tamamlanmış bir adıma ait tarihsel uygulama kaydıdır; kalıcı proje talimatı değildir.
- Bu sohbetin son kararları: Codex çağırma, toplu çalışma ve post-merge senkronizasyon politikasının güncel kaynağıdır.

---

## 2. Ana Proje Tanımı

CHIEF SITE ENGINEER (CSE), yalnız şantiye şefi tarafından kullanılan; not, takip, hatırlatıcı, hesap, fotoğraf, belge, günlük, arama ve proje hafızasını tek güvenilir akışta birleştiren local-first ve mobile-first **kişisel saha asistanı**dır.

```text
Araç bakımından geniş
Kullanıcı modeli bakımından tek sahipli
```

Ana çalışma döngüsü:

```text
Yakala
-> İşle
-> Takip et
-> Doğrula
-> Günlüğe al
```

Sistemin temel görevi şunları kolaylaştırmaktır:

- sahada birkaç saniyede not, takip veya kanıt yakalamak;
- aynı bilgiyi tekrar yazmadan işlemek, ilişkilendirmek ve takip etmek;
- fotoğraf ve dosyaları güvenli kaynak kayıtlarla bağlamak;
- açık konunun sonuçlandığını veya ne zaman yeniden görüneceğini bilmek;
- kimin bilgilendirildiğini ve neyin doğrulandığını kaydetmek;
- günlük kaydı gün içindeki kaynaklardan kontrollü bir snapshot olarak üretmek;
- resmî kayıt ile kişisel çalışma hafızasını ayırmak;
- proje devrini ve daha sonra geri çağırmayı güvenilir hâle getirmek;
- ileride AI destekli arama ve soru-cevap için temiz veri üretmek.

### Güncel gerçek kullanıcı problemi

Şantiye şefi bugün:

- sahada sürekli kâğıda kısa not alır;
- boy, alan, hacim, m³, adet ve benzeri hızlı hesapları müsveddede tutar;
- birinden dönüş beklenen işleri zihninde taşır;
- hatırlatıcıya ihtiyaç duyar;
- gün sonunda müsveddeleri ajandaya yeniden yazar;
- aynı bilgiyi not, görev, kanıt ve günlük log için tekrar üretir.

CSE'nin hedefi not almayı yasaklamak değildir. Hedef, bilgiyi bir kez yakalayıp tekrar yazmadan farklı işlevlerde güvenilir biçimde kullanmaktır.

### Ana karar cümlesi

> CSE, yalnız şantiye şefi tarafından kullanılan; not, takip, hatırlatıcı, hesap, fotoğraf, belge, günlük, arama ve proje hafızasını tek güvenilir akışta birleştiren local-first ve mobile-first kişisel saha asistanıdır.

---

## 3. Stratejik Konumlandırma

CSE’nin ilk hedefi Procore, Autodesk Construction Cloud veya Oracle Aconex gibi büyük platformlarla bütün özelliklerde rekabet etmek değildir.

CSE’nin ilk gerçek rakipleri şunlardır:

- WhatsApp grupları
- Telefon galerisi
- Excel listeleri
- Klasör karmaşası
- Defter notları
- E-posta ekleri
- “Bunu bir yere yazmıştım” düzeni

### Ürün filtresi

Her yeni özellik şu sorudan geçmelidir:

> Bu özellik şantiye şefinin sahada unutmamasını, kanıtlamasını, takip etmesini, raporlamasını veya daha sonra geri çağırmasını kolaylaştırıyor mu?

Cevap hayırsa özellik ertelenir veya kapsam dışı bırakılır.

### Temel farklılaşma

CSE’nin farkı çok modüllü olması değil, aşağıdaki işleri sade ve güvenilir yapmasıdır:

- takip için 8 saniyenin altında hedeflenen hızlı yakalama
- resmî gözlem için sade ve kısa kayıt
- Kayıt ile fotoğraf/dosya bağı
- Konum ve sorumlu bilgisi
- Açık/takipte/kapandı süreci
- Resmî ve özel alan ayrımı
- Kanıt ve arşiv bütünlüğü
- Saha tecrübesinden ürüne geri besleme

---

## 4. Değişmez Ürün ve Veri İlkeleri

1. CSE önce güvenilir veri omurgasını kurar; otomasyon ve AI daha sonra gelir.
2. Proje küçük, test edilebilir, geri alınabilir ve commitlenebilir adımlarla büyür.
3. Resmî kayıtlar ile kişisel/özel alan kesin olarak ayrılır.
4. Resmî kayıtlar fiziksel silme yerine arşivleme, pasifleştirme, hükümsüz kılma veya yeni revizyonla değiştirme yaklaşımıyla tasarlanır.
5. Kanıt niteliği taşıyan işlemler audit izi bırakabilecek şekilde modellenir; gerçek audit davranışı yalnız açık görev kapsamında uygulanır.
6. Medya dosyaları veritabanına gömülmez; dosya yolu, metadata ve bütünlük kontrolleriyle yönetilir.
7. Her attachment metadata kaydı fiziksel dosyayla tutarlı olmalıdır.
8. `private` çalışma verisi tek sahibine aittir ve resmî/proje output kapsamına otomatik girmez.
9. Bir aktif proje ve geçmiş proje arşivi desteklenebilir; kurumsal proje portföyü hedeflenmez.
10. Şirketler, ekipler ve diğer kişiler sistem kullanıcısı değil; kişi/kurum ve ilgili taraf kayıt referanslarıdır.
11. Paylaşım için gerekli bilgi private durumda bırakılmaz; açık kullanıcı işlemiyle project kapsama geçirilir ve source uygunluğu doğrulanmış Proje Paketi veya ilgili çıktıya seçilir.
12. `requires_human_review` yalnız insan inceleme sinyalidir.
13. Sistem kendiliğinden `blocked` üretmez.
14. Otomatik kabul, ret, onay, resmî karar veya paket bloklama yapılmaz.
15. Hard validation, migration, persistence, audit, backup/restore, API, GUI ve CLI ayrı ve açık görev gerektirir.
16. Offline, backup, restore, audit ve encryption gibi yüksek riskli alanlar önce belgelenir, sonra kontrollü uygulanır.
17. Saha için ağır ve kullanılmayan formlar yerine hızlı kayıt, güvenilir arşiv ve kanıt zinciri önceliklidir.
18. Uygulamaya yalnız şantiye şefi girer; multi-user, role, tenant, firma portalı ve SaaS ürün hedefi değildir.
19. Tek kullanıcı kararı güvenliği kaldırmaz; güvenlik owner-only cihaz, uygulama kilidi, şifreli backup ve kontrollü senkronizasyon sınırında ele alınır.

### Tasarım ilkesi ile uygulanmış özellik ayrımı

Bir ilkenin belgede bulunması, o davranışın mevcut kodda tam uygulanmış olduğu anlamına gelmez. Özellikle audit, persistence, yetkilendirme, encryption ve silmeme politikaları önce tasarım sözleşmesi olarak tutulabilir; uygulama durumu ayrıca doğrulanmalıdır.

### Faz 0 kanonik ADR indeksi

| Belge | Tek karar alanı | Uygulama durumu |
|---|---|---|
| `docs/adr/ADR-0001-single-memory-and-record-scope.md` | Tek Hafıza, kayıt türü/proje/kapsam ayrımı ve explicit scope conversion | Scope field/event/migration/UI uygulanmadı |
| `docs/adr/ADR-0002-memory-index-record-ref-read-model.md` | Source-of-truth, RecordRef, projection, rebuild ve drift | MemoryIndex schema/projector/UI uygulanmadı |
| `docs/adr/ADR-0003-backup-memory-download-project-package.md` | Backup, Hafızayı İndir, Proje Paketi ve Günlük Çıktı aileleri | Backup v1 ve Daily v1 mevcut; diğer iki aile uygulanmadı |
| `docs/adr/ADR-0004-owner-only-security-and-data-ownership-threat-model.md` | Owner-only asset/trust boundary/threat/data ownership/stop sözleşmesi | Loopback-default mevcut; app lock/auth/TLS/encryption uygulanmadı |

ADR kararı, production implementation kanıtı değildir. Current davranış
repository kodu, executable test ve merged commit kanıtıyla ayrıca doğrulanır.

---

## 5. Tek Kullanıcı Modeli

Uygulamanın tek gerçek kullanıcısı şantiye şefidir.

- Şirket, taşeron, işveren, yapı denetim, saha mühendisi ve kontrol mühendisi kullanıcı hesabı değildir.
- Bu taraflar yalnız `Contact`, `CompanyReference`, bildirilen kişi, beklenen taraf, sorumlu taraf, talimat veren veya belge kaynağı olarak kayıtlarda bulunabilir.
- Çok kullanıcılı ekip üyeliği, firma paneli, rol matrisi veya kurumsal collaboration kapsam dışıdır.

Bir aktif proje ile geçmiş proje arşivi desteklenebilir; kurumsal portföy yönetimi hedeflenmez.

---

## 6. Saha Kullanım İlkesi

Kayıt türüne göre iki hız hedefi vardır:

- `+ Unutma` kişisel takip yakalaması için ortanca süre 8 saniyenin altında olmalıdır.
- Resmî saha gözlemi kısa, kanıtlı ve sahada kullanılabilir kalmalı; eski 20-30 saniyelik kayıt hedefi bu daha ayrıntılı kayıt için üst sınır yönü olarak korunur.

Hızlı takip yakalamasında kullanıcıdan alınan tek zorunlu içerik:

```text
Ne unutulmamalı?
```

Resmî saha gözlemi ilk kayıtta mümkün olduğunca kısa tutulur:

- Tarih
- Proje
- Blok/kat/mahal/alan
- Kategori
- Kısa açıklama
- Fotoğraf veya dosya eki
- Durum
- Kime bildirildi

Detaylandırma, ilişkilendirme, sınıflandırma ve raporlama daha sonra yapılabilir.

### Hızlı kayıt, sonra detaylandırma

Sahada:

- minimum alan
- minimum tıklama
- hızlı fotoğraf
- hızlı durum kaydı

Ofiste:

- detaylandırma
- sınıflandırma
- ilişkilendirme
- raporlama
- arşiv ve kalite kontrol

---

## 7. İlk Saha MVP

İlk saha MVP'si şu yedi çekirdeği hedefler:

1. Hızlı saha gözlem kaydı
2. Fotoğraf/dosya eki bağlama
3. Konum bilgisi
4. Açık/takipte/kapandı durum takibi
5. Kime bildirildi bilgisi
6. Günlük export
7. Haftalık özet

Bu yedi çekirdek tarihsel MVP hedeflerini açıklar; hangilerinin güncel runtime'da uygulandığı veya kabul edildiği burada sabitlenmez. Gerçek implementation durumu güncel GitHub `master`, V2 Scope, Roadmap ve ilgili test/Issue kanıtından doğrulanır.

Tarihsel Flask/PC ve Saha Takibi v0.1 uygulamaları ürün omurgasının gelişim kanıtıdır; güncel mobil runtime, schema veya tamamlanma durumu olarak kullanılmaz. Bu bölüm yalnız MVP yetenek yönünü korur.

### Kalıcı ürün kapsamı dışında kalanlar

- multi-user hesap ve üyelik sistemi
- rol/yetki matrisi ve tenant mimarisi
- firma bazlı veri ayrımı ve şirket portföy dashboard'u
- taşeron, işveren veya yapı denetim portalı
- takım görevlendirme ve ekip içi mesajlaşma
- kurumsal onay zinciri ve workflow motoru
- SaaS hazırlığı, firma lisanslama ve billing
- çok taraflı cloud collaboration
- ERP veya genel entegrasyon pazarı olma hedefi
- tam otomatik resmî karar mekanizmaları

Bunlar “daha sonra” backlog'u değildir. CSE araç bakımından geniş, kullanıcı modeli bakımından tek sahipli kalır.

---

## 8. Dünya Örneklerinden Uyarlanan Dersler

Dünya örnekleri şu ortak omurgayı göstermektedir:

- Saha ve ofisin aynı veri akışında birleşmesi
- Günlük saha verisinin düzenli kayıt hâline gelmesi
- Belge ve çizimlerin sürüm kontrollü yönetilmesi
- Fotoğraf ve formların kanıt niteliğinde arşivlenmesi
- Issue/task/punch süreçlerinin kayıtlarla bağlanması
- Kalite, RFI, raporlama ve analitik katmanlarının temiz veri üzerinde kurulması
- Mobil ve saha öncelikli veri girişi
- Tek doğruluk kaynağı
- Değişiklik ve karar geçmişinin izlenebilirliği

### CSE’ye doğrudan aktarılacak dersler

- Önce şantiye şefi çekirdeği kurulmalı.
- Günlük kayıt, görsel kanıt, görev ve çizim ilişkisi ilk değer eşiğidir.
- Tek sahipli kişisel akış, kurumsal tek platform hedefinden daha üst üründür.
- AI değeri ancak birleşik ve güvenilir veriden doğar.
- Güven; veri sahipliği, owner-only cihaz sınırı, revision, backup ve audit disiplininden doğar.

### Doğrudan kopyalanmayacak yaklaşım

CSE büyük platformların bütün modüllerini başlangıçta taklit etmeyecektir. Dünya örnekleri ürün yönü için referanstır; özellik listesi için zorunlu şablon değildir.

---

## 9. Birleştirilmiş Ürün Katmanları

### Katman 1 - Güvenilir veri omurgası

- Project ve alan modelleri
- Record kimliği ve ilişki sözleşmeleri
- Attachment metadata
- Dosya yolu ve bütünlük kontrolleri
- Durum ve tarih sözleşmeleri
- Read-only diagnostic/report katmanları
- Resmî/özel veri ayrımı
- Gelecekte audit ve persistence için sınırlar

### Katman 2 - İlk saha hafızası

- Hızlı gözlem kaydı
- Fotoğraf/dosya eki
- Konum
- Durum takibi
- Bildirilen kişi
- Günlük ve haftalık çıktı

### Katman 3 - Temel saha operasyonu

- Günlük şantiye defteri
- Fotoğraf arşivi
- Çizim/revizyon defteri
- Görev/issue/punch list
- Inspection/QC formları
- İSG gözlem ve aksiyon
- Malzeme giriş/kullanım
- Toplantı tutanakları
- RFI/submittal lite

### Katman 4 - Tek Hafıza ve private çalışma kapsamı

- Kişisel notlar
- Hatırlatıcılar
- Kişi ve telefon rehberi
- Günlük kişisel gözlem
- Tecrübe bankası
- Karar ve ders arşivi
- Kişisel checklistler
- Hızlı saha cep defteri
- Kişisel risk/takip panosu

### Katman 5 - Kişisel yardımcı kayıt bağlamı

Yapı denetim, EBİS/YDS ve diğer taraflar uygulama kullanıcısı değil; şantiye şefinin kişisel saha hafızasındaki kayıt bağlamıdır.

- Yapı denetim kontrol takip defteri
- Kontrol çağrıları
- Denetçi ve kişi kartları
- Beton döküm kayıtları
- EBİS ve numune zinciri
- İrsaliye ve deney sonuçları
- Donatı/kalıp/beton checklistleri
- Numune sonuç kapanışı
- Uygunsuzluk ve kanıt ilişkileri

### Katman 6 - Mobil-first arayüz ve offline

- Responsive web arayüz
- PWA
- Offline read cache
- Kontrollü offline kayıt ve senkronizasyon

### Katman 7 - Tek sahipli güvenlik ve cihaz sürekliliği

- Uygulama kilidi ve mümkünse cihaz biyometrisi
- Güvenilen cihazlar
- Şifreli backup
- Owner-only telefon-PC senkronizasyonu
- Güvenli yerel ağ erişimi
- Veri sahibinin açık export/devir işlemi

### Katman 8 - Arama, analitik ve AI

- Akıllı arama
- Otomatik rapor özeti
- Risk erken uyarı
- AI destekli soru-cevap

---

## 10. Tek Hafıza ve kayıt kapsamı

Kullanıcı ayrı “özel alan” ve “resmî alan” uygulamalarında çalışmaz. Tek Hafıza
içindeki source kayıtlar `private | project` output/paylaşım kapsamı taşır.
`private`, resmî proje çıktısına doğrudan girmeyen owner çalışma kaydıdır;
cryptographic privacy, rol veya tenant değildir.

Mevcut local MVP'de uygulama kilidi veya encryption bulunmadığı için “kişisel” sözcüğü cryptographic privacy garantisi vermez. Bugünkü anlamı bir erişim rolü değil, çıktı kapsamıdır:

```text
private çalışma kaydı
-> resmî/proje çıktısı dışında

project kapsamlı kayıt
-> source uygunluğu yeniden doğrulanarak günlük, rapor veya Proje Paketi adayı
```

### Kayıt sınıfları

1. Kayıt türü: observation, follow-up, routine occurrence gibi domain kimliği.
2. Kapsam: `private | project` output/paylaşım uygunluğu.
3. Proje bağlantısı: kapsamdan ayrı ilişki; tek başına `project` kapsamı üretmez.

### Gizlilik kuralları

- `private` çalışma verisi varsayılan olarak resmî/proje çıktısı dışında kalır.
- Firma veya başka bir taraf sistem hesabıyla erişemez; böyle hesaplar ürün modelinde yoktur.
- Projeye bağlanmak kaydı otomatik `project` yapmaz.
- Paylaşılacak bilgi açık kullanıcı işlemi, revision ve append-only event ile
  `project` kapsamına geçirilir.
- Kapsamlar arasında otomatik veya görünmez aktarım yapılmaz.

### Tarihsel yardımcı araç adayları

- Kişisel not ekleme ve listeleme
- Kategori ve öncelik
- Hatırlatıcı tarihi
- Kişi kartı
- Telefon ve iletişim bilgisi
- Notu kişiye bağlama
- Günlük hatırlatıcı görünümü

### Yakın kapsam dışı yardımcı araçlar

- Sesli not
- AI arama
- WhatsApp entegrasyonu
- Otomatik telefon entegrasyonu
- Takvim entegrasyonu
- Otomatik transkripsiyon

### Önerilen veri varlıkları

- `PersonalNote`
- `PersonalReminder`
- `FieldContact`
- `ExperienceEntry`
- `PersonalChecklist`
- `PersonalChecklistItem`
- `DecisionLesson`

### Açık kapsam dönüşümü örnekleri

- Private çalışma notu -> project kapsamlı observation
- Private follow-up -> ayrı project observation'a açık conversion
- Private çalışma kaydı -> açık `private -> project` kapsam dönüşümü
- Project kapsamlı source -> uygunluk yeniden doğrulaması sonrası çıktı adayı

Dönüşüm açık kullanıcı işlemi, optimistic revision ve append-only event
gerektirir. Project bağlantısı, link, AI veya routine işlemi scope değiştiremez.

---

## 11. Modül Yol Haritasının Güncel Yorumu

Bu belge kalıcı ürün yönünü korur; tamamlanan madde, aktif iş ve sıradaki görev gibi değişken bilgiler burada dondurulmaz.

Güncel ürün kapsamı ve sırası şu kaynaklardan doğrulanır:

1. `docs/v2/CSE_V2_SCOPE.md`
2. `ROADMAP.md`
3. Güncel GitHub `master`, açık Issue/PR ve owner kararı

Tarihsel modül listeleri araştırma ve iz sürme kaynağıdır. Yeni bir iş, yalnız güncel kapsam ve gerçek saha ihtiyacıyla uyumluysa başlatılır.

---

## 12. Teknik Mimari Yönü

Uzun vadeli mimari katmanlı olmalıdır:

- Domain modelleri
- Uygulama servisleri
- Repository/persistence katmanı
- Dosya ve attachment servisi
- Export/report katmanı
- API
- Web/PWA arayüzü
- Single-owner security ve owner-only cihaz senkronizasyonu
- Audit ve backup/restore
- Search/AI katmanı

### Değişmeyen mimari sınırlar

- Güncel ürün Flutter tabanlı, offline-first ve tek sahipli mobil uygulamadır.
- Mobil runtime bir Python sunucusuna bağlı kabul edilmez.
- Reference snapshot öneri/history olarak immutable kalır.
- Kullanıcıya ait living-plan kararları ayrı mutable/evented katmanda saklanır.
- Stable identity, revision, transaction, history ve backup bütünlüğü korunur.

Runtime sürümü, SQLite schema, backup formatı, son merged SHA, tamamlanan V2 maddeleri ve sıradaki iş değişken repository bilgisidir. Bunlar her görev başında güncel kaynak kodu, GitHub `master`, V2 kapsamı ve aktif Issue üzerinden doğrulanır; bu belge sabit snapshot taşımaz.

---

## 13. Öğrenme Sistemi

CSE, ürün geliştirmeyi uygulamalı öğrenmeyle açıklar; ancak öğrenme çıktısı gerçek saha değeri üreten production zincirinin önüne geçmez.

Öğrenme eksenleri:

- Python ve yazılım geliştirme
- Şantiye şefliği ve saha yönetimi
- Yapı denetim/EBİS/YDS
- Git/GitHub/Codex çalışma disiplini

### Öğrenme dosyası ilkesi

Her teknik adımda her kategori için zorunlu dosya üretilmez. İlgili olduğunda uygun öğrenme dosyası oluşturulur.
Podcast ve tarihsel öğrenme belgeleri korunur; current-state veya ürün otoritesi sayılmaz ve production işini bloke etmez.

Önerilen öğrenme notu yapısı:

- Amaç
- Bu adımda yapılan iş
- Çözülen saha problemi
- Kullanılan teknik kavramlar
- Veri modeli veya sözleşme notu
- Testlerin amacı
- Gerçek şantiye karşılığı
- Sınırlar ve bilinçli olarak eklenmeyenler
- Sonraki küçük adım

---

## 14. Öğrenme ve Podcast Çıktıları

Öğrenme notu, glossary, podcast veya benzeri anlatım çıktıları yalnız owner açıkça istediğinde ya da kalıcı ve yeni bir kavramı açıklamak belirgin öğrenme değeri sağladığında oluşturulur.

Sabit adım aralığı, dosya sayısı veya podcast üretim zorunluluğu yoktur. Bu çıktılar production işini, doğrulamayı, commit/push veya merge akışını bloke etmez.

---

## 15. Kaynak ve Karar Otoritesi

| Bilgi türü | Yetkili kaynak |
| --- | --- |
| Kalıcı ürün amacı ve veri ilkeleri | Bu belge |
| Başlangıç ve kaynak sırası | `AGENTS.md` |
| Git/GitHub/Codex execution kuralları | `CSE_PROJECT_INSTRUCTIONS.md`, `CSE_WORKFLOW_ACCELERATION_PROTOCOL.md` |
| Doğrulama sahipliği ve minimum yeterli test | `CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md` |
| Değişken repository durumu | Güncel GitHub `master`, Issue, PR, branch ve commit kanıtı |
| Aktif işin dar kapsamı | Owner'ın güncel yetkisi ve risk şeridi gerektiriyorsa ilgili Issue |
| Task/result/state kayıtları | İkincil kanıt; yalnız protokol gerektiriyorsa |

Alt düzey bir kaynak kalıcı ürün veya veri güvenliği ilkesini gevşetemez. Statik bir snapshot güncel GitHub gerçeğini geçersiz kılamaz.

---

## 16. Resmî Repository ve Güncel Durum

Resmî repository `faliardic/chief-site-engineer`, varsayılan entegrasyon branch'i `master`dır.

Sabit yerel yol, SHA, schema, version, aktif Issue veya sıradaki iş bu belgede tutulmaz. Her çalışma güncel ortamda `git rev-parse --show-toplevel`, branch/HEAD, worktree ve GitHub kanıtıyla doğrulanır.

---

## 17. Görev Paylaşımı

### Owner / Fatih

- Ürün kapsamının ve ilerlemenin nihai karar sahibidir.
- Manuel ürün/device kabulünü ve nihai görsel/davranış PASS/FAIL kararını verir; PowerShell/terminal komutu çalıştırmaz.
- Ready, merge, Issue close, release, gerçek veri ve branch silme işlemlerine ayrı açık yetki verir.

### ChatGPT

- Güncel GitHub durumunu inceler.
- Uygun risk şeridini ve tek güvenli sonraki adımı belirler.
- Codex'e dar ve kesin görev verir; her handoff'ta kapsam/risk, beklenen validation/build/device işi ve blocker'a göre açık `Execution time budget: <süre>` atar.
- Kanıtı ve diff'i owner açısından sade biçimde raporlar.

### Codex

- Yalnız açıkça yetkilendirilen mikro-adımı uygular.
- Her görevde ChatGPT'nin handoff'ta açıkça verdiği execution time budget'a uyar.
- Repository-local terminal, automated test, analyzer ve build/APK hazırlığını yetkili görev kapsamında çalıştırır. Emulator/ADB/device execution yalnız exact package/device/data-safety owner delegasyonuyla yapılır; Fatih'e terminal komutu verilmez.
- Beklenmeyen değişiklik, izin veya kapsam çelişkisinde fail-closed durur.
- Ready, merge, Issue close veya branch silme yapmaz.

---

## 18. Codex Çağırma Politikası

Codex yalnız yerel dosya değişikliği, statik kontrol, commit/push veya başka mekanik repository işlemi gerektiğinde çağrılır. Planlama, GitHub incelemesi, ürün kararı ve salt-okunur analiz için yeni Codex turu zorunlu değildir.

Her Codex handoff'u ChatGPT'nin göreve özel belirlediği açık execution time budget'ı taşır; global sabit süre varsayılanı yoktur. Yetkili inceleme, edit/fix, focused validation ve commit/push bu bütçeye sığıyorsa tek adımda birleştirilir. Bütçe dolduğunda Codex durur, mevcut çalışmayı güvenle korur; kapsam genişletilmez, yeni yaklaşım veya retry zinciri başlatılmaz, exact blocker ve kalan tek aksiyon raporlanır. Süre bütçesi CRITICAL validation ve güvenlik kapılarını değiştirmez.

---

## 19. Senkronizasyon ve Preflight

Her değişiklik öncesinde yalnız gerekli minimum kontrol yapılır:

- doğru repository ve branch;
- `HEAD` ile ilgili remote ref ilişkisi;
- tracked/staged/untracked kapsamı;
- yarım merge/rebase/cherry-pick bulunmaması;
- exact changed-path allowlist'i;
- riskli işlerde schema/backup/version başlangıç değerleri.

Uyumsuzlukta otomatik düzeltme yapılmadan durulur. Post-merge senkronizasyonu güvenliyse sonraki ilgili işlemin başlangıcına eklenebilir; sırf senkronizasyon için ayrı tur zorunlu değildir.

---

## 20. Risk Şeritleri ve Mikro-Akış

### FAST

Dar, düşük riskli ve geri alınabilir işlerde temiz/senkron `master` üzerinde ilerlenebilir. Issue, PR, `.cse`, routing YAML ve ayrı hazırlık turu zorunlu değildir.

### STANDARD

Birden fazla dosyaya yayılan veya inceleme değeri taşıyan işte tek kısa ömürlü branch kullanılır. Gerekliyse tek PR açılır; başka iş bunun üzerine stacklenmez.

### CRITICAL

Schema, migration, backup, veri bütünlüğü, güvenlik, geniş mimari veya release-critical işlerde Issue, bağımsız branch, Draft PR, provenance ve owner review kapıları korunur.

Non-CRITICAL one-pass akışı:

1. Güncel durum ve owner'ın yetkilendirdiği kapsam doğrulanır; handoff'ta açık execution time budget bulunur.
2. Mevcut doğrudan repro kanıtı kullanılır veya bir kez reproduce edilir; fix/implement yapılır.
3. Codex statik kapsam kontrolünü ve tek focused automated validation'ı yapar; analyzer yalnız material ihtiyaçta eklenir.
4. Manuel/device kabul yalnız runtime'a özgü davranışta veya owner açıkça istediğinde yapılır; gereken kabulde Fatih PASS/FAIL kararını verir.
5. Automated PASS ve gerekiyorsa Fatih PASS sonrası yetkili commit/push aynı execution içinde yapılabilir; kabul gerekmiyorsa manuel PASS beklenmez.
6. Ready/merge/close yalnız ayrı açık owner yetkisiyle ilerler.

CRITICAL işlerde Issue'ya özel validation, owner kabulü ve publication kapıları aynen uygulanır.

FAIL sonucunda yeni özelliğe geçilmez; yalnız exact hataya yönelik dar düzeltme ele alınır.

---

## 21. Git ve Yerel Güvenlik

Exact allowlist dışında dosya stage edilmez veya değiştirilmez. Geniş staging kullanılmaz.

Açık izin olmadan şu işlemler yapılmaz:

- reset, clean veya stash;
- silme, taşıma, rename veya üzerine yazma;
- force-push;
- branch silme;
- gerçek kullanıcı verisi mutation'ı.

Beklenmeyen worktree değişikliği kullanıcıya ait kabul edilir ve korunur.

---

## 22. Test ve Kalite Kontrol

Repository-local terminal, automated test, analyzer ve build/APK hazırlığı Codex tarafından, yetkili görevin minimum yeterli kapsamıyla yürütülür. Fatih PowerShell/terminal/Git/Flutter/test/analyzer/build komutu çalıştırmaz; kendisine bu komutlar hazırlanmaz veya verilmez. Fatih yalnız manuel ürün/device kabulünü ve nihai görsel/davranış PASS/FAIL kararını verir. Emulator/ADB/device execution yalnız exact package, cihaz ve veri-koruma sınırıyla açık owner delegasyonunda yapılabilir; MAIN/Acceptance/Debug ve mevcut veri güvenliği sınırları korunur.

Codex automated execution yanında şu statik kontrolleri yapar:

- dokunulan dosyalarda gerekli format;
- tam diff ve exact changed-path incelemesi;
- `git diff --check`;
- protected drift;
- riskli işlerde schema/backup/version değişimi.

Non-CRITICAL işte doğrudan, tekrarlanabilir owner/device repro kanıtı ve yeterince belirlenmiş source root cause varsa deterministic automated FAIL önkoşulu aranmaz. Owner/device kanıtı, davranışı temsil edemeyen yapay harness'ten üstündür; widget/fake PASS cihaz FAIL'ini geçersiz kılmaz. Bir başarısız repro denemesinden sonra source/runtime diagnosis veya mevcut en güçlü kanıta geçilir. Kararı değiştirmeyen diagnostic/test döngüleri ve değişmeyen source üzerinde geçen testi tekrarlamak yasaktır.

Non-CRITICAL teslimde tek focused automated validation sonucu ve yalnız gerekiyorsa Fatih için kısa manuel/device kabul adımı bulunur. Non-CRITICAL işte bu kabul gerekmiyorsa gerekçesiyle `GEREKMİYOR` kaydedilir; automated PASS sonrası yetkili commit/push manuel PASS beklemez. Manuel/device kabul gerekiyorsa Fatih PASS/FAIL kapısı korunur; gerekli kontrol FAIL/PENDING ise commit/push yapılmaz. CRITICAL işlerde owner PASS ve Issue'ya özel validation/publication kapıları korunur. Ready/merge/release yine ayrı owner yetkisi ister. CI varsa ek güvenlik ağıdır; gereken owner doğrulamasının yerine geçmez.

---

## 23. `.cse` Kayıt Disiplini

`.cse` her mikro-adım için zorunlu değildir.

- FAST: task/result/state dosyası üretilmez.
- STANDARD: yalnız kalıcı iz veya koordinasyon gerçekten gerekiyorsa kullanılır.
- CRITICAL: task, result ve provenance kayıtları kanonik protokole göre tutulur.
- Owner açıkça isterse ilgili kayıt oluşturulur.

Kayıtlar gerçekleşmemiş işi tamamlanmış gösteremez ve güncel GitHub durumunu override edemez.

---

## 24. Branch, PR ve Merge

- Stacked branch/PR oluşturulmaz.
- FAST iş, Codex automated PASS ve yalnız gerekiyorsa Fatih manuel/device PASS sonrasında doğrudan `master`a commit/push edilebilir.
- STANDARD tek bağımsız kısa branch/PR kullanır.
- CRITICAL Draft PR, review ve provenance kapılarını kullanır.
- Draft durumu merge yetkisi değildir.
- Ready, merge, Issue close ve branch delete ayrı owner onayı gerektirir.
- Force-push yasaktır.

---

## 25. GitHub Actions ve CI

CI, mevcut olduğu ve çalışabildiği ölçüde ek kanıt sağlar. Codex'in test süresini uzatmak veya owner testini bekletmek için zorunlu çalışma adımı değildir.

CI başarısızlığı görmezden gelinmez; kök neden ayrıştırılmadan Ready/merge yapılmaz. Billing, runner veya platform durumu değişken GitHub bilgisidir ve bu belgede sabitlenmez.

---

## 26. ZIP, Export ve Handoff

ZIP, source bundle, export veya handoff paketi yalnız owner açıkça istediğinde üretilir. Normal devam akışı GitHub ve `AGENTS.md` üzerinden yürür; sohbetler arasında uzun prompt veya paket taşıma zorunlu değildir.

---

## 27. Yayınlama ve Saha Testi

Yayın ve gerçek cihaz kabulü owner-led'dir. Codex açık yetki olmadan build, install, ADB, emulator, cihaz veya gerçek veri işlemi yapmaz.

Saha testinde sentetik veri, veri koruma, backup/restore, başarısızlıkta durma ve dürüst PASS/PARTIAL/FAIL kaydı esastır. Public/store release veya production readiness yalnız ayrı kanıt ve owner kararıyla ilan edilir.

---

## 28. Güncel Proje Gerçeği

Bu belge current-state snapshot taşımaz.

Her yeni işte şu sıra izlenir:

1. Güncel GitHub `master` HEAD;
2. açık Issue ve PR'lar;
3. ilgili branch/commit diff'i;
4. owner'ın son kapsam ve test kanıtı;
5. gerekiyorsa yerel repository durumu;
6. yalnız destekleyici olarak task/result/state kayıtları.

SHA, version, schema, tamamlanan madde veya sıradaki iş eski metinden tahmin edilmez.

---

## 29. Eski Hükümlerin Durumu

Aşağıdaki tarihsel hükümler artık execution kuralı değildir:

- her işte zorunlu Issue → branch → Draft PR zinciri;
- test/analyzer/build execution'ının Fatih'e atanması;
- göreve özel ChatGPT bütçesi yerine sabit/global execution/test limitleri;
- her adımda zorunlu `.cse` kaydı;
- sabit aralıkta podcast veya learning dosyası;
- her merge sonrası ayrı senkronizasyon turu;
- sabit SHA/schema/version/current-item snapshot'ı;
- her iteration sonunda ZIP/handoff paketi.

Tarihsel kaynaklar iz için korunur; yeni işi yönetmez.

---

## 30. Kaynakların Durum Sınıflandırması

- Bu belgenin ürün, veri ve saha sözleşmeleri aktiftir.
- Execution için `AGENTS.md` ve onun yönlendirdiği protokoller aktiftir.
- V2 kapsamı ve ürün sırası için `docs/v2/CSE_V2_SCOPE.md` ile `ROADMAP.md` aktiftir.
- GitHub current-state için tek güncel kanıttır.
- Eski Step, SHA, handoff, ZIP, learning ve workflow anlatımları tarihseldir.

---

## 31. Bir Sonraki Ürün Yönü

Sıradaki ürün işi bu belgede sabitlenmez. Güncel yön, `docs/v2/CSE_V2_SCOPE.md`, `ROADMAP.md`, güncel GitHub kanıtı ve owner kararı birlikte okunarak belirlenir.

Yeni iş kalıcı ürün ilkelerine uymalı, gerçek saha değerini artırmalı ve aktif işi stacklememelidir.

---

## 32. Son Karar

CSE, yalnız şantiye şefinin kullandığı, araç bakımından geniş ve kullanıcı modeli bakımından tek sahipli kişisel saha asistanıdır:

```text
Yakala
-> İşle
-> Takip et
-> Doğrula
-> Günlüğe al
```

Non-CRITICAL execution döngüsü:

```text
Güncel durumu ve owner'ın yetkilendirdiği kapsamı doğrula
-> ChatGPT her handoff'a explicit execution time budget atar
-> reproduce once (mevcut owner/device kanıtı yeterli olabilir)
-> fix / implement
-> one focused automated validation
-> only-needed manual/device check (Fatih PASS/FAIL)
-> automated PASS ve gerekiyorsa Fatih PASS sonrası yetkili commit/push
-> owner merge gate (ayrı Ready/merge yetkisi)
```

CRITICAL işlerde Issue'ya özel validation, kabul ve publication kapıları aynen korunur.

Ürün ve veri güvenliği değişmez; execution yükü riskle orantılı tutulur.

---

## Tracked GitHub Bootstrap Addendum

Yeni sohbet, projenin güncel durumunu sohbet hafızasından tahmin etmez. Önce repository kökündeki `AGENTS.md` okunur; ardından onun yönlendirdiği güncel GitHub kanıtı ve yalnız gerekli protokoller takip edilir.

Normal devam için ZIP, handoff paketi, source bundle veya uzun prompt kopyalama gerekmez.

---

## 33. Saha Takibi v0.1 Bağlayıcı Sözleşme Kaydı

Issue #98 ve Epic #97 Saha Takibi domain sözleşmesini belirler. Bu bölüm
uygulanmış çekirdeğin tarihsel bağlayıcı kurallarını korur; güncel ürün işi ve
faz sırası §31, `docs/v2/CSE_V2_SCOPE.md` ve `ROADMAP.md` içindedir.

İlk kapsam üç ayrı domain kaydıdır:

- `FollowUpItem`: tek seferlik action, waiting veya recheck takibi.
- `RoutineTemplate`: günlük, iş günü, haftalık veya aylık tekrar kuralı.
- `RoutineOccurrence`: belirli Europe/Istanbul yerel gününde oluşan ve geçmişi şablondan bağımsız kalan gerçekleşme.

Değişmez ürün sınırları:

- `+ Unutma` hızlı create akışında kullanıcıdan yalnız `capture_text` istenir; ilk title deterministic whitespace normalization ile aynı metindir ve sonradan düzenlenebilir.
- `next_attention_at` kaydın ne zaman yeniden kullanıcı önüne geleceğidir; `deadline_at` gerçek son tarihtir ve aynı kavram değildir.
- Bildirimi kapatmak veya görünümden çıkmak takip kaydını tamamlamaz.
- Follow-up ve routine template proje bağlantısı nullable’dır; projesiz kayıt
  current mapping'de `private` kalır. Observation bağlanan follow-up’ın project
  değeri observation projesiyle aynı olmak zorundadır; bu bağlantı scope'u
  otomatik değiştirmez.
- Projeye bağlanmak kişisel takibi otomatik resmî yapmaz; resmî gözleme dönüşüm açık kullanıcı işlemidir.
- Zamanlanmamış açık follow-up yalnız `inbox` olabilir; `active/waiting` mutlaka `next_attention_at` taşır. Unutma Kutusu `inbox` kayıtlarının ayrı sorgusudur.
- `overdue`, `today`, `upcoming` yalnız planlı `active/waiting` kayıtlar için türetilir. `now` domain kategorisi değildir; “Şimdi ilgilen” overdue, zamanı gelmiş today ve önemli inbox kayıtlarının UI bileşimidir.
- Yerel recurrence kararı `Europe/Istanbul`; kalıcı gerçek anlar UTC’dir.
- Bugün dahil son yedi yerel gün için lazy/idempotent backfill yapılır; sınırsız geçmiş üretimi yapılmaz.
- Aynı template ve yerel tarih için yalnız bir occurrence olabilir.
- Template güncellemesi, pasifleştirme, tamamlama ve erteleme geçmiş occurrence’ları yeniden yazmaz.
- Yaşam döngüsü status’ları saklanır; planlı kayıtların `overdue`, `today`, `upcoming` zaman görünümleri sorgu anında türetilir.
- Mutation ve append-only event aynı transaction’da atomiktir; optimistic revision ve no-op davranışı mevcut observation sözleşmesiyle uyumludur.
- Yeni tablolar SQLite schema v3 ile eklenir; mevcut project/observation/attachment/event verisi değiştirilmez ve hard delete eklenmez.
- Tracking verisi SQLite snapshot backup içinde taşınır fakat mevcut günlük resmî observation export’una varsayılan olarak girmez.
- Puantaj ilk aşamada yalnız “her iş günü yapılacak rutin” kabul örneğidir; personel, saat, ücret veya bordro veri modülü değildir.

Ana kullanıcı görünümleri:

- Şimdi ilgilen
- Bugün
- Gecikenler
- Dönüş bekliyorum
- Tekrar kontrol edeceklerim
- Yaklaşanlar
- Unutma Kutusu
- Bugünkü rutinler
- Tamamlanan geçmiş

Kesin domain, recurrence, persistence, backup/restore ve export exclusion sözleşmesi:

```text
docs/field_tracking_v0_1_contract.md
```

Bu sözleşme kaydedildiğindeki tarihsel implementation durumu ve sırası:

1. Domain/recurrence — tamamlandı.
2. Schema v3/repository/event persistence — PR #104 ile tamamlandı.
3. Transactional service/backfill — bekliyor.
4. Backup compatibility ve resmî export exclusion kabulü — bekliyor.
5. Mobil runtime ve veri sahipliği ADR — bekliyor.
6. Mobil-first Kâğıdı Bırakma Sürümü — bekliyor.
7. Offline ve bildirim güvenilirliği — bekliyor.

Bu tarihsel liste current V2 completion veya next-work kaynağı değildir.

Mobil runtime, offline ve notification; auth/multi-user/cloud ile aynı uzak hedef değildir ve gerçek saha pilotlarından önce gelir. Kişisel AI, temiz veri omurgası ve saha pilotlarından sonra gelir.
