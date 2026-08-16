# CHIEF SITE ENGINEER exe - Birleştirilmiş Proje Kaynağı

**Belge türü:** Birleştirilmiş ana proje kaynağı
**Sürüm tarihi:** 2026-07-16
**Durum:** Tracked kanonik ürün ve kalıcı politika kaynağı
**Kanonik repo yolu:** `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`

Bu belge, CHIEF SITE ENGINEER exe projesine ait mevcut yol haritalarını, ürün stratejisini, veri ilkelerini, özel alan modelini, Chat Handoff paketini, güncel proje talimatlarını, GitHub/Codex çalışma düzenini ve bu sohbet içinde alınan son kararları tek kaynağa birleştirir.

Bu belge onaylanıp proje kaynaklarına eklendiğinde, eski belgeler tarihsel ve destekleyici kaynak olarak korunmalı; güncel karar ve çalışma düzeni için bu belge ile tracked kanonik proje talimatı esas alınmalıdır.

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

Merge edilmiş Local Field MVP ilk altı hedefi destekleyen SQLite persistence ve migration runner, managed attachment store, local Flask web akışı, proje/gözlem create-list-detail-update, revision conflict koruması, arama, günlük export, backup/verify/izole restore ve Windows tek tık launcher içerir. Haftalık özet ürün yüzeyi henüz tamamlanmış kabul edilmez.

Bu omurganın üzerindeki Saha Takibi v0.1 diliminde domain/recurrence, SQLite
schema v4 repository/event persistence, transactional application service,
yedi günlük lazy backfill, Backup compatibility, resmî export izolasyonu ve ilk
PC UI tamamlanmıştır. Gerçek saha kabulü, mobile/offline/notification ve ortak
Hafıza yaşam döngüsü tamamlanmamıştır.

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

Eski yol haritalarındaki 001-034 modül listesi tarihsel referanstır. Güncel V2
ürün paketi ve sırası `docs/v2/CSE_V2_SCOPE.md` ile `ROADMAP.md` içindedir.
Kurumsal/multi-user ürün hedefleri geri dönmez.

### Güncel öncelik sırası

```text
1. Proje/Mahal — complete
2. Sicil/Puantaj V2/Saha Rehberi — complete
3. Attachment/Fotoğraf/Medya V2 — complete
4. Ajanda V2 + kontrollü sync — complete
5. 7 Günlük Yaşayan İş Programı / İş ve Gün Planı — current
6. Günlük Log Çıktısı v1
7. İş Zinciri / Bağlı Log v1
8. İstenecek Malzemeler
9. Deterministik kişi/firma/etiket önerileri
10. Telefon görüşmesi sonucu → Ajanda
11. Proje fotoğraf/video albümü
12. Günlük Log Çıktısı v2
13. Mini hesap makinesi
```

Teknik sistem binlerce inşaat aktivitesi ve deterministik bağımlılık taşıyabilir;
şantiye şefinin kullanıcı akışı aktiviteyi bulup yakın plana birkaç işlemle
eklemek ve yalnız önündeki yedi günü güncel tutmak kadar sade kalır. Bu living
site plan bir Primavera klonu veya approved/contractual baseline değildir.

Activity Catalog Runtime, typed Project Profile ve Dependency Catalog, Project
Activity Instance Graph, deterministic Schedule Date Engine ve immutable
persistent reference-schedule snapshots merged temeldir. UI'dan önce yalnız
tek dar Living Plan MVP Core slice'ı gelebilir; immediate successor 7-day UI +
APK/device acceptance olmalıdır.

### Tarihsel Mobil-first Kâğıdı Bırakma çerçevesi

Bu çerçeve geçmiş ürün yönünü açıklar; güncel V2 Item 5 sırasını override etmez.
İlk gerçek saha pilotu için tariflenen minimum bütünleşik yüzey şunlardı:

- `+ Yakala` / `+ Unutma`;
- Bugün / Şimdi ilgilen / Geciken;
- Dönüş bekliyorum / tekrar kontrol;
- rutinler;
- fotoğraf veya dosya ekleme;
- minimum hızlı hesap şeridi;
- günlük zaman çizelgesi ve düzenlenebilir taslak;
- arama;
- backup durumu/görünürlüğü.

