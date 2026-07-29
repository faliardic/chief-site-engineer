# Issue #270 — Roadmap 2026.3.4 / 29 Temmuz Günlük Saha Geri Bildirimi VI

## Amaç

29 Temmuz 2026 günlük saha raporundaki 19 bulguyu, PR #269 sonrasında güncellenen
kanonik `ROADMAP.md` üzerine conflict-safe biçimde yerleştirmek ve ürün sırasını
P1 güvenilirlik → P2 günlük sürtünme → P3 ortak omurga/dikeyler şeklinde korumak.

Bu çalışma yalnız dokümantasyon değişikliğidir. Production/test kodunu,
notification runtime davranışını, mobil schema'yı, migration'ı, backup formatını
veya kullanıcı verisini değiştirmez.

## Güncel güvenli başlangıç noktası

- Repository: `faliardic/chief-site-engineer`
- Base branch: `master`
- Base commit: `438f0222f1a82c9dfa7ab53550d2b151daadaf18`
- Issue #268: `completed / closed`
- PR #269: `merged`
- Son tamamlanan production işi: #268 / PR #269 — Ajanda deterministik sıralama
- Sıradaki tek production işi: D29.1 / Issue #272 — bağımsız Hatırlatıcı bildirim
  yaşam döngüsü
- Bloklu yatay kabul: #257 → #254 / #256, Draft PR #259
- Mobil schema: `10`
- Backup formatı: `1`
- Migration: `0`

Birleşmiş güncel kanıt:

- Static configuration: `5 PASS`
- Focused Agenda: `42 PASS`
- Combined focused: `47 PASS`
- Flutter full suite: `308 PASS`
- Flutter analyze: `PASS`
- Son geçerli merged Python suite: `1005 passed, 7 skipped`

Issue #268 ile yeni Ajanda route varsayılanı `En yeni üstte` olmuştur; kullanıcı
`En eski üstte` seçebilir. Application query sırası `observed_at`, `created_at`,
`id` alanlarıyla deterministiktir; `updated_at` sıralamaya girmez. Filtre, arama,
sort ve detail dönüşü route-local korunur. Schema, migration ve backup formatı
değişmemiştir.

## Conflict-safe uygulama kararı

Eski Draft PR #271, PR #269'un da `ROADMAP.md` dosyasını değiştirmesi nedeniyle
current master ile conflict durumuna düşmüştür. Eski branch:

```text
agent/issue-270-roadmap-field-feedback-vi-canonical
```

yalnız read-only içerik karşılaştırma kaynağı olarak kullanılmıştır. Commit veya
dosya cherry-pick edilmemiş, branch merge/rebase edilmemiş ve eski `ROADMAP.md`
current master üzerine kopyalanmamıştır.

Targeted rebuild doğrudan
`438f0222f1a82c9dfa7ab53550d2b151daadaf18` üzerine uygulanmıştır. Böylece
Issue #268 / PR #269 tamamlanma kaydı ve deterministik Ajanda sıralama sözleşmesi
korunurken 29 Temmuz katmanı eklenmiştir.

## 19/19 saha bulgusu eşleme tablosu

| No | Saha bulgusu | Roadmap karşılığı | Öncelik / bağımlılık |
|---:|---|---|---|
| 1 | Backup sırasında bekleme/yükleme ekranı | D29.5 Backup işlem görünürlüğü | P2; backup formatı değişmez |
| 2 | Mahal oluşturup tekrar kullanma | Proje ve Mahal Kataloğu v1 | P3 ortak kimlik omurgası |
| 3 | Beton paketinde santral adı | Beton Paketi v2 | P3; Mahal Kataloğu sonrasında |
| 4 | Ajanda düzenleme değişiklik geçmişi | D29.4 | Event/revision tabanlı |
| 5 | `Yarın sabah` = 08:00 | D29.3 | P2; exact yerel zaman |
| 6 | Hatırlatıcıları projeye göre listeleme | D29.3 | P2; tüm/aktif/projesiz |
| 7 | Açık Betonun bildirim panelinde görünmesi | Faz 3 canlı Beton operasyonu | D29.1 sonrasında |
| 8 | Beton widget'ı | Beton Paketi v2 | Tek read-model; ayrı state yok |
| 9 | Ajanda kartında bağlı Hatırlatıcı işareti | D29.4 | Gerçek source link |
| 10 | Proje düzenle/arşivle/sil | Proje yaşam döngüsü karar kapısı | Hard-delete fail-closed |
| 11 | Detay dönüşünde arama odağı/klavye | D29.2 | P2 hotfix |
| 12 | Hızlı scroll ile aramanın aktif olması | D29.2 | P2 gesture izolasyonu |
| 13 | Hatırlatıcıyı erkene almanın zahmetli olması | D29.3 | P2 hızlı güvenli eylem |
| 14 | Düzenlemede Tam gün ve listede üstte görünüm | D29.3 | P2 all-day sözleşmesi |
| 15 | Bir Hatırlatıcı tamamlanınca tüm bildirimlerin kaybolması | D29.1 / #272 | P1; ilk production işi |
| 16 | İş içinde Yapılacaklar ve otomatik log | Blok 17–18 | P3; append-only log |
| 17 | Hafta başına ertele | D29.3 | P2; sonraki pazartesi 08:00 |
| 18 | Özel bildirim sesleri | Asset-dependent P3 | Kullanıcı asset'i + D29.1 |
| 19 | Fotoğraf kırpma | Ortak Attachment v2 | P3; orijinal korunur |

