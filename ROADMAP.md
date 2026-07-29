# CSE 2026.3.4 — Asistan-Öncelikli Ürün Yol Haritası

**Durum:** Kanonik ürün sırası  
**Tarih:** 29 Temmuz 2026  
**Ürün Epic'i:** #105  
**Yürütme Epic'i:** #127  
**Güncel saha backlog'u:** #219  
**Önceki saha backlog'u:** #203  
**Açık Release 0.1 pilotu:** #193  
**Güncel RC / günlük saha testi:** #245  
**Roadmap senkronizasyonu:** #270  
**Açık P2 implementation:** #268 / Draft PR #269 — Ajanda deterministik sıralama  
**Sıradaki doğrulanması gereken P1:** bağımsız Hatırlatıcı bildirim yaşam döngüsü  
**Bloklu yatay kabul zinciri:** #257 → #254 / #256, Draft PR #259

## 1. Ürün kararı

CSE bir şantiye ERP'si veya modül kataloğu değildir. Tek gerçek kullanıcısı
şantiye şefidir.

> CSE; şefin gördüğü, duyduğu, söylediği ve takip etmesi gereken her şeyi hızlıca
> yakalayan, doğru bağlama yerleştiren, açık döngüleri izleyen, eksikleri önüne
> getiren, büyük resmi gösteren ve geçmişi kaynaklarıyla geri çağıran local-first
> kişisel saha asistanıdır.

```text
Yakala → Anla → Bağla → Takip et → Doğrula → Özetle → Hatırla
```

Yeni özellik ancak veri girişini azaltıyor, tekrar girişi önlüyor, doğru bağlamı
kuruyor, açık döngüyü görünür kılıyor veya saha hâkimiyetini artırıyorsa alınır.

## 2. Güncel güvenli nokta

Release 0.1 çekirdeğinde mobil runtime, Ajanda, Hatırlatıcı, Puantaj, taşeron–ekip–
personel sicili, Beton Paketi, mikser/irsaliye/numune/laboratuvar, fotoğraf ve PDF,
parola korumalı backup/restore ve Android release güvenliği uygulanmıştır.

Tamamlanan günlük güvenilirlik dilimleri:

- #221 — hızlı `Bugün`, gerçek `Tam gün` ve legacy `Bekliyorum` sadeleştirmesi;
- #225 — birleşik ve sade Bugün görünümü;
- #227 — Hatırlatıcı geri dönüşüm kutusu;
- #230 — Hatırlatıcıda kaynak Ajanda fotoğrafları;
- #234 — Beton sınıfı kataloğu ve döküm zaman çizgisi;
- #237 — Ajanda Beton sinyali, öneri ve Beton paketine deep-link;
- #252 / PR #253 — `Yarına ertele`, `2 saat` ve `3 saat` hızlı eylemleri;
- #260 / PR #261 — Beton checklist source-of-truth ve döküm başlatma hotfix'i;
- #262 / PR #263 — Hatırlatıcı tarih/source uygunluğu;
- #264 / PR #265 — dört ana listede detail dönüşü route-local state korunumu;
- #266 / PR #267 — Türkçe kullanıcı dili, Puantaj `Kaydet` eylemi ve seçim toolbar'ı.

Güncel güvenli `master`:

```text
1179870a7c69d1e3f090e5fc61da9c7bbfc42879
```

Bu noktada mobil schema `10`, backup formatı `1`, Flutter full suite `300 PASS`,
Flutter analyze `PASS` ve son geçerli merged Python full suite
`1005 passed, 7 skipped` durumundadır. Issue #266 / PR #267 Türkçe locale,
Puantaj `Kaydet`, seçim toolbar'ı ve veri koruyan fiziksel cihaz kabulüyle
merge edilmiştir.

Issue #268 / Draft PR #269 Ajanda deterministik sıralama çalışmasıdır. Source,
test, APK ve fiziksel cihaz kanıtları PR'da bulunur; ancak Draft PR merge edilmeden
bu çalışma güvenli `master` noktası sayılmaz. Bu roadmap güncellemesi #268 branch'i,
commitleri veya production/test diff'i üzerinde değişiklik yapmaz.

Fiziksel cihaz smoke otomasyonu için #254 üzerinde izole acceptance harness,
#256 üzerinde atomik build-root rotasyonu ve #257 üzerinde doğrulanmış acceptance
artifact yeniden kullanımı çalışmaları bloklu Draft PR #259 içinde tutulur.
Merge edilmemiş branch/diff, GitHub `master` gerçeğinin yerine geçmez.

Ayrıntılı tamamlanma geçmişi Issue'larda, `CHANGELOG.md` ve karar belgelerinde
tutulur; bu dosya ileri ürün sırasını tanımlar.

## 3. Günlük saha testi ve geliştirme modeli

Haftalık test sonunda toplu karar verme modeli kullanılmaz. Kullanıcı uygulamayı
her gün gerçek şantiye işlerinde kullanır ve günlük test raporu verir. Her yeni
production adımı o rapordaki en yüksek öncelikli doğrulanmış bulguya göre seçilir.

```text
Günlük gerçek kullanım
→ Günlük test raporu
→ P0–P3 sınıflandırması
→ Tek child Issue
→ Dar uygulama ve minimum yeterli doğrulama
→ Veri korumalı cihaz güncellemesi
→ Ertesi gün gerçek saha doğrulaması
```

Öncelik sınıfları:

1. **P0 — Veri güvenliği:** kayıt kaybı, yanlış projeye/kayda bağlantı, bozuk
   attachment, backup/restore veya update bütünlüğü. Roadmap durur.
2. **P1 — Ana akış blocker'ı:** Ajanda, Hatırlatıcı, Puantaj veya Beton işleminin
   tamamlanamaması ya da güvenilir takip kaybı. Yeni özellikten önce çözülür.
3. **P2 — Günlük sürtünme:** yanıltıcı metin, gereksiz dokunma, tekrar veri girişi,
   yanlış eylem, yanlış sıralama veya sahada yavaşlatan UX. P3 özellikten önce alınır.
4. **P3 — Planlı özellik:** P0–P2 bulgusu yoksa aşağıdaki kanonik sıraya devam edilir.

Yedi günlük kabul kapısı korunur; ancak bu süre geliştirmeyi bekleten haftalık
bir pencere değildir. Kanıt, birbirini izleyen günlük raporların toplamıdır.

## 4. Üst seviye öncelik sırası

```text
Güvenilir saha sürümü
→ Günlük hotfix ve veri bağlantısı
→ Ortak medya ve günlük plan
→ Sürtünmesiz yakalama
→ Açık döngü asistanı
→ Bağlam ve büyük resim
→ Uçtan uca saha paketleri
→ Kalite/İSG/resmî süreç
→ Doküman ve proje hafızası
→ Kaynaklı AI
→ Geniş planlama ve öngörü
→ Ürünleştirme
```

AI dört kontrollü seviyede eklenir:

- **AI-1 Yakalama:** transkript, alan ve bağlam önerisi;
- **AI-2 İşleme:** belge alanı, fotoğraf grubu ve kayıt eşleştirmesi;
- **AI-3 Hafıza:** kaynaklı arama, soru-cevap ve rapor taslağı;
- **AI-4 Öngörü:** eksik adım, risk ve anomali önerisi.

