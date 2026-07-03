# Adim 113 - AuditEventRecord Baslangic Modeli

## Amac

Bu adimda audit event hatti icin yalnizca sade bir `AuditEventRecord` dataclass modeli eklendi.

Modelin amaci, ileride kanit degeri tasiyan olaylarin kim, ne, ne zaman, hangi kayit ve hangi gerekceyle gerceklestigi bilgisini tasiyabilecek veri sozlesmesini baslatmaktir.

## Model Alani

`AuditEventRecord` su zorunlu alanlari tasir:

- `event_id`
- `project_id`
- `event_type`
- `actor`
- `occurred_at`

Su alanlar opsiyonel metadata olarak tutulur:

- `target_record_type`
- `target_record_id`
- `reason`
- `old_value`
- `new_value`
- `source`
- `notes`

`target_record_type` ve `target_record_id` alanlarinin iliski kurallari Adim 117'de dokumante edildi.

Bu guncelleme model alanlarini degistirmez. Target record validation henuz eklenmedi.

## Sinirlar

Bu model persistence davranisi eklemez.

Bu adimda:

- audit repository eklenmedi
- otomatik audit yazimi eklenmedi
- decorator, middleware veya hook eklenmedi
- database veya migration eklenmedi
- JSON audit log yazimi eklenmedi
- scanner, export, backup veya restore hattina otomatik baglanti eklenmedi
- API, GUI, CLI veya AI entegrasyonu eklenmedi

## Test Kapsami

Model testleri:

- zorunlu alanlarin deger tasidigini
- opsiyonel alanlarin varsayilan olarak `None` kaldigini
- hedef kayit ve degisim baglami alanlarinin elle doldurulabildigini

dogrular.

## Konumlandirma

`AuditEventRecord`, resmi kaydin kendisi degildir. Bir kayit uzerinde veya bir sistem ciktisi etrafinda gerceklesen olayin izini temsil eder.

Ilk model bilerek serbest ve kucuk tutuldu. Validation, event type sozlugu, repository, otomatik uretim ve kalici saklama ayri adimlarin konusudur.
