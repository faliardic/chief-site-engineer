# CSE 2026.3.1 — Asistan-Öncelikli Ürün Yol Haritası

**Durum:** Kanonik ürün sırası  
**Tarih:** 25 Temmuz 2026
**Ürün Epic'i:** #105  
**Yürütme Epic'i:** #127  
**Güncel saha backlog'u:** #219
**Önceki saha backlog'u:** #203
**Açık Release 0.1 pilotu:** #193

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

## 2. Başlangıç noktası

Release 0.1 çekirdeğinde mobil runtime, Ajanda, Hatırlatıcı, Puantaj, taşeron–ekip–
personel sicili, Beton Paketi, mikser/irsaliye/numune/laboratuvar, fotoğraf ve PDF,
parola korumalı backup/restore ve Android release güvenliği uygulanmıştır.
Tamamlanan ana dilimler: #179, #183, #185, #187, #189, #191, #194, #196,
#198, #200, #202, #207, #212 ve #214.

Bu sürümün güvenli dokümantasyon başlangıç noktası
`d4ccc480570a971cf014ddbe00122ec6132cad01` commit'idir. Bu noktada PR #217'nin
minimum yeterli doğrulama protokolü ve PR #218'in `Yarın` görünümü `master`
üzerindedir.

Açık ilk kapı #193 gerçek cihaz saha kabulüdür. Gün 0 PASS kanıtı geçerlidir;
Issue #193 kapanmış sayılmaz ve yedi günlük pilot sürer. Pilot ile Release 0.1.1
günlük güvenilirlik/sadeleştirme sırası ayrı iş akışlarıdır. Ayrıntılı tamamlanma
geçmişi Issue'larda, `CHANGELOG.md` ve karar belgelerinde tutulur; bu dosya ileri
ürün sırasını tanımlar.

## 3. Yeni öncelik sırası

