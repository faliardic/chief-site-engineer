# Learning 188 - Export / Handover QC Review Checklist Downstream Formatter Plan

Bu adimda `build_export_handover_qc_review_checklist(summary, report)` ciktisinin ileride Markdown veya presentation formatter ile nasil okunabilir rapora donusturulebilecegini planladik.

Bu documentation-only bir adimdir.

Formatter implementasyonu yapilmadi.

## Formatter ne yapabilir?

Gelecekte formatter checklist JSON-ready dict input alabilir.

Sonra bunu presentation-safe Markdown veya string rapora cevirebilir.

Bu rapor sunlari gorunur kilar:

- status
- summary count'lari
- checklist item'lari
- path bilgisi
- error type
- technical detail
- next action hint
- `is_read_only=True`
- `is_blocking=False`
- `requires_human_review`
- `review_notes`

## Formatter ne yapmamalidir?

Formatter:

- dosya yazmamalidir
- export uretmemelidir
- `exports/` altina dosya birakmamalidir
- input checklist dict'i mutate etmemelidir
- checklist sonucunu yeniden hesaplamamalidir
- hard validation yapmamalidir
- `blocked` status uretmemelidir
- otomatik kabul/onay yapmamalidir
- otomatik ret yapmamalidir
- otomatik bloklama yapmamalidir
- database/repository erisimi yapmamalidir
- audit event uretmemelidir
- backup/restore baslatmamalidir
- API/GUI/CLI implementation olmamalidir

## Flag'ler nasil sunulmali?

`is_read_only=True` Markdown gorunumunde korunmalidir.

Bu raporun sadece okuma/gorunurluk amacli oldugunu anlatir.

`is_blocking=False` Markdown gorunumunde korunmalidir.

Bu raporun devir paketini bloke etmedigini anlatir.

`requires_human_review` inceleme gorunurlugudur.

Bloklama degildir.

## Scenario gorunumleri

Success-only checklist olumlu gorunurluk olarak sunulabilir.

Ama resmi kabul degildir.

Failure-only checklist insan incelemesi olarak sunulabilir.

Ama otomatik ret veya bloklama degildir.

Mixed checklist hem success hem review item'larini birlikte gosterebilir.

Ama tum paketi otomatik bloke etmez.

Empty veya zero-count checklist sinirli gorunurluk olarak okunmalidir.

Missing optional field durumunda safe fallback metin kullanilabilir.

Unknown/additional field durumunda yeni business rule uretilmemelidir.

## review_notes siniri

`review_notes` aciklayici notlardir.

Karar verici alan degildir.

Audit evidence degildir.

Official approval/rejection degildir.

## Gelecek implementasyon siniri

Formatter ileride yazilacaksa ayri adimda yazilmalidir.

O adimda ayri testler ve ayri dokumantasyon olmalidir.

Adim 188 sadece planlama yapar.

## Existing helper davranislari

Adim 188 su helper davranislarini degistirmez:

- `build_export_handover_qc_review_checklist(...)`
- `build_export_result_summary(...)`
- `build_export_result_report(...)`
- `format_export_result_report_as_markdown(...)`
- `format_export_result_summary_as_markdown(...)`
- `write_*`
- `try_write_*`

## Sonuc

Checklist formatter karar verici otorite olmayacaktir.

Hard validation daha sonra ayri ve kontrollu fazda ele alinmalidir.

Bu adimda kod, test, formatter, API/GUI/CLI, database/repository, audit, backup/restore, export ciktisi, hard validation veya `blocked` status eklenmedi.
