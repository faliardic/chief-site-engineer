# Podcast 036 — Issue #227–#277 NotebookLM Podcast Notu

## 1. NotebookLM Kullanım Talimatı / Instruction Reference

Bu not, `docs/notebooklm/NOTEBOOKLM_INSTRUCTIONS.md` içindeki kalıcı talimatla
birlikte kullanılmalıdır. Birleşmiş davranış, duraklatılmış aktif iş, açık Draft
PR ve ileri plan birbirine karıştırılmamalıdır.

## 2. Notun Kapsamı

Bu bölüm legacy Adım 001–225 döneminden Issue tabanlı proje günlüğüne geçişi ve
Issue #227–#277 arasındaki gerçek birleşmiş mobil işleri anlatır. Aralıktaki her
sayı bir CSE işi değildir; yalnız `CHANGELOG.md` içinde canonical
`## Issue #NNN` bölümü bulunan işler bu dönemin toplu kaydına alınır.

Güncel güvenli nokta Issue #277 / PR #278 /
`c72f6bc55fc658996a546d9833b85a2614b99327` birleşimidir. Issue #279
duraklatılmış ve birleşmemiştir. PR #259 açık, Draft ve conflicting durumdaki
ayrı acceptance altyapısıdır.

## 3. Dönemin Ana Teması

Ana tema, offline saha hafızasını büyütürken kullanıcı niyetini ve veriyi
korumaktır. Ajanda kaydı, Hatırlatıcı, Puantaj ve Beton paketi arasında kaynak
bağları görünür tutuldu; arşiv/çöp, append-only geçmiş, optimistic revision,
deterministik sıralama ve güvenli bildirim uzlaştırması korunarak saha
sürtünmeleri küçük Issue'larla azaltıldı.

## 4. Güncel Adımların Ayrıntılı Anlatımı

### Issue #227 — Hatırlatıcı çöp kutusu ve geri yükleme

Hatırlatıcılar fiziksel silme yerine çöp kutusuna taşınır. Çöpe alma, geri
yükleme ve kalıcı geçmiş görünümü lifecycle/event sözleşmesiyle izlenir;
bildirimler kaynak reminder durumuyla uzlaştırılır.

### Issue #230 — Reminder detayında kaynak Ajanda fotoğrafları

Kaynak Ajanda kaydı bulunan reminder, aktif kaynak fotoğraflarını salt-okunur
gösterir. Byte veya metadata reminder içine kopyalanmaz; mevcut attachment
integrity ve güvenli viewer yolu kullanılır. Eksik ya da bozulmuş kanıt
gizlenmez.

### Issue #234 — Beton sınıfı kataloğu ve döküm zaman çizgisi

Schema `10`, proje bazlı Beton sınıfı kataloğunu, append-only katalog geçmişini
ve paket–Ajanda bağını ekledi. Legacy sınıflar deterministik migrate edildi.
Planlandı, devam ediyor ve tamamlandı görünümü gerçek başlangıç/bitiş
zamanlarından türetilir; yönetilen Ajanda kaydı Beton paketinin saha günlüğü
projeksiyonudur.

### Issue #237 — Ajanda Beton sinyali ve deep-link

Ajanda açıklama, not ve kategori alanındaki dar beton/betonaj sinyalleri offline
ve deterministik öneriye dönüştürülür. Sistem otomatik paket, reminder veya
saha kararı üretmez. Kullanıcı aynı proje/gün bağlamıyla Beton oluşturma
akışına geçer; yönetilen Beton Ajanda kayıtları generic öneri göstermez.

### Issue #252 — Hatırlatıcı hızlı eylem ayrımı

`Yarına ertele`, `2 saat ertele` ve `3 saat ertele` ayrı kullanıcı niyetleri
olarak sunuldu. Hızlı mutation'lar mevcut canonical UTC, revision,
append-only event ve notification reconciliation yolunda kaldı.

### Issue #260 — Beton checklist source-of-truth hotfix'i

