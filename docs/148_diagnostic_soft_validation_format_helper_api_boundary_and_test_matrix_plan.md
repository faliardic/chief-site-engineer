# Adim 148 - Diagnostic / Soft Validation Format Helper API Boundary and Test Matrix Plan

Bu adimda Adim 147'de planlanan diagnostic / soft validation format layer icin API boundary, input/output sozlesmesi ve test matrix planlandi.

Bu adim documentation-only adimidir.

Kod veya test davranisi degistirilmedi.

Format helper implementasyonu yapilmadi.

## Olası helper adlari

Bu adimda asagidaki helperlar yalnizca planlandi.

Implementasyon yapilmadi.

- `format_record_id_diagnostic_report_as_markdown(...)`
- `format_record_id_soft_validation_report_as_markdown(...)`
- `format_record_id_diagnostic_report_as_json_ready_dict(...)`
- `format_record_id_soft_validation_report_as_json_ready_dict(...)`
- `build_handover_record_id_qc_summary(...)`

Bu fonksiyonlar bu adimda eklenmedi.

## API boundary

Format helper ileride diagnostic report dict veya soft validation report dict alabilir.

Format helper mevcut report dict'ini sunum formatina donusturur.

Format helper su davranislari yapmayacak:

- Diagnostic sonucu yeniden hesaplamaz.
- Soft validation status yeniden hesaplamaz.
- Kayit reddetmez.
- Veri degistirmez.
- Input mutate etmez.
- `blocked` status uretmez.
- Hard validation yapmaz.
- Database/repository yazmaz.
- Audit event olusturmaz.
- Dosya sistemi, backup, restore veya export uretmez.
- API/GUI/CLI eklemez.

Bu sinir, format layer'i read-only sunum katmani olarak tutar.

## Input sozlesmesi plani

### Diagnostic Markdown formatter

Input:

```text
build_record_id_diagnostic_report(records)
```

Bu input diagnostic report dict olmalidir.

Formatter diagnostic itemlari, summary/count alanlarini ve severity bilgisini yalnizca sunuma tasir.

### Soft validation Markdown formatter

Input:

```text
build_record_id_soft_validation_report(diagnostic_report)
```

Bu input soft validation report dict olmalidir.

Formatter `status`, `review_required`, `attention_required`, `messages`, count alanlari ve itemlari okunabilir hale getirir.

### JSON-ready dict formatter

Input:

- Diagnostic report dict.
- Soft validation report dict.

Output yine Python dict olmalidir.

Formatter dosyaya yazmaz.

Formatter export islemi yapmaz.

### Handover QC summary

Input:

- Tercihen soft validation report dict.
- Gerekirse diagnostic report dict.

Output read-only summary dict veya Markdown string olabilir.

Bu karar implementasyon oncesi API boundary adiminda tekrar netlestirilebilir.

## Output sozlesmesi plani

### Markdown output

Markdown output string dondurur.

Markdown output dosya yazmaz.

Olası alanlar:

- Baslik.
- Rapor turu.
- Status.
- Summary.
- Count alanlari.
- Warning itemlari.
- Error/attention itemlari.
- "Bu rapor kayit reddi degildir" notu.
- "Hard validation degildir" notu.
- "`blocked` status uretilmez" notu.

### JSON-ready dict output

JSON-ready dict output Python dict dondurur.

JSON-ready dict:

- Primitive/list/dict degerlerden olusur.
- Serialize edilemeyen `datetime` veya ozel object icermez.
- Input report itemlarini korur.
- Diagnostic sonucu degistirmez.
- Soft validation status yeniden hesaplamaz.
- Dosya yazmaz.

### Handover QC summary output

Olası output alanlari:

- `status`
- `review_required`
- `attention_required`
- `total_count`
- `warning_count`
- `error_count`
- `review_items`
- `attention_items`
- `message`

Handover QC summary "devir paketini otomatik bloke etmez" anlamini korur.

Bu output kayit reddi veya hard validation kapisi degildir.

## Markdown format standardi

Markdown ciktisi ileride su alanlari icerebilir:

- Baslik.
- Rapor turu.
- Status.
- `total_count`.
- `compatible_count`.
- `warning_count`.
- `error_count`.
- `review_required`.
- `attention_required`.
- Kisa yorum.
- Warning itemlari.
- Error/attention itemlari.
- "Bu rapor kayit reddi degildir" notu.
- "Hard validation degildir" notu.
- "`blocked` status uretilmez" notu.

Markdown formatter dosya uretmez.

## JSON-ready dict standardi

JSON-ready dict:

- Sadece primitive/list/dict degerler kullanir.
- Input report'taki itemlari korur.
- Item count degerlerini korur.
- Format metadata ekleyebilir.
- Diagnostic sonucu degistirmez.
- Soft validation status yeniden hesaplamaz.
- JSON dosyasi olusturmaz.

Dosya export isi ayri adimda planlanmalidir.

## Handover QC summary standardi

Handover QC summary yeni santiye sefine veri sagligi gorunurlugu saglar.

Handover QC summary:

- Warning/error kayitlarini gorunur yapar.
- "Gozden gecirilecek kayitlar" mantigiyla calisir.
- Devir paketini otomatik bloke etmez.
- Kayit reddetmez.
- Hard validation tetiklemez.
- `blocked` status uretmez.

## Test matrix plani

### Markdown formatter

Planlanan test kategorileri:

- `pass` report markdown uretimi.
- `review` report markdown uretimi.
- `attention` report markdown uretimi.
- Warning/error itemlarinin gorunmesi.
- "Hard validation degildir" notunun bulunmasi.
- `blocked` kelimesinin status olarak uretilmemesi.
- Dosya yazimi yapilmamasi.

### JSON-ready formatter

Planlanan test kategorileri:

- Output dict olmasi.
- Input mutate etmemesi.
- Item count korunumu.
- Items listesi korunumu.
- Serialize edilemeyen object eklenmemesi.
- Diagnostic sonucunun yeniden hesaplanmamasi.
- Soft validation status'un yeniden hesaplanmamasi.
- Dosya yazimi yapilmamasi.

### Handover QC summary

Planlanan test kategorileri:

- `pass` icin review/attention gerekmemesi.
- `review` icin `review_required` gorunmesi.
- `attention` icin `attention_required` gorunmesi.
- Warning/error item listesinin korunmasi.
- Devir paketinin otomatik bloke edilmemesi.
- `blocked` status uretilmemesi.

### Unsupported input

Unsupported input icin exception yerine okunur format/summary hatasi planlanabilir.

Bu hata kayit reddi anlami dogurmaz.

Bu davranis implementasyon oncesi API boundary adiminda netlestirilmelidir.

## Kullanim alanlari

- Handover on kontrol.
- Audit QC gorunumu.
- Admin/debug raporu.
- Export/backup oncesi insan-okur ozet.
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

1. Adim 148: format helper API boundary / test matrix plan.
2. Adim 149: read-only format helper implementation.
3. Adim 150: handover QC summary usage documentation.
4. Adim 151: format/export boundary follow-up veya Podcast 025 kapsam kontrolu.
5. Hard validation en sona birakilir.

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

Adim 148, diagnostic / soft validation format layer icin ilk API boundary ve test matrix sozlesmesini planladi.

Bu plan implementasyon oncesinde format helper'in sadece sunum katmani olarak kalmasini, mevcut helper davranislarini degistirmemesini ve hard validation'a erken gecmemesini saglar.

