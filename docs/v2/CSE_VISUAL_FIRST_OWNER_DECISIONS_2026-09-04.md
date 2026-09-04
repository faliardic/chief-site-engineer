# CSE Visual-First Owner Kararları — 4 Eylül 2026

**Belge türü:** Kanonik owner ürün ve yürütme kararı
**Durum:** Normatif yön kaynağı; production implementation yetkisi veya
tamamlanma kanıtı değildir
**Program otoritesi:** Issue #617
**Karar kaydı:** Issue #657 / UXF-019

## 1. Otorite ve supersession

Bu belge, Issue #617 programındaki sonraki üretim sırasını ve görünür ürün
yönünü günceller. Aşağıdaki yeni kararlarla çeliştiği ölçüde eski
`Dashboard = canlı proje kontrol merkezi` yönünü ve kalan görünmez UX polish
işlerini görsel dönüşümden önce zorunlu kılan sırayı supersede eder.

UXF-002..018 ile tamamlanan adaptive shell, ortak aktif proje,
erişilebilirlik, form/primary action, arama/filtre ve hata/reload altyapısı
geçerli merged temeldir. Hiçbiri geri alınmaz, geçersiz sayılmaz veya yeniden
tamamlanmamış ilan edilmez. Kalan accessibility, adaptive davranış, recovery,
empty/loading/error/success ve history/event borcu silinmez; visual-first
dalganın ardından release kapısı olarak geri döner.

Bu belge source code, schema, persistence, migration, build, APK veya cihaz
işlemi yetkisi vermez. Her üretim dilimi ayrı dar Issue, allowlist ve gereken
doğrulama/kabul kapılarıyla yürür.

## 2. Güncel yürütme sırası

Görünür dönüşüm, kullanıcı tarafından fark edilmeyen kalan polish borcundan
önce gelir:

1. **Project Profile / Home görsel dönüşümü:** Home, seçili projenin
   düzenlenebilir Project Profile yüzeyine dönüşür.
2. **Ortak görsel dil ve ekran araçları:** ortak yüzey, boşluk, hiyerarşi ve
   sağ ekran-tool rail dili uygulanır; Inventory istisnası korunur.
3. **Yüksek sürtünmeli ekran ve formlar:** Agenda Log, Reminder, New Project,
   Ajanda gün görünümü, Personel profili ve Puantaj sadeleştirmesi dar
   dilimlerle ele alınır.
4. **Release borcuna dönüş:** kalan empty/loading/error/success,
   history/event, adaptive/accessibility, recovery ve diğer bağımsız release
   kapıları tamamlanır.

Birinci sonraki production dalgası Project Profile/Home görsel dönüşümüdür.
Bu sıra, UXF-002..018'in tamamlanmış altyapı statüsünü değiştirmez.

## 3. Home ve Project Profile

- Home artık Dashboard/live control center değildir; seçili projenin
  düzenlenebilir **Project Profile** yüzeyidir.
- Varsayılan profil bilgileri proje adı, toplam kat, toplam alan ve YİBF no
  gibi temel proje bilgilerini içerir.
- Bilgi blokları dokunarak düzenlenebilir; owner ihtiyacına göre keyfî ek
  alanlar tanımlanabilir ve bloklar yeniden sıralanabilir.
- Diğer modüllere kompakt bir `Araçlar` girişi üzerinden ulaşılır.
- Bu yönün persistence modeli, schema etkisi, field type sistemi, doğrulama,
  migration ve reorder saklama biçimi bu karar belgesinde seçilmez; bunlar
  ayrı yetkili üretim dilimlerinin konusudur.

## 4. Ekran araçları ve Inventory istisnası

Genel dilde Reminder, Ajanda, Puantaj, Beton ve Saha Rehberi gibi ekranların
ikincil araçları sağ tarafta, başparmakla erişilebilir dikey bir ekran-tool
rail içinde toplanır. Birincil form eylemleri görünür ve metinli kalır;
destructive eylemler riskin gerektirdiği açık metin ve confirmation dilini
korur. Sağ rail bir ana navigation alternatifi veya her eylemi icon-only yapma
yetkisi değildir.

**Inventory bu genel kuralın açık istisnasıdır.** Mevcut sağ Inventory rail'i
canvas alanı tükettiği için supersede edilir; Inventory context, filtre ve
harita araçları kompakt üst alana döner. Soldaki Kroki/Katlar/Liste rail'i
korunur. Sketch editor selection ve D-pad yönü sonraki ayrı production
dilimidir; hareket adımı, seçim modeli ve persistence davranışı burada
belirlenmez.

## 5. Kilitli yüzey kararları

- **Ajanda:** üstte aylık/haftalık takvim geçişi bulunur; güne dokunmak o günün
  kayıtlarını gösterir. Arama ve filtre ekran araçları olarak kalır.
- **Formlar:** Agenda Log, Reminder ve New Project; sıkışık küçük kutu
  yığınları yerine ferah, progressive-disclosure yüzeyleri olur.
- **Personel:** Sicil'de kişi adına dokunmak en az ad, taşeron/firma, meslek,
  başlangıç tarihi, toplam puantaj ve notları gösteren profil özetini açar.
- **Puantaj:** büyük ölçüde sadeleştirilir. Puantaj tamamlama, duplicate
  oluşturmadan bağlı Ajanda kaydı üretir; exact senkronizasyon, identity,
  transaction ve failure semantiği ayrıca yetkilendirilmeden belirlenmez.

## 6. Sonraki ayrı dilimler için kaydedilen kararlar

- Otomatik backup klasörü.
- Metrajın ana keşif/metraj kalemlerinin tümüne genişlemesi.
- Bildirimde genişletilmiş `Ertele` eylemi.
- Uygulama genelinde alt soldan erişilen geçici cetvel aracı.

Bu başlıklar yön kararıdır, implementation sözleşmesi değildir. Backup
hedefi/rotasyonu, Metraj kapsam taksonomisi, snooze süresi/seçenekleri, cetvel
kalibrasyonu ve birimi ile Puantaj→Ajanda persistence/senkron ayrıntıları
uydurulmaz; ayrı Issue ve risk değerlendirmesi gerektirir.

## 7. Değişmeyen sınırlar

- CSE owner-only, local-first ve mobile-first kişisel saha asistanıdır.
- Stable identity, optimistic revision, append-only event/history,
  transaction, attachment ve backup/restore bütünlüğü korunur.
- Ajanda, Hatırlatıcı ve diğer kaynak kayıtların source-of-truth ayrımları
  sessizce birleştirilmez.
- UXF-002..018'in merged davranışları ve tarihsel kabul kanıtı korunur.
- DWG Viewer ilk genel yayın için `POST-RELEASE / DEFERRED` kalır.
- Public/store release ve gerçek kullanıcı verisi işlemleri ayrı owner kararı
  gerektirir.
