# Issue #270 — Roadmap 2026.3.4 / 29 Temmuz Günlük Saha Geri Bildirimi VI

## Amaç

29 Temmuz 2026 günlük saha kullanımında bildirilen 19 bulguyu kanonik ürün
sırasına yerleştirmek, doğrudan güvenilirlik sorunu olan maddeleri P1/P2 olarak
öne almak ve daha geniş özellikleri mevcut veri omurgalarıyla çakışmayacak dikey
bloklara bağlamak.

Bu çalışma yalnız dokümantasyon değişikliğidir. Production/test kodunu,
notification runtime davranışını, mobil schema'yı, backup formatını veya kullanıcı
verisini değiştirmez.

## Güvenli başlangıç noktası

- Repository: `faliardic/chief-site-engineer`
- Base branch: `master`
- Base commit: `1179870a7c69d1e3f090e5fc61da9c7bbfc42879`
- Mobil schema: `10`
- Backup formatı: `1`
- Son merged Flutter full suite: `300 PASS`
- Son merged Flutter analyze: `PASS`
- Açık production implementation: Issue #268 / Draft PR #269
- Bloklu yatay kabul: #257 → #254 / #256, Draft PR #259

Issue #268'in Ajanda deterministik sıralama kodu, testi, commit ancestry'si veya
Draft PR diff'i bu roadmap branch'ine taşınmaz. #268 merge edilmeden güvenli
`master` gerçeği sayılmaz.

## Çalışma ayarı

- Codex ayarı / akıl yürütme derecesi: **High**
- Asistan akıl yürütme önerisi: **High**
- Değişiklik sınıfı: `documentation-only`
- Production doğrulaması: gereksiz; production/test diff'i `0` olmalıdır.

## Günlük saha bulgularının kanonik yerleşimi

| No | Saha bulgusu | Roadmap karşılığı | Öncelik / bağımlılık |
|---:|---|---|---|
| 1 | Backup sırasında bekleme/yükleme ekranı | D29.5 Backup işlem görünürlüğü | P2; backup formatı değişmez |
| 2 | Mahal oluşturup tekrar kullanma | Proje ve Mahal Kataloğu v1 | P3 temel omurga |
| 3 | Beton paketinde santral adı | Beton Paketi v2 | Mahal Kataloğu sonrasında |
| 4 | Ajanda düzenleme değişiklik geçmişi | D29.4 | Event/revision tabanlı |
| 5 | `Yarın sabah` = 08:00 | D29.3 | Exact Europe/Istanbul sözleşmesi |
| 6 | Hatırlatıcıları projeye göre listeleme | D29.3 | Tüm projeler / aktif proje / Projesiz |
| 7 | Açık Betonun bildirim panelinde görünmesi | Faz 3 canlı Beton operasyonu | D29.1 sonrasında |
| 8 | Beton widget'ı | Beton Paketi v2 | Tek read-model; ayrı state yok |
| 9 | Ajanda kartında bağlı Hatırlatıcı işareti | D29.4 | Mevcut source link'ten beslenir |
| 10 | Proje düzenle/arşivle/sil | Proje yaşam döngüsü karar kapısı | Hard-delete fail-closed |
| 11 | Detay dönüşünde arama odağı/klavye | D29.2 | P2 hotfix |
| 12 | Hızlı scroll ile aramanın aktif olması | D29.2 | P2 hotfix |
| 13 | Hatırlatıcıyı erkene almanın zahmetli olması | D29.3 | Hızlı güvenli zaman eylemi |
| 14 | Düzenlemede Tam gün ve listede üstte görünüm | D29.3 | Mevcut all-day contract'ı |
| 15 | Bir Hatırlatıcı tamamlanınca tüm bildirimlerin kaybolması | D29.1 | P1; ilk production işi |
| 16 | İş içinde Yapılacaklar ve otomatik log | Blok 17–18 | Append-only log |
| 17 | Hafta başına ertele | D29.3 | Sonraki pazartesi 08:00 |
| 18 | Özel bildirim sesleri | Asset-dependent P3 | Kullanıcı asset'i + D29.1 |
| 19 | Fotoğraf kırpma | Ortak Attachment v2 | Orijinal sessizce ezilmez |

