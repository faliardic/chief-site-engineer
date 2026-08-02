# CSE 2026.3.4 — Asistan-Öncelikli Ürün Yol Haritası

**Durum:** Kanonik ürün sırası  
**Tarih:** 31 Temmuz 2026\
**Ürün Epic'i:** #105  
**Yürütme Epic'i:** #127  
**Güncel saha backlog'u:** #219  
**Önceki saha backlog'u:** #203  
**Açık Release 0.1 pilotu:** #193  
**Güncel RC / günlük saha testi:** #245  
**Roadmap senkronizasyonu:** #280 / PR #281\
**Son merge edilen production işi:** #277 / PR #278 — exact reminder hızlı planlama zamanları\
**Son merge edilen dokümantasyon işi:** #280 / PR #281 — README ve NotebookLM current-state senkronizasyonu\
**Aktif production işi:** Issue #279 — implementation ve tablet-only completion PASS; Draft PR aşamasında\
**Sıradaki production işi:** #279 merge/closure sonrasında ayrı GitHub yetkisiyle seçilecek\
**Bloklu yatay kabul zinciri:** #257 → #254 / #256, Draft PR #259

## CSE Orchestrator programı

- O0-O8 MVP, Issue #285, #287, #289, #291, #293 ve #295 zincirinde merged
  source üzerinde tamamlandı.
- Issue #297, exact pytest action'ını gerçek subprocess adapter ile tek kez
  çalıştıran ilk controlled live pilot kanıtıdır: O3 `30/30` PASS, external
  ledger verification PASS ve duplicate execute subprocess öncesi BLOCKED.
- Issue #299, O9 Responses API planner, local proposal revalidation, gerçek
  Codex child adapter, GitHub REST Draft PR client ve `api-run` CLI
  implementation'ını tamamlar. Default dry-run ve ayrı explicit execute
  kapıları korunur.
- Credential yokluğunda O9 live pilot `CREDENTIALS_MISSING` kalır; secret
  istenmez veya üretilmez. Production/mobile source, build ve device kapsamı
  genişlemez.
- O10 service/tray ayrı Issue, capability ve approval sözleşmesi gerektirir.

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
- #266 / PR #267 — Türkçe kullanıcı dili, Puantaj `Kaydet` eylemi ve seçim toolbar'ı;
- #268 / PR #269 — Ajanda deterministik sıralama;
- #272 / PR #274 — Hatırlatıcı bildirim izolasyonu;
- #275 / PR #276 — Ajanda arama odağı ve klavye izolasyonu;
- #277 / PR #278 — ertesi gün ve hafta başı exact `08:00` hızlı planlama;
- #279 — Hatırlatıcı detayında güvenli `Erkene al` ve açık geçmiş-zaman onayı;
  implementation ve tablet-only completion PASS, henüz merge edilmedi.

Güncel güvenli `master`:

```text
86d39b85e388e3ab44b985c63544f0fc5a1f8d5c
```

Bu master noktası #277 / PR #278 exact reminder hızlı planlama davranışını ve
#280 / PR #281 README/NotebookLM current-state senkronizasyonunu taşır.
`Yarın sabah` ve timed `Yarın 08:00` ertesi Europe/Istanbul günü `08:00`;
`Hafta başına ertele` sonraki pazartesi `08:00` üretir. Son merged production
kanıtı focused lifecycle `48/48`, focused widget `46/46`, Beton regression
`1/1`, Flutter full suite `333/333`, Flutter analyze `0` ve Samsung `SM-X610`
tablet wide smoke PASS'tir. Mobil schema `10`, backup formatı `1` ve migration
`0` korunmuştur.

Issue #279 birleşmemiş aktif production işidir. `Erkene al`, same/later
rejection ve ayrı geçmiş-zaman onayı implementation'ı tamamlanmış; rebase
sonrası focused lifecycle `52/52`, focused widget `51/51`, full Flutter
`342/342`, analyze ve exact allowlist kapıları PASS olmuştur. Rebase öncesi
Samsung `SM-X610` tablet kabulü, production/test blob eşitliği `6/6`
kanıtlandığı için yeniden kullanılmıştır. Yeni build/install/tablet smoke ve
telefon promotion yapılmamıştır.

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

### Yatay geliştirme yönetişimi — CSE Development Orchestrator