AI teknik kabul, resmî karar, imalat onayı veya sessiz kayıt kapatma yetkisi
kazanmaz.

# 5. Fazlar

## Faz 0 — Release 0.1 gerçek saha kabulü

**Amaç:** Mevcut çekirdeğin gerçek telefonda güvenilirliğini günlük raporlarla
kanıtlamak.

- Ajanda, Hatırlatıcı, Puantaj ve Beton birlikte kullanılır.
- Kapalı uygulama Hatırlatıcı teslimi doğrulanır.
- Backup, dışa çıkarma, preflight ve restore yürütülür.
- Fotoğraf, irsaliye, kayıt, restart ve güncelleme bütünlüğü doğrulanır.
- Günlük raporda bulunan P0/P1 sorunları ayrı dar blocker Issue'suna dönüşür.
- P2 bulgular Release 0.1.1 sırasına günlük öncelik olarak girer.

**Kapı:** En az 7 ardışık gerçek günlük rapor; veri kaybı `0`; sessiz kritik
notification başarısızlığı `0`; restore farkı `0`; açık kritik blocker `0`.

### Yatay fiziksel kabul altyapısı

Bu çalışma ürün özelliği değildir; bütün sonraki cihaz doğrulamalarının güvenli
ve veri-minimal yürütülmesini sağlar.

- #254 — production sandbox'ından ayrılmış Flutter acceptance harness;
- #255 — Windows generated dizin recovery — tamamlandı;
- #256 — ardışık build'ler için atomik `mobile/build` rotasyonu;
- #257 — fiziksel smoke sırasında exact doğrulanmış acceptance APK'yı yeni build
  veya rotasyon yapmadan yeniden kullanma.

Physical smoke yalnız provenance, marker, applicationId ve SHA-256 değeri
kanıtlanmış exact artifact'i kullanır. Doğrulanmış artifact mevcutsa smoke öncesi
gereksiz ikinci build veya destructive cleanup yapılmaz.

---

## Faz 0.1 — Release 0.1.1: Günlük Güvenilirlik / Sadeleştirme

**Amaç:** Universal Capture'a geçmeden önce günlük kullanım blocker'larını,
yanlış eylemleri, tekrar veri girişini, kaynak bağlantısı kopukluklarını ve temel
saha araçlarını dar child Issue'larla kapatmak.

### Tamamlanan bloklar

1. **Reminder scheduling contract — tamamlandı:** hızlı `Bugün`, gerçek
   `Tam gün` ve legacy `Bekliyorum` yüzeyinin kayıpsız kaldırılması.
2. **Birleşik ve sade Bugün — tamamlandı:** gecikenler, saatli bugün ve tam gün
   işleri tek ana yüzeyde.
3. **Reminder geri dönüşüm kutusu — tamamlandı:** recoverable trash/restore ve
   güvenli notification lifecycle.
4. **Ajanda → Hatırlatıcı kaynak attachment görünürlüğü — tamamlandı:** kaynak
   Ajanda fotoğrafları Hatırlatıcı detayında salt okunur.
5. **Beton sınıfı ve döküm zaman çizgisi — tamamlandı:** katalog, başlat/bitir,
   gerçek zamanlar ve tek bağlı Ajanda logu.
6. **Beton kelime önerisi/deep-link — tamamlandı:** deterministik öneri ve Beton
   paketine bağlantı; otomatik kayıt veya teknik karar yok.
7. **Hatırlatıcı hızlı eylem netliği — tamamlandı:** `Yarına ertele`, `2 saat` ve
   `3 saat` planlama/erteleme eylemleri; schema ve backup formatı değişmedi.

### Günlük Saha Hotfix Dalgası

8. **Beton checklist source-of-truth ve döküm başlatma blocker'ı — tamamlandı**
   - `Tümünü tamamla` atomik çalışır; kısmi checklist sonucu bırakmaz.
   - Açık/tamamlanan sayacı yalnız kaynak checklist item durumlarından hesaplanır.
   - Zorunlu kalemler tamamlanınca açık sayı aynı ekranda `0` olur ve
     `Dökümü başlat` ek refresh gerektirmeden kullanılabilir.
   - Restart sonrasında checklist ve başlatılabilirlik korunur.
   - `Dökümü başlat → Dökümü bitir` ana akışı gerçek cihazda doğrulanır.
   - Stale revision veya event failure bütün transaction'ı geri alır.

9. **Hatırlatıcı kaynak/tarih duyarlı eylem uygunluğu — tamamlandı**
   - `Yarına ertele` yalnız gecikmiş veya bugün tarihli uygun aktif kayıtta görünür.
   - Zaten yarın veya daha ileri tarihli kayıtta gösterilmez.
   - Puantaj tarafından yönetilen occurrence/reminder üzerinde generic eylem
     gösterilmez; kaynak akışa `Puantajı aç` ile gidilir.
   - UI görünürlüğü ile domain mutation guard aynı kurala dayanır.

10. **Liste ve navigasyon durumunu koruma — tamamlandı**
    - Detaydan geri dönünce scroll offset, seçili gün, proje/kategori filtresi,
      arama metni ve aktif görünüm korunur.
    - Ajanda, Hatırlatıcı, Beton ve Puantaj listeleri aynı route-local sözleşmeyi
      kullanır.
    - Cold restart sonrası aynı pixel konumu ilk sürüm zorunluluğu değildir.

11. **Türkçe kullanıcı dili ve kayıt eylemleri — tamamlandı**
    - Ana Puantaj form eylemi `Kaydet` olarak gösterilir.
    - `Taslak` lifecycle durumu içeride ve detay etiketi olarak korunur.
    - Metin seçme/kopyalama menüsü Türkçe locale ile çalışır.
    - Doğrulanmış karışık kullanıcı dili dar envanterle temizlenmiştir.

12. **Ajanda sıralama seçeneği — P2 / Issue #268 / Draft PR #269**
    - Yeni route varsayılanı `En yeni üstte`; kullanıcı `En eski üstte` seçebilir.
    - Seçim route-local kalır ve gün, proje, tür, aktif/arşiv, literal arama,
      detail mutation ve geri dönüş bağlamıyla korunur.
    - Sıra `observed_at`, `created_at`, `id` alanlarıyla application query
      katmanında deterministiktir; `updated_at` ve client-side `reverse()` yoktur.
    - Draft PR merge edilmeden blok tamamlandı sayılmaz.

### 29 Temmuz 2026 günlük saha dalgası

Bu dalga mevcut Blok 13–26 numaralarını değiştirmez. Her başlık ayrı ve dar child
Issue olarak uygulanır.

#### D29.1 — Hatırlatıcı bildirim izolasyonu — P1

- Bir Hatırlatıcı tamamlandığında yalnız o kaydın platform bildirimi kapanır.
- Diğer aktif, gecikmiş veya planlanmış Hatırlatıcı bildirimleri görünür kalır.
- Kart, detay, notification action ve deep-link aynı reminder kimliğini hedefler.
- Genel `cancelAll` veya eşdeğer toplu iptal normal tek-kayıt eyleminde kullanılmaz.
- Restart/reconcile sonrasında kalan bildirimler source kayıtlarıyla yeniden eşleşir.
- Aynı notification ID'nin farklı reminder kayıtlarında yeniden kullanılması yasaktır.
- En az üç eşzamanlı bildirimle tamamla, ertele, aç ve restart matrisi doğrulanır.