Eşleme sonucu: `19/19`. Eksik bulgu: `0`.

## P1 / P2 / P3 ayrımı

### P1 — Güvenilir takip kaybı

D29.1 / Issue #272, sıradaki tek production işidir. Tek reminder eyleminin diğer
aktif/görünür bildirimleri kaldırması güvenilir takip kaybıdır ve bütün yeni P3
özelliklerin önüne geçer.

### P2 — Günlük kullanım sürtünmesi

- D29.2: Ajanda arama odağı, klavye ve gesture izolasyonu
- D29.3: Hatırlatıcı zaman/düzenleme ve proje filtresi sürtünmesi
- D29.5: Backup işlem görünürlüğü

Bu işler ayrı ve dar child Issue'lar olarak uygulanır. D29.4 içindeki salt
gösterge küçük bir görünürlük işi olabilir; kullanıcı-okur mutation geçmişi ise
event/revision sözleşmesi nedeniyle daha geniş ortak omurgaya bağlanır.

### P3 — Ortak omurga ve dikeyler

- Proje ve Mahal Kataloğu v1
- Beton santral/mahal ve canlı operasyon yüzeyi
- Beton widget'ı
- İş/Yapılacaklar/otomatik log
- Ortak Attachment fotoğraf kırpma
- Özel bildirim sesleri

P3 işleri D29.1 ve ilgili P2 sürtünmeleri kapanmadan öne alınmaz.

## D29.1–D29.5 kanonik sırası

### D29.1 — Hatırlatıcı bildirim izolasyonu — P1 / Issue #272

- Bir Hatırlatıcı tamamlanınca yalnız kendi platform bildirimi kapanır.
- Diğer aktif ve görünür Hatırlatıcı bildirimleri korunur.
- Tek kayıt eyleminde toplu iptal kullanılmaz.
- Reminder UUID ile platform notification ID bağı korunur.
- Restart ve reconciliation ilgisiz aktif bildirimleri silemez.
- Teslim edilmiş aktif one-time notification ile terminal notification ayrılır.
- `pendingNotificationRequests()` içinde bulunmamak tek başına terminal kanıtı
  değildir.
- Üç görünür bildirimle tamamla, ertele, iptal, restart ve deep-link doğrulanır.

### D29.2 — Ajanda arama odağı ve klavye izolasyonu — P2

- Detaydan geri dönmek klavyeyi kendiliğinden açamaz.
- Arama metni route-local korunabilir.
- Odak, imleç ve klavye açık arama dokunuşu olmadan geri gelmez.
- Hızlı scroll, momentum scroll ve yön değiştirme arama alanını aktifleştiremez.
- Scroll gesture ile search tap gesture ayrılır.
- Uzun liste, küçük ekran, büyük metin ve detail mutation sonrası dönüş test edilir.

### D29.3 — Hatırlatıcı zaman ve düzenleme sürtünmesi — P2

- `Yarın sabah` ertesi yerel gün `08:00` demektir.
- `Hafta başına ertele` sonraki pazartesi `08:00` demektir.
- Kesin tarih ve saat işlemden önce gösterilir.
- Hatırlatıcı tam forma girmeden güvenli biçimde erkene alınabilir.
- Geçmiş zamana düşen seçim açık onay olmadan kaydedilmez.
- Düzenleme ekranında `Tam gün` seçeneği bulunur.
- Tam gün kayıtları ilgili gün içinde saatli kayıtların üstünde gösterilir.
- Gecikmiş/kritik bölüm sessizce aşağı itilmez.
- `Tüm projeler`, aktif proje ve `Projesiz` filtreleri bulunur.
- Arşivli projeler varsayılan aktif filtreye girmez.
- Filtre, arama, sıralama ve detail dönüşü route-local korunur.

### D29.4 — Ajanda–Hatırlatıcı görünürlüğü ve değişiklik geçmişi

- Bağlı Hatırlatıcısı olan Ajanda kartında erişilebilir gösterge bulunur.
- Gösterge yalnız gerçek source link'ten beslenir.
- Gösterge ilgili Hatırlatıcı detayına gider.
- Mutation geçmişi değişiklik zamanı, değişen alan, önceki değer ve yeni değeri
  taşır.
- Geçmiş kullanıcı tarafından değiştirilemez.
- Event/revision zincirinden üretilir veya onunla atomik tutulur.
- Eski günlük/log çıktıları sessizce yeniden yazılmaz.

### D29.5 — Backup işlem görünürlüğü

