# Adim 147 - Diagnostic / Soft Validation Format Helper Plan

Bu adimda mevcut diagnostic report ve soft validation report ciktilarinin ileride okunabilir sunum formatlarina nasil donusturulecegi planlandi.

Bu adim documentation-only adimidir.

Kod veya test davranisi degistirilmedi.

Format helper implementasyonu yapilmadi.

## Neden format helper gerekli?

`build_record_id_diagnostic_report(records)` ve `build_record_id_soft_validation_report(diagnostic_report)` su anda veri ve yorum katmanidir.

Bu ciktilar gelistirici, kullanici veya handover raporu icin dogrudan okunabilir olmayabilir.

Bu nedenle ayri bir format layer gerekir.

Format layer:

- Mevcut report dict alir.
- Report icindeki bilgiyi okunabilir/sunulabilir hale getirir.
- Diagnostic sonucu yeniden hesaplamaz.
- Soft validation status degerini yeniden hesaplamaz.
- Veri uretim davranisini degistirmez.
- Kayit reddetmez.
- Hard validation yapmaz.

## Mevcut helperlarin siniri

Mevcut helperlar degistirilmeyecek:

- `build_record_id_diagnostic_report(records)`
- `build_record_id_soft_validation_report(diagnostic_report)`

Format helper planlari bu iki helper'in davranisini genisletmez veya daraltmaz.

Diagnostic report yine record ID uyumluluk gorunurlugu uretir.

Soft validation report yine `pass` / `review` / `attention` yorumunu read-only olarak uretir.

## Olası gelecek helper adlari

Bu adimda asagidaki helperlar yalnizca planlandi.

Implementasyon yapilmadi.

- `format_record_id_diagnostic_report_as_markdown(...)`
- `format_record_id_soft_validation_report_as_markdown(...)`
- `format_record_id_diagnostic_report_as_json_ready_dict(...)`
- `format_record_id_soft_validation_report_as_json_ready_dict(...)`
- `build_handover_record_id_qc_summary(...)`

Bu fonksiyonlar bu adimda eklenmedi.

## Format layer siniri

Format layer diagnostic report dict veya soft validation report dict alabilir.

Format layer okunabilir veya sunulabilir cikti uretir.

Format layer su davranislari yapmayacak:

- Veriyi degistirmez.
- Diagnostic sonucu yeniden hesaplamaz.
- Soft validation status yeniden hesaplamaz.
- Kayit olusturmaz.
- Kayit reddetmez.
- Audit event olusturmaz.
- Database/repository yazmaz.
- Dosya sistemine yazmaz.
- Backup/export/restore islemi yapmaz.
- API/GUI/CLI eklemez.
- Migration veya otomatik duzeltme yapmaz.

Bu sinir, format layer'i sadece sunum katmani olarak tutar.

## Markdown format plani

Markdown ciktisi ileride insan-okur rapor olarak kullanilabilir.

Olası alanlar:

- Baslik.
- Kisa summary.
- `status`.
- `total_count`.
- `compatible_count`.
- `warning_count`.
- `error_count`.
- `review_required`.
- `attention_required`.
- Warning/error item listesi.
- "Bu rapor kayit reddi degildir" notu.
- "Hard validation degildir" notu.

Markdown format helper dosya uretmemelidir.

Markdown string veya okunabilir metin ciktisi uretmesi ileride ayri API boundary ile planlanabilir.

## JSON-ready dict format plani

JSON-ready dict Python dict olarak kalmalidir.

JSON-ready dict:

- Dosyaya yazilmaz.
- `datetime` veya ozel object icermez.
- Makine tarafindan okunabilir olur.
- Mevcut report bilgisini sunum dostu sekilde paketler.
- Export islemini kendisi yapmaz.

JSON dosya uretimi veya disari aktarma ayri bir adimda planlanmalidir.

## Handover QC summary plani

`build_handover_record_id_qc_summary(...)` benzeri bir format helper ileride handover on kontrol gorunurlugu saglayabilir.

Handover QC summary:

- Yeni santiye sefine veri sagligi gorunurlugu saglar.
- Warning ve error kayitlarini gorunur yapar.
- "Gozden gecirilecek kayitlar" mantigiyla calisir.
- Devir paketini otomatik bloke etmez.
- Kayit reddetmez.
- Hard validation tetiklemez.

Bu summary, karar kapisi degil insan-okur kalite kontrol ciktisidir.

## Severity ve status sunum standardi

Diagnostic severity sunumu:

- `info`: normal/canonical uyumlu kayit.
- `warning`: review / gozden gecirme sebebi.
- `error`: attention / manuel inceleme sebebi.

Soft validation status sunumu:

- `pass`: sorun gorunmuyor.
- `review`: warning var.
- `attention`: error var veya input yapisi dikkat istiyor.
- `blocked`: uretilmez ve format layer tarafindan da eklenmez.

Format layer severity veya status anlamlarini degistirmeyecek.

## Kullanilabilecegi alanlar

- Handover on kontrol.
- Audit QC raporu.
- Admin/debug gorunurlugu.
- Export/backup oncesi insan-okur rapor.
- Migration oncesi veri sagligi incelemesi.
- Test example standardization dokumantasyonu.

## Kullanilmayacagi alanlar

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

## Gelecek guvenli sira

1. Adim 147: format helper plan.
2. Adim 148: format helper API boundary / test matrix plan.
3. Adim 149: read-only format helper implementation.
4. Adim 150: handover QC summary usage documentation.
5. Adim 151: Podcast 025 kapsam kontrolu veya Adim 147-151 serisinin tamamlanmasina gore karar.
6. Hard validation en sona birakilir.

## Mutlak kararlar

- `target_record_id` hard validation hala eklenmeyecek.
- `AuditEventRecord.__post_init__` degistirilmeyecek.
- Legacy ID ornekleri korunacak.
- `build_record_id_diagnostic_report(...)` davranisi degistirilmeyecek.
- `build_record_id_soft_validation_report(...)` davranisi degistirilmeyecek.
- `blocked` status uretilmeyecek.
- Format layer read-only/sunum katmani olarak kalacak.
- Podcast 025 bu adimda olusturulmadi.

## Sonuc

Adim 147, diagnostic ve soft validation raporlarinin ileride nasil sunulacagini planladi.

Bu plan, rapor gorunurlugunu arttirirken mevcut helper davranislarini, constructor davranisini ve hard validation ertelemesini korur.

