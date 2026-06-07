# Adım 072 — Dosya Eki Kullanım Akışı

## Kısa Amaç

Bu adım, `FileAttachmentRecord` modelinin fotoğraf, video, PDF, belge ve ses dosyaları için ileride nasıl kullanılacağını kavramsal bir akış olarak açıklar.

Bu doküman gerçek dosya yükleme, dosyayı klasöre kopyalama, video oynatma veya thumbnail üretme davranışı eklemez. Amaç, ileride eklenecek dosya eki repository, yükleme, arşivleme veya listeleme adımlarının temel kullanım mantığını netleştirmektir.

## Temel Akış

Dosya eki kullanımı şu sırayla düşünülür:

1. Ana kayıt oluşturulur.
2. Dosya fiziksel olarak bir klasörde, sunucuda veya ileride bulut depolama ortamında tutulur.
3. `FileAttachmentRecord` dosyanın kendisini değil, dosya referansını ve metadata bilgisini tutar.
4. `related_record_type` ve `related_record_id` ile dosyanın hangi ana kayda bağlı olduğu belirtilir.
5. `file_type` ve `mime_type` ile dosyanın türü anlaşılır.
6. `description` ve `notes` alanlarıyla saha bağlamı korunur.

Bu yapı, büyük dosyaları model içine gömmeden, dosyanın hangi kayda neden bağlandığını izlenebilir hale getirir.

## Örnek Akışlar

### NCR Kaydına Fotoğraf Ekleme

Bir uygunsuzluk kaydında hatalı imalat fotoğrafla desteklenebilir.

```text
related_record_type = "nonconformity"
related_record_id = "NCR-00012"
file_name = "kolon-donati-uygunsuzluk.jpg"
file_path = "attachments/nonconformity/NCR-00012/kolon-donati-uygunsuzluk.jpg"
file_type = "image"
mime_type = "image/jpeg"
```

Bu kayıt fotoğraf dosyasının içeriğini taşımaz. Fotoğrafın nerede olduğunu ve hangi NCR kaydıyla ilişkili olduğunu anlatır.

### NCR Kaydına Video Ekleme

Bir uygunsuzluk sahada video ile belgelenebilir.

```text
related_record_type = "nonconformity"
related_record_id = "NCR-00012"
file_name = "beton-dokum-oncesi-kontrol.mp4"
file_path = "attachments/nonconformity/NCR-00012/beton-dokum-oncesi-kontrol.mp4"
file_type = "video"
mime_type = "video/mp4"
```

Bu kullanımda video dosyası modele gömülmez. Model sadece video referansını ve açıklayıcı metadata bilgisini tutar.

### Günlük Kayda PDF Ekleme

Günlük rapora imzalı PDF veya ek rapor bağlanabilir.

```text
related_record_type = "daily_log"
related_record_id = "DL-2026-06-07"
file_name = "gunluk-rapor-ek.pdf"
file_path = "attachments/daily_log/DL-2026-06-07/gunluk-rapor-ek.pdf"
file_type = "pdf"
mime_type = "application/pdf"
```

### Malzeme Teslim Kaydına İrsaliye Fotoğrafı Ekleme

Malzeme tesliminde irsaliye veya ürün etiketi fotoğrafla saklanabilir.

```text
related_record_type = "material_delivery"
related_record_id = "MAT-DEL-001"
file_name = "irsaliye-fotografi.jpg"
file_path = "attachments/material_delivery/MAT-DEL-001/irsaliye-fotografi.jpg"
file_type = "image"
mime_type = "image/jpeg"
```

### İş Güvenliği Gözlemine Video Ekleme

Riskli bir saha davranışı veya uygunsuz güvenlik durumu video ile belgelenebilir.

```text
related_record_type = "safety_observation"
related_record_id = "SAFE-OBS-004"
file_name = "iskele-guvenlik-gozlemi.mp4"
file_path = "attachments/safety_observation/SAFE-OBS-004/iskele-guvenlik-gozlemi.mp4"
file_type = "video"
mime_type = "video/mp4"
```

## Video Özel Akışı

Video dosyaları fotoğraflara göre daha büyük olabilir. Bu nedenle ilk aşamada sadece dosya yolu / referansı ve metadata tutulur.

Video için ilk aşamada tutulabilecek bilgiler:

- Dosya adı
- Dosya yolu veya depolama referansı
- Dosya tipi
- MIME tipi
- Dosya boyutu
- Yükleyen kişi
- Yükleme tarihi
- Bağlı olduğu ana kayıt
- Açıklama ve saha notu

Bu adımda video içeriği modele gömülmez.

Sonraki aşamalara bırakılan işler:

- Thumbnail üretme
- Video süresi tutma
- Çözünürlük bilgisi
- Video oynatma
- Video sıkıştırma
- Önizleme
- Streaming

Video ekleri özellikle beton dökümü, donatı kontrolü, iş güvenliği gözlemi, saha ilerleme kaydı ve drone görüntüleri için değerlidir.

## Kritik Kurallar

- Dosya eki ana kaydı değiştirmez.
- Dosya eki ana kaydı silmez.
- Aynı ana kayda birden fazla dosya eki bağlanabilir.
- Dosya eki kaydı, dosya içeriği değil dosya referansı tutar.
- `related_record_type` ve `related_record_id` bağlantıyı açık hale getirir.
- `file_type` proje içindeki sade dosya sınıfını belirtir.
- `mime_type` teknik dosya türünü belirtir.
- Şimdilik foreign key, ORM relation, API, GUI veya dosya yükleme sistemi yoktur.
- Dosya ekleri izlenebilirlik ve kanıt arşivi için tasarlanır.

## Şantiye Şefi Açısından Anlamı

Uygunsuzluk kaydı fotoğraf veya video kanıtıyla desteklenebilir.

Günlük raporlar ek belgelerle güçlenir.

İmalat öncesi ve sonrası saha durumu arşivlenebilir.

Malzeme teslimleri irsaliye veya ürün fotoğrafıyla desteklenebilir.

Denetim ve kalite geçmişi görsel kanıtlarla izlenebilir hale gelir.

Bu yaklaşım, sahada görülen bir durumun yalnızca yazılı not olarak kalmasını engeller. Kayıt, ilgili fotoğraf, video veya belgeyle birlikte daha anlaşılır ve denetlenebilir olur.

## Python Öğrenme Açısından Anlamı

Bu adım şu kavramları pekiştirir:

- Metadata modeli kullanımı
- Ana kayıt / ek kayıt ayrımı
- Dosya içeriği yerine dosya referansı tutma
- İlişkisel düşünmeye hazırlık
- Büyük dosya yönetimini küçük modelleme adımlarına bölme
- Dosya tipi ile MIME tipi arasındaki fark

`FileAttachmentRecord`, büyük bir dosya yönetim sistemi değildir. Küçük ve okunabilir bir veri modeliyle, ileride eklenecek repository, yükleme ve arşivleme adımları için temel davranış dilini hazırlar.

## Kapsam Dışı

Bu adımda uygulama kodu değiştirilmedi.

Bu adımda test dosyaları değiştirilmedi.

Bu adımda şu mekanizmalar eklenmedi:

- Yeni Python davranışı
- Repository
- Dosya yükleme sistemi
- Dosyayı fiziksel olarak klasöre kopyalama
- Video oynatma
- Thumbnail
- Önizleme
- SQLite
- JSON persistence
- API
- GUI
- CLI
