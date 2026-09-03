# CSE UI/UX Release Readiness — Wave 0 Kaynak Denetimi

**Issue:** #540

**Parent Epic:** #539

**Denetim tabanı:** `a6413025f07cbd48838e2b78a7d2135afa16df69`

**Denetim türü:** salt-okunur Flutter source audit + dokümantasyon truth-sync

**Tarih:** 30 Ağustos 2026

## 1. Executive summary

### Gözlenen mevcut kaynak davranışı

CSE'nin Flutter yüzeyi işlevsel modüller açısından geniştir; Ajanda,
Hatırlatıcı, 7 Günlük Plan, Puantaj, Beton, Malzeme, Günlük Log, İş Zinciri,
Saha Rehberi, medya, yedekleme ve Envanter için gerçek ekranlar vardır. Kritik
mutation akışlarının önemli kısmı stable kimlik, proje bağı ve açık kullanıcı
eylemi taşır. Buna karşılık uygulama kabuğu bu yetenekleri tek bir saha çalışma
bağlamında birleştirmez:

- `Başlangıç`, aktif projenin bugünkü durumunu gösteren bir kontrol merkezi
  değil, farklı önem ve sıklıktaki kartlardan oluşan bir menüdür.
- Ortak bir aktif-proje state'i yoktur. Çoğu proje bağlı ekran kendi listesini
  okur, kendi seçimini tutar ve çoğunlukla ilk aktif projeye düşer.
- Alt navigasyon altı destinasyon taşır; acceptance'ı tamamlanmamış ve şu anki
  geliştirme hattı ertelenmiş Envanter hâlâ birincil destinasyondur. Beton ve
  Sicil ise `Daha` altında kalır.
- `Unutma` oluşturmak için Hatırlatıcı ekranına gidip ikinci bir eylem gerekir;
  Unutma Kutusu'nun kalıcı yolu daha da derindedir.
- Loading/empty/error/retry kalıpları ekranlar arasında aynı değildir. Bazı
  ekranlar açık retry ve tanı kodu verirken bazıları yalnız metin gösterir.

### Kilitli owner/ürün yönü

Home, aktif proje Dashboard/control center'a dönüşecektir. Proje bağlamı yalnız
gereken ekranlarda sürekli görünür olacak; sık işler kısa ve anlaşılır yollara
alınacak; `Unutma` doğrudan görsel erişim kazanacaktır. Inventory mevcut
çalışması silinmeden ve tamamlandı/reddedildi denmeden ertelenmiştir. Minimal
güvenilir DWG Viewer daha sonraki yüksek öncelikli release işidir. Bu yön,
`docs/v2/CSE_PRODUCT_RELEASE_DECISIONS_2026-08-30.md` içindeki genel yayın
kapılarını değiştirmez: Dashboard, minimum proje araması, onboarding, teknik
telemetry, gizlilik/KVKK, Inventory kapanışı ve gerekli manuel/cihaz kabulü
release öncesinde ayrıca kapanmalıdır.

### Review sonucu

İki P0 release-readiness açığı vardır: Home'un aktif proje kontrol merkezi
olmaması ve proje seçiminin route'lar arasında taşınmaması. Bunlar tek büyük UI
rewrite ile değil, önce dar bir Dashboard v1, sonra shared project-context ve
navigasyon dilimleriyle çözülmelidir. Wave 1 için source-of-truth değiştirmeyen,
mevcut read-model'leri kullanan implementation-ready sınır bölüm 10'dadır.

## 2. Current app-shell/navigation map

```text
BootstrapGate
└─ MobileShell — ortak AppBar + IndexedStack + NavigationBar
   ├─ Başlangıç (_HomePage)
   │  ├─ Görüşme sonucu → PhoneCallResultPage
   │  ├─ 7 Günlük İş Programı → LivingPlanPage
   │  ├─ Günlük Log → DailyLogPage
   │  ├─ İstenecek Malzemeler → MaterialRequestsPage
   │  ├─ Saha ipucu carousel'i
   │  ├─ Hafıza ve Yedekleme → MemoryBackupPage
   │  ├─ Proje Albümü → ProjectMediaAlbumPage
   │  ├─ Dosya Kataloğu → AttachmentCatalogPage
   │  └─ Ek Dosya Sağlığı → AttachmentHealthPage
   ├─ Hatırlatıcı → RemindersPage
   │  ├─ + Unutma → ReminderFormPage
   │  ├─ Bugün / Yarın
   │  └─ Diğer sheet → Yaklaşanlar / Unutma Kutusu / Tekrar kontrol / Geçmiş / Çöp
   ├─ Ajanda → AgendaPage
   │  ├─ Log ekle → LogFormPage
   │  ├─ Kayıt detayı → LogDetailPage
   │  ├─ Yeni proje
   │  └─ Mahal Kataloğu → ProjectLocationCatalogPage
   ├─ Envanter → InventoryPage
   │  ├─ Kroki / Katlar / Liste
   │  ├─ Kroki editörü
   │  └─ Varlık hızlı kayıt / detay
   ├─ Puantaj → AttendancePage
   │  ├─ Günlük Puantaj → AttendanceDayPage
   │  ├─ İş gücü / taşeron / ekip yönetimi
   │  └─ Puantaj hatırlatıcısı
   └─ Daha (_MorePage)
      ├─ Beton Paketi → ConcretePage
      └─ Sicil → WorkforceDirectoryPage
         ├─ Personel detayı / İSG / KKD
         └─ Sicili yönet → WorkforcePage / WorkforceRegistryPage
```

Source anchors: `mobile/lib/app.dart::_MobileShellState`,
`_MobileShellState._destinations`, `MobileShell.build`, `_HomePageState.build`
ve `_MorePage.build`.

