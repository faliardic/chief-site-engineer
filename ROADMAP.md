# CSE 2026.3.2 — Asistan-Öncelikli Ürün Yol Haritası

**Durum:** Kanonik ürün sırası  
**Tarih:** 27 Temmuz 2026  
**Ürün Epic'i:** #105  
**Yürütme Epic'i:** #127  
**Güncel saha backlog'u:** #219  
**Önceki saha backlog'u:** #203  
**Açık Release 0.1 pilotu:** #193  
**Güncel RC / günlük saha testi:** #245

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
- #237 — Ajanda Beton sinyali, öneri ve Beton paketine deep-link.

Güncel güvenli `master`:

```text
5eeb192d56b834df8c6e44d0d2fd80b0194251b5
```

Bu noktada mobil schema `10`, backup formatı `1`, Flutter full suite `260 PASS`,
Flutter analyze temiz ve Python full suite `1005 passed, 7 skipped` durumundadır.
Issue #245 Day 0 cihaz kabulü PASS olmuş ve gerçek veri korunmuştur.

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
   tamamlanamaması. Yeni özellikten önce çözülür.
3. **P2 — Günlük sürtünme:** yanıltıcı metin, gereksiz dokunma, tekrar veri girişi,
   yanlış sıralama veya sahada yavaşlatan UX. P3 özellikten önce alınır.
4. **P3 — Planlı özellik:** P0–P2 bulgusu yoksa aşağıdaki kanonik sıraya devam edilir.

Yedi günlük kabul kapısı korunur; ancak bu süre geliştirmeyi bekleten haftalık
bir pencere değildir. Kanıt, birbirini izleyen günlük raporların toplamıdır.

## 4. Yeni öncelik sırası

