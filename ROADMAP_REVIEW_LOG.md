# CSE — Q01–Q26 Yol Haritası Değerlendirme Günlüğü

**Belge türü:** Dönemsel roadmap değerlendirme ve toplantı hafızası  
**Kapsam:** `ROADMAP.md` içindeki ilk genel yayın öncesi Q01–Q26 kuyruğu  
**Yürütme otoritesi:** `ROADMAP.md`  
**Durum / teknik gerçek otoritesi:** current GitHub `master`, açık Issue/PR ve gerçekleşmiş gate kanıtları

## 1. Bu dosyanın görevi

Bu dosya Q01–Q26 yol haritasını **değerlendirmek**, dönemsel toplantı sonuçlarını korumak ve ileride yapılacak planlama tartışmalarına bağlam sağlamak için kullanılır.

Bu dosya ikinci bir roadmap değildir ve kendi başına üretim sırasını değiştirmez.

- `ROADMAP.md`: hangi işin hangi sırada yürütüleceğinin kanonik kaynağıdır.
- `ROADMAP_REVIEW_LOG.md`: neden o sıranın mantıklı veya tartışmalı görüldüğünü, hangi risklerin/kararların öne çıktığını ve önceki toplantılarda ne değerlendirildiğini tutar.
- current GitHub: bir işin gerçekten açık, merge edilmiş, PASS/FAIL/PENDING veya bloke olup olmadığının kaynağıdır.
- `docs/project_decisions.md`: kalıcı teknik/ürün kararları içindir; dönemsel değerlendirme raporlarının yerine kullanılmaz.

## 2. ChatGPT kullanım kuralı

Fatih aşağıdaki türde bir talep verdiğinde ChatGPT bu dosyayı da zorunlu bağlam olarak okur:

- `Q'ları değerlendirelim`
- `önümüzdeki işleri değerlendirelim`
- `roadmap toplantısı yapalım`
- `sıradaki işlerin mantığını değerlendir`
- `yayından önceki işleri yeniden gözden geçir`
- `öncelikleri tekrar değerlendirelim`
- eşdeğer reprioritization / roadmap-review talepleri

Bu durumda değerlendirme sırası:

1. current GitHub `master` + açık Issue/PR/gate durumu;
2. güncel `AGENTS.md`;
3. güncel `ROADMAP.md` Q01–Q26 kuyruğu;
4. bu dosyadaki en yeni ve ilgili değerlendirme raporları;
5. gerekiyorsa V2 Scope, Unified Source ve ilgili Issue/PR kaynakları.

Normal `devam` veya execution talebinde bu dosyadaki öneriler ROADMAP sırasını override etmez.

## 3. Değerlendirme raporu kuralları

Her roadmap toplantısı veya owner tarafından kaydedilmesi istenen değerlendirme ayrı kronolojik kayıt olarak bu dosyanın sonuna eklenir.

Her rapor mümkün olduğunca şunları içerir:

- tarih;
- toplantının amacı;
- değerlendirilen Q maddeleri;
- toplantı anındaki current GitHub gerçeğinin kısa özeti;
- her Q için ürün değeri / release değeri;
- bağımlılık ve teknik risk;
- tahmini kapsam büyüklüğü: `küçük / orta / büyük / kritik`;
- yayın öncesi zorunluluk değerlendirmesi: `V1 blocker / güçlü aday / ertelenebilir / release gate`;
- önerilen sıra veya grup;
- Fatih'in verdiği owner kararları;
- açık sorular;
- ROADMAP truth-sync gerekip gerekmediği.

## 4. Otorite ve supersession kuralı

- Değerlendirme raporları tavsiye ve karar bağlamıdır; tek başına production authority değildir.
- Fatih toplantıda mevcut sırayı değiştirirse, yeni production iş başlamadan önce kabul edilen karar `ROADMAP.md` dosyasına truth-sync edilir.
- Kalıcı ürün kapsamı değişirse gerektiğinde `docs/v2/CSE_V2_SCOPE.md` veya ilgili kalıcı karar kaynağı da güncellenir.
- Bir değerlendirme daha sonra geçersiz kalırsa eski rapor silinmez veya geriye dönük yeniden yazılmaz. Yeni rapor eski raporu açıkça `SUPERSEDED` veya `KISMEN SUPERSEDED` olarak işaretler.
- Eski rapordaki SHA, Issue/PR veya durum bilgisi güncel gerçek sayılmaz; her yeni toplantıda current GitHub yeniden doğrulanır.
- ChatGPT geçmiş raporlardaki gerekçeleri kullanabilir fakat güncel olmayan durum bilgisini kopyalayamaz.

## 5. Değerlendirme bakış açısı

Q maddeleri değerlendirilirken yalnız “özellik güzel mi?” sorusu sorulmaz. En az şu açılardan düşünülür:

1. **Saha değeri:** Şantiye şefinin gerçek günlük işini ne kadar hızlandırıyor veya güvenli hale getiriyor?
2. **Yayın yeterliliği:** Bu olmadan ilk genel yayın eksik, riskli veya güven vermeyen durumda mı?
3. **Sürtünme:** Kullanıcının tekrar veri girişi, menü arama, gereksiz dokunuş veya bağlam kaybını azaltıyor mu?
4. **Veri riski:** Identity, revision, event/history, attachment, backup/restore veya user-file contract'ına dokunuyor mu?
5. **Kapsam şişmesi:** İlk sürüm için gerekli değerden daha büyük bir sistem mi açıyor?
6. **Test/gate maliyeti:** Manual/device/recovery/privacy/release gate yükü nedir?
7. **Bağımlılık:** Başka bir Q maddesinden önce/sonra yapılması teknik veya ürün açısından daha doğru mu?
8. **Erteleme maliyeti:** Post-release'e bırakılırsa gerçek kullanıcı deneyiminde ne kaybedilir?

## 6. Toplantı raporu şablonu

```markdown
## REVIEW-XXX — <başlık>

**Tarih:** YYYY-MM-DD  
**Amaç:** ...  
**Değerlendirilen Q'lar:** Qxx–Qyy / seçili maddeler

### Current GitHub gerçeği
- master: toplantı sırasında doğrulandı
- açık production Issue/PR: ...
- önemli gate/blocker: ...

### Değerlendirme

#### Qxx — <başlık>
- Saha değeri:
- Yayın öncesi önemi:
- Risk/kapsam:
- Bağımlılık:
- Öneri:

### Toplantı sonucu
- Fatih kararları:
- Öneri olarak kalanlar:
- Ertelenenler:
- Yeni araştırma gerekenler:

### ROADMAP etkisi
- `YOK` veya exact sıra/kapsam değişikliği
- Gerekliyse ROADMAP truth-sync referansı
```

