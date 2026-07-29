# CSE 2026.3.4 — Asistan-Öncelikli Ürün Yol Haritası

**Durum:** Kanonik ürün sırası  
**Tarih:** 29 Temmuz 2026  
**Ürün Epic'i:** #105  
**Yürütme Epic'i:** #127  
**Güncel saha backlog'u:** #219  
**Açık Release 0.1 pilotu:** #193  
**Güncel RC / günlük saha testi:** #245  
**Roadmap senkronizasyonu:** #270  
**Açık P2 implementation:** #268 / Draft PR #269 — Ajanda deterministik sıralama  
**Sıradaki doğrulanması gereken P1:** Hatırlatıcı bildirim izolasyonu  
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

Release 0.1 çekirdeğinde mobil runtime, Ajanda, Hatırlatıcı, Puantaj,
taşeron–ekip–personel sicili, Beton Paketi, mikser/irsaliye/numune/laboratuvar,
fotoğraf/PDF, parola korumalı backup/restore ve Android release güvenliği vardır.

Tamamlanan günlük güvenilirlik dilimleri:

- #221 — hızlı `Bugün`, gerçek `Tam gün`, legacy `Bekliyorum` sadeleştirmesi;
- #225 — birleşik ve sade Bugün;
- #227 — Hatırlatıcı geri dönüşüm kutusu;
- #230 — Hatırlatıcıda kaynak Ajanda fotoğrafları;
- #234 — Beton sınıfı kataloğu ve döküm zaman çizgisi;
- #237 — Ajanda Beton sinyali, öneri ve deep-link;
- #252 / PR #253 — `Yarına ertele`, `2 saat`, `3 saat`;
- #260 / PR #261 — Beton checklist source-of-truth hotfix'i;
- #262 / PR #263 — Hatırlatıcı tarih/source uygunluğu;
- #264 / PR #265 — detay dönüşünde route-local state;
- #266 / PR #267 — Türkçe kullanıcı dili, Puantaj `Kaydet`, seçim toolbar'ı.

Güncel güvenli `master`:

```text
1179870a7c69d1e3f090e5fc61da9c7bbfc42879
```

Bu noktada mobil schema `10`, backup formatı `1`, Flutter full suite `300 PASS`,
Flutter analyze `PASS` ve son geçerli merged Python full suite
`1005 passed, 7 skipped` durumundadır.

#268 / Draft PR #269 yalnız Ajanda deterministik sıralama çalışmasıdır. Draft PR
merge edilmeden güvenli `master` sayılmaz. 29 Temmuz saha istekleri bu branch'e
eklenmez. #257 → #254/#256 ve Draft PR #259 bloklu yatay kabul zinciridir.

## 3. Günlük saha testi ve geliştirme modeli

Haftalık toplu karar modeli kullanılmaz. Her aktif gün gerçek saha kullanımı,
günlük rapor ve en yüksek öncelikli doğrulanmış bulguya göre tek child Issue vardır.

```text
Gerçek kullanım → günlük rapor → P0–P3 → tek child Issue
→ dar uygulama → veri korumalı cihaz güncellemesi → ertesi gün doğrulama
```

1. **P0 — Veri güvenliği:** kayıt kaybı, yanlış bağlantı, attachment,
   backup/restore veya update bütünlüğü. Roadmap durur.
2. **P1 — Ana akış blocker'ı:** Ajanda, Hatırlatıcı, Puantaj veya Beton ana
   işlemi ya da güvenilir takip bozulur. Yeni özellikten önce çözülür.
3. **P2 — Günlük sürtünme:** yanlış eylem, tekrar giriş, odak/klavye, sıralama,
   gereksiz dokunma veya sahada yavaşlatan UX. P3'ten önce alınır.
4. **P3 — Planlı özellik:** P0–P2 yoksa kanonik sıraya devam edilir.

Yedi günlük kabul kapısı korunur; bu, geliştirmeyi bekleten haftalık pencere değil,
birbirini izleyen günlük raporların toplamıdır.

## 4. Üst seviye sıra

```text
Güvenilir saha sürümü → günlük hotfix ve veri bağlantısı
→ ortak medya ve günlük plan → sürtünmesiz yakalama
→ açık döngü asistanı → bağlam ve büyük resim
→ uçtan uca saha paketleri → kalite/İSG/resmî süreç
→ doküman ve proje hafızası → kaynaklı AI
→ geniş planlama ve öngörü → ürünleştirme
```