Navigasyonun güçlü yanı, ana modüllerin çoğunda stable detail route'ların ve
geri dönüşte parent reload davranışının bulunmasıdır. Temel zayıflık, seçili
alt destinasyonun dışında ortak operasyon bağlamı tutulmamasıdır. Notification
tap'i doğru Hatırlatıcı destinasyonunu seçip detail route açar; bu hedefli
cross-route davranış, gelecekte ortak proje context'i için yararlı bir shell
örneğidir.

## 3. Screen inventory

`Bağlam` sütunu mevcut davranıştır; öneri değildir.

| Ekran / yüzey | Giriş / parent | Bağlam | Ana iş ve eylemler | Çıkış / önemli davranış |
| --- | --- | --- | --- | --- |
| Bootstrap / güvenli tanı | App launch | Projeden bağımsız | DB/bootstrap açılışı; safe message ve diagnostic code | Başarılıysa shell; failure yüzeyinde açık retry yok |
| Başlangıç | Alt nav `Başlangıç` | Proje bağlamı yok | On farklı kartla modül/yardımcı yüzey açma | Kart route'larından geri dönünce menüye döner |
| Hatırlatıcı listesi | Alt nav `Hatırlatıcı` | Karışık: kişisel ve proje kayıtları aynı view group'ta | Bugün/Yarın/Diğer, snooze, restore, detail | Route-local group korunur; page-level proje filtresi yok |
| Unutma formu | Hatırlatıcı `+ Unutma` veya Ajanda detail | Standalone'da opsiyonel; source log'da sabit proje | Başlık, tür, zaman, opsiyonel proje/mahal/kişi/detay, save | Standalone constructor preferred project kabul etmiyor |
| Hatırlatıcı detayı | Reminder card / notification | Proje satırı görünür; kişisel kayıt açıkça belirtilir | Lifecycle, snooze, edit, delete, inbox, source navigation, delivery tanısı | Çok sayıda eşdeğer görünen action aynı Wrap'ta |
| Ajanda | Alt nav `Ajanda` | `Tüm projeler` varsayılanı; her kartta proje/mahal | Gün/arama/sort/kategori/archive filtreleri, kayıt/proje/mahal oluşturma | Filtreler route-local; error kartında açık retry yok |
| Ajanda formu | Ajanda `Log ekle`, detail edit, contextual routes | Proje zorunlu ve görünür | Log, zaman, kategori, mahal, fotoğraf, not | `initialProjectId`/`initialIstanbulDay` taşıyabilir |
| Ajanda detayı | Ajanda/Günlük Log/source navigation | Proje ve mahal açık | Edit/archive, attachment, reminder, sync, history, İş Zinciri | Parent'a geri dönüp reload |
| Mahal Kataloğu | Ajanda veya formların mahal eylemi | Seçili proje üstte görünür | Create/rename/reparent/archive/restore mahal | Error state retry sunar; proje seçimi yine local |
| 7 Günlük Plan | Başlangıç kartı | Local selector; ilk aktif proje | 7-day/overdue plan, item lifecycle/progress/impact/note | Projesiz durumda yalnız talimat; create-project route yok |
| Günlük Log | Başlangıç kartı | Local selector; ilk aktif proje | Seçili proje/gün için read-only Ajanda/Puantaj/Plan/Beton/takip özeti | İyi typed error + `Tekrar oku`; source detail route'ları |
| İş Zinciri | Günlük Log veya source detail | Exact linked projenin context'i | Ajanda kökü, takip lifecycle ve sonuç projection'ı | Read-only; typed error + retry; teknik ID/revision yoğunluğu var |
| Envanter | Alt nav `Envanter` | Çok projede explicit seçim zorunlu; fail-closed | Kroki/Katlar/Liste, arama/filtre, varlık create/detail, kroki edit | Project change cache/focus temizler; geliştirme hattı şu an deferred |
| Puantaj | Alt nav `Puantaj` | Local selector; ilk aktif proje | Gün seçimi, kişi/ekip özeti, workforce ve reminder settings | Ekranı açmak `ensureDay` yoluyla gün oluşturabilir; Dashboard reuse edilmemeli |
| Günlük Puantaj | Puantaj gün kartı | Header/detail içindeki exact gün/proje | Roster, sonuç/saat/not, complete/reopen, CSV/share/history | Uzun mutation yüzeyi; null/error durumunda açık retry yok |
| Saha Rehberi | `Daha → Sicil` | Local selector + `Görünen proje` etiketi | Search, aktif/arşiv, taşeron/ekip filtresi, personel detail | Projesiz kullanıcı Ajanda'ya metinle yönlendirilir |
| Sicil yönetimi | Saha Rehberi veya Puantaj workforce | Route'a verilen exact proje | Personel, taşeron, ekip create/edit/archive | `Sicil`, `Saha Rehberi`, `İş gücü` adları parçalı |
| Personel detayı | Saha Rehberi card | Kişi üzerinden implicit proje | Kimlik özeti, İSG belgeleri, KKD zimmetleri | Tabbed; error/null durumda retry yok |
| Beton listesi | `Daha → Beton Paketi` ve source route'ları | Local selector; ilk/initial proje | Gün/grup/search filtreleri, yeni döküm, detail | Pull refresh var; visible error retry butonu yok |
| Beton form/detay | Beton list/detail routes | Proje zorunlu ve görünür | Döküm paketi, sınıf, mahal, checklist, truck/evidence/follow-up | Domain-rich ve uzun; back parent reload eder |
| İstenecek Malzemeler | Başlangıç kartı | Local selector; ilk aktif proje | Açık/geçmiş, hızlı create, lifecycle ve detail/history | Projesiz ve typed failure state var; no-project action yok |
| Görüşme sonucu | Başlangıç kartı | Local selector; ilk aktif proje | Kişi/firma önerisi, mahal, sonuç/not → canonical Ajanda | Project read failure save'i kapatır; ortak active context yok |
| Proje Albümü | Başlangıç kartı | Local selector; ilk aktif proje | Media/source/context/date filtre, preview/open, source route | AppBar/pull refresh; fixed preview constraint küçük ekran riski |
| Dosya Kataloğu | Başlangıç kartı veya attachment picker | Local selector; ilk aktif proje | Fiziksel attachment metadata listesi; picker modunda seçim | Browse mode'da dosya/source açma eylemi yok; Home metni beklentiyi aşabilir |
| Ek Dosya Sağlığı | Başlangıç kartı | Global diagnostic; proje filtresi yok | Broken/orphan/integrity finding listesi | Teknik ID/path görünür; ordinary Home için admin ağırlıklı |
| Hafıza ve Yedekleme | Başlangıç kartı | Projeden bağımsız, tüm mobil hafıza | Backup, safety backup, preflight, destructive full restore | Açık acknowledgement/final confirm ve non-dismissible progress güçlü örnek |
| Puantaj reminder ayarı | Puantaj | Seçili proje/gün akışından contextual | Reminder schedule ayarı | Genel settings merkezi yok; ayarlar feature içine dağılmış |