Issue #285 ile başlayan O0–O10 programı, production ürün fazlarının yerine
geçmeyen yatay bir geliştirme-güvenliği katmanıdır. İlk amaç otomatik kod
yazmak değil; mevcut CSE scope, approval, provenance, evidence reuse, retry ve
fail-closed kurallarını makine tarafından doğrulanabilir hâle getirmektir.

```text
O0 mimari/güvenlik sözleşmesi
→ O1 read-only observer
→ O2 state/policy engine
→ O3 sonuç parser'ları
→ O4 sanitized #284 replay
→ O5 Codex dry-run
→ O6 controlled Codex
→ O7 commit/build/device gates
→ O8 GitHub evidence/Draft PR
→ O9 OpenAI API planner
→ O10 opsiyonel Windows operasyon yüzeyi
```

O0–O4 deterministik oracle katmanıdır ve OpenAI API kullanmaz. Her Orchestrator
fazı ayrı Issue, exact capability/allowlist, Fatih approval'ı ve minimum yeterli
validation planı gerektirir. Bu program açık production Issue sırasını,
Release 0.1 kabulünü veya gerçek saha backlog'unu sessizce değiştirmez.

Issue #287 ile O1 read-only observer implementation'ı; strict authorization v1,
tracked-only Git, GET-only GitHub, exact record metadata, sanitized Observation
v1 ve repository-dışı atomik runtime output sınırında başlatılmıştır. O1 policy
veya action runner değildir; full Python/live integration, checkpoint ve publish
ayrı approval kapılarında kalır.

Issue #289 ile O2 state/policy engine; O0 transition tablosunu executable hâle
getirir ve immutable Observation/authorization girdisinden approval,
capability, drift, budget, retry, evidence reuse ve blocker precedence kararı
üretir. O2 action çalıştırmaz, approval tüketmez, dış I/O yapmaz ve persistence
kurmaz; O3 result parser ile sonraki controlled runner fazlarının ön koşuludur.

Issue #291 ile O3 result parser; frozen `pytest`, `compileall`,
`git_diff_check`, Flutter test/analyze, build ve generic command output'unu
proven-only count, failure class, budget evidence, stream hash ve bounded
sanitized excerpt içeren canonical result'a çevirir. O3 action çalıştırmaz,
policy/state kararı vermez veya persistence kurmaz; O4 sanitized replay ve
sonraki controlled runner fazlarına deterministic evidence sağlar.

Issue #293 ile O4 sanitized replay; Issue #284'ün exact 19 comment
authorization/result/correction zincirini raw body veya gerçek kullanıcı/device
verisi taşımayan fixture üzerinden tekrar hesaplar. Latest-valid supersession,
source precedence, budget/retry, result class, evidence reuse ve checkpoint
provenance fail-closed doğrulanır. O4 action çalıştırmaz ve tarihsel Issue'yu
tamamlanmış saymaz; frozen checkpoint ile açık `DEVICE` gate'ini korur.

Issue #295 ile O5-O8 zorunlu MVP; deterministic ActionPlan, repository dışı
append-only admission/result ledger, injected controlled runner, ayrı
checkpoint/build/device gate planları ve normal push + tek Draft PR publish
adapter'ını O1-O4 oracle zincirine bağlar. Default dry-run, exact argv,
source/action fingerprint recheck, one-time approval/budget ve data-minimal O3
result sınırları executable olur. Gerçek Codex/build/device/GitHub action'ı
validation sırasında çalıştırılmaz. Issue #299 ile O9 OpenAI planner ve
controlled API/Codex/GitHub adapter zinciri eklenir; O10 opsiyonel Windows
operasyon yüzeyi zorunlu MVP dışında kalır.

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
3. **Hatırlatıcı geri dönüşüm kutusu — tamamlandı:** recoverable trash/restore ve
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

12. **Ajanda sıralama seçeneği — tamamlandı**
    - Yeni route varsayılanı `En yeni üstte`; kullanıcı `En eski üstte`
      seçebilir.
    - Seçim route-local kalır ve detay dönüşünde gün, proje, tür, aktif/arşiv,
      literal arama ve scroll bağlamıyla birlikte korunur.
    - Sıra `observed_at`, `created_at`, `id` alanlarıyla application query
      katmanında deterministiktir; `updated_at` ve client-side `reverse()`
      kullanılmaz.
    - Cold restart tercihi ve günlük çıktı sıralaması bu dar Issue'nun kapsamı
      dışındadır.