AI; yakalama, işleme, hafıza ve öngörü seviyelerinde kontrollü eklenir. Teknik
kabul, resmî karar, imalat onayı veya sessiz kayıt kapatma yetkisi kazanmaz.

# 5. Fazlar

## Faz 0 — Release 0.1 gerçek saha kabulü

Ajanda, Hatırlatıcı, Puantaj, Beton, attachment, backup/restore, restart ve veri
koruyan update gerçek telefonda günlük raporlarla doğrulanır.

**Kapı:** En az 7 ardışık günlük rapor; veri kaybı `0`; sessiz kritik notification
başarısızlığı `0`; restore farkı `0`; açık kritik blocker `0`.

### Yatay fiziksel kabul

- #254 — izole Flutter acceptance harness;
- #255 — Windows generated dizin recovery — tamamlandı;
- #256 — atomik `mobile/build` rotasyonu;
- #257 — exact doğrulanmış acceptance APK'yı gereksiz ikinci build olmadan kullanma.

Physical smoke yalnız provenance, marker, applicationId ve SHA-256 değeri
kanıtlanmış exact artifact'i kullanır.

---

## Faz 0.1 — Release 0.1.1: Günlük Güvenilirlik / Sadeleştirme

Tamamlanan bloklar 1–11; #268 / Draft PR #269 olan Ajanda sıralaması açık Blok
12'dir. Aşağıdaki 29 Temmuz dalgası mevcut blok numaralarını değiştirmez.

### 29 Temmuz 2026 günlük saha dalgası

#### D29.1 — Hatırlatıcı bildirim izolasyonu — P1

- Bir Hatırlatıcı tamamlandığında yalnız kendi platform bildirimi kapanır.
- Diğer aktif/gecikmiş/planlanmış bildirimler görünür kalır.
- Kart, detay, notification action ve deep-link aynı reminder kimliğini hedefler.
- Tek-kayıt eyleminde genel `cancelAll` kullanılmaz.
- Restart/reconcile kalan bildirimleri source kayıtlarıyla eşleştirir.
- Notification ID farklı Hatırlatıcılar arasında yeniden kullanılmaz.
- En az üç eşzamanlı bildirimle tamamla, ertele, aç ve restart doğrulanır.

**Kapı:** İlgisiz notification kaybı `0`.

#### D29.2 — Ajanda arama odağı ve klavye izolasyonu — P2

- Detaydan dönünce arama metni korunabilir; kullanıcı arama alanına açıkça
  dokunmadıysa odak, imleç ve klavye geri gelmez.
- Hızlı kaydırma, yön değiştirme ve momentum scroll aramayı aktifleştirmez.
- Scroll gesture ile search tap gesture ayrılır.
- Route dönüşü, reload, uzun liste, küçük ekran ve büyük yazı test edilir.

**Kapı:** Kullanıcı dokunuşu olmadan klavye açılması `0`.

#### D29.3 — Hatırlatıcı zaman ve düzenleme sürtünmesi — P2

- `Yarın sabah` exact ertesi yerel gün `08:00` demektir.
- `Hafta başına ertele` exact sonraki pazartesi `08:00` demektir; kesin tarih
  işlemden önce gösterilir.
- Zaman, tam forma girmeden güvenli hızlı eylemlerle erkene alınabilir; geçmiş
  zamana düşen seçim açık onay olmadan kaydedilmez.
- Düzenleme ekranında `Tam gün` oluşturmayla aynı sözleşmeyi kullanır.
- Aynı yerel günde tam gün kayıtları saatli kayıtların üstünde gösterilir;
  gecikmiş/kritik bölüm sessizce aşağı itilmez.
- Hatırlatıcı listesinde `Tüm projeler`, aktif proje ve `Projesiz` filtreleri vardır.
- Arşivli projeler varsayılan aktif filtrede görünmez.
- Filtre, arama, sıralama ve detay dönüşü route-local korunur.

#### D29.4 — Ajanda–Hatırlatıcı görünürlüğü ve değişiklik geçmişi — P2/P3

- Bağlı Hatırlatıcısı olan Ajanda kartında sağ üstte erişilebilir gösterge vardır.
- Gösterge yalnız gerçek source link'ten beslenir ve ilgili detaya gider.
- Ajanda sonradan düzenlenirse kullanıcı-okur değişiklik geçmişi oluşur.
- Geçmiş zaman, alan, önceki değer ve yeni değeri taşır.
- Geçmiş kullanıcı tarafından düzenlenmez; event/revision zincirinden üretilir
  veya onunla atomik tutulur.
