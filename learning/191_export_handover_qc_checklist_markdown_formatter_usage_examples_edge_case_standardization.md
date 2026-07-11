# Learning 191 - Export / Handover QC Checklist Markdown Formatter Usage, Examples, and Edge Case Standardization

Bu adim `format_export_handover_qc_review_checklist_as_markdown(checklist)` helper'inin nasil okunacagini ve nerede kullanilmamasi gerektigini belgelendirir.

Bu adim documentation-only'dir.

Kod, test, export dosyasi, commit veya push eklenmez.

## Formatter'in amaci

Formatter, checklist JSON-ready dict ciktisini presentation-safe Markdown string'e cevirir.

Kaynak checklist su helper'dan gelir:

```python
build_export_handover_qc_review_checklist(...)
```

Markdown ciktisi insan incelemesi icindir.

## Input

Beklenen input checklist dict'tir.

Bu dict, export result helper zincirinden gelir:

```text
build_export_result_summary(...)
build_export_result_report(...)
build_export_handover_qc_review_checklist(...)
```

Formatter raw export dosyasi okumaz.

Formatter summary, report veya checklist'i bastan hesaplamaz.

## Output

Output Markdown string'dir.

Bu metin sunlari gorunur kilar:

- checklist type
- status
- summary count'lari
- `is_read_only`
- `is_blocking`
- `requires_human_review`
- review notes
- item listesi
- varsa path, message, error type, technical detail ve next action

## Sinirlar

Formatter read-only presentation helper'dir.

Formatter:

- dosya yazmaz
- export uretmez
- database/repository erisimi yapmaz
- audit event uretmez
- backup/restore baslatmaz
- migration baslatmaz
- API/GUI/CLI davranisi eklemez
- input dict'i mutate etmez
- checklist sonucunu yeniden hesaplamaz
- summary/report sonucunu yeniden hesaplamaz
- hard validation yapmaz
- `blocked` status uretmez

## Blocking yorumu

`is_blocking` karar mekanizmasi degildir.

Formatter `is_blocking` degerini otomatik bloklama davranisina cevirmemelidir.

`requires_human_review` yalniz insan inceleme sinyalidir.

Otomatik kabul, otomatik ret, otomatik bloklama veya resmi handover karari degildir.

## Nerede kullanilir?

Uygun kullanim yerleri:

- handover QC review notu
- future export review ekraninda presentation layer
- NotebookLM / insan okumasina uygun ozet
- debug/admin metinsel inceleme

Bu kullanimlar gorunurluk icindir.

Karar verme icin degildir.

## Nerede kullanilmaz?

Formatter su amaclarla kullanilmamalidir:

- hard validation
- otomatik kayit reddi
- migration
- backup/restore
- API davranisi
- GUI davranisi
- CLI davranisi
- audit event uretimi
- dosya export helper yerine dogrudan export yazimi
- Markdown'u tekrar structured source of truth olarak parse etme

## Edge case standardi

Success checklist olumlu gorunurluktur.

Resmi kabul degildir.

Failure checklist review gorunurlugudur.

Otomatik ret, bloklama veya hard validation degildir.

Mixed checklist hem success hem review item'larini birlikte gosterir.

Paket karari degildir.

Empty checklist no-item veya sinirli gorunurluk olarak okunur.

Eksik alan durumunda guvenli fallback metni kullanilir.

Unknown status gorunur kalir, fakat yeni business rule'a donusmez.

Unsupported input durumunda guvenli Markdown fallback beklenir.

## Helper zinciri

Formatter zincirde son presentation katmanidir:

```text
build_export_result_summary(...)
build_export_result_report(...)
build_export_handover_qc_review_checklist(...)
format_export_handover_qc_review_checklist_as_markdown(...)
```

Bu siralama katmanlari ayri tutar:

- result summary/report
- checklist structure
- Markdown presentation
- explicit file writing helper'lari

## Sonuc

Adim 191, formatter usage documentation, example standardization ve edge case yorumlama standardini netlestirir.

Yeni helper, yeni test, export dosyasi, hard validation, `blocked` status, API/GUI/CLI, database/repository, audit, backup/restore, commit veya push eklenmez.
