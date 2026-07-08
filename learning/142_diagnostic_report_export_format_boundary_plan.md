# Adim 142 - Diagnostic Report Export / Format Boundary Plan

## Sunu yaptik

`build_record_id_diagnostic_report(...)` ciktisinin ileride hangi formatlarda sunulabilecegini planladik.

Bu adimda kod yazmadik, export helper eklemedik ve dosya uretmedik.

## Boyle yaptik

Diagnostic helper ile format/export katmanini ayirdik.

Diagnostic helper:

- Veri uretir.
- Diagnostic report dict dondurur.
- Kayit reddetmez.
- Veri degistirmez.

Format layer:

- Diagnostic report dict alir.
- Sunum ciktisi uretir.
- Diagnostic sonucu yeniden hesaplamaz.
- Dosya sistemine yazmaz.

Export layer ise daha riskli ayri bir katmandir ve bu adimda baslatilmadi.

## Cunku

Bir rapor helper'i eklendikten sonra ilk cazibe, onu hemen JSON dosyasina, Markdown raporuna veya UI/API ciktisina baglamaktir.

Bu hizli gecis risklidir. Formatlama, export ve entegrasyon ayni sey degildir.

Bu nedenle once siniri cizdik.

## Olası formatlar

JSON-ready dict:

- Makine tarafindan okunabilir.
- API/admin/debug veya ileride export oncesi kullanilabilir.
- Python dict olarak kalir.
- Dosyaya yazma isi ayri adimdir.

Markdown summary:

- Insan tarafindan okunabilir.
- Handover, QC notu veya proje raporu icin kullanilabilir.
- Tablo veya kisa ozet olabilir.

Handover QC summary:

- Devir teslim oncesi warning/error gorunurlugu saglar.
- Kayit reddetmez.
- Uyarilari "gozden gecirilecek kayit" olarak gosterir.

Admin/debug view:

- Gelistirici veya yoneticiye diagnostic gorunurluk saglar.
- Kullaniciya otomatik karar dayatmaz.

## Bu adimda yapilmayanlar

Bu adimda sunlar yapilmadi:

- `format_record_id_diagnostic_report_as_markdown(...)` eklenmedi.
- `format_record_id_diagnostic_report_as_json_ready_dict(...)` eklenmedi.
- `build_handover_record_id_qc_summary(...)` eklenmedi.
- JSON dosya exportu yapilmadi.
- Markdown dosyasi exportu yapilmadi.
- Backup/export servisi yazilmadi.
- CLI/API/GUI eklenmedi.

## Severity nasil sunulmali?

Severity anlamlari format layer tarafindan degistirilmemelidir.

- `info`: normal/canonical uyumlu kayit.
- `warning`: legacy veya prefix disi ama reddedilmeyen kayit.
- `error`: helper seviyesinde diagnostic sorunu.

`warning` veri reddi degildir.

`error` otomatik silme veya duzeltme sebebi degildir.

## Handover QC dersi

Handover QC raporu `total_count`, `warning_count`, `error_count` ve gerekirse warning/error itemlarini gosterebilir.

Ama bu rapor devri otomatik engellemez.

Raporun isi karar vermek degil, gozden gecirilecek kayitlari gorunur yapmaktir.

## Guvenli sira

Ilerleme sirasi soyle kalmalidir:

- Once format helper planı.
- Sonra format helper implementation.
- Sonra dosya export boundary planı.
- Sonra read-only export helper.
- Sonra export testleri.
- En son UI/API entegrasyonu.

Bu sira hard validation veya otomatik veri degisikligi baslatmaz.

## Ana ders

Diagnostic helper veri uretir. Format layer sunum uretir. Export layer dosya veya dis yuzey riskini tasir.

Bu uc katmani ayri tutmak CSE icin guvenli ilerleme saglar.

Hard validation hala eklenmedi. `AuditEventRecord.__post_init__` degismedi. `build_record_id_diagnostic_report(...)` davranisi degismedi. Legacy ID ornekleri korunur.