**Kapı:** İlgisiz notification kaybı `0`. Bu P1 kapanmadan yeni P3 özelliğe
geçilmez.

#### D29.2 — Ajanda arama odağı ve klavye izolasyonu — P2

- Ajanda detayından listeye dönüldüğünde literal arama metni korunabilir; ancak
  kullanıcı arama alanına açıkça dokunmadıysa odak, imleç ve klavye geri gelmez.
- Listeyi hızlı kaydırma, yön değiştirme veya momentum scroll arama alanını aktif
  etmez.
- Scroll gesture ile search tap gesture birbirinden ayrılır.
- Route dönüşü, detail mutation reload, hızlı scroll, küçük ekran, büyük yazı ve
  ekran klavyesi senaryoları widget testleriyle korunur.

**Kapı:** Kullanıcı açıkça aramaya dokunmadan klavye açılması `0`.

#### D29.3 — Hatırlatıcı zaman ve düzenleme sürtünmesi — P2

- `Yarın sabah` exact ertesi yerel gün `08:00` anlamına gelir.
- `Hafta başına ertele` exact sonraki pazartesi `08:00` anlamına gelir; uygulanacak
  tarih işlem öncesinde açıkça gösterilir.
- Hatırlatıcı zamanı tam düzenleme formuna girmeden güvenli hızlı eylemlerle erkene
  alınabilir; geçmiş zamana düşen seçim açık uyarı/onay olmadan kaydedilmez.
- Hatırlatıcı düzenleme ekranında `Tam gün` seçeneği oluşturma ekranıyla aynı
  sözleşmeyi kullanır.
- İlgili yerel gün içinde tam gün kayıtları saatli kayıtların üstünde gösterilir;
  gecikmiş/kritik üst bölümünün önceliği sessizce değiştirilmez.
- Hatırlatıcı listesinde `Tüm projeler`, aktif proje ve `Projesiz` filtreleri bulunur.
- Arşivli projeler varsayılan aktif filtrede gösterilmez.
- Filtre, arama, sıralama ve detay dönüşü route-local state ile korunur.

#### D29.4 — Ajanda–Hatırlatıcı bağlantı görünürlüğü ve değişiklik geçmişi — P2/P3

- Bağlı Hatırlatıcısı bulunan Ajanda kartında sağ üstte küçük, erişilebilir bir
  bağlantı göstergesi bulunur.
- Gösterge yanlış pozitif üretmez ve ilgili Hatırlatıcı detayına gider.
- Ajanda kaydı sonradan düzenlendiğinde kullanıcı tarafından okunabilir değişiklik
  geçmişi oluşturulur.
- Geçmiş en az değişiklik zamanı, değişen alan, önceki değer ve yeni değeri taşır.
- Geçmiş kullanıcı tarafından düzenlenemez; source event/revision zincirinden
  üretilir veya onunla atomik tutulur.
- Eski günlük/log çıktıları sessizce yeniden yazılmaz.
- Kontrollü Ajanda–Hatırlatıcı metin senkronu, değişiklik geçmişini atlamaz.

#### D29.5 — Backup işlem görünürlüğü — P2

- Yedek oluşturma sırasında uygulama donmuş gibi görünmez; ayrı bekleme/ilerleme
  yüzeyi açılır.
- Gerçek ilerleme yüzdesi yoksa sahte yüzde gösterilmez; doğrulanmış aşamalar
  gösterilir: hazırlanıyor, paketleniyor, bütünlük kontrolü, kaydediliyor.
- Aynı anda ikinci backup başlatılamaz.
- Geri/çıkış davranışı ve işlemin devam edip etmediği açıkça belirtilir.
- Başarıda dosya adı, konum ve zaman; hatada güvenli hata özeti ve dosyanın oluşup
  oluşmadığı gösterilir.
- Backup formatı, manifest, parola ve restore uyumluluğu değiştirilmez.

### Proje ve Mahal Kataloğu v1 — P3 temel omurga

Bu çalışma Blok 13'ten ve geniş Beton/İş akışından önce ortak bağımlılıktır.

- Proje adı ve açıklayıcı alanlar düzenlenebilir.
- Proje arşivlenebilir ve arşivden çıkarılabilir.
- Arşivleme bağlı Ajanda, Hatırlatıcı, Beton, İş, medya ve event geçmişini silmez.
- Proje bazlı yeniden kullanılabilir Mahal Kataloğu oluşturulur.
- Mahal stable ID, ad, isteğe bağlı üst bağlam ve aktif/arşiv durumunu taşır.
- Aynı mahal Ajanda, Hatırlatıcı, Beton, İş, fotoğraf ve sonraki iş paketlerinde
  tekrar seçilebilir.
- Mahal adı değiştiğinde tarihsel kayıtların kimliği kopmaz; sessiz string
  çoğaltma yapılmaz.
- Proje/Mahal katalogları olmadan Beton canlı operasyon ve geniş İş akışı başlamaz.

#### Kalıcı proje silme — karar çatışması

Yeni saha isteği, önceki `silme yok; arşivle` ürün kararıyla çelişmektedir.
Roadmap şu fail-closed konumu korur:

1. **Kesin kapsam:** düzenle, arşivle, arşivden çıkar.
2. **İlk güvenli silme adayı:** yalnız bağlı verisi `0` olan boş/test projesi.
3. **Bağlı verisi olan proje:** ilk implementation'da yalnız arşivlenir.
4. Kalıcı silme için ayrı Owner Data Lifecycle karar Issue'su gerekir.
5. Gelecekte silme kabul edilirse işlem öncesinde bağlı kayıt/medya/event
   envanteri, geri alınamazlık uyarısı, mevcut doğrulanmış backup, açık metin
   doğrulama ve kullanıcı güvenlik parolası birlikte zorunlu olur.
6. Parola tek başına veri kaybı koruması sayılmaz.
7. Otomatik, toplu veya arka planda hard-delete kesin kapsam dışıdır.

### Veri bağlantısı ve günlük çıktı

13. **Ajanda–Hatırlatıcı kontrollü metin senkronu**
    - Ajandadan oluşturulan yeni Hatırlatıcı başlangıçta kaynak metne bağlıdır.
    - Ajanda açıklama/not/mahal değişiklikleri bağlı Hatırlatıcı metnine atomik
      olarak yansır.
    - Hatırlatıcı zamanı, durumu, son tarihi ve sonuç alanları bağımsız kalır.
    - Kullanıcı Hatırlatıcı metnini doğrudan düzenlerse açık onayla metin bağı kopar.
    - Erteleme, tamamlama veya önem değiştirme bağı koparmaz.
    - Legacy bağlantılar veri ezmemek için varsayılan bağımsız kabul edilir.
    - Migration, append-only event, rollback ve backup/restore doğrulanır.
    - Ajanda kartındaki bağlı-Hatırlatıcı göstergesi aynı source link'ten beslenir;
      ikinci bağlantı gerçeği oluşturmaz.
    - Source metin değişikliği önceki/yeni değer geçmişinde görünür olur.
    - Senkronizasyon event'i ile kullanıcı-okur geçmiş aynı transaction/revision
      sınırında doğrulanır.

