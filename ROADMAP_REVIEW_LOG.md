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
- Bir değerlendirme daha sonra geçersiz kalırsa eski rapor silinmez veya geriye dönük yeniden yazılmaz. Yeni rapor eski raporu açıkça `SUPERSEDED` veya `KISMEN SUPERSEDED` olarak işaret eder.
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
