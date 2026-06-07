# Adım 070 — Dosya Eki İlişkili Kayıt Bağlantısı

## Kısa Amaç

Dosya ekleri tek başına değil, bir ana kayıtla ilişkili olduğunda anlam kazanır.

Fotoğraf, video, PDF, belge ve ses dosyaları `FileAttachmentRecord` ile temsil edilir. Bu model dosya içeriğini taşımaz; dosya yolu / referansı ve metadata bilgisini tutar.

Ana kayıt bağlantısı `related_record_type` ve `related_record_id` alanları üzerinden kurulur.

## Temel Bağlantı Mantığı

`related_record_type`: Dosya ekinin bağlı olduğu kayıt türünü belirtir.

`related_record_id`: Dosya ekinin bağlı olduğu ana kaydın id değerini belirtir.

Bu iki alan birlikte dosya ekinin hangi kayda ait olduğunu gösterir.

Örneğin:

```text
related_record_type = "nonconformity"
related_record_id = "NCR-00012"
```

Bu ifade, dosya ekinin `NCR-00012` kimlikli uygunsuzluk kaydına bağlı olduğunu anlatır.

## Örnek Kayıt Türleri

Kullanılabilecek kayıt türü değerleri:

- `nonconformity`
- `site_note`
- `daily_log`
- `material_delivery`
- `inspection`
- `safety_observation`
- `concrete_pour`
- `chief_private_note`

Bu değerler şimdilik string tabanlı basit ilişki etiketleridir.

## Örnek Kullanım

NCR kaydına fotoğraf ekleme:

```text
related_record_type = "nonconformity"
related_record_id = "NCR-00012"
file_type = "image"
```

NCR kaydına video ekleme:

```text
related_record_type = "nonconformity"
related_record_id = "NCR-00012"
file_type = "video"
```

Günlük kayda PDF ekleme:

```text
related_record_type = "daily_log"
related_record_id = "DL-2026-06-07"
file_type = "pdf"
```

Malzeme teslim kaydına irsaliye fotoğrafı ekleme:

```text
related_record_type = "material_delivery"
related_record_id = "MAT-DEL-001"
file_type = "image"
```

## Kritik Kurallar

- Dosya eki ana kaydı değiştirmemeli.
- Dosya eki ana kaydı silmemeli.
- Ana kayıt silinse bile ileride arşiv / izlenebilirlik politikası ayrıca tasarlanmalı.
- Bir ana kayda birden fazla dosya eki bağlanabilir.
- Aynı dosya tipi birden fazla kez kullanılabilir.
- Dosya içeriği modele gömülmez.
- Dosya yolu / referansı ve metadata tutulur.
- İlişki alanları şimdilik string tabanlı basit bağlantı olarak kalır.
- Foreign key, database relation, ORM, SQLite, API veya GUI bu adımda eklenmez.

## Şantiye Şefi Açısından Anlamı

Bir uygunsuzluk kaydına fotoğraf veya video kanıtı bağlanabilir.

Günlük rapora PDF veya görsel eklenebilir.

Malzeme teslimine irsaliye fotoğrafı bağlanabilir.

İş güvenliği gözlemine video eklenebilir.

Geçmiş kayıtlar dosya kanıtlarıyla birlikte izlenebilir hale gelir.

## Python Öğrenme Açısından Anlamı

Bu adım şu kavramları netleştirir:

- Basit ilişki modelleme
- Metadata ile dosya temsil etme
- Ana kayıt / ek kayıt ayrımı
- String tabanlı ilişki kurma
- Büyük veritabanı ilişkilerine geçmeden önce küçük modelleme

`related_record_type` ve `related_record_id`, henüz foreign key değildir. Bunlar Python veri modeli içinde sade ve okunabilir bir bağlantı bilgisidir.

## Kapsam Dışı

Bu adımda uygulama kodu değiştirilmedi.

Bu adımda test dosyaları değiştirilmedi.

Bu adımda şu mekanizmalar eklenmedi:

- Yeni Python davranışı
- Repository
- Dosya yükleme sistemi
- Dosyayı fiziksel klasöre kopyalama
- Video oynatma
- Thumbnail veya önizleme
- Foreign key
- ORM relation
- SQLite
- JSON persistence
- API
- GUI
- CLI