Hotfix Blokları 8–12 tamamlanmıştır. Günlük raporda yeni P0/P1 bulunursa sonraki
P2/P3 işlerin önüne geçer.

### 29 Temmuz 2026 günlük saha dalgası

Bu dalga mevcut Blok 13–26 numaralarını değiştirmez. D29.2 / Issue #275 aktif
tek production işidir; diğer başlıklar ayrı ve dar child Issue'lara bölünür.

#### D29.1 — Hatırlatıcı bildirim izolasyonu — P1 / Issue #272

- **Durum:** Tamamlandı ve #272 / PR #274 ile `master`a merge edildi.
- Bir Hatırlatıcı tamamlandığında yalnız kendi platform bildirimi kapanır.
- Diğer aktif ve görünür Hatırlatıcı bildirimleri korunur.
- Tek kayıt eyleminde genel `cancelAll` veya eşdeğer toplu iptal kullanılmaz.
- Reminder UUID ile platform notification ID bağı tekil ve kalıcıdır.
- Restart ve reconciliation ilgisiz aktif bildirimleri silemez.
- Teslim edilmiş aktif one-time notification ile terminal notification ayrılır.
- Bir bildirimin `pendingNotificationRequests()` içinde bulunmaması tek başına
  terminal olduğunun kanıtı değildir.
- Üç görünür bildirimle tamamla, ertele, iptal, restart ve deep-link matrisi
  doğrulanır.

**Kapı:** İlgisiz notification kaybı `0`. Bu P1 kapanmadan yeni P3 özelliğe
geçilmez.

#### D29.2 — Ajanda arama odağı ve klavye izolasyonu — P2

- **Durum:** Dar UI düzeltmesi, focused/full doğrulama ve Samsung `SM-X610`
  tablet automated wide smoke PASS; Draft PR incelemesi bekliyor. Telefon
  promotion kullanıcı tarafından ayrı talebe kadar ertelendi ve yapılmadı.
- Detaydan geri dönmek klavyeyi kendiliğinden açamaz.
- Arama metni route-local korunabilir; odak, imleç ve klavye kullanıcı açıkça
  arama alanına dokunmadıkça geri gelmez.
- Hızlı scroll, momentum scroll ve yön değiştirme arama alanını aktifleştiremez.
- Scroll gesture ile search tap gesture birbirinden ayrılır.
- Uzun liste, küçük ekran, büyük metin ve detail mutation sonrası dönüş test edilir.

**Kapı:** Kullanıcı açıkça aramaya dokunmadan klavye açılması `0`. Tablet PASS
bu Issue'nun yetkili fiziksel tamamlanma kapısıdır.

#### D29.3 — Hatırlatıcı zaman ve düzenleme sürtünmesi — P2

- `Yarın sabah` exact ertesi yerel gün `08:00` anlamına gelir. #277 / PR #278
  ile tamamlandı.
- `Hafta başına ertele` exact sonraki pazartesi `08:00` anlamına gelir.
  #277 / PR #278 ile tamamlandı.
- Uygulanacak kesin tarih ve saat işlemden önce gösterilir. #279 ile
  implementation ve tablet-only completion PASS.
- Hatırlatıcı, tam forma girmeden güvenli biçimde erkene alınabilir. #279 ile
  implementation ve tablet-only completion PASS.
- Geçmiş zamana düşen seçim açık onay olmadan kaydedilmez. #279 ile
  implementation ve tablet-only completion PASS.
- Düzenleme ekranında `Tam gün` seçeneği bulunur.
- Tam gün kayıtları ilgili gün içinde saatli kayıtların üstünde gösterilir;
  gecikmiş/kritik bölüm sessizce aşağı itilmez.
- Hatırlatıcı listesi `Tüm projeler`, aktif proje ve `Projesiz` filtrelerini taşır.
- Arşivli projeler varsayılan aktif filtreye girmez.
- Filtre, arama, sıralama ve detail dönüşü route-local korunur.

#### D29.4 — Ajanda–Hatırlatıcı görünürlüğü ve değişiklik geçmişi

