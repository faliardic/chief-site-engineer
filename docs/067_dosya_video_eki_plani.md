# Adım 067 — Dosya ve Video Eki Planı

## Kısa Amaç

CHIEF SITE ENGINEER içinde fotoğraf, video, PDF ve belge gibi dosya eklerinin farklı kayıtlarla ilişkilendirilebilmesi gerekir.

Bu planın temel kararı şudur: Video dosyaları doğrudan veritabanına gömülmeyecek. Veritabanı veya ilerideki kalıcı kayıt katmanı, dosyanın kendisini değil dosya yolu / dosya referansı ve metadata bilgisini tutacaktır.

Bu yaklaşım, büyük medya dosyalarını sistemin veri modeli içinde şişirmeden izlenebilir hale getirir.

## Temel Kavram

Dosya ekleri ortak bir attachment yaklaşımıyla ele alınmalıdır.

Mevcut projede bu yaklaşımın başlangıcı `AttachmentRecord` modelidir. İleride ihtiyaç olursa aynı mantık daha açık bir adla `FileAttachmentRecord` olarak genişletilebilir.

Bu ortak yapı altında şu tür ekler temsil edilebilir:

- Fotoğraf
- Video
- PDF
- Belge
- Ses notu
- Diğer dosyalar

## Önerilen Temel Alanlar

İleride genişletilmiş bir `FileAttachmentRecord` veya güncellenmiş `AttachmentRecord` için şu alanlar değerlendirilebilir:

- `attachment_id`
- `related_record_type`
- `related_record_id`
- `file_name`
- `file_path`
- `file_type`
- `mime_type`
- `file_size`
- `uploaded_by`
- `uploaded_at`
- `description`
- `notes`

Bu alanlar dosyanın kendisini değil, dosyanın sistem içindeki referansını ve açıklayıcı bilgisini tutar.

## Dosya Tipi Örnekleri

`file_type` alanı için şu sınıflandırmalar kullanılabilir:

- `image`
- `video`
- `pdf`
- `document`
- `audio`
- `other`

Bu sınıflandırma, fotoğraf ve video gibi medya dosyalarını aynı temel attachment mantığı içinde ama açık tür bilgisiyle yönetmeyi sağlar.

## Video İçin Özel Notlar

Video dosyaları fotoğraflara göre daha büyük olabilir. Bu nedenle ilk aşamada video dosyasının kendisi işlenmemeli veya veritabanına gömülmemelidir.

İlk aşamada tutulacak bilgi:

- Video dosya adı
- Video dosya yolu veya depolama referansı
- Dosya tipi
- MIME tipi
- Dosya boyutu
- İlişkili kayıt türü ve kayıt kimliği
- Kısa açıklama
- Yükleyen kişi ve tarih

İlk aşamada eklenmemesi gerekenler:

- Video oynatma
- Video sıkıştırma
- Thumbnail üretme
- Streaming
- Medya dönüştürme
- Otomatik süre / çözünürlük okuma

İleride eklenebilecek alan veya davranışlar:

- Thumbnail yolu
- Önizleme bilgisi
- Video süresi
- Çözünürlük
- Dosya boyutu limiti
- Harici medya depolama entegrasyonu

## İlişkilendirilebilecek Kayıt Türleri

Dosya ve video ekleri şu kayıt türleriyle ilişkilendirilebilir:

- NCR / uygunsuzluk kaydı
- Saha notu
- Günlük kayıt
- Malzeme teslim kaydı
- İmalat kontrol kaydı
- İş güvenliği gözlemi
- Beton döküm kaydı
- Şantiye şefi özel notu

Bu ilişki için temel yaklaşım, `related_record_type` ve `related_record_id` benzeri alanlarla ekin hangi kayıtla ilgili olduğunu açıkça tutmaktır.

## Şantiye Şefi Açısından Anlamı

Uygunsuzluk kayıtları fotoğraf veya video ile kanıtlanabilir.

Beton döküm öncesi ve sonrası durum görsel olarak saklanabilir.

Donatı, kalıp, yalıtım, saha düzeni ve iş güvenliği riskleri fotoğraf veya video ile arşivlenebilir.

Drone veya telefon videosu ilerleme takibi için kullanılabilir.

Geçmiş kayıtlar denetlenebilir ve tekrar incelenebilir kalır.

## Davranış İlkeleri

- Dosya eki kayıt silmemeli.
- Ek dosya kaydı bağlı olduğu ana kaydı değiştirmemeli.
- Dosya yolu veya referansı izlenebilir olmalı.
- Aynı ana kayda birden fazla ek bağlanabilmeli.
- Dosya tipi açıkça saklanmalı.
- Fotoğraf ve video aynı temel attachment mantığıyla yönetilmeli.
- Büyük medya işleme özellikleri sonraya bırakılmalı.
- Dosyanın kendisi yerine dosya metadata bilgisi tutulmalı.
- İlk aşamada sistem sadece referans ve açıklama bilgisi taşımalı.

## Sonraki Küçük Adım Önerileri

- Adım 068: `FileAttachmentRecord` veri modeli
- Adım 069: Dosya tipi sınıflandırması
- Adım 070: Attachment kayıtlarının NCR ile ilişkilendirme planı
- Adım 071: Podcast notu 061-070

## Kapsam Dışı

Bu adımda uygulama kodu değiştirilmedi.

Bu adımda test dosyaları değiştirilmedi.

Bu adımda şu mekanizmalar eklenmedi:

- JSON
- SQLite
- API
- GUI
- CLI
- Dosya yükleme sistemi
- Video oynatma
- Thumbnail üretme
- Streaming
- Medya işleme
- Yeni Python davranışı
