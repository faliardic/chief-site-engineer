# ADR-001: SQLite Kalıcılığı ve Yönetilen Ek Dosyalar

- Durum: Kabul edildi
- Tarih: 2026-07-12
- İlgili iş: GitHub Issue #71

## Bağlam

Chief Site Engineer'ın ilk saha MVP'si, uygulama kapandığında kaybolmayan ve
haricî bir sunucu gerektirmeden yerel bilgisayarda çalışabilen bir veri omurgasına
ihtiyaç duyar. Mevcut bellek içi modeller öğrenme ve davranış keşfi için yararlı
olsa da resmî saha kayıtlarının kalıcı kaynağı olamaz.

Kalıcı kayıtlar ile fotoğraf, PDF ve benzeri ek dosyalar aynı yaşam döngüsünün
parçalarıdır; fakat binary dosyaları doğrudan veritabanında tutmak dosya
yönetimini, bütünlük kontrolünü ve ilerideki devir paketlerini gereksiz biçimde
zorlaştırır. Ayrıca şemanın zaman içinde güvenli ve tekrarlanabilir şekilde
değişebilmesi gerekir.

## Karar

### Ana kalıcılık katmanı

- Ana persistence teknolojisi Python standard library içindeki `sqlite3` modülü
  ve SQLite olacaktır.
- JSON ana veritabanı değildir. Yalnız import, export ve support bundle formatı
  olarak kullanılacaktır.
- Şema değişiklikleri sıralı, sürümlü ve transaction içinde çalışan migration'lar
  ile uygulanacaktır. İlk sürüm `schema v1` olarak kaydedilecektir.
- Migration durumu `schema_migrations` tablosunda tutulacaktır.
- ORM eklenmeyecektir; bu aşamada SQL açık ve doğrudan okunabilir kalacaktır.

### Kimlik, zaman ve durum sözleşmeleri

- Yeni kalıcı kayıt kimlikleri canonical, küçük harfli ve tireli UUID string
  biçiminde olacaktır.
- Storage zamanları timezone-aware değerlerden üretilecek ve UTC ISO 8601
  biçiminde, `Z` son ekiyle saklanacaktır.
- Saha gözlemi durumları yalnız `open`, `tracking` ve `closed` olabilir.
- Yeni saha gözleminin başlangıç `revision` değeri `1` olacaktır.
- `closed` durumunda `closed_at` zorunludur; `open` ve `tracking` durumlarında
  `closed_at` boş olmalıdır.
- Optimistic concurrency için ilerideki update işlemleri `revision` değerini
  karşılaştıracaktır. Bu ADR revision alanını ve constraint'i kesinleştirir;
  update servisini uygulamaz.

### Yönetilen ek dosya deposu

- Attachment binary'leri SQLite içine BLOB olarak gömülmeyecektir.
- Uygulama tarafından yönetilen bir attachment root, file store sınırı olacaktır.
- Veritabanında binary yerine yalnız attachment root'a göre relative path,
  SHA-256, byte size, MIME type ve lifecycle metadata tutulacaktır.
- Attachment yaşam döngüsü `active`, `archived`, `superseded` ve `missing`
  değerleriyle temsil edilecektir.
- `stored_relative_path` benzersiz olacaktır; iki metadata kaydı aynı yönetilen
  dosyayı sessizce sahiplenemeyecektir.

### Kayıt yaşam döngüsü

- Resmî kayıtlar normal iş akışında fiziksel olarak silinmeyecektir.
- Kayıtlar `archived_at` ile arşivlenecek; ek dosyaların eski sürümleri
  `superseded` olarak işaretlenecektir.
- Fiziksel silme ayrı veri saklama politikası, açık kullanıcı kararı ve denetim
  izi gerektiren gelecekteki bir bakım işlemidir.

### Gelecekteki dosya finalize koordinasyonu

Bu görev gerçek dosya kopyalama veya finalize işlemi uygulamaz. Gelecekteki
application service şu iki kaynağı koordine edecektir:

1. SQLite içindeki attachment metadata ve observation event kaydı.
2. Yönetilen file store içindeki geçici ve finalize edilmiş binary dosya.

Veritabanı transaction'ı ile dosya sistemi tek bir ortak transaction paylaşamaz.
Bu nedenle gelecekteki akış geçici dosya, SHA-256/size doğrulaması, metadata/event
yazımı ve güvenli finalize adımlarını açıkça yönetecektir. Uygulama başlangıcında
çalışacak reconciliation işlemi; metadata var/dosya yok, dosya var/metadata yok
ve yarım kalmış geçici dosya durumlarını tespit edecektir. Bu ADR yalnız sınırı
tanımlar; finalize veya startup reconciliation davranışını uygulamaz.

## Sonuçlar

### Olumlu sonuçlar

- Ek servis veya paket olmadan yerel, tek dosyalı bir kalıcılık temeli oluşur.
- Foreign key ve CHECK constraint'leri temel veri tutarsızlıklarını veritabanı
  sınırında reddeder.
- Migration runner fresh database ve tekrar çalıştırma senaryolarını aynı API ile
  güvenli biçimde yönetir.
- Ek dosya binary'leri ile aranabilir metadata birbirinden ayrılır.
- UUID, UTC ve revision sözleşmeleri ilerideki repository/application service
  katmanları için açık bir sınır oluşturur.

### Bedeller ve riskler

- SQLite aynı anda yoğun çok-kullanıcılı yazım için seçilmemiştir.
- Veritabanı ile file store arasında gelecekte açık koordinasyon ve reconciliation
  gerekir.
- Şema migration'ları yayımlandıktan sonra immutable kabul edilmeli; sonraki
  değişiklikler yeni migration sürümüyle yapılmalıdır.
- Backup, restore ve attachment root taşıma davranışları ayrıca tasarlanmalıdır.

## Bu ADR'nin uygulamadığı konular

- SQLite repository adapter CRUD ve Unit of Work
- Application service ve status transition servisi
- Gerçek attachment copy, hash, temp-file veya finalize işlemi
- Startup reconciliation uygulaması
- Daily export ve backup/restore
- UI, API, CLI veya web framework
- ORM
- Cloud sync, offline sync ve multi-user koordinasyonu
- Authentication ve özel alan yetkilendirmesi
- Database veya file-store encryption