## Öncelik kararı

### D29.1 — Hatırlatıcı bildirim izolasyonu — P1

Bir Hatırlatıcı üzerinde `Tamamla`, `Ertele`, `Aç` veya benzeri tek-kayıt eylemi
uygulandığında yalnız ilgili notification kimliği etkilenmelidir. Genel
`cancelAll` veya farklı kayıtların aynı notification ID'yi paylaşması kabul
edilmez. En az üç eşzamanlı Hatırlatıcıyla tamamla/ertele/deep-link/restart matrisi
kanıtlanmadan bu blok kapanmaz.

Bu hata açık Beton persistent bildirimi ve özel seslerden önce çözülür; çünkü
ikisi de aynı platform notification yaşam döngüsüne güvenecektir.

### D29.2 — Ajanda arama odağı ve klavye izolasyonu — P2

Arama metninin route-local korunması, arama alanının otomatik odaklanması anlamına
gelmez. Detay dönüşü, detail mutation reload'u, hızlı kaydırma ve momentum scroll
kullanıcı açıkça arama alanına dokunmadıkça imleç veya klavye açamaz.

### D29.3 — Hatırlatıcı zaman ve düzenleme sürtünmesi — P2

- `Yarın sabah`: ertesi Europe/Istanbul yerel günü `08:00`.
- `Hafta başına ertele`: sonraki pazartesi `08:00`.
- Uygulanacak kesin tarih/saat mutation öncesinde gösterilir.
- Hatırlatıcı güvenli hızlı eylemle erkene alınabilir.
- Geçmiş zamana düşen seçim açık uyarı/onay olmadan kaydedilmez.
- Düzenleme ekranı oluşturma ekranıyla aynı `Tam gün` sözleşmesini kullanır.
- Aynı gün içindeki tam gün kayıtları saatli kayıtların üzerinde gösterilir;
  gecikmiş/kritik bölüm önceliği ayrıca korunur.
- Liste `Tüm projeler`, aktif proje ve `Projesiz` filtrelerini taşır.

### D29.4 — Ajanda–Hatırlatıcı görünürlüğü ve değişiklik geçmişi

Bağlı Hatırlatıcı göstergesi mevcut source link'ten üretilir; ikinci bir bağlantı
gerçeği oluşturmaz. Ajanda mutation geçmişi en az zaman, değişen alan, önceki değer
ve yeni değeri içerir. Geçmiş kullanıcı tarafından düzenlenemez ve eski günlük
çıktıları sessizce yeniden yazmaz.

### D29.5 — Backup işlem görünürlüğü

Gerçek yüzde bilgisi yoksa sahte ilerleme yüzdesi gösterilmez. Kullanıcıya
`hazırlanıyor`, `paketleniyor`, `bütünlük kontrolü`, `kaydediliyor` gibi gerçek
aşamalar gösterilir. Aynı anda ikinci backup başlatılmaz. Başarı veya hata
sonucunda dosyanın oluşup oluşmadığı kesin belirtilir.

## Proje ve Mahal Kataloğu v1

Mahal, her modülün tekrar yazdığı serbest string değil; proje içinde stable ID,
ad, isteğe bağlı üst bağlam ve aktif/arşiv durumu taşıyan ortak kayıttır. Aynı
mahal Ajanda, Hatırlatıcı, Beton, İş, fotoğraf ve sonraki iş paketlerinde seçilir.
Ad değişikliği tarihsel bağlantıyı koparmaz.

Projeler düzenlenebilir, arşivlenebilir ve arşivden çıkarılabilir. Arşivleme bağlı
Ajanda, Hatırlatıcı, Beton, İş, medya ve event geçmişini silmez.

## Kalıcı proje silme karar kapısı

