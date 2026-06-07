# Adım 075 — Dosya Eki Arşiv Güvenliği ve Silme / Taşıma Kararları

## Kısa Amaç

Bu adım, `FileAttachmentRecord` ile temsil edilen dosya ekleri için ileride uygulanacak silme, taşıma, kayıp dosya, arşiv güvenliği ve denetim izi kararlarını dokümante eder.

Bu adım yalnızca karar dokümantasyonudur. Uygulama kodu, test dosyaları, yeni model, repository, dosya yükleme, dosya silme, dosya taşıma, dosya kopyalama, SQLite, JSON persistence, API, GUI veya CLI davranışı eklenmez.

## 1. Temel Arşiv Güvenliği Yaklaşımı

Şantiye dosya ekleri yalnızca teknik dosya değildir. Fotoğraf, video, PDF, belge veya ses notu; hukuki, teknik ve saha hafızası açısından değer taşıyabilir.

Bu nedenle dosya eki silme ve taşıma işlemleri sıradan dosya işlemi gibi düşünülmemelidir.

`FileAttachmentRecord` dosyanın kendisini değil, dosya referansını ve metadata bilgisini tutar. Bu yüzden fiziksel dosya ile kayıt metadata bilgisinin birlikte korunması gerekir.

## 2. Dosya Silme Kararı

Varsayılan yaklaşım kalıcı silme değil, kontrollü arşiv dışı bırakma veya soft-delete olmalıdır.

Fiziksel dosya hemen silinmemelidir.

İleride bir dosya eki pasife alınacaksa şu bilgilerin tutulması değerlendirilebilir:

- Silinme / pasife alınma durumu
- Silen veya pasife alan kişi
- Silme / pasife alma tarihi
- Silme gerekçesi
- İlgili ana kayıt

Bu adımda herhangi bir soft-delete alanı veya kod davranışı eklenmez.

## 3. Fiziksel Dosya Yoksa Ne Olur?

`FileAttachmentRecord` kaydı duruyor ama fiziksel dosya bulunamıyorsa bu durum `missing file reference` olarak değerlendirilmelidir.

Bu durum her zaman uygulamanın tamamen çalışamaz hale gelmesi anlamına gelmez. İleride sistem bunu hata yerine arşiv bütünlüğü uyarısı olarak raporlayabilir.

Eksik dosya referansları şu amaçlarla ayrıca listelenmelidir:

- Denetim kontrolü
- Yedek bütünlüğü kontrolü
- Arşiv temizliği
- Dosya taşıma sonrası kontrol
- Kayıp kanıt riski takibi

Bu adımda dosya varlık kontrolü veya fiziksel dosya tarama davranışı eklenmez.

## 4. Dosya Taşıma Kararı

Dosya taşınırsa `FileAttachmentRecord` içindeki `file_path` veya ileride kullanılabilecek `storage_reference` güncellenmelidir.

Dosya taşıma işlemi ileride loglanmalıdır.

Taşıma geçmişinde şu bilgiler değerlendirilebilir:

- Eski yol
- Yeni yol
- Taşıyan kişi
- Taşıma tarihi
- Taşıma gerekçesi
- İlgili ana kayıt

Bu adımda gerçek dosya taşıma davranışı eklenmez.

## 5. Dosya Değiştirme / Üzerine Yazma Kararı

Arşiv dosyaları mümkünse üzerine yazılmamalıdır.

Yeni versiyon gerekiyorsa yeni dosya eki olarak tutulmalıdır.

Orijinal dosya korunmalı, yeni dosya ayrı sequence veya version bilgisiyle bağlanmalıdır.

Örnek:

```text
20260607_143210__nonconformity__NCR-000012__image__001.jpg
20260607_151500__nonconformity__NCR-000012__image__002.jpg
```

Bu yaklaşım saha denetim izi açısından daha güvenlidir. Hangi dosyanın önce, hangisinin sonra eklendiği kaybolmaz.

## 6. Silme Yerine Pasife Alma Yaklaşımı

Hatalı yüklenen dosya, ana kayıttan tamamen yok edilmek yerine pasif veya iptal edilmiş olarak işaretlenebilir.

