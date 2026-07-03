# Adim 114 - AuditEventRecord Validation Testleri

## Amac

Bu adimda `AuditEventRecord` baslangic modeline dar kapsamli validation davranisi eklendi.

Hedef, audit event kaydinin en temel kimlik ve olay alanlarinin bos kalmasini engellemektir. Bu davranis persistence, repository veya otomatik audit event uretimi degildir; yalnizca model olusturulurken guvenli baslangic kontroludur.

## Eklenen validation davranisi

`AuditEventRecord.__post_init__` icinde zorunlu alanlar kontrol edilir.

Bir zorunlu alan:

- bos string ise
- yalnizca whitespace iceriyorsa
- `None` olarak verildiyse

`ValueError` yukseltir.

Hata mesaji alan adini icerir:

```text
event_id is required
project_id is required
event_type is required
actor is required
occurred_at is required
```

## Zorunlu alanlar

Bu adimda zorunlu kabul edilen alanlar:

- `event_id`
- `project_id`
- `event_type`
- `actor`
- `occurred_at`

Bu alanlar audit event kaydinin kimligini, hangi projeye ait oldugunu, olay turunu, aktoru ve zamanini temsil eder.

## Opsiyonel alanlar

Bu alanlar `None` kalabilir:

- `target_record_type`
- `target_record_id`
- `reason`
- `old_value`
- `new_value`
- `source`
- `notes`

Bu adimda opsiyonel alanlara format, uzunluk, icerik veya pair tutarliligi validation eklenmedi.

## Neden yalnizca bos/whitespace/None kontrolu yapildi?

Audit event modeli henuz baslangic seviyesindedir.

Bu nedenle ilk validation yalnizca kaydin temel olarak anlamli olmasini saglar. Audit event icin daha zengin kurallar, once sozlesme ve kullanim ihtiyaci netlestikten sonra eklenmelidir.

Bu yaklasim kirici olmayan, test edilebilir ve kucuk adimla ilerleme ilkesini korur.

## Bu adimda bilincli olarak ertelenen validationlar

Bu adimda su kontroller eklenmedi:

- UUID format kontrolu
- ISO tarih/zaman format kontrolu
- event type enum kontrolu
- target record pair tutarliligi
- actor rol dogrulamasi
- project existence kontrolu
- old/new value JSON kontrolu
- maksimum uzunluk kontrolu
- ozel alan maskeleme sistemi
- otomatik ID uretimi
- otomatik `occurred_at` uretimi
- severity veya related attachment/report alanlari

## Test kapsami

Eklenen testler sunlari dogrular:

- bos zorunlu alanlar reddedilir
- whitespace zorunlu alanlar reddedilir
- `None` zorunlu alanlar reddedilir
- opsiyonel alanlar `None` kalabilir
- opsiyonel alanlar bos string olsa bile bu adimda reddedilmez

Bu testler `old_value` ve `new_value` alanlarinin bu adimda yalnizca opsiyonel metinsel metadata oldugunu da belgeler.

## Adim 115'e baglanti

Adim 115 icin uygun sonraki konu, audit event target record iliski kurallari veya event type sozlesmesi dokumantasyonudur.

Bu adimda yalnizca zorunlu alanlarin bos kalmasi engellendi. Target kayit iliskisi, event type listesi ve daha ileri audit sozlesmeleri ayrica ele alinmalidir.
