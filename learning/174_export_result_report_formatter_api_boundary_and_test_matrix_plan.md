# Learning 174 - Export Result Report Formatter API Boundary and Test Matrix Plan

Bu adimda export result report icin gelecekte eklenebilecek Markdown formatter helper'inin API sinirini ve test matrix planini yazdik. Kod veya test degistirmedik.

## Neden bu plan gerekli?

Adim 170 ile export result summary/report helperlari eklendi.

Mevcut helperlar:

- `build_export_result_summary(...)`
- `build_export_result_report(...)`
- `format_export_result_summary_as_markdown(...)`

Adim 171 usage boundary'yi anlatti.

Adim 172 edge case standardini yazdi.

Adim 173 de bu hattin sonraki follow-up yonunu planladi.

Bu noktada summary icin Markdown formatter var, fakat report seviyesinde ayri bir Markdown formatter yok.

Bu adim, o olasi formatter'i hemen yazmak yerine once API sinirini ve test beklentisini netlestirir.

## Planlanan helper

Gelecekte planlanabilecek helper:

```text
format_export_result_report_as_markdown(report)
```

Bu helper bu adimda implement edilmedi.

## API siniri

Planlanan helper `build_export_result_report(...)` ciktisi olan dict'i input olarak alabilir.

Output olarak presentation-safe Markdown string dondurmesi planlanir.

Bu helper dosya yazmaz.

Export uretmez.

Database veya repository erisimi yapmaz.

Summary/report sonucunu yeniden hesaplamaz.

Input dict'i mutate etmez.

Hard validation tetiklemez.

`blocked` status uretmez.

## Markdown'da ne gorunebilir?

Gelecekteki Markdown cikti su bilgileri gosterebilir:

- baslik
- overall status
- toplam success/failure count
- path gorunurlugu
- error message gorunurlugu
- result contract item listesi
- human review note
- "this is not hard validation" notu

Bu bilgiler handover QC veya proje gunlugu icin okunabilir olmalidir.

Markdown cikti presentation katmanidir. Karar mekanizmasi degildir.

## Test matrix dusuncesi

Gelecekte test yazilirsa su basliklar dusunulebilir:

- empty report
- all success results
- mixed success/failure results
- missing optional fields
- unknown status value
- path visibility
- error message visibility
- input immutability
- no recomputation
- Markdown output is string
- no blocked status
- no file writing
- no change to low-level write helper behavior
- no change to `try_write_*` wrapper behavior

Bu adimda bu testler yazilmadi.

## Katman ayrimi

`try_write_*` wrapper katmani dosya yazma girisiminin sonucunu result contract olarak raporlar.

`build_export_result_report(...)` bu result contract listesinden report ciktisi uretir.

Planlanan `format_export_result_report_as_markdown(...)` ise bu report dict'ini okunabilir Markdown string'e cevirebilir.

Bu uc katman birbirinin yerine gecmez.

Formatter:

- wrapper sonucunu yeniden hesaplamaz
- path safety karari vermez
- dosya yazmaz
- export uretmez
- audit event uretmez
- diagnostic veya soft validation sonucuna donusmez

## Sinirlar

Bu adim su sinirlari tekrarlar:

- implementasyon yok
- test yok
- `app/models.py` degismez
- `tests/test_models.py` degismez
- hard validation yok
- `blocked` status yok
- backup/restore yok
- database/repository yok
- API/GUI/CLI yok
- export cikti dosyasi yok
- mevcut helper davranisi degismez
- low-level `write_*` helper davranisi degismez
- `try_write_*` wrapper davranisi degismez
- ZIP/cache/export ciktisi repo kapsamina alinmaz

## Sonraki adim

Onerilen sonraki adim:

```text
Adim 175 - Read-only export result report markdown formatter implementation
```

Bu adimda Adim 175 baslatilmadi.
