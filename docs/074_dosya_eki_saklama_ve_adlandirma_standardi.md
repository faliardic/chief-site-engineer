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

## 2. Önerilen Ana Klasör Yapısı

İlk standart klasör yaklaşımı şu şekilde düşünülebilir:

```text
attachments/
  project_id/
    concrete/
    nonconformity/
    material/
    daily_site/
    workforce/
    inspection/
    site_chief_private/
    other/
```

Bu yapı, dosyaları bağlı oldukları ana kayıt türüne göre ayırır. Böylece beton, uygunsuzluk, malzeme, günlük saha, işçilik, denetim ve özel not ekleri aynı kök altında ama ayrı alanlarda saklanabilir.

## 3. Tarih Bazlı Alt Klasör Yaklaşımı

Kayıt sayısı arttıkça tek klasörde çok fazla dosya birikmemesi için tarih bazlı alt klasör kullanılabilir.

Örnek:

```text
attachments/
  project_id/
    concrete/
      2026/
        06/
          07/
```

Bu yapı, dosyaların hangi yıl, ay ve güne ait olduğunu klasör yolundan anlaşılır hale getirir.

## 4. Kayıt Türü ve Kayıt ID İlişkisi

Dosya klasörü, `related_record_type` ve `related_record_id` bilgisiyle uyumlu olmalıdır.

Örnek mantık:

```text
related_record_type = "concrete_pour"
related_record_id = "CP-000123"
```

Önerilen dosya klasörü:

```text
attachments/project_id/concrete/2026/06/07/CP-000123/
```

Bu yaklaşım, dosya sistemine bakıldığında dosyanın hangi proje, kayıt türü, tarih ve kayıt id ile ilgili olduğunu gösterir.

## 5. Dosya Adlandırma Standardı

Önerilen dosya adı şablonu:

```text
YYYYMMDD_HHMMSS__record_type__record_id__file_type__sequence.ext
```

Örnekler:

```text
20260607_143210__concrete_pour__CP-000123__image__001.jpg
20260607_143455__concrete_pour__CP-000123__video__001.mp4
20260607_160030__material_delivery__MD-000045__pdf__001.pdf
20260607_171500__nonconformity__NCR-000012__image__001.jpg
```

Bu şablon dosya adının tek başına da anlamlı olmasını sağlar. Dosya adı tarih, kayıt türü, kayıt id, dosya tipi ve sıra bilgisini içerir.

## 6. Dosya Adı Kuralları

Dosya adlarında şu kurallar tercih edilmelidir:

- Küçük harf kullanılmalı.
- Boşluk kullanılmamalı.
- Türkçe karakter kullanılmamalı.
- Özel karakterlerden kaçınılmalı.
- Ayırıcı olarak çift alt çizgi ve tek alt çizgi standardize edilmeli.
- Dosya uzantısı orijinal MIME type ile uyumlu olmalı.
- Aynı kayda ait çoklu dosyalarda sequence numarası kullanılmalı: `001`, `002`, `003`.

Önerilen ayrım:

- Tarih ve saat içinde tek alt çizgi: `20260607_143210`
- Ana parçalar arasında çift alt çizgi: `__`
- Sıra numarası üç haneli: `001`

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
