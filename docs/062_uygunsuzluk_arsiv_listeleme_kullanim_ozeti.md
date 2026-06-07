# Adım 062 — Uygunsuzluk Arşiv/Listeleme Kullanım Özeti

## Kısa Amaç

Bu not, `NonconformityRepository` içinde Adım 056-060 arasında netleşen NCR arşivleme ve listeleme davranışlarını kısa bir kullanım özeti olarak toplar.

NCR kayıtları sistemden silinmeden yönetilir. Bir kayıt aktif takipte kalabilir, arşive alınabilir, tekrar aktif hale getirilebilir veya tüm kayıt hafızasında görünmeye devam edebilir.

Bu yaklaşım şantiye kalite takibi için önemlidir. Çünkü uygunsuzluk kayıtları kaybolmaz, aktif takip listesi sade kalır ve geçmişe dönük izlenebilirlik korunur.

## Kullanılan Repository Davranışları

- `archive(nonconformity_id)`
- `restore(nonconformity_id)`
- `list_active()`
- `list_archived()`
- `list_all()`
- `get_archive_summary()`

## Davranışların Anlamı

`archive(nonconformity_id)`: Mevcut NCR kaydını silmeden arşive alır. Kayıt repository içinde kalır, sadece `is_archived` alanı `True` olur.

`restore(nonconformity_id)`: Arşivlenmiş NCR kaydını tekrar aktif hale getirir. Yeni kayıt oluşturmaz, mevcut kaydın `is_archived` alanını `False` yapar.

`list_active()`: Sadece aktif NCR kayıtlarını döndürür. Yani `is_archived == False` olan kayıtları listeler.

`list_archived()`: Sadece arşivlenmiş NCR kayıtlarını döndürür. Yani `is_archived == True` olan kayıtları listeler.

`list_all()`: Aktif ve arşivlenmiş tüm NCR kayıtlarını birlikte döndürür. Arşivlenmiş kayıtları dışlamaz.

`get_archive_summary()`: Aktif, arşivlenmiş ve toplam NCR kayıt sayılarını verir.

Örnek dönüş:

```python
{
    "active": 2,
    "archived": 1,
    "total": 3,
}
```

## Örnek Kullanım Akışı

Repository içinde 3 NCR kaydı olduğunu varsayalım.

Başlangıçta hiçbir kayıt arşivlenmemişse:

```python
{
    "active": 3,
    "archived": 0,
    "total": 3,
}
```

Bir kayıt `archive(nonconformity_id)` ile arşivlenirse:

```python
{
    "active": 2,
    "archived": 1,
    "total": 3,
}
```

Bu durumda:

- `list_active()` iki aktif kaydı döndürür.
- `list_archived()` bir arşivlenmiş kaydı döndürür.
- `list_all()` üç kaydı da döndürmeye devam eder.

Arşivlenen kayıt `restore(nonconformity_id)` ile tekrar aktif hale getirilirse:

```python
{
    "active": 3,
    "archived": 0,
    "total": 3,
}
```

Toplam kayıt sayısı değişmez. Çünkü archive ve restore işlemleri kayıt silmez veya yeni kayıt oluşturmaz.

## Kritik Kurallar

- Arşivleme kayıt silmez.
- Restore yeni kayıt oluşturmaz; mevcut kaydı tekrar aktif eder.
- Listeleme davranışları kayıtları değiştirmez.
- `status` alanı listeleme, archive veya restore sırasında kendiliğinden değişmez.
- `is_archived` görünürlük/arşiv durumunu temsil eder.
- `status` iş süreci durumunu temsil eder.
- Bu ayrım ileride SQLite, API, GUI veya dashboard eklense bile korunması gereken temel davranıştır.

## Şantiye Şefi Açısından Karşılığı

Kapanmış veya geçici olarak pasife alınmış uygunsuzluklar sistemden kaybolmaz. Arşive alınır ve gerektiğinde tekrar incelenebilir.

Aktif takip listesi sade kalır. Şantiye şefi günlük olarak yalnız aktif NCR kayıtlarına odaklanabilir.

Arşivlenmiş kayıtlar kalite geçmişinde kalır. Denetim, geçmiş inceleme veya kalite toplantısı sırasında bu kayıtlar tekrar görülebilir.

Yanlışlıkla arşivlenen kayıt restore ile tekrar aktif takibe alınabilir.

Bu yapı, kalite geçmişinin denetlenebilir ve izlenebilir kalmasını sağlar.

## Kapsam Dışı

Bu adımda uygulama kodu değiştirilmedi.

Bu adımda test dosyaları değiştirilmedi.

Bu adımda şu mekanizmalar eklenmedi:

- JSON
- SQLite
- API
- GUI
- CLI
- Dashboard
- Yeni Python davranışı
- Silme mantığı
- Otomatik history
- Otomatik workflow
