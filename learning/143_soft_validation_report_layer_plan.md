# Adim 143 - Soft Validation Report Layer Plan

## Sunu yaptik

`build_record_id_diagnostic_report(...)` ciktisinin ileride soft validation report layer icin nasil kullanilabilecegini planladik.

Bu adimda kod yazmadik, soft validation helper eklemedik ve test davranisini degistirmedik.

## Boyle yaptik

Diagnostic ile soft validation report arasindaki farki ayirdik.

Diagnostic:

- Ham bilgi uretir.
- `info`, `warning`, `error` itemlari verir.
- Summary/count bilgisi dondurur.
- Karar vermez.

Soft validation report:

- Diagnostic sonuclari yorumlar.
- Gozden gecirme veya dikkat gerektiren kayitlari gorunur yapar.
- Kayit reddetmez.
- Hard validation degildir.

## Cunku

Bir diagnostic report eklendikten sonra onu validation kapisina cevirmek kolay ama risklidir.

CSE icin daha guvenli sira sudur: once diagnostic bilgi, sonra soft yorum, sonra read-only rapor, en son ve ayrica degerlendirilirse hard validation.

## Kullanilabilecek alanlar

Soft validation report layer su alanlarda kullanilabilir:

- Handover on kontrol.
- Audit QC raporu.
- Export/backup oncesi risk gorunurlugu.
- Admin/debug kalite raporu.
- Migration oncesi veri sagligi incelemesi.
- Test example standardization gozden gecirme.

Bu kullanimlar gorunurluk saglar, otomatik engelleme yapmaz.

## Kullanilmamasi gereken alanlar

Soft validation report su isler icin kullanilmaz:

- `AuditEventRecord.__post_init__` icinde validation yapmak.
- Constructor validation olmak.
- Hard validation yapmak.
- Kayit olusturmayi engellemek.
- Legacy kayitlari reddetmek.
- Otomatik data correction yapmak.
- Migration uygulamak.
- Database/repository yazmak.
- Audit event olusturmak.
- `FileAttachmentRecord` davranisini degistirmek.

## Olası seviye dersleri

Ileride soft validation raporu su seviyeleri kullanabilir:

- `pass`: sadece canonical/info kayitlar var.
- `review`: warning var, gozden gecirme gerekir.
- `attention`: error var, manuel inceleme gerekir.

`blocked` bu asamada kullanilmamalidir.

`blocked` kelimesi engelleme ve hard validation anlami dogurabilir.

## Severity nasil okunur?

`info` normal/canonical uyumlu kayittir.

`warning` legacy veya prefix disi ama reddedilmeyen kayittir. Soft validation icinde review sebebi olabilir, fakat kayit reddi degildir.

`error` helper seviyesinde diagnostic sorunudur. Attention sebebi olabilir, fakat otomatik silme veya duzeltme sebebi degildir.

## Handover dersi

Handover raporunda soft validation eksikleri gorunur yapar.

Yeni santiye sefi warning/error kayitlarini risk notu olarak gorebilir.

Ama rapor devir paketini otomatik bloke etmez ve hard validation tetiklemez.

## Export/backup dersi

Export veya backup oncesinde soft validation raporu veri kalitesi risklerini gosterebilir.

Ama exportu otomatik durdurmaz, backup/restore davranisini degistirmez ve sadece "once gozden gecir" uyarisi saglar.

## Ana ders

Soft validation raporu bir karar mekanizmasi degil, yorumlanmis gorunurluk katmanidir.

Hard validation hala eklenmedi. `AuditEventRecord.__post_init__` degismedi. `build_record_id_diagnostic_report(...)` davranisi degismedi. Legacy ID ornekleri korunur.

Podcast 023 bu adimda olusturulmadi.
