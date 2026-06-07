# Adım 073 — Dosya Eki Örnek Kullanım Senaryoları

## Kısa Amaç

Bu adım, `FileAttachmentRecord` modelinin şantiye içindeki farklı kayıt türlerinde nasıl kullanılabileceğini örnek senaryolarla açıklar.

Bu doküman yeni Python davranışı eklemez. Dosya yükleme, dosya kopyalama, dosya silme, video oynatma, thumbnail üretme, API, GUI, CLI, SQLite veya JSON persistence bu adımın kapsamında değildir.

Amaç, fotoğraf, video, PDF, belge, ses notu ve diğer dosya eklerinin hangi ana kayıtlarla ilişkilendirilebileceğini saha pratiği üzerinden görünür hale getirmektir.

## Temel Kullanım Kararı

`FileAttachmentRecord`, dosyanın kendisini taşımaz.

Tutulan bilgi dosyanın referansı ve metadata bilgisidir:

- `related_record_type`
- `related_record_id`
- `file_name`
- `file_path`
- `file_type`
- `mime_type`
- `uploaded_by`
- `uploaded_at`
- `description`
- `notes`
- `file_size`

Dosya fiziksel olarak bir klasörde, sunucuda veya ileride bulut depolama ortamında tutulabilir. Büyük video dosyaları sistemin içine blob olarak gömülmez.

## Kontrollü Dosya Tipleri

`file_type` alanı proje içinde sade sınıflandırma için kullanılır:

- `image`
- `video`
- `pdf`
- `document`
- `audio`
- `other`

`mime_type` ise teknik dosya tipini belirtir. Örneğin `image/jpeg`, `video/mp4`, `application/pdf` veya `audio/mpeg`.

## 1. Beton Döküm Kaydına Fotoğraf / Video Bağlama

Beton döküm sürecinde görsel kayıt çok değerlidir. Dökümden önce donatı, kalıp, pas payı, tesisat geçişleri ve temizlik durumu fotoğraflanabilir. Döküm sırasında kısa video alınabilir. Dökümden sonra yüzey, mastarlama, kür uygulaması ve saha düzeni fotoğrafla belgelenebilir.

İlgili kayıt bağlantısı:

```text
related_record_type = "concrete_pour"
related_record_id = "CP-2026-001"
```

Örnek fotoğraf eki:

```text
file_name = "dokum-oncesi-donati-kontrol.jpg"
file_path = "attachments/concrete_pour/CP-2026-001/dokum-oncesi-donati-kontrol.jpg"
file_type = "image"
mime_type = "image/jpeg"
description = "Beton dokumu oncesi donati ve kalip kontrol fotografi."
```

Örnek video eki:

```text
file_name = "beton-dokum-ani.mp4"
file_path = "attachments/concrete_pour/CP-2026-001/beton-dokum-ani.mp4"
file_type = "video"
mime_type = "video/mp4"
description = "Beton dokumu sirasinda alinan kisa saha videosu."
```

Bu senaryo ileride `ConcretePourRecord` veya benzeri beton döküm kaydıyla ilişkilendirilebilir.

## 2. Uygunsuzluk / NCR Kaydına Fotoğraf, Video veya PDF Bağlama

Bir uygunsuzluk kaydının en güçlü tarafı, saha kanıtıyla desteklenmesidir. Uygunsuz imalat fotoğrafı, kısa saha videosu, tutanak veya teknik rapor PDF'i aynı NCR kaydına bağlanabilir.

İlgili kayıt bağlantısı:

```text
related_record_type = "nonconformity"
related_record_id = "NCR-00012"
```

Fotoğraf örneği:

```text
file_name = "hatali-imalat-fotografi.jpg"
file_path = "attachments/nonconformity/NCR-00012/hatali-imalat-fotografi.jpg"
file_type = "image"
mime_type = "image/jpeg"
```

Video örneği:

```text
file_name = "kisa-saha-videosu.mp4"
file_path = "attachments/nonconformity/NCR-00012/kisa-saha-videosu.mp4"
file_type = "video"
mime_type = "video/mp4"
```

PDF örneği:

```text
file_name = "teknik-rapor.pdf"
file_path = "attachments/nonconformity/NCR-00012/teknik-rapor.pdf"
file_type = "pdf"
mime_type = "application/pdf"
```

Bu senaryo `NonconformityRecord` veya `NonconformityCandidateRecord` ile kullanılabilir.

## 3. Malzeme Teslim Kaydına Belge Bağlama

Malzeme teslimlerinde irsaliye, fatura, ürün etiketi ve stok alanı fotoğrafı daha sonra kontrol için gerekebilir.

İlgili kayıt bağlantısı:

```text
related_record_type = "material_delivery"
related_record_id = "MAT-DEL-001"
```

İrsaliye PDF'i:

```text
file_name = "irsaliye.pdf"
file_path = "attachments/material_delivery/MAT-DEL-001/irsaliye.pdf"
file_type = "pdf"
mime_type = "application/pdf"
```

Malzeme etiketi fotoğrafı:

```text
file_name = "malzeme-etiketi.jpg"
file_path = "attachments/material_delivery/MAT-DEL-001/malzeme-etiketi.jpg"
file_type = "image"
mime_type = "image/jpeg"
```

Bu senaryo `MaterialDeliveryRecord` veya ilerideki malzeme kayıtları ile kullanılabilir.

