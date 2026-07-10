# Learning 189 - Export / Handover QC Review Checklist Downstream Formatter API Boundary and Test Matrix Plan

Bu adimda future checklist formatter icin API boundary ve test matrix planini netlestirdik.

Bu documentation-only bir adimdir.

Formatter implementasyonu yapilmadi.

## Olasil formatter adi

Ileride su isimde bir helper dusunulebilir:

```python
format_export_handover_qc_review_checklist_as_markdown(checklist)
```

Bu isim sadece plan ornegidir.

Adim 189'da helper eklenmedi.

## Input ne olmali?

Formatter input olarak `build_export_handover_qc_review_checklist(summary, report)` ciktisi olan JSON-ready checklist dict almalidir.

Raw writer result contract primary input olmamalidir.

Mevcut Markdown source of truth olarak parse edilmemelidir.

Input checklist dict mutate edilmemelidir.

Checklist sonucu yeniden hesaplanmamalidir.

Summary/report sonucu yeniden hesaplanmamalidir.

## Output ne olmali?

Formatter output olarak string dondurmelidir.

Bu string presentation-safe Markdown veya presentation-safe metin olabilir.

Output okunabilir olmali, ama karar verici olmamalidir.

## Output ne gostermeli?

Output en az sunlari gorunur kilabilir:

- checklist type
- status
- summary count'lari
- `is_read_only=True`
- `is_blocking=False`
- `requires_human_review`
- `review_notes`
- checklist item listesi
- path
- message
- error type
- technical detail
- next action hint

`requires_human_review` bloklama gibi sunulmamalidir.

`review_notes` aciklayici kalmalidir.

## Formatter ne yapmamalidir?

Formatter:

- dosya yazmamalidir
- export uretmemelidir
- `exports/` altina dosya birakmamalidir
- `write_*` helperlari cagirmamalidir
- `try_write_*` wrapperlari cagirmamalidir
- database/repository erisimi yapmamalidir
- audit event uretmemelidir
- backup/restore baslatmamalidir
- API/GUI/CLI davranisi eklememelidir
- hard validation yapmamalidir
- generated `blocked` status uretmemelidir
- otomatik kabul/onay/ret/bloklama yapmamalidir

## Edge case plan

Success-only checklist olumlu gorunurluk olarak sunulabilir.

Ama resmi kabul degildir.

Failure-only checklist review gorunurlugu olarak sunulabilir.

Ama otomatik ret veya bloklama degildir.

Mixed checklist hem success hem review item'larini gosterebilir.

Ama paket otomatik bloke edilmez.

Empty veya zero-count checklist sinirli gorunurluk olarak sunulmalidir.

Missing optional field safe fallback ile sunulmalidir.

Unknown/additional field yeni business rule'a donusturulmemelidir.

Unsupported input future formatter tarafindan ele alinacaksa safe presentation fallback olarak ele alinmalidir; hard validation veya `blocked` status'a donusmemelidir.

## Future test matrix

Ileride formatter implementasyonu yapilirsa testler sunlari kapsamalidir:

- success-only Markdown/string
- failure-only Markdown/string
- mixed Markdown/string
- empty / zero-count Markdown/string
- missing optional field fallback
- unknown/additional field presentation boundary
- unsupported input fallback
- output type `str`
- checklist type gorunurlugu
- `is_read_only` gorunurlugu
- `is_blocking=False` gorunurlugu
- `requires_human_review` non-blocking gorunurlugu
- `review_notes` aciklayici kalmasi
- item listesinin okunabilirligi
- input immutability
- no file write
- no export output
- no `exports/` output
- no generated `blocked`
- no hard validation regression
- existing checklist/summary/report/formatter/write/try_write davranislarinin korunmasi

## Existing helper davranislari

Adim 189 su davranislari degistirmez:

- `build_export_handover_qc_review_checklist(...)`
- `build_export_result_summary(...)`
- `build_export_result_report(...)`
- `format_export_result_report_as_markdown(...)`
- `format_export_result_summary_as_markdown(...)`
- `write_*`
- `try_write_*`

## Sonuc

Future formatter karar verici otorite olmayacaktir.

Future formatter hard validation degildir.

Future formatter `blocked` status uretmeyecektir.

GUI/API/CLI entegrasyonlari bu adimda eklenmedi.

Hard validation daha sonra ayri ve kontrollu fazda ele alinmalidir.