## 7. REVIEW-001 — Değerlendirme sisteminin kurulması

**Tarih:** 2026-09-06  
**Amaç:** Q01–Q26 için dönemsel roadmap değerlendirmelerini tek kalıcı dosyada tutacak sistemi kurmak.  
**Değerlendirilen Q'lar:** Q01–Q26 yapısının tamamı, ancak bu kayıt yeni bir reprioritization toplantısı değildir.

### Current GitHub gerçeği

- ROADMAP Q01–Q26 ilk genel yayın öncesi kanonik yürütme kuyruğudur.
- Bu kayıt oluşturulurken açık production işi PR #715 / Q01 İSG Geçmiş-Arşiv işidir.
- Bu toplantı production sırasını değiştirmez.

### Toplantı sonucu

- Fatih, Q maddelerinin arada sırada ayrıca değerlendirilmesini ve bu değerlendirme raporlarının kalıcı olarak saklanmasını istedi.
- Gelecekte sıradaki işler için değerlendirme istendiğinde ChatGPT yalnız ROADMAP sırasına değil, bu dosyadaki güncel ve ilgili geçmiş değerlendirmelere de bakacak.
- Değerlendirme raporu ile execution authority ayrıldı: rapor öneri bağlamı; kabul edilen sıra değişikliği ROADMAP'e ayrıca işlenir.

### ROADMAP etkisi

`YOK` — Q01–Q26 sırası bu kayıtla değiştirilmedi.

## 8. REVIEW-002 — İlk genel yayın gereklilik değerlendirmesi

**Tarih:** 2026-09-06  
**Amaç:** Q01–Q26 listesini ilk genel yayın için saha değeri, veri güvenliği, kapsam şişmesi ve gerçek yayın gerekliliği açısından yeniden değerlendirmek.  
**Değerlendirilen Q'lar:** Q01–Q26.

### Current GitHub gerçeği

- Toplantı sırasında `master` ve kanonik Q01–Q26 kuyruğu yeniden doğrulandı.
- Açık production işi Q01 / Issue #708 / Draft PR #715'tir; source/test/independent review PASS, exact Acceptance manuel gate PENDING durumundadır.
- Bu rapor öneri/değerlendirme kaydıdır; mevcut production sırasını veya PR #715 gate'ini değiştirmez.

### Genel değerlendirme

İlk yayın kapsamı yeni özellik sayısını artırmak yerine CSE'nin mevcut ana sözünü güvenilir biçimde yerine getirmeye odaklanmalıdır: kayıtları hızlı yakalamak, doğru proje bağlamında tutmak, tekrar yazdırmadan takip etmek, kanıt ve dosya bağlantılarını korumak, gerektiğinde geri bulmak ve veri kaybına karşı güvenilir recovery sağlamak.

Önerilen ilke:

> İlk yayını hızlandırmak için güvenlikten veya gerekli kabulden değil, yeni özellik kapsamından kısılmalı.

Küçük görsel kusurlar ve yardımcı kolaylıklar post-release'e kalabilir. Kayıp kayıt, yanlış proje, bozuk attachment bağı, güvenilmez temel hatırlatma davranışı, geri dönülemeyen restore veya yarım kalan ana iş akışı ilk yayına taşınmamalıdır.

### Q01–Q12 değerlendirmesi

#### Q01 — İSG Geçmiş / Arşiv
- Saha değeri: Yüksek; saklanan geçmişin aktif kayıtla karışmadan geri çağrılmasını sağlar.
- Yayın öncesi önemi: Güçlü aday; mevcut dar iş zaten implementation/gate aşamasında.
- Risk/kapsam: Orta; identity/history read sınırı nedeniyle kontrollü kalmalı.
- Öneri: Mevcut dar kapsamı Acceptance PASS ile tamamla; edit/restore/backfill veya geçmiş alan rekonstrüksiyonu ekleme.

#### Q02 — KKD hızlı seçim
- Saha değeri: Yüksek günlük kullanım kolaylığı.
- Yayın öncesi önemi: Güçlü aday, ancak mevcut KKD akışı güvenilir çalışıyorsa tek başına release blocker değildir.
- Risk/kapsam: Küçük/orta.
- Öneri: Mevcut canonical KKD seçeneklerini minimum dokunuşla seçtiren dar UX iyileştirmesi; stok/zimmet/toplu dağıtım kapsamı açılmasın.

#### Q03 — Otomatik personel kodu
- Saha değeri: Sınırlı; teknik stable identity ile kullanıcı-facing personel kodu aynı ihtiyaç değildir.
- Yayın öncesi önemi: Ertelenebilir.
- Risk/kapsam: CRITICAL identity/compatibility riski.
- Öneri: `POST-RELEASE / DEFERRED` güçlü öneri.

#### Q04 — Beton tamamlanma / sonuç / detay / düzenleme
- Saha değeri: Çok yüksek; Beton modülünün gerçek iş akışını tamamlar.
- Yayın öncesi önemi: Beton ilk sürümde görünüyorsa V1 blocker.
- Risk/kapsam: Orta; existing identity/attachment davranışları korunmalı.
- Öneri: Create → result/detail → edit/completion zinciri güvenilir biçimde tamamlanmalı; yeni beton özellikleri eklenmemeli.

#### Q05 — Malzemeler ortak UI/UX uyumu
- Saha değeri: Orta/yüksek.
- Yayın öncesi önemi: İşlevsel tutarlılık gerekli; salt görsel eşleme blocker olmamalı.
- Risk/kapsam: Küçük/orta.
- Öneri: Project context, ana eylem, state/error ve erişilebilirlik sorunlarını çöz; sırf görsel birebirlik için yeni tasarım turu açma.

#### Q06 — Albüm + Dosyalar + Yedekleme + Ayarlar yerleşimi
- Saha değeri: Yüksek bulunabilirlik.
- Yayın öncesi önemi: Minimum anlaşılır yerleşim güçlü aday.
- Risk/kapsam: Orta; backup/recovery sınırında kapsam büyümesi engellenmeli.
- Öneri: Kullanıcı fotoğrafı, dosyası ve yedeğini nerede bulacağını anlamalı; tüm bilgi mimarisini yeniden kurma.