Minimum hesap şeridi ile günlük zaman çizelgesi pilot öncesidir; gelişmiş hesap araçları ve yayımlanmış immutable günlük zinciri sonraki fazlarda kalır.

### Kayıtlı mühendislik hesap defteri

İlk Kâğıdı Bırakma Sürümü minimum hızlı hesap şeridi taşır. Bu bölümdeki gelişmiş ve kaydedilebilir mühendislik hesap defteri 30 günlük ana uygulama pilotundan sonra gelir ve yalnız sonucu değil şunları korur:

- girdiler;
- birimler;
- formül veya işlem şeridi;
- sonuç;
- tarih/saat;
- açıklama;
- proje, konum ve iş paketi bağlantısı;
- varsa fotoğraf veya kroki;
- resmî kayda aktarım durumu.

Kişisel hesap otomatik resmî metraj değildir. Resmî aktarma açık kullanıcı onayı gerektirir.

### Günlük şantiye logu

Günlük Log Çıktısı v1, ilk usable Living Plan sonrasında gelir ve gerçek
plan/progress/source kayıtlarını tüketir; primary saha-yönetimi döngüsünü
geciktirmez.

Gelişmiş günlük zincirinde taslak akşam kontrol edilip yayımlanan bir snapshot olur. Yayımlanmış günlük sessizce değişmez; düzeltme yeni revizyon veya ek ile yapılır.

### Canlı Proje Haritası

Harita ana veri kaynağı değil, kaynak kayıtların proje bağlamındaki read-model/projeksiyonudur.

```text
Proje dairesine dokun
-> ana iş/alan baloncukları

Taşıyıcı baloncuğa dokun
-> baloncuk büyüyerek yeni odak olur

Yaprak baloncuğa dokun
-> ayrıntılı ve düzenlenebilir kaynak kayıt çalışma ekranı
```

Haritada mouse wheel zoom, pinch zoom, trackpad zoom, pan/sürükleme, serbest zoom veya `+/-` zoom kontrolü bulunmaz. Tam uzak görünümde yalnız proje adını taşıyan en büyük daire görünür. `88/140`, `231 m³` veya `4 açık takip` gibi hesaplanmış balonlar doğrudan düzenlenmez; kaynak kayıt düzenlenir ve özet yeniden hesaplanır.

Harita minimum Saha Takibi UI ve gerçek saha kabulünden önce production önceliği değildir.

### Bugün, Harita, kayıt ve günlük ayrımı

- `Bugün`: Şu anda ne yapmalıyım?
- `Harita`: Bu bilgi proje içinde nerede?
- `Kayıt çalışma alanı`: Tam olarak ne oldu ve hangi işlem yapılacak?
- `Günlük`: Bugün ne yaşandı?

`Bugün`, `Geciken` ve `Beklenen` ayrı kopya kayıtlar değildir; aynı source record'ların dinamik görünümleridir.

### Eski modül numaraları

Eski modül numaraları arşiv referansı olarak kullanılabilir; yeni teknik adımların numarasıyla karıştırılmamalıdır. Teknik Step numaraları Git/GitHub geliştirme geçmişini, modül numaraları ise tarihsel ürün backlog’unu temsil eder.

### Legacy model envanteri ve deprecation yönü

Fiziksel silme öncesinde ayrı bir envanter görevi şu adayları sınıflandırır:

- `TrackingRecord` / `TaskCandidateRecord` -> `FollowUpItem` yönü;
- `AttachmentRecord` / `FileAttachmentRecord` -> kalıcı attachment metadata/store yönü;
- `DailySiteLog` / `DailyReportRecord` -> gelecekte `DailyLogSnapshot` yönü;
- `ProjectPartyRecord` / `ContactPersonRecord` / `SupplierRecord` -> tek kişi/kurum referans yönü;
- `MeetingActionRecord` / `RFIRecord` / `SubmittalRecord` -> not + takip + beklenen cevap ilişkisi;
- karmaşık NCR prototip zinciri -> gözlem + aksiyon + kanıt + sonuç temelinde yeniden değerlendirme;
- `app/records.py` in-memory repository'leri -> SQLite karşılıkları doğrulandıktan sonra deprecation.

Sınıflandırma sözlüğü `Aktif çekirdek`, `Dönüştürülecek`, `Legacy/arşivlenecek` ve `Silme adayı`dır.