14. **Günlük Log Çıktısı v1**
    - Seçilen proje ve gün için deterministik, insan-okur günlük log üretir.
    - Saat, kategori, mahal, açıklama, not, arşiv durumu ve attachment envanteri
      kaynak kayıtlarından alınır.
    - Telefona kaydetme ve paylaşma açık kullanıcı eylemidir.
    - Backup/restore artifact'i veya AI prompt'u değildir; ayrı versioned çıktı
      ailesidir.
    - İlk sürüm attachment byte'larını çoğaltmak zorunda değildir.

### Non-blocking eşlikçi UX

**Başlangıç ekranı Saha İpuçları** bağımsız, düşük riskli bir UI işidir ve sonraki
veri omurgası bloklarını bekletmez.

- Offline, dönüşümlü ve kullanıcıyı rahatsız etmeyen tek ipucu kartı.
- Manuel ileri/geri gezinme ve erişilebilirlik.
- İlk içerikler kayıt disiplini, kanıt, raporlama ve açık döngü farkındalığıdır.
- Popup veya notification kullanılmaz.

### Ortak medya omurgası

15. **Ortak Attachment v2**
    - Fotoğraf, video, ses ve belge için tek fiziksel attachment.
    - Ajanda, Hatırlatıcı, Beton, Sicil ve albüm için çoklu kayıt bağlantısı.
    - Galeriden çoklu seçim ve kamera ile ardışık çoklu fotoğraf çekimi.
    - Kaydetmeden önce önizleme, çıkarma ve kısmi hata durumunda atomik rollback.
    - Fotoğraf kaydetmeden önce kırpma ve döndürme desteklenir.
    - Orijinal attachment sessizce ezilmez; kırpılmış çıktı türev veya açık kullanıcı
      tercihiyle yönetilir.
    - Hash, MIME, boyut, backup/restore ve kaynak bağlantısı korunur.
    - Belge/irsaliye perspektif düzeltmesi ayrı sonraki iş olarak tutulur.
    - Managed storage, archive ve backup/restore round-trip korunur.
    - Aynı fiziksel dosya farklı modüller için kopyalanmaz.
    - Viewer dokunulan fotoğraf indeksinden başlar ve integrity hatasını gizlemez.

16. **Proje fotoğraf/video albümü**
    - Proje, tarih, kategori ve kaynak kayıt bağlantısıyla medya görünümü.
    - Thumbnail, sayfalama, swipe viewer ve kaynak kayda geri bağlantı.
    - Blok 15 tamamlanmadan başlamaz; fiziksel dosya ikinci kez kopyalanmaz.

### Günlük plan ve iş sürekliliği

17. **Ajanda Gün Planı Lite / İş ve Yapılacaklar**
    - `Günlük Kayıtlar | Gün Planı` görünümü.
    - Bir İş kaydı proje, mahal, gün, başlık, açıklama, öncelik, sıra, hedef tarih
      ve durum alanları taşır.
    - İşin içinde ayrı yapılacak listesi bulunur; ilk sürüm derinliği en fazla
      `İş → Yapılacak → Alt yapılacak` olur.
    - Alt kalemler varsa üst ilerleme onlardan hesaplanır; bağımsız ikinci sayaç yoktur.
    - `Tümünü tamamla` atomik çalışır; zorunlu açık kalem varken ana iş sessizce
      tamamlanmaz. Gerekçeli override açık event üretir.
    - Yapılacak tamamlandığında aynı İşe bağlı otomatik, append-only log oluşur.
    - Log en az zaman, eylem, önceki durum, yeni durum ve kaynak item kimliğini taşır.
    - Manuel açıklama, fotoğraf veya belge logu ayrıca eklenebilir.
    - Checklist item durumu source-of-truth'tur; log ikinci düzenlenebilir sayaç değildir.
    - Plan maddesinden Hatırlatıcı oluşturma desteklenir.
    - Yalnız kullanıcı onayıyla `Gerçekleşti ve Ajandaya kaydet` yapılır.
    - Planlanan iş, gerçekleşmiş Ajanda olayı sayılmaz.
    - İlk sürümde WBS, Gantt, bağımlılık ve kilometre taşı yoktur.

18. **İş Zinciri / Bağlı Log v1**
    - Birden çok tarihsel Ajanda logu tek `work_thread` veya eşdeğer üst kayda bağlanır.
    - Örnek akış: `başladı/devam ediyor → ilerleme → tamamlandı`.
    - Eski logun metni sessizce yeniden yazılmaz; her log gerçekleştiği anı korur.
    - İş Zinciri `Açık | Tamamlandı | İptal` durumunu taşır.
    - Kullanıcı `Bu işi açık iş olarak takip et`, `Mevcut işe bağla` ve
      `Bu işi tamamladı` eylemlerini açıkça seçer.
    - Aynı İşin otomatik checklist logları, manuel ilerleme logları ve ilişkili
      Ajanda olayları tek kronolojik görünümde birleşir.
    - Otomatik log silinmez veya geriye dönük değiştirilmez; düzeltme yeni event'le yapılır.
    - Yapılacak tamamlanması ana İşi otomatik kapatmaz; kapanış ayrı açık eylemdir.
    - Gün Planı maddesi aynı zincire bağlanabilir.
    - Faz 2 Open Loop ve Faz 4 İş Paketi için dar temel oluşturur.

19. **Günlük Log Çıktısı v2**
    - v1 alanlarına doğrulanmış fotoğraf/attachment görünümü eklenir.
    - Gün Planı gerçekleşmeleri, açık/tamamlanan İş Zincirleri ve bağlantılı kayıtlar
      tek günlük anlatıda kaynaklarıyla gösterilir.
    - Eski source kayıtları değiştirmez; yalnız presentation/read-model katmanıdır.

### Kişi ve bağlam omurgası

20. **Taşeron/personel/Puantaj UX ve Saha Rehberi**
    - #204 ile aynı taşeron–ekip–personel kimlik omurgası.
    - Puantajda taşeron → yalnız bağlı personel seçimi ve inline yeni kişi.
    - Telefon, adres, görev, firma, OSGB/SGK ve belge görünürlüğü.
    - Taşeron yetkilisi, personel, santral, laboratuvar, yapı denetim, tedarikçi ve
      diğer proje kişileri için birleşik arama.
    - Ad, firma, görev, proje ve normalize telefon numarasıyla arama.
    - Android numara çeviricisini açan kullanıcı kontrollü `Ara` eylemi.
    - Ayrı ve mükerrer bir telefon defteri kurulmaz.

21. **Deterministik kişi/firma/etiket önerileri**
    - Saha Rehberi kaydı rol, firma, görev ve kullanıcı tanımlı alias/etiketler taşır.
    - Ajanda veya yakalama metnindeki `kazık firması` gibi ifade, eşleşen gerçek
      kişi/firma kaydını öneri çipi olarak gösterebilir.
    - Kullanıcı onayı olmadan etiket veya kişi bağlantısı kaydedilmez.
    - Birden fazla veya düşük güvenli eşleşmede seçenek gösterilir; otomatik seçim yoktur.
    - İlk sürüm kural tabanlıdır ve Faz 1 Universal Capture tarafından yeniden kullanılır.