#### Q07 — Inventory release-level entegre doğrulama
- Saha değeri: Yüksek; tamamlanmış alanın regresyonunu engeller.
- Yayın öncesi önemi: Release QA gereği.
- Risk/kapsam: Yeni feature işi yok.
- Öneri: Yalnız entegre doğrulama; kanıtlanmış regresyonda dar bug child.

#### Q08 — Bildirim panelinde Ertele
- Saha değeri: Yüksek kullanım kolaylığı.
- Yayın öncesi önemi: Mevcut güvenilir erteleme yolu varsa ertelenebilir; temel reminder güvenilirliği daha önemlidir.
- Risk/kapsam: Background scheduling/persistence'e dokunursa büyür.
- Öneri: Panel kısayolunu ana reminder güvenilirliğinin önüne koyma.

#### Q09 — Puantaj tamamlanınca Ajanda kaydı
- Saha değeri: Orta; tekrar yazmayı azaltabilir.
- Yayın öncesi önemi: Ertelenebilir.
- Risk/kapsam: CRITICAL duplicate/transaction/history/rollback riski.
- Öneri: `POST-RELEASE / DEFERRED` güçlü öneri; Puantaj zaten kaynak kayıt olarak çalışmalı.

#### Q10 — Şefim otomatik yedek klasörü
- Saha değeri: Orta; kullanım kolaylığı.
- Yayın öncesi önemi: Koşullu. Güvenilir dış yedek/recovery yolu zorunlu, otomatik klasörün kendisi değil.
- Risk/kapsam: CRITICAL path/data-root/restore compatibility.
- Öneri: Mevcut yedek dışa aktarma ve recovery güvenilir ise post-release'e bırakılabilir; değilse eksik olan güvenlik yolu blocker olarak çözülmeli.

#### Q11 — Global hızlı cetvel
- Saha değeri: Faydalı yardımcı araç.
- Yayın öncesi önemi: Ertelenebilir.
- Risk/kapsam: Calibration ve global overlay/context restore nedeniyle gereksiz genişleyebilir.
- Öneri: `POST-RELEASE / DEFERRED` güçlü öneri.

#### Q12 — Metraj V1 release kapsam kararı
- Saha değeri: Uzun vadede yüksek.
- Yayın öncesi önemi: Kapsamlı katalog ilk yayın için zorunlu değil; mevcut hesapların doğruluğu zorunlu.
- Risk/kapsam: Büyük; katalog/schema/persistence zinciri açabilir.
- Öneri: Decision Gate'te **B — Post-release expansion** güçlü öneri.

### Q13–Q17 değerlendirmesi

#### Q13 — Minimum proje-geneli ortak arama
- Saha değeri: Çok yüksek; biriken saha hafızasını geri bulmayı sağlar.
- Yayın öncesi önemi: Güçlü V1 adayı.
- Risk/kapsam: Basit, supported record families ile sınırlandırılırsa orta.
- Öneri: Basit metin araması + project-safe scope + kaynak kayda geçiş; AI/OCR/enterprise index yok.

#### Q14 — Kısa guided onboarding
- Saha değeri: Yüksek ilk kullanım değeri.
- Yayın öncesi önemi: İlk kullanımın sorunsuz olması güçlü V1 gereğidir; tanıtım slaytı sayısı değil.
- Risk/kapsam: Küçük.
- Öneri: İlk proje ve ilk yararlı kayda yardım almadan ulaşılabilmeli; uzun tutorial açılmamalı.

#### Q15 — Minimum crash / ANR / fatal telemetry
- Saha değeri: Dolaylı fakat release sonrası teşhis için yüksek.
- Yayın öncesi önemi: Minimum hata görünürlüğü güçlü release adayı.
- Risk/kapsam: Privacy ve üçüncü taraf servis eklenirse büyür.
- Öneri: Kişisel saha içeriği toplamayan minimum teknik hata görünürlüğü; büyük davranış analitiği/telemetry sistemi açma.

#### Q16 — Privacy / KVKK / store declarations
- Saha değeri: Doğrudan saha akışı değil; güven ve mağaza uyumu için kritik.
- Yayın öncesi önemi: Release blocker.
- Risk/kapsam: Gerçek uygulama davranışıyla beyanların eşleşmesi gerekir.
- Öneri: Metin + gerçek permission/local-data/backup/media/telemetry davranışı birlikte doğrulansın; olmayan claim yazılmasın.

#### Q17 — Recovery / backup owner acceptance
- Saha değeri: Kritik güvenilirlik.
- Yayın öncesi önemi: Kesin release blocker.
- Risk/kapsam: CRITICAL destructive/data-integrity alanı.
- Öneri: Locked Restore Model A ve gerçek recovery yolu owner tarafından doğrulanmadan genel yayın yapılmamalı.

### Q18–Q26 değerlendirmesi

#### Q18 — Compact / medium / expanded window matrisi
- Yayın öncesi önemi: Release gate.
- Öneri: Desteklenen genişliklerde ana işlev, okunabilirlik ve taşma kontrolü; estetik mükemmellik hedefi değil. Q19 ile ortak kanıt kullanılabilir.

#### Q19 — Telefon / tablet / portrait / landscape / split-screen
- Yayın öncesi önemi: Release gate.
- Öneri: Hedef cihaz sınıflarında kritik akış ve state retention; her cihaz modelini tek tek test etme. Q18 kanıtıyla tekrar üretme.

#### Q20 — TalkBack / yüksek yazı / focus / grayscale
- Yayın öncesi önemi: Kritik akışlarda release gate.
- Öneri: Primary navigation, create/edit/save/confirm erişilebilir olmalı; kontrol yeni görsel redesign programına dönüşmemeli.

#### Q21 — Eksik evidence kapanışı
- Yayın öncesi önemi: Release gate.
- Öneri: Aynı RC üzerinde Q23/Q25 sırasında üretilen yeterli kanıt yeniden kullanılsın; sırf evidence sayısı için tekrar test/ekran görüntüsü üretilmesin.

