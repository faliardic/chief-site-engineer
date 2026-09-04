# CSE Sürtünmesiz UI/UX Sistem Sözleşmesi

**Belge türü:** Kanonik ürün arayüzü ve etkileşim sözleşmesi
**Tarih:** 4 Eylül 2026
**Durum:** Normatif ürün sözleşmesi; production implementation yetkisi veya
tamamlanma kanıtı değildir
**Program otoritesi:** Issue #617
**Kanıt tabanı:** Issue #616; manuel kabul PASS'i değildir

## 1. Amaç ve otorite sınırı

Bu belge, CSE'nin ilk genel yayın öncesi bütün UI/UX dilimlerinin uyması gereken
ortak sistemi tanımlar. CSE yeni büyük modüller ekleyerek değil, mevcut güçlü
özellikleri adaptive, erişilebilir, tutarlı, kendini açıklayan ve sahada minimum
sürtünmeyle çalışan tek bir kişisel saha asistanında birleştirerek ilerler.

Kalıcı ürün ve veri ilkelerinde
`docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`, kilitli ürün davranışlarında
`docs/post_v2_locked_feature_decisions.md`, güncel program sırasında Issue #617,
4 Eylül 2026 visual-first ürün ve sıra kararlarında
`docs/v2/CSE_VISUAL_FIRST_OWNER_DECISIONS_2026-09-04.md`,
V2 kapsam ve yürütme sırasında `docs/v2/CSE_V2_SCOPE.md` ile `ROADMAP.md`
yetkilidir. Aktif production diliminin exact kapsamı ayrıca kendi GitHub
Issue'sundan gelir.

Bu sözleşme:

- mevcut production davranışını kendiliğinden değiştirmez;
- herhangi bir UI işini implemented, accepted veya release-ready ilan etmez;
- schema, migration, backup/restore, stable identity, revision, event/history,
  transaction, attachment bütünlüğü veya source-of-truth sınırını gevşetmez;
- her production değişikliği için ayrı, dar Issue/PR ve gereken owner kabul
  kapılarını zorunlu bırakır.

## 2. Ürün anayasası

Bütün ekran, ortak bileşen ve akış kararları şu ilkelerden birlikte geçer:

1. CSE modül koleksiyonu değil, local-first ve mobile-first kişisel saha
   asistanıdır.
2. Arayüz sürtünmesiz, kolay öğrenilebilir ve kendini açıklayan olmalıdır.
3. Saha işi minimum dokunuş ve minimum zorunlu veri girişiyle yürümelidir.
4. Önce yakala, sonra ayrıntılandır ilkesi korunur.
5. Aynı bilgi kullanıcıya ikinci kez girdirilmez.
6. Eylem ihtiyaç duyulan bağlamda bulunur; kullanıcı menü avına zorlanmaz.
7. Aktif proje bütün proje-bağımlı ekranlarda kesintisiz ortak bağlamdır.
8. Home, seçili projenin düzenlenebilir Project Profile yüzeyidir; diğer
   modüllere kompakt `Araçlar` girişiyle ulaşılır.
9. İpuçları kullanım talimatı değil, özelliğin saha faydasının kısa
   açıklamasıdır.
10. Görsel dil sade, kontrollü, modern ve düşünülmüş olmalıdır.
11. Motion yalnız akış, durum değişimi ve geri bildirim için kullanılır.
12. Sürtünme azaltılırken veri bütünlüğü ve açık kullanıcı kontrolü korunur.
13. CSE yaygın saha işlerinde kâğıt, not, WhatsApp, galeri ve Excel'den daha
    hızlı olmayı hedefler.
14. Bir özellik ancak unutma, kanıtlama, takip, raporlama veya daha sonra geri
    çağırmayı kolaylaştırıyorsa doğrudan saha değeri üretir.

## 3. Adaptive shell sözleşmesi

- Layout cihaz adına, modeline veya yalnız orientation değerine göre değil,
  kullanılabilir pencere boyutuna göre uyarlanır.
- Compact pencerede en fazla beş ana destination görünür ve her destination'ın
  metin etiketi sürekli görünürdür. Semantics etiketi, görünür etiketin yerine
  geçen gizli bir çözüm değildir.
