# Issue #200 — Mikser Dialog Lifecycle Güvenliği

## Problem ve doğrulanmış neden

Yeni veya mevcut mikser dialogu kapanırken `showDialog` sonucu parent sayfaya
dönüyor, fakat route'un reverse transition animasyonu henüz tamamlanmamış
olabiliyordu. Parent `_editTruck()` bu anda beş `TextEditingController` nesnesini
hemen dispose ediyordu. Dialog TextField'ları son animasyon frame'lerinde aynı
controller'ları render etmeye çalışınca `widget_render_error` oluşabiliyordu.

Sorun restore edilmiş veriye özel değildir. Yeni mikser ve mevcut mikser aynı
controller yolunu kullandığı için iki akış da etkileniyordu.

## Yeni sahiplik sözleşmesi

`_TruckDialog`, controller'ların tek sahibidir:

- controller'lar dialog State `initState()` içinde oluşturulur;
- TextField'lar yalnız aynı State içindeki controller'ları kullanır;
- controller'lar yalnız dialog State `dispose()` içinde kapatılır;
- parent sayfaya yalnız immutable `_TruckDraft?` döner;
- parent hiçbir dialog controller'ını görmez veya dispose etmez.

Bu sözleşme animasyon süresini tahmin eden `Future.delayed(...)` davranışına
bağlı değildir. Flutter route dialog State'i gerçekten kaldırana kadar
controller'lar geçerli kalır.

## Mutation sözleşmesi

Dialog `_closing` guard'ını submit callback'inin ilk satırında kontrol eder.
Geçerli draft oluşturulurken guard senkron olarak kapanır; aynı event-loop'taki
ikinci tap ikinci `Navigator.pop` üretemez. Parent tek result aldığı için
`saveTruck` sıfır veya tam bir kez çağrılır.

Save success sonrasında detail read-model yeniden yüklenir. Mikser kartında
plaka, hacim, not ve revision görünür; canlı hedef/dökülen/kalan/aşılan m³ aynı
application metrics'inden okunur.

Validation veya optimistic stale failure'da immutable draft şu kimliklerle
birlikte korunur:

- mevcut truck ID veya yeni truck ID;
- event ID;
- bütün form değerleri ve zaman alanları.

Sayfadaki `Son mikser girdisini yeniden aç` eylemi önce güncel detail'i kullanır,
sonra aynı logical mutation kimliğiyle draft'ı yeniden açar. Böylece girdi
kaybolmaz ve belirsiz failure sonrasında yeni bir logical kayıt kimliği üretilmez.

## Korunan domain davranışları

- Legacy/null irsaliye okunur ve düzenlenebilir.
- `received` dışı sonuçta reason zorunludur; alan açılıp kapandığında controller
  State içinde yaşamaya devam eder.
- Geliş, boşaltma başlangıç ve bitiş zamanları draft üzerinden korunur.
- Application service'in optimistic revision, transaction, no-op ve
  `truck.updated` before/after event kuralları değişmez.
- Fiziksel veri silme, schema veya migration eklenmez.

## Modal audit

Beton ve Ajanda kapsamındaki local modal controller patternleri tarandı.
Mikser dışında local controller kullanan field notification, numune adedi,
gerekçe, hedef hacim ve yeni proje akışları State-owned dialog standardına
taşındı. Basit text inputlar `OwnedTextInputDialog`; çok alanlı Beton formları
kendi dedicated StatefulWidget'larını kullanır.

Statik regression testi parent modal methodlarında controller oluşturma/dispose
patterninin geri gelmediğini ve controller dispose'un dialog State içinde
kaldığını doğrular.

## Diagnostic doğruluğu

Framework fatal hatası DB mutation ile yarışabilir. Bu durumda global panel
`Yeni kayıt yazılmadı` diyemez. Yeni metin:

- işlem sonucunun doğrulanamadığını;
- uygulamanın kapatılıp yeniden açılmasını;
- ilgili kaydın kontrol edilmesini;
- işlem doğrulanmadan tekrar edilmemesini

açıkça söyler. `ErrorWidget.builder` ve güvenli diagnostic sınırı kaldırılmaz.

## Test ve artifact kapsamı

- Yeni ve mevcut mikser save/cancel reverse animation widget testleri.
- Save callback single-call ve double-submit guard testi.
- Null irsaliye, reason toggle, mevcut geliş/boşaltma zamanları ve UI revision.
- Failure sonrası immutable draft reopen.
- Application no-op/stale ve `truck.updated` regresyonları.
- Android API 36'da backup restore sonrası null irsaliyeli mikserin gerçek UI
  edit akışı ve append-only tek event doğrulaması.
- Flutter/Python tam regresyon, static/release gate, debug sidecar, unsigned AAB
  ve ephemeral-signed production RC.

Mobil schema `7`, backup format `1`, gerçek kullanıcı verisi ve production
kurulum sınırları değişmez. Codex gerçek backup'ı okumaz, restore/uninstall veya
store submission yapmaz.
