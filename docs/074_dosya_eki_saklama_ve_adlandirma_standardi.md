# Adım 074 — Dosya Eki Saklama ve Adlandırma Standardı

## Kısa Amaç

Bu adım, `FileAttachmentRecord` ile temsil edilen fotoğraf, video, PDF, belge, ses ve diğer dosya ekleri için ileride kullanılacak saklama klasör yapısı ve dosya adlandırma standardını dokümante eder.

Bu adım yalnızca dokümantasyon adımıdır. Uygulama kodu, test dosyaları, repository, dosya yükleme, fiziksel dosya kopyalama, dosya silme, dosya taşıma, video oynatma, thumbnail, önizleme, SQLite, JSON persistence, API, GUI veya CLI davranışı eklenmez.

## 1. Temel Saklama Yaklaşımı

Dosyanın kendisi veritabanına gömülmeyecek.

Dosya fiziksel olarak şu ortamlardan birinde tutulabilir:

- Proje klasörü içindeki kontrollü bir dosya alanı
- Sunucu dosya sistemi
- Ağ paylaşımı
- İleride bulut depolama ortamı

`FileAttachmentRecord` yalnızca dosya yolu / dosya referansı ve metadata bilgisini tutar.

Büyük video dosyaları sistem içinde blob olarak saklanmayacak. Video dosyası da fotoğraf, PDF veya belge gibi bir dosya referansı üzerinden izlenecek.

## 2. Canonical Path Standardı

Adım 085 itibarıyla yeni dosya eki hattı için canonical path standardı şudur:

```text
attachments/{project_id}/{record_type}/{yyyy}/{mm}/{dd}/{record_id}/{safe_file_name}
```

Örnekler:

```text
attachments/PRJ-001/nonconformity/2026/06/07/NCR-00012/photo_001.jpg
attachments/PRJ-001/concrete/2026/06/07/CP-000123/slump_test.pdf
attachments/PRJ-001/site_note/2026/06/07/SN-00045/site_photo.jpg
```

Bu yapı dosyaları proje, kayıt türü, tarih ve ana kayıt kimliğiyle birlikte izlenebilir yapar.

## 4. Kayıt Türü ve Kayıt ID İlişkisi

Dosya klasörü, `related_record_type` ve `related_record_id` bilgisiyle uyumlu olmalıdır. Canonical path içinde `related_record_type`, `record_type` klasörü olarak kullanılır.

Örnek mantık:

```text
project_id = "PRJ-001"
related_record_type = "concrete"
related_record_id = "CP-000123"
date = "2026-06-07"
safe_file_name = "slump_test.pdf"
```

Canonical dosya yolu:

```text
attachments/PRJ-001/concrete/2026/06/07/CP-000123/slump_test.pdf
```

Bu yaklaşım, dosya sistemine bakıldığında dosyanın hangi proje, kayıt türü, tarih ve kayıt id ile ilgili olduğunu gösterir.

## 5. Dosya Adlandırma Standardı

Canonical path içinde son parça `safe_file_name` değeridir.

```text
safe_file_name
```

Örnekler:

```text
photo_001.jpg
concrete_pour_video_001.mp4
material_delivery_report.pdf
ncr_photo_001.jpg
```

Dosya adı tek başına da okunabilir olabilir; fakat proje, kayıt türü, tarih ve kayıt id bilgisi artık canonical path içinde açıkça taşınır.

## 6. Dosya Adı Kuralları

Dosya adlarında şu kurallar tercih edilmelidir:

- Küçük harf kullanılmalı.
- Boşluk kullanılmamalı.
- Türkçe karakter kullanılmamalı.
- Özel karakterlerden kaçınılmalı.
- Ayırıcı olarak çift alt çizgi ve tek alt çizgi standardize edilmeli.
- Dosya uzantısı orijinal MIME type ile uyumlu olmalı.
- Aynı kayda ait çoklu dosyalarda sequence numarası kullanılmalı: `001`, `002`, `003`.