- Bu belgede final beş compact destination, sıraları veya üyelikleri
  seçilmez. Bu seçim Phase 1'de ayrı bir shell Issue'su ve owner review'uyla
  verilecek ilk uygulama kararıdır.
- Medium ve expanded pencereler navigation rail ve kullanılabilir alana uyumlu
  içerik düzeni kullanır; tablet üzerinde telefon bottom bar'ı aynen uzatılmaz.
- Uygulama orientation'ı zorla kilitlemez. Portrait, landscape, pencere yeniden
  boyutlandırma ve split-screen geçişleri kullanıcı durumunu korur.
- Expanded yüzey, ürün değerini artırdığı yerde grid veya list-detail düzeni
  kullanabilir. Yalnız daha fazla alan var diye içerik çoğaltılmaz.
- Büyük ekran, tek kolonlu telefon formunu kontrolsüz biçimde genişletmez;
  okunabilir max-width, mantıksal kolonlar veya bağlam paneli kullanır.
- Navigation destination, layout eşiği ve shell geçişleri source kaydı mutate
  etmez; yalnız görünüm ve route bağlamını değiştirir.

## 4. Ortak aktif proje sözleşmesi

- Proje-bağımlı ekranlar aynı ortak, görünür aktif-proje bileşenini kullanır;
  ekran başına farklı selector dili veya ikinci bir proje state'i oluşturmaz.
- Selector bir dokunuşta açılır, proje ikinci dokunuşta seçilir. Normal proje
  değiştirme akışı en fazla iki açık kullanıcı dokunuşudur.
- Aktif proje modüller arasında korunur; kullanıcı yeni modüle geçtiğinde aynı
  projeyi yeniden seçmez.
- Yeni proje-sahipli kayıt, aktif projeyi varsayılan alır. Domain bakımından
  anlamlıysa kullanıcıya bilinçli ve görünür override bırakılır; override gizli
  bağlam değişimi yapmaz.
- Ayarlar, Hakkında ve proje-bağımsız araçlar aktif-proje bileşenini göstermez.
- Görünür etkileşim alanı ile Semantics sınırı birebir eşleşir; bileşenin adı,
  seçili proje durumu, role'ü ve enabled/disabled durumu erişilebilirlik
  ağacında anlamlıdır.
- Aktif proje değiştirmek navigation/context işlemidir; yalnız bu işlem
  nedeniyle source kayıt, revision, event/history veya dosya bağı değişmez.

### 4.1. Home / Project Profile

- Home seçili projenin düzenlenebilir Project Profile yüzeyidir; eski canlı
  kontrol merkezi yönü current değildir.
- Proje adı, toplam kat, toplam alan ve YİBF no gibi varsayılan bilgiler; owner
  tanımlı ek alanlar ve yeniden sıralanabilir bilgi bloklarıyla birlikte
  dokunarak düzenlenebilir bir profil dili kullanır.
- Diğer modüller kompakt `Araçlar` girişinden erişilir; profil yüzeyi modül
  menüsü veya bakım paneliyle doldurulmaz.
- Persistence/schema, field type, validation, migration ve reorder saklama
  ayrıntıları ayrı yetkili production diliminde seçilir.

## 5. Erişilebilirlik ve etkileşim hedefi

- Telefon ve tabletlerde her birincil veya kritik kontrolün gerçek, görünür ve
  semantik etkileşim alanı en az `48×48 dp` olur. İkon daha küçük çizilebilir;
  fakat etkileşimli yüzey gizli padding ile anlaşılmaz hâle getirilemez.
- Görünür hit area, pointer/touch hit-test alanı ve Semantics bounds aynı
  sınırı temsil eder. Semantics label, role, state, value ve enabled/disabled
  bilgisi görünen davranışla eşleşir.
- İkon aksiyonları anlamlı Tooltip ve Semantics label taşır. Tooltip,
  anlaşılmaz birincil eylemi icon-only bırakmak için gerekçe değildir.
- Text/display scaling içerik veya eylem kaybı, clipping ya da erişilemez
  kontrol üretmez. Odak sırası görsel ve görev sırasını izler.
- Metin ve kontroller yeterli contrast taşır; seçim, hata, başarı, disabled veya
  risk durumu yalnız renkle anlatılmaz.
- Erişilebilirlik ortak bileşenin başlangıç sözleşmesidir; sonradan eklenen
  polish veya yalnız test etiketi değildir.