## 4. Günlük Saha Kaydına Fotoğraf / Ses Notu Bağlama

Günlük saha kaydı yalnızca yazılı açıklamadan oluşmak zorunda değildir. Günlük ilerleme fotoğrafları, gün sonu kısa sesli not ve ekip/imalat alanı fotoğrafları aynı günlük kayda bağlanabilir.

İlgili kayıt bağlantısı:

```text
related_record_type = "daily_site"
related_record_id = "DSR-2026-06-07"
```

Günlük ilerleme fotoğrafı:

```text
file_name = "gunluk-ilerleme-a-blok.jpg"
file_path = "attachments/daily_site/DSR-2026-06-07/gunluk-ilerleme-a-blok.jpg"
file_type = "image"
mime_type = "image/jpeg"
```

Sesli not:

```text
file_name = "gun-sonu-notu.mp3"
file_path = "attachments/daily_site/DSR-2026-06-07/gun-sonu-notu.mp3"
file_type = "audio"
mime_type = "audio/mpeg"
```

Bu senaryo `DailySiteRecord` veya ilerideki günlük kayıt modeli ile ilişkilendirilebilir.

## 5. İşçilik / Ekip Kaydına Fotoğraf Bağlama

İşçilik ve ekip kayıtlarında çalışma alanı, günlük ilerleme ve iş güvenliği durumu görsel olarak saklanabilir.

İlgili kayıt bağlantısı:

```text
related_record_type = "workforce"
related_record_id = "WF-2026-001"
```

Örnek:

```text
file_name = "ekip-calisma-alani.jpg"
file_path = "attachments/workforce/WF-2026-001/ekip-calisma-alani.jpg"
file_type = "image"
mime_type = "image/jpeg"
description = "Ekip calisma alani ve gunluk ilerleme gorseli."
```

Bu senaryo `WorkforceRecord` ile kullanılabilir.

## 6. Şantiye Şefi Özel Notlarına Dosya Bağlama

Şantiye şefinin özel notları, günlük operasyonun hızlı hafızası olabilir. Telefon listesi PDF'i, hatırlatma görseli, özel saha notu eki veya toplantı notu belgesi bu kayıt türüne bağlanabilir.

İlgili kayıt bağlantısı:

```text
related_record_type = "chief_private_note"
related_record_id = "CPN-0008"
```

Örnek belge:

```text
file_name = "toplanti-notu.docx"
file_path = "attachments/chief_private_note/CPN-0008/toplanti-notu.docx"
file_type = "document"
mime_type = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
```

Bu senaryo ileride `SiteChiefPrivateNoteRecord` veya benzeri özel modül kaydı ile ilişkilendirilebilir.

## 7. Denetim / Kontrol Kayıtlarına Belge Bağlama

Denetim ve kontrol kayıtlarında kontrol formu, yapı denetim yazışması, belediye/kurum evrakı, teknik şartname veya imalat onayı gibi belgeler saklanabilir.

İlgili kayıt bağlantısı:

```text
related_record_type = "inspection"
related_record_id = "INS-2026-014"
```

Kontrol formu PDF'i:

```text
file_name = "kontrol-formu.pdf"
file_path = "attachments/inspection/INS-2026-014/kontrol-formu.pdf"
file_type = "pdf"
mime_type = "application/pdf"
```

Teknik şartname:

```text
file_name = "imalat-onayi.pdf"
file_path = "attachments/inspection/INS-2026-014/imalat-onayi.pdf"
file_type = "pdf"
mime_type = "application/pdf"
```

Bu kullanım, denetim geçmişinin yalnızca metin notu değil, evrak ve kanıt dosyalarıyla birlikte izlenebilmesini sağlar.

## Ortak Kurallar

- Dosyanın kendisi veritabanına gömülmez.
- Dosya fiziksel olarak klasörde, sunucuda veya bulutta tutulur.
- `FileAttachmentRecord` sadece referans ve metadata taşır.
- Büyük video dosyaları sistem içinde blob olarak saklanmaz.
- Aynı ana kayıt türüne birden fazla dosya bağlanabilir.
- Bir dosya eki her zaman ilgili ana kayıtla ilişkilendirilir.
- İlişki `related_record_type` ve `related_record_id` ile kurulur.
- `file_type` kontrollü değerlerle kullanılmalıdır.
- Dosya eki ana kaydı değiştirmez.
- Dosya eki ana kaydı silmez.

## Şantiye Şefi Açısından Anlamı

Bu yaklaşım, sahada görülen bir durumun tek başına yazılı kalmasını engeller.

Beton dökümü, uygunsuzluk, malzeme teslimi, günlük saha kaydı, ekip çalışması, özel not ve denetim kaydı gibi farklı konular fotoğraf, video, PDF veya belge ile desteklenebilir.

Böylece kalite geçmişi daha denetlenebilir, saha hafızası daha güçlü ve geçmişe dönük inceleme daha güvenilir hale gelir.

## Kapsam Dışı

Bu adımda uygulama kodu değiştirilmedi.

Bu adımda test dosyaları değiştirilmedi.

Bu adımda şu mekanizmalar eklenmedi:

- Yeni Python davranışı
- Repository
- Dosya yükleme sistemi
- Fiziksel dosya kopyalama
- Dosya silme veya taşıma
- Thumbnail
- Video oynatma
- Önizleme
- Streaming
- SQLite
- JSON persistence
- API
- GUI
- CLI