Bu yön fiziksel silme, rename, import taşıma veya test kaldırma yetkisi vermez.

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

### Güncel gerçeklik

Güncel ürün Flutter tabanlı, offline-first ve tek sahipli mobil uygulamadır.
Mobile version `0.1.0+1`, SQLite schema `14`, backup format `1` ve safe merge
`447916be0b3ddd2af75b0fe85f8c7f710f29c1cd` değeridir.

V2 Items 1–4 complete'tir. Merged schedule foundation şunları içerir:

- Activity Catalog Runtime;
- typed Project Profile ve Dependency Catalog Runtime;
- Project Activity Instance Graph;
- deterministic Schedule Date Engine;
- immutable persistent reference-schedule snapshots;
- trusted date-window query.

Reference snapshot öneri/history olarak immutable kalır. Living-plan kullanıcı
kararları bunun üzerinde değil, ayrı mutable/evented katmanda saklanacaktır.
Item 5 Living 7-Day Plan current direction'dır fakat complete değildir. UI/APK/
device acceptance, actual quantity/progress/reforecast ve project-specific
productivity learning henüz uygulanmamıştır.

V1 owner saha kullanımı vardır; public/store release ve genel production
readiness ilan edilmemiştir. Python/Flask çekirdeği tarihsel ürün omurgası ve
sözleşme referansı olarak repository içinde korunur; güncel mobil runtime bir
Python sunucusuna bağlanmaz.

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

## 14. Podcast Disiplini

Her beş teknik Step tamamlandığında NotebookLM podcast notu oluşturulur.

Güncel durum:

- Podcast 030: Steps 196-200
- Podcast 031: Steps 201-205
- Sıradaki doğal aralık: Steps 206-210

Podcast notu yalnız ilgili aralığı kapsamalı ve ürün, teknik, saha ve öğrenme kazanımlarını birlikte açıklamalıdır.

---

## 15. Kaynak ve Karar Otoritesi

Tek bir genel sıralama yerine her bilgi türünün ayrı yetkili yüzeyi vardır:

| Bilgi türü | Yetkili kaynak |
| --- | --- |
| Kalıcı ürün amacı, ilkeler ve ürün sırası | `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md` |
| Git/GitHub/Codex güvenliği ve çalışma protokolü | `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md` |
| Aktif görevin dar kapsamı | current GitHub Issue ve `.cse/tasks/<issue_no>_task.md` |
| Değişken repository durumu | GitHub `master`, PR, Issue, branch ve commit kanıtı |
| Yerel factual mirror ve completion evidence | `.cse/state/project_state.json` ve `.cse/results/<issue_no>_result.md` |
| Tarihsel yön ve karar izi | `ROADMAP.md`, `docs/project_decisions.md`, `CHANGELOG.md` |

Current state her yeni iş öncesinde `origin/master` HEAD, açık Issue/PR'lar, ilgili diff, current Issue completion evidence'i ve yerel doğrulama ile belirlenir. `.cse/state`, README, ROADMAP, handoff, ZIP veya sohbet hafızası bu GitHub gerçeğini override edemez.

### Yerel ayna

Kök dizindeki ignored `CSE_GUNCEL_PROJE_TALIMATLARI.md` yalnız yerel kolaylık aynasıdır. Güncelliği kanıtlanmadan kullanılmaz; tracked kanonik dosyadan daha yüksek önceliğe sahip değildir ve normal görevlerde otomatik olarak değiştirilmez.

---

## 16. Resmî Repository ve Çalışma Yolu

Repository:

```text
faliardic/chief-site-engineer
```

Resmî yerel çalışma kopyası:

```text
V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer
```

Varsayılan branch:

```text
master
```

CSE için otomatik `C:` clone/workspace oluşturulmaz.

Şu eski/yanlış yol kullanılmaz ve yeniden oluşturulmaz:

```text
C:\Users\Fatih\Documents\chieh-site-engineer
```

Ayrı Desktop arşiv kopyası doğrulanmadan silinmez veya değiştirilmez:

```text
C:\Users\Fatih\Desktop\fatih\chief-site-engineer
```

---

## 17. ChatGPT, Codex ve GitHub İş Bölümü

### ChatGPT