Checklist başlığındaki açık sayı ile `Dökümü başlat` blocker kümesi aynı
zorunlu satırlardan hesaplanır. Laboratuvar ve yapı denetim kalemleri
system-owned kalır; kullanıcı bulk action ile bunları gerçeğe aykırı
tamamlayamaz. Field, event ve reminder güncellemeleri aynı transaction
sınırındadır.

### Issue #262 — Yarına ertele uygunluğu

Kart, detay ve application mutation aynı Europe/Istanbul gün helper'ını
kullanır. Yalnız gecikmiş veya bugün tarihli uygun bağımsız aktif reminder
ertelenebilir; gelecek, Puantaj kaynaklı, terminal, trash ve plansız kayıtlar
fail-closed reddedilir.

### Issue #264 — Liste bağlamının korunması

Ajanda, Hatırlatıcı, Beton ve Puantaj listeleri detail dönüşünde gün, proje,
filtre, arama ve scroll bağlamını canlı route içinde korur. Fresh veri geldikten
sonra offset güncel extent'e clamp edilir; hızlı çift dokunma duplicate detail
push üretmez.

### Issue #266 — Türkçe ürün dili ve Puantaj Kaydet

Root Flutter uygulaması canonical Türkçe locale/delegate setini kullanır.
Puantaj ana eylemi kullanıcıya `Kaydet` der fakat draft lifecycle anlamı
değişmez; günü tamamlama ayrı eylemdir. Editable/read-only seçim toolbar'ı
bağlama uygun kalır.

### Issue #268 — Deterministik Ajanda sıralaması

Ajanda `observed_at`, `created_at`, `id` alanlarında üç seviyeli application
query sözleşmesiyle en yeni veya en eski üstte sıralanır. `updated_at` kaydı
saha olay zamanından koparıp başka konuma taşımaz; UI listeyi sonradan tersine
çevirmez.

### Issue #272 — Hatırlatıcı bildirim izolasyonu

Teslim edilmiş gecikmiş tek-seferlik notification ile schedulable, terminal ve
orphan durumlar ayrıldı. Bir reminder mutation'ı başka aktif reminder'ın
bildirimini yanlışlıkla iptal etmez; korunacak delivered kayıt yeniden
planlanmaz veya kapasite tüketmez.

### Issue #275 — Ajanda arama odağı ve klavye izolasyonu

Arama metni/query ile focus/caret/IME ayrı route-local sözleşmelerdir. Detail
dönüşünde metin korunur fakat klavye kendiliğinden açılmaz. Gerçek drag
klavyeyi kapatır; odaksız scroll arama alanına focus vermez. Fiziksel kabul
Samsung `SM-X610` tablette wide smoke PASS ile tamamlandı; telefon promotion
yapılmadı.

### Issue #277 — Exact hızlı planlama zamanları

`Yarın sabah` ve timed `Yarın 08:00`, ertesi Europe/Istanbul günü tam `08:00`
üretir. `Hafta başına ertele`, her zaman sonraki pazartesi `08:00`ı seçer.
Preview ile application resolver gün sınırında uyuşmazsa mutation fail-closed
durur. Canonical row, event, notification binding, all-day korunumu ve cold
relaunch Samsung `SM-X610` tablet wide smoke ile doğrulandı; telefon promotion
yapılmadı.

## 5. Güncel Dönem Özeti

Bu dönemde mobil ürünün saha akışları yeni bir backend veya cloud bağımlılığı
eklemeden derinleşti. Hatırlatıcı niyeti daha açık hale geldi; Ajanda–Beton
bağları, fotoğraf kanıtı, checklist ve timeline güvenilirleştirildi; listeler
daha kararlı ve Türkçe hale geldi. Son birleşmiş mobil veri sözleşmesi schema
`10`, `.csebackup` formatı `1` ve canonical timezone `Europe/Istanbul`dır.

## 6. Önceki Adımların Ayrı Ayrı Özeti