- Bağlı Hatırlatıcısı bulunan Ajanda kartında erişilebilir bir gösterge bulunur.
- Gösterge yalnız gerçek source link'ten beslenir ve ilgili Hatırlatıcı detayına gider.
- Ajanda mutation geçmişi değişiklik zamanı, değişen alan, önceki değer ve yeni
  değeri taşır.
- Geçmiş kullanıcı tarafından değiştirilemez; event/revision zincirinden üretilir
  veya onunla atomik tutulur.
- Eski günlük/log çıktıları sessizce yeniden yazılmaz.

#### D29.5 — Backup işlem görünürlüğü

- Yedek oluşturulurken ayrı bekleme/ilerleme yüzeyi açılır.
- Gerçek yüzde yoksa sahte yüzde gösterilmez.
- Görünür aşamalar `hazırlanıyor`, `paketleniyor`, `bütünlük kontrolü yapılıyor`
  ve `kaydediliyor` şeklindedir.
- Aynı anda ikinci backup başlatılamaz.
- Geri/çıkış davranışı açıkça belirtilir.
- Başarıda dosya adı, konumu ve zaman; hatada dosyanın oluşup oluşmadığı gösterilir.
- Backup formatı, manifest, parola ve restore compatibility değişmez.

### Proje ve Mahal Kataloğu v1 — P3 temel omurga

- Proje düzenlenebilir, arşivlenebilir ve arşivden çıkarılabilir.
- Arşivleme hiçbir bağlı veriyi silmez.
- Proje bazlı stable-ID Mahal Kataloğu oluşturulur.
- Mahal stable ID, ad, isteğe bağlı üst bağlam ve aktif/arşiv durumu taşır.
- Aynı mahal Ajanda, Hatırlatıcı, Beton, İş ve fotoğraf kayıtlarında seçilebilir.
- Mahal adı değişse bile tarihsel kimlik kopmaz; sessiz string çoğaltma yapılmaz.

#### Kalıcı proje silme — fail-closed karar kapısı

1. Kesin kapsam düzenle, arşivle ve arşivden çıkardır.
2. İlk güvenli hard-delete adayı yalnız bağlı verisi `0` olan boş/test projesidir.
3. Bağlı verili proje ilk implementation'da yalnız arşivlenir.
4. Parola tek başına veri güvenliği sayılmaz.
5. Gelecekte bağlı verili silme değerlendirilirse bağlı veri envanteri, doğrulanmış
   backup, geri alınamazlık onayı ve güvenlik parolası birlikte gerekir.
6. Otomatik cascade hard-delete yapılmaz.

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
    - Fotoğraf kırpma ve döndürme desteklenir.
    - Mümkünse orijinal fiziksel dosya korunur; kırpılmış sürüm kayıt gösteriminde
      kullanılabilir.
    - Managed storage, hash/MIME/boyut, archive ve backup/restore round-trip korunur.
    - Belge perspektif düzeltmesi sonraki ayrı dar iş olarak kalır.
    - Aynı fiziksel dosya farklı modüller için kopyalanmaz.
    - Bir fotoğraf açıldığında aynı kaydın medyaları arasında sağa/sola kaydırılan
      viewer, dokunulan fotoğraf indeksinden başlar ve integrity hatasını gizlemez.

16. **Proje fotoğraf/video albümü**
    - Proje, tarih, kategori ve kaynak kayıt bağlantısıyla medya görünümü.
    - Thumbnail, sayfalama, swipe viewer ve kaynak kayda geri bağlantı.
    - Blok 15 tamamlanmadan başlamaz; fiziksel dosya ikinci kez kopyalanmaz.

### Günlük plan ve iş sürekliliği