- Eski günlük/log çıktıları sessizce yeniden yazılmaz.

#### D29.5 — Backup işlem görünürlüğü — P2

- Yedek oluşturulurken ayrı bekleme/ilerleme yüzeyi açılır.
- Gerçek yüzde yoksa sahte yüzde gösterilmez; `hazırlanıyor`, `paketleniyor`,
  `bütünlük kontrolü`, `kaydediliyor` aşamaları gösterilir.
- Aynı anda ikinci backup başlatılamaz.
- Geri/çıkış davranışı ve işlemin devam durumu açıkça belirtilir.
- Başarıda dosya adı/konum/zaman; hatada güvenli özet ve dosyanın oluşup
  oluşmadığı gösterilir.
- Backup formatı, manifest, parola ve restore uyumluluğu değişmez.

### Proje ve Mahal Kataloğu v1

- Proje düzenlenebilir, arşivlenebilir ve arşivden çıkarılabilir.
- Arşivleme Ajanda, Hatırlatıcı, Beton, İş, medya veya event geçmişini silmez.
- Proje bazlı yeniden kullanılabilir Mahal Kataloğu oluşturulur.
- Mahal stable ID, ad, isteğe bağlı üst bağlam ve aktif/arşiv durumu taşır.
- Aynı mahal Ajanda, Hatırlatıcı, Beton, İş ve fotoğrafta tekrar seçilebilir.
- Ad değişikliği tarihsel kimliği koparmaz; sessiz string çoğaltma yapılmaz.

#### Kalıcı proje silme — fail-closed karar kapısı

1. Kesin kapsam: düzenle, arşivle, arşivden çıkar.
2. İlk güvenli silme adayı: yalnız bağlı verisi `0` olan boş/test projesi.
3. Bağlı verili proje ilk implementation'da yalnız arşivlenir.
4. Kalıcı silme ayrı Owner Data Lifecycle karar Issue'su gerektirir.
5. Gelecekte kabul edilirse bağlı veri/medya/event envanteri, geri alınamazlık
   uyarısı, doğrulanmış güncel backup, açık metin doğrulama ve güvenlik parolası
   birlikte zorunludur.
6. Parola tek başına veri kaybı koruması değildir.
7. Otomatik, toplu veya arka planda hard-delete kapsam dışıdır.

### Kontrollü veri bağlantısı ve çıktılar

13. **Ajanda–Hatırlatıcı kontrollü metin senkronu:** kaynak açıklama/not/mahal
    değişikliği atomik yansır; Hatırlatıcı zaman/durum/sonuç bağımsızdır; kullanıcı
    Hatırlatıcı metnini doğrudan düzenlerse açık onayla bağ kopar.
14. **Günlük Log Çıktısı v1:** seçilen proje/gün için deterministik insan-okur
    çıktı; Backup ve AI prompt'tan ayrı versioned artifact ailesi.

### Ortak medya

15. **Ortak Attachment v2**
    - Fotoğraf, video, ses ve belge için tek fiziksel attachment.
    - Ajanda, Hatırlatıcı, Beton, Sicil ve albüm için çoklu kayıt bağlantısı.
    - Çoklu seçim/çekim, önizleme, çıkarma ve atomik rollback.
    - Fotoğraf kaydetmeden önce kırpma ve döndürme.
    - Orijinal dosya sessizce ezilmez; kırpılmış çıktı türev veya açık tercihtir.
    - Hash/MIME/boyut, archive ve backup/restore round-trip korunur.
    - İrsaliye perspektif düzeltmesi sonraki ayrı iştir.
16. **Proje fotoğraf/video albümü:** proje, tarih, kategori, mahal ve kaynak kayıtla
    medya görünümü; Blok 15 olmadan başlamaz.

### Günlük plan, İş ve log sürekliliği

17. **Ajanda Gün Planı Lite / İş ve Yapılacaklar**
    - İş; proje, mahal, gün, başlık, açıklama, öncelik, sıra, hedef tarih ve durum taşır.
    - Ayrı Yapılacaklar listesi vardır; ilk sürüm en fazla
      `İş → Yapılacak → Alt yapılacak` derinliğindedir.
    - Üst ilerleme alt kalemlerden hesaplanır; ikinci sayaç yoktur.
    - Yapılacak tamamlanınca aynı işe bağlı append-only otomatik log oluşur.
    - Log zaman, eylem, önceki/yeni durum ve kaynak item kimliğini taşır.
    - Otomatik log geriye dönük değiştirilmez; düzeltme yeni event'tir.
    - Manuel açıklama, fotoğraf veya belge logu eklenebilir.
    - Yalnız kullanıcı onayıyla `Gerçekleşti ve Ajandaya kaydet` yapılır.