Legacy Adım 001–225 dönemi tamamlanmış tarihsel bağlamdır. Bu not içinde 225
başlık tekrar edilmez; deterministik rolling source bu adımların canonical
CHANGELOG özetlerini ayrı ayrı üretir. Podcast 001–035 değiştirilmeden korunur.
Issue döneminde numara boşlukları tamamlanmış sahte işlerle doldurulmaz.

## 7. Birikimli Ürün ve Teknik Durum

Ana ürün Flutter mobil uygulamasıdır ve offline-first çalışır. Cihaz-içi SQLite,
uygulama özel attachment alanı, append-only event geçmişi, optimistic revision,
canonical UTC storage/Europe-Istanbul sunumu ve şifreli backup/restore omurgası
korunur. Android compile/target SDK `36`, mobil sürüm `0.1.0+1`, schema `10` ve
backup formatı `1`dir.

Python/Flask kodu tarihsel ürün çekirdeği ve repository araçları için
korunmaktadır; güncel mobil runtime Python sunucusuna bağlanmaz. Başarılı test
ve tablet kabulü ürünün field-ready, production-ready veya store-released
olduğu anlamına gelmez.

## 8. Test ve Güvenli Nokta Kanıtı

Issue #277 tamamlanmasında focused lifecycle `48/48`, focused widget `46/46`,
concrete regression `1/1`, full Flutter `333/333` ve `flutter analyze` `0`
sonucu alındı. Samsung `SM-X610` tablette exact quick schedule wide smoke ve
cold relaunch PASS oldu. Kullanıcı bu dar Issue için tablet PASS'i tamamlanma
kapısı seçti; telefon promotion ertelendi.

Bu kanıt `c72f6bc55fc658996a546d9833b85a2614b99327` safe point'ine aittir.
Issue #279'un birleşmemiş davranışı veya PR #259 altyapısı bu kanıta dahil
değildir.

## 9. Bilerek Ertelenenler

- Issue #279 içindeki reminder hızlı daha-erken-zaman davranışı duraklatılmıştır.
- Telefon promotion ve yeni cihaz kabul turu bu dokümantasyon işinde yoktur.
- PR #259 açık, Draft ve conflicting olarak birleşmemiştir.
- Store release, field-ready ve production-ready ilanı yapılmamıştır.
- NotebookLM upload/API/credential/browser otomasyonu ve Audio Overview üretimi
  repository generatorünün kapsamı dışındadır.

## 10. Sonraki Doğal Yön

Önce README, state ve NotebookLM kaynağının bu merged safe point'le tutarlı
kalması tamamlanmalıdır. Issue #279 ancak ayrı yetki ve kendi fail-closed test
kapılarıyla yeniden ele alınabilir. Daha geniş saha veya release altyapısı,
birleşmemiş PR #259'u ürün gerçeği gibi sunmadan ayrı Issue'larda yönetilmelidir.

## 11. NotebookLM Kısa Direktifi

Bu kaynaktan Türkçe, teknik ama anlaşılır bir bölüm üret. Legacy Adım 001–225
döneminden Issue tabanlı günlüğe geçişi açıkla. Issue #227, #230, #234, #237,
#252, #260, #262, #264, #266, #268, #272, #275 ve #277'yi saha karşılıklarıyla
anlat. Data protection, schema `10`, backup `1`, tablet-only kabul ve
birleşmemiş iş sınırını özellikle koru. Field-ready veya production-ready
olgunluğu uydurma.

## 12. Kapanış Sorusu ve Kısa Cevap

**Soru:** Issue #227–#277 dönemi CSE'yi hangi yönde olgunlaştırdı?

**Kısa cevap:** Yeni bir online servis eklemekten çok, sahadaki mevcut offline
kayıtların niyetini, kaynağını, sırasını, kanıtını ve geri döndürülebilirliğini
daha güvenilir yaptı; ancak ürün hâlâ field-ready veya production-ready ilan
edilmiş değildir.
