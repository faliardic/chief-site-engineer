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
8. Dashboard bir menü değil, canlı proje kontrol merkezidir.
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
| Dashboard'da günlük içeriğe rakip bakım araçları | 0 |

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

Mevcut merged işlevler geri alınmaz; sonraki dar dilimler bunları bu sözleşmeye
uyarlar. Tarihsel Issue/PR/test/manuel kabul kanıtı silinmez veya geriye dönük
yeniden yazılmaz. Çelişki olmayan ürün ve veri sözleşmeleri yürürlükte kalır.

## 14. Fazlı implementation haritası

Sıra Issue #617'deki program sırasıdır:

1. **Phase 0 — Contract and baseline:** #616 evidence baseline; bu kanonik
   sözleşme; Roadmap/V2 Scope truth-sync.
2. **Phase 1 — Adaptive and accessible foundation:** adaptive compact bar /
   expanded rail shell; owner-reviewed final compact destination set; ortak
   aktif-proje bileşeni; edge-to-edge, predictive Back ve resize/orientation
   state retention; `48×48`, Semantics, scaling, focus ve Tooltip ortakları.
3. **Phase 2 — Shared interaction system:** primary action/form; search/filter;
   empty/loading/error/success; kullanıcı diliyle history/event sistemi.
4. **Phase 3 — Daily core:** canlı Dashboard; Hatırlatıcı + Unutma Kutusu;
   Ajanda ve Ajanda→Hatırlatıcı prefill; Living Plan; Daily Log ve Work Chain
   hedefli kanıtı.
5. **Phase 4 — People and field safety:** Sicil/Saha Rehberi; Puantaj; İSG model
   audit ve tracking yüzeyi; KKD hızlı seçim. Otomatik personel kodu tutulursa
   ayrı yetkili CRITICAL dilimdir.
6. **Phase 5 — Supporting modules:** Beton completion/detail/edit; Materials
   ortak pattern uyumu; Album/files/backup/Settings yerleşimi; Inventory için
   yalnız küçük tutarlılık ve erişilebilirlik uyumu, redesign yok.
7. **Phase 6 — Independent release gates:** minimum ortak arama; kısa onboarding;
   minimum crash/ANR/fatal telemetry; privacy/KVKK/store beyanları;
   recovery/backup owner kabulü.
8. **Phase 7 — Integrated quality:** compact/medium/expanded matrisi;
   phone/tablet, portrait/landscape/split-screen; TalkBack, yüksek text scale,
   focus ve grayscale; eksik #616 kanıtı ve gerekli manuel kabul borcu;
   bütünleşik günlük saha şefi senaryosu.
9. **Phase 8 — Release candidate:** birleşik automated milestone kapıları,
   analyze/build/artifact provenance; owner phone/tablet release-candidate
   kabulü; açık owner genel yayın kararı.

Her production adımı tek dar Issue/PR olarak yürür; aynı anda yalnız bir
production implementation Issue'su aktiftir ve stacked PR açılmaz. Phase 0'ın
tamamlanması Phase 1 production değişikliğine kendiliğinden yetki vermez.

## 15. İlk sonraki karar ve korunacak kapılar

Bu sözleşme merge edildikten sonraki ilk product/implementation kararı, Phase 1
Adaptive CSE Shell için final compact destination üyeliğinin owner review'uyla
seçilmesidir. Ardından adaptive shell ve accessibility foundation ayrı dar
Issue'larla yürür.

DWG Viewer / Issue #523 `POST-RELEASE / DEFERRED` kalır ve ilk genel yayının
bağımlılığı değildir. Issue #479'daki manuel kabul borcu; #501, #502 ve #503
recovery/backup/update kapıları; #499 MAIN-only owner-phone sınırı; privacy,
telemetry ve release-candidate kabulü korunur. Ready, merge, Issue closure ve
public/store release yalnız ayrı owner kararıyla yapılır.