## 4. Project-context matrix

| Yüzey | Mevcut sınıf | Selector değerlendirmesi | Risk / öneri |
| --- | --- | --- | --- |
| Başlangıç | absent / ambiguous | Aktif proje selector'ı eksik | Wave 1'de tek belirgin aktif-proje header'ı; no-project açık onboarding |
| Ajanda | present but weak | `Tüm projeler` timeline için uygun; create için active context taşınmalı | Global active project ayrı, `Tüm projeler` bilinçli secondary filter olmalı |
| Hatırlatıcı | present but weak | Page-level selector yok; personal/project mix ürün için anlamlı olabilir | Active-project quick view ile kişisel/genel inbox birbirinden anlaşılır ayrılmalı |
| Unutma formu | optional / ambiguous | Standalone'da opsiyonel doğru; Dashboard'dan açıldığında proje preselect edilemiyor | Constructor'a future Issue ile preferred project ekle; kullanıcı değiştirebilsin |
| 7 Günlük Plan | clearly visible, route-local | Project-bound olduğu için selector uygun | Shell active project'i başlangıç değeri yap; local override shell'i bilinçli güncellesin |
| Günlük Log | clearly visible, route-local | Project-bound olduğu için selector uygun | Mevcut read-only projection Dashboard özet kaynağı olabilir |
| Puantaj | clearly visible, route-local | Project-bound olduğu için selector uygun | İlk-proje fallback yerine shell context; Dashboard read için `ensureDay` kullanma |
| Beton | clearly visible, route-local | Project-bound olduğu için selector uygun | Shell context'i `initialProjectId` ile taşı; seçim değişince ortak context kuralı açık olsun |
| Malzemeler | clearly visible, route-local | Project-bound olduğu için selector uygun | Shell context'i başlangıç yap; açık count Dashboard'da gösterilebilir |
| Saha Rehberi | clearly visible, route-local | Project-bound olduğu için selector uygun | Shell context; no-project dead end yerine project setup action |
| Görüşme sonucu | clearly visible, route-local | Project-bound capture için selector gerekli | İlk proje yerine shell context; project change form state'ini zaten fail-closed temizliyor |
| Proje Albümü | clearly visible, route-local | Project-bound olduğu için selector uygun | Shell context; Album/Catalog/Health bilgi mimarisi ayrıştırılmalı |
| Envanter | clearly visible, explicit | Birden çok projede explicit seçim güvenli ve doğru | Bu fail-closed davranışı korunur; current shell priority'si deferred olarak ele alınır |
| İş Zinciri / detail ekranları | implicit but trustworthy | Selector gereksiz; source exact project'i belirler | Header/breadcrumb ile proje adı sürekli görünür, selector eklenmez |
| Backup / health / bootstrap | project-independent | Selector gereksiz | Tools/Settings alanında konumlandır; proje selector'ıyla kirletme |

### Önerilen tek project-context pattern

1. `MobileShell` içinde tek session-level `ActiveProjectContext` bulunur. İlk
   sürümde yeni persistence/schema olmadan process içi state olabilir.
2. Dashboard header'ı aktif proje adını ve `Değiştir` eylemini sürekli gösterir.
3. Project-bound top-level ekranlar shell context'i başlangıç seçimi olarak
   alır. Kullanıcının o ekran içindeki proje değişimi ortak context'i de açıkça
   günceller; sessiz ilk-proje fallback kaldırılır.
4. Source-bound detail ekranları selector göstermez; exact proje adını
   breadcrumb/header olarak gösterir.
5. Ajanda ve Hatırlatıcı gibi cross-project/personal görünümler `Tüm projeler`
   veya `Kişisel` seçimini bilinçli secondary view olarak korur; bu seçim global
   active project'i silmez.
6. Backup, recovery, attachment health ve genel ayarlar project-independent
   kalır.

Bu pattern bir recommendation'dır; current functionality değildir.

## 5. High-frequency click-depth findings

Tıklama sayıları, uygulama açık ve alt navigasyon görünürken hedef eyleme kadar
minimum açık kullanıcı action sayısıdır. Frekans sınıfı ürünün günlük saha
amacından gelir; analytics iddiası değildir.