- #566, #571 ve #584'teki eski `40×40` telefon/tablet baseline'ı bu kuralla
  çeliştiği yerde geçersizdir.

## 6. Eylem hiyerarşisi

- Her yüzey, o anki görevi tamamlayan tek ve açık birincil eyleme sahiptir.
- Birincil eylemler görünür ve anlaşılırdır; varsayılan olarak belirsiz
  icon-only kontrole indirgenmez.
- Form tamamlama dili bağlama göre tutarlı `Kaydet`, `Oluştur` veya `Tamamla`
  fiilini kullanır ve yüzeyler arasında öngörülebilir konumda bulunur.
- Tekrarlanan ikincil eylemler, evrensel olarak anlaşılır olduklarında ikon
  olabilir; en az `48×48 dp` yüzey, Tooltip ve anlamlı Semantics zorunludur.
- Destructive veya geri alınamaz kararlar açık metinli eylem ve riskin
  gerektirdiği confirmation'ı korur. Güvenli, geri alınabilir işlemde uygun
  undo tercih edilir.
- Aynı önemde birden çok birincil eylem yarıştırılmaz; ikincil ve tertiary
  eylemler görsel hiyerarşide geride kalır.

### 6.1. Sağ ekran-tool rail dili

- Reminder, Ajanda, Puantaj, Beton ve Saha Rehberi gibi ekranlarda tekrarlanan
  ikincil ekran araçları başparmakla erişilebilir sağ dikey tool rail içinde
  toplanır.
- Rail, primary navigation yerine geçmez; birincil form eylemlerini veya
  destructive kararları icon-only yapmaz.
- Birincil eylemler görünür/metinli, destructive eylemler açık risk ve gereken
  confirmation diliyle kalır.
- Inventory açık istisnadır: canvas alanını tüketen sağ rail kaldırılır;
  context, filtre ve harita araçları kompakt üst alana taşınır. Soldaki
  Kroki/Katlar/Liste rail'i korunur.
- Inventory sketch selection ve D-pad davranışının ayrıntıları ayrı production
  dilimidir; bu sözleşme hareket adımı, seçim modeli veya persistence seçmez.

## 7. Formlar ve progressive disclosure

- Zorunlu alanlar önce gelir; opsiyonel ayrıntılar ilk yakalamayı geciktirmez.
- Akış `önce yakala → sonra ayrıntılandır` biçimindedir. İlk kayıt için domainin
  gerektirmediği alan zorunlu yapılmaz.
- Compact form tek kolonludur. Expanded form kontrolsüz uzamaz; okunabilir
  max-width, mantıksal kolonlar veya görevle ilgili context pane kullanır.
- Klavye, safe inset veya pencere boyutu birincil eylemi kapatmaz; kullanıcı
  girdi ve seçimini kaybetmeden klavyeyi yönetebilir.
- Validation ilgili alanın yanında, insan dilinde ve düzeltme yönüyle gösterilir.
  Hata sonrasında geçerli girişler silinmez; duplicate submit engellenir ve
  loading durumu açıktır.
- Aktif proje veya mevcut kayıt bağlamı forma yeniden yazdırılmaz. Deliberate
  override varsa mevcut değer görünür ve değişiklik açık kullanıcı işlemidir.
- Agenda Log, Reminder ve New Project formları ferah progressive-disclosure
  yüzeyleri olarak tasarlanır; küçük ve sıkışık kutu yığınına dönüştürülmez.

## 8. Arama, filtre ve list-detail

- Asıl içerik advanced kontrollerden önce gelir; boş yüzey filtre paneliyle
  başlamaz.
- Uygulama boyunca tanınabilir tek bir arama deseni kullanılır. Arama kapsamı
  ve sonuç bağlamı kullanıcı için anlaşılırdır.
- Advanced filtreler tek bir filtre eyleminin arkasındadır. Aktif filtreler
  sonuç yüzeyinde görünür, tek tek veya topluca temizlenebilir durumdadır.
- Arama sorgusu, filtre, sıralama ve scroll/list bağlamı detail'e girip geri
  dönüldüğünde korunur.
- Empty result ile teknik query failure aynı sunulmaz; kullanıcı filtrenin mi
  verinin mi sonucu daralttığını anlayabilir.