#### Q22 — Manuel kabul borçlarının kapanışı
- Yayın öncesi önemi: Release gate.
- Öneri: Release'e dahil gerçek davranışların gerekli testleri PASS olmalı; tarihsel/superseded maddeler gerekçeli N/A veya superseded disposition alabilir.

#### Q23 — Entegre “bir şantiye şefi günü” senaryosu
- Saha değeri: Çok yüksek.
- Yayın öncesi önemi: En önemli ürün kabul kapılarından biri.
- Öneri: Dolu bir projede project context → reminder/agenda → plan → puantaj → saha rehberi/İSG/KKD → beton/malzeme → inventory/media → backup/recovery akışı tek bütün olarak sınansın; tekrar veri girişi, context drift, dead end ve sürpriz mutation kabul edilmesin.

#### Q24 — Otomatik milestone gate + analyze/build + artifact provenance
- Yayın öncesi önemi: Kesin teknik release gate.
- Öneri: Exact release candidate revision için birleşik test/analyze/build, package/signing/entrypoint ve artifact provenance doğrulanmalı; başka revision kanıtı yeterli sayılmamalı.

#### Q25 — Owner telefon + tablet Release Candidate kabulü
- Yayın öncesi önemi: Release gate.
- Öneri: Exact RC artifact telefon + tablet sınıfında kritik günlük akış ve ergonomi açısından Fatih tarafından kabul edilmeli; mümkün olduğunda Q18–Q23 kanıtları aynı adayda birleştirilmeli.

#### Q26 — Açık genel yayın kararı
- Yayın öncesi önemi: Final owner gate.
- Öneri: Bütün required gate'ler geçtikten sonra ayrıca açık owner release kararı korunmalı.

### Liste dışında özellikle korunması önerilen release riskleri

1. **Reminder güvenilirliği, notification-panel kolaylığından önce gelir.** Arka plan, ekran kapalı, uygulama yeniden açılışı ve izin reddi davranışları kullanıcıya yanlış güven vermemeli.
2. **Kayıt güvenliği yalnız backup ekranında test edilmemeli.** `Kaydedildi` sonrası restart/update/reopen sırasında doğru proje, attachment bağı ve duplicate-free davranış korunmalı.
3. **İlk kullanım owner alışkanlığıyla karıştırılmamalı.** Ürünü geliştirme sürecinden tanımayan bir şantiye şefi ilk proje ve ilk kayda yardım almadan ulaşabilmeli.
4. **Store/release uygunluğu özellik listesinden ayrıdır.** Paket, target/platform uyumluluğu, imza, mağaza beyanları ve hesap bazlı yayın koşulları Q16/Q24 çevresinde ayrıca doğrulanmalıdır.

### Toplantı sonucu

- **Fatih kararları:** Bu raporun değerlendirme günlüğüne eklenmesi onaylandı. Q maddelerinin release statüsü/sırası için henüz ayrıca owner reprioritization kararı verilmedi.
- **Güçlü post-release önerileri:** Q03 otomatik personel kodu, Q09 Puantaj→Ajanda otomasyonu, Q11 global hızlı cetvel, Q12 kapsamlı Metraj genişlemesi.
- **Koşullu post-release önerisi:** Q10 otomatik yedek klasörü; yalnız mevcut dış yedek/recovery yolu yeterliyse.
- **Dar kapsamda tutulması önerilenler:** Q02, Q05, Q06, Q08, Q13, Q14, Q15.
- **Korunması önerilen zorunlu kapılar:** Q16, Q17 ve Q18–Q26; ayrıca Q04 Beton akışının release kapsamındaysa tamamlanması.
- **Yeni araştırma gerekenler:** Store/account-specific production access koşulları, final telemetry kapsamı ve gerçek RC üzerinde reminder güvenilirliği kanıtı release aşamasında ayrıca doğrulanmalı.

### ROADMAP etkisi

`YOK` — bu rapor yalnız değerlendirme hafızasıdır. Q01–Q26 sırası veya status etiketleri bu kayıtla değiştirilmedi. Fatih daha sonra önerilerden herhangi birini owner kararı olarak kabul ederse, yeni production iş başlamadan önce ilgili değişiklik `ROADMAP.md` içine truth-sync edilmelidir.

## 9. REVIEW-003 — Hatırlatıcı geri bildirimi ve tam kuyruk yeniden sıralaması

**Tarih:** 2026-09-06  
**Amaç:** Owner'ın Hatırlatıcı kullanım geri bildirimini kanonik pre-release kuyruğa eklemek ve “Q numaraları kayabilir; her yeni kabul edilen geri bildirimde tüm liste yeniden değerlendirilsin ve baştan sıralansın” kararını uygulamak.  
**Değerlendirilen Q'lar:** Güncel pre-release kuyruğun tamamı.

### Current GitHub gerçeği

- Toplantı sırasında current `master` yeniden doğrulandı.
- Açık production işi Issue #708 / Draft PR #715 / Q01 İSG Geçmiş-Arşiv işidir.
- PR #715 source/test/independent review kanıtına sahip olmakla birlikte exact Fatih Acceptance gate'i kapanmadan Ready/merge olamaz.
- Bu nedenle reprioritization Q01'i yerinden oynatmaz; yeni production implementation Q01 kapanmadan başlamaz.

### Owner kararları

1. Q numaraları tarihsel referans uğruna sabit tutulmayacak.
2. Fatih yeni bir kullanım/ürün geri bildirimini pre-release roadmap'e aldığında ChatGPT yalnız araya `Q01.5` benzeri ara numara eklemeyecek.
3. Her seferinde bütün current Q listesi saha değeri, release değeri, bağımlılık, sürtünme, teknik risk ve kapsam şişmesi açısından yeniden değerlendirilecek.
4. Gerekirse aynı iş ailesindeki Q'lar birleştirilecek ve tüm kalan kuyruk Q01'den itibaren yeniden numaralandırılacak.
5. Eski Q numarası current gerçek olmayacak; current sıra her zaman `ROADMAP.md` üzerinden okunacak.

### Yeniden sıralama gerekçesi