22. **Telefon görüşmesi sonucu → Ajanda**
    - Saha Rehberi'nden numara çevirici açılır.
    - Kullanıcı uygulamaya dönünce görüşme sonucunu açıkça kaydeder.
    - Sonuçlar: görüşüldü, ulaşılamadı, meşguldü, geri dönüş bekleniyor,
      arama yapılmadı ve diğer.
    - Kullanıcı onayıyla kişi/firma bağlantılı Ajanda kaydı oluşur.
    - `Geri dönüş bekleniyor` için Hatırlatıcı önerilir; otomatik oluşturulmaz.
    - Sistem Call Log geçmişi okunmaz; `READ_CALL_LOG` istenmez.

### Sonraki saha araçları

23. **İstenecek Malzemeler**
    - Malzeme, miktar/birim, ihtiyaç tarihi, öncelik ve açıklama.
    - `İhtiyaç var → İstendi → Geldi/İptal`.
    - Tam satın alma, teklif, sipariş veya muhasebe sistemi değildir.

24. **Kaynaklı AI prompt export**
    - Önce günlük, sonra hafta/ay/yıl.
    - Ajanda, Hatırlatıcı, Puantaj, Beton, Gün Planı, İş Zinciri ve görüşme kaynaklı
      deterministik metin.
    - Günlük Log Çıktısı ile aynı artifact ailesi değildir.
    - Gömülü AI çağrısı, otomatik gönderim veya sessiz veri mutasyonu yoktur.

25. **Mini hesap makinesi**
    - Temel işlemler ve kullanıcının onayladığı sayısal alana kontrollü aktarım.
    - İleri mühendislik hesapları ayrı dikeylerdir.

26. **Hava durumu uyarıları — ertelenmiş**
    - Haricî servis, proje konumu, cache/offline fallback, kullanıcı eşiği ve
      bildirim tercihi tasarımından sonra.
    - Her hava değişimi notification veya teknik karar üretmez.

### Özel bildirim sesleri — asset-dependent P3

- Kullanıcının hazırlayacağı ses dosyaları teslim edilmeden implementation başlamaz.
- Hatırlatıcı, kritik takip ve açık Beton operasyonu için rahatsız etmeyen ayrım
  tasarlanabilir.
- Sessiz, vibrasyon ve sistem varsayılanı seçenekleri korunur.
- Mevcut kullanıcı notification tercihleri ve upgrade davranışı test edilir.
- Bu iş D29.1 bildirim yaşam döngüsü güvenilirliğini bekler; onu bloke etmez.

**Kapı:** Blok 1–25 ve önlerindeki D29 güvenilirlik işleri ayrı, dar ve doğrulanmış
child Issue'larla tamamlanmadan Faz 1 production implementation'ı başlamaz. Blok 26
kanonik sırada korunur fakat haricî servis/eşik tasarımı nedeniyle ertelenmiştir.
Saha İpuçları hard gate değildir.

---

## Faz 1 — Release 0.2: Sürtünmesiz Evrensel Yakalama

**Amaç:** Her saha olayını 5–15 saniyede kayda dönüştürmek.

```text
+ Kaydet → Yaz | Konuş | Fotoğraf | Belge | Dosya | Hazır işlem
```

- Kullanıcı önce modül seçmez; CSE kayıt türünü önerir.
- Ortak `CaptureDraft` ve düzenlenebilir onay kartı kullanılır.
- Proje, blok/kat/mahal, imalat, kişi/firma ve termin etiketleri önerilir.
- Blok 21 alias/rol sözlüğü deterministik öneri için yeniden kullanılır.
- Aktif proje/mahal bağlamı geçici olarak kilitlenebilir.
- Eksik/düşük güvenli kayıtlar **Asistan Gelen Kutusu**na düşer.
- Ajanda ve Hatırlatıcı aynı işlemde oluşturulabilir.
- Sesli giriş kullanıcı onayıyla çalışır; ham ses varsayılan saklanmaz.
- Çevrim dışı taslak, restart ve Paylaş menüsü desteklenir.

**AI:** AI-1.  
**Kapı:** Sık kayıtların `%80`i `+ Kaydet`; ortanca süre `≤10 sn`; ilk zorunlu
alan `≤3`; çevrim dışı taslak kaybı `0`; tekrar veri girişi yok.

---

## Faz 2 — Release 0.3: Açık Döngü ve Takip Asistanı

**Amaç:** Şefin neyi yapacağını, kimden ne beklediğini ve kim ne söz verdiğini
zihninde taşımaması.

Ortak türler:

- Yapacağım;
- Başkasına verdim;
- Kimden ne bekliyorum;
- Söz/taahhüt;
- Kontrol edeceğim;
- Onay/cevap/belge bekliyor;
- Tekrarlanan rutin.

Özellikler:

- Blok 18 İş Zinciri açık döngü, sorumlu, takip tarihi ve taahhüt alanlarıyla genişler;
- **Beklediklerim:** kişi, konu, bekleme başlangıcı, son görüşme, sonraki takip,
  etkilenen iş;
- **Taahhütler:** sözü veren, termin, durum ve takip geçmişi;
- delegasyon, yeniden kontrol ve isteğe bağlı kapanış kanıtı;
- kaynaklı **Sabah Brifingi**;
- eksik soruları ve günlük rapor taslağıyla **Akşam Kapanışı**;
- birleştirilmiş kritik/işlem/takip/özet bildirimleri;
- `Ara`, `Mesaj hazırla`, `Tamamla`, `Ertele`, `Kaydı aç` eylemleri.

**AI:** AI-1 + kural motoru.  
**Kapı:** Her açık döngünün takip tarihi veya terminal durumu vardır; sabah özet
`≤30 sn`; akşam kapanışı `≤3 dk`; ayrı takip listesine ihtiyaç yok.

---

## Faz 3 — Release 0.4: Bağlam Omurgası ve Büyük Resim

**Amaç:** Ana ekranda ikon listesi değil, güncel saha durumu ve sıradaki doğru
hareketi göstermek.

```text
Proje → Bölge/Blok → Kat/Kesim → Mahal/Aks → İmalat/İş Paketi
```

Kişi, taşeron, ekip, malzeme, ekipman, belge/revizyon, görev, İş Zinciri ve kanıt
ortak referanslardır. Puantaj, görev, İSG ve paketler aynı kimlikleri kullanır.

Ana ekran:

1. kaynaklı Saha Brifingi;
2. Kritik, Bugün, Geciken, Beklenen, Hazır değil şeridi;
3. ilk sürümde Blok/Kat × İmalat **Saha Nabzı** matrisi;
4. aktif Beton gibi operasyonlar için canlı kart;
5. etkiye göre **Şimdi Ne Yapmalıyım** listesi;
6. proje, malzeme, ekip, ekipman, önceki iş, kalite ve İSG için 7–14 günlük hazırlık;
7. günlük zaman çizgisi.

Açık Beton operasyonu için:

- uygulama kartı ve Android bildirim paneli aynı açık Beton Paketini gösterir;
- tek read-model proje, mahal, santral, hedef beton, dökülen, kalan/aşılan, mikser
  sayısı ve son mikser zamanını üretir;