| Akış | Mevcut minimum yol | Depth | Değerlendirme |
| --- | --- | ---: | --- |
| Aktif proje değiştirme | Global yol yok; her modülü aç → local selector | Tek sayı verilemez | En yüksek sürtünme: aynı seçim tekrarlanır ve route'lar arası bağlam kaybolur |
| Bugünün 7 günlük planını açma | Başlangıç → `7 Günlük İş Programı` | 1 | Derinlik iyi; fakat açılan ilk proje active intent'i temsil etmeyebilir |
| Bugünkü hatırlatıcıları görme | Alt nav `Hatırlatıcı` | 1 | İyi |
| Yeni Unutma | Alt nav `Hatırlatıcı` → `+ Unutma` | 2 | Yüksek frekans için gereksiz dolaylı; Home direct action gerekli |
| Unutma Kutusu | `Hatırlatıcı` → `Diğer` → `Unutma Kutusu` | 3 | Kalıcı ana inbox için discoverability zayıf; Today count shortcut koşullu |
| Günlük saha kaydı oluşturma | Alt nav `Ajanda` → `Log ekle` | 2 | Kabul edilebilir ama Dashboard quick action ile 1 olabilir; Home Günlük Log kartı read-only'dir |
| Günlük kaydı okumak | Başlangıç → `Günlük Log` | 1 | Derinlik iyi; proje seçimi tekrar edebilir |
| Malzeme listesi | Başlangıç → `İstenecek Malzemeler` | 1 | Derinlik iyi; görünür önem/menu sırası zayıf |
| Personel bulma | `Daha` → `Sicil` | 2 | Günlük iletişim işi için dolaylı; arama iyi ama terminoloji parçalı |
| Sicil mutasyonu | `Daha` → `Sicil` → `Sicili yönet` | 3 | Orta frekans için kabul edilebilir; kullanıcı modelinin adları netleşmeli |
| Proje medya | Başlangıç → `Proje Albümü` | 1 | Derinlik iyi; Catalog/Health ile üç ayrı Home kartı bilgi mimarisini dağıtıyor |
| Aktif proje operasyonuna dönme | Back → Başlangıç menüsü; tekrar modül + selector | Değişken | Dashboard/session context olmadığı için kullanıcı zihinsel bağlamı yeniden kurar |

## 6. Component and visual consistency findings

### Başlık ve app bar

- Top-level destinations `MobileShell` AppBar'ını kullanır. Home'dan açılan
  modüller çoğunlukla kendi `Scaffold/AppBar`ını açar; `Daha` içindeki Beton ve
  Sicil wrapper AppBar altında ListView olarak render edilir. Teknik olarak
  tutarlı olsa da bilgi mimarisi top-level, Home-tool ve More-tool ayrımını
  kullanıcıya açıklamaz.
- `Sicil`, ekran içinde `Saha Rehberi`, mutation yüzeyinde `Sicili yönet` ve
  Puantaj altında `İş gücü / Taşeronlar ve ekipler` olarak adlandırılır.
- AppBar başlığı çoğu detail ekranda generic'tir; source-bound context proje
  adını body'nin ilerleyen kısmına bırakır.

### Hiyerarşi, spacing ve yoğunluk

- Uygulama genelinde `12–16` dp padding, Material 3 Card/ListTile,
  OutlineInputBorder ve Filled/Outlined button dili baskındır; iyi bir ortak
  temel vardır.
- Agenda, Saha Rehberi, Beton, Album ve Envanter çok sayıda filter'ı içeriğin
  önüne koyar. Envanter horizontal filter rail ile overflow'u yönetir; Agenda ve
  Saha Rehberi uzun dikey filter stack nedeniyle ilk kaydı aşağı iter.
- Reminder detail, Living Plan kartları ve AttendanceDay çok sayıda lifecycle
  action'ı eşit ağırlıklı `Wrap` içinde gösterir. Destructive veya nadir eylem
  primary daily action'dan yeterince ayrılmaz.
- Home sparse menü kartları ile domain-dense detail ekranları arasında ara bir
  summary/control-center katmanı yoktur.

### Eylemler, ikonlar ve touch target

- Kritik form submit ve Puantaj lifecycle button'larında 48 dp minimum yaygın;
  Material `IconButton` varsayılanları da çoğu icon-only kontrolü korur.
- Risk, küçük target'tan çok yan yana uzun `Row`/button label'larının dar
  ekranda sıkışmasıdır: Beton proje+tarih row'u, Album filename+open row'u,
  iki-column destructive/action row'ları ve sabit genişlikli preview/dialoglar.
- Destructive restore akışı acknowledgement + final confirmation ile güçlü ve
  örnek alınabilir. Buna karşılık normal lifecycle/archive eylemleri ekranlar
  arasında dialog, snackbar ve inline action olarak farklılaşır.

### Dialog, sheet ve snackbar

- Formlar çoğunlukla full page; küçük create/edit işleri `AlertDialog` veya
  modal sheet'tir. Sicil compliance/KKD dialogları çok alanlı olsa da scrollable.
- Reminder `Diğer` navigasyonu modal sheet içinde ikincil view listesi taşır;
  bu, gerçek bir bilgi mimarisi katmanını geçici action yüzeyine dönüştürür.
- Snackbar başarı/hata kullanımı vardır, fakat bazı ekranlar aynı hatayı body
  text, bazıları diagnostic card, bazıları snackbar ile bildirir.

### Uzun metin ve küçük ekran riski

- Çoğu dropdown `isExpanded` ve ellipsis kullanır; iyi örnektir.
- Personel, Beton ve media kartları 2–3 satırlı yoğun subtitle üretir.
- Album preview dialog'undaki yaklaşık `640 x 480` constraint ve file-name row'u
  küçük ekran/landscape inset altında ayrıca doğrulanmalıdır.