- GitHub durumunu kontrol eder.
- Issue oluşturur veya günceller.
- Codex gerekip gerekmediğine karar verir.
- Codex gerekiyorsa kullanıcıya açıkça **“Codex çalışmalı”** der ve nedenini belirtir.
- Branch diff’ini ve kanıtları inceler.
- Draft PR açar.
- PR’ı ready yapar.
- Kullanıcı onayıyla squash merge yapar.
- Gereksiz Codex çalışmalarını engeller.
- Proje dosyalarını GitHub connector üzerinden üretmez.

### Codex

- Yalnız resmî `V:` reposunda çalışır.
- Yerel dosya oluşturma/düzenleme, test, branch, commit ve push işlerini yapar.
- Yalnız Issue tarafından yetkilendirilen kapsamda çalışır.
- Beklenmeyen yerel değişiklikte durur.
- Tamamlama kanıtını güncel Issue’ya ekler.
- Varsayılan olarak PR açmaz ve merge yapmaz.

### GitHub

- Senkronize remote ve inceleme yüzeyidir.
- Issue, PR, review ve merge kayıtlarını taşır.
- Tek başına GitHub üzerinden dosya oluşturulması yerel uygulama tamamlandı anlamına gelmez.

### Kullanıcı

- Ürün kapsamının nihai karar sahibidir.
- `devam`, `işlem tamam` veya eşdeğer kısa komutlarla güvenli akışı ilerletir.
- Uzun talimat ve sonuç bloklarını ChatGPT ile Codex arasında taşımak zorunda değildir.

---

## 18. Codex Çağırma Politikası

Codex’in çalışması gerektiğine ChatGPT karar verir.

### Codex çalışmalı

- Yerel proje dosyası oluşturulacak veya düzenlenecekse
- Yerel test/script çalıştırılacaksa
- Hash, ZIP, ignored file, exports, path veya worktree kontrolü gerekiyorsa
- Branch oluşturma/değiştirme gerekiyorsa
- Commit veya push yapılacaksa
- Yerel hata çözülecekse
- Yerel master senkronizasyonu gerekiyorsa
- GitHub üzerinden güvenle yapılamayan yerel işlem varsa

### Codex normalde gerekmez

- Planlama ve mimari değerlendirme
- Ürün önceliklendirme
- GitHub Issue/PR/diff/comment/review kontrolü
- Issue veya yorum oluşturma
- Pushlanmış branch için Draft PR açma
- PR’ı ready yapma
- Squash merge
- Kavramsal analiz ve araştırma
- Yalnız GitHub durumunu raporlama

### Toplu çalışma modeli

```text
1 teknik adım = 1 ana Codex çalışması
engelleyici hata = en fazla 1 düzeltme çalışması
post-merge sync = güvenliyse sonraki Codex gerektiren işin başında
```

Her küçük yorum, metadata gözlemi veya engelleyici olmayan metin düzeltmesi için ayrı Codex turu açılmaz.

### Düzeltme turu gerektiren durumlar

- Test başarısızlığı
- Yetkisiz dosya değişikliği
- Yanlış repo/branch
- Bozuk JSON
- Eksik zorunlu dosya
- Merge güvenliğini etkileyen repository truth çelişkisi
- Gerçek kapsam veya veri güvenliği sorunu

### Metadata churn yasağı

Bir commit’in kendi SHA’sını aynı commit içindeki result/state dosyasına yazmak için yeni commit zinciri oluşturulmaz.

Final branch SHA ve divergence şu yüzeylerde kaydedilebilir:

- Issue completion comment
- GitHub branch bilgisi
- PR metadata

İkinci metadata commit’i yalnız gerçek ve engelleyici bir çelişki varsa yapılır.

---

## 19. Post-Merge Senkronizasyon Politikası

Merge sonrası yerel `master`ın anında senkronlanması her zaman ayrı Codex çalışması gerektirmez.

Güvenliyse senkronizasyon, sonraki Codex gerektiren görevin ilk aşamasında toplu yapılır.

Bu yapılana kadar yerel master’ın senkron olduğu iddia edilmez.

### Hemen senkronizasyon gereken durumlar

- Hemen ardından yeni yerel iş başlayacaksa
- Yerel durum belirsizse
- Kullanıcı açıkça isterse
- Merge sonrası yerel doğrulama kritikse

### Senkronizasyon komutları

