# Adim 142 - Diagnostic Report Export / Format Boundary Plan

## Amac

Bu adimda `build_record_id_diagnostic_report(...)` ciktisinin ileride JSON-ready dict, Markdown summary, handover QC summary ve admin/debug gorunumlerine nasil donusturulebilecegi planlandi.

Bu adim documentation-only adimidir. Export helper veya format helper implementasyonu yapilmadi.

## Neden export/format boundary gerekiyor?

Diagnostic report ciktisi ileride farkli yuzeylerde kullanilabilir.

Ayni diagnostic veri:

- JSON-ready dict olarak makine tarafindan okunabilir.
- Markdown summary olarak insan tarafindan okunabilir.
- Handover QC summary olarak devir teslim oncesi risk gorunurlugu saglayabilir.
- Admin/debug gorunumu olarak gelistirici veya yoneticiye diagnostic bilgi verebilir.

Bu nedenle formatlama katmani diagnostic helper'dan ayri kalmalidir.

`build_record_id_diagnostic_report(...)` diagnostic veri uretir. Export/format katmani sunum uretir.

## Mevcut helper siniri

`build_record_id_diagnostic_report(records)` helper'i:

- Read-only diagnostic report dict dondurur.
- Dosya uretmez.
- Export yapmaz.
- Database/repository yazmaz.
- Audit event olusturmaz.
- Backup/restore islemi yapmaz.
- Kayit reddetmez.
- Veri degistirmez.

Bu sinir korunacaktir.

## Olası ilerideki format helperlari

Asagidaki helper adlari ileride degerlendirilebilir:

- `format_record_id_diagnostic_report_as_markdown(...)`
- `format_record_id_diagnostic_report_as_json_ready_dict(...)`
- `build_handover_record_id_qc_summary(...)`

Bu adimda bu fonksiyonlar eklenmedi.

Bu adim yalnizca format/export sinirini planlar.

## Olası cikti formatlari

### JSON-ready dict

JSON-ready dict makine tarafindan okunabilir bir sunum katmani olabilir.

Kullanim alanlari:

- API/admin/debug gorunurlugu.
- Ileride export oncesi ara format.
- Test edilebilir ve sade rapor ciktisi.

Bu katman Python dict olarak kalmalidir. Dosyaya yazma isi ayri helper ve ayri adim olmalidir.

### Markdown summary

Markdown summary insan tarafindan okunabilir rapor ciktisi olabilir.

Kullanim alanlari:

- Handover notu.
- QC raporu.
- Proje durum ozeti.

Markdown ciktisi tablo veya kisa ozet formatinda olabilir. Bu ciktinin amaci karar vermek degil, diagnostic gorunurluk saglamaktir.

### Handover QC summary

Handover QC summary devir teslim oncesi risk gorunurlugu saglar.

Bu format:

- `total_count` degerini gosterebilir.
- `warning_count` degerini gosterebilir.
- `error_count` degerini gosterebilir.
- Warning/error itemlarini listeleyebilir.

Warning/error itemlari devir teslimi otomatik engellemez. "Gozden gecirilecek kayit" olarak yorumlanir.

### Admin/debug view

Admin/debug view gelistirici veya yonetici icin diagnostic gorunurluk saglar.

Bu gorunum:

- Diagnostic itemlari incelemeyi kolaylastirabilir.
- Summary/count alanlarini daha okunur hale getirebilir.
- Kullaniciya otomatik karar dayatmaz.

## Format layer siniri

Format layer:

- Diagnostic report dict alir.
- Sunum/format ciktisi uretir.
- Veriyi degistirmez.
- Diagnostic sonucu yeniden hesaplamaz.
- Kayit olusturmaz.
- Audit event uretmez.
- Database/repository yazmaz.
- Dosya sistemine yazmaz.
- Backup/export/restore islemini dogrudan yapmaz.

Format layer, `build_record_id_diagnostic_report(...)` ciktisini yorumlar ve sunar.

## Export boundary

Export ayri bir risk katmanidir.

Bu adimda:

- JSON dosya exportu yapilmayacak.
- Markdown dosyasi exportu yapilmayacak.
- Backup/export servisi yazilmayacak.
- CLI/API/GUI eklenmeyecek.

Ileride export yapilacaksa guvenli sira soyle olmalidir:

- Once format helper planı.
- Sonra format helper implementation.
- Sonra dosya export boundary planı.
- Sonra read-only export helper.
- Sonra export testleri.
- En son UI/API entegrasyonu.

## Severity sunum standardi

Format layer severity anlamlarini degistirmemelidir:

- `info`: normal/canonical uyumlu kayit.
- `warning`: legacy veya prefix disi ama reddedilmeyen kayit.
- `error`: helper seviyesinde diagnostic sorunu.

`warning` veri reddi degildir.

`error` otomatik silme veya duzeltme sebebi degildir.

## Handover QC yorumlama standardi

Handover raporunda su alanlar gorunur olabilir:

- `total_count`
- `warning_count`
- `error_count`
- warning/error item listesi

Uyarilar "devre engel" degil, "gozden gecirilecek kayit" olarak yorumlanmalidir.

Handover QC formatlama hard validation tetiklemez.

## Mutlak kararlar

- `target_record_id` hard validation hala eklenmeyecek.
- `AuditEventRecord.__post_init__` degistirilmeyecek.
- Legacy ID ornekleri korunacak.
- `build_record_id_diagnostic_report(...)` davranisi degistirilmeyecek.
- Export/format helper bu adimda implement edilmeyecek.
- `FileAttachmentRecord` davranisina dokunulmayacak.
- Podcast 023 bu adimda olusturulmadi.

## Sonuc

Adim 142, diagnostic report ciktisinin ileride nasil sunulabilecegini planladi ve format/export katmaninin sinirini diagnostic helper'dan ayirdi.

Bu adim veri reddi, veri degisikligi, dosya exportu, API/CLI/GUI entegrasyonu, migration veya hard validation baslatmaz.
