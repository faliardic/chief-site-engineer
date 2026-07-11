# CHIEF SITE ENGINEER exe - Birleştirilmiş Proje Kaynağı

**Belge türü:** Birleştirilmiş ana proje kaynağı
**Sürüm tarihi:** 2026-07-11
**Durum:** Proje kaynaklarına eklenmeye hazır önerilen kanonik üst kaynak
**Önerilen dosya adı:** `CSE_BIRLESTIRILMIS_PROJE_KAYNAGI.md`
**Önerilen repo yolu:** `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`

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
8. Bu sohbet içinde kesinleştirilen Step 206, Step 207, Step 208 ve Step 209 kararları
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

CHIEF SITE ENGINEER, aktif şantiye şeflerinin ve saha mühendislerinin WhatsApp, telefon galerisi, Excel, klasörler, defterler, e-postalar ve kişisel hafıza arasında dağılan saha bilgisini tek, güvenilir ve aranabilir bir şantiye hafızasına dönüştürmeyi amaçlayan saha odaklı bir sistemdir.

Sistemin temel görevi şunları kolaylaştırmaktır:

- Sahada hızlı kayıt açmak
- Fotoğraf ve dosyaları kayıtlarla ilişkilendirmek
- Açık işleri takip etmek
- Kimin bilgilendirildiğini kaydetmek
- Kanıt zincirini korumak
- Günlük ve haftalık rapor üretmek
- Resmî kayıt ile kişisel çalışma hafızasını ayırmak
- Proje devrini güvenilir hâle getirmek
- İleride AI destekli arama ve soru-cevap için temiz veri üretmek

### Ana karar cümlesi

> CSE; şantiye şefinin sahada gördüğü, fotoğrafladığı, not aldığı, bildirdiği, takip ettiği ve kapattığı işleri güvenilir biçimde kayıt altına alan; resmî kayıt ile kişisel alanı ayıran; önce veri omurgasını, sonra saha kullanımını, ardından otomasyon ve AI katmanını geliştiren sade bir şantiye hafızasıdır.

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

- 20-30 saniyede kayıt
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
8. Özel alan verileri kullanıcıya aittir ve proje devrinde otomatik olarak yeni şantiye şefine aktarılmaz.
9. Yeni şantiye şefinin özel alanı sıfırdan açılır.
10. Eski şantiye şefinin özel alanına erişim rol değişikliğiyle devredilmez.
11. Devir için gerekli bilgi özel alanda bırakılmaz; resmî kayda veya açıkça seçilmiş handover package içine dönüştürülür.
12. `requires_human_review` yalnız insan inceleme sinyalidir.
13. Sistem kendiliğinden `blocked` üretmez.
14. Otomatik kabul, ret, onay, resmî karar veya paket bloklama yapılmaz.
15. Hard validation, migration, persistence, audit, backup/restore, API, GUI ve CLI ayrı ve açık görev gerektirir.
16. Offline, backup, restore, audit ve encryption gibi yüksek riskli alanlar önce belgelenir, sonra kontrollü uygulanır.
17. Saha için ağır ve kullanılmayan formlar yerine hızlı kayıt, güvenilir arşiv ve kanıt zinciri önceliklidir.

### Tasarım ilkesi ile uygulanmış özellik ayrımı

Bir ilkenin belgede bulunması, o davranışın mevcut kodda tam uygulanmış olduğu anlamına gelmez. Özellikle audit, persistence, yetkilendirme, encryption ve silmeme politikaları önce tasarım sözleşmesi olarak tutulabilir; uygulama durumu ayrıca doğrulanmalıdır.

---

## 5. Hedef Kullanıcılar

İlk hedef kullanıcı grupları:

- Şantiye şefleri
- Saha mühendisleri
- Kontrol mühendisleri
- Yapı denetim ve saha kontrol ekipleri
- Küçük ve orta ölçekli müteahhitler
- Kendi kayıt düzenini kurmak isteyen mühendisler

İlk ürün, herkes için değil; aktif sahada çalışan ve kayıt/fotoğraf/takip karmaşası yaşayan mühendis için tasarlanır.