18. **İş Zinciri / Bağlı Log v1:** tarihsel Ajanda logları, otomatik checklist
    logları ve manuel ilerleme tek kronolojik iş zincirinde birleşir; eski log
    sessizce yeniden yazılmaz.
19. **Günlük Log Çıktısı v2:** attachment, Gün Planı ve İş Zinciri kaynaklarını
    tek günlük anlatıda gösterir; source kayıtları değiştirmez.

### Kişi ve sonraki saha araçları

20. **Taşeron/personel/Puantaj UX ve Saha Rehberi** — #204 kimlik omurgası.
21. **Deterministik kişi/firma/etiket önerileri** — kullanıcı onaysız bağ yok.
22. **Telefon görüşmesi sonucu → Ajanda** — sistem Call Log okunmaz.
23. **İstenecek Malzemeler** — ihtiyaç/istendi/geldi/iptal; tam satın alma değildir.
24. **Kaynaklı AI prompt export** — gömülü AI çağrısı veya sessiz mutasyon yok.
25. **Mini hesap makinesi** — temel işlemler ve onaylı sayısal aktarım.
26. **Hava durumu uyarıları — ertelenmiş** — konum, cache/offline fallback, eşik ve
    bildirim tercihi tasarımından sonra.

### Özel bildirim sesleri — asset-dependent P3

- Kullanıcının hazırlayacağı ses dosyaları teslim edilmeden implementation başlamaz.
- Hatırlatıcı, kritik takip ve açık Beton için rahatsız etmeyen ayrım tasarlanabilir.
- Sessiz, vibrasyon ve sistem varsayılanı korunur.
- Mevcut preference ve upgrade davranışı test edilir.
- D29.1 bildirim güvenilirliğini bekler; onu bloke etmez.

**Kapı:** Blok 1–25 ve önlerindeki D29 işleri ayrı dar child Issue'larla
kapanmadan Faz 1 production implementation'ı başlamaz. Blok 26 ertelenmiştir.

---

## Faz 1 — Release 0.2: Sürtünmesiz Evrensel Yakalama

```text
+ Kaydet → Yaz | Konuş | Fotoğraf | Belge | Dosya | Hazır işlem
```

Ortak `CaptureDraft`, düzenlenebilir onay kartı, proje/mahal/kişi önerisi,
Asistan Gelen Kutusu, çevrim dışı taslak ve kullanıcı onaylı sesli giriş.

**Kapı:** Sık kayıtların `%80`i `+ Kaydet`; ortanca süre `≤10 sn`; ilk zorunlu
alan `≤3`; çevrim dışı taslak kaybı `0`.

## Faz 2 — Release 0.3: Açık Döngü ve Takip Asistanı

Yapacağım, başkasına verdim, bekliyorum, söz/taahhüt, kontrol, onay/cevap/belge
ve tekrarlanan rutin; sorumlu/takip tarihi; kaynaklı Sabah Brifingi ve Akşam
Kapanışı.

**Kapı:** Her açık döngünün takip tarihi veya terminal durumu vardır; sabah özet
`≤30 sn`; akşam kapanışı `≤3 dk`.

## Faz 3 — Release 0.4: Bağlam Omurgası ve Büyük Resim

```text
Proje → Bölge/Blok → Kat/Kesim → Mahal/Aks → İmalat/İş Paketi
```

Ana ekranda kaynaklı brifing, kritik/beklenen şeridi, Saha Nabzı, canlı operasyon
kartı, Şimdi Ne Yapmalıyım, 7–14 günlük hazırlık ve günlük zaman çizgisi vardır.

### Açık Beton operasyon yüzeyi

- Uygulama kartı ve Android bildirim paneli aynı açık Beton Paketini gösterir.
- Tek read-model proje, mahal, santral, hedef, dökülen, kalan/aşılan beton,
  mikser sayısı ve son mikser zamanını üretir.
- Bildirimden `Mikser ekle`, `İrsaliye ekle`, `Fotoğraf çek`, `Paketi aç` ve
  `Dökümü bitir` güvenli akışları açılabilir.
- Hızlı işlem doğru paket/revision kimliğini taşır.
- Persistent bildirim D29.1 tamamlanmadan production'a alınmaz.