```powershell
git fetch origin --prune
git checkout master
git pull --ff-only origin master
git rev-parse master
git rev-parse origin/master
git rev-list --left-right --count origin/master...master
```

Beklenen divergence:

```text
0 0
```

---

## 20. Standart Teknik Adım Akışı

1. ChatGPT güncel GitHub durumunu doğrular.
2. Küçük ve sınırları net bir Issue açar veya günceller.
3. Codex gerekip gerekmediğine karar verir.
4. Gerekliyse kullanıcıya “Codex çalışmalı” bildirimi yapılır.
5. Codex tek toplu çalışmada:
   - resmî repo doğrulaması
   - gerekiyorsa post-merge sync
   - branch oluşturma
   - task dosyası
   - yetkili değişiklikler
   - test ve kalite kontrol
   - commit ve push
   - completion evidence
   işlemlerini yapar.
6. ChatGPT branch ve kanıtları inceler.
7. Güvenliyse Draft PR açılır.
8. Yalnız engelleyici hata varsa bir düzeltme turu istenir.
9. İnceleme geçerse PR ready yapılır.
10. Kullanıcının `devam` komutu güvenliyse merge akışını ilerletir.
11. Squash merge uygulanır.
12. Post-merge sync hemen veya sonraki gerekli Codex çalışmasının başında yapılır.

Yeni branch standardı:

```text
codex/issue-<issue_no>-<slug>
```

Eski `step-NNN-*` branch'ler tarihsel olarak korunur ve yeniden adlandırılmaz. Aynı anda yalnız bir aktif production implementation görevi ve en fazla bir incelemede PR bulunur; dokümantasyon işi aktif production branch'ini sessizce geçmez.

---

## 21. Git ve Yerel Güvenlik Kuralları

Her yerel çalışma öncesinde:

```powershell
Set-Location 'V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer'
git rev-parse --show-toplevel
git status --short --branch
git status --ignored --short --untracked-files=all
git remote -v
```

Beklenmeyen tracked, staged veya untracked proje değişikliği varsa durulur.

Otomatik olarak yapılmaz:

- `reset`
- `clean`
- `stash`
- silme
- taşıma
- rename
- üzerine yazma
- force push
- branch deletion

---

## 22. Test ve Kalite Kontrol

Her teknik yerel çalışmada uygun olan kontroller:

```powershell
python -m pytest
git diff --check
git diff -- app/models.py tests/test_models.py .github/workflows/pytest.yml
python -m json.tool .cse/state/project_state.json
```

Ayrıca:

- Değişen dosyalar Issue kapsamıyla aynı mı?
- Gerekli dosyalar fiziksel olarak yerelde mevcut mu?
- `exports/` beklenmeyen çıktı içeriyor mu?
- Ignored ZIP dokunulmamış mı?
- Branch local/remote SHA aynı mı?
- Divergence `0 0` mı?
- Final çalışma ağacı durumu doğru raporlandı mı?

Üretim kodu değiştiyse test eklenir veya güncellenir. Dokümantasyon-only adımlarda üretim kodu ve test davranışı değiştirilmez.

---

## 23. `.cse` Kayıt Disiplini

Her teknik adımda uygun kayıtlar:

```text
.cse/tasks/<issue_no>_task.md
.cse/results/<issue_no>_result.md
.cse/state/project_state.json
```

### State ayrımı

- `current_safe_point`: son merged/finalized güvenli nokta
- `active_work`: henüz merge edilmemiş aktif iş

Aktif iş merged safe point gibi gösterilmez.

### Result dosyası

Result dosyası olgusal olmalıdır ve mümkün olduğunda şunları içerir:

- Resmî yerel yol
- Base/master SHA
- Master divergence
- Branch adı
- Değişen dosyalar
- Test sonucu
- `git diff --check`
- Protected path durumu
- `exports/` ve ZIP durumu
- Çalışma ağacı durumu
- Push sonucu
- PR durumu
- Kalan işler

Henüz gerçekleşmemiş işlem tamamlanmış gibi yazılmaz.

---

## 24. PR ve Merge Kuralları