- **Hatırlatıcı yeni Q02:** Başka projeye ait reminder'ların karışması bir görsel polish değil günlük doğruluk/context problemidir. Hızlı `Unutma` yakalaması da CSE'nin temel saha döngüsüdür. Shared active-project altyapısı zaten mevcut olduğundan proje profili genişletmesine teknik olarak bağımlı değildir ve daha dar çözülebilir.
- **Ana Sayfa / Proje Profili Q03:** Çok yüksek ürün değeri korunur; ancak blok/proje alanları ve olası schema/stable-ID ihtiyacı nedeniyle Hatırlatıcı'ya göre daha geniş audit/implementation zinciri açabilir.
- **Arama Q08 ve onboarding Q09 öne çekildi:** REVIEW-002'de ikisi de yüksek release değeri taşıyan dar işler olarak değerlendirilmişti. Kullanıcının biriken saha hafızasını geri bulması ve ürünü geliştirme geçmişini bilmeyen yeni kullanıcının ilk akışa ulaşması, düşük değerli yardımcı araçlardan önce gelir.
- **Bildirim panelinde `Ertele` ayrı Q olmaktan çıkarıldı:** Aynı Reminder iş ailesinde Q02/REM-06 altına taşındı. Böylece notification kolaylığı temel Reminder doğruluğundan ayrı ve daha yüksek öncelikli iş gibi davranmaz.
- **Inventory release-level doğrulama ayrı Q olmaktan çıkarıldı:** Inventory production refinement zaten tamamlanmıştır. Yeni redesign açılmadan release-QA yükümlülüğü Q21 evidence kapanışı ve Q23 entegre günlük senaryo içine taşındı.
- **Q10 Puantaj→Ajanda, Q11 backup folder, Q12 otomatik personel kodu, Q13 Metraj ve Q14 global cetvel:** Pre-release kapsamdan owner tarafından henüz çıkarılmadıkları için korunurlar; ancak daha yüksek günlük/release değerli Reminder, Proje Profili, Beton, supporting IA, arama ve onboarding sonrasına sıralanırlar.
- **Q15–Q26:** Telemetry/privacy/recovery ve entegre release gate zinciri sıralı bağımlılık olarak korunur.

### Yeni kanonik sıra özeti

1. Q01 — İSG Geçmiş / Arşiv
2. Q02 — Hatırlatıcı aktif-proje bağlamı + hızlı Unutma
3. Q03 — Ana Sayfa / Proje Profili
4. Q04 — KKD hızlı seçim
5. Q05 — Beton completion/detail/edit
6. Q06 — Malzemeler UI/UX uyumu
7. Q07 — Albüm + Dosyalar + Yedekleme + Ayarlar yerleşimi
8. Q08 — Minimum proje-geneli arama
9. Q09 — Kısa guided onboarding
10. Q10 — Puantaj → Ajanda otomatik kayıt
11. Q11 — Şefim otomatik yedek klasörü
12. Q12 — Otomatik personel kodu decision gate
13. Q13 — Metraj V1 decision gate
14. Q14 — Global hızlı cetvel
15. Q15 — Minimum crash/ANR/fatal telemetry
16. Q16 — Privacy/KVKK/store declarations
17. Q17 — Recovery/backup owner acceptance
18. Q18 — Window matrix
19. Q19 — Telefon/tablet/orientation/split-screen
20. Q20 — TalkBack/yüksek yazı/focus/grayscale
21. Q21 — Eksik evidence + Inventory release-QA
22. Q22 — Manuel kabul borçları
23. Q23 — Entegre şantiye şefi günü
24. Q24 — Automated milestone/build/provenance
25. Q25 — Owner telefon+tablet RC kabulü
26. Q26 — Açık genel yayın kararı

### REVIEW-002 ile ilişki

`REVIEW-002` **KISMEN SUPERSEDED** durumundadır: içindeki saha değeri, risk ve post-release önerileri danışma bağlamı olarak korunur; ancak o rapordaki Q numaraları ve sıra artık current değildir. Current sıra yalnız ROADMAP'in yeniden numaralandırılmış Q01–Q26 kuyruğudur.

### ROADMAP etkisi

`VAR` — `ROADMAP.md` tam liste yeniden değerlendirilerek Q01–Q26 biçiminde baştan numaralandırılır; yeni Hatırlatıcı Q02 eklenir, Proje Profili Q03 olur, notification `Ertele` Q02'ye birleştirilir, tamamlanmış Inventory release-QA ayrı sıra maddesi olmaktan çıkarılıp Q21/Q23'e taşınır ve sonraki Q'lar yeni öncelik sırasına göre yeniden numaralandırılır.

## 10. REVIEW-004 — Ajanda/Takvim geri bildirimi ve tam kuyruk yeniden sıralaması

**Tarih:** 2026-09-06  
**Amaç:** Owner'ın Ajanda — Takvim kullanım geri bildirimini pre-release kuyruğa almak, tüm current Q listesini yeniden değerlendirmek ve yeni sıralamayı kanonikleştirmek.  
**Değerlendirilen Q'lar:** Güncel pre-release kuyruğun tamamı.

### Current GitHub gerçeği

- Toplantı sırasında current `master`, `AGENTS.md`, ROADMAP ve açık production PR yeniden doğrulandı.
- Açık production işi Issue #708 / Draft PR #715 / Q01 İSG Geçmiş-Arşiv işidir.
- PR #715 exact Fatih Acceptance gate'i kapanmadan Ready/merge olamaz; yeni Ajanda implementation'ı Q01 kapanmadan başlamaz.

### Owner Ajanda kararları

- Ajanda ay görünümü yatay kaydırma gerektirmeden kullanılabilir ekran genişliğine sığacak.
- Ajanda normal görünümünde yalnız aktif proje kayıtları bulunacak; diğer projeler karışmayacak.
- `Yeni Proje` Ajanda ana ekranından kaldırılacak.
- `Mahal Kataloğu` yönetimi Ajanda'dan çıkarılıp proje profili/proje bağlamına taşınacak; Ajanda Mahal'i yalnız kayıt bağlamı olarak kullanacak.
- Kayıt bulunan günler takvimde görünür olacak.
- Owner'ın önerdiği `kayıt sayısı kadar sınırsız nokta + spiral` davranışı ürün hedefi olarak aynen alınmadı. Aynı amaç daha okunabilir biçimde `1–3 kayıt = bounded nokta`, `4+ = bounded nokta + sayı rozeti/count` ile çözülecek. 100 kayıt için 100 ayrı nokta çizilmeyecek.
- Seçili günün kayıtları Ajanda bağlamında doğrudan görünür olacak; ay boşluğu ile seçili gün boşluğu farklı empty state olarak sunulacak.