- Raw UUID, revision, SHA/path ve event type'lar advanced diagnostic bilgidir;
  ordinary first layer yerine expansion/copy-support alanına alınmalıdır.

## 7. Empty/loading/error/recovery audit

| Yüzey ailesi | Loading | Empty / no-project | Error / recovery | Değerlendirme |
| --- | --- | --- | --- | --- |
| Bootstrap | Bare centered spinner | N/A | Safe diagnostic message/code; retry yok | Güvenli fakat cold-start dead end olabilir |
| Ajanda / Reminders | Spinner | Anlaşılır empty card | Generic safe text; pull-to-refresh her zaman keşfedilir değil | Açık `Tekrar dene` standardı gerekli |
| Living Plan | Spinner | `Önce proje oluşturun`; action yok; snapshot unavailable ayrı | Safe message; üst refresh icon dolaylı | No-project dead end |
| Daily Log | Spinner | Section-level empty/unavailable | Typed code + `Tekrar oku` | En iyi genel read-only state örneklerinden biri |
| Work Chain | Spinner | Exact link yoksa typed result | Retry + diagnostic | Güçlü ancak teknik detay first layer'da yoğun |
| Materials | Spinner | No-project ve empty ayrı | Failure code/card; retry paterni sınırlı | Typed ancak user recovery eylemi eksik |
| Attendance / Workforce / Concrete | Spinner | Ajanda'dan proje oluşturma talimatı veya empty text | Inline text; çoğunlukla retry yok | Modüller arası metinsel detour dead end yaratır |
| Location Catalog | Spinner | No project/location ayrı | Açık retry | Reusable state pattern adayı |
| Album / Catalog / Health | Spinner veya progress | Project/filter/broken state ayrımları var | AppBar/pull refresh veya text; tutarsız | Browse Catalog eylemsizliği empty olmayan dead end üretir |
| Inventory | Explicit load status enum | Project required/selection required/no sketch/empty filter ayrı | Typed diagnostic/failure + retry | State modellemesi güçlü; current priority deferred |
| Backup/restore | Inline/progress overlay | Safety backup empty ayrı | Safe non-mutating failure; destructive confirmation | En güçlü destructive/recovery örneği |

Ortak öneri: `LoadingSurface`, `EmptyStateCard`, `NoProjectState`,
`RecoverableErrorCard` ve `DiagnosticDetails` bileşen aileleri oluşturulsun.
Her recoverable error birincil `Tekrar dene`, gerekiyorsa ikincil tanı-kodu
copy alanı sunsun. No-project state tek bir project setup/management route'una
gitsin; yalnız “Ajanda'dan oluşturun” metni bırakılmasın.

## 8. P0/P1/P2/P3 finding register

### P0

| ID | Bulgu | Frekans | Release impact | Risk | Wave / dependency | Exact evidence anchors |
| --- | --- | --- | --- | --- | --- | --- |
| UI-540-P0-01 | Home aktif proje Dashboard/control center değil; günün kritik/geciken işi, planı ve proje özeti yok | high | blocker | medium | Wave 1; release decisions §2 | `mobile/lib/app.dart::_HomePageState.build`; `MobileShell.build`; `docs/v2/CSE_PRODUCT_RELEASE_DECISIONS_2026-08-30.md::Ana Proje Dashboard'u ve hızlı kayıt` |
| UI-540-P0-02 | Proje seçimi shell/session düzeyinde taşınmıyor; project-bound modüller bağımsız olarak ilk projeye veya tüm projelere düşüyor ve yanlış bağlamda işlem başlatma riski yaratıyor | high | blocker | high | Wave 1 foundation + Wave 2 adoption; P0-01 predecessor | `mobile/lib/features/living_plan/living_plan_page.dart::_LivingPlanPageState._reload`; `mobile/lib/features/daily_log/daily_log_page.dart::_DailyLogPageState._loadProjects`; `mobile/lib/features/attendance/attendance_page.dart::_AttendancePageState._loadProjects`; `mobile/lib/features/concrete/concrete_page.dart::_ConcretePageState._loadProjects`; `mobile/lib/features/material_requests/material_requests_page.dart::_MaterialRequestsPageState._loadProjects`; `mobile/lib/features/attachments/project_media_album_page.dart::_ProjectMediaAlbumPageState`; `mobile/lib/features/agenda/phone_call_result_page.dart::_PhoneCallResultPageState._loadProjects`; contrasting fail-closed example `mobile/lib/features/inventory/inventory_page.dart::InventoryPageController` and `InventoryPageState._buildProjectSelector` |

### P1