- Yeni iş doğrudan `master` üzerinde yapılmaz.
- PR önce Draft açılır.
- Varsayılan PR açma sorumlusu ChatGPT’dir.
- Codex yalnız açık yetki varsa PR açabilir.
- Merge yöntemi squash merge’dir.
- Force push yapılmaz.
- Branch otomatik silinmez.
- Review, kapsam ve test kontrolü geçmeden merge yapılmaz.
- Temiz inceleme sonrasında `devam` veya eşdeğer komut merge onayı sayılır.

---

## 25. GitHub Actions ve CI

Workflow dosyası korunur:

```text
.github/workflows/pytest.yml
```

Otomatik GitHub Actions çalıştırması billing/runner-start problemi nedeniyle manuel olarak devre dışıdır.

Güncel kurallar:

- Yeniden etkinleştirilmez.
- Required checks açılmaz.
- Workflow gereksiz değiştirilmez.
- Güvenlik doğrulaması yerel testlerle yapılır.
- Yalnız kullanıcı açıkça ister ve hesap sorunu çözülürse yeniden değerlendirilir.

Dünya örnekleri raporundaki otomatik CI/Codex review önerileri uzun vadeli yön olarak korunur; güncel hesap koşullarında uygulanmaz.

---

## 26. ZIP, Export ve Handoff Politikası

### ZIP

Mevcut ignored ZIP acil/offline yedektir:

```text
chief-site-engineer_adim_080_guvenli_nokta.zip
```

ZIP:

- stage edilmez
- silinmez
- taşınmaz
- yeniden adlandırılmaz
- commitlenmez

Her iteration sonunda yeni ZIP oluşturma kuralı kaldırılmıştır.

Yeni ZIP yalnız kullanıcı açıkça isterse oluşturulur.

### Export

`exports/` varsayılan olarak yalnız `.gitkeep` içermelidir. Bir görev açıkça export üretmiyorsa burada yeni çıktı oluşmamalıdır.

### Chat Handoff

`chat_handoff/` uzun sohbet geçişlerinde kullanılabilecek yardımcı bir özet katmanıdır.

Handoff:

- normal teknik adımın zorunlu parçası değildir
- her iteration sonunda otomatik oluşturulmaz
- Git, Issue, PR veya state kayıtlarının yerine geçmez
- yalnız kullanıcı istediğinde veya gerçekten yeni sohbete geçerken güncellenir
- tam prompt geçmişi yerine güvenli ve kısa proje özeti tercih edilir

Önerilen handoff dosyaları:

- `CURRENT_CONTEXT.md`
- `PROJECT_RULES.md`
- `ACTIVE_ROADMAP.md`
- `LAST_DECISIONS.md`
- `NEXT_ACTION.md`
- `MODULE_INDEX.md`
- `FILE_INDEX.md`
- `NEW_CHAT_START_PROMPT.md`

---

## 27. Yayınlama ve Saha Testi Stratejisi

CSE yayınlanmak için acele etmez.

Önerilen sıra:

1. Mobil-first Kâğıdı Bırakma Sürümü'nü şantiye şefinin ana uygulaması yapma
2. 7 günlük gerçek saha pilotu
3. 30 günlük ana uygulama pilotu
4. Backup/restore tatbikatı ve veri kaybı kontrolü
5. Kullanım sürtünmelerini ve kâğıda dönüş nedenlerini azaltma
6. Gerçek kullanımın kanıtladığı kişisel yardımcı araçları değerlendirme

### Saha geri besleme döngüsü

```text
Gerçek şantiye
-> gerçek problem
-> küçük kayıt aracı
-> sahada test
-> düzeltme
-> belge ve test
-> kontrollü ürün geliştirme
```

---

## 28. Güncel Proje Gerçeği

Bu bölüm kalıcı ürün politikasından ayrı bir factual snapshot'tır. Güncel durum her yeni görev başında GitHub ve yerel Git kanıtıyla yeniden doğrulanır; bu metin yeni kanıtı override etmez.

### 2026-08-16 doğrulanmış merged nokta

- Son schedule foundation görevi: Issue **#458**
- Squash-merge PR: **#459**
- `master` commit:

```text
447916be0b3ddd2af75b0fe85f8c7f710f29c1cd
```

- Mobile version `0.1.0+1`, SQLite schema `14` ve Backup format `1` current'tır.
- V2 Items 1–4 complete'tir.
- Activity Catalog, typed Project Profile/Dependency Catalog, Project Activity
  Instance Graph, Schedule Date Engine ve persistent immutable reference
  snapshots merged schedule foundation'dır.
