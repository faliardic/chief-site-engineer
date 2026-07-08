# Adim 152 - Export Helper API Boundary and File Writing Safety Plan

Bu adimda Adim 151'de belgelenen export / file writing boundary'den sonra olasi JSON / Markdown export helper'lari icin API boundary, path safety, overwrite policy ve test matrix plani hazirlandi.

Bu adim documentation-only adimidir.

Kod veya test davranisi degistirilmedi.

Export helper implementasyonu yapilmadi.

JSON veya Markdown dosyasi uretilmedi.

Podcast 026 bu adimda olusturulmadi.

## Export helper neden ayri katman?

Format helper'lar yalniz Python dict veya Markdown string dondurur.

Export helper ise kalici dosya ciktisi uretir.

Dosya yazimi:

- Output path riski tasir.
- Path traversal riski tasir.
- Overwrite riski tasir.
- Encoding karari ister.
- Proje koku veya izinli export klasoru siniri ister.
- Backup / restore veya handover package davranisiyla karisabilir.

Bu nedenle export helper, format helper'dan ayri planlanmalidir.

## Olasi export helper adlari

Asagidaki helper adlari yalnizca gelecek adimlar icin planlandi.

Bu adimda implementasyon yapilmadi:

- `write_record_id_diagnostic_report_json(...)`
- `write_record_id_soft_validation_report_json(...)`
- `write_record_id_diagnostic_report_markdown(...)`
- `write_record_id_soft_validation_report_markdown(...)`
- `write_handover_qc_summary_markdown(...)`

Bu fonksiyonlar bu adimda eklenmeyecek.

## API boundary

Ileride export helper eklenirse yalniz onceden uretilmis sunum ciktisini almalidir:

- JSON export helper input olarak JSON-ready Python dict alir.
- Markdown export helper input olarak Markdown string alir.

Export helper:

- Diagnostic report veya soft validation report'u yeniden hesaplamamalidir.
- Format helper davranisini degistirmemelidir.
- Kayit reddetmemelidir.
- Hard validation yapmamalidir.
- `blocked` status uretmemelidir.
- Database veya repository yazmamalidir.
- Audit event olusturmamalidir.
- Backup / restore motoru gibi davranmamalidir.
- API / GUI / CLI entegrasyonu eklememelidir.

Export helper karar kapisi degildir.

Export helper veri kalitesi sonucu uretmez; yalniz verilen hazir ciktinin guvenli dosya yazimi sorumlulugunu tasir.

## Input sozlesmesi

JSON export helper icin planlanan sozlesme:

- Input: JSON-ready Python dict.
- Output path: Acikca verilen guvenli path.
- Output: Yazilan dosya yolu veya write result dict olabilir.

Markdown export helper icin planlanan sozlesme:

- Input: Markdown string.
- Output path: Acikca verilen guvenli path.
- Output: Yazilan dosya yolu veya write result dict olabilir.

Bu adimda implementation yoktur.

## Path safety plani

Ileride dosya yazimi yapilirse path safety once test edilebilir sekilde planlanmalidir.

Planlanan prensipler:

- Output path acikca verilmelidir.
- Path traversal engellenmelidir.
- Proje koku veya izinli export klasoru disina yazma engellenmelidir.
- Absolute path davranisi ayrica test edilmelidir.
- Relative path davranisi ayrica test edilmelidir.
- Parent directory yoksa ne yapilacagi planlanmalidir.
- Dosya adi okunur ve deterministik olmalidir.
- Windows path karakterleri dikkate alinmalidir.
- ZIP / yedek dosyalar export kapsamina alinmamalidir.

Path safety olmadan dosya yazimi helper'i eklenmemelidir.

## Overwrite policy plani

Ileride overwrite davranisi acik olmalidir.

Onerilen guvenli varsayilan:

- Varsayilan olarak mevcut dosya overwrite edilmemelidir.
- `overwrite=False` default olmalidir.
- Overwrite gerekiyorsa explicit parametre ile yapilmalidir.
- `overwrite=True` davranisi ayri test edilmelidir.
- Yanlislikla mevcut export veya handover dosyasi ezilmemelidir.

Overwrite davranisi sessiz veya belirsiz olmamalidir.

## Encoding ve format plani

Dosya yazimi eklenirse:

- Markdown icin UTF-8 kullanilmalidir.
- JSON icin UTF-8 kullanilmalidir.
- JSON icin deterministic indentation dusunulmelidir.
- JSON ciktisi serialize edilebilir primitive / list / dict degerler icermelidir.
- Markdown ciktisi insan-okur olmalidir.
- Dosya yazimi format helper'dan gelen icerigi degistirmemelidir.

Export helper formatting helper degildir.

Export helper icerigi yeniden uretmez; verilen ciktinin dosyaya yazilmasini planlar.

## Handover package boundary

Handover export ileride explicit handover icerigi uretebilir.

Uygun kapsam:

- Yeni santiye sefine veri sagligi gorunurlugu saglamak.
- Warning/error veya review/attention kayitlarini gorunur yapmak.
- Handover on kontrol ciktisi uretmek.
- Explicit handover icerigini dosya ciktilarina tasimak.

Uygun olmayan kapsam:

- Eski santiye sefinin ozel alanini devretmek.
- Devir paketini otomatik bloke etmek.
- Kayit reddetmek.
- Hard validation tetiklemek.
- Backup / restore motoru olmak.
- Database veya repository yazmak.
- Audit event olusturmak.

Handover export kalite sinyali tasiyabilir; karar ve aksiyon insan incelemesine birakilir.

## Test matrix plani

Ileride export helper implementasyonundan once test matrix en az su kategorileri kapsamalidir:

- JSON export path safety.
- Markdown export path safety.
- Relative path davranisi.
- Absolute path davranisi.
- Path traversal reddi.
- Izinli export klasoru disina cikmama.
- Mevcut dosya `overwrite=False` ile korunur.
- `overwrite=True` explicit davranir.
- Parent directory davranisi.
- UTF-8 encoding.
- JSON serialize edilebilirlik.
- Markdown icerigi aynen yazilir.
- Input mutate edilmez.
- Format helper yeniden hesaplanmaz.
- Hard validation tetiklenmez.
- `blocked` status uretilmez.
- ZIP / yedek dosyalar stage veya export kapsamina alinmaz.

Bu test matrix dosya yazimi implementasyonu baslamadan once netlestirilmelidir.

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

1. Adim 152: export helper API boundary / file writing safety plan.
2. Adim 153: path safety / overwrite policy detailed documentation.
3. Adim 154: export helper test matrix finalization.
4. Adim 155: read-only file writing helper implementation.
5. Adim 156: export helper usage documentation.
6. Podcast 026: Adim 152-156 tamamlandiktan sonra.
7. Hard validation en sona birakilir.

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

Adim 152, export helper eklenmeden once API boundary, path safety, overwrite policy, encoding ve test matrix beklentilerini belirledi.

Bu sinir, format helper ciktilarini kalici dosya ciktisina donusturme fikrini kontrollu ve test edilebilir bir sonraki hatta tasir.