17. **Ajanda Gün Planı Lite / İş ve Yapılacaklar**
    - `Günlük Kayıtlar | Gün Planı` görünümü.
    - İş üst kaydı proje, mahal, gün, başlık, açıklama, öncelik, sıra, hedef tarih
      ve durum alanları taşır.
    - İş içinde ayrı Yapılacak listesi bulunur; ilk sürüm derinliği en fazla
      `İş → Yapılacak → Alt yapılacak` olur.
    - Alt kalemler varsa üst ilerleme onlardan hesaplanır; bağımsız ikinci sayaç yoktur.
    - `Tümünü tamamla` atomik çalışır; zorunlu açık kalem varken ana iş sessizce
      tamamlanmaz. Gerekçeli override açık event üretir.
    - Yapılacak tamamlandığında aynı İşe bağlı otomatik, append-only log oluşur.
    - Otomatik log en az zaman, eylem, önceki durum, yeni durum ve source item
      kimliğini taşır.
    - Kullanıcı ayrıca açıklama, fotoğraf veya belge ekleyebilir.
    - Yapılacak durumu source-of-truth'tur; log ikinci düzenlenebilir sayaç değildir.
    - Plan maddesinden Hatırlatıcı oluşturma.
    - Yalnız kullanıcı onayıyla `Gerçekleşti ve Ajandaya kaydet`.
    - Planlanan iş, gerçekleşmiş Ajanda olayı sayılmaz.
    - İş, proje, mahal, Hatırlatıcı ve tarihsel Ajanda kayıtlarıyla bağlanabilir.
    - İlk sürüm sınırsız checklist ağacı veya Gantt değildir.

18. **İş Zinciri / Bağlı Log v1**
    - Birden çok tarihsel Ajanda logu tek `work_thread` veya eşdeğer üst kayda bağlanır.
    - Örnek akış: `başladı/devam ediyor → ilerleme → tamamlandı`.
    - Eski logun metni sessizce yeniden yazılmaz; her log gerçekleştiği anı korur.
    - İş Zinciri `Açık | Tamamlandı | İptal` durumunu taşır.
    - Kullanıcı `Bu işi açık iş olarak takip et`, `Mevcut işe bağla` ve
      `Bu işi tamamladı` eylemlerini açıkça seçer.
    - Aynı İşin otomatik Yapılacak logları, manuel ilerleme logları ve ilişkili
      Ajanda olayları tek kronolojik görünümde birleşir.
    - Otomatik log silinmez veya geriye dönük değiştirilmez; düzeltme yeni event'tir.
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

- Kullanıcı ses asset'lerini daha sonra sağlayacaktır.
- D29.1 notification isolation tamamlanmadan başlanmaz.
- Bu roadmap adımında asset veya platform kodu eklenmez.
- İleride Hatırlatıcı, Beton ve kritik iş bildirimleri ayrı kontrollü kanallar
  veya tercihlerle değerlendirilebilir.

**Kapı:** Blok 1–25 ve önlerindeki D29 güvenilirlik işleri ayrı, dar ve doğrulanmış
child Issue'larla tamamlanmadan Faz 1 production implementation'ı başlamaz. Blok
26 kanonik sırada korunur fakat haricî servis/eşik tasarımı nedeniyle ertelenmiş
iştir. Saha İpuçları hard gate değildir.

Aktif tek production işi **D29.1 / Issue #272**'dir. Doğrulanan değişiklik merge
edilmeden D29.2 başlamaz. #257 → #254/#256 yatay kabul zinciri Draft PR #259
içinde bloklu kalır ve #272 kapsamına taşınmaz.

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

Açık Beton dökümü, bildirim panelinde devam eden operasyon olarak görünür:

- uygulama içi canlı kart, Android notification ve sonraki widget aynı read-model'den
  beslenir; birbirinden bağımsız üç state sistemi kurulmaz;
- read-model proje, mahal, santral, hedef beton, dökülen beton, kalan beton,
  mikser sayısı ve son mikser zamanını üretir;
- notification doğru paket/revision kimliğiyle `Mikser ekle`, `İrsaliye ekle`,
  `Fotoğraf çek`, `Paketi aç` ve `Dökümü bitir` akışlarını açabilir;
- persistent operasyon bildirimi D29.1 tamamlanmadan production'a alınmaz;
- Beton widget'ı notification lifecycle ve canlı Beton read-model'i kararlı hale
  geldikten sonra yapılır.

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
- santral ve stable-ID mahal bağlantısı;
- hedef beton, dökülen beton ve kalan beton;
- aynı plakanın farklı gelişleri dahil mikser yaşam döngüsü;
- mikser sayısı, son mikser zamanı ve hızlı mikser kaydı;
- irsaliye, fotoğraf ve açık dökümü bitirme;
- EBİS, numune, laboratuvar ve yapı denetim;
- versiyonlu numune önerisi ve gerekçeli override;
- kür, sonuç, eksik belge, rapor ve canlı ana ekran kartı;
- uygulama kartı, notification ve widget için tek source/read-model;
- widget açık paket, dökülen/kalan beton, mikser sayısı ve paketi açma eylemini
  gösterebilir; ayrı state veya sayaç tutmaz;