- Latest merged validation authority: database `22/22`, snapshot repository
  `11/11`, Schedule Engine `23/23`, backup/restore `36/36`, full Flutter
  `663/663`, analyze/integrity/FK PASS.
- Living Plan UI/APK/device kabulü, progress/reforecast ve productivity learning
  uygulanmadı.
- Public/store release ve production readiness ilan edilmedi.
- GitHub Actions hesabın runner/billing sınırı nedeniyle manuel olarak devre dışı kalır; yerel doğrulama zorunludur.

### Aktif production işi

Issue #460 source-authority truth-sync'i production davranışı değiştirmez.
Güncel canonical faz `truth-sync complete / Living Plan MVP Core ready`dir.
Sonraki production işi yalnız dar Living 7-Day Plan MVP Core olabilir; onun
immediate successor'ı 7-day UI + APK/device acceptance olmalıdır.

### Current-state doğrulama sırası

1. `origin/master` HEAD;
2. açık Issue ve PR'lar;
3. ilgili branch/commit diff'i;
4. current Issue completion evidence'i;
5. resmî `V:` kopyasındaki yerel doğrulama;
6. `.cse/state` ikincil factual mirror.

---

## 29. Kaynak Çakışmaları ve Kesin Çözümleri

### 29.1 Her iteration sonunda ZIP

**Eski kural:** Her iteration sonunda ZIP paketi ve sohbet arşivi oluştur.
**Güncel karar:** Kaldırıldı. ZIP yalnız açık kullanıcı talebiyle oluşturulur.

### 29.2 Handoff’un ana proje hafızası olması

**Eski kural:** Yeni sohbet yalnız handoff klasörünü esas alsın.
**Güncel karar:** Handoff yardımcı özet katmanıdır; kanonik talimat, GitHub ve `.cse` kayıtlarının yerine geçmez.

### 29.3 Yerel root talimatının en yüksek otorite olması

**Eski kural:** `CSE_GUNCEL_PROJE_TALIMATLARI.md` en yüksek öncelikli kaynak.
**Güncel karar:** Tracked kanonik dosya tek otoritedir; root dosya yalnız ignored yerel aynadır.

### 29.4 Her merge sonrası ayrı Codex sync

**Eski kural:** Merge sonrası hemen Codex çalıştır ve local master’ı senkronla.
**Güncel karar:** Güvenliyse sonraki Codex gerektiren işin başında toplu senkronizasyon yapılır.

### 29.5 Her Issue/comment sonrası Codex’in hemen çalışması

**Eski uygulama:** GitHub talimatı yazılır yazılmaz Codex turu açmak.
**Güncel karar:** ChatGPT Codex gerekliliğini değerlendirir ve yalnız gerektiğinde açıkça bildirir.

### 29.6 Her küçük metadata hatası için yeni commit

**Eski uygulama:** Result/state içinde final SHA yazmak için ek commit zinciri.
**Güncel karar:** Final SHA Issue veya PR metadata’da tutulabilir; yalnız gerçek engelleyici çelişkide düzeltme commit’i yapılır.

### 29.7 Eski aktif Step bilgileri

Step 203-225 aralığını aktif iş veya son güvenli nokta olarak gösteren metinler tarihsel kayıttır. Güncel merged nokta GitHub'dan doğrulanır; 2026-07-15 snapshot'ında Issue #102 / PR #104 / `9b25152ae38b72470e332929cb3a30ff955b75f1` esas alınır.

### 29.8 Eski modül sırasının bağlayıcı olması

001-034 modül listesi tarihsel backlog referansıdır. Yalnız gerçek kullanımın kanıtladığı kişisel yardımcı araçlar Epic #105 Faz 11'de yeniden değerlendirilir; kurumsal/multi-user hedefler geri alınmaz.

### 29.9 Her iteration için üç ayrı learning dosyası

**Eski kural:** Python, saha ve EBİS için her adımda ayrı dosya.
**Güncel karar:** Yalnız gerçekten ilgili olan öğrenme dosyaları oluşturulur.

### 29.10 Otomatik CI ve branch protection

