# Adim 148 - Diagnostic / Soft Validation Format Helper API Boundary and Test Matrix Plan

Bu adimda kod yazmadik.

Amacimiz, Adim 147'de planlanan format helper katmaninin API sinirini ve test matrisini netlestirmekti.

## Ana fikir

Format helper veri uretmez.

Format helper karar vermez.

Format helper mevcut diagnostic report veya soft validation report dict'ini okunabilir bir sunuma donusturur.

## Planlanan helper adlari

Ileride su helperlar dusunulebilir:

- `format_record_id_diagnostic_report_as_markdown(...)`
- `format_record_id_soft_validation_report_as_markdown(...)`
- `format_record_id_diagnostic_report_as_json_ready_dict(...)`
- `format_record_id_soft_validation_report_as_json_ready_dict(...)`
- `build_handover_record_id_qc_summary(...)`

Bu adimda bu helperlar eklenmedi.

## API boundary dersi

Format helper:

- Diagnostic report dict veya soft validation report dict alabilir.
- Mevcut report dict'ini sunum formatina cevirir.
- Diagnostic sonucu yeniden hesaplamaz.
- Soft validation status yeniden hesaplamaz.
- Kayit reddetmez.
- Veri degistirmez.
- Input mutate etmez.
- `blocked` status uretmez.
- Hard validation yapmaz.
- Dosya, database, repository, API, GUI veya CLI islemi yapmaz.

## Output dersi

Markdown output string olabilir.

JSON-ready output dict olmalidir.

Handover QC summary read-only summary dict veya Markdown string olabilir.

Bu outputlar dosya yazmaz.

Bu outputlar export islemi yapmaz.

## Handover QC dersi

Handover QC summary yeni santiye sefine veri sagligi gorunurlugu saglar.

`review_required` ve `attention_required` alanlari insan incelemesi icindir.

Devir paketini otomatik bloke etmez.

Kayit reddetmez.

Hard validation tetiklemez.

`blocked` status uretmez.

## Test matrix dersi

Markdown formatter icin:

- `pass`, `review`, `attention` raporlarinin okunabilir cikti uretmesi.
- Warning/error itemlarinin gorunmesi.
- Hard validation degildir notunun bulunmasi.
- `blocked` status uretilmemesi.

JSON-ready formatter icin:

- Output dict olmasi.
- Input mutate etmemesi.
- Item count korunumu.
- Items listesi korunumu.
- Serialize edilemeyen object eklenmemesi.
- Diagnostic veya soft validation sonucunun yeniden hesaplanmamasi.

Handover QC summary icin:

- `pass` durumunda review/attention gerekmemesi.
- `review` durumunda review sinyalinin gorunmesi.
- `attention` durumunda attention sinyalinin gorunmesi.
- Warning/error item listelerinin korunmasi.
- Devir paketini otomatik bloke etmemesi.
- `blocked` status uretmemesi.

Unsupported input icin okunur hata ciktisi planlanabilir; bu kayit reddi degildir.

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
- JSON/Markdown dosya uretimi eklenmedi.
- Podcast 025 olusturulmadi.

## Kapanis

Adim 148, format helper implementasyonu oncesinde neyin test edilecegini ve neyin API sinirinin disinda kalacagini netlestirdi.

Bu ayrim, CSE record ID raporlama hattini okunabilir hale getirirken hard validation, veri degisikligi ve otomatik bloklama davranislarini disarida tutar.

