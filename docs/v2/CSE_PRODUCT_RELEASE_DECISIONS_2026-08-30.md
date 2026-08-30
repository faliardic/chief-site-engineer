# CSE / Şefim — Ürün ve Genel Yayın Kararları

**Tarih:** 30 Ağustos 2026  
**Durum:** Kilitli ürün karar kaydı  
**Kapsam:** Önceki CSE ürün toplantıları + `CSE / Şefim — Bağımsız Ürün, Pazar ve Yayın Yeterliliği Araştırması` üzerine yapılan karar toplantısı  
**Raporun referans snapshot'ı:** `master @ baa7beff186e3fee95f1fb439d92045d7ba1af4e`

> Bu dosya yalnızca ürün sahibi tarafından toplantıda açıkça onaylanan kararları kaydeder. Yeni ürün önerisi eklemez. Bağımsız araştırma raporunun önerileri, ürün sahibinin toplantıda verdiği kararlarla çelişiyorsa aşağıdaki kilitli kararlar geçerlidir.

## 1. Yayın stratejisi

- İlk dış ürün aşaması **Limited Beta olmayacak; doğrudan genel yayın** hedeflenecek.
- Uygulama, ürün sahibi ürünün güvenilirliğinden ve yayın yeterliliğinden emin olmadan yayımlanmayacak.
- Kapalı/davetli testler gerekirse yalnız kalite doğrulama yöntemi olarak kullanılabilir; ayrı bir ürün yayın aşaması sayılmaz.
- Bağımsız raporun `LIMITED BETA` önerisi bu toplantıda kabul edilmedi.

## 2. Ana Proje Dashboard'u ve hızlı kayıt

- **Ana Proje Dashboard'u genel yayın öncesi zorunlu kabul kapısıdır.**
- Dashboard; aktif proje, kritik/geciken işler, bugünkü plan ve ilgili proje özetlerini gösteren canlı kontrol merkezi olacak.
- Gelişmiş universal hızlı kayıt / gelişmiş Unutma Kutusu sistemi genel yayın için zorunlu değildir.
- Gelişmiş hızlı kayıt sistemi genel yayından sonraki ilk yüksek öncelikli geliştirmelerden biri olacak.
- Mevcut kayıt ve Unutma Kutusu akışları çalışır durumda korunacak.

## 3. İlk genel yayındaki DWG kapsamı

İlk genel yayın için DWG kapsamı **Minimal Güvenilir Viewer + ölçüme hazır mimari** olarak kilitlenmiştir.

İlk sürümde kullanıcıya sunulacak zorunlu kapsam:

- DWG açma,
- pan,
- pinch zoom,
- fit-to-screen,
- güvenli cache reopen,
- kaynak dosya ve revizyon görünürlüğü,
- eksik font/XREF uyarıları,
- bozuk veya unsupported dosyada güvenli hata.

Mimari ilkeler:

- Original DWG immutable source-of-truth olacak.
- Derived viewer/cache katmanı yeniden üretilebilir olacak.
- Mimari daha sonra güvenilir iki nokta ölçümü, kalibrasyon ve trust-state eklenmesini engellemeyecek.
- **Ölçüm ikinci faz özelliğidir ve ilk genel yayın kapısı değildir.**

## 4. Restore modeli

Restore modeli **kontrollü tam geri yükleme + geri alma** olarak kilitlenmiştir.

- Restore, seçilen backup'ın exact state'ine tam dönüş yapacak.
- Restore başlamadan önce mevcut canlı durumun otomatik safety backup'ı alınacak.
- Safety backup doğrulanmadan restore başlamayacak.
- Kullanıcıya backup tarihi, etkilenecek kayıtlar ve full replacement davranışı açıkça gösterilecek.
- Restore sonrasında geri alma seçeneği bulunacak.
- Safety backup korunacak.
- Merge-restore ilk genel yayın kapsamına alınmayacak.

## 5. Envanter genel yayın kapısıdır

Envanter Kayıt tamamen kapanmadan CSE genel yayına çıkmayacaktır.

Genel yayın öncesinde en az aşağıdaki kapanışlar tamamlanmış olmalıdır:

- Issue `#537` correction,
- focused regression PASS,
- integrated regression PASS,
- gerçek cihaz acceptance,
- backup/restore round-trip,
- migration,
- spatial history bütünlüğü,
- attachment bütünlüğü,
- Slice 7 field closure.

Envanteri feature flag ile gizleyerek yayımlama veya bilinen persistence riskiyle beta etiketi altında görünür bırakma seçenekleri kabul edilmemiştir.

## 6. Tüm manuel testler tamamlanacak

- Genel yayında kullanıcıya görünür olan tüm temel özelliklerin **tüm manuel testleri genel yayın öncesi tamamlanacak**.
- `MANUAL TEST PENDING` veya `MANUAL TEST DEFERRED` durumu genel yayın kabulünde bırakılmayacak.
- Aşağıdaki durumlar ayrı kabul edilmeye devam edecek:

`Implemented ≠ Automated PASS ≠ Manual PASS ≠ Release Accepted`

## 7. Arama kapsamı

- Tam kapsamlı cross-module global search ilk genel yayın için zorunlu değildir.
- **Minimum proje içi ortak arama genel yayın öncesi zorunlu kabul kapısıdır.**
- Temel kayıtlar proje bağlamında ortak aranabilir olacak.
- Gelişmiş çapraz-modül filtreleme, DWG/attachment düzeyinde derin arama ve tam global search yayın sonrasına bırakılacak.

## 8. Onboarding