```text
Güvenilir saha sürümü
→ Günlük güvenilirlik ve sadeleştirme
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

# 4. Fazlar

## Faz 0 — Release 0.1 gerçek saha kabulü

**Amaç:** Mevcut çekirdeğin gerçek telefonda güvenilirliğini kanıtlamak.

- Ajanda, Hatırlatıcı, Puantaj ve Beton birlikte kullanılır.
- Kapalı uygulama reminder teslimi doğrulanır.
- Backup, dışa çıkarma, preflight ve restore yürütülür.
- Fotoğraf, irsaliye, kayıt, restart ve güncelleme bütünlüğü doğrulanır.
- Mevcut kritik Beton/mikser sürtünmeleri bakım hattında çözülür.

**Kapı:** En az 7 ardışık gerçek gün; veri kaybı `0`; sessiz kritik notification
başarısızlığı `0`; restore farkı `0`; açık kritik blocker `0`.

---

## Faz 0.1 — Release 0.1.1: Günlük Güvenilirlik / Sadeleştirme

**Amaç:** Universal Capture'a geçmeden önce günlük kullanım sürtünmelerini,
yanlış gün/saat anlamlarını, geri alınamaz kullanıcı işlemlerini ve kaynak
bağlantısı kopukluklarını dar child Issue'larla kapatmak.

Kanonik uygulama sırası:

1. **Reminder scheduling contract:** hızlı `Bugün`, sahte saat olmayan gerçek
   `Tam gün` ve reminder içindeki legacy `Bekliyorum` tür/schedule/status/filtre
   yüzeyinin kayıpsız kaldırılması. Gelecekteki `Beklediklerim`, reminder durumu
   değil Faz 2 Open Loop kaydıdır.
2. **Birleşik ve sade Bugün:** gecikenler, saatli bugün ve tam gün işleri tek ana
   yüzeyde gösterilir; kullanıcı önce filtre seçmek zorunda kalmaz. Saatsiz
   bugünkü işler için ayarlanabilir varsayılan gecikme eşiği `18:00` olur;
   yanlış `Bugün`/`Yarın` etiketleri giderilir.
3. **Reminder geri dönüşüm kutusu:** silme, geri yüklenebilir archive/trash'tır;
   notification binding güvenle kaldırılır ve restore sırasında yeniden
   üretilebilir. Issue #227 ile schema 9, append-only trash/restore event'leri
   ve `Diğer > Geri Dönüşüm Kutusu` yüzeyi uygulanmıştır. İlk sürümde otomatik
   hard-delete yoktur.
4. **Ajanda → reminder kaynak attachment görünürlüğü:** kaynak Ajanda fotoğrafı
   veya dosyası reminder detayında görünür; geniş attachment refactor'ı
   başlamadan dar read-model bağı düzeltilir.
5. **Beton sınıfı ve döküm zaman çizgisi:** proje kataloğundan beton sınıfı,
   `Planlandı → Devam ediyor → Tamamlandı`, gerçek başlat/bitir zamanı ve tek
   bağlı Ajanda logu aynı Beton source-of-truth kaydından yürür.
6. **Beton kelime önerisi/deep-link:** `beton`, `betonaj` gibi sinyaller yalnız
   kullanıcıya öneri ve `Beton paketine git` bağlantısı üretir; otomatik Beton
   kaydı, paket veya teknik karar üretmez.
7. **Ortak attachment v2:** fotoğraf, video, ses ve dosya için tek fiziksel
   attachment + çoklu kayıt bağlantısı; çoklu seçim, managed storage,
   hash/MIME/boyut ve backup/restore uyumluluğu.
8. **Proje fotoğraf/video albümü:** proje, tarih, kategori ve kaynak kayıt
   bağlantısıyla medya görünümü; kaynak dosya ikinci kez kopyalanmaz.
9. **Taşeron/personel/Puantaj UX:** #204 ile aynı kimlik omurgasında
   taşeron → personel seçimi, inline yeni kişi, adres ve OSGB/sigorta uyarısı.
10. **İstenecek Malzemeler:** malzeme, miktar/birim, ihtiyaç tarihi, öncelik,
    açıklama ve `İhtiyaç var → İstendi → Geldi/İptal` durumu; tam satın alma
    sistemi değildir.
11. **Kaynaklı AI prompt export:** önce günlük, sonra hafta/ay/yıl için
    deterministik ve kaynak bağlantılı metin; gömülü AI çağrısı, otomatik
    gönderim veya sessiz kayıt mutasyonu yoktur.
12. **Mini hesap makinesi:** temel işlemler ve kullanıcının onayladığı sayısal
    alana kontrollü sonuç aktarımı; ileri mühendislik hesapları ayrı dikeydir.
13. **Hava durumu uyarıları:** haricî servis, proje konumu, cache/offline
    fallback, kullanıcı eşiği ve bildirim tercihi tasarımı sonrasına ertelenir;
    her hava değişimi notification üretmez.

**Kapı:** Blok 1–12 ayrı, dar ve doğrulanmış child Issue'larla tamamlanmadan Faz 1
production implementation'ı başlamaz. Blok 13 kanonik sırada korunur fakat
haricî servis/eşik tasarımı nedeniyle ertelenmiş iştir ve gömülü AI, tam ERP,
otomatik hard-delete, otomatik Beton creation veya duplicate attachment için
erken yetki vermez.

İlk production child #221 Reminder scheduling contract'tır. Bu roadmap branch'i
Blok 1 veya sonraki production davranışını uygulamaz.

---

## Faz 1 — Release 0.2: Sürtünmesiz Evrensel Yakalama

**Amaç:** Her saha olayını 5–15 saniyede kayda dönüştürmek.

Uygulamanın her yerinden tek işlem:

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

- iş programı içe aktarma;
- günlük plan ve 2–6 haftalık look-ahead;
- bağımlılık ve kısıt listesi;
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

# 5. Zorunlu yatay kurallar

- Her faz migration, backup/restore, event, revision, hash ve archive testlerinden geçer.
- Yeni saha özelliği internetsiz temel akışı tamamlamadan kapanmaz.
- Kayıt süresi, dokunma, vazgeçme ve tekrar giriş içerik toplamadan ölçülür.
- En az 44 px hedef, tek el, güneş, büyük metin, açık hata ve geri alma korunur.
- Önemli değişikliklerde kim, ne zaman, önceki/yeni değer ve dayanak görünürdür.
- Aynı anda yalnız bir production implementation Issue'su aktif olur.

# 6. Backlog yerleşimi

### Hemen

- #193 Release 0.1 pilotu açık kalır ve mevcut Gün 0 kanıtıyla devam eder.
- #220 roadmap hizalamasından sonra ilk production child #221 Reminder scheduling
  contract'tır.
- Birleşik Bugün #225 ile, reminder trash/restore #227 ile tamamlanmıştır.
  Sıradaki production bloğu Ajanda → reminder kaynak attachment
  görünürlüğüdür; Beton sınıfı/zaman çizgisi veya Beton keyword önerisi henüz
  başlamaz.

### Sonraki kontrollü sıra

- Ortak attachment v2 ve proje fotoğraf/video albümü.
- #204 ile taşeron/personel/Puantaj UX.
- İstenecek Malzemeler, kaynaklı AI prompt export ve mini hesap makinesi.
- Bu kapılardan sonra Faz 1 Universal Capture, Voice Capture/Assistant Inbox ve
  Faz 2 Open Loop sırası korunur.

### Ertelenen

- Hava durumu servisi ve proaktif uyarılar; önce konum, cache/offline fallback,
  eşik ve kullanıcı bildirim tercihleri tasarlanır.
- Gömülü/doğrudan AI servis çağrısı; ilk adım yalnız kaynaklı prompt export'tur.
- Tam satın alma/ERP, gelişmiş video işleme ve otomatik medya analizi.
- Güvenli, salt-okunur gömülü DWG/Office/proje dokümanı viewer nihai ürün
  hedefidir; iki yönlü PC sync, PDF metraj ve ileri mühendislik hesaplarıyla
  birlikte ertelenmiştir.

### Kapsam dışı / yapılmaması gerekenler

- Reminder içinde legacy `Bekliyorum` durumunu yeniden canlandırmak; gelecekteki
  `Beklediklerim` Open Loop modelinde ayrı kavramdır.
- Kullanıcıya görünmeden otomatik hard-delete, otomatik kayıt kapatma veya sessiz
  veri mutasyonu.
- Beton kelimesinden otomatik Beton paketi/kaydı veya teknik karar üretmek.
- Aynı fiziksel attachment'ı Ajanda, reminder, Beton veya albüm için çoğaltmak.
- Kaynaksız AI raporu, kullanıcı onayı olmadan AI mutasyonu veya embedded AI'yı
  erken eklemek.
- Tam ERP, multi-user/tenant/SaaS, BIM/DWG/Office düzenleme, authoring ve teknik
  karar motoru.

# 7. Release 0.1 sonrası ilk Issue kuyruğu

Release 0.1.1 günlük güvenilirlik/sadeleştirme kuyruğu:

1. #221 Reminder scheduling contract;
2. birleşik ve sade Bugün görünümü — Issue #225 ile tamamlandı;
3. reminder recoverable trash/restore — Issue #227 ile tamamlandı;
4. sıradaki blok: Ajanda → reminder kaynak attachment görünürlüğü;
5. Beton sınıfı, başlat/bitir ve tek bağlı Ajanda logu;
6. Beton keyword önerisi/deep-link;
7. ortak attachment v2 ve çoklu medya/dosya;
8. proje fotoğraf/video albümü;
9. #204 taşeron/personel/Puantaj UX;
10. İstenecek Malzemeler;
11. kaynaklı AI prompt export;
12. mini hesap makinesi;
13. hava durumu uyarıları — haricî servis/eşik tasarımı nedeniyle ertelenmiş.

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

# 8. Nihai navigasyon

```text
Bugün | Saha | + Kaydet | Takip | Asistan
```

Malzeme, kalite, İSG, evrak ve ekipman ayrı ana ikon yığını oluşturmaz; ilgili iş
paketi, Saha, arama, Asistan veya ikincil `Tüm araçlar` alanından açılır.

# 9. Başarı ölçütleri

| Ölçüt | Hedef |
|---|---:|
| Hızlı kayıt ortancası | `≤10 sn` |
| Evrensel Yakalama oranı | `≥%80` |
| Sabah saha hâkimiyeti | `≤30 sn` |
| Bilinen kaydı bulma | `≤5 sn` |
| Günlük rapor | `≤3 dk` |
| Takip tarihi/terminal durumu olan açık döngü | `%100` |
| Sessiz AI mutasyonu | `0` |
| Kaynaksız AI proje iddiası | `0` |
| Pilot veri kaybı | `0` |

# 10. Kesin kapsam dışı

- tam muhasebe veya şirket ERP'si;
- çok kullanıcılı tenant/SaaS;
- bordro, cari ve çek/senet;
- resmî onay veya teknik kabul motoru;
- BIM/DWG/Office düzenleme, authoring ve teknik karar motoru;
- otomatik iki yönlü PC senkronu;
- otomatik hard-delete veya Beton kelimesinden otomatik kayıt/paket;
- aynı fiziksel attachment'ın modüller arasında kopyalanması;
- kullanıcı yerine karar veren, kaynak göstermeyen veya sessiz mutasyon yapan AI.

Başarı modül sayısıyla değil, şefin daha az zihinsel yükle daha hızlı, eksiksiz ve
kanıtlı saha yönetimi yapmasıyla ölçülür.
