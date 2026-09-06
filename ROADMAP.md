# CSE V2 — Kanonik Ürün Yol Haritası

**Durum:** Güncel yürütme sırası ve ilk genel yayın öncesi tek kanonik kuyruk  
**Güncelleme:** 6 Eylül 2026  
**V2 kapsam kaynağı:** `docs/v2/CSE_V2_SCOPE.md`  
**Değişken repository gerçeği:** Güncel SHA, açık Issue/PR, merge ve gate durumu her görevde GitHub `master` üzerinden doğrulanır.

## 1. Bu dosyanın görevi

Bu `ROADMAP.md`, CSE için **güncel yürütme sırasının tek kanonik dosyasıdır**.

- Ürün kapsamının ayrıntısı `docs/v2/CSE_V2_SCOPE.md` içindedir.
- Kalıcı ürün/veri ilkeleri `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md` içindedir.
- Çalışma, test, güvenlik ve publication kuralları `AGENTS.md` ve `docs/protocols/` altındaki bağlayıcı protokollerdedir.
- **Sıradaki ürün/release işi bu dosyadaki `İlk genel yayın öncesi tek kanonik yürütme kuyruğu`ndan seçilir.**
- Aynı anda açık bir production Issue/PR varsa önce onun required gate'leri tamamlanır; sonraki queue maddesine geçilmez.
- Queue sırası ancak Fatih'in yeni owner kararıyla değişir. Sıra değişikliği production işe başlamadan önce GitHub'da bu dosyaya yansıtılır.
- Queue üzerindeki durum notları yön gösterir; gerçek `OPEN/CLOSED`, PR head, test ve Acceptance durumu her zaman current GitHub gerçeğinden okunur.
- Eski Issue/PR, sohbet özeti, handoff, ZIP veya tarihsel roadmap metni bu sırayı override edemez.

## 2. Güncel ürün durumu — kısa özet

CSE owner-only, local-first ve mobile-first kişisel saha asistanıdır. V1 sahada kullanılmış; V2'nin kimlik, attachment, Ajanda, schedule/Living Plan, Günlük Log, İş Zinciri, Malzemeler, telefon görüşmesi sonucu, Proje Albümü, recovery ve Inventory omurgaları merged temeldir.

Frictionless Release Readiness programı Issue #617 ile yürür. UI/UX sözleşmesi, adaptive shell, ortak aktif proje, 48×48 erişilebilirlik tabanı, form/primary-action standardı, temel search/filter/error state altyapısı ve visual-first dönüşümün ana dilimleri merged durumdadır.

Son Inventory refinement zinciri #709/#710 → #711/#712 → #713/#714 tamamlanmış ve owner manuel kabulünden geçmiştir. 6 Eylül owner saha kullanım geri bildirimiyle Q06 altında yalnız dar Kroki/interaction refinement istisnası yeniden açılmıştır; önceki tamamlanmış davranışlar bunun dışında tekrar geliştirme işi sayılmaz. Aynı gün İş Gücü/Sicil için current Puantaj-yardımcısı konumundan first-class günlük saha alanına geçiş ve Firma → Personel sadeleştirmesi Q05 olarak kanonik kuyruğa alınmıştır. DWG Viewer / Issue #523 ilk genel yayın için blocker değildir ve `POST-RELEASE / DEFERRED` kalır.

Değişmeyen teknik baseline değerleri ilgili source/protokol ve current master'dan okunur; bu dosya sabit master SHA tutmaz.

## 3. Tamamlanmış yayın-hazırlık temeli

Aşağıdaki alanlar yeni queue maddesi olarak tekrar açılmaz; yalnız release QA sırasında regresyon bulunursa dar bug Issue'su açılır veya aşağıda açıkça owner-inserted dar istisna tanımlanır:

- #616 sanitize full-product evidence baseline.
- #618 kanonik frictionless UI/UX sözleşmesi + V2/roadmap truth-sync.
- #617 Phase 1 adaptive/accessibility foundation.
- #617 Phase 2 ortak form/action, search/filter, loading/error/retry ve insan-okunur event dili temel işleri.
- Reminder/Unutma, Ajanda ve Living Plan günlük akış sadeleştirmelerinin mevcut merged dalgaları; Q02 ve Q03 yalnız 6 Eylül owner saha kullanımında kalan yeni sürtünme/bağlam borcunu ele alır.
- Daily Log + Work Chain targeted Acceptance evidence closure (#698).
- Saha Rehberi/Sicil temel bilgi mimarisi ve Puantaj prerequisite/quick-result sadeleştirmeleri mevcut baseline'dır. Q05 bu baseline'ı silmez; yalnız first-class İş Gücü IA'sı, Firma → Personel hızlı kayıt yolu, user-facing Ekip opsiyonelliği ve form progressive disclosure borcunu düzeltir.
- İSG model audit + 20A aktif checklist/tracking temeli.
- Inventory compact top tools + D-pad + iki sıralı sketch-editor toolbar (#709–#714) tamamlanmış baseline'dır. Q06 yalnız 6 Eylül owner kullanımında kanıtlanan toolbar/gesture, first-create movement ve same-point multi-record borcunu düzeltir; Inventory'nin geri kalanını yeniden tasarım programına dönüştürmez.

Bu tamamlanmış temel, ilerideki queue maddelerinde sessizce geri alınmaz.

## 4. İlk genel yayın öncesi tek kanonik yürütme kuyruğu

### Durum etiketleri

- `ACTIVE` — current production child; önce bunun gate'leri kapanır.
- `NEXT` — active child tamamlanınca başlanacak ilk iş.
- `QUEUED` — sırayla bekleyen pre-release işi.
- `DECISION GATE` — uygulama öncesi owner V1/post-release kararı gerekir.
- `RELEASE GATE` — yeni ürün özelliği değil, yayın yeterliliği kapısıdır.
- `FINAL OWNER GATE` — public/store release için ayrı açık owner kararı gerekir.

### Q01 — İSG Geçmiş / Arşiv ve lifecycle event görünürlüğü

**Kaynak:** #617 Phase 4 / item 20B, Issue #708, current PR #715  
**Durum:** `ACTIVE` — source/test/independent review PASS; exact Acceptance manual gate tamamlanmadan Ready/merge yok.

Bitiş tanımı:

- arşiv kayıtları aktif İSG özeti/checklist'inden ayrı;
- existing event sequence insan-okunur Türkçe görünür;
- edit/restore/backfill yok;
- exact kişi/proje isolation ve zero-mutation read davranışı korunur;
- Fatih exact Acceptance build'de PASS verir ve PR merge edilir.

### Q02 — Hatırlatıcı aktif-proje bağlamı + hızlı Unutma akışı

**Kaynak:** 6 Eylül 2026 owner uygulama kullanım geri bildirimi — `Hatırlatıcı` başlığı; #617 daily-core ilkeleri; eski notification-panel `Ertele` Q'su bu maddeye birleştirildi.  
**Durum:** `NEXT` — Q01 gate'leri kapanıp PR #715 merge edilmeden production implementation başlamaz.

Bu madde, notification kolaylığından önce Hatırlatıcı'nın doğru proje bağlamını ve birkaç saniyelik yakalama akışını güvenilir hale getirir.

#### REM-01 — Yalnız aktif projenin normal Hatırlatıcı listesi

- Ana Hatırlatıcı görünümünde başka projelerin kayıtları gösterilmez.
- Normal kullanımda ayrı `Tüm projeler` listesi tutulmaz; başka projeye bakmak için aktif proje değiştirilir.
- Yeni kayıt aktif proje bağlamında oluşturulur; kullanıcıdan aynı proje tekrar seçtirilmez.
- Mevcut legacy/global/projesiz kayıt varsa silinmez, sessizce başka projeye bağlanmaz veya erişilemez bırakılmaz; implementation audit'i güvenli ikincil erişim/disposition yolunu açıkça tanımlar.
- Aktif proje yoksa global kayıt yaratmak yerine proje seçme/oluşturma yönü gösterilir.

Bu owner kararı, Hatırlatıcı özelinde önceki mixed/global browsing yönüyle çeliştiği ölçüde onu supersede eder.

#### REM-02 — Bugün / Yarın / Sonrası kontrolünü kendini açıklayan hale getir

- Üç yuvarlak kontrol ekran kompozisyonunda sağa hizalanır.
- Üç kontrol de sürekli görünür metin etiketi taşır; yalnız ikon ezberletilmez.
- Seçili görünüm görsel state ve Semantics ile açıkça anlaşılır.
- İçerik alanında aktif görünüm başlığı ayrıca görünür olabilir.
- Mevcut `Diğer` filtresi gerçekten yarından sonraki tarihleri ifade ediyorsa kullanıcı-facing etiket `Sonrası` olur; farklı semantik varsa audit sonucu gerçek anlamı anlatan kesin etiket kullanılır.

#### REM-03 — Unutma Kutusu tam sayfa olmaktan çıkar

- `+ Unutma` ayrı tam sayfaya götürmez.
- Telefonda varsayılan çözüm küçük bottom sheet / modal hızlı-yakalama yüzeyidir.
- Klavye, safe inset, text scale ve 48×48 etkileşim alanları korunur.
- Açma/kapatma mevcut Hatırlatıcı ekranı ve filtre state'ini kaybettirmez.

#### REM-04 — Unutma formunu minimum gerekli bilgiye indir

- Tek zorunlu ana içerik: `Ne unutulmamalı?`.
- Aktif proje küçük, salt-okunur bağlam olarak görünür; proje seçicisi bulunmaz.
- Tarih varsayılan olarak bugündür; `Bugün`, `Yarın`, `Tarih seç` gibi hızlı seçimler kullanılabilir.
- Saat kullanıcıya gerektiğinde değiştirilebilir. Current scheduling modeli date-only davranışı güvenle desteklemiyorsa persistence semantiği değiştirilmez; mevcut güvenli timestamp sözleşmesi default değerle korunur.
- Kullanıcı birkaç saniyelik bir Unutma kaydı için ayrıntılı form doldurmaya zorlanmaz.

#### REM-05 — Empty state ve proje değişimi

- Örneğin `Bugün için hatırlatıcın yok.` gibi açıklayıcı empty state gösterilir ve görünür `+ Unutma` eylemi sunulur.
- Aktif proje değişince yalnız görünüm context'i değişir; source kayıtlar mutate edilmez.
- Açık taslak varsa proje değişiminde sessizce yeni projeye kaydedilmez; taslak davranışı implementation child'ında açıkça tanımlanır.

#### REM-06 — Bildirim panelinde Ertele aksiyonu aynı Reminder iş ailesinde kalır

Eski ayrı `Bildirim panelinde Ertele` Q'su bu maddeye birleştirilmiştir:

- collapsed notification sade kalır;
- expanded notification'da görünür `Ertele` action'ı bulunur;
- süre seçenekleri current reminder semantiğine göre bounded tutulur;
- UI kolaylığı uğruna background scheduling, exact-alarm, reboot veya persistence engine sessizce değiştirilmez.

Bu alt dilim background/reboot engine değişikliği gerektirirse aynı STANDARD UI işi içinde genişletilmez; ayrı CRITICAL child açılır.

**Q02 bitiş tanımı:**

- ana Hatırlatıcı listesinde yalnız aktif proje kayıtları görünür;
- proje yeniden seçtirilmeden yeni reminder/Unutma aktif projeye bağlanır;
- Bugün/Yarın/sonraki tarih kontrolü ilk bakışta anlaşılır;
- Unutma Kutusu tam sayfa yerine hızlı modal/bottom sheet olarak çalışır;
- tek zorunlu içerik hızlı metindir;
- empty state doğru eylemi sunar;
- proje değişimi kayıt mutate etmez ve açık taslağı yanlış projeye taşımaz;
- notification `Ertele` kolaylığı temel reminder güvenilirliğinin önüne geçmez;
- uygulama restart/background/permission/reboot davranışı değişiyorsa gerekli ayrı risk/gate tanımlanmadan merge edilmez.

### Q03 — Ajanda aktif-proje takvimi + hızlı kayıt oluşturma

**Kaynak:** 6 Eylül 2026 owner uygulama kullanım geri bildirimleri — `Ajanda — Takvim` ve `Ajanda Kaydı Oluşturma` başlıkları; #617 daily-core ilkeleri.  
**Durum:** `QUEUED`

Ajanda, proje yönetimi menüsü değil **aktif projenin takvim tabanlı saha zaman çizgisi ve hızlı kayıt yüzeyi** olarak çalışır. Bu Q mevcut Ajanda stable identity, `AgendaCategory`, history/event ve attachment sözleşmelerini yeniden yazmaz; takvim ile `+ Ajanda kaydı` akışını aynı günlük-core işi altında sadeleştirir.

#### CAL-01 — Takvimi ekran genişliğine sığdır

- Ay takviminin yedi gün sütunu kullanılabilir ekran genişliği içinde tamamen görünür olur; normal kullanımda yatay kaydırma gerekmez.
- Layout cihaz modeline değil kullanılabilir pencere genişliğine göre ölçeklenir.
- Tarih okunabilirliği, 48×48 etkileşim/Semantics alanları, yüksek text scale ve safe inset korunur.
- Görsel hücrenin küçülmesi gerçek dokunma alanını erişilemez hale getirmez.

#### CAL-02 — Kayıt yoğunluğunu bounded göstergelerle göster

- Bir günde Ajanda kaydı varsa tarih altında görünür kayıt göstergesi bulunur.
- `1–3` kayıt için aynı sayıda küçük nokta kullanılabilir.
- `4+` kayıtta sınırsız nokta veya spiral çizilmez; bounded nokta + sayısal badge/count ile toplam yoğunluk görünür tutulur.
- Örneğin 100 kayıtta 100 ayrı nokta üretilmez; tarih hücresi kayıt sayacı yüzünden okunamaz hale gelmez.
- Gösterge yalnız kayıt yoğunluğunu anlatır; güne dokunulduğunda gerçek kayıt listesi açılır/görünür.

#### CAL-03 — Yalnız aktif projenin Ajanda kayıtları

- Normal Ajanda ay/gün görünümünde yalnız aktif projeye ait kayıtlar gösterilir.
- Başka projelerin kayıtları aynı takvimde karışmaz.
- Başka projeyi görmek için shared active-project context değiştirilir; Ajanda içinde ikinci bir bağımsız proje sistemi kurulmaz.
- Aktif proje değişimi source kaydı mutate etmez; görünüm context'i değişir.
- Seçili gün semantik olarak mümkünse korunabilir, fakat eski projenin kayıtları görünmez.
- Legacy/global/projesiz kayıt varsa silinmez veya sessizce başka projeye bağlanmaz; implementation audit'i güvenli erişim/disposition yolunu tanımlar.

#### CAL-04 — `Yeni Proje` eylemini Ajanda'dan kaldır

- Ajanda ana ekranındaki `Yeni Proje` butonu kaldırılır.
- Proje oluşturma onboarding / proje seçici / proje profili bağlamında kalır.
- Ajanda proje oluşturma giriş kapısı olmaz.

#### CAL-05 — `Mahal Kataloğu` yönetimini Ajanda'dan çıkar

- Ajanda ana ekranındaki `Mahal Kataloğu` yönetim girişi kaldırılır.
- Mahal yönetiminin ana konumu Proje Profili / proje bağlamıdır.
- Ajanda kaydı oluşturma akışı mevcut stable Mahal bilgisini **kullanabilir/seçebilir**, fakat Ajanda ana ekranı Mahal yönetim merkezi olmaz.
- Bu madde Q04/AP-06 ile uyumludur; aynı navigasyon davranışı iki ayrı source-of-truth üretmez.

#### CAL-06 — Seçili gün ve empty-state davranışı

- Kullanıcı güne dokunduğunda o günün kayıtları aynı Ajanda bağlamında doğrudan görünür; sırf günlük listeyi görmek için gereksiz ayrı navigasyon dayatılmaz.
- `Bu ay için Ajanda kaydı bulunmuyor.` ile `Bugün için kayıt yok.` gibi ay ve seçili-gün empty state'leri ayrılır.
- Boş seçili günde görünür `+ Ajanda kaydı` ana eylemi sunulabilir.

#### FORM-01 — Tarih ve saati açıklamanın hemen üstüne taşı

- Ayrı/aşağıdaki `Zaman ve tür` ExpansionTile kaldırılır.
- Tarih ve saat, `Kısa açıklama` alanının hemen üzerinde tek kompakt metadata satırında görünür.
- Tarih için takvim, saat için saat ikonu kullanılır; değerler ikon yanında açık metinle görünür.
- Kullanıcı bu kontrollere dokunarak tarih/saat seçicilerini açar.
- Normal yeni kayıt varsayılanı current Europe/Istanbul tarih+saatidir.
- Form kullanıcı tarafından takvimde başka bir gün seçildikten sonra açılmışsa seçilen gün korunur; saat current Istanbul saatiyle başlar. Kullanıcıya zaten seçtiği günü tekrar girdirtmez.

#### FORM-02 — Proje seçicisini ve form içi proje oluşturmayı kaldır

- Yeni Ajanda kaydında `Proje` dropdown'u bulunmaz.
- `Yeni proje oluştur` ikonu/eylemi formdan kaldırılır.
- Shared aktif proje üstte küçük, salt-okunur bağlam olarak görünür ve yeni kayıt bu exact proje ID'sine yazılır.
- Aktif proje yoksa form global/projesiz kayıt yaratmaz; kullanıcı önce proje seçme/oluşturma akışına yönlendirilir.
- Var olan bir kayıt düzenlenirken source proje identity'si formdan sessizce başka projeye taşınamaz; mevcut project ilişkisinin korunması audit ile sabitlenir.

#### FORM-03 — Proje seçicisinin yerine hızlı Mahal seçimi koy

- Ana bağlam kontrolü **Mahal seç** olur; yalnız aktif projenin mevcut stable Mahal kayıtlarını gösterir.
- Mahal seçimi opsiyoneldir; proje-geneli Ajanda kaydı geçerli kalır ve kullanıcı olmayan bir Mahal uydurmaya zorlanmaz.
- Kontrol ikon + açık `Mahal` etiketi taşır; çok mahalde bounded bottom sheet/searchable picker kullanılabilir.
- Mahal yönetimi/oluşturma bu formun işi değildir; `Mahal Kataloğu` form içine geri sokulmaz.
- Existing arşivli stable Mahal bağı bulunan eski kayıt düzenlenirken mevcut bağ görünür/preserved kalır; sessizce aktif başka Mahal'e dönüştürülmez.

#### FORM-04 — Tek ana metin alanı olarak `Kısa açıklama` bırak

- `İsteğe bağlı ayrıntılar` başlığı/ExpansionTile yeni kayıt formundan kaldırılır.
- Yeni kayıtta ayrı `Ayrıntılı not` metin alanı bulunmaz.
- Kullanıcının ana metin girişi yalnız `Kısa açıklama` olur; birkaç satıra büyüyebilen multiline alan olarak kalır.
- Mevcut legacy kayıtların saklanmış `notes` değeri migration olmadan silinmez veya edit-save sırasında boşaltılmaz; detail/history yüzeyindeki mevcut veri korunur.
- Eski not alanının gelecekte tamamen kaldırılması ayrı veri-contract kararıdır; bu UI sadeleştirmesi fiziksel veri silme yetkisi değildir.

#### FORM-05 — Kayıt türünü ikincil, kompakt kontrol olarak koru

- `Kayıt türü`, kaldırılan `Zaman ve tür` bölümünün içinde gizli ayrı form bölümü olarak kalmaz.
- Mevcut kapalı `AgendaCategory` sözleşmesi korunur; normal yeni kayıt varsayılanı `Genel not` olur ve kullanıcı çoğu kayıtta tür seçmeye zorlanmaz.
- Tür gerekiyorsa `Tür: Genel not` benzeri kompakt chip/dropdown ile değiştirilebilir; ana form hiyerarşisini domine etmez.
- İmalat, Kontrol, Görüşme/karar, Teslimat, İş güvenliği, Beton ve Sorun/gecikme gibi mevcut kategori anlamları; filtreleme ve Beton bağlantısı/sinyali gibi mevcut downstream davranışlar audit edilmeden silinmez.
- Schema/storage enum değişikliği bu UI işi kapsamında yoktur.

#### FORM-06 — Fotoğraf eklemeyi büyük ve görsel öncelikli hale getir

- Küçük `Fotoğraf ekle` ikon aksiyonu yerine form genişliğini kullanan belirgin bir fotoğraf kutusu/paneli bulunur.
- Kullanıcı-facing metin açıkça `Buradan fotoğraf ekle` / `Fotoğraf ekle` gibi eylemi anlatır.
- Dokununca mevcut güvenli Kamera / Sistem fotoğraf seçici akışı açılır; attachment güvenlik sözleşmesi korunur.
- Seçilen fotoğraflar kutunun altında bounded thumbnail/önizleme kartları olarak görünür; yalnız dosya adı listesiyle yetinilmez.
- Her önizlemede erişilebilir, en az 48×48 kaldırma eylemi bulunur.
- Çoklu fotoğraf seçimi korunur; picker iptali/başarısızlığı form metnini veya önceden seçilmiş fotoğrafları kaybettirmez.
- Thumbnail sunumu tam çözünürlüklü bütün fotoğrafları gereksiz eager decode ederek form performansını bozmamalıdır.
- Bu dilim yeni kayıttaki capture/pending-photo UX'ini düzeltir; mevcut kayıt attachment yaşam döngüsünü genişletmek ayrıca yetkilendirilmedikçe kapsam dışıdır.

#### FORM-07 — Nihai form hiyerarşisi ve draft güvenliği

Hedef günlük create sırası:

`Aktif proje (salt-okunur) → Tarih / Saat → Kısa açıklama → Mahal → Fotoğraf → Tür (ikincil) → Kaydet`

- Mevcut görünür `Kaydet` ana eylemi korunur ve en az 48×48 olur.
- Kaydedilmemiş değişiklik guard'ı korunur; fotoğraf veya metin varken yanlışlıkla Back veri kaybı üretmez.
- Proje/Mahal yönetimi, uzun opsiyonel form bölümleri ve ikinci metin alanı günlük capture akışını bölmez.
- Mevcut Beton suggestion gibi yararlı bağlamsal öneriler source semantiği korunarak ikincil kalabilir; ana hızlı kayıt akışını kapatmaz veya zorunlu hale gelmez.

**Q03 bitiş tanımı:**

- takvim yatay kaydırma olmadan kullanılabilir pencereye sığar;
- kayıt olan günler yoğunluğu anlaşılır biçimde gösterir ve çok yüksek kayıt sayısı sınırsız nokta/spiral ile UI'ı bozmaz;
- yalnız aktif proje kayıtları görünür ve proje değişimi source kayıtları mutate etmez;
- `Yeni Proje` ve `Mahal Kataloğu` yönetimi Ajanda ana ekranında/formunda bulunmaz;
- seçili günün kayıtları ve empty state kullanıcıya doğrudan anlaşılır;
- yeni kayıt formunda tarih/saat açıklamanın üstündedir ve context-aware doğru varsayılanla gelir;
- proje yeniden seçtirilmez; aktif proje read-only context olarak kullanılır;
- Mahal kolay erişilen, opsiyonel stable-ID seçicisidir;
- yeni kayıt için tek ana metin alanı `Kısa açıklama`dır; legacy ayrıntılı not verisi silinmez;
- fotoğraf ekleme büyük, belirgin ve önizlemeli ana capture yüzeyidir;
- `AgendaCategory` semantiği korunur fakat tür seçmek common-case zorunlu adıma dönüşmez;
- draft/back güvenliği, attachment bütünlüğü, stable identity/history ve mevcut downstream category davranışları korunur.

### Q04 — Ana Sayfa / Proje Profili genişletme

**Kaynak:** 6 Eylül 2026 owner uygulama kullanım geri bildirimi — `Ana Sayfa / Proje Profili` başlığı  
**Durum:** `QUEUED`

Amaç; Ana Sayfa'yı menü veya dar özet olmaktan çıkarıp aktif projenin okunabilir profili ve günlük saha kontrol yüzeyi haline getirmektir. Uygulama tek büyük PR olarak yapılmaz; aşağıdaki AP dilimleri current model audit'i ve risk düzeyine göre ayrı child'lara bölünebilir.

#### AP-01 — Mevcut proje veri modelini denetle

Kod değişikliğinden önce proje/blok/kat/mahal/personel omurgası incelenir:

- hangi proje alanları zaten mevcut;
- blok için stable ID/kayıt yapısı;
- kat ve Mahal'in blokla mevcut ilişkisi;
- toplam alan/kat bilgilerinin current source-of-truth'u;
- İşveren / Ana yüklenici / Yapı denetim gibi tarafların mevcut kaynakları;
- yeni alanlardan hangilerinin schema/persistence değişikliği gerektirdiği.

**Kural:** Mevcut bilgi ikinci kez saklanmaz. Audit schema değişikliğinin gerçekten gerekli olduğunu kanıtlarsa implementation öncesi ayrı CRITICAL child gerekir.

#### AP-02 — Proje profilinin bilgi mimarisini kur

İlk görünümde kompakt **Proje Özeti** bulunur. Hedef hazır alanlar:

- Proje adı;
- adres;
- toplam alan;
- blok sayısı;
- toplam kat;
- **YİBF No**.

Boş alanlar ana ekranı gereksiz doldurmaz. Ayrıntılar katmanlı/açılır bölümlerde sunulur:

- **Resmî Bilgiler:** YİBF No, ruhsat no, ruhsat tarihi, ada/parsel;
- **Proje Bilgileri:** başlangıç tarihi, hedef bitiş, kullanım türü, taşıyıcı sistem;
- **İlgili Taraflar:** İşveren, Ana yüklenici, Yapı denetim, Şantiye şefi.

Kesin alan listesi AP-01 audit sonucu kilitlenir; mevcut source'ta olmayan bilgi uydurulmaz.

#### AP-03 — Zengin profili ağır zorunlu forma dönüştürme

İlk proje oluşturma minimum bilgilerle tamamlanabilir kalır. Ayrıntılı proje bilgileri sonradan **Proje Profili → Düzenle** üzerinden eklenebilir. Zengin proje profili yeni proje oluşturma sürtünmesini artırmaz.

#### AP-04 — Blok bazlı proje yapısı

Çok bloklu projelerde ayrı **Bloklar** bölümü bulunur. A Blok / B Blok / C Blok gibi kayıtlar ayrı açılabilir. Audit izin verdiği ölçüde blokta şu bilgiler gösterilebilir:

- blok adı;
- toplam kat;
- bodrum kat;
- toplam alan;
- oturum alanı;
- bağımsız bölüm sayısı;
- kullanım türü.

Tek bloklu projede gereksiz çok-blok arayüzü dayatılmaz. Yeni stable identity veya persistence ihtiyacı audit edilmeden varsayılmaz.

#### AP-05 — Proje toplamlarını mümkün olduğunca bloklardan türet

Aynı bilgi proje ve blok seviyesinde kullanıcıya ikinci kez girdirilmez. Örneğin A Blok `4.500 m²`, B Blok `3.500 m²` ise semantik olarak uygunsa proje toplam alanı `8.000 m²` türetilebilir. Blok sayısı, toplam alan ve uygun bazı kat/bağımsız bölüm toplamları aynı ilkeye tabidir.

**Kural:** Türetilmiş değer ile bağımsız proje-level source alanı birbirine karıştırılmaz; mevcut source-of-truth sessizce değiştirilmez.

#### AP-06 — Mahal'i proje profilinin ana öğesi yap

`Mahal Kataloğu` Ajanda bağlamından çıkarılıp proje profiline taşınır. Proje profilinde erişilebilir, etiketli **Mahaller** girişi bulunur; yalnız icon kullanılmaz. Mevcut model izin verdiği ölçüde kullanıcıya `Proje → Blok → Kat → Mahal` ilişkisi anlaşılır biçimde gösterilir.

#### AP-07 — Özel Alan özelliğini koru

Mevcut **Özel alan ekle** kaldırılmaz. Ancak standart ve yaygın proje bilgileri kullanıcıya özel alan olarak yeniden tanımlatılmaz. Özel alan; sözleşme numarası, belediye dosya numarası, kule vinç referansı veya gerçekten projeye/kullanıcıya özgü ek bilgiler için esnek katman olarak kalır.

#### AP-08 — Ana sayfaya İş Gücü kartı ekle

Proje profilinde görünür **İş Gücü** kartı bulunur. Birincil günlük bilgi **Bugün sahada: N kişi** olur. Mevcut veri kaynakları güvenilir biçimde ayırabiliyorsa ikincil olarak **N kayıtlı personel** bilgisi gösterilebilir.

**Kural:** `Sicilde kayıtlı personel` ile `bugün gerçekten sahada bulunan personel` aynı metrik gibi sunulmaz.

#### AP-09 — İş Gücü kartını gerçek personel listesine bağla

İş Gücü kartına dokunulduğunda aktif projedeki saha personeli açılır. Bugünkü saha durumu önceliklidir. Liste gerektiğinde kişi, **Taşeron / İşveren** ve mevcut günlük durum bilgisini gösterebilir. Kullanıcı yalnız listeyi görmek için Sicil → ekip → Puantaj arasında gereksiz ekran dolaşımına zorlanmaz. Q05 first-class İş Gücü alanı tamamlandığında bu kart aynı shared destination/context'e derin link verir; ikinci bir bağımsız personel akışı oluşturmaz.

#### AP-10 — İş Gücü için doğru empty state'ler

İki durum ayrılır:

1. **Hiç firma/personel kaydı yok:** `Henüz saha personeli eklenmedi.` → ana eylem `Taşeron / İşveren ekle`.
2. **Personel kayıtlı fakat bugün saha/Puantaj durumu yok:** `Bugün için saha personeli henüz işaretlenmedi.` → ana eylem `Puantaja git`.

Bu iki durum aynı mesaj veya aynı CTA ile gösterilmez.

#### AP-11 — Ana sayfa yoğunluk kontrolü

Bütün proje alanları aynı anda açık bir form yığınına dönüştürülmez. Hedef hiyerarşi:

`Aktif proje → Proje Özeti → Bloklar → Mahaller / İş Gücü → Ayrıntılı proje bilgileri → Özel Alanlar`

Dashboard hâlâ canlı proje kontrol merkezi olmalı; bakım/form yoğunluğu günlük saha bilgisini bastırmamalıdır.

**Q04 bitiş tanımı:**

- proje genel bilgisi tek profilden okunabilir;
- çok bloklu projede bloklar ayrı incelenebilir;
- semantik olarak güvenli proje toplamları tekrar veri girişi olmadan türetilebilir;
- Mahaller doğrudan proje profilinden erişilebilir;
- bugünkü saha personeli ile kayıtlı personel ayrımı anlaşılır;
- İş Gücü kartı aktif proje personel görünümüne gider;
- empty state doğru ilk eylemi sunar;
- standart bilgiler için `Özel alan` oluşturmaya gerek kalmaz;
- ilk proje oluşturma onlarca zorunlu alana dönüşmez;
- schema/stable identity/persistence değişikliği gerekiyorsa ayrı CRITICAL yetki olmadan yapılmaz.

### Q05 — İş Gücü / Sicil first-class alanı + Firma → Personel sadeleştirmesi

**Kaynak:** 6 Eylül 2026 owner uygulama kullanım geri bildirimi — `İş Gücü / Saha Rehberi / Sicil` başlığı; #617 daily-core ve progressive-disclosure ilkeleri; current `WorkforceDirectoryPage`, `WorkforcePage`, `AttendancePage` baseline'ı.  
**Durum:** `QUEUED`

Amaç; İş Gücü'nü yalnız Puantaj ön-koşulu veya gizli yardımcı akış olmaktan çıkarıp aktif projenin günlük insan kaynağı yüzeyi haline getirmek, mevcut güçlü Saha Rehberi/Sicil yeteneklerini korumak ve ilk kayıt yolunu `Firma → Personel` seviyesine indirmektir.

#### WF-01 — İş Gücü'nü first-class ürün alanı yap; compact shell'i altıya çıkarma

- Compact navigation normatif `en fazla 5` sınırını korur; alt bara altıncı destination eklenmez.
- Current compact shell'deki `Puantaj` destination'ı **İş Gücü** üst alanına dönüşür. Böylece beş ana destination korunur: `Ana Sayfa`, `Hatırlatıcı`, `Ajanda`, `Envanter`, `İş Gücü`.
- İş Gücü alanı, daily attendance/Puantaj kabiliyeti ile Sicil/Saha Rehberi kabiliyetini aynı ürün ailesinde birleştirir. İlk seviye alt yüzeyler örneğin `Bugün` ve `Sicil` olarak ayrılabilir; exact compact control implementation child'da owner görsel review ile kilitlenir.
- `Bugün` mevcut daily Puantaj write semantics'ini sessizce değiştirmez; yalnız parent IA değişir. 7. owner feedback başlığındaki Puantaj IA/refinement ayrıca kendi roadmap kararında ele alınır.
- Q04 İş Gücü kartı bu shared destination'a doğru subview/context ile gider; farklı bir personel stack'i yaratmaz.
- Medium/expanded rail de aynı destination setini ve active-project context'i kullanır.

#### WF-02 — Mevcut Saha Rehberi / Sicil güçlü taraflarını koru

- Mevcut kişi arama, aktif/arşiv ayrımı, firma/ekip filtreleri, personel detail ve İSG/KKD/Puantaj ilişkileri yeniden yazılıp kaybedilmez.
- `Sicil` görünümü aktif projedeki canonical `WorkforceMember` kayıtlarının okunabilir directory/profile yüzeyi olur.
- Kişiye dokunmak mevcut stable person identity üzerinden profile gider; firma/ekip değişikliği geçmiş Puantaj, İSG, KKD veya event kayıtlarını yeniden yazmaz.
- User-facing sadeleştirme, backend `subcontractor`/team/table adlarını sırf isim uyumu için rename/migrate etme yetkisi değildir.

#### WF-03 — Puantaj için canonical Sicil/personel prerequisite'ini açıklaştır

- Puantaj satırı yalnız canonical Sicil `WorkforceMember` identity'si bulunan kişi için oluşturulur.
- Kullanıcı Puantaj içinden `Personel ekle` shortcut'ı kullanabiliyorsa bu shortcut önce aynı canonical Sicil kayıt akışını tamamlar; kayıt başarıyla oluşmadan attendance row yazılmaz.
- Serbest isim, geçici one-off person veya yalnız o güne ait sahte personel kaydı oluşturulmaz.
- Firma/personel prerequisite eksikse empty state kullanıcıyı doğru ilk kayıt eylemine yönlendirir; dead end üretmez.

#### WF-04 — İlk empty state'i Firma ile başlat ve Firma → Personel akışını doğrudan kur

- Seçili projede hiç firma/personel yoksa ilk ana eylem **`Taşeron / İşveren ekle`** olur; doğrudan `Personel ekle` gösterilmez.
- Firma başarıyla oluşturulduğunda kullanıcı registry/ekip yönetim ekranına geri atılmaz; aynı akışta görünür **`Personel ekle`** eylemi sunulur ve yeni personel o firmaya bağlanmış context ile açılır.
- Birden fazla personel ardışık eklenebilir; firma her seferinde yeniden seçtirilmez.
- Personel kayıtlı fakat bugün Puantaj yoksa `Bugün` yüzeyi `Puantaja git / Bugünü başlat` gibi doğru günlük eylemi sunar.

#### WF-05 — Firma terminolojisi ve hızlı firma formu

User-facing firma dili:

- genel registry/oluşturma eylemi: **`Taşeron / İşveren ekle`**;
- birinci alan: **`Firma adı`** — required;
- hemen altında: **`Yetkili adı`** — optional;
- **Telefon** korunur ve hızlı erişilebilir optional iletişim alanıdır;
- **Adres** ve **İş kalemi / uzmanlık** korunur;
- mevcut başlangıç/bitiş tarihi ve not gibi ikincil firma bilgileri veri kaybı olmadan korunur.

İlk görünüm form yığınına dönüşmez. `Firma adı`, `Yetkili adı` ve gerekirse `Telefon` önde; Adres, İş kalemi/uzmanlık, tarihler ve not progressive-disclosure `Diğer bilgiler` altında olabilir. Current source'taki `subcontractors` teknik adı user-facing copy'yi belirlemez.

#### WF-06 — Ekip'i kullanıcı-facing zorunlu prerequisite olmaktan çıkar

- Normal `Firma → Personel` akışında kullanıcı `Ekip oluştur` veya `Ekip seç` adımına zorlanmaz.
- Ekip kavramı tamamen silinmez; sahada gerçekten ekip yönetmek isteyen kullanıcı için optional/advanced organizasyon katmanı olarak kalabilir.
- Mevcut source bugün personel create/read zincirinde `teamName`, `team_id` ve firma+ekip JOIN'lerini zorunlu kullanmaktadır. Bu nedenle ilk implementation child **compatibility audit** ile başlar.
- Tercih edilen release yolu schema'yı gereksiz değiştirmeden current stable team/history modelini koruyarak kullanıcı-facing seçim adımını kaldırmaktır. Gerekirse her firma için açıkça kanonikleştirilmiş bir teknik/default ekip compatibility katmanı kullanılabilir; ad-hoc veya görünmez identity üretimi yapılmaz, davranış contract/test ile açıkça sabitlenir.
- Audit user-facing Ekip opsiyonelliğinin ancak nullable relation/schema migration, stable identity veya event/history contract değişikliğiyle güvenli olacağını kanıtlarsa bu alt dilim Q05 STANDARD UI işi içinde sessizce büyütülmez; ayrı **CRITICAL** child, exact migration/compatibility/backup gate ile açılır.
- Existing gerçek ekipler, ekip şefleri ve tarihsel ekip ilişkileri silinmez veya tek default ekip altında birleştirilmez.

#### WF-07 — Personel formunu minimum gerekli bilgiye indir

Yeni personel common-case ilk görünümü:

- bağlı **Taşeron / İşveren** — mevcut akıştan gelen salt-okunur context veya kolay override;
- **Ad Soyad** — required;
- **Meslek / Pozisyon** — required.

Ekip varsa **opsiyonel/advanced** seçim olur; personel oluşturmak için ilk görünümde zorunlu değildir.

Aşağıdakiler tek **`Diğer`** progressive-disclosure bölümü altında kalır:

- Personel kodu;
- Telefon;
- Adres;
- İşe başlama tarihi;
- Not.

Mevcut değerler edit sırasında korunur; kapalı `Diğer` bölümü existing data'yı sessizce boşaltmaz. İlk görünüm yalnız kaydın gerçekten gerekli bilgisini gösterir.

#### WF-08 — Directory filtre ve copy dilini aynı modele getir

- Saha Rehberi/Sicil filtrelerinde user-facing `Taşeron` tek başına kullanılmaz; bağlama göre **`Taşeron / İşveren`** veya açık `Firma` dili kullanılır.
- Existing ekip filtresi advanced/opsiyonel kalabilir; Ekip normal kayıt prerequisite'iymiş gibi gösterilmez.
- `Tanımsız taşeron` gibi eski fallback copy'ler audit edilir; canonical firma ilişkisi varken kullanıcıya backend terimi sızdırılmaz.
- İsim değişikliği source ID veya geçmiş event payload'ını rewrite etmez.

#### WF-09 — Firma sonrası doğrudan personel ve personel sonrası günlük işe dönüş

- Firma oluşturma success'i → doğrudan `Personel ekle`.
- Personel oluşturma success'i → yeni kişi Sicil listesinde görünür ve gerekiyorsa aynı İş Gücü context'inden bugünkü Puantaj'a eklenebilir.
- Kullanıcı yalnız bir personel eklemek için `Firma → Ekip yönetimi → Ekip ekle → Personel → tekrar Puantaj` zincirine zorlanmaz.
- Existing registry management ekranı advanced bakım için kalabilir; common-case ana yol değildir.

#### WF-10 — Veri güvenliği, risk ayrımı ve kabul

- `WorkforceMember.id` stable person identity olarak korunur; geçmiş attendance, İSG, KKD ve event ilişkileri isim/firma/ekip UX sadeleştirmesiyle yeniden yazılmaz.
- Firma arşivleme/pasifleştirme ve existing ekip lifecycle davranışları sessizce gevşetilmez.
- Shell destination değişimi source kaydı mutate etmez ve active-project context'i kaybettirmez.
- Schema/migration, stable identity, event/history veya backup relation değişikliği kanıtlanırsa exact CRITICAL child olmadan uygulanmaz.
- Compact 320/390 px, yüksek text scale, keyboard/back, empty states, Firma → Personel, existing-team edit, Sicil detail ve Puantaj prerequisite focused test + owner Acceptance ile doğrulanır.

**Q05 bitiş tanımı:**

- İş Gücü compact shell'de first-class ana destination'dır fakat compact destination sayısı 5'i geçmez;
- current Puantaj capability İş Gücü parent alanında günlük erişilebilirliğini kaybetmez;
- Sicil/Saha Rehberi doğrudan aynı İş Gücü alanından erişilir;
- Puantaj yalnız canonical kayıtlı personel identity'si üzerinde çalışır;
- ilk boş durumda `Taşeron / İşveren ekle`, firma sonrası doğrudan `Personel ekle` akışı vardır;
- normal personel ekleme Ekip oluşturma/seçme adımına zorlamaz;
- firma formunda `Firma adı`, `Yetkili adı`, telefon/adres/iş kalemi bilgileri doğru progressive disclosure ile korunur;
- personel formunun ilk görünümünde yalnız gerekli alanlar vardır; kod/telefon/adres/başlangıç/not `Diğer` altındadır;
- existing ekip, person identity, Puantaj/İSG/KKD geçmişi ve event ilişkileri korunur;
- teknik team compatibility schema/event/history değişikliği gerektirirse ayrı CRITICAL authority olmadan implementation yapılmaz.

### Q06 — Envanter / Kroki hedefli interaction refinement

**Kaynak:** 6 Eylül 2026 owner uygulama kullanım geri bildirimi — `Envanter / Kroki` başlığı; tamamlanmış #709–#714 baseline'ı; `docs/v2/CSE_INVENTORY_MAP_V1_CONTRACT.md`.  
**Durum:** `QUEUED`

Bu Q, tamamlanmış Inventory v1'i yeniden tasarım programına açmaz. Yalnız owner'ın gerçek kullanımda işaretlediği Kroki toolbar/gesture sürtünmesini ve aynı fiziksel noktaya birden fazla farklı Inventory kaydı ekleme engelini giderir. İlk implementation child source değişikliğinden önce current Inventory contract'taki açık toolbar davranışlarını bu owner kararıyla truth-sync eder.

#### INV-01 — Geri eylemini toolbox'tan ayır

- `Geri` çizim araçlarıyla aynı toolbox/rail içinde bir çizim aracı gibi sunulmaz.
- Ekranın üst bölümünde, kolay fark edilen, en az 48×48 gerçek hit-area'lı ayrı bir navigation action olur.
- Back/pop mevcut awaited autosave, save-failure block ve orientation restore sözleşmelerini aynen korur; görünür yer değişikliği veri güvenliğini daraltmaz.

#### INV-02 — `Taşı` modunu görünür toolbox'tan çıkar; pan/zoom kabiliyetini koru

- Dedicated `Taşı` toolbar butonu kaldırılır.
- Bu kaldırma ancak draw/select modlarında source mutation üretmeyen iki-parmak pan/pinch güvenli ve testli hale getirildikten sonra yapılır; tek parmak draw/select semantiği korunur.
- Pinch zoom ana viewport zoom yoludur; toolbar `+ / -` zoom butonları kaldırılır.
- `Tamamını göster / fit` ana toolbox'tan kaldırılır. Editor açılışındaki mevcut fit-to-canvas davranışı korunur; kullanıcı viewport'ta kaybolursa gerekiyorsa double-tap/overflow gibi ikincil, çakışmayan recovery gesture/action kullanılabilir.
- Pan/zoom/fit hiçbir koşulda source geometry veya placement koordinatını mutate etmez.

#### INV-03 — Permanent `Çizgiyi bitir` / `Alanı kapat` toolbar butonlarını kaldır, capability'yi contextual yap

- `Çizgiyi bitir` ve `Alanı kapat` permanent toolbox kontrolü olarak gösterilmez.
- Geçerli kapalı blok için mevcut snap-to-first/tap-first closure davranışı ana yol olur; kapanma sonrasında block/floor metadata akışı devam eder.
- Open-polyline desteği sessizce yok edilmez. Açık çizgiyi bitirme gerekiyorsa yalnız o anda görünen contextual `Tamam/Bitir`, yeni çizgiye geçiş veya eşdeğer açık kullanıcı eylemiyle erişilebilir kalır.
- Tek noktalı incomplete polyline cleanup, undo/redo ve autosave semantics korunur; mode switch gizlice source çizgiyi bitirmez.
- `CSE_INVENTORY_MAP_V1_CONTRACT.md` içindeki explicit button requirement production source'tan önce bu yeni owner UI yönüyle güncellenir.

#### INV-04 — `Serbest uzunluk` ikonunu semantiğine uygun hale getir

- Mevcut cetvel/`straighten` ikonu değiştirilir; yeni ikon bir ölçüm aracı izlenimi vermeden **yalnız sonraki kenarda akıllı uzunluk hizalamasını serbest bırakma** anlamını taşımalıdır.
- Exact Material icon implementation audit/görsel testte seçilir; yalnız icon değişikliği `Serbest uzunluk` semantiğini değiştirmez.
- Bir-shot davranışı korunur: yalnız sonraki committed segmentte smart length alignment bypass edilir, orthogonal kural korunur ve sonra normal hizalama geri gelir.

#### INV-05 — D-pad/movement wheel ilk kroki oluşturma aşamasında da çalışır

- `createOrRecover` ile ilk kroki hazırlanırken kullanıcı yeni oluşturulmuş/kapalı bir bloğu seçtiğinde aynı movement wheel ile sağa/sola/yukarı/aşağı taşıyabilir.
- Hareket yalnız valid mapped/new block üzerinde çalışır; henüz tamamlanmamış tek açık raw polyline sahte blok gibi taşınmaz.
- Bounds, self-intersection, overlap ve spatial validation fail-closed kalır.
- Immutable legacy/base geometry için mevcut kilit davranışı sessizce kaldırılmaz.
- İlk child mevcut source davranışını focused test + gerçek owner repro ile doğrular; zaten desteklenen path varsa gereksiz production rewrite yapılmaz, yalnız kanıtlanmış gap düzeltilir.

#### INV-06 — Çizim modu sticky kalır

- Kullanıcı `Çiz` modunu seçtiğinde, çizgiyi/alanı bitirmesi modu otomatik olarak başka moda çevirmemelidir.
- Kullanıcı açıkça `Seç` veya başka bir interaction'a geçene kadar draw mode seçili kalır.
- Current source bu yönde görünüyorsa ilk child cihazdaki owner bulgusunu reproduce eder; kaynak zaten doğruysa no-op evidence ile kapanır, device/runtime reset kanıtlanırsa dar bug fix yapılır.

#### INV-07 — Aynı fiziksel noktaya birden fazla farklı Inventory kaydı ekle

- Farklı `inventory_assets` kayıtları aynı exact aktif floor + `x/y` koordinatını paylaşabilir; bu davranış tek asset için v1 `one active placement` sınırını kaldırmaz.
- Current model/DB audit farklı asset'ler için same-coordinate uniqueness göstermediğinden varsayılan plan schema değişikliği değildir. Schema ihtiyacı ortaya çıkarsa Q06 aynı STANDARD UI işi içinde büyütülmez; ayrı CRITICAL child gerekir.
- Mevcut marker/cluster'a dokunulduğunda kayıtları açmanın yanında açık **`Bu noktaya kayıt ekle`** eylemi sunulur; bu eylem exact mevcut coordinate ve floor context'ini quick-create akışına taşır.
- Aynı noktadaki birden fazla kayıt tek count-cluster/stack marker ile temsil edilir; cluster açıldığında tüm kayıtlar deterministik listelenir ve her biri ayrı detail'e açılabilir.
- Marker overlap çözümü source koordinatlarını yapay olarak sağa/sola kaydırmaz; görsel ayrıştırma yalnız presentation state'tir.
- Existing map boş-alan tap davranışı korunur; marker hit'in create'i tamamen bloke etmesi bu explicit add-another action ile giderilir.

#### INV-08 — Q06 güvenlik ve kabul sınırı

- Stable asset/block/floor/sketch/placement identity, optimistic revision, append-only placement/event history, autosave/finalize ve backup formatı korunur.
- Bir asset'i birden fazla aktif placement'a bölme, stock ledger, CAD/GIS, gerçek ölçü veya yeni schema bu Q'nun doğal uzantısı değildir.
- Toolbar sadeleştirmesiyle temel navigation/pan/zoom/open-line/closure capability kaybolamaz.
- Exact create/edit-active ve same-point cluster davranışı focused automated test + owner device Acceptance ile doğrulanır.

**Q06 bitiş tanımı:**

- Geri eylemi toolbox'tan ayrılmış ve üstte açık navigation action olmuştur;
- `Taşı`, zoom `+/-`, fit, permanent `Çizgiyi bitir` ve permanent `Alanı kapat` ana toolbox'tan çıkmıştır, fakat karşılık gelen gerekli navigation/drawing capability kaybolmamıştır;
- draw/select sırasında iki-parmak pan/pinch güvenli çalışır;
- `Serbest uzunluk` ölçüm aracı izlenimi vermeyen anlamlı icon taşır ve one-shot semantics korunur;
- movement wheel yeni ilk-kroki bloklarında çalışır;
- draw mode explicit mode değişimine kadar sticky kalır;
- aynı exact noktada birden fazla farklı Inventory kaydı oluşturulabilir, cluster üzerinden tek tek açılabilir ve `Bu noktaya kayıt ekle` akışı vardır;
- source coordinate/identity/history/backup kontratları bozulmaz;
- Inventory contract source implementation'dan önce yeni toolbar/gesture/same-point owner kararlarıyla truth-sync edilmiştir.

### Q07 — KKD hızlı seçim

**Kaynak:** #617 Phase 4 / item 21  
**Durum:** `QUEUED`

Amaç: günlük saha kullanımında mevcut canonical KKD semantiğini değiştirmeden hızlı, erişilebilir ve minimum dokunuşlu seçim/atama akışı. Q05 İş Gücü/Sicil first-class alanı canonical person/firma akışını netleştirdiği için KKD hızlı seçim bu person identity yüzeyi üzerine oturur.

### Q08 — Beton tamamlanma / sonuç / detay / düzenleme akışı

**Kaynak:** #617 Phase 5 / item 23  
**Durum:** `QUEUED`

Amaç: Beton Paketi'nin gerçek saha kullanımında create → sonuç → detail → edit/completion zincirini tamamlamak ve mevcut identity/attachment davranışını korumak.

### Q09 — Malzemeler ortak UI/UX sistem uyumu

**Kaynak:** #617 Phase 5 / item 24  
**Durum:** `QUEUED`

Amaç: İstenecek Malzemeler ekranını shared project context, action, state, accessibility ve compact/adaptive görsel dile oturtmak; lifecycle source-of-truth'u değiştirmemek.

### Q10 — Albüm + Dosyalar + Yedekleme + Ayarlar yerleşimi

**Kaynak:** #617 Phase 5 / item 25  
**Durum:** `QUEUED`

Amaç: supporting tools'ın final first-release information architecture ve erişim yerini netleştirmek; attachment/recovery güvenlik sınırlarını korumak.

### Q11 — Minimum proje-geneli ortak arama

**Kaynak:** #617 Phase 6 / item 27  
**Durum:** `QUEUED`

İlk release için supported existing record families üzerinde basit, hızlı, project-safe ortak arama; enterprise/global index motoru değil.

### Q12 — Kısa guided onboarding

**Kaynak:** #617 Phase 6 / item 28  
**Durum:** `QUEUED`

Kısa, skip edilebilir ve değer odaklı: CSE nedir → ilk proje → ana günlük akış. Uzun tutorial yok.

### Q13 — Puantaj tamamlanınca Ajanda'ya otomatik kayıt

**Kaynak:** #617 owner decision `Puantaj → Ajanda automatic completion record`  
**Durum:** `QUEUED — CRITICAL`

- yalnız kullanıcı Puantaj gününü açıkça tamamladığında;
- generated Ajanda kaydı exact proje/gün/Puantaj source'una traceable;
- retry/reopen duplicate üretmez;
- identity, transaction, failure, event/history ve rollback sözleşmeleri ayrı CRITICAL Issue'da kilitlenir.

### Q14 — Şefim otomatik yedek klasörü

**Kaynak:** #617 owner decision `Backup destination folder`  
**Durum:** `QUEUED — CRITICAL`

- uygulama gerektiğinde dedicated local Şefim backup folder oluşturur ve default backup destination/source olarak kullanır;
- silent backup generation, overwrite, rotation/delete veya `.csebackup` format değişikliği bu kapsamın parçası değildir;
- exact path/data-root, compatibility ve restore validation zorunludur.

### Q15 — Otomatik personel kodu release kararı

**Kaynak:** #617 Phase 4 / item 22  
**Durum:** `DECISION GATE`

- Fatih V1 için tutarsa ayrı CRITICAL child açılır; identity/revision/compatibility sınırları açıkça test edilir.
- Fatih ilk genel yayın için gerekli görmezse açıkça `POST-RELEASE / DEFERRED` olarak işaretlenir.
- Karar verilmeden sessiz implementation yapılmaz.

### Q16 — Metraj V1 release kapsam kararı

**Kaynak:** #617 owner decision `Metraj scope expansion`  
**Durum:** `DECISION GATE`

Nihai ürün yönü: Metraj birkaç örnek kalemle sınırlı olmayacak; ana metraj kalemlerini kategori/iş grubu + arama/filtre ile kapsayacak.

Yayın öncesi yapılacak karar:

- **A — V1 blocker:** exact kalem kataloğu çıkarılır, persistence/schema etkisi incelenir ve ayrı implementation zinciri bu noktada tamamlanır.
- **B — Post-release expansion:** mevcut V1 metraj güvenli/işlevsel bırakılır; kapsamlı katalog açıkça post-release backlog'a alınır ve ilk genel yayını bloke etmez.

Fatih karar vermeden ChatGPT bu maddeyi sessizce atlamaz veya kapsamlı Metraj geliştirmesini başlatmaz.

### Q17 — Global hızlı cetvel

**Kaynak:** #617 owner decision `Quick Ruler global tool`  
**Durum:** `QUEUED`

- ekranın sol-alt köşesinden tek dokunuşla geçici tam ekran cetvel;
- tekrar dokunuşla exact önceki ekran/context geri gelir;
- source/form/session mutation yok;
- gerçek ölçü iddiasından önce device-aware physical calibration veya açık calibration fallback zorunludur.

### Q18 — Minimum crash/ANR/fatal telemetry + Privacy/KVKK/store declarations

**Kaynak:** #617 Phase 6 / items 29–30  
**Durum:** `QUEUED`

Aynı release-observability ve beyan ailesi tek Q altında kapanır:

- kişisel saha içeriğini gereksiz toplamayan minimum crash / ANR / fatal görünürlüğü sağlanır;
- telemetry/provider/permission gerçek davranışı local-first ve privacy sınırlarıyla audit edilir;
- Privacy / KVKK / store declarations uygulamanın gerçek izin, local data, backup, medya ve telemetry davranışıyla birebir eşleşir;
- uygulamada olmayan claim, gizli analytics veya beyan edilmemiş veri transferi yoktur;
- telemetry entegrasyonu security/privacy/dependency riski açarsa gerekli dar risk/gate tanımlanmadan merge edilmez.

Telemetry kapsamı önce kesinleşmeden ayrı privacy metni “tamamlandı” sayılmaz; aynı exact release davranışı üzerinden birlikte doğrulanırlar.

### Q19 — Recovery / backup owner acceptance

**Kaynak:** #617 Phase 6 / item 31  
**Durum:** `RELEASE GATE`

- locked Restore Model A doğrulanır: exact backup state full replacement, restore öncesi safety backup, backup verification, etkilenecek kayıt açıklaması, restore sonrası geri alma ve safety backup retention;
- backup folder işi Q14 pre-release yapıldıysa bu tur onun gerçek cihaz davranışını da kapsar;
- gerçek kritik data/destructive operasyon yalnız açık owner authority ile yürür.

### Q20 — Adaptive cihaz / pencere matrisi

**Kaynak:** #617 Phase 7 / items 32–33  
**Durum:** `RELEASE GATE`

Eski ayrı `compact/medium/expanded` ve `telefon/tablet/portrait/landscape/split-screen` gate'leri aynı doğrulama ailesinde birleştirilmiştir:

- compact / medium / expanded breakpoint davranışı;
- telefon ve tablet sınıfı;
- portrait / landscape;
- split-screen / resize;
- kritik state retention, okunabilirlik, taşma ve adaptive navigation davranışı.

Aynı RC ve aynı senaryodan üretilebilen kanıt tekrar çalıştırılmaz; estetik mükemmellik değil işlevsel/adaptive yeterlilik aranır.

### Q21 — TalkBack / yüksek yazı / focus / grayscale

**Kaynak:** #617 Phase 7 / item 34  
**Durum:** `RELEASE GATE`

Primary navigation ve kritik create/edit/save/confirm akışlarında erişilebilirlik kapanışı; yeni bir görsel redesign programına dönüşmez.

### Q22 — Release evidence + manuel kabul borçları + Inventory release-QA

**Kaynak:** #617 Phase 7 / items 35–36; Issue #479; #709–#714; Q06 owner refinement  
**Durum:** `RELEASE GATE`

Aynı RC üzerinde tekrar eden evidence ve manual-debt işleri tek gate'te kapanır:

- Baseline'da eksik kalan populated Puantaj, Beton result/detail/edit, attachment viewer, kayıtlı İSG/KKD ve gerekli motion/Back kanıtları tamamlanır.
- Daily Log + Work Chain targeted evidence #698 ile kapanmıştır ve yeniden yapılmaz.
- Inventory için #709–#714 baseline'ı ile Q06 Kroki refinement davranışları current RC üzerinde entegre regresyon/evidence kapsamında doğrulanır.
- İş Gücü/Sicil için Q05 Firma → Personel, canonical person prerequisite ve first-class shell davranışı current RC evidence/manual debt kapsamında doğrulanır.
- Release'e gerçekten dahil user-visible özelliklerde gerekli `PENDING/DEFERRED` manual test borcu PASS / N/A / superseded disposition ile kapanır; tarihsel gereksiz test sırf sayı için çalıştırılmaz.
- Q23/Q25 sırasında aynı exact RC üzerinde üretilmiş yeterli kanıt yeniden kullanılır; sırf evidence sayısı için duplicate screenshot/test turu yoktur.

### Q23 — Entegre “bir şantiye şefi günü” senaryosu

**Kaynak:** #617 Phase 7 / item 37  
**Durum:** `RELEASE GATE`

Tek projede gerçek günlük akışı temsil eden bütünleşik senaryo: proje bağlamı → hatırlatma/ajanda → plan → İş Gücü/Sicil/Puantaj → İSG/KKD → beton/malzeme → envanter/medya → backup/recovery; tekrar veri girişi, context drift, dead end ve mutation sürprizi olmamalı. Q05 Firma → Personel prerequisite ve Q06 same-point Inventory cluster/create bu senaryonun doğal parçasıdır.

### Q24 — Otomatik milestone gate + analyze/build + artifact provenance

**Kaynak:** #617 Phase 8 / item 38  
**Durum:** `RELEASE GATE`

Release candidate exact revision için gerekli birleşik test/analyze/build, package/signing/entrypoint ve artifact SHA/provenance kanıtı.

### Q25 — Owner telefon + tablet Release Candidate kabulü

**Kaynak:** #617 Phase 8 / item 39  
**Durum:** `RELEASE GATE`

Fatih exact RC artifact'ını en az telefon + tablet sınıfında kritik günlük akış ve görsel/ergonomi açısından kabul eder.

### Q26 — Açık genel yayın kararı

**Kaynak:** #617 Phase 8 / item 40  
**Durum:** `FINAL OWNER GATE`

Tüm zorunlu gate'ler geçtikten sonra public/store release ancak Fatih'in ayrı ve açık genel yayın kararıyla başlar. Release/store standing auto-merge yetkisinin dışındadır.

## 5. Queue çalışma kuralı

ChatGPT her yeni görevde veya `devam` talebinde:

1. current GitHub `master`, `AGENTS.md`, açık production Issue/PR ve bu queue'yu okur;
2. açık production Issue/PR varsa önce onu required gate'lerine kadar tamamlar;
3. aksi halde Q01→Q26 içinde current GitHub'a göre tamamlanmamış ilk uygulanabilir maddeyi seçer;
4. `DECISION GATE` maddesinde Fatih kararı yoksa implementation başlatmaz;
5. CRITICAL etiketi taşıyan maddede exact Issue/allowlist/compatibility/manual gate olmadan değişiklik yaptırmaz;
6. Fatih yeni sıra kararı verirse önce ROADMAP truth-sync yapılır, sonra production iş başlar;
7. aynı anda ikinci production implementation child açmaz;
8. tamamlanmış bir queue maddesini tekrar geliştirme işi gibi açmaz; yalnız kanıtlanmış regresyonda dar bug Issue açar veya ROADMAP'te açık owner-inserted dar refinement tanımlanır.

### Owner geri bildirimi sonrası tam yeniden sıralama kuralı

Fatih yeni bir ürün/kullanım geri bildirimini pre-release Q kuyruğuna eklemeyi istediğinde ChatGPT yalnız araya yeni bir numara sıkıştırmaz. Her seferinde:

1. current GitHub gerçeğini ve açık production gate'ini korur;
2. güncel Q01–Q26 listesinin tamamını saha değeri, release değeri, bağımlılık, sürtünme, risk ve kapsam şişmesi açısından yeniden değerlendirir;
3. kabul edilen yeni işi mevcut maddelerle çakışma/merge bakımından karşılaştırır;
4. gerekirse aynı iş ailesindeki Q'ları birleştirir veya tamamlanmış release-QA işini uygun release gate'e taşır;
5. kalan kanonik kuyruğu önem/bağımlılık sırasına göre baştan numaralandırır;
6. eski Q numarasını current otorite kabul etmez; güncel numara yalnız `ROADMAP.md` üzerinden okunur;
7. reprioritization gerekçesini `ROADMAP_REVIEW_LOG.md` içinde korur.

Bu kural, sıra ve numaraların tarihsel referans uğruna dondurulmasını engeller; açık production Issue/PR'nin required gate'leri ise her durumda önce tamamlanır.

## 6. İlk genel yayın sonrası / deferred backlog

Aşağıdakiler Q01–Q26 release kuyruğunu bloke etmez, ancak owner kararıyla daha sonra aktive edilebilir:

- **DWG Viewer v1 / Issue #523:** `POST-RELEASE / DEFERRED`. DWG ve doküman viewer uzun vadeli ana ürün hedefidir; ilk genel yayın bağımlılığı değildir.
- Q15'te V1 dışına alınırsa otomatik personel kodu.
- Q16'da B seçilirse kapsamlı Metraj katalog/çalışma merkezi.
- V2.12 Günlük Log v2 ve V2.13 Mini Hesap Makinesi: mevcut owner pause kararı sürer.
- Ayrı ürün toplantısı/brainstorm kayıtları, owner tarafından pre-release queue'ya taşınmadıkça yayın blocker'ı değildir.
- Büyük AI/semantic search, SaaS/multi-user, Primavera replacement ve geniş CAD/GIS hedefleri ilk genel yayın dışında kalır.

## 7. Korunan ürün ve güvenlik ilkeleri

- CSE modül koleksiyonu değil, local-first/mobile-first kişisel saha asistanıdır.
- Aynı bilgi ikinci kez girdirilmez; project context mümkün olduğunca korunur.
- Sürtünme azaltılırken stable identity, optimistic revision, append-only event/history, attachment ve backup bütünlüğü zayıflatılmaz.
- UI kendiliğinden hukuki uygunluk, resmî kabul/ret veya `blocked` kararı üretmez.
- Gerçek kullanıcı data root'u ve destructive restore/release işlemleri ayrı owner authority ister.
- Force-push, destructive reset/clean/stash ve beklenmeyen kullanıcı değişikliğini silme yoktur.
- Public/store release Q26'dan önce yapılmaz.

## 8. Tarihsel kaynaklar

Daha ayrıntılı V2 tarihçesi Git geçmişinde, `docs/v2/CSE_V2_SCOPE.md`, Issue #617 yorumları ve ilgili child Issue/PR'larda korunur. Eski roadmap fazları, Epic #97/#105/#127–#140, Orchestrator O0–O10, Bridge/Work Mode ve superseded UI programları current queue değildir.

Tarihsel kayıtlar silinmiş sayılmaz; yalnız yürütme otoritesi current `ROADMAP.md` içindeki yeniden numaralandırılmış Q01–Q26 kuyruğuna merkezileştirilmiştir.