`safe_file_name`, kullanıcı tarafından gelen orijinal dosya adından farklı olabilir. Orijinal ad metadata olarak `original_file_name` alanında korunabilir.

## 7. Orijinal Dosya Adı Yaklaşımı

Fiziksel dosya sisteminde güvenli ve standart dosya adı kullanılmalıdır.

Kullanıcının yüklediği orijinal dosya adı metadata olarak saklanabilir.

İleride `FileAttachmentRecord` için şu alan değerlendirilebilir:

```text
original_file_name
```

Orijinal dosya adı tek başına sistem kimliği olarak kullanılmamalıdır. Çünkü kullanıcı dosya adlarında boşluk, Türkçe karakter, tekrar eden ad veya sistem için riskli özel karakterler bulunabilir.

## 8. FileAttachmentRecord İçinde Tutulabilecek Metadata Notları

`FileAttachmentRecord` veya ileride genişletilecek dosya eki modeli şu bilgileri taşıyabilir:

- `file_name`
- `file_path` veya `storage_reference`
- `file_type`
- `mime_type`
- `file_size`
- `related_record_type`
- `related_record_id`
- `uploaded_at` veya `created_at`
- `uploaded_by` veya `created_by`
- `notes`

Bu bilgiler dosyanın içeriğini değil, dosyanın sistem içinde nasıl bulunacağını ve hangi kayda bağlı olduğunu anlatır.

## 9. Video Dosyaları İçin Özel Not

Video dosyaları büyük olabilir.

Bu nedenle video dosyaları veritabanına gömülmeyecek. Sadece dosya yolu / referansı ve metadata bilgisi tutulacak.

İleride video için şu metadata alanları değerlendirilebilir:

- Thumbnail yolu
- Duration / süre
- Resolution / çözünürlük
- Codec
- Dosya boyutu limiti
- Önizleme bilgisi

Bu adımda video oynatma, preview, thumbnail üretimi, streaming veya medya işleme eklenmez.

## 10. Yedekleme ve Arşiv Mantığı

Dosya yolu standardı yedeklemeyi kolaylaştırmalıdır.

Dosya adları tarih ve kayıt ilişkisini dışarıdan okunabilir yapmalıdır.

Dosya taşınırsa `FileAttachmentRecord` içindeki dosya yolu veya storage reference güncellenmelidir.

Dosya silme işlemi ileride kontrollü, yetkili ve loglanabilir olmalıdır. Bu adımda dosya silme davranışı eklenmez.

Arşiv açısından temel ilke şudur: Kayıt kanıtı olan dosya, rastgele kaybolmamalı veya kimliksiz kalmamalıdır.

## 11. Şantiye Şefi Açısından Anlamı

Bu standart, saha kanıtlarının dosya sisteminde dağınık ve belirsiz kalmasını önler.

Bir beton döküm videosu, bir NCR fotoğrafı, bir malzeme irsaliyesi veya bir denetim PDF'i hem klasör yolundan hem dosya adından anlaşılabilir olur.

Şantiye şefi için bu, geçmişe dönük incelemede zaman kazandırır. Kalite denetimi, hakediş kontrolü, malzeme teslim doğrulaması ve uygunsuzluk takibi daha izlenebilir hale gelir.

## 12. Yapılmayan İşler

Bu adımda şunlar yapılmadı:

- Dosya yükleme sistemi eklenmedi.
- Fiziksel dosya kopyalama, taşıma veya silme eklenmedi.
- Veritabanı veya persistence davranışı eklenmedi.
- API, GUI veya CLI eklenmedi.
- Thumbnail, preview veya video oynatma eklenmedi.
- Streaming veya medya işleme eklenmedi.
- Yeni Python davranışı eklenmedi.
- Repository eklenmedi.

Bu adım sadece dokümantasyon standardı oluşturur.
