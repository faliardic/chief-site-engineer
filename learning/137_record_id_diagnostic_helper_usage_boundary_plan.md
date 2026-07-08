# Adim 137 - Record ID Diagnostic Helper Usage Boundary Plan

## Sunu yaptik

`diagnose_record_id_for_target_type(...)` helper'inin nerede kullanilabilecegini ve nerede kullanilmamasi gerektigini belgeledik.

Bu adimda kod yazmadik. Test yazmadik. Runtime davranisi degistirmedik.

## Boyle yaptik

Helper'i iki ayri rolden uzak tuttuk:

- Constructor validation kapisi.
- Otomatik veri duzeltme araci.

Onun yerine helper'i saf diagnostic fonksiyon olarak tanimladik.

Yani helper bilgi uretir; cagiran katman bu bilgiyle ne yapacagina karar verir.

## Cunku

Diagnostic sonuc ile veri reddetme karari ayni sey degildir.

Bir ID legacy prefix kullaniyorsa bu kalite kontrol raporunda `warning` olabilir. Ama bu, kaydin olusturulmasini engellemek icin yeterli sebep degildir.

Bir helper `error` donduruyorsa bu da otomatik silme veya migration anlamina gelmez. Sadece helper bu girdiyle saglikli diagnostic uretmemistir.

Bu ayrim korunmazsa helper yanlislikla hard validation kapisina donusebilir.

## Boylece

CSE record ID kalitesini gorunur hale getirir ama mevcut veri davranisini kirmadan ilerler.

Gelecekte bu helper su yerlerde kullanilabilir:

- Handover on kontrol raporlari.
- Audit kalite kontrol raporlari.
- Migration oncesi envanter taramalari.
- Admin/debug diagnostic ciktilari.
- Test example standardization kontrolleri.

Ama su yerlerde kullanilmamalidir:

- `AuditEventRecord.__post_init__` icinde.
- Constructor validation katmani olarak.
- Legacy ID reddetmek icin.
- `FileAttachmentRecord` davranisini degistirmek icin.
- Otomatik migration veya data correction yapmak icin.

## Ana ders

Guvenilir veri omurgasi icin once gorunurluk kurulur.

Sonra raporlama ve test ornekleri standartlasir.

Hard validation en sona birakilir.

Bu siralama, hem veri kalitesini artirir hem de mevcut anlamli legacy kayitlari korur.