| ID | Bulgu | Frekans | Release impact | Risk | Wave / dependency | Exact evidence anchors |
| --- | --- | --- | --- | --- | --- | --- |
| UI-540-P1-01 | Direct `Unutma` Home erişimi yok; standalone form preferred active project alamıyor; Unutma Kutusu `Diğer` sheet altında | high | important | medium | Wave 1 quick action + Wave 2 reminder IA; P0-02 | `mobile/lib/features/reminders/reminders_page.dart::_RemindersPageState.build`, `_RemindersPageState._showOtherViews`; `mobile/lib/features/reminders/reminder_form_page.dart::ReminderFormPage` constructor; `mobile/lib/app.dart::_HomePageState.build` |
| UI-540-P1-02 | Alt navigasyon altı destinasyonla kalabalık; deferred Inventory primary slot'ta, günlük Beton/Sicil `Daha` altında; navigation önceliği current release programını yansıtmıyor | high | important | medium | Wave 3 navigation; Dashboard ve context adoption sonrası | `mobile/lib/app.dart::_MobileShellState._destinations`, `_MorePage.build`; `mobile/lib/features/inventory/inventory_page.dart::InventoryPage`; Issue #540 truth direction |
| UI-540-P1-03 | Home aynı düzeyde daily operations, recovery/admin ve pedagogical kartlar sunuyor; açık “bugün” hiyerarşisi yok | high | important | medium | Wave 1 | `mobile/lib/app.dart::_HomePageState.build`, `_HomeMenuCard`, `_FieldTipCard` |
| UI-540-P1-04 | Project lifecycle application mevcut olmasına rağmen user-facing rename/archive/restore/search yüzeyi bulunmuyor; create yalnız Ajanda ve Log formunda | medium | important | high | Wave 4 project management/search; P0-02 | `mobile/lib/application/agenda_application.dart::ProjectLifecycleApplication`; UI girişleri yalnız `mobile/lib/features/agenda/agenda_page.dart::_AgendaPageState._createProject` ve `mobile/lib/features/agenda/log_form_page.dart::_LogFormPageState._createProject`; `renameProject`/`mutateProjectArchive` presentation caller yok |
| UI-540-P1-05 | No-project state'ler action yerine kullanıcıyı metinle Ajanda'ya yollar; Living Plan, Puantaj, Saha Rehberi, Materials ve Inventory'de setup yolu parçalı | medium | important | low | Wave 2/4; tek project setup route | `mobile/lib/features/living_plan/living_plan_page.dart::_LivingPlanPageState.build`; `mobile/lib/features/attendance/attendance_page.dart::_AttendancePageState.build`; `mobile/lib/features/attendance/workforce_directory_page.dart::_WorkforceDirectoryPageState.build`; `mobile/lib/features/material_requests/material_requests_page.dart::_MaterialRequestsPageState.build`; `mobile/lib/features/inventory/inventory_page.dart::InventoryPageState._buildBody` |
| UI-540-P1-06 | Recoverable error'larda ortak ve keşfedilir retry yok; safe technical message kullanıcıyı dead end'de bırakabiliyor | medium | important | low | Wave 5 shared states | `mobile/lib/app.dart::BootstrapGate`, `BootstrapFailureScreen`; `mobile/lib/features/agenda/agenda_page.dart::_AgendaPageState.build`; `mobile/lib/features/reminders/reminders_page.dart::_RemindersPageState.build`; `mobile/lib/features/attendance/attendance_page.dart::_AttendancePageState.build`; `mobile/lib/features/concrete/concrete_page.dart::_ConcretePageState.build`; iyi örnekler `mobile/lib/features/daily_log/daily_log_page.dart::_DailyLogError`, `mobile/lib/features/agenda/project_location_catalog_page.dart`, `mobile/lib/features/inventory/inventory_page.dart::InventoryPageState._failure` |

### P2

| ID | Bulgu | Frekans | Release impact | Risk | Wave / dependency |
| --- | --- | --- | --- | --- | --- |
| UI-540-P2-01 | Filter stack ve lifecycle action yoğunluğu ilk içeriği/primary action'ı gölgeliyor | medium | polish | medium | Wave 5; Agenda, Reminder detail, Living Plan, AttendanceDay, Saha Rehberi, Beton |
| UI-540-P2-02 | `Sicil / Saha Rehberi / İş gücü / Taşeronlar ve ekipler` adlandırması ve entry point'leri tek kullanıcı modelinde birleşmiyor | medium | polish | low | Wave 3/5 |
| UI-540-P2-03 | UUID, revision, raw event type, diagnostic/path/SHA gibi teknik bilgi ordinary first layer'da fazla görünür | low | polish | low | Wave 5 diagnostic disclosure |
| UI-540-P2-04 | Album/Catalog/Health üç ayrı Home kartıdır; Catalog browse mode dosya/source açmaz ve preview/long-row small-screen riski taşır | medium | polish | medium | Wave 3 information architecture + Wave 5 layout |
| UI-540-P2-05 | Top-level outer AppBar, Home route AppBar ve More wrapper kalıpları görünür hierarchy/breadcrumb üretmiyor | medium | polish | medium | Wave 3 shell/navigation |

### P3

| ID | Bulgu | Frekans | Release impact | Risk | Wave / dependency |
| --- | --- | --- | --- | --- | --- |
| UI-540-P3-01 | Home saha ipucu temel öğretim metniyle prime alan tüketiyor; contextual “neden yararlı” yardım modeline dönüşmeli | low | polish | low | Wave 1 content cleanup |
| UI-540-P3-02 | Bazı uzun labels/rows ve `Mahál` gibi copy tutarsızlıkları küçük ekran ve dil QA'sı ister | low | polish | low | Wave 5 content/layout QA |

## 9. Recommended implementation slices

Her dilim tek dominant kullanıcı sonucu taşır ve ayrı Issue/authority ister.

1. **Wave 1 — Project Dashboard v1:** Home'u aktif proje control center'a
   dönüştür; read-only today summary, direct `Unutma` ve `Ajanda kaydı`, açık
   7-day plan/material yolları, no-project/error state. Bölüm 10 exact handoff.
2. **Wave 2 — Project context continuity:** session-level active project'i
   Living Plan, Daily Log, Puantaj, Beton, Materials, Album, Saha Rehberi ve
   capture route'larına başlangıç context'i olarak geçir; source-bound detail
   selector eklemeden breadcrumb göster; cross-project views'i koru.
3. **Wave 3 — Navigation and information architecture:** alt navigation/More
   önceliğini current daily flow'a göre yeniden kur; deferred Inventory'yi
   silmeden uygun secondary konuma taşı; admin/recovery/media tools'u grupla;
   workforce terminolojisini birleştir.
4. **Wave 4 — Project management + minimum project search:** create/rename/
   archive/restore ve minimum proje aramasını tek yüzeyde sun; no-project CTA'ları
   buraya bağla. Genel yayın kararındaki minimum project search gate'ini karşıla.