İleride şu alanlar değerlendirilebilir:

- `is_active`
- `deleted_at`
- `deleted_by`
- `delete_reason`
- `is_removed_from_view`

Bu adımda `FileAttachmentRecord` modeline yeni alan eklenmez.

## 7. Denetim İzi / Audit Trail Yaklaşımı

Dosya ekleme, taşıma, pasife alma ve silme işlemleri ileride işlem geçmişiyle izlenmelidir.

Şantiye şefi, yapı denetim, işveren veya idare açısından dosya geçmişi önemlidir. Bir fotoğrafın ne zaman eklendiği, kim tarafından eklendiği, sonradan taşınıp taşınmadığı veya pasife alınıp alınmadığı kalite hafızasının parçasıdır.

İleride bu işlem geçmişi ayrı bir modelle temsil edilebilir:

```text
AttachmentEventRecord
```

Bu model ileride şu olayları temsil edebilir:

- Dosya eklendi
- Dosya taşındı
- Dosya pasife alındı
- Dosya geri alındı
- Dosya referansı eksik bulundu
- Dosya metadata bilgisi güncellendi

Bu adımda yeni model eklenmez.

## 8. Yedekleme Yaklaşımı

Dosya klasör yapısı düzenli yedeklenebilir olmalıdır.

Metadata kayıtları ile fiziksel dosya arşivi birlikte yedeklenmelidir.

Sadece veritabanı veya JSON yedeği yeterli değildir. Fiziksel ek dosyalar da yedek kapsamına alınmalıdır.

İleride yedek bütünlüğü için şu kontroller değerlendirilebilir:

- Metadata kaydı var ama fiziksel dosya yok.
- Fiziksel dosya var ama metadata kaydı yok.
- Dosya yolu değişmiş ama kayıt güncellenmemiş.
- Aynı ana kayıt için beklenen dosya sayısı eksik.

Bu adımda yedekleme sistemi veya dosya varlık kontrolü eklenmez.

## 9. Video Dosyaları İçin Özel Güvenlik Notu

Video dosyaları büyük ve değerli olabilir.

Video dosyaları veritabanına gömülmeyecek. Dosya yolu / referansı ve metadata bilgisi tutulacaktır.

Video silme veya taşıma işlemleri özellikle kontrollü yapılmalıdır. Çünkü beton dökümü, iş güvenliği, drone ilerleme kaydı veya uygunsuzluk tespiti gibi konularda video sonradan önemli kanıt niteliği taşıyabilir.

Bu adımda şu davranışlar eklenmez:

- Thumbnail üretimi
- Streaming
- Preview
- Video oynatma
- Video sıkıştırma
- Video dosya analizi

## 10. Hukuki ve Saha Hafızası Açısından Karar

Beton döküm videosu, uygunsuzluk fotoğrafı, tutanak PDF'i veya malzeme irsaliyesi sonradan delil niteliği taşıyabilir.

Bu nedenle dosya ekleri kolayca kaybolmayacak, iz bırakmadan değiştirilmeyecek ve geri dönülmez şekilde silinmeyecek şekilde tasarlanmalıdır.

Şantiye hafızası açısından dosyanın ne zaman, hangi kayda ve kim tarafından eklendiği ileride kritik olacaktır.

Dosya eki sistemi büyüdüğünde temel ilke şu olmalıdır:

```text
Kanıt dosyası kaybolmadan, değişmeden ve iz bırakmadan silinmeden yönetilmelidir.
```

## 11. Yapılmayan İşler

Bu adımda şunlar yapılmadı:

- Dosya silme sistemi eklenmedi.
- Dosya taşıma sistemi eklenmedi.
- Dosya kopyalama veya yükleme sistemi eklenmedi.
- Soft-delete alanı eklenmedi.
- Audit trail modeli eklenmedi.
- Yeni Python davranışı eklenmedi.
- Yeni model eklenmedi.
- Repository eklenmedi.
- API, GUI veya CLI eklenmedi.
- Persistence davranışı eklenmedi.
- Thumbnail, preview, streaming veya video oynatma eklenmedi.

Bu adım sadece karar dokümantasyonu oluşturur.
