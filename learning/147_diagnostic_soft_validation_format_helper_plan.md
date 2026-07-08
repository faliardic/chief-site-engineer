# Adim 147 - Diagnostic / Soft Validation Format Helper Plan

Bu adimda kod yazmadik.

Amacimiz, diagnostic report ve soft validation report ciktilarinin ileride Markdown, JSON-ready dict ve handover QC summary gibi formatlara nasil cevrilecegini planlamakti.

## Ana fikir

Diagnostic ve soft validation helperlari veri/yorum katmanidir.

Format helper ise sunum katmani olmalidir.

Format helper:

- Mevcut report dict alir.
- Okunabilir cikti uretir.
- Diagnostic sonucu yeniden hesaplamaz.
- Soft validation status yeniden hesaplamaz.
- Veri degistirmez.
- Kayit reddetmez.
- Hard validation yapmaz.

## Mevcut helperlar degismedi

Su helperlarin davranisi degismedi:

- `build_record_id_diagnostic_report(records)`
- `build_record_id_soft_validation_report(diagnostic_report)`

Bu adimda yeni helper implementasyonu yapilmadi.

## Planlanan gelecek helperlar

Ileride su helperlar planlanabilir:

- `format_record_id_diagnostic_report_as_markdown(...)`
- `format_record_id_soft_validation_report_as_markdown(...)`
- `format_record_id_diagnostic_report_as_json_ready_dict(...)`
- `format_record_id_soft_validation_report_as_json_ready_dict(...)`
- `build_handover_record_id_qc_summary(...)`

Bu adimda bunlar eklenmedi.

## Markdown dersi

Markdown format insan-okur rapor icin dusunuluyor.

Baslik, summary, status, count alanlari, warning/error item listesi ve "Bu rapor kayit reddi degildir" notu icerebilir.

Markdown format dosya yazimi yapmamalidir.

## JSON-ready dict dersi

JSON-ready dict Python dict olarak kalmalidir.

Dosyaya yazma, export etme veya backup/restore islemi yapma bu helper'in isi olmamalidir.

## Handover QC dersi

Handover QC summary yeni santiye sefine veri sagligi gorunurlugu verebilir.

Warning/error kayitlarini gosterir.

Ama devir paketini otomatik bloke etmez.

Kayit reddetmez.

Hard validation tetiklemez.

## Severity ve status dersi

`info`, normal/canonical uyumlu kayittir.

`warning`, review/gozden gecirme sebebidir.

`error`, attention/manuel inceleme sebebidir.

`pass`, sorun gorunmedigini anlatir.

`review`, warning oldugunu anlatir.

`attention`, error veya input dikkat gerektiren durum oldugunu anlatir.

`blocked` uretilmez ve format layer tarafindan da eklenmez.

## Kullanilmamasi gereken yerler

- `AuditEventRecord.__post_init__`.
- Constructor validation.
- Hard validation.
- Kayit olusturmayi engelleme.
- Legacy kayitlari reddetme.
- Otomatik data correction.
- Migration uygulama adimi.
- Database/repository yazimi.
- Audit event olusturma.
- `FileAttachmentRecord` davranisini degistirme.
- API/GUI/CLI entegrasyonu.

## Degismeyen kararlar

- Hard validation eklenmedi.
- `AuditEventRecord.__post_init__` degismedi.
- `build_record_id_diagnostic_report(...)` davranisi degismedi.
- `build_record_id_soft_validation_report(...)` davranisi degismedi.
- `blocked` status eklenmedi.
- Format helper implementasyonu yapilmadi.
- Podcast 025 olusturulmadi.

## Kapanis

Adim 147, format layer'in veri ureten veya karar veren katman degil, sadece sunum katmani olacagini netlestirdi.

Bu ayrim CSE record ID hattinda gorunurluk saglarken hard validation'a erken gecisi engeller.