5. **Wave 5 — Shared state/component consistency:** retry/no-project/empty/
   diagnostic components; action hierarchy; filter disclosure; small-screen,
   long-text ve accessibility QA.
6. **Wave 6 — Guided onboarding and release shell:** ilk proje, Dashboard ve
   temel kayıt akışını kısa guided onboarding ile açıkla; telemetry/privacy/KVKK
   yüzeylerini ilgili ayrı release Issues ile bağla.
7. **Later high-priority — Minimal güvenilir DWG Viewer:** UI shell/daily-flow
   pass sonrasında, original DWG immutable ve ölçüme hazır mimari sınırında.
8. **Release-readiness closure:** deferred Inventory acceptance'ın tamamlanması,
   bütün gerekli manual/device testler, technical telemetry, KVKK/privacy,
   entitlement/freemium ve release gates. Bu audit release/Ready ilanı değildir.

## 10. Wave 1 — Project Dashboard proposed boundary

### Exact user problem

Şantiye şefi uygulamayı açtığında hangi projede çalıştığını ve bugün dikkat
gerektiren işleri tek bakışta göremiyor. Bir işlem seçtikten sonra her modülde
projeyi yeniden seçiyor. Hızlı `Unutma` ve günlük kayıt için önce ürün
hiyerarşisini hatırlamak zorunda kalıyor.

### Proposed Dashboard v1 information hierarchy

1. **Active project header:** proje adı, `Değiştir`, görünür today date.
2. **Primary quick actions:** `+ Unutma`, `+ Ajanda kaydı`.
3. **Bugün:** mevcut günlük read-model'den Ajanda, Puantaj, Living Plan, Beton ve
   açık takip section count/availability özeti; card tap ilgili mevcut ekrana.
4. **7 Günlük Plan:** overdue + next-seven-day kısa count ve `Planı aç`.
5. **İstenecek Malzemeler:** açık kayıt sayısı ve `Malzemeleri aç`.
6. **Project tools:** Proje Albümü ve Saha Rehberi; ikincil görsel ağırlık.
7. **All tools / safety:** Backup, Catalog, Attachment Health ve deferred
   Inventory ordinary today flow'dan ayrılmış secondary group.

Dashboard v1 yeni karar/özet uydurmaz. “Kritik” ifadesi ancak existing status,
due/overdue veya locked read-model semantiğiyle açıklanabiliyorsa kullanılır;
AI prioritization ya da contractual delay iddiası yapılmaz.

### Existing read-only source mapping

| Dashboard parçası | Mevcut source / port | Wave 1 kullanım sınırı |
| --- | --- | --- |
| Proje listesi/adı | `AgendaApplication.listProjects()` / `projectChanges` | Session active project; schema/persistence yok |
| Bugün birleşik özet | `DailyLogApplicationPort.loadDay(projectId, localDay)` | Read-only DB handle; section unavailable bilgisini aynen gösterir; `AttendanceApplication.ensureDay` çağırmaz |
| 7 günlük item'lar | `ConstructionLivingPlanApplicationPort.loadSevenDayPlan(projectId, windowStart)` | Mevcut plan/status/tarih; mutation yok |
| Açık malzemeler | `MaterialRequestApplicationPort.listMaterialRequests(projectId, open)` | Count + route; source row mutation yok |
| Hatırlatıcı/Unutma | Mevcut `ReminderFormPage` ve `AgendaApplication` | Direct route; active project preselection için dar route contract gerekir; save yine kullanıcı eylemidir |
| Ajanda hızlı kayıt | `LogFormPage(initialProjectId, initialIstanbulDay)` | Mevcut constructor reuse; no auto-save |
| Album/people | Mevcut `ProjectMediaAlbumPage`, `WorkforceDirectoryPage` | Active project initial context; yeni projection yok |

`DailyLogApplicationPort.loadDay` Dashboard summary için özellikle uygundur:
exact proje/gün okur, Ajanda/Puantaj/Living Plan/Beton/açık takip section'larını
ayrı availability ile döndürür ve SQLite'ı `readOnly: true` açar. Wave 1 bu
projection'ı UI'ya uygun küçük bir adapter/view-model ile kullanabilir; source
tablo, event veya revision değiştiremez.

### Project selector/context behavior

- Sıfır proje: Dashboard kayıt sayısı uydurmaz; ürün amacı + `İlk projeyi
  oluştur` primary CTA'sı gösterir.
- Tek proje: otomatik session selection yapılabilir; header yine proje adını
  gösterir.
- Birden çok proje: önceki session selection yoksa kullanıcı explicit seçim
  yapmadan project-bound card okumaları başlamaz. Inventory'nin fail-closed
  multi-project davranışı model alınır.
- Dashboard'dan açılan project-bound route selected ID/day alır. Route içindeki
  selector kullanıcıya açık kalır; değişirse shared context kuralı Wave 2'de
  bütün modüllere tamamlanır.
- Personal reminder veya global safety tools active project'e zorla bağlanmaz.

### Empty, no-project and error behavior

- Her card kendi loading skeleton/progress alanına ve bounded empty text'e sahip
  olur; bütün Dashboard tek bir yavaş section nedeniyle kapanmaz.
- Section read failure sağlıklı kartları silmez. `DailyLogSection.unavailable`
  semantiği korunur.
- Recoverable failure `Tekrar dene` verir; diagnostic code ikincil detail/copy
  alanındadır.
- No-project CTA tek project setup route'una gider. Project setup başarısızsa
  form verisi uydurulmaz ve Dashboard açıkça no-project kalır.
- Empty, “veri yüklenemedi” ve “özellik unavailable” aynı mesaj değildir.