- bildirimden `Mikser ekle`, `İrsaliye ekle`, `Fotoğraf çek`, `Paketi aç` ve
  `Dökümü bitir` gibi güvenli hızlı işlemler açılabilir;
- hızlı işlem doğru paket/revision kimliğini taşır ve yanlış projeye mutation yapmaz;
- persistent operasyon bildirimi D29.1 tamamlanmadan production'a alınmaz.

İlk çözüm BIM değildir. Matris ana yüzeydir; plan üzerine işaretleme ve lineer
görünüm sonraki iterasyondur.

**AI:** açıklanabilir kural tabanlı sıralama + metinleştirme.  
**Kapı:** Saha `≤30 sn` içinde anlaşılır; her kart kaynağa gider; dashboard için
ayrı veri girilmez; yaklaşan eksikler önceden görünür.

---

## Faz 4 — Release 0.5: İş Paketi Motoru ve İlk Dikeyler

**Amaç:** Gerçek saha işlerini parçalamadan uçtan uca yürütmek.

```text
Planla → Hazırla → Uygula → Doğrula → Kapat
```

Her paket mahal, zaman, ekip, bağımlılık, kontrol, kanıt, açık sorun, gerçekleşen
miktar, insan doğrulaması ve kapanış raporu taşır. Blok 18 İş Zinciri gerekli
olduğunda tam iş paketine bağlanır; tarihsel loglar kaynak olarak korunur.

### Beton Paketi v2

- hazırlık ve eksik kontrolü;
- beton santrali adı ve proje geçmişinden yeniden seçim;
- Proje ve Mahal Kataloğu stable kimliklerine bağlantı;
- aynı plakanın farklı gelişleri dahil mikser yaşam döngüsü;
- irsaliye ve canlı hedef/dökülen/kalan/aşılan metraj;
- EBİS, numune, laboratuvar ve yapı denetim;
- versiyonlu numune önerisi ve gerekçeli override;
- kür, sonuç, eksik belge, rapor ve canlı ana ekran kartı;
- uygulama kartı, bildirim ve widget için tek source/read-model;
- Beton widget'ında açık paket, dökülen/kalan beton, mikser sayısı ve paketi açma;
- widget ayrı state veya ayrı sayaç tutmaz; stale veri görünür biçimde yenilenir;
- paket kapandığında yalnız ilgili bildirim/widget operasyonu kaldırılır.

### Malzeme Teslimatı ve İrsaliye

- beklenen sevkiyat, tedarikçi, malzeme, miktar ve araç;
- irsaliye tarama;
- kabul/şartlı kabul/red;
- eksik/hasar, fotoğraf, sertifika ve test raporu;
- depo/mahal ve iş paketi bağlantısı.

### Numune ve Laboratuvar

- beton, donatı ve malzeme numunesi;
- etiket, laboratuvara teslim, sonuç bekleme ve sonuç belgesi;
- çap bazlı ayarlanabilir donatı numune önerisi;
- resmî onay üretmeyen override/event geçmişi.

### Kontrol ve Uygunsuzluk

- fotoğrafla hızlı kayıt, sorumlu, termin ve yeniden kontrol;
- önce/sonra ve kapanış kanıtı;
- tekrarlanan sorun görünümü.

**AI:** AI-2 + kural motoru.  
**Kapı:** Gerçek Beton ve malzeme teslimatı uçtan uca kapanır; irsaliye tekrar
girilmez; eksik kanıt görünür; AI kabul/ret vermez; günlük rapor otomatik beslenir.

---

## Faz 5 — Release 0.6: Kalite, İSG ve Resmî Süreç

**Kalite:** kontrol listesi, test/muayene, kontrol talebi, uygunsuzluk, düzeltici
faaliyet, yeniden kontrol, numune/sonuç ve kapanış raporu.

**İSG:** tehlike, eksik durum, ramak kala, kaza, iş izni, iskele/yüksekte çalışma,
belge süreleri, eğitim, KKD ve düzeltici faaliyet.

**Resmî süreç:** ruhsat, yer teslimi, yapı denetim, sözleşme, izin, abonelik,
sigorta, gerekli evrak, süre sonu, beklenen kişi ve sonraki takip.

**AI:** AI-2; belge türü/tarih çıkarma, benzer sorun gruplama ve yalnız inceleme
öneren fotoğraf sinyali. Yapısal veya İSG kabul kararı vermez.  
**Kapı:** Kapanışta kanıt zinciri; süreler önceden görünür; kritik İSG ana ekranda
önceliklidir.

---

## Faz 6 — Release 0.7: Doküman ve Proje Hafızası

- doküman kimliği, disiplin, revizyon ve yayın tarihi;
- güncel/eski/iptal durumu ve exact iş paketi bağlantısı;
- PDF önizleme ve çevrim dışı favori;
- proje, mahal, imalat, kişi ve paketle bağlı fotoğraf;
- önce/sonra ve fotoğraf işaretleme;
- **Saha Turu:** seri fotoğraf/sesli not ve tek doğrulama;
- Türkçe tam metin arama ve bağlam filtreleri;
- doğrulanmış Hafıza paketiyle PC'de salt-okunur görünüm.

İki yönlü senkron öncesinde telefon source-of-truth kalır.

**Kapı:** Bilinen kayıtların `%90`ı `≤5 sn`; yanlış revizyon görünür; fotoğraf
bağı kopmaz; PC telefon verisini değiştirmez.

---

## Faz 7 — Release 0.8: Kaynaklı AI Saha Asistanı

Doğal dil örnekleri:

- “Ali Usta'ya verdiğim açık işler?”
- “Sonucu gelmeyen numuneler?”
- “Yarınki Betonun eksikleri?”
- “B Blok üçüncü kattaki son uygunsuzluklar?”
- “Bugünkü raporu hazırla.”

Her cevap kayıt, belge/revizyon, fotoğraf, tarih ve güven seviyesi gösterir.
Kaynak yoksa “doğrulanmış kayıt bulamadım” denir.

Yardımcılar:

- sabah/akşam özetleri ve günlük/haftalık rapor;
- toplantı tutanağı, karar, görev ve taahhüt önerisi;
- kalite/İSG özeti ve iletişim taslağı;
- kural tabanlı eksik adım kontrolü.

AI teknik kabul vermez, uygunsuzluk kapatmaz, tutar/miktar onaylamaz, resmî
mesaj göndermez, termin/sorumluyu sessiz değiştirmez. Mutasyonlar kullanıcı onayı,
geri alma ve event kaydı taşır.

**Kapı:** Kaynak gerektiren cevaplarda `%100` kaynak; kaynaksız kesin iddia `0`;
düşük güven görünür; deterministik arama AI olmadan çalışır.

---

## Faz 8 — Release 0.9: Planlama ve İş Cephesi Hazırlığı

Blok 17 Gün Planı Lite bu fazın günlük mobil temelidir; burada geniş planlama
modeline geçilir.

- iş programı içe aktarma;
- günlük plan ve 2–6 haftalık look-ahead;
- WBS-lite, plan revision, bağımlılık ve kısıt listesi;
- proje, malzeme, ekip, ekipman, mahal, önceki iş, kalite ve İSG hazırlığı;
- kaynak çakışması, plan/gerçekleşen, gecikme nedeni ve tahmin.

