# Adim 138 - Record ID Diagnostic Report Helper Plan

## Sunu yaptik

Tekil `diagnose_record_id_for_target_type(...)` helper'inin ileride toplu diagnostic rapora nasil donusebilecegini planladik.

Bu adimda kod yazmadik. Test yazmadik. Diagnostic report helper implementasyonu yapmadik.

## Boyle yaptik

Olası helper adini planladik:

```python
build_record_id_diagnostic_report(...)
```

Bu helper ileride bir input listesini okuyabilir, her item icin tekil diagnostic sonuc uretebilir ve toplu ozet dondurebilir.

Olası rapor alanlari:

- `total_count`
- `compatible_count`
- `warning_count`
- `error_count`
- `items`
- `summary`

Her item, tekil diagnostic helper cikti alanlarini tasiyabilir.

## Cunku

Tekil diagnostic helper bir kaydi yorumlar.

Ama handover on kontrol, audit QC veya migration oncesi envanter gibi islerde birden fazla kaydin birlikte gorulmesi gerekir.

Toplu rapor helper'i bu gorunurlugu saglayabilir.

## Read-only neden onemli?

Diagnostic rapor, kalite sinyali uretir. Veri degistirmez.

Bu nedenle helper:

- Kayit reddetmez.
- Migration yapmaz.
- Otomatik duzeltme yapmaz.
- Dosya sistemiyle islem yapmaz.
- Database veya repository yazmaz.
- Audit event olusturmaz.

Bu sinir korunursa diagnostic report helper guvenli bir gorunurluk araci olarak kalir.

## Severity nasil okunmali?

`info`, canonical uyumlu kayitlari gosterir.

`warning`, legacy veya prefix disi ama reddedilmeyen kayitlari gosterir.

`error`, helper'in anlamli diagnostic uretemedigi girdileri gosterir.

`warning` veri reddi degildir. `error` otomatik silme veya duzeltme sebebi degildir.

## Ana ders

Toplu rapor, hard validation'a gecmek icin kisa yol degildir.

Once gorunurluk artar. Sonra test ornekleri standardize edilir. Sonra soft validation raporlari olgunlasir.

Hard validation en sona birakilir.

Bu sira CSE'nin legacy ID orneklerini ve mevcut audit constructor davranisini korur.