Dünya örnekleri raporunda önerilen otomatik CI ve branch protection uzun vadeli iyi uygulamadır. Güncel billing/runner-start koşulu nedeniyle Actions ve required checks kapalı kalır.

### 29.11 Audit ilkesi ile mevcut uygulama

“Kanıt işlemi audit izi bırakır” ürün tasarım ilkesidir. Audit davranışı mevcut uygulamada otomatik olarak var kabul edilmez; ayrı görevle uygulanır.

### 29.12 Step 204 düzeltme talimatı

`STEP_204_CODEX_DUZELTME_TALIMATI.md` tamamlanmış geçmiş adıma aittir. Güncel proje davranışını yönetmez; arşiv kaynağıdır.

---

## 30. Kaynakların Durum Sınıflandırması

### Aktif ve korunacak

- Birleştirilmiş bu kaynak
- Tracked kanonik proje talimatı
- Stratejik ürün yönü
- Güvenilir veri omurgası ilkeleri
- Güncel GitHub Issue/PR/state/result kayıtları

### Destekleyici ve uzun vadeli

- Dünya örnekleri yol haritası
- Özel alan ekli modüler yol haritası
- Eski modül listeleri
- Chat Handoff dosya şablonları

### Arşiv/historical

- Step 204 özel düzeltme talimatı
- Eski aktif Step ve commit bilgileri
- Her iteration ZIP zorunluluğu
- Eski CI/branch protection zorunluluğu
- Her adımda üç learning dosyası zorunluluğu

---

## 31. Bir Sonraki Ürün Yönü

Güncel 13 maddelik V2 paketinde Items 1–4 complete'tir. Revised Item 5,
**7 Günlük Yaşayan İş Programı / İş ve Gün Planı**, current direction'dır.

Hedef kullanıcı döngüsü:

```text
Reference schedule suggests
→ site manager selects/adds to the seven-day plan
→ Planlandı / Başladı / Tamamlandı / Ertelendi
→ actual field evidence is recorded
→ dependent planning can later be recalculated
→ project-specific productivity learning follows real data
```

Reference schedule immutable suggestion/history olarak kalır; living-plan user
decisions ayrı mutable/evented layer'da stable project/activity-instance/
snapshot kimliklerine referans verir. İlk sonraki production Issue yalnız dar
Living Plan MVP Core'dur. Immediate successor 7-day UI + APK/device acceptance
olmalıdır; başka geniş backend fazı araya giremez.

Critical path/float, full Gantt/Primavera replacement, approved baseline,
automatic reforecast, productivity learning, resource optimization ve AI/cloud
planning ilk usable UI/device pilotundan sonradır. Item 5 UI/APK/device kabulü
olmadan complete sayılmaz.

---

## 32. Son Karar

CSE yalnız şantiye şefinin kullandığı, araç bakımından geniş ve kullanıcı modeli bakımından tek sahipli kişisel saha asistanıdır; şu ana döngüde ilerler:

```text
Yakala
-> İşle
-> Takip et
-> Doğrula
-> Günlüğe al
```

Çalışma düzeni ise:

```text
Kullanıcı intent/devam verir
-> ChatGPT GitHub durumunu kontrol eder
-> Codex gerekip gerekmediğine karar verir
-> gerekiyorsa “Codex çalışmalı” der
-> tek toplu Codex çalışması
-> GitHub review ve Draft PR
-> gerekirse tek engelleyici düzeltme
-> squash merge
-> post-merge sync güvenliyse sonraki gerekli Codex çalışmasına eklenir
```

Bu belge, ürün yönü, veri ilkeleri, Tek Hafıza ve kayıt kapsamı, modül yol
haritası, kaynak otoritesi ve ChatGPT/Codex/GitHub çalışma düzenini tek çatı
altında birleştiren ana proje kaynağıdır.

---

## Tracked GitHub Bootstrap Addendum

Yeni ChatGPT sohbetleri CHIEF SITE ENGINEER projesine GitHub uzerinden devam eder. ZIP, handoff package, source ZIP veya uzun prompt kopyalama normal continuation icin gerekli degildir.

GitHub-native new-chat bootstrap kurali icin tracked kaynak:

```text
docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md
```

Operasyonel Git/GitHub/Codex execution kurallari icin tracked kaynak:

```text
docs/protocols/CSE_PROJECT_INSTRUCTIONS.md
```

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