---

## 6. Saha Kullanım İlkesi

İlk saha kaydının açılması hedef olarak 20-30 saniyeyi geçmemelidir.

İlk kayıt mümkün olduğunca kısa tutulur:

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

İlk gerçek saha MVP’si şu yedi çekirdeğe odaklanır:

1. Hızlı saha gözlem kaydı
2. Fotoğraf/dosya eki bağlama
3. Konum bilgisi
4. Açık/takipte/kapandı durum takibi
5. Kime bildirildi bilgisi
6. Günlük export
7. Haftalık özet

### İlk MVP’de öncelik verilmeyecekler

- Karmaşık dashboard
- Çok kullanıcı ve firma yönetimi
- Bulut ölçekleme
- Ağır AI özellikleri
- Büyük raporlama ekranları
- Geniş SaaS modülleri
- Tam otomatik karar mekanizmaları

Bu özellikler, çekirdek saha değeri gerçek kullanımda kanıtlandıktan sonra ele alınır.

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
- Tek platform hedefi başlangıç değil, uzun vadeli sonuçtur.
- AI değeri ancak birleşik ve güvenilir veriden doğar.
- Kurumsal güven; veri sahipliği, yetki, revizyon ve audit disiplininden doğar.

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

### Katman 4 - Şantiye Şefi Özel Alanı

- Kişisel notlar
- Hatırlatıcılar
- Kişi ve telefon rehberi
- Günlük kişisel gözlem
- Tecrübe bankası
- Karar ve ders arşivi
- Kişisel checklistler
- Hızlı saha cep defteri
- Kişisel risk/takip panosu

### Katman 5 - Yapı Denetim ve EBİS/YDS

- Yapı denetim kontrol takip defteri
- Kontrol çağrıları
- Denetçi ve kişi kartları
- Beton döküm kayıtları
- EBİS ve numune zinciri
- İrsaliye ve deney sonuçları
- Donatı/kalıp/beton checklistleri
- Numune sonuç kapanışı
- Uygunsuzluk ve kanıt ilişkileri

### Katman 6 - Arayüz ve offline

- Responsive web arayüz
- PWA
- Offline read cache
- Kontrollü offline kayıt ve senkronizasyon

### Katman 7 - Organizasyon ve ürünleşme

- Çoklu proje
- Kullanıcı ve rol sistemi
- Firma bazlı veri ayrımı
- Audit log sertleştirme
- Kurumsal raporlama
- SaaS hazırlığı

### Katman 8 - Arama, analitik ve AI

- Akıllı arama
- Otomatik rapor özeti
- Risk erken uyarı
- AI destekli soru-cevap

---

## 10. Şantiye Şefi Özel Alanı

Özel alan, resmî proje kaydı değildir. Kullanıcının kişisel notlarını, tecrübelerini, telefon rehberini, hatırlatıcılarını ve karar derslerini saklar.

### Kayıt sınıfları

1. Tamamen özel not
2. Projeye bağlı ama özel not
3. Kullanıcı tarafından resmî kayda dönüştürülmüş not

### Gizlilik kuralları

- Varsayılan olarak yalnız ilgili kullanıcı görür.
- Firma yöneticisi otomatik erişemez.
- Proje devrinde otomatik aktarılmaz.
- Resmî devir için gereken bilgi kullanıcı tarafından açıkça resmî kayda dönüştürülür.
- Özel alan ile resmî kayıt arasında otomatik ve görünmez aktarım yapılmaz.

### V1 işlevleri

- Kişisel not ekleme ve listeleme
- Kategori ve öncelik
- Hatırlatıcı tarihi
- Kişi kartı
- Telefon ve iletişim bilgisi
- Notu kişiye bağlama
- Günlük hatırlatıcı görünümü

### V1 kapsam dışı

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

### Resmî kayda dönüşüm örnekleri

- Kişisel not -> Görev
- Kişisel not -> Günlük kayıt
- Kişisel not -> Uygunsuzluk
- Kişisel ders -> Checklist maddesi
- Hatırlatıcı -> Beton/EBİS kaydı
- Kişi kartı -> Kontrol çağrısı