```text
Güvenilir saha sürümü
→ Günlük güvenilirlik ve veri bağlantısı
→ Sürtünmesiz yakalama
→ Açık döngü asistanı
→ Bağlam ve büyük resim
→ Uçtan uca saha paketleri
→ Kalite/İSG/resmî süreç
→ Doküman ve proje hafızası
→ Kaynaklı AI
→ Planlama ve öngörü
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
- Kapalı uygulama reminder teslimi doğrulanır.
- Backup, dışa çıkarma, preflight ve restore yürütülür.
- Fotoğraf, irsaliye, kayıt, restart ve güncelleme bütünlüğü doğrulanır.
- Günlük raporda bulunan P0/P1 sorunları ayrı dar blocker Issue'suna dönüşür.
- P2 bulgular Release 0.1.1 sırasına günlük öncelik olarak girer.

**Kapı:** En az 7 ardışık gerçek günlük rapor; veri kaybı `0`; sessiz kritik
notification başarısızlığı `0`; restore farkı `0`; açık kritik blocker `0`.

---

## Faz 0.1 — Release 0.1.1: Günlük Güvenilirlik / Sadeleştirme

**Amaç:** Universal Capture'a geçmeden önce günlük kullanım sürtünmelerini,
yanlış gün/saat anlamlarını, geri alınamaz kullanıcı işlemlerini, tekrar veri
girişini ve kaynak bağlantısı kopukluklarını dar child Issue'larla kapatmak.

### Tamamlanan bloklar

1. **Reminder scheduling contract — tamamlandı:** hızlı `Bugün`, gerçek
   `Tam gün` ve legacy `Bekliyorum` yüzeyinin kayıpsız kaldırılması.
2. **Birleşik ve sade Bugün — tamamlandı:** gecikenler, saatli bugün ve tam gün
   işleri tek ana yüzeyde.
3. **Reminder geri dönüşüm kutusu — tamamlandı:** recoverable trash/restore ve
   güvenli notification lifecycle.
4. **Ajanda → reminder kaynak attachment görünürlüğü — tamamlandı:** kaynak Ajanda
   fotoğrafları Hatırlatıcı detayında salt okunur.
5. **Beton sınıfı ve döküm zaman çizgisi — tamamlandı:** katalog, başlat/bitir,
   gerçek zamanlar ve tek bağlı Ajanda logu.
6. **Beton kelime önerisi/deep-link — tamamlandı:** deterministik öneri ve Beton
   paketine bağlantı; otomatik kayıt veya teknik karar yok.

### Sıradaki kanonik bloklar

7. **Hatırlatıcı hızlı eylem netliği**
   - Kart eylemi `Yarın` yerine `Yarına ertele` olarak gösterilir.
   - Üstteki `Yarın` görünüm filtresi değişmez.
   - `15 dakika`, `1 saat`, `2 saat`, `3 saat`, `Yarına ertele` ve özel tarih/saat
     seçenekleri tutarlı yüzeylerde sunulur.
   - Schema ve backup formatı değişmez.

8. **Ajanda–Hatırlatıcı kontrollü metin senkronu**
   - Ajandadan oluşturulan yeni Hatırlatıcı başlangıçta kaynak metne bağlıdır.
   - Ajanda açıklama/not/mahal değişiklikleri bağlı Hatırlatıcı metnine atomik
     olarak yansır.
   - Hatırlatıcı zamanı, durumu, son tarihi ve sonuç alanları bağımsız kalır.
   - Kullanıcı Hatırlatıcı metnini doğrudan düzenlerse açık onayla metin bağı kopar.
   - Erteleme, tamamlama veya önem değiştirme bağı koparmaz.
   - Legacy bağlantılar veri ezmemek için varsayılan bağımsız kabul edilir.
   - Migration, append-only event, rollback ve backup/restore doğrulanır.

9. **Başlangıç ekranı Saha İpuçları**
   - Offline, dönüşümlü ve kullanıcıyı rahatsız etmeyen tek ipucu kartı.
   - Manuel ileri/geri gezinme ve erişilebilirlik.
   - İlk içerikler kayıt disiplini, kanıt, raporlama ve açık döngü farkındalığıdır.
   - Popup veya notification kullanılmaz.

10. **Ortak attachment v2**
    - Fotoğraf, video, ses ve belge için tek fiziksel attachment.
    - Ajanda, Hatırlatıcı, Beton, Sicil ve albüm için çoklu kayıt bağlantısı.
    - Çoklu seçim, managed storage, hash/MIME/boyut, viewer/player ve archive.
    - Legacy Ajanda/Beton uyumluluğu ve backup/restore round-trip.
    - Aynı fiziksel dosya farklı modüller için kopyalanmaz.

11. **Ajanda Gün Planı Lite**
    - `Günlük Kayıtlar | Gün Planı` görünümü.
    - Proje, gün, başlık, açıklama, öncelik, sıra ve durum alanları.
    - `Yapılacak | Tamamlandı | İptal`, yarına taşıma ve sıralama.
    - Plan maddesinden Hatırlatıcı oluşturma.
    - Yalnız kullanıcı onayıyla `Gerçekleşti ve Ajandaya kaydet`.
    - Planlanan iş, gerçekleşmiş Ajanda olayı sayılmaz.
    - İlk sürümde WBS, Gantt, bağımlılık ve kilometre taşı yoktur.
    - Faz 8 planlama/lookahead için dar mobil temel oluşturur.

12. **Proje fotoğraf/video albümü**
    - Proje, tarih, kategori ve kaynak kayıt bağlantısıyla medya görünümü.
    - Thumbnail, sayfalama ve kaynak kayda geri bağlantı.
    - Blok 10 tamamlanmadan başlamaz; fiziksel dosya ikinci kez kopyalanmaz.

13. **Taşeron/personel/Puantaj UX ve Saha Rehberi**
    - #204 ile aynı taşeron–ekip–personel kimlik omurgası.
    - Puantajda taşeron → yalnız bağlı personel seçimi ve inline yeni kişi.
    - Telefon, adres, görev, firma, OSGB/SGK ve belge görünürlüğü.
    - Taşeron yetkilisi, personel, santral, laboratuvar, yapı denetim, tedarikçi ve
      diğer proje kişileri için birleşik arama.
    - Ad, firma, görev, proje ve normalize telefon numarasıyla arama.
    - Android numara çeviricisini açan kullanıcı kontrollü `Ara` eylemi.
    - Ayrı ve mükerrer bir telefon defteri kurulmaz.

14. **Telefon görüşmesi sonucu → Ajanda**
    - Saha Rehberi'nden numara çevirici açılır.
    - Kullanıcı uygulamaya dönünce görüşme sonucunu açıkça kaydeder.
    - Sonuçlar: görüşüldü, ulaşılamadı, meşguldü, geri dönüş bekleniyor,
      arama yapılmadı ve diğer.
    - Kullanıcı onayıyla kişi/firma bağlantılı Ajanda kaydı oluşur.
    - `Geri dönüş bekleniyor` için Hatırlatıcı önerilir; otomatik oluşturulmaz.
    - Sistem Call Log geçmişi okunmaz; `READ_CALL_LOG` istenmez.

15. **İstenecek Malzemeler**
    - Malzeme, miktar/birim, ihtiyaç tarihi, öncelik ve açıklama.
    - `İhtiyaç var → İstendi → Geldi/İptal`.
    - Tam satın alma, teklif, sipariş veya muhasebe sistemi değildir.

16. **Kaynaklı AI prompt export**
    - Önce günlük, sonra hafta/ay/yıl.
    - Ajanda, Hatırlatıcı, Puantaj, Beton, Gün Planı ve görüşme kaynaklı
      deterministik metin.
    - Gömülü AI çağrısı, otomatik gönderim veya sessiz veri mutasyonu yoktur.

17. **Mini hesap makinesi**
    - Temel işlemler ve kullanıcının onayladığı sayısal alana kontrollü aktarım.
    - İleri mühendislik hesapları ayrı dikeylerdir.

18. **Hava durumu uyarıları — ertelenmiş**
    - Haricî servis, proje konumu, cache/offline fallback, kullanıcı eşiği ve
      bildirim tercihi tasarımından sonra.
    - Her hava değişimi notification veya teknik karar üretmez.

**Kapı:** Blok 1–17 ayrı, dar ve doğrulanmış child Issue'larla tamamlanmadan Faz 1
production implementation'ı başlamaz. Blok 18 kanonik sırada korunur fakat
haricî servis/eşik tasarımı nedeniyle ertelenmiş iştir.

Sıradaki varsayılan production child **Blok 7 — Hatırlatıcı hızlı eylem
netliği**dir. Ancak yeni günlük raporda P0, P1 veya daha yüksek etkili P2 bulgusu
varsa günlük öncelik kuralı bu sıranın önüne geçer.

---

## Faz 1 — Release 0.2: Sürtünmesiz Evrensel Yakalama

**Amaç:** Her saha olayını 5–15 saniyede kayda dönüştürmek.

```text
+ Kaydet → Yaz | Konuş | Fotoğraf | Belge | Dosya | Hazır işlem
```

- Kullanıcı önce modül seçmez; CSE kayıt türünü önerir.
- Ortak `CaptureDraft` ve düzenlenebilir onay kartı kullanılır.
- Proje, blok/kat/mahal, imalat, kişi/firma ve termin etiketleri önerilir.
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

Kişi, taşeron, ekip, malzeme, ekipman, belge/revizyon, görev ve kanıt ortak
referanslardır. Puantaj, görev, İSG ve paketler aynı kimlikleri kullanır.

Ana ekran:

1. kaynaklı Saha Brifingi;
2. Kritik, Bugün, Geciken, Beklenen, Hazır değil şeridi;
3. ilk sürümde Blok/Kat × İmalat **Saha Nabzı** matrisi;
4. aktif Beton gibi operasyonlar için canlı kart;
5. etkiye göre **Şimdi Ne Yapmalıyım** listesi;
6. proje, malzeme, ekip, ekipman, önceki iş, kalite ve İSG için 7–14 günlük hazırlık;
7. günlük zaman çizgisi.

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
miktar, insan doğrulaması ve kapanış raporu taşır.

### Beton Paketi v2

- hazırlık ve eksik kontrolü;
- aynı plakanın farklı gelişleri dahil mikser yaşam döngüsü;
- irsaliye ve canlı hedef/dökülen/kalan/aşılan metraj;
- EBİS, numune, laboratuvar ve yapı denetim;
- versiyonlu numune önerisi ve gerekçeli override;
- kür, sonuç, eksik belge, rapor ve canlı ana ekran kartı.

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

Blok 11 Gün Planı Lite bu fazın günlük mobil temelidir; burada geniş planlama
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
- Önemli değişikliklerde kim, ne zaman, önceki/yeni değer ve dayanak görünürdür.
- Dar UI/metin işi schema veya tam release zincirini gereksiz yere tetiklemez.
- Persistence/schema değişikliği migration, rollback ve backup compatibility taşır.
- Gerçek kullanıcı verisi GitHub, test fixture veya tanı çıktısına kopyalanmaz.

# 7. Backlog yerleşimi

### Hemen

- #193 ve #245 saha kabulü günlük raporlarla sürer.
- Blok 1–6 tamamlanmıştır.
- Varsayılan sıradaki production işi Blok 7 Hatırlatıcı hızlı eylem netliğidir.
- Günlük raporda P0/P1 veya daha yüksek etkili P2 bulunursa o bulgu önce çözülür.

### Sonraki kontrollü sıra

1. Ajanda–Hatırlatıcı kontrollü metin senkronu;
2. Başlangıç ekranı Saha İpuçları;
3. Ortak attachment v2;
4. Ajanda Gün Planı Lite;
5. Proje fotoğraf/video albümü;
6. #204 Sicil/Puantaj ve Saha Rehberi;
7. Telefon görüşmesi sonucu → Ajanda;
8. İstenecek Malzemeler;
9. Kaynaklı AI prompt export;
10. Mini hesap makinesi;
11. ardından Faz 1 Universal Capture, Voice Capture/Assistant Inbox ve Faz 2 Open Loop.

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
- Beton kelimesinden otomatik Beton paketi/kaydı veya teknik karar üretmek.
- Aynı fiziksel attachment'ı Ajanda, Hatırlatıcı, Beton, Sicil veya albüm için
  çoğaltmak.
- Sistem Call Log geçmişini okumak veya `READ_CALL_LOG` istemek.
- Arama yapıldı varsayımıyla kullanıcı onayı olmadan Ajanda kaydı oluşturmak.
- Gün Planı maddesini otomatik olarak gerçekleşmiş saha olayı saymak.
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
7. Hatırlatıcı hızlı eylem netliği;
8. Ajanda–Hatırlatıcı kontrollü metin senkronu;
9. Başlangıç ekranı Saha İpuçları;
10. Ortak attachment v2;
11. Ajanda Gün Planı Lite;
12. Proje fotoğraf/video albümü;
13. #204 Sicil/Puantaj ve Saha Rehberi;
14. Telefon görüşmesi sonucu → Ajanda;
15. İstenecek Malzemeler;
16. Kaynaklı AI prompt export;
17. Mini hesap makinesi;
18. Hava durumu uyarıları — ertelenmiş.

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
| Hızlı kayıt ortancası | `≤10 sn` |
| Evrensel Yakalama oranı | `≥%80` |
| Sabah saha hâkimiyeti | `≤30 sn` |
| Bilinen kaydı bulma | `≤5 sn` |
| Günlük rapor | `≤3 dk` |
| Takip tarihi/terminal durumu olan açık döngü | `%100` |
| Ajanda–Hatırlatıcı bağlı metin ayrışması | `0` |
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