- Genel yayın öncesinde kısa guided onboarding zorunlu olacak.
- Hazır örnek/sentetik proje zorunlu olmayacak.
- İlk açılışta en az ürünün temel amacı, ilk proje oluşturma, Dashboard ve temel kayıt akışı kısa biçimde yönlendirilecek.
- Örnek proje yayın sonrasına veya opsiyonel içeriğe bırakılacak.

## 9. Teknik telemetry

- Genel yayın öncesinde minimum teknik telemetry zorunlu olacak.
- En az crash, ANR, fatal error ve kritik DWG conversion/runtime failure gibi teknik sorunlar izlenecek.
- Ayrıntılı ürün kullanım analitiği, modül kullanım sıklığı, D7/D30 retention, capture süreleri ve benzeri davranış analitiği ilk genel yayın için zorunlu değildir; yayın sonrasına bırakılacak.
- Local-first ve veri minimizasyonu ilkeleri korunacak.

## 10. Gizlilik / KVKK yayın paketi

Genel yayın öncesinde tam gizlilik/KVKK yayın paketi zorunludur. Kapsam:

- gizlilik politikası,
- KVKK aydınlatma metni,
- uygulama içinden erişilebilir gizlilik alanı,
- Play Store User Data beyanları,
- actual binary ile permission davranışı uyumu,
- teknik telemetry açıklaması,
- varsa üçüncü taraf SDK veri davranışlarının belgelenmesi.

## 11. Gelir modeli

- İlk genel yayın **freemium** modelle çıkacak.
- Ücretsiz temel sürüm bulunacak.
- Gelişmiş özelliklerin bir bölümü ücretli katmanda yer alacak.
- Ücretli/ücretsiz özellik sınırlarının tamamı ve fiyat seviyesi ayrı ürün toplantısında netleştirilecek.
- Mimari ileride paket ve abonelik modelinin değişmesine izin verecek şekilde esnek tutulacak.

## 12. Güçlü ücretsiz çekirdek

Ücretsiz sürüm CSE'nin gerçek günlük değerini deneyimlemeye izin verecek güçlü bir çekirdek sunacaktır.

- Temel proje,
- Ajanda,
- Hatırlatıcı,
- Dashboard,
- Living Plan,
- temel saha işlevleri

tamamen ücretli duvar arkasına kapatılmayacak.

Ücretli katman daha çok aşağıdaki profesyonel değer alanlarından oluşabilir:

- gelişmiş DWG araçları,
- ölçüm,
- ileri export/raporlama,
- daha yüksek kapasite,
- ileri analiz/akıllı özellikler.

Bu maddelerin nihai paket sınırları ayrıca kararlaştırılacaktır.

## 13. DWG için 30 günlük deneme

- DWG için klasik kalıcı ücretsiz limit yerine **30 günlük deneme modeli** kullanılacak.
- Deneme süresi uygulama kurulduğunda otomatik başlamayacak.
- İlk dosya açılışında da sessizce başlamayacak.
- Kullanıcı açık bir **“30 günlük DWG denemesini başlat”** onayı verecek.
- Süre yalnız kullanıcı bu onayı verdikten sonra başlayacak.

## 14. DWG denemesi bittikten sonra veri davranışı

- Deneme sırasında eklenen original DWG dosyaları silinmeyecek.
- Proje/revizyon metadata'sı ve dosya bağlantıları korunacak.
- Deneme veya üyelik bitişi hiçbir kullanıcı dosyasını silmeyecek.
- DWG Viewer açma işlevi ücretli katmana geçiş yapılana kadar kilitlenecek.

## 15. Ücretsiz aktif proje limiti

- Ücretsiz sürümde **1 aktif proje** sınırı olacak.
- Kullanıcı tek aktif projede CSE'nin gerçek günlük değerini tam olarak deneyebilecek.
- Birden fazla eşzamanlı aktif proje ücretli katmanın değer alanlarından biri olacak.

## 16. Arşivlenmiş projeler

- Arşivlenmiş projeler ücretsiz sürümdeki `1 aktif proje` limitine dahil olmayacak.
- Ücretsiz kullanıcı aynı anda yalnız 1 aktif proje kullanabilecek.
- Biten projeler arşivlenerek geçmiş proje hafızası korunabilecek.
- Yeni aktif proje açmak için mevcut aktif proje arşivlenebilecek.
- Arşivlenmiş projeler silinmeyecek; geçmiş proje hafızası korunacak.

## Açık / bu toplantıda karar verilmedi

- **Arşivlenmiş bir projenin yeniden aktifleştirilmesine ilişkin freemium kuralı karara bağlanmadı.** Bu konu toplantıda yeni öneri olarak gündeme geldi ve iptal edildi; bu dosya herhangi bir kural varsaymaz.
- Freemium ücretli/ücretsiz özellik sınırlarının tüm ayrıntıları ve fiyat seviyesi ayrı toplantıda kararlaştırılacaktır.

## Genel yayın için birleşik ilke

CSE'nin ilk dış yayını genel yayın olacaktır; ancak genel yayın tarihi tek bir özelliğin, özellikle DWG Viewer'ın tamamlanmasına otomatik olarak bağlanmayacaktır. Genel yayın yalnız kilitli yayın kabul kapıları, veri güveni, Envanter kapanışı, tüm manuel kabul testleri, gerekli gerçek cihaz doğrulamaları, Ana Proje Dashboard'u, minimum proje içi ortak arama, onboarding, teknik telemetry ve gizlilik/KVKK gereklilikleri yeterli güven düzeyinde tamamlandıktan sonra yapılacaktır.
