# Adim 151 - Export File Writing Boundary Plan

Bu adimda Adim 149'da eklenen JSON-ready dict ve Markdown string formatter helper'larindan sonra olasi export / file writing katmani icin guvenli sinir belgelendi.

Bu adim documentation-only adimidir.

Kod veya test davranisi degistirilmedi.

Export / file writing helper implementasyonu yapilmadi.

JSON veya Markdown dosyasi uretilmedi.

Podcast 025 bu adimda olusturulmadi.

## Neden export / file writing boundary gerekiyor?

Format helper'lar su anda yalniz Python dict veya Markdown string dondurur.

Dosya yazimi ise kalici cikti uretir.

Kalici cikti:

- Yanlis dizine yazilabilir.
- Var olan dosyayi ezebilir.
- Export, backup, restore veya handover package davranisiyla karistirilabilir.
- Path traversal ve encoding gibi ek riskler tasir.

Bu nedenle JSON-ready dict / Markdown string formatlama katmani ile dosya yazan export katmani ayrilmalidir.

## Mevcut helper siniri

Asagidaki helperlarin davranisi degistirilmeyecek:

- `build_record_id_diagnostic_report(...)`
- `build_record_id_soft_validation_report(...)`
- `format_record_id_diagnostic_report_as_json_ready_dict(...)`
- `format_record_id_soft_validation_report_as_json_ready_dict(...)`
- `format_record_id_diagnostic_report_as_markdown(...)`
- `format_record_id_soft_validation_report_as_markdown(...)`

Bu helperlar:

- Dosya uretmez.
- Export yapmaz.
- Backup / restore yapmaz.
- Database veya repository yazmaz.
- Audit event olusturmaz.
- Diagnostic sonucu yeniden hesaplamaz.
- Soft validation status yeniden hesaplamaz.
- Veri degistirmez.
- Kayit reddetmez.
- Hard validation yapmaz.
- `blocked` status uretmez.

## Olasi export / file writing helper adlari

Asagidaki helper adlari yalnizca gelecek adimlar icin planlandi.

Bu adimda implementasyon yapilmadi:

- `write_record_id_diagnostic_report_json(...)`
- `write_record_id_soft_validation_report_json(...)`
- `write_record_id_diagnostic_report_markdown(...)`
- `write_record_id_soft_validation_report_markdown(...)`
- `build_handover_qc_export_package(...)`

Bu fonksiyonlar bu adimda eklenmeyecek.

## Export / file writing layer siniri

Ileride export helper eklenirse yalniz onceden uretilmis sunum ciktisini almalidir:

- JSON icin JSON-ready dict.
- Markdown icin Markdown string.

Export helper:

- Diagnostic sonucu yeniden hesaplamamalidir.
- Soft validation status yeniden hesaplamamalidir.
- Kayit reddetmemelidir.
- Veri degistirmemelidir.
- Database veya repository yazmamalidir.
- Audit event olusturmamalidir.
- Backup / restore davranisi ustlenmemelidir.
- Hard validation tetiklememelidir.
- `blocked` status uretmemelidir.

Export helper karar kapisi degildir.

Export helper veri kalitesi sonucu uretmez; yalniz verilen ciktiyi dosyaya yazma sorumlulugunu tasir.

## Dosya yazimi icin guvenli prensipler

Ileride dosya yazimi planlanirsa su prensipler once belgelenmelidir:

- Output path acikca verilmelidir.
- Varsayilan olarak proje disina yazmamalidir.
- Path traversal riskine karsi sinirlandirilmalidir.
- Mevcut dosya overwrite davranisi ayri planlanmalidir.
- Dosya adi deterministik ve okunur olmalidir.
- Encoding UTF-8 olmalidir.
- JSON ciktisi serialize edilebilir primitive / list / dict degerler icermelidir.
- Markdown ciktisi insan-okur olmalidir.
- Export edilen dosyalar audit veya backup sistemiyle karistirilmamalidir.

Dosya yazimi basit gorunse bile repo, handover ve backup akislariyla temas ettigi icin ayri guvenlik kapisi ister.

## Handover package siniri

Handover package ileride veri sagligi gorunurlugu saglayabilir.

Uygun kapsam:

- Yeni santiye sefine record ID sagligi hakkinda okunabilir ozet vermek.
- Warning/error veya review/attention kayitlarini gorunur yapmak.
- "Gozden gecirilecek kayitlar" listesini handover notuna tasimak.
- Explicit handover icerigi uretmek.

Uygun olmayan kapsam:

- Devir paketini otomatik bloke etmek.
- Kayit reddetmek.
- Hard validation tetiklemek.
- Eski santiye sefinin ozel alanini devretmek.
- Backup / restore motoru gibi davranmak.
- Database veya repository yazmak.
- Audit event olusturmak.

Handover package kalite sinyali tasiyabilir; karar ve aksiyon insan incelemesine birakilir.

## Kullanilabilecegi alanlar

- Handover on kontrol ciktisi.
- Audit QC raporu exportu.
- Admin/debug raporu.
- Migration oncesi veri sagligi raporu.
- Export / backup oncesi insan-okur kalite raporu.

Bu kullanimlar raporlama ve gorunurluk amaclidir.

Kayit davranisini degistirmez.

## Kullanilmayacagi alanlar

- `AuditEventRecord.__post_init__`.
- Constructor validation.
- Hard validation.
- Kayit olusturmayi engelleme.
- Legacy kayitlari reddetme.
- Otomatik data correction.
- Migration uygulama adimi.
- Database / repository yazimi.
- Audit event olusturma.
- `FileAttachmentRecord` davranisini degistirme.
- API / GUI / CLI entegrasyonu.
- Backup / restore motoru.

## Gelecek guvenli sira

1. Adim 151: export / file writing boundary plan.
2. Podcast 025: Adim 147-151 NotebookLM podcast notu.
3. Adim 152: export helper API boundary / test matrix plan.
4. Adim 153: read-only file writing helper implementation plan veya implementation oncesi path safety plan.
5. Adim 154: path safety / overwrite policy documentation.
6. Hard validation en sona birakilir.

## Mutlak kararlar

- `target_record_id` hard validation hala eklenmeyecek.
- `AuditEventRecord.__post_init__` degistirilmeyecek.
- Legacy ID ornekleri korunacak.
- `build_record_id_diagnostic_report(...)` davranisi degistirilmeyecek.
- `build_record_id_soft_validation_report(...)` davranisi degistirilmeyecek.
- Format helper davranislari degistirilmeyecek.
- `blocked` status uretilmeyecek.
- Export / file writing bu adimda implement edilmeyecek.

## Sonuc

Adim 151, format helper ciktilarindan dosya yazan export katmanina gecmeden once guvenli siniri belirledi.

Bu sinir formatlama, export, handover package, backup / restore ve hard validation davranislarini birbirinden ayri tutar.