### Yeniden sıralama gerekçesi

- **Ajanda yeni Q03:** Yanlış proje kayıtlarının aynı takvimde görünmesi günlük doğruluk/context problemidir. Takvimin yatay kaydırma istemesi ve proje/Mahal yönetim eylemlerinin Ajanda içinde kalması sık kullanılan akışta doğrudan sürtünme üretir. Bu iş shared active-project altyapısını kullanabilir ve Proje Profili'nin daha geniş schema/model audit'ine bağımlı değildir.
- **Proje Profili Q04'e kaydı:** Ürün değeri çok yüksek kalır, ancak blok/proje alanları ve olası persistence/stable-ID gereksinimi nedeniyle Ajanda takvim sadeleştirmesinden daha geniştir.
- **KKD ve sonraki feature Q'ları birer sıra kaydı:** Yeni günlük-core Ajanda işi bunların önüne alınmıştır.
- **Eski Q18 + Q19 adaptive gate'leri birleştirildi:** Compact/medium/expanded ve telefon/tablet/orientation/split-screen aynı RC, breakpoint ve state-retention doğrulama ailesidir. Ayrı Q tutmak tekrar kanıt üretme riskini artırıyordu. Yeni tek `Adaptive cihaz / pencere matrisi` release gate'i bunları birlikte taşır.
- Bu birleşme sayesinde yeni Ajanda Q'su eklenmesine rağmen kanonik kuyruk Q01–Q26 olarak kalır; sayı 26'da tutulduğu için değil, iki eski gate gerçekten aynı doğrulama ailesi olduğu için birleştirilmiştir.

### Yeni kanonik sıra özeti

1. Q01 — İSG Geçmiş / Arşiv
2. Q02 — Hatırlatıcı aktif-proje bağlamı + hızlı Unutma
3. Q03 — Ajanda takvimi aktif-proje ve okunabilir ay görünümü
4. Q04 — Ana Sayfa / Proje Profili
5. Q05 — KKD hızlı seçim
6. Q06 — Beton completion/detail/edit
7. Q07 — Malzemeler UI/UX uyumu
8. Q08 — Albüm + Dosyalar + Yedekleme + Ayarlar yerleşimi
9. Q09 — Minimum proje-geneli arama
10. Q10 — Kısa guided onboarding
11. Q11 — Puantaj → Ajanda otomatik kayıt
12. Q12 — Şefim otomatik yedek klasörü
13. Q13 — Otomatik personel kodu decision gate
14. Q14 — Metraj V1 decision gate
15. Q15 — Global hızlı cetvel
16. Q16 — Minimum crash/ANR/fatal telemetry
17. Q17 — Privacy/KVKK/store declarations
18. Q18 — Recovery/backup owner acceptance
19. Q19 — Adaptive cihaz/pencere matrisi
20. Q20 — TalkBack/yüksek yazı/focus/grayscale
21. Q21 — Eksik evidence + Inventory release-QA
22. Q22 — Manuel kabul borçları
23. Q23 — Entegre şantiye şefi günü
24. Q24 — Automated milestone/build/provenance
25. Q25 — Owner telefon+tablet RC kabulü
26. Q26 — Açık genel yayın kararı

### Önceki değerlendirmelerle ilişki

`REVIEW-002` ve `REVIEW-003` içindeki saha değeri/risk gerekçeleri danışma bağlamı olarak korunur. `REVIEW-003` **KISMEN SUPERSEDED** durumundadır: Q02 Hatırlatıcı gerekçesi korunur; Q03 ve sonrası numara/sıra current değildir. Current sıra yalnız ROADMAP'deki Q01–Q26 listesidir.

### ROADMAP etkisi

`VAR` — Ajanda/Takvim Q03 olarak eklendi; Proje Profili ve sonraki Q'lar yeniden numaralandırıldı; eski iki adaptive/device release gate tek Q19 altında birleştirildi; ilgili cross-reference'lar yeni numaralara taşındı.

## 11. REVIEW-005 — Ajanda kayıt oluşturma akışı ve Q03 kapsam genişletmesi

**Tarih:** 2026-09-06  
**Amaç:** Owner'ın Ajanda Kaydı Oluşturma kullanım geri bildirimini değerlendirmek, mevcut runtime sözleşmeleriyle karşılaştırmak ve pre-release roadmap'te doğru iş ailesine yerleştirmek.  
**Değerlendirilen Q'lar:** Güncel Q01–Q26 kuyruğunun tamamı; ayrıntılı kapsam Q03.

### Current GitHub gerçeği

- Toplantı sırasında current `master`, `AGENTS.md`, ROADMAP, `ROADMAP_REVIEW_LOG.md` ve açık production PR yeniden doğrulandı.
- Açık production işi Issue #708 / Draft PR #715 / Q01 İSG Geçmiş-Arşiv işidir; Q01 kapanmadan yeni production child başlamaz.
- Ajanda form source audit'inde mevcut create/edit formunda `Proje` dropdown'u, `Yeni proje oluştur`, ayrı `Zaman ve tür` ExpansionTile, `İsteğe bağlı ayrıntılar`, `Ayrıntılı not`, stable Mahal seçimi ve küçük fotoğraf aksiyonu bulundu.
- Tarih/saat new-record init'inde zaten Europe/Istanbul current zamanından türetiliyor; takvimden gelen `initialIstanbulDay` mevcutsa seçilen gün korunuyor.
- `AgendaCategory` kapalı storage enum'udur ve Beton sinyali/yönlendirmesi dahil downstream anlam taşır; bu nedenle yalnız UI sadeleştirmesi gerekçesiyle silinmemelidir.
- Mahal için stable `locationId` zaten opsiyoneldir; bu, proje-geneli Ajanda kaydını koruyarak proje seçicisinin yerine Mahal'i kullanıcı-facing ana bağlam kontrolü yapmaya uygundur.

### Owner kararları ve ürün değerlendirmesi