Yeni saha isteği önceki `silme yok; arşivle` kararıyla çeliştiği için şu
fail-closed sınır kanonikleştirilmiştir:

1. Düzenleme, arşivleme ve arşivden çıkarma kesin kapsamdadır.
2. İlk güvenli hard-delete adayı yalnız bağlı verisi `0` olan boş/test projesidir.
3. Bağlı verisi olan proje ilk implementation'da yalnız arşivlenir.
4. Bağlı verili hard-delete için ayrı Owner Data Lifecycle karar Issue'su gerekir.
5. Gelecekte kabul edilirse işlem öncesinde kayıt/medya/event envanteri,
   doğrulanmış backup, geri alınamazlık doğrulaması ve güvenlik parolası birlikte
   zorunludur.
6. Parola tek başına veri kaybı koruması değildir.
7. Otomatik, toplu veya arka plan hard-delete kapsam dışıdır.

## Beton canlı operasyon sınırı

Beton Paketi santral ve stable mahal bağlantısı taşır. Açık paket için uygulama
kartı, Android bildirim paneli ve widget aynı read-model'i kullanır:

- proje ve mahal;
- santral;
- hedef, dökülen, kalan/aşılan beton;
- mikser sayısı ve son mikser zamanı;
- güvenli `Mikser ekle`, `İrsaliye ekle`, `Fotoğraf çek`, `Paketi aç`,
  `Dökümü bitir` eylemleri.

Widget veya notification ayrı sayaç/state tutmaz. Paket kapandığında yalnız ilgili
operasyon yüzeyi kaldırılır. Persistent notification D29.1 kapanmadan production'a
alınmaz.

## İş / Yapılacak / log sınırı

İş kaydı proje, mahal, açıklama, öncelik, hedef tarih ve durum taşır. İşin içinde
ayrı Yapılacak listesi bulunur. Bir Yapılacak tamamlandığında aynı İşe bağlı,
append-only otomatik log oluşur. Item durumu source-of-truth'tur; log ikinci
editable sayaç değildir. Planlanan iş kullanıcı onayı olmadan gerçekleşmiş Ajanda
olayı sayılmaz.

## Attachment ve bildirim sesi sınırı

Fotoğraf kırpma ve döndürme Ortak Attachment v2 içinde uygulanır. Orijinal dosya
sessizce ezilmez; hash/MIME/boyut, source bağlantısı ve backup/restore bütünlüğü
korunur. Belge perspektif düzeltmesi ayrı sonraki iştir.

Özel notification sesleri kullanıcı asset'leri teslim edildikten sonra ele alınır.
Sessiz, vibrasyon ve sistem varsayılanı korunur; upgrade ve kullanıcı tercihleri
test edilir.

## Değişen dosyalar

Exact branch farkı yalnız şunlardan oluşur:

1. `ROADMAP.md`
2. `docs/270_roadmap_field_feedback_vi.md`
3. `learning/270_roadmap_field_feedback_vi.md`

Global `CHANGELOG.md` ve `docs/project_decisions.md` bu roadmap-only değişiklikte
yeniden yazılmaz. Kanonik ileri sıra `ROADMAP.md`; ayrıntılı karar/eşleme ise bu
Issue belgesinde tutulur.

## Doğrulama kapıları

- Base/head karşılaştırmasında exact üç dokümantasyon dosyası.
- Production ve test dosyası değişikliği: `0`.
- Schema/migration/backup formatı değişikliği: `0`.
- Markdown code fence dengesi ve başlık yapısı.
- Sekme, conflict marker ve bozuk bağlantı referansı: `0`.
- 19 saha bulgusunun eşleme tablosunda eksik kalem: `0`.
- #268 / Draft PR #269 ve Draft PR #259 state değişikliği: `0`.

## Yayınlama sınırı

Branch Draft PR olarak açılır. Ready, merge, Issue close, force-push, amend,
branch silme veya yeni production child Issue oluşturma bu çalışmanın kapsamında
değildir.