**AI-4:** Yeterli veri sonrası süre, darboğaz, malzeme, taşeron ve uygunsuzluk
riski. Her öneri veri, gerekçe, güven ve hareket gösterir.  
**Kapı:** Gerçek iki haftalık plan CSE'de yürür; hazırlıksız işler en az 48 saat
önce görünür; plan değişikliği geçmişi korunur.

---

## Faz 9 — Release 1.0: Operasyon Genişlemesi ve Ürünleştirme

- araç/makine/kiralık ekipman sicili, bakım, arıza, belge ve boşta kalma;
- hafif ihtiyaç–teklif–sipariş–teslim ve saha harcaması;
- güvenlik incelemesi sonrası süreli dış görev/fotoğraf bağlantıları;
- Hafıza paketi → PC salt-okunur → tek yönlü transfer → kanıtlı dar senkron;
- uygulama kilidi, şifreli backup, güvenli güncelleme, recovery drill;
- performans, depolama, pil, signing ve store submission.

Tam muhasebe, cari, çek/senet, bordro, tenant ve multi-user eklenmez.

**Kapı:** 30 günlük ana kullanım; veri kaybı `0`; kritik güvenlik blocker `0`;
recovery `PASS`; günlük rapor `≤3 dk`; haricî not/hatırlatıcıya dönüş düşük.

# 6. Zorunlu yatay kurallar

- Her günlük rapor P0–P3 olarak sınıflandırılır; roadmap sırası yalnız P0–P2 yoksa
  varsayılan production sırasıdır.
- Aynı anda yalnız bir production implementation Issue'su aktif olur.
- Her faz migration, backup/restore, event, revision, hash ve archive testlerinden geçer.
- Yeni saha özelliği internetsiz temel akışı tamamlamadan kapanmaz.
- Kayıt süresi, dokunma, vazgeçme ve tekrar giriş içerik toplamadan ölçülür.
- En az 44 px hedef, tek el, güneş, büyük metin, açık hata ve geri alma korunur.
- Detaydan listeye dönüşte kullanıcı bağlamı ve scroll konumu gereksiz yere sıfırlanmaz.
- Tek kayıt eylemi ilgisiz platform bildirimini kapatamaz.
- Arama alanı yalnız açık kullanıcı etkileşimiyle odak alır; scroll veya route dönüşü
  kendiliğinden klavye açamaz.
- Kullanıcı tarafından değiştirilen source kayıtları önceki/yeni değer geçmişi üretir;
  yayımlanmış geçmiş çıktılar sessizce yeniden yazılmaz.
- Proje/Mahal bağlantısı string kopyasıyla değil stable kimlikle kurulur.
- Uygulama kartı, bildirim ve widget aynı operation read-model'ini kullanır.
- Backup gibi uzun süren işlemler kullanıcıya görünür durum ve kesin sonuç verir.
- Otomatik hard-delete yoktur; kalıcı silme ayrı karar, veri envanteri, backup ve
  geri alınamazlık kapısı gerektirir.
- Checklist mutation otomatik log üretebilir; log, checklist state'inin ikinci
  düzenlenebilir gerçeği değildir.
- Checklist açık/tamamlanan sayaçları item durumlarından hesaplanır.
- Planlanan iş ile gerçekleşmiş Ajanda olayı ayrı source-of-truth olarak kalır.
- Tarihsel Ajanda logu sessizce yeniden yazılmaz; süreklilik İş Zinciriyle kurulur.
- Kişi/firma/etiket eşleşmesi öneridir; kullanıcı onayı olmadan bağ kurulmaz.
- Günlük Log Çıktısı, Backup ve AI prompt export ayrı artifact aileleridir.
- Aynı fiziksel attachment farklı modüller için çoğaltılmaz.
- Dar UI/metin işi schema veya tam release zincirini gereksiz yere tetiklemez.
- Persistence/schema değişikliği migration, rollback ve backup compatibility taşır.
- Physical smoke exact doğrulanmış artifact'i yeniden kullanır; hash/provenance
  geçerliyse gereksiz ikinci build başlatılmaz.
- Gerçek kullanıcı verisi GitHub, test fixture veya tanı çıktısına kopyalanmaz.

# 7. Backlog yerleşimi

### Hemen

1. #193 ve #245 saha kabulünü günlük raporlarla sürdür.
2. #268 / Draft PR #269'u yalnız exact scope'u ve açık doğrulama sınırı içinde
   PASS/FAIL güvenli sonuca getir; 29 Temmuz saha özelliklerini bu branch'e ekleme.
3. D29.1 Hatırlatıcı bildirim izolasyonu için ayrı P1 child Issue aç ve çöz.
4. D29.2 Ajanda arama odağı/klavye izolasyonunu ayrı P2 hotfix olarak çöz.
5. D29.3 Hatırlatıcı zaman/düzenleme sürtünmelerini küçük, test edilebilir child
   Issue'lara böl.
6. #257 → #254/#256 ve Draft PR #259 bloklu kalır; fiziksel smoke kanıtı olmadan
   Ready/merge yapılmaz.

### Sonraki kontrollü sıra

1. D29.4 Ajanda–Hatırlatıcı bağlantı görünürlüğü ve değişiklik geçmişi;
2. D29.5 Backup işlem görünürlüğü;
3. Proje ve Mahal Kataloğu v1;
4. Beton paketinde santral + mahal;
5. Açık Beton operasyon bildirimi ve hızlı mikser kaydı;
6. Beton widget'ı;
7. Ajanda–Hatırlatıcı kontrollü metin senkronu;
8. Günlük Log Çıktısı v1;
9. Ortak Attachment v2 + fotoğraf kırpma;
10. Proje fotoğraf/video albümü;
11. İş/Yapılacaklar ve otomatik log;
12. İş Zinciri / Bağlı Log v1;
13. Günlük Log Çıktısı v2;
14. #204 Sicil/Puantaj ve Saha Rehberi;
15. deterministik kişi/firma/etiket önerileri;
16. Telefon görüşmesi sonucu → Ajanda;
17. İstenecek Malzemeler;
18. Kaynaklı AI prompt export;
19. Mini hesap makinesi;
20. ardından Faz 1 Universal Capture, Voice Capture/Assistant Inbox ve Faz 2 Open Loop.

Özel bildirim sesleri, kullanıcı asset'leri hazır olduğunda D29.1 sonrasında uygun
dar pencerede uygulanabilir.

### Non-blocking eşlikçi iş

- Başlangıç ekranı Saha İpuçları uygun dar UI penceresinde yapılabilir; veri omurgası
  veya P1/P2 hotfix sırasını bekletmez.

### Ertelenen

- Hava durumu servisi ve proaktif uyarılar; önce konum, cache/offline fallback,
  eşik ve kullanıcı bildirim tercihleri tasarlanır.
- Gömülü/doğrudan AI servis çağrısı; ilk adım yalnız kaynaklı prompt export'tur.
- Tam satın alma/ERP, gelişmiş video işleme ve otomatik medya analizi.
- Güvenli, salt-okunur gömülü DWG/Office/proje dokümanı viewer.
- İki yönlü PC sync, PDF metraj ve ileri mühendislik hesapları.

### Kapsam dışı / yapılmaması gerekenler