1. Ayrı `Zaman ve tür` bölümü kaldırılır; tarih ve saat `Kısa açıklama`nın hemen üstünde açık ikon+değer kontrolleri olur.
2. Normal varsayılan current İstanbul tarih/saatidir; kullanıcı takvimde başka bir gün seçip create başlattıysa seçilmiş gün yeniden sorulmaz, yalnız saat current değerle başlar.
3. Proje dropdown'u ve form içindeki `Yeni proje oluştur` kaldırılır. Aktif proje salt-okunur context olur; edit formu source kaydı sessizce başka projeye reassign etmez.
4. Proje seçicisinin kullanıcı-facing yerini **Mahal seç** alır. Mahal stable-ID tabanlı, yalnız aktif proje kapsamlı ve opsiyonel kalır; proje-geneli kayıt geçerlidir.
5. `İsteğe bağlı ayrıntılar` ve yeni kayıt için `Ayrıntılı not` alanı kaldırılır. Tek ana metin alanı multiline `Kısa açıklama` olur.
6. Existing legacy `notes` verisi bu UI değişikliğiyle silinmez, migration yapılmaz veya edit-save sırasında sessizce boşaltılmaz.
7. `Kayıt türü` ayrı form bölümü olmaktan çıkar ancak mevcut `AgendaCategory` semantiği korunur. Default `Genel not`; değiştirme gerektiğinde kompakt ikincil kontrol kullanılır. Common-case kullanıcı tür seçmeye zorlanmaz.
8. Fotoğraf ekleme küçük ikon olmaktan çıkar; büyük belirgin kutu/panel, Kamera/Sistem seçici akışı ve altında bounded thumbnail/önizlemeler kullanılır. Çoklu fotoğraf ve draft güvenliği korunur.
9. Nihai hızlı form hiyerarşisi: `Aktif proje → Tarih/Saat → Kısa açıklama → Mahal → Fotoğraf → Tür (ikincil) → Kaydet`.
10. Existing Back/unsaved-change guard ve attachment integrity korunur; yeni kayıt fotoğraf UX'i mevcut kayıt attachment yaşam döngüsünü sessizce genişletmez.

### Tam kuyruk yeniden değerlendirmesi

Standing owner kuralı gereği Q01–Q26'nın tamamı yeniden değerlendirildi. Bu geri bildirim için **Q-level yeni sıra değişikliği gerekmiyor**:

- Ajanda kayıt oluşturma, mevcut Q03 Takvim işinden bağımsız bir ürün ailesi değildir; kullanıcı aynı `Ajanda → gün → + kayıt` yolculuğunda iki davranışı birlikte yaşar.
- Ayrı Q açmak aynı ekran/feature ailesinde gereksiz ikinci implementation ve acceptance zinciri üretirdi.
- Q03 hâlihazırda Hatırlatıcı Q02'den sonra ve daha geniş Proje Profili Q04'ten önce doğru konumdadır.
- Q11 Puantaj→Ajanda otomatik kayıt ise mutation/duplicate/transaction/history nedeniyle ayrı CRITICAL iş olarak kalmalıdır; create-form UX ile birleştirilmez.
- Q04–Q26'nın göreli önem/bağımlılık sırasını değiştirecek yeni bir neden oluşmadı.

### Önceki değerlendirmelerle ilişki

`REVIEW-004` sıralama bakımından **CURRENT** kalır; Q01–Q26 numaraları değişmez. Ancak REVIEW-004'teki Q03 kapsamı bu raporla **GENİŞLETİLMİŞTİR**: Q03 artık yalnız takvim görünümü değil, aynı zamanda hızlı Ajanda kayıt oluşturma akışını da kapsar.

### ROADMAP etkisi

`VAR — SIRA DEĞİŞMEDİ` — Q03 başlığı `Ajanda aktif-proje takvimi + hızlı kayıt oluşturma` olarak genişletildi; CAL-01..06 korunup FORM-01..07 eklendi; Q03 bitiş tanımı capture UX, legacy-note preservation, category semantics ve photo-priority sınırlarıyla genişletildi. Q01–Q26 numaraları ve Q-level öncelik sırası değişmedi.

## 12. REVIEW-006 — Envanter/Kroki owner geri bildirimi ve tam kuyruk yeniden sıralaması

**Tarih:** 2026-09-06  
**Amaç:** Owner'ın Envanter / Kroki kullanım geri bildirimini current Inventory contract ve source ile karşılaştırmak, gerekli dar refinement kapsamını tanımlamak ve tüm pre-release kuyruğu yeniden sıralamak.  
**Değerlendirilen Q'lar:** Güncel Q01–Q26 kuyruğunun tamamı; ayrıntılı kapsam yeni Q05.

### Current GitHub gerçeği

- Toplantı sırasında current `master`, `AGENTS.md`, ROADMAP, `ROADMAP_REVIEW_LOG.md`, Inventory contract ve current Kroki source yeniden doğrulandı.
- Açık production işi Issue #708 / Draft PR #715 / Q01 İSG Geçmiş-Arşiv işidir; Q01 exact Fatih Acceptance kapanmadan yeni production child başlamaz.
- #709–#714 Inventory compact top tools + movement-wheel refinement zinciri tamamlanmış baseline'dır; bu owner geri bildirimi onun tamamını geçersiz saymaz.
- Current editor toolbar'da `Geri`, `Taşı`, `Çizgiyi bitir`, `Alanı kapat`, `Serbest uzunluk`, zoom `+/-` ve `Tamamını göster` kontrolleri gerçekten mevcuttur.
- Current one-finger pan davranışı `PAN/Taşı` moduna bağlıdır; kontrat iki-parmak pan/pinch'in her modda güvenli navigation olabilmesine izin verir. Bu nedenle `Taşı` butonunu alternatifsiz silmek doğru değildir.
- Current contract open polyline için `Çizgiyi bitir` ve block closure için explicit `Alanı kapat` davranışını tanımlar. Owner'ın permanent toolbox sadeleştirme kararı production source'tan önce contract truth-sync gerektirir.
- Movement wheel yalnız SELECT + selection halinde görünür; controller nudge, seçili polygonun stable block'a map edilmesini ister. Bu nedenle ilk kroki oluşturma desteği tamamlanmış yeni/closed block için hedeflenmeli, unfinished raw polyline için değil.
- Source'ta draw mode finalize/finish sonrası otomatik başka moda çevriliyor görünmemektedir; sticky-draw owner bulgusu önce gerçek runtime'da reproduce edilmelidir.
- Map projection aynı/çok yakın marker'ları zaten count-cluster olarak gruplayabilir. Farklı asset'lerin aynı `x/y` koordinatını paylaşmasını yasaklayan source-of-truth constraint bulunmadı; V1 kısıtı bir **asset başına** tek aktif placement'tır.
- Current create engelinin ana adayı `captureEmptyMapTap()` içindeki marker-hit guard'dır: marker'a denk gelen tap create'i reddeder. Bu nedenle same-point ihtiyacı için varsayılan çözüm schema migration değil explicit marker/cluster add-another UX'idir.