- Expanded list-detail yalnız navigation maliyetini gerçekten azaltıyor ve
  seçili kayıt bağlamını açık tutuyorsa kullanılır; compact akışın kaynak
  davranışını değiştirmez.
- Ajanda üstte aylık/haftalık takvim geçişi sunar; güne dokunmak o günün
  kayıtlarını gösterir. Arama ve filtre aynı ekran-tool dilinin parçasıdır.
- Sicil'de kişi adına dokunmak en az ad, taşeron/firma, meslek, başlangıç
  tarihi, toplam puantaj ve notları gösteren profil özetini açar.

## 9. Empty, loading, error, success ve history dili

- `Veri yok`, `bu filtrede sonuç yok`, `henüz kayıt yok` ve teknik failure
  birbirinden ayrılır.
- Empty state neyin eksik olduğunu söyler ve yalnız ilgili tek sonraki eylemi
  sunar.
- Loading mevcut bağlamı gereksiz yere silmez, duplicate action'ı önler ve
  belirsiz uzun beklemeyi sessiz bırakmaz.
- Error mesajı kullanıcı dilindedir; mümkünse güvenli retry veya recovery yolu
  gösterir. Raw exception, internal event code ve developer copy normal UI'da
  gösterilmez.
- Success geri bildirimleri ortak dil ve presentation kullanır. Recoverable
  mutation açık feedback ve uygun olduğunda undo sağlar.
- History kullanıcıya eylem, sonuç ve anlaşılır yerel tarih-saat olarak
  sunulur; raw event code veya yalın ISO timestamp gösterilmez. İnsan dili
  source event/history gerçeğini yeniden yazmaz veya gizlice birleştirmez.

## 10. Motion ve görsel dil

- Görsel dil sade, kontrollü, modern ve düşünülmüş kalır; dekoratif “premium”
  gösteri hedeflenmez.
- Material 3 ortak component davranışı ve tutarlılık altyapısıdır; wholesale
  expressive rebranding yetkisi değildir.
- Navigation, expand/collapse, selection, save ve status feedback için standart,
  kısa ve işlevsel motion kullanılabilir.
- Decorative bounce, persistent glow, sürekli attention animation ve işlemi
  geciktiren motion kullanılmaz.
- Motion bilgi veya state'in tek taşıyıcısı değildir. Reduced-motion uyumluluğu
  mümkün kalır ve motion azaltıldığında görev tamamlanabilirliği değişmez.

## 11. Platform davranışı

- Yüzeyler edge-to-edge düzeni safe inset, system bar, keyboard ve katlanabilir/
  yeniden boyutlandırılabilir pencere sınırlarını dikkate alarak kullanır.
- Predictive Back anlaşılır route stack ile çalışır; geri hareketi beklenmedik
  module jump, duplicate route veya source mutation üretmez.
- Kaydedilmemiş anlamlı form değişikliği varsa çıkış koruması gerekir. Boş veya
  değişmemiş form gereksiz confirmation ile sürtünme yaratmaz.
- Resize, orientation, background ve reopen sonrasında güvenle korunması gereken
  aktif proje, navigation, form draft ve arama/filtre bağlamı kendi açık
  sözleşmesine göre tutulur.
- Navigation veya aktif-proje switching tek başına source kayıt, schema,
  revision, event/history, attachment ya da backup gerçeğini değiştirmez.
- Platforma özgü route/back/inset davranışı ortak ürün anlamını ve
  erişilebilirliği bozmaz.

## 12. Nicel kabul hedefleri

Her production child Issue, kapsamına giren hedefleri executable veya manuel
kanıtla ölçer:

| Hedef | Kabul eşiği |
| --- | --- |
| Aktif proje değiştirme | En fazla 2 açık dokunuş |
| Modüller arasında proje yeniden seçimi | 0 |
| Basit Hatırlatıcı | 1 zorunlu metin girdisi; hedef en fazla 6 açık karar/dokunuş |
| Hatırlatıcıdan Unutma Kutusu | 1 dokunuş |
| Ajanda → Hatırlatıcı | Başlık ve proje yeniden girilmez |
| Kullanıcıya görünen internal event code | 0 |
| Etiketsiz primary navigation destination | 0 |
| Kritik eylem alanı | Görünür alan = hit-test = Semantics; en az `48×48 dp` |
| Project Profile'da proje bilgisine rakip modül/araç kalabalığı | 0 |