- Ayrı bekleme/ilerleme yüzeyi açılır.
- Gerçek yüzde yoksa sahte yüzde gösterilmez.
- Aşamalar hazırlanıyor, paketleniyor, bütünlük kontrolü yapılıyor ve kaydediliyor
  olarak görünür.
- Aynı anda ikinci backup başlatılamaz.
- Geri/çıkış davranışı açıkça belirtilir.
- Başarıda dosya adı, konumu ve zaman gösterilir.
- Hatada dosyanın oluşup oluşmadığı açıkça gösterilir.
- Backup formatı, manifest, parola ve restore compatibility değişmez.

## Proje ve Mahal Kataloğu kararı

Proje düzenlenebilir, arşivlenebilir ve arşivden çıkarılabilir. Arşivleme hiçbir
bağlı veriyi silmez.

Mahal, modüllerin tekrarladığı serbest string değildir. Proje bazında stable ID,
ad, isteğe bağlı üst bağlam ve aktif/arşiv durumu taşıyan ortak kayıttır. Aynı
mahal Ajanda, Hatırlatıcı, Beton, İş ve fotoğraf kayıtlarında seçilir. Ad değişse
bile tarihsel kimlik kopmaz.

## Kalıcı proje silme çakışması ve fail-closed sınır

1. Kesin kapsam düzenle, arşivle ve arşivden çıkardır.
2. İlk güvenli hard-delete adayı yalnız bağlı verisi `0` olan boş/test projesidir.
3. Bağlı verili proje ilk implementation'da yalnız arşivlenir.
4. Parola tek başına veri güvenliği sayılmaz.
5. Bağlı verili silme değerlendirilirse bağlı veri envanteri, doğrulanmış backup,
   geri alınamazlık onayı ve güvenlik parolası birlikte gerekir.
6. Otomatik cascade hard-delete yapılmaz.

## Beton dependency sırası

```text
D29.1 notification isolation
→ Proje ve Mahal Kataloğu v1
→ Beton santral/mahal ve canlı read-model
→ Açık Beton notification
→ Beton widget
```

Beton Paketi v2; santral, mahal, hedef beton, dökülen beton, kalan beton, mikser
sayısı, son mikser zamanı, hızlı mikser kaydı, irsaliye, fotoğraf ve açık dökümü
bitirme alanlarını/eylemlerini taşır.

Uygulama içi canlı kart, notification ve widget aynı read-model'den beslenir.
Birbirinden bağımsız üç state sistemi kurulmaz. Beton widget'ı notification
lifecycle ve canlı Beton read-model'i kararlı hale geldikten sonra yapılır.

## İş / Yapılacak / log sınırı

İş üst kaydı içinde ayrı Yapılacak listesi bulunur. Yapılacak tamamlanınca aynı
İşe bağlı append-only otomatik log oluşur. Eski log sessizce yeniden yazılmaz.
Kullanıcı ayrıca açıklama, fotoğraf veya belge ekleyebilir. İş; proje, mahal,
Hatırlatıcı ve tarihsel Ajanda kayıtlarıyla bağlanabilir.

İlk sürüm sınırsız checklist ağacı veya Gantt değildir. Yapılacak durumu
source-of-truth; otomatik log ise değiştirilemez olay kanıtıdır.

## Attachment ve notification sound bağımlılıkları

Ortak Attachment fotoğraf kırpma ve döndürmeyi destekler. Mümkünse orijinal
fiziksel dosya korunur; kırpılmış sürüm kayıt gösteriminde kullanılabilir. Aynı
fiziksel attachment modüller arasında çoğaltılmaz. Belge perspektif düzeltmesi
ayrı dar iş olarak kalır.

Özel bildirim sesleri kullanıcı asset'leri sağlandıktan ve D29.1 tamamlandıktan
sonra değerlendirilir. Bu documentation-only adımda asset veya platform kodu
eklenmez.

## Değişen dosyalar ve runtime sınırı

Exact branch farkı yalnız şunlardan oluşur:

1. `ROADMAP.md`
2. `docs/270_roadmap_field_feedback_vi.md`
3. `learning/270_roadmap_field_feedback_vi.md`

Production/test değişikliği: `0`.

Schema, migration, backup formatı ve runtime değişikliği: `0`.

Global `CHANGELOG.md`, `docs/project_decisions.md`, `.cse/**`, `mobile/**`,
`app/**` ve `tests/**` değiştirilmemiştir.

## Doğrulama yaklaşımı

Validation class `docs` olduğu için runtime test/build çalıştırılmaz. Yalnız
Markdown ve repository diff kontrolleri uygulanır:

- `git diff --check`
- exact changed-file allowlist `3/3`
- production/test diff `0`
- schema/migration diff `0`
- Markdown başlık ve code-fence dengesi
- conflict marker, tab ve invalid trailing whitespace `0`
- saha bulgusu eşlemesi `19/19`
- #268 / PR #269 completed kaydı
- #272'nin sıradaki tek production Issue olması
- current master SHA doğruluğu
- Draft PR #259 state değişikliği `0`