### Explicitly deferred from Dashboard v1

- Persistent last-project preference veya yeni schema/settings storage.
- Bütün modüllerin global context adoption'ı; bu Wave 2'dir.
- AI summary, saha kararı, critical-path/float veya contractual delay hesabı.
- Global/full-text arama; minimum project search Wave 4'tür.
- Inventory acceptance/continuation veya Inventory data card'ı.
- DWG preview/viewer, onboarding, telemetry, KVKK/privacy, entitlement/paywall.
- Navigation bar'ın nihai yeniden tasarımı ve full visual design-system rewrite.
- Source/domain lifecycle, notification, backup, schema, migration veya version
  değişikliği.

### Likely source/component boundaries

- `mobile/lib/app.dart`: shell injection, Home replacement ve existing route
  wiring; mümkünse büyüyen Dashboard ayrı feature dosyalarına çıkarılır.
- Yeni presentation-only Dashboard page/view-model/components: active project
  header, quick actions, today section cards, state surfaces.
- Existing ports: `AgendaApplication`, `DailyLogApplicationPort`,
  `ConstructionLivingPlanApplicationPort`, `MaterialRequestApplicationPort`.
- `ReminderFormPage`: optional preferred project route input; source-log exact
  binding'i override edemez.
- `LogFormPage`: existing `initialProjectId` ve `initialIstanbulDay` reuse.
- Bootstrap dependency wiring: yalnız mevcut application instances; yeni DB
  service veya background job yok.

Exact writable production paths ve changed contracts ancak ayrı Wave 1 Issue
authority'sinde belirlenir; bu audit source değişikliği yetkisi değildir.

### Focused test families needed in Wave 1

1. Active project: zero/one/multiple projects, explicit selection ve project
   change invalidation.
2. Dashboard read isolation: exact project/day; no cross-project leakage; no
   `ensureDay`/mutation/event/revision write.
3. Partial section failure: bir unavailable source diğer kartları silmez;
   retry yalnız read'i tekrarlar.
4. Quick actions: Unutma preferred project, personal override, Ajanda exact
   project/day, cancel no mutation.
5. Navigation/back: Dashboard context korunur; detail source project'i yanlış
   rebind etmez; notification route regresyonu yok.
6. Small screen/text scale/dark-light: wrapping, scroll, 48 dp targets,
   semantics/focus order.
7. Existing domain regression families: Agenda/Reminder/Living Plan/Materials
   source contracts değişmeden kalır.

Application/widget/device testlerinin hangilerinin çalışacağı Wave 1 authority
ve risk-temelli validation protokolünde belirlenir. Bu Wave 0 görevinde hiçbiri
çalıştırılmamıştır.

### Risks and dependencies

- `app.dart` halihazırda çok sayıda application dependency taşır; Dashboard
  wiring dosyayı daha da büyütmemelidir.
- Reminder list portu group-scoped olup doğrudan project query almaz. Project
  reminder özetinde client-side belirsiz filtre yerine exact, bounded read-model
  tasarımı gerekebilir; Wave 1 ilk kartı Daily Log open-follow-up section'ıyla
  sınırlayabilir.
- Attendance top-level page read sırasında `ensureDay` kullanır; Dashboard onu
  embed veya call etmemelidir. Daily Log read projection kullanılmalıdır.
- Shared active project'in route-local override ile ilişkisi tanımlanmadan
  bütün ekranlara aynı anda uygulanırsa stale selection/cross-project risk doğar.
- Deferred Inventory visible navigation davranışı Wave 1'de silinmez; nihai
  konumu Wave 3 review'unda kararlaştırılır.

## 11. Deferred/later items

- **Inventory Map v1:** merged tarihsel çalışmalar korunur. Issue #535 / Draft
  PR #536 deferred ve bu auditin ancestry/source truth'u değildir. Device
  acceptance tamamlanmamıştır; current UI programını bloke etmez. Owner release
  kararına göre Inventory genel yayın öncesinde yine kapanması gereken bir
  gate'tir.
- **DWG Viewer:** UI shell ve daily-flow pass sonrasında later high-priority.
  Minimal Reliable Viewer + measurement-ready architecture; measurement,
  editing ve CAD authoring ilk dilimde yoktur.
- **Onboarding, telemetry, privacy/KVKK, freemium/entitlement:** release scope'u
  olarak zorunlu olabilir, fakat Wave 1 Dashboard source scope'una karıştırılmaz.
- **Global/advanced search:** genel release için minimum proje araması gerekir;
  cross-module/DWG/attachment derin arama daha sonradır.
- **Inventory dışı CAD/GIS/full map, AI summary, multi-user/cloud/portal:** bu
  denetimin önerisi değildir ve mevcut V2-dışı sınırlarını korur.

## 12. Release-readiness implications

Bu audit “uygulama release-ready” sonucu vermez. Aksine release'e giden görünür
UI sırasını daraltır:

```text
Inventory Map v1 — historical work preserved; deferred / device acceptance incomplete
→ UI/UX Release Readiness Wave 0 — current docs/source audit
→ Project Dashboard v1
→ project-context continuity
→ navigation + project management/search + shared state polish
→ onboarding / telemetry / privacy-KVKK release shell
→ Minimal Reliable DWG Viewer — later high-priority
→ Inventory acceptance closure + remaining manual/device gates
→ release-readiness closure and separate owner release decision
```

Schema `22`, backup format `1`, mobile version `0.1.0+1`, existing source-of-truth,
event/history, notification ve platform contracts bu audit tarafından
değiştirilmemiştir. Dashboard, Inventory, DWG, Ready, merge, release veya store
publication uygulanmış/başlatılmış sayılmaz.