### Owner kararları ve ürün değerlendirmesi

1. `Geri` toolbox'tan çıkar ve üstte belirgin navigation action olur; autosave/back/orientation güvenliği korunur.
2. `Taşı` toolbar kontrolü kaldırılabilir, ancak yalnız draw/select sırasında güvenli iki-parmak pan/pinch kanıtlandıktan sonra. Navigation capability kaybolamaz.
3. Zoom `+/-` ve `Tamamını göster` ana toolbox'tan çıkarılır; pinch zoom ve initial fit korunur. Viewport recovery gerekiyorsa ikincil, çakışmayan action/gesture kullanılabilir.
4. Permanent `Çizgiyi bitir` ve `Alanı kapat` toolbox kontrolleri kaldırılır; capability tamamen silinmez. Valid polygon için snap-to-first ana closure yolu olur; open-polyline bitirme gerektiğinde contextual explicit eylem kalır.
5. `Serbest uzunluk` ruler/measurement çağrışımlı ikonundan çıkar; yalnız sonraki kenarın smart-length alignment'ını serbest bırakan one-shot semantiğe uygun icon kullanılır.
6. Movement wheel ilk `createOrRecover` akışında tamamlanmış/closed yeni blok seçildiğinde de çalışır; raw unfinished polyline için sahte blok hareketi yoktur.
7. Draw/`Çiz` modu explicit mode switch'e kadar sticky kalır. Source zaten böyleyse production rewrite yapılmaz; owner runtime bulgusu reproduce edilip gerçek reset noktası varsa dar fix yapılır.
8. Farklı Inventory asset kayıtları aynı exact floor + `x/y` koordinatını paylaşabilir. Marker/cluster yüzeyi `Bu noktaya kayıt ekle` eylemi verir; exact coordinate ve floor quick-create'e taşınır.
9. Same-point kayıtlar source coordinate'leri yapay offset ile değiştirilmeden count/stack cluster olarak sunulur ve deterministik listeden ayrı detail'lere açılır.
10. Schema değişikliği varsayılan çözüm değildir. Audit gerçek schema/persistence ihtiyacı kanıtlarsa Q05 STANDARD UI kapsamı büyütülmez; ayrı CRITICAL child gerekir.

### Tam kuyruk yeniden değerlendirmesi

Standing owner kuralı gereği bütün current sıra yeniden değerlendirildi:

- Yeni dar Inventory/Kroki refinement, Proje Profili'nden sonra **Q05** olarak yerleştirildi. Ürün çekirdeği ve günlük saha kullanımındaki doğrudan etkisi KKD/Beton sonrası yardımcı polish işlerinden daha yüksek; ancak mevcut geniş Proje Profili kararıyla block/Mahal/İş Gücü bağlamı önce korunur.
- Önceki Q05 ve sonrası feature/decision maddeleri bir sıra kaydırıldı.
- Listeyi sırf 26'da tutmak için yapay iş silinmedi. Eski `Eksik evidence + Inventory release-QA` ile `Manuel kabul borçları` aynı exact RC, evidence reuse ve acceptance-disposition ailesi olduğundan tek **Q22 — Release evidence + manuel kabul borçları + Inventory release-QA** gate'inde birleştirildi.
- Q23 entegre günlük senaryo Q05'teki same-point create/cluster ve sade Kroki interaction'ını da kapsar.
- Q01 açık production gate'i değişmedi; Q02 hâlâ NEXT'tir.

### Yeni kanonik sıra özeti

1. Q01 — İSG Geçmiş / Arşiv
2. Q02 — Hatırlatıcı aktif-proje bağlamı + hızlı Unutma
3. Q03 — Ajanda aktif-proje takvimi + hızlı kayıt oluşturma
4. Q04 — Ana Sayfa / Proje Profili
5. Q05 — Envanter / Kroki hedefli interaction refinement
6. Q06 — KKD hızlı seçim
7. Q07 — Beton completion/detail/edit
8. Q08 — Malzemeler UI/UX uyumu
9. Q09 — Albüm + Dosyalar + Yedekleme + Ayarlar yerleşimi
10. Q10 — Minimum proje-geneli arama
11. Q11 — Kısa guided onboarding
12. Q12 — Puantaj → Ajanda otomatik kayıt
13. Q13 — Şefim otomatik yedek klasörü
14. Q14 — Otomatik personel kodu decision gate
15. Q15 — Metraj V1 decision gate
16. Q16 — Global hızlı cetvel
17. Q17 — Minimum crash/ANR/fatal telemetry
18. Q18 — Privacy/KVKK/store declarations
19. Q19 — Recovery/backup owner acceptance
20. Q20 — Adaptive cihaz/pencere matrisi
21. Q21 — TalkBack/yüksek yazı/focus/grayscale
22. Q22 — Release evidence + manuel kabul borçları + Inventory release-QA
23. Q23 — Entegre şantiye şefi günü
24. Q24 — Automated milestone/build/provenance
25. Q25 — Owner telefon+tablet RC kabulü
26. Q26 — Açık genel yayın kararı

### Önceki değerlendirmelerle ilişki

`REVIEW-005` Q01–Q04 sıralaması ve Q03 kapsamı bakımından **CURRENT** kalır. Q05 ve sonrası numara/sıra kısmı bu raporla **KISMEN SUPERSEDED** durumundadır. Önceki Inventory tamamlanmış-baseline değerlendirmesi korunur; yalnız 6 Eylül owner bulgularıyla açıkça tanımlanan dar Q05 istisnası yeniden açılır.

### ROADMAP etkisi

`VAR` — owner-inserted Q05 Envanter/Kroki refinement eklendi; Q06–Q21 yeniden numaralandırıldı; eski evidence ve manual-debt release gate'leri Q22 altında birleştirildi; cross-reference'lar yeni Q numaralarına taşındı. Inventory contract'taki explicit toolbar/create yasakları source implementation'dan önce yeni owner yönüyle truth-sync edilmek zorundadır.