- paket kapandığında yalnız ilgili notification/widget operasyonu kaldırılır.

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
- Arama alanı yalnız açık kullanıcı etkileşimiyle odak alır; scroll veya route
  dönüşü kendiliğinden klavye açamaz.
- Kullanıcı tarafından değiştirilen source kayıtları önceki/yeni değer geçmişi
  üretir; yayımlanmış geçmiş çıktılar sessizce yeniden yazılmaz.
- Proje/Mahal bağlantısı string kopyasıyla değil stable kimlikle kurulur.
- Uygulama kartı, notification ve widget aynı operation read-model'ini kullanır.
- Backup gibi uzun süren işlemler kullanıcıya görünür durum ve kesin sonuç verir.
- Otomatik hard-delete yoktur; kalıcı silme ayrı karar, veri envanteri, backup ve
  geri alınamazlık kapısı gerektirir.
- Yapılacak mutation'ı otomatik log üretebilir; log, Yapılacak durumunun ikinci
  düzenlenebilir gerçeği değildir.
- Checklist açık/tamamlanan sayaçları item durumlarından hesaplanır.
- Planlanan iş ile gerçekleşmiş Ajanda olayı ayrı source-of-truth olarak kalır.
- Tarihsel Ajanda logu sessizce yeniden yazılmaz; süreklilik İş Zinciriyle kurulur.
- Kişi/firma/etiket eşleşmesi öneridir; kullanıcı onayı olmadan bağ kurulmaz.
- Günlük Log Çıktısı, Backup ve AI prompt export ayrı artifact aileleridir.
- Aynı fiziksel attachment farklı modüller için çoğaltılmaz.
- Dar UI/metin işi schema veya tam release zincirini gereksiz yere tetiklemez.
- Persistence/schema değişikliği migration, rollback ve backup compatibility taşır.
- Physical smoke exact doğrulanmış artifact'i yeniden kullanır; hash/provenance geçerliyse
  gereksiz ikinci build başlatılmaz.
- Gerçek kullanıcı verisi GitHub, test fixture veya tanı çıktısına kopyalanmaz.

# 7. Backlog yerleşimi

### Hemen

1. #193 ve #245 saha kabulünü günlük raporlarla sürdür.
2. D29.1 / Issue #272 Hatırlatıcı bildirim izolasyonunun Draft PR review/merge
   kararını tamamla.
3. D29.2 Ajanda arama odağı/klavye izolasyonuna yalnız #272 merge sonrasında ayrı
   P2 hotfix olarak başla.
4. D29.3 Hatırlatıcı zaman/düzenleme sürtünmelerini küçük, test edilebilir child
   Issue'lara böl.
5. #257 → #254/#256 ve Draft PR #259 bloklu kalır; fiziksel smoke kanıtı olmadan
   Ready/merge yapılmaz.

### Sonraki kontrollü sıra

1. D29.4 Ajanda–Hatırlatıcı görünürlüğü ve değişiklik geçmişi;
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
- Aynı fiziksel attachment'ı Ajanda, Hatırlatıcı, Beton, Sicil veya albüm için
  çoğaltmak.
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
12. #268 / PR #269 Ajanda sıralama seçeneği — tamamlandı;
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

- D29.1 / Issue #272 Hatırlatıcı bildirim izolasyonu — P1;
- D29.2 Ajanda arama odağı ve klavye izolasyonu — P2;
- D29.3 Hatırlatıcı zaman/düzenleme sürtünmesi — P2;
- D29.4 Ajanda–Hatırlatıcı görünürlüğü ve değişiklik geçmişi;
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
- bağlı verili projeyi yalnız parola sorarak kalıcı silme;
- aynı fiziksel attachment'ın modüller arasında kopyalanması;
- sistem Call Log geçmişinin okunması;
- kullanıcı yerine karar veren, kaynak göstermeyen veya sessiz mutasyon yapan AI.

Başarı modül sayısıyla değil, şefin daha az zihinsel yükle daha hızlı, eksiksiz ve
kanıtlı saha yönetimi yapmasıyla ölçülür.