- Reminder içinde legacy `Bekliyorum` durumunu yeniden canlandırmak.
- Kullanıcıya görünmeden otomatik hard-delete, otomatik kayıt kapatma veya sessiz
  veri mutasyonu.
- Bağlı verili projeyi yalnız parola sorarak kalıcı silmek.
- Beton kelimesinden otomatik Beton paketi/kaydı veya teknik karar üretmek.
- Tamamlanmış checklist'i ikinci ve stale bir sayaçla açık göstermeye devam etmek.
- Aynı fiziksel attachment'ı Ajanda, Hatırlatıcı, Beton, Sicil veya albüm için çoğaltmak.
- Sınırsız derinlikte checklist ağacı kurmak.
- Eski Ajanda logunu son durumla sessizce yeniden yazmak.
- Sistem Call Log geçmişini okumak veya `READ_CALL_LOG` istemek.
- Arama yapıldı varsayımıyla kullanıcı onayı olmadan Ajanda kaydı oluşturmak.
- Gün Planı maddesini otomatik olarak gerçekleşmiş saha olayı saymak.
- Kullanıcı onayı olmadan kişi/firma/etiket bağlamak.
- Kaynaksız AI raporu, kullanıcı onayı olmadan AI mutasyonu veya embedded AI'yı
  erken eklemek.
- Tam ERP, multi-user/tenant/SaaS, BIM/DWG/Office düzenleme, authoring ve teknik
  karar motoru.

# 8. Release 0.1 sonrası ilk Issue kuyruğu

Release 0.1.1 günlük güvenilirlik/sadeleştirme kuyruğu:

1. #221 Reminder scheduling contract — tamamlandı;
2. #225 birleşik ve sade Bugün — tamamlandı;
3. #227 reminder trash/restore — tamamlandı;
4. #230 Ajanda → reminder kaynak attachment görünürlüğü — tamamlandı;
5. #234 Beton sınıfı ve zaman çizgisi — tamamlandı;
6. #237 Beton keyword önerisi/deep-link — tamamlandı;
7. #252 / PR #253 Hatırlatıcı hızlı eylem netliği — tamamlandı;
8. #260 / PR #261 Beton checklist source-of-truth — tamamlandı;
9. #262 / PR #263 Hatırlatıcı kaynak/tarih uygunluğu — tamamlandı;
10. #264 / PR #265 liste ve navigasyon durumu — tamamlandı;
11. #266 / PR #267 Türkçe kullanıcı dili ve kayıt eylemleri — tamamlandı;
12. #268 / Draft PR #269 Ajanda sıralama seçeneği — açık;
13. Ajanda–Hatırlatıcı kontrollü metin senkronu;
14. Günlük Log Çıktısı v1;
15. Ortak Attachment v2;
16. Proje fotoğraf/video albümü;
17. Ajanda Gün Planı Lite;
18. İş Zinciri / Bağlı Log v1;
19. Günlük Log Çıktısı v2;
20. #204 Sicil/Puantaj ve Saha Rehberi;
21. deterministik kişi/firma/etiket önerileri;
22. Telefon görüşmesi sonucu → Ajanda;
23. İstenecek Malzemeler;
24. Kaynaklı AI prompt export;
25. Mini hesap makinesi;
26. Hava durumu uyarıları — ertelenmiş.

### 29 Temmuz saha dalgası

- D29.1 Hatırlatıcı bildirim izolasyonu — P1;
- D29.2 Ajanda arama odağı ve klavye izolasyonu — P2;
- D29.3 Hatırlatıcı zaman/düzenleme sürtünmesi — P2;
- D29.4 Ajanda–Hatırlatıcı bağlantı görünürlüğü ve değişiklik geçmişi;
- D29.5 Backup işlem görünürlüğü;
- Proje ve Mahal Kataloğu v1;
- Beton santral/mahal ve canlı operasyon yüzeyi;
- İş/Yapılacaklar/otomatik log standardizasyonu;
- Ortak Attachment fotoğraf kırpma;
- Özel bildirim sesleri — asset-dependent.

Günlük güvenilirlik kapısından sonraki mevcut ürün sırası:

1. Universal Capture contract and mobile shell;
2. Voice Capture and Assistant Inbox;
3. Open Loop model;
4. Morning Briefing and Evening Close;
5. Context hierarchy and Big Picture read-model;
6. Big Picture Home v1;
7. Material Delivery vertical;
8. Sample and Laboratory vertical;
9. General Work Package engine.

# 9. Nihai navigasyon

```text
Bugün | Saha | + Kaydet | Takip | Asistan
```

Malzeme, kalite, İSG, evrak ve ekipman ayrı ana ikon yığını oluşturmaz; ilgili iş
paketi, Saha, arama, Asistan veya ikincil `Tüm araçlar` alanından açılır.

# 10. Başarı ölçütleri

| Ölçüt | Hedef |
|---|---:|
| Günlük saha raporu işleme | Her aktif gün |
| Ana iş akışını durduran açık P1 | `0` |
| Tek Hatırlatıcı eyleminde ilgisiz notification kaybı | `0` |
| Açık arama dokunuşu olmadan Ajanda klavyesi açılması | `0` |
| Checklist sayaç/source ayrışması | `0` |
| Detaydan dönüşte bağlam kaybı | `0` |
| Ajanda mutation'ında kullanıcı-okur değişiklik geçmişi | `%100` |
| Proje filtresinde yanlış Hatırlatıcı gösterimi | `0` |
| Backup sırasında görünür durum olmadan bekleme | `0` |
| App / notification / widget Beton read-model ayrışması | `0` |
| Yapılacak mutation'ında eksik otomatik İş logu | `0` |
| Otomatik veya envantersiz proje hard-delete | `0` |
| Hızlı kayıt ortancası | `≤10 sn` |
| Evrensel Yakalama oranı | `≥%80` |
| Sabah saha hâkimiyeti | `≤30 sn` |
| Bilinen kaydı bulma | `≤5 sn` |
| Günlük rapor | `≤3 dk` |
| Takip tarihi/terminal durumu olan açık döngü | `%100` |
| Ajanda–Hatırlatıcı bağlı metin ayrışması | `0` |
| Duplicate fiziksel attachment | `0` |
| Tarihsel logun sessiz yeniden yazılması | `0` |
| Kullanıcı onaysız kişi/firma/etiket bağı | `0` |
| Sessiz AI mutasyonu | `0` |
| Kaynaksız AI proje iddiası | `0` |
| Pilot veri kaybı | `0` |

# 11. Kesin kapsam dışı

- tam muhasebe veya şirket ERP'si;
- çok kullanıcılı tenant/SaaS;
- bordro, cari ve çek/senet;
- resmî onay veya teknik kabul motoru;
- BIM/DWG/Office düzenleme, authoring ve teknik karar motoru;
- otomatik iki yönlü PC senkronu;
- otomatik hard-delete veya Beton kelimesinden otomatik kayıt/paket;
- aynı fiziksel attachment'ın modüller arasında kopyalanması;
- sistem Call Log geçmişinin okunması;
- kullanıcı yerine karar veren, kaynak göstermeyen veya sessiz mutasyon yapan AI.

Başarı modül sayısıyla değil, şefin daha az zihinsel yükle daha hızlı, eksiksiz ve
kanıtlı saha yönetimi yapmasıyla ölçülür.