Bu hedefler dokümantasyonla tamamlanmış sayılmaz; ilgili production diliminin
validation ve gerekiyorsa owner manuel kabul kapısında kanıtlanır.

## 13. Supersession haritası

Issue #617 ve bu sözleşme yalnız çelişen hükümleri supersede eder:

| Tarihsel kaynak | Korunan gerçek | Geçersiz çelişen kural |
| --- | --- | --- |
| #539 | Mevcut özellik kalitesi, günlük saha sürtünmesi ve dar child yaklaşımı | Eski dalga sırası ve DWG'yi ilk yayın öncesi bağımlılık sayma |
| #566 | Okunabilirliği koruyan compact bilgi yoğunluğu | Telefon/tablet için `40 px` hedefi yeterli sayma |
| #571 | İkincil ikonlarda tutarlı sözlük, Tooltip ve Semantics | Etiketleri gizleyen ana navigation ve agresif icon-first primary action |
| #584 | Merged Ajanda işlevleri, key/callback/domain ve confirmation davranışı | `40×40` icon-only save/create/edit/archive varsayılanı |

4 Eylül 2026 visual-first owner kararı ayrıca önceki `Dashboard = canlı proje
kontrol merkezi` yönünü Project Profile/Home ile ve kalan Step 10/11 görünmez
polish işlerini görsel dönüşümden önce zorunlu kılan sırayı visual-first
dalga ile supersede eder. UXF-002..018'in merged altyapısı korunur.

Mevcut merged işlevler geri alınmaz; sonraki dar dilimler bunları bu sözleşmeye
uyarlar. Tarihsel Issue/PR/test/manuel kabul kanıtı silinmez veya geriye dönük
yeniden yazılmaz. Çelişki olmayan ürün ve veri sözleşmeleri yürürlükte kalır.

## 14. Fazlı implementation haritası

UXF-002..018 ile adaptive/accessibility foundation ve tamamlanan ortak
interaction dilimleri geçerli merged temeldir. Güncel sıra:

1. **Project Profile / Home visual transformation:** Home, seçili projenin
   düzenlenebilir Project Profile yüzeyine dönüşür; modüller kompakt `Araçlar`
   girişinden erişilir.
2. **Shared visual language and screen tools:** ortak yüzey/boşluk/hiyerarşi ve
   genel sağ tool-rail dili; Inventory için kompakt üst araç alanı istisnası.
3. **High-friction forms and screens:** Agenda Log, Reminder, New Project,
   Ajanda gün görünümü, Personel profili ve Puantaj sadeleştirmesi ayrı dar
   dilimlerle ele alınır.
4. **Return to release debt:** kalan empty/loading/error/success,
   history/event, adaptive/accessibility, recovery/backup, arama/onboarding,
   telemetry/privacy ve bütünleşik kalite kapıları.
5. **Release candidate:** birleşik automated milestone kapıları,
   analyze/build/artifact provenance; owner phone/tablet release-candidate
   kabulü; açık owner genel yayın kararı.

Her production adımı tek dar Issue/PR olarak yürür; aynı anda yalnız bir
production implementation Issue'su aktiftir ve stacked PR açılmaz. Bu
truth-sync sonraki production değişikliğine kendiliğinden yetki vermez.

## 15. İlk sonraki karar ve korunacak kapılar

İlk sonraki production dalgası Project Profile/Home görsel dönüşümüdür.
Project Profile'ın persistence/schema modeli, ek alan tipleri ve reorder saklama
biçimi; Inventory D-pad adımı; cetvel kalibrasyonu; bildirim snooze süresi ve
Puantaj→Ajanda senkron semantiği ayrı yetkili dilimler olmadan belirlenmez.

DWG Viewer / Issue #523 `POST-RELEASE / DEFERRED` kalır ve ilk genel yayının
bağımlılığı değildir. Issue #479'daki manuel kabul borcu; #501, #502 ve #503
recovery/backup/update kapıları; #499 MAIN-only owner-phone sınırı; privacy,
telemetry ve release-candidate kabulü korunur. Ready, merge, Issue closure ve
public/store release yalnız ayrı owner kararıyla yapılır.