Dönüşüm açık kullanıcı işlemi olmalıdır.

---

## 11. Modül Yol Haritasının Güncel Yorumu

Eski yol haritalarındaki 001-034 modül listesi uzun vadeli backlog olarak korunur; ancak bu sıra artık bağlayıcı uygulama sırası değildir.

### Güncel öncelik sırası

#### Faz A - Mevcut veri omurgasının kapatılması

- Domain model ve sözleşmeler
- Attachment ve export sözleşmeleri
- Diagnostic/report/handover sınırları
- Repository truth ve çalışma protokolü

#### Faz B - İlk saha MVP’si

- Hızlı gözlem
- Gerçek attachment akışı
- Konum
- Durum
- Bildirilen kişi
- Günlük export
- Haftalık özet

#### Faz C - Persistence ve kullanılabilir ilk uygulama

- Basit ve güvenilir persistence
- Gerçek dosya yükleme/saklama
- Minimum uygulama arayüzü
- Yerel veya kontrollü saha testi

#### Faz D - Temel saha modülleri

- Günlük defter
- Fotoğraf arşivi
- Çizim/revizyon
- Issue/punch
- QC ve İSG

#### Faz E - Özel alan ve yapı denetim/EBİS

- Özel çalışma alanı
- Yapı denetim kontrol zinciri
- Beton/EBİS/numune

#### Faz F - Offline, çoklu proje ve ürünleşme

- PWA/offline
- Yetki
- Firma ayrımı
- Audit sertleştirme
- SaaS değerlendirmesi

#### Faz G - AI

- Arama
- Özet
- Soru-cevap
- Risk sinyalleri

### Eski modül numaraları

Eski modül numaraları arşiv referansı olarak kullanılabilir; yeni teknik adımların numarasıyla karıştırılmamalıdır. Teknik Step numaraları Git/GitHub geliştirme geçmişini, modül numaraları ise ürün backlog’unu temsil eder.

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
- Auth/role/tenant katmanı
- Audit ve backup/restore
- Search/AI katmanı

### Güncel gerçeklik

Proje şu anda tam saha uygulaması değildir. Güçlü tarafı testli domain/veri/dokümantasyon omurgasıdır.

Henüz eksik veya tam üretim seviyesinde olmayan başlıca alanlar:

- Persistence/database
- Gerçek dosya yükleme
- API
- GUI/PWA
- Authentication/authorization
- Deployment
- Tam backup/restore
- Gerçek offline senkronizasyon

Bu nedenle “field-ready” veya “production-ready” iddiası yapılmaz.

---

## 13. Öğrenme Sistemi

CSE yalnız ürün değil, aynı zamanda uygulamalı öğrenme sistemidir.

Öğrenme eksenleri:

- Python ve yazılım geliştirme
- Şantiye şefliği ve saha yönetimi
- Yapı denetim/EBİS/YDS
- Git/GitHub/Codex çalışma disiplini

### Öğrenme dosyası ilkesi

Her teknik adımda her kategori için zorunlu dosya üretilmez. İlgili olduğunda uygun öğrenme dosyası oluşturulur.

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

Bu belge proje kaynaklarına eklenip onaylandıktan sonra önerilen öncelik sırası:

1. Bu birleştirilmiş ana proje kaynağı
2. Tracked kanonik proje talimatı: `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
3. Güncel GitHub Issue ve yerel `.cse/tasks/<step>_task.md`
4. `.cse/state/project_state.json`
5. İlgili `.cse/results/<step>_result.md`
6. `ROADMAP.md`, `docs/project_decisions.md`, `CHANGELOG.md`
7. `CSE_STRATEGIC_PRODUCT_DIRECTION.md`
8. Güvenilir veri omurgası ilkeleri
9. `chat_handoff/` özetleri
10. Eski PDF, ZIP ve adım talimatları

### Yerel ayna

Kök dizindeki `CSE_GUNCEL_PROJE_TALIMATLARI.md` yalnız yerel kolaylık aynasıdır. Tracked kanonik dosyadan daha yüksek önceliğe sahip değildir.

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
.cse/tasks/NNN_task.md
.cse/results/NNN_result.md
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

1. Kişisel saha kullanımı
2. Gerçek şantiye verisiyle test
3. Çekirdek özellikleri sadeleştirme
4. Kullanım sürtünmelerini azaltma
5. Kapalı kullanıcı testi
6. Küçük ekip kullanımı
7. Ürünleşme/yayın değerlendirmesi

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

### Son doğrulanmış merged GitHub noktası

- Step: **208**
- PR: **#33**
- Issue: **#32**
- Merge commit:

```text
335fb83c989f3fbf1057d88ebe02045174efcdc9
```

- Son doğrulanan test seviyesi: **413 passed**
- GitHub Actions: manuel olarak devre dışı
- Podcast 031: Steps 201-205 tamamlandı

### Yerel senkronizasyon durumu

Step 209 baslangicinda resmî `V:` yerel master `335fb83c989f3fbf1057d88ebe02045174efcdc9` commit'ine fast-forward edildi ve `master...origin/master` divergence `0 0` olarak dogrulandi.

### Aktif iş

- Step: **209**
- Issue: **#34**
- Amaç: ilk Field MVP icin minimal `FieldObservationRecord` dataclass ve focused value/default testlerini eklemek
- Branch:

```text
step-209-field-observation-record-model
```

- Bu adim narrow model/test isidir.
- Field-MVP implementation yalniz minimal `FieldObservationRecord` dataclass ve focused test kapsaminda baslamistir.
- Attachment linking, repository/persistence, export/reporting, API/GUI/CLI, audit ve validation henuz uygulanmamistir.

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

Step 203, 204, 205, 206, 207 ve aktif Step 208 bilgisi taşıyan kaynaklar tarihsel duruma düşmüştür. Güncel merged safe point Step 208’dir; Step 209 aktif unmerged model/test aşamasındadır.

### 29.8 Eski modül sırasının bağlayıcı olması

001-034 modül listesi uzun vadeli backlog referansıdır. İlk saha MVP yönü daha yüksek önceliklidir.

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

Operasyonel protokol ve kaynak birleşimi kapatıldıktan sonra ürün geliştirme yönü yeniden saha değerine dönmelidir.

Önerilen sonraki ürün fazı:

1. İlk saha MVP veri sözleşmesini netleştirme
2. Hızlı saha gözlem kaydı modelini mevcut domain omurgasına bağlama
3. Gerçek attachment saklama sınırını planlama
4. Minimum persistence seçimi
5. Günlük export ve haftalık özet akışını gerçek veriye bağlama
6. Saha kullanım prototipi
7. Gerçek şantiye testi

Bu faz başlamadan önce ayrı ve açık Issue ile kapsam belirlenmelidir.

---

## 32. Son Karar

CHIEF SITE ENGINEER exe projesi bundan sonra şu ana düzende ilerlemelidir:

```text
Güvenilir veri
-> hızlı saha kaydı
-> fotoğraf ve kanıt
-> takip ve kapanış
-> rapor ve devir
-> persistence ve kullanılabilir uygulama
-> offline ve organizasyon
-> arama, otomasyon ve AI
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

Bu belge, ürün yönü, veri ilkeleri, özel alan, modül yol haritası, kaynak otoritesi ve ChatGPT/Codex/GitHub çalışma düzenini tek çatı altında birleştiren ana proje kaynağıdır.

---

## Step 207 Tracked Bootstrap Addendum

Yeni ChatGPT sohbetleri CHIEF SITE ENGINEER projesine GitHub uzerinden devam eder. ZIP, handoff package, source ZIP veya uzun prompt kopyalama normal continuation icin gerekli degildir.

GitHub-native new-chat bootstrap kurali icin tracked kaynak:

```text
docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md
```

Operasyonel Git/GitHub/Codex execution kurallari icin tracked kaynak:

```text
docs/protocols/CSE_PROJECT_INSTRUCTIONS.md
```