## Faz 4 — Release 0.5: İş Paketi Motoru ve İlk Dikeyler

```text
Planla → Hazırla → Uygula → Doğrula → Kapat
```

### Beton Paketi v2

- hazırlık ve eksik kontrolü;
- santral adı ve proje geçmişinden yeniden seçim;
- Proje/Mahal stable kimlikleri;
- mikser yaşam döngüsü ve irsaliye;
- hedef/dökülen/kalan/aşılan metraj;
- EBİS, numune, laboratuvar, yapı denetim, kür, sonuç ve eksik belge;
- uygulama, notification ve widget için tek source/read-model;
- widget'ta açık paket, dökülen/kalan, mikser sayısı ve paketi açma;
- widget ayrı state/sayaç tutmaz; paket kapanınca yalnız ilgili yüzey kaldırılır.

İlk dikeyler ayrıca Malzeme Teslimatı/İrsaliye, Numune/Laboratuvar ve
Kontrol/Uygunsuzluk akışlarıdır. AI kabul/ret vermez.

## Faz 5 — Release 0.6: Kalite, İSG ve Resmî Süreç

Kontrol listesi, test/muayene, uygunsuzluk, yeniden kontrol; tehlike/ramak kala/
iş izni/KKD; ruhsat, yapı denetim, izin, abonelik, sigorta ve süre takibi.

## Faz 6 — Release 0.7: Doküman ve Proje Hafızası

Doküman kimliği/revizyonu, PDF önizleme, proje/mahal/iş paketi bağlantılı medya,
Saha Turu, Türkçe arama ve doğrulanmış PC salt-okunur Hafıza paketi. Telefon
source-of-truth kalır.

## Faz 7 — Release 0.8: Kaynaklı AI Saha Asistanı

Her cevap kayıt, belge/revizyon, fotoğraf, tarih ve güven seviyesi gösterir.
Kaynak yoksa doğrulanmış kayıt bulunamadığı söylenir. AI teknik kabul vermez ve
sessiz mutasyon yapmaz.

## Faz 8 — Release 0.9: Planlama ve İş Cephesi Hazırlığı

İş programı içe aktarma, günlük/2–6 haftalık look-ahead, WBS-lite, bağımlılık,
kısıt, hazırlık, plan/gerçekleşen ve gecikme nedeni.

## Faz 9 — Release 1.0: Operasyon Genişlemesi ve Ürünleştirme

Araç/ekipman sicili, hafif ihtiyaç–teklif–teslim, güvenli dış görev bağlantıları,
Hafıza paketi/tek yönlü transfer, uygulama kilidi, şifreli backup, recovery,
performans, signing ve store submission. Tam ERP ve multi-user yoktur.

# 6. Zorunlu yatay kurallar

- P0–P2 varsa P3 sırası bekler; aynı anda yalnız bir production Issue aktiftir.
- İnternetsiz temel akış, migration/rollback/backup uyumu ve event/revision korunur.
- Detay dönüşünde bağlam/scroll gereksiz sıfırlanmaz.
- Tek kayıt eylemi ilgisiz platform bildirimini kapatamaz.
- Arama alanı yalnız açık kullanıcı etkileşimiyle odak alır.
- Source değişikliği önceki/yeni değer geçmişi üretir.
- Proje/Mahal bağlantısı stable kimlikle kurulur.
- Uygulama kartı, notification ve widget aynı read-model'i kullanır.
- Uzun işlem görünür durum ve kesin sonuç verir.
- Otomatik hard-delete yoktur; kalıcı silme ayrı karar, envanter ve backup kapısıdır.
- Checklist sayaçları item durumlarından hesaplanır.
- Checklist mutation otomatik log üretebilir; log ikinci düzenlenebilir gerçeklik değildir.
- Planlanan iş ve gerçekleşmiş Ajanda olayı ayrı source-of-truth kalır.
- Tarihsel log sessizce yeniden yazılmaz.
- Günlük Log Çıktısı, Backup ve AI prompt export ayrı artifact aileleridir.
- Aynı fiziksel attachment çoğaltılmaz; orijinal fotoğraf sessizce ezilmez.
- Dar UI işi schema veya tam release zincirini gereksiz tetiklemez.
- Physical smoke exact doğrulanmış artifact'i kullanır.
- Gerçek kullanıcı verisi GitHub/test/tanı çıktısına kopyalanmaz.

# 7. Backlog yerleşimi

### Hemen

