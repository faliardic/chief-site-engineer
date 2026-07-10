# Adim 169 - Export Result Summary Report API Boundary and Test Matrix Plan

Bu adimda Adim 168'de planlanan export result summary/report layer icin API siniri ve ileride yazilabilecek test matrix'i belgelendi.

Mevcut wrapper helperlar:

- `try_write_json_ready_dict_to_file(...)`
- `try_write_markdown_text_to_file(...)`

Bu adim documentation-only plan adimidir.

Kod yazilmadi.

Yeni test yazilmadi.

Mevcut testler degistirilmedi.

Export helper davranisi degistirilmedi.

JSON veya Markdown export cikti dosyasi uretilmedi.

Commit alinmadi.

Push yapilmadi.

## API boundary

Ilerideki summary/report helper yalniz wrapper result contract veya wrapper result contract listesi almalidir.

Plan duzeyinde degerlendirilebilecek helper isimleri:

- `build_export_result_summary(...)`
- `build_export_result_report(...)`
- `format_export_result_summary_as_markdown(...)`

Bu adimda bu helperlar implement edilmez.

Bu adimda helper imzasi kilitlenmez.

Bu adimda zorunlu output semasi olusturulmaz.

Bu adim yalniz API sinirini ve test matrix beklentilerini belgeler.

## Input siniri

Planlanan helperlar dosya yazma islemi yapmayacak.

Planlanan helperlar export helper cagirmayacak.

Planlanan helperlar path safety kararini yeniden hesaplamayacak.

Planlanan helperlar dusuk seviye `write_*` helperlarin yerine gecmeyecek.

Planlanan helperlar `try_*` wrapperlarin yerine gecmeyecek.

Planlanan helperlar sadece mevcut result contract verisini yorumlayacak.

Beklenen input, tek bir result contract dict'i veya result contract dict listesi olabilir.

Input contract'in kaynaklari su wrapperlar olabilir:

- `try_write_json_ready_dict_to_file(...)`
- `try_write_markdown_text_to_file(...)`

Input icindeki alanlar mevcut wrapper sozlesmesine dayanir:

- `success`
- `output_path`
- `attempted_path`
- `allowed_root`
- `file_type`
- `error_code`
- `error_message`
- `skipped_reason`
- `overwritten`

Summary/report layer bu alanlari yorumlayabilir, fakat wrapper sonucunu yeniden uretmez.

## Output siniri

Planlanan output su bicimlerden biri olabilir:

- JSON-ready dict.
- Markdown text.
- Handover QC summary.

Output yalniz raporlama ve yorumlama amacli olmalidir.

Output kayitlari gecersiz saymamalidir.

Output devir paketini otomatik bloke etmemelidir.

Output hard validation anlamina gelmemelidir.

Output `blocked` status uretmemelidir.

Output database veya repository kaydi degistirmemelidir.

Output audit event uretmemelidir.

## Success summary yorumu

Basarili wrapper contract summary tarafindan su sekilde yorumlanabilir:

```text
status="success"
message="Export dosyasi yazildi."
```

Bu yorum export yazma isleminin tamamlandigini belirtir.

Bu yorum backup olustugu anlamina gelmez.

Bu yorum audit event uretildigi anlamina gelmez.

Bu yorum devir paketinin otomatik onaylandigi anlamina gelmez.

## Failure summary yorumu

Basarisiz wrapper contract summary tarafindan su sekilde yorumlanabilir:

```text
status="review"
message="Export sonucu gozden gecirilmeli."
```

veya:

```text
status="attention"
message="Export yazimi tamamlanamadi."
```

Failure contract otomatik duzeltme baslatmaz.

Failure contract migration baslatmaz.

Failure contract devir paketini otomatik bloke etmez.

Failure contract hard validation degildir.

Failure contract `blocked` status uretmez.

## Handover QC yorumu

Basarili export sonucu handover QC'de gorunur olabilir.

Basarisiz export sonucu "review required" veya "attention" seklinde yorumlanabilir.

Bu yorum insan incelemesini destekler.

Bu yorum karar mekanizmasi degildir.

Bu yorum kayitlari gecersiz yapmaz.

Bu yorum audit event uretmez.

Bu yorum backup/restore sistemi degildir.

## Teknik detay / kullanici mesaji ayrimi

Summary/report layer ileride teknik detay ile kullanici mesajini ayirabilir.

Teknik detay:

- `attempted_path`
- `allowed_root`
- `error_code`
- `error_message`
- `skipped_reason`
- `overwritten`

Kullaniciya gosterilebilecek guvenli mesaj:

```text
Export yazilmadi; hedef dosya zaten var.
```

veya:

```text
Export yazilmadi; hedef klasor hazir degil.
```

Teknik detay korunabilir.

Ancak kullaniciya donen ozet teknik detayi asiri kullanmamalidir.

## Onerilen test matrix

Bu adimda test yazilmayacak.

Ileride summary/report layer implementasyonu dusunulurse su test basliklari belgelendi:

- success contract summary
- failure contract summary
- mixed success/failure result list
- missing optional fields
- unknown status
- unsupported input
- input immutability
- no file writing
- no blocked status
- no hard validation
- no recomputation of wrapper result
- markdown summary contains safe user message
- technical detail is preserved but not overused in user-facing summary

Bu test basliklari plan seviyesindedir.

Test dosyasi olusturulmaz.

Mevcut testler degistirilmez.

## Yapilmayacaklar

Kod yazilmayacak.

Test yazilmayacak.

Existing helper davranisi degistirilmeyecek.

Export cikti dosyasi uretilmeyecek.

Hard validation eklenmeyecek.

`blocked` status eklenmeyecek.

Backup/restore/API/GUI/CLI eklenmeyecek.

Audit event uretimi eklenmeyecek.

Database/repository davranisi eklenmeyecek.

ZIP/cache stage edilmeyecek.

Commit yapilmayacak.

Push yapilmayacak.

## Sonuc

Adim 169, export result summary/report layer icin API boundary ve test matrix planini netlestirir.

Bu adim summary/report helper implementasyonu degildir.

Bu adim wrapper result contract'i yorumlama katmaninin gelecekte nasil sinirlanabilecegini belgeler.

Bu adim hard validation, `blocked` status veya otomatik handover karari uretmez.