1. #193 ve #245 günlük saha kabulünü sürdür.
2. #268 / Draft PR #269'u yalnız exact scope içinde güvenli sonuca getir.
3. D29.1 bildirim izolasyonunu ayrı P1 child Issue olarak çöz.
4. D29.2 arama odağı/klavye izolasyonunu ayrı P2 hotfix olarak çöz.
5. D29.3 zaman/düzenleme sürtünmelerini küçük child Issue'lara böl.
6. #257 → #254/#256 ve Draft PR #259 fiziksel kanıt olmadan Ready/merge olmaz.

### Sonraki kontrollü sıra

1. D29.4 bağlantı göstergesi ve değişiklik geçmişi;
2. D29.5 Backup görünürlüğü;
3. Proje ve Mahal Kataloğu v1;
4. Beton santral + mahal;
5. Açık Beton bildirimi ve hızlı mikser;
6. Beton widget'ı;
7. Ajanda–Hatırlatıcı kontrollü metin senkronu;
8. Günlük Log Çıktısı v1;
9. Ortak Attachment v2 + fotoğraf kırpma;
10. Proje medya albümü;
11. İş/Yapılacaklar + otomatik log;
12. İş Zinciri / Bağlı Log v1;
13. Günlük Log Çıktısı v2;
14. Sicil/Puantaj/Saha Rehberi ve sonraki araçlar;
15. ardından Universal Capture, Assistant Inbox ve Open Loop.

Özel bildirim sesleri, kullanıcı asset'leri hazır olduğunda ve D29.1 sonrasında
uygun dar pencerede uygulanır.

### Ertelenen

Hava durumu servisi, gömülü AI çağrısı, tam satın alma/ERP, gelişmiş medya
analizi, DWG/Office viewer, iki yönlü PC sync, PDF metraj ve ileri hesaplar.

### Yapılmaması gerekenler

- kullanıcıya görünmeden hard-delete veya sessiz mutasyon;
- bağlı verili projeyi yalnız parola sorarak kalıcı silmek;
- tek Hatırlatıcı eyleminde tüm bildirimleri kapatmak;
- scroll/route dönüşüyle aramayı kendiliğinden odaklamak;
- Beton kelimesinden otomatik paket veya teknik karar üretmek;
- aynı fiziksel attachment'ı çoğaltmak;
- eski Ajanda logunu sessizce yeniden yazmak;
- sistem Call Log geçmişini okumak;
- kullanıcı onaysız kişi/firma/etiket bağı veya AI mutasyonu;
- tam ERP, multi-user/SaaS, BIM/DWG/Office authoring ve teknik karar motoru.

# 8. Başarı ölçütleri

| Ölçüt | Hedef |
|---|---:|
| Günlük saha raporu işleme | Her aktif gün |
| Açık P1 | `0` |
| Tek Hatırlatıcı eyleminde ilgisiz notification kaybı | `0` |
| Kullanıcı dokunuşu olmadan Ajanda klavyesi açılması | `0` |
| Checklist sayaç/source ayrışması | `0` |
| Detay dönüşünde bağlam kaybı | `0` |
| Ajanda mutation'ında değişiklik geçmişi | `%100` |
| Proje filtresinde yanlış Hatırlatıcı | `0` |
| Backup sırasında görünür durum olmadan bekleme | `0` |
| App/notification/widget Beton read-model ayrışması | `0` |
| Yapılacak mutation'ında eksik otomatik log | `0` |
| Otomatik veya envantersiz proje hard-delete | `0` |
| Hızlı kayıt ortancası | `≤10 sn` |
| Evrensel Yakalama | `≥%80` |
| Sabah saha hâkimiyeti | `≤30 sn` |
| Bilinen kaydı bulma | `≤5 sn` |
| Günlük rapor | `≤3 dk` |
| Duplicate fiziksel attachment | `0` |
| Tarihsel logun sessiz yeniden yazılması | `0` |
| Sessiz/kaynaksız AI iddiası | `0` |
| Pilot veri kaybı | `0` |

# 9. Nihai navigasyon ve kesin sınır

```text
Bugün | Saha | + Kaydet | Takip | Asistan
```

Tam muhasebe, tenant/SaaS, bordro/cari/çek-senet, resmî teknik kabul motoru,
BIM/DWG/Office authoring, otomatik iki yönlü PC sync ve kullanıcı yerine karar
veren AI kapsam dışıdır.

Başarı modül sayısıyla değil, şefin daha az zihinsel yükle daha hızlı, eksiksiz ve
kanıtlı saha yönetimi yapmasıyla ölçülür.
